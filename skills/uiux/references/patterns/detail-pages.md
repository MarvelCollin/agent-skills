# Detail Pages

One record: a student, an order, a ticket, a project. The user came to check its state, find one fact, change something, or act on it. The page answers "what is this, what state is it in, and what can I do" before any scrolling (R19).

## Header

Sticky while the page scrolls:

- Breadcrumb back to the list ("Students / Ana Putri")
- The record's name as the h1, with its key identifier (invoice number, ID) copyable next to it
- Status as text or a glyph plus word (R4), and the two or three facts users check most (owner, due date, amount)
- One primary action for the record's next step ("Send invoice", "Approve"). Secondary actions next to it, rare and destructive ones in a "More" menu
- Previous and next record arrows when users arrive from a list, keeping the list's filters ("3 of 48")

## Body

- Split into tabs when the record has distinct areas the user does not need at once: Overview, Activity, Files, Settings (R19). Each tab has its own URL (`?tab=activity`) and keeps its scroll position. Show counts on tabs that hold collections ("Files 4")
- The Overview tab fits the screen: key fields in a description list on the form grid (see [../form-layout.md](../form-layout.md)), grouped under short headings, the most used group first
- Related records appear as compact lists with a "View all" link to the filtered list, not full tables
- Empty fields say "Not set" with an inline way to fill them when the user may edit
- A side column on wide screens holds metadata (created, updated, owner, tags) and stays visible while the main column scrolls

## Viewing and Editing

| Pattern | Use when |
|---------|----------|
| Inline edit per field | Most fields are edited one at a time. Click the value or its pencil, edit, Enter saves, Esc cancels |
| Edit mode for a section | A group of fields must be valid together (an address). The section turns into a form with Save and Cancel |
| Separate edit page | The record is long and edits are rare and deliberate |

- View and edit layouts match so nothing jumps when switching
- Editing never loses the user's place. Saving shows "Saved" next to the field or a toast, and the timestamp updates
- Concurrent edits: if the record changed since it was loaded, say who changed what and offer to review before overwriting

## Activity and History

- An Activity tab or panel lists changes, comments and events newest first, with actor, action, time and a link to the related item (see [activity.md](activity.md))
- Comments have an input at the top or bottom that stays put, support mentions, and show "Edited" on changed comments

## Actions on the Record

- Actions that change state ("Mark as paid") confirm through the new state and a toast with Undo, not a dialog
- Destructive actions follow [overlays.md](overlays.md): name the record, say what is lost, offer Undo when the delete is soft
- After deleting, return to the list with a toast, not to a broken detail URL
- Actions the user lacks permission for stay visible but disabled with the reason, or are hidden if the user can never gain them

## Loading and Missing Records

- A skeleton that matches the header and the first tab
- A record that does not exist or was deleted shows a not found state with a link back to the list. One the user cannot access shows a no access state that names who to ask (see [states.md](states.md))

## Check

1. Above the fold at 1366x768: name, status, key facts and the primary action are visible?
2. Do tabs update the URL, and does Back return to the previous tab?
3. Does inline edit save with Enter, cancel with Esc and confirm the save?
4. Does Back return to the list with its filters and scroll?
5. Does a deleted record's URL show a helpful state?

## Sources

- [Tabs, Used Right, NN/g](https://www.nngroup.com/articles/tabs-used-right/)
- [List and details pattern, Microsoft](https://learn.microsoft.com/en-us/windows/apps/develop/ui/controls/list-details)
- [8 Design Guidelines for Complex Applications, NN/g](https://www.nngroup.com/articles/complex-application-design/)
- [Inline edit, PatternFly](https://www.patternfly.org/components/inline-edit/design-guidelines/)
