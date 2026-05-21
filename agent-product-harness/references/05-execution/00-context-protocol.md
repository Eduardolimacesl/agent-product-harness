# Context Protocol — Memória, Limpeza e Janela de Contexto

> **Documento mais importante deste harness.** Define como o contexto flui entre fases, o que persiste, o que é descartado e como cada subagente recebe **só** o que precisa.

---

## Princípios

1. **Contexto é caro.** Todo token gasto em informação irrelevante degrada a qualidade da resposta e aumenta o risco de alucinação.
2. **Camadas, não monólitos.** Memória global vs. memória da fase vs. memória da story. Nunca misturar.
3. **Source of truth ≠ context window.** Os documentos no repositório são a verdade. A janela de contexto é só o recorte da vez.
4. **Limpar entre fases é obrigatório**, não opcional.

---

## Camadas de memória

```
┌──────────────────────────────────────────────────────┐
│  Camada 1: Knowledge Base do Antigravity             │  long-term, atemporal
│  (padrões aprovados, ADRs finais, snippets)          │
├──────────────────────────────────────────────────────┤
│  Camada 2: AGENTS.md + docs/                          │  source of truth versionado
│  (rules globais, PRD, Spec, ADRs, runbooks)          │
├──────────────────────────────────────────────────────┤
│  Camada 3: docs/memory/<fase>/                        │  log de sessão (resumido)
│  (decisões tomadas durante execução)                 │
├──────────────────────────────────────────────────────┤
│  Camada 4: Context window do agente                   │  efêmero, descartado a cada limpeza
│  (apenas o necessário para a tarefa atual)           │
└──────────────────────────────────────────────────────┘
```

### O que vai em cada camada

**Camada 1 — Knowledge Base do Antigravity** (use `Save to Knowledge Base` no agente):

- ✅ Padrões de código validados (ex.: como estruturamos uma Server Action)
- ✅ ADRs aprovados (apenas `accepted`, nunca `proposed`)
- ✅ Comandos recorrentes do projeto
- ✅ Convenções de UI já consolidadas
- ❌ Trechos de PRD ainda em discussão
- ❌ Secrets, tokens, URLs internas
- ❌ Decisões temporárias de uma sprint

**Camada 2 — Repositório (`docs/`):**

- ✅ Discovery, PRD, Spec, ADRs, sprint plans
- ✅ Runbooks, checklists, templates
- ✅ Tudo que precisa de versionamento e revisão por PR

**Camada 3 — `docs/memory/<fase>/`:**

- ✅ Resumo final de cada sessão de execução (template abaixo)
- ✅ Decisões tomadas durante implementação que não viraram ADR formal
- ✅ Notas para o próximo agente que pegar a story
- ❌ Logs crus de tool calls (pesados, descartáveis)

**Camada 4 — Context window:**

- O recorte mínimo necessário, montado no início da sessão.
- Limpo no fim da sessão.

---

## Bootstrap de uma nova sessão (script mental do agente)

Quando uma sessão começa, o agente carrega na seguinte ordem (e nada mais):

```text
1. AGENTS.md (raiz)                       ← sempre
2. docs/prd/01-glossary.md                ← vocabulário canônico (sempre)
3. docs/spec/00-tech-spec.md              ← arquitetura, apenas seção do módulo
4. docs/spec/01-design-system.md          ← se a story tem UI
5. ADRs aplicáveis ao módulo da tarefa    ← apenas os relevantes
6. docs/sprints/<sprint-atual>/<story>.md ← a story em si
7. docs/memory/<fase>/_summary.md         ← contexto de transição (se aplicável)
8. Os arquivos de código que o plano declara que serão tocados
```

> **Hierarchical content segmentation** (Li et al. 2025, DeepCode §2.1):
> para o passo 3, **não** abra o Tech Spec inteiro. Use:
>
> ```bash
> bash <skill>/references/scripts/spec-fetch.sh "<heading exato ou substring>"
> ```
>
> que devolve apenas a seção pedida (heading + corpo até o próximo heading
> de nível igual ou superior). O índice JSON correspondente é gerado por
> `spec-index.sh`. Headings duplicados quebram o fetch — `validate.sh`
> falha quando há duplicatas. Liste o uso no Plan Artifact.

> **Pré-flight:** se a story toca auth/RBAC/billing/PII e nenhum ADR aplicável existe em `docs/spec/adr/`, o passo 0 do plano é **redigir o ADR** — não escreve código antes (veja [`SKILL.md`](../../SKILL.md) §D).

**Não carregar:**

- ❌ PRD inteiro se a story tem referência específica (carregar só a seção)
- ❌ Discovery (já consolidado no PRD)
- ❌ Stories de outras sprints
- ❌ ADRs `superseded` ou `proposed`
- ❌ Logs de memória de outras fases

