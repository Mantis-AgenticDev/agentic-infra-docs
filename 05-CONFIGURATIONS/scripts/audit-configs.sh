---
# FRONTMATTER CANÓNICO OBLIGATORIO
artifact_id: "audit-configs-v1.0.0"
artifact_type: "script"
version: "1.0.0-COMPREHENSIVE"
constraints_mapped: ["C2","C4","C5"]
canonical_path: "05-CONFIGURATIONS/scripts/audit-configs.sh"
domain: "05-CONFIGURATIONS"
subdomain: "scripts"
agent_role: "config-auditor"
language_lock: "bash"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain scripts --file 05-CONFIGURATIONS/scripts/audit-configs.sh --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants", "devops_team"]
human_readable: true
checksum_sha256: "29d6efe44a8d31f35214df21771cf800dbe8f735a6c0bb923331b91c2a074d6c"
# FIN FRONTMATTER
---

#!/usr/bin/env bash
# =============================================================================
# SCRIPT: audit-configs.sh
# DOMINIO: 05-CONFIGURATIONS/scripts
# PROPÓSITO: Auditoría automática de configuraciones contra interface-spec.yaml
#            y estándares MANTIS. Detecta desviaciones, valida constraints,
#            ejecuta validadores nativos y genera reporte JSON estructurado.
# USO: ./audit-configs.sh --scope all [--spec interface-spec.yaml] [--report-dir ./reports] [--strict]
# DEPENDENCIAS: bash >= 5.0, yq, jq, terraform, docker compose, shellcheck, yamllint
# AUTOR: configurations-master-agent (MANTIS)
# VERSIÓN: 1.0.0
# CONSTRAINTS: C2 (Consistencia IaC), C4 (Trazabilidad), C5 (Validación Estructural)
# =============================================================================
set -euo pipefail

# --- Configuración -----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"
CONFIGS_DIR="${REPO_ROOT}/05-CONFIGURATIONS"
SPEC_FILE="${CONFIGS_DIR}/interface-spec.yaml"
REPORT_DIR="${CONFIGS_DIR}/reports/audit"
TIMESTAMP=$(date -u +%Y%m%d_%H%M%S)
REPORT_FILE="${REPORT_DIR}/config-audit-${TIMESTAMP}.json"
LOG_FILE="/var/log/mantis-config-audit.log"

# Variables de ejecución
SCOPE="all" # all, terraform, docker, env, interface
STRICT="false"
EXIT_CODE=0

# --- Logging -----------------------------------------------------------------
log() {
    local level="$1"; shift
    local msg="[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [$level] $*"
    echo "$msg" | tee -a "$LOG_FILE"
}

# --- Validación y Args -------------------------------------------------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --scope) SCOPE="$2"; shift 2 ;;
            --spec) SPEC_FILE="$2"; shift 2 ;;
            --report-dir) REPORT_DIR="$2"; shift 2 ;;
            --strict) STRICT="true"; shift ;;
            -h|--help)
                echo "Uso: $0 --scope all [--spec interface-spec.yaml] [--report-dir ./reports] [--strict]"
                exit 0 ;;
            *) log ERROR "Opción desconocida: $1" ;;
        esac
    done
    mkdir -p "$REPORT_DIR"
    [[ ! -f "$SPEC_FILE" ]] && log WARN "⚠️ interface-spec.yaml no encontrado en $SPEC_FILE. Se omitirán validaciones cruzadas."
}

# --- Validadores Nativos -----------------------------------------------------
run_terraform_checks() {
    log INFO "🔍 Auditando Terraform (C2/C5)..."
    local tf_dir="${CONFIGS_DIR}/terraform"
    local findings=0
    
    if [[ -d "$tf_dir" ]]; then
        cd "$tf_dir"
        if terraform fmt -check -recursive >/dev/null 2>&1; then
            log INFO "✅ Terraform fmt: consistente"
        else
            log WARN "⚠️ Terraform fmt: inconsistencias detectadas. Ejecutar: terraform fmt -recursive"
            ((findings++))
        fi
        
        if terraform validate >/dev/null 2>&1; then
            log INFO "✅ Terraform validate: válido"
        else
            log ERROR "❌ Terraform validate: falló. Revisar sintaxis HCL."
            ((findings++))
            [[ "$STRICT" == "true" ]] && EXIT_CODE=1
        fi
        cd "$REPO_ROOT"
    fi
    echo "$findings"
}

