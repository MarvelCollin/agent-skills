# Real-Time and Streaming

Pushing data to clients as it changes. Long-lived connections behave differently from request and response: they hold memory, survive deploys badly, and fail silently. Design for reconnects from the start.

## Pick the Transport

| Transport | Direction | Fits | Watch out for |
|-----------|-----------|------|---------------|
| Polling | Client pulls | Updates every 30 seconds or slower, simple dashboards | Wasted requests. Use `ETag` and 304s |
| Long polling | Client pulls, server holds | Legacy clients, restrictive networks | One request per message, timeouts at proxies |
| Server-Sent Events | Server to client | Notifications, feeds, progress, AI token streaming | One direction only. Browsers allow 6 connections per domain on HTTP/1.1, so serve SSE over HTTP/2 |
| WebSockets | Both ways | Chat, collaboration, games, live cursors | Stateful connections, custom protocol, harder to scale and secure |
| Webhooks | Server to server | Notifying another backend | Signatures, retries, idempotent receivers (see [api-design.md](api-design.md)) |

Choose the simplest that works. SSE covers most "push updates to the browser" needs and rides on plain HTTP, auth and proxies.

## Connection Lifecycle

- **Authenticate at connect.** Browsers cannot set headers on a WebSocket handshake. Use the session cookie (and check `Origin` to stop cross-site WebSocket hijacking), or exchange the access token for a short-lived single-use ticket and pass that. Never put a long-lived token in the URL, where it ends up in logs
- **Re-authenticate.** When the session or token expires, close the connection or require a refresh message. A socket that outlives a revoked session is an authorization hole
- **Heartbeats.** Ping every 20 to 30 seconds and close connections that miss two. Load balancers drop idle connections (AWS ALB defaults to 60 seconds), and dead TCP peers are invisible without traffic. For SSE, send a comment line (`: keepalive`) on the same schedule
- **Close codes.** Use meaningful WebSocket codes so clients react correctly: 1000 normal, 1001 going away, 1008 policy violation (auth failed), 1009 message too big, 1011 server error, 1012 service restart, 1013 try again later, 4000 to 4999 for your own reasons

## Client Reconnection

- Reconnect with exponential backoff and full jitter, capped (for example 30 seconds). Without jitter, a deploy makes every client reconnect at the same moment and the new instances fall over
- Resume instead of restarting. SSE has this built in: send `id:` with every event and the browser sends `Last-Event-ID` on reconnect. For WebSockets, have the client send its last sequence number
- On resume, replay missed messages from a durable store (a table, Redis Streams, Kafka) or tell the client to refetch state

## Delivery Guarantees

A socket delivers at most once. If a message matters:

- Persist it first, then push it
- Give every message a sequence number per channel so the client can detect gaps and reorder
- Have the client acknowledge important messages, and redeliver the unacknowledged ones on reconnect
- Make client handling idempotent because redelivery means duplicates

## Backpressure and Limits

- Check the send buffer (`bufferedAmount` in `ws`, the writable state in your server) before writing. Drop, coalesce or disconnect slow consumers instead of buffering without limit
- Cap inbound message size and rate per connection
- Validate every inbound message with a schema, like any request body
- Cap connections per user and per IP

## Channels and Authorization

- Clients subscribe to channels or rooms. Authorize every subscription on the server: the user may join `org:42:orders` only if they belong to org 42
- Build channel names from server-side identity, never from a raw client string
- Authorize every inbound action, not just the connection
- Never broadcast data a subset of subscribers may not see. Fan out per authorized audience

## Scaling Out

- Each connection costs memory (tens of KB or more). Measure it and size instances by connections, not only by CPU
- Fan out across instances with a pub/sub backbone: Redis pub/sub for ephemeral messages, Redis Streams, NATS or Kafka when you need replay. Socket.IO uses the Redis or Postgres adapter for this
- Sticky sessions are needed only when a protocol falls back to long polling (Socket.IO does). Pure WebSocket and SSE connections stick to one instance by nature
- Presence ("who is online") lives in Redis with short TTLs refreshed by heartbeats, not in instance memory
- Set the load balancer and proxy idle timeouts above the heartbeat interval. For SSE behind NGINX, disable response buffering (`X-Accel-Buffering: no`)

## Deploys and Shutdown

- On `SIGTERM`, stop accepting new connections, send close code 1012 (or end the SSE stream), and give clients time to reconnect elsewhere before the process exits
- Client jitter spreads the reconnect wave. Roll instances gradually
- Keep the protocol versioned so old clients survive a deploy that changes message shapes

## Observability

- Gauge of open connections per instance
- Messages in and out per second, fan-out latency from publish to delivery
- Send buffer or queue depth, slow-consumer disconnects
- Reconnect rate (a spike means instability or a bad deploy)
- Authorization failures on subscribe

## Testing

- Unit test message handlers like request handlers
- Integration test auth on connect, subscribe authorization, and resume after reconnect
- Load test with k6 WebSockets (`k6/experimental/websockets`) or Artillery: ramp connections, hold them, measure fan-out latency and memory per connection

## Checklist

- [ ] Simplest transport that works (SSE before WebSockets)
- [ ] Auth at connect without long-lived tokens in URLs, `Origin` checked, re-auth on expiry
- [ ] Heartbeats under every proxy idle timeout
- [ ] Clients reconnect with jittered backoff and resume from the last id
- [ ] Important messages persisted, sequenced and acknowledged
- [ ] Backpressure, message size and rate limits
- [ ] Every subscription and action authorized
- [ ] Pub/sub backbone for multiple instances
- [ ] Graceful drain on deploy
