#!/bin/bash
set -euo pipefail

usage() {
    echo "Usage: cite-check.sh [--online] [--mailto <address>] <path> [path...]" >&2
}

ONLINE=0
MAILTO=""
TARGETS=()
while [ $# -gt 0 ]; do
    case "$1" in
        --online) ONLINE=1 ;;
        --mailto)
            if [ $# -lt 2 ]; then
                echo "ERROR: --mailto needs an address." >&2
                exit 1
            fi
            MAILTO="$2"
            shift ;;
        --*)
            echo "ERROR: unknown option $1." >&2
            usage
            exit 1 ;;
        *) TARGETS+=("$1") ;;
    esac
    shift
done

if [ ${#TARGETS[@]} -eq 0 ]; then
    echo "ERROR: give a file or folder to check." >&2
    usage
    exit 1
fi

FILES=()
ROOT=""
for TARGET in "${TARGETS[@]}"; do
    if command -v cygpath &>/dev/null; then
        TARGET="$(cygpath -u "$TARGET")"
    fi
    if [ ! -e "$TARGET" ]; then
        echo "ERROR: $TARGET does not exist." >&2
        exit 1
    fi
    if [ -d "$TARGET" ]; then
        [ -z "$ROOT" ] && ROOT="${TARGET%/}"
        while IFS= read -r -d '' file; do
            FILES+=("$file")
        done < <(find "$TARGET" -mindepth 1 \
            \( -type d \( -name .git -o -name node_modules -o -name .venv -o -name venv -o -name _build -o -name build \) -prune \) \
            -o \( -type f \( -iname '*.tex' -o -iname '*.md' -o -iname '*.markdown' -o -iname '*.qmd' -o -iname '*.rmd' -o -iname '*.bib' \) -print0 \))
    else
        case "$(printf '%s' "${TARGET##*/}" | tr 'A-Z' 'a-z')" in
            *.tex|*.md|*.markdown|*.qmd|*.rmd|*.bib) ;;
            *)
                echo "ERROR: $TARGET is not a .tex, .md or .bib file." >&2
                exit 1 ;;
        esac
        [ -z "$ROOT" ] && ROOT="$(dirname "$TARGET")"
        FILES+=("$TARGET")
    fi
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

SORTED=()
if [ ${#FILES[@]} -gt 0 ]; then
    while IFS= read -r file; do
        SORTED+=("$file")
    done < <(printf '%s\n' "${FILES[@]}" | LC_ALL=C sort -u)
fi

: >"$TMP/findings"
: >"$TMP/dois"
: >"$TMP/stats"

if [ ${#SORTED[@]} -gt 0 ]; then
LC_ALL=C awk -v root="$ROOT" -v findings="$TMP/findings" -v dois="$TMP/dois" -v stats="$TMP/stats" '
function relpath(f) {
    if (root != "" && root != "." && index(f, root "/") == 1) return substr(f, length(root) + 2)
    if (index(f, "./") == 1) return substr(f, 3)
    return f
}
function codeidx(code) {
    return CODES[code]
}
function emit(code, key, file, line, detail) {
    printf "%02d\t%s\t%09d\t%s\t%s %s %s:%d: %s\n", codeidx(code), file, line, key, code, key, file, line, detail > findings
}
function trim(s) {
    sub(/^[ \t]+/, "", s)
    sub(/[ \t]+$/, "", s)
    return s
}
function normtitle(s) {
    gsub(/<[^>]*>/, " ", s)
    gsub(/&[A-Za-z#0-9]+;/, " ", s)
    gsub(/\\u[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]/, " ", s)
    gsub(/\\[A-Za-z]+/, "", s)
    gsub(/\\[^A-Za-z]/, "", s)
    gsub(/[{}]/, "", s)
    s = tolower(s)
    gsub(/[^a-z0-9]+/, " ", s)
    return trim(s)
}
function add_cite(k, ln) {
    if (k == "") return
    if (!(k in CITED)) {
        CITED[k] = 1
        CFILE[k] = rel
        CLINE[k] = ln
        ncited++
    }
}
function add_keys(content, ln,    parts, n, i, k) {
    n = split(content, parts, ",")
    for (i = 1; i <= n; i++) {
        k = trim(parts[i])
        if (k == "*") nocite_all = 1
        else if (k !~ /#/) add_cite(k, ln)
    }
}
function scan_cites(s, ln,    cmd, rest, plural, got, c, closer, i, startcmd) {
    pend = ""
    while (match(s, /\\[A-Za-z]*cite[A-Za-z]*\*?/)) {
        cmd = substr(s, RSTART, RLENGTH)
        startcmd = RSTART
        rest = substr(s, RSTART + RLENGTH)
        plural = (cmd ~ /cites\*?$/)
        got = 0
        while (1) {
            sub(/^[ \t]+/, "", rest)
            c = substr(rest, 1, 1)
            if (c == "[" || c == "(") {
                closer = (c == "[") ? "]" : ")"
                i = index(rest, closer)
                if (i == 0) {
                    pend = substr(s, startcmd)
                    pendline = ln
                    return
                }
                rest = substr(rest, i + 1)
                continue
            }
            if (c == "{") {
                i = index(rest, "}")
                if (i == 0) {
                    pend = substr(s, startcmd)
                    pendline = ln
                    return
                }
                add_keys(substr(rest, 2, i - 2), ln)
                rest = substr(rest, i + 1)
                got++
                if (plural) continue
                break
            }
            if (c == "" && got == 0) {
                pend = substr(s, startcmd)
                pendline = ln
                return
            }
            break
        }
        s = rest
    }
}
function scan_pandoc(s, ln,    k) {
    s = " " s
    while (match(s, /[[ \t;(-]@[A-Za-z0-9_][A-Za-z0-9_:.\/-]*/)) {
        k = substr(s, RSTART + 2, RLENGTH - 2)
        sub(/[^A-Za-z0-9_]+$/, "", k)
        if (k !~ /^(fig|tbl|sec|eq|lst|tab):/) add_cite(k, ln)
        s = substr(s, RSTART + RLENGTH)
    }
}
function scan_bibitems(s, ln,    k) {
    while (match(s, /\\bibitem(\[[^]]*\])?\{[^}]*\}/)) {
        k = substr(s, RSTART, RLENGTH)
        sub(/^\\bibitem(\[[^]]*\])?\{/, "", k)
        sub(/\}$/, "", k)
        k = trim(k)
        if (k != "" && !(k in DEFINED)) {
            DEFINED[k] = 1
            DFILE[k] = rel
            DLINE[k] = ln
            ndefined++
        }
        s = substr(s, RSTART + RLENGTH)
    }
}
function text_line(line, ln) {
    if (pend != "") {
        if (pendcount >= 5) {
            pend = ""
        } else {
            pendcount++
            scan_cites(pend " " line, pendline)
            return
        }
    }
    pendcount = 0
    scan_cites(line, ln)
}
function brace_end(s,    i, n, d, c) {
    n = length(s)
    d = 0
    for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if (c == "{") d++
        else if (c == "}") {
            d--
            if (d == 0) return i
        }
    }
    return n + 1
}
function quote_end(s,    i, n, d, c) {
    n = length(s)
    d = 0
    for (i = 2; i <= n; i++) {
        c = substr(s, i, 1)
        if (c == "{") d++
        else if (c == "}") d--
        else if (c == "\"" && d <= 0 && substr(s, i - 1, 1) != "\\") return i
    }
    return n + 1
}
function parse_entry(text, ln,    i, key, rest, name, val, c, n, doi, low, title, missing, year, t) {
    i = index(text, "{")
    rest = substr(text, i + 1)
    i = index(rest, ",")
    if (i == 0) {
        key = rest
        rest = ""
    } else {
        key = substr(rest, 1, i - 1)
        rest = substr(rest, i + 1)
    }
    gsub(/[ \t}]/, "", key)
    if (key == "") return
    split("", F)
    while (1) {
        sub(/^[ \t,]+/, "", rest)
        if (!match(rest, /^[A-Za-z][A-Za-z0-9_:.+-]*[ \t]*=[ \t]*/)) break
        name = substr(rest, 1, RLENGTH)
        sub(/[ \t]*=[ \t]*$/, "", name)
        name = tolower(name)
        rest = substr(rest, RLENGTH + 1)
        val = ""
        while (1) {
            c = substr(rest, 1, 1)
            if (c == "{") {
                n = brace_end(rest)
                val = val substr(rest, 2, n - 2)
                rest = substr(rest, n + 1)
            } else if (c == "\"") {
                n = quote_end(rest)
                val = val substr(rest, 2, n - 2)
                rest = substr(rest, n + 1)
            } else {
                match(rest, /^[^,}# \t]*/)
                val = val substr(rest, 1, RLENGTH)
                rest = substr(rest, RLENGTH + 1)
            }
            sub(/^[ \t]+/, "", rest)
            if (substr(rest, 1, 1) == "#") {
                rest = substr(rest, 2)
                sub(/^[ \t]+/, "", rest)
                continue
            }
            break
        }
        F[name] = trim(val)
    }
    if (key in DEFINED) {
        emit("DUP_KEY", key, rel, ln, "also defined at " DFILE[key] ":" DLINE[key])
        return
    }
    DEFINED[key] = 1
    DFILE[key] = rel
    DLINE[key] = ln
    ndefined++
    if (F["doi"] == "" && F["url"] == "" && F["eprint"] == "" && F["isbn"] == "" && F["howpublished"] !~ /https?:/ && F["note"] !~ /https?:/) {
        emit("NO_LOCATOR", key, rel, ln, "no doi, url, eprint or isbn")
    }
    if (!("crossref" in F)) {
        missing = ""
        if (F["title"] == "") missing = missing " title"
        if (F["author"] == "" && F["editor"] == "" && F["organization"] == "" && F["institution"] == "") missing = missing " author"
        if (F["year"] == "" && F["date"] == "") missing = missing " year"
        if (missing != "") emit("MISSING_FIELD", key, rel, ln, "missing" missing)
    }
    year = ""
    t = F["year"] " " F["date"]
    if (match(t, /[12][0-9][0-9][0-9]/)) year = substr(t, RSTART, 4)
    title = normtitle(F["title"])
    doi = F["doi"]
    if (doi != "") {
        sub(/^[ \t]*(https?:\/\/)?(dx\.)?doi\.org\//, "", doi)
        sub(/^[Dd][Oo][Ii]:[ \t]*/, "", doi)
        doi = trim(doi)
        if (doi !~ /^10\.[0-9][0-9][0-9][0-9]+\/[^ \t]+$/) {
            emit("BAD_DOI", key, rel, ln, doi)
        } else {
            low = tolower(doi)
            if (low in DOIKEY) {
                emit("DUP_DOI", key, rel, ln, "same doi as " DOIKEY[low])
            } else {
                DOIKEY[low] = key
                printf "%s\037%s\037%d\037%s\037%s\037%s\n", key, rel, ln, doi, title, year > dois
            }
        }
    }
    if (title != "") {
        if (title in TITLEKEY) emit("DUP_TITLE", key, rel, ln, "same title as " TITLEKEY[title])
        else TITLEKEY[title] = key
    }
}
function bib_line(line, ln,    t, o, cl) {
    if (!inentry) {
        if (!match(line, /^[ \t]*@[A-Za-z]+[ \t]*\{/)) return
        t = substr(line, RSTART, RLENGTH)
        etype = tolower(t)
        gsub(/[^a-z]/, "", etype)
        inentry = 1
        ebuf = ""
        edepth = 0
        eline = ln
        line = substr(line, RSTART)
    }
    ebuf = ebuf " " line
    o = line
    cl = line
    edepth += gsub(/\{/, "", o) - gsub(/\}/, "", cl)
    if (edepth <= 0) {
        inentry = 0
        if (etype != "comment" && etype != "string" && etype != "preamble") parse_entry(ebuf, eline)
    }
}
BEGIN {
    split("MISSING_KEY UNCITED NO_LOCATOR MISSING_FIELD BAD_DOI DUP_KEY DUP_DOI DUP_TITLE", L, " ")
    for (i = 1; i <= 8; i++) CODES[L[i]] = i
    ncited = 0
    ndefined = 0
    nocite_all = 0
}
FNR == 1 {
    if (pend != "") {
        pendcount = 5
        pend = ""
    }
    rel = relpath(FILENAME)
    lowname = tolower(FILENAME)
    kind = "tex"
    if (lowname ~ /\.bib$/) kind = "bib"
    else if (lowname ~ /\.(md|markdown|qmd|rmd)$/) kind = "md"
    infence = 0
    yaml = 0
    inentry = 0
    pendcount = 0
}
{
    line = $0
    sub(/\r$/, "", line)
    if (kind == "bib") {
        bib_line(line, FNR)
        next
    }
    if (kind == "md") {
        if (FNR == 1 && line ~ /^---[ \t]*$/) {
            yaml = 1
            next
        }
        if (yaml) {
            if (line ~ /^(---|\.\.\.)[ \t]*$/) yaml = 0
            next
        }
        if (line ~ /^[ \t]*(```|~~~)/) {
            infence = !infence
            next
        }
        if (infence) next
        gsub(/`[^`]*`/, " ", line)
        scan_pandoc(line, FNR)
    } else {
        gsub(/\\%/, "  ", line)
        sub(/%.*/, "", line)
        scan_bibitems(line, FNR)
    }
    text_line(line, FNR)
}
END {
    for (k in CITED) {
        if (!(k in DEFINED)) emit("MISSING_KEY", k, CFILE[k], CLINE[k], "cited but not in any bibliography")
    }
    if (!nocite_all) {
        for (k in DEFINED) {
            if (!(k in CITED)) emit("UNCITED", k, DFILE[k], DLINE[k], "in the bibliography but never cited")
        }
    }
    printf "CITED_KEYS: %d\nBIB_ENTRIES: %d\n", ncited, ndefined > stats
}
' "${SORTED[@]}"
fi

urlencode() {
    local LC_ALL=C
    local s="$1" out="" c i
    for ((i = 0; i < ${#s}; i++)); do
        c="${s:i:1}"
        case "$c" in
            [A-Za-z0-9._~/-]) out+="$c" ;;
            *) out+="$(printf '%%%02X' "'$c")" ;;
        esac
    done
    printf '%s' "$out"
}

CHECKED=0
if [ "$ONLINE" -eq 1 ]; then
    if ! command -v curl &>/dev/null; then
        echo "ERROR: --online needs curl." >&2
        exit 1
    fi
    API="${CITE_CHECK_API:-https://api.crossref.org}"
    API="${API%/}"
    DELAY="${CITE_CHECK_DELAY:-1}"
    AGENT="cite-check/1.0"
    [ -n "$MAILTO" ] && AGENT="$AGENT (mailto:$MAILTO)"
    FIRST=1
    while IFS=$'\037' read -r key file line doi title year; do
        [ -n "$key" ] || continue
        if [ "$FIRST" -eq 0 ] && [ "$DELAY" != "0" ]; then
            sleep "$DELAY"
        fi
        FIRST=0
        CHECKED=$((CHECKED + 1))
        CODE=$(curl -sS -o "$TMP/body" -w '%{http_code}' --max-time 20 --connect-timeout 10 -A "$AGENT" "$API/works/$(urlencode "$doi")" 2>/dev/null) || CODE="000"
        case "$CODE" in
            200)
                LC_ALL=C awk -v key="$key" -v file="$file" -v line="$line" -v bibtitle="$title" -v bibyear="$year" '
function trim(s) {
    sub(/^[ \t]+/, "", s)
    sub(/[ \t]+$/, "", s)
    return s
}
function normtitle(s) {
    gsub(/<[^>]*>/, " ", s)
    gsub(/&[A-Za-z#0-9]+;/, " ", s)
    gsub(/\\u[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]/, " ", s)
    gsub(/\\[A-Za-z]+/, "", s)
    gsub(/\\[^A-Za-z]/, "", s)
    gsub(/[{}]/, "", s)
    s = tolower(s)
    gsub(/[^a-z0-9]+/, " ", s)
    return trim(s)
}
function unescape(s) {
    gsub(/\\"/, "\"", s)
    gsub(/\\\//, "/", s)
    return s
}
BEGIN { RS = "\001" }
{
    body = body $0
}
END {
    t = ""
    sub_t = ""
    y = ""
    if (match(body, /[{,]"title":\["([^"\\]|\\.)*"/)) t = unescape(substr(body, RSTART + 11, RLENGTH - 12))
    if (match(body, /[{,]"subtitle":\["([^"\\]|\\.)*"/)) sub_t = unescape(substr(body, RSTART + 14, RLENGTH - 15))
    if (match(body, /"issued":\{"date-parts":\[\[[0-9][0-9][0-9][0-9]/)) y = substr(body, RSTART + RLENGTH - 4, 4)
    full = t
    if (sub_t != "") full = t ": " sub_t
    reg = normtitle(full)
    if (bibtitle != "" && reg != "") {
        na = split(bibtitle, A, " ")
        nb = split(reg, B, " ")
        for (i = 1; i <= na; i++) SA[A[i]] = 1
        for (i = 1; i <= nb; i++) SB[B[i]] = 1
        inter = 0
        uni = 0
        for (w in SA) {
            uni++
            if (w in SB) inter++
        }
        for (w in SB) if (!(w in SA)) uni++
        if (uni > 0 && int(100 * inter / uni) < 70) {
            printf "%02d\t%s\t%09d\t%s\tTITLE_MISMATCH %s %s:%d: Crossref title is \"%s\"\n", 10, file, line, key, key, file, line, full
        }
    }
    if (bibyear != "" && y != "") {
        d = bibyear - y
        if (d < 0) d = -d
        if (d > 1) printf "%02d\t%s\t%09d\t%s\tYEAR_MISMATCH %s %s:%d: bib year %s, Crossref year %s\n", 11, file, line, key, key, file, line, bibyear, y
    }
}
' "$TMP/body" >>"$TMP/findings"
                ;;
            404)
                printf '%02d\t%s\t%09d\t%s\tDOI_NOT_FOUND %s %s:%d: %s not found at Crossref\n' 9 "$file" "$line" "$key" "$key" "$file" "$line" "$doi" >>"$TMP/findings" ;;
            *)
                printf '%02d\t%s\t%09d\t%s\tDOI_UNCHECKED %s %s:%d: request failed with status %s\n' 12 "$file" "$line" "$key" "$key" "$file" "$line" "$CODE" >>"$TMP/findings" ;;
        esac
    done <"$TMP/dois"
fi

count() {
    grep -c "^$1 " "$TMP/lines" || true
}

LC_ALL=C sort -t "$(printf '\t')" -k1,1 -k2,2 -k3,3 -k4,4 "$TMP/findings" | cut -f5- >"$TMP/lines"

echo "CITE CHECK: ${TARGETS[*]}"
echo "FILES_SCANNED: ${#SORTED[@]}"
if [ "$ONLINE" -eq 1 ]; then
    echo "ONLINE: on"
else
    echo "ONLINE: off"
fi
if [ -s "$TMP/stats" ]; then
    cat "$TMP/stats"
else
    echo "CITED_KEYS: 0"
    echo "BIB_ENTRIES: 0"
fi
echo ""
cat "$TMP/lines"
echo ""
echo "FINDINGS: $(wc -l <"$TMP/lines" | tr -d ' ')"
for code in MISSING_KEY UNCITED NO_LOCATOR MISSING_FIELD BAD_DOI DUP_KEY DUP_DOI DUP_TITLE; do
    echo "$code: $(count "$code")"
done
if [ "$ONLINE" -eq 1 ]; then
    echo "DOI_CHECKED: $CHECKED"
    for code in DOI_NOT_FOUND TITLE_MISMATCH YEAR_MISMATCH DOI_UNCHECKED; do
        echo "$code: $(count "$code")"
    done
fi
echo ""
echo "Each line is a lead. Confirm it in the document and the registry before you report it."
