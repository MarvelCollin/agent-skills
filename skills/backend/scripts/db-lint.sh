#!/bin/bash
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: db-lint.sh <path> [path...]" >&2
    exit 1
fi

FILES=()
ROOT=""
for target in "$@"; do
    if command -v cygpath &>/dev/null; then
        target="$(cygpath -u "$target")"
    fi
    if [ ! -e "$target" ]; then
        echo "ERROR: $target does not exist." >&2
        exit 1
    fi
    if [ -z "$ROOT" ]; then
        if [ -d "$target" ]; then ROOT="${target%/}"; else ROOT="$(dirname "$target")"; fi
    fi
    if [ -d "$target" ]; then
        while IFS= read -r -d '' file; do
            FILES+=("$file")
        done < <(find "$target" -mindepth 1 \
            \( -type d \( -name node_modules -o -name .git -o -name vendor -o -name dist -o -name build -o -name .venv -o -name venv \) -prune \) \
            -o \( -type f \( -name '*.sql' -o -name '*.prisma' \) -print0 \) | LC_ALL=C sort -z)
    else
        FILES+=("$target")
    fi
done

RESULTS="$(mktemp)"
trap 'rm -f "$RESULTS"' EXIT

if [ "${#FILES[@]}" -gt 0 ]; then
    LC_ALL=C awk -v root="$ROOT" '
    function rel(f) {
        if (index(f, root "/") == 1) return substr(f, length(root) + 2)
        return f
    }
    function trim(s) {
        sub(/^[ \t]+/, "", s)
        sub(/[ \t]+$/, "", s)
        return s
    }
    function norm(x) {
        gsub(/"/, "", x)
        sub(/.*\./, "", x)
        return tolower(x)
    }
    function emit(rule, check, file, n, text) {
        print rule " " check " " rel(file) ":" n ": " substr(trim(text), 1, 120)
    }
    function lead(s) {
        sub(/^[^(]*\(/, "", s)
        sub(/[,)].*$/, "", s)
        s = trim(s)
        sub(/[ \t].*$/, "", s)
        return norm(s)
    }
    function addfk(tbl, col, file, n, text,    key) {
        key = tbl SUBSEP col
        if (key in fkseen) return
        fkseen[key] = 1
        nfk++
        fkkey[nfk] = key
        fkfile[nfk] = file
        fkline[nfk] = n
        fktext[nfk] = text
    }
    function coltype(file, n, text, name, rest) {
        if (name ~ money && rest ~ /^(float|double precision|real|money)([^a-z]|$)/) emit("B14", "float-money", file, n, text)
        if (rest ~ /^timestamp([ \t]*\([0-9]+\))?([ \t]+without[ \t]+time[ \t]+zone)?([^a-z]|$)/ && rest !~ /^timestamp([ \t]*\([0-9]+\))?[ \t]+with[ \t]+time/) emit("B14", "timestamp-without-tz", file, n, text)
        if (rest ~ /^json([^b]|$)/) emit("B6", "json-not-jsonb", file, n, text)
        if (rest ~ /^(char|character)[ \t]*\(/) emit("B6", "char-column", file, n, text)
        if (rest ~ /^uuid/ && rest ~ /primary[ \t]+key/ && rest ~ /default[ \t]+(gen_random_uuid|uuid_generate_v4)/) emit("B14", "random-uuid-key", file, n, text)
    }
    function element(file, n, el, text,    low, name, rest) {
        low = tolower(trim(el))
        if (low == "") return
        if (low ~ /^constraint[ \t]/) sub(/^constraint[ \t]+[^ \t]+[ \t]+/, "", low)
        if (low ~ /^primary[ \t]+key/) { haspk[table] = 1; idx[table, lead(low)] = 1; return }
        if (low ~ /^unique[ \t]*\(/) { idx[table, lead(low)] = 1; return }
        if (low ~ /^foreign[ \t]+key/) { addfk(table, lead(low), file, n, text); return }
        if (low ~ /^(check|exclude|like)([ \t(]|$)/) return
        name = low
        sub(/[ \t].*$/, "", name)
        name = norm(name)
        rest = low
        if (rest !~ /[ \t]/) return
        sub(/^[^ \t]+[ \t]+/, "", rest)
        if (rest ~ /primary[ \t]+key/) { haspk[table] = 1; idx[table, name] = 1 }
        if (rest ~ /(^|[ \t])unique([ \t,]|$)/) idx[table, name] = 1
        if (rest ~ /(^|[ \t])references[ \t]/) addfk(table, name, file, n, text)
        coltype(file, n, text, name, rest)
    }
    function chunk(file, n, s, text,    i, c, buf) {
        buf = ""
        for (i = 1; i <= length(s); i++) {
            c = substr(s, i, 1)
            if (c == "(") {
                depth++
                if (depth == 1) continue
            } else if (c == ")") {
                depth--
                if (depth == 0) {
                    element(file, n, buf, text)
                    if (!(table in haspk) && !(table in nopk)) {
                        nopk[table] = 1
                        nopkfile[table] = file
                        nopkline[table] = tline
                        nopktext[table] = ttext
                    }
                    intable = 0
                    return
                }
            } else if (c == "," && depth == 1) {
                element(file, n, buf, text)
                buf = ""
                continue
            }
            if (depth >= 1) buf = buf c
        }
        if (buf != "") element(file, n, buf, text)
    }
    function flush(file,    s, tbl, after, name, rest) {
        s = tolower(stmt)
        gsub(/[ \t]+/, " ", s)
        s = trim(s)
        stmt = ""
        if (s == "") return
        if (s ~ /^(begin|start transaction)( |$)/) hastx[file] = 1
        if (s ~ /lock_timeout/) haslt[file] = 1
        if (s ~ /^create (unique )?index /) {
            tbl = s
            sub(/^.* on (only )?/, "", tbl)
            after = tbl
            sub(/[ (].*$/, "", tbl)
            tbl = norm(tbl)
            idx[tbl, lead(after)] = 1
            if (s ~ /^create (unique )?index concurrently/) {
                if (file in hastx) emit("B6", "concurrent-in-transaction", file, sline, stext)
            } else if (!((file, tbl) in created)) {
                emit("B6", "index-not-concurrent", file, sline, stext)
            }
            return
        }
        if (s ~ /^alter table /) {
            tbl = s
            sub(/^alter table (if exists )?(only )?/, "", tbl)
            sub(/ .*$/, "", tbl)
            tbl = norm(tbl)
            if (!(file in firstalter)) {
                firstalter[file] = sline
                firstaltertext[file] = stext
            }
            if (s ~ / add (constraint [^ ]+ )?primary key/) haspk[tbl] = 1
            if (s ~ / add (constraint [^ ]+ )?(primary key|unique)/ && s !~ / using index/) emit("B6", "unique-under-lock", file, sline, stext)
            if (s ~ / add (constraint [^ ]+ )?(foreign key|check)/ && s !~ /not valid/) emit("B6", "constraint-validates-under-lock", file, sline, stext)
            if (match(s, / add (constraint [^ ]+ )?foreign key/)) addfk(tbl, lead(substr(s, RSTART)), file, sline, stext)
            if (s ~ / alter (column )?[^ ]+ set not null/) emit("B6", "set-not-null", file, sline, stext)
            if (s ~ / alter (column )?[^ ]+ (set data )?type /) emit("B6", "column-type-change", file, sline, stext)
            if (s ~ / rename (to|column) | rename [^ ]+ to /) emit("B6", "rename", file, sline, stext)
            if (s ~ / drop column /) emit("B6", "drop", file, sline, stext)
            if (match(s, / add (column )?(if not exists )?/)) {
                after = substr(s, RSTART + RLENGTH)
                if (after !~ /^(constraint|primary|unique|foreign|check|exclude) /) {
                    name = after
                    sub(/ .*$/, "", name)
                    rest = after
                    sub(/^[^ ]+ ?/, "", rest)
                    if (rest ~ /not null/ && rest !~ /default /) emit("B6", "not-null-without-default", file, sline, stext)
                    if (rest ~ /default (gen_random_uuid|uuid_generate_v[14]|random|clock_timestamp|timeofday|nextval)/) emit("B6", "volatile-default", file, sline, stext)
                    coltype(file, sline, stext, norm(name), rest)
                }
            }
            return
        }
        if (s ~ /^drop table /) emit("B6", "drop", file, sline, stext)
        if (s ~ /^(update|delete from) / && s !~ / where /) emit("B6", "unbatched-write", file, sline, stext)
        if (s ~ /^(vacuum full|cluster|lock|reindex)( |$)/ && s !~ /concurrently/) emit("B6", "heavy-lock", file, sline, stext)
    }
    function endfile() {
        if (curfile != "" && !curprisma && trim(stmt) != "") flush(curfile)
        stmt = ""
    }
    BEGIN {
        money = "(price|amount|balance|cost|subtotal|fee|salary|total)"
    }
    FNR == 1 {
        sub(/^\357\273\277/, "")
        endfile()
        curfile = FILENAME
        curprisma = (FILENAME ~ /\.prisma$/)
        pg = 0
        inmodel = 0
        intable = 0
        indollar = 0
        stmt = ""
    }
    curprisma {
        line = $0
        sub(/\r$/, "", line)
        code = line
        sub(/\/\/.*$/, "", code)
        if (code ~ /provider[ \t]*=[ \t]*"(postgresql|postgres)"/) pg = 1
        if (code ~ /^[ \t]*model[ \t]+[A-Za-z0-9_]+[ \t]*\{/) {
            inmodel = 1
            model = code
            sub(/^[ \t]*model[ \t]+/, "", model)
            sub(/[ \t{].*$/, "", model)
            modelstart = npfk + 1
            next
        }
        if (!inmodel) next
        if (code ~ /^[ \t]*\}/) {
            for (i = modelstart; i <= npfk; i++) {
                if (!((model, pfkcol[i]) in pidx)) emit("B6", "fk-without-index", FILENAME, pfkline[i], pfktext[i])
            }
            inmodel = 0
            next
        }
        t = trim(code)
        if (t == "") next
        if (t ~ /^@@(index|unique|id)[ \t]*\(/) {
            c = t
            sub(/^[^[]*\[/, "", c)
            sub(/[,\] (].*$/, "", c)
            pidx[model, c] = 1
            next
        }
        fname = t
        sub(/[ \t].*$/, "", fname)
        ftype = t
        sub(/^[^ \t]+[ \t]+/, "", ftype)
        sub(/[ \t].*$/, "", ftype)
        if (t ~ /@id([^A-Za-z]|$)/ || t ~ /@unique/) pidx[model, fname] = 1
        if (t ~ /@relation\(/ && t ~ /fields:[ \t]*\[/) {
            c = t
            sub(/^.*fields:[ \t]*\[/, "", c)
            sub(/[,\] ].*$/, "", c)
            npfk++
            pfkcol[npfk] = c
            pfkline[npfk] = FNR
            pfktext[npfk] = line
        }
        if (tolower(fname) ~ money && ftype ~ /^Float\??$/) emit("B14", "float-money", FILENAME, FNR, line)
        if (pg && ftype ~ /^DateTime\??$/ && t !~ /@db\.Timestamptz/) emit("B14", "timestamp-without-tz", FILENAME, FNR, line)
        if (t ~ /@id/ && t ~ /@default\(uuid\((4)?\)\)/) emit("B14", "random-uuid-key", FILENAME, FNR, line)
        next
    }
    {
        line = $0
        sub(/\r$/, "", line)
        code = line
        sub(/--.*$/, "", code)
        low = tolower(code)
        if (intable) {
            chunk(FILENAME, FNR, code, line)
        } else if (match(low, /^[ \t]*create[ \t]+((global|local)[ \t]+)?((temp|temporary|unlogged)[ \t]+)?table[ \t]+(if[ \t]+not[ \t]+exists[ \t]+)?/)) {
            rest = substr(code, RSTART + RLENGTH)
            rawtable = rest
            sub(/[ \t(].*$/, "", rawtable)
            table = norm(rawtable)
            created[FILENAME, table] = 1
            if (tolower(rest) !~ /partition[ \t]+of|[ \t]as[ \t]/) {
                intable = 1
                depth = 0
                tline = FNR
                ttext = line
                chunk(FILENAME, FNR, substr(rest, length(rawtable) + 1), line)
            }
        }
        if (indollar || code ~ /\$[A-Za-z_]*\$/) {
            if (trim(stmt) == "") { sline = FNR; stext = line }
            stmt = stmt " " code
            tmp = code
            ndollar = gsub(/\$[A-Za-z_]*\$/, "", tmp)
            if (ndollar % 2 == 1) indollar = !indollar
            if (!indollar && code ~ /;[ \t]*$/) flush(FILENAME)
            next
        }
        np = split(code, parts, ";")
        for (k = 1; k <= np; k++) {
            if (trim(parts[k]) != "") {
                if (trim(stmt) == "") { sline = FNR; stext = line }
                stmt = stmt " " parts[k]
            }
            if (k < np) flush(FILENAME)
        }
    }
    END {
        endfile()
        for (i = 1; i <= nfk; i++) {
            if (!(fkkey[i] in idx)) emit("B6", "fk-without-index", fkfile[i], fkline[i], fktext[i])
        }
        for (t in nopk) {
            if (!(t in haspk)) emit("B6", "missing-primary-key", nopkfile[t], nopkline[t], nopktext[t])
        }
        for (f in firstalter) {
            if (!(f in haslt)) emit("B6", "no-lock-timeout", f, firstalter[f], firstaltertext[f])
        }
    }
    ' "${FILES[@]}" >>"$RESULTS"
fi

echo "DB LINT: $*"
echo "FILES_SCANNED: ${#FILES[@]}"
echo ""
sort -t " " -k1.2,1n -k2,2 -k3,3 "$RESULTS"
echo ""
echo "FINDINGS: $(wc -l <"$RESULTS" | tr -d ' ')"
for rule in B6 B14; do
    echo "$rule: $(grep -c "^$rule " "$RESULTS" || true)"
done
echo ""
echo "Each line is a lead, not a confirmed finding. Read it in context before reporting."
