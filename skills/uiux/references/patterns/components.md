# Components

How each building block behaves. Every component is custom styled (R7), keyboard operable with its WAI-ARIA APG pattern, has every state (default, hover, focus visible, active, disabled, loading, error, empty where they apply), uses the shared tokens (R8, R17, R18), and appears the same way everywhere in the product. Build each once and reuse it.

## Actions

### Button

- Hierarchy: one primary per view or section, secondary for alternatives, tertiary or text buttons for minor actions, danger only for destructive ones. Use ghost or text buttons when there are more than three actions
- Label is a verb plus object, sentence case, no more than about 3 words. No "OK" or "Submit"
- Sizes from the control height token. In a form row the button is as tall as the inputs (R17). Touch targets at least 44px
- Loading: keep the width, show a spinner and a verb ("Saving"), block repeat clicks. Disabled only with a visible reason (see [overlays.md](overlays.md))
- Order: in dialogs the primary is right and Cancel left of it. On page forms the primary is first on the left. Be consistent across the product
- Icon plus label where the icon helps recognition. Icon only buttons only for universal actions (close, more, search, edit), each with an `aria-label` and a tooltip

### Split Button and Menu Button

- A split button when one action is the default and a few variants exist ("Export CSV" plus a menu for Excel and PDF)
- A menu button shows a chevron and opens a menu (APG Menu Button)

### Link

- Navigates. Buttons act. Never a button that navigates without being a link, never a link that submits
- Underlined in body text. Descriptive text (see [content-format.md](content-format.md))

## Inputs

### Text Field

- Label above, hint under the label, message under the control (R17). Placeholder only as an example, never as the label
- Width matches the expected answer (R17). Correct `type`, `inputmode`, `autocomplete`. Allow paste
- Clear button in search and filter fields only
- Character counter only near a hard limit ("40 of 60 characters"), announced politely
- Prefix and suffix addons for units and fixed parts (`https://`, `Rp`, `%`)

### Textarea

- Starts at about 3 lines and grows with content up to a maximum, then scrolls once (R14). Resize handle vertical only

### Number Field

- Text input with `inputmode="decimal"` or `numeric`, optional stepper buttons when there is a usual value and small changes (quantity). Accept the user's locale separators. Min and max shown in the hint. Never change the value on mouse wheel

### Select, Radio or Combobox

| Options | Control |
|---------|---------|
| 2 to 5 | Radio group (or segmented control for view switching) |
| 5 to about 15 | Select (APG Select Only Combobox) |
| More than 15, or searchable data | Combobox with type to filter (APG Combobox) |
| Many, multiple choices | Multi select combobox with chips |

- Options in a meaningful order (frequency, logical, then alphabetical for known names like countries)
- Typing jumps to matching options. Selected option checked. Empty result says "No matches" and may offer "Create 'X'"
- Async options show a loading row and never lose the typed text
- The list opens below if space allows, flips above otherwise, matches the trigger width at least, and scrolls inside with a custom scrollbar (R7)

### Multi Select and Tags

- Chosen values as removable chips inside or under the field. Backspace removes the last chip. Show "+5 more" when chips overflow one line, expand on focus
- Select all and clear all for long lists. Selected items listed first when reopened

### Checkbox

- For independent options and a single opt in. Label clickable, aligned with the first text line (R17). Indeterminate state for "some selected" in a parent
- Opt ins start unchecked

### Radio Group

- For one choice among a few visible options. A `fieldset` with a `legend`. Arrow keys move and select. One option selected by default when a safe default exists

### Switch

- Only for settings that apply instantly. Label states what is on ("Email notifications"). Never inside a form with a Save button, use a checkbox there

### Segmented Control

- 2 to 5 mutually exclusive views or modes of the same content (List, Board, Calendar). Instant. Not for form answers that need submit

### Slider

- Only when the exact value matters less than the rough position, always paired with a number input for precision. APG Slider keys

### Date and Time

- Typed input that accepts common formats plus a calendar popover (R7). Show the parsed date back unambiguously ("Tue, 20 Oct 2026")
- Calendar opens on the selected or the relevant month, marks today, disables impossible dates with a reason, and has month and year jumps for distant dates. Birth dates use three fields or a typed input, not a calendar
- Date range: two inputs and a two month calendar on desktop, one on mobile, hover preview of the range, presets first (Today, Last 7 days, Last 30 days, This month, Custom) that set the calendar selection too
- Time: a typed field with a listbox of times in 15 or 30 minute steps, the timezone shown when it matters

### File Input

- See [data-io.md](data-io.md)

## Navigation

### Tabs

