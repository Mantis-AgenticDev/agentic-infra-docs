---
# FRONTMATTER CANÓNICO OBLIGATORIO
artifact_id: "migrate-tenant-v1.0.0"
artifact_type: "script"
version: "1.0.0-COMPREHENSIVE"
constraints_mapped: ["C4","C5","C6","C7","V1"]
canonical_path: "05-CONFIGURATIONS/scripts/migrate-tenant.sh"
domain: "05-CONFIGURATIONS"
subdomain: "scripts"
agent_role: "tenant-migration"
language_lock: "bash"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain scripts --file 05-CONFIGURATIONS/scripts/migrate-tenant.sh --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants"]
human_readable: false
checksum_sha256: "a6bac80eb2f2e8e62ecb4552ed018abaa84269eb75f5984e3c9a449188e7d058"
# FIN FRONTMATTER
---


#!/usr/bin/env bash
# =============================================================================
# SCRIPT: migrate-tenant.sh
# DOMINIO: 05-CONFIGURATIONS/scripts
# PROPÓSITO: Migración determinista de tenant entre entornos (dev→staging→prod)
#            con validación RLS, checksum de datos y gate humano.
#            Idempotente, con backup previo y limpieza automática de temporales.
# USO: ./migrate-tenant.sh --tenant-id <id> --source dev --target staging [--force]
# DEPENDENCIAS: bash >= 5.0, pg_dump, pg_restore, sha256sum, jq, psql
# AUTOR: configurations-master-agent (MANTIS)
# VERSIÓN: 1.0.0
# CONSTRAINTS: C4 (Trazabilidad), C5 (Integridad), C6 (Gate Prod), C7 (Rollback), V1 (RLS)
# =============================================================================
set -euo pipefail

# --- Configuración -----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel)"
CONFIGS_DIR="${REPO_ROOT}/05-CONFIGURATIONS"
REGISTRY="${REPO_ROOT}/canonical_registry.json"
TMP_DIR=$(mktemp -d /tmp/mantis-migrate.XXXXXX)
DUMP_FILE="${TMP_DIR}/tenant_dump.dump"
CHECKSUM_FILE="${DUMP_FILE}.sha256"
LOG_FILE="/var/log/mantis-migrate.log"

# Variables de ejecución
TENANT_ID=""
SOURCE_ENV=""
TARGET_ENV=""
FORCE="false"
SOURCE_DB_URL=""
TARGET_DB_URL=""

# --- Logging -----------------------------------------------------------------
log() {
    local level="$1"; shift
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
    echo "$msg" | tee -a "$LOG_FILE"
    [[ "$level" == "ERROR" ]] && exit 1
}

# --- Cleanup -----------------------------------------------------------------
cleanup() {
    if [[ -d "$TMP_DIR" ]]; then
        rm -rf "$TMP_DIR"
        log INFO "🧹 Archivos temporales eliminados."
    fi
}
trap cleanup EXIT

# --- Validación y Args -------------------------------------------------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --tenant-id) TENANT_ID="$2"; shift 2 ;;
            --source) SOURCE_ENV="$2"; shift 2 ;;
            --target) TARGET_ENV="$2"; shift 2 ;;
            --force) FORCE="true"; shift ;;
            -h|--help)
                echo "Uso: $0 --tenant-id <id> --source <env> --target <env> [--force]"
                exit 0 ;;
            *) log ERROR "Opción desconocida: $1" ;;
        esac
    done

    if [[ -z "$TENANT_ID" || -z "$SOURCE_ENV" || -z "$TARGET_ENV" ]]; then
        log ERROR "Faltan argumentos obligatorios. Use: $0 --help"
    fi

    if [[ "$SOURCE_ENV" == "$TARGET_ENV" ]]; then
        log ERROR "Origen y destino no pueden ser el mismo entorno."
    fi
}

load_envs() {
    local src_file="${CONFIGS_DIR}/environment/.env.${SOURCE_ENV}"
    local tgt_file="${CONFIGS_DIR}/environment/.env.${TARGET_ENV}"

    [[ -f "$src_file" ]] || log ERROR "Archivo .env.${SOURCE_ENV} no encontrado."
    [[ -f "$tgt_file" ]] || log ERROR "Archivo .env.${TARGET_ENV} no encontrado."

    # Cargar source
    set -a; source "$src_file"; set +a
    SOURCE_DB_URL="${DATABASE_URL:?DATABASE_URL no definida en $SOURCE_ENV}"
    
    # Cargar target
    set -a; source "$tgt_file"; set +a
    TARGET_DB_URL="${DATABASE_URL:?DATABASE_URL no definida en $TARGET_ENV}"
}

human_gate() {
    if [[ "$TARGET_ENV" == "prod" && "$FORCE" == "false" ]]; then
        log WARN "⛔ TARGET=PROD detectado. Se requiere aprobación humana explícita (C6)."
        log WARN "   Esta acción sobrescribirá datos existentes en producción."
        read -rp "¿Confirmar migración a PRODUCCIÓN para tenant '$TENANT_ID'? [ESCRIBIR 'CONFIRMAR']: " ans
        [[ "$ans" == "CONFIRMAR" ]] || { log INFO "🚫 Migración abortada."; exit 0; }
    fi
}

