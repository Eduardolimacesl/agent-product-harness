# Change Contract — Mudanças no próprio harness

> Toda mutação no harness — referência, template, script, regra — é tratada
> como mudança em runtime safety-critical. Não construímos Evolution Agent
> autônomo (visão v1.0+); adotamos o contrato como template de PR no repo
> do harness (Ning et al. 2026, §5.2.3).

## 1. Princípio

O harness está em produção: ele *roda* nas sessões dos agentes que ele
mesmo guia. Uma mudança no harness é deploy de runtime, não edição de
documentação. Precisa de:

- diagnóstico do modo de falha que ataca (de preferência mensurável via
  telemetria — H1-003),
- previsão clara de melhoria,
- invariantes a preservar,
- modo de falsificação (como saber que a mudança piorou),
- plano de rollback.

Esses são os 6 campos do Change Contract.

## 2. Quando é obrigatório

| Severidade | Exemplos | Contrato obrigatório? |
|---|---|---|
| `patch` | typo, clarificação, link quebrado, exemplo melhor | não |
| `minor` | nova referência, novo template, novo script, regra opcional | **sim** |
| `major` | regra obrigatória nova, breaking change em template, remoção de fase | **sim** |

Em dúvida: classifique como `minor` e preencha. Custo de preencher 6 campos
é baixo; custo de mutação não-rastreada é alto.

## 3. Os 6 campos

### 3.1 Componente modificado
Qual referência/template/script/regra muda. Caminho relativo a partir da
raiz do repo. Se múltiplos, liste em bullets.

### 3.2 Modo de falha que ataca
O problema recorrente que justifica a mudança. **Evidência preferida:**
recorte de `telemetry-report.sh` mostrando o sintoma (p.ex. "taxa de
plan-rejection em `auth-*` = 47% nos últimos 30 dias"). Em ausência de
telemetria, um caso concreto de friction observado em produto real.

### 3.3 Melhoria prevista
O que esperamos que melhore — concreto, idealmente mensurável. Ex.: "taxa
de plan-rejection em `auth-*` cai para <20%", "spec-fetch.sh resolve
heading em ≤50ms", "validate.sh deixa de produzir falso-positivo em
projetos sem `src/domain/`".

### 3.4 Invariantes que devem ser preservadas
O que **não pode quebrar** depois da mudança. Lista típica:

- Bootstrap mínimo continua bootando.
- Gates de CI (`validate.sh`, `check-spec-drift.sh`) continuam falhando
  pelos mesmos motivos.
- Numeração de princípios em `00-architecture-and-flow.md` §2 segue contígua.
- Hard rules de sandbox seguem aplicadas.
- Telemetria emite os 7 tipos de evento canônicos.

Cite as que **sua** mudança poderia afetar; não copie a lista inteira.

### 3.5 Como falsificar
Qual teste, dry-run ou uso real provaria que a mudança piorou em vez de
melhorar. Sem isso, a mudança é fé. Ex.: "rodar `validate.sh` em produto
bootstrapado v0.1; saída tem que continuar OK", "telemetria de 2 sprints
mostra plan-rejection caindo".

### 3.6 Rollback
Como reverter. Inclui impacto em produtos já bootstrapados — alguns
artefatos foram copiados (não linkados), então `git revert` no harness
não basta. Liste o passo extra se necessário.

## 4. Onde o contrato vive

Template de PR em
[`.github/PULL_REQUEST_TEMPLATE/harness-change.md`](../../../.github/PULL_REQUEST_TEMPLATE/harness-change.md)
— GitHub seleciona automaticamente quando o PR contém mudanças relevantes;
para forçar use `?template=harness-change.md` na URL do PR.

## 5. Visão futura (não-escopo de v0.3)

Ning et al. 2026 §3.5.2 prescreve um **Evolution Agent** autônomo que
detecta sintomas na telemetria, propõe mudanças, escreve o contrato. Isso
fica para depois — só faz sentido depois de a telemetria (H1-003) acumular
≥2 sprints de dados reais. Em v0.3, o contrato é preenchido por humano.

## 6. Auto-aplicação

Este próprio plano (v0.2→v0.3, story H2-002) é um exercício do contrato:
o componente é `.github/PULL_REQUEST_TEMPLATE/`; o modo de falha é
"mudanças no harness chegavam como PRs informais sem rastreabilidade do
porquê"; a melhoria prevista é "toda mudança `minor`/`major` carrega
diagnóstico explícito".
