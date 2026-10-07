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

## 3. Answer the Three Questions

### Is it easy to use?

Rate each of the Eight Golden Rules in [golden-rules.md](golden-rules.md) Pass, Partial or Fail with one line of evidence. Then give a verdict:
- **Yes:** every main task was done without hesitation, and no rule failed
- **Mostly:** tasks were done, with some friction or a Partial rule
- **No:** a task could not be finished, or a rule failed

### Is it nice to use?

Judge the feel, with evidence for each point:
- Visual hierarchy: the main action and content are obvious first
- Color: pastel palette or the user's colors, contrast checked (R1)
- Speed: pages load one at a time from the backend, skeletons hold the layout, nothing lags or jumps (R10)
- Feedback: every action responds, motion is quick and meaningful
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
| R1 Pastel palette | Pass / Fixed / Not applicable | ... |
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

### Fixed During Review
- ...

### Still Open
- <issue>, <why it matters>, <suggested fix>
```

Keep it short. Evidence beats adjectives.
