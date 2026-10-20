param(
    [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)][string[]]$Colors
)

$list = @($Colors | ForEach-Object { $_ -split '[\s,]+' } | Where-Object { $_ -ne "" })
if ($list.Count -lt 2) {
    [Console]::Error.WriteLine("ERROR: Usage: palette-check.ps1 <hex> <hex> [hex ...]")
    exit 1
}
$hexes = @()
foreach ($arg in $list) {
    $hex = $arg.Replace("#", "").ToLower()
    if ($hex -notmatch '^[0-9a-f]{6}$') {
        [Console]::Error.WriteLine("ERROR: $arg is not a six digit hex color.")
        exit 1
    }
    $hexes += $hex
}

$inv = [System.Globalization.CultureInfo]::InvariantCulture
function Fmt([string]$Format, [object[]]$Values) { return [string]::Format($inv, $Format, $Values) }
function Lin([double]$c) { if ($c -le 0.04045) { return $c / 12.92 } return [Math]::Pow(($c + 0.055) / 1.055, 2.4) }
function Cbrt([double]$x) { if ($x -le 0) { return 0.0 } return [Math]::Exp([Math]::Log($x) / 3) }
function Clamp([double]$x) { if ($x -lt 0) { return 0.0 } if ($x -gt 1) { return 1.0 } return $x }
function Srgb([string]$h) {
    return @(([Convert]::ToInt32($h.Substring(0, 2), 16) / 255.0), ([Convert]::ToInt32($h.Substring(2, 2), 16) / 255.0), ([Convert]::ToInt32($h.Substring(4, 2), 16) / 255.0))
}
function Linear([string]$h) { $s = Srgb $h; return @((Lin $s[0]), (Lin $s[1]), (Lin $s[2])) }
function OkLab([double]$r, [double]$g, [double]$b) {
    $l = Cbrt (0.4122214708 * $r + 0.5363325363 * $g + 0.0514459929 * $b)
    $m = Cbrt (0.2119034982 * $r + 0.6806995451 * $g + 0.1073969566 * $b)
    $s = Cbrt (0.0883024619 * $r + 0.2817188376 * $g + 0.6299787005 * $b)
    return @(
        (0.2104542553 * $l + 0.7936177850 * $m - 0.0040720468 * $s),
        (1.9779984951 * $l - 2.4285922050 * $m + 0.4505937099 * $s),
        (0.0259040371 * $l + 0.7827717662 * $m - 0.8086757660 * $s)
    )
}
function Lum([string]$h) { $v = Linear $h; return 0.2126 * $v[0] + 0.7152 * $v[1] + 0.0722 * $v[2] }
function Ratio([string]$a, [string]$b) {
    $x = Lum $a; $y = Lum $b
    if ($y -gt $x) { $t = $x; $x = $y; $y = $t }
    return ($x + 0.05) / ($y + 0.05)
}
function ApcaY([string]$h) {
    $s = Srgb $h
    $y = 0.2126729 * [Math]::Pow($s[0], 2.4) + 0.7151522 * [Math]::Pow($s[1], 2.4) + 0.0721750 * [Math]::Pow($s[2], 2.4)
    if ($y -lt 0.022) { $y += [Math]::Pow(0.022 - $y, 1.414) }
    return $y
}
function Apca([string]$text, [string]$bg) {
    $yt = ApcaY $text; $yb = ApcaY $bg
    if ([Math]::Abs($yb - $yt) -lt 0.0005) { return 0.0 }
    if ($yb -gt $yt) {
        $s = ([Math]::Pow($yb, 0.56) - [Math]::Pow($yt, 0.57)) * 1.14
        if ($s -lt 0.1) { return 0.0 }
        return ($s - 0.027) * 100
    }
    $s = ([Math]::Pow($yb, 0.65) - [Math]::Pow($yt, 0.62)) * 1.14
    if ($s -gt -0.1) { return 0.0 }
    return ($s + 0.027) * 100
}
$matrices = @{
    "protanopia" = @(@(0.152286, 1.052583, -0.204868), @(0.114503, 0.786281, 0.099216), @(-0.003882, -0.048116, 1.051998))
    "deuteranopia" = @(@(0.367322, 0.860646, -0.227968), @(0.280085, 0.672501, 0.047413), @(-0.011820, 0.042940, 0.968881))
    "tritanopia" = @(@(1.255528, -0.076749, -0.178779), @(-0.078411, 0.930809, 0.147602), @(0.004733, 0.691367, 0.303900))
}
function Sim([string]$h, [string]$kind) {
    $v = Linear $h
    if ($matrices.ContainsKey($kind)) {
        $m = $matrices[$kind]
        $v = @(
            (Clamp ($m[0][0] * $v[0] + $m[0][1] * $v[1] + $m[0][2] * $v[2])),
            (Clamp ($m[1][0] * $v[0] + $m[1][1] * $v[1] + $m[1][2] * $v[2])),
            (Clamp ($m[2][0] * $v[0] + $m[2][1] * $v[1] + $m[2][2] * $v[2]))
        )
    }
    return OkLab $v[0] $v[1] $v[2]
}
function Dist([string]$a, [string]$b, [string]$kind) {
    $p = Sim $a $kind; $q = Sim $b $kind
    return [Math]::Sqrt([Math]::Pow($p[0] - $q[0], 2) + [Math]::Pow($p[1] - $q[1], 2) + [Math]::Pow($p[2] - $q[2], 2))
}

