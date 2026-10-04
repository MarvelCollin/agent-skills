#!/bin/bash
set -euo pipefail

TARGET="${1:?Usage: conventions.sh <project-or-folder>}"

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

PATHS="$(mktemp)"
REPORT="$(mktemp)"
trap 'rm -f "$PATHS" "$REPORT"' EXIT

PRUNE=( \( -type d \( -name node_modules -o -name .git -o -name dist -o -name build -o -name .next -o -name .nuxt -o -name out \
    -o -name coverage -o -name vendor -o -name .venv -o -name venv -o -name __pycache__ -o -name target -o -name bin -o -name obj \
    -o -name .turbo -o -name .cache -o -name .svelte-kit \) -prune \) -o \( -type d -path '*/storage/framework' -prune \) )

find "$ROOT" -mindepth 1 "${PRUNE[@]}" -o -type d -print | sed "s#^$ROOT/##" | LC_ALL=C sort | sed 's/^/D /' >>"$PATHS"
find "$ROOT" -mindepth 1 "${PRUNE[@]}" -o -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.mjs' -o -name '*.cjs' \
    -o -name '*.vue' -o -name '*.svelte' -o -name '*.py' -o -name '*.go' -o -name '*.rb' -o -name '*.php' -o -name '*.java' -o -name '*.kt' \
    -o -name '*.cs' -o -name '*.css' -o -name '*.scss' \) -print | sed "s#^$ROOT/##" | LC_ALL=C sort | sed 's/^/F /' >>"$PATHS"

SOURCES=()
while IFS= read -r rel; do
    SOURCES+=("$ROOT/$rel")
done < <(grep '^F ' "$PATHS" | sed 's/^F //' | grep -vE '\.(css|scss)$' | head -400 || true)

JS_SOURCES=()
for f in "${SOURCES[@]+"${SOURCES[@]}"}"; do
    case "$f" in
        *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.vue|*.svelte) JS_SOURCES+=("$f") ;;
    esac
done

echo "CONVENTIONS: $1" >"$REPORT"
LC_ALL=C awk '
function style(s) {
    if (s ~ /^[a-z0-9]+$/) return "single-word"
    if (s ~ /^[a-z][a-z0-9]*(-[a-z0-9]+)+$/) return "kebab-case"
    if (s ~ /^[a-z][a-z0-9]*(_[a-z0-9]+)+$/) return "snake_case"
    if (s ~ /^[a-z][a-z0-9]*([A-Z][a-z0-9]*)+$/) return "camelCase"
    if (s ~ /^[A-Z][A-Za-z0-9]*$/ && s ~ /[a-z]/) return "PascalCase"
    return "other"
}
function before(a, b) {
    if (cnt[a] != cnt[b]) return cnt[a] > cnt[b]
    return a < b
}
function order(keys, n,    i, j, t) {
    for (i = 2; i <= n; i++) {
        t = keys[i]
        j = i - 1
        while (j >= 1 && before(t, keys[j])) {
            keys[j + 1] = keys[j]
            j--
        }
        keys[j + 1] = t
    }
}
function listing(prefix, limit,    k, n, i, out, key, keys) {
    n = 0
    for (k in cnt) {
        if (index(k, prefix) == 1) keys[++n] = k
    }
    order(keys, n)
    out = ""
    for (i = 1; i <= n && (limit == 0 || i <= limit); i++) {
        key = substr(keys[i], length(prefix) + 1)
        out = out (out == "" ? "" : ", ") key " " cnt[keys[i]]
    }
    return out == "" ? "none" : out
}
function dominant(prefix,    k, best, name) {
    best = ""
    for (k in cnt) {
        if (index(k, prefix) != 1) continue
        name = substr(k, length(prefix) + 1)
        if (name == "single-word" || name == "other") continue
        if (best == "" || before(k, best)) best = k
    }
    if (best == "") return "none"
    return substr(best, length(prefix) + 1)
}
{
    kind = substr($0, 1, 1)
    path = substr($0, 3)
    n = split(path, seg, "/")
    name = seg[n]
    if (kind == "D") {
        cnt["dir|" style(name)]++
        next
    }
    files++
    if (name ~ /^\./) next
    stem = name
    sub(/\..*$/, "", stem)
    ext = name
    sub(/^.*\./, ".", ext)
    exts[ext] = 1
    cnt["ext|" ext]++
    cnt["file|" ext "|" style(stem)]++
    m = split(name, parts, ".")
    for (i = 2; i < m; i++) {
        if (parts[i] ~ /^(service|controller|module|repository|repo|schema|dto|types|type|model|entity|hook|hooks|store|route|routes|util|utils|config|constants|api|client|handler|middleware|guard|resolver|query|queries|mutation|component|page|layout|stories|styles)$/) cnt["role|." parts[i]]++
    }
    istest = 0
    if (name ~ /\.test\./) { istest = 1; cnt["tname|.test."]++ }
    else if (name ~ /\.spec\./) { istest = 1; cnt["tname|.spec."]++ }
    else if (name ~ /_test\.(go|py)$/) { istest = 1; cnt["tname|_test"]++ }
    else if (name ~ /^test_.*\.py$/) { istest = 1; cnt["tname|test_"]++ }
    else if (name ~ /_spec\.rb$/) { istest = 1; cnt["tname|_spec"]++ }
    else if (name ~ /Tests?\.(java|kt|cs)$/) { istest = 1; cnt["tname|Test"]++ }
    if (istest) {
        loc = "colocated"
        for (i = 1; i < n; i++) {
            if (seg[i] == "__tests__") { loc = "__tests__"; break }
            if (seg[i] ~ /^(test|tests|spec|specs)$/) { loc = "test-dir"; break }
        }
        cnt["tloc|" loc]++
    }
    if (n >= 2) cnt["top|" seg[1]]++
    if (n >= 3) cnt["top|" seg[1] "/" seg[2]]++
}
END {
    print "FILES_SCANNED: " files + 0
    print "FILE_NAMING:"
    ne = 0
    for (k in cnt) if (index(k, "ext|") == 1) ek[++ne] = k
    order(ek, ne)
    doms = ""
    for (i = 1; i <= ne; i++) {
        e = substr(ek[i], 5)
        print "  " e ": " listing("file|" e "|", 0)
        d = dominant("file|" e "|")
        if (d != "none") doms = doms (doms == "" ? "" : " ") e "=" d
    }
    if (ne == 0) print "  none"
    print "DOMINANT_FILE_NAMING: " (doms == "" ? "none" : doms)
    print "DIR_NAMING: " listing("dir|", 0)
    print "DOMINANT_DIR_NAMING: " dominant("dir|")
    print "ROLE_SUFFIXES: " listing("role|", 0)
    print "TEST_LAYOUT: " listing("tloc|", 0)
    print "TEST_NAMING: " listing("tname|", 0)
    print "TOP_DIRS: " listing("top|", 12)
}
' "$PATHS" >>"$REPORT"

