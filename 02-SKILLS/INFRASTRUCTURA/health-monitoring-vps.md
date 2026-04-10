# health-monitoring-vps.md

> **Monitoreo de Salud VPS - Health Monitoring System**

**Skill:** INFRA-003 | **Categoría:** INFRAESTRUCTURA
**Última actualización:** 2026-04-10
**Validación SDD:** Pending
**Refs:** 02-RESOURCE-GUARDRAILS.md, 02-SKILLS/INFRAESTRUCTURA/n8n-concurrency-limiting.md

---

## 1. Propósito y Contexto

Este skill documenta los patrones y configuraciones necesarios para implementar un sistema completo de monitoreo de salud en los VPS, permitiendo detectar problemas antes de que causen indisponibilidad de servicios críticos.

El sistema de health monitoring es **crítico** porque:

- **C1 (Resource Guardrails):** Cada VPS tiene máximo 4GB RAM y 1 vCPU, recursos limitados que requieren monitoreo activo
- **C2 (Resource Guardrails):** n8n está limitado a 1.5GB RAM y debe mantenerse dentro de este límite
- **C3 (Resource Guardrails):** Servicios externos (WhatsApp, Telegram, Gmail) requieren conectividad constante
- **C4 (Architecture Rules):** Sistema multi-tenant donde la caída de un VPS puede afectar múltiples clientes

Sin un sistema de monitoreo robusto, los problemas se detectan cuando ya causaron pérdida de mensajes, timeouts en cascada o corrupción de datos.

---

## 2. Arquitectura de Health Monitoring

### 2.1 Diagrama de Componentes del Sistema

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    ARQUITECTURA DE HEALTH MONITORING                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                    CAPA DE RECOLECCIÓN                          │   │
│   │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐      │   │
│   │  │  System  │  │  Docker  │  │  Service │  │  Network │      │   │
│   │  │  Metrics │  │  Stats   │  │  Health  │  │  Latency │      │   │
│   │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘      │   │
│   │       │              │              │              │           │   │
│   │       └──────────────┴──────────────┴──────────────┘           │   │
│   │                              │                                   │   │
│   │                              ▼                                   │   │
│   │                  ┌─────────────────────┐                        │   │
│   │                  │   Prometheus Node   │                        │   │
│   │                  │     Exporter       │                        │   │
│   │                  └──────────┬──────────┘                        │   │
│   └─────────────────────────────┼───────────────────────────────────┘   │
│                                 │                                       │
│                                 ▼                                       │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                    CAPA DE ALERTAS                              │   │
│   │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐      │   │
│   │  │ Warning  │  │ Critical │  │  Down    │  │  Slow    │      │   │
│   │  │  Level   │  │  Level   │  │ Service  │  │ Response │      │   │
│   │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘      │   │
│   │       │              │              │              │           │   │
│   │       └──────────────┴──────────────┴──────────────┘           │   │
│   │                              │                                   │   │
│   │                              ▼                                   │   │
│   │  ┌──────────────────────────────────────────────────────────┐   │   │
│   │  │              Alert Manager (Routing & Deduplication)    │   │   │
│   │  └──────────────────────────────────────────────────────────┘   │   │
│   └─────────────────────────────┬───────────────────────────────────┘   │
│                                 │                                       │
│                                 ▼                                       │
│   ┌─────────────────────────────────────────────────────────────────┐   │
│   │                    CAPA DE NOTIFICACIÓN                         │   │
│   │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐      │   │
│   │  │ Telegram │  │   Gmail  │  │   SMS    │  │  Slack   │      │   │
│   │  │  Bot     │  │   SMTP   │  │ (Twilio) │  │  Hook    │      │   │
│   │  └──────────┘  └──────────┘  └──────────┘  └──────────┘      │   │
│   └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Métricas Monitoreadas por Servicio

| Servicio | Métricas Clave | Threshold Warning | Threshold Critical | Frecuencia |
|----------|----------------|-------------------|-------------------|------------|
| **CPU** | usage_percent | > 70% | > 90% | 30s |
| **RAM** | used_mb / total_mb | > 70% | > 85% | 30s |
| **Disk** | used_percent | > 75% | > 90% | 5m |
| **n8n** | container_status, memory_mb | > 1.2GB | > 1.4GB | 1m |
| **Redis** | memory_mb, connected_clients | > 200MB | > 240MB | 1m |
| **MySQL** | connections, query_time | > 80 conn | > 100 conn | 1m |
| **Qdrant** | memory_mb, collections | > 1GB | > 1.5GB | 5m |
| **Network** | latency_ms, packet_loss | > 200ms | > 1000ms | 30s |

---

## 3. Scripts de Health Check

### 3.1 Script Principal de Monitoreo (health_monitor.sh)

