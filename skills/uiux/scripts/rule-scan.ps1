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

$sparkle = [string][char]0x2728
$arrow = [string][char]0x2192
$checkGlyphs = "$([char]0x2713)|$([char]0x2714)|$([char]0x2705)"
$pastelPattern = "(^|[^a-z0-9-])(bg|from|via|to)-($hues)-(50|100|200)([^0-9]|$)"
$checkPattern = "<(Check|CheckIcon|CheckCircle|CheckCircle2|CircleCheck|CircleCheckBig|BadgeCheck)[\s/>]|$checkGlyphs"

Add-Findings (Find-Lines $files "#(39ff14|00ffff|ff00ff|ccff00|00ff00|0ff|f0f|0f0)([^0-9a-f]|$)" -IgnoreCase) "R1" "neon-color"
Add-Findings (Find-Lines $files "(^|[^a-z0-9-])(text|bg|border|ring|shadow|from|via|to|fill|stroke)-(lime|cyan|fuchsia)-(300|400)([^0-9]|$)") "R1" "neon-color"
foreach ($file in $files) {
    $pastel = @(Select-String -LiteralPath $file.FullName -Pattern $pastelPattern -AllMatches -Encoding UTF8 -CaseSensitive)
    $pastelHues = @($pastel | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[3].Value } | Sort-Object -Unique)
    if ($pastelHues.Count -ge 3) {
        Add-Findings ($pastel | Select-Object -First 1) "R1" "pastel-rainbow"
    }
}

