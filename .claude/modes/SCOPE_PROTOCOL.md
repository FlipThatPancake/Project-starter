# SESSION SCOPE — declare one at session start, before any code read

Every session opens by declaring a **scope**: a free-form set of path prefixes this
session intends to write. Scope is orientation, not a cage — it sets the read-set,
picks skills, and gives the guard something to nudge against. It replaces the old
fixed 7-mode menu, which assumed one project shape (a multi-route UI app with a
shared design system) and had no slot for data/ingest or cross-cutting work — so its
write wall got overridden on every project that wasn't that shape.

## The scope model (single source of truth: `scripts/scope-guard-hook.sh`)
- **Write is checked, not walled.** The declared scope (`/tmp/claude-scope-$H`, a
  newline list of path prefixes; a lone `*` = whole repo) is **ADVISORY by default**:
  an out-of-scope Edit/Write is ALLOWED, with a one-line nudge surfaced to Claude and
  the user. Legitimate cross-scope work (shared files, assets, docs, a data layer)
  proceeds with no override dance. `.claude/**` is always in scope.
- **Hard enforcement is opt-in.** `touch /tmp/claude-scope-enforce-$H` flips the guard
  to **BLOCKING**: an out-of-scope Edit/Write returns exit 2 until you widen the scope
  or clear the flag. Raise it deliberately when you want the deterministic,
  before-review guarantee the wall uniquely provides — e.g. tightly-scoped
  route-local work on a big multi-route project, where an accidental cross-route edit
  is the real risk. On most work you won't set it.
- **Read is never gated.** Token discipline comes from **lazy reading**, not walls:
  read only what the current step needs. At session start read ONLY
  `.claude/memory/INDEX.md` (+ your route's map). The session-start hook injects the
  skill index for free — never read a catalog to learn what exists.
- **The commit gate mirrors this** (`scripts/ship.sh`): a cross-scope commit is
  advisory (warn + proceed) by default, and blocked only when the enforce flag is set,
  unless the message carries `@allow-cross-route`.

## Opening protocol (every session)
1. **Determine repo state** — the `state:` line in `.claude/memory/INDEX.md`:
   `starter` = fresh/unbootstrapped (the mother `Project-starter` repo stays this) →
   a fresh bootstrap usually declares `*`; `in-progress` = a real project → declare
   the scope the task needs.
2. **Restate the session's purpose in one line, then declare a scope.** If the first
   prompt is explicit and unambiguous, state your understanding + the scope and
   proceed; in every other case (empty, vague, multi-intent) restate and WAIT for
   confirmation (`AskUserQuestion`) — never assume.
3. **Lock the scope** so the guard can orient:
   ```
   H=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
   printf '%s\n' <prefixes> > /tmp/claude-scope-$H      # '*' = whole repo
   # optional hard wall (blocks out-of-scope Edit/Write until removed):
   #   touch /tmp/claude-scope-enforce-$H
   ```
   State one line: `Scope: <slug> — <prefixes>`.
4. **Skills are opt-in** — the session-start hook already injected the index. Load a
   dormant skill only when the task needs it or the user asks: `/skills load <name>`
   (reading skill-curator's SKILL.md is only for install/update/extract/delete).
5. **Make the scope explicit** (§Branch & log) — the persistent record of what each
   session/branch scoped on.

**Address, don't act:** acknowledge the substance of the request as soon as
understood (e.g. "that already exists — here's its state"), but hold off *executing*
changes until the scope is declared (step 3). Acknowledging is not acting.

## Branch & log — making the scope explicit outside the conversation
- **A. Branch name (only when Claude creates the branch).** Most web sessions are
  handed an already-created, harness-tracked branch before the scope is known —
  **never rename it** (breaks tracking). Only when you create a branch from scratch
  do you name it `<scope-slug>/<short-desc>`, e.g. `system-dev/scope-guard-fix`.
- **B. `.claude/memory/SESSION-LOG.md` (always).** On scope lock, append one row:
  `| <date> | <branch> | <scope> | <one-line purpose> |`. This is the reliable,
  harness-independent record — read this, not the branch name, to know what a past
  session did.
- **C. Commit prefix (always).** Prefix the first commit line `[scope:<slug>]`, e.g.
  `[scope:system-dev] rewrite the scope guard`. Cheap, permanent, greppable.

## Example scopes (templates in `.claude/modes/*.md`, NOT a menu)
Worked examples you can crib from — declaring a scope that isn't among these is
normal, not an exception. Each file carries the scope prefixes + the guardrails that
tend to matter for that kind of work.
| example file | typical prefixes |
|---|---|
| `1-system-dev.md` | `.claude/ scripts/ tests/ CLAUDE.md README.md` |
| `2-new-project.md` | `*` |
| `3-new-route.md` | `src/routes/<route>/` |
| `4-continue-route.md` | `src/routes/<route>/` |
| `5-backend-routing.md` | `src/ scripts/` |
| `6-design-system.md` | `src/shared/` |
| `7-other.md` | whatever the task names |
| `8-data-ingest.md` | `data/ refs/ src/shared/schema/` |

Only work ON the meta-surface itself — the hooks, `scripts/`, mode files,
skill-curator's own SKILL.md — carries a real constraint (it's what the `system-dev`
example scope is for); that's guardrail discipline, not a separate lock.

## Hard rule
No explicit instruction ⇒ no assumption ⇒ ask. Prefer one scoped `AskUserQuestion`
over guessing which files, which stack, or which scope.
