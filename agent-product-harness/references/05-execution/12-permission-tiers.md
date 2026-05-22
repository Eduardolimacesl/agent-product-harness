# Permission Tiers — modelo de autorização em três níveis

> Reorganiza a lista plana de Hard rules em três tiers nomeados, com o
> tier `full-access` sempre atrelado a gate HITL obrigatório (Ning et al.
> 2026, §3.4.3). A permissão é **context-sensitive**: o mesmo comando é
> seguro em sandbox e perigoso em produção.

## 1. Os três tiers

| Tier | Ações | Gate |
|------|-------|------|
| **read-only** | navegação de repo, retrieval, análise estática, leitura de log, scripts `*-status.sh`/`*-list.sh`/`validate.sh` | nenhum |
| **sandbox-edit** | patch local, criação/edição de arquivos no workspace, instalação de deps em workspace isolado, execução de testes | **Gate 1** (Plan Artifact aprovado) |
| **full-access** | rede saída para serviços não-listados, leitura/escrita de credenciais, deploy, publicação de pacote, ops destrutivas de FS, mutação de histórico git, escrita em produção | **HITL obrigatório** (humano aprova *aquela ação específica*) |

## 2. Context-sensitivity

O tier de uma ação **depende do contexto** — argumentos, estado do
ambiente, sensibilidade dos dados, efeitos colaterais. Não é função só da
identidade do comando.

| Comando | Em sandbox isolado | Em path do repo | Em produção |
|---|---|---|---|
| `rm -rf <path>` | sandbox-edit (workspace temp) | full-access (perda potencial de trabalho) | full-access (incidente) |
| `git push` | — | full-access (publica) | full-access (publica em main) |
| `pnpm install <pkg>` | sandbox-edit | sandbox-edit | full-access (afeta build de prod) |
| `curl https://example.com` | sandbox-edit | sandbox-edit | full-access (rede saída) |
| `psql -c 'TRUNCATE ...'` | sandbox-edit (db efêmero) | full-access | full-access |
| Ler `.env*` | full-access | full-access | full-access |

**Regra de classificação:** na dúvida, classifique no tier mais alto
(fail-safe). Documente o caso-limite numa atualização deste arquivo.

## 3. Mapa das Hard rules atuais por tier

### read-only — sem gate específico

- Leitura de qualquer arquivo do workspace (exceto `.env*`).
- Scripts de leitura: `validate.sh`, `phase-status.sh`, `sprint-status.sh`,
  `story-list.sh`, `next-story.sh`, `spec-fetch.sh`, `telemetry-report.sh`.

### sandbox-edit — exige Plan Artifact aprovado (Gate 1)

- Criar/editar arquivos sob caminho do workspace.
- `pnpm install`, `pnpm dev`, `pnpm build`, `pnpm lint`, `pnpm test`,
  `pnpm typecheck`.
- `git add`, `git commit`, `git status`, `git diff`, `git log`.
- Scripts de mutação local: `telemetry-append.sh`, `codemap-update.sh`,
  `codemap-graph.sh`, `progress.sh`.

### full-access — exige HITL para *cada ação*

- `git push`, `git reset --hard`, `git rebase` interativo, `git
  cherry-pick` cross-branch, qualquer operação que reescreva history
  publicada.
- Operações de rede saída fora do allowlist do `mcp/registry.json`.
- Leitura/uso de `.env`, `.env.local`, `.env.*.local`, credenciais.
- Cópia de dados de produção para dev/test (mesmo com máscara — humano confirma a máscara).
- Deploy, publicação de pacote, mutação de schema em prod.
- `gh` operações de escrita (issue create, PR create, comment) — humano
  confirma que o remote é o repo do produto, não o do harness.
- Mudanças no `AGENTS.md` — sempre via PR.
- Adição/promoção a `Knowledge Base` — sempre via ADR/PR (mitigação de
  memory poisoning).

## 4. Hard rules transversais (aplicam-se a todos os tiers)

Independente de tier, **nunca**:

- Workaround silencioso quando o blueprint está errado — use Spec Drift
  Protocol ([`../04-sprints/04-spec-drift-protocol.md`](../04-sprints/04-spec-drift-protocol.md)).
- Skip de gates `typecheck`/`lint`/`test` com flag (`--no-verify`,
  `--force`, `--skip-checks`).
- Edição de `tailwind.config.js` (proibido por convenção da stack).
- Uso de Pages Router (`getServerSideProps`, etc.).
- Paralelizar subagentes em arquivos sobrepostos.

## 5. Allowlist por tier no `AGENTS.md` do produto

O `AGENTS.md` de cada produto declara sua allowlist por tier:

```markdown
### Allowlist — read-only (sem gate)
- pnpm typecheck, pnpm lint, git status, git diff, git log
- bash <skill>/.../validate.sh, phase-status.sh, sprint-status.sh,
  story-list.sh, next-story.sh, spec-fetch.sh, telemetry-report.sh

### Allowlist — sandbox-edit (após Gate 1)
- pnpm install, pnpm dev, pnpm build, pnpm test, pnpm test:unit, pnpm test:e2e
- git add, git commit
- bash <skill>/.../telemetry-append.sh, codemap-update.sh, codemap-graph.sh,
  progress.sh

### Allowlist — full-access (HITL para cada ação)
- git push
- gh (todas as escritas)
- comandos de deploy
- qualquer rm fora de /tmp ou node_modules
- comandos com sudo, curl | sh, mutação de .env*
```

`validate.sh` (ou doc-check separado) verifica que o `AGENTS.md` do
produto declara as três seções.

## 6. Relação com o `agent-assisted` / `agent-driven`

O modo de operação (`agent-assisted` / `agent-driven`) **não substitui**
os tiers — eles compõem:

- `agent-assisted` + tier `sandbox-edit`: gate 1 + gate 2 (review do diff).
- `agent-assisted` + tier `full-access`: HITL para cada ação, sem default.
- `agent-driven` + tier `read-only`: aceitável para análises rotineiras.
- `agent-driven` + tier `sandbox-edit`: só com ADR explícito autorizando.
- `agent-driven` + tier `full-access`: **proibido** — sempre HITL.

## 7. Anti-padrões

- ❌ "O usuário aprovou rodar `gh pr create` ontem, hoje posso rodar de
  novo" — full-access é por-ação, não por-sessão.
- ❌ Classificar `rm` no tier `sandbox-edit` porque "estou no workspace"
  — depende do path; em path versionado é full-access.
- ❌ Adicionar comando novo à allowlist do produto sem mapeá-lo a um tier.
