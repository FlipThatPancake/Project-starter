---
name: ship-now
description: Use when the user says "ship it", "ship to main", "push now", or wants to end the session by committing+pushing even though CLAUDE_AUTO_PUSH_TO_MAIN is set to false. One-time push override — does not edit settings.json.
---

# ship-now — one-time push override

`ship.sh` already pushes to whatever branch you're on, never literally "main" —
`CLAUDE_AUTO_PUSH_TO_MAIN` is a legacy name for "push at all". This skill forces
that push for THIS invocation only; the toggle is left exactly as the user set
it, for any later `ship.sh` calls this session.

## Steps
1. Commit message: use what the user gave; if none, write one summarizing this
   session's changes (imperative, ≤72 chars), prefixed with the session's mode
   tag per `CLAUDE.md`'s "Mode is explicit" rule, e.g. `[mode:1-system-dev] ...`.
2. Run:
   ```
   scripts/ship.sh "<msg>" --force-push
   ```
   `--force-push` (a real `ship.sh` flag, not just an env override) ignores
   `CLAUDE_AUTO_PUSH_TO_MAIN=false` for this call regardless of how it's set.
3. If `.claude/memory/SESSION-LOG.md` has no row for this session yet, append
   one first (per checkpoint's update rules) so the push carries the log entry.
4. Report the resulting commit hash and branch pushed to.

## Guardrails
- Never edits `.claude/settings.json` — this is a one-shot override, not a
  permanent flip. Changing the toggle itself is a settings edit, not this skill.
- Still respects the cross-route scope-guard gate — a cross-route commit still
  needs `@allow-cross-route` in the message; this skill doesn't bypass that.
- If nothing is staged/changed, `ship.sh` no-ops cleanly ("nothing to commit") —
  report that plainly rather than forcing an empty commit.
