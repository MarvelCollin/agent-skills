# Authentication

Establish who the caller is, reliably, and keep that proof safe for its lifetime. Prefer a proven library or identity provider (Auth0, Cognito, Keycloak, Entra ID, Clerk, Supabase Auth, or the framework's built-in auth) over custom code. Your job is mostly to configure it correctly.

## Passwords

- **Hashing (OWASP Password Storage Cheat Sheet):**
  - argon2id first choice, minimum m=19456 KiB (19 MiB), t=2, p=1
  - scrypt when argon2id is not available, N=2^17, r=8, p=1
  - bcrypt for legacy systems, cost 10 or more. bcrypt ignores input past 72 bytes, so reject longer passwords or pre-hash with HMAC-SHA-256 and a pepper (base64 encode the result before bcrypt)
  - PBKDF2-HMAC-SHA256 with 600,000 iterations when FIPS 140 is required
  - Never MD5, SHA-1, or a single SHA-2 pass, salted or not
- **Rehash on login** when the stored hash uses old parameters. The library's `needsRehash` check makes upgrades free
- **Pepper** (optional): a secret from the secrets manager mixed in with HMAC, so a database leak alone is not enough to crack hashes
- **Policy (NIST SP 800-63B):** length over complexity. At least 8 characters with MFA and 15 without, allow at least 64, allow all characters including spaces, no forced periodic rotation, no composition rules. Check new passwords against breached lists (Have I Been Pwned range API with k-anonymity)
- **Hashing is slow on purpose.** Run it off the event loop (the async API of the library) and rate limit login so hashing cannot be used to exhaust CPU

## Login Endpoint

- Generic failure message ("Email or password is incorrect"), the same status code and similar timing for unknown users and wrong passwords. Hash against a dummy hash when the user does not exist
- Rate limit per account and per IP, with backoff. Prefer progressive delays and CAPTCHA over hard lockouts, which let attackers lock out real users
- Compare secrets with a constant-time function (`crypto.timingSafeEqual`, `hmac.compare_digest`, `subtle.ConstantTimeCompare`, `MessageDigest.isEqual`)
- Log failures as security events with an opaque user id and IP, never the password attempted
- Signup and password reset must not reveal whether an email is registered. Send "If an account exists, we sent a link"

## Sessions (browser apps)

- Server-side sessions with an opaque random id of at least 128 bits, stored in Redis or the database
- Cookie: `HttpOnly`, `Secure`, `SameSite=Lax` (or `Strict`), `Path=/`, and the `__Host-` prefix when possible
- Rotate the session id on login and on privilege change to prevent fixation
- Idle timeout (15 to 60 minutes for sensitive apps) and an absolute timeout (hours to days)
- Logout and password change revoke the session server-side, and "log out everywhere" revokes all of them
- CSRF protection for cookie-authenticated state changes: `SameSite` plus a CSRF token or a custom header check

## Tokens and JWT

- Use JWTs where stateless verification earns its keep: between services, or short-lived API access. For a browser app talking to its own backend, a session cookie is simpler and revocable. If a SPA needs tokens, a backend-for-frontend that holds them server-side and gives the browser a cookie is the safest pattern. Do not keep tokens in `localStorage`
- Access tokens live 5 to 15 minutes. Refresh tokens are opaque, stored hashed, rotated on every use, and reuse of an old one revokes the whole family (reuse detection)
- Verify every token fully: signature with an allowlist of algorithms (never `none`, never accept HS256 when you expect RS256), `exp`, `nbf`, `iss`, `aud`, with a small clock skew allowance (about 60 seconds)
- Rotate signing keys with a `kid` header and a JWKS endpoint. Keep the private key in a KMS or secrets manager
- Payloads are readable by anyone. No personal data or secrets in claims. Keep them small
- Revocation needs either short lifetimes or a denylist of `jti` values checked on use

## OAuth 2 and OpenID Connect

- Authorization Code flow with PKCE for every client type. No implicit flow and no password grant (both removed in OAuth 2.1)
- Validate `state` (CSRF) and `nonce` (replay), exact-match redirect URIs, verify the ID token like any JWT
- Request the smallest scopes needed. Store provider tokens encrypted if you must keep them
- Link accounts by the provider's stable subject id (`sub`), not by email, unless the provider guarantees email verification

## MFA and Passkeys

- Offer passkeys (WebAuthn). They are phishing resistant and remove the password from the attack surface
- TOTP as a second factor. SMS only as a fallback because of SIM swapping
- Recovery codes are random, single use, and stored hashed
- Step-up authentication (re-enter password or MFA) before sensitive actions: changing email or password, adding payout details, deleting the account, exporting data

## API Keys and Machine Clients

- Generate with a CSPRNG, at least 128 bits, with a readable prefix for identification and secret scanning (`sk_live_...`)
- Show the key once, store only a hash (SHA-256 is fine because the key has high entropy), and look it up by a non-secret key id
- Keys have scopes, an owner, an expiry, last-used tracking, and can be rotated without downtime (two active keys during rotation)
- Service-to-service calls use mTLS or workload identity (cloud IAM roles, SPIFFE) with short-lived credentials instead of shared static secrets

## Password Reset and Email Verification

- Random single-use token, stored hashed, expiring in 15 to 60 minutes
- Using the token invalidates it and all other outstanding reset tokens, and revokes existing sessions
- The link goes to a page that submits the token with a POST. Do not log full reset URLs

## Checklist

- [ ] Auth middleware is global, with an explicit public allowlist
- [ ] Password hash is argon2id, scrypt or bcrypt with the parameters above
- [ ] Login, signup and reset are rate limited and do not enumerate accounts
- [ ] Session cookies have the right flags and rotate on login
- [ ] Tokens are short-lived and fully verified, refresh tokens rotate with reuse detection
- [ ] Secrets are compared in constant time
- [ ] Authentication events are logged without secrets
