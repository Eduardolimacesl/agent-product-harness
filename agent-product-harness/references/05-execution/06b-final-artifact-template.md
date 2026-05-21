# Final Artifact Template — Gate 2 de execução

> Artefato que o agente principal produz **ao terminar** uma story, antes
> de pedir o Gate 2 (review do diff pelo humano). Complementa o Plan
> Artifact ([`06-plan-artifact-template.md`](06-plan-artifact-template.md))
> de Gate 1.

## Quando produzir

Sempre que o Plan Artifact foi obrigatório. Para tarefas menores (1–2
arquivos, sem domínio sensível), 5 linhas inline no chat bastam.

## Estrutura obrigatória

```markdown
# Final Artifact — <story-id>

**Story:** docs/sprints/<n>/<story-id>.md
**Sessão:** <YYYY-MM-DD>
**Plan Artifact:** <link/anchor ao plan>

---

## 1. Sumário (≤ 5 linhas)

<o que mudou e por quê — sem repetir o plano>

## 2. Arquivos alterados

| Arquivo | Operação | 1 linha de explicação |
|---------|----------|------------------------|
| ... | criar/modificar/remover | ... |

## 3. Como testar

```bash
# comandos exatos, copy-paste
pnpm typecheck && pnpm lint && pnpm test
pnpm test:e2e -- <spec>
```

## 4. Evidence Bundle

> Obrigatório. Sem este bloco, sem Gate 2. (Ning et al. 2026, §5.2.2)

### 4.1 Checks rodados

- [ ] `pnpm typecheck` — <verde / output relevante>
- [ ] `pnpm lint` — <verde / output relevante>
- [ ] `pnpm test:unit` — <n passados / n total>
- [ ] `pnpm test:integration` — <n passados / n total>
- [ ] `pnpm test:e2e` — <spec rodada / resultado>
- [ ] `bash <skill>/.../validate.sh` — saiu 0

### 4.2 Suposições preservadas

> Invariantes que o código assume e mantém — auth, schema, contratos
> existentes, idempotência, ordem de eventos. Liste o que esta story
> tocou e provou que continua valendo.

- <invariante 1> — provado por <teste / verificação>
- <invariante 2> — ...

### 4.3 Regiões NÃO testadas

> **Obrigatório.** Não pode ficar vazio. Se cobertura é completa, escreva
> "Cobertura completa para esta story" + justificativa de 1 linha. Se há
> lacuna, declare-a — não esconder lacuna é o ponto da seção.

- <região 1> — motivo (ex.: depende de provider externo sem mock confiável)
- <região 2> — ...

### 4.4 Riscos remanescentes

| Risco | Severidade | Mitigação proposta para futuro |
|-------|------------|--------------------------------|
| ... | A/M/B | ... |

## 5. Próximo passo sugerido (1 linha)

<o que faz sentido fazer a seguir — para alimentar próxima story do sprint>
```

## Por que Evidence Bundle?

O Plan Artifact (Gate 1) declara *intenção*; o Final Artifact (Gate 2)
declara *evidência*. Hoje o output esperado já cobre sumário, arquivos,
como testar e riscos — falta o explícito sobre o que **não** foi coberto.

Sem §4.3, "está pronto" vira asserção. Com §4.3 obrigatório, o humano
revisa o que **falta** — e essa é a leitura que alimenta priorização de
testes futuros e tornaria o `_summary.md` da Sprint mais honesto.

## Anti-padrões

- ❌ §4.3 vazia ou "n/a" sem justificativa.
- ❌ Sumário em §1 que reproduz o plano — esta seção é resultado, não plano.
- ❌ "Como testar" sem comandos concretos.
- ❌ Misturar Plan Artifact e Final Artifact no mesmo documento — gates
  diferentes, momentos diferentes.

## Integração com `_summary.md` da Sprint

Quando a sprint fecha, o Smoke Run (§8 de
[`05-phase-summary-template.md`](05-phase-summary-template.md)) consome
agregando os Evidence Bundles das stories: a soma das "Regiões NÃO
testadas" alimenta priorização de testes para a próxima sprint.
