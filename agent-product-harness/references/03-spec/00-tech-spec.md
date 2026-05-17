# Tech Spec — `<NOME-DO-PRODUTO>` — vX.Y

> Documento que traduz o PRD em arquitetura, contratos e decisões técnicas.
> Fonte de verdade para o agente decidir **como** construir.

**Owner:** `<eng lead>`
**Status:** `📝 draft | 👀 review | ✅ approved`
**PRD de origem:** `docs/prd/<arquivo>.md`
**Última atualização:** `<YYYY-MM-DD>`

---

## 1. Resumo executivo técnico

> 5 linhas. Stack, padrão arquitetural, decisões cruciais.

```
[ex: Next.js 16 App Router, Tailwind v4, Postgres + Drizzle, Auth por JWT,
deploy em Vercel, observabilidade via OpenTelemetry → Grafana Cloud.]
```

---

## 2. Arquitetura de alto nível

```mermaid
flowchart LR
  Browser[Cliente / Browser] --> Edge[Next.js Edge / Proxy]
  Edge --> RSC[Server Components / Server Actions]
  RSC --> DB[(Postgres)]
  RSC --> Cache[(Cache / Redis)]
  RSC --> Ext[APIs externas]
  RSC --> Obs[OpenTelemetry]
```

**Componentes:**

| Componente | Tecnologia | Responsabilidade |
|------------|------------|------------------|
| Frontend / SSR | Next.js 16, RSC, Server Actions | Renderização, mutações, autenticação na borda |
| Estilo | Tailwind v4 (`@theme` no CSS) | Design system tokens, utility classes |
| Banco | Postgres (`<provedor>`) + Drizzle ORM | Persistência transacional |
| Cache | Cache Components (`"use cache"`) + Redis (opcional) | Reduzir round-trips |
| Auth | `<NextAuth/Clerk/Supabase Auth>` | Sessão, RBAC |
| Observabilidade | OpenTelemetry → `<destino>` | Logs, traces, métricas |
| Storage | `<S3/R2/Drive>` | Arquivos do usuário |

---

## 3. Decisões-chave (referência a ADRs)

| # | Decisão | ADR |
|---|---------|-----|
| D1 | App Router + RSC default, sem Pages Router | `adr/0001-app-router.md` |
| D2 | Tailwind v4 com config CSS-first | `adr/0002-tailwind-v4.md` |
| D3 | Drizzle como ORM | `adr/0003-drizzle.md` |
| D4 | `<...>` | `<...>` |

> Sempre que houver dúvida sobre **por quê**, leia o ADR.

---

## 4. Modelo de domínio

> Entidades principais e relações. Diagrama + dicionário.
>
> **Para produtos com domínio não-trivial** (≥ 2 entidades com regras, ≥ 2 áreas de negócio, ou ≥ 1 invariante), o modelo de domínio detalhado (Bounded Contexts, Aggregate Roots, Value Objects, Domain Events, máquinas de estado) vive em [`02-domain-model.md`](02-domain-model.md). Esta seção fica como **resumo executivo do domínio** — diagrama ER + dicionário de entidades persistidas. Não duplique o conteúdo do `02-domain-model.md`.
>
> Para produtos puramente CRUD, declare aqui explicitamente: *"Domínio CRUD; sem `02-domain-model.md` por decisão consciente."*

```mermaid
erDiagram
  USER ||--o{ INSPECTION : creates
  INSPECTION ||--|{ FINDING : has
  INSPECTION }o--|| BUILDING : about
```

**Dicionário:**

| Entidade | Campos-chave | Notas |
|----------|--------------|-------|
| User | id, email, role | role: `admin` \| `inspector` \| `viewer` |
| Inspection | id, building_id, status, … | status: `draft` \| `in_progress` \| `done` |

---

## 5. Esquema de dados (referência)

> Migration inicial. Drizzle ou SQL puro.

```ts
// db/schema.ts
export const users = pgTable('users', { /* … */ });
export const inspections = pgTable('inspections', { /* … */ });
```

**Índices críticos:** liste por tabela.
**Política de soft-delete:** `<sim/não>` e por quê.
**Migrations:** `<ferramenta>` + processo de rollback.

---

## 6. Contratos (rotas, Server Actions, eventos)

### 6.1 Rotas Next.js (App Router)

