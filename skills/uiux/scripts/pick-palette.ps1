$list = Join-Path (Split-Path -Parent $PSScriptRoot) "references/palettes.txt"

if (-not (Test-Path -LiteralPath $list)) {
    [Console]::Error.WriteLine("ERROR: $list does not exist.")
    exit 1
}

$palettes = @(Get-Content -LiteralPath $list -Encoding UTF8 | Where-Object { $_ -match '^#[0-9a-f]{6} ' })
if ($palettes.Count -eq 0) {
    [Console]::Error.WriteLine("ERROR: $list has no palettes.")
    exit 1
}

$line = $palettes | Get-Random
$parts = $line -split '\|'
$hex = $parts[0].Trim()
$code = ($hex -replace '[# ]', '')

Write-Output "Palette: https://colorhunt.co/palette/$code"
Write-Output "Colors: $hex"
Write-Output "OKLCH: $($parts[1].Trim())"
Write-Output "Likes: $($parts[2].Trim())"
