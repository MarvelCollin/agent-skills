# Testing Backends

Tests should prove the properties that break in production: authorization, query behavior at volume, concurrency, idempotency, failure handling and migrations. Line coverage alone proves none of them.

## Layers

| Layer | Tests | Notes |
|-------|-------|-------|
| Unit | Pure domain logic: pricing, state machines, policies, parsers | Fast, no I/O, many of them |
| Integration | Repositories, queries, migrations, transactions against a real database | Same engine and version as production |
| API | HTTP in, HTTP out, through the real middleware stack | Auth, validation, error shapes, status codes |
| Contract | Between services and against the OpenAPI spec | Pact for consumer-driven contracts, spec validation for responses |
| End to end | A few critical journeys across the deployed system | Slow, keep few |
| Load and failure | Thresholds under load, behavior when dependencies fail | Before release on hot paths |

## Use a Real Database

SQLite or an in-memory fake hides real behavior: constraint errors, isolation, JSON operators, case sensitivity, query plans. Use Testcontainers or a disposable database of the same engine and version, run the real migrations once, then isolate each test with a transaction that rolls back or a truncate between tests.

## Must-Have Tests

### Authorization matrix

Every endpoint against every role, including another user's and another tenant's records. Assert the denials (401, 403, 404). See [authorization.md](authorization.md).

### Mass assignment

Send forbidden fields (`role`, `tenant_id`, `is_admin`, `balance`) in create and update requests. Assert they are ignored or rejected.

### Query count

Fail when a list endpoint's query count grows with rows:

```python
def test_order_list_queries_are_flat(client, django_assert_max_num_queries):
    make_orders(50)
    with django_assert_max_num_queries(4):
        client.get("/api/orders?limit=50")
```

Rails `assert_queries_count` (7.2 and later), Laravel `DB::enableQueryLog()` then count, SQLAlchemy and Prisma event hooks, Hibernate `Statistics.getPrepareStatementCount()`, EF Core interceptors.

### Concurrency

Fire parallel requests and check the invariant:

```js
const results = await Promise.all(Array.from({ length: 20 }, () =>
  request(app).post('/api/checkout').set(auth).send({ sku: 'LAST-ONE', qty: 1 }),
))
expect(results.filter((r) => r.status === 201)).toHaveLength(1)
```

### Idempotency

Send the same request with the same `Idempotency-Key` twice. Assert one effect and the same response. Send a different body with the same key and assert 422.

### Failure injection

Make a dependency slow or broken (Toxiproxy, WireMock, nock, `responses`, `httptest`) and assert the endpoint returns the right status within its time budget, the circuit breaker opens, and no partial data is left.

### Migrations

Run all migrations from empty, and the newest ones against a snapshot shaped like production. Lint them for locks (see [migrations.md](migrations.md)).

### Logs and errors

Log a fake secret through each logging path and assert it is redacted. Trigger an unexpected error and assert the response body is generic and carries a request id.

## Test Data and Time

- Factories (factory_bot, Factory Boy, fishery, Instancio) instead of shared fixtures that every test mutates
- Freeze or inject the clock. Never depend on the current date, time zone of the machine, or sleep
- Seed randomness and print the seed on failure
- Property-based tests (Hypothesis, fast-check, jqwik, gopter) for parsers, money math and state machines

## Load Tests in CI

A short k6 or autocannon smoke run with thresholds against a staging deploy catches regressions in hot endpoints. Keep the full stress and soak runs for scheduled jobs. See [../load-testing.md](../load-testing.md).

## Pipeline

- Lint, type check, unit tests, integration tests, migration check, dependency and secret scanning, build once, then deploy the same artifact
- Flaky tests get fixed or quarantined with an owner, never retried until green silently
- Coverage is a signal for untested areas, not a target

## Checklist

- [ ] Integration tests on the real database engine with real migrations
- [ ] Authorization matrix and mass assignment tests
- [ ] Query-count tests on list endpoints
- [ ] Parallel tests for critical invariants
- [ ] Idempotency tests
- [ ] Failure injection for key dependencies
- [ ] Deterministic time and data
