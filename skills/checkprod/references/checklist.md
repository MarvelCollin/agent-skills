# Launch Checklist

Forty items in two groups. Each item says why it matters, what proof counts as a pass, how it is checked and how to fix it. Statuses are `pass`, `fail`, `warn`, `manual` and `n/a`.

- **pass** needs proof a reviewer can check: a file and line, a header or tag value from prod-url, a command output or a screenshot. No proof means it is not a pass
- **warn** works but falls short of the pass bar
- **manual** can only be confirmed in a browser, by the owner or by an active test. Say exactly what to check
- **n/a** needs a one line reason

`prod-scan` is the static scan, `prod-url` the live check. Both live in `<skill-dir>/scripts/`. Check names in backticks are the names the scripts print. Scan output is a first grade and its leads are places to read, not findings.

## Frontend

### FE1 Custom 404 page
- **Why:** a broken link that lands on a bare server error page looks abandoned, and a 404 that returns 200 gets indexed as a real page
- **Pass when:** a 404 page exists inside the site layout with navigation and links to the main pages, and unknown paths return HTTP 404
- **Checked by:** prod-scan `custom-404` (app/not-found, pages/404, 404.html, +error.svelte, error.vue, catch-all routes), prod-url `NOT_FOUND_STATUS` and `NOT_FOUND_PAGE`. A file that exists while the live site answers 200 is a fail
- **Fix:** add the framework's 404 file (see stacks.md) with the site header, a short plain message and links home and to the main pages. Make sure the host returns status 404 for it
- **Deeper:** `/uiux` R16

### FE2 CTA above the fold
- **Why:** visitors decide in seconds, and a hero with no clear next step loses them
- **Pass when:** at 375x812 and 1440x900 the primary action is visible without scrolling, names the outcome ("Book a demo", not "Learn more") and is the strongest element on screen
- **Checked by:** manual, screenshots at both sizes
- **Fix:** move the main action into the hero, give it an outcome label and the strongest visual weight
- **Deeper:** `/uiux` R16

### FE3 Meta title per page
- **Why:** the title is the search result headline and the browser tab label. One title for the whole site hides every page but the home page
- **Pass when:** every route sets its own title (page name, then brand, under about 60 characters)
- **Checked by:** prod-scan `meta-title` counts page files with their own title (metadata export, `<title>`, Head, useHead, a layout title prop), prod-url `TITLE`
- **Fix:** use the framework's metadata API per page and a title template in the root layout
- **Deeper:** `/uiux` R16

### FE4 Meta description per page
- **Why:** search engines and link previews show it under the title, and a missing one gets replaced by random page text
- **Pass when:** every public page has its own description of about 150 characters written for that page
- **Checked by:** prod-scan `meta-description`, prod-url `META_DESCRIPTION`
- **Fix:** add a description next to each page title through the same metadata API
- **Deeper:** `/uiux` R16

### FE5 Open Graph image and share tags
- **Why:** links shared in chat and social apps show a blank card without them
- **Pass when:** `og:title`, `og:description`, an `og:image` of 1200x630 that loads, and `twitter:card` are set on the home page and every page people share
- **Checked by:** prod-scan `open-graph` (opengraph-image files, openGraph metadata, og tags, twitter card), prod-url `OG_TITLE`, `OG_DESCRIPTION`, `OG_IMAGE` (fetched, status and type shown) and `TWITTER_CARD`
- **Fix:** add the share image file or metadata (see stacks.md) and `twitter: { card: "summary_large_image" }` or the meta tag
- **Deeper:** `/uiux` R16

### FE6 Favicon set
- **Why:** a missing icon shows a blank tab and a gray square on phone home screens
- **Pass when:** `favicon.ico`, an SVG or 32px PNG icon, a 180px Apple touch icon, and a web manifest with 192 and 512 pixel icons
- **Checked by:** prod-scan `favicon-set`, prod-url `FAVICON` and `APPLE_TOUCH_ICON` (fetched, and an HTML answer counts as missing)
- **Fix:** export the icon set from the logo and add the files and links the framework expects
- **Deeper:** `/uiux` R16

