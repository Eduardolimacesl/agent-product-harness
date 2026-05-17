---
name: clean-code-pass
description: Run a deterministic Clean Code review pass over the current diff before
  human review. Checks the 10 hard rules codified in AGENTS.md §4 — function size,
  boolean flags, CQS, magic literals, early-return, comment intent, naming,
  primitive obsession, DRY threshold, error-as-data. TRIGGER after writing code,
  before invoking `simplify` or `review`. SKIP for diffs ≤ 5 lines, formatting-only
  changes, or generated files (lockfiles, schemas, migrations).
---

# Skill: clean-code-pass

**Versão:** v0.1
**Status:** experimental
**Última revisão:** 2026-05-17
**Owner:** harness
**ADRs relacionados:** —

---

## 1. Propósito

Aplicar uma passada determinística de Clean Code sobre o **diff atual** antes do humano revisar. Reduz idas e voltas no PR sobre coisas que o agente podia ter visto sozinho (funções grandes, flags booleanas, comentários redundantes, magic strings).

## 2. Capabilities

- Detecta as 10 violações codificadas em `AGENTS.md` §4 → "Clean Code".
- Produz lista de violações com **arquivo:linha** e sugestão de refator.
- Reporta "nenhuma violação" explicitamente quando passa — não emite ruído.
- Não modifica código sozinha — sugere e pausa para humano decidir.

## 3. Quando usar

- Depois de implementar uma story e antes de pedir review humano (entre `simplify` e `review`).
- Quando o diff inclui ≥ 1 arquivo `.ts`/`.tsx` em `src/domain/`, `src/application/`, ou `lib/`.
- Antes de marcar a story como `status: done`.

## 4. Quando NÃO usar

- Diff com ≤ 5 linhas significativas (custo > benefício).
- Mudança puramente de formatação (`prettier`/`eslint --fix`).
- Arquivos gerados: `pnpm-lock.yaml`, `*.generated.ts`, migrations SQL, schemas Drizzle reflexos do banco.
- Arquivos de teste — testes têm padrões próprios (AAA, given/when/then); rodar Clean Code sobre `describe`/`it` gera falsos positivos. Para testes, prefira a heurística "um teste = uma asserção comportamental".

## 5. Preconditions

- Existe diff vs. base (`git diff --name-only` retorna ≥ 1 arquivo).
- `AGENTS.md` §4 → "Clean Code" carregado em contexto (10 regras).

## 6. Procedimento

1. Liste arquivos do diff: `git diff --name-only`.
2. Filtre pelas extensões alvo (`.ts`, `.tsx`) e exclua os listados em §4.
3. Para cada arquivo restante, aplique o checklist do `GUIDE.md` regra a regra.
4. Para cada violação, registre: `<arquivo>:<linha>` · regra violada · sugestão (1 linha).
5. Se zero violações: reporte "clean-code-pass: ✅ 0 violações em N arquivos" e termine.
6. Se ≥ 1 violação: reporte em tabela, pause, **não corrija sozinho** — humano decide quais aceitar.

## 7. Output esperado

Tabela enxuta:

```
| Arquivo:linha | Regra | Sugestão |
|---------------|-------|----------|
| src/application/inspections/create.ts:42 | R1 (função >30 linhas) | extrair `validateInput` |
| src/domain/billing/invoice.ts:18 | R2 (boolean flag) | quebrar em `markAsPaid()` / `markAsVoid()` |
```

Se vazia: `✅ clean-code-pass: 0 violações em <N> arquivos`.

## 8. Conflitos com outras skills

- `simplify` ataca duplicação e abstração; `clean-code-pass` ataca legibilidade local. Ordem: `simplify` primeiro, `clean-code-pass` depois.
- `review` é review geral (segurança, arquitetura, regressão); `clean-code-pass` é um subconjunto mecânico. Ordem: `clean-code-pass` → `simplify` → `review` → `security-review`.

## 9. Guia detalhado

Para o checklist completo, exemplos e contraexemplos por regra: ver [`GUIDE.md`](./GUIDE.md). Carregue sob demanda — não inflar contexto.
