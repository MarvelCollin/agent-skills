#!/bin/bash
set -euo pipefail

TARGET="${1:?Usage: grep-audit.sh <path>}"

if command -v cygpath &>/dev/null; then
    TARGET="$(cygpath -u "$TARGET")"
fi

if [ ! -e "$TARGET" ]; then
    echo "ERROR: $TARGET does not exist." >&2
    exit 1
fi

FILES=()
while IFS= read -r -d '' file; do
    FILES+=("$file")
done < <(find "$TARGET" \
    \( -type d \( -name node_modules -o -name .git -o -name dist -o -name build -o -name .next \
        -o -name vendor -o -name coverage -o -name .venv -o -name venv \) -prune \) \
    -o \( -type f \( -name '*.js' -o -name '*.ts' -o -name '*.jsx' -o -name '*.tsx' -o -name '*.py' \
        -o -name '*.rb' -o -name '*.php' -o -name '*.go' -o -name '*.java' -o -name '*.cs' \
        -o -name '*.env*' -o -name '*.yml' -o -name '*.yaml' -o -name '*.json' -o -name '*.sql' \) \
        ! -name '*.min.*' ! -name 'package-lock.json' -print0 \))

if [ "${#FILES[@]}" -eq 0 ]; then
    echo "No source files found under $TARGET."
    exit 0
fi

RESULTS="$(mktemp)"
trap 'rm -f "$RESULTS"' EXIT

flag() {
    local category="$1" pattern="$2"
    grep -nHIiE "$pattern" "${FILES[@]}" 2>/dev/null \
        | sed -E "s/^([^:]+:[0-9]+:)/[$category] \1/" >>"$RESULTS" || true
}

flag_cs() {
    local category="$1" pattern="$2"
    grep -nHIE "$pattern" "${FILES[@]}" 2>/dev/null \
        | sed -E "s/^([^:]+:[0-9]+:)/[$category] \1/" >>"$RESULTS" || true
}

flag_without() {
    local category="$1" pattern="$2" exclude="$3"
    grep -nHIiE "$pattern" "${FILES[@]}" 2>/dev/null \
        | grep -viE "^[^:]+:[0-9]+:.*($exclude)" \
        | sed -E "s/^([^:]+:[0-9]+:)/[$category] \1/" >>"$RESULTS" || true
}

flag_cs_without() {
    local category="$1" pattern="$2" exclude="$3"
    grep -nHIE "$pattern" "${FILES[@]}" 2>/dev/null \
        | grep -vE "^[^:]+:[0-9]+:.*($exclude)" \
        | sed -E "s/^([^:]+:[0-9]+:)/[$category] \1/" >>"$RESULTS" || true
}

AUTHORITY_NAMES="role|is_?admin|tenant_?id|owner_?id|user_?id|account_?id|permissions"
VALUE_NAMES="price|unit_?price|amount|total|subtotal|discount|fee|cost|balance|credits?|points|status|paid|is_?paid|verified|is_?verified|approved|plan|tier|is_?premium|step"

client_input_regex() {
    local names="$1"
    local request_chain="(req|request|ctx)[[:alnum:]_.]*\.(body|json|form|data|POST|GET|query|params|args|values)(\.get)?(\.($names)\b|[[:space:]]*[[(][[:space:]]*[\"']($names)[\"'])"
    local local_dotted="(^|[^[:alnum:]_.])(body|payload)\.($names)\b"
    local local_lookup="(^|[^[:alnum:]_.])(body|payload|data|params|json|form|input)(\.get)?[[:space:]]*[[(][[:space:]]*[\"']($names)[\"']"
    local destructured="\{[^}]*\b($names)\b[^}]*\}[[:space:]]*=[[:space:]]*(await[[:space:]]+)?(req|request)[[:alnum:]_.]*\.(body|json|form|data|query|params|args)"
    local php="\\\$_(POST|REQUEST)[[:space:]]*\[[[:space:]]*[\"']($names)[\"']|\\\$request->((input|get|post)\([\"'])?($names)\b"
    local ruby="params(\[[^]]*\])*\[:($names)\]|permit\([^)]*:($names)\b"
    local getter="(getParameter|FormValue|PostForm|PostFormValue)\([\"']($names)[\"']"
    echo "($request_chain)|($local_dotted)|($local_lookup)|($destructured)|($php)|($ruby)|($getter)"
}

ENV_WHOLE="process\.env([^.?[:alnum:]_[]|$)|os\.environ([^.[:alnum:]_[]|\.copy\(|\.items\(|$)|ENV\.(to_h|to_hash)\b|getenv\(\)|\\\$_(ENV|SERVER)([^[:alnum:]_[]|$)"

