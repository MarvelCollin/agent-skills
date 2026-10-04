# Design Mode

Design a new service, a large feature, or a significant change before code exists. The output is a short design doc that Build mode then follows. Use it when the user asks how to build or architect something, when a feature touches several tables, services or queues, or when a choice (database, sync or async, monolith or service) will be expensive to undo.

Write the design to `backend-design-<slug>-<YYYYMMDD>/design.md` (gitignored) from [../templates/design-template.md](../templates/design-template.md), unless the user wants it in the repo (`docs/adr/` or `docs/design/`).

## 1. Ask the Forcing Questions

Every architecture choice depends on a few facts. Get them before recommending anything. Infer what you can from the code, config and the user's words first. Ask only what is still unknown, at most four at a time, and always offer a recommended answer so the user can just accept it. If the user says "just decide", pick sensible defaults and list them as assumptions in the doc.

| # | Question | Why it matters | Kill criterion |
|---|----------|----------------|----------------|
| 1 | Peak requests per second now and in 12 months, and the read to write ratio | Drives database, cache, queue and partitioning choices | "It needs to scale" with no number. Estimate from current users and usage (step 2) instead of guessing |
| 2 | Data size now, growth per month, retention | Drives indexing, partitioning, archiving, backup time | None. Estimate if unknown |
| 3 | Tenancy: single user, shared multi-tenant with row isolation, or isolated per tenant | Decides the data access pattern, hard to change later | Isolated tenants for every customer without enterprise pricing to pay for it |
| 4 | Data sensitivity: public, internal, personal, health, payment card | Sets the compliance floor: encryption, audit, residency, scope | Health or card data with no named owner for compliance. Stop and flag it, and prefer providers (Stripe, an identity provider) that keep you out of scope |
| 5 | Which operations must be strongly consistent, and which can lag | Picks transactions and locks versus events and caches | None |
| 6 | Latency targets per key journey (p95, p99), availability SLO, RPO and RTO | Turns "fast and reliable" into checkable numbers | Customer data with no RPO and RTO. Define them before launch |
| 7 | Team size, who is on call, the existing stack and infrastructure | Reuse beats novelty. Small teams cannot run many services | Microservices or event-driven everything for a team under about 20 engineers without a platform team. Use a modular monolith |

## 2. Estimate Capacity

Back-of-envelope math, shown in the doc:

- Requests per second = daily active users times requests per user per day divided by 86,400, times a peak factor (3 to 10)
- Storage per year = rows per day times average row size times 365, plus indexes (often 50 to 100 percent extra)
- Concurrency (Little's law) = requests per second times average latency in seconds
- Database connections needed = concurrency that touches the database times the share of request time spent in the database

Example: 50,000 daily users times 40 requests is 2 million a day, about 23 per second, about 140 per second at a 6x peak. At 120 ms average, about 17 requests are in flight. One Postgres primary handles that easily.

Most products fit on one well-indexed Postgres primary, a cache and a job queue for years. Say so when the numbers show it.

## 3. Choose the Shape

Default: a modular monolith on Postgres, with Redis for cache and rate limits and a durable job queue for slow work. Deviate only with a reason the numbers or constraints support:

| Need | Choice |
|------|--------|
| Independent deploys by separate teams, very different scaling or runtime needs | Extract a service along a bounded context |
| Heavy reads with tolerable staleness | Cache, then read replicas, then read models |
| Write volume beyond one primary | Batch and queue writes, partition by tenant or key, then shard |
| Long multi-step business processes with waits and retries | A workflow engine (Temporal, Step Functions) or a saga |
| Full-text relevance, facets | Postgres full-text first, a search engine when relevance tuning matters |
| Event history as the source of truth (audit, replay) | Event sourcing, only where the domain needs it |
| Real-time push to clients | SSE or WebSockets with a pub/sub backbone (see [topics/realtime.md](topics/realtime.md)) |

Record each significant choice as an ADR in the doc: context, options considered, decision, consequences.

## 4. Model the Data

Start from access patterns, not entities:

1. List every query the feature runs: the filter, the sort, the expected rows, how often
2. Design tables and relationships that serve them, with constraints (`NOT NULL`, `UNIQUE`, foreign keys, `CHECK`)
3. Derive the indexes from the query list. Each hot query names its index
4. Add the tenancy column and its index where tenancy applies
5. Pick types per [postgres.md](postgres.md) `schema-types`: `timestamptz`, money in minor units, `bigint` identity or UUIDv7 keys
6. Plan how the data evolves: migrations with expand and contract, backfills, retention

## 5. Define the API Contract

Write the contract before the code, starting from [../templates/openapi-starter.yaml](../templates/openapi-starter.yaml):

- Resources, methods and status codes per [topics/api-design.md](topics/api-design.md)
- Request and response schemas, with limits on every string and array
- Cursor pagination on lists, with a default and maximum `limit`
- `Idempotency-Key` on unsafe POSTs with side effects that matter
- RFC 9457 problem details for every error
- Who may call each operation and on which objects (feeds B1 and B2)

## 6. Plan for Failure

For each dependency, fill a row:

| Dependency | If slow | If down | If it answers twice | Timeout | Retry | Fallback |
|------------|---------|---------|---------------------|---------|-------|----------|
| Payment provider | Fail the request after 3 s | Order stays pending, job retries | Idempotency key dedupes | 3 s | 2 with jitter | None, clear error |
| Recommendation service | Skip the section | Cached popular items | Harmless | 300 ms | 0 | Cache |

Also cover: what happens during deploys (two versions at once), when the queue backs up, and when a tenant is ten times bigger than the rest.

## 7. Security, Observability, Rollout

- **Security:** authentication method, authorization model and policy location, data classification, audit events, secrets, rate limits on abuse-prone flows
- **Observability:** SLIs per key journey, the SLO, alerts with runbooks, dashboards, the logs and traces you need to debug it
- **Rollout:** migration order, feature flag, load test plan with pass criteria ([load-testing.md](load-testing.md)), canary, rollback triggers

## 8. Success Criteria

A design is not done until it states, in numbers:

- Latency targets (p50, p95, p99) for each key journey
- The availability SLO
- RPO and RTO for the data it stores
- The capacity it is built for and the first bottleneck expected beyond that

## 9. Checkpoint

Present a summary (shape, data model, API surface, top risks, open questions) and wait for approval before building anything that is costly to undo: schema, public API, new infrastructure. Small, reversible features can go straight to Build mode with the design written as the short "settle and state" step.

Then build with [build-rules.md](build-rules.md), using the design as the source for the Rules Check.
