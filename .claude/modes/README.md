# SESSION MODES — pick one at session start, before any code read

Every session runs in exactly ONE mode. A mode bundles four things so Claude
reads only what's relevant and never wanders:

- **allowlist** — paths the scope-guard (`scripts/scope-guard-hook.sh`) permits Edit/Write on
- **read-set** — the few files to orient from
- **skills** — the loadout offered on entry (via skill-manager)
- **guardrails** — mode-specific rules

**Meta/infrastructure read scope (applies to every mode):** the repo's meta surface —
all of `.claude/**` (including narrative docs like `SKILL-MANAGER-HANDOFF.md` and
`skills-store/WIKI.md`), `scripts/**`, `tests/**`, `CLAUDE.md`, `README.md` — is
**Mode 1's domain**, freely readable there since understanding/changing that surface
IS mode 1's job. **Every other mode (2–7) reads from that surface ONLY the specific
file a running skill-manager verb operationally needs** (e.g. `CATALOG.md` /
`MODE-SHORTLISTS.md` for the entry GATE, a `references/*.md` file while running `add`)
— never to browse or understand the system for its own sake; that curiosity belongs in
mode 1. This is **documented discipline, not mechanically enforced** —
`scope-guard-hook.sh` only gates `Edit`/`Write`, never `Read`/`Grep` — so it relies on
self-policing per this rule, same as the rest of each mode's read-set.

## Selection protocol (run this first, every session)

1. **Determine repo state** — read the `state:` line in `.claude/memory/INDEX.md`:
   - `starter` → fresh/unbootstrapped (the mother `Project-starter` repo is always `starter`). Steer toward **mode 2 (new project)**.
   - `in-progress` → a real project (set the first time mode 2 runs). Offer modes 3–6.
2. **Pick the mode:**
   - **Restate the session's purpose in one line first.** If the first prompt is
     explicit and unambiguous, state your understanding + the inferred mode and
     proceed (e.g. "switch to /pricing" → mode 4; "let's build the design tokens"
     → mode 6; "fix the skill-manager picker" → mode 1).
   - **In EVERY other case — including an empty, vague, or multi-intent prompt —
     restate your understanding and WAIT for the user's confirmation before
     locking a mode.** Never assume. Use `AskUserQuestion` with the 7 modes as
     options; keep asking scoped follow-ups until scope is unambiguous.
   - **Scope note:** installing/cataloging a skill into `.claude/skills-store/`
     (dormant) is available in any mode. Only *loading* a skill into
     `.claude/skills/**` (active) or editing the mechanics (hooks, `skillctl.sh`,
     mode files, skill-manager's own SKILL.md) requires mode 1 — see
     skill-manager SKILL.md → Hard rules.
3. **Lock the mode** — write its allowlist so the scope-guard enforces it:
   ```
   H=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
   printf '%s\n' <allowlist prefixes from the mode file> > /tmp/claude-mode-$H
   ```
   (`.claude/memory/` is always allowed implicitly; no need to list it.)
   State one line: `Mode: <n>-<name>`.
4. **Gate on skills** — on entry, skill-manager prints the full catalogue as
   markdown tables (not prose/bullets — this is the first thing the user reads
   in the session, keep it scannable): *(top)* a table of the best candidates —
   starting from `.claude/skills-store/MODE-SHORTLISTS.md`'s row for this mode,
   then broadened to anything else matching the confirmed task — columns
   `skill | state | why/how`, then *(below)* one table per category for the
   full store, columns `skill | state | policy | load-when`. **Wait for the
   user's free-text confirm or redaction before installing/loading anything**
   — skip only if the user already named skills or said "none". Applies in
   every mode. (See skill-manager SKILL.md → "Mode-entry skill GATE".)
5. **Make the mode explicit** (§Branch & log below) — this is the persistent
   record of what each session/branch was scoping on.
6. **Read the mode file** (`.claude/modes/<n>-*.md`) and follow it.

**Sequencing — address, don't act:** You may and should acknowledge the substance of
the user's literal request as soon as you understand it (e.g. "that already exists —
here's its state" / "that'll mean touching X"). But hold off **executing** any change
toward it until BOTH step 3 (mode locked) and step 4 (skill gate resolved) are done.
Acknowledging is not acting — don't let it slide into starting the task early.

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
