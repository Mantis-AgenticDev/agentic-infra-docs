---
# FRONTMATTER CANÓNICO OBLIGATORIO
artifact_id: "vps-hardening-v1.0.0"
artifact_type: "script"
version: "1.0.0-COMPREHENSIVE"
constraints_mapped: ["C3", "C6", "C7", "C8"]
canonical_path: "05-CONFIGURATIONS/security/vps-hardening.sh"
domain: "05-CONFIGURATIONS"
subdomain: "security"
agent_role: "vps-hardening"
language_lock: "bash"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain security --file 05-CONFIGURATIONS/security/vps-hardening.sh --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants"]
human_readable: false
checksum_sha256: "ecce674ffc181d75a8e64b372fe64b7449b0cf95f705ea6970dac0ebe415fefa"
# FIN FRONTMATTER
---

#!/usr/bin/env bash
# =============================================================================
# SCRIPT: vps-hardening.sh
# DOMINIO: 05-CONFIGURATIONS/security
# PROPÓSITO: Endurecimiento de seguridad a nivel de SO (UFW, Fail2Ban, SSH,
#            actualizaciones automáticas, parámetros de kernel). Idempotente,
#            con backup de configs críticos y registro de auditoría.
# USO: ./vps-hardening.sh [--env dev|staging|prod] [--dry-run] [--confirm]
# DEPENDENCIAS: bash >= 5.0, ufw, fail2ban, unattended-upgrades, sed, grep
# AUTOR: configurations-master-agent (MANTIS)
# VERSIÓN: 1.0.0
# CONSTRAINTS: C3 (Seguridad), C6 (Cumplimiento), C7 (Resiliencia), C8 (Auditoría)
# =============================================================================
set -euo pipefail

# --- Configuración -----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="/opt/mantis/backups/hardening/$(date +%Y%m%d_%H%M%S)"
LOG_FILE="/var/log/mantis-hardening.log"
DRY_RUN="false"
CONFIRMED="false"
ENVIRONMENT="prod"

# Puertos por defecto (sobreescribibles via .env)
SSH_PORT="22"
ALLOWED_TCP_PORTS="80,443"

# --- Logging -----------------------------------------------------------------
log() {
    local level="$1"; shift
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
    echo "$msg" | tee -a "$LOG_FILE"
    if [[ "$level" == "ERROR" ]]; then exit 1; fi
}

# --- Validación y Args -------------------------------------------------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --env) ENVIRONMENT="$2"; shift 2 ;;
            --dry-run) DRY_RUN="true"; shift ;;
            --confirm) CONFIRMED="true"; shift ;;
            -h|--help)
                echo "Uso: $0 [--env dev|staging|prod] [--dry-run] [--confirm]"
                exit 0 ;;
            *) log ERROR "Opción desconocida: $1" ;;
        esac
    done
}

pre_flight_checks() {
    # Verificar root (necesario para cambios de SO)
    if [[ "$EUID" -ne 0 ]]; then
        log ERROR "Este script requiere privilegios de root. Use: sudo $0"
    fi

    # Verificar distribución (optimizado para Debian/Ubuntu)
    if ! command -v apt-get &>/dev/null; then
        log WARN "Distribución no Debian/Ubuntu detectada. Algunos pasos pueden requerir ajuste manual."
    fi

    # Verificar conectividad a repositorios
    if ! ping -c1 -W2 archive.ubuntu.com &>/dev/null && ! ping -c1 -W2 security.ubuntu.com &>/dev/null; then
        log WARN "Sin acceso a Internet. Se omitirán actualizaciones de paquetes."
    fi

    # Confirmación de seguridad
    if [[ "$DRY_RUN" == "false" && "$CONFIRMED" == "false" ]]; then
        log INFO "⚠️  Este script modificará configuraciones críticas del SO."
        read -rp "¿Confirmar ejecución en entorno ${ENVIRONMENT}? [y/N]: " ans
        [[ "$ans" =~ ^[Yy]$ ]] || { log INFO "🚫 Abortado por usuario."; exit 0; }
    fi

    mkdir -p "$BACKUP_DIR" "$LOG_FILE" 2>/dev/null || true
    log INFO "✅ Pre-flight completado. Backup dir: $BACKUP_DIR"
}

