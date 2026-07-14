---
name: spec
description: Turn a finished grill-me session into a short written spec in .claude/memory/SPEC.md, and track its tickets as they ship. Use when a grill-me session reaches shared understanding, when the user says "write the spec" or "/spec", or asks what's open.
group: productivity
disable-model-invocation: false
---

# Spec — durable plan + ticket tracking

Turns a grill-me session's shared understanding into a short, living document at `.claude/memory/SPEC.md`, and tracks the tickets (shippable, demoable chunks — usually one route or section) needed to build it.

## When it fires
- A grill-me session just reached shared understanding (self-fires — announce first).
- The user says "write the spec", "/spec", or asks what's open/pending.
- Every session start: read `SPEC.md` if it exists (see "Session start" below) — this is a read, not a firing of the write behavior.

## Announce when firing
State plainly before writing, e.g. "Writing this up as a spec in `.claude/memory/SPEC.md`." — same courtesy grill-me gives before its first question.

## Session start
`SPEC.md`, if present, is surfaced automatically at the start of every session by `session-start-hook.sh` (same zero-token-when-absent mechanism as the skill index). Read it before starting work — tickets aren't necessarily tackled in order or one-per-session, so treat the whole open list as live, not just a single "next" item.

## File: `.claude/memory/SPEC.md`
One living file, the forward-looking twin of `INDEX.md`. `INDEX.md` records what exists (rear-view); `SPEC.md` records what's coming (road ahead). Always writable in every mode — `.claude/memory/**` is unconditionally allowed by the scope-guard hook, no allowlist edits needed.

Create it lazily — only when the first spec is written. Don't pre-create an empty file.

**Cap: 120 non-empty lines**, enforced by `validate.mjs --memory` alongside every other memory file. If a project's section is fully shipped (every ticket checked), delete that whole section rather than letting it accumulate — `SPEC.md` is a working plan, not a shipped-work archive (that's `INDEX.md`'s job). If nearing the cap with active work still open, that's a signal the spec is trying to hold too much — split by project/feature name rather than trimming ticket detail that's still needed.

### Format
```markdown
# Spec

## <project or feature name>
What it is: <one or two sentences>
What matters:
- <non-negotiable decision locked during grilling>
- <another one>

Tickets:
- [ ] <ticket name> — done when: <concrete, observable finish line>
- [ ] <ticket name> — done when: <finish line>   (after: <ticket it depends on, if a real blocking dependency exists>)
- [x] <a ticket already shipped>
```

A **ticket** is one whole thing working end-to-end — usually one route or one section. Not "all the layout, then all the data, then all the interaction." Tickets don't have to be tackled in listed order or one per session — several small ones may get done in a single sitting, out of sequence. Only add `(after: ...)` when one ticket genuinely can't start before another; otherwise leave the ordering loose.

## What this skill does
1. Reads the existing `SPEC.md` if one exists; never clobbers it.
2. Appends a new section (new project/feature) or updates an existing one — write only what changed.
3. Writes "What it is" and "What matters" from what was just locked in the grill-me session.
4. Writes the ticket list.
5. Stops. This skill does not build anything.

## Ticking a box — explicit confirmation only, every time
Whether a ticket is actually *done* is a decision, not an observable fact — a file existing doesn't mean it meets the done-when criterion. So:
- Only the user ticks a box. Never tick one silently, never infer completion from a diff, a build, or a `ship-now` push.
- If a done-when criterion looks satisfied, ask first — e.g. "Tick '<ticket name>' as done?" — and tick it only on explicit yes ("yes", "tick it", "done", or equivalent). A "no" or non-answer leaves it unchecked.
- Ask about one ticket at a time, the same way grill-me asks one question at a time.

## Relationship to other skills
- `checkpoint`/`INDEX.md` record what got built (rear-view). This skill records what's coming (road ahead). They don't overlap or need reconciling.
- `handoff` should reference `SPEC.md`'s open tickets when recording session continuity.
- `domain-modeling`'s `CONTEXT.md` is strictly product vocabulary — never duplicate ticket/spec content there.

<!-- built for this repo, 2026-07-14; idea borrowed from github:mattpocock/skills — skills/engineering/to-spec and to-tickets — but rebuilt from scratch: single file instead of separate spec+ticket docs, no dependency graph/GitHub Issues/ticket-type taxonomy, plain "spec/ticket" vocabulary instead of Matt's terminology. Dropped the "next up" single-pointer concept per user ruling 2026-07-14 (tickets are small and often tackled out of order, several per session) in favor of surfacing the whole open list at session start. Ticking requires explicit per-ticket confirmation, never inferred. Not a vendored copy — no LOCK.md row. -->
