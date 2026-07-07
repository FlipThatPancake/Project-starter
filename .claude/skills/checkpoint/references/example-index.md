# EXAMPLE — canonical INDEX.md shape (multi-route). Match this exactly.

```markdown
# MEMORY INDEX — read first; then ONLY your route's map + the shared files its pointer rows name
state: in-progress

## Routes
| route | path | status | map | design | data-deps |
|---|---|---|---|---|---|
| /survey-jun26 | jun26/index.html | live | routes/survey-jun26.md | design-m3 | — |
| /survey-sep26 | sep26/index.html | wip | routes/survey-sep26.md | design-m3 | data-respondents |
| /landing | landing/index.html | live | routes/landing.md | design-brand | — |
| /privacy | privacy.html | live | — (stub: static page, no JS) | none | — |

## Shared registries
| id | file | used-by |
|---|---|---|
| design-m3 | shared/design-m3.md | survey-jun26, survey-sep26 |
| design-brand | shared/design-brand.md | landing |
| data-respondents | shared/data-respondents.md | survey-sep26 |

## Global gotchas (never evicted; max 8)
- Never Read a route's dist/*.html — generated; sources only.
- Flags are flagcdn SVGs via flagSvg(); Unicode flag emoji render blank on Windows.
```

Notes on the shape (do not copy into real files):
- `state:` on line 2 — `starter` (fresh/unbootstrapped) or `in-progress` (real project); flipped once by new-project mode. Scope-lock is driven by route COUNT, not this line.
- One row per route, no prose. A route without complexity stays a stub row (`map: —`).
- A hub/home route's list of other routes belongs in `shared/data-portal-manifest.md`, not in code peeks.
- `used-by` in shared registries is maintained BOTH ways: route map points at shared file, shared registry lists users.
- Global gotchas = cross-route only; route-specific gotchas live in the route map.
