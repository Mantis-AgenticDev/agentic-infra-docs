## Archivo 2: `05-CONFIGURATIONS/validation/orchestrator-engine.sh`
#!/usr/bin/env bash
#
# =============================================================================
#   GOVERNANCE ORCHESTRATOR ENGINE v1.0.0
#   Sistema central de certificación de artefactos SDD
# =============================================================================
# 
# Este script implementa un motor de decisión por capas que evalúa un archivo
# según su identidad, normas C1-C8, y madurez funcional, para asignarle un
# Nivel (Tier) y determinar las acciones subsecuentes (revisión humana,
# merge automático, o despliegue autónomo).
#
# USO:
#   Modo interactivo (humano):
#     ./orchestrator-engine.sh --interactive
#
#   Modo headless (IA/CI/CD):
#     ./orchestrator-engine.sh --json-input <archivo.json>
#
#   Modo directo (para pruebas):
#     ./orchestrator-engine.sh --file <ruta> --type <tipo> --folder <carpeta>
#
# SALIDA:
#   En modo interactivo: reporte legible en pantalla + log.
#   En modo headless: JSON estructurado con nivel, checks, issues, next_step.
#
# DEPENDENCIAS:
#   - jq (para JSON)
#   - yq (para YAML, opcional)
#   - shellcheck, yamllint, terraform (según tipo de archivo)
#   - Los validadores del proyecto (audit-secrets.sh, check-rls.sh, etc.)
#
# AUTOR: Equipo de Arquitectura Agéntica
# FECHA: 2025-04-11
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# CONFIGURACIÓN GLOBAL Y CONSTANTES
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VALIDATION_DIR="$SCRIPT_DIR"                     # donde residen los validadores
SCRIPTS_DIR="$PROJECT_ROOT/05-CONFIGURATIONS/scripts"
LOG_FILE="/tmp/orchestrator-$(date +%Y%m%d-%H%M%S).log"

# Colores para terminal interactiva
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Niveles de certificación
TIER_1="1"   # SDD Asistida
TIER_2="2"   # Autogeneración + Entrega
TIER_3="3"   # Auto-Deploy + ZIP

# -----------------------------------------------------------------------------
# FUNCIONES AUXILIARES
# -----------------------------------------------------------------------------

# Log tanto a archivo como a consola (si es interactivo)
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    if [[ "${INTERACTIVE:-false}" == "true" ]]; then
        case "$level" in
            ERROR)   echo -e "${RED}[ERROR]${NC} $message" ;;
            WARNING) echo -e "${YELLOW}[WARN]${NC} $message" ;;
            INFO)    echo -e "${BLUE}[INFO]${NC} $message" ;;
            SUCCESS) echo -e "${GREEN}[OK]${NC} $message" ;;
            *)       echo "$message" ;;
        esac
    fi
}

# Verificar disponibilidad de herramientas externas
check_dependencies() {
    local missing=()
    command -v jq >/dev/null 2>&1 || missing+=("jq")
    # yq es opcional, pero recomendado
    command -v yq >/dev/null 2>&1 || log WARNING "yq no encontrado (opcional, algunas validaciones YAML serán limitadas)"
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log ERROR "Dependencias faltantes: ${missing[*]}"
        exit 1
    fi
}

# Obtener el tipo de archivo real (basado en extensión y contenido)
detect_file_type() {
    local file="$1"
    local ext="${file##*.}"
    case "$ext" in
        sh)          echo "bash" ;;
        tf)          echo "terraform" ;;
        yaml|yml)    echo "yaml" ;;
        md)          echo "markdown" ;;
        json)        echo "json" ;;
        py)          echo "python" ;;
        js)          echo "javascript" ;;
        *)           echo "unknown" ;;
    esac
}

# Determinar la carpeta canónica donde reside o se ubicará el archivo
# (Usa PROJECT_TREE.md como referencia si está disponible)
get_canonical_folder() {
    local file="$1"
    local rel_path="${file#$PROJECT_ROOT/}"
    # Extraer el primer directorio de la ruta (ej. "02-SKILLS/BASE DE DATOS-RAG/archivo.md" -> "02-SKILLS")
    echo "$rel_path" | cut -d'/' -f1
}

