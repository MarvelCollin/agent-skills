#!/bin/bash
set -uo pipefail

usage() {
    echo "Usage: prod-url.sh <url> [--authorized]" >&2
}

fail() {
    echo "ERROR: $1" >&2
    exit 1
}

if [ $# -lt 1 ] || [ -z "${1:-}" ]; then
    usage
    exit 1
fi
URL="$1"
shift
AUTHORIZED=0
while [ $# -gt 0 ]; do
    case "$1" in
        --authorized) AUTHORIZED=1; shift ;;
        *) usage; fail "unknown option $1" ;;
    esac
done

case "$URL" in
    http://*|https://*) ;;
    *) fail "url must start with http:// or https://." ;;
esac
command -v curl &>/dev/null || fail "curl not found."

TMP="$(mktemp -d)" || fail "cannot create a temp folder."
trap 'rm -rf "$TMP"' EXIT
TAB="$(printf '\t')"
UA="Mozilla/5.0 (compatible; checkprod/1.0)"
REQS=0
CODE=""
TTFB=""
CTYPE=""
REDIR=""
EFF=""

fetch() {
    local name="$1" url="$2" follow="$3" out
    local args=(-sS --compressed --max-time 15 --connect-timeout 10 -A "$UA" -o "$TMP/$name.body" -D "$TMP/$name.head" -w '%{http_code}\t%{time_starttransfer}\t%{content_type}\t%{redirect_url}\t%{url_effective}')
    if [ "$follow" = 1 ]; then
        args+=(-L --max-redirs 5)
    fi
    : >"$TMP/$name.body"
    : >"$TMP/$name.head"
    out="$(curl "${args[@]}" "$url" 2>/dev/null)"
    REQS=$((REQS + 1))
    IFS="$TAB" read -r CODE TTFB CTYPE REDIR EFF <<<"$out"
    [ -n "$CODE" ] || CODE="000"
    [ -n "$EFF" ] || EFF="$url"
    CTYPE="${CTYPE%%;*}"
    CTYPE="$(printf '%s' "$CTYPE" | tr '[:upper:]' '[:lower:]' | tr -d ' ')"
}

is_local() {
    case "$1" in
        localhost|*.localhost|*.test|*.local|::1|0.0.0.0|host.docker.internal) return 0 ;;
        127.*|10.*|192.168.*|::ffff:127.*|::ffff:10.*|::ffff:192.168.*) return 0 ;;
        172.1[6-9].*|172.2[0-9].*|172.3[0-1].*) return 0 ;;
        *) return 1 ;;
    esac
}

fetch page "$URL" 1
if [ "$CODE" = "000" ]; then
    fail "request to $URL failed."
fi
STATUS="$CODE"
FINAL="$EFF"
PAGE_TTFB="$TTFB"

SCHEME="${FINAL%%://*}"
rest="${FINAL#*://}"
HOSTPORT="${rest%%/*}"
HOSTPORT="${HOSTPORT%%\?*}"
HOSTPORT="${HOSTPORT%%#*}"
ORIGIN="$SCHEME://$HOSTPORT"
pathpart="${rest%%\?*}"
pathpart="${pathpart%%#*}"
case "$pathpart" in
    */*) pathpart="/${pathpart#*/}" ;;
    *) pathpart="/" ;;
esac
BASEDIR="$ORIGIN${pathpart%/*}/"
host="${HOSTPORT##*@}"
case "$host" in
    \[*) host="${host#\[}"; host="${host%%\]*}" ;;
    *) host="${host%%:*}" ;;
esac
host="$(printf '%s' "$host" | tr '[:upper:]' '[:lower:]')"
if is_local "$host"; then
    SCOPE="local"
    PROBE=1
elif [ "$AUTHORIZED" -eq 1 ]; then
    SCOPE="remote authorized"
    PROBE=1
else
    SCOPE="remote passive"
    PROBE=0
fi

