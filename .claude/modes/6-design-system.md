# Example scope: design-system / shared files

Work on the shared design system and other shared assets that multiple routes
opt into.

- **scope:** `src/shared/`
  ```
  H=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
  printf '%s\n' src/shared/ > /tmp/claude-scope-$H
  ```
- **read-set:** `.claude/memory/INDEX.md` + the shared registry file(s) in `.claude/memory/shared/` + the maps of routes that consume the tokens (to gauge blast radius). Not route code.
- **skills:** opt-in — design-judgement skills are the point here, so load whatever the shared system's decisions need.
- **guardrails:**
  - A token change ripples to every consuming route — check the shared registry's `used-by` before editing.
  - Load `anti-slop-preflight` (dormant) and run it before finalizing any visual change.
  - Cross-route by nature: verifying a change against a consuming route is advisory (allowed with a nudge). If you set the enforce flag, use `@allow-cross-route` in the commit message.
  - Route-local styling belongs in the route (new-route / continue-route), not here.
