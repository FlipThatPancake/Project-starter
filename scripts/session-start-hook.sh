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

# 3. Skill index — regenerate the thin browse surface (v2 §B4/B5) and embed it so
#    Claude never needs to READ CATALOG/CONFLICTS/skill-manager at session start.
#    Skills are OPT-IN: this list is for awareness; load only on request.
SKILL_INDEX="  (skill index unavailable)"
if command -v node >/dev/null 2>&1; then
  node scripts/gen-skill-index.mjs >/dev/null 2>&1 || true
  [ -f .claude/skills-store/INDEX.md ] && SKILL_INDEX=$(grep '^|' .claude/skills-store/INDEX.md 2>/dev/null)
fi

CONTEXT=$(cat <<EOF
SESSION MODE SELECTION (from session-start-hook) — do this before reading any code.

$STATE_LINE

Pick a session mode per .claude/modes/README.md:
  1 system-dev · 2 new-project · 3 new-route · 4 continue-route · 5 backend-routing · 6 design-system · 7 other
Rule: restate the session's purpose in one line. If the first prompt is explicit and unambiguous, state your understanding + inferred mode and proceed; otherwise WAIT for the user's confirmation before locking a mode (AskUserQuestion) — never assume. Then lock it (write /tmp/claude-mode-<hash>) and read ONLY .claude/modes/<n>-*.md + .claude/memory/INDEX.md (lazy start — do NOT read CATALOG/CONFLICTS/skill-manager unless you actually act on skills).
Skills are OPT-IN (no mandatory gate). The current loadout is below — load a dormant skill only when the task needs it or the user asks, via \`/skills load <name>\` (thin mechanics; reading skill-manager's full SKILL.md is only for installing a NEW skill from the web). MODE-SHORTLISTS.md suggests per-mode picks if you want them.
Address, don't act: acknowledge the substance of the user's request as soon as understood, but do NOT execute changes until the mode is locked.

Skill index (active = in context now · dormant = zero tokens until loaded; size = SKILL.md lines):
$SKILL_INDEX

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
