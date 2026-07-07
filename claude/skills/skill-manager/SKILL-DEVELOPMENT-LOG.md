# Skill development log — token-efficient project memory system

Not part of the anchor/map system (deliberately outside `.claude/memory/`): this
tracks development of the *tooling itself* (skills, scripts, template), not
site content. The anchor-checker in `scripts/validate.mjs` only scans
`.html`/`.css`/`.js`/`.mjs` for `@sec:`/`@css:`/`@js:` anchors — it never reads
`.md`, so skill docs can't be wired into `INDEX.md`'s route table without
failing lint. Keep this file as free-form prose; don't register it as a route.

## Origin

Built after completing the M3.o survey-report project. Un-instrumented session
cost ~400K tokens, ~80% from repeated whole-file reads of `index.html` (2.3MB,
89% base64 on one line). Root cause: no stable navigation system, so every
prompt re-discovered section locations via grep/awk over the full file.

## Architecture (as shipped)

- **Anchor comments** (`@sec:`, `@css:`, `@js:`) in source — stable grep
  targets, immune to line-number drift.
- **Compartmentalized memory** — `.claude/memory/INDEX.md` (registry + global
  gotchas, cap 60 lines) → `routes/<r>.md` (per-route section→anchor map, cap
  100 lines) → `shared/*.md` (cross-route facts, cap 80 lines).
- **profile: portal | standalone** line in INDEX.md — switches session
  behavior:
  - `portal` (multi-route domain): session locks to ONE route; fires a
    route-picker survey only when the first prompt is ambiguous about which
    route it targets. Advisory lock — Claude won't silently wander cross-route
    without a `shared/` pointer or explicit user request.
  - `standalone` (single site/app): no lock ceremony, whole project is scope.
- **Zero-token Stop hook** (`scripts/checkpoint-nudge.sh`) — measures git delta
  since the last `chore(memory): checkpoint` commit (files touched, lines
  changed, new anchors introduced) and recommends `/checkpoint` when thresholds
  cross (≥5 files / ≥150 lines / new anchors). Pure shell, no model call.
- **`/checkpoint` skill** — the only thing allowed to rewrite memory files.
  Cheap-model-safe: strict rewrite protocol + hard prohibitions (never
  invent anchors, never exceed caps, never drop gotchas) in
  `checkpoint/SKILL.md`.
- **`validate.mjs --memory`** — lints INDEX.md/route maps against actual code:
  profile line present, required headings present, every anchor named in a
  route map must resolve in that route's actual `.html/.css/.js/.mjs` source,
  drift detection (routes present on disk but unregistered in INDEX).

## Key decisions and why

| Decision | Why |
|---|---|
| Anchors are comments, not line numbers | Line numbers drift on every edit; comments survive |
| Map caps are hard limits (60/100/80 lines) | Forces pruning; a memory file that grows unboundedly defeats the point |
| Scope-lock is advisory, not hard-enforced | Blocking cross-route reads outright would make simple hub/shared-data routes unworkable |
| Survey fires only on ambiguity, not every session | Asking "which route?" on every prompt in a single-route session is pure friction |
| Anchor resolution restricted to html/css/js/mjs | Matches the actual site-content stack this was built for; not extended to arbitrary doc formats (see note above) |
| Checkpoint nudge is shell-only, zero-token | The recommender must not itself cost tokens to run every Stop event |

## Known edge cases handled

- Unborn HEAD (first commit) in `ship.sh`
- `build.mjs --all` filtering out `_skeleton`/hidden template entries
- Fresh scaffold with an empty route table (allowed) vs. real on-disk routes
  unregistered in INDEX (flagged as drift)
- Missing `profile:` line (hard lint failure)

## Open / next

- (add items here as new work chunks start)
