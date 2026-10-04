# Backend Build Rules

These rules apply whenever you create or change server code: endpoints, services, queries, models, migrations, jobs, config. B1 to B15 are hard rules. Break one only when the user explicitly asks for that exact thing, and say so in the Rules Check.

The scan tags after each rule title are what `scripts/backend-scan.*` reports for application code and what `scripts/db-lint.*` reports for SQL migrations and Prisma schemas. Rules with no tag need a human read.

## B1: Authenticate Every Route, Deny by Default

Scan: `weak-password-hash`

- Every route requires authentication unless it is on an explicit public allowlist (health checks, login, signup, public content). New routes are private by default because the auth middleware is global, not opt-in per route
- Passwords use argon2id (OWASP minimum m=19456 KiB, t=2, p=1), or scrypt, or bcrypt cost 10 or more with the 72 byte limit handled. Never MD5, SHA-1 or a bare SHA-2 hash
- Login, signup, password reset and token endpoints are rate limited per account and per IP, return generic errors that do not reveal whether an account exists, and compare secrets in constant time
- Sessions are opaque random ids in `HttpOnly`, `Secure`, `SameSite` cookies, rotated on login and privilege change. Access tokens are short-lived (5 to 15 minutes) with rotating refresh tokens. JWTs are verified with an algorithm allowlist plus `iss`, `aud` and `exp` checks
- Use a proven library or identity provider. Never hand-roll crypto, token formats or OAuth flows

Details: [topics/authentication.md](topics/authentication.md)

## B2: Authorize Every Object, Function and Field

Scan: `unscoped-lookup`, `client-authority`, `mass-assignment`

- **Object level (OWASP API1).** Every read, update or delete of a record checks that the caller may access that record. Scope it in the query itself (`WHERE id = $1 AND tenant_id = $2`) instead of fetching first and checking later. Lists filter in the query, never after pagination
- **Function level (API5).** Admin and privileged operations check the role or permission on the server, in one central policy layer, not only by hiding UI
- **Property level (API3).** Writes accept an allowlist of fields. Never pass the raw body to `create` or `update`. Reads return a response DTO that leaves out fields the caller may not see
- Identity, role, tenant and owner come from the authenticated principal, never from the body, query or a client header
- Return 404 for records outside the caller's scope so their existence does not leak
- Enforce the same policy in every entry point: HTTP, GraphQL resolvers, websockets, jobs and admin scripts

Details: [topics/authorization.md](topics/authorization.md)

## B3: Validate Input at the Boundary, Shape Output on Purpose

- Every input (body, query, path params, headers, uploaded files, queue messages, webhook payloads) passes a schema before business logic runs: types, required fields, lengths, ranges, formats, enums, array sizes. Unknown fields are rejected or stripped
- Global limits on body size, header size, JSON depth and upload size
- Validation failures return 400 or 422 with field-level problem details
- Responses come from an explicit serializer or DTO per endpoint. Never return an ORM entity or a raw row, which leaks columns like `password_hash` the day someone adds them

Details: [topics/validation.md](topics/validation.md), [topics/api-design.md](topics/api-design.md)

## B4: No N+1 Queries

Scan: `query-in-loop`, `http-in-loop`

- Never run a query, or call another service, once per item in a loop, a `map`, a comprehension or a serializer field. Load related data with eager loading (a join or one `IN` query per relation), batch by ids, or aggregate in SQL
- GraphQL resolvers use a per-request DataLoader
- Turn on the framework's lazy-load guard in development and tests (Rails `strict_loading`, Laravel `preventLazyLoading`, SQLAlchemy `raiseload`, Django `nplusone` or `assertNumQueries`, Hibernate `default_batch_fetch_size` plus statistics)
- The number of queries per request is constant, not proportional to the number of rows. Prove it with a query-count test for list endpoints
- Writes in bulk use bulk insert or upsert, not one statement per row

Details: [topics/database.md](topics/database.md), [stack-notes.md](stack-notes.md)

## B5: Every Query Is Bounded, Paginated and Lean

Scan: `unbounded-query`, `select-star`, `offset-pagination`

- Every list endpoint paginates on the server with a default page size (20 is typical) and a hard maximum (100 is typical). No endpoint returns a whole table
- Large or infinite lists use keyset (cursor) pagination with a stable sort and a unique tiebreaker (`ORDER BY created_at DESC, id DESC`). Offset is fine for small, bounded admin lists
- Select only the columns the endpoint returns. No `SELECT *` in application queries
- Filtering, sorting and aggregation happen in the database, on allowlisted fields
- Exports and batch jobs stream or iterate in chunks instead of loading everything into memory