```bash
#!/bin/bash
# health_monitor.sh - Sistema principal de monitoreo de salud VPS
# Ref: 02-RESOURCE-GUARDRAILS.md

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════

readonly SCRIPT_NAME="$(basename "$0")"
readonly LOG_DIR="/var/log/health"
readonly LOG_FILE="${LOG_DIR}/health_monitor.log"
readonly ALERT_STATE_FILE="/var/run/health_alert_state.json"
readonly TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
readonly TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"
readonly GMAIL_SMTP_USER="${GMAIL_SMTP_USER:-}"
readonly GMAIL_SMTP_PASS="${GMAIL_SMTP_PASS:-}"
readonly ALERT_EMAIL="${ALERT_EMAIL:-}"

# Umbrales de alertas (Ref: 02-RESOURCE-GUARDRAILS.md)
declare -A THRESHOLDS=(
    [CPU_WARNING]=70
    [CPU_CRITICAL]=90
    [RAM_WARNING]=70
    [RAM_CRITICAL]=85
    [DISK_WARNING]=75
    [DISK_CRITICAL]=90
    [N8N_RAM_WARNING]=1228
    [N8N_RAM_CRITICAL]=1433
    [REDIS_RAM_WARNING]=200
    [REDIS_RAM_CRITICAL]=240
    [NETWORK_LATENCY_WARNING]=200
    [NETWORK_LATENCY_CRITICAL]=1000
)

# ═══════════════════════════════════════════════════════════════════
# FUNCIONES DE LOGGING
# ═══════════════════════════════════════════════════════════════════

log_message() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "$LOG_FILE"
}

log_info()  { log_message "INFO" "$1"; }
log_warn()  { log_message "WARN" "$1"; }
log_error() { log_message "ERROR" "$1"; }
log_debug() { [[ "${DEBUG:-0}" == "1" ]] && log_message "DEBUG" "$1" || true; }

# ═══════════════════════════════════════════════════════════════════
# FUNCIONES DE INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════

init_environment() {
    # Crear directorio de logs
    mkdir -p "$LOG_DIR"

    # Verificar dependencias
    for cmd in docker bc curl jq; do
        if ! command -v "$cmd" &>/dev/null; then
            log_error "Dependencia faltante: $cmd"
            exit 1
        fi
    done

    log_info "=========================================="
    log_info "Iniciando Health Monitor - $(hostname)"
    log_info "=========================================="
}

# ═══════════════════════════════════════════════════════════════════
# FUNCIONES DE RECOLECCIÓN DE MÉTRICAS
# ═══════════════════════════════════════════════════════════════════

get_cpu_usage() {
    # Obtener uso de CPU (promedio de 1 minuto)
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' || echo "0"
}

get_ram_usage() {
    # Obtener uso de RAM en MB
    free -m | awk 'NR==2{printf "%.0f", $3}'
}

get_ram_total() {
    # Obtener RAM total en MB
    free -m | awk 'NR==2{printf "%.0f", $2}'
}

get_disk_usage() {
    # Obtener uso de disco en porcentaje
    df -h / | awk 'NR==2{print $5}' | sed 's/%//'
}

get_load_average() {
    # Obtener load average (1, 5, 15 minutos)
    uptime | awk -F'load average:' '{print $2}' | tr -d ','
}

get_n8n_status() {
    # Verificar estado del contenedor n8n
    local container_name="${N8N_CONTAINER:-n8n_main}"

    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo "running"
    elif docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo "stopped"
    else
        echo "not_found"
    fi
}

get_n8n_memory() {
    # Obtener memoria de n8n en MB
    local container_name="${N8N_CONTAINER:-n8n_main}"
    docker stats "$container_name" --no-stream --format "{{.MemUsage}}" | \
        awk '{print $1}' | sed 's/MiB//' | sed 's/GiB/*1024/g' | bc 2>/dev/null || echo "0"
}

get_n8n_health() {
    # Verificar endpoint de salud de n8n
    local n8n_url="${N8N_URL:-http://localhost:5678}"
    local response
    response=$(curl -s -w "%{http_code}" -o /dev/null "${n8n_url}/healthz" 2>/dev/null || echo "000")
    echo "$response"
}

get_redis_status() {
    # Verificar estado de Redis
    local container_name="${REDIS_CONTAINER:-n8n_redis}"

    if docker exec "$container_name" redis-cli ping 2>/dev/null | grep -q "PONG"; then
        echo "ok"
    else
        echo "error"
    fi
}

get_redis_memory() {
    # Obtener memoria de Redis en MB
    local container_name="${REDIS_CONTAINER:-n8n_redis}"
    docker exec "$container_name" redis-cli info memory | \
        grep "used_memory_human" | awk -F: '{print $2}' | tr -d 'r\n' | \
        awk '{if($1 ~ /G/) printf "%.0f\n", $1*1024; else printf "%.0f\n", $1}' 2>/dev/null || echo "0"
}

get_mysql_status() {
    # Verificar estado de MySQL
    local host="${MYSQL_HOST:-localhost}"
    local port="${MYSQL_PORT:-3306}"

    if timeout 5 mysqladmin ping -h "$host" -P "$port" &>/dev/null; then
        echo "ok"
    else
        echo "error"
    fi
}

get_mysql_connections() {
    # Obtener número de conexiones MySQL
    local host="${MYSQL_HOST:-localhost}"
    local port="${MYSQL_PORT:-3306}"
    local user="${MYSQL_USER:-root}"
    local pass="${MYSQL_PASSWORD:-}"

    mysqladmin extended-status -h "$host" -P "$port" -u "$user" ${pass:+-p"$pass"} 2>/dev/null | \
        grep "Threads_connected" | awk '{print $4}' || echo "0"
}

get_network_latency() {
    # Obtener latencia a servicios externos (ms)
    local target="${1:-8.8.8.8}"
    local latency
    latency=$(ping -c 1 -W 2 "$target" 2>/dev/null | \
        grep "time=" | awk -F'time=' '{print $2}' | awk '{print $1}' || echo "999")
    echo "$latency"
}

get_api_latency() {
    # Obtener latencia a API de OpenRouter (ms)
    local start_time
    local end_time
    local latency
    start_time=$(date +%s%3N)
    curl -s -o /dev/null "https://openrouter.ai/api/v1/models" 2>/dev/null || true
    end_time=$(date +%s%3N)
    latency=$((end_time - start_time))
    echo "$latency"
}

get_container_restart_count() {
    # Contar reinicios de contenedor
    local container_name="$1"
    docker inspect "$container_name" --format='{{.RestartCount}}' 2>/dev/null || echo "0"
}

get_docker_uptime() {
    # Obtener uptime de contenedor
    local container_name="$1"
    docker inspect "$container_name" --format='{{.State.StartedAt}}' 2>/dev/null || echo "unknown"
}

# ═══════════════════════════════════════════════════════════════════
# FUNCIONES DE ANÁLISIS Y ALERTAS
# ═══════════════════════════════════════════════════════════════════

check_threshold() {
    # Verificar si un valor excede un umbral
    local value="$1"
    local threshold="$2"

    if (( $(echo "$value > $threshold" | bc -l) )); then
        return 0  # Excedido
    else
        return 1  # Dentro del límite
    fi
}

get_severity_level() {
    # Determinar nivel de severidad basado en umbrales
    local metric="$1"
    local value="$2"

    local warning_threshold="${THRESHOLDS[${metric}_WARNING]:-100}"
    local critical_threshold="${THRESHOLDS[${metric}_CRITICAL]:-100}"

    if check_threshold "$value" "$critical_threshold"; then
        echo "CRITICAL"
    elif check_threshold "$value" "$warning_threshold"; then
        echo "WARNING"
    else
        echo "OK"
    fi
}

format_metric_alert() {
    # Formatear mensaje de alerta para métricas
    local metric="$1"
    local value="$2"
    local unit="$3"
    local severity="$4"

    local emoji
    case "$severity" in
        CRITICAL) emoji="🔴" ;;
        WARNING)  emoji="🟡" ;;
        OK)       emoji="🟢" ;;
    esac

    echo "${emoji} **${metric}**: ${value}${unit} [${severity}]"
}

# ═══════════════════════════════════════════════════════════════════
# FUNCIONES DE NOTIFICACIÓN
# ═══════════════════════════════════════════════════════════════════

send_telegram_alert() {
    # Enviar alerta por Telegram
    local message="$1"
    local severity="${2:-INFO}"

    if [[ -z "$TELEGRAM_BOT_TOKEN" || -z "$TELEGRAM_CHAT_ID" ]]; then
        log_warn "Telegram no configurado, omitiendo envío"
        return 1
    fi

    local emoji
    case "$severity" in
        CRITICAL) emoji="🚨" ;;
        WARNING)  emoji="⚠️" ;;
        INFO)     emoji="ℹ️" ;;
    esac

    local full_message="${emoji} *VPS Health Alert*\n\n${message}"
    local encoded_message
    encoded_message=$(echo "$full_message" | jq -Rs .)

    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${encoded_message}" \
        -d "parse_mode=Markdown" \
        > /dev/null

    log_info "Alerta Telegram enviada: ${severity}"
}

send_gmail_alert() {
    # Enviar alerta por email (Gmail SMTP)
    local subject="$1"
    local body="$2"
    local severity="${3:-INFO}"

    if [[ -z "$GMAIL_SMTP_USER" || -z "$GMAIL_SMTP_PASS" || -z "$ALERT_EMAIL" ]]; then
        log_warn "Gmail no configurado, omitiendo envío"
        return 1
    fi

    {
        echo "From: ${GMAIL_SMTP_USER}"
        echo "To: ${ALERT_EMAIL}"
        echo "Subject: [${severity}] ${subject}"
        echo "Content-Type: text/plain; charset=UTF-8"
        echo ""
        echo "$body"
    } | msmtp -a default -t "$ALERT_EMAIL" 2>/dev/null || \
    {
        # Fallback: usar sendmail si msmtp no está disponible
        echo -e "From: ${GMAIL_SMTP_USER}\nTo: ${ALERT_EMAIL}\nSubject: [${severity}] ${subject}\n\n$body" | \
        sendmail -f "$GMAIL_SMTP_USER" "$ALERT_EMAIL" 2>/dev/null || \
        log_error "No se pudo enviar email de alerta"
    }

    log_info "Alerta Gmail enviada: ${severity}"
}

check_alert_cooldown() {
    # Verificar si estamos en período de cooldown para evitar spam
    local alert_type="$1"
    local cooldown_seconds="${2:-300}"  # 5 minutos por defecto

    if [[ ! -f "$ALERT_STATE_FILE" ]]; then
        echo "false"
        return
    fi

    local last_alert
    last_alert=$(jq -r ".${alert_type}.last_sent // 0" "$ALERT_STATE_FILE" 2>/dev/null || echo "0")
    local current_time
    current_time=$(date +%s)

    if (( current_time - last_alert < cooldown_seconds )); then
        echo "true"
    else
        echo "false"
    fi
}

update_alert_state() {
    # Actualizar estado de alerta para tracking
    local alert_type="$1"
    local severity="$2"

    mkdir -p "$(dirname "$ALERT_STATE_FILE")"

    if [[ -f "$ALERT_STATE_FILE" ]]; then
        local existing_state
        existing_state=$(cat "$ALERT_STATE_FILE")
    else
        existing_state="{}"
    fi

    echo "$existing_state" | jq --arg type "$alert_type" \
        --arg severity "$severity" \
        --arg timestamp "$(date +%s)" \
        '.[$type] = {"last_sent": ($timestamp | tonumber), "last_severity": $severity}' \
        > "$ALERT_STATE_FILE.tmp" && mv "$ALERT_STATE_FILE.tmp" "$ALERT_STATE_FILE"
}

trigger_alert() {
    # Función principal para disparar alertas
    local alert_type="$1"
    local message="$2"
    local severity="${3:-WARNING}"

    # Verificar cooldown (evitar spam de alertas)
    if [[ "$severity" != "CRITICAL" ]] && check_alert_cooldown "$alert_type"; then
        log_debug "Alerta en cooldown: ${alert_type}"
        return
    fi

    # Enviar por Telegram
    send_telegram_alert "$message" "$severity"

    # Enviar por email para alertas críticas
    if [[ "$severity" == "CRITICAL" ]]; then
        send_gmail_alert "VPS CRITICAL: $(hostname)" "$message" "$severity"
    fi

    # Actualizar estado
    update_alert_state "$alert_type" "$severity"
}

# ═══════════════════════════════════════════════════════════════════
# FUNCIONES DE RECUPERACIÓN AUTOMÁTICA
# ═══════════════════════════════════════════════════════════════════

attempt_container_restart() {
    # Intentar reiniciar un contenedor caído
    local container_name="$1"
    local service_name="${2:-$container_name}"

    log_warn "Intentando reiniciar contenedor: ${container_name}"

    if docker restart "$container_name" 2>/dev/null; then
        log_info "Contenedor reiniciado exitosamente: ${container_name}"
        trigger_alert "${service_name}_restarted" \
            "✅ Contenedor reiniciado: ${container_name}" \
            "INFO"
        return 0
    else
        log_error "Falló reinicio de contenedor: ${container_name}"
        trigger_alert "${service_name}_restart_failed" \
            "❌ Falló reinicio de ${container_name}. Requiere intervención manual." \
            "CRITICAL"
        return 1
    fi
}

cleanup_stuck_workflows() {
    # Limpiar workflows colgados en n8n
    local container_name="${N8N_CONTAINER:-n8n_main}"
    local stuck_minutes="${STUCK_THRESHOLD_MINUTES:-10}"

    log_info "Buscando workflows colgados (>${stuck_minutes} min)..."

    local stuck_workflows
    stuck_workflows=$(docker exec "$container_name" \
        n8n execute list --active --json 2>/dev/null | \
        jq -r ".[] | select(.startedAt < now - ${stuck_minutes} * 60) | .id" 2>/dev/null || echo "")

    if [[ -n "$stuck_workflows" ]]; then
        local count=0
        while IFS= read -r workflow_id; do
            [[ -z "$workflow_id" ]] && continue
            log_warn "Deteniendo workflow colgado: ${workflow_id}"
            docker exec "$container_name" n8n execute stop --id "$workflow_id" 2>/dev/null || true
            ((count++))
        done <<< "$stuck_workflows"

        log_info "Detenidos ${count} workflows colgados"
        trigger_alert "stuck_workflows_cleared" \
            "🧹 Limpiados ${count} workflows colgados en n8n" \
            "INFO"
    fi
}

emergency_memory_cleanup() {
    # Limpieza de emergencia cuando la memoria está crítica
    local container_name="${N8N_CONTAINER:-n8n_main}"

    log_error "Ejecutando limpieza de emergencia de memoria..."

    # Pausar n8n temporalmente
    docker pause "$container_name" 2>/dev/null || true
    sleep 5

    # Forzar garbage collection en Docker
    docker exec "$container_name" node -e "if(global.gc) global.gc()" 2>/dev/null || true

    # Limpiar logs antiguos de n8n
    docker exec "$container_name" find /home/node/.n8n/logs -type f -mtime +7 -delete 2>/dev/null || true

    # Reanudar n8n
    docker unpause "$container_name" 2>/dev/null || true

    sleep 30

    # Verificar si mejoró
    local new_memory
    new_memory=$(get_n8n_memory)

    if check_threshold "$new_memory" "${THRESHOLDS[N8N_RAM_CRITICAL]}"; then
        log_error "Memoria aún crítica (${new_memory}MB). Reiniciando contenedor..."
        attempt_container_restart "$container_name" "n8n"
    else
        log_info "Memoria reducida a ${new_memory}MB"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# FUNCIONES DE REPORTING
# ═══════════════════════════════════════════════════════════════════

generate_health_report() {
    # Generar reporte de salud completo
    cat << EOF
═══════════════════════════════════════════════════════════════
                    REPORTE DE SALUD VPS
                    $(date '+%Y-%m-%d %H:%M:%S')
═══════════════════════════════════════════════════════════════

📊 SISTEMA
───────────────────────────────────────────────────────────────
  Hostname: $(hostname)
  Uptime: $(uptime -p 2>/dev/null || echo "unknown")
  Load Average: $(get_load_average)
  CPU Usage: $(get_cpu_usage)%
  RAM Usage: $(get_ram_usage)MB / $(get_ram_total)MB ($(echo "scale=1; $(get_ram_usage)*100/$(get_ram_usage)" | bc)%)
  Disk Usage: $(get_disk_usage)%

🐳 DOCKER CONTAINERS
───────────────────────────────────────────────────────────────
  n8n:
    Status: $(get_n8n_status)
    Memory: $(get_n8n_memory)MB
    Health Check: $(get_n8n_health)
    Restarts: $(get_container_restart_count "${N8N_CONTAINER:-n8n_main}")

  Redis:
    Status: $(get_redis_status)
    Memory: $(get_redis_memory)MB

  MySQL:
    Status: $(get_mysql_status)
    Connections: $(get_mysql_connections)

🌐 RED
───────────────────────────────────────────────────────────────
  Latencia DNS (8.8.8.8): $(get_network_latency "8.8.8.8")ms
  Latencia OpenRouter: $(get_api_latency)ms

═══════════════════════════════════════════════════════════════
EOF
}

export_prometheus_metrics() {
    # Exportar métricas en formato Prometheus
    local cpu_usage
    local ram_usage
    local ram_total
    local disk_usage
    local n8n_memory
    local redis_memory
    local mysql_connections

    cpu_usage=$(get_cpu_usage)
    ram_usage=$(get_ram_usage)
    ram_total=$(get_ram_total)
    disk_usage=$(get_disk_usage)
    n8n_memory=$(get_n8n_memory)
    redis_memory=$(get_redis_memory)
    mysql_connections=$(get_mysql_connections)

    cat << EOF
# HELP vps_cpu_usage_percent CPU usage percentage
# TYPE vps_cpu_usage_percent gauge
vps_cpu_usage_percent ${cpu_usage}

# HELP vps_ram_usage_mb RAM usage in megabytes
# TYPE vps_ram_usage_mb gauge
vps_ram_usage_mb ${ram_usage}

# HELP vps_ram_total_mb Total RAM in megabytes
# TYPE vps_ram_total_mb gauge
vps_ram_total_mb ${ram_total}

# HELP vps_ram_usage_percent RAM usage percentage
# TYPE vps_ram_usage_percent gauge
vps_ram_usage_percent $(echo "scale=2; ${ram_usage}*100/${ram_total}" | bc)

# HELP vps_disk_usage_percent Disk usage percentage
# TYPE vps_disk_usage_percent gauge
vps_disk_usage_percent ${disk_usage}

# HELP n8n_memory_mb n8n container memory usage in megabytes
# TYPE n8n_memory_mb gauge
n8n_memory_mb ${n8n_memory}

# HELP redis_memory_mb Redis memory usage in megabytes
# TYPE redis_memory_mb gauge
redis_memory_mb ${redis_memory}

# HELP mysql_connections MySQL active connections
# TYPE mysql_connections gauge
mysql_connections ${mysql_connections}

# HELP network_latency_ms Network latency in milliseconds
# TYPE network_latency_ms gauge
network_latency_ms $(get_network_latency "8.8.8.8")
EOF
}

# ═══════════════════════════════════════════════════════════════════
# FUNCIÓN PRINCIPAL DE CHECK
# ═══════════════════════════════════════════════════════════════════

run_health_checks() {
    local has_critical=false
    local has_warning=false
    local alert_messages=""

    log_info "Ejecutando health checks..."

    # ─────────────────────────────────────────────────────────────
    # CHECK: CPU Usage
    # ─────────────────────────────────────────────────────────────
    local cpu_usage
    cpu_usage=$(get_cpu_usage)
    local cpu_severity
    cpu_severity=$(get_severity_level "CPU" "$cpu_usage")

    if [[ "$cpu_severity" != "OK" ]]; then
        alert_messages+="$(format_metric_alert "CPU" "$cpu_usage" "%" "$cpu_severity")\n"
        [[ "$cpu_severity" == "CRITICAL" ]] && has_critical=true || has_warning=true

        if [[ "$cpu_severity" == "CRITICAL" ]]; then
            trigger_alert "cpu_critical" "CPU crítico: ${cpu_usage}%" "CRITICAL"
        fi
    fi

    # ─────────────────────────────────────────────────────────────
    # CHECK: RAM Usage
    # ─────────────────────────────────────────────────────────────
    local ram_usage
    ram_usage=$(get_ram_usage)
    local ram_total
    ram_total=$(get_ram_total)
    local ram_percent
    ram_percent=$(echo "scale=1; ${ram_usage}*100/${ram_total}" | bc)
    local ram_severity
    ram_severity=$(get_severity_level "RAM" "$ram_percent")

    if [[ "$ram_severity" != "OK" ]]; then
        alert_messages+="$(format_metric_alert "RAM" "${ram_percent}" "%" "$ram_severity")\n"
        [[ "$ram_severity" == "CRITICAL" ]] && has_critical=true || has_warning=true

        if [[ "$ram_severity" == "CRITICAL" ]]; then
            trigger_alert "ram_critical" "RAM crítica: ${ram_percent}% (${ram_usage}MB)" "CRITICAL"
        fi
    fi

    # ─────────────────────────────────────────────────────────────
    # CHECK: Disk Usage
    # ─────────────────────────────────────────────────────────────
    local disk_usage
    disk_usage=$(get_disk_usage)
    local disk_severity
    disk_severity=$(get_severity_level "DISK" "$disk_usage")

    if [[ "$disk_severity" != "OK" ]]; then
        alert_messages+="$(format_metric_alert "Disk" "$disk_usage" "%" "$disk_severity")\n"
        [[ "$disk_severity" == "CRITICAL" ]] && has_critical=true || has_warning=true

        if [[ "$disk_severity" == "CRITICAL" ]]; then
            trigger_alert "disk_critical" "Disco crítico: ${disk_usage}%" "CRITICAL"
        fi
    fi

    # ─────────────────────────────────────────────────────────────
    # CHECK: n8n Status
    # ─────────────────────────────────────────────────────────────
    local n8n_status
    n8n_status=$(get_n8n_status)
    local n8n_memory
    n8n_memory=$(get_n8n_memory)
    local n8n_health_code
    n8n_health_code=$(get_n8n_health)
    local n8n_memory_severity
    n8n_memory_severity=$(get_severity_level "N8N_RAM" "$n8n_memory")

    if [[ "$n8n_status" != "running" ]]; then
        alert_messages+="🔴 **n8n**: Status=${n8n_status} [CRITICAL]\n"
        has_critical=true
        attempt_container_restart "${N8N_CONTAINER:-n8n_main}" "n8n"
        trigger_alert "n8n_down" "n8n está caído: ${n8n_status}" "CRITICAL"
    elif [[ "$n8n_health_code" != "200" ]]; then
        alert_messages+="🟡 **n8n**: Health check=${n8n_health_code} [WARNING]\n"
        has_warning=true
        trigger_alert "n8n_health" "n8n health check falló: ${n8n_health_code}" "WARNING"
    fi

    if [[ "$n8n_memory_severity" != "OK" ]]; then
        alert_messages+="$(format_metric_alert "n8n RAM" "$n8n_memory" "MB" "$n8n_memory_severity")\n"
        [[ "$n8n_memory_severity" == "CRITICAL" ]] && has_critical=true || has_warning=true

        if [[ "$n8n_memory_severity" == "CRITICAL" ]]; then
            emergency_memory_cleanup
        fi
    fi

    # ─────────────────────────────────────────────────────────────
    # CHECK: Redis Status
    # ─────────────────────────────────────────────────────────────
    local redis_status
    redis_status=$(get_redis_status)
    local redis_memory
    redis_memory=$(get_redis_memory)
    local redis_memory_severity
    redis_memory_severity=$(get_severity_level "REDIS_RAM" "$redis_memory")

    if [[ "$redis_status" != "ok" ]]; then
        alert_messages+="🔴 **Redis**: Status=${redis_status} [CRITICAL]\n"
        has_critical=true
        attempt_container_restart "${REDIS_CONTAINER:-n8n_redis}" "redis"
        trigger_alert "redis_down" "Redis está caído" "CRITICAL"
    fi

    if [[ "$redis_memory_severity" != "OK" ]]; then
        alert_messages+="$(format_metric_alert "Redis RAM" "$redis_memory" "MB" "$redis_memory_severity")\n"
        [[ "$redis_memory_severity" == "CRITICAL" ]] && has_critical=true || has_warning=true
    fi

    # ─────────────────────────────────────────────────────────────
    # CHECK: MySQL Status
    # ─────────────────────────────────────────────────────────────
    local mysql_status
    mysql_status=$(get_mysql_status)
    local mysql_connections
    mysql_connections=$(get_mysql_connections)

    if [[ "$mysql_status" != "ok" ]]; then
        alert_messages+="🔴 **MySQL**: Status=${mysql_status} [CRITICAL]\n"
        has_critical=true
        trigger_alert "mysql_down" "MySQL está inalcanzable" "CRITICAL"
    elif [[ "$mysql_connections" -gt 80 ]]; then
        alert_messages+="🟡 **MySQL**: Connections=${mysql_connections} [WARNING]\n"
        has_warning=true

        if [[ "$mysql_connections" -gt 100 ]]; then
            trigger_alert "mysql_connections_high" "MySQL conexiones altas: ${mysql_connections}" "WARNING"
        fi
    fi

    # ─────────────────────────────────────────────────────────────
    # CHECK: Network Latency
    # ─────────────────────────────────────────────────────────────
    local network_latency
    network_latency=$(get_network_latency "8.8.8.8")
    local network_severity
    network_severity=$(get_severity_level "NETWORK_LATENCY" "$network_latency")

    if [[ "$network_severity" != "OK" ]]; then
        alert_messages+="$(format_metric_alert "Network Latency" "$network_latency" "ms" "$network_severity")\n"
        [[ "$network_severity" == "CRITICAL" ]] && has_critical=true || has_warning=true
    fi

    # ─────────────────────────────────────────────────────────────
    # Limpieza periódica de workflows colgados
    # ─────────────────────────────────────────────────────────────
    cleanup_stuck_workflows

    # ─────────────────────────────────────────────────────────────
    # Resumen de alertas
    # ─────────────────────────────────────────────────────────────
    if [[ "$has_critical" == "true" ]]; then
        log_error "⚠️ Estado: CRITICAL"
        log_error -e "$alert_messages"
    elif [[ "$has_warning" == "true" ]]; then
        log_warn "⚠️ Estado: WARNING"
        log_warn -e "$alert_messages"
    else
        log_info "✅ Estado: HEALTHY"
    fi

    log_info "Health checks completados"
}

# ═══════════════════════════════════════════════════════════════════
# PUNTO DE ENTRADA
# ═══════════════════════════════════════════════════════════════════

main() {
    local mode="${1:-check}"

    init_environment

    case "$mode" in
        check)
            run_health_checks
            ;;
        report)
            generate_health_report
            ;;
        metrics)
            export_prometheus_metrics
            ;;
        *)
            echo "Uso: $SCRIPT_NAME [check|report|metrics]"
            exit 1
            ;;
    esac
}

# Trap para cleanup
trap 'log_info "Deteniendo Health Monitor"; exit 0' SIGTERM SIGINT

# Ejecutar si no es sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### 3.2 Script de Monitoreo Inter-VPS (vps_interconnection_monitor.sh)

```bash
#!/bin/bash
# vps_interconnection_monitor.sh - Monitoreo de interconexión entre VPS
# Ref: 02-SKILLS/INFRAESTRUCTURA/vps-interconnection.md

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════
# CONFIGURACIÓN DE VPS REMOTOS
# ═══════════════════════════════════════════════════════════════════

