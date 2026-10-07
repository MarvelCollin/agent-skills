---
type: llm
focus: { source: file, path: src/routes/checkout.js }
---

This is the route file that was written.

PASS if all of these hold:
1. The body is validated with a schema that accepts only product ids and quantities (with sensible limits), and the client-sent `price`, `total`, `role` and `status` are ignored or rejected
2. Prices come from the database (`Product.priceCents`, inactive products rejected) and the order total is computed on the server
3. The order is created with the user id from `req.user.id` and a server-chosen status, never from the body
4. The Stripe secret key is read from a server-side environment variable (for example `process.env.STRIPE_SECRET_KEY`, validated at startup or on use), and the Stripe call happens in this route on the server

FAIL if any of the four is missing, or if the route trusts a client-sent amount, role or status.
