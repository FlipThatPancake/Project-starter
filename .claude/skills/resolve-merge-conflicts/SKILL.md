---
name: resolve-merge-conflicts
description: Use when there is an in-progress git merge/rebase conflict (conflicted files, mid-merge/mid-rebase state) that needs to be untangled — not for the routine "leftover marker in a staged commit" case, which ship.sh already blocks. Manual, load by name.
---

# resolve-merge-conflicts

## Scope — read this first
This skill is for an **active merge/rebase conflict on a local/feature branch**.

It does NOT apply to:
- A merge/rebase whose target is `main` or another shared/protected branch. On
  those, resolve on a disposable local branch as usual, but **stop before the
  final commit/push and ask the user** — do not auto-finish a conflict
  resolution that lands on a shared branch. This is a hard carve-out from the
  "never abort" rule below; a shared-branch conflict is exactly the case where
  a silent auto-resolution is most dangerous.
- `ship.sh`'s own conflict handling. `--to-main` already aborts cleanly on
  conflict and hands the temp branch back for inspection — that's correct
  behavior for an unattended/auto-ship context and this skill doesn't override
  it. Use this skill when a human (or the user, mid-session) explicitly wants
  the conflict resolved now, feature-branch-to-feature-branch or
  feature-branch-to-upstream-feature-branch.

## Steps
1. **See the current state.** `git status`, `git log --oneline --graph -20
   --all`, list conflicted files (`git diff --name-only --diff-filter=U`).
2. **Find the primary source of each conflict.** For each conflicted file,
   check both sides' commit messages (`git log <ours>..<theirs>` and reverse)
   and, if referenced, the PR/issue that introduced each side. Understand what
   each side was trying to do — don't guess from the diff alone if the intent
   isn't obvious from it.
3. **Resolve each hunk.** Preserve both intents where they're compatible.
   Where they're genuinely incompatible, pick the one matching the merge's
   stated goal (the branch/PR this merge exists to land) and leave a one-line
   note (commit body, not inline comment) on the trade-off made — don't invent
   new behavior neither side wrote.
4. **Run the project's checks** before finalizing: `node scripts/validate.mjs
   --all`, then any route build (`node scripts/build.mjs <route>`) affected by
   the resolution, then the universal conflict-marker guard ship.sh already
   runs (staged diff must have zero `<<<<<<<`/`=======`/`>>>>>>>` lines) —
   don't invent a separate check pipeline, use what this repo already has.
5. **Finish.** Stage everything, commit (or `git rebase --continue` through
   all remaining commits if rebasing). Do not `--abort` once you've reached
   this point on a feature branch — abandoning a resolved conflict loses the
   analysis work from steps 2-3. `--abort` is still correct if you discover
   mid-resolution that the merge target is wrong or shared/protected (see
   Scope above) — abort and ask, don't push through.
6. Ship per normal `ship-now` rules (branch target, unless the user asked for
   `pr`) — this skill resolves the conflict, it doesn't decide where the
   result gets pushed.

## Why "never abort" is softened here
The upstream version of this idea says "always resolve, never abort." That's
right for a feature branch where you're the only one affected — a clean
resolution captured now (with the intent-tracing in step 2) is strictly better
than punting. It is wrong as an absolute rule in a repo where a Stop hook can
auto-ship every turn: an unattended agent that "always resolves and commits"
a conflict landing on `main` has no human checkpoint. So: abort freely (and
ask) the moment a conflict resolution would land on a shared/protected branch;
otherwise resolve to completion, don't abort.
