# MEMORY INDEX — read first; then ONLY your route's map + the shared files its pointer rows name
profile: standalone
<!-- ^ set at bootstrap: `portal` = multi-route domain, sessions lock to one route;
     `standalone` = single site/app. validate.mjs --memory fails if missing. -->

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
