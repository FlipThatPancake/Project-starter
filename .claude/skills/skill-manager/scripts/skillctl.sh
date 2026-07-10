#!/usr/bin/env bash
# skillctl.sh — deterministic skill loadout ops; the model decides WHAT, this does the moving.
# Usage: skillctl.sh status | load <name>... | unload <name>... | unload --all
#
# Model (design proposal v2 §B2/B3/B6): metadata lives in each skill's SKILL.md
# frontmatter; there is NO central CATALOG. `load` COPIES store→active (the store keeps
# the master, so the gitignored active copy can never lose it); `unload` removes the
# active copy (master stays in the store). Always-on system skills live committed in
# .claude/skills/ with no store master and cannot be unloaded here.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
ACTIVE=.claude/skills; STORE=.claude/skills-store; SHELF="$STORE/skill-storage"
mkdir -p "$SHELF"

reindex() { node scripts/gen-skill-index.mjs >/dev/null 2>&1 || true; }

# policy_of <skill> — read `policy:` from the skill's own frontmatter (active copy
# preferred, else store master). Empty if the skill or field is absent.
policy_of() {
  local f
  for f in "$ACTIVE/$1/SKILL.md" "$SHELF/$1/SKILL.md"; do
    [ -f "$f" ] && { sed -n 's/^policy:[[:space:]]*//p' "$f" | head -1; return; }
  done
}

# footprint_of <skill> — comma-separated glob list from add-and-handoff.md §2a's
# footprint table, raw (still backtick-quoted); empty if the skill has no dedicated row.
footprint_of() {
  local ref=".claude/skills/skill-manager/references/add-and-handoff.md" line
  [ -f "$ref" ] || return 1
  line=$(grep -F "| $1 |" "$ref" | head -1)
  [ -z "$line" ] && return 1
  awk -F'|' '{print $3}' <<< "$line"
}

# has_footprint <skill> — true if any of its footprint globs matches a live file
# in the project (derived from disk, never logged — same principle as load-time
# conflict detection in add-and-handoff.md §3).
has_footprint() {
  local raw globs g f matched=1
  raw=$(footprint_of "$1") || return 1
  [ -z "$raw" ] && return 1
  raw="${raw//\`/}"
  IFS=',' read -ra globs <<< "$raw"
  shopt -s nullglob
  for g in "${globs[@]}"; do
    g="$(sed 's/^[[:space:]]*//; s/[[:space:]]*$//' <<< "$g")"
    [ -z "$g" ] && continue
    for f in $g; do [ -e "$f" ] && matched=0 && break 2; done
  done
  shopt -u nullglob
  return $matched
}

cmd="${1:-status}"; shift || true
case "$cmd" in
  status)
    echo "== active ($ACTIVE):"
    for d in "$ACTIVE"/*/; do
      n=$(basename "$d"); p=$(policy_of "$n")
      printf '  %-24s %s\n' "$n" "${p:-!! no policy in frontmatter — drift}"
    done
    echo "== dormant ($SHELF, not currently active):"
    found=0
    for d in "$SHELF"/*/; do
      [ -d "$d" ] || continue; n=$(basename "$d")
      [ -e "$ACTIVE/$n" ] && continue      # active copy shadows the store master
      found=1
      printf '  %-24s %s\n' "$n" "$(policy_of "$n")"
    done
    [ "$found" = 1 ] || echo "  (none dormant)"
    ;;
  load)
    # COPY store→active (master stays in the store); the active copy is gitignored
    # unless whitelisted, so it never leaks to other branches.
    [ $# -ge 1 ] || { echo "skillctl: load needs skill names"; exit 2; }
    for n in "$@"; do
      [ -d "$SHELF/$n" ] || { echo "skillctl: '$n' not in store"; exit 1; }
      [ -e "$ACTIVE/$n" ] && { echo "skillctl: '$n' already active"; continue; }
      cp -r "$SHELF/$n" "$ACTIVE/$n" && echo "loaded: $n (live immediately)"
    done
    reindex
    ;;
  unload)
    # Remove the active COPY only (the store master remains). An always-on system
    # skill has no store master and cannot be unloaded here.
    [ $# -ge 1 ] || { echo "skillctl: unload needs names or --all"; exit 2; }
    if [ "$1" = "--all" ]; then set -- $(ls "$ACTIVE"); fi
    for n in "$@"; do
      [ -d "$ACTIVE/$n" ] || { echo "skillctl: '$n' not active — skipped"; continue; }
      p=$(policy_of "$n")
      case "$p" in
        pinned|ride-along) echo "refused: $n is $p — stays loaded"; continue;;
      esac
      if [ ! -d "$SHELF/$n" ]; then
        echo "refused: $n is a committed always-on skill (no store master) — change the .gitignore whitelist to alter its status"; continue
      fi
      rm -rf "$ACTIVE/$n" && echo "unloaded: $n (store master kept)"
    done
    reindex
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
  check-conflicts)
    # Mechanical, read-only, derived-not-logged: for each machine-parseable exclusive
    # group in CONFLICTS.md, glob each member's footprint (add-and-handoff.md §2a)
    # against THIS project. Reports which unused members should be suppressed from
    # mode-entry suggestions because an exclusive peer's footprint is already present.
    # Naming a suppressed skill explicitly still goes through the normal load-time
    # warn (add-and-handoff.md §3c) — this command only informs suggestion-building.
    CONF=".claude/skills/skill-manager/references/conflict-rulings.md"
    [ -f "$CONF" ] || { echo "skillctl: $CONF missing"; exit 0; }
    groups=$(awk '
      /^## Exclusive groups/ {f=1; next}
      f && /^## / {f=0}
      f && /^\|-+\|$/ {ds=1; next}
      f && ds && /^\|/ {print}
    ' "$CONF")
    if [ -z "$groups" ]; then
      echo "check-conflicts: no machine-readable exclusive groups yet"
      exit 0
    fi
    found_any=0
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      inner="${line#|}"; inner="${inner%|}"
      IFS=',' read -ra members <<< "$inner"
      used=(); unused=()
      for m in "${members[@]}"; do
        m="$(sed 's/^[[:space:]]*//; s/[[:space:]]*$//' <<< "$m")"
        [ -z "$m" ] && continue
        if has_footprint "$m"; then used+=("$m"); else unused+=("$m"); fi
      done
      if [ "${#used[@]}" -gt 0 ] && [ "${#unused[@]}" -gt 0 ]; then
        found_any=1
        echo "suppress: ${unused[*]} — exclusive with already-used: ${used[*]}"
      fi
    done <<< "$groups"
    [ "$found_any" = 1 ] || echo "check-conflicts: no suppressions — no exclusive-group footprints found in this project"
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
  *) echo "usage: skillctl.sh status | load <n>... | unload <n>... | unload --all | check-conflicts | check-updates | pin <source>"; exit 2;;
esac
