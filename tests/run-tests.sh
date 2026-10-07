#!/bin/bash
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$ROOT/skills/uiux/scripts"
SECSCRIPTS="$ROOT/skills/security/scripts"
BACKSCRIPTS="$ROOT/skills/backend/scripts"
BACKFIX="$ROOT/tests/fixtures/backend"
DBFIX="$ROOT/tests/fixtures/db"
CONVFIX="$ROOT/tests/fixtures/conventions"
SECFIX="$ROOT/tests/fixtures/security"
FAKES="$ROOT/tests/fakes"
WORK="$(mktemp -d)"
PASSED=0
FAILED=0
SERVER_PID=""

cleanup() {
    if [ -n "$SERVER_PID" ]; then
        kill "$SERVER_PID" 2>/dev/null || true
    fi
    rm -rf "$WORK"
}
trap cleanup EXIT

pass() {
    PASSED=$((PASSED + 1))
    echo "  ok   $1"
}

fail() {
    FAILED=$((FAILED + 1))
    echo "  FAIL $1"
    if [ -n "${2:-}" ]; then
        printf '%s\n' "$2" | sed 's/^/       /'
    fi
}

expect_contains() {
    local name="$1" output="$2" expected="$3"
    if printf '%s\n' "$output" | grep -qF -- "$expected"; then
        pass "$name"
    else
        fail "$name: expected '$expected'" "$output"
    fi
}

expect_matches() {
    local name="$1" output="$2" pattern="$3"
    if printf '%s\n' "$output" | grep -qE -- "$pattern"; then
        pass "$name"
    else
        fail "$name: expected /$pattern/" "$output"
    fi
}

expect_exit() {
    local name="$1" actual="$2" expected="$3"
    if [ "$actual" -eq "$expected" ]; then
        pass "$name"
    else
        fail "$name: exit $actual, expected $expected"
    fi
}