| Rota | Tipo | Auth | Descrição |
|------|------|------|-----------|
| `/` | RSC | público | landing |
| `/(app)/dashboard` | RSC | autenticado | overview |
| `/(app)/inspections/[id]` | RSC | autenticado + RBAC | detalhe |
| `/api/webhooks/<x>` | Route Handler | assinado | webhook externo |

### 6.2 Server Actions

Use Server Actions para mutações. Cada action tem:

```ts
// app/(app)/inspections/actions.ts
'use server';

import { z } from 'zod';

const CreateInspectionInput = z.object({
  buildingId: z.string().uuid(),
  notes: z.string().max(2000).optional(),
});

export async function createInspection(input: unknown) {
  const data = CreateInspectionInput.parse(input);
  // ... auth check, db, revalidate
}
```

**Regras:**
- Sempre validar input com Zod (ou Valibot).
- Sempre verificar auth + autorização explicitamente.
- Sempre `revalidatePath`/`revalidateTag` no final, se mutou estado.
- Nunca expor erro cru ao cliente — mapear para mensagem segura.

### 6.3 Webhooks / API routes externas

| Endpoint | Método | Auth | Idempotência |
|----------|--------|------|--------------|
| `/api/webhooks/<x>` | POST | HMAC | sim, via `event_id` |

### 6.4 Contratos como código (Spec-Driven Development)

Os contratos das seções 6.2 e 6.3 **não vivem só nesta Spec**. Cada um é declarado uma única vez em código e referenciado tanto pela implementação quanto pelos testes. Isso fecha a malha entre spec e código — a Spec sempre reflete o que está rodando, ou a CI falha.

**Regra:** todo Server Action, webhook e Domain Event publicado tem um schema declarado em `src/contracts/` (ou `lib/contracts/` na Variante A) e nomeado conforme tabela abaixo.

| Tipo de contrato | Local canônico | Importado por |
|------------------|----------------|----------------|
| Input de Server Action | `src/contracts/<contexto>/<action>.input.ts` (Zod) | a própria action + testes (unit + integration) + Tech Spec |
| Output de Server Action | `src/contracts/<contexto>/<action>.output.ts` (Zod union `{ ok, ... }`) | mesma |
| Payload de webhook recebido | `src/contracts/webhooks/<provider>.<event>.ts` | route handler + teste de integração |
| Domain Event publicado | `src/contracts/events/<context>.<event>.v1.ts` (JSON Schema ou Zod) | publisher + consumer + analytics + dashboard |

**Exemplo (Variante A):**

```ts
// lib/contracts/inspections/create-inspection.input.ts
import { z } from 'zod';

export const CreateInspectionInput = z.object({
  buildingId: z.string().uuid(),
  notes: z.string().max(2000).optional(),
});
export type CreateInspectionInput = z.infer<typeof CreateInspectionInput>;
```

```ts
// app/(app)/inspections/actions.ts
'use server';
import { CreateInspectionInput } from '@/lib/contracts/inspections/create-inspection.input';

export async function createInspection(input: unknown) {
  const parsed = CreateInspectionInput.safeParse(input);
  // ...
}
```

```ts
// tests/unit/contracts/inspections/create-inspection.input.test.ts
import { CreateInspectionInput } from '@/lib/contracts/inspections/create-inspection.input';
// teste valida casos válidos/inválidos sem importar a action
```

**Critérios de aceite executáveis:** sempre que possível, todo Given/When/Then **P0** do PRD vira **um teste E2E nomeado pelo ID da story**:

```ts
// tests/e2e/inspections.spec.ts
test('US-02 / AC-1: inspetor cria inspeção fim-a-fim', async ({ page }) => {
  // espelha o Given/When/Then literalmente
});
```

> Sem ferramenta extra (Cucumber/Gherkin). Usa o que já está no stack (Zod + Playwright).

**Drift detection.** O script [`../scripts/check-spec-drift.sh`](../scripts/check-spec-drift.sh) compara:

- Server Actions listadas em §6.2 vs. arquivos `export async function` em `app/.../actions.ts` (Variante A) ou `src/interface/web/app/.../actions.ts` (Variante B).
- Domain Events listados em [`02-domain-model.md`](02-domain-model.md) §3.1.4 vs. arquivos em `src/domain/<contexto>/events/` ou `src/contracts/events/`.
- Webhooks listados em §6.3 vs. route handlers em `app/api/webhooks/`.

