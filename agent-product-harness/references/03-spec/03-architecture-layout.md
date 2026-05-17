# Architecture Layout — escolha do leiaute de pastas

> Decisão estratégica de como o código é fisicamente organizado. **Precisa virar ADR** logo no início do produto (Sprint 01) — refazer depois custa muito caro porque cada story carrega o layout escolhido.
>
> Pré-requisito: [`02-domain-model.md`](02-domain-model.md) (se aplicável), porque a granularidade dos contextos influencia a escolha.

---

## Por que esta decisão existe

O harness padroniza **stack** (Next.js 16 + Tailwind v4 + TypeScript estrito) mas **não impõe leiaute único** porque o ROI muda dramaticamente com a complexidade do domínio:

- Produto CRUD com 3 entidades planas, 1 papel de usuário, sem regras complexas → Clean Architecture é overhead.
- Produto com múltiplos bounded contexts, invariantes de negócio, integrações com sistemas externos → leiaute Next.js-idiomático mistura camadas e gera caos em 6 meses.

A decisão é binária: **Variante A (idiomática)** ou **Variante B (em camadas)**. Não existe meio-termo "evoluímos depois" sem dor — comece como pretende terminar.

---

## Variante A — Leiaute Next.js-idiomático (default)

Estrutura conforme [`05-execution/02-nextjs-conventions.md`](../05-execution/02-nextjs-conventions.md) §3:

```
app/                  ← rotas, layouts, páginas, Server Actions
  (marketing)/
  (app)/
    inspections/
      page.tsx
      actions.ts      ← validação + persistência + revalidate, tudo aqui
components/
  ui/
  features/
    inspections/
lib/
  db/
    schema.ts
    client.ts
  auth/
  utils.ts
tests/
```

**Quando escolher:**

- Produto CRUD majoritário (≥ 70% das stories são "salvar form, listar registros").
- Time pequeno (1-3 devs), velocidade de feature > pureza arquitetural.
- Domínio simples, sem invariantes além das do banco.
- MVP que pode ser descartado/reescrito em 6 meses.

**Custos aceitos:**

- Server Action mistura validação, auth, persistência. Refatorar para extrair use-case quando uma das três crescer.
- Acoplamento direto a Drizzle/Postgres na camada de UI — trocar ORM é trabalhoso.
- Testes de domínio mais difíceis: precisam de DB efêmero porque não há fronteira clara entre regra e persistência.

**Vantagens:**

- Onboarding rápido (todo dev Next.js entende em 10 minutos).
- Menos arquivos por feature → diff menor por story.
- Fricção mínima com `create-next-app` e com a maioria das skills externas (`next-best-practices`, `supabase`, etc.).

---

## Variante B — Leiaute em camadas (Clean Architecture)

```
src/
  domain/             ← entidades, VOs, eventos, regras puras. Zero deps externas.
    inspections/
      inspection.ts           ← Aggregate Root
      finding.ts              ← Entity
      events/
        inspection-completed.ts
      ports/                  ← interfaces (repositories, services)
        inspection-repository.ts
      values/
        inspection-status.ts  ← Value Object
    identity/
    billing/
  application/        ← use-cases (orquestração)
    inspections/
      create-inspection.ts    ← comando
      list-inspections.ts     ← query (CQS)
    identity/
    billing/
  infrastructure/     ← adapters (impl das ports)
    db/
      drizzle/
        drizzle-inspection-repository.ts
    auth/
      supabase-auth-adapter.ts
    events/
      in-process-event-bus.ts
  interface/          ← Next.js fino
    web/              ← (era app/) — rotas, layouts, Server Actions = thin controllers
      (marketing)/
      (app)/
        inspections/
          page.tsx
          actions.ts          ← valida com Zod, chama use-case, mapeia erro
      proxy.ts
    cli/              ← se aplicar
  contracts/          ← schemas Zod compartilhados entre interface e tests
    inspections/
      create-inspection.schema.ts
tests/
  unit/
    domain/           ← espelha src/domain/
    application/      ← espelha src/application/
  integration/        ← adapters reais (Drizzle, Supabase)
  e2e/                ← Playwright
```

**Regras de dependência (a direção é sagrada):**

```
interface → application → domain
            ↑
infrastructure ↑ (depende de domain via ports; nunca o contrário)
```

- `domain/` **não importa** nada de `application/`, `infrastructure/`, `interface/`, nem libs externas com I/O.
- `application/` importa de `domain/` + `contracts/`. Recebe ports concretas via DI (construtor ou parâmetro).
- `infrastructure/` importa de `domain/` (para implementar ports) e libs externas.
- `interface/` importa de `application/` e `contracts/`. **Não** importa `domain/` direto e **não** importa `infrastructure/` direto — composição (montagem da DI) fica num arquivo `src/composition.ts` ou no entry point.

**Quando escolher:**

- Produto com **≥ 1 Bounded Context Core** identificado em `02-domain-model.md`.
- Existe pelo menos 1 invariante de negócio não-trivial (saldo, máquina de estado, política de combinação).
- Roadmap inclui integrações múltiplas (SAP, ERP, gateway de pagamento) — separação reduz acoplamento.
- Time ≥ 4 devs ou múltiplas equipes — fronteiras de pasta = fronteiras sociais.
- Produto com vida esperada ≥ 2 anos.

**Custos aceitos:**

