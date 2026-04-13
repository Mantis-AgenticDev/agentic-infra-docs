---
ai_optimized: true
title: "00-INDEX: Docker Compose — Red Inter-VPS MANTIS AGENTIC"
version: "1.0.0"
canonical_path: "05-CONFIGURATIONS/docker-compose/00-INDEX.md"
status: "PRODUCTION_READY"
constraints_mapped: ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8"]
gate_status: "PASSED (7/7)"
audience: "Junior → Senior — leer completo antes de cualquier deploy"
last_updated: "2026-04-13"
related_files:
  - "[[05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml]]"
  - "[[05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.yml]]"
  - "[[05-CONFIGURATIONS/docker-compose/vps3-n8n-uazapi.yml]]"
  - "[[05-CONFIGURATIONS/00-INDEX.md]]"
  - "[[05-CONFIGURATIONS/validation/validate-skill-integrity.sh]]"
  - "[[05-CONFIGURATIONS/terraform/modules/vps-base/main.tf]]"
  - "[[02-SKILLS/INFRASTRUCTURA/vps-interconnection.md]]"
  - "[[02-SKILLS/INFRASTRUCTURA/ssh-tunnels-remote-services.md]]"
  - "[[02-SKILLS/INFRASTRUCTURA/ssh-key-management.md]]"
  - "[[02-SKILLS/INFRASTRUCTURA/ufw-firewall-configuration.md]]"
  - "[[02-SKILLS/INFRAESTRUCTURA/n8n-concurrency-limiting.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/mysql-sql-rag-ingestion.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/redis-session-management.md]]"
  - "[[02-SKILLS/SEGURIDAD/security-hardening-vps.md]]"
  - "[[02-SKILLS/SEGURIDAD/backup-encryption.md]]"
  - "[[01-RULES/01-ARCHITECTURE-RULES.md]]"
  - "[[01-RULES/02-RESOURCE-GUARDRAILS.md]]"
  - "[[01-RULES/03-SECURITY-RULES.md]]"
  - "[[01-RULES/06-MULTITENANCY-RULES.md]]"
---

# 🌐 Red MANTIS AGENTIC — Guía Completa de 3 VPS Interconectados

> **Para juniors:** Lee este documento entero antes de tocar cualquier archivo de configuración.
> Contiene el "por qué" detrás de cada decisión de arquitectura.
> **Para seniors:** La sección de SSH Tunnels y el diagrama de red son los más relevantes.

---

## 📚 Tabla de Contenidos

