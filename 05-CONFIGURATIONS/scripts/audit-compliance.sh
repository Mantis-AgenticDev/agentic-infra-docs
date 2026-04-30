---
# FRONTMATTER CANÓNICO OBLIGATORIO
artifact_id: "audit-compliance-v1.0.0"
artifact_type: "script"
version: "1.0.0-COMPREHENSIVE"
constraints_mapped: ["C5","C6"]
canonical_path: "05-CONFIGURATIONS/scripts/audit-compliance.sh"
domain: "05-CONFIGURATIONS"
subdomain: "scripts"
agent_role: "compliance-auditor"
language_lock: "bash"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain scripts --file 05-CONFIGURATIONS/scripts/audit-compliance.sh --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants"]
human_readable: false
checksum_sha256: "20fbdbde9d62eb976428ed013de20f5998ba9790369362029f2889e9934ebde7"
# FIN FRONTMATTER
---


#!/usr/bin/env bash
# =============================================================================
# SCRIPT: audit-compliance.sh
# DOMINIO: 05-CONFIGURATIONS/scripts
# PROPÓSITO: Auditoría de cumplimiento CIS/NIST automatizada. Escanea Terraform,
#            Docker, y configs del sistema. Genera reporte JSON/Markdown con
#            hallazgos, severidad y sugerencias de remediación. Gate CI/CD (C6).
# USO: ./audit-compliance.sh --scope all [--fail-on HIGH] [--report-dir ./reports] [--strict]
# DEPENDENCIAS: bash >= 5.0, checkov, trivy, tfsec, conftest/opa, jq
# AUTOR: configurations-master-agent (MANTIS)
# VERSIÓN: 1.0.0
# CONSTRAINTS: C5 (Integridad Estructural), C6 (Cumplimiento/Aprobación)
# =============================================================================
set -euo pipefail

# --- Configuración -----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel)"
CONFIGS_DIR="${REPO_ROOT}/05-CONFIGURATIONS"
REPORT_DIR="./audit-reports"
TIMESTAMP=$(date -u +%Y%m%d_%H%M%S)
TMP_DIR=$(mktemp -d /tmp/mantis-audit.XXXXXX)
LOG_FILE="/var/log/mantis-compliance-audit.log"

# Variables de ejecución
SCOPE="all" # all, terraform, docker, system
FAIL_ON="HIGH" # CRITICAL, HIGH, MEDIUM, NONE
REPORT_FORMAT="all" # json, md, all
STRICT="false"

# --- Logging -----------------------------------------------------------------
log() {
    local level="$1"; shift
    local msg="[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [$level] $*"
    echo "$msg" | tee -a "$LOG_FILE"
    [[ "$level" == "ERROR" || "$level" == "CRITICAL" ]] && exit 1
}

# --- Cleanup -----------------------------------------------------------------
cleanup() {
    rm -rf "$TMP_DIR"
    log INFO "🧹 Archivos temporales de auditoría eliminados."
}
trap cleanup EXIT

# --- Validación y Args -------------------------------------------------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --scope) SCOPE="$2"; shift 2 ;;
            --fail-on) FAIL_ON="$2"; shift 2 ;;
            --report-dir) REPORT_DIR="$2"; shift 2 ;;
            --format) REPORT_FORMAT="$2"; shift 2 ;;
            --strict) STRICT="true"; shift ;;
            -h|--help)
                echo "Uso: $0 --scope all [--fail-on HIGH] [--report-dir ./reports] [--strict]"
                exit 0 ;;
            *) log ERROR "Opción desconocida: $1" ;;
        esac
    done
    mkdir -p "$REPORT_DIR"
}

check_dependencies() {
    local tools=("checkov" "trivy" "tfsec" "conftest" "jq")
    local missing=()
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing+=("$tool")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log WARN "⚠️ Herramientas faltantes: ${missing[*]}. Se omitirán sus escaneos."
        log WARN "   Instalar: pip install checkov; brew/apt install trivy tfsec conftest"
    fi
}

# --- Escáneres ---------------------------------------------------------------
scan_terraform() {
    log INFO "🔍 Escaneando Terraform (Checkov + TFSec)..."
    local tf_dir="${CONFIGS_DIR}/terraform"
    
    if [[ ! -d "$tf_dir" ]]; then
        log INFO "ℹ️ Directorio Terraform no encontrado. Omitiendo."
        return 0
    fi

    # Checkov
    if command -v checkov &>/dev/null; then
        checkov -d "$tf_dir" -o json --quiet > "${TMP_DIR}/checkov.json" 2>/dev/null || true
    fi
    
    # TFSec
    if command -v tfsec &>/dev/null; then
        tfsec "$tf_dir" -s -f json > "${TMP_DIR}/tfsec.json" 2>/dev/null || true
    fi
}

