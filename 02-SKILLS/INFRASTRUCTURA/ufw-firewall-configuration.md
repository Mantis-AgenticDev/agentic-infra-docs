---
title: "UFW Firewall Configuration"
category: "Infraestructura"
domain: ["seguridad", "infraestructura", "redes"]
constraints: ["C1", "C2", "C3"]
priority: "Alta"
version: "1.0.0"
last_updated: "2026-04-09"
ai_optimized: true
tags:
  - sdd/config/ufw
  - sdd/security
  - sdd/network
  - lang/es
related_files:
  - "01-RULES/03-SECURITY-RULES.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
  - "00-CONTEXT/facundo-infrastructure.md"
  - "02-SKILLS/INFRAESTRUCTURA/ssh-key-management.md"
  - "02-SKILLS/INFRAESTRUCTURA/fail2ban-configuration.md"
---

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

### Checklist de Prerrequisitos

- [ ] Servidor Ubuntu 22.04 o 24.04 LTS
- [ ] Acceso sudo al servidor
- [ ] Conexión SSH activa (no cerrar hasta validar)
- [ ] Conectividad a internet desde el servidor

### Tiempo Estimado

- **Instalación UFW:** 5 minutos
- **Configuración reglas básicas:** 10 minutos
- **Validación completa:** 5 minutos
- **Total:** 20 minutos

### Cómo Usar Este Documento

