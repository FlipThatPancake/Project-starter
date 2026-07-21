# System audit — 2026-07-19 · full meta-surface scan (mode 1)

**Scope:** every live file in `.claude/**`, `scripts/**`, `tests/**`, `CLAUDE.md`, `README.md`,
`src/` scaffolding — scanned for redundancies, naming/hook/instruction conflicts, zombie
commands/files, gaps, bugs, dead-ends. Mechanical claims below were verified live (hook
invocations with synthetic payloads, script runs), not inferred. `test-tooling.mjs` all
passing and `validate --all` clean at audit time — every finding is in the layer those
checks don't cover.

## A. Confirmed bugs (mechanical, reproduced live)

**A1 — Route-lock format mismatch breaks enforcement (HIGH).** Mode 3, mode 4,
project-memory SKILL §1, and PROJECT-MEMORY-SYSTEM-HANDOFF §7 all document the lock as
`echo "/<route>" > /tmp/claude-route-scope-$H` (leading slash). Both consumers —
`scope-guard-hook.sh` (`ROUTE_DIR="src/routes/$LOCKED_ROUTE"`) and `ship.sh` F4 — then
build `src/routes//pricing/` (double slash), which never matches a real path. Reproduced:
with the documented lock, an **in-route** edit to `src/routes/pricing/index.html` is
DENIED (exit 2, "blocked outside locked route '/pricing'. Only edits to
src/routes//pricing/**…"); with a slash-less lock it passes. Net effect on a real
multi-route project: modes 3/4 survive Edit/Write only because the mode allowlist
supersedes, but ship.sh F4 flags every staged file (including in-route ones) as a
cross-route violation → every ship on a locked route fails without `@allow-cross-route`.
Fix either the docs (drop the slash) or the consumers (strip a leading `/`); consumers
stripping is safer (accepts both).

**A2 — `/skills list` doesn't exist (MEDIUM).** `.claude/commands/skills.md` ("(no args)
or `list` / `status`"), skill-curator SKILL.md ("`/skills list|load|unload|remove`"), and
README's table all advertise `list`; `skillctl.sh` has no `list` verb — `bash
scripts/skillctl.sh list` exits 2 with usage. Add `list` as an alias of `status` (one
case-pattern) or fix three docs.

**A3 — Three surfaces disagree on `.claude/**` writability (MEDIUM).**
MODES_PROTOCOL §scope-model: "`.claude/**` is always writable (memory maps, logs, skill
activation, cataloguing)". scope-guard-hook.sh: only `.claude/memory/**` is always
writable. ship.sh F4: allows all of `^\.claude/`. Reproduced: in a mode-4 allowlist, a
Write to `.claude/skills-store/skill-storage/<new>/SKILL.md` is DENIED — so the
repeatedly-stated rule that install/catalog is "available in ANY mode" (MODES_PROTOCOL
scope note, skill-curator Hard rules, mode 7) is mechanically false for tool-based
writes; it only works via Bash `cp` (which the hook can't see). Pick one truth — likely
widen the hook to `^\.claude/` to match MODES_PROTOCOL + ship.sh.

**A4 — scope-guard's `@allow-cross-route` override is a dead-end (MEDIUM).** The hook's
denial message says to put `@allow-cross-route` "in your next prompt … to override", and
project-memory §1 claims "both the Edit/Write hook and ship-time gate check for it" —
but the hook never sees prompts and has no override branch; only ship.sh checks the
commit message. The only real Edit/Write escape is editing the mode allowlist. Fix the
two texts (hook message + project-memory §1) to describe the real path.

**A5 — Known upstream bug shipped unfixed in store `session-log` (LOW, sleeping).**
WIKI.md §11 documents the casing bug (prose `YYYY-wWW Agent Log.md` vs code
`${WEEK} agent-log.md` — forks the weekly log on Linux) and says "fix the casing in our
copy before use". Our vendored copy retains both lines verbatim (SKILL.md:15 vs :56) and
LOCK.md records `local-mods: none`. Fix the copy + record the local-mod, per our own rule.

**A6 — Zombie/ineffective settings.json keys (LOW).** (a) `disabledMcpjsonServers`
governs project `.mcp.json` servers — this repo has no `.mcp.json`, so it's a no-op; the
entries also use tool-prefix names (`mcp__Figma`) rather than server names, and the named
servers were demonstrably live this session. (b) `skillOverrides` is not a settings key I
can match to any documented harness behavior — likely inert. Either wire these correctly
or delete them so the file stops implying protections it doesn't provide.

**A7 — `CLAUDE_AUTO_PUSH_TO_MAIN` name/comment contradicts behavior (LOW).** ship.sh:
`AUTO_PUSH != true` skips ALL pushes. But the var name says "to main", and ship.sh's own
comment says setting false means "push only the current branch, never to main" — wrong on
both counts: `true` doesn't push main either (only `--to-main` does), `false` pushes
nothing. Rename (e.g. `CLAUDE_AUTO_PUSH`) or rewrite the comments.

## B. Instruction conflicts & redundancies

**B1 — README bootstrap step 1 teaches the retired `profile:` flag (HIGH for a starter
repo).** "Set `profile:` in `.claude/memory/INDEX.md` — `portal` … or `standalone`" —
that flag was removed (mode 2: "no standalone/portal flag anymore"; project-memory §0:
route COUNT is the only driver). Following the README produces an INDEX that
`validate.mjs --memory` hard-fails (`missing "state: starter|in-progress"`). README also:
places anti-slop-preflight in `.claude/skills/` (it's dormant in the store), describes
settings.json as wiring only the Stop hook (three hooks are wired), and its Daily-flow
omits mode selection entirely. The README predates the mode/v3 work and was never swept.

**B2 — PROJECT-MEMORY-SYSTEM-HANDOFF.md is the biggest staleness hotspot.** Billed as
"complete reference for a fresh session in a different environment", but: §5/§6/§9
describe the `profile:` line as current (validator checks `state:`); §15 step 2 tells a
new project to create INDEX "with a `profile:` line" → fails validation; §7 describes the
ship gate as post-commit ("diffs HEAD~1 … refuses to push") — it's now the pre-commit F4
staged-files gate; §11's flag list omits `--force-push`/`--to-main`. The project-memory
SKILL frontmatter also still says "(portal profile)". A doc that teaches a fresh clone a
shape the validator rejects is worse than no doc.

**B3 — CLAUDE.md "push to main unless told otherwise" vs ship-now.** ship-now's resolved
default is the opposite: no destination named → target = branch, main only via PR. The
harness also forbids pushing anywhere but the designated branch. CLAUDE.md's Batch-commits
row should say "push to the session branch".

**B4 — Curation references still point at retired filenames.** Live (non-archive) files:
WIKI.md ("rulings … live in `CONFLICTS.md` (single source of truth)", "our MODULES.md");
add-and-handoff.md §1 ("MODULES.md" ×2, "per CONFLICTS/CATALOG notes"), §3b ("CONFLICTS
`sequential` row"), §4 ("CONFLICTS.md Handoffs table"); updates.md ("MODULES.md rows",
"CONFLICTS rule"); conflict-rulings.md itself ("install-policy → CATALOG", "CATALOG
rows"); module-index.md ("see CATALOG Installed"). Real names: `conflict-rulings.md`,
`module-index.md`; CATALOG is gone. Each is a wrong turn for the model mid-install.

**B5 — conflict-rulings.md violates its own inclusion rule.** The machine-parseable
exclusive group `designer-skills, ui-ux-pro-max` sits under a header stating a group
appears "ONLY once every member's name matches a real installed skill" — neither is in
the store (they were installed only in the deleted live-test worktree). Also the first
precedence rule references `design-m3` — the prior project's design system, meaningless
in the starter. `check-conflicts` handles the absent footprints gracefully (verified),
so this is doc-integrity, not breakage.

**B6 — Checkpoint commit convention vs mode prefix, unstated.** checkpoint SKILL:
`chore(memory): checkpoint <routes>`; CLAUDE.md: prefix EVERY commit `[mode:…]`.
Combined form works (nudge greps substring — verified pattern), but neither doc mentions
the other; a literal reader picks one.

## C. Zombies / dead surface

- **`_skeleton` anchor dup by design:** `_skeleton/index.html` names its route-local style
  anchor `@css:tokens`, same as `src/shared/tokens.css`'s anchor — after `@inline`, dist
  contains the anchor twice (validate only lints src, so it's silent). Rename the
  skeleton's to `@css:route-local` or similar. Related inconsistency: `validate --all`
  lints `_skeleton/index.html` but `build --all` skips `_*` — two definitions of "the
  route set".
- **checkpoint-nudge comment ≠ code:** claims it "skips the active copy … whose store
  master already covers the name (shadowing)"; the loop has no skip (harmless today —
  both copies carry the same frontmatter).
- **Agent-log archives are fine** (banner'd historical), but mode 1's read-set names
  `SKILL-MANAGER-HANDOFF.md` as orientation material without noting it's superseded.

## D. Gaps

- **D1 — Zero test coverage for the bash layer.** test-tooling.mjs covers only
  validate.mjs/build.mjs. scope-guard-hook.sh, ship.sh (F4 gate, gitlink guard,
  --to-main), checkpoint-nudge.sh, skillctl.sh, session-start-hook.sh are untested —
  A1 and A3 live exactly there and would have been caught by a 10-line payload-pipe test.
  Highest-leverage fix in this audit: a `tests/hooks` suite piping synthetic JSON into
  scope-guard and running ship.sh F4 against a fixture repo.
- **D2 — scope-guard hard-depends on jq, no fallback.** Under `set -e`, a missing jq
  makes the hook error (non-2 exit) → fails open silently. session-start-hook has a jq
  fallback; the *enforcement* hook — where fail-open matters — doesn't.
- **D3 — Starter repo nudges forever.** No `chore(memory): checkpoint` commit exists, so
  the nudge baseline is the root commit; on the mother repo the Stop hook recommends
  /checkpoint hourly, permanently (verified: fires with "66 source files changed…").
  Consider suppressing when `state: starter`.
- **D4 — SESSION-LOG hygiene:** "newest first" is violated (07-16 rows below 07-14);
  header says "keep last 20" rows while the validator caps 40 lines — compatible today,
  two units of measure tomorrow.

## Follow-up (same day, user-ruled)

Fixed in the follow-up commit: **A7 deleted** (CLAUDE_AUTO_PUSH_TO_MAIN ruled legacy —
env var removed from settings.json, `--force-push` flag + AUTO_PUSH logic removed from
ship.sh, ship-now updated to plain `ship.sh "<msg>"`); **B3 fixed** (CLAUDE.md's "push to
main unless told otherwise" replaced — ship-now is the only ship-to-git mechanism);
**B4 fixed** (all retired CONFLICTS.md/MODULES.md/CATALOG pointers in WIKI,
add-and-handoff, updates, conflict-rulings, module-index replaced with current names;
historical v3 banners left as-is); **C-anchor-dup fixed** (`_skeleton`'s route-local
anchor renamed `@css:route-styles`; `@css:tokens` now belongs to shared tokens.css
alone). Still open: A1–A6, B1, B2, B5, B6, D1–D4.

## Follow-up 2 (2026-07-19/20, user-ruled) — remediation round

- **A1 fixed**: scope-guard-hook.sh and ship.sh F4 now strip a leading `/` from the
  route lock, so the documented `echo "/<route>"` format works everywhere.
- **A2 fixed**: `skillctl.sh list` added as an alias of `status`.
- **A3 fixed** (user ruling: always writable): scope-guard now exempts all of
  `.claude/**`, matching MODES_PROTOCOL and ship's gate — one truth across all three.
- **A4 fixed** (block KEPT per recommendation — zero token cost): both hook denial
  messages now state the real escape (re-scope / widen the mode allowlist) instead of
  the nonexistent prompt override; project-memory §1 and HANDOFF §7 corrected to match.
- **A5 fixed**: session-log casing unified on `agent-log.md`; LOCK.md local-mods row
  records the fix.
- **A6 fixed**: dead `disabledMcpjsonServers` + `skillOverrides` keys deleted.
- **B1/B2 fixed**: README bootstrap + HANDOFF doc fully swept to `state:`/route-count
  model; ship-gate description corrected to pre-commit; flag lists updated.
- **B5 re-ruled** (user, 2026-07-19): exclusive-group rows MAY name not-yet-vendored
  skills (inert until installed); the warn only fires when a load would make two peers
  simultaneously ACTIVE. Header rewritten; `design-m3` precedence row left (harmless
  house-rule example).
- **D1 fixed**: test-tooling.mjs extended with 15 bash-layer cases (scope-guard payload
  pipes, ship F4 + template filter in temp git repos, skillctl round-trip, nudge
  suppression). First run immediately caught a latent `skillctl status` crash on an
  empty active dir — fixed (glob guard).
- **D3 fixed**: checkpoint-nudge suppresses the volume nudge when `state: starter`.
## Follow-up 3 (2026-07-20, opus) — final cleanups; all findings now closed

- **B6 fixed**: checkpoint SKILL step 3 now shows the combined message
  `[mode:…] chore(memory): checkpoint <routes>` and explains why both coexist (the nudge
  greps the substring via `git log --grep`, so the mode prefix is harmless). Verified the
  grep still matches.
- **D2 fixed**: scope-guard-hook.sh no longer hard-depends on jq. If jq is absent it uses
  a sed-based fallback extractor for the flat string fields; if even that yields no tool
  name on a payload that clearly names one, it fails CLOSED (exit 2) instead of the old
  fail-OPEN abort. Verified live with jq hidden from PATH: in-route → 0, out-of-route → 2.
- **D4 fixed**: SESSION-LOG rows reordered strictly newest-first (07-14 and 07-10 were
  misplaced); row content preserved byte-for-byte. Header's "keep last 20" reconciled to
  the validator's real 40-non-empty-line cap.
- **C-item fixed**: mode-1 read-set now flags `agent-log/*HANDOFF*` +
  `SKILL-DEVELOPMENT-LOG.md` as historical/superseded (read for the *why*, not as spec),
  while still naming the live `PROJECT-MEMORY-SYSTEM-HANDOFF.md` as current.

Every finding A1–A7, B1–B6, C, D1–D4 is now resolved or explicitly re-ruled. Bash-layer
regression coverage added so A1/A3-class drift can't recur silently.

## Follow-up 4 (2026-07-20, opus) — close the D2 test-coverage gap

The D2 jq-fallback was verified live but had no automated guard (a PATH-stripping test
is brittle — breaks the moment the script uses a new coreutil). Added a documented test
seam instead: `SCOPE_GUARD_NO_JQ=1` forces the fallback branch, so the suite exercises it
with zero PATH surgery. Three new cases (29 total): fallback allows in-route, blocks
out-of-route, and fails CLOSED on an unparseable guarded payload. Negative-control
checked — neutering the fail-closed guard makes the test fail, proving it has teeth.
No known defects or coverage gaps remain in the audited surface.

## Verdict

The Node layer (validator/builder/tests) is tight and all-green. The decay is
concentrated in (1) bash enforcement scripts whose contracts drifted from the docs with
no tests to catch it (A1/A3/A4), and (2) prose that survived three redesigns unswept
(B1/B2/B4). Nothing found contradicts the architecture itself; every fix above is local.