### FE7 robots.txt
- **Why:** a staging `Disallow: /` that ships to production removes the whole site from search
- **Pass when:** robots.txt exists, does not disallow everything for `User-agent: *` in production, and has a `Sitemap:` line
- **Checked by:** prod-scan `robots-txt`, prod-url `ROBOTS_TXT`
- **Fix:** allow crawling in production, keep private paths disallowed, add `Sitemap: https://<domain>/sitemap.xml`. Block staging with auth or a noindex header instead of a shared robots file

### FE8 Sitemap
- **Why:** it tells search engines which pages exist and when they changed
- **Pass when:** sitemap.xml exists or is generated, lists the public pages with absolute URLs on the real domain, and robots.txt points to it
- **Checked by:** prod-scan `sitemap` (file, route or package), prod-url `SITEMAP_XML`
- **Fix:** add the framework's sitemap route or plugin (see stacks.md) and list every public page

### FE9 Alt text on every image
- **Why:** screen reader users hear nothing or a file name, and images without alt lose search traffic
- **Pass when:** every image has alt text that says what it shows for this page, and decorative images use `alt=""`. No file names, no "image of"
- **Checked by:** prod-scan `image-alt` with `img-without-alt` and `weak-alt` leads, prod-url `IMAGES` and `IMAGES_WITHOUT_ALT`
- **Fix:** write alt text for content images and set `alt=""` on decorative ones
- **Deeper:** `/uiux` R16

### FE10 Mobile breakpoints
- **Why:** most visitors arrive on a phone, and sideways scroll or tiny targets make the site feel broken
- **Pass when:** a viewport meta tag, mobile first responsive styles, and no sideways scroll at 375, 768 and 1440 with tap targets of 44px or more
- **Checked by:** prod-scan `mobile-breakpoints` (viewport and responsive styles), prod-url `VIEWPORT`, then manual at the three widths
- **Fix:** add the viewport tag, replace fixed widths with max widths and breakpoints, and fix the element that overflows
- **Deeper:** `/uiux` R16

### FE11 Sticky mobile CTA on long landing pages
- **Why:** on a long phone page the main action scrolls away and never comes back
- **Pass when:** on landing pages longer than about three screens at 375px, a bar with the main action appears once the hero button scrolls away, respects the safe area and never covers content or form fields. `n/a` for short pages
- **Checked by:** manual at 375. prod-scan `sticky-mobile-cta` points at any fixed bottom element
- **Fix:** add a bottom action bar that shows after the hero button leaves the viewport
- **Deeper:** `/uiux` R16

### FE12 Loading states
- **Why:** a blank area or a jumping layout while data loads reads as broken
- **Pass when:** every async view shows a skeleton shaped like the content, with no layout shift. A spinner only for small inline actions
- **Checked by:** prod-scan `loading-states` (loading files, Skeleton components, skeleton classes, loading flags without a skeleton)
- **Fix:** add a skeleton per list, card and page that loads data
- **Deeper:** `/uiux` R10 and R16

### FE13 Form error states
- **Why:** a form that fails silently or with a browser bubble loses the lead
- **Pass when:** errors show inline next to the field, are tied to it with `aria-describedby` and `aria-invalid`, and focus moves to the first invalid field
- **Checked by:** prod-scan `form-errors`, then manual. Submit each form empty on a local or staging build
- **Fix:** validate on submit, render the message under the field and wire the aria attributes
- **Deeper:** `/uiux` R16

### FE14 Thank you page or success state
- **Why:** after submitting, people need to know it worked and what happens next
- **Pass when:** every form ends on a success state or thank you page that says what happens next and when
- **Checked by:** prod-scan `form-success`, then manual on a local or staging build
- **Fix:** add a success state or a thank you route for each form
- **Deeper:** `/uiux` R16

### FE15 Privacy policy linked in the footer
- **Why:** required by law in most places once you collect any personal data, analytics included, and its absence makes a site look untrustworthy
- **Pass when:** a privacy policy page exists (or a hosted one) and the footer links to it
- **Checked by:** prod-scan `privacy-page`
- **Fix:** ask the user for the legal entity and what data the site collects. Draft only on request and mark the draft as not reviewed by a lawyer. Link it from the footer

