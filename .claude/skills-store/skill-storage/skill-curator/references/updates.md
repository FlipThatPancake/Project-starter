> **v3 model change (2026-07):** `skill-manager` (pinned) was retired; this doc
> now belongs to `skill-curator` (dormant). No more `policy` field; `category`
> was renamed `group` (free-text, optional). No generated `INDEX.md`.

# Updating a third-party store skill — review-gated, never auto-applied
Loaded only when skill-curator runs `update`. Third-party skills are VENDORED copies; an update can help OR break. `LOCK.md` pins what we vendored so drift is detectable and rollback is possible.

## Detect (cheap, safe, run often — changes nothing)
`skillctl.sh check-updates` — `git ls-remote` per LOCK row vs the pinned ref (cheap, no fetch); only on a SHA diff does it pay for a shallow clone to read the new commit's date. Prints ours-vs-latest (sha + upstream-date, both from git history — never filesystem mtime, so the comparison is valid even if the skill dir was re-cloned/re-copied since). Stamps `last-checked`.
When it runs: on `add`, on `sync`, at first manager use in a new project, and when the Stop hook's staleness nudge fires (>7 days). Detection is decoupled from application on purpose.

## Apply (manual, reviewed — the safety core)
1. Fetch upstream at the new ref into a SCRATCH dir — never straight over our copy.
2. DIFF the things OUR SYSTEM depends on and report each before applying:
   - frontmatter `description` → triggering. A widened dragnet = more mis-fires / picker noise. If it grew, consider tightening in our copy.
   - **footprint files** (add-and-handoff §2) → if the skill now reads/writes different files, our detection + handoffs silently break. Update §2 in the SAME pass.
   - **our local-mods** (LOCK `local-mods` col) → upstream may have reset `disable-model-invocation`, undone our bug-fixes, etc. RE-APPLY every one.
   - modules (`reference/` etc.) → add/remove MODULES.md rows to match.
   - new conflicts → a new module/dep may collide with an installed skill; add a CONFLICTS rule if so.
3. AskUserQuestion: **apply** (with local-mods re-applied) / **skip** (keep the pinned version) / **apply then let me test**.
4. On apply: replace the copy, re-apply local-mods, `skillctl.sh pin <source>` again for the new sha+upstream-date, rewrite the LOCK row (new pinned-ref, new upstream-date, unchanged local-mods), run `validate --skills`.
5. Rollback: the OLD pinned-ref is still in git history / re-cloneable — note it before overwriting so a bad update is one re-install away.

## Project dependency-file reconciliation (MANDATORY during every update — the mid-project safety)
An update can change the STRUCTURE the skill expects in its dependency files. The project may already hold those files, written by the OLD version, mid-work. Reconcile per owned file — the exact fix ADAPTS to what's actually on disk; the signatures only guide:
1. **Derive the NEW structure** the updated skill expects (grep its templates/reference for the headings/fields it writes) → compare to the recorded signature in `add-and-handoff.md` §2b (the OLD schema). Unchanged → this file is safe, skip it.
2. **Schema changed → look into the project**: glob §2a for the file.
   - Absent → no conflict; the skill will create it fresh next run.
   - Present → run `scripts/structcheck.sh <project-file> "<new marker>" ...` with the NEW signature's markers. It reports which required markers the existing file is MISSING (renamed/removed/new sections). Also re-run the footprint-overlap + CONFLICTS check against the skill's NEW footprint — an update may start writing a file another installed skill owns.
3. **Misaligned → offer MIGRATION** (AskUserQuestion): back up the file first, then transform it to the new structure — fill newly-required sections from existing content where derivable, flag what can't be inferred, preserve the user's real data. Lossy + semantic → model-driven, always reviewed, never a blind rewrite. Skipping migration is allowed (the skill may then misbehave against the stale file — say so).
4. **After applying** → rewrite §2b's signature row for this skill to the NEW version, so it becomes the schema of record for next time.

## Never
- Never auto-apply. Detection may be automatic; application is always the user's call.
- Never drop a local-mod silently. If upstream conflicts with one, surface it and ask.
