# 03 — Motion · Midea Report Design System

> Part of the **Midea research-report design language**. For use on Midea
> projects.

Motion is a first-class part of the Midea report look. It's understated but consistent: the
page *assembles* itself on load — text fades up, bars grow from their origin,
cards fade in — all with the same **exponential ease-out** family. Nothing
bounces. Interactions (hover/press) are quick; entrances are longer and settle
slowly.

**All reveal animations are pure CSS running on page load** — no
IntersectionObserver, no scroll trigger, no JS class toggling. Elements start in
their "hidden" transform and animate to rest with a delay. This keeps the system
portable: drop the markup in, and it animates itself.

---

## The three easing curves (recap)

| Token | Curve | Used for |
|---|---|---|
| `--ease-out-quart` | `cubic-bezier(0.25, 1, 0.5, 1)` | Hover, colour, background, generic UI. |
| `--ease-out-quint` | `cubic-bezier(0.22, 1, 0.36, 1)` | Scale/lift transforms, chevron rotation. |
| `--ease-out-expo` | `cubic-bezier(0.16, 1, 0.3, 1)` | **Reveals/entrances** — bars, fade-ups, modals. |

---

## Core keyframes

```css
@keyframes fade-up   { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: none; } }
@keyframes fade-in   { from { opacity: 0; } to { opacity: 1; } }
@keyframes modal-in  { from { opacity: 0; transform: scale(0.97) translateY(6px); } to { opacity: 1; transform: none; } }
@keyframes bar-grow-x { to { transform: scaleX(1); } }
@keyframes bar-grow-y { to { transform: scaleY(1); } }
```

The two `bar-grow-*` keyframes only define the **end** state; the start state
(`scaleX(0)` / `scaleY(0)`) lives on the element itself, so the fill is hidden
until its animation runs.

---

## Bars: start hidden, grow to full

Every fill type is pinned at zero-scale from its natural origin. **Horizontal**
bars grow from the **left**; **vertical** bars grow from the **bottom**.

```css
/* horizontal — grow from left */
.bar-fill, .mini-bar-fill, .oe-trend-fill, .cmt-fill, .ps-seg-bar {
  transform: scaleX(0); transform-origin: left center;
}
/* vertical — grow from bottom */
.scale-bar-fill, .scale-mini-fill {
  transform: scaleY(0); transform-origin: bottom center;
}
```

Using `transform: scale` (not animating `width`/`height`) means the growth is
GPU-composited and buttery. The percentage label sits in `::after` on the fill,
so it rides along as the bar grows.

---

## The stagger ladder

Rows animate in sequence, each starting ~**70ms** after the previous, so a list
"unrolls". The pattern: base delay + per-row step, capped with an `nth-child(n+k)`
catch-all so arbitrarily long lists don't drift forever.

**Main horizontal bars** — duration `0.55s`, base `0.30s`, step `0.07s`:
```css
.bar-item:nth-child(1) .bar-fill { animation: bar-grow-x 0.55s var(--ease-out-expo) 0.30s forwards; }
.bar-item:nth-child(2) .bar-fill { animation: bar-grow-x 0.55s var(--ease-out-expo) 0.37s forwards; }
.bar-item:nth-child(3) .bar-fill { animation: bar-grow-x 0.55s var(--ease-out-expo) 0.44s forwards; }
.bar-item:nth-child(4) .bar-fill { animation: bar-grow-x 0.55s var(--ease-out-expo) 0.51s forwards; }
.bar-item:nth-child(5) .bar-fill { animation: bar-grow-x 0.55s var(--ease-out-expo) 0.58s forwards; }
/* … continue to 10 … */
.bar-item:nth-child(n+11) .bar-fill { animation: bar-grow-x 0.55s var(--ease-out-expo) 1.00s forwards; }
```

**Mini bars** — faster `0.45s`, base `0.10s`, step `0.07s`, cap at 6+.
**Vertical scale bars** — `0.55s`, base `0.30s`, step `0.06s`, cap at 7+.
**Trend / theme bars** — `0.40s`, base `0.10s`, step `0.07s`, cap at 5+.