readonly SSH_USER="${SSH_USER:-root}"
readonly SSH_KEY="${SSH_KEY:-~/.ssh/id_rsa}"
readonly CHECK_INTERVAL="${CHECK_INTERVAL:-60}"

# Lista de VPS a monitorear
declare -A VPS_PEERS=(
    ["vps-n8n-uazaoi"]="192.168.1.10"
    ["vps-qdrant-espocrm"]="192.168.1.20"
    ["vps-backup"]="192.168.1.30"
)

# Servicios esperados en cada VPS
declare -A VPS_SERVICES=(
    ["vps-n8n-uazaoi"]="n8n:5678,mysql:3306,redis:6379"
    ["vps-qdrant-espocrm"]="qdrant:6333,mysql:3306"
    ["vps-backup"]="rsync:873"
)

# ═══════════════════════════════════════════════════════════════════
# FUNCIONES DE LOGGING
# ═══════════════════════════════════════════════════════════════════

LOG_DIR="/var/log/vps-monitor"
LOG_FILE="${LOG_DIR}/interconnection.log"

log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] $message" | tee -a "$LOG_FILE"
}

log_info()   { log_message "INFO" "$1"; }
log_warn()   { log_message "WARN" "$1"; }
log_error()  { log_message "ERROR" "$1"; }

