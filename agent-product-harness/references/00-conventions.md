# Conventions — Frontmatter, Paths, Datetime, Safety

> Leia este arquivo **antes** de qualquer operação que crie ou edite artefatos
> do harness. Centraliza schemas e regras que antes estavam espalhadas por
> templates. Análogo ao `conventions.md` do `ccpm`, adaptado ao harness com
> gates por fase.

Escopo: este documento define **só** convenções mecânicas (frontmatter, paths,
comandos shell). Princípios e gates por fase ficam em
[`00-architecture-and-flow.md`](00-architecture-and-flow.md).

---

## 1. Estrutura de diretórios em `docs/`

```text
docs/
├── discovery/
│   └── 00-discovery-brief.md
├── prd/
│   ├── 00-prd.md
│   └── 01-glossary.md
├── spec/
│   ├── 00-tech-spec.md
│   ├── 01-design-system.md
│   └── adr/
│       └── <NNNN>-<slug>.md
├── sprints/
│   └── <N>/
│       ├── sprint-plan.md
│       ├── <story-id>.md
│       ├── <bug-id>.md
│       └── <story-id>-analysis.md   # opcional, ver 09-parallel-streams
├── memory/
│   ├── discovery/_summary.md
│   ├── prd/_summary.md
│   ├── design/_summary.md
│   ├── spec/_summary.md
│   ├── sprints/_summary.md
│   ├── execution/<YYYY-MM-DD>-<story-id>.md
│   ├── testing/_summary.md
│   ├── deploys/_summary.md
│   ├── telemetry.jsonl                 # deep telemetry, ver 05-execution/11-*
│   └── codemap/                        # índice estrutural, ver 05-execution/10-*
│       ├── README.md
│       ├── modules/<slug>.md
│       └── graph.json
└── runbooks/
```

Regras duras:

+ **Stories vivem em `docs/sprints/<N>/`**, nunca na raiz de `sprints/`.
+ **Cada fase tem sua subpasta em `memory/`**, com `_summary.md` exigido para
  destravar a próxima fase.
+ **`docs/spec/adr/` é obrigatório** mesmo quando vazio (mantenha `.gitkeep`).

---

## 2. Frontmatter por tipo de artefato

Todo artefato versionado leva frontmatter YAML entre `---`. Campos com `?`
são opcionais; o resto é obrigatório.

### 2.1 PRD — `docs/prd/00-prd.md`

```yaml
---
name: <product-or-feature-name>     # kebab-case
description: <one-liner>
phase: prd
status: draft | approved | superseded
created: <ISO 8601 UTC>
updated: <ISO 8601 UTC>
sponsor: <nome humano>
---
```

### 2.2 ADR — `docs/spec/adr/<NNNN>-<slug>.md`

```yaml
---
id: <NNNN>                          # zero-padded sequencial
title: <título curto>
status: proposed | accepted | superseded | deprecated
created: <ISO 8601 UTC>
updated: <ISO 8601 UTC>
supersedes: ?<id>
superseded_by: ?<id>
tags: [auth, billing, schema, ...]
---
```

### 2.3 Sprint plan — `docs/sprints/<N>/sprint-plan.md`

```yaml
---
sprint: <N>
goal: <one-liner>
start: <YYYY-MM-DD>
end: <YYYY-MM-DD>
status: planning | active | closed
progress: 0%                         # recalculado por scripts/progress.sh
created: <ISO 8601 UTC>
updated: <ISO 8601 UTC>
---
```

### 2.4 Story — `docs/sprints/<N>/<story-id>.md`

```yaml
---
id: <us-NN-slug | ts-NN-slug | spike-NN-slug | chore-NN-slug>
name: <Title Case>
type: story | tech-task | spike | chore
priority: P0 | P1 | P2
size: XS | S | M | L
sprint: <N>
status: todo | doing | review | done | blocked-spec-drift | cancelled
owner: <nome | unassigned>
created: <ISO 8601 UTC>
updated: <ISO 8601 UTC>
depends_on: []                       # ids de stories que precisam terminar antes
parallel: true | false               # pode rodar concorrente com não-conflitantes
conflicts_with: []                   # ids que tocam os mesmos arquivos
adr_refs: []                         # ADRs aplicáveis (ex: ["0001", "0003"])
github: ?<url>                       # populado pelo 08-github-sync
---
```

### 2.5 Bug — `docs/sprints/<N>/<bug-id>.md`

Mesmo schema da story, com:

```yaml
type: bug
bug_for: <story-id-original>         # story em que o bug foi descoberto
```

### 2.6 Phase summary — `docs/memory/<fase>/_summary.md`

