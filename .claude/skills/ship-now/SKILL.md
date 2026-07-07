---
name: ship-now
description: Use when the user says "ship it", "push now", "ship to main", or "merge to main", or wants to end the session by committing+pushing even though CLAUDE_AUTO_PUSH_TO_MAIN is set to false. Pushes the current branch as a one-time override; ALSO merges into main, but only when the user explicitly asks for main/merge, not on a bare "ship it".
---

# ship-now — one-time push override (+ optional explicit merge to main)

`ship.sh` pushes whatever branch you're on by default — it does NOT touch
`main` unless told to. `CLAUDE_AUTO_PUSH_TO_MAIN` is a legacy name for
"push at all", not "push to main"; don't let the name imply otherwise.

## Deciding which mode the user means
- "ship it" / "push now" / "save my work" → **branch push only**. Do NOT merge to main unless asked.
- "ship to main" / "merge to main" / "get this onto main" → **branch push + merge to main** (`--to-main`).
- Ambiguous ("ship this session") → ask which one before running anything that touches `main`; merging into a shared branch is not something to guess at.

## Steps
1. Commit message: use what the user gave; if none, write one summarizing this
   session's changes (imperative, ≤72 chars), prefixed with the session's mode
   tag per `CLAUDE.md`'s "Mode is explicit" rule, e.g. `[mode:1-system-dev] ...`.
2. Run:
   ```
   scripts/ship.sh "<msg>" --force-push [--to-main]
   ```
   - `--force-push` (a real `ship.sh` flag) ignores `CLAUDE_AUTO_PUSH_TO_MAIN=false`
     for this call only — the toggle is untouched for later calls.
   - `--to-main`, when the user asked for main/merge: after the branch push
     succeeds, merges the branch into `origin/main` via a disposable local temp
     branch (`--no-ff`, real merge commit) and pushes that — never force-pushes
     main. On a genuine conflict or a race (main moved since fetch), it aborts
     cleanly, leaves `main` untouched, and reports how to resolve manually —
     it will NOT auto-resolve or force through a conflict.
3. If `.claude/memory/SESSION-LOG.md` has no row for this session yet, append
   one first (per checkpoint's update rules) so the push carries the log entry.
4. Report the resulting commit hash, branch pushed to, and (if `--to-main` ran)
   whether the merge into `main` succeeded or was rejected.

## Guardrails
- Never edits `.claude/settings.json` — this is a one-shot override, not a
  permanent flip. Changing the toggle itself is a settings edit, not this skill.
- Still respects the cross-route scope-guard gate — a cross-route commit still
  needs `@allow-cross-route` in the message; this skill doesn't bypass that.
- If nothing is staged/changed, `ship.sh` no-ops cleanly ("nothing to commit") —
  report that plainly rather than forcing an empty commit.
- `--to-main` merges CURRENT `origin/main` content in as-is, conflicts and all
  history — it does not know if unrelated commits landed there since you last
  looked (e.g. direct web-UI uploads/deletes). If that matters, check
  `git log origin/main` first and say so before merging.
