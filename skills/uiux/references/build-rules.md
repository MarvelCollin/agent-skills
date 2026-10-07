# UI Build Rules

These rules apply whenever you create or change UI: pages, components, dashboards, forms, tables, modals. Rules R1 to R14 are hard rules. Break one only when the user explicitly asks for that exact thing, and say so in the review.

Read these alongside [color.md](color.md), [navigation.md](navigation.md), [golden-rules.md](golden-rules.md) and the slop catalog in [slop-patterns.md](slop-patterns.md).

## R1: Pastel Palette Unless the User Picks Colors

If the user has not named colors or a brand palette, build a pastel palette with the method in [color.md](color.md).

Never:
- Use saturated default fills such as Tailwind `bg-blue-500`, `bg-green-500`, `bg-purple-500`, `bg-orange-500` or their hex values (`#3B82F6`, `#22C55E`, `#A855F7`, `#F97316`)
- Give sibling items one rainbow color each (blue card, green card, purple card, orange card)
- Default to indigo, violet or lavender (slop patterns C01 and C02)

Pastel does not mean low contrast. Text on pastel surfaces uses a dark shade of the same hue (4.5:1 or better). Borders, focus rings and icons that carry meaning reach 3:1 against what they sit on.

If the user gives colors, use theirs and still meet the contrast rules.

## R2: No Stat Cards with Icon Tiles

Do not build a row of identical cards that each hold a colored square icon, a small label and a number. This is the default AI dashboard (slop patterns K15 and L11).

Instead:
- Put the key numbers in one summary strip under the page title. Label above number, separated by whitespace or a thin rule. No card per number and no icons
- Give the number that matters most more size and weight than the rest. They are not equal, so they should not look equal
- Give each number context: change since last period, a target, or the next step ("7 results, 2 need grading")
- Make each number a link to the filtered view it counts
- Ask whether a bare total earns a place at all. A count can often live next to its nav item instead ("Users 5")

## R3: No Icons Inside Rounded Squares

Do not wrap an icon in a tinted or solid rounded square, circle or blob, in any color (slop pattern K01). This applies to feature lists, stat blocks, list items, empty states and headers.

Instead:
- Place the icon inline with its text, at text size and in the text color
- Use no icon when the label is already clear
- If an icon must stand alone, show the bare glyph with a text label or an accessible name. No container

## R4: No Pill Badges

Do not use rounded-full pills with tinted backgrounds for status, role, category or tags (slop pattern K11). This covers `rounded-full px-2 text-xs` spans and components named Badge, Chip or Pill that render that way.

Pick one treatment that fits the product and use it everywhere:
- **Plain column value:** in tables, the status or role is ordinary text in its own column, and that column is filterable (R5)
- **Glyph plus word:** a small shape before the word, one distinct shape per state (square, ring, diamond, dash), in the state's dark tone. Shape and word carry the meaning, not color alone
- **Weighted text:** the word in the state's dark tone and medium weight, no background
- **Underlined label:** the word with a 2px underline in the state's tone, offset from the text
- **Squared tag:** only when a label must look like an object: 2px corner radius or less, 1px border in the darker tone, no fill, normal case

Every status still has a text label. Never show state by color alone (WCAG 1.4.1).

## R5: Every Table Gets Search and Filters on Every Column

Each data table has:
- A global search box above it
- A filter control in or under every column header, matched to the data type:
  - text: "contains" search input
  - fixed set of values (status, role): multi-select checklist with its own search
  - numbers: min and max range
  - dates: custom date range picker (R7)
  - yes/no: any, yes or no
- Sorting on every sortable column, with `aria-sort` on the header
- A line showing what is active, such as "Showing 12 of 240, filtered by Role: Student, Status: Late", with a way to clear each filter and all filters
- An empty state for "no rows match" with a clear-filters action. This is different from "no data yet"
- A sticky header, and a sticky first column when the table scrolls sideways
- A human-readable first column (name or title, not an internal ID)
- Filters stored in the URL query so the view can be shared and survives reload
- Text search debounced by about 250ms. Filtering never resets scroll position or moves focus
- A labelled, keyboard-reachable control for every filter ("Filter by Name")
- On narrow screens, the filters move into a sheet opened from a "Filters" button that shows the active count. Rows scroll sideways with the first column pinned, or become stacked rows that keep the same filters

## R6: Overlays Size to Their Content

Modals, drawers, popovers, dropdowns, menus and toasts size themselves to their content within limits. Never give every modal the same fixed width or height.

