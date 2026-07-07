#!/bin/bash
# PreToolUse hook — validate Edit/Write against locked route's scope

set -e

# Compute cwd hash (matches project-memory session-lock logic)
CWD_HASH=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
SCOPE_FILE="/tmp/claude-scope-$CWD_HASH"

# No lock, no check
[[ ! -f "$SCOPE_FILE" ]] && exit 0

LOCKED_ROUTE=$(cat "$SCOPE_FILE")

# Read hook payload from stdin (JSON). Per Claude Code hooks schema, the tool
# name is top-level "tool_name" and its arguments are under "tool_input"
# (Edit/Write use "tool_input.file_path"); "cwd" is the repo root at invocation.
PAYLOAD=$(cat)
TOOL_NAME=$(echo "$PAYLOAD" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$PAYLOAD" | jq -r '.tool_input.file_path // empty')
REPO_ROOT=$(echo "$PAYLOAD" | jq -r '.cwd // empty')
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

# Allowlist: src/routes/<locked>/** and .claude/memory/**
# Everything else (including shared/**) requires override at ship time
ROUTE_DIR="src/routes/$LOCKED_ROUTE"

if [[ "$REL_PATH" =~ ^$ROUTE_DIR/ ]] || [[ "$REL_PATH" =~ ^\.claude/memory/ ]]; then
  exit 0
fi

# Outside allowlist — deny (ship-time gate handles override)
cat >&2 <<EOF
{
  "tool": "$TOOL_NAME",
  "file": "$REL_PATH",
  "error": "scope-violation",
  "message": "Edit/Write blocked outside locked route '$LOCKED_ROUTE'. Only edits to $ROUTE_DIR/** and .claude/memory/** are allowed. Use @allow-cross-route in your next prompt and commit message to override."
}
EOF
exit 2