RES=""
resolve() {
    case "$1" in
        http://*|https://*) RES="$1" ;;
        //*) RES="$SCHEME:$1" ;;
        /*) RES="$ORIGIN$1" ;;
        *) RES="$BASEDIR$1" ;;
    esac
}

awk -v ttfb="$PAGE_TTFB" '
function clean(s) { gsub(/[ \t\r\n]+/, " ", s); sub(/^ /, "", s); sub(/ $/, "", s); return substr(s, 1, 150) }
function attr(tag, name,    l, v, q, e) {
    l = tolower(tag)
    if (!match(l, "[ \t/]" name "[ \t]*=[ \t]*")) return "\001"
    v = substr(tag, RSTART + RLENGTH)
    q = substr(v, 1, 1)
    if (q == "\"" || q == "\047") {
        v = substr(v, 2)
        e = index(v, q)
        if (e) return substr(v, 1, e - 1)
        return v
    }
    if (match(v, /[ \t>]/)) return substr(v, 1, RSTART - 1)
    return v
}
function val(s) { return (s == "\001") ? "" : clean(s) }
FILENAME == ARGV[1] {
    line = $0
    sub(/\r$/, "", line)
    if (line ~ /^HTTP\//) { split("", H); next }
    c = index(line, ":")
    if (c > 1) {
        k = tolower(substr(line, 1, c - 1))
        v = substr(line, c + 1)
        sub(/^[ \t]+/, "", v)
        sub(/[ \t]+$/, "", v)
        if (k in H) H[k] = H[k] ", " v
        else H[k] = v
    }
    next
}
{
    line = $0
    sub(/\r$/, "", line)
    html = html " " line
}
END {
    low = tolower(html)
    title = ""
    if (match(low, /<title[^>]*>/)) {
        s = RSTART + RLENGTH
        e = index(substr(low, s), "</title")
        if (e) title = clean(substr(html, s, e - 1))
    }
    lang = ""
    if (match(low, /<html[^>]*>/)) lang = val(attr(substr(html, RSTART, RLENGTH), "lang"))
    rest = html
    lrest = low
    while (match(lrest, /<(meta|link|img|script)[ \t\/>]/)) {
        st = RSTART
        name = substr(lrest, st + 1, RLENGTH - 2)
        e = index(substr(lrest, st), ">")
        if (e == 0) e = length(lrest) - st + 1
        tag = substr(rest, st, e)
        if (name == "meta") {
            k = attr(tag, "name")
            if (k == "\001") k = attr(tag, "property")
            k = tolower(k)
            if (k != "\001" && !(k in M)) M[k] = val(attr(tag, "content"))
        } else if (name == "link") {
            rel = tolower(attr(tag, "rel"))
            href = val(attr(tag, "href"))
            if (rel == "canonical" && canon == "") canon = href
            else if (rel ~ /(^| )apple-touch-icon/) { if (apple == "") apple = href }
            else if (rel ~ /(^| )icon( |$)/ && icon == "") icon = href
        } else if (name == "img") {
            images++
            if (tolower(tag) !~ /[ \t\/]alt([ \t]*=|[ \t>\/]|$)/) noalt++
        } else if (name == "script" && script == "") {
            script = val(attr(tag, "src"))
        }
        rest = substr(rest, st + e)
        lrest = substr(lrest, st + e)
    }
    print "HSTS\t" clean(H["strict-transport-security"])
    print "CSP\t" clean(H["content-security-policy"])
    print "CSPRO\t" clean(H["content-security-policy-report-only"])
    print "XCTO\t" clean(H["x-content-type-options"])
    print "XFO\t" clean(H["x-frame-options"])
    print "REF\t" clean(H["referrer-policy"])
    print "TITLE\t" title
    print "DESC\t" M["description"]
    print "OGT\t" M["og:title"]
    print "OGD\t" M["og:description"]
    print "OGI\t" M["og:image"]
    print "TWC\t" M["twitter:card"]
    print "CANON\t" canon
    print "VIEWPORT\t" M["viewport"]
    print "LANG\t" lang
    print "ICON\t" icon
    print "APPLE\t" apple
    print "SCRIPT\t" script
    print "IMAGES\t" (images + 0)
    print "NOALT\t" (noalt + 0)
    printf "TTFB\t%d\n", ttfb * 1000
}' "$TMP/page.head" "$TMP/page.body" >"$TMP/parsed"

HSTS="" CSP="" CSPRO="" XCTO="" XFO="" REF="" TITLE="" DESC="" OGT="" OGD="" OGI="" TWC="" CANON="" VIEWPORT="" PAGE_LANG="" ICON="" APPLE="" SCRIPT="" IMAGES=0 NOALT=0 TTFB_MS=0
while IFS="$TAB" read -r k v; do
    case "$k" in
        HSTS) HSTS="$v" ;;
        CSP) CSP="$v" ;;
        CSPRO) CSPRO="$v" ;;
        XCTO) XCTO="$v" ;;
        XFO) XFO="$v" ;;
        REF) REF="$v" ;;
        TITLE) TITLE="$v" ;;
        DESC) DESC="$v" ;;
        OGT) OGT="$v" ;;
        OGD) OGD="$v" ;;
        OGI) OGI="$v" ;;
        TWC) TWC="$v" ;;
        CANON) CANON="$v" ;;
        VIEWPORT) VIEWPORT="$v" ;;
        LANG) PAGE_LANG="$v" ;;
        ICON) ICON="$v" ;;
        APPLE) APPLE="$v" ;;
        SCRIPT) SCRIPT="$v" ;;
        IMAGES) IMAGES="$v" ;;
        NOALT) NOALT="$v" ;;
        TTFB) TTFB_MS="$v" ;;
    esac
done <"$TMP/parsed"

or_missing() {
    if [ -n "$1" ]; then printf '%s' "$1"; else printf 'missing'; fi
}

if [ "$SCHEME" = "https" ]; then
    case "$URL" in
        http://*) HTTPS="yes (http redirects to https)" ;;
        *)
            fetch httpcheck "http://$HOSTPORT/" 0
            case "$CODE" in
                000) HTTPS="yes (http is not served)" ;;
                3*)
                    case "$REDIR" in
                        https://*) HTTPS="yes (http redirects to https)" ;;
                        *) HTTPS="partial (http://$HOSTPORT does not redirect to https)" ;;
                    esac
                    ;;
                *) HTTPS="partial (http://$HOSTPORT does not redirect to https)" ;;
            esac
            ;;
    esac
else
    HTTPS="no (final URL is http)"
fi

FRAME="$XFO"
if [ -z "$FRAME" ]; then
    case "$CSP" in
        *frame-ancestors*)
            fa="frame-ancestors${CSP#*frame-ancestors}"
            FRAME="CSP ${fa%%;*}"
            ;;
    esac
fi
CSP_OUT="$CSP"
if [ -z "$CSP_OUT" ] && [ -n "$CSPRO" ]; then
    CSP_OUT="report-only ($CSPRO)"
fi

asset() {
    local name="$1" href="$2"
    resolve "$href"
    fetch "$name" "$RES" 1
    if [ "$CODE" = "000" ]; then
        ASSET="missing ($href is unreachable)"
    elif [ "$CODE" != "200" ]; then
        ASSET="missing ($href returns $CODE)"
    elif [ "$CTYPE" = "text/html" ]; then
        ASSET="missing ($href returns text/html)"
    else
        ASSET="ok ($href, 200 $CTYPE)"
    fi
}

ASSET=""
asset favicon "${ICON:-/favicon.ico}"
FAVICON="$ASSET"
asset apple "${APPLE:-/apple-touch-icon.png}"
APPLE_OUT="$ASSET"

if [ -n "$OGI" ]; then
    resolve "$OGI"
    fetch ogimage "$RES" 1
    if [ "$CODE" = "000" ]; then
        OG_IMAGE="$OGI (unreachable)"
    else
        OG_IMAGE="$OGI ($CODE $CTYPE)"
    fi
else
    OG_IMAGE="missing"
fi

SITEMAP_URL="$ORIGIN/sitemap.xml"
fetch robots "$ORIGIN/robots.txt" 1
if [ "$CODE" = "200" ] && [ "$CTYPE" != "text/html" ] && grep -qiE '^[[:space:]]*user-agent[[:space:]]*:' "$TMP/robots.body"; then
    awk '
    {
        line = $0
        sub(/\r$/, "", line)
        if (sm == "" && tolower(line) ~ /^[ \t]*sitemap[ \t]*:/) {
            sm = line
            sub(/^[ \t]*[A-Za-z]+[ \t]*:[ \t]*/, "", sm)
            sub(/[ \t]+$/, "", sm)
        }
        l = tolower(line)
        sub(/#.*/, "", l)
        if (l ~ /^[ \t]*user-agent[ \t]*:/) {
            if (rules) { star = 0; rules = 0 }
            v = l
            sub(/^[ \t]*user-agent[ \t]*:[ \t]*/, "", v)
            sub(/[ \t]+$/, "", v)
            if (v == "*") star = 1
            next
        }
        if (l ~ /^[ \t]*(dis)?allow[ \t]*:/) rules = 1
        if (star && l ~ /^[ \t]*disallow[ \t]*:[ \t]*\/[ \t]*$/) dis = 1
    }
    END { print (dis ? "1" : "0") "\t" sm }' "$TMP/robots.body" >"$TMP/robots.parsed"
    IFS="$TAB" read -r rdis rsm <"$TMP/robots.parsed"
    if [ "$rdis" = "1" ]; then
        ROBOTS="blocks all crawlers (Disallow: / for User-agent: *)"
    elif [ -n "$rsm" ]; then
        ROBOTS="ok (Sitemap: $rsm)"
    else
        ROBOTS="ok (no Sitemap line)"
    fi
    case "$rsm" in
        http://*|https://*) SITEMAP_URL="$rsm" ;;
    esac