Add-Findings (Find-Lines $files "(^|[^A-Za-z])(Sparkles|Sparkle|WandSparkles|SparklesIcon)([^A-Za-z]|$)|lucide-sparkles|$sparkle") "R15" "sparkle-icon"
Add-Findings (Find-Lines $files "(radial|linear)-gradient\([^)]*[^0-9.][12]px[^)]*transparent|DotPattern|GridPattern|dot-pattern|grid-pattern") "R15" "dot-grid"
Add-Findings (Find-Lines $files "rounded-full" | Where-Object { $_.Line -cmatch "blur-(2xl|3xl|\[[0-9]+px\])" }) "R15" "gradient-orb"
Add-Findings (Find-Lines $files "filter\s*:\s*blur\(([4-9][0-9]|[1-9][0-9][0-9])px\)" -IgnoreCase) "R15" "gradient-orb"
Add-Findings (Find-Lines $files "backdrop-blur|backdrop-saturate|backdrop-filter\s*:" -IgnoreCase) "R15" "glass-surface"
Add-Findings (Find-Lines $files "hover:(-translate-y-|scale-1[0-9][0-9])|hover:shadow-(xl|2xl)") "R15" "hover-lift"
Add-Findings (Find-Lines $files "hover:-?translate-x-" | Where-Object { $_.Line -cmatch "Arrow|arrow|Chevron|chevron|$arrow" }) "R15" "animated-arrow"
Add-Findings (Find-Lines $files "font-family[^;]*(Inter|Geist|Space Grotesk)([^A-Za-z]|$)|(^|[^A-Za-z_])(Inter|Space_Grotesk|Geist|Geist_Mono)\s*\(\{|[`"']geist/font|family=(Inter|Space\+Grotesk|Geist)([^A-Za-z]|$)") "R15" "default-font"
Add-Findings (Find-Lines $files "[\uD83C-\uD83E][\uDC00-\uDFFF]") "R15" "emoji"
foreach ($file in $files) {
    $checks = @(Select-String -LiteralPath $file.FullName -Pattern $checkPattern -Encoding UTF8 -CaseSensitive)
    if ($checks.Count -ge 3) {
        Add-Findings ($checks | Select-Object -First 1) "R15" "checkmark-bullets"
    }
    $text = [System.IO.File]::ReadAllText($file.FullName)
    $macDots = ($text -match "#ff5f5[67]") -and ($text -match "#ffbd2e|#febc2e") -and ($text -match "#27c93f|#28c840")
    $tailwindDots = ($text -cmatch "rounded-full[^`"']*bg-red-(400|500)|bg-red-(400|500)[^`"']*rounded-full") -and
        ($text -cmatch "rounded-full[^`"']*bg-(yellow|amber)-(400|500)|bg-(yellow|amber)-(400|500)[^`"']*rounded-full") -and
        ($text -cmatch "rounded-full[^`"']*bg-(green|emerald)-(400|500)|bg-(green|emerald)-(400|500)[^`"']*rounded-full")
    if ($macDots -or $tailwindDots) {
        Add-Findings (Select-String -LiteralPath $file.FullName -Pattern "#ff5f5[67]|bg-red-(400|500)" -Encoding UTF8 | Select-Object -First 1) "R15" "fake-terminal"
    }
}

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

$markupFiles = @($files | Where-Object { @(".html", ".htm", ".jsx", ".tsx", ".vue", ".svelte", ".astro") -contains $_.Extension.ToLower() })
Add-Findings (Find-Lines $markupFiles "<(img|Image)(\s[^>]*)?/?>" | Where-Object { $_.Line -cnotmatch "[\s:]alt\s*=|\{\.\.\." }) "R16" "img-without-alt"
Add-Findings (Find-Lines $markupFiles "lorem ipsum|(^|[^a-z0-9.-])example\.(com|org)|123 main st|555-[0-9]{4}|\(555\)|john doe|jane doe|your-?(domain|company)\.com|acme (inc|corp)" -IgnoreCase) "R16" "placeholder-copy"
foreach ($file in @($markupFiles | Where-Object { @(".html", ".htm") -contains $_.Extension.ToLower() })) {
    $html = [System.IO.File]::ReadAllText($file.FullName)
    if ($html -match "<head([\s>]|$)") {
        $head = Select-String -LiteralPath $file.FullName -Pattern "<head([\s>]|$)" -Encoding UTF8 | Select-Object -First 1
        if ($html -notmatch "name=[`"']?viewport") { Add-Findings $head "R16" "missing-viewport" }
        if ($html -notmatch "<title([\s>]|$)") { Add-Findings $head "R16" "missing-title" }
        if ($html -notmatch "name=[`"']?description") { Add-Findings $head "R16" "missing-description" }
    }
    if ($html -match "<html([\s>]|$)" -and $html -notmatch "<html[^>]*\slang=") {
        Add-Findings (Select-String -LiteralPath $file.FullName -Pattern "<html([\s>]|$)" -Encoding UTF8 | Select-Object -First 1) "R16" "missing-lang"
    }
}

$labelPattern = "<label|<Label|<FormLabel|<FieldLabel|<legend|<Legend|aria-label|aria-labelledby|\slabel="
$controlPattern = "<(input|Input|select|Select|SelectTrigger|button|Button|DatePicker|Combobox|ComboboxInput)([\s>]|$)"
$heightPattern = "[`"'\s]h-(7|8|9|10|11|12|14)([`"'\s]|$)"
foreach ($file in $markupFiles) {
    $placeholders = @(Select-String -LiteralPath $file.FullName -Pattern "<(input|Input|textarea|Textarea)[^>]*placeholder=" -Encoding UTF8 -CaseSensitive)
    $hasLabel = Select-String -LiteralPath $file.FullName -Pattern $labelPattern -Encoding UTF8 -CaseSensitive -Quiet
    if ($placeholders.Count -gt 0 -and -not $hasLabel) {
        Add-Findings ($placeholders | Select-Object -First 1) "R17" "placeholder-as-label"
    }
    $sized = @(Select-String -LiteralPath $file.FullName -Pattern $controlPattern -Encoding UTF8 -CaseSensitive | Where-Object { $_.Line -cmatch $heightPattern })
    $heights = @($sized | ForEach-Object { [regex]::Matches($_.Line, $heightPattern) } | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    if ($heights.Count -ge 2) {
        Add-Findings ($sized | Select-Object -First 1) "R17" "mixed-control-heights"
    }
    $headers = @(Select-String -LiteralPath $file.FullName -Pattern "<(thead|TableHeader)([\s>]|$)" -Encoding UTF8 -CaseSensitive)
    $hasSticky = Select-String -LiteralPath $file.FullName -Pattern "sticky" -Encoding UTF8 -CaseSensitive -Quiet
    if ($headers.Count -gt 0 -and -not $hasSticky) {
        Add-Findings ($headers | Select-Object -First 1) "R19" "header-not-sticky"
    }
}

Add-Findings (Find-Lines $files "(^|[`"'\s])transition-all([`"'\s]|$)|transition(-property)?\s*:\s*[`"']?all([`"'\s;,]|$)") "R18" "transition-all"
Add-Findings (Find-Lines $files "transition-\[(width|height|max-height|min-height|top|left|right|bottom|margin|padding|inset)|transition(-property)?\s*:\s*[`"']?[^;`"'{}]*(^|[\s,:`"'])(width|height|max-height|min-height|top|left|right|bottom|margin|margin-[a-z]+|padding|padding-[a-z]+)([\s,;`"']|$)|animate=\{\{[^}]*(width|height|top|left)\s*:") "R18" "layout-animation"
Add-Findings (Find-Lines $files "(^|[`"'\s:])duration-(500|700|1000|\[([5-9][0-9]{2}|[1-9][0-9]{3,})ms\]|\[[1-9](\.[0-9]+)?s\])([`"'\s]|$)|(transition|animation)(-duration)?\s*:\s*[`"']?[^;`"'{}]*[^0-9.]([5-9][0-9]{2}|[1-9][0-9]{3,})ms|(transition|animation)(-duration)?\s*:\s*[`"']?[^;`"'{}]*\s(0?\.[5-9][0-9]*|[1-9](\.[0-9]+)?)s([^a-z]|$)" | Where-Object {
    $_.Line -cnotmatch "infinite|spin|pulse|shimmer|skeleton|progress"
}) "R18" "slow-motion"
Add-Findings (Find-Lines $files "(^|[`"'\s])animate-bounce([`"'\s]|$)|cubic-bezier\([^,)]*,\s*(-|1\.[0-9]*[1-9]|[2-9])|cubic-bezier\([^,)]*,[^,)]*,[^,)]*,\s*(-|1\.[0-9]*[1-9]|[2-9])") "R18" "bounce"
$animPattern = "@keyframes|(transition|animation)(-[a-z]+)?\s*:|(^|[`"'\s])(transition|transition-[a-z]+|animate-[a-z]+)([`"'\s]|$)|framer-motion|motion/react|<motion\.|startViewTransition"
$reducedPattern = "prefers-reduced-motion|motion-reduce:|motion-safe:|useReducedMotion|reducedMotion|MotionConfig"
if (@(Find-Lines $files $reducedPattern).Count -eq 0) {
    foreach ($file in $files) {
        Add-Findings (Select-String -LiteralPath $file.FullName -Pattern $animPattern -Encoding UTF8 -CaseSensitive | Select-Object -First 1) "R18" "missing-reduced-motion"
    }
}

