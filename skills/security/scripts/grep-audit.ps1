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

Write-Output "GREP AUDIT: $Path"
Write-Output "FILES_SCANNED: $($files.Count)"
Write-Output ""
$results | Sort-Object { $_ } -Culture "en-US" | ForEach-Object { Write-Output $_ }
Write-Output ""
Write-Output "LEADS: $($results.Count)"
Write-Output ""
Write-Output "Each line is a lead, not a confirmed finding. Read it in context before reporting."
