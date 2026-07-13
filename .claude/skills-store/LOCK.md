# SKILL LOCK — provenance + pinned versions of THIRD-PARTY store skills only. Read/written by skill-curator update ops. First-party skills (skill-curator, project-memory, checkpoint, anti-slop-preflight) are ours → not tracked here.
last-checked: 2026-07-07
pinned-ref = the upstream commit (short SHA) we vendored. upstream-date = that commit's OWN authorship date (from git history, not filesystem mtime — hardcoded text here so it survives any re-clone/re-copy of the skill dir, e.g. via the starter-repo). installed = when WE vendored it into this project (local event, separate from upstream-date). local-mods = edits we made to our copy that an update must PRESERVE. Rollback = re-install the previous pinned-ref.

| skill | source | pinned-ref | upstream-date | installed | local-mods |
|---|---|---|---|---|---|
| session-log | github:michalparkola/tapestry-skills | 80e1dc5 | 2026-07-04 | 2026-07-07 | group/allowed-tools frontmatter added (v3 metadata distribution) |
| learn-this | github:michalparkola/tapestry-skills | 80e1dc5 | 2026-07-04 | 2026-07-07 | group/allowed-tools frontmatter added (v3 metadata distribution) |
| article-extractor | github:michalparkola/tapestry-skills | 80e1dc5 | 2026-07-04 | 2026-07-07 | group/allowed-tools frontmatter added (v3 metadata distribution) |
| ship-learn-next | github:michalparkola/tapestry-skills | 80e1dc5 | 2026-07-04 | 2026-07-07 | group/allowed-tools frontmatter added (v3 metadata distribution) |
