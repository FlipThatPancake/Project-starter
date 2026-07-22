# Scope redesign spec — retire fixed modes, keep a free-form declared scope

**Date:** 2026-07-22 · **Branch:** claude/mode-scope-limitations-nd8pav · **Mode:** 1-system-dev
**Status:** DRAFT — awaiting user sign-off on the open decisions (§7) before implementation.

## 1. Goal (one line)
Replace the fixed 7-mode menu + always-on write wall with a **free-form declared
scope** that is **advisory by default** and **hard-blocking only when opted in** —
keeping the one protection the wall genuinely provides for the case that earns it,
and dropping the override tax on everything else.

## 2. Why (the diagnosis this spec acts on)
The mode system originally bundled three jobs: (a) read orientation / token
discipline, (b) a **mandatory skill gate**, (c) a write wall. Job (b) is already
gone — skills went opt-in and the session-start hook injects the index for free.
Of what remains, two independent misfits surfaced in real (non-starter) projects:

1. **The write wall is drawn around the wrong unit.** Route modes (3/4) allow only
   `src/routes/<route>/`. Real route work legitimately *writes* shared tokens,
   assets, and docs — so those edits got blocked and overridden. The wall fires on
   true positives (intended cross-scope edits), not just accidental wandering.
   (Note: **Read was never gated**, and `.claude/**` is always writable — so any
   pain reading reference files/docs, or writing memory, was *not* the wall; that
   was the lazy-read guidance mis-orienting a data session.)
2. **The taxonomy has no slot for a whole class of work.** "Build a database from
   reference files, parse data before building" is data/ingest work. The 7 modes are
   entirely UI-shaped (routes, shared design system, page routing). Such sessions
   land in mode-7 "other", whose spec is "ask the user to define scope" — i.e. the
   menu punts.

Root cause: the system hard-codes one project shape (multi-route UI app + shared
design system) into a fixed menu and an always-on wall. Every project that isn't
that shape springs a leak, patched with an override.

## 3. What we KEEP (these never needed the menu or the wall)
- One-line session-purpose restatement (orientation).
- A declared scope line (now **free-form**, not a menu pick).
- The `SESSION-LOG.md` trail (harness-independent history).
- Commit provenance prefix + self-created-branch slug.
- Lazy reading (soft guidance — the real token-saver).
- The **capability** of a hard write wall, for when it's earned (see §4).

## 4. The new model
Three parts replace "pick 1 of 7 modes + lock its allowlist":

1. **Declare scope (free-form).** At session start, after the purpose line, state a
   free-form scope — the path prefixes this session intends to write, e.g.
   `building the ingest layer — will write data/, refs/, src/shared/schema/`.
   Written to a single lock file as newline-separated prefixes (same format the
   hook already parses). A lone `*` = whole-repo (replaces mode 2).
2. **Advisory by default.** Edits outside the declared prefixes are **allowed**, with
   a one-line nudge surfaced to Claude ("editing `X` — outside your declared scope
   `[…]`; intended?"). No `exit 2`, no override ceremony. This covers the
   data/cross-cutting/shared work that caused the overrides.
3. **Hard-block as an opt-in.** When you *want* the deterministic guardrail — the
   huge-multi-route project doing tightly-scoped route-local edits — you flip the
   scope to enforcing for that session. Out-of-scope edits then `exit 2` (today's
   behavior). This preserves the wall's unique value (deterministic, at-write-time,
   before-review prevention) precisely when it's earned, instead of always-on.

`.claude/**` stays always-writable in both modes (memory/logs/skills), unchanged.

## 5. Hook behavior spec (`scripts/scope-guard-hook.sh`)
Single lock file (unify the two current files — the legacy route lock
`/tmp/claude-route-scope-$H` folds into the one scope file; the mode allowlist
supersedes it today anyway). Contents = newline-separated write-prefixes.

| situation | today | after |
|---|---|---|
| no lock file | allow (exit 0) | allow (exit 0) — unchanged |
| edit inside declared prefixes | allow | allow — unchanged |
| edit to `.claude/**` | allow | allow — unchanged |
| edit outside, **advisory** (default) | n/a | **allow + nudge** (see mechanism below) |
| edit outside, **enforcing** (opt-in) | block (exit 2) | block (exit 2) — unchanged |
| guarded tool, unparseable payload (no-jq) | fail closed (exit 2) | fail closed (exit 2) — unchanged |
| non-Edit/Write tool | pass through | pass through — unchanged |

