# CodeMap — `docs/memory/codemap/`

> Índice estrutural do produto. Camada 2 da memória do harness — fica entre
> a Tech Spec (decisão arquitetural) e o código em si.
>
> Protocolo: [`references/05-execution/10-codemem-protocol.md`](../../../references/05-execution/10-codemem-protocol.md).

## Estrutura

```
docs/memory/codemap/
├── README.md          ← este arquivo
├── modules/           ← um .md por módulo público
│   ├── <module-A>.md
│   └── ...
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
  - lib/**/*           # quando relevante para o produto
exclude:
  - **/*.test.ts
  - **/*.spec.ts
  - **/__fixtures__/**
  - **/*.d.ts
```

## Ritual

- Toda story que cria/altera interface pública em path da allowlist roda
  `codemap-update.sh <story-id>` no DoD.
- O script NÃO invoca LLM. Lista os módulos a (re)gerar; o agente da story
  preenche.
- Módulo deprecated: `status: deprecated` por 2 sprints, depois move para
  `modules/_archive/`.

## Uso em stories futuras

Bootstrap mínimo carrega **seletivamente** apenas os módulos referenciados
pelos arquivos do plano. Nunca carregue `modules/` inteiro.
