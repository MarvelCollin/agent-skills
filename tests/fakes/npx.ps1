$fixtures = Join-Path $PSScriptRoot "..\fixtures"
$mode = if ($env:FAKE_NPX_MODE) { $env:FAKE_NPX_MODE } else { "ok" }
$dir = "."
$save = $null
$outputPath = $null

for ($i = 0; $i -lt $args.Count; $i++) {
    $arg = [string]$args[$i]
    if ($arg -eq "--dir") {
        $dir = $args[$i + 1]
        $i++
    } elseif ($arg -eq "--save") {
        $save = $args[$i + 1]
        $i++
    } elseif ($arg.StartsWith("--output-path=")) {
        $outputPath = $arg.Substring("--output-path=".Length)
    }
}

if ($mode -eq "fail") {
    [Console]::Error.WriteLine("fake npx failure")
    exit 1
}

if ($save) {
    Copy-Item (Join-Path $fixtures "axe-results.json") (Join-Path $dir $save)
}

if ($outputPath) {
    Copy-Item (Join-Path $fixtures "lighthouse.report.json") "$outputPath.report.json"
    Set-Content -Path "$outputPath.report.html" -Value "<html></html>"
}

if ($mode -eq "fail-after-write") {
    exit 1
}
exit 0
