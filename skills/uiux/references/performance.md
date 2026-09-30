# Performance and Data Loading

How to keep a UI fast and responsive, especially one backed by a database that grows. This is rule R10 in [build-rules.md](build-rules.md). The core idea: never load or render more than the screen needs right now.

## Data Loading

### Paginate on the backend

A table or list must ask the server for one page at a time. Never fetch every row and slice in the browser.

- Send `page` (or a `cursor`), `pageSize`, `sort`, and the active `filters` as request parameters.
- The server applies the filter, sort and limit, and returns that page plus a total count or a next cursor.
- Cursor or keyset pagination scales better than offset for large or fast-changing tables, because deep offsets get slow. Use offset for small, stable sets where a page-number UI matters.
- Default page size 25 to 50. Show the range and total ("26 to 50 of 1,240"). Offer next and previous, or infinite scroll with a sentinel that loads the next page as it nears the viewport.

### Filter and search on the backend

The R5 search and column filters send their state to the server. A search box debounces about 250ms, then requests filtered rows. It does not filter a large in-memory array. Keep the active filters in the URL so the view is shareable and reloads the same page.

### Fetch less, reuse more

- Request only the fields the screen shows. Do not over-fetch and hide columns.
- Cache fetched pages and query results. Do not refetch what has not changed. A data-fetching library (TanStack Query, SWR, RTK Query, Apollo) gives caching, dedupe, background refresh and loading and error states for free. Prefer one over hand-rolled fetch in effects.
- Deduplicate in-flight requests. Cancel a stale request when its inputs change (AbortController).
- Prefetch the next page or the likely next route when idle.

## Perceived Speed

### Skeletons, not blank screens or spinners

- While content loads, show a skeleton shaped like the real thing: table rows, cards, text lines, the avatar circle. It holds the layout so nothing jumps when data arrives.
- Use a spinner only for a small inline action (a button saving), never for a whole page or table.
- Show the skeleton only after a short delay (about 150ms) so a fast response does not flash it. Keep it on screen a minimum time once shown, so it does not flicker.
- On error, show a clear message with a retry, not a stuck skeleton.

### No layout shift

- Reserve space for anything async: images, avatars, embeds, ads, late text. Give images and avatars explicit width and height or an aspect ratio box. Target CLS near zero.
- Do not push content down when a banner or fetched value appears. Reserve its space up front.

## Runtime Smoothness

- Debounce search and resize. Throttle scroll and pointer-move handlers.
- Keep the main thread free. Move heavy compute to a web worker. Avoid synchronous work in a scroll or input handler.
- Virtualize a list (render only visible rows) only when a single page is still very long. Pagination usually removes the need.
- Animate only `transform` and `opacity` (R8). Never animate width, height, top or left.
- Memoize expensive renders and derived values. Give list items stable keys. Avoid recreating large objects and handlers on every render.
- Batch state updates. Avoid a state change on every keystroke that re-renders a big tree, use the debounced value.

## Loading Less Code

- Code-split by route so the first screen ships less JavaScript.
- Lazy-load below-the-fold and heavy components (charts, editors, maps, date pickers) with a suspense fallback skeleton.
- Lazy-load offscreen images with `loading="lazy"`, and serve sized, modern formats.
- Watch the bundle. Drop or defer heavy dependencies. Tree-shake.

## Checks

- Load a table against a large dataset (thousands of rows). It must stay smooth and must not fetch everything. Check the network panel: one page per request, with paging and filter params.
- Throttle the network in the browser and confirm skeletons appear and the layout does not jump.
- Type in the search box and confirm it debounces and queries the server, not a client array.
- Measure: Largest Contentful Paint, Interaction to Next Paint, and Cumulative Layout Shift, with the Lighthouse script in the uiux audit if useful. Watch for long tasks while scrolling and typing.

## Sources

- [Core Web Vitals, web.dev](https://web.dev/articles/vitals)
- [Optimize Largest Contentful Paint, web.dev](https://web.dev/articles/optimize-lcp)
- [Optimize Cumulative Layout Shift, web.dev](https://web.dev/articles/optimize-cls)
- [Optimize Interaction to Next Paint, web.dev](https://web.dev/articles/optimize-inp)
- [Keyset (cursor) pagination, use-the-index-luke.com](https://use-the-index-luke.com/no-offset)
