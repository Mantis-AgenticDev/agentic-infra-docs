#!/usr/bin/env bash
# 05-CONFIGURATIONS/scripts/packager-assisted.sh
# ==============================================================================
# SDD Hardened Agentic Packager
# ==============================================================================
# Descripción: Script maestro para empaquetar skills generadas por IA en 
# artefactos ZIP listos para despliegue humano. Valida constraints C1-C8,
# inyecta configuraciones de entorno seguras y genera checksums.
#
# Uso: ./packager-assisted.sh <tenant_id> [--mode auto|assisted]
#
# Reglas Aplicadas: C1, C2, C3, C4, C5, C7, C8
# ==============================================================================

set -euo pipefail

# --- CONFIGURACIÓN GLOBAL ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
TEMP_DIR="${ROOT_DIR}/.temp_packaging_$(date +%s)"
RELEASES_DIR="${ROOT_DIR}/releases"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# --- COLORES PARA OUTPUT ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- FUNCIONES DE LOGGING (C8) ---
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_json_event() {
    local event=$1
    local tenant_id=$2
    local details=$3
    echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"event\":\"$event\",\"tenant_id\":\"$tenant_id\",\"details\":\"$details\"}" >> "${TEMP_DIR}/packaging.log"
}

# --- VALIDACIÓN DE ENTRADA (C4) ---
TENANT_ID=${1:?$(log_error "C4 VIOLATION: tenant_id is required as first argument.")}
MODE=${2:-auto}

if [[ ! "$TENANT_ID" =~ ^[a-z0-9-]+$ ]]; then
    log_error "C4 VIOLATION: tenant_id must be kebab-case alphanumeric."
    exit 1
fi

log_info "Iniciando empaquetado para tenant: $TENANT_ID (Mode: $MODE)"
mkdir -p "$TEMP_DIR" "$RELEASES_DIR"
log_json_event "packaging_start" "$TENANT_ID" "mode=$MODE"

# --- PASO 1: VALIDACIÓN DE PRE-REQUISITOS ---
log_info "Paso 1: Validando pre-requisitos..."

if ! command -v zip &> /dev/null; then
    log_error "Dependency missing: 'zip' command not found. Install it."
    exit 1
fi

if [ ! -f "${ROOT_DIR}/config/bootstrap-company.json" ]; then
    log_error "C3/C4 Missing: config/bootstrap-company.json not found."
    exit 1
fi

# Validar que el tenant_id exista en el bootstrap
if ! grep -q "\"tenant_id\": \"$TENANT_ID\"" "${ROOT_DIR}/config/bootstrap-company.json"; then
    log_error "C4 MISMATCH: Tenant ID $TENANT_ID not found in bootstrap config."
    exit 1
fi

log_json_event "prerequisites_check" "$TENANT_ID" "passed"

# --- PASO 2: COPIA DE ARTEFACTOS GENERADOS ---
log_info "Paso 2: Copiando artefactos generados..."

# Estructura base del ZIP
mkdir -p "${TEMP_DIR}/${TENANT_ID}/{src,config,infra,docs,scripts,tests}"

# Copiar código fuente generado (asumiendo ruta estándar)
if [ -d "${ROOT_DIR}/generated_skills/${TENANT_ID}" ]; then
    cp -r "${ROOT_DIR}/generated_skills/${TENANT_ID}/"* "${TEMP_DIR}/${TENANT_ID}/src/"
else
    log_warn "No generated skills found for $TENANT_ID. Creating empty src dir."
fi

# Copiar configuración segura
cp "${ROOT_DIR}/config/bootstrap-company.json" "${TEMP_DIR}/${TENANT_ID}/config/"
cp "${ROOT_DIR}/05-CONFIGURATIONS/templates/.env.example" "${TEMP_DIR}/${TENANT_ID}/config/.env.example" 2>/dev/null || touch "${TEMP_DIR}/${TENANT_ID}/config/.env.example"

# Copiar scripts de validación y deploy
cp "${ROOT_DIR}/05-CONFIGURATIONS/scripts/validate-constraints-cli.sh" "${TEMP_DIR}/${TENANT_ID}/scripts/" 2>/dev/null || true
cp "${ROOT_DIR}/05-CONFIGURATIONS/scripts/smoke_test_deploy.ts" "${TEMP_DIR}/${TENANT_ID}/scripts/" 2>/dev/null || true

# Copiar documentación generada
if [ -d "${ROOT_DIR}/docs/generated_skills/${TENANT_ID}" ]; then
    cp -r "${ROOT_DIR}/docs/generated_skills/${TENANT_ID}/"* "${TEMP_DIR}/${TENANT_ID}/docs/"
