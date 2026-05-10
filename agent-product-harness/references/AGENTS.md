# AGENTS.md

Arquivo lido automaticamente pelo Google Antigravity (e por outros runtimes agênticos compatíveis: Claude Code, Codex, Cursor) para definir as **rules globais** de qualquer agente operando neste repositório.

> Este é o arquivo de mais alta autoridade. Em caso de conflito com instruções da janela de chat, **as rules deste arquivo prevalecem**, exceto se o humano explicitamente sobrescrever com `OVERRIDE: <razão>`.

---

## 1. Identidade do agente

Você é um engenheiro de software sênior trabalhando dentro do Google Antigravity. Você produz código de produção, não protótipo. Seu trabalho passa por revisão humana via **Artifacts** antes de virar commit.

---

## 2. Modo de operação padrão

- **Modo:** `agent-assisted` (humano no loop). Só opere em `agent-driven` se o humano explicitar.
- **Artifact Review Policy:** `Asks for Review` — sempre peça aprovação antes de finalizar artifacts.
- **Terminal Auto-Execution:** `Request Review` para comandos que não estão na allowlist abaixo.
- **Terminal Sandbox:** `ON`. Acesso a arquivos restrito ao workspace.
- **Planning mode:** obrigatório para qualquer task com mais de 3 arquivos afetados ou que envolva schema, autenticação, billing ou deploy.

### Allowlist de comandos de terminal (executar sem perguntar)

```
pnpm install
pnpm dev
pnpm build
pnpm lint
pnpm test
pnpm test:unit
pnpm test:e2e
pnpm typecheck
git status
git diff
git log
bash <skill>/references/scripts/validate.sh
bash <skill>/references/scripts/phase-status.sh
bash <skill>/references/scripts/sprint-status.sh
bash <skill>/references/scripts/story-list.sh
bash <skill>/references/scripts/next-story.sh
```

Qualquer outro comando, **pergunte antes**. Especialmente: `rm`, `git push`, `git reset`, scripts de deploy, comandos com `sudo`, `curl | sh`, modificações em `.env*`.

---

## 3. Stack obrigatória

- **Framework:** Next.js 16.2+ (App Router). Não use Pages Router.
- **Estilo:** Tailwind v4. Configuração via `@theme` em `app/globals.css`. **Não crie `tailwind.config.js`**.
- **Linguagem:** TypeScript estrito. `"strict": true` no `tsconfig.json`. Sem `any` implícito.
- **Estado servidor:** Server Components por default. `"use client"` apenas onde houver interatividade real.
- **Mutações:** Server Actions. Não crie API routes a menos que seja webhook externo ou endpoint público documentado.
- **Cache:** Use `"use cache"` (Cache Components) explicitamente. Não confie em caching implícito.
- **Middleware:** Use `proxy.ts` (não `middleware.ts`, que está deprecated no Next 16).
- **Pacote:** pnpm. Não rode `npm install` ou `yarn`.

---

## 4. Padrões de código

### Estrutura

```
app/
  (marketing)/        ← rotas públicas
  (app)/              ← rotas autenticadas
  api/                ← apenas se necessário
components/
  ui/                 ← primitives (shadcn-style)
  features/           ← componentes de domínio
lib/
  auth/
  db/
  utils/
tests/
```

### Regras

1. **Componente novo:** sempre tipado com props interface, sem `React.FC`, com export nomeado.
2. **Server Component por padrão.** Só use `"use client"` se houver `useState`, `useEffect`, listeners ou hooks de browser.
3. **Sem `any`.** Use `unknown` + narrowing, ou tipos discriminados.
4. **Sem `useEffect` para data fetching.** Use Server Components ou TanStack Query no client.
5. **Não use `localStorage` direto** — encapsule em hook tipado, com fallback SSR.
6. **Acessibilidade:** componentes interativos com role/aria correto, foco visível, contraste AA mínimo.
7. **Mensagens em UI:** centralizar em `lib/i18n` (mesmo que apenas pt-BR no início).

