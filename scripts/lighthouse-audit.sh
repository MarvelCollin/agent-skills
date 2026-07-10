#!/bin/bash
set -euo pipefail

URL="${1:?Usage: lighthouse-audit.sh <url> [output-dir]}"
OUTPUT_DIR="${2:-.}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_PATH="${OUTPUT_DIR}/lighthouse_${TIMESTAMP}"

if ! command -v npx &>/dev/null; then
    echo "ERROR: npx not found. Install Node.js first."
    exit 1
fi

npx lighthouse "$URL" \
    --output=json \
    --output=html \
    --output-path="$REPORT_PATH" \
    --chrome-flags="--headless --no-sandbox" \
    --only-categories=performance,accessibility,best-practices,seo \
    --quiet

if [ $? -eq 0 ]; then
    echo "LIGHTHOUSE_JSON=${REPORT_PATH}.report.json"
    echo "LIGHTHOUSE_HTML=${REPORT_PATH}.report.html"

    if command -v jq &>/dev/null; then
        echo ""
        echo "SCORES:"
        jq -r '.categories | to_entries[] | "\(.key): \(.value.score * 100)"' "${REPORT_PATH}.report.json"
    fi
else
    echo "ERROR: Lighthouse audit failed"
    exit 1
fi
