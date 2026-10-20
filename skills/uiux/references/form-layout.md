# Form Layout

How to build forms that line up, every time. This is rule R17 in [build-rules.md](build-rules.md). What a form asks, how it validates and how it saves lives in [patterns/forms.md](patterns/forms.md). This file is only about geometry.

## Why Generated Forms Look Messy

These are the causes behind almost every crooked form. Check for each one before calling a form done.

| Cause | What the user sees | Fix |
|-------|--------------------|-----|
| Each row is its own flex container with free widths | Columns that do not continue from row to row | One grid on the form, fields span tracks |
| Labels of different length in a row | The input under a wrapping label sits lower than its neighbour | Subgrid rows: label row, control row, message row |
| An error or helper under one field in a row | The neighbour keeps its place but the next row jumps unevenly | The message slot is part of the subgrid row |
| Select, date picker and input come from different libraries | 36px, 40px and 42px tall controls side by side | One `--control-h` token used by every control |
| A button next to an input gets no label row | The button aligns with the label, not the input | Put the button in the control row (attached) or give it an empty label row through the subgrid |
| Checkbox groups indented by the control's own margin | Text starts a few pixels right of every other left edge | Zero margins on the control, gap on the group |
| Toggle rows built differently from field rows | Switches float at random x positions | One toggle row component, switch pinned to the right edge |
| Per field `margin-top` or `mt-1` tweaks | Uneven vertical rhythm | `gap` on the grid only, no margins on fields |
| Mixed label positions | Some labels above, some beside | Labels above everywhere. Beside only in a dedicated settings layout (below), never mixed in one form |

## Field Anatomy

Every field is the same four parts in the same order:

1. **Label** above the control, left aligned, sentence case, with `(optional)` after it when the field is optional. Required fields are marked as the form's convention says (see [patterns/forms.md](patterns/forms.md))
2. **Hint** under the label when the user needs it before typing (format, why we ask). Never inside the control as a placeholder only
3. **Control** at the shared height
4. **Message** under the control: the error when there is one. It is tied to the control with `aria-describedby`

