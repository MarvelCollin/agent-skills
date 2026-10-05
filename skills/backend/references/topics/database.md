# Database Access and Design

Most backend latency is in the database, and most database problems are in a few query shapes. This file covers N+1 queries, query design, pagination, indexing, connection pools, schema and data types. For Postgres-specific rules ranked by impact, with wrong and right SQL, plan reading, RLS performance and vacuum, see [../postgres.md](../postgres.md).

## N+1 Queries

**What it is.** One query loads N parent rows, then the code runs one more query per row to load a relation. 1 + N round trips. It looks fine with 5 rows in development and falls over with 500 in production.

```python
orders = Order.objects.filter(owner=user)[:50]
for order in orders:
    print(order.customer.name)
```

That is 51 queries. The lazy load hides inside attribute access, serializers, templates and GraphQL resolvers.

**How to find it**

- Turn on SQL logging and call the endpoint with 1 row and with 50 rows. If the count grows, it is N+1
- Repeated identical query shapes with different ids in one request trace
- Tools: Django Debug Toolbar, `nplusone`, `django-zen-queries`, `assertNumQueries`. Rails Bullet, Prosopite, `strict_loading`. Laravel `Model::preventLazyLoading()`. SQLAlchemy `raiseload("*")` or `lazy="raise"`. Hibernate statistics and `hypersistence-utils`. EF Core `LogTo` and MiniProfiler. Prisma query events. Any APM showing spans per request
- The `query-in-loop` check in `backend-scan` finds explicit calls in loops. It cannot see lazy attribute access, so read serializers too

**How to fix it**

| Situation | Fix |
|-----------|-----|
| To-one relation (order to customer) | Join in the same query: Django `select_related`, Rails `includes` or `eager_load`, SQLAlchemy `joinedload`, JPA `JOIN FETCH`, EF `Include`, Prisma `include`, GORM `Joins` |
| To-many relation (order to items) | One extra `IN` query per relation, not a join that multiplies rows: Django `prefetch_related`, Rails `preload`, SQLAlchemy `selectinload`, Hibernate `@BatchSize`, EF `AsSplitQuery`, Prisma `include`, GORM `Preload` |
| Counts or sums per parent | Aggregate in SQL: `GROUP BY`, `withCount`, `annotate(Count(...))`, or a lateral join |
| GraphQL fields | A DataLoader per request that batches ids within one tick |
| Calling another service per item | A batch endpoint (`GET /users?ids=1,2,3`) or a local read model |
| Writes per row | Bulk insert or upsert (`INSERT ... VALUES (...), (...)`, `bulk_create`, `insert_all`, `createMany`, `COPY`) |

Manual batching when no ORM helper fits:

```sql
SELECT id, name FROM customers WHERE id = ANY($1)
```

Then map results by id in memory. Deduplicate the ids first.

**Prevent it from coming back.** Enable the lazy-load guard in development and tests, and add a query-count test to list endpoints (see [testing.md](testing.md)).

## Query Design

- **Select only what you return.** `SELECT *` pulls wide columns (text, JSON, blobs) over the network, defeats covering indexes, and breaks when columns are added. Use projections (`.only()`, `select:`, `Select(x => new Dto {...})`)
- **Filter, sort and aggregate in the database.** Never load rows to filter in application code
- **Keep predicates sargable.** `WHERE created_at >= $1` uses an index. `WHERE DATE(created_at) = $1` or `WHERE lower(email) = $1` does not, unless you add an expression index
- **Avoid leading wildcards.** `LIKE '%term%'` cannot use a B-tree index. Use a trigram index (`pg_trgm`), full-text search, or a search engine
- **Prefer `EXISTS` over `COUNT(*) > 0`.** It stops at the first match
- **Large `IN` lists:** pass an array (`= ANY($1)`) or join against a temporary table or `VALUES` list
- **Always `LIMIT`** user-facing queries, even internal ones that "only return a few"
- **Mind implicit casts.** Comparing a text column to a number, or mismatched collations, disables indexes
- **Parameterize everything.** It prevents SQL injection and lets the database cache plans

## Pagination

Offset pagination (`LIMIT 20 OFFSET 10000`) makes the database read and discard 10,000 rows, gets slower with every page, and skips or repeats rows when data changes between requests.

Keyset (cursor) pagination stays fast at any depth:

```sql
SELECT id, created_at, total_cents
FROM orders
WHERE tenant_id = $1
  AND (created_at, id) < ($2, $3)
ORDER BY created_at DESC, id DESC
LIMIT 21
```

- Index: `(tenant_id, created_at DESC, id DESC)`
- The cursor is an opaque base64 encoding of the last row's `(created_at, id)`. Fetch `limit + 1` rows to know whether a next page exists
- The sort always ends with a unique column so ties are stable
- Exact total counts on big tables are expensive. Return `has_more`, use an estimate (`pg_class.reltuples`), or serve counts from a separate cached endpoint

Offset is acceptable for small bounded sets and admin screens where users jump to page numbers.

## Indexing

