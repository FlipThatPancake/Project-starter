# Fix proposals — from the 2026-07-07 live system test

Companion to `2026-07-07-live-system-test.md` (findings F0–F9). These are the concrete
edits a **mode-1 (system-dev) session** should review and apply — the test session (mode 7)
proposed but deliberately did not touch mechanics. Ordered by leverage; each item names the
exact file(s) to edit.

## 1. F0 — Merge the system to `main` (prerequisite for everything)
`main` (local + origin, `8a2f0b6`) contains zero `.claude/` files, old CLAUDE.md, old
scripts. **Action:** run the ship-now PR path to merge the current branch state into main.
Until then every fresh clone/worktree boots without the session system. No file edits — a
merge. Do this first; F1/F3/F4 retests only mean something afterward.

## 2. F1 — Load-scope contradiction + wrong skillctl path (two one-liners)
- `.claude/modes/README.md` (mode-1 restriction): append — *"Exception: loading/unloading
  via the Mode-entry GATE with user confirmation is sanctioned in every mode; the mode-1
  restriction covers ad-hoc loadout edits outside the GATE."*
- `.claude/skills/skill-manager/SKILL.md` §Verbs header: correct `scripts/skillctl.sh` →
  `.claude/skills/skill-manager/scripts/skillctl.sh` (first live invocation exited 127).

## 3. F2 — User-decision precedence rule (one rule, kills three collision classes)
- `.claude/skills/skill-manager/SKILL.md` §Combine protocol, new first line: *"An explicit
  user decision (grilled requirement, named brand color, stated constraint) outranks every
  skill heuristic, random seed, and checklist line — mechanical, no judgment call."*
- Mirror one sentence in `CONFLICTS.md`'s precedence notes.
- **Open user decision:** `anti-slop-preflight/SKILL.md` line 43 ("prefers-reduced-motion …
  permanent standing override") — planted trap or bug? If trap: annotate it as a known
  canary. If bug: delete the line. The test agent passed it either way (style lock + user
  requirement won), but it cost a judgment call.

## 4. F3 — Enforce route-map shape at write time, not /checkpoint time
Preferred: extend `scripts/validate.mjs` `--memory` to enforce the canonical column set from
`checkpoint/references/map-format.md` (today it checks only headings/caps/anchors, so a
wrong-shaped map validates clean and gets fully rewritten at /checkpoint).
Fallback (doc-only): link `map-format.md` from mode 2/3's "register the route" step.

## 5. F4 — Dual logs, dual locks, ungated --no-push commits
- `.claude/modes/README.md`: state that a session logs to the repo it operates in — a
  worktree/child session owns its own `.claude/memory/SESSION-LOG.md`; the mother-repo row
  written at mode-lock (before any worktree exists) is orientation, not the record.
- Rename `/tmp/claude-mode-$H` → `claude-mode-allowlist-$H` and `/tmp/claude-scope-$H` →
  `claude-route-scope-$H` (they're one keystroke apart today); update
  `scripts/scope-guard-hook.sh`, `scripts/ship.sh`, modes/README.md, mode files.
  Cross-reference each lock in the other consumer's header comment.
- `scripts/ship.sh`: move the cross-route scope gate to run **before the commit** (it
  currently sits inside the push path, so `--no-push` commits bypass it entirely).

## 6. F9 — ship.sh gitlink guard (incident fixed live; guard still missing)
`git add -A` staged the test subagent's worktree as a `160000` gitlink (commit `8980bce`,
reverted in `1ef44ad`; `.gitignore` now covers `.claude/worktrees/`). **Action:** after
`git add -A` in `scripts/ship.sh`, abort if any staged entry is a gitlink:
`git ls-files -s | awk '$1=="160000"{bad=1; print "ship: embedded git repo staged: "$4}
END{exit bad}'` — a blocked commit beats a silently broken clone.

## 7. F5 — Batch path for multi-skill `add`
`.claude/skills/skill-manager/SKILL.md` §add: *"User named N skills inline with an install
directive → derive policy/category from each skill's CATALOG.md Upstream annotation, skip
per-skill AskUserQuestion, present ONE consolidated confirmation line for all N before
writing rows."* (This is what the test agent improvised; formalize it.)
Also document: multi-copy upstream repos (impeccable ships 13 duplicate SKILL.md copies) —
take the repo-root copy; and reconcile frontmatter-name vs dir-name mismatches at add time
(taste-skill's frontmatter says `design-taste-frontend` — latent identity split between
skillctl (dir-keyed) and harness (frontmatter-keyed)).

## 8. F6 — MODE-SHORTLISTS row 2 additions (needs user confirmation per file's own rule)
Add to row 2 (new-project): `anti-slop-preflight`, `impeccable + taste-skill (pair)` —
bootstrapping is visual work more often than not; today every mode-2 session manually
broadens into rows 3/6 territory.

## 9. F7 — Pack-member fast path
`.claude/skills/skill-manager/SKILL.md` §add or §Verbs: *"Task needs a sibling member of an
already-loaded pack (same LOCK.md source row) → one yes/no question, reuse the existing
pin/clone, skip the full add flow."*

## 10. F8 — Minor
- `CATALOG.md`: add a `size` column (SKILL.md line count) so the GATE can warn before a
  1,200-line load (taste-skill case); grep-headings-first becomes an explicit suggestion.
- `CLAUDE.md` built-file hazard row: extend to vendored minified blobs in `src/` (72KB gsap
  in `src/routes/home/` is now dodge-territory for whole-file reads, same as dist).
- Env/README note: unpkg.com is proxy-blocked (CONNECT 403); use registry.npmjs.org.

## Token-efficiency note for the mode-1 session
The single biggest recoverable waste was **~660 lines of tool source read only to learn
undocumented formats/flags** (validate.mjs 286, skillctl.sh 153, ship.sh 150, build.mjs 68).
Items 2, 4, and a short "flags & formats" cheatsheet (one table in README.md or a
`scripts/README.md`) would eliminate most of that class of read entirely.
