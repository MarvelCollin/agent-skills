# Observability

Observability is being able to answer a new question about production ("why is checkout slow for tenant 42 since 14:05?") from telemetry, without shipping new code. It rests on metrics, traces, logs and profiles, tied together by shared ids.

## What to Measure

**RED for every service and route** (request driven work):

- **Rate:** requests per second
- **Errors:** failed requests per second, by status class
- **Duration:** a latency histogram, so you can read p50, p95 and p99

**USE for every resource** (things that saturate):

- **Utilization:** CPU, memory, pool connections in use, worker threads busy
- **Saturation:** queue lengths, pool wait time, event loop lag, run queue
- **Errors:** connection failures, OOM kills, dropped messages

The Google SRE four golden signals (latency, traffic, errors, saturation) cover the same ground.

Plus **business metrics** (orders per minute, signups, payment success rate). They catch problems technical metrics miss.

## Metrics Practice

- Use the right type: counters for things that only go up (requests, errors), gauges for current values (in-flight requests, queue depth), histograms for distributions (latency, payload size)
- Latency is always a histogram. Choose bucket boundaries around your SLO (for a 300 ms target, buckets near 100, 200, 300, 500 ms)
- **Cardinality:** every label combination is a separate time series. Label with route templates (`/orders/:id`), method, status class, and dependency name. Never with user ids, raw URLs, emails or request ids. High-cardinality detail belongs in traces and logs
- Name metrics with units and follow OpenTelemetry semantic conventions (`http.server.request.duration` in seconds)
- Export runtime metrics: GC pauses, heap, event loop lag, goroutines, thread pools, DB pool in-use and pending

## Tracing

- OpenTelemetry SDK with auto-instrumentation for the HTTP server, HTTP clients, database drivers, cache clients and queue clients. Add manual spans around important business steps
- Propagate W3C trace context across every hop, including into job payloads and message headers
- Span attributes follow semantic conventions: `http.route`, `http.response.status_code`, `db.system`, `db.operation.name`, `server.address`. Add `tenant.id` and an opaque `user.id` when useful for debugging
- Do not put secrets or personal data in span attributes or SQL text with literal values
- Sampling: head sampling at a fixed rate for high volume, or tail sampling in the Collector to keep all errors and slow traces
- Exemplars link a latency histogram bucket to a sample trace

## Service Level Objectives

- **SLI:** a measured ratio of good events, such as requests served under 300 ms with a non-5xx status
- **SLO:** the target, such as 99.9 percent over 30 days
- **Error budget:** the allowed bad fraction (0.1 percent, about 43 minutes a month). When it is spent, reliability work comes before features
- Define SLOs for user-facing journeys (login, search, checkout), not for every internal endpoint

## Alerting

- Alert on symptoms users feel (error rate, latency, SLO burn), not on causes (CPU at 80 percent). Causes go on dashboards
- Use multi-window, multi-burn-rate alerts on SLOs: page when the budget burns fast (for example 14.4 times the normal rate over 1 hour and 5 minutes), open a ticket when it burns slowly
- Every alert is actionable, has an owner and links to a runbook. Delete alerts nobody acts on
- Alert on queue age and DLQ growth for async work, and on certificate and credential expiry

## Dashboards

One per service, top to bottom:

1. RED for the service, by route
2. Dependencies: latency and errors for the database, cache and each downstream service
3. Saturation: pools, queues, CPU, memory, event loop lag
4. Deploy markers and feature flag changes on the timeline
5. Business metrics for the service

## Error Tracking

Use an error tracker (Sentry, Rollbar, Honeybadger, or the APM's equivalent) with release and environment tags, so new errors after a deploy are visible within minutes. Scrub personal data before sending.

## Profiles

Continuous profiling (Pyroscope, Parca, cloud profilers) shows which code burns CPU and memory in production, and diffs between versions.

## Health and Synthetics

- Liveness and readiness endpoints (see [resilience.md](resilience.md))
- Synthetic checks that run key user journeys from outside every minute, so you notice outages before users report them

## Checklist

- [ ] RED metrics per route with latency histograms
- [ ] Runtime and pool saturation metrics
- [ ] OpenTelemetry tracing across services and queues
- [ ] Logs carry `trace_id`
- [ ] No high-cardinality metric labels
- [ ] SLOs on key journeys with burn-rate alerts
- [ ] Every alert has a runbook
- [ ] Error tracking tagged with release
