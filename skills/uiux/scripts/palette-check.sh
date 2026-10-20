#!/bin/bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
    echo "ERROR: Usage: palette-check.sh <hex> <hex> [hex ...]" >&2
    exit 1
fi

COLORS=()
for arg in "$@"; do
    hex="$(printf '%s' "$arg" | tr -d '#' | tr '[:upper:]' '[:lower:]')"
    if ! printf '%s' "$hex" | grep -qE '^[0-9a-f]{6}$'; then
        echo "ERROR: $arg is not a six digit hex color." >&2
        exit 1
    fi
    COLORS+=("$hex")
done

awk -v list="${COLORS[*]}" '
function hexval(h,   i, v, d) {
    v = 0
    for (i = 1; i <= length(h); i++) {
        d = index("0123456789abcdef", substr(h, i, 1)) - 1
        v = v * 16 + d
    }
    return v
}
function lin(c) { return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ^ 2.4 }
function cbrt(x) { return x <= 0 ? 0 : exp(log(x) / 3) }
function clamp(x) { return x < 0 ? 0 : (x > 1 ? 1 : x) }
function load(h,   r, g, b) {
    r = hexval(substr(h, 1, 2)) / 255
    g = hexval(substr(h, 3, 2)) / 255
    b = hexval(substr(h, 5, 2)) / 255
    LR = lin(r); LG = lin(g); LB = lin(b)
    SR = r; SG = g; SB = b
}
function oklab(r, g, b,   l, m, s) {
    l = cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
    m = cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
    s = cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
    OL = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
    OA = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
    OB = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
}
function lum(h) { load(h); return 0.2126 * LR + 0.7152 * LG + 0.0722 * LB }
function ratio(a, b,   x, y, t) {
    x = lum(a); y = lum(b)
    if (y > x) { t = x; x = y; y = t }
    return (x + 0.05) / (y + 0.05)
}
function apcaY(h,   y) {
    load(h)
    y = 0.2126729 * SR ^ 2.4 + 0.7151522 * SG ^ 2.4 + 0.0721750 * SB ^ 2.4
    if (y < 0.022) y += (0.022 - y) ^ 1.414
    return y
}
function apca(text, bg,   yt, yb, s) {
    yt = apcaY(text); yb = apcaY(bg)
    if ((yb > yt ? yb - yt : yt - yb) < 0.0005) return 0
    if (yb > yt) {
        s = (yb ^ 0.56 - yt ^ 0.57) * 1.14
        return s < 0.1 ? 0 : (s - 0.027) * 100
    }
    s = (yb ^ 0.65 - yt ^ 0.62) * 1.14
    return s > -0.1 ? 0 : (s + 0.027) * 100
}
function sim(h, k,   r, g, b) {
    load(h)
    if (k == "protanopia") {
        r = 0.152286 * LR + 1.052583 * LG - 0.204868 * LB
        g = 0.114503 * LR + 0.786281 * LG + 0.099216 * LB
        b = -0.003882 * LR - 0.048116 * LG + 1.051998 * LB
    } else if (k == "deuteranopia") {
        r = 0.367322 * LR + 0.860646 * LG - 0.227968 * LB
        g = 0.280085 * LR + 0.672501 * LG + 0.047413 * LB
        b = -0.011820 * LR + 0.042940 * LG + 0.968881 * LB
    } else if (k == "tritanopia") {
        r = 1.255528 * LR - 0.076749 * LG - 0.178779 * LB
        g = -0.078411 * LR + 0.930809 * LG + 0.147602 * LB
        b = 0.004733 * LR + 0.691367 * LG + 0.303900 * LB
    } else {
        r = LR; g = LG; b = LB
    }
    oklab(clamp(r), clamp(g), clamp(b))
}
function dist(a, b, k,   l1, a1, b1) {
    sim(a, k); l1 = OL; a1 = OA; b1 = OB
    sim(b, k)
    return sqrt((l1 - OL) ^ 2 + (a1 - OA) ^ 2 + (b1 - OB) ^ 2)
}
function pair(name, text, bg, need,   r, lc) {
    r = ratio(text, bg); lc = apca(text, bg)
    printf "PAIR %s: #%s on #%s %.2f:1 Lc %.1f\n", name, text, bg, r, lc
    PR = r; PLC = lc
}
function fail(msg) { fails++; F[fails] = msg }
function warn(msg) { warns++; W[warns] = msg }
function note(msg) { notes++; N[notes] = msg }
BEGIN {
    n = split(list, C, " ")
    printf "PALETTE CHECK:"
    for (i = 1; i <= n; i++) printf " #%s", C[i]
    printf "\n"
    for (i = 1; i <= n; i++) {
        load(C[i]); oklab(LR, LG, LB)
        L[i] = OL; CH[i] = sqrt(OA * OA + OB * OB)
        H[i] = atan2(OB, OA) * 180 / 3.141592653589793
        if (H[i] < 0) H[i] += 360
        printf "COLOR: #%s oklch(%.3f %.3f %.0f)\n", C[i], L[i], CH[i], H[i]
    }
    hi = 1; lo = 1
    for (i = 2; i <= n; i++) {
        if (L[i] > L[hi]) hi = i
        if (L[i] < L[lo]) lo = i
    }
    bg = L[hi] >= 0.9 ? hi : 0
    ink = L[lo] <= 0.35 ? lo : 0
    primary = 0
    for (i = 1; i <= n; i++) if (i != bg && i != ink && (primary == 0 || CH[i] > CH[primary])) primary = i
    surface = 0
    for (i = 1; i <= n; i++) if (i != bg && i != ink && i != primary && L[i] >= 0.8 && (surface == 0 || L[i] > L[surface])) surface = i
    accent = ""
    for (i = 1; i <= n; i++) if (i != bg && i != ink && i != primary && i != surface) accent = accent (accent == "" ? "" : " ") "#" C[i]
    bgHex = bg ? C[bg] : "ffffff"
    inkHex = ink ? C[ink] : "1f1f1f"
    print "ROLE bg: " (bg ? "#" C[bg] : "derived near white")
    print "ROLE surface: " (surface ? "#" C[surface] : "derived from bg")
    print "ROLE primary: " (primary ? "#" C[primary] : "none")
    print "ROLE accent: " (accent != "" ? accent : "none")
    print "ROLE ink: " (ink ? "#" C[ink] : "derived near black")

    pair("ink-on-bg", inkHex, bgHex)
    if (ink) {
        if (PR < 4.5 || PLC < 75) fail(sprintf("body-text: ink on bg is %.2f:1 and Lc %.1f. Body text needs at least 4.5:1 and Lc 75. Derive a darker ink from the palette hue", PR, PLC))
        else if (PR < 7 || PLC < 90) warn(sprintf("body-text: ink on bg is %.2f:1 and Lc %.1f. Long reading is more comfortable at 7:1 and Lc 90. Use it for short text or derive a darker ink", PR, PLC))
    }
    if (surface) {
        pair("ink-on-surface", inkHex, C[surface])
        if (ink && (PR < 4.5 || PLC < 60)) fail(sprintf("surface-text: ink on surface #%s is %.2f:1 and Lc %.1f. Text on panels needs 4.5:1 and Lc 60", C[surface], PR, PLC))
    }
    if (primary) {
        pair("primary-on-bg", C[primary], bgHex)
        if (PR < 3) note(sprintf("primary-as-text: #%s on bg is %.2f:1. Use it only as a fill, never for links, icons or borders that carry meaning", C[primary], PR))
        else if (PR < 4.5) note(sprintf("primary-as-text: #%s on bg is %.2f:1. Fine for icons, borders and large text, not for links or small text", C[primary], PR))
        pair("white-on-primary", "ffffff", C[primary]); wr = PR
        pair("ink-on-primary", inkHex, C[primary]); ir = PR
        if (wr < 4.5 && ir < 4.5) warn(sprintf("text-on-primary: neither white (%.2f:1) nor ink (%.2f:1) reaches 4.5:1 on #%s. Buttons on it need large bold labels or a darker shade", wr, ir, C[primary]))
    }

    for (i = 1; i <= n; i++) {
        if (CH[i] > 0.25) fail(sprintf("oversaturated: #%s has chroma %.3f. Colors this intense tire the eyes and vibrate next to other colors. Keep chroma at 0.25 or less", C[i], CH[i]))
        else if (CH[i] > 0.2 && L[i] > 0.75) fail(sprintf("neon: #%s is bright and saturated (L %.3f, C %.3f). It glares on screens. Pick a calmer palette", C[i], L[i], CH[i]))
        else if (CH[i] > 0.15) note(sprintf("accent-only: #%s has chroma %.3f. Use it for small areas (buttons, markers, the 10 percent), never backgrounds or long text", C[i], CH[i]))
    }
    if (bg && CH[bg] > 0.05) warn(sprintf("tinted-background: #%s has chroma %.3f. A full page in a strong tint is tiring. Use it as surface and derive bg as a near white of its hue (chroma 0.02 or less)", C[bg], CH[bg]))
    if (surface && CH[surface] > 0.1) warn(sprintf("saturated-surface: #%s has chroma %.3f. Large panels this saturated compete with content. Use it for small areas", C[surface], CH[surface]))
    if (ink && C[ink] == "000000") note("pure-black-text: ink is #000000. A near black from the palette hue (L 0.2 to 0.26) keeps contrast high and matches the palette")

    for (i = 1; i <= n; i++) {
        isred = CH[i] > 0.13 && (H[i] < 40 || H[i] > 350)
        if (!isred) continue
        for (j = 1; j <= n; j++) {
            isblue = CH[j] > 0.1 && H[j] >= 225 && H[j] < 265
            if (isblue) warn(sprintf("red-blue: #%s and #%s vibrate when they touch (chromostereopsis). Never put one on the other, keep a neutral between them", C[i], C[j]))
        }
    }

    split("protanopia deuteranopia tritanopia", K, " ")
    for (i = 1; i <= n; i++) for (j = i + 1; j <= n; j++) {
        if (i == bg || j == bg) continue
        normal = dist(C[i], C[j], "none")
        if (normal < 0.1) continue
        worst = 1; kind = ""
        for (k = 1; k <= 3; k++) { d = dist(C[i], C[j], K[k]); if (d < worst) { worst = d; kind = K[k] } }
        if (worst < 0.05) warn(sprintf("color-blind: #%s and #%s look alike with %s (dE %.3f). Never let them be the only difference between two states or chart series", C[i], C[j], kind, worst))
    }

    if (L[lo] <= 0.3) {
        pair("dark-mode text-on-bg", C[hi], C[lo])
        if (L[lo] < 0.12) warn(sprintf("dark-background: #%s is nearly black. In dark mode use a dark gray of the palette hue (L 0.18 to 0.22) to avoid halation and smearing", C[lo]))
        if (L[hi] > 0.98 && L[lo] < 0.2) warn(sprintf("dark-halation: #%s text on #%s glows for people with astigmatism. In dark mode use off white text (L 0.88 to 0.93)", C[hi], C[lo]))
        if (primary && CH[primary] > 0.12) note(sprintf("dark-saturation: in dark mode lower the chroma of #%s by about a third so it does not vibrate on the dark background", C[primary]))
    } else {
        print "PAIR dark-mode text-on-bg: no dark palette color, derive bg at L 0.18 to 0.22"
    }

    for (i = 1; i <= fails; i++) print "FAIL " F[i]
    for (i = 1; i <= warns; i++) print "WARN " W[i]
    for (i = 1; i <= notes; i++) print "NOTE " N[i]
    print "FAILS: " fails + 0
    print "WARNINGS: " warns + 0
    print "RESULT: " (fails > 0 ? "FAIL" : (warns > 0 ? "REVIEW" : "PASS"))
}'