elif [ "$CODE" = "200" ]; then
    ROBOTS="missing (returns HTML, not a robots file)"
elif [ "$CODE" = "000" ]; then
    ROBOTS="missing (unreachable)"
else
    ROBOTS="missing (HTTP $CODE)"
fi

fetch sitemap "$SITEMAP_URL" 1
if [ "$CODE" = "200" ]; then
    read -r smok smcount <<<"$(awk '{ l = tolower($0); if (l ~ /<urlset|<sitemapindex/) ok = 1; n += gsub(/<loc[ >]/, "", l) } END { print (ok ? 1 : 0) " " (n + 0) }' "$TMP/sitemap.body")"
    if [ "$smok" = "1" ]; then
        SITEMAP="ok ($smcount URLs)"
    elif [ "$CTYPE" = "text/html" ]; then
        SITEMAP="missing (returns HTML, not XML)"
    else
        SITEMAP="invalid (no urlset or sitemapindex)"
    fi
elif [ "$CODE" = "000" ]; then
    SITEMAP="missing (unreachable)"
else
    SITEMAP="missing (HTTP $CODE)"
fi

fetch notfound "$ORIGIN/checkprod-missing-page-7f3a9c" 1
case "$CODE" in
    404|410)
        NF_STATUS="$CODE"
        NF_PAGE="$(awk '
        { html = html " " tolower($0) }
        END {
            if (html ~ /this page could not be found/) print "default (Next.js)"
            else if (html ~ /<center>nginx/) print "default (nginx)"
            else if (html ~ /was not found on this server/) print "default (Apache)"
            else if (html ~ /cannot get \//) print "default (Express)"
            else if (html ~ /error response/ && html ~ /error code: 404/) print "default (Python http.server)"
            else if (html ~ /the page could not be found/ && html ~ /not_found/) print "default (Vercel)"
            else if (html ~ /followed a broken link/) print "default (Netlify)"
            else if (html ~ /github pages site here/) print "default (GitHub Pages)"
            else if (html ~ /<a[ \t][^>]*href/) print "custom"
            else print "default (no links back into the site)"
        }' "$TMP/notfound.body")"
        ;;
    200)
        NF_STATUS="200 (soft 404)"
        NF_PAGE="none (unknown paths return a normal page)"
        ;;
    000)
        NF_STATUS="unreachable"
        NF_PAGE="unknown (unreachable)"
        ;;
    *)
        NF_STATUS="$CODE"
        NF_PAGE="unknown (HTTP $CODE)"
        ;;
