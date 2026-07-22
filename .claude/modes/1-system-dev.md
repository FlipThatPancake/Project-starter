# Example scope: system-dev

Work ON the starter itself: scripts, hooks, the memory system, the skill-curator
system, tests. The meta-surface — `scripts/skillctl.sh`, the hooks, `.claude/modes/**`,
skill-curator's own SKILL.md, and the ACTIVE loadout in `.claude/skills/**` — is the
one place a real constraint lives: only touch it when the session's purpose IS that
surface. Cataloging/installing a skill into `.claude/skills-store/` (dormant) is a
normal skill-curator operation and needs no special scope — see skill-curator SKILL.md.

- **scope:** `.claude/ scripts/ tests/ CLAUDE.md README.md`
  ```
  H=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
  printf '%s\n' .claude/ scripts/ tests/ CLAUDE.md README.md > /tmp/claude-scope-$H
  ```
- **read-set:** the meta/infrastructure surface, freely — all of `.claude/**`
  (including `skills-store/WIKI.md` and other mode files), `scripts/**`, `tests/**`,
  `CLAUDE.md`, `README.md`. Note: `.claude/memory/agent-log/*HANDOFF*.md` and
  `SKILL-DEVELOPMENT-LOG.md` are HISTORICAL (banner'd superseded) — read them for the
  chronological *why*, not as current spec; the live design is in the SKILL.md files and
  `PROJECT-MEMORY-SYSTEM-HANDOFF.md`. Understanding/changing that surface IS the job, so
  this is the one scope where broad reads are expected. Still prefer grep/anchors over
  whole-file reads on large files. `src/**` stays out unless the task is tooling that
  explicitly names route code.
- **skills:** load `skill-curator` from the store only when doing
  install/update/extract/delete work; otherwise the active baseline is enough.
- **guardrails:**
  - Never hand-move skill dirs — use `scripts/skillctl.sh` (or the `skill-curator` skill).
  - After touching scripts or memory shape, run `node scripts/test-tooling.mjs` and
    `node scripts/validate.mjs --all` before shipping.
  - Editing the validators/hooks can change what "valid" means — re-run the full test
    suite, don't trust a single check.
