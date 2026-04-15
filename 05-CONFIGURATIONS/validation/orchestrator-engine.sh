#!/bin/bash
# ==============================================================================
# ORCHESTRADOR CENTRALIZADO DE GOBERNANZA SDD
# ==============================================================================
# MOTOR DE CERTIFICACIÓN AUTOMATIZADA PARA GENERACIÓN AGÉNTICA
# ==============================================================================
#
# DESCRIPCIÓN:
#   Este script es el sistema nervioso central que traduce las normas C1-C8,
#   los requisitos multi-tenant, las políticas de no-regresión y los estándares
#   de hardening en decisiones binarias, certificadas y ejecutables.
#
# ARQUITECTURA:
#   - CAPA 1: Identidad y Contexto (¿Qué es? ¿Dónde vive? ¿Para qué sirve?)
#   - CAPA 2: Filtro Normativo C1-C8 (Reglas base obligatorias)
#   - CAPA 3: Certificación por Niveles (TIER 1/2/3)
#   - CAPA 4: Enrutamiento y Acción (Validadores + CI/CD)
#
# USO:
#   ./orchestrator-engine.sh --mode <interactive|headless> --file <path> [opciones]
#
#   Modo Interactivo (Humano):
#     ./orchestrator-engine.sh --mode interactive
#
#   Modo Headless (IA/CI):
#     ./orchestrator-engine.sh --mode headless --file 02-SKILLS/AI/gpt-integration.md --json
#
# URLs de Validadores Coordinados:
#   audit-secrets.sh       → https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/audit-secrets.sh
#   check-rls.sh           → https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/check-rls.sh
#   check-wikilinks.sh     → https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/check-wikilinks.sh
#   schema-validator.py     → https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schema-validator.py
#   validate-frontmatter.sh → https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/validate-frontmatter.sh
#   validate-skill-integrity.sh → https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/validate-skill-integrity.sh
#   verify-constraints.sh  → https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/verify-constraints.sh
#
# CÓDIGOS DE RETORNO:
#   0 = SUCCESS          → Validación exitosa, artefacto certificado
#   1 = VALIDATION_FAILED → Fallas detectadas, requiere corrección
#   2 = CRITICAL_BLOCK   → C3 o C4 violado, bloqueo crítico
#   3 = IDENTITY_MISSING → No se pudo identificar el archivo
#   4 = VALIDATOR_ERROR  → Error interno de validador
#   5 = TIMEOUT          → Ejecución excedió tiempo límite
#
# VERSIÓN: 1.1.0
# FECHA: 2026-04-14
# AUTOR: MiniMax Agent (Senior Auditor) + Matrix Integration
#
# ==============================================================================

# ------------------------------------------------------------------------------
# SECCIÓN 1: CONFIGURACIÓN Y VARIABLES GLOBALES
# ------------------------------------------------------------------------------
# Esta sección define las constantes y configuraciones que el motor usa
# durante toda su ejecución. Los ingenieros juniors deben modificar solo
# estas variables si necesitan ajustar comportamiento global.

set -euo pipefail
# set -e:  Sale del script si un comando falla
# set -u:  Sale si hay variables indefinidas
# set -o pipefail: Captura errores en pipes

# --- RUTAS Y DIRECTORIOS ---
# Directorio base del orquestador (se calcula dinámicamente)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALIDATOR_BASE_PATH="${SCRIPT_DIR}"
REPORT_DIR="${SCRIPT_DIR}/reports"
LOG_DIR="${SCRIPT_DIR}/logs"

# --- VERSIÓN Y METADATOS ---
ORCHESTRATOR_VERSION="1.1.0"
ORCHESTRATOR_BUILD="2026-04-14T11:49:33Z"

# --- CONFIGURACIÓN DE TIERS ---
# Umbrales mínimos para cada tier
TIER1_MIN_SCORE=20
TIER2_MIN_SCORE=50
TIER3_MIN_SCORE=80

# --- CONFIGURACIÓN DE VALIDACIÓN ---
MIN_EXAMPLES_TIER1=5
MIN_EXAMPLES_TIER2=10
MIN_EXAMPLES_TIER3=10
MAX_PLACEHOLDERS_ALLOWED=0

# --- COLORES PARA OUTPUT (MODO INTERACTIVO) ---
# Engineers juniors: Estos códigos ANSI hacen el output más legible
# Los colores se desactivan si NO_COLOR está definido
if [[ -z "${NO_COLOR:-}" ]]; then
    COLOR_RESET='\033[0m'
    COLOR_RED='\033[0;31m'
    COLOR_GREEN='\033[0;32m'
    COLOR_YELLOW='\033[0;33m'
    COLOR_BLUE='\033[0;34m'
    COLOR_MAGENTA='\033[0;35m'
    COLOR_CYAN='\033[0;36m'
    COLOR_BOLD='\033[1m'
else
    COLOR_RESET=''
    COLOR_RED=''
    COLOR_GREEN=''
    COLOR_YELLOW=''
    COLOR_BLUE=''
    COLOR_MAGENTA=''
    COLOR_CYAN=''
    COLOR_BOLD=''
fi

