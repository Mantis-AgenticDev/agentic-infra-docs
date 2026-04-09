---
title: "VPS Interconnection"
category: "Infraestructura"
domain: ["infraestructura", "redes", "cross-vps"]
constraints: ["C1", "C2", "C3", "C4", "C5"]
priority: "Alta"
version: "1.0.0"
last_updated: "2026-04-09"
ai_optimized: true
tags:
  - sdd/config/vps
  - sdd/network
  - sdd/cross-vps
  - lang/es
related_files:
  - "01-RULES/01-ARCHITECTURE-RULES.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
  - "01-RULES/03-SECURITY-RULES.md"
  - "01-RULES/06-MULTITENANCY-RULES.md"
  - "00-CONTEXT/facundo-infrastructure.md"
  - "02-SKILLS/INFRAESTRUCTURA/ssh-key-management.md"
  - "02-SKILLS/INFRAESTRUCTURA/ufw-firewall-configuration.md"
  - "02-SKILLS/INFRAESTRUCTURA/ssh-tunnels-remote-services.md"
---

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

### Checklist de Prerrequisitos

- [ ] 3 VPS en Hostinger KVM1 (São Paulo)
- [ ] Claves SSH configuradas (cross-VPS trust)
- [ ] UFW configurado en los 3 servidores
- [ ] IPs de los 3 VPS conocidas
- [ ] Acceso sudo en todos los VPS

### Tiempo Estimado

- **Configurar cross-VPS trust:** 15 minutos
- **Crear túneles SSH:** 10 minutos
- **Configurar health checks cross-VPS:** 10 minutos
- **Validación completa:** 10 minutos
- **Total:** 45 minutos

### Cómo Usar Este Documento

