# Session rules — token discipline

| Rule | Do |
|---|---|
| Mode first | FIRST action every session: restate the session's purpose in one line. Explicit, unambiguous prompt → state understanding + inferred mode and proceed; otherwise WAIT for confirmation — never assume. Lock the mode, read the mode file |
| Address, don't act | You may acknowledge the substance of the user's request as soon as understood (e.g. "that already exists — here's its state"). Do NOT execute changes toward it until BOTH the mode is locked AND the skill gate (below) is resolved |
| Skill gate | Every mode, after purpose is confirmed: print the FULL skill catalog as a markdown list — top picks seeded from `.claude/skills-store/MODE-SHORTLISTS.md`'s row for this mode, then broadened to anything else matching the task; below: everything else by category. WAIT for the user's free-text confirm/redaction before installing or loading anything — skip only if the user already named skills or said "none" |
| Mode is explicit | Never rename a branch you were handed (breaks harness tracking); only self-created branches get a `<mode-slug>/` prefix. Always: append a row to `.claude/memory/SESSION-LOG.md`, and prefix every commit message `[mode:<n>-<slug>]` |
| Memory first | Read `.claude/memory/INDEX.md` + your route's map before ANY code read/grep (project-memory skill) |
| Scope lock | Multi-route (≥2 routes): lock onto ONE route per session; re-scope only when told ("switch to /x") |
| Meta read scope | `.claude/**`, `scripts/**`, `tests/**`, `CLAUDE.md`, `README.md` are Mode 1's domain to read freely (incl. `SKILL-MANAGER-HANDOFF.md`/`WIKI.md`). Every other mode reads from there ONLY what a running skill-manager verb needs (e.g. `CATALOG.md`/`MODE-SHORTLISTS.md` for the gate) — never to browse. Documented discipline, not hook-enforced |
| Skills | Lean loadout: active = pinned + ride-along only; skill payload sits in `.claude/skills-store/skill-storage/` (zero context), metadata `.md`s at the store root. Installing into the store is fine in any mode; loading into active (`.claude/skills/**`) or editing mechanics needs mode 1. Never hand-move skill dirs |
| Anchor navigation | Grep `@sec:` / `@css:` / `@js:` anchors from the map, then Read with offset/limit — never whole-file Reads |
| Built-file hazard | dist/*.html are self-contained with inlined base64 — unscoped Read/grep pays the image tax; work in src/ |
| Never read dist/ | Generated output; sources only |
| Scripts, not boilerplate | `node scripts/validate.mjs --all` · `node scripts/build.mjs <route>` · `scripts/ship.sh "msg"` — never inline `node -e` validators |
| Batch commits | One `ship.sh` per work chunk, not per edit; push to main unless told otherwise |
| Checkpoint | Run /checkpoint when nudged by the Stop hook, or after finding a non-obvious root cause / making a future-constraining decision |
| Session hygiene | Batch related fixes into one prompt's work; suggest a fresh session when a new work chunk starts |
| Model hint | Mechanical edits/renames → cheap model is fine; debugging/design/checkpoint precision → larger model |
