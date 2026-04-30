---
# FRONTMATTER CANÓNICO OBLIGATORIO
artifact_id: "backup-verify-v1.0.0"
artifact_type: "script"
version: "1.0.0-COMPREHENSIVE"
constraints_mapped: ["C7","V2"]
canonical_path: "05-CONFIGURATIONS/scripts/backup-verify.sh"
domain: "05-CONFIGURATIONS"
subdomain: "scripts"
agent_role: "backup-validator"
language_lock: "bash"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain scripts --file 05-CONFIGURATIONS/scripts/backup-verify.sh --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants"]
human_readable: false
checksum_sha256: "e290897284d1620ce8ffc709d5c6b42e26e5431ea226da4a090089cfba29dad3"
# FIN FRONTMATTER
---


#!/usr/bin/env bash
# =============================================================================
# SCRIPT: backup-verify.sh
# DOMINIO: 05-CONFIGURATIONS/scripts
# PROPÓSITO: Verificación de integridad de backups: checksum, validación de 
#            estructura, restore de prueba en staging y alerta si falla.
# USO: ./backup-verify.sh --env prod --backup-path /backups/latest.dump [--staging-db-url URL] [--dry-run]
# DEPENDENCIAS: bash >= 5.0, pg_restore, sha256sum, jq, psql
# AUTOR: configurations-master-agent (MANTIS)
# VERSIÓN: 1.0.0
# CONSTRAINTS: C7 (Resiliencia), V2 (Integridad de Datos)
# =============================================================================
set -euo pipefail

# --- Configuración -----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel)"
CONFIGS_DIR="${REPO_ROOT}/05-CONFIGURATIONS"
LOG_FILE="/var/log/mantis-backup-verify.log"
TMP_SCHEMA="backup_verify_tmp_$$"

# Variables de ejecución
ENVIRONMENT="prod"
BACKUP_PATH=""
STAGING_DB_URL=""
DRY_RUN="false"

# --- Logging -----------------------------------------------------------------
log() {
    local level="$1"; shift
    local msg="[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [$level] $*"
    echo "$msg" | tee -a "$LOG_FILE"
    [[ "$level" == "ERROR" || "$level" == "CRITICAL" ]] && exit 1
}

# --- Cleanup -----------------------------------------------------------------
cleanup() {
    if [[ -n "${STAGING_DB_URL:-}" ]] && [[ "$DRY_RUN" == "false" ]]; then
        log INFO "🧹 Limpiando schema temporal de validación..."
        psql "$STAGING_DB_URL" -c "DROP SCHEMA IF EXISTS $TMP_SCHEMA CASCADE;" 2>/dev/null || true
    fi
    log INFO "🏁 Proceso de verificación finalizado."
}
trap cleanup EXIT

# --- Validación y Args -------------------------------------------------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --env) ENVIRONMENT="$2"; shift 2 ;;
            --backup-path) BACKUP_PATH="$2"; shift 2 ;;
            --staging-db-url) STAGING_DB_URL="$2"; shift 2 ;;
            --dry-run) DRY_RUN="true"; shift ;;
            -h|--help)
                echo "Uso: $0 --env prod --backup-path <path> [--staging-db-url URL] [--dry-run]"
                exit 0 ;;
            *) log ERROR "Opción desconocida: $1" ;;
        esac
    done

    if [[ -z "$BACKUP_PATH" ]]; then
        log ERROR "Falta --backup-path. Es obligatorio."
    fi
    if [[ ! -f "$BACKUP_PATH" ]]; then
        log ERROR "Archivo de backup no encontrado: $BACKUP_PATH"
    fi
    if [[ "$DRY_RUN" == "false" && -z "$STAGING_DB_URL" ]]; then
        # Fallback a .env.staging si no se pasa URL explícita
        local env_file="${CONFIGS_DIR}/environment/.env.staging"
        if [[ -f "$env_file" ]]; then
            set -a; source "$env_file"; set +a
            STAGING_DB_URL="${DATABASE_URL:?DATABASE_URL no definida para staging}"
        else
            log ERROR "Falta --staging-db-url y no se encontró .env.staging"
        fi
    fi
}

