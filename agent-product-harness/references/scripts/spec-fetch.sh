#!/usr/bin/env bash
# spec-fetch.sh "<heading>" [<file>] — emits the named section of a spec doc.
#
# Use it during bootstrap mínimo to load ONLY the section needed for a story,
# instead of pulling the entire Tech Spec into context. Implements
# Hierarchical Content Segmentation (Li et al. 2025, DeepCode §2.1).
#
# Default file: docs/spec/00-tech-spec.md (resolved from repo_root).
#
# Heading match rules (in order):
#   1. exact match on the heading text (after stripping leading # and spaces);
#   2. case-insensitive substring match.
#
# The section runs from the matched heading (inclusive) to the next heading
# of equal or higher level (exclusive). Subsections under the matched heading
# are included.
#
# Exit codes:
#   0  match found, section emitted on stdout
#   1  no match
#   2  multiple matches (ambiguous — refine the query, or fix the spec so
#      headings are unique; see validate.sh check on heading uniqueness)
#   3  file missing / unreadable

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  echo "usage: spec-fetch.sh \"<heading>\" [<file>]" >&2
  exit 3
fi

QUERY="$1"
FILE="${2:-}"

if [[ -z "$FILE" ]]; then
  ROOT="$(repo_root)" || exit 3
  FILE="$ROOT/docs/spec/00-tech-spec.md"
fi

if [[ ! -r "$FILE" ]]; then
  echo "ERRO: arquivo não legível: $FILE" >&2
  exit 3
fi

# Find candidate heading lines. Pass query through awk via -v to avoid
# shell-quoting pitfalls.
MATCHES=$(awk -v q="$QUERY" '
  function lower(s) { return tolower(s) }
  BEGIN {
    ql = lower(q)
  }
  /^#{1,6}[[:space:]]/ {
    line = $0
    text = $0
    sub(/^#+[[:space:]]+/, "", text)
    sub(/[[:space:]]+$/, "", text)
    # exact match first
    if (text == q)      { print NR "\t" text "\texact"; next }
    if (lower(text) == ql) { print NR "\t" text "\texact-ci"; next }
    if (index(lower(text), ql) > 0) { print NR "\t" text "\tsubstr" }
  }
' "$FILE")

if [[ -z "$MATCHES" ]]; then
  echo "ERRO: nenhum heading casa com '$QUERY' em $FILE" >&2
  exit 1
fi

# Prefer exact matches if any; otherwise treat all as candidates.
EXACT=$(echo "$MATCHES" | awk -F'\t' '$3 ~ /^exact/ { print }')
if [[ -n "$EXACT" ]]; then
  MATCHES="$EXACT"
fi

N=$(echo "$MATCHES" | wc -l | tr -d ' ')
if [[ "$N" -gt 1 ]]; then
  echo "ERRO: '$QUERY' casa com $N headings em $FILE:" >&2
  echo "$MATCHES" | awk -F'\t' '{ printf "  L%-5d  %s\n", $1, $2 }' >&2
  echo "Refine a query ou padronize headings (validate.sh checa unicidade)." >&2
  exit 2
fi

START_LINE=$(echo "$MATCHES" | awk -F'\t' '{ print $1; exit }')

# Determine the level (# count) of the matched heading and find the next
# heading with level ≤ that level (end of our section).
END_LINE=$(awk -v start="$START_LINE" '
  NR == start {
    match($0, /^#+/)
    lvl = RLENGTH
    next
  }
  NR > start && /^#{1,6}[[:space:]]/ {
    match($0, /^#+/)
    if (RLENGTH <= lvl) { print NR - 1; found = 1; exit }
  }
  END {
    if (!found) print NR
  }
' "$FILE")

# Emit the slice.
sed -n "${START_LINE},${END_LINE}p" "$FILE"
