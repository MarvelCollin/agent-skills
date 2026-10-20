# Pagination

How users move through a long collection. Data always loads one page at a time from the backend (R10 in [../build-rules.md](../build-rules.md), [../performance.md](../performance.md)). This file is about what the user sees and controls.

## Pick the Pattern

| Pattern | Use when | Avoid when |
|---------|----------|------------|
| Numbered pages | Users look for specific records, compare, or come back to a place. The default for tables, search results and admin lists | Pure browsing feeds |
| Load more button | Browsing a small to medium set (under a few hundred) with good filters, on mobile, or when the footer must stay reachable | Users need to return to an exact position |
| Infinite scroll | Endless homogeneous feeds with no specific goal (activity streams, social feeds) | Anything task based, tables, search results, pages with a footer, keyboard and screen reader heavy users |
| Show all | A set small enough to load fast (about 50 rows or fewer) | Large sets |

If infinite scroll is used anyway: show a loading row, a count of how many are loaded of the total, a "Back to top" control, the ARIA `feed` role, and restore position on Back.

## Numbered Pages

- Range and total near the table: "26 to 50 of 1,240". With cursor paging and no total, "Showing 50" and Next only
- Controls: Previous, page numbers, Next. Show first, last, current and one or two neighbours, ellipses for gaps: `1 … 4 5 [6] 7 8 … 50`
- Hide Previous on the first page and Next on the last, or disable them with a clear look. Hide the whole control when there is only one page
- The current page is not a link, looks different by more than color, and has `aria-current="page"`. Wrap the control in `nav` with `aria-label="Pagination"`, each link labelled "Page 6"
- Targets at least 40px on desktop and 44px on touch
- For very large sets add a "Go to page" field
- Rows per page selector with 10, 25, 50 and 100. Default 25 to 50 for tables. The choice is remembered per user and per table
- Place the control under the table, aligned right, and the range text on the left. Long pages may repeat a compact control above the table

## State and URL

- `page`, `pageSize` and `sort` live in the URL with the filters. Reload and shared links restore the same page
- Back from a detail page returns to the same page and scroll position
- Changing a filter, sort or search returns to page 1
- Paging scrolls to the top of the table, not the top of the document, and keeps the toolbar and header in view
- A URL for a page that no longer exists (after deletes) redirects to the last valid page with a short note
- Deleting the last row of a page moves back one page instead of showing an empty page
- Put the page number in the document title ("Invoices, page 3 of 50") so screen reader users hear the change

## Loading Between Pages

- Keep the old rows visible and dim them, or show a skeleton of the same row count, while the next page loads. Never collapse the table to a spinner
- Prefetch the next page when idle so Next feels instant
- Keep the pagination control in place while loading so the user can click again

## Mobile

- Show Previous, "Page 3 of 12" and Next, each a large target. Optionally a page select in the middle
- Load more is often better on phones for browsing. Keep a count ("20 of 148")

## Check

1. Can the user tell how many records exist and where they are in them?
2. Does reload, Back and a copied URL return to the same page with the same filters?
3. Does a filter change reset to page 1?
4. Does the current page announce correctly with a screen reader?
5. At 375px, are the controls large enough and still on one line?

## Sources

- [Pagination component, GOV.UK Design System](https://design-system.service.gov.uk/components/pagination/)
- [Infinite Scrolling: When to Use It, When to Avoid It, NN/g](https://www.nngroup.com/articles/infinite-scrolling-tips/)
- [Alternatives to Pagination on Product Listing Pages, NN/g](https://www.nngroup.com/articles/alternatives-pagination-listing-pages/)
- [Users' Pagination Preferences and View All, NN/g](https://www.nngroup.com/articles/item-list-view-all/)
- [Feed pattern, WAI-ARIA APG](https://www.w3.org/WAI/ARIA/apg/patterns/feed/)
