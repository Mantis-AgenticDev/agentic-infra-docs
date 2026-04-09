---
title: "SSH Key Management"
category: "Infraestructura"
domain: ["seguridad", "infraestructura", "comunicaciones"]
constraints: ["C1", "C2", "C3", "C5"]
priority: "Alta"
version: "1.0.0"
last_updated: "2026-04-09"
ai_optimized: true
tags:
  - sdd/config/ssh
  - sdd/security
  - lang/es
related_files:
  - "01-RULES/03-SECURITY-RULES.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
  - "00-CONTEXT/facundo-infrastructure.md"
  - "02-SKILLS/INFRAESTRUCTURA/ufw-firewall-configuration.md"
---

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

### Checklist de Prerrequisitos

- [ ] Acceso SSH a VPS (usuario con permisos sudo)
- [ ] Terminal Linux/Mac o PuTTY/WSL (Windows)
- [ ] Par de claves SSH existente o permiso para generar una
- [ ] Conectividad de red al VPS (puerto 22 abierto)

### Tiempo Estimado

- **Generación de claves:** 5 minutos
- **Configuración de VPS:** 10 minutos
- **Validación completa:** 5 minutos
- **Total:** 20 minutos

### Cómo Usar Este Documento

1. **Si nunca generaste claves SSH:** Ir a [[#ejemplo-1-generar-par-de-claves-rsa-ed25519]]
2. **Si ya tienes claves y quieres desplegarlas:** Ir a [[#ejemplo-2-desplegar-clave-pública-en-vps]]
3. **Si necesitas acceso cross-VPS:** Ir a [[#ejemplo-3-configurar-trust-entre-vps]]
4. **Si quieres automatizar con n8n:** Ir a [[#ejemplo-5-script-de-rotación-de-claves]]

### Qué Hacer Si Falla

| Error | Causa | Solución |
|-------|-------|----------|
| `Permission denied (publickey)` | Clave no agregada al agente | Ejecutar `ssh-add ~/.ssh/id_ed25519` |
| `Connection refused` | Puerto SSH cerrado | Verificar UFW: `sudo ufw status` |
| `Key refused` | Permisos incorrectos en archivo | `chmod 600 ~/.ssh/authorized_keys` |
| `Host key verification failed` | Host desconocido | `ssh-keygen -R hostname` |
| `Timeout` | Firewall bloqueando | Revisar reglas en painel do VPS |

### Glosario Rápido

| Término | Significado | Ejemplo |
|---------|-------------|----------|
| **Clave pública** | Archivo `.pub` que se copia al servidor | `id_ed25519.pub` |
| **Clave privada** | Archivo sin extensión que permanece local | `id_ed25519` |
| **SSH Agent** | Programa que guarda claves en memoria | `ssh-agent` |
| **Authorized_keys** | Archivo que lista claves públicas permitidas | `~/.ssh/authorized_keys` |
| **Fingerprint** | Hash único de la clave para verificación | `SHA256:xxxxx` |

---

## 🎯 Propósito y Alcance

### Propósito

Este documento establece el procedimiento estándar para la **generación, despliegue y gestión de claves SSH** en la infraestructura de 3 VPS de Mantis Agentic. El objetivo es garantizar autenticación segura sin passwords, cumplir con las constraints de seguridad (C3) y facilitar la automatización cross-VPS.

### Alcance

- **VPS cubiertos:** VPS-1 (n8n/uazapi), VPS-2 (EspoCRM/MySQL/Qdrant), VPS-3 (n8n/uazapi failover)
- **Usuarios afectados:** root, usuario_deploy, n8n_service
- **Servicios que usan SSH:** rsync, git, tunnel SSH, automatización n8n

### Constraints Aplicadas

| Constraint | Descripción | Aplicación |
|------------|-------------|------------|
| **C1** | Máx 4GB RAM/VPS | Sin impacto directo |
| **C2** | Máx 1 vCPU | Sin impacto directo |
| **C3** | DB internas nunca expuestas | SSH tunneling para MySQL/Qdrant |
| **C5** | Backup diario + SHA256 | Claves en backups encriptados |

### Objetivos de Seguridad

1. **Autenticación sin password:** Eliminar passwords débiles
2. **Aislamiento por usuario:** Cada servicio tiene su propia clave
3. **Traza de auditoría:** Logs de conexión con timestamp y origen
4. **Rotación periódica:** Cambio de claves cada 90 días

---

## 📐 Fundamentos (De 0 a Intermedio)

### Conceptos Básicos de SSH

#### Cómo Funciona la Autenticación por Claves

```
[Tu Computadora]                    [VPS]
     │                                  │
     │  1. Solicitud conexión           │
     │ ─────────────────────────────►   │
     │                                  │
     │  2. Servidor envía challenge     │
     │ ◄─────────────────────────────   │
     │                                  │
     │  3. Tu computadora firma con     │
     │     clave PRIVADA                │
     │ ─────────────────────────────►   │
     │                                  │
     │  4. Servidor verifica con        │
     │     clave PÚBLICA (authorized)   │
     │     ✅ Si coincide → ACCESO      │ 
     │                                  │
```

### Tipos de Algoritmos de Clave

| Algoritmo | Bits | Seguridad | Compatibilidad | Recomendación |
|-----------|------|-----------|----------------|---------------|
| **RSA** | 4096 | Alta | Universal | Legacy systems |
| **ED25519** | 256 | Muy Alta | Moderno | ✅ Producción |
| **ECDSA** | 256 | Alta | Moderada | Alternativa |

**Selección:** Usar **ED25519** como estándar. RSA solo para servidores antiguos que no soporten ED25519.

### Estructura de Archivos SSH

```
~/.ssh/
├── id_ed25519              # Clave PRIVADA (NUNCA compartir)
├── id_ed25519.pub          # Clave PÚBLICA (se copia al servidor)
├── id_rsa                  # Clave RSA legacy (si aplica)
├── id_rsa.pub
├── authorized_keys         # Lista de claves públicas permitidas
├── known_hosts             # Huellas de servidores conocidos
├── config                  # Configuración de conexiones
└── mantis_vps1             # Clave específica para VPS-1
```

### Permisos de Archivos (CRÍTICO)

| Archivo | Permiso | Comando |
|---------|---------|---------|
| Directorio `~/.ssh` | 700 | `chmod 700 ~/.ssh` |
| Clave privada | 600 | `chmod 600 ~/.ssh/id_ed25519` |
| Clave pública | 644 | `chmod 644 ~/.ssh/id_ed25519.pub` |
| `authorized_keys` | 600 | `chmod 600 ~/.ssh/authorized_keys` |
| `config` | 600 | `chmod 600 ~/.ssh/config` |

---

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

### Topología de Claves SSH

```
┌─────────────────────────────────────────────────────────────────────┐
│                        TU COMPUTADORA LOCAL                         │
│                                                                     │
│  ~/.ssh/                                                            │
│  ├── id_ed25519_mantis        # Clave principal (producción)        │
│  ├── id_ed25519_mantis.pub    # Se copia a todos los VPS            │
│  ├── id_ed25519_n8n_hooks    # Clave específica para webhooks       │
│  └── config                  # Hosts definidos                      │
└─────────────────────────────────────────────────────────────────────┘
                    │
                    │ Clave pública copiada
                    ▼
┌───────────────────┬───────────────────┬───────────────────┐
│      VPS-1        │      VPS-2        │      VPS-3        │
│   São Paulo       │   São Paulo       │   São Paulo       │
│                   │                   │                   │
│ ~/.ssh/           │ ~/.ssh/           │ ~/.ssh/           │
│ authorized_keys:  │ authorized_keys:  │ authorized_keys:  │
│ • Tu clave        │ • Tu clave        │ • Tu clave        │
│ • VPS-3 (trust)   │ • VPS-1 (trust)   │ • VPS-1 (trust)   │
│ • VPS-2 (trust)   │ • VPS-1 (trust)   │                   │
│                   │                   │                   │
│ root + deploy     │ root + espocrm    │ root + deploy     │
└───────────────────┴───────────────────┴───────────────────┘
```

### Límites de Conexiones SSH Concurrentes

| Servicio | Límite | Archivo Config |
|----------|--------|----------------|
| SSH demonio (`sshd`) | 10 conexiones/VPS | `/etc/ssh/sshd_config` |
| Agent forwarding | 5 saltos máximo | `~/.ssh/config` |
| Conexiones por IP | 5 intentos/min | `fail2ban` |

### Configuración sshd para VPS 4GB RAM

```bash
# /etc/ssh/sshd_config optimizado

# Conexiones concurrentes
MaxSessions 10

# Timeouts (C1: 4GB RAM - sin impacto)
ClientAliveInterval 60
ClientAliveCountMax 3

# Autenticación
PermitRootLogin without-password  # Solo con clave, no password
PubkeyAuthentication yes
PasswordAuthentication no         # PROHIBIDO en producción
PermitEmptyPasswords no

# Logging
SyslogFacility AUTH
LogLevel INFO

# Ciphers modernos
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
```

---

## 🔗 Conexión Local vs Externa / Cross-VPS

### Conexión Local (Tu Computadora → VPS)

```
┌──────────────────┐     Internet      ┌──────────────────┐
│  Tu Computadora  │ ───────────────►  │     VPS-X        │
│                  │    Puerto 22      │  São Paulo       │
│  ssh -i ~/.ssh/  │                   │  n8n / MySQL /   │
│  id_ed25519      │                   │  EspoCRM         │
│  mantis@IP_VPS   │                   │                  │
└──────────────────┘                   └──────────────────┘
```

**Comando típico:**
```bash
ssh -i ~/.ssh/id_ed25519_mantis -p 22 mantis@186.234.x.x
```

### Conexión Cross-VPS (VPS-1 → VPS-2)

```
┌──────────────────┐                   ┌──────────────────┐
│      VPS-1       │ ──── SSH ────────►│      VPS-2       │
│   São Paulo      │    Tunnel         │   São Paulo      │
│                  │                   │                  │
│  n8n necesita    │  ssh -L 3306:     │  MySQL (3306)    │
│  acceder MySQL   │  localhost:3306   │  Qdrant (6333)   │
│  (VPS-2)         │  user@VPS2_IP     │  EspoCRM (80)    │
└──────────────────┘                   └──────────────────┘
```

**Script de túnel SSH para MySQL/Qdrant:**
```bash
# /opt/mantis/scripts/ssh-tunnel-vps2.sh
#!/bin/bash
set -euo pipefail

REMOTE_USER="mantis"
REMOTE_HOST="186.234.x.x"  # IP VPS-2
LOCAL_PORT_MYSQL="3306"
LOCAL_PORT_QDRANT="6333"

# túneles en background
ssh -f -N -L "${LOCAL_PORT_MYSQL}:localhost:3306" \
        -L "${LOCAL_PORT_QDRANT}:localhost:6333" \
        "${REMOTE_USER}@${REMOTE_HOST}"

echo "Túneles activos: MySQL:${LOCAL_PORT_MYSQL}, Qdrant:${LOCAL_PORT_QDRANT}"
```

### Configuración SSH Config para Cross-VPS

```bash
# ~/.ssh/config

# Tu acceso directo a VPS
Host vps1
    HostName 186.234.x.10
    User mantis
    IdentityFile ~/.ssh/id_ed25519_mantis
    Port 22
    ForwardAgent yes

Host vps2
    HostName 186.234.x.20
    User mantis
    IdentityFile ~/.ssh/id_ed25519_mantis
    Port 22

Host vps3
    HostName 186.234.x.30
    User mantis
    IdentityFile ~/.ssh/id_ed25519_mantis
    Port 22

# Cross-VPS trust (desde VPS-1)
Host vps2-mysql
    HostName localhost
    User mantis
    IdentityFile ~/.ssh/id_ed25519_vps_cross
    Port 3333
    ProxyJump vps1
```

---

## 🛠️ 5 Ejemplos de Configuración (Copy-Paste Validables)

### EJEMPLO 1: Generar Par de Claves RSA/ED25519

**Objetivo:** Crear par de claves ED25519 para acceso a producción.

```bash
# 1. Crear directorio si no existe
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# 2. Generar par de claves ED25519 (recomendado)
ssh-keygen -t ed25519 \
  -C "mantis-agentic-$(date +%Y%m%d)" \
  -f ~/.ssh/id_ed25519_mantis

# 3. Generar par de claves para cross-VPS
ssh-keygen -t ed25519 \
  -C "mantis-cross-vps-$(date +%Y%m%d)" \
  -f ~/.ssh/id_ed25519_vps_cross

# 4. Verificar fingerprints
ssh-keygen -lf ~/.ssh/id_ed25519_mantis.pub
ssh-keygen -lf ~/.ssh/id_ed25519_vps_cross.pub

# 5. Respaldar clave privada (encriptado)
# IMPORTANTE: Guardar en gestor de passwords
cp ~/.ssh/id_ed25519_mantis ~/mantis_keys/backup/
```

✅ **Deberías ver:**
```
2048 SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx mantis-agentic-20260409 (RSA)
256 SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx mantis-cross-vps-20260409 (ED25519)
```

❌ **Si ves esto... → Ve a Troubleshooting:**
- `Bad permissions`: `chmod 600 ~/.ssh/id_ed25519_mantis`
- `Key file not found`: Verificar que el directorio existe

---

### EJEMPLO 2: Desplegar Clave Pública en VPS

**Objetivo:** Agregar tu clave pública al archivo `authorized_keys` de un VPS.

```bash
# OPCIÓN A: Usando ssh-copy-id (automático)
ssh-copy-id -i ~/.ssh/id_ed25519_mantis.pub \
  mantis@186.234.x.10

# OPCIÓN B: Manual (si ssh-copy-id no funciona)
# 1. Copiar clave manualmente
cat ~/.ssh/id_ed25519_mantis.pub
# Salida: ssh-ed25519 AAAA... mantis-agentic-20260409

# 2. Conectar al VPS y agregar
ssh -i ~/.ssh/id_ed25519_mantis mantis@186.234.x.10

# 3. En el VPS, crear archivo authorized_keys
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "ssh-ed25519 AAAA... mantis-agentic-20260409" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# 4. Verificar
cat ~/.ssh/authorized_keys

# 5. Agregar al agent (Linux/Mac)
ssh-add ~/.ssh/id_ed25519_mantis
```

✅ **Deberías ver:** `Number of key(s) added: 1`

❌ **Si ves esto... → Ve a Troubleshooting 3:**
- `Permission denied (publickey)`: Verificar permisos y contenido de authorized_keys

---

### EJEMPLO 3: Configurar Trust Entre VPS (Cross-VPS)

**Objetivo:** Permitir que VPS-1 se conecte a VPS-2 sin password para rsync/backup.

```bash
# EN VPS-1 (origen del túnel)
# 1. Generar clave específica si no existe
sudo -u mantis ssh-keygen -t ed25519 \
  -C "vps1-to-vps2-$(date +%Y%m%d)" \
  -f /home/mantis/.ssh/id_ed25519_vps12

# 2. Copiar clave pública a VPS-2
ssh-copy-id -i /home/mantis/.ssh/id_ed25519_vps12.pub \
  mantis@186.234.x.20

# 3. Verificar conexión sin password
ssh -i /home/mantis/.ssh/id_ed25519_vps12 \
  mantis@186.234.x.20 "hostname && uptime"

# 4. Agregar a known_hosts automáticamente
ssh-keyscan -H 186.234.x.20 >> ~/.ssh/known_hosts 2>/dev/null

# 5. Probar rsync
rsync -avz --progress \
  -e "ssh -i /home/mantis/.ssh/id_ed25519_vps12" \
  /var/backups/ \
  mantis@186.234.x.20:/var/backups/vps1/
```

✅ **Deberías ver:** `mantis@vps2:~$` (prompt del VPS-2 sin pedir password)

❌ **Si ves esto... → Ve a Troubleshooting 2:**
- `Host key verification failed`: `ssh-keygen -R 186.234.x.20`

---

### EJEMPLO 4: Configurar SSH Config Multi-Host

**Objetivo:** Definir aliases y configuraciones en `~/.ssh/config` para acceso rápido.

```bash
# ~/.ssh/config

# ==================== MANTIS AGENTIC ====================

# Acceso personal a VPS
Host vps1
    HostName 186.234.x.10
    User mantis
    IdentityFile ~/.ssh/id_ed25519_mantis
    Port 22
    ForwardAgent yes
    AddKeysToAgent yes
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host vps2
    HostName 186.234.x.20
    User mantis
    IdentityFile ~/.ssh/id_ed25519_mantis
    Port 22
    ForwardAgent yes

Host vps3
    HostName 186.234.x.30
    User mantis
    IdentityFile ~/.ssh/id_ed25519_mantis
    Port 22

# Cross-VPS connections (usar desde vps1)
Host vps1-to-vps2
    HostName 186.234.x.20
    User mantis
    IdentityFile ~/.ssh/id_ed25519_vps_cross
    Port 22
    ProxyJump vps1

# Aliases para servicios (túneles)
Host mysql-vps2
    HostName localhost
    User mantis
    IdentityFile ~/.ssh/id_ed25519_vps_cross
    Port 3333
```

**Uso:**
```bash
# Conexión directa
ssh vps1

# rsync usando alias
rsync -avz -e "ssh -i ~/.ssh/id_ed25519_vps_cross" \
  /data/ vps1-to-vps2:/data/
```

✅ **Deberías ver:** Conexión exitosa con alias `vps1`

❌ **Si ves esto... → Ve a Troubleshooting 4:**
- `Bad configuration option`: Verificar sintaxis del archivo config

---

### EJEMPLO 5: Script de Rotación de Claves

**Objetivo:** Rotar claves SSH cada 90 días con script automatizado.

```bash
#!/bin/bash
# /opt/mantis/scripts/rotate-ssh-keys.sh
# Rotation: cada 90 días

set -euo pipefail

LOG_FILE="/var/log/mantis/ssh-rotate-$(date +%Y%m%d).log"
KEY_DIR="/home/mantis/.ssh"
BACKUP_DIR="/var/backups/ssh-keys/$(date +%Y%m%d)"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Crear directorio de backup
mkdir -p "$BACKUP_DIR"

# 1. Generar nueva clave
log "Generando nueva clave ED25519..."
ssh-keygen -t ed25519 \
  -C "mantis-rotated-$(date +%Y%m%d)" \
  -f "${KEY_DIR}/id_ed25519_mantis_new" \
  -N ""  # Sin passphrase para automatización

# 2. Respaldar clave anterior
if [[ -f "${KEY_DIR}/id_ed25519_mantis" ]]; then
    cp "${KEY_DIR}/id_ed25519_mantis" "${BACKUP_DIR}/"
    log "Clave anterior respaldada en ${BACKUP_DIR}"
fi

# 3. Copiar nueva clave a todos los VPS
VPS_IPS=("186.234.x.10" "186.234.x.20" "186.234.x.30")

for vps_ip in "${VPS_IPS[@]}"; do
    log "Desplegando nueva clave en ${vps_ip}..."
    ssh-copy-id -i "${KEY_DIR}/id_ed25519_mantis_new.pub" \
      -o ConnectTimeout=10 \
      "mantis@${vps_ip}" 2>/dev/null || \
      log "WARN: Falló despliegue en ${vps_ip}"
done

# 4. Reemplazar clave activa
mv "${KEY_DIR}/id_ed25519_mantis_new" "${KEY_DIR}/id_ed25519_mantis"
mv "${KEY_DIR}/id_ed25519_mantis_new.pub" "${KEY_DIR}/id_ed25519_mantis.pub"
chmod 600 "${KEY_DIR}/id_ed25519_mantis"
chmod 644 "${KEY_DIR}/id_ed25519_mantis.pub"

# 5. Verificar conexión
log "Verificando nueva clave..."
ssh -o ConnectTimeout=10 mantis@186.234.x.10 "echo OK" && \
  log "Nueva clave verificada exitosamente"

# 6. Generar checksum SHA256
log "Generando checksum..."
sha256sum "${KEY_DIR}/id_ed25519_mantis" > "${KEY_DIR}/id_ed25519_mantis.sha256"

log "Rotación completada"
```

**Ejecución via cron (90 días):**
```bash
# /etc/cron.d/mantis-ssh-rotate
# Rotar cada 90 días a las 3 AM
0 3 */90 * * root /opt/mantis/scripts/rotate-ssh-keys.sh
```

✅ **Deberías ver:** Archivo de log con `Rotación completada`

❌ **Si ves esto... → Ve a Troubleshooting 5:**
- `Permission denied`: Verificar que el script se ejecuta como root o mantis

---

## 🐞 5 Eventos/Problemas Críticos y Troubleshooting

| Error Exacto (copiable) | Causa Raíz (lenguaje simple) | Comando de Diagnóstico | Solución Paso a Paso | Constraint Afectado (C#) |
|------------------------|------------------------------|------------------------|---------------------|--------------------------|
| `Permission denied (publickey)` | La clave pública no está en `authorized_keys` del VPS | `ssh -vvv user@host` | 1. Verificar que clave `.pub` fue copiada 2. `cat ~/.ssh/authorized_keys` en VPS 3. Comparar fingerprint: `ssh-keygen -lf ~/.ssh/id_ed25519.pub` 4. Agregar si falta | C3 |
| `Connection refused` | Puerto 22 bloqueado por firewall | `sudo ufw status` | 1. Verificar que UFW permite SSH 2. `sudo ufw allow 22/tcp` 3. Verificar fail2ban no baneó tu IP 4. Check `sudo systemctl status sshd` | C3 |
| `Bad permissions 0644 for 'id_ed25519': Unprotected private key file` | Permisos muy abiertos en clave privada | `ls -la ~/.ssh/` | 1. `chmod 700 ~/.ssh` 2. `chmod 600 ~/.ssh/id_ed25519` 3. `chmod 644 ~/.ssh/id_ed25519.pub` 4. Verificar que solo tu usuario tiene acceso | C5 |
| `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!` | La IP del VPS cambió (nueva instalación) | `ssh-keygen -R host` | 1. `ssh-keygen -R 186.234.x.10` 2. `ssh-keygen -R hostname` 3. Reconectar y aceptar nueva huella 4. Verificar que no es ataque MITM | C3 |
| `Agent admitted failure to sign using the key` | SSH Agent no tiene la clave cargada | `ssh-add -l` | 1. `ssh-add ~/.ssh/id_ed25519_mantis` 2. `ssh-add -l` para verificar 3. Si falla, verificar permisos de clave 4. En Mac: `ssh-add --apple-use-keychain` | C5 |

### Troubleshooting Detallado 1: Permission Denied (Publickey)

**Pasos de diagnóstico:**

```bash
# 1. Verificar qué clave estás usando
ssh -v -i ~/.ssh/id_ed25519_mantis user@host

# 2. Ver contenido de authorized_keys en VPS
ssh user@host "cat ~/.ssh/authorized_keys"

# 3. Comparar fingerprints
# En tu máquina:
ssh-keygen -lf ~/.ssh/id_ed25519_mantis.pub

# En VPS:
ssh user@host "ssh-keygen -lf ~/.ssh/authorized_keys"

# 4. Ver logs de sshd en VPS
ssh user@host "sudo tail -f /var/log/auth.log | grep sshd"
```

---

## ✅ Validación SDD y Comandos de Verificación

### Checklist de Validación

```bash
#!/bin/bash
# /opt/mantis/scripts/validate-ssh-config.sh

ERRORS=0

echo "=== Validación SSH - Mantis Agentic ==="

# 1. Verificar permisos de directorio .ssh
if [[ $(stat -c %a ~/.ssh) != "700" ]]; then
    echo "❌ ~/.ssh tiene permisos $(stat -c %a ~/.ssh), esperado 700"
    ERRORS=$((ERRORS+1))
else
    echo "✅ ~/.ssh permisos correctos"
fi

# 2. Verificar permisos de clave privada
if [[ $(stat -c %a ~/.ssh/id_ed25519_mantis) != "600" ]]; then
    echo "❌ Clave privada tiene permisos $(stat -c %a ~/.ssh/id_ed25519_mantis)"
    ERRORS=$((ERRORS+1))
else
    echo "✅ Clave privada permisos correctos"
fi

# 3. Verificar que sshd_config permite pubkey
if ssh user@host "grep -q 'PubkeyAuthentication yes' /etc/ssh/sshd_config"; then
    echo "✅ PubkeyAuthentication habilitado"
else
    echo "❌ PubkeyAuthentication no está habilitado"
    ERRORS=$((ERRORS+1))
fi

# 4. Verificar que password auth está deshabilitado
if ssh user@host "grep -q 'PasswordAuthentication no' /etc/ssh/sshd_config"; then
    echo "✅ PasswordAuthentication deshabilitado"
else
    echo "⚠️ PasswordAuthentication podría estar habilitado"
fi

# 5. Test de conexión
if timeout 10 ssh -o ConnectTimeout=5 \
  -o StrictHostKeyChecking=no \
  user@host "echo OK" > /dev/null 2>&1; then
    echo "✅ Conexión SSH exitosa"
else
    echo "❌ Conexión SSH falló"
    ERRORS=$((ERRORS+1))
fi

# 6. Verificar fingerprints en known_hosts
echo ""
echo "=== Fingerprints de VPS ==="
for host in vps1 vps2 vps3; do
    ssh-keygen -lf ~/.ssh/known_hosts 2>/dev/null | grep -i "$host" || echo "  ${host}: sin fingerprint"
done

echo ""
if [[ $ERRORS -eq 0 ]]; then
    echo "🎉 Validación SSH: TODOS LOS CHECKS PASARON"
    exit 0
else
    echo "❌ Validación SSH: $ERRORS ERRORES ENCONTRADOS"
    exit 1
fi
```

### Comandos de Verificación Rápida

```bash
# Verificar agente SSH
ssh-add -l

# Ver fingerprints de clave
ssh-keygen -lf ~/.ssh/id_ed25519_mantis.pub

# Ver claves en authorized_keys de VPS
ssh user@host "wc -l ~/.ssh/authorized_keys"

# Test de conexión rápida
ssh -o BatchMode=yes -o ConnectTimeout=5 user@host "echo OK"

# Ver logs de autenticación
ssh user@host "sudo tail -20 /var/log/auth.log | grep sshd"
```

---

## 🔗 Referencias Cruzadas y Glosario

### Archivos Relacionados

| Archivo | Descripción | Relevancia |
|---------|-------------|------------|
| [[01-RULES/03-SECURITY-RULES.md]] | Reglas de seguridad SSH y hardening | C3, C5 |
| [[01-RULES/02-RESOURCE-GUARDRAILS.md]] | Límites de recursos VPS | C1, C2 |
| [[00-CONTEXT/facundo-infrastructure.md]] | Arquitectura de 3 VPS | Topología |
| [[02-SKILLS/INFRAESTRUCTURA/ufw-firewall-configuration.md]] | Configuración UFW | Puerto 22 |
| [[02-SKILLS/INFRAESTRUCTURA/fail2ban-configuration.md]] | Protección contra brute force | SSH |

### Glosario Completo

| Término | Definición | Contexto |
|---------|------------|----------|
| **Authorized_keys** | Archivo que contiene claves públicas autorizadas para login SSH | `~/.ssh/authorized_keys` |
| **ED25519** | Algoritmo de firma digital de curva elíptica, 256 bits, muy seguro | Algoritmo recomendado |
| **Fingerprint** | Hash SHA256 de la clave pública, usado para verificar identidad | `ssh-keygen -lf` |
| **Known_hosts** | Archivo que almacena fingerprints de hosts conocidos | Previene MITM |
| **ProxyJump** | Conexión a través de un host intermedio (bastion) | Acceso cross-VPS |
| **SSH Agent** | Programa que mantiene claves en memoria para evitar escribir passphrase | `ssh-agent`, `ssh-add` |
| **SSH Config** | Archivo de configuración para aliases y opciones por host | `~/.ssh/config` |
| **Túnel SSH** | Redirección de puertos local/remota a través de conexión SSH | `ssh -L` |

### Variables de Entorno Relacionadas

```bash
# ~/.bashrc o /etc/environment

# SSH Agent
export SSH_AUTH_SOCK="$HOME/.ssh/ssh-agent.sock"

# Aliases de conexión rápida
alias vps1='ssh -i ~/.ssh/id_ed25519_mantis mantis@186.234.x.10'
alias vps2='ssh -i ~/.ssh/id_ed25519_mantis mantis@186.234.x.20'
alias vps3='ssh -i ~/.ssh/id_ed25519_mantis mantis@186.234.x.30'

# Tunnel MySQL
alias tunnel-mysql='ssh -L 3306:localhost:3306 mantis@186.234.x.20 -fN'
```

### URLs Raw para IAs

```
Base: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/

https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/02-SKILLS/INFRAESTRUCTURA/ssh-key-management.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/01-RULES/03-SECURITY-RULES.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/00-CONTEXT/facundo-infrastructure.md
```

---

**Versión 1.0.0 - 2026-04-09 - Mantis-AgenticDev**
**Licencia:** Creative Commons para uso interno del proyecto
