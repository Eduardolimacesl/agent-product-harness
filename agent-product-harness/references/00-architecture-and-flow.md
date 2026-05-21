# Arquitetura e Fluxo do Harness

> Como as peças deste harness se encaixam, em que ordem fluem, quem produz e quem consome cada artefato, e por que as restrições foram desenhadas assim.

> Leia este documento **antes** de qualquer outro. Ele é o mapa que dá sentido ao restante.

---

## 1. O que é o harness

Um **harness** é um arnês: um conjunto de cordas que prende o trabalho humano e o trabalho dos agentes a uma estrutura, evitando que qualquer dos dois caia no precipício.

Tecnicamente, este harness é:

- Um **conjunto de templates de documentos** (discovery, PRD, spec, ADR, sprint, story, runbook, checklist).
- Um **protocolo de contexto** que governa o que cada agente lê, lembra e esquece.
- Um **conjunto de rules** (`AGENTS.md`) que o Google Antigravity e outros runtimes agênticos compatíveis carregam automaticamente.
- Uma **convenção de stack** (Next.js 16.x + Tailwind v4 + TypeScript estrito) com seus padrões de código obrigatórios.
- Uma **pipeline de qualidade e segurança** (testes em pirâmide, checklists de release, runbook de deploy).

Tudo orientado a um objetivo: **delegar com segurança partes do trabalho a agentes de IA, sem perder controle, sem alucinação acumulada, sem dívida técnica invisível**.

---

## 2. Princípios arquiteturais

Doze princípios sustentam todas as decisões deste harness. Quando algo parecer arbitrário, é porque deriva de um destes. P1–P5 são os fundamentos originais; P6–P9 vêm da análise Zhou et al. 2026 (externalização cognitiva); P10–P11 vêm da análise Li et al. 2025 (DeepCode); P12 vem da análise Ning et al. 2026 (Code as Agent Harness).

### P1 — Documento antes de código

Cada fase produz um artefato versionado em `docs/` que é a fonte de verdade para a fase seguinte. O agente nunca codifica a partir de um chat efêmero — ele codifica a partir de um documento aprovado.

### P2 — Contexto mínimo viável

Nenhum agente recebe mais informação do que precisa para sua tarefa. O custo do excesso de contexto não é só financeiro: é **degradação de qualidade**. Modelos diluem foco e começam a alucinar quando sobrecarregados. Por isso, o documento **`05-execution/00-context-protocol.md`** define quatro camadas de memória com regras estritas de transição.

### P3 — Artifacts, não prosa

A revisão humana acontece sobre **Artifacts** (o conceito nativo do Antigravity: planos, diffs, gravações, screenshots), não sobre logs de tool calls. O agente principal é responsável por consolidar evidência verificável em segundos, não em parágrafos.

### P4 — Humano no loop por padrão

O modo default é `agent-assisted`. `agent-driven` só é liberado quando há track record de confiança naquele tipo específico de tarefa, registrado em ADR. Tarefas com dinheiro, autenticação, dados pessoais ou deploy nunca migram para `agent-driven`.

### P5 — Sandbox sempre

Terminal Sandbox ligado, escopo restrito ao workspace, allowlist explícita de comandos. O agente não rasga o repositório nem o sistema de arquivos por engano.

### P6 — Externalização não é gratuita (Zhou et al. 2026, §8.4)

Cada camada adicional de memória, schema ou regra impõe latência e overhead de raciocínio. Além de certo ponto, o modelo gasta mais esforço parseando e coordenando módulos do que resolvendo a tarefa. Toda adição ao harness deve passar pelo teste: *reduz o burden cognitivo do agente, ou apenas adiciona mais um?* Detalhe em [`00-paper-analysis.md`](00-paper-analysis.md) §2.

### P7 — Recall vira Recognition (Zhou et al. 2026, §3.4)

A transformação representacional converte um problema interno de recall em um problema externo de recognition-and-retrieval. Todo template do harness é desenhado para que o agente **reconheça** uma estrutura conhecida, não para que **reescreva** a estrutura do zero. Essa é a justificativa de existir dos templates de PRD, ADR, story, spec etc.

### P8 — Os módulos competem pelo context window (Zhou et al. 2026, §7.1)

