# AI Design Slop Pattern Catalog

## Severity Levels

- **P0** — Screams AI on sight. Instant tell.
- **P1** — Obvious AI smell. Trained eyes spot immediately.
- **P2** — Cosmetic AI pattern. Subtle but contributes to the "vibe-coded" feel.

---

## Color Patterns

### P0

| ID | Pattern | Detection |
|----|---------|-----------|
| C01 | Purple-to-Blue Gradient | `from-indigo-500 to-purple-600`, `from-purple-* to-blue-*`, gradient with hues 240-280 |
| C02 | VibeCode Purple | Primary color clustering around `#8B5CF6`, `bg-violet-500`, lavender-purple accent |
| C03 | Cyan-on-Dark | `text-cyan-400` on `bg-slate-900/950`, neon cyan as primary accent on dark theme |
| C04 | Neon Glow Borders | `box-shadow: 0 0 20px rgba(color, 0.8)`, colored `ring-*` at full saturation on dark |

### P1

| ID | Pattern | Detection |
|----|---------|-----------|
| C05 | Untouched Zinc/Slate Neutrals | `bg-zinc-*`, `bg-slate-*` as sole neutral palette, no customization |
| C06 | Gradient Text on Headings | `bg-clip-text text-transparent bg-gradient-to-r` on `h1`-`h3` |
| C07 | Cream/Beige Default Surface | `bg-amber-50`, `bg-stone-50`, warm beige as background without brand reason |
| C08 | Dark Mode Colored Glows | `shadow-[0_0_20px_rgba(139,92,246,0.3)]` or similar colored shadow |
| C09 | Timid Even Palette | Multiple accent colors at similar saturation, no dominant/accent hierarchy |

### P2

| ID | Pattern | Detection |
|----|---------|-----------|
| C10 | Safe Green Fallback | `bg-emerald-500` as "alternative to purple" without brand logic |
| C11 | Pure White/Black No Nuance | `#fff` or `#000` backgrounds with zero warmth or depth |
| C12 | Rainbow Accent Bars | Each sibling card has different `border-l-*` color cycling through palette |

---

## Typography Patterns

### P0

| ID | Pattern | Detection |
|----|---------|-----------|
| T01 | Inter Everywhere | `font-family: 'Inter'` as sole font across all elements |
| T02 | Single Font Everything | Computed font-family identical on `h1` through `p`, `button`, `label` |
| T03 | Oversized Italic Serif Hero | `font-style: italic` + serif family on hero `h1`, often Instrument Serif or Playfair |

### P1

| ID | Pattern | Detection |
|----|---------|-----------|
| T04 | Repeated AI Font Combos | Space Grotesk + Instrument Serif, Geist everywhere, Satoshi + Clash Display |
| T05 | Serif Italic Accent Word | Mixed `font-family` within single heading (one word italic serif, rest sans) |
| T06 | All-Caps Section Labels | `text-transform: uppercase` + `letter-spacing: 0.05em+` on section kickers |
| T07 | Flat Type Hierarchy | Size ratio between adjacent heading levels < 1.25 |
| T08 | Crushed Letter Spacing | `letter-spacing` below -0.02em on body text |

### P2

| ID | Pattern | Detection |
|----|---------|-----------|
| T09 | Monospace Body Copy | `font-family` containing "mono"/"courier" on `<p>` tags |
| T10 | No Type Scale System | Heading sizes don't follow any ratio (1.25/1.333/1.5) |
| T11 | Wide Letter Spacing Body | `letter-spacing > 0.05em` on body text |

---

## Layout Patterns

### P0

| ID | Pattern | Detection |
|----|---------|-----------|
| L01 | Canned Skeleton | Hero → 3 Feature Cards → Logo Strip → Pricing → FAQ → Footer in exact order |
| L02 | Centered Hero + Pill Badge | Small uppercase pill/badge sitting above oversized centered hero `h1` |
| L03 | Three Feature Cards | Exactly 3 identical cards in a row: icon + heading + text |
| L04 | Reflexive Bento Grid | CSS grid with mixed `col-span-*` on a marketing page with no content justification |

### P1

| ID | Pattern | Detection |
|----|---------|-----------|
| L05 | Colored Left-Border Cards | `border-left: 3-4px solid [color]` or `border-l-4 border-purple-500` |
| L06 | Numbered Step Sequences | "1, 2, 3" step flows, always exactly three steps |
| L07 | Stat Banner Rows | Horizontal 3-4 big numbers with small labels, full-width |
| L08 | Nested Card Stacking | Cards inside cards, 3-5 levels of nesting with own padding/shadow each |
| L09 | Hero Metric Layout | Big number + small label + gradient accent line on left |
| L10 | Sidebar Emoji Icons | Navigation using emoji characters instead of SVG/icon library |
| L11 | Dashboard Template Default | Sidebar (240-280px) + 4-6 KPI cards + charts below |

### P2

| ID | Pattern | Detection |
|----|---------|-----------|
| L12 | Monotonous Spacing | Same gap/padding value repeated across all sections |
| L13 | Repeated Section Kickers | Tiny uppercase tracked label above every `h2`/`h3` |
| L14 | Decorative Number Markers | Large display numbers as section labels for non-sequential content |

---

## Component Patterns

### P0

| ID | Pattern | Detection |
|----|---------|-----------|
| K01 | Icon-in-Rounded-Square | `bg-{accent}-50 rounded-lg p-2` + Lucide/Heroicon above heading in feature card |
| K02 | Reflexive Glassmorphism | `backdrop-filter: blur(10px)` + `bg-white/10` + semi-transparent border everywhere |
| K03 | Untouched shadcn Defaults | `rounded-2xl shadow-lg p-6` on every surface, default shadcn card |
| K04 | Purple/Violet Gradient Orbs | Absolute-positioned `bg-gradient-to-*` + `blur-3xl` + `opacity-*` blobs behind hero |

