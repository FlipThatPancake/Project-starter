# Mode 4 — continue an existing route

Resume work on a route that already exists.

- **allowlist:** `src/routes/<route>/` (the locked route only)
  ```
  H=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
  printf '%s\n' src/routes/<route>/ > /tmp/claude-mode-$H
  echo "/<route>" > /tmp/claude-route-scope-$H   # route lock
  ```
- **read-set:** `.claude/memory/INDEX.md` + `routes/<route>.md` map ONLY, then anchor-navigate into code (project-memory §2–4).
- **skills:** opt-in, same as every mode — loadout varies by task; `anti-slop-preflight` (dormant) is worth loading if the resumed work touches visuals.
- **guardrails:**
  - If the route is ambiguous, ask (`AskUserQuestion` built from INDEX's route table) — never re-infer silently mid-session.
  - Peek other routes' MAPS freely; touch their CODE only via a `shared/` pointer or explicit request.
  - Re-read `/tmp/claude-route-scope-$H` after any context compaction to recover the lock.
