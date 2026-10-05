# Client Trust: Expose Nothing Secret, Trust Nothing From the Client

Two rules, one idea. Whatever reaches the browser is public, and whatever the browser sends can be changed. The client is hostile territory in both directions. B16 covers what leaves the server. B17 covers what comes back.

## What the Browser Can See

Anyone can open DevTools. Treat every row as readable and editable by the user and by any script that runs on the page.

| Where | What is visible | Must never be there | Fix |
|-------|-----------------|---------------------|-----|
| Bundled JavaScript (Sources tab) | Every string in the bundle, including inlined env vars, keys, internal URLs, admin routes, feature flags | API secrets, private keys, service-role keys, database URLs, signing keys | Keep the call on the server. Ship only public values |
| Source maps (`.js.map`) | The original source with comments and file layout | Any source map served to the public in production | Disable, or generate hidden maps and upload them privately to the error tracker |
| Network tab | Full request and response bodies and headers | Extra fields on a response: `passwordHash`, tokens, internal ids, other users' data, config | A response DTO per endpoint (B3). Field level authorization in GraphQL |
| Application tab | `localStorage`, `sessionStorage`, IndexedDB, cookies | Access tokens, refresh tokens, API keys, role or plan flags | One opaque session id in an `HttpOnly`, `Secure`, `SameSite` cookie |
| Page HTML and SSR state | `__NEXT_DATA__`, `__NUXT__`, `window.__INITIAL_STATE__`, inline config scripts, `data-` attributes | A whole database row or settings object passed from server code to a client component | Pass a minimal object with only the fields the component renders |
| URLs, history and referrer | Query strings are logged, bookmarked and sent in `Referer` | Tokens, reset codes, session ids | Put them in a header, a cookie or a POST body |
| Mobile and desktop binaries | The APK, IPA or Electron app can be unpacked and read | Any embedded secret | The same rule. Call your server, which holds the secret |

An environment variable is private only while it stays on the server. It becomes public the moment a bundler inlines it into client code. A user cannot read `process.env` on your server, but they can read it in the bundle if you put it there.

### Public Prefixes That Inline Values Into the Bundle

| Framework | Public (inlined into client code) | Server only |
|-----------|-----------------------------------|-------------|
| Next.js | `NEXT_PUBLIC_*` | Plain `process.env.X` in route handlers, server components and server actions |
| Vite | `VITE_*` through `import.meta.env` | Anything without the prefix, read in server code |
| Create React App | `REACT_APP_*` | Not applicable. CRA has no server |
| Nuxt | `runtimeConfig.public` and `NUXT_PUBLIC_*` | Top level `runtimeConfig` keys |
| SvelteKit | `$env/static/public` and `PUBLIC_*` | `$env/static/private`, `$env/dynamic/private` |
| Astro | `PUBLIC_*` | Other variables, in server code only |
| Expo and React Native | `EXPO_PUBLIC_*` | Not applicable. The app is the client |
| Vue CLI | `VUE_APP_*` | Not applicable |
| Gatsby | `GATSBY_*` | `process.env.X` in `gatsby-node` |
| Angular | Everything in `environment.ts` | Not applicable. Use a backend |

Rules for the public column:

- Never put a secret, private key, service-role key, signing key, database URL or third party secret behind a public prefix. The prefix is a promise that the value is safe to publish
- Values that must be public (publishable payment keys, search-only keys, maps keys, a Sentry DSN) are restricted at the provider by origin, quota and permission, so that a copied key is useless elsewhere
- Calls that need a secret (payments, email, LLM APIs, storage signing, admin APIs) run on the server. The browser calls your endpoint and your server calls the provider. A backend for frontend or a presigned URL replaces shipping a key
- Check the built output, not only the source. Search the production bundle (`.next/static`, `dist`, `build`) for your own secret values. Make that a CI step so a leak fails the build
- A secret exposed even once is compromised. Rotate it. Removing it from the file is not enough

## Sessions and Tokens

- The user can always see their own cookie in DevTools. The goal is that seeing it gives nothing: the value is an opaque random id with no data inside, it cannot be guessed or forged, and it expires and is revoked on the server
- `HttpOnly` keeps scripts, and therefore any XSS, from reading it. `Secure` keeps it off plain HTTP. `SameSite` limits cross-site sends
- Do not keep access tokens, refresh tokens, API keys or role flags in `localStorage`, `sessionStorage`, a script-set cookie (`document.cookie = ...`), a URL or a global variable. One XSS reads all of them
- If a single page app needs tokens, a backend for frontend keeps them on the server and gives the browser a session cookie (see [authentication.md](authentication.md))
- Do not put sensitive claims in a JWT payload. It is base64, not encryption. Anyone can read it
- Do not log a session id, token or cookie, and do not echo them back in a response or an error

## Responses and Over-Exposure

- Return an explicit DTO per endpoint. Never return an ORM entity, a raw row or a settings object
- Never serialize `process.env`, `os.environ`, the framework config or a request object into a response, a template, an error page or a log line
- Debug and ops surfaces are off or authenticated in production: `/env`, `/debug`, `/actuator/env`, `phpinfo()`, profilers, Swagger or GraphQL playgrounds, verbose error pages
- GraphQL: authorize per field, limit depth and cost, and disable introspection or put it behind auth in production
- Do not expose guessable internals that help an attacker: sequential ids where enumeration matters, internal hostnames, stack traces, library versions

## Never Trust What the Client Sends

Everything a client sends can be changed. That includes bodies, query strings, path ids, headers, cookies, hidden form fields, token claims and `localStorage` flags, edited in DevTools (Edit and Resend), a proxy or `curl`. The UI only suggests. The server decides.

