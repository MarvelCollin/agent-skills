param(
    [Parameter(Mandatory=$true, Position=0, ValueFromRemainingArguments=$true)][string[]]$Path
)

$Path = @($Path | ForEach-Object { $_ -split ',' } | Where-Object { $_ -ne "" })

$excludedDirs = @("node_modules", ".git", "vendor", "dist", "build", ".venv", "venv")
$files = New-Object System.Collections.Generic.List[string]
$root = $null

foreach ($target in $Path) {
    if (-not (Test-Path -LiteralPath $target)) {
        [Console]::Error.WriteLine("ERROR: $target does not exist.")
        exit 1
    }
    $full = (Resolve-Path -LiteralPath $target).Path
    $isDir = Test-Path -LiteralPath $full -PathType Container
    if (-not $root) {
        $root = if ($isDir) { $full.TrimEnd('\', '/') } else { Split-Path -Parent $full }
    }
    if ($isDir) {
        $base = $full.TrimEnd('\', '/')
        $found = @(Get-ChildItem -LiteralPath $full -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object {
            $relative = $_.FullName.Substring($base.Length) -replace '\\', '/'
            $segments = @($relative.TrimStart('/') -split '/')
            $dirs = if ($segments.Count -gt 1) { $segments[0..($segments.Count - 2)] } else { @() }
            ($_.Extension -eq ".sql" -or $_.Extension -eq ".prisma") -and -not ($dirs | Where-Object { $excludedDirs -contains $_ })
        } | Sort-Object { $_.FullName } -Culture ([System.Globalization.CultureInfo]::InvariantCulture))
        foreach ($f in $found) { $files.Add($f.FullName) }
    } else {
        $files.Add($full)
    }
}

$results = New-Object System.Collections.Generic.List[string]
$money = '(price|amount|balance|cost|subtotal|fee|salary|total)'

function Get-Rel([string]$File) {
    if ($File.StartsWith($root + '\') -or $File.StartsWith($root + '/')) { return ($File.Substring($root.Length + 1) -replace '\\', '/') }
    return ($File -replace '\\', '/')
}
function Emit([string]$Rule, [string]$Check, [string]$File, [int]$Line, [string]$Text) {
    $t = $Text.Trim(" ", "`t")
    if ($t.Length -gt 120) { $t = $t.Substring(0, 120) }
    $results.Add("$Rule $Check $(Get-Rel $File):${Line}: $t")
}
function Norm([string]$X) {
    $x = $X -replace '"', ''
    $x = $x -replace '^.*\.', ''
    return $x.ToLowerInvariant()
}
function Lead([string]$S) {
    $s = $S -replace '^[^(]*\(', ''
    $s = $s -replace '[,)].*$', ''
    $s = $s.Trim(" ", "`t")
    $s = $s -replace '[ \t].*$', ''
    return (Norm $s)
}

$idx = @{}
$haspk = @{}
$nopk = [ordered]@{}
$created = @{}
$fkSeen = @{}
$fks = New-Object System.Collections.Generic.List[object]
$hasTx = @{}
$hasLt = @{}
$firstAlter = [ordered]@{}

function Add-Fk([string]$Table, [string]$Col, [string]$File, [int]$Line, [string]$Text) {
    $key = "$Table|$Col"
    if ($fkSeen.ContainsKey($key)) { return }
    $fkSeen[$key] = $true
    $fks.Add([pscustomobject]@{ Key = $key; File = $File; Line = $Line; Text = $Text })
}

function Check-ColType([string]$File, [int]$Line, [string]$Text, [string]$Name, [string]$Rest) {
    if ($Name -match $money -and $Rest -match '^(float|double precision|real|money)([^a-z]|$)') { Emit "B14" "float-money" $File $Line $Text }
    if ($Rest -match '^timestamp([ \t]*\([0-9]+\))?([ \t]+without[ \t]+time[ \t]+zone)?([^a-z]|$)' -and $Rest -notmatch '^timestamp([ \t]*\([0-9]+\))?[ \t]+with[ \t]+time') { Emit "B14" "timestamp-without-tz" $File $Line $Text }
    if ($Rest -match '^json([^b]|$)') { Emit "B6" "json-not-jsonb" $File $Line $Text }
    if ($Rest -match '^(char|character)[ \t]*\(') { Emit "B6" "char-column" $File $Line $Text }
    if ($Rest -match '^uuid' -and $Rest -match 'primary[ \t]+key' -and $Rest -match 'default[ \t]+(gen_random_uuid|uuid_generate_v4)') { Emit "B14" "random-uuid-key" $File $Line $Text }
}

$state = @{ Table = ""; Depth = 0; InTable = $false; TLine = 0; TText = "" }

function Process-Element([string]$File, [int]$Line, [string]$El, [string]$Text) {
    $low = $El.Trim(" ", "`t").ToLowerInvariant()
    if ($low -eq "") { return }
    $table = $state.Table
    if ($low -match '^constraint[ \t]') { $low = $low -replace '^constraint[ \t]+[^ \t]+[ \t]+', '' }
    if ($low -match '^primary[ \t]+key') { $haspk[$table] = $true; $idx["$table|$(Lead $low)"] = $true; return }
    if ($low -match '^unique[ \t]*\(') { $idx["$table|$(Lead $low)"] = $true; return }
    if ($low -match '^foreign[ \t]+key') { Add-Fk $table (Lead $low) $File $Line $Text; return }
    if ($low -match '^(check|exclude|like)([ \t(]|$)') { return }
    if ($low -notmatch '[ \t]') { return }
    $name = Norm ($low -replace '[ \t].*$', '')
    $rest = $low -replace '^[^ \t]+[ \t]+', ''
    if ($rest -match 'primary[ \t]+key') { $haspk[$table] = $true; $idx["$table|$name"] = $true }
    if ($rest -match '(^|[ \t])unique([ \t,]|$)') { $idx["$table|$name"] = $true }
    if ($rest -match '(^|[ \t])references[ \t]') { Add-Fk $table $name $File $Line $Text }
    Check-ColType $File $Line $Text $name $rest
}

function Process-Chunk([string]$File, [int]$Line, [string]$S, [string]$Text) {
    $buf = New-Object System.Text.StringBuilder
    foreach ($c in $S.ToCharArray()) {
        if ($c -eq '(') {
            $state.Depth++
            if ($state.Depth -eq 1) { continue }
        } elseif ($c -eq ')') {
            $state.Depth--
            if ($state.Depth -eq 0) {
                Process-Element $File $Line $buf.ToString() $Text
                $t = $state.Table
                if (-not $haspk.ContainsKey($t) -and -not $nopk.Contains($t)) {
                    $nopk[$t] = [pscustomobject]@{ File = $File; Line = $state.TLine; Text = $state.TText }
                }
                $state.InTable = $false
                return
            }
        } elseif ($c -eq ',' -and $state.Depth -eq 1) {
            Process-Element $File $Line $buf.ToString() $Text
            [void]$buf.Clear()
            continue
        }
        if ($state.Depth -ge 1) { [void]$buf.Append($c) }
    }
    if ($buf.Length -gt 0) { Process-Element $File $Line $buf.ToString() $Text }
}

function Flush-Statement([string]$File, [string]$Stmt, [int]$SLine, [string]$SText) {
    $s = (($Stmt.ToLowerInvariant()) -replace '[ \t]+', ' ').Trim()
    if ($s -eq "") { return }
    if ($s -match '^(begin|start transaction)( |$)') { $hasTx[$File] = $true }
    if ($s -match 'lock_timeout') { $hasLt[$File] = $true }
    if ($s -match '^create (unique )?index ') {
        $after = $s -replace '^.* on (only )?', ''
        $tbl = Norm ($after -replace '[ (].*$', '')
        $idx["$tbl|$(Lead $after)"] = $true
        if ($s -match '^create (unique )?index concurrently') {
            if ($hasTx.ContainsKey($File)) { Emit "B6" "concurrent-in-transaction" $File $SLine $SText }
        } elseif (-not $created.ContainsKey("$File|$tbl")) {
            Emit "B6" "index-not-concurrent" $File $SLine $SText
        }
        return
    }
    if ($s -match '^alter table ') {
        $tbl = $s -replace '^alter table (if exists )?(only )?', ''
        $tbl = Norm ($tbl -replace ' .*$', '')
        if (-not $firstAlter.Contains($File)) { $firstAlter[$File] = [pscustomobject]@{ Line = $SLine; Text = $SText } }
        if ($s -match ' add (constraint [^ ]+ )?primary key') { $haspk[$tbl] = $true }
        if ($s -match ' add (constraint [^ ]+ )?(primary key|unique)' -and $s -notmatch ' using index') { Emit "B6" "unique-under-lock" $File $SLine $SText }
        if ($s -match ' add (constraint [^ ]+ )?(foreign key|check)' -and $s -notmatch 'not valid') { Emit "B6" "constraint-validates-under-lock" $File $SLine $SText }
        $m = [regex]::Match($s, ' add (constraint [^ ]+ )?foreign key')
        if ($m.Success) { Add-Fk $tbl (Lead $s.Substring($m.Index)) $File $SLine $SText }
        if ($s -match ' alter (column )?[^ ]+ set not null') { Emit "B6" "set-not-null" $File $SLine $SText }
        if ($s -match ' alter (column )?[^ ]+ (set data )?type ') { Emit "B6" "column-type-change" $File $SLine $SText }
        if ($s -match ' rename (to|column) | rename [^ ]+ to ') { Emit "B6" "rename" $File $SLine $SText }
        if ($s -match ' drop column ') { Emit "B6" "drop" $File $SLine $SText }
        $m = [regex]::Match($s, ' add (column )?(if not exists )?')
        if ($m.Success) {
            $after = $s.Substring($m.Index + $m.Length)
            if ($after -notmatch '^(constraint|primary|unique|foreign|check|exclude) ') {
                $name = $after -replace ' .*$', ''
                $rest = $after -replace '^[^ ]+ ?', ''
                if ($rest -match 'not null' -and $rest -notmatch 'default ') { Emit "B6" "not-null-without-default" $File $SLine $SText }
                if ($rest -match 'default (gen_random_uuid|uuid_generate_v[14]|random|clock_timestamp|timeofday|nextval)') { Emit "B6" "volatile-default" $File $SLine $SText }
                Check-ColType $File $SLine $SText (Norm $name) $rest
            }
        }
        return
    }
    if ($s -match '^drop table ') { Emit "B6" "drop" $File $SLine $SText }
    if ($s -match '^(update|delete from) ' -and $s -notmatch ' where ') { Emit "B6" "unbatched-write" $File $SLine $SText }
    if ($s -match '^(vacuum full|cluster|lock|reindex)( |$)' -and $s -notmatch 'concurrently') { Emit "B6" "heavy-lock" $File $SLine $SText }
}

function Lint-Prisma([string]$File, [string[]]$Lines) {
    $pg = $false
    $inModel = $false
    $model = ""
    $pidx = @{}
    $pfk = New-Object System.Collections.Generic.List[object]
    for ($i = 0; $i -lt $Lines.Length; $i++) {
        $n = $i + 1
        $line = $Lines[$i].TrimEnd("`r")
        $code = $line -replace '//.*$', ''
        if ($code -match 'provider[ \t]*=[ \t]*"(postgresql|postgres)"') { $pg = $true }
        if ($code -match '^[ \t]*model[ \t]+[A-Za-z0-9_]+[ \t]*\{') {
            $inModel = $true
            $model = ($code -replace '^[ \t]*model[ \t]+', '') -replace '[ \t{].*$', ''
            $pfk.Clear()
            continue
        }
        if (-not $inModel) { continue }
        if ($code -match '^[ \t]*\}') {
            foreach ($f in $pfk) {
                if (-not $pidx.ContainsKey("$model|$($f.Col)")) { Emit "B6" "fk-without-index" $File $f.Line $f.Text }
            }
            $inModel = $false
            continue
        }
        $t = $code.Trim(" ", "`t")
        if ($t -eq "") { continue }
        if ($t -cmatch '^@@(index|unique|id)[ \t]*\(') {
            $c = ($t -replace '^[^\[]*\[', '') -replace '[,\] (].*$', ''
            $pidx["$model|$c"] = $true
            continue
        }
        $fname = $t -replace '[ \t].*$', ''
        $ftype = ($t -replace '^[^ \t]+[ \t]+', '') -replace '[ \t].*$', ''
        if ($t -cmatch '@id([^A-Za-z]|$)' -or $t -cmatch '@unique') { $pidx["$model|$fname"] = $true }
        if ($t -cmatch '@relation\(' -and $t -cmatch 'fields:[ \t]*\[') {
            $c = ($t -replace '^.*fields:[ \t]*\[', '') -replace '[,\] ].*$', ''
            $pfk.Add([pscustomobject]@{ Col = $c; Line = $n; Text = $line })
        }
        if ($fname.ToLowerInvariant() -match $money -and $ftype -cmatch '^Float\??$') { Emit "B14" "float-money" $File $n $line }
        if ($pg -and $ftype -cmatch '^DateTime\??$' -and $t -cnotmatch '@db\.Timestamptz') { Emit "B14" "timestamp-without-tz" $File $n $line }
        if ($t -cmatch '@id' -and $t -cmatch '@default\(uuid\((4)?\)\)') { Emit "B14" "random-uuid-key" $File $n $line }
    }
}

$createRe = '^[ \t]*create[ \t]+((global|local)[ \t]+)?((temp|temporary|unlogged)[ \t]+)?table[ \t]+(if[ \t]+not[ \t]+exists[ \t]+)?'

foreach ($file in $files) {
    $lines = [System.IO.File]::ReadAllLines($file)
    if ($file.EndsWith(".prisma")) { Lint-Prisma $file $lines; continue }
    $state.InTable = $false
    $state.Depth = 0
    $inDollar = $false
    $stmt = ""
    $sLine = 0
    $sText = ""
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $n = $i + 1
        $line = $lines[$i].TrimEnd("`r")
        $code = $line -replace '--.*$', ''
        if ($state.InTable) {
            Process-Chunk $file $n $code $line
        } else {
            $m = [regex]::Match($code, $createRe, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            if ($m.Success) {
                $rest = $code.Substring($m.Index + $m.Length)
                $rawTable = $rest -replace '[ \t(].*$', ''
                $state.Table = Norm $rawTable
                $created["$file|$($state.Table)"] = $true
                if ($rest.ToLowerInvariant() -notmatch 'partition[ \t]+of|[ \t]as[ \t]') {
                    $state.InTable = $true
                    $state.Depth = 0
                    $state.TLine = $n
                    $state.TText = $line
                    Process-Chunk $file $n $rest.Substring($rawTable.Length) $line
                }
            }
        }
        if ($inDollar -or $code -match '\$[A-Za-z_]*\$') {
            if ($stmt.Trim() -eq "") { $sLine = $n; $sText = $line }
            $stmt = "$stmt $code"
            $count = ([regex]::Matches($code, '\$[A-Za-z_]*\$')).Count
            if ($count % 2 -eq 1) { $inDollar = -not $inDollar }
            if (-not $inDollar -and $code -match ';[ \t]*$') { Flush-Statement $file $stmt $sLine $sText; $stmt = "" }
            continue
        }
        $parts = $code -split ';', -1
        for ($k = 0; $k -lt $parts.Length; $k++) {
            if ($parts[$k].Trim(" ", "`t") -ne "") {
                if ($stmt.Trim() -eq "") { $sLine = $n; $sText = $line }
                $stmt = "$stmt $($parts[$k])"
            }
            if ($k -lt $parts.Length - 1) { Flush-Statement $file $stmt $sLine $sText; $stmt = "" }
        }
    }
    if ($stmt.Trim() -ne "") { Flush-Statement $file $stmt $sLine $sText }
}

foreach ($f in $fks) {
    if (-not $idx.ContainsKey($f.Key)) { Emit "B6" "fk-without-index" $f.File $f.Line $f.Text }
}
foreach ($t in $nopk.Keys) {
    if (-not $haspk.ContainsKey($t)) { Emit "B6" "missing-primary-key" $nopk[$t].File $nopk[$t].Line $nopk[$t].Text }
}
foreach ($f in $firstAlter.Keys) {
    if (-not $hasLt.ContainsKey($f)) { Emit "B6" "no-lock-timeout" $f $firstAlter[$f].Line $firstAlter[$f].Text }
}

Write-Output "DB LINT: $($Path -join ' ')"
Write-Output "FILES_SCANNED: $($files.Count)"
Write-Output ""
$results | Sort-Object @{ Expression = { [int]($_.Split(' ')[0].Substring(1)) } }, @{ Expression = { $_.Split(' ')[1] } }, @{ Expression = { $_.Split(' ')[2] } } | ForEach-Object { Write-Output $_ }
Write-Output ""
Write-Output "FINDINGS: $($results.Count)"
foreach ($rule in @("B6", "B14")) {
    $count = @($results | Where-Object { $_.StartsWith("$rule ") }).Count
    Write-Output "${rule}: $count"
}
Write-Output ""
Write-Output "Each line is a lead, not a confirmed finding. Read it in context before reporting."