Falha se: contrato listado na Spec sem arquivo correspondente, ou arquivo de contrato sem entrada na Spec. Gate do `validate.sh` no PR final.

---

## 7. Caching

- **Default:** todo código dinâmico no request time (Next 16 default).
- **`"use cache"`:** declarar explicitamente em funções/páginas estáticas ou semi-estáticas.
- **Tags:** `revalidateTag('inspections')` após mutação.
- **CDN/Edge cache:** `<configuração>`.

---

## 8. Autenticação e autorização

- **Provedor:** `<...>`
- **Sessão:** cookie HTTP-only, SameSite=Lax, Secure em prod.
- **RBAC:** definido no banco, checado em **toda** Server Action e RSC sensível via helper `requireRole(role)`.
- **Sem checagem só no cliente.** Cliente é hint visual; servidor é fonte de verdade.

---

## 9. Observabilidade

| Sinal | Ferramenta | O que capturamos |
|-------|------------|------------------|
| Logs | `pino` estruturado | nível, traceId, userId (hash) |
| Traces | OpenTelemetry | rotas, queries DB, server actions |
| Métricas | OTel + `<destino>` | latência p50/p95/p99, error rate |
| Frontend | `<Sentry/PostHog>` | erros JS, web vitals |

**SLOs:**

| SLO | Alvo |
|-----|------|
| Disponibilidade | 99.5% |
| Latência p95 | < 800ms |
| Error rate | < 0.5% |

---

## 10. Performance budgets

| Métrica | Budget |
|---------|--------|
| LCP p75 | < 2.5s |
| INP p75 | < 200ms |
| CLS p75 | < 0.1 |
| JS inicial (gzipped) | < 150KB |
| Bundle por rota | < 250KB |

CI deve **falhar** o build se ultrapassar.

---

## 11. Segurança

| Item | Decisão |
|------|---------|
| Headers | CSP, HSTS, X-Frame-Options, Referrer-Policy via `proxy.ts` |
| Input | Zod em toda entrada de borda |
| Output | escape automático do React; `dangerouslySetInnerHTML` proibido sem ADR |
| Secrets | `.env`, nunca commitados; gerenciador `<...>` em prod |
| Dependências | `pnpm audit` em CI; Renovate / Dependabot |
| RCE / SSRF | revisão obrigatória em qualquer fetch a URL provida pelo usuário |
| Rate limiting | em rotas públicas e webhooks |
| LGPD | minimização, retenção definida, deleção pelo usuário |

> Mais detalhe em `07-deploy/01-security-checklist.md`.

---

## 12. Estratégia de testes (resumo)

> Detalhe em `06-testing/00-testing-strategy.md`.

- Unit (Vitest): lógica pura, schemas Zod, utilitários.
- Component (Testing Library): comportamento, estados, a11y.
- Integration: Server Actions com DB de teste.
- E2E (Playwright): fluxos críticos do PRD.
- Visual / smoke via browser subagent do Antigravity.

---

## 13. Riscos técnicos

| Risco | Mitigação |
|-------|-----------|
| `<dependência crítica>` | `<plano B>` |
| `<latência DB>` | `<índice / cache>` |
| `<vendor lock-in>` | `<adapter>` |

---

## 14. Faseamento técnico

| Fase | Entrega | Critério de "pronto" |
|------|---------|----------------------|
| Fase 1 | Skeleton + auth | login + RSC funcional + CI verde |
| Fase 2 | Domínio core | CRUD + testes |
| Fase 3 | Observabilidade + perf | dashboards + budgets passando |
| Fase 4 | Hardening + deploy | runbook executado em staging |

---

## 15. Aprovações

| Papel | Pessoa | Status |
|-------|--------|--------|
| Eng lead | `<...>` | ⬜ |
| SRE / DevOps | `<...>` | ⬜ |
| Segurança | `<...>` | ⬜ |
| Product | `<...>` | ⬜ |

---

## Como instruir o agente nesta fase

```
Sua tarefa é gerar a Tech Spec a partir do PRD aprovado em docs/prd/.
Para cada decisão técnica importante, abra um ADR em docs/spec/adr/ usando
o template de ADR. Não escreva código de implementação ainda.
Diagrame em Mermaid quando ajudar.
Marque com 🟡 onde você assumiu algo que precisa de validação humana.
Ao final, gere um Artifact com a Spec + lista de ADRs criados.
```
