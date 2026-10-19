param(
    [Parameter(Position=0)][string]$Path,
    [string]$Profile,
    [string]$Seen,
    [switch]$Record,
    [string]$Min
)

function Show-Usage { [Console]::Error.WriteLine("Usage: job-score.ps1 -Path <jobs.tsv> [-Profile <file>] [-Seen <file>] [-Record] [-Min <score>]") }

$homeDir = if ($env:UPWORK_JOBS_HOME) { $env:UPWORK_JOBS_HOME } else { Join-Path $HOME ".upwork-jobs" }
if (-not $Profile) { $Profile = Join-Path $homeDir "profile.conf" }

if (-not $Path) {
    [Console]::Error.WriteLine("ERROR: give a jobs TSV file.")
    Show-Usage
    exit 1
}
if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    [Console]::Error.WriteLine("ERROR: $Path does not exist.")
    exit 1
}
if (-not (Test-Path -LiteralPath $Profile -PathType Leaf)) {
    [Console]::Error.WriteLine("ERROR: profile $Profile does not exist. Copy templates/profile.conf there and edit it.")
    exit 1
}
if ($Min -and $Min -notmatch '^[0-9]+$') {
    [Console]::Error.WriteLine("ERROR: --min must be a whole number.")
    exit 1
}
if ($Record -and -not $Seen) { $Seen = Join-Path $homeDir "seen.txt" }

function Trim-Value([string]$s) { if ($null -eq $s) { return "" } return ($s -replace "`r", "").Trim(" ", "`t") }
function To-Num([string]$s) {
    $s = (Trim-Value $s) -replace '[$,%+]', ''
    if ($s -match '^[0-9]+(\.[0-9]+)?$') { return [double]$s }
    return -1
}
function Has-Term([string]$hay, [string]$term) {
    $n = $term.Length
    if ($n -eq 0) { return $false }
    $start = 0
    while (($pos = $hay.IndexOf($term, $start, [StringComparison]::Ordinal)) -ge 0) {
        $before = if ($pos -gt 0) { $hay[$pos - 1] } else { ' ' }
        $after = if ($pos + $n -lt $hay.Length) { $hay[$pos + $n] } else { ' ' }
        if ("$before" -notmatch '[a-z0-9]' -and "$after" -notmatch '[a-z0-9]') { return $true }
        $start = $pos + 1
    }
    return $false
}
function Split-List([string]$s) {
    if (-not $s) { return @() }
    return @($s.ToLower() -split ',' | ForEach-Object { Trim-Value $_ } | Where-Object { $_ -ne "" })
}
function Add-Flag([string]$flags, [string]$flag) { if ($flags) { return "$flags,$flag" } return $flag }

$seenSet = @{}
if ($Seen -and (Test-Path -LiteralPath $Seen -PathType Leaf)) {
    foreach ($line in [IO.File]::ReadAllLines($Seen)) {
        $t = Trim-Value $line
        if ($t) { $seenSet[$t] = $true }
    }
}

$p = @{ rate = "15"; min_hourly = "10"; min_fixed = "50"; require_verified = "yes"; min_score = "55" }
foreach ($line in [IO.File]::ReadAllLines($Profile)) {
    $l = $line -replace "`r", ""
    if ($l -match '^[ \t]*#' -or $l -notmatch '=') { continue }
    $eq = $l.IndexOf('=')
    $p[(Trim-Value $l.Substring(0, $eq))] = Trim-Value $l.Substring($eq + 1)
}

$scam = "telegram,whatsapp,outside upwork,outside of upwork,off upwork,off platform,off-platform,registration fee,training fee,upfront payment,pay to start,security deposit,crypto wallet" -split ','
$tz = "us only,u.s. only,us based only,us-based only,must be in the us,est hours,pst hours,est time zone,pst time zone,us business hours,us working hours,us/uk business hours,uk business hours,overlap with us,overlap with est,overlap with pst,us central time,us eastern time,us pacific time,uk only,europe only,eu only" -split ','
$ft = "full-time,full time,40 hours,40 hrs,40+ hours,40 hours per week" -split ','

$core = Split-List $p["core"]
$sec = Split-List $p["secondary"]
$avoid = Split-List $p["avoid"]
$minScore = if ($Min) { [int]$Min } else { [int](To-Num $p["min_score"]) }
$rate = To-Num $p["rate"]
$minHourly = To-Num $p["min_hourly"]
$minFixed = To-Num $p["min_fixed"]

$lines = [IO.File]::ReadAllLines((Resolve-Path -LiteralPath $Path).Path)
$cidx = @{}
$rows = New-Object System.Collections.Generic.List[object]
$ids = New-Object System.Collections.Generic.List[string]
$batch = @{}
$skipCount = @{}
$total = 0; $shortlist = 0; $low = 0
$header = $false

