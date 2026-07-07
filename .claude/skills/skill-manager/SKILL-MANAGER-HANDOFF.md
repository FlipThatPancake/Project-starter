# Skill Management System — handoff for a fresh Claude session

You are reading this because you've just landed in an environment/repo that has this
system installed, and you need the complete picture without re-deriving it from
scratch. This document is self-contained: it explains what the system is for, exactly
how every file and verb works, why it's built the way it is (so you don't undo a
deliberate decision thinking it's an oversight), and what's still incomplete.

Read this once, fully, before touching anything under `.claude/skills/` or
`.claude/skills-store/`.

---

## 1. The problem this solves

The user works across many projects and wants a large personal library of Claude Code
skills (design tools, animation libraries, research helpers, etc.) available *in
general*, without every one of them being loaded — and therefore costing context
tokens and competing for auto-trigger attention — in *every* session.

Claude Code's native behavior: any skill under `.claude/skills/` has its name +
description resident in context for the whole session (only the SKILL.md *body* is
progressively disclosed, loaded on invocation). There is no native per-skill
enable/disable switch in settings.json beyond an all-or-nothing
`disableBundledSkills`. So the only real lever is **filesystem presence**: a skill
directory that exists under `.claude/skills/` is active; one that doesn't, isn't.

This system turns that one lever into a deliberate, managed library:

- **`.claude/skills/`** = the checkout desk. Whatever sits here is **active** — in
  context, able to auto-trigger (unless muted). Keep this set small.
- **`.claude/skills-store/`** = the shelf. Skills here are **dormant** — zero context
  cost, invisible to the model, until deliberately loaded.
- A third category, **fixed** skills (harness bundled skills like `dataviz`/`pptx`,
  claude.ai account skills, installed plugins), live outside this repo entirely. This
  system cannot load/unload/mute them — it can only report on them truthfully.

The manager of this whole system is itself a skill: **`skill-manager`**, permanently
active (`pinned`), which is how a session ever gets to "load X" in the first place —
it's the one skill guaranteed present even in a brand-new session with nothing else
loaded.

## 2. Design principles (why it's built this way — don't relitigate these lightly)

1. **Mechanics in bash, judgment in the model.** Every actual filesystem operation
   (moving a directory, checking git refs, grepping for markers) runs in a script
   (`skillctl.sh`, `structcheck.sh`), not as freehand model actions. The model decides
   *what* to do; the script does it deterministically. This keeps operations cheap,
   auditable, and re-runnable as regression tests.
2. **Detection is automatic and cheap; every consequential action requires
   confirmation.** Drift detection, update-availability checks, and conflict detection
   all run without asking. Actually loading/unloading a skill, applying an update, or
   migrating a project file always goes through `AskUserQuestion` (or explicit
   command). Nothing destructive or hard-to-reverse happens silently.
3. **A ruling, once made, is written down — never re-derived.** User decisions about
   which skills conflict, which take precedence, which chain together, and what
   policy (pinned/ride-along/menu/manual) a skill gets are all recorded as data in
   the store, not left to the model's judgment each time. See `CONFLICTS.md` and
   `CATALOG.md`.
4. **Evidence and decisions are different files with different lifecycles.**
   `WIKI.md` is descriptive research (verbose, changes when you re-research a skill).
   `CONFLICTS.md` is prescriptive rulings (terse, changes when the user decides
   something). Don't merge these — mixing them made an earlier draft of this system
   worse, not better.
5. **A guardrail must never impose a style choice.** This bit the system once (see
   §7, the `quieter` incident) — a "restraint" principle from a design skill was
   briefly baked into the always-on guardrail, silently biasing every design toward
   minimalism. That was wrong and was reverted. Anything in the ride-along tier must
   be direction-agnostic: consistency/accessibility/mechanical checks, never "make it
   more X."
6. **Never track state you can instead derive.** There is deliberately no "skills
   used in this project" log. Conflict/handoff detection works by globbing for each
   skill's known **footprint files** in the live repo — what's actually on disk right
   now — not by remembering what ran before. A log would drift (skill ran, files
   later deleted, log still says "used"); a footprint scan is always current.
