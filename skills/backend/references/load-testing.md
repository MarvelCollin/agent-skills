# Load and Stress Testing

Find out how a service behaves under load, where it breaks, and why. A load test without server-side monitoring only tells you that something is slow. The goal is to name the bottleneck.

## Authorization Comes First

Load tests send heavy traffic. Against a system you do not own, that is a denial-of-service attack.

- **Local and private hosts** (`localhost`, `127.0.0.1`, `::1`, `*.localhost`, `*.test`, `*.local`, `10.x`, `172.16.x` to `172.31.x`, `192.168.x`, `host.docker.internal`) are the default authorized case when they run the user's own build
- **Any other host** needs the user to state, in chat, that they own it or are authorized to load test it. Record the statement in the run's `plan.md`. Also require a rate cap (`-r`) so the test is bounded
- **Production** only with an explicit go-ahead from the owner, a rate cap, off-peak timing, someone watching dashboards, and a stop condition. Prefer staging with production-like data
- **Cloud and CDN providers** have their own policies on load testing. Mention that the user should check theirs before testing a hosted target
- **Never** load test a third-party site or API, run tests meant to take a service down, or route traffic in ways that hide its source. If the request turns that way, say so and stop

The `load-test` script enforces the local check and refuses remote hosts without `--authorized` and a rate cap. Pass `--authorized` only after the user has confirmed authorization in chat.

## Test Types

| Type | Question it answers | Shape |
|------|---------------------|-------|
| Smoke | Does the script work and is the baseline sane? | 1 to 5 users, 1 minute |
| Load (average) | Does it meet the SLO at normal traffic? | Ramp to expected peak, hold 5 to 30 minutes |
| Stress | What happens above normal peak? Does it degrade gracefully? | Ramp to 1.5x to 3x peak in steps |
| Spike | Does it survive a sudden burst and recover? | Jump to a high rate in seconds, hold briefly, drop |
| Soak | Does it leak or degrade over time? | Normal load for hours |
| Breakpoint | Where is the capacity limit? | Ramp until errors or latency cross the threshold |

Run smoke first, always. Then pick the type that answers the user's question.

## Plan Before Running

Write `backend-load-<slug>-<YYYYMMDD>/plan.md` with:

- **Targets and mix:** which endpoints, and in what ratio. Mirror real traffic (say 70 percent reads of the list, 20 percent detail, 10 percent writes), not one endpoint in a loop
- **Goals:** pass criteria up front. For example p95 under 300 ms, p99 under 800 ms, error rate under 0.5 percent, at 200 requests per second. Derive them from the SLO or from current peak traffic times a safety factor
- **Data:** a production-sized dataset. N+1 queries and missing indexes stay invisible on a 50-row dev database. Seed with a factory script if needed. Use dedicated test accounts and tokens, never real users
- **Workload model:** open (fixed arrival rate, like real users on the internet) or closed (fixed concurrent users that wait for each response). Open models are better for finding saturation because a closed model slows its own traffic when the server slows, which hides the problem (coordinated omission)
- **Environment:** run the load generator on a different machine from the server when you can. On one laptop they compete for CPU, so treat local numbers as relative (before vs after a fix), not as capacity
- **What to watch on the server:** see below
- **Stop conditions:** error rate above a limit, or a dependency alarm

## Watch the Server, Not Just the Client

During the run, collect:

- Service: CPU, memory, GC pauses, event loop lag (Node), thread pool or worker saturation, open file descriptors
- Database: active and waiting connections, pool wait time, CPU, slow query log, locks and deadlocks, `pg_stat_statements` top queries, replication lag
- Cache: hit ratio, latency, evictions, memory
- Queues: depth, age of the oldest message, consumer lag
- Dependencies: latency and error rate of each outbound call (traces show this best)

## Running

### Quick HTTP benchmark (script)

For one endpoint, use the bundled script. It wraps `autocannon` through `npx`, so it needs Node.js.

```bash
bash "<skill-dir>/scripts/load-test.sh" "http://localhost:3000/api/orders?limit=20" -d 30 -c 20 -H "Authorization: Bearer $TOKEN" -o "<run-dir>"
```

