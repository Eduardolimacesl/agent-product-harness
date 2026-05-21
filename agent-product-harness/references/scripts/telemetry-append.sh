#!/usr/bin/env bash
# telemetry-append.sh — append one event to docs/memory/telemetry.jsonl
#
# Usage:
#   telemetry-append.sh \
#     --event <type> \
#     --story <story-id> \
#     --phase <phase> \
#     --data '<json>'
#
# All flags required except --story (omit for bootstrap-phase events).
#
# Event type must be one of:
#   plan_submitted | plan_approved | plan_rejected | gate_failed |
#   subagent_dispatched | human_intervention | story_closed |
#   spec_drift_detected
#
# Phase must be one of:
#   bootstrap | discovery | prd | design | spec | sprint | execution |
#   testing | deploy
#
# Validates against references/templates/telemetry-event-schema.json
# (via jq when available; falls back to minimal awk checks otherwise).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

EVENT=""; STORY=""; PHASE=""; DATA=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --event) EVENT="$2"; shift 2 ;;
    --story) STORY="$2"; shift 2 ;;
    --phase) PHASE="$2"; shift 2 ;;
    --data)  DATA="$2";  shift 2 ;;
    -h|--help)
      sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *)
      echo "ERRO: flag desconhecida: $1" >&2
      exit 2 ;;
  esac
done

if [[ -z "$EVENT" || -z "$PHASE" || -z "$DATA" ]]; then
  fail "uso: telemetry-append.sh --event <type> --phase <phase> --data '<json>' [--story <id>]"
  exit 2
fi

VALID_EVENTS="plan_submitted plan_approved plan_rejected gate_failed subagent_dispatched human_intervention story_closed spec_drift_detected"
if ! echo " $VALID_EVENTS " | grep -q " $EVENT "; then
  fail "evento inválido: $EVENT"
  echo "Válidos: $VALID_EVENTS" >&2
  exit 2
fi

VALID_PHASES="bootstrap discovery prd design spec sprint execution testing deploy"
if ! echo " $VALID_PHASES " | grep -q " $PHASE "; then
  fail "fase inválida: $PHASE"
  echo "Válidas: $VALID_PHASES" >&2
  exit 2
fi

if [[ "$PHASE" != "bootstrap" && -z "$STORY" ]]; then
  fail "--story é obrigatório para phase=$PHASE"
  exit 2
fi

# Validate data is JSON.
if command -v jq >/dev/null 2>&1; then
  if ! echo "$DATA" | jq -e . >/dev/null 2>&1; then
    fail "--data não é JSON válido: $DATA"
    exit 2
  fi
else
  # Minimal sanity: must start with { and end with }
  if ! [[ "$DATA" =~ ^[[:space:]]*\{.*\}[[:space:]]*$ ]]; then
    fail "--data não parece JSON (sem jq disponível para validação completa)"
    exit 2
  fi
fi

ROOT="$(repo_root)" || exit 1
OUT="$ROOT/docs/memory/telemetry.jsonl"
mkdir -p "$(dirname "$OUT")"
touch "$OUT"

TS=$(now)

# Build the event line. Prefer jq for proper escaping; otherwise hand-build
# and trust the caller didn't put control chars in --story.
if command -v jq >/dev/null 2>&1; then
  if [[ -n "$STORY" ]]; then
    EVENT_LINE=$(jq -nc \
      --arg ts "$TS" --arg event "$EVENT" \
      --arg story "$STORY" --arg phase "$PHASE" \
      --argjson data "$DATA" \
      '{ts:$ts, event:$event, story_id:$story, phase:$phase, data:$data}')
  else
    EVENT_LINE=$(jq -nc \
      --arg ts "$TS" --arg event "$EVENT" \
      --arg phase "$PHASE" \
      --argjson data "$DATA" \
      '{ts:$ts, event:$event, phase:$phase, data:$data}')
  fi
else
  if [[ -n "$STORY" ]]; then
    EVENT_LINE="{\"ts\":\"$TS\",\"event\":\"$EVENT\",\"story_id\":\"$STORY\",\"phase\":\"$PHASE\",\"data\":$DATA}"
  else
    EVENT_LINE="{\"ts\":\"$TS\",\"event\":\"$EVENT\",\"phase\":\"$PHASE\",\"data\":$DATA}"
  fi
fi

echo "$EVENT_LINE" >> "$OUT"
ok "appended $EVENT → $OUT"