$animateUtilityPattern = "(^|[`"'\s:])(animate-in|animate-out|fade-in-0|fade-out-0|zoom-in-95|zoom-out-95|slide-in-from-(top|bottom|left|right)(-[0-9]+)?)([`"'\s]|$)"
$animatePluginPattern = "tw-animate-css|tailwindcss-animate"
$hasAnimatePlugin = @(Find-Lines $files $animatePluginPattern).Count -gt 0
if (-not $hasAnimatePlugin) {
    $packages = @(Get-ChildItem -LiteralPath $root -Recurse -File -Force -Filter "package.json" -ErrorAction SilentlyContinue | Where-Object {
        -not (($_.FullName.Substring($root.Length) -split '[\\/]') -contains "node_modules")
    })
    $dir = $root
    for ($i = 0; $i -lt 4; $i++) {
        $parent = Split-Path -Parent $dir
        if (-not $parent -or $parent -eq $dir) { break }
        $dir = $parent
        $candidate = Join-Path $dir "package.json"
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { $packages += Get-Item -LiteralPath $candidate }
    }
    foreach ($package in $packages) {
        if (Select-String -LiteralPath $package.FullName -Pattern $animatePluginPattern -Encoding UTF8 -Quiet) {
            $hasAnimatePlugin = $true
            break
        }
    }
}
if (-not $hasAnimatePlugin) {
    foreach ($file in $files) {
        Add-Findings (Select-String -LiteralPath $file.FullName -Pattern $animateUtilityPattern -Encoding UTF8 -CaseSensitive | Select-Object -First 1) "R18" "motion-plugin-missing"
    }
}

$fixedWidthPattern = "(^|[`"'\s])w-(64|72|80|96)([`"'\s]|$)"
foreach ($file in $markupFiles) {
    if (Select-String -LiteralPath $file.FullName -Pattern "<(input|Input|SearchInput|textarea|Textarea)([\s>/]|$)" -Encoding UTF8 -CaseSensitive -Quiet) {
        Add-Findings (Select-String -LiteralPath $file.FullName -Pattern $fixedWidthPattern -Encoding UTF8 -CaseSensitive | Where-Object {
            $_.Line -cnotmatch "(sm|md|lg|xl|2xl|@[a-z0-9]+):w-"
        }) "R19" "fixed-width-control"
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
foreach ($rule in @("R1", "R3", "R4", "R5", "R6", "R7", "R9", "R10", "R11", "R13", "R14", "R15", "R16", "R17", "R18", "R19")) {
    $count = @($results | Where-Object { $_.StartsWith("$rule ") }).Count
    Write-Output "${rule}: $count"
}
