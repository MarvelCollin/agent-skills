CPSCRIPTS="$ROOT/skills/checkprod/scripts"
CPFIX="$ROOT/tests/fixtures/checkprod"
CPGOOD="$WORK/checkprod-good"
CPBAD="$WORK/checkprod-bad"
CPGIT="$WORK/checkprod-git"
CPKEY="AKIAIOSFODNN7EXAMPLE"

cp -R "$CPFIX/good" "$CPGOOD"
cp -R "$CPFIX/bad" "$CPBAD"
mkdir -p "$CPGIT/config"
printf '{\n  "name": "history-demo",\n  "dependencies": { "next": "14.2.5" }\n}\n' >"$CPGIT/package.json"
printf 'module.exports = { awsKey: "%s" }\n' "$CPKEY" >"$CPGIT/config/keys.js"
printf 'API_TOKEN=history-token-4821\n' >"$CPGIT/.env"
printf 'DEBUG=false\n' >"$CPGIT/.env.production"
(
    cd "$CPGIT" &&
        git init -q &&
        git add -A &&
        git -c user.name=t -c user.email=t@t.test commit -q -m add &&
        git rm -q config/keys.js .env &&
        git -c user.name=t -c user.email=t@t.test commit -q -m remove
) >/dev/null 2>&1

checkprod_absent() {
    local name="$1" output="$2" unexpected="$3"
    if printf '%s\n' "$output" | grep -qF -- "$unexpected"; then
        fail "$name: did not expect '$unexpected'" "$output"
    else
        pass "$name"
    fi
}

checkprod_same() {
    local name="$1" first="$2" second="$3"
    if [ "$(printf '%s\n' "$first" | tail -n +2)" = "$(printf '%s\n' "$second" | tail -n +2)" ]; then
        pass "$name"
    else
        fail "$name" "$(diff <(printf '%s\n' "$first" | tail -n +2) <(printf '%s\n' "$second" | tail -n +2))"
    fi
}

