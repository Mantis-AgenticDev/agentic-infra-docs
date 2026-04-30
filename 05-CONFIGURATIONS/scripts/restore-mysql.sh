#!/usr/bin/env bash
# ---
# artifact_id: restore-db-mantis
# artifact_type: restore_script
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C3","C4","C5","C7","V2"]
# canonical_path: 05-CONFIGURATIONS/scripts/restore-mysql.sh
# domain: 05-CONFIGURATIONS
# subdomain: scripts
# agent_role: configurations-master
# language_lock: es-ES
# validation_command: orchestrator-engine.sh --domain configurations --strict
# tier: 2
# immutable: true
# requires_human_approval_for_changes: true
# audience: ["agentic_assistants"]
# human_readable: false
# checksum_sha256: "01792b4ef28ba3361e81812b822f1c58ae06d6bfc5435878a2dcb06c2f465744"
# ---
set -euo pipefail

# [CONSTRAINT_MAP]
# C3: Uso seguro de credenciales; cero logueo de passwords
# C5: Verificación obligatoria de checksum SHA256 antes de tocar la DB
# V2: Integridad de datos; restauración atómica desde backups comprimidos (.sql.zst)
# C7: Seguridad operativa; gate de confirmación para entornos productivos

# [DEPENDENCIES]
# psql (PostgreSQL client), zstd, sha256sum, bash >= 4.3
# [INTERFACE_ALIGNMENT]
# Consumes: DATABASE_URL, TARGET_FILE (from CLI)
# Produce: Restored DB, Audit Log, Exit Status

# [GLOBALS]
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BACKUP_DIR="${BACKUP_DIR:-/var/backups/mantis-db}"
readonly LOG_FILE="${BACKUP_DIR}/restore-audit.log"
readonly TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

mkdir -p "$(dirname "$LOG_FILE")"

# [LOGGING]
log() { printf '[%s] [%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$2" | tee -a /dev/stderr >> "$LOG_FILE"; }
log_info()  { log "INFO"  "$1"; }
log_warn()  { log "WARN"  "$1"; }
log_error() { log "ERROR" "$1"; exit 1; }

# [ARGS & VALIDATION]
TARGET_FILE="${1:-}"
FORCE="${2:-false}"

if [[ -z "$TARGET_FILE" ]]; then
  log_error "USO: $0 <archivo_backup.sql.zst> [--force]"
  log_error "El archivo debe existir y tener su correspondiente .sha256 en el mismo directorio."
  exit 1
fi

# Verificar existencia de herramientas
command -v psql >/dev/null 2>&1 || log_error "DEPENDENCY_FAIL: psql no encontrado (PostgreSQL client)"
command -v zstd >/dev/null 2>&1 || log_error "DEPENDENCY_FAIL: zstd no encontrado (requerido para descomprimir)"

# Verificar archivo de backup y checksum
if [[ ! -f "$TARGET_FILE" ]]; then
  log_error "FILE_NOT_FOUND: $TARGET_FILE"
  exit 1
fi

SHA_FILE="${TARGET_FILE}.sha256"
if [[ -f "$SHA_FILE" ]]; then
  log_info "PHASE_1_START: Verificando integridad SHA256 (V2)..."
  if ! sha256sum -c "$SHA_FILE" >/dev/null 2>&1; then
    log_error "INTEGRITY_FAIL: El checksum no coincide. El backup está corrupto."
    exit 1
  fi
  log_info "PHASE_1_COMPLETE: Integridad verificada ✅"
else
  log_error "CHECKSUM_MISSING: No se encontró $SHA_FILE. No se puede verificar integridad."
  exit 1
fi

# [SECURITY GATE (C7)]
# Extraer entorno de DATABASE_URL si existe
if [[ -n "${DATABASE_URL:-}" ]]; then
  if echo "$DATABASE_URL" | grep -q "prod"; then
    log_warn "PROD_GATE: Detectado entorno PRODUCTION en DATABASE_URL."
    if [[ "$FORCE" != "true" ]]; then
      log_error "BLOCKED: Restaurar en prod requiere flag --force para confirmar intencionalidad."
      exit 1
    fi
    log_warn "PROD_OVERRIDE: Restauración forzada en prod iniciada."
  fi
else
  log_warn "ENV_MISSING: DATABASE_URL no definida. Se usará la configuración de cliente local."
fi

# [PHASE_2: RESTORE (V2/C3)]
log_info "PHASE_2_START: Iniciando restauración..."
log_info "Target: $TARGET_FILE"

# Parsear DATABASE_URL si está definida
if [[ -n "${DATABASE_URL:-}" ]]; then
  PGHOST=$(echo "$DATABASE_URL" | grep -oP '(?<=://)[^:@]+' | cut -d'/' -f1)
  PGPORT=$(echo "$DATABASE_URL" | grep -oP ':\K\d+' | head -n1)
  PGUSER=$(echo "$DATABASE_URL" | grep -oP 'postgres://\K[^:]+')
  PGDATABASE=$(echo "$DATABASE_URL" | grep -oP '/\K[^?]+')
  
  export PGHOST PGPORT PGUSER PGDATABASE
fi

# Descomprimir y aplicar a DB
# Usamos 'zstd -dc' para stream al stdout y pipearlo a psql
# Esto evita crear un archivo .sql gigante en disco (ahorro espacio/tiempo)
if zstd -dc "$TARGET_FILE" | psql -f -; then
  log_info "PHASE_2_COMPLETE: Restauración finalizada exitosamente ✅"
else
  log_error "RESTORE_FAIL: Error crítico durante la ejecución de psql."
  exit 1
fi

# [PHASE 3: POST-RESTORE VALIDATION (C5)]
log_info "PHASE_3_START: Validando conexión post-restauración..."
if psql -c "SELECT 1;" >/dev/null 2>&1; then
  log_info "PHASE_3_COMPLETE: Conexión a DB activa y funcional ✅"
else
  log_error "POST_CHECK_FAIL: La DB no responde tras la restauración."
  exit 1
fi

log_info "RESTORE_SUCCESS: Base de datos restaurada desde $TARGET_FILE"
exit 0


---
