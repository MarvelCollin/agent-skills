# UI Review

Run this after building or changing UI, and whenever the user asks `/uiux review`. It answers three questions with evidence: Is it easy to use? Is it nice to use? Is the navigation good?

Fix every hard-rule violation you find before you report. Only report what you could not fix or what needs a decision from the user.

## 1. Scan the Code

Run the rule scan on the files you created or changed (see the end of [build-rules.md](build-rules.md)). For each finding, open the line and decide:
- **Real:** fix it, then scan again
- **False positive:** note why in one line

## 2. Use the UI

If the UI can run (a dev server, a static file, a preview), open it with a browser tool from [browser-protocol.md](browser-protocol.md). Otherwise review the rendered markup and styles, and say that the review was static.

1. Screenshot at 1440x900 and 375x812
2. Pick the 2 or 3 main tasks the UI exists for. Do each one as the best-fit persona from [personas.md](personas.md). Count steps, note hesitations and errors
3. Tab through the screen with the keyboard only. Check focus order, visible focus, and that every custom control works with its APG keys
4. Trigger every state you built: empty, loading, error, success, disabled, long text, many rows
5. For tables: search, filter every column, sort, clear filters, reload, and check that the filters survive
6. For overlays: open each one with short and long content and check that it sizes itself and scrolls only its body
7. For speed (R10): load tables and lists against a large dataset. Check the network panel: one page per request with paging, sort and filter parameters, never the whole dataset. Throttle the network and confirm skeletons appear with no layout jump. Type in search and confirm it debounces and queries the server
8. For avatars (R11): view users with and without photos. No initials circles
9. Squint at the screenshot and view it in grayscale (see the checks in [color.md](color.md))
10. For form overlays (R14): open every modal, drawer and sheet that holds a form, fill it with the longest realistic content, and shrink the window to 700px tall. The title and the action buttons stay visible, only the body scrolls, there is one scrollbar, fields in a row line up, and there is no empty space under a field or after the last one
11. For code structure (R12, R13): compare every new file's name, folder and style with the conventions report, and check that types, server calls, hooks and components each sit in their own files
12. For AI template tells (R15): go down the R15 table row by row on the screenshots. Hover every card, button and link. Look for sparkles, check bullets, dot grids, orbs, glass, fake terminals, three pricing tiers, invented testimonials and the default fonts
13. For launch readiness (R16): on each public page check the main action is visible at 375 and 1440 without scrolling, scroll a long page on mobile and find the sticky action, read the page title, description and share tags in the head, open a made up URL and check the 404 page and its status code, submit each form wrong and then right, and read the footer for privacy, terms and real contact details
14. For forms (R17): run the alignment check in [form-layout.md](form-layout.md) on every form at 1440 and 375 wide, once clean and once after a submit with errors, until it prints `ALIGNED`. Then look at the screenshot: labels, controls, checkboxes and buttons share one left edge and controls in a row share one height
15. For motion (R18): open every menu, popover, modal, drawer, toast and accordion, run the motion check from [motion.md](motion.md) right after each opens, and record one Performance trace with 4x CPU throttling. Repeat with reduced motion emulated
16. For screen fit (R19): screenshot every app screen at 1440x900 and 1366x768. The title, the main action and the main content are visible without scrolling. Scroll every long view and confirm the page header, tabs and table header stay in place

## 3. Answer the Three Questions

### Is it easy to use?

Rate each of the Eight Golden Rules in [golden-rules.md](golden-rules.md) Pass, Partial or Fail with one line of evidence. Then give a verdict:
- **Yes:** every main task was done without hesitation, and no rule failed
- **Mostly:** tasks were done, with some friction or a Partial rule
- **No:** a task could not be finished, or a rule failed

### Is it nice to use?

Judge the feel, with evidence for each point:
- Visual hierarchy: the main action and content are obvious first
- Color: the picked Color Hunt palette or the user's colors, no purple, `palette-check` passed or its warnings fixed, comfortable for long sessions (R1, Eye Comfort in [color.md](color.md))
- Speed: pages load one at a time from the backend, skeletons hold the layout, nothing lags or jumps (R10)
- Feedback: every action responds on the first frame, motion is short, explains the change and never drops a frame (R18)
- Craft: consistent spacing, radius and type tokens, every state designed
- Slop: check against [slop-patterns.md](slop-patterns.md). The build must rate Clean (0 to 10). Anything worse gets fixed before reporting

Verdict: **Yes**, **Mostly** or **No**.

### Is the navigation good?

Run the checks at the end of [navigation.md](navigation.md): where am I, how do I reach the main tasks, does back work, is mobile navigation visible, does it work by keyboard.

Verdict: **Yes**, **Mostly** or **No**.

## Output

Write the review in chat, without semicolons or em dashes (R9):

```markdown
## UI Review

**Easy to use:** Yes / Mostly / No. <one sentence why>
**Nice to use:** Yes / Mostly / No. <one sentence why>
**Navigation:** Yes / Mostly / No. <one sentence why>

### Tasks Tried
| Task | Persona | Steps | Result | Friction |
|------|---------|-------|--------|----------|

### Eight Golden Rules
| Rule | Rating | Evidence |
|------|--------|----------|
| 1 Consistency | Pass / Partial / Fail | ... |
| ... | | |

### Hard Rules
| Rule | Status | Evidence |
|------|--------|----------|
| R1 Color Hunt palette | Pass / Fixed / Not applicable | ... |
| R2 No icon-tile stat cards | | |
| R3 No icons in rounded squares | | |
| R4 No pill badges | | |
| R5 Table search and column filters | | |
| R6 Overlays size to content | | |
| R7 Custom controls and scrollbars | | |
| R8 Specific and consistent layout | | |
| R9 No semicolons or em dashes | | |
| R10 Fast, backend pagination, skeletons | | |
| R11 Real avatars, no initials | | |
| R12 Follows the project's conventions | | |
| R13 Clean, layered structure | | |
| R14 Form overlays: pinned actions, one scroll area, aligned fields | | |
| R15 No AI template tells | | |
| R16 Launch ready pages | | |
| R17 Forms on one grid, controls aligned | | |
| R18 Short, calm, compositor only motion | | |
| R19 Fits the screen, sticky headers, tabs | | |

### Fixed During Review
- ...

### Still Open
- <issue>, <why it matters>, <suggested fix>
```

Keep it short. Evidence beats adjectives.