Build this once as a `Field` component (or the project's existing one) and use it for every control type: text, select, combobox, date, number, file, textarea.

## The Grid

```css
:root {
  --control-h: 40px;
  --control-px: 12px;
  --control-radius: 6px;
  --field-gap: 20px;
  --section-gap: 40px;
  --label-gap: 6px;
}

.form {
  display: grid;
  grid-template-columns: repeat(6, minmax(0, 1fr));
  column-gap: 16px;
  row-gap: var(--field-gap);
  max-width: 40rem;
}

.field {
  grid-column: span 6;
  display: grid;
  grid-row: span 3;
  grid-template-rows: subgrid;
  row-gap: var(--label-gap);
  align-content: start;
}

.field--half { grid-column: span 3; }
.field--third { grid-column: span 2; }

.field > label { align-self: end; }
.field > .message:empty { display: none; }

.control {
  height: var(--control-h);
  padding-inline: var(--control-px);
  border: 1px solid var(--line);
  border-radius: var(--control-radius);
  font-size: 16px;
  width: 100%;
  box-sizing: border-box;
}

textarea.control { height: auto; min-height: calc(var(--control-h) * 2.5); padding-block: 8px; }

.form__section { grid-column: 1 / -1; margin-top: calc(var(--section-gap) - var(--field-gap)); }
.form__actions { grid-column: 1 / -1; display: flex; gap: 12px; }

@media (max-width: 640px) {
  .field, .field--half, .field--third { grid-column: 1 / -1; }
}
```

How it works:

- The form is one grid. Every field spans whole tracks, so a half width field always ends exactly where the field above it would split
- Each field takes three grid rows and passes them to its children with `subgrid`. In a row of two fields, both labels share row 1, both controls share row 2, both messages share row 3. A label that wraps to two lines moves both controls down together, so they stay level
- When a field has no hint, merge the hint into the label row (a `div` holding label and hint) so the subgrid stays three rows. Never let one field have four rows and its neighbour three
- `row-gap` on the form is the only vertical spacing between fields. No margins on fields
- Every control class sets the same height, padding, border and radius. Selects, combobox triggers, date picker triggers and number fields use `.control` too

Tailwind equivalent: `grid grid-cols-6 gap-x-4 gap-y-5` on the form, `col-span-6 sm:col-span-3 grid grid-rows-subgrid row-span-3 gap-y-1.5` on a field, and one `h-10 px-3 rounded-md border` class string shared by every control through the field component. If the project has a `cn` or variants helper, define the control classes once there.

## Widths

Width tells the user how long the answer is. Pick from the grid, never a free pixel width.

| Answer | Span of 6 | Examples |
|--------|-----------|----------|
| Long free text | 6 | Name, email, address line, title, URL |
| Medium | 3 | City, phone, date, a select with short options |
| Short fixed length | 2 | Postal code, year, CVV, quantity, percentage |
| Pairs | 3 and 3 | First and last name, start and end, min and max |

Keep the form itself to about 40rem wide on desktop. A 1200px wide email field is a layout bug, not a feature.

## Things That Sit in a Row

- **Input with an attached button** (search, copy, apply a code): one control group with a shared border, the button the same height as the input and inside the control row
- **Input with a unit or prefix:** the unit is an addon inside the control height (`Rp`, `%`, `min`), not text in the label
- **Range pairs:** two fields of span 3 with labels "From" and "To", or one range control. Never a dash floating between two inputs at a different height
- **Inline filter bars** above tables: one row, every control at `--control-h`, gap of one token, the clear action as a text button of the same height at the end

## Checkboxes, Radios and Switches

- A group is a `fieldset` whose `legend` sits where a label would. Options stack vertically with an 8 to 12px gap. Horizontal options only for two or three very short choices
- The box or circle aligns to the first line of its text (`align-items: start` and a top offset that centers it on the first line), and the group's left edge equals the other fields' left edge
- A single consent checkbox spans the whole grid width
- Switch rows: label and description left, switch right, centered vertically, full grid width, same vertical padding as a field row. Use these in settings (see [patterns/settings-account.md](patterns/settings-account.md)), not in forms that have a submit button

## Sections

- Long forms group fields under short section headings that span the grid. The gap above a heading is the section token, the gap below is the field token
- Optional and advanced fields go into a collapsed section with a clear label ("Advanced options"), not into a second column
- In settings pages a two column layout is allowed: the section title and description in a left column of about one third, the fields in the right two thirds. All sections use the same split

## Labels Beside Fields

Only for dense internal tools and settings where users scan labels. Then:

- The form grid gets `grid-template-columns: max-content minmax(0, 1fr)` and each field uses `grid-template-columns: subgrid` so all labels share one column sized by the longest label
- Labels are left aligned, short, and vertically centered on the control's first line
- Every field in that form uses the same layout. Under 640px labels move above

## Read Mode

A record shown read only (a detail page, a review step) uses a description list on the same grid: term on top or in a fixed left column, value below or beside, the same widths and gaps as the edit form. Switching between view and edit must not move anything except the values turning into controls.

## The Alignment Check

Run this in the browser on every form, at 1440 and 375 wide, once clean and once after submitting with errors. With agent-browser, pipe it to `agent-browser eval --stdin`. With other browser tools, run it in the page.

```js
(() => {
  const SEL = 'input:not([type=hidden]):not([type=checkbox]):not([type=radio]):not([type=range]), select, textarea, button, [role=combobox], [role=spinbutton]'
  const box = (el) => el.getBoundingClientRect()
  const shown = (el) => { const r = box(el); return r.width >= 24 && r.height >= 24 && getComputedStyle(el).visibility !== 'hidden' }
  const inside = (a, b) => { const r = box(a), s = box(b); return a !== b && r.left >= s.left && r.right <= s.right && r.top >= s.top && r.bottom <= s.bottom }
  const name = (el) => (el.getAttribute('aria-label') || el.labels?.[0]?.textContent || el.textContent || el.name || el.tagName).trim().replace(/\s+/g, ' ').slice(0, 30)
  const isField = (el) => el.tagName !== 'TEXTAREA' && !(el.tagName === 'BUTTON' && el.getAttribute('role') !== 'combobox')
  const out = []
  let roots = [...document.querySelectorAll('form, [role=form], [data-form]')]
  if (!roots.length) roots = [document.querySelector('main') || document.body]
  roots.forEach((root, i) => {
    const all = [...root.querySelectorAll(SEL)].filter(shown)
    const controls = all.filter((el) => !all.some((other) => inside(el, other)))
    const tag = `form ${i + 1}`
    const rows = []
    controls.sort((a, b) => box(a).top - box(b).top).forEach((el) => {
      const r = box(el), mid = r.top + r.height / 2
      const row = rows.find((x) => mid >= x.top && mid <= x.bottom)
      if (row) { row.items.push(el); row.bottom = Math.max(row.bottom, r.bottom) } else rows.push({ top: r.top, bottom: r.bottom, items: [el] })
    })
    rows.forEach((row) => {
      const items = row.items.filter((el) => el.tagName !== 'TEXTAREA')
      if (items.length < 2) return
      const tops = items.map((el) => Math.round(box(el).top))
      const heights = items.map((el) => Math.round(box(el).height))
      const labels = items.map((el) => el.labels?.[0]).filter(Boolean).map((l) => Math.round(box(l).top))
      const names = items.map(name).join(', ')
      if (Math.max(...tops) - Math.min(...tops) > 1) out.push(`${tag}: controls in one row start at different heights (${names}: ${tops.join(', ')})`)
      if (Math.max(...heights) - Math.min(...heights) > 1) out.push(`${tag}: controls in one row differ in height (${names}: ${heights.join(', ')}px)`)
      if (labels.length > 1 && Math.max(...labels) - Math.min(...labels) > 1) out.push(`${tag}: labels in one row start at different heights (${names})`)
    })
    const heights = [...new Set(controls.filter(isField).map((el) => Math.round(box(el).height)))].sort((a, b) => a - b)
    if (heights.length > 1) out.push(`${tag}: single line controls use ${heights.length} heights (${heights.join(', ')}px)`)
    const lefts = rows.map((row) => Math.min(...row.items.map((el) => Math.round(box(el).left))))
    const edge = Math.min(...lefts)
    rows.forEach((row, k) => {
      const d = lefts[k] - edge
      if (d > 1 && d < 16) out.push(`${tag}: row ${k + 1} starts ${d}px right of the form edge (${row.items.map(name).join(', ')})`)
    })
  })
  return out.length ? out.join('\n') : `ALIGNED: ${roots.length} form(s) checked`
})()
```

Every line it prints is a real misalignment unless the design calls for it (an indented sub question under a radio option is allowed). Fix and run it again until it prints `ALIGNED`. Then look at the screenshot: the left edges of labels, controls, checkboxes and buttons form one straight line.

## Sources

- [Form Field Usability: Avoid Extensive Multicolumn Layouts, Baymard](https://baymard.com/blog/avoid-multi-column-forms)
- [Form Field Usability: Matching User Expectations, Baymard](https://baymard.com/blog/form-field-usability-matching-user-expectations)
- [Group Form Elements Effectively Using White Space, NN/g](https://www.nngroup.com/articles/form-design-white-space/)
- [Placeholders in Form Fields Are Harmful, NN/g](https://www.nngroup.com/articles/form-design-placeholders/)
- [Label Placement in Forms, UXmatters](https://www.uxmatters.com/mt/archives/2006/07/label-placement-in-forms.php)
- [Question pages, GOV.UK Design System](https://design-system.service.gov.uk/patterns/question-pages)
- [CSS subgrid, MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_grid_layout/Subgrid)
