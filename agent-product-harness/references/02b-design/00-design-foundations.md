# Design Foundations — `<NOME-DO-PRODUTO>`

> Documento da fase **02.5 — Design Foundations**, entre PRD e Tech Spec.
> Define a identidade visual, tokens de design e princípios de UX **antes** de qualquer componente UI ser implementado.

**Owner:** `<designer ou eng lead>`
**Status:** `📝 draft | 👀 review | ✅ approved`
**PRD de origem:** `docs/prd/<arquivo>.md`
**Última atualização:** `<YYYY-MM-DD>`

---

## Por que esta fase existe

Tailwind v4 com `@theme` em `globals.css` exige **tokens definidos antes do primeiro componente**. Refazer paleta, tipografia ou raio depois custa caro: cada componente Shadcn já consumiu os tokens errados.

A fase Design Foundations existe para:

1. Travar a identidade visual (paleta, tipografia, motion) antes que qualquer story de UI entre em execução.
2. Produzir um **starter kit visual** (botões, inputs, cards, modais) verificável em screenshot.
3. Servir como referência única para os agentes que vão implementar componentes — sem improviso de paleta a cada story.

**Outputs esperados:**

- `docs/spec/01-design-system.md` (este template, preenchido).
- Bloco `@theme` em `app/globals.css` com tokens de cor, tipografia, escala, raios, sombras, motion.
- Screenshot do starter kit (gerado por browser subagent) anexado ao Artifact final.

**Gate de saída:** aprovação visual humana sobre o screenshot do starter kit. Sem isso, nenhuma story de UI avança.

---

## 1. Análise da identidade visual

> Se há logo / brand assets existentes, comece por eles. Se é greenfield, gere moodboard primeiro e anexe à seção 11.

**Logo / brand assets analisados:**

```
[caminho ou link das imagens analisadas]
```

**Cores extraídas (do logo / referências):**

| Papel | Hex | Justificativa |
|-------|-----|---------------|
| Primária | `#______` | `<por que esta cor?>` |
| Secundária | `#______` | `<...>` |
| Acento | `#______` | `<...>` |

**Sensação pretendida** (3 adjetivos): `<ex: confiável, técnico, ágil>`

**Referências visuais** (concorrentes, produtos admirados):

- `<ref 1 + por quê>`
- `<ref 2 + por quê>`

---

## 2. Tokens de cor

> Definir light **e** dark. Nomeie por **papel semântico**, não por matiz (`primary`, não `blue-800`). O matiz pode mudar; o papel não.

### 2.1 Cores semânticas

| Token | Light | Dark | Uso |
|-------|-------|------|-----|
| `--color-bg` | `#______` | `#______` | fundo padrão da página |
| `--color-fg` | `#______` | `#______` | texto padrão |
| `--color-muted` | `#______` | `#______` | texto secundário |
| `--color-primary` | `#______` | `#______` | ações primárias, links |
| `--color-primary-fg` | `#______` | `#______` | texto sobre primária |
| `--color-accent` | `#______` | `#______` | destaque pontual |
| `--color-success` | `#______` | `#______` | sucesso, confirmação |
| `--color-warning` | `#______` | `#______` | alerta, atenção |
| `--color-danger` | `#______` | `#______` | erro, destrutivo |
| `--color-border` | `#______` | `#______` | divisores, bordas |
| `--color-ring` | `#______` | `#______` | foco visível |

### 2.2 Contraste (WCAG)

Para cada par texto/fundo principal, verifique contraste mínimo:

| Par | Ratio | WCAG |
|-----|-------|------|
| `fg` sobre `bg` | `<X:1>` | AA / AAA |
| `primary-fg` sobre `primary` | `<X:1>` | AA / AAA |
| `muted` sobre `bg` | `<X:1>` | AA / AAA |

> **Mínimo:** 4.5:1 para texto normal, 3:1 para texto grande / não-texto. Pares que falham → ajustar antes de prosseguir.

---

