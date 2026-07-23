# 02 — Components · Midea Report Design System

> Part of the **Midea research-report design language**. For use on Midea
> projects. Components reference Midea tokens only — never hardcode a colour.

Copy-paste recipes. Every rule references tokens from `tokens.css`. The same CSS
is available concatenated in `components.css` — link that after `tokens.css` and
you only need the **markup** blocks below.

Component index:
[Cards](#cards) · [Section & question headers](#section--question-headers) ·
[Stat tiles](#stat-tiles) · [Segment bars](#segment-bars-stacked-monochrome) ·
[Horizontal bar chart](#horizontal-bar-chart) · [Mini bars](#mini-bars-compact-panels) ·
[Vertical scale chart](#vertical-scale-chart) · [Toggle buttons](#toggle-buttons) ·
[Tabs](#tabs-pill-tab-bar) · [Badges](#badges) · [Chips](#chips) ·
[Quote-card collage](#quote-card-collage) · [Response cards](#response-cards) ·
[Modals](#modals)

---

## Cards

The base container. Hairline border, soft shadow, rounded, `overflow:hidden`.

```html
<div class="card">
  <div class="card-head">
    <div>
      <div class="q-label">Sample composition</div>
      <h3>Who took part in the study</h3>
      <div class="q-sub">195 participants across 6 European markets.</div>
    </div>
    <!-- optional right-aligned control (toggle-row, etc.) -->
  </div>
  <div class="card-body"><!-- content --></div>
</div>
```

```css
.card {
  background: var(--card);
  border: 0.5px solid var(--border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow);
  margin-bottom: 18px;
  overflow: hidden;             /* clips outward outlines — see foundations §5 */
}
.card-head {
  padding: 24px 0 20px;
  border-bottom: 0.5px solid var(--border);
  display: flex; align-items: flex-start; justify-content: space-between; gap: 12px;
}
.card-head .q-label {           /* the accent "eyebrow" over a headline */
  font-size: 14px; font-weight: 600; color: var(--accent);
  text-transform: uppercase; letter-spacing: .5px; margin-bottom: 8px;
}
.card-head h3 {
  font-family: 'DM Serif Display', Georgia, serif;
  font-size: clamp(32px, 4vw, 44px); font-weight: 400;
  line-height: 1.15; letter-spacing: 0.01em; text-wrap: balance;
}
.card-head .q-sub {
  font-size: 19px; color: var(--text2); margin-top: 8px;
  line-height: 1.55; text-wrap: pretty;
}
.card-body { padding: 24px 0; }
```

> **Signature convention:** in the report, cards past the third one on the page
> shed their chrome and align to the page column (see `04-page-structure.md`):
> ```css
> .page-wrap > .card:nth-child(n+4) { background: var(--bg); border: none; box-shadow: none; }
> ```
> The first few "hero" cards feel raised; later analytical sections read as open
> page content. Adopt or drop this per project — but it's part of the look.

---

## Section & question headers

Two eyebrow styles. **Question label** (`q-label`) is accent, lives inside a
card head. **Section label** is grey, stands alone between sections with a rule.

```html
<div class="section-label">Detailed findings</div>
```
```css
.section-label {
  font-size: 14px; font-weight: 600; letter-spacing: .5px;
  text-transform: uppercase; color: var(--text3);
  margin: 64px 0 20px;                    /* the big vertical rhythm */
  display: flex; align-items: center; gap: 10px;
}
.section-label::after {                    /* trailing hairline rule */
  content:''; flex:1; height:0.5px; background: var(--border);
}
```

---

## Stat tiles

Outlined (border-only, no fill/shadow) tiles for headline numbers. Border turns
accent on hover.

```html
<div class="ps-stats">
  <div class="ps-stat">
    <div class="ps-val">195</div>
    <div class="ps-key">Participants</div>
    <div class="ps-sub">6 markets</div>
  </div>
  <!-- … -->
</div>
```
```css
.ps-stats { display: grid; grid-template-columns: repeat(5, 1fr); gap: 12px; margin-bottom: 22px; }
.ps-stat {
  background: transparent; border: 1px solid var(--text);
  border-radius: var(--radius-lg); padding: 20px; text-align: center;
  box-shadow: none;
  transition: border-color 0.25s var(--ease-out-quart);
}
.ps-stat:hover { border-color: var(--accent); }
.ps-stat .ps-val { font-size: 26px; font-weight: 700; color: var(--text); line-height: 1.1; }
.ps-stat .ps-key { font-size: 14px; font-weight: 400; color: var(--text2); margin-top: 6px; }
.ps-stat .ps-sub { font-size: 14px; color: var(--text3); margin-top: 2px; }
@media (max-width: 760px) { .ps-stats { grid-template-columns: repeat(2, 1fr); } }
```

---

## Segment bars (stacked, monochrome)

A single pill split into monochromatic accent segments — for demographic /
composition breakdowns. Uses the `--seg-1..4` ramp.

```html
<div class="ps-dist">
  <div class="ps-dist-label">Age</div>
  <div class="ps-seg-bar">
    <div class="ps-seg ps-seg-c1" style="width:32%"></div>
    <div class="ps-seg ps-seg-c2" style="width:28%"></div>
    <div class="ps-seg ps-seg-c3" style="width:24%"></div>
    <div class="ps-seg ps-seg-c4" style="width:16%"></div>
  </div>
  <div class="ps-legend">
    <span class="ps-legend-item"><span class="ps-legend-dot" style="background:var(--seg-1)"></span>18–29 <span class="ps-lv">32%</span></span>
    <!-- … -->
  </div>
</div>
```
```css
.ps-seg-bar {
  display: flex; height: 20px; border-radius: var(--radius-pill);
  overflow: hidden; background: var(--bar-bg);
}
.ps-seg { height: 100%; }
.ps-seg-c1 { background: var(--seg-1); } .ps-seg-c2 { background: var(--seg-2); }
.ps-seg-c3 { background: var(--seg-3); } .ps-seg-c4 { background: var(--seg-4); }
.ps-legend { display: flex; flex-wrap: wrap; gap: 6px 14px; margin-top: 8px; }
.ps-legend-item { display: flex; align-items: center; gap: 5px; font-size: 14px; color: var(--text); }
.ps-legend-dot { width: 9px; height: 9px; border-radius: 2px; flex: 0 0 auto; }
.ps-legend-item .ps-lv { color: var(--text2); }
```
Reveal: the whole bar scales in — `.ps-seg-bar { transform: scaleX(0); … }` +
`animation: bar-grow-x 0.60s var(--ease-out-expo) 0.45s both;` (see `03-motion`).

---

## Horizontal bar chart

The workhorse. Pill track, accent fill, percentage label that lives **inside**
the fill (white) and flips **outside** (grey) when the bar is too short.

```html
<div class="bar-list">
  <div class="bar-item">
    <div class="bar-label">Design 2</div>
    <div class="bar-row">
      <div class="bar-track">
        <div class="bar-fill" style="width:64%" data-pct="64%"></div>
      </div>
      <div class="bar-count">124</div>
    </div>
  </div>
  <!-- add class "pct-outside" to .bar-fill when the bar is too narrow -->
</div>
```
```css
.bar-list { display: flex; flex-direction: column; gap: 14px; }
.bar-item { display: flex; flex-direction: column; gap: 6px; }
.bar-item .bar-label { font-size: 14px; color: var(--text); }
.bar-row { display: flex; align-items: center; gap: 10px; }
.bar-track {
  height: 18px; width: 100%; background: var(--bar-bg);
  border-radius: var(--radius-pill); overflow: hidden;
}
.bar-fill {
  height: 100%; background: var(--accent);
  border-radius: var(--radius-pill);
  position: relative; overflow: visible;
}
.bar-fill::after {                       /* % label inside the fill, white */
  content: attr(data-pct);
  position: absolute; right: 8px; top: 50%; transform: translateY(-50%);
  font-size: 13px; font-weight: 700; letter-spacing: 0.01em;
  color: rgba(255,255,255,0.92); white-space: nowrap;
}
.bar-fill.pct-outside::after {           /* flipped outside when too short */
  right: auto; left: calc(100% + 6px); color: var(--text2);
}
.bar-row .bar-count { font-size: 14px; color: var(--text3); width: 28px; text-align: right; }
```
Reveal ladder (staggered from the left) is in `03-motion.md`. Fills must start at
`transform: scaleX(0); transform-origin: left center;`.

### "Other" row variant (outlined, no fill)
An interactive row that matches the bar list but carries a text preview + chevron
instead of a percentage. Border/radius live on the **track**, not the fill.
```css
.other-track {
  height: 30px; background: transparent;
  border: 1px solid var(--text); border-radius: var(--radius-pill);
  overflow: hidden; transition: background 0.15s var(--ease-out-quart);
}
.other-row-trigger { cursor: pointer; user-select: none; }
.other-row-trigger:hover .other-track { background: var(--bar-bg); }
.other-chevron { transition: transform 0.25s var(--ease-out-quint); }
.other-chevron.open { transform: rotate(180deg); }
```

---

## Mini bars (compact panels)

Tiny fixed-width bars for per-country / per-segment breakdown grids (3×2).

```html
<div class="country-panel">
  <div class="country-panel-head">
    <img class="pflag" src="…"><span class="pname">Germany</span><span class="pn">n=40</span>
  </div>
  <div class="mini-bar-list">
    <div class="mini-bar-item">
      <span class="mini-bar-label">Design 2</span>
      <div class="mini-bar-right">
        <div class="mini-bar-track"><div class="mini-bar-fill" style="width:70%"></div></div>
        <span class="mini-bar-pct">70%</span>
      </div>
    </div>
  </div>
</div>
```
```css
.country-panel {                          /* outlined, no fill/shadow */
  border: 1px solid var(--border-2); border-radius: var(--radius-lg);
  padding: 20px; background: transparent; box-shadow: none;
}
.country-panel-head {
  display: flex; align-items: center; gap: 8px;
  margin-bottom: 14px; padding-bottom: 10px; border-bottom: 1px solid var(--border);
}
.mini-bar-list { display: flex; flex-direction: column; gap: 9px; }
.mini-bar-item { display: grid; grid-template-columns: 1fr auto; gap: 8px; align-items: center; }
.mini-bar-right { display: flex; align-items: center; gap: 8px; }
.mini-bar-track { width: 80px; height: 7px; background: var(--bar-bg); border-radius: var(--radius-pill); overflow: hidden; }
.mini-bar-fill { height: 100%; background: var(--accent); border-radius: var(--radius-pill); }
.mini-bar-pct { font-size: 14px; font-weight: 700; color: var(--accent); width: 36px; text-align: right; }
```
Panels are on a `display:grid; grid-template-columns: repeat(3, minmax(0,1fr)); gap:18px` wrapper.

---

## Vertical scale chart

Column bars (e.g. a 1–5 Likert scale) growing **up** from the baseline.

```html
<div class="scale-bars">
  <div class="scale-col">
    <div class="scale-pct">8%</div>
    <div class="scale-bar-outer"><div class="scale-bar-inner">
      <div class="scale-bar-fill" style="height:16%"></div>
    </div></div>
  </div>
  <!-- 5 columns -->
</div>
<div class="scale-labels"><div class="scale-num">1</div>…</div>
```
```css
.scale-bars { display: grid; grid-template-columns: repeat(5, 1fr); gap: 6px; align-items: flex-end; height: 120px; }
.scale-col { display: flex; flex-direction: column; align-items: center; justify-content: flex-end; gap: 4px; height: 100%; }
.scale-bar-outer { width: 100%; display: flex; align-items: flex-end; flex: 1; }
.scale-bar-inner { width: 100%; height: 100%; background: var(--bar-bg); border-radius: 6px 6px 0 0; overflow: hidden; display: flex; align-items: flex-end; min-height: 4px; }
.scale-bar-fill { width: 100%; background: var(--accent); border-radius: 6px 6px 0 0; }
.scale-pct { font-size: 14px; font-weight: 600; color: var(--accent); }
.scale-num { text-align: center; font-size: 15px; font-weight: 600; color: var(--text3); padding: 6px 0; border-top: 2px solid var(--border); }
```
Vertical fills start at `transform: scaleY(0); transform-origin: bottom center;`.

---

## Toggle buttons

A pill segmented control. Inactive = ghost; active = outlined (border, no fill).
Optional direction-aware label "roll" on hover.

```html
<div class="toggle-row">
  <button class="toggle-btn active">English</button>
  <button class="toggle-btn">Original</button>
</div>
```
```css
.toggle-row { display: flex; align-items: center; gap: 6px; background: var(--surface-2); border-radius: var(--radius-pill); padding: 4px; }
.toggle-btn {
  border: 1.5px solid transparent; background: transparent;
  border-radius: var(--radius-pill); padding: 6px 14px;
  font-size: 13px; font-weight: 500; color: var(--text2); cursor: pointer;
  font-family: inherit;
  transition: background 0.15s var(--ease-out-quart), color 0.15s var(--ease-out-quart), border-color 0.15s var(--ease-out-quart);
}
.toggle-btn:hover { border-color: var(--text3); color: var(--text); }
.toggle-btn.active { border: 1.5px solid var(--text); color: var(--text); font-weight: 600; }
```

---

## Tabs (pill tab-bar)

For filtering (e.g. by country). Active tab is **solid ink** with white text.

```html
<div class="oe-country-tabs">
  <button class="oe-country-tab active">All</button>
  <button class="oe-country-tab">Germany</button>
</div>
```
```css
.oe-country-tabs { display: flex; gap: 4px; flex-wrap: wrap; background: var(--surface-2); border-radius: var(--radius-pill); padding: 4px; width: fit-content; }
.oe-country-tab {
  border: none; background: transparent; border-radius: var(--radius-pill);
  padding: 5px 12px; font-size: 14px; font-weight: 500; color: var(--text2);
  cursor: pointer; font-family: inherit;
  transition: background 0.15s var(--ease-out-quart), color 0.15s var(--ease-out-quart);
}
.oe-country-tab:hover { background: var(--card); color: var(--text); }
.oe-country-tab.active { background: var(--ink); color: var(--on-accent); font-weight: 600; box-shadow: 0 1px 4px rgba(0,0,0,.12); }
```

> Two active-state idioms coexist by design: **outlined** (toggle-btn, calm,
> for view switches) vs **solid ink** (tab, assertive, for content filters).

---

## Badges

Small pill labels. Region/neutral badge uses `--surface-2`; warning badge uses
amber. 13px, subtle.

```html
<span class="region-badge">DE +5</span>
<span class="warn-badge">0 votes in Portugal</span>
```
```css
.region-badge {
  display: inline-block; font-size: 13px; font-weight: 500; letter-spacing: .1px;
  background: var(--surface-2); color: var(--text2);
  border-radius: var(--radius-pill); padding: 2px 10px; white-space: nowrap;
}
.warn-badge {
  display: inline-block; font-size: 13px; font-weight: 500; letter-spacing: .1px;
  background: var(--amber-lt); color: var(--amber);
  border-radius: var(--radius-pill); padding: 2px 10px; white-space: nowrap;
}
```

---

## Chips

Small bordered info cards (e.g. a country grid). `--radius-md`, hairline, hover
raises the shadow.

```css
.country-chip {
  background: var(--card); border: 0.5px solid var(--border);
  border-radius: var(--radius-md); padding: 8px 10px; text-align: center;
  box-shadow: var(--shadow); transition: box-shadow 0.20s var(--ease-out-quart);
}
.country-chip:hover { box-shadow: var(--shadow-lg); }
```

---

## Quote-card collage

A signature hero element: 3–4 scattered, individually-rotated quote cards that
**straighten and lift on hover**, plus one accent-coloured card. Collapses to a
plain grid on mobile.

```html
<div class="voice-collage">
  <div class="voice-card card-1" style="--i:0">
    <div class="voice-head">
      <div class="voice-avatar">DE</div>
      <div>
        <div class="voice-name">Female, 60 · Germany</div>
        <div class="voice-context">Chose Design 2</div>
      </div>
    </div>
    <p class="voice-body">"The grill symbol is confusing…"</p>
    <span class="voice-tag">#grill-icon</span>
  </div>
  <!-- card-2, card-3, then one card-4 with class "accent" -->
</div>
```
```css
.voice-collage { position: relative; height: 460px; max-width: 620px; margin: 24px auto 20px; }
.voice-card {
  position: absolute; background: var(--card);
  border: 1px solid rgba(0,0,0,.16); border-radius: var(--radius);
  padding: 18px 20px;
  box-shadow: 0 2px 6px rgba(0,0,0,.06), 0 8px 20px rgba(0,0,0,.05);
  overflow: hidden;
  transition: transform 0.35s var(--ease-out-quint), box-shadow 0.25s var(--ease-out-quart), border-color 0.25s var(--ease-out-quart);
}
/* resting positions + base rotation — tune coords to taste */
.card-1 { top: 0;       left: 8px;   width: 264px; transform: rotate(-3deg); z-index: 2; }
.card-2 { top: 36px;    right: 12px; width: 244px; transform: rotate(4deg);  z-index: 3; }
.card-3 { bottom: 0;    left: 40px;  width: 280px; transform: rotate(-2deg); z-index: 1; }
.card-4 { bottom: 72px; right: 8px;  width: 208px; transform: rotate(5deg);  z-index: 2; }
.voice-card:hover {
  transform: translateY(-6px) rotate(0deg) !important;   /* lift + straighten */
  box-shadow: 0 4px 10px rgba(0,0,0,.08), 0 16px 32px rgba(0,0,0,.10);
  border-color: rgba(0,0,0,.28); z-index: 10;
}
.voice-card.accent { background: var(--accent); border-color: transparent; color: #fff; }
.voice-card.accent .voice-name,
.voice-card.accent .voice-body { color: #fff; }
.voice-card.accent .voice-context { color: rgba(255,255,255,.75); }
.voice-avatar { width: 30px; height: 30px; border-radius: 50%; background: var(--surface-2); color: var(--text2); display: flex; align-items: center; justify-content: center; font-size: 13px; font-weight: 700; flex-shrink: 0; }
.voice-head { display: flex; gap: 10px; align-items: center; margin-bottom: 10px; }
.voice-name { font-size: 13px; font-weight: 600; color: var(--text); line-height: 1.2; }
.voice-context { font-size: 14px; color: var(--text3); margin-top: 2px; }
.voice-body { font-size: 14.5px; line-height: 1.65; color: var(--text); text-wrap: pretty; }
.voice-tag { display: inline-block; background: var(--surface-2); color: var(--text2); font-size: 13px; font-weight: 500; padding: 3px 10px; border-radius: var(--radius-pill); margin-top: 10px; }
/* mobile: collapse the pile into a static grid */
@media (max-width: 680px) {
  .voice-collage { position: static; height: auto; display: grid; grid-template-columns: 1fr 1fr; gap: 10px; max-width: 100%; }
  .voice-card { position: static; transform: none !important; width: auto !important; top:auto; left:auto; right:auto; bottom:auto; box-shadow: var(--shadow); }
}
@media (max-width: 460px) { .voice-collage { grid-template-columns: 1fr; } }
```
Cards also stagger-fade in on load via `--i` (see `03-motion.md`).

---

## Response cards

Plain quote/answer rows — hairline card, small shadow, comfortable line-height.

```css
.oe-response {
  font-size: 15px; color: var(--text); line-height: 1.7; padding: 12px 14px;
  background: var(--card); border: 0.5px solid var(--border);
  border-radius: var(--radius-sm); box-shadow: var(--shadow);
}
```

---

## Modals

Scrim + blur, centred, entrance-animated. Base overlay reused for lightboxes and
content modals.

```html
<div class="modal-overlay open">
  <div class="modal-inner">
    <img src="…">
    <div class="modal-caption"><span>Caption</span></div>
  </div>
</div>
```
```css
.modal-overlay {
  display: none; position: fixed; inset: 0; z-index: 1000;
  background: var(--overlay); backdrop-filter: blur(6px);
  align-items: center; justify-content: center;
}
.modal-overlay.open { display: flex; }
.modal-inner {
  position: relative; max-width: 90vw; max-height: 90vh;
  border-radius: var(--radius-xl); overflow: hidden; box-shadow: var(--shadow-pop);
}
.modal-inner img { display: block; max-width: 88vw; max-height: 80vh; object-fit: contain; }
.modal-caption {
  position: absolute; bottom: 0; left: 0; right: 0;
  background: var(--overlay-soft); color: var(--on-overlay);
  font-size: 14px; font-weight: 500; padding: 10px 16px;
  display: flex; align-items: center; justify-content: space-between;
}
/* entrance (see 03-motion) */
.modal-overlay.open { animation: fade-in 0.20s var(--ease-out-quart) both; }
.modal-overlay.open .modal-inner { animation: modal-in 0.30s var(--ease-out-expo) 0.04s both; }
```

For a **content modal** (image panel + text panel side by side), set
`.modal-inner { display:flex; max-width:min(96vw,1160px) }` with a fixed-width
image side (`420px`) and a flexible scrolling text side. Full recipe lives in the
source; the essentials are the flex split + `--thumb-bg` image panel + pill
"winner"/badge chips using `--ink` / `--overlay-chip`.
