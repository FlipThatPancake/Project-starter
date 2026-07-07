# Live system test — 2026-07-07 · full-session simulation report

**Session:** `claude/system-testing-zev0ad` (mode 7-other) · **Method:** a subagent in an
isolated git worktree played out a complete scripted Mode-2 (new-project) session — a
product-designer portfolio ("Maya Chen") — across 8 user turns, obeying every repo rule as
written and journaling all friction. Evidence: journal (`2026-07-07-test-journal.md`, same
dir), worktree `\.claude/worktrees/agent-ab5f19ad3e4987c95` (branch
`worktree-agent-ab5f19ad3e4987c95`, 2 commits, never pushed).

## Verdict

**The system works end-to-end.** All 8 turns completed: mode inference → lock → skill GATE →
4 upstream installs + 5 loads → grilling (cut at 5 questions as instructed) →
designer-skills kickoff → build via scripts → gsap-core motion → scope-creep correctly
deflected → /checkpoint → `ship.sh --no-push`. Zero pushes, zero unrecoverable failures,
validators clean at ship. Output quality was high (anchored sections, OKLCH tokens,
reduced-motion honored, self-contained 82.5KB dist).

**But ~40% of the session's token budget went to overhead the system itself caused** —
re-reading protocol files, and reading tool *source code* to learn formats the docs don't
state. And one environmental root cause invalidated the first ten minutes: see F0.

## Token accounting

Subagent total: **164,512 tokens · 72 tool calls · 21.2 min.**

| bucket | approx volume | notes |
|---|---|---|
| protocol/skill reads | ~1,000 lines | skill-manager SKILL.md 150 + modes README 107 + gate metadata 125 + checkpoint refs 145 + gsap-core 254 + impeccable 140 + anti-slop 57 + grilling 15 |
| tool source read *only to learn undocumented formats/flags* | ~660 lines | validate.mjs 286, skillctl.sh 153, ship.sh 150, build.mjs 68 — pure documentation debt |
| actual product work | ~280 written lines | index.html + tokens + memory — the cheap part |
| test overhead (journal) | ~250 lines | not system cost |

Wins: the 1,207-line taste-skill was consumed via grep (~40 lines) thanks to the
distill-into-checklist pattern — that design demonstrably pays. Grilling early-cutoff worked
cleanly (5 questions, no runaway).

## Defects, ranked

**F0 — `main` does not contain the system (root cause; found in orchestrator verification).**
Local *and* origin `main` sit at `8a2f0b6` ("Add files via upload"): **zero `.claude/` files,
old CLAUDE.md, old scripts**. Every mode-1 session's work (modes, skills, store, memory,
current ship/validate) lives only on side branches — the PR #2/#3 merge commits are in this
branch's ancestry but `main` was never advanced. Consequences observed live: the agent's
worktree (based on main) booted with NO session system — it had to hand-copy
`.claude/{skills,skills-store,modes}` + scripts from the parent before any rule could run;
mid-session the stale validate.mjs produced false failures; two divergent CLAUDE.md files
were simultaneously in play. **Any fresh clone or worktree of this repo today boots without
the system it documents.** Fix: merge the system to `main` (ship-now PR path) — highest
priority, invalidates half of friction below once done.

**F1 — Load-scope contradiction (predicted pre-test, confirmed live).**
`modes/README.md`: loading into `.claude/skills/**` "requires mode 1" vs skill-manager's
Mode-entry GATE that exists to load skills "in EVERY mode". The agent resolved it sensibly
(GATE + user confirmation = the sanctioned load path; mode-1 restriction = ad-hoc edits
outside the GATE) but had to improvise a ruling mid-boot. Also: SKILL.md says mechanics run
in `scripts/skillctl.sh` — actual path is `.claude/skills/skill-manager/scripts/skillctl.sh`;
first invocation exited 127. Fix: one clarifying sentence in both files + correct the path.

**F2 — Design-skill pile-up needs a referee.** Three live collisions, each resolved only by
judgment: (a) anti-slop-preflight line 43 declares prefers-reduced-motion "a permanent,
standing override" (motion plays regardless of OS setting) vs impeccable's "reduced motion is
not optional" vs the user's explicit requirement — if that line is a deliberately planted
trap, the agent passed (style lock + user outrank checklist, ruling recorded in the lock); if
not, it's a real defect to delete; (b) impeccable's `palette.mjs` hands a *random* seed hue
(got 356.8 pink) with "anchor within ±10°" language and no "user brief wins" escape hatch —
agent overrode with the grilled terracotta; (c) impeccable's brand.md reflex-rejects the
editorial/display-serif lane the user explicitly chose. Precedence exists (style lock >
checklist > task fit) but each case still burned a judgment call. Fix: add an explicit
top-of-chain rule everywhere: *explicit user decisions outrank every skill heuristic, seed,
and checklist line*.

