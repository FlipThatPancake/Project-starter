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
- **read-set:** only the file(s) the task names. Use grep/anchors, not whole-dir reads. `.claude/skills-store/*.md` metadata read on demand (per skill-manager rules).
- **skills:** `skill-manager` (pinned) is the working tool; usually pinned-only otherwise. Offer the store on entry anyway.
- **guardrails:**
  - Never hand-move skill dirs — use `skill-manager` / `skillctl.sh`.
  - After touching scripts or memory shape, run `node scripts/test-tooling.mjs` and `node scripts/validate.mjs --all` before shipping.
  - Editing the validators/hooks can change what "valid" means — re-run the full test suite, don't trust a single check.
