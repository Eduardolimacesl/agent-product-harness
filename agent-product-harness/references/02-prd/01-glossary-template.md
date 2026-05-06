# Glossary Template — `docs/prd/01-glossary.md`

> Vocabulário canônico do produto. **Carregado no bootstrap mínimo** de toda sessão de execução (veja [`SKILL.md`](../../SKILL.md) §D).

A fase PRD é onde o vocabulário operacional do domínio é fixado. Sem glossário, cada nova sessão reconstrói termos do zero — e o agente inevitavelmente colide com o usuário ("DT" significa coisas diferentes em discovery e em código).

> Personas vivem no PRD §3. **Glossário é diferente:** termos operacionais, siglas, status, papéis técnicos do domínio. O cruzamento PRD ↔ Spec ↔ Stories só funciona se este arquivo é canônico.

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

| Categoria | Exemplos |
|-----------|----------|
| **Papéis de usuário** | admin, coordenador, operador, viewer |
| **Status de domínio** | rascunho, em análise, aprovado, arquivado |
| **Entidades-chave** | inspeção, ordem, projeto, cliente |
| **Siglas operacionais** | DT, DA, FAB, SLA, NPS — formas extensas e contexto |
| **Termos técnicos com sentido específico** | "whitelist" significa o quê **neste produto**? |
| **Métricas de produto** | DAU, retenção D7, ativação |
| **Ambientes** | dev, staging, sandbox, prod — qual URL, qual dado |

---

## Critério de "pronto"

O glossário está em estado aceitável para gate de PRD quando:

- [ ] Todo termo de domínio que aparece no PRD tem entrada.
- [ ] Toda sigla usada está expandida pelo menos uma vez.
- [ ] Papéis e status estão **enumerados** (não "etc.").
- [ ] Nenhuma entrada diz "ver discovery" ou "TBD" — ou está definido, ou está marcado `🟡 a definir antes de Spec`.

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
