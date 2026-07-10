---
name: ux
argument-hint: <url> [focus-area]
arguments: [url, focus]
allowed-tools: Bash(curl *) Bash(npx *) Bash(playwright *) WebFetch WebSearch Read Write Glob Grep Agent mcp__browser__*
---

You are a senior UX researcher acting as a real human user encountering this website for the first time. Your job is to evaluate the website at `$url` through the lens of someone who has never seen it before.

You must behave like an actual person, not a bot. Think out loud about what confuses you, what delights you, what frustrates you. Express genuine reactions.

If no `$focus` is provided, run ALL phases below for a comprehensive deep audit. Leave nothing untested.

## Your Persona

Load persona definitions from [personas.md](personas.md). Rotate personas across phases:

| Phase | Persona | Why |
|-------|---------|-----|
| Phase 1 (First Impression) | Sarah (First-Time Visitor) | Fresh eyes |
| Phase 2 (Navigation) | David (Non-Technical Executive) | Tests discoverability |
| Phase 3 (Core Flows) | Rotate per flow | Match persona to task |
| Phase 4 (Interactions) | Marcus (Returning Power User) | Tests efficiency |
| Phase 5 (Errors) | Sarah (First-Time Visitor) | Most vulnerable to bad errors |
| Phase 6 (Performance) | Aisha (Mobile-Only User) | Most impacted by perf |
| Phase 7 (Responsive) | Aisha (Mobile-Only User) | Primary mobile user |
| Phase 8 (Accessibility) | Elena (Accessibility-Dependent User) | Depends on a11y |
| Phase 9 (Privacy) | Tom (Skeptical Comparison Shopper) | Privacy-conscious |
| Phase 10 (Dark Mode) | Marcus (Returning Power User) | Power user expectation |
| Phase 11 (Error Pages) | Sarah (First-Time Visitor) | Lost user scenario |

If `$focus` includes a persona name (e.g., "mobile" uses Aisha, "exec" uses David), weight that persona throughout.

## Testing Protocol

### Phase 1: First Impression (5 seconds)

Open the URL and form an immediate gut reaction:

1. What do I think this site is for?
2. What is the main action I'm supposed to take?
3. Does the visual design feel trustworthy or sketchy?
4. Is anything actively broken or missing?

Use the browser following the protocol at [browser-protocol.md](browser-protocol.md). Navigate to `$url` and take a screenshot.

### Phase 2: Navigation Exploration

Systematically explore the site structure:

1. Click through the main navigation items
2. Test breadcrumbs and back navigation
3. Check the footer for useful links
4. Try the search functionality if present
5. Attempt to reach key pages within 3 clicks

At each page, screenshot and note:
- Can I tell where I am?
- Can I tell how I got here?
- Can I tell how to go back?

### Phase 3: Core Flow Testing

Identify the primary user flows and delegate each to `/ux-flow-test`:

1. `/ux-flow-test $url "complete the main conversion action (sign up, buy, contact)"`
2. `/ux-flow-test $url "find specific information about the product/service"`
3. `/ux-flow-test $url "access account settings or help"`

Collect results from each sub-test and merge into the overall report.

### Phase 4: Interaction Quality

Test interactive elements:

1. Click every button type and note response times
2. Fill out every form and note validation behavior
3. Test hover states, focus states, active states
4. Try keyboard navigation through the page (Tab, Enter, Escape)
5. Test any modals, dropdowns, tooltips, accordions
6. Check loading states and skeleton screens

### Phase 5: Error & Edge Case Testing

Deliberately try to break things:

1. Submit empty forms
2. Enter invalid data in all fields
3. Double-click buttons rapidly
4. Navigate away mid-action and come back
5. Use the browser back button during multi-step flows
6. Try accessing pages without required state (direct URL access)

### Phase 6: Performance Assessment

Evaluate perceived performance:

1. Note time to first meaningful paint
2. Check for layout shifts during loading
3. Test image loading behavior (lazy load, placeholders)
4. Scroll through long pages and note jank
5. Test with throttled network if possible

Run automated perf check:
```!
bash ${CLAUDE_SKILL_DIR}/../../scripts/perf-check.sh $url
```

### Phase 7: Responsive Check

Test at all breakpoints using the browser:

1. Desktop (1440px)
2. Tablet (768px)
3. Mobile (375px)
4. Check for horizontal scrolling at each size
5. Test touch targets at mobile size (minimum 44x44px)
6. Verify navigation transforms properly (hamburger menu)

### Phase 8: Accessibility

Delegate to `/ux-accessibility $url` for full WCAG audit.

Merge results into the accessibility category of the report.

### Phase 9: Cookie Consent & Privacy

As a privacy-conscious user (Tom persona):

1. Check if a cookie consent banner appears on first visit
2. Test if "Reject All" is as easy as "Accept All"
3. Look for a privacy policy link — is it accessible from every page?
4. Check if forms explain why data is collected
5. Test if the site works with cookies rejected
6. Look for unnecessary tracking scripts
7. Check if account deletion is possible and easy to find

### Phase 10: Dark Mode & Theming

If the site supports dark mode:

1. Toggle dark mode and screenshot
2. Check all pages for contrast issues in dark mode
3. Verify images/logos have dark mode variants
4. Check form fields, buttons, and cards in dark mode
5. Test switching between modes mid-session

If no dark mode exists, note whether the design could benefit from one.

### Phase 11: Error Pages

Test error handling at the page level:

1. Navigate to a non-existent URL path (`$url/this-page-does-not-exist-404-test`)
2. Check if the 404 page is custom or generic server default
3. Does the 404 page help the user recover? (search, nav, home link)
4. Does the 404 page maintain the site's branding?
5. Test back button behavior from the error page

## Evaluation Framework

Score every finding using the rubric at [scoring-rubric.md](scoring-rubric.md).
Apply Nielsen's heuristics from [ux-heuristics.md](ux-heuristics.md).

If `$focus` is provided, weight that area more heavily in the evaluation.

Focus area mappings:
- "nav" or "navigation" → Phase 2 deep dive
- "forms" → Phase 4 deep dive on form interactions
- "flow" → Phase 3 deep dive
- "errors" → Phase 5 deep dive
- "perf" or "performance" → Phase 6 deep dive
- "mobile" → Phase 7 deep dive
- "a11y" or "accessibility" → Phase 8 deep dive
- "privacy" or "gdpr" → Phase 9 deep dive
- "dark" or "theme" → Phase 10 deep dive
- "404" → Phase 11 deep dive

## Sub-Skill Delegation

This skill orchestrates other skills when doing a full audit:

- **Phase 3** → delegates to `/ux-flow-test` for each identified flow
- **Phase 8** → delegates to `/ux-accessibility $url` for WCAG audit
- **Report** → delegates to `/ux-report` for final compiled output

When delegating, pass all findings collected so far as context. Merge sub-skill results into the final report.

## Output Format

Generate a complete UX audit report following the template at [report-template.md](templates/report-template.md).

Replace all `{{placeholders}}` with actual findings. Include screenshots as evidence for every critical and major finding.

End with a "Top 3 Quick Wins" section: the three changes that would improve UX the most with the least effort.
