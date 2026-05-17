# ADR-0001 — Architecture Layout

> **Template.** Este ADR fica em `docs/spec/adr/0001-architecture-layout.md` no produto. Copiar deste arquivo no bootstrap da Sprint 01 e preencher. Referência completa em [`../../../../references/03-spec/03-architecture-layout.md`](../../../../references/03-spec/03-architecture-layout.md).

**Status:** `proposed | accepted | superseded by ADR-XXXX | deprecated`
**Data:** `<YYYY-MM-DD>`
**Decisores:** `<eng lead>, <PM>, <tech advisor opcional>`
**Consultores:** `<lista>`

---

## Contexto

Todo produto neste harness precisa decidir entre **Variante A (Next.js-idiomática)** e **Variante B (em camadas / Clean Architecture)** antes da Sprint 01. A decisão é estratégica: refatorar depois custa caro porque cada story carrega o leiaute escolhido. O harness fornece a referência completa em [`references/03-spec/03-architecture-layout.md`](#) com critérios de decisão.

Resumo do produto (para contexto da decisão):

- **Domínio:** `<1-2 frases sobre o que o produto faz; cite o Bounded Context Core de 02-domain-model.md>`
- **Time:** `<N devs hoje; expectativa em 6 meses>`
- **Vida esperada:** `<MVP descartável | 1-2 anos | ≥ 2 anos>`
- **Integrações no roadmap:** `<lista>`

---

## Decisão

> **Decidimos a Variante `<A | B>` porque `<razão central, 1 frase>`.**

### Pontuação aplicada

| Sinal | Peso | Aplica? | Pontos |
|-------|------|---------|--------|
| `02-domain-model.md` identifica ≥ 1 Bounded Context Core | +3 | `<sim/não>` | `<0 ou 3>` |
| Existe ≥ 1 invariante de negócio não-trivial | +2 | `<...>` | `<...>` |
| Roadmap menciona ≥ 2 integrações externas em ≤ 6 meses | +2 | `<...>` | `<...>` |
| Time atual ≥ 4 devs ou planeja crescer | +1 | `<...>` | `<...>` |
| Vida esperada do produto ≥ 2 anos | +1 | `<...>` | `<...>` |
| MVP descartável ou prova de conceito | -3 | `<...>` | `<...>` |
| Time é 1 dev solo permanentemente | -2 | `<...>` | `<...>` |
| **Total** | | | `<...>` |

`<comentário sobre o resultado: a pontuação confirma a variante escolhida, ou a variante foi escolhida apesar da pontuação?>`

### Detalhamento

`<2-4 parágrafos: qual leiaute, qual a estrutura de pastas (cole o trecho relevante de 03-architecture-layout.md), quais as regras de dependência se Variante B, qual o caminho de migração se a decisão se revelar errada.>`

---

## Alternativas consideradas

### Opção A — Variante A (Next.js-idiomática) `<escolhida | rejeitada>`

- ✅ `<vantagens aplicáveis a este produto>`
- ❌ `<desvantagens aceitas ou que motivaram rejeição>`

### Opção B — Variante B (em camadas / Clean Architecture) `<escolhida | rejeitada>`

- ✅ `<vantagens aplicáveis a este produto>`
- ❌ `<desvantagens aceitas ou que motivaram rejeição>`

### Opção C — Híbrido informal

- Rejeitada de antemão pelo harness. Ver anti-padrões em [`references/03-spec/03-architecture-layout.md`](#).

---

## Consequências

**Positivas:**

- `<benefícios concretos esperados nas próximas 4 sprints>`

**Negativas / dívidas aceitas:**

- `<custos concretos: onboarding mais lento, mais arquivos por feature, etc.>`

**Impacto em outros sistemas:**

- `AGENTS.md`: precisa de leitura adaptada nas regras X, Y, Z. *(Se Variante B; listar 5+ regras conforme tabela em [`03-architecture-layout.md`](#) §"Mapeamento das regras".)*
- `05-execution/02-nextjs-conventions.md` §3: leitura adaptada para `src/interface/web/`. *(Se Variante B.)*
- `05-execution/00-context-protocol.md` "Bootstrap mínimo": passos 5-7 mudam para `src/domain/<contexto>/`. *(Se Variante B.)*
- `scripts/validate.sh` check #11 (TDD gap): ativo apenas se `src/domain/` ou `src/application/` existirem. *(Se Variante B, fica ativo.)*

---

## Regras impactadas (Variante B apenas)

> Liste **explicitamente** as regras do harness que precisam de leitura adaptada. Sem isso, o agente vai cumprir a regra original e violar o leiaute escolhido.

| Regra original | Onde está | Leitura nesta variante |
|----------------|-----------|------------------------|
| `<ex: "Server Action mora em app/.../actions.ts">` | `02-nextjs-conventions.md` §5 | `<ex: "Em src/interface/web/app/.../actions.ts; thin controller; chama use-case de src/application/">` |
| `<ex: "lib/db/schema.ts é fonte de verdade">` | `02-nextjs-conventions.md` §3 | `<ex: "Schema em src/infrastructure/db/schema.ts; modelo verdadeiro em src/domain/">` |
| `<...>` | `<...>` | `<...>` |

---

## Plano de revisão

> Esta decisão deve ser reavaliada se acontecer X.

`<ex: "Reavaliar se a Variante B mostrar fricção em > 50% das stories da Sprint 02 (medido por retro), ou se o time crescer > 8 devs e equipes ficarem acopladas demais nos contextos.">`

---

## Referências

- PRD: `docs/prd/<arquivo>.md`
- Domain Model: `docs/spec/02-domain-model.md`
- Tech Spec: `docs/spec/00-tech-spec.md`
- Referência do harness: [`references/03-spec/03-architecture-layout.md`](#)

---

## Como o agente deve tratar este ADR

- Toda story que toca código deve carregar este ADR no bootstrap mínimo (Context Protocol §1).
- Se a story propuser código que **viola a direção de dependência** (Variante B) ou propuser estrutura em camadas (Variante A escolhida), o agente **para**, cita este ADR e pede confirmação ou abertura de ADR de substituição.
- O `check-spec-drift.sh` lê este ADR para saber qual layout está em uso e ajusta as checagens.
