# Story Template — `docs/sprints/<N>/<story-id>.md`

> Unidade de trabalho da sprint. 1 story = 1 PR (ou conjunto pequeno de PRs).
> Salvar em `docs/sprints/<sprint-N>/<id>.md` — **nunca** na raiz de `sprints/`.
>
> Frontmatter completo definido em [`../00-conventions.md`](../00-conventions.md) §2.4.

---

## Frontmatter (obrigatório)

```yaml
---
id: us-NN-slug                       # us | ts | spike | chore + número + slug
name: <Title Case>
type: story                          # story | tech-task | spike | chore
priority: P0                         # P0 | P1 | P2
size: M                              # XS | S | M | L
sprint: <N>
status: todo                         # todo | doing | review | done
owner: unassigned
created: <ISO 8601 UTC>
updated: <ISO 8601 UTC>
depends_on: []                       # ["us-01-...", "ts-03-..."]
parallel: true                       # pode rodar concorrente com não-conflitantes
conflicts_with: []                   # ["us-04-..."] toca os mesmos arquivos
adr_refs: []                         # ["0001", "0003"] ADRs aplicáveis
github:                              # populado pelo 08-github-sync
---
```

Validação automática via [`../scripts/validate.sh`](../scripts/validate.sh).

---

## Contexto

> Por que esta story existe? Liga ao PRD/Spec.

```
PRD: <link/seção>
Spec: <link/seção>
```

---

## Como usuário

> Formato narrativo curto.

```
Como <persona>, quero <ação>, para que <benefício>.
```

---

## Critérios de aceite

**AC-1:**
- **Dado** `<contexto>`
- **Quando** `<ação>`
- **Então** `<resultado observável>`

**AC-2:** … (repetir)

**Casos de erro:**

- [ ] `<comportamento em caso de input inválido>`
- [ ] `<comportamento offline>`
- [ ] `<comportamento sem permissão>`

**Acessibilidade:**

- [ ] Navegação por teclado funciona
- [ ] Leitor de tela anuncia mudanças relevantes
- [ ] Contraste AA verificado

**Performance:**

- [ ] Não regride o budget de bundle
- [ ] LCP/INP da rota afetada dentro do budget

---

## Plano de implementação (Plan Artifact do agente)

> Preenchido pelo agente **antes** de tocar em código. Aprovado pelo humano
> (Gate 1). Template detalhado em
> [`../05-execution/06-plan-artifact-template.md`](../05-execution/06-plan-artifact-template.md).

**Arquivos a criar/modificar:**

| Arquivo | Ação | Motivo |
|---------|------|--------|
| `app/(app)/inspections/new/page.tsx` | criar | tela do formulário |
| `app/(app)/inspections/actions.ts` | modificar | adicionar `createInspection` |
| `lib/db/schema.ts` | modificar | nova coluna `notes` |

**Migrations necessárias:** `<sim/não, qual>`

**Quebra em passos:**

1. `[ ]` Atualizar schema + gerar migration
2. `[ ]` Criar Server Action validada com Zod
3. `[ ]` Criar página com Server Component + `<Form>`
4. `[ ]` Tratar estados loading/error com `useFormStatus`
5. `[ ]` Adicionar testes (unit do Zod + integration da action)
6. `[ ]` Adicionar E2E "criar inspeção" no Playwright
7. `[ ]` Validar a11y manualmente + axe
8. `[ ]` Atualizar README do módulo

**Dependências entre stories:** declaradas em `depends_on:` no frontmatter.
O script [`../scripts/next-story.sh`](../scripts/next-story.sh) usa esse campo
para identificar o que está pronto para começar.

**Subagentes envolvidos:**

- Para stories M+ tocando ≥3 camadas, considere paralelizar produzindo
  `<story-id>-analysis.md` conforme
  [`03-story-analysis-template.md`](03-story-analysis-template.md). Sem essa
  análise, **não** lançar sub-agentes em paralelo.
- Browser subagent: validar formulário e capturar screenshot do estado de erro.

---

## Testes a adicionar

| Tipo | O que testa | Arquivo |
|------|-------------|---------|
| Unit | validação Zod do input | `tests/unit/inspections.schema.test.ts` |
| Integration | action grava no DB | `tests/integration/inspections.action.test.ts` |
| E2E | criar inspeção fim-a-fim | `tests/e2e/inspections.spec.ts` |

---

## Riscos / pontos de atenção

```
[ex: "esta story toca o módulo de auth — revisar com cuidado autorização"]
```

> Se a story toca auth/RBAC/billing/PII e `adr_refs:` está vazio, o
> `validate.sh` recusa. Passo 0 do plano = redigir ADR.

---

## Definition of Done para esta story

- [ ] Todos AC verdes com evidência (screenshot/gif/log)
- [ ] Migrations aplicadas em staging
- [ ] Testes adicionados e passando
- [ ] PR aprovado
- [ ] Telemetria do novo evento configurada
- [ ] Documentação atualizada
- [ ] Smoke test em staging
- [ ] `status: done` no frontmatter; rodou `progress.sh <sprint>`

---

## Como instruir o agente

```
Trabalhe nesta story <id>.
1. Leia esta página inteira.
2. Leia AGENTS.md, docs/prd/01-glossary.md e a Tech Spec.
3. Rode bash <skill>/references/scripts/validate.sh — deve sair 0.
4. Antes de qualquer arquivo: gere o Plan Artifact (acima) preenchido e ESPERE
   minha aprovação.
5. Se size ≥ M e a story toca ≥3 camadas, gere também
   <id>-analysis.md (template em ../04-sprints/03-story-analysis-template.md).
6. Após aprovado, implemente passo a passo. Pause após cada passo se houver
   dúvida.
7. Rode `pnpm typecheck && pnpm lint && pnpm test:unit` no fim de cada passo.
8. Para validação visual, invoque o browser subagent e anexe screenshot ao
   Artifact.
9. Não rode `git push`. Não toque em arquivos fora da lista do plano sem
   perguntar.
10. Ao final: status: done + progress.sh + execution log em
    docs/memory/execution/<YYYY-MM-DD>-<id>.md.
```
