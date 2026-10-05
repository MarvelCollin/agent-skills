# Backend Essentials Checklist

A fast pass over a backend against five groups: Maintenance, Security, Database Speed, Caching and Response Speed. Each item maps to a build rule or topic file and says what proof counts. Use it when the user asks for "the essentials", a quick health check, or a pre-launch pass. For a scored deep review use [review.md](review.md) instead.

Arguments after `checklist`: an optional path (default the current project) and an optional group (`maintenance`, `security`, `db`, `caching`, `speed`). No group means all five.

## How to Run

Stress test first. Find where the backend actually hurts before you grade anything, so the fixes follow evidence and not the order of the list.

1. **Stress test baseline** (Database Speed, Caching and Response Speed depend on it)
   - Find a target. A service the user already runs, or one you start from the project's own start command. Local and private hosts are authorized by default. Any other host needs the user to state they own it or may load test it, plus a requests per second cap. Follow the authorization rules in [load-testing.md](load-testing.md), never test a third party
   - No runnable target and no way to start one: skip this step, write `not measured` in the report, and say what you would have run. Never invent numbers
   - Pick the 3 to 5 hottest endpoints from the routes and the user (a list, a detail, a search or filter, a write, login). Use a production-sized dataset when a seed script or factory exists. On a small dev database N+1 queries and missing indexes stay hidden, so say that the numbers are optimistic
   - Run smoke first, then a stress or breakpoint run per [load-testing.md](load-testing.md) (`load-test.sh` for one endpoint, k6 for a mixed ramp). Watch the server side during the run: app CPU, event loop lag, database CPU and slow queries, pool waits, memory
   - Record the knee (the rate just before latency bends), p95 and p99 and error rate at the knee, and the resource that saturated first. Name the bottleneck with the Symptom to Cause table in [load-testing.md](load-testing.md). Keep the plan and numbers in `backend-load-<slug>-<YYYYMMDD>/`
2. Detect the stack and find the entry points, config, migrations and infrastructure files
3. Run `bash "<skill-dir>/scripts/backend-scan.sh" "<path>"` (or the `.ps1` twin) and, when migrations exist, `bash "<skill-dir>/scripts/db-lint.sh" "<migrations-path>"`. Scan output is leads, so read each one in context
4. Grade every item in the chosen groups as `pass`, `fail`, `partial` or `n/a`. A `pass` needs proof a reviewer can check: a file and line, a config value, a command output, a test name. No proof means `fail`
5. Items that live outside the repo (backups, CDN, HTTPS at the load balancer, alerts) cannot be seen from code. Mark them `unverified` and name who can confirm. Never guess `pass`
6. Rank the fixes. Failed items that explain the measured bottleneck come first (see the table below), then the rest by impact over effort. Security and Maintenance items are graded whatever the stress test showed, because load does not reveal SQL injection or a missing backup
7. After fixing the top items, rerun the same stress test and report before and after numbers

## Bottleneck to Checklist Items

| Measured at the knee | Start with these failed items |
|----------------------|-------------------------------|
| Database CPU high, app CPU low, latency grows with row count | Database Speed: indexes, composite and covering indexes, N+1, selected columns, `LIMIT`, cursor pagination, `EXPLAIN` |
| Latency climbs while CPU stays low, errors begin at an exact concurrency | Database Speed: connection pooling, transactions, query timeouts. Response Speed: request timeouts, background jobs |
| One core pinned or event loop lag | Response Speed: async I/O, background jobs, compression at the edge. Maintenance: profile slow endpoints |
| Database load tracks request rate and the same reads repeat | Caching: Redis reads, TTL, invalidation, HTTP cache headers. Database Speed: precomputed counts |
| A slow outbound dependency in the traces | Response Speed: parallel calls, request timeouts, background jobs |
| Large response bytes, bandwidth near saturation | Response Speed: compression, small payloads, pagination, image resizing. Caching: CDN |
| Sporadic 502 or 503 under load | Response Speed: keep-alive timeout order. Maintenance: health check, error monitoring |
| Login or signup is the slowest route | Security: keep password hashing off the event loop and rate limit it. Do not lower the hash cost to look faster |
| Memory climbs during a soak | Maintenance: profile slow endpoints. Caching: TTL and bounded keys |
| `429` early in the ramp | Security: rate limiting. Confirm the limits match the plan |

