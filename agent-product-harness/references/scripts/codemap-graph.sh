#!/usr/bin/env bash
# codemap-graph.sh — regenerate docs/memory/codemap/graph.json from
# the module-level entries in docs/memory/codemap/modules/*.md.
#
# Reads each module .md, extracts:
#   - module name (frontmatter "module:" or filename slug)
#   - status (frontmatter)
#   - dependency lines under the "### Imports (afferent — ...)" heading,
#     of the form "- `<path>` — usa: <symbols>"
#
# Emits a JSON document with nodes (one per module file) and edges (one
# per intra-codemap dependency line — external "npm:..." deps become a
# node only when both ends are mapped modules).
#
# Usage:
#   codemap-graph.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

ROOT="$(repo_root)" || exit 1
cd "$ROOT"

CODEMAP_DIR="docs/memory/codemap"
MODULES_DIR="$CODEMAP_DIR/modules"
OUT="$CODEMAP_DIR/graph.json"

if [[ ! -d "$MODULES_DIR" ]]; then
  fail "$MODULES_DIR não existe — rode codemap-update.sh primeiro"
  exit 1
fi

NOW=$(now)

# Collect modules: filename slug + status from frontmatter.
declare -a NODES
declare -A SLUGS

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  slug=$(basename "$f" .md)
  [[ "$slug" == "_archive" ]] && continue
  status=$(frontmatter_get "$f" status)
  [[ -z "$status" ]] && status="active"
  NODES+=("$slug|$status|$f")
  SLUGS["$slug"]=1
done < <(find "$MODULES_DIR" -maxdepth 1 -name '*.md' 2>/dev/null | sort)

# Build edges by parsing the "### Imports" section in each module file.
declare -a EDGES
for entry in "${NODES[@]}"; do
  IFS='|' read -r from status file <<<"$entry"
  in_imports=0
  while IFS= read -r line; do
    if [[ "$line" =~ ^###[[:space:]]+Imports ]]; then
      in_imports=1
      continue
    fi
    if [[ $in_imports -eq 1 && "$line" =~ ^###[[:space:]] ]]; then
      in_imports=0
    fi
    if [[ $in_imports -eq 1 && "$line" =~ ^-[[:space:]]+\`([^\`]+)\`[[:space:]]+—[[:space:]]+usa:[[:space:]]+(.*)$ ]]; then
      dep_path="${BASH_REMATCH[1]}"
      symbols="${BASH_REMATCH[2]}"
      # Skip external (npm:) edges — keep only intra-repo where both ends
      # have a codemap entry.
      [[ "$dep_path" == npm:* ]] && continue
      dep_slug=$(echo "$dep_path" \
        | sed -E 's@^src/@@; s@^app/@@; s@^lib/@@' \
        | sed -E 's@\.(ts|tsx|js|jsx)$@@' \
        | tr '/' '-' | tr -d '()')
      if [[ -n "${SLUGS[$dep_slug]:-}" ]]; then
        EDGES+=("$from|$dep_slug|imports|$symbols")
      fi
    fi
  done < "$file"
done

# Emit JSON. Quote a string safely for JSON.
jsonq() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '"%s"' "$s"
}

{
  echo "{"
  printf '  "$schema": "https://agent-product-harness.dev/schemas/codemap-graph.json",\n'
  printf '  "generated_at": %s,\n' "$(jsonq "$NOW")"
  printf '  "nodes": ['
  first=1
  for entry in "${NODES[@]}"; do
    IFS='|' read -r slug status file <<<"$entry"
    [[ $first -eq 0 ]] && printf ','
    first=0
    printf '\n    { "module": %s, "status": %s }' \
      "$(jsonq "$slug")" "$(jsonq "$status")"
  done
  if [[ ${#NODES[@]} -gt 0 ]]; then printf '\n  '; fi
  echo "],"
  printf '  "edges": ['
  first=1
  for edge in "${EDGES[@]}"; do
    IFS='|' read -r from to kind syms <<<"$edge"
    [[ $first -eq 0 ]] && printf ','
    first=0
    printf '\n    { "from": %s, "to": %s, "kind": %s, "symbols": %s }' \
      "$(jsonq "$from")" "$(jsonq "$to")" "$(jsonq "$kind")" "$(jsonq "$syms")"
  done
  if [[ ${#EDGES[@]} -gt 0 ]]; then printf '\n  '; fi
  echo "]"
  echo "}"
} > "$OUT"

ok "graph.json regenerado: $OUT (${#NODES[@]} nodes, ${#EDGES[@]} edges)"
