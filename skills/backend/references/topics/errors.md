# Error Handling

Good error handling gives clients a clear, safe answer, gives operators the full story, and never leaves data half-changed.

## Classify Errors

| Class | Examples | Status | Log level |
|-------|----------|--------|-----------|
| Client input | Validation failed, malformed JSON | 400, 422 | info or none |
| Auth | Not logged in, not allowed | 401, 403, 404 | info, security event |
| State | Not found, conflict, wrong state transition, stale version | 404, 409, 412 | info |
| Limits | Rate limited, too large | 429, 413 | info, sampled |
| Dependency | Upstream timeout or 5xx, circuit open | 502, 503, 504 | warn or error |
| Bug | Null reference, unhandled case, failed invariant | 500 | error with stack |

Expected errors are part of the API contract and do not page anyone. Unexpected errors are bugs, logged with full context and tracked.

## Domain Errors

Throw or return typed domain errors (`NotFound`, `Conflict`, `Forbidden`, `ValidationFailed`, `DependencyUnavailable`) from the service layer. The service does not know about HTTP. One central handler maps types to status codes.

## One Central Handler

All errors flow to one place that:

1. Maps known error types to status codes and problem details
2. Treats everything else as a 500 with a generic body
3. Logs once: expected errors at a low level, unexpected ones with the stack trace, request id, route and user id
4. Reports unexpected errors to the error tracker
5. Adds the request id to the response

```js
app.use((err, req, res, next) => {
  const known = toProblem(err)
  if (!known) req.log.error({ err }, 'unhandled error')
  const problem = known ?? { type: 'about:blank', title: 'Internal Server Error', status: 500 }
  res.status(problem.status).type('application/problem+json').json({ ...problem, request_id: req.id })
})
```

```python
@app.exception_handler(Exception)
async def unhandled(request, exc):
    logger.exception("unhandled error")
    return JSONResponse(
        {"type": "about:blank", "title": "Internal Server Error", "status": 500, "request_id": request.state.request_id},
        status_code=500,
        media_type="application/problem+json",
    )
```

## Problem Details (RFC 9457)

```json
{
  "type": "https://api.example.com/problems/insufficient-stock",
  "title": "Insufficient stock",
  "status": 409,
  "detail": "Only 2 units of SKU-123 are available.",
  "instance": "/orders",
  "request_id": "01J9Z3K8V6M5"
}
```

- `type` is a stable URI clients can switch on, documented in the API docs
- `title` is a short constant summary. `detail` is specific to this occurrence and safe to show
- Extension fields (`errors`, `request_id`, `retry_after`) are allowed
- Content type `application/problem+json`

## Never Leak

Responses never include stack traces, exception class names, SQL, ORM messages, file paths, internal hostnames or IPs, library versions, or raw upstream error bodies. Turn off framework debug pages in production (`DEBUG=False`, `NODE_ENV=production`, `ASPNETCORE_ENVIRONMENT=Production`).

## Never Swallow

```js
try { await charge(order) } catch (e) {}
```

The charge failed, the order is marked paid, and nobody knows. Instead:

- Handle the error (retry, fallback, compensate) and record that you did, or
- Let it propagate to the central handler
- Catch the narrowest exception type you can handle. `except:` in Python also catches `KeyboardInterrupt` and `SystemExit`
- After a partial failure, undo or compensate so data stays consistent (transactions, sagas)

## Process-Level Failures

- Node: handle `unhandledRejection` and `uncaughtException` by logging and exiting. The process manager restarts a clean process. Continuing after an uncaught exception runs in an unknown state
- Python asyncio: set a loop exception handler, and always await or attach callbacks to created tasks so their exceptions are not lost
- Go: a recover middleware turns handler panics into 500s with a log line. Panics in other goroutines still crash the process, so recover there too where appropriate
- Java and .NET: global exception handlers per thread pool, and observe failed tasks

## Fail Fast at Startup

Validate config, check the database connection and required migrations, and load secrets before reporting ready. A service that boots with bad config fails later in confusing ways.

## Checklist

- [ ] Typed domain errors, one central handler
- [ ] Problem details with request id on every error
- [ ] Generic 500 bodies, debug mode off in production
- [ ] No empty catches, no bare `except`
- [ ] Unexpected errors logged once with stack and sent to the error tracker
- [ ] Process-level handlers log and exit cleanly
