# UX Heuristics Evaluation Framework

## Nielsen's 10 Usability Heuristics

### H1: Visibility of System Status
- Does the system show loading states?
- Are progress indicators present for long operations?
- Does the user know where they are in the navigation?
- Are success/error states clearly communicated?

### H2: Match Between System and Real World
- Does the language match what users would expect?
- Are icons intuitive and recognizable?
- Does the information flow in a logical order?
- Are domain-specific terms explained or avoided?

### H3: User Control and Freedom
- Can users undo actions easily?
- Is there a clear way to go back?
- Can users cancel in-progress operations?
- Are there emergency exits from complex flows?

### H4: Consistency and Standards
- Are similar elements styled the same way?
- Do buttons behave consistently across pages?
- Does the site follow platform conventions?
- Are labels and terminology consistent?

### H5: Error Prevention
- Are destructive actions confirmed before execution?
- Does the UI prevent invalid input where possible?
- Are form fields validated inline?
- Are constraints communicated before the user hits them?

### H6: Recognition Rather Than Recall
- Are options visible rather than hidden in memory?
- Are recent items and suggestions shown?
- Is contextual help available where needed?
- Are labels always visible (not just placeholder text)?

### H7: Flexibility and Efficiency of Use
- Are there keyboard shortcuts for power users?
- Can frequent actions be done quickly?
- Are there customization options?
- Do advanced features stay out of the way for beginners?

### H8: Aesthetic and Minimalist Design
- Is the interface free of unnecessary information?
- Is visual hierarchy clear?
- Does every element serve a purpose?
- Is whitespace used effectively?

### H9: Help Users Recognize, Diagnose, and Recover from Errors
- Are error messages in plain language?
- Do errors explain what went wrong?
- Do errors suggest how to fix the problem?
- Are errors shown near the relevant field?

### H10: Help and Documentation
- Is help easily accessible?
- Is documentation searchable?
- Are instructions task-oriented?
- Is onboarding present for new users?

## Cognitive Load Assessment

### Intrinsic Load
- How complex is the core task?
- How many decisions does the user need to make?
- How many items need to be held in working memory?

### Extraneous Load
- Is there unnecessary visual noise?
- Are there distracting animations or auto-playing media?
- Is the layout causing confusion about what to read first?

### Germane Load
- Does the interface help build mental models?
- Are patterns learnable and transferable?
- Does progressive disclosure work effectively?

## Interaction Cost Matrix

| Action | Low Cost | Medium Cost | High Cost |
|--------|----------|-------------|-----------|
| Click/Tap | Single target, large area | Small target, precise aim | Hidden target, hover-reveal |
| Read | Short, scannable | Medium paragraph | Dense wall of text |
| Scroll | Minimal, above fold | One page length | Infinite scroll without anchor |
| Think | Obvious next step | Some deliberation | Confusion about what to do |
| Wait | Instant (<100ms) | Noticeable (100ms-1s) | Frustrating (>1s) |
| Navigate | Direct link | 2-3 clicks | Deep buried path |
| Input | Auto-filled, minimal | Standard form | Complex multi-step input |

## Performance Perception Thresholds

| Duration | User Perception |
|----------|----------------|
| 0-100ms | Instant |
| 100-300ms | Slight delay, still feels responsive |
| 300ms-1s | Noticeable lag, needs loading indicator |
| 1-5s | Frustrating, needs progress bar |
| 5-10s | Attention lost, needs explanation |
| 10s+ | Abandoned unless high motivation |
