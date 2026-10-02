param(
    [Parameter(Mandatory=$true)][string]$Target,
    [string]$OutputDir = "."
)

if (-not (Test-Path -LiteralPath $OutputDir -PathType Container)) {
    [Console]::Error.WriteLine("ERROR: output directory $OutputDir does not exist.")
    exit 1
}
$OutputDir = (Resolve-Path -LiteralPath $OutputDir).Path

function Test-Local([string]$H) {
    if ($H -in @("localhost", "127.0.0.1", "::1")) { return $true }
    if ($H.EndsWith(".localhost") -or $H.EndsWith(".test")) { return $true }
    if ($H -match '^10\.' -or $H -match '^192\.168\.') { return $true }
    if ($H -match '^172\.(1[6-9]|2[0-9]|3[0-1])\.') { return $true }
    return $false
}

function Get-Slug([string]$Value) {
    return (($Value.ToLower() -replace '[^a-z0-9]+', '-') -replace '^-+', '') -replace '-+$', ''
}

$today = Get-Date

if (($Target -notmatch '://') -and (Test-Path -LiteralPath $Target -PathType Container)) {
    $kind = "source"
    $abs = (Resolve-Path -LiteralPath $Target).Path
    $slug = Get-Slug (Split-Path -Leaf $abs)
    $inScope = $abs
    $auth = "own source tree, static code review, nothing runs against a live target"
    $targetHost = "none"
} else {
    $kind = "host"
    $rest = $Target -replace '^[a-zA-Z][a-zA-Z0-9+.-]*://', ''
    $rest = ($rest -split '[/?#]')[0]
    $rest = ($rest -split '@')[-1]
    $parts = $rest -split ':', 2
    $targetHost = $parts[0].ToLower()
    $port = ""
    if ($parts.Count -gt 1) { $port = $parts[1] }
    if ([string]::IsNullOrWhiteSpace($targetHost)) {
        [Console]::Error.WriteLine("ERROR: could not parse a host or find a directory from '$Target'.")
        exit 1
    }
    if (-not (Test-Local $targetHost)) {
        [Console]::Error.WriteLine("ERROR: $targetHost is not a local or private-range host. scope-init only covers your own dev builds. For any other host, state your authorization in chat and write scope.md by hand.")
        exit 1
    }
    $slugSource = $targetHost
    if ($port) { $slugSource = "$targetHost-$port" }
    $slug = Get-Slug $slugSource
    $inScope = $targetHost
    $auth = "local dev build, owner request in chat on $($today.ToString('yyyy-MM-dd'))"
}

$engagement = Join-Path $OutputDir "security-$slug-$($today.ToString('yyyyMMdd'))"
$scopeFile = Join-Path $engagement "scope.md"
New-Item -ItemType Directory -Force -Path (Join-Path $engagement "evidence") | Out-Null

foreach ($f in @("recon.md", "findings.md", "notes.md")) {
    $p = Join-Path $engagement $f
    if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType File -Path $p | Out-Null }
}

if (Test-Path -LiteralPath $scopeFile) {
    $status = "existing"
} else {
    $status = "created"
    $content = @(
        "# Scope: $Target",
        "",
        "- Authorization: $auth",
        "- In scope: $inScope",
        "- Out of scope: none beyond the off-limits list below",
        "- Target: $Target",
        "- Test window: any",
        "- Test account: seeded test user or one the developer creates",
        "- Allowed actions: full non-destructive testing of the dev build, including proof payloads, auth and access control checks, and reading source and config",
        "- Off-limits: production, third-party and payment services, DoS and floods, destructive writes, real user data",
        "- Contact: the developer running this session"
    )
    [System.IO.File]::WriteAllLines($scopeFile, $content, (New-Object System.Text.UTF8Encoding($false)))
}

Write-Output "SCOPE_INIT: $Target"
Write-Output "KIND: $kind"
Write-Output "HOST: $targetHost"
Write-Output "ENGAGEMENT_DIR: $engagement"
Write-Output "SCOPE_FILE: $scopeFile"
Write-Output "SCOPE_STATUS: $status"
Write-Output "AUTHORIZATION: $auth"