# ═══════════════════════════════════════════════════════════════════
# FUNCIONES DE CHECK DE CONECTIVIDAD
# ═══════════════════════════════════════════════════════════════════

check_ssh_connectivity() {
    # Verificar conectividad SSH a VPS remoto
    local vps_name="$1"
    local vps_ip="$2"
    local timeout="${3:-5}"

    if timeout "$timeout" ssh -o StrictHostKeyChecking=no \
        -o ConnectTimeout="$timeout" \
        -i "$SSH_KEY" \
        "${SSH_USER}@${vps_ip}" "echo ok" &>/dev/null; then
        echo "ok"
    else
        echo "error"
    fi
}

check_service_port() {
    # Verificar si un servicio está accesible en un puerto
    local host="$1"
    local port="$2"
    local timeout="${3:-3}"

    if timeout "$timeout" bash -c "echo > /dev/tcp/${host}/${port}" 2>/dev/null; then
        echo "ok"
    else
        echo "error"
    fi
}

check_tunnel_status() {
    # Verificar estado de túnel SSH activo
    local tunnel_name="$1"

    if pgrep -f "ssh.*${tunnel_name}" > /dev/null; then
        echo "active"
    else
        echo "inactive"
    fi
}

get_remote_health() {
    # Obtener métricas de salud de VPS remoto via SSH
    local vps_name="$1"
    local vps_ip="$2"

    local ssh_cmd="ssh -o StrictHostKeyChecking=no -i ${SSH_KEY} ${SSH_USER}@${vps_ip}"

    cat << EOF | $ssh_cmd 2>/dev/null || echo "error"
$(cat << 'INNER_SCRIPT'
#!/bin/bash
echo "cpu:$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')"
echo "ram_free:$(free -m | awk 'NR==2{print $7}')"
echo "disk:$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')"
echo "load:$(uptime | awk -F'load average:' '{print $2}' | tr -d ',')"
INNER_SCRIPT
)
EOF
}

