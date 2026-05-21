# Subagent Delegation — Quando, Como e Para Quê

> Antigravity permite orquestrar múltiplos agentes em paralelo via **Agent Manager** (Mission Control), além de subagentes especializados (browser subagent). Este documento dita as regras de quando vale paralelizar, quando vale especializar, e quando é melhor manter **um único agente**.

---

## Modelo mental

```
                ┌──────────────────────┐
                │   Você (humano)      │
                │   Arquiteto / PM     │
                └──────────┬───────────┘
                           │ define objetivo
                           ▼
                ┌──────────────────────┐
                │  Agente principal    │  ← faz o plano, executa o grosso
                │  (conversa de chat)  │
                └──────────┬───────────┘
                           │ delega
                ┌──────────┼──────────┐
                ▼          ▼          ▼
        Browser sub.   Outro agente   Outro workspace
        (validação    (workspace      (tarefa
        visual)        paralelo)      ortogonal)
```

---

## Tipos de delegação

### 1. Subagente embutido (browser subagent)

Já existe no Antigravity. **Use sempre** que precisar de:

- Validação visual de uma rota / componente / fluxo.
- Smoke test E2E rápido durante implementação.
- Captura de screenshot/gravação para Artifact de revisão.
- Verificar console errors no browser real.

**Comando padrão para o agente principal:**

```
Use o browser subagent para abrir <URL>, executar <ação>,
capturar screenshot do resultado e anexar ao Artifact.
Pare se houver erro no console.
```

### 2. Agente paralelo no mesmo workspace

⚠️ **Evitar** quando os agentes podem tocar arquivos sobrepostos. Conflito de edição é o cenário mais comum de retrabalho.

**Use só quando:**

- As tarefas são **estritamente ortogonais** (ex.: agente A escreve documentação, agente B escreve testes que **não** dependem do código que A está alterando).
- Há mecanismo de coordenação (branches diferentes, worktrees).

### 3. Agente em workspace separado

✅ **Padrão para paralelização real.**

Cenários típicos:

- Workspace `app/` (frontend) e `infra/` (terraform/CI) avançando em paralelo.
- Workspace `web/` e `mobile/` compartilhando contratos.
- Worktree separado dedicado a refactoring grande, isolado da feature em andamento.

### 4. Não delegar (manter agente único)

Use **um agente, um chat, uma story** quando:

- A story é coesa e cabe em uma sessão.
- Há acoplamento alto entre arquivos.
- O custo de coordenação > benefício do paralelismo.

> **Default deve ser não delegar.** Delegação tem custo cognitivo, e às vezes você sai com 3 PRs meia-boca quando teria saído com 1 PR sólido.

---

## Matriz de decisão

| Situação | Decisão |
|----------|---------|
| Story M, 3–5 arquivos, 1 módulo | 1 agente |
| Validação visual durante a story | + browser subagent |
| Refactor grande + feature ao mesmo tempo | 2 workspaces (worktree) |
| Documentação extensa + código | 1 agente, sequencial; ou 2 workspaces se ortogonais |
| Migration de schema + UI dependente | 1 agente, sequencial. **Nunca paralelo.** |
| Setup de CI + setup de auth | 2 workspaces, ortogonal ✅ |
| Bug em produção | 1 agente, foco total, sem paralelismo |

---

## Como instruir cada subagente

### Princípio: Briefing mínimo, contexto recortado

Cada subagente recebe **apenas**:

1. **Objetivo único** — uma frase.
2. **Critério de pronto** — observável, verificável.
3. **Restrições** — o que **não** fazer.
4. **Recursos** — links para docs específicas (não o repo inteiro).

### Template — briefing de subagente

```
OBJETIVO
<uma frase clara, verbo no imperativo>

PRONTO QUANDO
- [ ] <critério 1>
- [ ] <critério 2>

NÃO FAÇA
- <fora do escopo 1>
- <fora do escopo 2>

LEIA APENAS
- AGENTS.md
- docs/spec/00-tech-spec.md (seção <X>)
- <arquivo específico>

OUTPUT ESPERADO
- Artifact com diff + 5 linhas de sumário
```

### Exemplo concreto

```
OBJETIVO
Adicionar testes E2E para o fluxo "criar inspeção" no Playwright.

PRONTO QUANDO
- [ ] tests/e2e/inspections.spec.ts existe e passa
- [ ] Cobre: usuário logado, formulário válido, formulário inválido, persistência
- [ ] Roda em < 30s no CI

NÃO FAÇA
- Não modifique app/(app)/inspections/* (essa é outra story)
- Não introduza dependências novas sem ADR

LEIA APENAS
- AGENTS.md
- harness/06-testing/00-testing-strategy.md
- docs/sprints/<n>/US-01.md
- playwright.config.ts existente

OUTPUT ESPERADO
- Artifact com o teste, screenshot da execução verde, sumário em 5 linhas
```

---

## Regras de coordenação

### Quem é o "tech lead" da sessão?

Sempre o **agente principal** com quem você está conversando. Subagentes reportam para ele, não para você diretamente. Você fala com o principal; ele decompõe.

### Sincronização

- Subagentes finalizam **antes** do principal consolidar.
- O principal **valida** os Artifacts dos subagentes antes de declarar tarefa pronta.
- Conflitos: o principal **escolhe** e justifica no Artifact final.

### Falha de subagente

Se um subagente:

- ❌ Excede orçamento de tempo/turnos → cancele e refaça com escopo menor.
- ❌ Toca arquivos fora do briefing → reverta a alteração; refaça o briefing.
- ❌ Produz código que quebra typecheck do projeto → o principal **não** integra; pede correção ou refaz.

---

## Padrões de delegação por fase

| Fase | Recomendação |
|------|--------------|
| Discovery | 1 agente, modo conversacional. Sem subagentes. |
| PRD | 1 agente. Eventualmente subagente para validação de concorrência via web. |
| Spec | 1 agente para produtos S; **Concept + Algorithm split** para produtos M+ (ver §"Concept + Algorithm split" abaixo). |
| Sprint planning | 1 agente. |
| Execução de story | 1 agente principal + browser subagent quando há UI. |
| Refatoração grande | Workspace dedicado, agente separado, agent-driven com revisão. |
| Hotfix | 1 agente, foco máximo, sem paralelismo. |
| Documentação extensa | 1 agente sequencial, ou workspace separado em paralelo se docs são ortogonais ao código. |

---

## Concept + Algorithm split em fase Spec (produtos M+)

Para produtos com domínio não-trivial (≥ 2 bounded contexts, ≥ 3 ADRs
previstos, ou modelo de domínio em `02-domain-model.md`), a fase Spec
ganha dois subagentes em paralelo (Li et al. 2025, DeepCode §2.1 —
Multi-Agent Specification Analysis):

| Subagente | Perspectiva | Responde a |
|---|---|---|
| **Concept Agent** | "o que" e "por que" | bounded contexts, agregados, eventos, casos de uso, RNFs |
| **Algorithm Agent** | "como" | esquema de dados, contratos de Server Action, fluxo de auth, caching, observabilidade |

### Briefing — Concept Agent

```
OBJETIVO
A partir do PRD aprovado, produza o modelo conceitual da Tech Spec:
seções B1 (File Hierarchy a nível de bounded context), §4 (Modelo de
domínio), §8 (Auth de alto nível), §13 (Riscos técnicos do conceito).

PRONTO QUANDO
- [ ] docs/spec/00-tech-spec.md §4 preenchido com diagrama ER + dicionário
- [ ] docs/spec/02-domain-model.md com ≥1 bounded context + agregados + eventos
- [ ] §13 lista 3+ riscos com mitigação proposta

NÃO FAÇA
- Não escolha banco, ORM, provedor de auth, lib de validação — isso é do Algorithm Agent.
- Não escreva código de Server Action ou schema SQL.
- Não abra ADRs sem flag 🟡 — a reconciliação humana decide.

LEIA APENAS
- AGENTS.md
- docs/prd/00-prd.md + docs/prd/01-glossary.md
- harness/03-spec/02-domain-model.md (template)
- harness/03-spec/00-tech-spec.md §0–§4, §13

OUTPUT ESPERADO
- Diff em docs/spec/ + sumário ≤ 5 linhas + lista de questões para
  reconciliação humana.
```

### Briefing — Algorithm Agent

```
OBJETIVO
A partir do PRD aprovado, produza o modelo algorítmico da Tech Spec:
seções B2 (Component Specification), §5 (Schema), §6 (Contratos),
§7 (Caching), §9 (Observabilidade), §10 (Performance), §11 (Segurança).

PRONTO QUANDO
- [ ] docs/spec/00-tech-spec.md §5 com schema inicial Drizzle + índices
- [ ] §6 com contratos Zod por Server Action + webhooks
- [ ] §10 com budgets explícitos
- [ ] §11 com checklist por item

NÃO FAÇA
- Não defina bounded contexts, agregados ou eventos de domínio — isso é do Concept Agent.
- Não escolha o "porquê" — só o "como" das decisões já enquadradas.
- Não abra ADRs sem flag 🟡 — reconciliação humana decide.

LEIA APENAS
- AGENTS.md
- docs/prd/00-prd.md
- harness/03-spec/00-tech-spec.md §0, §5–§7, §9–§11

OUTPUT ESPERADO
- Diff em docs/spec/ + sumário ≤ 5 linhas + lista de questões para
  reconciliação humana.
```

### Reconciliação — humana, não delegada

Conflitos entre as duas perspectivas (ex.: Concept Agent define agregado
`Inspection` rico em invariantes; Algorithm Agent escolhe schema CRUD que
não suporta esses invariantes) **viram ADRs**. O eng lead reconcilia:

1. Lê as duas saídas em paralelo.
2. Para cada divergência relevante, abre ADR justificando a escolha.
3. Aprova a versão final da Tech Spec só **depois** dos ADRs aceitos.

A reconciliação **nunca** é delegada a um terceiro agente — esse é o
ponto onde a decisão humana tem maior alavancagem.

### Quando NÃO usar o split

- Produtos S (1 bounded context, CRUD simples) — o overhead de coordenação
  ultrapassa o ganho.
- Refatoração de Spec já existente (use 1 agente focado).
- Spec urgente em sprint de hotfix — sem fôlego para reconciliação.

---

## Anti-padrões

- ❌ Subir 5 agentes "para acelerar" sem delimitar workspace e escopo. Resultado: merge hell.
- ❌ Pedir para o subagente "ler tudo do projeto antes de começar". Resultado: token gasto, foco perdido.
- ❌ Usar `agent-driven` em subagente novo, sem track record de confiança no domínio.
- ❌ Delegar decisão de arquitetura para subagente. Decisões vão para ADR, não para chat efêmero.
- ❌ Manter subagente vivo entre stories diferentes. Encerre, abra nova sessão com briefing limpo.
