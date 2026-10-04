# Stack Notes

Concrete tools and idioms per stack. Use the project's existing choices first. Suggest these only where the project has nothing.

## Node.js and TypeScript (Express, Fastify, NestJS, Hono)

- **Validation:** zod or valibot, TypeBox with Fastify route schemas, class-validator with NestJS `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true })`
- **Eager loading:**
  - Prisma: `include: { items: true }` or `select` with nested relations. Count with `_count`. Bulk with `createMany`
  - Drizzle: relational queries `with: { items: true }`, or explicit joins
  - TypeORM: `relations: { items: true }` or `leftJoinAndSelect`. Avoid lazy relations
  - Sequelize: `include: [{ model: Item }]`, `separate: true` for has-many with limits
  - Mongoose: `.populate('items')` (one `$in` query per path) plus `.lean()` for read-only
  - Kysely or Knex: an explicit join, or `whereIn('order_id', ids)` then group in memory
- **SQL logging:** Prisma `log: ['query']`, TypeORM `logging: true`, Sequelize `logging: console.log` in development, Knex `debug: true`
- **Logging:** pino (`pino-http` for request lines, `redact` for secrets), `AsyncLocalStorage` for request context
- **Tracing:** `@opentelemetry/sdk-node` with `auto-instrumentations-node`
- **Errors:** Express error middleware (Express 5 forwards rejected promises), Fastify `setErrorHandler`, NestJS exception filters
- **Jobs:** BullMQ (Redis), pg-boss or Graphile Worker (Postgres)
- **Timeouts:** `fetch(url, { signal: AbortSignal.timeout(ms) })`, undici `Agent` with `headersTimeout` and `bodyTimeout`, axios `timeout`
- **Rate limits:** `@fastify/rate-limit`, `express-rate-limit` with a Redis store, `@nestjs/throttler`
- **Config:** zod or envalid over `process.env`
- **Tests:** Vitest or Jest, supertest, Testcontainers, nock or MSW for HTTP

## Python (Django, FastAPI, Flask)

- **Validation:** Pydantic models (FastAPI), DRF serializers with explicit `fields`, marshmallow
- **Eager loading:**
  - Django: `select_related` for foreign keys and one-to-one (join), `prefetch_related` for reverse and many-to-many (one `IN` query), `Prefetch("items", queryset=...)` to filter, `annotate(Count(...))` for counts, `.only()` for columns, `bulk_create`
  - SQLAlchemy 2.0: `selectinload` for collections, `joinedload` for many-to-one, `raiseload("*")` or `lazy="raise"` to forbid lazy loads, `select(Model.id, Model.name)` for columns
- **N+1 detection:** django-debug-toolbar, `nplusone`, `django-zen-queries`, `assertNumQueries` or pytest-django `django_assert_max_num_queries`
- **SQL logging:** Django `LOGGING` with `django.db.backends` at DEBUG, SQLAlchemy `echo=True`
- **Logging:** structlog with `contextvars`, or stdlib `logging` with a JSON formatter
- **Tracing:** `opentelemetry-instrument` auto-instrumentation
- **Errors:** FastAPI `exception_handler`, DRF `EXCEPTION_HANDLER`, Django middleware
- **Jobs:** Celery, RQ, Dramatiq, Procrastinate (Postgres). Use `transaction.on_commit` to enqueue in Django
- **Timeouts:** `httpx` with `timeout=` (or `httpx.AsyncClient` in async code). `requests` has no default timeout
- **Async pitfalls:** no `requests`, sync drivers or `time.sleep` inside `async def`. Use `asyncpg`, `httpx.AsyncClient`, `asyncio.sleep`, or `run_in_threadpool`
- **Config:** pydantic-settings
- **Tests:** pytest, pytest-django, Testcontainers, Factory Boy, `responses` or `respx`, Hypothesis

## Ruby on Rails

- **Validation:** strong parameters with `permit` (never `permit!`), model validations, dry-validation for complex input
- **Eager loading:** `includes` (decides), `preload` (separate queries), `eager_load` (join). `strict_loading` per model or globally in development. Counter caches for counts. `find_each` for batches. `insert_all` and `upsert_all` for bulk
- **N+1 detection:** Bullet, Prosopite, `strict_loading`
- **Logging:** lograge or semantic_logger for JSON
- **Jobs:** Sidekiq, Solid Queue, good_job. `after_commit` callbacks or `perform_later` after the transaction
- **Migrations:** strong_migrations, `algorithm: :concurrently` for indexes with `disable_ddl_transaction!`
- **Tests:** RSpec or Minitest, factory_bot, `assert_queries_count` (Rails 7.2 and later)

## PHP Laravel

- **Validation:** Form Requests, `$request->validated()` only, `$fillable` on models (never `$guarded = []`)
- **Eager loading:** `with('items')`, `withCount('items')`, `load` for already-fetched models. `Model::preventLazyLoading(! app()->isProduction())` in a service provider. `chunkById` and `lazyById` for big sets. `cursorPaginate` for keyset pagination
- **Logging:** Monolog JSON formatter, context via `Log::withContext`
- **Jobs:** Laravel queues with Redis or database, `afterCommit()` on dispatch, Horizon for monitoring
- **Tests:** Pest or PHPUnit, `DB::enableQueryLog()` for query counts

