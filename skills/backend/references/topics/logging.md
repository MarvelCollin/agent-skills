# Logging

Logs exist to answer questions during an incident and an audit: what happened, to whom, when, and why. Structured, correlated, low-noise logs answer them. A wall of free text with secrets in it creates a second incident.

## Structured by Default

- One JSON object per line, written to stdout. The platform or a collector ships it (OpenTelemetry Collector, Fluent Bit, Vector)
- Use the stack's structured logger, configured once and imported everywhere:

| Stack | Logger |
|-------|--------|
| Node | pino (fast, built-in redaction), winston |
| Python | structlog, or stdlib `logging` with a JSON formatter |
| Go | `log/slog` (standard library), zap, zerolog |
| Java and Kotlin | SLF4J with Logback or Log4j2 and a JSON encoder |
| .NET | `ILogger` with Serilog or the built-in JSON console formatter |
| Ruby on Rails | semantic_logger, lograge for request lines |
| PHP | Monolog with a JSON formatter |

- No `console.log`, `print`, `puts`, `System.out.println` or `fmt.Println` in server code

## Standard Fields

Every line carries:

| Field | Example |
|-------|---------|
| `timestamp` | `2026-10-02T09:30:00.123Z` (UTC, ISO 8601) |
| `level` | `info` |
| `message` | `order created` (a stable event name, not a sentence with values baked in) |
| `service`, `version`, `env` | `orders-api`, `1.14.2`, `production` |
| `trace_id`, `span_id` | W3C trace context ids |
| `request_id` | from the `X-Request-Id` header or generated at the edge |
| `user_id`, `tenant_id` | opaque ids when known, never emails or names |

Request summary lines add `method`, `route` (the template, `/orders/:id`), `status`, `duration_ms`, `bytes`.

Put values in fields, not in the message string. `logger.info({ orderId, totalCents }, "order created")` can be searched and aggregated. `"Order 42 created for $19.99"` cannot.

## Correlation

- Accept an incoming `X-Request-Id` (validate its format and length) or generate one at the edge. Echo it in the response header and in error bodies
- Propagate W3C `traceparent` to every downstream HTTP call and into job payloads
- Store request context in async-local storage so every log line picks it up without passing it by hand: `AsyncLocalStorage` (Node), `contextvars` (Python), MDC (Java), `context.Context` (Go), `ILogger` scopes (.NET)
- OpenTelemetry log bridges add `trace_id` and `span_id` automatically, which lets you jump from a slow trace to its log lines

## Levels

| Level | Meaning | Production |
|-------|---------|------------|
| `error` | Something failed and a human may need to act | On, alerts on rate |
| `warn` | Unexpected but handled (retry succeeded, fallback used, deprecated call) | On |
| `info` | Business events and one summary line per request or job | On, sampled at very high volume |
| `debug` | Detail for diagnosing | Off, or enabled per request or per service temporarily |

Log level is config, changeable without a deploy.

## Never Log

- Passwords, even failed attempts
- Tokens, API keys, session ids, cookies, `Authorization` headers, signed URLs, reset links
- Private keys, connection strings, secrets
- Card numbers (PCI), bank details, government ids
- Full personal data: names, emails, phones, addresses, health data. Log an opaque id
- Full request and response bodies by default

Enforce it in the logger, not by hoping each call site remembers:

```js
const logger = pino({
  redact: {
    paths: ['req.headers.authorization', 'req.headers.cookie', '*.password', '*.token', '*.apiKey', '*.secret'],
    censor: '[redacted]',
  },
})
```

Python structlog and stdlib logging: a processor or filter that masks known keys. Java: Logback masking patterns. Add a test that logs a fake secret and asserts it does not appear.

## Errors

- Log an error once, where it is handled (usually the central error handler), with the stack trace and context
- Do not log and rethrow at every layer. One failure becomes five log lines and the real cause hides
- Include the error type and a stable error code for grouping

## Log Injection

User input in logs can forge entries with newlines or break parsers. Structured JSON logging escapes control characters. Never build log lines by string concatenation of user input, and truncate long values.

## Volume and Cost

- Sample successful request logs at very high volume. Keep 100 percent of errors and slow requests
- Never log inside tight loops. Aggregate (count, then log once)
- Health check and metrics scrape requests are excluded from access logs
- Retention by tier: hot searchable storage for days to weeks, cheap archive for compliance

## Audit Logs

Separate from application logs, for accountability:

- **Events:** login, logout, failed login, MFA changes, password changes, role and permission changes, access to sensitive records, data exports, admin actions, impersonation, settings changes, deletions
- **Fields:** actor id, actor type (user, admin, service), action, resource type and id, tenant, timestamp, source IP and user agent, outcome (success or denied), and before and after values for changes where appropriate
- **Storage:** append-only, tamper-evident (write-once storage or hash chaining), access-controlled, retained per compliance needs
- Security events follow a consistent vocabulary (the OWASP Logging Vocabulary Cheat Sheet: `authn_login_fail`, `authz_fail`, `input_validation_fail` and so on) so detection rules can match them

## Checklist

- [ ] One structured JSON logger, configured centrally
- [ ] Standard fields and request ids on every line
- [ ] Trace context propagated to downstream calls and jobs
- [ ] Redaction configured in the logger and tested
- [ ] Errors logged once with stack traces
- [ ] Audit log for security relevant actions
- [ ] Log levels configurable at runtime
