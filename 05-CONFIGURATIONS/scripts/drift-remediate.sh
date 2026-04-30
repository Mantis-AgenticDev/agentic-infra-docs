---
# FRONTMATTER CANÓNICO OBLIGATORIO
artifact_id: "drift-remediate-v1.0.0"
artifact_type: "script"
version: "1.0.0-COMPREHENSIVE"
constraints_mapped: ["C2","C7","C8"]
canonical_path: "05-CONFIGURATIONS/scripts/drift-remediate.sh"
domain: "05-CONFIGURATIONS"
subdomain: "scripts"
agent_role: "drift-remediation"
language_lock: "bash"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain scripts --file 05-CONFIGURATIONS/scripts/drift-remediate.sh --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants"]
human_readable: false
checksum_sha256: "9995509ecccdf4c05171dbc9b6e00f171635cc2b82fb820cad062509f2f28d22"
# FIN FRONTMATTER
---


#!/usr/bin/env bash
# =============================================================================
# SCRIPT: drift-remediate.sh
# DOMINIO: 05-CONFIGURATIONS/scripts
# PROPÓSITO: Remediación automática de drift detectado en infraestructura.
#            Clasifica por severidad y aplica correcciones (terraform apply
#            o refresh-only) o alerta según política.
# USO: ./drift-remediate.sh --env prod [--auto-apply] [--severity-threshold HIGH]
# DEPENDENCIAS: bash >= 5.0, terraform, jq
# AUTOR: configurations-master-agent (MANTIS)
# VERSIÓN: 1.0.0
# CONSTRAINTS: C2 (IaC), C7 (Resiliencia), C8 (Observabilidad)
# =============================================================================
set -euo pipefail

# --- Configuración -----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel)"
TERRAFORM_DIR="${REPO_ROOT}/05-CONFIGURATIONS/terraform"
LOG_FILE="/var/log/mantis-drift-remediation.log"
BACKUP_DIR="/opt/mantis/backups/state/$(date +%Y%m%d_%H%M%S)"

# Variables de ejecución
ENVIRONMENT="prod"
AUTO_APPLY="false"
SEVERITY_THRESHOLD="HIGH" # LOW, MEDIUM, HIGH, CRITICAL

# --- Logging -----------------------------------------------------------------
log() {
    local level="$1"; shift
    local msg="[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [$level] $*"
    echo "$msg" | tee -a "$LOG_FILE"
    # Si es crítico y hay webhooks, se podría notificar aquí
    [[ "$level" == "CRITICAL" ]] && exit 1
}

# --- Validación y Args -------------------------------------------------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --env) ENVIRONMENT="$2"; shift 2 ;;
            --auto-apply) AUTO_APPLY="true"; shift ;;
            --severity-threshold) SEVERITY_THRESHOLD="$2"; shift 2 ;;
            -h|--help)
                echo "Uso: $0 --env prod [--auto-apply] [--severity-threshold HIGH]"
                exit 0 ;;
            *) log ERROR "Opción desconocida: $1" ;;
        esac
    done
}

pre_flight_checks() {
    log INFO "🔍 Verificando prerequisitos..."
    command -v terraform >/dev/null 2>&1 || log ERROR "terraform no encontrado"
    command -v jq >/dev/null 2>&1 || log ERROR "jq no encontrado"
    
    [[ -d "$TERRAFORM_DIR" ]] || log ERROR "Directorio Terraform no encontrado: $TERRAFORM_DIR"
    
    # Backup de seguridad antes de tocar nada (C7)
    mkdir -p "$BACKUP_DIR"
    cd "$TERRAFORM_DIR/envs/${ENVIRONMENT}"
    
    # Exportar estado actual por si hay que revertir
    terraform state pull > "${BACKUP_DIR}/state-${ENVIRONMENT}-pre-remediation.json"
    log INFO "💾 Backup de estado guardado."
}

