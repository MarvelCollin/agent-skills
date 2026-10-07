# Client Exposure

Whatever the browser receives, the user can read. So can anyone who gets script running in the user's page. Minifying code, hiding a field in the UI or burying a value in a bundle protects nothing. This file covers what the client is handed: bundled values, stored tokens, rendered state and response fields. What the client sends back is in [tampering.md](tampering.md).

A user can always see their own cookie in DevTools. That alone is not a finding. The real tests are in the Session and Tokens bullet below.

## What to Check

- **Env values in the bundle:** a framework inlines a variable into the JavaScript when its name has a public prefix. Look for `NEXT_PUBLIC_`, `VITE_`, `REACT_APP_`, `EXPO_PUBLIC_`, `NUXT_PUBLIC_` (and `runtimeConfig.public`), `VUE_APP_`, `GATSBY_`, SvelteKit and Astro `PUBLIC_`, the `env` block in `next.config.js`, Vite `define`, webpack `DefinePlugin`, and Angular `environment.ts` where everything in the file ships. A secret key, private key, service role key, database URL, webhook secret or paid API key behind any of these is public. Server-side env vars are never visible unless something bundles them or prints them.
- **Hardcoded keys in JS:** literals in client code, config objects, analytics snippets and test leftovers. Key-shaped strings such as `sk_live_`, `AKIA`, `ghp_` and private key blocks.
- **Source maps:** a production `.js.map` that is reachable gives original source, comments, internal routes and anything the code mentions. Check `productionBrowserSourceMaps`, `devtool`, `build.sourcemap` and `GENERATE_SOURCEMAP`.
- **SSR state:** `__NEXT_DATA__`, `__NUXT__`, `window.__INITIAL_STATE__`, inline `<script>` config and `data-` attributes. A whole user row, a token or an internal flag serialized for hydration is readable in view-source. Props passed from server code into a client component are serialized the same way.
- **Over-fetched responses:** password hashes, reset tokens, internal ids, other users' fields, feature and config objects, fields the UI never renders. Hiding a field in the UI does not remove it from the response.
- **Session and tokens:** these must hold up when the user can read everything. The session value is an opaque random id that carries no data and cannot be forged. It is `HttpOnly`, `Secure` and `SameSite` so a script (XSS) cannot read it. No access token, refresh token, API key or role flag sits in script-readable storage (`localStorage`, `sessionStorage`, a cookie set from JavaScript, IndexedDB). No token or session id appears in a URL, where it leaks through history, logs and `Referer`.
- **Debug and env surfaces:** an endpoint that returns `process.env` or `os.environ`, `/env`, `/actuator/env`, `/debug`, `/.env`, `phpinfo()`, a framework debug page or console, a heap dump.
- **GraphQL:** introspection left on in production, field suggestions in errors, verbose resolver errors with stack traces or SQL.
- **Mobile and desktop builds:** keys and endpoints packed into an APK, IPA or Electron `app.asar` are recoverable by unpacking the file. A key in the app is a key the user holds.

## How to Test Safely

- Use your own test accounts and your own build. Never read another person's session or data.
- Never use a secret you find. Confirming that it exists and is reachable is the finding. Save the location and redact the value.
- Prefer commands that print file names and status codes over commands that print the secret itself.

DevTools procedure, with the app running and signed in as your test user:

1. **Sources tab.** Press `Ctrl+Shift+F` to search every loaded file. Search for the names and values of your own server-only secrets (the database password, the third-party secret key from your `.env`), for the public prefixes above, and for `sk_live`, `apiKey`, `Bearer` and `secret`. Any server-only value that turns up is the finding. Check the file tree for `webpack://` or original source folders, which means a source map is loaded.
2. **Network tab.** Reload with Preserve log on and filter to Fetch/XHR. Open each response and read the full body for fields the UI never shows (hashes, tokens, other users, config). In the Headers tab, read response `Set-Cookie` flags and any token in a request URL or `Referer`.
3. **Application tab.** Open Local Storage, Session Storage, IndexedDB and Cookies. Note anything token-shaped. In Cookies, read the HttpOnly, Secure and SameSite columns for the session cookie.
4. **Console quick checks.** Run `Object.keys(localStorage)`, `Object.keys(sessionStorage)` and `document.cookie`. The session cookie should be missing from `document.cookie`. If it shows, scripts can read it.
5. **View source.** Open `view-source:` on the page and search for `__NEXT_DATA__`, `__NUXT__`, `__INITIAL_STATE__`, `<script>` blocks and `data-` attributes. From the shell, with your own test cookie:

