param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)][string[]]$Path
)

$Path = @($Path | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne "" })
if ($Path.Count -eq 0) {
    [Console]::Error.WriteLine("ERROR: give a file or folder to read.")
    [Console]::Error.WriteLine("Usage: numbers-extract.ps1 -Path <path>[,path...]")
    exit 1
}

$extensions = @(".tex", ".md", ".markdown", ".qmd", ".rmd", ".txt")
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
            [Console]::Error.WriteLine("ERROR: $p is not a .tex, .md or .txt file.")
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

$out = New-Object System.Collections.Generic.List[string]
$out.Add("NUMBERS EXTRACT: $($Path -join ' ')")
$out.Add("FILES_SCANNED: $($relNames.Count)")
$out.Add("")

$inv = [Globalization.CultureInfo]::InvariantCulture
$abbr = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
foreach ($a in "e.g i.e al fig figs eq eqs sec secs tab vs cf approx no nos vol pp p dr mr ms prof st resp ca ref refs".Split(' ')) { [void]$abbr.Add($a) }

$nums = New-Object System.Collections.Generic.List[object]
$samples = New-Object System.Collections.Generic.List[object]
$pctLines = New-Object System.Collections.Generic.List[string]

$State = @{
    rel = ""; kind = "txt"; inabs = $false; inrefs = $false; intab = $false; infence = $false; yaml = $false; inpre = $false; done = $false
    habs = $false; pnext = ""; pzone = ""; ptext = ""
}
$PL = New-Object System.Collections.Generic.List[int]
$PO = New-Object System.Collections.Generic.List[int]

$refWords = '\\(ref|eqref|cref|autoref|pageref|nameref|label|url|href|includegraphics|input|include|bibliography|bibliographystyle|addbibresource|usepackage|vspace|hspace|setlength|cmidrule|cline|multirow|multicolumn|footnotemark|[a-z]*cite[a-z]*)\*?(\([^)]*\))?(\[[^\]]*\])*\{[^}]*\}'
$crossWords = '(^|[^a-z])(figures?|figs?\.|tables?|tab\.|sections?|sec\.|eqs?\.|equations?|appendix|chapters?|algorithms?|lines?|pages?|pp?\.|steps?|rows?|columns?|items?|stages?|phases?|versions?|v\.)[ ~]*\(?[0-9]+(\.[0-9]+)*[a-z]?\)?([ ]*(-|--|to|and)[ ]*\(?[0-9]+(\.[0-9]+)*[a-z]?\)?)?'

function Get-Clean([string]$t) {
    $c = $t.ToLowerInvariant()
    $c = $c.Replace('\%', '%')
    $c = [regex]::Replace($c, $refWords, ' ')
    $c = [regex]::Replace($c, 'https?://[^ )}>]*', ' ')
    $c = [regex]::Replace($c, '\]\([^)]*\)', '] ')
    $c = [regex]::Replace($c, '@[a-z0-9_][a-z0-9_:./-]*', ' ')
    $c = [regex]::Replace($c, '\[[0-9][0-9 ,;-]*\]', ' ')
    $c = [regex]::Replace($c, $crossWords, ' ')
    $c = [regex]::Replace($c, '[0-9]+(st|nd|rd|th)([^a-z]|$)', ' ')
    $c = [regex]::Replace($c, '\\[a-z]+\*?', ' ')
    $c = [regex]::Replace($c, '\\.', ' ')
    $c = [regex]::Replace($c, '[{}$~]', ' ')
    return $c
}

function Get-Pow10([int]$d) {
    $r = 1.0
    for ($i = 0; $i -lt $d; $i++) { $r *= 10 }
    return $r
}

