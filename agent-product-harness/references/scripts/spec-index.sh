#!/usr/bin/env bash
# spec-index.sh [<file>] — generates a JSON index of headings in a spec doc.
#
# Writes <file>'s sibling .index.json (e.g. docs/spec/00-tech-spec.md →
# docs/spec/.index.json) with one entry per heading:
#
#   [
#     { "heading": "0. Implementation Blueprint", "level": 2,
#       "start_line": 14, "end_line": 75 },
#     ...
#   ]
#
# Used by spec-fetch.sh consumers and by validate.sh for heading uniqueness.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

FILE="${1:-}"
if [[ -z "$FILE" ]]; then
  ROOT="$(repo_root)" || exit 1
  FILE="$ROOT/docs/spec/00-tech-spec.md"
fi

if [[ ! -r "$FILE" ]]; then
  fail "arquivo não legível: $FILE"
  exit 1
fi

DIR="$(dirname "$FILE")"
BASE="$(basename "$FILE" .md)"
OUT="$DIR/.${BASE}.index.json"

# Build entries: first emit a list of (lineno, level, text). Then resolve
# end_line as the line before the next heading of level ≤ current, or EOF.
awk '
  function emit_json(arr_n,  i) {
    printf "["
    for (i = 1; i <= arr_n; i++) {
      if (i > 1) printf ","
      printf "\n  { \"heading\": \"%s\", \"level\": %d, \"start_line\": %d, \"end_line\": %d }",
        text[i], level[i], start[i], end[i]
    }
    if (arr_n > 0) printf "\n"
    print "]"
  }
  function json_escape(s) {
    gsub(/\\/, "\\\\", s)
    gsub(/"/,  "\\\"", s)
    gsub(/\t/, "\\t", s)
    gsub(/\r/, "",   s)
    return s
  }

  /^#{1,6}[[:space:]]/ {
    n++
    start[n] = NR
    match($0, /^#+/)
    level[n] = RLENGTH
    t = $0
    sub(/^#+[[:space:]]+/, "", t)
    sub(/[[:space:]]+$/,   "", t)
    text[n] = json_escape(t)
  }
  END {
    total_lines = NR
    for (i = 1; i <= n; i++) {
      end[i] = total_lines
      for (j = i + 1; j <= n; j++) {
        if (level[j] <= level[i]) { end[i] = start[j] - 1; break }
      }
    }
    emit_json(n)
  }
' "$FILE" > "$OUT"

ok "índice gerado: $OUT"
