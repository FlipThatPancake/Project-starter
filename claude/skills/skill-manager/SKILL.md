---
name: skill-manager
description: Use when the user wants to see, load, unload, install, extract, or remove skills ("what skills are available", "load gsap", "add this skill", "start a design session"), when a session needs a capability beyond the pinned set, when the Stop hook or validate --skills reports loadout drift, or on a design-judgment task when menu-policy skills are installed (run the picker). Manages .claude/skills/ (active) vs .claude/skills-store/ (dormant, zero context cost).
---

# Skill manager — loadout protocol

States: **active** = dir in `.claude/skills/` (in context, can trigger) · **dormant** = dir in `.claude/skills-store/` (zero tokens) · **fixed** = harness/claude.ai/plugin skills (in session context, NOT controllable here — list live, never catalog).
Metadata (store, read when invoked, never preemptively): `CATALOG.md` (what exists + policy) · `MODULES.md` (sub-modules) · `CONFLICTS.md` (rulings the picker/add enforce) · `LOCK.md` (third-party pinned versions) · `WIKI.md` (deep evidence, only for analysis/onboarding). State is derived from folder location; never written.

## Verbs (mechanics run in bash — `scripts/skillctl.sh` — never hand-move dirs)
| verb | do |
|---|---|
| list / status | `skillctl.sh status` + fixed skills from session context, grouped by category; capability hunts also check MODULES.md and Upstream candidates. First manager use in a new project & `LOCK.md` last-checked is stale/absent → offer `check-updates` |
| load <name…> / <profile> | run the load-time conflict check FIRST (`references/add-and-handoff.md` §3: already-active? sequential predecessor's files present → offer handoff §4? exclusive peer's files present → warn?), then `skillctl.sh load …`; profiles from `skills-store/profiles.md`; live immediately |
| unload <name…> / --all | `skillctl.sh unload …` — script refuses pinned/ride-along |
| add <source> | interactive install — §add below |
| extract <parent>/<module> | carve a module into a standalone store skill — §extract below |
| remove <name> | delete from store + its catalog row + its MODULES rows |
| sync | pull starter-repo URL from CATALOG header; unset → say so and stop. Also runs `check-updates` |
| check-updates | `skillctl.sh check-updates` — compare pinned refs (LOCK.md) to upstream HEAD; DETECTION ONLY, never applies. Auto-run at add/sync/new-project; Stop-hook nudges when stale (>7d) |
| update <skill> | review-gated apply — `references/updates.md`: diff description/footprint/local-mods/modules; RE-APPLY our local-mods; **reconcile the project's existing dependency files against the updated skill's new structure** (`structcheck.sh`, migrate on drift); never auto-apply |

## Menu picker — per TASK, never sticky
Menu skills are muted (`disable-model-invocation: true` in our copies), so they can never fire uninvited — this picker is their only activation path. Trigger: the task calls for design judgment (or a menu skill's domain) AND menu skills/modules are installed.
- Ask on EVERY new task/prompt. Follow-up iterations of the SAME task reuse the last choice; a new task asks fresh. No session persistence.
- Skip the ask when the user names skills inline ("use impeccable/typeset") or says "no skills".
- First read `CONFLICTS.md`: drop options that are `exclusive` with an already-active skill, present a `compatible` pair as the recommended **Combined**, and let `precedence` set ordering. An unrecorded conflict → resolve with the user, then append the ruling.
- Options (AskUserQuestion, multiSelect on): first = **"Combined: <the 2-3 complementary picks> (Recommended)"** when several genuinely fit; then individual skills and MODULES (`parent/module` granularity from MODULES.md — never "whole pack"); last = "None — pinned + guardrails only".

## Combine protocol (when ≥2 skills/modules are chosen)
1. Read ONLY the selected guidance files. 2. Overlapping rules → keep the single best fit per conflict, applying `CONFLICTS.md` precedence (default chain: project design-m3 › anti-slop-preflight › best task fit); unique rules → union. 3. Execution: single-stage task → apply the merged set at once; multistage task → assign skills/modules to stages (e.g. IA module → structure pass, typeset → typography pass) and state the stage map in one line before starting.

## add <source> — interactive install
1. Fetch into the store (`git clone --depth 1` / curl); read frontmatter description ONLY.
2. Classify pack / deep / standalone (`references/add-and-handoff.md` §1) and confirm with the user — a PACK registers members individually, never as a unit.
3. Recommend a policy from `references/catalog-format.md`; AskUserQuestion to confirm policy (recommended first) — and category when not obvious. Hand-dropped dirs flagged by drift start here too.
4. Check `CONFLICTS.md` + footprints (§2): `duplicate`/`exclusive` with something installed, or its dep files already in the repo → warn before writing the row; genuinely new overlap → propose a rule, append once the user rules; record the new skill's footprint in §2.
5. Write ONE Installed row (load-when = trigger, ≤10 words); policy=menu → set `disable-model-invocation: true` in our copy.
6. Deep/pack → index notable modules/members in MODULES.md (a module MAY sit in a different category than its parent).
7. Third-party source → `skillctl.sh pin <source>` for exact sha/date (deterministic, not filesystem mtime — survives re-cloning); record a `LOCK.md` row (source, pinned-ref=short sha, upstream-date, install date, local-mods e.g. "set disable-model-invocation").
8. `node scripts/validate.mjs --skills` must pass before the turn ends.

## extract <parent>/<module>
When a module earns independent life (precedent: anti-slop-preflight ← taste-skill §14): distill it into its own store dir with frontmatter, add an Installed row (provenance in the note), flip its MODULES.md status to `extracted`, leave the parent untouched. Prefer extract over loading a whole deep skill for one module you use often.

## Hard rules
- Fixed skills: report truthfully as "active — not controllable here"; never pretend to unload one.
- Packs (gsap, tapestry, accesslint): register/load MEMBERS individually.
- The manager never edits pinned rows and never unloads itself.
