#!/usr/bin/env bash
# validate.sh — checa convenções e gates do harness.
# Sai 0 se tudo OK, 1 se há falhas.
#
# O que checa:
#  1. docs/ existe
#  2. docs/spec/adr/ existe (mesmo que vazio)
#  3. docs/prd/01-glossary.md existe (após bootstrap)
#  4. nenhuma story na raiz de docs/sprints/
#  5. cada subpasta de docs/sprints/<N>/ tem sprint-plan.md
#  6. para cada fase em memory/, _summary.md existe e tem conteúdo
#  7. frontmatter de stories tem campos obrigatórios
#  8. depends_on / conflicts_with referenciam stories existentes
#  9. stories sensíveis (auth/billing/PII) têm adr_refs
# 10. ADRs em docs/spec/adr/ seguem padrão NNNN-slug.md
# 11. TDD: arquivos em src/domain/** ou src/application/** têm teste
#     correspondente em tests/unit/ (warning, não fail — só se o projeto
#     adotou o layout Clean Arch).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

ROOT="$(repo_root)" || exit 1
cd "$ROOT"

FAILS=0
fail_check() { fail "$@"; FAILS=$((FAILS + 1)); }

# 1. docs/
if [[ ! -d docs ]]; then
  fail_check "docs/ não existe — projeto não foi feito bootstrap"
  echo
  echo "Total de falhas: $FAILS"
  exit 1
fi
ok "docs/ existe"

# 2. ADR folder
if [[ ! -d docs/spec/adr ]]; then
  fail_check "docs/spec/adr/ ausente — obrigatório (adicione .gitkeep)"
else
  ok "docs/spec/adr/ existe"
fi

# 3. Glossary
if [[ ! -f docs/prd/01-glossary.md ]]; then
  warn "docs/prd/01-glossary.md ausente — bootstrap mínimo exige."
else
  ok "docs/prd/01-glossary.md existe"
fi

# 4. Stories na raiz de sprints/
ROOT_STORIES=$(find docs/sprints -maxdepth 1 -name '*.md' 2>/dev/null || true)
if [[ -n "$ROOT_STORIES" ]]; then
  fail_check "Stories encontradas na raiz de docs/sprints/ (devem estar em <N>/):"
  while IFS= read -r f; do echo "        $f"; done <<<"$ROOT_STORIES"
else
  ok "nenhuma story na raiz de docs/sprints/"
fi

# 5. Sprint plan por sprint folder
while IFS= read -r sprint_dir; do
  [[ -z "$sprint_dir" ]] && continue
  if [[ ! -f "$sprint_dir/sprint-plan.md" ]]; then
    fail_check "sprint-plan.md ausente em $sprint_dir"
  else
    ok "sprint-plan.md presente em $sprint_dir"
  fi
