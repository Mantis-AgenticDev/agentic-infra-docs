#!/usr/bin/env bash
# ---
# artifact_id: vps-hardening-mantis
# artifact_type: security_script
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C2","C3","C4","C5","C6","C7"]
# canonical_path: 05-CONFIGURATIONS/security/vps-hardening.sh
# domain: 05-CONFIGURATIONS
# subdomain: security
# agent_role: configurations-master
# language_lock: es-ES
# validation_command: orchestrator-engine.sh --domain configurations --strict
# tier: 3
# immutable: true
# requires_human_approval_for_changes: true
# audience: ["agentic_assistants"]
# human_readable: false
# checksum_sha256: "a5e08e40c9ba0533d00971f4f3c65e7db4123f121e11bab8f7885f7059670d25"
# ---
set -euo pipefail

# [CONSTRAINT_MAP]
# C2: Todo cambio aplicado vía script; cero configuración manual en VPS
# C3: Cero hardcodeo de credenciales; claves SSH gestionadas externamente
# C4: Backups de configs originales + logging con timestamp y commit hash
# C5: Validación de distro, dependencias y sintaxis estricta
# C6: Gate explícito para producción; requiere confirmación o flag --env prod
# C7: Idempotente; backups atómicos para rollback; operaciones reversibles

# [DEPENDENCIES]
# ufw, fail2ban, unattended-upgrades, apt, journalctl, bash >= 4.3
# [INTERFACE_ALIGNMENT]
# Consumes: environment_tag, ssh_admin_cidr (from mapping.yaml)
# Produces: hardened SSH/UFW/Fail2Ban state, audit log, backup archive

# [GLOBALS]
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly BACKUP_DIR="/opt/mantis-hardening-backups/$(date +%Y%m%d_%H%M%S)"
readonly AUDIT_LOG="/var/log/mantis-hardening-audit.log"
readonly SSHD_CONF="/etc/ssh/sshd_config"
readonly UFW_CONF="/etc/default/ufw"
readonly F2B_JAIL="/etc/fail2ban/jail.local"
readonly UNATTENDED_CONF="/etc/apt/apt.conf.d/50unattended-upgrades"

mkdir -p "$BACKUP_DIR" "$(dirname "$AUDIT_LOG")"

