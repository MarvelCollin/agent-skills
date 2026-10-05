# Agent Skills
![License](https://img.shields.io/github/license/MarvelCollin/agent-skills) ![Last commit](https://img.shields.io/github/last-commit/MarvelCollin/agent-skills) ![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-8A2BE2)

A growing set of skills for Claude Code, packaged as one plugin. Each skill lives in its own folder under `skills/` and becomes one slash command.

## Skills

| Skill | Usage | What it does |
|-------|-------|--------------|
| `/backend` | `/backend [what to build]`, `/backend design <system>`, `/backend review <path>`, `/backend checklist [path]`, `/backend load <url>` or `/backend <topic>` | Designs and builds backend code under expert rules, reviews it for production readiness, runs the essentials checklist, or load tests a service you own |
| `/uiux` | `/uiux [what to build]` or `/uiux <url> [focus]` | Builds UI/UX frontend that follows strict UX rules and reviews it, or audits a live site as a real user |
| `/security` | `/security <target-or-path> [phase]` | Runs an authorized security review of an app you own or are cleared to test, or a static code review |

## Installation

As a plugin, which installs every skill:

```bash
claude plugin marketplace add MarvelCollin/agent-skills
claude plugin install agent-skills@agent-skills
```

Or copy one skill into your personal skills folder. Each skill keeps everything it needs inside its own folder, so it works on its own. Swap `backend` for `uiux` or `security`:

```bash
git clone https://github.com/MarvelCollin/agent-skills
cp -r agent-skills/skills/backend ~/.claude/skills/backend
```

To try a local checkout without installing it:

```bash
claude --plugin-dir ./agent-skills
```

## `/uiux`

### Build

```
/uiux an admin dashboard for a school testing system
```

Claude also loads the skill on its own whenever you ask it to build or restyle UI. Every build follows these hard rules:

| Rule | What it means |
|------|---------------|
| R1 Pastel palette | Pastel colors built in OKLCH unless you name your own. No saturated default blue, green, purple or orange fills. Contrast is still checked |
| R2 No icon-tile stat cards | Totals go in one summary strip with context and links, not a row of identical cards with colored icon squares |
| R3 No icons in rounded squares | Icons sit inline with their text, without a tinted tile |
| R4 No pill badges | Status and role labels use plain column values, a shape plus a word, or weighted text |
| R5 Filterable tables | Global search plus a filter on every column, sorting, a clear-filters line, and filters kept in the URL |
| R6 Overlays size to content | Modals, drawers and popovers fit their content within limits and become sheets on mobile |
| R7 Custom controls | Custom scrollbars, date pickers, selects, checkboxes, sliders, dialogs and tooltips, built on accessible APG patterns |
| R8 Specific, consistent layouts | Layouts come from the product's content and main task, not a template, with one set of tokens and one component per job |
| R9 Clean copy | No semicolons and no em dashes in UI text or in anything the skill writes |
| R10 Fast data loading | Tables and lists paginate from the backend with server-side sort and filter, skeleton loading states, no layout shift, no lag |
| R11 Real avatars | A real photo or a neutral placeholder, never a circle of initials |

It also applies the guides on [navigation](skills/uiux/references/navigation.md), [color picking](skills/uiux/references/color.md) and [Shneiderman's Eight Golden Rules](skills/uiux/references/golden-rules.md).

After building, it reviews its own work and answers three questions with evidence: **Is it easy to use? Is it nice to use? Is the navigation good?** It runs a rule scan on the code, uses the UI in a browser when it can, and fixes what it finds before reporting.

```
/uiux review                     # review the UI built in this session
/uiux review src/pages/admin     # review existing code
```

### Audit

```
/uiux https://example.com                                  # full audit, 12 phases
/uiux https://example.com a11y AA                          # one focus area
/uiux https://example.com flow "sign up for an account"   # one user goal, step by step
/uiux https://example.com vs https://example.org           # head-to-head comparison
/uiux report                                               # compile findings from this session
```

Focus areas: `nav`, `flow`, `forms`, `errors`, `perf`, `mobile`, `a11y [A|AA|AAA]`, `privacy`, `dark`, `404`, `slop [strict]`. A persona name (`sarah`, `marcus`, `elena`, `david`, `aisha`, `tom`) runs the full audit as that persona.

### Requirements

- A browser tool: the [agent-browser](https://github.com/vercel-labs/agent-browser) CLI (recommended), the Claude desktop browser pane, or the Playwright MCP server
- bash or PowerShell for the scripts
- Node.js and Chrome for the axe-core and Lighthouse scans (optional)

## `/security`

An authorized security review of a web app you own or are cleared to test. It is built for your own and local or dev builds first (localhost, private hosts, your own source), and refuses targets you cannot show authorization for.

```
/security dev                            # find your running dev server and screen it, no setup questions
/security dev ./app                      # same, for a project in another folder
/security ./src                          # static secure-code review, runs nothing live
/security http://localhost:3000          # full review of your local app
/security http://localhost:3000 recon    # one phase
/security review ./api                    # code review of a folder
```

**Dev mode** is the quickest way to screen your own build. A `dev-detect` script finds the dev server running on 127.0.0.1 and reads the stack and dev command from the project. A `scope-init` script then writes the engagement folder and `scope.md` with safe default rules for a local build, so there are no setup questions. The skill runs every phase white-box, reading your source next to the live app, and stops only at the end with the report. `scope-init` refuses any host that is not local, so a public site still needs your stated authorization. The skill pins itself to Opus 5.5 at high effort while it runs.

It works in phases, based on the OWASP WSTG and ASVS:

1. **Scope.** Confirms authorization and writes the rules of engagement. Nothing active runs before this. A `scope-check` script verifies each target is in scope, and flags out-of-scope hosts.
2. **Recon.** Maps the attack surface inside scope, preferring the app's own source and traffic over noisy scanning.
3. **Testing.** Works through vulnerability classes matched to what recon found: injection, broken auth and access control, SSRF and server-side, XSS and client-side, session and tokens, business logic, misconfiguration, exposed secrets, client exposure (env values in the bundle, tokens in storage, over-fetched responses, public source maps), client tampering (an edited request that forges a role, owner, price or status), API, and LLM features. Lightest touch that proves the issue, nothing destructive.
4. **Validation.** Six gates kill false positives. A finding ships only when reproduced with evidence and real impact.
5. **Report.** Every finding gets severity, evidence, impact and a concrete fix, mapped to OWASP and CWE, with fixes ranked by risk over effort.

A `grep-audit` script speeds up code review by flagging risky sinks and hardcoded secrets for a human to read, including secrets behind public env prefixes, tokens in web storage, public source maps, decoded but unverified JWTs, cookies without `HttpOnly`, and roles, prices and identity headers taken from the client. The skill only tests targets the user owns or is authorized to test, and never helps evade detection, target at scale, run denial-of-service, or attack third parties.

## `/backend`

Backend engineering at a staff level: correct under concurrency, fast at real data volume, safe by default, and easy to operate.

```
/backend add a paginated orders endpoint       # build under the hard rules
/backend design a multi-tenant billing service # design doc first, then build
/backend review ./api                          # scored production-readiness review
/backend review diff main                      # review a branch or the current changes
/backend checklist ./api security              # stress test first, then the essentials checklist
/backend load http://localhost:3000/api/orders # load or stress test your own service
/backend n+1                                   # one topic: explain, audit this code for it, fix
```

Claude also loads the skill on its own when you write endpoints, queries, migrations or jobs, or ask to optimize or harden a backend.

### Build

Every build follows these hard rules, then ends with a Rules Check that says pass, not applicable or still open for each one:

| Rule | What it means |
|------|---------------|
| B1 Authenticate every route | Global auth with a public allowlist, argon2id or bcrypt, rate-limited login, short tokens fully verified |
| B2 Authorize every object, function and field | Owner or tenant scope inside the query, server-side permission checks, write allowlists and read DTOs, identity never from the client |
| B3 Validate at the boundary | A schema on every input, global size limits, problem details on failure, a DTO on every response |
| B4 No N+1 queries | Eager loading or batching, DataLoader for GraphQL, lazy-load guards in dev, query-count tests |
| B5 Bounded, paginated, lean queries | Default and max page size, keyset pagination for big lists, no `SELECT *` |
| B6 Index and constrain in the database | Indexes that match hot queries checked with EXPLAIN, indexed foreign keys, constraints, safe online migrations |
| B7 Transactions, concurrency, idempotency | Short transactions, atomic updates or locks instead of check-then-act, idempotency keys, outbox |
| B8 Timeouts, retries and limits | A timeout on every outbound call, bounded retries with jitter, circuit breakers, rate limits |
| B9 Structured logs | JSON logs with request and trace ids, redaction of secrets, one log per error, audit log |
| B10 Metrics, traces, health | RED metrics, OpenTelemetry tracing, separate liveness and readiness |
| B11 Safe errors | One handler, RFC 9457 problem details, nothing leaked, nothing swallowed |
| B12 Slow work off the request path | Durable idempotent jobs, nothing that blocks the event loop |
| B13 Config and shutdown | Typed config validated at startup, no secret fallbacks, graceful shutdown |
| B14 Correct types | Money as integer cents or decimal, UTC `timestamptz`, UUIDv7 or bigint keys |
| B15 Prove it with tests | Real-database integration tests, authorization matrix, query counts, parallel and idempotency tests, tamper tests, a build check for leaked secrets |
| B16 Nothing secret reaches the client | No secret behind a public env prefix or in the bundle, no public source maps or debug pages, an opaque `HttpOnly` session cookie, no tokens in web storage, DTO responses with no hashes or config |
| B17 The server decides | Role, owner, price, total and status come from the server and a forged field changes nothing, hidden UI is never the check, tokens are verified and not only decoded |

The rules link to 21 topic guides: API design, authentication, authorization, validation, database and N+1, migrations, concurrency, caching, performance, resilience, background jobs, logging, observability, errors, testing, config and deploy, architecture, distributed systems, real-time, client trust (secrets out of the browser, never trust client values), and a security baseline mapped to the OWASP API Security Top 10 (2023). A Postgres guide ranks its rules by impact with wrong and right SQL, and a stack guide covers the concrete fixes for Node, Python, Rails, Laravel, Spring, .NET, Go and GraphQL.

### Design

`/backend design <system>` is for a new service or a change that is costly to undo. It asks only the questions the code cannot answer (traffic, data size, tenancy, consistency, latency and recovery targets), each with a recommended answer. It then estimates capacity, picks the simplest shape the numbers support, models data from access patterns, drafts the API contract and records decisions as ADRs. It stops for your approval before building anything expensive to reverse.

### Review

`/backend review <path>` maps the system, runs the `backend-scan` script, walks 13 areas against the rules, measures query counts and plans when the app runs locally, and confirms every finding through five gates before it is reported. The report has a weighted score out of 100, a severity for each finding, and a fix plan ranked by impact over effort.

`backend-scan` flags leads with a rule tag: N+1 calls inside loops, maps and comprehensions, unscoped id lookups, client-supplied roles, mass assignment, unbounded queries, `SELECT *`, offset pagination, blocking index builds, HTTP calls without timeouts, unstructured or secret-leaking logs, swallowed and leaked errors, blocking calls, credentials in connection strings, secret fallbacks, float money, naive timestamps, decoded but unverified JWTs, cookies without `HttpOnly`, secrets behind public env prefixes, public source maps, the whole environment sent in a response, tokens in web storage, and client-sent prices, status and identity headers. It skips tests, vendored code and build output. `/backend review diff [base]` reviews only a branch, pull request or the current changes.

`db-lint` does the same for SQL migrations and Prisma schemas: blocking index builds, constraints validated under lock, `NOT NULL` without a default, column type changes, unbatched backfills, foreign keys without an index, float money, timestamps without a time zone and random UUID keys.

### Checklist

`/backend checklist [path] [maintenance|security|db|caching|speed]` is the fast pass for the essentials. It stress tests first, when it has a runnable target you own, to find the real bottleneck, then grades 48 items in five groups and ranks the fixes so the ones that explain the bottleneck come first. Each item links to its rule and topic file, and every `pass` needs proof (file and line, config value, command output). With no runnable target the baseline is reported as `not measured`, never invented. Items that live outside the repo, such as backups, CDN and HTTPS at the load balancer, are marked `unverified` instead of guessed.

| Group | Items |
|-------|-------|
| Maintenance | Migrations, health check, logging, error monitoring, database backups, tests, profiling slow endpoints |
| Security | Password hashing, rate limiting, parameterized queries, input validation, secrets in env vars, HTTPS, CORS whitelist, httpOnly and secure cookies, JWT expiry with refresh tokens, no stack traces to users, secrets and sessions kept out of the browser, no trust in client-sent roles or prices |
| Database speed | Indexes, composite and covering indexes, N+1, selected columns, `LIMIT`, cursor pagination, batching, pooling, precomputed counts, denormalized hot reads, `EXPLAIN`, query timeouts, transactions |
| Caching | Redis for reads and sessions, HTTP cache headers, CDN, TTL, invalidation on update |
| Response speed | Compression, small payloads, pagination, HTTP/2 and keep-alive, async I/O, background jobs, parallel calls, request timeouts, image resizing on upload |

### Load test

`/backend load <url> [smoke|load|stress|spike|soak|breakpoint]` plans the traffic mix and pass criteria, runs the test, watches the server side, and names the bottleneck with evidence. The `load-test` script wraps autocannon (it needs Node.js) and reports requests, RPS, p50, p90, p99, error rate and a pass or fail against thresholds. For ramps and mixed traffic the skill writes a k6 script.

Load tests only run against services you own. Local and private hosts are allowed by default. Any other host needs you to state your authorization, and the script refuses it without `--authorized` and a rate cap. The skill never load tests third parties.

## Project Structure

```
.claude-plugin/
  plugin.json                 Plugin manifest
  marketplace.json            Marketplace entry so the repo can be installed directly
skills/
  uiux/
    SKILL.md                  Entry point: build, review and audit modes
    references/               Build rules, color, navigation, golden rules, UI review,
                              browser protocol, personas, rubric, heuristics, flow test,
                              accessibility, comparison, slop catalog, report
    templates/                Report and flow test templates
    scripts/                  rule-scan, perf-check, axe-scan, lighthouse-audit, conventions (.sh + .ps1)
  security/
    SKILL.md                  Entry point: scope, recon, test, validate, report, code review
    references/               Authorization, recon, validation, reporting, code review,
                              testing/ (12 vulnerability classes)
    templates/                Report and finding templates
    scripts/                  dev-detect, scope-init, scope-check, grep-audit (.sh + .ps1)
  backend/
    SKILL.md                  Entry point: build, design, review, checklist, load test and topic modes
    references/               Build rules B1 to B17, design, review, essentials checklist, load testing,
                              Postgres guide, stack notes, topics/ (21 backend topic guides)
    templates/                Design, review and load test report templates, OpenAPI starter
    scripts/                  backend-scan, db-lint, conventions, load-test (.sh + .ps1)
evals/                        Cases for claude plugin eval
tests/                        Unit tests for the scripts
```

## Development

Run the script tests. They start a local fixture server and use a fake `npx`, so they need Python 3 but no network or Chrome:

```bash
bash tests/run-tests.sh
```

Validate the manifests and skill frontmatter:

```bash
claude plugin validate .
```

Run the behavior evals, starting with one case:

```bash
claude plugin eval . --case build-dashboard --allow-tools Bash Write Edit
```

## License

MIT
