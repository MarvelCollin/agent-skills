param(
    [Parameter(Mandatory=$true)][string]$Url,
    [string]$Output = "axe-results.json"
)

if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
    Write-Error "npx not found. Install Node.js first."
    exit 1
}

npx @axe-core/cli $Url --save $Output 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Output "AXE_RESULTS=$Output"

    if (Test-Path $Output) {
        $results = Get-Content $Output | ConvertFrom-Json
        $violations = @($results | ForEach-Object { $_.violations } | Where-Object { $_ -ne $null }).Count
        $passes = @($results | ForEach-Object { $_.passes } | Where-Object { $_ -ne $null }).Count
        Write-Output "VIOLATIONS: $violations"
        Write-Output "PASSES: $passes"

        if ($violations -gt 0) {
            Write-Output ""
            Write-Output "TOP VIOLATIONS:"
            $results | ForEach-Object { $_.violations } |
                Sort-Object { $_.nodes.Count } -Descending |
                Select-Object -First 5 |
                ForEach-Object {
                    Write-Output "  [$($_.impact)] $($_.id): $($_.help) ($($_.nodes.Count) instances)"
                }
        }
    }
} else {
    Write-Error "axe scan failed"
    exit 1
}
