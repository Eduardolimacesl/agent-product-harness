#!/usr/bin/env bash
# check-cross-artifact.sh — coerência ENTRE artefatos antes da Execução.
#
# Implementa o Cross-Artifact Analysis
# (references/04-sprints/06-cross-artifact-analysis.md). Distinto de
# validate.sh (convenção mecânica) e de check-spec-drift.sh (spec vs código):
# aqui checamos as RELAÇÕES entre Constitution, PRD, Tech Spec e Sprint/Stories.
#
# Severidade:
#   CRITICAL → bloqueia a entrada na Execução (conta para exit 1)
#   WARN     → aviso a sanar; não bloqueia
#
# Checagens:
#   A (CRITICAL) todo adr_refs de story resolve para docs/spec/adr/<id>-*.md
#   B (CRITICAL) toda user story P0 do PRD é coberta por ≥1 story de sprint
#                (declarada fora de escopo no sprint-plan rebaixa a WARN)
#   C (CRITICAL) zero [NEEDS CLARIFICATION] em prd/ + spec/ + sprints/
#   D (WARN)     docs/memory/constitution.md existe e está ratified
#   E (WARN)     toda story referencia PRD/Spec (campo não-placeholder)
#   F (WARN)     toda Server Action / webhook da Tech Spec é citada por ≥1 story
#
# Limitações honestas: parser é grep/awk; casa por convenção de naming
# (US-NN no PRD ↔ us-NN nas stories). Detecta ausência estrutural, não
# divergência semântica. Para semântica, use revisão humana no Gate 1.
#
# Exit codes:
#   0 = nenhum CRITICAL (WARNs podem existir)
#   1 = ≥1 CRITICAL
#   2 = pré-condição faltando

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

# grep/find sem match é caso esperado — não abortar.
set +e

ROOT="$(repo_root)" || exit 2
cd "$ROOT" || exit 2

if [[ ! -d docs/sprints ]]; then
  fail "docs/sprints/ ausente — rode após o Sprint Planning"
  exit 2
fi

CRIT=0
WARNS=0
crit()  { fail "[CRITICAL] $*"; CRIT=$((CRIT + 1)); }
advise(){ warn "[WARN] $*"; WARNS=$((WARNS + 1)); }

SPEC="docs/spec/00-tech-spec.md"

# ---------------------------------------------------------------------------
# A. adr_refs de cada story resolve para um arquivo de ADR.
# ---------------------------------------------------------------------------
info "A. adr_refs ↔ docs/spec/adr/ ..."
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  refs=$(awk '/^adr_refs:/{print}' "$f" | grep -oE '"[0-9]{4}"|[0-9]{4}' | tr -d '"' | sort -u)
  for id in $refs; do
    [[ -z "$id" ]] && continue
    if ! ls "docs/spec/adr/${id}-"*.md >/dev/null 2>&1; then
      crit "$f: adr_refs '$id' sem arquivo docs/spec/adr/${id}-*.md"
    fi
  done
done < <(story_files)

# ---------------------------------------------------------------------------
# B. Cobertura: toda US-NN P0 do PRD tem story (ou está declarada fora de escopo).
# ---------------------------------------------------------------------------
info "B. PRD P0 ↔ stories de sprint ..."
PRD_P0=$(grep -rhE '^\| *US-[0-9]+ ' docs/prd 2>/dev/null \
  | grep -E '\bP0\b' \
  | grep -oE 'US-[0-9]+' | sort -u)

if [[ -z "$PRD_P0" ]]; then
  advise "nenhuma user story P0 encontrada em docs/prd/ (§5) — cobertura não checada"
else
  STORY_LIST=$(story_files)
  PLAN_LIST=$(find docs/sprints -name 'sprint-plan.md' 2>/dev/null)
  while IFS= read -r usid; do
    [[ -z "$usid" ]] && continue
    low=$(echo "$usid" | tr 'A-Z' 'a-z')   # US-01 → us-01
    in_story=0; in_plan=0
    if [[ -n "$STORY_LIST" ]]; then
      echo "$STORY_LIST" | xargs grep -liE "\b${low}\b" 2>/dev/null | grep -q . && in_story=1
    fi
    if [[ -n "$PLAN_LIST" ]]; then
      echo "$PLAN_LIST" | xargs grep -liE "\b${usid}\b" 2>/dev/null | grep -q . && in_plan=1
    fi
    if [[ $in_story -eq 1 ]]; then
      :  # coberta
    elif [[ $in_plan -eq 1 ]]; then
      advise "$usid (P0) sem story, mas citada no sprint-plan — confirme que é fora-de-escopo intencional (§4)"
    else
      crit "$usid (P0) do PRD não tem story nem aparece em nenhum sprint-plan (requisito órfão)"
    fi
  done <<<"$PRD_P0"
