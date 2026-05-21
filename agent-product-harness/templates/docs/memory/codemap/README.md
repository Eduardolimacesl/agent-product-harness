# CodeMap — `docs/memory/codemap/`

> Índice estrutural do produto. Camada 2 da memória do harness.
> Protocolo: `<skill>/references/05-execution/10-codemem-protocol.md`.

## Estrutura

```
docs/memory/codemap/
├── README.md          ← este arquivo
├── modules/           ← um .md por módulo público
└── graph.json         ← grafo de dependências entre módulos
```

## Allowlist de "módulos públicos"

Apenas paths nesta lista geram entrada em `modules/`. Editar via PR.

```yaml
include:
  - src/domain/**/*
  - src/application/**/*
  - src/contracts/**/*
  - app/(app)/**/actions.ts
exclude:
  - "**/*.test.ts"
  - "**/*.spec.ts"
  - "**/__fixtures__/**"
  - "**/*.d.ts"
```

## Ritual

Toda story que cria/altera interface pública em path da allowlist roda
`codemap-update.sh <story-id>` antes de `status: done`.
