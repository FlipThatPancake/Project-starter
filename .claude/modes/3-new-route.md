# Mode 3 — new route

Scaffold and build ONE new route in an existing project.

- **allowlist:** `src/routes/<route>/` (the new route only)
  ```
  H=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
  printf '%s\n' src/routes/<route>/ > /tmp/claude-mode-$H
  echo "/<route>" > /tmp/claude-route-scope-$H   # also set the route lock
  ```
- **read-set:** `.claude/memory/INDEX.md` only, then bootstrap the route (project-memory §6). No other route maps.
- **skills:** opt-in, same as every mode — this is visual work, so `anti-slop-preflight` (dormant) is usually worth loading before finalizing; load anything else the route's design needs.
- **guardrails:**
  - Ask for the route name/purpose if not given — don't invent one.
  - `cp -r src/routes/_skeleton src/routes/<route>`, add the row to `INDEX.md`, give it a `routes/<route>.md` map once it earns one.
  - Shared files (`src/shared/**`) are out of scope here — that's mode 6.
