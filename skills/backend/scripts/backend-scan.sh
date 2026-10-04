#!/bin/bash
set -euo pipefail

TARGET="${1:?Usage: backend-scan.sh <path>}"

if command -v cygpath &>/dev/null; then
    TARGET="$(cygpath -u "$TARGET")"
fi

if [ ! -e "$TARGET" ]; then
    echo "ERROR: $TARGET does not exist." >&2
    exit 1
fi

FILES=()
SQL_FILES=()
add_file() {
    case "$1" in
        *.sql) SQL_FILES+=("$1") ;;
    esac
    FILES+=("$1")
}

if [ -d "$TARGET" ]; then
    ROOT="${TARGET%/}"
    while IFS= read -r -d '' file; do
        add_file "$file"
    done < <(find "$TARGET" -mindepth 1 \
        \( -type d \( -name node_modules -o -name .git -o -name dist -o -name build -o -name .next -o -name vendor \
            -o -name coverage -o -name .venv -o -name venv -o -name __pycache__ -o -name target -o -name bin -o -name obj \
            -o -name test -o -name tests -o -name __tests__ -o -name spec -o -name e2e \) -prune \) \
        -o \( -type d -path '*/storage/framework' -prune \) \
        -o \( -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.cjs' -o -name '*.ts' -o -name '*.py' -o -name '*.rb' \
            -o -name '*.php' -o -name '*.go' -o -name '*.java' -o -name '*.kt' -o -name '*.cs' -o -name '*.sql' -o -name '*.prisma' \) \
            ! -name '*.min.*' ! -name '*.d.ts' ! -name '*.test.*' ! -name '*.spec.*' ! -name '*_test.go' ! -name '*_test.py' \
            ! -name 'test_*.py' ! -name '*_spec.rb' ! -name '*Test.java' ! -name '*Tests.cs' -print0 \))
else
    ROOT="$(dirname "$TARGET")"
    add_file "$TARGET"
fi

RESULTS="$(mktemp)"
trap 'rm -f "$RESULTS"' EXIT

Q="[\"'\`]"
MONEY="(price|amount|balance|cost|subtotal|fee|salary|total)"

report() {
    awk -v rule="$1" -v check="$2" -v ex="${3:-}" -v root="$ROOT" '
    {
        i = index($0, ":")
        file = substr($0, 1, i - 1)
        rest = substr($0, i + 1)
        j = index(rest, ":")
        n = substr(rest, 1, j - 1)
        code = substr(rest, j + 1)
        sub(/\r$/, "", code)
        if (ex != "" && tolower(code) ~ tolower(ex)) next
        if (index(file, root "/") == 1) file = substr(file, length(root) + 2)
        sub(/^[ \t]+/, "", code)
        print rule " " check " " file ":" n ": " substr(code, 1, 120)
    }' >>"$RESULTS"
}

scan() {
    if [ "${#FILES[@]}" -gt 0 ]; then
        grep -nHE -- "$1" "${FILES[@]}" 2>/dev/null || true
    fi
}

scan_i() {
    if [ "${#FILES[@]}" -gt 0 ]; then
        grep -inHE -- "$1" "${FILES[@]}" 2>/dev/null || true
    fi
}

scan_sql_i() {
    if [ "${#SQL_FILES[@]}" -gt 0 ]; then
        grep -inHE -- "$1" "${SQL_FILES[@]}" 2>/dev/null || true
    fi
}

scan_i "pass(word|wd)?.*(md5|sha1|sha256|sha512|createhash)|(md5|sha1|sha256|sha512|createhash).*pass(word|wd)?" \
    | report B1 weak-password-hash

scan_i "(findById|findByPk|findUnique|findOne|findFirst|get_object_or_404|objects[.]get|[.]find)[(][^)]*(req[.](params|query|body)|request[.](args|params|GET|POST|query_params|path_params)|params\[)" \
    | report B2 unscoped-lookup "owner|tenant|user_?id|account_?id|org_?id|current_?user|req[.]user|request[.]user"
scan_i "(req[.]body|request[.](json|data|form|POST))([.]|\[$Q?)(role|is_?admin|tenant_?id|owner_?id|user_?id|account_?id|permissions?)([^a-z_]|$)" \
    | report B2 client-authority
scan "(create|update|insert|build|assign|fill|updateOne|insertOne|update_attributes|merge)[(][^)]*req[.]body[[:space:]]*[),}]|[*][*]request[.](data|json|POST|form)|params[.]permit!" \
    | report B2 mass-assignment

scan "[.](findMany|findAll)[(][[:space:]]*[)]|[.]find[(][[:space:]]*(\{[[:space:]]*\})?[[:space:]]*[)]|objects[.]all[(][)]|[.]query[(][^)]*[)][.]all[(][)]" \
    | report B5 unbounded-query "limit|take|paginat|first|slice|[[]:"
scan_i "select[[:space:]]+[*][[:space:]]+from" \
    | report B5 select-star "exists[[:space:]]*[(]"
scan_i "offset[[:space:]]+([$][0-9]|:[a-z_]+|[?]|%s|[0-9]+)|[.](skip|offset)[(]" \
    | report B5 offset-pagination

scan_sql_i "create[[:space:]]+(unique[[:space:]]+)?index[[:space:]]" \
    | report B6 blocking-index "concurrently"
scan "add_index[[:space:]]" \
    | report B6 blocking-index "concurrently"

scan "(requests|httpx)[.](get|post|put|patch|delete|head|request)[(]" \
    | report B8 no-timeout "timeout"
scan "(^|[^A-Za-z0-9_.])fetch[(]" \
    | report B8 no-timeout "signal|timeout"
scan "axios[.](get|post|put|patch|delete|request)[(]" \
    | report B8 no-timeout "timeout"
scan "http[.](Get|Post|Head|PostForm)[(]|&http[.]Client\{\}|http[.]DefaultClient" \
    | report B8 no-timeout

scan "console[.](log|info|debug|warn|error)[(]|^[[:space:]]*print[(]|System[.](out|err)[.]print|fmt[.]Print(ln|f)?[(]|^[[:space:]]*puts[[:space:]]|var_dump[(]|print_r[(]|Console[.]Write(Line)?[(]" \
    | report B9 unstructured-log
scan_i "(^|[^a-z0-9_])(log|logger|logging|console|print)([.][a-z]+)?[(].*[,(+{][[:space:]]*[a-z_.]*(password|passwd|secret|token|authorization|api_?key|card_?number|cvv|ssn)" \
    | report B9 sensitive-log "redact|mask"

scan "catch[[:space:]]*([(][^)]*[)])?[[:space:]]*\{[[:space:]]*\}|except([[:space:]][^:]*)?:[[:space:]]*pass([[:space:]]|$)|[.]catch[(][[:space:]]*([(][^)]*[)]|[A-Za-z_]*)[[:space:]]*=>[[:space:]]*(\{[[:space:]]*\}|null|undefined)[[:space:]]*[)]|rescue[[:space:]]+nil" \
    | report B11 swallowed-error
scan "^[[:space:]]*except[[:space:]]*:" \
    | report B11 bare-except
scan "(res[.]|return|Response|jsonify|reply[.]).*((err|error|e|ex)[.]stack|format_exc[(]|str[(](e|err|exc|ex|error)[)])|res[.](status[(][0-9]+[)][.])?(send|json)[(](err|error|e)[)]" \
    | report B11 leaked-error

scan "(readFileSync|writeFileSync|appendFileSync|execSync|spawnSync|pbkdf2Sync|scryptSync|hashSync|compareSync)[(]|(^|[^A-Za-z0-9_])time[.]sleep[(]|Thread[.]sleep[(]|[.]Result([^A-Za-z(]|$)|[.]Wait[(][)]|GetAwaiter[(][)][.]GetResult" \
    | report B12 blocking-call

scan_i "(mongodb([+]srv)?|postgres(ql)?|mysql|mariadb|rediss?|amqps?|mssql)://[^:/\"'[:space:]@]+:[^@/\"'[:space:]]+@" \
    | report B13 credentials-in-dsn "[$][{]|process[.]env|environ|getenv|ENV[[]"
scan_i "(secret|key|token|password|passwd)[a-z_]*[[:space:]]*(\|\||[?][?])[[:space:]]*$Q[^\"'\`]+|(getenv|environ[.]get)[(][[:space:]]*[\"'][a-z_]*(secret|key|token|password)[a-z_]*[\"'][[:space:]]*,[[:space:]]*[\"'][^\"']+[\"']" \
    | report B13 secret-fallback

scan_i "$MONEY[a-z_]*[[:space:]]*[:=][[:space:]]*(parsefloat|float)[(]|$MONEY[a-z_]*[[:space:]]+(float|double|real|float32|float64)([^a-z0-9]|$)|(float|double|float64)[[:space:]]+$MONEY|$MONEY[a-z_]*[[:space:]]*=[[:space:]]*(models[.]floatfield|column[(][[:space:]]*float|db[.]column[(][[:space:]]*db[.]float|mapped_column[(][[:space:]]*float)" \
    | report B14 float-money
scan "datetime[.](utcnow|now)[(][[:space:]]*[)]|DateTime[.]Now([^A-Za-z]|$)" \
    | report B14 naive-datetime
scan_sql_i "[[:space:]]timestamp([[:space:]]*,|[[:space:]]+(not|null|default)|[[:space:]]*$)" \
    | report B14 naive-datetime

if [ "${#FILES[@]}" -gt 0 ]; then
    awk -v root="$ROOT" '
    function rel(f) {
        if (index(f, root "/") == 1) return substr(f, length(root) + 2)
        return f
    }
    function emit(rule, check, n, text) {
        sub(/^[ \t]+/, "", text)
        print rule " " check " " rel(FILENAME) ":" n ": " substr(text, 1, 120)
    }
    BEGIN {
        db = "prisma[.][A-Za-z_]+[.][A-Za-z]+[(]|[.]objects[.](get|filter|exclude|count|create)[(]|session[.](query|get|execute|scalar|scalars)[(]|cursor[.]execute[(]|[.](query|execute|raw)[(]|[.](findOne|findById|findByPk|findUnique|findFirst|findMany|findAll|find_by|countDocuments|aggregate|populate|where)[(]|[Rr]epo(sitory)?[.](find|get|count|exists|load)|(ToListAsync|FirstOrDefaultAsync|SingleOrDefaultAsync|FindAsync|CountAsync)[(]|db[.](First|Find|Where|Raw|Get|Select|Query|QueryRow|Exec)[(]|knex[(]|[A-Z][A-Za-z0-9_]*[.](find|find_by)[(]"
        http = "(^|[^A-Za-z0-9_.])fetch[(]|axios([.](get|post|put|patch|delete|request))?[(]|(requests|httpx)[.](get|post|put|patch|delete)[(]|http[.](Get|Post)[(]|[.](GetAsync|PostAsync|getForObject|getForEntity)[(]"
        cb = "[.](forEach|map|flatMap|each|each_with_index|find_each|for_each)[ \t]*[({]|[.]each[ \t]+do"
        stmt = "^[ \t]*(async[ \t]+)?(for|foreach|while)([ \t(]|$)"
        comp = "[ \t]for[ \t]+[A-Za-z_][A-Za-z0-9_, ]*[ \t]in[ \t]"
    }
    FNR == 1 { loop_line = 0; prev = ""; prev_n = 0 }
    {
        line = $0
        sub(/\r$/, "", line)
        if (line ~ /^[ \t]*$/) next
        match(line, /^[ \t]*/)
        indent = RLENGTH
        if (loop_line > 0 && (indent <= loop_indent || FNR - loop_line > 12)) loop_line = 0
        hit = ""
        if (loop_line > 0) {
            if (line ~ db) hit = "query-in-loop"
            else if (line ~ http) hit = "http-in-loop"
        }
        if (hit == "" && match(line, cb)) {
            rest = substr(line, RSTART + RLENGTH)
            if (rest ~ db) hit = "query-in-loop"
            else if (rest ~ http) hit = "http-in-loop"
        }
        if (hit == "" && line !~ stmt && line ~ comp) {
            if (line ~ db) hit = "query-in-loop"
            else if (line ~ http) hit = "http-in-loop"
        }
        if (hit != "") emit("B4", hit, FNR, line)
        if (line ~ stmt || line ~ cb) {
            loop_line = FNR
            loop_indent = indent
        }
        if (line ~ /^[ \t]*(pass|\})[ \t]*$/) {
            if ((line ~ /pass/ && prev ~ /^[ \t]*except[^:]*:[ \t]*$/) || (line ~ /\}/ && prev ~ /catch[ \t]*([(][^)]*[)])?[ \t]*\{[ \t]*$/)) {
                emit("B11", "swallowed-error", prev_n, prev)
            }
        }
        prev = line
        prev_n = FNR
    }
    ' "${FILES[@]}" >>"$RESULTS"
fi

echo "BACKEND SCAN: $TARGET"
echo "FILES_SCANNED: ${#FILES[@]}"
echo ""
sort -t " " -k1.2,1n -k2,2 -k3,3 "$RESULTS"
echo ""
echo "FINDINGS: $(wc -l <"$RESULTS" | tr -d ' ')"
for rule in B1 B2 B4 B5 B6 B8 B9 B11 B12 B13 B14; do
    echo "$rule: $(grep -c "^$rule " "$RESULTS" || true)"
done
echo ""
echo "Each line is a lead, not a confirmed finding. Read it in context before reporting."
