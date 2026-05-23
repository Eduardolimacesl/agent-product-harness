# Constitution — lei de qualidade do produto

> Documento de invariantes **não-negociáveis do produto**: o que ele deve
> sempre ser, independentemente da story em execução. Importado da filosofia
> Spec-Driven Development (github/spec-kit, `/speckit.constitution` +
> `.specify/memory/constitution.md`). Vive em `docs/memory/constitution.md`.

## 1. O que é (e o que não é)

A Constitution responde *"que qualidade este produto recusa abrir mão?"*.
É distinta de tudo que já existe no harness — não duplica:

| Artefato | Escopo | Granularidade |
|---|---|---|
| **Constitution** | **este produto, sempre** | invariantes atemporais |
| `AGENTS.md` | comportamento do **agente** | regras de operação |
| ADR | **uma** decisão técnica | pontual, datada |
| Tech Spec | **como** construir | arquitetura desta versão |
| Princípios P1–P12 | o **harness** em si | meta-nível |

Os P1–P12 governam o *harness*; a Constitution governa o *produto*. Um produto
de fintech e um blog usam o mesmo harness, mas têm Constitutions diferentes.

## 2. Por que existe

Sem ela, "qualidade" é renegociada a cada story — uma sprint apertada corta
testes, a seguinte corta a11y, e seis meses depois ninguém sabe qual era o
padrão. A Constitution é o ponto fixo que o gate `/analyze`
([`../04-sprints/06-cross-artifact-analysis.md`](../04-sprints/06-cross-artifact-analysis.md))
cita para reprovar spec/plano que a viole. Transforma "qualidade" de opinião
em verificável (P12 — *governado*).

## 3. Estrutura — artigos canônicos

A Constitution é curta (alvo: ≤1 página). Cada artigo tem **poucas regras
testáveis**, não prosa. Esqueleto mínimo:

| Artigo | Pergunta que fecha | Exemplo de regra |
|---|---|---|
| I — Qualidade de código | o que o review nunca aceita? | "sem `any`; função >30 linhas refatora" |
| II — Disciplina de teste | o que define 'pronto'? | "todo P0 tem E2E; domínio é TDD" |
| III — Consistência de UX | o que toda tela respeita? | "estados loading/vazio/erro/sucesso obrigatórios" |
| IV — Budgets de performance | qual o teto? | "LCP p75 <2.5s; bundle/rota <250KB; CI falha se estourar" |
| V — Baseline de segurança | o mínimo inegociável? | "Zod na borda; sem secret em código; sensível exige ADR" |
| VI — Simplicidade | quando parar de abstrair? | "3 ocorrências antes de extrair; sem feature flag especulativa" |

Adapte os artigos ao produto. Um CLI não tem Artigo III; uma fintech adiciona
um artigo de auditoria/compliance. **Cada regra deve ser checável** — se não
dá para falsificar num diff ou num gate, é valor, não regra (mova para a
discovery/PRD).

## 4. Ciclo de vida

1. **Bootstrap (§A):** esqueleto copiado de
   [`../../templates/docs/memory/constitution.md`](../../templates/docs/memory/constitution.md)
   com `status: draft`.
2. **Ratificação (gate PRD → Spec):** o eng lead + sponsor preenchem ≥1 regra
   por artigo aplicável e marcam `status: ratified`. A Spec não avança para
   Sprint sem Constitution ratificada (cf. [`../../SKILL.md`](../../SKILL.md) §B).
3. **Emenda:** mudar uma regra é mudar o contrato de qualidade. Toda emenda
   carrega um mini-Change-Contract no log de emendas (campos: regra, modo de
   falha que ataca, como falsificar) e **bump de `version`**. Não se edita
   silenciosamente — é o mesmo princípio do
   [`../12-harness-evolution/00-change-contract.md`](../12-harness-evolution/00-change-contract.md),
   aplicado ao produto.

## 5. Frontmatter

```yaml
---
artifact: constitution
version: <major.minor>            # bump a cada emenda
status: draft | ratified
ratified: <YYYY-MM-DD | TODO>
created: <ISO 8601 UTC>
updated: <ISO 8601 UTC>
---
```

Schema também em [`../00-conventions.md`](../00-conventions.md) §2.8.

## 6. Como é consumida

- **Tech Spec** declara, em §0, conformidade com a Constitution vigente.
- **Plan Artifact** (Gate 1) verifica que o plano não viola nenhum artigo.
- **`check-cross-artifact.sh`** avisa se a Constitution está ausente ou em
  `draft` na entrada da Execução.
- **Review humano** usa a Constitution como checklist objetivo no Gate 2.

## 7. Anti-padrões

- ❌ Constitution-ensaio: três parágrafos de filosofia, zero regra checável.
- ❌ Duplicar o `AGENTS.md` — confunde regra-do-agente com lei-do-produto.
- ❌ Emendar no mesmo PR da story que a emenda destrava (igual ao drift).
- ❌ Artigo que ninguém cita em nenhum gate — candidato a remoção (P6).
- ❌ Deixar em `draft` e seguir para Sprint "porque dava pressa".

## 8. Como instruir o agente nesta fase

```
Vamos ratificar a Constitution em docs/memory/constitution.md.
1. Leia o PRD aprovado e os requisitos não-funcionais (§7 do PRD).
2. Para cada artigo aplicável (I–VI), proponha 1–3 regras CHECÁVEIS.
   Descarte qualquer regra que não se possa verificar em diff/gate.
3. Pule artigos que não se aplicam (ex.: III para produto sem UI) e
   registre o porquê.
4. Marque com [NEEDS CLARIFICATION: ...] toda regra cujo número/limiar
   o PRD não fixou (ex.: meta de cobertura).
5. Ao final, peça aprovação do eng lead + sponsor e só então status: ratified.
Não escreva código. Não invente budgets — pergunte.
```
