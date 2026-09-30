#!/bin/bash
set -euo pipefail

URL="${1:?Usage: axe-scan.sh <url> [output-dir]}"
OUTPUT_DIR="${2:-.}"
OUTPUT_NAME="axe-results.json"
OUTPUT_FILE="$OUTPUT_DIR/$OUTPUT_NAME"

for tool in npx node; do
    if ! command -v "$tool" &>/dev/null; then
        echo "ERROR: $tool not found. Install Node.js first." >&2
        exit 1
    fi
done

mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_FILE"

if ! npx --yes @axe-core/cli "$URL" --dir "$OUTPUT_DIR" --save "$OUTPUT_NAME" --no-reporter; then
    echo "ERROR: axe scan failed. Check that Chrome is installed and that chromedriver matches its version." >&2
    exit 1
fi

if [ ! -f "$OUTPUT_FILE" ]; then
    echo "ERROR: axe scan finished but $OUTPUT_FILE was not written." >&2
    exit 1
fi

echo "AXE_RESULTS: $OUTPUT_FILE"

node - "$OUTPUT_FILE" <<'EOF'
const fs = require("fs");
const parsed = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const results = Array.isArray(parsed) ? parsed : [parsed];
const violations = results.flatMap((result) => result.violations || []);
const passes = results.flatMap((result) => result.passes || []);
const affectedNodes = violations.reduce((total, rule) => total + (rule.nodes || []).length, 0);
console.log(`VIOLATIONS: ${violations.length}`);
console.log(`VIOLATION_NODES: ${affectedNodes}`);
console.log(`PASSES: ${passes.length}`);
if (violations.length > 0) {
    console.log("");
    console.log("TOP VIOLATIONS:");
    violations
        .slice()
        .sort((a, b) => (b.nodes || []).length - (a.nodes || []).length)
        .slice(0, 5)
        .forEach((rule) => {
            console.log(`  [${rule.impact}] ${rule.id}: ${rule.help} (${(rule.nodes || []).length} instances)`);
        });
}
EOF
