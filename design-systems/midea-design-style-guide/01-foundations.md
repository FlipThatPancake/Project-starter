# 01 — Foundations · Midea Report Design System

> Part of the **Midea research-report design language**. For use on Midea
> projects. **Midea Blue** (`--accent`, `#0098D1`) is the sole brand accent.

The atoms of the system. Every value here is a token in `tokens.css`. Component
rules reference tokens by name; they never contain literal colours. Values shown
are the **light theme**; dark-theme values are in `tokens.css` under
`[data-theme="dark"]`.

---

## 1. Colour

### Canvas & surfaces
| Token | Light | Role |
|---|---|---|
| `--bg` | `#F9F9FA` | Page background. A warm near-white, not pure `#fff`. |
| `--card` | `#FFFFFF` | Raised card/panel surface. |
| `--surface-2` | `#F3F4F6` | Insets: toggle tracks, tab bars, chips, avatars, hover fills. |
| `--card-blue` | `#E0F3FA` | Rare accent-washed panel. |

### Ink & text ramp
| Token | Light | Role |
|---|---|---|
| `--ink` | `#000000` | Active chrome only — solid pill buttons/tabs. |
| `--text` | `#1C1C1C` | Primary text: body, headings, values. |
| `--text2` | `rgba(0,0,0,.60)` | Secondary: sublabels, captions, counts. |
| `--text3` | `rgba(0,0,0,.58)` | Tertiary: eyebrow labels, axis numbers. |

> The ramp is **near-black + two greys**, not four distinct greys. `--text2` and
> `--text3` are almost the same on purpose — the hierarchy comes from size and
> weight as much as colour.

### Accent (the only chromatic colour)
| Token | Light | Role |
|---|---|---|
| `--accent` | `#0098D1` | Midea Blue. Bar fills, active states, CTAs, links, the eyebrow dot. |
| `--accent-d` | `#0077A3` | Darker — hover/pressed accent. |
| `--accent-lt` | `#E0F3FA` | Accent wash — active-row background, subtle hover tint. |

**Discipline rule:** accent appears on interactive/active elements and data
fills. It is never a background for large areas and never decorative.

### Secondary tint — amber (caveats ONLY)
| Token | Light | Role |
|---|---|---|
| `--amber` | `#C07B12` | Warning/caveat text + badge foreground. |
| `--amber-lt` | `#FCF3E3` | Caveat badge/notes background. |

### Lines & tracks
| Token | Light | Role |
|---|---|---|
| `--border` | `rgba(0,0,0,.10)` | Hairline card & section borders (used at `0.5px`). |
| `--border-2` | `rgba(0,0,0,.18)` | Stronger outline for outlined (border-only) panels. |
| `--bar-bg` | `rgba(0,0,0,.06)` | Empty bar-track background. |

### Categorical segment ramp (monochromatic)
For stacked-segment / demographic bars — a single hue stepping lighter, **not** a
rainbow:
| Token | Light | Dark |
|---|---|---|
| `--seg-1` | `#0098D1` | `#5BA8FF` |
| `--seg-2` | `#4CB5DC` | `#7DBBFF` |
| `--seg-3` | `#8AD0E8` | `#9FCDFF` |
| `--seg-4` | `#BEEAF8` | `#C2DEFF` |

> This monochromatic ramp is a signature move: categories read as *one family*,
> keeping the palette calm. If you need >4 categories, extend the ramp lighter
> rather than introducing a new hue.

### Overlays & on-colour
`--overlay` … `--overlay-btn` are graduated black scrims for modals/lightboxes.
`--on-accent` / `--on-overlay` are `#FFFFFF` — text that sits on accent or scrim.
`--thumb-bg` (`#E5E9EF`) backs image placeholders and modal image panels.

---

## 2. Typography

Two families, loaded from Google Fonts (see `README`/`tokens.css` header).

| Family | Use | Notes |
|---|---|---|
| **DM Serif Display** | Headlines only (`h1` line 1, card `h3`, big titles). | Weight 400 only — it's a display serif, never bold. Fallback `Georgia, serif`. |
| **Hanken Grotesk** | Everything else — body, labels, data, buttons. | Weights 300–700 loaded. Fallback `system-ui, sans-serif`. |

**Global body settings** (in `tokens.css`):
```css
font-family: 'Hanken Grotesk', system-ui, sans-serif;
font-variant-numeric: tabular-nums;   /* aligned digits — important for stats */
font-optical-sizing: auto;
font-size: 16px;
line-height: 1.65;
```

