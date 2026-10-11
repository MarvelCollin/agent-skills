#!/bin/bash
set -uo pipefail

if [ $# -lt 1 ] || [ -z "${1:-}" ]; then
    echo "Usage: prod-scan.sh <path>" >&2
    exit 1
fi

ARG="$1"
TARGET="$ARG"
if command -v cygpath &>/dev/null; then
    TARGET="$(cygpath -u "$TARGET")"
fi
if [ ! -e "$TARGET" ]; then
    echo "ERROR: $ARG does not exist." >&2
    exit 1
fi
if [ ! -d "$TARGET" ]; then
    echo "ERROR: $ARG is not a folder. Pass the project folder." >&2
    exit 1
fi
if ! cd "$TARGET"; then
    echo "ERROR: cannot open $ARG." >&2
    exit 1
fi
ROOT="$(pwd)"

TMP="$(mktemp -d)" || { echo "ERROR: cannot create a temp folder." >&2; exit 1; }
trap 'rm -rf "$TMP"' EXIT

find . -mindepth 1 \( -type d \( -name node_modules -o -name .git -o -name dist -o -name build -o -name .next -o -name out \
    -o -name coverage -o -name vendor -o -name .venv -o -name venv -o -name __pycache__ -o -name .svelte-kit -o -name .nuxt \
    -o -name .output -o -name .vercel -o -name .netlify -o -name .turbo -o -name .astro -o -name .cache \
    -o -name test -o -name tests -o -name __tests__ -o -name e2e -o -name cypress \) -prune \) -o -type f -print 2>/dev/null \
    | sed 's|^\./||' | LC_ALL=C sort >"$TMP/all"

KEY_RE='AKIA[0-9A-Z]{16}|sk_live_[0-9A-Za-z]{10,}|ghp_[0-9A-Za-z]{30,}|xox[abp]-[0-9A-Za-z-]{10,}|AIza[0-9A-Za-z_-]{30,}|sk-ant-[0-9A-Za-z_-]{20,}|sk-proj-[0-9A-Za-z_-]{20,}|sk-[0-9A-Za-z]{20,}|-----BEGIN ([A-Z]+ )?PRIVATE KEY-----'
GITSTATE="norepo"
COMMITS=0
GI=""
: >"$TMP/tracked"
: >"$TMP/histp"
: >"$TMP/envh"
if ! command -v git &>/dev/null; then
    GITSTATE="nogit"
elif [ "$(git -C "$ROOT" rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ]; then
    GITSTATE="ok"
    COMMITS="$(git -C "$ROOT" rev-list --all --count -- . 2>/dev/null | tr -d '\r')"
    git -C "$ROOT" ls-files -- '*.env' '*.env.*' >"$TMP/tracked" 2>/dev/null
    git -C "$ROOT" log --all -E "-G$KEY_RE" -p --no-color --no-ext-diff --format='@%h' --relative -- . 2>/dev/null | head -n 20000 >"$TMP/histp"
    git -C "$ROOT" log --all --diff-filter=A --format='@%h' --name-only --relative -- '*.env' '*.env.*' >"$TMP/envh" 2>/dev/null
    if [ ! -f .gitignore ]; then
        top="$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null | tr -d '\r')"
        [ -n "$top" ] && [ -f "$top/.gitignore" ] && GI="$top/.gitignore"
    fi
fi
[ -f .gitignore ] && GI=".gitignore"
if command -v gitleaks &>/dev/null; then
    TOOL="gitleaks is installed, run gitleaks git for a full scan"
elif command -v trufflehog &>/dev/null; then
    TOOL="trufflehog is installed, run trufflehog git file://. for a full scan"
else
    TOOL="gitleaks not installed so this is a pattern search only"
fi

RX=""
expand_rx() {
    local s="$1" re='^(.*)(\[[^]]*\]|[A-Za-z0-9])\{([0-9]+)(,?)\}(.*)$' pre atom n comma post rep i
    while [[ $s =~ $re ]]; do
        pre="${BASH_REMATCH[1]}"
        atom="${BASH_REMATCH[2]}"
        n="${BASH_REMATCH[3]}"
        comma="${BASH_REMATCH[4]}"
        post="${BASH_REMATCH[5]}"
        rep=""
        for ((i = 0; i < n; i++)); do rep="$rep$atom"; done
        [ -n "$comma" ] && rep="$rep$atom*"
        s="$pre$rep$post"
    done
    RX="$s"
}

Q="[\"'\`]"
export CP_LIST="$TMP/all" CP_TRACKED="$TMP/tracked" CP_HISTP="$TMP/histp" CP_ENVH="$TMP/envh"
export CP_ARG="$ARG" CP_GITSTATE="$GITSTATE" CP_COMMITS="${COMMITS:-0}" CP_GI="$GI" CP_TOOL="$TOOL"
export CP_NOTFOUND='^(src/)?app/(.*/)?not-found\.(js|jsx|ts|tsx|mdx)$|^(src/)?pages/404\.(js|jsx|ts|tsx|astro|md|mdx|vue|html)$|(^|/)404\.html?$|(^|/)\+error\.svelte$|(^|/)error\.vue$'
export CP_CATCHALL='\[\[?\.\.\.[A-Za-z0-9_]*\]\]?|(^|/)routes/\$\.(js|jsx|ts|tsx)$'
export CP_PAGE_SKIP='(^|/)pages/api/|(^|/)_(app|document|error)\.|(^|/)(404|500|not-found|\+error)\.|(^|/)(api|resources?)\.|\.server\.|(^|/)google[0-9a-f]+\.html$'
export CP_LAYOUT='(^|/)layout\.(js|jsx|ts|tsx)$|^(src/)?pages/_(app|document)\.|(^|/)layouts?/|(^|/)\+layout\.svelte$|(^|/)app\.vue$|(^|/)nuxt\.config\.|^app/root\.|(^|/)index\.html?$|^src/app\.html$'
export CP_TITLE='<title|export const metadata|generateMetadata|useHead\(|useSeoMeta\(|<Helmet|document\.title|export (const|function|let) meta|<NextSeo|<([A-Z][A-Za-z]*Layout|Layout|SEO|Seo|Head|Meta)[^>]*title='
export CP_DESC="name=${Q}?description|description[[:space:]]*:|<NextSeo|<([A-Z][A-Za-z]*Layout|Layout|SEO|Seo|Head|Meta)[^>]*description="
export CP_TW="twitter:card|card[[:space:]]*:[[:space:]]*${Q}summary"
export CP_ICONS="${Q}icons${Q}|icons[[:space:]]*:"
export CP_ROBOTS_ROUTE_DIS="disallow[[:space:]]*:[[:space:]]*${Q}/${Q}"
export CP_VIEWPORT="name=${Q}viewport|export const viewport|viewport[[:space:]]*:"
export CP_RESP="@media[^{]*(min|max)-width|@container|[ \"'\`](sm|md|lg|xl|2xl):[a-z]"
export CP_STICKY="(fixed|sticky)[^\"']*bottom-0|bottom-0[^\"']*(fixed|sticky)|position:[[:space:]]*(fixed|sticky)"
export CP_LOADING='isLoading|isPending|loading[[:space:]]*(&&|\?)|<Suspense|\{#await|Loading\.\.\.|<Spinner|spinner'
export CP_FETCH="fetch\(|useQuery|useSWR|axios|getDocs|onSnapshot|useFetch|useAsyncData|\.from\(${Q}[a-z_]+${Q}\)\.select"
export CP_FORM='<form|<Form[ >]|useForm\(|onSubmit|handleSubmit|use:enhance|<v-form'
export CP_FERR='FormMessage|ErrorMessage|fieldErrors|formState|errors\.[A-Za-z_]+|errors\[|setError\(|\$errors|setCustomValidity|validationErrors'
export CP_OKH='thank you|thanks for|isSubmitted|isSubmitSuccessful|isSuccess|setSuccess|toast\.success|successMessage|status === .success'
export CP_PRIV_PAGE='(^|/)[^/]*privacy[^/]*(/[^/]*)?\.(js|jsx|ts|tsx|md|mdx|astro|vue|svelte|html?)$'
export CP_PRIV_LINK="(href|to)=[{]?${Q}?[^\"'\` >}]*privacy"
export CP_TERMS_PAGE='(^|/)(tos|[^/]*terms[^/]*|[^/]*conditions[^/]*)(/[^/]*)?\.(js|jsx|ts|tsx|md|mdx|astro|vue|svelte|html?)$'
export CP_TERMS_LINK="(href|to)=[{]?${Q}?[^\"'\` >}]*(terms|/tos|conditions)"
export CP_EXT_LINK="(href|to)=[{]?${Q}?https?://"
export CP_AN='gtag\(|googletagmanager\.com|google-analytics\.com|react-ga|GoogleAnalytics|plausible\.io|next-plausible|plausible-tracker|posthog|umami|@vercel/analytics|usefathom|fathom-client|mixpanel|segment\.(com|io)|@segment/|@amplitude/|amplitude\.com|matomo|piwik|simpleanalytics|cloudflareinsights|clarity\.ms|hotjar|fbq\(|connect\.facebook\.net'
export CP_PF='plausible\.io|next-plausible|plausible-tracker|umami|@vercel/analytics|usefathom|fathom-client|simpleanalytics|cloudflareinsights|matomo|piwik'
export CP_TRACK='gtag\(|googletagmanager\.com|google-analytics\.com|react-ga|GoogleAnalytics|posthog|mixpanel|segment\.(com|io)|@segment/|@amplitude/|amplitude\.com|clarity\.ms|hotjar|fbq\(|connect\.facebook\.net|snap\.licdn\.com|analytics\.tiktok\.com|intercom|hs-scripts\.com'
export CP_CONSENT="cookieconsent|cookie-consent|react-cookie-consent|vanilla-cookieconsent|cookiebot|onetrust|osano|klaro|tarteaucitron|iubenda|termly|usercentrics|cookiehub|CookieBanner|ConsentBanner|cookie-banner|consent-banner|gtag\(${Q}consent|ad_storage|analytics_storage"
expand_rx "${Q}(G|GTM)-X{4,}|${Q}UA-X{4,}|data-domain=${Q}(example\.com|yourdomain|your-domain)|(G|GTM)-XXXX"; export CP_PHID="$RX"
expand_rx 'lorem ipsum|dolor sit amet|example\.(com|org|net)|123 main st|\(?555\)?[-. ][0-9]{3}[-. ]?[0-9]{4}|555-01[0-9]{2}|john doe|jane doe|(^|[^a-z])acme([^a-z]|$)|your company|company name|your@email|yourdomain\.com'; export CP_PH="$RX"
export CP_TODO='(^|[^A-Za-z])(TODO|TBD|FIXME)([^A-Za-z]|$)'
export CP_INSECURE="(src|href|action)=${Q}http://"
export CP_SITE="metadataBase|(^|[^A-Za-z_])site[[:space:]]*:[[:space:]]*${Q}https?://|siteUrl[[:space:]]*[:=]|SITE_URL[[:space:]]*="
export CP_PUB='(NEXT_PUBLIC|VITE|REACT_APP|EXPO_PUBLIC|NUXT_PUBLIC|VUE_APP|GATSBY|PUBLIC)_[A-Z0-9_]*(SECRET|PRIVATE|PASSWORD|PASSWD|TOKEN|SERVICE_?ROLE|CREDENTIAL|API_?KEY|DATABASE_?URL|DB_?URL)'
expand_rx 'sk_live_[0-9A-Za-z]{8,}|rk_live_[0-9A-Za-z]{8,}|AKIA[0-9A-Z]{16}|gh[pousr]_[0-9A-Za-z]{30,}|xox[abpr]-[0-9A-Za-z-]{10,}|sk-ant-[0-9A-Za-z_-]{20,}|sk-proj-[0-9A-Za-z_-]{20,}|sk-[0-9A-Za-z]{20,}|-----BEGIN ([A-Z]+ )?PRIVATE KEY-----'; export CP_HARD="$RX"
export CP_SRCMAP="productionBrowserSourceMaps[[:space:]]*:[[:space:]]*true|sourcemap[[:space:]]*:[[:space:]]*true|GENERATE_SOURCEMAP[[:space:]]*=[[:space:]]*true|devtool[[:space:]]*:[[:space:]]*${Q}(inline-)?source-map${Q}"
export CP_OPENRULE='allow[[:space:]]+[^:;]*(write|create|update|delete)[^:;]*(;|:[[:space:]]*if[[:space:]]+true)|request\.time[[:space:]]*<|"\.(read|write)"[[:space:]]*:[[:space:]]*"?true'
export CP_ROLE='\.role[[:space:]]*(===|!==|==|!=)|role[[:space:]]*(===|!==|==|!=)|isAdmin|is_admin|requireAdmin|requireRole|adminOnly|hasRole|checkRole|is_staff|is_superuser|@Roles|RolesGuard|staff_member_required|permission_required|user_passes_test|authorize\(|can\('
export CP_ADMIN_ROUTE="(get|post|put|patch|delete|use|all|route)\([[:space:]]*${Q}(/api)?/admin"
export CP_USE_CLIENT="^[[:space:]]*${Q}use client${Q}"
export CP_RATE='express-rate-limit|rate-limiter-flexible|@upstash/ratelimit|@nestjs/throttler|@fastify/rate-limit|hono-rate-limiter|express-slow-down|slowapi|django-ratelimit|flask-limiter|rack-attack|ratelimit|rate_limit|rate-limit|throttle'
export CP_STORE='supabase\.storage|\.storage\.from\(|firebase/storage|getStorage\(|@aws-sdk/client-s3|aws-sdk|S3Client|@google-cloud/storage|cloudinary|uploadthing|@vercel/blob|minio|boto3'
export CP_PUBBUCKET="(createBucket|updateBucket)\([^)]*public${Q}?[[:space:]]*:[[:space:]]*true|[Aa][Cc][Ll]${Q}?[[:space:]]*[:=][[:space:]]*${Q}public-read|BlockPublicAcls${Q}?[[:space:]]*[:=][[:space:]]*false|allUsers"
export CP_SIGNED='createSignedUrl|getSignedUrl|generate_presigned_url|presign|signedUrl|SignedUrl'
export CP_API_PATH='^(src/)?pages/api/.*\.(js|jsx|ts|tsx|mjs)$|^(src/)?app/(.*/)?route\.(js|ts|mjs)$|(^|/)\+server\.(js|ts)$|(^|/)\+page\.server\.(js|ts)$|^server/(api|routes)/.*\.(js|ts)$'
export CP_API_CODE="(app|router|fastify|bp|blueprint)\.(get|post|put|patch|delete|all|route)\([[:space:]]*[\"'\`/]|@(app|router|bp|blueprint|api)\.(get|post|put|patch|delete|route)\(|^[[:space:]]*[\"']use server[\"']|@(Get|Post|Put|Patch|Delete)\(|@api_view|def (get|post|put|patch|delete)\(self"
export CP_INPUT='req\.body|req\.query|req\.params|request\.json\(|request\.formData\(|req\.json\(|request\.(json|form|args|get_json|data|POST|GET)|searchParams\.get|formData\.get|readBody\(|getQuery\('
export CP_PARSE='\.parse\(|\.safeParse\(|\.parseAsync\(|validate|celebrate\(|BaseModel|Serializer\(|is_valid\(|[Ss]chema|(^|[^A-Za-z0-9_])z\.(object|string|number|instanceof|array|enum|union|coerce)'
export CP_AUTH='getServerSession|(^|[^.A-Za-z_])auth\(\)|getUser\(|currentUser|requireAuth|requireUser|requireAdmin|requireSession|isAuthenticated|req\.user|request\.user|getToken\(|verifyToken|jwt\.verify|Depends\(get_current|login_required|@UseGuards|withAuth|clerkMiddleware|authMiddleware|getAuth\(|locals\.user|getSession\(|auth\.uid'
export CP_GLOBAL_AUTH='app\.use\([^)]*(auth|requireAuth|passport\.authenticate|jwt|session)|DEFAULT_PERMISSION_CLASSES|LoginRequiredMiddleware|APP_GUARD'
export CP_PUBLIC_API='(login|signin|sign-in|signup|sign-up|register|auth|webhooks?|health|healthz|status|public|contact|newsletter|subscribe|og|sitemap|robots|callback)'
export CP_SQLI='(SELECT|select) [^`]*(FROM|from) [^`]*\$\{|(INSERT INTO|insert into|DELETE FROM|delete from) [^`]*\$\{|(UPDATE|update) [A-Za-z_."]+ (SET|set) [^`]*\$\{|\$(query|execute)RawUnsafe|execute\([^)]*\.format\('"|\"(SELECT|INSERT|UPDATE|DELETE) [^\"]*\"[[:space:]]*\+|'(SELECT|INSERT|UPDATE|DELETE) [^']*'[[:space:]]*\+|f${Q}(SELECT|INSERT|UPDATE|DELETE|select|insert|update|delete) |${Q}(SELECT|INSERT|UPDATE|DELETE) [^\"']*%s[^\"']*${Q}[[:space:]]*%"
export CP_LOG='(console\.(log|info|debug|warn|error)|logger\.[a-z]+|logging\.[a-z]+|log\.[a-z]+|print)\(.*([,(+{][[:space:]]*[a-z_.]*(password|passwd|secret|token|authorization|api_?key|apikey|card_?number|cvv|ssn)|(req|request)\.(body|headers)\))'
export CP_TAMPER="(req\.body|request\.(json|data|form|POST)|body|data|input|args|payload)(\.|\[${Q}?)(role|isAdmin|is_admin|price|unitPrice|unit_price|amount|total|subtotal|discount|ownerId|owner_id|userId|user_id|status|plan|tier|credits|balance|isPaid|is_paid|paid|verified|isVerified|approved)([^A-Za-z0-9_]|\$)|\{[^}]*(role|price|amount|total|ownerId|owner_id|userId|user_id|status|isAdmin|plan|credits)[^}]*\}[[:space:]]*=[[:space:]]*(await[[:space:]]+)?(req\.body|req\.json\(\)|request\.json\(\)|body)"
export CP_MASS="(create|update|insert|upsert|updateOne|insertOne)\([^)]*(\.\.\.(req\.)?body|req\.body[[:space:]]*[),}])|data[[:space:]]*:[[:space:]]*req\.body|\*\*request\.(data|json)"
export CP_CLIENTW="\.from\(${Q}[a-z_]+${Q}\)\.(insert|update|upsert)\(.*(role|price|status|owner|user_id|is_admin|plan|credits|amount|total)"
export CP_UP="multer|formidable|busboy|multipart|UploadFile|FileField|ImageField|request\.files|req\.files?([^A-Za-z]|\$)|\.upload\(|createPresignedPost|uploadthing|@vercel/blob|uploadBytes|formData\.get\(${Q}(file|avatar|image|upload|photo|document)"
export CP_LIMIT='limits[[:space:]]*:|fileSize|maxFileSize|max_size|MAX_FILE_SIZE|maxSize|MAX_UPLOAD|content-length-range|\.size[[:space:]]*>|max_content_length|MAX_CONTENT_LENGTH|FILE_UPLOAD_MAX|DATA_UPLOAD_MAX|sizeLimit|bodySizeLimit|maxBodyLength'
export CP_CTYPE='file-type|fileTypeFromBuffer|fileTypeFromFile|python-magic|magic\.from|filetype\.guess|imghdr|sharp\(|magic-bytes|mmmagic'
export CP_SENDS='JSON\.stringify\(\{[^}]*(total|price|amount|role|status|discount|isAdmin)'
export CP_HASHR='(res\.(json|send)|json\(|jsonify|Response|return|reply\.send)[^;]*(password_?hash|hashed_?password|password_?digest|api_?secret|client_?secret|private_?key)'
export CP_SELALL="\.from\(${Q}(users|profiles|accounts|customers)${Q}\)\.select\((${Q}\*${Q})?\)"
export CP_DTO="select[[:space:]]*:[[:space:]]*\{|\.select\(${Q}[A-Za-z_, ]+${Q}\)|omit\(|pick\(|toDTO|toDto|toJSON|serialize|Serializer|response_model|exclude[[:space:]]*[:=]|fields[[:space:]]*="
export CP_COOKIE='res\.cookie\(|cookies\(\)\.set\(|cookies\.set\(|setCookie\(|set_cookie\(|Set-Cookie|serialize\('
export CP_WEBSTORE="(localStorage|sessionStorage)\.setItem\([[:space:]]*${Q}[^\"'\`]*(token|jwt|session|auth|access|refresh|bearer)"
export CP_SESS='next-auth|@auth/[a-z-]+|@clerk/[a-z-]+|@supabase/ssr|@supabase/auth-helpers-[a-z]+|lucia|better-auth|iron-session|@kinde-oss/[a-z-]+|express-session|cookie-session|firebase'
export CP_UNSCOPED='(findById|findByPk|findUnique|findOne|findFirst|get_object_or_404|objects\.get|\.find)\([^)]*(req\.(params|query|body)|request\.(args|params|GET|POST|query_params|path_params)|params\[|params\.)'
export CP_DEBUG="^[[:space:]]*(export[[:space:]]+)?(DEBUG|APP_DEBUG|FLASK_DEBUG|DJANGO_DEBUG)[[:space:]]*=[[:space:]]*${Q}?(true|1|on|yes)|app\.run\([^)]*debug[[:space:]]*=[[:space:]]*True"
export CP_CORS="Access-Control-Allow-Origin${Q}?[[:space:]]*[:,][[:space:]]*${Q}\*|origin[[:space:]]*:[[:space:]]*${Q}\*${Q}|origin[[:space:]]*:[[:space:]]*true|cors\(\)|CORS_ALLOW_ALL_ORIGINS[[:space:]]*=[[:space:]]*True|CORS_ORIGIN_ALLOW_ALL[[:space:]]*=[[:space:]]*True|allow_origins[[:space:]]*=[[:space:]]*\[${Q}\*"
export CP_STACK='(res\.|return|Response|jsonify|json\().*((err|error|e|ex)\.stack|format_exc\()|res\.(status\([0-9]+\)\.)?(send|json)\((err|error|e)\)'
export CP_HEADERS='helmet|Content-Security-Policy|Strict-Transport-Security|X-Frame-Options|X-Content-Type-Options|SECURE_HSTS_SECONDS|SECURE_SSL_REDIRECT|[Tt]alisman|securityHeaders|frame-ancestors|nuxt-security'
expand_rx 'AKIA[0-9A-Z]{16}'; export CP_K_AWS="$RX"
expand_rx 'sk_live_[0-9A-Za-z]{10,}'; export CP_K_STRIPE="$RX"
expand_rx 'ghp_[0-9A-Za-z]{30,}'; export CP_K_GITHUB="$RX"
expand_rx 'xox[abp]-[0-9A-Za-z-]{10,}'; export CP_K_SLACK="$RX"
expand_rx 'AIza[0-9A-Za-z_-]{30,}'; export CP_K_GOOGLE="$RX"
expand_rx 'sk-ant-[0-9A-Za-z_-]{20,}'; export CP_K_ANTHROPIC="$RX"
expand_rx 'sk-proj-[0-9A-Za-z_-]{20,}|sk-[0-9A-Za-z]{20,}'; export CP_K_OPENAI="$RX"
export CP_K_PRIVATE='-----BEGIN ([A-Z]+ )?PRIVATE KEY-----'
expand_rx 'gh[pousr]_[A-Za-z0-9]{20,}'; export CP_X_GH="$RX"
expand_rx 'xox[abpr]-[A-Za-z0-9-]{10,}'; export CP_X_SLACK="$RX"
expand_rx 'AIza[0-9A-Za-z_-]{30,}'; export CP_X_GOOGLE="$RX"
expand_rx 'sk-ant-[A-Za-z0-9_-]{10,}'; export CP_X_ANTHROPIC="$RX"
expand_rx 'sk-(proj-)?[A-Za-z0-9_-]{20,}'; export CP_X_OPENAI="$RX"
expand_rx 'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{5,}'; export CP_X_JWT="$RX"
export CP_X_QUOTED="([Ss]ecret|SECRET|[Tt]oken|TOKEN|[Pp]assword|PASSWORD|[Pp]asswd|PASSWD|[Aa]pi_?[Kk]ey|API_?KEY|[Pp]rivate_?[Kk]ey|PRIVATE_?KEY|[Cc]redential|CREDENTIAL|[Aa]ccess_?[Kk]ey|ACCESS_?KEY|SERVICE_ROLE|[Ss]ervice[Rr]ole|_KEY)[A-Za-z0-9_]*[\"']?[[:space:]]*[:=][[:space:]]*[\"'][^\"']+[\"']"

read -r -d '' MAIN_AWK <<'AWK'
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function base(p) { sub(/.*\//, "", p); return p }
function dirof(p) { if (p !~ /\//) return "."; sub(/\/[^\/]*$/, "", p); return p }
function classify(p,    n, l, env, ext, text, tags, mark) {
    n = base(p)
    l = tolower(n)
    if (l ~ /\.min\.|\.map$|\.d\.ts$|\.(test|spec)\.[a-z0-9]+$|_test\.(py|go)$|^test_.*\.py$/) return ""
    if (l ~ /^(package-lock\.json|npm-shrinkwrap\.json|pnpm-lock\.yaml|yarn\.lock|bun\.lockb?|composer\.lock|gemfile\.lock|poetry\.lock|pipfile\.lock|cargo\.lock|uv\.lock)$/) return ""
    if (l ~ /^(readme|changelog|contributing|license|code_of_conduct|security)(\.|$)/) return ""
    env = (l ~ /^\.env/)
    ext = ""
    if (match(l, /\.[a-z0-9]+$/)) ext = substr(l, RSTART + 1)
    text = env || ext ~ /^(js|jsx|ts|tsx|mjs|cjs|vue|svelte|astro|html|htm|md|mdx|css|scss|sass|less|json|json5|yaml|yml|toml|xml|txt|sql|rules|py|rb|php|go|java|kt|cs|webmanifest)$/ || l ~ /^(_headers|_redirects|dockerfile|procfile|cname|pipfile|gemfile)$/
    if (!text) return ""
    tags = "T"
    mark = (ext ~ /^(html|htm|jsx|tsx|js|vue|svelte|astro|mdx|md)$/)
    if (mark) tags = tags "M"
    if (mark || ext ~ /^(css|scss|sass|less)$/) tags = tags "W"
    if (ext ~ /^(js|jsx|ts|tsx|mjs|cjs|vue|svelte|astro|py|rb|php|go|java|kt|cs)$/) tags = tags "S"
    if (env) tags = tags "E"
    else tags = tags "N"
    if (ext == "sql") tags = tags "Q"
    if (l == "package.json") tags = tags "P"
    if (l ~ /^requirements.*\.txt$|^pyproject\.toml$|^pipfile$/) tags = tags "Y"
    if (mark || p ~ /(^|\/)(locales?|messages|i18n|content|data)\/.*\.(json|ya?ml)$/ || l ~ /\.config\.(js|mjs|cjs|ts)$/) tags = tags "H"
    return tags
}
function inset(i, set) {
    if (TG[i] == "") return 0
    if (length(set) == 1) return index(TG[i], set) > 0
    if (set == "API") return (i in isapi)
    if (set == "NONAPI") return index(TG[i], "S") > 0 && !(i in isapi)
    if (set == "PAGES") return (i in ispage)
    if (set == "LAYOUTS") return (i in islayout)
    if (set == "LIST") return (i in inlist)
    return 0
}
function first(set, re, ci,    i, n, s) {
    if (ci) re = tolower(re)
    for (i = 1; i <= np; i++) {
        if (!inset(i, set)) continue
        for (n = 1; n <= NL[i]; n++) {
            s = ci ? tolower(L[i, n]) : L[i, n]
            if (s ~ re) return P[i] ":" n
        }
    }
    return ""
}
function hits(set, re, ci, id, check, ex, exci,    i, n, s, c) {
    if (ci) re = tolower(re)
    if (exci) ex = tolower(ex)
    c = 0
    for (i = 1; i <= np; i++) {
        if (!inset(i, set)) continue
        for (n = 1; n <= NL[i]; n++) {
            s = ci ? tolower(L[i, n]) : L[i, n]
            if (s !~ re) continue
            if (ex != "") {
                s = exci ? tolower(L[i, n]) : L[i, n]
                if (s ~ ex) continue
            }
            addlead(id, check, P[i] ":" n, trim(L[i, n]))
            c++
        }
    }
    return c
}
function file_has(i, re, ci,    n, s) {
    if (ci) re = tolower(re)
    for (n = 1; n <= NL[i]; n++) {
        s = ci ? tolower(L[i, n]) : L[i, n]
        if (s ~ re) return n
    }
    return 0
}
function path_first(re,    i) {
    for (i = 1; i <= np; i++) if (P[i] ~ re) return P[i]
    return ""
}
function addlead(id, check, where, text) {
    nlead++
    LD[nlead] = id " " check " " where ": " text
    if (!((id, check) in LCC)) {
        LON[id]++
        LO[id, LON[id]] = check
        LFC[id, check] = where
        LCC[id, check] = 0
    }
    LCC[id, check]++
    if (!(id in LC)) {
        LF[id] = where
        LC[id] = 0
    }
    LC[id]++
}
function cnt(id) { return (id in LC) ? LC[id] : 0 }
function cntc(id, check) { return ((id, check) in LCC) ? LCC[id, check] : 0 }
function leadcounts(id,    k, s) {
    s = ""
    for (k = 1; k <= LON[id]; k++) s = s (k > 1 ? ", " : "") LO[id, k] " " LCC[id, LO[id, k]]
    return s
}
function item(id, status, check, ev) {
    nitem++
    IT[nitem] = id " " status " " check ": " ev
    ST[status]++
}
function dep(re,    i, n) {
    re = "\"(" re ")\"[ \t]*:"
    for (i = 1; i <= np; i++) {
        if (!inset(i, "P")) continue
        for (n = 1; n <= NL[i]; n++) if (L[i, n] ~ re) return 1
    }
    return 0
}
function depname(re,    i, n, m) {
    re = "\"(" re ")\"[ \t]*:"
    for (i = 1; i <= np; i++) {
        if (!inset(i, "P")) continue
        for (n = 1; n <= NL[i]; n++) {
            if (match(L[i, n], re)) {
                m = substr(L[i, n], RSTART + 1)
                sub(/".*/, "", m)
                return m
            }
        }
    }
    return ""
}
function pydep(re,    i) {
    re = "(^|[^a-z0-9_-])(" re ")([^a-z0-9_-]|$)"
    for (i = 1; i <= np; i++) if (inset(i, "Y") && file_has(i, re, 1)) return 1
    return 0
}
function rxall(s, re,    out) {
    out = ""
    while (match(s, re)) {
        out = out substr(s, 1, RSTART - 1) "<redacted>"
        s = substr(s, RSTART + RLENGTH)
    }
    return out s
}
function redact(s,    out, m, st, ln, k, q) {
    s = rxall(s, "(sk|rk)_(live|test)_[A-Za-z0-9]+")
    s = rxall(s, ENVIRON["CP_K_AWS"])
    s = rxall(s, ENVIRON["CP_X_GH"])
    s = rxall(s, ENVIRON["CP_X_SLACK"])
    s = rxall(s, ENVIRON["CP_X_GOOGLE"])
    s = rxall(s, ENVIRON["CP_X_ANTHROPIC"])
    s = rxall(s, ENVIRON["CP_X_OPENAI"])
    s = rxall(s, ENVIRON["CP_X_JWT"])
    s = rxall(s, "-----BEGIN [A-Z ]*PRIVATE KEY-----")
    out = ""
    while (match(s, "://[^:/@ \"\047]+:[^@/ \"\047]+@")) {
        m = substr(s, RSTART, RLENGTH)
        k = index(substr(m, 4), ":") + 3
        out = out substr(s, 1, RSTART - 1) substr(m, 1, k) "<redacted>@"
        s = substr(s, RSTART + RLENGTH)
    }
    s = out s
    out = ""
    while (match(s, ENVIRON["CP_X_QUOTED"])) {
        st = RSTART
        ln = RLENGTH
        m = substr(s, st, ln)
        match(m, /[:=][ \t]*["\047]/)
        k = RSTART + RLENGTH - 1
        q = substr(m, k, 1)
        out = out substr(s, 1, st - 1) substr(m, 1, k) "<redacted>" q
        s = substr(s, st + ln)
    }
    return out s
}
function page_meta(id, check, re, label,    i, total, titled, missing, root, firstp) {
    total = 0
    titled = 0
    missing = ""
    root = ""
    firstp = ""
    for (i = 1; i <= np; i++) {
        if (i in ispage) {
            total++
            if (firstp == "") firstp = P[i]
            if (file_has(i, re, 0)) titled++
            else if (missing == "") missing = P[i]
        }
        if ((i in islayout) && root == "" && file_has(i, re, 0)) root = P[i]
    }
    if (total == 0) {
        if (root != "") item(id, "warn", check, label " in " root ", no page files found to check one per page")
        else item(id, "fail", check, "no page " label " found")
    } else if (titled == total) {
        if (SPA) item(id, "warn", check, "one " label " in " firstp " for a single page app with a router, set one per route")
        else item(id, "pass", check, "own " label " in all " total " pages, for example " firstp)
    } else if (root != "") {
        item(id, "warn", check, "site wide " label " in " root ", own " label " in " titled " of " total " pages, first without one: " missing)
    } else {
        item(id, "fail", check, "own " label " in " titled " of " total " pages, first without one: " missing)
    }
}
function done_tag(tag,   v, lv) {
    images++
    if (tag !~ /[ \t]alt[ \t]*=/ && tag !~ /\{[ \t]*\.\.\./) {
        noalt++
        addlead("FE9", "img-without-alt", tfile ":" tline, ttext)
        return
    }
    if (match(tag, /[ \t]alt[ \t]*=[ \t]*["\047][^"\047]*["\047]/)) {
        v = substr(tag, RSTART, RLENGTH)
        sub(/^[ \t]alt[ \t]*=[ \t]*["\047]/, "", v)
        sub(/["\047]$/, "", v)
        lv = tolower(trim(v))
        if (lv ~ /^(image|img|photo|picture|pic|graphic|banner|screenshot|untitled)$/ || lv ~ /\.(png|jpe?g|gif|webp|svg|avif)$/ || lv ~ /^(image|picture|photo) of /) {
            weakalt++
            addlead("FE9", "weak-alt", tfile ":" tline, ttext)
        }
    }
}
function scan_images(    i, n, line, rest, p, tag, pending, buf) {
    for (i = 1; i <= np; i++) {
        if (!inset(i, "M")) continue
        pending = 0
        for (n = 1; n <= NL[i]; n++) {
            line = L[i, n]
            rest = line
            if (pending) {
                p = index(rest, ">")
                if (p > 0) {
                    buf = buf " " substr(rest, 1, p)
                    done_tag(buf)
                    pending = 0
                    rest = substr(rest, p + 1)
                } else {
                    buf = buf " " rest
                    if (n - tline >= 8) { done_tag(buf); pending = 0 }
                    continue
                }
            }
            while (match(rest, /<(img|Image|NuxtImg|NuxtPicture)([ \t]|\/?>|$)/)) {
                tag = substr(rest, RSTART)
                tfile = P[i]
                tline = n
                ttext = trim(line)
                p = index(tag, ">")
                if (p > 0) {
                    done_tag(substr(tag, 1, p))
                    rest = substr(tag, p + 1)
                } else {
                    buf = tag
                    pending = 1
                    break
                }
            }
        }
        if (pending) done_tag(buf)
    }
}
function robots_block(i,    n, line, v, star, rules) {
    star = 0
    rules = 0
    for (n = 1; n <= NL[i]; n++) {
        line = tolower(L[i, n])
        sub(/#.*/, "", line)
        if (line ~ /^[ \t]*user-agent[ \t]*:/) {
            if (rules) { star = 0; rules = 0 }
            v = line
            sub(/^[ \t]*user-agent[ \t]*:[ \t]*/, "", v)
            sub(/[ \t]+$/, "", v)
            if (v == "*") star = 1
            continue
        }
        if (line ~ /^[ \t]*(dis)?allow[ \t]*:/) rules = 1
        if (star && line ~ /^[ \t]*disallow[ \t]*:[ \t]*\/[ \t]*$/) return P[i] ":" n
    }
    return ""
}
function norm(t) { gsub(/"/, "", t); sub(/^public\./, "", t); return t }
function stmt(file, ln, text, buf,    s, t, raw, cmd) {
    s = tolower(buf)
    gsub(/[ \t]+/, " ", s)
    sub(/^ /, "", s)
    if (s ~ /storage\.buckets/) nbuckets++
    if (s ~ /^insert into storage\.buckets/ && s ~ /(^|[^a-z_])true([^a-z_]|$)/) { nb++; BK[nb] = file ":" ln; BT[nb] = text }
    if (s ~ /^update storage\.buckets / && s ~ /public ?= ?true/) { nb++; BK[nb] = file ":" ln; BT[nb] = text }
    if (match(s, /^create (unlogged )?table (if not exists )?[a-z0-9_."]+/)) {
        t = substr(s, RSTART, RLENGTH)
        sub(/^create (unlogged )?table (if not exists )?/, "", t)
        raw = t
        gsub(/"/, "", raw)
        if (!(raw ~ /\./ && raw !~ /^public\./)) {
            t = norm(t)
            if (!(t in seen)) { seen[t] = 1; nt++; TN[nt] = t; TW[t] = file ":" ln; TX[t] = text }
        }
    } else if (match(s, /^alter table (if exists )?(only )?[a-z0-9_."]+ enable row level security/)) {
        t = s
        sub(/^alter table (if exists )?(only )?/, "", t)
        sub(/ .*$/, "", t)
        rls[norm(t)] = 1
    } else if (s ~ /^create policy /) {
        cmd = "all"
        if (match(s, / for (all|select|insert|update|delete)( |$)/)) {
            cmd = substr(s, RSTART + 5, RLENGTH - 5)
            sub(/ $/, "", cmd)
        }
        if (cmd != "select" && s ~ /(using|with check) ?\( ?true ?\)/) addlead("BE2", "open-policy", file ":" ln, text)
    }
}
function scan_sql(    i, n, line, code, rest, p, piece, buf, sline, stext) {
    for (i = 1; i <= np; i++) {
        if (!inset(i, "Q")) continue
        buf = ""
        sline = 0
        for (n = 1; n <= NL[i]; n++) {
            line = L[i, n]
            code = line
            sub(/--.*$/, "", code)
            rest = code
            while ((p = index(rest, ";")) > 0) {
                piece = substr(rest, 1, p - 1)
                if (sline == 0 && piece ~ /[^ \t]/) { sline = n; stext = trim(line) }
                buf = buf " " piece
                if (buf ~ /[^ \t]/) stmt(P[i], sline, stext, buf)
                buf = ""
                sline = 0
                rest = substr(rest, p + 1)
            }
            if (rest ~ /[^ \t]/) {
                if (sline == 0) { sline = n; stext = trim(line) }
                buf = buf " " rest
            }
        }
        if (buf ~ /[^ \t]/) stmt(P[i], sline, stext, buf)
    }
}
function sessions(    i, n, j, w, t) {
    for (i = 1; i <= np; i++) {
        if (!inset(i, "S")) continue
        for (n = 1; n <= NL[i]; n++) {
            if (L[i, n] ~ /jwt\.sign\(/) {
                w = ""
                for (j = n; j <= NL[i] && j <= n + 3; j++) w = w " " L[i, j]
                if (w !~ /expiresIn|exp[ \t]*:|expires/) addlead("BE17", "jwt-no-expiry", P[i] ":" n, trim(L[i, n]))
            }
            if (L[i, n] ~ ENVIRON["CP_COOKIE"]) {
                w = ""
                for (j = n; j <= NL[i] && j <= n + 5; j++) w = w " " tolower(L[i, j])
                if (w !~ /httponly/ || w !~ /secure/ || w !~ /samesite/) addlead("BE17", "cookie-flags", P[i] ":" n, trim(L[i, n]))
            }
        }
    }
}
function legal(id, check, pagere, linkre, label,    pg, i, n, s, foot, any, ext, lre, ere) {
    pg = path_first(pagere)
    foot = ""
    any = ""
    ext = ""
    lre = tolower(linkre)
    ere = tolower(ENVIRON["CP_EXT_LINK"])
    for (i = 1; i <= np; i++) {
        if (!inset(i, "M")) continue
        for (n = 1; n <= NL[i]; n++) {
            s = tolower(L[i, n])
            if (s !~ lre) continue
            if (any == "") any = P[i] ":" n
            if (foot == "" && tolower(P[i]) ~ /footer|layout/) foot = P[i] ":" n
            if (ext == "" && s ~ ere) ext = P[i] ":" n
        }
    }
    if (pg != "" && foot != "") item(id, "pass", check, "page at " pg ", linked from " foot)
    else if (pg != "" && any != "") item(id, "warn", check, "page at " pg " is linked from " any ", not from the footer")
    else if (pg != "") item(id, "warn", check, "page at " pg " but nothing links to it")
    else if (ext != "") item(id, "pass", check, "links to a hosted " label " at " ext)
    else if (any != "") item(id, "fail", check, "link at " any " but no " label " page in the project")
    else item(id, "fail", check, "no " label " page")
}
function comment_skip(t, todo) {
    if (tolower(t) ~ /placeholder/) return 1
    if (t ~ /^[ \t]*(\/\/|\/\*|\*|\{\/\*|<!--)/) return 1
    if (todo && t ~ /(\/\/|\/\*|<!--|\{\/\*).*(TODO|TBD|FIXME)/) return 1
    return 0
}
function readfile(path, arr,    line, n) {
    n = 0
    while ((getline line < path) > 0) {
        sub(/\r$/, "", line)
        arr[++n] = line
    }
    close(path)
    return n
}
BEGIN {
    list = ENVIRON["CP_LIST"]
    while ((getline p < list) > 0) {
        sub(/\r$/, "", p)
        if (p == "") continue
        np++
        P[np] = p
        PI[p] = np
        TG[np] = classify(p)
        if (TG[np] != "") {
            ntext++
            nl = 0
            while ((getline line < p) > 0) {
                sub(/\r$/, "", line)
                L[np, ++nl] = line
            }
            close(p)
            NL[np] = nl
        }
    }
    close(list)

    FRAMEWORK = "unknown"
    if (dep("next")) {
        if (path_first("^(src/)?app/(.*/)?(page|layout)\\.(js|jsx|ts|tsx|mdx)$") != "") FRAMEWORK = "next-app"
        else FRAMEWORK = "next-pages"
    } else if (dep("@remix-run/[a-z-]+|@react-router/dev")) FRAMEWORK = "remix"
    else if (dep("astro") || path_first("(^|/)astro\\.config\\.") != "") FRAMEWORK = "astro"
    else if (dep("@sveltejs/kit")) FRAMEWORK = "sveltekit"
    else if (dep("nuxt") || path_first("(^|/)nuxt\\.config\\.") != "") FRAMEWORK = "nuxt"
    else if (dep("vite|react-scripts") || path_first("(^|/)vite\\.config\\.") != "") FRAMEWORK = "vite"
    else if (path_first("\\.html?$") != "") FRAMEWORK = "static"

    napi = 0
    for (i = 1; i <= np; i++) {
        if (!inset(i, "S")) continue
        if (P[i] ~ ENVIRON["CP_API_PATH"] || file_has(i, ENVIRON["CP_API_CODE"], 0)) {
            isapi[i] = 1
            napi++
        }
    }

    BACKEND = ""
    if (dep("@supabase/[a-z-]+") || path_first("^supabase/(config\\.toml|migrations/)") != "") { BACKEND = "supabase"; SB = 1 }
    if (dep("firebase|firebase-admin") || path_first("(^|/)(firebase\\.json|firestore\\.rules|storage\\.rules|database\\.rules\\.json)$") != "") { BACKEND = BACKEND (BACKEND == "" ? "" : ", ") "firebase"; FB = 1 }
    jsapi = 0
    for (i in isapi) if (P[i] ~ /\.(js|jsx|ts|tsx|mjs|cjs)$/) jsapi = 1
    if (dep("express|fastify|koa|hono|@nestjs/core|@hapi/hapi|restify|@trpc/server") || jsapi) { BACKEND = BACKEND (BACKEND == "" ? "" : ", ") "node"; NODE = 1 }
    py = 0
    for (i = 1; i <= np; i++) if (inset(i, "Y") || (inset(i, "S") && P[i] ~ /\.py$/)) py = 1
    if (py) { BACKEND = BACKEND (BACKEND == "" ? "" : ", ") "python"; PY = 1 }
    if (BACKEND == "") BACKEND = "none"
    SERVER = (napi > 0 || NODE || PY)
    DB = (SB || FB)

    f = path_first(ENVIRON["CP_NOTFOUND"])
    if (f != "") item("FE1", "pass", "custom-404", "custom 404 page at " f)
    else {
        f = path_first(ENVIRON["CP_CATCHALL"])
        if (f != "") item("FE1", "warn", "custom-404", "catch-all route at " f ", confirm unknown paths get a 404 page with status 404")
        else item("FE1", "fail", "custom-404", "no 404 page (app/not-found, pages/404, 404.html, +error.svelte or error.vue)")
    }

    item("FE2", "manual", "cta-above-fold", "check at 375x812 and 1440x900 that the main action shows without scrolling and names the outcome")

    if (FRAMEWORK == "next-app") pagere = "^(src/)?app/(.*/)?page\\.(js|jsx|ts|tsx|mdx)$"
    else if (FRAMEWORK == "next-pages") pagere = "^(src/)?pages/.*\\.(js|jsx|ts|tsx|mdx)$"
    else if (FRAMEWORK == "astro") pagere = "^src/pages/.*\\.(astro|md|mdx)$"
    else if (FRAMEWORK == "sveltekit") pagere = "(^|/)\\+page\\.svelte$"
    else if (FRAMEWORK == "nuxt") pagere = "^(app/)?pages/.*\\.vue$"
    else if (FRAMEWORK == "remix") pagere = "^app/routes/.*\\.(js|jsx|ts|tsx)$"
    else pagere = "\\.html?$"
    for (i = 1; i <= np; i++) {
        if (TG[i] == "") continue
        if (P[i] ~ pagere && P[i] !~ ENVIRON["CP_PAGE_SKIP"]) ispage[i] = 1
        if (P[i] ~ ENVIRON["CP_LAYOUT"]) islayout[i] = 1
    }
    SPA = 0
    if (FRAMEWORK == "vite" && dep("react-router|react-router-dom|vue-router|@tanstack/react-router|wouter|svelte-routing|@solidjs/router|preact-router")) {
        if (first("S", "document\\.title|Helmet|useHead|@unhead|useTitle|useDocumentTitle", 0) == "") SPA = 1
    }
    page_meta("FE3", "meta-title", ENVIRON["CP_TITLE"], "title")
    page_meta("FE4", "meta-description", ENVIRON["CP_DESC"], "description")

    ogfile = path_first("(^|/)opengraph-image[^/]*\\.(png|jpe?g|gif|webp|js|jsx|ts|tsx)$")
    twfile = path_first("(^|/)twitter-image[^/]*\\.(png|jpe?g|gif|webp|js|jsx|ts|tsx)$")
    og = first("T", "og:(title|description|image)|openGraph", 0)
    ogimg = first("T", "og:image", 0)
    if (ogimg == "") {
        for (i = 1; i <= np; i++) if (inset(i, "T") && file_has(i, "openGraph", 0)) inlist[i] = 1
        ogimg = first("LIST", "images[[:space:]]*:", 0)
        split("", inlist)
    }
    tw = first("T", ENVIRON["CP_TW"], 0)
    imgev = (ogfile != "") ? ogfile : ogimg
    ogev = (og != "") ? og : ogfile
    twev = (tw != "") ? tw : twfile
    if (ogev == "" && imgev == "") item("FE5", "fail", "open-graph", "no Open Graph tags or share image")
    else {
        missing = ""
        if (og == "") missing = missing (missing == "" ? "" : ", ") "og:title and og:description"
        if (imgev == "") missing = missing (missing == "" ? "" : ", ") "og:image"
        if (twev == "") missing = missing (missing == "" ? "" : ", ") "twitter:card"
        if (missing == "") item("FE5", "pass", "open-graph", "share image at " imgev ", Open Graph tags at " ogev ", twitter card at " twev)
        else item("FE5", "warn", "open-graph", "missing " missing ", Open Graph found at " ogev)
    }

    ico = path_first("(^|/)favicon\\.ico$")
    icon = path_first("(^|/)(favicon[^/]*|icon[0-9]*)\\.(svg|png)$")
    apple = path_first("(^|/)(apple-touch-icon[^/]*|apple-icon[0-9]*)\\.(png|jpe?g)$")
    man = path_first("(^|/)(site\\.webmanifest|manifest\\.(json|webmanifest|js|ts)|[^/]*\\.webmanifest)$")
    mani = ""
    if (man != "" && TG[PI[man]] != "" && file_has(PI[man], ENVIRON["CP_ICONS"], 0)) mani = man
    have = 0
    missing = ""
    if (ico != "") have++; else missing = missing (missing == "" ? "" : ", ") "favicon.ico"
    if (icon != "") have++; else missing = missing (missing == "" ? "" : ", ") "an SVG or PNG icon"
    if (apple != "") have++; else missing = missing (missing == "" ? "" : ", ") "a 180px apple touch icon"
    if (mani != "") have++; else missing = missing (missing == "" ? "" : ", ") "manifest icons"
    if (have == 4) item("FE6", "pass", "favicon-set", ico ", " icon ", " apple " and icons in " mani)
    else if (have == 0) item("FE6", "fail", "favicon-set", "no favicon, app icon, apple touch icon or manifest icons")
    else item("FE6", "warn", "favicon-set", "missing " missing)

    rb = path_first("(^|/)robots\\.txt$")
    rbr = path_first("(^|/)robots\\.(js|ts|mjs)$|(^|/)robots\\.txt/\\+server\\.(js|ts)$|(^|/)robots\\.txt\\.(js|ts)$")
    if (rb != "" && TG[PI[rb]] != "") {
        dis = robots_block(PI[rb])
        split("", inlist)
        inlist[PI[rb]] = 1
        sm = first("LIST", "^[[:space:]]*sitemap[[:space:]]*:", 1)
        split("", inlist)
        if (dis != "") item("FE7", "fail", "robots-txt", dis " disallows every path for all crawlers")
        else if (sm != "") item("FE7", "pass", "robots-txt", rb " allows crawling and names the sitemap at " sm)
        else item("FE7", "warn", "robots-txt", rb " has no Sitemap line")
    } else if (rbr != "") {
        split("", inlist)
        inlist[PI[rbr]] = 1
        dis = first("LIST", ENVIRON["CP_ROBOTS_ROUTE_DIS"], 0)
        sm = first("LIST", "sitemap", 1)
        split("", inlist)
        if (dis != "") item("FE7", "fail", "robots-txt", dis " disallows every path")
        else if (sm != "") item("FE7", "pass", "robots-txt", rbr " allows crawling and names the sitemap at " sm)
        else item("FE7", "warn", "robots-txt", rbr " has no sitemap entry")
    } else {
        gen = first("T", "generateRobotsTxt[[:space:]]*:[[:space:]]*true", 0)
        gendep = depname("astro-robots-txt|@nuxtjs/robots|nuxt-simple-robots")
        if (gen != "") item("FE7", "pass", "robots-txt", "robots.txt generated by next-sitemap at " gen)
        else if (gendep != "") item("FE7", "pass", "robots-txt", "robots.txt generated by " gendep)
        else item("FE7", "fail", "robots-txt", "no robots.txt or robots route")
    }

    sm = path_first("(^|/)sitemap[^/]*\\.(xml|js|ts|mjs)$|(^|/)sitemap[^/]*\\.xml/")
    smdep = depname("next-sitemap|@astrojs/sitemap|@nuxtjs/sitemap|sitemap|vite-plugin-sitemap|svelte-sitemap|remix-sitemap|nuxt-simple-sitemap|astro-sitemap")
    if (sm != "") item("FE8", "pass", "sitemap", "sitemap at " sm)
    else if (smdep != "") item("FE8", "pass", "sitemap", "sitemap generated by " smdep)
    else item("FE8", "fail", "sitemap", "no sitemap.xml, sitemap route or sitemap package")

    scan_images()
    if (images == 0) item("FE9", "n/a", "image-alt", "no images found")
    else if (noalt > 0) item("FE9", "fail", "image-alt", noalt " of " images " images have no alt, first at " LFC["FE9", "img-without-alt"])
    else if (weakalt > 0) item("FE9", "warn", "image-alt", weakalt " of " images " alt texts are a file name or a generic word, first at " LFC["FE9", "weak-alt"])
    else item("FE9", "pass", "image-alt", "all " images " images have alt text")

    if (FRAMEWORK == "next-app" || FRAMEWORK == "next-pages" || FRAMEWORK == "nuxt") vp = "added by default in " FRAMEWORK
    else {
        vp = first("T", ENVIRON["CP_VIEWPORT"], 0)
        if (vp != "") vp = "at " vp
    }
    resp = first("W", ENVIRON["CP_RESP"], 0)
    if (vp == "") item("FE10", "fail", "mobile-breakpoints", "no viewport meta tag")
    else if (resp == "") item("FE10", "warn", "mobile-breakpoints", "viewport " vp " but no responsive styles (media queries or breakpoint classes)")
    else item("FE10", "manual", "mobile-breakpoints", "viewport " vp ", responsive styles at " resp ", check 375, 768 and 1440 for sideways scroll")

    st = first("W", ENVIRON["CP_STICKY"], 0)
    if (st != "") item("FE11", "manual", "sticky-mobile-cta", "fixed or sticky element at " st ", check that long landing pages keep the main action in reach at 375")
    else item("FE11", "manual", "sticky-mobile-cta", "no fixed bottom bar found, check that long landing pages keep the main action in reach at 375")

    skf = path_first("(^|/)(loading\\.(js|jsx|ts|tsx)|[^/]*[Ss]keleton[^/]*\\.(js|jsx|ts|tsx|vue|svelte|astro))$")
    skh = first("W", "Skeleton|skeleton|animate-pulse|aria-busy", 0)
    ld = first("M", ENVIRON["CP_LOADING"], 0)
    fe = first("S", ENVIRON["CP_FETCH"], 0)
    if (skf != "") item("FE12", "pass", "loading-states", "skeleton at " skf)
    else if (skh != "") item("FE12", "pass", "loading-states", "skeleton at " skh)
    else if (ld != "") item("FE12", "warn", "loading-states", "loading flag at " ld " but no skeleton")
    else if (fe != "") item("FE12", "fail", "loading-states", "data loads at " fe " with no loading state")
    else item("FE12", "n/a", "loading-states", "no client side data loading found")

    form = first("M", ENVIRON["CP_FORM"], 0)
    aria = first("M", "aria-invalid|aria-describedby|aria-errormessage", 0)
    ferr = first("M", ENVIRON["CP_FERR"], 0)
    if (form == "") item("FE13", "n/a", "form-errors", "no forms found")
    else if (aria != "") item("FE13", "pass", "form-errors", "field errors tied to inputs at " aria)
    else if (ferr != "") item("FE13", "warn", "form-errors", "field errors at " ferr " are not tied to the input with aria-describedby and aria-invalid")
    else item("FE13", "fail", "form-errors", "the form at " form " shows no inline error state")

    okp = path_first("(^|/)[^/]*(thank-you|thankyou|thanks|success|confirmation|confirmed)[^/]*(/|\\.)")
    okh = first("M", ENVIRON["CP_OKH"], 1)
    if (form == "") item("FE14", "n/a", "form-success", "no forms found")
    else if (okp != "") item("FE14", "pass", "form-success", "success page at " okp)
    else if (okh != "") item("FE14", "pass", "form-success", "success state at " okh)
    else item("FE14", "fail", "form-success", "no thank you page or success state after the form at " form)

    legal("FE15", "privacy-page", ENVIRON["CP_PRIV_PAGE"], ENVIRON["CP_PRIV_LINK"], "privacy policy")
    legal("FE16", "terms-page", ENVIRON["CP_TERMS_PAGE"], ENVIRON["CP_TERMS_LINK"], "terms")

    an = first("T", ENVIRON["CP_AN"], 1)
    pf = first("T", ENVIRON["CP_PF"], 1)
    tr = first("T", ENVIRON["CP_TRACK"], 1)
    cs = first("T", ENVIRON["CP_CONSENT"], 1)
    if (tr == "") item("FE17", "n/a", "cookie-consent", "no trackers or ad pixels found")
    else if (cs != "") item("FE17", "manual", "cookie-consent", "trackers at " tr ", consent banner at " cs ", check that reject is as easy as accept and nothing loads before consent")
    else {
        hits("M", ENVIRON["CP_TRACK"], 1, "FE17", "tracker-without-consent", "", 0)
        item("FE17", "fail", "cookie-consent", "tracker at " tr " loads with no consent banner")
    }
    hits("T", ENVIRON["CP_PHID"], 1, "FE18", "placeholder-id", "", 0)
    if (an == "") item("FE18", "fail", "analytics", "no analytics found")
    else if (cnt("FE18") > 0) item("FE18", "fail", "analytics", "analytics ID at " LF["FE18"] " looks like a placeholder")
    else if (pf != "") item("FE18", "pass", "analytics", "privacy friendly analytics at " pf)
    else if (tr != "" && cs != "") item("FE18", "pass", "analytics", "analytics at " tr ", consent gate at " cs)
    else if (tr != "") item("FE18", "warn", "analytics", "analytics at " tr " with no consent gate (see FE17)")
    else item("FE18", "pass", "analytics", "analytics at " an)

    phre = tolower(ENVIRON["CP_PH"])
    for (i = 1; i <= np; i++) {
        if (!inset(i, "H")) continue
        for (n = 1; n <= NL[i]; n++) {
            if (tolower(L[i, n]) !~ phre) continue
            if (comment_skip(L[i, n], 0)) continue
            addlead("FE19", "placeholder", P[i] ":" n, trim(L[i, n]))
        }
    }
    for (i = 1; i <= np; i++) {
        if (!inset(i, "M")) continue
        for (n = 1; n <= NL[i]; n++) {
            if (L[i, n] !~ ENVIRON["CP_TODO"]) continue
            if (comment_skip(L[i, n], 1)) continue
            addlead("FE19", "todo-in-page", P[i] ":" n, trim(L[i, n]))
        }
    }
    contact = first("M", "mailto:|tel:", 0)
    if (contact == "") contact = path_first("(^|/)[^/]*contact[^/]*(/[^/]*)?\\.(js|jsx|ts|tsx|md|mdx|astro|vue|svelte|html?)$")
    if (cnt("FE19") > 0) item("FE19", "fail", "real-content", "placeholder lines: " cnt("FE19") ", first at " LF["FE19"])
    else if (contact == "") item("FE19", "warn", "real-content", "no email link, phone link or contact page found")
    else item("FE19", "pass", "real-content", "contact at " contact ", no placeholder text found")

    hits("M", ENVIRON["CP_INSECURE"], 0, "FE20", "insecure-url", "http://(localhost|127\\.0\\.0\\.1|0\\.0\\.0\\.0|www\\.w3\\.org)", 0)
    site = first("T", ENVIRON["CP_SITE"], 0)
    if (cnt("FE20") > 0) item("FE20", "warn", "domain-https", "resources loaded over http: " cnt("FE20") ", first at " LF["FE20"])
    else if (site != "") item("FE20", "manual", "domain-https", "site URL at " site ", run prod-url on the live domain for HTTPS and load time")
    else item("FE20", "manual", "domain-https", "run prod-url on the live domain for HTTPS and load time")

    for (i = 1; i <= np; i++) {
        if (!inset(i, "T")) continue
        for (n = 1; n <= NL[i]; n++) {
            if (L[i, n] !~ ENVIRON["CP_PUB"]) continue
            if (L[i, n] ~ /PUBLISHABLE|ANON|SEARCH|MAPS|SITE_?KEY|PUBLIC_?KEY|CLIENT_?KEY/) continue
            t = trim(L[i, n])
            if (inset(i, "E")) {
                k = index(t, "=")
                if (k > 0) t = substr(t, 1, k - 1) "=<redacted>"
            }
            addlead("BE1", "public-env-secret", P[i] ":" n, t)
        }
    }
    hits("N", ENVIRON["CP_HARD"], 0, "BE1", "hardcoded-key", "", 0)
    hits("T", ENVIRON["CP_SRCMAP"], 1, "BE1", "sourcemap-public", "", 0)
    envreal = ""
    for (i = 1; i <= np; i++) {
        if (P[i] ~ /(^|\/)\.env[^\/]*$/ && P[i] !~ /\.(example|sample|template|dist|defaults)$/) { envreal = P[i]; break }
    }
    if (ENVIRON["CP_GITSTATE"] == "ok") {
        nt2 = readfile(ENVIRON["CP_TRACKED"], TRK)
        for (k = 1; k <= nt2; k++) {
            b = base(TRK[k])
            if (b ~ /^\.env/ && TRK[k] !~ /\.(example|sample|template|dist|defaults)$/) addlead("BE1", "env-tracked", TRK[k], "tracked by git, remove it from the repo and rotate every value in it")
        }
    }
    gi = ENVIRON["CP_GI"]
    ign = ""
    if (gi != "") {
        ngi = readfile(gi, GIL)
        for (k = 1; k <= ngi; k++) if (GIL[k] ~ /^[ \t]*(\/|\*\*\/|\*)?\.env/) { ign = gi ":" k; break }
    }
    if (ign == "" && envreal != "") addlead("BE1", "env-not-ignored", (gi == "" ? ".gitignore" : gi), "no line ignores .env files, so " envreal " can be committed")
    if (cnt("BE1") > 0) item("BE1", "fail", "hide-api-keys", leadcounts("BE1") ", first at " LF["BE1"])
    else if (ign == "") item("BE1", "warn", "hide-api-keys", "no .gitignore line ignores .env files, add .env* before the first env file is created")
    else item("BE1", "pass", "hide-api-keys", "no secret behind a public prefix, no key in code, no public source maps, .env ignored at " ign)

    scan_sql()
    withrls = 0
    for (k = 1; k <= nt; k++) {
        if (TN[k] in rls) withrls++
        else addlead("BE2", "table-without-rls", TW[TN[k]], TX[TN[k]])
    }
    fsr = ""
    for (i = 1; i <= np; i++) {
        if (inset(i, "T") && P[i] ~ /(^|\/)(firestore\.rules|database\.rules\.json)$/) {
            if (fsr == "") fsr = P[i]
            inlist[i] = 1
        }
    }
    hits("LIST", ENVIRON["CP_OPENRULE"], 0, "BE2", "open-rules", "", 0)
    split("", inlist)
    if (!DB) item("BE2", "n/a", "rls", "no Supabase or Firebase, the server owns data access (see BE19)")
    else if (cnt("BE2") > 0) item("BE2", "fail", "rls", leadcounts("BE2") ", first at " LF["BE2"])
    else {
        parts = ""
        status = "pass"
        if (SB) {
            if (nt > 0) parts = "RLS on all " nt " tables in the migrations"
            else { parts = "no table migrations in the repo, check RLS in the Supabase dashboard"; status = "manual" }
        }
        if (FB) {
            if (fsr != "") parts = parts (parts == "" ? "" : ", ") "no open rule in " fsr
            else { parts = parts (parts == "" ? "" : ", ") "no firestore.rules in the repo, check the rules in the Firebase console"; status = "manual" }
        }
        item("BE2", status, "rls", parts)
    }

    idr = path_first("\\[(id|[A-Za-z_]*Id|[A-Za-z_]*_id)\\]")
    if (idr == "") idr = first("S", "[\"\047`][^\"\047`]*/:[A-Za-z_]*[iI]d", 0)
    if (idr != "") item("BE3", "manual", "idor-test", "active test, run /security with two accounts against routes that take an id such as " idr)
    else item("BE3", "manual", "idor-test", "active test, run /security with two accounts against every route that takes an id")

    tool = ENVIRON["CP_TOOL"]
    if (ENVIRON["CP_GITSTATE"] == "nogit") item("BE4", "manual", "git-history-secrets", "git is not installed, scan the history with gitleaks or trufflehog")
    else if (ENVIRON["CP_GITSTATE"] != "ok") item("BE4", "manual", "git-history-secrets", "not a git repository, scan the history of the repo that deploys this code")
    else {
        hist = ENVIRON["CP_HISTP"]
        npair = 0
        h = ""
        f = ""
        while ((getline line < hist) > 0) {
            sub(/\r$/, "", line)
            if (line ~ /^@[0-9a-f]+$/) {
                if (f != "" && npair < 20) { npair++; PH[npair] = h; PF[npair] = f; PK[npair] = kinds(KD) }
                f = ""
                split("", KD)
                h = substr(line, 2)
                continue
            }
            if (line ~ /^diff --git /) {
                if (f != "" && npair < 20) { npair++; PH[npair] = h; PF[npair] = f; PK[npair] = kinds(KD) }
                split("", KD)
                f = line
                sub(/^diff --git "?a\//, "", f)
                sub(/"? "?b\/.*$/, "", f)
                continue
            }
            if (line ~ /^(\+\+\+|---) /) continue
            if (line ~ /^[-+]/) {
                if (line ~ ENVIRON["CP_K_AWS"]) KD["aws-access-key"] = 1
                if (line ~ ENVIRON["CP_K_STRIPE"]) KD["stripe-live-key"] = 1
                if (line ~ ENVIRON["CP_K_GITHUB"]) KD["github-token"] = 1
                if (line ~ ENVIRON["CP_K_SLACK"]) KD["slack-token"] = 1
                if (line ~ ENVIRON["CP_K_GOOGLE"]) KD["google-api-key"] = 1
                if (line ~ ENVIRON["CP_K_ANTHROPIC"]) KD["anthropic-key"] = 1
                if (line ~ ENVIRON["CP_K_OPENAI"]) KD["openai-key"] = 1
                if (line ~ ENVIRON["CP_K_PRIVATE"]) KD["private-key"] = 1
            }
        }
        close(hist)
        if (f != "" && npair < 20) { npair++; PH[npair] = h; PF[npair] = f; PK[npair] = kinds(KD) }
        ncommit = 0
        nnongoogle = 0
        for (k = 1; k <= npair; k++) {
            addlead("BE4", "secret-in-history", PF[k] "@" PH[k], PK[k] ", value not shown")
            if (!(PH[k] in seenc)) { seenc[PH[k]] = 1; ncommit++ }
            if (PK[k] != "google-api-key") nnongoogle++
        }
        envh = ENVIRON["CP_ENVH"]
        while ((getline line < envh) > 0) {
            sub(/\r$/, "", line)
            if (line ~ /^@[0-9a-f]+$/) { h = substr(line, 2); continue }
            if (line == "") continue
            b = base(line)
            if (b ~ /^\.env/ && line !~ /\.(example|sample|template|dist|defaults)$/) addlead("BE4", "env-in-history", line "@" h, "env file committed, rotate every value it held")
        }
        close(envh)
        if (ENVIRON["CP_COMMITS"] + 0 == 0) item("BE4", "manual", "git-history-secrets", "no commit touches this folder yet, keep .env files out of the first commit and scan again after it")
        else if (cnt("BE4") == 0) item("BE4", "pass", "git-history-secrets", "no key pattern or .env file in " ENVIRON["CP_COMMITS"] " commits, " tool)
        else if (nnongoogle == 0 && cntc("BE4", "env-in-history") == 0) item("BE4", "warn", "git-history-secrets", "Google API key in history, fine for a Firebase web config only if the key is restricted, " tool)
        else item("BE4", "fail", "git-history-secrets", leadcounts("BE4") " in " ncommit " commits, first at " LF["BE4"] ", rotate those keys, " tool)
    }

    mwcover = ""
    for (i = 1; i <= np; i++) {
        if (TG[i] == "" || P[i] !~ /^(src\/)?middleware\.(js|ts)$|(^|\/)hooks\.server\.(js|ts)$|^server\/middleware\/[^\/]*\.(js|ts)$/) continue
        if (file_has(i, "admin", 0) && file_has(i, ENVIRON["CP_ROLE"], 0)) { mwcover = P[i]; break }
    }
    nadmin = 0
    firstok = ""
    for (i = 1; i <= np; i++) {
        if (!inset(i, "S")) continue
        if (P[i] !~ /(^|\/)(app|pages|routes|api|server|controllers|views)\/(.*\/)?admin([\/._-]|$)/ && !file_has(i, ENVIRON["CP_ADMIN_ROUTE"], 0)) continue
        nadmin++
        rn = file_has(i, ENVIRON["CP_ROLE"], 0)
        if (rn) {
            client = 0
            if (file_has(i, ENVIRON["CP_USE_CLIENT"], 0)) client = 1
            else if (FRAMEWORK == "next-pages" && P[i] ~ /^(src\/)?pages\// && P[i] !~ /^(src\/)?pages\/api\// && !file_has(i, "getServerSideProps", 0)) client = 1
            if (client) addlead("BE5", "client-only-role-check", P[i] ":" rn, trim(L[i, rn]))
            else if (firstok == "") firstok = P[i] ":" rn
            continue
        }
        if (mwcover != "") { if (firstok == "") firstok = mwcover; continue }
        covered = ""
        d = dirof(P[i])
        while (d ~ /(^|\/)[^\/]*admin/) {
            split("layout.tsx layout.ts layout.jsx layout.js +layout.server.ts +layout.server.js +layout.ts +layout.js", LN, " ")
            for (k = 1; k <= 8; k++) {
                cand = (d == "." ? LN[k] : d "/" LN[k])
                if ((cand in PI) && TG[PI[cand]] != "" && file_has(PI[cand], ENVIRON["CP_ROLE"], 0)) { covered = cand; break }
            }
            if (covered != "" || d == ".") break
            d = dirof(d)
        }
        if (covered != "") { if (firstok == "") firstok = covered }
        else addlead("BE5", "admin-without-role-check", P[i], "no server side role check in this file, its layout or middleware")
    }
    if (nadmin == 0) item("BE5", "n/a", "admin-routes", "no admin routes found")
    else if (cnt("BE5") == 0) item("BE5", "pass", "admin-routes", "server side role check on all admin routes (" nadmin "), for example " firstok)
    else item("BE5", "warn", "admin-routes", cnt("BE5") " of " nadmin " admin routes show no server side role check, first at " LF["BE5"])

    item("BE6", "manual", "user-isolation", "active test, sign in as two users and confirm neither can see or change the other's data, run /security")

    rl = first("T", ENVIRON["CP_RATE"], 1)
    if (!SERVER) {
        if (DB) item("BE7", "manual", "rate-limit", "no own API, Supabase and Firebase limit their auth endpoints, check those limits and add App Check or edge limits")
        else item("BE7", "n/a", "rate-limit", "no server code found")
    } else if (rl != "") item("BE7", "pass", "rate-limit", "rate limiting at " rl)
    else item("BE7", "fail", "rate-limit", "no rate limiting found for " napi " route files")

    for (k = 1; k <= nb; k++) addlead("BE8", "public-bucket", BK[k], BT[k])
    hits("S", ENVIRON["CP_PUBBUCKET"], 0, "BE8", "public-bucket", "", 0)
    nstr = 0
    for (i = 1; i <= np; i++) {
        if (inset(i, "T") && P[i] ~ /(^|\/)storage\.rules$/) { inlist[i] = 1; nstr++ }
    }
    hits("LIST", ENVIRON["CP_OPENRULE"], 0, "BE8", "open-rules", "", 0)
    split("", inlist)
    hits("S", "getPublicUrl\\(", 0, "BE8", "public-url", "", 0)
    store = first("T", ENVIRON["CP_STORE"], 0)
    signed = first("S", ENVIRON["CP_SIGNED"], 0)
    nopen = cntc("BE8", "public-bucket") + cntc("BE8", "open-rules")
    if (store == "" && nbuckets == 0 && nstr == 0) item("BE8", "n/a", "storage-buckets", "no file storage found")
    else if (nopen > 0) item("BE8", "fail", "storage-buckets", leadcounts("BE8") ", first at " LF["BE8"])
    else if (cntc("BE8", "public-url") > 0) item("BE8", "warn", "storage-buckets", "files go out through getPublicUrl at " LFC["BE8", "public-url"] ", use signed URLs for private files")
    else if (signed != "") item("BE8", "pass", "storage-buckets", "signed URLs at " signed ", no public bucket or open storage rule")
    else item("BE8", "warn", "storage-buckets", "storage at " (store == "" ? "the SQL migrations" : store) " with no signed URLs, check that buckets are private")

    nin = 0
    nval = 0
    firstval = ""
    for (i = 1; i <= np; i++) {
        if (!(i in isapi)) continue
        hn = file_has(i, ENVIRON["CP_INPUT"], 0)
        if (!hn) continue
        nin++
        if (file_has(i, ENVIRON["CP_PARSE"], 0)) {
            nval++
            if (firstval == "") firstval = P[i]
        } else addlead("BE9", "unvalidated-input", P[i] ":" hn, trim(L[i, hn]))
    }
    if (nin == 0) {
        if (SERVER) item("BE9", "n/a", "input-validation", "no route reads request input")
        else if (DB) item("BE9", "manual", "input-validation", "the client writes straight to the database, check constraints and rules (BE2)")
        else item("BE9", "n/a", "input-validation", "no server routes found")
    } else if (nval == nin) item("BE9", "pass", "input-validation", "all " nin " route files that read input validate it, for example " firstval)
    else if (nval > 0) item("BE9", "warn", "input-validation", nval " of " nin " route files that read input validate it, first without at " LF["BE9"])
    else item("BE9", "fail", "input-validation", "none of " nin " route files that read input validate it, first at " LF["BE9"])

    glob = ""
    for (i = 1; i <= np; i++) {
        if (TG[i] == "" || P[i] !~ /^(src\/)?middleware\.(js|ts)$|(^|\/)hooks\.server\.(js|ts)$|^server\/middleware\/[^\/]*\.(js|ts)$/) continue
        if (file_has(i, ENVIRON["CP_AUTH"], 0)) { glob = P[i]; break }
    }
    if (glob == "") glob = first("S", ENVIRON["CP_GLOBAL_AUTH"], 0)
    npriv = 0
    nauth = 0
    pubre = tolower(ENVIRON["CP_PUBLIC_API"])
    for (i = 1; i <= np; i++) {
        if (!(i in isapi)) continue
        if (tolower(P[i]) ~ pubre) continue
        npriv++
        if (file_has(i, ENVIRON["CP_AUTH"], 0)) nauth++
        else if (glob == "") addlead("BE10", "route-without-auth", P[i], "no session or token check")
    }
    if (napi == 0) {
        if (DB) item("BE10", "n/a", "auth-by-default", "no own API routes, data access rules are under BE2")
        else item("BE10", "n/a", "auth-by-default", "no server routes found")
    } else if (glob != "") item("BE10", "pass", "auth-by-default", "auth middleware at " glob " runs before routes, confirm its matcher covers every private route")
    else if (npriv == 0) item("BE10", "manual", "auth-by-default", "all " napi " route files look public by name (login, webhook, contact), confirm none returns private data")
    else if (nauth == npriv) item("BE10", "pass", "auth-by-default", "session check in all " npriv " private route files")
    else if (nauth > 0) item("BE10", "warn", "auth-by-default", "session check in " nauth " of " npriv " private route files, first without at " LF["BE10"])
    else item("BE10", "fail", "auth-by-default", "no session check in any of " npriv " private route files, first at " LF["BE10"])

    hits("S", ENVIRON["CP_SQLI"], 0, "BE11", "sql-string-building", "", 0)
    if (cnt("BE11") > 0) item("BE11", "warn", "sql-injection", "queries built from strings: " cnt("BE11") ", first at " LF["BE11"] ", parameterize them and confirm with /security")
    else item("BE11", "manual", "sql-injection", "no string built SQL found, confirm with an injection test from /security")

    hits("S", ENVIRON["CP_LOG"], 1, "BE12", "sensitive-log", "redact|mask", 1)
    nsrc = 0
    for (i = 1; i <= np; i++) if (inset(i, "S")) nsrc++
    if (cnt("BE12") > 0) item("BE12", "fail", "sensitive-logs", "log lines that print secrets or whole requests: " cnt("BE12") ", first at " LF["BE12"])
    else if (nsrc == 0) item("BE12", "n/a", "sensitive-logs", "no code found")
    else item("BE12", "pass", "sensitive-logs", "no log line prints a password, token, key or whole request")

    hits("API", ENVIRON["CP_TAMPER"], 0, "BE13", "client-value", "", 0)
    hits("API", ENVIRON["CP_MASS"], 0, "BE13", "mass-assignment", "", 0)
    hits("NONAPI", ENVIRON["CP_CLIENTW"], 0, "BE13", "client-write", "", 0)
    if (cnt("BE13") > 0) item("BE13", "fail", "field-tampering", leadcounts("BE13") ", first at " LF["BE13"])
    else if (napi > 0) item("BE13", "pass", "field-tampering", "no route reads role, price, owner or status from the request")
    else if (DB) item("BE13", "manual", "field-tampering", "the client writes straight to the database, protect role, price and status columns with policies or column privileges (BE2)")
    else item("BE13", "n/a", "field-tampering", "no server routes found")

    nup = 0
    for (i = 1; i <= np; i++) {
        if (!inset(i, "S")) continue
        un = file_has(i, ENVIRON["CP_UP"], 0)
        if (!un) continue
        upf[i] = 1
        nup++
        if (!file_has(i, ENVIRON["CP_LIMIT"], 0)) addlead("BE14", "upload-without-limit", P[i] ":" un, trim(L[i, un]))
    }
    for (i = 1; i <= np; i++) {
        if (!(i in upf)) continue
        for (n = 1; n <= NL[i]; n++) {
            if (L[i, n] ~ /originalname|originalFilename|file\.name|\.filename/ && L[i, n] ~ /path|join|upload|writeFile|rename|\.from\(/) addlead("BE14", "original-filename", P[i] ":" n, trim(L[i, n]))
        }
    }
    ctype = ""
    for (i = 1; i <= np && ctype == ""; i++) {
        if (!(i in upf)) continue
        cn = file_has(i, ENVIRON["CP_CTYPE"], 0)
        if (cn) ctype = P[i] ":" cn
    }
    if (nup == 0) item("BE14", "n/a", "file-uploads", "no file upload handling found")
    else if (cntc("BE14", "upload-without-limit") > 0) item("BE14", "fail", "file-uploads", leadcounts("BE14") ", first at " LF["BE14"])
    else if (ctype == "") item("BE14", "warn", "file-uploads", "uploads limit size but do not check the type from the file bytes")
    else if (cntc("BE14", "original-filename") > 0) item("BE14", "warn", "file-uploads", "uploads keep the user's file name at " LF["BE14"] ", store them under a generated name")
    else item("BE14", "pass", "file-uploads", "uploads limit size and check the type by content at " ctype)

    hits("NONAPI", ENVIRON["CP_SENDS"], 0, "BE15", "client-sends-value", "", 0)
    if (cnt("BE15") > 0) item("BE15", "warn", "server-logic", "the client sends price, total, role or status at " LF["BE15"] ", confirm the server ignores it and recomputes")
    else item("BE15", "manual", "server-logic", "read the flows that move money or change roles and confirm the server computes them")

    hits("S", ENVIRON["CP_HASHR"], 1, "BE16", "secret-in-response", "omit|delete |exclude|without|except|redact|pick\\(|drop|strip|select", 1)
    hits("S", ENVIRON["CP_SELALL"], 0, "BE16", "select-all-users", "", 0)
    for (i = 1; i <= np; i++) {
        if (!(i in isapi)) continue
        if (!file_has(i, "(findUnique|findFirst|findMany|findOne|findById|findByPk)\\(", 0) || file_has(i, "select[[:space:]]*:", 0)) continue
        for (n = 1; n <= NL[i]; n++) if (L[i, n] ~ /json\((user|users|row|rows|record|account|profile|customer)\)/) addlead("BE16", "whole-row", P[i] ":" n, trim(L[i, n]))
    }
    dto = first("API", ENVIRON["CP_DTO"], 0)
    if (cntc("BE16", "secret-in-response") > 0) item("BE16", "fail", "trim-responses", leadcounts("BE16") ", first at " LF["BE16"])
    else if (cnt("BE16") > 0) item("BE16", "warn", "trim-responses", leadcounts("BE16") ", first at " LF["BE16"] ", return only the fields the client needs")
    else if (napi > 0 && dto != "") item("BE16", "pass", "trim-responses", "responses pick their fields, for example " dto)
    else if (napi > 0) item("BE16", "manual", "trim-responses", "read each route's response and confirm it returns only the fields the client needs")
    else item("BE16", "n/a", "trim-responses", "no own API responses found")

    sessions()
    hits("S", ENVIRON["CP_WEBSTORE"], 1, "BE17", "token-in-web-storage", "", 0)
    hits("S", "document\\.cookie[[:space:]]*=[^=].*(token|jwt|session|auth)", 1, "BE17", "token-in-script-cookie", "", 0)
    sesslib = depname(ENVIRON["CP_SESS"])
    if (sesslib == "" && pydep("django|flask-login")) sesslib = "the Python framework"
    authany = sesslib
    if (authany == "") authany = first("S", ENVIRON["CP_COOKIE"] "|jwt\\.sign|signIn|login", 1)
    logout = first("S", "logout|log_out|signOut|sign_out|clearCookie|destroySession|session\\.destroy", 1)
    if (cnt("BE17") > 0) item("BE17", "fail", "auth-sessions", leadcounts("BE17") ", first at " LF["BE17"])
    else if (authany == "") item("BE17", "n/a", "auth-sessions", "no login or session handling found")
    else if (logout == "") item("BE17", "warn", "auth-sessions", "sessions found but no logout or sign out")
    else if (sesslib != "") item("BE17", "pass", "auth-sessions", "sessions handled by " sesslib ", logout at " logout)
    else item("BE17", "manual", "auth-sessions", "custom sessions, check expiry and rotation on login, logout at " logout)

    jsman = path_first("(^|/)package\\.json$")
    jslock = path_first("(^|/)(package-lock\\.json|npm-shrinkwrap\\.json|pnpm-lock\\.yaml|yarn\\.lock|bun\\.lockb?)$")
    pyman = path_first("(^|/)(requirements[^/]*\\.txt|pyproject\\.toml|Pipfile)$")
    pylock = path_first("(^|/)(poetry\\.lock|Pipfile\\.lock|uv\\.lock|requirements[^/]*\\.txt)$")
    bot = path_first("(^|/)\\.github/dependabot\\.ya?ml$|(^|/)renovate\\.json5?$|(^|/)\\.renovaterc(\\.json)?$|(^|/)\\.github/renovate\\.json5?$")
    if (bot == "" && first("P", "\"renovate\"[[:space:]]*:", 0) != "") bot = "package.json renovate config"
    cmd = ""
    if (jsman != "") {
        if (jslock ~ /pnpm-lock\.yaml$/) c = "pnpm audit --prod"
        else if (jslock ~ /yarn\.lock$/) c = (path_first("(^|/)\\.yarnrc\\.yml$") != "") ? "yarn npm audit --environment production" : "yarn audit --groups dependencies"
        else if (jslock ~ /bun\.lockb?$/) c = "bun audit"
        else c = "npm audit --omit=dev"
        cmd = c
    }
    if (pyman != "") {
        c = ("requirements.txt" in PI) ? "pip-audit -r requirements.txt" : "pip-audit"
        cmd = cmd (cmd == "" ? "" : " and ") c
    }
    if (path_first("(^|/)Gemfile$") != "") cmd = cmd (cmd == "" ? "" : " and ") "bundle audit check --update"
    if (path_first("(^|/)go\\.mod$") != "") cmd = cmd (cmd == "" ? "" : " and ") "govulncheck ./..."
    if (path_first("(^|/)Cargo\\.toml$") != "") cmd = cmd (cmd == "" ? "" : " and ") "cargo audit"
    if (path_first("(^|/)composer\\.json$") != "") cmd = cmd (cmd == "" ? "" : " and ") "composer audit"
    lock = (jslock != "") ? jslock : pylock
    if (lock == "") lock = "none"
    if (cmd == "") item("BE18", "n/a", "dependency-scan", "no dependency manifest found")
    else if (jsman != "" && jslock == "") item("BE18", "fail", "dependency-scan", jsman " has no lockfile, commit one, then run: " cmd)
    else if (bot == "") item("BE18", "warn", "dependency-scan", "lockfile " lock ", no Dependabot or Renovate config, run: " cmd)
    else item("BE18", "manual", "dependency-scan", "lockfile " lock ", updates by " bot ", run: " cmd " and grade on its output")

    hits("S", ENVIRON["CP_UNSCOPED"], 0, "BE19", "unscoped-lookup", "owner|tenant|user_?id|account_?id|org_?id|current_?user|req\\.user|request\\.user|session", 1)
    if (cnt("BE19") > 0) item("BE19", "warn", "record-access", "lookups by a request id with no owner filter: " cnt("BE19") ", first at " LF["BE19"] ", prove it with /security")
    else item("BE19", "manual", "record-access", "active test, read, update and delete another user's record with /security")

    for (i = 1; i <= np; i++) {
        if (inset(i, "T") && P[i] !~ /\.env\.(development|dev|local|test|example|sample|template)/ && P[i] !~ /\.local$/) inlist[i] = 1
    }
    hits("LIST", ENVIRON["CP_DEBUG"], 1, "BE20", "debug-on", "", 0)
    split("", inlist)
    hits("S", ENVIRON["CP_CORS"], 0, "BE20", "cors-wildcard", "", 0)
    hits("S", ENVIRON["CP_STACK"], 0, "BE20", "stack-in-response", "", 0)
    hdr = first("T", ENVIRON["CP_HEADERS"], 0)
    if (cnt("BE20") > 0) item("BE20", "fail", "production-config", leadcounts("BE20") ", first at " LF["BE20"])
    else if (hdr == "") item("BE20", "warn", "production-config", "no security headers configured (helmet, next.config headers, vercel.json, netlify.toml or _headers), confirm with prod-url")
    else item("BE20", "pass", "production-config", "security headers at " hdr ", no debug flag, no wildcard CORS, no stack traces in responses")

    print "PROD SCAN: " ENVIRON["CP_ARG"]
    print "FRAMEWORK: " FRAMEWORK
    print "BACKEND: " BACKEND
    print "FILES_SCANNED: " (ntext + 0)
    print ""
    for (k = 1; k <= nitem; k++) print redact(IT[k])
    print ""
    print "LEADS: " (nlead + 0)
    for (k = 1; k <= nlead; k++) {
        s = redact(LD[k])
        j = index(s, ": ")
        if (j > 0) s = substr(s, 1, j + 1) substr(s, j + 2, 120)
        print s
    }
    print ""
    print "PASS: " (ST["pass"] + 0)
    print "FAIL: " (ST["fail"] + 0)
    print "WARN: " (ST["warn"] + 0)
    print "MANUAL: " (ST["manual"] + 0)
    print "NA: " (ST["n/a"] + 0)
    print ""
    print "Statuses come from static evidence. Open the evidence behind each pass, check manual items in a browser or with prod-url, and hand active tests to /security."
}
function kinds(arr,    s, n, k, order) {
    n = split("aws-access-key stripe-live-key github-token slack-token google-api-key anthropic-key openai-key private-key", order, " ")
    s = ""
    for (k = 1; k <= n; k++) if (order[k] in arr) s = s (s == "" ? "" : ", ") order[k]
    if (s == "") s = "key pattern"
    return s
}
AWK

if ! awk "$MAIN_AWK" </dev/null; then
    echo "ERROR: the scan failed while reading $ARG." >&2
    exit 1
fi