# --- CONFIGURACIÓN DE REDIRECCIÓN DE LOGS ---
# Todos los logs van a stderr para no contaminar stdout (importante para JSON)
log_debug() { echo -e "${COLOR_CYAN}[DEBUG]${COLOR_RESET} $*" >&2; }
log_info()  { echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*" >&2; }
log_warn()  { echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*" >&2; }
log_error() { echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2; }
log_success() { echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $*" >&2; }

# --- VARIABLES DE ESTADO (NO MODIFICAR DIRECTAMENTE) ---
# Estas variables se llenan durante la ejecución
declare -g TARGET_FILE=""
declare -g TARGET_FOLDER=""
declare -g TARGET_FUNCTION=""
declare -g EXPECTED_TIER=0
declare -g MODE="interactive"
declare -g OUTPUT_JSON=false
declare -g STRICT_MODE=false
declare -g CI_MODE="${CI_MODE:-false}"

# Arrays para almacenar resultados de validaciones
declare -a VALIDATORS_INVOKED=()
declare -a CHECKS_PASSED=()
declare -a CHECKS_FAILED=()
declare -a CHECKS_WARNED=()

# Variables de resultado
declare -g FINAL_TIER=0
declare -g FINAL_SCORE=0
declare -g SHA256_CHECKSUM=""
declare -g EXIT_CODE=0
declare -g BLOCKING_MESSAGE=""

# ------------------------------------------------------------------------------
# SECCIÓN 2: FUNCIONES DE UTILIDAD
# ------------------------------------------------------------------------------
# Funciones auxiliares que facilitan la lógica principal.
# Engineers juniors: lean esta sección para entender helpers reutilizables.

# ------------------------------------------------------------------------------
# print_banner(): Muestra el banner de inicio del orquestador
# ------------------------------------------------------------------------------
print_banner() {
    cat << 'EOF'

    ╔═══════════════════════════════════════════════════════════════╗
    ║                                                               ║
    ║     ████████╗██╗  ██╗███████╗    ███████╗ ██████╗ ██████╗     ║
    ║     ╚══██╔══╝██║  ██║██╔════╝    ██╔════╝██╔═══██╗██╔══██╗    ║
    ║        ██║   ███████║█████╗      █████╗  ██║   ██║██████╔╝    ║
    ║        ██║   ██╔══██║██╔══╝      ██╔══╝  ██║   ██║██╔══██╗    ║
    ║        ██║   ██║  ██║███████╗    ██║     ╚██████╔╝██║  ██║    ║
    ║        ╚═╝   ╚═╝  ╚═╝╚══════╝    ╚═╝      ╚═════╝ ╚═╝  ╚═╝    ║
    ║                                                               ║
    ║            ORQUESTADOR CENTRALIZADO DE GOBERNANZA SDD         ║
    ║                    Sistema de Certificación                   ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝

EOF
    echo -e "  ${COLOR_BOLD}Versión:${COLOR_RESET} ${ORCHESTRATOR_VERSION}"
    echo -e "  ${COLOR_BOLD}Fecha:${COLOR_RESET} ${ORCHESTRATOR_BUILD}"
    echo ""
}

# ------------------------------------------------------------------------------
# usage(): Muestra la ayuda de uso del script
# ------------------------------------------------------------------------------
usage() {
    cat << 'EOF'
USO:
    ./orchestrator-engine.sh --mode <interactive|headless> [opciones]

MODOS:
    interactive    Modo guiado para humanos (preguntas paso a paso)
    headless       Modo silencioso para IAs y CI/CD

OPCIONES:
    -f, --file <path>        Archivo a validar (requerido en headless)
    -d, --dir <path>         Directorio destino (para contexto)
    -t, --tier <1|2|3>      Tier objetivo esperado
    --function <type>       Función del archivo (documentation, pattern, etc.)
    --json                  Output en formato JSON (headless mode)
    --strict                Trata warnings como errores bloqueantes
    -h, --help              Muestra esta ayuda
    --version               Muestra versión

EJEMPLOS:
    # Modo interactivo
    ./orchestrator-engine.sh --mode interactive

    # Modo headless con JSON
    ./orchestrator-engine.sh --mode headless --file 02-SKILLS/AI/gpt-integration.md --json

    # Modo headless strict
    ./orchestrator-engine.sh --mode headless --file 05-CONFIGURATIONS/docker-compose/vps1-n8n.yml --json --strict

VALIDADORES COORDINADOS:
    audit-secrets.sh        → Detector C3 (Zero Hardcode)
    check-rls.sh           → Verificador C4 (Multi-tenancy)
    check-wikilinks.sh      → Validador de referencias
    schema-validator.py      → Validador JSON Schema
    validate-frontmatter.sh → Verificador de metadatos
    verify-constraints.sh   → Check C1-C6 textual
    validate-skill-integrity.sh → Verificador de integridad

EOF
}

# ------------------------------------------------------------------------------
# check_dependencies(): Verifica que las dependencias necesarias estén disponibles
# ------------------------------------------------------------------------------
# ¿Por qué existe esta función?
# Los validadores externos dependen de herramientas del sistema (grep, sed, jq, etc.)
# Si falta alguna dependencia, el orquestador debe fallar tempranamente con un
# mensaje claro, no silenciosamente.

check_dependencies() {
    local missing_deps=()
    local required_tools=("grep" "sed" "find" "sha256sum" "cat")

    # Agregar herramientas opcionales solo si se van a usar
    command -v shellcheck >/dev/null 2>&1 && required_tools+=("shellcheck") || log_warn "shellcheck no encontrado (opcional)"
    command -v yamllint >/dev/null 2>&1 && required_tools+=("yamllint") || log_warn "yamllint no encontrado (opcional)"
    command -v jq >/dev/null 2>&1 && required_tools+=("jq") || log_warn "jq no encontrado (opcional)"

    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            # Solo fallar por herramientas realmente requeridas
            if [[ " grep sed find sha256sum cat " == *" $tool "* ]]; then
                missing_deps+=("$tool")
            fi
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Dependencias faltantes: ${missing_deps[*]}"
        log_error "Instale las dependencias faltantes antes de continuar."
        return 1
    fi

    log_debug "Todas las dependencias verificadas ✓"
}

# ------------------------------------------------------------------------------
# calculate_sha256(): Calcula el checksum SHA256 de un archivo
# ------------------------------------------------------------------------------
# ¿Por qué existe esta función?
# El SHA256 es obligatorio para TIER_3 (Auto-Deploy). Permite verificar
# integridad del artefacto y detectar modificaciones no autorizadas.

calculate_sha256() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        log_error "Archivo no encontrado para checksum: $file"
        return 1
    fi

    # Usar sha256sum (estándar) o shasum (macOS compatible)
    if command -v sha256sum >/dev/null 2>&1; then
        SHA256_CHECKSUM=$(sha256sum "$file" | awk '{print $1}')
    elif command -v shasum >/dev/null 2>&1; then
        SHA256_CHECKSUM=$(shasum -a 256 "$file" | awk '{print $1}')
    else
        log_warn "No se pudo calcular SHA256 (herramienta no disponible)"
        SHA256_CHECKSUM="unavailable"
    fi

    log_debug "SHA256: ${SHA256_CHECKSUM}"
}

# ------------------------------------------------------------------------------
# SECCIÓN 2.5: CARGA DE MATRIZ DE NORMAS CANÓNICAS
# ------------------------------------------------------------------------------
# Esta sección carga y parsea norms-matrix.json para validación contextual.
# Sin esta matriz, el orquestador aplica reglas genéricas (falsos positivos).

# --- RUTA DE LA MATRIZ (precedencia) ---
if [[ -n "${NORMS_MATRIX_PATH:-}" ]]; then
  NORMS_MATRIX_FILE="${NORMS_MATRIX_PATH}"
elif [[ -f "${VALIDATOR_BASE_PATH}/norms-matrix.json" ]]; then
  NORMS_MATRIX_FILE="${VALIDATOR_BASE_PATH}/norms-matrix.json"
else
  NORMS_MATRIX_FILE="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")/05-CONFIGURATIONS/validation/norms-matrix.json"
fi

# --- FUNCIÓN: load_norms_matrix() ---
load_norms_matrix() {
  log_debug "Cargando matriz desde: $NORMS_MATRIX_FILE"
  [[ ! -f "$NORMS_MATRIX_FILE" ]] && { log_error "Matriz no encontrada"; return 1; }
  jq empty "$NORMS_MATRIX_FILE" >/dev/null || { log_error "JSON inválido"; return 1; }
  
  # Precargar reglas clave en memoria para consultas rápidas
  MASTER_PRECEDENCE=$(jq -r '.master_precedence_rule' "$NORMS_MATRIX_FILE")
  log_debug "✓ Matriz cargada: $(jq -r '.version' "$NORMS_MATRIX_FILE")"
  CHECKS_PASSED+=("norms_matrix_loaded: PASS")
}

# --- FUNCIÓN: query_norms_profile() ---
# Consulta: ruta_alta + extensión + función → perfil de normas aplicables
query_norms_profile() {
  local ruta="$1" ext="$2" func="$3"
  jq -r --arg p "$ruta" --arg e ".$ext" --arg f "$func" '
    .matrix_by_location | to_entries | 
    map(select(.key as $k | $p | startswith($k))) | 
    sort_by(.key|length) | last | .value.extensions[$e] // .value.extensions["*"] // null
  ' "$NORMS_MATRIX_FILE"
}

# --- FUNCIÓN: get_constraint_intensity() ---
# Retorna: "mandatory" | "applicable" | "contextual" | "not_applicable"
get_constraint_intensity() {
  local profile="$1" constraint="$2"
  echo "$profile" | jq -r ".constraints.${constraint}.intensity // \"not_applicable\""
}

# --- FUNCIÓN: get_active_validators() ---
# Retorna lista de validadores a ejecutar para este perfil
get_active_validators() {
  local profile="$1"
  echo "$profile" | jq -r '.active_validators[]?' 2>/dev/null
}

# --- FUNCIÓN: is_blocking() ---
# Determina si un fallo en esta constraint debe bloquear certificación
is_blocking() {
  local profile="$1" constraint="$2"
  local intensity=$(get_constraint_intensity "$profile" "$constraint")
  [[ "$intensity" == "mandatory" ]]
}

# Cargar matriz al inicio (se ejecutará en main)
# NOTA: No llamar aquí; se invoca explícitamente en main() tras check_dependencies

# ------------------------------------------------------------------------------
# SECCIÓN 3: CAPA 1 - IDENTIDAD Y CONTEXTO
# ------------------------------------------------------------------------------
# Esta capa responde: ¿Qué es este archivo? ¿Dónde vive? ¿Para qué sirve?
# Si falla → RECHAZO INMEDIATO (código 3)

# ------------------------------------------------------------------------------
# identify_file_type(): Identifica el tipo de archivo por extensión
# ------------------------------------------------------------------------------
identify_file_type() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        BLOCKING_MESSAGE="Archivo no encontrado: $file"
        return 1
    fi

    # Extraer extensión
    local extension="${file##*.}"
    local extension_lower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

    # Validar extensión reconocida
    case "$extension_lower" in
        sh)
            TARGET_FILE_TYPE="bash"
            ;;
        py)
            TARGET_FILE_TYPE="python"
            ;;
        tf)
            TARGET_FILE_TYPE="terraform"
            ;;
        yaml|yml)
            TARGET_FILE_TYPE="yaml"
            ;;
        md)
            TARGET_FILE_TYPE="markdown"
            ;;
        json)
            TARGET_FILE_TYPE="json"
            ;;
        sql)
            TARGET_FILE_TYPE="sql"
            ;;
        js)
            TARGET_FILE_TYPE="javascript"
            ;;
        *)
            TARGET_FILE_TYPE="unknown"
            BLOCKING_MESSAGE="Tipo de archivo no reconocido: .$extension"
            return 1
            ;;
    esac

    log_debug "Tipo identificado: $TARGET_FILE_TYPE (.$extension)"
    CHECKS_PASSED+=("identity_type: PASS (.${extension} recognized)")
    return 0
}