run_docker_checks() {
    log INFO "🔍 Auditando Docker Compose (C2/C5)..."
    local compose_dir="${CONFIGS_DIR}/docker-compose"
    local findings=0
    
    if [[ -d "$compose_dir" ]]; then
        for f in "${compose_dir}"/*.yml "${compose_dir}"/*.yaml; do
            [[ -f "$f" ]] || continue
            if docker compose -f "$f" config --quiet >/dev/null 2>&1; then
                log INFO "✅ $(basename "$f"): sintaxis válida"
            else
                log WARN "⚠️ $(basename "$f"): error de sintaxis. Ejecutar: docker compose -f $f config"
                ((findings++))
            fi
        done
    fi
    echo "$findings"
}

run_interface_cross_check() {
    log INFO "🔍 Auditoría cruzada vs interface-spec.yaml (C4/C5)..."
    local findings=0
    
    if [[ ! -f "$SPEC_FILE" ]]; then
        log INFO "ℹ️ Archivo de interfaz no especificado. Omitiendo cruce."
        echo "0"
        return
    fi
    
    # Extraer variables esperadas del spec
    local expected_vars
    expected_vars=$(yq '.global_variables | keys | join(" ")' "$SPEC_FILE" 2>/dev/null || echo "")
    
    # Buscar variables hardcodeadas o no mapeadas en docker-compose
    if [[ -n "$expected_vars" ]]; then
        for var in $expected_vars; do
            if grep -rq "${var}=" "${CONFIGS_DIR}/docker-compose/" 2>/dev/null; then
                # Verificar si usa secret_file o env_file (correcto) vs hardcode directo (incorrecto)
                local hardcode_count
                hardcode_count=$(grep -r "${var}=[^/]" "${CONFIGS_DIR}/docker-compose/" 2>/dev/null | grep -v "_FILE=" | wc -l)
                if (( hardcode_count > 0 )); then
                    log WARN "⚠️ Variable '$var' hardcodeada en docker-compose. Usar secrets o env_file."
                    ((findings++))
                fi
            fi
        done
    fi
    echo "$findings"
}

# --- Generación de Reporte ---------------------------------------------------
generate_report() {
    local tf_issues="$1" docker_issues="$2" interface_issues="$3"
    local total_issues=$((tf_issues + docker_issues + interface_issues))
    local status="PASS"
    
    if (( total_issues > 0 )); then
        status="WARN"
        [[ "$STRICT" == "true" && $EXIT_CODE -eq 1 ]] && status="FAIL"
    fi
    
    jq -n \
      --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --arg scope "$SCOPE" \
      --argjson tf "$tf_issues" \
      --argjson docker "$docker_issues" \
      --argjson interface "$interface_issues" \
      --argjson total "$total_issues" \
      --arg status "$status" \
      --arg strict "$STRICT" \
      '{
        metadata: { timestamp: $ts, scope: $scope, strict_mode: ($strict == "true") },
        summary: { terraform_findings: $tf, docker_findings: $docker, interface_drift: $interface, total: $total, status: $status },
        recommendations: [
          "Ejecutar terraform fmt -recursive para alinear formato HCL",
          "Usar secrets o _FILE env vars para credenciales en Docker",
          "Validar interface-spec.yaml con orchestrator-engine.sh --strict",
          "Integrar este script como paso pre-commit en CI/CD"
        ]
      }' > "$REPORT_FILE"
      
    log INFO "📄 Reporte generado: $REPORT_FILE"
}

# --- Ejecución Principal -----------------------------------------------------
main() {
    parse_args "$@"
    log INFO "🚀 Iniciando auditoría de configuraciones (Scope: $SCOPE)"
    
    local tf_issues=0 docker_issues=0 interface_issues=0
    
    case "$SCOPE" in
        all|terraform) tf_issues=$(run_terraform_checks) ;;
        all|docker) docker_issues=$(run_docker_checks) ;;
        all|interface) interface_issues=$(run_interface_cross_check) ;;
    esac
    
    generate_report "$tf_issues" "$docker_issues" "$interface_issues"
    
    if [[ "$status" == "FAIL" ]]; then
        log ERROR "🛑 Auditoría fallida en modo estricto. Revisar reporte y corregir antes de merge."
    else
        log INFO "✅ Auditoría completada. Total hallazgos: $((tf_issues + docker_issues + interface_issues))"
    fi
    exit $EXIT_CODE
}

main "$@"


---
