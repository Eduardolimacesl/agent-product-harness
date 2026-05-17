# Guia da skill `clean-code-pass`

> Carregue sob demanda. Manifesto curto em [`SKILL.md`](./SKILL.md).

Este guia detalha as 10 regras de `AGENTS.md` §4 → "Clean Code" com exemplo, contraexemplo e heurística de detecção. Use como checklist sobre o diff atual.

---

## R1 — Função > 30 linhas → refatorar

**Detectar:** conte linhas não-vazias e não-comentário no corpo da função. > 30 = candidato.

**Por quê:** funções longas escondem múltiplas responsabilidades e custam relê-las inteiras.

**❌ Ruim:**

```ts
async function createInspection(input: unknown) {
  // 50 linhas misturando validação, auth, persistência, revalidate, log
}
```

**✅ Bom:**

```ts
async function createInspection(input: unknown) {
  const data = await parseAndValidate(input);
  const user = await requireUser();
  const inspection = await persistInspection(data, user);
  await revalidateInspections();
  return ok(inspection);
}
```

**Exceção válida:** switch grande sobre union exaustivo (TS força `never`), tabela de lookup, gerador de SQL.

---

## R2 — Argumento booleano em método público

**Detectar:** assinatura de método/função exportada com parâmetro `boolean`.

**Por quê:** no call site, `setActive(true)` não comunica nada. Exige ler implementação.

**❌ Ruim:**

```ts
inspection.setStatus(true);
```

**✅ Bom:**

```ts
inspection.publish();
inspection.unpublish();
```

**Exceção válida:** parâmetro de configuração nomeado em options object — `fetch(url, { cache: true })` é aceitável porque o nome é a documentação.

---

## R3 — Command-Query Separation

**Detectar:** função que retorna valor **e** muda estado (write em DB, mutação de objeto, chamada com side-effect).

**❌ Ruim:**

```ts
function getUser(id: string): User {
  metrics.increment('user.fetched'); // efeito colateral
  return db.users.find(id);
}
```

**✅ Bom:**

```ts
function getUser(id: string): User {
  return db.users.find(id);
}
// caller decide quando emitir métrica
```

**Exceção válida:** caches transparentes (memoização) — efeito é invisível ao caller.

---

## R4 — Sem números/strings mágicos

**Detectar:** literais numéricos ≠ 0/1/-1 em condições, ou strings repetidas em ≥ 2 lugares.

**❌ Ruim:**

```ts
if (inspection.findings.length > 50) throw new Error('too many');
if (status === 'in_progress') { ... }
if (status === 'in_progress') { ... } // de novo
```

**✅ Bom:**

```ts
const MAX_FINDINGS_PER_INSPECTION = 50;
const Status = { Draft: 'draft', InProgress: 'in_progress', Done: 'done' } as const;
type Status = (typeof Status)[keyof typeof Status];

if (inspection.findings.length > MAX_FINDINGS_PER_INSPECTION) throw ...;
if (status === Status.InProgress) { ... }
```

---

## R5 — Early-return preferido a `else` aninhado

**Detectar:** `if ... else { if ... else { ... } }` ou indentação > 3 níveis.

**❌ Ruim:**

```ts
function handle(req: Req) {
  if (req.user) {
    if (req.user.role === 'admin') {
      return doAdmin();
    } else {
      return forbidden();
    }
  } else {
    return unauthorized();
  }
}
```

**✅ Bom:**

```ts
function handle(req: Req) {
  if (!req.user) return unauthorized();
  if (req.user.role !== 'admin') return forbidden();
  return doAdmin();
}
```

---

## R6 — Comentário só explica "por quê", nunca "o quê"

**Detectar:** comentário que parafraseia a próxima linha de código.

**❌ Ruim:**

```ts
// incrementa contador
counter++;

// busca usuário pelo id
const user = await db.users.find(id);
```

**✅ Bom:**

```ts
counter++;

const user = await db.users.find(id);

// Stripe webhook reentra até 3x em 30min — idempotência via event_id na tabela.
if (await events.has(payload.id)) return ok();
```

**Heurística:** se você remover o comentário e um leitor competente entender o código, o comentário era ruído.

---

## R7 — Nomes longos > nomes curtos enigmáticos (sem redundância)

**Detectar:**
- Variáveis de 1-2 letras fora de loops triviais (`i`, `j` em `for` está OK).
- Sufixos redundantes com o tipo (`userObj`, `inspectionList`, `nameStr`).
- Hungarian notation (`strName`, `bActive`).

**❌ Ruim:**

```ts
const iL: Inspection[] = ...
const u = await getUser();
function fmt(d: Date) { ... }
```

**✅ Bom:**

```ts
const inspections: Inspection[] = ...
const user = await getUser();
function formatAsBrazilianDate(date: Date) { ... }
```

