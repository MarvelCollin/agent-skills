# Agent Skills

Claude Code plugin that bundles a growing set of skills. Each skill lives in its own folder under `skills/` and becomes one slash command.

## Project Structure

```
.claude-plugin/plugin.json       Plugin manifest
.claude-plugin/marketplace.json  Marketplace entry for installing from GitHub
skills/uiux/                     /uiux UI build rules, UI review and UX audit
skills/security/                 /security authorized security review and code review
skills/backend/                  /backend build rules, backend review and load testing
  SKILL.md                       Entry point (each skill)
  references/                    Loaded on demand by SKILL.md
  templates/                     Report templates
  scripts/                       Helper scripts (.sh + .ps1 pairs)
evals/<case>/                    claude plugin eval cases (prompt.md + graders/)
tests/                           Script unit tests, fixture server, fake npx
```

## Conventions

- Every skill has a SKILL.md with `name`, `description` and `when_to_use` frontmatter
- A skill keeps everything it needs inside its own folder so it also works when copied to `~/.claude/skills/`
- `${CLAUDE_SKILL_DIR}` only expands inside SKILL.md. Reference files write `<skill-dir>` instead
- Do not use `!` command injection for anything that can fail. A failing injected command aborts the whole skill
- Every script has a bash (.sh) and a PowerShell (.ps1) variant with the same output keys
- Frontmatter values that start with `[`, `{` or contain `: ` must be quoted, or the whole frontmatter silently fails to parse. Check with `claude --plugin-dir . plugin details agent-skills` (always-on cost near 20 tokens means it failed)
- Scripts print `ERROR:` to stderr and exit 1 on failure. Never fail silently
- No comments in code
- Generated reports and scan output are gitignored, never committed
- Commit messages are one line starting with feat: or fix:

## /uiux Design Principles

- Build mode hard rules R1 to R11 live in `skills/uiux/references/build-rules.md`. Keep `scripts/rule-scan.*` in sync when a rule changes
- No semicolons or em dashes in anything the skill tells Claude to write, and none in the skill's own prose

## /security Principles

- Authorization first. No active testing before a scope is on file and the target is confirmed in it. `scope-check.*` enforces this. Local and own builds are the default authorized case
- Only targets the user owns or is authorized to test. Never help evade detection, target at scale, run DoS, or attack third parties
- Methodology-driven (OWASP WSTG, ASVS, CWE), lightest-touch proof, no destructive payloads
- Every finding needs evidence and real impact (six validation gates) before it ships
- Act as a human user, not a bot
- Every finding needs a severity and evidence (screenshot or specific observation)
- Scoring uses the weighted rubric in `skills/uiux/references/scoring-rubric.md`
- Browser interactions follow `skills/uiux/references/browser-protocol.md`
- Never submit real purchases, payments or messages during a test

## /backend Principles

- Build mode hard rules B1 to B15 live in `skills/backend/references/build-rules.md`. Each rule names its `backend-scan` checks. Keep `scripts/backend-scan.*` and the scan tags in sync when a rule changes
- Topic depth lives in `skills/backend/references/topics/`, one file per area. SKILL.md maps topic words to files
- Checklist mode (`references/checklist.md`) stress tests first and ranks fixes by the measured bottleneck. Keep its items in sync with the build rules and the topic files they link to
- Scan output is leads, not findings. A finding needs a reachable path, real impact, evidence and a concrete fix (five gates in `references/review.md`)
- Measure before and after. Query counts, EXPLAIN plans, traces and load numbers beat opinions
- Load tests only against targets the user owns or is authorized to test. Local and private hosts are the default. `load-test.*` refuses remote hosts without `--authorized` and a rate cap. Never load test third parties
- Same copy rule as the other skills: no semicolons or em dashes in prose or reports. Code examples follow the target project's style

## Checks

```
bash tests/run-tests.sh
claude plugin validate .
claude plugin eval . --case <name> --allow-tools Bash WebFetch
```
