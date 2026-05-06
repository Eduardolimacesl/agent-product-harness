# Protocolos — MCP, Server Actions, Webhooks e Prep para A2A

> Implementa a recomendação P0 da análise do paper de Zhou et al. (2026), Seção 5: **protocolos externalizam estrutura de interação** — invocation grammar, lifecycle semantics, permission/trust boundaries e discovery metadata. Sem esta camada, interação entre agente, tools e serviços vira "exercício frágil de prompt-following" (§5.1).
>
> Complementa (não substitui) `AGENTS.md`, `02-nextjs-conventions.md` e `07-deploy/01-security-checklist.md`. Quando este documento conflita com chat efêmero, **prevalece este documento**.

---

## 1. O que é um protocolo neste harness

Um **protocolo** é um contrato de interação com 4 propriedades:

1. **Invocation grammar** — schema tipado dos argumentos e do retorno.
2. **Lifecycle semantics** — estados (idle → in-flight → completed/failed), idempotência, retries.
3. **Permission boundaries** — quem pode chamar, com que credencial, sob que escopo.
4. **Discovery metadata** — registry consultável (manifest do servidor, capability card, OpenAPI/JSON Schema).

Tudo que cruza fronteira de processo (agente → tool, agente → serviço, serviço → serviço) **deve** ter os 4 elementos declarados ou referenciados em algum lugar do repo.

---

## 2. Famílias de protocolo deste harness

| Família | Onde aparece | Ferramenta | Status no harness |
|---------|--------------|------------|-------------------|
| **Agent ↔ Tool** | agente chamando MCP server (Postgres, Slack, Figma, browser) | MCP (Anthropic) | ⚠️ adotar quando precisar |
| **Agent ↔ Serviço interno** | Server Action chamada de Server/Client Component | Next.js Server Actions + Zod | ✅ obrigatório |
| **Serviço ↔ Serviço externo** | webhook recebido de Stripe, GitHub, etc. | Route Handler + HMAC | ✅ obrigatório |
| **Agent ↔ Agent** | delegação entre agentes em workspaces diferentes | A2A (Google) | 🔜 prep apenas |
| **Agent ↔ User** | streaming de eventos para UI | AG-UI / Vercel AI SDK | 🔜 quando o produto tiver UI agêntica |

---

## 3. MCP (Model Context Protocol) — agente ↔ tool

### 3.1 Quando usar

Sempre que o agente precisar acessar um sistema externo de forma estruturada: banco de dados, Slack, Figma, Linear, Sentry, navegador, filesystem fora do workspace. **Não** invente client HTTP no agente nem cole credenciais em chat — instale um servidor MCP.

### 3.2 Registry obrigatório

Manter `mcp/registry.json` versionado no repo:

```json
{
  "$schema": "https://modelcontextprotocol.io/schemas/registry.json",
  "version": 1,
  "servers": [
    {
      "name": "postgres",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "purpose": "leitura/escrita controlada no DB de desenvolvimento",
      "scope": "dev-only",
      "auth": "env:DATABASE_URL_DEV",
      "approved_by": "ADR-NNNN",
      "checksum": "sha256:<hash do binário publicado>"
    }
  ]
}
```

Regra: **só entram servers listados no registry**. Adição passa por PR + ADR.

### 3.3 Trust boundaries

- ❌ Servidor MCP **nunca** roda contra DB de produção em sessão de desenvolvimento.
- ❌ Servidor MCP **nunca** recebe token de produção do gerenciador de secrets.
- ✅ Tokens de MCP são curtos (≤ 24h) e escopados por ambiente.
- ✅ Sandbox do Antigravity permanece ON mesmo com MCP — o servidor é processo separado, não bypass.
- ✅ Logs de chamadas MCP entram em `docs/memory/execution/<sessão>.md` (resumo, sem payload sensível).

### 3.4 Riscos específicos (§8.4 do paper — protocol spoofing)

> "Manifests forjados de tools ou endpoints manipulados podem causar ações não autorizadas sob aparência de interação legítima."

Mitigação:

- [ ] Lista de servers permitidos é a **fonte de verdade** — Antigravity bloqueia o que não está listado.
- [ ] Origem do binário é verificada (checksum + repositório oficial).
- [ ] Auditoria mensal: comparar `mcp/registry.json` com servers efetivamente carregados no workspace.

---

## 4. Server Actions como protocolo interno

Toda Server Action é um **protocolo agente ↔ serviço**. Hoje [02-nextjs-conventions.md §5](./02-nextjs-conventions.md) já exige Zod + auth + revalidate — este documento **eleva** essa convenção a status formal de protocolo.

### 4.1 Contrato obrigatório

```ts
// app/(app)/inspections/actions.ts
'use server';

import { z } from 'zod';
import { revalidateTag } from 'next/cache';
import { auth } from '@/lib/auth';
import { db } from '@/lib/db/client';

// 1. SCHEMA — invocation grammar
const CreateInspection = z.object({
  buildingId: z.string().uuid(),
  notes: z.string().max(2000).optional(),
});

// 2. RETURN SHAPE — lifecycle semantics tipadas
type Result<T> =
  | { ok: true; data: T }
  | { ok: false; code: 'UNAUTHORIZED' | 'VALIDATION' | 'CONFLICT' | 'INTERNAL'; errors?: unknown };

export async function createInspection(
  input: z.infer<typeof CreateInspection>,
): Promise<Result<{ id: string }>> {
  // 3. PERMISSION — auth check antes de qualquer efeito
  const user = await auth();
  if (!user) return { ok: false, code: 'UNAUTHORIZED' };

  // 4. VALIDAÇÃO DE BORDA
  const parsed = CreateInspection.safeParse(input);
  if (!parsed.success) {
    return { ok: false, code: 'VALIDATION', errors: parsed.error.flatten() };
  }

  // 5. EFEITO + INVALIDAÇÃO
  const row = await db.inspections.create({ ...parsed.data, userId: user.id });
  revalidateTag('inspections');
  return { ok: true, data: { id: row.id } };
}
```

### 4.2 Discovery metadata

Cada feature mantém `app/<feature>/contracts.ts` exportando os schemas Zod das suas actions. Isto é o equivalente do "capability card":

```ts
// app/(app)/inspections/contracts.ts
export const InspectionContracts = {
  create: CreateInspection,
  update: UpdateInspection,
  delete: DeleteInspection,
} as const;
```

Skills internas (ver [04-skill-template.md](./04-skill-template.md)) podem importar destes contratos para gerar testes, formulários ou clients tipados — sem reinventar.

### 4.3 Auditoria

Toda Server Action loga: `actor.id`, `action`, `target`, `result.code`, `duration_ms`. Logger configurado em `lib/logger.ts` com **redaction** automática (ver [01-security-checklist.md §9](../07-deploy/01-security-checklist.md)).

---

## 5. Webhooks externos — serviço ↔ serviço

Webhooks são protocolos **assimétricos**: outro sistema dispara, nós recebemos. Riscos: replay, spoofing, injeção.

### 5.1 Contrato obrigatório

```ts
// app/api/webhooks/stripe/route.ts
import { NextResponse } from 'next/server';
import { verifyStripeSignature } from '@/lib/webhooks/stripe';

export async function POST(req: Request) {
  const body = await req.text();
  const sig = req.headers.get('stripe-signature');

  // 1. ASSINATURA HMAC
  const event = verifyStripeSignature(body, sig);
  if (!event) return new NextResponse('invalid signature', { status: 401 });

  // 2. ANTI-REPLAY — timestamp ≤ 5 min
  if (Math.abs(Date.now() / 1000 - event.created) > 300) {
    return new NextResponse('stale', { status: 401 });
  }

  // 3. IDEMPOTÊNCIA — chave única por event.id
  const seen = await db.webhookEvents.findUnique({ where: { id: event.id } });
  if (seen) return NextResponse.json({ ok: true, deduped: true });

  await db.webhookEvents.create({ data: { id: event.id, payload: event } });

  // 4. PROCESSAMENTO
  await handleStripeEvent(event);
  return NextResponse.json({ ok: true });
}
```

### 5.2 Checklist de webhook