## Report Format

```
Backend Checklist: <project> (<date>)
Stress baseline .... knee at 180 rps on GET /orders, p99 2.1 s, database CPU saturated (N+1, 41 queries per request)
Maintenance ........ 5 of 7 pass, 1 partial, 1 unverified
Security ........... 9 of 12 pass, 3 fail
Database Speed ..... 9 of 14 pass, 5 fail
Caching ............ 2 of 6 pass, 4 n/a
Response Speed ..... 6 of 9 pass, 3 fail

Fail and partial
| Item | Status | Evidence | Fix |
|------|--------|----------|-----|
| Fix N+1 queries | fail | routes/orders.js:14 queries items per order in a loop | include items in one query (B4) |

Fix first (bottleneck items, then the rest)
1. ...

After fixes: knee 520 rps, p99 240 ms (same test, same data)
```

When nothing could be measured, the first line reads `Stress baseline .... not measured (no runnable target)` and the ranking falls back to impact over effort.

Prose in the report follows the plugin copy rule: no semicolons and no em dashes.

## Maintenance

| Item | Rule or topic | Pass when |
|------|---------------|-----------|
| Use migrations for schema changes | B6, [migrations](topics/migrations.md) | Every schema change is a versioned migration file in the repo, nothing is changed by hand in production, `db-lint` has no open findings, and risky changes follow expand then contract |
| Add health check endpoint | B10, [resilience](topics/resilience.md) | Separate liveness and readiness routes exist, readiness checks the database, both skip auth, and neither does heavy work |
| Add logging | B9, [logging](topics/logging.md) | One structured JSON logger with request id and redaction, no `console.log` or `print` in server code (`unstructured-log`, `sensitive-log` are clean) |
| Add error monitoring | B10, B11, [observability](topics/observability.md) | Unhandled errors and panics reach a tracker (Sentry or similar) with release and request id, PII is scrubbed, and an alert fires on a new error type or an error rate spike |
| Back up database regularly | [config-deploy](topics/config-deploy.md) Backups and Recovery | Automated backups with point-in-time recovery, encrypted, stored in a separate account or region, and a restore was tested within the last quarter. Usually `unverified` from code |
| Write tests | B15, [testing](topics/testing.md) | Integration tests hit a real database of the same engine, an authorization matrix test exists, and CI runs them on every push |
| Profile slow endpoints | [performance](topics/performance.md), B10 | p95 and p99 per route template are visible, slow query logging or `pg_stat_statements` is on, and the slowest routes have a profile or trace taken before any tuning |

## Security

