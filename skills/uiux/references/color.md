# Color Picking

How to choose and check a palette, for building and for auditing. Rule R1 in [build-rules.md](build-rules.md) makes pastel the default when the user has not chosen colors.

## Principles

1. **Proportion, 60-30-10.** About 60% of the area is the dominant color, 30% secondary, 10% accent. In product UI the 60% is almost always a neutral or near-neutral background, the 30% is surfaces such as panels, sidebars and headers, and the 10% is reserved for actions and key signals. A palette with five equally loud colors has no hierarchy (slop pattern C09).
2. **One hue family leads.** Pick one primary hue for the product, one accent hue that contrasts with it, tinted neutrals, and semantic colors for success, warning, danger and info. That is the whole palette.
3. **Color supports meaning, never carries it alone.** Every state shown in color is also shown in text, shape or position (WCAG 1.4.1).
4. **Contrast is measured, not eyeballed.** Normal text needs 4.5:1, large text (24px, or 18.66px bold) needs 3:1, and UI parts that carry meaning (input borders, focus rings, icons, chart lines) need 3:1 against every color they touch (WCAG 1.4.3 and 1.4.11).
5. **Same job, same color.** Links, primary buttons, focus rings and selected states each get one color that never changes across screens (Golden Rule 1 in [golden-rules.md](golden-rules.md)).

## Build Palettes in OKLCH

OKLCH is perceptually uniform, so equal lightness steps look equal across hues, unlike HSL, where a yellow and a blue at the same lightness look very different. Define tokens in `oklch(L C H)` and derive every shade from the same hue.

OKLCH lightness is not the same as WCAG luminance, so always check the actual contrast ratio.

## Default Pastel Recipe

Use this when the user has not named colors.

1. **Choose the hue from the product.** Calm and trustworthy (health, finance, education): teal or sage around H 160-200, or slate blue around H 230-250. Warm and friendly (community, food, kids): peach or apricot around H 40-70. Growth and nature: sage or moss around H 130-150. Avoid violet and lavender (H 270-300) as a default, because that is the most common AI tell (C02). Pick a different hue for each project unless the brand dictates one.
2. **Accent hue:** 120 to 180 degrees away from the primary, at the same low chroma.
3. **Build the scale per hue:**

| Token | OKLCH L | OKLCH C | Use |
|-------|---------|---------|-----|
| `bg` | 0.97-0.99 | 0.005-0.015 | Page background (the 60%) |
| `surface` | 0.94-0.96 | 0.01-0.03 | Panels, sidebars, table header (the 30%) |
| `tint` | 0.88-0.93 | 0.03-0.07 | Selected rows, hover, highlighted areas |
| `soft` | 0.80-0.86 | 0.05-0.09 | Primary button fill, active nav marker |
| `line` | 0.55-0.65 | 0.04-0.08 | Input borders, focus rings, meaningful icons (reaches 3:1 on `bg`) |
| `strong` | 0.40-0.48 | 0.06-0.10 | Links, text on `tint` and `soft` |
| `ink` | 0.20-0.28 | 0.02-0.05 | Body text and headings |

4. **Neutrals** share the primary hue at very low chroma (C 0.005-0.02), so grays feel related rather than default zinc or slate (C05).
5. **Semantic colors** use the same lightness steps: success around H 150, warning around H 80, danger around H 25, info around H 240. Danger may carry a little more chroma than the rest so it wins attention.
6. **Buttons:** primary is a `soft` fill with `ink` text, or a `strong` fill with near-white text. Check both. Never pastel text on a pastel fill.

Example shape of the tokens:

```css
:root {
  --bg: oklch(0.985 0.008 190);
  --surface: oklch(0.955 0.02 190);
  --tint: oklch(0.91 0.05 190);
  --soft: oklch(0.83 0.07 190);
  --line: oklch(0.6 0.06 190);
  --strong: oklch(0.44 0.08 190);
  --ink: oklch(0.24 0.03 190);
  --accent-soft: oklch(0.86 0.07 45);
  --accent-strong: oklch(0.47 0.1 45);
}
```

## Dark Mode

Keep the same hues. Swap the lightness roles: background around L 0.18-0.22 with a little chroma, surfaces a step lighter, text around L 0.92-0.95. Lower chroma slightly so pastels do not glow. Recheck every contrast pair.

## Checks

- Measure contrast for: body text on `bg` and `surface`, text on every fill, links, placeholder text, disabled text (it may fail, but must still be distinguishable), input borders, focus rings, and chart series against the background.
- Squint test: the one primary action per screen should be the first thing you notice.
- Grayscale test: view a screenshot in grayscale. States should still be distinguishable by text, shape or position.
- No saturated default fills (C13), no rainbow of sibling cards (C12), no purple gradient (C01).

## Sources

- [Using Color to Enhance Your Design, NN/g](https://www.nngroup.com/articles/color-enhance-design/)
- [OKLCH in CSS: why we moved from RGB and HSL, Evil Martians](https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl)
- [OKLCH in CSS: consistent, accessible color palettes, LogRocket](https://blog.logrocket.com/oklch-css-consistent-accessible-color-palettes)
- [The 60-30-10 rule, LogRocket](https://blog.logrocket.com/ux-design/60-30-10-rule/)
- [Contrast and Color Accessibility, WebAIM](https://webaim.org/articles/contrast/)
- [Color contrast, MDN](https://developer.mozilla.org/en-US/docs/Web/Accessibility/Guides/Understanding_WCAG/Perceivable/Color_contrast)
