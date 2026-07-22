#!/usr/bin/env bash
# ship.sh — validate → build changed routes → commit → push (with retry).
# Usage: scripts/ship.sh "commit message" [--no-validate] [--no-build] [--no-push] [--all] [--deep] [--sync] [--to-main]
# Validation is SCOPED to changed routes by default (cheap on a big portal);
# --deep (or --all) forces a full-portal audit.
# --to-main: explicit opt-in ONLY. After the branch push succeeds, merges this
# branch into origin/main via a disposable local temp branch (--no-ff, so the
# merge is visible in history) and pushes that. Never force-pushes; on conflict
# or a race (main moved since fetch), the temp branch is left for inspection
# and nothing is force-applied. Does NOT run without a successful branch push
# first (so --to-main + --no-push is rejected).
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

MSG="${1:-}"; shift || true
[ -z "$MSG" ] && { echo "ship: commit message required" >&2; exit 2; }
NOVAL=0 NOBUILD=0 NOPUSH=0 ALL=0 DEEP=0 SYNC=0 TOMAIN=0
for a in "$@"; do case "$a" in
  --no-validate) NOVAL=1;; --no-build) NOBUILD=1;; --no-push) NOPUSH=1;;
  --all) ALL=1;; --deep) DEEP=1;; --sync) SYNC=1;;
  --to-main) TOMAIN=1;;
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
    # rebuild only routes whose src changed vs HEAD (incl. uncommitted);
    # skip templates (_skeleton) and dotfiles, same filter as build.mjs --all
    CHANGED=$(git diff HEAD --name-only -- src/routes 2>/dev/null | sed -n 's|^src/routes/\([^/]*\)/.*|\1|p' | grep -v '^[_.]' | sort -u || true)
    if [ -n "$CHANGED" ]; then echo "$CHANGED" | xargs node scripts/build.mjs; fi
  else
    # unborn HEAD (first commit): build everything buildable
    node scripts/build.mjs --all
  fi
fi

git add -A

# F9 guard: never commit an embedded git repo (gitlink, mode 160000) — e.g. a stray
# agent worktree swept in by `git add -A`. A silent gitlink is a broken clone; a
# blocked commit is recoverable. Fix by `git rm --cached <path>` or .gitignore.
GITLINKS=$(git ls-files -s | awk '$1=="160000"{print $4}')
if [ -n "$GITLINKS" ]; then
  echo "ship: refusing to commit embedded git repo(s) (gitlink):" >&2
  echo "$GITLINKS" | sed 's/^/  /' >&2
  echo "ship: remove with 'git rm --cached <path>' or add the path to .gitignore" >&2
  exit 2
fi

# Cross-scope commit gate — runs BEFORE the commit (so --no-push commits are gated
# too). Mirrors scope-guard-hook.sh's posture: if a session scope is declared,
# staged files outside it are ADVISORY by default (warn and proceed — legitimate
# cross-scope commits touching shared/route/data don't need a ceremony), and
# BLOCKED only when the enforce flag is set, unless the message carries
# @allow-cross-route. Scope source mirrors the hook: the declared-scope file
# preferred, the legacy route lock as fallback; .claude/** is always in scope.
CWD_HASH=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
SCOPE_FILE="/tmp/claude-scope-$CWD_HASH"
ROUTE_LOCK="/tmp/claude-route-scope-$CWD_HASH"
ENFORCE_FLAG="/tmp/claude-scope-enforce-$CWD_HASH"

_in_scope() {   # returns 0 if $1 (repo-relative path) is within the declared scope
  local p="$1"
  [[ "$p" =~ ^\.claude/ ]] && return 0
  if [ -f "$SCOPE_FILE" ]; then
    local pref
    while IFS= read -r pref; do
      [ -z "$pref" ] && continue
      [ "$pref" = "*" ] && return 0
      [[ "$p" == "$pref"* ]] && return 0
    done < "$SCOPE_FILE"
    return 1
  elif [ -f "$ROUTE_LOCK" ]; then
    local r; r=$(cat "$ROUTE_LOCK"); r="${r#/}"
    [[ "$p" == "src/routes/$r/"* ]] && return 0
    return 1
  fi
  return 0   # no scope declared → everything in scope
}