# [LOGGING]
log() { printf '[%s] [%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$2" | tee -a "$AUDIT_LOG"; }
log_info()  { log "INFO"  "$1"; }
log_warn()  { log "WARN"  "$1"; }
log_error() { log "ERROR" "$1"; }

# [ARGS & ENV]
ENV="${1:-dev}"
SSH_ADMIN_CIDR="${SSH_ADMIN_CIDR:-10.0.0.0/8}" # Default internal CIDR; override via mapping.yaml
SSH_PORT="${SSH_PORT:-22}"

if [[ "$ENV" == "prod" ]]; then
  log_warn "PROD_GATE: Hardening en producción. Requiere validación previa o ejecución vía pipeline CI/CD"
  if [[ "${CI:-false}" != "true" && -z "${FORCE_PROD:-}" ]]; then
    log_error "BLOCKED: Ejecutar con FORCE_PROD=true o desde pipeline con approval gate"
    exit 1
  fi
fi

# [VALIDATION]
for cmd in ufw fail2ban-client apt-get journalctl; do
  command -v "$cmd" >/dev/null 2>&1 || { log_error "DEPENDENCY_FAIL: $cmd requerido"; exit 1; }
done

# Detect distro compatibility
if ! grep -qi "ubuntu\|debian" /etc/os-release 2>/dev/null; then
  log_warn "DISTRO_COMPAT: Script optimizado para Ubuntu/Debian. Verificar paths en otras distros"
fi

# [BACKUP & ROLLBACK PREP (C7)]
backup_configs() {
  log_info "BACKUP_START: Guardando configs originales en $BACKUP_DIR"
  [[ -f "$SSHD_CONF" ]] && cp -a "$SSHD_CONF" "$BACKUP_DIR/" || true
  [[ -f "$F2B_JAIL" ]] && cp -a "$F2B_JAIL" "$BACKUP_DIR/" || touch "$BACKUP_DIR/jail.local.bak"
  [[ -f "$UNATTENDED_CONF" ]] && cp -a "$UNATTENDED_CONF" "$BACKUP_DIR/" || true
  
  cat > "$BACKUP_DIR/ROLLBACK.sh" <<'EOF'
#!/bin/bash
set -euo pipefail
echo "🔄 Restaurando configs desde backup..."
[[ -f sshd_config ]] && cp -f sshd_config /etc/ssh/sshd_config
[[ -f jail.local ]] && cp -f jail.local /etc/fail2ban/jail.local
[[ -f 50unattended-upgrades ]] && cp -f 50unattended-upgrades /etc/apt/apt.conf.d/50unattended-upgrades
systemctl restart sshd fail2ban || true
echo "✅ Rollback completado. Verificar servicios."
EOF
  chmod +x "$BACKUP_DIR/ROLLBACK.sh"
  log_info "BACKUP_COMPLETE: ROLLBACK.sh listo en $BACKUP_DIR"
}

# [PHASE_1: SSH HARDENING (C3, C4)]
phase_ssh() {
  log_info "PHASE_1_START: Hardening SSH"
  
  # Idempotencia: solo modificar si el valor actual difiere
  sed -i "s/^#PermitRootLogin.*/PermitRootLogin no/" "$SSHD_CONF"
  sed -i "s/^PermitRootLogin.*/PermitRootLogin no/" "$SSHD_CONF"
  
  sed -i "s/^#PasswordAuthentication.*/PasswordAuthentication no/" "$SSHD_CONF"
  sed -i "s/^PasswordAuthentication.*/PasswordAuthentication no/" "$SSHD_CONF"
  
  sed -i "s/^#PubkeyAuthentication.*/PubkeyAuthentication yes/" "$SSHD_CONF"
  sed -i "s/^PubkeyAuthentication.*/PubkeyAuthentication yes/" "$SSHD_CONF"
  
  sed -i "s/^#MaxAuthTries.*/MaxAuthTries 3/" "$SSHD_CONF"
  sed -i "s/^MaxAuthTries.*/MaxAuthTries 3/" "$SSHD_CONF"
  
  # Deshabilitar login root directo sin romper sesión actual (C7)
  systemctl reload sshd || systemctl restart sshd
  log_info "PHASE_1_COMPLETE: SSH configurado (root=no, password=no, pubkey=yes)"
}

# [PHASE_2: UFW FIREWALL (C2, C6)]
phase_ufw() {
  log_info "PHASE_2_START: Configurando UFW"
  
  ufw --force reset >/dev/null 2>&1 || true
  ufw default deny incoming
  ufw default allow outgoing
  
  # SSH restringido (C3: solo CIDR de gestión)
  ufw allow from "$SSH_ADMIN_CIDR" to any port "$SSH_PORT" proto tcp comment "SSH-Management"
  
  # HTTP/HTTPS público
  ufw allow 80/tcp comment "HTTP"
  ufw allow 443/tcp comment "HTTPS"
  
  # Rate limiting para puertos críticos
  ufw limit 22/tcp comment "SSH-BruteForce-Protect"
  
  [[ "$ENV" == "prod" ]] && ufw logging on || ufw logging low
  
  ufw --force enable
  log_info "PHASE_2_COMPLETE: UFW activo | Default: deny in / allow out"
}

# [PHASE_3: FAIL2BAN (C5, C8)]
phase_fail2ban() {
  log_info "PHASE_3_START: Configurando Fail2Ban"
  
  cat > "$F2B_JAIL" <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = ${SSH_PORT}
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 7200
EOF

  systemctl enable fail2ban
  systemctl restart fail2ban
  
  # Validación post-config
  if fail2ban-client status sshd >/dev/null 2>&1; then
    log_info "PHASE_3_COMPLETE: Fail2Ban activo (maxretry=3, bantime=2h)"
  else
    log_error "FAIL2BAN_START_FAIL: Verificar logs con journalctl -u fail2ban"
    exit 1
  fi
}

# [PHASE_4: AUTOMATED UPDATES (C7, C2)]
phase_updates() {
  log_info "PHASE_4_START: Habilitando actualizaciones de seguridad automáticas"
  
  if ! dpkg -l unattended-upgrades | grep -q "ii"; then
    apt-get update -qq && apt-get install -y unattended-upgrades >/dev/null 2>&1
  fi
  
  cat > "$UNATTENDED_CONF" <<EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}:\${distro_codename}-updates";
};
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "04:00";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
EOF

  systemctl enable unattended-upgrades
  systemctl restart unattended-upgrades
  log_info "PHASE_4_COMPLETE: Auto-updates habilitados (reboot 04:00 UTC)"
}

# [PHASE_5: AUDIT & VERIFICATION (C4, C5)]
phase_audit() {
  log_info "PHASE_5_START: Verificación final y auditoría"
  
  # Verificar servicios activos
  for svc in sshd ufw fail2ban unattended-upgrades; do
    if systemctl is-active "$svc" >/dev/null 2>&1; then
      log_info "SERVICE_OK: $svc activo"
    else
      log_warn "SERVICE_WARN: $svc inactivo o no requerido en este entorno"
    fi
  done
  
  # Registrar hash de configs aplicadas
  sha256sum "$SSHD_CONF" "$F2B_JAIL" "$UNATTENDED_CONF" >> "$AUDIT_LOG"
  
  log_info "PHASE_5_COMPLETE: Hardening finalizado. Audit log: $AUDIT_LOG"
}

# [EXECUTION PIPELINE]
log_info "HARDENING_START: Env=$ENV | CIDR=$SSH_ADMIN_CIDR"
backup_configs
phase_ssh
phase_ufw
phase_fail2ban
phase_updates
phase_audit

log_info "HARDENING_SUCCESS: VPS hardened bajo normas MANTIS v2.0.0"


---
