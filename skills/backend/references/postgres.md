# Postgres Rules

Concrete Postgres rules ranked by impact, each with the wrong shape, the right shape, and how to check. Use the rule id (`query-missing-index`) in findings. MySQL notes are at the end.

| Priority | Category | Impact | Prefix |
|----------|----------|--------|--------|
| 1 | Queries and indexes | Critical | `query-` |
| 2 | Connections | Critical | `conn-` |
| 3 | Security and RLS | Critical | `sec-` |
| 4 | Schema | High | `schema-` |
| 5 | Locking and concurrency | Medium to high | `lock-` |
| 6 | Data access | Medium | `data-` |
| 7 | Monitoring and maintenance | Low to medium | `monitor-` |
| 8 | Advanced features | Low | `adv-` |

Always capture `EXPLAIN (ANALYZE, BUFFERS)` before a change and again after it. Change one thing at a time.

## 1. Queries and Indexes

### query-missing-index (Critical)

A hot filter, join or sort with no matching index scans the whole table. Fine on 1,000 rows, a timeout on 10 million.

Wrong:

```sql
SELECT id, total_cents FROM orders WHERE customer_id = $1
```

with no index on `customer_id`. The plan shows `Seq Scan on orders` with `Rows Removed by Filter` in the millions.

Right:

```sql
CREATE INDEX CONCURRENTLY orders_customer_id_idx ON orders (customer_id)
```

Check: `pg_stat_user_tables.seq_scan` high on large tables, `EXPLAIN` showing `Seq Scan` on a big table for a selective filter.

### query-composite-order (Critical)

In a composite index, equality columns go first, then the sort or range column. The wrong order cannot serve the query.

Wrong:

```sql
CREATE INDEX orders_created_status_idx ON orders (created_at, status)
```

for `WHERE status = 'paid' ORDER BY created_at DESC LIMIT 20`.

Right:

```sql
CREATE INDEX CONCURRENTLY orders_status_created_idx ON orders (status, created_at DESC)
```

A composite index also serves queries on its leading columns alone, so `(tenant_id, created_at)` makes a separate `(tenant_id)` index redundant.

### query-covering-index (High)

When a hot query reads a few extra columns, `INCLUDE` them so Postgres answers from the index alone (an Index Only Scan).

```sql
CREATE INDEX CONCURRENTLY orders_customer_created_idx
  ON orders (customer_id, created_at DESC) INCLUDE (status, total_cents)
```

Index only scans need a recently vacuumed table (the visibility map). Watch `Heap Fetches` in the plan.

### query-partial-index (High)

Index only the rows the hot query touches. Smaller, faster, cheaper to maintain.

```sql
CREATE INDEX CONCURRENTLY jobs_pending_idx ON jobs (run_at) WHERE status = 'pending'
```

The query must repeat the same predicate (`WHERE status = 'pending'`) for the planner to use it.

### query-sargable (High)

A function or cast on the indexed column hides it from the index.

Wrong:

```sql
SELECT id FROM users WHERE lower(email) = lower($1)
```

```sql
SELECT id FROM orders WHERE date(created_at) = $1
```

Right: an expression index, or a range on the raw column.

```sql
CREATE UNIQUE INDEX CONCURRENTLY users_email_lower_idx ON users (lower(email))
```

```sql
SELECT id FROM orders WHERE created_at >= $1 AND created_at < $1 + interval '1 day'
```

### query-leading-wildcard (High)

`LIKE '%term%'` and `ILIKE` cannot use a B-tree index.

Right: a trigram index, or full-text search (see `adv-full-text`).

```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm
```

```sql
CREATE INDEX CONCURRENTLY products_name_trgm_idx ON products USING gin (name gin_trgm_ops)
```

### query-index-type (Medium)

| Data or query | Index |
|---------------|-------|
| Equality, range, sort | B-tree (default) |
| `jsonb` containment, arrays, full-text | GIN |
| Huge append-only time series | BRIN |
| Geometry, ranges, nearest neighbor | GiST |
| Vector similarity | HNSW (pgvector) |

### query-any-array (Medium)

Pass id lists as one array parameter, not a giant `IN` list built as a string.

```sql
SELECT id, name FROM customers WHERE id = ANY($1::bigint[])
```

