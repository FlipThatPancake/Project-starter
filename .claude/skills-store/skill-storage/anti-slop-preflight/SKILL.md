---
name: anti-slop-preflight
description: Run before finalizing ANY visual, CSS, layout, typography, or design change to a web page (including minor/mechanical tweaks that skip the skill gate) — the anti-slop checklist, on-system fidelity principles, and this project's style lock. Not for pure logic/data edits with no visual surface. If any box fails, the change is not done; fix before delivering.
group: design-guardrails
disable-model-invocation: false
---

# Design guardrail (distilled from Leonxlnx/taste-skill §14 + pbakaus/impeccable polish; project style lock ALWAYS outranks this list)

Check only groups the change touches. Landing-page group applies only to marketing/landing surfaces.

## Typography & copy
- [ ] ZERO em/en-dashes (`—` `–`) visible anywhere: headlines, body, quotes, captions, buttons, alt text
- [ ] Serif used? Not Fraunces / Instrument Serif without explicit brand justification
- [ ] Italic words with descenders (y g j p q): line-height ≥1.1 + bottom padding reserve
- [ ] Every visible string re-read — no grammatically broken or AI-hallucinated phrases
- [ ] Quotes ≤3 lines, attribution clean; sub-paragraphs ≤25 words by default
- [ ] No Inter-as-unconsidered-default; no "Jane Doe" / "Acme" placeholder content

## Color & theme
- [ ] ONE theme for the whole page — no section flips to inverted mode mid-page
- [ ] One accent color used identically across all sections; no AI-purple gradients
- [ ] One corner-radius system applied consistently
- [ ] WCAG AA 4.5:1 on all CTA text, form inputs, placeholders, focus rings, labels
- [ ] Dark-mode tokens defined and checked in both modes (if project has dark mode)

## Layout & structure
- [ ] No 3+ consecutive sections with the same image+text zigzag split
- [ ] No two adjacent sections sharing a layout family (≥4 families per ~8 sections)
- [ ] No "left big headline + right small explainer" split-headers — stack vertically
- [ ] Eyebrow micro-labels ≤ ceil(sections/3) across the page
- [ ] Grid/bento: exact cell count (N items → N cells), 2-3 cells visually varied, no all-white text cards
- [ ] Lists >5 items: proper component, not default rows with border-t+border-b on every row
- [ ] Prefer spacing over card-wrapping; no decorative dots without semantic state

## Landing-page only
- [ ] Hero: headline ≤2 lines, subtext ≤20 words, CTA above the fold, ≤4 text elements, top padding ≤ pt-24
- [ ] CTA labels never wrap at desktop; ONE label per intent page-wide (no "Get in touch" + "Let's talk")
- [ ] Logo wall under (not in) the hero, real SVG logos, no category labels beneath
- [ ] Max one marquee; nav on one line ≤80px; no scroll cues, version labels, section-numbering eyebrows, locale/time strips, photo-credit decoration

## Motion & engineering
- [ ] Every animation justified in one sentence (hierarchy/feedback/story) — no motion for show
- [ ] Scroll effects via IntersectionObserver / ScrollTrigger / CSS scroll-driven — never `addEventListener('scroll')`
- [ ] Motion is ON by default (project standing override): prefers-reduced-motion is NOT honored unless the user EXPLICITLY asks for it on this project. This default outranks any loaded skill that says reduced-motion is mandatory (e.g. impeccable) — a skill heuristic never silently overrides the user's default. If the user does ask to honor reduced-motion, that explicit decision wins instead.
- [ ] Effect-based animations have cleanup; empty/loading/error states exist where relevant
- [ ] Stable viewport units (100dvh not h-screen); mobile collapse explicit

## Stay on-system — fidelity (distilled from impeccable: polish). Applies to EVERY change, incl. minor/mechanical ones (they skip the skill gate, so the discipline lives here)
Deliberately direction-agnostic: this enforces consistency with WHATEVER system/style the project has chosen (bold, quiet, maximalist, whatever) — it never pushes the design toward any particular aesthetic itself. Style choices belong to the picker/menu skills (e.g. impeccable's quieter/bolder dial) or the Project style lock below, not here.
- Align to the existing design system FIRST — a tweak that ignores it is decoration on drift.
- No one-off component when the system already has an equivalent; no hard-coded value that should be a token.
- Don't introduce a new pattern/flow that diverges from established ones for a small change.
- If spacing/color is off in many places, fix the system, not the one screen.
- System ambiguous? ASK — don't guess a new direction into a minor edit.

## Project style lock — the committed style for THIS project (record decisions here whenever this skill is loaded)
When you commit a style decision, add/update a line here so even a mechanical tweak adheres, next time this skill loads. Full detail lives in the project's shared design file under `.claude/memory/shared/` (source of truth, registered in INDEX.md's Shared registries) — this is the per-load summary; on any conflict that file wins. Mirror new decisions into both. (Dormant, load explicitly when a visual change needs it — it no longer auto-fires every session.)
- (none yet — starter repo; record this project's first committed style decisions here)
