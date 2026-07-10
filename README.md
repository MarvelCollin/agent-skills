# User Testing Skills

Claude Code plugin that acts as a human user to test websites for usability, UX quality, accessibility, performance, privacy, and user flow issues.

## Quick Start

```
/ux https://your-site.com
```

One command. Tests everything: navigation, flows, interactions, errors, performance, responsive, accessibility, privacy, dark mode, 404 pages, AI design slop. Produces a scored report with prioritized findings.

## All Skills

| Skill | Usage | Purpose |
|-------|-------|---------|
| `/ux` | `/ux <url> [focus]` | Full comprehensive UX audit |
| `/ux-flow-test` | `/ux-flow-test <url> "goal"` | Test a specific user flow |
| `/ux-accessibility` | `/ux-accessibility <url> [A\|AA\|AAA]` | WCAG compliance audit |
| `/ux-compare` | `/ux-compare <url1> <url2>` | Head-to-head comparison |
| `/ux-slop` | `/ux-slop <url> [strict]` | Detect AI-generated design patterns |
| `/ux-report` | `/ux-report [output-path]` | Compile findings into report |

## Focus Areas

Run `/ux` with a focus area for targeted deep-dives:

```
/ux https://example.com nav        # Navigation deep dive
/ux https://example.com mobile     # Responsive + touch targets
/ux https://example.com forms      # Form interactions
/ux https://example.com a11y       # Accessibility
/ux https://example.com privacy    # Cookie consent + GDPR
/ux https://example.com perf       # Performance
/ux https://example.com errors     # Error handling
/ux https://example.com dark       # Dark mode testing
/ux https://example.com 404        # Error pages
/ux https://example.com slop       # AI design slop detection
```

## Installation

```bash
claude plugin add ./
```

## Project Structure

```
.claude-plugin/plugin.json    Plugin manifest
skills/
  ux/                         Main orchestrator + shared resources
    SKILL.md                  12-phase comprehensive audit
    browser-protocol.md       Browser interaction rules
    personas.md               6 test personas
    scoring-rubric.md         8-category weighted scoring
    ux-heuristics.md          Nielsen's 10 + cognitive load
    templates/                Report and flow templates
  ux-flow-test/               Goal-based user flow simulation
  ux-accessibility/           WCAG A/AA/AAA auditor
  ux-compare/                 Side-by-side comparison
  ux-slop/                    AI design slop detector (80+ patterns)
  ux-report/                  Report compiler
scripts/                      Automation (bash + PowerShell)
evals/                        Skill evaluation test cases
```

## Scripts

| Script | Purpose |
|--------|---------|
| `lighthouse-audit.sh/.ps1` | Lighthouse performance + a11y scan |
| `axe-scan.sh/.ps1` | axe-core accessibility violations |
| `perf-check.sh/.ps1` | TTFB, compression, cache checks |
