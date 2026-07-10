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
| `.claude/skills/anti-slop-preflight/` | pre-ship checklist for visual/design changes |
| `.claude/memory/` | `INDEX.md` registry + per-route maps + shared registries (committed = persistent) |
| `.claude/skills-store/` | dormant skill library (zero context cost until loaded) |
| `.claude/settings.json` | Stop hook → `scripts/checkpoint-nudge.sh` (deterministic, zero-token recommender) |
| `scripts/` | `validate.mjs` · `build.mjs` · `ship.sh` · `checkpoint-nudge.sh` · `scope-guard-hook.sh` |
| `tests/` | fixtures + `test-tooling.mjs` covering the scripts above |
| `src/routes/_skeleton/` | copy this when adding a new route (portal profile) |
| `src/shared/tokens.css` | shared design tokens routes opt into via `<!-- @inline:../../shared/tokens.css -->` |

## Starting a new project from this repo

This repo *is* the starter kit — for a new project, create a new GitHub repo
from this one (or clone it and re-point `origin`), then:

1. Set `profile:` in `.claude/memory/INDEX.md` — `portal` (multi-route domain:
   every session locks onto ONE route, with an auto route-picker question when
   the first prompt is ambiguous) or `standalone` (single site/app: whole
   project is the scope, no lock ceremony).
2. Add routes under `.claude/memory/INDEX.md` as they're created (`cp -r
   src/routes/_skeleton src/routes/<route>`); give each a `routes/<route>.md`
   map once it earns one.
3. Fill `src/shared/tokens.css` if routes will share a design system;
   otherwise leave empty.
4. Commit: `scripts/ship.sh "chore: bootstrap project"`.

## Daily flow

| when | do |
|---|---|
| session start | Claude reads `.claude/memory/INDEX.md` + the route map and locks scope (project-memory skill, automatic) |
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
