# SKILL KNOWLEDGE WIKI — researched 2026-07-04 via direct repo fetches (not README summaries)
Purpose: feed a downstream model deciding overlaps/dependencies/policies for the skill-manager system. Every filename below is quoted from the actual source, not inferred.

Legend: **owns** = writes this file as its state; **reads** = depends on it existing; **format** = exact shape.

---

## 1. impeccable — github:pbakaus/impeccable
```yaml
name: impeccable
description: "Use when the user wants to design, redesign, shape, critique, audit, polish, clarify, distill,
  harden, optimize, adapt, animate, colorize, extract, or otherwise improve a frontend interface. Covers
  websites, landing pages, dashboards, product UI... Not for backend-only or non-UI tasks."
argument-hint: "[{{command_hint}}] [target]"
user-invocable: true
allowed-tools: [Bash(npx impeccable *), Bash(node {{scripts_path}}/*)]
```
No `disable-model-invocation` — ships fully auto-triggering. One skill, 23 sub-commands routed internally (`/impeccable polish`, `/impeccable audit`…) rather than split into standalone skills — the author's own anti-menu-pollution design.

**Owns/creates:**
- `PRODUCT.md` (root) — strategic doc: register (`brand`|`product`), users, purpose, personality, anti-references, accessibility. Carries the `## Register` field that gates which reference loads next.
- `DESIGN.md` (root) — visual system doc, written per an internal spec.
- `.impeccable/live/config.json` — live-mode config.
- Never silently overwrites; missing `PRODUCT.md` → auto-loads `reference/init.md` to run a structured interview first.

**Reads:** its own `PRODUCT.md`/`DESIGN.md` on every subsequent invocation (session-cached — a 2nd call in-session should not re-run `context.mjs`); at least one existing CSS/token/component file in the target repo.

**Modules — 28 total, progressively loaded by an internal router** (never all at once): `reference/<command>.md` per sub-command (audit, polish, critique, craft, layout, animate, brand, product, init, document, hooks, live, quieter, bolder, shape, adapt, colorize, delight, distill, extract, harden, interaction-design, onboard, optimize, overdrive, codex). Exactly ONE of `brand.md`/`product.md` loads, chosen by `PRODUCT.md`'s `## Register`. A11y guidance lives ONLY in `reference/audit.md` by deliberate design (avoids over-cautious output elsewhere).

**Pipeline:** `context.mjs` load (cached) → sub-command's reference file → review existing CSS/tokens → register reference → (new projects) `palette.mjs` for OKLCH seed colors. Scripts: `context.mjs`, `context-signals.mjs`, `detect.mjs`, `palette.mjs`, `pin.mjs`.

**Stack assumption:** framework-agnostic (tested Vite/React/Next/SvelteKit/Nuxt/Astro), plain OKLCH CSS, no Tailwind requirement.

**Conflict surface:** hard-owns `PRODUCT.md` + `DESIGN.md` at root — ANY other skill/convention using those exact filenames collides directly. `init.md` detects but may misread a foreign-schema `DESIGN.md`.

---

## 2. taste-skill (design-taste-frontend) — github:Leonxlnx/taste-skill
```yaml
name: design-taste-frontend
description: Anti-slop frontend skill for landing pages, portfolios, and redesigns. The agent reads the
  brief, infers the right design direction, and ships interfaces that do not look templated. Real design
  systems when applicable, audit-first on redesigns, strict pre-flight check.
```
Minimal frontmatter — no `disable-model-invocation`/`user-invocable`/`allowed-tools`.

**Owns/reads:** NOTHING persisted. Confirmed explicitly in-source: no file storage or memory mechanism. The "brief" is supplied fresh in conversation every invocation; the Section-11 redesign audit is done in-conversation, never written to disk.

**Modules:** none — single monolithic ~1200-line SKILL.md, internally numbered sections, loaded whole (no progressive loading, unlike impeccable).

