# Polish Pass

Twenty small fixes that separate a finished interface from a generated one. This is rule R20 in [build-rules.md](build-rules.md). Run it on everything in scope after the screen works and before the UI Review. Many items are owned by an earlier rule. Those rows point to it and add only what the earlier rule does not say.

| # | Item | Owner |
|---|------|-------|
| 1 | Delete filler badges | R20, styled by R4 |
| 2 | Drop redundant labels | R20 |
| 3 | Unitalicize random words | R20, slop T03 and T05 |
| 4 | Mono only where needed | R20, slop T09 |
| 5 | Use a design system | R8, R12 |
| 6 | Show the actual product | R15, R16 |
| 7 | Enlarge the main feature | R20, R2, R8 |
| 8 | Group with spacing | R20, R8, R17 |
| 9 | Make headlines specific | R20, slop X02, X09, X12 |
| 10 | Emphasize the CTA | R20, R16 |
| 11 | Add an accent color | R1, [color.md](color.md) |
| 12 | Keep icons consistent | R20, R3, R15 |
| 13 | Remove embellishments | R15 |
| 14 | Inner radius equals outer radius minus padding | R20 |
| 15 | Improve text contrast | R20, R1, [color.md](color.md) |
| 16 | Wrap headlines properly | R20 |
| 17 | Align by eye, not by pixels | R20 |
| 18 | Use tabular numbers | R20, [content-format.md](patterns/content-format.md) |
| 19 | Add loading states | R10, R14, [feedback.md](patterns/feedback.md) |
| 20 | Animate useful feedback | R18, [motion.md](motion.md) |

## Cut

### 1. Delete Filler Badges

A badge earns its place only when it changes what the user does next: an unread count, a required action, a state that differs from the default. Delete the rest.

- "New" on a feature that shipped months ago, "Beta" or "Introducing" above a hero, "AI powered", "Hot", "Popular" on every plan, "Pro" on half the menu
- A badge that repeats the column, heading or text next to it ("Active" in a list already filtered to active)
- A count badge showing 0. Hide it until there is something to count
- One badge per item in a list. When every row has one, none stands out

Badges that stay use one of the R4 treatments, never a tinted pill.

### 2. Drop Redundant Labels

Remove a label when the content, the heading or the control already says the same thing.

- "Email: ana@markwise.school" in a profile card. The address explains itself
- A "Features" heading above a section that is plainly features. Write a heading that says something (item 9) or none
- "Name" repeated inside every cell of a Name column
- A tooltip or `title` that repeats the visible button text
- "Click here to download", "Submit form". The button says the verb and the object ("Download report")
- A placeholder that repeats the field label ("Email" over "Email")

Never remove a form field's label (R17) or a control's accessible name. Removing a visible label that a screen reader needs means moving it into `aria-label`, not deleting it.

### 13. Remove Embellishments

Owned by R15. For every decorative element ask: if it disappears, does the user lose information? If not, delete it. That covers blobs, dot grids, glows, gradient borders, decorative lines, floating shapes, sparkles and shadows on everything.

## Type

### 3. Unitalicize Random Words

No italic accent word inside a heading, no italic serif hero, no italic for emphasis on a random phrase (slop T03 and T05).

Italic is for titles of works, a term at the point it is defined, foreign words and quoted speech. Emphasis uses weight or color from the tokens, never a switch of font family in the middle of a line.

### 4. Mono Only Where Needed

Monospace is for text a person reads or copies character by character: code, commands, keyboard keys, file paths, IDs, hashes, API keys and version numbers.

Never use it for eyebrows, section labels, navigation, buttons, prices, dates, stats or body text (slop T09). A mono uppercase label with wide tracking above every section is a template tell. Numbers that need to line up use tabular figures of the main font (item 18), not a mono font.

### 9. Make Headlines Specific

A headline says what this product does, for whom, or what result the user gets, with a concrete noun or number from the user.

- Test: could it sit on a competitor's site unchanged? Then rewrite it. "Build the future of work" fails. "Grade a class of quizzes in two minutes" passes
- No "It's not X, it's Y" and no "Less X. More Y." (X09)
- App screens too: page titles name the object and the scope ("Invoices for March", "3 students need grading"), empty states say what to do next
- Never invent a number or a claim to sound specific. Ask the user (R16)

