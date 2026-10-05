---
type: llm
---

PASS if the final reply tells the user to stop exposing secrets and sessions in the browser, naming at least these two problems with a fix for each:
1. `VITE_STRIPE_SECRET_KEY` is inlined into the client bundle and visible to anyone in DevTools, so the key must move to a server-only variable and be rotated, with the Stripe call made by the server (the browser may only hold a publishable key)
2. Keeping the login JWT in localStorage lets any XSS read it, so the browser should hold an opaque session in an `HttpOnly`, `Secure`, `SameSite` cookie (or use a backend for frontend)

and it also explains that the client-sent `price`, `total`, `role` and `status` can be edited by any user and are now computed or taken from the server, ideally with a rules check or self-review.
FAIL if it does not mention the exposed Stripe key, or ignores the client-controlled values.
