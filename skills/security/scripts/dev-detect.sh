#!/bin/bash
set -euo pipefail

PROJECT="${1:-.}"
PORTS="${2:-3000,3001,4000,4200,5000,5173,5174,8000,8080,8081,8888,9000}"

if command -v cygpath &>/dev/null; then
    PROJECT="$(cygpath -u "$PROJECT")"
fi

if [ ! -d "$PROJECT" ]; then
    echo "ERROR: project directory $PROJECT does not exist." >&2
    exit 1
fi

if ! printf '%s' "$PORTS" | grep -qE '^[0-9]+(,[0-9]+)*$'; then
    echo "ERROR: ports must be a comma-separated list of numbers, got '$PORTS'." >&2
    exit 1
fi

if ! command -v curl &>/dev/null; then
    echo "ERROR: curl is required." >&2
    exit 1
fi

STACK=()
has_dep() {
    grep -qE "\"$1\"[[:space:]]*:" "$PROJECT/package.json" 2>/dev/null
}
has_text() {
    grep -qiE "$2" "$PROJECT/$1" 2>/dev/null
}

if [ -f "$PROJECT/package.json" ]; then
    STACK+=("node")
    for dep in next vite react-scripts @angular/core nuxt @sveltejs/kit @remix-run/dev express fastify @nestjs/core; do
        has_dep "$dep" && STACK+=("$dep")
    done
fi
if [ -f "$PROJECT/requirements.txt" ] || [ -f "$PROJECT/pyproject.toml" ] || [ -f "$PROJECT/manage.py" ]; then
    STACK+=("python")
    for fw in django flask fastapi; do
        if has_text requirements.txt "^$fw" || has_text pyproject.toml "\"?$fw"; then
            STACK+=("$fw")
        fi
    done
fi
[ -f "$PROJECT/go.mod" ] && STACK+=("go")
if [ -f "$PROJECT/Gemfile" ]; then
    STACK+=("ruby")
    has_text Gemfile "gem ['\"]rails['\"]" && STACK+=("rails")
fi
if [ -f "$PROJECT/composer.json" ]; then
    STACK+=("php")
    has_text composer.json "laravel/framework" && STACK+=("laravel")
fi
if [ -f "$PROJECT/pom.xml" ] || [ -f "$PROJECT/build.gradle" ] || [ -f "$PROJECT/build.gradle.kts" ]; then
    STACK+=("java")
fi

DEV_COMMAND="none"
if has_dep dev; then
    DEV_COMMAND="npm run dev"
elif has_dep start; then
    DEV_COMMAND="npm start"
elif [ -f "$PROJECT/manage.py" ]; then
    DEV_COMMAND="python manage.py runserver"
elif [ -f "$PROJECT/Gemfile" ]; then
    DEV_COMMAND="bin/rails server"
elif [ -f "$PROJECT/artisan" ]; then
    DEV_COMMAND="php artisan serve"
fi

echo "DEV_DETECT: $PROJECT"
if [ "${#STACK[@]}" -eq 0 ]; then
    echo "STACK: unknown"
else
    echo "STACK: $(IFS=,; printf '%s' "${STACK[*]}" | sed 's/,/, /g')"
fi
echo "DEV_COMMAND: $DEV_COMMAND"

COUNT=0
FIRST="none"
IFS=',' read -ra PORT_LIST <<<"$PORTS"
for port in "${PORT_LIST[@]}"; do
    code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 2 "http://127.0.0.1:$port/" 2>/dev/null || true)"
    if [ -n "$code" ] && [ "$code" != "000" ]; then
        echo "LISTENING: http://127.0.0.1:$port (HTTP $code)"
        COUNT=$((COUNT + 1))
        [ "$FIRST" = "none" ] && FIRST="http://127.0.0.1:$port"
    fi
done

echo "LISTENING_COUNT: $COUNT"
echo "SUGGESTED_TARGET: $FIRST"
