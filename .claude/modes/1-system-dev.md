# Mode 1 — system / skill development

Work ON the starter itself: scripts, hooks, the memory system, the skill-curator
system, tests. This is the only mode allowed to edit `.claude/skills/**` (the
ACTIVE loadout) or the skill mechanics (`scripts/skillctl.sh`, skill-curator's own
SKILL.md, the hooks, `.claude/modes/**`). Cataloging/installing a skill into
`.claude/skills-store/` (dormant) is a normal skill-curator operation and does
NOT require this mode — see skill-curator SKILL.md → Hard rules.

- **allowlist:** `.claude/` · `scripts/` · `tests/` · `CLAUDE.md` · `README.md`
  ```
  H=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
  printf '%s\n' .claude/ scripts/ tests/ CLAUDE.md README.md > /tmp/claude-mode-$H
  ```
- **read-set:** the ENTIRE meta/infrastructure surface, freely — all of `.claude/**`
  (including `skills-store/WIKI.md`, `.claude/memory/agent-log/SKILL-MANAGER-HANDOFF.md`,
  other mode files), `scripts/**`, `tests/**`, `CLAUDE.md`, `README.md`. This is the
  one mode exempt from the narrow-reads default, since understanding/changing that
  surface IS the job. Still prefer grep/anchors over whole-file reads on large files.
  `src/**` stays out of scope unless the task is cross-cutting tooling that explicitly
  names route code.
- **skills:** no pinned skill-manager anymore (v3) — load `skill-curator` from the
  store only when doing install/update/extract/delete work; otherwise the active
  baseline (checkpoint/project-memory/etc.) is enough.
- **guardrails:**
  - Never hand-move skill dirs — use `scripts/skillctl.sh` (or the `skill-curator` skill for install/update/extract/delete).
  - After touching scripts or memory shape, run `node scripts/test-tooling.mjs` and `node scripts/validate.mjs --all` before shipping.
  - Editing the validators/hooks can change what "valid" means — re-run the full test suite, don't trust a single check.