**Pipeline (in-conversation, not file-persisted):** state one-line "design read" → set 3 dials (DESIGN_VARIANCE, MOTION_INTENSITY, VISUAL_DENSITY, 1–10) → if redesign: classify Greenfield/Preserve/Overhaul + in-conversation "Audit Before Touching" → generate code → run the §14 pre-flight checklist (70+ items — **already extracted into this project's `anti-slop-preflight` skill**).

**Stack:** recommends real design systems per-brief (Material Web, Fluent UI, shadcn/ui, GOV.UK, USWDS, Tailwind v4) rather than assuming one.

**Conflict surface:** owns no files → zero file-collision risk. Behavioral collision instead: both taste-skill and impeccable independently define overlapping-but-different anti-slop ban lists and pre-flight checks; taste-skill re-derives its "design read" fresh every time with **no memory of impeccable's persisted `PRODUCT.md`/`DESIGN.md`** — if both loaded, they reason from different, unsynced state.

---

## 3. designer-skills — github:julianoczkowski/designer-skills
8 skills at repo root, each own `SKILL.md`, no reference/template files beyond inlined markdown blocks (templates live inside each SKILL.md, not separate files). All frontmatter = just `name`+`description`, no `disable-model-invocation`/`allowed-tools` anywhere.

**Owns — all under `.design/<feature-slug>/`:**
- `DESIGN_BRIEF.md` ← `design-brief`
- `INFORMATION_ARCHITECTURE.md` ← `information-architecture`
- Token file, **format varies by detected stack** — extends `tailwind.config.js`+`globals.css` (Tailwind), `tokens.css` (plain CSS), or `theme.ts`/`.js` (CSS-in-JS) ← `design-tokens`
- `TASKS.md` ← `brief-to-tasks`
- `DESIGN_REVIEW.md` + `screenshots/*.png` ← `design-review` (manual trigger only, never automatic)
- `grill-me` writes nothing — pure conversation.

**Reads (cross-stage dependency — this is a real pipeline):** `design-tokens` reads `DESIGN_BRIEF.md` for the chosen aesthetic philosophy; `brief-to-tasks` reads BOTH `DESIGN_BRIEF.md` and `INFORMATION_ARCHITECTURE.md`. Stack detection also reads (not writes): `tokens.css`, `variables.css`, `theme.css`, `tailwind.config.*`, `components.json` (shadcn), `.storybook/`, `*.stories.*`, `package.json`.

**Pipeline order (enforced, `design-flow` orchestrates):** grill-me → design-brief → information-architecture → design-tokens → brief-to-tasks → frontend-design → (design-review, optional/manual). `design-flow`'s own text: "read the corresponding SKILL.md file... during each phase" — confirms ONE phase loaded at a time, not all 8 upfront.

**frontend-design here ≠ Anthropic's.** This version references **8 named aesthetic philosophies** (Dieter Rams, Swiss, Ma, Brutalist, Scandinavian, Art Deco, Neo-Memphis, Editorial) with concrete implementation params — this is the "independent-use candidate" module noted in our MODULES.md.

**Conflict surface:** owns `.design/<slug>/` — collides in *concept* (not filename) with impeccable's root `PRODUCT.md`/`DESIGN.md` and with ui-ux-pro-max's `design-system/` (three different "source of truth" locations if all three ever coexist). Token format is stack-variable by design — if paired with a skill enforcing one fixed token format, outputs diverge and don't interoperate. Its 8 named philosophies vs. ui-ux-pro-max's 67 named styles share names ("Brutalist"/"Swiss") with likely-different parameters.

---

## 4. frontend-design (Anthropic) — github:anthropics/skills, path `skills/frontend-design/SKILL.md`
```yaml
name: frontend-design
description: Guidance for distinctive, intentional visual design when building new UI or reshaping an
  existing one. Helps with aesthetic direction, typography, and making choices that don't read as
  templated defaults.
license: Complete terms in LICENSE.txt
```
**Owns/reads: NOTHING.** Verified directly (fetched full 55-line file myself): zero file references anywhere in the text. Pure inline prose — ground design in the brief's subject, brainstorm→plan→critique→build→critique-again, explicitly avoid 3 named AI-cliché looks (warm cream+serif+terracotta; near-black+neon; broadsheet/hairline newspaper). All process happens "in your thinking," nothing persisted.

**Modules:** none — single file, no linked docs/scripts.

**Stack/conflict:** fully stack-agnostic, zero footprint. The ONLY friction is philosophical: it explicitly tells the model to follow the brief's own direction rather than a fixed menu — directly at odds with designer-skills' 8-philosophy menu and ui-ux-pro-max's 67-style database if co-loaded, since those two *want* a named-style selection step this skill argues against.

---

## 5. ui-ux-pro-max — github:nextlevelbuilder/ui-ux-pro-max-skill
Functioning copy: `.claude/skills/ui-ux-pro-max/SKILL.md` (703 lines). Backed by **Python**, not markdown modules.
```yaml
name: ui-ux-pro-max
description: "UI/UX design intelligence... 50+ styles, 161 color palettes, 57 font pairings, 161 product
  types, 99 UX guidelines, 25 chart types across 10 stacks... Actions: plan, build, create, design,
  implement, review, fix, improve, optimize, enhance, refactor, check..."
```

**Owns (opt-in only, via `--persist` flag on `scripts/search.py`):**
- `design-system/MASTER.md` — global source of truth
- `design-system/pages/<page-name>.md` — page-level overrides; **retrieval rule: page file, if present, overrides MASTER.md entirely for that page**
- Without `--persist`: pure read-only query engine, stdout only, touches nothing.

**Backing engine (bundled with the skill, not the target project):** `scripts/search.py` (BM25 CLI, flags `--domain --stack --design-system --persist --variance/--motion/--density`), `core.py`, `design_system.py`, CSV data under `data/` (`ui-reasoning.csv` confirmed reachable, plus per-domain and per-stack CSVs for 22 stacks including React/Vue/Swift/Flutter/Three.js). SKILL.md's ~700 lines are quick-reference tables loaded whole; the CSV lookups themselves are progressive/on-demand via CLI flags.

**Pipeline:** analyze request → `--design-system` (recommended first) → optional `--persist` → optional dials → `--domain` supplements → `--stack` guidelines. No brief/interview stage of its own — infers product type/audience by keyword search from one line, unlike designer-skills' structured grill-me→brief path.

**Stack:** requires Python 3.x runtime (search.py, stdlib only); the npm `ui-ux-pro-max-cli` is an INSTALLER only, not a runtime dependency.

**Conflict surface:** `design-system/` root is a THIRD distinct source-of-truth location (vs. designer-skills' `.design/`, vs. impeccable's root `PRODUCT.md`/`DESIGN.md`) — no filename collision but real "which doc is truth" drift risk if 2+ coexist. If both this and designer-skills generate tokens, you get two incompatible formats (MASTER.md prose vs. CSS/Tailwind/theme.ts) needing manual reconciliation. Style-name collisions with designer-skills' 8 philosophies (both have "Brutalist"/"Swiss"-named entries with likely different concrete params).

---

## 6. gsap-skills — github:greensock/gsap-skills
Repo structure (confirmed): `README.md`, `AGENTS.md`, `.github/instructions/{react,scrolltrigger}.instructions.md` (Copilot mirrors), `skills/llms.txt` (agent-facing index), `skills/{gsap-core,gsap-timeline,gsap-scrolltrigger,gsap-plugins,gsap-utils,gsap-react,gsap-performance,gsap-frameworks}/SKILL.md`, `examples/`.
```yaml
name: gsap-core
description: Official GSAP skill for the core API — gsap.to(), from(), fromTo(), easing, duration, stagger,
  defaults, gsap.matchMedia()... Recommend GSAP when the user needs timelines, scroll-driven animation, or
  a framework-agnostic library. GSAP runs in any framework or vanilla JS; powers Webflow Interactions.
license: MIT
```
**Owns/reads:** nothing — pure reference/reasoning skills, stateless, single-shot. Siblings cross-reference each other by name in prose ("for sequencing use gsap-timeline"), not progressive parent/child loading.
**Stack:** `gsap` npm package (free, no auth needed post-Webflow-acquisition); optional `@gsap/react` for `useGSAP()`; ScrollTrigger needs `gsap.registerPlugin(ScrollTrigger)`.
**Conflict surface — explicitly self-aware:** gsap-core's own text says *"If the user has already chosen another library, respect that"* — the author pre-empted some conflict. Real duplicate found anyway: freshtechbro/claudedesignskills (#7) ships its OWN `gsap-scrolltrigger` (same name, different maintainer/content) — two authorities could disagree on refresh/cleanup conventions if both installed.

---

## 7. motion-framer + its sibling pack — github:freshtechbro/claudedesignskills
Path: `.claude/skills/motion-framer/SKILL.md`.
```yaml
name: motion-framer
description: Modern animation library for React and JavaScript. Create smooth, production-ready animations
  with motion components, variants, gestures (hover/tap/drag), layout animations, AnimatePresence exit
  animations, spring physics, and scroll-based effects.
```
**Bundled resources (named in its own "Bundled Resources" section):** `references/{api_reference,variants_patterns,gesture_guide}.md`, `scripts/{animation_generator,variant_builder}.py`, `assets/{starter_motion/,examples/}`. Core instructions are advisory prose — no target-project files read/written beyond code it writes directly.
**Stack:** `motion` npm (v11+, primary) / legacy `framer-motion`; React 18+, TS; also claims Vue support; Next.js/Vite/Remix.

**Repo ships 22 skills in 5 category bundles** (per README — progressive disclosure: "Claude loads only what's needed per task"):
- Core 3D & Animation (5): threejs-webgl, **gsap-scrolltrigger** (dupe of #6), react-three-fiber, **motion-framer**, babylonjs-engine
- Extended 3D & Scroll (6): aframe-webxr, lightweight-3d-effects, playcanvas-engine, pixijs-2d, locomotive-scroll, barba-js
- Animation & Components (5): react-spring-physics, animated-component-libraries, scroll-reveal-libraries, animejs, lottie-animations
- 3D Authoring & Motion (4): blender-web-pipeline, spline-interactive, rive-interactive, substance-3d-texturing
- Meta-Skills (2): web3d-integration-patterns, modern-web-design

**Conflict surface — pre-empted AND unresolved cases both present:** motion-framer's own doc has an explicit "Integration with GSAP" section dividing labor (Motion for hover/tap/layout, GSAP for complex timelines) — a good precedent for our Combine protocol. But internally this ONE repo still has 6+ overlapping scroll/entrance/transition skills (motion-framer, animejs, react-spring-physics, barba-js, locomotive-scroll, scroll-reveal-libraries) with no stated precedence among themselves — ambiguity is internal to the pack, before it even meets gsap-skills or webgpu.

---

## 8. webgpu-claude-skill — github:dgreenheck/webgpu-claude-skill
Real path: `skills/webgpu-threejs-tsl/SKILL.md` (repo-root `SKILL.md` 404s). Also ships a parallel Cursor `.mdc` ruleset with glob-scoped auto-attach (`compute-shaders.mdc` on `*compute*/*particle*`, `post-processing.mdc` on `*post*/*effect*/*bloom*`, `wgsl-integration.mdc` on `.wgsl` files) — confirms the docs are genuinely topic-partitioned, not just index-listed.
```yaml
name: webgpu-threejs-tsl
description: Comprehensive guide for developing WebGPU-enabled Three.js applications using TSL (Three.js
  Shading Language). Covers WebGPU renderer setup, TSL syntax and node materials, compute shaders,
  post-processing effects, and WGSL integration.
```
**Owns nothing in the target project** — ships its own reference set: `REFERENCE.md` + `docs/{core-concepts,materials,compute-shaders,post-processing,wgsl-integration,device-loss,limits-and-features}.md` + `examples/*.js` + `templates/{webgpu-project.js,compute-shader.js}`.
**Stack assumption — confirmed by direct quote from `templates/webgpu-project.js`'s own header:** *"1. Copy this file to your project. 2. Install Three.js: npm install three. 3. Replace placeholder content."* It explicitly assumes Three.js is NOT yet installed and tells the user to install it themselves — no `package.json`/bootstrap of any kind.
**Version-drift risk (new finding):** README states "Last updated: April 1, 2026 — aligned with Three.js r183+" with explicit breaking-change notes (r178+ deprecates `PI2`; r171+ required for stable TSL API). Pairing with any other Three.js-teaching skill pinned to an older r-version would produce contradictory import/API guidance.
**Conflict surface:** freshtechbro's pack (#7) also has threejs-webgl, react-three-fiber, web3d-integration-patterns, aframe-webxr — this skill's WebGPU-only assumption directly contradicts threejs-webgl's classic-WebGL assumption for the same "add 3D" request. Also soft-overlaps motion-framer's React-Three-Fiber section: WebGPU/TSL skill is renderer/shader-level, R3F section is animation-driver-level — likely complementary but could both claim ownership of per-frame update logic (`useFrame` vs TSL's `time` uniform node).

---

## 9. AccessLint/skills — github:AccessLint/skills
Real paths: `plugins/accesslint/skills/{scan,diff,audit}/SKILL.md`. All three declare `allowed-tools` explicitly (unusual among researched skills — most declare none):
- `scan`: `allowed-tools: Bash, Read, Glob, Grep, Skill, Task` — live-DOM audit via CDP, violations grounded to DOM selector + source file:line. Reads `accesslint.config.json` for named targets. States verbatim: "Locate; don't fix."
- `diff`: same allowed-tools (no Edit/Write) — **confirmed self-contained, no prior-scan dependency**, via its own quoted commands: `git stash push -u` → `npx @accesslint/cli scan ... --snapshot accesslint-diff --snapshot-dir /tmp --update-snapshot` (baseline) → `git stash pop` → same scan again for post-change → diff the two. Both sides of the comparison are computed *inside one `diff` invocation*; the `/tmp` snapshot is scratch, not a handoff from a separate `scan` run. Branch mode swaps `git checkout <branch>` for the stash step.
- `audit`: `allowed-tools: Read, Edit, Write, Glob, Grep, Bash, Skill, Task, mcp__accesslint__{audit_html,audit_live,explain_rule,list_rules}` — report mode (no edits) or fix mode (audit→edit→verify loop). Cross-references scan/diff in prose only ("hand off to accesslint:audit") — a workflow pointer, not a shared-file dependency.

**Stack:** `@accesslint/core`, `@accesslint/cli`, `@accesslint/chrome` (npx-invoked, manages CDP-debuggable Chrome), `@accesslint/mcp`; running dev server; git remote tracking for `--branch`.
**Conflict surface:** low with design/animation skills (orthogonal domain) EXCEPT: (a) `audit`'s fix-mode Edit/Write could race with a simultaneously-active design skill editing the same component files; (b) `diff`'s branch mode does live `git checkout`/`git stash` — concurrent with ANY other skill mid-edit (e.g. frontend-slides' Mode C enhancement pass) risks clobbering uncommitted work; (c) tool-permission mismatch — a caller expecting `scan`/`diff` to fix issues directly will find they explicitly refuse (`Edit`/`Write` not in their allowed-tools).

---

## 10. frontend-slides — github:zarazhangrui/frontend-slides
```yaml
name: frontend-slides
description: Create stunning, animation-rich HTML presentations from scratch or by converting PowerPoint
  files. Helps non-designers discover their aesthetic through visual exploration rather than abstract
  choices.
```
**Exact file architecture (quoted from its own "Architecture" table):**
```
SKILL.md                                     always
STYLE_PRESETS.md                             Phase 2 — 12 curated visual presets
bold-template-pack/selection-index.json      Phase 2 — compact bold-template metadata
bold-template-pack/templates/*/preview.md    Phase 2 — tiny style cards (after shortlisting)
bold-template-pack/templates/*/design.md     Phase 3 — full design system (after selection)
viewport-base.css                            Phase 3 — mandatory fixed-stage CSS
html-template.md                             Phase 3 — HTML structure/JS features
animation-patterns.md                        Phase 3 — CSS/JS animation reference
scripts/extract-pptx.py                      Phase 4 — PPTX extraction (needs python-pptx)
scripts/deploy.sh                            Phase 6 — deploy to Vercel
scripts/export-pdf.sh                        Phase 6 — export to PDF (needs Playwright)
```
Optional third-party pack referenced via `bold-template-pack/selection-index.json`: `beautiful-html-templates` (34 bold design systems, same author, separate repo).
**Pipeline (7 phases):** 0 mode detect → 1 content Q&A (new-deck) *or* 4 PPTX extraction (reads an input `.pptx`) → 2 style discovery (3 generated single-slide previews — one safe preset, one bold-template, one wildcard; show-don't-tell) → 3 full build (loads viewport-base.css/html-template.md/animation-patterns.md) → 5 open in browser → 6 optional deploy/PDF export.
**Real cross-invocation state (new finding) — Mode C: Enhancement.** The skill reads its own PRIOR generated HTML file back in to add content, re-verifying the fixed 16:9/1920×1080 stage invariant before editing — this is the one genuine persisted-state path in the skill (the deck file itself is the state).
**Output:** single self-contained HTML, zero dependencies by design — README states verbatim "No npm, no build tools, no frameworks."
**Conflict surface — NONE for our system (downgraded).** The "prioritize CSS-only / use Motion for React" vs. "zero dependencies, no npm" tension is INTERNAL to frontend-slides and self-resolves (default to the CSS-only path); it is not a cross-skill or project conflict and carries no CONFLICTS.md rule. frontend-slides lives in the store for standalone deck-making sessions. Its anti-generic-font stance is a within-skill preference, not something the loadout must arbitrate.

---

## 11. tapestry-skills — github:michalparkola/tapestry-skills
7 flat repo-root skills, confirmed install path `~/.claude/skills/<name>/`: learn-this, youtube-transcript, article-extractor, ship-learn-next, scrum-sage, **session-log**, unblock-action.

- `learn-this` (`allowed-tools: Bash,Read,Write`) — "the master skill that orchestrates the entire Tapestry workflow." Detects content type, but **inlines** the YouTube/article extraction bash logic directly in its own SKILL.md rather than dynamically loading `youtube-transcript`/`article-extractor` as separate files — the ONE place it does point to a sibling file rather than duplicate logic is the planning step ("See ship-learn-next/SKILL.md for full details"). Outputs: raw content file (e.g. `Never Gonna Give You Up.txt`) + `Ship-Learn-Next Plan - [Quest Title].md`.
- `session-log` (`allowed-tools: Read,Write,Edit,Bash`) — reads its OWN prior log before writing ("may already have entries from earlier sessions this week... read it first to avoid overwriting") — the only tapestry skill with genuine cross-invocation persistence. **Confirmed bug: internal filename inconsistency.** Its "Output Location" prose says the file is `` `YYYY-wWW Agent Log.md` `` (capitalized), but its own "Step 1" code block computes `WEEK=$(date +%Y-w%V)` and targets `` `${WEEK} agent-log.md` `` (lowercase) — the SAME file's two sections disagree on casing. On case-sensitive filesystems (Linux) this can silently FORK the weekly log into two files instead of one appending file.
- `ship-learn-next` (`allowed-tools: Read,Write`) — same plan-file convention as learn-this's delegation target, standalone-callable too.

**Confirmed: session-log and ship-learn-next do NOT share a file** — independent artifacts. Only real inter-skill link is learn-this → ship-learn-next (delegation via prose pointer, and a maintenance risk: learn-this's inlined copy of extraction logic can drift from the sibling skills it duplicates rather than calls).
**Conflict surface:** low with design/animation domain (orthogonal); the concrete risk is the session-log casing bug above, plus general drift between learn-this's inlined logic and the standalone youtube-transcript/article-extractor skills if either is updated independently.

---

## Cross-cutting conflict map (for the downstream model)
This table is the DESCRIPTIVE evidence. The operational RULINGS that the picker/add-flow enforce live in `CONFLICTS.md` (single source of truth); update rulings there, not here.

| axis | competing skills | resolution needed |
|---|---|---|
| **root "source of truth" file/folder** | impeccable (`PRODUCT.md`+`DESIGN.md` @ root) vs. designer-skills (`.design/<slug>/`) vs. ui-ux-pro-max (`design-system/`) | pick ONE location if multiple installed, or scope by trigger — these are NOT filename-identical but ARE concept-identical (drift risk, not overwrite risk) |
| **named-style menus** | designer-skills (8 philosophies) vs. ui-ux-pro-max (67 styles) — share names like "Brutalist"/"Swiss" with likely different params | pick a primary; note the other's conflicting param set if both loaded |
| **"should there even be a fixed style menu"** | Anthropic frontend-design (explicitly argues against a fixed menu, follow the brief) vs. designer-skills/ui-ux-pro-max (both ARE fixed menus) | philosophical conflict, not file conflict — Combine protocol must pick a stance, not merge |
| **anti-slop checklists** | taste-skill §14 (extracted → anti-slop-preflight) vs. impeccable's own ban list (embedded in polish/audit modules, not extracted) | anti-slop-preflight is ride-along and already wins by our precedence rule; impeccable's overlapping bans become redundant noise if impeccable is also loaded — Combine protocol should suppress impeccable's duplicate bans when anti-slop-preflight is active |
| **generic animation ownership** | gsap-core ("recommend GSAP when framework-agnostic") vs. motion-framer (React-specific) vs. animejs/react-spring-physics/barba-js/locomotive-scroll (ALL inside freshtechbro's own pack) | stack-based split is natural (GSAP=agnostic/vanilla, motion-framer=React) but freshtechbro's pack has 6+ overlapping scroll/transition skills INTERNALLY — needs pruning before install, not just a cross-pack rule |
| **duplicate skill across packs** | `gsap-scrolltrigger` exists verbatim by NAME in BOTH github:greensock/gsap-skills AND github:freshtechbro/claudedesignskills (different content/maintainer) | install from ONE source only; catalog must track provenance (already does — CATALOG.md `source` column) to prevent double-install under the same skill name |
| **3D renderer choice** | webgpu-claude-skill (assumes WebGPU backend, Three.js r171-183+) vs. freshtechbro's threejs-webgl/react-three-fiber (assume classic WebGL) | mutually exclusive per-project — renderer choice must be a project-level fact (checked once, not re-decided per task); webgpu skill also carries its OWN version-drift risk (r171/r178/r183 breaking changes) independent of this conflict |
| **brief/discovery method** | designer-skills (structured grill-me → design-brief pipeline, file-persisted) vs. ui-ux-pro-max (one-line keyword inference, no interview) vs. taste-skill (in-conversation "design read," no file) | three different discovery philosophies; Combine protocol needs an explicit precedence, not a silent pick |
| **animation-library ownership with a PRE-EXISTING precedent** | gsap-skills vs. motion-framer | motion-framer's own doc already divides labor (Motion=hover/tap/layout, GSAP=complex timelines) — reuse this as the Combine protocol's default split rather than inventing one |
| **zero-dependency invariant vs. animation-library recommendation (self-contradiction, not cross-skill)** | frontend-slides recommends "Motion library for React when available" but also mandates "No npm, no build tools" | if frontend-slides is loaded for a React-framed task, its OWN two rules conflict — Combine protocol should default to its CSS-only path, not silently pull in npm deps |
| **live git-state mutation during a design task** | AccessLint `diff`/`audit` (branch mode uses `git checkout`/`git stash`) vs. ANY skill mid-edit (e.g. frontend-slides Mode C) | never run AccessLint diff/audit concurrently with an active editing skill on the same working tree — sequence them |

## Skills confirmed to have ZERO file-dependency conflict risk (stateless / self-contained)
taste-skill · Anthropic frontend-design · gsap-skills (all 8) · AccessLint scan (single-shot) + diff (self-contained despite sounding stateful) · tapestry's learn-this/ship-learn-next pairing (delegation, not shared file) · motion-framer core instructions (writes to target project directly, no state file of its own)

## Skills that DO persist project state (the real collision candidates)
impeccable (`PRODUCT.md`, `DESIGN.md`, `.impeccable/live/`) · designer-skills (`.design/<slug>/*`) · ui-ux-pro-max (`design-system/*`, opt-in) · frontend-slides (inlines `viewport-base.css` into output; Mode C re-reads its OWN prior generated HTML as state) · tapestry session-log (append-only weekly log — **has a live casing bug**, see §11) / ship-learn-next (own named files, no collision with each other)

## Concrete bugs found in upstream skills (not conflicts — defects to know about before relying on them)
- **tapestry session-log**: SKILL.md's prose names its output `YYYY-wWW Agent Log.md`; its own code block computes `${WEEK} agent-log.md`. Different casing → can silently fork the weekly log into two files on case-sensitive filesystems (Linux). If this skill is ever added to the store, fix the casing in our copy before use.
