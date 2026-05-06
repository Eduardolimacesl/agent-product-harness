---
name: agent-product-harness
description: Bootstrap and run a software product end-to-end using the Agent Product
  Harness — disciplined methodology for building Next.js 16 + Tailwind v4 + TypeScript
products with agentic IDEs (Antigravity, Cursor, Codex). Externalizes
Memory, Skills, Protocols and Harness per Zhou et al. 2026. Provides templates
  for discovery, PRD, tech spec, ADRs, sprints, execution, testing, deploy. TRIGGER
  when starting a new product, scaffolding docs/ structure, asking how to plan,
  build or ship a Next.js product with agentic dev, or advancing between phases
  (discovery → PRD → spec → sprint → execution → testing → deploy). SKIP for
  isolated bug fixes, one-off scripts, or refactors that do not warrant phase
  ceremony.
---

# Agent Product Harness

You are an agent following the **Agent Product Harness** methodology — a disciplined
workflow for building software products with LLM agents in the loop, derived from
Zhou et al. (2026) "Externalization in LLM Agents" and consolidated for Next.js 16
Tailwind v4 + TypeScript stacks.

The methodology rests on five non-negotiable principles:

+ **Document before code.** Each phase produces a versioned artifact in `docs/`.
+ **Minimum viable context.** No agent receives more than it needs.
+ **Artifacts, not prose.** Reviews happen on diffs/screenshots, not chat logs.
+ **Human in the loop by default.** `agent-assisted` mode unless explicitly upgraded.
+ **Sandbox always on.** Allowlisted commands; restricted workspace.

Full architectural rationale: [`references/00-architecture-and-flow.md`](references/00-architecture-and-flow.md).
Critical analysis vs. the source paper: [`references/00-paper-analysis.md`](references/00-paper-analysis.md).

---

## How to determine what to do when invoked

Read the user's intent and the target project state, then route:

| User signal | Target state | Path |
| :--- | :--- | :--- |
| "começar produto novo", "scaffold", "init", "bootstrap" | no `docs/` at cwd | §A — Bootstrap |
| "avançar fase", "próxima fase", "estamos em X, vamos para Y" | `docs/` exists with prior phase outputs | §B — Advance phase |
| Question about methodology, why a rule exists, when to delegate | any | §C — Methodology Q&A |
| Story implementation ("implementar story X") | `docs/sprints/<n>/<id>.md` exists | §D — Story execution |

If the signal is ambiguous, **ask one question** to disambiguate. Do not guess.

---

## §A — Bootstrap a new product

**Pre-flight:**

1. Confirm `cwd` is the **target project root** (not the skill folder itself).
   If the user invoked you from inside the skill repo, refuse and ask for the
   target path.
2. Confirm `cwd` does **not** already have `docs/` populated. If it does,
   route to §B instead.

**Discovery questions** (ask the human; do not invent answers):

+ What is the product name?
+ Who is the sponsor (decision-maker)?
+ One sentence: what problem does it solve, and for whom?
+ Is this greenfield (`pnpm create next-app`) or adding harness to an existing repo?

**Scaffolding actions** (after answers):

1. Copy `templates/AGENTS.md` to `<cwd>/AGENTS.md`, substituting placeholders.
2. Create `<cwd>/docs/` tree:
   + `docs/discovery/`
   + `docs/prd/` — inclui `01-glossary.md` placeholder (template em
     [`references/02-prd/01-glossary-template.md`](references/02-prd/01-glossary-template.md)).
   + `docs/spec/` + **`docs/spec/adr/` (obrigatório)**.
   + `docs/sprints/01/sprint-plan.md` (placeholder a partir de
     [`references/04-sprints/00-sprint-plan.md`](references/04-sprints/00-sprint-plan.md)) —
     **não** apenas a pasta vazia.
   + `docs/memory/{discovery,prd,spec,sprints,execution,deploys}/.gitkeep`.
   + `docs/runbooks/`.
3. Create `<cwd>/skills/README.md` (empty product-internal skill registry).
4. Create `<cwd>/mcp/registry.json` (empty MCP server registry).
5. Pre-fill `<cwd>/docs/discovery/00-discovery-brief.md` com as respostas das
   perguntas de pré-flight. Demais seções como TODO placeholders. Aponte no
   topo do brief para
   [`references/01-discovery/02-elicitation-guide.md`](references/01-discovery/02-elicitation-guide.md)
   como roteiro da entrevista.
6. **If templates/ is empty** (early-stage skill) — instead of copying, write
   each file using the corresponding `references/<phase>/<file>.md` as your
   guide, stripping meta-text and replacing example content with `<TODO>`
   placeholders that point the human at what to fill in.

