#!/bin/bash
set -euo pipefail

URL="${1:?Usage: lighthouse-audit.sh <url> [output-dir]}"
OUTPUT_DIR="${2:-.}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_PATH="$OUTPUT_DIR/lighthouse_$TIMESTAMP"
JSON_REPORT="$REPORT_PATH.report.json"
HTML_REPORT="$REPORT_PATH.report.html"

for tool in npx node; do
    if ! command -v "$tool" &>/dev/null; then
        echo "ERROR: $tool not found. Install Node.js first." >&2
        exit 1
    fi
done

mkdir -p "$OUTPUT_DIR"

LIGHTHOUSE_STATUS=0
npx --yes lighthouse "$URL" \
    --output=json \
    --output=html \
    --output-path="$REPORT_PATH" \
    --chrome-flags="--headless=new --no-sandbox" \
    --only-categories=performance,accessibility,best-practices,seo \
    --quiet || LIGHTHOUSE_STATUS=$?

if [ ! -f "$JSON_REPORT" ]; then
    echo "ERROR: Lighthouse audit failed (exit $LIGHTHOUSE_STATUS). Check that Chrome is installed." >&2
    exit 1
fi

if [ "$LIGHTHOUSE_STATUS" -ne 0 ]; then
    echo "WARNING: Lighthouse exited with $LIGHTHOUSE_STATUS after writing its report." >&2
fi

echo "LIGHTHOUSE_JSON: $JSON_REPORT"
echo "LIGHTHOUSE_HTML: $HTML_REPORT"

node - "$JSON_REPORT" <<'EOF'
const fs = require("fs");
const report = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const formatScore = (score) => (typeof score === "number" ? String(Math.round(score * 100)) : "n/a");
console.log("");
console.log("SCORES:");
for (const [id, category] of Object.entries(report.categories || {})) {
    console.log(`${id}: ${formatScore(category.score)}`);
}
const metrics = ["first-contentful-paint", "largest-contentful-paint", "total-blocking-time", "cumulative-layout-shift", "speed-index"];
console.log("");
console.log("METRICS:");
for (const id of metrics) {
    const audit = (report.audits || {})[id];
    if (audit) {
        console.log(`${id}: ${audit.displayValue || "n/a"}`);
    }
}
EOF