Memory retrieval, skill loading e protocol schemas ocupam tokens. Expandir um módulo necessariamente comprime os outros. O "bootstrap mínimo" não é uma checklist passiva — é uma decisão **calculada** de orçamento de contexto por story.

### P9 — A fronteira parametric/externalizado é móvel (Zhou et al. 2026, §7.3, §8.1)

Quando modelos amadurecem, a partição ótima entre o que está nos pesos e o que está externalizado muda. Decisões de externalização (ex.: "use Zod sempre") são revisadas anualmente em sprint de saúde do harness, não tratadas como permanentes.

### P10 — Maximização do Signal-to-Noise Ratio (Li et al. 2025, §3)

Sucessor preciso de P2. Todo template, regra ou gate responde a uma pergunta única: *isso aumenta o SNR no contexto do agente, ou adiciona ruído?* P2 fala em volume; P10 fala em densidade — é o critério operacional ao escrever templates e revisar `AGENTS.md`.

### P11 — Roteamento hierárquico > escala de contexto (Li et al. 2025, §1)

Quando o agente está "perdido", a resposta default não é dar mais contexto nem trocar para um modelo maior. É **rotear melhor** a informação que já existe: bootstrap mais seletivo, índice hierárquico (cf. `spec-fetch.sh`, `codemap/`), recorte por dependência. O harness escala roteando, não inflando.

### P12 — As quatro propriedades-alvo (Ning et al. 2026, §5.2.7)

Todo componente do harness — template, script, regra, ritual — serve a pelo menos uma de quatro propriedades: **executável**, **inspecionável**, **stateful**, **governado**. Componente que não serve a nenhuma é candidato a remoção (corolário do P6). As quatro propriedades funcionam como checklist na auto-revisão semestral do harness.

---

## 3. Topologia do harness

```
                          ┌────────────────────────────────────┐
                          │           HUMANO (você)            │
                          │     PM/arquiteto/release manager   │
                          └────────────────┬───────────────────┘
                                           │
                                           │ define objetivo, aprova Artifacts
                                           ▼
        ┌──────────────────────────────────────────────────────────────────┐
        │              GOOGLE ANTIGRAVITY  —  Mission Control              │
        │                                                                  │
        │  ┌─────────────────┐      ┌─────────────────┐                    │
        │  │  Editor View    │      │  Agent Manager  │                    │
        │  │  (síncrono)     │      │  (paralelo)     │                    │
        │  └─────────────────┘      └─────────────────┘                    │
        │                                                                  │
        │  ┌──────────────────────────────────────────────────────────┐    │
        │  │              AGENTE PRINCIPAL (por workspace)            │    │
        │  │  lê: AGENTS.md + docs/ + story atual                     │    │
        │  └─────────────┬─────────────┬───────────────┬──────────────┘    │
        │                │             │               │                   │
        │     ┌──────────▼───┐  ┌──────▼─────────┐ ┌───▼──────────────┐    │
        │     │ Browser sub. │  │ Subagente      │ │ Subagente em     │    │
        │     │ (validação   │  │ paralelo       │ │ workspace        │    │
        │     │  visual)     │  │ (mesmo ws)     │ │ separado         │    │
        │     └──────────────┘  └────────────────┘ └──────────────────┘    │
        │                                                                  │
        │  ┌──────────────────────────────────────────────────────────┐    │
        │  │             KNOWLEDGE BASE (long-term)                   │    │
        │  │  padrões aprovados · ADRs accepted · snippets            │    │
        │  └──────────────────────────────────────────────────────────┘    │
        └──────────────────────────────────────────────────────────────────┘
                                           │
                                           ▼
        ┌──────────────────────────────────────────────────────────────────┐
        │                 REPOSITÓRIO  (source of truth)                   │
        │                                                                  │
        │  AGENTS.md  ←  rules globais lidas pelos agentes                 │
        │  docs/                                                           │
        │    discovery/ · prd/ · spec/ · adr/ · sprints/                   │
        │    memory/   · runbooks/                                         │
        │  app/ · components/ · lib/ · tests/                              │
        │  proxy.ts  ·  app/globals.css (Tailwind v4)                      │
        └──────────────────────────────────────────────────────────────────┘
                                           │
                                           ▼
        ┌──────────────────────────────────────────────────────────────────┐
        │                       CI / CD pipeline                           │
        │  typecheck · lint · unit · integration · e2e · a11y · perf       │
        │  audit · gitleaks · SAST · build · staging · canary · prod       │
        └──────────────────────────────────────────────────────────────────┘
```

