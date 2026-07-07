# Session rules — token discipline

| Rule | Do |
|---|---|
| Mode first | FIRST action every session: pick a session mode (`.claude/modes/README.md`). Infer ONLY on an explicit, unambiguous prompt; otherwise ASK — never assume. Lock it, offer the skill store, read the mode file |
| Mode is explicit | Never rename a branch you were handed (breaks harness tracking); only self-created branches get a `<mode-slug>/` prefix. Always: append a row to `.claude/memory/SESSION-LOG.md`, and prefix every commit message `[mode:<n>-<slug>]` |
| Memory first | Read `.claude/memory/INDEX.md` + your route's map before ANY code read/grep (project-memory skill) |
| Scope lock | Multi-route (≥2 routes): lock onto ONE route per session; re-scope only when told ("switch to /x") |
| Skills | Lean loadout: active = pinned + ride-along only; library sits in `.claude/skills-store/` (zero context). Need a capability, or installing/removing a skill → skill-manager skill. Never hand-move skill dirs |
| Anchor navigation | Grep `@sec:` / `@css:` / `@js:` anchors from the map, then Read with offset/limit — never whole-file Reads |
| Built-file hazard | dist/*.html are self-contained with inlined base64 — unscoped Read/grep pays the image tax; work in src/ |
| Never read dist/ | Generated output; sources only |
| Scripts, not boilerplate | `node scripts/validate.mjs --all` · `node scripts/build.mjs <route>` · `scripts/ship.sh "msg"` — never inline `node -e` validators |
| Batch commits | One `ship.sh` per work chunk, not per edit; push to main unless told otherwise |
| Checkpoint | Run /checkpoint when nudged by the Stop hook, or after finding a non-obvious root cause / making a future-constraining decision |
| Session hygiene | Batch related fixes into one prompt's work; suggest a fresh session when a new work chunk starts |
| Model hint | Mechanical edits/renames → cheap model is fine; debugging/design/checkpoint precision → larger model |
