#!/bin/bash
set -uo pipefail

usage() {
    echo "Usage: job-score.sh <jobs.tsv> [--profile <file>] [--seen <file>] [--record] [--min <score>]" >&2
}

JOBS=""
HOME_DIR="${UPWORK_JOBS_HOME:-$HOME/.upwork-jobs}"
PROFILE="$HOME_DIR/profile.conf"
SEEN=""
RECORD=0
MIN=""

while [ $# -gt 0 ]; do
    case "$1" in
        --profile) PROFILE="${2:-}"; shift 2 ;;
        --seen) SEEN="${2:-}"; shift 2 ;;
        --record) RECORD=1; shift ;;
        --min) MIN="${2:-}"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        -*) echo "ERROR: unknown option $1" >&2; usage; exit 1 ;;
        *) JOBS="$1"; shift ;;
    esac
done

if [ -z "$JOBS" ]; then
    echo "ERROR: give a jobs TSV file." >&2
    usage
    exit 1
fi
if [ ! -f "$JOBS" ]; then
    echo "ERROR: $JOBS does not exist." >&2
    exit 1
fi
if [ ! -f "$PROFILE" ]; then
    echo "ERROR: profile $PROFILE does not exist. Copy templates/profile.conf there and edit it." >&2
    exit 1
fi
if [ -n "$MIN" ] && ! printf '%s' "$MIN" | grep -qE '^[0-9]+$'; then
    echo "ERROR: --min must be a whole number." >&2
    exit 1
fi
if [ "$RECORD" -eq 1 ] && [ -z "$SEEN" ]; then
    SEEN="$HOME_DIR/seen.txt"
fi

SEEN_IN="/dev/null"
if [ -n "$SEEN" ] && [ -f "$SEEN" ]; then
    SEEN_IN="$SEEN"
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