- [ ] HMAC verificado **antes** de qualquer parsing do payload.
- [ ] Timestamp validado contra janela ≤ 5 min.
- [ ] `event.id` registrado para deduplicação.
- [ ] Resposta 2xx **só** após persistir confirmação (ou após enfileirar com garantia de entrega).
- [ ] Logs sem corpo cru — apenas `event.type`, `event.id`, `result`.

---

## 6. Prep para A2A (Agent-to-Agent)

Hoje não usamos. **Não implementar agora** — só deixar a porta destrancada.

### 6.1 Quando vai chegar

Dois sinais de que precisamos:

1. Antigravity Mission Control passar a coordenar agentes em workspaces diferentes que **trocam mensagens** (não só compartilham arquivos via git).
2. Surgir necessidade de delegação para agente de outro time/produto que **não compartilha o repositório**.

### 6.2 Princípios que já fixamos para o futuro

- **Identidade do agente:** todo agente assina handoffs com identidade verificável (DID, JWT assinado por chave do workspace, ou equivalente). Nunca "agente anônimo".
- **Capability negotiation:** agente que recebe handoff anuncia quais skills aceita executar. Não aceita por default tudo.
- **Audit trail:** toda mensagem A2A entra em `docs/memory/handoffs/` com correlationId para rastrear cadeia.
- **Boundary humana:** handoffs que envolvem `$$`, dados pessoais, deploy ou auth **sempre** passam por gate humano, mesmo entre agentes "confiáveis".

### 6.3 O que **não** fazer enquanto não for hora

- ❌ Inventar protocolo proprietário de comunicação entre agentes.
- ❌ Permitir que agente escreva diretamente em workspace de outro produto.
- ❌ Compartilhar Knowledge Base entre produtos sem curadoria.

Quando chegar a hora, abrir ADR `ADR-NNNN: adoção de A2A para handoff cross-workspace` e atualizar este documento.

---

## 7. Prep para AG-UI / Vercel AI SDK (agente ↔ user)

Quando o **produto** (não o ambiente de dev) tiver superfície agêntica voltada para o usuário final — copilot, chat, geração assistida — o protocolo agente↔UI deve seguir AG-UI ou Vercel AI SDK (`useChat`, `streamText`, RSC streaming). Por enquanto, fora de escopo.

Antecipar apenas:

- Streaming de eventos é **append-only** — UI nunca regrava histórico do servidor.
- Tool calls expostas ao usuário **respeitam** a allowlist do `AGENTS.md` (não há tools "user-only" que escapam do gate).
- PII em prompts **nunca** vai para Knowledge Base do agente do produto.

---

## 8. Como o agente trata este documento

1. Antes de criar Server Action, conferir o contrato da §4.
2. Antes de criar Route Handler, decidir: é webhook (§5)? endpoint público? — sem essa classificação, **parar** e perguntar.
3. Antes de adicionar dependência em servidor MCP, conferir registry da §3.2 e abrir ADR se for novo.
4. Quando vir referência a "A2A" ou "AG-UI" em discussão, citar §6 ou §7 e **não** implementar sem decisão arquitetural.

---

## 9. Anti-padrões

- ❌ `fetch` direto a serviço externo a partir do agente sem servidor MCP intermediário.
- ❌ Server Action sem retorno tipado (`Promise<unknown>` ou `Promise<any>`).
- ❌ Webhook que aceita request **antes** de verificar HMAC.
- ❌ Adicionar servidor MCP por convicção pessoal — sempre por ADR.
- ❌ Reaproveitar token de produção em servidor MCP de dev.
- ❌ Confundir skill com protocolo: skill **usa** protocolo; protocolo **não usa** skill.

---

## 10. Glossário

| Termo | Definição operacional |
|---|---|
| **Tool** | função invocável pelo agente que produz efeito ou retorna dado. Tem manifest (nome, descrição, schema). |
| **Protocol** | regra de interação entre dois processos. Diz **como** uma tool é invocada com segurança. |
| **MCP server** | processo separado que expõe um conjunto de tools via Model Context Protocol. |
| **Capability card** | metadata de discovery — schema, escopo, exemplos. Para Server Actions, mora em `contracts.ts`. |
| **Handoff (A2A)** | passagem de tarefa de um agente para outro, com mensagem assinada e estado correlato. |
