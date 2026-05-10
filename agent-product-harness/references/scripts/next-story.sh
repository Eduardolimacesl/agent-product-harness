#!/usr/bin/env bash
# next-story.sh [<sprint-N>] — próxima story pronta para começar.
#
# "Pronta" = status:todo + todas as deps em depends_on têm status:done.
# Sort por priority (P0 > P1 > P2), depois por size (XS > S > M > L).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

ROOT="$(repo_root)" || exit 1
cd "$ROOT"

SPRINT="${1:-}"

# Mapa id → status
declare -A STATUS
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  id=$(frontmatter_get "$f" id)
  s=$(frontmatter_get "$f" status)
  [[ -n "$id" ]] && STATUS["$id"]="$s"
done < <(story_files)

CANDIDATES=()
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  s=$(frontmatter_get "$f" status)
  [[ "$s" != "todo" ]] && continue

  # extrai depends_on como lista
  deps=$(awk '/^depends_on:/{flag=1;next}/^[a-z_]+:/{flag=0}flag' "$f" \
         | grep -oE '"[^"]+"|[a-z0-9-]+' | tr -d '"' || true)
  inline_deps=$(frontmatter_get "$f" depends_on)
  if [[ "$inline_deps" =~ \[(.*)\] ]]; then
    inline="${BASH_REMATCH[1]}"
    inline=${inline//,/ }
    inline=${inline//\"/}
    deps="$deps $inline"
  fi

  blocked=0
  for d in $deps; do
    [[ "$d" == "[]" || -z "$d" ]] && continue
    if [[ "${STATUS[$d]:-}" != "done" ]]; then
      blocked=1
      break
    fi
  done
  [[ $blocked -eq 1 ]] && continue

  prio=$(frontmatter_get "$f" priority)
  size=$(frontmatter_get "$f" size)
  id=$(frontmatter_get "$f" id)
  name=$(frontmatter_get "$f" name)
  CANDIDATES+=("${prio:-P9}|${size:-Z}|$id|$name|$f")
done < <(story_files "$SPRINT")

if [[ ${#CANDIDATES[@]} -eq 0 ]]; then
  warn "nenhuma story pronta (todos bloqueados, em andamento ou concluídos)"
  exit 0
fi

printf '%s\n' "${CANDIDATES[@]}" | sort | head -10 | while IFS='|' read -r p s id n f; do
  printf "%-3s %-7s %-22s  %s\n        %s\n" "$p" "$s" "$id" "$n" "$f"
done