1. [¿Qué tenemos y por qué? (Conceptos para juniors)](#conceptos)
2. [Visión General de la Red](#vision-general)
3. [Los 3 Archivos Docker Compose](#los-3-archivos)
4. [Configuración de Hardware por Servidor](#hardware)
5. [Red Interna — SSH Tunnels (CRÍTICO leer)](#ssh-tunnels)
6. [Flujo de Tráfico Completo](#flujo-trafico)
7. [Proceso de Deploy Paso a Paso](#deploy)
8. [Operaciones del Día a Día](#operaciones)
9. [Tabla de Validación (15 checks)](#validacion)
10. [Troubleshooting](#troubleshooting)

---

## <a name="conceptos"></a>📐 Fundamentos para Juniors — ¿Qué tenemos y por qué?

### ¿Por qué 3 servidores y no 1?

Un servidor único con todo tiene un problema fundamental: **es un punto único de fallo**. Si cae, todo cae. Con 3 servidores especializados:

```
Un servidor para todo (MAL):
├── Si el disco se llena de logs → MySQL cae → EspoCRM cae → n8n cae → WhatsApp cae
└── Un solo problema tumba el servicio completo

Tres servidores especializados (BIEN):
├── VPS1 solo corre n8n + WhatsApp → si cae, VPS3 puede tomar el trabajo
├── VPS2 solo corre las bases de datos → optimizado para I/O, no para CPU
└── VPS3 es el respaldo de VPS1 → permite mantenimiento sin downtime
```

### ¿Por qué MySQL y Qdrant no son públicos?

Imagina que tu base de datos es una caja fuerte con todos los datos de tus clientes. Podrías:

- **Opción A (mala):** Poner la caja fuerte en la vidriera de tu negocio, visible desde la calle.
- **Opción B (buena):** Mantener la caja fuerte en la sala trasera, accesible solo para empleados con llave especial (clave SSH).

En MANTIS, la "sala trasera" es la red interna de Docker. La "llave especial" son los túneles SSH. Nadie en internet puede ver ni tocar MySQL o Qdrant directamente.

### ¿Qué es un túnel SSH?

Sin túnel:
```
Tu aplicación (VPS1) ──────── INTERNET ──────── MySQL (VPS2)
                         (datos visibles, riesgo)
```

Con túnel SSH:
```
Tu aplicación (VPS1) ──── túnel SSH cifrado ──── MySQL (VPS2)
localhost:3306              (datos cifrados)       puerto real
                   (para la app es "local" pero en realidad es remoto)
```

La aplicación cree que MySQL está en `localhost:3306`. En realidad, el túnel SSH redirige silenciosamente esa conexión al MySQL real en VPS2, a través de un canal cifrado. **Para afuera es invisible.**

### ¿Qué es EspoCRM y por qué SÍ es público?

EspoCRM es la interfaz web del CRM que los clientes usan para ver sus contactos, leads y reportes. Es como el "panel de administración" del negocio. Necesita ser accesible desde un navegador → debe tener acceso HTTPS público. Pero solo EspoCRM, no la base de datos que está detrás.

```
Cliente en su navegador:
  https://crm.tudominio.com.br  →  EspoCRM  →  MySQL (interno)
                                               ↑ solo accesible internamente
```

---

## <a name="vision-general"></a>🗺️ Visión General de la Red

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                    MANTIS AGENTIC — ARQUITECTURA DE RED COMPLETA             ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  INTERNET                                                                    ║
║     │                                                                        ║
║     ├─────── HTTPS:443 ──────────────┬────────────────────────────────────── ║
║     │                                │                                       ║
║     ▼                                ▼                                       ║
║  ┌──────────────────────┐    ┌──────────────────────────┐                    ║
║  │  VPS1 (KVM1/KVM2)    │    │  VPS2 (KVM1/KVM2)        │                    ║
║  │  n8n + uazapi + Redis│    │  EspoCRM + MySQL + Qdrant│                    ║
║  │                      │    │                          │                    ║
║  │  Traefik:443 ─► n8n  │    │  Traefik:443 ─► EspoCRM  │                    ║
║  │  uazapi (interno)    │    │  MySQL  (127.0.0.1:3306) │◄── SSH Tunnel ──┐  ║
║  │  Redis  (127.x:6379) │    │  Qdrant (127.0.0.1:6333) │◄── SSH Tunnel ──┤  ║
║  │                      │    │                          │                 │  ║
║  │  IP pública: x.x.x.1 │    │  IP pública: x.x.x.2    │                  │  ║
║  └──────────┬───────────┘    └──────────────────────────┘                 │  ║
║             │                                                             │  ║
║             │ SSH Tunnel (desde VPS1 a VPS2):                             │  ║
║             │   localhost:3306 → VPS2:3306 (MySQL)                        │  ║
║             │   localhost:6333 → VPS2:6333 (Qdrant)                       │  ║
║             │                                                             │  ║
║             └──── mismo patrón ───────────────────────────────────────── ─┘  ║
║                                                                              ║
║  ┌──────────────────────────────────────────────────────────────────────┐    ║
║  │  VPS3 (KVM1/KVM2)  — Failover / Tenants adicionales                  │    ║
║  │  n8n + uazapi + Redis (arquitectura idéntica a VPS1)                 │    ║
║  │                                                                      │    ║
║  │  Traefik:443 ─► n8n-backup.dominio.com                               │    ║
║  │  SSH Tunnel → VPS2:3306 (MySQL)   localhost:3307 en VPS3             │    ║
║  │  SSH Tunnel → VPS2:6333 (Qdrant)  localhost:6334 en VPS3             │    ║
║  │                                                                      │    ║
║  │  IP pública: x.x.x.3                                                 │    ║
║  └──────────────────────────────────────────────────────────────────────┘    ║
║                                                                              ║
║  REGLA C3 ABSOLUTA:                                                          ║
║  ✅ Solo HTTPS:443 y SSH:22 tienen acceso desde internet                     ║
║  ❌ MySQL:3306, Qdrant:6333/6334, Redis:6379 NUNCA accesibles públicamente   ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

### Tabla de Puertos — Qué es público y qué no

| Servicio | VPS | Puerto | ¿Público? | Razón |
|---|---|---|---|---|
| HTTPS | VPS1/2/3 | 443 | ✅ SÍ | Necesario para usuarios |
| HTTP redirect | VPS1/2/3 | 80 | ✅ SÍ | Solo para redirigir a 443 |
| SSH | VPS1/2/3 | 22 | ✅ SÍ (solo clave) | Administración segura |
| n8n | VPS1/3 | 5678 | 🔒 Vía Traefik | Protegido por TLS + BasicAuth |
| EspoCRM | VPS2 | 80 interno | 🔒 Vía Traefik | Protegido por TLS + RateLimit |
| MySQL | VPS2 | 3306 | ❌ NUNCA | Solo red Docker interna |
| Qdrant REST | VPS2 | 6333 | ❌ NUNCA | Solo localhost o SSH tunnel |
| Qdrant gRPC | VPS2 | 6334 | ❌ NUNCA | Solo localhost o SSH tunnel |
| Redis | VPS1/3 | 6379 | ❌ NUNCA | Solo red Docker interna |
| OTEL Collector | VPS1/2/3 | 4317/4318 | ❌ NUNCA | Solo localhost |
| Traefik Dashboard | VPS1/2/3 | 8080 | ❌ NUNCA | Solo localhost |

---

## <a name="los-3-archivos"></a>📁 Los 3 Archivos Docker Compose

| Archivo | Servicios | Rol en la Red | Acceso Público |
|---|---|---|---|
| `vps1-n8n-uazapi.yml` | n8n + uazapi + Redis + Traefik + OTEL | Orquestador principal | n8n vía HTTPS |
| `vps2-crm-qdrant.yml` | EspoCRM + MySQL + Qdrant + Traefik + OTEL | Hub de datos | Solo EspoCRM vía HTTPS |
| `vps3-n8n-uazapi.yml` | n8n + uazapi + Redis + Traefik + OTEL | Failover/Tenants adicionales | n8n-backup vía HTTPS |

### Subnets Docker (sin colisiones)

| VPS | Subnet Docker | Por qué diferente |
|---|---|---|
| VPS1 | `172.20.0.0/24` | Base |
| VPS2 | `172.21.0.0/24` | Evita colisión si los 3 VPS comparten IP pública temporal |
| VPS3 | `172.22.0.0/24` | Ídem |

---

## <a name="hardware"></a>⚙️ Configuración de Hardware por Servidor

### KVM1 (Hostinger) — Configuración Inicial

| VPS | vCPU | RAM | NVMe | Bandwidth |
|---|---|---|---|---|
| VPS1 | 1 núcleo | 4 GB | 50 GB | 4 TB |
| VPS2 | 1 núcleo | 4 GB | 50 GB | 4 TB |
| VPS3 | 1 núcleo | 4 GB | 50 GB | 4 TB |

**Cuándo KVM1 es insuficiente para VPS2:**
- `docker stats` muestra MySQL + Qdrant > 3GB constantes
- Consultas RAG con latencia > 2 segundos regularmente
- Más de 5 tenants activos simultáneos con bases de datos grandes

### KVM2 (Hostinger) — Scale-Up

| VPS | vCPU | RAM | NVMe | Bandwidth |
|---|---|---|---|---|
| VPS1 | 2 núcleos | 8 GB | 100 GB | 8 TB |
| VPS2 | 2 núcleos | 8 GB | 100 GB | 8 TB |
| VPS3 | 2 núcleos | 8 GB | 100 GB | 8 TB |

**Recomendación:** Empezar con KVM1 en los 3 VPS. Escalar VPS2 a KVM2 primero (es el hub de datos y el que más se beneficia de más RAM para MySQL y Qdrant).

---

## <a name="ssh-tunnels"></a>🔐 Red Interna — SSH Tunnels (LEER COMPLETO)

Esta es la parte más importante para entender cómo VPS1 y VPS3 hablan con MySQL y Qdrant en VPS2 **sin exponer nada al internet**.

### Paso 0 — Requisito Previo: Claves SSH entre VPS

Antes de configurar túneles, VPS1 y VPS3 necesitan poder conectar a VPS2 sin contraseña (autenticación por clave).

```bash
# Ejecutar en VPS1 (y repetir en VPS3)
# ──────────────────────────────────────────────────────────────────
# PASO 1: Generar par de claves en VPS1 (si no existe)
# ⚠️ Junior: Cuando pregunte "passphrase", dejar vacío para tunnels automáticos
ssh-keygen -t ed25519 -C "vps1-mantis-tunnel" -f ~/.ssh/vps1_tunnel -N ""

# Ver la clave pública generada
cat ~/.ssh/vps1_tunnel.pub
# Output ejemplo: ssh-ed25519 AAAAC3Nz... vps1-mantis-tunnel

# PASO 2: Copiar la clave pública a VPS2
# Reemplazar IP_VPS2 con la IP real de tu VPS2
ssh-copy-id -i ~/.ssh/vps1_tunnel.pub root@IP_VPS2
# Pedirá contraseña de root de VPS2 (solo esta vez)

# PASO 3: Verificar que funciona SIN contraseña
ssh -i ~/.ssh/vps1_tunnel root@IP_VPS2 "echo 'Conexion exitosa'"
# ✅ Deberías ver: Conexion exitosa
# ❌ Si ves: Permission denied → revisar que se copió la clave correctamente
```

### Paso 1 — Configurar SSH Config File (Simplifica todo)

```bash
# En VPS1 y VPS3: editar ~/.ssh/config
# Este archivo permite usar "vps2" en vez de "root@IP_VPS2 -i ~/.ssh/vps1_tunnel"
cat > ~/.ssh/config << 'EOF'
# Configuración de conexión a VPS2 desde VPS1/VPS3
Host vps2
    HostName IP_VPS2              # ← Reemplazar con IP real de VPS2
    User root
    IdentityFile ~/.ssh/vps1_tunnel
    ServerAliveInterval 30        # Mantener conexión viva
    ServerAliveCountMax 3         # Reintentar 3 veces antes de cerrar
    StrictHostKeyChecking no      # Solo para primer uso; cambiar a yes después
    ConnectTimeout 10

# Para acceder directamente a MySQL en VPS2 desde tu laptop (solo en desarrollo)
Host vps2-mysql-dev
    HostName IP_VPS2
    User root
    IdentityFile ~/.ssh/tu_clave_laptop
    LocalForward 13306 127.0.0.1:3306   # localhost:13306 → VPS2:MySQL
EOF

chmod 600 ~/.ssh/config

# Probar
ssh vps2 "echo 'Config OK'"
# ✅ Deberías ver: Config OK
```

### Paso 2 — Crear Túneles Persistentes con autossh

`autossh` es como SSH pero se reinicia solo si la conexión cae. **Imprescindible en producción.**

```bash
# Instalar autossh en VPS1 y VPS3
apt-get install -y autossh

# ─────────────────────────────────────────────────────────────────────────
# TUNNEL 1: MySQL (VPS2:3306 → VPS1:localhost:3306)
# ─────────────────────────────────────────────────────────────────────────
# Lo que hace: cuando n8n en VPS1 conecta a localhost:3306,
#              se redirige automáticamente a MySQL en VPS2.
# Para la app n8n es transparente: cree que MySQL está local.
#
# -L 3306:localhost:3306  = "Escucha en mi puerto 3306,
#                            conecta a localhost:3306 del servidor destino (VPS2)"
#
# ⚠️ Junior: El primer 3306 es el puerto LOCAL (en VPS1).
#            El segundo 3306 es el puerto en VPS2 (donde escucha MySQL).
# ─────────────────────────────────────────────────────────────────────────
autossh -M 0 -f -N \
  -o "ServerAliveInterval=30" \
  -o "ServerAliveCountMax=3" \
  -o "ExitOnForwardFailure=yes" \
  -L "127.0.0.1:3306:127.0.0.1:3306" \
  vps2

# ─────────────────────────────────────────────────────────────────────────
# TUNNEL 2: Qdrant REST (VPS2:6333 → VPS1:localhost:6333)
# ─────────────────────────────────────────────────────────────────────────
autossh -M 0 -f -N \
  -o "ServerAliveInterval=30" \
  -o "ServerAliveCountMax=3" \
  -o "ExitOnForwardFailure=yes" \
  -L "127.0.0.1:6333:127.0.0.1:6333" \
  vps2

# ─────────────────────────────────────────────────────────────────────────
# TUNNEL 3: Qdrant gRPC (VPS2:6334 → VPS1:localhost:6334)
# ─────────────────────────────────────────────────────────────────────────
autossh -M 0 -f -N \
  -o "ServerAliveInterval=30" \
  -o "ServerAliveCountMax=3" \
  -o "ExitOnForwardFailure=yes" \
  -L "127.0.0.1:6334:127.0.0.1:6334" \
  vps2

# Verificar que los túneles están activos
ss -tulpn | grep -E '3306|6333|6334'
# ✅ Deberías ver: 3 líneas con 127.0.0.1 escuchando en esos puertos
# ❌ Si no ves nada: autossh no arrancó → ver logs: journalctl -u autossh-mysql
```

### Paso 3 — Hacer los Túneles Permanentes con Systemd

Los túneles arriba se perderán si el servidor reinicia. Systemd los mantiene activos siempre:

```bash
# Crear servicio systemd para cada túnel
# Repetir este proceso para cada túnel (mysql, qdrant-rest, qdrant-grpc)

# ── Servicio para túnel MySQL ────────────────────────────────────────────
cat > /etc/systemd/system/mantis-tunnel-mysql.service << 'EOF'
[Unit]
Description=MANTIS SSH Tunnel — MySQL VPS2
Documentation=https://github.com/Mantis-AgenticDev/agentic-infra-docs
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
# C3: Variables de entorno desde archivo (nunca hardcodeadas en el servicio)
EnvironmentFile=/etc/mantis/tunnels.env

ExecStart=/usr/bin/autossh -M 0 -N \
  -o "ServerAliveInterval=30" \
  -o "ServerAliveCountMax=3" \
  -o "ExitOnForwardFailure=yes" \
  -o "StrictHostKeyChecking=accept-new" \
  -i /root/.ssh/vps1_tunnel \
  -L "127.0.0.1:3306:127.0.0.1:3306" \
  root@${VPS2_IP}

# C7: Reinicio automático con backoff exponencial
Restart=on-failure
RestartSec=5s
RestartSteps=10
RestartMaxDelaySec=60s

# C8: Logs estructurados
StandardOutput=journal
StandardError=journal
SyslogIdentifier=mantis-tunnel-mysql

[Install]
WantedBy=multi-user.target
EOF

# ── Archivo de variables de entorno del túnel (C3) ──────────────────────
mkdir -p /etc/mantis
cat > /etc/mantis/tunnels.env << 'EOF'
# Variables para los servicios de túneles SSH
# C3: Este archivo tampoco va a git (contiene IP del servidor)
VPS2_IP=IP_REAL_DE_VPS2   # ← CAMBIAR por la IP real
EOF
chmod 600 /etc/mantis/tunnels.env

# ── Repetir para Qdrant REST ─────────────────────────────────────────────
cat > /etc/systemd/system/mantis-tunnel-qdrant-rest.service << 'EOF'
[Unit]
Description=MANTIS SSH Tunnel — Qdrant REST VPS2
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
EnvironmentFile=/etc/mantis/tunnels.env
ExecStart=/usr/bin/autossh -M 0 -N \
  -o "ServerAliveInterval=30" \
  -o "ServerAliveCountMax=3" \
  -o "ExitOnForwardFailure=yes" \
  -i /root/.ssh/vps1_tunnel \
  -L "127.0.0.1:6333:127.0.0.1:6333" \
  root@${VPS2_IP}
Restart=on-failure
RestartSec=5s
RestartSteps=10
RestartMaxDelaySec=60s
StandardOutput=journal
SyslogIdentifier=mantis-tunnel-qdrant-rest

[Install]
WantedBy=multi-user.target
EOF

# ── Repetir para Qdrant gRPC ─────────────────────────────────────────────
cat > /etc/systemd/system/mantis-tunnel-qdrant-grpc.service << 'EOF'
[Unit]
Description=MANTIS SSH Tunnel — Qdrant gRPC VPS2
After=network-online.target

[Service]
Type=simple
User=root
EnvironmentFile=/etc/mantis/tunnels.env
ExecStart=/usr/bin/autossh -M 0 -N \
  -o "ServerAliveInterval=30" \
  -o "ServerAliveCountMax=3" \
  -o "ExitOnForwardFailure=yes" \
  -i /root/.ssh/vps1_tunnel \
  -L "127.0.0.1:6334:127.0.0.1:6334" \
  root@${VPS2_IP}
Restart=on-failure
RestartSec=5s
RestartSteps=10
RestartMaxDelaySec=60s
StandardOutput=journal
SyslogIdentifier=mantis-tunnel-qdrant-grpc

[Install]
WantedBy=multi-user.target
EOF

# ── Habilitar e iniciar los 3 servicios ──────────────────────────────────
systemctl daemon-reload

for service in mantis-tunnel-mysql mantis-tunnel-qdrant-rest mantis-tunnel-qdrant-grpc; do
  systemctl enable "$service"
  systemctl start "$service"
  sleep 2
  systemctl is-active "$service" && echo "✅ $service activo" || echo "❌ $service falló"
done

# Verificar los 3 túneles activos
ss -tulpn | grep -E '127.0.0.1:(3306|6333|6334)'
# ✅ Deberías ver 3 líneas
```

### Paso 4 — VPS3 usa puertos distintos para evitar conflictos

VPS3 tiene la misma configuración que VPS1 pero **usa puertos locales diferentes** para los túneles, en caso de que ambos VPS alguna vez corran en el mismo host físico (migración, mantenimiento):

```bash
# En VPS3: usar puertos 3307 y 6334 localmente
# (VPS2 sigue escuchando en 3306 y 6333 — solo el puerto local cambia)

autossh -M 0 -f -N \
  -L "127.0.0.1:3307:127.0.0.1:3306" \  # ← Puerto local 3307 (no 3306)
  vps2

autossh -M 0 -f -N \
  -L "127.0.0.1:6334:127.0.0.1:6333" \  # ← Puerto local 6334 (no 6333)
  vps2

# Por eso en .env.vps3.example:
# MYSQL_TUNNEL_PORT=3307
# QDRANT_TUNNEL_URL=http://127.0.0.1:6334
```

---

## <a name="flujo-trafico"></a>🔄 Flujo de Tráfico Completo

### Flujo: Mensaje WhatsApp → Respuesta RAG

```
1. Usuario manda mensaje WhatsApp
   └─► uazapi (VPS1, red interna Docker)

2. uazapi → webhook → n8n (VPS1, localhost:5678)
   └─► C4: tenant_id validado en primer nodo del workflow

3. n8n genera embedding del mensaje
   └─► OpenRouter API (internet, C6: cloud-only)

4. n8n busca en Qdrant chunks relevantes
   └─► localhost:6333 (VPS1) → SSH Tunnel → Qdrant (VPS2:6333)
   └─► C4: filter={tenant_id: "restaurante_001"}

5. n8n llama al LLM con contexto RAG
   └─► OpenRouter API (internet, C6)

6. n8n guarda la interacción en MySQL
   └─► localhost:3306 (VPS1) → SSH Tunnel → MySQL (VPS2:3306)
   └─► C4: INSERT con tenant_id

7. n8n actualiza sesión en Redis
   └─► redis (red Docker interna VPS1)

8. n8n envía respuesta a uazapi
   └─► uazapi → WhatsApp → Usuario
```

### Flujo: Cliente accede al CRM EspoCRM

```
1. Cliente abre navegador: https://crm.tudominio.com.br
   └─► DNS → IP pública VPS2

2. VPS2 Traefik recibe la petición HTTPS
   └─► Verifica certificado TLS (Let's Encrypt)
   └─► Aplica rate limiting (60 req/min)
   └─► Aplica security headers (HSTS, XSS)

3. Traefik proxy → EspoCRM (red Docker interna VPS2)
   └─► PHP-FPM procesa la petición

4. EspoCRM consulta MySQL
   └─► mysql:3306 (nombre de servicio Docker, red interna)
   └─► C4: WHERE tenant_id = 'restaurante_001'

5. EspoCRM retorna HTML → Traefik → HTTPS → Cliente
```

---

## <a name="deploy"></a>🚀 Proceso de Deploy Completo (Orden Obligatorio)

### Orden de Deploy — VPS2 SIEMPRE primero

```bash
# ═══════════════════════════════════════════════════════════════════
# ORDEN OBLIGATORIO: VPS2 → VPS1 → VPS3
# Razón: VPS1 y VPS3 dependen de MySQL y Qdrant en VPS2.
#         Si se inicia VPS1 antes que VPS2, los workflows fallarán.
# ═══════════════════════════════════════════════════════════════════

# ── PASO 1: Deploy VPS2 (Hub de datos) ──────────────────────────────────
echo "🗄️ Iniciando VPS2 (MySQL + EspoCRM + Qdrant)..."
ssh root@IP_VPS2 "
  cd /opt/mantis &&
  source .env.vps2 &&
  docker compose -f 05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.yml \
    --env-file .env.vps2 \
    up -d --remove-orphans --wait
"
echo "⏳ Esperando que MySQL esté listo (90s)..."
sleep 90

# Verificar VPS2 saludable
ssh root@IP_VPS2 "docker ps --filter 'health=unhealthy' | wc -l"
# ✅ Deberías ver: 0 (ningún servicio unhealthy)

# ── PASO 2: Configurar SSH Tunnels en VPS1 ────────────────────────────
echo "🔐 Configurando túneles SSH en VPS1..."
ssh root@IP_VPS1 "
  systemctl start mantis-tunnel-mysql &&
  systemctl start mantis-tunnel-qdrant-rest &&
  systemctl start mantis-tunnel-qdrant-grpc
  sleep 3
  ss -tulpn | grep -E '127.0.0.1:(3306|6333|6334)'
"
# ✅ Deberías ver: 3 líneas con túneles activos

# ── PASO 3: Deploy VPS1 ──────────────────────────────────────────────
echo "🤖 Iniciando VPS1 (n8n + uazapi + Redis)..."
ssh root@IP_VPS1 "
  cd /opt/mantis &&
  docker compose -f 05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml \
    --env-file .env.vps1 \
    up -d --remove-orphans --wait
"

# ── PASO 4: Deploy VPS3 (si está en uso) ─────────────────────────────
echo "🔄 Iniciando VPS3 (Failover)..."
ssh root@IP_VPS3 "
  systemctl start mantis-tunnel-mysql &&
  systemctl start mantis-tunnel-qdrant-rest
  cd /opt/mantis &&
  docker compose -f 05-CONFIGURATIONS/docker-compose/vps3-n8n-uazapi.yml \
    --env-file .env.vps3 \
    up -d --remove-orphans --wait
"

echo "✅ Deploy completo de los 3 VPS"
```

### Script de Verificación Post-Deploy

```bash
#!/bin/bash
# scripts/verify-network-health.sh
# Ejecutar después del deploy para verificar que los 3 VPS están conectados

set -euo pipefail

VPS1_IP="${VPS1_IP:?VPS1_IP requerida}"
VPS2_IP="${VPS2_IP:?VPS2_IP requerida}"
VPS3_IP="${VPS3_IP:?VPS3_IP requerida}"

PASS=0; FAIL=0

check() {
  local desc="$1"; local cmd="$2"; local expected="$3"
  result=$(eval "$cmd" 2>/dev/null || echo "ERROR")
  if echo "$result" | grep -qiP "$expected"; then
    echo "  ✅ $desc"; ((PASS++))
  else
    echo "  ❌ $desc | Got: ${result:0:60}"; ((FAIL++))
  fi
}

echo "═══ VERIFICACIÓN RED MANTIS 3-VPS ═══"

echo "─── VPS2: Servicios internos ───"
check "MySQL saludable" \
  "ssh root@$VPS2_IP 'docker inspect --format={{.State.Health.Status}} mantis-mysql'" \
  "healthy"
check "Qdrant saludable" \
  "ssh root@$VPS2_IP 'docker inspect --format={{.State.Health.Status}} mantis-qdrant'" \
  "healthy"
check "EspoCRM accesible" \
  "curl -sf -o /dev/null -w '%{http_code}' https://crm.${CRM_DOMAIN:-tudominio.com.br}" \
  "200|301|302"

echo "─── VPS1: Tunnels y servicios ───"
check "Tunnel MySQL activo en VPS1" \
  "ssh root@$VPS1_IP 'ss -tulpn | grep 127.0.0.1:3306'" \
  "127.0.0.1"
check "Tunnel Qdrant activo en VPS1" \
  "ssh root@$VPS1_IP 'ss -tulpn | grep 127.0.0.1:6333'" \
  "127.0.0.1"
check "VPS1 puede hacer ping a MySQL via tunnel" \
  "ssh root@$VPS1_IP 'mysqladmin ping -h 127.0.0.1 -P 3306 -u root -p\${MYSQL_ROOT_PASSWORD} 2>/dev/null'" \
  "mysqld is alive"
check "n8n saludable en VPS1" \
  "ssh root@$VPS1_IP 'docker inspect --format={{.State.Health.Status}} mantis-n8n'" \
  "healthy"

echo "─── VPS3: Tunnels y servicios ───"
check "Tunnel MySQL activo en VPS3" \
  "ssh root@$VPS3_IP 'ss -tulpn | grep 127.0.0.1:3307'" \
  "127.0.0.1"
check "n8n saludable en VPS3" \
  "ssh root@$VPS3_IP 'docker inspect --format={{.State.Health.Status}} mantis-vps3-n8n'" \
  "healthy"

echo ""
echo "═══════════════════════════════════════════"
echo "RESULTADO: ✅ $PASS checks pasaron | ❌ $FAIL fallaron"
[ $FAIL -eq 0 ] && \
  echo "🎉 Red MANTIS 3-VPS operacional" && exit 0 || exit 1
```

---

## <a name="operaciones"></a>🔧 Operaciones del Día a Día

### Ver estado de todos los servicios

```bash
# Ver servicios en los 3 VPS simultáneamente
for vps in $VPS1_IP $VPS2_IP $VPS3_IP; do
  echo "─── $vps ───"
  ssh root@$vps "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
  echo ""
done
```

### Ver consumo de recursos

```bash
# Consumo en tiempo real (C1/C2 monitoring)
ssh root@$VPS2_IP "docker stats --no-stream \
  --format 'table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}'"

# Esperado en KVM1 VPS2:
# mantis-mysql    800MiB / 1GiB      15%
# mantis-qdrant   600MiB / 1GiB      5%
# mantis-espocrm  300MiB / 512MiB    2%
# mantis-traefik  50MiB  / 128MiB    1%
```

### Backup manual (C5)

```bash
# Backup de MySQL (ejecutar en VPS2)
ssh root@$VPS2_IP "
  TIMESTAMP=\$(date +%Y%m%d_%H%M%S)
  docker exec mantis-mysql mysqldump \
    -u root -p\${MYSQL_ROOT_PASSWORD} \
    --all-databases \
    --single-transaction \
    | gzip > /opt/mantis/backups/mysql_\${TIMESTAMP}.sql.gz
  sha256sum /opt/mantis/backups/mysql_\${TIMESTAMP}.sql.gz
"

# Snapshot de Qdrant (ejecutar en VPS2)
ssh root@$VPS2_IP "
  curl -X POST \
    -H 'api-key: \${QDRANT_API_KEY}' \
    'http://127.0.0.1:6333/snapshots'
"
```

### Revisar túneles SSH

```bash
# Estado de los servicios de túneles
ssh root@$VPS1_IP "
  for svc in mantis-tunnel-mysql mantis-tunnel-qdrant-rest mantis-tunnel-qdrant-grpc; do
    echo -n \"\$svc: \"
    systemctl is-active \$svc
  done
"

# Si un túnel falló, reiniciar
ssh root@$VPS1_IP "systemctl restart mantis-tunnel-mysql"
```

### Failover manual VPS1 → VPS3

```bash
# Si VPS1 cae y necesitas activar VPS3 como primario:

# 1. Verificar que VPS3 está operacional
ssh root@$VPS3_IP "docker ps | grep mantis-vps3-n8n"

# 2. Actualizar DNS para apuntar al dominio n8n al IP de VPS3
# (hacerlo en el panel de DNS de tu registrador)
# n8n.tudominio.com → IP_VPS3

# 3. Notificar al equipo
echo "⚠️ FAILOVER ACTIVADO: n8n ahora en VPS3 ($VPS3_IP)"
echo "   DNS actualizado: n8n.tudominio.com → $VPS3_IP"
echo "   Sesiones WhatsApp necesitan reconexión manual"
```

---

## <a name="validacion"></a>✅ Tabla de Validación Completa — Red 3-VPS

| # | Check | Constraint | Donde Verificar | ✅ Deberías ver | ❌ Si ves esto | Solución |
|---|---|---|---|---|---|---|
| 1 | MySQL no accesible desde internet | C3 | Desde tu laptop: `nc -zv IP_VPS2 3306` | `Connection refused` o `timeout` | Conexión exitosa | **CRÍTICO:** MySQL tiene puerto público. Eliminar `ports:` en el compose y reiniciar |
| 2 | Qdrant no accesible desde internet | C3 | Desde tu laptop: `nc -zv IP_VPS2 6333` | `Connection refused` | Conexión exitosa | Verificar que `ports` en Qdrant sea `127.0.0.1:6333:6333` |
| 3 | SSH tunnel MySQL activo en VPS1 | C3/C7 | En VPS1: `ss -tulpn \| grep 127.0.0.1:3306` | `127.0.0.1:3306` escuchando | Sin output | Iniciar servicio: `systemctl start mantis-tunnel-mysql` |
| 4 | VPS1 puede conectar a MySQL via tunnel | C7 | En VPS1: `mysqladmin ping -h 127.0.0.1 -P 3306 -u root -p$PASS` | `mysqld is alive` | `Access denied` o timeout | Verificar credenciales en `.env.vps1` y que el tunnel está activo |
| 5 | Subnets Docker no colisionan | C7 | `docker network ls` en cada VPS | VPS1: `172.20.x`, VPS2: `172.21.x`, VPS3: `172.22.x` | Misma subnet en 2 VPS | Modificar `subnet:` en el compose del VPS conflictivo |
| 6 | EspoCRM accesible vía HTTPS | C3 | `curl -sf https://crm.dominio.com` | HTTP 200 o redirect | Connection refused | Verificar Traefik y certificado TLS |
| 7 | n8n protegido con BasicAuth | C3 | `curl -sf https://n8n.dominio.com` | HTTP 401 sin credenciales | HTTP 200 (acceso libre) | Verificar `N8N_BASIC_AUTH_ACTIVE=true` |
| 8 | Redis no accesible desde internet | C3 | Desde laptop: `redis-cli -h IP_VPS1 -p 6379 ping` | `Could not connect` | `PONG` | Redis tiene puerto público. Cambiar a `127.0.0.1:6379:6379` |
| 9 | Túneles systemd con reinicio automático | C7 | `systemctl show mantis-tunnel-mysql \| grep Restart=` | `Restart=on-failure` | `Restart=no` | Editar el .service y recargar: `systemctl daemon-reload` |
| 10 | MySQL healthcheck con start_period 120s | C7 | `grep 'start_period' vps2-crm-qdrant.yml` | `120s` o más | `< 60s` | MySQL necesita tiempo para inicializar tablespaces la primera vez |
| 11 | tenant_id en todos los containers | C4 | `docker inspect mantis-n8n \| grep TENANT_ID` | `TENANT_ID=restaurante_001` | Sin output | Verificar que `.env` tiene TENANT_ID y fue cargado |
| 12 | Logs son JSON en todos los servicios | C8 | `docker logs mantis-n8n --tail 5 \| python3 -m json.tool` | JSON válido | Texto plano | Verificar configuración de logging en el compose |
| 13 | Backup labels en todos los volúmenes | C5 | `docker volume inspect mantis-mysql-data \| grep backup` | `"mantis.backup": "daily"` | Sin labels | Agregar `labels:` con `mantis.backup` a los volúmenes |
| 14 | ICC deshabilitado en redes Docker | C3 | `docker network inspect mantis-internal-vps2 \| grep icc` | `"enable_icc": "false"` | `"enable_icc": "true"` | Recrear la red con `enable_icc: "false"` |
| 15 | autossh reinicia tunnel si cae VPS2 | C7 | Simular: `ssh root@VPS2 "systemctl stop docker"` → esperar 60s → reiniciar | Tunnel se reconecta solo | Tunnel se queda caído | Verificar `RestartSec` y `RestartMaxDelaySec` en el .service |

---

## <a name="troubleshooting"></a>🐞 Troubleshooting Común

| Error | VPS | Causa | Diagnóstico | Solución |
|---|---|---|---|---|
| `n8n no puede conectar a MySQL` | VPS1 | Tunnel SSH caído | `systemctl status mantis-tunnel-mysql` | `systemctl restart mantis-tunnel-mysql` |
| `EspoCRM: Error de BD` | VPS2 | MySQL contenedor caído o reiniciando | `docker ps \| grep mysql` + `docker logs mantis-mysql` | `docker compose restart mysql` en VPS2 |
| `Qdrant: Connection refused` | VPS1/3 | Tunnel Qdrant caído | `ss -tulpn \| grep 6333` | `systemctl restart mantis-tunnel-qdrant-rest` |
| `OOM: MySQL killed` | VPS2 | `innodb_buffer_pool_size` demasiado alto para KVM1 | `dmesg \| grep -i 'killed process'` | Reducir a `--innodb_buffer_pool_size=512M` o escalar a KVM2 |
| `n8n: EXECUTIONS_MAX_CONCURRENT exceeded` | VPS1/3 | Demasiados workflows simultáneos | `docker stats mantis-n8n` (RAM alta) | Reducir `EXECUTIONS_MAX_CONCURRENT` a 3 |
| `Traefik: 502 Bad Gateway` | VPS1/2/3 | Servicio backend caído | `docker logs mantis-traefik --tail 20` | Reiniciar el servicio backend (`n8n` o `espocrm`) |
| `SSH: Host key verification failed` | Cualquiera | Servidor reinstalado, clave cambió | `ssh-keygen -R IP_VPS2` | Eliminar la clave vieja y reconectar |
| `autossh no arranca al inicio` | VPS1/3 | Servicio systemd no habilitado | `systemctl is-enabled mantis-tunnel-mysql` | `systemctl enable mantis-tunnel-mysql` |

---

## 🔗 Referencias Cruzadas

- [[05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml]] — Compose VPS1
- [[05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.yml]] — Compose VPS2
- [[05-CONFIGURATIONS/docker-compose/vps3-n8n-uazapi.yml]] — Compose VPS3
- [[05-CONFIGURATIONS/00-INDEX.md]] — Índice maestro de configuraciones
- [[05-CONFIGURATIONS/terraform/modules/vps-base/main.tf]] — IaC complementario
- [[05-CONFIGURATIONS/validation/validate-skill-integrity.sh]] — Validador SDD
- [[02-SKILLS/INFRASTRUCTURA/vps-interconnection.md]] — Detalle de interconexión VPS
- [[02-SKILLS/INFRASTRUCTURA/ssh-tunnels-remote-services.md]] — SSH tunnels detallado
- [[02-SKILLS/INFRASTRUCTURA/ssh-key-management.md]] — Gestión de claves SSH
- [[02-SKILLS/INFRASTRUCTURA/ufw-firewall-configuration.md]] — Configuración de firewall
- [[02-SKILLS/INFRAESTRUCTURA/espocrm-setup.md]] — Setup de EspoCRM
- [[02-SKILLS/BASE DE DATOS-RAG/mysql-optimization-4gb-ram.md]] — Tuning MySQL C1
- [[02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md]] — Ingesta RAG Qdrant
- [[02-SKILLS/BASE DE DATOS-RAG/redis-session-management.md]] — Sesiones Redis
- [[02-SKILLS/SEGURIDAD/security-hardening-vps.md]] — Hardening base de cada VPS
- [[02-SKILLS/SEGURIDAD/backup-encryption.md]] — Backup cifrado C5
- [[01-RULES/03-SECURITY-RULES.md]] — Reglas de seguridad C3
- [[01-RULES/07-SCALABILITY-RULES.md]] — Cuándo escalar de KVM1 a KVM2

<!-- ai:file-end marker — do not remove -->
Versión 1.0.0 — 2026-04-13 — Mantis-AgenticDev
Red: VPS1(172.20.x) ↔ SSH-Tunnel ↔ VPS2(172.21.x) ↔ SSH-Tunnel ↔ VPS3(172.22.x)
Constraints: C1(RAM) C2(CPU) C3(zero-expose-DB) C4(tenant_id) C5(backup) C7(resilience) C8(logs)