checkprod_scan_checks() {
    local label="$1" good="$2" bad="$3" history="$4"
    expect_contains "$label detects the next app router" "$good" "FRAMEWORK: next-app"
    expect_contains "$label detects supabase and node" "$good" "BACKEND: supabase, node"
    expect_contains "$label counts scanned files" "$good" "FILES_SCANNED: 30"
    expect_contains "$label passes a custom 404" "$good" "FE1 pass custom-404: custom 404 page at app/not-found.tsx"
    expect_contains "$label passes a title per page" "$good" "FE3 pass meta-title: own title in all 7 pages"
    expect_contains "$label passes a description per page" "$good" "FE4 pass meta-description: own description in all 7 pages"
    expect_contains "$label passes share tags" "$good" "FE5 pass open-graph: share image at app/opengraph-image.png"
    expect_contains "$label passes the favicon set" "$good" "FE6 pass favicon-set:"
    expect_contains "$label passes a robots route with a sitemap" "$good" "FE7 pass robots-txt: app/robots.ts allows crawling"
    expect_contains "$label passes a sitemap route" "$good" "FE8 pass sitemap: sitemap at app/sitemap.ts"
    expect_contains "$label passes images with alt" "$good" "FE9 pass image-alt: all 2 images have alt text"
    expect_contains "$label leaves breakpoints to a browser" "$good" "FE10 manual mobile-breakpoints: viewport added by default in next-app"
    expect_contains "$label leaves the CTA to a browser" "$good" "FE2 manual cta-above-fold:"
    expect_contains "$label passes skeletons" "$good" "FE12 pass loading-states: skeleton at app/loading.tsx"
    expect_contains "$label passes inline form errors" "$good" "FE13 pass form-errors: field errors tied to inputs at components/ContactForm.tsx:"
    expect_contains "$label passes a thank you page" "$good" "FE14 pass form-success: success page at app/contact/thank-you/page.tsx"
    expect_contains "$label passes a privacy page in the footer" "$good" "FE15 pass privacy-page: page at app/privacy/page.tsx, linked from components/Footer.tsx:8"
    expect_contains "$label passes a terms page in the footer" "$good" "FE16 pass terms-page: page at app/terms/page.tsx, linked from components/Footer.tsx:9"
    expect_contains "$label skips consent without trackers" "$good" "FE17 n/a cookie-consent: no trackers or ad pixels found"
    expect_contains "$label passes privacy friendly analytics" "$good" "FE18 pass analytics: privacy friendly analytics at app/layout.tsx:2"
    expect_contains "$label passes real contact details" "$good" "FE19 pass real-content: contact at components/Footer.tsx:7"
    expect_contains "$label passes hidden keys" "$good" "BE1 pass hide-api-keys: no secret behind a public prefix"
    expect_contains "$label passes RLS on every table" "$good" "BE2 pass rls: RLS on all 3 tables in the migrations"
    expect_contains "$label leaves IDOR to /security" "$good" "BE3 manual idor-test:"
    expect_contains "$label reports a folder outside git" "$good" "BE4 manual git-history-secrets: not a git repository"
    expect_contains "$label passes a server side admin check" "$good" "BE5 pass admin-routes: server side role check on all admin routes (1)"
    expect_contains "$label passes rate limiting" "$good" "BE7 pass rate-limit:"
    expect_contains "$label passes private storage with signed URLs" "$good" "BE8 pass storage-buckets: signed URLs at app/api/upload/route.ts:27"
    expect_contains "$label passes validated routes" "$good" "BE9 pass input-validation: all 3 route files that read input validate it"
    expect_contains "$label passes auth middleware" "$good" "BE10 pass auth-by-default: auth middleware at middleware.ts"
    expect_contains "$label passes clean logs" "$good" "BE12 pass sensitive-logs:"
    expect_contains "$label passes server side values" "$good" "BE13 pass field-tampering:"
    expect_contains "$label passes limited uploads" "$good" "BE14 pass file-uploads: uploads limit size and check the type by content"
    expect_contains "$label passes trimmed responses" "$good" "BE16 pass trim-responses:"
    expect_contains "$label passes managed sessions" "$good" "BE17 pass auth-sessions: sessions handled by @supabase/ssr"
    expect_contains "$label names the audit command" "$good" "BE18 manual dependency-scan: lockfile package-lock.json, updates by .github/dependabot.yml, run: npm audit --omit=dev"
    expect_contains "$label passes production config" "$good" "BE20 pass production-config: security headers at next.config.js:1"
    expect_contains "$label finds no leads in the good project" "$good" "LEADS: 0"
    expect_contains "$label counts passes" "$good" "PASS: 28"
    expect_contains "$label counts no fails" "$good" "FAIL: 0"
    expect_contains "$label counts manual items" "$good" "MANUAL: 11"

    expect_contains "$label detects the next pages router" "$bad" "FRAMEWORK: next-pages"
    expect_contains "$label detects supabase, firebase and node" "$bad" "BACKEND: supabase, firebase, node"
    expect_contains "$label fails a missing 404" "$bad" "FE1 fail custom-404: no 404 page"
    expect_contains "$label fails missing page titles" "$bad" "FE3 fail meta-title: own title in 1 of 4 pages, first without one: pages/admin/index.jsx"
    expect_contains "$label fails missing descriptions" "$bad" "FE4 fail meta-description: own description in 0 of 4 pages"
    expect_contains "$label fails missing share tags" "$bad" "FE5 fail open-graph: no Open Graph tags or share image"
    expect_contains "$label warns on a partial favicon set" "$bad" "FE6 warn favicon-set: missing an SVG or PNG icon, a 180px apple touch icon, manifest icons"
    expect_contains "$label fails a robots.txt that blocks everything" "$bad" "FE7 fail robots-txt: public/robots.txt:2 disallows every path for all crawlers"
    expect_contains "$label fails a missing sitemap" "$bad" "FE8 fail sitemap:"
    expect_contains "$label fails images without alt" "$bad" "FE9 fail image-alt: 1 of 2 images have no alt, first at pages/index.jsx:12"
    expect_contains "$label lists an image without alt" "$bad" "FE9 img-without-alt pages/index.jsx:12: <img src=\"/hero.png\" />"
    expect_contains "$label reads an image tag split across lines" "$bad" "FE9 weak-alt pages/index.jsx:13: <img"
    expect_contains "$label warns on a page with no breakpoints" "$bad" "FE10 warn mobile-breakpoints:"
    expect_contains "$label warns on loading text without a skeleton" "$bad" "FE12 warn loading-states: loading flag at pages/pricing.jsx:14"
    expect_contains "$label fails forms without inline errors" "$bad" "FE13 fail form-errors:"
    expect_contains "$label fails forms without a success state" "$bad" "FE14 fail form-success:"
    expect_contains "$label fails a missing privacy page" "$bad" "FE15 fail privacy-page: no privacy policy page"
    expect_contains "$label fails a missing terms page" "$bad" "FE16 fail terms-page: no terms page"
    expect_contains "$label fails trackers without consent" "$bad" "FE17 fail cookie-consent: tracker at pages/_app.jsx:7 loads with no consent banner"
    expect_contains "$label fails a placeholder analytics id" "$bad" "FE18 fail analytics: analytics ID at pages/_app.jsx:7 looks like a placeholder"
    expect_contains "$label fails placeholder content" "$bad" "FE19 fail real-content: placeholder lines: 6, first at components/Footer.jsx:4"
    expect_contains "$label lists lorem ipsum" "$bad" "FE19 placeholder pages/index.jsx:11: <h1>Lorem ipsum dolor sit amet</h1>"
    expect_contains "$label lists a 555 number" "$bad" "FE19 placeholder pages/index.jsx:18:"
    expect_contains "$label lists a TODO in a page" "$bad" "FE19 todo-in-page pages/index.jsx:20:"
    checkprod_absent "$label skips input placeholders" "$bad" "contact.jsx:11"
    expect_contains "$label warns on http assets" "$bad" "FE20 warn domain-https: resources loaded over http: 1, first at components/Footer.jsx:6"
    expect_contains "$label fails exposed keys" "$bad" "BE1 fail hide-api-keys: public-env-secret 4, hardcoded-key 1, sourcemap-public 1, env-not-ignored 1"
    expect_contains "$label redacts a public env secret" "$bad" "BE1 public-env-secret .env.local:1: NEXT_PUBLIC_STRIPE_SECRET_KEY=<redacted>"
    expect_contains "$label redacts a hardcoded key" "$bad" "BE1 hardcoded-key lib/s3.js:5: credentials: { accessKeyId: \"<redacted>\""
    expect_contains "$label flags public source maps" "$bad" "BE1 sourcemap-public next.config.js:3:"
    expect_contains "$label flags env files git would commit" "$bad" "BE1 env-not-ignored .gitignore: no line ignores .env files"
    checkprod_absent "$label never prints the stripe value" "$bad" "sk_live_FAKE0000"
    checkprod_absent "$label never prints the aws key" "$bad" "$CPKEY"
    checkprod_absent "$label never prints the service role value" "$bad" "fake-service-role-value"
    expect_contains "$label fails open data rules" "$bad" "BE2 fail rls: open-policy 1, table-without-rls 1, open-rules 1"
    expect_contains "$label flags a write policy using true" "$bad" "BE2 open-policy supabase/migrations/001_init.sql:6:"
    expect_contains "$label flags a table without RLS" "$bad" "BE2 table-without-rls supabase/migrations/001_init.sql:9: create table public.orders ("
    expect_contains "$label flags open firestore rules" "$bad" "BE2 open-rules firestore.rules:5:"
    expect_contains "$label warns on admin routes without a server check" "$bad" "BE5 warn admin-routes: 2 of 2 admin routes"
    expect_contains "$label flags a client only role check" "$bad" "BE5 client-only-role-check pages/admin/index.jsx:6:"
    expect_contains "$label flags an admin API without a role check" "$bad" "BE5 admin-without-role-check pages/api/admin/users.js:"
    expect_contains "$label fails missing rate limits" "$bad" "BE7 fail rate-limit: no rate limiting found for 5 route files"
    expect_contains "$label fails public storage" "$bad" "BE8 fail storage-buckets: public-bucket 1, open-rules 1, public-url 1"
    expect_contains "$label flags a public bucket" "$bad" "BE8 public-bucket supabase/migrations/001_init.sql:16:"
    expect_contains "$label flags test mode storage rules" "$bad" "BE8 open-rules storage.rules:5:"
    expect_contains "$label fails unvalidated input" "$bad" "BE9 fail input-validation: none of 3 route files that read input validate it"
    expect_contains "$label fails routes without auth" "$bad" "BE10 fail auth-by-default: no session check in any of 4 private route files"
    expect_contains "$label warns on string built SQL" "$bad" "BE11 warn sql-injection: queries built from strings: 2"
    expect_contains "$label fails a logged password" "$bad" "BE12 sensitive-log pages/api/login.js:6:"
    expect_contains "$label fails a price from the request body" "$bad" "BE13 client-value pages/api/orders.js:6:"
    expect_contains "$label fails a client write of status" "$bad" "BE13 client-write components/Checkout.jsx:7:"
    expect_contains "$label fails uploads without limits" "$bad" "BE14 fail file-uploads: upload-without-limit 2, original-filename 4"
    expect_contains "$label warns when the client sends the total" "$bad" "BE15 warn server-logic: the client sends price, total, role or status at components/Checkout.jsx:6"
    expect_contains "$label fails a password hash in a response" "$bad" "BE16 fail trim-responses: secret-in-response 1, select-all-users 1, whole-row 1"
    expect_contains "$label fails weak sessions" "$bad" "BE17 fail auth-sessions: jwt-no-expiry 1, cookie-flags 1, token-in-web-storage 1"
    expect_contains "$label fails a missing lockfile" "$bad" "BE18 fail dependency-scan: package.json has no lockfile, commit one, then run: npm audit --omit=dev"
    expect_contains "$label warns on lookups without an owner" "$bad" "BE19 unscoped-lookup pages/api/users/[id].js:6:"
    expect_contains "$label fails debug and wildcard CORS" "$bad" "BE20 fail production-config: debug-on 1, cors-wildcard 1"
    expect_contains "$label counts leads" "$bad" "LEADS: 58"
    expect_contains "$label counts fails" "$bad" "FAIL: 27"
    expect_contains "$label counts warns" "$bad" "WARN: 8"
    expect_contains "$label counts passes in the bad project" "$bad" "PASS: 0"

    expect_contains "$label fails secrets in git history" "$history" "BE4 fail git-history-secrets: secret-in-history 2, env-in-history 2 in 2 commits"
    expect_matches "$label names the commit and file of a deleted key" "$history" "^BE4 secret-in-history config/keys.js@[0-9a-f]{7,}: aws-access-key, value not shown$"
    expect_matches "$label lists env files ever committed" "$history" "^BE4 env-in-history \.env@[0-9a-f]{7,}: env file committed"
    expect_contains "$label flags an env file tracked by git" "$history" "BE1 env-tracked .env.production: tracked by git"
    checkprod_absent "$label never prints a key from history" "$history" "$CPKEY"
    checkprod_absent "$label never prints an env value from history" "$history" "history-token-4821"
}

