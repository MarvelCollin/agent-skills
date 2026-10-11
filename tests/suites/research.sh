RESSCRIPTS="$ROOT/skills/research/scripts"
RESFIX="$ROOT/tests/fixtures/research"

research_absent() {
    local name="$1" output="$2" unexpected="$3"
    if printf '%s\n' "$output" | grep -qF -- "$unexpected"; then
        fail "$name: did not expect '$unexpected'" "$output"
    else
        pass "$name"
    fi
}

research_same() {
    local name="$1" first="$2" second="$3"
    if [ "$(printf '%s\n' "$first" | tail -n +2)" = "$(printf '%s\n' "$second" | tail -n +2)" ]; then
        pass "$name"
    else
        fail "$name" "$(diff <(printf '%s\n' "$first" | tail -n +2) <(printf '%s\n' "$second" | tail -n +2))"
    fi
}

research_cite_checks() {
    local label="$1" bad="$2" clean="$3" md="$4"
    expect_contains "$label reports offline mode" "$bad" "ONLINE: off"
    expect_contains "$label counts cited keys" "$bad" "CITED_KEYS: 14"
    expect_contains "$label counts bibliography entries" "$bad" "BIB_ENTRIES: 14"
    expect_contains "$label flags a cited key missing from the bibliography" "$bad" "MISSING_KEY missing2021 paper.tex:21: cited but not in any bibliography"
    expect_contains "$label flags an entry that is never cited" "$bad" "UNCITED unused2018 refs.bib:112: in the bibliography but never cited"
    expect_contains "$label flags an entry with no doi or url" "$bad" "NO_LOCATOR nolink2017 refs.bib:29: no doi, url, eprint or isbn"
    expect_contains "$label flags a missing year" "$bad" "MISSING_FIELD noyear refs.bib:90: missing year"
    expect_contains "$label flags a malformed doi" "$bad" "BAD_DOI badoi2020 refs.bib:96: 10.5555"
    expect_contains "$label flags a duplicate key" "$bad" "DUP_KEY chen2020 refs.bib:83: also defined at refs.bib:76"
    expect_contains "$label flags a duplicate doi regardless of case" "$bad" "DUP_DOI kim2022b refs.bib:52: same doi as kim2022"
    expect_contains "$label flags a likely duplicate title" "$bad" "DUP_TITLE smith2019b refs.bib:68: same title as smith2019a"
    expect_contains "$label counts every finding" "$bad" "FINDINGS: 8"
    expect_contains "$label counts each code" "$bad" "DUP_TITLE: 1"
    research_absent "$label ignores a citation inside a comment" "$bad" "commented2020"
    research_absent "$label ignores macro parameters" "$bad" "#1"
    research_absent "$label reads a citation split across lines" "$bad" "UNCITED kim2022 "
    research_absent "$label reads optional arguments before the keys" "$bad" "UNCITED oldyear "
    research_absent "$label leaves registry checks out of offline mode" "$bad" "DOI_CHECKED"
    expect_contains "$label reports nothing on a clean paper" "$clean" "FINDINGS: 0"
    expect_contains "$label counts the clean paper's keys" "$clean" "CITED_KEYS: 3"
    expect_contains "$label flags a missing pandoc key" "$md" "MISSING_KEY delta2022 survey.md:14: cited but not in any bibliography"
    expect_contains "$label flags an uncited entry next to markdown" "$md" "UNCITED epsilon2018 survey.bib:25: in the bibliography but never cited"
    expect_contains "$label reads pandoc keys in brackets and in text" "$md" "CITED_KEYS: 4"
    research_absent "$label ignores email addresses" "$md" "example"
    research_absent "$label ignores code blocks" "$md" "decorator"
    research_absent "$label ignores cross references" "$md" "fig:habits"
}