fi

# ---------------------------------------------------------------------------
# C. Zero marcadores [NEEDS CLARIFICATION] em prd/spec/sprints.
# ---------------------------------------------------------------------------
info "C. marcadores [NEEDS CLARIFICATION] ..."
MARKERS=$(grep -rEn '\[NEEDS CLARIFICATION' docs/prd docs/spec docs/sprints --include='*.md' 2>/dev/null)
if [[ -n "$MARKERS" ]]; then
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    crit "marcador aberto: $line"
  done <<<"$MARKERS"
fi

# ---------------------------------------------------------------------------
# D. Constitution existe e está ratificada.
# ---------------------------------------------------------------------------
info "D. constitution ..."
CONST="docs/memory/constitution.md"
if [[ ! -f "$CONST" ]]; then
  advise "$CONST ausente — produto sem lei de qualidade ratificada"
else
  st=$(frontmatter_get "$CONST" status)
  if [[ "$st" != "ratified" ]]; then
    advise "$CONST com status '$st' (esperado: ratified) antes da Execução"
  fi
fi

# ---------------------------------------------------------------------------
# E. Toda story referencia PRD/Spec (campo não-placeholder).
# ---------------------------------------------------------------------------
info "E. stories ↔ PRD/Spec ..."
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  # Linhas "PRD:" / "Spec:" com conteúdo real (sem <placeholder> e não vazias).
  ref=$(grep -hE '^(PRD|Spec):' "$f" 2>/dev/null \
    | sed -E 's/^(PRD|Spec): *//' \
    | grep -vE '^<.*>$' | grep -vE '^\s*$')
  if [[ -z "$ref" ]]; then
    advise "$(basename "$f"): sem referência preenchida a PRD/Spec (## Contexto)"
  fi
done < <(story_files)

# ---------------------------------------------------------------------------
# F. Server Actions / webhooks da Tech Spec citados por ≥1 story.
# ---------------------------------------------------------------------------
if [[ -f "$SPEC" ]]; then
  info "F. contratos da Tech Spec ↔ stories ..."
  STORY_LIST=$(story_files)
  SPEC_ACTIONS=$(awk '/^### 6\.2 Server Actions/{flag=1;next} /^### 6\.[3-9]/{flag=0} flag' "$SPEC" \
    | grep -oE 'export async function [a-zA-Z_][a-zA-Z0-9_]*' \
    | awk '{print $4}' | sort -u)
  for act in $SPEC_ACTIONS; do
    [[ -z "$act" ]] && continue
    if [[ -n "$STORY_LIST" ]]; then
      if ! echo "$STORY_LIST" | xargs grep -lF "$act" 2>/dev/null | grep -q .; then
        advise "Server Action '$act' (Tech Spec §6.2) não citada por nenhuma story"
      fi
    fi
  done
  SPEC_WEBHOOKS=$(awk '/^### 6\.3 Webhooks/{flag=1;next} /^### 6\.[4-9]/{flag=0} /^---$/{flag=0} flag' "$SPEC" \
    | grep -oE '/api/webhooks/[a-zA-Z0-9_-]+' | sort -u)
  for wh in $SPEC_WEBHOOKS; do
    [[ -z "$wh" ]] && continue
    if [[ -n "$STORY_LIST" ]]; then
      if ! echo "$STORY_LIST" | xargs grep -lF "$wh" 2>/dev/null | grep -q .; then
        advise "Webhook '$wh' (Tech Spec §6.3) não citado por nenhuma story"
      fi
    fi
  done
else
  advise "$SPEC ausente — checagem F (contratos ↔ story) pulada"
fi

echo
info "cross-artifact: $CRIT crítico(s), $WARNS aviso(s)"
if [[ $CRIT -eq 0 ]]; then
  ok "check-cross-artifact: nenhum bloqueador — Execução liberada"
  exit 0
else
  fail "check-cross-artifact: $CRIT bloqueador(es) — resolva antes da Execução"
  exit 1
fi