# -----------------------------------------------------------------------------
# CAPA 1: IDENTIDAD Y CONTEXTO
# -----------------------------------------------------------------------------
layer_identity() {
    log INFO "🔍 Capa 1: Estableciendo identidad y contexto"
    
    # Variables globales que se llenarán
    FILE_PATH=""
    FILE_TYPE=""
    TARGET_FOLDER=""
    FUNCTION=""
    METADATA_OK=false
    
    if [[ "$HEADLESS" == "true" ]]; then
        # Modo headless: valores vienen del JSON
        FILE_PATH="${INPUT_FILE_PATH}"
        FILE_TYPE="${INPUT_FILE_TYPE}"
        TARGET_FOLDER="${INPUT_TARGET_FOLDER}"
        FUNCTION="${INPUT_FUNCTION}"
    else
        # Modo interactivo: preguntar
        echo -e "${BLUE}=== CAPA 1: IDENTIDAD DEL ARTEFACTO ===${NC}"
        read -p "Ruta completa del archivo (o ruta donde se creará): " FILE_PATH
        FILE_TYPE=$(detect_file_type "$FILE_PATH")
        echo "Tipo detectado: $FILE_TYPE"
        read -p "Confirma el tipo (bash/terraform/yaml/markdown/json/other): " input_type
        [[ -n "$input_type" ]] && FILE_TYPE="$input_type"
        read -p "Directorio destino (ej. 02-SKILLS/INFRASTRUCTURA/): " TARGET_FOLDER
        read -p "Función principal del archivo: " FUNCTION
    fi
    
    # Validaciones básicas
    if [[ ! -f "$FILE_PATH" && "$HEADLESS" != "true" ]]; then
        log WARNING "El archivo no existe aún. Se validará la intención."
    fi
    
    # Verificar metadatos canónicos si el archivo existe
    if [[ -f "$FILE_PATH" ]]; then
        case "$FILE_TYPE" in
            markdown)
                if grep -q "^canonical_path:" "$FILE_PATH" && grep -q "^ai_optimized:" "$FILE_PATH"; then
                    METADATA_OK=true
                    log SUCCESS "Metadatos canónicos presentes"
                else
                    log ERROR "Falta frontmatter canónico en archivo Markdown"
                    return 1
                fi
                ;;
            yaml|terraform)
                # Buscar comentarios con metadatos
                if grep -q "# canonical_path:" "$FILE_PATH" || grep -q "# @canonical" "$FILE_PATH"; then
                    METADATA_OK=true
                else
                    log WARNING "Metadatos canónicos no detectados (requerido para Tier 2+)"
                fi
                ;;
            bash)
                if head -n 20 "$FILE_PATH" | grep -q "# canonical_path:"; then
                    METADATA_OK=true
                else
                    log WARNING "Metadatos canónicos no detectados"
                fi
                ;;
        esac
    fi
    
    log INFO "Identidad establecida: Tipo=$FILE_TYPE, Carpeta=$TARGET_FOLDER, Función=$FUNCTION"
    return 0
}

