
### 2. Archivo: `05-CONFIGURATIONS/validation/orchestrator-engine.sh`
#**Ubicación:** `05-CONFIGURATIONS/validation/orchestrator-engine.sh`
#```bash
#!/bin/bash
# ---
# title: Orchestrator Engine
# description: Motor centralizado de gobernanza y certificación de artefactos
# tier: 3
# ---

set -euo pipefail

# Constantes y Rutas
BASE_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
VALIDATORS_DIR="${BASE_DIR}/05-CONFIGURATIONS/validation"
REPORT_FILE="${BASE_DIR}/skill-validation-report.json"

# Colores para salida interactiva
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Estado global de validación
PASSED_CHECKS=()
BLOCKING_ISSUES=()
RECOMMENDED_ACTION=""
TIER_CERTIFIED=1

# Función de Log/Output
log() { echo -e "${BLUE}[ORCHESTRATOR]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; BLOCKING_ISSUES+=("$1"); }
pass() { echo -e "${GREEN}[PASS]${NC} $1"; PASSED_CHECKS+=("$1"); }

# Parseo de argumentos
HEADLESS=false
FILE_PATH=""
FILE_TYPE=""
TARGET_FOLDER=""
FUNCTION_HINT=""

usage() {
    echo "Uso: $0 [opciones]"
    echo "Opciones:"
    echo "  --headless        Ejecución sin interacción humana (IA/CI)"
    echo "  --file <path>     Ruta del archivo a validar"
    echo "  --type <ext>      Extensión del archivo (ej. .sh, .md)"
    echo "  --folder <ruta>   Carpeta destino (ej. 05-CONFIGURATIONS)"
    echo "  --function <desc> Función principal del archivo"
    exit 1
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --headless) HEADLESS=true ;;
        --file) FILE_PATH="$2"; shift ;;
        --type) FILE_TYPE="$2"; shift ;;
        --folder) TARGET_FOLDER="$2"; shift ;;
        --function) FUNCTION_HINT="$2"; shift ;;
        *) usage ;;
    esac
    shift
done

# Interfaz Interactiva Humana
if [[ "$HEADLESS" == false ]]; then
    echo -e "${BLUE}==============================================${NC}"
    echo -e "${BLUE}  MANTIS GOVERNANCE ORCHESTRATOR - INTERACTIVE${NC}"
    echo -e "${BLUE}==============================================${NC}"
    if [[ -z "$FILE_PATH" ]]; then
        read -p "Ruta del archivo a validar: " FILE_PATH
    fi
    if [[ ! -f "$FILE_PATH" ]]; then
        error "Archivo no encontrado: $FILE_PATH"
        echo -e "\n${RED}Ejecución abortada por errores críticos.${NC}"
        exit 1
    fi
    if [[ -z "$FILE_TYPE" ]]; then
        FILE_TYPE=".${FILE_PATH##*.}"
        echo "Tipo detectado: $FILE_TYPE"
    fi
    if [[ -z "$TARGET_FOLDER" ]]; then
        read -p "¿En qué carpeta principal vive? (ej. 02-SKILLS): " TARGET_FOLDER
    fi
    if [[ -z "$FUNCTION_HINT" ]]; then
        read -p "¿Cuál es su función principal?: " FUNCTION_HINT
    fi
    echo ""
fi

# Validaciones base de archivo
if [[ ! -f "$FILE_PATH" ]]; then
    error "El archivo $FILE_PATH no existe."
    TIER_CERTIFIED=0
fi

# ---------------------------------------------------------
# CAPA 1 & 2: FILTRO NORMATIVO Y EJECUCIÓN DE EXTERNOS
# ---------------------------------------------------------
log "Iniciando análisis Capa 1 y 2 para $FILE_PATH ($FILE_TYPE) en $TARGET_FOLDER"

# 1. Chequeo de Secretos (Siempre aplica C3)
if [[ -x "${VALIDATORS_DIR}/audit-secrets.sh" ]]; then
    log "Ejecutando audit-secrets.sh (Norma C3)..."
    if bash "${VALIDATORS_DIR}/audit-secrets.sh" "$FILE_PATH" >/dev/null 2>&1; then
        pass "C3 - Cero Hardcode / Secretos protegidos."
    else
        error "C3 CRÍTICO: Posible fuga de secretos o hardcode detectado."
        TIER_CERTIFIED=0
    fi
fi

# 2. Chequeo Frontmatter
if [[ "$FILE_TYPE" == ".md" || "$FILE_TYPE" == ".sh" || "$FILE_TYPE" == ".yml" ]]; then
    if [[ -x "${VALIDATORS_DIR}/validate-frontmatter.sh" ]]; then
        log "Ejecutando validate-frontmatter.sh..."
        if bash "${VALIDATORS_DIR}/validate-frontmatter.sh" "$FILE_PATH" >/dev/null 2>&1; then
             pass "Frontmatter canónico válido."
        else
             warn "Frontmatter inválido o ausente."
        fi
    fi
fi