- Width: `width: fit-content` with `min-width: min(20rem, 100vw - 2rem)` and `max-width: min(<content cap>, 100vw - 2rem)`. Pick the cap from the content: short confirmation about 28rem, form about 40rem, data or media about 64rem
- Height: automatic up to `max-height: min(90dvh, <cap>)`. Header and footer stay in place and only the body scrolls, with the custom scrollbar (R7). Form overlays follow the full structure in R14
- Under 640px wide, modals become full-width bottom sheets or full screens with a visible close control
- Popovers and dropdowns flip or shift to stay on screen, and match their trigger's width when they list options
- Use a modal only for decisions that need attention. Show errors inline, next to the field (see [golden-rules.md](golden-rules.md))
- Focus moves into the overlay on open, stays trapped inside while it is modal, and returns to the trigger on close. Escape closes it

## R7: Custom Controls, Never Browser Built-ins

Build every control as a custom component in the product's own style. Nothing should render with the browser's default look.

| Instead of | Build | Accessible pattern |
|------------|-------|--------------------|
| Default scrollbars | A custom scroll area or styled scrollbar (see below) | Keeps native scrolling |
| `<input type="date">`, `datetime-local`, `month`, `week` | Custom date picker: typed input plus calendar popup | APG Date Picker Dialog or Date Picker Combobox |
| `<input type="time">` | Custom time field or listbox of times | APG Combobox |
| `<select>`, `<datalist>` | Custom select or combobox | APG Select-Only Combobox, Combobox |
| Native checkbox, radio | Custom checkbox, radio group, switch | APG Checkbox, Radio Group, Switch |
| `<input type="range">` | Custom slider | APG Slider |
| `<input type="number">` spinners | Custom number field with stepper buttons | APG Spinbutton |
| `<input type="file">` | Custom drop zone plus button | Button with a visually hidden file input |
| `<input type="color">` | Custom swatch picker | APG Radio Group or Grid |
| `alert()`, `confirm()`, `prompt()` | Custom dialog, or an inline message with undo | APG Dialog (Modal) |
| `title` tooltips | Custom tooltip on hover and focus | APG Tooltip |
| Browser validation bubbles | `novalidate` plus inline error text tied to the field with `aria-describedby` | |

Scrollbars:
- Every scrolling container gets the product's scrollbar: at least `scrollbar-width: thin` and `scrollbar-color: <thumb> <track>` plus `::-webkit-scrollbar` rules, or a custom scroll-area component with its own thumb
- Keep native scrolling: wheel, touch, keyboard, momentum. Never hijack or smooth-scroll the wheel
- A scroll container with no focusable children gets `tabindex="0"`, a role and an accessible name, so keyboard users can scroll it

Headless libraries are fine when you style them yourself: React Aria, Radix, Headless UI, Ark UI, Reka UI, Melt UI, react-day-picker. Their untouched default look is not (slop pattern K03). Whatever you build must support the keyboard model of its APG pattern, show focus, and expose name, role and state.

## R8: Layouts That Are Specific and Consistent

Specific means the layout comes from this product's content and main task, not from a template. Consistent means the same job always looks and behaves the same.

- Start from the main task on the screen. Give it the most space and the first position, and let everything else support it
- Do not assemble canned layouts: sidebar plus KPI cards plus chart, hero plus three feature cards plus logos plus FAQ (slop patterns L01, L03, L11)
- Define tokens before building and use only those:
  - a spacing scale on a 4px or 8px base
  - a radius scale that varies by element size (small controls 4 to 6px, containers 8 to 12px), not one radius everywhere (S04)
  - 2 or 3 elevation levels, used for layering only
  - a type scale with a clear ratio (1.2 to 1.333) and a font pairing chosen for the product, not Inter by default (T01)
- One component per job. Every table, filter, date picker, dialog and empty state across the product uses the same component
- Keep a clear hierarchy: one dominant element per screen, then supporting content. Avoid rows of equal boxes
- Use whitespace and alignment to group before reaching for borders and cards. Do not nest cards inside cards (L08)
- Motion is short (150 to 250ms), eases out, and explains a change. No bounce, no fade-in on every element (M01, M02)

## R9: No Semicolons or Em Dashes in Words

Never use a semicolon or an em dash (U+2014) in any text a person reads: UI copy, labels, buttons, headings, messages, tooltips, empty states, placeholder text, alt text, and everything this skill writes (reviews, reports, summaries).

- Split the thought into two sentences, or join it with a comma and a conjunction ("Scores are saved. You can leave now.")
- Use a colon to introduce a list or an explanation, and a plain hyphen only inside compound words and ranges
- Code syntax is not copy. Semicolons in CSS and JavaScript statements are fine

## R10: Fast, and Never Loading a Whole Dataset at Once

The UI stays responsive no matter how much data exists. Never fetch every row and render it. See [performance.md](performance.md) for the full method.