1. **Si es la primera vez:** Ir a [[#ejemplo-1-configurar-cross-vps-trust]]
2. **Si necesitas túneles SSH:** Ir a [[#ejemplo-2-crear-túneles-ssh-permanentes]]
3. **Si configuras VPS-1 ↔ VPS-2:** Ir a [[#ejemplo-3-conectar-n8n-a-mysql-qdrant]]
4. **Si quieres health checks cross-VPS:** Ir a [[#ejemplo-4-monitoreo-cross-vps]]
5. **Si tienes problemas de conexión:** Ir a [[#ejemplo-5-troubleshooting]]

### Qué Hacer Si Falla

| Error | Causa | Solución |
|-------|-------|----------|
| `Connection refused` | Firewall bloqueando | `sudo ufw allow from IP_VPS` |
| `Permission denied (publickey)` | Clave SSH no deployada | `ssh-copy-id` |
| `Timeout` | Red o firewall | Verificar IPs y puertos |
| `Host key verification failed` | Host nuevo | `ssh-keygen -R hostname` |
| `No route to host` | Problema de red | `ping IP_VPS` |

### Glosario Rápido

| Término | Significado | Ejemplo |
|---------|-------------|---------|
| **Cross-VPS** | Comunicación entre VPS | VPS-1 conecta a MySQL en VPS-2 |
| **Túnel SSH** | Puerto local redireccionado via SSH | `-L 3306:localhost:3306` |
| **SSH Tunnel** | Conexión segura entre servidores | `ssh -fN -L ...` |
| **Trust** | Acceso sin password entre VPS | Claves SSH autorizadas |
| **ProxyJump** | Conexión via host intermedio | `-J bastion` |

---

## 🎯 Propósito y Alcance

### Propósito

Este documento establece el procedimiento estándar para configurar la **interconexión entre los 3 VPS** de Mantis Agentic. El objetivo es garantizar que n8n (VPS-1 y VPS-3) pueda acceder a MySQL y Qdrant (VPS-2), compartir datos de health monitoring, y ejecutar scripts de backup distribuidos.

### Alcance

| VPS | Servicios | Función | IP |
|-----|-----------|---------|-----|
| **VPS-1** | n8n, uazapi, Redis | Orquestador principal | 186.234.x.10 |
| **VPS-2** | EspoCRM, MySQL, Qdrant | Base de datos central | 186.234.x.20 |
| **VPS-3** | n8n, uazapi (failover) | Failover/backup | 186.234.x.30 |

### Constraints Aplicadas

| Constraint | Descripción | Aplicación |
|------------|-------------|------------|
| **C1** | Máx 4GB RAM/VPS | Sin túneles pesados |
| **C2** | Máx 1 vCPU | Conexiones eficientes |
| **C3** | DB internas nunca expuestas | MySQL/Qdrant via túnel SSH solo |
| **C4** | tenant_id obligatorio | Logging de conexiones con tenant_id |
| **C5** | Backup diario + SHA256 | Backups via rsync cross-VPS |

### Topología de Conexiones

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          ARQUITECTURA CROSS-VPS                             │
│                                                                             │
│    ┌──────────────────────────────────────────────────────────────────┐     │
│    │                         INTERNET                                 │     │
│    └──────────────────────────────────────────────────────────────────┘     │
│                    │                    │                    │              │
│                    ▼                    ▼                    ▼              │
│    ┌───────────────┐        ┌───────────────┐        ┌───────────────┐     │
│    │    VPS-1      │        │    VPS-2      │        │    VPS-3      │     │
│    │  São Paulo    │        │  São Paulo    │        │  São Paulo    │     │
│    │               │        │               │        │               │     │
│    │  n8n (5678)   │        │  EspoCRM (80) │        │  n8n (5678)   │     │
│    │  uazapi(3000) │        │  MySQL  (3306)│        │  uazapi(3000) │     │
│    │  Redis (6379) │◄──────►│  Qdrant (6333)│◄──────►│  Redis (6379) │     │
│    │               │   SSH  │               │   SSH  │               │     │
│    │               │ Tunnels│               │ Tunnels│               │     │
│    └───────┬───────┘        └───────┬───────┘        └───────┬───────┘     │
│            │                        │                        │              │
│            │  health checks         │                        │              │
│            └────────────────────────┴────────────────────────┘              │
│                              │                                             │
│                    ┌─────────▼─────────┐                                   │
│                    │  Alertas a       │                                   │
│                    │  Facundo         │                                   │
│                    │  (Telegram)      │                                   │
│                    └─────────────────┘                                   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📐 Fundamentos (De 0 a Intermedio)

### Conceptos de Conexión Cross-VPS

#### Tipos de Conexión

| Tipo | Descripción | Caso de Uso |
|------|-------------|-------------|
| **Directa** | Conexión SSH normal | Deploys, gestión |
| **Túnel SSH** | Puerto local → remoto via SSH | MySQL/Qdrant |
| **ProxyJump** | Via host bastion | Acceso admin |
| **rsync** | Sincronización archivos | Backups |

#### Cómo Funciona un Túnel SSH

```
┌─────────────┐     Puerto Local     ┌─────────────┐     Puerto Remoto
│   VPS-1      │ ──────────────────► │   VPS-2      │
│             │                     │             │
│  localhost  │                     │  localhost  │
│  :3306      │        SSH          │  :3306      │
│             │ ═══════════════════►│             │
│  (n8n)      │     Encriptado      │  (MySQL)   │
│  ve:puerto  │                     │             │
│  local 3306 │                     │             │
└─────────────┘                     └─────────────┘

n8n en VPS-1 se conecta a localhost:3306
El tráfico se envía via SSH encriptado a VPS-2:3306
```

### Comparativa: Métodos de Acceso

| Método | Seguridad | Complejidad | Latencia | Recomendación |
|--------|-----------|-------------|----------|----------------|
| **SSH Direct** | Alta | Baja | Baja | ✅ Admin scripts |
| **SSH Tunnel** | Alta | Media | Media | ✅ MySQL/Qdrant |
| **VPN** | Muy Alta | Alta | Alta | ⏸️ Futuro |
| **ProxyJump** | Alta | Media | Media | Para admin |

---

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

### Especificaciones de los VPS

| Recurso | VPS-1 | VPS-2 | VPS-3 |
|---------|-------|-------|-------|
| **vCPU** | 1 | 1 | 1 |
| **RAM** | 4 GB | 4 GB | 4 GB |
| **Disco** | 50 GB NVMe | 50 GB NVMe | 50 GB NVMe |
| **Servicios** | n8n, uazapi, Redis | EspoCRM, MySQL, Qdrant | n8n, uazapi, Redis |
| **IP** | 186.234.x.10 | 186.234.x.20 | 186.234.x.30 |

### Configuración de Red

```bash
# Red Cross-VPS Allowed en UFW

# EN VPS-2 (MySQL/Qdrant)
sudo ufw allow from 186.234.x.10 to any port 3306 proto tcp comment 'VPS-1 MySQL'
sudo ufw allow from 186.234.x.30 to any port 3306 proto tcp comment 'VPS-3 MySQL'
sudo ufw allow from 186.234.x.10 to any port 6333 proto tcp comment 'VPS-1 Qdrant'
sudo ufw allow from 186.234.x.30 to any port 6333 proto tcp comment 'VPS-3 Qdrant'

# EN VPS-1 y VPS-3
# No necesita reglas especiales para salir (egress allowed)
```

### Límites de Conexión

| Recurso | Límite | Archivo Config |
|---------|--------|----------------|
| **Conexiones SSH** | 10/VPS | `/etc/ssh/sshd_config` |
| **Conexiones MySQL** | 50/VPS-2 | `my.cnf` |
| **Conexiones Qdrant** | 20/VPS-2 | Configuración |
| **Túneles activos** | 5/VPS | `MaxSessions` |

---

## 🔗 Conexión Local vs Externa / Cross-VPS

### Conexión Local (Mismo VPS)

```
┌─────────────────────────────────┐
│              VPS-2               │
│                                 │
│  MySQL ◄───── localhost:3306    │
│  Qdrant ◄──── localhost:6333    │
│  EspoCRM ◄─── localhost:80      │
│                                 │
│  Redis ◄─────── localhost:6379  │
└─────────────────────────────────┘
```

### Conexión Cross-VPS (VPS-1 → VPS-2)

```
┌─────────────────┐     SSH Tunnel     ┌─────────────────┐
│     VPS-1        │ ════════════════► │     VPS-2        │
│                  │                    │                  │
│  n8n             │  ssh -L 3306:     │  MySQL (3306)    │
│  se conecta a:   │  localhost:3306   │                  │
│  localhost:3306  │  user@VPS2_IP     │  Qdrant (6333)   │
│                  │                    │                  │
│  (túnel SSH)     │                    │  EspoCRM (80)    │
└─────────────────┘                    └─────────────────┘
```

---

## 🛠️ 5 Ejemplos de Configuración (Copy-Paste Validables)

### EJEMPLO 1: Configurar Cross-VPS Trust

**Objetivo:** Permitir que VPS-1 se conecte a VPS-2 sin password.

```bash
#!/bin/bash
# /opt/mantis/scripts/setup-cross-vps-trust.sh

set -euo pipefail

VPS1_IP="186.234.x.10"
VPS2_IP="186.234.x.20"
VPS3_IP="186.234.x.30"
SSH_USER="mantis"

echo "=== Configurando Cross-VPS Trust ==="

# 1. Crear directorio SSH si no existe en VPS-1
ssh ${SSH_USER}@${VPS1_IP} "mkdir -p ~/.ssh && chmod 700 ~/.ssh"

# 2. Generar clave SSH específica para cross-VPS (si no existe)
ssh ${SSH_USER}@${VPS1_IP} "test -f ~/.ssh/id_ed25519_vps_cross && echo 'existe' || ssh-keygen -t ed25519 -C 'vps-cross-$(date +%Y%m%d)' -f ~/.ssh/id_ed25519_vps_cross -N ''"

# 3. Copiar clave pública a VPS-2
ssh-copy-id -i ~/.ssh/id_ed25519_vps_cross.pub ${SSH_USER}@${VPS2_IP}

# 4. Copiar clave pública a VPS-3
ssh-copy-id -i ~/.ssh/id_ed25519_vps_cross.pub ${SSH_USER}@${VPS3_IP}

# 5. Agregar IPs a known_hosts de VPS-1
ssh ${SSH_USER}@${VPS1_IP} "ssh-keyscan -H ${VPS2_IP} >> ~/.ssh/known_hosts"
ssh ${SSH_USER}@${VPS1_IP} "ssh-keyscan -H ${VPS3_IP} >> ~/.ssh/known_hosts"

# 6. Verificar conexión sin password
echo "Verificando conexión a VPS-2..."
ssh -i ~/.ssh/id_ed25519_vps_cross ${SSH_USER}@${VPS2_IP} "hostname && uptime"
echo "✅ VPS-1 → VPS-2 sin password"

echo "Verificando conexión a VPS-3..."
ssh -i ~/.ssh/id_ed25519_vps_cross ${SSH_USER}@${VPS3_IP} "hostname && uptime"
echo "✅ VPS-1 → VPS-3 sin password"

# 7. Repetir para VPS-3 como failover
echo ""
echo "Configurando VPS-3 como failover..."
ssh ${SSH_USER}@${VPS3_IP} "test -f ~/.ssh/id_ed25519_vps_cross && echo 'existe' || ssh-keygen -t ed25519 -C 'vps-cross-failover-$(date +%Y%m%d)' -f ~/.ssh/id_ed25519_vps_cross -N ''"
ssh-copy-id -i ${SSH_USER}@${VPS3_IP}:~/.ssh/id_ed25519_vps_cross.pub ${SSH_USER}@${VPS2_IP}

echo ""
echo "🎉 Cross-VPS Trust configurado"
```

✅ **Deberías ver:**
```
hostname: vps2
uptime: 14:23:45 up 12 days
✅ VPS-1 → VPS-2 sin password
```

❌ **Si ves esto... → Ve a Troubleshooting 1:**
- `Permission denied (publickey)` → Verificar que ssh-copy-id funcionó

---

### EJEMPLO 2: Crear Túneles SSH Permanentes

**Objetivo:** Crear túneles SSH para MySQL y Qdrant entre VPS-1 y VPS-2.

```bash
#!/bin/bash
# /opt/mantis/scripts/ssh-tunnel-vps2.sh
# Túneles SSH para acceder MySQL/Qdrant en VPS-2 desde VPS-1

set -euo pipefail

REMOTE_USER="mantis"
REMOTE_HOST="186.234.x.20"
LOCAL_PORT_MYSQL="3306"
REMOTE_PORT_MYSQL="3306"
LOCAL_PORT_QDRANT="6333"
REMOTE_PORT_QDRANT="6333"
IDENTITY_FILE="/home/mantis/.ssh/id_ed25519_vps_cross"
LOG_FILE="/var/log/mantis/ssh-tunnel.log"

# Función para verificar y crear túnel
check_and_create_tunnel() {
    local tunnel_name="$1"
    local local_port="$2"
    local remote_port="$3"

    # Verificar si ya existe el túnel
    if nc -z localhost ${local_port} 2>/dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Túnel ${tunnel_name} ya activo en puerto ${local_port}" >> "$LOG_FILE"
        return 0
    fi

    # Crear túnel
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Creando túnel ${tunnel_name}..." >> "$LOG_FILE"
    ssh -f -N \
        -L "${local_port}:localhost:${remote_port}" \
        -o "ExitOnForwardFailure=yes" \
        -o "ServerAliveInterval=60" \
        -o "ServerAliveCountMax=3" \
        -i "$IDENTITY_FILE" \
        "${REMOTE_USER}@${REMOTE_HOST}" \
        2>&1 >> "$LOG_FILE"

    # Verificar
    sleep 2
    if nc -z localhost ${local_port} 2>/dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Túnel ${tunnel_name} creado exitosamente" >> "$LOG_FILE"
        return 0
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Error creando túnel ${tunnel_name}" >> "$LOG_FILE"
        return 1
    fi
}

# Verificar que el log existe
mkdir -p "$(dirname $LOG_FILE)"

# Crear túneles
check_and_create_tunnel "MySQL" "$LOCAL_PORT_MYSQL" "$REMOTE_PORT_MYSQL"
check_and_create_tunnel "Qdrant" "$LOCAL_PORT_QDRANT" "$REMOTE_PORT_QDRANT"

# Mostrar estado
echo "=== Estado de túneles SSH ==="
ss -tlnp | grep -E "(3306|6333)" || echo "No hay túneles activos"

# Verificar conectividad
echo ""
echo "=== Verificación de conectividad ==="
nc -zv localhost 3306 2>&1 && echo "✅ MySQL accesible" || echo "❌ MySQL no accesible"
nc -zv localhost 6333 2>&1 && echo "✅ Qdrant accesible" || echo "❌ Qdrant no accesible"
```

**Configuración systemd para túnel permanente:**

```bash
# /etc/systemd/system/ssh-tunnel-mysql.service
[Unit]
Description=SSH Tunnel to VPS-2 MySQL
After=network.target

[Service]
Type=forking
ExecStart=/usr/bin/ssh -f -N -L 3306:localhost:3306 -i /home/mantis/.ssh/id_ed25519_vps_cross mantis@186.234.x.20
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
```

```bash
# Activar servicio
sudo systemctl daemon-reload
sudo systemctl enable ssh-tunnel-mysql
sudo systemctl start ssh-tunnel-mysql
sudo systemctl status ssh-tunnel-mysql
```

✅ **Deberías ver:** `ssh-tunnel-mysql.service: active (running)`

❌ **Si ves esto... → Ve a Troubleshooting 2:**
- `nc: Connection refused` → El túnel SSH no se estableció

---

### EJEMPLO 3: Conectar n8n a MySQL/Qdrant

**Objetivo:** Configurar n8n en VPS-1 para acceder a MySQL y Qdrant en VPS-2 via túnel SSH.

```bash
#!/bin/bash
# /opt/mantis/scripts/configure-n8n-cross-vps.sh
# Configurar n8n para conectar a MySQL y Qdrant via túnel SSH

set -euo pipefail

echo "=== Configurando n8n para Cross-VPS ==="

# 1. Asegurar que túneles están activos
/opt/mantis/scripts/ssh-tunnel-vps2.sh

# 2. Configurar variables de entorno para n8n
cat >> /opt/n8n/env  <<EOF

# Configuración Cross-VPS (VPS-1 → VPS-2)
# MySQL via túnel SSH (localhost:3306 → VPS-2:3306)
DB_TYPE=mysql
DB_HOST=localhost
DB_PORT=3306
DB_DATABASE=n8n
DB_USERNAME=n8n
DB_PASSWORD=\${DB_PASSWORD}

# Qdrant via túnel SSH (localhost:6333 → VPS-2:6333)
QDRANT_URL=http://localhost:6333
QDRANT_COLLECTION=n8n_embeddings
EOF

# 3. Verificar conexión MySQL
echo "Verificando conexión MySQL..."
timeout 5 mysqladmin ping -h localhost -u n8n -p\${DB_PASSWORD} 2>/dev/null && \
    echo "✅ MySQL accesible" || echo "⚠️ MySQL no accesible (verificar túnel)"

# 4. Verificar conexión Qdrant
echo "Verificando conexión Qdrant..."
curl -s http://localhost:6333/collections 2>/dev/null | jq -e '.result.collections' > /dev/null && \
    echo "✅ Qdrant accesible" || echo "⚠️ Qdrant no accesible (verificar túnel)"

# 5. Mostrar configuración
echo ""
echo "=== Configuración n8n ==="
echo "MySQL: localhost:3306 (→ VPS-2 via túnel SSH)"
echo "Qdrant: localhost:6333 (→ VPS-2 via túnel SSH)"
echo ""
echo "⚠️ IMPORTANTE: Los túneles SSH deben estar activos para que n8n funcione"
```

**Configuración n8n .env:**

```bash
# /opt/n8n/.env

# Base de datos MySQL (via túnel SSH)
DB_TYPE=mysql
DB_HOST=localhost
DB_PORT=3306
DB_DATABASE=n8n
DB_USERNAME=n8n
DB_PASSWORD=n8n_password_seguro

# Qdrant
QDRANT_URL=http://localhost:6333
QDRANT_COLLECTION=n8n_embeddings

# Execution
EXECUTIONS_PROCESS=main
EXECUTIONS_MAX_CONCURRENT=5
WEBHOOK_TIMEOUT=30000
```

✅ **Deberías ver:** MySQL y Qdrant accesibles via localhost

❌ **Si ves esto... → Ve a Troubleshooting 3:**
- `Connection refused: MySQL` → Túnel SSH no activo

---

### EJEMPLO 4: Monitoreo Cross-VPS

**Objetivo:** Configurar health checks que monitoreen servicios en VPS-2 desde VPS-1.

```bash
#!/bin/bash
# /opt/mantis/scripts/cross-vps-healthcheck.sh
# Health check cross-VPS: verifica MySQL y Qdrant en VPS-2

set -euo pipefail

TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID}"
LOG_FILE="/var/log/mantis/cross-vps-health.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

send_alert() {
    local severity="$1"
    local message="$2"
    local emoji

    case "$severity" in
        "CRITICAL") emoji="🔴" ;;
        "WARNING") emoji="⚠️" ;;
        "INFO") emoji="ℹ️" ;;
    esac

    curl -s -X POST \
        "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${emoji} [${severity}] Cross-VPS Health: ${message}"
}

# Verificar que túneles están activos
check_tunnel() {
    local port="$1"
    local name="$2"

    if nc -z localhost ${port} 2>/dev/null; then
        log "✅ Túnel ${name} activo en puerto ${port}"
        return 0
    else
        log "❌ Túnel ${name} NO activo en puerto ${port}"
        send_alert "CRITICAL" "${name} tunnel DOWN on $(hostname)"
        return 1
    fi
}

# Verificar MySQL
check_mysql() {
    log "Verificando MySQL..."

    # Verificar que puerto MySQL está accesible
    if ! nc -z localhost 3306 2>/dev/null; then
        log "❌ MySQL no accesible en localhost:3306"
        send_alert "CRITICAL" "MySQL NOT accessible from $(hostname)"
        return 1
    fi

    # Verificar con mysqladmin
    if timeout 5 mysqladmin ping -h localhost -u n8n -p\${DB_PASSWORD} > /dev/null 2>&1; then
        log "✅ MySQL respondiendo"
        return 0
    else
        log "❌ MySQL no responde a ping"
        send_alert "CRITICAL" "MySQL not responding"
        return 1
    fi
}

# Verificar Qdrant
check_qdrant() {
    log "Verificando Qdrant..."

    # Verificar que puerto Qdrant está accesible
    if ! nc -z localhost 6333 2>/dev/null; then
        log "❌ Qdrant no accesible en localhost:6333"
        send_alert "CRITICAL" "Qdrant NOT accessible from $(hostname)"
        return 1
    fi

    # Verificar API de Qdrant
    QDRANT_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:6333/readyz)
    if [[ "$QDRANT_RESPONSE" == "200" ]]; then
        log "✅ Qdrant respondiendo"
        return 0
    else
        log "❌ Qdrant API error (HTTP ${QDRANT_RESPONSE})"
        send_alert "CRITICAL" "Qdrant API error: HTTP ${QDRANT_RESPONSE}"
        return 1
    fi
}

# Verificar VPS-2 directamente (backup check)
check_vps2_direct() {
    log "Verificando VPS-2 directamente..."

    if timeout 5 ssh -o ConnectTimeout=5 \
        -i /home/mantis/.ssh/id_ed25519_vps_cross \
        mantis@186.234.x.20 "uptime && systemctl status mysql | head -3" \
        > /dev/null 2>&1; then
        log "✅ VPS-2 accesible"
        return 0
    else
        log "⚠️ VPS-2 no accesible directamente"
        return 1
    fi
}

# Ejecución principal
log "=== Iniciando Cross-VPS Health Check ==="

TUNNEL_MYSQL=$(check_tunnel 3306 "MySQL")
TUNNEL_QDRANT=$(check_tunnel 6333 "Qdrant")

if [[ "$TUNNEL_MYSQL" == "0" ]]; then
    check_mysql
fi

if [[ "$TUNNEL_QDRANT" == "0" ]]; then
    check_qdrant
fi

check_vps2_direct

log "=== Health Check completado ==="
```

**Cron para ejecutar cada 5 minutos:**

```bash
# /etc/cron.d/cross-vps-healthcheck
# Verificar cada 5 minutos
*/5 * * * * root /opt/mantis/scripts/cross-vps-healthcheck.sh >> /var/log/mantis/cron-health.log 2>&1
```

✅ **Deberías ver:** Logs en `/var/log/mantis/cross-vps-health.log`

❌ **Si ves esto... → Ve a Troubleshooting 4:**
- `Túnel MySQL NO activo` → Reiniciar túnel manualmente

---

### EJEMPLO 5: Troubleshooting

**Objetivo:** Diagnosticar problemas comunes de conexión cross-VPS.

```bash
#!/bin/bash
# /opt/mantis/scripts/cross-vps-troubleshoot.sh
# Troubleshooting para problemas cross-VPS

echo "=== Troubleshooting Cross-VPS ==="
echo ""

# 1. Verificar IPs
echo "1. IPs configuradas:"
echo "   VPS-1: 186.234.x.10"
echo "   VPS-2: 186.234.x.20"
echo "   VPS-3: 186.234.x.30"
echo ""

# 2. Verificar conectividad básica
echo "2. Verificando ping a VPS-2..."
ping -c 3 186.234.x.20 2>&1 | tail -2
echo ""

# 3. Verificar SSH
echo "3. Verificando SSH directo..."
timeout 5 ssh -o ConnectTimeout=5 \
    -o StrictHostKeyChecking=no \
    -i ~/.ssh/id_ed25519_vps_cross \
    mantis@186.234.x.20 "hostname" 2>&1 || echo "❌ SSH falló"
echo ""

# 4. Verificar túneles activos
echo "4. Verificando túneles SSH..."
ps aux | grep "ssh.*-L" | grep -v grep || echo "❌ No hay túneles activos"
echo ""

# 5. Verificar puertos locales
echo "5. Verificando puertos locales..."
ss -tlnp | grep -E "(3306|6333)" || echo "❌ Puertos MySQL/Qdrant no listening"
echo ""

# 6. Verificar UFW en VPS-2
echo "6. Para verificar UFW en VPS-2, ejecutar:"
echo "   ssh mantis@186.234.x.20 'sudo ufw status numbered'"
echo ""

# 7. Verificar logs SSH
echo "7. Logs recientes de túnel:"
tail -10 /var/log/mantis/ssh-tunnel.log 2>/dev/null || echo "No hay logs"
echo ""

# 8. Test de conexión MySQL
echo "8. Test MySQL via túnel..."
nc -zv localhost 3306 2>&1 || echo "❌ MySQL no accesible"
echo ""

# 9. Test de conexión Qdrant
echo "9. Test Qdrant via túnel..."
nc -zv localhost 6333 2>&1 || echo "❌ Qdrant no accesible"
echo ""

# 10. Soluciones comunes
echo "=== Soluciones Rápidas ==="
echo "Para reiniciar túneles:"
echo "  killall ssh && /opt/mantis/scripts/ssh-tunnel-vps2.sh"
echo ""
echo "Para verificar UFW en VPS-2:"
echo "  ssh mantis@186.234.x.20 'sudo ufw allow from 186.234.x.10 to any port 3306'"
echo "  ssh mantis@186.234.x.20 'sudo ufw allow from 186.234.x.10 to any port 6333'"
```

**Tabla de problemas y soluciones:**

| Problema | Causa | Solución |
|----------|-------|----------|
| `No route to host` | IP incorrecta o red | Verificar IP con `ping` |
| `Connection refused` (SSH) | Firewall o servicio caído | `sudo ufw allow 22/tcp` en VPS destino |
| `Permission denied` | Clave no copiada | `ssh-copy-id` |
| `Connection refused` (MySQL) | Túnel SSH caído | Reiniciar túnel |
| `nc: Connection refused` | Puerto no expuesto | Verificar `-L` en comando SSH |

---

## 🐞 5 Eventos/Problemas Críticos y Troubleshooting

| Error Exacto (copiable) | Causa Raíz (lenguaje simple) | Comando de Diagnóstico | Solución Paso a Paso | Constraint Afectado (C#) |
|------------------------|------------------------------|------------------------|---------------------|--------------------------|
| `Permission denied (publickey)` | Clave SSH no deployada a VPS destino | `ssh-copy-id -i ~/.ssh/id_ed25519_vps_cross.pub mantis@186.234.x.20` | 1. Verificar que clave existe: `ls -la ~/.ssh/id_ed25519_vps_cross*` 2. Copiar a VPS destino: `ssh-copy-id` 3. Verificar contenido de `~/.ssh/authorized_keys` en VPS destino 4. Probar conexión directa | C3 |
| `Connection refused` (MySQL via túnel) | Túnel SSH no establecido o caído | `ps aux \| grep "ssh.*-L 3306"` | 1. Verificar que sshd está corriendo en VPS-2: `ssh mantis@186.234.x.20 "sudo systemctl status sshd"` 2. Verificar UFW en VPS-2: `sudo ufw status \| grep 3306` 3. Recrear túnel: `killall ssh; /opt/mantis/scripts/ssh-tunnel-vps2.sh` 4. Verificar logs: `tail -20 /var/log/mantis/ssh-tunnel.log` | C3 |
| `MySQL/Qdrant expuesto a internet` | Reglas UFW incorrectas en VPS-2 | `curl -v mysql://186.234.x.20:3306` (desde outside) | 1. `ssh mantis@186.234.x.20 "sudo ufw status numbered"` 2. Eliminar regla que permite 0.0.0.0:3306 3. Agregar regla específica: `sudo ufw insert 1 allow from 186.234.x.10 to any port 3306` 4. `sudo ufw reload` 5. Verificar: `curl mysql://186.234.x.20:3306` (debe fallar) | C3 (CRÍTICO) |
| `Túnel SSH se corta después de minutos` | SSH keepalive no configurado | `grep "ClientAlive" /etc/ssh/ssh_config` | 1. Agregar a `~/.ssh/config`: `ServerAliveInterval 60` y `ServerAliveCountMax 3` 2. Usar systemd service con `Restart=on-failure` 3. Crear script de monitoreo que reinicie túneles caídos 4. Verificar que proceso ssh sigue activo: `ps aux \| grep "ssh -f -N"` | C4 |
| `nc: Connection refused` (puerto local) | Túnel mal configurado o puerto ocupado | `ss -tlnp \| grep 3306` | 1. Verificar que puerto no está usado: `ss -tlnp \| grep 3306` 2. Si está ocupado, matar proceso: `sudo kill $(lsof -t -i:3306)` 3. Verificar formato de `-L`: debe ser `local_port:localhost:remote_port` 4. Verificar que IP en VPS destino es correcta 5. Reiniciar: `killall ssh && ssh -f -N -L 3306:localhost:3306 ...` | C4 |

---

## ✅ Validación SDD y Comandos de Verificación

### Checklist de Validación

```bash
#!/bin/bash
# /opt/mantis/scripts/validate-cross-vps.sh

ERRORS=0
VPS1_IP="186.234.x.10"
VPS2_IP="186.234.x.20"
VPS3_IP="186.234.x.30"

echo "=== Validación Cross-VPS - Mantis Agentic ==="

# 1. Verificar conectividad entre VPS
echo ""
echo "1. Conectividad básica..."
for vps in "VPS-1:${VPS1_IP}" "VPS-2:${VPS2_IP}" "VPS-3:${VPS3_IP}"; do
    name="${vps%%:*}"
    ip="${vps##*:}"
    if ping -c 1 -W 2 "${ip}" > /dev/null 2>&1; then
        echo "✅ ${name} (${ip}) reachable"
    else
        echo "❌ ${name} (${ip}) NOT reachable"
        ERRORS=$((ERRORS+1))
    fi
done

# 2. Verificar SSH trust
echo ""
echo "2. SSH Trust VPS-1 → VPS-2..."
if timeout 10 ssh -o ConnectTimeout=5 \
    -o StrictHostKeyChecking=no \
    -i ~/.ssh/id_ed25519_vps_cross \
    mantis@${VPS2_IP} "hostname" > /dev/null 2>&1; then
    echo "✅ SSH Trust VPS-1 → VPS-2 OK"
else
    echo "❌ SSH Trust VPS-1 → VPS-2 FAIL"
    ERRORS=$((ERRORS+1))
fi

# 3. Verificar túneles
echo ""
echo "3. Verificando túneles SSH..."
if ps aux | grep -q "ssh.*-L 3306.*${VPS2_IP}"; then
    echo "✅ Túnel MySQL activo"
else
    echo "❌ Túnel MySQL NO activo"
    ERRORS=$((ERRORS+1))
fi

if ps aux | grep -q "ssh.*-L 6333.*${VPS2_IP}"; then
    echo "✅ Túnel Qdrant activo"
else
    echo "❌ Túnel Qdrant NO activo"
    ERRORS=$((ERRORS+1))
fi

# 4. Verificar acceso a servicios via túnel
echo ""
echo "4. Acceso a MySQL via túnel..."
if nc -z localhost 3306 2>/dev/null; then
    echo "✅ MySQL accesible via localhost:3306"
else
    echo "❌ MySQL NO accesible"
    ERRORS=$((ERRORS+1))
fi

echo ""
echo "5. Acceso a Qdrant via túnel..."
if nc -z localhost 6333 2>/dev/null; then
    echo "✅ Qdrant accesible via localhost:6333"
else
    echo "❌ Qdrant NO accesible"
    ERRORS=$((ERRORS+1))
fi

# 5. Verificar UFW rules en VPS-2
echo ""
echo "6. UFW en VPS-2 (requiere acceso manual)..."
echo "   Ejecutar en VPS-2: sudo ufw status numbered | grep -E '(3306|6333)'"
echo "   Debería mostrar ALLOW solo desde 186.234.x.10 y 186.234.x.30"

echo ""
if [[ $ERRORS -eq 0 ]]; then
    echo "🎉 Validación Cross-VPS: TODOS LOS CHECKS PASARON"
    exit 0
else
    echo "❌ Validación Cross-VPS: $ERRORS ERRORES ENCONTRADOS"
    exit 1
fi
```

### Comandos de Verificación Rápida

```bash
# Ver estado de túneles
ps aux | grep "ssh.*-L"

# Test MySQL
mysql -h localhost -u n8n -p -e "SELECT 1"

# Test Qdrant
curl http://localhost:6333/readyz

# Ver logs
tail -f /var/log/mantis/ssh-tunnel.log

# Ver conexiones activas
ss -tlnp | grep -E "(3306|6333)"
```

---

## 🔗 Referencias Cruzadas y Glosario

### Archivos Relacionados

| Archivo | Descripción | Relevancia |
|---------|-------------|------------|
| [[01-RULES/01-ARCHITECTURE-RULES.md]] | Arquitectura de servicios | Topología VPS |
| [[01-RULES/03-SECURITY-RULES.md]] | Seguridad SSH y firewall | C3 |
| [[01-RULES/06-MULTITENANCY-RULES.md]] | Aislamiento de datos | C4 |
| [[00-CONTEXT/facundo-infrastructure.md]] | Configuración VPS | IPs y servicios |
| [[02-SKILLS/INFRAESTRUCTURA/ssh-key-management.md]] | Gestión de claves SSH | Cross-VPS trust |
| [[02-SKILLS/INFRAESTRUCTURA/ufw-firewall-configuration.md]] | Firewall UFW | Puertos cross-VPS |

### Glosario Completo

| Término | Definición | Contexto |
|---------|------------|----------|
| **Túnel SSH** | Redirección de puertos via conexión SSH encriptada | `-L local:remote` |
| **ProxyJump** | Conexión via host intermedio | `-J bastion` |
| **known_hosts** | Archivo con fingerprints de hosts SSH | Previene MITM |
| **SSH Agent** | Programa que mantiene claves en memoria | `ssh-agent` |
| **Port Forwarding** | Redirección de puertos TCP | Local o remoto |
| **KeepAlive** | Paquetes para mantener conexión activa | `ServerAliveInterval` |
| **Failover** | Cambio automático a sistema secundario | VPS-3 como backup |

### Variables de Entorno

```bash
# /opt/mantis/.env

# Cross-VPS Configuration
VPS1_IP="186.234.x.10"
VPS2_IP="186.234.x.20"
VPS3_IP="186.234.x.30"
SSH_USER="mantis"
SSH_KEY_PATH="/home/mantis/.ssh/id_ed25519_vps_cross"

# Tunnels
MYSQL_TUNNEL_LOCAL_PORT="3306"
MYSQL_TUNNEL_REMOTE_PORT="3306"
QDRANT_TUNNEL_LOCAL_PORT="6333"
QDRANT_TUNNEL_REMOTE_PORT="6333"
```

### URLs Raw para IAs

```
Base: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/

https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/02-SKILLS/INFRAESTRUCTURA/vps-interconnection.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/01-RULES/01-ARCHITECTURE-RULES.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/00-CONTEXT/facundo-infrastructure.md
```

---

**Versión 1.0.0 - 2026-04-09 - Mantis-AgenticDev**
**Licencia:** Creative Commons para uso interno del proyecto
