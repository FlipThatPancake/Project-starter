# Example scope: continue-route

Resume work on a route that already exists.

- **scope:** `src/routes/<route>/`
  ```
  H=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
  printf '%s\n' src/routes/<route>/ > /tmp/claude-scope-$H
  echo "/<route>" > /tmp/claude-route-scope-$H   # project-memory route lock (read-navigation)
  ```
- **read-set:** `.claude/memory/INDEX.md` + `routes/<route>.md` map ONLY, then anchor-navigate into code (project-memory §2–4).
- **skills:** opt-in — loadout varies by task; `anti-slop-preflight` (dormant) is worth loading if the resumed work touches visuals.
- **guardrails:**
  - If the route is ambiguous, ask (`AskUserQuestion` built from INDEX's route table) — never re-infer silently mid-session.
  - Peek other routes' MAPS freely; touching their CODE is advisory (allowed with a nudge) — do it via a `shared/` pointer or on explicit request, not by drift.
  - Re-read `/tmp/claude-scope-$H` (and `/tmp/claude-route-scope-$H`) after any context compaction to recover the scope.
