#!/usr/bin/env bash
# progress.sh <sprint-N> — recalcula 'progress:' no sprint-plan.md.
#
# Fórmula: done / total das stories em docs/sprints/<N>/.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"
# shellcheck source=_safety.sh
source "$SCRIPT_DIR/_safety.sh"

ROOT="$(repo_root)" || exit 1
cd "$ROOT"

SPRINT="${1:-}"
if [[ -z "$SPRINT" ]]; then
  fail "uso: progress.sh <sprint-N>   (ex.: progress.sh 01)"
  exit 1
fi

PLAN="docs/sprints/$SPRINT/sprint-plan.md"
if [[ ! -f "$PLAN" ]]; then
  fail "sprint-plan.md não encontrado em docs/sprints/$SPRINT/"
  exit 1
fi

TOTAL=0; DONE=0
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  TOTAL=$((TOTAL + 1))
  s=$(frontmatter_get "$f" status)
  [[ "$s" == "done" ]] && DONE=$((DONE + 1))
done < <(story_files "$SPRINT")

if [[ $TOTAL -eq 0 ]]; then
  warn "nenhuma story em docs/sprints/$SPRINT/"
  exit 0
fi

PCT=$(( DONE * 100 / TOTAL ))
frontmatter_set "$PLAN" progress "${PCT}%"
frontmatter_set "$PLAN" updated "$(now)"

ok "sprint $SPRINT: ${DONE}/${TOTAL} done = ${PCT}% (atualizado em $PLAN)"
