# User Testing Skills

Claude Code plugin for automated UX testing via agent-as-human simulation.

## Project Structure

```
.claude-plugin/plugin.json    Plugin manifest
skills/                       Skill definitions (each folder = one slash command)
  ux-tester/                  Full UX audit orchestrator
  ux-flow-test/               Single user flow tester
  ux-accessibility/           WCAG compliance auditor
  ux-compare/                 Head-to-head site comparison
  ux-report/                  Report compiler
scripts/                      Automation scripts (.sh + .ps1 variants)
evals/                        Test cases for skill evaluation
```

## Conventions

- Every skill MUST have a SKILL.md with valid YAML frontmatter
- Skills reference shared resources via relative markdown links
- All scripts have both bash (.sh) and PowerShell (.ps1) variants
- No code comments in scripts — keep them self-documenting via clear variable names
- Generated reports and artifacts go in .gitignore, never committed
- Personas, heuristics, and scoring rubrics live in ux-tester/ as shared resources
- Conventional commits: feat: fix: chore: refactor: docs: test:

## Skill Design Principles

- Skills act as human users, not automated bots
- Every finding needs severity + evidence (screenshot or specific observation)
- Scoring uses weighted rubric from scoring-rubric.md
- ux-tester orchestrates sub-skills, avoid duplicating logic across skills
- Browser interactions follow browser-protocol.md
- All skills support the agent-browser MCP tool and Playwright as fallback

## Testing Skills

Run evals with:
```
/ux-tester https://example.com
/ux-flow-test https://example.com "sign up for account"
/ux-accessibility https://example.com
/ux-compare https://site-a.com https://site-b.com
/ux-report
```
