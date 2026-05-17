# Glossary Template — `docs/prd/01-glossary.md` (Ubiquitous Language)

> **Vocabulário canônico do produto** — em terminologia DDD, esta é a **Linguagem Ubíqua** (Ubiquitous Language) do(s) Bounded Context(s) ativos. Mesmas palavras no PRD, no chat com sponsor, nos critérios de aceite, **e** no código (entidade, campo, evento, papel).
>
> **Carregado no bootstrap mínimo** de toda sessão de execução (veja [`SKILL.md`](../../SKILL.md) §D).

A fase PRD é onde a linguagem ubíqua é fixada. Sem ela, cada nova sessão reconstrói termos do zero — e o agente inevitavelmente colide com o usuário ("DT" significa coisas diferentes em discovery e em código).

> Personas vivem no PRD §3. **Glossário é diferente:** termos operacionais, siglas, status, papéis técnicos do domínio, **eventos de negócio**. O cruzamento PRD ↔ Spec ↔ Stories ↔ código só funciona se este arquivo é canônico.

---

## Regra de ouro (DDD)

> **Termo só entra aqui se aparece — ou vai aparecer — no código.**

Se um termo é só de marketing ou copy interno sem reflexo em entidade/campo/status/evento/papel, ele **não** pertence à linguagem ubíqua: vive no PRD §10 (copy) ou na Knowledge Base. Misturar copy com linguagem ubíqua polui o glossário e perde a função de contrato PRD ↔ código.

Critério prático: para cada termo, responda **onde ele aparece (ou vai aparecer) no código?** — nome de classe, campo de tabela, valor de enum, nome de evento, rota, role. Se não houver resposta concreta, não é linguagem ubíqua.

---

## Como usar

1. **Crie no bootstrap.** O scaffolding inicializa este arquivo vazio em `docs/prd/01-glossary.md`.
2. **Atualize durante PRD.** Cada termo de domínio que aparece no PRD deve estar aqui antes do gate de aprovação.
3. **Atualize durante Spec.** Termos técnicos novos (ex.: papéis em RBAC) entram aqui.
4. **Lido em toda story.** O agente principal carrega este arquivo no bootstrap mínimo da sessão de execução.
5. **Termo não documentado = TODO.** Se o agente encontra um termo desconhecido, ele **pausa** e pede ao humano definição antes de codar.

---

## Estrutura

```markdown
# Glossário — `<NOME-DO-PRODUTO>`

**Status:** vivo
**Última atualização:** <YYYY-MM-DD>

---

## Convenções

- Termos em ordem alfabética.
- Cada entrada: **termo · definição · contexto onde aparece (PRD/Spec/UI/DB) · exemplo**.
- Conflitos de uso (mesma palavra com sentidos diferentes) são **resolvidos** aqui — não tolerados.
- Sigla sempre acompanha forma extensa na primeira menção do termo definido.

---

## A

### `<termo>`

**Definição:** <1-2 linhas, no idioma do usuário se possível>

**Aparece em:** PRD §X · Spec §Y · UI da tela `<...>` · tabela `<...>`

**Exemplo:** <frase que usa o termo corretamente>

**Não confundir com:** <termo similar, com a diferença explicada>

---

## B

...

```

---

## Categorias típicas a cobrir

Em quase todo produto, o glossário inclui pelo menos:

| Categoria | Exemplos | Reflexo típico no código |
|-----------|----------|--------------------------|
| **Papéis de usuário** | admin, coordenador, operador, viewer | enum `Role`, coluna `users.role`, função `requireRole()` |
| **Status de domínio** | rascunho, em análise, aprovado, arquivado | union de literais `Status`, coluna `<entidade>.status` |
| **Entidades-chave** | inspeção, ordem, projeto, cliente | classe/tabela `Inspection`, `Order`, `Project`, `Customer` |
| **Eventos de negócio** | "Inspeção concluída", "Pagamento aprovado" | classe `InspectionCompleted`, `PaymentApproved` em `src/domain/<contexto>/events/` |
| **Siglas operacionais** | DT, DA, FAB, SLA, NPS — formas extensas e contexto | constantes, campos de relatório |
| **Termos técnicos com sentido específico** | "whitelist" significa o quê **neste produto**? | tabela `whitelist`, função `isWhitelisted()` |
| **Métricas de produto** | DAU, retenção D7, ativação | views/queries de analytics, eventos de telemetria |
| **Ambientes** | dev, staging, sandbox, prod — qual URL, qual dado | `process.env.APP_ENV`, blocos de config |

> **Eventos de negócio** entram no glossário porque, em DDD, eles são contrato observável entre subdomínios. Se Sprint 03 adicionar um consumer de "Inspeção concluída", o nome do evento e seu payload precisam estar fixados antes — não inventados no momento de codar.

---

## Critério de "pronto"

O glossário está em estado aceitável para gate de PRD quando:

- [ ] Todo termo de domínio que aparece no PRD tem entrada.
- [ ] Toda sigla usada está expandida pelo menos uma vez.
- [ ] Papéis e status estão **enumerados** (não "etc.").
- [ ] **Cada entrada cita pelo menos um reflexo no código** (classe, tabela, campo, enum, evento, rota, role) — ou marca `🟡 reflexo a definir na Spec`.
- [ ] Nenhuma entrada diz "ver discovery" ou "TBD" — ou está definido, ou está marcado `🟡 a definir antes de Spec`.
- [ ] **Mesmo termo, mesma grafia no PRD, no código e nos critérios de aceite das stories.** Variações ("usuário" vs "operador" vs "user") tratadas como bug de linguagem ubíqua: consolidar antes do gate.

---

## Exemplo concreto (curto)

```markdown
### `Whitelist`

**Definição:** lista de domínios/emails autorizados a criar conta. Usuários fora dela são bloqueados no signup.

**Aparece em:** PRD §10 (privacidade), Spec §5 (auth), tabela `whitelist`, ADR-0002.

**Exemplo:** "Adicionar `@empresa.com.br` à whitelist permite que qualquer pessoa do domínio se cadastre."

**Não confundir com:** allowlist de comandos do agente (`AGENTS.md` §2.1) — escopo diferente.

---

### `DT` (Dia Trabalhado)

**Definição:** um dia útil em que o operador esteve presente em campo. Apurado pelo coordenador semanalmente.

**Aparece em:** PRD §11 (métricas), tela `relatorio-mensal`, tabela `apuracoes`.

**Exemplo:** "Operadores efetivos têm meta de 22 DT/mês."

**Não confundir com:** `DA` (Dia Ausente) — ver entrada própria.
```

---

## Anti-padrões

- ❌ "Definição vai para o ADR mais tarde." → não. Ou está aqui, ou termo não é usado em PRD.
- ❌ Entrada em prosa > 5 linhas. → glossário é referência rápida, não doc longo.
- ❌ Mesmo termo com 2 entradas. → consolide.
- ❌ Glossário só com siglas, sem papéis/status/entidades. → metade do problema persiste.
- ❌ Não atualizar quando o domínio muda. → glossário desatualizado é pior que ausência: agente confia, e erra.
- ❌ **Termo no glossário sem reflexo no código.** → é copy ou marketing; mude de lugar (PRD §10 ou Knowledge Base).
- ❌ **Termo no código sem entrada no glossário.** → linguagem ubíqua quebrada. Adicione a entrada ou renomeie no código para um termo que já existe.
- ❌ **Tradução silenciosa** (PRD diz "operador", código diz `worker`). → escolha um lado, fixe no glossário, renomeie o outro. Toda tradução acumula bug de comunicação.
