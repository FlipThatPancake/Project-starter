# MODE SKILL SHORTLISTS — per-mode starter picks for the skill-manager's Mode-entry GATE.
Consulted FIRST when building the "top suggested picks" for a session; the gate then
broadens to scan the rest of CATALOG.md (Installed + Upstream candidates) for anything
else that fits the confirmed task. Not exhaustive by design — a short, curated guess,
not a duplicate of the catalog. Distinct from `profiles.md` (named bulk loadouts you can
invoke by name any time, independent of mode) — a shortlist row may point at a profile
where one already covers it.
maintained-by: skill-manager, per the "New-skill mode-fit check" (SKILL.md) — updated
only with user confirmation, never silently.

| mode | shortlist | why | related profile |
|---|---|---|---|
| 1-system-dev | (none beyond skill-manager, pinned) | system/skill work is self-contained; no store skill adds value here | mechanical |
| 2-new-project | designer-skills OR ui-ux-pro-max (exclusive — CONFLICTS.md, picker chooses one), awesome-design-md (reference, copy-in) | bootstrapping structure/stack/design-system decisions | new-project |
| 3-new-route | anti-slop-preflight, impeccable, taste-skill, accesslint-scan | building a page/route touches visual quality + a11y | design-polish |
| 4-continue-route | anti-slop-preflight, accesslint-scan, session-log | resuming visual work; session-log captures progress | design-polish |
| 5-backend-routing | (none — no design judgement needed) | routing/page-structure work is non-visual | mechanical |
| 6-design-system | anti-slop-preflight, impeccable, taste-skill, designer-skills (design-tokens module) | shared design system is the point of this mode | design-polish |
| 7-other | (task-dependent — no preset) | scope undefined until the user clarifies; ask broadly instead of guessing | — |

## Notes
- A shortlist entry being listed does NOT mean auto-load — the Mode-entry GATE still
  presents it as a suggestion and waits for the user's confirm/redaction, same as any
  other candidate.
- Rows here are starting guesses, not rulings — CONFLICTS.md exclusivity/precedence
  still applies when the user picks ≥2 shortlisted skills together.
- When a mode's shortlist and the confirmed task purpose disagree (e.g. mode 5 but the
  task clearly touches visual work), state the mismatch and broaden the search rather
  than silently following the shortlist.
