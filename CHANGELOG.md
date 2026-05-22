# Changelog

All notable changes to the **agent-product-harness** skill are documented in
this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
this project adheres to a semver-ish scheme at the **skill** level — see
[README.md §Versioning](./README.md#versioning).

---

## [v0.3] — 2026-05-21

> Governança e refinamentos: permissão em três tiers, HITL como estado
> durável, evolução do harness com Change Contract obrigatório, e
> opt-ins (CodeRAG, Multi-Agent Spec) para produtos que se beneficiam.

### Added

- **Permission model em três tiers** (`read-only` / `sandbox-edit` /
  `full-access`) — Ning et al. 2026, §3.4.3. Context-sensitive: o mesmo
  comando muda de tier conforme argumento e ambiente. Toda ação
  full-access exige HITL.
  - `references/05-execution/12-permission-tiers.md`
  - `validate.sh` falha se `AGENTS.md` do produto não declara as três
    seções de allowlist por tier.
- **Change Contract** — toda mudança `minor`/`major` no harness carrega
  6 campos (componente, modo de falha, melhoria, invariantes,
  falsificação, rollback). `patch` PRs dispensam.
  - `.github/PULL_REQUEST_TEMPLATE/harness-change.md`
  - `references/12-harness-evolution/00-change-contract.md`
- **Multi-Agent Specification Analysis** (Concept + Algorithm split)
  para produtos M+ na fase Spec — Li et al. 2025, DeepCode §2.1.
  Reconciliação humana (eng lead) com conflitos virando ADRs.
  - `references/05-execution/01-subagent-delegation.md` ganha seção
    dedicada com os dois briefings.
- **Evidence Bundle** no Final Artifact (Gate 2) — checks rodados,
  invariantes preservadas, **regiões NÃO testadas** (obrigatório),
  riscos remanescentes — Ning et al. 2026, §5.2.2.
  - `references/05-execution/06b-final-artifact-template.md`
  - `references/06-testing/00-testing-strategy.md` §11 cruza com
    priorização da próxima sprint.
- **Approvals Ledger** — toda decisão HITL em `full-access` é
  registrada em `docs/memory/approvals.jsonl` com evidência, riscos,
  decisão, e (quando aplicável) `becomes_rule` que alimenta evolução
  de política — Ning et al. 2026, §5.2.5.
  - `references/05-execution/13-approvals-ledger.md`
  - `references/templates/approval-entry-schema.json`
  - `references/scripts/approvals-append.sh`
  - `templates/docs/memory/approvals.jsonl`
  - `telemetry-report.sh` conta entradas com `becomes_rule` e avisa
    quando ≥5 regras candidatas estão sem promoção.
  - `references/07-deploy/01-security-checklist.md` §13a ganha bloco
    de auditoria mensal do ledger.
- **Reference Mining (CodeRAG) opt-in** — fase opcional entre Spec e
  Sprint Plan; default desligado. Vale para domínio específico em
  modelos médios — Li et al. 2025, §2.3.
  - `references/03-spec/06-reference-mining.md`
  - `references/templates/spec/references-template.json`
  - `references/templates/spec/references-schema.json` (JSON Schema com
    commit SHA fixado obrigatório)
  - Allowlist de licenças (MIT, Apache-2.0, BSD-2/3, ISC, 0BSD);
    GPL/AGPL/LGPL/SSPL/BUSL bloqueadas sem ADR; `validate.sh` enforça.
  - Hard rule: atribuição inline obrigatória em todo código derivado.
- **Modelo mínimo recomendado** em `AGENTS.md §0` — Sonnet 4.6+ /
  GPT-5 / Gemini 2.5 Pro; modelos abaixo só para tarefas mecânicas.
  Bootstrap (§A) pergunta o modelo no Discovery e preenche o bloco.
- Opt-ins de Spec/Sprint na fase Discovery (Reference Mining, Concept +
  Algorithm split).

### Changed

- `SKILL.md` "Hard rules" reorganizado por tier de permissão; bootstrap
  (§A) cria `approvals.jsonl`; §D passo 7 aponta ao novo Final Artifact.
- `AGENTS.md` template: allowlist reescrita em três blocos (read-only /
  sandbox-edit / full-access).
- `00-architecture-and-flow.md` §5 ganha §5.0.1 sobre as duas séries
  estruturadas da Camada 2/3 (telemetry + approvals); §8 e §11
  apontam ao modelo de tiers; §12 adiciona o Change Contract.
- `README.md` §"Improving the harness" exige Change Contract para
  `minor`/`major`.

---

## [v0.2] — 2026-05-21

> Fundação: estado estruturado + telemetria. Implementa os mecanismos
> triplo-confirmados pelas três análises (Zhou, DeepCode,
> Code-as-Harness) e formaliza o que já existia disperso.

### Added

- **CodeMem layer** (`docs/memory/codemap/`) — índice estrutural por
  módulo público, com `modules/<slug>.md` por módulo e `graph.json`
  de dependências. Move o harness do nível "implicit/file-only" para
  "repository-based" (Ning et al. 2026, §4); fecha o gap que mais
  aparece em ablation de Li et al. 2025 (>2× em scores com
  dependências cruzadas).
  - `references/05-execution/10-codemem-protocol.md`
  - `references/templates/codemap/{module,README,graph}-template`
  - `templates/docs/memory/codemap/`
  - `references/scripts/codemap-update.sh` — detecta módulos
    alterados via git diff, lista CREATE/UPDATE com paths de
    template; determinístico, sem LLM.
  - `references/scripts/codemap-graph.sh` — regenera `graph.json`
    a partir dos `modules/*.md` (parse de "### Imports (afferent)").
  - `validate.sh` falha quando arquivos públicos não têm entrada.
- **Deep Telemetry** (`docs/memory/telemetry.jsonl`) — 7 tipos de
  evento estruturados (plan_submitted, plan_approved/rejected,
  gate_failed, subagent_dispatched, human_intervention, story_closed,
  spec_drift_detected); coexiste com o log narrativo
  `docs/memory/execution/*.md`. Triplo-confirmada (Zhou §1.4,
  DeepCode §5, Code-as-Harness §3.5.1).
  - `references/05-execution/11-telemetry-protocol.md`
  - `references/templates/telemetry-event-schema.json`
  - `references/scripts/telemetry-append.sh` (valida tipo, fase, JSON)
  - `references/scripts/telemetry-report.sh` (5 métricas: distribuição,
    plan-rejection rate, gate failures, spec drift ratio, duração
    média de story)
  - `validate.sh` falha quando `telemetry.jsonl` tem linhas não-JSON.
- **Tech Spec Implementation Blueprint** — 5 seções canônicas como
  espinha obrigatória da Tech Spec (B1 Project File Hierarchy,
  B2 Component Specification, B3 Verification Protocol, B4 Execution
  Environment, B5 Staged Development Plan), Li et al. 2025 §2.1.
  Cada uma com propósito, critério de pronto e exemplo.
- **Hierarchical Content Segmentation** — `spec-fetch.sh "<heading>"`
  emite só a seção pedida do Tech Spec (heading + corpo até próximo
  heading de nível ≤). `spec-index.sh` gera índice JSON.
  - `validate.sh` falha quando headings do Tech Spec têm duplicatas
    (precondição para fetch não-ambíguo).
- **Spec Drift Protocol** — saída disciplinada do "Plan-then-Code"
  rígido. Quando a Spec/PRD/ADR está errada, o agente pausa
  (`status: blocked-spec-drift`), cria report e espera decisão humana
  (A: corrigir Spec + ADR retroativa, B: ajustar story, C: cancelar).
  Workaround silencioso vira Hard rule violation.
  - `references/04-sprints/04-spec-drift-protocol.md`
  - `references/04-sprints/05-spec-drift-report-template.md`
  - `phase-status.sh` lista stories bloqueadas separadamente.
- **Smoke Run** obrigatório no `_summary.md` da Sprint (7 itens:
  install limpo, typecheck, lint, test, dev boot ≤30s, README parity,
  output anexado). `validate.sh` enforça.
- **Convergence criterion nomeado** — o harness usa "correctness
  convergence" (Code-as-Harness §4.3.2); recusa explicitamente
  "implicit convergence" (loops sem critério objetivo de parada).
- **Princípios P6–P12** em `00-architecture-and-flow.md` §2:
  - P6–P9 promovidos da análise Zhou (`00-paper-analysis.md`).
  - P10 (SNR maximization, DeepCode §3).
  - P11 (Roteamento hierárquico > escala, DeepCode §1).
  - P12 (Quatro propriedades-alvo: executável, inspecionável,
    stateful, governado, Code-as-Harness §5.2.7).

### Changed

- `SKILL.md` §D passo 2 indica `spec-fetch.sh` como entrada preferida
  do tech-spec; §A bootstrap inclui `telemetry.jsonl` e
  `docs/memory/codemap/`; §H novo (Spec Drift); novo Hard rule contra
  workaround silencioso.
- Story template e `00-conventions.md` adicionam status
  `blocked-spec-drift` e `cancelled`.
- DoD da story inclui codemap-update quando aplicável.

---

## [v0.1] — antes deste plano

Versão inicial documentada nos commits anteriores a `14e3e03`. Bootstrap
mínimo, fluxo Discovery → PRD → Spec → Sprint → Execução → Deploy,
templates de fase, scripts básicos (`validate.sh`, `phase-status.sh`,
`sprint-status.sh`, `story-list.sh`, `next-story.sh`, `progress.sh`,
`check-spec-drift.sh`), princípios P1–P5, AGENTS.md base.
