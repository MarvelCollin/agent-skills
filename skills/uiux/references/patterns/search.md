# Search

Search inside an app (a table's search box, the global search, a picker's search) and its results. The user knows roughly what they want and expects to type a few characters and see it.

## The Search Box

- A visible field, not only an icon, wherever search is a main way in. Wide enough for a typical query (about 30 characters)
- A label (visible or `aria-label`) and a placeholder that says what is searchable: "Search by name, email or student ID"
- The query stays in the box on the results, editable, with a clear (×) button
- Shortcut `/` focuses it. `Esc` clears, then blurs
- In a table, search debounces about 250ms and queries the server (R10). Searching resets to page 1 and keeps the other filters
- Results update in place. The box never loses focus while results load

## Matching

- Case and accent insensitive, tolerant of extra spaces and common typos
- Matches the fields the placeholder promised, including IDs pasted with or without prefixes
- Exact matches rank first, then starts with, then contains, then recent and frequently used items
- Highlight the matched text in results

## Suggestions

- Before typing: recent searches (with a way to remove them) and recently viewed records
- While typing: suggestions that complete the query and, in global search, the top matching records grouped by type ("Students", "Classes", "Invoices") with a "See all results for 'ana'" item
- Arrow keys move through suggestions, Enter opens, the active suggestion is visible. The APG Combobox pattern applies
- Keep the list short (about 8 items) and fast. Never a full results page squeezed into a dropdown

## Scope

- Global search covers everything by default. If a scope is set ("in this class"), show it as a removable chip in the box and on the results, with "Search everywhere" one click away
- A search inside a filtered list searches within those filters and says so

## Results Page

- The query, the result count, and how they are sorted ("128 results for 'ana', best match first")
- Results grouped or filterable by type with counts per type
- Each result shows its type, title, the matched snippet, and one or two attributes that help pick the right one (class, status, date)
- Sort by relevance by default, with newest as the second option
- Most important hits on the first page. Pagination as [pagination.md](pagination.md)

## No Results

Never a dead end. Show:

1. The query and that nothing matched, in plain words, no jokes
2. The query still in the box to edit
3. A spelling suggestion or a search that does return results ("Did you mean 'Anna'?")
4. The filters or scope that narrowed it, each removable, plus "Clear all filters"
5. A broader route: search everywhere, browse the related list
6. When it makes sense, the action to create it ("Create student 'Ana P.'")

## Avoid

- Search that only matches from the start of one field
- Search that clears filters, or filters that clear search
- Results that reorder as the user is about to click
- A search icon that opens a modal for a table search

## Check

1. Search for an exact ID, a partial name, a misspelled name and a term with no results. Is each handled?
2. Is the query still visible and editable on the results?
3. Do suggestions work by keyboard alone?
4. Does the scope show, and can the user widen it in one click?

## Sources

- [Search: Visible and Simple, NN/g](https://www.nngroup.com/articles/search-visible-and-simple/)
- [3 Guidelines for Search Engine No Results Pages, NN/g](https://www.nngroup.com/articles/search-no-results-serp/)
- [Scoped Search, NN/g](https://www.nngroup.com/articles/scoped-search/)
- [Site Search Suggestions, NN/g](https://www.nngroup.com/articles/site-search-suggestions/)
- [5 Proven UX Strategies for No Results Pages, Baymard](https://baymard.com/blog/no-results-page)
- [Combobox pattern, WAI-ARIA APG](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/)
