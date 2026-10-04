param(
    [Parameter(Mandatory=$true)][string]$Path
)

if (-not (Test-Path -LiteralPath $Path)) {
    [Console]::Error.WriteLine("ERROR: $Path does not exist.")
    exit 1
}

$full = (Resolve-Path -LiteralPath $Path).Path
$root = if (Test-Path -LiteralPath $full -PathType Container) { $full.TrimEnd('\', '/') } else { Split-Path -Parent $full }
$pruned = @("node_modules", ".git", "dist", "build", ".next", ".nuxt", "out", "coverage", "vendor", ".venv", "venv", "__pycache__", "target", "bin", "obj", ".turbo", ".cache", ".svelte-kit")
$sourceExt = @(".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".vue", ".svelte", ".py", ".go", ".rb", ".php", ".java", ".kt", ".cs", ".css", ".scss")
$jsExt = @(".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs", ".vue", ".svelte")
$ordinal = [System.StringComparer]::Ordinal

$dirs = New-Object System.Collections.Generic.List[string]
$files = New-Object System.Collections.Generic.List[string]

function Walk([string]$Dir, [string]$Rel) {
    foreach ($item in @(Get-ChildItem -LiteralPath $Dir -Force -ErrorAction SilentlyContinue)) {
        $relPath = if ($Rel) { "$Rel/$($item.Name)" } else { $item.Name }
        if ($item.PSIsContainer) {
            if ($pruned -contains $item.Name) { continue }
            if ($relPath -match '(^|/)storage/framework$') { continue }
            $dirs.Add($relPath)
            Walk $item.FullName $relPath
        } elseif ($sourceExt -contains $item.Extension.ToLower()) {
            $files.Add($relPath)
        }
    }
}
Walk $root ""
$dirs.Sort($ordinal)
$files.Sort($ordinal)

$cnt = @{}
function Inc([string]$Key) { if ($cnt.ContainsKey($Key)) { $cnt[$Key]++ } else { $cnt[$Key] = 1 } }

function Get-Style([string]$S) {
    if ($S -cmatch '^[a-z0-9]+$') { return "single-word" }
    if ($S -cmatch '^[a-z][a-z0-9]*(-[a-z0-9]+)+$') { return "kebab-case" }
    if ($S -cmatch '^[a-z][a-z0-9]*(_[a-z0-9]+)+$') { return "snake_case" }
    if ($S -cmatch '^[a-z][a-z0-9]*([A-Z][a-z0-9]*)+$') { return "camelCase" }
    if ($S -cmatch '^[A-Z][A-Za-z0-9]*$' -and $S -cmatch '[a-z]') { return "PascalCase" }
    return "other"
}

$roles = '^(service|controller|module|repository|repo|schema|dto|types|type|model|entity|hook|hooks|store|route|routes|util|utils|config|constants|api|client|handler|middleware|guard|resolver|query|queries|mutation|component|page|layout|stories|styles)$'

foreach ($d in $dirs) {
    $name = ($d -split '/')[-1]
    Inc "dir|$(Get-Style $name)"
}
$fileCount = 0
foreach ($f in $files) {
    $seg = $f -split '/'
    $n = $seg.Length
    $name = $seg[$n - 1]
    $fileCount++
    if ($name.StartsWith(".")) { continue }
    $stem = $name -replace '\..*$', ''
    $ext = $name -replace '^.*\.', '.'
    Inc "ext|$ext"
    Inc "file|$ext|$(Get-Style $stem)"
    $parts = $name -split '\.'
    for ($i = 1; $i -lt $parts.Length - 1; $i++) {
        if ($parts[$i] -cmatch $roles) { Inc "role|.$($parts[$i])" }
    }
    $isTest = $true
    if ($name -cmatch '\.test\.') { Inc "tname|.test." }
    elseif ($name -cmatch '\.spec\.') { Inc "tname|.spec." }
    elseif ($name -cmatch '_test\.(go|py)$') { Inc "tname|_test" }
    elseif ($name -cmatch '^test_.*\.py$') { Inc "tname|test_" }
    elseif ($name -cmatch '_spec\.rb$') { Inc "tname|_spec" }
    elseif ($name -cmatch 'Tests?\.(java|kt|cs)$') { Inc "tname|Test" }
    else { $isTest = $false }
    if ($isTest) {
        $loc = "colocated"
        for ($i = 0; $i -lt $n - 1; $i++) {
            if ($seg[$i] -ceq "__tests__") { $loc = "__tests__"; break }
            if ($seg[$i] -cmatch '^(test|tests|spec|specs)$') { $loc = "test-dir"; break }
        }
        Inc "tloc|$loc"
    }
    if ($n -ge 2) { Inc "top|$($seg[0])" }
    if ($n -ge 3) { Inc "top|$($seg[0])/$($seg[1])" }
}

function Get-Ordered([string]$Prefix) {
    $keys = New-Object System.Collections.Generic.List[string]
    foreach ($k in $cnt.Keys) { if ($k.StartsWith($Prefix, [System.StringComparison]::Ordinal)) { $keys.Add($k) } }
    $keys.Sort([Comparison[string]]{
        param($a, $b)
        if ($cnt[$a] -ne $cnt[$b]) { return $cnt[$b] - $cnt[$a] }
        return [string]::CompareOrdinal($a, $b)
    })
    return ,$keys
}
function Get-Listing([string]$Prefix, [int]$Limit) {
    $keys = Get-Ordered $Prefix
    $items = New-Object System.Collections.Generic.List[string]
    foreach ($k in $keys) {
        if ($Limit -gt 0 -and $items.Count -ge $Limit) { break }
        $items.Add("$($k.Substring($Prefix.Length)) $($cnt[$k])")
    }
    if ($items.Count -eq 0) { return "none" }
    return ($items -join ", ")
}
function Get-Dominant([string]$Prefix) {
    foreach ($k in (Get-Ordered $Prefix)) {
        $name = $k.Substring($Prefix.Length)
        if ($name -ne "single-word" -and $name -ne "other") { return $name }
    }
    return "none"
}

$out = New-Object System.Collections.Generic.List[string]
$out.Add("CONVENTIONS: $Path")
$out.Add("FILES_SCANNED: $fileCount")
$out.Add("FILE_NAMING:")
$extKeys = Get-Ordered "ext|"
$doms = New-Object System.Collections.Generic.List[string]
foreach ($k in $extKeys) {
    $e = $k.Substring(4)
    $out.Add("  ${e}: $(Get-Listing "file|$e|" 0)")
    $d = Get-Dominant "file|$e|"
    if ($d -ne "none") { $doms.Add("$e=$d") }
}
if ($extKeys.Count -eq 0) { $out.Add("  none") }
$out.Add("DOMINANT_FILE_NAMING: $(if ($doms.Count -gt 0) { $doms -join ' ' } else { 'none' })")
$out.Add("DIR_NAMING: $(Get-Listing 'dir|' 0)")
$out.Add("DOMINANT_DIR_NAMING: $(Get-Dominant 'dir|')")
$out.Add("ROLE_SUFFIXES: $(Get-Listing 'role|' 0)")
$out.Add("TEST_LAYOUT: $(Get-Listing 'tloc|' 0)")
$out.Add("TEST_NAMING: $(Get-Listing 'tname|' 0)")
$out.Add("TOP_DIRS: $(Get-Listing 'top|' 12)")

$formatters = New-Object System.Collections.Generic.List[string]
$semiConfig = ""
$quoteConfig = ""
$aliases = ""
$dir = $root
function Has([string]$Pattern) { return @(Get-ChildItem -LiteralPath $dir -Force -Filter $Pattern -ErrorAction SilentlyContinue).Count -gt 0 }
function Add-Formatter([string]$Name) { if (-not $formatters.Contains($Name)) { $formatters.Add($Name) } }
for ($level = 0; $level -lt 4; $level++) {
    $pkg = Join-Path $dir "package.json"
    $pyproject = Join-Path $dir "pyproject.toml"
    if ((Has ".prettierrc*") -or (Has "prettier.config.*") -or ((Test-Path -LiteralPath $pkg) -and (Select-String -LiteralPath $pkg -Pattern '"prettier"\s*:' -Quiet))) {
        Add-Formatter "prettier"
        foreach ($cfgName in @(".prettierrc", ".prettierrc.json")) {
            $cfg = Join-Path $dir $cfgName
            if (Test-Path -LiteralPath $cfg -PathType Leaf) {
                $text = [System.IO.File]::ReadAllText($cfg)
                if (-not $semiConfig -and $text -match '"semi"\s*:\s*false') { $semiConfig = "no" }
                if (-not $semiConfig -and $text -match '"semi"\s*:\s*true') { $semiConfig = "yes" }
                if (-not $quoteConfig -and $text -match '"singleQuote"\s*:\s*true') { $quoteConfig = "single" }
                if (-not $quoteConfig -and $text -match '"singleQuote"\s*:\s*false') { $quoteConfig = "double" }
            }
        }
    }
    if ((Has "eslint.config.*") -or (Has ".eslintrc*")) { Add-Formatter "eslint" }
    if ((Has "biome.json") -or (Has "biome.jsonc")) { Add-Formatter "biome" }
    if (Has ".editorconfig") { Add-Formatter "editorconfig" }
    if ((Has ".stylelintrc*") -or (Has "stylelint.config.*")) { Add-Formatter "stylelint" }
    if ((Has "ruff.toml") -or (Has ".ruff.toml") -or ((Test-Path -LiteralPath $pyproject) -and (Select-String -LiteralPath $pyproject -Pattern '^\[tool\.ruff' -Quiet))) { Add-Formatter "ruff" }
    if ((Test-Path -LiteralPath $pyproject) -and (Select-String -LiteralPath $pyproject -Pattern '^\[tool\.black' -Quiet)) { Add-Formatter "black" }
    if (Has ".rubocop.yml") { Add-Formatter "rubocop" }
    if (Has ".php-cs-fixer*.php") { Add-Formatter "php-cs-fixer" }
    if (Has "go.mod") { Add-Formatter "gofmt" }
    if (-not $aliases) {
        foreach ($cfgName in @("tsconfig.json", "jsconfig.json")) {
            $cfg = Join-Path $dir $cfgName
            if (-not $aliases -and (Test-Path -LiteralPath $cfg -PathType Leaf)) {
                $found = New-Object System.Collections.Generic.List[string]
                foreach ($m in [regex]::Matches([System.IO.File]::ReadAllText($cfg), '"[@~#][^"]*/\*"\s*:')) {
                    $a = $m.Value -replace '^"', '' -replace '\*"\s*:$', ''
                    if (-not $found.Contains($a)) { $found.Add($a) }
                }
                $found.Sort($ordinal)
                $aliases = $found -join ' '
            }
        }
    }
    $markers = @(".git", "package.json", "pyproject.toml", "go.mod", "composer.json", "Gemfile", "pom.xml", "build.gradle")
    if (@($markers | Where-Object { Test-Path -LiteralPath (Join-Path $dir $_) }).Count -gt 0) { break }
    $parent = Split-Path -Parent $dir
    if (-not $parent -or $parent -eq $dir) { break }
    $dir = $parent
}

$stmts = 0; $semis = 0; $single = 0; $double = 0; $tabs = 0; $spaced = 0; $twos = 0
$sources = @($files | Where-Object { $_ -notmatch '\.(css|scss)$' } | Select-Object -First 400)
$jsCount = 0
foreach ($rel in $sources) {
    $isJs = $jsExt -contains ([System.IO.Path]::GetExtension($rel).ToLower())
    if ($isJs) { $jsCount++ }
    foreach ($line in [System.IO.File]::ReadAllLines((Join-Path $root $rel))) {
        if ($line -match '^[ \t]*$') { continue }
        if ($isJs) {
            if ($line -cmatch '^[ \t]*(import|export|const|let|var|return)[ \t]' -and $line -notmatch '[{(,>=\[][ \t]*$') {
                $stmts++
                if ($line -match ';[ \t]*$') { $semis++ }
            }
            if ($line -cmatch '^[ \t]*import[ \t]') {
                if ($line -cmatch "(from[ \t]+|import[ \t]+)'") { $single++ }
                elseif ($line -cmatch '(from[ \t]+|import[ \t]+)"') { $double++ }
            }
        }
        if ($line.StartsWith("`t")) { $tabs++ }
        else {
            $m = [regex]::Match($line, '^ +')
            if ($m.Success) {
                $spaced++
                if ($m.Length % 4 -eq 2) { $twos++ }
            }
        }
    }
}

if ($semiConfig) { $semiLine = "$semiConfig (prettier config)" }
elseif ($jsCount -eq 0 -or $stmts -eq 0) { $semiLine = "unknown" }
elseif ($semis * 2 -gt $stmts) { $semiLine = "yes ($semis of $stmts statements)" }
else { $semiLine = "no ($semis of $stmts statements)" }

if ($quoteConfig) { $quoteLine = "$quoteConfig (prettier config)" }
elseif ($single + $double -eq 0) { $quoteLine = "unknown" }
elseif ($single -ge $double) { $quoteLine = "single ($single of $($single + $double) imports)" }
else { $quoteLine = "double ($double of $($single + $double) imports)" }

if ($tabs + $spaced -eq 0) { $indentLine = "unknown" }
elseif ($tabs -gt $spaced) { $indentLine = "tabs" }
elseif ($twos * 20 -gt $spaced) { $indentLine = "2 spaces" }
else { $indentLine = "4 spaces" }

$out.Add("FORMATTERS: $(if ($formatters.Count -gt 0) { $formatters -join ' ' } else { 'none' })")
$out.Add("SEMICOLONS: $semiLine")
$out.Add("QUOTES: $quoteLine")
$out.Add("INDENT: $indentLine")
$out.Add("IMPORT_ALIAS: $(if ($aliases) { $aliases } else { 'none' })")
$out.Add("")
$out.Add("Follow the dominant style for new files and folders. Formatter config wins over the sample.")
$out | ForEach-Object { Write-Output $_ }
