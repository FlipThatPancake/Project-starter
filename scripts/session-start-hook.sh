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

# 3. Skill index — enumerate .claude/skills/ (active) + the store (dormant) directly
#    in bash (v3: no generated INDEX.md, no policy field) so Claude never needs to
#    READ skill-curator's doctrine at session start. Skills are OPT-IN: this list is
#    for awareness; load only on request.
SKILL_INDEX=""
for d in .claude/skills/*/; do
  [ -d "$d" ] || continue
  n=$(basename "$d"); f="${d}SKILL.md"
  [ -f "$f" ] || continue
  g=$(sed -n 's/^group:[[:space:]]*//p' "$f" | head -1)
  sz=$(grep -cv '^[[:space:]]*$' "$f" 2>/dev/null || echo 0)
  SKILL_INDEX="${SKILL_INDEX}| $n | active | ${g:-—} | $sz |
"
done
for d in .claude/skills-store/skill-storage/*/; do
  [ -d "$d" ] || continue
  n=$(basename "$d")
  [ -e ".claude/skills/$n" ] && continue    # active copy shadows the store master
  f="${d}SKILL.md"
  [ -f "$f" ] || continue
  g=$(sed -n 's/^group:[[:space:]]*//p' "$f" | head -1)
  sz=$(grep -cv '^[[:space:]]*$' "$f" 2>/dev/null || echo 0)
  SKILL_INDEX="${SKILL_INDEX}| $n | dormant | ${g:-—} | $sz |
"
done
[ -z "$SKILL_INDEX" ] && SKILL_INDEX="  (no skills found)"
SKILL_INDEX="| skill | state | group | size |
|---|---|---|---|
${SKILL_INDEX}"

# 4. Spec — surface .claude/memory/SPEC.md in full if it exists (zero cost when
#    absent, same pattern as the skill index). Tickets are small and often
#    tackled out of order / several per session, so there's no single "next"
#    pointer to compute — just hand over the whole open plan.
SPEC_FILE=".claude/memory/SPEC.md"
if [ -f "$SPEC_FILE" ]; then
  SPEC_BLOCK=$(cat "$SPEC_FILE")
  SPEC_SECTION="

Spec (.claude/memory/SPEC.md) — read at session start, tickets may be tackled out of order:
${SPEC_BLOCK}"
else
  SPEC_SECTION=""
fi

# 5. Context — surface .claude/memory/CONTEXT.md (the shared glossary) in full if
#    it exists, same zero-cost-when-absent pattern, so every session opens sharing
#    the project's vocabulary.
CONTEXT_FILE=".claude/memory/CONTEXT.md"
if [ -f "$CONTEXT_FILE" ]; then
  CONTEXT_BLOCK=$(cat "$CONTEXT_FILE")
  CONTEXT_SECTION="

Terms (.claude/memory/CONTEXT.md) — the project's shared glossary, honor these canonical terms:
${CONTEXT_BLOCK}"
else
  CONTEXT_SECTION=""
fi

CONTEXT=$(cat <<EOF
SESSION MODE SELECTION (from session-start-hook) — do this before reading any code.

$STATE_LINE

Pick a session mode (steps summarized here — the full spec is .claude/modes/MODES_PROTOCOL.md, read it ONLY if you need detail beyond this summary):
  1 system-dev · 2 new-project · 3 new-route · 4 continue-route · 5 backend-routing · 6 design-system · 7 other
Rule: restate the session's purpose in one line. If the first prompt is explicit and unambiguous, state your understanding + inferred mode and proceed; otherwise WAIT for the user's confirmation before locking a mode (AskUserQuestion) — never assume. Then lock the mode + read ONLY the chosen .claude/modes/<n>-*.md (it carries the exact lock command + allowlist) + .claude/memory/INDEX.md (lazy start — do NOT read skill-curator or its references unless you actually act on skills).
Skills are OPT-IN (no mandatory gate). The current loadout is below — load a dormant skill only when the task needs it or the user asks, via \`/skills load <name>\` (thin mechanics; reading skill-curator's SKILL.md is only for installing/updating/extracting/deleting a skill).
Address, don't act: acknowledge the substance of the user's request as soon as understood, but do NOT execute changes until the mode is locked.

Skill index (active = in context now · dormant = zero tokens until loaded; size = SKILL.md lines):
$SKILL_INDEX

Remote branches by recency (for the new-project 'which branch to copy from' question):
$BRANCHES
${SPEC_SECTION}${CONTEXT_SECTION}
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
