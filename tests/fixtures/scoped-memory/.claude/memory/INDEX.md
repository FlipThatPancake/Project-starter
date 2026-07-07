# MEMORY INDEX — read first; then ONLY your route's map + the shared files its pointer rows name
state: in-progress

## Routes
| route | path | status | map | design | data-deps |
|---|---|---|---|---|---|
| /app | app.html | live | routes/app.md | design-x | — |
| /other | other.html | live | routes/other.md | none | — |

## Shared registries
| id | file | used-by |
|---|---|---|
| design-x | shared/design-x.md | app |

## Global gotchas (never evicted; max 8)
- Never Read a route's dist/*.html — generated; sources only.
