param(
    [Parameter(Mandatory=$true, Position=0)][string]$Url,
    [switch]$Authorized
)

function Fail([string]$Message) {
    [Console]::Error.WriteLine("ERROR: $Message")
    exit 1
}

if ($Url -cnotmatch '^https?://') { Fail "url must start with http:// or https://." }

Add-Type -AssemblyName System.Net.Http
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$UA = "Mozilla/5.0 (compatible; checkprod/1.0)"
$handler = New-Object System.Net.Http.HttpClientHandler
$handler.AllowAutoRedirect = $false
$handler.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate
$client = New-Object System.Net.Http.HttpClient($handler)
$client.Timeout = [TimeSpan]::FromSeconds(15)
$script:reqs = 0

function Normalize-Url([string]$u) {
    $rest = $u.Substring($u.IndexOf("://") + 3)
    if ($rest.IndexOfAny([char[]]@('/', '?', '#')) -lt 0) { return $u + "/" }
    return $u
}

function Fetch([string]$u, [bool]$follow) {
    $script:reqs++
    $res = @{ Code = 0; Ttfb = 0; CType = ""; Redirect = ""; Final = $u; Body = ""; Headers = @{} }
    $current = $u
    $redirects = 0
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        while ($true) {
            $req = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Get, (New-Object Uri($current)))
            [void]$req.Headers.TryAddWithoutValidation("User-Agent", $UA)
            [void]$req.Headers.TryAddWithoutValidation("Accept-Encoding", "gzip, deflate")
            $resp = $client.SendAsync($req, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
            $code = [int]$resp.StatusCode
            $loc = $resp.Headers.Location
            if ($follow -and $code -ge 300 -and $code -lt 400 -and $loc -and $redirects -lt 5) {
                $current = (New-Object Uri((New-Object Uri($current)), $loc)).AbsoluteUri
                $redirects++
                $resp.Dispose()
                continue
            }
            break
        }
        $res.Ttfb = $sw.ElapsedMilliseconds
        $res.Code = $code
        if ($redirects -eq 0) { $res.Final = Normalize-Url $u } else { $res.Final = $current }
        if ($code -ge 300 -and $code -lt 400 -and $loc) { $res.Redirect = (New-Object Uri((New-Object Uri($current)), $loc)).AbsoluteUri }
        foreach ($h in $resp.Headers) { $res.Headers[$h.Key.ToLowerInvariant()] = ($h.Value -join ", ") }
        foreach ($h in $resp.Content.Headers) { $res.Headers[$h.Key.ToLowerInvariant()] = ($h.Value -join ", ") }
        if ($resp.Content.Headers.ContentType) { $res.CType = $resp.Content.Headers.ContentType.MediaType.ToLowerInvariant() }
        $bytes = $resp.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
        $res.Body = [System.Text.Encoding]::UTF8.GetString($bytes)
        $resp.Dispose()
    } catch {
        $res.Code = 0
    }
    return $res
}

function Body-Lines([string]$body) {
    $parts = $body.Split([char]10)
    $out = New-Object System.Collections.Generic.List[string]
    for ($k = 0; $k -lt $parts.Length; $k++) {
        if ($k -eq $parts.Length - 1 -and $parts[$k] -eq "") { break }
        $out.Add($parts[$k].TrimEnd([char]13))
    }
    return ,$out.ToArray()
}

function Is-Local([string]$name) {
    if ($name -in @("localhost", "::1", "0.0.0.0", "host.docker.internal")) { return $true }
    if ($name -like "*.localhost" -or $name -like "*.test" -or $name -like "*.local") { return $true }
    if ($name -match '^(127|10)\.' -or $name -match '^192\.168\.' -or $name -match '^::ffff:(127|10)\.' -or $name -match '^::ffff:192\.168\.') { return $true }
    if ($name -match '^172\.(1[6-9]|2[0-9]|3[0-1])\.') { return $true }
    return $false
}

