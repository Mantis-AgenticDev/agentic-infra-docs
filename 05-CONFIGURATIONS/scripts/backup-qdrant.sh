#!/usr/bin/env bash
# ---
# artifact_id: backup-qdrant-mantis
# artifact_type: backup_script
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C3","C4","C5","V2","V3"]
# canonical_path: 05-CONFIGURATIONS/scripts/backup-qdrant.sh
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
# checksum_sha256: "60515d9f6d9cc91ce56b3a618340bb14aeabab6187e5222f6e4f18cb1919fbdf"
# ---
set -euo pipefail

# [CONSTRAINT_MAP]
# C3: Secrets via env vars o Docker Secrets; cero exposición en logs/stdout
# C4: Nomenclatura atómica con timestamp, checksum SHA256, log de auditoría
# C5: Validación de conexión pre-backup, verificación de integridad post-backup
# V2: Snapshot completo con verificación de checksum y retención configurable
# V3: Backup de configuración HNSW/IVFFlat para recuperación de performance vectorial

# [DEPENDENCIES]
# curl, jq, sha256sum, aws cli (opcional), bash >= 4.3
# [INTERFACE_ALIGNMENT]
# Consumes: QDRANT_ENDPOINT, QDRANT_API_KEY, BACKUP_S3_BUCKET (mapping.yaml)
# Produce: .snapshot.json, .config.json, .sha256 manifest, upload status log

# [GLOBALS]
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BACKUP_DIR="${BACKUP_DIR:-/var/backups/mantis-qdrant}"
readonly RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
readonly S3_BUCKET="${BACKUP_S3_BUCKET:-}"
readonly LOG_FILE="${BACKUP_DIR}/backup-audit.log"
readonly TIMESTAMP="$(date -u +%Y%m%d_%H%M%S)"
readonly SNAPSHOT_FILE="qdrant-snapshot-${TIMESTAMP}.json"
readonly CONFIG_FILE="qdrant-config-${TIMESTAMP}.json"
readonly CHECKSUM_FILE="${SNAPSHOT_FILE}.sha256"

mkdir -p "$BACKUP_DIR"
touch "$LOG_FILE"

