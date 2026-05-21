# Telemetry Protocol — `docs/memory/telemetry.jsonl`

> Camada de **deep telemetry** do harness — registra o **processo** de
> decisão do agente (prompts, gates, intervenções), não só o resultado.
> Triplo-confirmado por Zhou et al. 2026 §1.4 ("observabilidade do agente"),
> Li et al. 2025 §5 ("métricas de sucesso") e Ning et al. 2026 §3.5.1
> ("Deep Telemetry"). Coexiste com `docs/memory/execution/*.md` — aquele é
> log narrativo para humanos, este é estruturado e agregável.

## 1. Princípio

Sem dados estruturados, a revisão do harness é *anecdotal debugging*. Com
deep telemetry, vira *comparative diagnosis*: "qual a taxa de plan-rejection
nos últimos 30 dias?", "quantos gates falharam por typecheck vs. teste?",
"o tempo Plan→Diff caiu depois da story X?". É o substrato que justifica
mexer no harness (story H2-002, Change Contract).

## 2. Formato

JSONL — um JSON por linha. Arquivo: `docs/memory/telemetry.jsonl` (vazio
após bootstrap). Rotação por sprint: `telemetry-<N>.jsonl` opcional;
`telemetry-report.sh` agrega todos.

```json
{
  "ts": "2026-01-15T14:30:00Z",
  "event": "plan_rejected",
  "story_id": "auth-002",
  "phase": "execution",
  "data": { "motivo": "escopo negativo ausente", "tentativa": 1 }
}
```

Campos obrigatórios: `ts` (ISO 8601 UTC), `event` (um dos 7 tipos abaixo),
`phase` (`bootstrap | discovery | prd | design | spec | sprint | execution | testing | deploy`),
`data` (objeto, schema livre por tipo). `story_id` é obrigatório para todos
os eventos exceto `bootstrap`.

## 3. Os 7 tipos de evento

| Evento | Quando emitir | Campos-chave em `data` |
|---|---|---|
| `plan_submitted` | Plan Artifact pronto para Gate 1 | `n_arquivos`, `n_subagentes`, `tem_adr_step` |
| `plan_approved` | Humano aprovou Plan Artifact | `tentativa` |
| `plan_rejected` | Humano rejeitou Plan Artifact | `tentativa`, `motivo` |
| `gate_failed` | typecheck/lint/test/e2e falhou em um passo | `gate` (`typecheck\|lint\|test\|e2e\|smoke`), `n_tentativa` |
| `subagent_dispatched` | Subagente iniciado | `tipo` (`browser\|paralelo\|worktree`), `objetivo` |
| `human_intervention` | Humano interveio (correção, aprovação extra, escalação) | `tipo` (`approval\|correction\|escalation`), `tier` (ver H2-001) |
| `story_closed` | Story fechou em done/cancelled | `status_final`, `tokens_aprox`, `custo_aprox`, `duracao_min` |
| `spec_drift_detected` | Protocolo de Spec Drift disparou | `severidade`, `tipo_drift` |

> Tokens/custo são estimativas, não contabilidade. O valor é tendência
> comparável, não auditoria fiscal.

## 4. Quem emite — pontos de emissão no SKILL.md

A emissão NÃO é um passo novo — é side-effect de passos que já existem:

| SKILL.md ponto | Evento |
|---|---|
| §A passo 7 (bootstrap conclui) | (opcional) — nenhum, log narrativo basta |
| §D passo 4 (Plan Artifact pronto) | `plan_submitted` |
| §D passo 4 (humano aprova / rejeita) | `plan_approved` ou `plan_rejected` |
| §D passo 5 (typecheck/lint/test falha) | `gate_failed` |
| §D passo 3 / passo 5 (subagente iniciado) | `subagent_dispatched` |
| §D passo 8 (human review com fix solicitado) | `human_intervention` |
| §D passo 10 (status: done) | `story_closed` |
| §H passo 4 (drift report criado) | `spec_drift_detected` |

## 5. Como emitir

```bash
bash <skill>/references/scripts/telemetry-append.sh \
  --event plan_rejected --story us-04-billing --phase execution \
  --data '{"motivo":"escopo negativo ausente","tentativa":1}'
```

O script valida contra schema antes de escrever.

## 6. Como agregar

```bash
bash <skill>/references/scripts/telemetry-report.sh [<file...>]
```

Sem argumentos: lê `docs/memory/telemetry.jsonl` + `docs/memory/telemetry-*.jsonl`.
Imprime ≥4 métricas: taxa de plan-rejection, distribuição de `gate_failed`,
tempo médio Plan→Diff por story, contagem de drifts.

## 7. Privacidade e custo

- Nada de PII em `data`. Story IDs são internos.
- Sem prompts crus — apenas metadados estruturados.
- Tokens/custo são **estimativas**: registre o que o runtime expõe; não
  invente. Se desconhecido, omita o campo.

## 8. Quando NÃO emitir

- Em retry automático de mesma operação dentro do mesmo passo (use
  `n_tentativa` no evento existente).
- Em rascunhos descartados do Plan Artifact (só emite ao submeter).
- Em sessões de Q&A sobre o harness (sem story).

## 9. Anti-padrões

- ❌ Emitir eventos com `event: "info"` ou similar. Tipo desconhecido =
  evento perdido. Use um dos 7.
- ❌ Colocar prompt cru ou trecho de código em `data`. Estruturado, curto.
- ❌ Usar telemetria como substituto do `docs/memory/execution/*.md` —
  são camadas diferentes. Cada uma resolve um problema.

## 10. Schema

JSON Schema canônico:
[`references/templates/telemetry-event-schema.json`](../templates/telemetry-event-schema.json).
`telemetry-append.sh` valida cada evento contra esse schema antes de
gravar.
