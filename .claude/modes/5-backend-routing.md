# Example scope: backend-routing / page structure

Work on the app's structure: routing, the shell, build wiring, how routes fit
together. Inherently cross-route.

- **scope:** `src/ scripts/` (structural + build)
  ```
  H=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
  printf '%s\n' src/ scripts/ > /tmp/claude-scope-$H
  ```
- **read-set:** `.claude/memory/INDEX.md` + every affected route's map (this scope legitimately reads across routes) + any `shared/` registry the change touches.
- **skills:** opt-in — routing/plumbing, not visual, so the active baseline is usually enough; load a store skill only if a specific task needs one.
- **guardrails:**
  - Cross-route by design — the wide `src/` scope already covers it; if you additionally set the enforce flag, add `@allow-cross-route` to the commit message so the ship gate lets it through.
  - Don't do route-content work here; that's the new-route / continue-route scopes. This is plumbing.
  - Run `node scripts/validate.mjs --all` before shipping — structural changes ripple.
