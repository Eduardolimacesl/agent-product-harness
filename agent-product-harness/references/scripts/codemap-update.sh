#!/usr/bin/env bash
# codemap-update.sh <story-id> — detect modules modified by a story.
#
# This script does NOT invoke an LLM. It detects changed files via git
# diff, filters them against the allowlist in
# docs/memory/codemap/README.md (or built-in defaults), and prints for
# each matched module:
#
#   - whether a codemap entry already exists (UPDATE) or not (CREATE)
#   - the suggested target path under docs/memory/codemap/modules/
#   - the template path the agent should use
#
# The story agent then fills the entries within the same session — this
# preserves the minimum-bootstrap discipline (no new agent session).
#
# Usage:
#   codemap-update.sh <story-id> [--base <ref>]
#
# --base defaults to the upstream tracking ref or "main".
#
# Exit codes:
#   0  ran cleanly (may print zero matches — that's fine if the story
#      didn't touch public modules)
#   1  not in a git repo / docs/ missing
#   2  bad usage

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

STORY=""
BASE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) BASE="$2"; shift 2 ;;
    -h|--help) sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) [[ -z "$STORY" ]] && STORY="$1" && shift || { echo "ERRO: arg extra: $1" >&2; exit 2; } ;;
  esac
done

if [[ -z "$STORY" ]]; then
  fail "usage: codemap-update.sh <story-id> [--base <ref>]"
  exit 2
fi

ROOT="$(repo_root)" || exit 1
cd "$ROOT"

if [[ ! -d .git ]] && ! git rev-parse --git-dir >/dev/null 2>&1; then
  fail "não é um repo git — codemap-update precisa de git diff"
  exit 1
fi

if [[ -z "$BASE" ]]; then
  BASE=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null \
         || echo "main")
fi

# Built-in defaults (override by editing docs/memory/codemap/README.md
# allowlist in v0.3+ when this script parses it).
DEFAULT_INCLUDES=(
  'src/domain/'
  'src/application/'
  'src/contracts/'
  'app/(app)/'
  'lib/'
)
DEFAULT_EXCLUDES=(
  '.test.ts'
  '.spec.ts'
  '__fixtures__'
  '.d.ts'
)

CHANGED=$(git diff --name-only "$BASE"...HEAD 2>/dev/null || git diff --name-only "$BASE" 2>/dev/null)
if [[ -z "$CHANGED" ]]; then
  # Fall back to staged + unstaged
  CHANGED=$(git diff --name-only HEAD 2>/dev/null)
fi

if [[ -z "$CHANGED" ]]; then
  info "nenhum arquivo modificado detectado contra $BASE"
  exit 0
fi

MATCHED=()
while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  hit=0
  for inc in "${DEFAULT_INCLUDES[@]}"; do
    [[ "$path" == "$inc"* ]] && hit=1 && break
  done
  [[ $hit -eq 0 ]] && continue
  for exc in "${DEFAULT_EXCLUDES[@]}"; do
    if [[ "$path" == *"$exc"* ]]; then
      hit=0
      break
    fi
  done
  [[ $hit -eq 1 ]] && MATCHED+=("$path")
done <<<"$CHANGED"

if [[ ${#MATCHED[@]} -eq 0 ]]; then
  ok "story $STORY: nenhum arquivo público alterado — nada a atualizar"
  exit 0
fi

# Find the skill repo's templates dir to reference. We assume the script
# is invoked from the product repo via the skill symlink; reflect the path
# back so the agent can copy from it.
TEMPLATE_PATH="$SCRIPT_DIR/../templates/codemap/module-template.md"
TEMPLATE_REL=$(realpath --relative-to="$ROOT" "$TEMPLATE_PATH" 2>/dev/null || echo "$TEMPLATE_PATH")

echo "Story: $STORY"
echo "Base:  $BASE"
echo "Arquivos públicos alterados: ${#MATCHED[@]}"
echo
echo "Entradas de codemap a (re)gerar:"
echo

for path in "${MATCHED[@]}"; do
  # Module slug: drop extension, replace / with - and ( ) with empty.
  slug=$(echo "$path" \
    | sed -E 's@^src/@@; s@^app/@@; s@^lib/@@' \
    | sed -E 's@\.(ts|tsx|js|jsx)$@@' \
    | tr '/' '-' | tr -d '()')
  target="docs/memory/codemap/modules/${slug}.md"
  if [[ -f "$target" ]]; then
    action="UPDATE"
  else
    action="CREATE"
  fi
  printf "  [%s]  %s\n          source : %s\n          target : %s\n          template: %s\n\n" \
    "$action" "$slug" "$path" "$target" "$TEMPLATE_REL"
done

info "preencher as entradas acima dentro da mesma sessão; depois rodar codemap-graph.sh"
