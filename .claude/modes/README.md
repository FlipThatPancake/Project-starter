# SESSION MODES — pick one at session start, before any code read

Every session runs in exactly ONE mode. A mode bundles four things so Claude
reads only what's relevant and never wanders:

- **allowlist** — paths the scope-guard (`scripts/scope-guard-hook.sh`) permits Edit/Write on
- **read-set** — the few files to orient from
- **skills** — the loadout offered on entry (via skill-manager)
- **guardrails** — mode-specific rules

## Selection protocol (run this first, every session)

1. **Determine repo state** — read the `state:` line in `.claude/memory/INDEX.md`:
   - `starter` → fresh/unbootstrapped (the mother `Project-starter` repo is always `starter`). Steer toward **mode 2 (new project)**.
   - `in-progress` → a real project (set the first time mode 2 runs). Offer modes 3–6.
2. **Pick the mode:**
   - **Infer ONLY when the first prompt is an explicit, unambiguous instruction** (e.g. "switch to /pricing" → mode 4; "let's build the design tokens" → mode 6; "fix the skill-manager picker" → mode 1).
   - **In EVERY other case — including an empty, vague, or multi-intent prompt — ASK.** Never assume the mode. Use `AskUserQuestion` with the 7 modes as options; keep asking scoped follow-ups until scope is unambiguous.
3. **Lock the mode** — write its allowlist so the scope-guard enforces it:
   ```
   H=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
   printf '%s\n' <allowlist prefixes from the mode file> > /tmp/claude-mode-$H
   ```
   (`.claude/memory/` is always allowed implicitly; no need to list it.)
   State one line: `Mode: <n>-<name>`.
4. **Offer skills** — on entry, skill-manager presents *(top)* the best candidates
   for this prompt, then *(below)* the full store by category, multi-select. Load
   the chosen set. (See skill-manager SKILL.md → "Mode-entry skill offer".)
5. **Read the mode file** (`.claude/modes/<n>-*.md`) and follow it.

## The 7 modes
| # | file | one-liner |
|---|---|---|
| 1 | `1-system-dev.md` | modify/test/debug the starter + skill system itself |
| 2 | `2-new-project.md` | bootstrap a fresh project: decide structure & stack |
| 3 | `3-new-route.md` | scaffold + build one new route |
| 4 | `4-continue-route.md` | resume an existing route |
| 5 | `5-backend-routing.md` | routing / page structure (cross-route) |
| 6 | `6-design-system.md` | shared design system & shared files |
| 7 | `7-other.md` | anything else — ask the user to define scope |

## Hard rule (applies to every mode)
No explicit instruction ⇒ **no assumption ⇒ ask.** Prefer one scoped
`AskUserQuestion` over guessing which files, which stack, or which route.
