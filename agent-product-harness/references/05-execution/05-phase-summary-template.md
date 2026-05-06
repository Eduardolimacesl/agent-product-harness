# Phase Summary Template — `docs/memory/<fase>/_summary.md`

> Cada fase termina com um `_summary.md` em sua pasta de memória. Este arquivo é o **gate de transição**: sem ele, a próxima fase não começa.

> Se o `_summary.md` não existe ou está incompleto, o agente recusa avançar (veja [`SKILL.md`](../../SKILL.md) §B e [`00-context-protocol.md`](00-context-protocol.md)).

---

## Por que existe

Resumos de fase resolvem três problemas:

1. **Continuidade entre sessões** — o agente da fase seguinte não relê o histórico de chat; lê o `_summary.md`.
2. **Auditoria** — o humano consegue, em 2 minutos, saber o que foi decidido sem reabrir tudo.
3. **Knowledge Base candidata** — o que aparece em `_summary.md` repetidamente vira padrão promovido para a Camada 1.

---

## Estrutura obrigatória

Cada `_summary.md` segue este esqueleto. Campos vazios são proibidos: ou tem conteúdo, ou está marcado `n/a` com justificativa.

```markdown
# Resumo de <fase> — <YYYY-MM-DD>

**Owner da fase:** <nome>
**Sessões envolvidas:** <links para logs em docs/memory/execution/ se aplicável>
**Status de saída:** ✅ aprovado | 🟡 aprovado com ressalvas | ❌ retornou para fase anterior

## 1. O que foi decidido

> Liste decisões em forma de afirmação. Uma por linha. Vincule ao artefato/ADR onde a decisão vive.

- <decisão 1> → [ADR-0001](../../spec/adr/0001-...md)
- <decisão 2> → seção 4.2 do PRD
- ...

## 2. O que ficou em aberto (carregar para próxima fase)

> Itens que dependem da próxima fase para resolver. Cada um vira input do bootstrap da fase seguinte.

- <item 1> — <quem resolve, quando>
- <item 2> — <...>

## 3. ADRs criados nesta fase

| ADR | Título | Status |
|-----|--------|--------|
| 0001 | <título> | accepted |

> Se nenhum ADR foi criado em uma fase que tipicamente os produz (Spec, Design Foundations), justifique aqui.

## 4. Padrões salvos na Knowledge Base

- <padrão 1> — link/snippet
- <padrão 2> — ...

> Se nenhum padrão entrou na KB, escreva por quê. KB curada > KB cheia.

## 5. Métricas / artefatos verificáveis

> Para fases que produzem artefato verificável: link e como verificar.

- Discovery: brief ✅ aprovado pelo sponsor em <data>
- PRD: critérios Given/When/Then todos preenchidos
- Design Foundations: screenshot do starter kit em <link>
- Spec: tech-spec aprovado, ADRs accepted
- Sprint planning: sprint-plan.md com DoR satisfeito em todas as stories

## 6. Avisos para o próximo agente

> O que economiza tempo ou evita armadilha. Curto e específico.

- <aviso 1>
- <aviso 2>

## 7. Harness debt observada

> Padrões/lacunas que apareceram aplicando o harness. Viram PR contra a skill.

- <observação 1> — proposta
- <observação 2> — ...
```

---

## Tamanho-alvo

**≤ 200 linhas.** Se passou disso, está consolidando demais — separe em arquivos auxiliares dentro da mesma pasta de memória.

---

## Por fase, o que costuma entrar

| Fase | Decisões típicas | ADR esperado? |
|------|-----------------|---------------|
| Discovery | go/pivot/no-go, hipótese travada, métrica primária | não |
| PRD | escopo v1, critérios de aceite, plano de lançamento | não (raramente) |
| Design Foundations | paleta, tipografia, tokens, princípios UX | sim, se decisão polêmica (ex.: dark-first) |
| Spec | stack, contratos, modelo de domínio | **sim, sempre** |
| Sprint planning | stories selecionadas, capacidade, riscos da sprint | não |
| Execução (por story) | log de sessão em arquivo separado, não em `_summary.md` | situacional |
| Deploy | versão promovida, smoke pós-deploy, rollback usado? | não |

---

## Anti-padrões

- ❌ Copiar e colar o documento da fase no `_summary.md`. → o resumo é **destilado**, não duplicação.
- ❌ Deixar seções vazias "para preencher depois". → ou está pronto, ou não está.
- ❌ Escrever em prosa narrativa (>200 linhas). → vira ilegível na próxima sessão.
- ❌ Misturar resumos de múltiplas fases no mesmo arquivo. → 1 arquivo por fase, sempre.
