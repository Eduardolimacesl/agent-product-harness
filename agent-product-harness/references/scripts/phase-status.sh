#!/usr/bin/env bash
# phase-status.sh — mostra qual fase do harness está completa e qual é a próxima.
#
# Definição: uma fase está completa se docs/memory/<fase>/_summary.md
# existe e tem conteúdo.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

ROOT="$(repo_root)" || exit 1
cd "$ROOT"

PHASES=(discovery prd design spec sprints execution testing deploys)

echo "Fases do harness:"
echo

NEXT=""
for phase in "${PHASES[@]}"; do
  if phase_summary_exists "$phase"; then
    status=$(frontmatter_get "docs/memory/$phase/_summary.md" status_de_saida)
    case "$status" in
      aprovado)            sym="✅" ;;
      aprovado-com-ressalvas) sym="🟡" ;;
      retornou)            sym="❌" ;;
      *)                   sym="❓" ;;
    esac
    printf "  %s %-12s %s\n" "$sym" "$phase" "${status:-sem status_de_saida}"
  else
    if [[ -z "$NEXT" ]]; then
      printf "  ⏭  %-12s %s\n" "$phase" "(próxima — sem _summary.md)"
      NEXT="$phase"
    else
      printf "  ⬜ %-12s\n" "$phase"
    fi
  fi
done

echo
if [[ -n "$NEXT" ]]; then
  echo "Próxima fase a iniciar: $NEXT"
else
  echo "Todas as fases têm _summary.md."
fi

# Stories blocked on Spec Drift — listed separately because they need
# a human decision before they can move (see
# references/04-sprints/04-spec-drift-protocol.md).
DRIFT_FILES=()
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  s=$(frontmatter_get "$f" status)
  [[ "$s" == "blocked-spec-drift" ]] && DRIFT_FILES+=("$f")
done < <(story_files)

if [[ ${#DRIFT_FILES[@]} -gt 0 ]]; then
  echo
  echo "Stories bloqueadas em spec-drift (aguardam decisão humana):"
  for f in "${DRIFT_FILES[@]}"; do
    id=$(frontmatter_get "$f" id)
    echo "  ⚠  $id  ($f)"
  done
fi
