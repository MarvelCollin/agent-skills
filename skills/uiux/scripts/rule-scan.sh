#!/bin/bash
set -euo pipefail

TARGET="${1:?Usage: rule-scan.sh <path>}"

if command -v cygpath &>/dev/null; then
    TARGET="$(cygpath -u "$TARGET")"
fi

if [ ! -e "$TARGET" ]; then
    echo "ERROR: $TARGET does not exist." >&2
    exit 1
fi

if [ -d "$TARGET" ]; then
    ROOT="${TARGET%/}"
else
    ROOT="$(dirname "$TARGET")"
fi

FILES=()
JSON_FILES=()
while IFS= read -r -d '' file; do
    case "$file" in
        *.json) JSON_FILES+=("$file") ;;
        *) FILES+=("$file") ;;
    esac
done < <(find "$TARGET" \
    \( -type d \( -name node_modules -o -name .git -o -name dist -o -name build -o -name .next -o -name .nuxt \
        -o -name .svelte-kit -o -name out -o -name coverage -o -name vendor -o -name .turbo -o -name .cache \) -prune \) \
    -o \( -type f \( -name '*.html' -o -name '*.htm' -o -name '*.jsx' -o -name '*.tsx' -o -name '*.js' -o -name '*.ts' \
        -o -name '*.vue' -o -name '*.svelte' -o -name '*.astro' -o -name '*.css' -o -name '*.scss' -o -name '*.sass' \
        -o -name '*.less' -o -name '*.json' \) ! -name '*.min.*' ! -name 'package.json' ! -name 'package-lock.json' \
        ! -name 'tsconfig*.json' -print0 \))

RESULTS="$(mktemp)"
trap 'rm -f "$RESULTS"' EXIT

Q="[\"']"
HUES="red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose"
SATURATED_HEX="3b82f6|2563eb|1d4ed8|22c55e|16a34a|15803d|a855f7|9333ea|7e22ce|f97316|ea580c|c2410c|f59e0b|d97706|8b5cf6|7c3aed|6366f1|4f46e5|10b981|059669|ef4444|dc2626|ec4899|db2777|06b6d4|0891b2|14b8a6|0d9488|eab308|84cc16|f43f5e|0ea5e9|0284c7"
TABLE_PATTERN="<table([[:space:]>]|$)|<Table([[:space:]>]|$)|<DataTable|useReactTable|createColumnHelper"
COLUMN_FILTER_PATTERN="column-filter|columnFilter|ColumnFilter|setFilterValue|getColumnFilter|filterFn"
PAGINATION_PATTERN="paginat|pageSize|page_size|per_page|perPage|[?&]page=|offset|cursor|hasNextPage|nextPage|loadMore|useInfiniteQuery|limit="
OVERFLOW_PATTERN="overflow(-[xy])?-(auto|scroll)([^a-z-]|$)|overflow(-[xy])?[[:space:]]*:[[:space:]]*(auto|scroll)"
CUSTOM_SCROLLBAR_PATTERN="scrollbar-width|scrollbar-color|::-webkit-scrollbar|ScrollArea|scroll-area|OverlayScrollbars|simplebar"