FORMATTERS=()
SEMI_CONFIG=""
QUOTE_CONFIG=""
ALIASES=""
dir="$ROOT"
has() { compgen -G "$dir/$1" >/dev/null 2>&1; }
for _ in 1 2 3 4; do
    if has ".prettierrc*" || has "prettier.config.*" || { [ -f "$dir/package.json" ] && grep -q '"prettier"[[:space:]]*:' "$dir/package.json"; }; then
        FORMATTERS+=(prettier)
        for cfg in "$dir"/.prettierrc "$dir"/.prettierrc.json; do
            if [ -f "$cfg" ]; then
                if [ -z "$SEMI_CONFIG" ] && grep -qE '"semi"[[:space:]]*:[[:space:]]*false' "$cfg"; then SEMI_CONFIG="no"; fi
                if [ -z "$SEMI_CONFIG" ] && grep -qE '"semi"[[:space:]]*:[[:space:]]*true' "$cfg"; then SEMI_CONFIG="yes"; fi
                if [ -z "$QUOTE_CONFIG" ] && grep -qE '"singleQuote"[[:space:]]*:[[:space:]]*true' "$cfg"; then QUOTE_CONFIG="single"; fi
                if [ -z "$QUOTE_CONFIG" ] && grep -qE '"singleQuote"[[:space:]]*:[[:space:]]*false' "$cfg"; then QUOTE_CONFIG="double"; fi
            fi
        done
    fi
    if has "eslint.config.*" || has ".eslintrc*"; then FORMATTERS+=(eslint); fi
    if has "biome.json" || has "biome.jsonc"; then FORMATTERS+=(biome); fi
    if has ".editorconfig"; then FORMATTERS+=(editorconfig); fi
    if has ".stylelintrc*" || has "stylelint.config.*"; then FORMATTERS+=(stylelint); fi
    if has "ruff.toml" || has ".ruff.toml" || { [ -f "$dir/pyproject.toml" ] && grep -q '^\[tool\.ruff' "$dir/pyproject.toml"; }; then FORMATTERS+=(ruff); fi
    if [ -f "$dir/pyproject.toml" ] && grep -q '^\[tool\.black' "$dir/pyproject.toml"; then FORMATTERS+=(black); fi
    if has ".rubocop.yml"; then FORMATTERS+=(rubocop); fi
    if has ".php-cs-fixer*.php"; then FORMATTERS+=(php-cs-fixer); fi
    if has "go.mod"; then FORMATTERS+=(gofmt); fi
    if [ -z "$ALIASES" ]; then
        for cfg in "$dir/tsconfig.json" "$dir/jsconfig.json"; do
            if [ -f "$cfg" ] && [ -z "$ALIASES" ]; then
                ALIASES="$(grep -oE '"[@~#][^"]*/\*"[[:space:]]*:' "$cfg" | sed -E 's/^"//; s/\*"[[:space:]]*:$//' | LC_ALL=C sort -u | tr '\n' ' ' | sed 's/ $//' || true)"
            fi
        done
    fi
    if [ -d "$dir/.git" ] || [ -f "$dir/package.json" ] || [ -f "$dir/pyproject.toml" ] || [ -f "$dir/go.mod" ] || [ -f "$dir/composer.json" ] || [ -f "$dir/Gemfile" ] || [ -f "$dir/pom.xml" ] || [ -f "$dir/build.gradle" ]; then
        break
    fi
    parent="$(dirname "$dir")"
    [ "$parent" = "$dir" ] && break
    dir="$parent"
done

STYLE="$(LC_ALL=C awk '
{
    sub(/\r$/, "")
    if ($0 ~ /^[ \t]*$/) next
    if (FILENAME ~ /\.(ts|tsx|js|jsx|mjs|cjs|vue|svelte)$/) {
        if ($0 ~ /^[ \t]*(import|export|const|let|var|return)[ \t]/ && $0 !~ /[{(\[,=>][ \t]*$/) {
            stmts++
            if ($0 ~ /;[ \t]*$/) semis++
        }
        if ($0 ~ /^[ \t]*import[ \t]/) {
            if ($0 ~ /(from[ \t]+|import[ \t]+)\047/) single++
            else if ($0 ~ /(from[ \t]+|import[ \t]+)"/) double++
        }
    }
    if ($0 ~ /^\t/) tabs++
    else if (match($0, /^ +/)) {
        spaced++
        if (RLENGTH % 4 == 2) twos++
    }
}
END {
    printf "%d %d %d %d %d %d %d\n", stmts, semis, single, double, tabs, spaced, twos
}
' "${SOURCES[@]+"${SOURCES[@]}"}" /dev/null)"

read -r STMTS SEMIS SINGLE DOUBLE TABS SPACED TWOS <<<"$STYLE"

if [ -n "$SEMI_CONFIG" ]; then
    SEMI_LINE="$SEMI_CONFIG (prettier config)"
elif [ "${#JS_SOURCES[@]}" -eq 0 ] || [ "$STMTS" -eq 0 ]; then
    SEMI_LINE="unknown"
elif [ $((SEMIS * 2)) -gt "$STMTS" ]; then
    SEMI_LINE="yes ($SEMIS of $STMTS statements)"
else
    SEMI_LINE="no ($SEMIS of $STMTS statements)"
fi

if [ -n "$QUOTE_CONFIG" ]; then
    QUOTE_LINE="$QUOTE_CONFIG (prettier config)"
elif [ $((SINGLE + DOUBLE)) -eq 0 ]; then
    QUOTE_LINE="unknown"
elif [ "$SINGLE" -ge "$DOUBLE" ]; then
    QUOTE_LINE="single ($SINGLE of $((SINGLE + DOUBLE)) imports)"
else
    QUOTE_LINE="double ($DOUBLE of $((SINGLE + DOUBLE)) imports)"
fi

if [ $((TABS + SPACED)) -eq 0 ]; then
    INDENT_LINE="unknown"
elif [ "$TABS" -gt "$SPACED" ]; then
    INDENT_LINE="tabs"
elif [ $((TWOS * 20)) -gt "$SPACED" ]; then
    INDENT_LINE="2 spaces"
else
    INDENT_LINE="4 spaces"
fi

FORMATTER_LINE="none"
if [ "${#FORMATTERS[@]}" -gt 0 ]; then
    FORMATTER_LINE="$(printf '%s\n' "${FORMATTERS[@]}" | awk '!seen[$0]++' | tr '\n' ' ' | sed 's/ $//')"
fi

cat "$REPORT"
echo "FORMATTERS: $FORMATTER_LINE"
echo "SEMICOLONS: $SEMI_LINE"
echo "QUOTES: $QUOTE_LINE"
echo "INDENT: $INDENT_LINE"
echo "IMPORT_ALIAS: ${ALIASES:-none}"
echo ""
echo "Follow the dominant style for new files and folders. Formatter config wins over the sample."
