# Transactions, Concurrency and Idempotency

Concurrency bugs pass every test run serially and then corrupt data under real traffic: double charges, oversold stock, duplicate accounts, lost updates.

## Transactions

- Group writes that must succeed or fail together into one transaction
- Keep it short. Never call an external API, send an email, or wait on a user inside a transaction. It holds locks and a pooled connection the whole time
- Set the isolation level on purpose:
  - **Read Committed** (Postgres default): each statement sees committed data. Good for most work, but read-then-write sequences can race
  - **Repeatable Read** (MySQL InnoDB default): a stable snapshot. Postgres raises serialization errors on conflicting updates, so be ready to retry
  - **Serializable:** behaves as if transactions ran one at a time. Safest, but you must retry on serialization failure (SQLSTATE `40001`)
- Retry deadlocks and serialization failures a few times with jitter. Wrap the whole transaction, not one statement
- Avoid deadlocks by taking locks in a consistent order (sort ids before updating many rows)

## Race Conditions

The classic bug is check then act:

```python
item = Item.objects.get(id=item_id)
if item.stock >= qty:
    item.stock -= qty
    item.save()
```

Two requests read stock 1 at the same time, both pass, stock goes to minus 1.

**Fixes, from simplest:**

1. **Atomic conditional update.** Let the database check and change in one statement, then look at the affected row count:

```sql
UPDATE items SET stock = stock - $1 WHERE id = $2 AND stock >= $1
```

   Zero rows updated means out of stock. Django `F()` expressions, Rails `update_counters` or `where(...).update_all`, and ORM `increment` helpers do the same

2. **Unique constraints** for "only one": one active subscription per user, one vote per poll, one claim per coupon. Insert and handle the conflict (`INSERT ... ON CONFLICT DO NOTHING`)

3. **Optimistic locking.** A `version` column. Update with `WHERE id = $1 AND version = $2` and increment it. Zero rows means someone else changed it, so reload and retry or return 409. JPA `@Version`, Rails `lock_version`, EF concurrency tokens. Expose it to clients as an `ETag`

4. **Pessimistic locking.** `SELECT ... FOR UPDATE` inside a short transaction when contention is high and retries are costly. `FOR UPDATE SKIP LOCKED` lets workers claim different rows from a queue table without blocking each other. `NOWAIT` fails fast

5. **Advisory locks** (`pg_advisory_xact_lock`) to serialize work on a logical key that is not a row, such as one sync per customer

## Distributed Locks

Avoid them when a database constraint or atomic update can do the job. If you need one:

- Use a lease with an expiry so a crashed holder does not block forever
- A paused process (GC, network) can wake up after its lease expired and still think it holds the lock. Protect the resource with a fencing token: a number that increases with each lock grant, checked by the resource on every write
- Redis single-instance locks (`SET key value NX PX 30000`) are fine for efficiency (avoid duplicate work), not for correctness. For correctness use the database, ZooKeeper or etcd

## Idempotency

At-least-once delivery is the norm: client retries, load balancer retries, queue redeliveries, webhook resends. Make repeated delivery harmless.

- **API:** `Idempotency-Key` on unsafe POSTs (see [api-design.md](api-design.md)). Store the key and result in the same transaction as the effect
- **Natural keys:** an upsert keyed by a business id (`external_payment_id`) is idempotent by design
- **Consumers:** an inbox table of processed message ids with a unique constraint. Insert the id and do the work in one transaction. A duplicate fails the insert and is skipped
- **Side effects you cannot roll back** (emails, third-party charges): pass your idempotency key to the provider (Stripe, most payment APIs accept one), and record that the effect happened before acknowledging

## The Dual Write Problem and the Outbox

Writing to the database and then publishing to a broker can half fail: the row commits and the publish fails, or the publish succeeds and the transaction rolls back.

**Transactional outbox:**

1. In the same transaction as the business write, insert the event into an `outbox` table
2. A relay reads the outbox in order and publishes, marking rows sent. Use a poller with `FOR UPDATE SKIP LOCKED`, or change data capture (Debezium) on the outbox table
3. Consumers deduplicate by event id because the relay can publish twice

The same rule applies to jobs: **enqueue after commit**. A job enqueued inside a transaction can run before the commit and find no row, or run for a transaction that rolled back. Use `transaction.on_commit` (Django), `after_commit` (Rails), a database-backed queue in the same transaction (pg-boss, Oban, Solid Queue, River, good_job), or the outbox.

## Sagas

For a business flow across services with no shared transaction (order, payment, shipping), use a saga: a sequence of local transactions, each with a compensating action (refund, release stock) when a later step fails. Orchestrate it explicitly or with a workflow engine (Temporal, AWS Step Functions) instead of chains of events nobody can trace.

## Ordering

- Brokers order messages only within a partition or group. Key messages by the entity id (Kafka partition key, SQS FIFO message group) to keep per-entity order
- Consumers should tolerate out-of-order events: carry a version or timestamp and ignore stale ones

## In-Process Concurrency

- Module-level mutable state in Node or Python is shared by every concurrent request. Keep request data in request scope
- `async` code still races at every `await`
- Go: run tests with `-race`. Protect shared maps with a mutex or use channels
- Java: prefer immutable objects and concurrent collections. Virtual threads (Java 21) make blocking cheap but do not remove races

## Checklist

- [ ] Multi-step writes in short transactions, no network calls inside
- [ ] No check-then-act on shared state. Atomic updates, constraints or locks instead
- [ ] Unique business rules enforced by unique indexes
- [ ] Idempotency keys on payments, orders and other effects that matter
- [ ] Outbox or after-commit for events and jobs
- [ ] Consumers deduplicate by message id
- [ ] A parallel-request test for each critical invariant
