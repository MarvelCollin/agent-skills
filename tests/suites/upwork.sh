UPSCRIPTS="$ROOT/skills/upwork/scripts"
UPFIX="$ROOT/tests/fixtures/upwork"

upwork_score_checks() {
    local label="$1" out="$2" strict="$3"
    expect_contains "$label ranks the docker job first" "$(printf '%s\n' "$out" | sed -n 3p)" "JOB 94 ~01dock"
    expect_contains "$label lists the matched stack" "$out" "stack next.js,docker compose,dockerfile,nginx,vps"
    expect_contains "$label shows the score parts" "$out" "parts stack 40 pay 11 client 20 comp 15 level 8"
    expect_contains "$label keeps a timezone job with a penalty" "$out" "JOB 68 ~01dotnet"
    expect_contains "$label flags the timezone wording" "$out" "flags timezone:est hours"
    expect_contains "$label counts overlapping terms once" "$out" "stack asp.net core,c#,rest api"
    expect_contains "$label keeps a job with unknown payment status" "$out" "JOB 59 ~01anon"
    expect_contains "$label flags unknown payment status" "$out" "flags payment-unknown"
    expect_contains "$label marks a weak job as low" "$out" "LOW 21 ~01vue"
    expect_contains "$label flags a high connects cost" "$out" "flags connects:20"
    expect_contains "$label skips full-time roles" "$out" "SKIP ~01gofull full-time"
    expect_contains "$label skips avoided stacks" "$out" "SKIP ~01wp avoid:wordpress"
    expect_contains "$label skips off-platform scams" "$out" "SKIP ~01scam scam:telegram"
    expect_contains "$label skips unverified clients" "$out" "SKIP ~01unver unverified"
    expect_contains "$label skips low pay" "$out" "SKIP ~01cheap low-pay"
    expect_contains "$label skips unrelated work" "$out" "SKIP ~01excel no-stack-match"
    expect_contains "$label skips region locked jobs" "$out" "SKIP ~01region region-lock"
    expect_contains "$label skips jobs seen before" "$out" "SKIP ~01old seen"
    expect_contains "$label skips duplicates in one batch" "$out" "SKIP ~01dock duplicate"
    expect_contains "$label counts jobs" "$out" "JOBS: 13"
    expect_contains "$label counts the shortlist" "$out" "SHORTLIST: 3"
    expect_contains "$label counts skips" "$out" "SKIPPED: 9"
    expect_contains "$label counts each skip reason" "$out" "SKIP_SCAM: 1"
    expect_contains "$label counts seen jobs" "$out" "SKIP_SEEN: 1"
    expect_contains "$label reports the threshold" "$out" "MIN_SCORE: 55"
    expect_contains "$label applies a stricter threshold" "$strict" "LOW 68 ~01dotnet"
    expect_contains "$label reports the stricter threshold" "$strict" "MIN_SCORE: 70"
    if printf '%s\n' "$out" | grep -q "SKIP_FILLED\|SKIP_INTERVIEWING"; then
        fail "$label keeps the old summary for a TSV without activity columns" "$out"
    else
        pass "$label keeps the old summary for a TSV without activity columns"
    fi
}

