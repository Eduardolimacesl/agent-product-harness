#!/usr/bin/env bash
# help.sh — lista scripts disponíveis no harness

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cat <<'EOF'
agent-product-harness — scripts disponíveis

Leitura (não escreve nada):
  validate.sh                  Checa convenções e gates do harness.
  phase-status.sh              Qual fase concluída, qual a próxima.
  sprint-status.sh [<N>]       Resumo da sprint (default: maior número).
  story-list.sh    [<N>]       Lista stories com status.
  next-story.sh    [<N>]       Próxima story pronta para começar.

Escrita (passa por _safety.sh):
  progress.sh      <N>         Recalcula progress: no sprint-plan.md.

Helpers (sourced, não rodar direto):
  _lib.sh                      Funções comuns (now, repo_root, frontmatter).
  _safety.sh                   Bloqueia escrita no repo da skill.

Uso típico (de dentro do projeto, onde docs/ vive):
  bash <skill>/references/scripts/validate.sh
  bash <skill>/references/scripts/sprint-status.sh 01

Dica: alias
  alias aph='bash <skill>/references/scripts'
  aph/validate.sh
EOF

ls -1 "$SCRIPT_DIR"/*.sh 2>/dev/null | xargs -n1 basename | sort