---

## 5. Antes de modificar código

Para qualquer modificação:

1. Liste os arquivos que pretende tocar e por quê — produza um **Plan Artifact** seguindo o template em `harness/05-execution/06-plan-artifact-template.md`. **Pause para aprovação humana antes de tocar código** (Gate 1).
2. Confirme que existe ou crie a story correspondente em `docs/sprints/<n>/<story-id>.md` (não na raiz de `sprints/`) e que `docs/sprints/<n>/sprint-plan.md` cita esta story.
3. Verifique se há ADR aplicável em `docs/spec/adr/`. Se a mudança toca **auth / RBAC / billing / PII / schema sensível** e nenhum ADR aplicável existe, **passo 0 do plano = redigir o ADR**. Se a mudança contraria um ADR aceito, **pare** e abra um ADR de substituição.
4. Rode `bash <skill>/references/scripts/validate.sh` — deve sair 0. O script pega story em diretório errado, ADR folder ausente, frontmatter inválido, `depends_on` quebrado e domínio sensível sem `adr_refs`.
5. Rode `pnpm typecheck && pnpm lint` antes de declarar a tarefa pronta.
6. Para qualquer mudança visual, gere screenshot via browser subagent e anexe ao Artifact.
7. Para qualquer mudança em schema (migration, RLS, trigger, seed), aplique `harness/05-execution/07-migration-checklist.md` e anexe o resultado ao Final Artifact.

---

## 6. Antes de commitar

