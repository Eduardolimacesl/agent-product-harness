# Spec Drift Report — `<story-id>`

> `docs/sprints/<N>/<story-id>-drift.md`. Corpo ≤ 25 linhas.

**Story:** `<id>` · **Sprint:** `<N>` · **Aberto:** `<ISO 8601 UTC>` · **Severidade:** `low|medium|high`

## 1. Tipo
- [ ] Contradição direta · [ ] Lacuna explícita · [ ] Premissa falsa
## 2. Evidência (path:linha, ≤5 linhas)
```
<recorte código + recorte Spec, ou comando + saída>
```
## 3. Decisão pedida (pergunta fechada)
> `<ex.: "idempotência por event_id ou (event_id, provider)?">`
## 4. Opções (uma linha cada)
- **A.** Corrigir Spec + ADR retroativa — atrasa `<x>h`.
- **B.** Ajustar story para a realidade — `<x>h`, Spec fica inválida.
- **C.** Cancelar — abre `<new-story-id>`.
## 5. Recomendação do agente
> `<opção + motivo, 1 linha>`
## 6. Decisão (preencher na resolução)
Por `<nome>` · Opção `A|B|C` · ADR/edição `<link>` · Retomou `<ISO 8601 UTC>`