- **Index for the queries you run**, found with `pg_stat_statements`, the slow query log, or APM. Not every column
- **Composite order:** equality columns first, then the sort column, then range columns. An index on `(tenant_id, status, created_at)` serves `WHERE tenant_id = ? AND status = ? ORDER BY created_at`
- **Covering indexes** (`INCLUDE (total_cents)` in Postgres, extra trailing columns in MySQL) let the query read only the index
- **Partial indexes** for hot subsets: `WHERE deleted_at IS NULL`, `WHERE status = 'pending'`
- **Expression indexes** for computed predicates: `ON users (lower(email))`
- **GIN** for `jsonb`, arrays and full-text. **BRIN** for huge append-only time-ordered tables. **Hash** rarely
- **Foreign keys:** Postgres does not index them automatically. Unindexed foreign keys make joins slow and turn parent deletes into full scans with heavy locking. MySQL InnoDB creates them
- **Cost:** every index slows writes and uses memory. Find unused ones (`pg_stat_user_indexes.idx_scan = 0`) and duplicates, and drop them
- **Verify with plans.** `EXPLAIN (ANALYZE, BUFFERS)` on realistic data. Look for sequential scans on big tables, sorts spilling to disk, nested loops over many rows, and estimates far from actual rows (run `ANALYZE` to refresh statistics)

## Connection Pools

- **Small pools beat big ones.** HikariCP's starting point: connections = (core count times 2) plus effective spindle count. A 4-core database server handles about 10 active connections efficiently. Extra connections add context switching and lock contention
- **Budget the total.** Pool size times app instances (times worker processes per instance) must stay under the database `max_connections` with headroom for migrations, admin and replicas
- **Use a pooler** for many instances or serverless: PgBouncer in transaction mode, RDS Proxy, or the provider's pooler. Transaction mode means no session state across transactions: use `SET LOCAL`, and check prepared statement support in your driver
- **Set timeouts:** pool acquire timeout (fail fast instead of queueing forever), `statement_timeout`, `idle_in_transaction_session_timeout`, `lock_timeout`
- **Release connections.** Leaks show as pool exhaustion under load. Always use the framework's scoped session or `try/finally`
- **Do not hold a connection during slow work.** Fetch, release, then call the slow API

## Schema and Types

- **Constraints are the last line of defense:** `NOT NULL`, `UNIQUE`, foreign keys, `CHECK (quantity > 0)`. Application validation can race. Constraints cannot
- **Primary keys:** `bigint` identity, or UUIDv7 (RFC 9562, time ordered, inserts stay at the end of the B-tree). Random UUIDv4 keys scatter inserts across the index and bloat it. If enumeration matters, expose a separate opaque public id
- **Money:** `NUMERIC(19,4)` or integer minor units in `bigint`, with a currency column. Never `float` or `double`
- **Time:** `timestamptz` in Postgres, always UTC. Plain `timestamp` loses the offset. MySQL `DATETIME` has no zone, so store UTC by convention and document it
- **Enums:** a lookup table or a `CHECK` constraint is easier to evolve than a native enum type in some engines
- **JSON columns** for truly variable data only. Anything you filter or join on deserves a real column
- **Soft delete** (`deleted_at`) adds a filter to every query and breaks unique constraints. If you need it, use partial unique indexes `WHERE deleted_at IS NULL` and a default scope. Consider an archive table instead
- **Audit columns:** `created_at`, `updated_at`, and `created_by` where accountability matters
- **Normalize first.** Denormalize deliberately for a measured read path, and document how the copy stays in sync

## Scaling Reads and Data

- **Read replicas** for heavy reads. Replicas lag, so read-your-own-writes paths (show the order just placed) go to the primary for a short window
- **Materialized views or summary tables** for dashboards and reports, refreshed on a schedule or incrementally
- **Precompute counts and totals** that are read far more often than they change (comment count, order total, unread badge). Keep a counter column updated in the same transaction as the write (`SET count = count + 1`), or a summary row rebuilt by a job. A `COUNT(*)` or `SUM` over a large table on every request is a scan each time. For a rough total on a huge table, the planner estimate (`reltuples`) is often enough
- **Partition** very large time-series tables by time so old partitions can be dropped instead of deleted
- **Archive** cold data. Smaller hot tables mean smaller indexes that fit in memory
- **Search** belongs in Postgres full-text for simple cases, or OpenSearch, Elasticsearch, Meilisearch or Typesense when relevance and facets matter

## ORM Hygiene

- No queries from views, templates or serializers. Load everything the response needs in the service layer
- Read-only queries skip change tracking (EF `AsNoTracking`, Hibernate read-only, Django `values()` for raw data)
- Iterate big result sets in chunks (`iterator()`, `find_each`, `chunkById`, streaming cursors)
- Know what your ORM does by default. Hibernate `@ManyToOne` is eager unless set to lazy. Spring `open-in-view` keeps lazy loading alive in views, so set `spring.jpa.open-in-view=false`
- Drop to SQL for reports and complex aggregates. A query builder like Kysely, jOOQ, sqlc or SQLAlchemy Core keeps it typed

## Checklist

- [ ] Query count per request is constant for list endpoints
- [ ] No `SELECT *`, every query has a `LIMIT`
- [ ] Keyset pagination for large or infinite lists
- [ ] Hot queries have matching indexes, verified with plans on real volume
- [ ] Foreign keys indexed, constraints in the schema
- [ ] Pool sized against `max_connections`, with acquire and statement timeouts
- [ ] Money, time and id types are correct