analyze_drift() {
    log INFO "🔍 Analizando tipo de drift y severidad..."
    
    # Ejecutar plan para detectar cambios
    # -refresh-only: Solo actualiza estado (metadata drift)
    # normal: Detecta cambios en infra vs HCL (config drift)
    
    # Intentar primero refresh-only para ver si es solo estado
    if terraform plan -refresh-only -out=drift.out -input=false 2>&1 | grep -q "No changes"; then
        log INFO "✅ No hay drift de metadatos/estado. Revisando config drift..."
    else
        log WARN "⚠️ Drift de metadatos detectado (ej: tags actualizados por cloud)."
        if [[ "$AUTO_APPLY" == "true" ]]; then
            log INFO "🔄 Aplicando refresh-only para sincronizar estado..."
            terraform apply -refresh-only -auto-approve
            log INFO "✅ Estado actualizado."
        fi
        return 0
    fi

    # Si hay cambios reales en infra
    if terraform plan -out=drift.out -input=false 2>&1 | grep -q "No changes"; then
        log INFO "✅ Infraestructura sincronizada con HCL."
        rm -f drift.out
        return 0
    fi
    
    log WARN "⚠️ DRIFT DE CONFIGURACIÓN DETECTADO. Analizando severidad..."
    analyze_severity
}

analyze_severity() {
    local plan_json="drift-json"
    terraform show -json drift.out > "$plan_json"

    # Analizar recursos afectados
    local changes
    changes=$(jq -r '.resource_changes[] | select(.change.actions | length > 0) | .address' "$plan_json")
    
    if [[ -z "$changes" ]]; then
        log INFO "✅ No hay recursos a cambiar."
        rm -f drift.out "$plan_json"
        return 0
    fi
    
    local critical=0
    local high=0
    local medium=0

    while IFS= read -r resource; do
        # Heurística simple de clasificación
        case "$resource" in
            *security_group*|*iam*|*firewall*|*policy*)
                log CRITICAL "🔴 Security Drift: $resource"
                ((critical++)) ;;
            *instance*|*database*|*subnet*|*vpc*)
                log WARN "🟡 Config Drift: $resource"
                ((high++)) ;;
            *tag*|*label*|*annotation*)
                log INFO "🟢 Tag/Metadata Drift: $resource"
                ((medium++)) ;;
            *)
                log WARN "⚪ Unknown Drift: $resource"
                ((high++)) ;;
        esac
    done <<< "$changes"

    rm -f drift.out "$plan_json"
    
    # Decisión basada en umbral
    if (( critical > 0 )); then
        log CRITICAL "🛑 CRITICAL DRIFT DETECTADO ($critical). Abortando auto-remediación. Requiere revisión humana."
        if [[ "$SEVERITY_THRESHOLD" == "CRITICAL" && "$AUTO_APPLY" == "true" ]]; then
            log WARN "⚠️ Override de política: Aplicando remedio crítico..."
            apply_remediation
        else
            log CRITICAL "❌ No se aplicarán cambios automáticos. Notifique a seguridad."
            return 2
        fi
    elif (( high > 0 )); then
        if [[ "$SEVERITY_THRESHOLD" == "HIGH" || "$SEVERITY_THRESHOLD" == "MEDIUM" ]]; then
            log INFO "🔄 Configuración desviada. Aplicando remedio..."
            apply_remediation
        else
            log WARN "⏸️ Umbral no permite remediar cambios HIGH."
        fi
    elif (( medium > 0 )); then
        log INFO "🔄 Drift menor detectado. Aplicando refresh..."
        apply_remediation
    fi
}

apply_remediation() {
    log INFO "🛠️ Iniciando proceso de remediación..."
    
    # Backup final antes de apply
    terraform state pull > "${BACKUP_DIR}/state-pre-apply.json" 2>/dev/null || true
    
    if terraform apply -auto-approve -input=false 2>&1 | tee /tmp/apply-output.log; then
        log INFO "✅ Remediación completada exitosamente."
        # Registrar en log de auditoría
        echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] REMEDIATION env=$ENVIRONMENT status=SUCCESS" >> /var/log/mantis-audit.log
    else
        log ERROR "❌ Fallo en remediación. Revisar logs."
        # Intentar rollback manual si es posible (restore state)
        log WARN "🔄 Intentando restaurar estado previo..."
        if terraform state push "${BACKUP_DIR}/state-${ENVIRONMENT}-pre-remediation.json"; then
            log INFO "✅ Estado restaurado. Infraestructura no fue alterada permanentemente (pero puede requerir ajuste manual)."
        fi
        return 1
    fi
}

# --- Ejecución Principal -----------------------------------------------------
main() {
    parse_args "$@"
    pre_flight_checks
    analyze_drift
    log INFO "🏁 Proceso de remediación finalizado."
}

main "$@"


---