Três planos coexistem:

1. **Plano humano** (topo): você define objetivo, aprova Artifacts, autoriza release.
2. **Plano agêntico** (Antigravity): orquestra agente principal, subagentes, browser subagent e Knowledge Base.
3. **Plano de produção** (repositório + pipeline): código versionado, CI, deploy auditável.

A interação entre os planos é **mediada por documentos**, nunca por chat efêmero.

---

## 4. As oito fases — fluxo macro

```
   Discovery ──► PRD ──► Design ──► Spec ──► Sprint ──► Execução ──► Testes ──► Deploy
      │           │     Foundations  │         │           │           │          │
      │           │       │          │         │           │           │          │
      ▼           ▼       ▼          ▼         ▼           ▼           ▼          ▼
   brief +     PRD +    paleta +  Tech Spec  Sprint     código +    suíte de    runbook
   canvas     glossário  tokens +  + ADRs     plan      Artifacts   testes      executado
              aprovado   starter             + stories                          + smoke
                         kit
```

Cada seta é um **gate**. Você não passa para a próxima fase sem o artefato da anterior aprovado. Cada gate dispara o **ritual de limpeza de contexto** descrito no protocolo, materializado em `docs/memory/<fase>/_summary.md` (template em [`05-execution/05-phase-summary-template.md`](05-execution/05-phase-summary-template.md)).

**Design Foundations** (fase 02.5) entra entre PRD e Spec sempre que o produto tem UI. Tailwind v4 com `@theme` em `globals.css` exige tokens definidos antes do primeiro componente; refazer paleta depois é caro porque cada Shadcn já consumiu os tokens errados. Detalhe completo em [`02b-design/00-design-foundations.md`](02b-design/00-design-foundations.md).

### 4.1 Discovery (fase 01)

**Objetivo:** descobrir se o problema vale a pena, antes de gastar 1 linha de código.

**Inputs:** intuição, dor de usuário relatada, dados, conversas.

**Outputs:** `01-discovery/00-discovery-brief.md` preenchido + `01-opportunity-canvas.md`.

**Quem trabalha:** humano em diálogo com 1 agente. **Sem subagentes.** Modo conversacional, divergente.

**Critério de saída:** sponsor aprova o problema, hipótese e métrica de sucesso. Se o veredito é "no-go", o documento fica arquivado com a lição aprendida — isso também é entrega.

### 4.2 PRD (fase 02)

**Objetivo:** definir **o que** o produto faz e **para quem**, com critérios verificáveis.

**Inputs:** discovery aprovado.

**Outputs:** `02-prd/00-prd-template.md` preenchido com user stories, critérios Given/When/Then, requisitos não-funcionais, métricas, plano de lançamento.

**Quem trabalha:** humano + 1 agente. Mesmo agente da discovery? **Não** — sessão nova, contexto limpo, mindset convergente.

**Critério de saída:** todos os critérios de aceite são observáveis e binarizáveis. Aprovação dos stakeholders listados. **Glossário** (`docs/prd/01-glossary.md`) preenchido com todo termo de domínio que aparece no PRD — vira input do bootstrap mínimo de toda story.

### 4.2.5 Design Foundations (fase 02.5)

**Objetivo:** travar identidade visual, tokens de design e princípios de UX **antes** de qualquer componente Shadcn ser implementado. Tailwind v4 com `@theme` em `globals.css` exige tokens definidos antes do primeiro componente.

**Inputs:** PRD aprovado + brand assets (logo, referências visuais).

**Outputs:** `docs/spec/01-design-system.md` + bloco `@theme` em `app/globals.css` + screenshot do starter kit (botões, inputs, cards, modal, tipografia, swatches) gerado via browser subagent.

**Quem trabalha:** designer (se houver) ou eng lead + 1 agente. Browser subagent para validar starter kit.

**Critério de saída:** aprovação visual humana sobre o screenshot do starter kit. Sem isso, nenhuma story de UI da Sprint 01 entra em execução.