# ═══════════════════════════════════════════════════════════════════
# FUNCIONES DE MONITOREO
# ═══════════════════════════════════════════════════════════════════

monitor_vps_peer() {
    local vps_name="$1"
    local vps_ip="$2"
    local expected_services="$3"

    local status="ok"
    local alert_message="${vps_name} (${vps_ip}):\n"

    # Check SSH
    log_info "Verificando SSH a ${vps_name}..."
    if [[ "$(check_ssh_connectivity "$vps_name" "$vps_ip")" != "ok" ]]; then
        status="error"
        alert_message+="  ❌ SSH: inalcanzable\n"

        # Intentar reconectar
        log_warn "SSH caído, intentando reconectar..."
        reconnect_ssh_tunnel "$vps_name" "$vps_ip"
    else
        alert_message+="  ✅ SSH: ok\n"
    fi

    # Check servicios esperados
    IFS=',' read -ra SERVICES <<< "$expected_services"
    for service in "${SERVICES[@]}"; do
        IFS=':' read -r svc_name svc_port <<< "$service"

        log_info "Verificando servicio ${svc_name} en ${vps_name}..."
        if [[ "$(check_service_port "$vps_ip" "$svc_port")" != "ok" ]]; then
            status="error"
            alert_message+="  ❌ ${svc_name}:${svc_port} no responde\n"
        else
            alert_message+="  ✅ ${svc_name}:${svc_port} ok\n"
        fi
    done

    # Check métricas remotas
    local remote_health
    remote_health=$(get_remote_health "$vps_name" "$vps_ip")
    if [[ "$remote_health" != "error" ]]; then
        local cpu
        local ram_free
        local disk
        cpu=$(echo "$remote_health" | grep "^cpu:" | cut -d: -f2)
        ram_free=$(echo "$remote_health" | grep "^ram_free:" | cut -d: -f2)
        disk=$(echo "$remote_health" | grep "^disk:" | cut -d: -f2)

        alert_message+="  📊 CPU: ${cpu}%, RAM libre: ${ram_free}MB, Disco: ${disk}%\n"

        # Alertas por umbrales
        if (( $(echo "$cpu > 90" | bc -l 2>/dev/null || echo "0") )); then
            status="warning"
            alert_message+="  ⚠️ CPU alto en VPS remoto\n"
        fi

        if (( disk > 90 )); then
            status="warning"
            alert_message+="  ⚠️ Disco alto en VPS remoto\n"
        fi
    fi

    # Enviar alerta si hay problemas
    if [[ "$status" != "ok" ]]; then
        send_alert "${vps_name}_${status}" "$alert_message" "$status"
    fi

    echo "$status"
}

reconnect_ssh_tunnel() {
    # Reconectar túnel SSH caído
    local tunnel_name="$1"
    local remote_ip="$2"

    # Detener túnel existente si hay残留
    pkill -f "ssh.*${tunnel_name}" 2>/dev/null || true
    sleep 2

    # Reconectar basado en configuración de túneles
    case "$tunnel_name" in
        "vps-qdrant-espocrm")
            # Reconectar túnel a Qdrant
            ssh -f -N -L 6333:localhost:6333 \
                -o StrictHostKeyChecking=no \
                -o ServerAliveInterval=60 \
                -i "$SSH_KEY" \
                "${SSH_USER}@${remote_ip}" \
                -o "LocalCommand=echo 'Túnel Qdrant activo'"
            log_info "Túnel Qdrant reconectado"
            ;;
        "vps-backup")
            # Reconectar túnel a rsync
            ssh -f -N -L 8022:localhost:22 \
                -o StrictHostKeyChecking=no \
                -o ServerAliveInterval=60 \
                -i "$SSH_KEY" \
                "${SSH_USER}@${remote_ip}"
            log_info "Túnel rsync reconectado"
            ;;
    esac
}

