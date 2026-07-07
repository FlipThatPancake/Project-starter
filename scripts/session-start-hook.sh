#!/usr/bin/env bash
# SessionStart hook — orientation, NOT dependency install. Injects a mode menu +
# repo state + branch-recency list so Claude picks a session mode before reading
# any code. Zero model tokens to compute; the injected text is the only cost.
# Emits additionalContext via the SessionStart hookSpecificOutput contract.
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$ROOT" || exit 0

INDEX=".claude/memory/INDEX.md"

# 1. Repo state: starter (fresh/unbootstrapped) vs in-progress (real project).
#    Mode 2 flips this on first bootstrap. Missing/unreadable → assume starter.
STATE="starter"
if [ -f "$INDEX" ]; then
  s=$(grep -m1 '^state:' "$INDEX" | sed 's/^state:[[:space:]]*//' | tr -d '[:space:]')
  [ -n "$s" ] && STATE="$s"
fi

if [ "$STATE" = "in-progress" ]; then
  STATE_LINE="Repo state: in-progress → a real project. Offer modes 3 (new route), 4 (continue route), 5 (backend/routing), 6 (design system); modes 1/2/7 as relevant."
else
  STATE_LINE="Repo state: starter → fresh/unbootstrapped (the mother Project-starter repo is always 'starter'). Steer toward mode 2 (new project) unless the prompt clearly says otherwise."
fi

# 2. Branch discovery — remote branches ranked by last-commit recency, so the
#    new-project flow can ask which branch to copy starter files from.
BRANCHES=$(git for-each-ref --sort=-committerdate refs/remotes \
  --format='  %(refname:short) — %(committerdate:relative)' 2>/dev/null | head -8)
[ -z "$BRANCHES" ] && BRANCHES="  (no remote branches found)"

CONTEXT=$(cat <<EOF
SESSION MODE SELECTION (from session-start-hook) — do this before reading any code.

$STATE_LINE

Pick a session mode per .claude/modes/README.md:
  1 system-dev · 2 new-project · 3 new-route · 4 continue-route · 5 backend-routing · 6 design-system · 7 other
Rule: restate the session's purpose in one line. If the first prompt is explicit and unambiguous, state your understanding + inferred mode and proceed; otherwise WAIT for the user's confirmation before locking a mode (AskUserQuestion) — never assume. Then lock it (write /tmp/claude-mode-<hash>) and read .claude/modes/<n>-*.md.
Skill GATE (every mode, after purpose is confirmed): print the FULL catalog as a markdown list — top: 2-4 suggested picks with why/how, below: everything else by category (incl. Upstream candidates + dormant store skills) — and WAIT for the user's free-text confirm/redaction before installing or loading anything. Skip only if the user already named skills or said "none". (skill-manager SKILL.md → "Mode-entry skill GATE".)

Remote branches by recency (for the new-project 'which branch to copy from' question):
$BRANCHES
EOF
)

if command -v jq >/dev/null 2>&1; then
  jq -n --arg c "$CONTEXT" \
    '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$c}}'
else
  # jq absent — fall back to plain stdout (still surfaced as context)
  printf '%s\n' "$CONTEXT"
fi
exit 0
