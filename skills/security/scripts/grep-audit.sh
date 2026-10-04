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

echo "GREP AUDIT: $TARGET"
echo "FILES_SCANNED: ${#FILES[@]}"
echo ""
sort "$RESULTS" | sed "s#$TARGET/##"
echo ""
echo "LEADS: $(wc -l <"$RESULTS" | tr -d ' ')"
echo ""
echo "Each line is a lead, not a confirmed finding. Read it in context before reporting."
