# Bug Template — `docs/sprints/<N>/bug-<NN>-<slug>.md`

> Bug é unidade de trabalho de primeira classe, não "outra story". Quando
> aparece em testing/execução de story já fechada, registra-se separadamente
> com `bug_for:` apontando para a story origem. Inspiração: §"Bug Reporting"
> do `ccpm/references/sync.md`.

---

## Frontmatter obrigatório

```yaml
---
id: bug-<NN>-<slug>
name: "Bug: <descrição curta>"
type: bug
priority: P0 | P1 | P2
size: XS | S | M               # bugs > M são raros — quebrar antes
sprint: <N>
status: todo | doing | review | done
owner: <nome | unassigned>
created: <ISO 8601 UTC>
updated: <ISO 8601 UTC>
depends_on: []
parallel: false                # default false; bugs raramente paralelizam
conflicts_with: []
adr_refs: []
bug_for: <story-id-original>   # OBRIGATÓRIO — story onde o bug foi descoberto
severity: critical | high | medium | low
found_in: testing | staging | production | exec-step-N
github: ?<url>
---
```

---

## 1. Contexto

> Onde, quando e como o bug apareceu. Linka à story original.

```
Story original: <story-id> — <link>
Fase em que apareceu: <discovery|prd|spec|exec|testing|staging|prod>
Data: <YYYY-MM-DD>
Sessão de exec relacionada: <docs/memory/execution/<...>.md>
```

---

## 2. Descrição

O que está quebrado, em 1–3 frases.

---

## 3. Steps to reproduce

```
1. ...
2. ...
3. ...
```

+ **Ambiente:** local | staging | prod
+ **Versão / commit:** `<sha curto>`
+ **Dados de teste:** `<linka fixture/seed>`

---

## 4. Expected vs Actual

+ **Expected:** `<...>`
+ **Actual:** `<...>` (anexar screenshot/log se UI/runtime)

---

## 5. Análise de raiz (preencher antes do fix)

> Diagnóstico técnico. Não é hipótese — é observação verificada.

---

## 6. Critérios de aceite

+ [ ] Bug não reproduz mais com os steps acima.
+ [ ] Comportamento da story original (#<original>) não regrediu — incluir
      teste de regressão no PR.
+ [ ] Telemetria/log que teria capturado este bug está adicionada (se
      aplicável).

---

## 7. Plano de implementação

> Mesma estrutura do Plan Artifact de uma story
> ([`../05-execution/06-plan-artifact-template.md`](../05-execution/06-plan-artifact-template.md)).
> Pause para aprovação humana antes de tocar código.

---

## 8. Riscos

```
[ex.: "o fix muda comportamento de <X> que outras stories dependem"]
```

---

## 9. Definition of Done

+ [ ] AC verdes
+ [ ] Teste de regressão escrito
+ [ ] PR aprovado
+ [ ] Issue original (#<bug_for>) atualizada com link para o fix
+ [ ] Smoke em staging

---

## 10. Como instruir o agente

```
Trabalhe no bug <id>. Story original: <bug_for>.
1. Reproduza localmente seguindo §3.
2. Antes de qualquer fix: complete §5 (análise de raiz) e produza Plan
   Artifact (§7). PAUSE para aprovação humana.
3. Após aprovado, escreva o teste de regressão PRIMEIRO (TDD para bug).
4. Implemente o fix mínimo. Não refatore além do necessário.
5. Rode pnpm typecheck && pnpm lint && pnpm test:unit.
6. Atualize a story original com nota: "Bug #<id> corrigido em <PR>".
7. Não rode git push. Não toque em arquivos fora do plano.
```

---

## Anti-padrões

+ ❌ Bug sem `bug_for` (perde rastreabilidade da regressão).
+ ❌ Fix sem teste de regressão (bug volta na próxima refatoração).
+ ❌ Refatorar "de quebra" durante o fix (escopo escapando — abrir story
  separada).
+ ❌ Bug `size = L` sem quebrar (geralmente é múltiplos bugs disfarçados).