# 3. RLS y Multi-tenant (Norma C4) - Específico por ruta
if [[ "$TARGET_FOLDER" == *"02-SKILLS/BASE DE DATOS-RAG"* || "$TARGET_FOLDER" == *"04-WORKFLOWS"* || "$FILE_TYPE" == ".sql" ]]; then
    if [[ -x "${VALIDATORS_DIR}/check-rls.sh" ]]; then
         log "Ejecutando check-rls.sh (Norma C4 Multi-tenant)..."
         if bash "${VALIDATORS_DIR}/check-rls.sh" "$FILE_PATH" >/dev/null 2>&1; then
             pass "C4 - tenant_id detectado y válido."
         else
             error "C4 CRÍTICO: Falla aislamiento multi-tenant (falta tenant_id o RLS)."
             TIER_CERTIFIED=0
         fi
    fi
fi

# 4. Validaciones Específicas por Tipo
case "$FILE_TYPE" in
    .sh)
        log "Validando sintaxis Bash..."
        if shellcheck "$FILE_PATH" >/dev/null 2>&1; then
            pass "Sintaxis Bash y Shellcheck OK."
        else
            warn "Shellcheck reporta advertencias. Revisa idempotencia (C7)."
        fi
        ;;
    .json)
        log "Validando estructura JSON..."
        if jq empty "$FILE_PATH" >/dev/null 2>&1; then
            pass "Sintaxis JSON válida."
        else
            error "JSON inválido."
            TIER_CERTIFIED=0
        fi
        ;;
esac

# ---------------------------------------------------------
# CAPA 3: CERTIFICACIÓN POR NIVELES (TIER CALCULATION)
# ---------------------------------------------------------
log "Evaluando Tier objetivo..."

# Lógica de cálculo basada en la Matriz Canónica
if [[ ${#BLOCKING_ISSUES[@]} -gt 0 ]]; then
    TIER_CERTIFIED=0
    RECOMMENDED_ACTION="Corregir errores bloqueantes (C3/C4/Sintaxis) y re-ejecutar."
else
    # Si pasa los bloqueos base, al menos es Tier 1
    TIER_CERTIFIED=1
    RECOMMENDED_ACTION="Requiere aprobación humana en PR."

    # Subida a Tier 2/3 basada en carpeta destino
    if [[ "$TARGET_FOLDER" == *"05-CONFIGURATIONS"* || "$TARGET_FOLDER" == *"04-WORKFLOWS"* ]]; then
        TIER_CERTIFIED=3
        RECOMMENDED_ACTION="Apto para Auto-Deploy. Ejecutar packager-assisted.sh."
    elif [[ "$TARGET_FOLDER" == *"03-AGENTS"* || "$TARGET_FOLDER" == *"01-RULES"* ]]; then
        TIER_CERTIFIED=2
        RECOMMENDED_ACTION="Apto para Merge automático tras CI."
    fi
fi

# ---------------------------------------------------------
# CAPA 4: RESULTADO Y REPORTE JSON
# ---------------------------------------------------------

# Generar checksum
FILE_SHA256=$(sha256sum "$FILE_PATH" | awk '{print $1}')

# Generar JSON de salida para IA/CI
cat <<EOF > "$REPORT_FILE"
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "file": "$FILE_PATH",
  "tier_certified": $TIER_CERTIFIED,
  "passed_checks": $(printf '%s\n' "${PASSED_CHECKS[@]}" | jq -R . | jq -s .),
  "blocking_issues": $(printf '%s\n' "${BLOCKING_ISSUES[@]}" | jq -R . | jq -s .),
  "recommended_action": "$RECOMMENDED_ACTION",
  "sha256": "$FILE_SHA256"
}
EOF

# Output final para Humano o CI Log
if [[ "$HEADLESS" == false ]]; then
    echo -e "\n${BLUE}=== RESULTADO DE CERTIFICACIÓN ===${NC}"
    if [[ $TIER_CERTIFIED -eq 0 ]]; then
        echo -e "${RED}❌ RECHAZADO (TIER 0)${NC}"
        for issue in "${BLOCKING_ISSUES[@]}"; do echo -e "  - $issue"; done
    else
        if [[ $TIER_CERTIFIED -eq 3 ]]; then
            echo -e "${GREEN}✅ CERTIFICADO: NIVEL 3 (AUTO-DEPLOY)${NC}"
        elif [[ $TIER_CERTIFIED -eq 2 ]]; then
            echo -e "${GREEN}✅ CERTIFICADO: NIVEL 2 (MERGE AUTOMÁTICO)${NC}"
        else
            echo -e "${YELLOW}✅ CERTIFICADO: NIVEL 1 (REQUIERE REVISIÓN)${NC}"
        fi
    fi
    echo -e "${BLUE}📋 Acción Recomendada:${NC} $RECOMMENDED_ACTION"
    echo -e "${BLUE}💾 Reporte guardado en:${NC} $REPORT_FILE"
    echo -e "${BLUE}==================================${NC}\n"
fi

# Salida de error estricta para CI/CD si no certifica al menos a Tier 1
if [[ $TIER_CERTIFIED -eq 0 ]]; then
    exit 1
fi
exit 0
