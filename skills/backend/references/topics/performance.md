# Performance

Performance work is a loop: set a target, measure, find the biggest bottleneck, fix it, measure again. Guessing wastes time on code that was never slow.

## Set the Target

- Pick latency goals per endpoint as percentiles, such as p95 under 200 ms and p99 under 500 ms at 300 requests per second
- Build a latency budget: if the endpoint has 200 ms, the database gets 50, the downstream service 80, serialization 10, and the rest is headroom
- Track percentiles, not averages. An average of 80 ms can hide a p99 of 3 seconds

## Measure

- **Traces** (OpenTelemetry) show where time goes inside one request: database, cache, downstream calls, gaps of pure CPU
- **Profilers** show which functions burn CPU or allocate memory:
  - Node: `--cpu-prof`, Clinic.js (Doctor, Flame, Bubbleprof), 0x
  - Python: py-spy, Scalene, cProfile
  - Go: `pprof` (CPU, heap, goroutine, block, mutex profiles)
  - JVM: async-profiler, JDK Flight Recorder
  - .NET: dotnet-trace, dotnet-counters
- **Continuous profiling** (Pyroscope, Parca, cloud profilers) catches production-only hot spots
- **Database:** `pg_stat_statements`, slow query log, `EXPLAIN (ANALYZE, BUFFERS)`
- **Load tests** for behavior under concurrency (see [../load-testing.md](../load-testing.md))

## Where Time Usually Goes

In rough order of how often it is the culprit:

1. **Database:** N+1 queries, missing indexes, unbounded queries, `SELECT *`, offset pagination, lock waits (see [database.md](database.md))
2. **Sequential I/O:** awaiting independent calls one after another
3. **Downstream calls:** slow third parties without timeouts, chatty service-to-service calls
4. **Pool waits:** too few connections for the concurrency, or connections held during slow work
5. **Serialization:** huge JSON payloads, slow serializers, deep object graphs
6. **CPU in the request path:** hashing, image work, PDF generation, big regexes, compression of huge bodies
7. **Garbage collection and memory pressure**

## Patterns That Help

- **Run independent I/O concurrently** with a limit:

```js
const [user, orders, prefs] = await Promise.all([
  getUser(id),
  getOrders(id, { limit: 20 }),
  getPrefs(id),
])
```

  Python `asyncio.gather` or `TaskGroup`, Go `errgroup`, Java `CompletableFuture.allOf` or structured concurrency. For many items use a bounded pool (`p-limit`, `asyncio.Semaphore`, `errgroup.SetLimit`), not an unbounded fan-out
- **Batch** round trips: `MGET`, multi-row inserts, batch endpoints, DataLoader
- **Reuse connections:** keep-alive HTTP agents, one shared client per dependency, HTTP/2 to upstreams that support it. Creating a client per request costs a TLS handshake every time
- **Return less:** pagination, field selection, compression for responses above about 1 KB
- **Stream large responses** (exports, files) instead of building them in memory. Use database cursors for big result sets
- **Precompute** expensive reads into summary tables or caches (see [caching.md](caching.md))
- **Move slow work to jobs** (see [async-jobs.md](async-jobs.md))
- **Cheap work first:** validate and authorize before expensive calls. Reject early

## Runtime Notes

### Node.js

- One event loop per process. Any sync CPU work stalls every request on that process. Watch event loop lag (`perf_hooks.monitorEventLoopDelay`)
- No `*Sync` fs or crypto calls in request paths. Use async bcrypt or argon2, `worker_threads` or a job for CPU-heavy work
- Run one process per core (cluster, PM2, or multiple containers)
- Fast JSON with schema-based serializers (Fastify's `fast-json-stringify`)
- Watch for ReDoS: nested quantifiers on user input like `(a+)+`. Use RE2 or bounded patterns

### Python

- The GIL means one thread runs Python at a time. Scale with processes (Gunicorn or Uvicorn workers, starting at 2 times cores plus 1 for sync workers)
- In async frameworks (FastAPI, Starlette), a blocking call (`requests`, a sync driver, `time.sleep`) blocks the whole loop. Use async clients (`httpx.AsyncClient`, `asyncpg`) or `run_in_threadpool`
- `orjson` for fast JSON. Avoid ORM object creation for large reads (`values()`, `.scalars()` with only needed columns)

### Go

- Goroutine leaks from blocked channels or missing `context` cancellation. Watch the goroutine count
- Pass `context.Context` with deadlines everywhere
- Reduce allocations on hot paths. `sync.Pool` for big reusable buffers. Profile before tuning
- Set `GOMEMLIMIT` in containers

### JVM

- Size the heap against the container limit (`-XX:MaxRAMPercentage`). Pick a GC for the goal (G1 default, ZGC for low pause)
- Virtual threads (Java 21) make blocking I/O cheap and remove most thread pool tuning, but pinning inside `synchronized` blocks can still limit them on older JDKs
- Watch connection pool and thread pool saturation

### .NET

- Async all the way. `.Result` or `.Wait()` on tasks causes thread pool starvation
- `AsNoTracking` for reads, compiled queries for hot paths, `IAsyncEnumerable` for streaming

## Memory

- Leaks come from unbounded caches and maps, event listeners never removed, closures holding big objects, and global request registries
- Take heap snapshots at intervals during a soak test and compare
- Every in-memory cache has a size bound (LRU)
- Set runtime memory limits below the container limit so the runtime collects before the kernel kills it

## Reasoning Tools

- **Little's law:** requests in flight = arrival rate times latency. Use it to size pools and workers
- **Amdahl's law:** speeding up a part that takes 10 percent of the time can save at most 10 percent
- **Queueing:** latency rises sharply as utilization nears 100 percent. Plan to run resources at 60 to 70 percent at peak

## Cost

Performance is also cost. Fewer queries, smaller payloads and less CPU mean smaller instances and lower egress and database bills. Mention the cost effect when it is large.

## Checklist

- [ ] Latency target per hot endpoint, as percentiles
- [ ] Traces show where time goes
- [ ] Independent I/O runs concurrently with limits
- [ ] No blocking calls on the event loop or async workers
- [ ] Shared, keep-alive clients for every dependency
- [ ] Large responses paginated or streamed
- [ ] Every fix has a before and after number
