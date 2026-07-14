---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
group: session-mgmt
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save it into this repo, not the OS temp directory — `.claude/memory/handoffs/<YYYY-MM-DD>-<branch>.md` — so it survives container teardown and is visible to the next session (this project runs in ephemeral containers; nothing outside the repo persists).

Include a "suggested skills" section in the document, which suggests skills that the agent should invoke.

Do not duplicate content already captured in other artifacts (PRDs, plans, ADRs, issues, commits, diffs, `.claude/memory/SESSION-LOG.md`). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.

<!-- adapted from github:mattpocock/skills — skills/productivity/handoff; changes: (1) save location (repo path, not OS temp), (2) reference-list wording widened from "specs" to "PRDs" plus an explicit `.claude/memory/SESSION-LOG.md` pointer, to match this repo's actual artifact set -->