| Item | Rule or topic | Pass when |
|------|---------------|-----------|
| Hash and salt passwords (bcrypt or argon2) | B1, [authentication](topics/authentication.md) | argon2id, scrypt or bcrypt with cost 10 or more. The library salts per hash, so no hand-made salt scheme. `weak-password-hash` is clean |
| Add rate limiting | B8, [resilience](topics/resilience.md) | Global limit per user, key or IP with `429` and `Retry-After`, plus tighter limits on login, signup, password reset and expensive routes. The limit store is shared across instances |
| Use parameterized queries | [security-baseline](topics/security-baseline.md) Injection, [database](topics/database.md) | No SQL built by concatenating or interpolating input. Dynamic sort columns and table names come from an allowlist. Raw query helpers receive bind parameters. The scan does not tag this, so read each raw query call by hand |
| Validate and sanitize all input | B3, [validation](topics/validation.md) | Every body, query, path, header and file passes a schema before logic runs, unknown fields are rejected, and size limits are set |
| Store secrets in env vars | B13, [config-deploy](topics/config-deploy.md) | One typed config module validates at startup, no secrets in the repo or as fallbacks, `.env` is gitignored (`secret-fallback`, `credentials-in-dsn` are clean) |
| Force HTTPS | [security-baseline](topics/security-baseline.md) Transport and Headers | HTTP redirects to HTTPS, `Strict-Transport-Security` is sent, and the app trusts the proxy's forwarded protocol header correctly. Often `unverified` from code |
| Set CORS whitelist | [security-baseline](topics/security-baseline.md) Transport and Headers | An explicit list of allowed origins, never `*` together with credentials, and the `Origin` header is not reflected back unchecked |
| Use httpOnly and secure cookies | B1 | Session and refresh cookies set `HttpOnly`, `Secure` and `SameSite`, and no token lives in `localStorage` |
| Add JWT expiry and refresh tokens | B1, [authentication](topics/authentication.md) | Access tokens last 5 to 15 minutes, refresh tokens rotate and can be revoked, and verification pins the algorithm and checks `iss`, `aud` and `exp` |
| Keep secrets, env values and sessions out of the browser | B16, [client-trust](topics/client-trust.md) | No secret behind a public env prefix (`NEXT_PUBLIC_`, `VITE_`, `REACT_APP_` and similar), no key in the client bundle or build output, production source maps are not public, no token in `localStorage` or a script-set cookie, and no env dump or debug page in production (`public-env-secret`, `env-exposed`, `sourcemap-public`, `token-in-web-storage` are clean) |
| Never trust role, price, owner or status sent by the client | B17, [client-trust](topics/client-trust.md) | Role, tenant, owner and plan come from the session. Totals and prices are computed from server data. Status and workflow steps change only through server transitions. Tokens are verified, not only decoded. Tamper tests prove a forged field is ignored or rejected (`client-authority`, `client-value`, `client-header`, `jwt-unverified` are clean) |
| Never return stack traces to users | B11, [errors](topics/errors.md) | One central handler returns a generic 500 body with a request id, and debug mode is off in production (`leaked-error` is clean) |

## Database Speed

| Item | Rule or topic | Pass when |
|------|---------------|-----------|
| Add indexes on searched and filtered columns | B6, [database](topics/database.md) | Every `WHERE`, `JOIN` and `ORDER BY` column on a hot query is indexed, foreign keys included, confirmed with `EXPLAIN` |
| Add composite indexes for common query combos | B6, [postgres](postgres.md) | Multi-column filters use one composite index with equality columns first, then the range or sort column |
| Use covering indexes for hot queries | [postgres](postgres.md) | The few hottest read queries use `INCLUDE` columns and show an index-only scan in `EXPLAIN` |
| Fix N+1 queries | B4 | Query count per request stays flat as rows grow. Proven by a query-count test or SQL logging (`query-in-loop`, `http-in-loop` are clean) |
| Select only needed columns, avoid `SELECT *` | B5 | Queries name their columns (`select-star` is clean) |
| Use `LIMIT` on every list query | B5 | Every list has a default and a maximum page size (`unbounded-query` is clean) |
| Use cursor pagination instead of `OFFSET` | B5 | Large or growing lists use keyset pagination with a unique tiebreaker (`offset-pagination` is clean) |
| Batch inserts and updates | B4, [database](topics/database.md) | Bulk writes use multi-row insert, upsert or `COPY`, never one statement per row in a loop |
| Use connection pooling | B8, [database](topics/database.md) | One bounded pool per process, sized against the database's `max_connections` across all instances, with an acquire timeout. A pooler such as PgBouncer sits in front when instances are many |
| Precompute counts and totals | [database](topics/database.md), [caching](topics/caching.md) | Hot counts and totals come from a counter column, summary table or materialized view, not `COUNT(*)` over a big table on every request |
| Denormalize hot read data | [database](topics/database.md) | Any denormalized copy has one named owner that updates it, and a way to rebuild it. Only done after a measurement showed the join was the cost |
| Check slow queries with `EXPLAIN` | B6, [postgres](postgres.md) | The slowest queries from `pg_stat_statements` or the slow log have an `EXPLAIN (ANALYZE, BUFFERS)` plan on realistic data |
| Set query timeouts | B8 | `statement_timeout` or the driver equivalent is set, shorter than the request deadline |
| Wrap related writes in transactions | B7, [concurrency](topics/concurrency.md) | Writes that must succeed together share one short transaction, with no network calls inside it |

