param(
    [Parameter(Mandatory=$true)][string]$ScopeFile,
    [Parameter(Mandatory=$true)][string]$Target
)

if (-not (Test-Path -LiteralPath $ScopeFile -PathType Leaf)) {
    [Console]::Error.WriteLine("ERROR: scope file $ScopeFile not found. Run the scope phase first.")
    exit 3
}

$targetHost = $Target
$targetHost = $targetHost -replace '^[a-zA-Z][a-zA-Z0-9+.-]*://', ''
$targetHost = ($targetHost -split '[/?#]')[0]
$targetHost = ($targetHost -split '@')[-1]
$targetHost = ($targetHost -split ':')[0]
$targetHost = $targetHost.ToLower()

if ([string]::IsNullOrWhiteSpace($targetHost)) {
    [Console]::Error.WriteLine("ERROR: could not parse a host from '$Target'.")
    exit 3
}

$lines = Get-Content -LiteralPath $ScopeFile

function Get-List([string]$Label) {
    foreach ($line in $lines) {
        if ($line -imatch "^[-*\s]*$Label\s*:?\s*(.+)$") {
            return $Matches[1]
        }
    }
    return ""
}

function Test-List([string]$H, [string]$List) {
    foreach ($raw in ($List -split ',')) {
        $entry = $raw.Trim().ToLower()
        $entry = $entry -replace '^https?://', ''
        $entry = ($entry -split '[/:]')[0]
        if ([string]::IsNullOrWhiteSpace($entry)) { continue }
        $wildcard = $false
        $base = $entry
        if ($entry.StartsWith('*.')) { $wildcard = $true; $base = $entry.Substring(2) }
        elseif ($entry.StartsWith('.')) { $wildcard = $true; $base = $entry.Substring(1) }
        if ([string]::IsNullOrWhiteSpace($base)) { continue }
        if ($H -eq $base) { return $entry }
        if ($wildcard -and $H.EndsWith(".$base")) { return $entry }
    }
    return $null
}

function Test-Local([string]$H) {
    if ($H -in @("localhost", "127.0.0.1", "::1")) { return $true }
    if ($H.EndsWith(".localhost") -or $H.EndsWith(".test")) { return $true }
    if ($H -match '^10\.' -or $H -match '^192\.168\.') { return $true }
    if ($H -match '^172\.(1[6-9]|2[0-9]|3[0-1])\.') { return $true }
    return $false
}

$inList = Get-List 'in.?scope'
$outList = Get-List 'out.?of.?scope'

$outHit = Test-List $targetHost $outList
if ($outHit) {
    Write-Output "OUT_OF_SCOPE: $targetHost matches out-of-scope entry ($outHit). Do not test it."
    exit 2
}

$inHit = Test-List $targetHost $inList
if ($inHit) {
    Write-Output "IN_SCOPE: $targetHost matches in-scope entry ($inHit)."
    exit 0
}

if (Test-Local $targetHost) {
    Write-Output "IN_SCOPE: $targetHost is a local or private-range host (default authorized). Confirm it is your own build."
    exit 0
}

Write-Output "NOT_LISTED: $targetHost is not in the in-scope list and is not a local host. Add it to $ScopeFile with authorization before testing."
exit 1
