# Discovery — Elicitation Guide

> Roteiro discriminador que o agente usa para conduzir a entrevista de discovery. **Sem este guide, o brief vira preenchimento de campo.**

A heurística "o agente faz perguntas até preencher" só funciona se houver:

1. **Árvore de perguntas** com follow-ups por seção.
2. **Padrões de challenge** que detectam respostas rasas.
3. **Critério explícito de "pronto para PRD"**.

Este documento define os três. O agente deve **citar este guide** ao iniciar a fase de discovery e marcar as perguntas que ainda não tiveram resposta.

---

## Princípios da entrevista

- **Pergunta única por vez.** Múltiplas perguntas em um bloco fazem o humano responder só a última.
- **Profundidade > largura.** Antes de passar para a próxima seção, esgote follow-ups da atual.
- **Não invente respostas.** Se o humano não sabe, registre como "hipótese a validar" — não preencha por inferência.
- **Sinais vermelhos param a entrevista.** Contradição entre seções, lacuna em métrica primária, falta de evidência → pare e confronte antes de seguir.

---

## Árvore de perguntas por seção

### Seção 1 — Problema

**Pergunta-âncora:** "Em uma frase, qual é o problema?"

Follow-ups (faça em ordem; pule se já respondido):

1. "Quem mais sente esse problema, além de você?" — força sair de N=1.
2. "Com que frequência ele acontece? Diária, semanal, situacional?"
3. "O que acontece hoje quando o problema ocorre? Qual é o workaround atual?"
4. "Quanto custa o problema hoje — em tempo, dinheiro, qualidade ou frustração?"
5. "Há quanto tempo isso acontece? O que mudou (ou não) desde então?"
6. "Você já tentou resolver antes? O que falhou?"

**Sinais vermelhos:**

- 🚨 "Acho que todo mundo tem esse problema" sem segmentação.
- 🚨 "Custa muito tempo" sem nenhum número (mesmo grosseiro).
- 🚨 Workaround atual descrito vagamente ("uma planilha aí").
- 🚨 Tentativas anteriores não citadas — provável que não tenha investigado.

### Seção 2 — Hipótese

**Pergunta-âncora:** "Qual é a sua hipótese — `acreditamos que [solução] resolve [problema] para [pessoa] gerando [resultado]`?"

Follow-ups:

1. "O que **invalidaria** essa hipótese? Qual evidência te faria desistir?"
2. "Qual é o **menor experimento** que você consegue rodar para testá-la?"
3. "Por que esta solução, e não as 2-3 alternativas óbvias?"
4. "Se a hipótese estiver certa, qual seria o efeito de segunda ordem (bom ou ruim) no negócio?"

**Sinais vermelhos:**

- 🚨 Hipótese não tem critério de invalidação. → "É só fazer e ver" não é hipótese, é palpite.
- 🚨 Confiança "alta" sem evidência quantitativa.
- 🚨 Solução já está pré-decidida e o problema foi escrito para caber nela.

### Seção 3 — Evidências

**Pergunta-âncora:** "Que evidências você tem hoje?"

Follow-ups:

1. "Quantas entrevistas / observações reais? Com quantas pessoas distintas?"
2. "Há dado quantitativo (analytics, suporte, planilha) ou só qualitativo?"
3. "Qual o **insight mais surpreendente** que você ouviu? Por que surpreendeu?"
4. "Algum entrevistado **discordou**? Por quê? O que isso te disse?"
5. "Existe concorrente ou solução adjacente que já resolve isso? Como?"

**Sinais vermelhos:**

- 🚨 0 evidências quantitativas.
- 🚨 Todas as entrevistas com pessoas do mesmo perfil/empresa.
- 🚨 Nenhuma anti-evidência registrada — quem só ouve confirmação está enviesado.

### Seção 4 — Não-objetivos

**Pergunta-âncora:** "O que este produto **não** vai resolver?"

Follow-ups:

1. "Há um problema adjacente tentador que você está deliberadamente deixando de fora? Por quê?"
2. "Que pedido de stakeholder você vai precisar **negar** durante o build?"
3. "Que persona/segmento você está **explicitamente** descartando para v1?"

**Sinais vermelhos:**

- 🚨 Não-objetivos vagos ("não é uma solução completa de X") — vire-os concretos.
- 🚨 Lista vazia ou com 1 item. → quase sempre significa que o escopo ainda não foi pensado.

### Seção 5 — Métrica de sucesso

**Pergunta-âncora:** "Qual métrica diz que isto funcionou?"

Follow-ups:

1. "Qual é o **baseline** dessa métrica hoje? (Mesmo que estimado.)"
2. "Qual é a **meta** em quanto tempo? (3, 6, 12 meses.)"
3. "Como você vai **instrumentar** essa medição? Existe a fonte de dados?"
4. "Quais métricas de **guarda-corpo** não podem piorar? (ex: latência, custo, erro.)"
5. "Se a métrica primária subir mas uma de guarda-corpo cair, o que vence?"

**Sinais vermelhos:**