$fails = New-Object System.Collections.Generic.List[string]
$warns = New-Object System.Collections.Generic.List[string]
$notes = New-Object System.Collections.Generic.List[string]
$script:pr = 0.0
$script:plc = 0.0
function Pair([string]$name, [string]$text, [string]$bg) {
    $script:pr = Ratio $text $bg
    $script:plc = Apca $text $bg
    Write-Output (Fmt "PAIR {0}: #{1} on #{2} {3:0.00}:1 Lc {4:0.0}" @($name, $text, $bg, $script:pr, $script:plc))
}

$n = $hexes.Count
Write-Output ("PALETTE CHECK: " + (($hexes | ForEach-Object { "#$_" }) -join " "))
$L = @(); $CH = @(); $H = @()
foreach ($hex in $hexes) {
    $v = Linear $hex
    $lab = OkLab $v[0] $v[1] $v[2]
    $chroma = [Math]::Sqrt($lab[1] * $lab[1] + $lab[2] * $lab[2])
    $hue = [Math]::Atan2($lab[2], $lab[1]) * 180 / [Math]::PI
    if ($hue -lt 0) { $hue += 360 }
    $L += $lab[0]; $CH += $chroma; $H += $hue
    Write-Output (Fmt "COLOR: #{0} oklch({1:0.000} {2:0.000} {3:0})" @($hex, $lab[0], $chroma, $hue))
}
$hi = 0; $lo = 0
for ($i = 1; $i -lt $n; $i++) {
    if ($L[$i] -gt $L[$hi]) { $hi = $i }
    if ($L[$i] -lt $L[$lo]) { $lo = $i }
}
$bg = if ($L[$hi] -ge 0.9) { $hi } else { -1 }
$ink = if ($L[$lo] -le 0.35) { $lo } else { -1 }
$primary = -1
for ($i = 0; $i -lt $n; $i++) { if ($i -ne $bg -and $i -ne $ink -and ($primary -lt 0 -or $CH[$i] -gt $CH[$primary])) { $primary = $i } }
$surface = -1
for ($i = 0; $i -lt $n; $i++) { if ($i -ne $bg -and $i -ne $ink -and $i -ne $primary -and $L[$i] -ge 0.8 -and ($surface -lt 0 -or $L[$i] -gt $L[$surface])) { $surface = $i } }
$accent = @()
for ($i = 0; $i -lt $n; $i++) { if ($i -ne $bg -and $i -ne $ink -and $i -ne $primary -and $i -ne $surface) { $accent += "#" + $hexes[$i] } }
$bgHex = if ($bg -ge 0) { $hexes[$bg] } else { "ffffff" }
$inkHex = if ($ink -ge 0) { $hexes[$ink] } else { "1f1f1f" }
Write-Output ("ROLE bg: " + $(if ($bg -ge 0) { "#" + $hexes[$bg] } else { "derived near white" }))
Write-Output ("ROLE surface: " + $(if ($surface -ge 0) { "#" + $hexes[$surface] } else { "derived from bg" }))
Write-Output ("ROLE primary: " + $(if ($primary -ge 0) { "#" + $hexes[$primary] } else { "none" }))
Write-Output ("ROLE accent: " + $(if ($accent.Count -gt 0) { $accent -join " " } else { "none" }))
Write-Output ("ROLE ink: " + $(if ($ink -ge 0) { "#" + $hexes[$ink] } else { "derived near black" }))