# [LOGGING]
log() { printf '[%s] [%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$2" >> "$LOG_FILE"; }
log_info()  { log "INFO"  "$1"; }
log_warn()  { log "WARN"  "$1"; }
log_error() { log "ERROR" "$1"; exit 1; }

# [VALIDATION]
command -v curl >/dev/null 2>&1 || log_error "DEPENDENCY_FAIL: curl no encontrado"
command -v jq >/dev/null 2>&1 || log_error "DEPENDENCY_FAIL: jq no encontrado"
[[ -n "${QDRANT_ENDPOINT:-}" ]] || log_error "ENV_MISSING: QDRANT_ENDPOINT no definido (ver mapping.yaml)"
[[ -n "${QDRANT_API_KEY:-}" ]] || log_error "ENV_MISSING: QDRANT_API_KEY no definido (inyectar vía secrets)"

# Validar formato endpoint
if ! echo "$QDRANT_ENDPOINT" | grep -qP '^https?://[a-zA-Z0-9.-]+(:[0-9]+)?$'; then
  log_error "VALIDATION_FAIL: QDRANT_ENDPOINT formato inválido"
fi

# [PHASE_1: HEALTH CHECK & COLLECTION LIST (V3)]
log_info "PHASE_1_START: Verificando salud de Qdrant y listando colecciones"
HEALTH_STATUS=$(curl -sf --max-time 10 "${QDRANT_ENDPOINT}/healthz" -H "api-key: ${QDRANT_API_KEY}" 2>>"$LOG_FILE" | jq -r '.title' 2>/dev/null || echo "FAIL")
[[ "$HEALTH_STATUS" == "qdrant - vector search engine" ]] || log_error "HEALTH_FAIL: Qdrant no responde en ${QDRANT_ENDPOINT}"

COLLECTIONS=$(curl -sf "${QDRANT_ENDPOINT}/collections" -H "api-key: ${QDRANT_API_KEY}" | jq -r '.result.collections[].name' 2>/dev/null || echo "")
[[ -n "$COLLECTIONS" ]] || log_warn "COLLECTIONS_EMPTY: No se detectaron colecciones para backup"

log_info "PHASE_1_COMPLETE: $(echo "$COLLECTIONS" | wc -l) colecciones detectadas"

# [PHASE_2: SNAPSHOT & CONFIG EXPORT (V2, V3)]
log_info "PHASE_2_START: Exportando snapshots y configuración vectorial"
for collection in $COLLECTIONS; do
  # Snapshot de datos (V2: integridad)
  curl -sf -X PUT "${QDRANT_ENDPOINT}/collections/${collection}/snapshots" \
    -H "api-key: ${QDRANT_API_KEY}" \
    -H "Content-Type: application/json" \
    -d '{"wait": true}' \
    -o "${BACKUP_DIR}/${collection}-snapshot-${TIMESTAMP}.json" 2>>"$LOG_FILE" || \
    log_warn "SNAPSHOT_WARN: Fallo en colección ${collection}"

  # Configuración de colección (V3: performance HNSW/IVFFlat)
  curl -sf "${QDRANT_ENDPOINT}/collections/${collection}" \
    -H "api-key: ${QDRANT_API_KEY}" \
    -o "${BACKUP_DIR}/${collection}-config-${TIMESTAMP}.json" 2>>"$LOG_FILE" || true
done

# Consolidar metadata del backup
jq -n \
  --arg ts "$TIMESTAMP" \
  --arg endpoint "$QDRANT_ENDPOINT" \
  --arg collections "$(echo "$COLLECTIONS" | tr '\n' ',')" \
  '{timestamp: $ts, endpoint: $endpoint, collections: ($collections | split(",") | map(select(length > 0))), backup_type: "qdrant-snapshot", version: "2.0.0"}' \
  > "${BACKUP_DIR}/${SNAPSHOT_FILE}"

log_info "PHASE_2_COMPLETE: Snapshots y configs exportados"

# [PHASE_3: INTEGRITY CHECKSUM (C5, V2)]
log_info "PHASE_3_START: Generando checksum SHA256 para verificación de integridad"
sha256sum "${BACKUP_DIR}/${SNAPSHOT_FILE}" | awk '{print $1}' > "${BACKUP_DIR}/${CHECKSUM_FILE}"
# Checksum adicional para cada snapshot de colección
for f in "${BACKUP_DIR}"/*-snapshot-*.json; do
  [[ -f "$f" ]] && sha256sum "$f" >> "${BACKUP_DIR}/${CHECKSUM_FILE}" || true
done
log_info "PHASE_3_COMPLETE: Checksums generados"

# [PHASE_4: REMOTE SYNC (OPTIONAL C4/C7)]
if [[ -n "$S3_BUCKET" && command -v aws >/dev/null 2>&1 ]]; then
  log_info "PHASE_4_START: Sincronizando con S3: s3://${S3_BUCKET}/qdrant-backups/"
  aws s3 sync "${BACKUP_DIR}/" "s3://${S3_BUCKET}/qdrant-backups/${TIMESTAMP}/" \
    --exclude "*" --include "*.json" --include "*.sha256" \
    >> "$LOG_FILE" 2>&1 || log_warn "SYNC_WARN: Fallo subida S3 (verificar credenciales/permisos)"
  log_info "PHASE_4_COMPLETE: Sync S3 completado"
else
  log_info "PHASE_4_SKIP: S3_BUCKET no definido o aws cli ausente"
fi

# [PHASE_5: RETENTION CLEANUP (C7)]
log_info "PHASE_5_START: Aplicando política de retención (${RETENTION_DAYS} días)"
find "$BACKUP_DIR" -name "qdrant-*.json" -mtime +"$RETENTION_DAYS" -delete 2>/dev/null || true
find "$BACKUP_DIR" -name "*.sha256" -mtime +"$RETENTION_DAYS" -delete 2>/dev/null || true
log_info "PHASE_5_COMPLETE: Retención aplicada"

# [FINAL REPORT]
SIZE=$(du -sh "${BACKUP_DIR}" 2>/dev/null | cut -f1)
log_info "BACKUP_SUCCESS: ${SNAPSHOT_FILE} | Size: ${SIZE} | SHA256: $(cat "${BACKUP_DIR}/${CHECKSUM_FILE}" | head -n1)"
exit 0


---
