# SKILL CATALOG — library metadata. A skill's STATE (active/dormant) is derived from its folder location; never write state here.
starter-repo: (not yet created — put its git URL here; `sync` then = git pull into this store)
policies: pinned=never unloaded · ride-along=always loaded, auto-fires, never asks · menu=never auto-fires, activated only via picker · manual=load by name

## Installed
| skill | kind | category | policy | load-when |
|---|---|---|---|---|
| skill-manager | skill | core | pinned | always — runs this system |
| project-memory | skill | core | pinned | always — repo scope + navigation |
| checkpoint | skill | core | pinned | always — memory writes |
| anti-slop-preflight | skill | design-guardrails | manual | before finalizing ANY visual/CSS/design change — suggested via MODE-SHORTLISTS.md for modes 3/4/6, not auto-loaded (changed from ride-along 2026-07-07 — user ruling: don't load when a session has no visual work) |
| ship-now | skill | core | manual | "ship it" / "ship to main" — push branch, or PR+GitHub-merge to main, session end |
| session-log | skill | research | manual | /session-log — capture & document session outputs to agent-log |
| learn-this | skill | research | manual | /learn-this <URL> — extract content from URLs → action plan |
| article-extractor | skill | research | manual | /article-extractor — extract clean text from web articles |
| ship-learn-next | skill | research | manual | /ship-learn-next — turn learning content into 5-rep action plan |
| handoff | skill | session-mgmt | manual | active every session/mode (not ride-along, per user ruling 2026-07-07); /handoff — compact conversation into a handoff doc for the next agent; saves into `.claude/memory/handoffs/`, not OS temp (adapted from source) |
| grill-me | skill | productivity | manual | active every session/mode; thin dispatcher → runs `grilling` |
| grilling | skill | productivity | ride-along | active every session/mode; self-fires on "grill" phrasing or judgment call that a plan needs stress-testing — MUST announce when firing ("Running a grilling session…") per user ruling 2026-07-07; suggested in MODE-SHORTLISTS.md row 2 (fresh-project) |
| grill-with-docs | skill | productivity | manual | active every session/mode; thin dispatcher → runs `grilling` + `domain-modeling` together |
| domain-modeling | skill | productivity | ride-along | active every session/mode (new terminology can surface anytime — see note below); maintains `CONTEXT.md`/`CONTEXT-MAP.md`/ADRs; MUST announce when writing (not when passively reading) |
| fable-mode | skill | process | manual | active every session/mode; `disable-model-invocation: true` added on top of source — NOT a ride-along (user ruling 2026-07-07: too heavy to self-trigger on phrasing); invoke by name for tasks needing staged/verified execution |

## Overlap groups — picker offers modules (see MODULES.md); multi-select = Combined (smart merge per skill-manager Combine protocol)
- design-judgment: impeccable · taste-skill · frontend-design · ui-ux-pro-max — all claim general frontend design. Precedence when co-loaded: project design tokens (design-m3) > anti-slop-preflight > best task fit.

## Notes (added 2026-07-07, new-skills-storage session)
- `domain-modeling` vs `project-memory`: no conflict, different layers. `project-memory` = file-location/structure map (where things live), `domain-modeling`'s `CONTEXT.md` = business-glossary/ADRs (what terms mean, why hard decisions were made), deliberately excluding implementation details. Both can be active every session without duplicating each other's content.
- `grill-with-docs` depends on `domain-modeling` being active (it invokes it directly) — both are active every session, so the dependency is always satisfiable.
- `designer-skills` (Upstream candidates, below) names an internal step "grill-me" in its own 8-flow — unrelated to the installed `mattpocock/skills` grill-me/grilling/grill-with-docs cluster above; naming coincidence only, no functional overlap since designer-skills is not installed.
- Evaluated and **declined** (2026-07-07): `last30days-skill` (heavy Python/API-key/keychain deps, no claude.ai web path), `firecrawl`-as-skill (redundant — this project already has Firecrawl as an MCP server), `ponytail` (hook-driven plugin, narrowly software-dev-specific framing), `skill-creator` (mostly duplicates what skill-manager already does for us), `claude-mnemonic` (Go daemon + SQLite/vector-DB + own MCP server — not portable; the *pattern* of a repo-stored mistake/lesson log is worth revisiting as our own lightweight skill later, not by importing this repo), `cc-probeline` (confirmed CLI-only by its own README — reads local `~/.claude/projects/*.jsonl` and hooks the terminal status line, explicitly not web-portable).

## Upstream candidates (researched 2026-07-04; not installed — `add` pulls one into the store)
| name | category | source | note |
|---|---|---|---|
| impeccable | design-judgment | github:pbakaus/impeccable | **PRIMARY design pick (user)**; 28 modules → menu policy, picker offers modules; co-loads with taste-skill (CONFLICTS) |
| taste-skill | design-judgment | github:Leonxlnx/taste-skill | dials + design-system selection; checklist already extracted → anti-slop-preflight; pairs with impeccable |
| frontend-design | design-judgment | github:anthropics/skills | lighter design guidance (also exists as fixed claude.ai skill) |
| ui-ux-pro-max | design-judgment | github:nextlevelbuilder/ui-ux-pro-max-skill | new-project starter; python search + CSVs; **exclusive with designer-skills** (CONFLICTS) |
| designer-skills | design-process | github:julianoczkowski/designer-skills | new-project starter; 8-flow grill-me→brief→IA→tokens→tasks→build→review; **exclusive with ui-ux-pro-max** |
| gsap-core · gsap-timeline · gsap-scrolltrigger · gsap-plugins · gsap-react (+3) | motion | github:greensock/gsap-skills | pack — load members individually, never whole; **wins all gsap tasks** (CONFLICTS) |
| motion-framer | motion | github:freshtechbro/claudedesignskills | Framer Motion / React; freshtechbro is a 22-skill pack → **install PER-SKILL only, never as a pack** (user); skip its dup gsap-scrolltrigger |
| webgpu-claude-skill | 3d-graphics | github:dgreenheck/webgpu-claude-skill | Three.js + TSL + WebGPU, compute shaders |
| accesslint-scan · accesslint-diff · accesslint-audit | a11y-testing | github:AccessLint/skills | WCAG 2.2; diff is a ride-along candidate |
| frontend-slides | deliverables | github:zarazhangrui/frontend-slides | single-file HTML presentations, style previews |
| tapestry (7 members) | research | github:michalparkola/tapestry-skills | learn-this, article-extractor, yt-transcripts… load members individually |
| awesome-design-md | references | github:VoltAgent/awesome-design-md | 73 DESIGN.md brand docs — copy INTO a project, never loaded as skill |
| Skill_Seekers · npxskillui | tools | github:yusufkaraaslan/Skill_Seekers · github:amaancoderx/npxskillui | skill FACTORIES — run to generate skills, never loaded |
| playwright-cli | tools | github:microsoft/playwright-cli | token-efficient browser-automation CLI |
