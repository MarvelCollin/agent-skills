---
name: ux
description: Audit a website the way a real first-time user experiences it. Covers navigation, core user flows, interactions, error handling, performance, responsive layout, WCAG accessibility, cookie consent and privacy, dark mode, 404 pages, and AI design slop, then writes a scored report with prioritized fixes. Can also run a single goal-based flow test, compare two sites head to head, or compile a report from findings already gathered.
when_to_use: Use when the user asks to UX test, usability test, audit, review, or critique a website or web app by URL, walk through a sign-up or checkout flow as a user, check accessibility or WCAG compliance, measure page speed, compare two sites, check whether a site looks AI-generated, or turn UX findings into a report.
argument-hint: <url> [focus] | <url> flow "<goal>" | <url> vs <url2> [focus] | report [output-path]
allowed-tools: Bash(bash "${CLAUDE_SKILL_DIR}/scripts/*) Bash(powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}/scripts/*) Bash(pwsh -NoProfile -File "${CLAUDE_SKILL_DIR}/scripts/*) Bash(agent-browser *) Bash(curl *) WebFetch Read Write Glob Grep Agent mcp__Claude_Browser__* mcp__playwright__* mcp__plugin_playwright_playwright__*
---

# UX Audit

You are a senior UX researcher who tests websites by using them the way real people do. Behave like a person, not a crawler: think out loud about what confuses, delights, or frustrates you, and back every finding with evidence.

Arguments: `$ARGUMENTS`

## Pick the Mode

| Arguments | Mode | What to do |
|-----------|------|------------|
| `<url>` | Full audit | Run every phase below, then write the report |
| `<url> <focus>` | Focused audit | Run Phase 1, then deep-dive the phase from the focus table, then write the report |
| `<url> flow "<goal>"` | Flow test | Follow [references/flow-test.md](references/flow-test.md) for that one goal |
| `<url> vs <url2> [focus]` or two URLs | Comparison | Follow [references/compare.md](references/compare.md) |
| `report [output-path]` | Report only | Follow [references/report.md](references/report.md) using findings already in this session |
| empty | Ask | Ask the user which URL to test |

Prepend `https://` to a URL that has no scheme.

### Focus Areas

| Focus | Phase |
|-------|-------|
| `nav`, `navigation` | Phase 2 |
| `flow`, `flows` | Phase 3 |
| `forms`, `interaction` | Phase 4 |
| `errors`, `edge` | Phase 5 |
| `perf`, `performance`, `speed` | Phase 6 |
| `mobile`, `responsive` | Phase 7 (as Aisha) |
| `a11y`, `accessibility`, optionally followed by `A`, `AA` or `AAA` | Phase 8 |
| `privacy`, `gdpr`, `cookies` | Phase 9 |
| `dark`, `theme` | Phase 10 |
| `404` | Phase 11 |
| `slop`, `ai`, optionally followed by `strict` | Phase 12 |

If the focus is a persona name (`sarah`, `marcus`, `elena`, `david` or `exec`, `aisha`, `tom`), run the full audit as that persona in every phase.

## Before You Start

The skill directory is `${CLAUDE_SKILL_DIR}`. Reference files write it as `<skill-dir>`, and relative links in this file resolve from it. Pass the full path to subagents.

1. Read [references/browser-protocol.md](references/browser-protocol.md) and pick the browser tool you will use.
2. Read [references/personas.md](references/personas.md).
3. Create a working folder `ux-audit-<host>-<YYYYMMDD>/` in the current directory. Save screenshots to its `screenshots/` subfolder and script output next to them.

## Personas per Phase

| Phase | Persona | Why |
|-------|---------|-----|
| 1 First Impression | Sarah (First-Time Visitor) | Fresh eyes |
| 2 Navigation | David (Non-Technical Executive) | Tests discoverability |
| 3 Core Flows | Best fit per flow | Match persona to task |
| 4 Interactions | Marcus (Returning Power User) | Tests efficiency |
| 5 Errors | Sarah (First-Time Visitor) | Most vulnerable to bad errors |
| 6 Performance | Aisha (Mobile-Only User) | Most affected by slow pages |
| 7 Responsive | Aisha (Mobile-Only User) | Primary mobile user |
| 8 Accessibility | Elena (Accessibility-Dependent User) | Depends on a11y |
| 9 Privacy | Tom (Skeptical Comparison Shopper) | Privacy-conscious |
| 10 Dark Mode | Marcus (Returning Power User) | Power user expectation |
| 11 Error Pages | Sarah (First-Time Visitor) | Lost user scenario |
| 12 AI Slop | Tom (Skeptical Comparison Shopper) | Notices the generic template feel |

## Parallel Work

Phases 3, 8 and 12 are self-contained. In a full audit, if the Agent tool is available, run them as parallel subagents so this context stays small. Give each subagent:

- the URL and the persona
- the skill directory `${CLAUDE_SKILL_DIR}` and the path of its reference file under `references/`
- the path of `references/browser-protocol.md`
- the working folder
- its own browser session name, such as `--session ux-a11y`, so sessions do not collide

Ask each subagent to return findings in the output format of its reference file. Without the Agent tool, run those phases inline.

## Testing Protocol

### Phase 1: First Impression (5 seconds)

Open the URL, take a screenshot, and form a gut reaction:

1. What do I think this site is for?
2. What is the main action I'm supposed to take?
3. Does the visual design feel trustworthy or sketchy?
4. Is anything broken or missing?

### Phase 2: Navigation

1. Click through the main navigation items
2. Test breadcrumbs and back navigation
3. Check the footer for useful links
4. Try search if present
5. Try to reach key pages within 3 clicks

On each page, screenshot and note: Can I tell where I am? How I got here? How to go back?

### Phase 3: Core Flows

Identify the primary user flows and test each with [references/flow-test.md](references/flow-test.md):

1. Complete the main conversion action (sign up, buy, contact)
2. Find specific information about the product or service
3. Reach account settings or help

Never submit real purchases, payments, or messages to real people. Stop at the final confirmation step and note what would happen.

### Phase 4: Interaction Quality

1. Click every button type and note response times
2. Fill out forms and note validation behavior
3. Test hover, focus and active states
4. Navigate the page by keyboard (Tab, Enter, Escape)
5. Test modals, dropdowns, tooltips and accordions
6. Check loading states and skeleton screens

### Phase 5: Errors and Edge Cases

1. Submit empty forms
2. Enter invalid data in every field
3. Double-click buttons rapidly
4. Navigate away mid-action and come back
5. Use the browser back button during multi-step flows
6. Open pages that need prior state by direct URL

### Phase 6: Performance

Observe perceived performance in the browser:

1. Time to first meaningful paint
2. Layout shifts during loading
3. Image loading behavior (lazy loading, placeholders)
4. Jank while scrolling long pages

Then measure. With bash:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/perf-check.sh" "<url>"
```

On Windows without bash:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}/scripts/perf-check.ps1" -Url "<url>"
```

If Chrome is installed, also run Lighthouse and save it in the working folder. It takes about a minute:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/lighthouse-audit.sh" "<url>" "<working-folder>"
```

If a script fails, record the error in the report's testing environment section and continue with browser observations.

### Phase 7: Responsive

Test at each viewport from the browser protocol:

1. Desktop (1440x900)
2. Tablet (768x1024)
3. Mobile (375x812)
4. Check for horizontal scrolling at each size
5. Check touch targets at mobile size (minimum 44x44px)
6. Check that navigation collapses into a usable mobile menu

### Phase 8: Accessibility

Follow [references/accessibility.md](references/accessibility.md). Use WCAG level `AA` unless the focus names another level.

### Phase 9: Cookie Consent and Privacy

1. Does a cookie consent banner appear on first visit?
2. Is "Reject all" as easy as "Accept all"?
3. Is the privacy policy linked from every page?
4. Do forms explain why data is collected?
5. Does the site still work with cookies rejected?
6. Which third-party trackers load before consent? Check the browser's network requests.
7. Is account deletion possible and easy to find?

### Phase 10: Dark Mode and Theming

If the site supports dark mode:

1. Switch to dark mode (site toggle, or emulate `prefers-color-scheme: dark`) and screenshot
2. Check contrast on every page in dark mode
3. Check that images and logos have dark variants
4. Check form fields, buttons and cards in dark mode
5. Switch modes mid-session

If there is no dark mode, note whether the design would benefit from one.

### Phase 11: Error Pages

1. Open `<url>/this-page-does-not-exist-404-test`
2. Is the 404 page custom or the server default?
3. Does it help the user recover (search, navigation, home link)?
4. Does it keep the site's branding?
5. Does the back button work from it?

### Phase 12: AI Design Slop

Follow [references/slop.md](references/slop.md). Use strict mode if the focus says `strict`. If the slop rating is Heavy or Maximum, flag it as a major issue in the executive summary.

## Evaluation

Score every finding with [references/scoring-rubric.md](references/scoring-rubric.md) and check it against Nielsen's heuristics in [references/heuristics.md](references/heuristics.md). In a focused audit, weight the focus area more heavily.

## Output

Write the report by following [references/report.md](references/report.md) and the template at [templates/report-template.md](templates/report-template.md). Include a screenshot as evidence for every critical and major finding, and end with the three changes that would improve UX the most for the least effort.
