# API Design

A good API is predictable: the same conventions everywhere, explicit contracts, and evolution without breaking clients.

## Resources and Methods

- Nouns, plural, lowercase with hyphens: `/orders`, `/orders/{id}`, `/orders/{id}/items`. Nest at most one level. Use query filters beyond that
- Actions that do not fit CRUD become sub-resources or explicit commands: `POST /orders/{id}/cancel`
- Method semantics:

| Method | Safe | Idempotent | Use |
|--------|------|------------|-----|
| GET | yes | yes | Read. Never changes state |
| HEAD | yes | yes | Headers only |
| PUT | no | yes | Replace the whole resource |
| PATCH | no | not by default | Partial update with JSON Merge Patch (RFC 7396) or JSON Patch (RFC 6902) |
| DELETE | no | yes | Remove. A second delete returns 404 or 204, consistently |
| POST | no | no | Create or command. Make it idempotent with an `Idempotency-Key` |

## Status Codes

| Code | When |
|------|------|
| 200 | Success with a body |
| 201 | Created, with a `Location` header |
| 202 | Accepted for async processing, with a link to poll the operation |
| 204 | Success with no body |
| 304 | Not modified (conditional GET) |
| 400 | Malformed request |
| 401 | Not authenticated, with `WWW-Authenticate` |
| 403 | Authenticated but not allowed (use 404 when existence must not leak) |
| 404 | Not found or not visible to this caller |
| 409 | Conflict with current state (duplicate, wrong state transition, idempotency key in use) |
| 412 | Precondition failed (`If-Match` did not match) |
| 413 | Body too large |
| 415 | Unsupported content type |
| 422 | Valid syntax, invalid content |
| 428 | Precondition required (you demand `If-Match`) |
| 429 | Rate limited, with `Retry-After` |
| 500 | Unexpected server error, generic body |
| 502, 504 | Upstream failed or timed out |
| 503 | Overloaded or in maintenance, with `Retry-After` |

## Errors

Use RFC 9457 problem details (`application/problem+json`) for every error, everywhere. See [errors.md](errors.md).

## Pagination, Filtering, Sorting

- Cursor pagination for feeds and large lists: `GET /orders?limit=20&cursor=eyJ...` returning `{ "data": [...], "next_cursor": "...", "has_more": true }`. Offset for small admin lists. See [database.md](database.md)
- `limit` defaults to 20 and is capped at 100
- Filters are explicit and allowlisted: `?status=paid&created_after=2026-01-01T00:00:00Z`
- Sorting from an allowlist with a direction: `?sort=-created_at`. Always add a unique tiebreaker server-side
- Sparse fieldsets (`?fields=id,status,total`) help mobile clients on wide resources

## Idempotency

Clients retry. Networks drop responses after the server committed. For unsafe POSTs that matter (payments, orders, sends), accept an `Idempotency-Key` header (IETF httpapi draft, the pattern Stripe popularized):

1. Store the key with a hash of the request and the caller id, in the same transaction as the effect
2. Same key and same request returns the stored response
3. Same key and a different request returns 422
4. Same key still in progress returns 409
5. Keys expire after about 24 hours

## Concurrency Control

- Return an `ETag` (a version or hash) on reads
- Require `If-Match` on updates to contended resources. A stale version gets 412, so two editors cannot silently overwrite each other (lost update)
- `If-None-Match` on GET lets clients and CDNs get a cheap 304

## Versioning and Evolution

- Additive changes are not breaking: new optional fields, new endpoints, new enum values (if clients were told to tolerate unknown values)
- Breaking changes: removing or renaming fields, changing types or meaning, making optional input required, tightening validation. These need a new version
- Version in the path (`/v2/`) or a header. Pick one and keep it
- Deprecate with the `Deprecation` header (RFC 9745), the `Sunset` header (RFC 8594) with the removal date, and a `Link` with `rel="deprecation"` to the migration guide. Track who still calls the old version before removing it
- Never reuse a removed field name with a different meaning

## Contracts

- OpenAPI 3.1 is the source of truth, written first or generated from code, published with every release
- Generate server validators, client SDKs and types from it
- Lint the spec (Spectral) and fail CI on breaking changes (oasdiff)
- Contract tests between services (Pact) or response validation against the spec in integration tests
- Keep the inventory complete (OWASP API9). No undocumented, debug or forgotten old endpoints in production

## Long-Running Work

- Return 202 with an operation resource: `Location: /operations/{id}`. The client polls it, or you call a webhook when done
- Never hold an HTTP request open for minutes

## Webhooks (outbound)

- Sign every delivery with HMAC-SHA-256 over the timestamp and body. Receivers verify the signature and reject old timestamps (about 5 minutes) to stop replay
- Include a unique event id so receivers can deduplicate
- Deliver from a job queue with retries, exponential backoff and a dead letter queue. Show delivery logs to customers
- Small payloads with ids. Let receivers fetch details with their own authorization

## Data Formats

- Timestamps: ISO 8601 with offset, in UTC: `2026-10-02T09:30:00Z`
- Money: integer minor units with a currency (`{ "amount": 1999, "currency": "USD" }`) or a decimal string. Never a float
- 64-bit ids as strings for JavaScript clients (precision ends at 2^53)
- Booleans are booleans, not `"Y"` or `1`
- Enable gzip or Brotli for JSON responses above about 1 KB

## Bulk Operations

- Cap batch size (100 to 1000 items)
- Report per-item results so partial failure is visible
- Run large batches as async jobs

## GraphQL

- A DataLoader per request for every relation resolver, or N+1 is guaranteed
- Limits on query depth, complexity or cost, and on page size per connection
- Persisted queries (allowlisted operations) for first-party clients
- Authorization in the business layer, checked per field where fields differ in sensitivity
- Cursor-based connections for lists
- Disable introspection in production if the schema is not public

## gRPC

- Set a deadline on every call and propagate it
- Evolve protobufs safely: never reuse or renumber field numbers, mark removed ones `reserved`
- Map errors to standard status codes with details

## Real-Time

- Server-Sent Events for one-way server push. Plain HTTP, auto reconnect with `Last-Event-ID`
- WebSockets for two-way. Authenticate on connect, recheck when the token expires, send heartbeats, bound the per-connection send buffer (backpressure), and limit message size and rate
- Scale out with a pub/sub backbone (Redis, NATS, Kafka) so any instance can push to any client

Details on transports, reconnection, delivery guarantees and scaling: [realtime.md](realtime.md).

## Rate Limit Headers

Return `429` with `Retry-After`. Advertise quotas with the `RateLimit` and `RateLimit-Policy` fields from the IETF httpapi draft, or the widely deployed `RateLimit-Limit`, `RateLimit-Remaining` and `RateLimit-Reset`.

## Checklist

- [ ] Consistent resource naming and method semantics
- [ ] Correct status codes and problem details everywhere
- [ ] Paginated, filtered and sorted from allowlists, with caps
- [ ] Idempotency keys on unsafe POSTs that matter
- [ ] ETag and `If-Match` on contended updates
- [ ] OpenAPI spec in CI with breaking-change checks
- [ ] Deprecation and sunset headers on old versions