Details: [topics/database.md](topics/database.md), [topics/api-design.md](topics/api-design.md)

## B6: Index and Constrain in the Database

Scan: `blocking-index`. DB lint: `index-not-concurrent`, `concurrent-in-transaction`, `constraint-validates-under-lock`, `unique-under-lock`, `set-not-null`, `column-type-change`, `volatile-default`, `not-null-without-default`, `rename`, `drop`, `unbatched-write`, `heavy-lock`, `no-lock-timeout`, `fk-without-index`, `missing-primary-key`, `json-not-jsonb`, `char-column`

- Every hot query has an index that matches its `WHERE`, `JOIN` and `ORDER BY`, checked with `EXPLAIN` (`EXPLAIN ANALYZE` on a realistic data volume). Composite indexes put equality columns first, then the sort or range column
- Foreign key columns are indexed (Postgres does not do it for you)
- Integrity lives in the schema: `NOT NULL`, `UNIQUE`, foreign keys and `CHECK` constraints back up the application checks. Unique business rules (one active subscription per user) are unique indexes, not a read-then-write
- Migrations are safe on a live table: create indexes concurrently, add constraints as `NOT VALID` then validate, backfill in batches, and set a `lock_timeout`. Schema changes follow expand then contract so the old and new app versions both work during deploy

Details: [topics/database.md](topics/database.md), [topics/migrations.md](topics/migrations.md)

## B7: Transactions, Concurrency and Idempotency

- Writes that must succeed or fail together run in one transaction. Transactions stay short and never wrap network calls, emails or slow work
- Read-modify-write on shared state is never a separate read then write. Use an atomic update (`SET stock = stock - 1 WHERE id = $1 AND stock >= 1` and check the affected row count), optimistic locking with a version column, or `SELECT ... FOR UPDATE` for short critical sections
- Unsafe operations with side effects that matter (payments, orders, sends) accept an `Idempotency-Key` and return the stored result on retry
- A database write plus a message or event uses a transactional outbox, not a write then a publish that can half fail. Jobs are enqueued after commit
- Consumers of queues and webhooks are idempotent because delivery is at least once

Details: [topics/concurrency.md](topics/concurrency.md)

## B8: Timeouts, Retries and Limits on Every Call

Scan: `no-timeout`

- Every outbound call (HTTP, database, cache, queue, SMTP) has a connect timeout and an overall timeout shorter than the caller's own deadline. Databases get a `statement_timeout` or the driver equivalent
- Retries only for transient failures on idempotent operations, with exponential backoff, full jitter and a small cap (about 3 attempts). Retry at one layer only. Honor `Retry-After`
- A dependency that fails often sits behind a circuit breaker with a fallback or a fast clear error
- Inbound limits: rate limits per user, API key or IP with `429` and `Retry-After`, tighter limits on login and expensive endpoints, request body and upload size caps, server read and write timeouts
- Connection pools are sized and bounded, with an acquire timeout

Details: [topics/resilience.md](topics/resilience.md)

## B9: Structured Logs With Correlation and No Secrets

Scan: `unstructured-log`, `sensitive-log`

- Log through the project's structured logger as JSON with consistent fields: timestamp in UTC, level, message, service, request id and trace id, route, status, duration, and an opaque user or tenant id when known. No `console.log`, `print` or `fmt.Println` in server code
- Every request carries a request id and W3C `traceparent` that flows to downstream calls, jobs and every log line through context (AsyncLocalStorage, contextvars, MDC)
- Never log passwords, tokens, API keys, session ids, cookies, authorization headers, card data or full personal data. Configure redaction in the logger, not at each call site
- Log an error once, with its stack, where it is handled. Do not log and rethrow at every layer
- Security relevant actions (login, failed login, permission denied, role change, data export, admin action) go to an audit log with who, what, which resource, when, from where and the outcome

Details: [topics/logging.md](topics/logging.md)

## B10: Metrics, Traces and Health Checks

- Each service exports RED metrics per route template: request rate, error rate and a latency histogram (not an average). Label by route template, method and status class, never by user id or raw URL
- OpenTelemetry tracing covers incoming requests, database calls, outbound HTTP and queue work, with context propagated across service and queue boundaries
- Separate liveness (the process is alive, no dependency checks) and readiness (can serve traffic: database reachable, warmed up) endpoints
- Runtime saturation is visible: pool connections in use and waiting, queue depth and oldest job age, event loop lag or thread pool usage, memory and GC
- New critical paths come with an SLO or at least an alert on error rate and p99 latency