### FE16 Terms page linked in the footer
- **Why:** sets the rules of use, payments and liability, and is expected on anything people sign up for or pay for
- **Pass when:** a terms page exists and the footer links to it. `n/a` for a simple brochure site that takes no sign ups or payments
- **Checked by:** prod-scan `terms-page`
- **Fix:** same as FE15. Never present drafted terms as reviewed

### FE17 Cookie banner when trackers load
- **Why:** in the EU, UK and other places, non-essential cookies and trackers need consent before they load
- **Pass when:** no non-essential cookies or trackers load (`n/a`), or a consent banner blocks them until the visitor accepts, with reject as easy as accept
- **Checked by:** prod-scan `cookie-consent` with `tracker-without-consent` leads, then manual. Load the page fresh and watch the network before clicking anything
- **Fix:** switch to cookieless analytics, or add a consent tool and gate every tracker on it (Google consent mode defaults to denied)

### FE18 Analytics installed
- **Why:** without it you launch blind and cannot tell what works
- **Pass when:** one analytics tool is installed with a real site ID, privacy friendly or gated by consent where required
- **Checked by:** prod-scan `analytics` with `placeholder-id` leads (G-XXXX and similar)
- **Fix:** ask the user which tool and the real site ID. Never invent an ID

### FE19 Real contact details and no placeholder content
- **Why:** lorem ipsum, example.com, 555 numbers, John Doe or Acme instantly mark a site as unfinished or fake
- **Pass when:** a working email or contact page, a postal address or imprint where the law needs one, and no placeholder text on any user facing page
- **Checked by:** prod-scan `real-content` with `placeholder` and `todo-in-page` leads
- **Fix:** replace each placeholder with real content from the user. Remove sections that have no real content yet, such as testimonials
- **Deeper:** `/uiux` R15 and R16

### FE20 Real domain with HTTPS and a fast first load
- **Why:** browsers flag http, and a slow first load loses visitors before they see anything
- **Pass when:** the site runs on its own domain over HTTPS, http redirects to https, and the first response arrives fast (TTFB under about 800 ms)
- **Checked by:** prod-scan `domain-https` (site URL, `insecure-url` leads), prod-url `HTTPS`, `HSTS`, `FINAL_URL` and `TTFB_MS`. `/uiux` measures full page speed
- **Fix:** connect the domain at the host, force HTTPS, and load every asset over https

## Backend

### BE1 Hide API keys
- **Why:** anything in the client bundle or a public repo is public, and leaked keys get abused within hours
- **Pass when:** no secret sits behind a public env prefix (`NEXT_PUBLIC_`, `VITE_`, `REACT_APP_` and similar), no key is in client code or the built bundle, production source maps are not public, and `.env` is not committed and is in `.gitignore`
- **Checked by:** prod-scan `hide-api-keys` with `public-env-secret`, `hardcoded-key`, `sourcemap-public`, `env-tracked` and `env-not-ignored` leads, prod-url `EXPOSED_ENV` and `SOURCE_MAPS` on local or authorized hosts
- **Fix:** move the call that needs the secret to the server, rename the variable without the public prefix, turn off public source maps, ignore `.env*`, and tell the user to rotate every key that was exposed
- **Deeper:** `/backend` B16 and B13, `/security` client exposure and secrets

### BE2 RLS on every table the client can reach
- **Why:** with Supabase or Firebase the anon key ships in the bundle by design, so the database rules are the only lock
- **Pass when:** RLS is enabled on every table in an exposed schema with owner scoped policies, no `using (true)` on insert, update or delete, and Firebase rules never allow open writes or test mode. `n/a` when only the server touches the database
- **Checked by:** prod-scan `rls` with `table-without-rls`, `open-policy` and `open-rules` leads from SQL migrations and rules files. Without migrations in the repo it is `manual` (Supabase security advisor or the Firebase console)
- **Fix:** enable RLS in the migration that creates each table, scope policies with `auth.uid()`, and replace open rules with owner checks
- **Deeper:** `/backend` B18 and `references/topics/client-data-access.md`, `/security` data and storage testing

