# Example scope: new-route

Scaffold and build ONE new route in an existing project.

- **scope:** `src/routes/<route>/` (the new route)
  ```
  H=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
  printf '%s\n' src/routes/<route>/ > /tmp/claude-scope-$H
  echo "/<route>" > /tmp/claude-route-scope-$H   # project-memory route lock (read-navigation)
  ```
  Building a route often legitimately touches `src/shared/` (tokens) and `assets/` —
  that's fine: the guard is advisory, so those edits proceed with a nudge. Add those
  prefixes to the scope line if you want the nudge to stop.
- **read-set:** `.claude/memory/INDEX.md` only, then bootstrap the route (project-memory §6). No other route maps.
- **skills:** opt-in — this is visual work, so `anti-slop-preflight` (dormant) is usually worth loading before finalizing; load anything else the route's design needs.
- **guardrails:**
  - Ask for the route name/purpose if not given — don't invent one.
  - `cp -r src/routes/_skeleton src/routes/<route>`, add the row to `INDEX.md`, give it a `routes/<route>.md` map once it earns one.
