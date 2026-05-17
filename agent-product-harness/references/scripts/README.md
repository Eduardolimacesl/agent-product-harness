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
| `phase-status.sh` | Mostra qual fase está concluída e qual é a próxima. | — |
| `sprint-status.sh` | Resumo de stories por status na sprint. | `<sprint-N>?` |
| `story-list.sh` | Lista stories com badges. | `<sprint-N>?` |
| `next-story.sh` | Próxima story pronta (sem dep não-resolvida). | `<sprint-N>?` |
| `progress.sh` | Recalcula `progress:` no `sprint-plan.md`. | `<sprint-N>` |
| `_lib.sh` | Helpers (sourced por outros scripts). | — |
| `_safety.sh` | Bloqueia escrita no próprio repo da skill. | — |

---

## Quando usar o LLM em vez do script

+ Output do script tem erro ou ambiguidade.
+ Usuário pergunta "o que isso significa" sobre o output.
+ Tarefa requer escrever conteúdo (não só ler/contar).
+ Decisão envolve trade-off ou prioridade subjetiva.

Fora desses casos: rode o script primeiro, sempre.
