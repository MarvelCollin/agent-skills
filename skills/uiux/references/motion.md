# Motion

Small, calm motion that explains what changed, on every interactive part of the product, without ever costing a frame. This is rule R18 in [build-rules.md](build-rules.md).

## What Motion Is For

Animate only when it answers one of these:

- **Where did it come from?** A menu grows from its trigger, a drawer slides from the edge it lives on
- **What changed?** A new row tints briefly, a saved field shows a check
- **Did it work?** A pressed button responds on the first frame, a toast arrives
- **Where did it go?** A deleted row fades out before the list closes the gap

If none applies, do not animate. Motion that only decorates (page load reveals, scroll triggered fades, floating shapes, counters that tick up) is slop (M01, M08).

## Tokens

Define these once and use only these. No hand typed durations or curves in components.

```css
:root {
  --dur-instant: 100ms;
  --dur-fast: 150ms;
  --dur-base: 200ms;
  --dur-slow: 250ms;
  --dur-page: 300ms;
  --ease-standard: cubic-bezier(0.2, 0, 0, 1);
  --ease-enter: cubic-bezier(0, 0, 0, 1);
  --ease-exit: cubic-bezier(0.3, 0, 1, 1);
}

@media (prefers-reduced-motion: reduce) {
  :root {
    --dur-instant: 0ms;
    --dur-fast: 0ms;
    --dur-base: 0ms;
    --dur-slow: 0ms;
    --dur-page: 0ms;
  }
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}
```

- Enter uses `--ease-enter` (fast start, soft stop). Exit uses `--ease-exit` and is one step shorter than the enter. Movement on screen uses `--ease-standard`
- In Tailwind, put the tokens in the theme (`transitionDuration`, `transitionTimingFunction`) and use `motion-safe:` or `motion-reduce:` variants. In Framer Motion or Motion, wrap the app in `MotionConfig reducedMotion="user"`
- Reduced motion keeps meaning: a fade or an instant state change still shows what happened. Remove movement and scale, not feedback

## Recipes per Component

| Component | Enter | Exit | Notes |
|-----------|-------|------|-------|
| Button, link | Background and color over `--dur-instant` | Same | Press: `transform: scale(0.98)` for `--dur-instant`. No lift, no shadow growth, no sliding arrow (R15) |
| Focus ring | Instant | Instant | Never animate focus. It must appear on the first frame |
| Checkbox, radio | Check mark draws or scales from 0.8 over `--dur-instant` | Same | |
| Switch | Thumb `translateX` over `--dur-fast` with `--ease-standard` | Same | Track color changes with it |
| Tooltip | Opacity over `--dur-instant` after a 300 to 500ms hover delay. On focus, no delay | Instant | Moving between neighbouring tooltips skips the delay |
| Dropdown, popover, select list, combobox | Opacity 0 to 1 plus `scale(0.98)` to 1 from the trigger side (`transform-origin`), `--dur-fast` | Opacity only, `--dur-instant` | Never slide a menu in from far away |
| Modal | Backdrop opacity `--dur-base`. Dialog opacity plus `translateY(8px)` to 0 or `scale(0.98)` to 1, `--dur-base` | `--dur-fast` | Focus moves into the dialog at the start, not after the animation |
| Drawer, side sheet | `translateX(100%)` to 0, `--dur-slow` | `--dur-base` | Bottom sheet uses `translateY`. Drag to dismiss follows the finger with no transition |
| Toast | `translateY(8px)` plus opacity, `--dur-base` | Opacity plus small `translateX`, `--dur-fast` | Stacked toasts shift with `transform`, never with `top` |
| Tabs | Active indicator moves with `transform: translateX() scaleX()`, `--dur-base` | | Panel content swaps instantly or with a `--dur-fast` fade. No sliding panels |
| Accordion, collapsible | Chevron rotates with `transform`. Panel grows with `grid-template-rows: 0fr` to `1fr`, `--dur-base` | `--dur-fast` | The single allowed layout animation. One panel at a time, never a long list |
| Row added to a list or table | Background tint that fades out after about 1s | | Signals "this is new". Siblings do not animate |
| Row removed | Opacity to 0 over `--dur-fast`, then remove | | If siblings must close the gap smoothly, use a FLIP `transform`, not height |
| Inline save | "Saving" text, then a check icon fading in over `--dur-fast` | Check fades after 2s | |
| Skeleton | A shimmer pseudo element moving with `transform: translateX`, 1.2 to 1.6s linear loop | Content replaces it with no fade or a `--dur-fast` fade | Never animate `background-position`, it repaints. Static under reduced motion |
| Spinner | Rotate with `transform`, linear, looping | | Appears only after about 400ms of waiting so fast actions do not flash |
| Progress bar | `transform: scaleX()` from the left | | Never animate `width` |
| Page or route change | Optional cross fade with the View Transitions API, `--dur-fast` to `--dur-base` | | Never wait for an animation before showing data. Move focus to the new heading after the swap |
| Drag and drop | Item follows the pointer with `transform`, no transition | Settles into place over `--dur-fast` | Drop targets highlight with color, not size |
| Charts | Bars or lines draw once on first load over `--dur-slow` at most | | No animation on every filter change. Values update in place |
| Numbers | Change instantly | | No counting up |