checkprod_url_checks() {
    local label="$1" full="$2" bare="$3" remote="$4" authorized="$5"
    expect_contains "$label reports a local scope" "$full" "SCOPE: local"
    expect_contains "$label reports the status" "$full" "HTTP_STATUS: 200"
    expect_contains "$label reports the final URL" "$full" "FINAL_URL: http://127.0.0.1:$PORT/"
    expect_matches "$label reports TTFB in whole milliseconds" "$full" "^TTFB_MS: [0-9]+$"
    expect_contains "$label reports plain http" "$full" "HTTPS: no (final URL is http)"
    expect_contains "$label reads HSTS" "$full" "HSTS: max-age=63072000; includeSubDomains"
    expect_contains "$label reads the CSP" "$full" "CSP: default-src 'self'; frame-ancestors 'none'"
    expect_contains "$label reads nosniff" "$full" "X_CONTENT_TYPE_OPTIONS: nosniff"
    expect_contains "$label reads frame protection" "$full" "FRAME_PROTECTION: DENY"
    expect_contains "$label reads the referrer policy" "$full" "REFERRER_POLICY: strict-origin-when-cross-origin"
    expect_contains "$label reads the title" "$full" "TITLE: Harbor Notes"
    expect_contains "$label reads the description" "$full" "META_DESCRIPTION: Plan your week with notes your whole team can edit."
    expect_contains "$label reads og title" "$full" "OG_TITLE: Harbor Notes"
    expect_contains "$label reads og description" "$full" "OG_DESCRIPTION: Shared notes for small teams."
    expect_contains "$label fetches the og image" "$full" "OG_IMAGE: http://127.0.0.1:$PORT/og.png (200 image/png)"
    expect_contains "$label reads the twitter card" "$full" "TWITTER_CARD: summary_large_image"
    expect_contains "$label reads the canonical URL" "$full" "CANONICAL: http://127.0.0.1:$PORT/"
    expect_contains "$label reads the viewport" "$full" "VIEWPORT: width=device-width, initial-scale=1"
    expect_contains "$label reads the language" "$full" "LANG: en"
    expect_contains "$label fetches the favicon" "$full" "FAVICON: ok (/favicon.ico, 200 image/x-icon)"
    expect_contains "$label fetches the apple touch icon" "$full" "APPLE_TOUCH_ICON: ok (/apple-touch-icon.png, 200 image/png)"
    expect_contains "$label reads robots.txt" "$full" "ROBOTS_TXT: ok (Sitemap: http://127.0.0.1:$PORT/sitemap.xml)"
    expect_contains "$label counts sitemap URLs" "$full" "SITEMAP_XML: ok (2 URLs)"
    expect_contains "$label sees a real 404 status" "$full" "NOT_FOUND_STATUS: 404"
    expect_contains "$label sees a custom 404 page" "$full" "NOT_FOUND_PAGE: custom"
    expect_contains "$label counts images" "$full" "IMAGES: 2"
    expect_contains "$label counts images with alt" "$full" "IMAGES_WITHOUT_ALT: 0"
    expect_contains "$label finds no exposed env file" "$full" "EXPOSED_ENV: no (HTTP 404)"
    expect_contains "$label finds no exposed git folder" "$full" "EXPOSED_GIT: no (HTTP 404)"
    expect_contains "$label finds no public source map" "$full" "SOURCE_MAPS: no (/static/app.js.map returns 404)"
    expect_matches "$label stays within about 12 requests" "$full" "^REQUESTS: ([0-9]|1[0-2])$"

    expect_contains "$label reports a missing title" "$bare" "TITLE: missing"
    expect_contains "$label reports a missing description" "$bare" "META_DESCRIPTION: missing"
    expect_contains "$label reports a missing og image" "$bare" "OG_IMAGE: missing"
    expect_contains "$label reports a missing viewport" "$bare" "VIEWPORT: missing"
    expect_contains "$label reports a missing language" "$bare" "LANG: missing"
    expect_contains "$label reports missing HSTS" "$bare" "HSTS: missing"
    expect_contains "$label treats an HTML favicon as missing" "$bare" "FAVICON: missing (/favicon.ico returns text/html)"
    expect_contains "$label treats an HTML robots.txt as missing" "$bare" "ROBOTS_TXT: missing (returns HTML, not a robots file)"
    expect_contains "$label treats an HTML sitemap as missing" "$bare" "SITEMAP_XML: missing (returns HTML, not XML)"
    expect_contains "$label flags a soft 404" "$bare" "NOT_FOUND_STATUS: 200 (soft 404)"
    expect_contains "$label counts images without alt" "$bare" "IMAGES_WITHOUT_ALT: 2"
    expect_contains "$label flags an exposed env file" "$bare" "EXPOSED_ENV: yes (/.env returns KEY=value lines"
    expect_contains "$label flags an exposed git folder" "$bare" "EXPOSED_GIT: yes (/.git/HEAD is readable"
    expect_contains "$label flags a public source map" "$bare" "SOURCE_MAPS: yes (/app.js.map is public)"
    checkprod_absent "$label never prints the env file body" "$bare" "fixture-not-a-real-key"
    checkprod_absent "$label never prints the git head" "$bare" "refs/heads/main"

    expect_contains "$label keeps a remote host passive" "$remote" "SCOPE: remote passive"
    expect_contains "$label still reads a remote page" "$remote" "TITLE: Harbor Notes"
    expect_contains "$label skips env probes on a remote host" "$remote" "EXPOSED_ENV: not checked (remote host, pass --authorized after the user confirms they own it)"
    expect_contains "$label skips git probes on a remote host" "$remote" "EXPOSED_GIT: not checked (remote host"
    expect_contains "$label skips source map probes on a remote host" "$remote" "SOURCE_MAPS: not checked (remote host"
    expect_contains "$label probes an authorized remote host" "$authorized" "SCOPE: remote authorized"
    expect_contains "$label runs exposure probes when authorized" "$authorized" "EXPOSED_ENV: no (HTTP 404)"
}