## 3. Tipografia

| Token | Valor | Uso |
|-------|-------|-----|
| `--font-sans` | `<ex: 'Inter', system-ui, sans-serif>` | UI geral |
| `--font-mono` | `<ex: 'JetBrains Mono', monospace>` | código, dados |
| `--font-display` | `<opcional>` | títulos hero |

**Escala tipográfica:**

| Token | Tamanho | Line-height | Uso |
|-------|---------|-------------|-----|
| `--text-xs` | 0.75rem | 1rem | legendas |
| `--text-sm` | 0.875rem | 1.25rem | UI secundária |
| `--text-base` | 1rem | 1.5rem | corpo |
| `--text-lg` | 1.125rem | 1.75rem | subtítulos |
| `--text-xl` | 1.25rem | 1.75rem | títulos pequenos |
| `--text-2xl` | 1.5rem | 2rem | títulos seção |
| `--text-3xl` | 1.875rem | 2.25rem | títulos de página |

**Pesos disponíveis:** `<ex: 400, 500, 600, 700>` — não use mais de 4.

---

## 4. Espaçamento, raios e sombras

**Espaçamento:** Tailwind default (4px scale) salvo justificativa explícita.

**Raios:**

| Token | Valor | Uso |
|-------|-------|-----|
| `--radius-sm` | 0.25rem | inputs pequenos, badges |
| `--radius` | 0.5rem | botões, cards |
| `--radius-lg` | 0.75rem | modais |
| `--radius-full` | 9999px | avatars, pills |

**Sombras:**

| Token | Valor | Uso |
|-------|-------|-----|
| `--shadow-sm` | `<...>` | cards em repouso |
| `--shadow` | `<...>` | dropdowns, popovers |
| `--shadow-lg` | `<...>` | modais |

---

## 5. Motion

| Token | Valor | Uso |
|-------|-------|-----|
| `--ease-out` | `cubic-bezier(0.16, 1, 0.3, 1)` | entrada padrão |
| `--ease-in` | `cubic-bezier(0.7, 0, 0.84, 0)` | saída padrão |
| `--duration-fast` | 150ms | hover, foco |
| `--duration-base` | 250ms | dropdowns, toggles |
| `--duration-slow` | 400ms | modais, page transitions |

**Princípio:** respeitar `prefers-reduced-motion`. Implementação obrigatória em `globals.css`.

---

## 6. Princípios de UX (verificáveis)

> Cada princípio precisa de **critério verificável**, não slogan. Se você não consegue testar, não é princípio — é desejo.

| Princípio | Critério verificável |
|-----------|---------------------|
| Mobile-first | toda tela renderiza usável em 360px de largura sem scroll horizontal |
| Foco sempre visível | todo elemento focável tem outline com `--color-ring` ≥ 2px |
| Contraste mínimo | nenhum par texto/fundo abaixo de 4.5:1 |
| Carga leve | LCP < 2.5s p75 em conexão 3G simulada |
| Feedback imediato | toda ação destrutiva pede confirmação; toda ação assíncrona mostra loading em < 100ms |
| Erro nunca culpa o usuário | mensagens de erro descrevem causa + ação a tomar, não código técnico |

---

## 7. Estados de componentes-chave

> Para cada componente listado, descreva os estados e referencie o equivalente Shadcn (se aplicável).

### 7.1 Botão

| Estado | Comportamento visual | Token de cor |
|--------|---------------------|--------------|
| default | fundo `--color-primary`, texto `--color-primary-fg` | — |
| hover | escurece 10% | — |
| active | escurece 20% | — |
| focus | adiciona ring 2px `--color-ring` | — |
| disabled | opacidade 0.5, sem hover | — |
| loading | spinner inline, texto reduzido a label "Carregando" | — |

Variantes: `primary`, `secondary`, `ghost`, `destructive`. Tamanhos: `sm`, `default`, `lg`, `icon`.