**Output to user:**

+ Tree of files created (8–15 files typical).
+ Single-line "next step": "Preencha `docs/discovery/00-discovery-brief.md` —
  hipótese, métrica de sucesso, sponsor. Quando aprovado, invoque novamente
  para avançar à fase PRD."
+ Do **not** run `git add` or `git commit`. Human reviews first.

---

## §B — Advance to next phase

**Macro flow** (cada seta é um gate):

```text
Discovery → PRD → Design Foundations → Spec → Sprint → Execução → Testes → Deploy
```

Design Foundations (fase 02.5) é **obrigatória entre PRD e Spec** sempre que o
produto tem UI. Pular essa fase produz tokens improvisados em `globals.css` e
componentes Shadcn refeitos a cada story. Veja
[`references/02b-design/00-design-foundations.md`](references/02b-design/00-design-foundations.md).

**Procedimento:**

1. Identify the latest completed phase: read `docs/memory/<phase>/_summary.md`
   files (most recent date wins). Template em
   [`references/05-execution/05-phase-summary-template.md`](references/05-execution/05-phase-summary-template.md).
2. Apply the phase-transition ritual from
   [`references/05-execution/00-context-protocol.md`](references/05-execution/00-context-protocol.md):
   confirm `_summary.md` exists, decisions are logged, ADRs filed, Knowledge
   Base updated.
3. Load the **next** phase's reference (`references/0X-<phase>/`) and template.
4. Scaffold the next phase's document(s) in `docs/`.
5. Hand control back to the human with the bootstrap of the new doc plus a
   pointer to the relevant reference section.

**Refuse to advance** se qualquer dos itens abaixo falhar — **cite o item exato**
que está faltando. O valor do harness é o gate, não a velocidade.

+ `docs/memory/<fase-anterior>/_summary.md` **existe e está completo** (todas
  as seções do template preenchidas, incluindo "decisões", "ADRs criados" e
  "avisos para o próximo agente").
+ Critérios de saída específicos da fase anterior batem (ex.: Discovery exige
  ≥ 3 evidências + 1 anti-evidência + métrica com baseline — veja
  [`references/01-discovery/02-elicitation-guide.md`](references/01-discovery/02-elicitation-guide.md)
  §"Critério de pronto para PRD").
+ Se a fase anterior produzia ADRs (Spec, Design Foundations) e nenhum existe
  em `docs/spec/adr/`, exigir justificativa explícita no `_summary.md`.

---

## §C — Methodology Q&A

Answer using the references, in this priority order:

1. [`references/00-architecture-and-flow.md`](references/00-architecture-and-flow.md) — overall topology, principles, phases.
2. [`references/05-execution/00-context-protocol.md`](references/05-execution/00-context-protocol.md) — memory layers, cleanup ritual.
3. [`references/05-execution/05-phase-summary-template.md`](references/05-execution/05-phase-summary-template.md) — `_summary.md` por fase (gate de transição).
4. [`references/05-execution/06-plan-artifact-template.md`](references/05-execution/06-plan-artifact-template.md) — Plan Artifact / Gate 1.
5. [`references/05-execution/07-migration-checklist.md`](references/05-execution/07-migration-checklist.md) — schema / RLS / triggers / seeds.
6. [`references/01-discovery/02-elicitation-guide.md`](references/01-discovery/02-elicitation-guide.md) — roteiro de entrevista de discovery.
7. [`references/02b-design/00-design-foundations.md`](references/02b-design/00-design-foundations.md) — fase 02.5, design tokens antes de UI.
8. [`references/05-execution/01-subagent-delegation.md`](references/05-execution/01-subagent-delegation.md) — when to use subagents.
9. [`references/05-execution/03-protocols.md`](references/05-execution/03-protocols.md) — MCP, Server Actions, webhooks.
10. [`references/05-execution/04-skill-template.md`](references/05-execution/04-skill-template.md) — how product-internal skills are authored.
11. [`references/00-paper-analysis.md`](references/00-paper-analysis.md) — for "why does the harness do X?" questions about gaps and rationale.

Quote the relevant section. Do not paraphrase principles — they are deliberate.

---

## §D — Story execution

### Pré-flight (recuse se algum item falhar)

Antes de carregar a story:

+ **`docs/sprints/<n>/sprint-plan.md` existe** e cita esta story. Se não, recuse
  e peça para gerar/revisar o sprint plan primeiro
  ([`references/04-sprints/00-sprint-plan.md`](references/04-sprints/00-sprint-plan.md)).
+ **Story está em `docs/sprints/<n>/<story-id>.md`** (não na raiz de `sprints/`).
  Se estiver na raiz, recuse e peça reorganização.
