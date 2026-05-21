## Change Contract

> Obrigatório para mudanças `minor` e `major` no harness (semver do README §"Versioning").
> Mudanças `patch` (typo, clarificação, link quebrado) dispensam o contrato — apague esta seção.
>
> Referência completa: [`references/12-harness-evolution/00-change-contract.md`](../../agent-product-harness/references/12-harness-evolution/00-change-contract.md).

**Componente modificado:**
<!-- qual referência/template/script/regra muda -->

**Modo de falha que ataca:**
<!-- qual problema recorrente isto resolve; idealmente com evidência da telemetria
     (taxa de plan-rejection, gates falhados, ratio de spec-drift, etc.) -->

**Melhoria prevista:**
<!-- o que esperamos que melhore — concreto e mensurável quando possível -->

**Invariantes que devem ser preservadas:**
<!-- o que NÃO pode quebrar; ex.: bootstrap mínimo, gates de CI,
     numeração contígua de princípios, regras de sandbox -->

**Como falsificar:**
<!-- qual teste/uso provaria que a mudança piorou; um caso concreto -->

**Rollback:**
<!-- como reverter; impacto em produtos já bootstrapados -->

---

## Sumário da mudança

<!-- 1–3 linhas. -->

## Checklist

- [ ] Componente atualizado segue o budget de linhas dos templates do harness.
- [ ] Cross-references em `references/` (incluindo `00-architecture-and-flow.md`)
      atualizadas se aplicável.
- [ ] `validate.sh` ainda passa em produto-piloto bootstrapado.
- [ ] CHANGELOG/README §Versioning bump apropriado.
