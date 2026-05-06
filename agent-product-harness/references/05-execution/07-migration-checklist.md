# Migration / Schema Checklist

> Checklist obrigatório no Final Artifact de qualquer story que toque schema (Postgres / Supabase). Substitui "deixe-me ver depois".

> Complementa a skill externa `supabase` — quando a runtime tem essa skill, **invoque-a primeiro** para padrões de RLS, triggers e clients SSR; depois aplique este checklist como gate de PR.

---

## Quando aplicar

- Criar/alterar tabela, view, função, trigger, tipo enum.
- Criar/alterar políticas RLS.
- Criar/alterar índices.
- Seed inicial (admin, dados de domínio).
- Qualquer arquivo em `supabase/migrations/` ou `migrations/`.

---

## 1. Estrutura da migration

- [ ] Nome do arquivo segue convenção: `<timestamp>_<descricao_em_snake_case>.sql`.
- [ ] Idempotente quando aplicável: `create table if not exists`, `create or replace`, `on conflict do nothing` em seeds.
- [ ] **Tem rollback** (`down.sql` ou seção comentada com SQL inverso). Se irreverssível (ex.: drop column), justificar no commit.
- [ ] Não usa `drop` ou `truncate` em ambiente de produção sem flag explícita.
- [ ] Comentários SQL no início explicando **por que** a migration existe (link para story / ADR).

---

## 2. RLS (Row-Level Security)

> Se a tabela tem PII ou é multi-tenant, RLS é obrigatório.

- [ ] `alter table <t> enable row level security;` antes de qualquer policy.
- [ ] **Política por papel** para cada operação relevante:
  - [ ] `select` — quem pode ler.
  - [ ] `insert` — quem pode criar.
  - [ ] `update` — quem pode editar (e quais colunas).
  - [ ] `delete` — quem pode remover.
- [ ] Política `default deny` quando o domínio é sensível: nada passa sem regra explícita.
- [ ] Considera `auth.uid()` e `auth.jwt()->>'role'` (Supabase) ou equivalente.
- [ ] **Service role** documentado: que operação só roda via service role e por quê.
- [ ] Testou as políticas com **pelo menos 2 papéis distintos** (ex.: usuário comum + admin) em SQL ou teste de integração.

---

## 3. Triggers e funções

- [ ] Função declarada como `security definer` **só** quando necessário; documentar por quê.
- [ ] `set search_path = public, pg_temp` em funções `security definer` (mitigação de privilege escalation).
- [ ] Trigger cobre **casos de borda**:
  - [ ] Insert normal.
  - [ ] Update parcial (mudança de email, role, etc.).
  - [ ] Delete (cascata? soft delete?).
  - [ ] Reentrada (trigger não dispara a si mesmo em loop).
- [ ] Trigger não bloqueia operações inesperadas (ex.: trigger de signup que rejeita usuário deve dar mensagem clara, não falhar silencioso).

---

## 4. Whitelist / RBAC / autenticação

> Domínio sensível: gate de ADR obrigatório (veja [`SKILL.md`](../../SKILL.md) §D).

- [ ] Existe ADR aplicável em `docs/spec/adr/` referenciado no commit.
- [ ] Decisão de **default role** documentada (ex.: novo usuário entra como `efetivo`, não `admin`).
- [ ] **Bypass** para admin/seed declarado explicitamente — não como side-effect.
- [ ] Whitelist (se houver) é tabela versionada, **não hardcode** em SQL ou env var.
- [ ] Operações sensíveis (mudar role, criar admin) auditadas — log em tabela `audit_log` ou equivalente.

---

## 5. Seeds

- [ ] Seed de admin **não vaza segredos** no git: senha em env var ou via fluxo "primeiro login define senha".
- [ ] Seed é **idempotente**: rodar duas vezes não quebra nem duplica.
- [ ] Seed separado por ambiente: dados de dev ≠ dados de prod ≠ dados de teste.
- [ ] Seed em produção, se existir, está documentado no runbook de deploy.

---

## 6. Índices e performance

- [ ] FK tem índice (`create index on <t>(<fk>)`). Postgres não cria automaticamente.
- [ ] Coluna usada em `where` recorrente tem índice (verificar com `explain`).
- [ ] Índice composto na ordem certa (coluna mais seletiva primeiro).
- [ ] Sem índice redundante (ex.: `(a, b)` torna `(a)` parcialmente desnecessário).
- [ ] Queries pesadas previstas têm `explain analyze` no PR description.

---

## 7. Tipos e domínio

- [ ] `not null` em colunas obrigatórias. `null` é decisão, não default.
- [ ] `default` declarado quando faz sentido (`now()` em `created_at`, `false` em flag).
- [ ] Enum versus tabela de lookup: enum só se valores são finitos e estáveis. Caso contrário, tabela.
- [ ] Constraints (`check`, `unique`, `foreign key`) declaradas, não delegadas só à aplicação.
- [ ] Timestamps com timezone (`timestamptz`), não `timestamp` ingênuo.

---

## 8. Compatibilidade e rollout

- [ ] Migration **aditiva** quando possível: novas colunas como nullable; preencher; depois `not null`.
- [ ] Mudança breaking (rename, drop) tem janela de coexistência ou ADR justificando rollout direto.
- [ ] App roda contra schema antigo **e** novo durante o rollout? Se não, deploy precisa de ordem explícita no runbook.
- [ ] Backfill grande tem batch / lock-aware (não locka tabela inteira em prod).

---

## 9. Reprodutibilidade

- [ ] Migration roda limpa em base zero (`supabase db reset`).
- [ ] Migration roda em base já com dados (seed local) sem corromper.
- [ ] Tipos do client (Drizzle / Prisma / Supabase types) regenerados e commitados.
- [ ] Testes de integração que tocam essas tabelas atualizados / passando.

---

## 10. Final Artifact da story (gate de PR)

Antes de declarar a story pronta, anexe ao Final Artifact:

- [ ] Lista de itens deste checklist marcados.
- [ ] Saída de `supabase db reset` ou equivalente, mostrando migrations aplicadas em ordem.
- [ ] Saída de **teste de RLS com ≥ 2 papéis** (pode ser script SQL anexado).
- [ ] Diff do schema gerado (ex.: `supabase db diff`) confirmando que migrations refletem o estado pretendido.
- [ ] Risco residual conhecido (ou "nenhum identificado").

---

## Anti-padrões

- ❌ Migration sem RLS em tabela com PII — bloqueia merge.
- ❌ Trigger com `security definer` sem `search_path` — vulnerabilidade conhecida.
- ❌ Seed com senha hardcoded em SQL — vaza no git.
- ❌ "Migration roda em prod, no dev a gente não testou" — ordem invertida.
- ❌ Drop de coluna no mesmo PR que adiciona — sem janela de coexistência. Quebra rollout.
- ❌ Whitelist em variável de ambiente longa, mutada manualmente em produção — vire tabela.
