# Mode 5 — backend / routing / page structure

Work on the app's structure: routing, the shell, build wiring, how routes fit
together. Inherently cross-route.

- **allowlist:** `src/` · `scripts/` (structural + build)
  ```
  H=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
  printf '%s\n' src/ scripts/ > /tmp/claude-mode-$H
  ```
- **read-set:** `.claude/memory/INDEX.md` + every affected route's map (this is the one mode that legitimately reads across routes) + any `shared/` registry the change touches.
- **skills:** opt-in, same as every mode — this mode is routing/plumbing, not visual, so the active baseline is usually enough; load a store skill only if a specific task needs one.
- **guardrails:**
  - Cross-route by design — but say so: use `@allow-cross-route` in the prompt and the final commit message (the ship-time gate checks for it).
  - Don't do route-content work here; that's modes 3/4. This mode is plumbing.
  - Run `node scripts/validate.mjs --all` before shipping — structural changes ripple.
