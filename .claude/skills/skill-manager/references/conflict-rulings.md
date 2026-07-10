# SKILL CONFLICTS & RESOLUTIONS — operational rulings the picker + add-flow ENFORCE. Descriptive evidence lives in WIKI.md; this file holds DECISIONS only, kept terse.
updated-by: skill-manager · written when: user makes a ruling · `add` detects an overlap · picker hits an unrecorded conflict (record the resolution so it's known next time)
read-at: picker/load time (filter + order options) · add time (warn on duplicate/exclusive)

## Rule types (only these five; install-policy → CATALOG)
- **precedence** — both may be active; LEFT wins the contested call
- **exclusive** — never co-load; pick one (usually a per-project fact, decided once)
- **sequential** — A → B: run A first, B builds on A's output files (see Handoffs). Order matters, not exclusion; re-loading A restarts A's flow
- **compatible** — confirmed good together (+ how, if non-obvious)
- **duplicate** — same capability from two sources; install ONE

## Rules
| type | skills / group | ruling | why |
|---|---|---|---|
| precedence | project design-m3 › anti-slop-preflight › any menu skill | project tokens win, then the guardrail, then task-fit | house rule |
| compatible | impeccable + taste-skill | co-load freely; **impeccable is the primary design-judgment pick**, taste-skill adds dial + anti-slop breadth. File-state safe: impeccable owns PRODUCT.md/DESIGN.md, taste-skill persists nothing | user ruling 2026-07-04 |
| sequential | designer-skills → impeccable (or other design-judgment) | designer-skills sets up a NEW project (brief/IA/tokens); THEN load impeccable to build on those files — on load, offer to seed impeccable from the brief (Handoffs). Re-loading designer-skills restarts its own flow. NOT exclusive — order-dependent | user ruling 2026-07-04 |
| precedence | greensock/gsap-* › freshtechbro gsap-scrolltrigger | greensock official wins ALL gsap tasks | user ruling 2026-07-04 |
| duplicate | gsap-scrolltrigger: greensock vs freshtechbro | register/install greensock's copy only; never add freshtechbro's | user ruling + WIKI §6/§7 |
| exclusive | webgpu-threejs-tsl ⊕ freshtechbro threejs-webgl / react-three-fiber | never co-load TWO contradicting renderers (WebGPU vs classic WebGL). Loading ONE 3D skill mid-session is FINE — the block is only against a second, conflicting renderer | user ruling + WIKI §8 |
| exclusive | designer-skills ⊕ ui-ux-pro-max | both new-project starters, incompatible token + named-style systems — pick ONE per project. Kept exclusive until user tests them (2026-07-04) | user ruling |

## Exclusive groups — machine-parseable (exact skill names (frontmatter `name:`), comma-separated; read by
`skillctl.sh check-conflicts` to suppress an unused member from mode-entry suggestions
when its excluded peer already has footprint files in the project — see
`add-and-handoff.md` §2a for footprint globs). A group appears here ONLY once every
member's name matches a real installed skill — until then it stays prose-only above.
The `webgpu-threejs-tsl ⊕ freshtechbro threejs-webgl / react-three-fiber` row (line 20)
is NOT here yet: those are pack-member names, not yet registered as their own CATALOG
rows (per `add-and-handoff.md` §1, freshtechbro packs register per-member on `add`) —
add its row here once real names exist at vendor-time.
| members (comma-separated) |
|---|
| designer-skills, ui-ux-pro-max |

## Handoffs (file seeding for `sequential` pairs — LOSSY translation + user review, never a blind copy)
| from → to | source files | target files | transfer |
|---|---|---|---|
| designer-skills → impeccable | .design/&lt;slug&gt;/DESIGN_BRIEF.md (+ INFORMATION_ARCHITECTURE.md) | PRODUCT.md, DESIGN.md | brief's purpose/users/personality/anti-refs → PRODUCT.md; visual+token+IA decisions → DESIGN.md; then impeccable's own init refines. Never overwrite an existing target without confirm |

## Unresolved / needs a ruling
(empty — move a row here when the picker hits a conflict you haven't decided yet; resolve into Rules above)