awk -v FS='\t' -v seenf="$SEEN_IN" -v proff="$PROFILE" -v minarg="$MIN" -v rows="$WORK/rows" -v summary="$WORK/summary" -v ids="$WORK/ids" '
function trim(s) { gsub(/\r/, "", s); sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
function num(s) { s = trim(s); gsub(/[$,%+]/, "", s); return (s ~ /^[0-9]+(\.[0-9]+)?$/) ? s + 0 : -1 }
function has(hay, term,    pos, start, before, after, n) {
    n = length(term)
    if (n == 0) return 0
    start = 1
    while ((pos = index(substr(hay, start), term)) > 0) {
        pos = start + pos - 1
        before = (pos > 1) ? substr(hay, pos - 1, 1) : " "
        after = substr(hay, pos + n, 1)
        if (before !~ /[a-z0-9]/ && after !~ /[a-z0-9]/) return 1
        start = pos + 1
    }
    return 0
}
function split_list(s, arr,    n, i, raw, out, item) {
    n = split(tolower(s), raw, ",")
    out = 0
    for (i = 1; i <= n; i++) {
        item = trim(raw[i])
        if (item != "") arr[++out] = item
    }
    return out
}
function col(name) { return (name in cidx) ? trim($cidx[name]) : "" }
function bump(reason) { skipcount[reason]++ }
BEGIN {
    nscam = split("telegram,whatsapp,outside upwork,outside of upwork,off upwork,off platform,off-platform,registration fee,training fee,upfront payment,pay to start,security deposit,crypto wallet", scam, ",")
    ntz = split("us only,u.s. only,us based only,us-based only,must be in the us,est hours,pst hours,est time zone,pst time zone,us business hours,us working hours,us/uk business hours,uk business hours,overlap with us,overlap with est,overlap with pst,us central time,us eastern time,us pacific time,uk only,europe only,eu only", tz, ",")
    nft = split("full-time,full time,40 hours,40 hrs,40+ hours,40 hours per week", ft, ",")
    nmulti = split("multiple freelancers,several freelancers,more than one freelancer,multiple positions,several positions,multiple hires,several hires,hire multiple,hiring multiple,hire several,hiring several,multiple developers,several developers", multi, ",")
    p["rate"] = 15; p["min_hourly"] = 10; p["min_fixed"] = 50; p["require_verified"] = "yes"; p["min_score"] = 55
}
FNR == 1 { fileno = (fileno == 0 && FILENAME == seenf) ? 1 : ((fileno <= 1 && FILENAME == proff) ? 2 : 3) }
fileno == 1 {
    line = trim($0)
    if (line != "") seen[line] = 1
    next
}
fileno == 2 {
    line = $0
    gsub(/\r/, "", line)
    if (line ~ /^[ \t]*#/ || line !~ /=/) next
    key = trim(substr(line, 1, index(line, "=") - 1))
    p[key] = trim(substr(line, index(line, "=") + 1))
    next
}
fileno == 3 && !header {
    for (i = 1; i <= NF; i++) cidx[tolower(trim($i))] = i
    header = 1
    hasact = ("interviewing" in cidx) || ("invites_sent" in cidx) || ("hires_on_job" in cidx) || ("last_viewed_hours" in cidx)
    ncore = split_list(p["core"], core)
    nsec = split_list(p["secondary"], sec)
    navoid = split_list(p["avoid"], avoid)
    minscore = (minarg != "") ? minarg + 0 : p["min_score"] + 0
    next
}
fileno == 3 {
    if (trim($0) == "") next
    id = col("id"); title = col("title"); url = col("url")
    if (id == "") id = url
    total++
    if (id in seen) { bump("seen"); printf "3\t000\t%s\tSKIP %s seen | %s\n", id, id, title > rows; next }
    if (id in batch) { bump("duplicate"); printf "3\t000\t%s\tSKIP %s duplicate | %s\n", id, id, title > rows; next }
    batch[id] = 1
    print id > ids

    lt = " " tolower(title) " "
    ls = " " tolower(col("skills")) " "
    lx = " " tolower(col("text")) " "
    all = lt " " ls " " lx

    reason = ""
    flags = ""
    penalty = 0

    nm = 0
    for (i = 1; i <= ncore + nsec; i++) {
        t = (i <= ncore) ? core[i] : sec[i - ncore]
        if (has(lt, t) || has(ls, t) || (length(t) >= 4 && has(lx, t))) { nm++; mterm[nm] = t; mcore[nm] = (i <= ncore) }
    }
    corehits = 0; sechits = 0; stack = ""
    for (i = 1; i <= nm; i++) {
        covered = 0
        for (j = 1; j <= nm; j++) if (j != i && length(mterm[j]) > length(mterm[i]) && index(mterm[j], mterm[i])) { covered = 1; break }
        if (covered) continue
        if (mcore[i]) corehits++; else sechits++
        stack = stack (stack == "" ? "" : ",") mterm[i]
    }
    avoidhit = ""
    for (i = 1; i <= navoid; i++) if (has(lt, avoid[i]) || has(ls, avoid[i])) { avoidhit = avoid[i]; break }

    for (i = 1; i <= nscam; i++) if (has(all, scam[i])) { reason = "scam:" scam[i]; break }
    workload = tolower(col("workload"))
    verified = col("payment_verified")
    type = tolower(col("type"))
    rmin = num(col("rate_min")); rmax = num(col("rate_max")); budget = num(col("budget"))
    hourly = (rmax > 0) ? rmax : rmin

    if (reason == "" && index(lx, "only freelancers located in") && !has(lx, "indonesia") && !has(lx, "asia")) reason = "region-lock"
    if (reason == "" && workload == "full" && tolower(p["full_time_ok"]) != "yes") reason = "full-time"
    if (reason == "" && tolower(p["require_verified"]) == "yes" && verified == "0") reason = "unverified"
    if (reason == "" && corehits + sechits == 0) reason = "no-stack-match"
    if (reason == "" && avoidhit != "" && corehits == 0) reason = "avoid:" avoidhit
    if (reason == "" && type == "hourly" && hourly > 0 && hourly < p["min_hourly"] + 0) reason = "low-pay"
    if (reason == "" && type == "fixed" && budget > 0 && budget < p["min_fixed"] + 0) reason = "low-pay"
    iv = num(col("interviewing")); inv = num(col("invites_sent")); hj = num(col("hires_on_job")); lv = num(col("last_viewed_hours"))
    multipos = 0
    for (i = 1; i <= nmulti; i++) if (has(lx, multi[i])) { multipos = 1; break }
    if (reason == "" && hj >= 1 && !multipos) reason = "filled"
    if (reason == "" && iv >= 5) reason = "interviewing"

    if (reason != "") {
        bump(reason ~ /^scam:/ ? "scam" : (reason ~ /^avoid:/ ? "avoid" : reason))
        printf "3\t000\t%s\tSKIP %s %s | %s\n", id, id, reason, title > rows
        next
    }

    sstack = corehits * 12 + sechits * 5
    if (sstack > 40) sstack = 40

    if (type == "fixed") {
        if (budget >= 500) spay = 15
        else if (budget >= 150) spay = 11
        else if (budget > 0) spay = 6
        else spay = 5
        paytxt = "fixed " (budget > 0 ? "$" budget : "?")
    } else {
        if (hourly >= p["rate"] + 0) spay = 15
        else if (hourly > 0) spay = 8
        else spay = 7
        paytxt = "hourly " (rmin > 0 ? rmin : "?") "-" (rmax > 0 ? rmax : "?")
    }

    spent = num(col("client_spent")); hire = num(col("hire_rate")); rating = num(col("client_rating"))
    sclient = (verified == "1") ? 4 : ((verified == "0") ? 0 : 2)
    if (spent >= 10000) sclient += 8; else if (spent >= 1000) sclient += 6; else if (spent > 0) sclient += 3; else sclient += 1
    if (hire >= 50) sclient += 5; else if (hire >= 20) sclient += 3; else if (hire > 0) sclient += 1
    if (rating >= 4.5) sclient += 3; else if (rating >= 4) sclient += 2; else if (rating <= 0) sclient += 1

    props = num(col("proposals")); posted = num(col("posted_hours"))
    if (props < 0) scomp = 4; else if (props < 5) scomp = 10; else if (props < 10) scomp = 7; else if (props < 15) scomp = 4; else if (props < 20) scomp = 2; else scomp = 0
    if (posted < 0) scomp += 1; else if (posted <= 6) scomp += 5; else if (posted <= 24) scomp += 3; else if (posted <= 72) scomp += 1
    if (iv == 0) scomp += 3; else if (iv >= 3) scomp -= 4
    if (inv > 0 && iv > 0) scomp -= 3
    if (lv >= 0 && lv <= 1) scomp += 2; else if (lv > 24) scomp -= 4
    if (scomp < 0) scomp = 0
    if (scomp > 15) scomp = 15

    level = tolower(col("level"))
    if (level == "entry") slevel = 10; else if (level == "intermediate") slevel = 8; else if (level == "expert") slevel = 4; else slevel = 5

    for (i = 1; i <= ntz; i++) if (has(lx, tz[i])) { flags = flags (flags == "" ? "" : ",") "timezone:" tz[i]; penalty += 10; break }
    if (workload != "part") for (i = 1; i <= nft; i++) if (has(lx, ft[i])) { flags = flags (flags == "" ? "" : ",") "full-time-wording"; penalty += 10; break }
    if (avoidhit != "") { flags = flags (flags == "" ? "" : ",") "avoid:" avoidhit; penalty += 15 }
    if (verified != "1" && verified != "0") flags = flags (flags == "" ? "" : ",") "payment-unknown"
    connects = num(col("connects"))
    if (connects >= 16) flags = flags (flags == "" ? "" : ",") "connects:" connects
    if (inv > 0 && iv > 0) flags = flags (flags == "" ? "" : ",") "invited-shortlist"
    if (lv > 24) flags = flags (flags == "" ? "" : ",") "client-inactive"
    if (hj >= 1) flags = flags (flags == "" ? "" : ",") "hired:" hj

    score = sstack + spay + sclient + scomp + slevel - penalty
    if (score < 0) score = 0
    if (score > 100) score = 100

    tag = (score >= minscore) ? "JOB" : "LOW"
    group = (tag == "JOB") ? 1 : 2
    if (tag == "JOB") shortlist++; else low++
    printf "%d\t%03d\t%s\t%s %d %s | %s | stack %s | %s | proposals %s | posted %s | parts stack %d pay %d client %d comp %d level %d | flags %s | %s\n", group, 100 - score, id, tag, score, id, title, stack, paytxt, (props < 0 ? "?" : props), (posted < 0 ? "?" : posted "h"), sstack, spay, sclient, scomp, slevel, (flags == "" ? "none" : flags), url > rows
}
END {
    skipped = 0
    for (r in skipcount) skipped += skipcount[r]
    printf "JOBS: %d\nSHORTLIST: %d\nLOW: %d\nSKIPPED: %d\nMIN_SCORE: %d\n", total, shortlist, low, skipped, minscore > summary
    n = split("seen,duplicate,scam,region-lock,full-time,unverified,no-stack-match,avoid,low-pay" (hasact ? ",filled,interviewing" : ""), order, ",")
    for (i = 1; i <= n; i++) printf "SKIP_%s: %d\n", toupper(order[i]), skipcount[order[i]] + 0 > summary
}
' "$SEEN_IN" "$PROFILE" "$JOBS"
STATUS=$?
if [ "$STATUS" -ne 0 ]; then
    echo "ERROR: could not read $JOBS." >&2
    exit 1
fi

echo "UPWORK JOB SCORE: $JOBS"
echo "PROFILE: $PROFILE"
if [ -s "$WORK/rows" ]; then
    LC_ALL=C sort -t "$(printf '\t')" -k1,1n -k2,2n -k3,3 "$WORK/rows" | cut -f4-
fi
cat "$WORK/summary"

if [ "$RECORD" -eq 1 ] && [ -s "$WORK/ids" ]; then
    mkdir -p "$(dirname "$SEEN")"
    cat "$WORK/ids" >>"$SEEN"
    echo "RECORDED: $(wc -l <"$WORK/ids" | tr -d ' ') to $SEEN"
fi
exit 0