| Value | Wrong: taken from the client | Right: decided by the server |
|-------|------------------------------|------------------------------|
| Role, permissions, plan | `req.body.role`, a `role` cookie, a `localStorage` flag, an unverified JWT claim | Looked up from the authenticated principal on the server |
| User, tenant, owner id | `userId` in the body, `X-User-Id` or `X-Tenant` header | Taken from the session. Referenced ids checked for ownership in the query |
| Price, total, discount, fee | `req.body.price`, `req.body.total`, `req.body.discount` | The client sends product ids and quantities. The server looks up prices and computes the total |
| Status, paid, verified, approved | `req.body.status = "paid"` | The server moves state through allowed transitions only |
| Workflow step | A `step` field, or reaching a later endpoint directly | A state machine checks the current state and the actor on every call |
| Quantity and limits | Any number | Integer, minimum, maximum and a stock or quota check |
| Coupon or credit | An amount or percent from the client | A code the server validates, uses once and prices itself |
| Timestamps | `createdAt` from the client | The server clock |
| File name, type and size | Client file name and `Content-Type` | Server-generated name, type read from the content, size limit |
| Redirect target | A `next` or `returnUrl` parameter | An allowlist or a relative path only |
| Client network info | `X-Forwarded-For`, `Host`, `Origin`, `Referer` used for decisions | Only trusted after your own proxy overwrites them, and never for authorization |
| Webhook or queue payloads | The payload as sent | Verified signature, then re-fetch the object from the provider or database |

```js
router.post('/orders', async (req, res) => {
  const order = await prisma.order.create({ data: { ...req.body, userId: req.body.userId } })
  res.json(order)
})
```

```js
const OrderInput = z.object({
  items: z.array(z.object({ productId: z.string().uuid(), qty: z.number().int().min(1).max(50) })).min(1).max(50),
})

router.post('/orders', async (req, res) => {
  const { items } = OrderInput.parse(req.body)
  const products = await prisma.product.findMany({
    where: { id: { in: items.map((i) => i.productId) }, active: true },
    select: { id: true, priceCents: true },
  })
  const price = new Map(products.map((p) => [p.id, p.priceCents]))
  if (price.size !== new Set(items.map((i) => i.productId)).size) return res.status(422).json(problem('unknown_product'))
  const totalCents = items.reduce((sum, i) => sum + price.get(i.productId) * i.qty, 0)
  const order = await prisma.order.create({
    data: { userId: req.user.id, status: 'pending', totalCents, items: { create: items.map((i) => ({ productId: i.productId, qty: i.qty, unitCents: price.get(i.productId) })) } },
    select: { id: true, status: true, totalCents: true },
  })
  res.status(201).json(order)
})
```

### Rules That Come With It

- **Hidden UI is not security.** A missing button, a disabled input, a frontend route guard or a menu that hides admin links protects nothing. Every endpoint checks the caller on its own (B2)
- **Client side validation is a convenience.** The same checks run on the server (B3), including ownership of every referenced id
- **Decode is not verify.** `jwt.decode`, `jwt_decode` and reading claims without a signature check trust a token anyone can forge. Verify the signature, pin the algorithm, and check `iss`, `aud` and `exp` (B1)
- **Mass assignment.** Accept an allowlist of fields. Never pass `req.body` to `create` or `update` (B2)
- **Parameter pollution.** Repeated or array-typed parameters (`?role=user&role=admin`) are parsed by a schema into one expected type
- **Enforce the state machine on the server.** Each transition checks who may make it and from which state, so skipping a step or replaying one gains nothing
- **Idempotency keys and client-generated ids** are scoped to the caller, so one user cannot collide with or replay another's

## Other Places the Same Rule Applies

- Mobile and desktop apps, Electron and browser extensions. The package can be unpacked, so no secret ships inside it
- Internal service calls. A call from another service is an input too. Authenticate it (mTLS or signed service tokens) and authorize it
- Queue messages and webhooks. Anyone who can reach the endpoint or the broker can forge a message. Verify the signature and validate the schema
- Uploaded files. Name, type, size, content and embedded metadata are all attacker controlled
- Cached and stored client data. A cart or form draft kept in the browser is re-validated and re-priced on checkout
- Analytics and feature flag payloads. Entitlements come from a server lookup, never a client flag

## Test It

- **Exposure check in CI:** grep the production build output for your real secret values and secret names. Fail the build on a hit
- **Public prefix audit:** list every variable behind a public prefix and confirm each is meant to be published
- **DevTools pass:** open Sources, Network and Application on a logged-in page. Look for secrets, extra response fields, tokens in storage and cookies without `HttpOnly`
- **Tamper tests (B15):** for each sensitive endpoint, send the forbidden role, owner id, price, status or step with a normal user's token, then expect the server to ignore the field or reject the request with a 4xx. Assert that nothing changed in the database
- **Authorization matrix:** call each admin or owner-only endpoint as a normal user and as no user. Expect denial every time
- For active attack testing of a running app, hand off to `/security` (see its client exposure and tampering guides)

## Checklist

- [ ] No secret behind a public env prefix, no key in the bundle, no secret value in the build output
- [ ] Production source maps are not public
- [ ] Session is an opaque id in an `HttpOnly`, `Secure`, `SameSite` cookie, and no token sits in web storage
- [ ] Responses use DTOs. No hashes, tokens, config or whole rows. No env dump or debug page in production
- [ ] Role, owner, tenant, plan, price, total, status and step are decided on the server
- [ ] JWTs are verified, not only decoded
- [ ] Every endpoint checks the caller itself. Hidden UI is not relied on
- [ ] Tamper tests exist for the sensitive endpoints