```bash
curl -s -b "$TEST_COOKIE" http://localhost:3000/dashboard | grep -oE "__NEXT_DATA__|__NUXT__|__INITIAL_STATE__"
```

6. **Source maps.** Copy a bundle URL from the Network tab (JS filter). Check the last line of the bundle for `sourceMappingURL`, then request the map. A 200 with JSON is the finding:

```bash
curl -s "<bundle-url>" | tail -c 200
curl -sI "<bundle-url>.map"
curl -s "<bundle-url>.map" | head -c 300
```

7. **Built output.** On your own checkout, search the build folders (`.next/static`, `dist`, `build`, `out`, `public`) for the value of each server-only secret. The loop prints only the variable name, never the value. Values wrapped in quotes need the quotes stripped first:

```bash
while IFS='=' read -r name value
do
  [ "${#value}" -ge 8 ] && grep -rIlqF -- "$value" .next/static dist build out 2>/dev/null && echo "$name is in the built output"
done < .env.local
find .next/static dist build out -name "*.map" 2>/dev/null
```

8. **Session cookie.** Log in and read the value. If it decodes to readable JSON or base64 of user data, it carries data and may be forgeable. Change one character and reload. A sound session is rejected. Then use [session.md](session.md) for fixation, rotation and logout.
9. **Env and debug paths.** Check status codes only. If one returns 200, note it and stop. Do not read or save the contents beyond confirming what kind of file or page it is:

```bash
for path in /env /debug /actuator/env /.env /phpinfo.php /console
do
  curl -s -o /dev/null -w "$path %{http_code}\n" "http://localhost:3000$path"
done
```

10. **GraphQL.** Ask the schema for its root type name, then send a malformed query and read how much the error says:

```bash
curl -s -X POST http://localhost:4000/graphql -H "Content-Type: application/json" -d '{"query":"{__schema{queryType{name}}}"}'
```

11. **Mobile and desktop.** On your own build, unpack the package (`unzip app.apk`, `unzip app.ipa`, `npx asar extract app.asar out`) and search the contents for key prefixes and your own secret values.

## Confirmed Finding Looks Like

A value that should be server-only (secret key, private key, token, hash, internal config) readable from a bundle, source map, page source, response body or storage, reached by an ordinary or unauthenticated user. The location is saved (bundle URL, response field, storage key) with the value redacted, and the impact states what the value grants. For tokens, a credential sits in script-readable storage or a URL, or a session cookie lacks HttpOnly, with the XSS or leak path stated.

Not findings: a publishable or public key built to ship (Stripe `pk_`, a Supabase anon key behind row-level security, a Maps key restricted by referrer), and a user reading their own `HttpOnly` cookie in DevTools. For a public key, check that it is scoped and restricted instead.

## Fix

- Keep secrets on the server. Move the call that needs the secret into a route handler, server action or backend proxy. The client gets the result, never the key.
- Put only values that are safe for strangers to read behind public prefixes. Rename or remove any that are not. Rotate every secret that was ever bundled.
- Disable production source maps, or upload them privately to the error tracker (`hidden-source-map`) and keep `.map` files out of the deployed folder.
- Shape every response and every SSR prop on the server with an explicit allowlist (serializer, DTO, `select`). Never serialize a whole row.
- Use an opaque random session id in a cookie with `HttpOnly`, `Secure` and `SameSite`. Keep access and refresh tokens out of `localStorage`, `sessionStorage` and URLs. Keep expiry short.
- Remove env, debug and heap dump endpoints from production, or put them behind authentication on an internal port. Turn off GraphQL introspection and verbose errors.
- Scan the build output for secret values in CI, and fail the build on a hit.

References: OWASP WSTG (INFO-05 information leakage in page content, CLNT-12 browser storage), OWASP API Security Top 10 API3 (excessive data exposure and property level authorization), CWE-200, CWE-312, CWE-540.