- **Tables and long lists paginate.** Load one page at a time from the backend, with page or cursor, page size, sort, and filters sent as parameters. The server does the paging, sorting and filtering, not the browser. Default page size 25 to 50. Offer next and previous or infinite scroll, and show the range ("26 to 50 of 1,240").
- **The filters and sort from R5 run on the backend too.** A search box sends its query to the server (debounced about 250ms), it does not filter a giant in-memory array.
- **Skeletons, not spinners, for content.** While a page or table loads, show a skeleton shaped like the real content (rows, cards, text lines) so the layout does not jump. Use a spinner only for a small inline action. Never a blank screen.
- **No layout shift.** Reserve space for images, avatars and async content so nothing jumps when it arrives (CLS near zero). Give images width and height.
- **Keep interaction smooth.** Debounce search and resize, throttle scroll handlers, and keep work off the main thread. Virtualize a list only when a page of rows is still very long. Do not animate layout properties (R8).
- **Load what is needed, when needed.** Code-split routes, lazy-load below-the-fold and heavy components, and lazy-load offscreen images. Cache and reuse fetched pages, and do not refetch what has not changed.
- **Optimistic where safe.** For a small write the user expects to succeed, update the UI at once and reconcile with the server, with a clear rollback on failure.

A table or list that loads its whole dataset and pages or filters in the browser fails this rule.

## R11: Real Avatars, Never Initials

Do not fall back to a circle with a person's initials for a profile picture. The initials-in-a-colored-circle avatar is a template default and reads as generic.

- Show the person's actual photo when there is one.
- When there is none, use a neutral placeholder that is not initials: a simple user glyph in the product's muted tone, or a generated shape or pattern keyed to the user id (an identicon or a soft gradient blob), the same treatment everywhere.
- Reserve the avatar's exact size so it does not shift when the image loads (R10). Give the `img` width, height, `loading="lazy"` and a real `alt` of the person's name.
- If a monogram is truly unavoidable for a brand reason, that is the one exception, and it must be a deliberate, consistent style, not the default letter circle. Say so in the review.

## R12: Follow the Project's Conventions

New code reads as if the same team wrote it. Before writing, learn how this project already does things:

```bash
bash "<skill-dir>/scripts/conventions.sh" "<project-or-folder>"
```

On Windows without bash: `powershell -NoProfile -ExecutionPolicy Bypass -File "<skill-dir>/scripts/conventions.ps1" -Path "<project-or-folder>"`. It reports the dominant file and folder naming per file type, role suffixes (`.types`, `.service`, `.api`), where tests live, the formatter config, semicolons, quotes, indent and the import alias. Then open two or three existing files of the same kind as the one you will write (a sibling component, the nearest page, its hook).

- **File and folder names** follow the dominant style for that file type: if components are `UserCard.tsx`, a new one is `OrderCard.tsx`, not `order-card.tsx`. Folders follow the dominant folder style. Use the role suffixes the project already uses
- **Code style** follows the formatter config, and the sample where there is none: semicolons, quotes, indent, the import alias (`@/`) instead of long relative paths
- **Patterns** match: named or default exports, function declarations or arrow components, the styling approach (Tailwind, CSS modules, styled components), the state and data libraries already installed. Do not add a dependency for something the project already solves
- **Placement** matches: tests where the project keeps them (`TEST_LAYOUT`), shared primitives where existing ones live
- **Reuse** existing components, tokens, hooks, utilities and API clients before creating new ones
- **No convention yet:** use `PascalCase.tsx` components, `useCamelCase.ts` hooks, `kebab-case` folders, `Component.types.ts` for types, and say so in the review

If the existing convention conflicts with R13, keep R13's separation but use the project's naming for the new files.

## R13: Clean, Layered Frontend Structure

Code is split by responsibility so it stays readable as it grows. Each file has one job.

| Concern | Lives in | Never in |
|---------|----------|----------|
| Interfaces and types | `Component.types.ts` beside the component, or the feature's `types.ts` | The component file |
| Server calls (`fetch`, `axios`, SDK clients) | An API module per resource (`orders.api.ts`, `services/orders.ts`) | Components |
| Data loading, caching, mutations | A hook per use case (`useOrders`, `useUpdateOrder`), on the project's data library (TanStack Query, SWR, RTK Query) when it has one | Components |
| Business logic and derived state | Hooks or plain functions in `lib/` or the feature folder | JSX |
| Constants, options, config | `constants.ts` or the feature's config file | Scattered string literals |
| Markup and interaction | The component | |

