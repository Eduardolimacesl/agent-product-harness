#!/usr/bin/env bash
# _safety.sh — repository safety check.
# Bloqueia escrita acidental no próprio repo da skill.
# Sourced por scripts que escrevem.

set -euo pipefail

_aph_remote_url="$(git remote get-url origin 2>/dev/null || echo "")"

if [[ "$_aph_remote_url" == *"agent-product-harness"* ]] && \
   [[ "$_aph_remote_url" == *"eduardolimacesl"* ]]; then
  echo "" >&2
  echo "ERRO: este diretório aponta para o repo da skill agent-product-harness." >&2
  echo "      remote: $_aph_remote_url" >&2
  echo "" >&2
  echo "Você provavelmente clonou a skill como template. Troque o remote:" >&2
  echo "  git remote set-url origin <seu-repo-de-produto>" >&2
  echo "" >&2
  exit 2
fi

unset _aph_remote_url
