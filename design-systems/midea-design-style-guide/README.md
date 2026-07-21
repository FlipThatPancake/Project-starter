# Midea — Research Report Design Style Guide

**This is the official Midea design language for research/insight reports.** Use
it for any **Midea** project that presents study, survey, or analytics findings
as a web report. It is a portable specification for building reports that look
and feel like the **Midea 3.0 Eleva survey report** — hand this folder to any
Midea project (or any coding agent) and it has everything needed to reproduce
the Midea visual language from scratch: tokens, components, motion, and page
structure, without seeing the original file.

> **Brand scope:** These assets encode Midea's brand identity — **Midea Blue**
> (`#0098D1`) as the sole accent, the Midea report typography, elevation, and
> motion. They are intended for Midea reports and Midea-affiliated work. Keep
> Midea Blue as the accent unless a specific Midea sub-brand dictates otherwise.

> Design tools change; this describes an *aesthetic system*, not one HTML file.
> It's framework-agnostic: the tokens and rules translate cleanly to plain
> HTML/CSS, React, Vue, or any templating layer.

---

## What the Midea report style *is*, in one paragraph

A calm, editorial, single-column report on a near-white canvas. **One serif
display face** (DM Serif Display) for headlines against a **humanist sans**
(Hanken Grotesk) for everything else. Exactly **one chromatic accent** — **Midea
Blue** `#0098D1` — used with discipline: CTAs, active states, and bar fills only.
Everything else is a black-to-grey text ramp on white cards with **hairline
0.5px borders** and **soft, blue-tinted shadows**. Data is shown in **pill-shaped
horizontal bars** that grow from the left on load with a staggered,
exponential ease-out. Corners are generously rounded; motion is quick but never
bouncy. The result reads like a designed magazine feature, not a dashboard.

---

## The 10 rules that define the look

1. **One accent, used sparingly.** `--accent` (Midea Blue) is the only colour
   with chroma. If everything is blue, nothing reads as important. Text is the
   black→grey ramp; surfaces are white/grey.
2. **Serif display + sans body.** Headlines in `DM Serif Display` (weight 400,
   `clamp()`-scaled). Body, labels, data in `Hanken Grotesk`.
3. **Hairline borders, not heavy ones.** Cards use `0.5px solid var(--border)`.
   Outlined panels use `1px solid var(--border-2)` or `1px solid var(--text)`.
4. **Soft, tinted elevation.** Shadows are blue-tinted and diffuse
   (`--shadow` / `--shadow-lg` / `--shadow-pop`), never hard grey drop-shadows.
5. **Pills for tracks & controls.** Bar tracks, toggle buttons, tabs, and
   badges are all `--radius-pill` (999px).
6. **Bars grow from the left, staggered.** Every bar fill starts at
   `scaleX(0)` and animates to `scaleX(1)` on load, each row ~70ms after the
   last, using `--ease-out-expo`.
7. **Exponential ease-out for all motion.** Fast start, long gentle settle.
   No bounce, no overshoot, no `ease-in-out`. Three curves only (see below).
8. **Tabular numerals everywhere.** `font-variant-numeric: tabular-nums` on
   `body` so stats and percentages align in columns.
9. **Generous vertical rhythm.** Sections are separated by a lot of space
   (`margin: 64px 0 20px` on section labels) and a hairline rule.
10. **Amber is for caveats only.** The secondary tint (`--amber`) appears only
    on warning/caveat badges and notes — never decoratively.

---

## Files in this folder