## Performance Rules

- **Animate only `transform` and `opacity`.** They run on the compositor and skip layout and paint. `width`, `height`, `top`, `left`, `margin`, `padding`, `border-width`, `font-size` force layout every frame. `box-shadow`, `filter`, `backdrop-filter`, `background-position` and `color` on large areas force paint
- **Name the property.** `transition: opacity var(--dur-fast) var(--ease-enter), transform var(--dur-fast) var(--ease-enter)`. Never `transition: all` or `transition-all`, which animates every future property change including layout ones
- **Shadows:** put the larger shadow on a pseudo element and change its `opacity`
- **`will-change` only on demand.** Add it just before an animation starts (on pointer down or menu open) and remove it after. Never in a global stylesheet, never on many elements. Each promoted layer costs GPU memory
- **No layout thrash.** In JavaScript, read all measurements first, then write styles, inside `requestAnimationFrame`. Never read `offsetHeight` or `getBoundingClientRect` inside a loop that also writes
- **Prefer CSS transitions and the Web Animations API** for simple motion. They run off the main thread. Use a motion library only when the project already has one, and avoid its layout animations (`layout`, `layoutId`) on lists, because they measure every element
- **Few things move at once.** At most one or two animations per interaction. Lists of 20 items do not each animate
- **Animations never wait on work.** Start the request and the animation together. Show the data the moment it arrives, even mid animation
- **Keep the main thread free during motion.** No long tasks over 50ms while something animates. Debounce input, defer heavy rendering (`startTransition`, `requestIdleCallback`) and virtualize long lists (R10)

## Checks

1. Run the rule scan. It flags `transition-all`, layout properties in transitions, durations over 500ms, overshooting curves and animated files with no reduced motion handling (R18 leads)
2. Trigger each animation, then immediately run this in the page (with agent-browser, `agent-browser eval --stdin`). It lists running animations that move layout or paint properties or run too long:

```js
(() => {
  const ok = ['transform', 'opacity', 'translate', 'scale', 'rotate']
  const skip = ['offset', 'easing', 'composite', 'computedOffset']
  const rows = document.getAnimations().map((a) => {
    const t = a.effect?.getTiming?.() || {}
    const props = [...new Set((a.effect?.getKeyframes?.() || []).flatMap((k) => Object.keys(k)).filter((k) => !skip.includes(k)))]
    if (a.transitionProperty) props.push(a.transitionProperty)
    const el = a.effect?.target
    const name = el ? `${el.tagName.toLowerCase()}${el.id ? '#' + el.id : ''}.${String(el.className).split(' ')[0]}` : 'unknown'
    return { name, props: [...new Set(props)], duration: t.duration, iterations: t.iterations }
  })
  const bad = rows.filter((r) => r.props.some((p) => !ok.includes(p)) || (r.iterations !== Infinity && Number(r.duration) > 400))
  return bad.length ? bad.map((r) => `${r.name}: ${r.props.join(', ')} for ${r.duration}ms`).join('\n') : `MOTION OK: ${rows.length} running animation(s) use transform or opacity`
})()
```

3. In Chrome DevTools, open Rendering and turn on Paint flashing and Layout Shift Regions, then open every menu, modal, drawer and toast. Only the moving element may flash
4. Record a Performance trace with 4x CPU throttling while opening the heaviest overlay and scrolling the longest list. Frames stay under 16ms, no long tasks during the animation, no purple layout blocks on animated frames
5. Emulate reduced motion (`agent-browser set media light reduced-motion`, or DevTools Rendering) and repeat. Nothing moves, every state change is still visible
6. Click quickly through a menu, a modal and a tab change. No animation ever delays the next click

## Sources

- [Executing UX Animations: Duration and Motion Characteristics, NN/g](https://www.nngroup.com/articles/animation-duration/)
- [How to create high performance CSS animations, web.dev](https://web.dev/articles/animations-guide)
- [Animations and performance, web.dev](https://web.dev/articles/animations-and-performance)
- [Easing and duration tokens, Material Design 3](https://m3.material.io/styles/motion/easing-and-duration/tokens-specs)
- [Same document view transitions, Chrome for Developers](https://developer.chrome.com/docs/web-platform/view-transitions/same-document)
- [Skeleton Screens 101, NN/g](https://www.nngroup.com/articles/skeleton-screens/)
- [WCAG 2.2 Animation from Interactions (2.3.3)](https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions.html)