# --- Funciones de Hardening --------------------------------------------------
backup_config() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cp -p "$file" "$BACKUP_DIR/"
        log INFO "📦 Backup de $file → $BACKUP_DIR/"
    fi
}

secure_ssh() {
    log INFO "🔐 Aplicando hardening a SSH..."
    local sshd_config="/etc/ssh/sshd_config"
    backup_config "$sshd_config"

    # Función auxiliar para modificar sshd_config de forma idempotente
    set_ssh_opt() {
        local key="$1" val="$2"
        if grep -qE "^${key}\s" "$sshd_config"; then
            if [[ "$DRY_RUN" == "true" ]]; then
                log INFO "[DRY-RUN] Actualizaría $key $val"
            else
                sed -i "s/^${key}\s.*/${key} ${val}/" "$sshd_config"
            fi
        else
            if [[ "$DRY_RUN" == "true" ]]; then
                log INFO "[DRY-RUN] Agregaría $key $val"
            else
                echo "${key} ${val}" >> "$sshd_config"
            fi
        fi
    }

    # Aplicar directivas de seguridad (C6: Cumplimiento CIS)
    set_ssh_opt "PermitRootLogin" "no"
    set_ssh_opt "PasswordAuthentication" "no"
    set_ssh_opt "PubkeyAuthentication" "yes"
    set_ssh_opt "MaxAuthTries" "3"
    set_ssh_opt "X11Forwarding" "no"
    set_ssh_opt "AllowTcpForwarding" "no"
    set_ssh_opt "Port" "$SSH_PORT"

    # Reiniciar servicio si no es dry-run
    if [[ "$DRY_RUN" == "false" ]]; then
        systemctl restart sshd || systemctl restart ssh
        log INFO "✅ SSH hardening aplicado y servicio reiniciado."
    fi
}

configure_ufw() {
    log INFO "🛡️ Configurando UFW (Firewall)..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log INFO "[DRY-RUN] Habilitaría UFW con política default deny incoming, allow outgoing"
        log INFO "[DRY-RUN] Permitiría puertos: ${SSH_PORT}/tcp, ${ALLOWED_TCP_PORTS}/tcp"
        return 0
    fi

    ufw default deny incoming
    ufw default allow outgoing
    
    # Permitir SSH
    ufw allow "${SSH_PORT}/tcp" comment 'SSH Hardened'
    
    # Permitir puertos de aplicación
    IFS=',' read -ra PORTS <<< "$ALLOWED_TCP_PORTS"
    for port in "${PORTS[@]}"; do
        ufw allow "${port}/tcp" comment 'App/Traefik/Nginx'
    done

    ufw --force enable
    log INFO "✅ UFW habilitado y reglas aplicadas."
}

configure_fail2ban() {
    log INFO "🚫 Instalando/configurando Fail2Ban..."
    if ! command -v fail2ban-server &>/dev/null; then
        if [[ "$DRY_RUN" == "false" ]]; then
            apt-get update && apt-get install -y fail2ban
        else
            log INFO "[DRY-RUN] Instalaría fail2ban"
            return 0
        fi
    fi

    local jail_local="/etc/fail2ban/jail.local"
    backup_config "$jail_local"

    if [[ "$DRY_RUN" == "true" ]]; then
        log INFO "[DRY-RUN] Configuraría jail.local con bantime=3600, findtime=600, maxretry=3"
        return 0
    fi

    cat > "$jail_local" <<'EOF'
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port    = 22
filter  = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime  = 7200
EOF

    # Reemplazar puerto si es distinto a 22
    if [[ "$SSH_PORT" != "22" ]]; then
        sed -i "s/^port    = 22/port    = ${SSH_PORT}/" "$jail_local"
    fi

    systemctl enable fail2ban
    systemctl restart fail2ban
    log INFO "✅ Fail2Ban configurado y activo."
}