> Tune two numbers to change the whole feel: the **base delay** (when the group
> starts, after the header has faded in) and the **step** (row-to-row spacing).
> Keep the step in the 60–70ms range — tighter feels frantic, wider feels slow.

### ⚠️ The #1 gotcha — stagger selector must match the wrapper class

The stagger targets a specific wrapper (`.bar-item`, `.mini-bar-item`,
`.scale-col`, …). If a list reuses the same `.bar-track`/`.bar-fill` markup under
a **different** wrapper class, the animation never fires and **the bars sit stuck
at `scaleX(0)` — invisible.** In the source this bit four times. Two fixes:

1. Add the new wrapper to the selector list:
   ```css
   .bar-item:nth-child(1) .bar-fill,
   .design-item:nth-child(1) .bar-fill { animation: bar-grow-x 0.55s var(--ease-out-expo) 0.30s forwards; }
   ```
2. Or match the fill by its own position instead of requiring a specific
   ancestor (used for `.oe-trend-item`, which appears in two containers):
   ```css
   .oe-trend-item:nth-child(1) .oe-trend-fill { animation: …; }
   ```

**Rule:** whenever you add a chart whose fill starts at `scale(0)`, make sure a
stagger rule actually targets it. No matching rule = permanently hidden bar.

---

## Header & card entrances

The header fades up in three beats; stat tiles and collage cards stagger via an
inline `--i` index.

```css
/* header — three staggered fade-ups */
.report-header h1        { animation: fade-up 0.55s var(--ease-out-expo) 0.35s both; }
.report-header .subtitle { animation: fade-up 0.50s var(--ease-out-expo) 0.48s both; }
.report-header .subtext  { animation: fade-up 0.50s var(--ease-out-expo) 0.58s both; }

/* stat tiles — indexed stagger via inline style="--i:N" */
.ps-stats .ps-stat { animation: fade-up 0.40s var(--ease-out-quart) calc(0.20s + var(--i,0) * 0.06s) both; }

/* quote-card collage — indexed stagger */
.voice-collage .voice-card { animation: fade-in 0.50s var(--ease-out-quart) calc(0.60s + var(--i,0) * 0.10s) both; }
```

The **`--i` technique** is the cleanest way to stagger an arbitrary count without
writing `nth-child` rules: set `style="--i:0"`, `--i:1`, … in markup and compute
the delay with `calc()`.

`both` (vs `forwards`): `both` also applies the *from* state before the delay, so
the element is hidden during its wait. Use `both` for fade-ups; `forwards` is
fine for bars because their hidden state is already set on the element.

---

## Interaction motion

Quick, `--ease-out-quart`, short durations:

| Interaction | Property / duration |
|---|---|
| Card / chip hover | `box-shadow` `0.20s` (raise `--shadow`→`--shadow-lg`) |
| Stat tile hover | `border-color` `0.25s` → accent |
| Thumb hover | `transform: scale(1.04)` `0.25s` `--ease-out-quint` + shadow |
| Chevron toggle | `transform: rotate(180deg)` `0.25s` `--ease-out-quint` |
| Row hover | `background` `0.20s` → `--surface-2` |
| Toggle/tab | `background`/`color`/`border-color` `0.15s` |
| Modal in | overlay `fade-in 0.20s`; inner `modal-in 0.30s` `--ease-out-expo` |

---

## Optional: reduced-motion

The source omits it. For accessibility parity in a new build, add:
```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { animation-duration: .001ms !important; animation-delay: 0s !important; transition-duration: .001ms !important; }
  .bar-fill, .mini-bar-fill, .oe-trend-fill, .cmt-fill, .ps-seg-bar { transform: none !important; }
  .scale-bar-fill, .scale-mini-fill { transform: none !important; }
}
```
This snaps bars to full size and removes the assembly animation for users who ask
for less motion — recommended for any new report.
