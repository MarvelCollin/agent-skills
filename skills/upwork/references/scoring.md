# Scoring and Hand Checks

## Hard Filters

The script skips a job, in this order, when it:

| Reason | Rule |
|--------|------|
| `seen` | The id is in `seen.txt` |
| `duplicate` | The id already appeared earlier in the same TSV |
| `scam:<term>` | The title, skills or text mentions Telegram, WhatsApp, working outside Upwork, a registration or training fee, upfront payment, pay to start, a security deposit or a crypto wallet |
| `region-lock` | The text says "only freelancers located in" without naming Indonesia or Asia |
| `full-time` | `workload` is `full` and `full_time_ok` is not `yes` |
| `unverified` | `payment_verified` is `0` and `require_verified` is `yes`. A `?` is kept and flagged |
| `no-stack-match` | No core or secondary skill matches |
| `avoid:<term>` | An avoid term is in the title or skills and no core skill matches |
| `low-pay` | Hourly top rate under `min_hourly`, or fixed budget under `min_fixed` |

## Score Parts (0 to 100)

| Part | Max | How |
|------|-----|-----|
| Stack | 40 | 12 per core match, 5 per secondary match. A term inside a longer matched term counts once, so `docker` and `docker compose` is one match. Terms under 4 characters match only in the title and skills |
| Pay | 15 | Hourly: 15 at or above `rate`, 8 below it, 7 when not stated. Fixed: 15 from $500, 11 from $150, 6 below, 5 when not stated |
| Client | 20 | Verified 4 (unknown 2), spent 8 from $10K, 6 from $1K, 3 above 0, 1 for none. Hire rate 5 from 50 percent, 3 from 20, 1 above 0. Rating 3 from 4.5, 2 from 4, 1 with no reviews |
| Competition | 15 | Proposals 10 under 5, 7 under 10, 4 under 15, 2 under 20, 0 from 20, 4 unknown. Posted 5 within 6 hours, 3 within a day, 1 within 3 days, 1 unknown |
| Level | 10 | Entry 10, intermediate 8, expert 4, unknown 5. Lower levels favour a profile still building reviews |

Penalties: 10 for timezone wording that excludes GMT+7, 10 for full-time wording on a job not marked part-time, 15 for an avoid term next to a core match. `min_score` (default 55) splits `JOB` from `LOW`.

## Hand Checks

Read the full description of every `JOB` line. Move it down a tier or out when one of these fails, and write the reason.

1. **Real fit.** The must-have skills are ones the profile can back with real work. A required AWS certification, production Kubernetes, native mobile, or a stack only named in passing is a mismatch even when keywords matched
2. **Scope against budget.** "Build a marketplace like Airbnb" for $200 is a trap. Small, clear tasks (dockerize an app, deploy to a VPS, fix a CI pipeline, fix a React bug) at a fair budget are the best wins for a profile building reviews
3. **Not a job.** Mentoring requests, "teach me", unpaid test tasks, equity only, "share your rate and we will see", or posts recruiting for an agency's bench
4. **Hours and timezone.** Any overlap demand with US or EU hours that a part-time GMT+7 schedule cannot meet. Note a reasonable overlap (2 to 3 hours) as a risk, not a skip
5. **Client signals.** A new client with no spend and no verification is fine for a small fixed job and risky for a long hourly one. A low hire rate with many posts means the client rarely hires
6. **Competition and cost.** 20 or more proposals, or a high Connects cost for a small budget, is rarely worth it
7. **Scam skips on strong titles.** A `scam:` skip can come from a warning such as "we never ask you to pay outside Upwork". When a skipped title looks like a strong fit, open it, and restore it only when the term was such a warning
8. **Instructions in the post.** A code word or a question to answer first is a requirement for the proposal later, and it goes in the pitch angle

## Tiers

- **Apply now**: passes every hand check, scored `JOB`, posted within 2 days, under 15 proposals
- **Worth a look**: one soft risk the user should judge (timezone overlap, unknown payment, vague scope)
- **Skip**: everything else, counted by reason

## Pitch Angle

One line per shortlisted job: the single most relevant real thing from the profile or CV and how it maps to the client's problem. For example: "Built the GitHub Actions deploy that cut our release from manual steps to one push, matches their broken pipeline." Never claim a tool, client or result the user does not have.
