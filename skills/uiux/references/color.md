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

1. **Pick the palette at random.** Run `bash "<skill-dir>/scripts/pick-palette.sh"` (or `pick-palette.ps1` on Windows). It picks one palette from [palettes.txt](palettes.txt), a snapshot of the Color Hunt popular all time list (https://colorhunt.co/palettes/popular) with every purple, violet, lavender and magenta palette removed, and every palette that fails the eye comfort check removed. It prints the palette link, the four hex colors and the same colors in OKLCH. Do not pick a favorite by hand, and do not use the same palette for two projects.
2. **Check it for eye comfort.** Run `bash "<skill-dir>/scripts/palette-check.sh" <hex> <hex> <hex> <hex>` (or `palette-check.ps1` on Windows). It assigns the roles below, measures every text pair in WCAG ratio and APCA Lc, and flags oversaturated and neon colors, strongly tinted backgrounds, saturated surfaces, red and blue pairs, colors that look alike to color blind users, and dark mode risks. A `FAIL` means run the picker again. Every `WARN` gets the fix it names, applied in the tokens and stated with the palette. Follow each `NOTE` when placing colors. Run it on the user's own colors too, and once more on the final tokens including derived ones.
3. **Never use purple.** No color with OKLCH hue between 265 and 335 at chroma above 0.03 goes into the UI, not even as an extra shade you derive. The snapshot already leaves those palettes out. Use purple only when the user names it.
4. **Apply the palette colors as they are.** Put the four hex values into the tokens unchanged. Do not shift their hue, lightness or chroma to make them pastel or to match a recipe. Map them by role:

| Palette color | Token | Use |
|---------------|-------|-----|
| Lightest color (OKLCH L 0.9 or higher, chroma 0.05 or less, otherwise it becomes `surface` and `bg` is derived) | `bg` | Page background (the 60%) |
| Next lightest | `surface`, `tint` | Panels, sidebars, table header, selected rows (the 30%) |
| Most saturated color | `primary` | Primary button fill, active nav marker, links when contrast allows (the 10%) |
| Remaining color | `accent` | Secondary highlights, charts, state markers |
| Darkest color (L 0.35 or lower) | `ink` | Body text and headings |

5. **Fill only the roles the palette leaves empty.** When no palette color is light enough for `bg`, use white or a near-white with the hue of the lightest palette color at chroma 0.01 or less. When no color is dark enough for `ink`, use the hue of the darkest palette color at L 0.22 to 0.26. Derive `line` (borders, focus rings) and text on fills the same way. Every derived color takes its hue from a palette color and is listed as derived when you state the palette.
6. **Contrast decides where a color may go, not whether it is used.** If a palette color fails 4.5:1 as text, keep it as a fill or surface and put `ink` or near-white text on it. If button text fails on the `primary` fill, pick the text color that passes (near-white or `ink`), never a lighter tint of the fill.
7. **Semantic colors** for success, warning, danger and info come from the palette when it has a fitting hue (green for success, red or coral for danger). Otherwise derive them: success around H 150, warning around H 80, danger around H 25, info around H 240, at the same lightness as `primary`.
8. **If the palette cannot work,** for example four near-identical light tints with no usable fill, run the picker again. Say that you rerolled and why.

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

## Eye Comfort

People stare at a SaaS product for hours. These rules come from reading research and vision science, and `palette-check` measures most of them.

1. **Dark text on a light background by default.** Proofreading accuracy and reading speed are higher with dark on light (positive polarity), because the brighter screen narrows the pupil and sharpens the image. The advantage grows as text gets smaller and holds for older adults. Dark mode is a preference to offer, not the default and not an accessibility fix.
2. **Keep text contrast high. Do not soften it for comfort.** Higher text contrast improves legibility. Body text aims for 7:1 and APCA Lc 90, never under 4.5:1 and Lc 75. Text on surfaces and panels never under 4.5:1 and Lc 60. A near black from the palette hue is fine as `ink`. Light gray body text is not.
3. **Glare comes from large bright saturated areas, not from contrast.** The page background stays near white with chroma 0.05 or less, surfaces stay at chroma 0.1 or less, and colors above chroma 0.15 cover only the 10% (buttons, markers, selected states). Nothing above chroma 0.25 and no neon (chroma above 0.2 at lightness above 0.75) anywhere.
4. **Never let saturated red and blue touch.** The eye focuses red and blue at different depths, so red on blue or blue on red appears to vibrate (chromostereopsis). Keep a neutral between them and never use one as text on the other. Avoid saturated pure blue text on dark backgrounds, which the eye struggles to focus.
5. **Dark mode is built, not inverted.** Background a dark gray of the palette hue at L 0.18 to 0.22, never `#000000`. Text off white at L 0.88 to 0.93, never `#ffffff` on near black, because bright text on black blooms and smears for people with astigmatism (about 4 in 10 adults). Lower the chroma of `primary` and `accent` by about a third so they do not vibrate. Keep body text between Lc 75 and 90 rather than the maximum.
6. **Plan for color blindness.** About 1 in 12 men and 1 in 200 women have a color vision deficiency, mostly red green. `palette-check` simulates protanopia, deuteranopia and tritanopia and warns when two palette colors become indistinguishable. Those two colors may never be the only difference between two states or two chart series.
7. **No eye care tints.** There is no evidence that screen blue light damages eyes, and blue filter tints do not reduce strain. Strain comes from long sessions and small, dense text. Help by keeping body text at 16px or larger with line height 1.5 and lines of 60 to 80 characters, and never forcing users to zoom.
8. **Respect the user's settings.** Follow `prefers-color-scheme`, increase contrast under `prefers-contrast: more`, and keep the UI usable under `forced-colors: active`.

## Dark Mode

Keep the palette's hues. Use the darkest palette color as the background when its L is between 0.15 and 0.3, otherwise derive a background from its hue at L 0.18 to 0.22. Surfaces are a step lighter in the same hue. Text is the lightest palette color when its L is 0.93 or lower, otherwise an off white of its hue at L 0.88 to 0.93. Lower the chroma of `primary` and `accent` by about a third and lighten them only when they fail contrast. Recheck every pair with `palette-check` using the dark tokens.

## Checks

- Run `palette-check` on the final tokens, light and dark, and resolve every FAIL and WARN.
- Measure contrast for: body text on `bg` and `surface`, text on every fill, links, placeholder text, disabled text (it may fail, but must still be distinguishable), input borders, focus rings, and chart series against the background.
- Squint test: the one primary action per screen should be the first thing you notice.
- Grayscale test: view a screenshot in grayscale. States should still be distinguishable by text, shape or position.
- No saturated default fills (C13), no rainbow of sibling cards (C12), no purple gradient (C01).
- No stock pastel rainbow (C17), harsh multi hue gradient (C14), purple on black (C15) or neon accent (C16). Each palette color keeps one role, not one color per card.
- No purple anywhere unless the user asked for it.

## Sources

- [Positive display polarity is advantageous for both younger and older adults, Piepenbrock et al., Ergonomics 2013](https://www.researchgate.net/publication/236662424_Positive_display_polarity_is_advantageous_for_both_younger_and_older_adults)
- [Smaller pupil size and better proofreading performance with positive polarity displays, Piepenbrock et al.](https://www.researchgate.net/publication/264903980_Smaller_pupil_size_and_better_proofreading_performance_with_positive_than_with_negative_polarity_displays)
- [APCA easy intro and contrast levels, Myndex](https://git.apcacontrast.com/documentation/APCAeasyIntro.html)
- [Why APCA, Myndex](https://git.apcacontrast.com/documentation/WhyAPCA.html)
- [Chromostereopsis, Interaction Design Foundation](https://ixdf.org/literature/topics/chromostereopsis)
- [Effect of Chromostereoscopic Stimulus on Accommodative Response, BIOJ](https://bioj-online.com/articles/10.22599/bioj.515)
- [Ambient Illumination and Text Color on Visual Fatigue under Negative Polarity, Sensors 2024](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC11175232/)
- [When dark mode becomes hard to read: a halation problem](https://a11ywithdiana.substack.com/p/when-dark-mode-becomes-hard-to-read)
- [Should You Be Worried About Blue Light, American Academy of Ophthalmology](https://www.aao.org/eye-health/tips-prevention/should-you-be-worried-about-blue-light)
- [Color Blindness, National Eye Institute](https://www.nei.nih.gov/learn-about-eye-health/eye-conditions-and-diseases/color-blindness)
- [A Physiologically based Model for Simulation of Color Vision Deficiency, Machado et al. 2009](https://www.inf.ufrgs.br/~oliveira/pubs_files/CVD_Simulation/CVD_Simulation.html)

- [Using Color to Enhance Your Design, NN/g](https://www.nngroup.com/articles/color-enhance-design/)
- [OKLCH in CSS: why we moved from RGB and HSL, Evil Martians](https://evilmartians.com/chronicles/oklch-in-css-why-quit-rgb-hsl)
- [OKLCH in CSS: consistent, accessible color palettes, LogRocket](https://blog.logrocket.com/oklch-css-consistent-accessible-color-palettes)
- [The 60-30-10 rule, LogRocket](https://blog.logrocket.com/ux-design/60-30-10-rule/)
- [Contrast and Color Accessibility, WebAIM](https://webaim.org/articles/contrast/)
- [Color contrast, MDN](https://developer.mozilla.org/en-US/docs/Web/Accessibility/Guides/Understanding_WCAG/Perceivable/Color_contrast)