**Quando pular:** produto sem UI (CLI, lib, daemon). Mesmo assim, registre a decisão de pular no `_summary.md` da fase para auditoria.

Detalhe completo em [`02b-design/00-design-foundations.md`](02b-design/00-design-foundations.md).

### 4.3 Spec (fase 03)

**Objetivo:** traduzir o PRD em arquitetura, contratos e decisões técnicas.

**Inputs:** PRD aprovado.

**Outputs:** `03-spec/00-tech-spec.md` + N arquivos `adr/NNNN-*.md`, um por decisão importante.

**Quem trabalha:** eng lead + 1 agente. Subagente paralelo só se houver ADRs ortogonais a redigir.

**Critério de saída:** stack travada, modelo de domínio definido, contratos das Server Actions especificados, ADRs aprovados.

**Estrutura obrigatória — 5 seções canônicas (Li et al. 2025, DeepCode §2.1):** toda Tech Spec abre com um Implementation Blueprint contendo cinco seções nomeadas: (B1) Project File Hierarchy, (B2) Component Specification, (B3) Verification Protocol, (B4) Execution Environment, (B5) Staged Development Plan. Detalhe em [`03-spec/00-tech-spec.md`](03-spec/00-tech-spec.md) §0.

### 4.4 Sprint planning (fase 04)

**Objetivo:** quebrar o escopo aprovado em unidades de trabalho cabíveis.

**Inputs:** PRD + Spec.

**Outputs:** `04-sprints/<n>/sprint-plan.md` + N stories no template `01-story-template.md`.

**Quem trabalha:** time + 1 agente. O agente sugere quebra; humanos validam DoR.

**Critério de saída:** stories no tamanho M ou menor, com critérios de aceite, mapa de workspaces e atribuição de agentes.

### 4.5 Execução (fase 05)

**Objetivo:** transformar story em código mergeado.

**Inputs:** uma story por vez.

**Outputs:** PR com código, testes, screenshots, log em `docs/memory/execution/`.

**Quem trabalha:** 1 agente principal por story + browser subagent quando há UI. Eventualmente subagente em workspace separado para tarefas ortogonais.

**Critério de saída:** DoD satisfeito (typecheck, lint, testes, revisão humana, deploy em staging).

**Particularidade:** cada story é uma **sessão nova** do agente. Não se arrasta contexto entre stories. Veja o protocolo na seção 6.

### 4.6 Qualidade (fase 06)

A fase 06 não é sequencial — ela é **transversal**. Testes nascem na fase 05 (TDD para domínio, test-after para UI) e a estratégia em `06-testing/00-testing-strategy.md` é o contrato que toda story respeita.

**Outputs específicos da fase:** suíte E2E cobrindo P0 do PRD, configuração de Lighthouse CI, gates de cobertura no pipeline, testes de a11y automatizados.

#### Critério de convergência do harness — nomeado

O harness usa **correctness convergence** (Ning et al. 2026, §4.3.2): a Sprint converge quando gates objetivos passam em ambiente limpo, não quando o agente julga "está pronto". O sinal operacional é o `## Smoke Run` verde em [`docs/memory/sprints/<N>/_summary.md`](05-execution/05-phase-summary-template.md) ao fechar a sprint.

Por que nomeamos? Os papers listam 6 critérios de convergência observados em harnesses reais: (1) correctness (test-gated), (2) consensus (multi-agent agree), (3) coverage (exhaustive enumeration), (4) budget (token/time cap), (5) explicit (human stop), (6) implicit (loop terminates after N iterations without criterion). O pior é o (6) — parar sem critério objetivo, comum em loops execution-error-fix. Adotamos (1) e, para gates HITL, (5). Recusamos (6) por design.

Anti-padrão concreto: `_summary.md` declarado verde sem Smoke Run reproduzível é convergência implícita disfarçada de correctness.

### 4.7 Deploy (fase 07)

**Objetivo:** levar a versão a produção de forma reversível.

**Inputs:** main com CI verde + smoke em staging.

**Outputs:** versão em produção + log em `docs/memory/deploys/`.

**Quem trabalha:** release manager humano executa o runbook. Agente **não** faz deploy em produção; pode preparar release notes e rodar smoke em staging.