One prepared statement shape for any list length, and no injection risk.

### query-exists (Medium)

Use `EXISTS` to ask "is there at least one". `COUNT(*)` reads every match.

```sql
SELECT EXISTS (SELECT 1 FROM orders WHERE customer_id = $1 AND status = 'open')
```

## 2. Connections

### conn-pool-size (Critical)

Each Postgres connection is a process with its own memory. Hundreds of active connections thrash CPU and locks. Start near (cores times 2) plus spindles active connections on the database, and make app pools small.

Check: total of pool size times instances times workers stays well under `max_connections` minus `superuser_reserved_connections` minus headroom for migrations and admin.

### conn-pooler (Critical)

Many app instances, serverless functions or worker processes need a pooler in front: PgBouncer in transaction mode, RDS Proxy, or the provider's pooler. Transaction mode hands a server connection to a client only for the length of a transaction.

Consequences of transaction mode:
- Session state does not survive across transactions. Use `SET LOCAL` inside the transaction, not `SET`
- `LISTEN` and session advisory locks need a direct connection
- Prepared statements need PgBouncer 1.21 or later with `max_prepared_statements` set, or the driver's prepared statements turned off (`prepare: false` in postgres.js, `statement_cache_size=0` in asyncpg, `pgbouncer=true` in Prisma connection strings)

### conn-timeouts (Critical)

Set limits per role so one bad query cannot hold a connection forever:

```sql
ALTER ROLE app_user SET statement_timeout = '5s'
```

```sql
ALTER ROLE app_user SET idle_in_transaction_session_timeout = '30s'
```

```sql
ALTER ROLE app_user SET lock_timeout = '2s'
```

Long-running jobs and migrations use their own role or `SET LOCAL` with a larger value.

### conn-leaks (High)

A connection checked out and never returned (an early return before `release`, an exception path) drains the pool until every request waits. Always use the driver's scoped helper (`pool.query`, a `with` block, `try/finally`). Check: pool "waiting" count grows while active database work stays low.

## 3. Security and RLS

### sec-least-privilege (Critical)

The app connects as a role that can read and write its tables and nothing more. Migrations run as a separate owner role.

```sql
REVOKE CREATE ON SCHEMA public FROM PUBLIC
```

```sql
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA app TO app_user
```

Read-only analytics or reporting gets its own role with `SELECT` only. Never connect the app as a superuser or the table owner.

### sec-rls-enable (Critical)

For multi-tenant tables, Row Level Security is the backstop when application scoping fails.

```sql
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY
```

```sql
ALTER TABLE invoices FORCE ROW LEVEL SECURITY
```

`FORCE` makes the table owner obey the policies too. Superusers and roles with `BYPASSRLS` still bypass them, so the app role must have neither.

### sec-rls-performance (High)

A policy expression runs per row. Wrap function calls in a subselect so Postgres evaluates them once per query, and index the policy columns.

Wrong:

```sql
CREATE POLICY tenant_isolation ON invoices
  USING (tenant_id = current_setting('app.tenant_id')::uuid)
```

Right:

```sql
CREATE POLICY tenant_isolation ON invoices
  USING (tenant_id = (SELECT current_setting('app.tenant_id')::uuid))
```

```sql
CREATE INDEX CONCURRENTLY invoices_tenant_id_idx ON invoices (tenant_id)
```

The same applies to `auth.uid()` on Supabase: `(SELECT auth.uid())`. Complex membership checks go in a `SECURITY DEFINER` function (next rule) instead of a correlated subquery per row.

### sec-security-definer (High)

`SECURITY DEFINER` functions run with the owner's rights and skip RLS on the tables they touch. Make them safe:
- `SET search_path = ''` and schema-qualify every name inside, so a caller cannot hijack lookups
- Check the caller's identity inside the function body
- Keep them in a schema the API does not expose
- `REVOKE EXECUTE ... FROM PUBLIC` and grant only to the roles that need it

### sec-set-local-tenant (High)

With pooling, set the tenant per transaction, never per session:

```sql
SET LOCAL app.tenant_id = '3f6c1a2e-...'
```

A plain `SET` leaks the tenant to the next client that borrows the connection.

## 4. Schema

### schema-primary-key (High)