research_cite_online_checks() {
    local label="$1" online="$2" dead="$3"
    expect_contains "$label reports online mode" "$online" "ONLINE: on"
    expect_contains "$label checks each valid doi once" "$online" "DOI_CHECKED: 7"
    expect_contains "$label flags a doi the registry does not know" "$online" "DOI_NOT_FOUND fake2023 refs.bib:36: 10.5555/does.not.exist not found at Crossref"
    expect_contains "$label flags a title that does not match the registry" "$online" "TITLE_MISMATCH wrongtitle2020 refs.bib:21: Crossref title is \"Metric Learning for \"Few Shot\" Classification\""
    expect_contains "$label flags a year that does not match the registry" "$online" "YEAR_MISMATCH oldyear refs.bib:13: bib year 2015, Crossref year 2019"
    expect_contains "$label keeps the offline findings" "$online" "FINDINGS: 11"
    expect_contains "$label reports no failed requests" "$online" "DOI_UNCHECKED: 0"
    research_absent "$label allows one year between online and print" "$online" "YEAR_MISMATCH kim2022"
    research_absent "$label joins a registry subtitle to its title" "$online" "TITLE_MISMATCH subtitled2019"
    research_absent "$label strips markup from registry titles" "$online" "TITLE_MISMATCH smith2019a"
    research_absent "$label accepts a matching record" "$online" "good2021"
    expect_contains "$label reports an unreachable registry as unchecked" "$dead" "DOI_UNCHECKED solo research-solo.bib:1: request failed with status 000"
    expect_contains "$label counts the unchecked request" "$dead" "DOI_UNCHECKED: 1"
}

research_numbers_checks() {
    local label="$1" tex="$2" clean="$3" md="$4" txt="$5"
    expect_contains "$label finds the latex abstract" "$tex" "ABSTRACT: found"
    expect_contains "$label lists an abstract number with its sentence" "$tex" "NUM ABSTRACT paper.tex:12: 87.4% | Students who joined the program reached an average of 87.4\\% on the final exam and finished 12\\% faster."
    expect_contains "$label lists body numbers" "$tex" "NUM TEXT paper.tex:31: 85.2% |"
    expect_contains "$label lists table cells" "$tex" "NUM TABLE paper.tex:41: 85.2 |"
    expect_contains "$label lists caption numbers" "$tex" "NUM CAPTION paper.tex:35: 3 |"
    expect_contains "$label flags an abstract number found nowhere else" "$tex" "ABSTRACT_ONLY 87.4% paper.tex:12:"
    expect_contains "$label counts abstract only numbers" "$tex" "ABSTRACT_ONLY: 1"
    research_absent "$label matches abstract numbers within rounding" "$tex" "ABSTRACT_ONLY 12%"
    expect_contains "$label lists distinct sample sizes" "$tex" "SAMPLE_SIZES: 120 112"
    expect_contains "$label flags each sample size when they differ" "$tex" "SAMPLE_SIZE 112 paper.tex:31:"
    expect_contains "$label flags percentages that do not sum to 100" "$tex" "PCT_SUM 95 paper.tex:27:"
    expect_contains "$label counts all flags" "$tex" "FLAGS: 4"
    research_absent "$label skips the preamble" "$tex" "paper.tex:2:"
    research_absent "$label skips figure and table references" "$tex" "paper.tex:28:"
    expect_contains "$label reports nothing to flag on a clean paper" "$clean" "FLAGS: 0"
    expect_contains "$label keeps a single sample size quiet" "$clean" "SAMPLE_SIZES: 96"
    expect_contains "$label finds a markdown abstract" "$md" "NUM ABSTRACT survey.md:9: 62% |"
    expect_contains "$label reads markdown tables" "$md" "NUM TABLE survey.md:30: 62% |"
    expect_contains "$label flags percentages above 100" "$md" "PCT_SUM 110 survey.md:33:"
    research_absent "$label skips code blocks" "$md" "survey.md:20:"
    research_absent "$label skips list markers" "$md" "survey.md:23:"
    research_absent "$label skips front matter" "$md" "survey.md:2:"
    expect_contains "$label finds a plain text abstract" "$txt" "ABSTRACT: found"
    expect_contains "$label flags a plain text abstract number" "$txt" "ABSTRACT_ONLY 18% report.txt:4:"
    expect_contains "$label reads upper case N" "$txt" "SAMPLE_SIZES: 64 60"
    research_absent "$label skips the reference list" "$txt" "report.txt:13:"
    research_absent "$label skips numbered headings" "$txt" "report.txt:8:"
}

printf '%s\n' "@article{solo," "  author = {Solo, Han}," "  title = {Peer Feedback at Scale}," "  year = {2021}," "  doi = {10.5555/good.2021}" "}" >"$WORK/research-solo.bib"

