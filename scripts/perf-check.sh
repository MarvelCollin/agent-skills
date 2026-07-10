#!/bin/bash
set -euo pipefail

URL="${1:?Usage: perf-check.sh <url>}"

if ! command -v curl &>/dev/null; then
    echo "ERROR: curl not found."
    exit 1
fi

echo "PERFORMANCE CHECK: $URL"
echo "========================"

METRICS=$(curl -sI -o /dev/null -w "HTTP_STATUS: %{http_code}\nCONNECT_MS: %{time_connect}\nTLS_MS: %{time_appconnect}\nTTFB_S: %{time_starttransfer}\nTOTAL_S: %{time_total}\nSIZE_BYTES: %{size_download}\nREDIRECTS: %{num_redirects}\nTTFB_MS: %{time_starttransfer}" -D /dev/stderr "$URL" 2>/tmp/perf_headers)

echo "$METRICS"

HEADERS=$(cat /tmp/perf_headers)
rm -f /tmp/perf_headers

if echo "$HEADERS" | grep -qi "content-encoding: gzip\|content-encoding: br"; then
    echo "COMPRESSION: enabled"
else
    echo "COMPRESSION: disabled"
fi

if echo "$HEADERS" | grep -qi "cache-control"; then
    CACHE=$(echo "$HEADERS" | grep -i "cache-control" | head -1 | tr -d '\r')
    echo "CACHE: $CACHE"
else
    echo "CACHE: no cache-control header"
fi

if echo "$HEADERS" | grep -qi "strict-transport-security"; then
    echo "HSTS: enabled"
else
    echo "HSTS: disabled"
fi

TTFB_RAW=$(echo "$METRICS" | grep "TTFB_S:" | tail -1 | awk '{print $2}')
TTFB_MS=$(echo "$TTFB_RAW" | awk '{printf "%d", $1 * 1000}')

echo ""
if [ "$TTFB_MS" -lt 200 ]; then
    echo "TTFB_RATING: excellent"
elif [ "$TTFB_MS" -lt 500 ]; then
    echo "TTFB_RATING: good"
elif [ "$TTFB_MS" -lt 1000 ]; then
    echo "TTFB_RATING: needs_improvement"
else
    echo "TTFB_RATING: poor"
fi
