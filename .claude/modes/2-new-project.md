# Mode 2 — new project (bootstrap)

Turn a fresh copy of the starter into a real project. **This is where structure
& stack are decided** — there is no standalone/portal flag anymore; the shape you
choose here is simply reflected by how many routes exist.

- **allowlist:** everything (`*`)
  ```
  H=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
  echo '*' > /tmp/claude-mode-$H
  ```
- **read-set:** `README.md` (bootstrap steps) + `.claude/memory/INDEX.md` + `src/routes/_skeleton/`.
- **skills:** gate on the store (see `.claude/skills-store/MODE-SHORTLISTS.md` row for this mode); design/build skills as the chosen stack needs.

## Steps
1. **Ask the structure & stack** (don't assume). At minimum: multi-route web app
   vs. a single HTML file; shared design system or not; any framework.
2. **Ask which branch to copy starter files from.** The session-start hook already
   listed remote branches by recency; surface them and confirm the source branch
   before copying. If unsure which is freshest, re-run:
   ```
   git for-each-ref --sort=-committerdate refs/remotes --format='%(refname:short) — %(committerdate:relative)'
   ```
3. Bootstrap per README: create routes (`cp -r src/routes/_skeleton src/routes/<route>`),
   register them in `INDEX.md`, fill `src/shared/tokens.css` only if routes will share a system.
4. **Flip the state:** set `state: in-progress` in `.claude/memory/INDEX.md`
   (it was `starter`). This is what future sessions detect to skip the bootstrap steer.
5. Commit: `scripts/ship.sh "chore: bootstrap project"`.

## Guardrails
- Never assume the stack — a wrong guess here shapes the whole project. Ask.
- The mother `Project-starter` repo must stay `state: starter`; only flip on a real new project.
