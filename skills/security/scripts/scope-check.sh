#!/bin/bash
set -euo pipefail

SCOPE_FILE="${1:?Usage: scope-check.sh <scope-file> <target-url-or-host>}"
TARGET="${2:?Usage: scope-check.sh <scope-file> <target-url-or-host>}"

if [ ! -f "$SCOPE_FILE" ]; then
    echo "ERROR: scope file $SCOPE_FILE not found. Run the scope phase first." >&2
    exit 3
fi

host="$TARGET"
host="${host#*://}"
host="${host%%/*}"
host="${host%%\?*}"
host="${host%%#*}"
host="${host##*@}"
host="${host%%:*}"
host="$(printf '%s' "$host" | tr '[:upper:]' '[:lower:]')"

if [ -z "$host" ]; then
    echo "ERROR: could not parse a host from '$TARGET'." >&2
    exit 3
fi

extract_list() {
    grep -iE "^[-*[:space:]]*$1" "$SCOPE_FILE" 2>/dev/null | head -1 | sed -E "s/^[-*[:space:]]*$1[[:space:]]*:?[[:space:]]*//I" || true
}

IN_LIST="$(extract_list 'in.?scope')"
OUT_LIST="$(extract_list 'out.?of.?scope')"

matches_list() {
    local h="$1" list="$2" entry wildcard base
    printf '%s\n' "$list" | tr ',' '\n' | while IFS= read -r entry; do
        entry="$(printf '%s' "$entry" | tr '[:upper:]' '[:lower:]' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
        entry="${entry#http://}"
        entry="${entry#https://}"
        entry="${entry%%/*}"
        entry="${entry%%:*}"
        [ -z "$entry" ] && continue
        wildcard=0
        case "$entry" in
            \*.*) wildcard=1; base="${entry#\*.}" ;;
            .*)   wildcard=1; base="${entry#.}" ;;
            *)    base="$entry" ;;
        esac
        [ -z "$base" ] && continue
        if [ "$h" = "$base" ]; then
            echo "hit:$entry"
        elif [ "$wildcard" -eq 1 ] && [ "${h%".$base"}" != "$h" ]; then
            echo "hit:$entry"
        fi
    done | head -1
}

is_local() {
    case "$1" in
        localhost|127.0.0.1|::1|*.localhost|*.test) return 0 ;;
        10.*|192.168.*) return 0 ;;
        172.1[6-9].*|172.2[0-9].*|172.3[0-1].*) return 0 ;;
        *) return 1 ;;
    esac
}

OUT_HIT="$(matches_list "$host" "$OUT_LIST")"
if [ -n "$OUT_HIT" ]; then
    echo "OUT_OF_SCOPE: $host matches out-of-scope entry (${OUT_HIT#hit:}). Do not test it."
    exit 2
fi

IN_HIT="$(matches_list "$host" "$IN_LIST")"
if [ -n "$IN_HIT" ]; then
    echo "IN_SCOPE: $host matches in-scope entry (${IN_HIT#hit:})."
    exit 0
fi

if is_local "$host"; then
    echo "IN_SCOPE: $host is a local or private-range host (default authorized). Confirm it is your own build."
    exit 0
fi

echo "NOT_LISTED: $host is not in the in-scope list and is not a local host. Add it to $SCOPE_FILE with authorization before testing."
exit 1
