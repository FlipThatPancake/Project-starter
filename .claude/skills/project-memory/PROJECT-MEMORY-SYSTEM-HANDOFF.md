# Project-memory system — complete reference for a fresh Claude session

This is a standalone technical reference for the token-efficient project-memory
system built into this repo. It is written so a Claude session in a **different
environment** (a fresh clone, a starter-repo derivative, or another repo this
system gets copied into) can understand the whole system from this one file,
without having lived through the sessions that built it.

Not part of the anchor/map system itself (deliberately outside
`.claude/memory/`): this describes the *tooling*, and is prose by design. The
anchor-checker in `scripts/validate.mjs` only scans `.html`/`.css`/`.js`/`.mjs`
for `@sec:`/`@css:`/`@js:` anchors — it never reads `.md`, so this file (like
`.claude/memory/agent-log/SKILL-DEVELOPMENT-LOG.md`) can't and shouldn't be wired into `INDEX.md`'s route
table.

For the chronological *why* behind each decision, see `.claude/memory/agent-log/SKILL-DEVELOPMENT-LOG.md`.
This file is the *what/how*, organized as a reference, not a log.

---

## 1. The problem this solves

A large single-file site (`index.html`, 2.3MB, 89% base64 image data on one
line in this repo) burns enormous context if an agent re-discovers section
locations via whole-file reads or unscoped greps every session. Measured cost
on this repo pre-instrumentation: ~400K tokens in one session, ~80% from
repeated whole-file reads of the same megaline file.