### 16. Wrap Headlines Properly

- `text-wrap: balance` on h1 to h3, card titles, short centered text and hero subtitles. `text-wrap: pretty` on paragraphs so the last line is never a single word. In Tailwind: `text-balance` and `text-pretty`
- Headlines get a measure (`max-width` about 20 to 35ch), paragraphs 45 to 75ch. A headline that runs the full width of a 1440 screen is not wrapped, it is stretched
- Never force breaks with `<br>`. It breaks the line in the wrong place at every other width. Use balance, a `max-width`, or `&nbsp;` to keep a brand name, a number and its unit, or a short final pair together
- Headline line height 1.05 to 1.25, tighter than body text. No hyphenation in headings
- Check at 375, 768 and 1440: no line holds one word alone, and no line ends on "a", "the", "of" or "to" when a balanced break exists

### 18. Use Tabular Numbers

Set `font-variant-numeric: tabular-nums` (Tailwind `tabular-nums`) on every number that changes in place or sits in a column: table cells, prices, totals, stats, counters, timers, progress, pagination ranges, dates in lists and chart axes. Digits then keep one width, columns line up and a ticking counter does not wobble.

- Right align numeric columns and keep the same decimals in a column ([content-format.md](patterns/content-format.md))
- Keep proportional figures in running prose
- Check that the chosen font has the `tnum` feature. Most text fonts do, some display fonts do not. If it does not, pick a font that does instead of switching to mono

## Hierarchy

### 7. Enlarge the Main Feature

The one thing a screen or section is about gets visibly more size than everything else, about 1.5 to 2 times the next element.

- On a landing page, the main feature gets a large real screenshot or demo, not a card equal to three others
- On a dashboard, the metric that matters most is larger than the rest (R2)
- In an app screen, the main content column is wider than any side panel, and the main task sits first (R8)

If everything is the same size, nothing is the main feature.

### 8. Group with Spacing

Proximity groups before borders do.

- The gap inside a group is clearly smaller than the gap between groups, about half or less
- A label sits closer to its control than to the field above it. A heading sits closer to its own section than to the section before it, so its top margin is larger than its bottom margin
- Use spacing tokens only (R8), with one gap between fields and a larger one between sections (R17)
- Try spacing first. Add a divider, border or card only when spacing alone does not separate the groups

### 10. Emphasize the CTA

- One primary action per view. It is the filled button in the primary color and the highest contrast element on the screen
- Secondary actions are outline or text buttons. Never two filled buttons of equal weight side by side
- The label names the outcome with a verb ("Start free trial", "Send invoice"), never "Submit" or "Click here"
- Placement and size follow R16 on public pages and R14 and R17 in forms. The primary button is as tall as the inputs in its row

## Detail

### 12. Keep Icons Consistent

- One icon set for the whole product. Never mix Lucide with Heroicons, Font Awesome or emoji
- One stroke width (for example 1.5 or 2) and one style. Outline everywhere, filled only to mark the active or selected state
- Sizes come from tokens matched to the text beside them: about 16px next to 14px text, 20px next to 16px text
- Icons take the text color of their label and center on the text, not on the line box
- One concept, one icon. If a gear means settings in the sidebar, it means settings everywhere
- No icon in a tile (R3), no icon before every heading or button (R15)

### 14. Inner Radius Equals Outer Radius Minus Padding

When a rounded shape sits inside another rounded shape, the corners must be concentric:

```css
.card { --radius: 16px; --pad: 8px; border-radius: var(--radius); padding: var(--pad); }
.card > .media { border-radius: max(0px, calc(var(--radius) - var(--pad))); }
```

- A card at 16px with 8px padding holds an image at 8px. The same radius on both makes the inner corners look swollen
- It applies to an image in a card, a button inside an input, the selected segment of a segmented control, the highlighted item of a menu, a thumbnail in a tile and a code block in a panel
- When the padding is equal to or larger than the outer radius, the inner element is square, or takes its own small control radius from the R8 scale when it is a control
- Define the outer radius and the padding as tokens so the inner radius is derived, never typed by hand