## Caching

Mark the whole group `n/a` with a one-line reason when the measured read load does not need it. Caching adds invalidation bugs, so it is not a default.

| Item | Rule or topic | Pass when |
|------|---------------|-----------|
| Cache frequent reads in Redis | [caching](topics/caching.md) Patterns | The hottest read-heavy, rarely changing lookups use cache-aside with a bounded key space, stampede protection and a fallback to the database when Redis is down |
| Cache sessions in Redis | [authentication](topics/authentication.md), [caching](topics/caching.md) | When sessions are server-side, they live in a shared store with an expiry, not in process memory, so any instance can serve any user |
| Add HTTP cache headers (`Cache-Control`, `ETag`) | [caching](topics/caching.md) HTTP Caching | Public data sends `Cache-Control` and `ETag` with `304` support. Private or per-user responses send `private` or `no-store`, and `Vary` is correct |
| Use a CDN for static files and images | [caching](topics/caching.md) Layers | Static assets and uploaded images are served from object storage behind a CDN with fingerprinted file names and long immutable caching. Often `unverified` from code |
| Set cache expiry (TTL) | [caching](topics/caching.md) Invalidation and Stampedes | Every cache write sets a TTL with jitter. No key lives forever by accident |
| Invalidate cache on update | [caching](topics/caching.md) Invalidation | Each write path that changes cached data deletes or updates the key after commit, and the TTL is the backstop for any missed path |

## Response Speed

| Item | Rule or topic | Pass when |
|------|---------------|-----------|
| Compress responses (gzip or brotli) | [performance](topics/performance.md) Compression and Connections | Text responses over about 1 KB are compressed at the proxy or app, with `Vary: Accept-Encoding`, and images and archives are skipped |
| Keep JSON payload small | B3, B5 | Responses come from a DTO per endpoint, list views return summary fields only, and heavy fields sit behind a detail route or a `fields` parameter |
| Paginate all list endpoints | B5 | No list returns an unbounded result (`unbounded-query` is clean) |
| Enable HTTP/2 or keep-alive | [performance](topics/performance.md) Compression and Connections | The edge speaks HTTP/2 or HTTP/3, and the app's keep-alive timeout is longer than the proxy's idle timeout so reused connections do not hit 502 |
| Use async and non-blocking I/O | B12 | No sync file, crypto or sleep calls and no blocking waits on a request path (`blocking-call` is clean) |
| Move slow tasks to background jobs | B12, [async-jobs](topics/async-jobs.md) | Email, image processing, reports and third-party syncs run in a durable queue. The request returns 201 or 202 |
| Run independent calls in parallel | B12, [performance](topics/performance.md) | Independent reads in one handler use `Promise.all`, `gather` or `errgroup` with a concurrency limit |
| Add request timeouts | B8, [resilience](topics/resilience.md) | Server read and write timeouts are set, and every outbound call has a timeout shorter than the caller's deadline (`no-timeout` is clean) |
| Resize and compress images on upload | [validation](topics/validation.md) File Uploads | Uploads are capped by bytes and pixels, then resized into bounded variants and re-encoded (WebP or AVIF) by a background job. List views never load the original |