upwork_activity_checks() {
    local label="$1" out="$2"
    expect_contains "$label scores a job with empty activity columns as before" "$out" "JOB 84 ~02blank"
    expect_contains "$label leaves competition alone with no activity" "$(printf '%s\n' "$out" | grep '~02blank')" "comp 5 level"
    expect_contains "$label adds for no interviews and a client viewing within the hour" "$(printf '%s\n' "$out" | grep '~02fresh')" "comp 10 level"
    expect_contains "$label caps competition at 15" "$(printf '%s\n' "$out" | grep '~02ceil')" "comp 15 level"
    expect_contains "$label takes off for 3 to 4 interviewing" "$(printf '%s\n' "$out" | grep '~02busy')" "comp 1 level"
    expect_contains "$label takes off for invites with interviews" "$(printf '%s\n' "$out" | grep '~02some')" "comp 2 level"
    expect_contains "$label flags an invited shortlist" "$(printf '%s\n' "$out" | grep '~02some')" "flags invited-shortlist"
    expect_contains "$label takes off for a client not seen in a day" "$(printf '%s\n' "$out" | grep '~02cold')" "comp 4 level"
    expect_contains "$label flags an inactive client" "$(printf '%s\n' "$out" | grep '~02cold')" "flags client-inactive"
    expect_contains "$label floors competition at 0" "$(printf '%s\n' "$out" | grep '~02floor')" "comp 0 level"
    expect_contains "$label skips a job with a hire" "$out" "SKIP ~02filled filled"
    expect_contains "$label keeps a hire on a several position job" "$out" "JOB 84 ~02multi"
    expect_contains "$label flags the hire on a several position job" "$(printf '%s\n' "$out" | grep '~02multi')" "flags hired:1"
    expect_contains "$label skips a job with 5 interviewing" "$out" "SKIP ~02crowd interviewing"
    expect_contains "$label ranks the open window first" "$(printf '%s\n' "$out" | sed -n 4p)" "JOB 89 ~02fresh"
    expect_contains "$label counts filled skips" "$out" "SKIP_FILLED: 1"
    expect_contains "$label counts interviewing skips" "$out" "SKIP_INTERVIEWING: 1"
    expect_contains "$label counts all activity skips" "$out" "SKIPPED: 2"
}

echo "job-score.sh"
UP_OUT=$(bash "$UPSCRIPTS/job-score.sh" "$UPFIX/jobs.tsv" --profile "$UPFIX/profile.conf" --seen "$UPFIX/seen.txt" 2>&1); CODE=$?
expect_exit "exits cleanly" "$CODE" 0
UP_STRICT=$(bash "$UPSCRIPTS/job-score.sh" "$UPFIX/jobs.tsv" --profile "$UPFIX/profile.conf" --seen "$UPFIX/seen.txt" --min 70 2>&1)
upwork_score_checks "it" "$UP_OUT" "$UP_STRICT"
UP_ACT=$(bash "$UPSCRIPTS/job-score.sh" "$UPFIX/jobs-activity.tsv" --profile "$UPFIX/profile.conf" 2>&1); CODE=$?
expect_exit "exits cleanly with activity columns" "$CODE" 0
upwork_activity_checks "it" "$UP_ACT"

OUT=$(bash "$UPSCRIPTS/job-score.sh" "$UPFIX/jobs.tsv" --profile "$UPFIX/profile.conf" 2>&1)
expect_contains "scores a first run with no seen file" "$OUT" "JOB 94 ~01dock"
expect_contains "counts nothing as seen on a first run" "$OUT" "SKIP_SEEN: 0"
OUT=$(bash "$UPSCRIPTS/job-score.sh" "$UPFIX/jobs.tsv" --profile "$UPFIX/profile.conf" --seen "$WORK/upwork-none.txt" 2>&1)
expect_contains "scores with a seen file that does not exist yet" "$OUT" "SKIP_SEEN: 0"
cp "$UPFIX/seen.txt" "$WORK/upwork-seen.txt"
OUT=$(bash "$UPSCRIPTS/job-score.sh" "$UPFIX/jobs.tsv" --profile "$UPFIX/profile.conf" --seen "$WORK/upwork-seen.txt" --record 2>&1)
expect_contains "records new job ids" "$OUT" "RECORDED: 11 to $WORK/upwork-seen.txt"
OUT=$(bash "$UPSCRIPTS/job-score.sh" "$UPFIX/jobs.tsv" --profile "$UPFIX/profile.conf" --seen "$WORK/upwork-seen.txt" 2>&1)
expect_contains "skips every recorded job on the next run" "$OUT" "SKIP_SEEN: 13"
expect_contains "shortlists nothing already recorded" "$OUT" "SHORTLIST: 0"

