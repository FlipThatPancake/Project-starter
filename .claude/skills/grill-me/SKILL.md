---
name: grill-me
description: Grill the user relentlessly about a plan or design. Use when the user wants to stress-test a plan before building, or uses any 'grill' trigger phrases.
group: productivity
disable-model-invocation: false
---

# Grill-me — relentless interview

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time, waiting for feedback on each question before continuing. Asking multiple questions at once is bewildering.

If a *fact* can be found by exploring the codebase, look it up rather than asking me — but stay within the current mode's scope (its read-set / allowlist) while doing so; only reach beyond it when doing so is clearly warranted for the question at hand, or I've said so explicitly. The *decisions*, though, are mine — put each one to me and wait for my answer.

Do not enact the plan until I confirm we have reached a shared understanding.

## This-repo addition: announce when firing
State plainly before the first question, e.g. "Running a grill-me session on this." — whether you triggered it by name, by a "grill" phrase, or on your own judgment that a plan needs stress-testing before being built. The user should never be mid-interview without knowing that's what's happening.

## Optional: capture terms and decisions as you go
If the plan introduces domain terms worth pinning down or hard-to-reverse decisions worth recording, also run `domain-modeling` alongside the interview.

<!-- collapsed from github:mattpocock/skills (pinned commit 16a2a5c) — originally three skills: grilling (engine), grill-me (alias, no-op body: "Run a /grilling session"), grill-with-docs (alias + domain-modeling clause). Merged into one per user ruling 2026-07-14: kept the grill-me name (sticky for this user), grilling's engine body + local mods verbatim, and folded grill-with-docs's docs-clause in as an optional paragraph. Local mods preserved: (1) announce-when-firing rule (2026-07-07), (2) fact-finding scoped to current mode's read-set, declined upstream's later "environment (filesystem, tools, etc.)" broadening as unbounded scope-creep risk (2026-07-14). -->