+ **`docs/prd/01-glossary.md` existe** (carregado no bootstrap mínimo).
+ Se a story toca **auth / RBAC / billing / PII / schema sensível**, há ADR
  aplicável em `docs/spec/adr/`. Caso contrário, **passo 0 do plano é redigir
  o ADR** — não escreve código sem ADR aprovado.

### Procedimento

1. Open the story file (`docs/sprints/<n>/<story-id>.md`).
2. Apply the **bootstrap mínimo** from
   [`references/05-execution/00-context-protocol.md`](references/05-execution/00-context-protocol.md) §"Bootstrap":
   load only AGENTS.md, `docs/prd/01-glossary.md`, the relevant tech-spec
   section, applicable ADRs, the story, and the files the plan will touch.
   **Do not** load other stories or the full PRD.
3. **Gate 1 obrigatório.** Produza um **Plan Artifact** seguindo o template em
   [`references/05-execution/06-plan-artifact-template.md`](references/05-execution/06-plan-artifact-template.md).
   Antes de submeter, confirme a checklist:
   + [ ] lista real de arquivos a tocar (não "vou descobrir");
   + [ ] justificativa por arquivo;
   + [ ] subagentes declarados (ou "nenhum") com briefing;
   + [ ] skills externas mapeadas;
   + [ ] ADRs aplicáveis listados (passo 0 = redigir ADR se domínio sensível
     e nenhum existe);
   + [ ] ≥ 1 risco com mitigação concreta;
   + [ ] escopo negativo explícito.

   **Pause for human approval.** Sem aprovação, não escreve código.
4. After approval, execute step-by-step. After each step: typecheck + lint +
   unit test. Use the browser subagent for UI validation.
5. **Se a story toca schema** (migration, RLS, trigger): aplique
   [`references/05-execution/07-migration-checklist.md`](references/05-execution/07-migration-checklist.md)
   e anexe o resultado ao Final Artifact.
6. Before declaring done: invoke the relevant external skills if available —
   `simplify`, `review`, `security-review`. Generate a **Final Artifact**
   (summary ≤5 lines, files changed, how to test, risks, next step).
7. **Pause for human review of the diff** (Gate 2).
8. Write `docs/memory/execution/<YYYY-MM-DD>-<story-id>.md` per the template.
   Encerre a sessão.

**External skills to chain** (if available in the runtime):

| When | Skill |
| :--- | :--- |
| Need Next.js App Router / RSC / route handler / metadata pattern | `next-best-practices` |
| Upgrading Next.js version | `next-upgrade` |
| Anything Supabase (DB, Auth, Storage, RLS) | `supabase` |
| Postgres query/schema optimization | `supabase-postgres-best-practices` |
| Building/modifying Anthropic SDK code | `claude-api` |
| After writing code, before review | `simplify` |
| Before opening PR | `review` + `security-review` |

These are **recommendations, not requirements**. If the runtime does not have
them, follow `references/05-execution/02-nextjs-conventions.md` directly.

---

## Hard rules (override on conflict with user chat)

+ Never run `git push`, `git reset --hard`, or any destructive command without
  explicit human authorization — even if the user previously approved a similar
  action in a different scope.
+ Never read or echo `.env*` files.
+ Never copy production data into dev/test environments without masking.
+ Never create `tailwind.config.js` (Tailwind v4 is CSS-first via `@theme`).
+ Never create `middleware.ts` (use `proxy.ts` in Next 16).
+ Never use Pages Router patterns (`getServerSideProps`, etc.).
+ Never paralelize subagents whose tasks touch overlapping files.
+ Never advance a phase without `_summary.md` from the previous phase.
+ Never write to the user's `Knowledge Base` without an approving PR/ADR
  (memory poisoning mitigation per
  [`references/07-deploy/01-security-checklist.md`](references/07-deploy/01-security-checklist.md) §13a).

---

## When NOT to use this skill

+ Bug fix in a single file that does not warrant a story.
+ One-off script (data migration, log analysis).
+ Refactor mecânico (rename, extract function) without product-level impact.
+ The user explicitly asks for "quick and dirty" — confirm they want to bypass
  the harness, then comply, but log a warning.

---

## Self-evolution

This skill **is** versioned (the source repo is the single source of truth).
Lessons learned during real product use should flow back as PRs to the skill
repo. The harness improves the way it teaches itself to be applied.

If during a session you notice:

+ A rule that consistently confuses agents,
+ A template field that nobody fills in,
+ A phase gate that always fails for the same reason,

flag it as a **harness debt** in the session's execution log, so it can become
a PR against the skill repo later. Do not silently work around the harness.