function Add-Sentence([string]$t, [int]$ln, [string]$zone) {
    $t = [regex]::Replace($t, '[ \t]+', ' ')
    if ($t.StartsWith(' ')) { $t = $t.Substring(1) }
    if ($t.EndsWith(' ')) { $t = $t.Substring(0, $t.Length - 1) }
    if ($t -eq "") { return }
    $c = Get-Clean $t
    $cnt = 0
    $sum = 0.0
    $maxd = 0
    $bad = $false
    $ms = [regex]::Matches($c, '[0-9]+(,[0-9]{3})*(\.[0-9]+)?(e[-+]?[0-9]+)?')
    $skipUntil = -1
    foreach ($m in $ms) {
        $a = $m.Index
        if ($a -lt $skipUntil) { continue }
        $tok = $m.Value
        $after = $a + $m.Length
        $pc = if ($a -ge 1) { [string]$c[$a - 1] } else { "" }
        $ppc = if ($a -ge 2) { [string]$c[$a - 2] } else { "" }
        $neg = $false
        if ($pc -cmatch '[a-z0-9_^]') { continue }
        if ($pc -eq ".") {
            if ($ppc -cmatch '[a-z0-9_]') { continue }
            $tok = "0." + $tok
        } elseif ($pc -eq "-") {
            if ($ppc -cmatch '[a-z]') { continue }
            if ($ppc -cnotmatch '[0-9-]') { $neg = $true }
        }
        $rest = if ($after -lt $c.Length) { $c.Substring($after) } else { "" }
        $pct = $false
        $pm = [regex]::Match($rest, '^ ?%')
        if ($pm.Success) {
            $pct = $true
            $skipUntil = $after + $pm.Length
        } elseif ($rest -cmatch '^ ?(percent|per cent)([^a-z]|$)') {
            $pct = $true
        }
        $tok = $tok.Replace(',', '')
        if ($neg) { $tok = "-" + $tok }
        $dec = 0
        if ($tok.IndexOf('.') -ge 0 -and $tok -cnotmatch 'e') { $dec = $tok.Length - ($tok.IndexOf('.') + 1) }
        $val = if ($pct) { "$tok%" } else { $tok }
        $x = [double]::Parse($tok, $inv)
        $nums.Add(@($zone, $State.rel, $ln, $val, $dec, $x, $t))
        $out.Add("NUM $zone $($State.rel):${ln}: $val | $t")
        if ($pct) {
            $cnt++
            $sum += $x
            if ($dec -gt $maxd) { $maxd = $dec }
            if ($x -lt 0 -or $x -gt 100) { $bad = $true }
        }
    }
    foreach ($m in [regex]::Matches($c, '(^|[^a-z0-9_])n *= *[0-9][0-9,]*')) {
        $v = [regex]::Replace($m.Value, '^[^=]*= *', '').Replace(',', '')
        $samples.Add(@($v, $State.rel, $ln, $t))
    }
    if ($cnt -ge 3 -and -not $bad -and $sum -ge 80 -and $sum -le 120) {
        $tol = $cnt * 0.5 / (Get-Pow10 $maxd)
        if ([Math]::Abs($sum - 100) -gt $tol + 1e-9) {
            $pctLines.Add("PCT_SUM " + $sum.ToString("F$maxd", $inv) + " $($State.rel):${ln}: $t")
        }
    }
}

function Add-Line([string]$line, [int]$ln) {
    if ($PL.Count -eq 0) {
        $State.pzone = if ($State.inabs) { "ABSTRACT" } elseif ($State.pnext -ne "") { $State.pnext } else { "TEXT" }
        $State.pnext = ""
        $PL.Add($ln)
        $PO.Add(0)
        $State.ptext = $line
        return
    }
    $PL.Add($ln)
    $PO.Add($State.ptext.Length + 1)
    $State.ptext = $State.ptext + " " + $line
}

function Get-LineAt([int]$pos) {
    $r = $PL[0]
    for ($k = 0; $k -lt $PL.Count; $k++) { if ($PO[$k] -le $pos) { $r = $PL[$k] } }
    return $r
}

