---
type: llm
---

PASS if the reply flags at least five of these with a concrete fix:
1. SQL built by string interpolation in /login and in /products (parameterized queries)
2. Plaintext password comparison (hash with argon2id or bcrypt)
3. JWT secret fallback "dev" and credentials inside the connection string (env vars, validated at startup)
4. CORS reflecting any origin with credentials (explicit whitelist)
5. Cookie set without HttpOnly, Secure and SameSite, and a JWT with no expiry or refresh token
6. Stack trace returned to the client from the error handler
7. N+1 COUNT query per product, and `SELECT *` with no LIMIT on /products
8. No rate limiting on /login
9. No health check, no logging, no query timeout, no compression

FAIL if fewer than five are flagged, or the fixes are vague.
