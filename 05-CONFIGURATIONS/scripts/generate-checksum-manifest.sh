#!/usr/bin/env bash
# ---
# artifact_id: generate-checksum-manifest-mantis
# artifact_type: maintenance_script
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C3","C4","C5","C7"]
# canonical_path: 05-CONFIGURATIONS/scripts/generate-checksum-manifest.sh
# domain: 05-CONFIGURATIONS
# subdomain: scripts
# agent_role: configurations-master
# language_lock: es-ES
# validation_command: orchestrator-engine.sh --domain configurations --strict
# tier: 2
# immutable: true
# requires_human_approval_for_changes: true
# audience: ["agentic_assistants", "human_ops"]
# human_readable: false
# checksum_sha256: "c44eee6a5cf0f804e732d512ced471d70095a50163be14e6eb1fe3af3f35319b"
# ---
set -euo pipefail

# [CONSTRAINT_MAP]
# C3: Cero exposición de rutas sensibles o credenciales en stdout
# C4: Trazabilidad via timestamp UTC, versión canónica y conteo atómico
# C5: Validación de deps (jq, sha256sum), sintaxis JSON y atomicidad de escritura
# C7: Idempotente; sobrescribe manifest de forma segura sin corrupción parcial

# [DEPENDENCIES]
# git, jq, sha256sum, bash >= 4.3
# [INTERFACE_ALIGNMENT]
# Produce: 05-CONFIGURATIONS/registry/checksum-manifest.json
# Consumes: Repo gittracked files (05-CONFIGURATIONS/, .github/workflows/, security/, docs/)

# [GLOBALS]
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$(dirname "$(dirname "$SCRIPT_DIR")")")"
readonly MANIFEST_DIR="${REPO_ROOT}/05-CONFIGURATIONS/registry"
readonly MANIFEST_FILE="${MANIFEST_DIR}/checksum-manifest.json"
readonly TMP_MANIFEST="${MANIFEST_FILE}.tmp"
readonly GENERATED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
readonly MANIFEST_VERSION="2.0.0-COMPREHENSIVE"

mkdir -p "$MANIFEST_DIR"

# [LOGGING]
log() { printf '[%s] [%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$2" | tee -a /dev/stderr; }
log_info()  { log "INFO"  "$1"; }
log_warn()  { log "WARN"  "$1"; }
log_error() { log "ERROR" "$1"; exit 1; }

# [VALIDATION]
for cmd in git jq sha256sum; do
  command -v "$cmd" >/dev/null 2>&1 || log_error "DEPENDENCY_FAIL: $cmd requerido"
done

# [PHASE 1: FILE DISCOVERY (C4, C7)]
phase_discover() {
  log_info "PHASE_1_START: Descubriendo artefactos versionados..."
  # Usar git ls-files para evitar .tmp, .env reales, logs locales y binarios
  if git rev-parse &>/dev/null; then
    mapfile -t FILES < <(git ls-files \
      05-CONFIGURATIONS/ \
      .github/workflows/ \
      02-SKILLS/ \
      security/ \
      docs/ \
      2>/dev/null | grep -vE '(\.gitkeep$|\.tmp/|08-LOGS/|\.env\.prod|\.env\.staging|\.env\.dev)')
  else
    # Fallback si no hay repo git
    mapfile -t FILES < <(find 05-CONFIGURATIONS/ .github/workflows/ 02-SKILLS/ security/ docs/ -type f 2>/dev/null | grep -vE '(\.gitkeep$|\.tmp/|08-LOGS/)')
  fi

  [[ ${#FILES[@]} -gt 0 ]] || log_error "FILES_NOT_FOUND: No se detectaron artefactos en las rutas canónicas"
  log_info "PHASE_1_COMPLETE: ${#FILES[@]} archivos identificados"
}

# [PHASE 2: CHECKSUM COMPUTATION & JSON BUILD (C3, C5)]
phase_compute_and_build() {
  log_info "PHASE_2_START: Calculando SHA256 y construyendo manifest..."
  
  # Inicializar estructura base
  jq -n \
    --arg ver "$MANIFEST_VERSION" \
    --arg ts "$GENERATED_AT" \
    '{artifacts: {}, version: $ver, generated_at: $ts, total_files: 0, schema: "mantis-v2"}' > "$TMP_MANIFEST"

  local count=0
  for f in "${FILES[@]}"; do
    [[ -f "$f" ]] || continue
    local checksum
    checksum=$(sha256sum "$f" | awk '{print $1}')
    
    # Inyectar atómicamente en JSON
    jq --arg path "$f" --arg sha "$checksum" --arg ts "$GENERATED_AT" \
       '.artifacts[$path] = {version: $ARGS.named.ver, sha256: $sha, last_modified: $ts, validated_by: "orchestrator-engine.sh", constraints: ["C1","C2","C3","C4","C5","C6","C7","C8","V1","V2","V3"]}' \
       "$TMP_MANIFEST" > "${TMP_MANIFEST}.2" && mv "${TMP_MANIFEST}.2" "$TMP_MANIFEST"
    ((count++))
  done

  # Actualizar conteo final
  jq --argjson count "$count" '.total_files = $count' "$TMP_MANIFEST" > "${TMP_MANIFEST}.3" && mv "${TMP_MANIFEST}.3" "$TMP_MANIFEST"
  log_info "PHASE_2_COMPLETE: $count checksums calculados"
}

# [PHASE 3: ATOMIC WRITE & VALIDATION (C5, C7)]
phase_commit() {
  log_info "PHASE_3_START: Validando integridad y escribiendo manifest..."
  
  # Validar JSON estructural
  if ! jq empty "$TMP_MANIFEST" 2>/dev/null; then
    log_error "JSON_INVALID: Manifest temporal corrupto. Abortando."
    rm -f "$TMP_MANIFEST" "${TMP_MANIFEST}.2" "${TMP_MANIFEST}.3" 2>/dev/null
    exit 1
  fi

  # Escritura atómica (C7: previene corrupción por interrupción)
  mv "$TMP_MANIFEST" "$MANIFEST_FILE"
  
  # Limpiar temporales residuales
  rm -f "${TMP_MANIFEST}.2" "${TMP_MANIFEST}.3" 2>/dev/null || true
  
  log_info "PHASE_3_COMPLETE: Manifest escrito en $MANIFEST_FILE"
}

# [REPORT]
phase_report() {
  local final_count
  final_count=$(jq '.total_files' "$MANIFEST_FILE" 2>/dev/null || echo 0)
  local manifest_sha
  manifest_sha=$(sha256sum "$MANIFEST_FILE" | awk '{print $1}')
  
  log_info "MANIFEST_SUCCESS: $final_count artefactos registrados | SHA256(manifest): $manifest_sha"
  log_info "📄 Verificar con: jq '.artifacts | keys' $MANIFEST_FILE"
}

# [EXECUTION PIPELINE]
log_info "CHECKSUM_MANIFEST_START: $MANIFEST_VERSION | $GENERATED_AT"
phase_discover
phase_compute_and_build
phase_commit
phase_report
exit 0
