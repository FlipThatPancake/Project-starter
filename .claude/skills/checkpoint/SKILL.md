---
name: checkpoint
description: Use when the user says /checkpoint, "save progress", or "update memory". Rewrites .claude/memory/INDEX.md and the touched routes/<route>.md maps to reflect this session's changes, validates them, and stages them for commit.
group: core
---

# Checkpoint — memory rewrite protocol

## Before writing (mandatory, in order)
1. Read `references/map-format.md`, `references/example-index.md`, `references/example-route-map.md`. Match their shape EXACTLY — same columns, same terseness.
2. List which routes/sections this session actually changed (git diff + your own edits). You will touch ONLY those parts of memory. Untouched routes stay byte-identical.
3. Grep every anchor you are about to keep or add. Dead anchor: section still exists in code → re-insert the anchor comment in code (cheap, keeps map stable); section gone → delete the map row.

## Update rules
| change | op |
|---|---|
| section added/moved/removed | rewrite that route's Sections table row(s) |
| new route | add one INDEX row (+ route map file only if it passes the threshold in map-format.md) |
| new gotcha (non-obvious root cause found this session) | append to route or global gotchas |
| decision that constrains future work | prepend to Recent decisions |
| completed/planned work changed | rewrite Priorities block |
| over cap (INDEX 60 / route 100 / shared 80 / SESSION-LOG 40 lines) | evict oldest DECISIONS first; if a decision is still load-bearing, promote to gotcha first. NEVER evict gotchas. SESSION-LOG evicts its oldest row(s) |
| session ending / mode locked this session | ensure one row exists in `SESSION-LOG.md` for this session (date, branch, mode, one-line scope) — append if missing, never rewrite past rows |

## Hard prohibitions (especially when running on a small/cheap model)
- Never delete or reword a gotcha you didn't verify this session.
- Never convert tables to prose. Never add prose paragraphs.
- Never rewrite sections whose subject you didn't touch.
- Never "summarize" or compress existing rows.

## After writing
1. Run `node scripts/validate.mjs --memory` — it mechanically checks caps, table shape, and that every anchor resolves in code. Fix failures before proceeding; do not commit failing memory.
2. Stage memory files (plus any anchor comments re-inserted in code).
3. Commit message: `chore(memory): checkpoint <routes touched>`.

## When to RECOMMEND running /checkpoint (criteria for the model; the Stop-hook nudge covers volume automatically)
| signal | recommend? |
|---|---|
| non-obvious root cause found (gotcha-class) | yes, say so in your final message |
| decision made that future sessions must know | yes |
| new section/route/anchor added | yes (hook usually catches this too) |
| cosmetic tweaks, copy edits, single obvious fix | no |
