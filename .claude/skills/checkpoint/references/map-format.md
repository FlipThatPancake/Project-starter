# Memory file format spec

## Files & caps
| file | cap (lines) | contains |
|---|---|---|
| `INDEX.md` | 60 | `state:` line, route table, shared registries, global gotchas (max 8) |
| `routes/<route>.md` | 100 | header line, pointer line, Sections table, Hot elements, Priorities, Recent decisions (cap 10), route gotchas (max 10, inside Sections gotcha column or a Gotchas block) |
| `shared/<id>.md` | 80 | tokens/patterns tables; NEVER concrete values duplicated from code — names + pointers only |
| `ref/<topic>.md` | none | deep/rare material, loaded on demand only |
| `SESSION-LOG.md` | 40 | one row per session: date, branch, mode, one-line scope (see `.claude/modes/README.md` §Branch & log); newest first, evict oldest |

## INDEX state line (required, line 2)
`state: starter` (fresh/unbootstrapped) or `state: in-progress` (real project);
flipped once by new-project mode on first bootstrap. Unrelated to scope — structure
is ALWAYS route-based (`src/routes/<name>/`, even a single-file artifact is one
route) and scope-lock is driven by ROUTE COUNT (≥2 routes → lock one per session).
Checkpoint never changes this line.

## Portal-manifest convention
When a hub/home route lists other routes (titles, statuses, links), those facts are shared
data: keep them in `shared/data-portal-manifest.md` (used-by: hub + every listed route),
updated at /checkpoint when a route's public facts change. Hub work then never needs to
read other routes' code.

## Route map threshold
A route earns its own `routes/<r>.md` file when ANY of: >300 lines of code, >5 mapped sections, ≥1 gotcha, edited in ≥2 sessions. Otherwise it stays a one-row stub in INDEX.md with `map: —`.

## Required section order (route map)
1. `# /<route> — <path> (<one-line shape note>)`
2. `uses:` pointer line (shared design/data ids with file paths)
3. `## Sections` table: `| section | anchor(s) | gotcha |`
4. `## Hot elements` (bullets, ≤6)
5. `## Priorities / planned` (≤6 lines, done items deleted)
6. `## Recent decisions (cap 10, newest first)` — `- YYYY-MM-DD <decision>`

## Writing style
- Tables over prose (~15 vs ~40 tokens per fact). Prose ONLY for gotchas where compression would lose the lesson.
- Reference token/anchor NAMES, never duplicate values from code.
- Dates ISO. Newest first in decisions.

## Shared-file rule
Facts shared by ≥2 routes live ONLY in `shared/`; route maps point (`uses: design-m3 (shared/design-m3.md)`) but never copy.