---

## Limpeza entre fases (obrigatório)

Ao **passar de fase** (ex.: PRD → Spec, Spec → Sprint, Sprint N → Sprint N+1), execute o ritual:

### Checklist de fim-de-fase

- [ ] Documento da fase está commitado e aprovado.
- [ ] Decisões importantes viraram ADR.
- [ ] Padrões reutilizáveis foram salvos na Knowledge Base.
- [ ] Resumo da fase foi escrito em `docs/memory/<fase>/_summary.md` (template abaixo).
- [ ] **Encerrar a sessão atual do Antigravity** e começar nova sessão para a próxima fase. Isso descarta a Camada 4.

### Por quê encerrar a sessão?

Cada fase tem mindset diferente:

- **Discovery:** divergente, faz perguntas, evita comprometer.
- **PRD:** convergente, escreve para humanos.
- **Spec:** convergente, escreve para máquinas.
- **Execução:** focado em uma story por vez.

Se você arrasta o contexto da Discovery para a Execução, o agente fica filosófico onde deveria ser cirúrgico.

---

## Template — `docs/memory/<fase>/_summary.md`

> Versão completa, com seções obrigatórias e exemplos por fase, em [`05-phase-summary-template.md`](05-phase-summary-template.md).

Esqueleto mínimo:

```markdown
# Resumo de <fase> — <YYYY-MM-DD>

## O que foi decidido
- ...

## O que ficou em aberto (carregar para próxima fase)
- ...

## ADRs criados nesta fase
- ADR-XXXX: <título>

## Padrões salvos na Knowledge Base
- ...

## Avisos para o próximo agente
- ...

## Harness debt observada
- ...
```

> **Tamanho-alvo:** ≤ 200 linhas. Se passou disso, está consolidando demais — separe.
>
> **Gate de transição:** sem `_summary.md` completo, a próxima fase **não começa**. O agente da fase seguinte recusa avançar e cita o item faltante (veja [`SKILL.md`](../../SKILL.md) §B).

---

## Template — log de sessão de execução

Para cada sessão de implementação (story sendo trabalhada), o agente, ao finalizar, escreve:

`docs/memory/execution/<YYYY-MM-DD>-<story-id>.md`

```markdown
# Sessão <story-id> — <data>

**Duração estimada:** <Xh>
**Status final:** done | parcial | bloqueado

## Plano original
<copiar/resumir o Plan Artifact>

## Desvios do plano
- ...

## Decisões pequenas tomadas
- ...

## Aprendizados que valem virar Knowledge Base ou ADR
- ...

## Pendências
- ...

## Comandos úteis usados
```bash
pnpm db:migrate
```
```

---

## Regras para o agente sobre o que **lembrar** vs. o que **esquecer**

| Tipo de informação | Onde fica | Quando o agente acessa |
|--------------------|-----------|------------------------|
| Convenção de código consolidada | Knowledge Base | sempre, automaticamente |
| ADR `accepted` | `docs/spec/adr/` | quando a tarefa toca o domínio do ADR |
| PRD aprovado | `docs/prd/` | só seções específicas, sob demanda |
| Critério de aceite da story | `docs/sprints/<n>/<id>.md` | sempre na sessão da story |
| Senha/token | em **lugar nenhum** legível por agente | nunca |
| Discussão de Slack/email | em **lugar nenhum** persistente sem curadoria | só se virar ADR/sumário |

---

## Sinais de que o contexto está degradando

Pare e limpe se:

- 🚨 O agente começa a contradizer um ADR aceito.
- 🚨 O agente referencia uma story de outra sprint sem motivo.
- 🚨 Respostas começam a ficar "filosóficas" e perdem ação concreta.
- 🚨 O agente "esquece" o stack obrigatório do `AGENTS.md`.
- 🚨 Você precisou repetir uma instrução básica mais de duas vezes.

**Ação:** encerre a sessão, abra nova, recomece com o bootstrap mínimo.

---

## Anti-padrões

- ❌ "Cole o PRD inteiro no chat para o agente lembrar." → Não. Aponte para `docs/prd/<...>.md` e carregue **só a seção** que importa.
- ❌ "Mantenha a mesma sessão por uma sprint inteira." → Não. Uma sessão por story, no máximo.
- ❌ "Salve tudo na Knowledge Base, depois a gente filtra." → Não. Knowledge Base curada vale ouro; lixo vira ruído.
- ❌ "Vou explicar de novo a stack a cada prompt." → Não. Está no `AGENTS.md`. Se o agente não lê, conserte o `AGENTS.md` ou recomece a sessão.
