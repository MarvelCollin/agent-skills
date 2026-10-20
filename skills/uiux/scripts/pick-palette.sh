#!/bin/bash
set -euo pipefail

LIST="$(cd "$(dirname "$0")/.." && pwd)/references/palettes.txt"

if [ ! -f "$LIST" ]; then
    echo "ERROR: $LIST does not exist." >&2
    exit 1
fi

COUNT=$(grep -cE '^#[0-9a-f]{6} ' "$LIST" || true)
if [ "$COUNT" -eq 0 ]; then
    echo "ERROR: $LIST has no palettes." >&2
    exit 1
fi

PICK=$(( (RANDOM * 32768 + RANDOM) % COUNT + 1 ))
LINE=$(grep -E '^#[0-9a-f]{6} ' "$LIST" | sed -n "${PICK}p")

HEX=$(printf '%s' "$LINE" | cut -d'|' -f1 | sed 's/ *$//')
OKLCH=$(printf '%s' "$LINE" | cut -d'|' -f2 | sed 's/^ *//; s/ *$//')
LIKES=$(printf '%s' "$LINE" | cut -d'|' -f3 | tr -d ' ')
CODE=$(printf '%s' "$HEX" | tr -d '# ')

echo "Palette: https://colorhunt.co/palette/$CODE"
echo "Colors: $HEX"
echo "OKLCH: $OKLCH"
echo "Likes: $LIKES"
