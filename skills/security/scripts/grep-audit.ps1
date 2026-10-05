param(
    [Parameter(Mandatory=$true)][string]$Path
)

if (-not (Test-Path -LiteralPath $Path)) {
    [Console]::Error.WriteLine("ERROR: $Path does not exist.")
    exit 1
}

$target = (Resolve-Path -LiteralPath $Path).Path
$excludedDirs = @("node_modules", ".git", "dist", "build", ".next", "vendor", "coverage", ".venv", "venv")
$extensions = @(".js", ".ts", ".jsx", ".tsx", ".py", ".rb", ".php", ".go", ".java", ".cs", ".yml", ".yaml", ".json", ".sql")

$files = @(Get-ChildItem -LiteralPath $target -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object {
    $relative = if ($_.FullName.Length -gt $target.Length) { $_.FullName.Substring($target.Length) } else { $_.Name }
    $segments = $relative -split '[\\/]'
    ($extensions -contains $_.Extension.ToLower() -or $_.Name -like "*.env*") -and
    -not ($segments | Where-Object { $excludedDirs -contains $_ }) -and
    $_.Name -notlike "*.min.*" -and
    $_.Name -ne "package-lock.json"
})

if ($files.Count -eq 0) {
    Write-Output "No source files found under $Path."
    exit 0
}

$results = New-Object System.Collections.Generic.List[string]
$paths = @($files | ForEach-Object { $_.FullName })

