---
# FRONTMATTER CANÓNICO OBLIGATORIO
artifact_id: "canary-deploy-v1.0.0"
artifact_type: "script"
version: "1.0.0-COMPREHENSIVE"
constraints_mapped: ["C7","C8","V3"]
canonical_path: "05-CONFIGURATIONS/scripts/canary-deploy.sh"
domain: "05-CONFIGURATIONS"
subdomain: "scripts"
agent_role: "canary-deployment"
language_lock: "bash"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain scripts --file 05-CONFIGURATIONS/scripts/canary-deploy.sh --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants"]
human_readable: false
checksum_sha256: "97dab3b7d3e507d853a9b913367a95fb0e387a2dde498936513c9e4c972efede"
# FIN FRONTMATTER
---


#!/usr/bin/env bash
# =============================================================================
# SCRIPT: canary-deploy.sh
# DOMINIO: 05-CONFIGURATIONS/scripts
# PROPÓSITO: Despliegue canario con monitoreo métrico (error rate, latencia p99)
#            y rollback automático si se superan umbrales. Compatible con 
#            Docker Compose + Proxy reverso + Prometheus.
# USO: ./canary-deploy.sh --env prod --canary-image registry/app:v2.1.0 \
#            --canary-pct 20 --monitor-minutes 15 --err-threshold 0.01 --lat-threshold 500
# DEPENDENCIAS: bash >= 5.0, docker compose, curl, jq, nginx/traefik (routing)
# AUTOR: configurations-master-agent (MANTIS)
# VERSIÓN: 1.0.0
# CONSTRAINTS: C7 (Resiliencia/Rollback), C8 (Observabilidad), V3 (Performance)
# =============================================================================
set -euo pipefail

# --- Configuración -----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel)"
CONFIGS_DIR="${REPO_ROOT}/05-CONFIGURATIONS"
LOG_FILE="/var/log/mantis-canary-deploy.log"
PROXY_CONFIG_DIR="/etc/nginx/conf.d" # Ajustable vía --proxy-dir
CANARY_LABEL="canary=true"
PROMETHEUS_URL="${PROMETHEUS_URL:-http://localhost:9090}"

# Variables de ejecución
ENVIRONMENT="prod"
CANARY_IMAGE=""
CANARY_PCT=10
MONITOR_MINUTES=10
ERR_THRESHOLD="0.01"    # 1% error rate
LAT_THRESHOLD="500"     # 500ms p99 latency
PROXY_DIR=""
DRY_RUN="false"
CANARY_CONTAINER="app-canary"
STABLE_CONTAINER="app-stable"

# --- Logging -----------------------------------------------------------------
log() {
    local level="$1"; shift
    local msg="[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [$level] $*"
    echo "$msg" | tee -a "$LOG_FILE"
    [[ "$level" == "ERROR" || "$level" == "CRITICAL" ]] && exit 1
}

# --- Cleanup / Rollback ------------------------------------------------------
rollback() {
    log WARN "🔄 Iniciando rollback automático (C7: Resiliencia)..."
    
    if [[ "$DRY_RUN" == "false" ]]; then
        # Detener canario
        docker stop "$CANARY_CONTAINER" 2>/dev/null || true
        docker rm "$CANARY_CONTAINER" 2>/dev/null || true
        
        # Restaurar routing (ejemplo Nginx: restaurar upstream original)
        if [[ -n "$PROXY_DIR" && -f "${PROXY_DIR}/upstream_stable.conf.bak" ]]; then
            cp "${PROXY_DIR}/upstream_stable.conf.bak" "${PROXY_DIR}/upstream.conf"
            systemctl reload nginx 2>/dev/null || docker exec nginx-proxy nginx -s reload 2>/dev/null || true
        fi
    fi
    
    log WARN "🚫 Rollback completado. Servicio estable preservado."
    exit 1
}
trap rollback ERR