"$PYTHON" - "$RESFIX/crossref" >"$WORK/research-port" <<'EOF' &
import http.server
import os
import sys

os.chdir(sys.argv[1])


class Quiet(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Quiet)
print(server.server_address[1], flush=True)
server.serve_forever()
EOF
RES_SERVER_PID=$!
for _ in $(seq 1 50); do
    [ -s "$WORK/research-port" ] && break
    sleep 0.1
done
RES_API="http://127.0.0.1:$(tr -d '\r\n' <"$WORK/research-port")"

echo "cite-check.sh"
RES_BAD=$(bash "$RESSCRIPTS/cite-check.sh" "$RESFIX/bad" 2>&1); CODE=$?
expect_exit "exits 0 when it finds problems" "$CODE" 0
RES_CLEAN=$(bash "$RESSCRIPTS/cite-check.sh" "$RESFIX/clean" 2>&1)
RES_MD=$(bash "$RESSCRIPTS/cite-check.sh" "$RESFIX/md" 2>&1)
research_cite_checks "it" "$RES_BAD" "$RES_CLEAN" "$RES_MD"
RES_ONLINE=$(CITE_CHECK_API="$RES_API" CITE_CHECK_DELAY=0 bash "$RESSCRIPTS/cite-check.sh" --online --mailto test@example.org "$RESFIX/bad" 2>&1); CODE=$?
expect_exit "exits 0 online" "$CODE" 0
RES_DEAD=$(CITE_CHECK_API="$DEAD" CITE_CHECK_DELAY=0 bash "$RESSCRIPTS/cite-check.sh" --online "$WORK/research-solo.bib" 2>&1)
research_cite_online_checks "it" "$RES_ONLINE" "$RES_DEAD"
OUT=$(bash "$RESSCRIPTS/cite-check.sh" "$WORK/research-nope" 2>&1); CODE=$?
expect_exit "fails on a missing path" "$CODE" 1
expect_contains "prints an error for a missing path" "$OUT" "ERROR:"
OUT=$(bash "$RESSCRIPTS/cite-check.sh" "$RESFIX/txt/report.txt" 2>&1); CODE=$?
expect_exit "fails on an unsupported file type" "$CODE" 1
expect_contains "names the supported file types" "$OUT" "ERROR:"
bash "$RESSCRIPTS/cite-check.sh" >/dev/null 2>&1; CODE=$?
expect_exit "fails without a path" "$CODE" 1
bash "$RESSCRIPTS/cite-check.sh" --fast "$RESFIX/bad" >/dev/null 2>&1; CODE=$?
expect_exit "fails on an unknown option" "$CODE" 1
bash "$RESSCRIPTS/cite-check.sh" "$RESFIX/bad" --mailto >/dev/null 2>&1; CODE=$?
expect_exit "fails when --mailto has no address" "$CODE" 1

echo "numbers-extract.sh"
RES_TEX=$(bash "$RESSCRIPTS/numbers-extract.sh" "$RESFIX/bad/paper.tex" 2>&1); CODE=$?
expect_exit "exits 0 when it flags numbers" "$CODE" 0
RES_NCLEAN=$(bash "$RESSCRIPTS/numbers-extract.sh" "$RESFIX/clean" 2>&1)
RES_NMD=$(bash "$RESSCRIPTS/numbers-extract.sh" "$RESFIX/md/survey.md" 2>&1)
RES_NTXT=$(bash "$RESSCRIPTS/numbers-extract.sh" "$RESFIX/txt" 2>&1)
research_numbers_checks "it" "$RES_TEX" "$RES_NCLEAN" "$RES_NMD" "$RES_NTXT"
expect_contains "scans a folder" "$RES_NTXT" "FILES_SCANNED: 1"
OUT=$(bash "$RESSCRIPTS/numbers-extract.sh" "$WORK/research-nope" 2>&1); CODE=$?
expect_exit "fails on a missing path" "$CODE" 1
expect_contains "prints an error for a missing path" "$OUT" "ERROR:"
OUT=$(bash "$RESSCRIPTS/numbers-extract.sh" "$RESFIX/bad/refs.bib" 2>&1); CODE=$?
expect_exit "fails on an unsupported file type" "$CODE" 1
expect_contains "prints an error for an unsupported file type" "$OUT" "ERROR:"
bash "$RESSCRIPTS/numbers-extract.sh" >/dev/null 2>&1; CODE=$?
expect_exit "fails without a path" "$CODE" 1

