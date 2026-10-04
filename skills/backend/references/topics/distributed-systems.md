# Distributed Systems Patterns

Patterns for work that spans services, queues or long periods of time. Each one solves a real problem and adds real cost. Reach for them when a modular monolith with one database no longer fits (see [architecture.md](architecture.md)), not before.

## Splitting a System

- **Strangler fig:** put a routing layer in front of the old system and move one capability at a time to the new one. Each step is shippable and reversible. Never plan a big-bang rewrite
- **Anti-corruption layer:** a translation layer between your model and a legacy or third-party model, so their concepts and quirks do not leak into your domain
- **Backend for frontend:** a thin API per client type (web, mobile, partner) that aggregates and shapes data for that client. Business rules stay in the services underneath
- **API gateway:** one entry point for auth, rate limiting, routing and TLS. Keep business logic out of it
- **Service discovery:** use the platform's (Kubernetes DNS, cloud service registry). Do not hardcode hosts

## Communication

| Style | Use when | Rules |
|-------|----------|-------|
| Synchronous request (HTTP, gRPC) | The caller needs the answer to continue | Deadlines, retries only on idempotent calls, circuit breakers ([resilience.md](resilience.md)). Keep call chains short |
| Command over a queue | One service asks another to do something later | One consumer owns it. Idempotent handler |
| Event (pub/sub) | A service announces that something happened | Past tense name, no expectation of a reply, many consumers |
| Request and reply over messaging | Async work that still returns a result | Correlation id, reply queue, timeout |

**A timeout is not a failure.** When a call times out, the other side may have done the work. Make operations idempotent, retry with the same key, and reconcile with a periodic job that compares state.

## Sagas

A saga runs a business process across services as a sequence of local transactions. When a step fails, compensating actions undo the earlier ones (refund the payment, release the stock). There is no distributed transaction and no two-phase commit.

| | Orchestration | Choreography |
|---|---------------|--------------|
| How | A coordinator tells each service what to do next | Each service reacts to the previous service's events |
| Fits | More than three steps, branching, timeouts, visibility needs | Two or three simple steps |
| Risk | The coordinator becomes a hub | Nobody can see the whole flow. Cyclic event chains |

Rules:
- Persist the saga state (id, current step, status, data) in the orchestrator's database and log every transition with the saga id
- Every step and every compensation is idempotent, because messages are redelivered
- Compensate in reverse order. A step that partly ran still needs compensation
- Give each step its own timeout. One global timeout fits no step well
- Identify the pivot step, the point after which the saga only moves forward (for example once the payment is captured). Steps after it must be retryable until they succeed
- Use semantic locks: mark records as pending (`order.status = 'pending_payment'`) so other operations know they are mid-flight
- Test the compensation path by injecting a failure at every step. It is the hardest code to get right and the least exercised

## Workflow Engines

Temporal, AWS Step Functions, Azure Durable Functions and Inngest run long processes with durable state, timers, retries and history built in. Choose one over a hand-rolled saga when processes run for minutes to months, wait on humans or timers, or have many branches.

With Temporal and similar engines:
- Workflow code must be deterministic: no direct I/O, random numbers or wall-clock time. Side effects go in activities
- Activities get timeouts and retry policies, and must be idempotent
- Version workflow code carefully. Running workflows replay old history against new code

## Event-Driven Design

- **Event shape:** a unique id, a type with a version (`order.placed.v2`), when it occurred, the entity id, the producer, and the data
- **Notification or state transfer:** a thin event ("order 42 changed") makes consumers call back for details. A fat event carries the state consumers need, which removes the callback but couples them to the payload
- **Schema evolution:** add optional fields freely. Never rename, retype or remove a field in place. Publish a new version and run both until consumers move. A schema registry (Avro, Protobuf, JSON Schema) enforces compatibility
- **Publishing:** the transactional outbox, so the database write and the event cannot diverge ([concurrency.md](concurrency.md))
- **Consuming:** idempotent handlers with an inbox table of processed ids. Ordering only within a partition key. Dead letter queue with replay tooling
- **Replay:** keep events long enough to rebuild a consumer's state from scratch

## Event Sourcing

Store the sequence of events as the source of truth and derive current state by replaying them.

- **Fits:** domains where history matters as much as state (ledgers, audit-heavy workflows, temporal queries like "what did the cart look like at 14:05")
- **Costs:** every read model must be built and kept in sync, schema evolution of old events is permanent work, and deleting personal data needs crypto-shredding (encrypt per subject, delete the key)
- **Event store:** one stream per aggregate, append with an expected version for optimistic concurrency, events immutable
- **Snapshots:** save state every N events so loading an aggregate stays fast
- **Upcasting:** convert old event versions to the current shape at read time

Do not event source a whole system by default. Apply it to the one aggregate that needs it.

## CQRS and Projections

Separate the write model (validates commands, enforces invariants) from read models shaped for each query.

- **Projections** consume events and update read tables. They must be idempotent, track their position (checkpoint), and be rebuildable from zero
- **Eventual consistency** shows in the UI: after a command, either return the new state from the command itself or show a pending state until the projection catches up
- **When not to:** plain CRUD with similar read and write shapes. CQRS doubles the moving parts

## Data Across Services

- Each service owns its tables. Others use its API or its events
- Need another service's data often? Keep a local read-only copy updated by its events, instead of calling it on every request
- API composition (calling several services and merging) needs parallel calls, deadlines and a partial-result policy
- Joins across services do not exist. Design boundaries so most queries stay inside one

## Time and Ordering

- Wall clocks on different machines disagree. Never order cross-node events by timestamp alone
- Order with sequence numbers from a single writer, partition offsets, or version numbers per entity
- Store both the time an event occurred and the time it was recorded

## Consistency Models

| Model | Promise | Typical use |
|-------|---------|-------------|
| Strong | Every read sees the latest write | Money, inventory, permissions |
| Read your writes | A user sees their own changes immediately | Profiles, settings, "my orders" |
| Monotonic reads | A user never sees data go backwards | Feeds, timelines |
| Eventual | Everyone converges, eventually | Counters, search, recommendations, analytics |

Pick per operation, not per system, and make the user-visible effect explicit.

## Testing

- Contract tests between producer and consumer for APIs and event schemas (Pact supports messages)
- Saga tests that fail each step and check every compensation
- Replay tests that rebuild a projection from the event log and compare it with the live one
- Fault injection: drop, duplicate, delay and reorder messages in staging

## Checklist

- [ ] A concrete reason to distribute, written as an ADR
- [ ] Short synchronous chains with deadlines, events for announcements
- [ ] Every cross-service operation idempotent, with reconciliation for unknown outcomes
- [ ] Sagas persisted, compensated in reverse, each step with its own timeout, compensations tested
- [ ] Events versioned, published through an outbox, consumed idempotently
- [ ] Event sourcing and CQRS only where the domain needs them
- [ ] Ordering by sequence, not by wall clock
