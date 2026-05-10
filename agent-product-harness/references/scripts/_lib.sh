#!/usr/bin/env bash
# _lib.sh — helpers comuns. Sourced por outros scripts.
#
# Uso:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/_lib.sh"

set -euo pipefail

# now :: ISO 8601 UTC
now() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# repo_root :: encontra o diretório que contém docs/
repo_root() {
  local d="$PWD"
  while [[ "$d" != "/" ]]; do
    if [[ -d "$d/docs" ]]; then
      echo "$d"
      return 0
    fi
    d="$(dirname "$d")"
  done
  echo "" >&2
  echo "ERRO: nenhum diretório docs/ encontrado a partir de $PWD" >&2
  return 1
}

# frontmatter_get <file> <key> :: imprime valor do campo (string nua)
frontmatter_get() {
  local file="$1"
  local key="$2"
  awk -v k="$key" '
    BEGIN { infm=0 }
    /^---$/ { infm = !infm; next }
    infm && $1 == k":" { sub(/^[^:]+: */, ""); print; exit }
  ' "$file"
}

# frontmatter_set <file> <key> <value> :: substitui in-place
frontmatter_set() {
  local file="$1"
  local key="$2"
  local value="$3"
  if grep -q "^${key}:" "$file"; then
    sed -i.bak "/^${key}:/c\\
${key}: ${value}" "$file"
    rm -f "$file.bak"
  else
    echo "AVISO: campo '$key' não existe em $file — não inserido" >&2
    return 1
  fi
}

# strip_frontmatter <file> :: imprime corpo sem frontmatter YAML
strip_frontmatter() {
  local file="$1"
  sed '1,/^---$/d; 1,/^---$/d' "$file"
}

# story_files <sprint-N?> :: lista todos os arquivos de story de uma sprint
# (tudo em docs/sprints/<N>/ exceto sprint-plan.md e *-analysis.md)
story_files() {
  local sprint="${1:-}"
  local root
  root="$(repo_root)" || return 1
  if [[ -n "$sprint" ]]; then
    find "$root/docs/sprints/$sprint" -maxdepth 1 -name '*.md' \
      ! -name 'sprint-plan.md' ! -name '*-analysis.md' 2>/dev/null | sort
  else
    find "$root/docs/sprints" -mindepth 2 -maxdepth 2 -name '*.md' \
      ! -name 'sprint-plan.md' ! -name '*-analysis.md' 2>/dev/null | sort
  fi
}

# phase_summary_exists <phase> :: 0 se _summary.md existe e tem conteúdo
phase_summary_exists() {
  local phase="$1"
  local root
  root="$(repo_root)" || return 1
  local f="$root/docs/memory/$phase/_summary.md"
  [[ -s "$f" ]]
}

# color helpers (no-op se não TTY)
if [[ -t 1 ]]; then
  C_RED="\033[0;31m"; C_GREEN="\033[0;32m"; C_YEL="\033[0;33m"
  C_BLUE="\033[0;34m"; C_DIM="\033[2m"; C_OFF="\033[0m"
else
  C_RED=""; C_GREEN=""; C_YEL=""; C_BLUE=""; C_DIM=""; C_OFF=""
fi

ok()   { printf "${C_GREEN}OK${C_OFF}    %s\n" "$*"; }
fail() { printf "${C_RED}FAIL${C_OFF}  %s\n" "$*"; }
warn() { printf "${C_YEL}WARN${C_OFF}  %s\n" "$*"; }
info() { printf "${C_BLUE}INFO${C_OFF}  %s\n" "$*"; }