$page = Fetch $Url $true
if ($page.Code -eq 0) { Fail "request to $Url failed." }
$final = $page.Final
$scheme = $final.Substring(0, $final.IndexOf("://"))
$rest = $final.Substring($final.IndexOf("://") + 3)
$hostport = ($rest -split '[/?#]')[0]
$origin = "${scheme}://$hostport"
$pathpart = ($rest -split '[?#]')[0]
if ($pathpart.Contains('/')) { $pathpart = $pathpart.Substring($pathpart.IndexOf('/')) } else { $pathpart = "/" }
$basedir = $origin + $pathpart.Substring(0, $pathpart.LastIndexOf('/')) + "/"
$hostName = ($hostport -split '@')[-1]
if ($hostName.StartsWith("[")) { $hostName = $hostName.Substring(1).Split(']')[0] } else { $hostName = $hostName.Split(':')[0] }
$hostName = $hostName.ToLowerInvariant()
if (Is-Local $hostName) { $scope = "local"; $probe = $true }
elseif ($Authorized) { $scope = "remote authorized"; $probe = $true }
else { $scope = "remote passive"; $probe = $false }

function Resolve-Href([string]$href) {
    if ($href -cmatch '^https?://') { return $href }
    if ($href.StartsWith("//")) { return "${scheme}:$href" }
    if ($href.StartsWith("/")) { return $origin + $href }
    return $basedir + $href
}

$NONE = [string][char]1
function Clean([string]$s) {
    $s = ($s -replace '[ \t\r\n]+', ' ')
    if ($s.StartsWith(" ")) { $s = $s.Substring(1) }
    if ($s.EndsWith(" ")) { $s = $s.Substring(0, $s.Length - 1) }
    if ($s.Length -gt 150) { $s = $s.Substring(0, 150) }
    return $s
}
function Attr([string]$tag, [string]$name) {
    $l = $tag.ToLowerInvariant()
    $m = [regex]::Match($l, '[ \t/]' + $name + '[ \t]*=[ \t]*')
    if (-not $m.Success) { return $NONE }
    $v = $tag.Substring($m.Index + $m.Length)
    if ($v.Length -gt 0 -and ($v[0] -eq '"' -or $v[0] -eq "'")) {
        $q = $v[0]
        $v = $v.Substring(1)
        $e = $v.IndexOf($q)
        if ($e -ge 0) { return $v.Substring(0, $e) }
        return $v
    }
    $m2 = [regex]::Match($v, '[ \t>]')
    if ($m2.Success) { return $v.Substring(0, $m2.Index) }
    return $v
}
function Val([string]$s) { if ($s -eq $NONE) { return "" } return (Clean $s) }

$html = ""
$sb = New-Object System.Text.StringBuilder
foreach ($line in (Body-Lines $page.Body)) { [void]$sb.Append(" ").Append($line) }
$html = $sb.ToString()
$low = $html.ToLowerInvariant()
$title = ""
$m = [regex]::Match($low, '<title[^>]*>')
if ($m.Success) {
    $s = $m.Index + $m.Length
    $e = $low.IndexOf("</title", $s)
    if ($e -ge 0) { $title = Clean $html.Substring($s, $e - $s) }
}
$pageLang = ""
$m = [regex]::Match($low, '<html[^>]*>')
if ($m.Success) { $pageLang = Val (Attr $html.Substring($m.Index, $m.Length) "lang") }
$meta = @{}
$canon = ""
$apple = ""
$icon = ""
$scriptSrc = ""
$images = 0
$noalt = 0
$tagRx = New-Object System.Text.RegularExpressions.Regex('<(meta|link|img|script)[ \t/>]')
$pos = 0
while ($true) {
    $m = $tagRx.Match($low, $pos)
    if (-not $m.Success) { break }
    $name = $m.Groups[1].Value
    $end = $low.IndexOf('>', $m.Index)
    if ($end -lt 0) { $end = $low.Length - 1 }
    $tag = $html.Substring($m.Index, $end - $m.Index + 1)
    if ($name -eq "meta") {
        $k = Attr $tag "name"
        if ($k -eq $NONE) { $k = Attr $tag "property" }
        $k = $k.ToLowerInvariant()
        if ($k -ne $NONE -and -not $meta.ContainsKey($k)) { $meta[$k] = Val (Attr $tag "content") }
    } elseif ($name -eq "link") {
        $rel = (Attr $tag "rel").ToLowerInvariant()
        $href = Val (Attr $tag "href")
        if ($rel -eq "canonical" -and $canon -eq "") { $canon = $href }
        elseif ($rel -match '(^| )apple-touch-icon') { if ($apple -eq "") { $apple = $href } }
        elseif ($rel -match '(^| )icon( |$)' -and $icon -eq "") { $icon = $href }
    } elseif ($name -eq "img") {
        $images++
        if ($tag.ToLowerInvariant() -cnotmatch '[ \t/]alt([ \t]*=|[ \t>/]|$)') { $noalt++ }
    } elseif ($name -eq "script" -and $scriptSrc -eq "") {
        $scriptSrc = Val (Attr $tag "src")
    }
    $pos = $end + 1
    if ($pos -ge $low.Length) { break }
}