flag "sql-concat"        "(SELECT|INSERT|UPDATE|DELETE|FROM|WHERE)[^;]*[\"'][[:space:]]*\+|\+[[:space:]]*[\"'][^\"']*(SELECT|INSERT|UPDATE|DELETE|FROM|WHERE)"
flag "sql-interp"        "(execute|query|exec|cursor|raw|prepare)[[:space:]]*\(.*(\\\$\{|%s|f[\"']).*(SELECT|INSERT|UPDATE|DELETE|FROM|WHERE)"
flag "command-exec"      "(os\.system|subprocess\.(call|run|Popen).*shell[[:space:]]*=[[:space:]]*True|child_process|exec\(|execSync|popen|Runtime\.getRuntime|ProcessBuilder|shell_exec|passthru)"
flag_cs "code-eval"      "(^|[^.[:alnum:]_])(eval|new[[:space:]]+Function|Function[[:space:]]*\(|setTimeout[[:space:]]*\([[:space:]]*[\"'])|pickle\.loads|yaml\.load[[:space:]]*\(|Marshal\.load|ObjectInputStream"
flag "dangerous-dom"     "(innerHTML|outerHTML|document\.write|insertAdjacentHTML|dangerouslySetInnerHTML|v-html)"
flag "deserialize"       "(pickle\.loads|yaml\.load[[:space:]]*\((?!.*Loader)|unserialize\(|JSON\.parse[[:space:]]*\(.*(req|request|body))"
flag "weak-crypto"       "(\bMD5\b|\bSHA1\b|\bDES\b|\bRC4\b|Math\.random\(\).*(token|password|secret|key)|createCipher\()"
flag "hardcoded-secret"  "(api[_-]?key|secret|passwd|password|token|private[_-]?key|access[_-]?key)[[:space:]]*[:=][[:space:]]*[\"'][A-Za-z0-9_/+.=-]{12,}[\"']"
flag "aws-key"           "AKIA[0-9A-Z]{16}"
flag "private-key-block" "BEGIN (RSA |EC |OPENSSH |DSA |PGP )?PRIVATE KEY"
flag "disabled-tls"      "(verify[[:space:]]*=[[:space:]]*False|rejectUnauthorized[[:space:]]*:[[:space:]]*false|InsecureSkipVerify[[:space:]]*:[[:space:]]*true|CURLOPT_SSL_VERIFYPEER.*(0|false))"
flag "permissive-cors"   "(Access-Control-Allow-Origin.*\*|cors\(\)|origin[[:space:]]*:[[:space:]]*[\"']\*[\"'])"
flag "debug-on"          "(DEBUG[[:space:]]*=[[:space:]]*True|app\.debug[[:space:]]*=[[:space:]]*true|NODE_ENV.*development.*production)"
flag_cs_without "client-env-secret" "(^|[^A-Za-z0-9_])(NEXT_PUBLIC|NUXT_PUBLIC|EXPO_PUBLIC|VITE|REACT_APP|VUE_APP|GATSBY|PUBLIC)_[A-Z0-9_]*(SECRET|PRIVATE|PASSWORD|PASSWD|TOKEN|SERVICE_?ROLE|CREDENTIAL|API_?KEY|DATABASE_?URL|DB_?URL)" "PUBLISHABLE|ANON|SEARCH|MAPS|SITE_?KEY|PUBLIC_?KEY|CLIENT_?KEY"
flag "client-token-storage" "((local|session)Storage\.(set|get)Item[[:space:]]*\([^,)]*(token|jwt|session|secret|password|api_key|auth|bearer|credential)|document\.cookie[[:space:]]*\+?=[^=].*(token|jwt|session|auth))"
flag "sourcemap-public"  "(productionBrowserSourceMaps[[:space:]]*:[[:space:]]*true|devtool[[:space:]]*:[[:space:]]*[\"'](inline-)?source-map[\"']|sourcemap[[:space:]]*:[[:space:]]*true|GENERATE_SOURCEMAP[[:space:]]*[:=][[:space:]]*[\"']?true)"
flag "env-dump"          "((send|json|jsonify|render|write|return|Response|reply|log|print|dump|echo)[^;]*($ENV_WHOLE)|phpinfo[[:space:]]*\()"
flag_without "jwt-unverified" "jwt\.decode[[:space:]]*\(" "algorithms|secret|key|public|verify_signature"
flag "jwt-unverified"    "(verify_signature[\"']?[[:space:]]*[:=][[:space:]]*false|ignore_?expiration[\"']?[[:space:]]*[:=][[:space:]]*true|alg(orithms?)?[\"']?[[:space:]]*[:=][[:space:]]*(\[[^]]*)?[\"']none[\"'])"
flag_without "cookie-flags" "(res\.cookie|set_?cookie)[[:space:]]*\(" "http_?only"
flag "client-authority"  "$(client_input_regex "$AUTHORITY_NAMES")"
flag "client-value"      "$(client_input_regex "$VALUE_NAMES")"
flag "client-header"     "(headers|header|META|getHeader|get_header)[^;]{0,12}x[-_](user|role|tenant|account|org|admin|uid)"

LC_ALL=C sort -u "$RESULTS" -o "$RESULTS"

echo "GREP AUDIT: $TARGET"
echo "FILES_SCANNED: ${#FILES[@]}"
echo ""
sort "$RESULTS" | sed "s#$TARGET/##"
echo ""
echo "LEADS: $(wc -l <"$RESULTS" | tr -d ' ')"
echo ""
echo "Each line is a lead, not a confirmed finding. Read it in context before reporting."