if [ -f "$SCOPE_FILE" ] || [ -f "$ROUTE_LOCK" ]; then
  VIOLATIONS=""
  for file in $(git diff --cached --name-only 2>/dev/null || true); do
    _in_scope "$file" || VIOLATIONS="$VIOLATIONS  $file"$'\n'
  done
  if [ -n "$VIOLATIONS" ]; then
    if [ -f "$SCOPE_FILE" ]; then ALLOWED=$(paste -sd' ' "$SCOPE_FILE" 2>/dev/null)
    else ALLOWED="src/routes/$(sed 's#^/##' "$ROUTE_LOCK" 2>/dev/null)/"; fi
    if [ -f "$ENFORCE_FLAG" ] && ! [[ "$MSG" =~ @allow-cross-route ]]; then
      echo "ship: scope violation (enforcing) — commit touches files outside declared scope [$ALLOWED]:" >&2
      printf '%s' "$VIOLATIONS" >&2
      echo "ship: add @allow-cross-route to the commit message, or remove /tmp/claude-scope-enforce-$CWD_HASH to drop to advisory" >&2
      exit 2
    fi
    echo "ship: note (advisory) — commit touches files outside declared scope [$ALLOWED], proceeding:" >&2
    printf '%s' "$VIOLATIONS" >&2
  fi
fi

git diff --cached --quiet && { echo "ship: nothing to commit"; exit 0; }
git commit -m "$MSG"

[ "$SYNC" = 1 ] && git pull --rebase origin "$(git branch --show-current)"

if [ "$NOPUSH" = 0 ]; then
  # Pushes to the CURRENT branch only. main is reached exclusively via the
  # ship-now skill (GitHub PR merge), or --to-main as its confirmed fallback.
  # (Cross-route scope gate now runs pre-commit, above — F4.)
  BR="$(git branch --show-current)"
  PUSHED=0
  for delay in 0 2 4 8 16; do
    sleep "$delay"
    if git push -u origin "$BR"; then PUSHED=1; break; fi
    echo "ship: push failed, retrying in $((delay*2))s..." >&2
  done
  [ "$PUSHED" = 1 ] || { echo "ship: push failed after retries" >&2; exit 1; }
fi

if [ "$TOMAIN" = 1 ]; then
  if [ "$NOPUSH" = 1 ]; then
    echo "ship: --to-main requires the branch push to succeed first — remove --no-push" >&2
    exit 2
  fi
  BR="$(git branch --show-current)"
  if [ "$BR" = "main" ]; then
    echo "ship: already on main — --to-main merges a feature branch INTO main, nothing to do" >&2
  else
    echo "ship: --to-main — merging '$BR' into main on origin" >&2
    git fetch origin main
    TMP="_ship_to_main_$$"
    git branch -f "$TMP" origin/main
    git checkout -q "$TMP"
    if git merge --no-ff "$BR" -m "Merge branch '$BR' into main (ship.sh --to-main)"; then
      if git push origin "$TMP:main"; then
        echo "ship: main updated with '$BR'" >&2
        git checkout -q "$BR"
        git branch -D "$TMP" >/dev/null 2>&1 || true
      else
        echo "ship: push to main failed (main may have moved since fetch) — merge kept on local branch '$TMP' for inspection; fetch and retry" >&2
        git checkout -q "$BR"
        exit 1
      fi
    else
      git merge --abort 2>/dev/null || true
      git checkout -q "$BR"
      git branch -D "$TMP" >/dev/null 2>&1 || true
      echo "ship: merge conflict merging '$BR' into main — resolve manually: git fetch origin main && git checkout -b fix-merge origin/main && git merge $BR" >&2
      exit 1
    fi
  fi
fi
