#!/usr/bin/env bash
# telemetry-report.sh [<jsonl-file>...] — aggregate metrics from telemetry.
#
# Without args, reads docs/memory/telemetry.jsonl plus any rotated files
# matching docs/memory/telemetry-*.jsonl. Prints:
#
#   - total events + per-event counts
#   - plan rejection rate (plan_rejected / (plan_submitted))
#   - gate_failed distribution by gate
#   - spec drift count
#   - average story duration (when story_closed has duracao_min)
#
# Each line of telemetry.jsonl is one event; see
# references/05-execution/11-telemetry-protocol.md.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

declare -a FILES
if [[ $# -gt 0 ]]; then
  FILES=("$@")
else
  ROOT="$(repo_root)" || exit 1
  [[ -f "$ROOT/docs/memory/telemetry.jsonl" ]] && FILES+=("$ROOT/docs/memory/telemetry.jsonl")
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    FILES+=("$f")
  done < <(find "$ROOT/docs/memory" -maxdepth 1 -name 'telemetry-*.jsonl' 2>/dev/null | sort)
fi

if [[ ${#FILES[@]} -eq 0 ]]; then
  warn "nenhum arquivo de telemetria encontrado"
  exit 0
fi

# Concat all files, drop blank lines.
INPUT=$(cat "${FILES[@]}" 2>/dev/null | grep -v '^[[:space:]]*$' || true)
TOTAL=$(echo "$INPUT" | grep -c . || true)

echo "Telemetry report — $(date)"
echo "  Arquivos: ${#FILES[@]}"
echo "  Eventos:  $TOTAL"
echo

if [[ $TOTAL -eq 0 ]]; then
  warn "sem eventos para agregar"
  exit 0
fi

# Per-event counts. Uses jq if available; else a regex-based extractor.
echo "Distribuição por evento:"
if command -v jq >/dev/null 2>&1; then
  echo "$INPUT" | jq -r '.event' | sort | uniq -c | sort -rn \
    | awk '{ printf "  %-26s %d\n", $2, $1 }'
else
  echo "$INPUT" | grep -oE '"event"[[:space:]]*:[[:space:]]*"[^"]+"' \
    | sed -E 's/.*"event"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' \
    | sort | uniq -c | sort -rn \
    | awk '{ printf "  %-26s %d\n", $2, $1 }'
fi
echo

# Plan rejection rate.
P_SUB=$(echo "$INPUT" | grep -c '"event"[[:space:]]*:[[:space:]]*"plan_submitted"' || true)
P_REJ=$(echo "$INPUT" | grep -c '"event"[[:space:]]*:[[:space:]]*"plan_rejected"' || true)
if [[ $P_SUB -gt 0 ]]; then
  RATE=$(awk -v r="$P_REJ" -v s="$P_SUB" 'BEGIN { printf "%.1f", (r/s)*100 }')
  echo "Plan-rejection rate: $P_REJ / $P_SUB = ${RATE}%"
else
  echo "Plan-rejection rate: sem plans submetidos"
fi
echo

# Gate failure distribution.
echo "Falhas de gate (por tipo):"
if command -v jq >/dev/null 2>&1; then
  GATES=$(echo "$INPUT" | jq -r 'select(.event=="gate_failed") | .data.gate // "?"' | sort | uniq -c | sort -rn)
else
  GATES=$(echo "$INPUT" \
    | grep '"event"[[:space:]]*:[[:space:]]*"gate_failed"' \
    | grep -oE '"gate"[[:space:]]*:[[:space:]]*"[^"]+"' \
    | sed -E 's/.*"gate"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' \
    | sort | uniq -c | sort -rn)
fi
if [[ -z "$GATES" ]]; then
  echo "  (nenhuma)"
else
  echo "$GATES" | awk '{ printf "  %-12s %d\n", $2, $1 }'
fi
echo

# Spec drift count.
DRIFT=$(echo "$INPUT" | grep -c '"event"[[:space:]]*:[[:space:]]*"spec_drift_detected"' || true)
CLOSED=$(echo "$INPUT" | grep -c '"event"[[:space:]]*:[[:space:]]*"story_closed"' || true)
if [[ $CLOSED -gt 0 ]]; then
  RATIO=$(awk -v d="$DRIFT" -v c="$CLOSED" 'BEGIN { printf "%.1f", (d/c)*100 }')
  echo "Spec drift: $DRIFT detectado(s) / $CLOSED stories fechadas = ${RATIO}%"
  if awk -v r="$RATIO" 'BEGIN { exit !(r > 10) }'; then
    warn "drift > 10% — abra story na sprint de saúde do harness"
  fi
else
  echo "Spec drift: $DRIFT detectado(s) (sem stories fechadas para ratio)"
fi
echo

# Average story duration when reported.
if command -v jq >/dev/null 2>&1; then
  DURATIONS=$(echo "$INPUT" | jq -r 'select(.event=="story_closed") | .data.duracao_min // empty' | grep -E '^[0-9.]+$' || true)
  if [[ -n "$DURATIONS" ]]; then
    AVG=$(echo "$DURATIONS" | awk '{ s += $1; n += 1 } END { if (n>0) printf "%.1f", s/n }')
    N=$(echo "$DURATIONS" | wc -l | tr -d ' ')
    echo "Duração média de story (min): $AVG  (n=$N)"
  fi
fi

# Approvals Ledger summary (separate file from telemetry).
LEDGER="docs/memory/approvals.jsonl"
if [[ -z "${FILES[0]:-}" ]] || [[ ! -f "${FILES[0]}" ]] || ! [[ "${FILES[0]}" == *approvals* ]]; then
  ROOT2="$(repo_root 2>/dev/null)" || true
  [[ -n "$ROOT2" && -f "$ROOT2/docs/memory/approvals.jsonl" ]] && LEDGER="$ROOT2/docs/memory/approvals.jsonl"
fi
if [[ -f "$LEDGER" ]]; then
  echo
  echo "Approvals ledger ($LEDGER):"
  L_TOTAL=$(grep -c . "$LEDGER" 2>/dev/null || echo 0)
  if command -v jq >/dev/null 2>&1; then
    L_RULES=$(jq -r 'select(.becomes_rule != null and .becomes_rule != "") | .ts' "$LEDGER" 2>/dev/null | wc -l | tr -d ' ')
    L_PROMOTED=$(jq -r 'select(.promoted_to != null and .promoted_to != "") | .ts' "$LEDGER" 2>/dev/null | wc -l | tr -d ' ')
  else
    L_RULES=$(grep -c '"becomes_rule"' "$LEDGER" 2>/dev/null || echo 0)
    L_PROMOTED=$(grep -c '"promoted_to"' "$LEDGER" 2>/dev/null || echo 0)
  fi
  L_PENDING=$((L_RULES - L_PROMOTED))
  printf "  total            %d\n" "$L_TOTAL"
  printf "  com becomes_rule %d\n" "$L_RULES"
  printf "  promovidas       %d\n" "$L_PROMOTED"
  printf "  pendentes        %d\n" "$L_PENDING"
  if [[ $L_PENDING -ge 5 ]]; then
    warn "≥5 regras candidatas não promovidas — story de promoção de políticas?"
  fi
fi