Details: [topics/observability.md](topics/observability.md)

## B11: Consistent Errors That Leak Nothing

Scan: `swallowed-error`, `bare-except`, `leaked-error`

- One central error handler maps domain errors to HTTP status codes and returns RFC 9457 problem details (`application/problem+json`) with a request id
- Unexpected errors return a generic 500 body. Stack traces, SQL, file paths, hostnames and library versions never reach the client
- Never swallow an exception. No empty `catch`, no `except: pass`, no catching everything to carry on in a half-updated state. Handle it, or let it reach the handler
- Unhandled promise rejections, panics and uncaught exceptions are logged and end the process so the supervisor restarts it cleanly

Details: [topics/errors.md](topics/errors.md)

## B12: Slow Work Leaves the Request Path, Nothing Blocks

Scan: `blocking-call`

- Emails, notifications, outbound webhooks, file processing, report generation and third-party syncs run in a durable job queue. The request returns 201 or 202 quickly
- Jobs carry ids, not objects, are idempotent, retry with backoff, have a timeout and a dead letter queue, and are observable (queue depth, failures, age)
- Request handlers never block the event loop or a worker: no `readFileSync`, `execSync`, synchronous hashing or `time.sleep` in a request path, no `.Result` or `.Wait()` on async work. CPU-heavy work goes to a worker pool or a job
- Independent I/O in one request runs concurrently with a concurrency limit, not as a chain of sequential awaits

Details: [topics/async-jobs.md](topics/async-jobs.md), [topics/performance.md](topics/performance.md)

## B13: Config From the Environment, Checked at Startup, Clean Shutdown

Scan: `credentials-in-dsn`, `secret-fallback`

- All config comes from the environment or a secrets manager through one typed config module that validates everything at startup and refuses to boot when something is missing or malformed
- No secrets in code, in committed config, or as fallback defaults (`process.env.JWT_SECRET || "dev"`). No credentials inside connection strings in source
- The same build artifact is promoted through every environment. Only config changes
- On `SIGTERM` the service fails readiness, stops accepting new work, finishes in-flight requests and jobs within a deadline, closes pools and flushes telemetry, then exits

Details: [topics/config-deploy.md](topics/config-deploy.md), [topics/resilience.md](topics/resilience.md)

## B14: Correct Types for Money, Time and Identity

Scan: `float-money`, `naive-datetime`. DB lint: `float-money`, `timestamp-without-tz`, `random-uuid-key`

- Money is an integer count of minor units (cents) or a fixed-point `DECIMAL` or `NUMERIC`, always paired with a currency code. Never a float. Rounding is explicit and happens once
- Timestamps are stored in UTC with a time zone aware type (`timestamptz` in Postgres) and exchanged as ISO 8601 with an offset. Convert to local time only at the edge. Durations use a monotonic clock
- Primary keys are `bigint` identity or time-ordered UUIDv7 (RFC 9562), not random UUIDv4 on hot tables. Do not expose guessable sequential ids where enumeration matters. 64-bit ids go to JavaScript clients as strings
- Text is UTF-8 end to end. Email and username uniqueness uses a normalized form (case folded) with a matching unique index

Details: [topics/database.md](topics/database.md), [topics/api-design.md](topics/api-design.md)

## B15: Prove It With Tests

- Integration tests run against a real database of the same engine and version (Testcontainers or a disposable instance) with the real migrations, not an in-memory substitute
- An authorization matrix test covers each role against each endpoint, including another user's and another tenant's records, and expects the denial
- List endpoints have a query-count assertion that stays flat as rows grow
- Concurrency-sensitive paths (stock, balance, unique claims) have a test that fires parallel requests and checks the invariant
- Idempotent endpoints have a test that sends the same key twice
- Hot endpoints get a load smoke test with thresholds before release (see [load-testing.md](load-testing.md))

Details: [topics/testing.md](topics/testing.md)

## Rules Check Format

End a build with:

```
Rules Check
B1 auth ............ pass (global middleware, /orders is private)
B2 authz ........... pass (scoped by user_id in query, DTO allowlist)
B4 N+1 ............. pass (include items, 2 queries per request at 20 and 200 rows)
B6 indexes ......... still open (orders.created_at has no index, migration added but not run)
B10 metrics ........ not applicable (no metrics stack in this project yet)
...
```

Keep each line short and specific. "pass" needs a reason a reviewer can check.
