# SKILL LOCK — provenance + pinned versions of THIRD-PARTY store skills only. Read/written by skill-manager update ops. First-party skills (skill-manager, project-memory, checkpoint, anti-slop-preflight) are ours → not tracked here.
last-checked: 2026-07-06
pinned-ref = the upstream commit (short SHA) we vendored. upstream-date = that commit's OWN authorship date (from git history, not filesystem mtime — hardcoded text here so it survives any re-clone/re-copy of the skill dir, e.g. via the starter-repo). installed = when WE vendored it into this project (local event, separate from upstream-date). local-mods = edits we made to our copy that an update must PRESERVE. Rollback = re-install the previous pinned-ref.

| skill | source | pinned-ref | upstream-date | installed | local-mods |
|---|---|---|---|---|---|
(empty — populated by `add` when a third-party skill is first vendored)