function Header-Value([string]$name) {
    if ($page.Headers.ContainsKey($name)) { return (Clean $page.Headers[$name]) }
    return ""
}
$hsts = Header-Value "strict-transport-security"
$csp = Header-Value "content-security-policy"
$cspro = Header-Value "content-security-policy-report-only"
$xcto = Header-Value "x-content-type-options"
$xfo = Header-Value "x-frame-options"
$ref = Header-Value "referrer-policy"
function Meta-Value([string]$k) { if ($meta.ContainsKey($k)) { return $meta[$k] } return "" }
function Or-Missing([string]$s) { if ($s -ne "") { return $s } return "missing" }

if ($scheme -eq "https") {
    if ($Url -cmatch '^http://') { $https = "yes (http redirects to https)" }
    else {
        $hc = Fetch "http://$hostport/" $false
        if ($hc.Code -eq 0) { $https = "yes (http is not served)" }
        elseif ($hc.Code -ge 300 -and $hc.Code -lt 400 -and $hc.Redirect -cmatch '^https://') { $https = "yes (http redirects to https)" }
        else { $https = "partial (http://$hostport does not redirect to https)" }
    }
} else { $https = "no (final URL is http)" }

$frame = $xfo
if ($frame -eq "" -and $csp.Contains("frame-ancestors")) {
    $fa = "frame-ancestors" + $csp.Substring($csp.IndexOf("frame-ancestors") + 15)
    $semi = $fa.IndexOf(';')
    if ($semi -ge 0) { $fa = $fa.Substring(0, $semi) }
    $frame = "CSP $fa"
}
$cspOut = $csp
if ($cspOut -eq "" -and $cspro -ne "") { $cspOut = "report-only ($cspro)" }

function Asset([string]$href) {
    $r = Fetch (Resolve-Href $href) $true
    if ($r.Code -eq 0) { return "missing ($href is unreachable)" }
    if ($r.Code -ne 200) { return "missing ($href returns $($r.Code))" }
    if ($r.CType -eq "text/html") { return "missing ($href returns text/html)" }
    return "ok ($href, 200 $($r.CType))"
}
$iconHref = $icon
if ($iconHref -eq "") { $iconHref = "/favicon.ico" }
$favicon = Asset $iconHref
$appleHref = $apple
if ($appleHref -eq "") { $appleHref = "/apple-touch-icon.png" }
$appleOut = Asset $appleHref

$ogi = Meta-Value "og:image"
if ($ogi -ne "") {
    $r = Fetch (Resolve-Href $ogi) $true
    if ($r.Code -eq 0) { $ogImage = "$ogi (unreachable)" } else { $ogImage = "$ogi ($($r.Code) $($r.CType))" }
} else { $ogImage = "missing" }