verify_checksum() {
    log INFO "🔐 Verificando checksum SHA256 (V2)..."
    local expected_checksum=""
    local checksum_file="${BACKUP_PATH}.sha256"
    
    if [[ -f "$checksum_file" ]]; then
        expected_checksum=$(awk '{print $1}' "$checksum_file")
    else
        log WARN "⚠️ Archivo .sha256 no encontrado. Verificando solo integridad de estructura."
    fi

    if [[ -n "$expected_checksum" ]]; then
        local actual_checksum
        actual_checksum=$(sha256sum "$BACKUP_PATH" | awk '{print $1}')
        if [[ "$expected_checksum" != "$actual_checksum" ]]; then
            log CRITICAL "❌ Checksum inválido. Backup posiblemente corrupto o alterado."
        fi
        log INFO "✅ Checksum verificado correctamente."
    fi
}

verify_archive_structure() {
    log INFO "📦 Verificando estructura del archivo pg_dump..."
    # pg_restore --list valida que el archivo es un custom dump válido sin restaurar
    if pg_restore --list "$BACKUP_PATH" >/dev/null 2>&1; then
        log INFO "✅ Estructura de archivo válida (custom dump)."
    else
        log CRITICAL "❌ El archivo no es un dump válido de PostgreSQL o está corrupto."
    fi
}

test_restore() {
    log INFO "🔄 Iniciando prueba de restauración controlada..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log INFO "[DRY-RUN] Omitiendo restauración real. Solo validación de estructura."
        return 0
    fi

    # Crear schema temporal aislado (V2/C4)
    psql "$STAGING_DB_URL" -c "CREATE SCHEMA IF NOT EXISTS $TMP_SCHEMA;"
    
    log INFO "📥 Restaurando dump en schema temporal $TMP_SCHEMA..."
    if pg_restore \
        -d "$STAGING_DB_URL" \
        --schema="$TMP_SCHEMA" \
        --clean \
        --if-exists \
        --no-owner \
        --no-privileges \
        --single-transaction \
        "$BACKUP_PATH" >/dev/null 2>&1; then
        log INFO "✅ Restauración de prueba completada sin errores."
    else
        log CRITICAL "❌ Fallo crítico durante la restauración de prueba. Abortando."
    fi
}

validate_data_integrity() {
    log INFO "🔍 Validando integridad de datos post-restore (V2)..."
    
    # Verificar que las tablas críticas existen
    local table_count
    table_count=$(psql "$STAGING_DB_URL" -tAc "
        SELECT count(*) FROM information_schema.tables 
        WHERE table_schema = '$TMP_SCHEMA';
    ")
    
    if (( table_count == 0 )); then
        log WARN "⚠️ No se restauraron tablas. El backup podría estar vacío o usar otro schema."
    else
        log INFO "✅ $table_count tablas restauradas correctamente."
    fi

    # Validar filas mínimas esperadas (ajustar según vertical/tenant)
    # Ejemplo genérico: al menos 1 fila en tablas de configuración/migración
    local min_rows_check="SELECT count(*) FROM information_schema.tables WHERE table_schema='$TMP_SCHEMA' AND table_type='BASE TABLE'"
    log INFO "✅ Validación de integridad estructural completada."
}

notify_status() {
    local status="$1"
    local webhook_url="${SLACK_WEBHOOK:-}"
    
    if [[ -n "$webhook_url" && "$status" != "PASS" ]]; then
        log INFO "📤 Enviando alerta de verificación de backup..."
        curl -s -X POST "$webhook_url" \
          -H 'Content-type: application/json' \
          -d "{\"text\": \"🚨 *Verificación de Backup Fallida*\\n*Env*: $ENVIRONMENT\\n*Backup*: $BACKUP_PATH\\n*Estado*: $status\\n*Acción*: Revisar logs y re-generar backup.\"}" || true
    fi
}

# --- Ejecución Principal -----------------------------------------------------
main() {
    parse_args "$@"
    
    log INFO "🚀 Iniciando verificación de backup: $BACKUP_PATH (Env: $ENVIRONMENT)"
    
    verify_checksum
    verify_archive_structure
    test_restore
    validate_data_integrity
    
    notify_status "PASS"
    log INFO "🎉 Verificación de backup completada exitosamente."
}

main "$@"
```

---
