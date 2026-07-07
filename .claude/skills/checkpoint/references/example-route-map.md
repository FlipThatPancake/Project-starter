# EXAMPLE — canonical routes/<route>.md shape. Match this exactly.

```markdown
# /survey-jun26 — jun26/index.html (single self-contained file; CSS top, HTML mid, JS bottom; anchors don't drift, line numbers do)
uses: design-m3 (shared/design-m3.md) | data: none (inline JS objects)

## Sections
| section | anchor(s) | gotcha |
|---|---|---|
| page loader | @css:loader · @js:loader | LOADER defined in early small script ON PURPOSE (paints before big data script parses) |
| preference list | @sec:preference · @js:render-preference | stagger selector must match JS-emitted wrapper class or bars stick at 0% |
| concept modal | @sec:concept-modal · @css:concept-modal · @js:concept-modal | zoom = takeover layer; state resets on open/close |

## Hot elements (most-edited)
- toggle buttons: @css:toggle-btn (roll disabled for .active)
- bar stagger rules: @css:reveal-stagger

## Priorities / planned
1. P1: mobile layout for concept-modal zoom

## Recent decisions (cap 10, newest first)
- 2026-07-03 concept-modal zoom = in-modal takeover, not width-expand (text side would be unusable)
- 2026-07-02 loader split into two script blocks so ring paints early
```

Notes on the shape (do not copy into real files):
- Header line carries the file-shape hint, not exact line numbers.
- `anchor(s)` column: `·`-separated prefixes of the SAME feature; add `(file.js)` suffix for folder routes.
- gotcha column: one line max; longer lessons become a decision or global gotcha.
- Decisions are dated, newest first, capped at 10 — evicted oldest-first; promote to gotcha if still load-bearing.