if [ -n "$POWERSHELL" ]; then
    echo "cite-check.ps1"
    PS_BAD=$(run_ps "$RESSCRIPTS/cite-check.ps1" -Path "$RESFIX/bad" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "exits 0 when it finds problems" "$CODE" 0
    PS_CLEAN=$(run_ps "$RESSCRIPTS/cite-check.ps1" -Path "$RESFIX/clean" 2>&1 | tr -d '\r')
    PS_MD=$(run_ps "$RESSCRIPTS/cite-check.ps1" -Path "$RESFIX/md" 2>&1 | tr -d '\r')
    research_cite_checks "it" "$PS_BAD" "$PS_CLEAN" "$PS_MD"
    research_same "matches the bash output on the planted paper" "$RES_BAD" "$PS_BAD"
    research_same "matches the bash output on markdown" "$RES_MD" "$PS_MD"
    PS_ONLINE=$(CITE_CHECK_API="$RES_API" CITE_CHECK_DELAY=0 run_ps "$RESSCRIPTS/cite-check.ps1" -Online -Mailto test@example.org -Path "$RESFIX/bad" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "exits 0 online" "$CODE" 0
    PS_DEAD=$(CITE_CHECK_API="$DEAD" CITE_CHECK_DELAY=0 run_ps "$RESSCRIPTS/cite-check.ps1" -Online -Path "$WORK/research-solo.bib" 2>&1 | tr -d '\r')
    research_cite_online_checks "it" "$PS_ONLINE" "$PS_DEAD"
    research_same "matches the bash output online" "$RES_ONLINE" "$PS_ONLINE"
    OUT=$(run_ps "$RESSCRIPTS/cite-check.ps1" -Path "$WORK/research-nope" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "fails on a missing path" "$CODE" 1
    expect_contains "prints an error for a missing path" "$OUT" "ERROR:"
    OUT=$(run_ps "$RESSCRIPTS/cite-check.ps1" -Path "$RESFIX/txt/report.txt" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "fails on an unsupported file type" "$CODE" 1
    expect_contains "names the supported file types" "$OUT" "ERROR:"
    run_ps "$RESSCRIPTS/cite-check.ps1" >/dev/null 2>&1; CODE=$?
    expect_exit "fails without a path" "$CODE" 1

    echo "numbers-extract.ps1"
    PS_TEX=$(run_ps "$RESSCRIPTS/numbers-extract.ps1" -Path "$RESFIX/bad/paper.tex" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "exits 0 when it flags numbers" "$CODE" 0
    PS_NCLEAN=$(run_ps "$RESSCRIPTS/numbers-extract.ps1" -Path "$RESFIX/clean" 2>&1 | tr -d '\r')
    PS_NMD=$(run_ps "$RESSCRIPTS/numbers-extract.ps1" -Path "$RESFIX/md/survey.md" 2>&1 | tr -d '\r')
    PS_NTXT=$(run_ps "$RESSCRIPTS/numbers-extract.ps1" -Path "$RESFIX/txt" 2>&1 | tr -d '\r')
    research_numbers_checks "it" "$PS_TEX" "$PS_NCLEAN" "$PS_NMD" "$PS_NTXT"
    research_same "matches the bash output on latex" "$RES_TEX" "$PS_TEX"
    research_same "matches the bash output on markdown" "$RES_NMD" "$PS_NMD"
    research_same "matches the bash output on plain text" "$RES_NTXT" "$PS_NTXT"
    OUT=$(run_ps "$RESSCRIPTS/numbers-extract.ps1" -Path "$WORK/research-nope" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "fails on a missing path" "$CODE" 1
    expect_contains "prints an error for a missing path" "$OUT" "ERROR:"
    OUT=$(run_ps "$RESSCRIPTS/numbers-extract.ps1" -Path "$RESFIX/bad/refs.bib" 2>&1 | tr -d '\r'); CODE=$?
    expect_exit "fails on an unsupported file type" "$CODE" 1
    run_ps "$RESSCRIPTS/numbers-extract.ps1" >/dev/null 2>&1; CODE=$?
    expect_exit "fails without a path" "$CODE" 1
fi

kill "$RES_SERVER_PID" 2>/dev/null || true