Pair "ink-on-bg" $inkHex $bgHex
if ($ink -ge 0) {
    if ($script:pr -lt 4.5 -or $script:plc -lt 75) { $fails.Add((Fmt "body-text: ink on bg is {0:0.00}:1 and Lc {1:0.0}. Body text needs at least 4.5:1 and Lc 75. Derive a darker ink from the palette hue" @($script:pr, $script:plc))) }
    elseif ($script:pr -lt 7 -or $script:plc -lt 90) { $warns.Add((Fmt "body-text: ink on bg is {0:0.00}:1 and Lc {1:0.0}. Long reading is more comfortable at 7:1 and Lc 90. Use it for short text or derive a darker ink" @($script:pr, $script:plc))) }
}
if ($surface -ge 0) {
    Pair "ink-on-surface" $inkHex $hexes[$surface]
    if ($ink -ge 0 -and ($script:pr -lt 4.5 -or $script:plc -lt 60)) { $fails.Add((Fmt "surface-text: ink on surface #{0} is {1:0.00}:1 and Lc {2:0.0}. Text on panels needs 4.5:1 and Lc 60" @($hexes[$surface], $script:pr, $script:plc))) }
}
if ($primary -ge 0) {
    $p = $hexes[$primary]
    Pair "primary-on-bg" $p $bgHex
    if ($script:pr -lt 3) { $notes.Add((Fmt "primary-as-text: #{0} on bg is {1:0.00}:1. Use it only as a fill, never for links, icons or borders that carry meaning" @($p, $script:pr))) }
    elseif ($script:pr -lt 4.5) { $notes.Add((Fmt "primary-as-text: #{0} on bg is {1:0.00}:1. Fine for icons, borders and large text, not for links or small text" @($p, $script:pr))) }
    Pair "white-on-primary" "ffffff" $p; $wr = $script:pr
    Pair "ink-on-primary" $inkHex $p; $ir = $script:pr
    if ($wr -lt 4.5 -and $ir -lt 4.5) { $warns.Add((Fmt "text-on-primary: neither white ({0:0.00}:1) nor ink ({1:0.00}:1) reaches 4.5:1 on #{2}. Buttons on it need large bold labels or a darker shade" @($wr, $ir, $p))) }
}

