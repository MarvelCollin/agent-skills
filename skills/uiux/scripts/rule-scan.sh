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

scan_insensitive "#(39ff14|00ffff|ff00ff|ccff00|00ff00|0ff|f0f|0f0)([^0-9a-f]|$)" | report R1 neon-color
scan "(^|[^a-z0-9-])(text|bg|border|ring|shadow|from|via|to|fill|stroke)-(lime|cyan|fuchsia)-(300|400)([^0-9]|$)" | report R1 neon-color
for file in "${FILES[@]+"${FILES[@]}"}"; do
    pastel_hues="$({ grep -oE "(^|[^a-z0-9-])(bg|from|via|to)-($HUES)-(50|100|200)([^0-9]|$)" "$file" || true; } \
        | sed -E "s/^.*-($HUES)-(50|100|200).*$/\1/" | sort -u | wc -l | tr -d ' ')"
    if [ "$pastel_hues" -ge 3 ]; then
        grep -nHE -m1 "(^|[^a-z0-9-])(bg|from|via|to)-($HUES)-(50|100|200)([^0-9]|$)" "$file" | report R1 pastel-rainbow
    fi
done

scan "(^|[^A-Za-z])(Sparkles|Sparkle|WandSparkles|SparklesIcon)([^A-Za-z]|$)|lucide-sparkles|✨" | report R15 sparkle-icon
scan "(radial|linear)-gradient\([^)]*[^0-9.][12]px[^)]*transparent|DotPattern|GridPattern|dot-pattern|grid-pattern" | report R15 dot-grid
scan "rounded-full" \
    | { grep -E "blur-(2xl|3xl|\[[0-9]+px\])" || true; } \
    | report R15 gradient-orb
scan_insensitive "filter[[:space:]]*:[[:space:]]*blur\(([4-9][0-9]|[1-9][0-9][0-9])px\)" | report R15 gradient-orb
scan_insensitive "backdrop-blur|backdrop-saturate|backdrop-filter[[:space:]]*:" | report R15 glass-surface
scan "hover:(-translate-y-|scale-1[0-9][0-9])|hover:shadow-(xl|2xl)" | report R15 hover-lift
scan "hover:-?translate-x-" \
    | { grep -E "Arrow|arrow|Chevron|chevron|→" || true; } \
    | report R15 animated-arrow
scan "font-family[^;]*(Inter|Geist|Space Grotesk)([^A-Za-z]|$)|(^|[^A-Za-z_])(Inter|Space_Grotesk|Geist|Geist_Mono)[[:space:]]*\(\{|[\"']geist/font|family=(Inter|Space\+Grotesk|Geist)([^A-Za-z]|$)" | report R15 default-font
if [ "${#FILES[@]}" -gt 0 ]; then
    { LC_ALL=C grep -nHF $'\xf0\x9f' "${FILES[@]}" 2>/dev/null || true; } | report R15 emoji
fi
CHECK_PATTERN="<(Check|CheckIcon|CheckCircle|CheckCircle2|CircleCheck|CircleCheckBig|BadgeCheck)[[:space:]/>]|✓|✔|✅"
for file in "${FILES[@]+"${FILES[@]}"}"; do
    checks="$(grep -cE "$CHECK_PATTERN" "$file" || true)"
    if [ "${checks:-0}" -ge 3 ]; then
        grep -nHE -m1 "$CHECK_PATTERN" "$file" | report R15 checkmark-bullets
    fi
    if { grep -qiE "#ff5f5[67]" "$file" && grep -qiE "#ffbd2e|#febc2e" "$file" && grep -qiE "#27c93f|#28c840" "$file"; } \
        || { grep -qE "rounded-full[^\"']*bg-red-(400|500)|bg-red-(400|500)[^\"']*rounded-full" "$file" \
            && grep -qE "rounded-full[^\"']*bg-(yellow|amber)-(400|500)|bg-(yellow|amber)-(400|500)[^\"']*rounded-full" "$file" \
            && grep -qE "rounded-full[^\"']*bg-(green|emerald)-(400|500)|bg-(green|emerald)-(400|500)[^\"']*rounded-full" "$file"; }; then
        grep -nHiE -m1 "#ff5f5[67]|bg-red-(400|500)" "$file" | report R15 fake-terminal
    fi
done

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

scan "<(DialogContent|SheetContent|DrawerContent|ModalContent|Modal|dialog)([[:space:]][^>]*)?(overflow(-y)?-(auto|scroll)|overflow(-y)?:[[:space:]]*(auto|scroll))" | report R14 scrolling-overlay
scan "disabled=\\{[^}]*(isValid|canSubmit|isComplete|isFormValid)" | report R14 disabled-until-valid

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

