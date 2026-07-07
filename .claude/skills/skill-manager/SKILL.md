---
name: skill-manager
description: Use when the user wants to see, load, unload, install, extract, or remove skills ("what skills are available", "load gsap", "add this skill", "start a design session"), when a session needs a capability beyond the pinned set, when the Stop hook or validate --skills reports loadout drift, or on a design-judgment task when menu-policy skills are installed (run the picker). Manages .claude/skills/ (active) vs .claude/skills-store/skill-storage/ (dormant, zero context cost) — the store's root holds only metadata .md files.
---

# Skill manager — loadout protocol

States: **active** = dir in `.claude/skills/` (in context, can trigger) · **dormant** = dir in `.claude/skills-store/skill-storage/` (zero tokens — metadata `.md` files live at the store's ROOT, never mixed with skill dirs) · **fixed** = harness/claude.ai/plugin skills (in session context, NOT controllable here — list live, never catalog).
Metadata (store, read when invoked, never preemptively): `CATALOG.md` (what exists + policy) · `MODULES.md` (sub-modules) · `CONFLICTS.md` (rulings the picker/add enforce) · `LOCK.md` (third-party pinned versions) · `MODE-SHORTLISTS.md` (per-mode starter picks for the entry GATE) · `WIKI.md` (deep evidence, only for analysis/onboarding). State is derived from folder location; never written.

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

## Mode-entry skill GATE — on every session-mode lock
When a session mode is locked (`.claude/modes/README.md` step 4), this is a GATE, not
an offer: do not install, load, or otherwise act on any skill until the user has
confirmed or redacted the list below — in EVERY mode, not just design.
- Print the **full catalogue as a markdown list** in chat (not a constrained picker —
  the catalogue is too large to fit ~4 options):
  - **Top: suggested picks** — build this from **`MODE-SHORTLISTS.md`'s row for the
    locked mode FIRST** (its curated starter guess for this mode), then broaden: scan
    the rest of CATALOG.md (Installed + Upstream) for anything else that matches the
    confirmed session purpose by keyword/category, even if absent from the shortlist.
    Merge both into 2–4 picks, each with a short why/how (≤1 line). If the shortlist
    and the actual task disagree (e.g. mode 5 but the task is visibly visual work),
    say so and follow the task, not the shortlist.
  - **Below: everything else by category** — `skillctl.sh status` grouped by
    CATALOG.md category, PLUS Upstream candidates `add` could pull in, PLUS dormant
    store skills not yet loaded. Note always-on pinned/ride-along skills as
    "already active" for transparency — they are not part of the choice.
- **Wait for the user's free-text reply** confirming or redacting the selection.
  Do not proceed to load/install anything until they respond.
- **Skip only when the user already named specific skills inline, or explicitly
  said "no skills" / "none"** in the prompt that triggered mode lock — then honor
  that directly instead of printing the list. Otherwise the gate is absolute:
  always show the full list, every mode, every session.
- Apply the same CONFLICTS.md checks as the menu picker before loading the chosen set.

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
9. Run the **New-skill mode-fit check** (below) before ending the turn.

## New-skill mode-fit check — runs after every `add` (and `extract`)
A newly-installed skill should be considered for `MODE-SHORTLISTS.md`, not just left
undiscoverable in the full catalogue. After step 8 above:
1. Read the new skill's category + description against each of the 7 mode one-liners
   (`.claude/modes/README.md` → "The 7 modes").
2. For every mode where it plausibly fits (category match, or description clearly
   serves that mode's kind of task), note it as a candidate addition to that mode's
   shortlist row — apply the same CONFLICTS.md exclusivity/precedence checks a normal
   shortlist entry would need.
3. Propose the fit(s) to the user in one line per mode ("fits mode 3/6 shortlist
   because X — add it?") and **wait for confirmation** — never add silently, since
   shortlist curation is a judgment call, not a mechanical derivation.
4. On confirmation, update the shortlist row(s) in `MODE-SHORTLISTS.md` only (never
   auto-load the skill itself — that still goes through the normal GATE/picker).
5. If it fits no mode particularly well, say so and leave `MODE-SHORTLISTS.md`
   untouched — not every installed skill needs to be in a shortlist.

## extract <parent>/<module>
When a module earns independent life (precedent: anti-slop-preflight ← taste-skill §14): distill it into its own store dir with frontmatter, add an Installed row (provenance in the note), flip its MODULES.md status to `extracted`, leave the parent untouched. Prefer extract over loading a whole deep skill for one module you use often. Then run the **New-skill mode-fit check** above — an extracted module is a newly-installed store skill too.

## Hard rules
- Fixed skills: report truthfully as "active — not controllable here"; never pretend to unload one.
- Packs (gsap, tapestry, accesslint): register/load MEMBERS individually.
- The manager never edits pinned rows and never unloads itself.
- **Mode scope:** `add`/`extract`/`remove` write only to `.claude/skills-store/skill-storage/`
  (dormant catalog) + the store's own root metadata (CATALOG.md/MODULES.md/LOCK.md/
  MODE-SHORTLISTS.md) — available in ANY mode. Only `load`/`unload` (which move a dir
  into/out of `.claude/skills/**`, the active loadout) and edits to the mechanics
  themselves (this file, `skillctl.sh`, the hooks, `.claude/modes/**`) are restricted
  to Mode 1 (system-dev).