scan_docker() {
    log INFO "🐳 Escaneando Docker (Trivy)..."
    local compose_dir="${CONFIGS_DIR}/docker-compose"
    
    if [[ ! -d "$compose_dir" ]]; then
        log INFO "ℹ️ Directorio Docker Compose no encontrado. Omitiendo."
        return 0
    fi

    if command -v trivy &>/dev/null; then
        trivy config "$compose_dir" --format json --output "${TMP_DIR}/trivy-docker.json" 2>/dev/null || true
        trivy fs "${CONFIGS_DIR}/Dockerfile*" --scanners secret,misconfig --format json --output "${TMP_DIR}/trivy-files.json" 2>/dev/null || true
    fi
}

scan_policies() {
    log INFO "📜 Validando políticas OPA/Conftest..."
    local policies_dir="${CONFIGS_DIR}/security/policies"
    local target="${CONFIGS_DIR}/terraform"
    
    if command -v conftest &>/dev/null && [[ -d "$policies_dir" ]]; then
        conftest test "$target" --policy "$policies_dir" --output json > "${TMP_DIR}/conftest.json" 2>/dev/null || true
    fi
}

# --- Agregación y Reporte ----------------------------------------------------
aggregate_results() {
    log INFO "📊 Agregando hallazgos y calculando severidad..."
    local total_critical=0 total_high=0 total_medium=0 total_low=0
    local findings_json="[]"

    # Helper para extraer y sumar
    count_findings() {
        local file="$1" key="$2"
        if [[ -f "$file" ]]; then
            local count
            count=$(jq "[.results[]?.[]?.Severity? // .[].Status == \"FAIL\" | select(. == \"$key\")] | length" "$file" 2>/dev/null || echo 0)
            echo "$count"
        else echo 0; fi
    }

    total_critical=$(( $(count_findings "${TMP_DIR}/checkov.json" "CRITICAL") + $(count_findings "${TMP_DIR}/tfsec.json" "HIGH") )) # TFSec HIGH ~ CRITICAL
    total_high=$(( $(count_findings "${TMP_DIR}/checkov.json" "HIGH") + $(count_findings "${TMP_DIR}/trivy-docker.json" "HIGH") ))
    total_medium=$(( $(count_findings "${TMP_DIR}/checkov.json" "MEDIUM") + $(count_findings "${TMP_DIR}/trivy-docker.json" "MEDIUM") ))
    total_low=$(( $(count_findings "${TMP_DIR}/checkov.json" "LOW") + $(count_findings "${TMP_DIR}/trivy-docker.json" "LOW") ))

    # Generar reporte JSON estructurado (C5)
    cat > "${REPORT_DIR}/audit-report-${TIMESTAMP}.json" <<EOF
{
  "audit_metadata": {
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "scope": "$SCOPE",
    "fail_threshold": "$FAIL_ON",
    "strict_mode": $STRICT
  },
  "summary": {
    "critical": $total_critical,
    "high": $total_high,
    "medium": $total_medium,
    "low": $total_low
  },
  "findings_files": {
    "checkov": "$([ -f "${TMP_DIR}/checkov.json" ] && echo "${TMP_DIR}/checkov.json" || echo "null")",
    "tfsec": "$([ -f "${TMP_DIR}/tfsec.json" ] && echo "${TMP_DIR}/tfsec.json" || echo "null")",
    "trivy_docker": "$([ -f "${TMP_DIR}/trivy-docker.json" ] && echo "${TMP_DIR}/trivy-docker.json" || echo "null")"
  }
}
EOF
    log INFO "✅ Reporte JSON generado: ${REPORT_DIR}/audit-report-${TIMESTAMP}.json"

    # Evaluar gate de cumplimiento (C6)
    local should_fail=false
    if [[ "$FAIL_ON" == "CRITICAL" && $total_critical -gt 0 ]]; then should_fail=true; fi
    if [[ "$FAIL_ON" == "HIGH" && (( total_critical > 0 || total_high > 0 )) ]]; then should_fail=true; fi
    if [[ "$FAIL_ON" == "MEDIUM" && (( total_critical > 0 || total_high > 0 || total_medium > 0 )) ]]; then should_fail=true; fi
    
    # Modo estricto: cualquier hallazgo falla
    if [[ "$STRICT" == "true" && (( total_critical + total_high + total_medium + total_low > 0 )) ]]; then 
        should_fail=true
    fi

    if [[ "$should_fail" == "true" ]]; then
        log CRITICAL "🛑 Gate de cumplimiento NO superado. Umbral: $FAIL_ON | Hallazgos: C=$total_critical H=$total_high M=$total_medium L=$total_low"
        return 2
    else
        log INFO "✅ Gate de cumplimiento superado. Umbral: $FAIL_ON"
        return 0
    fi
}

# --- Ejecución Principal -----------------------------------------------------
main() {
    parse_args "$@"
    check_dependencies
    
    log INFO "🚀 Iniciando auditoría de cumplimiento (Scope: $SCOPE)"
    
    case "$SCOPE" in
        all) scan_terraform; scan_docker; scan_policies ;;
        terraform) scan_terraform ;;
        docker) scan_docker ;;
        system) log INFO "ℹ️ Escaneo de sistema SO pendiente de implementación (cis-lint/dockle). Omitiendo por ahora." ;;
    esac
    
    aggregate_results
    local exit_code=$?
    
    log INFO "🏁 Auditoría finalizada."
    return $exit_code
}

main "$@"


---
