# Backend Review

Review an existing backend for production readiness: correctness, authorization, performance at real data volume, reliability and operability. This reads code and, when the app runs locally, measures it. For attack testing of a live app, use `/security`.

Create `backend-review-<slug>-<YYYYMMDD>/` in the current directory (gitignored) with:

- `map.md`: the system map from step 1
- `scan.txt`: raw output of the scan
- `findings.md`: confirmed findings in the format below
- `evidence/`: query logs, EXPLAIN output, traces, load numbers
- `report.md`: the final report from [../templates/review-template.md](../templates/review-template.md)

## Diff Review

For `review diff [base]` (a branch or PR before merge), review only what changed. No review folder and no score.

1. List the changed files: `git diff --name-only --diff-filter=AMR <base>...HEAD` plus uncommitted changes from `git diff --name-only HEAD`. The base defaults to the main branch
2. Scan them in one call. Pass the source files to `backend-scan` and the migration or schema files to `db-lint` (several paths are allowed: separate arguments, or `-Path "a,b"` on PowerShell). Non-source files are skipped
3. Read the full diff, then the surrounding code each change depends on: the route's middleware, the query's callers, the migration's table
4. Check every changed endpoint, query, migration and job against B1 to B15, and confirm each finding with the five gates below
5. Report: findings most severe first in the finding format, then what looks good, then a verdict: **approve**, **approve with fixes** (Low and Medium only), or **changes requested** (any Critical or High)

## 1. Map the System

Before judging anything, write `map.md`:

- **Stack:** language, framework, ORM, database, cache, queue, hosting
- **Entry points:** HTTP routes (list them with method and path), GraphQL schema, websocket handlers, job workers, cron jobs, CLI scripts
- **Auth:** how identity is established, where authorization decisions live, the roles and tenancy model
- **Data:** main tables or collections, their relationships, the largest tables, the migration tool
- **Dependencies:** every outbound call (databases, caches, third-party APIs, internal services)
- **Cross-cutting layers:** error handler, logger, config loader, metrics and tracing setup, health checks
- **Hot paths:** the endpoints that matter most by traffic or business value. Ask the user if it is not obvious

Prefer the router file, the middleware chain and the data access layer over reading every file.

## 2. Run the Scan

```bash
bash "<skill-dir>/scripts/backend-scan.sh" "<path>" > "<review-dir>/scan.txt"
```