send_alert() {
    # Enviar alerta de interconexión
    local alert_type="$1"
    local message="$2"
    local severity="${3:-WARNING}"

    # Usar función de Telegram del script principal
    if [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]]; then
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d "chat_id=${TELEGRAM_CHAT_ID}" \
            -d "text=🌐 *VPS Interconnection Alert*

${message}" \
            -d "parse_mode=Markdown" > /dev/null
    fi

    log_"${severity,,}" "Alerta enviada: ${alert_type}"
}

# ═══════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════

main() {
    mkdir -p "$(dirname "$LOG_FILE")"

    log_info "═══════════════════════════════════════════════════════════════"
    log_info "Iniciando monitoreo de interconexión VPS"
    log_info "═══════════════════════════════════════════════════════════════"

    local overall_status="ok"

    for vps_name in "${!VPS_PEERS[@]}"; do
        local vps_ip="${VPS_PEERS[$vps_name]}"
        local services="${VPS_SERVICES[$vps_name]}"

        log_info "──────────────────────────────────────────────────────────────"
        log_info "Monitoreando: ${vps_name}"

        local vps_status
        vps_status=$(monitor_vps_peer "$vps_name" "$vps_ip" "$services")

        if [[ "$vps_status" != "ok" ]]; then
            overall_status="$vps_status"
        fi
    done

    log_info "──────────────────────────────────────────────────────────────"
    log_info "Estado general de interconexión: ${overall_status^^}"

    if [[ "$overall_status" == "error" ]]; then
        exit 1
    fi
}

# Ejecutar como demonio si se especifica
if [[ "${1:-}" == "--daemon" ]]; then
    while true; do
        main
        sleep "$CHECK_INTERVAL"
    done
else
    main
fi
```

### 3.3 Configuración de Cron Jobs para Monitoreo

```bash
# /etc/cron.d/health-monitoring
# Programar checks de salud en el VPS

# Health check cada 5 minutos
*/5 * * * * root /opt/scripts/health_monitor.sh check >> /var/log/health/cron.log 2>&1

# Reporte diario de salud (8 AM)
0 8 * * * root /opt/scripts/health_monitor.sh report | mail -s "VPS Health Report $(hostname)" admin@example.com

# Exportar métricas Prometheus cada 30 segundos (para Prometheus/Grafana)
* * * * * root /opt/scripts/health_monitor.sh metrics > /var/www/html/metrics.prom 2>&1
* * * * * root sleep 30 && /opt/scripts/health_monitor.sh metrics >> /var/www/html/metrics.prom 2>&1

# Monitoreo de interconexión cada 5 minutos
*/5 * * * * root /opt/scripts/vps_interconnection_monitor.sh --daemon &

# Cleanup de logs antiguos (domingo a las 3 AM)
0 3 * * 0 root find /var/log/health -type f -mtime +30 -delete