The fix has two independent halves:
1. **Stable navigation** — comment anchors in source that survive edits (line
   numbers don't), so an agent can grep a name instead of reading everything.
2. **Compartmentalized memory** — small, capped markdown files that tell an
   agent WHERE things are (anchor names, gotchas, decisions) without
   duplicating WHAT the code does. The agent still reads real code for
   content; the memory files exist purely to make that reading targeted.

Everything else in this system (scope-lock, enforcement hooks, validation,
checkpoint) exists to keep those two halves honest and small over time.

---

## 2. Layer map (what depends on what)

```
project-memory skill (SKILL.md)          ← session-level protocol Claude follows
   │  writes                                 (route count → scope-lock →
   │  /tmp/claude-route-scope-<hash>                read-order → anchor navigation)
   ▼
scope-guard-hook.sh (PreToolUse hook)     ← reads that file, enforces scope
   +
ship.sh's cross-route gate (post-commit) ← reads that file too, catches
                                             anything the hook missed

checkpoint skill (SKILL.md + references/) ← rewrites INDEX.md + route maps
                                             (the rear-view); format spec
                                             lives in map-format.md
   +
spec skill / domain-modeling skill        ← sibling writers, same directory:
                                             spec writes SPEC.md (road ahead),
                                             domain-modeling writes CONTEXT.md
                                             (glossary) — same cap discipline,
                                             disjoint scope from checkpoint

validate.mjs                              ← lints .claude/memory/* against
                                             real code (anchors resolve, caps
                                             respected, shape correct)

checkpoint-nudge.sh (Stop hook)           ← zero-token shell heuristic that
                                             recommends running /checkpoint

build.mjs                                 ← unrelated to memory; resolves
                                             @asset/@inline BUILD markers
                                             (different from @sec/@css/@js
                                             NAVIGATION anchors) into dist/
```

Nothing in this stack calls a model. Every script here is deterministic shell
or zero-dependency Node. The only "intelligence" is the SKILL.md files, which
are protocol Claude reads and follows — they are not executable.

---

## 3. File inventory

| path | role |
|---|---|
| `.claude/skills/project-memory/SKILL.md` | Session protocol: scope-lock, read order, anchor navigation, enforcement description |
| `.claude/skills/project-memory/references/anchor-conventions.md` | Anchor syntax/naming rules, grep recipes |
| `.claude/skills/checkpoint/SKILL.md` | Rewrite protocol for `INDEX.md` + route maps (SPEC.md/CONTEXT.md have their own sibling writers — see §8) |
| `.claude/skills/checkpoint/references/map-format.md` | The format spec: file caps, required headings, state-line semantics |
| `.claude/skills/checkpoint/references/example-index.md` | Canonical `INDEX.md` shape to copy exactly |
| `.claude/skills/checkpoint/references/example-route-map.md` | Canonical `routes/<r>.md` shape to copy exactly |
| `.claude/memory/INDEX.md` | The registry: state line, route table, shared registries, global gotchas |
| `.claude/memory/routes/<route>.md` | Per-route section→anchor map (only for routes past the complexity threshold) |
| `.claude/memory/shared/<id>.md` | Cross-route facts (design tokens, shared data) — never duplicated per-route |
| `.claude/skills/spec/SKILL.md` | Writes `.claude/memory/SPEC.md` — forward-looking plan + tickets, ticked only on explicit user confirmation |
| `.claude/skills/domain-modeling/SKILL.md` | Writes `.claude/memory/CONTEXT.md` — project-specific term glossary |
| `.claude/memory/SPEC.md` | The road ahead: per-project "what it is" / "what matters" / tickets (optional, lazily created) |
| `.claude/memory/CONTEXT.md` | The shared glossary: canonical terms + `_Avoid_` synonyms (optional, lazily created) |
| `scripts/validate.mjs` | Lints both source anchors (`--src`) and memory (`--memory`); also `--skills` (separate, skill loadout lint, unrelated to memory) |
| `scripts/scope-guard-hook.sh` | PreToolUse hook: nudges (advisory) on Edit/Write outside the declared scope; blocks only when the enforce flag is set |
| `scripts/ship.sh` | validate → build changed routes → commit → cross-route gate → push (with retry) |
| `scripts/checkpoint-nudge.sh` | Stop hook: zero-token `/checkpoint` recommender |
| `scripts/build.mjs` | Resolves `@asset`/`@inline` BUILD markers into `dist/<route>.html` (unrelated to navigation anchors, but shares the same comment-marker idea) |
| `scripts/test-tooling.mjs` + `tests/fixtures/*` | Regression suite for validate.mjs/build.mjs behavior |
| `.claude/settings.json` | Wires both hooks (`PreToolUse` → scope-guard, `Stop` → checkpoint-nudge) |

---

## 4. Anchors: the navigation primitive

Three comment prefixes, placed on their own line immediately before the thing
they mark:

| context | anchor | end-marker (only for >200-line spans, optional) |
|---|---|---|
| HTML | `<!-- @sec:name -->` | `<!-- @end:name -->` |
| CSS | `/* @css:name */` | — |
| JS | `// @js:name` | — |

**Naming**: lowercase kebab-case, ≤3 words (`concept-modal`, not `ConceptModal`
or `the-concept-modal-thing`). Unique per file per prefix. The SAME name
across `@sec:`/`@css:`/`@js:` is a deliberate pairing meaning "these are the
HTML/CSS/JS layers of one feature" — grep them together:
`grep -n "@(sec|css|js):concept-modal" file.html`.

**Never rename an anchor** — memory maps and grep habits reference it by name.
Add a new one instead if the old concept is truly gone.

**Anchors are pure text matches.** A literal anchor-looking string in prose or
a comment registers as a real anchor to the validator and to grep. (A test
fixture in this repo's history briefly had `@sec:ghost` mentioned in
explanatory text and it satisfied the orphan-pair check — this is a known
sharp edge, not a bug: don't write anchor-shaped strings in docs/prose unless
you mean it.)

A separate, unrelated marker syntax exists for **build resolution** (handled
by `build.mjs`, not `validate.mjs`'s anchor lint, not a navigation aid):
- `<!-- @asset:assets/foo.png -->` → next `src="…"` becomes a base64 data-URI.
- `<!-- @inline:../shared/tokens.css -->` → replaced by the file's contents,
  wrapped in `<style>`/`<script>` by extension.

---

## 5. Memory files: format and caps

### `INDEX.md` (cap: 60 non-empty lines)
Required shape (line 2 is the state line, exact heading names matter — the
validator string-matches them):

```markdown
# MEMORY INDEX — read first; then ONLY your route's map + the shared files its pointer rows name
state: in-progress

## Routes
| route | path | status | map | design | data-deps |
|---|---|---|---|---|---|
| /survey-jun26 | jun26/index.html | live | routes/survey-jun26.md | design-m3 | — |

## Shared registries
| id | file | used-by |
|---|---|---|
| design-m3 | shared/design-m3.md | survey-jun26, survey-sep26 |

## Global gotchas (never evicted; max 8)
- Never Read a route's dist/*.html — generated; sources only.
```

- `state:` is `starter` or `in-progress` — see §6 for what it actually does.
- A route with no real complexity stays a one-row stub: `map: —`. It does NOT
  need its own `routes/<r>.md` file.
- A `## Shared registries` row whose `used-by` column lists only ONE route is
  flagged by the validator as `shared-solo` (a warning, not a failure) — it's
  not actually shared yet, keep it route-local until a 2nd route needs it.
- `## Global gotchas` is capped at 8 **bullets**, hard limit, never evicted —
  if you're at 8 and need a 9th, something else has to be promoted out of
  "global" into a route-specific gotcha, or genuinely retired.

### `routes/<route>.md` (cap: 100 non-empty lines)
Only created once a route crosses a complexity threshold (see
`map-format.md`: >300 lines of code, >5 mapped sections, ≥1 gotcha, OR edited
in ≥2 sessions — whichever comes first). Below that, the route stays a stub
row in INDEX with `map: —`.

```markdown
# /survey-jun26 — jun26/index.html (single self-contained file; CSS top, HTML mid, JS bottom)
uses: design-m3 (shared/design-m3.md) | data: none (inline JS objects)

## Sections
| section | anchor(s) | gotcha |
|---|---|---|
| preference list | @sec:preference · @js:render-preference | stagger selector must match JS-emitted wrapper class or bars stick at 0% |

## Hot elements (most-edited)
- bar stagger rules: @css:reveal-stagger

## Priorities / planned
1. P1: mobile layout for concept-modal zoom

## Recent decisions (cap 10, newest first)
- 2026-07-03 concept-modal zoom = in-modal takeover, not width-expand
```

- `## Recent decisions`: capped at **10 bullets**, newest first, oldest
  evicted first when full. If an evicted decision is still load-bearing
  (something a future session needs to not re-break), promote it to a
  gotcha before it's dropped — gotchas are never evicted.
- Route gotchas live either in the `Sections` table's gotcha column, or in an
  optional `## Gotchas` block — the validator counts BOTH toward the cap of
  10.
- Tables over prose everywhere (~15 vs ~40 tokens per fact). Prose is
  reserved for gotchas where compressing would lose the actual lesson.

### `shared/<id>.md` (cap: 80 non-empty lines)
Facts genuinely used by ≥2 routes — tokens, patterns, shared data shapes.
Route maps point at these (`uses: design-m3 (shared/design-m3.md)`) but never
copy concrete values out of them. A route's own map should never duplicate
what's in a shared file.

### `SPEC.md` (cap: 120 non-empty lines) — written by `spec`, not checkpoint
The forward-looking twin of `INDEX.md`: per-project sections with "what it
is", "what matters", and a ticket checklist. Optional, created lazily on the
first spec. Full format lives in `.claude/skills/spec/SKILL.md` (not
duplicated here to avoid two sources of truth). Tickets are ticked only on
the user's explicit confirmation — never inferred from a diff or a push.
Injected in full at every session start by `session-start-hook.sh` when
present (zero-cost when absent).

### `CONTEXT.md` (cap: 80 non-empty lines) — written by `domain-modeling`, not checkpoint
The project's shared glossary: term, tight definition, `_Avoid_` synonyms.
Optional, created lazily on the first settled term. Full format lives in
`.claude/skills/domain-modeling/SKILL.md`. Glossary only — no decisions, no
implementation detail. Also injected in full at session start, same
mechanism as `SPEC.md`.

---

## 6. `state:` line — what it actually controls

Early versions of this system had a `profile: portal|standalone` line as a
**structural** fork — standalone meant a flat-file project, portal meant
`src/routes/<name>/`. That fork was collapsed (see
`.claude/memory/agent-log/SKILL-DEVELOPMENT-LOG.md`, "sixth work chunk") because it created a painful
migration cliff the moment a standalone project grew a second route. The
`profile:` line is GONE — if you see it in an old copy of this system, it's
stale; the validator now rejects it.

**Current model**: INDEX.md line 2 is `state: starter` (fresh/unbootstrapped —
the mother Project-starter repo stays this forever) or `state: in-progress`
(a real project; mode 2 new-project flips it once at first bootstrap). The
line only tells the session-start hook whether to steer toward bootstrap.
`checkpoint` never changes it.

Scope-locking is unrelated to this line — it is driven by **route COUNT**:

| INDEX route count | behavior |
|---|---|
| ≥ 2 | multi-route: every session locks to ONE route (§7) |
| ≤ 1 | trivially scoped — the one route IS the whole project, skip locking |

Structure is ALWAYS route-based conceptually (even a single `index.html`
counts as one route); a one-route project that grows a second route starts
locking automatically, nothing to flip.

---

## 7. Session scope-lock + enforcement

### The protocol (project-memory SKILL.md §1)
When INDEX lists ≥2 routes:
- First user prompt names a route unambiguously → lock silently, state
  `Scope: /<route>` in one line.
- Ambiguous → ask exactly ONE `AskUserQuestion`, options built live from
  INDEX's route table, plus "whole project / cross-route" and "new route".
- On lock, persist it to a tmp file so it survives context compaction within
  the session:
  ```bash
  echo "/<route>" > /tmp/claude-route-scope-$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
  ```
  The hash is of the absolute repo path, so different repos/worktrees don't
  collide. **This exact hash formula must match across the skill doc, the
  hook, and ship.sh — if one of them uses a different hash algorithm, the
  three pieces silently stop agreeing on which file to check.** (This
  actually happened once, in a now-deleted `project-template/` copy of the
  skill that used an older `cksum`-based formula — a reminder that any
  future copy of these files must be re-derived from live files, not
  hand-maintained separately.)
- Re-scope ONLY on explicit user instruction ("switch to /x", "unlock
  scope"). Never re-infer from a later ambiguous prompt.

### The enforcement layer (two independent backstops)

**1. `scope-guard-hook.sh` — a PreToolUse hook.**
Wired in `.claude/settings.json` under `hooks.PreToolUse`. Runs before every
Edit/Write tool call. Reads the scope-lock tmp file; if none exists, no-ops
(exit 0). If locked, reads the hook's stdin JSON and checks the target file
path against an allowlist.

**Critical implementation detail — get this exactly right or the hook is a
silent no-op:** Claude Code's actual PreToolUse hook payload uses these exact
field names:
```json
{
  "tool_name": "Edit",
  "tool_input": { "file_path": "/absolute/path/to/file" },
  "cwd": "/absolute/repo/root"
}
```
`tool_name` (not `tool`), `tool_input.file_path` (not `params.file_path`),
and **`file_path` arrives as an absolute path**, not repo-relative. An earlier
version of this hook read the wrong field names — the wrong names meant
`TOOL_NAME` was always empty, so the hook exited 0 on literally every call
and never blocked anything, for the entire time it existed before this bug
was caught. If you're porting this hook to a new repo or rewriting it, verify
against the current Claude Code hooks documentation, because a field-name
typo here produces a hook that LOOKS installed and configured but enforces
nothing — no error, no warning, just silent pass-through.

The scope itself: `src/routes/<locked-route>/**` and `.claude/**` are always in
scope. Everything else — including shared files like `shared/tokens.css` that the
locked route depends on — is out-of-scope. **Posture (advisory by default):** an
out-of-scope Edit/Write is ALLOWED, with a nudge emitted via the PreToolUse
`additionalContext` (to Claude) + `systemMessage` (to the user), exit 0. This is
deliberate — editing a shared file DOES ripple to every route that inlines it, but
that is often exactly the intended cross-scope work (design-system, data, docs), and
forcing a re-lock on each one was the friction that made the old hard wall get
overridden constantly. The nudge keeps the "am I drifting?" signal without the tax.

**Opt-in enforcement:** `touch /tmp/claude-scope-enforce-$H` flips the hook to
BLOCKING — out-of-scope Edit/Write then returns exit 2 (JSON reason on stderr) until
the scope is widened or the flag cleared. Raise it deliberately for tightly-scoped
work on a big multi-route project, where an accidental cross-route edit is the risk
worth a deterministic, before-review guarantee. `@allow-cross-route` is the COMMIT
gate's override (below), relevant when enforcing.

**2. `ship.sh`'s pre-commit cross-scope gate.**
The PreToolUse hook only sees tool calls — a Bash-written file (e.g.
`sed -i` from inside a Bash tool call) bypasses it entirely; hooks that
inspect Bash commands are best-effort/fails-open by nature. `ship.sh`
provides the parallel check: after staging (`git add -A`), BEFORE committing,
it checks every STAGED file (`git diff --cached --name-only`, repo-relative
paths) against the same scope. It mirrors the hook's posture — advisory by
default (warn on stderr and proceed), and refusing to commit (exit 2) only when
the enforce flag is set and the commit message lacks `@allow-cross-route`.

Together: the hook nudges most drift proactively (before the model even sees a
would-be edit accepted); the ship-time gate re-checks at commit and catches what
slips past (Bash writes) — both advisory unless you've opted into enforcement.

---

## 8. `checkpoint` skill — writer of INDEX.md and route maps

`project-memory` is read-and-navigate; `checkpoint` rewrites `INDEX.md` and
`routes/<route>.md` — the rear-view of the memory system (what exists).
Invoked on `/checkpoint`, "save progress", or "update memory" — or
recommended by the Stop-hook nudge (§10).

Two sibling files live in the same directory with their own writers, not
checkpoint: `SPEC.md` (the road ahead — written by the `spec` skill) and
`CONTEXT.md` (the shared glossary — written by `domain-modeling`). Both are
first-class memory files, capped and validated the same way (§9), but
checkpoint never touches them — see each skill's own `SKILL.md` for its
write discipline.

Protocol (`checkpoint/SKILL.md`):
1. Read `map-format.md` + both example files FIRST, match their shape
   exactly — same columns, same terseness. This is explicitly designed to be
   "cheap-model-safe": a smaller/cheaper model running checkpoint should still
   produce correct output because the shape is copied, not improvised.
2. Diff-scope yourself: list only the routes/sections THIS session actually
   touched. Everything else stays byte-identical — checkpoint is not a
   whole-memory rewrite, it's a targeted patch.
3. Grep every anchor before keeping/adding it to a map. Dead anchor (in map,
   gone from code) → either the section still exists (re-insert the anchor
   comment, cheap) or it's genuinely gone (delete the map row).
4. Hard prohibitions: never delete/reword an unverified gotcha, never
   convert tables to prose, never rewrite untouched sections, never
   "summarize" existing rows.
5. After writing: run `node scripts/validate.mjs --memory` and fix failures
   before proceeding. Never commit failing memory.
6. Commit message convention: `chore(memory): checkpoint <routes touched>`.
   (`checkpoint-nudge.sh`'s baseline diff looks for this exact grep pattern
   to find "since the last checkpoint" — using a different message format
   breaks the nudge's baseline detection.)

Cap-eviction rule when a file is at/over its line cap: evict oldest DECISIONS
first; if an about-to-be-evicted decision is still load-bearing, promote it
to a gotcha first (gotchas are never evicted, only decisions are).

---

## 9. `validate.mjs` — what it actually checks

Two independent modes plus a third (unrelated) one that now coexists in this
codebase:

**`--src <file>...`** (HTML/CSS/JS source checks):
1. Inline `<script>` blocks parse as valid JS (via `node:vm`).
2. No leftover git conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`).
3. Anchor uniqueness per file (no duplicate `@sec:foo` twice in one file).
4. Anchor naming convention: lowercase prefix, kebab-case name, ≤3 words
   (`anchor-name` rule — case-insensitive match, so `@Sec:FooBar` is caught).
5. Every `@end:name` pairs with a `@sec:name` in the same file (`end-orphan`
   rule). `@sec:` without a matching `@end:` is legal — end markers are
   optional and only meant for >200-line spans.
6. Build markers (`@asset:`/`@inline:`) resolve to real files relative to the
   source file's own directory.

**`--memory [--routes a,b]`** (memory lint, stack-agnostic):
- Line caps: INDEX 60 / route map 100 / shared file 80 / SESSION-LOG 40 /
  SPEC.md 120 / CONTEXT.md 80 (non-empty lines; SPEC/CONTEXT checked only
  when the file exists — both are optional, lazily created).
- Shape: `state:` line present and valid, required headings present in
  both INDEX and every registered route map.
- **Semantic caps** (added specifically because line caps alone don't stop a
  cheap model from stuffing 20 one-line decisions into a still-under-100-line
  file): global gotchas ≤8, route decisions ≤10, route gotchas ≤10 (counting
  both the Sections-table gotcha column and any `## Gotchas` block bullets).
- Drift detection: routes present on disk under `src/routes/` but missing
  from INDEX's route table → hard failure. An empty route table is fine on a
  fresh scaffold, but real on-disk routes must be registered.
- The expensive check — every anchor named in a route's map must actually
  resolve in that route's real source — is **scoped** via `--routes a,b`:
  only routes whose id is in that list get the (expensive, reads-the-code)
  anchor walk; everything else still gets the cheap shape/cap checks (those
  only read small `.md` files). Omitting `--routes` = deep-check every route
  (full audit; this is what `--all` and `ship.sh --deep` use).
- `shared-solo` is a **warning**, not a failure — printed to stderr, but exit
  code stays 0. Everything else above is a hard failure (exit 1).

**`--skills`** (unrelated to memory — this is the skill loadout lint: checks
each skill's own SKILL.md frontmatter (name/description/exclusive-with) against
the `.gitignore` always-on whitelist. It happens to live in the same file
because both systems converged on `main` after being built in parallel
sessions. If you're reading this in a repo without the skill-loadout system,
`--skills` and `--all`'s optional `checkSkills()` call will simply no-op —
`--all` only runs it `if (existsSync('.claude/skills'))`.)

Exit codes throughout: `0` clean (possibly with warnings) · `1` validation
failures (all listed, not just the first) · `2` usage/IO error.

---

## 10. `checkpoint-nudge.sh` — the Stop-hook recommender

Wired under `hooks.Stop` in `.claude/settings.json`. Runs after every model
turn ends. Pure shell, zero model tokens, rate-limited to once/hour/repo via
a tmp stamp file.

Measures git delta since the last `chore(memory): checkpoint` commit (or the
repo's root commit if none exists yet):
- Files changed (excluding `dist/`, `.claude/memory/`, `*.lock`).
- Lines changed (insertions + deletions).
- New/edited anchor lines (`+.*@(sec|css|js):` in the diff).
- Removed anchor lines (`-.*@(sec|css|js):`) — tracked symmetrically with new
  ones, because an *edited* anchored line diffs as `+1/-1` and fires both
  counters. This is intentionally conservative: a changed anchored line may
  mean the map's description of that section is now stale too.
- New files under `src/`.

Thresholds (any one crossing triggers the nudge): ≥5 files, ≥150 lines, ≥1
anchor line touched, ≥1 new src file. Emits a `systemMessage` JSON line the
harness surfaces to the user; does not block anything, purely advisory.

If the skill-loadout system is installed in the repo, `checkpoint-nudge.sh` on `main`
also carries two unrelated nudges (skill-loadout drift, third-party skill
staleness) that were added by that parallel system — these coexist in the
same file but are logically independent of the memory-checkpoint nudge.

---

## 11. `ship.sh` — the orchestration script

```
scripts/ship.sh "commit message" [--no-validate] [--no-build] [--no-push] [--all] [--deep] [--sync] [--to-main]
```

Sequence: validate → build changed routes → `git add -A` → cross-route gate
(§7, pre-commit) → commit → push with retry (0s/2s/4s/8s/16s backoff).
`--to-main` is the ship-now skill's confirmed fallback only — normal path to
main is a GitHub PR merge.

- Validation is **scoped by default**: derives changed route ids from
  `git diff HEAD` over `src/routes/`, `.claude/memory/routes/`, and root
  `index.html`, passes them to `validate.mjs --memory --routes <ids>`.
  `--deep` or `--all` forces a full audit; an unborn HEAD (first commit ever)
  also forces deep, since there's no baseline to diff against.
- Build is similarly scoped: only routes whose `src/routes/<r>/` changed vs
  HEAD get rebuilt, unless `--all`.
- This is the single entry point meant for actual use — "never inline `node
  -e` validators," per this repo's `CLAUDE.md`. Don't hand-roll the
  validate→build→commit→push sequence; always go through `ship.sh`.

---

## 12. `build.mjs` — unrelated to navigation, don't confuse the two

`node scripts/build.mjs <route>... | --all` turns
`src/routes/<route>/index.html` into a single self-contained
`dist/<route>.html`, resolving `@inline:` (whole-file inlining, wrapped by
extension) and `@asset:` (base64 data-URI) markers relative to the source
file's own directory. Deterministic: same input bytes → same output bytes.
Missing/unresolved marker → exit 1, nothing written (never a partial dist).

Navigation anchors (`@sec:`/`@css:`/`@js:`) are deliberately preserved in the
built output — they cost ~20 bytes each and keep `dist/` grep-able when
debugging production artifacts, even though `dist/` itself should never be
read as a memory source (`CLAUDE.md` hard rule: "Never read dist/").

If a project has no `src/routes/` (a single flat `index.html`, like this
repo's actual content route), `build.mjs` is simply inert — there's nothing
to build, sources ARE the served artifact.

---

## 13. Testing

`node scripts/test-tooling.mjs` — zero-dependency regression suite. Each case
copies a `tests/fixtures/<name>/` directory to a fresh temp dir, runs
`validate.mjs` or `build.mjs` there as a child process, and asserts exit code
+ expected stdout/stderr substrings. Fixtures:

| fixture | exercises |
|---|---|
| `good` | clean memory + clean HTML both validate exit-0 |
| `bad-memory` | semantic caps (`cap-gotchas`, `cap-decisions`) + dead anchor all reported together |
| `bad-html` | anchor-naming violation + orphan `@end:` both reported |
| `build-demo` | markers resolve, output is self-contained, anchors preserved in dist |
| `build-bad` | unresolved `@asset` fails cleanly, writes nothing |
| `scoped-memory` | proves `--routes` actually skips the expensive anchor-walk for out-of-scope routes while still running cheap checks (and the `shared-solo` warning fires) |

A repo with the `usage-analysis` skill installed also has a `transcript`
fixture testing `analyze-usage.mjs` — that skill/script is a separate work
chunk, not part of this core memory system, and isn't present in every
branch/repo this system has been copied into (see §14).

**Known sharp edge from writing these fixtures**: fixture prose that happens
to contain an anchor-shaped string (e.g. `@sec:ghost` in an explanatory
comment) registers as a real anchor to the validator, since anchors are pure
text matches with no context awareness. Word your fixtures' non-anchor prose
carefully.

---

## 14. Known gaps / staleness

A `project-template/` folder used to exist as a portable copy of this
system, but it was deleted on 2026-07-07 — it had gone stale relative to the
live files here (see the note in item 2 below), and since this repo's root
is itself the clean starter kit (no unrelated project content mixed in), a
separate copy added duplication risk without adding value. New projects
should be started by copying this repo directly (new GitHub repo from this
one, or clone + re-point `origin`), not from a template subfolder.

Separately, on `main` (as opposed to the dev branches this system was mostly
built on), the following related-but-separate skills/scripts have NOT been
ported and may not exist depending on which branch you're reading this from:
`usage-analysis` (on-demand transcript token analyzer), `project-setup` v2 /
`init-fresh` (session router + new-project bootstrap checklist),
`grill-with-docs` pack (`grilling` + `domain-modeling`, interview-driven
plan-stress-testing). These are documented in `.claude/memory/agent-log/SKILL-DEVELOPMENT-LOG.md` if
you need them; they're independent of the core memory/anchor/enforcement
system described in this file and can be added or skipped without affecting
anything above.

---

## 15. Bootstrapping a brand-new project with this system

1. Copy `.claude/skills/project-memory/`, `.claude/skills/checkpoint/`,
   `scripts/validate.mjs`, `scripts/scope-guard-hook.sh`, `scripts/ship.sh`,
   `scripts/checkpoint-nudge.sh`, `scripts/build.mjs` (if using
   `src/routes/`), and the `hooks` block of `.claude/settings.json` — from
   THIS repo directly (there is no separate `project-template/` — see §14).
2. Create `.claude/memory/INDEX.md` shaped exactly like
   `checkpoint/references/example-index.md`, with the `state:` line on line 2
   (`starter` until the project's first real bootstrap flips it to
   `in-progress`).
3. Add anchor comments (`@sec:`/`@css:`/`@js:`) to source from the very first
   file — retrofitting anchors onto unanchored code later is strictly harder
   than starting with them.
4. Run `node scripts/validate.mjs --memory` to confirm the bootstrap is
   shape-valid before your first commit.
5. Use `scripts/ship.sh "message"` for all commits going forward — it wires
   validation, scoped builds, the cross-route gate, and retry-push together;
   don't hand-roll the sequence.
6. Route maps (`routes/<r>.md`) get created lazily, only once a route
   actually crosses the complexity threshold in §5 — don't pre-create empty
   ones for every route on day one.
