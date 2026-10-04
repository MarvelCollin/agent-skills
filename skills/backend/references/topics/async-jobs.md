# Background Jobs and Queues

Anything slow, unreliable or not needed for the response leaves the request path. Jobs make the API fast and let failures retry without the user waiting.

## What Goes Async

- Emails, SMS and push notifications
- Outbound webhooks and third-party syncs
- Image, video, PDF and document processing
- Report and export generation
- Search indexing, cache warming, analytics events
- Anything that takes more than a few hundred milliseconds and the user does not need in the response

The request validates, writes the record, enqueues the job after commit, and returns 201 or 202.

## Choosing a Queue

| Kind | Examples | Fits |
|------|----------|------|
| Database-backed | pg-boss, Graphile Worker, River (Go), Oban (Elixir), Solid Queue and good_job (Rails), django-q, Procrastinate | Moderate volume. Enqueue in the same transaction as the write, no new infrastructure |
| Redis-backed | BullMQ, Sidekiq, Celery with Redis, RQ, Asynq, Hangfire | High throughput job processing |
| Message brokers | RabbitMQ, Amazon SQS, Google Pub/Sub, Azure Service Bus | Decoupled services, routing, managed durability |
| Logs and streams | Kafka, Redpanda, Kinesis | Event streams, replay, many consumers, ordering per key |
| Workflow engines | Temporal, AWS Step Functions, Inngest | Long multi-step flows with state, timers and compensation |

## Job Design

- **Small payloads:** ids and the minimum context (tenant id, actor id, idempotency key). Load fresh data inside the job. Objects in the payload go stale and may carry secrets into the queue store
- **Idempotent:** delivery is at least once. Running the job twice must be harmless. Check state before acting, use upserts, pass idempotency keys to providers
- **Retries:** exponential backoff with jitter and a max attempt count. Separate retryable errors (timeouts, 5xx) from permanent ones (validation failure, record deleted) and do not retry the permanent ones
- **Dead letter queue:** jobs that exhaust retries go to a DLQ with the error. Alert on it. Build a way to inspect and replay
- **Timeouts:** every job has a maximum run time. For brokers with visibility timeouts (SQS), the timeout must exceed the job's maximum run time, or the message is redelivered while still running
- **Poison messages:** a message that crashes the worker must not block the queue forever. Count failures and move it aside
- **Unique jobs:** deduplicate with a job key when enqueuing the same work twice is likely (reindex product 42)
- **Priorities:** separate queues for fast user-facing work and slow bulk work so a big export does not delay password reset emails
- **Concurrency limits** per queue and per external API, matched to the provider's rate limits
- **Chunk big work:** one job per batch of 1,000 records, not one job for a million rows. Progress is resumable

## Enqueue After Commit

A job enqueued inside a transaction can run before the commit (it finds no row) or for a transaction that rolled back (it acts on data that does not exist). Use the framework's after-commit hook, a database-backed queue in the same transaction, or the outbox pattern (see [concurrency.md](concurrency.md)).

## Scheduled Jobs

- Run once across all replicas: a scheduler leader, an advisory lock, or the queue's cron feature. Do not run cron in every app container
- Prevent overlap: if the 5-minute job takes 7 minutes, the next run must skip or wait
- Schedule in UTC. If a job must follow local business hours, handle daylight saving transitions explicitly (a 02:30 job may run twice or never)
- Make missed runs catch up safely, or document that they do not

## Streams (Kafka and similar)

- Commit offsets after processing, not before. Processing must be idempotent because a crash replays from the last commit
- Partition by entity id to keep per-entity order. The number of partitions caps consumer parallelism
- Monitor consumer lag
- Use a schema registry and compatible schema evolution for event payloads

## Workers

- Graceful shutdown: stop fetching, finish or release current jobs, exit before the platform kill deadline
- Workers carry the same logging, tracing and tenant context as requests. Propagate the trace context from the enqueuing request into the job
- Size worker concurrency against database pool size. Workers need connections too

## Observe

- Queue depth and age of the oldest job (the best "are we behind" signal)
- Throughput, failure rate, retry rate, DLQ size
- Job duration percentiles per job type
- Alert on oldest job age and DLQ growth, not on single failures

## Checklist

- [ ] Slow and unreliable work runs in jobs
- [ ] Payloads are ids, jobs are idempotent
- [ ] Retries with backoff, a max, and a DLQ that alerts
- [ ] Enqueued after commit
- [ ] Scheduled jobs run once and never overlap
- [ ] Queue depth and oldest job age monitored
