---
name: domain-modeling
description: Build and sharpen a project's shared vocabulary — the terms specific to what's being built. Use when the user wants to pin down what a term means, resolve a naming conflict, or when grill-me surfaces a fuzzy or overloaded word. Maintains .claude/memory/CONTEXT.md.
group: productivity
disable-model-invocation: false
---

# Domain modeling — the project's shared vocabulary

Actively build and sharpen the glossary of terms specific to THIS project as you design — challenging fuzzy words, probing edge cases, and writing each term down the moment it's settled. This is the *active* discipline, not passive reading: reading `CONTEXT.md` for vocabulary is a one-line habit any skill can do; this skill is for when you're *changing* the model.

## File: `.claude/memory/CONTEXT.md`
The glossary lives at `.claude/memory/CONTEXT.md` — beside `INDEX.md` (what exists) and `SPEC.md` (what's coming) as the third of the memory triad: **what the terms mean**. Always writable in every scope (`.claude/memory/**` is unconditionally allowed by the scope-guard). Surfaced in full at every session start by `session-start-hook.sh` (zero-cost when absent), so every session opens already sharing the vocabulary.

Create it **lazily** — only when the first real project-specific term is settled. A project with no special vocabulary needs no `CONTEXT.md`; don't force one.

**Cap: 80 non-empty lines**, enforced by `validate.mjs --memory` alongside every other memory file. Terms are canonical vocabulary, not a log — they're rarely evicted. If ever over cap, that's a signal to retire terms genuinely no longer relevant to current work, not to trim definitions thinner.

`CONTEXT.md` is a glossary and nothing else — no implementation details, no decisions (those live in `SPEC.md`'s "What matters" and the memory maps' "Recent decisions"), no scratch notes.

### Format
```md
# Terms

**Segment**:
A saved filter over the audience — a named set of rules, not a fixed list of people.
_Avoid_: group, list, cohort

**View**:
One arrangement of panels a user can switch between on a dashboard.
_Avoid_: tab, layout, page
```
- **Be opinionated.** When several words mean the same thing, pick the best one; list the rest under `_Avoid_`.
- **Keep definitions tight.** One or two sentences. Define what it IS, not what it does.
- **Only project-specific terms.** If it's a general web or programming concept (button, dropdown, cache), it doesn't belong — only words that carry a meaning unique to this project. Ask before adding: would this mean the same thing on any project, or is it special to *this* one? Only the latter belongs.
- **Group under subheadings** only if natural clusters emerge; a flat list is fine.

## While designing (especially inside a grill-me session)
- **Challenge conflicts.** A new use of a term clashes with the glossary → call it out immediately. "Your glossary defines 'segment' as a saved filter, but you're using it to mean a fixed list — which is it?"
- **Sharpen fuzzy words.** A vague or overloaded term → propose one precise canonical word. "You're saying 'user' — the person viewing the dashboard, or the account it belongs to? Those differ."
- **Probe with a scenario.** When two concepts blur, invent a concrete case that forces the boundary. "If someone edits the filter after sharing it, does the shared link show the old results or the new ones?"
- **Write it down inline.** The moment a term is settled, add it to `CONTEXT.md` right then — don't batch. Announce first: "Updating CONTEXT.md: pinning 'segment' as a saved filter, not a fixed list."
- **Flag contradictions with what's built.** If a settled term contradicts what a route or section already does or says, surface it rather than quietly papering over it.

## Relationship to the rest of the system
- Compatible with **grill-me**: when an interview surfaces or overloads a term, run this alongside to capture it — grill-me resolves the plan, this pins the words.
- **project-memory** maps *where things live*; this maps *what words mean*. Different layers — a route map may reference a term, but never restates the glossary.
- **spec** records what's being built and its tickets; `CONTEXT.md` never holds ticket or plan content.

<!-- adapted from github:mattpocock/skills — skills/engineering/domain-modeling (pinned commit 16a2a5c); heavily rewritten 2026-07-14: stripped to glossary-only — dropped ADRs / docs/adr and the bounded-context / CONTEXT-MAP.md machinery (both softdev-DDD-specific), moved CONTEXT.md from repo root to .claude/memory/CONTEXT.md (scope-guard always-writable + memory triad + session-start injection), inlined the term format (deleted CONTEXT-FORMAT.md + ADR-FORMAT.md). Local mods kept: announce-when-writing rule, project-memory cross-reference note. -->
