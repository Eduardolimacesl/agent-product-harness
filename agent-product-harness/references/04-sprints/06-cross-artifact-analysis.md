# Cross-Artifact Analysis — coerência antes do código

> Checagem de consistência **entre** os artefatos (Constitution ↔ PRD ↔ Tech
> Spec ↔ Sprint/Stories ↔ ADRs) **antes** de iniciar a Execução. Importado da
> filosofia Spec-Driven Development (github/spec-kit, `/speckit.analyze`).
> Gate na saída do Sprint Planning / pré-flight da fase Execução.

## 1. Princípio

Cada artefato pode estar internamente correto e o conjunto, ainda assim,
incoerente: uma user story do PRD sem nenhuma story de sprint, uma Server
Action na Spec que nenhuma story implementa, um `adr_refs` apontando para ADR
inexistente. O Spec Drift Protocol pega isso **tarde** (durante a execução,
um caso por vez). O analyze pega **cedo** (o conjunto inteiro, antes da
primeira linha de código). Falha barata: minutos de revisão evitam horas de
retrabalho.

## 2. Onde se encaixa entre os gates existentes

| Mecanismo | Pergunta | Quando |
|---|---|---|
| `validate.sh` | os artefatos seguem a **convenção**? (paths, frontmatter, deps) | sempre |
| **`check-cross-artifact.sh`** | os artefatos são **coerentes entre si**? | saída do Sprint Planning |
| `check-clarifications.sh` | sobrou **ambiguidade** aberta? | gates PRD→Spec, Spec→Sprint |
| `check-spec-drift.sh` | a spec **contradiz o código**? | durante/após execução |

`validate.sh` é mecânico (sintaxe); `check-cross-artifact.sh` é semântico
(relações). Não se substituem.

## 3. O que o analyze checa

Severidade: **CRITICAL** bloqueia a entrada na Execução; **WARN** é aviso a
sanar mas não bloqueia.

| # | Checagem | Severidade |
|---|---|---|
| A | todo `adr_refs` de story resolve para arquivo em `docs/spec/adr/` | CRITICAL |
| B | toda user story P0 do PRD é coberta por ≥1 story de sprint | CRITICAL |
| C | zero `[NEEDS CLARIFICATION]` em prd/ + spec/ + sprints/ | CRITICAL |
| D | `docs/memory/constitution.md` existe e está `ratified` | WARN |
| E | toda story referencia uma seção de PRD/Spec (campo `Spec:`/`PRD:` preenchido) | WARN |
| F | toda Server Action / webhook da Tech Spec é citada por ≥1 story | WARN |

Detalhe e limitações (parser é grep/awk, best-effort) em
[`../scripts/check-cross-artifact.sh`](../scripts/check-cross-artifact.sh).

## 4. Procedimento

1. Pré-condição: Sprint Plan existe e `validate.sh` sai 0.
2. Rode `bash <skill>/references/scripts/check-cross-artifact.sh`.
3. **CRITICAL → pare.** Não inicie a Execução. Resolva na origem:
   - cobertura faltando (B) → adicione story ou marque o requisito como fora
     de escopo desta sprint no Sprint Plan §4;
   - `adr_refs` quebrado (A) → corrija o id ou escreva o ADR;
   - marcador aberto (C) → volte ao Clarify Protocol.
4. **WARN → registre.** Sane ou justifique no `_summary.md` da fase Sprint.
5. Saída verde é pré-condição do §D (Story execution) no `SKILL.md`.

## 5. Relação com cobertura de requisitos

A checagem B é a malha PRD→Sprint. Não confunda com a malha Spec→Código
(check-spec-drift) nem com critério-de-aceite→teste (que vive na Tech Spec
§6.4, "Critérios de aceite executáveis"). As três juntas fecham o rastro:

```
PRD (US-NN) ──B──► Story de sprint ──drift──► Server Action/Webhook ──§6.4──► Teste E2E
```

## 6. Anti-padrões

- ❌ Iniciar a Execução com CRITICAL aberto "porque a story é simples".
- ❌ Silenciar a checagem B deletando a user story do PRD em vez de decidir escopo.
- ❌ Tratar WARN como ruído permanente — WARN recorrente vira dívida de harness.
- ❌ Rodar o analyze e ignorar a saída (convergência implícita disfarçada).

## 7. Caso de teste (dry-run)

**Cenário:** Sprint 01 de `inspectai`. O PRD lista US-01..US-04 (todas P0). O
Sprint Plan seleciona US-01, US-02, US-03. A Tech Spec §6.2 documenta
`createInspection`, `listInspections`, `finalizeInspection`. As stories citam
`adr_refs: ["0001", "0009"]`, mas só existe `0001-...` em `docs/spec/adr/`.

**Saída esperada:** `check-cross-artifact.sh` reporta
- CRITICAL (A): `adr_refs` "0009" sem arquivo correspondente;
- WARN (B): US-04 (P0) sem story — esperado se Sprint Plan §4 declara US-04
  fora desta sprint; CRITICAL se não declara;
- WARN (F): `finalizeInspection` na Spec sem story que a implemente.

Resolução: escrever ADR-0009 (ou corrigir o id), confirmar US-04 em §4 do
Sprint Plan, e adicionar story para `finalizeInspection` ou removê-la da Spec
desta versão. Re-rodar até sair 0 CRITICAL.
