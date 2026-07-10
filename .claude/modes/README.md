# SESSION MODES — pick one at session start, before any code read

Every session runs in exactly ONE mode. A mode bundles three things so Claude
reads only what's relevant and never wanders:

- **allowlist** — paths the scope-guard (`scripts/scope-guard-hook.sh`) permits Edit/Write on
- **read-set** — the few files to orient from
- **guardrails** — mode-specific rules

**One scope model (applies to every mode — the single source of truth is
`scope-guard-hook.sh`; this only describes it):**
- **Write** is gated. The mode allowlist (`/tmp/claude-mode-$H`, written at lock)
  lists the path prefixes Edit/Write may touch; `.claude/**` is always writable
  (memory maps, logs, skill activation, cataloguing). A lone `*` allows all
  (mode 2). Editing the *mechanics* themselves — `.claude/modes/**`, the hooks,
  `scripts/skillctl.sh`, `skill-curator`'s own SKILL.md — is Mode 1's job; other
  modes simply don't touch them, but that's guardrail discipline, not a separate lock.
- **Read** is NOT gated (the hook guards only Edit/Write). Token discipline comes
  from **lazy reading**, not walls: read only what the current step needs. At
  session start read ONLY the mode file + `.claude/memory/INDEX.md`. Do not read
  `skills-store/*`, `skill-curator`'s SKILL.md, or narrative docs unless you are
  actually acting on skills — the skill index is injected free by the
  session-start hook, so you never read a catalog to know what exists.

## Selection protocol (run this first, every session)

1. **Determine repo state** — read the `state:` line in `.claude/memory/INDEX.md`:
   - `starter` → fresh/unbootstrapped (the mother `Project-starter` repo is always `starter`). Steer toward **mode 2 (new project)**.
   - `in-progress` → a real project (set the first time mode 2 runs). Offer modes 3–6.
2. **Pick the mode:**
   - **Restate the session's purpose in one line first.** If the first prompt is
     explicit and unambiguous, state your understanding + the inferred mode and
     proceed (e.g. "switch to /pricing" → mode 4; "let's build the design tokens"
     → mode 6; "fix the skillctl.sh load bug" → mode 1).
   - **In EVERY other case — including an empty, vague, or multi-intent prompt —
     restate your understanding and WAIT for the user's confirmation before
     locking a mode.** Never assume. Use `AskUserQuestion` with the 7 modes as
     options; keep asking scoped follow-ups until scope is unambiguous.
   - **Scope note:** loading/unloading a skill and curating (install/update/
     extract/delete) a new one are available in ANY mode (`/skills load <name>`;
     the store is the shared library, activation is local and gitignored). Only
     editing the *mechanics* — hooks, `scripts/skillctl.sh`, mode files,
     skill-curator's own SKILL.md — is Mode 1's job.
3. **Lock the mode** — write its allowlist so the scope-guard enforces it:
   ```
   H=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
   printf '%s\n' <allowlist prefixes from the mode file> > /tmp/claude-mode-$H
   ```
   (`.claude/memory/` is always allowed implicitly; no need to list it.)
   State one line: `Mode: <n>-<name>`.
4. **Skills are opt-in — no mandatory gate.** The session-start hook already
   injected the skill index (active + dormant, with sizes) into context for
   free, so you know what exists without reading anything. Load a dormant skill
   only when the task actually needs it, or the user asks, or you want a
   suggestion — `.claude/skills-store/MODE-SHORTLISTS.md` lists per-mode picks
   if you choose to consult it. To load: `/skills load <name>` (thin mechanics —
   copies from the store; reading skill-curator's SKILL.md is needed ONLY to
   install/update/extract/delete a skill). Do not print the whole catalogue or
   block the session waiting for a skill decision.
5. **Make the mode explicit** (§Branch & log below) — this is the persistent
   record of what each session/branch was scoping on.
6. **Read the mode file** (`.claude/modes/<n>-*.md`) and follow it.

**Sequencing — address, don't act:** You may and should acknowledge the substance of
the user's literal request as soon as you understand it (e.g. "that already exists —
here's its state" / "that'll mean touching X"). But hold off **executing** any change
toward it until step 3 (mode locked) is done. Acknowledging is not acting — don't let
it slide into starting the task early. (Skills are opt-in now, so there is no gate to
resolve first — load one lazily if and when the work needs it.)

## Branch & log — making the mode explicit outside the conversation

Two mechanisms, because branch naming is only sometimes in Claude's control:

**A. Branch name (only when Claude creates the branch itself).** Most sessions
(Claude Code on the web) are handed an already-created, harness-tracked branch
BEFORE the mode is known — the branch name is fixed before step 2 above runs, so
it cannot embed the mode, and renaming a pushed harness-tracked branch mid-session
risks breaking that tracking. **Never rename a branch you were handed.** Only when
Claude is the one creating a new branch from scratch (e.g. `git checkout -b`,
no pre-assigned branch) does it name it `<mode-slug>/<short-desc>`, e.g.
`system-dev/skill-loadout-fix`, `new-route/pricing-page`. Mode slugs match the
mode filenames minus the number: `system-dev · new-project · new-route ·
continue-route · backend-routing · design-system · other`.

**B. `.claude/memory/SESSION-LOG.md` (always, every session)** — the reliable,
harness-independent record. On mode lock (step 3), append one row:
`| <date> | <branch> | <mode> | <one-line scope> |`. This is what answers
"what was session X actually scoping on" after the fact, regardless of what
the branch happened to be named.

**C. Commit message prefix (always, every `ship.sh`/commit this session).**
Prefix the first line with `[mode:<n>-<slug>]`, e.g. `[mode:1-system-dev] add
session-mode selection system`. Cheap, permanent, greppable in `git log`.

## The 7 modes
| # | file | one-liner |
|---|---|---|
| 1 | `1-system-dev.md` | modify/test/debug the starter + skill system itself |
| 2 | `2-new-project.md` | bootstrap a fresh project: decide structure & stack |
| 3 | `3-new-route.md` | scaffold + build one new route |
| 4 | `4-continue-route.md` | resume an existing route |
| 5 | `5-backend-routing.md` | routing / page structure (cross-route) |
| 6 | `6-design-system.md` | shared design system & shared files |
| 7 | `7-other.md` | anything else — ask the user to define scope |

## Hard rule (applies to every mode)
No explicit instruction ⇒ **no assumption ⇒ ask.** Prefer one scoped
`AskUserQuestion` over guessing which files, which stack, or which route.
