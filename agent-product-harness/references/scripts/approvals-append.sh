#!/usr/bin/env bash
# approvals-append.sh — append one entry to docs/memory/approvals.jsonl
#
# Usage:
#   approvals-append.sh \
#     --tier <read-only|sandbox-edit|full-access> \
#     --action "<one-line>" \
#     --evidence "<what was shown to human>" \
#     --risks "<risks surfaced>" \
#     --decision <approved|rejected|approved-with-condition> \
#     --by <name-or-handle> \
#     [--story <story-id>] \
#     [--condition "<condition>"] \
#     [--becomes-rule "<rule>"]
#
# Validates against references/templates/approval-entry-schema.json
# (jq when available; minimal checks otherwise).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

TIER=""; ACTION=""; EVIDENCE=""; RISKS=""
DECISION=""; BY=""; STORY=""; COND=""; RULE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tier)         TIER="$2"; shift 2 ;;
    --action)       ACTION="$2"; shift 2 ;;
    --evidence)     EVIDENCE="$2"; shift 2 ;;
    --risks)        RISKS="$2"; shift 2 ;;
    --decision)     DECISION="$2"; shift 2 ;;
    --by)           BY="$2"; shift 2 ;;
    --story)        STORY="$2"; shift 2 ;;
    --condition)    COND="$2"; shift 2 ;;
    --becomes-rule) RULE="$2"; shift 2 ;;
    -h|--help)      sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "ERRO: flag desconhecida: $1" >&2; exit 2 ;;
  esac
done

for v in TIER ACTION EVIDENCE RISKS DECISION BY; do
  if [[ -z "${!v}" ]]; then
    fail "campo obrigatório ausente: --${v,,}"
    echo "rode --help para ver o uso" >&2
    exit 2
  fi
done

case "$TIER" in
  read-only|sandbox-edit|full-access) ;;
  *) fail "tier inválido: $TIER"; exit 2 ;;
esac

case "$DECISION" in
  approved|rejected|approved-with-condition) ;;
  *) fail "decision inválida: $DECISION"; exit 2 ;;
esac

if [[ "$DECISION" == "approved-with-condition" && -z "$COND" ]]; then
  fail "--condition é obrigatório quando --decision=approved-with-condition"
  exit 2
fi

ROOT="$(repo_root)" || exit 1
OUT="$ROOT/docs/memory/approvals.jsonl"
mkdir -p "$(dirname "$OUT")"
touch "$OUT"

TS=$(now)

if command -v jq >/dev/null 2>&1; then
  ARGS=(
    --arg ts "$TS"
    --arg tier "$TIER"
    --arg action "$ACTION"
    --arg evidence "$EVIDENCE"
    --arg risks "$RISKS"
    --arg decision "$DECISION"
    --arg by "$BY"
  )
  FILTER='{ts:$ts, tier:$tier, action_proposed:$action, evidence_shown:$evidence, risks_surfaced:$risks, decision:$decision, decided_by:$by}'

  if [[ -n "$STORY" ]]; then
    ARGS+=(--arg story "$STORY")
    FILTER+=' + {story_id:$story}'
  fi
  if [[ -n "$COND" ]]; then
    ARGS+=(--arg cond "$COND")
    FILTER+=' + {condition:$cond}'
  fi
  if [[ -n "$RULE" ]]; then
    ARGS+=(--arg rule "$RULE")
    FILTER+=' + {becomes_rule:$rule}'
  fi
  LINE=$(jq -nc "${ARGS[@]}" "$FILTER")
else
  # Hand-built (no escaping for control chars; jq is the official path).
  LINE="{\"ts\":\"$TS\",\"tier\":\"$TIER\",\"action_proposed\":\"$ACTION\",\"evidence_shown\":\"$EVIDENCE\",\"risks_surfaced\":\"$RISKS\",\"decision\":\"$DECISION\",\"decided_by\":\"$BY\""
  [[ -n "$STORY" ]] && LINE+=",\"story_id\":\"$STORY\""
  [[ -n "$COND"  ]] && LINE+=",\"condition\":\"$COND\""
  [[ -n "$RULE"  ]] && LINE+=",\"becomes_rule\":\"$RULE\""
  LINE+="}"
fi

echo "$LINE" >> "$OUT"
ok "registrado: $DECISION ($TIER) → $OUT"