1. **Si es VPS nuevo:** Ir a [[#ejemplo-1-instalar-y-configurar-ufw-desde-cero]]
2. **Si necesitas abrir puertos específicos:** Ir a [[#ejemplo-2-abrir-y-cerrar-puertos]]
3. **Si configuras VPS-1 o VPS-3 (n8n):** Ir a [[#ejemplo-3-configurar-para-vps-n8n-uazapi]]
4. **Si configuras VPS-2 (MySQL/Qdrant):** Ir a [[#ejemplo-4-configurar-para-vps-con-db-interna]]
5. **Si necesitas troubleshooting:** Ir a [[#ejemplo-5-restaurar-acceso-si-bloqueaste-ssh]]

### Qué Hacer Si Falla

| Error | Causa | Solución |
|-------|-------|----------|
| `ufw: command not found` | UFW no instalado | `sudo apt install ufw` |
| `SSH connection refused` | Regla SSH eliminada | [[#ejemplo-5-restaurar-acceso-si-bloqueaste-ssh]] |
| `Connection timeout` | UFW bloqueando todo | `sudo ufw disable` temporalmente |
| `ufw status` vacío | UFW inactivo | `sudo ufw enable` |
| `bad port number` | Puerto inválido | Verificar formato: `22`, `80/tcp`, `1000:2000` |

### Glosario Rápido

| Término | Significado | Ejemplo |
|---------|-------------|---------|
| **UFW** | Uncomplicated Firewall, interfaz simplificada para iptables | `sudo ufw allow 22` |
| **Puertos** | Canales de comunicación numerados (0-65535) | 22 (SSH), 80 (HTTP), 443 (HTTPS) |
| **Regla** | Permiso o denegación para tráfico | `allow from 192.168.1.0/24 to any port 3306` |
| **Perfil** | Plantilla de reglas predefinidas | `ufw app list` (OpenSSH, Nginx Full) |
| **Default policy** | Comportamiento para tráfico sin regla explícita | `ufw default deny incoming` |

---

## 🎯 Propósito y Alcance

### Propósito

Este documento establece el procedimiento estándar para configurar **UFW (Uncomplicated Firewall)** en los 3 VPS de Mantis Agentic. El objetivo es proteger los servicios expuestos a internet, cumplir con la constraint C3 (DB internas nunca expuestas) y facilitar la automatización de reglas para nuevos servicios.

### Alcance

- **VPS cubiertos:** VPS-1 (n8n/uazapi), VPS-2 (EspoCRM/MySQL/Qdrant), VPS-3 (n8n/uazapi failover)
- **Puertos covered:** SSH (22), HTTP (80), HTTPS (443), puertos internos
- **Servicios protegidos:** n8n, uazapi, EspoCRM, MySQL, Qdrant, Redis

### Constraints Aplicadas

| Constraint | Descripción | Aplicación |
|------------|-------------|------------|
| **C1** | Máx 4GB RAM/VPS | Sin impacto en firewall |
| **C2** | Máx 1 vCPU | Sin impacto en firewall |
| **C3** | DB internas nunca expuestas | MySQL/Qdrant solo accesible via túnel SSH |

### Objetivos de Seguridad

1. **Default deny:** Todo tráfico no explícitamente permitido está bloqueado
2. **Aislamiento de servicios:** MySQL/Qdrant inaccesibles desde internet
3. **Acceso mínimo:** Solo puertos necesarios expuestos
4. **Trazabilidad:** Logs de conexiones bloqueadas

---

## 📐 Fundamentos (De 0 a Intermedio)

### Conceptos Básicos de UFW

#### Cómo Funciona UFW

```
[Internet] ──────► [UFW Firewall] ──────► [Servidor]
                       │
                       ├── allow 22/tcp  ──► SSH ✓
                       ├── allow 80/tcp  ──► HTTP ✓
                       ├── allow 443/tcp ──► HTTPS ✓
                       ├── deny 3306/tcp ──► MySQL ✗
                       └── deny 6333/tcp ──► Qdrant ✗
```

### Comandos Básicos de UFW

```bash
# Estados
sudo ufw status verbose     # Ver estado y reglas
sudo ufw enable            # Activar firewall
sudo ufw disable           # Desactivar firewall

# Reglas básicas
sudo ufw allow 22/tcp       # Permitir SSH
sudo ufw deny 3306/tcp      # Denegar MySQL
sudo ufw delete allow 22    # Eliminar regla

# Por perfil de aplicación
sudo ufw app list           # Ver perfiles disponibles
sudo ufw allow 'Nginx Full' # Permitir HTTP+HTTPS

# Por IP específica
sudo ufw allow from 192.168.1.100 to any port 22

# Reglas con comment
sudo ufw allow 22/tcp comment 'SSH para admin'
```

### Estructura de Reglas

```bash
# Ver reglas numeradas
sudo ufw status numbered

# Output ejemplo:
# [ 1] 22/tcp                     ALLOW IN    Anywhere    # SSH admin
# [ 2] 80/tcp                     ALLOW IN    Anywhere    # HTTP
# [ 3] 443/tcp                    ALLOW IN    Anywhere    # HTTPS
# [ 4] 3306/tcp                   DENY IN     Anywhere    # MySQL interno
# [ 5] 6333/tcp                   DENY IN     Anywhere    # Qdrant interno
```

### Estados de UFW

| Estado | Descripción | Uso |
|--------|-------------|-----|
| **active** | Firewall funcionando | Producción |
| **inactive** | Firewall deshabilitado | Solo si hay problemas graves |
| **enabled** | Se activa al boot | Configurado correctamente |
| **disabled** | No se activa al boot | No recomendado en producción |

---

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

### Topología de Puertos por VPS

```
┌──────────────────────────────────────────────────────────────────────┐
│                         INTERNET (0.0.0.0/0)                         │
└──────────────────────────────────────────────────────────────────────┘
                    │                    │                    │
                    ▼                    ▼                    ▼
            ┌───────────┐        ┌───────────┐        ┌───────────┐
            │   VPS-1   │        │   VPS-2   │        │   VPS-3   │
            │  São Paulo│        │  São Paulo│        │  São Paulo│
            └───────────┘        └───────────┘        └───────────┘
                    │                    │                    │
     ┌──────────────┴──┐    ┌──────────────┴───┐    ┌──────────────┴───┐
     │ Puerto  Política│    │ Puerto   Política│    │ Puerto   Política│
     ├─────────────────┤    ├───────────────-──┤    ├─────────────────┤
     │ 22/tcp  ALLOW   │    │ 22/tcp  ALLOW    │    │ 22/tcp  ALLOW   │
     │ 80/tcp  ALLOW   │    │ 80/tcp  ALLOW    │    │ 80/tcp  ALLOW   │
     │ 443/tcp ALLOW   │    │ 443/tcp ALLOW    │    │ 443/tcp ALLOW   │
     │ 3000/tcp ALLOW  │    │ 3306/tcp DENY    │    │ 3000/tcp ALLOW  │
     │ 5678/tcp ALLOW  │    │ 6333/tcp DENY    │    │ 5678/tcp ALLOW  │
     │ 6379/tcp DENY   │    │ 8080/tcp ALLOW   │    │ 6379/tcp DENY   │
     └─────────────────┘    └─────────────────-┘    └─────────────────┘
           Servicios:            Servicios:           Servicios:
           n8n (5678)           EspoCRM (80)        n8n (5678)
           uazapi (3000)        MySQL (3306)        uazapi (3000)
           Redis (6379)*        Qdrant (6333)       Redis (6379)*

     * Redis solo localhost
```

### Reglas por VPS

#### VPS-1 y VPS-3 (n8n + uazapi)

```bash
# Permitir SSH
sudo ufw allow 22/tcp comment 'SSH admin'

# Permitir web services
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# Permitir n8n (webhook endpoint)
sudo ufw allow 5678/tcp comment 'n8n'

# Permitir uazapi
sudo ufw allow 3000/tcp comment 'uazapi'

# Denegar Redis externo (solo localhost)
sudo ufw deny 6379/tcp comment 'Redis interno'

# Denegar MySQL (no se usa en este VPS)
sudo ufw deny 3306/tcp comment 'MySQL no instalado'

# Denegar Qdrant (no se usa en este VPS)
sudo ufw deny 6333/tcp comment 'Qdrant no instalado'

# Permitir acceso desde VPS-2 (para health checks)
sudo ufw allow from 186.234.x.20 to any port 5678 comment 'Desde VPS-2'
```

#### VPS-2 (EspoCRM + MySQL + Qdrant)

```bash
# Permitir SSH
sudo ufw allow 22/tcp comment 'SSH admin'

# Permitir EspoCRM web
sudo ufw allow 80/tcp comment 'EspoCRM HTTP'
sudo ufw allow 443/tcp comment 'EspoCRM HTTPS'

# Permitir interfaz web Qdrant (si se necesita)
# DESCOMENTAR SOLO SI SE REQUIERE ACCESO WEB A QDRANT
# sudo ufw allow 6333/tcp comment 'Qdrant Dashboard'

# Permitir desde VPS-1 y VPS-3 ( túneles SSH)
sudo ufw allow from 186.234.x.10 to any port 3306 comment 'Desde VPS-1 MySQL'
sudo ufw allow from 186.234.x.30 to any port 3306 comment 'Desde VPS-3 MySQL'
sudo ufw allow from 186.234.x.10 to any port 6333 comment 'Desde VPS-1 Qdrant'
sudo ufw allow from 186.234.x.30 to any port 6333 comment 'Desde VPS-3 Qdrant'

# Denegar MySQL desde internet (C3)
sudo ufw deny 3306/tcp comment 'MySQL interno - denegado externo'

# Denegar Qdrant desde internet (C3)
sudo ufw deny 6333/tcp comment 'Qdrant interno - denegado externo'

# Denegar Redis
sudo ufw deny 6379/tcp comment 'Redis interno'
```

---

## 🔗 Conexión Local vs Externa / Cross-VPS

### Tráfico Local (Desde el Mismo VPS)

```
┌─────────────────────────────────────────┐
│              VPS-2                      │
│                                         │
│  Redis (6379) ◄──── localhost:6379      │
│  MySQL (3306) ◄──── localhost:3306      │
│  Qdrant (6333) ◄──── localhost:6333     │
│                                         │
│  UFW permite: from 127.0.0.1            │
└─────────────────────────────────────────┘
```

### Tráfico Cross-VPS (VPS-1 → VPS-2 via SSH Tunnel)

```
┌─────────────────┐     SSH Tunnel      ┌─────────────────┐
│     VPS-1       │ ──────────────────► │     VPS-2       │
│                 │   (puerto 22)       │                 │
│  n8n necesita   │                     │  MySQL (3306)   │
│  datos MySQL    │                     │  Qdrant (6333)  │
│                 │                     │                 │
│  Conecta via    │                     │  UFW permite:   │
│  localhost:3306 │                     │  from 186.234.x │
│  (túnel SSH)    │                     │  .10 y .30      │
└─────────────────┘                     └─────────────────┘
```

**Reglas UFW para permitir cross-VPS:**

```bash
# En VPS-2, permitir conexiones desde VPS-1 y VPS-3
sudo ufw allow from 186.234.x.10 to any port 3306 proto tcp comment 'VPS-1 MySQL'
sudo ufw allow from 186.234.x.10 to any port 6333 proto tcp comment 'VPS-1 Qdrant'
sudo ufw allow from 186.234.x.30 to any port 3306 proto tcp comment 'VPS-3 MySQL'
sudo ufw allow from 186.234.x.30 to any port 6333 proto tcp comment 'VPS-3 Qdrant'
```

---

## 🛠️ 5 Ejemplos de Configuración (Copy-Paste Validables)

### EJEMPLO 1: Instalar y Configurar UFW Desde Cero

**Objetivo:** Configurar UFW en un VPS nuevo con reglas seguras básicas.

```bash
# 1. Verificar que UFW está instalado
which ufw || sudo apt update && sudo apt install ufw -y

# 2. Establecer políticas por defecto (CRÍTICO)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw default allow routed

# 3. Permitir SSH ANTES de activar (CRÍTICO - no cerrar sesión)
# OPCIÓN A: Puerto estándar
sudo ufw allow 22/tcp comment 'SSH'

# OPCIÓN B: Puerto personalizado (si cambiaste SSH)
# sudo ufw allow 2222/tcp comment 'SSH puerto personalizado'

# 4. Permitir HTTP y HTTPS
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# 5. Activar UFW
# IMPORTANTE: Mantener conexión SSH abierta en otra terminal
sudo ufw --force enable

# 6. Verificar estado
sudo ufw status verbose

# 7. Habilitar logging
sudo ufw logging on

# 8. Agregar al inicio del sistema
sudo systemctl enable ufw
```

✅ **Deberías ver:**
```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), allow (routed)
To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere
80/tcp                     ALLOW IN    Anywhere
443/tcp                    ALLOW IN    Anywhere
```

❌ **Si ves esto... → Ve a Troubleshooting 1:**
- `ERROR: Could not lose connection` → Ir a [[#troubleshooting-1-no-se-puede-habilitar-ufw]]

---

### EJEMPLO 2: Abrir y Cerrar Puertos

**Objetivo:** Gestionar puertos específicos para diferentes servicios.

```bash
# ABRIR PUERTO para nuevo servicio
# Ejemplo: Abrir puerto 5678 para n8n
sudo ufw allow 5678/tcp comment 'n8n webhook'

# ABRIR RANGO DE PUERTOS
# Ejemplo: Puertos 8000-9000 para desarrollo
sudo ufw allow 8000:9000/tcp comment 'Rango desarrollo'

# ABRIR DESDE IP ESPECÍFICA SOLAMENTE
# Ejemplo: Solo tu IP de oficina puede acceder a n8n
sudo ufw allow from 192.168.1.100 to any port 5678 comment 'n8n solo oficina'

# ABRIR DESDE RED LOCAL
# Ejemplo: Toda la red 192.168.1.0/24 puede acceder
sudo ufw allow from 192.168.1.0/24 to any port 5678 comment 'n8n red local'

# CERRAR PUERTO (denegar)
sudo ufw deny 3306/tcp comment 'MySQL denegado'

# VER REGLAS NUMERADAS
sudo ufw status numbered

# ELIMINAR REGLA POR NÚMERO
# Primero ver reglas
sudo ufw status numbered
# Output:
# [ 1] 22/tcp                     ALLOW IN    Anywhere
# [ 2] 5678/tcp                   ALLOW IN    Anywhere
# [ 3] 3306/tcp                   DENY IN     Anywhere

# Eliminar regla 2
sudo ufw delete 2

# ELIMINAR POR NOMBRE
sudo ufw delete allow 5678/tcp

# VER LOGS DE UFW
sudo tail -f /var/log/ufw.log
```

✅ **Deberías ver:** `Rule added` o `Rule deleted` según corresponda

❌ **Si ves esto... → Ve a Troubleshooting 2:**
- `WARN: Rule already exists` → La regla ya está configurada

---

### EJEMPLO 3: Configurar para VPS n8n + uazapi

**Objetivo:** Configurar UFW específicamente para VPS-1 o VPS-3 con n8n y uazapi.

```bash
#!/bin/bash
# /opt/mantis/scripts/setup-ufw-vps1.sh
# Configurar UFW para VPS con n8n + uazapi

set -euo pipefail

LOG_FILE="/var/log/mantis/ufw-setup-$(date +%Y%m%d).log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Iniciando configuración UFW para VPS n8n+uazapi..."

# 1. Permitir SSH (siempre primero)
log "Configurando SSH..."
sudo ufw allow 22/tcp comment 'SSH admin'

# 2. Permitir servicios web
log "Configurando servicios web..."
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# 3. Permitir n8n
log "Configurando n8n..."
sudo ufw allow 5678/tcp comment 'n8n'

# 4. Permitir uazapi
log "Configurando uazapi..."
sudo ufw allow 3000/tcp comment 'uazapi'

# 5. Denegar servicios internos
log "Configurando denegaciones..."
sudo ufw deny 6379/tcp comment 'Redis interno'
sudo ufw deny 3306/tcp comment 'MySQL no instalado'
sudo ufw deny 6333/tcp comment 'Qdrant no instalado'

# 6. Permitir desde VPS-2 (health checks)
log "Configurando acceso cross-VPS..."
sudo ufw allow from 186.234.x.20 to any port 5678 comment 'Desde VPS-2 healthcheck'

# 7. Políticas por defecto
log "Estableciendo políticas por defecto..."
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 8. Logging
log "Habilitando logging..."
sudo ufw logging on

# 9. Activar
log "Activando UFW..."
sudo ufw --force enable

log "Configuración completada"
sudo ufw status verbose
```

✅ **Deberías ver:** `Status: active` con todas las reglas listadas

❌ **Si ves esto... → Ve a Troubleshooting 3:**
- `Bad port number` → Puerto no válido

---

### EJEMPLO 4: Configurar para VPS con DB Interna

**Objetivo:** Configurar UFW para VPS-2 con MySQL y Qdrant, restringiendo acceso interno.

```bash
#!/bin/bash
# /opt/mantis/scripts/setup-ufw-vps2.sh
# Configurar UFW para VPS con EspoCRM + MySQL + Qdrant

set -euo pipefail

VPS1_IP="186.234.x.10"
VPS3_IP="186.234.x.30"
VPS2_IP="186.234.x.20"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Iniciando configuración UFW para VPS MySQL+Qdrant..."

# 1. Reset completo (comentar si quieres agregar a existentes)
sudo ufw --force reset

# 2. Políticas por defecto
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 3. SSH
sudo ufw allow 22/tcp comment 'SSH admin'

# 4. EspoCRM
sudo ufw allow 80/tcp comment 'EspoCRM HTTP'
sudo ufw allow 443/tcp comment 'EspoCRM HTTPS'

# 5. MySQL solo desde VPS-1 y VPS-3 (C3 - constraint crítica)
log "Configurando MySQL interno..."
sudo ufw allow from ${VPS1_IP} to any port 3306 proto tcp comment 'VPS-1 MySQL'
sudo ufw allow from ${VPS3_IP} to any port 3306 proto tcp comment 'VPS-3 MySQL'
# DENEGAR explícitamente desde internet
sudo ufw deny 3306/tcp comment 'MySQL denegado externo'

# 6. Qdrant solo desde VPS-1 y VPS-3 (C3 - constraint crítica)
log "Configurando Qdrant interno..."
sudo ufw allow from ${VPS1_IP} to any port 6333 proto tcp comment 'VPS-1 Qdrant'
sudo ufw allow from ${VPS3_IP} to any port 6333 proto tcp comment 'VPS-3 Qdrant'
# DENEGAR explícitamente desde internet
sudo ufw deny 6333/tcp comment 'Qdrant denegado externo'

# 7. Redis (localhost solo)
sudo ufw deny 6379/tcp comment 'Redis solo localhost'

# 8. Logging
sudo ufw logging on

# 9. Activar
sudo ufw --force enable

log "Configuración completada para VPS-2"
log "MySQL y Qdrant SOLO accesibles desde VPS-1 y VPS-3"
sudo ufw status numbered
```

✅ **Deberías ver:** MySQL y Qdrant con reglas `ALLOW IN` solo desde IPs de VPS-1 y VPS-3

❌ **Si ves esto... → Ve a Troubleshooting 4:**
- MySQL accesible desde 0.0.0.0/0 → Eliminar regla y crear correcta

---

### EJEMPLO 5: Restaurar Acceso Si Bloqueaste SSH

**Objetivo:** Recuperar acceso SSH si accidentalmente te bloqueaste.

```bash
#!/bin/bash
# /opt/mantis/scripts/emergency-ssh-recovery.sh
# ⚠️ EJECUTAR EN CASO DE EMERGENCIA ⚠️

set -euo pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# OPCIÓN 1: Si tienes acceso a la terminal local (no SSH)
# Simplemente ejecutar:
sudo ufw allow 22/tcp
sudo ufw reload

# OPCIÓN 2: Si perdiste acceso SSH pero tienes acceso físico/VNC
# Ejecutar desde consola local:

# OPCIÓN 3: Via Panel de Hostinger (VPS KVM)
# 1. Acceder a "Consola" en el painel de Hostinger
# 2. Login como root
# 3. Ejecutar:
sudo ufw disable
sudo ufw allow 22/tcp
sudo ufw enable

# OPCIÓN 4: Si UFW está corrupto
# Reset completo via SSH directo (no UFW)
iptables -F
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Luego reconfigurar UFW
sudo ufw disable
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw enable

log "Acceso SSH restaurado"
```

**Prevención para el futuro:**
```bash
# Siempre verificar que SSH esté permitido ANTES de activar UFW
sudo ufw allow 22/tcp
# Ahora puedes activar UFW sin riesgo
sudo ufw enable
```

✅ **Deberías ver:** `Status: active` y poder conectarte por SSH

❌ **Si no funciona... → Ve a Troubleshooting 5:**
- `Connection refused` incluso después de disable → Problema de red, contactar proveedor

---

## 🐞 5 Eventos/Problemas Críticos y Troubleshooting

| Error Exacto (copiable) | Causa Raíz (lenguaje simple) | Comando de Diagnóstico | Solución Paso a Paso | Constraint Afectado (C#) |
|------------------------|------------------------------|------------------------|---------------------|--------------------------|
| `ERROR: Could not lose connection` | Regla SSH no была добавлена antes de activar | `sudo ufw status` | 1. Conectar via VNC/Console del proveedor 2. `sudo ufw allow 22/tcp` 3. `sudo ufw reload` 4. Verificar que SSH funciona 5. `sudo ufw enable` | C3 |
| `ssh: connect to host port 22: Connection refused` | Puerto SSH bloqueado o cambiado | `sudo ufw status \| grep 22` | 1. Acceder via consola del proveedor 2. `sudo ufw allow 22/tcp` 3. `sudo ufw reload` 4. Si puerto cambió: `sudo ufw allow N/tcp` donde N es el puerto | C3 |
| `Bad port number` | Formato de puerto inválido | `sudo ufw status numbered` | 1. Formato correcto: `22`, `22/tcp`, `8000:9000/tcp` 2. Puerto inválido: números fuera de 1-65535 3. Usar: `sudo ufw allow 5678/tcp` | - |
| `MySQL/Qdrant accesible desde internet` | Regla DENY no была добавлена o IPs incorrectas | `curl -v mysql://186.234.x.x:3306` | 1. `sudo ufw status numbered` 2. Verificar que existe `DENY 3306` y `ALLOW from 186.234.x.10` 3. Si falta: `sudo ufw insert 1 deny 3306/tcp` 4. Reiniciar: `sudo ufw reload` | C3 |
| `ufw status vacío o no muestra reglas` | UFW no está activo o está deshabilitado | `sudo systemctl status ufw` | 1. `sudo ufw enable` 2. Si no funciona: `sudo systemctl enable ufw` 3. `sudo ufw reload` 4. `sudo ufw status verbose` | - |

### Troubleshooting Detallado 1: No Se Puede Habilitar UFW

**Pasos de diagnóstico:**

```bash
# 1. Verificar que SSH está permitido
sudo ufw status | grep 22

# Si no hay salida, SSH no está permitido
# IMPORTANTE: No continuar hasta que SSH esté permitido

# 2. Permitir SSH
sudo ufw allow 22/tcp

# 3. Ahora sí activar
sudo ufw --force enable

# 4. Verificar que sigue activo después de reboot
sudo systemctl status ufw
```

---

## ✅ Validación SDD y Comandos de Verificación

### Checklist de Validación

```bash
#!/bin/bash
# /opt/mantis/scripts/validate-ufw-config.sh

ERRORS=0
VPS_TYPE="${1:-unknown}"

echo "=== Validación UFW - Mantis Agentic ==="
echo "VPS Type: ${VPS_TYPE}"

# 1. Verificar que UFW está activo
if sudo ufw status | grep -q "Status: active"; then
    echo "✅ UFW está activo"
else
    echo "❌ UFW NO está activo"
    ERRORS=$((ERRORS+1))
fi

# 2. Verificar que SSH está permitido
if sudo ufw status | grep -q "22/tcp.*ALLOW"; then
    echo "✅ SSH (22) está permitido"
else
    echo "❌ SSH (22) NO está permitido"
    ERRORS=$((ERRORS+1))
fi

# 3. Verificar que HTTP/HTTPS están permitidos
if sudo ufw status | grep -q "80/tcp.*ALLOW"; then
    echo "✅ HTTP (80) está permitido"
fi
if sudo ufw status | grep -q "443/tcp.*ALLOW"; then
    echo "✅ HTTPS (443) está permitido"
fi

# 4. Verificaciones específicas por tipo de VPS
case "${VPS_TYPE}" in
    "vps1"|"vps3")
        echo ""
        echo "=== Validación VPS n8n+uazapi ==="

        # n8n debe estar permitido
        if sudo ufw status | grep -q "5678/tcp.*ALLOW"; then
            echo "✅ n8n (5678) está permitido"
        else
            echo "❌ n8n (5678) NO está permitido"
            ERRORS=$((ERRORS+1))
        fi

        # MySQL y Qdrant deben estar DENIED desde internet
        if sudo ufw status | grep -q "3306/tcp.*DENY"; then
            echo "✅ MySQL (3306) DENEGADO desde internet"
        else
            echo "⚠️ MySQL (3306) podría estar expuesto"
        fi
        ;;

    "vps2")
        echo ""
        echo "=== Validación VPS MySQL+Qdrant ==="

        # MySQL desde IPs cross-VPS
        if sudo ufw status | grep -q "from 186.234.x.10.*3306.*ALLOW"; then
            echo "✅ MySQL permitido desde VPS-1"
        else
            echo "❌ MySQL NO permitido desde VPS-1"
            ERRORS=$((ERRORS+1))
        fi

        # MySQL DENIED desde internet
        if sudo ufw status | grep -q "3306.*DENY"; then
            echo "✅ MySQL DENEGADO desde internet"
        else
            echo "❌ MySQL podría estar expuesto a internet (CRÍTICO)"
            ERRORS=$((ERRORS+1))
        fi

        # Qdrant DENIED desde internet
        if sudo ufw status | grep -q "6333.*DENY"; then
            echo "✅ Qdrant DENEGADO desde internet"
        else
            echo "❌ Qdrant podría estar expuesto a internet (CRÍTICO)"
            ERRORS=$((ERRORS+1))
        fi
        ;;
esac

# 5. Verificar políticas por defecto
if sudo ufw status verbose | grep -q "deny (incoming)"; then
    echo "✅ Default policy: deny incoming"
else
    echo "❌ Default policy incorrecta"
    ERRORS=$((ERRORS+1))
fi

# 6. Verificar logging
if sudo ufw status verbose | grep -q "Logging: on"; then
    echo "✅ Logging habilitado"
else
    echo "⚠️ Logging no está habilitado"
fi

echo ""
if [[ $ERRORS -eq 0 ]]; then
    echo "🎉 Validación UFW: TODOS LOS CHECKS PASARON"
    exit 0
else
    echo "❌ Validación UFW: $ERRORS ERRORES ENCONTRADOS"
    exit 1
fi
```

### Comandos de Verificación Rápida

```bash
# Ver estado completo
sudo ufw status verbose

# Ver reglas numeradas
sudo ufw status numbered

# Ver logs recientes
sudo tail -20 /var/log/ufw.log

# Ver si puerto está accesible desde outside
# (ejecutar desde otra máquina)
nc -zv tu-dominio.com 22
nc -zv tu-dominio.com 3306

# Test de conectividad MySQL
nc -zv tu-dominio.com 3306

# Test de conectividad Qdrant
nc -zv tu-dominio.com 6333
```

---

## 🔗 Referencias Cruzadas y Glosario

### Archivos Relacionados

| Archivo | Descripción | Relevancia |
|---------|-------------|------------|
| [[01-RULES/03-SECURITY-RULES.md]] | Reglas de seguridad SSH y hardening | C3, hardering |
| [[01-RULES/02-RESOURCE-GUARDRAILS.md]] | Límites de recursos VPS | C1, C2 |
| [[00-CONTEXT/facundo-infrastructure.md]] | Arquitectura de 3 VPS | Topología |
| [[02-SKILLS/INFRAESTRUCTURA/ssh-key-management.md]] | Gestión de claves SSH | Puerto 22 |
| [[02-SKILLS/INFRAESTRUCTURA/fail2ban-configuration.md]] | Protección contra brute force | SSH |

### Glosario Completo

| Término | Definición | Contexto |
|---------|------------|----------|
| **UFW** | Uncomplicated Firewall - interfaz simplificada para iptables | Gestión de reglas |
| **iptables** | Sistema de filtrado de paquetes del kernel Linux | UFW genera reglas iptables |
| **Puerto** | Número identificador de servicio (0-65535) | 22=SSH, 80=HTTP, 443=HTTPS |
| **Protocolo** | TCP o UDP - tipo de comunicación | TCP para HTTP, SSH, MySQL |
| **Default policy** | Regla aplicada cuando no hay coincidencia explícita | `deny incoming`, `allow outgoing` |
| **Ingress** | Tráfico entrante al servidor | Controlado por `deny incoming` |
| **Egress** | Tráfico saliente del servidor | Generalmente `allow outgoing` |
| **Cross-VPS** | Comunicación entre VPS de la misma infraestructura | MySQL/Qdrant via túnel SSH |

### Variables de Entorno Relacionadas

```bash
# /etc/environment o ~/.bashrc

# Alias útiles para gestión UFW
alias ufw-status='sudo ufw status verbose'
alias ufw-log='sudo tail -50 /var/log/ufw.log'
alias ufw-rules='sudo ufw status numbered'
```

### URLs Raw para IAs

```
Base: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/

https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/02-SKILLS/INFRAESTRUCTURA/ufw-firewall-configuration.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/01-RULES/03-SECURITY-RULES.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/00-CONTEXT/facundo-infrastructure.md
```

---

**Versión 1.0.0 - 2026-04-09 - Mantis-AgenticDev**
**Licencia:** Creative Commons para uso interno del proyecto
