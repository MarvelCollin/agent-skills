# List Pages

The index of a collection: students, orders, invoices, tickets. The user comes to find a record, compare records, open or edit one, or act on many. A list page must support all four tasks. Search and filters per column are rule R5 in [../build-rules.md](../build-rules.md). Paging, search and filters have their own files: [pagination.md](pagination.md), [search.md](search.md), [filters-sort.md](filters-sort.md).

## Anatomy, Top to Bottom

1. Page header: title with total count, primary action ("New invoice"), secondary actions (Import, Export) (see [app-shell.md](app-shell.md))
2. Saved views or status tabs when users switch between a few fixed slices ("All", "Overdue", "Drafts"), each with its count
3. Toolbar: global search on the left, filters, sort, then view options (columns, density) on the right. All controls one height (R17)
4. Active filters summary with remove buttons and "Clear all"
5. The table or list, with a sticky header (R19)
6. Pagination with range and total

Items 1 to 4 stay visible while the rows scroll.

## Table, Cards or List

| Use | When |
|-----|------|
| Table | Records share attributes and users compare or scan them. The default for SaaS data |
| List rows | Records are mostly text with one or two attributes (messages, notifications, activity) |
| Cards | Records are visual (images, files, people) and users browse rather than compare |

Never cards for data users must compare. Comparing across cards forces eye travel and memory.

## Columns

- First column: the human readable identifier (name, title, invoice number), linked to the detail page. Never an internal ID first
- Order columns by importance to the user, related columns together. 5 to 8 columns visible by default, the rest available in a column picker
- Numbers right aligned with tabular figures and the same decimals in a column. Text left aligned. Dates in one format per column (see [content-format.md](content-format.md))
- Status as plain text or a glyph plus word (R4), filterable
- Long text truncates with an ellipsis at a sensible width and shows in full on hover and on the detail page
- Empty cells show a muted "Not set", never blank and never a dash alone
- Column picker lets users show, hide and reorder columns with a menu (not only drag and drop), and remembers the choice per user
- Density toggle (comfortable and compact) for tables used all day

## Default Order

The default sort answers the most common question for that list: newest first for activity, due date for tasks, needs attention first for queues. Never alphabetical by default unless users look up known names. The sort is visible in the column header (`aria-sort`) and in the URL.

## Row Interaction

- Clicking the row's name opens the detail page. If the whole row is clickable, it is still a real link (open in a new tab works) and inner controls stop propagation
- Hover tints the row. Zebra stripes or row borders keep the eye on the line in wide tables
- One or two row actions can sit inline at the end of the row, always visible with labels or clear icons with tooltips. More actions go into a row menu ("More actions for Invoice 1043"). Never hide all actions behind hover only
- Destructive row actions sit last in the menu, separated, and follow [overlays.md](overlays.md)

## Viewing and Editing One Row

| Way | Use when |
|-----|----------|
| Detail page | The record has many fields, tabs or history |
| Side panel next to the list | Users go through many records in a row and need the list for reference. The panel has prev and next |
| Inline edit in the cell | One or two quick fields edited often (status, owner, due date). Never for required multi field changes |
| Modal | Avoid for editing records. It hides the rows the user is looking at |

Inline edit rules: the cell shows it is editable on hover (pencil or field outline), Enter or click starts editing, Enter or blur saves, Escape cancels and restores, Tab moves to the next editable cell, the column width does not jump, a failed save keeps the draft and shows why.

## Bulk Actions

- A checkbox column first. Clicking a checkbox never opens the row
- Selecting shows a contextual action bar in place of the toolbar: "3 selected", the actions that apply to all, and "Clear selection"
- The header checkbox selects the current page. Then offer "Select all 1,240 matching" as a link in the bar. Say clearly which one is active
- Shift click selects a range
- After the action: a toast with the result ("12 invoices archived") and Undo when possible. If some failed, say how many and why, and keep those selected
- Long running bulk work runs in the background with progress and a notification when done

## Saved Views

- Users can save the current filters, sort and columns as a named view, share it with the team, and set a default
- Views appear as tabs or a dropdown above the toolbar. A modified view shows "Unsaved changes" with Save and Reset

## Mobile

- Keep the table when users compare: freeze the first column, scroll sideways, and signal more columns with a cut off column or an edge fade
- Otherwise turn rows into stacked items that show the identifier, status and the one or two attributes users need, with the same search, filters and sort
- Filters open in a full screen sheet with Apply showing the result count

## Avoid

- Loading every row and filtering in the browser (R10)
- Pagination, search and filters that reset each other or forget state on Back
- Actions that only appear on hover
- Horizontal scroll on desktop for a table that would fit with fewer default columns
- A table with no empty state, or the same empty state for "no data yet" and "no results"

## Check

1. Can the user find a known record in under 10 seconds with search, a filter or sort?
2. Does Back from a detail page return to the same page, filters, sort and scroll position?
3. Do bulk actions say how many records they affect and offer undo?
4. Is the first column readable, are numbers right aligned, do long values truncate cleanly?
5. At 375px, can the user still find, filter and open a record?

## Sources

- [Data Tables: Four Major User Tasks, NN/g](https://www.nngroup.com/articles/data-tables/)
- [Mobile Tables, NN/g](https://www.nngroup.com/articles/mobile-tables/)
- [Bulk Actions: 3 Design Guidelines, NN/g](https://www.nngroup.com/videos/bulk-actions-design-guidelines/)
- [Alphabetical Sorting Must (Mostly) Die, NN/g](https://www.nngroup.com/articles/alphabetical-sorting-must-mostly-die/)
- [Inline edit design guidelines, PatternFly](https://www.patternfly.org/components/inline-edit/design-guidelines/)
- [Enterprise data tables, Pencil and Paper](https://www.pencilandpaper.io/articles/ux-pattern-analysis-enterprise-data-tables)