### 15. Improve Text Contrast

Owned by R1 and [color.md](color.md). The common failure is muted secondary text.

- Body text reaches 4.5:1 and aims for 7:1. Secondary and helper text still reaches 4.5:1
- Tailwind `gray-400` (`#9ca3af`) on white is about 2.5:1 and fails. `gray-500` (`#6b7280`) is about 4.8:1 and passes. The same holds for the slate, zinc, neutral and stone scales
- Placeholder text is text and reaches 4.5:1. Disabled text may fall below, but stays distinguishable
- Text over an image sits on a scrim or a solid surface, checked at the image's lightest point
- Measure with `palette-check` or a contrast tool, never by eye

### 17. Align by Eye, Not by Pixels

Geometric centering is not visual centering. Adjust where the math looks wrong.

- **Play and arrow glyphs.** A triangle centered by its box looks off to the left. Nudge it toward its point by about a tenth of its width
- **Icon buttons and icon plus text.** Give the icon side a little less padding than the text side (for example 12px and 16px) so the content looks centered
- **Round and pointed shapes.** Circles and triangles need to be slightly larger than squares to look the same size
- **Text and icons.** Center icons on the text's cap height or x height, not on the line box. Where supported, `text-box: trim-both cap alphabetic` removes the extra space above and below text so labels center in buttons and badges
- **Large headings.** A big heading's first letter carries side bearing. Pull it left with a small negative margin (about `-0.04em`) so its edge lines up with the body text below
- **Quotes and bullets.** Opening quote marks and list markers hang outside the text edge so the letters align (`hanging-punctuation: first` where supported, or a negative `text-indent`)

Check on a zoomed screenshot and by squinting. If it looks off, it is off, whatever the inspector says.

## Color, Loading and Feedback

### 11. Add an Accent Color

Owned by R1 and [color.md](color.md). The accent is about 10% of the screen and marks the one thing to notice: the primary action, the current location, a key data point. A screen of only neutrals where nothing stands out gets the accent on its primary action and its active state. An accent used on everything stops being an accent.

### 19. Add Loading States

Owned by R10, R14 and [feedback.md](patterns/feedback.md). Skeletons shaped like the content for anything that loads, a spinner with a verb on a button while its request is in flight ("Saving"), optimistic updates where safe, and never a blank screen. If a response usually arrives in under about 300ms, delay the indicator so it does not flash, and once shown keep it long enough to read.

### 20. Animate Useful Feedback

Owned by R18 and [motion.md](motion.md). Animate what confirms an action or explains a change: a saved check, a copied label, a row entering the list it was added to, a count updating, a toast with undo. Never animate for decoration.

### 5 and 6. Design System and Real Product

Use a design system: R8 tokens, one component per job, and the project's own components first (R12). Show the actual product: a real screenshot, recording or live demo (R15, R16).

## Check

Go through the twenty items on screenshots at 1440x900 and 375x812 and in the code you changed:

1. Run the rule scan. The R20 leads cover italic words in headings, decorative mono labels, forced breaks in headings, faint gray text and formatted numbers without tabular figures
2. Count the badges on each screen and delete every one that does not change what the user does next
3. Read every label and heading and delete the ones the content already says
4. Find the main feature and the primary action on each screen in under five seconds. If you cannot, enlarge or emphasize them
5. Resize each headline from 375 to 1440 and look for a lone last word or a forced break
6. Zoom into every nested rounded shape and check the corners are concentric
7. Zoom into every icon button and icon plus text pair and check they look centered
8. Watch a changing number and a numeric column. The digits must not shift
9. Throttle the network and trigger every action once. Each one shows a loading state and confirms when done

## Sources

- [text-wrap, MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/text-wrap)
- [font-variant-numeric, MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/font-variant-numeric)
- [hanging-punctuation, MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/hanging-punctuation)
- [Proximity Principle in Visual Design, NN/g](https://www.nngroup.com/articles/gestalt-proximity/)
- [Contrast and Color Accessibility, WebAIM](https://webaim.org/articles/contrast/)
