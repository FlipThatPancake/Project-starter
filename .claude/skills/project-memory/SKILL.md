---
name: project-memory
description: Use at the start of every session in this repo — first to establish the session's route scope (portal profile), and whenever locating any route, page section, component, or element, including when the user names a route or a section ("the preference list", "/reports"). Read .claude/memory/INDEX.md and the matching routes/<route>.md map BEFORE any exploratory file reads or greps.
group: core
---

# Project memory — session scope + read protocol

## 0. Route COUNT decides scope behavior; `state:` only gates bootstrap
Structure is ALWAYS route-based (`src/routes/<name>/`); a single-file project is
just a one-route project. What varies is whether the scope-lock question fires:
| situation | behavior |
|---|---|
| INDEX lists ≥2 routes | multi-route: narrow EVERY session to one route (§1) |
| INDEX lists ≤1 route | trivially scoped: the one route IS the whole project; skip §1 |

Route COUNT is the ONLY driver of locking — no portal/standalone flag. A one-route
project that grows a 2nd route starts locking automatically; nothing to flip.
The `state:` line (`starter`/`in-progress`) is unrelated to scope — it only tells
the session-start hook whether to steer toward new-project bootstrap (see
`.claude/modes/MODES_PROTOCOL.md`). Missing `state:` = treat as `starter`.

## 1. Session scope lock (when INDEX lists ≥2 routes)
- First user prompt names a route/project unambiguously → lock silently; state one line: `Scope: /<route>`.
- Ambiguous → ask ONE AskUserQuestion with options built live from INDEX's route table, plus "whole project / cross-route" and "new route". Nothing more — every other survey answer already lives in the memory files.
- On lock, persist it: `echo "/<route>" > /tmp/claude-route-scope-$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)` — and re-read that file whenever scope is uncertain (e.g. after a context compaction).
- The lock is advisory but binding: confine reads/greps/edits to the locked route's paths + the shared files its pointer rows name. Re-scope ONLY when the user says so ("switch to /x", "unlock scope") — never re-infer from a later ambiguous prompt.

### Enforcement (scope-guard)
Edit/Write tools are blocked outside the scope via PreToolUse hook: only edits to `src/routes/<locked>/**` and `.claude/memory/**` are allowed. Shared files (including `shared/tokens.css`) and other routes require override. To allow cross-route work, use `@allow-cross-route` in your prompt + final commit message — both the Edit/Write hook and ship-time gate check for it. Without override, cross-route commits are rejected at push time.

## 2. Read order (never deviate)
1. `.claude/memory/INDEX.md` — always, first.
2. `routes/<locked-route>.md` ONLY. Never bulk-read `routes/`.
3. Only the `shared/*.md` files that map's pointer rows name.
4. `ref/*.md` only when a task explicitly demands deep material.

## 3. Task type → files to read
| task | read |
|---|---|
| edit within locked route | INDEX + that route's map |
| cross-route / design-system change | INDEX + shared registry file(s) + each affected route's map |
| new route | INDEX only, then bootstrap (§6) |
| pure question | INDEX + route map; often no code reads at all |

## 4. Anchor-first navigation
- Maps list anchors (`@sec:concept-modal`, `@css:reveal-stagger`, `@js:render-preference`). `Grep` the anchor, then `Read` with offset/limit around the hit. NO exploratory whole-file Reads, NO blind Globs.
- One name across `@sec:`/`@css:`/`@js:` = layers of one feature; grep together: `@(sec|css|js):name`.

## 5. Cross-route etiquette: peek, don't wander (portal)
- Another route's MAP: read freely whenever the locked route references it (~cheap).
- Another route's CODE: only via a `shared/` pointer or the user's explicit request this session.
- A hub/home route consuming other routes' facts (titles, status, links) is SHARED DATA → maintain `shared/data-portal-manifest.md` (used-by: hub + all listed routes); never code-peek for it.

## 6. Trust & failure modes
| situation | action |
|---|---|
| map contradicts code | map wins for WHERE, code wins for WHAT; keep working from code, flag for /checkpoint |
| dead anchor (in map, not in code) | navigate via nearby anchors; flag for /checkpoint |
| `.claude/memory/` missing/empty | offer bootstrap: scan routes, generate INDEX + maps shaped like `../checkpoint/references/example-*.md`; ask before writing |
| route not in INDEX | add the row immediately (one line), continue |
| anchor conventions unclear | read `references/anchor-conventions.md` |
