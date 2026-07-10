---
name: skill-manager
description: Use when the user wants to see, load, unload, install, extract, or remove skills ("what skills are available", "load gsap", "add this skill", "start a design session"), when a session needs a capability beyond the pinned set, when the Stop hook or validate --skills reports loadout drift, or on a design-judgment task when menu-policy skills are installed (run the picker). Manages .claude/skills/ (active) vs .claude/skills-store/skill-storage/ (dormant, zero context cost) — the store's root holds only metadata .md files.
policy: pinned
category: core
---

# Skill manager — loadout protocol

**Two layers (v2):** *thin mechanics* run in bash and need NO reading of this file —
`/skills list|load|unload` just moves dirs. This SKILL.md is *doctrine*: read it only
for the heavy operations (installing a NEW skill from the web, extract, update,
conflict resolution). Loading an already-stored skill never requires opening this file.

States: **active** = dir in `.claude/skills/` (in context, can trigger) · **dormant** =
dir in `.claude/skills-store/skill-storage/` (zero tokens) · **fixed** =
harness/claude.ai/plugin skills (in session context, NOT controllable here).
**Metadata model:** each skill's own `SKILL.md` frontmatter carries `policy` +
`category` (+ optional `exclusive-with`); state is derived from folder location; `size`
is computed. `.claude/skills-store/INDEX.md` is GENERATED from that
(`node scripts/gen-skill-index.mjs`) — gitignored, rebuilt at session start and after
every load/unload. There is **no central CATALOG**. Add-time doctrine lives in
`references/` (`conflict-rulings.md`, `module-index.md`, `catalog-format.md`,
`add-and-handoff.md`, `updates.md`); `skills-store/` root holds only `INDEX.md`
(generated), `LOCK.md`, `MODE-SHORTLISTS.md`, `WIKI.md`.

**Activation is COPY, not move.** `load` copies the store master into `.claude/skills/`;
the master stays in the store. The active copy is **gitignored** (except the always-on
whitelist in `.gitignore`) so a skill loaded for one task never leaks to other branches
or main. `unload` deletes the active copy; the master remains. To make a skill
permanently always-on, add a `!` line to the `.gitignore` whitelist (rare, deliberate).

## Verbs (mechanics in `.claude/skills/skill-manager/scripts/skillctl.sh` — never hand-move dirs)
| verb | do |
|---|---|
| list / status | `skillctl.sh status` (reads frontmatter, no catalog). The session-start hook already injected the INDEX, so usually no command needed |
| load <name…> | quick check: already active? exclusive-with a currently-active skill (its frontmatter)? → warn. Then `skillctl.sh load …` (copies, regenerates INDEX); live immediately. **Pack-member fast path (F7):** a sibling of an already-loaded pack (same LOCK source) → one yes/no, reuse the pin, no full add |
| unload <name…> / --all | `skillctl.sh unload …` — refuses pinned/ride-along and committed always-on skills |
| add <source> | interactive install of a NEW skill — §add below (this is the only verb that needs this file) |
| extract <parent>/<module> | carve a module into a standalone store skill — §extract |
| remove <name> | delete the store master; regenerate INDEX |
| check-updates | `skillctl.sh check-updates` — compare pinned refs (LOCK.md) to upstream HEAD; DETECTION ONLY. Stop-hook nudges when stale (>7d) |
| check-conflicts | `skillctl.sh check-conflicts` — globs `references/conflict-rulings.md` exclusive groups vs project footprints; read-only, optional (only useful if you consult MODE-SHORTLISTS) |
| update <skill> | review-gated apply — `references/updates.md`; RE-APPLY local-mods; reconcile dep files (`structcheck.sh`); never auto-apply |

