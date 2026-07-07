#!/usr/bin/env bash
# structcheck.sh <file> <expected-marker>... — mechanical core of update reconciliation.
# Reports which expected structural markers (headings / field names the updated skill
# requires) are present or MISSING in a project dependency file. Exit 1 if any missing,
# 2 on usage/IO error. The migration itself is model-driven; this only DETECTS drift.
set -u
f="${1:-}"; shift || true
[ -n "$f" ] && [ -f "$f" ] || { echo "structcheck: no such file: ${f:-<none>}" >&2; exit 2; }
[ "$#" -ge 1 ] || { echo "structcheck: need at least one expected marker" >&2; exit 2; }
miss=0
for m in "$@"; do
  if grep -qiF -- "$m" "$f"; then printf '  ok    %s\n' "$m"
  else printf '  MISS  %s\n' "$m"; miss=1; fi
done
[ "$miss" -eq 0 ] && echo "structcheck: aligned" || echo "structcheck: $f is MISSING markers above — reconcile before the updated skill runs against it"
exit "$miss"