MARKUP=()
for file in "${FILES[@]+"${FILES[@]}"}"; do
    case "$file" in
        *.html|*.htm|*.jsx|*.tsx|*.vue|*.svelte|*.astro) MARKUP+=("$file") ;;
    esac
done
if [ "${#MARKUP[@]}" -gt 0 ]; then
    { grep -nHE "<(img|Image)([[:space:]][^>]*)?/?>" "${MARKUP[@]}" 2>/dev/null || true; } \
        | { grep -vE "^[^:]+:[0-9]+:.*([[:space:]:]alt[[:space:]]*=|\{\.\.\.)" || true; } \
        | report R16 img-without-alt
    { grep -inHE "lorem ipsum|(^|[^a-z0-9.-])example\.(com|org)|123 main st|555-[0-9]{4}|\(555\)|john doe|jane doe|your-?(domain|company)\.com|acme (inc|corp)" "${MARKUP[@]}" 2>/dev/null || true; } \
        | report R16 placeholder-copy
fi
for file in "${MARKUP[@]+"${MARKUP[@]}"}"; do
    case "$file" in
        *.html|*.htm) ;;
        *) continue ;;
    esac
    if grep -qiE "<head([[:space:]>]|$)" "$file"; then
        if ! grep -qiE "name=[\"']?viewport" "$file"; then
            { grep -inHE -m1 "<head([[:space:]>]|$)" "$file" || true; } | report R16 missing-viewport
        fi
        if ! grep -qiE "<title([[:space:]>]|$)" "$file"; then
            { grep -inHE -m1 "<head([[:space:]>]|$)" "$file" || true; } | report R16 missing-title
        fi
        if ! grep -qiE "name=[\"']?description" "$file"; then
            { grep -inHE -m1 "<head([[:space:]>]|$)" "$file" || true; } | report R16 missing-description
        fi
    fi
    if grep -qiE "<html([[:space:]>]|$)" "$file" && ! grep -qiE "<html[^>]*[[:space:]]lang=" "$file"; then
        { grep -inHE -m1 "<html([[:space:]>]|$)" "$file" || true; } | report R16 missing-lang
    fi
done

LABEL_PATTERN="<label|<Label|<FormLabel|<FieldLabel|<legend|<Legend|aria-label|aria-labelledby|[[:space:]]label="
CONTROL_PATTERN="<(input|Input|select|Select|SelectTrigger|button|Button|DatePicker|Combobox|ComboboxInput)([[:space:]>]|$)"
HEIGHT_PATTERN="[\"'[:space:]]h-(7|8|9|10|11|12|14)([\"'[:space:]]|$)"
for file in "${MARKUP[@]+"${MARKUP[@]}"}"; do
    if grep -qE "<(input|Input|textarea|Textarea)[^>]*placeholder=" "$file" && ! grep -qE "$LABEL_PATTERN" "$file"; then
        grep -nHE -m1 "<(input|Input|textarea|Textarea)[^>]*placeholder=" "$file" | report R17 placeholder-as-label
    fi
    heights="$({ grep -E "$CONTROL_PATTERN" "$file" || true; } | { grep -oE "$HEIGHT_PATTERN" || true; } | tr -d "\"' " | sort -u | wc -l | tr -d ' ')"
    if [ "$heights" -ge 2 ]; then
        { grep -nHE "$CONTROL_PATTERN" "$file" || true; } | { grep -E "$HEIGHT_PATTERN" || true; } | head -n 1 | report R17 mixed-control-heights
    fi
    if grep -qE "<(thead|TableHeader)([[:space:]>]|$)" "$file" && ! grep -qE "sticky" "$file"; then
        grep -nHE -m1 "<(thead|TableHeader)([[:space:]>]|$)" "$file" | report R19 header-not-sticky
    fi
done

