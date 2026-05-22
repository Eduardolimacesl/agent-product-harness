# Spec Drift Protocol

> Saída disciplinada do "Plan-then-Code" rígido. Quando o agente descobre,
> durante a execução, que o Tech Spec/PRD/ADR está **errado, incompleto ou
> contradiz a realidade do código**, esta é a única rota legal — workaround
> silencioso é proibido pela Hard rule do [`SKILL.md`](../../SKILL.md).

## 1. Princípio

O blueprint pode estar errado. O agente **descobre**, **pausa**, **escala** e
**espera decisão humana**. Failed verification updates the plan, não o contrário
(Ning et al. 2026, §3.4.2).

## 2. Quando dispara (apenas estes três sinais)

1. **Contradição direta** entre Spec e código existente.
2. **Lacuna explícita**: o passo do plano exige decisão (interface, fluxo,
   regra) que não está no PRD, Spec ou ADR aplicável.
3. **Premissa falsa**: o plano assume estado/dep que, ao ser verificado, não
   existe (tabela, lib, env var, feature flag).

**Não disparam:** typo, ambiguidade resolvível por leitura, refactor cosmético,
decisão deixada em aberto por design (ex.: nome de variável).

## 3. Procedimento

1. **Pause** a execução. Nada de commit.
2. `status: blocked-spec-drift` no frontmatter da story.
3. Crie `docs/sprints/<N>/<story-id>-drift.md` via
   [`05-spec-drift-report-template.md`](05-spec-drift-report-template.md).
4. Emita `spec_drift_detected` na telemetria (após H1-003).
5. Apresente ao humano. Aguarde decisão.

## 4. Decisão humana (escolher exatamente uma)

| Opção | Significa | Ação |
|---|---|---|
| **A. Corrigir Spec/PRD** | Blueprint errado | Atualiza Spec + ADR retroativa. Story retoma. |
| **B. Ajustar story** | Story interpretou mal | Edita AC/plano. Story retoma. |
| **C. Cancelar story** | Premissa caiu | `status: cancelled`. Abre nova se aplicável. |

**Hard rule:** sem decisão registrada (ADR retroativa, edição assinada, ou
cancelamento), a story **não** sai de `blocked-spec-drift`.

## 5. Auditoria

Telemetria mede `spec_drift_detected / story_closed`. Se >10%, a fase Spec está
sendo apressada — abrir story na sprint de saúde do harness.

## 6. Anti-padrões

- ❌ Implementar "o que faz mais sentido" sem registrar a decisão.
- ❌ Atualizar a Spec silenciosamente no mesmo PR da story.
- ❌ Mudar o AC para se livrar do block.
- ❌ Tratar drift como bug.

## 7. Caso de teste (dry-run)

**Cenário:** na story `us-04-billing-webhook`, o agente nota que a Tech Spec
§6.3 lista o webhook `stripe.checkout.completed` mas a tabela `webhook_events`
em produção tem `UNIQUE(event_id, provider)` e a Spec não cobre re-entrega.

**Passos esperados:** agente pausa → `status: blocked-spec-drift` → cria
`us-04-billing-webhook-drift.md` (tipo: contradição direta) → emite
`spec_drift_detected` → humano decide **A** (corrige Spec §6.3 + ADR-0042
retroativa) → story retoma.