Every table has a primary key. Use `bigint GENERATED ALWAYS AS IDENTITY` or a time-ordered UUIDv7 (`uuidv7()` is built in from Postgres 18, use an extension or app-side generation before that). Random UUIDv4 keys scatter inserts across the B-tree and bloat it on hot tables.

### schema-fk-index (High)

Postgres does not index foreign key columns. Without the index, joins on the key scan, and deleting a parent row scans the child table while holding a lock.

```sql
CREATE INDEX CONCURRENTLY order_items_order_id_idx ON order_items (order_id)
```

Check with the unindexed foreign key query in `monitor-fk-without-index`.

### schema-constraints (High)

`NOT NULL`, `UNIQUE`, `CHECK` and foreign keys enforce invariants the application cannot guarantee under concurrency.

```sql
ALTER TABLE order_items ADD CONSTRAINT order_items_quantity_positive CHECK (quantity > 0) NOT VALID
```

```sql
ALTER TABLE order_items VALIDATE CONSTRAINT order_items_quantity_positive
```

### schema-types (High)

| Data | Use | Avoid |
|------|-----|-------|
| Instants | `timestamptz` | `timestamp` (drops the offset) |
| Money | `bigint` minor units or `numeric(19,4)` | `float`, `double precision`, `real`, `money` |
| Text | `text` with a `CHECK (length(x) <= n)` if needed | `char(n)` (pads with spaces) |
| JSON | `jsonb` | `json` (no indexing, keeps duplicates) |
| Flags | `boolean` | `smallint`, `'Y'` strings |
| Fixed sets | lookup table or `CHECK (x IN (...))` | enum types you will need to reorder or rename |

### schema-identifiers (Medium)

Use unquoted lowercase `snake_case` names. A name created as `"UserId"` must be quoted forever, which breaks tools and hand-written SQL.

### schema-soft-delete (Medium)

If you soft delete, unique rules must ignore deleted rows:

```sql
CREATE UNIQUE INDEX CONCURRENTLY users_email_active_idx ON users (lower(email)) WHERE deleted_at IS NULL
```

Every query needs the same filter. Prefer a default scope in the data layer, or an archive table.

### schema-partitioning (Medium)

Partition by time when a table grows past roughly 100 million rows, when old data is dropped on a schedule, or when vacuum cannot keep up. Dropping a partition is instant. Deleting millions of rows is not. Every query should filter on the partition key so the planner can prune.

## 5. Locking and Concurrency

### lock-short-transactions (Medium to high)

Locks are held until commit. Never call an HTTP API, send email, or wait for a user inside a transaction. Long transactions also block vacuum from cleaning dead rows across the whole database.

### lock-atomic-update (High)

Wrong (read, check in code, write):

```sql
SELECT stock FROM items WHERE id = $1
```

Right (check and change in one statement, then read the affected row count):

```sql
UPDATE items SET stock = stock - $2 WHERE id = $1 AND stock >= $2 RETURNING stock
```

### lock-skip-locked (Medium)

Workers that claim jobs from a table use `FOR UPDATE SKIP LOCKED` so they never wait on each other:

```sql
UPDATE jobs SET status = 'running', locked_at = now()
WHERE id = (
  SELECT id FROM jobs WHERE status = 'pending' AND run_at <= now()
  ORDER BY run_at FOR UPDATE SKIP LOCKED LIMIT 1
)
RETURNING id, payload
```

### lock-deadlocks (Medium)

Deadlocks happen when two transactions lock the same rows in different orders. Lock rows in a consistent order (sort ids before batch updates) and retry on SQLSTATE `40P01`.

### lock-advisory (Medium)

Serialize work on a logical key that is not a row (one sync per customer, one cron run at a time):

```sql
SELECT pg_try_advisory_xact_lock(hashtext('sync:' || $1))
```

The `xact` form releases at commit, which is safe with transaction pooling.

### lock-migrations (High)

Every migration sets `lock_timeout` so an `ALTER` that cannot get its lock fails fast instead of queueing every query behind it. See [topics/migrations.md](topics/migrations.md) and run `db-lint` on migration files.

## 6. Data Access

### data-n-plus-one (Critical)

One query per parent row. Batch with `= ANY($1)` or a join (see [topics/database.md](topics/database.md)).

### data-keyset-pagination (High)

Wrong:

```sql
SELECT id, created_at FROM events ORDER BY created_at DESC LIMIT 50 OFFSET 100000
```

Right:

```sql
SELECT id, created_at FROM events
WHERE (created_at, id) < ($1, $2)
ORDER BY created_at DESC, id DESC
LIMIT 50
```

with an index on `(created_at DESC, id DESC)`.

### data-batch-insert (High)

One statement per row pays a round trip and a commit each time. Use multi-row inserts, `unnest` arrays, or `COPY` for bulk loads.

```sql
INSERT INTO events (account_id, kind, payload)
SELECT * FROM unnest($1::bigint[], $2::text[], $3::jsonb[])
```

### data-upsert (Medium)

Use `INSERT ... ON CONFLICT` instead of select then insert, which races.

```sql
INSERT INTO daily_stats (account_id, day, views) VALUES ($1, $2, 1)
ON CONFLICT (account_id, day) DO UPDATE SET views = daily_stats.views + 1
```

Add `WHERE` to `DO UPDATE` to skip writes that change nothing.

### data-returning (Medium)

`INSERT`, `UPDATE` and `DELETE` can return rows with `RETURNING`. No follow-up select.

### data-batched-delete (Medium)

Delete or update millions of rows in batches by key range, with pauses, so you do not hold locks for minutes, bloat the table, or spike replication lag:

```sql
DELETE FROM audit_log WHERE id IN (
  SELECT id FROM audit_log WHERE created_at < now() - interval '1 year' LIMIT 5000
)
```

Repeat until zero rows. For time-based retention, partitioning is better.

## 7. Monitoring and Maintenance

### monitor-explain (Medium)

Read plans with `EXPLAIN (ANALYZE, BUFFERS)` on realistic data. On a write, wrap it in `BEGIN` and `ROLLBACK`, because `ANALYZE` executes the statement.

| Plan shows | Means | Remedy |
|------------|-------|--------|
| `Seq Scan` on a big table with a selective filter | No usable index | Add or fix the index (`query-missing-index`, `query-sargable`) |
| Estimated rows far from actual rows | Stale or weak statistics | `ANALYZE table`, raise `default_statistics_target` for skewed columns, extended statistics for correlated columns |
| `Nested Loop` with a large outer side | Many index lookups | Index the inner join key, or let a hash join run by fixing estimates |
| `Sort Method: external merge` | Sort spilled to disk | Index that provides the order, or raise `work_mem` for that query |
| `Buffers: shared read` much larger than `hit` | Reading from disk | Covering index, more memory, smaller rows |
| `Heap Fetches` high on an Index Only Scan | Visibility map stale | Vacuum the table more often |
| `Rows Removed by Filter` huge | Index not selective enough | Composite or partial index |

### monitor-pg-stat-statements (Medium)

Enable `pg_stat_statements` and look at the top queries by total time, not only the slowest single run:

```sql
SELECT left(query, 120) AS query, calls,
       round(total_exec_time) AS total_ms,
       round(mean_exec_time, 1) AS mean_ms,
       rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20
```

A cheap query called 50,000 times a minute often costs more than one slow report. High `calls` with tiny `rows` per call is the signature of N+1.

### monitor-vacuum (Medium)

Updates and deletes leave dead rows that autovacuum cleans. When it falls behind, tables bloat, index only scans stop working, and in the worst case transaction id wraparound forces a shutdown.

```sql
SELECT relname, n_live_tup, n_dead_tup, last_autovacuum, last_autoanalyze
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC
LIMIT 20
```

- For big hot tables, lower the per-table thresholds: `ALTER TABLE events SET (autovacuum_vacuum_scale_factor = 0.02)`
- Run `ANALYZE` after bulk loads
- Watch `age(datfrozenxid)` per database and alert long before 2 billion (for example at 1 billion)
- Long-running transactions and abandoned replication slots stop vacuum everywhere. Find them in `pg_stat_activity` and `pg_replication_slots`
- Avoid `VACUUM FULL` on live tables. It takes an exclusive lock. Use `pg_repack` to rebuild bloated tables online

### monitor-unused-indexes (Low to medium)

```sql
SELECT schemaname, relname, indexrelname, idx_scan, pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC
```

Check replicas too before dropping, since stats are per server. Unique and primary key indexes stay even when unused for reads.

