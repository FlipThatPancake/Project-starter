#!/bin/bash
# PreToolUse hook — validate Edit/Write against locked route's scope

set -e

# Compute cwd hash (matches project-memory session-lock logic)
CWD_HASH=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
SCOPE_FILE="/tmp/claude-route-scope-$CWD_HASH"
MODE_FILE="/tmp/claude-mode-$CWD_HASH"

# No mode lock AND no route lock → nothing to enforce
[[ ! -f "$MODE_FILE" && ! -f "$SCOPE_FILE" ]] && exit 0

# Guard the read: under `set -e`, a bare $(cat missing) would abort the script
LOCKED_ROUTE=""
[[ -f "$SCOPE_FILE" ]] && LOCKED_ROUTE=$(cat "$SCOPE_FILE")
# Locks are written as "/<route>" (docs format) — strip the leading slash so
# "src/routes/$LOCKED_ROUTE" doesn't become src/routes//<route> (matches nothing)
LOCKED_ROUTE="${LOCKED_ROUTE#/}"

# Read hook payload from stdin (JSON). Per Claude Code hooks schema, the tool
# name is top-level "tool_name" and its arguments are under "tool_input"
# (Edit/Write use "tool_input.file_path"); "cwd" is the repo root at invocation.
PAYLOAD=$(cat)

# Field extraction. jq is preferred, but this is the ENFORCEMENT hook — if jq is
# absent, aborting under `set -e` would exit non-2, which the harness reads as
# "allow" (fail-OPEN — the worst outcome for a guard). So fall back to a
# sed-based extractor that handles the flat string fields we need. If BOTH fail
# to yield a tool name on a payload that clearly has one, fail CLOSED (exit 2).
# SCOPE_GUARD_NO_JQ=1 forces the jq-free fallback below — the test suite sets it
# to exercise that path deterministically without stripping jq from PATH (which
# would be brittle: it'd break the moment this script used a new coreutil). Never
# set it in normal operation.
if [ -z "${SCOPE_GUARD_NO_JQ:-}" ] && command -v jq >/dev/null 2>&1; then
  TOOL_NAME=$(printf '%s' "$PAYLOAD" | jq -r '.tool_name // empty')
  FILE_PATH=$(printf '%s' "$PAYLOAD" | jq -r '.tool_input.file_path // empty')
  REPO_ROOT=$(printf '%s' "$PAYLOAD" | jq -r '.cwd // empty')
else
  # Minimal fallback: grab the first quoted value of each key. Good enough for
  # the flat string fields Edit/Write payloads carry; not general JSON parsing.
  jqless() { printf '%s' "$PAYLOAD" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1; }
  TOOL_NAME=$(jqless tool_name)
  FILE_PATH=$(jqless file_path)
  REPO_ROOT=$(jqless cwd)
  # If the payload names a guarded tool but we couldn't extract a path, fail
  # closed rather than silently allowing an unparsed Edit/Write.
  if [[ -z "$TOOL_NAME" ]] && printf '%s' "$PAYLOAD" | grep -q '"tool_name"'; then
    echo '{"error":"scope-guard-parse","message":"jq unavailable and fallback parse failed; blocking Edit/Write to fail safe. Install jq."}' >&2
    exit 2
  fi
fi
[[ -z "$REPO_ROOT" ]] && REPO_ROOT=$(pwd)

# Only validate Edit and Write tools
if [[ "$TOOL_NAME" != "Edit" && "$TOOL_NAME" != "Write" ]]; then
  exit 0
fi

# No file_path, allow
[[ -z "$FILE_PATH" ]] && exit 0

# file_path arrives absolute (repo-root-prefixed) — make it repo-relative so it
# lines up with the allowlist, which is written relative to the repo root
REL_PATH="$FILE_PATH"
if [[ "$FILE_PATH" == "$REPO_ROOT"/* ]]; then
  REL_PATH="${FILE_PATH#"$REPO_ROOT"/}"
fi

# .claude/** is always writable in any mode (memory, skill activation,
# cataloguing) — matches MODES_PROTOCOL and ship.sh's commit gate
[[ "$REL_PATH" =~ ^\.claude/ ]] && exit 0

# Mode allowlist (set by the session-mode lock) supersedes the route lock.
# File holds newline-separated repo-relative path prefixes; a lone '*' = allow all.
if [[ -f "$MODE_FILE" ]]; then
  while IFS= read -r prefix; do
    [[ -z "$prefix" ]] && continue
    [[ "$prefix" == "*" ]] && exit 0
    [[ "$REL_PATH" == "$prefix"* ]] && exit 0
  done < "$MODE_FILE"
  ALLOWED=$(paste -sd' ' "$MODE_FILE" 2>/dev/null)
  cat >&2 <<EOF
{
  "tool": "$TOOL_NAME",
  "file": "$REL_PATH",
  "error": "scope-violation",
  "message": "Edit/Write blocked by the locked session mode. Allowed prefixes: $ALLOWED (plus .claude/**). To proceed: switch mode, or deliberately widen the mode allowlist file — this hook has no inline override."
}
EOF
  exit 2
fi

# No mode file → fall back to the route lock: src/routes/<locked>/**
ROUTE_DIR="src/routes/$LOCKED_ROUTE"
if [[ "$REL_PATH" =~ ^$ROUTE_DIR/ ]]; then
  exit 0
fi

# Outside allowlist — deny (ship-time gate handles override)
cat >&2 <<EOF
{
  "tool": "$TOOL_NAME",
  "file": "$REL_PATH",
  "error": "scope-violation",
  "message": "Edit/Write blocked outside locked route '/$LOCKED_ROUTE'. Only edits to $ROUTE_DIR/** and .claude/** are allowed. To work cross-route: re-lock scope ('switch to /x') or widen the mode allowlist — this hook has no inline override. (ship.sh separately requires @allow-cross-route in the commit message for cross-route commits.)"
}
EOF
exit 2
