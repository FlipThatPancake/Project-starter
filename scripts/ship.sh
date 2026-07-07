#!/usr/bin/env bash
# ship.sh — validate → build changed routes → commit → push (with retry).
# Usage: scripts/ship.sh "commit message" [--no-validate] [--no-build] [--no-push] [--all] [--deep] [--sync] [--force-push]
# Validation is SCOPED to changed routes by default (cheap on a big portal);
# --deep (or --all) forces a full-portal audit.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

MSG="${1:-}"; shift || true
[ -z "$MSG" ] && { echo "ship: commit message required" >&2; exit 2; }
NOVAL=0 NOBUILD=0 NOPUSH=0 ALL=0 DEEP=0 SYNC=0 FORCEPUSH=0
for a in "$@"; do case "$a" in
  --no-validate) NOVAL=1;; --no-build) NOBUILD=1;; --no-push) NOPUSH=1;;
  --all) ALL=1;; --deep) DEEP=1;; --sync) SYNC=1;; --force-push) FORCEPUSH=1;;
  *) echo "ship: unknown flag $a" >&2; exit 2;;
esac; done

if [ "$NOVAL" = 0 ]; then
  if [ "$DEEP" = 1 ] || [ "$ALL" = 1 ] || ! git rev-parse -q --verify HEAD >/dev/null 2>&1; then
    node scripts/validate.mjs --all          # full audit (also on first/unborn commit)
  else
    # scope the memory anchor-walk + html checks to routes changed vs HEAD.
    # ids come from changed route dirs, changed route maps, or root index.html.
    IDS=$(git diff HEAD --name-only 2>/dev/null \
      | sed -nE 's#^src/routes/([^/]+)/.*#\1#p; s#^\.claude/memory/routes/([^/]+)\.md#\1#p; s#^(index\.html)$#\1#p' \
      | sort -u | paste -sd, - || true)
    HTML=$(git diff HEAD --name-only 2>/dev/null \
      | grep -E '(^index\.html$|^src/routes/[^/]+/index\.html$)' || true)
    node scripts/validate.mjs --memory --routes "$IDS"
    [ -n "$HTML" ] && echo "$HTML" | xargs node scripts/validate.mjs --src
  fi
fi

if [ "$NOBUILD" = 0 ] && [ -d src/routes ]; then
  if [ "$ALL" = 1 ]; then
    node scripts/build.mjs --all
  elif git rev-parse -q --verify HEAD >/dev/null 2>&1; then
    # rebuild only routes whose src changed vs HEAD (incl. uncommitted)
    CHANGED=$(git diff HEAD --name-only -- src/routes 2>/dev/null | sed -n 's|^src/routes/\([^/]*\)/.*|\1|p' | sort -u || true)
    if [ -n "$CHANGED" ]; then echo "$CHANGED" | xargs node scripts/build.mjs; fi
  else
    # unborn HEAD (first commit): build everything buildable
    node scripts/build.mjs --all
  fi
fi

git add -A
git diff --cached --quiet && { echo "ship: nothing to commit"; exit 0; }
git commit -m "$MSG"

[ "$SYNC" = 1 ] && git pull --rebase origin "$(git branch --show-current)"

if [ "$NOPUSH" = 0 ]; then
  # Honor CLAUDE_AUTO_PUSH_TO_MAIN (from .claude/settings.json env). Set to false
  # at the start of a session to push only the current branch, never to main.
  # Defaults to true (legacy behavior). --force-push overrides for THIS call only
  # (does not touch settings.json — the env toggle is unchanged for later calls).
  AUTO_PUSH="${CLAUDE_AUTO_PUSH_TO_MAIN:-true}"
  if [ "$AUTO_PUSH" != "true" ] && [ "$FORCEPUSH" = 0 ]; then
    echo "ship: CLAUDE_AUTO_PUSH_TO_MAIN=false; skipping push (set to true, or pass --force-push, to enable)" >&2
    exit 0
  fi
  [ "$AUTO_PUSH" != "true" ] && [ "$FORCEPUSH" = 1 ] && echo "ship: --force-push overriding CLAUDE_AUTO_PUSH_TO_MAIN=false for this push" >&2

  # Cross-route gate: if a scope-lock exists, check that no edits fall outside
  # the locked route's allowlist (src/routes/<locked>/** and .claude/memory/**).
  # Override with @allow-cross-route in the commit message.
  CWD_HASH=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
  SCOPE_FILE="/tmp/claude-scope-$CWD_HASH"

  if [ -f "$SCOPE_FILE" ]; then
    LOCKED_ROUTE=$(cat "$SCOPE_FILE")
    ROUTE_DIR="src/routes/$LOCKED_ROUTE"

    # Collect files changed in this commit
    CHANGED_FILES=$(git diff HEAD~1 --name-only 2>/dev/null || true)
    VIOLATIONS=""

    for file in $CHANGED_FILES; do
      # Violations: not in route dir and not in .claude/memory/
      if [[ ! "$file" =~ ^$ROUTE_DIR/ ]] && [[ ! "$file" =~ ^\.claude/memory/ ]]; then
        VIOLATIONS="$VIOLATIONS$file"$'\n'
      fi
    done

    if [ -n "$VIOLATIONS" ]; then
      # Cross-route changes detected — check for override marker
      if ! [[ "$MSG" =~ @allow-cross-route ]]; then
        echo "ship: scope violation — commit touches files outside '$LOCKED_ROUTE':" >&2
        echo "$VIOLATIONS" >&2
        echo "ship: include @allow-cross-route in your prompt + commit message to allow cross-route edits" >&2
        exit 2
      fi
      echo "ship: cross-route override (@allow-cross-route) detected, proceeding" >&2
    fi
  fi

  BR="$(git branch --show-current)"
  for delay in 0 2 4 8 16; do
    sleep "$delay"
    git push -u origin "$BR" && exit 0
    echo "ship: push failed, retrying in $((delay*2))s..." >&2
  done
  echo "ship: push failed after retries" >&2; exit 1
fi
