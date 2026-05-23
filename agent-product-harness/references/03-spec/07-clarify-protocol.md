# Clarify Protocol — resolução estruturada de ambiguidade

> Gate anti-ambiguidade **antes** do planejamento. Quando o PRD ou a Tech
> Spec deixa uma decisão em aberto, o agente **marca** a lacuna em vez de
> adivinhar. Importado da filosofia Spec-Driven Development (github/spec-kit,
> comando `/clarify`); ancorado em P10 (SNR) e P1 (documento antes de código).

## 1. Princípio

A maior fonte de retrabalho não é código errado — é código **certo para a
spec errada**. O agente preenche silenciosamente toda lacuna que encontra,
e cada preenchimento é uma aposta não-registrada. O Clarify Protocol troca
*recall* (o agente inventa o que falta) por *recognition* (o humano
reconhece a pergunta e decide) — exatamente a transformação representacional
do P7.

Regra-mãe: **ambiguidade vira pergunta explícita, nunca suposição implícita.**

## 2. O marcador `[NEEDS CLARIFICATION]`

Sempre que o agente, ao redigir ou ler um artefato, encontra uma decisão que
o PRD/Spec/ADR não responde, insere **inline**, no ponto exato:

```
[NEEDS CLARIFICATION: <pergunta objetiva e binária quando possível>]
```

Exemplos:

```
A inspeção pode ser editada após finalizada?
[NEEDS CLARIFICATION: edição pós-finalização é permitida? Se sim, gera nova versão ou sobrescreve?]

Retenção de dados: [NEEDS CLARIFICATION: prazo de retenção do anexo de inspeção — 1 ano, 5 anos, indefinido?]
```

Regras do marcador:

- **Uma pergunta por marcador.** Compostas viram dois marcadores.
- **Binária ou de múltipla escolha** sempre que possível — reduz ida-e-volta.
- O marcador `🟡` (legado nos templates) é alias visual; **sempre o promova**
  ao `[NEEDS CLARIFICATION: …]` com a pergunta dentro antes de pedir o gate.
- Marcador é detectado por [`../scripts/check-clarifications.sh`](../scripts/check-clarifications.sh).

## 3. Quando o gate dispara (dois pontos)

| Transição | O que checa |
|---|---|
| **PRD → Spec** | zero marcadores em `docs/prd/` |
| **Spec → Sprint** | zero marcadores em `docs/spec/` |

Antes de avançar a fase, rode `check-clarifications.sh`. Se houver marcador
não resolvido, a fase **não** avança (cf. gate em [`../../SKILL.md`](../../SKILL.md) §B).
Marcadores são **legítimos durante o draft** — o gate só exige zero no momento
da transição.

## 4. A varredura por cobertura (antes de redigir o gate)

Não espere os marcadores surgirem por acaso. Ao fechar PRD ou Spec, varra
estas categorias e marque o que não estiver respondido. É a versão harness
do questionário por cobertura do `/clarify`:

1. **Atores e permissões** — quem pode fazer o quê? Há papel não mapeado no RBAC?
2. **Estados e transições** — todo estado de entidade tem entrada e saída definidas?
3. **Casos de borda** — vazio, máximo, concorrência, offline, re-entrega.
4. **Dados** — sensibilidade, retenção, deleção, base legal (LGPD).
5. **Erros** — o que o usuário vê quando falha? Mensagem e recuperação.
6. **Não-funcionais** — algum budget de perf/a11y/segurança sem número?
7. **Integrações** — contrato de cada borda externa está fechado?
8. **Escopo** — o que é explicitamente *fora* desta versão?

Cada categoria sem resposta clara → um `[NEEDS CLARIFICATION]`.

## 5. O log de Clarifications

As respostas humanas viram registro versionado, não conversa efêmera. Toda
Tech Spec e PRD carrega uma seção `## Clarifications` com sessões datadas:

```markdown
## Clarifications

### Sessão 2026-05-23
- P: edição pós-finalização é permitida? → R: não; finalizada é imutável. Correção vira nova inspeção vinculada.
- P: retenção do anexo? → R: 5 anos (exigência regulatória). ADR-0007 registra.
```

Ao resolver, **remova o marcador inline** e reescreva o trecho com a decisão,
deixando o rastro no log. Decisões com impacto arquitetural viram ADR (não
só log).

## 6. Relação com o Spec Drift Protocol

São complementares e **não** se sobrepõem:

| | Clarify | Spec Drift |
|---|---|---|
| Quando | **antes** de planejar (fase Spec/Sprint) | **durante** a execução |
| Sintoma | a spec **não responde** algo | a spec **contradiz** a realidade do código |
| Saída | marcador resolvido + log/ADR | `blocked-spec-drift` + decisão A/B/C |
| Referência | este documento | [`../04-sprints/04-spec-drift-protocol.md`](../04-sprints/04-spec-drift-protocol.md) |

Ambiguidade resolvível por leitura **não** é clarify (igual ao drift: typo e
escolha cosmética não disparam). Clarify é para decisão ausente, não para
preguiça de ler.

## 7. Anti-padrões

- ❌ Adivinhar o que o PRD não diz e seguir codando ("o que faz mais sentido").
- ❌ Marcar com `🟡` genérico sem a pergunta dentro.
- ❌ Resolver o marcador no chat e não registrar no log de Clarifications.
- ❌ Avançar a fase com marcadores abertos por "estarem quase resolvidos".
- ❌ Empilhar 8 perguntas abertas num marcador só.

## 8. Caso de teste (dry-run)

**Cenário:** ao fechar a Tech Spec de `inspectai`, o agente varre §4 (atores)
e nota que o PRD cita "auditor externo" mas o RBAC só tem `admin | inspector
| viewer`.

**Passos esperados:** agente insere
`[NEEDS CLARIFICATION: "auditor externo" é um quarto papel ou um viewer com escopo? Que permissões?]`
em §8 → roda `check-clarifications.sh` (sai 1, lista o marcador) → apresenta
ao humano → humano decide "viewer com escopo read-only por organização" →
agente remove o marcador, reescreve §8, anexa ao `## Clarifications` da Spec e
abre ADR-0008 (decisão de RBAC) → `check-clarifications.sh` sai 0 → fase
Spec → Sprint destrava.
