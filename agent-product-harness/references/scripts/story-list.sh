#!/usr/bin/env bash
# story-list.sh [<sprint-N>] — lista stories com status, prioridade, owner.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

ROOT="$(repo_root)" || exit 1
cd "$ROOT"

SPRINT="${1:-}"
printf "%-3s %-22s %-9s %-3s %-7s %-12s %s\n" \
  "" "id" "type" "P" "size" "status" "name"
printf -- "-%.0s" {1..100}; echo

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  id=$(frontmatter_get "$f" id)
  type=$(frontmatter_get "$f" type)
  prio=$(frontmatter_get "$f" priority)
  size=$(frontmatter_get "$f" size)
  status=$(frontmatter_get "$f" status)
  name=$(frontmatter_get "$f" name)
  case "$status" in
    todo)   sym="⬜" ;;
    doing)  sym="🟨" ;;
    review) sym="🟦" ;;
    done)   sym="✅" ;;
    *)      sym="❓" ;;
  esac
  printf "%-3s %-22s %-9s %-3s %-7s %-12s %s\n" \
    "$sym" "$id" "$type" "$prio" "$size" "$status" "$name"
done < <(story_files "$SPRINT")