esac

NOT_CHECKED="not checked (remote host, pass --authorized after the user confirms they own it)"
if [ "$PROBE" -eq 1 ]; then
    fetch env "$ORIGIN/.env" 0
    if [ "$CODE" = "200" ] && [ "$CTYPE" != "text/html" ] && grep -qE '^[A-Za-z_][A-Za-z0-9_]*=' "$TMP/env.body"; then
        EXPOSED_ENV="yes (/.env returns KEY=value lines, block it and rotate every value)"
    elif [ "$CODE" = "200" ]; then
        EXPOSED_ENV="no (/.env returns a normal page)"
    else
        EXPOSED_ENV="no (HTTP $CODE)"
    fi
    fetch git "$ORIGIN/.git/HEAD" 0
    if [ "$CODE" = "200" ] && grep -qE '^(ref: |[0-9a-f]{40})' "$TMP/git.body"; then
        EXPOSED_GIT="yes (/.git/HEAD is readable, the source and history can be downloaded)"
    elif [ "$CODE" = "200" ]; then
        EXPOSED_GIT="no (/.git/HEAD returns a normal page)"
    else
        EXPOSED_GIT="no (HTTP $CODE)"
    fi
    if [ -z "$SCRIPT" ]; then
        SOURCE_MAPS="not checked (no script tag on the page)"
    else
        resolve "$SCRIPT"
        case "$RES" in
            "$ORIGIN"/*)
                spath="${RES#"$ORIGIN"}"
                spath="${spath%%\?*}"
                fetch map "$ORIGIN$spath.map" 0
                if [ "$CODE" = "200" ] && grep -q '"mappings"' "$TMP/map.body"; then
                    SOURCE_MAPS="yes ($spath.map is public)"
                else
                    SOURCE_MAPS="no ($spath.map returns $CODE)"
                fi
                ;;
            *) SOURCE_MAPS="not checked (the first script is on another host)" ;;
        esac
    fi
else
    EXPOSED_ENV="$NOT_CHECKED"
    EXPOSED_GIT="$NOT_CHECKED"
    SOURCE_MAPS="$NOT_CHECKED"
fi

echo "PROD URL CHECK: $URL"
echo "SCOPE: $SCOPE"
echo "HTTP_STATUS: $STATUS"
echo "FINAL_URL: $FINAL"
echo "TTFB_MS: $TTFB_MS"
echo "HTTPS: $HTTPS"
echo "HSTS: $(or_missing "$HSTS")"
echo "CSP: $(or_missing "$CSP_OUT")"
echo "X_CONTENT_TYPE_OPTIONS: $(or_missing "$XCTO")"
echo "FRAME_PROTECTION: $(or_missing "$FRAME")"
echo "REFERRER_POLICY: $(or_missing "$REF")"
echo "TITLE: $(or_missing "$TITLE")"
echo "META_DESCRIPTION: $(or_missing "$DESC")"
echo "OG_TITLE: $(or_missing "$OGT")"
echo "OG_DESCRIPTION: $(or_missing "$OGD")"
echo "OG_IMAGE: $OG_IMAGE"
echo "TWITTER_CARD: $(or_missing "$TWC")"
echo "CANONICAL: $(or_missing "$CANON")"
echo "VIEWPORT: $(or_missing "$VIEWPORT")"
echo "LANG: $(or_missing "$PAGE_LANG")"
echo "FAVICON: $FAVICON"
echo "APPLE_TOUCH_ICON: $APPLE_OUT"
echo "ROBOTS_TXT: $ROBOTS"
echo "SITEMAP_XML: $SITEMAP"
echo "NOT_FOUND_STATUS: $NF_STATUS"
echo "NOT_FOUND_PAGE: $NF_PAGE"
echo "IMAGES: $IMAGES"
echo "IMAGES_WITHOUT_ALT: $NOALT"
echo "EXPOSED_ENV: $EXPOSED_ENV"
echo "EXPOSED_GIT: $EXPOSED_GIT"
echo "SOURCE_MAPS: $SOURCE_MAPS"
echo "REQUESTS: $REQS"
