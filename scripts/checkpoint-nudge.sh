#!/usr/bin/env bash
# Stop-hook: deterministic /checkpoint recommender. Costs ZERO model tokens —
# runs as a shell command each time Claude stops, measures change volume since
# the last checkpoint commit, and injects a one-line nudge only when thresholds
# are crossed (≥5 source files, ≥150 lines, or an added/edited/removed @anchor
# line, or a new file), at most
# once per hour per repo.
set -u
cd "$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0

# skill loadout drift → recommend the skill-curator skill (own hourly stamp).
# Model v3: a skill is "registered" iff its own SKILL.md carries name+description
# frontmatter (no policy field, no central CATALOG). Missing either = drift. Skips
# the active copy of a skill whose store master already covers the name (shadowing).
if [ -d .claude/skills ]; then
  DRIFT=""
  for d in .claude/skills/*/ .claude/skills-store/skill-storage/*/; do
    [ -d "$d" ] || continue
    f="$d/SKILL.md"
    if [ ! -f "$f" ] || ! grep -q '^name:' "$f" || ! grep -q '^description:' "$f"; then
      DRIFT="${DRIFT:+$DRIFT, }$(basename "$d")"
    fi
  done
  if [ -n "$DRIFT" ]; then
    SSTAMP="/tmp/skill-drift-$(pwd | cksum | cut -d' ' -f1)"
    slast=$(cat "$SSTAMP" 2>/dev/null || echo 0)
    snow=$(date +%s)
    if [ $((snow - slast)) -ge 3600 ]; then
      date +%s > "$SSTAMP"
      printf '{"systemMessage":"\\ud83e\\udde9 Skill loadout drift: %s missing name/description frontmatter."}\n' "$DRIFT"
      exit 0
    fi
  fi
fi

# third-party skill update staleness → nudge (ZERO network here — reads only LOCK's local date; once/day)
LOCK=".claude/skills-store/LOCK.md"
if [ -f "$LOCK" ] && grep -q 'github:' "$LOCK"; then
  lc=$(grep -m1 '^last-checked:' "$LOCK" | sed 's/last-checked:[[:space:]]*//')
  lcs=$(date -d "$lc" +%s 2>/dev/null || echo 0)
  now=$(date +%s)
  if [ "$lcs" -gt 0 ] && [ $(( (now - lcs) / 86400 )) -ge 7 ]; then
    USTAMP="/tmp/skill-update-$(pwd | cksum | cut -d' ' -f1)"
    ulast=$(cat "$USTAMP" 2>/dev/null || echo 0)
    if [ $((now - ulast)) -ge 86400 ]; then
      date +%s > "$USTAMP"
      days=$(( (now - lcs) / 86400 ))
      printf '{"systemMessage":"\\ud83d\\udd04 Third-party skills unchecked for %s days. Run the skill-curator skill: check-updates (detection only, never auto-applies)."}\n' "$days"
      exit 0
    fi
  fi
fi

# rate-limit: one nudge per hour
STAMP="/tmp/checkpoint-nudge-$(pwd | cksum | cut -d' ' -f1)"
if [ -f "$STAMP" ]; then
  last=$(cat "$STAMP" 2>/dev/null || echo 0)
  now=$(date +%s)
  [ $((now - last)) -lt 3600 ] && exit 0
fi

# baseline = last checkpoint commit, else root commit
BASE=$(git log --grep='chore(memory): checkpoint' --format=%H -1 2>/dev/null)
[ -z "$BASE" ] && BASE=$(git rev-list --max-parents=0 HEAD 2>/dev/null | tail -1)
[ -z "$BASE" ] && exit 0

# committed + working-tree changes vs baseline, excluding generated/memory paths
EXCL=(':!dist' ':!.claude/memory' ':!*.lock')
FILES=$(git diff "$BASE" --name-only -- . "${EXCL[@]}" 2>/dev/null | wc -l)
LINES=$(git diff "$BASE" --shortstat -- . "${EXCL[@]}" 2>/dev/null \
  | grep -oE '[0-9]+ (insertion|deletion)' | grep -oE '[0-9]+' | paste -sd+ - | bc 2>/dev/null || echo 0)
NEWANCHOR=$(git diff "$BASE" -- '*.html' '*.css' '*.js' '*.mjs' 2>/dev/null | grep -c '^+.*@\(sec\|css\|js\):' || true)
# deleted/renamed/edited anchored lines diff as '-' lines; a pure edit shows as
# +1/-1, which is intentionally conservative — an anchored line changing may
# mean the map needs updating
DELANCHOR=$(git diff "$BASE" -- '*.html' '*.css' '*.js' '*.mjs' 2>/dev/null | grep -c '^-.*@\(sec\|css\|js\):' || true)
NEWFILE=$(git diff "$BASE" --name-only --diff-filter=A -- src 2>/dev/null | wc -l)

REASON=""
[ "${FILES:-0}" -ge 5 ] && REASON="$FILES source files changed"
[ "${LINES:-0}" -ge 150 ] && REASON="${REASON:+$REASON, }$LINES lines changed"
[ "${NEWANCHOR:-0}" -ge 1 ] && REASON="${REASON:+$REASON, }$NEWANCHOR new/edited anchor line(s)"
[ "${DELANCHOR:-0}" -ge 1 ] && REASON="${REASON:+$REASON, }$DELANCHOR removed anchor line(s)"
[ "${NEWFILE:-0}" -ge 1 ] && REASON="${REASON:+$REASON, }$NEWFILE new src file(s)"
[ -z "$REASON" ] && exit 0

date +%s > "$STAMP"
printf '{"systemMessage":"\\ud83d\\udccd Memory checkpoint recommended: %s since the last checkpoint commit. Run /checkpoint to update .claude/memory/."}\n' "$REASON"
exit 0