---

## R8 — Primitivo obsessivo → Value Object

**Detectar:** `string` que carrega regra (CPF, e-mail, slug, URL, moeda) passada entre funções sem validação.

**❌ Ruim:**

```ts
function sendInvoice(email: string, amount: number) { ... }
sendInvoice('not-an-email', -50); // compila
```

**✅ Bom:**

```ts
class Email {
  private constructor(readonly value: string) {}
  static parse(raw: string): Email {
    if (!/^[^@]+@[^@]+\.[^@]+$/.test(raw)) throw new Error('invalid email');
    return new Email(raw);
  }
}

class Money {
  private constructor(readonly cents: number, readonly currency: 'BRL' | 'USD') {}
  static of(cents: number, currency: 'BRL' | 'USD'): Money {
    if (cents < 0) throw new Error('money cannot be negative');
    return new Money(cents, currency);
  }
}

function sendInvoice(to: Email, amount: Money) { ... }
sendInvoice(Email.parse('a@b.com'), Money.of(5000, 'BRL'));
```

**Exceção válida:** strings opacas (UUIDs, IDs do banco) podem ficar como `Brand<string, 'UserId'>` (branded type) sem classe — peso < ganho.

---

## R9 — DRY com cabeça

**Detectar:** 3+ cópias do mesmo padrão estrutural (não apenas mesmo texto).

**Regra:**
- **2 ocorrências:** tolere. Talvez seja coincidência, não padrão.
- **3 ocorrências:** extraia. Já dá pra ver o padrão real.
- **Abstrair antes do 3º caso:** premature abstraction. Custo > ganho.

**❌ Ruim (premature):**

```ts
// 1 caso de log, e já tem helper
function logBusinessEvent<T>(event: string, payload: T, ctx: Ctx) { ... }
logBusinessEvent('user.created', user, ctx);
```

**❌ Ruim (over-tolerant):**

```ts
// 4 funções repetem o mesmo pattern de auth + validate + persist
async function createInspection(...) { /* 30 linhas */ }
async function updateInspection(...) { /* 30 linhas quase iguais */ }
async function deleteInspection(...) { /* 30 linhas quase iguais */ }
async function archiveInspection(...) { /* 30 linhas quase iguais */ }
```

**✅ Bom:** extraia `withAuthAndValidation(schema, handler)` quando o terceiro caso aparece.

---

## R10 — Erro é dado, não controle de fluxo

**Detectar:** `throw` para erros esperados (validação, regra de negócio, "não encontrado").

**❌ Ruim:**

```ts
async function transfer(from: Account, to: Account, amount: Money) {
  if (from.balance.lessThan(amount)) {
    throw new Error('insufficient balance'); // erro esperado
  }
  // ...
}

try {
  await transfer(a, b, m);
} catch (e) {
  if (e.message === 'insufficient balance') showToast(...);
}
```

**✅ Bom:**

```ts
type TransferError = { code: 'INSUFFICIENT_BALANCE' } | { code: 'ACCOUNT_FROZEN' };
type TransferResult = { ok: true; tx: Tx } | { ok: false; error: TransferError };

async function transfer(...): Promise<TransferResult> {
  if (from.balance.lessThan(amount)) {
    return { ok: false, error: { code: 'INSUFFICIENT_BALANCE' } };
  }
  // ...
  return { ok: true, tx };
}

const result = await transfer(a, b, m);
if (!result.ok) {
  if (result.error.code === 'INSUFFICIENT_BALANCE') showToast(...);
  return;
}
```

`throw` continua sendo a ferramenta certa para: erro de programação (assertion), corrupção de invariante, falha de infra (DB down). O caller não tem o que fazer nesses casos a não ser propagar.

---

## Como rodar a passada (passo a passo)

1. `git diff --name-only main...HEAD` (ou contra a branch base).
2. Filtre `.ts` / `.tsx` excluindo: `*.test.ts`, `*.spec.ts`, `*.generated.ts`, migrations, lockfiles.
3. Para cada arquivo: aplique R1..R10 acima.
4. Monte tabela `arquivo:linha | regra | sugestão` (ver §7 do `SKILL.md`).
5. Reporte. **Não corrija sozinho.** O humano decide quais sugestões virar commit.

---

## Métricas a observar (curadas pelo Knowledge Base)

| Métrica | Alvo | Sinal de problema |
|---------|------|-------------------|
| Violações por 1000 linhas de diff | < 3 | > 10 → harness debt: regra ambígua ou educação faltando |
| % de sugestões aceitas pelo humano | > 70% | < 50% → regra está sendo aplicada errado |
| Falsos positivos reportados | < 5% | > 10% → revisar critério da regra |

Se alguma métrica desviar, abrir story de "saúde do clean-code-pass" na próxima sprint de processo.
