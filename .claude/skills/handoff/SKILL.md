---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
group: session-mgmt
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save it into this repo, not the OS temp directory — `.claude/memory/handoffs/<YYYY-MM-DD>-<branch>.md` — so it survives container teardown and is visible to the next session (this project runs in ephemeral containers; nothing outside the repo persists).

Record this session's declared scope (the prefixes, and the `.claude/modes/*.md` example it was cribbed from if any) and, if the repo is multi-route, the route in scope. The next agent still runs its own scope-declaration step per the session-start protocol — this is context for "is this a direct continuation," not a substitute for that confirmation.

Include a "suggested skills" section in the document, naming skills the next agent should `/skills load` and why.

Do not duplicate content already captured in other artifacts (PRDs, plans, ADRs, issues, commits, diffs, `.claude/memory/SESSION-LOG.md`, `.claude/memory/INDEX.md`). Reference them by path instead — the next agent reads memory first per this repo's rules, so restating structure here just goes stale.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.

<!-- adapted from github:mattpocock/skills — skills/productivity/handoff; local mods: (1) save location (repo path, not OS temp) — ephemeral containers require persisting into the repo, (2) records the session's locked mode + route scope for continuity with this repo's mode-first protocol, (3) reference list keeps "PRDs" (upstream's own wording at our pin commit 16a2a5c; upstream later narrowed it back to "specs" in 697d4ce — declined) and adds `.claude/memory/SESSION-LOG.md` + `INDEX.md` pointers -->