### Type scale (as used in the report)
| Element | Family | Size | Weight | Colour | Extra |
|---|---|---|---|---|---|
| Report title line 1 | serif | `clamp(38px, 7.2vw, 66px)` | 400 | `--text` | `letter-spacing:-.01em`, `text-wrap:balance` |
| Report title line 2 | sans | `clamp(16px, 2.6vw, 23px)` | 700 | `--accent` | sits under line 1 |
| Card headline `h3` | serif | `clamp(32px, 4vw, 44px)` | 400 | `--text` | `line-height:1.15` |
| Eyebrow / q-label | sans | `14px` | 600 | `--accent` | `uppercase`, `letter-spacing:.5px` |
| Section label | sans | `14px` | 600 | `--text3` | `uppercase`, `letter-spacing:.5px` |
| Card subtitle (`q-sub`) | sans | `19px` | 400 | `--text2` | `line-height:1.55` |
| Body paragraph | sans | `16px` | 400 | `--text` / `--text2` | `line-height:1.65` |
| Bar label | sans | `14px` | 400 | `--text` | |
| Stat value | sans | `26px` | 700 | `--text` | tabular-nums |
| Data emphasis (%) | sans | `13–14px` | 700 | `--accent` or white-on-fill | |
| Caption / axis | sans | `13–14px` | 400–600 | `--text3` | |

**Patterns worth copying:**
- Headlines use `text-wrap: balance`; long body paragraphs use `text-wrap: pretty`.
- Eyebrow labels are always **uppercase, `letter-spacing:.5px`, 14px, 600**, and
  either accent (a "question label") or `--text3` (a "section label").
- The serif is *only* ever weight 400. Never bold the serif.

---

## 3. Spacing & layout rhythm

- **Container:** `.page-wrap { max-width: 1100px; margin: 0 auto; padding: 32px 20px 80px; }`
- **Reading column** for prose: cap at ~`680px` (`.subtext { max-width:680px }`).
- **Section spacing:** section labels carry the big gap — `margin: 64px 0 20px`.
- **Card internals:** head `padding: 24px 0 20px`; body `padding: 24px 0`.
  (Note the **horizontal padding is 0** — cards from the 4th child on drop their
  chrome and align to the page column; see `04-page-structure.md`.)
- **Card gap:** `margin-bottom: 18px` between cards.
- **Bar list gap:** `14px` between bar rows; `6px` between a bar's label and track.

Spacing is not a rigid 8pt grid — it's a rhythm: tight inside components
(`4–10px`), generous between sections (`64px`).

---

## 4. Shape — border radius

| Token | Value | Applied to |
|---|---|---|
| `--radius-sm` | `8px` | Tight insets, image thumbs, small hover targets. |
| `--radius-md` | `12px` | Chips, small cards (country chips). |
| `--radius` | `16px` | Default card / expand panel. |
| `--radius-lg` | `20px` | Large cards, outlined stat/country panels. |
| `--radius-xl` | `24px` | Modals. |
| `--radius-pill` | `999px` | **Bar tracks, toggle buttons, tabs, badges.** |

Rule of thumb: **anything that holds data or is a control is a pill; anything
that holds content is 16–24px rounded.**

---

## 5. Elevation — shadows

Shadows are **soft, diffuse, and blue-tinted** (light theme) — they read as
depth, not as a hard drop. Never use a neutral grey box-shadow.

| Token | Light value |
|---|---|
| `--shadow` | `0 1px 2px rgba(0,152,209,.04), 0 4px 12px rgba(0,152,209,.06)` |
| `--shadow-lg` | `0 4px 16px rgba(0,152,209,.08), 0 8px 24px rgba(0,152,209,.06)` |
| `--shadow-pop` | `0 8px 32px rgba(0,152,209,.12), 0 2px 8px rgba(0,152,209,.06)` |

- Resting cards: `--shadow`. Hover lift: `--shadow-lg`. Modals/popovers: `--shadow-pop`.
- Dark theme swaps to standard black shadows (tint disappears — see tokens).
- **Overflow gotcha:** cards use `overflow: hidden`, which clips *outward*
  hover outlines. For a hover ring on a child near a card edge, use an **inset**
  box-shadow (`box-shadow: inset 0 0 0 2px var(--accent)`) instead of `outline`.

---

## 6. Motion — easing tokens

Three curves, all **exponential ease-out** (fast start → long soft settle). This
single decision is most of why the report feels "expensive". No bounce, no
overshoot, no `ease-in-out`, no `linear` (except the loader spinner).

| Token | Curve | Use |
|---|---|---|
| `--ease-out-quart` | `cubic-bezier(0.25, 1, 0.5, 1)` | Default UI transitions (hover, colour, background). |
| `--ease-out-quint` | `cubic-bezier(0.22, 1, 0.36, 1)` | Transforms — scale/lift, chevron rotate. |
| `--ease-out-expo` | `cubic-bezier(0.16, 1, 0.3, 1)` | Reveals & entrances — bar growth, fade-ups. |

Typical durations: hover/colour `0.15s`; transform/lift `0.25–0.35s`; reveals
`0.40–0.60s`; modal in `0.30s`. See `03-motion.md` for the full reveal ladder.