### monitor-fk-without-index (Medium)

```sql
SELECT c.conrelid::regclass AS table_name, a.attname AS column_name
FROM pg_constraint c
JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = c.conkey[1]
WHERE c.contype = 'f'
  AND NOT EXISTS (
    SELECT 1 FROM pg_index i
    WHERE i.indrelid = c.conrelid AND i.indkey[0] = c.conkey[1]
  )
```

### monitor-blocking (Medium)

Find who is blocking whom during an incident:

```sql
SELECT pid, pg_blocking_pids(pid) AS blocked_by, state, wait_event_type,
       now() - xact_start AS xact_age, left(query, 100) AS query
FROM pg_stat_activity
WHERE cardinality(pg_blocking_pids(pid)) > 0
```

### monitor-cache-hit (Low to medium)

```sql
SELECT round(100.0 * sum(blks_hit) / nullif(sum(blks_hit) + sum(blks_read), 0), 2) AS cache_hit_pct
FROM pg_stat_database
```

Busy OLTP databases usually sit above 99 percent. A drop means the working set no longer fits in memory.

### monitor-replication-lag (Low to medium)

On the primary:

```sql
SELECT application_name, state, replay_lag FROM pg_stat_replication
```

Route read-your-own-writes traffic to the primary when lag is high.

The `pg-diagnose` script runs these checks read-only in one go.

## 8. Advanced Features

### adv-jsonb-index (Low)

GIN with `jsonb_path_ops` serves containment (`@>`) queries. For a single hot key, an expression B-tree index is smaller:

```sql
CREATE INDEX CONCURRENTLY events_payload_gin ON events USING gin (payload jsonb_path_ops)
```

```sql
CREATE INDEX CONCURRENTLY events_payload_type_idx ON events ((payload ->> 'type'))
```

Anything you filter or join on often deserves a real column.

### adv-full-text (Low)

A generated `tsvector` column with a GIN index beats `ILIKE` for word search:

```sql
ALTER TABLE articles ADD COLUMN search tsvector
  GENERATED ALWAYS AS (to_tsvector('english', coalesce(title, '') || ' ' || coalesce(body, ''))) STORED
```

```sql
CREATE INDEX CONCURRENTLY articles_search_idx ON articles USING gin (search)
```

Query with `search @@ websearch_to_tsquery('english', $1)`.

### adv-pgvector (Low)

Use an HNSW index for approximate nearest neighbor search, and filter selectively before or alongside the vector search. Store the embedding model and dimension with the data so you can re-embed later.

### adv-materialized-view (Low)

Materialized views precompute heavy reports. `REFRESH MATERIALIZED VIEW CONCURRENTLY` keeps it readable during refresh but needs a unique index on the view.

### adv-listen-notify (Low)

`LISTEN` and `NOTIFY` are fine for small, best-effort signals. Notifications are lost while no listener is connected, and `LISTEN` needs a dedicated session (not transaction pooling). For durable work, use a jobs table or a queue.

## MySQL Notes

| Postgres rule | MySQL 8 equivalent |
|---------------|--------------------|
| `EXPLAIN (ANALYZE, BUFFERS)` | `EXPLAIN ANALYZE` (8.0.18 and later), `EXPLAIN FORMAT=JSON` |
| `pg_stat_statements` | `performance_schema.events_statements_summary_by_digest`, the slow query log |
| `statement_timeout` | `max_execution_time` (SELECT only), `innodb_lock_wait_timeout`, `lock_wait_timeout` for DDL |
| `CREATE INDEX CONCURRENTLY` | Online DDL with `ALGORITHM=INPLACE, LOCK=NONE`, or gh-ost and pt-online-schema-change |
| `timestamptz` | `DATETIME` storing UTC by convention, or `TIMESTAMP` (ends in 2038) |
| `ON CONFLICT` | `INSERT ... ON DUPLICATE KEY UPDATE` |
| `FOR UPDATE SKIP LOCKED` | Same syntax (8.0 and later) |
| Partial index | Not supported. Use a generated column plus an index |
| Expression index | Functional key parts (8.0.13 and later) |

InnoDB clusters rows by primary key, so a random primary key (UUIDv4) hurts even more than in Postgres. Foreign keys get an index automatically in InnoDB.
