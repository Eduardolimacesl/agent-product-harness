#!/usr/bin/env bash
# check-spec-drift.sh — detecta desalinhamento entre Tech Spec / Domain Model
# e o código de contratos (Server Actions, Domain Events, Webhooks).
#
# Exit codes:
#   0 = nenhum drift
#   1 = drift detectado
#   2 = pré-condição faltando (sem docs/spec/00-tech-spec.md, etc.)
#
# O que checa (best-effort, baseado em grep / convenção de pastas):
#  A. Server Actions: cada action listada em §6.2 da Tech Spec existe como
#     `export async function <nome>` em app/.../actions.ts (Variante A) ou
#     src/interface/web/app/.../actions.ts (Variante B). E vice-versa.
#  B. Domain Events: cada evento listado em 02-domain-model.md §3.1.4
#     tem arquivo correspondente em src/domain/<contexto>/events/ ou
#     src/contracts/events/.
#  C. Webhooks: cada webhook listado em §6.3 tem route handler em
#     app/api/webhooks/<x>/route.ts.
#
# Limitações honestas:
#  - Parser é grep + awk; convenções de naming precisam ser respeitadas.
#  - Detecta drift estrutural (existe/não existe), não semântico (campo X
#    mudou de tipo). Para isso, use testes de contrato.
#  - Lê ADR-0001 para decidir entre Variante A e B; default é A.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

# _lib.sh ativa `set -euo pipefail`. Para este script, grep/find sem matches
# é caso esperado (não há drift) — não queremos que isso aborte. Desligo só
# o errexit; mantenho nounset e pipefail.
set +e

ROOT="$(repo_root)" || exit 2
cd "$ROOT" || exit 2

# Pré-condição: Tech Spec existe
SPEC="docs/spec/00-tech-spec.md"
if [[ ! -f "$SPEC" ]]; then
  fail "$SPEC ausente — sem spec, nada a checar"
  exit 2
fi

# Detectar variante de layout via ADR-0001
LAYOUT="A"  # default
ADR="docs/spec/adr/0001-architecture-layout.md"
if [[ -f "$ADR" ]]; then
  # Procura "Variante B" em linha começando com "Decidimos" ou "Status"
  if grep -qiE '^\*\*Decidimos.*Variante.*\bB\b|Variante\s+B.*(escolhida|accepted)' "$ADR"; then
    LAYOUT="B"
  fi
fi
info "Layout detectado via ADR-0001: Variante $LAYOUT"

# Pastas-alvo conforme variante
if [[ "$LAYOUT" == "B" ]]; then
  ACTIONS_GLOB="src/interface/web/app"
  EVENTS_GLOBS=("src/domain" "src/contracts/events")
  WEBHOOKS_GLOB="src/interface/web/app/api/webhooks"
else
  ACTIONS_GLOB="app"
  EVENTS_GLOBS=("src/domain/events" "lib/contracts/events")
  WEBHOOKS_GLOB="app/api/webhooks"
fi

DRIFTS=0
report_drift() { fail "$@"; DRIFTS=$((DRIFTS + 1)); }

# Helper: extrai entradas de uma tabela markdown a partir do cabeçalho
# Uso: extract_table_first_col <file> <header-marker>
# Retorna primeira coluna de cada linha de dados (sem ` `).
extract_table_first_col() {
  local file="$1"
  local marker="$2"
  awk -v m="$marker" '
    $0 ~ m { in_sec = 1; next }
    in_sec && /^\| *[A-Za-z`\/_-]/ && !/^\|[-: ]+\|/ && !/^\| *Rota *\|/ && !/^\| *Endpoint *\|/ && !/^\| *Evento *\|/ {
      # primeira célula entre pipes
      gsub(/^\| */, ""); sub(/ *\|.*/, "")
      gsub(/`/, "")
      print
    }
    in_sec && /^---$/ { in_sec = 0 }
    in_sec && /^## / { in_sec = 0 }
  ' "$file"
}

# A. Server Actions
info "Checando Server Actions (§6.2 do Tech Spec)..."
SPEC_ACTIONS=$(awk '/^### 6\.2 Server Actions/{flag=1;next} /^### 6\.[3-9]/{flag=0} flag' "$SPEC" \
  | grep -oE 'export async function [a-zA-Z_][a-zA-Z0-9_]*' \
  | awk '{print $4}' | sort -u)

if [[ -z "$SPEC_ACTIONS" ]]; then
  warn "Nenhuma Server Action documentada em §6.2 — pulando."