On Windows without bash:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill-dir>/scripts/backend-scan.ps1" -Path "<path>"
```

Then lint the migrations and schema files (SQL and Prisma) the same way:

```bash
bash "<skill-dir>/scripts/db-lint.sh" "<migrations-or-schema-path>" >> "<review-dir>/scan.txt"
```

On Windows: `powershell -NoProfile -ExecutionPolicy Bypass -File "<skill-dir>/scripts/db-lint.ps1" -Path "<path>"`. It flags migrations that lock or rewrite live tables, foreign keys without an index, tables without a primary key, and wrong types for money, time and keys.

Each line is `<rule> <check> <file>:<line>: <code>`. These are leads, not findings. The scan skips tests, vendored code and build output. It cannot see lazy-loaded relations in templates or serializers, missing indexes, or missing authorization on routes that do no lookup, so the manual walk in step 3 is where most real findings come from.

## 3. Walk Each Area

Work through the areas in the scoring table below. For each, read the hot paths end to end and check the matching build rule in [build-rules.md](build-rules.md) and its topic file. Questions that find the most issues:

- **Authentication:** Is the auth middleware global or opt-in? Which routes skip it and should they? How are passwords hashed? Are tokens verified fully?
- **Authorization:** Pick three object endpoints and trace the id from the URL to the query. Is ownership or tenancy in the `WHERE`? Can a body field set `role`, `tenant_id` or `owner_id`? Do admin routes check the permission on the server?
- **Input and API contract:** Is there a schema on every input? Body size limit? Do responses go through DTOs? Are status codes and error shapes consistent?
- **Data access:** For each list endpoint, count queries for 1 row and for 50 rows. Any serializer or template touching a relation? Any unbounded query?
- **Schema and migrations:** Do hot queries have matching indexes? Foreign keys indexed? Constraints present? Would the last five migrations lock a big table?
- **Concurrency:** Find every read-then-write on shared state (stock, balance, counters, unique claims). Are payment and order creation idempotent? Is any job enqueued inside a transaction?
- **Resilience:** Does every outbound client have a timeout? Where are retries, and are they bounded with jitter? Rate limits on login and expensive routes? Graceful shutdown?
- **Caching and performance:** What is cached, with what key, TTL and invalidation? Can a cache key mix up users or tenants? Any sync blocking call in a handler? Sequential awaits that could run concurrently?
- **Logging:** Structured? Request id on every line? Any secret or personal data logged? Audit log for sensitive actions?
- **Observability:** RED metrics? Tracing? Liveness and readiness separate? Can you tell from telemetry alone why a request was slow?
- **Errors:** One handler? Problem details? Empty catches? Stack traces in responses? Unhandled rejection handling?
- **Config and operations:** Config validated at startup? Secrets in code or defaults? Container runs as non-root with resource limits? Backups tested?
- **Testing:** Integration tests on a real database? Authorization tests that expect denial? Query-count tests? Any load test?

## 4. Measure When You Can

When the app can run locally, measure instead of guessing:

- **Query counts:** turn on SQL logging (see [stack-notes.md](stack-notes.md)) and call each list endpoint with small and large data. A count that grows with rows is a confirmed N+1
- **Query plans:** run `EXPLAIN (ANALYZE, BUFFERS)` (Postgres) or `EXPLAIN ANALYZE` (MySQL 8) on hot queries against realistic volume. Seed data if the dev database is tiny, because missing indexes do not show on 50 rows. Save plans to `evidence/`
- **Top queries:** if `pg_stat_statements` or the slow query log is available, list the top ten by total time
- **Latency:** a short smoke load test from [load-testing.md](load-testing.md) on the two or three hottest endpoints

## 5. Confirm Each Finding

A lead becomes a finding only when it passes all of these:

1. **Reachable.** The code runs in a real request, job or deploy path. Dead code is a note
2. **Not handled elsewhere.** No global middleware, base repository scope, ORM default, database constraint or gateway already covers it. Check before you claim
3. **Real impact.** You can state the consequence in user or business terms: another tenant's data exposed, p99 grows with data size, double charge on retry, outage when a dependency hangs, secrets in the log store
4. **Evidence.** A code path from entry to problem with `file:line`, or a measurement (query log, plan, trace, load numbers)
5. **Concrete fix.** A specific change in the project's own idiom, not "add caching"

## Severity

| Severity | Meaning | Examples |
|----------|---------|----------|
| Critical | Data exposure across users or tenants, data loss or corruption, or an outage under normal load | IDOR on invoices, race that oversells stock, migration that locks the orders table for minutes |
| High | Outage or severe slowdown at expected peak, a security control missing on a sensitive path, secrets exposed in logs | N+1 on the main list endpoint, no timeout on the payment provider, tokens logged |
| Medium | Degrades at growth or makes incidents hard to handle | Offset pagination on a growing table, no request ids, missing readiness probe |
| Low | Hygiene with small direct impact | `SELECT *` on a narrow table, inconsistent error shape on one route |
| Info | Suggestion or good practice to keep | A place where a cache would pay off later |

## Finding Format

```markdown
### [SEV] <short title>

- **Severity:** Critical / High / Medium / Low / Info
- **Area:** <area from the scoring table>, rule B<n>
- **Location:** <file:line or endpoint>
- **Summary:** what is wrong, in one or two sentences

**Impact.** What happens to users, data, cost or uptime, and when.

**Evidence.** The code path or measurement. Point to `evidence/` files.

**Fix.** The specific change, with a short code sketch in the project's idiom.

**Verify.** How to prove the fix worked (a test, a query count, a plan, a load number).
```

## Scoring

Grade each area from 0 to 4, then compute the weighted score out of 100.

| Grade | Meaning |
|-------|---------|
| 4 | Expert. Rule followed everywhere, enforced by tooling or tests |
| 3 | Solid. Followed on hot paths, minor gaps |
| 2 | Partial. Followed in places, real gaps on important paths |
| 1 | Weak. Mostly missing, or a High finding in this area |
| 0 | Absent or dangerous, or a Critical finding in this area |

| Area | Rules | Weight |
|------|-------|--------|
| Authentication | B1 | 8 |
| Authorization | B2 | 12 |
| Input and API contract | B3 | 8 |
| Data access and queries | B4, B5 | 12 |
| Schema, indexes and migrations | B6 | 8 |
| Concurrency and transactions | B7 | 8 |
| Resilience and limits | B8 | 8 |
| Caching and performance | B12 | 6 |
| Logging | B9 | 8 |
| Observability | B10 | 6 |
| Error handling | B11 | 6 |
| Config and operations | B13, B14 | 5 |
| Testing | B15 | 5 |

Score = sum of (weight times grade divided by 4). A Critical finding caps its area at 0 and a High finding caps it at 1.

| Score | Verdict |
|-------|---------|
| 90 to 100 | Expert. Ready for scale |
| 75 to 89 | Production ready with known gaps |
| 60 to 74 | Risky. Fix the High findings before growth |
| below 60 | Not production ready |

Grade only what you checked. If an area could not be assessed (no access to infra config, say), mark it "not assessed", drop its weight, and scale the score to 100. Say so in the report.

## Report

Fill [../templates/review-template.md](../templates/review-template.md). Findings most severe first. End with a fix plan ranked by impact over effort, where P0 is high impact and low effort. Keep the tone factual. Blame the code path, not the person.
