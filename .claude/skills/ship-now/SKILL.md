---
name: ship-now
description: Use when the user says "ship it", "push now", "save my work", "ship to main", "PR to main", "ship-now branch always on/off", or wants to commit+push at session end even with CLAUDE_AUTO_PUSH_TO_MAIN=false. Two targets — branch (default) or pr (whenever main is meant) — using GitHub's own PR merge as the ONLY normal path to main. A local direct merge exists solely as a confirmed fallback if the GitHub merge is blocked. "always on/off" toggles a zero-token Stop-hook auto-ship to branch for the rest of the session.
---

# ship-now — commit + push, to a clearly-chosen target

## Mental model (do NOT get this wrong)
Work happens in this container's LOCAL git repo — ephemeral, dies with the
session. GitHub (`origin`) is the durable copy. `git push` is the ONLY thing
that makes work survive. The container's local `main` branch is a stale
bookmark we never work on — not a valid target, ever.

**A PR is not git asking permission — git has no concept of PRs.** A PR is
GitHub's layer on top of git: it stages a branch for review/status-checks/
branch-protection, and GitHub itself performs the merge once those gates pass
(or a human clicks merge). "Normal GitHub protocol" = push → PR → let GitHub
merge it. Bypassing that (a local `git merge` pushed straight to `main`) skips
every gate GitHub would otherwise enforce — that's why it's a fallback, not a
routine option.

## Toggle: auto-ship to branch ("always on" / "always off") — check this FIRST
If the args contain "always on" (or "auto on", "always"): this is NOT a normal
ship — it's a persistent mode switch. Handle it and stop, don't fall through to
target resolution below:
1. `H=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8); echo on > /tmp/claude-autoship-$H`
2. Run one immediate **branch** ship now (§Steps — branch) to clear anything
   already pending.
3. Report: auto-ship is ON for the rest of this session — every turn's Stop
   hook (`scripts/auto-ship-hook.sh`) will silently push to the branch if
   anything changed; `main` is never touched by this. Turn off with
   "ship-now branch always off".

If the args contain "always off" (or "auto off"):
1. `H=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8); rm -f /tmp/claude-autoship-$H`
2. Report: auto-ship is OFF. (Does not itself ship anything pending — say so;
   run a normal "ship it" if there's uncommitted work you want saved.)

Mechanics: the flag is a session-scoped `/tmp` file (dies with the container,
same as the mode/scope locks) — it does NOT persist to a future session. The
Stop hook is pure shell (deterministic timestamp commit message, silent on
success, only prints on failure) — zero added model tokens per turn. It always
targets **branch**, never `pr`/main, regardless of this toggle.

## The two targets
| target | commits go to | main touched? | how |
|---|---|---|---|
| **branch** | `origin/<current-branch>` | no | `scripts/ship.sh "<msg>" --force-push` |
| **pr** | `origin/<current-branch>` + PR into `main`, merged via GitHub | yes, through GitHub's own gates | push, then PR create/update + GitHub-side merge (§PR flow) |

There is no routine "merge directly" option. If GitHub's merge is blocked,
see §Fallback — it requires the user's explicit yes each time, never assumed.

## Resolving which target
1. Explicit token (`branch` / `pr`) wins.
2. Clear NL: branch → "ship it", "push now", "save", "back up my work".
   pr → "ship to main", "PR to main", "open a PR", "get this on main", "release it".
3. No destination named at all → **target = branch**, no prompt. State plainly:
   pushed to the branch, nothing on main, say "ship to main" to escalate.
   (There's nothing left to disambiguate — "direct merge" no longer exists as
   an alternate reading of a main-mention, so step 3 from the old design is gone.)

## Steps — branch
1. Commit message: user's if given; else summarize the session (imperative,
   ≤72 chars), prefixed with the mode tag per CLAUDE.md, e.g. `[mode:1-system-dev] …`.
2. If `.claude/memory/SESSION-LOG.md` lacks this session's row, append it first.
3. `scripts/ship.sh "<msg>" --force-push`.
4. Report commit hash + branch pushed to.

## Steps — pr (normal GitHub protocol)
1. Steps 1–3 above (push the branch first — a PR needs commits to point at).
2. Check for an existing open PR: `mcp__github__list_pull_requests` (head=current
   branch). None → `mcp__github__create_pull_request` (base=`main`). One exists →
   the push already updated it; note its URL.
3. **Merge it through GitHub, not locally**: `mcp__github__merge_pull_request`
   (pullNumber, default `merge_method: merge`). This is the step that respects
   branch protection, required status checks, and required reviews — exactly
   the "ask GitHub" step the user wants as the only normal path.
4. If the merge call succeeds → report: PR URL, merged, main updated.
5. If it's rejected (blocked by protection rules, failing/pending checks, required
   reviews not satisfied, merge conflict) → **do not silently fall back**. Report
   the exact reason GitHub gave, then go to §Fallback.

## Fallback — only after a blocked GitHub merge, only with explicit yes
1. State plainly why the GitHub merge didn't go through.
2. `AskUserQuestion`: offer to force it via a local direct merge
   (`scripts/ship.sh "<msg>" --force-push --to-main` — merges via a disposable
   temp branch, `--no-ff`, never force-pushes `main`; aborts clean on a real
   conflict) vs. leaving the PR open for manual resolution/review.
3. Only run `--to-main` if the user picks that option. Never assume "PR failed"
   implies "force it" — that decision is the user's alone, every time.
4. Report the outcome (merged / still blocked / conflict needing manual resolution).

## Guardrails
- Never edits `.claude/settings.json` — `--force-push` is a one-shot override.
- Cross-route commits still need `@allow-cross-route` in the message.
- Nothing staged/changed → ship.sh no-ops ("nothing to commit"); report plainly.
  For **pr** with no new commits, still check/refresh the existing PR and attempt
  its merge — there may already be pushed commits waiting to land.
- `--to-main` (fallback only) merges in whatever is CURRENTLY on `origin/main`
  as-is — if unrelated commits landed there outside review, say so before using it.
