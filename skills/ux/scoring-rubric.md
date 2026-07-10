# UX Scoring Rubric

## Severity Scale

| Level | Label | Impact |
|-------|-------|--------|
| 0 | Not a problem | No usability impact detected |
| 1 | Cosmetic | Minor visual inconsistency, fix when convenient |
| 2 | Minor | Users can work around it, causes slight friction |
| 3 | Major | Significant difficulty, users may fail at task |
| 4 | Critical | Users cannot complete the task, blocks core flow |

## Category Scoring (1-10)

### Navigation & Information Architecture
- 1-3: Users cannot find key features, navigation is broken or misleading
- 4-6: Navigation works but requires effort, some paths are unintuitive
- 7-8: Clear navigation with minor inconsistencies
- 9-10: Intuitive wayfinding, users always know where they are and how to get where they need

### Visual Design & Hierarchy
- 1-3: No clear hierarchy, elements compete for attention, illegible text
- 4-6: Basic hierarchy exists but inconsistent, some readability issues
- 7-8: Clean design with clear hierarchy, minor polish needed
- 9-10: Professional, purposeful design that guides the eye naturally

### Interaction Design
- 1-3: Buttons unclear, forms confusing, feedback absent
- 4-6: Interactions work but feel clunky or inconsistent
- 7-8: Smooth interactions with minor friction points
- 9-10: Delightful, responsive interactions that feel natural

### Content & Messaging
- 1-3: Confusing language, jargon-heavy, missing critical info
- 4-6: Understandable but could be clearer, some unnecessary content
- 7-8: Clear and concise with minor wording improvements possible
- 9-10: Perfect tone, scannable, every word earns its place

### Performance & Responsiveness
- 1-3: Unacceptable load times, janky animations, broken on mobile
- 4-6: Functional but sluggish, some responsive issues
- 7-8: Fast with minor performance hiccups, responsive design works
- 9-10: Instant feedback, smooth animations, perfect across devices

### Error Handling & Recovery
- 1-3: Silent failures, cryptic errors, no recovery path
- 4-6: Errors shown but unhelpful, some recovery options
- 7-8: Clear errors with suggestions, undo available for most actions
- 9-10: Proactive error prevention, graceful degradation, full recovery

### Accessibility
- 1-3: Inaccessible to assistive technology, no alt text, poor contrast
- 4-6: Basic accessibility but gaps in keyboard nav or screen reader support
- 7-8: WCAG AA compliant with minor issues
- 9-10: WCAG AAA compliant, inclusive design throughout

### Onboarding & Learnability
- 1-3: No guidance, steep learning curve, users left guessing
- 4-6: Some help available but gaps for new users
- 7-8: Good onboarding with minor improvements possible
- 9-10: Zero-friction start, progressive disclosure, instant productivity

## Overall Score Calculation

```
overall = (
  navigation * 0.15 +
  visual_design * 0.10 +
  interaction * 0.20 +
  content * 0.10 +
  performance * 0.15 +
  error_handling * 0.10 +
  accessibility * 0.10 +
  onboarding * 0.10
)
```

## Rating Bands

| Score | Rating | Verdict |
|-------|--------|---------|
| 9.0-10.0 | Exceptional | Ship-ready, delightful experience |
| 7.5-8.9 | Good | Solid experience with minor polish needed |
| 6.0-7.4 | Acceptable | Functional but notable friction areas |
| 4.0-5.9 | Below Average | Significant usability barriers exist |
| 2.0-3.9 | Poor | Major redesign needed for core flows |
| 0.0-1.9 | Unusable | Fundamental issues prevent task completion |