On Windows without bash:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill-dir>/scripts/load-test.ps1" -Url "http://localhost:3000/api/orders?limit=20" -Duration 30 -Connections 20 -Header "Authorization: Bearer <token>" -OutputDir "<run-dir>"
```

Options: `-d` seconds (default 30, max 3600), `-c` connections (default 10, max 1000), `-r` overall requests per second cap, `-m` method, `-H` header (repeatable), `-b` body, `-o` output dir, `--p99` threshold in ms (default 1000), `--max-errors` percent (default 1), `--authorized` for an authorized remote host.

Output keys: `REQUESTS`, `RPS_AVG`, `LATENCY_P50_MS`, `LATENCY_P90_MS`, `LATENCY_P99_MS`, `LATENCY_MAX_MS`, `ERRORS`, `TIMEOUTS`, `NON_2XX`, `ERROR_RATE_PCT`, and `RESULT: pass` or `fail` against the thresholds. Raw JSON is saved in the output dir.

Without `-r` autocannon is a closed model (each connection waits for its response). Add `-r` for a fixed arrival rate.

### Scenarios and ramps (k6)

For mixed traffic, ramps and thresholds, write a k6 script in the run folder. Use an arrival-rate executor for an open model:

```js
import http from 'k6/http'
import { check } from 'k6'

const BASE = __ENV.BASE_URL || 'http://localhost:3000'
const params = { headers: { Authorization: `Bearer ${__ENV.TOKEN}` } }

export const options = {
  scenarios: {
    stress: {
      executor: 'ramping-arrival-rate',
      startRate: 20,
      timeUnit: '1s',
      preAllocatedVUs: 50,
      maxVUs: 500,
      stages: [
        { target: 100, duration: '2m' },
        { target: 200, duration: '3m' },
        { target: 400, duration: '3m' },
        { target: 0, duration: '1m' },
      ],
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.005'],
    http_req_duration: ['p(95)<300', 'p(99)<800'],
  },
}

export default function () {
  const r = Math.random()
  const res = r < 0.7
    ? http.get(`${BASE}/api/orders?limit=20`, params)
    : r < 0.9
      ? http.get(`${BASE}/api/orders/${__ENV.ORDER_ID}`, params)
      : http.post(`${BASE}/api/orders`, JSON.stringify({ sku: 'TEST-1', qty: 1 }), {
          headers: { ...params.headers, 'Content-Type': 'application/json', 'Idempotency-Key': `${__VU}-${__ITER}` },
        })
  check(res, { 'status is 2xx': (x) => x.status >= 200 && x.status < 300 })
}
```

Run with `k6 run -e BASE_URL=... -e TOKEN=... script.js --summary-export=summary.json`. Other good tools: Gatling (JVM), Locust (Python), Vegeta and oha (CLI, open model), JMeter (legacy suites).

Warm up before measuring (JIT, caches, pools). Change one thing at a time between runs. Run each comparison at least twice.

## Reading the Results

- Use percentiles. p50 is the typical user, p99 is the one who complains. Averages hide tails
- Plot latency against throughput. Latency stays flat, then bends sharply at the knee. Capacity is the rate just before the knee, not where errors start
- **Little's law:** concurrency = throughput times latency. At 200 requests per second and 250 ms, about 50 requests are in flight. If the pool has 10 database connections and each request holds one for 100 ms, the pool tops out near 100 requests per second
- Errors at a sharp threshold usually mean a hard limit: pool size, file descriptors, worker count, a rate limiter, or a dependency quota

## Symptom to Cause

| Symptom | Likely cause | Check | Fix |
|---------|--------------|-------|-----|
| Latency climbs with load while CPU stays low | Waiting on a pool, lock or dependency | Pool wait metrics, lock views, traces | Shorter transactions, right-size pool, fix slow dependency, add timeouts |
| One CPU core pinned, others idle (Node, Python) | Event loop or GIL blocked by sync work | Event loop lag, profiler flame graph | Move CPU work to workers, remove sync calls, cluster processes |
| Database CPU high, app CPU low | Missing index, N+1, heavy query | `pg_stat_statements`, slow log, EXPLAIN | Add index, eager load, select fewer columns, cache |
| Latency grows with data size, not load | Unbounded query, offset pagination, missing index | Plan with large tables | Keyset pagination, index, limits |
| Errors start at an exact concurrency | Pool, worker, fd or connection limit | Server logs, `ulimit -n`, pool config | Raise the limit with evidence, or queue and shed load |
| Memory grows during soak and never drops | Leak: unbounded cache or map, listeners, unclosed connections | Heap snapshots over time | Bound caches, close resources, fix listeners |
| p99 spikes every few seconds | GC pauses, cron, cache expiry stampede | GC logs, timeline against jobs | Tune heap, spread jobs, stagger TTLs, single-flight |
| 429 or 503 from the app early | Rate limiter or load shedding working | Response headers | Expected. Confirm limits match the plan |
| Throughput flat while latency rises | Saturated at some resource | USE metrics per resource | Find the saturated resource and scale or optimize it |

## Report

Write `report.md` from [../templates/load-report-template.md](../templates/load-report-template.md): the goal, environment, mix, results table per run, the knee, the bottleneck with evidence, fixes ranked by impact, and before and after numbers for any fix applied.