### BE3 Test IDOR attacks
- **Why:** changing an id in a URL or request is the most common way users read data that is not theirs
- **Pass when:** `/security` proves with two test accounts that swapping ids is refused on every route that takes one
- **Checked by:** manual, active test. prod-scan names routes that take an id
- **Fix:** scope every lookup by the session user or tenant
- **Deeper:** `/backend` B2, `/security`

### BE4 Scan git history for secrets
- **Why:** deleting a file does not remove it from history, and anyone with the repo can read old commits
- **Pass when:** no key pattern or `.env` file appears anywhere in history, or every key found has been rotated. A full scanner (gitleaks or trufflehog) agrees when installed
- **Checked by:** prod-scan `git-history-secrets` with `secret-in-history` and `env-in-history` leads (commit hash and file only, values never shown), plus gitleaks or trufflehog when installed
- **Fix:** rotate every key found first, then purge history only if the user wants to. Add secret scanning to CI
- **Deeper:** `/backend` B13

### BE5 Lock admin routes
- **Why:** hiding the admin link in the UI does not stop anyone from calling the admin API
- **Pass when:** every admin page and API checks the role on the server, in the route, its layout or middleware
- **Checked by:** prod-scan `admin-routes` with `admin-without-role-check` and `client-only-role-check` leads
- **Fix:** add a server side role check that reads the role from the session or the database, never from the client
- **Deeper:** `/backend` B1 and B2

### BE6 Test user isolation
- **Why:** one tenant seeing another tenant's data ends trust in the product
- **Pass when:** `/security` proves that two users cannot see or change each other's data
- **Checked by:** manual, active test
- **Fix:** scope every query and policy by owner or tenant
- **Deeper:** `/backend` B2 and B18, `/security`

### BE7 Rate limit APIs
- **Why:** without limits, login gets brute forced and one script can run up the bill
- **Pass when:** a shared limit per user, key or IP returns 429, with tighter limits on login, sign up, password reset and expensive routes
- **Checked by:** prod-scan `rate-limit`
- **Fix:** add a rate limiter backed by a shared store (for example Upstash or Redis) in front of the API
- **Deeper:** `/backend` B8

### BE8 Lock storage buckets
- **Why:** a public bucket lists or serves every uploaded file to anyone
- **Pass when:** buckets are private, files go out through short lived signed URLs, uploads land in per user folders, and Firebase storage rules are not open
- **Checked by:** prod-scan `storage-buckets` with `public-bucket`, `open-rules` and `public-url` leads
- **Fix:** make the bucket private, serve files with signed URLs, and add storage policies scoped to the owner
- **Deeper:** `/backend` B18, `/security` data and storage testing

### BE9 Validate all inputs
- **Why:** unvalidated input causes crashes, bad data and injection
- **Pass when:** every route that reads a body, query or param checks it with a schema before any logic runs, and unknown fields are rejected
- **Checked by:** prod-scan `input-validation` with `unvalidated-input` leads
- **Fix:** add a schema (zod, valibot, pydantic or similar) at the top of each handler
- **Deeper:** `/backend` B3

### BE10 Block unauthenticated routes
- **Why:** a route that forgets its auth check is open to the internet
- **Pass when:** auth is deny by default (middleware in front of every private route) or every private route checks the session itself
- **Checked by:** prod-scan `auth-by-default` with `route-without-auth` leads
- **Fix:** add auth middleware with an allowlist of public paths
- **Deeper:** `/backend` B1

### BE11 Test SQL injection
- **Why:** one string built query can dump or delete the database
- **Pass when:** no SQL is built from strings, and `/security` confirms injection fails on the running app
- **Checked by:** prod-scan `sql-injection` with `sql-string-building` leads, then manual active test
- **Fix:** use parameterized queries or the ORM's query builder
- **Deeper:** `/backend` B3, `/security`

### BE12 Remove sensitive logs
- **Why:** passwords and tokens in logs leak to every tool and person that can read them
- **Pass when:** no log line prints a password, token, key, card number or a whole request body or headers
- **Checked by:** prod-scan `sensitive-logs` with `sensitive-log` leads
- **Fix:** remove the value from the log or use a logger with redaction
- **Deeper:** `/backend` B9

