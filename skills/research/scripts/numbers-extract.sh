#!/bin/bash
set -euo pipefail

usage() {
    echo "Usage: numbers-extract.sh <path> [path...]" >&2
}

if [ $# -lt 1 ]; then
    echo "ERROR: give a file or folder to read." >&2
    usage
    exit 1
fi

FILES=()
ROOT=""
for TARGET in "$@"; do
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
            -o \( -type f \( -iname '*.tex' -o -iname '*.md' -o -iname '*.markdown' -o -iname '*.qmd' -o -iname '*.rmd' -o -iname '*.txt' \) -print0 \))
    else
        case "$(printf '%s' "${TARGET##*/}" | tr 'A-Z' 'a-z')" in
            *.tex|*.md|*.markdown|*.qmd|*.rmd|*.txt) ;;
            *)
                echo "ERROR: $TARGET is not a .tex, .md or .txt file." >&2
                exit 1 ;;
        esac
        [ -z "$ROOT" ] && ROOT="$(dirname "$TARGET")"
        FILES+=("$TARGET")
    fi
done

SORTED=()
if [ ${#FILES[@]} -gt 0 ]; then
    while IFS= read -r file; do
        SORTED+=("$file")
    done < <(printf '%s\n' "${FILES[@]}" | LC_ALL=C sort -u)
fi

echo "NUMBERS EXTRACT: $*"
echo "FILES_SCANNED: ${#SORTED[@]}"
echo ""

if [ ${#SORTED[@]} -eq 0 ]; then
    echo ""
    echo "NUMBERS: 0"
    echo "ABSTRACT: not found"
    echo "SAMPLE_SIZES: none"
    echo "ABSTRACT_ONLY: 0"
    echo "SAMPLE_SIZE: 0"
    echo "PCT_SUM: 0"
    echo "FLAGS: 0"
    echo ""
    echo "Each flag is a lead. Read the sentence in context before you report it."
    exit 0
fi

LC_ALL=C awk -v root="$ROOT" '
function relpath(f) {
    if (root != "" && root != "." && index(f, root "/") == 1) return substr(f, length(root) + 2)
    if (index(f, "./") == 1) return substr(f, 3)
    return f
}
function absval(x) {
    return x < 0 ? -x : x
}
function pow10(d,    r, i) {
    r = 1
    for (i = 0; i < d; i++) r *= 10
    return r
}
function append(line, ln) {
    if (plen == 0) {
        pzone = inabs ? "ABSTRACT" : (pnext != "" ? pnext : "TEXT")
        pnext = ""
        plen = 1
        PL[1] = ln
        PO[1] = 1
        ptext = line
        return
    }
    plen++
    PL[plen] = ln
    PO[plen] = length(ptext) + 2
    ptext = ptext " " line
}
function line_at(pos,    k, r) {
    r = PL[1]
    for (k = 1; k <= plen; k++) if (PO[k] <= pos) r = PL[k]
    return r
}
function word_before(i,    k) {
    k = i - 1
    while (k >= 1 && substr(ptext, k, 1) ~ /[A-Za-z.]/) k--
    return tolower(substr(ptext, k + 1, i - 1 - k))
}
function flush(    n, s, i, c, nx, j, d, w) {
    if (plen == 0) return
    n = length(ptext)
    s = 1
    for (i = 1; i <= n; i++) {
        c = substr(ptext, i, 1)
        if (c != "." && c != "!" && c != "?") continue
        nx = substr(ptext, i + 1, 1)
        if (nx != " " && nx != "\t") continue
        j = i + 1
        while (j <= n && (substr(ptext, j, 1) == " " || substr(ptext, j, 1) == "\t")) j++
        if (j > n) continue
        d = substr(ptext, j, 1)
        if (d !~ /[A-Z\\]/) continue
        if (c == ".") {
            w = word_before(i)
            if ((w in ABBR) || length(w) == 1) continue
        }
        sentence(substr(ptext, s, i - s + 1), line_at(s), pzone)
        s = j
        i = j - 1
    }
    if (s <= n) sentence(substr(ptext, s), line_at(s), pzone)
    plen = 0
    ptext = ""
}
function unit(line, ln, zone) {
    flush()
    sentence(line, ln, zone)
}
function clean(t,    c) {
    c = tolower(t)
    gsub(/\\%/, "%", c)
    gsub(/\\(ref|eqref|cref|autoref|pageref|nameref|label|url|href|includegraphics|input|include|bibliography|bibliographystyle|addbibresource|usepackage|vspace|hspace|setlength|cmidrule|cline|multirow|multicolumn|footnotemark|[a-z]*cite[a-z]*)\*?(\([^)]*\))?(\[[^]]*\])*\{[^}]*\}/, " ", c)
    gsub(/https?:\/\/[^ )}>]*/, " ", c)
    gsub(/\]\([^)]*\)/, "] ", c)
    gsub(/@[a-z0-9_][a-z0-9_:.\/-]*/, " ", c)
    gsub(/\[[0-9][0-9 ,;-]*\]/, " ", c)
    gsub(/(^|[^a-z])(figures?|figs?\.|tables?|tab\.|sections?|sec\.|eqs?\.|equations?|appendix|chapters?|algorithms?|lines?|pages?|pp?\.|steps?|rows?|columns?|items?|stages?|phases?|versions?|v\.)[ ~]*\(?[0-9]+(\.[0-9]+)*[a-z]?\)?([ ]*(-|--|to|and)[ ]*\(?[0-9]+(\.[0-9]+)*[a-z]?\)?)?/, " ", c)
    gsub(/[0-9]+(st|nd|rd|th)([^a-z]|$)/, " ", c)
    gsub(/\\[a-z]+\*?/, " ", c)
    gsub(/\\./, " ", c)
    gsub(/[{}$~]/, " ", c)
    return c
}
function sentence(t, ln, zone,    c, off, r, a, L, tok, pc, ppc, neg, rest, pct, dec, val, cnt, sum, maxd, bad, tol, fmt, m) {
    gsub(/[ \t]+/, " ", t)
    sub(/^ /, "", t)
    sub(/ $/, "", t)
    if (t == "") return
    c = clean(t)
    off = 1
    cnt = 0
    sum = 0
    maxd = 0
    bad = 0
    while (off <= length(c)) {
        r = substr(c, off)
        if (!match(r, /[0-9]+(,[0-9][0-9][0-9])*(\.[0-9]+)?(e[-+]?[0-9]+)?/)) break
        a = off + RSTART - 1
        L = RLENGTH
        off = a + L
        tok = substr(c, a, L)
        pc = (a > 1) ? substr(c, a - 1, 1) : ""
        ppc = (a > 2) ? substr(c, a - 2, 1) : ""
        neg = 0
        if (pc ~ /[a-z0-9_^]/) continue
        if (pc == ".") {
            if (ppc ~ /[a-z0-9_]/) continue
            tok = "0." tok
        } else if (pc == "-") {
            if (ppc ~ /[a-z]/) continue
            if (ppc !~ /[0-9-]/) neg = 1
        }
        rest = substr(c, off)
        pct = 0
        if (match(rest, /^ ?%/)) {
            pct = 1
            off += RLENGTH
        } else if (match(rest, /^ ?(percent|per cent)([^a-z]|$)/)) {
            pct = 1
        }
        gsub(/,/, "", tok)
        if (neg) tok = "-" tok
        dec = 0
        if (index(tok, ".") > 0 && tok !~ /e/) dec = length(tok) - index(tok, ".")
        val = tok (pct ? "%" : "")
        nnum++
        NZ[nnum] = zone
        NFL[nnum] = rel
        NL[nnum] = ln
        NV[nnum] = val
        ND[nnum] = dec
        NX[nnum] = tok + 0
        NS[nnum] = t
        print "NUM " zone " " rel ":" ln ": " val " | " t
        if (pct) {
            cnt++
            sum += tok + 0
            if (dec > maxd) maxd = dec
            if (tok + 0 < 0 || tok + 0 > 100) bad = 1
        }
    }
    r = c
    while (match(r, /(^|[^a-z0-9_])n *= *[0-9][0-9,]*/)) {
        m = substr(r, RSTART, RLENGTH)
        r = substr(r, RSTART + RLENGTH)
        sub(/^[^=]*= */, "", m)
        gsub(/,/, "", m)
        nss++
        SV[nss] = m
        SF[nss] = rel
        SL[nss] = ln
        ST[nss] = t
    }
    if (cnt >= 3 && !bad && sum >= 80 && sum <= 120) {
        tol = cnt * 0.5 / pow10(maxd)
        if (absval(sum - 100) > tol + 1e-9) {
            fmt = "%." maxd "f"
            npct++
            PCTLINE[npct] = "PCT_SUM " sprintf(fmt, sum) " " rel ":" ln ": " t
        }
    }
}
function start_file(    low) {
    rel = relpath(FILENAME)
    low = tolower(FILENAME)
    kind = "txt"
    if (low ~ /\.tex$/) kind = "tex"
    else if (low ~ /\.(md|markdown|qmd|rmd)$/) kind = "md"
    inabs = 0
    inrefs = 0
    intab = 0
    infence = 0
    yaml = 0
    inpre = 0
    done = 0
    plen = 0
    ptext = ""
    pnext = ""
}
function tex_line(line, ln,    endabs, low) {
    gsub(/\\%/, "\001", line)
    sub(/%.*/, "", line)
    gsub(/\001/, "\\%", line)
    if (line ~ /\\documentclass/) {
        inpre = 1
        return
    }
    if (inpre) {
        if (line ~ /\\begin\{document\}/) inpre = 0
        return
    }
    if (line ~ /\\end\{document\}/) {
        flush()
        done = 1
        return
    }
    if (line ~ /\\begin\{thebibliography\}/) {
        flush()
        inrefs = 1
        return
    }
    if (inrefs) {
        if (line ~ /\\end\{thebibliography\}/) inrefs = 0
        return
    }
    if (line ~ /\\begin\{abstract\}/) {
        flush()
        inabs = 1
        habs = 1
        sub(/.*\\begin\{abstract\}/, "", line)
    }
    endabs = 0
    if (inabs && line ~ /\\end\{abstract\}/) {
        sub(/\\end\{abstract\}.*/, "", line)
        endabs = 1
    }
    if (line ~ /\\begin\{(tabular|tabularx|tabulary|longtable|array)\*?\}/) {
        flush()
        intab = 1
        return
    }
    if (intab) {
        if (line ~ /\\end\{(tabular|tabularx|tabulary|longtable|array)\*?\}/) {
            intab = 0
            return
        }
        unit(line, ln, "TABLE")
        return
    }
    if (line ~ /^[ \t]*\\(part|chapter|section|subsection|subsubsection|paragraph|subparagraph)\*?[[{]/) {
        flush()
        inabs = 0
        low = tolower(line)
        if (low ~ /\{[ \t]*abstract[ \t]*\}/) {
            inabs = 1
            habs = 1
        }
        return
    }
    if (line ~ /^[ \t]*\\(begin|end)\{/) {
        flush()
        gsub(/\\(begin|end)\{[^}]*\}(\[[^]]*\])?(\{[^}]*\})?/, "", line)
        if (line ~ /^[ \t]*$/) {
            if (endabs) inabs = 0
            return
        }
    }
    if (line ~ /^[ \t]*\\item/) {
        flush()
        sub(/^[ \t]*\\item(\[[^]]*\])?/, "", line)
    }
    if (line ~ /\\caption/) {
        flush()
        pnext = "CAPTION"
    }
    if (line ~ /^[ \t]*$/) {
        flush()
        if (endabs) inabs = 0
        return
    }
    append(line, ln)
    if (endabs) {
        flush()
        inabs = 0
    }
}
function plain_line(line, ln,    low, h) {
    low = tolower(line)
    if (kind == "md" && line ~ /^ ? ? ?#/) {
        flush()
        h = low
        sub(/^[ \t]*#+[ \t]*/, "", h)
        sub(/[ \t#]+$/, "", h)
        inabs = 0
        inrefs = 0
        if (h ~ /^abstract[:.]?$/) {
            inabs = 1
            habs = 1
        } else if (h ~ /^([0-9.]+[ \t]+)?(references|bibliography|works cited|literature cited)[:.]?$/) {
            inrefs = 1
        }
        return
    }
    if (low ~ /^[ \t]*[*_]*abstract[*_]*[ \t]*[:.]?[ \t]*[*_]*[ \t]*$/) {
        flush()
        inabs = 1
        habs = 1
        inrefs = 0
        return
    }
    if (low ~ /^[ \t]*[*_]*([0-9]+\.?[ \t]+)?(references|bibliography|works cited|literature cited)[*_]*[ \t]*:?[ \t]*$/) {
        flush()
        inabs = 0
        inrefs = 1
        return
    }
    if (inrefs) {
        if (low ~ /^[ \t]*[*_#]*[ \t]*(appendix|appendices|supplementary)/) {
            flush()
            inrefs = 0
        } else {
            return
        }
    }
    if (low ~ /^[ \t]*[*_]*abstract[*_]*[^a-z0-9 \t]/) {
        flush()
        inabs = 1
        habs = 1
        sub(/^[ \t]*[*_]*[Aa][Bb][Ss][Tt][Rr][Aa][Cc][Tt][*_]*/, "", line)
        sub(/^[^A-Za-z0-9]+/, "", line)
    }
    if (inabs && low ~ /^[ \t]*[*_#]*[ \t]*(([0-9]+|[ivx]+)\.?[ \t]+)?(introduction|keywords|key words|index terms|background|motivation|overview)([^a-z]|$)/) {
        flush()
        inabs = 0
    }
    if (kind == "md" && line ~ /^[ \t]*\|/) {
        unit(line, ln, "TABLE")
        return
    }
    if (kind == "txt" && line ~ /\t.*\t/) {
        unit(line, ln, "TABLE")
        return
    }
    if (kind == "txt" && length(line) <= 80 && line ~ /^[ \t]*[0-9]+(\.[0-9]+)*\.?[ \t]+[A-Z][^.!?]*$/) {
        flush()
        return
    }
    if (kind == "md" && line ~ /^[ \t]*([-*+]|[0-9]+[.)])[ \t]+/) {
        flush()
        sub(/^[ \t]*([-*+]|[0-9]+[.)])[ \t]+/, "", line)
    }
    if (low ~ /^[ \t]*[*_]*(table|figure|fig\.)[ \t]*[0-9]+[a-z]?[*_]*[ \t]*[:.]/) {
        flush()
        pnext = "CAPTION"
    }
    if (line ~ /^[ \t]*$/) {
        flush()
        return
    }
    append(line, ln)
}
BEGIN {
    split("e.g i.e al fig figs eq eqs sec secs tab vs cf approx no nos vol pp p dr mr ms prof st resp ca ref refs", A, " ")
    for (i in A) ABBR[A[i]] = 1
    nnum = 0
    nss = 0
    npct = 0
    habs = 0
}
FNR == 1 {
    if (NR > 1) flush()
    start_file()
}
{
    line = $0
    sub(/\r$/, "", line)
    if (done) next
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
            flush()
            infence = !infence
            next
        }
        if (infence) next
    }
    if (kind == "tex") tex_line(line, FNR)
    else plain_line(line, FNR)
}
END {
    flush()
    print ""
    nao = 0
    for (i = 1; i <= nnum; i++) {
        if (NZ[i] != "ABSTRACT") continue
        if (NV[i] in SEEN) continue
        SEEN[NV[i]] = 1
        tol = 0.5 / pow10(ND[i]) + 1e-9
        found = 0
        for (j = 1; j <= nnum; j++) {
            if (NZ[j] == "ABSTRACT") continue
            if (absval(NX[j] - NX[i]) <= tol) {
                found = 1
                break
            }
        }
        if (!found) {
            nao++
            print "ABSTRACT_ONLY " NV[i] " " NFL[i] ":" NL[i] ": " NS[i]
        }
    }
    nd = 0
    list = ""
    for (i = 1; i <= nss; i++) {
        if (!(SV[i] in DIST)) {
            DIST[SV[i]] = 1
            nd++
            list = list (list == "" ? "" : " ") SV[i]
        }
    }
    nflag = 0
    if (nd >= 2) {
        for (i = 1; i <= nss; i++) {
            nflag++
            print "SAMPLE_SIZE " SV[i] " " SF[i] ":" SL[i] ": " ST[i]
        }
    }
    for (i = 1; i <= npct; i++) print PCTLINE[i]
    print ""
    print "NUMBERS: " nnum
    print "ABSTRACT: " (habs ? "found" : "not found")
    print "SAMPLE_SIZES: " (list == "" ? "none" : list)
    print "ABSTRACT_ONLY: " nao
    print "SAMPLE_SIZE: " nflag
    print "PCT_SUM: " npct
    print "FLAGS: " (nao + nflag + npct)
    print ""
    print "Each flag is a lead. Read the sentence in context before you report it."
}
' "${SORTED[@]}"
