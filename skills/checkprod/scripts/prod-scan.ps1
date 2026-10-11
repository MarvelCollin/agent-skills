param(
    [Parameter(Mandatory=$true, Position=0)][string]$Path
)

function Fail([string]$Message) {
    [Console]::Error.WriteLine("ERROR: $Message")
    exit 1
}

if (-not (Test-Path -LiteralPath $Path)) { Fail "$Path does not exist." }
if (-not (Test-Path -LiteralPath $Path -PathType Container)) { Fail "$Path is not a folder. Pass the project folder." }
$root = (Resolve-Path -LiteralPath $Path).ProviderPath.TrimEnd('\', '/')

$excluded = @("node_modules", ".git", "dist", "build", ".next", "out", "coverage", "vendor", ".venv", "venv", "__pycache__", ".svelte-kit", ".nuxt", ".output", ".vercel", ".netlify", ".turbo", ".astro", ".cache", "test", "tests", "__tests__", "e2e", "cypress")
$all = New-Object System.Collections.Generic.List[string]
$stack = New-Object System.Collections.Generic.Stack[string]
$stack.Push($root)
try {
    while ($stack.Count -gt 0) {
        $dir = $stack.Pop()
        foreach ($sub in [System.IO.Directory]::GetDirectories($dir)) {
            $name = [System.IO.Path]::GetFileName($sub)
            if ($excluded -notcontains $name) { $stack.Push($sub) }
        }
        foreach ($file in [System.IO.Directory]::GetFiles($dir)) {
            $all.Add($file.Substring($root.Length + 1).Replace('\', '/'))
        }
    }
} catch {
    Fail "cannot read $Path. $($_.Exception.Message)"
}
$FilePaths = $all.ToArray()
[Array]::Sort($FilePaths, [StringComparer]::Ordinal)
$np = $FilePaths.Length

$Q = '["''`]'
$RxCache = @{}
function Get-Rx([string]$Pattern, [bool]$Ci) {
    $key = "$Ci|$Pattern"
    if (-not $RxCache.ContainsKey($key)) {
        $opt = [System.Text.RegularExpressions.RegexOptions]::CultureInvariant
        if ($Ci) { $opt = $opt -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase }
        $RxCache[$key] = New-Object System.Text.RegularExpressions.Regex($Pattern, $opt)
    }
    return $RxCache[$key]
}
function Get-Mx([string]$Pattern, [bool]$Ci) {
    $key = "M|$Ci|$Pattern"
    if (-not $RxCache.ContainsKey($key)) {
        $opt = [System.Text.RegularExpressions.RegexOptions]::CultureInvariant -bor [System.Text.RegularExpressions.RegexOptions]::Multiline
        if ($Ci) { $opt = $opt -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase }
        $RxCache[$key] = New-Object System.Text.RegularExpressions.Regex($Pattern, $opt)
    }
    return $RxCache[$key]
}

function Get-Tags([string]$p) {
    $n = $p
    $slash = $n.LastIndexOf('/')
    if ($slash -ge 0) { $n = $n.Substring($slash + 1) }
    $l = $n.ToLowerInvariant()
    if ($l -cmatch '\.min\.|\.map$|\.d\.ts$|\.(test|spec)\.[a-z0-9]+$|_test\.(py|go)$|^test_.*\.py$') { return "" }
    if ($l -cmatch '^(package-lock\.json|npm-shrinkwrap\.json|pnpm-lock\.yaml|yarn\.lock|bun\.lockb?|composer\.lock|gemfile\.lock|poetry\.lock|pipfile\.lock|cargo\.lock|uv\.lock)$') { return "" }
    if ($l -cmatch '^(readme|changelog|contributing|license|code_of_conduct|security)(\.|$)') { return "" }
    $isEnv = $l -cmatch '^\.env'
    $ext = ""
    $m = [regex]::Match($l, '\.[a-z0-9]+$')
    if ($m.Success) { $ext = $m.Value.Substring(1) }
    $text = $isEnv -or ($ext -cmatch '^(js|jsx|ts|tsx|mjs|cjs|vue|svelte|astro|html|htm|md|mdx|css|scss|sass|less|json|json5|yaml|yml|toml|xml|txt|sql|rules|py|rb|php|go|java|kt|cs|webmanifest)$') -or ($l -cmatch '^(_headers|_redirects|dockerfile|procfile|cname|pipfile|gemfile)$')
    if (-not $text) { return "" }
    $tags = "T"
    $mark = $ext -cmatch '^(html|htm|jsx|tsx|js|vue|svelte|astro|mdx|md)$'
    if ($mark) { $tags += "M" }
    if ($mark -or ($ext -cmatch '^(css|scss|sass|less)$')) { $tags += "W" }
    if ($ext -cmatch '^(js|jsx|ts|tsx|mjs|cjs|vue|svelte|astro|py|rb|php|go|java|kt|cs)$') { $tags += "S" }
    if ($isEnv) { $tags += "E" } else { $tags += "N" }
    if ($ext -ceq "sql") { $tags += "Q" }
    if ($l -ceq "package.json") { $tags += "P" }
    if ($l -cmatch '^requirements.*\.txt$|^pyproject\.toml$|^pipfile$') { $tags += "Y" }
    if ($mark -or ($p -cmatch '(^|/)(locales?|messages|i18n|content|data)/.*\.(json|ya?ml)$') -or ($l -cmatch '\.config\.(js|mjs|cjs|ts)$')) { $tags += "H" }
    return $tags
}

function Read-Lines([string]$FullPath) {
    $text = [System.IO.File]::ReadAllText($FullPath)
    $parts = $text.Split([char]10)
    $count = $parts.Length
    if ($count -gt 0 -and $parts[$count - 1] -eq "") { $count-- }
    $lines = New-Object string[] $count
    for ($k = 0; $k -lt $count; $k++) { $lines[$k] = $parts[$k].TrimEnd([char]13) }
    return ,$lines
}

$PathIndex = New-Object 'System.Collections.Generic.Dictionary[string,int]' ([StringComparer]::Ordinal)
$FileTags = New-Object string[] $np
$FileLines = New-Object object[] $np
$FileText = New-Object string[] $np
$ntext = 0
for ($i = 0; $i -lt $np; $i++) {
    $PathIndex[$FilePaths[$i]] = $i
    $FileTags[$i] = Get-Tags $FilePaths[$i]
    if ($FileTags[$i] -ne "") {
        $ntext++
        try {
            $FileLines[$i] = Read-Lines (Join-Path $root $FilePaths[$i])
        } catch {
            $FileLines[$i] = New-Object string[] 0
        }
        $FileText[$i] = [string]::Join([string][char]10, $FileLines[$i])
    }
}

$isapi = @{}
$ispage = @{}
$islayout = @{}
$inlist = @{}

function In-Set([int]$i, [string]$set) {
    if ($FileTags[$i] -eq "") { return $false }
    if ($set.Length -eq 1) { return $FileTags[$i].Contains($set) }
    if ($set -eq "API") { return $isapi.ContainsKey($i) }
    if ($set -eq "NONAPI") { return $FileTags[$i].Contains("S") -and -not $isapi.ContainsKey($i) }
    if ($set -eq "PAGES") { return $ispage.ContainsKey($i) }
    if ($set -eq "LAYOUTS") { return $islayout.ContainsKey($i) }
    if ($set -eq "LIST") { return $inlist.ContainsKey($i) }
    return $false
}

function Trim-Text([string]$s) { return $s.Trim(" ", "`t") }

function First-Hit([string]$set, [string]$re, [bool]$ci) {
    $rx = Get-Rx $re $ci
    $mx = Get-Mx $re $ci
    for ($i = 0; $i -lt $np; $i++) {
        if (-not (In-Set $i $set)) { continue }
        if (-not $mx.IsMatch($FileText[$i])) { continue }
        $lines = $FileLines[$i]
        for ($n = 0; $n -lt $lines.Length; $n++) {
            if ($rx.IsMatch($lines[$n])) { return $FilePaths[$i] + ":" + ($n + 1) }
        }
    }
    return ""
}

function File-Has([int]$i, [string]$re, [bool]$ci) {
    if ($FileTags[$i] -eq "") { return 0 }
    if (-not (Get-Mx $re $ci).IsMatch($FileText[$i])) { return 0 }
    $rx = Get-Rx $re $ci
    $lines = $FileLines[$i]
    for ($n = 0; $n -lt $lines.Length; $n++) {
        if ($rx.IsMatch($lines[$n])) { return $n + 1 }
    }
    return 0
}

function Path-First([string]$re) {
    $rx = Get-Rx $re $false
    for ($i = 0; $i -lt $np; $i++) { if ($rx.IsMatch($FilePaths[$i])) { return $FilePaths[$i] } }
    return ""
}

$Leads = New-Object System.Collections.Generic.List[string]
$LC = @{}
$LF = @{}
$LCC = @{}
$LFC = @{}
$LO = @{}
function Add-Lead([string]$id, [string]$check, [string]$where, [string]$text) {
    $Leads.Add("$id $check ${where}: $text")
    $key = "$id|$check"
    if (-not $LCC.ContainsKey($key)) {
        if (-not $LO.ContainsKey($id)) { $LO[$id] = New-Object System.Collections.Generic.List[string] }
        $LO[$id].Add($check)
        $LFC[$key] = $where
        $LCC[$key] = 0
    }
    $LCC[$key]++
    if (-not $LC.ContainsKey($id)) {
        $LF[$id] = $where
        $LC[$id] = 0
    }
    $LC[$id]++
}
function Cnt([string]$id) { if ($LC.ContainsKey($id)) { return $LC[$id] } return 0 }
function Cntc([string]$id, [string]$check) { $key = "$id|$check"; if ($LCC.ContainsKey($key)) { return $LCC[$key] } return 0 }
function Lead-Counts([string]$id) {
    $parts = @()
    foreach ($c in $LO[$id]) { $parts += "$c " + $LCC["$id|$c"] }
    return ($parts -join ", ")
}

function Add-Hits([string]$set, [string]$re, [bool]$ci, [string]$id, [string]$check, [string]$ex, [bool]$exci) {
    $rx = Get-Rx $re $ci
    $mx = Get-Mx $re $ci
    $erx = $null
    if ($ex -ne "") { $erx = Get-Rx $ex $exci }
    $c = 0
    for ($i = 0; $i -lt $np; $i++) {
        if (-not (In-Set $i $set)) { continue }
        if (-not $mx.IsMatch($FileText[$i])) { continue }
        $lines = $FileLines[$i]
        for ($n = 0; $n -lt $lines.Length; $n++) {
            if (-not $rx.IsMatch($lines[$n])) { continue }
            if ($erx -and $erx.IsMatch($lines[$n])) { continue }
            Add-Lead $id $check ($FilePaths[$i] + ":" + ($n + 1)) (Trim-Text $lines[$n])
            $c++
        }
    }
    return $c
}

$Items = New-Object System.Collections.Generic.List[string]
$StatusCount = @{ "pass" = 0; "fail" = 0; "warn" = 0; "manual" = 0; "n/a" = 0 }
function Add-Item([string]$id, [string]$status, [string]$check, [string]$ev) {
    $Items.Add("$id $status ${check}: $ev")
    $StatusCount[$status]++
}

function Dep([string]$re) {
    $pattern = '"(' + $re + ')"[ \t]*:'
    for ($i = 0; $i -lt $np; $i++) {
        if (-not (In-Set $i "P")) { continue }
        if (File-Has $i $pattern $false) { return $true }
    }
    return $false
}
function Dep-Name([string]$re) {
    $rx = Get-Rx ('"(' + $re + ')"[ \t]*:') $false
    for ($i = 0; $i -lt $np; $i++) {
        if (-not (In-Set $i "P")) { continue }
        foreach ($line in $FileLines[$i]) {
            $m = $rx.Match($line)
            if ($m.Success) {
                $rest = $line.Substring($m.Index + 1)
                $qi = $rest.IndexOf('"')
                if ($qi -ge 0) { $rest = $rest.Substring(0, $qi) }
                return $rest
            }
        }
    }
    return ""
}
function Py-Dep([string]$re) {
    $pattern = '(^|[^a-z0-9_-])(' + $re + ')([^a-z0-9_-]|$)'
    for ($i = 0; $i -lt $np; $i++) {
        if ((In-Set $i "Y") -and (File-Has $i $pattern $true)) { return $true }
    }
    return $false
}
function Base-Name([string]$p) { $k = $p.LastIndexOf('/'); if ($k -ge 0) { return $p.Substring($k + 1) } return $p }
function Dir-Of([string]$p) { $k = $p.LastIndexOf('/'); if ($k -lt 0) { return "." } return $p.Substring(0, $k) }

function Redact([string]$s) {
    $s = [regex]::Replace($s, '(sk|rk)_(live|test)_[A-Za-z0-9]+', '<redacted>')
    $s = [regex]::Replace($s, 'AKIA[0-9A-Z]{16}', '<redacted>')
    $s = [regex]::Replace($s, 'gh[pousr]_[A-Za-z0-9]{20,}', '<redacted>')
    $s = [regex]::Replace($s, 'xox[abpr]-[A-Za-z0-9-]{10,}', '<redacted>')
    $s = [regex]::Replace($s, 'AIza[0-9A-Za-z_-]{30,}', '<redacted>')
    $s = [regex]::Replace($s, 'sk-ant-[A-Za-z0-9_-]{10,}', '<redacted>')
    $s = [regex]::Replace($s, 'sk-(proj-)?[A-Za-z0-9_-]{20,}', '<redacted>')
    $s = [regex]::Replace($s, 'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{5,}', '<redacted>')
    $s = [regex]::Replace($s, '-----BEGIN [A-Z ]*PRIVATE KEY-----', '<redacted>')
    $s = [regex]::Replace($s, '(://[^:/@ "'']+:)[^@/ "'']+@', '$1<redacted>@')
    $s = [regex]::Replace($s, '(([Ss]ecret|SECRET|[Tt]oken|TOKEN|[Pp]assword|PASSWORD|[Pp]asswd|PASSWD|[Aa]pi_?[Kk]ey|API_?KEY|[Pp]rivate_?[Kk]ey|PRIVATE_?KEY|[Cc]redential|CREDENTIAL|[Aa]ccess_?[Kk]ey|ACCESS_?KEY|SERVICE_ROLE|[Ss]ervice[Rr]ole|_KEY)[A-Za-z0-9_]*["'']?\s*[:=]\s*)(["''])[^"'']+["'']', '$1$3<redacted>$3')
    return $s
}

$FRAMEWORK = "unknown"
if (Dep "next") {
    if ((Path-First '^(src/)?app/(.*/)?(page|layout)\.(js|jsx|ts|tsx|mdx)$') -ne "") { $FRAMEWORK = "next-app" } else { $FRAMEWORK = "next-pages" }
} elseif (Dep '@remix-run/[a-z-]+|@react-router/dev') { $FRAMEWORK = "remix" }
elseif ((Dep "astro") -or ((Path-First '(^|/)astro\.config\.') -ne "")) { $FRAMEWORK = "astro" }
elseif (Dep '@sveltejs/kit') { $FRAMEWORK = "sveltekit" }
elseif ((Dep "nuxt") -or ((Path-First '(^|/)nuxt\.config\.') -ne "")) { $FRAMEWORK = "nuxt" }
elseif ((Dep 'vite|react-scripts') -or ((Path-First '(^|/)vite\.config\.') -ne "")) { $FRAMEWORK = "vite" }
elseif ((Path-First '\.html?$') -ne "") { $FRAMEWORK = "static" }

$apiPath = Get-Rx '^(src/)?pages/api/.*\.(js|jsx|ts|tsx|mjs)$|^(src/)?app/(.*/)?route\.(js|ts|mjs)$|(^|/)\+server\.(js|ts)$|(^|/)\+page\.server\.(js|ts)$|^server/(api|routes)/.*\.(js|ts)$' $false
$apiCode = '(app|router|fastify|bp|blueprint)\.(get|post|put|patch|delete|all|route)\(\s*["''`/]|@(app|router|bp|blueprint|api)\.(get|post|put|patch|delete|route)\(|^\s*["'']use server["'']|@(Get|Post|Put|Patch|Delete)\(|@api_view|def (get|post|put|patch|delete)\(self'
$napi = 0
for ($i = 0; $i -lt $np; $i++) {
    if (-not (In-Set $i "S")) { continue }
    if ($apiPath.IsMatch($FilePaths[$i]) -or (File-Has $i $apiCode $false)) {
        $isapi[$i] = 1
        $napi++
    }
}

$BACKEND = ""
$SB = $false
$FB = $false
$NODE = $false
$PY = $false
if ((Dep '@supabase/[a-z-]+') -or ((Path-First '^supabase/(config\.toml|migrations/)') -ne "")) { $BACKEND = "supabase"; $SB = $true }
if ((Dep 'firebase|firebase-admin') -or ((Path-First '(^|/)(firebase\.json|firestore\.rules|storage\.rules|database\.rules\.json)$') -ne "")) {
    if ($BACKEND -ne "") { $BACKEND += ", " }
    $BACKEND += "firebase"
    $FB = $true
}
$jsapi = $false
foreach ($k in $isapi.Keys) { if ($FilePaths[$k] -cmatch '\.(js|jsx|ts|tsx|mjs|cjs)$') { $jsapi = $true } }
if ((Dep 'express|fastify|koa|hono|@nestjs/core|@hapi/hapi|restify|@trpc/server') -or $jsapi) {
    if ($BACKEND -ne "") { $BACKEND += ", " }
    $BACKEND += "node"
    $NODE = $true
}
$pyFound = $false
for ($i = 0; $i -lt $np; $i++) { if ((In-Set $i "Y") -or ((In-Set $i "S") -and $FilePaths[$i] -cmatch '\.py$')) { $pyFound = $true } }
if ($pyFound) {
    if ($BACKEND -ne "") { $BACKEND += ", " }
    $BACKEND += "python"
    $PY = $true
}
if ($BACKEND -eq "") { $BACKEND = "none" }
$SERVER = ($napi -gt 0) -or $NODE -or $PY
$DB = $SB -or $FB

$f = Path-First '^(src/)?app/(.*/)?not-found\.(js|jsx|ts|tsx|mdx)$|^(src/)?pages/404\.(js|jsx|ts|tsx|astro|md|mdx|vue|html)$|(^|/)404\.html?$|(^|/)\+error\.svelte$|(^|/)error\.vue$'
if ($f -ne "") { Add-Item "FE1" "pass" "custom-404" "custom 404 page at $f" }
else {
    $f = Path-First '\[\[?\.\.\.[A-Za-z0-9_]*\]\]?|(^|/)routes/\$\.(js|jsx|ts|tsx)$'
    if ($f -ne "") { Add-Item "FE1" "warn" "custom-404" "catch-all route at $f, confirm unknown paths get a 404 page with status 404" }
    else { Add-Item "FE1" "fail" "custom-404" "no 404 page (app/not-found, pages/404, 404.html, +error.svelte or error.vue)" }
}

Add-Item "FE2" "manual" "cta-above-fold" "check at 375x812 and 1440x900 that the main action shows without scrolling and names the outcome"

switch ($FRAMEWORK) {
    "next-app" { $pagere = '^(src/)?app/(.*/)?page\.(js|jsx|ts|tsx|mdx)$' }
    "next-pages" { $pagere = '^(src/)?pages/.*\.(js|jsx|ts|tsx|mdx)$' }
    "astro" { $pagere = '^src/pages/.*\.(astro|md|mdx)$' }
    "sveltekit" { $pagere = '(^|/)\+page\.svelte$' }
    "nuxt" { $pagere = '^(app/)?pages/.*\.vue$' }
    "remix" { $pagere = '^app/routes/.*\.(js|jsx|ts|tsx)$' }
    default { $pagere = '\.html?$' }
}
$pageRx = Get-Rx $pagere $false
$skipRx = Get-Rx '(^|/)pages/api/|(^|/)_(app|document|error)\.|(^|/)(404|500|not-found|\+error)\.|(^|/)(api|resources?)\.|\.server\.|(^|/)google[0-9a-f]+\.html$' $false
$layoutRx = Get-Rx '(^|/)layout\.(js|jsx|ts|tsx)$|^(src/)?pages/_(app|document)\.|(^|/)layouts?/|(^|/)\+layout\.svelte$|(^|/)app\.vue$|(^|/)nuxt\.config\.|^app/root\.|(^|/)index\.html?$|^src/app\.html$' $false
for ($i = 0; $i -lt $np; $i++) {
    if ($FileTags[$i] -eq "") { continue }
    if ($pageRx.IsMatch($FilePaths[$i]) -and -not $skipRx.IsMatch($FilePaths[$i])) { $ispage[$i] = 1 }
    if ($layoutRx.IsMatch($FilePaths[$i])) { $islayout[$i] = 1 }
}
$SPA = $false
if ($FRAMEWORK -eq "vite" -and (Dep 'react-router|react-router-dom|vue-router|@tanstack/react-router|wouter|svelte-routing|@solidjs/router|preact-router')) {
    if ((First-Hit "S" 'document\.title|Helmet|useHead|@unhead|useTitle|useDocumentTitle' $false) -eq "") { $SPA = $true }
}

function Page-Meta([string]$id, [string]$check, [string]$re, [string]$label) {
    $total = 0
    $titled = 0
    $missing = ""
    $rootf = ""
    $firstp = ""
    for ($i = 0; $i -lt $np; $i++) {
        if ($ispage.ContainsKey($i)) {
            $total++
            if ($firstp -eq "") { $firstp = $FilePaths[$i] }
            if (File-Has $i $re $false) { $titled++ }
            elseif ($missing -eq "") { $missing = $FilePaths[$i] }
        }
        if ($islayout.ContainsKey($i) -and $rootf -eq "" -and (File-Has $i $re $false)) { $rootf = $FilePaths[$i] }
    }
    if ($total -eq 0) {
        if ($rootf -ne "") { Add-Item $id "warn" $check "$label in $rootf, no page files found to check one per page" }
        else { Add-Item $id "fail" $check "no page $label found" }
    } elseif ($titled -eq $total) {
        if ($SPA) { Add-Item $id "warn" $check "one $label in $firstp for a single page app with a router, set one per route" }
        else { Add-Item $id "pass" $check "own $label in all $total pages, for example $firstp" }
    } elseif ($rootf -ne "") {
        Add-Item $id "warn" $check "site wide $label in $rootf, own $label in $titled of $total pages, first without one: $missing"
    } else {
        Add-Item $id "fail" $check "own $label in $titled of $total pages, first without one: $missing"
    }
}
Page-Meta "FE3" "meta-title" '<title|export const metadata|generateMetadata|useHead\(|useSeoMeta\(|<Helmet|document\.title|export (const|function|let) meta|<NextSeo|<([A-Z][A-Za-z]*Layout|Layout|SEO|Seo|Head|Meta)[^>]*title=' "title"
Page-Meta "FE4" "meta-description" ('name=' + $Q + '?description|description\s*:|<NextSeo|<([A-Z][A-Za-z]*Layout|Layout|SEO|Seo|Head|Meta)[^>]*description=') "description"

$ogfile = Path-First '(^|/)opengraph-image[^/]*\.(png|jpe?g|gif|webp|js|jsx|ts|tsx)$'
$twfile = Path-First '(^|/)twitter-image[^/]*\.(png|jpe?g|gif|webp|js|jsx|ts|tsx)$'
$og = First-Hit "T" 'og:(title|description|image)|openGraph' $false
$ogimg = First-Hit "T" 'og:image' $false
if ($ogimg -eq "") {
    for ($i = 0; $i -lt $np; $i++) { if ((In-Set $i "T") -and (File-Has $i 'openGraph' $false)) { $inlist[$i] = 1 } }
    $ogimg = First-Hit "LIST" 'images\s*:' $false
    $inlist.Clear()
}
$tw = First-Hit "T" ('twitter:card|card\s*:\s*' + $Q + 'summary') $false
$imgev = $ogimg
if ($ogfile -ne "") { $imgev = $ogfile }
$ogev = $ogfile
if ($og -ne "") { $ogev = $og }
$twev = $twfile
if ($tw -ne "") { $twev = $tw }
if ($ogev -eq "" -and $imgev -eq "") { Add-Item "FE5" "fail" "open-graph" "no Open Graph tags or share image" }
else {
    $miss = @()
    if ($og -eq "") { $miss += "og:title and og:description" }
    if ($imgev -eq "") { $miss += "og:image" }
    if ($twev -eq "") { $miss += "twitter:card" }
    if ($miss.Count -eq 0) { Add-Item "FE5" "pass" "open-graph" "share image at $imgev, Open Graph tags at $ogev, twitter card at $twev" }
    else { Add-Item "FE5" "warn" "open-graph" ("missing " + ($miss -join ", ") + ", Open Graph found at $ogev") }
}

$ico = Path-First '(^|/)favicon\.ico$'
$icon = Path-First '(^|/)(favicon[^/]*|icon[0-9]*)\.(svg|png)$'
$apple = Path-First '(^|/)(apple-touch-icon[^/]*|apple-icon[0-9]*)\.(png|jpe?g)$'
$man = Path-First '(^|/)(site\.webmanifest|manifest\.(json|webmanifest|js|ts)|[^/]*\.webmanifest)$'
$mani = ""
if ($man -ne "" -and $FileTags[$PathIndex[$man]] -ne "" -and (File-Has $PathIndex[$man] ($Q + 'icons' + $Q + '|icons\s*:') $false)) { $mani = $man }
$have = 0
$miss = @()
if ($ico -ne "") { $have++ } else { $miss += "favicon.ico" }
if ($icon -ne "") { $have++ } else { $miss += "an SVG or PNG icon" }
if ($apple -ne "") { $have++ } else { $miss += "a 180px apple touch icon" }
if ($mani -ne "") { $have++ } else { $miss += "manifest icons" }
if ($have -eq 4) { Add-Item "FE6" "pass" "favicon-set" "$ico, $icon, $apple and icons in $mani" }
elseif ($have -eq 0) { Add-Item "FE6" "fail" "favicon-set" "no favicon, app icon, apple touch icon or manifest icons" }
else { Add-Item "FE6" "warn" "favicon-set" ("missing " + ($miss -join ", ")) }

function Robots-Block([int]$i) {
    $star = $false
    $rules = $false
    $lines = $FileLines[$i]
    for ($n = 0; $n -lt $lines.Length; $n++) {
        $line = $lines[$n].ToLowerInvariant()
        $hash = $line.IndexOf('#')
        if ($hash -ge 0) { $line = $line.Substring(0, $hash) }
        if ($line -cmatch '^[ \t]*user-agent[ \t]*:') {
            if ($rules) { $star = $false; $rules = $false }
            $v = ($line -creplace '^[ \t]*user-agent[ \t]*:[ \t]*', '') -creplace '[ \t]+$', ''
            if ($v -eq "*") { $star = $true }
            continue
        }
        if ($line -cmatch '^[ \t]*(dis)?allow[ \t]*:') { $rules = $true }
        if ($star -and $line -cmatch '^[ \t]*disallow[ \t]*:[ \t]*/[ \t]*$') { return $FilePaths[$i] + ":" + ($n + 1) }
    }
    return ""
}
$rb = Path-First '(^|/)robots\.txt$'
$rbr = Path-First '(^|/)robots\.(js|ts|mjs)$|(^|/)robots\.txt/\+server\.(js|ts)$|(^|/)robots\.txt\.(js|ts)$'
if ($rb -ne "" -and $FileTags[$PathIndex[$rb]] -ne "") {
    $dis = Robots-Block $PathIndex[$rb]
    $inlist.Clear()
    $inlist[$PathIndex[$rb]] = 1
    $sm = First-Hit "LIST" '^\s*sitemap\s*:' $true
    $inlist.Clear()
    if ($dis -ne "") { Add-Item "FE7" "fail" "robots-txt" "$dis disallows every path for all crawlers" }
    elseif ($sm -ne "") { Add-Item "FE7" "pass" "robots-txt" "$rb allows crawling and names the sitemap at $sm" }
    else { Add-Item "FE7" "warn" "robots-txt" "$rb has no Sitemap line" }
} elseif ($rbr -ne "") {
    $inlist.Clear()
    $inlist[$PathIndex[$rbr]] = 1
    $dis = First-Hit "LIST" ('disallow\s*:\s*' + $Q + '/' + $Q) $false
    $sm = First-Hit "LIST" 'sitemap' $true
    $inlist.Clear()
    if ($dis -ne "") { Add-Item "FE7" "fail" "robots-txt" "$dis disallows every path" }
    elseif ($sm -ne "") { Add-Item "FE7" "pass" "robots-txt" "$rbr allows crawling and names the sitemap at $sm" }
    else { Add-Item "FE7" "warn" "robots-txt" "$rbr has no sitemap entry" }
} else {
    $gen = First-Hit "T" 'generateRobotsTxt\s*:\s*true' $false
    $gendep = Dep-Name 'astro-robots-txt|@nuxtjs/robots|nuxt-simple-robots'
    if ($gen -ne "") { Add-Item "FE7" "pass" "robots-txt" "robots.txt generated by next-sitemap at $gen" }
    elseif ($gendep -ne "") { Add-Item "FE7" "pass" "robots-txt" "robots.txt generated by $gendep" }
    else { Add-Item "FE7" "fail" "robots-txt" "no robots.txt or robots route" }
}

$sm = Path-First '(^|/)sitemap[^/]*\.(xml|js|ts|mjs)$|(^|/)sitemap[^/]*\.xml/'
$smdep = Dep-Name 'next-sitemap|@astrojs/sitemap|@nuxtjs/sitemap|sitemap|vite-plugin-sitemap|svelte-sitemap|remix-sitemap|nuxt-simple-sitemap|astro-sitemap'
if ($sm -ne "") { Add-Item "FE8" "pass" "sitemap" "sitemap at $sm" }
elseif ($smdep -ne "") { Add-Item "FE8" "pass" "sitemap" "sitemap generated by $smdep" }
else { Add-Item "FE8" "fail" "sitemap" "no sitemap.xml, sitemap route or sitemap package" }

$script:images = 0
$script:noalt = 0
$script:weakalt = 0
$tagRx = New-Object System.Text.RegularExpressions.Regex('<(img|Image|NuxtImg|NuxtPicture)([ \t]|/?>|$)')
$altValRx = New-Object System.Text.RegularExpressions.Regex('[ \t]alt[ \t]*=[ \t]*["''][^"'']*["'']')
function Done-Tag([string]$tag, [string]$where, [string]$text) {
    $script:images++
    if (($tag -cnotmatch '[ \t]alt[ \t]*=') -and ($tag -cnotmatch '\{[ \t]*\.\.\.')) {
        $script:noalt++
        Add-Lead "FE9" "img-without-alt" $where $text
        return
    }
    $m = $altValRx.Match($tag)
    if ($m.Success) {
        $v = $m.Value -creplace '^[ \t]alt[ \t]*=[ \t]*["'']', ''
        $v = $v.Substring(0, $v.Length - 1)
        $lv = (Trim-Text $v).ToLowerInvariant()
        if (($lv -cmatch '^(image|img|photo|picture|pic|graphic|banner|screenshot|untitled)$') -or ($lv -cmatch '\.(png|jpe?g|gif|webp|svg|avif)$') -or ($lv -cmatch '^(image|picture|photo) of ')) {
            $script:weakalt++
            Add-Lead "FE9" "weak-alt" $where $text
        }
    }
}
for ($i = 0; $i -lt $np; $i++) {
    if (-not (In-Set $i "M")) { continue }
    $lines = $FileLines[$i]
    $pending = $false
    $buf = ""
    $twhere = ""
    $ttext = ""
    $tline = 0
    for ($n = 0; $n -lt $lines.Length; $n++) {
        $line = $lines[$n]
        $rest = $line
        if ($pending) {
            $p = $rest.IndexOf('>')
            if ($p -ge 0) {
                $buf = $buf + " " + $rest.Substring(0, $p + 1)
                Done-Tag $buf $twhere $ttext
                $pending = $false
                $rest = $rest.Substring($p + 1)
            } else {
                $buf = $buf + " " + $rest
                if (($n + 1) - $tline -ge 8) { Done-Tag $buf $twhere $ttext; $pending = $false }
                continue
            }
        }
        while ($true) {
            $m = $tagRx.Match($rest)
            if (-not $m.Success) { break }
            $tag = $rest.Substring($m.Index)
            $tline = $n + 1
            $twhere = $FilePaths[$i] + ":" + $tline
            $ttext = Trim-Text $line
            $p = $tag.IndexOf('>')
            if ($p -ge 0) {
                Done-Tag $tag.Substring(0, $p + 1) $twhere $ttext
                $rest = $tag.Substring($p + 1)
            } else {
                $buf = $tag
                $pending = $true
                break
            }
        }
    }
    if ($pending) { Done-Tag $buf $twhere $ttext }
}
if ($script:images -eq 0) { Add-Item "FE9" "n/a" "image-alt" "no images found" }
elseif ($script:noalt -gt 0) { Add-Item "FE9" "fail" "image-alt" ("$($script:noalt) of $($script:images) images have no alt, first at " + $LFC["FE9|img-without-alt"]) }
elseif ($script:weakalt -gt 0) { Add-Item "FE9" "warn" "image-alt" ("$($script:weakalt) of $($script:images) alt texts are a file name or a generic word, first at " + $LFC["FE9|weak-alt"]) }
else { Add-Item "FE9" "pass" "image-alt" "all $($script:images) images have alt text" }

if ($FRAMEWORK -eq "next-app" -or $FRAMEWORK -eq "next-pages" -or $FRAMEWORK -eq "nuxt") { $vp = "added by default in $FRAMEWORK" }
else {
    $vp = First-Hit "T" ('name=' + $Q + 'viewport|export const viewport|viewport\s*:') $false
    if ($vp -ne "") { $vp = "at $vp" }
}
$resp = First-Hit "W" '@media[^{]*(min|max)-width|@container|[ "''`](sm|md|lg|xl|2xl):[a-z]' $false
if ($vp -eq "") { Add-Item "FE10" "fail" "mobile-breakpoints" "no viewport meta tag" }
elseif ($resp -eq "") { Add-Item "FE10" "warn" "mobile-breakpoints" "viewport $vp but no responsive styles (media queries or breakpoint classes)" }
else { Add-Item "FE10" "manual" "mobile-breakpoints" "viewport $vp, responsive styles at $resp, check 375, 768 and 1440 for sideways scroll" }

$st = First-Hit "W" '(fixed|sticky)[^"'']*bottom-0|bottom-0[^"'']*(fixed|sticky)|position:\s*(fixed|sticky)' $false
if ($st -ne "") { Add-Item "FE11" "manual" "sticky-mobile-cta" "fixed or sticky element at $st, check that long landing pages keep the main action in reach at 375" }
else { Add-Item "FE11" "manual" "sticky-mobile-cta" "no fixed bottom bar found, check that long landing pages keep the main action in reach at 375" }

$skf = Path-First '(^|/)(loading\.(js|jsx|ts|tsx)|[^/]*[Ss]keleton[^/]*\.(js|jsx|ts|tsx|vue|svelte|astro))$'
$skh = First-Hit "W" 'Skeleton|skeleton|animate-pulse|aria-busy' $false
$ld = First-Hit "M" 'isLoading|isPending|loading\s*(&&|\?)|<Suspense|\{#await|Loading\.\.\.|<Spinner|spinner' $false
$fe = First-Hit "S" ('fetch\(|useQuery|useSWR|axios|getDocs|onSnapshot|useFetch|useAsyncData|\.from\(' + $Q + '[a-z_]+' + $Q + '\)\.select') $false
if ($skf -ne "") { Add-Item "FE12" "pass" "loading-states" "skeleton at $skf" }
elseif ($skh -ne "") { Add-Item "FE12" "pass" "loading-states" "skeleton at $skh" }
elseif ($ld -ne "") { Add-Item "FE12" "warn" "loading-states" "loading flag at $ld but no skeleton" }
elseif ($fe -ne "") { Add-Item "FE12" "fail" "loading-states" "data loads at $fe with no loading state" }
else { Add-Item "FE12" "n/a" "loading-states" "no client side data loading found" }

$form = First-Hit "M" '<form|<Form[ >]|useForm\(|onSubmit|handleSubmit|use:enhance|<v-form' $false
$aria = First-Hit "M" 'aria-invalid|aria-describedby|aria-errormessage' $false
$ferr = First-Hit "M" 'FormMessage|ErrorMessage|fieldErrors|formState|errors\.[A-Za-z_]+|errors\[|setError\(|\$errors|setCustomValidity|validationErrors' $false
if ($form -eq "") { Add-Item "FE13" "n/a" "form-errors" "no forms found" }
elseif ($aria -ne "") { Add-Item "FE13" "pass" "form-errors" "field errors tied to inputs at $aria" }
elseif ($ferr -ne "") { Add-Item "FE13" "warn" "form-errors" "field errors at $ferr are not tied to the input with aria-describedby and aria-invalid" }
else { Add-Item "FE13" "fail" "form-errors" "the form at $form shows no inline error state" }

$okp = Path-First '(^|/)[^/]*(thank-you|thankyou|thanks|success|confirmation|confirmed)[^/]*(/|\.)'
$okh = First-Hit "M" 'thank you|thanks for|isSubmitted|isSubmitSuccessful|isSuccess|setSuccess|toast\.success|successMessage|status === .success' $true
if ($form -eq "") { Add-Item "FE14" "n/a" "form-success" "no forms found" }
elseif ($okp -ne "") { Add-Item "FE14" "pass" "form-success" "success page at $okp" }
elseif ($okh -ne "") { Add-Item "FE14" "pass" "form-success" "success state at $okh" }
else { Add-Item "FE14" "fail" "form-success" "no thank you page or success state after the form at $form" }

function Legal([string]$id, [string]$check, [string]$pagere, [string]$linkre, [string]$label) {
    $pg = Path-First $pagere
    $foot = ""
    $any = ""
    $ext = ""
    $lrx = Get-Rx $linkre $true
    $lmx = Get-Mx $linkre $true
    $erx = Get-Rx ('(href|to)=[{]?' + $Q + '?https?://') $true
    for ($i = 0; $i -lt $np; $i++) {
        if (-not (In-Set $i "M")) { continue }
        if (-not $lmx.IsMatch($FileText[$i])) { continue }
        $lines = $FileLines[$i]
        for ($n = 0; $n -lt $lines.Length; $n++) {
            if (-not $lrx.IsMatch($lines[$n])) { continue }
            $where = $FilePaths[$i] + ":" + ($n + 1)
            if ($any -eq "") { $any = $where }
            if ($foot -eq "" -and $FilePaths[$i].ToLowerInvariant() -cmatch 'footer|layout') { $foot = $where }
            if ($ext -eq "" -and $erx.IsMatch($lines[$n])) { $ext = $where }
        }
    }
    if ($pg -ne "" -and $foot -ne "") { Add-Item $id "pass" $check "page at $pg, linked from $foot" }
    elseif ($pg -ne "" -and $any -ne "") { Add-Item $id "warn" $check "page at $pg is linked from $any, not from the footer" }
    elseif ($pg -ne "") { Add-Item $id "warn" $check "page at $pg but nothing links to it" }
    elseif ($ext -ne "") { Add-Item $id "pass" $check "links to a hosted $label at $ext" }
    elseif ($any -ne "") { Add-Item $id "fail" $check "link at $any but no $label page in the project" }
    else { Add-Item $id "fail" $check "no $label page" }
}
Legal "FE15" "privacy-page" '(^|/)[^/]*privacy[^/]*(/[^/]*)?\.(js|jsx|ts|tsx|md|mdx|astro|vue|svelte|html?)$' ('(href|to)=[{]?' + $Q + '?[^"''` >}]*privacy') "privacy policy"
Legal "FE16" "terms-page" '(^|/)(tos|[^/]*terms[^/]*|[^/]*conditions[^/]*)(/[^/]*)?\.(js|jsx|ts|tsx|md|mdx|astro|vue|svelte|html?)$' ('(href|to)=[{]?' + $Q + '?[^"''` >}]*(terms|/tos|conditions)') "terms"

$trackRe = 'gtag\(|googletagmanager\.com|google-analytics\.com|react-ga|GoogleAnalytics|posthog|mixpanel|segment\.(com|io)|@segment/|@amplitude/|amplitude\.com|clarity\.ms|hotjar|fbq\(|connect\.facebook\.net|snap\.licdn\.com|analytics\.tiktok\.com|intercom|hs-scripts\.com'
$an = First-Hit "T" 'gtag\(|googletagmanager\.com|google-analytics\.com|react-ga|GoogleAnalytics|plausible\.io|next-plausible|plausible-tracker|posthog|umami|@vercel/analytics|usefathom|fathom-client|mixpanel|segment\.(com|io)|@segment/|@amplitude/|amplitude\.com|matomo|piwik|simpleanalytics|cloudflareinsights|clarity\.ms|hotjar|fbq\(|connect\.facebook\.net' $true
$pf = First-Hit "T" 'plausible\.io|next-plausible|plausible-tracker|umami|@vercel/analytics|usefathom|fathom-client|simpleanalytics|cloudflareinsights|matomo|piwik' $true
$tr = First-Hit "T" $trackRe $true
$cs = First-Hit "T" ('cookieconsent|cookie-consent|react-cookie-consent|vanilla-cookieconsent|cookiebot|onetrust|osano|klaro|tarteaucitron|iubenda|termly|usercentrics|cookiehub|CookieBanner|ConsentBanner|cookie-banner|consent-banner|gtag\(' + $Q + 'consent|ad_storage|analytics_storage') $true
if ($tr -eq "") { Add-Item "FE17" "n/a" "cookie-consent" "no trackers or ad pixels found" }
elseif ($cs -ne "") { Add-Item "FE17" "manual" "cookie-consent" "trackers at $tr, consent banner at $cs, check that reject is as easy as accept and nothing loads before consent" }
else {
    [void](Add-Hits "M" $trackRe $true "FE17" "tracker-without-consent" "" $false)
    Add-Item "FE17" "fail" "cookie-consent" "tracker at $tr loads with no consent banner"
}
[void](Add-Hits "T" ($Q + '(G|GTM)-X{4,}|' + $Q + 'UA-X{4,}|data-domain=' + $Q + '(example\.com|yourdomain|your-domain)|(G|GTM)-XXXX') $true "FE18" "placeholder-id" "" $false)
if ($an -eq "") { Add-Item "FE18" "fail" "analytics" "no analytics found" }
elseif ((Cnt "FE18") -gt 0) { Add-Item "FE18" "fail" "analytics" ("analytics ID at " + $LF["FE18"] + " looks like a placeholder") }
elseif ($pf -ne "") { Add-Item "FE18" "pass" "analytics" "privacy friendly analytics at $pf" }
elseif ($tr -ne "" -and $cs -ne "") { Add-Item "FE18" "pass" "analytics" "analytics at $tr, consent gate at $cs" }
elseif ($tr -ne "") { Add-Item "FE18" "warn" "analytics" "analytics at $tr with no consent gate (see FE17)" }
else { Add-Item "FE18" "pass" "analytics" "analytics at $an" }

function Comment-Skip([string]$t, [bool]$todo) {
    if ($t.ToLowerInvariant().Contains("placeholder")) { return $true }
    if ($t -cmatch '^[ \t]*(//|/\*|\*|\{/\*|<!--)') { return $true }
    if ($todo -and $t -cmatch '(//|/\*|<!--|\{/\*).*(TODO|TBD|FIXME)') { return $true }
    return $false
}
$phRx = Get-Rx 'lorem ipsum|dolor sit amet|example\.(com|org|net)|123 main st|\(?555\)?[-. ][0-9]{3}[-. ]?[0-9]{4}|555-01[0-9]{2}|john doe|jane doe|(^|[^a-z])acme([^a-z]|$)|your company|company name|your@email|yourdomain\.com' $true
for ($i = 0; $i -lt $np; $i++) {
    if (-not (In-Set $i "H")) { continue }
    $lines = $FileLines[$i]
    for ($n = 0; $n -lt $lines.Length; $n++) {
        if (-not $phRx.IsMatch($lines[$n])) { continue }
        if (Comment-Skip $lines[$n] $false) { continue }
        Add-Lead "FE19" "placeholder" ($FilePaths[$i] + ":" + ($n + 1)) (Trim-Text $lines[$n])
    }
}
$todoRx = Get-Rx '(^|[^A-Za-z])(TODO|TBD|FIXME)([^A-Za-z]|$)' $false
for ($i = 0; $i -lt $np; $i++) {
    if (-not (In-Set $i "M")) { continue }
    $lines = $FileLines[$i]
    for ($n = 0; $n -lt $lines.Length; $n++) {
        if (-not $todoRx.IsMatch($lines[$n])) { continue }
        if (Comment-Skip $lines[$n] $true) { continue }
        Add-Lead "FE19" "todo-in-page" ($FilePaths[$i] + ":" + ($n + 1)) (Trim-Text $lines[$n])
    }
}
$contact = First-Hit "M" 'mailto:|tel:' $false
if ($contact -eq "") { $contact = Path-First '(^|/)[^/]*contact[^/]*(/[^/]*)?\.(js|jsx|ts|tsx|md|mdx|astro|vue|svelte|html?)$' }
if ((Cnt "FE19") -gt 0) { Add-Item "FE19" "fail" "real-content" ("placeholder lines: " + (Cnt "FE19") + ", first at " + $LF["FE19"]) }
elseif ($contact -eq "") { Add-Item "FE19" "warn" "real-content" "no email link, phone link or contact page found" }
else { Add-Item "FE19" "pass" "real-content" "contact at $contact, no placeholder text found" }

[void](Add-Hits "M" ('(src|href|action)=' + $Q + 'http://') $false "FE20" "insecure-url" 'http://(localhost|127\.0\.0\.1|0\.0\.0\.0|www\.w3\.org)' $false)
$site = First-Hit "T" ('metadataBase|(^|[^A-Za-z_])site\s*:\s*' + $Q + 'https?://|siteUrl\s*[:=]|SITE_URL\s*=') $false
if ((Cnt "FE20") -gt 0) { Add-Item "FE20" "warn" "domain-https" ("resources loaded over http: " + (Cnt "FE20") + ", first at " + $LF["FE20"]) }
elseif ($site -ne "") { Add-Item "FE20" "manual" "domain-https" "site URL at $site, run prod-url on the live domain for HTTPS and load time" }
else { Add-Item "FE20" "manual" "domain-https" "run prod-url on the live domain for HTTPS and load time" }

$pubRx = Get-Rx '(NEXT_PUBLIC|VITE|REACT_APP|EXPO_PUBLIC|NUXT_PUBLIC|VUE_APP|GATSBY|PUBLIC)_[A-Z0-9_]*(SECRET|PRIVATE|PASSWORD|PASSWD|TOKEN|SERVICE_?ROLE|CREDENTIAL|API_?KEY|DATABASE_?URL|DB_?URL)' $false
$pubEx = Get-Rx 'PUBLISHABLE|ANON|SEARCH|MAPS|SITE_?KEY|PUBLIC_?KEY|CLIENT_?KEY' $false
for ($i = 0; $i -lt $np; $i++) {
    if (-not (In-Set $i "T")) { continue }
    $lines = $FileLines[$i]
    for ($n = 0; $n -lt $lines.Length; $n++) {
        if (-not $pubRx.IsMatch($lines[$n])) { continue }
        if ($pubEx.IsMatch($lines[$n])) { continue }
        $t = Trim-Text $lines[$n]
        if (In-Set $i "E") {
            $k = $t.IndexOf('=')
            if ($k -ge 0) { $t = $t.Substring(0, $k) + "=<redacted>" }
        }
        Add-Lead "BE1" "public-env-secret" ($FilePaths[$i] + ":" + ($n + 1)) $t
    }
}
[void](Add-Hits "N" 'sk_live_[0-9A-Za-z]{8,}|rk_live_[0-9A-Za-z]{8,}|AKIA[0-9A-Z]{16}|gh[pousr]_[0-9A-Za-z]{30,}|xox[abpr]-[0-9A-Za-z-]{10,}|sk-ant-[0-9A-Za-z_-]{20,}|sk-proj-[0-9A-Za-z_-]{20,}|sk-[0-9A-Za-z]{20,}|-----BEGIN ([A-Z]+ )?PRIVATE KEY-----' $false "BE1" "hardcoded-key" "" $false)
[void](Add-Hits "T" ('productionBrowserSourceMaps\s*:\s*true|sourcemap\s*:\s*true|GENERATE_SOURCEMAP\s*=\s*true|devtool\s*:\s*' + $Q + '(inline-)?source-map' + $Q) $true "BE1" "sourcemap-public" "" $false)
$envreal = ""
for ($i = 0; $i -lt $np; $i++) {
    if ($FilePaths[$i] -cmatch '(^|/)\.env[^/]*$' -and $FilePaths[$i] -cnotmatch '\.(example|sample|template|dist|defaults)$') { $envreal = $FilePaths[$i]; break }
}

$gitState = "norepo"
$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) { $gitState = "nogit" }
else {
    $inside = & git -C $root rev-parse --is-inside-work-tree 2>$null
    if ("$inside".Trim() -eq "true") { $gitState = "ok" }
}
if ($gitState -eq "ok") {
    $tracked = @(& git -C $root ls-files -- '*.env' '*.env.*' 2>$null)
    foreach ($t in $tracked) {
        $t = "$t".TrimEnd([char]13)
        if ($t -eq "") { continue }
        if ((Base-Name $t) -cmatch '^\.env' -and $t -cnotmatch '\.(example|sample|template|dist|defaults)$') { Add-Lead "BE1" "env-tracked" $t "tracked by git, remove it from the repo and rotate every value in it" }
    }
}
$gi = ""
if ($gitState -eq "ok" -and -not (Test-Path -LiteralPath (Join-Path $root ".gitignore"))) {
    $top = "$(& git -C $root rev-parse --show-toplevel 2>$null)".Trim()
    if ($top -ne "" -and (Test-Path -LiteralPath (Join-Path $top ".gitignore"))) { $gi = "$top/.gitignore" }
}
if (Test-Path -LiteralPath (Join-Path $root ".gitignore")) { $gi = ".gitignore" }
$ign = ""
if ($gi -ne "") {
    $giPath = $gi
    if ($gi -eq ".gitignore") { $giPath = Join-Path $root ".gitignore" }
    $gil = Read-Lines $giPath
    for ($k = 0; $k -lt $gil.Length; $k++) {
        if ($gil[$k] -cmatch '^[ \t]*(/|\*\*/|\*)?\.env') { $ign = $gi + ":" + ($k + 1); break }
    }
}
if ($ign -eq "" -and $envreal -ne "") {
    $giShow = $gi
    if ($giShow -eq "") { $giShow = ".gitignore" }
    Add-Lead "BE1" "env-not-ignored" $giShow "no line ignores .env files, so $envreal can be committed"
}
if ((Cnt "BE1") -gt 0) { Add-Item "BE1" "fail" "hide-api-keys" ((Lead-Counts "BE1") + ", first at " + $LF["BE1"]) }
elseif ($ign -eq "") { Add-Item "BE1" "warn" "hide-api-keys" "no .gitignore line ignores .env files, add .env* before the first env file is created" }
else { Add-Item "BE1" "pass" "hide-api-keys" "no secret behind a public prefix, no key in code, no public source maps, .env ignored at $ign" }

$script:nbuckets = 0
$Buckets = New-Object System.Collections.Generic.List[string]
$Tables = New-Object System.Collections.Generic.List[string]
$TableWhere = @{}
$TableText = @{}
$Rls = @{}
function Norm-Table([string]$t) { return ($t.Replace('"', '') -creplace '^public\.', '') }
function Handle-Stmt([string]$file, [int]$ln, [string]$text, [string]$buf) {
    $s = ($buf.ToLowerInvariant() -creplace '[ \t]+', ' ') -creplace '^ ', ''
    if ($s -cmatch 'storage\.buckets') { $script:nbuckets++ }
    if ($s -cmatch '^insert into storage\.buckets' -and $s -cmatch '(^|[^a-z_])true([^a-z_]|$)') { $Buckets.Add("$file`:$ln`t$text") }
    if ($s -cmatch '^update storage\.buckets ' -and $s -cmatch 'public ?= ?true') { $Buckets.Add("$file`:$ln`t$text") }
    $m = [regex]::Match($s, '^create (unlogged )?table (if not exists )?[a-z0-9_."]+')
    if ($m.Success) {
        $t = $m.Value -creplace '^create (unlogged )?table (if not exists )?', ''
        $raw = $t.Replace('"', '')
        if (-not ($raw.Contains('.') -and $raw -cnotmatch '^public\.')) {
            $t = Norm-Table $t
            if (-not $TableWhere.ContainsKey($t)) {
                $Tables.Add($t)
                $TableWhere[$t] = "$file`:$ln"
                $TableText[$t] = $text
            }
        }
    } elseif ($s -cmatch '^alter table (if exists )?(only )?[a-z0-9_."]+ enable row level security') {
        $t = ($s -creplace '^alter table (if exists )?(only )?', '') -creplace ' .*$', ''
        $Rls[(Norm-Table $t)] = 1
    } elseif ($s -cmatch '^create policy ') {
        $cmd = "all"
        $pm = [regex]::Match($s, ' for (all|select|insert|update|delete)( |$)')
        if ($pm.Success) { $cmd = $pm.Groups[1].Value }
        if ($cmd -ne "select" -and $s -cmatch '(using|with check) ?\( ?true ?\)') { Add-Lead "BE2" "open-policy" "$file`:$ln" $text }
    }
}
for ($i = 0; $i -lt $np; $i++) {
    if (-not (In-Set $i "Q")) { continue }
    $buf = ""
    $sline = 0
    $stext = ""
    $lines = $FileLines[$i]
    for ($n = 0; $n -lt $lines.Length; $n++) {
        $line = $lines[$n]
        $code = $line
        $dash = $code.IndexOf("--")
        if ($dash -ge 0) { $code = $code.Substring(0, $dash) }
        $rest = $code
        while (($p = $rest.IndexOf(';')) -ge 0) {
            $piece = $rest.Substring(0, $p)
            if ($sline -eq 0 -and $piece -cmatch '[^ \t]') { $sline = $n + 1; $stext = Trim-Text $line }
            $buf = $buf + " " + $piece
            if ($buf -cmatch '[^ \t]') { Handle-Stmt $FilePaths[$i] $sline $stext $buf }
            $buf = ""
            $sline = 0
            $rest = $rest.Substring($p + 1)
        }
        if ($rest -cmatch '[^ \t]') {
            if ($sline -eq 0) { $sline = $n + 1; $stext = Trim-Text $line }
            $buf = $buf + " " + $rest
        }
    }
    if ($buf -cmatch '[^ \t]') { Handle-Stmt $FilePaths[$i] $sline $stext $buf }
}
$withrls = 0
foreach ($t in $Tables) {
    if ($Rls.ContainsKey($t)) { $withrls++ }
    else { Add-Lead "BE2" "table-without-rls" $TableWhere[$t] $TableText[$t] }
}
$openRule = 'allow\s+[^:;]*(write|create|update|delete)[^:;]*(;|:\s*if\s+true)|request\.time\s*<|"\.(read|write)"\s*:\s*"?true'
$fsr = ""
for ($i = 0; $i -lt $np; $i++) {
    if ((In-Set $i "T") -and $FilePaths[$i] -cmatch '(^|/)(firestore\.rules|database\.rules\.json)$') {
        if ($fsr -eq "") { $fsr = $FilePaths[$i] }
        $inlist[$i] = 1
    }
}
[void](Add-Hits "LIST" $openRule $false "BE2" "open-rules" "" $false)
$inlist.Clear()
if (-not $DB) { Add-Item "BE2" "n/a" "rls" "no Supabase or Firebase, the server owns data access (see BE19)" }
elseif ((Cnt "BE2") -gt 0) { Add-Item "BE2" "fail" "rls" ((Lead-Counts "BE2") + ", first at " + $LF["BE2"]) }
else {
    $parts = @()
    $status = "pass"
    if ($SB) {
        if ($Tables.Count -gt 0) { $parts += "RLS on all $($Tables.Count) tables in the migrations" }
        else { $parts += "no table migrations in the repo, check RLS in the Supabase dashboard"; $status = "manual" }
    }
    if ($FB) {
        if ($fsr -ne "") { $parts += "no open rule in $fsr" }
        else { $parts += "no firestore.rules in the repo, check the rules in the Firebase console"; $status = "manual" }
    }
    Add-Item "BE2" $status "rls" ($parts -join ", ")
}

$idr = Path-First '\[(id|[A-Za-z_]*Id|[A-Za-z_]*_id)\]'
if ($idr -eq "") { $idr = First-Hit "S" ('["''`][^"''`]*/:[A-Za-z_]*[iI]d') $false }
if ($idr -ne "") { Add-Item "BE3" "manual" "idor-test" "active test, run /security with two accounts against routes that take an id such as $idr" }
else { Add-Item "BE3" "manual" "idor-test" "active test, run /security with two accounts against every route that takes an id" }

if (Get-Command gitleaks -ErrorAction SilentlyContinue) { $tool = "gitleaks is installed, run gitleaks git for a full scan" }
elseif (Get-Command trufflehog -ErrorAction SilentlyContinue) { $tool = "trufflehog is installed, run trufflehog git file://. for a full scan" }
else { $tool = "gitleaks not installed so this is a pattern search only" }
$kindRx = [ordered]@{
    "aws-access-key" = 'AKIA[0-9A-Z]{16}'
    "stripe-live-key" = 'sk_live_[0-9A-Za-z]{10,}'
    "github-token" = 'ghp_[0-9A-Za-z]{30,}'
    "slack-token" = 'xox[abp]-[0-9A-Za-z-]{10,}'
    "google-api-key" = 'AIza[0-9A-Za-z_-]{30,}'
    "anthropic-key" = 'sk-ant-[0-9A-Za-z_-]{20,}'
    "openai-key" = 'sk-proj-[0-9A-Za-z_-]{20,}|sk-[0-9A-Za-z]{20,}'
    "private-key" = '-----BEGIN ([A-Z]+ )?PRIVATE KEY-----'
}
function Kinds-Of($found) {
    $names = @()
    foreach ($name in $kindRx.Keys) { if ($found.ContainsKey($name)) { $names += $name } }
    if ($names.Count -eq 0) { return "key pattern" }
    return ($names -join ", ")
}
if ($gitState -eq "nogit") { Add-Item "BE4" "manual" "git-history-secrets" "git is not installed, scan the history with gitleaks or trufflehog" }
elseif ($gitState -ne "ok") { Add-Item "BE4" "manual" "git-history-secrets" "not a git repository, scan the history of the repo that deploys this code" }
else {
    $commits = "$(& git -C $root rev-list --all --count -- . 2>$null)".Trim()
    if ($commits -eq "") { $commits = "0" }
    $keyRe = 'AKIA[0-9A-Z]{16}|sk_live_[0-9A-Za-z]{10,}|ghp_[0-9A-Za-z]{30,}|xox[abp]-[0-9A-Za-z-]{10,}|AIza[0-9A-Za-z_-]{30,}|sk-ant-[0-9A-Za-z_-]{20,}|sk-proj-[0-9A-Za-z_-]{20,}|sk-[0-9A-Za-z]{20,}|-----BEGIN ([A-Z]+ )?PRIVATE KEY-----'
    $histp = @(& git -C $root log --all -E "-G$keyRe" -p --no-color --no-ext-diff '--format=@%h' --relative -- . 2>$null | Select-Object -First 20000)
    $pairs = New-Object System.Collections.Generic.List[object]
    $h = ""
    $f = ""
    $found = @{}
    foreach ($raw in $histp) {
        $line = "$raw".TrimEnd([char]13)
        if ($line -cmatch '^@[0-9a-f]+$') {
            if ($f -ne "" -and $pairs.Count -lt 20) { $pairs.Add(@($h, $f, (Kinds-Of $found))) }
            $f = ""
            $found = @{}
            $h = $line.Substring(1)
            continue
        }
        if ($line -cmatch '^diff --git ') {
            if ($f -ne "" -and $pairs.Count -lt 20) { $pairs.Add(@($h, $f, (Kinds-Of $found))) }
            $found = @{}
            $f = ($line -creplace '^diff --git "?a/', '') -creplace '"? "?b/.*$', ''
            continue
        }
        if ($line -cmatch '^(\+\+\+|---) ') { continue }
        if ($line -cmatch '^[-+]') {
            foreach ($name in $kindRx.Keys) { if ($line -cmatch $kindRx[$name]) { $found[$name] = 1 } }
        }
    }
    if ($f -ne "" -and $pairs.Count -lt 20) { $pairs.Add(@($h, $f, (Kinds-Of $found))) }
    $seenc = @{}
    $ncommit = 0
    $nnongoogle = 0
    foreach ($pair in $pairs) {
        Add-Lead "BE4" "secret-in-history" ($pair[1] + "@" + $pair[0]) ($pair[2] + ", value not shown")
        if (-not $seenc.ContainsKey($pair[0])) { $seenc[$pair[0]] = 1; $ncommit++ }
        if ($pair[2] -ne "google-api-key") { $nnongoogle++ }
    }
    $envh = @(& git -C $root log --all --diff-filter=A '--format=@%h' --name-only --relative -- '*.env' '*.env.*' 2>$null)
    foreach ($raw in $envh) {
        $line = "$raw".TrimEnd([char]13)
        if ($line -cmatch '^@[0-9a-f]+$') { $h = $line.Substring(1); continue }
        if ($line -eq "") { continue }
        if ((Base-Name $line) -cmatch '^\.env' -and $line -cnotmatch '\.(example|sample|template|dist|defaults)$') { Add-Lead "BE4" "env-in-history" ($line + "@" + $h) "env file committed, rotate every value it held" }
    }
    if ([int]$commits -eq 0) { Add-Item "BE4" "manual" "git-history-secrets" "no commit touches this folder yet, keep .env files out of the first commit and scan again after it" }
    elseif ((Cnt "BE4") -eq 0) { Add-Item "BE4" "pass" "git-history-secrets" "no key pattern or .env file in $commits commits, $tool" }
    elseif ($nnongoogle -eq 0 -and (Cntc "BE4" "env-in-history") -eq 0) { Add-Item "BE4" "warn" "git-history-secrets" "Google API key in history, fine for a Firebase web config only if the key is restricted, $tool" }
    else { Add-Item "BE4" "fail" "git-history-secrets" ((Lead-Counts "BE4") + " in $ncommit commits, first at " + $LF["BE4"] + ", rotate those keys, $tool") }
}

$roleRe = '\.role\s*(===|!==|==|!=)|role\s*(===|!==|==|!=)|isAdmin|is_admin|requireAdmin|requireRole|adminOnly|hasRole|checkRole|is_staff|is_superuser|@Roles|RolesGuard|staff_member_required|permission_required|user_passes_test|authorize\(|can\('
$mwRx = Get-Rx '^(src/)?middleware\.(js|ts)$|(^|/)hooks\.server\.(js|ts)$|^server/middleware/[^/]*\.(js|ts)$' $false
$mwcover = ""
for ($i = 0; $i -lt $np; $i++) {
    if ($FileTags[$i] -eq "" -or -not $mwRx.IsMatch($FilePaths[$i])) { continue }
    if ((File-Has $i 'admin' $false) -and (File-Has $i $roleRe $false)) { $mwcover = $FilePaths[$i]; break }
}
$adminPathRx = Get-Rx '(^|/)(app|pages|routes|api|server|controllers|views)/(.*/)?admin([/._-]|$)' $false
$adminRoute = '(get|post|put|patch|delete|use|all|route)\(\s*' + $Q + '(/api)?/admin'
$layoutNames = @("layout.tsx", "layout.ts", "layout.jsx", "layout.js", "+layout.server.ts", "+layout.server.js", "+layout.ts", "+layout.js")
$nadmin = 0
$firstok = ""
for ($i = 0; $i -lt $np; $i++) {
    if (-not (In-Set $i "S")) { continue }
    if (-not $adminPathRx.IsMatch($FilePaths[$i]) -and -not (File-Has $i $adminRoute $false)) { continue }
    $nadmin++
    $rn = File-Has $i $roleRe $false
    if ($rn) {
        $client = $false
        if (File-Has $i ('^\s*' + $Q + 'use client' + $Q) $false) { $client = $true }
        elseif ($FRAMEWORK -eq "next-pages" -and $FilePaths[$i] -cmatch '^(src/)?pages/' -and $FilePaths[$i] -cnotmatch '^(src/)?pages/api/' -and -not (File-Has $i 'getServerSideProps' $false)) { $client = $true }
        if ($client) { Add-Lead "BE5" "client-only-role-check" ($FilePaths[$i] + ":" + $rn) (Trim-Text $FileLines[$i][$rn - 1]) }
        elseif ($firstok -eq "") { $firstok = $FilePaths[$i] + ":" + $rn }
        continue
    }
    if ($mwcover -ne "") { if ($firstok -eq "") { $firstok = $mwcover }; continue }
    $covered = ""
    $d = Dir-Of $FilePaths[$i]
    while ($d -cmatch '(^|/)[^/]*admin') {
        foreach ($ln in $layoutNames) {
            $cand = "$d/$ln"
            if ($d -eq ".") { $cand = $ln }
            if ($PathIndex.ContainsKey($cand) -and $FileTags[$PathIndex[$cand]] -ne "" -and (File-Has $PathIndex[$cand] $roleRe $false)) { $covered = $cand; break }
        }
        if ($covered -ne "" -or $d -eq ".") { break }
        $d = Dir-Of $d
    }
    if ($covered -ne "") { if ($firstok -eq "") { $firstok = $covered } }
    else { Add-Lead "BE5" "admin-without-role-check" $FilePaths[$i] "no server side role check in this file, its layout or middleware" }
}
if ($nadmin -eq 0) { Add-Item "BE5" "n/a" "admin-routes" "no admin routes found" }
elseif ((Cnt "BE5") -eq 0) { Add-Item "BE5" "pass" "admin-routes" "server side role check on all admin routes ($nadmin), for example $firstok" }
else { Add-Item "BE5" "warn" "admin-routes" ("$(Cnt 'BE5') of $nadmin admin routes show no server side role check, first at " + $LF["BE5"]) }

Add-Item "BE6" "manual" "user-isolation" "active test, sign in as two users and confirm neither can see or change the other's data, run /security"

$rl = First-Hit "T" 'express-rate-limit|rate-limiter-flexible|@upstash/ratelimit|@nestjs/throttler|@fastify/rate-limit|hono-rate-limiter|express-slow-down|slowapi|django-ratelimit|flask-limiter|rack-attack|ratelimit|rate_limit|rate-limit|throttle' $true
if (-not $SERVER) {
    if ($DB) { Add-Item "BE7" "manual" "rate-limit" "no own API, Supabase and Firebase limit their auth endpoints, check those limits and add App Check or edge limits" }
    else { Add-Item "BE7" "n/a" "rate-limit" "no server code found" }
} elseif ($rl -ne "") { Add-Item "BE7" "pass" "rate-limit" "rate limiting at $rl" }
else { Add-Item "BE7" "fail" "rate-limit" "no rate limiting found for $napi route files" }

foreach ($b in $Buckets) {
    $tab = $b.IndexOf("`t")
    Add-Lead "BE8" "public-bucket" $b.Substring(0, $tab) $b.Substring($tab + 1)
}
[void](Add-Hits "S" ('(createBucket|updateBucket)\([^)]*public' + $Q + '?\s*:\s*true|[Aa][Cc][Ll]' + $Q + '?\s*[:=]\s*' + $Q + 'public-read|BlockPublicAcls' + $Q + '?\s*[:=]\s*false|allUsers') $false "BE8" "public-bucket" "" $false)
$nstr = 0
for ($i = 0; $i -lt $np; $i++) {
    if ((In-Set $i "T") -and $FilePaths[$i] -cmatch '(^|/)storage\.rules$') { $inlist[$i] = 1; $nstr++ }
}
[void](Add-Hits "LIST" $openRule $false "BE8" "open-rules" "" $false)
$inlist.Clear()
[void](Add-Hits "S" 'getPublicUrl\(' $false "BE8" "public-url" "" $false)
$store = First-Hit "T" 'supabase\.storage|\.storage\.from\(|firebase/storage|getStorage\(|@aws-sdk/client-s3|aws-sdk|S3Client|@google-cloud/storage|cloudinary|uploadthing|@vercel/blob|minio|boto3' $false
$signed = First-Hit "S" 'createSignedUrl|getSignedUrl|generate_presigned_url|presign|signedUrl|SignedUrl' $false
$nopen = (Cntc "BE8" "public-bucket") + (Cntc "BE8" "open-rules")
if ($store -eq "" -and $script:nbuckets -eq 0 -and $nstr -eq 0) { Add-Item "BE8" "n/a" "storage-buckets" "no file storage found" }
elseif ($nopen -gt 0) { Add-Item "BE8" "fail" "storage-buckets" ((Lead-Counts "BE8") + ", first at " + $LF["BE8"]) }
elseif ((Cntc "BE8" "public-url") -gt 0) { Add-Item "BE8" "warn" "storage-buckets" ("files go out through getPublicUrl at " + $LFC["BE8|public-url"] + ", use signed URLs for private files") }
elseif ($signed -ne "") { Add-Item "BE8" "pass" "storage-buckets" "signed URLs at $signed, no public bucket or open storage rule" }
else {
    $where = $store
    if ($where -eq "") { $where = "the SQL migrations" }
    Add-Item "BE8" "warn" "storage-buckets" "storage at $where with no signed URLs, check that buckets are private"
}

$inputRe = 'req\.body|req\.query|req\.params|request\.json\(|request\.formData\(|req\.json\(|request\.(json|form|args|get_json|data|POST|GET)|searchParams\.get|formData\.get|readBody\(|getQuery\('
$parseRe = '\.parse\(|\.safeParse\(|\.parseAsync\(|validate|celebrate\(|BaseModel|Serializer\(|is_valid\(|[Ss]chema|(^|[^A-Za-z0-9_])z\.(object|string|number|instanceof|array|enum|union|coerce)'
$nin = 0
$nval = 0
$firstval = ""
for ($i = 0; $i -lt $np; $i++) {
    if (-not $isapi.ContainsKey($i)) { continue }
    $hn = File-Has $i $inputRe $false
    if (-not $hn) { continue }
    $nin++
    if (File-Has $i $parseRe $false) {
        $nval++
        if ($firstval -eq "") { $firstval = $FilePaths[$i] }
    } else { Add-Lead "BE9" "unvalidated-input" ($FilePaths[$i] + ":" + $hn) (Trim-Text $FileLines[$i][$hn - 1]) }
}
if ($nin -eq 0) {
    if ($SERVER) { Add-Item "BE9" "n/a" "input-validation" "no route reads request input" }
    elseif ($DB) { Add-Item "BE9" "manual" "input-validation" "the client writes straight to the database, check constraints and rules (BE2)" }
    else { Add-Item "BE9" "n/a" "input-validation" "no server routes found" }
} elseif ($nval -eq $nin) { Add-Item "BE9" "pass" "input-validation" "all $nin route files that read input validate it, for example $firstval" }
elseif ($nval -gt 0) { Add-Item "BE9" "warn" "input-validation" ("$nval of $nin route files that read input validate it, first without at " + $LF["BE9"]) }
else { Add-Item "BE9" "fail" "input-validation" ("none of $nin route files that read input validate it, first at " + $LF["BE9"]) }

$authRe = 'getServerSession|(^|[^.A-Za-z_])auth\(\)|getUser\(|currentUser|requireAuth|requireUser|requireAdmin|requireSession|isAuthenticated|req\.user|request\.user|getToken\(|verifyToken|jwt\.verify|Depends\(get_current|login_required|@UseGuards|withAuth|clerkMiddleware|authMiddleware|getAuth\(|locals\.user|getSession\(|auth\.uid'
$glob = ""
for ($i = 0; $i -lt $np; $i++) {
    if ($FileTags[$i] -eq "" -or -not $mwRx.IsMatch($FilePaths[$i])) { continue }
    if (File-Has $i $authRe $false) { $glob = $FilePaths[$i]; break }
}
if ($glob -eq "") { $glob = First-Hit "S" 'app\.use\([^)]*(auth|requireAuth|passport\.authenticate|jwt|session)|DEFAULT_PERMISSION_CLASSES|LoginRequiredMiddleware|APP_GUARD' $false }
$npriv = 0
$nauth = 0
$pubApiRx = Get-Rx '(login|signin|sign-in|signup|sign-up|register|auth|webhooks?|health|healthz|status|public|contact|newsletter|subscribe|og|sitemap|robots|callback)' $true
for ($i = 0; $i -lt $np; $i++) {
    if (-not $isapi.ContainsKey($i)) { continue }
    if ($pubApiRx.IsMatch($FilePaths[$i])) { continue }
    $npriv++
    if (File-Has $i $authRe $false) { $nauth++ }
    elseif ($glob -eq "") { Add-Lead "BE10" "route-without-auth" $FilePaths[$i] "no session or token check" }
}
if ($napi -eq 0) {
    if ($DB) { Add-Item "BE10" "n/a" "auth-by-default" "no own API routes, data access rules are under BE2" }
    else { Add-Item "BE10" "n/a" "auth-by-default" "no server routes found" }
} elseif ($glob -ne "") { Add-Item "BE10" "pass" "auth-by-default" "auth middleware at $glob runs before routes, confirm its matcher covers every private route" }
elseif ($npriv -eq 0) { Add-Item "BE10" "manual" "auth-by-default" "all $napi route files look public by name (login, webhook, contact), confirm none returns private data" }
elseif ($nauth -eq $npriv) { Add-Item "BE10" "pass" "auth-by-default" "session check in all $npriv private route files" }
elseif ($nauth -gt 0) { Add-Item "BE10" "warn" "auth-by-default" ("session check in $nauth of $npriv private route files, first without at " + $LF["BE10"]) }
else { Add-Item "BE10" "fail" "auth-by-default" ("no session check in any of $npriv private route files, first at " + $LF["BE10"]) }

$sqliRe = '(SELECT|select) [^`]*(FROM|from) [^`]*\$\{|(INSERT INTO|insert into|DELETE FROM|delete from) [^`]*\$\{|(UPDATE|update) [A-Za-z_."]+ (SET|set) [^`]*\$\{|\$(query|execute)RawUnsafe|execute\([^)]*\.format\(|"(SELECT|INSERT|UPDATE|DELETE) [^"]*"\s*\+|''(SELECT|INSERT|UPDATE|DELETE) [^'']*''\s*\+|f' + $Q + '(SELECT|INSERT|UPDATE|DELETE|select|insert|update|delete) |' + $Q + '(SELECT|INSERT|UPDATE|DELETE) [^"'']*%s[^"'']*' + $Q + '\s*%'
[void](Add-Hits "S" $sqliRe $false "BE11" "sql-string-building" "" $false)
if ((Cnt "BE11") -gt 0) { Add-Item "BE11" "warn" "sql-injection" ("queries built from strings: " + (Cnt "BE11") + ", first at " + $LF["BE11"] + ", parameterize them and confirm with /security") }
else { Add-Item "BE11" "manual" "sql-injection" "no string built SQL found, confirm with an injection test from /security" }

[void](Add-Hits "S" '(console\.(log|info|debug|warn|error)|logger\.[a-z]+|logging\.[a-z]+|log\.[a-z]+|print)\(.*([,(+{]\s*[a-z_.]*(password|passwd|secret|token|authorization|api_?key|apikey|card_?number|cvv|ssn)|(req|request)\.(body|headers)\))' $true "BE12" "sensitive-log" 'redact|mask' $true)
$nsrc = 0
for ($i = 0; $i -lt $np; $i++) { if (In-Set $i "S") { $nsrc++ } }
if ((Cnt "BE12") -gt 0) { Add-Item "BE12" "fail" "sensitive-logs" ("log lines that print secrets or whole requests: " + (Cnt "BE12") + ", first at " + $LF["BE12"]) }
elseif ($nsrc -eq 0) { Add-Item "BE12" "n/a" "sensitive-logs" "no code found" }
else { Add-Item "BE12" "pass" "sensitive-logs" "no log line prints a password, token, key or whole request" }

$tamperRe = '(req\.body|request\.(json|data|form|POST)|body|data|input|args|payload)(\.|\[' + $Q + '?)(role|isAdmin|is_admin|price|unitPrice|unit_price|amount|total|subtotal|discount|ownerId|owner_id|userId|user_id|status|plan|tier|credits|balance|isPaid|is_paid|paid|verified|isVerified|approved)([^A-Za-z0-9_]|$)|\{[^}]*(role|price|amount|total|ownerId|owner_id|userId|user_id|status|isAdmin|plan|credits)[^}]*\}\s*=\s*(await\s+)?(req\.body|req\.json\(\)|request\.json\(\)|body)'
[void](Add-Hits "API" $tamperRe $false "BE13" "client-value" "" $false)
[void](Add-Hits "API" '(create|update|insert|upsert|updateOne|insertOne)\([^)]*(\.\.\.(req\.)?body|req\.body\s*[),}])|data\s*:\s*req\.body|\*\*request\.(data|json)' $false "BE13" "mass-assignment" "" $false)
[void](Add-Hits "NONAPI" ('\.from\(' + $Q + '[a-z_]+' + $Q + '\)\.(insert|update|upsert)\(.*(role|price|status|owner|user_id|is_admin|plan|credits|amount|total)') $false "BE13" "client-write" "" $false)
if ((Cnt "BE13") -gt 0) { Add-Item "BE13" "fail" "field-tampering" ((Lead-Counts "BE13") + ", first at " + $LF["BE13"]) }
elseif ($napi -gt 0) { Add-Item "BE13" "pass" "field-tampering" "no route reads role, price, owner or status from the request" }
elseif ($DB) { Add-Item "BE13" "manual" "field-tampering" "the client writes straight to the database, protect role, price and status columns with policies or column privileges (BE2)" }
else { Add-Item "BE13" "n/a" "field-tampering" "no server routes found" }

$upRe = 'multer|formidable|busboy|multipart|UploadFile|FileField|ImageField|request\.files|req\.files?([^A-Za-z]|$)|\.upload\(|createPresignedPost|uploadthing|@vercel/blob|uploadBytes|formData\.get\(' + $Q + '(file|avatar|image|upload|photo|document)'
$limitRe = 'limits\s*:|fileSize|maxFileSize|max_size|MAX_FILE_SIZE|maxSize|MAX_UPLOAD|content-length-range|\.size\s*>|max_content_length|MAX_CONTENT_LENGTH|FILE_UPLOAD_MAX|DATA_UPLOAD_MAX|sizeLimit|bodySizeLimit|maxBodyLength'
$upf = @{}
$nup = 0
for ($i = 0; $i -lt $np; $i++) {
    if (-not (In-Set $i "S")) { continue }
    $un = File-Has $i $upRe $false
    if (-not $un) { continue }
    $upf[$i] = 1
    $nup++
    if (-not (File-Has $i $limitRe $false)) { Add-Lead "BE14" "upload-without-limit" ($FilePaths[$i] + ":" + $un) (Trim-Text $FileLines[$i][$un - 1]) }
}
for ($i = 0; $i -lt $np; $i++) {
    if (-not $upf.ContainsKey($i)) { continue }
    $lines = $FileLines[$i]
    for ($n = 0; $n -lt $lines.Length; $n++) {
        if ($lines[$n] -cmatch 'originalname|originalFilename|file\.name|\.filename' -and $lines[$n] -cmatch 'path|join|upload|writeFile|rename|\.from\(') { Add-Lead "BE14" "original-filename" ($FilePaths[$i] + ":" + ($n + 1)) (Trim-Text $lines[$n]) }
    }
}
$ctype = ""
for ($i = 0; $i -lt $np -and $ctype -eq ""; $i++) {
    if (-not $upf.ContainsKey($i)) { continue }
    $cn = File-Has $i 'file-type|fileTypeFromBuffer|fileTypeFromFile|python-magic|magic\.from|filetype\.guess|imghdr|sharp\(|magic-bytes|mmmagic' $false
    if ($cn) { $ctype = $FilePaths[$i] + ":" + $cn }
}
if ($nup -eq 0) { Add-Item "BE14" "n/a" "file-uploads" "no file upload handling found" }
elseif ((Cntc "BE14" "upload-without-limit") -gt 0) { Add-Item "BE14" "fail" "file-uploads" ((Lead-Counts "BE14") + ", first at " + $LF["BE14"]) }
elseif ($ctype -eq "") { Add-Item "BE14" "warn" "file-uploads" "uploads limit size but do not check the type from the file bytes" }
elseif ((Cntc "BE14" "original-filename") -gt 0) { Add-Item "BE14" "warn" "file-uploads" ("uploads keep the user's file name at " + $LF["BE14"] + ", store them under a generated name") }
else { Add-Item "BE14" "pass" "file-uploads" "uploads limit size and check the type by content at $ctype" }

[void](Add-Hits "NONAPI" 'JSON\.stringify\(\{[^}]*(total|price|amount|role|status|discount|isAdmin)' $false "BE15" "client-sends-value" "" $false)
if ((Cnt "BE15") -gt 0) { Add-Item "BE15" "warn" "server-logic" ("the client sends price, total, role or status at " + $LF["BE15"] + ", confirm the server ignores it and recomputes") }
else { Add-Item "BE15" "manual" "server-logic" "read the flows that move money or change roles and confirm the server computes them" }

[void](Add-Hits "S" '(res\.(json|send)|json\(|jsonify|Response|return|reply\.send)[^;]*(password_?hash|hashed_?password|password_?digest|api_?secret|client_?secret|private_?key)' $true "BE16" "secret-in-response" 'omit|delete |exclude|without|except|redact|pick\(|drop|strip|select' $true)
[void](Add-Hits "S" ('\.from\(' + $Q + '(users|profiles|accounts|customers)' + $Q + '\)\.select\((' + $Q + '\*' + $Q + ')?\)') $false "BE16" "select-all-users" "" $false)
$wholeRx = Get-Rx 'json\((user|users|row|rows|record|account|profile|customer)\)' $false
for ($i = 0; $i -lt $np; $i++) {
    if (-not $isapi.ContainsKey($i)) { continue }
    if (-not (File-Has $i '(findUnique|findFirst|findMany|findOne|findById|findByPk)\(' $false) -or (File-Has $i 'select\s*:' $false)) { continue }
    $lines = $FileLines[$i]
    for ($n = 0; $n -lt $lines.Length; $n++) { if ($wholeRx.IsMatch($lines[$n])) { Add-Lead "BE16" "whole-row" ($FilePaths[$i] + ":" + ($n + 1)) (Trim-Text $lines[$n]) } }
}
$dto = First-Hit "API" ('select\s*:\s*\{|\.select\(' + $Q + '[A-Za-z_, ]+' + $Q + '\)|omit\(|pick\(|toDTO|toDto|toJSON|serialize|Serializer|response_model|exclude\s*[:=]|fields\s*=') $false
if ((Cntc "BE16" "secret-in-response") -gt 0) { Add-Item "BE16" "fail" "trim-responses" ((Lead-Counts "BE16") + ", first at " + $LF["BE16"]) }
elseif ((Cnt "BE16") -gt 0) { Add-Item "BE16" "warn" "trim-responses" ((Lead-Counts "BE16") + ", first at " + $LF["BE16"] + ", return only the fields the client needs") }
elseif ($napi -gt 0 -and $dto -ne "") { Add-Item "BE16" "pass" "trim-responses" "responses pick their fields, for example $dto" }
elseif ($napi -gt 0) { Add-Item "BE16" "manual" "trim-responses" "read each route's response and confirm it returns only the fields the client needs" }
else { Add-Item "BE16" "n/a" "trim-responses" "no own API responses found" }

$cookieRe = 'res\.cookie\(|cookies\(\)\.set\(|cookies\.set\(|setCookie\(|set_cookie\(|Set-Cookie|serialize\('
$cookieRx = Get-Rx $cookieRe $false
for ($i = 0; $i -lt $np; $i++) {
    if (-not (In-Set $i "S")) { continue }
    $lines = $FileLines[$i]
    for ($n = 0; $n -lt $lines.Length; $n++) {
        if ($lines[$n] -cmatch 'jwt\.sign\(') {
            $w = ""
            for ($j = $n; $j -lt $lines.Length -and $j -le $n + 3; $j++) { $w = $w + " " + $lines[$j] }
            if ($w -cnotmatch 'expiresIn|exp[ \t]*:|expires') { Add-Lead "BE17" "jwt-no-expiry" ($FilePaths[$i] + ":" + ($n + 1)) (Trim-Text $lines[$n]) }
        }
        if ($cookieRx.IsMatch($lines[$n])) {
            $w = ""
            for ($j = $n; $j -lt $lines.Length -and $j -le $n + 5; $j++) { $w = $w + " " + $lines[$j].ToLowerInvariant() }
            if (-not $w.Contains("httponly") -or -not $w.Contains("secure") -or -not $w.Contains("samesite")) { Add-Lead "BE17" "cookie-flags" ($FilePaths[$i] + ":" + ($n + 1)) (Trim-Text $lines[$n]) }
        }
    }
}
[void](Add-Hits "S" ('(localStorage|sessionStorage)\.setItem\(\s*' + $Q + '[^"''`]*(token|jwt|session|auth|access|refresh|bearer)') $true "BE17" "token-in-web-storage" "" $false)
[void](Add-Hits "S" 'document\.cookie\s*=[^=].*(token|jwt|session|auth)' $true "BE17" "token-in-script-cookie" "" $false)
$sesslib = Dep-Name 'next-auth|@auth/[a-z-]+|@clerk/[a-z-]+|@supabase/ssr|@supabase/auth-helpers-[a-z]+|lucia|better-auth|iron-session|@kinde-oss/[a-z-]+|express-session|cookie-session|firebase'
if ($sesslib -eq "" -and (Py-Dep 'django|flask-login')) { $sesslib = "the Python framework" }
$authany = $sesslib
if ($authany -eq "") { $authany = First-Hit "S" ($cookieRe + '|jwt\.sign|signIn|login') $true }
$logout = First-Hit "S" 'logout|log_out|signOut|sign_out|clearCookie|destroySession|session\.destroy' $true
if ((Cnt "BE17") -gt 0) { Add-Item "BE17" "fail" "auth-sessions" ((Lead-Counts "BE17") + ", first at " + $LF["BE17"]) }
elseif ($authany -eq "") { Add-Item "BE17" "n/a" "auth-sessions" "no login or session handling found" }
elseif ($logout -eq "") { Add-Item "BE17" "warn" "auth-sessions" "sessions found but no logout or sign out" }
elseif ($sesslib -ne "") { Add-Item "BE17" "pass" "auth-sessions" "sessions handled by $sesslib, logout at $logout" }
else { Add-Item "BE17" "manual" "auth-sessions" "custom sessions, check expiry and rotation on login, logout at $logout" }

$jsman = Path-First '(^|/)package\.json$'
$jslock = Path-First '(^|/)(package-lock\.json|npm-shrinkwrap\.json|pnpm-lock\.yaml|yarn\.lock|bun\.lockb?)$'
$pyman = Path-First '(^|/)(requirements[^/]*\.txt|pyproject\.toml|Pipfile)$'
$pylock = Path-First '(^|/)(poetry\.lock|Pipfile\.lock|uv\.lock|requirements[^/]*\.txt)$'
$bot = Path-First '(^|/)\.github/dependabot\.ya?ml$|(^|/)renovate\.json5?$|(^|/)\.renovaterc(\.json)?$|(^|/)\.github/renovate\.json5?$'
if ($bot -eq "" -and (First-Hit "P" '"renovate"\s*:' $false) -ne "") { $bot = "package.json renovate config" }
$cmds = @()
if ($jsman -ne "") {
    if ($jslock -cmatch 'pnpm-lock\.yaml$') { $cmds += "pnpm audit --prod" }
    elseif ($jslock -cmatch 'yarn\.lock$') {
        if ((Path-First '(^|/)\.yarnrc\.yml$') -ne "") { $cmds += "yarn npm audit --environment production" } else { $cmds += "yarn audit --groups dependencies" }
    }
    elseif ($jslock -cmatch 'bun\.lockb?$') { $cmds += "bun audit" }
    else { $cmds += "npm audit --omit=dev" }
}
if ($pyman -ne "") {
    if ($PathIndex.ContainsKey("requirements.txt")) { $cmds += "pip-audit -r requirements.txt" } else { $cmds += "pip-audit" }
}
if ((Path-First '(^|/)Gemfile$') -ne "") { $cmds += "bundle audit check --update" }
if ((Path-First '(^|/)go\.mod$') -ne "") { $cmds += "govulncheck ./..." }
if ((Path-First '(^|/)Cargo\.toml$') -ne "") { $cmds += "cargo audit" }
if ((Path-First '(^|/)composer\.json$') -ne "") { $cmds += "composer audit" }
$cmd = $cmds -join " and "
$lock = $jslock
if ($lock -eq "") { $lock = $pylock }
if ($lock -eq "") { $lock = "none" }
if ($cmd -eq "") { Add-Item "BE18" "n/a" "dependency-scan" "no dependency manifest found" }
elseif ($jsman -ne "" -and $jslock -eq "") { Add-Item "BE18" "fail" "dependency-scan" "$jsman has no lockfile, commit one, then run: $cmd" }
elseif ($bot -eq "") { Add-Item "BE18" "warn" "dependency-scan" "lockfile $lock, no Dependabot or Renovate config, run: $cmd" }
else { Add-Item "BE18" "manual" "dependency-scan" "lockfile $lock, updates by $bot, run: $cmd and grade on its output" }

[void](Add-Hits "S" '(findById|findByPk|findUnique|findOne|findFirst|get_object_or_404|objects\.get|\.find)\([^)]*(req\.(params|query|body)|request\.(args|params|GET|POST|query_params|path_params)|params\[|params\.)' $false "BE19" "unscoped-lookup" 'owner|tenant|user_?id|account_?id|org_?id|current_?user|req\.user|request\.user|session' $true)
if ((Cnt "BE19") -gt 0) { Add-Item "BE19" "warn" "record-access" ("lookups by a request id with no owner filter: " + (Cnt "BE19") + ", first at " + $LF["BE19"] + ", prove it with /security") }
else { Add-Item "BE19" "manual" "record-access" "active test, read, update and delete another user's record with /security" }

for ($i = 0; $i -lt $np; $i++) {
    if ((In-Set $i "T") -and $FilePaths[$i] -cnotmatch '\.env\.(development|dev|local|test|example|sample|template)' -and $FilePaths[$i] -cnotmatch '\.local$') { $inlist[$i] = 1 }
}
[void](Add-Hits "LIST" ('^\s*(export\s+)?(DEBUG|APP_DEBUG|FLASK_DEBUG|DJANGO_DEBUG)\s*=\s*' + $Q + '?(true|1|on|yes)|app\.run\([^)]*debug\s*=\s*True') $true "BE20" "debug-on" "" $false)
$inlist.Clear()
[void](Add-Hits "S" ('Access-Control-Allow-Origin' + $Q + '?\s*[:,]\s*' + $Q + '\*|origin\s*:\s*' + $Q + '\*' + $Q + '|origin\s*:\s*true|cors\(\)|CORS_ALLOW_ALL_ORIGINS\s*=\s*True|CORS_ORIGIN_ALLOW_ALL\s*=\s*True|allow_origins\s*=\s*\[' + $Q + '\*') $false "BE20" "cors-wildcard" "" $false)
[void](Add-Hits "S" '(res\.|return|Response|jsonify|json\().*((err|error|e|ex)\.stack|format_exc\()|res\.(status\([0-9]+\)\.)?(send|json)\((err|error|e)\)' $false "BE20" "stack-in-response" "" $false)
$hdr = First-Hit "T" 'helmet|Content-Security-Policy|Strict-Transport-Security|X-Frame-Options|X-Content-Type-Options|SECURE_HSTS_SECONDS|SECURE_SSL_REDIRECT|[Tt]alisman|securityHeaders|frame-ancestors|nuxt-security' $false
if ((Cnt "BE20") -gt 0) { Add-Item "BE20" "fail" "production-config" ((Lead-Counts "BE20") + ", first at " + $LF["BE20"]) }
elseif ($hdr -eq "") { Add-Item "BE20" "warn" "production-config" "no security headers configured (helmet, next.config headers, vercel.json, netlify.toml or _headers), confirm with prod-url" }
else { Add-Item "BE20" "pass" "production-config" "security headers at $hdr, no debug flag, no wildcard CORS, no stack traces in responses" }

Write-Output "PROD SCAN: $Path"
Write-Output "FRAMEWORK: $FRAMEWORK"
Write-Output "BACKEND: $BACKEND"
Write-Output "FILES_SCANNED: $ntext"
Write-Output ""
foreach ($it in $Items) { Write-Output (Redact $it) }
Write-Output ""
Write-Output "LEADS: $($Leads.Count)"
foreach ($ld in $Leads) {
    $s = Redact $ld
    $j = $s.IndexOf(": ")
    if ($j -ge 0) {
        $tail = $s.Substring($j + 2)
        if ($tail.Length -gt 120) { $tail = $tail.Substring(0, 120) }
        $s = $s.Substring(0, $j + 2) + $tail
    }
    Write-Output $s
}
Write-Output ""
Write-Output "PASS: $($StatusCount['pass'])"
Write-Output "FAIL: $($StatusCount['fail'])"
Write-Output "WARN: $($StatusCount['warn'])"
Write-Output "MANUAL: $($StatusCount['manual'])"
Write-Output "NA: $($StatusCount['n/a'])"
Write-Output ""
Write-Output "Statuses come from static evidence. Open the evidence behind each pass, check manual items in a browser or with prod-url, and hand active tests to /security."