### P1

| ID | Pattern | Detection |
|----|---------|-----------|
| K05 | Ghost Cards | `border border-gray-200 shadow-lg rounded-xl` on every container |
| K06 | Gray 1px Border Everything | `border border-zinc-200` applied to all cards uniformly |
| K07 | Floating 3D Abstract Blobs | Positioned elements with 3D transforms or SVG abstract shapes |
| K08 | Mandatory FAQ Accordion | FAQ accordion at page bottom regardless of product needs |
| K09 | Logo Cloud Strip | "Trusted by" logo bar with recognizable company logos |
| K10 | Testimonial Card Grid | Identical card format: circular avatar + name + title + quote |
| K11 | Pill Badge Everywhere | Small rounded-full pill badges used for every label, tag, status |

### P2

| ID | Pattern | Detection |
|----|---------|-----------|
| K12 | Emoji Feature Bullets | Emoji Unicode characters as feature list icons |
| K13 | Status Dots No Meaning | Small colored circles on elements with no defined state |
| K14 | Decorative Stripe Patterns | `repeating-linear-gradient` as surface decoration |

---

## Content & Copy Patterns

### P0

| ID | Pattern | Detection |
|----|---------|-----------|
| X01 | Marketing Buzzwords | "Streamline," "empower," "supercharge," "world-class," "enterprise-grade," "cutting-edge," "best-in-class," "revolutionary" |
| X02 | Vague Aspirational Headlines | "Build the future of," "Your all-in-one platform," "Scale without limits," "Elevate your workflow" |
| X03 | Fake Social Proof | "Trusted by X,000+ teams" on new/unknown products with no evidence |

### P1

| ID | Pattern | Detection |
|----|---------|-----------|
| X04 | Em-Dash Overuse | More than 2 em-dashes (`—`) per paragraph in body copy |
| X05 | Abstract Opening Verbs | "Unlock," "Transform," "Discover," "Reimagine" as section openers |
| X06 | Hedging Value Props | "May help you," "can potentially," "designed to possibly" in value proposition |
| X07 | Generic Audience Copy | "For modern teams," "for forward-thinking companies," "for the next generation" |
| X08 | Beta Announcement Badge | Pill badge above hero with "Now in beta," "New," "Introducing" |
| X09 | Aphoristic Cadence | Short punchy rebuttals and manufactured-contrast sentences repeated |

### P2

| ID | Pattern | Detection |
|----|---------|-----------|
| X10 | Theater Framing | Word "theater" used dismissively in copy |
| X11 | Generic Stock Imagery | Diverse team at laptop, too smooth, overly symmetrical photos |
| X12 | Placeholder-Quality Copy | Copy that reads like slightly-better lorem ipsum with no specifics |

---

## Interaction & Motion Patterns

### P0

| ID | Pattern | Detection |
|----|---------|-----------|
| M01 | Uniform Fade-In Everything | Same fade-in animation on every element on scroll enter |
| M02 | Bounce/Elastic Easing | Dialogs that spring, cards that overshoot with `cubic-bezier` bounce curves |

### P1

| ID | Pattern | Detection |
|----|---------|-----------|
| M03 | Image Hover Transform | `hover:scale-*` or `hover:rotate-*` on `<img>` elements |
| M04 | Decorative Parallax | Background parallax layers with `transform: translateZ()` |
| M05 | No Transition on Buttons | Missing `transition` property on button hover/active states |
| M06 | Meaningless Hover States | `:hover` that only changes opacity slightly, communicates nothing |
| M07 | Cursor Followers | Custom element following mouse position via JS |

### P2

| ID | Pattern | Detection |
|----|---------|-----------|
| M08 | Staggered Scroll Reveals | `animation-delay` incrementing across sibling elements |
| M09 | Layout Property Animation | Transitions on width/height/padding instead of transform/opacity |

---

## Structural Meta Patterns

### P0

| ID | Pattern | Detection |
|----|---------|-----------|
| S01 | Permanent Dark Mode | Dark background as default with no light mode toggle (34% of AI sites) |

### P1

| ID | Pattern | Detection |
|----|---------|-----------|
| S02 | Missing UI States | No `:focus-visible`, `[disabled]`, `.error`, empty, loading states |
| S03 | Inconsistent Shadow Recipes | Multiple different `box-shadow` values across components, no system |
| S04 | 16px Border Radius Everywhere | Single `border-radius` value on all elements |
| S05 | No Responsive Consideration | Desktop-only layout with missing/broken media queries |
| S06 | Inline Styles Everywhere | High count of `style=""` attributes from AI generation |

---

## Scoring

### Slop Score Calculation

```
p0_count × 10 + p1_count × 5 + p2_count × 2 = raw_slop_score
```

| Raw Score | Rating | Verdict |
|-----------|--------|---------|
| 0-10 | Clean | No significant AI patterns detected |
| 11-25 | Mild | Some AI defaults present, minor cleanup needed |
| 26-50 | Moderate | Clearly AI-generated, needs design pass |
| 51-80 | Heavy Slop | Significant redesign needed |
| 81+ | Maximum Slop | Complete AI template, zero human design input |

### Category Breakdown

Report slop density per category:
- Colors: X patterns found
- Typography: X patterns found
- Layout: X patterns found
- Components: X patterns found
- Content: X patterns found
- Motion: X patterns found
- Structure: X patterns found
