# Example scope: data-ingest

Build a data layer before (or alongside) the UI: parse reference material, shape a
schema, generate a database or fixtures. This kind of work has no single "route" —
it spans reference inputs, a data/output dir, and often a shared schema — which is
exactly why the old route-shaped menu had no slot for it. Declare the prefixes the
task actually writes.

- **scope:** `data/ refs/ src/shared/schema/` (adjust to where inputs and outputs live)
  ```
  H=$(pwd | sha256sum | cut -d' ' -f1 | cut -c1-8)
  printf '%s\n' data/ refs/ src/shared/schema/ > /tmp/claude-scope-$H
  ```
  Reference/source material you only READ (docs, sample files, exports) needs no scope
  entry — reads are never gated. List only the prefixes you WRITE.
- **read-set:** `.claude/memory/INDEX.md` + any existing schema/registry the data feeds,
  + the reference files themselves (read freely — that's the input).
- **skills:** opt-in — load `domain-modeling` if the parse forces naming/vocabulary
  decisions worth pinning in `.claude/memory/CONTEXT.md`; load parsing/research skills
  as the sources need.
- **guardrails:**
  - Pin the shape before mass-parsing — a schema decision made mid-ingest is expensive
    to reverse. Consider `grill-me` / `spec` on the schema first.
  - Keep raw inputs (`refs/`) separate from derived outputs (`data/`) so a re-parse is
    reproducible and never clobbers the source.
  - If the ingest also needs shared types the UI consumes, that's cross-scope but
    advisory — it proceeds; widen the scope line if you want the nudge to stop.
