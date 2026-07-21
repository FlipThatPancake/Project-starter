# 04 — Page structure & anatomy · Midea Report Design System

> Part of the **Midea research-report design language**. For use on Midea
> projects.

How a Midea report is assembled top to bottom, the container system, the responsive
rules, and the two structural conventions that define the reading experience.

---

## Document shell

```html
<!DOCTYPE html>
<html lang="en"><!-- data-theme="dark" to flip -->
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Report title</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link rel="stylesheet"
    href="https://fonts.googleapis.com/css2?family=DM+Serif+Display&family=Hanken+Grotesk:wght@300..700&display=swap">
  <link rel="stylesheet" href="tokens.css">
  <link rel="stylesheet" href="components.css">
</head>
<body>
  <div id="page-loader"><!-- optional; see below --></div>
  <div class="page-wrap">
    <div class="report-header">…</div>
    <!-- hero element(s) -->
    <!-- section-label + card, repeated -->
  </div>
</body>
</html>
```

---

## The container

```css
.page-wrap { max-width: 1100px; margin: 0 auto; padding: 32px 20px 80px; }
```

A single centred column, max **1100px**. Everything lives inside it. Prose
paragraphs cap tighter (~680px) for readability; charts and grids use the full
width.

---

## Vertical anatomy (top → bottom)

1. **Page loader** *(optional)* — a full-screen overlay with a thin progress ring
   that fades out once content is ready. Only worth it if the page ships heavy
   inline assets (the source embeds ~2MB of base64 images, so it shows an
   indeterminate spinner, then a determinate ring). For a light page, skip it.
2. **Header** — serif title (two lines), an accent "eyebrow" subtitle with a dot,
   and a short intro paragraph. Fades up in three beats.
3. **Hero element** — e.g. the scattered **quote-card collage**. Sets the tone
   before any data.
4. **Sections** — each is `section-label` (grey eyebrow + hairline rule) followed
   by a `card`. Sections are separated by the `64px` top margin on the label.
5. **Footer whitespace** — the container's `80px` bottom padding gives the report
   a calm ending; no heavy footer.

### Header recipe
```css
.report-header { padding: 40px 4px 12px; margin-bottom: 8px; }
.header-top { display: flex; align-items: flex-start; gap: 32px; justify-content: space-between; }
.report-header h1 { display: flex; flex-direction: column; font-weight: 400; line-height: 1.1; flex: 1; }
.report-header .h1-line1 { font-family: 'DM Serif Display', Georgia, serif; font-size: clamp(38px, 7.2vw, 66px); color: var(--text); letter-spacing: -.01em; text-wrap: balance; }
.report-header .h1-line2 { font-size: clamp(16px, 2.6vw, 23px); font-weight: 700; color: var(--accent); letter-spacing: .01em; margin-top: 6px; text-wrap: balance; }
.report-header .subtitle { color: var(--text2); font-size: 14px; font-weight: 600; letter-spacing: .4px; text-transform: uppercase; margin-top: 14px; display: inline-flex; align-items: center; gap: 6px; }
.report-header .subtitle::before { content:''; width: 6px; height: 6px; background: var(--accent); border-radius: 50%; display: inline-block; }
.report-header .subtext { color: var(--text2); font-size: 16px; margin-top: 10px; max-width: 680px; line-height: 1.65; text-wrap: pretty; }
```
A logo/mark (SVG, `currentColor`, ~53px) sits top-right in `.header-top`, opposite
the title.

---

## Structural convention #1 — cards "dissolve" after the hero

The first few cards are raised (white, bordered, shadowed) — they feel like
hero panels. From the **4th** card onward, cards shed their chrome and become
plain page sections aligned to the column:

```css
.page-wrap > .card:nth-child(n+4) {
  background: var(--bg);
  border: none;
  box-shadow: none;
}
```

Why it works: the top of the report feels composed and product-like; the
analytical depth below reads as open editorial content, not an endless stack of
boxes. **Card internals use `padding: … 0`** (zero horizontal) precisely so that
when the chrome disappears, content stays flush to the page column.

> Adopt this as-is, or choose your own cutoff — but keep the *idea*: don't box
> every section. Boxes are for emphasis; most content should breathe.

---

## Structural convention #2 — outlined vs filled surfaces

Two surface treatments, used deliberately:

| Treatment | Looks like | Used for |
|---|---|---|
| **Filled** — `--card` bg + `0.5px` border + `--shadow` | raised white panel | Hero cards, response cards, chips, popovers. |
| **Outlined** — transparent bg + `1px` border, no shadow | quiet framed region | Stat tiles, per-country breakdown panels. |

Outlined surfaces keep dense grids (stat rows, 3×2 breakdowns) light — six
shadowed boxes in a row would be noisy; six thin outlines stay calm.

---

## Responsive breakpoints

The system is largely fluid (`clamp()` type, `fr` grids). Explicit breakpoints
are few and purposeful:

| Breakpoint | Change |
|---|---|
| `≤ 760px` | Stat grid `5→2` cols; two-column distribution grids `→1`. |
| `≤ 680px` | Quote-card collage: absolute pile `→` static 2-up grid, rotations removed. |
| `≤ 460px` | Collage grid `2→1`. |

Rule: collapse multi-column grids to 1–2 columns; **kill decorative transforms**
(rotations, absolute positioning) on small screens; let type keep scaling via
`clamp()`.

---

## Building a *new* report with this system — checklist

1. Link fonts + `tokens.css` + `components.css`. Wrap everything in `.page-wrap`.
2. Write the header: serif title line 1, accent line 2, dotted eyebrow, one intro
   paragraph.
3. Add a hero (collage, a big stat row, or a lead chart).
4. For each finding: `section-label` → `card` (`q-label` eyebrow → serif `h3` →
   `q-sub`) → the right chart component from `02-components.md`.
5. Pick chart types by shape of data: ranking → **horizontal bars**; scale/Likert
   → **vertical scale chart**; breakdown by group → **mini-bar panels**;
   composition → **segment bar**; qualitative → **quote collage / response cards**.
6. Give every bar fill a matching **stagger rule** (see `03-motion.md` gotcha).
7. Verify dark mode (`data-theme="dark"`) — if anything looks wrong, you
   hardcoded a colour; replace it with a token.
8. Sanity pass against the "10 rules" in `README.md`: one accent, serif headlines,
   hairline borders, tinted shadows, pills for controls, staggered left-growing
   bars, exponential ease-out, tabular numerals, generous rhythm, amber only for
   caveats.
