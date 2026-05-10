# Story Analysis Template — `docs/sprints/<N>/<story-id>-analysis.md`

> Pré-requisito para paralelizar uma story em múltiplos sub-agentes.
> Ver [`../05-execution/09-parallel-streams.md`](../05-execution/09-parallel-streams.md).
>
> Sem este arquivo, sub-agentes não devem ser lançados em paralelo.

---

## Frontmatter

```yaml
---
story: <story-id>
analyzed: <ISO 8601 UTC>
estimated_hours: <total wall time se sequencial>
parallelization_factor: <ratio sequencial/paralelo, ex.: 2.5>
---
```

---

## 1. Visão geral

> Em ≤ 5 linhas: o que esta story faz, por que se beneficia de paralelismo,
> qual o ganho esperado.

---

## 2. Streams

Um bloco por stream. Mínimo 2 streams.

### Stream A — `<nome>` (ex.: DB Layer)

+ **Scope:** o que este stream entrega.
+ **Files:** lista exata. Glob OK se inequívoco (`lib/db/**`).
+ **Can start:** `imediatamente` | `após Stream <X>`.
+ **Estimated hours:** N
+ **Dependencies:** outros streams ou serviços.
+ **Sub-agente sugerido:** `general-purpose | browser | <skill específica>`.

### Stream B — `<nome>`

…

---

## 3. Coordination Points

### Shared Files

| Arquivo | Stream owner | Outros streams pulam após |
|---------|--------------|---------------------------|
| `lib/types/<domain>.ts` | A (DB) | A commitar primeiro |
| `package.json` | A | A commitar primeiro |

### Sequential Requirements

+ Stream B (UI) depende de tipo gerado por Stream A (DB).
+ Stream C (Tests E2E) depende de UI estar minimamente navegável.

---

## 4. Conflict Risk Assessment

| Risco | Severidade | Mitigação |
|-------|-----------|-----------|
| Stream A e B tocam `lib/db/schema.ts` | alta | A entrega tipos, B só consome |
| Migration race com outra story | média | Lock de migration por sprint |

---

## 5. Parallelization Strategy

+ Lançar A e D imediatamente (sem deps).
+ B e C iniciam quando A commitar tipos.
+ Tests (E) inicia quando UI (B) tem rota navegável.

Diagrama (texto):

```text
A ──┬──> B ──> E
    └──> C
D ─────────────> (independente)
```

---

## 6. Expected Timeline

| Cenário | Wall time | Notas |
|---------|-----------|-------|
| Sequencial (single agent) | <h> | baseline |
| Paralelo (4 streams) | <h> | crítico = stream mais longo |
| Ganho | <%> | inclui overhead de coordenação |

---

## 7. Como instruir cada sub-agente

> 1 bloco por stream. Briefing curto, 100% auto-suficiente.
> Modelo em [`../05-execution/09-parallel-streams.md`](../05-execution/09-parallel-streams.md) §5.

---

## 8. Decisão final

+ [ ] Aprovado para paralelizar (humano).
+ [ ] Não — executar single-agent. Razão: `<...>`