foreach ($raw in $lines) {
    $cells = ($raw -replace "`r", "") -split "`t"
    if (-not $header) {
        for ($i = 0; $i -lt $cells.Count; $i++) { $cidx[(Trim-Value $cells[$i]).ToLower()] = $i }
        $header = $true
        continue
    }
    if ((Trim-Value $raw) -eq "") { continue }
    $col = { param($name) if ($cidx.ContainsKey($name) -and $cidx[$name] -lt $cells.Count) { Trim-Value $cells[$cidx[$name]] } else { "" } }
    $id = & $col "id"; $title = & $col "title"; $url = & $col "url"
    if (-not $id) { $id = $url }
    $total++
    if ($seenSet.ContainsKey($id)) {
        $skipCount["seen"] = 1 + [int]$skipCount["seen"]
        $rows.Add([pscustomobject]@{ G = 3; K = 0; Id = $id; Line = "SKIP $id seen | $title" })
        continue
    }
    if ($batch.ContainsKey($id)) {
        $skipCount["duplicate"] = 1 + [int]$skipCount["duplicate"]
        $rows.Add([pscustomobject]@{ G = 3; K = 0; Id = $id; Line = "SKIP $id duplicate | $title" })
        continue
    }
    $batch[$id] = $true
    $ids.Add($id)

    $lt = " " + $title.ToLower() + " "
    $ls = " " + (& $col "skills").ToLower() + " "
    $lx = " " + (& $col "text").ToLower() + " "
    $all = "$lt $ls $lx"

    $reason = ""; $flags = ""; $penalty = 0

    $matched = New-Object System.Collections.Generic.List[object]
    $terms = @($core | ForEach-Object { [pscustomobject]@{ T = $_; Core = $true } }) + @($sec | ForEach-Object { [pscustomobject]@{ T = $_; Core = $false } })
    foreach ($term in $terms) {
        $t = $term.T
        if ((Has-Term $lt $t) -or (Has-Term $ls $t) -or ($t.Length -ge 4 -and (Has-Term $lx $t))) { $matched.Add($term) }
    }
    $coreHits = 0; $secHits = 0; $stack = ""
    for ($i = 0; $i -lt $matched.Count; $i++) {
        $covered = $false
        for ($j = 0; $j -lt $matched.Count; $j++) {
            if ($j -ne $i -and $matched[$j].T.Length -gt $matched[$i].T.Length -and $matched[$j].T.Contains($matched[$i].T)) { $covered = $true; break }
        }
        if ($covered) { continue }
        if ($matched[$i].Core) { $coreHits++ } else { $secHits++ }
        $stack = Add-Flag $stack $matched[$i].T
    }
    $avoidHit = ""
    foreach ($a in $avoid) { if ((Has-Term $lt $a) -or (Has-Term $ls $a)) { $avoidHit = $a; break } }

    foreach ($s in $scam) { if (Has-Term $all $s) { $reason = "scam:$s"; break } }
    $workload = (& $col "workload").ToLower()
    $verified = & $col "payment_verified"
    $type = (& $col "type").ToLower()
    $rmin = To-Num (& $col "rate_min"); $rmax = To-Num (& $col "rate_max"); $budget = To-Num (& $col "budget")
    $hourly = if ($rmax -gt 0) { $rmax } else { $rmin }

    if (-not $reason -and $lx.Contains("only freelancers located in") -and -not (Has-Term $lx "indonesia") -and -not (Has-Term $lx "asia")) { $reason = "region-lock" }
    if (-not $reason -and $workload -eq "full" -and "$($p['full_time_ok'])".ToLower() -ne "yes") { $reason = "full-time" }
    if (-not $reason -and "$($p['require_verified'])".ToLower() -eq "yes" -and $verified -eq "0") { $reason = "unverified" }
    if (-not $reason -and ($coreHits + $secHits) -eq 0) { $reason = "no-stack-match" }
    if (-not $reason -and $avoidHit -and $coreHits -eq 0) { $reason = "avoid:$avoidHit" }
    if (-not $reason -and $type -eq "hourly" -and $hourly -gt 0 -and $hourly -lt $minHourly) { $reason = "low-pay" }
    if (-not $reason -and $type -eq "fixed" -and $budget -gt 0 -and $budget -lt $minFixed) { $reason = "low-pay" }

    if ($reason) {
        $bucket = if ($reason -like "scam:*") { "scam" } elseif ($reason -like "avoid:*") { "avoid" } else { $reason }
        $skipCount[$bucket] = 1 + [int]$skipCount[$bucket]
        $rows.Add([pscustomobject]@{ G = 3; K = 0; Id = $id; Line = "SKIP $id $reason | $title" })
        continue
    }

    $sStack = [Math]::Min(40, $coreHits * 12 + $secHits * 5)

    if ($type -eq "fixed") {
        $sPay = if ($budget -ge 500) { 15 } elseif ($budget -ge 150) { 11 } elseif ($budget -gt 0) { 6 } else { 5 }
        $payTxt = "fixed " + $(if ($budget -gt 0) { "`$$budget" } else { "?" })
    } else {
        $sPay = if ($hourly -ge $rate) { 15 } elseif ($hourly -gt 0) { 8 } else { 7 }
        $payTxt = "hourly " + $(if ($rmin -gt 0) { "$rmin" } else { "?" }) + "-" + $(if ($rmax -gt 0) { "$rmax" } else { "?" })
    }

    $spent = To-Num (& $col "client_spent"); $hire = To-Num (& $col "hire_rate"); $rating = To-Num (& $col "client_rating")
    $sClient = if ($verified -eq "1") { 4 } elseif ($verified -eq "0") { 0 } else { 2 }
    $sClient += if ($spent -ge 10000) { 8 } elseif ($spent -ge 1000) { 6 } elseif ($spent -gt 0) { 3 } else { 1 }
    $sClient += if ($hire -ge 50) { 5 } elseif ($hire -ge 20) { 3 } elseif ($hire -gt 0) { 1 } else { 0 }
    $sClient += if ($rating -ge 4.5) { 3 } elseif ($rating -ge 4) { 2 } elseif ($rating -le 0) { 1 } else { 0 }

    $props = To-Num (& $col "proposals"); $posted = To-Num (& $col "posted_hours")
    $sComp = if ($props -lt 0) { 4 } elseif ($props -lt 5) { 10 } elseif ($props -lt 10) { 7 } elseif ($props -lt 15) { 4 } elseif ($props -lt 20) { 2 } else { 0 }
    $sComp += if ($posted -lt 0) { 1 } elseif ($posted -le 6) { 5 } elseif ($posted -le 24) { 3 } elseif ($posted -le 72) { 1 } else { 0 }

    $level = (& $col "level").ToLower()
    $sLevel = switch ($level) { "entry" { 10 } "intermediate" { 8 } "expert" { 4 } default { 5 } }

    foreach ($z in $tz) { if (Has-Term $lx $z) { $flags = Add-Flag $flags "timezone:$z"; $penalty += 10; break } }
    if ($workload -ne "part") { foreach ($f in $ft) { if (Has-Term $lx $f) { $flags = Add-Flag $flags "full-time-wording"; $penalty += 10; break } } }
    if ($avoidHit) { $flags = Add-Flag $flags "avoid:$avoidHit"; $penalty += 15 }
    if ($verified -ne "1" -and $verified -ne "0") { $flags = Add-Flag $flags "payment-unknown" }
    $connects = To-Num (& $col "connects")
    if ($connects -ge 16) { $flags = Add-Flag $flags "connects:$connects" }

    $score = [Math]::Max(0, [Math]::Min(100, $sStack + $sPay + $sClient + $sComp + $sLevel - $penalty))
    $tag = if ($score -ge $minScore) { "JOB" } else { "LOW" }
    if ($tag -eq "JOB") { $shortlist++ } else { $low++ }
    $propTxt = if ($props -lt 0) { "?" } else { "$props" }
    $postTxt = if ($posted -lt 0) { "?" } else { "${posted}h" }
    $flagTxt = if ($flags) { $flags } else { "none" }
    $line = "$tag $score $id | $title | stack $stack | $payTxt | proposals $propTxt | posted $postTxt | parts stack $sStack pay $sPay client $sClient comp $sComp level $sLevel | flags $flagTxt | $url"
    $rows.Add([pscustomobject]@{ G = $(if ($tag -eq "JOB") { 1 } else { 2 }); K = 100 - $score; Id = $id; Line = $line })
}