### BE13 Block field tampering
- **Why:** if the server trusts role, price, owner or status from the request, anyone can edit the request
- **Pass when:** role, owner and plan come from the session, prices from the server catalog, and status changes only through server transitions
- **Checked by:** prod-scan `field-tampering` with `client-value`, `mass-assignment` and `client-write` leads
- **Fix:** ignore those fields from the client, compute them on the server, and protect the columns with policies or column privileges
- **Deeper:** `/backend` B17, `/security`

### BE14 Restrict file uploads
- **Why:** unchecked uploads fill storage, host malware or run as code
- **Pass when:** uploads have a size limit, the type is checked from the file bytes, files get generated names, and they land in private storage
- **Checked by:** prod-scan `file-uploads` with `upload-without-limit` and `original-filename` leads
- **Fix:** cap the size, check the type with a library such as file-type, store under a random name, and serve through signed URLs
- **Deeper:** `/backend` B3 and B18

### BE15 Secure server logic
- **Why:** business rules that run in the browser can be skipped by anyone with devtools
- **Pass when:** totals, discounts, limits, credits and permissions are computed and enforced on the server
- **Checked by:** prod-scan `server-logic` with `client-sends-value` leads, then manual reading of the money and role flows
- **Fix:** move the rule to the server and treat the client's value as display only
- **Deeper:** `/backend` B17

### BE16 Trim API responses
- **Why:** returning whole rows leaks password hashes, internal flags and other users' data
- **Pass when:** every response comes from an allowlist of fields (a DTO or a select list), with no hashes, secrets or internal fields
- **Checked by:** prod-scan `trim-responses` with `secret-in-response`, `select-all-users` and `whole-row` leads
- **Fix:** select only the needed columns and map rows to a response shape
- **Deeper:** `/backend` B3 and B16

### BE17 Secure auth sessions
- **Why:** a token in localStorage or a cookie without flags can be stolen by any script on the page
- **Pass when:** sessions use HttpOnly, Secure, SameSite cookies, tokens expire and rotate, and logout ends the session on the server
- **Checked by:** prod-scan `auth-sessions` with `cookie-flags`, `jwt-no-expiry`, `token-in-web-storage` and `token-in-script-cookie` leads
- **Fix:** use the auth library's server session or set the cookie flags, add expiry and rotation, and add a logout that clears the session
- **Deeper:** `/backend` B1 and B16

### BE18 Scan dependencies
- **Why:** known vulnerable packages are the easiest way in
- **Pass when:** a lockfile is committed, the audit shows no high or critical issue in production dependencies, and Dependabot or Renovate keeps them current
- **Checked by:** prod-scan `dependency-scan` (lockfile, update bot and the audit command to run), then the audit command itself
- **Fix:** commit the lockfile, upgrade or replace the vulnerable packages, and add Dependabot or Renovate
- **Deeper:** `/backend` B13

### BE19 Test record access
- **Why:** read, update and delete must each check ownership, and update and delete are often forgotten
- **Pass when:** `/security` proves another user's record cannot be read, updated or deleted
- **Checked by:** prod-scan `record-access` with `unscoped-lookup` leads, then manual active test
- **Fix:** include the owner or tenant in every lookup and write
- **Deeper:** `/backend` B2, `/security`

### BE20 Production config
- **Why:** debug pages, open CORS and stack traces hand attackers a map
- **Pass when:** debug is off, HTTPS and HSTS are on, security headers are set (CSP, X-Content-Type-Options, frame protection, Referrer-Policy), CORS uses an allowlist, and errors return a generic message
- **Checked by:** prod-scan `production-config` with `debug-on`, `cors-wildcard` and `stack-in-response` leads, prod-url `HSTS`, `CSP`, `X_CONTENT_TYPE_OPTIONS`, `FRAME_PROTECTION`, `REFERRER_POLICY` and `EXPOSED_GIT`
- **Fix:** turn debug off in production config, add the headers in the framework or host config, list allowed origins, and return a generic error with a request id
- **Deeper:** `/backend` B11 and B13, `/security` config testing
