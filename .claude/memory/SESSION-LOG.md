# SESSION LOG — one row per session; newest first; keep last 20 (evict oldest)
Format: `| date | branch | mode | scope |`. Appended on mode lock (`.claude/modes/README.md` §Branch & log). This is the persistent, harness-independent record of what each session/branch was scoping on — read this, not the branch name, to know what a past session did.

| date | branch | mode | scope |
|---|---|---|---|
| 2026-07-07 | claude/memory-skill-store-expansion-zvcvk4 | 1-system-dev | installed 4 tapestry research skills into store (Phase 1: session-log, learn-this, article-extractor, ship-learn-next). Re-locked from a mistaken 7-other. Reworked session-start flow: purpose restatement (wait if ambiguous) + skill offer→GATE (full catalog, wait for confirm/redaction, every mode) across hook/modes/skill-manager/CLAUDE.md; clarified skills/** (mode-1-only) vs skills-store/** (any mode). |
| 2026-07-07 | claude/verify-environment-setup-ut7dpn | 1-system-dev | copied `.claude/` scaffolding from M3.o-june26-survey-report; built the session-mode selection system (modes/, session-start-hook, scope-guard mode allowlist, state: starter\|in-progress); reconstructed missing test fixtures; added CLAUDE_AUTO_PUSH_TO_MAIN toggle to ship.sh |