echo "prod-scan.sh"
CPGOOD_SH=$(bash "$CPSCRIPTS/prod-scan.sh" "$CPGOOD" 2>&1); CODE=$?
expect_exit "exits 0 on a ready project" "$CODE" 0
CPBAD_SH=$(bash "$CPSCRIPTS/prod-scan.sh" "$CPBAD" 2>&1); CODE=$?
expect_exit "exits 0 on a project with gaps" "$CODE" 0
CPGIT_SH=$(bash "$CPSCRIPTS/prod-scan.sh" "$CPGIT" 2>&1)
checkprod_scan_checks "sh" "$CPGOOD_SH" "$CPBAD_SH" "$CPGIT_SH"
OUT=$(bash "$CPSCRIPTS/prod-scan.sh" "$WORK/checkprod-missing" 2>&1); CODE=$?
expect_exit "fails on a missing path" "$CODE" 1
expect_contains "prints an error for a missing path" "$OUT" "ERROR:"
OUT=$(bash "$CPSCRIPTS/prod-scan.sh" "$CPGOOD/package.json" 2>&1); CODE=$?
expect_exit "fails on a file instead of a folder" "$CODE" 1
expect_contains "asks for the project folder" "$OUT" "ERROR: $CPGOOD/package.json is not a folder"
bash "$CPSCRIPTS/prod-scan.sh" >/dev/null 2>&1; CODE=$?
expect_exit "fails without a path" "$CODE" 1

