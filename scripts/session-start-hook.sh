#!/usr/bin/env bash
# SessionStart hook — orientation, NOT dependency install. Injects a scope prompt +
# repo state + branch-recency list so Claude declares a session scope before reading
# any code. Zero model tokens to compute; the injected text is the only cost.
# Emits additionalContext via the SessionStart hookSpecificOutput contract.
set -u

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$ROOT" || exit 0

INDEX=".claude/memory/INDEX.md"

# 1. Repo state: starter (fresh/unbootstrapped) vs in-progress (real project).
#    The new-project bootstrap flips this on first run. Missing/unreadable → assume starter.
STATE="starter"
if [ -f "$INDEX" ]; then
  s=$(grep -m1 '^state:' "$INDEX" | sed 's/^state:[[:space:]]*//' | tr -d '[:space:]')
  [ -n "$s" ] && STATE="$s"
fi

if [ "$STATE" = "in-progress" ]; then
  STATE_LINE="Repo state: in-progress → a real project. Typical scopes: one route (src/routes/<r>/), the shared design system (src/shared/), backend/routing, or a data/ingest layer (data/, refs/, …). Declare whichever the task needs."
else
  STATE_LINE="Repo state: starter → fresh/unbootstrapped (the mother Project-starter repo is always 'starter'). A fresh bootstrap usually declares a wide scope ('*') unless the prompt is narrower."
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
SESSION SCOPE (from session-start-hook) — set this before reading any code.

$STATE_LINE

Restate the session's purpose in one line, then DECLARE A SCOPE — the free-form set of path prefixes this session intends to write (e.g. \`src/routes/pricing/\`, or \`data/ refs/ src/shared/schema/\` for an ingest session, or \`*\` for a fresh bootstrap). If the first prompt is explicit and unambiguous, state your understanding + the scope and proceed; otherwise WAIT for the user's confirmation before locking scope (AskUserQuestion) — never assume.

Lock the scope so the guard can orient. It is ADVISORY by default — an out-of-scope Edit/Write is ALLOWED with a nudge, never blocked — so legitimate cross-scope work (shared files, assets, docs, data) needs no override:
  H=\$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
  printf '%s\n' <prefixes> > /tmp/claude-scope-\$H     # '*' = whole repo
  # optional HARD wall (blocks out-of-scope Edit/Write until removed):
  #   touch /tmp/claude-scope-enforce-\$H   — raise it deliberately for tightly-scoped work on a big multi-route project
Then read ONLY .claude/memory/INDEX.md (+ your route's map) — lazy start; do NOT read skill-curator or its references unless you act on skills. The files in .claude/modes/ are worked EXAMPLE scopes (system-dev, new-project, new-route, continue-route, backend-routing, design-system, data-ingest, other) — templates to crib from, not a menu you must pick from. Full model: .claude/modes/SCOPE_PROTOCOL.md (read only if you need detail beyond this summary).
Skills are OPT-IN (no mandatory gate). The current loadout is below — load a dormant skill only when the task needs it or the user asks, via \`/skills load <name>\` (thin mechanics; reading skill-curator's SKILL.md is only for installing/updating/extracting/deleting a skill).
Address, don't act: acknowledge the substance of the user's request as soon as understood, but do NOT execute changes until the scope is declared.

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
