---
name: skill-curator
description: Use ONLY for curating the skill STORE itself — installing a brand-new skill from the web, updating a vendored third-party skill, extracting a module into its own skill, or fully deleting a skill and every line that references it. NOT for loading/unloading/listing skills already in the store — that's the thin `/skills` command, no doctrine read needed. Dormant by design; load only for these heavy, infrequent operations.
group: skill-system
---

# Skill curator — install / update / extract / delete (the heavy, infrequent ops)

**Everyday loadout ops don't need this file.** `/skills list|load|unload|remove`
(`scripts/skillctl.sh`) are pure directory operations — no doctrine read. This
skill exists only for the four operations below, which involve judgment:
classifying a new source, recording conflicts, reconciling an update against a
live project, or scrubbing every reference to a skill being deleted.

**Model (v3):** each skill's own `SKILL.md` frontmatter carries `name`,
`description`, an optional one-word `group` (free-text grouping hint, not an
enum — reuse an existing value where it fits), and optional `exclusive-with`
(recorded symmetrically on both members). State is derived from location:
**active** = `.claude/skills/` (in context) · **dormant** = store
(`skills-store/skill-storage/`, zero tokens) · **fixed** = harness/claude.ai
skills, not controllable here. "Always-on" is defined solely by the
`.gitignore` whitelist — no `policy` field, no central index file. Activation
is COPY (store→active); the store keeps the master, so the gitignored active
copy never risks the only copy, and never leaks to other branches.

## install <source> — add a NEW skill from the web
1. Fetch into the store (`git clone --depth 1` / curl); read frontmatter
   `description` ONLY, not the full body, to keep this cheap.
2. Classify pack / deep / standalone — `references/add-and-handoff.md` §1. A
   PACK registers members individually, never as a unit.
3. Set `group` on the new skill's frontmatter (reuse an existing value if one
   fits; state your pick in one line — no formal approval table needed).
   Multiple skills named inline with one install directive → derive each
   `group` from the source's own framing and confirm ALL in one line, not
   per-skill.
4. Conflicts: check `references/conflict-rulings.md` + footprints
   (§2 of add-and-handoff.md). `duplicate`/`exclusive` with something
   installed, or dep files already present → warn; genuinely new overlap →
   propose a rule, append once the user rules. Record `exclusive-with` in
   BOTH skills' frontmatter (symmetry — `validate --skills` enforces it).
5. Deep/pack → index notable modules in `references/module-index.md`.
6. Third-party → `skillctl.sh pin <source>`; record a `LOCK.md` row (source,
   short sha, upstream-date, install date, local-mods).
7. `node scripts/validate.mjs --skills` must pass.

## extract <parent>/<module> — carve a module into its own store skill
Distill the module into its own store dir with frontmatter (`name`,
`description`, `group`); flip its `references/module-index.md` status to
`extracted`; leave the parent untouched.

## update <skill> — review-gated apply, never auto
Full procedure: `references/updates.md`. Short form: fetch upstream into a
scratch dir (never straight over the vendored copy), diff what our system
depends on (description drift, footprint files, our local-mods, modules,
new conflicts), `AskUserQuestion` before applying, then on apply: replace the
copy, RE-APPLY every local-mod, re-pin, rewrite the `LOCK.md` row, reconcile
any live project dependency files (`structcheck.sh`), run `validate --skills`.

## delete <skill> — full teardown, not just a directory
The thin `/skills remove <name>` only deletes the bare store directory — use
that for an unwired, never-referenced skill. Use THIS verb once a skill has
been live long enough to accumulate references elsewhere in the system:
1. Unload it if active (`skillctl.sh unload <name>`), then remove the store
   master (`skillctl.sh remove <name>`).
2. Grep the whole repo for the skill's name and scrub every hit:
   `.gitignore` whitelist line (if promoted), `exclusive-with` entries in
   OTHER skills' frontmatter (peer must drop it too — symmetry cuts both
   ways), `LOCK.md` row, `references/conflict-rulings.md` rules/groups
   naming it, `references/module-index.md` rows where it's the parent, any
   README/CLAUDE.md mentions.
3. `node scripts/validate.mjs --skills` must pass clean afterward — that's the
   proof nothing was left half-scrubbed.

## Hard rules
- Fixed skills: report truthfully as "active — not controllable here"; never fake-unload one.
- Packs (gsap, tapestry): register/load MEMBERS individually.
- Never hand-move a skill dir — go through `skillctl.sh` (thin mechanics) even
  from inside a curation flow.
- **Mode scope:** install/update/extract/delete are available in ANY mode (the
  store is the shared library). Only editing the *mechanics* — this file,
  `scripts/skillctl.sh`, the hooks, `.claude/modes/**` — is Mode 1 (system-dev)
  work.