| File | What it gives you |
|---|---|
| `tokens.css` | **Drop-in.** All CSS custom properties (light + dark) + base `body` rules. Copy verbatim; re-theme by editing only the token blocks. |
| `01-foundations.md` | Full token reference with values, meanings, and usage rules: colour, type scale, spacing, radii, shadows, easing. |
| `02-components.md` | Copy-paste recipes (markup + CSS) for every component: cards, section headers, horizontal/mini/vertical bars, toggles, tabs, badges, stat tiles, segment bars, quote-card collage, modals. |
| `03-motion.md` | The reveal/stagger animation system — keyframes, delay ladders, and the one rule that breaks it most often. |
| `04-page-structure.md` | Page anatomy: the loader, header, section rhythm, container widths, responsive breakpoints, and the "cards fade to plain after the 3rd" convention. |
| `components.css` | All component CSS from `02` concatenated into one importable file (after `tokens.css`). |
| `starter.html` | A minimal, working skeleton (header + one card + one bar chart) that links `tokens.css` + `components.css`. Open it to see the system live, then build on it. |

---

## Quick start

```html
<!DOCTYPE html>
<html lang="en"><!-- add data-theme="dark" for dark mode -->
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link rel="stylesheet"
    href="https://fonts.googleapis.com/css2?family=DM+Serif+Display&family=Hanken+Grotesk:wght@300..700&display=swap">
  <link rel="stylesheet" href="tokens.css">
  <link rel="stylesheet" href="components.css">
</head>
<body>
  <div class="page-wrap"><!-- max-width 1100px, centered --></div>
</body>
</html>
```

Read `01`→`04` in order the first time. After that, `02-components.md` is the
day-to-day reference.

---

## Midea brand assets

**Accent — Midea Blue.** `--accent: #0098D1` (light) / `#5BA8FF` (dark). This is
the only chromatic colour in the system and the core of the Midea report
identity. Do not introduce a second brand hue; extend the monochromatic
`--seg-*` ramp instead when you need more categories.

**Logo mark.** The Midea "M" mark is an inline SVG that inherits `currentColor`,
so it themes automatically (set the parent's `color`, or let it inherit
`--text`). It sits top-right in the report header at ~53px wide. Reuse verbatim:

```html
<svg class="header-logo" viewBox="0 0 103 91" fill="none"
     xmlns="http://www.w3.org/2000/svg" aria-label="Midea">
  <path d="M94.4 32.1H86.5C85.6 32.1 85.8 32.9 85.8 32.9C85.9 33.9 86.2 35.6 86.2 39.1C86.2 46.9 85.3 58 76.8 68.6L76.2 69.3C76.2 69.3 71.1 33.6 71 32.9C71 32.9 71 32.1 70.3 32.1H62.3C61.6 32.1 61.6 32.9 61.6 32.9C61.4 37 59.1 71.4 34.1 76.9C39.4 77.5 45.9 75.8 51.5 72.3C58.4 68 63.1 61.6 64.7 54.3C64.7 54.3 67.8 73.4 68.2 77.9V78.2L68 78.3C61 82.1 53 84 45 84C25.2 84 7.7 72.3 0 54.5C4.5 75.5 23.2 90.8 45.2 90.8C70.8 90.8 85.9 69.4 88.6 54.2C88.6 54.2 92 76.4 92.1 77.1H102.6C102.5 76.1 95.5 33.6 95.4 32.9C95.1 32.9 95.1 32.1 94.4 32.1ZM6 50.8C6 27.4 25.7 8.4 50 8.4C65 8.4 79 15.9 87.1 28.1C81.2 11.4 64.7 0 46.1 0C22.2 0 2.7 18.6 2.7 41.6C2.7 47.9 4.3 54 7.1 59.6C6.4 56.7 6 53.8 6 50.8Z" fill="currentColor"/>
</svg>
```
```css
.header-logo { width: 53px; height: auto; flex-shrink: 0; color: var(--text); margin-top: 6px; }
```

**Typography.** DM Serif Display (headlines) + Hanken Grotesk (everything else)
are the Midea report typefaces — see `01-foundations.md §2`.

## Dark mode

Every token has a dark counterpart. Set `data-theme="dark"` on `<html>`; nothing
else changes. Because components reference only tokens (never literal hex), they
flip automatically. If you add a component, **never hardcode a colour** — add or
reuse a token so dark mode keeps working.
