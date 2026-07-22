# MEMORY INDEX — read first; then ONLY your route's map + the shared files its pointer rows name
state: starter
<!-- ^ `starter` = fresh/unbootstrapped (the mother Project-starter repo stays this);
     `in-progress` = a real project — the new-project bootstrap flips it on first run.
     The session-start hook branches on this. validate.mjs --memory fails if missing.
     Scope behavior is driven by route COUNT, not this line (see project-memory §0). -->

## Routes
| route | path | status | map | design | data-deps |
|---|---|---|---|---|---|
<!-- one row per route; use `— (stub: reason)` in map column until a route earns its own file -->

## Shared registries
| id | file | used-by |
|---|---|---|
<!-- add rows only when ≥2 routes share a design system or data source -->

## Global gotchas (never evicted; max 8)
- Never Read a route's dist/*.html — generated; sources only.
