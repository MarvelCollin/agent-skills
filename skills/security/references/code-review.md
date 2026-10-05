# Secure Code Review

Review source for vulnerabilities without running anything against a live target. This needs no authorization gate when the code is the user's own, because it executes nothing against a live system. It is the fallback when a live target cannot be authorized, and a strong first pass before any dynamic testing.

## Approach

Work from input to sink. A vulnerability is almost always untrusted input reaching a dangerous operation without the right check in between.

1. **Find the inputs.** Request params, body, headers, cookies, uploads, websocket and queue messages, and any external data the app trusts.
2. **Find the sinks.** Database queries, shell and process calls, file paths, outbound HTTP, template rendering, HTML output, deserialization, reflection, redirects.
3. **Trace the path.** For each input that reaches a sink, check what happens in between. Missing or wrong handling is the finding.

## What to Look For

- **Injection:** string-built SQL or shell or queries, template rendering of user input, `eval`-family calls. Want parameterized queries, safe APIs, no dynamic code from input. See [testing/injection.md](testing/injection.md).
- **Access control:** endpoints and object lookups that do not check the caller owns or may access the object. Look for missing authorization on every state-changing and data-returning route, not just login. See [testing/auth-access.md](testing/auth-access.md).
- **Authentication and sessions:** password storage, token generation and verification, session lifecycle, cookie flags. See [testing/session.md](testing/session.md).
- **Server-side:** user-controlled URLs fetched by the server (SSRF), user input in file paths (traversal), upload handling, XML parsing, deserialization of untrusted data. See [testing/server-side.md](testing/server-side.md).
- **Client-side:** unescaped output into HTML or the DOM, missing CSRF protection on state changes, unvalidated redirects. See [testing/client-side.md](testing/client-side.md).
- **Secrets:** hardcoded keys, tokens, passwords, connection strings. Check config, source, and history. See [testing/secrets.md](testing/secrets.md).
- **Config and defaults:** debug mode on, verbose errors, permissive CORS, missing security headers, default credentials. See [testing/config.md](testing/config.md).
- **Business logic:** steps that can be skipped or replayed, amounts and quantities trusted from the client, missing server-side checks. See [testing/business-logic.md](testing/business-logic.md).
- **Client exposure:** secrets in public-prefixed env vars (`NEXT_PUBLIC_`, `VITE_`, `REACT_APP_`, `EXPO_PUBLIC_`, `NUXT_PUBLIC_`, `VUE_APP_`, `GATSBY_`, `PUBLIC_`), hardcoded keys in client code, production source maps, whole rows serialized into SSR state or API responses, tokens in `localStorage` or script-set cookies, session cookies without `HttpOnly`, endpoints that print the environment. See [testing/client-exposure.md](testing/client-exposure.md).
- **Client-controlled values:** role, owner, tenant, price, total, status or step taken from the body, query, headers or a decoded but unverified JWT, mass assignment, authorization enforced only in the UI, webhooks and queue messages accepted without verification. See [testing/tampering.md](testing/tampering.md).
- **Dependencies:** known-vulnerable versions in the lockfile. Note them with the advisory id.

## Speed It Up with Grep

Search the changed or whole tree for risky patterns, then read each hit in context. These are leads, not findings. Confirm by reading the surrounding code.

```bash
bash "<skill-dir>/scripts/grep-audit.sh" "<path>"
```

On Windows without bash:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill-dir>/scripts/grep-audit.ps1" -Path "<path>"
```

The script flags likely dangerous sinks and hardcoded secrets by file and line. It also flags client exposure and client trust leads under these categories: `client-env-secret` (secret-named env vars behind public prefixes), `client-token-storage` (tokens in `localStorage`, `sessionStorage` or script-set cookies), `sourcemap-public`, `env-dump` (the whole environment sent or logged), `jwt-unverified` (decode without verify, ignored expiry, `none`), `cookie-flags` (cookie set without `HttpOnly`), `client-authority` (role, owner or tenant read from the request), `client-value` (price, status or step read from the request) and `client-header` (identity from `X-User`, `X-Role` and similar headers). Every hit needs a human read. Many are safe in context.

## Output

Write findings in the format from [reporting.md](reporting.md). For code review, Location is `file:line` and Evidence is the code path from input to sink. Each finding still needs impact, root cause, and a concrete fix. Run findings through [validation.md](validation.md): a pattern match with no reachable path and no impact is a note, not a finding.
