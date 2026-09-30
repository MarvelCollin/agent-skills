#!/bin/bash
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$ROOT/skills/uiux/scripts"
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
    expect_contains "$label counts every finding" "$bad_output" "FINDINGS: 13"
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
OUT=$(bash "$SCRIPTS/rule-scan.sh" "$WORK/missing" 2>&1); CODE=$?
expect_exit "fails on a missing path" "$CODE" 1
expect_contains "prints an error for a missing path" "$OUT" "ERROR:"

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
    OUT=$(run_ps "$SCRIPTS/rule-scan.ps1" -Path "$WORK/missing" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "fails on a missing path" "$CODE" 1
    expect_contains "prints an error for a missing path" "$OUT" "ERROR:"
else
    echo "PowerShell not found, skipping .ps1 tests"
fi

echo ""
echo "$PASSED passed, $FAILED failed"
[ "$FAILED" -eq 0 ]