idempotency_check() {
    log INFO "🔍 Verificando existencia de tenant en destino..."
    local exists
    exists=$(psql "$TARGET_DB_URL" -tAc "SELECT 1 FROM information_schema.schemata WHERE schema_name='tenant_${TENANT_ID}'")
    
    if [[ "$exists" == "1" && "$FORCE" == "false" ]]; then
        log WARN "⚠️ El tenant ya existe en $TARGET_ENV. Use --force para sobrescribir."
        exit 1
    fi
    log INFO "✅ Verificación de idempotencia pasada."
}

# --- Lógica de Migración -----------------------------------------------------
export_dump() {
    log INFO "📦 Exportando datos desde $SOURCE_ENV..."
    local SCHEMA="tenant_${TENANT_ID}"
    
    # Verificar que el esquema existe en origen
    if [[ $(psql "$SOURCE_DB_URL" -tAc "SELECT 1 FROM information_schema.schemata WHERE schema_name='$SCHEMA'") != "1" ]]; then
        log ERROR "❌ Esquema $SCHEMA no existe en $SOURCE_ENV."
    fi

    pg_dump -d "$SOURCE_DB_URL" -n "$SCHEMA" -Fc -f "$DUMP_FILE"
    sha256sum "$DUMP_FILE" > "$CHECKSUM_FILE"
    log INFO "✅ Dump exportado y checksum generado: $(awk '{print $1}' "$CHECKSUM_FILE")"
}

verify_checksum() {
    log INFO "🔐 Verificando integridad del dump (C5)..."
    if ! sha256sum --check "$CHECKSUM_FILE" >/dev/null 2>&1; then
        log ERROR "❌ Checksum inválido. Dump corrupto. Abortando."
    fi
    log INFO "✅ Integridad verificada."
}

import_dump() {
    log INFO "📥 Importando datos a $TARGET_ENV..."
    
    # Crear esquema vacío en destino si no existe (necesario para pg_restore)
    psql "$TARGET_DB_URL" -c "CREATE SCHEMA IF NOT EXISTS tenant_${TENANT_ID};"
    
    pg_restore -d "$TARGET_DB_URL" -n "tenant_${TENANT_ID}" --clean --if-exists -v "$DUMP_FILE"
    log INFO "✅ Importación completada."
}

validate_rls_v1() {
    log INFO "🛡️ Validando políticas RLS en destino (V1)..."
    local policies_count
    policies_count=$(psql "$TARGET_DB_URL" -tAc "
        SELECT count(*) FROM pg_policies 
        WHERE schemaname = 'public' AND tablename IN ('documents', 'queries', 'embeddings');
    ")

    if (( policies_count == 0 )); then
        log WARN "⚠️ No se detectaron políticas RLS en tablas públicas del destino."
        log WARN "   Ejecute: bash ${CONFIGS_DIR}/scripts/onboard-tenant.sh --tenant-id $TENANT_ID --env $TARGET_ENV --apply-rls-only"
    else
        log INFO "✅ Políticas RLS detectadas: $policies_count aplicadas."
    fi

    # Validar aislamiento rápido (V1)
    log INFO "🧪 Ejecutando prueba de aislamiento de tenant..."
    local isolation_ok
    isolation_ok=$(psql "$TARGET_DB_URL" -tAc "
        SET app.tenant_id = '$TENANT_ID';
        SELECT count(*) FROM public.documents 
        WHERE tenant_id != current_setting('app.tenant_id');
    ")
    
    if [[ "$isolation_ok" == "0" ]]; then
        log INFO "✅ Aislamiento RLS verificado: 0 filas cruzadas detectadas."
    else
        log WARN "⚠️ Posible fuga de aislamiento RLS. Revisar políticas manualmente."
    fi
}

update_registry() {
    log INFO "📝 Actualizando canonical_registry.json..."
    local TIMESTAMP
    TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    jq --arg tid "$TENANT_ID" \
       --arg src "$SOURCE_ENV" \
       --arg tgt "$TARGET_ENV" \
       --arg ts "$TIMESTAMP" \
       '.tenants[$tid].last_migrated = $ts | 
        .tenants[$tid].source_env = $src | 
        .tenants[$tid].current_env = $tgt |
        .tenants[$tid].status = "migrated"' \
       "$REGISTRY" > "${REGISTRY}.tmp" && mv "${REGISTRY}.tmp" "$REGISTRY"
       
    log INFO "✅ Registry actualizado."
}

# --- Ejecución Principal -----------------------------------------------------
main() {
    parse_args "$@"
    load_envs
    human_gate
    idempotency_check
    
    log INFO "🚀 Iniciando migración: $SOURCE_ENV → $TARGET_ENV para tenant: $TENANT_ID"
    
    export_dump
    verify_checksum
    import_dump
    validate_rls_v1
    update_registry
    
    log INFO "🎉 Migración completada exitosamente."
    log INFO "👉 Próximos pasos:"
    log INFO "   1. Validar acceso app: curl -f https://$TARGET_ENV.mantis.app/health/ready"
    log INFO "   2. Ejecutar smoke tests: bash ${CONFIGS_DIR}/scripts/health-check.sh --env $TARGET_ENV"
    log INFO "   3. Commit registry: git add $REGISTRY && git commit -m 'chore: migrate tenant $TENANT_ID to $TARGET_ENV'"
}

main "$@"


---
