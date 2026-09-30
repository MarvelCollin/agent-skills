#!/bin/bash
set -euo pipefail

URL="${1:?Usage: perf-check.sh <url>}"

if ! command -v curl &>/dev/null; then
    echo "ERROR: curl not found." >&2
    exit 1
fi

HEADERS_FILE=$(mktemp)
trap 'rm -f "$HEADERS_FILE"' EXIT

WRITE_OUT='%{http_code} %{time_connect} %{time_appconnect} %{time_starttransfer} %{time_total} %{size_download} %{num_redirects} %{url_effective}'

if ! METRICS=$(curl -sS -L --max-time 30 \
    -H "Accept-Encoding: gzip, deflate, br" \
    -o /dev/null -D "$HEADERS_FILE" -w "$WRITE_OUT" "$URL"); then
    echo "ERROR: request to $URL failed." >&2
    exit 1
fi

read -r STATUS CONNECT_S TLS_S TTFB_S TOTAL_S SIZE_BYTES REDIRECTS FINAL_URL <<<"$METRICS"

to_ms() {
    awk -v seconds="$1" 'BEGIN { printf "%d", seconds * 1000 }'
}

FINAL_HEADERS=$(tr -d '\r' <"$HEADERS_FILE" | awk '/^HTTP\// { block = "" } { block = block $0 "\n" } END { printf "%s", block }')

header_value() {
    printf '%s\n' "$FINAL_HEADERS" | grep -i "^$1:" | head -1 | cut -d: -f2- | sed 's/^ *//' || true
}

TTFB_MS=$(to_ms "$TTFB_S")
ENCODING=$(header_value "content-encoding")
CACHE_CONTROL=$(header_value "cache-control")

echo "PERFORMANCE CHECK: $URL"
echo "========================"
echo "HTTP_STATUS: $STATUS"
echo "FINAL_URL: $FINAL_URL"
echo "REDIRECTS: $REDIRECTS"
echo "CONNECT_MS: $(to_ms "$CONNECT_S")"
echo "TLS_MS: $(to_ms "$TLS_S")"
echo "TTFB_MS: $TTFB_MS"
echo "TOTAL_MS: $(to_ms "$TOTAL_S")"
echo "TRANSFER_BYTES: $SIZE_BYTES"

if [ -n "$ENCODING" ]; then
    echo "COMPRESSION: enabled ($ENCODING)"
else
    echo "COMPRESSION: disabled"
fi

if [ -n "$CACHE_CONTROL" ]; then
    echo "CACHE_CONTROL: $CACHE_CONTROL"
else
    echo "CACHE_CONTROL: missing"
fi

if [ "$TTFB_MS" -le 800 ]; then
    echo "TTFB_RATING: good"
elif [ "$TTFB_MS" -le 1800 ]; then
    echo "TTFB_RATING: needs_improvement"
else
    echo "TTFB_RATING: poor"
fi