function Invoke-Flush {
    if ($PL.Count -eq 0) { return }
    $p = $State.ptext
    $n = $p.Length
    $s = 0
    $i = 0
    while ($i -lt $n) {
        $c = $p[$i]
        if ($c -ne '.' -and $c -ne '!' -and $c -ne '?') { $i++; continue }
        $nx = if ($i + 1 -lt $n) { $p[$i + 1] } else { [char]0 }
        if ($nx -ne ' ' -and $nx -ne "`t") { $i++; continue }
        $j = $i + 1
        while ($j -lt $n -and ($p[$j] -eq ' ' -or $p[$j] -eq "`t")) { $j++ }
        if ($j -ge $n) { $i++; continue }
        if ([string]$p[$j] -cnotmatch '[A-Z\\]') { $i++; continue }
        if ($c -eq '.') {
            $k = $i - 1
            while ($k -ge 0 -and ([string]$p[$k] -cmatch '[A-Za-z.]')) { $k-- }
            $w = $p.Substring($k + 1, $i - 1 - $k).ToLowerInvariant()
            if ($abbr.Contains($w) -or $w.Length -eq 1) { $i++; continue }
        }
        Add-Sentence $p.Substring($s, $i - $s + 1) (Get-LineAt $s) $State.pzone
        $s = $j
        $i = $j
    }
    if ($s -lt $n) { Add-Sentence $p.Substring($s) (Get-LineAt $s) $State.pzone }
    $PL.Clear()
    $PO.Clear()
    $State.ptext = ""
}

function Add-Unit([string]$line, [int]$ln, [string]$zone) {
    Invoke-Flush
    Add-Sentence $line $ln $zone
}

$tabEnv = '(tabular|tabularx|tabulary|longtable|array)\*?\}'

function Read-TexLine([string]$line, [int]$ln) {
    $line = $line.Replace('\%', [string][char]1)
    $cut = $line.IndexOf('%')
    if ($cut -ge 0) { $line = $line.Substring(0, $cut) }
    $line = $line.Replace([string][char]1, '\%')
    if ($line -cmatch '\\documentclass') {
        $State.inpre = $true
        return
    }
    if ($State.inpre) {
        if ($line -cmatch '\\begin\{document\}') { $State.inpre = $false }
        return
    }
    if ($line -cmatch '\\end\{document\}') {
        Invoke-Flush
        $State.done = $true
        return
    }
    if ($line -cmatch '\\begin\{thebibliography\}') {
        Invoke-Flush
        $State.inrefs = $true
        return
    }
    if ($State.inrefs) {
        if ($line -cmatch '\\end\{thebibliography\}') { $State.inrefs = $false }
        return
    }
    if ($line -cmatch '\\begin\{abstract\}') {
        Invoke-Flush
        $State.inabs = $true
        $State.habs = $true
        $line = [regex]::Replace($line, '.*\\begin\{abstract\}', '')
    }
    $endabs = $false
    if ($State.inabs -and $line -cmatch '\\end\{abstract\}') {
        $line = [regex]::Replace($line, '\\end\{abstract\}.*', '')
        $endabs = $true
    }
    if ($line -cmatch ('\\begin\{' + $tabEnv)) {
        Invoke-Flush
        $State.intab = $true
        return
    }
    if ($State.intab) {
        if ($line -cmatch ('\\end\{' + $tabEnv)) {
            $State.intab = $false
            return
        }
        Add-Unit $line $ln "TABLE"
        return
    }
    if ($line -cmatch '^[ \t]*\\(part|chapter|section|subsection|subsubsection|paragraph|subparagraph)\*?[\[{]') {
        Invoke-Flush
        $State.inabs = $false
        if ($line.ToLowerInvariant() -cmatch '\{[ \t]*abstract[ \t]*\}') {
            $State.inabs = $true
            $State.habs = $true
        }
        return
    }
    if ($line -cmatch '^[ \t]*\\(begin|end)\{') {
        Invoke-Flush
        $line = [regex]::Replace($line, '\\(begin|end)\{[^}]*\}(\[[^\]]*\])?(\{[^}]*\})?', '')
        if ($line -cmatch '^[ \t]*$') {
            if ($endabs) { $State.inabs = $false }
            return
        }
    }
    if ($line -cmatch '^[ \t]*\\item') {
        Invoke-Flush
        $line = [regex]::Replace($line, '^[ \t]*\\item(\[[^\]]*\])?', '')
    }
    if ($line -cmatch '\\caption') {
        Invoke-Flush
        $State.pnext = "CAPTION"
    }
    if ($line -cmatch '^[ \t]*$') {
        Invoke-Flush
        if ($endabs) { $State.inabs = $false }
        return
    }
    Add-Line $line $ln
    if ($endabs) {
        Invoke-Flush
        $State.inabs = $false
    }
}