done < <(find docs/sprints -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

# 6. Phase summaries
for phase in discovery prd design spec sprints execution testing deploys; do
  if [[ -d "docs/memory/$phase" ]]; then
    if ! phase_summary_exists "$phase"; then
      warn "docs/memory/$phase/ existe mas _summary.md vazio/ausente"
    else
      ok "docs/memory/$phase/_summary.md OK"
    fi
  fi
done

# 6b. Sprint summaries (in docs/memory/sprints/** or docs/sprints/<N>/_summary.md)
# require the "## Smoke Run" section — correctness-convergence gate.
SPRINT_SUMMARIES=$(find docs/memory/sprints docs/sprints -type f -name '_summary.md' 2>/dev/null || true)
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  if ! grep -qE '^##[[:space:]]+Smoke Run\b' "$f"; then
    fail_check "$f sem seção '## Smoke Run' (gate de convergência da Sprint)"
  else
    ok "$f tem '## Smoke Run'"
  fi
done <<<"$SPRINT_SUMMARIES"

# 7+8+9. Frontmatter de stories
ALL_IDS=()
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  id=$(frontmatter_get "$f" id)
  if [[ -z "$id" ]]; then
    fail_check "$f sem campo 'id' no frontmatter"
    continue
  fi
  ALL_IDS+=("$id")
  for required in name type status created sprint; do
    if ! grep -q "^${required}:" "$f"; then
      fail_check "$f sem campo obrigatório '$required'"
    fi
  done
done < <(story_files)

if [[ ${#ALL_IDS[@]} -gt 0 ]]; then
  ok "frontmatter base validado para ${#ALL_IDS[@]} story(s)"
fi

# Dependency integrity
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  deps=$(awk '/^depends_on:/{flag=1;next}/^[a-z_]+:/{flag=0}flag' "$f" \
         | grep -oE '"[^"]+"|[a-z0-9-]+' | tr -d '"' || true)
  for d in $deps; do
    [[ "$d" == "[]" || -z "$d" ]] && continue
    found=0
    for id in "${ALL_IDS[@]}"; do
      [[ "$id" == "$d" ]] && { found=1; break; }
    done
    if [[ $found -eq 0 ]]; then
      fail_check "$f: depends_on referencia '$d' que não existe"
    fi
  done
done < <(story_files)

# Sensitive domain → adr_refs
SENSITIVE_PATTERN='auth|RBAC|rbac|billing|PII|pii|whitelist|password|token'
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  type=$(frontmatter_get "$f" type)
  [[ "$type" != "story" && "$type" != "tech-task" ]] && continue
  if grep -qE "$SENSITIVE_PATTERN" "$f"; then
    adr_refs=$(frontmatter_get "$f" adr_refs)
    if [[ -z "$adr_refs" || "$adr_refs" == "[]" ]]; then
      fail_check "$f toca domínio sensível mas adr_refs está vazio"
    fi
  fi
done < <(story_files)

# 9b. Tech Spec heading uniqueness (precondition for spec-fetch.sh).
if [[ -f docs/spec/00-tech-spec.md ]]; then
  DUPES=$(grep -E '^#{1,6}[[:space:]]+' docs/spec/00-tech-spec.md \
    | sed -E 's/^#+[[:space:]]+//; s/[[:space:]]+$//' \
    | sort | uniq -d)
  if [[ -n "$DUPES" ]]; then
    fail_check "headings duplicados em docs/spec/00-tech-spec.md (quebra spec-fetch.sh):"
    while IFS= read -r h; do echo "        $h"; done <<<"$DUPES"
  else
    ok "headings únicos em docs/spec/00-tech-spec.md"
  fi
fi

# 10. ADR naming
if [[ -d docs/spec/adr ]]; then
  while IFS= read -r adr; do
    [[ -z "$adr" ]] && continue
    base=$(basename "$adr" .md)
    if ! [[ "$base" =~ ^[0-9]{4}- ]]; then
      fail_check "ADR $adr fora do padrão NNNN-slug.md"
    fi
  done < <(find docs/spec/adr -maxdepth 1 -name '*.md' 2>/dev/null)
fi

# 11. TDD: arquivos em src/domain/** ou src/application/** devem ter teste
# correspondente em tests/unit/<mesmo-caminho-relativo>/. Apenas warn — não fail.
# Só roda se o projeto adotou o layout Clean Arch (src/domain ou src/application).
if [[ -d src/domain || -d src/application ]]; then
  TDD_GAPS=0
  while IFS= read -r src_file; do
    [[ -z "$src_file" ]] && continue
    # Ignora index.ts puro de re-export
    if [[ "$(basename "$src_file")" == "index.ts" ]] \
       && ! grep -qE '^(export (function|class|const)|class |function )' "$src_file"; then
      continue
    fi
    rel="${src_file#src/}"                # ex: domain/inspections/inspection.ts
    base="${rel%.ts}"                     # ex: domain/inspections/inspection
    test_candidates=(
      "tests/unit/${base}.test.ts"
      "tests/unit/${base}.spec.ts"
    )
    found=0
    for t in "${test_candidates[@]}"; do
      [[ -f "$t" ]] && { found=1; break; }
    done
    if [[ $found -eq 0 ]]; then
      warn "TDD gap: $src_file sem teste em tests/unit/${base}.{test,spec}.ts"
      TDD_GAPS=$((TDD_GAPS + 1))
    fi
  done < <(find src/domain src/application -type f -name '*.ts' \
           ! -name '*.test.ts' ! -name '*.spec.ts' 2>/dev/null)
  if [[ $TDD_GAPS -eq 0 ]]; then
    ok "TDD: todo arquivo de domain/application tem teste correspondente"
  fi
fi

echo
if [[ $FAILS -eq 0 ]]; then
  ok "validate: tudo verde"
  exit 0
else
  fail "validate: $FAILS falha(s) encontrada(s)"
  exit 1
fi