- 🚨 Métrica sem baseline. → não dá para saber se subiu.
- 🚨 Meta sem prazo. → vira aspiração eterna.
- 🚨 Instrumento "a definir". → impossível medir; bloqueia GA.
- 🚨 Métrica é uma vaidade ("mais usuários") sem ligação com problema.

### Seção 6 — Restrições

**Pergunta-âncora:** "Que restrições reais existem?"

Follow-ups (cada uma exige número, não adjetivo):

1. "Orçamento — `R$X` ou `Y horas-pessoa`?"
2. "Prazo — qual data ou qual sprint?"
3. "Compliance — LGPD, ISO, ABNT específicas?"
4. "Tecnologia — algo obrigatório (sistema legado) ou proibido (vendor banned)?"
5. "Equipe — quantos perfis e quais?"

**Sinais vermelhos:**

- 🚨 "A definir" em mais de uma linha.
- 🚨 Adjetivos no lugar de números ("apertado", "rápido", "barato").

### Seção 7 — Stakeholders

**Pergunta-âncora:** "Quem aprova o quê?"

Follow-ups:

1. "Sponsor toma decisão de go/no-go financeira — quem é, e tem autoridade real?"
2. "PO/Product define escopo — é a mesma pessoa?"
3. "Eng lead define arquitetura — é a mesma pessoa?"
4. "Há usuário-piloto disponível para validar?"

**Sinais vermelhos:**

- 🚨 Mesma pessoa em ≥ 2 papéis críticos. → flag explícito; pode ser ok em time pequeno, mas o agente deve confirmar.
- 🚨 Sponsor sem autoridade real ("preciso pedir para o meu chefe").

### Seção 8 — Riscos

**Pergunta-âncora:** "O que pode dar errado?"

Follow-ups:

1. "Qual é o risco que mata o projeto se acontecer?"
2. "Qual é o risco mais provável (mesmo que pequeno)?"
3. "Para cada um: qual é a mitigação concreta — não 'monitorar', mas **fazer o quê**?"

**Sinais vermelhos:**

- 🚨 Lista < 3 itens.
- 🚨 Mitigações abstratas ("comunicação", "atenção", "monitoramento").

---

## Padrões de challenge (regras invioláveis)

O agente aplica estas regras automaticamente, sem precisar do humano lembrar:

| Padrão | Regra |
|--------|-------|
| **1 stakeholder = 1 papel real** | Se a mesma pessoa aparece em ≥ 2 papéis, sinalizar 🟡 e confirmar com o humano. |
| **Toda métrica precisa de baseline** | Sem baseline, não há como saber se a meta foi atingida. Recusar deixar a seção como "a definir". |
| **Toda restrição precisa de número** | Adjetivos viram TODO; números viram tabela. |
| **Toda hipótese precisa de critério de invalidação** | "O que faria você desistir?" — se não há resposta, hipótese é palpite. |
| **≥ 1 anti-evidência testável** | Confirmação só confirma viés. Se não há nada que poderia invalidar, há viés de seleção. |
| **Não-objetivos ≥ 2** | Lista de 1 item ou vazia indica que escopo ainda não foi pensado. |
| **Mitigação concreta, não abstrata** | "Monitorar" não é mitigação. "Rodar carga sintética antes do GA" é. |

---

## Critério de "pronto para PRD"

A fase Discovery só está pronta para gate quando **todos** os critérios abaixo passam:

- [ ] **≥ 3 evidências** registradas, sendo **≥ 1 quantitativa**.
- [ ] **≥ 1 anti-evidência** testável.
- [ ] **≥ 1 não-objetivo** concreto (não vago).
- [ ] **Métrica primária** com `baseline` + `meta` + `prazo` + `instrumento de medição`.
- [ ] **Métricas de guarda-corpo** ≥ 1 listadas.
- [ ] **Hipótese** com critério de invalidação explícito.
- [ ] **Restrições** sem "a definir" — todas com número ou marcadas como "não aplicável".
- [ ] **Stakeholders** com 1 pessoa por papel (ou flag explícito de acumulação).
- [ ] **Riscos** ≥ 3, com mitigação concreta cada.
- [ ] **Decisão final** registrada (Go / Pivot / No-go).

Se algum critério falha, o agente **registra a lacuna** e **não sinaliza pronto** — mesmo que o humano peça para avançar. O brief volta para entrevista.

---

## Output esperado ao final da entrevista

Ao terminar, o agente produz um **Artifact** contendo:

1. O brief preenchido (template `00-discovery-brief.md`).
2. **As 3 perguntas críticas que ainda não têm resposta**, com sugestão de como obtê-las (entrevista, dado, experimento).
3. Um **veredicto explícito** sobre cada item da checklist "pronto para PRD" — verde/amarelo/vermelho.
4. Recomendação: avançar para PRD, voltar para entrevista, ou pivotar a hipótese.

> O agente **não decide** o gate. O sponsor decide. Mas o agente entrega o material com qualidade suficiente para que a decisão seja honesta.
