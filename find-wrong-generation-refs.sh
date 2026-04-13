#!/usr/bin/env bash
#---
# metadata_version: 1.0
# purpose: "Buscar y reportar todas las referencias incorrectas a '02-SKILLS/GENERATION-MODELS.md'"
# usage: ./find-wrong-generation-refs.sh [--replace] [--dry-run]
# ---
set -euo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly WRONG_PATTERN="01-GENERATION-MODELS\.md"
readonly CORRECT_PATH="02-SKILLS/GENERATION-MODELS.md"
readonly CORRECT_WIKILINK="[[GENERATION-MODELS.md]]"

# Colores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Flags
DRY_RUN=false
DO_REPLACE=false

# ────────────────────────────────────────────────────────────────────────────
# PARSER DE ARGUMENTOS
# ────────────────────────────────────────────────────────────────────────────
parse_args() {
  for arg in "$@"; do
    case "$arg" in
      --replace) DO_REPLACE=true ;;
      --dry-run) DRY_RUN=true ;;
      --help|-h)
        echo "Uso: $0 [--replace] [--dry-run]"
        echo ""
        echo "Busca referencias incorrectas a '02-SKILLS/GENERATION-MODELS.md' y reporta o corrige."
        echo ""
        echo "Opciones:"
        echo "  --replace   Reemplaza automáticamente 02-SKILLS/GENERATION-MODELS.md → GENERATION-MODELS.md"
        echo "  --dry-run   Muestra qué se cambiaría sin modificar archivos"
        echo "  --help, -h  Muestra esta ayuda"
        exit 0
        ;;
    esac
  done
}

# ────────────────────────────────────────────────────────────────────────────
# BUSCAR REFERENCIAS INCORRECTAS
# ────────────────────────────────────────────────────────────────────────────
search_wrong_refs() {
  echo -e "${YELLOW}🔍 Buscando referencias incorrectas a '02-SKILLS/GENERATION-MODELS.md'...${NC}"
  echo ""
  
  local found=0
  
  # Buscar en archivos .md, .sh, .py, .yml, .json (excluyendo .git y node_modules)
  while IFS=: read -r file line_num content; do
    [[ -z "$file" ]] && continue
    ((found++)) || true
    
    echo -e "${RED}❌ Encontrado:${NC} $file:$line_num"
    echo "   $content"
    echo ""
    
  done < <(grep -rn --exclude-dir={.git,node_modules,venv,__pycache__} \
    -E "$WRONG_PATTERN" \
    --include="*.md" --include="*.sh" --include="*.py" --include="*.yml" --include="*.yaml" --include="*.json" \
    "$REPO_ROOT" 2>/dev/null || true)
  
  if [[ "$found" -eq 0 ]]; then
    echo -e "${GREEN}✅ No se encontraron referencias incorrectas.${NC}"
  else
    echo -e "${YELLOW}📊 Total de coincidencias: $found${NC}"
  fi
  
  return $found
}

# ────────────────────────────────────────────────────────────────────────────
# REEMPLAZAR REFERENCIAS (OPCIONAL)
# ────────────────────────────────────────────────────────────────────────────
replace_refs() {
  echo -e "${YELLOW}🔧 Reemplazando '02-SKILLS/GENERATION-MODELS.md' → 'GENERATION-MODELS.md'...${NC}"
  
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}⚠️  Modo DRY-RUN: No se modificarán archivos${NC}"
    echo ""
  fi
  
  local replaced=0
  
  # Reemplazar en wikilinks: [[02-SKILLS/GENERATION-MODELS.md]] → [[GENERATION-MODELS.md]]
  # Y también en rutas relativas: 02-SKILLS/GENERATION-MODELS.md → 02-SKILLS/GENERATION-MODELS.md
  while IFS= read -r -d '' file; do
    # Contar coincidencias antes
    local count
    count=$(grep -c "01-GENERATION-MODELS\.md" "$file" 2>/dev/null || echo 0)
    
    if [[ "$count" -gt 0 ]]; then
      ((replaced += count)) || true
      
      if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}📝 [DRY-RUN] $file: $count reemplazos pendientes${NC}"
      else
        # Reemplazo seguro con sed
        sed -i -E 's|01-GENERATION-MODELS\.md|GENERATION-MODELS.md|g' "$file"
        echo -e "${GREEN}✅ $file: $count reemplazos aplicados${NC}"
      fi
    fi
  done < <(find "$REPO_ROOT" -type f \( -name "*.md" -o -name "*.sh" -o -name "*.py" -o -name "*.yml" -o -name "*.yaml" -o -name "*.json" \) \
    -not -path "*/.git/*" -not -path "*/node_modules/*" -print0 2>/dev/null)
  
  echo ""
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}📊 Total de reemplazos pendientes: $replaced${NC}"
    echo -e "${YELLOW}💡 Ejecuta sin --dry-run para aplicar los cambios${NC}"
  else
    echo -e "${GREEN}✅ Total de reemplazos aplicados: $replaced${NC}"
  fi
}

# ────────────────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────────────────
main() {
  parse_args "$@"
  
  echo "🔎 Validador de referencias a GENERATION-MODELS.md"
  echo "=================================================="
  echo "Repo: $REPO_ROOT"
  echo "Patrón incorrecto: $WRONG_PATTERN"
  echo "Corrección: $CORRECT_PATH"
  echo ""
  
  # Paso 1: Buscar y reportar
  search_wrong_refs
  local search_result=$?
  
  echo ""
  
  # Paso 2: Ofrecer reemplazo si se encontró algo y se pidió --replace
  if [[ "$search_result" -gt 0 && "$DO_REPLACE" == "true" ]]; then
    replace_refs
  elif [[ "$search_result" -gt 0 ]]; then
    echo -e "${YELLOW}💡 Para corregir automáticamente, ejecuta:${NC}"
    echo "   $0 --replace"
    echo ""
    echo -e "${YELLOW}💡 Para ver qué cambiaría sin modificar, ejecuta:${NC}"
    echo "   $0 --replace --dry-run"
  fi
  
  # Código de salida: 0 si no hay errores, >0 si hay referencias incorrectas
  exit $search_result
}

main "$@"
