# Mode 1 — system / skill development

Work ON the starter itself: scripts, hooks, the memory system, the skill-manager
system, tests. This is the only mode allowed to edit `.claude/skills/**` (the
ACTIVE loadout) or the skill-manager mechanics (`skillctl.sh`, its own SKILL.md,
the hooks, `.claude/modes/**`). Cataloging/installing a skill into
`.claude/skills-store/` (dormant) is a normal skill-manager operation and does
NOT require this mode — see skill-manager SKILL.md → Hard rules.

- **allowlist:** `.claude/` · `scripts/` · `tests/` · `CLAUDE.md` · `README.md`
  ```
  H=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
  printf '%s\n' .claude/ scripts/ tests/ CLAUDE.md README.md > /tmp/claude-mode-$H
  ```
- **read-set:** the ENTIRE meta/infrastructure surface, freely — all of `.claude/**`
  (including `SKILL-MANAGER-HANDOFF.md`, `skills-store/WIKI.md`, other mode files),
  `scripts/**`, `tests/**`, `CLAUDE.md`, `README.md` (see README's "Meta/infrastructure
  read scope" — this is the one mode exempt from the narrow-reads default, since
  understanding/changing that surface IS the job). Still prefer grep/anchors over
  whole-file reads on large files. `src/**` stays out of scope unless the task is
  cross-cutting tooling that explicitly names route code.
- **skills:** `skill-manager` (pinned) is the working tool; usually pinned-only otherwise. Offer the store on entry anyway.
- **guardrails:**
  - Never hand-move skill dirs — use `skill-manager` / `skillctl.sh`.
  - After touching scripts or memory shape, run `node scripts/test-tooling.mjs` and `node scripts/validate.mjs --all` before shipping.
  - Editing the validators/hooks can change what "valid" means — re-run the full test suite, don't trust a single check.
