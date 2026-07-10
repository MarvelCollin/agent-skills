#!/bin/bash

URL="${1:?Usage: perf-check.sh <url>}"

echo "PERFORMANCE CHECK: $URL"
echo "========================"

START=$(date +%s%N)
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL")
END=$(date +%s%N)
TTFB=$(( (END - START) / 1000000 ))

echo "HTTP_STATUS: ${HTTP_CODE}"
echo "TTFB_MS: ${TTFB}"

CURL_METRICS=$(curl -s -o /dev/null -w "CONNECT_MS: %{time_connect}\nTLS_MS: %{time_appconnect}\nTTFB_S: %{time_starttransfer}\nTOTAL_S: %{time_total}\nSIZE_BYTES: %{size_download}\nREDIRECTS: %{num_redirects}" "$URL")
echo "$CURL_METRICS"

HEADERS=$(curl -sI "$URL")

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

echo ""
if [ "$TTFB" -lt 200 ]; then
    echo "TTFB_RATING: excellent"
elif [ "$TTFB" -lt 500 ]; then
    echo "TTFB_RATING: good"
elif [ "$TTFB" -lt 1000 ]; then
    echo "TTFB_RATING: needs_improvement"
else
    echo "TTFB_RATING: poor"
fi
