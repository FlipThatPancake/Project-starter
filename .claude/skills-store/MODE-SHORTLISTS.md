# MODE SKILL SHORTLISTS — per-mode starter picks for the skill-manager's Mode-entry GATE.
Consulted FIRST when building the "top suggested picks" for a session; the gate then
broadens to scan the rest of CATALOG.md (Installed + Upstream candidates) for anything
else that fits the confirmed task. Not exhaustive by design — a short, curated guess,
not a duplicate of the catalog.
maintained-by: skill-manager, per the "New-skill mode-fit check" (SKILL.md) — updated
only with user confirmation, never silently.

| mode | shortlist | why |
|---|---|---|
| 1-system-dev | (none beyond skill-manager, pinned) | system/skill work is self-contained; no store skill adds value here |
| 2-new-project | designer-skills OR ui-ux-pro-max (exclusive — CONFLICTS.md, picker chooses one), awesome-design-md (reference, copy-in), grilling (already active — flag for running a grilling session before locking structure/stack) | bootstrapping structure/stack/design-system decisions |
| 3-new-route | anti-slop-preflight, impeccable, taste-skill | building a page/route touches visual quality (accesslint-scan dropped 2026-07-07 — it's a plugin+MCP bundle, not installable via our skill-store flow; see CATALOG.md note) |
| 4-continue-route | anti-slop-preflight, session-log | resuming visual work; session-log captures progress |
| 5-backend-routing | (none — no design judgement needed) | routing/page-structure work is non-visual |
| 6-design-system | anti-slop-preflight, impeccable, taste-skill, designer-skills (design-tokens module) | shared design system is the point of this mode |
| 7-other | (task-dependent — no preset) | scope undefined until the user clarifies; ask broadly instead of guessing |

## Notes
- A shortlist entry being listed does NOT mean auto-load — the Mode-entry GATE still
  presents it as a suggestion and waits for the user's confirm/redaction, same as any
  other candidate.
- Rows here are starting guesses, not rulings — CONFLICTS.md exclusivity/precedence
  still applies when the user picks ≥2 shortlisted skills together.
- When a mode's shortlist and the confirmed task purpose disagree (e.g. mode 5 but the
  task clearly touches visual work), state the mismatch and broaden the search rather
  than silently following the shortlist.
- On an in-progress project, `skillctl.sh check-conflicts` (run at every GATE) can
  suppress a shortlisted skill if its exclusive peer already has footprint files in
  the project — e.g. row 2's "designer-skills OR ui-ux-pro-max" collapses to whichever
  one this project actually used. See skill-manager SKILL.md → Mode-entry GATE.
