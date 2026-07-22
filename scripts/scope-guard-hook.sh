#!/bin/bash
# PreToolUse hook — check Edit/Write against the session's DECLARED SCOPE.
#
# Posture (see .claude/modes/SCOPE_PROTOCOL.md):
#   ADVISORY (default): an out-of-scope Edit/Write is ALLOWED, with a nudge
#     surfaced to Claude (additionalContext) and the user (systemMessage). The
#     declared scope is orientation, not a wall — legitimate cross-scope work
#     (shared files, assets, docs, data/ingest) proceeds without an override dance.
#   ENFORCING (opt-in): if the enforce flag file exists, an out-of-scope Edit/Write
#     is BLOCKED (exit 2, stderr fed back to Claude). This is the deterministic,
#     before-review guardrail — raise it deliberately for tightly-scoped work on a
#     large multi-route project, where an accidental cross-route edit is the risk.
#
# Lock files (keyed on sha256 of `pwd` output, matching ship.sh / project-memory):
#   /tmp/claude-scope-<h>          declared write-prefixes, newline-separated; '*' = whole repo
#   /tmp/claude-scope-enforce-<h>  existence flips advisory -> enforcing
#   /tmp/claude-route-scope-<h>    legacy route lock (project-memory) -> src/routes/<route>/

set -e

CWD_HASH=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
SCOPE_FILE="/tmp/claude-scope-$CWD_HASH"
ENFORCE_FLAG="/tmp/claude-scope-enforce-$CWD_HASH"
ROUTE_LOCK="/tmp/claude-route-scope-$CWD_HASH"

# No scope declared at all → nothing to check.
[[ ! -f "$SCOPE_FILE" && ! -f "$ROUTE_LOCK" ]] && exit 0

# jq is preferred for both parsing the payload and emitting the advisory JSON.
# SCOPE_GUARD_NO_JQ=1 forces the jq-free path (the test suite sets it to exercise
# the fallback deterministically — never set it in normal operation).
if [ -z "${SCOPE_GUARD_NO_JQ:-}" ] && command -v jq >/dev/null 2>&1; then HAVE_JQ=1; else HAVE_JQ=0; fi

PAYLOAD=$(cat)

# --- extract tool_name / file_path / cwd ---
# If jq is absent, fall back to a sed extractor for the flat string fields we need.
# If a payload clearly names a guarded tool but we cannot parse it, fail CLOSED
# (exit 2) rather than silently allowing an unvetted Edit/Write — this is the one
# place the guard blocks regardless of advisory/enforcing posture, because a hook
# that can't read its input can't make any safety claim.
if [[ "$HAVE_JQ" == 1 ]]; then
  TOOL_NAME=$(printf '%s' "$PAYLOAD" | jq -r '.tool_name // empty')
  FILE_PATH=$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.file_path // empty')
  REPO_ROOT=$(printf '%s' "$PAYLOAD" | jq -r '.cwd // empty')
else
  jqless() { printf '%s' "$PAYLOAD" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1; }
  TOOL_NAME=$(jqless tool_name)
  FILE_PATH=$(jqless file_path)
  REPO_ROOT=$(jqless cwd)
  if [[ -z "$TOOL_NAME" ]] && printf '%s' "$PAYLOAD" | grep -q '"tool_name"'; then
    echo '{"error":"scope-guard-parse","message":"jq unavailable and fallback parse failed; blocking Edit/Write to fail safe. Install jq."}' >&2
    exit 2
  fi
fi
[[ -z "$REPO_ROOT" ]] && REPO_ROOT=$(pwd)

# Only Edit/Write are scoped.
[[ "$TOOL_NAME" != "Edit" && "$TOOL_NAME" != "Write" ]] && exit 0
[[ -z "$FILE_PATH" ]] && exit 0

# Make the path repo-relative so it lines up with the declared prefixes.
REL_PATH="$FILE_PATH"
if [[ "$FILE_PATH" == "$REPO_ROOT"/* ]]; then
  REL_PATH="${FILE_PATH#"$REPO_ROOT"/}"
fi

# .claude/** is always in scope (memory maps, logs, skill activation).
[[ "$REL_PATH" =~ ^\.claude/ ]] && exit 0

# --- resolve the allowlist and whether this edit is in scope ---
# Primary: the declared-scope file (newline prefixes; '*' = whole repo).
# Legacy fallback: the route lock → the single prefix src/routes/<route>/.
MATCHED=0
ALLOWED=""
if [[ -f "$SCOPE_FILE" ]]; then
  while IFS= read -r prefix; do
    [[ -z "$prefix" ]] && continue
    if [[ "$prefix" == "*" || "$REL_PATH" == "$prefix"* ]]; then MATCHED=1; break; fi
  done < "$SCOPE_FILE"
  ALLOWED=$(paste -sd' ' "$SCOPE_FILE" 2>/dev/null)
elif [[ -f "$ROUTE_LOCK" ]]; then
  LOCKED_ROUTE=$(cat "$ROUTE_LOCK"); LOCKED_ROUTE="${LOCKED_ROUTE#/}"
  ROUTE_PREFIX="src/routes/$LOCKED_ROUTE/"
  [[ "$REL_PATH" == "$ROUTE_PREFIX"* ]] && MATCHED=1
  ALLOWED="$ROUTE_PREFIX"
fi

# In scope → allow silently (normal flow).
[[ "$MATCHED" == 1 ]] && exit 0

# --- OUT OF SCOPE ---
if [[ -f "$ENFORCE_FLAG" ]]; then
  # Enforcing: block. stderr is fed back to Claude as the tool error.
  cat >&2 <<EOF
{
  "tool": "$TOOL_NAME",
  "file": "$REL_PATH",
  "error": "scope-violation",
  "message": "BLOCKED by enforced session scope. Allowed prefixes: $ALLOWED (plus .claude/**). To proceed: widen /tmp/claude-scope-$CWD_HASH, or remove /tmp/claude-scope-enforce-$CWD_HASH to drop back to advisory."
}
EOF
  exit 2
fi

# Advisory (default): ALLOW and attach a nudge. We deliberately emit NO
# permissionDecision — the edit follows the normal permission flow, we only add
# context — so the guard never silently auto-approves an edit that would otherwise
# prompt. additionalContext reaches Claude; systemMessage reaches the user.
NUDGE="Scope nudge: Edit/Write to '$REL_PATH' is outside your declared session scope ($ALLOWED, plus .claude/**). If that's intended, carry on. If you're drifting off-task, re-focus or re-declare scope. To make the boundary hard, touch /tmp/claude-scope-enforce-$CWD_HASH."
if [[ "$HAVE_JQ" == 1 ]]; then
  jq -cn --arg ctx "$NUDGE" --arg rel "$REL_PATH" --arg allowed "$ALLOWED" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$ctx},
      systemMessage:("scope-guard (advisory): editing " + $rel + " outside declared scope (" + $allowed + ")")}'
else
  # Degraded path (no jq): can't safely emit JSON, so nudge on stderr and allow.
  printf '%s\n' "$NUDGE" >&2
fi
exit 0
