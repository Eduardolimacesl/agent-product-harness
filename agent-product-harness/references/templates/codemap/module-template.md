---
module: <nome-do-modulo>
last_touched_story: <story-id>
last_touched_at: <YYYY-MM-DD>
status: active
---

# Module: <nome-do-modulo>

## Core Purpose
<Uma frase. Responsabilidade primária. Não copiar README.>

## Public Interface

### Functions / Hooks / Server Actions
- `<assinatura completa>` — <propósito em 1 linha>

### Classes / Components
- `<Nome>` — <propósito>; props/métodos públicos: <lista>

### Constants / Types exportados
- `<NOME>` — <uso>

## Dependencies

### Imports (afferent — o que ESTE módulo usa)
- `<path interno>` — usa: <símbolos>
- `npm:<pacote>` — uso: <para que>

### Consumed by (efferent — quem usa ESTE módulo)
- `<path>` (story `<id>`) — consome: <símbolos>

## Notes
<Apenas invariante não óbvia. ≤3 linhas.>
