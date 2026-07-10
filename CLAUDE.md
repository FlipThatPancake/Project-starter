# Session rules — token discipline

| Rule | Do |
|---|---|
| Mode first | FIRST action every session: restate the session's purpose in one line. Explicit, unambiguous prompt → state understanding + inferred mode and proceed; otherwise WAIT for confirmation — never assume. Lock the mode, read the mode file |
| Address, don't act | You may acknowledge the substance of the user's request as soon as understood (e.g. "that already exists — here's its state"). Do NOT execute changes toward it until the mode is locked (skills are opt-in — no gate to resolve first) |
| Skills opt-in | No mandatory gate. The session-start hook injects the skill index for free. Load a dormant skill only when the task needs it, the user names it, or you consult `MODE-SHORTLISTS.md` for a suggestion — `/skills load <name>` (thin; reading skill-curator's SKILL.md is only for install/update/extract/delete) |
| User decisions win | An explicit user decision (grilled requirement, named color, stated constraint) outranks every skill heuristic, seed, and checklist line. When a skill's default conflicts with what the user said, surface the conflict and let them choose — never silently override |
| Mode is explicit | Never rename a branch you were handed (breaks harness tracking); only self-created branches get a `<mode-slug>/` prefix. Always: append a row to `.claude/memory/SESSION-LOG.md`, and prefix every commit message `[mode:<n>-<slug>]` |
| Memory first | Read `.claude/memory/INDEX.md` + your route's map before ANY code read/grep (project-memory skill) |
| Scope lock | Multi-route (≥2 routes): lock onto ONE route per session; re-scope only when told ("switch to /x") |
| Lazy reading | Read only what the current step needs. At session start read ONLY the mode file + `.claude/memory/INDEX.md`. Do not read `skills-store/*`, skill-curator's SKILL.md, or narrative docs unless actually acting on skills. Reading the meta surface to *understand/change* it is Mode 1's job; other modes read the minimum a task needs |
| Skills | Metadata lives in each skill's SKILL.md frontmatter (`name`/`description`, optional `group`, optional `exclusive-with`). No `policy` field — "always-on" is defined solely by the `.gitignore` whitelist; no generated index file — the session-start hook enumerates directly. Loading COPIES store→active and is available in ANY mode; the active copy is gitignored so it never leaks to other branches. Editing the mechanics needs mode 1. Never hand-move skill dirs — use `/skills` or `scripts/skillctl.sh` |
| Anchor navigation | Grep `@sec:` / `@css:` / `@js:` anchors from the map, then Read with offset/limit — never whole-file Reads |
| Built-file hazard | dist/*.html are self-contained with inlined base64 — unscoped Read/grep pays the image tax; work in src/. Same for vendored minified libraries in src/ (e.g. a bundled gsap.min.js) — never whole-file Read them |
| Never read dist/ | Generated output; sources only |
| Scripts, not boilerplate | `node scripts/validate.mjs --all` · `node scripts/build.mjs <route>` · `scripts/ship.sh "msg"` — never inline `node -e` validators |
| Batch commits | One `ship.sh` per work chunk, not per edit; push to main unless told otherwise |
| Checkpoint | Run /checkpoint when nudged by the Stop hook, or after finding a non-obvious root cause / making a future-constraining decision |
| Session hygiene | Batch related fixes into one prompt's work; suggest a fresh session when a new work chunk starts |
| Model hint | Mechanical edits/renames → cheap model is fine; debugging/design/checkpoint precision → larger model |