- 2 to 6 parallel sections of one object that users do not need to compare at once (R19). Short labels, counts where useful
- The active tab is clear by more than color (weight plus an indicator bar). Each tab has a URL. Arrow keys move between tabs (APG Tabs)
- Never tabs inside tabs, never tabs in an accordion. Overflowing tabs go into a "More" menu, not a scroll carousel

### Accordion

- Many short sections where users need one or two (FAQ, advanced options). Several can be open at once. Not for content most users need
- The whole header row is the button, with a chevron that rotates (R18). `aria-expanded`

### Breadcrumbs

- See [../navigation.md](../navigation.md). Truncate middle levels on narrow screens with a "…" menu

### Stepper

- See [multi-step.md](multi-step.md)

### Pagination

- See [pagination.md](pagination.md)

### Sidebar, Top Bar, Command Palette

- See [app-shell.md](app-shell.md)

## Overlays

### Modal, Drawer, Popover

- See [overlays.md](overlays.md) for choosing, R6 and R14 for sizing and form layout

### Dropdown Menu

- Actions grouped with separators, destructive last. Icons optional and consistent. Shortcuts shown right aligned. Disabled items explain why on hover and focus
- Arrow keys, Home, End, type ahead, Esc closes and returns focus (APG Menu). Submenus open on hover with a delay and on Right arrow

### Tooltip

- A short label or hint for an element, on hover after about 300 to 500ms and immediately on focus. Dismiss with Esc. Never holds interactive content or information needed to finish the task
- All icon only buttons have one. Other elements either all have one in a region or none (consistency)

### Popup Tip

- An `i` or `?` button that opens a small popover on click with extra explanation and an optional link. For fields and terms that some users do not know

## Feedback

### Toast, Banner, Inline Alert

- See [feedback.md](feedback.md). Alerts use an icon plus a title plus text, never color alone, and the danger and warning colors pass contrast

### Status

- Plain text or a glyph plus word (R4). One color per meaning across the product (success, warning, danger, info, neutral). The same status uses the same word everywhere

### Progress, Spinner, Skeleton

- See [feedback.md](feedback.md) and [../motion.md](../motion.md)

### Count Badge

- A small number for unread or pending items, capped ("99+"). Only for things that need attention

## Data Display

### Table

- See [list-pages.md](list-pages.md) and R5

### Description List (key value)

- Terms and values on the form grid (R17), aligned the same way as the edit form, "Not set" for empty values, copy buttons for IDs

### Card

- Only for items users browse visually or for grouping a section on a page. Not for metrics with icon tiles (R2), not nested (L08). The whole card can be a link with one clear title link inside

### Avatar

- See R11. Avatar groups show 3 to 5 then "+N" with the full list on hover or click

### Chips and Tags

- Squared and quiet (R4). Removable chips have a remove button with an accessible name ("Remove filter Late")

### Empty State

- See [states.md](states.md)

### Chart

- See [dashboard.md](dashboard.md)

### Code and Copy

- Monospace, a copy button that confirms "Copied" for 2 seconds, never selectable line numbers

### Keyboard Key

- Shortcut hints use a `kbd` style that matches the platform (`Ctrl K` on Windows, `⌘ K` on macOS)

## Check

1. Tab through every component. Is focus visible and does each respond to its APG keys?
2. Is every component built once and reused, with the same look and behavior on every screen?
3. Does every component have its loading, empty, error and disabled states?
4. Do controls in forms share one height and line up (R17)?

## Sources

- [WAI-ARIA Authoring Practices Guide patterns](https://www.w3.org/WAI/ARIA/apg/patterns/)
- [Listboxes vs. Dropdown Lists, NN/g](https://www.nngroup.com/articles/listbox-dropdown/)
- [Does Your Form Really Need a Dropdown List, NN/g](https://www.nngroup.com/articles/dropdown-list/)
- [Checkboxes vs. Radio Buttons, NN/g](https://www.nngroup.com/articles/checkboxes-vs-radio-buttons/)
- [Toggle Switch Guidelines, NN/g](https://www.nngroup.com/articles/toggle-switch-guidelines/)
- [Tooltip Guidelines, NN/g](https://www.nngroup.com/articles/tooltip-guidelines/)
- [Tabs, Used Right, NN/g](https://www.nngroup.com/articles/tabs-used-right/)
- [Accordions on Desktop, NN/g](https://www.nngroup.com/articles/accordions-on-desktop/)
- [Placeholders in Form Fields Are Harmful, NN/g](https://www.nngroup.com/articles/form-design-placeholders/)
- [Button usage, Carbon Design System](https://v10.carbondesignsystem.com/components/button/usage/)
- [Date range pattern, uxpatterns.dev](https://uxpatterns.dev/patterns/forms/date-range)