function Read-PlainLine([string]$line, [int]$ln) {
    $low = $line.ToLowerInvariant()
    if ($State.kind -eq "md" -and $line -cmatch '^ ? ? ?#') {
        Invoke-Flush
        $h = [regex]::Replace($low, '^[ \t]*#+[ \t]*', '')
        $h = [regex]::Replace($h, '[ \t#]+$', '')
        $State.inabs = $false
        $State.inrefs = $false
        if ($h -cmatch '^abstract[:.]?$') {
            $State.inabs = $true
            $State.habs = $true
        } elseif ($h -cmatch '^([0-9.]+[ \t]+)?(references|bibliography|works cited|literature cited)[:.]?$') {
            $State.inrefs = $true
        }
        return
    }
    if ($low -cmatch '^[ \t]*[*_]*abstract[*_]*[ \t]*[:.]?[ \t]*[*_]*[ \t]*$') {
        Invoke-Flush
        $State.inabs = $true
        $State.habs = $true
        $State.inrefs = $false
        return
    }
    if ($low -cmatch '^[ \t]*[*_]*([0-9]+\.?[ \t]+)?(references|bibliography|works cited|literature cited)[*_]*[ \t]*:?[ \t]*$') {
        Invoke-Flush
        $State.inabs = $false
        $State.inrefs = $true
        return
    }
    if ($State.inrefs) {
        if ($low -cmatch '^[ \t]*[*_#]*[ \t]*(appendix|appendices|supplementary)') {
            Invoke-Flush
            $State.inrefs = $false
        } else {
            return
        }
    }
    if ($low -cmatch '^[ \t]*[*_]*abstract[*_]*[^a-z0-9 \t]') {
        Invoke-Flush
        $State.inabs = $true
        $State.habs = $true
        $line = [regex]::Replace($line, '^[ \t]*[*_]*[Aa][Bb][Ss][Tt][Rr][Aa][Cc][Tt][*_]*', '')
        $line = [regex]::Replace($line, '^[^A-Za-z0-9]+', '')
    }
    if ($State.inabs -and $low -cmatch '^[ \t]*[*_#]*[ \t]*(([0-9]+|[ivx]+)\.?[ \t]+)?(introduction|keywords|key words|index terms|background|motivation|overview)([^a-z]|$)') {
        Invoke-Flush
        $State.inabs = $false
    }
    if ($State.kind -eq "md" -and $line -cmatch '^[ \t]*\|') {
        Add-Unit $line $ln "TABLE"
        return
    }
    if ($State.kind -eq "txt" -and $line -cmatch "`t.*`t") {
        Add-Unit $line $ln "TABLE"
        return
    }
    if ($State.kind -eq "txt" -and $line.Length -le 80 -and $line -cmatch '^[ \t]*[0-9]+(\.[0-9]+)*\.?[ \t]+[A-Z][^.!?]*$') {
        Invoke-Flush
        return
    }
    if ($State.kind -eq "md" -and $line -cmatch '^[ \t]*([-*+]|[0-9]+[.)])[ \t]+') {
        Invoke-Flush
        $line = [regex]::Replace($line, '^[ \t]*([-*+]|[0-9]+[.)])[ \t]+', '')
    }
    if ($low -cmatch '^[ \t]*[*_]*(table|figure|fig\.)[ \t]*[0-9]+[a-z]?[*_]*[ \t]*[:.]') {
        Invoke-Flush
        $State.pnext = "CAPTION"
    }
    if ($line -cmatch '^[ \t]*$') {
        Invoke-Flush
        return
    }
    Add-Line $line $ln
}

