#!/bin/bash
set -euo pipefail

TARGET="${1:?Usage: scope-init.sh <local-url-host-or-source-path> [output-dir]}"
OUT_DIR="${2:-.}"

if command -v cygpath &>/dev/null; then
    OUT_DIR="$(cygpath -u "$OUT_DIR")"
fi

if [ ! -d "$OUT_DIR" ]; then
    echo "ERROR: output directory $OUT_DIR does not exist." >&2
    exit 1
fi

is_local() {
    case "$1" in
        localhost|127.0.0.1|::1|*.localhost|*.test) return 0 ;;
        10.*|192.168.*) return 0 ;;
        172.1[6-9].*|172.2[0-9].*|172.3[0-1].*) return 0 ;;
        *) return 1 ;;
    esac
}

slugify() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

SOURCE_PATH="$TARGET"
if command -v cygpath &>/dev/null; then
    case "$TARGET" in
        *://*) ;;
        *) SOURCE_PATH="$(cygpath -u "$TARGET" 2>/dev/null || printf '%s' "$TARGET")" ;;
    esac
fi

if [ -d "$SOURCE_PATH" ]; then
    KIND="source"
    ABS="$(cd "$SOURCE_PATH" && pwd)"
    SLUG="$(slugify "$(basename "$ABS")")"
    IN_SCOPE="$ABS"
    AUTH="own source tree, static code review, nothing runs against a live target"
    HOST="none"
else
    KIND="host"
    rest="${TARGET#*://}"
    rest="${rest%%/*}"
    rest="${rest%%\?*}"
    rest="${rest%%#*}"
    rest="${rest##*@}"
    HOST="$(printf '%s' "${rest%%:*}" | tr '[:upper:]' '[:lower:]')"
    PORT=""
    [ "$rest" != "${rest#*:}" ] && PORT="${rest#*:}"
    if [ -z "$HOST" ]; then
        echo "ERROR: could not parse a host or find a directory from '$TARGET'." >&2
        exit 1
    fi
    if ! is_local "$HOST"; then
        echo "ERROR: $HOST is not a local or private-range host. scope-init only covers your own dev builds. For any other host, state your authorization in chat and write scope.md by hand." >&2
        exit 1
    fi
    SLUG="$(slugify "$HOST${PORT:+-$PORT}")"
    IN_SCOPE="$HOST"
    AUTH="local dev build, owner request in chat on $(date +%Y-%m-%d)"
fi

ENGAGEMENT="$OUT_DIR/security-$SLUG-$(date +%Y%m%d)"
SCOPE_FILE="$ENGAGEMENT/scope.md"
mkdir -p "$ENGAGEMENT/evidence"

for f in recon.md findings.md notes.md; do
    [ -f "$ENGAGEMENT/$f" ] || : >"$ENGAGEMENT/$f"
done

if [ -f "$SCOPE_FILE" ]; then
    STATUS="existing"
else
    STATUS="created"
    cat >"$SCOPE_FILE" <<EOF
# Scope: $TARGET

- Authorization: $AUTH
- In scope: $IN_SCOPE
- Out of scope: none beyond the off-limits list below
- Target: $TARGET
- Test window: any
- Test account: seeded test user or one the developer creates
- Allowed actions: full non-destructive testing of the dev build, including proof payloads, auth and access control checks, and reading source and config
- Off-limits: production, third-party and payment services, DoS and floods, destructive writes, real user data
- Contact: the developer running this session
EOF
fi

echo "SCOPE_INIT: $TARGET"
echo "KIND: $KIND"
echo "HOST: $HOST"
echo "ENGAGEMENT_DIR: $ENGAGEMENT"
echo "SCOPE_FILE: $SCOPE_FILE"
echo "SCOPE_STATUS: $STATUS"
echo "AUTHORIZATION: $AUTH"
