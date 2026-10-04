param(
    [Parameter(Mandatory=$true)][string]$Url,
    [int]$Duration = 30,
    [int]$Connections = 10,
    [int]$Rate = 0,
    [string]$Method = "GET",
    [string[]]$Header = @(),
    [string]$Body = "",
    [string]$OutputDir = "load-results",
    [double]$P99 = 1000,
    [double]$MaxErrorPct = 1,
    [switch]$Authorized
)

function Fail([string]$Message, [int]$Code = 1) {
    [Console]::Error.WriteLine("ERROR: $Message")
    exit $Code
}

if ($Duration -lt 1 -or $Duration -gt 3600) { Fail "duration must be a whole number of seconds from 1 to 3600." }
if ($Connections -lt 1 -or $Connections -gt 1000) { Fail "connections must be a whole number from 1 to 1000." }
if ($Rate -lt 0) { Fail "rate must be a whole number of requests per second." }
if ($Url -notmatch '^https?://') { Fail "url must start with http:// or https://." }

$hostPart = $Url -replace '^[a-zA-Z]+://', ''
$hostPart = ($hostPart -split '[/?#]')[0]
$hostPart = ($hostPart -split '@')[-1]
if ($hostPart.StartsWith("[")) {
    $hostPart = $hostPart.Substring(1).Split(']')[0]
} else {
    $hostPart = $hostPart.Split(':')[0]
}
$hostPart = $hostPart.ToLower()

function Test-LocalHost([string]$Name) {
    if ($Name -in @("localhost", "::1", "0.0.0.0", "host.docker.internal")) { return $true }
    if ($Name -like "*.localhost" -or $Name -like "*.test" -or $Name -like "*.local") { return $true }
    if ($Name -match '^(127|10)\.' -or $Name -match '^192\.168\.') { return $true }
    if ($Name -match '^172\.(1[6-9]|2[0-9]|3[0-1])\.') { return $true }
    return $false
}

$scope = "local"
if (-not (Test-LocalHost $hostPart)) {
    if (-not $Authorized) {
        Fail "$hostPart is not a local or private host. Load testing it needs the owner's authorization. Confirm it with the user, record it, then pass -Authorized with a rate cap (-Rate)." 2
    }
    if ($Rate -le 0) { Fail "a remote target needs a rate cap. Pass -Rate <requests per second>." }
    $scope = "remote (authorized)"
}

foreach ($tool in @("npx", "node")) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { Fail "$tool not found. Install Node.js first." }
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$resultsJson = Join-Path $OutputDir "autocannon_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"

$npxArgs = @("--yes", "autocannon", "-j", "-c", "$Connections", "-d", "$Duration", "-m", $Method)
if ($Rate -gt 0) { $npxArgs += @("-R", "$Rate") }
foreach ($h in $Header) {
    $index = $h.IndexOf(":")
    if ($index -lt 1) { Fail "header '$h' must look like 'Name: value'." }
    $npxArgs += @("-H", "$($h.Substring(0, $index))=$($h.Substring($index + 1).TrimStart())")
}
if ($Body) { $npxArgs += @("-b", $Body) }
$npxArgs += $Url

$output = & npx @npxArgs
$status = $LASTEXITCODE
$text = (@($output) -join "`n")
[System.IO.File]::WriteAllText([System.IO.Path]::GetFullPath($resultsJson), $text)

if ($status -ne 0 -or -not $text.Trim()) {
    Fail "load test failed (exit $status). Check that the service is up and Node.js can run autocannon."
}

$jsonLine = @($text -split "`r?`n" | Where-Object { $_.Trim().StartsWith("{") })[-1]
if (-not $jsonLine) { Fail "no JSON result in $resultsJson" }
$r = $jsonLine | ConvertFrom-Json

$inv = [System.Globalization.CultureInfo]::InvariantCulture
function Get-Number($Value) { if ($null -eq $Value) { return [double]0 } return [double]$Value }
function Format-Ms($Value) { return [string][math]::Round((Get-Number $Value), [System.MidpointRounding]::AwayFromZero) }

$errors = Get-Number $r.errors
$timeouts = Get-Number $r.timeouts
$non2xx = Get-Number $r.non2xx
$total = Get-Number $r.requests.total
$attempted = [math]::Max([math]::Max((Get-Number $r.requests.sent), $total + $errors + $timeouts), 1)
$errorPct = (($errors + $timeouts + $non2xx) / $attempted) * 100
$p99Value = Get-Number $r.latency.p99
$pass = ($p99Value -le $P99) -and ($errorPct -le $MaxErrorPct)

Write-Output "LOAD_TEST: $Url"
Write-Output "SCOPE: $scope"
Write-Output "RESULTS_JSON: $resultsJson"
Write-Output "CONNECTIONS: $Connections"
Write-Output "DURATION_S: $Duration"
Write-Output "RATE_CAP: $(if ($Rate -gt 0) { $Rate } else { 'none' })"
Write-Output "REQUESTS: $([string]$total)"
Write-Output "RPS_AVG: $((Get-Number $r.requests.average).ToString('0.0', $inv))"
Write-Output "LATENCY_P50_MS: $(Format-Ms $r.latency.p50)"
Write-Output "LATENCY_P90_MS: $(Format-Ms $r.latency.p90)"
Write-Output "LATENCY_P99_MS: $(Format-Ms $r.latency.p99)"
Write-Output "LATENCY_MAX_MS: $(Format-Ms $r.latency.max)"
Write-Output "ERRORS: $([string]$errors)"
Write-Output "TIMEOUTS: $([string]$timeouts)"
Write-Output "NON_2XX: $([string]$non2xx)"
Write-Output "ERROR_RATE_PCT: $($errorPct.ToString('0.00', $inv))"
Write-Output "THRESHOLD_P99_MS: $($P99.ToString($inv))"
Write-Output "THRESHOLD_ERROR_PCT: $($MaxErrorPct.ToString($inv))"
Write-Output "RESULT: $(if ($pass) { 'pass' } else { 'fail' })"
