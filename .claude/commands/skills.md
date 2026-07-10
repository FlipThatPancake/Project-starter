---
description: Thin skill loadout mechanics — list / load / unload without reading skill-manager doctrine.
---
Run the skill mechanic directly. Do NOT read skill-manager's SKILL.md for this — that
doctrine is only needed to install a BRAND-NEW skill from the web. Loading an
already-stored skill is a pure dir copy:

```
bash .claude/skills/skill-manager/scripts/skillctl.sh $ARGUMENTS
```

Argument forms:
- (no args) or `list` / `status` → show the active + dormant loadout
- `load <name>...` → copy dormant skill(s) into the active set (regenerates INDEX; live immediately)
- `unload <name>...` → remove the active copy (the store master is kept)

Notes:
- Activation is local + gitignored — a skill you load here does NOT leak to other
  branches or main (only the always-on whitelist in `.gitignore` is committed).
- If `load` says "not in store", the skill isn't catalogued yet → that needs the full
  `add` flow: invoke the `skill-manager` skill and follow its §add.
- After a load/unload, state in one line what is now active. If a loaded skill declares
  `exclusive-with` a currently-active skill, flag it before proceeding.
