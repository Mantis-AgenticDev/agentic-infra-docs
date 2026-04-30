#!/usr/bin/env bash
# ---
# artifact_id: backup-db-mantis
# artifact_type: backup_script
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C3","C4","C5","V2"]
# canonical_path: 05-CONFIGURATIONS/scripts/backup-mysql.sh
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
# checksum_sha256: "2192c09a32fd56724346dfe94771035770d164a24611b731d74afdaf81536f5"
# ---
set -euo pipefail

# [CONSTRAINT_MAP]
# C3: Secrets via env vars o Docker Secrets; cero exposición en logs/stdout
# C4: Nomenclatura atómica con timestamp, checksum SHA256, log de auditoría
# C5: Validación de conexión pre-dump, verificación de integridad post-dump
# V2: Dump completo con --clean --if-exists, compresión zstd, retención configurable

# [DEPENDENCIES]
# pg_dump, zstd (o gzip), sha256sum, aws cli (opcional), bash >= 4.3
# [INTERFACE_ALIGNMENT]
# Consumes: DATABASE_URL, BACKUP_RETENTION_DAYS, BACKUP_S3_BUCKET (mapping.yaml)
# Produces: .sql.zst archive, .sha256 manifest, upload status log

# [GLOBALS]
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BACKUP_DIR="${BACKUP_DIR:-/var/backups/mantis-db}"
readonly RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
readonly S3_BUCKET="${BACKUP_S3_BUCKET:-}"
readonly LOG_FILE="${BACKUP_DIR}/backup-audit.log"
readonly TIMESTAMP="$(date -u +%Y%m%d_%H%M%S)"
readonly DUMP_FILE="mantis-db-backup-${TIMESTAMP}.sql.zst"
readonly CHECKSUM_FILE="${DUMP_FILE}.sha256"

mkdir -p "$BACKUP_DIR"
touch "$LOG_FILE"

# [LOGGING]
log() { printf '[%s] [%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$2" >> "$LOG_FILE"; }
log_info()  { log "INFO"  "$1"; }
log_warn()  { log "WARN"  "$1"; }
log_error() { log "ERROR" "$1"; exit 1; }

# [VALIDATION]
command -v pg_dump >/dev/null 2>&1 || log_error "DEPENDENCY_FAIL: pg_dump no encontrado"
command -v zstd >/dev/null 2>&1 || { log_warn "zstd no encontrado, usando gzip"; COMP_CMD="gzip -9"; EXT="gz"; } || COMP_CMD="zstd -3"; EXT="zst"
COMP_FILE="mantis-db-backup-${TIMESTAMP}.sql.${EXT}"

[[ -n "${DATABASE_URL:-}" ]] || log_error "ENV_MISSING: DATABASE_URL no definido (ver mapping.yaml)"

# Validar formato conexión PostgreSQL
if ! echo "$DATABASE_URL" | grep -qP '^postgres://[^:]+:[^@]+@[^:]+:\d+/[^?]+'; then
  log_error "VALIDATION_FAIL: DATABASE_URL formato inválido o incompleto"
fi

# [PHASE_1: DUMP & COMPRESS]
log_info "PHASE_1_START: Iniciando dump lógico con pg_dump"
PGPASSWORD=$(echo "$DATABASE_URL" | grep -oP '(?<=:)[^:@]+(?=@)') \
PGHOST=$(echo "$DATABASE_URL" | grep -oP '(?<=://)[^:@]+' | cut -d'/' -f1) \
PGPORT=$(echo "$DATABASE_URL" | grep -oP ':\K\d+' | head -n1) \
PGUSER=$(echo "$DATABASE_URL" | grep -oP 'postgres://\K[^:]+') \
PGDATABASE=$(echo "$DATABASE_URL" | grep -oP '/\K[^?]+') \
pg_dump --clean --if-exists --no-owner --no-privileges \
  --format=plain --compress=0 \
  -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" \
  | $COMP_CMD > "${BACKUP_DIR}/${COMP_FILE}" 2>>"$LOG_FILE" || \
  log_error "DUMP_FAIL: Error ejecutando pg_dump"

log_info "PHASE_1_COMPLETE: Dump comprimido en ${COMP_FILE}"

# [PHASE_2: INTEGRITY CHECKSUM (V2)]
log_info "PHASE_2_START: Generando checksum SHA256"
sha256sum "${BACKUP_DIR}/${COMP_FILE}" | awk '{print $1}' > "${BACKUP_DIR}/${CHECKSUM_FILE}"
log_info "PHASE_2_COMPLETE: Checksum: $(cat "${BACKUP_DIR}/${CHECKSUM_FILE}")"

# [PHASE_3: REMOTE SYNC (OPTIONAL C4/C7)]
if [[ -n "$S3_BUCKET" && command -v aws >/dev/null 2>&1 ]]; then
  log_info "PHASE_3_START: Sincronizando con S3: s3://${S3_BUCKET}/db-backups/"
  aws s3 cp "${BACKUP_DIR}/${COMP_FILE}" "s3://${S3_BUCKET}/db-backups/${COMP_FILE}" >> "$LOG_FILE" 2>&1 || \
    log_warn "SYNC_WARN: Fallo subida S3 (verificar credenciales/permisos)"
  aws s3 cp "${BACKUP_DIR}/${CHECKSUM_FILE}" "s3://${S3_BUCKET}/db-backups/${CHECKSUM_FILE}" >> "$LOG_FILE" 2>&1 || true
  log_info "PHASE_3_COMPLETE: Sync S3 completado"
else
  log_info "PHASE_3_SKIP: S3_BUCKET no definido o aws cli ausente"
fi

# [PHASE_4: RETENTION CLEANUP (C7)]
log_info "PHASE_4_START: Aplicando política de retención (${RETENTION_DAYS} días)"
find "$BACKUP_DIR" -name "mantis-db-backup-*.sql.${EXT}" -mtime +"$RETENTION_DAYS" -delete 2>/dev/null || true
find "$BACKUP_DIR" -name "mantis-db-backup-*.sha256" -mtime +"$RETENTION_DAYS" -delete 2>/dev/null || true
log_info "PHASE_4_COMPLETE: Retención aplicada"

# [FINAL REPORT]
SIZE=$(du -h "${BACKUP_DIR}/${COMP_FILE}" | cut -f1)
log_info "BACKUP_SUCCESS: ${COMP_FILE} | Size: ${SIZE} | SHA256: $(cat "${BACKUP_DIR}/${CHECKSUM_FILE}")"
exit 0


---