Shadcn equivalente: [`Button`](https://ui.shadcn.com/docs/components/button)

### 7.2 Input

| Estado | Comportamento visual |
|--------|---------------------|
| default | borda `--color-border`, fundo `--color-bg` |
| focus | ring 2px `--color-ring`, borda `--color-primary` |
| error | borda `--color-danger`, ícone de alerta, helper text vermelho |
| disabled | opacidade 0.5, fundo `--color-muted` |

Shadcn equivalente: [`Input`](https://ui.shadcn.com/docs/components/input)

### 7.3 Card

Padrão: borda `--color-border`, fundo `--color-bg`, raio `--radius`, sombra `--shadow-sm`. Hover (se interativo): `--shadow`.

Shadcn equivalente: [`Card`](https://ui.shadcn.com/docs/components/card)

### 7.4 Modal / Dialog

Overlay: `rgba(0,0,0,0.5)` (light) / `rgba(0,0,0,0.7)` (dark). Conteúdo: raio `--radius-lg`, sombra `--shadow-lg`. Foco preso (focus trap). Fecha com Esc.

Shadcn equivalente: [`Dialog`](https://ui.shadcn.com/docs/components/dialog)

---

## 8. Bloco `@theme` final

> Cole aqui o bloco que será gravado em `app/globals.css`. Esta seção é o **contrato com o código**.

```css
@import "tailwindcss";

@theme {
  /* cores */
  --color-bg: #______;
  --color-fg: #______;
  /* ... etc, conforme seções 2–5 ... */
}

@media (prefers-color-scheme: dark) {
  @theme {
    --color-bg: #______;
    /* ... */
  }
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## 9. Starter kit — checklist visual

Antes de aprovar esta fase, gere uma página `/_design` (não-produção) com:

- [ ] Todos os botões em todos os estados (default, hover, focus, disabled, loading).
- [ ] Inputs (default, focus, error, disabled) com label e helper text.
- [ ] Cards (estático e interativo).
- [ ] Modal aberto.
- [ ] Tipografia: H1, H2, H3, parágrafo, código inline, código em bloco.
- [ ] Toast / alerta de sucesso, warning, error.
- [ ] Cores semânticas em swatches com label do token.

**Screenshot anexado:** `<link ou caminho para o Artifact>`

> Use o **browser subagent** para gerar e validar o screenshot. O agente principal não inspeciona pixels.

---

## 10. Aprovação

| Papel | Pessoa | Status |
|-------|--------|--------|
| Sponsor / PO | `<...>` | ⬜ |
| Eng lead | `<...>` | ⬜ |
| Designer (se houver) | `<...>` | ⬜ |

**Razão de aprovação ou ajuste pedido:**

```
[texto]
```

---

## 11. Anexos

- Moodboard: `<link>`
- Logos / brand assets: `<caminho>`
- Inspirações: `<links>`

---

## Como instruir o agente nesta fase

```
Sua tarefa é me ajudar a produzir o Design Foundations do produto.

Inputs disponíveis:
- PRD aprovado em docs/prd/<arquivo>.md (leia personas e fluxos principais).
- Logo / brand assets em <caminho>.

Sequência:
1. Analise o(s) logo(s) e proponha paleta primária + secundária + acento, com hex e justificativa.
2. Para cada par texto/fundo principal, calcule contraste WCAG e ajuste se < 4.5:1.
3. Proponha tipografia (sans + mono), escala e pesos. Justifique escolha.
4. Proponha tokens de raio, sombra e motion.
5. Para cada componente-chave (botão, input, card, modal), descreva estados e mapeie para tokens.
6. Gere o bloco @theme final que entra em app/globals.css.
7. Crie a rota /_design com o starter kit (seção 9). Use browser subagent para gerar screenshot.
8. Pause para aprovação humana antes de qualquer story de UI.

NÃO comece a implementar componentes de domínio (US-XX) antes deste documento ser aprovado.
Marque com 🟡 qualquer ponto onde você inferiu algo no lugar de me perguntar.
```
