#!/usr/bin/env bash
# sprint-status.sh [<sprint-N>] — resumo de stories da sprint.
# Default: maior número de sprint encontrado.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

ROOT="$(repo_root)" || exit 1
cd "$ROOT"

SPRINT="${1:-}"
if [[ -z "$SPRINT" ]]; then
  SPRINT=$(find docs/sprints -mindepth 1 -maxdepth 1 -type d 2>/dev/null \
           | xargs -n1 basename | sort -n | tail -1)
fi

if [[ -z "$SPRINT" || ! -d "docs/sprints/$SPRINT" ]]; then
  fail "sprint $SPRINT não encontrada"
  exit 1
fi

echo "Sprint $SPRINT — $(date)"
echo

if [[ -f "docs/sprints/$SPRINT/sprint-plan.md" ]]; then
  goal=$(frontmatter_get "docs/sprints/$SPRINT/sprint-plan.md" goal)
  status=$(frontmatter_get "docs/sprints/$SPRINT/sprint-plan.md" status)
  progress=$(frontmatter_get "docs/sprints/$SPRINT/sprint-plan.md" progress)
  echo "  Goal:     ${goal:-(não definido)}"
  echo "  Status:   ${status:-?}"
  echo "  Progress: ${progress:-?}"
  echo
fi

T_TODO=0; T_DOING=0; T_REVIEW=0; T_DONE=0; TOTAL=0
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  TOTAL=$((TOTAL + 1))
  s=$(frontmatter_get "$f" status)
  case "$s" in
    todo)   T_TODO=$((T_TODO+1)) ;;
    doing)  T_DOING=$((T_DOING+1)) ;;
    review) T_REVIEW=$((T_REVIEW+1)) ;;
    done)   T_DONE=$((T_DONE+1)) ;;
  esac
done < <(story_files "$SPRINT")

printf "  ⬜ todo:   %d\n" "$T_TODO"
printf "  🟨 doing:  %d\n" "$T_DOING"
printf "  🟦 review: %d\n" "$T_REVIEW"
printf "  ✅ done:   %d\n" "$T_DONE"
printf "  ── total: %d\n" "$TOTAL"

if [[ $TOTAL -gt 0 ]]; then
  pct=$(( T_DONE * 100 / TOTAL ))
  echo
  echo "  Computed progress: ${pct}%"
fi
