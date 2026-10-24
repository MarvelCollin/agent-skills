# Filters and Sort

Narrowing and ordering a collection. Rule R5 in [../build-rules.md](../build-rules.md) requires a filter for every table column. This file covers how filters behave.

## Placement

- Column filters in or under each header for tables (R5). A filter bar above the table for the 3 to 5 most used filters, plus "More filters" for the rest
- On mobile, one "Filters (3)" button opens a full screen sheet. The active count is on the button
- Applied filters show as removable chips above the results with "Clear all". Never only inside the filter panel
- Sorting is separate from filtering: a sort control and sortable headers. Sorting reorders, filtering removes

## Filter Bar Layout

- Search first and widest, then the 2 to 4 most used filters, then sort, on one row with one control height (R17)
- One summary line under the bar: "Showing 12 of 129 products", then each active filter as a removable squared tag ("Category: Paint ×"), then "Clear all". It is the only place the user needs to look to know why the list is short
- Size the bar from its own width, not the window. In a split screen (a product list beside a cart, a list beside a detail pane) the list column can be narrow on a wide monitor. Use container queries with three tiers: one row when wide, search on its own row with the filters in an equal width grid below when medium, search plus a "Filters (2)" button opening a bottom sheet when narrow
- The bottom sheet holds the same controls stacked full width, with "Clear filters" and "Show 48 products" pinned at the bottom

## Applying

| Mode | Use when |
|------|----------|
| Instant, each change updates results | Results return in under about 1s and users explore |
| Apply button | Inside an overlay or mobile sheet, or when queries are slow, or when users set many criteria at once |

- Instant mode never freezes the controls while results load. Results dim or show a skeleton, the filter panel stays where it is, and the user can keep changing filters
- Apply buttons show the expected count ("Show 48 results") and update it as choices change
- An overlay filter panel stays open while the user sets several filters. Never close it after each choice
- Never auto scroll the page, collapse a filter group, or move the panel on a change
- Changing a filter returns to page 1

## Controls by Data Type

| Data | Control |
|------|---------|
| Text | "Contains" input, debounced |
| A few fixed values (2 to 7) | Checkbox list or segmented buttons, each with its count ("Late (12)") |
| Many fixed values | Multi select combobox with search, selected values first |
| Numbers | Min and max inputs, optionally with a slider |
| Dates | Date range picker with presets (Today, Last 7 days, This month, Custom) |
| Yes or no | Any, Yes, No |
| People | Combobox with avatars, "Me" first |

- Never a row of chips for one choice out of more than about 7 values. Thirty categories as chips wrap into six rows and push the results off screen. Use a single select combobox with search, "All" first, each option showing its count, the chosen one checked
- Options that would return zero results show (0) and are disabled with the reason, not hidden. A toggle can hide them
- Long option lists show 7 to 10 with "Show more" and a search
- Remember recently used filter values

## State

- Filters, sort and search live in the URL. Reload, Back and shared links restore them
- Back from a detail page restores the exact filter state and scroll position
- Users can save a combination as a view (see [list-pages.md](list-pages.md))
- An incompatible combination shows a clear message instead of an empty list without explanation
- Clearing wins over debounce. "Clear all" empties the search box and the URL at once. Write the debounced query to the URL only when the debounced value itself changes, never on every URL change, or a stale query writes itself back a moment after the clear
- Unknown values in the URL (`?stock=everything`) fall back to the default instead of showing an empty list

## Sort

- Default sort answers the most common question for that list (see [list-pages.md](list-pages.md))
- Header click cycles ascending, descending, back to default. The arrow shows direction, `aria-sort` on the header
- Optional secondary sort for power users, shown in a sort menu

## Empty Results

"No invoices match these filters" plus the active filters as chips, a "Clear all filters" button, and when one filter is the cause, a suggestion to remove it. Different from "No invoices yet" (see [states.md](states.md)).

## Check

1. Apply three filters, open a record, press Back. Same results, same scroll?
2. Copy the URL into a new tab. Same view?
3. Is every active filter visible and removable in one click?
4. Do filters keep working while results load?
5. On mobile, does the sheet show the count on Apply?
6. Type a search, then press "Clear all" at once. Does the old query stay gone, in the box, the URL and the results?
7. Open the side panels so the list column is at its narrowest. Do the filters still fit, or move to a second row or the sheet, with nothing overflowing?
8. Can a long single choice filter be searched by typing, and picked with the arrow keys and Enter?

## Sources

- [User Intent Affects Filter Design, NN/g](https://www.nngroup.com/articles/applying-filters/)
- [Filters vs. Facets, NN/g](https://www.nngroup.com/articles/filters-vs-facets/)
- [Designing Filters That Work, Smashing Magazine](https://www.smashingmagazine.com/2021/07/frustrating-design-patterns-broken-frozen-filters/)
- [Data Tables: Four Major User Tasks, NN/g](https://www.nngroup.com/articles/data-tables/)