echo "prod-url.sh"
CPFULL_SH=$(bash "$CPSCRIPTS/prod-url.sh" "$BASE/" 2>&1); CODE=$?
expect_exit "succeeds on a complete site" "$CODE" 0
CPBARE_SH=$(bash "$CPSCRIPTS/prod-url.sh" "http://localhost:$PORT/" 2>&1); CODE=$?
expect_exit "succeeds on a bare site" "$CODE" 0
CPREMOTE_SH=$(bash "$CPSCRIPTS/prod-url.sh" "http://2130706433:$PORT/" 2>&1)
CPAUTH_SH=$(bash "$CPSCRIPTS/prod-url.sh" "http://2130706433:$PORT/" --authorized 2>&1)
checkprod_url_checks "sh" "$CPFULL_SH" "$CPBARE_SH" "$CPREMOTE_SH" "$CPAUTH_SH"
OUT=$(bash "$CPSCRIPTS/prod-url.sh" "ftp://example.com/" 2>&1); CODE=$?
expect_exit "rejects a non http URL" "$CODE" 1
expect_contains "explains the URL scheme rule" "$OUT" "ERROR: url must start with http:// or https://."
OUT=$(bash "$CPSCRIPTS/prod-url.sh" "$DEAD" 2>&1); CODE=$?
expect_exit "fails on an unreachable URL" "$CODE" 1
expect_contains "prints an error for an unreachable URL" "$OUT" "ERROR: request to $DEAD failed."
bash "$CPSCRIPTS/prod-url.sh" >/dev/null 2>&1; CODE=$?
expect_exit "fails without a URL" "$CODE" 1