for ($i = 0; $i -lt $n; $i++) {
    if ($CH[$i] -gt 0.25) { $fails.Add((Fmt "oversaturated: #{0} has chroma {1:0.000}. Colors this intense tire the eyes and vibrate next to other colors. Keep chroma at 0.25 or less" @($hexes[$i], $CH[$i]))) }
    elseif ($CH[$i] -gt 0.2 -and $L[$i] -gt 0.75) { $fails.Add((Fmt "neon: #{0} is bright and saturated (L {1:0.000}, C {2:0.000}). It glares on screens. Pick a calmer palette" @($hexes[$i], $L[$i], $CH[$i]))) }
    elseif ($CH[$i] -gt 0.15) { $notes.Add((Fmt "accent-only: #{0} has chroma {1:0.000}. Use it for small areas (buttons, markers, the 10 percent), never backgrounds or long text" @($hexes[$i], $CH[$i]))) }
}
if ($bg -ge 0 -and $CH[$bg] -gt 0.05) { $warns.Add((Fmt "tinted-background: #{0} has chroma {1:0.000}. A full page in a strong tint is tiring. Use it as surface and derive bg as a near white of its hue (chroma 0.02 or less)" @($hexes[$bg], $CH[$bg]))) }
if ($surface -ge 0 -and $CH[$surface] -gt 0.1) { $warns.Add((Fmt "saturated-surface: #{0} has chroma {1:0.000}. Large panels this saturated compete with content. Use it for small areas" @($hexes[$surface], $CH[$surface]))) }
if ($ink -ge 0 -and $hexes[$ink] -eq "000000") { $notes.Add("pure-black-text: ink is #000000. A near black from the palette hue (L 0.2 to 0.26) keeps contrast high and matches the palette") }

for ($i = 0; $i -lt $n; $i++) {
    $isRed = $CH[$i] -gt 0.13 -and ($H[$i] -lt 40 -or $H[$i] -gt 350)
    if (-not $isRed) { continue }
    for ($j = 0; $j -lt $n; $j++) {
        if ($CH[$j] -gt 0.1 -and $H[$j] -ge 225 -and $H[$j] -lt 265) {
            $warns.Add((Fmt "red-blue: #{0} and #{1} vibrate when they touch (chromostereopsis). Never put one on the other, keep a neutral between them" @($hexes[$i], $hexes[$j])))
        }
    }
}

$kinds = @("protanopia", "deuteranopia", "tritanopia")
for ($i = 0; $i -lt $n; $i++) {
    for ($j = $i + 1; $j -lt $n; $j++) {
        if ($i -eq $bg -or $j -eq $bg) { continue }
        if ((Dist $hexes[$i] $hexes[$j] "none") -lt 0.1) { continue }
        $worst = 1.0; $kind = ""
        foreach ($k in $kinds) { $d = Dist $hexes[$i] $hexes[$j] $k; if ($d -lt $worst) { $worst = $d; $kind = $k } }
        if ($worst -lt 0.05) { $warns.Add((Fmt "color-blind: #{0} and #{1} look alike with {2} (dE {3:0.000}). Never let them be the only difference between two states or chart series" @($hexes[$i], $hexes[$j], $kind, $worst))) }
    }
}

if ($L[$lo] -le 0.3) {
    Pair "dark-mode text-on-bg" $hexes[$hi] $hexes[$lo]
    if ($L[$lo] -lt 0.12) { $warns.Add((Fmt "dark-background: #{0} is nearly black. In dark mode use a dark gray of the palette hue (L 0.18 to 0.22) to avoid halation and smearing" @($hexes[$lo]))) }
    if ($L[$hi] -gt 0.98 -and $L[$lo] -lt 0.2) { $warns.Add((Fmt "dark-halation: #{0} text on #{1} glows for people with astigmatism. In dark mode use off white text (L 0.88 to 0.93)" @($hexes[$hi], $hexes[$lo]))) }
    if ($primary -ge 0 -and $CH[$primary] -gt 0.12) { $notes.Add((Fmt "dark-saturation: in dark mode lower the chroma of #{0} by about a third so it does not vibrate on the dark background" @($hexes[$primary]))) }
} else {
    Write-Output "PAIR dark-mode text-on-bg: no dark palette color, derive bg at L 0.18 to 0.22"
}

foreach ($f in $fails) { Write-Output "FAIL $f" }
foreach ($w in $warns) { Write-Output "WARN $w" }
foreach ($x in $notes) { Write-Output "NOTE $x" }
Write-Output "FAILS: $($fails.Count)"
Write-Output "WARNINGS: $($warns.Count)"
$result = if ($fails.Count -gt 0) { "FAIL" } elseif ($warns.Count -gt 0) { "REVIEW" } else { "PASS" }
Write-Output "RESULT: $result"
