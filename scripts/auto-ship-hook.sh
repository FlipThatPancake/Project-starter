#!/usr/bin/env bash
# Stop hook — auto-ship to the CURRENT BRANCH ONLY when the /ship-now
# "always on" toggle is set. Never touches main. Zero model tokens: pure
# shell, deterministic commit message, silent on success — only surfaces
# output when the ship actually fails, so a long incremental-tweaking
# session doesn't grow context on every turn.
set -u
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$ROOT" || exit 0

CWD_HASH=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
FLAG="/tmp/claude-autoship-$CWD_HASH"
[ -f "$FLAG" ] || exit 0
[ "$(cat "$FLAG" 2>/dev/null)" = "on" ] || exit 0

# nothing changed → nothing to do, stay silent (no subprocess, no output)
git status --porcelain 2>/dev/null | grep -q . || exit 0

N=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
MSG="auto-ship: $(date -u +%Y-%m-%dT%H:%M:%SZ) ($N file(s))"

OUT=$(bash scripts/ship.sh "$MSG" --force-push 2>&1)
STATUS=$?

if [ "$STATUS" -ne 0 ]; then
  DETAIL=$(printf '%s' "$OUT" | tail -5 | tr '\n' ' ' | sed 's/"/\\"/g')
  printf '{"systemMessage":"\\u26a0\\ufe0f auto-ship (branch always on) failed: %s"}\n' "$DETAIL"
fi
exit 0
