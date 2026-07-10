> **v2 model change (2026-07):** the central `CATALOG.md`, `CONFLICTS.md`, and
> `MODULES.md` were retired. Skill metadata (`policy`/`category`/`exclusive-with`)
> now lives in each skill's own SKILL.md frontmatter; `.claude/skills-store/INDEX.md`
> is GENERATED (`node scripts/gen-skill-index.mjs`, gitignored). CONFLICTS.md →
> `references/conflict-rulings.md`; MODULES.md → `references/module-index.md`.
> Read "write a CATALOG row" below as "set frontmatter + regenerate the INDEX", and
> "MODULES.md" as "module-index.md". Activation COPIES store→active (gitignored).

# Catalog format + policy assignment

## Installed row shape (exact)
`| <name> | <kind> | <category> | <policy> | <load-when> |`
- name: lowercase-hyphenated, = the skill's directory name
- kind: `skill` · `pack-member` · `tool` · `reference`
- category: core · design-guardrails · design-judgment · design-process · motion · 3d-graphics · a11y-testing · deliverables · research · tools · references (add a new one only with ≥2 skills)
- policy: see decision table below
- load-when: a TRIGGER — the task situation that should reach for it, ≤10 words

## Policy decision (first match wins)
| the skill… | policy |
|---|---|
| is repo infrastructure every session depends on (memory, anchors, this manager) | pinned |
| is a guardrail the user wants on every matching task with zero prompts (checklists, a11y diff) | ride-along |
| overlaps others in its category / has a dragnet description (broad design-guidance packs) | menu — and set `disable-model-invocation: true` in our copy |
| everything else | manual |

## Module row shape (MODULES.md)
`| <module> | <parent> | <category> | referenced|extracted | <note> |`
- parent must exist in CATALOG.md (Installed or candidates); validator enforces.
- category may DIFFER from the parent's (impeccable/animate → motion); if two fit, pick primary, name the other in the note.
- referenced = load parent, read only that module's file · extracted = distilled into its own store skill via `extract`.

## Rules
- One row per skill; pack members get their own rows (`gsap-scrolltrigger`, not `gsap-skills`).
- kind=tool and kind=reference rows never get loaded — tools are executed, references are copied into projects.
- New menu skill → check the Overlap groups section; add it to its group and index notable modules in MODULES.md.
- `add` never assigns policy silently: recommend from the decision table, confirm via AskUserQuestion.
- Deleting a skill = delete dir + row + its MODULES rows together; validator flags any half-done state.