fi

log_json_event "artifacts_copied" "$TENANT_ID" "success"

# --- PASO 3: VALIDACIÓN DE CONSTRAINTS C1-C6 (C5) ---
log_info "Paso 3: Ejecutando validación de constraints C1-C6..."

VALIDATION_SCRIPT="${TEMP_DIR}/${TENANT_ID}/scripts/validate-constraints-cli.sh"
if [ -f "$VALIDATION_SCRIPT" ]; then
    chmod +x "$VALIDATION_SCRIPT"
    # Ejecutar validación en el directorio temporal
    cd "${TEMP_DIR}/${TENANT_ID}"
    if bash "$VALIDATION_SCRIPT"; then
        log_info "Validación de constraints EXITOSA."
        log_json_event "constraints_validation" "$TENANT_ID" "passed"
    else
        log_error "Validación de constraints FALLIDA. Revisa los logs."
        log_json_event "constraints_validation" "$TENANT_ID" "failed"
        exit 1
    fi
    cd "$ROOT_DIR"
else
    log_warn "Script de validación no encontrado. Omitiendo paso automático."
fi

# --- PASO 4: INYECCIÓN DE VARIABLES DE ENTORNO SEGURAS (C3) ---
log_info "Paso 4: Preparando .env.example..."

cat > "${TEMP_DIR}/${TENANT_ID}/config/.env.example" <<EOF
# ==============================================================================
# Environment Variables for Tenant: ${TENANT_ID}
# NEVER commit this file with real values to version control.
# ==============================================================================

# C4: Multi-Tenancy
TENANT_ID=${TENANT_ID}

# C1/C2: Operational Limits
MAX_RESULTS=50
TIMEOUT_MS=30000
CONNECTION_LIMIT=15

# C3: Secrets (Replace with actual values in production env)
DB_PRIMARY_DSN=postgresql://user:pass@host:5432/dbname
OPENROUTER_API_KEY=sk-or-v1-...
QDRANT_URL=http://localhost:6333
QDRANT_API_KEY=your-qdrant-key

# C6: AI Routing
MODEL_PREFERENCE=qwen/qwen-2.5-72b-instruct
PROVIDER_PROXY=openrouter
EOF

log_json_event "env_template_injected" "$TENANT_ID" "success"

# --- PASO 5: EMPAQUETADO ZIP (C7) ---
log_info "Paso 5: Comprimiendo artefactos..."

ZIP_NAME="release-${TENANT_ID}-${TIMESTAMP}.zip"
cd "${TEMP_DIR}"
zip -r "${RELEASES_DIR}/${ZIP_NAME}" "${TENANT_ID}/" -x "*.git/*" "*.DS_Store" > /dev/null
cd "$ROOT_DIR"

if [ ! -f "${RELEASES_DIR}/${ZIP_NAME}" ]; then
    log_error "Fallo al crear el archivo ZIP."
    exit 1
fi

log_info "ZIP creado: ${RELEASES_DIR}/${ZIP_NAME}"
log_json_event "zip_created" "$TENANT_ID" "file=${ZIP_NAME}"

# --- PASO 6: CHECKSUM Y FIRMA (C8) ---
log_info "Paso 6: Generando checksum SHA256..."

sha256sum "${RELEASES_DIR}/${ZIP_NAME}" > "${RELEASES_DIR}/${ZIP_NAME}.sha256"
CHECKSUM=$(cat "${RELEASES_DIR}/${ZIP_NAME}.sha256" | awk '{print $1}')

log_info "SHA256: $CHECKSUM"
log_json_event "checksum_generated" "$TENANT_ID" "sha256=${CHECKSUM}"

# --- PASO 7: LIMPIEZA Y MENSAJE FINAL ---
log_info "Paso 7: Limpiando archivos temporales..."
rm -rf "$TEMP_DIR"

echo ""
echo "=============================================================================="
echo "✅ EMPAQUETADO COMPLETADO CON ÉXITO"
echo "=============================================================================="
echo "📦 Artefacto: ${RELEASES_DIR}/${ZIP_NAME}"
echo "🔐 Checksum:  $CHECKSUM"
echo "👤 Tenant:    $TENANT_ID"
echo "=============================================================================="
echo "Instrucciones para Deploy Humano:"
echo "1. Descomprimir: unzip ${ZIP_NAME}"
echo "2. Configurar:   cp config/.env.example config/.env && editar .env"
echo "3. Validar:      ./scripts/validate-constraints-cli.sh"
echo "4. Desplegar:    docker-compose up -d (o según infra definida)"
echo "=============================================================================="

log_json_event "packaging_complete" "$TENANT_ID" "status=success"
exit 0