## Java and Kotlin (Spring Boot)

- **Validation:** Jakarta Bean Validation with `@Valid` on request DTOs. Never bind requests straight to entities
- **Eager loading:** `JOIN FETCH` in JPQL, `@EntityGraph(attributePaths = "items")`, `@BatchSize` or `hibernate.default_batch_fetch_size`. Set `@ManyToOne(fetch = LAZY)` (the default is eager). `spring.jpa.open-in-view=false`. DTO projections for reads
- **N+1 detection:** Hibernate statistics, `hypersistence-utils` query count assertions, datasource-proxy
- **SQL logging:** `logging.level.org.hibernate.SQL=DEBUG`
- **Logging:** SLF4J with Logback and logstash-logback-encoder, MDC for request ids
- **Tracing:** OpenTelemetry Java agent or Micrometer Tracing
- **Errors:** `@RestControllerAdvice` with `ProblemDetail` (Spring 6 supports RFC 9457 natively)
- **Resilience:** resilience4j (circuit breaker, retry, bulkhead, rate limiter, time limiter)
- **Pool:** HikariCP. Set `maximumPoolSize`, `connectionTimeout`
- **Jobs:** Spring Batch, JobRunr, Quartz with a cluster lock, ShedLock for scheduled tasks
- **Tests:** JUnit 5, Testcontainers, WireMock, `@DataJpaTest`, `@SpringBootTest`

## .NET (ASP.NET Core)

- **Validation:** DataAnnotations or FluentValidation on request records. Bind to DTOs, not entities
- **Eager loading:** `Include` and `ThenInclude`, `AsSplitQuery` for multiple collections, `Select` projections into DTOs, `AsNoTracking` for reads. Keep lazy-loading proxies off
- **SQL logging:** `optionsBuilder.LogTo(Console.WriteLine, LogLevel.Information)` in development. `EnableSensitiveDataLogging` only locally
- **Logging:** `ILogger` with Serilog or the JSON console formatter, scopes for request context
- **Tracing:** OpenTelemetry .NET with ASP.NET Core, HttpClient and EF Core instrumentation
- **Errors:** `AddProblemDetails()` with `UseExceptionHandler()` (RFC 9457 built in)
- **Resilience:** `Microsoft.Extensions.Http.Resilience` (Polly v8) with `AddStandardResilienceHandler`
- **HTTP clients:** `IHttpClientFactory`, never `new HttpClient()` per request
- **Jobs:** Hangfire, Quartz.NET, hosted services with channels
- **Tests:** xUnit, Testcontainers, WebApplicationFactory, WireMock.Net

## Go

- **Validation:** go-playground/validator, or types generated from OpenAPI (oapi-codegen) with request validation middleware
- **Data access:** sqlc or sqlx with explicit joins or `WHERE id = ANY($1)` for batching. GORM: `Preload("Items")` or `Joins("Customer")`
- **Logging:** `log/slog` with a JSON handler, values from `context.Context`
- **Tracing:** OpenTelemetry Go with `otelhttp` and `otelsql` or `otelpgx`
- **Timeouts:** `http.Client{Timeout: ...}` (the default client has none), `context.WithTimeout` on every call, `http.Server` with `ReadHeaderTimeout`, `ReadTimeout`, `WriteTimeout`, `IdleTimeout`
- **Errors:** wrap with `%w`, map sentinel and typed errors to status codes in one middleware, recover middleware for panics
- **Pool:** `pgxpool` with `MaxConns`. `database/sql` `SetMaxOpenConns`, `SetMaxIdleConns`, `SetConnMaxLifetime`
- **Jobs:** River (Postgres), Asynq (Redis)
- **Tests:** `testing` with `httptest`, Testcontainers, `-race` always

## GraphQL (any stack)

- DataLoader per request: `dataloader` (Node), Strawberry or aiodataloader (Python), graphql-batch (Ruby), java-dataloader, GreenDonut (.NET Hot Chocolate), graph-gophers/dataloader (Go)
- Depth and complexity limits: graphql-depth-limit, graphql-query-complexity, Hot Chocolate cost analysis
- Persisted queries for first-party clients

## Databases

- **Postgres:** `pg_stat_statements`, `auto_explain` for slow plans, `EXPLAIN (ANALYZE, BUFFERS)`, `pg_stat_user_indexes` for unused indexes, `statement_timeout`, `lock_timeout`, `idle_in_transaction_session_timeout`, PgBouncer, squawk for migrations
- **MySQL:** slow query log with `long_query_time`, `EXPLAIN ANALYZE` (8.0.18 and later), Performance Schema, `max_execution_time`, gh-ost or pt-online-schema-change
- **MongoDB:** `explain("executionStats")`, compound indexes by equality, sort, range (ESR rule), profiler, `maxTimeMS` on queries, avoid unbounded arrays in documents
- **Redis:** `SLOWLOG`, `INFO`, `--bigkeys`, `maxmemory-policy`, no `KEYS *`