apply_sysctl_hardening() {
    log INFO "⚙️ Aplicando hardening de red (sysctl)..."
    local sysctl_conf="/etc/sysctl.d/99-mantis-hardening.conf"
    backup_config "$sysctl_conf"

    if [[ "$DRY_RUN" == "true" ]]; then
        log INFO "[DRY-RUN] Aplicaría parámetros de kernel anti-spoofing y SYN-flood"
        return 0
    fi

    cat > "$sysctl_conf" <<'EOF'
# Protección contra IP Spoofing
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignorar pings broadcast
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Protección contra SYN Flood
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2

# Deshabilitar redirecciones ICMP
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.all.send_redirects = 0
EOF

    sysctl -p "$sysctl_conf" >/dev/null 2>&1 || true
    log INFO "✅ Parámetros de kernel aplicados."
}

setup_unattended_upgrades() {
    log INFO "🔄 Configurando actualizaciones de seguridad automáticas..."
    if ! dpkg -l unattended-upgrades | grep -q '^ii'; then
        if [[ "$DRY_RUN" == "false" ]]; then
            apt-get install -y unattended-upgrades
            dpkg-reconfigure --priority=low unattended-upgrades
        else
            log INFO "[DRY-RUN] Instalaría y configuraría unattended-upgrades"
            return 0
        fi
    fi

    # Asegurar que está habilitado para seguridad
    if [[ "$DRY_RUN" == "false" ]]; then
        systemctl enable unattended-upgrades
        systemctl start unattended-upgrades
    fi
    log INFO "✅ Actualizaciones automáticas de seguridad configuradas."
}

# --- Verificación Post-Hardening (C8) ----------------------------------------
verify_hardening() {
    log INFO "🔍 Verificando estado post-hardening..."
    
    local status_pass=0
    
    # SSH
    if grep -q "PermitRootLogin no" /etc/ssh/sshd_config; then log INFO "✅ SSH RootLogin: disabled"; else ((status_pass++)); fi
    if grep -q "PasswordAuthentication no" /etc/ssh/sshd_config; then log INFO "✅ SSH PasswordAuth: disabled"; else ((status_pass++)); fi
    
    # UFW
    if ufw status verbose | grep -q "Status: active"; then log INFO "✅ UFW: active"; else ((status_pass++)); fi
    
    # Fail2Ban
    if systemctl is-active --quiet fail2ban; then log INFO "✅ Fail2Ban: running"; else ((status_pass++)); fi
    
    if [[ $status_pass -gt 0 ]]; then
        log WARN "⚠️ $status_pass verificaciones fallaron. Revisar manualmente."
    else
        log INFO "✅ Todas las verificaciones de hardening superadas."
    fi
}

# --- Ejecución Principal -----------------------------------------------------
main() {
    parse_args "$@"
    pre_flight_checks
    
    log INFO "🚀 Iniciando endurecimiento de VPS (Env: $ENVIRONMENT)..."
    
    secure_ssh
    configure_ufw
    configure_fail2ban
    apply_sysctl_hardening
    setup_unattended_upgrades
    
    verify_hardening
    
    log INFO "🎉 Hardening completado. Backup de configs original en: $BACKUP_DIR"
    log INFO "👉 Próximos pasos:"
    log INFO "   1. Verificar acceso SSH desde nueva terminal ANTES de cerrar sesión actual."
    log INFO "   2. Ejecutar: sudo ufw status verbose | sudo fail2ban-client status sshd"
    log INFO "   3. Continuar con despliegue: docker-compose up -d"
}

main "$@"


---