OUT=$(UPWORK_JOBS_HOME="$WORK/upwork-home" bash "$UPSCRIPTS/job-score.sh" "$UPFIX/jobs.tsv" 2>&1); CODE=$?
expect_exit "fails without a profile" "$CODE" 1
expect_contains "explains the missing profile" "$OUT" "Copy templates/profile.conf there"
bash "$UPSCRIPTS/job-score.sh" >/dev/null 2>&1; CODE=$?
expect_exit "fails without a jobs file" "$CODE" 1
bash "$UPSCRIPTS/job-score.sh" "$WORK/upwork-nope.tsv" --profile "$UPFIX/profile.conf" >/dev/null 2>&1; CODE=$?
expect_exit "fails on a missing jobs file" "$CODE" 1
bash "$UPSCRIPTS/job-score.sh" "$UPFIX/jobs.tsv" --profile "$UPFIX/profile.conf" --min high >/dev/null 2>&1; CODE=$?
expect_exit "rejects a non numeric threshold" "$CODE" 1

if [ -n "$POWERSHELL" ]; then
    echo "job-score.ps1"
    PS_OUT=$(run_ps "$UPSCRIPTS/job-score.ps1" -Path "$UPFIX/jobs.tsv" -Profile "$UPFIX/profile.conf" -Seen "$UPFIX/seen.txt" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "exits cleanly" "$CODE" 0
    PS_STRICT=$(run_ps "$UPSCRIPTS/job-score.ps1" -Path "$UPFIX/jobs.tsv" -Profile "$UPFIX/profile.conf" -Seen "$UPFIX/seen.txt" -Min 70 2>&1 | tr -d '\r')
    upwork_score_checks "it" "$PS_OUT" "$PS_STRICT"
    if [ "$(printf '%s\n' "$UP_OUT" | tail -n +3)" = "$(printf '%s\n' "$PS_OUT" | tail -n +3)" ]; then
        pass "matches the bash output"
    else
        fail "matches the bash output" "$(diff <(printf '%s\n' "$UP_OUT" | tail -n +3) <(printf '%s\n' "$PS_OUT" | tail -n +3))"
    fi
    PS_ACT=$(run_ps "$UPSCRIPTS/job-score.ps1" -Path "$UPFIX/jobs-activity.tsv" -Profile "$UPFIX/profile.conf" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "exits cleanly with activity columns" "$CODE" 0
    upwork_activity_checks "it" "$PS_ACT"
    if [ "$(printf '%s\n' "$UP_ACT" | tail -n +3)" = "$(printf '%s\n' "$PS_ACT" | tail -n +3)" ]; then
        pass "matches the bash output with activity columns"
    else
        fail "matches the bash output with activity columns" "$(diff <(printf '%s\n' "$UP_ACT" | tail -n +3) <(printf '%s\n' "$PS_ACT" | tail -n +3))"
    fi
    OUT=$(run_ps "$UPSCRIPTS/job-score.ps1" -Path "$UPFIX/jobs.tsv" -Profile "$UPFIX/profile.conf" 2>&1 | tr -d '')
    expect_contains "scores a first run with no seen file" "$OUT" "JOB 94 ~01dock"
    cp "$UPFIX/seen.txt" "$WORK/upwork-seen-ps.txt"
    OUT=$(run_ps "$UPSCRIPTS/job-score.ps1" -Path "$UPFIX/jobs.tsv" -Profile "$UPFIX/profile.conf" -Seen "$WORK/upwork-seen-ps.txt" -Record 2>&1 | tr -d '\r')
    expect_contains "records new job ids" "$OUT" "RECORDED: 11 to"
    OUT=$(run_ps "$UPSCRIPTS/job-score.ps1" -Path "$UPFIX/jobs.tsv" -Profile "$UPFIX/profile.conf" -Seen "$WORK/upwork-seen-ps.txt" 2>&1 | tr -d '\r')
    expect_contains "skips every recorded job on the next run" "$OUT" "SKIP_SEEN: 13"
    OUT=$(UPWORK_JOBS_HOME="$WORK/upwork-home" run_ps "$UPSCRIPTS/job-score.ps1" -Path "$UPFIX/jobs.tsv" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "fails without a profile" "$CODE" 1
    run_ps "$UPSCRIPTS/job-score.ps1" >/dev/null 2>&1; CODE=$?
    expect_exit "fails without a jobs file" "$CODE" 1
    run_ps "$UPSCRIPTS/job-score.ps1" -Path "$UPFIX/jobs.tsv" -Profile "$UPFIX/profile.conf" -Min high >/dev/null 2>&1; CODE=$?
    expect_exit "rejects a non numeric threshold" "$CODE" 1
fi
