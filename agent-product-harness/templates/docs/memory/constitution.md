---
artifact: constitution
version: 0.1
status: draft
ratified: TODO
created: <ISO 8601 UTC>
updated: <ISO 8601 UTC>
---

# Constitution — `<NOME-DO-PRODUTO>`

> Invariantes não-negociáveis **deste produto**. Curta (≤1 página), só regras
> checáveis. Ratificada no gate PRD → Spec. Guia de preenchimento:
> `references/03-spec/08-constitution.md`.
>
> Regra de ouro: se não dá para falsificar num diff ou gate, **não é regra** —
> é valor de produto (volta para o PRD).

---

## Artigo I — Qualidade de código

- `<TODO: ex. sem `any`; função >30 linhas refatora; CQS respeitada>`
- `<TODO>`

## Artigo II — Disciplina de teste

- `<TODO: ex. todo P0 do PRD tem 1 teste E2E nomeado pela story>`
- `<TODO: ex. arquivos em src/domain/** e src/application/** são TDD>`
- Meta de cobertura: `[NEEDS CLARIFICATION: meta por módulo — ex. 80%?]`

## Artigo III — Consistência de UX

> Pular para produtos sem UI (CLI, lib, daemon) — registre o porquê abaixo.

- `<TODO: ex. toda tela cobre loading/vazio/erro/sucesso>`
- `<TODO: ex. a11y WCAG 2.1 AA em componentes interativos>`

## Artigo IV — Budgets de performance

- `<TODO: ex. LCP p75 <2.5s; INP p75 <200ms; bundle/rota <250KB>`
- CI **falha** o build ao estourar qualquer budget acima.

## Artigo V — Baseline de segurança

- `<TODO: ex. Zod em toda entrada de borda>`
- `<TODO: ex. nenhum secret em código; sensível (auth/billing/PII) exige ADR>`

## Artigo VI — Simplicidade

- `<TODO: ex. 3 ocorrências antes de extrair abstração>`
- `<TODO: ex. sem feature flag/abstração especulativa para requisito hipotético>`

---

## Artigos não aplicáveis

| Artigo | Por que não se aplica |
|--------|-----------------------|
| `<ex. III>` | `<ex. produto é CLI, sem UI>` |

---

## Log de emendas

> Toda emenda: bump de `version`, mini-contrato (regra · modo de falha que
> ataca · como falsificar). Nunca editar regra silenciosamente.

| Data | Versão | Artigo | Mudança | Modo de falha que ataca | Como falsificar |
|------|--------|--------|---------|-------------------------|-----------------|
| `<YYYY-MM-DD>` | `0.1` | — | ratificação inicial | — | — |