# -----------------------------------------------------------------------------
# CAPA 2: FILTRO NORMATIVO C1-C8
# -----------------------------------------------------------------------------
layer_normative_filter() {
    log INFO "📏 Capa 2: Aplicando filtro normativo C1-C8"
    
    # Inicializar contadores
    BLOCKING_ISSUES=()
    WARNINGS=()
    PASSED_CHECKS=()
    
    # C1/C2: Límites de recursos (búsqueda básica)
    if [[ -f "$FILE_PATH" ]]; then
        if grep -qE "memory|cpu|limits|requests" "$FILE_PATH"; then
            PASSED_CHECKS+=("C1/C2")
        else
            WARNINGS+=("C1/C2: No se declaran límites de recursos explícitos")
        fi
    fi
    
    # C3: Cero hardcode de secretos (usará audit-secrets.sh más tarde, pero hacemos pre-check)
    if [[ -f "$FILE_PATH" ]]; then
        if grep -qE "(password|secret|api_key|token)\s*=\s*[\"'][^$][^\"']+[\"']" "$FILE_PATH"; then
            BLOCKING_ISSUES+=("C3: Posible hardcode de secretos detectado")
        else
            PASSED_CHECKS+=("C3")
        fi
    fi
    
    # C4: tenant_id presente (búsqueda básica)
    if [[ -f "$FILE_PATH" ]]; then
        if grep -q "tenant_id" "$FILE_PATH"; then
            PASSED_CHECKS+=("C4")
        else
            # Para ciertos directorios es obligatorio
            if [[ "$TARGET_FOLDER" == *"BASE DE DATOS-RAG"* || "$TARGET_FOLDER" == *"DATABASE"* ]]; then
                BLOCKING_ISSUES+=("C4: tenant_id ausente en contexto de base de datos")
            else
                WARNINGS+=("C4: tenant_id no referenciado (requerido para multi-tenancy)")
            fi
        fi
    fi
    
    # C5: Comando de validación declarado
    if [[ -f "$FILE_PATH" ]]; then
        if grep -q "validation_command\|validate.*&&" "$FILE_PATH"; then
            PASSED_CHECKS+=("C5")
        else
            WARNINGS+=("C5: Falta comando de validación explícito o ejemplos")
        fi
    fi
    
    # C6: Cloud-only inference
    if [[ -f "$FILE_PATH" ]]; then
        if grep -q "localhost:11434\|http://localhost" "$FILE_PATH"; then
            WARNINGS+=("C6: Referencia a localhost en entorno de producción")
        else
            PASSED_CHECKS+=("C6")
        fi
    fi
    
    # C7: Resiliencia declarada (timeouts, retries)
    if [[ -f "$FILE_PATH" ]]; then
        if grep -qE "timeout|retry|healthcheck|circuit" "$FILE_PATH"; then
            PASSED_CHECKS+=("C7")
        else
            WARNINGS+=("C7: No se detectan mecanismos de resiliencia")
        fi
    fi
    
    # C8: Observabilidad (JSON logs, trace_id)
    if [[ -f "$FILE_PATH" ]]; then
        if grep -qE "json.*log|trace_id|otel" "$FILE_PATH"; then
            PASSED_CHECKS+=("C8")
        else
            WARNINGS+=("C8: Observabilidad estructurada no declarada")
        fi
    fi
    
    # Si hay bloqueos críticos (C3 o C4), detener
    for issue in "${BLOCKING_ISSUES[@]}"; do
        log ERROR "$issue"
    done
    if [[ ${#BLOCKING_ISSUES[@]} -gt 0 ]]; then
        log ERROR "Fallo crítico en filtro normativo. No se puede continuar."
        return 1
    fi
    
    log SUCCESS "Filtro normativo superado (con ${#WARNINGS[@]} advertencias)"
    return 0
}

# -----------------------------------------------------------------------------
# CAPA 3: CERTIFICACIÓN POR NIVELES (TIER)
# -----------------------------------------------------------------------------
determine_tier() {
    log INFO "📊 Capa 3: Determinando nivel de certificación"
    
    # Base: asumimos Tier 1
    TIER="$TIER_1"
    
    # Requisitos mínimos Tier 1: sintaxis válida (se verificó antes o se verificará por validadores)
    # Además debe tener al menos 5 ejemplos (verificado por validador de markdown)
    
    # Para Tier 2: 0 placeholders, validador ejecutable, determinismo, >=10 ejemplos
    local placeholders_found=0
    if [[ -f "$FILE_PATH" ]]; then
        placeholders_found=$(grep -cE "TODO|FIXME|CAMBIAR|<.*>|\$\{.*:?\}" "$FILE_PATH" || true)
    fi
    
    if [[ $placeholders_found -eq 0 ]] && [[ "$METADATA_OK" == "true" ]]; then
        # Cumple condiciones básicas para Tier 2
        TIER="$TIER_2"
        log INFO "Cumple condiciones para Tier 2 (sin placeholders, metadatos OK)"
        
        # Para Tier 3: necesita idempotencia, healthcheck, rollback, CI/CD trigger
        # Estos se evalúan con validadores específicos; aquí hacemos un pre-chequeo
        if [[ -f "$FILE_PATH" ]]; then
            if grep -q "idempotent\|idempotency\|healthcheck\|rollback" "$FILE_PATH"; then
                TIER="$TIER_3"
                log SUCCESS "Cumple condiciones para Tier 3 (idempotencia/healthcheck declarados)"
            fi
        fi
    fi
    
    # Ajuste según carpeta (según matriz de mapeo)
    case "$TARGET_FOLDER" in
        00-CONTEXT|07-PROCEDURES)
            # Máximo Tier 1 por diseño
            [[ "$TIER" -gt 1 ]] && TIER=1
            ;;
        01-RULES|03-AGENTS|06-PROGRAMMING)
            # Máximo Tier 2
            [[ "$TIER" -gt 2 ]] && TIER=2
            ;;
        04-WORKFLOWS|05-CONFIGURATIONS)
            # Puede llegar a Tier 3
            ;;
    esac
    
    log INFO "Nivel certificado: $TIER"
}

