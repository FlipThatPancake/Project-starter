# Claude Code project starter — token-efficient blueprint

A clean-slate starter repo for token-efficient Claude Code sessions: persistent
memory (survives ephemeral web containers), anchor-based navigation, a lean
skill-management system, and zero-dependency build/validate/ship scripts.

Distilled from a production project where un-instrumented sessions cost
~400K tokens each; instrumented orientation costs ~3K.

## What's here

| path | purpose |
|---|---|
| `CLAUDE.md` | session token-discipline rules |
| `.claude/skills/project-memory/` | auto-skill: memory-first navigation protocol |
| `.claude/skills/checkpoint/` | `/checkpoint`: safe memory rewrites |
| `scripts/skillctl.sh` | thin skill loadout mechanics — list/load/unload/remove (`/skills`) |
| `.claude/skills-store/skill-storage/skill-curator/` | dormant skill: install/update/extract/delete a skill (heavy, infrequent ops) |
| `.claude/memory/` | `INDEX.md` registry + per-route maps + shared registries (committed = persistent) |
| `.claude/skills-store/` | dormant skill library, zero context cost until loaded (includes `anti-slop-preflight`, the pre-ship visual checklist) |
| `.claude/settings.json` | wires the three hooks: SessionStart → `session-start-hook.sh` (mode menu + skill index), PreToolUse → `scope-guard-hook.sh` (scope enforcement), Stop → `checkpoint-nudge.sh` (zero-token /checkpoint recommender) |
| `scripts/` | `validate.mjs` · `build.mjs` · `ship.sh` · `session-start-hook.sh` · `checkpoint-nudge.sh` · `scope-guard-hook.sh` |
| `tests/` | fixtures + `test-tooling.mjs` covering the scripts above |
| `src/routes/_skeleton/` | copy this when adding a new route |
| `src/shared/tokens.css` | shared design tokens routes opt into via `<!-- @inline:../../shared/tokens.css -->` |

## Starting a new project from this repo

This repo *is* the starter kit — for a new project, create a new GitHub repo
from this one (or clone it and re-point `origin`), then:

1. Start a session. The SessionStart hook reads `state: starter` in
   `.claude/memory/INDEX.md` and steers into **mode 2 (new-project)**, which
   asks the structure & stack, then flips the state to `in-progress`. (There is
   no portal/standalone flag — scope-locking kicks in automatically once INDEX
   lists ≥2 routes; a one-route project is trivially the whole scope.)
2. Add routes (`cp -r src/routes/_skeleton src/routes/<route>`) and register
   each as a row in `.claude/memory/INDEX.md`; give each a `routes/<route>.md`
   map once it earns one.
3. Fill `src/shared/tokens.css` if routes will share a design system;
   otherwise leave empty.
4. Commit: `scripts/ship.sh "chore: bootstrap project"`.

## Daily flow

| when | do |
|---|---|
| session start | the SessionStart hook injects the mode menu + skill index; Claude locks a session mode, reads `.claude/memory/INDEX.md` (+ the route map on multi-route projects) and locks scope |
| change route mid-session | say "switch to /route" or "unlock scope" — scope is never re-inferred silently |
| ship a chunk | `scripts/ship.sh "msg"` (validates + builds changed routes + commits + pushes) |
| Stop-hook nudge appears | run `/checkpoint` |
| need a new capability | ask for it, or `/skills load <name>` from the store (thin — no doctrine read); `skill-curator` installs a brand-new one from the web |

## Environment notes

- **Vendoring a web library** (e.g. GSAP) for a self-contained build: fetch from
  `https://registry.npmjs.org/<pkg>/-/<pkg>-<ver>.tgz`. `unpkg.com` is blocked by the
  agent proxy (CONNECT 403); the npm registry is allowlisted. Drop the minified file in
  the route's dir and `@inline` it — but never whole-file Read that blob (built-file hazard).
- **Skill activation is local.** `/skills load X` copies a skill into `.claude/skills/`,
  which is gitignored except the always-on whitelist — so it never leaks to other
  branches. The store (`.claude/skills-store/skill-storage/`) is the shared library.