$out = New-Object System.Collections.Generic.List[string]
$out.Add("UPWORK JOB SCORE: $Path")
$out.Add("PROFILE: $Profile")
$sorted = [System.Linq.Enumerable]::ToArray([System.Linq.Enumerable]::ThenBy(
    [System.Linq.Enumerable]::ThenBy(
        [System.Linq.Enumerable]::OrderBy([object[]]$rows.ToArray(), [Func[object,int]]{ param($r) $r.G }),
        [Func[object,int]]{ param($r) $r.K }),
    [Func[object,string]]{ param($r) $r.Id }, [StringComparer]::Ordinal))
foreach ($r in $sorted) { $out.Add($r.Line) }
$skipped = 0
foreach ($v in $skipCount.Values) { $skipped += $v }
$out.Add("JOBS: $total")
$out.Add("SHORTLIST: $shortlist")
$out.Add("LOW: $low")
$out.Add("SKIPPED: $skipped")
$out.Add("MIN_SCORE: $minScore")
foreach ($k in "seen,duplicate,scam,region-lock,full-time,unverified,no-stack-match,avoid,low-pay" -split ',') {
    $out.Add("SKIP_$($k.ToUpper()): $([int]$skipCount[$k])")
}
if ($Record -and $ids.Count -gt 0) {
    $dir = Split-Path -Parent $Seen
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [IO.File]::AppendAllText($Seen, (($ids -join "`n") + "`n"))
    $out.Add("RECORDED: $($ids.Count) to $Seen")
}
$out | ForEach-Object { Write-Output $_ }
exit 0