# -----------------------------------------------------------------------------
# CAPA 4: ENRUTAMIENTO Y EJECUCIÓN DE VALIDADORES EXTERNOS
# -----------------------------------------------------------------------------
invoke_validators() {
    log INFO "🔧 Capa 4: Invocando validadores específicos"
    
    # Array para almacenar resultados de cada validador
    VALIDATOR_RESULTS=()
    
    # Función para ejecutar un validador y capturar su salida
    run_validator() {
        local validator="$1"
        local args="$2"
        local description="$3"
        log INFO "Ejecutando $description..."
        if [[ -x "$VALIDATION_DIR/$validator" ]]; then
            if $VALIDATION_DIR/$validator $args >> "$LOG_FILE" 2>&1; then
                VALIDATOR_RESULTS+=("$validator: OK")
                log SUCCESS "$validator finalizó correctamente"
            else
                VALIDATOR_RESULTS+=("$validator: FAIL")
                log ERROR "$validator reportó errores"
                return 1
            fi
        else
            log WARNING "$validator no encontrado o no ejecutable"
            VALIDATOR_RESULTS+=("$validator: SKIP (no disponible)")
        fi
        return 0
    }
    
    # Según tipo de archivo y carpeta, invocar validadores (matriz de mapeo)
    case "$FILE_TYPE" in
        bash)
            run_validator "audit-secrets.sh" "$FILE_PATH" "audit-secrets.sh (C3)"
            run_validator "verify-constraints.sh" "$FILE_PATH" "verify-constraints.sh (C1-C6)"
            # Shellcheck se ejecuta aparte si está disponible
            if command -v shellcheck >/dev/null 2>&1; then
                if shellcheck -x "$FILE_PATH" >> "$LOG_FILE" 2>&1; then
                    VALIDATOR_RESULTS+=("shellcheck: OK")
                else
                    VALIDATOR_RESULTS+=("shellcheck: FAIL")
                    log ERROR "shellcheck encontró problemas"
                fi
            fi
            ;;
        terraform)
            run_validator "audit-secrets.sh" "$FILE_PATH" "audit-secrets.sh (C3)"
            run_validator "validate-frontmatter.sh" "$FILE_PATH" "validate-frontmatter.sh (metadatos)"
            if command -v terraform >/dev/null 2>&1; then
                (cd "$(dirname "$FILE_PATH")" && terraform fmt -check "$(basename "$FILE_PATH")" >> "$LOG_FILE" 2>&1) \
                    && VALIDATOR_RESULTS+=("terraform fmt: OK") \
                    || { VALIDATOR_RESULTS+=("terraform fmt: FAIL"); log ERROR "terraform fmt falló"; }
                (cd "$(dirname "$FILE_PATH")" && terraform validate >> "$LOG_FILE" 2>&1) \
                    && VALIDATOR_RESULTS+=("terraform validate: OK") \
                    || { VALIDATOR_RESULTS+=("terraform validate: FAIL"); log ERROR "terraform validate falló"; }
            fi
            ;;
        yaml)
            run_validator "validate-frontmatter.sh" "$FILE_PATH" "validate-frontmatter.sh"
            if command -v yamllint >/dev/null 2>&1; then
                if yamllint "$FILE_PATH" >> "$LOG_FILE" 2>&1; then
                    VALIDATOR_RESULTS+=("yamllint: OK")
                else
                    VALIDATOR_RESULTS+=("yamllint: FAIL")
                fi
            fi
            # Si es un workflow n8n, usar schema-validator
            if [[ "$FILE_PATH" == *"workflow"* || "$FILE_PATH" == *"n8n"* ]]; then
                run_validator "schema-validator.py" "$FILE_PATH" "schema-validator.py (n8n schema)"
            fi
            ;;
        markdown)
            run_validator "validate-frontmatter.sh" "$FILE_PATH" "validate-frontmatter.sh"
            run_validator "check-wikilinks.sh" "$FILE_PATH" "check-wikilinks.sh"
            # Contar ejemplos (requisito >=5 para Tier 1)
            local examples_count=$(grep -cE '✅|❌|🔧' "$FILE_PATH" || true)
            if [[ $examples_count -ge 5 ]]; then
                VALIDATOR_RESULTS+=("examples_check: OK ($examples_count ejemplos)")
            else
                VALIDATOR_RESULTS+=("examples_check: FAIL (solo $examples_count ejemplos, se requieren >=5)")
            fi
            ;;
        json)
            run_validator "schema-validator.py" "$FILE_PATH" "schema-validator.py"
            if command -v jq >/dev/null 2>&1; then
                if jq empty "$FILE_PATH" >> "$LOG_FILE" 2>&1; then
                    VALIDATOR_RESULTS+=("jq syntax: OK")
                else
                    VALIDATOR_RESULTS+=("jq syntax: FAIL")
                    log ERROR "JSON mal formado"
                fi
            fi
            ;;
        *)
            log WARNING "Tipo de archivo no reconocido, se aplicarán validadores genéricos"
            run_validator "audit-secrets.sh" "$FILE_PATH" "audit-secrets.sh"
            ;;
    esac
    
    # Validadores específicos por carpeta
    if [[ "$TARGET_FOLDER" == *"BASE DE DATOS-RAG"* || "$FILE_PATH" == *".sql"* ]]; then
        run_validator "check-rls.sh" "$FILE_PATH" "check-rls.sh (C4 multi-tenancy)"
    fi
    
    # Si es Tier 3 y existe packager-assisted.sh, sugerir empaquetado
    if [[ "$TIER" == "$TIER_3" ]]; then
        if [[ -x "$SCRIPTS_DIR/packager-assisted.sh" ]]; then
            log INFO "Preparando para empaquetado Tier 3..."
            VALIDATOR_RESULTS+=("packager: ready (ejecutar packager-assisted.sh manualmente)")
        fi
    fi
}

