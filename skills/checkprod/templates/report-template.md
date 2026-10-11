# Launch Check: {{project}}

**Date:** {{date}}
**Checked by:** agent-skills /checkprod
**Project:** {{path_or_none}}
**Live URL:** {{url_or_none}} ({{scope_local_remote_passive_or_remote_authorized}})
**Stack:** {{framework}}, backend {{backend}}

---

## Verdict

{{one_of_ready_to_launch_or_ready_after_the_blockers_or_not_ready}}

{{two_or_three_plain_sentences_saying_what_the_app_is_the_overall_state_the_most_serious_problem_and_the_first_fix}}

| Group | Pass | Fail | Warn | Manual | N/A |
|-------|------|------|------|--------|-----|
| Frontend FE1 to FE20 | {{n}} | {{n}} | {{n}} | {{n}} | {{n}} |
| Backend BE1 to BE20 | {{n}} | {{n}} | {{n}} | {{n}} | {{n}} |

---

## Blockers

{{one_line_per_blocker_with_the_item_what_is_wrong_where_and_the_fix_or_None}}

1. {{example BE1 hide API keys. NEXT_PUBLIC_STRIPE_SECRET_KEY is read in components/Checkout.jsx:9. Move the call to a server route and rotate the key}}

## Top Fixes

{{the_next_five_to_ten_fixes_after_the_blockers_ranked_by_impact_over_effort_with_the_item_ID_and_the_file_to_change}}

1. {{fix}}

---

## Frontend

| ID | Item | Status | Proof | Fix |
|----|------|--------|-------|-----|
| FE1 | Custom 404 page | {{status}} | {{file_and_line_or_prod_url_value_or_screenshot}} | {{fix_or_none}} |
| FE2 | CTA above the fold | {{status}} | {{proof}} | {{fix}} |
| FE3 | Meta title per page | {{status}} | {{proof}} | {{fix}} |
| FE4 | Meta description per page | {{status}} | {{proof}} | {{fix}} |
| FE5 | Open Graph image and share tags | {{status}} | {{proof}} | {{fix}} |
| FE6 | Favicon set | {{status}} | {{proof}} | {{fix}} |
| FE7 | robots.txt | {{status}} | {{proof}} | {{fix}} |
| FE8 | Sitemap | {{status}} | {{proof}} | {{fix}} |
| FE9 | Alt text on every image | {{status}} | {{proof}} | {{fix}} |
| FE10 | Mobile breakpoints | {{status}} | {{proof}} | {{fix}} |
| FE11 | Sticky mobile CTA | {{status}} | {{proof}} | {{fix}} |
| FE12 | Loading states | {{status}} | {{proof}} | {{fix}} |
| FE13 | Form error states | {{status}} | {{proof}} | {{fix}} |
| FE14 | Thank you page or success state | {{status}} | {{proof}} | {{fix}} |
| FE15 | Privacy policy in the footer | {{status}} | {{proof}} | {{fix}} |
| FE16 | Terms page in the footer | {{status}} | {{proof}} | {{fix}} |
| FE17 | Cookie banner when trackers load | {{status}} | {{proof}} | {{fix}} |
| FE18 | Analytics installed | {{status}} | {{proof}} | {{fix}} |
| FE19 | Real contact details, no placeholders | {{status}} | {{proof}} | {{fix}} |
| FE20 | Real domain, HTTPS, fast first load | {{status}} | {{proof}} | {{fix}} |

## Backend

| ID | Item | Status | Proof | Fix |
|----|------|--------|-------|-----|
| BE1 | Hide API keys | {{status}} | {{proof}} | {{fix}} |
| BE2 | RLS on every reachable table | {{status}} | {{proof}} | {{fix}} |
| BE3 | Test IDOR attacks | {{status}} | {{proof}} | {{hand_off_to_security}} |
| BE4 | Scan git history for secrets | {{status}} | {{commit_hashes_and_files_only_never_values}} | {{fix}} |
| BE5 | Lock admin routes | {{status}} | {{proof}} | {{fix}} |
| BE6 | Test user isolation | {{status}} | {{proof}} | {{hand_off_to_security}} |
| BE7 | Rate limit APIs | {{status}} | {{proof}} | {{fix}} |
| BE8 | Lock storage buckets | {{status}} | {{proof}} | {{fix}} |
| BE9 | Validate all inputs | {{status}} | {{proof}} | {{fix}} |
| BE10 | Block unauthenticated routes | {{status}} | {{proof}} | {{fix}} |
| BE11 | Test SQL injection | {{status}} | {{proof}} | {{hand_off_to_security}} |
| BE12 | Remove sensitive logs | {{status}} | {{proof}} | {{fix}} |
| BE13 | Block field tampering | {{status}} | {{proof}} | {{fix}} |
| BE14 | Restrict file uploads | {{status}} | {{proof}} | {{fix}} |
| BE15 | Secure server logic | {{status}} | {{proof}} | {{fix}} |
| BE16 | Trim API responses | {{status}} | {{proof}} | {{fix}} |
| BE17 | Secure auth sessions | {{status}} | {{proof}} | {{fix}} |
| BE18 | Scan dependencies | {{status}} | {{audit_command_and_its_result}} | {{fix}} |
| BE19 | Test record access | {{status}} | {{proof}} | {{hand_off_to_security}} |
| BE20 | Production config | {{status}} | {{proof}} | {{fix}} |

---

## Manual Checks Still Open

{{each_manual_item_with_exactly_what_to_look_at_where_and_who_can_confirm_it_or_None}}

## How This Was Checked

- Static scan: `prod-scan` on {{path}}, {{files_scanned}} files, {{leads}} leads read in context
- Live check: `prod-url` on {{url}}, {{requests}} requests, scope {{scope}}
- Audits: {{dependency_audit_command_and_secret_scanner_or_not_run_with_the_reason}}
- Browser: {{tool_and_pages_checked_at_375x812_and_1440x900_or_no_browser_tool}}
- Not done here: active attack tests (BE3, BE6, BE11, BE19). Run `/security` on a target you own or are authorized to test