**Critério de saída:** canário promovido para 100%, smoke pós-deploy verde, sem alertas em 1h.

---

## 5. As quatro camadas de memória

Este é o pedaço mais importante da arquitetura. Repete-se aqui o que está em `05-execution/00-context-protocol.md`, com foco em **por quê**.

```
┌──────────────────────────────────────────────────────┐
│  Camada 1: Knowledge Base (Antigravity)              │  long-term, atemporal
│  Decisões e padrões que valem para sempre.           │
├──────────────────────────────────────────────────────┤
│  Camada 2: Repositório (AGENTS.md + docs/)           │  source of truth versionado
│  Tudo que entra em PR e tem histórico git.           │
├──────────────────────────────────────────────────────┤
│  Camada 3: Logs de fase (docs/memory/<fase>/)        │  resumos auditáveis
│  Resumo final da sessão, não o log cru.              │
├──────────────────────────────────────────────────────┤
│  Camada 4: Context window do agente                  │  efêmero, descartável
│  O recorte mínimo da tarefa atual.                   │
└──────────────────────────────────────────────────────┘
```

**Por que quatro camadas e não uma só?**

Porque cada camada tem custo diferente e propósito diferente:

- **Camada 1** é cara de manter (cura humana) e barata de consultar. Boa para o que é estável.
- **Camada 2** é a fonte de verdade legal — entra em git, entra em revisão, entra em ADR.
- **Camada 3** existe para responder "o que aconteceu na sessão de ontem" sem reabrir o histórico inteiro do chat.
- **Camada 4** é volátil por design. Se ela sobrevive entre sessões, você está fazendo errado.

**A regra-mãe:** quando você passa de fase ou de story, **encerre a sessão do agente**. Comece nova. A Camada 4 zera. Camadas 1, 2 e 3 carregam o que importa.

### 5.1 CodeMem como índice estrutural da Camada 2

A Camada 2 (`docs/`) hoje contém Tech Spec (decisão arquitetural) e
`_summary.md` por fase (narrativa). Falta uma terceira granularidade: a
**interface pública por módulo** — quem expõe o quê, quem consome. Esse é
o CodeMap (`docs/memory/codemap/`).

Ele move o harness do nível "implicit/file-only" para "repository-based"
na taxonomia de substrato de Ning et al. 2026 §4 — o gap que mais aparece
em ablation de Li et al. 2025 (>2× em scores com dependências cruzadas).

