#!/usr/bin/env bash
# skillctl.sh — deterministic skill loadout ops; the model decides WHAT, this does the moving.
# Usage: skillctl.sh status | load <name>... | unload <name>... | unload --all
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
ACTIVE=.claude/skills; STORE=.claude/skills-store; SHELF="$STORE/skill-storage"; CAT="$STORE/CATALOG.md"
[ -f "$CAT" ] || { echo "skillctl: $CAT missing — catalog required"; exit 2; }
mkdir -p "$SHELF"

policy_of() { awk -F'|' -v s=" $1 " '$2==s {gsub(/ /,"",$5); print $5; exit}' "$CAT"; }

cmd="${1:-status}"; shift || true
case "$cmd" in
  status)
    echo "== active ($ACTIVE):"
    for d in "$ACTIVE"/*/; do
      n=$(basename "$d"); p=$(policy_of "$n")
      printf '  %-24s %s\n' "$n" "${p:-!! NOT IN CATALOG — drift}"
    done
    echo "== dormant ($SHELF):"
    found=0
    for d in "$SHELF"/*/; do
      [ -d "$d" ] || continue; found=1; n=$(basename "$d")
      printf '  %-24s %s\n' "$n" "$(policy_of "$n")"
    done
    [ "$found" = 1 ] || echo "  (store empty)"
    ;;
  load)
    [ $# -ge 1 ] || { echo "skillctl: load needs skill names"; exit 2; }
    for n in "$@"; do
      [ -d "$SHELF/$n" ] || { echo "skillctl: '$n' not in store"; exit 1; }
      [ -e "$ACTIVE/$n" ] && { echo "skillctl: '$n' already active"; exit 1; }
      mv "$SHELF/$n" "$ACTIVE/$n" && echo "loaded: $n (live immediately)"
    done
    ;;
  unload)
    [ $# -ge 1 ] || { echo "skillctl: unload needs names or --all"; exit 2; }
    if [ "$1" = "--all" ]; then set -- $(ls "$ACTIVE"); fi
    for n in "$@"; do
      [ -d "$ACTIVE/$n" ] || { echo "skillctl: '$n' not active — skipped"; continue; }
      p=$(policy_of "$n")
      case "$p" in
        pinned|ride-along) echo "refused: $n is $p — stays loaded";;
        *) mv "$ACTIVE/$n" "$SHELF/$n" && echo "unloaded: $n";;
      esac
    done
    ;;
  check-updates)
    # Detection only — compares pinned SHA to upstream HEAD (cheap: ls-remote, no fetch).
    # Only pays for a date lookup (shallow clone) on skills where a diff is actually found.
    LOCK="$STORE/LOCK.md"
    [ -f "$LOCK" ] || { echo "skillctl: no LOCK.md — no third-party skills tracked"; exit 0; }
    rows=$(awk -F'|' 'NF>=7 && $4 ~ /[0-9a-f]/ {n=$2;s=$3;p=$4;d=$5; gsub(/^ +| +$/,"",n);gsub(/^ +| +$/,"",s);gsub(/^ +| +$/,"",p);gsub(/^ +| +$/,"",d); if(n!="skill") print n"|"s"|"p"|"d}' "$LOCK")
    if [ -z "$rows" ]; then echo "skillctl: LOCK.md tracks no third-party skills yet"; else
      echo "$rows" | while IFS='|' read -r name src pin ourdate; do
        [ -z "$name" ] && continue
        url=$(printf '%s' "$src" | sed 's#^github:#https://github.com/#')
        remote=$(git ls-remote "$url" HEAD 2>/dev/null | awk '{print $1}')
        if [ -z "$remote" ]; then echo "  $name: could not reach $url (network/proxy) — skipped"
        else case "$remote" in
          "$pin"*) echo "  $name: up to date ($pin, $ourdate)";;
          *)
            tmp=$(mktemp -d); newdate="?"
            git clone --depth 1 -q "$url" "$tmp" 2>/dev/null && newdate=$(git -C "$tmp" log -1 --format=%cI 2>/dev/null || echo "?")
            rm -rf "$tmp"
            echo "  $name: UPDATE available — ours: $pin ($ourdate)  latest: ${remote:0:12} ($newdate) — review with: skill-manager update $name"
            ;;
          esac
        fi
      done
    fi
    today=$(date +%Y-%m-%d); sed -i "s/^last-checked:.*/last-checked: $today/" "$LOCK" 2>/dev/null || true
    ;;
  pin)
    # Resolve a source to exact, deterministic provenance for a LOCK.md row (used by add/update).
    [ $# -ge 1 ] || { echo "skillctl: pin needs a source (github:owner/repo or URL)"; exit 2; }
    url=$(printf '%s' "$1" | sed 's#^github:#https://github.com/#')
    full=$(git ls-remote "$url" HEAD 2>/dev/null | awk '{print $1}')
    [ -n "$full" ] || { echo "skillctl: could not reach $url"; exit 1; }
    tmp=$(mktemp -d); date="?"
    git clone --depth 1 -q "$url" "$tmp" 2>/dev/null && date=$(git -C "$tmp" log -1 --format=%cI 2>/dev/null || echo "?")
    rm -rf "$tmp"
    printf 'sha=%s short=%s date=%s\n' "$full" "${full:0:12}" "$date"
    ;;
  *) echo "usage: skillctl.sh status | load <n>... | unload <n>... | unload --all | check-updates | pin <source>"; exit 2;;
esac
