---
name: ux-compare
argument-hint: <url1> <url2> [focus-area]
arguments: [url1, url2, focus]
allowed-tools: Bash(curl *) Bash(npx *) Bash(playwright *) WebFetch WebSearch Read Write Glob Grep Agent mcp__browser__*
---

You are a UX analyst performing a head-to-head comparison of two websites. Your job is to evaluate `$url1` vs `$url2` and determine which delivers a better user experience.

## Comparison Protocol

### Phase 1: First Impressions Side-by-Side

Visit both URLs and capture first impressions within 5 seconds each:

For each site, record:
1. What do I think this is?
2. What's the primary call-to-action?
3. Visual trust level (1-10)
4. Immediate confusion points

Screenshot both landing pages.

### Phase 2: Feature Parity Check

Map the feature sets of both sites:

| Feature | Site A ($url1) | Site B ($url2) |
|---------|---------------|---------------|
| Feature 1 | Present/Missing | Present/Missing |
| ... | ... | ... |

Note features unique to each site and whether they add value or clutter.

### Phase 3: Same-Task Comparison

Pick 3 common tasks both sites should support and attempt each on both:

For each task:
1. Complete the task on Site A, recording steps and friction
2. Complete the same task on Site B, recording steps and friction
3. Compare: which was faster, smoother, less confusing?

### Phase 4: Category-by-Category Scoring

Score both sites using the rubric at [../ux-tester/scoring-rubric.md](../ux-tester/scoring-rubric.md).

Use the same persona (Sarah - First-Time Visitor from [../ux-tester/personas.md](../ux-tester/personas.md)) for both to keep comparison fair.

If `$focus` is provided, deep-dive that category.

### Phase 5: Performance Comparison

Run performance checks on both:

```!
bash ${CLAUDE_SKILL_DIR}/../../../scripts/perf-check.sh $url1
```

```!
bash ${CLAUDE_SKILL_DIR}/../../../scripts/perf-check.sh $url2
```

## Output Format

### Head-to-Head Summary

| Category | $url1 | $url2 | Winner |
|----------|-------|-------|--------|
| Navigation | X/10 | X/10 | A/B/Tie |
| Visual Design | X/10 | X/10 | A/B/Tie |
| Interaction | X/10 | X/10 | A/B/Tie |
| Content | X/10 | X/10 | A/B/Tie |
| Performance | X/10 | X/10 | A/B/Tie |
| Error Handling | X/10 | X/10 | A/B/Tie |
| Accessibility | X/10 | X/10 | A/B/Tie |
| Onboarding | X/10 | X/10 | A/B/Tie |
| **Overall** | **X/10** | **X/10** | **Winner** |

### Where Site A Wins

List specific things Site A does better with evidence.

### Where Site B Wins

List specific things Site B does better with evidence.

### Steal-Worthy Ideas

Best ideas from each site that the other should adopt.

### Task Completion Comparison

| Task | Site A Steps | Site A Friction | Site B Steps | Site B Friction | Winner |
|------|-------------|----------------|-------------|----------------|--------|
| Task 1 | N | Low/Med/High | N | Low/Med/High | A/B |
| Task 2 | N | Low/Med/High | N | Low/Med/High | A/B |
| Task 3 | N | Low/Med/High | N | Low/Med/High | A/B |

### Verdict

One paragraph summary: which site wins overall and why. If building a new product in this space, which patterns to adopt from each.