**Como se diferencia de `_summary.md`:** `_summary.md` é narrativo ("o que
aconteceu na fase"); codemap é estrutural ("qual a forma do código hoje").
Não se substituem. Protocolo:
[`05-execution/10-codemem-protocol.md`](05-execution/10-codemem-protocol.md).

---

## 6. O ciclo de uma story (fluxo zoom-in)

```
   ┌───────────────────────────────────────────────────────────┐
   │  HUMANO seleciona story do sprint plan                    │
   └────────────────────────┬──────────────────────────────────┘
                            │
                            ▼
   ┌───────────────────────────────────────────────────────────┐
   │  Nova sessão do AGENTE PRINCIPAL                          │
   │  Bootstrap mínimo:                                        │
   │    1. AGENTS.md (raiz)                                    │
   │    2. tech-spec — apenas seção do módulo afetado          │
   │    3. ADRs aplicáveis ao módulo                           │
   │    4. story.md atual                                      │
   │    5. arquivos do código que o plano vai tocar            │
   └────────────────────────┬──────────────────────────────────┘
                            │
                            ▼
   ┌───────────────────────────────────────────────────────────┐
   │  AGENTE produz PLAN ARTIFACT                              │
   │  Lista arquivos, passos, dependências, subagentes         │
   └────────────────────────┬──────────────────────────────────┘
                            │
                            ▼
   ┌───────────────────────────────────────────────────────────┐
   │  HUMANO revisa o plano (gate 1)                           │
   │  Aprovado? ──► segue                                      │
   │  Rejeitado? ──► volta a refinar                           │
   └────────────────────────┬──────────────────────────────────┘
                            │
                            ▼
   ┌───────────────────────────────────────────────────────────┐
   │  AGENTE executa passo a passo                             │
   │  A cada passo:                                            │
   │    • implementa                                           │
   │    • roda typecheck + lint + test:unit                    │
   │    • se UI: invoca browser subagent + screenshot          │
   │  Pausa em dúvidas relevantes                              │
   └────────────────────────┬──────────────────────────────────┘
                            │
                            ▼
   ┌───────────────────────────────────────────────────────────┐
   │  AGENTE entrega ARTIFACT FINAL                            │
   │  Sumário · arquivos alterados · como testar · riscos      │
   └────────────────────────┬──────────────────────────────────┘
                            │
                            ▼
   ┌───────────────────────────────────────────────────────────┐
   │  HUMANO revisa diff (gate 2)                              │
   │  PR aprovado e mergeado                                   │
   └────────────────────────┬──────────────────────────────────┘
                            │
                            ▼
   ┌───────────────────────────────────────────────────────────┐
   │  AGENTE escreve log em docs/memory/execution/             │
   │  Sessão é ENCERRADA                                       │
   │  Padrões reutilizáveis viram Knowledge Base               │
   └───────────────────────────────────────────────────────────┘
```

Dois gates humanos por story (plano e diff). Dois cleanups de contexto (entrada e saída). Resultado: rastreabilidade total e contexto sempre fresco.

---

## 7. O fluxo de delegação a subagentes

A heurística é simples: **delegação tem custo de coordenação**. Você só delega quando o ganho de paralelismo supera esse custo.

```
              "Tenho uma tarefa para o agente"
                          │
                          ▼
              ┌───────────────────────┐
              │ Cabe em 1 sessão?     │── sim ──► 1 AGENTE, sem subagentes
              └──────────┬────────────┘
                         │ não
                         ▼
              ┌───────────────────────┐
              │ Tem componente de UI  │── sim ──► + BROWSER SUBAGENT
              │ a validar?            │           para validação visual
              └──────────┬────────────┘
                         ▼
              ┌───────────────────────┐
              │ As subtarefas tocam   │── sim ──► 1 AGENTE sequencial
              │ arquivos sobrepostos? │           (paralelizar = merge hell)
              └──────────┬────────────┘
                         │ não
                         ▼
              ┌───────────────────────┐
              │ As subtarefas são     │── sim ──► WORKSPACES SEPARADOS
              │ ortogonais (ex: docs  │           via Agent Manager
              │ + testes)?            │
              └──────────┬────────────┘
                         │ não
                         ▼
                Default: 1 AGENTE, sequencial
```

**Regra de ouro:** o default é não delegar. Delegação é uma decisão consciente, não automática.

Para o briefing de cada subagente, há um template em `05-execution/01-subagent-delegation.md` com quatro campos: objetivo, pronto-quando, não-faça, leia-apenas. Sem isso, o subagente vira um agente tradicional que come o contexto inteiro.

---

## 8. Como o `AGENTS.md` se conecta a tudo

`AGENTS.md` é o arquivo mais importante do repositório, depois do código em si. Ele:

- É **lido automaticamente** pelo Antigravity, Claude Code, Codex, Cursor (convenção da indústria desde fim de 2025).
- É a **maior autoridade** em conflitos com instruções de chat.
- É **versionado** em git como qualquer outro arquivo — alterações passam por PR.
- É **enxuto** (alvo: ~200 linhas) — um agente lê em < 10 segundos.

Funções:

```
┌──────────────────────────────────────────┐
│ AGENTS.md                                │
├──────────────────────────────────────────┤
│ identidade do agente                     │  ← "você é um eng sênior"
│ modo de operação (agent-assisted)        │  ← evita autonomia indevida
│ allowlist de comandos                    │  ← evita rm -rf surpresa
│ stack obrigatória                        │  ← Next 16, Tailwind v4
│ padrões de código                        │  ← Server Components default
│ gates antes de modificar                 │  ← Plan Artifact obrigatório
│ gates antes de commit                    │  ← typecheck/lint/test
│ regras de secrets                        │  ← nunca lê .env em chat
│ quando parar e perguntar                 │  ← critérios ausentes, $$, auth
│ regras de memória                        │  ← Knowledge Base curada
│ formato de output                        │  ← sumário 5 linhas, riscos, próximo passo
└──────────────────────────────────────────┘
```

Quando uma rule do `AGENTS.md` ficar obsoleta, a alteração passa por **PR** — porque mudar a regra do jogo precisa de revisão humana. Não se altera por chat.

---

## 9. Como a stack escolhida apoia o fluxo

A stack não foi escolhida só por "ser moderna". Cada peça apoia o fluxo agêntico:

**Next.js 16.2+** — tem `AGENTS.md` nativo no `create-next-app`, browser log forwarding (erros do browser vão direto para o terminal do agente), Cache Components com `"use cache"` explícito (sem caching mágico que confunde o agente), `proxy.ts` substituindo `middleware.ts` (nome menos ambíguo), e MCP devtools experimentais.

**Tailwind v4** — config CSS-first via `@theme` em `globals.css`. Sem `tailwind.config.js`. **Um arquivo a menos** para o agente confundir, e tokens de design ficam na mesma camada do CSS (mais previsível ao gerar UI).

**TypeScript estrito** — o compilador é o primeiro revisor do agente. Sem `any`, sem implicit. Quando o agente erra, o tipo grita antes do humano ler.

**Server Components + Server Actions** — menos cerimônia, menos boilerplate, menos chance do agente inventar API routes desnecessárias. Validação Zod na borda em toda action é regra inegociável.

**Vitest + Playwright + axe** — feedback rápido em três escalas. O agente sabe se errou em segundos (unit), em minutos (integration), em < 5 min (E2E completo).

**pnpm** — lockfile estável e mais rápido; comportamento mais previsível em CI.

---

## 10. Como o pipeline traduz o harness em garantia

```
   Push em PR
        │
        ▼
   ┌─────────────────────┐
   │ quality job         │  typecheck · lint · unit · audit · gitleaks
   └──────────┬──────────┘
              │ paralelo
              ▼
   ┌─────────────────────┐
   │ integration job     │  Server Actions contra Postgres efêmero
   └──────────┬──────────┘
              │
              ▼
   ┌─────────────────────┐
   │ e2e job             │  Playwright em build de produção
   └──────────┬──────────┘
              │
              ▼
   ┌─────────────────────┐
   │ lighthouse job      │  performance + a11y budgets
   └──────────┬──────────┘
              │
              ▼
   Merge para main ──► auto-deploy em staging
              │
              ▼
   Tag vX.Y.Z ──► canário 10% ──► observação 10min ──► 100% ou rollback
```

Cada gate do pipeline corresponde a uma garantia que o harness promete:

- `typecheck` valida o **AGENTS.md sobre tipos**.
- `unit + integration` valida a **estratégia de testes**.
- `e2e` valida os **critérios de aceite do PRD**.
- `lighthouse` valida os **budgets de performance da Spec**.
- `audit + gitleaks + SAST` valida a **checklist de segurança**.
- `canário` valida o **runbook de deploy**.

Se um gate falha, o agente **não pode** declarar a tarefa pronta. O humano **não pode** mergear. Não há atalho.

**Deep telemetry** (Ning et al. 2026, §3.5.1) é o substrato de
observabilidade do próprio harness. Eventos estruturados em
[`docs/memory/telemetry.jsonl`](05-execution/11-telemetry-protocol.md) —
plan_submitted, plan_rejected, gate_failed, story_closed, etc. — alimentam
métricas agregáveis (taxa de plan-rejection, tempo Plan→Diff, distribuição
de falhas por gate). Sem isso, a revisão do harness é *anecdotal
debugging*; com isso, vira *comparative diagnosis*. Coexiste com o log
narrativo `docs/memory/execution/*.md` (que é para humanos lerem); a
telemetria é para agregar.

---

## 11. O que cada papel faz no harness

| Papel | O que produz | O que aprova | O que nunca faz |
|-------|--------------|--------------|------------------|
| **Sponsor** | direção estratégica | go/no-go de discovery, GA | escolhe stack |
| **Product owner** | discovery, PRD | escopo de sprint | define arquitetura |
| **Eng lead** | tech spec, ADRs | arquitetura, releases | merge sem revisão |
| **Dev / contribuidor** | stories, código, testes | PR de outros | push em main direto |
| **Release manager** | runbook, release notes | promoção a prod | bypass do CI |
| **Agente principal** | plan artifact, código, log de sessão | nada | deploy em prod, push, secrets |
| **Browser subagent** | screenshots, smoke visual | nada | edição de código |
| **Subagente paralelo** | artefato escopado, contido | nada | tocar fora do briefing |

A coluna mais importante é **"o que nunca faz"**. É o que define os limites do harness.

---

## 12. Como o harness evolui

Este harness não é estático. Ele evolui sob as mesmas regras que governa:

1. **Mudanças de stack ou padrão obrigatório** → ADR.
2. **Mudanças no `AGENTS.md`** → PR com revisão.
3. **Novos templates ou checklists** → contribuição via PR.
4. **Lições aprendidas em retro** → entram no canvas da próxima sprint, e em casos relevantes, sobem para `docs/memory/<fase>/_summary.md` ou para a Knowledge Base.

Sinais de que o harness precisa de revisão:

- O agente está repetidamente quebrando uma rule que não está clara.
- Uma fase está consistentemente atrasando o release.
- Um template está sendo ignorado porque "não cabe".
- Subagentes estão sendo subutilizados ou superutilizados.
- A taxa de retrabalho de plano-rejeitado está alta.

Trate qualquer um desses sinais como dívida do harness e abra story para resolver na sprint de "saúde de processo".

---

## 13. Anti-padrões que o harness existe para impedir

Estes são os erros recorrentes que motivaram cada peça:

| Anti-padrão | O que acontece | O harness evita via |
|-------------|----------------|---------------------|
| "Vou só prototipar primeiro" | protótipo vira produção, sem testes | gates de DoR/DoD |
| "Cole o repo inteiro no chat" | contexto saturado, alucinação | bootstrap mínimo |
| "Deixa o agente decidir a arquitetura" | decisão sem revisão, sem rastro | ADR obrigatório |
| "Vou rodar 5 agentes em paralelo" | merge hell, retrabalho | matriz de delegação |
| "Salva tudo na memória" | Knowledge Base poluída | curadoria explícita |
| "Push direto em prod, é só um patchzinho" | incidente | runbook + canário |
| "Esse secret eu coloco no .env.example só pra exemplo" | vazamento | `gitleaks` + checklist |
| "Esse warning de typecheck depois eu vejo" | bug em prod | gate de CI |
| "O agente escreveu, então deve estar certo" | regressão silenciosa | gates de testes + revisão |

---

## 14. Resumo em uma frase

> **O harness é um conjunto de documentos e protocolos que transforma agentes de IA em colaboradores rastreáveis: contexto recortado, decisões versionadas, código auditado e deploy reversível, com humano nos gates certos.**

Se em algum momento o trabalho começar a parecer mais lento por causa do harness, **provavelmente está**. E é proposital — a velocidade que importa é a de **shipping seguro recorrente**, não a de pull request individual.

---

## 15. Onde ir agora

| Você é... | Leia em seguida |
|-----------|-----------------|
| Novo no projeto | `README.md` → `AGENTS.md` → `05-execution/00-context-protocol.md` |
| Vai começar produto novo | `01-discovery/00-discovery-brief.md` + `01-discovery/02-elicitation-guide.md` |
| Vai conduzir entrevista de discovery | `01-discovery/02-elicitation-guide.md` |
| Vai escrever PRD | `02-prd/00-prd-template.md` + `02-prd/01-glossary-template.md` |
| Vai definir design system | `02b-design/00-design-foundations.md` |
| Vai modelar domínio (DDD tático) | `03-spec/02-domain-model.md` (pré-requisito: `02-prd/01-glossary-template.md`) |
| Vai desenhar arquitetura | `03-spec/00-tech-spec.md` + `01-adr-template.md` |
| Vai planejar sprint | `04-sprints/00-sprint-plan.md` + `01-story-template.md` |
| Vai implementar story | `05-execution/02-nextjs-conventions.md` + `05-execution/06-plan-artifact-template.md` |
| Vai mexer em schema/migration | `05-execution/07-migration-checklist.md` |
| Vai fechar uma fase | `05-execution/05-phase-summary-template.md` |
| Vai delegar a subagente | `05-execution/01-subagent-delegation.md` |
| Vai escrever testes | `06-testing/00-testing-strategy.md` |
| Vai fazer release | `07-deploy/00-deploy-runbook.md` + `01-security-checklist.md` |
