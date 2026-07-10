# Slop Detection Rules

## CSS Property Detection

### Gradient Tells
```css
background: linear-gradient(*indigo*purple*)
background: linear-gradient(*purple*blue*)
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%)
-webkit-background-clip: text
-webkit-text-fill-color: transparent
```

### Glassmorphism Tells
```css
backdrop-filter: blur(*)
background: rgba(255, 255, 255, 0.1)
border: 1px solid rgba(255, 255, 255, 0.2)
```

### Shadow Tells
```css
box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1)     /* generic AI shadow */
box-shadow: 0 0 *px rgba(*, *, *, 0.[3-9])     /* colored glow */
box-shadow: 0 25px 50px -12px rgba(0, 0, 0, *)  /* oversized shadow */
```

### Border Tells
```css
border-left: 3px solid *
border-left: 4px solid *
border: 1px solid rgb(228, 228, 231)            /* zinc-200 */
border: 1px solid rgb(229, 231, 235)            /* gray-200 */
```

### Radius Tells
```css
border-radius: 1rem     /* rounded-2xl default */
border-radius: 0.75rem  /* rounded-xl default */
```

## Tailwind Class Detection

### P0 Regex Patterns
```
/bg-(indigo|violet|purple)-(500|600)/
/from-(purple|indigo|violet)-\d+ to-(blue|pink|purple)-\d+/
/bg-clip-text.*text-transparent.*bg-gradient/
/backdrop-blur/
/rounded-(2xl|3xl).*shadow-lg.*p-6/
/blur-(2xl|3xl).*opacity-\d+.*absolute/
```

### P1 Regex Patterns
```
/border-l-[3-4].*border-(purple|indigo|violet|blue|emerald)/
/bg-(zinc|slate)-(50|100|200|800|900|950)/
/shadow-\[0_0_\d+px_rgba/
/text-cyan-400.*bg-(slate|gray|zinc)-(900|950)/
/rounded-full.*px-[2-3].*py-[0-1].*text-(xs|sm)/
```

### P2 Regex Patterns
```
/bg-(emerald|green)-(500|600)/
/bg-(amber|stone)-50/
/tracking-tight.*text-(4xl|5xl|6xl)/
```

## HTML Structure Detection

### Hero Section Pattern
```
<section>
  <span class="*pill*badge*rounded-full*">*badge text*</span>
  <h1 class="*text-(4xl|5xl|6xl)*">*headline*</h1>
  <p class="*text-(lg|xl)*text-(gray|zinc|muted)*">*subheadline*</p>
  <div>*buttons*</div>
</section>
```

### Feature Card Pattern
```
<div class="*grid*cols-3*">
  <div class="*card*rounded*shadow*p-6*">
    <div class="*rounded-lg*bg-*-50*p-2*">*icon*</div>
    <h3>*heading*</h3>
    <p>*description*</p>
  </div>
  <!-- repeated 2 more times -->
</div>
```

### Stat Card Pattern
```
<div class="*grid*cols-(3|4)*">
  <div>
    <span class="*text-(3xl|4xl)*font-bold*">*big number*</span>
    <span class="*text-(sm|xs)*text-(gray|muted)*">*label*</span>
  </div>
  <!-- repeated 2-3 more times -->
</div>
```

### Canned Page Skeleton
```
1. Hero with badge + headline + CTA buttons
2. Logo cloud / "Trusted by" strip
3. Three feature cards in a grid
4. Stats/metrics banner
5. Testimonials grid
6. Pricing table (3 tiers)
7. FAQ accordion
8. CTA section
9. Footer with multi-column links
```

## Content Detection

### Buzzword List
```
streamline, empower, supercharge, world-class, enterprise-grade,
cutting-edge, best-in-class, revolutionary, game-changing, seamless,
effortless, powerful, robust, scalable, intuitive, comprehensive,
next-generation, state-of-the-art, industry-leading, mission-critical,
future-proof, end-to-end, holistic, paradigm, synergy, leverage,
optimize, harness, accelerate, amplify, elevate, unlock, transform,
reimagine, disrupt
```

### Vague Headline Patterns
```
"Build the future of *"
"Your all-in-one * platform"
"Scale * without limits"
"Elevate your *"
"The * you've been waiting for"
"* made simple"
"* for modern teams"
"The modern way to *"
"Rethink how you *"
"* at scale"
```

### Social Proof Red Flags
```
"Trusted by *,000+ *"
"Join *,000+ *"
"Used by teams at *"
"Loved by * worldwide"
```

Check against: domain age, actual user base, logo authenticity.

## Font Detection

### AI Default Fonts
```
Inter
Geist
Geist Mono
Space Grotesk
Instrument Serif
Satoshi
Clash Display
Plus Jakarta Sans
DM Sans
```

### AI Font Combos
```
Inter + Instrument Serif
Space Grotesk + Instrument Serif
Geist + Geist Mono
Satoshi + Clash Display
DM Sans + DM Serif Display
Plus Jakarta Sans + Playfair Display
```

## Scoring Integration

When scanning a page, count matches per category:

1. Fetch page HTML and computed styles
2. Match against CSS property rules
3. Match against Tailwind class patterns
4. Analyze HTML structure against known skeletons
5. Scan copy against buzzword and headline lists
6. Check fonts against AI default list
7. Calculate slop score using weights from slop-patterns.md
