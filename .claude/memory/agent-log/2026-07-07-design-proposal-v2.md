# Design Proposal v2 — session system slimming & skill-manager redesign

**Provenance:** distilled from the 2026-07-07 live system test (`2026-07-07-live-system-test.md`,
findings F0–F9) plus the follow-up design discussion with the user. This is the **brief for a
mode-1 (system-dev) session** to implement. Nothing here was implemented in the test session
(mode 7). Decisions marked **[DECIDED]** are user-confirmed; **[OPEN]** needs a user call.

---

## IMPLEMENTATION STATUS — all items shipped (mode 1, 2026-07)

Implemented across commits `b5a920d` (B6/F9/F4/lock-rename) · `f422397` (B3/B4 metadata
+ validator) · `33a5385` (B1/B2/B5/F1/F5/F7 lazy opt-in gate + thin mechanics) · `5b6b0cd`
(F3/F2/F8 + doctrine banners). Verified end-to-end: full `validate --all` clean; skill
load→copy→gitignored→unload lifecycle; hook emits opt-in index; gitlink guard + pre-commit
scope gate live. F0 struck (false alarm — origin/main already had the system). F6 declined
by user (row 2 unchanged). Part C resolved by unifying the scope model in modes/README.
Not touched (out of scope / historical): WIKI.md and the project-memory handoff retain
incidental old-name mentions; upstream skills (impeccable etc.) are still not installed, so
their per-skill exclusive-with frontmatter lands only when they're actually added.

## Part A — Confirmed defect fixes (corrected F-list)

**F0 — STRUCK (false alarm).** Earlier claim "main lacks the .claude system" was wrong — it came
from a stale *local* `main` ref. `origin/main` already has the full system (merged via PR #3,
2026-07-08). No action. Lesson for future analysis: `git fetch` before judging a remote branch.

**F1 — Load-scope contradiction + wrong path. [DECIDED]**
- Remove Rule A entirely: `.claude/modes/README.md`'s "loading a skill requires mode 1." The
  every-mode GATE (Rule B) is the one that stands. (Ad-hoc activation is allowed in any mode.)
- Fix `skill-manager/SKILL.md` §Verbs: path is `.claude/skills/skill-manager/scripts/skillctl.sh`,
  not `scripts/skillctl.sh` (first live call exited 127).

**F2 — Motion default + conflict handling. [DECIDED]**
- **Motion is ON by default and overrides skill heuristics; only turned off if the user
  explicitly says so.** So `anti-slop-preflight`'s "prefers-reduced-motion is a standing
  override, motion plays regardless" line is CORRECT and stays. `impeccable`'s "reduced motion
  is not optional" is SUBORDINATE and must be documented as such (or the line softened).
- **General rule:** when a skill heuristic conflicts with an explicit user decision, **surface
  the conflict and let the user choose** — do not silently override in either direction. (The
  test agent silently ruled; the desired behavior is to ask.)

**F3 — Route-map shape enforced by validator. [DECIDED]**
Extend `scripts/validate.mjs --memory` to enforce the canonical column layout from
`checkpoint/references/map-format.md`. Today it checks only headings/caps/anchors, so a
wrong-shaped map validates clean at build time and gets silently rewritten at /checkpoint.

**F4 — Reduced to one fix (dual-log part DROPPED as a test-only artifact).**
- `scripts/ship.sh`: the cross-route scope gate currently sits inside the push path, so
  `--no-push` commits bypass it. Move the check to run **before the commit**.
- Lock-file naming: `/tmp/claude-mode-$H` (mode allowlist) vs `/tmp/claude-scope-$H` (route
  lock) are one keystroke apart. Rename for clarity + cross-reference in each consumer's header.
  (Low priority; see Part B for the broader scope simplification.)

**F5 — Superseded by Part B** (the header-metadata + thin-mechanics redesign replaces the
"three add processes / batch questions" proposal with something cleaner). See below.