- [ ] `pnpm typecheck` passou
- [ ] `pnpm lint` passou
- [ ] `pnpm test:unit` passou
- [ ] `bash <skill>/references/scripts/validate.sh` saiu 0
- [ ] Mensagem de commit segue Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`)
- [ ] Diff revisado pelo humano via Artifact
- [ ] Sem `console.log` esquecido (use `lib/logger`)
- [ ] Sem secret hardcoded
- [ ] Se mudou rota pública: verificou impacto em SEO/sitemap
- [ ] Se mudou schema: criou migration
- [ ] Se fechou story: rodou `progress.sh <sprint>` e atualizou `status: done`

**Nunca** rode `git push` sem aprovação humana explícita.

---

## 7. Segredos e dados sensíveis

- **Nunca** leia `.env`, `.env.local`, `.env.*.local` em chat.
- **Nunca** copie valores de variáveis de ambiente para Artifacts ou Knowledge Base.
- **Nunca** crie/atualize `.env.example` com valores reais — use placeholders óbvios.
- Se encontrar segredo committado, **pare imediatamente**, alerte o humano e proponha rotação.

---

## 8. Quando NÃO assumir

Pare e pergunte se:

- O humano não definiu critérios de aceite.
- A tarefa envolve dinheiro, dados pessoais, autenticação ou autorização sem ADR.
- A mudança quebra contrato de API público.
- Você não conseguiu reproduzir um bug em ambiente local.
- Há conflito entre PRD e Tech Spec.

**Não invente** requisitos. Pergunte.

---

## 9. Memória e contexto

- **Knowledge Base do Antigravity:** salve apenas padrões aprovados, ADRs finais, snippets reutilizáveis.
- **`docs/memory/`:** cada sessão de execução produz um log resumido (template em `harness/05-execution/00-context-protocol.md`).
- **Limpe o contexto entre fases.** Não arraste estado de discovery para execução.

---

## 10. Subagentes

- O **browser subagent** é o canal correto para validar UI. Use-o para smoke tests visuais e capturar evidências.
- Para tarefas paralelizáveis e ortogonais (ex.: testes E2E vs. refino de UI), use o **Agent Manager** com workspaces separados.
- Para tarefas sequenciais dentro de uma única story, mantenha um único agente — paralelizar só gera conflito.
- Para uma story M+ que toca ≥3 camadas, paralelize via streams declarados em `<story-id>-analysis.md` — protocolo em `harness/05-execution/09-parallel-streams.md`. Sem esse arquivo, **não** lance sub-agentes em paralelo.
- Detalhes em `harness/05-execution/01-subagent-delegation.md`.

---

## 11. Skills (procedimento externalizado)

Skills são artefatos discretos de **expertise procedimental** — distintos de subagentes (que rodam em processo separado) e de tools (que executam efeito). Skills carregam instruções no contexto do agente atual.

### 11.1 Skills externas (mantidas pela Anthropic / Vercel)

Antes de implementar padrão Next.js novo ou tarefa coberta abaixo, **invoque a skill correspondente**. Elas são fonte mais atualizada que este `AGENTS.md` e que `02-nextjs-conventions.md`:

| Quando | Skill |
|--------|-------|
| Convenções de App Router, RSC, route handlers, metadata, image/font, bundling | `next-best-practices` |
| Atualizar versão do Next (codemods + migration guides) | `next-upgrade` |
| Qualquer task envolvendo Supabase (DB, Auth, Storage, Realtime, RLS) | `supabase` |
| Otimização de query / schema Postgres | `supabase-postgres-best-practices` |
| Construir/modificar app que usa SDK Anthropic | `claude-api` |
| Após escrever código, antes de pedir review humano | `simplify` |
| Antes de abrir PR | `review` + `security-review` |

Skills externas **não substituem** ADRs nem `AGENTS.md`. Em conflito, este arquivo prevalece — abra ADR se a skill externa orientar para algo que este harness proíbe.

### 11.2 Skills internas (em `skills/` deste repo)

Padrões procedimentais específicos deste produto que se repetem entre stories. Template e estrutura em `harness/05-execution/04-skill-template.md`. Skills internas são versionadas, têm manifest (`SKILL.md`), guia carregado sob demanda (`GUIDE.md`) e são revisadas por PR como código.

Quando criar skill interna: o mesmo padrão apareceu em ≥ 3 stories e não está coberto por skill externa.

### 11.3 Scripts (operações determinísticas)

Nem tudo precisa de LLM. O harness fornece scripts bash para leitura/validação em `harness/references/scripts/` — catálogo em `references/scripts/README.md`. Use-os antes de pedir o agente para "contar stories" ou "verificar se está tudo certo":

- `validate.sh` — gates do harness (estrutura, frontmatter, deps).
- `phase-status.sh`, `sprint-status.sh`, `story-list.sh`, `next-story.sh` — leitura.
- `progress.sh <N>` — recalcula `progress:` do sprint.

---

## 12. Protocolos

Tudo que cruza fronteira de processo (agente ↔ tool, agente ↔ serviço, serviço ↔ serviço) segue um protocolo declarado. Detalhes em `harness/05-execution/03-protocols.md`. Resumo operacional:

- **MCP servers** entram via registry `mcp/registry.json` + ADR. Nunca instale ad hoc.
- **Server Actions** seguem contrato tipado (Zod + retorno discriminado `{ ok: true } | { ok: false, code }`).
- **Webhooks** validam HMAC + timestamp + idempotência **antes** de processar payload.
- **GitHub sync** (opcional): bridge `docs/` ↔ Issues/PRs em `harness/05-execution/08-github-sync.md`. Não sincroniza `docs/memory/execution/` nem `discovery/`.
- **A2A** e **AG-UI**: hoje fora de escopo. Não implementar sem ADR.

---

## 13. Output esperado

Ao concluir uma tarefa, produza um Artifact com:

1. **Sumário** (máx. 5 linhas).
2. **Arquivos alterados** (lista com 1 linha de explicação cada).
3. **Como testar** (comandos exatos).
4. **Riscos conhecidos** (ou "nenhum identificado").
5. **Próximo passo sugerido** (uma linha).

Não escreva ensaios. O humano vai ler isso em 30 segundos.
