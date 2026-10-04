# Caching

A cache trades freshness and complexity for speed. Add one when a measured read path is expensive, read far more often than written, and can tolerate some staleness. Know the invalidation story before you write the first `set`.

## Layers

| Layer | Good for | Watch out for |
|-------|----------|---------------|
| HTTP and CDN | Public, cacheable GET responses and static assets | Personalized data cached publicly |
| In-process memory | Tiny, hot, rarely changing data (config, feature flags, lookup tables) | Each instance has its own copy, memory growth |
| Distributed (Redis, Memcached, Valkey) | Shared results across instances: sessions, computed views, rate limit counters | Network hop, a new dependency that can fail |
| Database | Materialized views, summary tables, the buffer cache | Refresh cost |

## Patterns

- **Cache-aside (lazy loading):** read from cache, on miss read the source and set the cache. The default choice
- **Read-through and write-through:** the cache library talks to the source. Simpler call sites, less control
- **Write-behind:** write to the cache and flush later. Fast, but data loss on crash. Rarely worth it
- **Precomputed:** a job builds the value ahead of time (leaderboards, dashboards)

## Invalidation

- Every cached value has a TTL, even when you also invalidate explicitly. The TTL bounds the damage of a missed invalidation
- On write, **delete** the key after the database commit rather than setting the new value, to avoid racing writers putting an old value back
- Versioned keys (`product:42:v17`) make invalidation a version bump
- Tag or group keys when one write affects many entries
- Keep invalidation next to the write path in code so nobody forgets it

## Keys

- Include every input that changes the result: tenant, user or role when the content depends on permissions, locale, currency, query params, API version
- A cache key that forgets the tenant or user serves one customer's data to another. Treat key design as an authorization question
- Namespace and version keys: `app:v3:tenant:{t}:product:{id}`
- Hash long inputs to keep keys short

## Stampedes

When a hot key expires, hundreds of requests miss at once and all hit the database.

- **Single-flight or request coalescing:** one request recomputes while the rest wait for its result (a lock key with `SET NX PX`, or an in-process promise map)
- **Stale-while-revalidate:** serve the expired value while one worker refreshes it
- **TTL jitter:** add random spread (plus or minus 10 percent) so keys do not expire together
- **Probabilistic early refresh (XFetch):** refresh a little before expiry with rising probability
- **Warm the cache** after deploys for known hot keys

## Negative Caching

Cache "not found" for a short TTL so repeated lookups of missing ids do not all reach the database. Keep it short so a newly created record shows up quickly.

## Failure Handling

- A cache is an optimization. When it is down or slow, fall back to the source with tight timeouts (a few milliseconds to tens of milliseconds), and protect the source with a circuit breaker and rate limit
- Never store the only copy of important data in a cache
- Do not cache errors for long. Cache 5xx results for seconds at most, or not at all

## Redis Practice

- Set `maxmemory` and an eviction policy: `allkeys-lru` or `allkeys-lfu` for a pure cache. Use a separate instance with `noeviction` for queues, locks and sessions you cannot lose
- Avoid big keys and huge collections. Paginate with `SCAN`, never `KEYS *` in production
- Pipeline or `MGET` multiple keys in one round trip
- Compact serialization (MessagePack or compressed JSON) for large values
- Monitor hit ratio, latency, memory, evictions and connected clients

## HTTP Caching

- `Cache-Control: public, max-age=60, s-maxage=300, stale-while-revalidate=30` for shared public data
- `Cache-Control: private, no-store` for anything personal or authenticated
- `ETag` or `Last-Modified` so clients revalidate with a cheap 304
- `Vary` on headers that change the response (`Accept-Encoding`, `Accept-Language`). Never `Vary: Authorization` as a way to cache personal data in a shared CDN
- Fingerprinted static assets with `max-age=31536000, immutable`

## Measure

- Hit ratio per cache and per key family
- Latency with and without the cache
- Memory use and evictions
- A cache with a low hit ratio adds latency and complexity. Remove it

## Checklist

- [ ] Added for a measured hot path, with a TTL and an invalidation plan
- [ ] Keys include tenant, user or role where the content depends on them
- [ ] Delete after commit on writes
- [ ] Stampede protection on hot keys
- [ ] Falls back to the source when the cache fails
- [ ] Personal responses are `private, no-store` at the HTTP layer
- [ ] Hit ratio monitored
