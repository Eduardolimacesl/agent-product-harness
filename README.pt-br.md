# Agent Product Harness — Repositório de Skill

Este repositório é a fonte da verdade para a skill **`agent-product-harness`**
— uma skill no formato Anthropic que inicializa (bootstrap) e executa produtos de software sob uma
metodologia disciplinada projetada para IDEs agentic (Antigravity,
Cursor, Codex).

A skill em si vive em [`agent-product-harness/`](./agent-product-harness/).
Este README é para **mantenedores** da skill — pessoas que estão aprimorando o harness.
Os usuários finais invocam a skill através de seu ambiente de execução (runtime); eles não navegam neste repositório.

---

## O que há neste repositório

```text
.
├── README.md                                  ← este arquivo (voltado para mantenedores)
└── agent-product-harness/                     ← a skill distribuível
    ├── SKILL.md                               ← manifesto + ponto de entrada
    ├── references/                            ← docs da metodologia (lidos sob demanda)
    │   ├── 00-architecture-and-flow.md
    │   ├── 00-paper-analysis.md
    │   ├── README.md
    │   ├── AGENTS.md
    │   ├── 01-discovery/
    │   ├── 02-prd/
    │   ├── 03-spec/
    │   ├── 04-sprints/
    │   ├── 05-execution/
    │   ├── 06-testing/
    │   └── 07-deploy/
    └── templates/                             ← scaffolding pronto para uso (WIP)
        └── docs/
```

- **`references/`** — a metodologia. O agente lê estes arquivos para entender os
  princípios, preencher templates e responder perguntas (Q&A). Nunca são copiados integralmente para os
  projetos dos usuários.
- **`templates/`** — arquivos pré-preenchidos e baseados em placeholders que são copiados para o
  projeto do usuário durante o bootstrap. **Atualmente vazio** — veja o roadmap abaixo.

---

## Como a skill é consumida

Formato Anthropic Skills (padrão aberto). Para tornar a skill disponível em um
runtime, coloque a pasta `agent-product-harness/` onde esse runtime procura por
skills:

| Runtime | Localização da Skill |
| :--- | :--- |
| Claude Code (nível de usuário) | `~/.claude/skills/agent-product-harness/` |
| Claude Code (nível de projeto) | `<projeto>/.claude/skills/agent-product-harness/` |
| Antigravity | diretório de skills análogo (compatível com formato Anthropic) |
| Cursor / Codex | clone o repositório e referencie via regras de projeto apontando para `agent-product-harness/SKILL.md` |

A distribuição mais simples é um **`git clone`** deste repositório, ou um symlink do
diretório de skills do runtime para `agent-product-harness/`.

---

## Instalação Local (No Projeto)

Para utilizar este harness em um projeto específico (instalação local), siga estes passos:

1. **Clone este repositório** em um local de sua preferência:

   ```bash
   git clone git@github.com:Eduardolimacesl/agent-product-harness.git
   ```

2. **Crie o diretório de skills** no seu projeto de destino (ex: para Antigravity):

   ```bash
   mkdir -p .gemini/antigravity/skills
   ```

3. **Crie um link simbólico (symlink)** da pasta da skill para o seu projeto:

   ```bash
   # Substitua /caminho/para/repositorio pelo caminho onde você clonou este repo
   ln -s /caminho/para/repositorio/agent-product-harness ./.gemini/antigravity/skills/agent-product-harness
   ```

Isso permite que você faça alterações neste repositório do harness e as veja refletidas imediatamente no seu projeto de desenvolvimento.

---

## Como os usuários a invocam

Em qualquer runtime compatível, o usuário digita algo como:

- *"Quero começar um produto novo seguindo o agent-product-harness"*
- *"Use a skill agent-product-harness para fazer bootstrap aqui"*
- *"Avance a fase do harness — terminamos discovery"*

O runtime faz a correspondência do pedido com o campo `description` em
[`agent-product-harness/SKILL.md`](./agent-product-harness/SKILL.md) e carrega
a skill. A partir daí, as instruções da skill assumem o controle.

---

## Roadmap (maturidade da skill)

### v0.1 — Capaz de Bootstrap a partir de referências *(atual)*

- A skill é invocável, pode responder perguntas sobre a metodologia.
- O caminho de bootstrap recorre a "escrever cada arquivo usando `references/<phase>/`
  como guia" porque `templates/` está vazio.

### v0.2 — Templates extraídos

- Cada arquivo em `references/0X-<phase>/` ganha um gêmeo simplificado, baseado em placeholders,
  em `templates/docs/<phase>/`.
- O bootstrap copia os templates integralmente e depois preenche as respostas a partir do
  Q&A inicial.
- ~40 min por arquivo de template. Feito à medida que o primeiro produto real é inicializado
  (extração durante o uso).

### v0.3 — Skills internas como templates

- Adição de `templates/skills/` com skills internas de semente para o produto:
  `server-action-with-zod`, `proxy-security-headers`, `cache-component-pattern`
  (todos já exemplificados em
  [`references/05-execution/04-skill-template.md`](./agent-product-harness/references/05-execution/04-skill-template.md)).

### v1.0 — Testado em produção

- Usado em pelo menos 1 produto real de ponta a ponta.
- Documento de observabilidade (`05-observability.md`) e documento de promoção de memória
  (`06-memory-promotion.md`) adicionados — fecha as lacunas P1 de
  [`references/00-paper-analysis.md`](./agent-product-harness/references/00-paper-analysis.md).
- Princípios P6–P9 promovidos da análise para `00-architecture-and-flow.md`.

---

## Melhorando o harness

Este repositório é a **fonte única da verdade**. O ciclo:

1. Use a skill em um produto real.
2. Note fricções (regra que confunde, campo de template que ninguém preenche,
   trava de fase que sempre falha pelo mesmo motivo).
3. Abra um PR aqui atualizando o arquivo relevante em `references/` ou `templates/`.
4. Gere uma nova versão (`v0.X`).
5. Puxe a atualização para o diretório de skills do runtime (`git pull`).

A seção §"Self-evolution" de
[`agent-product-harness/SKILL.md`](./agent-product-harness/SKILL.md) instrui
o agente a **sinalizar** débitos do harness durante as sessões para que eles surjam aqui.

---

## Versionamento

Versionamento semântico (mais ou menos) no nível da **skill**:

- **major** (`v1.0` → `v2.0`) — quebra a compatibilidade com projetos inicializados existentes
  (fases renomeadas, templates removidos). Notas de migração necessárias.
- **minor** (`v1.0` → `v1.1`) — adiciona novos templates, referências ou caminhos de skill
  sem quebrar as saídas anteriores.
- **patch** (`v1.0.1`) — correções de digitação, esclarecimentos, sem mudança de comportamento.

Fixe por tag no CI / configuração do runtime. **Não** acompanhe a `main` em projetos de
produção — fixe a versão para que um `git pull` não altere silenciosamente o harness sob um
produto em execução.

---

## Licença & Atribuição

A metodologia baseia-se em Zhou et al. (2026), *"Externalization in LLM Agents: A
Unified Review of Memory, Skills, Protocols and Harness Engineering"*
(arXiv:2604.08224v1). Veja
[`agent-product-harness/references/00-paper-analysis.md`](./agent-product-harness/references/00-paper-analysis.md)
para o mapeamento crítico entre o artigo e este harness.
