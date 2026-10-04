---
type: llm
focus: { source: file, path: src/routes/orders.js }
---

This is the route file that was written.

PASS if all of these hold:
1. Orders, items and product names load with a constant number of queries, using Prisma `include` or `select` with nested relations (or an equivalent batched query), not a query per order or per item inside a loop or `map`
2. The orders query filters by the signed-in user (`req.user.id`), never by an id from the query string or body
3. The route paginates on the server with a default page size and a maximum (a cap such as 100), preferably cursor or keyset based given thousands of orders, with a stable order such as `createdAt` plus `id`
4. Query parameters like `limit` and `cursor` are validated (for example with zod) before use

FAIL if any of the four is missing.
