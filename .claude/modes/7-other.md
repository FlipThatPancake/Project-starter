# Example scope: other

The task doesn't match the other examples. Do NOT improvise a scope — get it from
the user, then declare it free-form.

- **scope:** undefined until the user defines it. Ask what paths are in play,
  then write them:
  ```
  H=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
  printf '%s\n' <paths the user names> > /tmp/claude-scope-$H
  ```
  Only use `*` (whole repo) if the user explicitly says the task is repo-wide.
- **read-set:** whatever the user points to — nothing pre-decided.
- **skills:** opt-in — load/unload (`/skills load <name>`) and install/update/extract/
  delete (`skill-curator` skill) are both fine. Only editing mechanics
  (`scripts/skillctl.sh`, hooks, mode files) belongs in the `system-dev` scope.
- **guardrails:**
  - Ask enough scoped questions to pin down goal, files, and skills before touching anything.
  - If the task turns out to match one of the other example scopes mid-conversation, re-declare to it.
