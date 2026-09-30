# Agent Skills
![License](https://img.shields.io/github/license/MarvelCollin/agent-skills) ![Last commit](https://img.shields.io/github/last-commit/MarvelCollin/agent-skills) ![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-8A2BE2)

A growing set of skills for Claude Code, packaged as one plugin.

## Skills

| Skill | Usage | What it does |
|-------|-------|--------------|
| `/uiux` | `/uiux <url> [focus]` | Tests a website the way a real first-time user would and writes a scored UX report |

More skills are on the way.

## `/uiux`

```
/uiux https://your-site.com
```

One command runs 12 phases: first impression, navigation, core user flows, interactions, errors and edge cases, performance, responsive layout, WCAG accessibility, cookie consent and privacy, dark mode, 404 pages, and AI design slop. Every finding comes with a severity and evidence, and the report ends with the three fixes that pay off most.

### Modes

```
/uiux https://example.com                                  # full audit
/uiux https://example.com a11y AA                          # one focus area
/uiux https://example.com flow "sign up for an account"   # one user goal, step by step
/uiux https://example.com vs https://example.org           # head-to-head comparison
/uiux report                                               # compile findings from this session
```

### Focus Areas

| Focus | Tests |
|-------|-------|
| `nav` | Navigation and wayfinding |
| `flow` | Core user flows |
| `forms` | Forms and interactive elements |
| `errors` | Invalid input and edge cases |
| `perf` | Time to first byte, compression, caching, Lighthouse |
| `mobile` | Responsive layout and touch targets |
| `a11y [A\|AA\|AAA]` | WCAG audit with axe-core and a manual checklist |
| `privacy` | Cookie consent, trackers, privacy policy |
| `dark` | Dark mode and theming |
| `404` | Error pages |
| `slop [strict]` | 80+ patterns that make a site look AI-generated |

A persona name (`sarah`, `marcus`, `elena`, `david`, `aisha`, `tom`) runs the full audit as that persona.

### Requirements

- A browser tool: the [agent-browser](https://github.com/vercel-labs/agent-browser) CLI (recommended), the Claude desktop browser pane, or the Playwright MCP server
- `curl` or PowerShell for the performance check
- Node.js and Chrome for the axe-core and Lighthouse scans (optional)

## Installation

As a plugin:

```bash
claude plugin marketplace add MarvelCollin/agent-skills
claude plugin install agent-skills@agent-skills
```

Or copy a single skill into your personal skills folder:

```bash
git clone https://github.com/MarvelCollin/agent-skills
cp -r agent-skills/skills/uiux ~/.claude/skills/uiux
```

To try a local checkout without installing it:

```bash
claude --plugin-dir ./agent-skills
```

## Project Structure

```
.claude-plugin/
  plugin.json                 Plugin manifest
  marketplace.json            Marketplace entry so the repo can be installed directly
skills/
  ux/
    SKILL.md                  Entry point: modes, focus areas, 12 phases
    references/               Browser protocol, personas, rubric, heuristics,
                              flow test, accessibility, comparison, slop, report
    templates/                Report and flow test templates
    scripts/                  perf-check, axe-scan, lighthouse-audit (.sh + .ps1)
evals/                        Cases for claude plugin eval
tests/                        Unit tests for the scripts
```

## Development

Run the script tests. They start a local fixture server and use a fake `npx`, so they need Python 3 but no network or Chrome:

```bash
bash tests/run-tests.sh
```

Validate the manifests and skill frontmatter:

```bash
claude plugin validate .
```

Run the behavior evals. They drive a real browser against live sites, so start with one case:

```bash
claude plugin eval . --case report-without-data --allow-tools Bash WebFetch
```

## License

MIT
