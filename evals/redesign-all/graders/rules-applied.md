---
type: llm
---

The original app breaks many uiux rules: a purple palette on near black with Inter, emoji icons in icon tiles and in the navigation, a sparkle eyebrow, glass, pill badges for roles and a filler "New" badge, initials avatars, a native select, date input and checkbox, `alert()` and `confirm()`, a table with no column filters and no sticky header, a fixed size modal, an em dash and a semicolon in copy, hover lift and a bouncing `transition: all`, an italic accent word in a heading, a `<br>` inside a heading, "Name:" and "Email:" labels, mono uppercase labels, and numbers without tabular figures.

PASS if the run picks a new palette with the palette picker and checks it, builds shared components first (tokens, field, button, dialog, table or select), then redesigns every one of the four screens and the navigation, and the final files fix at least fifteen of the problems above.
FAIL if a screen is left untouched, if the purple palette or Inter stays, or if fewer than fifteen problems are fixed.