$sitemapUrl = "$origin/sitemap.xml"
$r = Fetch "$origin/robots.txt" $true
$robotLines = Body-Lines $r.Body
$hasAgent = $false
foreach ($line in $robotLines) { if ($line -match '^\s*user-agent\s*:') { $hasAgent = $true; break } }
if ($r.Code -eq 200 -and $r.CType -ne "text/html" -and $hasAgent) {
    $sm = ""
    $star = $false
    $rules = $false
    $dis = $false
    foreach ($line in $robotLines) {
        if ($sm -eq "" -and $line.ToLowerInvariant() -cmatch '^[ \t]*sitemap[ \t]*:') {
            $sm = ($line -creplace '^[ \t]*[A-Za-z]+[ \t]*:[ \t]*', '') -creplace '[ \t]+$', ''
        }
        $l = $line.ToLowerInvariant()
        $hash = $l.IndexOf('#')
        if ($hash -ge 0) { $l = $l.Substring(0, $hash) }
        if ($l -cmatch '^[ \t]*user-agent[ \t]*:') {
            if ($rules) { $star = $false; $rules = $false }
            $v = ($l -creplace '^[ \t]*user-agent[ \t]*:[ \t]*', '') -creplace '[ \t]+$', ''
            if ($v -eq "*") { $star = $true }
            continue
        }
        if ($l -cmatch '^[ \t]*(dis)?allow[ \t]*:') { $rules = $true }
        if ($star -and $l -cmatch '^[ \t]*disallow[ \t]*:[ \t]*/[ \t]*$') { $dis = $true }
    }
    if ($dis) { $robots = "blocks all crawlers (Disallow: / for User-agent: *)" }
    elseif ($sm -ne "") { $robots = "ok (Sitemap: $sm)" }
    else { $robots = "ok (no Sitemap line)" }
    if ($sm -cmatch '^https?://') { $sitemapUrl = $sm }
} elseif ($r.Code -eq 200) { $robots = "missing (returns HTML, not a robots file)" }
elseif ($r.Code -eq 0) { $robots = "missing (unreachable)" }
else { $robots = "missing (HTTP $($r.Code))" }

$r = Fetch $sitemapUrl $true
if ($r.Code -eq 200) {
    $smok = $false
    $smcount = 0
    foreach ($line in (Body-Lines $r.Body)) {
        $l = $line.ToLowerInvariant()
        if ($l -cmatch '<urlset|<sitemapindex') { $smok = $true }
        $smcount += ([regex]::Matches($l, '<loc[ >]')).Count
    }
    if ($smok) { $sitemap = "ok ($smcount URLs)" }
    elseif ($r.CType -eq "text/html") { $sitemap = "missing (returns HTML, not XML)" }
    else { $sitemap = "invalid (no urlset or sitemapindex)" }
} elseif ($r.Code -eq 0) { $sitemap = "missing (unreachable)" }
else { $sitemap = "missing (HTTP $($r.Code))" }

$r = Fetch "$origin/checkprod-missing-page-7f3a9c" $true
if ($r.Code -eq 404 -or $r.Code -eq 410) {
    $nfStatus = "$($r.Code)"
    $nb = New-Object System.Text.StringBuilder
    foreach ($line in (Body-Lines $r.Body)) { [void]$nb.Append(" ").Append($line.ToLowerInvariant()) }
    $h = $nb.ToString()
    if ($h -cmatch 'this page could not be found') { $nfPage = "default (Next.js)" }
    elseif ($h -cmatch '<center>nginx') { $nfPage = "default (nginx)" }
    elseif ($h -cmatch 'was not found on this server') { $nfPage = "default (Apache)" }
    elseif ($h -cmatch 'cannot get /') { $nfPage = "default (Express)" }
    elseif ($h -cmatch 'error response' -and $h -cmatch 'error code: 404') { $nfPage = "default (Python http.server)" }
    elseif ($h -cmatch 'the page could not be found' -and $h -cmatch 'not_found') { $nfPage = "default (Vercel)" }
    elseif ($h -cmatch 'followed a broken link') { $nfPage = "default (Netlify)" }
    elseif ($h -cmatch 'github pages site here') { $nfPage = "default (GitHub Pages)" }
    elseif ($h -cmatch '<a[ \t][^>]*href') { $nfPage = "custom" }
    else { $nfPage = "default (no links back into the site)" }
} elseif ($r.Code -eq 200) {
    $nfStatus = "200 (soft 404)"
    $nfPage = "none (unknown paths return a normal page)"
} elseif ($r.Code -eq 0) {
    $nfStatus = "unreachable"
    $nfPage = "unknown (unreachable)"
} else {
    $nfStatus = "$($r.Code)"
    $nfPage = "unknown (HTTP $($r.Code))"
}