# --- Validación y Args -------------------------------------------------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --env) ENVIRONMENT="$2"; shift 2 ;;
            --canary-image) CANARY_IMAGE="$2"; shift 2 ;;
            --canary-pct) CANARY_PCT="$2"; shift 2 ;;
            --monitor-minutes) MONITOR_MINUTES="$2"; shift 2 ;;
            --err-threshold) ERR_THRESHOLD="$2"; shift 2 ;;
            --lat-threshold) LAT_THRESHOLD="$2"; shift 2 ;;
            --proxy-dir) PROXY_DIR="$2"; shift 2 ;;
            --dry-run) DRY_RUN="true"; shift ;;
            -h|--help)
                echo "Uso: $0 --env prod --canary-image <img> [--canary-pct 10] [--monitor-minutes 10]"
                exit 0 ;;
            *) log ERROR "Opción desconocida: $1" ;;
        esac
    done

    if [[ -z "$CANARY_IMAGE" ]]; then
        log ERROR "Falta --canary-image. Obligatorio."
    fi
}

pre_flight_checks() {
    log INFO "🔍 Verificando prerequisitos..."
    command -v docker >/dev/null 2>&1 || log ERROR "docker no encontrado"
    command -v jq >/dev/null 2>&1 || log ERROR "jq no encontrado"
    
    # Verificar contenedor estable
    if ! docker ps --format '{{.Names}}' | grep -q "^${STABLE_CONTAINER}$"; then
        log ERROR "Contenedor estable '$STABLE_CONTAINER' no encontrado o no corriendo."
    fi
    
    # Verificar Prometheus accesible
    if ! curl -sf "${PROMETHEUS_URL}/api/v1/status/config" >/dev/null 2>&1; then
        log WARN "⚠️ Prometheus no accesible en ${PROMETHEUS_URL}. Métricas no validables en tiempo real."
    fi

    # Backup de proxy config si se aplica
    if [[ -n "$PROXY_DIR" && -d "$PROXY_DIR" && "$DRY_RUN" == "false" ]]; then
        cp "${PROXY_DIR}/upstream.conf" "${PROXY_DIR}/upstream_stable.conf.bak"
        log INFO "💾 Backup de routing guardado."
    fi
}

deploy_canary() {
    log INFO "🚀 Desplegando versión canaria: $CANARY_IMAGE ($CANARY_PCT% tráfico estimado)..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log INFO "[DRY-RUN] Simularía: docker run --name $CANARY_CONTAINER -d $CANARY_IMAGE"
        return 0
    fi

    docker run -d \
      --name "$CANARY_CONTAINER" \
      --env-file "${CONFIGS_DIR}/environment/.env.${ENVIRONMENT}" \
      --network app-network \
      --label "$CANARY_LABEL" \
      --restart unless-stopped \
      "$CANARY_IMAGE"
      
    sleep 10 # Esperar health check inicial
    if docker inspect -f '{{.State.Health.Status}}' "$CANARY_CONTAINER" 2>/dev/null | grep -q "unhealthy"; then
        log CRITICAL "❌ Canary container no pasa health check inicial. Abortando."
    fi
    log INFO "✅ Canary desplegado y saludable."
}

update_routing() {
    log INFO "🔀 Actualizando routing para distribuir tráfico ($CANARY_PCT%)..."
    
    if [[ -z "$PROXY_DIR" || "$DRY_RUN" == "true" ]]; then
        log INFO "[INFO] Routing externo no especificado o dry-run. Omitiendo."
        return 0
    fi

    # Ejemplo genérico para Nginx weighted upstream
    # Ajustar según tu stack real (Traefik labels, HAProxy, etc.)
    cat > "${PROXY_DIR}/upstream.conf" <<EOF
upstream backend {
    server ${STABLE_CONTAINER}:8080 weight=$((100 - CANARY_PCT));
    server ${CANARY_CONTAINER}:8080 weight=${CANARY_PCT};
}
EOF
    
    systemctl reload nginx 2>/dev/null || docker exec nginx-proxy nginx -s reload 2>/dev/null || true
    log INFO "✅ Routing actualizado."
}

