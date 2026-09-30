# API Testing

REST and GraphQL endpoints. Many of the classes above apply, plus API-specific issues. APIs often carry the real authorization logic, so test it hard here.

## What to Check

- **Object-level authorization (BOLA/IDOR):** every endpoint that takes an object id, checked as in [auth-access.md](auth-access.md). The top API risk.
- **Function-level authorization:** admin or privileged operations reachable by lower roles.
- **Mass assignment:** the API binds request fields straight to a model, letting a user set fields they should not (role, isAdmin, ownerId).
- **Excessive data exposure:** the endpoint returns more than the client needs, and the front end hides it, but the raw response leaks it.
- **Rate limiting:** no limit on expensive or sensitive operations (login, search, export).
- **GraphQL specifics:** introspection left on in production, deeply nested queries that exhaust resources, authorization checked per resolver.

## How to Test Safely

- Hit each endpoint directly with your test accounts. Swap ids across accounts for BOLA. Call privileged operations as a low-privilege user.
- For mass assignment, add an unexpected field (a role or ownership field) to a create or update request and see if it sticks. Use your test account.
- Read raw responses for fields the UI does not show.
- For rate limiting, send a small burst to confirm no limit, not a flood.
- For GraphQL, check whether introspection is enabled and whether each resolver enforces authorization. Keep any nested-query test shallow enough not to strain the server.

## Confirmed Finding Looks Like

An API let a test account reach another's object, set a forbidden field, or returned data it should not, reproduced with the request and response saved.

## Fix

- Check object ownership and role on the server for every endpoint. Deny by default.
- Bind only an allowlist of fields. Never mass-assign from the request body.
- Return only the fields the client needs. Shape responses server-side.
- Rate-limit sensitive and expensive endpoints.
- GraphQL: turn off introspection in production, enforce authorization in every resolver, limit query depth and cost.

References: OWASP API Security Top 10 (API1 BOLA, API3, API5, API6), CWE-285, CWE-915, CWE-213.