# Backup de estado de alertas
0 */6 * * * root tar -czf /var/backups/alert-states-$(date +\%Y\%m\%d\%H).tar.gz /var/run/health_alert_state.json 2>/dev/null
```

---

## 4. Workflows n8n para Health Monitoring

### 4.1 Workflow: VPS Health Alert System

```json
{
  "name": "VPS-Health-Alert-System",
  "nodes": [
    {
      "name": "Schedule Trigger",
      "type": "n8n-nodes-base.scheduleTrigger",
      "typeVersion": 2,
      "parameters": {
        "rule": {
          "interval": [
            {
              "field": "minutes",
              "minutesInterval": 5
            }
          ]
        }
      },
      "position": [100, 300]
    },
    {
      "name": "Execute Health Script",
      "type": "n8n-nodes-base.processLargeFiles",
      "typeVersion": 1,
      "parameters": {
        "command": "bash",
        "args": "/opt/scripts/health_monitor.sh check",
        "note": "Ejecutar script de salud del VPS"
      },
      "position": [300, 300]
    },
    {
      "name": "Parse Log Output",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "parameters": {
        "jsCode": "// Parsear salida del health monitor\nconst logOutput = $input.item().json.output;\n\n// Extraer estado y métricas\nconst stateMatch = logOutput.match(/Estado:\\s*(HEALTHY|WARNING|CRITICAL)/);\nconst cpuMatch = logOutput.match(/CPU Usage:\\s*([\\d.]+)%/);\nconst ramMatch = logOutput.match(/RAM Usage:\\s*(\\d+)MB/);\nconst diskMatch = logOutput.match(/Disk Usage:\\s*(\\d+)%/);\n\nreturn [{\n  json: {\n    timestamp: new Date().toISOString(),\n    state: stateMatch ? stateMatch[1] : 'UNKNOWN',\n    cpu: cpuMatch ? parseFloat(cpuMatch[1]) : null,\n    ram_mb: ramMatch ? parseInt(ramMatch[1]) : null,\n    disk_percent: diskMatch ? parseInt(diskMatch[1]) : null,\n    alert_needed: stateMatch && ['WARNING', 'CRITICAL'].includes(stateMatch[1])\n  }\n}];"
      },
      "position": [500, 300]
    },
    {
      "name": "Check Alert Needed",
      "type": "n8n-nodes-base.switch",
      "typeVersion": 2,
      "parameters": {
        "dataType": "boolean",
        "valueComparisonMode": "equals",
        "rules": {
          "values": [
            {
              "operation": "equals",
              "value2": true
            }
          ]
        },
        "fallbackOutput": "default"
      },
      "position": [700, 300]
    },
    {
      "name": "Compose Telegram Alert",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "parameters": {
        "jsCode": "// Componer mensaje de alerta Telegram\nconst data = $input.item().json;\n\nlet emoji = data.state === 'CRITICAL' ? '🚨' : '⚠️';\nlet severity = data.state;\n\nconst message = `${emoji} *VPS Health Alert*\n\n` +\n  `*Estado:* ${severity}\n` +\n  `*Servidor:* ${require('os').hostname()}\n` +\n  `*Hora:* ${new Date().toLocaleString('es-ES', {timeZone: 'America/Sao_Paulo'})}\n\n` +\n  `📊 *Métricas:*\n` +\n  `• CPU: ${data.cpu}%\n` +\n  `• RAM: ${data.ram_mb}MB\n` +\n  `• Disco: ${data.disk_percent}%\n\n` +\n  `🔗 [Ver Dashboard](${process.env.GRAFANA_URL || 'http://localhost:3000'})`;\n\nreturn [{ json: { message, severity } }];"
      },
      "position": [900, 200]
    },
    {
      "name": "Send Telegram Alert",
      "type": "n8n-nodes-base.telegramBot",
      "typeVersion": 1,
      "parameters": {
        "chatId": "{{ $env.TELEGRAM_ALERT_CHAT_ID }}",
        "text": "={{ $json.message }}",
        "additionalFields": {
          "parse_mode": "Markdown"
        }
      },
      "position": [1100, 200]
    },
    {
      "name": "Store Health Metrics",
      "type": "n8n-nodes-base.postgres",
      "typeVersion": 2,
      "parameters": {
        "operation": "executeQuery",
        "query": "INSERT INTO health_metrics (server_id, cpu_usage, ram_usage_mb, disk_usage, state, created_at) VALUES ($1, $2, $3, $4, $5, NOW())",
        "options": {
          "host": "{{ $env.MYSQL_HOST }}",
          "port": "{{ $env.MYSQL_PORT }}",
          "database": "{{ $env.MYSQL_DATABASE }}"
        }
      },
      "position": [1100, 400]
    },
    {
      "name": "No Alert",
      "type": "n8n-nodes-base.noOp",
      "parameters": {},
      "position": [900, 400]
    }
  ],
  "connections": {
    "Schedule Trigger": {
      "main": [[{"node": "Execute Health Script", "type": "main", "index": 0}]]
    },
    "Execute Health Script": {
      "main": [[{"node": "Parse Log Output", "type": "main", "index": 0}]]
    },
    "Parse Log Output": {
      "main": [[{"node": "Check Alert Needed", "type": "main", "index": 0}]]
    },
    "Check Alert Needed": {
      "main": [[{"node": "Compose Telegram Alert", "type": "main", "index": 0}]],
      "default": [[{"node": "No Alert", "type": "main", "index": 0}]]
    },
    "Compose Telegram Alert": {
      "main": [[{"node": "Send Telegram Alert", "type": "main", "index": 0}]]
    },
    "Send Telegram Alert": {
      "main": [[{"node": "Store Health Metrics", "type": "main", "index": 0}]]
    },
    "No Alert": {
      "main": [[{"node": "Store Health Metrics", "type": "main", "index": 0}]]
    }
  },
  "settings": {
    "executionOrder": "v1",
    "saveDataErrorExecution": "all",
    "saveDataSuccessExecution": "none",
    "timeout": 120
  },
  "staticData": null
}
```

### 4.2 Workflow: Service Health Check con Auto-Recovery

```json
{
  "name": "Service-Health-AutoRecovery",
  "nodes": [
    {
      "name": "Webhook Trigger",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 2,
      "parameters": {
        "httpMethod": "POST",
        "path": "service-health-check",
        "responseMode": "lastNode"
      },
      "position": [100, 300]
    },
    {
      "name": "Get Service Config",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "parameters": {
        "jsCode": "// Obtener configuración de servicios a monitorear\nconst services = [\n  { name: 'n8n', container: 'n8n_main', port: 5678, healthEndpoint: '/healthz' },\n  { name: 'redis', container: 'n8n_redis', port: 6379, healthEndpoint: null },\n  { name: 'mysql', container: 'mysql_main', port: 3306, healthEndpoint: null }\n];\n\nconst tenantId = $input.item().json.tenant_id || 'default';\n\nreturn services.map(svc => ({ json: { ...svc, tenant_id: tenantId } }));"
      },
      "position": [300, 300]
    },
    {
      "name": "Loop Over Services",
      "type": "n8n-nodes-base.splitInBatches",
      "typeVersion": 2,
      "parameters": {
        "batchSize": 1,
        "options": {
          "reset": false
        }
      },
      "position": [500, 300]
    },
    {
      "name": "Check Container Status",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "parameters": {
        "jsCode": "// Verificar estado de contenedor Docker\nconst service = $input.item().json;\nconst { execSync } = require('child_process');\n\ntry {\n  // Check si el contenedor está corriendo\n  const isRunning = execSync(`docker ps --filter name=${service.container} --format '{{.Names}}'`, {\n    encoding: 'utf8'\n  }).includes(service.container);\n  \n  let healthStatus = 'unknown';\n  let responseTime = null;\n  \n  if (isRunning && service.healthEndpoint) {\n    // Verificar endpoint de salud\n    const start = Date.now();\n    const http = require('http');\n    try {\n      const response = await new Promise((resolve, reject) => {\n        const req = http.get(`http://localhost:${service.port}${service.healthEndpoint}`, res => {\n          resolve(res.statusCode);\n        });\n        req.on('error', reject);\n        req.setTimeout(5000, () => {\n          req.destroy();\n          reject(new Error('Timeout'));\n        });\n      });\n      responseTime = Date.now() - start;\n      healthStatus = response === 200 ? 'healthy' : 'unhealthy';\n    } catch (e) {\n      healthStatus = 'unreachable';\n    }\n  } else if (isRunning) {\n    healthStatus = 'running';\n  } else {\n    healthStatus = 'stopped';\n  }\n  \n  return [{\n    json: {\n      ...service,\n      is_running: isRunning,\n      health_status: healthStatus,\n      response_time_ms: responseTime,\n      needs_restart: !isRunning || healthStatus === 'unreachable'\n    }\n  }];\n} catch (error) {\n  return [{\n    json: {\n      ...service,\n      error: error.message,\n      needs_restart: true\n    }\n  }];\n}"
      },
      "position": [700, 300]
    },
    {
      "name": "Needs Restart?",
      "type": "n8n-nodes-base.switch",
      "typeVersion": 2,
      "parameters": {
        "dataType": "boolean",
        "valueComparisonMode": "equals",
        "rules": {
          "values": [
            {
              "operation": "equals",
              "value2": true
            }
          ]
        },
        "fallbackOutput": "default"
      },
      "position": [900, 300]
    },
    {
      "name": "Restart Container",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "parameters": {
        "jsCode": "// Reiniciar contenedor Docker\nconst { execSync } = require('child_process');\nconst service = $input.item().json;\n\ntry {\n  const result = execSync(`docker restart ${service.container}`, { encoding: 'utf8' });\n  console.log(`Contenedor ${service.container} reiniciado`);\n  \n  // Esperar a que esté disponible\n  await new Promise(r => setTimeout(r, 10000));\n  \n  return [{\n    json: {\n      ...service,\n      restart_result: 'success',\n      restarted_at: new Date().toISOString()\n    }\n  }];\n} catch (error) {\n  return [{\n    json: {\n      ...service,\n      restart_result: 'failed',\n      restart_error: error.message\n    }\n  }];\n}"
      },
      "position": [1100, 200]
    },
    {
      "name": "Send Restart Alert",
      "type": "n8n-nodes-base.telegramBot",
      "typeVersion": 1,
      "parameters": {
        "chatId": "{{ $env.TELEGRAM_ALERT_CHAT_ID }}",
        "text": "=🔄 *Auto-Recovery*\n\nServicio: {{ $json.name }}\nContenedor: {{ $json.container }}\nResultado: {{ $json.restart_result }}\n{{ $json.restart_error ? 'Error: ' + $json.restart_error : '' }}",
        "additionalFields": {
          "parse_mode": "Markdown"
        }
      },
      "position": [1300, 200]
    },
    {
      "name": "Record Service Status",
      "type": "n8n-nodes-base.postgres",
      "typeVersion": 2,
      "parameters": {
        "operation": "executeQuery",
        "query": "INSERT INTO service_health_log (service_name, container, status, response_time_ms, restarted, created_at) VALUES ($1, $2, $3, $4, $5, NOW())",
        "options": {
          "host": "{{ $env.MYSQL_HOST }}",
          "port": "{{ $env.MYSQL_PORT }}",
          "database": "{{ $env.MYSQL_DATABASE }}"
        }
      },
      "position": [1300, 400]
    },
    {
      "name": "Loop Continue",
      "type": "n8n-nodes-base.wait",
      "typeVersion": 1,
      "parameters": {
        "amount": 1,
        "unit": "seconds"
      },
      "position": [1500, 300]
    }
  ],
  "connections": {
    "Webhook Trigger": {
      "main": [[{"node": "Get Service Config", "type": "main", "index": 0}]]
    },
    "Get Service Config": {
      "main": [[{"node": "Loop Over Services", "type": "main", "index": 0}]]
    },
    "Loop Over Services": {
      "main": [[{"node": "Check Container Status", "type": "main", "index": 0}]]
    },
    "Check Container Status": {
      "main": [[{"node": "Needs Restart?", "type": "main", "index": 0}]]
    },
    "Needs Restart?": {
      "main": [[{"node": "Restart Container", "type": "main", "index": 0}]],
      "default": [[{"node": "Record Service Status", "type": "main", "index": 0}]]
    },
    "Restart Container": {
      "main": [[{"node": "Send Restart Alert", "type": "main", "index": 0}]]
    },
    "Send Restart Alert": {
      "main": [[{"node": "Record Service Status", "type": "main", "index": 0}]]
    },
    "Record Service Status": {
      "main": [[{"node": "Loop Continue", "type": "main", "index": 0}]]
    },
    "Loop Continue": {
      "main": [[{"node": "Loop Over Services", "type": "main", "index": 0}]]
    }
  }
}
```

---

## 5. Dashboard de Grafana para Health Monitoring

### 5.1 JSON del Dashboard

```json
{
  "dashboard": {
    "title": "VPS Health Monitoring",
    "uid": "vps-health-main",
    "panels": [
      {
        "title": "CPU Usage",
        "type": "gauge",
        "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0},
        "targets": [
          {
            "expr": "vps_cpu_usage_percent",
            "legendFormat": "CPU %"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 70},
                {"color": "red", "value": 90}
              ]
            },
            "unit": "percent"
          }
        }
      },
      {
        "title": "RAM Usage",
        "type": "gauge",
        "gridPos": {"h": 8, "w": 6, "x": 6, "y": 0},
        "targets": [
          {
            "expr": "vps_ram_usage_percent",
            "legendFormat": "RAM %"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 70},
                {"color": "red", "value": 85}
              ]
            },
            "unit": "percent"
          }
        }
      },
      {
        "title": "Disk Usage",
        "type": "gauge",
        "gridPos": {"h": 8, "w": 6, "x": 12, "y": 0},
        "targets": [
          {
            "expr": "vps_disk_usage_percent",
            "legendFormat": "Disk %"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 75},
                {"color": "red", "value": 90}
              ]
            },
            "unit": "percent"
          }
        }
      },
      {
        "title": "n8n Memory",
        "type": "gauge",
        "gridPos": {"h": 8, "w": 6, "x": 18, "y": 0},
        "targets": [
          {
            "expr": "n8n_memory_mb",
            "legendFormat": "n8n RAM MB"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "min": 0,
            "max": 1536,
            "thresholds": {
              "mode": "absolute",
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 1200},
                {"color": "red", "value": 1433}
              ]
            },
            "unit": "deca-mega"
          }
        }
      },
      {
        "title": "Service Status Overview",
        "type": "stat",
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 8},
        "targets": [
          {
            "expr": "up{job='n8n'}",
            "legendFormat": "n8n"
          },
          {
            "expr": "up{job='redis'}",
            "legendFormat": "Redis"
          },
          {
            "expr": "up{job='mysql'}",
            "legendFormat": "MySQL"
          }
        ]
      },
      {
        "title": "Health Metrics Timeline",
        "type": "timeseries",
        "gridPos": {"h": 10, "w": 24, "x": 0, "y": 16},
        "targets": [
          {
            "expr": "vps_cpu_usage_percent",
            "legendFormat": "CPU"
          },
          {
            "expr": "vps_ram_usage_percent",
            "legendFormat": "RAM"
          },
          {
            "expr": "vps_disk_usage_percent",
            "legendFormat": "Disk"
          }
        ],
        "options": {
          "legend": {
            "displayMode": "table",
            "placement": "right"
          }
        }
      }
    ]
  }
}
```

---

## 6. Problemas Habituales y Soluciones

### Problema 1: Health Script No Se Ejecuta por Permisos

**Síntoma:** El script de health monitoring no se ejecuta o falla con errores de permisos.

**Causa raíz:** El script requiere permisos de ejecución y acceso a Docker socket.

**Solución:**

```bash
# Asignar permisos correctos
chmod +x /opt/scripts/health_monitor.sh
chmod +x /opt/scripts/vps_interconnection_monitor.sh

