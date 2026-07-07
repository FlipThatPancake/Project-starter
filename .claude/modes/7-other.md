# Mode 7 — other

The task doesn't fit modes 1–6. Do NOT improvise a scope — get it from the user.

- **allowlist:** undefined until the user defines it. Ask what paths are in play,
  then write them:
  ```
  H=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
  printf '%s\n' <paths the user names> > /tmp/claude-mode-$H
  ```
  Only use `*` (allow-all) if the user explicitly says the task is repo-wide.
- **read-set:** whatever the user points to — nothing pre-decided.
- **skills:** gate on the store once the task is understood (full catalogue,
  wait for confirm — see skill-manager SKILL.md → "Mode-entry skill GATE").
  Installing into `.claude/skills-store/` is fine in this mode; loading into
  `.claude/skills/**` or editing mechanics is not — that needs mode 1.
- **guardrails:**
  - Ask enough scoped questions to pin down goal, files, and skills before touching anything.
  - If the task turns out to match a real mode mid-conversation, switch to it.