- Mais arquivos por feature (Server Action → use-case → port → adapter → migration → contrato → testes).
- Onboarding mais lento (precisa entender a direção de dependência).
- `next-best-practices` e `02-nextjs-conventions.md` precisam ser lidos com tradução mental: tudo que diz "em `app/`" lê-se "em `src/interface/web/app/`".

**Vantagens:**

- Regras de negócio testáveis sem subir banco (fakes in-memory implementam as ports).
- TDD natural no domínio (gate em `validate.sh` check #11 já assume este layout).
- Trocar Drizzle por Prisma, Postgres por outro banco, Supabase Auth por Clerk = trocar um adapter; domínio não sente.
- Bounded Contexts viram pastas que **forçam** desacoplamento — não dá pra acidentalmente fazer `Billing` ler tabela de `Inspections`.

---

## Como decidir

Pesos práticos (somar; ≥ 5 → Variante B; < 5 → Variante A):

| Sinal | Peso |
|-------|------|
| `02-domain-model.md` identifica ≥ 1 Bounded Context Core | +3 |
| Existe ≥ 1 invariante de negócio não-trivial | +2 |
| Roadmap menciona ≥ 2 integrações externas em ≤ 6 meses | +2 |
| Time atual ≥ 4 devs ou planeja crescer | +1 |
| Vida esperada do produto ≥ 2 anos | +1 |
| MVP descartável ou prova de conceito | -3 |
| Time é 1 dev solo permanentemente | -2 |

> O peso é heurístico, não receita. Use como provocação, não como veredito.

---

## Mapeamento das regras do harness por variante

Várias regras de `AGENTS.md` e das convenções precisam de leitura adaptada se a Variante B for adotada. Ver tabela de "Regras impactadas" no [`adr/0001-architecture-layout.md`](#) (template em [`templates/docs/spec/adr/0001-architecture-layout.md`](../../templates/docs/spec/adr/0001-architecture-layout.md)).

| Regra original (Variante A) | Leitura na Variante B |
|------------------------------|----------------------|
| Server Action mora em `app/.../actions.ts` com validação + persistência | Server Action em `src/interface/web/app/.../actions.ts` valida com Zod (do `src/contracts/`), chama use-case em `src/application/`, mapeia erro de domínio para resposta segura. Nada mais. |
| `lib/db/schema.ts` é a fonte de verdade do modelo | Schema em `src/infrastructure/db/schema.ts` é tradução do modelo; modelo verdadeiro está em `src/domain/`. |
| Validar entrada com Zod **na borda** | Continua valendo, mas o schema Zod **mora em `src/contracts/`** e é importado tanto pelo Server Action quanto pelo teste. |
| Bootstrap mínimo carrega `lib/db/schema.ts` quando a story toca persistência | Carrega `src/domain/<contexto>/<agregado>.ts` + `src/application/<contexto>/<use-case>.ts` + a port relevante. **Não** carrega `infrastructure/` a menos que a story altere o adapter. |
| TDD obrigatório para "lógica de domínio, validações, máquinas de estado" | Mesma regra, mas **mecanizada**: `validate.sh` check #11 avisa quando arquivo em `src/domain/**` ou `src/application/**` não tem teste correspondente. |

---

## Migração entre variantes (raro, mas possível)

**A → B:** custo alto. Padrão de migração incremental:
1. Crie `src/domain/<contextoCore>/` apenas para o Bounded Context que mais sofre com acoplamento.
2. Extraia uma Server Action por vez para use-case. Server Action vira controller fino.
3. Schema continua em `lib/db/schema.ts` no início; mova para `src/infrastructure/db/` quando ≥ 50% das ações migrarem.
4. ADR de substituição obrigatório (`0001-architecture-layout-revision.md` referenciando o ADR original).

**B → A:** quase nunca acontece, mas se acontecer, é sinal de que a Variante B foi escolhida prematuramente. Trate como retro: ADR registra a aprendizagem e renomeia pastas.

---

## Anti-padrões

- ❌ **Híbrido informal** ("usamos camadas só nesta feature"). → ou tudo, ou nada; meio-termo gera 2 modelos mentais simultâneos.
- ❌ **Variante B sem `02-domain-model.md`**. → leiaute em camadas sem modelo é estrutura vazia; o agente carrega pastas mas não tem invariantes para proteger.
- ❌ **Variante A com mais de 5 contextos identificados**. → o leiaute idiomático vai colapsar; revise a decisão.
- ❌ **Server Action na Variante B com lógica de negócio inline**. → controller fino. Se sente vontade de escrever regra ali, suba para use-case.
- ❌ **Domain importando lib externa com I/O**. → quebra a regra de dependência; o teste do domínio precisa de DB → você não tem domínio puro.

---

## Como instruir o agente nesta fase

```
Sua tarefa é guiar o time na escolha do leiaute de arquitetura e produzir
o ADR-0001.

1. Leia docs/spec/02-domain-model.md (se existir) e o PRD.
2. Some os pesos da tabela "Como decidir".
3. Apresente o resultado, com justificativa para cada peso atribuído.
4. Pergunte explicitamente: "Variante A ou B?". Não decida sozinho.
5. Com a resposta humana, redija docs/spec/adr/0001-architecture-layout.md
   a partir do template em templates/docs/spec/adr/0001-architecture-layout.md.
6. Se Variante B: liste no ADR as 5+ regras de AGENTS.md / convenções que
   precisarão de leitura adaptada (use a tabela "Mapeamento das regras"
   acima como base).
7. Não crie as pastas ainda. Pastas vêm na Sprint 01, story de "scaffold
   arquitetural", com seu próprio Plan Artifact.
```