foreach ($relName in $relNames) {
    Invoke-Flush
    $file = $byRel[$relName]
    $ext = $file.Extension.ToLower()
    $State.rel = $relName
    $State.kind = "txt"
    if ($ext -eq ".tex") { $State.kind = "tex" }
    elseif (@(".md", ".markdown", ".qmd", ".rmd") -contains $ext) { $State.kind = "md" }
    $State.inabs = $false
    $State.inrefs = $false
    $State.intab = $false
    $State.infence = $false
    $State.yaml = $false
    $State.inpre = $false
    $State.done = $false
    $State.pnext = ""
    $content = [System.IO.File]::ReadAllLines($file.FullName, [System.Text.Encoding]::UTF8)
    for ($n = 0; $n -lt $content.Count; $n++) {
        if ($State.done) { break }
        $ln = $n + 1
        $line = $content[$n]
        if ($State.kind -eq "md") {
            if ($ln -eq 1 -and $line -cmatch '^---[ \t]*$') {
                $State.yaml = $true
                continue
            }
            if ($State.yaml) {
                if ($line -cmatch '^(---|\.\.\.)[ \t]*$') { $State.yaml = $false }
                continue
            }
            if ($line -cmatch '^[ \t]*(```|~~~)') {
                Invoke-Flush
                $State.infence = -not $State.infence
                continue
            }
            if ($State.infence) { continue }
        }
        if ($State.kind -eq "tex") { Read-TexLine $line $ln } else { Read-PlainLine $line $ln }
    }
}
Invoke-Flush

$out.Add("")
$nao = 0
$seen = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
foreach ($a in $nums) {
    if ($a[0] -ne "ABSTRACT") { continue }
    if (-not $seen.Add($a[3])) { continue }
    $tol = 0.5 / (Get-Pow10 $a[4]) + 1e-9
    $found = $false
    foreach ($b in $nums) {
        if ($b[0] -eq "ABSTRACT") { continue }
        if ([Math]::Abs($b[5] - $a[5]) -le $tol) {
            $found = $true
            break
        }
    }
    if (-not $found) {
        $nao++
        $out.Add("ABSTRACT_ONLY $($a[3]) $($a[1]):$($a[2]): $($a[6])")
    }
}
$distinct = New-Object System.Collections.Generic.List[string]
foreach ($s in $samples) { if (-not $distinct.Contains($s[0])) { $distinct.Add($s[0]) } }
$nflag = 0
if ($distinct.Count -ge 2) {
    foreach ($s in $samples) {
        $nflag++
        $out.Add("SAMPLE_SIZE $($s[0]) $($s[1]):$($s[2]): $($s[3])")
    }
}
foreach ($l in $pctLines) { $out.Add($l) }
$out.Add("")
$out.Add("NUMBERS: $($nums.Count)")
$out.Add("ABSTRACT: " + $(if ($State.habs) { "found" } else { "not found" }))
$out.Add("SAMPLE_SIZES: " + $(if ($distinct.Count -eq 0) { "none" } else { $distinct -join ' ' }))
$out.Add("ABSTRACT_ONLY: $nao")
$out.Add("SAMPLE_SIZE: $nflag")
$out.Add("PCT_SUM: $($pctLines.Count)")
$out.Add("FLAGS: $($nao + $nflag + $pctLines.Count)")
$out.Add("")
$out.Add("Each flag is a lead. Read the sentence in context before you report it.")
foreach ($l in $out) { Write-Output $l }
