# Parallel Streams — Decompor 1 story em sub-agentes ortogonais

> Quando uma story é grande o suficiente para se beneficiar de paralelismo,
> decomponha em **streams** com escopo de arquivos travado e rode 1 sub-agente
> por stream. Inspiração direta de `ccpm/references/execute.md`.

---

## 1. Quando ativar

+ Story tem **size = M** ou maior **e** toca ≥ 3 camadas (ex.: schema, action,
  UI, testes).
+ Você consegue declarar `arquivo X só pertence ao stream Y` antes de tocar
  código (sem isso, paraleliza só conflito).
+ Tem ≥ 2 sub-agentes disponíveis no runtime.

Se qualquer condição falhar, **não paralelize.** Single-agent linear é mais
rápido em escopos pequenos.

---

## 2. Streams comuns por camada

| Stream | Escopo típico de arquivos |
|--------|---------------------------|
| **DB** | `lib/db/schema.ts`, `supabase/migrations/`, RLS policies |
| **Service** | `lib/<domain>/*.ts`, `lib/db/<domain>.ts` |
| **Action** | `app/(app)/<route>/actions.ts`, validação Zod |
| **UI** | `app/(app)/<route>/page.tsx`, `components/features/<domain>/` |
| **Tests** | `tests/unit/<domain>.*`, `tests/e2e/<domain>.spec.ts` |
| **Docs** | `docs/runbooks/`, READMEs de módulo |

Um arquivo só pode estar em **um** stream. Arquivos compartilhados (types,
config, `package.json`) ficam com **um stream designado** (geralmente DB ou
Service) e os outros pulam após o commit dele.

---

## 3. Story analysis — gate antes de paralelizar

Produza `docs/sprints/<N>/<story-id>-analysis.md` antes de spawnar agentes.
Template em
[`../04-sprints/03-story-analysis-template.md`](../04-sprints/03-story-analysis-template.md).

Resumo do que o doc tem:

```yaml
---
story: <id>
analyzed: <ISO 8601 UTC>
estimated_hours: <total>
parallelization_factor: <1.0–5.0>
---
```

Mais corpo descrevendo:

+ cada stream (Scope, Files, Can Start, Dependencies, Hours);
+ Coordination Points (arquivos compartilhados, sequenciamento);
+ Conflict Risk Assessment;
+ Expected Timeline (com vs. sem paralelo).

Sem este arquivo, recusa paralelizar.

---

## 4. Worktree por sprint

Para isolar a sprint de outros trabalhos e habilitar branch-per-story:

```bash
git checkout main && git pull origin main
git worktree add ../sprint-<N> -b sprint/<N>
cd ../sprint-<N>
```

Dentro do worktree, cada story cria sua branch local a partir de `sprint/<N>`:

```bash
git checkout -b story/<id>
```

Merge: `story/<id>` → `sprint/<N>` → `main` (via PR review humano).

Cleanup ao fim da sprint:

```bash
git worktree remove ../sprint-<N>
git branch -d sprint/<N>
```

> Convenção análoga ao `epic/<name>` do CCPM, mas escopada por sprint do harness
> em vez de epic, porque epic aqui é o PRD inteiro — granularidade errada para
> branch.

---

## 5. Lançar streams como sub-agentes

Briefing-padrão para cada sub-agente:

```text
Você é um sub-agente trabalhando no Stream <X> da story <id> em ../sprint-<N>/.

Leia primeiro:
  1. docs/sprints/<N>/<story-id>.md            (story completa)
  2. docs/sprints/<N>/<story-id>-analysis.md   (análise de paralelismo)
  3. AGENTS.md                                 (rules globais)

Seu escopo de arquivos (NÃO toque fora):
  - <arquivo 1>
  - <arquivo 2>

Dependências de outros streams:
  - Stream <Y> precisa terminar antes de você modificar <arquivo Z>.
  - Aguarde sinal antes de começar.

Regras de coordenação:
  - Antes de tocar arquivo compartilhado: git pull --rebase origin sprint/<N>.
  - Commit com formato: '<id> [stream-<X>]: <descrição curta>'.
  - Nunca --force.
  - Conflito não-resolvível → pare, registre em
    docs/sprints/<N>/<story-id>-stream-<X>-progress.md, peça ajuda humana.

Gate de saída:
  Final Artifact ≤ 5 linhas + lista de arquivos + testes + riscos.
  Status do stream: completed.
```

---

## 6. Coordenação ao vivo

Enquanto streams rodam, mantenha
`docs/sprints/<N>/<story-id>-execution.md`:

```markdown
## Active Streams
- Stream A (DB): @agent-A — Started <ts>
- Stream B (UI): @agent-B — Started <ts>

## Queued
- Stream C (Tests): @agent-C — Waiting on Stream A

## Completed
- (vazio)

## Conflicts
- (vazio)
```

Quando um stream completa, dispare os que dependiam dele.

---

## 7. Anti-padrões

+ ❌ Paralelizar 2 streams que tocam o mesmo arquivo (vira merge conflict
  garantido).
+ ❌ Streams sem `arquivos:` declarados — vai virar improviso.
+ ❌ Pular o `<story-id>-analysis.md` porque "vai ser rapidinho".
+ ❌ `--force` em qualquer git op de sub-agente.
+ ❌ Mais de 4 streams concorrentes na mesma story (overhead de coordenação
  passa a perder do ganho).
+ ❌ Spawnar sub-agentes sem worktree dedicado se o trabalho é > 1h
  (poluição do working tree principal).

---

## 8. Quando NÃO paralelizar

+ Story = XS ou S.
+ Toda a mudança é em 1 camada (só UI, só DB).
+ Você ainda não definiu schema — backfill de paralelismo após escrever schema
  é trivial; antes, é chute.
+ Sub-agentes do runtime são sequenciais sob o capô (ler doc do runtime).
