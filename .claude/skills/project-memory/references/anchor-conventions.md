# Anchor conventions

## Syntax by context
| context | anchor comment | end-marker (only for >200-line spans) |
|---|---|---|
| HTML | `<!-- @sec:name -->` | `<!-- @end:name -->` |
| CSS | `/* @css:name */` | — |
| JS | `// @js:name` | — |

## Naming rules
- lowercase kebab-case, ≤3 words: `concept-modal`, `render-preference`, `reveal-stagger`.
- Unique per route per prefix. The SAME name across prefixes is deliberate pairing (HTML/CSS/JS layers of one feature).
- NEVER rename an anchor (maps and habits reference it) — add a new one instead.
- Place the anchor on its own line immediately BEFORE the thing it marks.

## Grep recipes
| goal | command |
|---|---|
| find one feature, all layers | `grep -n "@(sec\|css\|js):concept-modal" <file>` |
| list every anchor in a file | `grep -n "@sec:\|@css:\|@js:" <file>` |
| verify uniqueness | `grep -o "@[a-z]*:[a-z0-9-]*" <file> \| sort \| uniq -d` (empty = good) |

## Single-file vs folder routes
- Single-file route: all three prefixes coexist in the one file.
- Folder route: same names; the map's anchor column adds the file, e.g. `@js:pref-sort (js/pref.js)`.

## Build markers (related, used by scripts/build.mjs — not navigation anchors)
| marker | effect at build |
|---|---|
| `<!-- @asset:assets/foo.png -->` | next src="…" placeholder becomes base64 data-URI |
| `<!-- @inline:../shared/tokens.css -->` | replaced by file contents in `<style>`/`<script>` wrapper |
