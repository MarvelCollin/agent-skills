# Client Tampering

Everything a client sends is attacker-controlled. A user can edit a request in DevTools (Network tab, Edit and Resend or Copy as cURL), in a proxy, with curl or from a script. Hidden fields, disabled buttons, route guards and client-side validation only guide honest users. The server has to decide identity, role, price and state for itself. What the client is handed is covered in [client-exposure.md](client-exposure.md).

The classic case is a user editing one request so the endpoint accepts `role: admin`. The same thinking applies to every client you ship and every caller you trust.

## What to Check

- **Identity and authority fields:** role, isAdmin, tenant, owner, userId, accountId, plan or permissions taken from the body, query, path, a hidden form field, a header (`X-User-Id`, `X-Role`, `X-Tenant`), a plain-text cookie or a `localStorage` flag the server reads back.
- **Unverified tokens:** JWT claims used after a decode with no signature check, `alg: none` accepted, `ignoreExpiration` set, a role claim in a token the user can mint, a cookie holding a role with no signature.
- **Values the server should own:** price, total, discount, fee, balance, points, status, paid, verified or step accepted from the client.
- **Mass assignment:** the request body spread straight into a model or update, so any column can be set.
- **Parameter pollution:** the same parameter twice (`role=user&role=admin`), array or object values where a string is expected, duplicate JSON keys, and parsers that disagree about which one wins.
- **UI-only protection:** a hidden or disabled button, a frontend route guard or a feature flag with the endpoint behind it unprotected.
- **Client-side-only validation:** length, range, format, required fields or file type enforced only in JavaScript.
- **Trusted request metadata:** `X-Forwarded-For`, `Origin`, `Referer` or `Host` used for access control, IP allowlists or rate limits.
- **Forged events:** a webhook or queue message accepted without a verified signature or authenticated producer, so anyone who can reach it can post "payment succeeded". Also replay of a real one.
- **Client-sent time and ids:** timestamps, expiry, client-generated ids, version numbers and idempotency keys the server believes.
- **Files:** the file name (traversal), `Content-Type`, extension and declared size taken from the client instead of checked against the content.
- **Skipped state:** a multi-step flow where calling a later endpoint directly skips the earlier checks.
- **Other callers:** mobile and desktop apps, browser extensions, internal service-to-service calls that trust an identity header, queue and webhook payloads, and the contents of uploaded files. Ask the same two questions of each. Who can send this, and what does the server verify?

## How to Test Safely

- Use your own test accounts only. To prove escalation or cross-account effect, use two accounts you own (a low-privilege one and a second one). Never touch real users or real data.
- Tamper only with your own requests. Do the normal action once with the Network tab open, then right-click the request and use Edit and Resend (Firefox) or Copy as cURL (Chrome and Firefox). Change one value at a time and keep the original and the edited request.
- Prove the change with a second read, not just a 200. Reload the profile or fetch the order and check that the stored state moved. A field the server accepted and ignored is not a finding.
- Typical edits on your own request:

```bash
curl -s -X PATCH http://localhost:3000/api/profile -H "Content-Type: application/json" -b "$TEST_COOKIE" -d '{"name":"Test","role":"admin"}'
curl -s -X POST http://localhost:3000/api/orders -H "Content-Type: application/json" -b "$TEST_COOKIE" -d '{"sku":"A1","qty":1,"price":0.01}'
curl -s http://localhost:3000/api/me -H "X-Role: admin" -H "X-User-Id: <second-test-account-id>" -b "$TEST_COOKIE"
```

- For a UI guard, call the endpoint directly as the low-privilege user and as no user, ignoring the UI.
- For a token, decode your own JWT, change a claim and send it back. Check whether the server rejects a bad signature, `alg: none` and an expired token. Use only tokens you own.
- For a multi-step flow, call the last step first with your test account and see what it checks.
- For webhooks and queues, send an unsigned or wrongly signed request with test data to your local endpoint. Never fire a real payment event.
- Read the handler where you can. What it binds from the body, and where it gets identity, answers most of this quickly.
- Stop and ask before any test that would charge a card, send email or change state you cannot revert. Prove it on seeded data instead.

## Confirmed Finding Looks Like

A request the tester edited changed something the server should own (a role, an owner, a price, a status, a skipped step), and a second read shows the changed state. The original and tampered requests and responses are saved, the missing server-side check is named, and the impact is in business terms (free goods, admin access, another tenant's data).

## Fix

- Derive identity, tenant and role on the server from the verified session or token. Ignore any copy the client sends.
- Bind an allowlist of fields (DTO, schema, `permit`, pick). Never spread the request body into a model or an update.
- Compute price, totals, discounts and fees on the server from the catalog. Take only ids and quantities from the client and validate their range.
- Verify JWT signatures with a pinned algorithm and check expiry and audience. Never read claims from a decode without verify.
- Check authorization on the endpoint for every function. Hiding a control in the UI is cosmetic.
- Repeat every validation on the server. Treat client validation as a convenience.
- Do not use `X-Forwarded-For`, `Origin` or `Referer` for access decisions. Have the proxy set trusted headers and strip client copies. Accept internal identity headers only from the gateway.
- Verify webhook signatures with the provider's secret, check the timestamp against replay and make handlers idempotent. Authenticate queue producers and validate message schemas.
- Set timestamps and ids on the server. Store uploads under a generated name and detect the type from the content.
- Enforce state transitions on the server. Each step checks the recorded result of the previous one.

References: OWASP WSTG (BUSL-01 business logic data validation, ATHZ-02 bypassing the authorization schema, INPVAL-04 HTTP parameter pollution), OWASP API Security Top 10 (API1, API3, API5, API6), CWE-602 (client-side enforcement of server-side security), CWE-639, CWE-915, CWE-345, CWE-565.
