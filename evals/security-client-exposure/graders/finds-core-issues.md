---
type: llm
---

The fixture is a small Next.js shop with six planted client-side trust problems:

1. A server secret (the Stripe secret key) sits behind a public env prefix (`NEXT_PUBLIC_STRIPE_SECRET_KEY`), so it is inlined into the browser bundle and used from client code.
2. `productionBrowserSourceMaps: true` in next.config.js publishes the original source of the production bundle.
3. The login component stores the JWT in `localStorage`, where any script (XSS) can read it.
4. The orders API trusts `role` and `price` (and `status`) from `req.body`, so a user can edit the request to act as admin or pay any amount.
5. The users route returns the whole database row including `passwordHash` and has no ownership check.
6. `getUser` uses `jwt.decode` without verifying the signature, so a forged token is accepted.

PASS if the reply identifies at least four of these six issues and gives a concrete fix for each issue it names (for example: move the Stripe call server-side and rotate the key, disable production source maps, use an HttpOnly Secure SameSite session cookie, derive role from the verified session and price from the catalog, return only allowlisted user fields with an authorization check, use `jwt.verify` with a pinned algorithm).
FAIL if it names fewer than four, or names issues without concrete fixes, or treats the `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` value as a leaked secret.
