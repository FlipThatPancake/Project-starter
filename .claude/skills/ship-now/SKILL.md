---
name: ship-now
description: Use when the user says "ship it", "push now", "save my work", "ship to main", "merge to main", "PR to main", or wants to commit+push at session end even with CLAUDE_AUTO_PUSH_TO_MAIN=false. Resolves to one of three targets — branch / pr / merge — inferring from wording, asking only when a main-integration method is ambiguous.
---

# ship-now — commit + push, to a clearly-chosen target

## Mental model (do NOT get this wrong)
Work happens in this container's LOCAL git repo — ephemeral, dies with the
session. GitHub (`origin`) is the durable copy. `git push` is the ONLY thing
that makes work survive. Two things people wrongly call "push to main":
- The container's local `main` branch = a stale bookmark we never work on.
  **Never update it — it changes nothing anyone can see. Not a valid target.**
- `origin/main` on GitHub = the real shared branch. THIS is what "to main" means.

## The three targets
Every invocation resolves to exactly ONE:

| target | commits go to | main touched? | how |
|---|---|---|---|
| **branch** | `origin/<current-branch>` | no | `scripts/ship.sh "<msg>" --force-push` |
| **pr** | `origin/<current-branch>` + a PR into `main` | no (you merge on GitHub) | ship.sh push, then create/update PR via github MCP |
| **merge** | `origin/<current-branch>`, then merged into `origin/main` now | yes, immediately, no review | `scripts/ship.sh "<msg>" --force-push --to-main` |

## Resolving which target (in order)
1. **Explicit token** in the args — `branch`, `pr`, or `merge` — wins outright.
2. **Clear natural language:**
   - branch → "ship it", "push now", "save", "back up my work", "push the branch"
   - pr → "open a PR", "PR it", "PR to main", "raise a pull request", "review before main"
   - merge → "merge to main directly", "straight to main", "to-main", "merge now no PR"
3. **Main mentioned but method unclear** — bare "push to main", "ship to main",
   "get this on main", "release it" → **ASK** (`AskUserQuestion`): PR vs direct
   merge. Recommend PR first (reviewable; and it's the ONLY path that works once
   branch protection is on — a direct merge to a protected main is rejected).
4. **No destination named at all** ("ship it", "ship now", "save") → **target =
   branch**, no prompt. Afterward state plainly: pushed to the branch, nothing on
   main, and that "ship to main" is how to escalate. (User-chosen default.)

## Steps (all targets)
1. Commit message: user's if given; else summarize this session (imperative,
   ≤72 chars) prefixed with the mode tag per CLAUDE.md, e.g. `[mode:1-system-dev] …`.
2. If `.claude/memory/SESSION-LOG.md` lacks this session's row, append it first
   (per checkpoint rules) so the push carries it.
3. Run the target's command from the table.
   - `--force-push` overrides `CLAUDE_AUTO_PUSH_TO_MAIN=false` for THIS call only
     (never edits settings.json).
   - For **pr**: after the branch push, check for an existing open PR
     (`mcp__github__list_pull_requests`, head=current branch); create one
     (`mcp__github__create_pull_request`, base=main) if none, else report the
     existing PR URL (a new push already updates it).
4. Report: commit hash, branch pushed to, and — for pr/merge — the PR URL or
   whether the merge into `main` succeeded / was rejected.

## Guardrails
- Never edits `.claude/settings.json` — one-shot override, not a permanent flip.
- **merge** uses `ship.sh --to-main`: merges via a disposable temp branch
  (`--no-ff`, real merge commit), never force-pushes main; on conflict or a race
  it aborts, leaves main untouched, and reports how to resolve. It also pulls in
  whatever is CURRENTLY on `origin/main` as-is (including any unrelated direct
  pushes/deletes) — if that could matter, check `git log origin/main` first and
  say so before merging.
- If branch protection is on, prefer/steer to **pr**; warn that **merge** will
  likely be rejected by GitHub.
- Cross-route commits still need `@allow-cross-route` in the message — not bypassed.
- Nothing staged/changed → ship.sh no-ops ("nothing to commit"); report that
  plainly, don't force an empty commit. (A pr/merge with no new commits can still
  open/refresh the PR or merge already-pushed commits — do that part.)
