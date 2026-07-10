> **v2 model change (2026-07):** the central `CATALOG.md`, `CONFLICTS.md`, and
> `MODULES.md` were retired. Skill metadata (`policy`/`category`/`exclusive-with`)
> now lives in each skill's own SKILL.md frontmatter; `.claude/skills-store/INDEX.md`
> is GENERATED (`node scripts/gen-skill-index.mjs`, gitignored). CONFLICTS.md →
> `references/conflict-rulings.md`; MODULES.md → `references/module-index.md`.
> Read "write a CATALOG row" below as "set frontmatter + regenerate the INDEX", and
> "MODULES.md" as "module-index.md". Activation COPIES store→active (gitignored).

# Add classification · footprint detection · load-time handoff
Loaded by skill-manager only during `add`/`load` — NOT resident. SKILL.md carries pointers; the detail is here.

## 1. Classify a fetched source (pack vs deep-skill vs standalone)
Inspect the fetched repo tree, then confirm with the user before writing rows:
| tree shows | class | how to register |
|---|---|---|
| multiple `**/skills/<name>/SKILL.md` (or several top-level `<name>/SKILL.md` dirs) | **PACK** | register MEMBERS individually (kind=pack-member), one family prefix; NEVER install as a unit. Index shared modules in MODULES.md |
| one `SKILL.md` + a `reference/`\|`docs/`\|`references/` folder of sub-files | **DEEP** | install as ONE dir (kind=skill); index notable modules in MODULES.md (status referenced) |
| one flat `SKILL.md`, no sub-files | **STANDALONE** | install as one dir (kind=skill); no MODULES rows |
Ambiguous (a root `SKILL.md` AND a `skills/` dir) → AskUserQuestion. Packs whose members overlap (freshtechbro) → install only the specific members needed, per CONFLICTS/CATALOG notes.

## 2a. Footprint globs — files a skill reads/writes in a target project (from WIKI)
Glob these to detect whether a skill's deps already exist, or whether adding a skill will collide with files already present.
| skill | footprint glob |
|---|---|
| impeccable | `PRODUCT.md`, `DESIGN.md`, `.impeccable/` |
| designer-skills | `.design/*/DESIGN_BRIEF.md`, `.design/*/INFORMATION_ARCHITECTURE.md`, `.design/*/TASKS.md`, `.design/*/DESIGN_REVIEW.md` |
| ui-ux-pro-max | `design-system/MASTER.md`, `design-system/pages/*.md` |
| frontend-slides | self-contained `*.html` decks — no shared repo deps |
| taste-skill · frontend-design · gsap-* · motion-framer (core) | none (stateless) |
New skill added → record its footprint here in the same pass (this table IS the "what deps live where" tracking, derived not logged).

## 2b. Structure signatures — required markers in each owned file (grep-checkable via `structcheck.sh`)
This is the schema of record for the CURRENTLY vendored version. On `update`, diff the updated skill's derived structure against these rows to see if the schema changed; then `structcheck.sh` the real project files against the NEW markers. Authoritative signatures are captured at vendor-time from the skill's OWN templates — rows below are PROVISIONAL (from research) until the skill is actually vendored.
| skill / file | expected markers (headings / fields) |
|---|---|
| impeccable / PRODUCT.md | `## Register` (values brand\|product), `## Users`, `## Purpose`, `## Personality`, `## Anti-references`, `## Accessibility` |
| impeccable / DESIGN.md | `## Tokens`, `## Type`, `## Color`, `## Spacing`, `## Motion` (approx — per impeccable's design.md spec) |
| designer-skills / DESIGN_BRIEF.md | brief-template headings — capture exact set at vendor-time from `design-brief/SKILL.md` |
| ui-ux-pro-max / design-system/MASTER.md | `Colors`, `Typography`, `Spacing`, `Components` |
Stateless skills (taste-skill, frontend-design, gsap-*) own no files → no signature.

## 3. Load-time conflict detection (run on `load`, before moving the dir)
a. **Already active?** `skillctl status` lists it under `.claude/skills/` → say so, skip the load.
b. **Sequential order?** CONFLICTS `sequential` row names this skill as B with a predecessor A → glob A's footprint (§2). Present but B not yet loaded → this is the intended order; offer HANDOFF (§4). Absent → B runs standalone (fine).
c. **Exclusive peer's files present?** glob §2 for an `exclusive` peer's footprint → WARN: two source-of-truth systems would coexist; ask whether to proceed, pick one, or migrate.
d. **Duplicate already installed?** (e.g. a gsap-scrolltrigger from another source) → refuse, name the kept copy.
e. None → load normally.

## 4. Handoff seeding (a `sequential` predecessor's files exist)
Goal: let the newly-loaded skill build on prior work instead of starting cold or ignoring it.
1. Read the mapping from CONFLICTS.md Handoffs table (source files → target files → transfer notes).
2. Read the source file(s); draft the target file(s). This is a LOSSY schema translation, not a copy — surface what you inferred.
3. AskUserQuestion: **seed now** (write targets, then let the new skill's init refine) / **start fresh** (new skill ignores prior files) / **cancel load**.
4. Never overwrite an existing target file without explicit confirm. Record nothing to a log — the files themselves are the state.
