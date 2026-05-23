#!/usr/bin/env bash
# check-clarifications.sh — detecta marcadores [NEEDS CLARIFICATION] abertos.
#
# Gate anti-ambiguidade do Clarify Protocol
# (references/03-spec/07-clarify-protocol.md). Marcadores são legítimos
# durante o draft; este gate exige ZERO no momento da transição de fase.
#
# Uso:
#   check-clarifications.sh                 # checa docs/prd e docs/spec
#   check-clarifications.sh docs/prd        # escopo a um diretório
#   check-clarifications.sh docs/spec docs/sprints
#
# Exit codes:
#   0 = nenhum marcador aberto
#   1 = marcador(es) encontrado(s) (lista file:line)
#   2 = pré-condição faltando (diretório-alvo inexistente)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

# _lib.sh ativa errexit; grep sem match é caso esperado (sem marcador) —
# não queremos abortar. Desligo só o errexit.
set +e

ROOT="$(repo_root)" || exit 2
cd "$ROOT" || exit 2

# Alvos: args ou default (prd + spec).
if [[ $# -gt 0 ]]; then
  TARGETS=("$@")
else
  TARGETS=("docs/prd" "docs/spec")
fi

# Marcador canônico do Clarify Protocol. O 🟡 legado é alias visual e deve
# ser promovido ao marcador explícito — avisamos se aparecer sozinho.
MARKER='\[NEEDS CLARIFICATION'

FOUND=0
CHECKED=0

for target in "${TARGETS[@]}"; do
  if [[ ! -e "$target" ]]; then
    warn "alvo inexistente, pulando: $target"
    continue
  fi
  CHECKED=$((CHECKED + 1))

  # Marcadores explícitos — bloqueiam.
  HITS=$(grep -rEn "$MARKER" "$target" --include='*.md' 2>/dev/null)
  if [[ -n "$HITS" ]]; then
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      fail "marcador aberto: $line"
      FOUND=$((FOUND + 1))
    done <<<"$HITS"
  fi

  # 🟡 legado sem marcador explícito na mesma linha — só avisa.
  LEGACY=$(grep -rEn '🟡' "$target" --include='*.md' 2>/dev/null \
    | grep -vE "$MARKER")
  if [[ -n "$LEGACY" ]]; then
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      warn "🟡 legado (promova a [NEEDS CLARIFICATION: <pergunta>]): $line"
    done <<<"$LEGACY"
  fi
done

if [[ $CHECKED -eq 0 ]]; then
  fail "nenhum diretório-alvo existe — nada a checar"
  exit 2
fi

echo
if [[ $FOUND -eq 0 ]]; then
  ok "check-clarifications: nenhum marcador aberto em ${TARGETS[*]}"
  exit 0
else
  fail "check-clarifications: $FOUND marcador(es) aberto(s) — resolva antes de avançar a fase"
  exit 1
fi