```yaml
---
phase: discovery | prd | design | spec | sprints | execution | testing | deploy
status_de_saida: aprovado | aprovado-com-ressalvas | retornou
created: <ISO 8601 UTC>
owner: <nome>
adrs_criados: []                     # lista de ids
---
```

Conteúdo do corpo segue
[`05-execution/05-phase-summary-template.md`](05-execution/05-phase-summary-template.md).

### 2.7 Execution log — `docs/memory/execution/<YYYY-MM-DD>-<story-id>.md`

```yaml
---
story: <story-id>
date: <YYYY-MM-DD>
duration_min: <int>
status: completed | partial | aborted
files_changed: <int>
gate_1_approved: true | false        # plan artifact aprovado
gate_2_approved: true | false        # diff aprovado
---
```

---

## 3. Datetime

Sempre UTC ISO 8601. **Nunca** datilografar:

```bash
date -u +"%Y-%m-%dT%H:%M:%SZ"
```

Use `scripts/_lib.sh::now` para padronizar.

---

## 4. Atualização de frontmatter via `sed`

Para mudar **um** campo preservando o resto:

```bash
sed -i.bak "/^<field>:/c\\<field>: <value>" <file>
rm <file>.bak
```

Para extrair só o **corpo** (sem frontmatter), útil para sync:

```bash
sed '1,/^---$/d; 1,/^---$/d' <file> > /tmp/body.md
```

Use `scripts/_lib.sh::frontmatter_set` / `::frontmatter_get` /
`::strip_frontmatter` para encapsular.

---

## 5. Repository safety check

Qualquer script ou comando que escreva em `docs/` deve, antes, garantir que
não está rodando dentro do **próprio repositório da skill** (proteção contra
usuário que esqueceu de trocar `git remote`).

```bash
remote_url=$(git remote get-url origin 2>/dev/null || echo "")
if [[ "$remote_url" == *"agent-product-harness"* ]] && \
   [[ "$remote_url" == *"eduardolimacesl"* ]]; then
  echo "ERRO: este diretório aponta para o repo da skill agent-product-harness."
  echo "Troque o remote ou rode em outro projeto."
  exit 1
fi
```

Ver `scripts/_safety.sh`.

---

## 6. Naming

+ **Stories:** `<tipo>-<NN>-<slug>.md` (ex.: `us-01-criar-inspecao.md`,
  `ts-03-observabilidade.md`, `spike-01-vector-db.md`,
  `chore-02-upgrade-next.md`).
+ **Bugs:** `bug-<NN>-<slug>.md` (sempre `bug_for` preenchido).
+ **Sprint folders:** `docs/sprints/01/`, `02/`, ... zero-padded a 2 dígitos.
+ **ADRs:** `<NNNN>-<slug>.md`, sequencial 4 dígitos (`0001-...`).
+ **Slugs:** kebab-case, lowercase, ASCII, sem acento.
+ **Phase keys:** `discovery | prd | design | spec | sprints | execution |
  testing | deploy` (singular, lowercase).

---

## 7. Cálculo de progresso

Progresso de uma sprint = `done / total` das stories que **não** são `chore`
de processo:

```bash
total=$(grep -l '^type:' docs/sprints/<N>/[a-z]*.md | wc -l)
done=$(awk '/^status: done/{print FILENAME}' docs/sprints/<N>/[a-z]*.md \
        | sort -u | wc -l)
progress=$(( done * 100 / total ))
```

Ver `scripts/progress.sh` para a versão completa que atualiza o frontmatter
do `sprint-plan.md`.

---

## 8. Anti-padrões (recusados pelo `validate.sh`)

+ ❌ Story em `docs/sprints/<id>.md` (raiz). Deve estar em `docs/sprints/<N>/`.
+ ❌ ADR sem número (`adr/auth.md` em vez de `adr/0001-auth.md`).
+ ❌ Datetime placeholder (`YYYY-MM-DD`) committado.
+ ❌ Frontmatter sem `status` ou `created`.
+ ❌ `_summary.md` faltando em fase já iniciada (bloqueia próxima fase).
+ ❌ `depends_on` apontando para id que não existe.
+ ❌ Story com `type: story` tocando auth/RBAC/billing/PII sem `adr_refs`.
+ ❌ `docs/prd/01-glossary.md` ausente após bootstrap.

---

## 9. Quando este documento muda

É contrato — qualquer mudança em schema de frontmatter ou path quebra projetos
existentes. Atualize via PR contra a skill, com nota em `CHANGELOG` (a criar
quando v0.2 sair) e bump de versão **major**.
