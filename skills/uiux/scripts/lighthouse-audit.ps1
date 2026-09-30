param(
    [Parameter(Mandatory=$true)][string]$Url,
    [string]$OutputDir = "."
)

foreach ($tool in @("npx", "node")) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        [Console]::Error.WriteLine("ERROR: $tool not found. Install Node.js first.")
        exit 1
    }
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$reportPath = Join-Path $OutputDir "lighthouse_$timestamp"
$jsonReport = "$reportPath.report.json"
$htmlReport = "$reportPath.report.html"

npx --yes lighthouse $Url `
    --output=json `
    --output=html `
    --output-path="$reportPath" `
    --chrome-flags="--headless=new --no-sandbox" `
    --only-categories=performance,accessibility,best-practices,seo `
    --quiet
$lighthouseStatus = $LASTEXITCODE

if (-not (Test-Path $jsonReport)) {
    [Console]::Error.WriteLine("ERROR: Lighthouse audit failed (exit $lighthouseStatus). Check that Chrome is installed.")
    exit 1
}

if ($lighthouseStatus -ne 0) {
    [Console]::Error.WriteLine("WARNING: Lighthouse exited with $lighthouseStatus after writing its report.")
}

Write-Output "LIGHTHOUSE_JSON: $jsonReport"
Write-Output "LIGHTHOUSE_HTML: $htmlReport"

$report = Get-Content -Raw $jsonReport | ConvertFrom-Json

Write-Output ""
Write-Output "SCORES:"
$report.categories.PSObject.Properties | ForEach-Object {
    $score = if ($null -ne $_.Value.score) { [math]::Round($_.Value.score * 100) } else { "n/a" }
    Write-Output "$($_.Name): $score"
}

Write-Output ""
Write-Output "METRICS:"
foreach ($id in @("first-contentful-paint", "largest-contentful-paint", "total-blocking-time", "cumulative-layout-shift", "speed-index")) {
    $audit = $report.audits.$id
    if ($audit) {
        $value = if ($audit.displayValue) { $audit.displayValue } else { "n/a" }
        Write-Output "${id}: $value"
    }
}
