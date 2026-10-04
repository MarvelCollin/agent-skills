---
type: llm
---

PASS if the reply identifies all three of these with a concrete fix for each:
1. The N+1 queries in GET /orders (items and customer loaded per order inside the loop), fixed with eager loading such as Prisma `include` or a batched `in` query
2. The broken object level authorization (IDOR) in GET and PATCH /orders/:id, fixed by scoping the lookup to the signed-in user (for example `where: { id, userId: req.user.id }`)
3. The unbounded list in GET /orders, fixed with server-side pagination with a default and a maximum page size

and also names at least two of: mass assignment from passing `req.body` to update, no timeout on the payment fetch, the authorization header being logged, money parsed as a float, or the payment not being idempotent.
FAIL if it misses the N+1, misses the IDOR, or gives no concrete fixes.
