param(
    [Parameter(Mandatory=$true)][string]$Url,
    [string]$OutputDir = "."
)

$outputName = "axe-results.json"

foreach ($tool in @("npx", "node")) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        [Console]::Error.WriteLine("ERROR: $tool not found. Install Node.js first.")
        exit 1
    }
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$outputFile = Join-Path $OutputDir $outputName
Remove-Item -Force -ErrorAction SilentlyContinue $outputFile

npx --yes @axe-core/cli $Url --dir $OutputDir --save $outputName --no-reporter

if ($LASTEXITCODE -ne 0) {
    [Console]::Error.WriteLine("ERROR: axe scan failed. Check that Chrome is installed and that chromedriver matches its version.")
    exit 1
}

if (-not (Test-Path $outputFile)) {
    [Console]::Error.WriteLine("ERROR: axe scan finished but $outputFile was not written.")
    exit 1
}

Write-Output "AXE_RESULTS: $outputFile"

$results = @(Get-Content -Raw $outputFile | ConvertFrom-Json)
$violations = @($results | ForEach-Object { $_.violations } | Where-Object { $_ -ne $null })
$passes = @($results | ForEach-Object { $_.passes } | Where-Object { $_ -ne $null })
$affectedNodes = ($violations | ForEach-Object { @($_.nodes).Count } | Measure-Object -Sum).Sum
if (-not $affectedNodes) { $affectedNodes = 0 }

Write-Output "VIOLATIONS: $($violations.Count)"
Write-Output "VIOLATION_NODES: $affectedNodes"
Write-Output "PASSES: $($passes.Count)"

if ($violations.Count -gt 0) {
    Write-Output ""
    Write-Output "TOP VIOLATIONS:"
    $violations |
        Sort-Object { @($_.nodes).Count } -Descending |
        Select-Object -First 5 |
        ForEach-Object {
            Write-Output "  [$($_.impact)] $($_.id): $($_.help) ($(@($_.nodes).Count) instances)"
        }
}