scan "(^|[\"'[:space:]])transition-all([\"'[:space:]]|$)|transition(-property)?[[:space:]]*:[[:space:]]*[\"']?all([\"'[:space:];,]|$)" | report R18 transition-all
scan "transition-\[(width|height|max-height|min-height|top|left|right|bottom|margin|padding|inset)|transition(-property)?[[:space:]]*:[[:space:]]*[\"']?[^;\"'{}]*(^|[[:space:],:\"'])(width|height|max-height|min-height|top|left|right|bottom|margin|margin-[a-z]+|padding|padding-[a-z]+)([[:space:],;\"']|$)|animate=\{\{[^}]*(width|height|top|left)[[:space:]]*:" | report R18 layout-animation
scan "(^|[\"'[:space:]:])duration-(500|700|1000|\[([5-9][0-9]{2}|[1-9][0-9]{3,})ms\]|\[[1-9](\.[0-9]+)?s\])([\"'[:space:]]|$)|(transition|animation)(-duration)?[[:space:]]*:[[:space:]]*[\"']?[^;\"'{}]*[^0-9.]([5-9][0-9]{2}|[1-9][0-9]{3,})ms|(transition|animation)(-duration)?[[:space:]]*:[[:space:]]*[\"']?[^;\"'{}]*[[:space:]](0?\.[5-9][0-9]*|[1-9](\.[0-9]+)?)s([^a-z]|$)" \
    | { grep -vE "infinite|spin|pulse|shimmer|skeleton|progress" || true; } \
    | report R18 slow-motion
scan "(^|[\"'[:space:]])animate-bounce([\"'[:space:]]|$)|cubic-bezier\([^,)]*,[[:space:]]*(-|1\.[0-9]*[1-9]|[2-9])|cubic-bezier\([^,)]*,[^,)]*,[^,)]*,[[:space:]]*(-|1\.[0-9]*[1-9]|[2-9])" | report R18 bounce
ANIM_PATTERN="@keyframes|(transition|animation)(-[a-z]+)?[[:space:]]*:|(^|[\"'[:space:]])(transition|transition-[a-z]+|animate-[a-z]+)([\"'[:space:]]|$)|framer-motion|motion/react|<motion\.|startViewTransition"
REDUCED_PATTERN="prefers-reduced-motion|motion-reduce:|motion-safe:|useReducedMotion|reducedMotion|MotionConfig"
if ! { [ "${#FILES[@]}" -gt 0 ] && grep -qE "$REDUCED_PATTERN" "${FILES[@]}" 2>/dev/null; }; then
    for file in "${FILES[@]+"${FILES[@]}"}"; do
        { grep -nHE -m1 "$ANIM_PATTERN" "$file" || true; } | report R18 missing-reduced-motion
    done
fi

ANIMATE_UTILITY_PATTERN="(^|[\"'[:space:]:])(animate-in|animate-out|fade-in-0|fade-out-0|zoom-in-95|zoom-out-95|slide-in-from-(top|bottom|left|right)(-[0-9]+)?)([\"'[:space:]]|$)"
ANIMATE_PLUGIN_PATTERN="tw-animate-css|tailwindcss-animate"
has_animate_plugin() {
    if [ "${#FILES[@]}" -gt 0 ] && grep -qE "$ANIMATE_PLUGIN_PATTERN" "${FILES[@]}" 2>/dev/null; then
        return 0
    fi
    local pkg dir
    while IFS= read -r -d '' pkg; do
        if grep -qE "$ANIMATE_PLUGIN_PATTERN" "$pkg" 2>/dev/null; then
            return 0
        fi
    done < <(find "$ROOT" \( -type d -name node_modules -prune \) -o \( -type f -name package.json -print0 \) 2>/dev/null)
    dir="$ROOT"
    for _ in 1 2 3 4; do
        dir="$(dirname "$dir")"
        if [ -f "$dir/package.json" ] && grep -qE "$ANIMATE_PLUGIN_PATTERN" "$dir/package.json" 2>/dev/null; then
            return 0
        fi
    done
    return 1
}
if ! has_animate_plugin; then
    for file in "${FILES[@]+"${FILES[@]}"}"; do
        { grep -nHE -m1 "$ANIMATE_UTILITY_PATTERN" "$file" || true; } | report R18 motion-plugin-missing
    done
fi

FIXED_WIDTH_PATTERN="(^|[\"'[:space:]])w-(64|72|80|96)([\"'[:space:]]|$)"
for file in "${MARKUP[@]+"${MARKUP[@]}"}"; do
    if grep -qE "<(input|Input|SearchInput|textarea|Textarea)([[:space:]>/]|$)" "$file"; then
        { grep -nHE "$FIXED_WIDTH_PATTERN" "$file" || true; }             | { grep -vE "(sm|md|lg|xl|2xl|@[a-z0-9]+):w-" || true; }             | report R19 fixed-width-control
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
for rule in R1 R3 R4 R5 R6 R7 R9 R10 R11 R13 R14 R15 R16 R17 R18 R19; do
    echo "$rule: $(grep -c "^$rule " "$RESULTS" || true)"
done
