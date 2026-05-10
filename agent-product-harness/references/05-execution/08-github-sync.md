# GitHub Sync — Bridge opcional `docs/` ↔ Issues / PRs

> Como espelhar artefatos do harness em GitHub Issues e Pull Requests para
> auditoria pública e coordenação de equipe. **Opcional.** O harness funciona
> 100% local; este protocolo é para times que querem rastro externo.
>
> Inspiração: `ccpm/references/sync.md`. A diferença: o CCPM **nasce** acoplado
> ao GitHub; aqui o GitHub é uma camada de saída do que `docs/` já decidiu.

---

## 1. Mapeamento

| Artefato em `docs/` | Representação no GitHub |
|---------------------|--------------------------|
| `docs/prd/00-prd.md` | Epic Issue (label: `epic`, `prd`) |
| `docs/sprints/<N>/sprint-plan.md` | Milestone (`Sprint <N>`) |
| `docs/sprints/<N>/<story-id>.md` | Issue (label: `story`, `sprint:<N>`) |
| `docs/sprints/<N>/<bug-id>.md` | Issue (label: `bug`, `sprint:<N>`) |
| `docs/spec/adr/<NNNN>-<slug>.md` | Issue de discussão (label: `adr`) **ou** seção do epic |
| `docs/memory/<phase>/_summary.md` | Comment de fechamento no epic |
| Execução de story | Branch `story/<id>` + PR |
| Sprint encerrada | Comment de retro no milestone |

---

## 2. Pré-requisitos

+ `gh` CLI autenticado (`gh auth status`).
+ `git remote get-url origin` aponta para o repo do **produto** (não o repo da
  skill — checagem em [`scripts/_safety.sh`](../scripts/_safety.sh)).
+ Permissão de escrita em issues + PRs.

Não pré-cheque autenticação obsessivamente — rode `gh` e trate falha:

```bash
gh issue list || { echo "falha no gh — rode 'gh auth login'"; exit 1; }
```

---

## 3. Sync inicial — empurrar PRD + sprint para GitHub

Pré-flight:

+ `validate.sh` deve sair 0.
+ `_summary.md` da fase **prd** existe e está aprovado.
+ `sprint-plan.md` da sprint existe.

Passo a passo:

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

# 1. Cria milestone para a sprint
gh api repos/$REPO/milestones -f title="Sprint <N>" \
  -f description="$(frontmatter_get docs/sprints/<N>/sprint-plan.md goal)"

# 2. Cria epic issue a partir do PRD
strip_frontmatter docs/prd/00-prd.md > /tmp/prd-body.md
epic_n=$(gh issue create --title "Epic: <product>" \
  --body-file /tmp/prd-body.md \
  --label epic,prd --json number -q .number)

# 3. Cria uma issue por story
for story in $(story_files <N>); do
  id=$(frontmatter_get "$story" id)
  name=$(frontmatter_get "$story" name)
  strip_frontmatter "$story" > /tmp/story-body.md
  echo -e "\n\n— Parte do epic #$epic_n" >> /tmp/story-body.md
  n=$(gh issue create --title "$name" \
        --body-file /tmp/story-body.md \
        --label story,sprint:<N> \
        --milestone "Sprint <N>" \
        --json number -q .number)
  frontmatter_set "$story" github "https://github.com/$REPO/issues/$n"
done
```

Resultado: cada story tem `github:` no frontmatter; o epic linka todas; o
milestone agrupa.

---

## 4. Branch + PR por story

Convenção:

+ Branch: `story/<id>` (ex.: `story/us-01-criar-inspecao`).
+ Worktree: ver [`09-parallel-streams.md`](09-parallel-streams.md) para o caso
  de paralelismo por sprint.
+ Commits: `<id>: <descrição>` (ex.: `us-01: add Zod schema for create form`).
+ PR title: `<id>: <name da story>`.
+ PR body: gerado pelo Final Artifact da story (sumário ≤ 5 linhas + arquivos
  + testes + riscos).
+ PR linka issue com `Closes #<n>` no body.

```bash
git checkout -b story/<id>
# ... trabalha
git push -u origin story/<id>
gh pr create --title "<id>: <name>" --body-file /tmp/final-artifact.md
```

---

## 5. Progress comments durante execução

A cada Final Artifact de **passo** dentro da story (não no fim), opcionalmente
postar comment no issue com:

```markdown
## Progresso — <YYYY-MM-DD HH:MM>

### ✅ Concluído neste step
- ...

### 🔜 Próximo step
- ...

### ⚠️ Riscos / dúvidas
- ...
```

Evite spammar — 1 comment por step relevante, não por commit.

---

## 6. Fechamento

Quando a story sai (PR merged):

```bash
gh issue close <n> --comment "Fechada via #<pr_number>."
frontmatter_set docs/sprints/<N>/<story-id>.md status done
frontmatter_set docs/sprints/<N>/<story-id>.md updated "$(now)"
bash <skill>/scripts/progress.sh <N>   # recalcula sprint-plan.md
```

Quando a sprint encerra (`_summary.md` da fase `sprints` aprovado):

```bash
strip_frontmatter docs/memory/sprints/_summary.md > /tmp/retro.md
milestone_n=$(gh api repos/$REPO/milestones -q '.[] | select(.title=="Sprint <N>") | .number')
gh api repos/$REPO/milestones/$milestone_n -X PATCH -f state=closed
gh issue comment $epic_n --body-file /tmp/retro.md
```

---

## 7. Bug encontrado em story já fechada

Ver §E em [`SKILL.md`](../../SKILL.md). O fluxo cria `bug-<NN>-<slug>.md` com
`bug_for: <story-id-original>` e abre issue `Bug:` linkada à issue original
via `Follow-up to #<n>` no body.

---

## 8. O que **não** sincronizar

+ ❌ ADRs como issues separadas se o time já revisa em PR — duplica esforço.
+ ❌ Logs de execução em `docs/memory/execution/` — privados.
+ ❌ Discovery brief — geralmente confidencial.
+ ❌ `_summary.md` linha-a-linha — só o destilado de fechamento.

---

## 9. Falhas de rede

Se `gh` falhar por rede, retentar com backoff exponencial (2s, 4s, 8s, 16s).
Se falhar 4 vezes, **não** marcar local como "sincronizado" — humano resolve.

---

## 10. Quando NÃO usar este protocolo

+ Equipe de 1 pessoa com auditoria irrelevante.
+ Produto pré-discovery (ainda não há issues que justifiquem o overhead).
+ Política da empresa proíbe issues públicas e não há GH Enterprise privado.

Nesses casos, `docs/` + PRs continuam sendo a fonte de verdade. O harness
funciona sem este protocolo.