# Agregar usuario al grupo docker
usermod -aG docker health-monitor  # o el usuario que ejecute el script

# Verificar acceso al socket Docker
ls -la /var/run/docker.sock
chmod 666 /var/run/docker.sock  # Solo si es necesario

# Configurar sudo para comandos específicos
echo "health-monitor ALL=(ALL) NOPASSWD: /usr/bin/docker" >> /etc/sudoers.d/health
```

---

### Problema 2: Alertas Duplicadas por Cooldown Ineficaz

**Síntoma:** Se reciben múltiples alertas del mismo problema en poco tiempo.

**Causa raíz:** El mecanismo de cooldown no está funcionando correctamente o el intervalo es muy corto.

**Solución:**

```bash
# Verificar que el archivo de estado existe y tiene permisos
ls -la /var/run/health_alert_state.json

# Aumentar el cooldown si es necesario (recomendado: 300 segundos / 5 minutos)
# En el script principal:
# readonly COOLDOWN_SECONDS=300

# Verificar logs de alertas
tail -f /var/log/health/health_monitor.log | grep -i "alert"
```

---

### Problema 3: Docker Stats Falla en Contenedores Detenidos

**Síntoma:** El script falla al obtener métricas de un contenedor que está detenído.

**Solución:**

```bash
# Modificar la función get_n8n_memory para manejar contenedores detenidos
get_n8n_memory() {
    local container_name="${N8N_CONTAINER:-n8n_main}"

    # Verificar primero si el contenedor existe
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo "0"
        return
    fi

    # Verificar si está corriendo
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        docker stats "$container_name" --no-stream --format "{{.MemUsage}}" | \
            awk '{print $1}' | sed 's/MiB//' | sed 's/GiB/*1024/g' | bc 2>/dev/null || echo "0"
    else
        echo "stopped"
    fi
}
```

---

### Problema 4: Prometheus No Recoge Métricas

**Síntoma:** Las métricas no aparecen en Prometheus/Grafana.

**Solución:**

```bash
# Verificar que el archivo de métricas se está generando
cat /var/www/html/metrics.prom

# Verificar permisos
chown prometheus:prometheus /var/www/html/metrics.prom

# Verificar que nginx/nginx está sirviendo el archivo
curl http://localhost/metrics.prom

# Agregar job a prometheus.yml
# - job_name: 'vps-health'
#   static_configs:
#     - targets: ['localhost:9100']  # Node Exporter
#     - targets: ['localhost:80']   # Custom metrics
#       metrics_path: '/metrics.prom'
```

---

### Problema 5: Telegram Bot No Recibe Mensajes

**Síntoma:** Las alertas de Telegram no se entregan.

**Solución:**

```bash
# Verificar token y chat_id
echo "Bot Token: ${TELEGRAM_BOT_TOKEN:0:10}..."
echo "Chat ID: $TELEGRAM_CHAT_ID"

# Test directo al API de Telegram
curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
  -d "chat_id=${TELEGRAM_CHAT_ID}" \
  -d "text=Test de conectividad"

# Verificar respuestas del bot
curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates"
```

---

## 7. Checklist de Validación

| # | Verificación | Estado | Ref |
|---|--------------|--------|-----|
| 1 | Health monitor script instalado en /opt/scripts | ⬜ | Sección 3 |
| 2 | Permisos de ejecución asignados (chmod +x) | ⬜ | Problema 1 |
| 3 | Cron jobs configurados en /etc/cron.d | ⬜ | Sección 3.3 |
| 4 | Variables de entorno configuradas (Telegram, Gmail) | ⬜ | Sección 3 |
| 5 | Archivo de estado de alertas tiene permisos de escritura | ⬜ | Problema 2 |
| 6 | Workflow n8n de alertas activo y habilitado | ⬜ | Sección 4.1 |
| 7 | Dashboard de Grafana importado | ⬜ | Sección 5 |
| 8 | Prometheus configurado para recoger métricas | ⬜ | Problema 4 |
| 9 | Interconexión VPS configurada y probada | ⬜ | Sección 3.2 |
| 10 | Telegram bot verificado y funcional | ⬜ | Problema 5 |
| 11 | Alertas de Gmail configuradas (para críticos) | ⬜ | Sección 3 |
| 12 | Procedimiento de auto-recovery documentado | ⬜ | Sección 4.2 |
| 13 | Logs rotando correctamente | ⬜ | Sección 3.3 |
| 14 | Backup de estados de alerta configurado | ⬜ | Sección 3.3 |

---

## 8. Referencias

- **02-RESOURCE-GUARDRAILS.md:** Límites de RAM 4GB, CPU 1 vCPU
- **02-SKILLS/INFRAESTRUCTURA/n8n-concurrency-limiting.md:** Control de concurrencia
- **02-SKILLS/INFRAESTRUCTURA/vps-interconnection.md:** Interconexión entre VPS
- **02-SKILLS/COMUNICACION/telegram-bot-integration.md:** Integración con Telegram
- **02-SKILLS/COMUNICACION/gmail-smtp-integration.md:** Integración con Gmail SMTP
- **04-API-RELIABILITY-RULES.md:** Retry y circuit breaker

---

**Autor:** MiniMax Agent
**Fecha creación:** 2026-04-10
**Última validación:** Pending SDD Compliance
**Versión:** 1.0.0
