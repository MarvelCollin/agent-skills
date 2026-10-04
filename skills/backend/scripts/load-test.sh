#!/bin/bash
set -euo pipefail

usage() {
    echo "Usage: load-test.sh <url> [-d seconds] [-c connections] [-r rate] [-m method] [-H 'Name: value'] [-b body] [-o dir] [--p99 ms] [--max-errors pct] [--authorized]" >&2
}

fail() {
    echo "ERROR: $1" >&2
    exit "${2:-1}"
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

URL="$1"
shift
DURATION=30
CONNECTIONS=10
RATE=0
METHOD="GET"
BODY=""
OUTPUT_DIR="load-results"
P99_MS=1000
MAX_ERROR_PCT=1
AUTHORIZED=0
HEADERS=()

while [ $# -gt 0 ]; do
    case "$1" in
        -d) DURATION="${2:-}"; shift 2 ;;
        -c) CONNECTIONS="${2:-}"; shift 2 ;;
        -r) RATE="${2:-}"; shift 2 ;;
        -m) METHOD="${2:-}"; shift 2 ;;
        -H) HEADERS+=("${2:-}"); shift 2 ;;
        -b) BODY="${2:-}"; shift 2 ;;
        -o) OUTPUT_DIR="${2:-}"; shift 2 ;;
        --p99) P99_MS="${2:-}"; shift 2 ;;
        --max-errors) MAX_ERROR_PCT="${2:-}"; shift 2 ;;
        --authorized) AUTHORIZED=1; shift ;;
        *) usage; fail "unknown option $1" ;;
    esac
done

is_int() {
    case "$1" in
        ''|*[!0-9]*) return 1 ;;
        *) return 0 ;;
    esac
}

is_number() {
    printf '%s' "$1" | grep -qE '^[0-9]+([.][0-9]+)?$'
}

is_int "$DURATION" && [ "$DURATION" -ge 1 ] && [ "$DURATION" -le 3600 ] || fail "duration must be a whole number of seconds from 1 to 3600."
is_int "$CONNECTIONS" && [ "$CONNECTIONS" -ge 1 ] && [ "$CONNECTIONS" -le 1000 ] || fail "connections must be a whole number from 1 to 1000."
is_int "$RATE" || fail "rate must be a whole number of requests per second."
is_number "$P99_MS" || fail "--p99 must be a number of milliseconds."
is_number "$MAX_ERROR_PCT" || fail "--max-errors must be a percentage."

case "$URL" in
    http://*|https://*) ;;
    *) fail "url must start with http:// or https://." ;;
esac

host="${URL#*://}"
host="${host%%/*}"
host="${host%%\?*}"
host="${host##*@}"
case "$host" in
    \[*) host="${host#\[}"; host="${host%%\]*}" ;;
    *) host="${host%%:*}" ;;
esac
host="$(printf '%s' "$host" | tr '[:upper:]' '[:lower:]')"

is_local() {
    case "$1" in
        localhost|*.localhost|*.test|*.local|::1|0.0.0.0|host.docker.internal) return 0 ;;
        127.*|10.*|192.168.*) return 0 ;;
        172.1[6-9].*|172.2[0-9].*|172.3[0-1].*) return 0 ;;
        *) return 1 ;;
    esac
}

SCOPE="local"
if ! is_local "$host"; then
    if [ "$AUTHORIZED" -ne 1 ]; then
        fail "$host is not a local or private host. Load testing it needs the owner's authorization. Confirm it with the user, record it, then pass --authorized with a rate cap (-r)." 2
    fi
    if [ "$RATE" -le 0 ]; then
        fail "a remote target needs a rate cap. Pass -r <requests per second>."
    fi
    SCOPE="remote (authorized)"
fi

for tool in npx node; do
    if ! command -v "$tool" &>/dev/null; then
        fail "$tool not found. Install Node.js first."
    fi
done

mkdir -p "$OUTPUT_DIR"
RESULTS_JSON="$OUTPUT_DIR/autocannon_$(date +%Y%m%d_%H%M%S).json"

ARGS=(--yes autocannon -j -c "$CONNECTIONS" -d "$DURATION" -m "$METHOD")
if [ "$RATE" -gt 0 ]; then
    ARGS+=(-R "$RATE")
fi
for header in "${HEADERS[@]+"${HEADERS[@]}"}"; do
    name="${header%%:*}"
    value="${header#*:}"
    value="${value# }"
    ARGS+=(-H "$name=$value")
done
if [ -n "$BODY" ]; then
    ARGS+=(-b "$BODY")
fi
ARGS+=("$URL")

STATUS=0
npx "${ARGS[@]}" >"$RESULTS_JSON" || STATUS=$?

if [ "$STATUS" -ne 0 ] || [ ! -s "$RESULTS_JSON" ]; then
    fail "load test failed (exit $STATUS). Check that the service is up and Node.js can run autocannon."
fi

echo "LOAD_TEST: $URL"
echo "SCOPE: $SCOPE"
echo "RESULTS_JSON: $RESULTS_JSON"
echo "CONNECTIONS: $CONNECTIONS"
echo "DURATION_S: $DURATION"
if [ "$RATE" -gt 0 ]; then
    echo "RATE_CAP: $RATE"
else
    echo "RATE_CAP: none"
fi

node - "$RESULTS_JSON" "$P99_MS" "$MAX_ERROR_PCT" <<'EOF'
const fs = require("fs")
const [file, p99Limit, errorLimit] = process.argv.slice(2)
const lines = fs.readFileSync(file, "utf8").split(/\r?\n/).filter((l) => l.trim().startsWith("{"))
if (lines.length === 0) {
    console.error("ERROR: no JSON result in " + file)
    process.exit(1)
}
const r = JSON.parse(lines[lines.length - 1])
const latency = r.latency || {}
const requests = r.requests || {}
const errors = Number(r.errors || 0)
const timeouts = Number(r.timeouts || 0)
const non2xx = Number(r.non2xx || 0)
const total = Number(requests.total || 0)
const attempted = Math.max(Number(requests.sent || 0), total + errors + timeouts, 1)
const errorPct = ((errors + timeouts + non2xx) / attempted) * 100
const ms = (v) => String(Math.round(Number(v || 0)))
const p99 = Number(latency.p99 || 0)
const pass = p99 <= Number(p99Limit) && errorPct <= Number(errorLimit)
console.log("REQUESTS: " + total)
console.log("RPS_AVG: " + Number(requests.average || 0).toFixed(1))
console.log("LATENCY_P50_MS: " + ms(latency.p50))
console.log("LATENCY_P90_MS: " + ms(latency.p90))
console.log("LATENCY_P99_MS: " + ms(latency.p99))
console.log("LATENCY_MAX_MS: " + ms(latency.max))
console.log("ERRORS: " + errors)
console.log("TIMEOUTS: " + timeouts)
console.log("NON_2XX: " + non2xx)
console.log("ERROR_RATE_PCT: " + errorPct.toFixed(2))
console.log("THRESHOLD_P99_MS: " + p99Limit)
console.log("THRESHOLD_ERROR_PCT: " + errorLimit)
console.log("RESULT: " + (pass ? "pass" : "fail"))
EOF
