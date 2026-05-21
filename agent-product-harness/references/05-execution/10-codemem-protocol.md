# CodeMem Protocol — `docs/memory/codemap/`

> Índice estrutural de **interfaces públicas** do produto. Move o harness do
> nível "implicit/file-only" para "repository-based" na taxonomia de
> substrato de Ning et al. 2026 §4. O gap que mais aparece em ablation de
> Li et al. 2025 (>2× em scores com dependências cruzadas).

## 1. Princípio — SNR maximization

Cada entrada do codemap responde a uma única pergunta: *qual a interface
pública deste módulo e quem depende dela?* Tudo mais é ruído. Inclusive
detalhes de implementação, exemplos longos, prose narrativa. Esses vivem
no código (e no `_summary.md` se for decisão de fase).

Sucessor operacional de P10 (`00-architecture-and-flow.md` §2): CodeMap
existe se aumenta SNR em stories futuras. Quando uma entrada vira ruído,
arquive.

## 2. Quando criar entrada

**Sim, cria** quando a story:
- introduz path coberto pela allowlist em `codemap/README.md`;
- expõe nova função/hook/component/action com consumo externo;
- adiciona Domain Event publicado.

**Não cria** para: testes, fixtures, tipos privados, helpers internos sem
consumidor externo, scripts de migração, arquivos `*.d.ts` puros.

## 3. Quando atualizar entrada

**Sim, atualiza** quando a interface pública muda:
- assinatura de função/action (parâmetros, retorno);
- props públicas de componente;
- símbolo exportado novo ou removido;
- aparece um novo consumidor (atualiza a seção *Consumed by*).

**Não atualiza** quando: refactor interno mantém a interface; ajuste de
estilo/lint; rename de variável local.

## 4. Quando arquivar

Módulo deprecated: marca `status: deprecated`. Mantém em `modules/` por **2
sprints** (para o cross-reference de `Consumed by` ainda funcionar enquanto
migra). Depois move para `modules/_archive/`. **Nunca** remove sem
arquivar — outras entradas podem citar.

## 5. Ritual no DoD da story

Antes de `status: done`, o agente da story:

1. Roda `bash <skill>/references/scripts/codemap-update.sh <story-id>`.
2. O script imprime a lista de módulos detectados como impactados e os
   paths de template/entrada a preencher.
3. O agente preenche (ele já tem o contexto da story — não delega para
   nova sessão).
4. Revisa o diff do `codemap/`.
5. Commita junto com o código da story.

`validate.sh` falha se há módulo público sem entrada no codemap.

`codemap-update.sh` **não** invoca LLM. É detecção determinística (path
matching contra allowlist) + andaime — preserva o bootstrap mínimo da
story.

## 6. Como o agente usa em stories futuras

No bootstrap mínimo de uma story futura, o agente carrega seletivamente:
para cada path que o Plan Artifact declara que vai tocar, carregar
`docs/memory/codemap/modules/<module>.md`. **Nunca** carregar a pasta
inteira — quebraria P8 (módulos competem pelo context window).

Para descobrir consumidores antes de mexer em interface pública:

```bash
grep -l "<simbolo>" docs/memory/codemap/modules/*.md
```

ou ler `graph.json` (campo `edges`).

## 7. Relação com outras camadas

|Camada|Granularidade|Quem mantém|Onde fica|
|---|---|---|---|
|Tech Spec §0–§15|Decisão arquitetural|Eng lead|`docs/spec/00-tech-spec.md`|
|`_summary.md` por fase|Narrativa da fase|Agente principal|`docs/memory/<fase>/_summary.md`|
|**CodeMap (este)**|Interface pública por módulo|Agente da story|`docs/memory/codemap/modules/*.md`|
|`telemetry.jsonl`|Eventos estruturados|Agente (side-effect)|`docs/memory/telemetry.jsonl`|

Não se substituem. `_summary.md` é narrativo ("o que aconteceu na fase");
codemap é estrutural ("qual a forma do código hoje").