else
  CODE_ACTIONS=$(find "$ACTIONS_GLOB" -type f -name 'actions.ts' 2>/dev/null \
    | xargs grep -hE "^export async function [a-zA-Z_][a-zA-Z0-9_]*" 2>/dev/null \
    | awk '{print $4}' | awk -F'(' '{print $1}' | sort -u)

  # Specced sem code
  while IFS= read -r act; do
    [[ -z "$act" ]] && continue
    if ! grep -qFx "$act" <<<"$CODE_ACTIONS"; then
      report_drift "Server Action documentada mas ausente no código: $act"
    fi
  done <<<"$SPEC_ACTIONS"

  # Code sem spec
  while IFS= read -r act; do
    [[ -z "$act" ]] && continue
    if ! grep -qFx "$act" <<<"$SPEC_ACTIONS"; then
      report_drift "Server Action no código mas ausente da Tech Spec §6.2: $act"
    fi
  done <<<"$CODE_ACTIONS"
fi

# B. Domain Events
DOMAIN_DOC="docs/spec/02-domain-model.md"
if [[ -f "$DOMAIN_DOC" ]]; then
  info "Checando Domain Events (§3.1.4 do Domain Model)..."
  # Eventos: primeira coluna de tabelas após "#### 3.1.4 Domain Events"
  SPEC_EVENTS=$(awk '
    /^#### 3\.[0-9]+\.4 Domain Events/{flag=1;next}
    /^#### 3\./{flag=0}
    flag && /^\| *`[A-Z][A-Za-z0-9]+`/ {
      gsub(/^\| *`/, ""); sub(/` *\|.*/, "")
      print
    }
  ' "$DOMAIN_DOC" | sort -u)

  if [[ -n "$SPEC_EVENTS" ]]; then
    # Coletar arquivos de eventos em qualquer pasta candidata
    CODE_EVENTS=""
    for glob in "${EVENTS_GLOBS[@]}"; do
      [[ ! -d "$glob" ]] && continue
      while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        base=$(basename "$f" .ts)
        # converte kebab-case → PascalCase para comparar com nome de classe
        pascal=$(echo "$base" | awk -F'-' '{
          for (i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2);
          OFS=""; $1=$1; print
        }')
        CODE_EVENTS+="$pascal"$'\n'
      done < <(find "$glob" -type f -name '*.ts' \
               ! -name '*.test.ts' ! -name '*.spec.ts' \
               -path '*event*' 2>/dev/null)
    done
    CODE_EVENTS=$(echo "$CODE_EVENTS" | sort -u | grep -v '^$' || true)

    while IFS= read -r ev; do
      [[ -z "$ev" ]] && continue
      if ! grep -qFx "$ev" <<<"$CODE_EVENTS"; then
        report_drift "Domain Event documentado mas sem arquivo correspondente: $ev"
      fi
    done <<<"$SPEC_EVENTS"

    while IFS= read -r ev; do
      [[ -z "$ev" ]] && continue
      if ! grep -qFx "$ev" <<<"$SPEC_EVENTS"; then
        report_drift "Arquivo de evento no código mas ausente do Domain Model §3.1.4: $ev"
      fi
    done <<<"$CODE_EVENTS"
  fi
else
  info "Sem 02-domain-model.md — pulando checagem de Domain Events."
fi

# C. Webhooks
info "Checando Webhooks (§6.3 do Tech Spec)..."
SPEC_WEBHOOKS=$(awk '/^### 6\.3 Webhooks/{flag=1;next} /^### 6\.[4-9]/{flag=0} /^---$/{flag=0} flag' "$SPEC" \
  | grep -oE '`/api/webhooks/[a-zA-Z0-9_-]+`' \
  | tr -d '`' | sort -u)

if [[ -n "$SPEC_WEBHOOKS" ]]; then
  CODE_WEBHOOKS=$(find "$WEBHOOKS_GLOB" -type d -mindepth 1 -maxdepth 1 2>/dev/null \
    | sed "s|^${WEBHOOKS_GLOB}|/api/webhooks|" | sort -u)

  while IFS= read -r wh; do
    [[ -z "$wh" ]] && continue
    if ! grep -qFx "$wh" <<<"$CODE_WEBHOOKS"; then
      report_drift "Webhook documentado mas sem route handler: $wh"
    fi
  done <<<"$SPEC_WEBHOOKS"

  while IFS= read -r wh; do
    [[ -z "$wh" ]] && continue
    if ! grep -qFx "$wh" <<<"$SPEC_WEBHOOKS"; then
      report_drift "Route handler de webhook sem entrada na Tech Spec §6.3: $wh"
    fi
  done <<<"$CODE_WEBHOOKS"
fi

echo
if [[ $DRIFTS -eq 0 ]]; then
  ok "check-spec-drift: tudo alinhado"
  exit 0
else
  fail "check-spec-drift: $DRIFTS drift(s) detectado(s)"
  exit 1
fi
