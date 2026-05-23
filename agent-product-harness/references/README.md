# Harness de Desenvolvimento de Produto

Processo end-to-end para desenvolver produtos de software com **Google Antigravity** como IDE agêntica, **Next.js 16.x** + **Tailwind v4** no frontend, e disciplina rígida de contexto e delegação a subagentes.

---

## Filosofia

1. **Documento antes de código.** Cada fase produz um artefato versionado em `/docs` que serve de fonte de verdade para os agentes.
2. **Contexto mínimo viável.** Cada subagente recebe **apenas** o que precisa para sua tarefa. Cleanup obrigatório entre fases.
3. **Artifacts > prosa.** Aproveite o sistema de Artifacts do Antigravity (planos, diffs, gravações, screenshots) para revisar trabalho sem ler tool calls crus.
4. **Humano no loop por padrão.** Comece em modo *agent-assisted* ou *review-driven*; só promova para *agent-driven* tarefas comprovadamente seguras.
5. **Sandbox sempre ligado.** Terminal Sandbox + escopo de workspace é não negociável.

---

## Mapa de Fases

| # | Fase | Documento principal | Saída esperada |
|---|------|---------------------|----------------|
| 01 | **Discovery** | `01-discovery/00-discovery-brief.md` + `02-elicitation-guide.md` | Problema validado, hipóteses, métricas |
| 02 | **PRD** | `02-prd/00-prd-template.md` + `01-glossary-template.md` | Escopo, requisitos, critérios de aceite, glossário |
| 02.5 | **Design Foundations** | `02b-design/00-design-foundations.md` | Paleta, tokens `@theme`, starter kit visual |
| 03 | **Spec** | `03-spec/00-tech-spec.md` + ADRs | Arquitetura, contratos, decisões |
| 04 | **Sprints** | `04-sprints/00-sprint-plan.md` | Backlog priorizado, stories quebradas |
| 05 | **Execução** | `05-execution/00-context-protocol.md` | Código + memória limpa por fase |
| 06 | **Qualidade** | `06-testing/00-testing-strategy.md` | Cobertura unitária + E2E + segurança |
| 07 | **Deploy** | `07-deploy/00-deploy-runbook.md` | Pipeline auditado e reversível |

Documentos transversais à fase de Execução:

- `05-execution/01-subagent-delegation.md` — quando delegar a subagente.
- `05-execution/02-nextjs-conventions.md` — convenções específicas deste harness (delega padrões oficiais à skill `next-best-practices`).
- `05-execution/03-protocols.md` — MCP, Server Actions, webhooks, prep para A2A.
- `05-execution/04-skill-template.md` — template de skill interna (`skills/`).
- `05-execution/05-phase-summary-template.md` — `_summary.md` por fase, gate de transição.
- `05-execution/06-plan-artifact-template.md` — Plan Artifact obrigatório (Gate 1) antes de tocar código.
- `05-execution/07-migration-checklist.md` — schema, RLS, triggers, seeds — gate de PR para qualquer story que mexa em DB.

Gates de coerência da spec (filosofia Spec-Driven Development):

- `03-spec/07-clarify-protocol.md` — marcadores `[NEEDS CLARIFICATION]`; gate anti-ambiguidade antes do planejamento (SDD `/clarify`).
- `03-spec/08-constitution.md` — `docs/memory/constitution.md`, lei de qualidade não-negociável do produto (SDD constitution).
- `04-sprints/06-cross-artifact-analysis.md` — coerência entre Constitution/PRD/Spec/Stories antes da Execução (SDD `/analyze`).

---

## Como usar com Antigravity

1. **Crie um workspace por produto.** Ideal: 1 agente por workspace para evitar conflito de arquivos.
2. **Coloque `AGENTS.md` na raiz do repositório.** É o arquivo que o Antigravity (e o `create-next-app` 16.2+) lê automaticamente como rules globais.
3. **Use Planning Mode para tarefas complexas.** Force o agente a produzir um Plan Artifact antes de tocar em código.
4. **Use o Agent Manager (Mission Control) para paralelizar fases ortogonais.** Ex.: subagente A escrevendo testes enquanto subagente B refina a UI — em workspaces separados.
5. **Knowledge Base é seu *long-term memory*.** Salve nela: ADRs aprovados, padrões de código validados, comandos recorrentes. Não salve secrets, nem trechos de PRD ainda em discussão.
6. **Limpe o contexto entre fases.** Veja `05-execution/00-context-protocol.md`.

---

## Stack de referência

- **Frontend:** Next.js 16.2+ (App Router, Server Components, Server Actions, Cache Components com `"use cache"`, Turbopack default).
- **Estilo:** Tailwind v4 (configuração CSS-first via `@theme`, sem `tailwind.config.js`).
- **Tipagem:** TypeScript estrito em todo o projeto.
- **Runtime:** Node.js LTS atual.
- **Testes:** Vitest (unit) + Playwright (E2E) + Testing Library (componentes).
- **Lint/Format:** Biome ou ESLint + Prettier (escolher uma e travar via ADR).
- **Pacote:** pnpm (lockfile commitado).

---

## Convenções de pastas no repositório

```text
/
├── AGENTS.md                  ← rules globais p/ Antigravity (e demais agentes)
├── docs/
│   ├── discovery/
│   ├── prd/
│   │   └── 01-glossary.md     ← vocabulário canônico (carregado em toda story)
│   ├── spec/
│   │   ├── 01-design-system.md ← output da fase Design Foundations
│   │   └── adr/               ← obrigatório no scaffold
│   ├── sprints/
│   │   └── 01/
│   │       ├── sprint-plan.md
│   │       └── <story-id>.md
│   ├── memory/                ← logs de sessão por fase (ver 05-execution)
│   │   ├── discovery/_summary.md
│   │   ├── prd/_summary.md
│   │   ├── spec/_summary.md
│   │   ├── sprints/_summary.md
│   │   ├── execution/<YYYY-MM-DD>-<story-id>.md
│   │   └── deploys/
│   └── runbooks/
├── app/                       ← Next.js App Router
├── components/
├── lib/
├── tests/
│   ├── unit/
│   └── e2e/
└── .github/workflows/
```

---

## Ordem de leitura recomendada

Antes de iniciar qualquer projeto novo, leia nesta ordem:

1. `AGENTS.md` (raiz) — entender as rules de execução
2. `05-execution/00-context-protocol.md` — entender como o contexto vai ser gerenciado
3. `05-execution/01-subagent-delegation.md` — entender quando delegar
4. As demais fases conforme o produto avança