**F3 — Route-map shape is only discoverable at /checkpoint time.** The map written during the
build turn passed `validate --memory` yet had the wrong shape (extra column, missing
`uses:`/Hot elements/Priorities) and needed a full rewrite at checkpoint — the canonical
format lives only in checkpoint's references. Fix: either validate enforces the real column
set, or the mode-2/3 files link map-format.md at map-creation time.

**F4 — Duplicated mechanisms with undocumented interplay.** (a) Two SESSION-LOG homes
(mother repo vs project memory) — the session wrote both, docs never say which one a
child/worktree session owns. (b) Two /tmp locks: `claude-mode-$H` (mode allowlist) vs
`claude-scope-$H` (route lock, read only by ship.sh) — near-identical names, no
cross-reference, and **ship.sh's cross-route gate runs only on the push path, so `--no-push`
commits are silently ungated**. Fix: document ownership; move the scope gate before commit.

**F5 — The `add` flow doesn't scale past one skill.** Installing 4 upstream skills per the
spec means ~8 AskUserQuestion rounds (policy + category each) plus a mode-fit confirmation
mid-turn; the agent batched decisions from CATALOG's own upstream annotations instead
(reasonable, but a documented batch path should exist: "user named N skills inline → derive
policy from catalog annotations, confirm once"). Related: impeccable ships 13 duplicate
SKILL.md copies (picking one is undocumented convention); taste-skill's frontmatter name
(`design-taste-frontend`) differs from its dir/catalog name (`taste-skill`) — latent identity
mismatch between skillctl (dir-keyed) and the harness (frontmatter-keyed).

**F6 — GATE inputs mis-tuned for the most common case.** MODE-SHORTLISTS row 2 (new-project)
omits all visual-quality skills even though bootstrapping is usually visual — every such
session must manually broaden into rows 3/6. And the full-catalog table (19 store + 15
upstream rows) is a genuinely heavy first message. Fix: add anti-slop-preflight (+ the
design-judgment pair) to row 2; consider a compact rendering for the "everything else" half.

**F7 — Pack-member seam.** The literal request "scroll-triggered reveal" belongs to
gsap-scrolltrigger per gsap-core's own doc, but only gsap-core was authorized and there's no
lightweight mid-session "add one more member" path. The agent's workaround
(IntersectionObserver + core tweens, sanctioned by anti-slop) was arguably better
engineering, but the seam is real. Fix: a one-question fast path for adding a sibling pack
member already covered by an existing LOCK row.

**F8 — Minor.** (a) Nothing warns about a skill's raw size before loading (taste-skill: 1,207
lines) — a `size` column in CATALOG would let the GATE flag it. (b) A vendored 72KB gsap blob
now lives in `src/routes/home/` — built-file-hazard covers dist/, nothing covers vendored
blobs in src/; add them to the never-whole-file-Read rule. (c) unpkg.com is proxy-blocked
(CONNECT 403); registry.npmjs.org works — worth a note in the env docs. (d) Boot cost ~460
protocol lines before any user-visible work — heavier than README's "~3K orientation" claim.

## What worked as designed (worth keeping)

- **Mode inference + lock + address-don't-act:** informal prompt correctly steered to mode 2;
  landing-page ask acknowledged but nothing executed pre-gate.
- **Skill GATE:** built from shortlist row 2, correctly broadened, check-conflicts run,
  waited for confirmation; inline-named skills honored directly per spec.
- **Conflicts machinery:** designer-skills⊕ui-ux-pro-max exclusivity enforced; sequential
  designer-skills→impeccable handoff (brief seeds PRODUCT.md/DESIGN.md) followed from
  CONFLICTS' Handoffs table; menu copies muted via disable-model-invocation; LOCK pinned.
- **Grilling with cutoff:** announced itself, one question at a time, stopped at 5, artifacts
  (brief + CONTEXT.md ADR) written with announced writes.
- **Scope-creep defense (turn 6):** blog+CMS correctly deflected to a fresh session, conflict
  with ADR-001 flagged, pending decision recorded — no code touched. Exactly the intended
  behavior, though the "where to log a deferral" path was improvised (CONTEXT.md).
- **Anchor navigation + scripts:** all sections anchored, validators/build used exclusively
  (no inline node -e), dist never read.
- **ship.sh `--no-push`:** full pipeline ran (scoped validate → rebuild → commit), nothing
  left the machine, `--to-main`/`--force-push` untouched.

## Recommended action order

1. **Merge the system to `main`** (F0) — everything else assumes this.
2. One-sentence fixes: load-scope clarification + skillctl path (F1), user-decision-outranks-
   heuristics rule (F2), map-format link in mode files or stricter validate (F3).
3. Decide anti-slop line 43's fate — trap (document it as such) or bug (delete it) (F2a).
4. ship.sh: run scope gate pre-commit, not pre-push (F4); document SESSION-LOG ownership.
5. skill-manager: batch-add fast path + pack-member fast path (F5/F7); CATALOG `size` column
   (F8a); MODE-SHORTLISTS row 2 additions (F6).
6. Env docs: npm-registry-not-unpkg note; src-vendored-blob read discipline (F8).