report() {
    local rule="$1" check="$2" match file rest line text
    while IFS= read -r match; do
        file="${match%%:*}"
        rest="${match#*:}"
        line="${rest%%:*}"
        text="$(printf '%s' "${rest#*:}" | tr -d '\r' | sed 's/^[[:space:]]*//' | cut -c1-120)"
        printf '%s %s %s:%s: %s\n' "$rule" "$check" "${file#"$ROOT"/}" "$line" "$text" >>"$RESULTS"
    done
}

scan() {
    if [ "${#FILES[@]}" -gt 0 ]; then
        grep -nHE "$@" "${FILES[@]}" 2>/dev/null || true
    fi
}

scan_insensitive() {
    if [ "${#FILES[@]}" -gt 0 ]; then
        grep -inHE "$@" "${FILES[@]}" 2>/dev/null || true
    fi
}

scan_json() {
    if [ "${#JSON_FILES[@]}" -gt 0 ]; then
        grep -nHE "$@" "${JSON_FILES[@]}" 2>/dev/null || true
    fi
}

scan "(^|[^a-z0-9-])(bg|from|via|to|fill)-($HUES)-(500|600|700)([^0-9]|$)" | report R1 saturated-fill
scan_insensitive "(background(-color)?|fill)[[:space:]]*:[[:space:]]*#($SATURATED_HEX)([^0-9a-f]|$)|bg-\[#($SATURATED_HEX)\]" | report R1 saturated-fill

scan "rounded" \
    | { grep -E "(^|[^a-z-])(size|w|h)-(6|7|8|9|10|11|12|14|16)([^0-9]|$)" || true; } \
    | { grep -E "bg-[a-z]+-(50|100|200|300|400|500|600|700)([^0-9]|$)" || true; } \
    | { grep -E "place-items-center|justify-center|items-center" || true; } \
    | report R3 icon-tile

scan "rounded-full" \
    | { grep -E "(^|[^a-z-])px-(1|1\.5|2|2\.5|3)([^0-9.]|$)" || true; } \
    | { grep -E "text-(xs|\[1[0-2]px\])" || true; } \
    | report R4 pill-badge
scan "<(Badge|Chip|Pill)([[:space:]>/]|$)" | report R4 pill-badge
scan_insensitive "(class|className)=.*(${Q}|[[:space:]])(badge|pill|chip)(${Q}|[[:space:]])" | report R4 pill-badge
scan_insensitive "border-radius[[:space:]]*:[[:space:]]*(9999|999)px" | report R4 pill-badge

for file in "${FILES[@]+"${FILES[@]}"}"; do
    if grep -qE "$TABLE_PATTERN" "$file" && ! grep -qE "$COLUMN_FILTER_PATTERN" "$file"; then
        grep -nHE -m1 "$TABLE_PATTERN" "$file" | report R5 table-without-column-filters
    fi
    if grep -qE "$TABLE_PATTERN" "$file" && ! grep -qiE "$PAGINATION_PATTERN" "$file"; then
        grep -nHE -m1 "$TABLE_PATTERN" "$file" | report R10 table-without-pagination
    fi
done

scan_insensitive "modal|dialog|drawer|sheet|popover" \
    | { grep -E "(^|[^a-z-])(w|h)-\[[0-9]+px\]|(^|[^a-z-])(width|height)[[:space:]]*:[[:space:]]*[0-9]+px" || true; } \
    | report R6 fixed-size-overlay

scan "type=${Q}(date|datetime-local|time|month|week|range|color)${Q}" | report R7 native-control
scan "<(select|datalist)([[:space:]>]|$)" | report R7 native-control
scan "type=${Q}(checkbox|radio|file)${Q}" \
    | { grep -vE "sr-only|appearance-none|appearance:[[:space:]]*none|opacity-0|visually-hidden|[[:space:]]hidden" || true; } \
    | report R7 native-control
scan "(^|[^.a-zA-Z0-9_])(alert|confirm|prompt)\(" | report R7 browser-dialog

HAS_CUSTOM_SCROLLBAR=0
if [ "${#FILES[@]}" -gt 0 ] && grep -qE "$CUSTOM_SCROLLBAR_PATTERN" "${FILES[@]}" 2>/dev/null; then
    HAS_CUSTOM_SCROLLBAR=1
fi
if [ "$HAS_CUSTOM_SCROLLBAR" -eq 0 ]; then
    for file in "${FILES[@]+"${FILES[@]}"}"; do
        { grep -nHE -m1 "$OVERFLOW_PATTERN" "$file" || true; } | report R7 default-scrollbar
    done
fi

scan_insensitive "getInitials|(^|[^a-z])initials([^a-z]|$)|charAt\(0\)|(slice|substring|substr)\(0,[[:space:]]*[12]\)[[:space:]]*\.toUpperCase" | report R11 initials-avatar

for file in "${FILES[@]+"${FILES[@]}"}"; do
    case "$file" in
        *.tsx|*.jsx|*.vue|*.svelte) ;;
        *) continue ;;
    esac
    { grep -nHE "^[[:space:]]*(export[[:space:]]+)?(interface|type)[[:space:]]+[A-Z][A-Za-z0-9_]*" "$file" || true; } | report R13 inline-types
    { grep -nHE "(^|[^A-Za-z0-9_.])fetch\(|axios(\.(get|post|put|patch|delete|request))?\(" "$file" || true; } | report R13 fetch-in-component
    lines="$(wc -l <"$file" | tr -d ' ')"
    if [ "$lines" -gt 300 ]; then
        printf '%s:1:%s lines, split it into smaller components\n' "$file" "$lines" | report R13 large-component
    fi
done

scan "—|&mdash;|&#8212;" | report R9 em-dash
scan_json "—" | report R9 em-dash
scan "[A-Za-z0-9\"'/]>[^<>{}]*[A-Za-z0-9)][[:space:]]*;[[:space:]]+[A-Za-z][^<>{}]*<" | report R9 semicolon-in-copy
scan_json ":[[:space:]]*\"[^\"]*[A-Za-z0-9)];[[:space:]]+[A-Za-z][^\"]*\"" | report R9 semicolon-in-copy

echo "RULE SCAN: $TARGET"
echo "FILES_SCANNED: $(( ${#FILES[@]} + ${#JSON_FILES[@]} ))"
echo ""
sort "$RESULTS"
echo ""
echo "FINDINGS: $(wc -l <"$RESULTS" | tr -d ' ')"
for rule in R1 R3 R4 R5 R6 R7 R9 R10 R11 R13; do
    echo "$rule: $(grep -c "^$rule " "$RESULTS" || true)"
done