# ------------------------------------------------------------------------------
# identify_file_location(): Identifica la ubicación en el árbol del proyecto
# ------------------------------------------------------------------------------
# ¿Por qué existe esta función?
# Cada directorio tiene validadores y normas específicas. Por ejemplo:
# - 02-SKILLS/BASE DE DATOS-RAG/ → activa check-rls.sh obligatoriamente
# - 05-CONFIGURATIONS/validation/ → no invoca validadores recursivamente

identify_file_location() {
    local file="$1"
    local absolute_path="$(realpath "$file" 2>/dev/null || echo "$file")"

    # Extraer directorio padre relativo
    local relative_dir
    relative_dir=$(dirname "$file")

    # Determinar categoría del directorio
    case "$relative_dir" in
        00-CONTEXT|00-CONTEXT/*)
            TARGET_FOLDER_CATEGORY="context"
            ;;
        01-RULES|01-RULES/*)
            TARGET_FOLDER_CATEGORY="rules"
            ;;
        02-SKILLS/BASE\ DE\ DATOS-RAG|02-SKILLS/BASE\ DE\ DATOS-RAG/*)
            TARGET_FOLDER_CATEGORY="database-rag"
            ;;
        02-SKILLS/*)
            TARGET_FOLDER_CATEGORY="skills"
            ;;
        03-AGENTS|03-AGENTS/*)
            TARGET_FOLDER_CATEGORY="agents"
            ;;
        04-WORKFLOWS|04-WORKFLOWS/*)
            TARGET_FOLDER_CATEGORY="workflows"
            ;;
        05-CONFIGURATIONS|05-CONFIGURATIONS/*)
            TARGET_FOLDER_CATEGORY="configurations"
            ;;
        05-CONFIGURATIONS/validation)
            TARGET_FOLDER_CATEGORY="validation-scripts"
            ;;
        06-PROGRAMMING|06-PROGRAMMING/*)
            TARGET_FOLDER_CATEGORY="programming"
            ;;
        07-PROCEDURES|07-PROCEDURES/*)
            TARGET_FOLDER_CATEGORY="procedures"
            ;;
        08-LOGS|08-LOGS/*)
            TARGET_FOLDER_CATEGORY="logs"
            ;;
        *)
            TARGET_FOLDER_CATEGORY="unknown"
            BLOCKING_MESSAGE="Ubicación no reconocida en PROJECT_TREE: $relative_dir"
            return 1
            ;;
    esac

    TARGET_FOLDER="$relative_dir"
    log_debug "Ubicación: $TARGET_FOLDER (categoría: $TARGET_FOLDER_CATEGORY)"
    CHECKS_PASSED+=("identity_location: PASS ($TARGET_FOLDER valid)")
    return 0
}

# ------------------------------------------------------------------------------
# identify_file_function(): Clasifica la función del archivo
# ------------------------------------------------------------------------------
# Esta función infiere la función basándose en el contexto (ubicación + nombre)

identify_file_function() {
    local file="$1"

    if [[ -n "$TARGET_FUNCTION" ]]; then
        # Ya proporcionado por el usuario
        log_debug "Función proporcionada: $TARGET_FUNCTION"
        return 0
    fi

    # Inferir función desde el contexto
    case "$TARGET_FOLDER_CATEGORY" in
        context)
            TARGET_FUNCTION="documentation"
            ;;
        rules)
            TARGET_FUNCTION="norm"
            ;;
        skills|database-rag)
            TARGET_FUNCTION="skill"
            ;;
        agents)
            TARGET_FUNCTION="agent-definition"
            ;;
        workflows)
            TARGET_FUNCTION="pipeline"
            ;;
        configurations)
            if [[ "$TARGET_FILE_TYPE" == "bash" ]]; then
                TARGET_FUNCTION="script"
            else
                TARGET_FUNCTION="configuration"
            fi
            ;;
        validation-scripts)
            TARGET_FUNCTION="validator"
            ;;
        programming)
            TARGET_FUNCTION="code-pattern"
            ;;
        procedures)
            TARGET_FUNCTION="runbook"
            ;;
        *)
            TARGET_FUNCTION="unknown"
            ;;
    esac

    log_debug "Función inferida: $TARGET_FUNCTION"
    return 0
}

# ------------------------------------------------------------------------------
# verify_frontmatter(): Verifica presencia de metadatos canónicos
# ------------------------------------------------------------------------------
# Los metadatos canónicos son OBLIGATORIOS para que el orquestador pueda
# enrutar y auditar. Sin ellos, el archivo es rechazable inmediatamente.

verify_frontmatter() {
    local file="$1"

    case "$TARGET_FILE_TYPE" in
        markdown|yaml|terraform)
            # Verificar frontmatter YAML
            if grep -q "^---$" "$file" 2>/dev/null; then
                log_debug "Frontmatter YAML encontrado ✓"
                CHECKS_PASSED+=("frontmatter_present: PASS")

                # Verificar campos requeridos
                local has_canonical_path=false
                local has_ai_optimized=false

                # Extraer sección frontmatter
                local fm_content
                fm_content=$(awk '/^---$/,/^---$/{if(NR>1) print}' "$file" 2>/dev/null || echo "")

                echo "$fm_content" | grep -q "canonical_path:" && has_canonical_path=true
                echo "$fm_content" | grep -q "ai_optimized:" && has_ai_optimized=true

                if [[ "$has_canonical_path" == "true" ]]; then
                    CHECKS_PASSED+=("frontmatter_canonical_path: PASS")
                else
                    CHECKS_WARNED+=("frontmatter_canonical_path: WARN (ausente)")
                fi

                if [[ "$has_ai_optimized" == "true" ]]; then
                    CHECKS_PASSED+=("frontmatter_ai_optimized: PASS")
                else
                    CHECKS_WARNED+=("frontmatter_ai_optimized: WARN (ausente)")
                fi

                return 0
            else
                CHECKS_WARNED+=("frontmatter_present: WARN (ausente)")
                return 0
            fi
            ;;
        bash)
            # Verificar comentarios de frontmatter (# --- ...)
            if grep -qE "^# ?---+" "$file" 2>/dev/null; then
                log_debug "Header bash encontrado ✓"
                CHECKS_PASSED+=("frontmatter_present: PASS")
                return 0
            else
                CHECKS_WARNED+=("frontmatter_present: WARN (ausente)")
                return 0
            fi
            ;;
        json)
            # JSON no usa frontmatter pero debe tener estructura válida
            if jq empty "$file" 2>/dev/null; then
                CHECKS_PASSED+=("json_valid: PASS")
                return 0
            else
                CHECKS_FAILED+=("json_valid: FAIL (sintaxis inválida)")
                return 1
            fi
            ;;
        *)
            CHECKS_PASSED+=("frontmatter_optional: PASS (tipo $TARGET_FILE_TYPE)")
            return 0
            ;;
    esac
}

# ------------------------------------------------------------------------------
# run_capa1_identity(): Ejecuta toda la Capa 1
# ------------------------------------------------------------------------------
run_capa1_identity() {
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "CAPA 1: IDENTIDAD Y CONTEXTO"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local file="$TARGET_FILE"

    # Paso 1: Identificar tipo
    if ! identify_file_type "$file"; then
        log_error "❌ FALLO EN IDENTIFICACIÓN DE TIPO"
        CHECKS_FAILED+=("identity_type: FAIL ($BLOCKING_MESSAGE)")
        return 1
    fi

    # Paso 2: Identificar ubicación
    if ! identify_file_location "$file"; then
        log_error "❌ FALLO EN IDENTIFICACIÓN DE UBICACIÓN"
        CHECKS_FAILED+=("identity_location: FAIL ($BLOCKING_MESSAGE)")
        return 1
    fi

    # Paso 3: Identificar función
    identify_file_function "$file"

    # Paso 4: Verificar frontmatter
    verify_frontmatter "$file" || {
        log_error "❌ FALLO EN VERIFICACIÓN DE FRONTMATTER"
        return 1
    }

    log_success "✅ CAPA 1 COMPLETADA - Identidad verificada"
    return 0
}

# ------------------------------------------------------------------------------
# SECCIÓN 4: CAPA 2 - FILTRO NORMATIVO C1-C8 (CON MATRIZ DINÁMICA)
# ------------------------------------------------------------------------------
# Esta capa aplica las reglas base. C3 y C4 son BLOQUEO CRÍTICO.
# Los demás son ADVERTENCIAS según el tier objetivo.
# MODIFICADO: Usa norms-matrix.json para validación contextual por ruta/extensión/función

# ------------------------------------------------------------------------------
# run_validator(): Ejecuta un validador externo y captura resultado
# ------------------------------------------------------------------------------
# ¿Por qué existe esta función?
# Centraliza la lógica de invocación de validadores externos. Permite:
# - Registrar qué validadores se invocaron
# - Capturar errores sin detener la ejecución
# - Generar logs estructurados

run_validator() {
    local validator_name="$1"
    local validator_path="${VALIDATOR_BASE_PATH}/${validator_name}"
    local target="$2"
    local shift_extra="${3:-}"

    # Verificar que el validador existe
    if [[ ! -x "$validator_path" ]]; then
        # Intentar con bash
        if [[ ! -f "$validator_path" ]]; then
            log_warn "Validador no encontrado: $validator_path (omitido)"
            return 0
        fi
    fi

    VALIDATORS_INVOKED+=("$validator_name")
    log_debug "Invocando: $validator_name --file $target"

    # Ejecutar validador y capturar resultado
    local result
    local exit_code=0

    if [[ "$validator_name" == *.py ]]; then
        result=$(python3 "$validator_path" --file "$target" 2>&1) || exit_code=$?
    else
        result=$("$validator_path" --file "$target" $shift_extra 2>&1) || exit_code=$?
    fi

    if [[ ${exit_code:-0} -eq 0 ]]; then
        log_debug "✓ $validator_name: PASS"
        return 0
    else
        log_warn "⚠ $validator_name: FAIL (exit $exit_code)"
        log_debug "Detalle: $result"
        CHECKS_FAILED+=("${validator_name}: FAIL")
        return 1
    fi
}

# ------------------------------------------------------------------------------
# check_constraint_c3(): Detector de hardcoded secrets (C3)
# ------------------------------------------------------------------------------
# C3 es BLOQUEO CRÍTICO. Si encuentra hardcoded secrets, el orquestador
# debe detenerse inmediatamente con código 2.

check_constraint_c3() {
    log_debug "Verificando C3: Zero Hardcode"

    local file="$TARGET_FILE"
    local hardcoded_patterns=(
        'password\s*=\s*["'"'"'][^${][^"'"'"']*["'"'"']'
        'api_key\s*=\s*["'"'"'][^${][^"'"'"']*["'"'"']'
        'secret\s*=\s*["'"'"'][^${][^"'"'"']*["'"'"']'
        'token\s*=\s*["'"'"'][^${][^"'"'"']*["'"'"']'
    )

    for pattern in "${hardcoded_patterns[@]}"; do
        local match
        match=$(grep -En "$pattern" "$file" 2>/dev/null || true)

        if [[ -n "$match" ]]; then
            log_error "🚫 BLOQUEO CRÍTICO C3: Hardcoded detectado"
            log_error "   Ubicación: $match"
            log_error "   Patrón: $pattern"
            BLOCKING_MESSAGE="C3_FAIL: Hardcoded detected"
            CHECKS_FAILED+=("c3_zero_hardcode: FAIL (hardcoded found)")
            return 1
        fi
    done

    # Verificar uso correcto de variables
    if grep -qE '\${[A-Z_]+:\?missing\}' "$file" 2>/dev/null; then
        CHECKS_PASSED+=("c3_zero_hardcode: PASS (using \${VAR:?})")
    fi

    # Verificar sensitive = true en terraform
    if [[ "$TARGET_FILE_TYPE" == "terraform" ]]; then
        if grep -qE 'sensitive\s*=\s*true' "$file" 2>/dev/null; then
            CHECKS_PASSED+=("c3_terraform_sensitive: PASS")
        fi
    fi

    return 0
}

# ------------------------------------------------------------------------------
# check_constraint_c4(): Verificador de tenant_id (C4)
# ------------------------------------------------------------------------------
# C4 es BLOQUEO CRÍTICO para archivos que tocan base de datos o configs multi-tenant.

check_constraint_c4() {
    log_debug "Verificando C4: Multi-tenancy (tenant_id)"

    local file="$TARGET_FILE"

    # C4 es OBLIGATORIO solo para ciertos contextos
    case "$TARGET_FOLDER_CATEGORY" in
        database-rag|configurations|agents)
            # Buscar tenant_id en el archivo
            if grep -qE 'tenant_id' "$file" 2>/dev/null; then
                local tenant_count
                tenant_count=$(grep -cE 'tenant_id' "$file" || echo "0")
                CHECKS_PASSED+=("c4_tenant_id: PASS (encontrado $tenant_count veces)")

                # Verificaciones específicas según tipo
                if [[ "$TARGET_FILE_TYPE" == "sql" ]]; then
                    # En SQL, tenant_id debe estar en WHERE o índices
                    if grep -qE 'WHERE.*tenant_id|WHERE.*\.tenant_id' "$file" 2>/dev/null; then
                        CHECKS_PASSED+=("c4_sql_where_tenant: PASS")
                    else
                        log_warn "⚠ C4 SQL: tenant_id encontrado pero no en WHERE"
                        CHECKS_WARNED+=("c4_sql_where_tenant: WARN (tenant_id no en filtro)")
                    fi
                fi
                return 0
            else
                log_error "🚫 BLOQUEO CRÍTICO C4: tenant_id no encontrado"
                BLOCKING_MESSAGE="C4_FAIL: tenant_id missing"
                CHECKS_FAILED+=("c4_tenant_id: FAIL (missing)")
                return 1
            fi
            ;;
        *)
            # Para otros contextos, C4 es informativo
            if grep -qE 'tenant_id' "$file" 2>/dev/null; then
                CHECKS_PASSED+=("c4_tenant_id: PASS (informativo)")
            fi
            return 0
            ;;
    esac
}

# ------------------------------------------------------------------------------
# check_constraint_c5(): Verificador de comandos de validación declarados
# ------------------------------------------------------------------------------
check_constraint_c5() {
    log_debug "Verificando C5: Comando de validación"

    local file="$TARGET_FILE"

    # Buscar validation_command en frontmatter o comentarios
    if grep -qE 'validation_command:|VALIDATION:' "$file" 2>/dev/null; then
        CHECKS_PASSED+=("c5_validation_command: PASS")
        return 0
    fi

    # Para scripts, verificar que tienen sintaxis válida
    if [[ "$TARGET_FILE_TYPE" == "bash" ]]; then
        if bash -n "$file" 2>/dev/null; then
            CHECKS_PASSED+=("c5_syntax_valid: PASS")
            return 0
        fi
    fi

    # Para JSON, verificar con jq
    if [[ "$TARGET_FILE_TYPE" == "json" ]]; then
        if jq empty "$file" 2>/dev/null; then
            CHECKS_PASSED+=("c5_json_valid: PASS")
            return 0
        fi
    fi

    CHECKS_WARNED+=("c5_validation_command: WARN (no declarado explícitamente)")
    return 0
}

# ------------------------------------------------------------------------------
# check_constraint_c6(): Verificador de cloud-only inference
# ------------------------------------------------------------------------------
# Prohíbe localhost:11434 u otros endpoints locales en configs de producción

check_constraint_c6() {
    log_debug "Verificando C6: Cloud-only inference"

    local file="$TARGET_FILE"

    # Patrones prohibidos en producción
    local prohibited_patterns=(
        'localhost:11434'
        '127\.0\.0\.1:11434'
        'ollama.*localhost'
    )

    for pattern in "${prohibited_patterns[@]}"; do
        if grep -qE "$pattern" "$file" 2>/dev/null; then
            log_error "🚫 BLOQUEO C6: Endpoint local detectado en producción"
            BLOCKING_MESSAGE="C6_FAIL: Localhost inference found"
            CHECKS_FAILED+=("c6_cloud_only: FAIL (localhost detected)")
            return 1
        fi
    done

    CHECKS_PASSED+=("c6_cloud_only: PASS (no localhost)")
    return 0
}

# ------------------------------------------------------------------------------
# check_constraint_c7(): Verificador de resiliencia (timeouts, retries)
# ------------------------------------------------------------------------------
check_constraint_c7() {
    log_debug "Verificando C7: Resiliencia"

    local file="$TARGET_FILE"

    # Patrones de resiliencia
    local resilience_patterns=(
        'timeout'
        'retry'
        'retries'
        'healthcheck'
        'health_check'
        'circuit.breaker'
    )

    local found_resilience=false
    for pattern in "${resilience_patterns[@]}"; do
        if grep -qiE "$pattern" "$file" 2>/dev/null; then
            found_resilience=true
            break
        fi
    done

    if [[ "$found_resilience" == "true" ]]; then
        CHECKS_PASSED+=("c7_resilience: PASS (patrones encontrados)")
    else
        CHECKS_WARNED+=("c7_resilience: WARN (sin patrones de resiliencia)")
    fi

    return 0
}

# ------------------------------------------------------------------------------
# check_constraint_c8(): Verificador de observabilidad
# ------------------------------------------------------------------------------
check_constraint_c8() {
    log_debug "Verificando C8: Observabilidad"

    local file="$TARGET_FILE"

    # Patrones de observabilidad
    local observability_patterns=(
        'trace_id'
        'traceId'
        '"level":'
        'logger'
        'logging'
        'otel'
        'openTelemetry'
    )

    local found_observability=false
    for pattern in "${observability_patterns[@]}"; do
        if grep -qE "$pattern" "$file" 2>/dev/null; then
            found_observability=true
            break
        fi
    done

    if [[ "$found_observability" == "true" ]]; then
        CHECKS_PASSED+=("c8_observability: PASS (patrones encontrados)")
    else
        CHECKS_WARNED+=("c8_observability: WARN (sin patrones de observabilidad)")
    fi

    return 0
}

# ------------------------------------------------------------------------------
# run_capa2_normative(): Ejecuta toda la Capa 2 (VERSIÓN CON MATRIZ DINÁMICA)
# ------------------------------------------------------------------------------
# MODIFICADO: Consulta norms-matrix.json para aplicar validación contextual
# en lugar de checks fijos. Elimina falsos positivos por carpeta/tipo.

run_capa2_normative() {
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "CAPA 2: FILTRO NORMATIVO C1-C8 (Matriz Dinámica)"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local file="$TARGET_FILE"
    local capa2_failed=false

    # ── CONSULTA DE PERFIL DESDE MATRIZ (NUEVO - Reemplaza checks fijos) ──
    log_debug "Consultando perfil de normas para: $TARGET_FOLDER_CATEGORY / $TARGET_FILE_TYPE / $TARGET_FUNCTION"
    
    local norms_profile
    norms_profile=$(query_norms_profile "$TARGET_FOLDER_CATEGORY" "$TARGET_FILE_TYPE" "$TARGET_FUNCTION")
    
    if [[ -z "$norms_profile" || "$norms_profile" == "null" ]]; then
        log_warn "No se encontró perfil específico; aplicando perfil genérico"
        norms_profile='{"constraints":{"C1":{"intensity":"contextual"},"C2":{"intensity":"contextual"},"C3":{"intensity":"applicable"},"C4":{"intensity":"contextual"},"C5":{"intensity":"applicable"},"C6":{"intensity":"contextual"},"C7":{"intensity":"contextual"},"C8":{"intensity":"contextual"}},"active_validators":["verify-constraints.sh","audit-secrets.sh"]}'
    fi
    
    # ── ITERAR CONSTRAINTS SEGÚN INTENSIDAD DEL PERFIL ─────────────────────
    for constraint in C1 C2 C3 C4 C5 C6 C7 C8; do
        local intensity=$(get_constraint_intensity "$norms_profile" "$constraint")
        
        case "$intensity" in
            "not_applicable")
                log_debug "⚪ $constraint: No aplicable para este perfil; omitiendo"
                continue
                ;;
            "mandatory")
                log_debug "🔴 $constraint: Obligatorio; ejecutando verificación estricta"
                if ! check_constraint_"${constraint,,}"; then
                    log_error "🚫 BLOQUEO CRÍTICO: $constraint no cumplido"
                    CHECKS_FAILED+=("${constraint}: MANDATORY_FAIL")
                    capa2_failed=true
                else
                    CHECKS_PASSED+=("${constraint}: MANDATORY_PASS")
                fi
                ;;
            "applicable")
                log_debug "🟢 $constraint: Aplicable; ejecutando verificación estándar"
                if ! check_constraint_"${constraint,,}"; then
                    log_warn "⚠️ $constraint: Verificación falló (advertencia para Tier 2-3)"
                    CHECKS_WARNED+=("${constraint}: APPLICABLE_WARN")
                else
                    CHECKS_PASSED+=("${constraint}: APPLICABLE_PASS")
                fi
                ;;
            "contextual")
                log_debug "🟡 $constraint: Contextual; evaluando condición específica"
                # Ejecutar solo si la función o carpeta lo requiere
                if [[ "$TARGET_FUNCTION" == *"db"* || "$TARGET_FOLDER_CATEGORY" == *"database"* || "$TARGET_FOLDER_CATEGORY" == *"infra"* ]]; then
                    if ! check_constraint_"${constraint,,}"; then
                        log_warn "⚠️ $constraint: Verificación contextual falló"
                        CHECKS_WARNED+=("${constraint}: CONTEXTUAL_WARN")
                    else
                        CHECKS_PASSED+=("${constraint}: CONTEXTUAL_PASS")
                    fi
                else
                    log_debug "⚪ $constraint: Condición contextual no activa; omitiendo"
                fi
                ;;
        esac
    done
    
    # ── EJECUTAR VALIDADORES EXTERNOS SEGÚN LISTA ACTIVA DEL PERFIL ────────
    log_debug "Ejecutando validadores externos para este perfil"
    local active_validators=$(get_active_validators "$norms_profile")
    
    if [[ -n "$active_validators" ]]; then
        while IFS= read -r validator; do
            [[ -z "$validator" ]] && continue
            log_debug "→ Ejecutando validador: $validator"
            run_validator "$validator" "$TARGET_FILE"
        done <<< "$active_validators"
    else
        log_debug "⚪ No hay validadores externos activos para este perfil"
    fi
    
    # ── RESUMEN DE CAPA 2 ─────────────────────────────────────────────────
    if [[ "$capa2_failed" == true ]]; then
        log_error "❌ Capa 2: Fallos críticos en filtro normativo"
        return 1
    fi

    log_success "✅ CAPA 2 COMPLETADA - Normativa verificada (matriz dinámica)"
    return 0
}

# ------------------------------------------------------------------------------
# SECCIÓN 5: CAPA 3 - CERTIFICACIÓN POR NIVELES
# ------------------------------------------------------------------------------
# Esta capa calcula el puntaje y asigna el tier basado en madurez funcional.

# ------------------------------------------------------------------------------
# calculate_examples_count(): Cuenta ejemplos en el archivo
# ------------------------------------------------------------------------------
# Los ejemplos son indicadores de calidad:
# - TIER 1: ≥5 ejemplos
# - TIER 2: ≥10 ejemplos
# - TIER 3: ≥10 ejemplos

calculate_examples_count() {
    local file="$TARGET_FILE"
    local example_markers=("✅" "❌" "🔧" "SUCCESS" "FAIL" "ERROR" "OK" "PASS")

    local count=0
    for marker in "${example_markers[@]}"; do
        local found
        found=$(grep -cF "$marker" "$file" 2>/dev/null || echo "0")
        count=$((count + found))
    done

    # Normalizar: cada bloque de ejemplo tiene 2-3 markers
    local examples_estimated=$((count / 2))

    log_debug "Ejemplos estimados: $examples_estimated"

    if [[ $examples_estimated -ge $MIN_EXAMPLES_TIER3 ]]; then
        CHECKS_PASSED+=("examples_count: PASS ($examples_estimated >= $MIN_EXAMPLES_TIER3)")
        return 0
    elif [[ $examples_estimated -ge $MIN_EXAMPLES_TIER1 ]]; then
        CHECKS_WARNED+=("examples_count: WARN ($examples_estimated < $MIN_EXAMPLES_TIER3)")
        return 0
    else
        CHECKS_WARNED+=("examples_count: WARN (solo $examples_estimated ejemplos)")
        return 0
    fi
}

# ------------------------------------------------------------------------------
# check_placeholders(): Verifica ausencia de placeholders residuales
# ------------------------------------------------------------------------------
check_placeholders() {
    local file="$TARGET_FILE"

    local placeholder_patterns=(
        'TODO'
        'FIXME'
        'CAMBIAR'
        'REEMPLAZAR'
        '\${[^}]+\?'
    )

    local found_placeholders=0
    for pattern in "${placeholder_patterns[@]}"; do
        local found
        found=$(grep -cE "$pattern" "$file" 2>/dev/null || echo "0")
        found_placeholders=$((found_placeholders + found))
    done

    if [[ $found_placeholders -gt 0 ]]; then
        log_warn "⚠ Placeholders residuales encontrados: $found_placeholders"
        CHECKS_WARNED+=("placeholders: WARN ($found_placeholders encontrados)")
        return 1
    fi

    CHECKS_PASSED+=("placeholders: PASS (0 residuales)")
    return 0
}

# ------------------------------------------------------------------------------
# check_determinism(): Verifica determinismo del artefacto
# ------------------------------------------------------------------------------
# Un artefacto determinista produce el mismo output con el mismo input

check_determinism() {
    local file="$TARGET_FILE"

    # Patrones que rompen determinismo
    local non_deterministic_patterns=(
        'date\s+'
        'timestamp'
        'random'
        '\$RANDOM'
        'uuidgen'
    )

    for pattern in "${non_deterministic_patterns[@]}"; do
        if grep -qE "$pattern" "$file" 2>/dev/null; then
            log_warn "⚠ Patrón no-deterministico: $pattern"
            CHECKS_WARNED+=("determinism: WARN ($pattern found)")
            return 1
        fi
    done

    CHECKS_PASSED+=("determinism: PASS")
    return 0
}

# ------------------------------------------------------------------------------
# check_healthcheck_tier3(): Verifica elementos de TIER 3
# ------------------------------------------------------------------------------
# TIER 3 requiere: healthcheck, rollback, idempotencia, namespace aislado

check_healthcheck_tier3() {
    local file="$TARGET_FILE"

    # Verificar healthcheck
    if grep -qE 'healthcheck|health_check|health:' "$file" 2>/dev/null; then
        CHECKS_PASSED+=("tier3_healthcheck: PASS")
    fi

    # Verificar restart policy o equivalente
    if grep -qE 'restart:|always|unless-stopped' "$file" 2>/dev/null; then
        CHECKS_PASSED+=("tier3_restart_policy: PASS")
    fi

    # Verificar namespace
    local namespace_patterns=("mantis-vps" "tenant_" "kb_")
    local has_namespace=false
    for pattern in "${namespace_patterns[@]}"; do
        if grep -qE "$pattern" "$file" 2>/dev/null; then
            has_namespace=true
            break
        fi
    done

    if [[ "$has_namespace" == "true" ]]; then
        CHECKS_PASSED+=("tier3_namespace: PASS (prefijo aislado)")
    fi

    # Calcular SHA256 para TIER 3
    calculate_sha256 "$file"
}

# ------------------------------------------------------------------------------
# calculate_tier_score(): Calcula el puntaje total y determina tier
# ------------------------------------------------------------------------------
# Algoritmo:
# - Factores que suman: sintaxis, C1-C8, ejemplos, determinismo, etc.
# - Factores que restan: placeholders, hardcoded, falta de tenant_id
# - Puntaje >= 80 → TIER 3
# - Puntaje >= 50 → TIER 2
# - Puntaje >= 20 → TIER 1
# - Puntaje < 20 → RECHAZADO

calculate_tier_score() {
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "CAPA 3: CERTIFICACIÓN POR NIVELES"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local score=0
    local file="$TARGET_FILE"

    # === FACTORES QUE SUMAN ===

    # Base: sintaxis válida
    case "$TARGET_FILE_TYPE" in
        bash)
            if bash -n "$file" 2>/dev/null; then
                score=$((score + 10))
                log_debug "+10: Sintaxis bash válida"
            fi
            ;;
        json)
            if jq empty "$file" 2>/dev/null; then
                score=$((score + 10))
                log_debug "+10: Sintaxis JSON válida"
            fi
            ;;
        yaml)
            if command -v yamllint >/dev/null 2>&1; then
                if yamllint "$file" 2>/dev/null; then
                    score=$((score + 10))
                    log_debug "+10: Sintaxis YAML válida"
                fi
            else
                score=$((score + 5))
                log_debug "+5: YAML sin yamllint (asumido válido)"
            fi
            ;;
    esac

    # C1-C8 passed
    local c_passed=$(grep -c ": PASS" <<< "$(declare -p CHECKS_PASSED 2>/dev/null)" 2>/dev/null || echo "0")
    score=$((score + c_passed * 2))
    log_debug "+$((c_passed * 2)): Checks C1-C8 pasados ($c_passed)"

    # Ejemplos suficientes
    local examples
    examples=$(grep -cE "(✅|❌|🔧)" "$file" 2>/dev/null || echo "0")
    if [[ $examples -ge $MIN_EXAMPLES_TIER2 ]]; then
        score=$((score + 15))
        log_debug "+15: Ejemplos suficientes ($examples >= $MIN_EXAMPLES_TIER2)"
    elif [[ $examples -ge $MIN_EXAMPLES_TIER1 ]]; then
        score=$((score + 10))
        log_debug "+10: Ejemplos básicos ($examples >= $MIN_EXAMPLES_TIER1)"
    fi

    # Determinismo
    if check_determinism; then
        score=$((score + 15))
        log_debug "+15: Determinismo verificado"
    fi

    # Healthcheck para TIER 3
    if grep -qE 'healthcheck|health_check' "$file" 2>/dev/null; then
        score=$((score + 10))
        log_debug "+10: Healthcheck presente"
    fi

    # Namespace aislado
    if grep -qE '(mantis-vps|tenant_|kb_)' "$file" 2>/dev/null; then
        score=$((score + 10))
        log_debug "+10: Namespace aislado"
    fi

    # SHA256
    if [[ -n "$SHA256_CHECKSUM" && "$SHA256_CHECKSUM" != "unavailable" ]]; then
        score=$((score + 5))
        log_debug "+5: SHA256 calculado"
    fi

    # === FACTORES QUE RESTAN ===

    # Placeholders
    local placeholder_count
    placeholder_count=$(grep -cE '(TODO|FIXME|CAMBIAR|\${[^}]+\?)' "$file" 2>/dev/null || echo "0")
    if [[ $placeholder_count -gt 0 ]]; then
        score=$((score - placeholder_count * 5))
        log_debug "-$((placeholder_count * 5)): Placeholders ($placeholder_count)"
    fi

    FINAL_SCORE=$score

    # Determinar tier
    if [[ $score -ge $TIER3_MIN_SCORE ]]; then
        FINAL_TIER=3
        log_success "🏆 TIER 3 - Auto-Deploy + ZIP Autónomo"
    elif [[ $score -ge $TIER2_MIN_SCORE ]]; then
        FINAL_TIER=2
        log_success "🥈 TIER 2 - Autogeneración + Entrega Pantalla"
    elif [[ $score -ge $TIER1_MIN_SCORE ]]; then
        FINAL_TIER=1
        log_success "🥉 TIER 1 - SDD Asistida por IA"
    else
        FINAL_TIER=0
        log_error "❌ RECHAZADO - Puntaje insuficiente ($score < $TIER1_MIN_SCORE)"
        BLOCKING_MESSAGE="SCORE_FAIL: Insufficient maturity ($score)"
        return 1
    fi

    log_info "   Puntaje final: $score / 100+"
    log_info "   Tier certificado: $FINAL_TIER"
    log_info "   Tier esperado: ${EXPECTED_TIER:-no especificado}"

    return 0
}

# ------------------------------------------------------------------------------
# SECCIÓN 6: CAPA 4 - ENRUTAMIENTO Y ACCIÓN
# ------------------------------------------------------------------------------
# Según tier asignado, decide siguiente acción

# ------------------------------------------------------------------------------
# generate_json_report(): Genera reporte en formato JSON
# ------------------------------------------------------------------------------
generate_json_report() {
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    cat << EOF
{
  "orchestrator_version": "${ORCHESTRATOR_VERSION}",
  "timestamp": "${timestamp}",
  "file_path": "${TARGET_FILE}",
  "file_type": "${TARGET_FILE_TYPE}",
  "folder_category": "${TARGET_FOLDER_CATEGORY}",
  "function": "${TARGET_FUNCTION}",
  "tier_certified": ${FINAL_TIER},
  "tier_requested": ${EXPECTED_TIER:-0},
  "tier_match": $([ ${FINAL_TIER} -ge ${EXPECTED_TIER:-0} ] && echo "true" || echo "false"),
  "score": ${FINAL_SCORE},
  "passed_checks": [
$(for check in "${CHECKS_PASSED[@]}"; do echo "    {\"check\": \"$check\", \"status\": \"PASS\"},"; done | sed '$ s/,$//')
  ],
  "blocking_issues": [
$(for check in "${CHECKS_FAILED[@]}"; do echo "    {\"check\": \"$check\", \"status\": \"FAIL\"},"; done | sed '$ s/,$//')
  ],
  "warnings": [
$(for check in "${CHECKS_WARNED[@]}"; do echo "    {\"check\": \"$check\", \"status\": \"WARN\"},"; done | sed '$ s/,$//')
  ],
  "validators_invoked": [
$(for v in "${VALIDATORS_INVOKED[@]}"; do echo "    \"$v\","; done | sed '$ s/,$//')
  ],
  "sha256": "${SHA256_CHECKSUM}",
  "next_step": "$(case $FINAL_TIER in 3) echo "deploy_allowed";; 2) echo "merge_allowed";; 1) echo "human_review_required";; *) echo "rejected";; esac)",
  "ci_gate_required": $([ $FINAL_TIER -ge 2 ] && echo "true" || echo "false"),
  "human_approval_required": $([ $FINAL_TIER -eq 1 ] && echo "true" || echo "false"),
  "blocking_message": "${BLOCKING_MESSAGE:-}"
}
EOF
}

# ------------------------------------------------------------------------------
# print_summary(): Imprime resumen final (modo interactivo)
# ------------------------------------------------------------------------------
print_summary() {
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "RESUMEN DE VALIDACIÓN"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    echo ""
    echo -e "  ${COLOR_BOLD}Archivo:${COLOR_RESET} ${TARGET_FILE}"
    echo -e "  ${COLOR_BOLD}Tipo:${COLOR_RESET} ${TARGET_FILE_TYPE}"
    echo -e "  ${COLOR_BOLD}Función:${COLOR_RESET} ${TARGET_FUNCTION}"
    echo -e "  ${COLOR_BOLD}Ubicación:${COLOR_RESET} ${TARGET_FOLDER}"
    echo ""

    if [[ $FINAL_TIER -gt 0 ]]; then
        local tier_color tier_label tier_action
        case $FINAL_TIER in
            3) tier_color="$COLOR_RED"; tier_label="TIER 3 - AUTO-DEPLOY"; tier_action="Pipeline directo → Deploy" ;;
            2) tier_color="$COLOR_YELLOW"; tier_label="TIER 2 - AUTOGENERACIÓN"; tier_action="Merge automático tras CI gate" ;;
            1) tier_color="$COLOR_GREEN"; tier_label="TIER 1 - SDD ASISTIDA"; tier_action="Requiere aprobación humana" ;;
        esac

        echo -e "  ${tier_color}${COLOR_BOLD}★ ${tier_label}${COLOR_RESET}"
        echo -e "  ${COLOR_BOLD}Acción:${COLOR_RESET} ${tier_action}"
        echo ""
        echo -e "  ${COLOR_BOLD}Puntaje:${COLOR_RESET} ${FINAL_SCORE} / 100+"
        echo -e "  ${COLOR_BOLD}SHA256:${COLOR_RESET} ${SHA256_CHECKSUM}"
        echo ""
    fi

    # Mostrar warnings si hay
    if [[ ${#CHECKS_WARNED[@]} -gt 0 ]]; then
        echo -e "  ${COLOR_YELLOW}${COLOR_BOLD}⚠ ADVERTENCIAS (${#CHECKS_WARNED[@]}):${COLOR_RESET}"
        for warn in "${CHECKS_WARNED[@]}"; do
            echo -e "    • ${warn}"
        done
        echo ""
    fi

    # Mostrar errores bloqueantes
    if [[ ${#CHECKS_FAILED[@]} -gt 0 ]]; then
        echo -e "  ${COLOR_RED}${COLOR_BOLD}✗ ERRORES BLOQUEANTES (${#CHECKS_FAILED[@]}):${COLOR_RESET}"
        for fail in "${CHECKS_FAILED[@]}"; do
            echo -e "    • ${fail}"
        done
        echo ""
    fi

    # Validadores invocados
    if [[ ${#VALIDATORS_INVOKED[@]} -gt 0 ]]; then
        echo -e "  ${COLOR_CYAN}${COLOR_BOLD}Validadores invocados:${COLOR_RESET}"
        for v in "${VALIDATORS_INVOKED[@]}"; do
            echo -e "    • $v"
        done
        echo ""
    fi

    # Recomendación
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    case $FINAL_TIER in
        3)
            echo -e "  ${COLOR_GREEN}✅ CERTIFICADO: NIVEL 3${COLOR_RESET}"
            echo -e "  ${COLOR_GREEN}Pipeline directo habilitado.${COLOR_RESET}"
            ;;
        2)
            echo -e "  ${COLOR_YELLOW}✅ CERTIFICADO: NIVEL 2${COLOR_RESET}"
            echo -e "  ${COLOR_YELLOW}Merge automático tras pasar gate CI.${COLOR_RESET}"
            ;;
        1)
            echo -e "  ${COLOR_BLUE}✅ CERTIFICADO: NIVEL 1${COLOR_RESET}"
            echo -e "  ${COLOR_BLUE}Requiere revisión y aprobación humana.${COLOR_RESET}"
            ;;
        *)
            echo -e "  ${COLOR_RED}❌ NO CERTIFICADO${COLOR_RESET}"
            echo -e "  ${COLOR_RED}${BLOCKING_MESSAGE:-Puntaje insuficiente}${COLOR_RESET}"
            ;;
    esac
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ------------------------------------------------------------------------------
# determine_exit_action(): Determina la acción y código de salida
# ------------------------------------------------------------------------------
determine_exit_action() {
    if [[ -n "$BLOCKING_MESSAGE" ]]; then
        # Error bloqueante
        if [[ "$BLOCKING_MESSAGE" == C3_FAIL* ]] || [[ "$BLOCKING_MESSAGE" == C4_FAIL* ]]; then
            EXIT_CODE=2  # CRITICAL_BLOCK
        else
            EXIT_CODE=1  # VALIDATION_FAILED
        fi
    elif [[ $FINAL_TIER -eq 0 ]]; then
        EXIT_CODE=1
    else
        EXIT_CODE=0  # SUCCESS
    fi
}

# ------------------------------------------------------------------------------
# SECCIÓN 7: FLUJO PRINCIPAL
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# run_interactive_mode(): Modo guiado para humanos
# ------------------------------------------------------------------------------
run_interactive_mode() {
    print_banner

    echo -e "  ${COLOR_BOLD}Modo:${COLOR_RESET} INTERACTIVO"
    echo -e "  ${COLOR_BOLD}Fecha:${COLOR_RESET} $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    # Crear directorios si no existen
    mkdir -p "$REPORT_DIR" "$LOG_DIR"

    # Solicitar información al usuario
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo -e "  ${COLOR_BOLD}CONFIGURACIÓN DE VALIDACIÓN${COLOR_RESET}"
    echo -e "${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo ""

    read -r -p "  📁 Ruta del archivo a validar: " TARGET_FILE
    TARGET_FILE=$(eval echo "$TARGET_FILE" 2>/dev/null || echo "$TARGET_FILE")

    if [[ ! -f "$TARGET_FILE" ]]; then
        log_error "Archivo no encontrado: $TARGET_FILE"
        exit 3
    fi

    echo ""
    echo "  Seleccione tier objetivo:"
    echo "    [1] TIER 1 - SDD Asistida (documentación, skills en progreso)"
    echo "    [2] TIER 2 - Autogeneración (scripts, configs)"
    echo "    [3] TIER 3 - Auto-Deploy (infraestructura, pipelines)"
    read -r -p "  Selección [1-3]: " tier_input
    EXPECTED_TIER="${tier_input:-1}"

    echo ""
    echo "  Seleccione función:"
    echo "    [1] documentation  [2] pattern      [3] configuration"
    echo "    [4] agent-def     [5] pipeline     [6] skill"
    echo "    [7] script        [8] runbook      [9] auto-detectar"
    read -r -p "  Selección [1-9]: " func_input

    case "${func_input:-9}" in
        1) TARGET_FUNCTION="documentation" ;;
        2) TARGET_FUNCTION="pattern" ;;
        3) TARGET_FUNCTION="configuration" ;;
        4) TARGET_FUNCTION="agent-definition" ;;
        5) TARGET_FUNCTION="pipeline" ;;
        6) TARGET_FUNCTION="skill" ;;
        7) TARGET_FUNCTION="script" ;;
        8) TARGET_FUNCTION="runbook" ;;
        *) TARGET_FUNCTION="" ;;
    esac

    echo ""
    read -r -p "  ¿Modo STRICT (warnings son errores)? [y/N]: " strict_input
    [[ "${strict_input,,}" == "y" ]] && STRICT_MODE=true

    echo ""
    log_info "Iniciando validación..."
    echo ""

    # Ejecutar capas
    if ! run_capa1_identity; then
        print_summary
        exit 3  # IDENTITY_MISSING
    fi

    if ! run_capa2_normative; then
        determine_exit_action
        print_summary
        exit $EXIT_CODE
    fi

    if ! calculate_tier_score; then
        determine_exit_action
        print_summary
        exit $EXIT_CODE
    fi

    # Calcular SHA256
    calculate_sha256 "$TARGET_FILE"

    # Determinar acción final
    determine_exit_action

    # Mostrar resumen
    print_summary

    exit $EXIT_CODE
}

# ------------------------------------------------------------------------------
# run_headless_mode(): Modo silencioso para IAs y CI/CD
# ------------------------------------------------------------------------------
run_headless_mode() {
    # En modo headless, todo va a stderr, solo JSON a stdout
    log_debug "Iniciando modo HEADLESS"

    if [[ -z "$TARGET_FILE" ]]; then
        echo '{"error": "TARGET_FILE required in headless mode"}' >&2
        exit 3
    fi

    if [[ ! -f "$TARGET_FILE" ]]; then
        echo "{\"error\": \"File not found: $TARGET_FILE\"}" >&2
        exit 3
    fi

    # Ejecutar capas silenciosamente
    if ! run_capa1_identity 2>/dev/null; then
        generate_json_report
        exit 3
    fi

    if ! run_capa2_normative 2>/dev/null; then
        generate_json_report
        determine_exit_action
        exit $EXIT_CODE
    fi

    if ! calculate_tier_score 2>/dev/null; then
        generate_json_report
        determine_exit_action
        exit $EXIT_CODE
    fi

    # Calcular SHA256
    calculate_sha256 "$TARGET_FILE"

    # Determinar acción final
    determine_exit_action

    # Generar reporte
    if [[ "$OUTPUT_JSON" == "true" ]]; then
        generate_json_report
    else
        # Modo simple: solo resultado
        if [[ $EXIT_CODE -eq 0 ]]; then
            echo "TIER_${FINAL_TIER} CERTIFIED"
        else
            echo "VALIDATION_FAILED: ${BLOCKING_MESSAGE}"
        fi
    fi

    exit $EXIT_CODE
}

# ------------------------------------------------------------------------------
# SECCIÓN 8: PARSEO DE ARGUMENTOS Y PUNTO DE ENTRADA
# ------------------------------------------------------------------------------

main() {
    # Verificar dependencias primero
    check_dependencies || exit 4

    # Cargar matriz de normas canónicas (obligatorio para validación contextual)
    load_norms_matrix || {
        log_error "No se puede continuar sin matriz de normas"
        exit 4  # VALIDATOR_ERROR
    }
    
    # Parsear argumentos
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --mode)
                MODE="$2"
                shift 2
                ;;
            -f|--file)
                TARGET_FILE="$2"
                shift 2
                ;;
            -d|--dir)
                TARGET_FOLDER="$2"
                shift 2
                ;;
            -t|--tier)
                EXPECTED_TIER="$2"
                shift 2
                ;;
            --function)
                TARGET_FUNCTION="$2"
                shift 2
                ;;
            --json)
                OUTPUT_JSON=true
                shift
                ;;
            --strict)
                STRICT_MODE=true
                shift
                ;;
            -h|--help)
                print_banner
                usage
                exit 0
                ;;
            --version)
                echo "orchestrator-engine.sh version $ORCHESTRATOR_VERSION"
                exit 0
                ;;
            *)
                log_error "Opción desconocida: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Validar modo
    case "$MODE" in
        interactive|headless)
            ;;
        *)
            log_error "Modo inválido: $MODE"
            usage
            exit 1
            ;;
    esac

    # Ejecutar según modo
    if [[ "$MODE" == "interactive" ]]; then
        run_interactive_mode
    else
        run_headless_mode
    fi
}

# Punto de entrada
# Los argumentos se procesan en main()
main "$@"
