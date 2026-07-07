# SKILL CATALOG — library metadata. A skill's STATE (active/dormant) is derived from its folder location; never write state here.
starter-repo: (not yet created — put its git URL here; `sync` then = git pull into this store)
policies: pinned=never unloaded · ride-along=always loaded, auto-fires, never asks · menu=never auto-fires, activated only via picker · manual=load by name or profile

## Installed
| skill | kind | category | policy | load-when |
|---|---|---|---|---|
| skill-manager | skill | core | pinned | always — runs this system |
| project-memory | skill | core | pinned | always — repo scope + navigation |
| checkpoint | skill | core | pinned | always — memory writes |
| anti-slop-preflight | skill | design-guardrails | ride-along | before finalizing ANY visual/CSS/design change |
| ship-now | skill | core | manual | "ship it" / "ship to main" — push branch, or PR+GitHub-merge to main, session end |
| session-log | skill | research | manual | /session-log — capture & document session outputs to agent-log |
| learn-this | skill | research | manual | /learn-this <URL> — extract content from URLs → action plan |
| article-extractor | skill | research | manual | /article-extractor — extract clean text from web articles |
| ship-learn-next | skill | research | manual | /ship-learn-next — turn learning content into 5-rep action plan |

## Overlap groups — picker offers modules (see MODULES.md); multi-select = Combined (smart merge per skill-manager Combine protocol)
- design-judgment: impeccable · taste-skill · frontend-design · ui-ux-pro-max — all claim general frontend design. Precedence when co-loaded: project design tokens (design-m3) > anti-slop-preflight > best task fit.

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