function Flag([string]$Category, [string]$Pattern, [switch]$CaseSensitive) {
    $hits = Select-String -LiteralPath $paths -Pattern $Pattern -Encoding UTF8 -CaseSensitive:$CaseSensitive -ErrorAction SilentlyContinue
    foreach ($hit in @($hits)) {
        $rel = $hit.Path
        if ($rel.StartsWith($target)) { $rel = $rel.Substring($target.Length).TrimStart('\', '/') }
        $rel = $rel -replace '\\', '/'
        $results.Add("[$Category] ${rel}:$($hit.LineNumber):$($hit.Line.Trim())")
    }
}

function FlagWithout([string]$Category, [string]$Pattern, [string]$Exclude, [switch]$CaseSensitive) {
    $hits = Select-String -LiteralPath $paths -Pattern $Pattern -Encoding UTF8 -CaseSensitive:$CaseSensitive -ErrorAction SilentlyContinue
    foreach ($hit in @($hits)) {
        $excluded = if ($CaseSensitive) { $hit.Line -cmatch $Exclude } else { $hit.Line -match $Exclude }
        if ($excluded) { continue }
        $rel = $hit.Path
        if ($rel.StartsWith($target)) { $rel = $rel.Substring($target.Length).TrimStart('\', '/') }
        $rel = $rel -replace '\\', '/'
        $results.Add("[$Category] ${rel}:$($hit.LineNumber):$($hit.Line.Trim())")
    }
}

$authorityNames = 'role|is_?admin|tenant_?id|owner_?id|user_?id|account_?id|permissions'
$valueNames = 'price|unit_?price|amount|total|subtotal|discount|fee|cost|balance|credits?|points|status|paid|is_?paid|verified|is_?verified|approved|plan|tier|is_?premium|step'

function ClientInputPattern([string]$Names) {
    $requestChain = '(req|request|ctx)[\w.]*\.(body|json|form|data|POST|GET|query|params|args|values)(\.get)?(\.(' + $Names + ')\b|\s*[\[(]\s*["''](' + $Names + ')["''])'
    $localDotted = '(^|[^\w.])(body|payload)\.(' + $Names + ')\b'
    $localLookup = '(^|[^\w.])(body|payload|data|params|json|form|input)(\.get)?\s*[\[(]\s*["''](' + $Names + ')["'']'
    $destructured = '\{[^}]*\b(' + $Names + ')\b[^}]*\}\s*=\s*(await\s+)?(req|request)[\w.]*\.(body|json|form|data|query|params|args)'
    $php = '\$_(POST|REQUEST)\s*\[\s*["''](' + $Names + ')["'']|\$request->((input|get|post)\(["''])?(' + $Names + ')\b'
    $ruby = 'params(\[[^\]]*\])*\[:(' + $Names + ')\]|permit\([^)]*:(' + $Names + ')\b'
    $getter = '(getParameter|FormValue|PostForm|PostFormValue)\(["''](' + $Names + ')["'']'
    return "($requestChain)|($localDotted)|($localLookup)|($destructured)|($php)|($ruby)|($getter)"
}

$envWhole = 'process\.env(?![.?\w\[])|os\.environ(?![.\w\[])|os\.environ\.(copy|items)\(|ENV\.(to_h|to_hash)\b|getenv\(\)|\$_(ENV|SERVER)(?![\w\[])'

Flag "sql-concat"        "(SELECT|INSERT|UPDATE|DELETE|FROM|WHERE)[^;]*[""'][ \t]*\+|\+[ \t]*[""'][^""']*(SELECT|INSERT|UPDATE|DELETE|FROM|WHERE)"
Flag "sql-interp"        "(execute|query|exec|cursor|raw|prepare)[ \t]*\(.*(\$\{|%s|f[""']).*(SELECT|INSERT|UPDATE|DELETE|FROM|WHERE)"
Flag "command-exec"      "(os\.system|subprocess\.(call|run|Popen).*shell[ \t]*=[ \t]*True|child_process|exec\(|execSync|popen|Runtime\.getRuntime|ProcessBuilder|shell_exec|passthru)"
Flag "code-eval"         "(^|[^.\w])(eval|new[ \t]+Function|Function[ \t]*\(|setTimeout[ \t]*\([ \t]*[""'])|pickle\.loads|yaml\.load[ \t]*\(|Marshal\.load|ObjectInputStream" -CaseSensitive
Flag "dangerous-dom"     "(innerHTML|outerHTML|document\.write|insertAdjacentHTML|dangerouslySetInnerHTML|v-html)"
Flag "deserialize"       "(pickle\.loads|unserialize\(|Marshal\.load)"
Flag "weak-crypto"       "(\bMD5\b|\bSHA1\b|\bDES\b|\bRC4\b|Math\.random\(\).*(token|password|secret|key)|createCipher\()"
Flag "hardcoded-secret"  "(api[_-]?key|secret|passwd|password|token|private[_-]?key|access[_-]?key)[ \t]*[:=][ \t]*[""'][A-Za-z0-9_/+.=-]{12,}[""']"
Flag "aws-key"           "AKIA[0-9A-Z]{16}"
Flag "private-key-block" "BEGIN (RSA |EC |OPENSSH |DSA |PGP )?PRIVATE KEY"
Flag "disabled-tls"      "(verify[ \t]*=[ \t]*False|rejectUnauthorized[ \t]*:[ \t]*false|InsecureSkipVerify[ \t]*:[ \t]*true|CURLOPT_SSL_VERIFYPEER.*(0|false))"
Flag "permissive-cors"   "(Access-Control-Allow-Origin.*\*|cors\(\)|origin[ \t]*:[ \t]*[""']\*[""'])"
Flag "debug-on"          "(DEBUG[ \t]*=[ \t]*True|app\.debug[ \t]*=[ \t]*true)"
FlagWithout "client-env-secret" '(^|[^A-Za-z0-9_])(NEXT_PUBLIC|NUXT_PUBLIC|EXPO_PUBLIC|VITE|REACT_APP|VUE_APP|GATSBY|PUBLIC)_[A-Z0-9_]*(SECRET|PRIVATE|PASSWORD|PASSWD|TOKEN|SERVICE_?ROLE|CREDENTIAL|API_?KEY|DATABASE_?URL|DB_?URL)' 'PUBLISHABLE|ANON|SEARCH|MAPS|SITE_?KEY|PUBLIC_?KEY|CLIENT_?KEY' -CaseSensitive
Flag "client-token-storage" '((local|session)Storage\.(set|get)Item\s*\([^,)]*(token|jwt|session|secret|password|api_key|auth|bearer|credential)|document\.cookie\s*\+?=[^=].*(token|jwt|session|auth))'
Flag "sourcemap-public"  '(productionBrowserSourceMaps\s*:\s*true|devtool\s*:\s*["''](inline-)?source-map["'']|sourcemap\s*:\s*true|GENERATE_SOURCEMAP\s*[:=]\s*["'']?true)'
Flag "env-dump"          ('((send|json|jsonify|render|write|return|Response|reply|log|print|dump|echo)[^;]*(' + $envWhole + ')|phpinfo\s*\()')
FlagWithout "jwt-unverified" 'jwt\.decode\s*\(' 'algorithms|secret|key|public|verify_signature'
Flag "jwt-unverified"    '(verify_signature["'']?\s*[:=]\s*false|ignore_?expiration["'']?\s*[:=]\s*true|alg(orithms?)?["'']?\s*[:=]\s*(\[[^\]]*)?["'']none["''])'
FlagWithout "cookie-flags" '(res\.cookie|set_?cookie)\s*\(' 'http_?only'
Flag "client-authority"  (ClientInputPattern $authorityNames)
Flag "client-value"      (ClientInputPattern $valueNames)
Flag "client-header"     '(headers|header|META|getHeader|get_header)[^;]{0,12}x[-_](user|role|tenant|account|org|admin|uid)'

$seen = New-Object System.Collections.Generic.HashSet[string]
$unique = New-Object System.Collections.Generic.List[string]
foreach ($line in $results) {
    if ($seen.Add($line)) { $unique.Add($line) }
}
$results = $unique

Write-Output "GREP AUDIT: $Path"
Write-Output "FILES_SCANNED: $($files.Count)"
Write-Output ""
$results | Sort-Object { $_ } -Culture "en-US" | ForEach-Object { Write-Output $_ }
Write-Output ""
Write-Output "LEADS: $($results.Count)"
Write-Output ""
Write-Output "Each line is a lead, not a confirmed finding. Read it in context before reporting."
