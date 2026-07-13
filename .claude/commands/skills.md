---
description: Thin skill loadout mechanics — list / load / unload / remove without reading skill-curator doctrine.
---
Run the skill mechanic directly. Do NOT read skill-curator's SKILL.md for this — that
doctrine is only needed to install/update/extract/delete a skill. Loading an
already-stored skill is a pure dir copy:

```
bash scripts/skillctl.sh $ARGUMENTS
```

Argument forms:
- (no args) or `list` / `status` → show the active + dormant loadout
- `load <name>...` → copy dormant skill(s) into the active set (live immediately)
- `unload <name>...` → remove the active copy (the store master is kept)
- `remove <name>...` → delete the store master entirely (bare dir delete — refuses
  if still active; use only for a skill with no references elsewhere in the system,
  otherwise see skill-curator's `delete` for a full cross-reference teardown)

Notes:
- Activation is local + gitignored — a skill you load here does NOT leak to other
  branches or main (only the always-on whitelist in `.gitignore` is committed).
- If `load` says "not in store", the skill isn't catalogued yet → that needs the full
  install flow: invoke the `skill-curator` skill and follow its §install.
- After a load/unload, state in one line what is now active. If a loaded skill declares
  `exclusive-with` a currently-active skill, flag it before proceeding.