## Loading is OPT-IN — no mandatory gate
The session-start hook injects the skill index for free, so the model already knows what
exists. There is **no session-start gate** that blocks work waiting for a skill decision.
Load a dormant skill only when: the task needs its capability, the user names it, or you
choose to consult `MODE-SHORTLISTS.md` for a per-mode suggestion. When the user names
skills inline, just load them. Before loading a set, check each one's `exclusive-with`
frontmatter against what's already active (and `references/conflict-rulings.md` for
not-yet-installed upstream pairs) — warn on a real conflict, otherwise proceed.

## Menu picker — per TASK, never sticky (only if menu-policy skills are installed)
Menu skills are muted (`disable-model-invocation: true`), so this picker is their only
activation path. Trigger: a design-judgment task AND menu skills installed.
- Ask per task (a new task asks fresh); skip when the user names skills or says "none".
- Read `references/conflict-rulings.md`: drop options `exclusive` with an active skill,
  present a `compatible` pair as the recommended **Combined**, let `precedence` order.
- Options (AskUserQuestion, multiSelect): first = **"Combined: <2–3 picks> (Recommended)"**;
  then individual skills/modules (`references/module-index.md`); last = "None".

## Combine protocol (when ≥2 skills/modules are chosen)
1. Read ONLY the selected guidance files. 2. **An explicit user decision (a grilled
requirement, a named brand color, a stated constraint) outranks every skill heuristic,
seed, or checklist line — mechanical, no judgment call.** Below that: project design
tokens › anti-slop-preflight › best task fit (`references/conflict-rulings.md`). Overlaps
→ keep the single best fit; unique rules → union. 3. Single-stage task → apply the merged
set at once; multistage → assign skills to stages, state the stage map in one line first.

## add <source> — interactive install of a NEW skill (the heavy path)
1. Fetch into the store (`git clone --depth 1` / curl); read frontmatter description ONLY.
2. Classify pack / deep / standalone (`references/add-and-handoff.md` §1) — a PACK
   registers members individually, never as a unit.
3. Set the new skill's frontmatter `policy` + `category` (recommend from
   `references/catalog-format.md`). **Batch path (F5):** if the user named N skills
   inline with an install directive, derive each policy/category from the source's own
   annotation and confirm ALL in ONE line — do not ask per-skill. policy=menu → also set
   `disable-model-invocation: true` in our copy.
4. Conflicts: check `references/conflict-rulings.md` + footprints (§2). `duplicate`/
   `exclusive` with something installed, or dep files already present → warn; genuinely
   new overlap → propose a rule, append once the user rules. Record `exclusive-with` in
   BOTH skills' frontmatter (symmetry — `validate --skills` enforces it).
5. Deep/pack → index notable modules in `references/module-index.md`.
6. Third-party → `skillctl.sh pin <source>`; record a `LOCK.md` row (source, short sha,
   upstream-date, install date, local-mods).
7. `node scripts/gen-skill-index.mjs` then `node scripts/validate.mjs --skills` must pass.
8. Run the **New-skill mode-fit check** below.

## New-skill mode-fit check — after every add / extract
Consider the new skill for `MODE-SHORTLISTS.md`. Read its category + description against
the 7 mode one-liners (`.claude/modes/README.md`); for each plausible fit, propose it in
one line and **wait for confirmation** (shortlist curation is a judgment call, never
silent). On confirm, update the shortlist row only — never auto-load.

## extract <parent>/<module>
Distill a module into its own store dir with frontmatter (policy+category), flip its
`references/module-index.md` status to `extracted`, leave the parent untouched. Then run
the mode-fit check. Regenerate the INDEX.

## Hard rules
- Fixed skills: report truthfully as "active — not controllable here"; never fake-unload one.
- Packs (gsap, tapestry): register/load MEMBERS individually.
- The manager never unloads itself or another pinned/ride-along skill.
- **Mode scope:** loading, unloading, and cataloguing are available in ANY mode
  (activation is local + gitignored). Only editing the *mechanics* — this file,
  `skillctl.sh`, the hooks, `.claude/modes/**` — is Mode 1 (system-dev) work.
