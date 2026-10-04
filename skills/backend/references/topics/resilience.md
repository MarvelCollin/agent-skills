# Resilience

Dependencies will be slow, fail, or vanish. A resilient service fails fast, contains the damage, recovers on its own, and protects itself from overload.

## Timeouts

- Every outbound call has a timeout: HTTP clients, database queries, cache, queue publishes, SMTP, DNS. Many defaults are infinite (Node `fetch`, Python `requests`, Go `http.Client{}`, axios)
- Set both a connect timeout (short, about 1 to 3 seconds) and an overall request timeout matched to the dependency's normal p99 plus margin
- **Deadline propagation:** the inner timeout is shorter than the outer one. If the client gives up at 5 seconds, the downstream call must not run for 30. Pass a deadline through context (`context.Context`, `AbortSignal`, gRPC deadlines) and skip work when it has already expired
- Database: `statement_timeout` per role or per transaction, and a pool acquire timeout

```js
const res = await fetch(url, { signal: AbortSignal.timeout(2000) })
```

```python
httpx.get(url, timeout=httpx.Timeout(2.0, connect=1.0))
```

```go
client := &http.Client{Timeout: 2 * time.Second}
```

## Retries

- Retry only transient failures: connection errors, timeouts, 502, 503, 504, 429. Never retry 400, 401, 403, 404 or 422
- Retry only idempotent operations, or ones protected by an idempotency key
- Exponential backoff with full jitter: `sleep = random(0, min(cap, base * 2 ** attempt))`. Without jitter, every client retries in sync and hammers the recovering service
- Cap attempts (about 3) and total time (within the caller's deadline)
- Honor `Retry-After`
- **Retry at one layer.** If the client, the gateway and the service each retry 3 times, one failure becomes 27 calls. Use a retry budget (for example, retries may add at most 10 percent extra traffic)

## Circuit Breakers

When a dependency keeps failing, stop calling it for a while so it can recover and your threads are not tied up waiting.

- **Closed:** calls flow. Failures are counted over a window
- **Open:** after a threshold (say 50 percent failures over 20 calls), calls fail immediately for a cool-down period
- **Half-open:** a few trial calls decide whether to close again

Libraries: opossum (Node), resilience4j (JVM), Polly (.NET), pybreaker or aiobreaker (Python), sony/gobreaker (Go). A service mesh (Istio, Linkerd) or gateway can do it at the network layer.

## Bulkheads

Isolate resources per dependency so one slow dependency cannot consume everything: separate connection pools, concurrency limits per downstream, separate worker queues for slow and fast jobs.

## Fallbacks and Degradation

Decide per dependency what happens when it is down:

| Dependency | Fallback |
|------------|----------|
| Recommendations | Show popular items from a cache |
| Avatar service | Neutral placeholder |
| Payment provider | Fail clearly, keep the order pending, retry from a job |
| Feature flag service | Last known values, then safe defaults |

A fallback must not hide failure from monitoring. Count every fallback.

## Rate Limiting

- **Algorithms:** token bucket (allows bursts up to bucket size, smooth average), sliding window counter (accurate, cheap), fixed window (simple, bursty at edges), leaky bucket (smooth output)
- **Keys:** authenticated user or API key first, then tenant, then IP for anonymous traffic. IP alone punishes users behind shared NAT
- **Tiers:** strict limits on login, signup, password reset, OTP verification and anything that costs money (SMS, email, AI calls). Looser on cheap reads
- **Distributed:** in Redis with an atomic script, or at the gateway (NGINX, Envoy, Kong, Cloudflare, API Gateway). An in-memory limiter per instance multiplies the limit by the instance count
- **Response:** 429 with `Retry-After` and rate limit headers (see [api-design.md](api-design.md))
- Rate limit internal callers too, so a buggy batch job cannot take down the API

## Load Shedding and Backpressure

- When overloaded, reject early with 503 and `Retry-After` instead of queueing until everything times out
- Bound every queue: request queues, in-memory work queues, worker backlogs
- Concurrency limits per instance (adaptive limiters like Netflix concurrency-limits or Envoy adaptive concurrency)
- Prioritize: shed analytics and background work before checkout
- Streams and websockets respect backpressure. Stop reading when the writer cannot keep up

## Health Checks

| Probe | Question | Checks | On failure |
|-------|----------|--------|------------|
| Liveness | Is the process stuck? | Only the process itself. No dependency checks | Restart the container |
| Readiness | Can it take traffic now? | Database and critical dependencies reachable, warm-up done, not shutting down | Remove from the load balancer |
| Startup | Has it finished booting? | Migrations checked, caches warmed | Delay the other probes |

A liveness check that pings the database restarts every instance when the database blips, which turns a blip into an outage. Keep health endpoints cheap, unauthenticated or on an internal port, and excluded from rate limits and request logs.

## Graceful Shutdown

On `SIGTERM`:

1. Mark not ready, so the load balancer stops sending new requests
2. Wait briefly for the balancer to notice (a `preStop` sleep of a few seconds in Kubernetes)
3. Stop accepting new connections and new jobs
4. Finish in-flight requests and jobs, with a deadline shorter than the platform's grace period (Kubernetes `terminationGracePeriodSeconds` defaults to 30)
5. Close database and cache pools, flush logs, traces and metrics
6. Exit

Make sure the process is PID 1 or behind an init (`tini`, `dumb-init`, `exec` in the entrypoint) so it receives the signal. Jobs that cannot finish in time must be safe to retry.

## Failure Testing

- Inject latency and errors in tests with Toxiproxy, WireMock, nock or `responses`, and assert the endpoint answers within its budget with the right status
- Game days or chaos experiments in staging: kill an instance, drop the cache, slow the database
- Verify alerts fire and runbooks work

## Checklist

- [ ] Timeouts on every outbound call, shorter than the caller's deadline
- [ ] Bounded retries with backoff and jitter, only for idempotent transient failures
- [ ] Circuit breakers and fallbacks for flaky dependencies
- [ ] Rate limits per user or key, strict on auth and costly endpoints
- [ ] Bounded queues and load shedding
- [ ] Separate liveness and readiness
- [ ] Graceful shutdown tested
