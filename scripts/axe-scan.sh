#!/bin/bash

URL="${1:?Usage: axe-scan.sh <url> [output-file]}"
OUTPUT="${2:-axe-results.json}"

if ! command -v npx &>/dev/null; then
    echo "ERROR: npx not found. Install Node.js first."
    exit 1
fi

npx @axe-core/cli "$URL" --save "$OUTPUT" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "AXE_RESULTS=${OUTPUT}"

    if command -v jq &>/dev/null; then
        VIOLATIONS=$(jq '[.[].violations[]] | length' "$OUTPUT")
        PASSES=$(jq '[.[].passes[]] | length' "$OUTPUT")
        echo "VIOLATIONS: ${VIOLATIONS}"
        echo "PASSES: ${PASSES}"

        if [ "$VIOLATIONS" -gt 0 ]; then
            echo ""
            echo "TOP VIOLATIONS:"
            jq -r '[.[].violations[]] | sort_by(-.nodes | length) | .[:5][] | "  [\(.impact)] \(.id): \(.help) (\(.nodes | length) instances)"' "$OUTPUT"
        fi
    fi
else
    echo "ERROR: axe scan failed"
    exit 1
fi
