# Plan Artifact Template — Gate 1 de execução

> Template único do **Plan Artifact** que o agente principal produz **antes** de tocar em qualquer arquivo de código.
> Aprovação humana deste artefato = **Gate 1** do ciclo de story (veja [`00-architecture-and-flow.md`](../00-architecture-and-flow.md) §6).

Sem este artefato aprovado, o agente **não escreve código**. Sem exceção.

---

## Quando este gate dispara

Plan Artifact é **obrigatório** quando a tarefa:

- Toca **≥ 3 arquivos**, ou
- Envolve **schema** (migration, alteração de tabela, RLS), ou
- Envolve **autenticação / autorização** (login, RBAC, whitelist), ou
- Envolve **billing / pagamento**, ou
- Envolve **deploy** (CI/CD, release), ou
- Envolve **PII** ou dados sensíveis (LGPD), ou
- Cria/altera **MCP server**, **Server Action pública**, **webhook externo**.

Para tarefas menores (1-2 arquivos, refactor mecânico, fix isolado), o Plan Artifact pode ser substituído por **2 linhas inline no chat**: o que vou tocar e por quê. Mas se houver dúvida, faça o Plan Artifact completo — é barato.

---

## Estrutura obrigatória

```markdown
# Plan Artifact — <story-id>

**Story:** docs/sprints/<n>/<story-id>.md
**Sessão:** <YYYY-MM-DD>
**Agente:** <identificação do agente / modelo>
**Modo:** agent-assisted | agent-driven (com ADR habilitando)

---

## 1. Objetivo da sessão (1 frase)

<o que esta sessão entrega; sem rodeios>

## 2. Critérios de aceite que serão satisfeitos

> Copiar do `<story-id>.md`. Se algum critério não for endereçado nesta sessão, justificar.

- [ ] Given/When/Then 1
- [ ] Given/When/Then 2
- [ ] ...

## 3. Arquivos que pretendo tocar

| Arquivo | Operação | Razão |
|---------|----------|-------|
| `app/(app)/inspecoes/page.tsx` | criar | tela de listagem (US-02) |
| `lib/db/schema/inspecoes.ts` | criar | tabela + tipo |
| `migrations/<timestamp>_inspecoes.sql` | criar | migration |
| ... | ... | ... |

> ≥ 3 arquivos? confirma a obrigatoriedade do gate. Se < 3 e nenhuma outra condição se aplica, considere se o artefato é necessário.

## 4. Passos de execução

> Sequência lógica. Cada passo termina em verificação (typecheck/lint/test/screenshot).

**Regra TDD (obrigatória para arquivos em `src/domain/**` ou `src/application/**`):** cada passo que cria/altera código nessas camadas é dividido em três subpassos explícitos:

- `red`: escrever (ou alterar) o teste que falha — rodar para confirmar que falha **pelo motivo certo**.
- `green`: implementar o mínimo para o teste passar.
- `refactor`: melhorar nomes/estrutura sem quebrar teste; rodar a suíte ao final.

Para código em `app/`, `components/`, `lib/utils`, infra (`src/infrastructure/**`) e integrações com APIs externas instáveis, **test-after é aceitável** — mas o passo de teste continua obrigatório antes do commit.

Exemplo:

1. `[red]` Adicionar caso "rejeita notes > 2000 chars" em `tests/unit/domain/inspections/inspection.test.ts` — verificação: `pnpm test:unit -- inspection` falha com mensagem esperada.
2. `[green]` Implementar invariante em `src/domain/inspections/inspection.ts` — verificação: mesmo comando passa.
3. `[refactor]` Extrair `MAX_NOTES_LENGTH` como constante de domínio — verificação: suíte continua verde + typecheck.
4. `[test-after]` Adicionar Server Action `createInspection` em `app/(app)/inspections/actions.ts` — verificação: `pnpm typecheck && pnpm lint && pnpm test:integration`.
5. ...

Se um passo de domínio/aplicação **não** segue red-green-refactor, justifique no próprio passo (`[no-tdd: <razão>]`) — humano avalia no Gate 2.

## 5. Subagentes necessários

| Subagente | Para quê | Briefing (objetivo · pronto-quando · não-faça · leia-apenas) |
|-----------|----------|-------------------------------------------------------------|
| browser   | smoke visual da tela X | … |
| ...       | ...      | ... |

> Se a tarefa é puramente backend / sem UI, registre "nenhum subagente necessário" — explicitar evita a tentação de delegar sem motivo.

## 6. Skills externas a invocar

| Quando | Skill |
|--------|-------|
| Antes de modelar tabela | `supabase-postgres-best-practices` |
| Antes de criar migration / RLS | `supabase` |
| Antes de criar componente Shadcn | `next-best-practices` |
| Após implementar, antes do diff | `simplify` |
| Antes de declarar pronto | `review` + `security-review` |

## 7. ADRs aplicáveis

| ADR | Status | Por que se aplica |
|-----|--------|-------------------|
| 0001 | accepted | RBAC via Supabase RLS — esta story usa |
| 0002 | accepted | Whitelist por trigger — não toca, mas confere alinhamento |

> **Se a tarefa toca domínio sensível (auth/RBAC/billing/PII) e não há ADR aplicável: PARE e redija o ADR como passo 0 do plano.**

## 8. Riscos e mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| <risco 1> | A/M/B | A/M/B | <ação concreta> |

## 9. O que NÃO está nesta sessão

> Escopo negativo explícito. Evita scope creep durante execução.

- ❌ <item 1>
- ❌ <item 2>

## 10. Pedido de aprovação

> Última linha. Pause aqui.

**Aguardando Gate 1.** Aprovo / ajusto / rejeito? Se aprovado, prossigo passo a passo da seção 4. Se rejeitado, refaço o plano.
```

---

## Checklist do agente antes de submeter o Plan Artifact

O agente revisa **antes** de pedir aprovação:

- [ ] **Lista de arquivos** real (não "vou ver e descubro"). Se não consegue listar, falta investigação.
- [ ] **Justificativa** por arquivo. Se "não sei por que vou tocar", não toca.
- [ ] **Subagentes** declarados com briefing — ou registro explícito de "nenhum".
- [ ] **Skills externas** mapeadas — ou registro explícito de "nenhuma se aplica".
- [ ] **ADRs aplicáveis** listados. Se domínio sensível e não há ADR → passo 0 = redigir ADR.
- [ ] **Riscos** ≥ 1 listado com mitigação concreta. "Sem riscos" é quase sempre falso.
- [ ] **Escopo negativo** explícito (seção 9).
- [ ] **TDD aplicado** a todo passo que toca `src/domain/**` ou `src/application/**` (red-green-refactor). Exceções marcadas como `[no-tdd: <razão>]`.

Se algum desses bate como vazio sem justificativa, o agente **refaz o plano** antes de mandar para gate.

---

## O que o humano avalia no Gate 1

| Verificação | Se falhar |
|-------------|-----------|
| Lista de arquivos é coerente com a story? | Rejeitar e pedir replanejamento. |
| ADR está em dia (ou foi adicionado como passo 0)? | Bloquear até ADR existir. |
| Riscos foram pensados ou são pro forma? | Pedir para refazer seção 8. |
| Escopo negativo está alinhado com o sprint? | Ajustar limites. |
| Subagente faz sentido ou é delegação por delegar? | Pedir justificativa. |

Se aprovado: humano responde "aprovado" + qualquer ajuste pontual. Agente prossegue passo a passo da seção 4.

---

## Anti-padrões

- ❌ "Vou começar e depois ajusto o plano." → não. Plano vem antes do código.
- ❌ Plan Artifact com "todos os arquivos do módulo" listados sem justificativa por arquivo.
- ❌ "Riscos: nenhum identificado" sem ter parado para pensar.
- ❌ Pular o gate "porque o humano confia" — o gate **é** o que mantém a confiança.
- ❌ Plan Artifact que muda significativamente durante a execução sem nova aprovação. → pause, atualize, peça novo gate parcial.
