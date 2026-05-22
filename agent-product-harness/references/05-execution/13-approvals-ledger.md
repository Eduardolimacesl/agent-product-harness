# Approvals Ledger — HITL como estado durável

> Cada aprovação/rejeição/exceção humana vira **estado durável do harness**,
> não evento efêmero (Ning et al. 2026, §5.2.5). Registro em
> `docs/memory/approvals.jsonl`. Aprovações com `becomes_rule: true`
> alimentam a evolução da política — não são só log.

## 1. Princípio

Hoje, quando o agente pede HITL em full-access, a aprovação acontece no
chat e some. Resultado: a mesma decisão é re-deliberada todo dia, e
nenhuma regra é capturada para reutilização.

Ledger resolve isso registrando cada decisão com:

- **evidência mostrada** ao humano no momento da aprovação,
- **riscos surfaçados**,
- **decisão** + autor,
- e — quando aplicável — **regra reutilizável** que essa decisão cria.

O `becomes_rule` é o link com **evolução de política**: aprovações que
viram regra são promovidas para o `AGENTS.md` do produto (via PR) ou para
a tabela de tiers em
[`12-permission-tiers.md`](12-permission-tiers.md).

## 2. Quando registrar

Toda ação que dispara HITL — todo gate full-access (`12-permission-tiers.md`
§3). Em particular:

- `git push`, history-rewriting git ops, deploy, publicação de pacote.
- `gh` writes (issue/PR create, comment).
- Leitura/uso de `.env*`, credenciais.
- Cópia de dados de produção (mesmo com máscara).
- Escrita na Knowledge Base.
- Mudanças no `AGENTS.md`.
- Excepcionalmente: aprovações de Plan Artifact (Gate 1) que envolvem
  ação posteriormente full-access — registre a aprovação no ledger
  *quando a ação ocorre*, não quando o plano é aprovado.

## 3. Formato

JSONL — uma entrada por linha em `docs/memory/approvals.jsonl`.

```json
{
  "ts": "2026-01-15T16:00:00Z",
  "story_id": "billing-003",
  "tier": "full-access",
  "action_proposed": "git push de release v0.5.0 com migration de schema billing",
  "evidence_shown": "diff de migration + saída de dry-run + smoke verde em staging",
  "risks_surfaced": "downtime curto (<1min) na aplicação da migration; sem rollback automático",
  "decision": "approved-with-condition",
  "decided_by": "eduardo",
  "condition": "rodar smoke pós-deploy em 5min; ROLLBACK manual via runbook se houver alerta",
  "becomes_rule": "deploys com migration de schema billing sempre rodam smoke pós-deploy em 5min"
}
```

### Campos

| Campo | Tipo | Obrigatório | Notas |
|---|---|---|---|
| `ts` | ISO 8601 UTC | sim | timestamp da aprovação |
| `story_id` | string | sim (se ação tem story) | omitir só em manutenção fora de story |
| `tier` | enum | sim | `full-access` na maioria; `sandbox-edit` se exceção |
| `action_proposed` | string | sim | descrição em 1 linha da ação |
| `evidence_shown` | string | sim | o que o agente apresentou ao humano |
| `risks_surfaced` | string | sim | riscos identificados no momento |
| `decision` | enum | sim | `approved` \| `rejected` \| `approved-with-condition` |
| `decided_by` | string | sim | quem aprovou |
| `condition` | string | só se `approved-with-condition` | descrição da ressalva |
| `becomes_rule` | string | opcional | regra reutilizável que essa decisão cria |

## 4. Schema canônico

[`../templates/approval-entry-schema.json`](../templates/approval-entry-schema.json).
`telemetry-append.sh` (futuro: `approvals-append.sh`) valida antes de gravar.

## 5. Promoção de regras

Quando uma entrada do ledger tem `becomes_rule` preenchido, a regra é
**candidata** a virar política reusável:

1. O agente principal (na próxima Plan Artifact do tipo afetado) cita a
   entrada do ledger.
2. Se a regra se confirma em ≥2 decisões consistentes, abre PR
   promovendo para uma das duas casas:
   - **`AGENTS.md` do produto** (gates, allowlist por tier);
   - **`references/05-execution/12-permission-tiers.md`** (caso a regra
     redefina o tier de um comando).
3. Aprovação do PR fecha o loop. A entrada do ledger ganha campo
   `promoted_to: <path>:<commit>` em anotação manual.

## 6. Auditoria

`telemetry-report.sh` (v0.3+) inclui contagem de:

- Entradas com `becomes_rule != null` — *quantas decisões geraram regra*.
- Entradas com `becomes_rule != null` **sem** `promoted_to` — *quantas regras
  potenciais não foram promovidas* (write-only smell).

Threshold sugerido: se ≥ 5 entradas com `becomes_rule` ficam não
promovidas por > 2 sprints, abrir story de "promoção de políticas" na
sprint de saúde do harness.

`07-deploy/01-security-checklist.md` ganha auditoria periódica das
decisões `rejected` — para confirmar que a rejeição foi seguida (sem
re-tentativa silenciosa).

## 7. Integração com telemetria

Aprovações **também** emitem `human_intervention` na telemetria
([`11-telemetry-protocol.md`](11-telemetry-protocol.md) §3), com
`data.tipo = "approval"` e `data.tier = "full-access"`. A telemetria é
agregação; o ledger é o registro estruturado da decisão em si.

## 8. Privacidade

- `evidence_shown` e `condition` podem mencionar paths/IDs, mas
  **nunca** valores de variáveis sensíveis (tokens, hashes de senha,
  emails de usuário). Use placeholders se preciso.
- `decided_by` é nome ou handle; não use e-mail completo.

## 9. Anti-padrões

- ❌ Aprovação "verbal" sem entrada no ledger. Verbal não persiste.
- ❌ `evidence_shown: "diff e logs"` — vago. Linkar ao Artifact ou
  comando específico.
- ❌ `becomes_rule` preenchido com fortuna ("sempre cuidado com push") —
  formule como regra acionável.
- ❌ `decision: "approved-with-condition"` sem `condition` preenchido.
- ❌ Reutilizar decisão antiga ("já aprovaram parecido ano passado") —
  full-access é por-ação, não por-precedente.