if [ -n "$POWERSHELL" ]; then
    echo "prod-scan.ps1"
    CPGOOD_PS=$(run_ps "$CPSCRIPTS/prod-scan.ps1" -Path "$CPGOOD" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "exits 0 on a ready project" "$CODE" 0
    CPBAD_PS=$(run_ps "$CPSCRIPTS/prod-scan.ps1" -Path "$CPBAD" 2>&1 | tr -d '\r')
    CPGIT_PS=$(run_ps "$CPSCRIPTS/prod-scan.ps1" -Path "$CPGIT" 2>&1 | tr -d '\r')
    checkprod_scan_checks "ps1" "$CPGOOD_PS" "$CPBAD_PS" "$CPGIT_PS"
    checkprod_same "ps1 matches sh on the ready project" "$CPGOOD_SH" "$CPGOOD_PS"
    checkprod_same "ps1 matches sh on the project with gaps" "$CPBAD_SH" "$CPBAD_PS"
    checkprod_same "ps1 matches sh on git history" "$CPGIT_SH" "$CPGIT_PS"
    OUT=$(run_ps "$CPSCRIPTS/prod-scan.ps1" -Path "$WORK/checkprod-missing" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "fails on a missing path" "$CODE" 1
    expect_contains "prints an error for a missing path" "$OUT" "ERROR:"
    OUT=$(run_ps "$CPSCRIPTS/prod-scan.ps1" -Path "$CPGOOD/package.json" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "fails on a file instead of a folder" "$CODE" 1
    expect_contains "asks for the project folder" "$OUT" "is not a folder"

    echo "prod-url.ps1"
    CPFULL_PS=$(run_ps "$CPSCRIPTS/prod-url.ps1" -Url "$BASE/" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "succeeds on a complete site" "$CODE" 0
    CPBARE_PS=$(run_ps "$CPSCRIPTS/prod-url.ps1" -Url "http://localhost:$PORT/" 2>&1 | tr -d '\r')
    CPREMOTE_PS=$(run_ps "$CPSCRIPTS/prod-url.ps1" -Url "http://2130706433:$PORT/" 2>&1 | tr -d '\r')
    CPAUTH_PS=$(run_ps "$CPSCRIPTS/prod-url.ps1" -Url "http://2130706433:$PORT/" -Authorized 2>&1 | tr -d '\r')
    checkprod_url_checks "ps1" "$CPFULL_PS" "$CPBARE_PS" "$CPREMOTE_PS" "$CPAUTH_PS"
    OUT=$(run_ps "$CPSCRIPTS/prod-url.ps1" -Url "ftp://example.com/" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "rejects a non http URL" "$CODE" 1
    expect_contains "explains the URL scheme rule" "$OUT" "ERROR: url must start with http:// or https://."
    OUT=$(run_ps "$CPSCRIPTS/prod-url.ps1" -Url "$DEAD" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "fails on an unreachable URL" "$CODE" 1
    expect_contains "prints an error for an unreachable URL" "$OUT" "ERROR: request to $DEAD failed."
else
    echo "PowerShell not found, skipping checkprod .ps1 tests"
fi
