# Mode 4 — continue an existing route

Resume work on a route that already exists.

- **allowlist:** `src/routes/<route>/` (the locked route only)
  ```
  H=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
  printf '%s\n' src/routes/<route>/ > /tmp/claude-mode-$H
  echo "/<route>" > /tmp/claude-scope-$H   # route lock
  ```
- **read-set:** `.claude/memory/INDEX.md` + `routes/<route>.md` map ONLY, then anchor-navigate into code (project-memory §2–4).
- **skills:** gate on the store (see `.claude/skills-store/MODE-SHORTLISTS.md` row for this mode); loadout varies by task.
- **guardrails:**
  - If the route is ambiguous, ask (`AskUserQuestion` built from INDEX's route table) — never re-infer silently mid-session.
  - Peek other routes' MAPS freely; touch their CODE only via a `shared/` pointer or explicit request.
  - Re-read `/tmp/claude-scope-$H` after any context compaction to recover the lock.
