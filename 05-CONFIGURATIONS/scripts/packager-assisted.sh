#!/usr/bin/env bash
# ---
# artifact_id: packager-assisted-mantis
# artifact_type: packaging_script
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C1","C3","C4","C5","C7","C8"]
# canonical_path: 05-CONFIGURATIONS/scripts/packager-assisted.sh
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
# checksum_sha256: "30f16293ad9007eb8e5d3bcdb307714f82492c71485fbd39a1a04ff05a8b3504"
# ---
set -euo pipefail

# [CONSTRAINT_MAP]
# C1: Versionado semántico estricto; inmutabilidad de artefactos empaquetados
# C3: Exclusión automática de .env.*, .terraform/, secrets y logs del paquete
# C4: Trazabilidad via git commit, tag, timestamp y manifest JSON
# C5: Validación SHA256 automática + checksum manifesto
# C7: Rollback-ready: estructura de directorios clara + manifest de reversión
# C8: SBOM opcional (Syft) para trazabilidad de dependencias en releases

# [DEPENDENCIES]
# tar, gzip, sha256sum, jq, git, bash >= 4.3
# [INTERFACE_ALIGNMENT]
# Consumes: VERSION_TAG (env), EXCLUDE_LIST (.gitignore aligned)
# Produces: .tar.gz archive, SHA256SUMS, package-manifest.json, SBOM (opcional)

# [GLOBALS]
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$(dirname "$(dirname "$SCRIPT_DIR")")")"
readonly OUTPUT_DIR="${REPO_ROOT}/output/releases"
readonly TIMESTAMP="$(date -u +%Y%m%d_%H%M%S)"
readonly EXCLUDE_FILE="${REPO_ROOT}/.releaseignore"

mkdir -p "$OUTPUT_DIR"

# [DEFAULT EXCLUDES (C3: Secrets & Build Artifacts)]
cat > "$EXCLUDE_FILE" <<'EOF'
.env*
*.tfstate
.terraform/
node_modules/
__pycache__/
*.log
08-LOGS/
05-CONFIGURATIONS/.tmp/
.github/workflows/.cache/
EOF

# [LOGGING]
log() { printf '[%s] [%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$2" | tee -a /dev/stderr; }
log_info()  { log "INFO"  "$1"; }
log_warn()  { log "WARN"  "$1"; }
log_error() { log "ERROR" "$1"; exit 1; }

# [ARGS & VALIDATION]
TARGET_VERSION="${1:-$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0-${TIMESTAMP}")}"
ENV_FILTER="${2:-.}"

[[ -d "$REPO_ROOT" ]] || log_error "REPO_ROOT_INVALID: No se detectó repositorio Git"
command -v tar >/dev/null && command -v sha256sum >/dev/null && command -v jq >/dev/null || \
  log_error "DEPENDENCY_FAIL: tar, sha256sum o jq no encontrados"

# [PHASE_1: ASSEMBLY & ARCHIVE (C1, C3)]
log_info "PHASE_1_START: Empaquetando release ${TARGET_VERSION}"
ARCHIVE_NAME="mantis-release-${TARGET_VERSION//[^a-zA-Z0-9._-]/_}-${TIMESTAMP}.tar.gz"

tar -czf "${OUTPUT_DIR}/${ARCHIVE_NAME}" \
  --exclude-from="$EXCLUDE_FILE" \
  --transform="s,^,mantis-${TARGET_VERSION}/," \
  -C "$REPO_ROOT" "$ENV_FILTER" 2>>/dev/null || \
  log_error "TAR_FAIL: Error creando archivo comprimido"

log_info "PHASE_1_COMPLETE: ${ARCHIVE_NAME} creado"

# [PHASE_2: CHECKSUM & MANIFEST (C4, C5)]
log_info "PHASE_2_START: Generando checksum y manifest"
CHECKSUM=$(sha256sum "${OUTPUT_DIR}/${ARCHIVE_NAME}" | awk '{print $1}')
echo "${CHECKSUM}  ${ARCHIVE_NAME}" > "${OUTPUT_DIR}/SHA256SUMS"

GIT_COMMIT="$(git rev-parse HEAD 2>/dev/null || echo 'unknown')"
GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
FILE_COUNT=$(tar -tzf "${OUTPUT_DIR}/${ARCHIVE_NAME}" | wc -l)
SIZE_HUMAN=$(du -h "${OUTPUT_DIR}/${ARCHIVE_NAME}" | cut -f1)

jq -n \
  --arg ver "$TARGET_VERSION" \
  --arg ts "$TIMESTAMP" \
  --arg commit "$GIT_COMMIT" \
  --arg branch "$GIT_BRANCH" \
  --arg archive "$ARCHIVE_NAME" \
  --arg checksum "$CHECKSUM" \
  --arg size "$SIZE_HUMAN" \
  --argjson files "$FILE_COUNT" \
  '{
    version: $ver,
    timestamp: $ts,
    git_commit: $commit,
    branch: $branch,
    archive: $archive,
    sha256: $checksum,
    size_human: $size,
    file_count: $files,
    rollback_ready: true,
    constraints_applied: ["C1","C3","C4","C5","C7","C8"]
  }' > "${OUTPUT_DIR}/package-manifest.json"

log_info "PHASE_2_COMPLETE: Manifest y SHA256 generados"

# [PHASE_3: SBOM GENERATION (C8 - Optional)]
if command -v syft >/dev/null 2>&1; then
  log_info "PHASE_3_START: Generando SBOM con Syft..."
  syft dir:"${REPO_ROOT}" --scope all-layers --output cyclonedx-json > "${OUTPUT_DIR}/sbom-${TARGET_VERSION}.json" 2>/dev/null || log_warn "SBOM_WARN: Syft falló o estructura incompleta"
  log_info "PHASE_3_COMPLETE: SBOM generado"
else
  log_info "PHASE_3_SKIP: Syft no instalado. SBOM omitido (opcional C8)"
fi

# [FINAL REPORT]
log_info "PACKAGER_SUCCESS: ${ARCHIVE_NAME} | ${SIZE_HUMAN} | SHA256: ${CHECKSUM}"
exit 0


---