7. **Provenance must survive re-cloning.** A skill's "last updated" fact is stored as
   plain text in `LOCK.md`, fetched from **git commit history** (`git log
   --format=%cI`), never inferred from filesystem mtimes — mtimes reset on every
   `git clone`/copy, so they're useless for tracking whether a vendored copy is
   stale. This matters a lot once skills start round-tripping through a starter repo
   into fresh project checkouts.

## 3. Directory map

```
.claude/skills/                          ← ACTIVE — scanned by the harness, costs context
├── skill-manager/                       ← pinned, permanent, runs this whole system
│   ├── SKILL.md                         the resident protocol (verbs, picker, hard rules)
│   ├── references/
│   │   ├── catalog-format.md            row shapes + policy decision table
│   │   ├── add-and-handoff.md           pack/deep/standalone classification, footprint
│   │   │                                globs, structure signatures, load-time conflict
│   │   │                                detection, handoff seeding protocol
│   │   └── updates.md                   the review-gated update procedure + mandatory
│   │                                    dependency-file reconciliation
│   └── scripts/
│       ├── skillctl.sh                  status | load | unload | check-updates | pin
│       └── structcheck.sh               greps a project file for expected structural
│                                         markers; the mechanical core of reconciliation
├── project-memory/                      ← pinned (separate system — see §9)
└── checkpoint/                          ← pinned (separate system — see §9)

.claude/skills-store/                    ← DORMANT — NOT scanned, zero context cost
├── CATALOG.md                           what exists + policy (Installed + Upstream candidates)
├── MODULES.md                           sub-modules of deep skills/packs
├── CONFLICTS.md                         rulings: precedence/exclusive/sequential/
│                                        compatible/duplicate + Handoffs table
├── LOCK.md                              third-party provenance: pinned commit, its
│                                        upstream date, our install date, our local mods
├── MODE-SHORTLISTS.md                   per-mode starter picks for the entry GATE
├── profiles.md                          named bulk loadouts (session-level presets)
├── anti-slop-preflight/                 ← manual since 2026-07-07 (was ride-along —
│                                        see MODE-SHORTLISTS.md); design guardrail (§7)
└── WIKI.md                              deep research on 14 third-party skills — read
                                         ONLY for analysis/onboarding, never routinely
```
(Note: this tree is illustrative, not exhaustively synced to every `add` — CATALOG.md
is the live source of truth for what's actually installed where.)

Everything in `references/` and everything in `.claude/skills-store/` costs **zero
tokens** until a verb explicitly reads it. `skill-manager/SKILL.md` itself is the only
thing permanently resident, and it's kept to ~50 lines for exactly that reason —
pointers to the reference files, not the full procedure inline.

## 4. The three states, precisely

| state | where | context cost | who can change it |
|---|---|---|---|
| **active** | `.claude/skills/<name>/` | name+description resident; body loads on invocation | `skillctl.sh load/unload` (never hand-move) |
| **dormant** | `.claude/skills-store/<name>/` | zero — invisible to the harness | same |
| **fixed** | harness bundled / claude.ai account / installed plugin | resident, outside this repo's control | claude.ai settings / `disableBundledSkills` only |

`skillctl.sh status` reports the first two categories mechanically (by listing
directories and looking up each name's policy in `CATALOG.md`). Fixed skills are
listed from the live session's own skill listing at the time — there is no
file recording them, because they can drift independently of this repo and a
stale record would lie.

## 5. Policy — the fourth dimension, orthogonal to state

Every row in `CATALOG.md`'s Installed table also carries a **policy**, which governs
*how* an active skill behaves, decided once (with the user, via `AskUserQuestion`) at
`add` time:

| policy | behavior | who gets it |
|---|---|---|
| `pinned` | permanently active, cannot be unloaded (`skillctl.sh unload` refuses) | repo infrastructure every session needs: `skill-manager`, `project-memory`, `checkpoint` |
| `ride-along` | permanently active, auto-fires on matching tasks, **never asks** | guardrails the user wants with zero friction: none currently assigned — `anti-slop-preflight` held this policy until 2026-07-07, when the user changed it to `manual` (it doesn't apply to every session; see `MODE-SHORTLISTS.md`) |
| `menu` | active only when loaded, but even then **muted** (`disable-model-invocation: true` set in our own copy of its frontmatter) — can only be activated through the picker, never auto-fires | broad/overlapping skills where auto-triggering would cause mis-fires or unwanted style pushes — e.g. impeccable, taste-skill, frontend-design, ui-ux-pro-max, all in one `design-judgment` overlap group |
| `manual` | dormant by default; loaded by explicit name or via a `profiles.md` bulk preset | everything else — motion libraries, 3D tooling, research helpers |

The decision table for assigning policy to a *new* skill lives in
`references/catalog-format.md` — read it before ever running `add`.

## 6. Verbs — what `skill-manager` actually does

All of these are described tersely in the resident `SKILL.md`; this section is the
expanded version for onboarding.

### `list` / `status`
Runs `skillctl.sh status` (lists active + dormant with their policy from
`CATALOG.md`), then appends fixed skills read live from session context — never from
a file, because that would drift. A capability hunt ("do I have anything for X?")
also checks `MODULES.md` and the Upstream candidates table in `CATALOG.md`. On first
manager use in a new project, or when `LOCK.md`'s `last-checked` is stale/absent,
offer to run `check-updates`.

### `load <name>` / `load <profile>`
**Never** a direct `mv`. First runs the **load-time conflict check**
(`add-and-handoff.md` §3):
- Already active? → say so, skip.
- Is this skill the "B" side of a `sequential` rule in `CONFLICTS.md`, and does its
  predecessor's footprint (§2a) exist in the repo? → offer a **handoff** (§4 below)
  before loading.
- Does an `exclusive` peer's footprint exist? → warn that two source-of-truth systems
  would coexist; ask whether to proceed, pick one, or migrate.
- Is this a `duplicate` of something already installed? → refuse, name the kept copy.

Only after that check passes does `skillctl.sh load <name>` actually move the
directory from store to active. `load <profile>` reads a named bulk loadout from
`profiles.md` and loads each member the same way.

### `unload <name>` / `unload --all`
`skillctl.sh unload` — the script itself (not just the model's judgment) refuses to
unload anything whose policy is `pinned` or `ride-along`. `skill-manager` also never
unloads itself, as a hard rule independent of policy.

### `add <source>`
The interactive install flow, in order (full detail in `add-and-handoff.md` + the
resident SKILL.md's `add` section):
1. Fetch into the store; read **frontmatter description only** — never the full body,
   to keep categorization cheap.
2. **Classify**: does the fetched tree show multiple `skills/<name>/SKILL.md` (→
   **PACK**, register members individually, never as a unit) · one `SKILL.md` +
   a `reference/`/`docs/` folder (→ **DEEP**, index its modules) · one flat file (→
   **STANDALONE**)? Confirm with the user if ambiguous.
3. **Recommend a policy** from the decision table, confirm via `AskUserQuestion`
   (recommended option first).
4. **Check for conflicts**: does it duplicate or is it exclusive with something
   installed? Do its footprint files already exist in the repo (meaning some other
   session/skill already wrote them)? Warn/propose a `CONFLICTS.md` rule as needed.
   Record the new skill's footprint into `add-and-handoff.md` §2a in the same pass —
   this is the only place that table gets updated, and it's mandatory, not optional.
5. Write **one** `CATALOG.md` Installed row. If policy is `menu`, set
   `disable-model-invocation: true` in the vendored copy's own frontmatter — this is
   an edit to *our copy*, not upstream.
6. If deep/pack, index notable modules into `MODULES.md`.
7. If third-party, run `skillctl.sh pin <source>` to get an exact SHA + upstream
   commit date, and write one `LOCK.md` row.
8. `node scripts/validate.mjs --skills` must pass before the turn ends. Non-negotiable.

### `extract <parent>/<module>`
Distills one module of an already-installed deep skill into its own standalone store
skill. The precedent and proof this works: `anti-slop-preflight` **is** an extraction
of `taste-skill`'s §14 pre-flight checklist. Use this when you keep reaching for one
module of a large skill without wanting the whole thing loaded. Flip the module's
`MODULES.md` status from `referenced` to `extracted`; leave the parent untouched.

### `remove <name>`
Deletes the store directory **and** its `CATALOG.md` row **and** any `MODULES.md`
rows referencing it, together, in one pass — never partially.

### `sync`
Pulls the starter-repo URL recorded in `CATALOG.md`'s header line into the store (see
§10 — this is not yet wired to a real repo). Also runs `check-updates` as a matter of
course, since you're already touching the network.

### `check-updates` — detection, never mutation
Runs `skillctl.sh check-updates`. For every `LOCK.md` row: `git ls-remote` the
source's HEAD (cheap — no object fetch) and compare to the pinned SHA. **Only on a
mismatch** does it pay for a shallow clone (`git clone --depth 1`) to read the new
commit's actual date via `git log -1 --format=%cI`. This means the common case
("nothing changed") stays cheap, and the network cost is paid only when there's
something real to report. Prints, per skill, either `up to date (sha, date)` or
`UPDATE available — ours: sha (date) latest: sha (date)`. Stamps `last-checked` in
`LOCK.md` regardless of outcome. **This verb never modifies a skill.**

This has been tested live against a real repo (`Leonxlnx/taste-skill`) in the session
that built this system — both the "stale ref, diff detected, date correctly enriched"
path and the "current ref, reported up to date, no extra clone" path were verified
against the actual GitHub remote, not simulated.

### `update <skill>` — the safety-critical verb
Full procedure in `references/updates.md`. Never auto-applied; always
`AskUserQuestion`-gated. Steps:
1. Fetch the new upstream ref into a **scratch** directory — never straight over the
   vendored copy.
2. Diff everything **our system depends on**, and report each finding before asking
   to apply:
   - Did the frontmatter `description` widen? (A broader trigger dragnet means more
     mis-fires and picker noise.)
   - Did the skill's **footprint** (which files it reads/writes in a target project)
     change? If so, `add-and-handoff.md` §2a must be updated in the same pass, or
     future conflict/handoff detection silently goes stale.
   - Are our **local-mods** (recorded per-skill in `LOCK.md`, e.g. "set
     disable-model-invocation") still present, or did the upstream update reset them?
     Every local-mod must be **re-applied**, not silently dropped.
   - Did modules change? Update `MODULES.md` rows to match.
   - Does anything new collide with an installed skill? Add a `CONFLICTS.md` rule.
3. **Mandatory project dependency-file reconciliation** (this is the part that
   handles "I'm mid-project and the skill I depend on just changed its expected file
   structure"):
   - Derive the *new* structure the updated skill expects (grep its own templates).
   - Compare to the *old* structure recorded in `add-and-handoff.md` §2b. Unchanged →
     nothing to do for this file.
   - Changed → glob for the skill's footprint file in the live project. Absent → no
     conflict (skill will just create it fresh). **Present** → run
     `scripts/structcheck.sh <project-file> "<new-marker>" ...`, which mechanically
     reports which required markers the existing file is missing. This has been
     tested: a project file with all old markers passes (exit 0); a file missing a
     newly-required marker is correctly flagged (exit 1).
   - On drift, offer a **migration**: back up the file, then transform it toward the
     new structure — filling derivable sections, flagging what can't be inferred,
     never silently discarding the user's real content. This step is inherently
     lossy and semantic (model-driven), unlike the mechanical detection step. The
     user can decline migration; if so, say plainly that the skill may misbehave
     against the stale file.
   - After applying, rewrite the signature in §2b to the new version, so it's correct
     for next time.
4. On apply: replace the vendored copy, re-apply local-mods, re-run `skillctl.sh pin`
   for the new SHA+date, rewrite the `LOCK.md` row, run `validate --skills`.
5. Rollback is inherent: the old pinned-ref is still resolvable via git, so a bad
   update is one re-install away — note the old ref before overwriting.

## 7. The menu picker + Combine protocol

Trigger: a task calls for design judgment (or some other menu skill's domain) *and*
one or more menu-policy skills/modules are installed (dormant menu skills obviously
can't be picked — they have to be loaded first).

- **Asked on every new task**, not once per session. A multi-turn continuation of the
  *same* task reuses the prior choice; a genuinely new task/prompt asks fresh. This
  was a deliberate correction mid-build: the user does substantial work with one skill
  for a major redesign, then wants something lighter for the next minor tweak — a
  session-sticky choice would have been wrong.
- Skipped entirely when the user names a skill/module inline ("use
  impeccable/typeset") or says "no skills."
- Reads `CONFLICTS.md` first: drops any option `exclusive` with something already
  active; presents a `compatible` pair as the recommended **"Combined"** option (see
  below); lets `precedence` rows set which skill's guidance wins on a contested call.
- Presented via `AskUserQuestion`, multi-select on. Order: Combined recommendation
  first (when ≥2 skills genuinely fit) → individual skills/modules (at
  `parent/module` granularity from `MODULES.md`, never "load the whole 28-module
  pack") → "None — pinned + guardrails only" always available as an explicit out.

**Combine protocol**, when the user picks ≥2 things: read only the selected guidance
files (nothing else); where two picks give conflicting instructions, resolve using
`CONFLICTS.md` precedence (default chain: project's own design tokens > the
`anti-slop-preflight` guardrail > best fit for this specific task); where they're
complementary, take the union. If the task is multi-stage, it's fine — and often
better — to assign different skills to different stages (e.g., one module for
structure, a different one for typography) rather than blending both into every
decision; state the stage assignment in one line before starting so it can be vetoed.

## 8. The conflict system

Five rule types in `CONFLICTS.md`, and this is the operative distinction: **evidence
lives in `WIKI.md`, rulings live here.** Don't let these merge back together.

| type | meaning |
|---|---|
| `precedence` | both may be active; the left-named one wins any contested call |
| `exclusive` | never co-load; the user picks one, decided once per project |
| `sequential` | order matters, not exclusion — A runs first (sets up files), then B builds on A's output. Re-loading A restarts A's own flow. This is NOT the same as exclusive — the user explicitly corrected an earlier draft that had mislabeled a sequential relationship as exclusive |
| `compatible` | confirmed to work well together, with the "how" noted if non-obvious |
| `duplicate` | the same capability shipped by two different sources — install exactly one |

Current rulings on file (all user-made, dated 2026-07-04, in this project): project
design tokens beat the guardrail beat any menu skill on a contested call · impeccable
+ taste-skill are compatible and co-load freely (impeccable is the user's primary
pick) · designer-skills is `sequential` into impeccable (a genuine handoff, not
exclusion — designer-skills sets up a new project, then impeccable builds on its
files) · greensock's official gsap-skills wins all gsap tasks over a same-named
duplicate shipped inside another pack (freshtechbro/claudedesignskills) · webgpu and
a conflicting classic-WebGL renderer are exclusive, but this only blocks a *second*
contradicting renderer — loading one 3D skill mid-session is fine, it doesn't have to
wait for a dedicated session · designer-skills and ui-ux-pro-max are kept exclusive
**pending the user actually testing them together** — this is explicitly flagged as
provisional, not a permanent architectural judgment.

`Handoffs` table (below Rules in the same file): for each `sequential` pair, the exact
source-file → target-file mapping and what gets transferred. Currently one row:
designer-skills' `DESIGN_BRIEF.md`/`INFORMATION_ARCHITECTURE.md` → impeccable's
`PRODUCT.md`/`DESIGN.md`. This transfer is explicitly lossy/semantic — the manager
drafts the target files and asks before writing, never silently overwrites an
existing target.

The validator checks `CONFLICTS.md`'s cap (60 non-empty lines) and that every rule
uses one of the five known types — it deliberately does **not** try to parse the
freeform "skills / group" column (it uses ad hoc notation like `⊕`/`›`), because an
earlier attempt at a stricter parser was judged too brittle for the value it added.

## 9. Relationship to the *other* system already in this repo: project memory

This repo also runs a **separate, older system** for token-efficient navigation of
large source files — `project-memory` and `checkpoint` skills, `.claude/memory/`
(INDEX.md + route maps + shared registries), anchor comments (`@sec:`/`@css:`/`@js:`)
in source, and a zero-token Stop-hook nudge for memory staleness. Its own handoff doc
is `.claude/skills/project-memory/PROJECT-MEMORY-SYSTEM-HANDOFF.md` (with the
chronological build log in `.claude/skills/skill-manager/SKILL-DEVELOPMENT-LOG.md`) —
read those separately if you need to work
on navigation/memory, not this system.

The two systems share infrastructure but stay conceptually separate:
- Both `project-memory` and `checkpoint` are `pinned` **rows in this system's
  `CATALOG.md`** — the skill-manager treats them as core, permanently-active
  infrastructure, but does not manage their internal behavior.
- `scripts/validate.mjs` and `scripts/checkpoint-nudge.sh` are shared files —
  `--memory` mode and the checkpoint-staleness nudge belong to the memory system;
  `--skills` mode and the loadout-drift/update-staleness nudges belong to this one.
  They're appended to the same files rather than duplicated, but each mode is
  independent and doesn't depend on the other's internals.
- The `anti-slop-preflight` guardrail's "Project style lock" section is a short,
  always-resident summary that must be mirrored from (and never override) the
  project's shared design file under `.claude/memory/shared/` (registered in
  INDEX.md's Shared registries). In the starter repo the lock starts empty — each
  project records its own decisions as they're made.

## 10. Known gaps — do not assume these are finished

Be honest about these with the user; don't quietly "complete" them without asking,
since some involve judgment calls only the user has made so far for *this* project.

- **No starter repo exists yet.** `CATALOG.md`'s header line says so explicitly:
  `starter-repo: (not yet created — put its git URL here...)`. `sync` is a no-op
  until one exists. The Upstream candidates table in `CATALOG.md` is effectively the
  shopping list for what that repo should eventually contain.
- **`LOCK.md` is empty.** No third-party skill has actually been vendored into this
  project yet — everything researched so far (impeccable, taste-skill, designer-
  skills, etc.) is documented in `WIKI.md`/`CATALOG.md`'s candidates table but not
  installed. The `add`/`pin`/`check-updates`/`update` machinery has been tested
  mechanically and once against a real remote, but not yet exercised end-to-end on a
  real installed skill in this repo.
- **Structure signatures in `add-and-handoff.md` §2b are provisional.** They were
  derived from research (reading the skills' own repos), not captured at actual
  vendor-time from the skill's own templates as the protocol requires going forward.
  The first real `add` of impeccable/designer-skills/ui-ux-pro-max should replace
  these with authoritative signatures.
- **designer-skills ⊕ ui-ux-pro-max exclusivity is explicitly a placeholder** — kept
  exclusive only because the user hasn't tested them together yet, not because
  they're proven incompatible. Revisit this rule once tested.
- **The `quieter` incident is worth reading in full history** if you're ever tempted
  to add "general wisdom" from a design skill into the ride-along guardrail. A
  correction was needed once already: `quieter` is one pole of a directional dial
  (quieter ↔ bolder), and baking its content into an always-on guardrail would
  silently bias every design toward restraint. The surviving guardrail content
  (`polish`-derived "Stay on-system — fidelity") was re-checked against the same
  test and kept only because it's genuinely direction-agnostic. Apply that same test
  to anything you're tempted to add: *does this enforce consistency, or does it push
  toward a particular aesthetic?* Only the former belongs in a ride-along.

## 11. Quick-start checklist for a genuinely new environment

1. Read `.claude/skills-store/CATALOG.md` first — it's the map of everything
   installed and everything candidate.
2. If the user asks "what skills do I have" — run `skillctl.sh status`, then read
   session context for fixed skills, then check `MODULES.md` for anything they might
   want that's one level deeper than a whole skill.
3. If the user wants a capability not yet in the store — check the Upstream
   candidates table in `CATALOG.md` first (14 skills already researched, in
   `WIKI.md`, with known conflicts already mapped) before searching from scratch.
4. Never hand-move a directory between `.claude/skills/` and
   `.claude/skills-store/`. Always go through `skillctl.sh`.
5. Never skip `node scripts/validate.mjs --skills` after any catalog/module/conflict/
   lock edit. It is cheap and it catches real drift (tested adversarially multiple
   times during this system's construction: duplicate rows, orphaned modules,
   skills present on both shelves at once, unknown conflict-rule types, core
   infrastructure missing its pinned row).
6. If in doubt about whether something is a universal principle or a directional
   style choice, re-read §10's `quieter` note before adding it anywhere near the
   ride-along tier.
