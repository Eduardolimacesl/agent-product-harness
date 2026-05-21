# Reference Mining (CodeRAG) — fase opcional entre Spec e Sprint Plan

> **OPT-IN.** Default = desligado. Ative só quando o produto se beneficiar
> (Li et al. 2025, DeepCode §2.3 — modelos médios têm knowledge gaps que
> CodeRAG fecha; modelos de fronteira não precisam).

## 1. Quando ativar

Sinais de que vale o overhead:

- Produto de **domínio específico** com convenções não-óbvias (compliance
  setorial, protocolos proprietários, integração com APIs raras).
- **Modelo médio** declarado no `AGENTS.md §0` (não Sonnet 4.6+ / GPT-5 /
  Gemini 2.5 Pro).
- Eng lead identifica ≥1 repositório de referência open-source que
  resolve problema análogo de forma comprovada.

Sinais de que NÃO ativar:

- Stack majoritariamente padrão (Next.js + Postgres CRUD).
- Modelo de fronteira já cobre o domínio.
- Prazo curto — Reference Mining adiciona dias à Spec.

## 2. O que produz

Um manifest versionado em `docs/spec/04-references.json` listando:

- Repositórios indexados (URL, commit fixado, licença, escopo).
- Tuplas `(source_file, target_component, relationship_type, confidence, context)`
  — links explícitos entre arquivo de referência e componente do produto.

O agente, em stories futuras, consulta o manifest e cita as tuplas no
Plan Artifact (§7 ADRs aplicáveis, ou §6 Skills externas).

## 3. Schema do manifest

[`../templates/spec/references-template.json`](../templates/spec/references-template.json).
Validado por schema em `validate.sh` quando o arquivo existe.

```json
{
  "$schema": "https://agent-product-harness.dev/schemas/spec-references.json",
  "enabled": true,
  "generated_at": "2026-01-15T10:00:00Z",
  "repos": [
    {
      "name": "stripe-go",
      "url": "https://github.com/stripe/stripe-go",
      "commit": "f7c1d2e3...",
      "license": "MIT",
      "scope": "webhooks de pagamento; idempotência por event_id"
    }
  ],
  "tuples": [
    {
      "source_file": "stripe-go/webhook/webhook.go#L42-L67",
      "target_component": "app/api/webhooks/stripe/route.ts",
      "relationship_type": "pattern",
      "confidence": "high",
      "context": "verificação HMAC + tolerância de timestamp + lookup idempotente em webhook_events"
    }
  ]
}
```

### Campos

| Campo | Notas |
|---|---|
| `enabled` | `false` desativa toda a fase (default) |
| `repos[*].commit` | **commit SHA fixado** — nunca tag/branch (drift silencioso) |
| `repos[*].license` | apenas valores na allowlist de §4 |
| `tuples[*].relationship_type` | `pattern` \| `api-shape` \| `algorithm` \| `data-model` |
| `tuples[*].confidence` | `high` \| `medium` \| `low` — `low` exige revisão humana extra |

## 4. Allowlist de licenças

Compatíveis com produto comercial (use sem ressalvas):

- `MIT`
- `Apache-2.0`
- `BSD-2-Clause`
- `BSD-3-Clause`
- `ISC`
- `0BSD`

**Bloqueadas** por default — exigem ADR específico se quiser usar:

- `GPL-*` (todas variantes)
- `AGPL-*`
- `LGPL-*`
- `SSPL-*`
- `BUSL-*` (Business Source License)
- ausência de LICENSE (assume "all rights reserved")

`validate.sh` falha se `repos[*].license` está fora da allowlist e não há
ADR justificando.

## 5. Hard rule — atribuição obrigatória

Sempre que código do produto deriva (estrutura, algoritmo, comentário,
nome de função) de uma tupla do manifest, **registrar atribuição inline**:

```ts
// Padrão derivado de stripe-go/webhook/webhook.go#L42-L67 (MIT)
// ver docs/spec/04-references.json tuple #3
export async function verifyStripeWebhook(req: Request) { ... }
```

Sem atribuição: violação de licença (mesmo em MIT). Em diff sem cabeçalho
de atribuição em arquivo gerado a partir de tupla, o reviewer rejeita.

## 6. Quando atualizar o manifest

- **Refresh semestral:** revisitar commit SHAs; bumpar para versão atual
  e ADR registrando as mudanças relevantes.
- Após **incidente** relacionado a código derivado: revisar a tupla,
  considerar remover.
- Quando o produto **substitui** o uso da referência por solução
  in-house: remover a tupla e atualizar atribuição.

## 7. Integração com o pipeline

| Fase | Reference Mining |
|---|---|
| Discovery | pergunta opt-in: "produto vai usar CodeRAG?" |
| PRD | sem efeito |
| Spec | gera o manifest se opt-in |
| Sprint planning | sem efeito |
| Execução de story | agente consulta manifest no bootstrap mínimo se houver tupla relacionada |
| Testes | mesmos gates |
| Deploy | LICENSE consolidada inclui atribuições agregadas |

## 8. Não-ativação por default no bootstrap

`SKILL.md §A` **não** cria `docs/spec/04-references.json`. Bootstrap
imprime instrução opcional: *"Se quiser ativar Reference Mining (Li et
al. 2025, §2.3), crie `docs/spec/04-references.json` com `enabled: true`
seguindo [`../03-spec/06-reference-mining.md`](references/03-spec/06-reference-mining.md)
durante a Spec."*

## 9. Anti-padrões

- ❌ Manifest sem `commit` fixado (`commit: "main"`) — drift silencioso.
- ❌ Tupla com `confidence: low` sem revisão humana adicional registrada
  em ADR.
- ❌ Copiar código de repo GPL "porque é só inspiração" — abre ADR ou não use.
- ❌ Atribuição em commit message apenas — precisa estar no arquivo gerado.
- ❌ Ativar Reference Mining em produto CRUD padrão "porque parece útil".
