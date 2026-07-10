param(
    [Parameter(Mandatory=$true)][string]$Url,
    [string]$OutputDir = "."
)

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$reportPath = Join-Path $OutputDir "lighthouse_$timestamp"

if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
    Write-Error "npx not found. Install Node.js first."
    exit 1
}

npx lighthouse $Url `
    --output=json `
    --output=html `
    --output-path="$reportPath" `
    --chrome-flags="--headless --no-sandbox" `
    --only-categories=performance,accessibility,best-practices,seo `
    --quiet

if ($LASTEXITCODE -eq 0) {
    Write-Output "LIGHTHOUSE_JSON=$reportPath.report.json"
    Write-Output "LIGHTHOUSE_HTML=$reportPath.report.html"

    if (Test-Path "$reportPath.report.json") {
        $report = Get-Content "$reportPath.report.json" | ConvertFrom-Json
        Write-Output ""
        Write-Output "SCORES:"
        $report.categories.PSObject.Properties | ForEach-Object {
            Write-Output "$($_.Name): $([math]::Round($_.Value.score * 100))"
        }
    }
} else {
    Write-Error "Lighthouse audit failed"
    exit 1
}
