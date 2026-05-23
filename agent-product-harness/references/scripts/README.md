# Scripts — Operações determinísticas

Scripts bash para operações que **não** precisam de LLM: contar, listar,
validar, calcular progresso. Análogo a `ccpm/references/scripts/`.

## Filosofia

> Use o LLM para o que requer raciocínio (escrever PRD, decompor stories,
> revisar diff). Use scripts para o que requer apenas leitura e regra fixa.

Isso reduz custo de tokens, padroniza output e elimina variação entre
sessões.

---

## Como rodar

De dentro do diretório do projeto (onde `docs/` vive):

```bash
bash <skill_path>/scripts/<script>.sh [args]
```

Quando a skill está symlinked em `.gemini/antigravity/skills/agent-product-harness/`:

```bash
bash .gemini/antigravity/skills/agent-product-harness/agent-product-harness/references/scripts/validate.sh
```

Dica: criar alias no projeto:

```bash
alias aph='bash <skill_path>/scripts'
aph/validate.sh
```

---

## Catálogo

| Script | O que faz | Argumentos |
|--------|-----------|------------|
| `help.sh` | Lista todos os scripts disponíveis. | — |
| `validate.sh` | Checa convenções e gates do harness. Sai 0/1. | — |
| `check-spec-drift.sh` | Detecta drift entre Tech Spec / Domain Model e o código de contratos (Server Actions, Domain Events, Webhooks). Lê ADR-0001 para detectar variante de layout. Sai 0/1/2. | — |
| `check-clarifications.sh` | Detecta marcadores `[NEEDS CLARIFICATION]` abertos (Clarify Protocol). Gate PRD→Spec e Spec→Sprint. Sai 0/1/2. | `[<dir>...]` (default `docs/prd docs/spec`) |
| `check-cross-artifact.sh` | Coerência entre Constitution / PRD / Tech Spec / Stories antes da Execução (Cross-Artifact Analysis). CRITICAL bloqueia; WARN avisa. Sai 0/1/2. | — |
| `phase-status.sh` | Mostra qual fase está concluída e qual é a próxima. | — |
| `sprint-status.sh` | Resumo de stories por status na sprint. | `<sprint-N>?` |
| `story-list.sh` | Lista stories com badges. | `<sprint-N>?` |
| `next-story.sh` | Próxima story pronta (sem dep não-resolvida). | `<sprint-N>?` |
| `progress.sh` | Recalcula `progress:` no `sprint-plan.md`. | `<sprint-N>` |
| `spec-fetch.sh` | Emite uma seção do Tech Spec (heading + corpo). Hierarchical Content Segmentation, Li et al. 2025. | `"<heading>" [<file>]` |
| `spec-index.sh` | Gera índice JSON de headings do Tech Spec em `docs/spec/.00-tech-spec.index.json`. | `[<file>]` |
| `telemetry-append.sh` | Anexa um evento ao `docs/memory/telemetry.jsonl`. Valida tipo, fase, JSON. | `--event <t> --phase <p> --data '<json>' [--story <id>]` |
| `telemetry-report.sh` | Agrega telemetria: total, taxa de plan-rejection, gates falhados, drift ratio, duração média. | `[<jsonl-file>...]` |
| `codemap-update.sh` | Detecta módulos públicos alterados pela story e lista entradas de codemap a (re)gerar. Determinístico, sem LLM. | `<story-id> [--base <ref>]` |
| `codemap-graph.sh` | Regenera `docs/memory/codemap/graph.json` a partir dos `modules/*.md`. | — |
| `approvals-append.sh` | Anexa uma entrada ao `docs/memory/approvals.jsonl` (HITL ledger). Valida tier, decisão, JSON. | `--tier <t> --action "<>" --evidence "<>" --risks "<>" --decision <d> --by <name> [--story <id>] [--condition "<>"] [--becomes-rule "<>"]` |
| `_lib.sh` | Helpers (sourced por outros scripts). | — |
| `_safety.sh` | Bloqueia escrita no próprio repo da skill. | — |

---

## Quando usar o LLM em vez do script

+ Output do script tem erro ou ambiguidade.
+ Usuário pergunta "o que isso significa" sobre o output.
+ Tarefa requer escrever conteúdo (não só ler/contar).
+ Decisão envolve trade-off ou prioridade subjetiva.

Fora desses casos: rode o script primeiro, sempre.
