# Architecture and Scaling

Choose the simplest architecture that meets today's needs with a clear path to the next order of magnitude. Most systems fail from accidental complexity long before they hit hardware limits.

## Code Structure

- **Thin handlers:** parse and validate input, resolve the caller, call a service, map the result to a response. No business rules and no queries in controllers
- **Services** hold business logic and authorization decisions, and own transactions
- **Repositories or query modules** hold data access. One place to add tenant scoping, eager loading and pagination
- **Domain types** for important concepts (Money, EmailAddress, OrderStatus) instead of loose strings and numbers
- **Dependencies injected** (clients, clock, config) so they can be replaced in tests
- **No database access from serializers, views or templates**

## Domain Modeling

For business logic that is more than CRUD, model the domain explicitly. For plain CRUD, skip this. It is overhead there.

- **Bounded contexts:** split the domain into areas that each have one consistent model and vocabulary (billing, catalog, shipping). The same word can mean different things in different contexts, and that is fine. These are also the natural module and service boundaries
- **Ubiquitous language:** names in code match the words domain experts use
- **Entities** have identity that persists as they change (an order). **Value objects** are defined by their values and are immutable (Money, EmailAddress, DateRange). Validate value objects at construction so an invalid one cannot exist
- **Aggregates** are consistency boundaries: a root entity plus what must change with it (an order and its lines). Change one aggregate per transaction, reach inner objects only through the root, and refer to other aggregates by id
- **Domain events** record what happened (`OrderPlaced`) and coordinate between aggregates and contexts, published through the outbox
- **Repositories** load and save whole aggregates. One per aggregate root, not one per table

### Hexagonal Architecture (Ports and Adapters)

- The domain core has no framework, database or HTTP imports
- **Ports** are interfaces the core defines: `OrderRepository`, `PaymentGateway`, `Clock`
- **Adapters** implement them: a Postgres repository, a Stripe gateway, an HTTP controller
- Dependencies point inward. The core never imports an adapter
- Unit tests swap in in-memory adapters, so business rules are tested without a database. Integration tests cover the real adapters

Clean Architecture and Onion Architecture are variations of the same idea. Pick one vocabulary per codebase and keep it.

## Monolith First

- Start with a modular monolith: one deployable, clear internal modules with explicit interfaces, no reaching into another module's tables
- Split out a service only for a concrete reason: independent scaling, a different runtime need, a separate team that must deploy independently, or a strong isolation requirement
- Warning signs of a distributed monolith: services that must deploy together, shared database tables, chains of synchronous calls for one user request, one change touching many services

## Services and Data

- Each service owns its data. Others go through its API or its events, never its tables
- Synchronous calls (HTTP, gRPC) when the caller needs the answer now. Asynchronous events when the caller only needs to announce something happened
- Avoid long synchronous chains. Each hop multiplies failure probability and adds latency. Five services at 99.9 percent each is about 99.5 percent together
- An API gateway or backend-for-frontend handles auth, rate limiting and aggregation at the edge

## Events

- Events describe facts in the past tense (`OrderPlaced`) with an id, a timestamp, a version and the entity id
- Version event schemas and evolve them compatibly (a schema registry with Avro, Protobuf or JSON Schema)
- Delivery is at least once, so consumers are idempotent
- Publish with the outbox pattern (see [concurrency.md](concurrency.md))
- Keep a way to replay events for rebuilding read models

## Consistency

- **CAP and PACELC:** during a partition you choose availability or consistency. Even without one you trade latency for consistency
- Strong consistency where money, inventory, access rights and uniqueness are involved
- Eventual consistency where staleness is acceptable: feeds, counters, search, analytics, recommendations
- Make the user-facing effect of eventual consistency explicit (read your own writes from the primary, show "processing" states)

## Scaling

- **Stateless app tier:** no local sessions, uploads or caches that must survive. Any instance can serve any request, so you scale horizontally behind a load balancer
- **Reads:** indexes first, then caching, then read replicas, then read models built for specific queries (CQRS when read and write shapes really differ)
- **Writes:** batch and queue them, partition data by tenant or key, and shard only when one primary truly cannot keep up
- **Hot spots:** one huge tenant or one hot row (a global counter) limits scaling. Spread with sharded counters, per-tenant limits or dedicated capacity
- **Async smoothing:** queues absorb spikes so the database sees a steady rate

## Capacity Planning

- Back-of-envelope first: daily active users, requests per user, peak-to-average ratio (often 3 to 10), payload sizes, data growth per month
- Example: 100,000 daily users times 50 requests is 5 million a day, about 58 per second on average, about 300 per second at a 5x peak
- Validate estimates with load tests (see [../load-testing.md](../load-testing.md)) and keep 30 to 50 percent headroom at peak
- Track growth trends for storage, connections and the largest tables

## Multi-Region and Availability

- Most products need multiple availability zones, not multiple regions
- Multi-region adds data replication and conflict problems. Do it for a clear requirement (latency for distant users, regulatory residency, regional disaster recovery)
- Know your single points of failure: one database primary, one Redis, one queue, one third-party provider

## Decision Records

Record significant choices as short architecture decision records: the context, the options, the decision, and its consequences. Future maintainers need the why.

## Checklist

- [ ] Thin handlers, services own logic and transactions, repositories own queries
- [ ] Modules or services own their data
- [ ] Synchronous chains kept short, events for announcements
- [ ] Strong consistency where correctness demands it
- [ ] Stateless app tier that scales horizontally
- [ ] Capacity estimates checked with load tests
