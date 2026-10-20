# Color Picking

How to choose and check a palette, for building and for auditing. Rule R1 in [build-rules.md](build-rules.md) makes a random Color Hunt palette the default when the user has not chosen colors.

## Principles

1. **Proportion, 60-30-10.** About 60% of the area is the dominant color, 30% secondary, 10% accent. In product UI the 60% is almost always a neutral or near-neutral background, the 30% is surfaces such as panels, sidebars and headers, and the 10% is reserved for actions and key signals. A palette with five equally loud colors has no hierarchy (slop pattern C09).
2. **One hue family leads.** Pick one primary hue for the product, one accent hue that contrasts with it, tinted neutrals, and semantic colors for success, warning, danger and info. That is the whole palette.
3. **Color supports meaning, never carries it alone.** Every state shown in color is also shown in text, shape or position (WCAG 1.4.1).
4. **Contrast is measured, not eyeballed.** Normal text needs 4.5:1, large text (24px, or 18.66px bold) needs 3:1, and UI parts that carry meaning (input borders, focus rings, icons, chart lines) need 3:1 against every color they touch (WCAG 1.4.3 and 1.4.11).
5. **Same job, same color.** Links, primary buttons, focus rings and selected states each get one color that never changes across screens (Golden Rule 1 in [golden-rules.md](golden-rules.md)).

## Build Palettes in OKLCH

OKLCH is perceptually uniform, so equal lightness steps look equal across hues, unlike HSL, where a yellow and a blue at the same lightness look very different. Define tokens in `oklch(L C H)` and derive every shade from the same hue.

OKLCH lightness is not the same as WCAG luminance, so always check the actual contrast ratio.

## Default: a Random Color Hunt Palette

Use this when the user has not named colors.

1. **Pick the palette at random.** Run `bash "<skill-dir>/scripts/pick-palette.sh"` (or `pick-palette.ps1` on Windows). It picks one palette from [palettes.txt](palettes.txt), a snapshot of the Color Hunt popular all time list (https://colorhunt.co/palettes/popular) with every purple, violet, lavender and magenta palette removed. It prints the palette link, the four hex colors and the same colors in OKLCH. Do not pick a favorite by hand, and do not use the same palette for two projects.
2. **Never use purple.** No color with OKLCH hue between 265 and 335 at chroma above 0.03 goes into the UI, not even as an extra shade you derive. The snapshot already leaves those palettes out. Use purple only when the user names it.
3. **Apply the palette colors as they are.** Put the four hex values into the tokens unchanged. Do not shift their hue, lightness or chroma to make them pastel or to match a recipe. Map them by role:

| Palette color | Token | Use |
|---------------|-------|-----|
| Lightest color (OKLCH L 0.9 or higher) | `bg` | Page background (the 60%) |
| Next lightest | `surface`, `tint` | Panels, sidebars, table header, selected rows (the 30%) |
| Most saturated color | `primary` | Primary button fill, active nav marker, links when contrast allows (the 10%) |
| Remaining color | `accent` | Secondary highlights, charts, state markers |
| Darkest color (L 0.35 or lower) | `ink` | Body text and headings |

4. **Fill only the roles the palette leaves empty.** When no palette color is light enough for `bg`, use white or a near-white with the hue of the lightest palette color at chroma 0.01 or less. When no color is dark enough for `ink`, use the hue of the darkest palette color at L 0.22 to 0.26. Derive `line` (borders, focus rings) and text on fills the same way. Every derived color takes its hue from a palette color and is listed as derived when you state the palette.
5. **Contrast decides where a color may go, not whether it is used.** If a palette color fails 4.5:1 as text, keep it as a fill or surface and put `ink` or near-white text on it. If button text fails on the `primary` fill, pick the text color that passes (near-white or `ink`), never a lighter tint of the fill.
6. **Semantic colors** for success, warning, danger and info come from the palette when it has a fitting hue (green for success, red or coral for danger). Otherwise derive them: success around H 150, warning around H 80, danger around H 25, info around H 240, at the same lightness as `primary`.
7. **If the palette cannot work,** for example four near-identical light tints with no usable fill, run the picker again. Say that you rerolled and why.

State the palette before writing code: the Color Hunt link, which hex goes to which token, and every derived color.

Example with the palette https://colorhunt.co/palette/f9f7f7dbe2ef3f72af112d4e:

```css
:root {
  --bg: #f9f7f7;
  --surface: #dbe2ef;
  --primary: #3f72af;
  --on-primary: #ffffff;
  --ink: #112d4e;
  --line: oklch(0.6 0.05 254);
}
```

Here `--on-primary` and `--line` are derived. The palette has no accent, so links use `--primary` and danger is derived at H 25.

## Dark Mode

Keep the palette. Use its darkest color as the background when its L is 0.3 or lower, otherwise derive a background from its hue at L 0.18 to 0.22. Surfaces are a step lighter in the same hue, and text is the lightest palette color or a near-white with its hue. Keep `primary` and `accent` as they are when they pass contrast on the dark background, and lighten them only when they fail. Recheck every contrast pair.

## Checks

- Measure contrast for: body text on `bg` and `surface`, text on every fill, links, placeholder text, disabled text (it may fail, but must still be distinguishable), input borders, focus rings, and chart series against the background.
- Squint test: the one primary action per screen should be the first thing you notice.
- Grayscale test: view a screenshot in grayscale. States should still be distinguishable by text, shape or position.
- No saturated default fills (C13), no rainbow of sibling cards (C12), no purple gradient (C01).
- No stock pastel rainbow (C17), harsh multi hue gradient (C14), purple on black (C15) or neon accent (C16). Each palette color keeps one role, not one color per card.
- No purple anywhere unless the user asked for it.

## Sources

- [Using Color to Enhance Your Design, NN/g](https://www.nngroup.com/articles/color-enhance-design/)
- [OKLCH in CSS: why we moved from RGB and HSL, Evil Martians](https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl)
- [OKLCH in CSS: consistent, accessible color palettes, LogRocket](https://blog.logrocket.com/oklch-css-consistent-accessible-color-palettes)
- [The 60-30-10 rule, LogRocket](https://blog.logrocket.com/ux-design/60-30-10-rule/)
- [Contrast and Color Accessibility, WebAIM](https://webaim.org/articles/contrast/)
- [Color contrast, MDN](https://developer.mozilla.org/en-US/docs/Web/Accessibility/Guides/Understanding_WCAG/Perceivable/Color_contrast)