$notChecked = "not checked (remote host, pass --authorized after the user confirms they own it)"
if ($probe) {
    $r = Fetch "$origin/.env" $false
    $kv = $false
    foreach ($line in (Body-Lines $r.Body)) { if ($line -cmatch '^[A-Za-z_][A-Za-z0-9_]*=') { $kv = $true; break } }
    if ($r.Code -eq 200 -and $r.CType -ne "text/html" -and $kv) { $exposedEnv = "yes (/.env returns KEY=value lines, block it and rotate every value)" }
    elseif ($r.Code -eq 200) { $exposedEnv = "no (/.env returns a normal page)" }
    else { $exposedEnv = "no (HTTP $($r.Code.ToString('000')))" }
    $r = Fetch "$origin/.git/HEAD" $false
    $head = $false
    foreach ($line in (Body-Lines $r.Body)) { if ($line -cmatch '^(ref: |[0-9a-f]{40})') { $head = $true; break } }
    if ($r.Code -eq 200 -and $head) { $exposedGit = "yes (/.git/HEAD is readable, the source and history can be downloaded)" }
    elseif ($r.Code -eq 200) { $exposedGit = "no (/.git/HEAD returns a normal page)" }
    else { $exposedGit = "no (HTTP $($r.Code.ToString('000')))" }
    if ($scriptSrc -eq "") { $sourceMaps = "not checked (no script tag on the page)" }
    else {
        $src = Resolve-Href $scriptSrc
        if ($src.StartsWith("$origin/")) {
            $spath = $src.Substring($origin.Length).Split('?')[0]
            $r = Fetch "$origin$spath.map" $false
            if ($r.Code -eq 200 -and $r.Body.Contains('"mappings"')) { $sourceMaps = "yes ($spath.map is public)" }
            else { $sourceMaps = "no ($spath.map returns $($r.Code.ToString('000')))" }
        } else { $sourceMaps = "not checked (the first script is on another host)" }
    }
} else {
    $exposedEnv = $notChecked
    $exposedGit = $notChecked
    $sourceMaps = $notChecked
}

Write-Output "PROD URL CHECK: $Url"
Write-Output "SCOPE: $scope"
Write-Output "HTTP_STATUS: $($page.Code)"
Write-Output "FINAL_URL: $final"
Write-Output "TTFB_MS: $($page.Ttfb)"
Write-Output "HTTPS: $https"
Write-Output "HSTS: $(Or-Missing $hsts)"
Write-Output "CSP: $(Or-Missing $cspOut)"
Write-Output "X_CONTENT_TYPE_OPTIONS: $(Or-Missing $xcto)"
Write-Output "FRAME_PROTECTION: $(Or-Missing $frame)"
Write-Output "REFERRER_POLICY: $(Or-Missing $ref)"
Write-Output "TITLE: $(Or-Missing $title)"
Write-Output "META_DESCRIPTION: $(Or-Missing (Meta-Value 'description'))"
Write-Output "OG_TITLE: $(Or-Missing (Meta-Value 'og:title'))"
Write-Output "OG_DESCRIPTION: $(Or-Missing (Meta-Value 'og:description'))"
Write-Output "OG_IMAGE: $ogImage"
Write-Output "TWITTER_CARD: $(Or-Missing (Meta-Value 'twitter:card'))"
Write-Output "CANONICAL: $(Or-Missing $canon)"
Write-Output "VIEWPORT: $(Or-Missing (Meta-Value 'viewport'))"
Write-Output "LANG: $(Or-Missing $pageLang)"
Write-Output "FAVICON: $favicon"
Write-Output "APPLE_TOUCH_ICON: $appleOut"
Write-Output "ROBOTS_TXT: $robots"
Write-Output "SITEMAP_XML: $sitemap"
Write-Output "NOT_FOUND_STATUS: $nfStatus"
Write-Output "NOT_FOUND_PAGE: $nfPage"
Write-Output "IMAGES: $images"
Write-Output "IMAGES_WITHOUT_ALT: $noalt"
Write-Output "EXPOSED_ENV: $exposedEnv"
Write-Output "EXPOSED_GIT: $exposedGit"
Write-Output "SOURCE_MAPS: $sourceMaps"
Write-Output "REQUESTS: $($script:reqs)"