**Opt-in-block mechanism (Decision D-block, §7):** recommended = a sentinel first
line in the scope file (`#enforce`) OR a sibling flag file
`/tmp/claude-scope-enforce-$H`. Default recommendation: **sibling flag file** —
keeps the prefix parser untouched and the allow-path trivially backward-compatible.

**Advisory-nudge mechanism (must verify against the Claude Code hooks API at
implementation time):** a PreToolUse hook that *allows but informs* is not plain
`exit 0` (stderr on exit 0 isn't reliably surfaced to Claude). Intended path: emit
JSON on stdout with `hookSpecificOutput.permissionDecision: "allow"` +
`permissionDecisionReason: "<nudge>"` (falling back to exit-0-with-stderr if that
field isn't honored in this harness). **This is the one implementation unknown to
confirm first** — the whole "advisory but visible" behavior depends on it.

## 6. File-by-file change list
- `scripts/scope-guard-hook.sh` — advisory default + opt-in enforce flag; unify to
  one lock file; keep fail-closed jq fallback.
- `scripts/test-tooling.mjs` — `guard()` gains an `enforce` option. Rewrite the
  "blocks outside" cases: default now expects allow (exit 0); a new enforcing case
  expects exit 2. Keep the fail-closed no-jq assertions.
- `scripts/session-start-hook.sh` — stop steering to a mode pick; prompt for the
  free-form purpose + declared-scope line. Drop the "1..7" menu framing.
- `.claude/modes/` — **Decision D-menu (§7).** Either delete the 8 files (menu
  retired) or keep 1–2 as *optional example presets* referenced from the protocol.
- `.claude/modes/MODES_PROTOCOL.md` → rename/rewrite to `SCOPE_PROTOCOL.md`:
  declare-scope + advisory/enforce, no menu. (Keep old filename as a stub redirect?
  — minor, decide at edit time.)
- `CLAUDE.md` — rewrite the session-rules table: "Mode first" → "Scope first
  (free-form)"; "Mode is explicit" → declared-scope + commit prefix; drop
  menu/allowlist-per-mode language; keep memory-first, lazy-reading, batch-commits,
  checkpoint rows as-is.
- `scripts/ship.sh` — align the `@allow-cross-route` commit gate with the new model
  (advisory by default; only meaningful when enforcing). Verify + adjust.
- `SESSION-LOG.md` header + row format — `| date | branch | mode | scope |` →
  `| date | branch | scope |`; commit prefix `[mode:<n>-<slug>]` → `[scope:<slug>]`
  (**Decision D-prefix, §7**).
- Sweep stale references found by grep: `.claude/skills/project-memory/SKILL.md`
  (+ its HANDOFF), `domain-modeling/SKILL.md`, `spec/SKILL.md`, `README.md`,
  `.claude/settings.json` (hook wiring stays — same file, new behavior).

## 7. Decisions (RESOLVED — user sign-off 2026-07-22)
- **D-menu → KEEP ALL 8, DEMOTE TO EXAMPLES.** The 8 mode files stay but are
  reframed as *non-binding example scopes* referenced from the protocol, not a menu
  you must pick from. No deletions. Rewrite their framing so nothing reads as a
  mandatory "pick 1 of 7" gate or an enforced allowlist; they become worked examples
  of how to write a declared scope (route-local, shared, system-dev, data/ingest…).
  → **Add a data/ingest example** so the UI-shaped set stops being the only guidance.
- **D-prefix → KEEP as `[scope:<slug>]`.** Reword the commit prefix from
  `[mode:<n>-<slug>]` to `[scope:<slug>]`; cheap greppable provenance retained.
- **D-block → sibling flag file** `/tmp/claude-scope-enforce-$H` (existence flips
  advisory→enforcing; prefix parser untouched, allow-path backward-compatible).
- **D-rename → rename** `claude-mode-$H` → `claude-scope-$H` across hook + tests +
  ship.sh + session-start-hook for clarity (contained set of call sites).

## 8. Test / validation plan
- `node scripts/test-tooling.mjs` — updated guard() cases (advisory-allow,
  enforce-block, fail-closed) all green.
- `node scripts/validate.mjs --all` — memory + skills shape still valid after the
  SESSION-LOG format change and any mode-file deletions.
- Manual: confirm the advisory-nudge JSON path actually surfaces to Claude in this
  harness (the §5 unknown) before finalizing.

## 9. Non-goals
- Not changing skills (already opt-in), lazy-reading, memory maps, or the
  checkpoint/ship flows beyond the wording/prefix touch-ups above.
- Not removing provenance (SESSION-LOG, commit prefix) — only reshaping it.