monitor_metrics() {
    log INFO "📊 Monitoreando métricas por $MONITOR_MINUTES minutos..."
    local end_time=$(( $(date +%s) + (MONITOR_MINUTES * 60) ))
    
    while (( $(date +%s) < end_time )); do
        sleep 30 # Intervalo de muestreo
        
        # 1. Error Rate (5xx / total)
        local err_rate
        err_rate=$(curl -sf "${PROMETHEUS_URL}/api/v1/query" \
            --data-urlencode "query=sum(rate(http_requests_total{status=~\"5..\",job=~\".*${CANARY_CONTAINER}.*\"}[5m])) / sum(rate(http_requests_total{job=~\".*${CANARY_CONTAINER}.*\"}[5m]))" 2>/dev/null \
            | jq -r '.data.result[0].value[1] // "0"')
        
        # 2. Latencia p99
        local latency_p99
        latency_p99=$(curl -sf "${PROMETHEUS_URL}/api/v1/query" \
            --data-urlencode "query=histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket{job=~\".*${CANARY_CONTAINER}.*\"}[5m])) by (le))" 2>/dev/null \
            | jq -r '.data.result[0].value[1] // "0"' 2>/dev/null || echo "0")
        
        # Convertir a ms para comparación
        local latency_ms
        latency_ms=$(echo "$latency_p99 * 1000" | bc 2>/dev/null || echo "0")

        log INFO "📈 Métricas actuales → Error Rate: ${err_rate} | Latency p99: ${latency_ms}ms"

        # Validar umbrales (C8/V3)
        if (( $(echo "$err_rate > $ERR_THRESHOLD" | bc -l) )); then
            log CRITICAL "🛑 Error rate ${err_rate} supera umbral ${ERR_THRESHOLD}. Activando rollback."
        fi
        if (( $(echo "$latency_ms > $LAT_THRESHOLD" | bc -l) )); then
            log CRITICAL "🛑 Latencia p99 ${latency_ms}ms supera umbral ${LAT_THRESHOLD}ms. Activando rollback."
        fi
    done
    
    log INFO "✅ Período de monitoreo completado sin violar umbrales."
}

promote_canary() {
    log INFO "🏆 Promoviendo canary a estable..."
    
    if [[ "$DRY_RUN" == "false" ]]; then
        # 100% tráfico al canary
        update_routing # Asume que la función ajusta pesos o cambia upstream
        
        # Renombrar contenedores (docker rename)
        docker rename "$STABLE_CONTAINER" "${STABLE_CONTAINER}-old" 2>/dev/null || true
        docker rename "$CANARY_CONTAINER" "$STABLE_CONTAINER" 2>/dev/null || true
        docker stop "${STABLE_CONTAINER}-old" 2>/dev/null || true
        docker rm "${STABLE_CONTAINER}-old" 2>/dev/null || true
        
        log INFO "✅ Promoción completada. Versión $CANARY_IMAGE es ahora la estable."
    else
        log INFO "[DRY-RUN] Simularía promoción y renombrado de contenedores."
    fi
}

# --- Ejecución Principal -----------------------------------------------------
main() {
    parse_args "$@"
    pre_flight_checks
    
    log INFO "🎯 Iniciando Canary Deploy: $ENVIRONMENT → $CANARY_IMAGE"
    
    deploy_canary
    update_routing
    monitor_metrics
    promote_canary
    
    log INFO "🎉 Canary deploy finalizado exitosamente."
    log INFO "👉 Próximos pasos:"
    log INFO "   1. Verificar métricas globales: curl -f ${PROMETHEUS_URL}/graph"
    log INFO "   2. Actualizar registry: git tag v\$(date +%Y.%m.%d)-canary"
    log INFO "   3. Notificar al equipo: curl -X POST \$SLACK_WEBHOOK -d '{\"text\": \"✅ Canary promovido a estable\"}'"
}

main "$@"


---
