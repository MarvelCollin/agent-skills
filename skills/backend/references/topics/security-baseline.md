# Security Baseline for Builders

What every backend should have by construction. This is the builder's side. For testing a running app for vulnerabilities, use `/security`.

## OWASP API Security Top 10 (2023) Mapped to Rules

| Risk | What to build | Rule |
|------|---------------|------|
| API1 Broken Object Level Authorization | Owner or tenant scope in every id lookup | B2, [authorization.md](authorization.md) |
| API2 Broken Authentication | Proven auth, strong hashing, short tokens, rate-limited login | B1, [authentication.md](authentication.md) |
| API3 Broken Object Property Level Authorization | Write allowlists and read DTOs | B2, B3, [validation.md](validation.md) |
| API4 Unrestricted Resource Consumption | Rate limits, pagination caps, body and upload limits, timeouts, spend caps on paid APIs (SMS, email, AI) | B5, B8, [resilience.md](resilience.md) |
| API5 Broken Function Level Authorization | Server-side permission checks on every privileged action | B2 |
| API6 Unrestricted Access to Sensitive Business Flows | Per-account limits and bot protection on purchase, signup, referral, coupon and booking flows | [authorization.md](authorization.md) |
| API7 Server Side Request Forgery | Allowlist outbound hosts for user-supplied URLs, block private and metadata IP ranges after DNS resolution, no automatic redirects, separate egress | below |
| API8 Security Misconfiguration | Debug off, strict CORS, security headers, TLS, no default credentials, verbose errors off | B11, B13 |
| API9 Improper Inventory Management | Complete OpenAPI inventory, retire old versions, no forgotten debug or staging hosts | [api-design.md](api-design.md) |
| API10 Unsafe Consumption of APIs | Validate third-party responses, timeouts, TLS verification on, treat upstream data as untrusted | B3, B8 |

## Injection

- Parameterized queries everywhere. ORMs are safe until someone uses a raw query with string formatting
- Never pass user input to a shell. Use argument arrays (`execFile`, `subprocess.run([...])`) and avoid the shell entirely
- No `eval`, dynamic `require` or `import`, or template rendering of user-controlled templates
- Identifiers (column and table names for sorting) come from an allowlist, never from input

## Outbound Requests (SSRF)

When the server fetches a URL a user supplied (webhooks, image import, link previews):

- Allow only `https` (and `http` if needed), only expected ports
- Resolve DNS and reject private, loopback, link-local and cloud metadata addresses (`169.254.169.254`), then connect to the resolved IP so DNS rebinding cannot swap it
- Do not follow redirects automatically, or recheck each hop
- Set timeouts and response size limits
- Run fetchers in an isolated egress path when possible

## Transport and Headers

- TLS 1.2 or later everywhere, including internal traffic where the network is shared. HSTS on public hosts
- CORS: an explicit allowlist of origins. Never reflect any origin while allowing credentials
- Security headers for anything that returns HTML: `Content-Security-Policy`, `X-Content-Type-Options: nosniff`, `Referrer-Policy`, `frame-ancestors` in CSP. APIs return `Content-Type: application/json` and `nosniff`
- Cookies: `Secure`, `HttpOnly`, `SameSite`

## Cryptography

- Use high-level libraries (libsodium, Tink, the platform's KMS). Never invent schemes
- Symmetric encryption with AES-256-GCM or ChaCha20-Poly1305, unique nonces, keys from a KMS
- Random values for tokens and ids from a CSPRNG (`crypto.randomBytes`, `secrets`, `crypto/rand`), never `Math.random`
- Passwords hashed as in [authentication.md](authentication.md)

## Dependencies

- Lockfiles committed, installs reproducible
- Automated vulnerability scanning in CI and automated update PRs
- Review new dependencies: maintenance, popularity, install scripts, permissions
- Watch for typosquatting and dependency confusion (scope private packages, pin registries)

## Data Protection and Privacy

- **Minimize:** collect only what the product needs, and keep it only as long as needed. Define retention per data type and delete on schedule
- **Classify:** know which tables and fields hold personal or sensitive data
- **Encrypt:** at rest (managed disk and database encryption) and in transit. Field-level encryption for the most sensitive values (government ids, health data, tokens for third parties)
- **Access:** production data access is limited, logged and reviewed. Staging uses synthetic or masked data, never raw production copies
- **Rights:** support export and deletion requests (GDPR, CCPA and similar). Deletion reaches backups on their rotation, caches, search indexes, logs and third-party processors
- **Residency:** know where data is stored when regulations require a region

## Abuse Prevention

- Signup and messaging features attract spam. Verify emails, rate limit, and add bot detection where needed
- Cost-bearing features (SMS, email, AI calls, file processing) have per-account quotas and global spend alerts

## Checklist

- [ ] Every OWASP API Top 10 row has a concrete control
- [ ] No string-built queries or shell commands
- [ ] SSRF protections on user-supplied URLs
- [ ] Strict CORS, TLS, security headers
- [ ] Dependency and secret scanning in CI
- [ ] Personal data classified, minimized, encrypted and deletable
