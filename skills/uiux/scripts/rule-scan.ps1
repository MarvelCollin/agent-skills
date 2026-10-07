param(
    [Parameter(Mandatory=$true)][string]$Path
)

if (-not (Test-Path -LiteralPath $Path)) {
    [Console]::Error.WriteLine("ERROR: $Path does not exist.")
    exit 1
}

$target = (Resolve-Path -LiteralPath $Path).Path
if (Test-Path -LiteralPath $target -PathType Container) {
    $root = $target.TrimEnd('\', '/')
} else {
    $root = Split-Path -Parent $target
}

$excludedDirs = @("node_modules", ".git", "dist", "build", ".next", ".nuxt", ".svelte-kit", "out", "coverage", "vendor", ".turbo", ".cache")
$extensions = @(".html", ".htm", ".jsx", ".tsx", ".js", ".ts", ".vue", ".svelte", ".astro", ".css", ".scss", ".sass", ".less", ".json")
$excludedNames = @("package.json", "package-lock.json")

$allFiles = @(Get-ChildItem -LiteralPath $target -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object {
    $relative = $_.FullName.Substring($root.Length)
    $segments = $relative -split '[\\/]'
    $extensions -contains $_.Extension.ToLower() -and
    -not ($segments | Where-Object { $excludedDirs -contains $_ }) -and
    $_.Name -notlike "*.min.*" -and
    $excludedNames -notcontains $_.Name -and
    $_.Name -notlike "tsconfig*.json"
})
$files = @($allFiles | Where-Object { $_.Extension -ne ".json" })
$jsonFiles = @($allFiles | Where-Object { $_.Extension -eq ".json" })

$results = New-Object System.Collections.Generic.List[string]

function Get-RelativePath([string]$FullPath) {
    return $FullPath.Substring($root.Length).TrimStart('\', '/') -replace '\\', '/'
}

function Add-Findings($Found, [string]$Rule, [string]$Check) {
    foreach ($match in @($Found)) {
        if ($null -eq $match) { continue }
        $text = $match.Line.Trim()
        if ($text.Length -gt 120) { $text = $text.Substring(0, 120) }
        $results.Add("$Rule $Check $(Get-RelativePath $match.Path):$($match.LineNumber): $text")
    }
}

function Find-Lines($FileSet, [string]$Pattern, [switch]$IgnoreCase) {
    if (@($FileSet).Count -eq 0) { return @() }
    $paths = @($FileSet | ForEach-Object { $_.FullName })
    if ($IgnoreCase) {
        return @(Select-String -LiteralPath $paths -Pattern $Pattern -Encoding UTF8)
    }
    return @(Select-String -LiteralPath $paths -Pattern $Pattern -Encoding UTF8 -CaseSensitive)
}

$quote = "[`"']"
$hues = "red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose"
$saturatedHex = "3b82f6|2563eb|1d4ed8|22c55e|16a34a|15803d|a855f7|9333ea|7e22ce|f97316|ea580c|c2410c|f59e0b|d97706|8b5cf6|7c3aed|6366f1|4f46e5|10b981|059669|ef4444|dc2626|ec4899|db2777|06b6d4|0891b2|14b8a6|0d9488|eab308|84cc16|f43f5e|0ea5e9|0284c7"
$tablePattern = "<table([\s>]|$)|<Table([\s>]|$)|<DataTable|useReactTable|createColumnHelper"
$columnFilterPattern = "column-filter|columnFilter|ColumnFilter|setFilterValue|getColumnFilter|filterFn"
$paginationPattern = "paginat|pageSize|page_size|per_page|perPage|[?&]page=|offset|cursor|hasNextPage|nextPage|loadMore|useInfiniteQuery|limit="
$overflowPattern = "overflow(-[xy])?-(auto|scroll)([^a-z-]|$)|overflow(-[xy])?\s*:\s*(auto|scroll)"
$customScrollbarPattern = "scrollbar-width|scrollbar-color|::-webkit-scrollbar|ScrollArea|scroll-area|OverlayScrollbars|simplebar"
$emDash = [string][char]0x2014

Add-Findings (Find-Lines $files "(^|[^a-z0-9-])(bg|from|via|to|fill)-($hues)-(500|600|700)([^0-9]|$)") "R1" "saturated-fill"
Add-Findings (Find-Lines $files "(background(-color)?|fill)\s*:\s*#($saturatedHex)([^0-9a-f]|$)|bg-\[#($saturatedHex)\]" -IgnoreCase) "R1" "saturated-fill"

Add-Findings (Find-Lines $files "rounded" | Where-Object {
    $_.Line -cmatch "(^|[^a-z-])(size|w|h)-(6|7|8|9|10|11|12|14|16)([^0-9]|$)" -and
    $_.Line -cmatch "bg-[a-z]+-(50|100|200|300|400|500|600|700)([^0-9]|$)" -and
    $_.Line -cmatch "place-items-center|justify-center|items-center"
}) "R3" "icon-tile"

Add-Findings (Find-Lines $files "rounded-full" | Where-Object {
    $_.Line -cmatch "(^|[^a-z-])px-(1|1\.5|2|2\.5|3)([^0-9.]|$)" -and
    $_.Line -cmatch "text-(xs|\[1[0-2]px\])"
}) "R4" "pill-badge"
Add-Findings (Find-Lines $files "<(Badge|Chip|Pill)([\s>/]|$)") "R4" "pill-badge"
Add-Findings (Find-Lines $files "(class|className)=.*($quote|\s)(badge|pill|chip)($quote|\s)" -IgnoreCase) "R4" "pill-badge"
Add-Findings (Find-Lines $files "border-radius\s*:\s*(9999|999)px" -IgnoreCase) "R4" "pill-badge"

foreach ($file in $files) {
    $hasTable = Select-String -LiteralPath $file.FullName -Pattern $tablePattern -Encoding UTF8 -CaseSensitive -Quiet
    $hasFilters = Select-String -LiteralPath $file.FullName -Pattern $columnFilterPattern -Encoding UTF8 -CaseSensitive -Quiet
    if ($hasTable -and -not $hasFilters) {
        Add-Findings (Select-String -LiteralPath $file.FullName -Pattern $tablePattern -Encoding UTF8 -CaseSensitive | Select-Object -First 1) "R5" "table-without-column-filters"
    }
    $hasPagination = Select-String -LiteralPath $file.FullName -Pattern $paginationPattern -Encoding UTF8 -Quiet
    if ($hasTable -and -not $hasPagination) {
        Add-Findings (Select-String -LiteralPath $file.FullName -Pattern $tablePattern -Encoding UTF8 -CaseSensitive | Select-Object -First 1) "R10" "table-without-pagination"
    }
}

Add-Findings (Find-Lines $files "modal|dialog|drawer|sheet|popover" -IgnoreCase | Where-Object {
    $_.Line -cmatch "(^|[^a-z-])(w|h)-\[[0-9]+px\]|(^|[^a-z-])(width|height)\s*:\s*[0-9]+px"
}) "R6" "fixed-size-overlay"

Add-Findings (Find-Lines $files "<(DialogContent|SheetContent|DrawerContent|ModalContent|Modal|dialog)(\s[^>]*)?(overflow(-y)?-(auto|scroll)|overflow(-y)?:\s*(auto|scroll))") "R14" "scrolling-overlay"
Add-Findings (Find-Lines $files "disabled=\{[^}]*(isValid|canSubmit|isComplete|isFormValid)") "R14" "disabled-until-valid"

Add-Findings (Find-Lines $files "type=$quote(date|datetime-local|time|month|week|range|color)$quote") "R7" "native-control"
Add-Findings (Find-Lines $files "<(select|datalist)([\s>]|$)") "R7" "native-control"
Add-Findings (Find-Lines $files "type=$quote(checkbox|radio|file)$quote" | Where-Object {
    $_.Line -cnotmatch "sr-only|appearance-none|appearance:\s*none|opacity-0|visually-hidden|\shidden"
}) "R7" "native-control"
Add-Findings (Find-Lines $files "(^|[^.a-zA-Z0-9_])(alert|confirm|prompt)\(") "R7" "browser-dialog"

$hasCustomScrollbar = @(Find-Lines $files $customScrollbarPattern).Count -gt 0
if (-not $hasCustomScrollbar) {
    foreach ($file in $files) {
        Add-Findings (Select-String -LiteralPath $file.FullName -Pattern $overflowPattern -Encoding UTF8 -CaseSensitive | Select-Object -First 1) "R7" "default-scrollbar"
    }
}

Add-Findings (Find-Lines $files "getInitials|(^|[^a-z])initials([^a-z]|$)|charAt\(0\)|(slice|substring|substr)\(0,[ 	]*[12]\)[ 	]*\.toUpperCase" -IgnoreCase) "R11" "initials-avatar"

$componentFiles = @($files | Where-Object { @(".tsx", ".jsx", ".vue", ".svelte") -contains $_.Extension.ToLower() })
Add-Findings (Find-Lines $componentFiles '^\s*(export\s+)?(interface|type)\s+[A-Z][A-Za-z0-9_]*') "R13" "inline-types"
Add-Findings (Find-Lines $componentFiles '(^|[^A-Za-z0-9_.])fetch\(|axios(\.(get|post|put|patch|delete|request))?\(') "R13" "fetch-in-component"
foreach ($file in $componentFiles) {
    $lineCount = @([System.IO.File]::ReadAllLines($file.FullName)).Count
    if ($lineCount -gt 300) {
        $results.Add("R13 large-component $(Get-RelativePath $file.FullName):1: $lineCount lines, split it into smaller components")
    }
}

Add-Findings (Find-Lines $files "$emDash|&mdash;|&#8212;") "R9" "em-dash"
Add-Findings (Find-Lines $jsonFiles $emDash) "R9" "em-dash"
Add-Findings (Find-Lines $files "[A-Za-z0-9`"'/]>[^<>{}]*[A-Za-z0-9)]\s*;\s+[A-Za-z][^<>{}]*<") "R9" "semicolon-in-copy"
Add-Findings (Find-Lines $jsonFiles ":\s*`"[^`"]*[A-Za-z0-9)];\s+[A-Za-z][^`"]*`"") "R9" "semicolon-in-copy"

Write-Output "RULE SCAN: $Path"
Write-Output "FILES_SCANNED: $($allFiles.Count)"
Write-Output ""
$results | Sort-Object { $_ } -Culture "en-US" | ForEach-Object { Write-Output $_ }
Write-Output ""
Write-Output "FINDINGS: $($results.Count)"
foreach ($rule in @("R1", "R3", "R4", "R5", "R6", "R7", "R9", "R10", "R11", "R13", "R14")) {
    $count = @($results | Where-Object { $_.StartsWith("$rule ") }).Count
    Write-Output "${rule}: $count"
}
