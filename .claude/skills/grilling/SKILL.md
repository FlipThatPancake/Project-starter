---
name: grilling
description: Grill the user relentlessly about a plan or design. Use when the user wants to stress-test a plan before building, or uses any 'grill' trigger phrases.
group: productivity
disable-model-invocation: false
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time, waiting for feedback on each question before continuing. Asking multiple questions at once is bewildering.

If a *fact* can be found by exploring the codebase, look it up rather than asking me — but stay within the current mode's scope (its read-set / allowlist) while doing so; only reach beyond it when doing so is clearly warranted for the question at hand, or I've said so explicitly. The *decisions*, though, are mine — put each one to me and wait for my answer.

Do not enact the plan until I confirm we have reached a shared understanding.

## This-repo addition: announce when firing
State plainly before the first question, e.g. "Running a grilling session on this." — whether you triggered it by name, by a "grill" phrase, or on your own judgment that a plan needs stress-testing before being built. The user should never be mid-interview without knowing that's what's happening.

<!-- adapted from github:mattpocock/skills — skills/productivity/grilling; local mods: (1) explicit-announce rule per user ruling 2026-07-07 (active every session, self-fires on judgment, but must say so), (2) fact-finding scoped to the current mode's read-set per user ruling 2026-07-14 — declined upstream's later broadening to "environment (filesystem, tools, etc.)" (upstream commit 697d4ce) as unbounded scope-creep risk; escape hatch is Claude's judgment or explicit user say-so -->
