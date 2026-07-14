---
name: spec
description: Turn a finished grill-me session into a short written spec in .claude/memory/SPEC.md, and track its tickets as they ship. Use when a grill-me session reaches shared understanding, when the user says "write the spec" or "/spec", or asks what's next up.
group: productivity
disable-model-invocation: false
---

# Spec — durable plan + ticket tracking

Turns a grill-me session's shared understanding into a short, living document at `.claude/memory/SPEC.md`, and tracks the tickets (shippable, demoable chunks — usually one route or section) needed to build it.

## When it fires
- A grill-me session just reached shared understanding (self-fires — announce first).
- The user says "write the spec", "/spec", or asks "what's next up".

## Announce when firing
State plainly before writing, e.g. "Writing this up as a spec in `.claude/memory/SPEC.md`." — same courtesy grill-me gives before its first question.

## File: `.claude/memory/SPEC.md`
One living file, the forward-looking twin of `INDEX.md`. `INDEX.md` records what exists (rear-view); `SPEC.md` records what's coming (road ahead). Always writable in every mode — `.claude/memory/**` is unconditionally allowed by the scope-guard hook, no allowlist edits needed.

Create it lazily — only when the first spec is written. Don't pre-create an empty file.

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
- [ ] <ticket name> — done when: <finish line>   (after: <ticket it depends on, if any>)
- [x] <a ticket already shipped>

Next up: <name of the first open ticket that isn't waiting on another>
```

A **ticket** is one whole thing working end-to-end, then the next — usually one route or one section, ordered shared/foundation work first. Not "all the layout, then all the data, then all the interaction."

**Next up** is a one-line pointer: the first unchecked ticket not blocked by an earlier one. No separate tracker, no dependency graph — just read top to bottom.

## What this skill does
1. Reads the existing `SPEC.md` if one exists; never clobbers it.
2. Appends a new section (new project/feature) or updates an existing one — write only what changed.
3. Writes "What it is" and "What matters" from what was just locked in the grill-me session.
4. Writes the ticket list in build order.
5. Sets "Next up".
6. Stops. This skill does not build anything and does not check boxes on its own — a ticket's box gets checked when it actually ships (a plain edit, done by hand, by `ship-now`, or on request).

## Relationship to other skills
- `checkpoint`/`INDEX.md` record what got built (rear-view). This skill records what's coming (road ahead). They don't overlap or need reconciling.
- `handoff` should point at `SPEC.md`'s "Next up" line when recording session continuity.
- `domain-modeling`'s `CONTEXT.md` is strictly product vocabulary — never duplicate ticket/spec content there.

<!-- built for this repo, 2026-07-14; idea borrowed from github:mattpocock/skills — skills/engineering/to-spec and to-tickets — but rebuilt from scratch: single file instead of separate spec+ticket docs, no dependency graph/GitHub Issues/ticket-type taxonomy, plain "spec/ticket/next up" vocabulary instead of Matt's terminology. Not a vendored copy — no LOCK.md row. -->
