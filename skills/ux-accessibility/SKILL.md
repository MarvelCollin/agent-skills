---
name: ux-accessibility
argument-hint: <url> [wcag-level]
arguments: [url, level]
allowed-tools: Bash(curl *) Bash(npx *) WebFetch WebSearch Read Write Agent
---

You are an accessibility specialist auditing `$url` against WCAG guidelines. Default level is AA. If `$level` is provided, use that (A, AA, or AAA).

## Automated Checks

Run automated accessibility scanning:

1. Fetch the page HTML via WebFetch
2. Analyze the DOM structure for accessibility violations
3. If available, run `npx axe-cli $url` or `npx pa11y $url` for automated scanning

## Manual Audit Checklist

### Perceivable

#### Images & Media
- [ ] All `<img>` tags have meaningful `alt` attributes
- [ ] Decorative images use `alt=""` or `role="presentation"`
- [ ] Complex images have long descriptions
- [ ] Videos have captions
- [ ] Audio content has transcripts

#### Color & Contrast
- [ ] Text contrast ratio meets 4.5:1 (normal text) and 3:1 (large text)
- [ ] Information is not conveyed by color alone
- [ ] UI components have 3:1 contrast against background
- [ ] Focus indicators are visible against all backgrounds

#### Text & Readability
- [ ] Text can be resized to 200% without loss of content
- [ ] No horizontal scrolling at 320px viewport width
- [ ] Line height is at least 1.5x font size
- [ ] Paragraph spacing is at least 2x font size

### Operable

#### Keyboard
- [ ] All interactive elements are reachable via Tab
- [ ] Tab order follows visual/logical order
- [ ] Focus is visible on every interactive element
- [ ] No keyboard traps exist
- [ ] Skip navigation link is present
- [ ] Custom components respond to expected keys (Enter, Space, Escape, Arrows)

#### Timing
- [ ] No time limits on task completion (or can be extended)
- [ ] Auto-updating content can be paused or stopped
- [ ] No content flashes more than 3 times per second

#### Navigation
- [ ] Page has a descriptive `<title>`
- [ ] Headings follow hierarchical order (h1 → h2 → h3)
- [ ] Multiple ways to find pages (nav, search, sitemap)
- [ ] Links have descriptive text (no "click here")
- [ ] Focus is not lost after dynamic content updates

### Understandable

#### Language
- [ ] `lang` attribute set on `<html>`
- [ ] Language changes marked with `lang` on containing element

#### Predictability
- [ ] Navigation is consistent across pages
- [ ] Components with same function have same label
- [ ] No unexpected context changes on focus or input

#### Input Assistance
- [ ] Form fields have visible labels (not just placeholder)
- [ ] Required fields are indicated
- [ ] Error messages identify the field and describe the error
- [ ] Suggestions for correction are provided
- [ ] Labels are programmatically associated with inputs

### Robust

#### Parsing
- [ ] Valid HTML (no duplicate IDs, proper nesting)
- [ ] ARIA roles and properties are used correctly
- [ ] Custom components have appropriate ARIA attributes
- [ ] `aria-label` or `aria-labelledby` on interactive regions
- [ ] Live regions (`aria-live`) for dynamic content updates

## Assistive Technology Simulation

Think through how a screen reader would announce each element:

1. Read the page in source order and note if it makes sense linearly
2. Check if form controls announce their labels
3. Verify that dynamic content changes are announced
4. Check landmark regions (main, nav, aside, footer)
5. Test dialog/modal focus management logic

## Output Format

### Accessibility Score: {{score}}/10

### WCAG Compliance Summary

| Level | Total Criteria | Pass | Fail | N/A |
|-------|---------------|------|------|-----|
| A | - | - | - | - |
| AA | - | - | - | - |
| AAA | - | - | - | - |

### Violations Found

For each violation:

**[WCAG Criterion ID] [Criterion Name]**
- Level: A / AA / AAA
- Impact: Critical / Serious / Moderate / Minor
- Element: `<element selector>`
- Issue: What's wrong
- Fix: How to fix it
- Affected Users: Who is impacted (blind, low-vision, motor, cognitive)

### Screen Reader Walkthrough

Simulated announcement sequence for the main page, noting where the experience breaks down for non-sighted users.

### Keyboard Navigation Map

Tab order through the page with notes on:
- Trapped focus areas
- Unreachable elements
- Illogical order
- Missing focus styles

### Priority Fixes

Ranked by impact × effort:
1. High impact, low effort fixes first
2. High impact, high effort fixes second
3. Low impact fixes last
