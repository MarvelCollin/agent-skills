# Agent Skills

Claude Code plugin that bundles a growing set of skills. Each skill lives in its own folder under `skills/` and becomes one slash command.

## Project Structure

```
.claude-plugin/plugin.json       Plugin manifest
.claude-plugin/marketplace.json  Marketplace entry for installing from GitHub
skills/ux/                       /ux website UX audit
  SKILL.md                       Entry point, modes, phases
  references/                    Loaded on demand by SKILL.md
  templates/                     Report and flow test templates
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
- Scripts print `ERROR:` to stderr and exit 1 on failure. Never fail silently
- No comments in code
- Generated reports and scan output are gitignored, never committed
- Conventional commits: feat: fix: chore: refactor: docs: test:

## /ux Design Principles

- Act as a human user, not a bot
- Every finding needs a severity and evidence (screenshot or specific observation)
- Scoring uses the weighted rubric in `skills/ux/references/scoring-rubric.md`
- Browser interactions follow `skills/ux/references/browser-protocol.md`
- Never submit real purchases, payments or messages during a test

## Checks

```
bash tests/run-tests.sh
claude plugin validate .
claude plugin eval . --case <name> --allow-tools Bash WebFetch
```
