---
# FRONTMATTER CANÓNICO OBLIGATORIO
artifact_id: "clean-old-releases-v1.0.0"
artifact_type: "script"
version: "1.0.0-COMPREHENSIVE"
constraints_mapped: ["C1","C4","C7"]
canonical_path: "05-CONFIGURATIONS/scripts/clean-old-releases.sh"
domain: "05-CONFIGURATIONS"
subdomain: "scripts"
agent_role: "release-cleanup"
language_lock: "bash"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain scripts --file 05-CONFIGURATIONS/scripts/clean-old-releases.sh --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants", "release_team"]
human_readable: true
checksum_sha256: "cebaa5e4d307ab41286f8b05216b5f72be5d3c88aaec1af5d69a2d91734af9c5"
# FIN FRONTMATTER
---

#!/usr/bin/env bash
# =============================================================================
# SCRIPT: clean-old-releases.sh
# DOMINIO: 05-CONFIGURATIONS/scripts
# PROPÓSITO: Limpieza programada de releases antiguos: retención configurable,
#            verificación de checksums pre-eliminación, registro de auditoría
#            y modo --dry-run para validación segura.
# USO: ./clean-old-releases.sh --retention 90 [--dry-run] [--env prod] [--confirm]
# DEPENDENCIAS: bash >= 5.0, find, sha256sum, jq, date
# AUTOR: configurations-master-agent (MANTIS)
# VERSIÓN: 1.0.0
# CONSTRAINTS: C1 (Inmutabilidad versionada), C4 (Trazabilidad), C7 (Resiliencia)
# =============================================================================
set -euo pipefail

# --- Configuración -----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"
OUTPUT_DIR="${REPO_ROOT}/05-CONFIGURATIONS/output/releases"
LOG_FILE="/var/log/mantis-cleanup.log"
AUDIT_LOG="${REPO_ROOT}/08-LOGS/cleanup-audit/$(date +%Y%m%d).jsonl"

# Variables de ejecución
RETENTION_DAYS=90
DRY_RUN="false"
CONFIRMED="false"
ENV_FILTER=""

# --- Logging -----------------------------------------------------------------
log() {
    local level="$1"; shift
    local msg="[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [$level] $*"
    echo "$msg" | tee -a "$LOG_FILE"
    [[ "$level" == "ERROR" ]] && exit 1
}

# --- Validación y Args -------------------------------------------------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --retention) RETENTION_DAYS="$2"; shift 2 ;;
            --dry-run) DRY_RUN="true"; shift ;;
            --env) ENV_FILTER="$2"; shift 2 ;;
            --confirm) CONFIRMED="true"; shift ;;
            -h|--help)
                echo "Uso: $0 --retention <days> [--dry-run] [--env prod] [--confirm]"
                exit 0 ;;
            *) log ERROR "Opción desconocida: $1" ;;
        esac
    done

    if [[ ! -d "$OUTPUT_DIR" ]]; then
        log WARN "⚠️ Directorio de releases no encontrado: $OUTPUT_DIR. Creando..."
        mkdir -p "$OUTPUT_DIR"
    fi

    mkdir -p "$(dirname "$AUDIT_LOG")"
}

# --- Funciones de Limpieza ---------------------------------------------------
get_old_releases() {
    local cutoff_date
    cutoff_date=$(date -d "-${RETENTION_DAYS} days" +%Y%m%d 2>/dev/null || date -v-"${RETENTION_DAYS"d +%Y%m%d 2>/dev/null)
    
    find "$OUTPUT_DIR" -mindepth 1 -maxdepth 1 -type d -name "v*" | while read -r release_dir; do
        local release_name
        release_name=$(basename "$release_dir")
        local release_date
        release_date=$(echo "$release_name" | grep -oP 'v\d+\.\d+\.\d+' | sed 's/v//' | tr '.' '')
        
        # Si no se puede parsear fecha, usar fecha de modificación del directorio
        if [[ -z "$release_date" || ${#release_date} -lt 6 ]]; then
            release_date=$(stat -c %Y "$release_dir" 2>/dev/null | xargs -I{} date -d @{} +%Y%m%d 2>/dev/null || echo "000000")
        fi
        
        if [[ "$release_date" < "$cutoff_date" ]]; then
            echo "$release_dir"
        fi
    done
}

verify_checksums() {
    local release_dir="$1"
    local failed=0
    
    for checksum_file in "$release_dir"/*.sha256; do
        if [[ -f "$checksum_file" ]]; then
            if ! sha256sum -c "$checksum_file" --quiet 2>/dev/null; then
                log WARN "⚠️ Checksum inválido: $(basename "$checksum_file")"
                ((failed++))
            fi
        fi
    done
    
    return $failed
}

audit_removal() {
    local release_dir="$1"
    local reason="$2"
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    jq -n --arg dir "$release_dir" \
          --arg reason "$reason" \
          --arg ts "$timestamp" \
          --arg env "${ENV_FILTER:-all}" \
          '{timestamp: $ts, action: "cleanup", release: $dir, reason: $reason, environment: $env, dry_run: '"$DRY_RUN"'}' \
          >> "$AUDIT_LOG"
}

cleanup_release() {
    local release_dir="$1"
    local release_name
    release_name=$(basename "$release_dir")
    
    log INFO "🔍 Verificando integridad de $release_name..."
    
    if ! verify_checksums "$release_dir"; then
        log WARN "⚠️ Checksums inválidos en $release_name. Marcando para revisión manual."
        audit_removal "$release_dir" "checksum_failure"
        return 1
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log INFO "[DRY-RUN] Eliminaría: $release_dir"
        audit_removal "$release_dir" "dry_run_cleanup"
        return 0
    fi
    
    log INFO "🗑️ Eliminando release antiguo: $release_name"
    rm -rf "$release_dir"
    audit_removal "$release_dir" "retention_policy_cleanup"
    log INFO "✅ $release_name eliminado exitosamente."
}

# --- Ejecución Principal -----------------------------------------------------
main() {
    parse_args "$@"
    
    log INFO "🚀 Iniciando limpieza de releases (Retención: ${RETENTION_DAYS}d, Env: ${ENV_FILTER:-all})"
    
    local old_releases
    mapfile -t old_releases < <(get_old_releases)
    
    if [[ ${#old_releases[@]} -eq 0 ]]; then
        log INFO "✅ No hay releases antiguos que limpiar."
        return 0
    fi
    
    log INFO "📋 Releases candidatos para limpieza: ${#old_releases[@]}"
    for r in "${old_releases[@]}"; do log INFO "   - $(basename "$r")"; done
    
    if [[ "$DRY_RUN" == "false" && "$CONFIRMED" == "false" ]]; then
        read -rp "¿Confirmar eliminación de ${#old_releases[@]} releases? [y/N]: " ans
        [[ "$ans" =~ ^[Yy]$ ]] || { log INFO "🚫 Limpieza abortada por usuario."; exit 0; }
    fi
    
    local cleaned=0 failed=0
    for release in "${old_releases[@]}"; do
        if cleanup_release "$release"; then
            ((cleaned++))
        else
            ((failed++))
        fi
    done
    
    log INFO "🏁 Limpieza finalizada: $cleaned eliminados, $failed con errores."
    log INFO "📄 Registro de auditoría: $AUDIT_LOG"
}

main "$@"


---
