param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)][string[]]$Path,
    [switch]$Online,
    [string]$Mailto = ""
)

$Path = @($Path | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne "" })
if ($Path.Count -eq 0) {
    [Console]::Error.WriteLine("ERROR: give a file or folder to check.")
    [Console]::Error.WriteLine("Usage: cite-check.ps1 [-Online] [-Mailto <address>] -Path <path>[,path...]")
    exit 1
}

$extensions = @(".tex", ".md", ".markdown", ".qmd", ".rmd", ".bib")
$excludedDirs = @(".git", "node_modules", ".venv", "venv", "_build", "build")

$root = $null
$fileList = New-Object System.Collections.Generic.List[object]
foreach ($p in $Path) {
    if (-not (Test-Path -LiteralPath $p)) {
        [Console]::Error.WriteLine("ERROR: $p does not exist.")
        exit 1
    }
    $target = (Resolve-Path -LiteralPath $p).Path
    if (Test-Path -LiteralPath $target -PathType Container) {
        $base = $target.TrimEnd('\', '/')
        if (-not $root) { $root = $base }
        $found = @(Get-ChildItem -LiteralPath $target -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object {
            $relative = $_.FullName.Substring($base.Length) -replace '\\', '/'
            $segments = $relative.TrimStart('/') -split '/'
            $dirSegments = if ($segments.Count -gt 1) { $segments[0..($segments.Count - 2)] } else { @() }
            ($extensions -contains $_.Extension.ToLower()) -and -not ($dirSegments | Where-Object { $excludedDirs -contains $_ })
        })
        foreach ($f in $found) { $fileList.Add($f) }
    } else {
        $item = Get-Item -LiteralPath $target
        if ($extensions -notcontains $item.Extension.ToLower()) {
            [Console]::Error.WriteLine("ERROR: $p is not a .tex, .md or .bib file.")
            exit 1
        }
        if (-not $root) { $root = Split-Path -Parent $target }
        $fileList.Add($item)
    }
}

function Get-RelativePath([string]$FullPath) {
    if ($root -and ($FullPath.StartsWith($root + '\') -or $FullPath.StartsWith($root + '/'))) {
        return $FullPath.Substring($root.Length + 1) -replace '\\', '/'
    }
    return $FullPath -replace '\\', '/'
}

$byRel = @{}
foreach ($f in $fileList) {
    $r = Get-RelativePath $f.FullName
    if (-not $byRel.ContainsKey($r)) { $byRel[$r] = $f }
}
$relNames = [string[]]@($byRel.Keys)
[Array]::Sort($relNames, [StringComparer]::Ordinal)

$codes = @{ "MISSING_KEY" = 1; "UNCITED" = 2; "NO_LOCATOR" = 3; "MISSING_FIELD" = 4; "BAD_DOI" = 5; "DUP_KEY" = 6; "DUP_DOI" = 7; "DUP_TITLE" = 8; "DOI_NOT_FOUND" = 9; "TITLE_MISMATCH" = 10; "YEAR_MISMATCH" = 11; "DOI_UNCHECKED" = 12 }
$sortKeys = New-Object System.Collections.Generic.List[string]
$lines = New-Object System.Collections.Generic.List[string]

function Add-Finding([string]$Code, [string]$Key, [string]$File, [int]$Line, [string]$Detail) {
    $sortKeys.Add(("{0:D2}`t{1}`t{2:D9}`t{3}" -f $codes[$Code], $File, $Line, $Key))
    $lines.Add("$Code $Key ${File}:${Line}: $Detail")
}

function Trim-Space([string]$s) {
    return $s.Trim([char[]]@(' ', "`t"))
}

function Get-NormTitle([string]$s) {
    if ($null -eq $s) { return "" }
    $s = [regex]::Replace($s, '<[^>]*>', ' ')
    $s = [regex]::Replace($s, '&[A-Za-z#0-9]+;', ' ')
    $s = [regex]::Replace($s, '\\u[0-9A-Fa-f]{4}', ' ')
    $s = [regex]::Replace($s, '\\[A-Za-z]+', '')
    $s = [regex]::Replace($s, '\\[^A-Za-z]', '')
    $s = [regex]::Replace($s, '[{}]', '')
    $s = $s.ToLowerInvariant()
    $s = [regex]::Replace($s, '[^a-z0-9]+', ' ')
    return Trim-Space $s
}

$cited = New-Object System.Collections.Hashtable ([StringComparer]::Ordinal)
$citedOrder = New-Object System.Collections.Generic.List[string]
$defined = New-Object System.Collections.Hashtable ([StringComparer]::Ordinal)
$definedOrder = New-Object System.Collections.Generic.List[string]
$doiKey = New-Object System.Collections.Hashtable ([StringComparer]::Ordinal)
$titleKey = New-Object System.Collections.Hashtable ([StringComparer]::Ordinal)
$doiList = New-Object System.Collections.Generic.List[object]
$script:nociteAll = $false
$script:pend = ""
$script:pendline = 0
$script:pendcount = 0
$script:rel = ""

function Add-Cite([string]$k, [int]$ln) {
    if ($k -eq "") { return }
    if (-not $cited.ContainsKey($k)) {
        $cited[$k] = @($script:rel, $ln)
        $citedOrder.Add($k)
    }
}

function Add-Keys([string]$content, [int]$ln) {
    foreach ($part in $content.Split(',')) {
        $k = Trim-Space $part
        if ($k -eq "*") { $script:nociteAll = $true }
        elseif ($k -cnotmatch '#') { Add-Cite $k $ln }
    }
}

function Scan-Cites([string]$s, [int]$ln) {
    $script:pend = ""
    while ($true) {
        $m = [regex]::Match($s, '\\[A-Za-z]*cite[A-Za-z]*\*?')
        if (-not $m.Success) { return }
        $startcmd = $m.Index
        $plural = $m.Value -cmatch 'cites\*?$'
        $rest = $s.Substring($m.Index + $m.Length)
        $got = 0
        while ($true) {
            $rest = [regex]::Replace($rest, '^[ \t]+', '')
            $c = if ($rest.Length -gt 0) { $rest.Substring(0, 1) } else { "" }
            if ($c -eq "[" -or $c -eq "(") {
                $closer = if ($c -eq "[") { "]" } else { ")" }
                $i = $rest.IndexOf($closer)
                if ($i -lt 0) {
                    $script:pend = $s.Substring($startcmd)
                    $script:pendline = $ln
                    return
                }
                $rest = $rest.Substring($i + 1)
                continue
            }
            if ($c -eq "{") {
                $i = $rest.IndexOf("}")
                if ($i -lt 0) {
                    $script:pend = $s.Substring($startcmd)
                    $script:pendline = $ln
                    return
                }
                Add-Keys $rest.Substring(1, $i - 1) $ln
                $rest = $rest.Substring($i + 1)
                $got++
                if ($plural) { continue }
                break
            }
            if ($c -eq "" -and $got -eq 0) {
                $script:pend = $s.Substring($startcmd)
                $script:pendline = $ln
                return
            }
            break
        }
        $s = $rest
    }
}

function Scan-Pandoc([string]$s, [int]$ln) {
    $s = " " + $s
    while ($true) {
        $m = [regex]::Match($s, '[\[ \t;(-]@[A-Za-z0-9_][A-Za-z0-9_:./-]*')
        if (-not $m.Success) { return }
        $k = [regex]::Replace($m.Value.Substring(2), '[^A-Za-z0-9_]+$', '')
        if ($k -cnotmatch '^(fig|tbl|sec|eq|lst|tab):') { Add-Cite $k $ln }
        $s = $s.Substring($m.Index + $m.Length)
    }
}

function Add-Defined([string]$k, [int]$ln) {
    $defined[$k] = @($script:rel, $ln)
    $definedOrder.Add($k)
}

function Scan-Bibitems([string]$s, [int]$ln) {
    while ($true) {
        $m = [regex]::Match($s, '\\bibitem(\[[^\]]*\])?\{[^}]*\}')
        if (-not $m.Success) { return }
        $k = [regex]::Replace($m.Value, '^\\bibitem(\[[^\]]*\])?\{', '')
        $k = Trim-Space ([regex]::Replace($k, '\}$', ''))
        if ($k -ne "" -and -not $defined.ContainsKey($k)) { Add-Defined $k $ln }
        $s = $s.Substring($m.Index + $m.Length)
    }
}

function Text-Line([string]$line, [int]$ln) {
    if ($script:pend -ne "") {
        if ($script:pendcount -ge 5) {
            $script:pend = ""
        } else {
            $script:pendcount++
            Scan-Cites ($script:pend + " " + $line) $script:pendline
            return
        }
    }
    $script:pendcount = 0
    Scan-Cites $line $ln
}

function Get-BraceEnd([string]$s) {
    $d = 0
    for ($i = 0; $i -lt $s.Length; $i++) {
        $c = $s[$i]
        if ($c -eq '{') { $d++ }
        elseif ($c -eq '}') {
            $d--
            if ($d -eq 0) { return $i }
        }
    }
    return $s.Length
}

function Get-QuoteEnd([string]$s) {
    $d = 0
    for ($i = 1; $i -lt $s.Length; $i++) {
        $c = $s[$i]
        if ($c -eq '{') { $d++ }
        elseif ($c -eq '}') { $d-- }
        elseif ($c -eq '"' -and $d -le 0 -and $s[$i - 1] -ne '\') { return $i }
    }
    return $s.Length
}

function Get-Rest([string]$s, [int]$from) {
    if ($from -ge $s.Length) { return "" }
    return $s.Substring($from)
}

function Parse-Entry([string]$text, [int]$ln) {
    $i = $text.IndexOf('{')
    $rest = Get-Rest $text ($i + 1)
    $i = $rest.IndexOf(',')
    if ($i -lt 0) {
        $key = $rest
        $rest = ""
    } else {
        $key = $rest.Substring(0, $i)
        $rest = Get-Rest $rest ($i + 1)
    }
    $key = [regex]::Replace($key, '[ \t}]', '')
    if ($key -eq "") { return }
    $F = @{}
    while ($true) {
        $rest = [regex]::Replace($rest, '^[ \t,]+', '')
        $m = [regex]::Match($rest, '^[A-Za-z][A-Za-z0-9_:.+-]*[ \t]*=[ \t]*')
        if (-not $m.Success) { break }
        $name = [regex]::Replace($m.Value, '[ \t]*=[ \t]*$', '').ToLowerInvariant()
        $rest = Get-Rest $rest $m.Length
        $val = ""
        while ($true) {
            $c = if ($rest.Length -gt 0) { $rest[0] } else { [char]0 }
            if ($c -eq '{') {
                $n = Get-BraceEnd $rest
                $val += $rest.Substring(1, [Math]::Max(0, [Math]::Min($n, $rest.Length) - 1))
                $rest = Get-Rest $rest ($n + 1)
            } elseif ($c -eq '"') {
                $n = Get-QuoteEnd $rest
                $val += $rest.Substring(1, [Math]::Max(0, [Math]::Min($n, $rest.Length) - 1))
                $rest = Get-Rest $rest ($n + 1)
            } else {
                $b = [regex]::Match($rest, '^[^,}# \t]*')
                $val += $b.Value
                $rest = Get-Rest $rest $b.Length
            }
            $rest = [regex]::Replace($rest, '^[ \t]+', '')
            if ($rest.StartsWith("#")) {
                $rest = [regex]::Replace($rest.Substring(1), '^[ \t]+', '')
                continue
            }
            break
        }
        $F[$name] = Trim-Space $val
    }
    if ($defined.ContainsKey($key)) {
        $prev = $defined[$key]
        Add-Finding "DUP_KEY" $key $script:rel $ln "also defined at $($prev[0]):$($prev[1])"
        return
    }
    Add-Defined $key $ln
    $get = { param($n) if ($F.ContainsKey($n)) { [string]$F[$n] } else { "" } }
    if ((& $get "doi") -eq "" -and (& $get "url") -eq "" -and (& $get "eprint") -eq "" -and (& $get "isbn") -eq "" -and (& $get "howpublished") -cnotmatch 'https?:' -and (& $get "note") -cnotmatch 'https?:') {
        Add-Finding "NO_LOCATOR" $key $script:rel $ln "no doi, url, eprint or isbn"
    }
    if (-not $F.ContainsKey("crossref")) {
        $missing = ""
        if ((& $get "title") -eq "") { $missing += " title" }
        if ((& $get "author") -eq "" -and (& $get "editor") -eq "" -and (& $get "organization") -eq "" -and (& $get "institution") -eq "") { $missing += " author" }
        if ((& $get "year") -eq "" -and (& $get "date") -eq "") { $missing += " year" }
        if ($missing -ne "") { Add-Finding "MISSING_FIELD" $key $script:rel $ln "missing$missing" }
    }
    $year = ""
    $ym = [regex]::Match((& $get "year") + " " + (& $get "date"), '[12][0-9][0-9][0-9]')
    if ($ym.Success) { $year = $ym.Value }
    $title = Get-NormTitle (& $get "title")
    $doi = & $get "doi"
    if ($doi -ne "") {
        $doi = [regex]::Replace($doi, '^[ \t]*(https?://)?(dx\.)?doi\.org/', '')
        $doi = [regex]::Replace($doi, '^[Dd][Oo][Ii]:[ \t]*', '')
        $doi = Trim-Space $doi
        if ($doi -cnotmatch '^10\.[0-9][0-9][0-9][0-9]+/[^ \t]+$') {
            Add-Finding "BAD_DOI" $key $script:rel $ln $doi
        } else {
            $low = $doi.ToLowerInvariant()
            if ($doiKey.ContainsKey($low)) {
                Add-Finding "DUP_DOI" $key $script:rel $ln "same doi as $($doiKey[$low])"
            } else {
                $doiKey[$low] = $key
                $doiList.Add(@($key, $script:rel, $ln, $doi, $title, $year))
            }
        }
    }
    if ($title -ne "") {
        if ($titleKey.ContainsKey($title)) {
            Add-Finding "DUP_TITLE" $key $script:rel $ln "same title as $($titleKey[$title])"
        } else {
            $titleKey[$title] = $key
        }
    }
}

foreach ($relName in $relNames) {
    $script:rel = $relName
    $file = $byRel[$relName]
    $ext = $file.Extension.ToLower()
    $kind = "tex"
    if ($ext -eq ".bib") { $kind = "bib" }
    elseif (@(".md", ".markdown", ".qmd", ".rmd") -contains $ext) { $kind = "md" }
    $script:pend = ""
    $script:pendcount = 0
    $infence = $false
    $yaml = $false
    $inentry = $false
    $etype = ""
    $ebuf = ""
    $edepth = 0
    $eline = 0
    $content = [System.IO.File]::ReadAllLines($file.FullName, [System.Text.Encoding]::UTF8)
    for ($n = 0; $n -lt $content.Count; $n++) {
        $ln = $n + 1
        $line = $content[$n]
        if ($kind -eq "bib") {
            if (-not $inentry) {
                $m = [regex]::Match($line, '^[ \t]*@[A-Za-z]+[ \t]*\{')
                if (-not $m.Success) { continue }
                $etype = [regex]::Replace($m.Value.ToLowerInvariant(), '[^a-z]', '')
                $inentry = $true
                $ebuf = ""
                $edepth = 0
                $eline = $ln
                $line = $line.Substring($m.Index)
            }
            $ebuf = $ebuf + " " + $line
            $edepth += ($line.Split('{').Count - 1) - ($line.Split('}').Count - 1)
            if ($edepth -le 0) {
                $inentry = $false
                if (@("comment", "string", "preamble") -notcontains $etype) { Parse-Entry $ebuf $eline }
            }
            continue
        }
        if ($kind -eq "md") {
            if ($ln -eq 1 -and $line -cmatch '^---[ \t]*$') {
                $yaml = $true
                continue
            }
            if ($yaml) {
                if ($line -cmatch '^(---|\.\.\.)[ \t]*$') { $yaml = $false }
                continue
            }
            if ($line -cmatch '^[ \t]*(```|~~~)') {
                $infence = -not $infence
                continue
            }
            if ($infence) { continue }
            $line = [regex]::Replace($line, '`[^`]*`', ' ')
            Scan-Pandoc $line $ln
        } else {
            $line = $line.Replace('\%', '  ')
            $cut = $line.IndexOf('%')
            if ($cut -ge 0) { $line = $line.Substring(0, $cut) }
            Scan-Bibitems $line $ln
        }
        Text-Line $line $ln
    }
}

foreach ($k in $citedOrder) {
    if (-not $defined.ContainsKey($k)) {
        $loc = $cited[$k]
        Add-Finding "MISSING_KEY" $k $loc[0] $loc[1] "cited but not in any bibliography"
    }
}
if (-not $script:nociteAll) {
    foreach ($k in $definedOrder) {
        if (-not $cited.ContainsKey($k)) {
            $loc = $defined[$k]
            Add-Finding "UNCITED" $k $loc[0] $loc[1] "in the bibliography but never cited"
        }
    }
}

$checked = 0
if ($Online) {
    $ProgressPreference = 'SilentlyContinue'
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
    $api = if ($env:CITE_CHECK_API) { $env:CITE_CHECK_API.TrimEnd('/') } else { "https://api.crossref.org" }
    $delay = if ($env:CITE_CHECK_DELAY) { [double]$env:CITE_CHECK_DELAY } else { 1.0 }
    $agent = "cite-check/1.0"
    if ($Mailto) { $agent = "$agent (mailto:$Mailto)" }
    $first = $true
    foreach ($entry in $doiList) {
        $key = $entry[0]; $file = $entry[1]; $line = $entry[2]; $doi = $entry[3]; $bibTitle = $entry[4]; $bibYear = $entry[5]
        if (-not $first -and $delay -gt 0) { Start-Sleep -Milliseconds ([int]($delay * 1000)) }
        $first = $false
        $checked++
        $url = "$api/works/" + ([Uri]::EscapeDataString($doi) -replace '%2F', '/')
        $code = "000"
        $body = ""
        try {
            $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 20 -UserAgent $agent -ErrorAction Stop
            $code = [string][int]$resp.StatusCode
            $body = [System.Text.Encoding]::UTF8.GetString($resp.RawContentStream.ToArray())
        } catch {
            $r = $_.Exception.Response
            if ($r) { $code = [string][int]$r.StatusCode }
        }
        if ($code -eq "200") {
            $t = ""
            $subT = ""
            $y = ""
            $m = [regex]::Match($body, '[{,]"title":\["((?:[^"\\]|\\.)*)"')
            if ($m.Success) { $t = $m.Groups[1].Value.Replace('\"', '"').Replace('\/', '/') }
            $m = [regex]::Match($body, '[{,]"subtitle":\["((?:[^"\\]|\\.)*)"')
            if ($m.Success) { $subT = $m.Groups[1].Value.Replace('\"', '"').Replace('\/', '/') }
            $m = [regex]::Match($body, '"issued":\{"date-parts":\[\[([0-9]{4})')
            if ($m.Success) { $y = $m.Groups[1].Value }
            $full = $t
            if ($subT -ne "") { $full = "${t}: $subT" }
            $reg = Get-NormTitle $full
            if ($bibTitle -ne "" -and $reg -ne "") {
                $setA = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
                $setB = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
                foreach ($w in $bibTitle.Split(' ')) { [void]$setA.Add($w) }
                foreach ($w in $reg.Split(' ')) { [void]$setB.Add($w) }
                $inter = 0
                $uni = 0
                foreach ($w in $setA) {
                    $uni++
                    if ($setB.Contains($w)) { $inter++ }
                }
                foreach ($w in $setB) { if (-not $setA.Contains($w)) { $uni++ } }
                if ($uni -gt 0 -and [Math]::Floor(100 * $inter / $uni) -lt 70) {
                    Add-Finding "TITLE_MISMATCH" $key $file $line "Crossref title is `"$full`""
                }
            }
            if ($bibYear -ne "" -and $y -ne "") {
                if ([Math]::Abs([int]$bibYear - [int]$y) -gt 1) {
                    Add-Finding "YEAR_MISMATCH" $key $file $line "bib year $bibYear, Crossref year $y"
                }
            }
        } elseif ($code -eq "404") {
            Add-Finding "DOI_NOT_FOUND" $key $file $line "$doi not found at Crossref"
        } else {
            Add-Finding "DOI_UNCHECKED" $key $file $line "request failed with status $code"
        }
    }
}

$keyArray = $sortKeys.ToArray()
$lineArray = $lines.ToArray()
[Array]::Sort($keyArray, $lineArray, [StringComparer]::Ordinal)

Write-Output "CITE CHECK: $($Path -join ' ')"
Write-Output "FILES_SCANNED: $($relNames.Count)"
if ($Online) { Write-Output "ONLINE: on" } else { Write-Output "ONLINE: off" }
Write-Output "CITED_KEYS: $($citedOrder.Count)"
Write-Output "BIB_ENTRIES: $($definedOrder.Count)"
Write-Output ""
foreach ($l in $lineArray) { Write-Output $l }
Write-Output ""
Write-Output "FINDINGS: $($lineArray.Count)"
foreach ($code in @("MISSING_KEY", "UNCITED", "NO_LOCATOR", "MISSING_FIELD", "BAD_DOI", "DUP_KEY", "DUP_DOI", "DUP_TITLE")) {
    $count = @($lineArray | Where-Object { $_.StartsWith("$code ") }).Count
    Write-Output "${code}: $count"
}
if ($Online) {
    Write-Output "DOI_CHECKED: $checked"
    foreach ($code in @("DOI_NOT_FOUND", "TITLE_MISMATCH", "YEAR_MISMATCH", "DOI_UNCHECKED")) {
        $count = @($lineArray | Where-Object { $_.StartsWith("$code ") }).Count
        Write-Output "${code}: $count"
    }
}
Write-Output ""
Write-Output "Each line is a lead. Confirm it in the document and the registry before you report it."