find_python() {
    local candidate
    for candidate in python3 python; do
        if command -v "$candidate" &>/dev/null && "$candidate" -c "import sys; sys.exit(0 if sys.version_info >= (3, 7) else 1)" &>/dev/null; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

find_powershell() {
    local candidate
    for candidate in pwsh powershell; do
        if command -v "$candidate" &>/dev/null; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

run_ps() {
    "$POWERSHELL" -NoProfile -ExecutionPolicy Bypass -File "$@"
}

PYTHON="$(find_python)" || { echo "python 3.7+ is required to run the tests"; exit 1; }
POWERSHELL="$(find_powershell)" || POWERSHELL=""

"$PYTHON" "$ROOT/tests/fixture_server.py" >"$WORK/port" &
SERVER_PID=$!
for _ in $(seq 1 50); do
    [ -s "$WORK/port" ] && break
    sleep 0.1
done
PORT="$(tr -d '\r\n' <"$WORK/port")"
if [ -z "$PORT" ]; then
    echo "fixture server did not start"
    exit 1
fi
BASE="http://127.0.0.1:$PORT"
DEAD="http://127.0.0.1:1"

echo "perf-check.sh"
OUT=$(bash "$SCRIPTS/perf-check.sh" "$BASE/" 2>&1); CODE=$?
expect_exit "succeeds on a live page" "$CODE" 0
expect_contains "reports status" "$OUT" "HTTP_STATUS: 200"
expect_contains "detects gzip when the client asks for it" "$OUT" "COMPRESSION: enabled (gzip)"
expect_contains "reports cache-control" "$OUT" "CACHE_CONTROL: max-age=3600"
expect_matches "reports TTFB in whole milliseconds" "$OUT" "^TTFB_MS: [0-9]+$"
expect_contains "rates a fast local TTFB as good" "$OUT" "TTFB_RATING: good"
OUT=$(bash "$SCRIPTS/perf-check.sh" "$BASE/plain" 2>&1)
expect_contains "reports missing compression" "$OUT" "COMPRESSION: disabled"
expect_contains "reports missing cache-control" "$OUT" "CACHE_CONTROL: missing"
OUT=$(bash "$SCRIPTS/perf-check.sh" "$BASE/redirect" 2>&1)
expect_contains "follows and counts redirects" "$OUT" "REDIRECTS: 1"
expect_contains "reports the final URL" "$OUT" "FINAL_URL: $BASE/"
OUT=$(bash "$SCRIPTS/perf-check.sh" "$DEAD" 2>&1); CODE=$?
expect_exit "fails on an unreachable URL" "$CODE" 1
expect_contains "prints an error for an unreachable URL" "$OUT" "ERROR: request to $DEAD failed."
bash "$SCRIPTS/perf-check.sh" >/dev/null 2>&1; CODE=$?
expect_exit "fails without a URL" "$CODE" 1

echo "axe-scan.sh"
OUT=$(PATH="$FAKES:$PATH" FAKE_NPX_MODE=ok bash "$SCRIPTS/axe-scan.sh" "$BASE/" "$WORK/axe" 2>&1); CODE=$?
expect_exit "succeeds when axe writes results" "$CODE" 0
expect_contains "reports the results path" "$OUT" "AXE_RESULTS: $WORK/axe/axe-results.json"
expect_contains "counts violated rules" "$OUT" "VIOLATIONS: 2"
expect_contains "counts affected nodes" "$OUT" "VIOLATION_NODES: 5"
expect_contains "counts passes" "$OUT" "PASSES: 3"
expect_matches "lists the most frequent violation first" "$(printf '%s\n' "$OUT" | grep -A1 'TOP VIOLATIONS:')" "\[serious\] color-contrast: .* \(3 instances\)"
OUT=$(PATH="$FAKES:$PATH" FAKE_NPX_MODE=fail bash "$SCRIPTS/axe-scan.sh" "$BASE/" "$WORK/axe-fail" 2>&1); CODE=$?
expect_exit "fails when axe fails" "$CODE" 1
expect_contains "prints an error when axe fails" "$OUT" "ERROR: axe scan failed."

echo "lighthouse-audit.sh"
OUT=$(PATH="$FAKES:$PATH" FAKE_NPX_MODE=ok bash "$SCRIPTS/lighthouse-audit.sh" "$BASE/" "$WORK/lh" 2>&1); CODE=$?
expect_exit "succeeds when lighthouse writes a report" "$CODE" 0
expect_contains "rounds category scores" "$OUT" "performance: 87"
expect_contains "reports a perfect score" "$OUT" "best-practices: 100"
expect_contains "reports a null score as n/a" "$OUT" "seo: n/a"
expect_contains "reports key metrics" "$OUT" "largest-contentful-paint: 2.1 s"
OUT=$(PATH="$FAKES:$PATH" FAKE_NPX_MODE=fail-after-write bash "$SCRIPTS/lighthouse-audit.sh" "$BASE/" "$WORK/lh-warn" 2>&1); CODE=$?
expect_exit "keeps a report written before a non-zero exit" "$CODE" 0
expect_contains "warns about the non-zero exit" "$OUT" "WARNING: Lighthouse exited with 1"
OUT=$(PATH="$FAKES:$PATH" FAKE_NPX_MODE=fail bash "$SCRIPTS/lighthouse-audit.sh" "$BASE/" "$WORK/lh-fail" 2>&1); CODE=$?
expect_exit "fails when no report is written" "$CODE" 1
expect_contains "prints an error when no report is written" "$OUT" "ERROR: Lighthouse audit failed"

RULES="$ROOT/tests/fixtures/rules"
mkdir -p "$WORK/rules-project/node_modules/lib"
cp "$RULES/good/page.html" "$WORK/rules-project/page.html"
cp "$RULES/bad/dashboard.html" "$WORK/rules-project/node_modules/lib/dashboard.html"
mkdir -p "$WORK/rules-big"
for i in $(seq 1 320); do echo "  <p>line $i</p>"; done >"$WORK/rules-big/Huge.tsx"

rule_scan_checks() {
    local label="$1" bad_output="$2" good_output="$3" vendored_output="$4"
    expect_contains "$label flags saturated fills" "$bad_output" "R1 saturated-fill dashboard.html:3:"
    expect_contains "$label flags icon tiles" "$bad_output" "R3 icon-tile dashboard.html:3:"
    expect_contains "$label flags pill badges" "$bad_output" "R4 pill-badge dashboard.html:7:"
    expect_contains "$label flags tables without column filters" "$bad_output" "R5 table-without-column-filters dashboard.html:11:"
    expect_contains "$label flags fixed-size overlays" "$bad_output" "R6 fixed-size-overlay dashboard.html:14:"
    expect_contains "$label flags native date inputs" "$bad_output" "R7 native-control dashboard.html:8:"
    expect_contains "$label flags native selects" "$bad_output" "R7 native-control dashboard.html:9:"
    expect_contains "$label flags native checkboxes" "$bad_output" "R7 native-control dashboard.html:10:"
    expect_contains "$label flags browser dialogs" "$bad_output" "R7 browser-dialog dashboard.html:16:"
    expect_contains "$label flags default scrollbars" "$bad_output" "R7 default-scrollbar dashboard.html:15:"
    expect_contains "$label flags em dashes" "$bad_output" "R9 em-dash dashboard.html:12:"
    expect_contains "$label flags semicolons in markup copy" "$bad_output" "R9 semicolon-in-copy dashboard.html:13:"
    expect_contains "$label flags semicolons in string files" "$bad_output" "R9 semicolon-in-copy strings.json:2:"
    expect_contains "$label flags tables without pagination" "$bad_output" "R10 table-without-pagination dashboard.html:11:"
    expect_contains "$label flags initials avatars" "$bad_output" "R11 initials-avatar dashboard.html:"
    expect_contains "$label flags interfaces inside components" "$bad_output" "R13 inline-types OrderCard.tsx:3:"
    expect_contains "$label flags type aliases inside components" "$bad_output" "R13 inline-types OrderCard.tsx:8:"
    expect_contains "$label flags fetch inside components" "$bad_output" "R13 fetch-in-component OrderCard.tsx:13:"
    expect_contains "$label counts every finding" "$bad_output" "FINDINGS: 18"
    expect_contains "$label passes clean UI" "$good_output" "FINDINGS: 0"
    expect_contains "$label skips node_modules" "$vendored_output" "FINDINGS: 0"
}

echo "rule-scan.sh"
BAD=$(bash "$SCRIPTS/rule-scan.sh" "$RULES/bad" 2>&1); CODE=$?
expect_exit "exits 0 when it finds violations" "$CODE" 0
GOOD=$(bash "$SCRIPTS/rule-scan.sh" "$RULES/good" 2>&1)
VENDORED=$(bash "$SCRIPTS/rule-scan.sh" "$WORK/rules-project" 2>&1)
rule_scan_checks "it" "$BAD" "$GOOD" "$VENDORED"
OUT=$(bash "$SCRIPTS/rule-scan.sh" "$RULES/bad/strings.json" 2>&1)
expect_contains "scans a single file" "$OUT" "R9 semicolon-in-copy strings.json:2:"
OUT=$(bash "$SCRIPTS/rule-scan.sh" "$WORK/rules-big" 2>&1)
expect_contains "flags components over 300 lines" "$OUT" "R13 large-component Huge.tsx:1: 320 lines"
OUT=$(bash "$SCRIPTS/rule-scan.sh" "$WORK/missing" 2>&1); CODE=$?
expect_exit "fails on a missing path" "$CODE" 1
expect_contains "prints an error for a missing path" "$OUT" "ERROR:"

SCOPE="$SECFIX/scope/scope.md"
CODE_DIR="$SECFIX/code"

scope_checks() {
    local label="$1" runner="$2"
    local out code
    out=$($runner "$SCOPE" "https://app.demo.test/x" 2>&1); code=$?
    expect_exit "$label in-scope exact exits 0" "$code" 0
    expect_contains "$label reports in-scope" "$out" "IN_SCOPE"
    $runner "$SCOPE" "https://a.staging.demo.com" >/dev/null 2>&1; expect_exit "$label in-scope wildcard exits 0" "$?" 0
    $runner "$SCOPE" "http://localhost:3000" >/dev/null 2>&1; expect_exit "$label local host exits 0" "$?" 0
    out=$($runner "$SCOPE" "https://payments.example.com" 2>&1); code=$?
    expect_exit "$label out-of-scope exits 2" "$code" 2
    expect_contains "$label reports out-of-scope" "$out" "OUT_OF_SCOPE"
    $runner "$SCOPE" "https://old.legacy.example.com" >/dev/null 2>&1; expect_exit "$label out-of-scope wildcard exits 2" "$?" 2
    out=$($runner "$SCOPE" "https://evil.com" 2>&1); code=$?
    expect_exit "$label unlisted exits 1" "$code" 1
    expect_contains "$label reports unlisted" "$out" "NOT_LISTED"
    $runner "$SECFIX/scope/missing.md" "http://localhost" >/dev/null 2>&1; expect_exit "$label missing scope file exits 3" "$?" 3
}

scope_init_checks() {
    local label="$1" runner="$2" checker="$3" out_flag="$4"
    local dir="$WORK/init-$label" out code scope
    mkdir -p "$dir"
    out=$($runner "http://localhost:3000/login" $out_flag "$dir" 2>&1 | tr -d '\r'); code=$?
    expect_exit "$label local url exits 0" "$code" 0
    expect_contains "$label reports created" "$out" "SCOPE_STATUS: created"
    expect_contains "$label reports host" "$out" "HOST: localhost"
    expect_matches "$label names folder by host and port" "$out" "ENGAGEMENT_DIR: .*security-localhost-3000-[0-9]{8}$"
    scope="$(printf '%s\n' "$out" | sed -n 's/^SCOPE_FILE: //p')"
    expect_contains "$label writes in-scope host" "$(cat "$scope" 2>/dev/null)" "- In scope: localhost"
    expect_contains "$label records local authorization" "$(cat "$scope" 2>/dev/null)" "- Authorization: local dev build"
    $checker "$scope" "http://localhost:3000/api" >/dev/null 2>&1; expect_exit "$label scope passes scope-check" "$?" 0
    $checker "$scope" "https://evil.com" >/dev/null 2>&1; expect_exit "$label scope rejects other hosts" "$?" 1
    out=$($runner "http://localhost:3000" $out_flag "$dir" 2>&1 | tr -d '\r')
    expect_contains "$label keeps an existing scope" "$out" "SCOPE_STATUS: existing"
    out=$($runner "192.168.1.20:8080" $out_flag "$dir" 2>&1 | tr -d '\r'); code=$?
    expect_exit "$label private host exits 0" "$code" 0
    out=$($runner "$CODE_DIR" $out_flag "$dir" 2>&1 | tr -d '\r'); code=$?
    expect_exit "$label source path exits 0" "$code" 0
    expect_contains "$label reports source kind" "$out" "KIND: source"
    expect_matches "$label names folder by source dir" "$out" "ENGAGEMENT_DIR: .*security-code-[0-9]{8}$"
    out=$($runner "https://example.com" $out_flag "$dir" 2>&1 | tr -d '\r'); code=$?
    expect_exit "$label public host exits 1" "$code" 1
    expect_contains "$label prints an error for a public host" "$out" "ERROR: example.com is not a local"
    out=$($runner "http://localhost" $out_flag "$WORK/nope-init" 2>&1 | tr -d '\r'); code=$?
    expect_exit "$label missing output dir exits 1" "$code" 1
}

DEVPROJ="$WORK/devproj"
mkdir -p "$DEVPROJ" "$WORK/emptyproj"
printf '{\n  "scripts": { "dev": "vite" },\n  "dependencies": { "express": "^4.0.0" },\n  "devDependencies": { "vite": "^5.0.0" }\n}\n' >"$DEVPROJ/package.json"

dev_detect_checks() {
    local label="$1" runner="$2" path_flag="$3" ports_flag="$4"
    local out code
    out=$($runner $path_flag "$DEVPROJ" $ports_flag "1,$PORT" 2>&1 | tr -d '\r'); code=$?
    expect_exit "$label succeeds on a project" "$code" 0
    expect_contains "$label detects the stack" "$out" "STACK: node, vite, express"
    expect_contains "$label finds the dev command" "$out" "DEV_COMMAND: npm run dev"
    expect_contains "$label finds the running server" "$out" "LISTENING: http://127.0.0.1:$PORT (HTTP 200)"
    expect_contains "$label skips closed ports" "$out" "LISTENING_COUNT: 1"
    expect_contains "$label suggests the running server" "$out" "SUGGESTED_TARGET: http://127.0.0.1:$PORT"
    out=$($runner $path_flag "$WORK/emptyproj" $ports_flag "1" 2>&1 | tr -d '\r'); code=$?
    expect_exit "$label succeeds with nothing running" "$code" 0
    expect_contains "$label reports an unknown stack" "$out" "STACK: unknown"
    expect_contains "$label reports no target" "$out" "SUGGESTED_TARGET: none"
    out=$($runner $path_flag "$WORK/nope-dev" 2>&1 | tr -d '\r'); code=$?
    expect_exit "$label fails on a missing project" "$code" 1
    expect_contains "$label prints an error for a missing project" "$out" "ERROR:"
    out=$($runner $path_flag "$DEVPROJ" $ports_flag "80;rm" 2>&1 | tr -d '\r'); code=$?
    expect_exit "$label rejects a bad port list" "$code" 1
}

audit_checks() {
    local label="$1" audit_output="$2" safe_output="$3"
    expect_contains "$label flags hardcoded secrets" "$audit_output" "[hardcoded-secret] app.py:2:"
    expect_contains "$label flags aws keys" "$audit_output" "[aws-key] app.py:9:"
    expect_contains "$label flags sql string concatenation" "$audit_output" "[sql-concat] app.py:4:"
    expect_contains "$label flags command execution" "$audit_output" "[command-exec] app.py:6:"
    expect_contains "$label flags weak crypto" "$audit_output" "[weak-crypto] app.py:8:"
    expect_contains "$label flags eval" "$audit_output" "[code-eval] sub/ui.js:3:"
    expect_contains "$label flags dangerous dom sinks" "$audit_output" "[dangerous-dom] sub/ui.js:1:"
    expect_contains "$label flags permissive cors" "$audit_output" "[permissive-cors] sub/ui.js:2:"
    expect_contains "$label counts nine leads" "$audit_output" "LEADS: 9"
    expect_matches "$label leaves safe code clean" "$safe_output" "safe\.py"
}

mkdir -p "$WORK/backend-project/node_modules/lib" "$WORK/backend-project/tests" "$WORK/backend-project/src"
cp "$BACKFIX/bad/orders.js" "$WORK/backend-project/node_modules/lib/orders.js"
cp "$BACKFIX/bad/orders.js" "$WORK/backend-project/tests/orders.js"
cp "$BACKFIX/bad/orders.js" "$WORK/backend-project/src/orders.test.js"
cp "$BACKFIX/good/orders.js" "$WORK/backend-project/src/orders.js"

backend_scan_checks() {
    local label="$1" bad="$2" good="$3" vendored="$4"
    expect_contains "$label flags weak password hashing" "$bad" "B1 weak-password-hash app.py:22:"
    expect_contains "$label flags unscoped lookups in js" "$bad" "B2 unscoped-lookup orders.js:14:"
    expect_contains "$label flags unscoped lookups in python" "$bad" "B2 unscoped-lookup app.py:21:"
    expect_contains "$label flags client supplied roles" "$bad" "B2 client-authority orders.js:20:"
    expect_contains "$label flags mass assignment" "$bad" "B2 mass-assignment orders.js:19:"
    expect_contains "$label flags a query in a for loop" "$bad" "B4 query-in-loop orders.js:6:"
    expect_contains "$label flags an orm call in a python loop" "$bad" "B4 query-in-loop app.py:8:"
    expect_contains "$label flags a query in a comprehension" "$bad" "B4 query-in-loop app.py:9:"
    expect_contains "$label flags http calls in a map" "$bad" "B4 http-in-loop orders.js:8:"
    expect_contains "$label flags unbounded prisma queries" "$bad" "B5 unbounded-query orders.js:4:"
    expect_contains "$label flags unbounded django queries" "$bad" "B5 unbounded-query app.py:6:"
    expect_contains "$label flags offset pagination" "$bad" "B5 offset-pagination orders.js:30:"
    expect_contains "$label flags select star" "$bad" "B5 select-star orders.js:6:"
    expect_contains "$label flags requests without a timeout" "$bad" "B8 no-timeout app.py:11:"
    expect_contains "$label flags fetch without a signal" "$bad" "B8 no-timeout orders.js:8:"
    expect_contains "$label flags console logging" "$bad" "B9 unstructured-log orders.js:9:"
    expect_contains "$label flags print logging" "$bad" "B9 unstructured-log app.py:10:"
    expect_contains "$label flags secrets in logs" "$bad" "B9 sensitive-log orders.js:29:"
    expect_contains "$label flags empty one-line catches" "$bad" "B11 swallowed-error orders.js:28:"
    expect_contains "$label flags empty multi-line catches" "$bad" "B11 swallowed-error orders.js:39:"
    expect_contains "$label flags except pass" "$bad" "B11 swallowed-error app.py:15:"
    expect_contains "$label flags bare except" "$bad" "B11 bare-except app.py:15:"
    expect_contains "$label flags raw errors sent to clients" "$bad" "B11 leaked-error orders.js:33:"
    expect_contains "$label flags str(e) in responses" "$bad" "B11 leaked-error app.py:29:"
    expect_contains "$label flags sync file reads" "$bad" "B12 blocking-call orders.js:31:"
    expect_contains "$label flags time.sleep" "$bad" "B12 blocking-call app.py:23:"
    expect_contains "$label flags credentials in connection strings" "$bad" "B13 credentials-in-dsn app.py:24:"
    expect_contains "$label flags secret fallbacks in js" "$bad" "B13 secret-fallback orders.js:32:"
    expect_contains "$label flags secret fallbacks in python" "$bad" "B13 secret-fallback app.py:25:"
    expect_contains "$label flags parseFloat on money" "$bad" "B14 float-money orders.js:26:"
    expect_contains "$label flags naive datetimes" "$bad" "B14 naive-datetime app.py:12:"
    expect_contains "$label counts every lead" "$bad" "FINDINGS: 31"
    expect_contains "$label counts leads per rule" "$bad" "B11: 6"
    expect_contains "$label passes clean code" "$good" "FINDINGS: 0"
    expect_contains "$label skips vendored and test files" "$vendored" "FINDINGS: 0"
    expect_contains "$label still scans source next to tests" "$vendored" "FILES_SCANNED: 1"
}

db_lint_checks() {
    local label="$1" bad="$2" good="$3"
    expect_contains "$label flags indexes built under lock" "$bad" "B6 index-not-concurrent 002_changes.sql:11:"
    expect_contains "$label exempts indexes on tables created in the same file" "$(printf '%s\n' "$bad" | grep -c '001_init.sql:20' || true)" "0"
    expect_contains "$label flags concurrent index in a transaction" "$bad" "B6 concurrent-in-transaction 002_changes.sql:10:"
    expect_contains "$label flags constraints validated under lock" "$bad" "B6 constraint-validates-under-lock 002_changes.sql:8:"
    expect_contains "$label flags unique constraints built under lock" "$bad" "B6 unique-under-lock 002_changes.sql:9:"
    expect_contains "$label flags set not null" "$bad" "B6 set-not-null 002_changes.sql:4:"
    expect_contains "$label flags column type changes" "$bad" "B6 column-type-change 002_changes.sql:5:"
    expect_contains "$label flags volatile defaults" "$bad" "B6 volatile-default 002_changes.sql:3:"
    expect_contains "$label flags not null columns without default" "$bad" "B6 not-null-without-default 002_changes.sql:2:"
    expect_contains "$label flags renames" "$bad" "B6 rename 002_changes.sql:6:"
    expect_contains "$label flags dropped columns" "$bad" "B6 drop 002_changes.sql:7:"
    expect_contains "$label flags unbatched writes" "$bad" "B6 unbatched-write 002_changes.sql:12:"
    expect_contains "$label flags heavy locks" "$bad" "B6 heavy-lock 002_changes.sql:13:"
    expect_contains "$label flags migrations without lock timeout" "$bad" "B6 no-lock-timeout 002_changes.sql:2:"
    expect_contains "$label flags unindexed foreign keys in sql" "$bad" "B6 fk-without-index 001_init.sql:10:"
    expect_contains "$label flags unindexed relations in prisma" "$bad" "B6 fk-without-index schema.prisma:9:"
    expect_contains "$label flags tables without a primary key" "$bad" "B6 missing-primary-key 001_init.sql:15:"
    expect_contains "$label flags json columns" "$bad" "B6 json-not-jsonb 001_init.sql:12:"
    expect_contains "$label flags char columns" "$bad" "B6 char-column 001_init.sql:4:"
    expect_contains "$label flags float money in sql" "$bad" "B14 float-money 001_init.sql:11:"
    expect_contains "$label flags float money in prisma" "$bad" "B14 float-money schema.prisma:10:"
    expect_contains "$label flags timestamp without time zone" "$bad" "B14 timestamp-without-tz 001_init.sql:5:"
    expect_contains "$label flags prisma datetime without timestamptz" "$bad" "B14 timestamp-without-tz schema.prisma:11:"
    expect_contains "$label flags random uuid keys in sql" "$bad" "B14 random-uuid-key 001_init.sql:2:"
    expect_contains "$label flags random uuid keys in prisma" "$bad" "B14 random-uuid-key schema.prisma:7:"
    expect_contains "$label counts every lead" "$bad" "FINDINGS: 24"
    expect_contains "$label passes clean migrations and schema" "$good" "FINDINGS: 0"
}

mkdir -p "$WORK/conv"
cp -r "$CONVFIX/project" "$WORK/conv/project"
cp -r "$CONVFIX/plain" "$WORK/conv/plain"
mkdir -p "$WORK/conv/project/node_modules/Bad_Lib"
echo "export const x = 1;" >"$WORK/conv/project/node_modules/Bad_Lib/BadName.ts"

conventions_checks() {
    local label="$1" project="$2" plain="$3"
    expect_contains "$label counts source files and skips node_modules" "$project" "FILES_SCANNED: 12"
    expect_contains "$label reports naming per extension" "$project" "  .tsx: PascalCase 4, kebab-case 1"
    expect_contains "$label picks the dominant multi-word style" "$project" "DOMINANT_FILE_NAMING: .ts=kebab-case .tsx=PascalCase"
    expect_contains "$label reports folder naming" "$project" "DOMINANT_DIR_NAMING: kebab-case"
    expect_contains "$label reports role suffixes" "$project" "ROLE_SUFFIXES: .service 2, .types 1"
    expect_contains "$label reports test layout" "$project" "TEST_LAYOUT: colocated 1, test-dir 1"
    expect_contains "$label reports test naming" "$project" "TEST_NAMING: .test. 2"
    expect_contains "$label reports top folders" "$project" "TOP_DIRS: src 11, src/components 5, src/lib 3"
    expect_contains "$label finds formatters" "$project" "FORMATTERS: prettier editorconfig"
    expect_contains "$label reads semicolons from prettier" "$project" "SEMICOLONS: no (prettier config)"
    expect_contains "$label reads quotes from prettier" "$project" "QUOTES: single (prettier config)"
    expect_contains "$label detects two space indent" "$project" "INDENT: 2 spaces"
    expect_contains "$label reads the import alias" "$project" "IMPORT_ALIAS: @/"
    expect_contains "$label samples semicolons without config" "$plain" "SEMICOLONS: yes (4 of 4 statements)"
    expect_contains "$label samples quotes without config" "$plain" "QUOTES: double (2 of 2 imports)"
    expect_contains "$label detects four space indent" "$plain" "INDENT: 4 spaces"
    expect_contains "$label reports no formatter" "$plain" "FORMATTERS: none"
}

load_test_checks() {
    local label="$1" ok="$2" strict="$3"
    expect_contains "$label reports total requests" "$ok" "REQUESTS: 2505"
    expect_contains "$label reports average rps" "$ok" "RPS_AVG: 250.5"
    expect_contains "$label reports p50" "$ok" "LATENCY_P50_MS: 35"
    expect_contains "$label reports p99" "$ok" "LATENCY_P99_MS: 640"
    expect_contains "$label reports non-2xx responses" "$ok" "NON_2XX: 7"
    expect_contains "$label computes the error rate" "$ok" "ERROR_RATE_PCT: 0.40"
    expect_contains "$label reports no rate cap" "$ok" "RATE_CAP: none"
    expect_contains "$label passes within thresholds" "$ok" "RESULT: pass"
    expect_contains "$label fails over the p99 threshold" "$strict" "RESULT: fail"
}

echo "scope-check.sh"
scope_checks "sh" "bash $SECSCRIPTS/scope-check.sh"

echo "scope-init.sh"
scope_init_checks "sh" "bash $SECSCRIPTS/scope-init.sh" "bash $SECSCRIPTS/scope-check.sh" ""

echo "dev-detect.sh"
dev_detect_checks "sh" "bash $SECSCRIPTS/dev-detect.sh" "" ""

echo "grep-audit.sh"
AUDIT=$(bash "$SECSCRIPTS/grep-audit.sh" "$CODE_DIR" 2>&1); CODE=$?
expect_exit "exits 0 on a scan with leads" "$CODE" 0
SAFE=$(bash "$SECSCRIPTS/grep-audit.sh" "$CODE_DIR" 2>&1 | grep -c "safe.py" || true)
audit_checks "sh" "$AUDIT" "$([ "$SAFE" = "0" ] && echo "safe.py-clean" || echo "safe.py-flagged")"
OUT=$(bash "$SECSCRIPTS/grep-audit.sh" "$WORK/nope-audit" 2>&1); CODE=$?
expect_exit "fails on a missing path" "$CODE" 1
expect_contains "prints an error for a missing path" "$OUT" "ERROR:"
FPCNT=$(bash "$SECSCRIPTS/grep-audit.sh" "$BACKFIX/good" 2>&1 | grep -c "code-eval" || true)
expect_exit "sh does not flag the function keyword as code-eval" "$FPCNT" 0
REALEVAL=$(bash "$SECSCRIPTS/grep-audit.sh" "$CODE_DIR" 2>&1 | grep -c "\[code-eval\] sub/ui.js:3:" || true)
expect_exit "sh still flags real eval" "$REALEVAL" 1

echo "backend-scan.sh"
BAD=$(bash "$BACKSCRIPTS/backend-scan.sh" "$BACKFIX/bad" 2>&1); CODE=$?
expect_exit "exits 0 when it finds leads" "$CODE" 0
GOOD=$(bash "$BACKSCRIPTS/backend-scan.sh" "$BACKFIX/good" 2>&1)
VENDORED=$(bash "$BACKSCRIPTS/backend-scan.sh" "$WORK/backend-project" 2>&1)
backend_scan_checks "it" "$BAD" "$GOOD" "$VENDORED"
OUT=$(bash "$BACKSCRIPTS/backend-scan.sh" "$BACKFIX/bad/app.py" 2>&1)
expect_contains "scans a single file" "$OUT" "FINDINGS: 14"
OUT=$(bash "$BACKSCRIPTS/backend-scan.sh" "$BACKFIX/bad/app.py" "$BACKFIX/bad/orders.js" "$ROOT/README.md" 2>&1)
expect_contains "scans several paths and skips non-source files" "$OUT" "FILES_SCANNED: 2"
expect_contains "reports leads from every path" "$OUT" "FINDINGS: 31"
OUT=$(bash "$BACKSCRIPTS/backend-scan.sh" "$WORK/nope-backend" 2>&1); CODE=$?
expect_exit "fails on a missing path" "$CODE" 1
expect_contains "prints an error for a missing path" "$OUT" "ERROR:"

echo "db-lint.sh"
BAD=$(bash "$BACKSCRIPTS/db-lint.sh" "$DBFIX/bad" 2>&1); CODE=$?
expect_exit "exits 0 when it finds leads" "$CODE" 0
GOOD=$(bash "$BACKSCRIPTS/db-lint.sh" "$DBFIX/good" 2>&1)
db_lint_checks "it" "$BAD" "$GOOD"
OUT=$(bash "$BACKSCRIPTS/db-lint.sh" "$DBFIX/bad/002_changes.sql" 2>&1)
expect_contains "lints a single migration" "$OUT" "FINDINGS: 14"
OUT=$(bash "$BACKSCRIPTS/db-lint.sh" "$DBFIX/bad/001_init.sql" "$DBFIX/bad/002_changes.sql" 2>&1)
expect_contains "lints several paths" "$OUT" "FINDINGS: 20"
OUT=$(bash "$BACKSCRIPTS/db-lint.sh" "$WORK/nope-db" 2>&1); CODE=$?
expect_exit "fails on a missing path" "$CODE" 1
expect_contains "prints an error for a missing path" "$OUT" "ERROR:"

for skill in backend uiux; do
    echo "conventions.sh ($skill)"
    PROJECT=$(bash "$ROOT/skills/$skill/scripts/conventions.sh" "$WORK/conv/project" 2>&1); CODE=$?
    expect_exit "exits 0" "$CODE" 0
    PLAIN=$(bash "$ROOT/skills/$skill/scripts/conventions.sh" "$WORK/conv/plain" 2>&1)
    conventions_checks "it" "$PROJECT" "$PLAIN"
    OUT=$(bash "$ROOT/skills/$skill/scripts/conventions.sh" "$WORK/nope-conv" 2>&1); CODE=$?
    expect_exit "fails on a missing path" "$CODE" 1
    expect_contains "prints an error for a missing path" "$OUT" "ERROR:"
done
if cmp -s "$ROOT/skills/backend/scripts/conventions.sh" "$ROOT/skills/uiux/scripts/conventions.sh" && cmp -s "$ROOT/skills/backend/scripts/conventions.ps1" "$ROOT/skills/uiux/scripts/conventions.ps1"; then
    pass "backend and uiux ship the same conventions scripts"
else
    fail "backend and uiux conventions scripts differ"
fi

echo "load-test.sh"
OK=$(PATH="$FAKES:$PATH" bash "$BACKSCRIPTS/load-test.sh" "http://127.0.0.1:$PORT/" -d 5 -c 4 -H "Authorization: Bearer test" -o "$WORK/load" 2>&1); CODE=$?
expect_exit "succeeds against a local host" "$CODE" 0
STRICT=$(PATH="$FAKES:$PATH" bash "$BACKSCRIPTS/load-test.sh" "http://localhost:$PORT/" --p99 500 -o "$WORK/load" 2>&1)
load_test_checks "it" "$OK" "$STRICT"
OUT=$(PATH="$FAKES:$PATH" bash "$BACKSCRIPTS/load-test.sh" "https://example.com/" -o "$WORK/load" 2>&1); CODE=$?
expect_exit "refuses a remote host without authorization" "$CODE" 2
expect_contains "explains the authorization requirement" "$OUT" "needs the owner's authorization"
PATH="$FAKES:$PATH" bash "$BACKSCRIPTS/load-test.sh" "https://example.com/" --authorized -o "$WORK/load" >/dev/null 2>&1; CODE=$?
expect_exit "requires a rate cap for a remote host" "$CODE" 1
OUT=$(PATH="$FAKES:$PATH" bash "$BACKSCRIPTS/load-test.sh" "https://example.com/" --authorized -r 10 -o "$WORK/load" 2>&1); CODE=$?
expect_exit "runs an authorized remote host with a rate cap" "$CODE" 0
expect_contains "reports the remote scope" "$OUT" "SCOPE: remote (authorized)"
PATH="$FAKES:$PATH" bash "$BACKSCRIPTS/load-test.sh" "http://localhost/" -c 5000 >/dev/null 2>&1; CODE=$?
expect_exit "rejects too many connections" "$CODE" 1
OUT=$(PATH="$FAKES:$PATH" FAKE_NPX_MODE=fail bash "$BACKSCRIPTS/load-test.sh" "http://localhost/" -o "$WORK/load" 2>&1); CODE=$?
expect_exit "fails when autocannon fails" "$CODE" 1
expect_contains "prints an error when autocannon fails" "$OUT" "ERROR: load test failed"

if [ -n "$POWERSHELL" ]; then
    echo "perf-check.ps1"
    OUT=$(run_ps "$SCRIPTS/perf-check.ps1" -Url "$BASE/" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "succeeds on a live page" "$CODE" 0
    expect_contains "reports status" "$OUT" "HTTP_STATUS: 200"
    expect_contains "detects gzip when the client asks for it" "$OUT" "COMPRESSION: enabled (gzip)"
    expect_contains "reports cache-control" "$OUT" "CACHE_CONTROL: max-age=3600"
    expect_matches "reports TTFB in whole milliseconds" "$OUT" "^TTFB_MS: [0-9]+$"
    OUT=$(run_ps "$SCRIPTS/perf-check.ps1" -Url "$BASE/plain" 2>&1 | tr -d '\r')
    expect_contains "reports missing compression" "$OUT" "COMPRESSION: disabled"
    expect_contains "reports missing cache-control" "$OUT" "CACHE_CONTROL: missing"
    OUT=$(run_ps "$SCRIPTS/perf-check.ps1" -Url "$BASE/redirect" 2>&1 | tr -d '\r')
    expect_contains "follows and counts redirects" "$OUT" "REDIRECTS: 1"
    expect_contains "reports the final URL" "$OUT" "FINAL_URL: $BASE/"
    OUT=$(run_ps "$SCRIPTS/perf-check.ps1" -Url "$DEAD" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "fails on an unreachable URL" "$CODE" 1
    expect_contains "prints an error for an unreachable URL" "$OUT" "ERROR: request to $DEAD failed."

    echo "axe-scan.ps1"
    OUT=$(PATH="$FAKES:$PATH" FAKE_NPX_MODE=ok run_ps "$SCRIPTS/axe-scan.ps1" -Url "$BASE/" -OutputDir "$WORK/axe-ps" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "succeeds when axe writes results" "$CODE" 0
    expect_contains "counts violated rules" "$OUT" "VIOLATIONS: 2"
    expect_contains "counts affected nodes" "$OUT" "VIOLATION_NODES: 5"
    expect_contains "counts passes" "$OUT" "PASSES: 3"
    expect_matches "lists the most frequent violation first" "$(printf '%s\n' "$OUT" | grep -A1 'TOP VIOLATIONS:')" "\[serious\] color-contrast: .* \(3 instances\)"
    OUT=$(PATH="$FAKES:$PATH" FAKE_NPX_MODE=fail run_ps "$SCRIPTS/axe-scan.ps1" -Url "$BASE/" -OutputDir "$WORK/axe-ps-fail" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "fails when axe fails" "$CODE" 1
    expect_contains "prints an error when axe fails" "$OUT" "ERROR: axe scan failed."

    echo "lighthouse-audit.ps1"
    OUT=$(PATH="$FAKES:$PATH" FAKE_NPX_MODE=ok run_ps "$SCRIPTS/lighthouse-audit.ps1" -Url "$BASE/" -OutputDir "$WORK/lh-ps" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "succeeds when lighthouse writes a report" "$CODE" 0
    expect_contains "rounds category scores" "$OUT" "performance: 87"
    expect_contains "reports a perfect score" "$OUT" "best-practices: 100"
    expect_contains "reports a null score as n/a" "$OUT" "seo: n/a"
    expect_contains "reports key metrics" "$OUT" "largest-contentful-paint: 2.1 s"
    OUT=$(PATH="$FAKES:$PATH" FAKE_NPX_MODE=fail-after-write run_ps "$SCRIPTS/lighthouse-audit.ps1" -Url "$BASE/" -OutputDir "$WORK/lh-ps-warn" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "keeps a report written before a non-zero exit" "$CODE" 0
    expect_contains "warns about the non-zero exit" "$OUT" "WARNING: Lighthouse exited with 1"
    OUT=$(PATH="$FAKES:$PATH" FAKE_NPX_MODE=fail run_ps "$SCRIPTS/lighthouse-audit.ps1" -Url "$BASE/" -OutputDir "$WORK/lh-ps-fail" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "fails when no report is written" "$CODE" 1
    expect_contains "prints an error when no report is written" "$OUT" "ERROR: Lighthouse audit failed"
    echo "rule-scan.ps1"
    BAD=$(run_ps "$SCRIPTS/rule-scan.ps1" -Path "$RULES/bad" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "exits 0 when it finds violations" "$CODE" 0
    GOOD=$(run_ps "$SCRIPTS/rule-scan.ps1" -Path "$RULES/good" 2>&1 | tr -d '\r')
    VENDORED=$(run_ps "$SCRIPTS/rule-scan.ps1" -Path "$WORK/rules-project" 2>&1 | tr -d '\r')
    rule_scan_checks "it" "$BAD" "$GOOD" "$VENDORED"
    OUT=$(run_ps "$SCRIPTS/rule-scan.ps1" -Path "$RULES/bad/strings.json" 2>&1 | tr -d '\r')
    expect_contains "scans a single file" "$OUT" "R9 semicolon-in-copy strings.json:2:"
    OUT=$(run_ps "$SCRIPTS/rule-scan.ps1" -Path "$WORK/rules-big" 2>&1 | tr -d '\r')
    expect_contains "flags components over 300 lines" "$OUT" "R13 large-component Huge.tsx:1: 320 lines"
    OUT=$(run_ps "$SCRIPTS/rule-scan.ps1" -Path "$WORK/missing" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "fails on a missing path" "$CODE" 1
    expect_contains "prints an error for a missing path" "$OUT" "ERROR:"
    echo "scope-check.ps1"
    scope_checks "ps1" "run_ps $SECSCRIPTS/scope-check.ps1 -ScopeFile"

    echo "scope-init.ps1"
    scope_init_checks "ps1" "run_ps $SECSCRIPTS/scope-init.ps1 -Target" "run_ps $SECSCRIPTS/scope-check.ps1 -ScopeFile" "-OutputDir"

    echo "dev-detect.ps1"
    dev_detect_checks "ps1" "run_ps $SECSCRIPTS/dev-detect.ps1" "-Path" "-Ports"

    echo "grep-audit.ps1"
    AUDIT=$(run_ps "$SECSCRIPTS/grep-audit.ps1" -Path "$CODE_DIR" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "exits 0 on a scan with leads" "$CODE" 0
    SAFE=$(run_ps "$SECSCRIPTS/grep-audit.ps1" -Path "$CODE_DIR" 2>&1 | tr -d '\r' | grep -c "safe.py" || true)
    audit_checks "ps1" "$AUDIT" "$([ "$SAFE" = "0" ] && echo "safe.py-clean" || echo "safe.py-flagged")"
    OUT=$(run_ps "$SECSCRIPTS/grep-audit.ps1" -Path "$WORK/nope-audit" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "fails on a missing path" "$CODE" 1
    expect_contains "prints an error for a missing path" "$OUT" "ERROR:"
    FPCNT=$(run_ps "$SECSCRIPTS/grep-audit.ps1" -Path "$BACKFIX/good" 2>&1 | tr -d '\r' | grep -c "code-eval" || true)
    expect_exit "ps1 does not flag the function keyword as code-eval" "$FPCNT" 0
    REALEVAL=$(run_ps "$SECSCRIPTS/grep-audit.ps1" -Path "$CODE_DIR" 2>&1 | tr -d '\r' | grep -c "\[code-eval\] sub/ui.js:3:" || true)
    expect_exit "ps1 still flags real eval" "$REALEVAL" 1

    echo "backend-scan.ps1"
    BAD=$(run_ps "$BACKSCRIPTS/backend-scan.ps1" -Path "$BACKFIX/bad" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "exits 0 when it finds leads" "$CODE" 0
    GOOD=$(run_ps "$BACKSCRIPTS/backend-scan.ps1" -Path "$BACKFIX/good" 2>&1 | tr -d '\r')
    VENDORED=$(run_ps "$BACKSCRIPTS/backend-scan.ps1" -Path "$WORK/backend-project" 2>&1 | tr -d '\r')
    backend_scan_checks "it" "$BAD" "$GOOD" "$VENDORED"
    OUT=$(run_ps "$BACKSCRIPTS/backend-scan.ps1" -Path "$BACKFIX/bad/app.py" 2>&1 | tr -d '\r')
    expect_contains "scans a single file" "$OUT" "FINDINGS: 14"
    OUT=$(run_ps "$BACKSCRIPTS/backend-scan.ps1" "$BACKFIX/bad/app.py" "$BACKFIX/bad/orders.js" "$ROOT/README.md" 2>&1 | tr -d '\r')
    expect_contains "scans several paths and skips non-source files" "$OUT" "FILES_SCANNED: 2"
    expect_contains "reports leads from every path" "$OUT" "FINDINGS: 31"
    OUT=$(run_ps "$BACKSCRIPTS/backend-scan.ps1" -Path "$WORK/nope-backend" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "fails on a missing path" "$CODE" 1
    expect_contains "prints an error for a missing path" "$OUT" "ERROR:"

    echo "db-lint.ps1"
    BAD=$(run_ps "$BACKSCRIPTS/db-lint.ps1" -Path "$DBFIX/bad" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "exits 0 when it finds leads" "$CODE" 0
    GOOD=$(run_ps "$BACKSCRIPTS/db-lint.ps1" -Path "$DBFIX/good" 2>&1 | tr -d '\r')
    db_lint_checks "it" "$BAD" "$GOOD"
    OUT=$(run_ps "$BACKSCRIPTS/db-lint.ps1" -Path "$DBFIX/bad/002_changes.sql" 2>&1 | tr -d '\r')
    expect_contains "lints a single migration" "$OUT" "FINDINGS: 14"
    OUT=$(run_ps "$BACKSCRIPTS/db-lint.ps1" "$DBFIX/bad/001_init.sql" "$DBFIX/bad/002_changes.sql" 2>&1 | tr -d '\r')
    expect_contains "lints several paths" "$OUT" "FINDINGS: 20"
    OUT=$(run_ps "$BACKSCRIPTS/db-lint.ps1" -Path "$WORK/nope-db" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "fails on a missing path" "$CODE" 1
    expect_contains "prints an error for a missing path" "$OUT" "ERROR:"

    for skill in backend uiux; do
        echo "conventions.ps1 ($skill)"
        PROJECT=$(run_ps "$ROOT/skills/$skill/scripts/conventions.ps1" -Path "$WORK/conv/project" 2>&1 | tr -d '\r'); CODE=$?
        expect_exit "exits 0" "$CODE" 0
        PLAIN=$(run_ps "$ROOT/skills/$skill/scripts/conventions.ps1" -Path "$WORK/conv/plain" 2>&1 | tr -d '\r')
        conventions_checks "it" "$PROJECT" "$PLAIN"
        OUT=$(run_ps "$ROOT/skills/$skill/scripts/conventions.ps1" -Path "$WORK/nope-conv" 2>&1 | tr -d '\r'); CODE=$?
        expect_exit "fails on a missing path" "$CODE" 1
        expect_contains "prints an error for a missing path" "$OUT" "ERROR:"
    done

    echo "load-test.ps1"
    OK=$(PATH="$FAKES:$PATH" run_ps "$BACKSCRIPTS/load-test.ps1" -Url "http://127.0.0.1:$PORT/" -Duration 5 -Connections 4 -Header "Authorization: Bearer test" -OutputDir "$WORK/load-ps" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "succeeds against a local host" "$CODE" 0
    STRICT=$(PATH="$FAKES:$PATH" run_ps "$BACKSCRIPTS/load-test.ps1" -Url "http://localhost:$PORT/" -P99 500 -OutputDir "$WORK/load-ps" 2>&1 | tr -d '\r')
    load_test_checks "it" "$OK" "$STRICT"
    OUT=$(PATH="$FAKES:$PATH" run_ps "$BACKSCRIPTS/load-test.ps1" -Url "https://example.com/" -OutputDir "$WORK/load-ps" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "refuses a remote host without authorization" "$CODE" 2
    expect_contains "explains the authorization requirement" "$OUT" "needs the owner's authorization"
    PATH="$FAKES:$PATH" run_ps "$BACKSCRIPTS/load-test.ps1" -Url "https://example.com/" -Authorized -OutputDir "$WORK/load-ps" >/dev/null 2>&1; CODE=$?
    expect_exit "requires a rate cap for a remote host" "$CODE" 1
    OUT=$(PATH="$FAKES:$PATH" run_ps "$BACKSCRIPTS/load-test.ps1" -Url "https://example.com/" -Authorized -Rate 10 -OutputDir "$WORK/load-ps" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "runs an authorized remote host with a rate cap" "$CODE" 0
    expect_contains "reports the remote scope" "$OUT" "SCOPE: remote (authorized)"
    PATH="$FAKES:$PATH" run_ps "$BACKSCRIPTS/load-test.ps1" -Url "http://localhost/" -Connections 5000 >/dev/null 2>&1; CODE=$?
    expect_exit "rejects too many connections" "$CODE" 1
    OUT=$(PATH="$FAKES:$PATH" FAKE_NPX_MODE=fail run_ps "$BACKSCRIPTS/load-test.ps1" -Url "http://localhost/" -OutputDir "$WORK/load-ps" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "fails when autocannon fails" "$CODE" 1
    expect_contains "prints an error when autocannon fails" "$OUT" "ERROR: load test failed"
else
    echo "PowerShell not found, skipping .ps1 tests"
fi

echo ""
echo "$PASSED passed, $FAILED failed"
[ "$FAILED" -eq 0 ]