**F6 — MODE-SHORTLISTS row 2 additions. [OPEN — needs user confirm per file's own rule]**
Add `anti-slop-preflight` and the `impeccable + taste-skill` pair to the new-project row;
bootstrapping is usually visual work. (Still valid under Part B — shortlists just read lazily.)

**F7 — Pack-member fast path. [DECIDED]**
When a task needs a sibling of an already-loaded pack (e.g. gsap-scrolltrigger when gsap-core
is active, same LOCK source), one yes/no question reusing the existing pin — not a full add.

**F8 — Minor. [DECIDED]**
- Skill `size` (SKILL.md line count) → now a header field (Part B), so the index can warn before
  a 1,200-line load (taste-skill case).
- Built-file-hazard rule (`CLAUDE.md`): extend to vendored minified blobs in `src/` (the 72KB
  gsap blob in `src/routes/home/`), not just `dist/`.
- Env note: unpkg.com is proxy-blocked (CONNECT 403); use registry.npmjs.org for library vendoring.

**F9 — ship.sh gitlink guard. [DECIDED — .gitignore part DONE]**
`.gitignore` now covers `.claude/worktrees/` (done, commit 1ef44ad). Still add: after `git add -A`
in `ship.sh`, abort if any staged entry is a `160000` gitlink — a blocked commit beats a
silently-broken clone.

---

## Part B — Architecture redesign: lazy, distributed skill-manager

Root problem the test exposed: **too much is read eagerly at session start and then lingers in
context unused all session** (context is append-only — nothing "unloads"). The single lever is:
*read nothing until the specific action needs it.* Five coordinated changes:

### B1 — Lazy session start [DECIDED]
Session start reads **only** the mode file + `INDEX.md`. No CATALOG, no CONFLICTS, no
MODE-SHORTLISTS, no skill-manager SKILL.md. Those are skill-only inputs, read only on skill
actions. MODE-SHORTLISTS in particular has exactly one consumer (the gate) and must never be
read on its own at startup.

### B2 — Split skill-manager: thin mechanics vs heavy doctrine [DECIDED]
- **Mechanics** — `/skills list`, `/skills load <name>`, `/skills unload <name>` — a thin
  script. `load` resolves `<name>` → derivable store path
  `.claude/skills-store/skill-storage/<name>/`, copies the dir via bash `cp` (bytes never enter
  context), and reads **only that one skill's header** to check `exclusive-with` against the
  active set. No doctrine file read, no CATALOG read, no sibling reads.
- **Doctrine** — the full SKILL.md (web-install flow, conflict resolution, extract) — read
  **only** for the rare heavy operation of fetching a NEW skill off the web and cataloguing it.

### B3 — Per-skill header metadata; retire CATALOG table + CONFLICTS.md at runtime [DECIDED]
Each skill's SKILL.md frontmatter carries its own: `policy` (pinned/manual/menu/ride-along),
`category`, `size`, and `exclusive-with:` / `precedence` (recorded **symmetrically** on both
members of a pair). Consequences:
- **CONFLICTS.md is deleted as a runtime file.** Activation-time conflict checks are
  self-contained (read the incoming skill's header vs active set). Conflict *rationale/history*
  moves to a rarely-read decisions log (WIKI-type), read only when designing a new rule.
- **CATALOG.md's big hand-maintained table goes away**, replaced by B4's generated index.
- Tradeoff accepted: symmetric conflict facts can drift; the add-flow validates both sides exist.

### B4 — One generated, thin index [DECIDED]
A derived index — one line per skill (`name · category · policy · size`) — auto-regenerated on
every add/remove (never hand-maintained). This is the ONLY browse surface, and the ~10 lines the
SessionStart hook prints for free. Full detail on any skill = read that one skill's header on demand.

### B5 — Opt-in gate instead of mandatory ceremony [DECIDED]
The skill gate is no longer a mandatory session-start ritual. Default off; the hook prints the
B4 index (~10 lines); the user types `/skills` (or names skills inline) to engage. Removes both
the recurring token cost AND the "user must remember the procedure" design smell.

### B6 — Activation never leaks across branches (gitignore negation) [DECIDED]
Root cause: "active" == "dir committed in `.claude/skills/`", so git carries activation across
merges. Fix — commit ONLY the always-on system skills, ignore the rest:
```
.claude/skills/*
!.claude/skills/skill-manager/
!.claude/skills/project-memory/
!.claude/skills/checkpoint/
```
- Pinned/system skills stay committed (intended everywhere — no leak concern).
- Any ad-hoc activated skill lands in `.claude/skills/` locally but is invisible to git → never
  travels to another branch or main. **User: "I never want a skill to persist to other branches
  unless it's a system skill."**
- The store (`.claude/skills-store/`) stays committed = the shared library of what CAN be
  activated. Each session re-activates what it needs from it.
- Promoting a skill to always-on = a deliberate one-line whitelist edit (rare, explicit).

### Net effect
Session start reads mode file + INDEX only · hook prints a 10-line index · `/skills load X`
reads one header + copies · heavy doctrine loads only for web-install · activation is
gitignored scratch that never leaks. Collapses the recurring overhead AND fixes the branch-leak
in one coherent shape.

---

## Part C — Scope/mode simplification (lighter touch) [DECIDED direction]
- Keep the mode system (scope-lock, mode guidance, commit prefix) — cheap and useful.
- Do NOT build a full per-mode read/write matrix. The real bug was **four overlapping
  declarations** of "what can this session touch" (mode allowlist file, route scope-lock, the
  "meta read scope" prose, the mode-1 load restriction) that were never reconciled — that's what
  let F1 slip. Consolidate into ONE declared statement; keep the single cheap `ship.sh` route
  guard with `.claude/memory/**` (and `.claude/skills-store/**` for catalog writes) as standing
  exceptions written once, not assumed in four places.
- Read-scope is prose discipline, not enforced — leave it; token savings come from B1 (lazy
  reads), not from read-scope walls.

---

## Suggested sequencing for the mode-1 session
1. B6 gitignore negation (isolated, high-value, low-risk) + F9 ship.sh gitlink guard.
2. B2+B3+B4 together (they're one mechanism): headers carry metadata → thin mechanics → generated
   index → delete CONFLICTS.md/CATALOG table. Biggest token win.
3. B1 + B5 lazy/opt-in gate (depends on B4's index existing).
4. F1, F2, F3 doc/validator one-liners.
5. F4 ship.sh scope-gate-pre-commit; Part C consolidation.
6. F6 (confirm first), F7, F8 cleanups.

## Open items needing a user decision
- **F6:** confirm the MODE-SHORTLISTS row-2 additions.
- **Part C:** confirm you want the four scope declarations collapsed into one (vs left as-is).