- **One component per file.** A component file over about 300 lines, or with more than one exported component, gets split into subcomponents
- **Feature folders** for app code (`features/orders/` with `components/`, `hooks/`, `api/`, `types.ts`), shared primitives in one place (`components/ui/`). Follow the existing layout when there is one
- **Typed boundaries.** Props have a named type in the types file. No `any`. API responses are typed once in the API module and mapped to UI types there, not in components
- **Thin components.** A component reads props and hook results and renders. Early returns for loading, empty and error states. No nested ternaries deeper than one level in JSX. Repeated markup becomes a subcomponent
- **No prop drilling past two levels.** Use composition (children, slots) or context
- **Naming:** components are nouns (`OrderCard`), hooks start with `use`, event props start with `on` and handlers with `handle`, booleans read as questions (`isOpen`, `hasError`)
- **Imports flow one way:** pages use features, features use shared `components/ui` and `lib`, never the reverse

## R14: Form Overlays Keep Their Actions in View and Their Fields Aligned

Every modal, drawer or sheet that holds a form is built from three regions. The person always sees the title and the action buttons, however much content sits between them.

| Region | Holds | Behavior |
|--------|-------|----------|
| Header | Title, one line of description, close button | Pinned. `flex-shrink: 0` |
| Body | Fields, helpers, previews | The only scroll area. `flex: 1`, `min-height: 0`, `overflow-y: auto`, `overscroll-behavior: contain`, custom scrollbar (R7) |
| Footer | Primary action, Cancel, destructive action | Pinned. `flex-shrink: 0`. Always visible without scrolling |

- **The popup is a flex column** with `overflow: hidden` and `max-height: min(90dvh, <cap>)`. Never put `overflow-y: auto` on the popup itself, because then the footer scrolls away with the fields
- **A form that wraps body and footer** is a flex column too (`display: flex`, `flex-direction: column`, `flex: 1`, `min-height: 0`). Forgetting this is the most common reason the footer still scrolls. Build it into the shared dialog component so no screen can forget it
- **Dividers appear only when the body scrolls.** Show the header border when the body is scrolled down and the footer border when more content sits below. A short form has no lines and no wasted chrome
- **One scroll area.** Text areas and rich text editors inside an overlay grow with their content. They never get their own scrollbar inside a scrolling body. If a field needs a fixed height, the body does not scroll
- **Footer layout:** primary action on the right, Cancel beside it, a destructive action alone on the left. Buttons size to their label on desktop and stack full width only under 640px. The footer padding matches the header and body padding exactly
- **Do not disable the submit button until the form is valid.** A greyed out button explains nothing. Keep it enabled, validate on submit, move focus to the first invalid field and show the error next to it. Disable it only while the request is in flight, with a spinner and a verb (Saving)
- **No reserved blank space.** No fixed heights on the body, no `min-height` on tag inputs, text areas or lists larger than one row of content, no empty helper slots, and no padding after the last field beyond the body padding

### Pick the Container From the Content

| Content | Container |
|---------|-----------|
| A confirmation or one or two fields | Small modal, about 28rem |
| Up to about eight short fields | Form modal, about 36 to 40rem. Pair short related fields (min and max, start and end) in two columns |
| More than eight fields, a rich text editor, a generator panel or a live preview | Wide modal, about 48 to 56rem, with the secondary panel in a side column on desktop, or a side sheet |
| More than about fifteen fields, several sections, or the person needs the page behind for reference | A dedicated page or a stepper with its own URL |

When a modal grows past its container, change the container instead of shrinking the content. Collapse optional helpers (an AI writer, advanced settings) into a section that opens on request, group fields under short section headings, and move the rest to a sheet or a page.

### Fields in a Row Line Up

- Fields that share a row share the same label baseline and the same input baseline. Use a grid with `align-items: start` and give every label the same height
- Helper text belongs to every field in the row or to none. A single helper under one column leaves a hole under the other. Move it into the field (a unit suffix such as `%` or `min`) or below the whole row
- Units live in the input as a suffix, not in the label in brackets
- One spacing token between fields and a larger one between sections, the same in every overlay
- Toggle rows keep the label and description on the left and the switch on the right, vertically centered, with the same padding as the fields around them
- Under 640px every row becomes one column and the overlay becomes a full height sheet with the footer pinned above the keyboard (`100dvh`)

## Every Component Ships with Every State

Default, hover, focus-visible, active, disabled, loading, empty, error and success, where they apply. A screen is not done until its loading, empty and error states exist.

## Checking the Rules

Run the rule scan on the code you changed. It flags likely R1, R3, R4, R5, R6, R7, R9, R10, R11, R13 and R14 violations with file and line:

```bash
bash "<skill-dir>/scripts/rule-scan.sh" "<project-or-folder>"
```

On Windows without bash:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill-dir>/scripts/rule-scan.ps1" -Path "<project-or-folder>"
```

The scan is a heuristic. Check every finding by eye, fix the real ones, and check R2, R8, the rest of R10 and the rest of R14 in the rendered UI. For R14, open every form overlay with the most content it can hold and at a 700px tall window: the footer must be visible without scrolling and there must be one scrollbar. Check R12 by comparing the names and style of new files against the conventions report.