# -----------------------------------------------------------------------------
# GENERAR REPORTE FINAL Y SALIDA
# -----------------------------------------------------------------------------
generate_report() {
    log INFO "📄 Generando reporte final"
    
    # Construir objeto JSON para salida headless
    local json_output
    json_output=$(jq -n \
        --arg tier "$TIER" \
        --argjson passed "$(printf '%s\n' "${PASSED_CHECKS[@]}" | jq -R . | jq -s .)" \
        --argjson blocking "$(printf '%s\n' "${BLOCKING_ISSUES[@]}" | jq -R . | jq -s .)" \
        --argjson warnings "$(printf '%s\n' "${WARNINGS[@]}" | jq -R . | jq -s .)" \
        --argjson validators "$(printf '%s\n' "${VALIDATOR_RESULTS[@]}" | jq -R . | jq -s .)" \
        --arg next_step "$( [[ "$TIER" == "$TIER_1" ]] && echo "Requiere revisión humana" || \
                          [[ "$TIER" == "$TIER_2" ]] && echo "Listo para merge automático (CI gate)" || \
                          echo "Listo para deploy autónomo (ejecutar packager-assisted.sh)" )" \
        --arg recommended_action "$( [[ ${#BLOCKING_ISSUES[@]} -gt 0 ]] && echo "block" || echo "pass" )" \
        '{
            tier_certified: $tier,
            passed_checks: $passed,
            blocking_issues: $blocking,
            warnings: $warnings,
            validator_results: $validators,
            recommended_action: $recommended_action,
            next_step: $next_step,
            log_file: $logfile
        }' --arg logfile "$LOG_FILE")
    
    if [[ "$HEADLESS" == "true" ]]; then
        echo "$json_output" | jq .
    else
        echo -e "\n${GREEN}========================================${NC}"
        echo -e "${GREEN}  CERTIFICACIÓN FINAL: NIVEL $TIER${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo -e "Checks superados: ${PASSED_CHECKS[*]}"
        if [[ ${#WARNINGS[@]} -gt 0 ]]; then
            echo -e "${YELLOW}Advertencias:${NC}"
            printf '  • %s\n' "${WARNINGS[@]}"
        fi
        echo -e "Resultados de validadores:"
        printf '  • %s\n' "${VALIDATOR_RESULTS[@]}"
        echo -e "\n${BLUE}Acción recomendada:${NC} $([[ ${#BLOCKING_ISSUES[@]} -gt 0 ]] && echo "CORREGIR BLOQUEOS" || echo "CONTINUAR")"
        echo -e "${BLUE}Próximo paso:${NC} $([[ "$TIER" == "$TIER_1" ]] && echo "Someter a revisión humana" || \
                           [[ "$TIER" == "$TIER_2" ]] && echo "Merge automático tras CI" || \
                           echo "Ejecutar packager-assisted.sh para despliegue autónomo")"
        echo -e "\nLog completo: $LOG_FILE"
    fi
}

# -----------------------------------------------------------------------------
# FUNCIÓN PRINCIPAL
# -----------------------------------------------------------------------------
main() {
    # Parseo de argumentos
    INTERACTIVE=false
    HEADLESS=false
    INPUT_JSON_FILE=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --interactive)
                INTERACTIVE=true
                shift
                ;;
            --json-input)
                HEADLESS=true
                INPUT_JSON_FILE="$2"
                shift 2
                ;;
            --file)
                # Modo directo (útil para pruebas)
                FILE_PATH="$2"
                shift 2
                ;;
            --type)
                FILE_TYPE="$2"
                shift 2
                ;;
            --folder)
                TARGET_FOLDER="$2"
                shift 2
                ;;
            *)
                echo "Opción desconocida: $1"
                exit 1
                ;;
        esac
    done
    
    # Verificar dependencias
    check_dependencies
    
    # Si es headless, cargar JSON
    if [[ "$HEADLESS" == "true" ]]; then
        if [[ ! -f "$INPUT_JSON_FILE" ]]; then
            echo "ERROR: Archivo JSON no encontrado: $INPUT_JSON_FILE"
            exit 1
        fi
        INPUT_FILE_PATH=$(jq -r '.file_path' "$INPUT_JSON_FILE")
        INPUT_FILE_TYPE=$(jq -r '.file_type' "$INPUT_JSON_FILE")
        INPUT_TARGET_FOLDER=$(jq -r '.target_folder' "$INPUT_JSON_FILE")
        INPUT_FUNCTION=$(jq -r '.function' "$INPUT_JSON_FILE")
        log INFO "Modo headless iniciado con entrada JSON"
    fi
    
    # Ejecutar capas
    if ! layer_identity; then
        log ERROR "Capa 1 falló. Abortando."
        exit 1
    fi
    
    if ! layer_normative_filter; then
        # En modo headless, emitir JSON de fallo
        if [[ "$HEADLESS" == "true" ]]; then
            jq -n --argjson issues "$(printf '%s\n' "${BLOCKING_ISSUES[@]}" | jq -R . | jq -s .)" \
                '{ tier_certified: 0, blocking_issues: $issues, recommended_action: "block" }'
        fi
        exit 1
    fi
    
    determine_tier
    invoke_validators
    generate_report
}

# -----------------------------------------------------------------------------
# PUNTO DE ENTRADA
# -----------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi


---
