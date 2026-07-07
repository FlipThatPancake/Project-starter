# PROFILES — bulk loadouts. `bash .claude/skills/skill-manager/scripts/skillctl.sh load <names>` per row. Pinned + ride-along are always on and never listed here.
| profile | load | note |
|---|---|---|
| mechanical | (nothing) | pinned-only — the default session state |
| design-polish | ONE design-judgment skill, chosen via picker | guardrails already active as ride-along |
| new-project | ONE of {designer-skills, ui-ux-pro-max} — exclusive (CONFLICTS); designer-skills then hands off to impeccable (sequential) | run designer-skills' /grill-me first; fills planning-discovery |
| 3d-site | webgpu-claude-skill · gsap-core · gsap-scrolltrigger | 3D is complex → USUALLY its own fresh session, but loading a single 3D skill mid-session is fine; only a 2nd contradicting renderer is blocked (CONFLICTS) |
| research | tapestry members as needed | `list research` to browse before loading |

Conflict precedence when overlapping design skills are co-loaded: project design tokens (design-m3) > anti-slop-preflight > best task fit.
Picker cadence: ask per TASK — follow-up iterations of the same task reuse the choice; a new task/prompt asks fresh. Never session-sticky.
