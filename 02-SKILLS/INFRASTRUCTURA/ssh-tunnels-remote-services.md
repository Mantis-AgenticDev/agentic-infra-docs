---
title: "SSH Tunnels for Remote Services - Agentic Infra Docs"
category: "Infrastructure"
subcategory: "Networking"
priority: "critical"
version: "1.0.0"
last_updated: "2026-04-09"
language: "es"
repository: "agentic-infra-docs"
owner: "Mantis-AgenticDev"
type: "skill"
ia_parser_version: "2.0"
auto_validate: true
compliance_check: "weekly"
validation_script: "scripts/validate-against-specs.sh"
auto_fixable: false
severity_scope: "critical"
tags:
- ssh
- tunneling
- remote-services
- vps
- networking
- security
- mysql
- qdrant
related_files:
- "01-RULES/03-SECURITY-RULES.md"
- "01-RULES/01-ARCHITECTURE-RULES.md"
- "01-RULES/02-RESOURCE-GUARDRAILS.md"
- "02-SKILLS/INFRASTRUCTURA/ssh-key-management.md"
- "02-SKILLS/INFRASTRUCTURA/ufw-firewall-configuration.md"
spec_references:
- "C3"
- "ARQ-005"
- "SEG-001"
constraints_applied:
- "C1"
- "C2"
- "C3"
---

# SSH Tunnels for Remote Services

## Descripción Técnica Detallada

### Propósito y Contexto

Los túneles SSH constituyen el mecanismo primario de conectividad segura entre los VPS del proyecto MANTIS AGENTIC desplegados en Hostinger Brasil. Dado que la restricción C3 establece que MySQL y Qdrant nunca deben estar expuestos en direcciones 0.0.0.0 o 0.0.0.0/0, los túneles SSH funcionan como el único conducto permitido para el tráfico de bases de datos entre servidores. Esta arquitectura no solo cumple con los requisitos de seguridad, sino que también proporciona cifrado de extremo a extremo para toda comunicación de datos, incluyendo credenciales de bases de datos, consultas SQL y vectores de embeddings.

En el contexto del proyecto MANTIS AGENTIC, los túneles SSH resuelven un desafío arquitectónico fundamental: la necesidad de comunicar servicios distribuidos en múltiples VPS sin exponer servicios sensibles a internet. VPS-1 ejecuta n8n, uazapi y Redis; VPS-2 contiene EspoCRM, MySQL y Qdrant; mientras que VPS-3 funciona como n8n secundario con capacidades de failover. La comunicación entre estos nodos ocurre exclusivamente a través de túneles SSH cifrados, garantizando que ningún servicio de base de datos sea accesible directamente desde internet.

La metodología SDD (Specification-Driven Development) aplicada en este proyecto requiere que cada túnel SSH esté completamente documentado, versionado y validable. Los túneles no son simplemente configuraciones ad-hoc, sino componentes de infraestructura críticos cuya configuración, comportamiento esperado y procedimientos de recuperación deben estar especificados formalmente.

### Principios Fundamentales de SSH Tunneling

El tunneling SSH funciona encapsulando tráfico de red dentro de una conexión SSH cifrada. Cuando se establece un túnel SSH Local Forwarding, el cliente SSH escucha en un puerto local especificado y reenvía todo el tráfico recibido hacia el servidor SSH, que posteriormente lo deriva hacia el destino final. Este proceso crea un canal cifrado que atraviesa redes no confiables sin exposición de los servicios subyacentes.

En el contexto de MANTIS AGENTIC, esta tecnología se aplica principalmente para tres casos de uso: acceso a MySQL desde aplicaciones en otros VPS, conexión a Qdrant para Retrieval-Augmented Generation (RAG), y comunicación Redis para cache distribuido. Cada caso de uso presenta requisitos específicos de puertos, persistencia y recuperación automática que deben configurarse de manera diferencial.

### Beneficios de la Arquitectura de Túneles SSH

La implementación de túneles SSH como mecanismo primario de conectividad ofrece beneficios sustanciales. El primero es el cumplimiento automático de la restricción C3, ya que los servicios de base de datos permanecen bound exclusivamente a localhost o interfaces privadas. El segundo beneficio radica en la transparencia para las aplicaciones, que pueden conectarse a servicios remotos utilizando direcciones localhost estándar. El tercer beneficio es la auditoría centralizada, dado que todo el tráfico de base de datos pasa a través de conexiones SSH cuyos logs pueden centralizarse y analizarse. Finalmente, la arquitectura proporciona flexibilidad operativa, permitiendo reconfigurar la topología de red sin modificar configuraciones de aplicaciones.

---

## Arquitectura de Red

### Topología de Conexiones entre VPS

La arquitectura de red del proyecto MANTIS AGENTIC establece una topología hub-and-spoke donde VPS-2 (conteniendo MySQL y Qdrant) funciona como el hub central de datos. VPS-1 y VPS-3 son spokes que consumen servicios de datos a través de túneles SSH establecidos hacia VPS-2.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        MANTIS AGENTIC - SSH Tunnel Architecture            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│    ┌─────────────────┐         SSH Tunnel (3306)         ┌─────────────────┐ │
│    │                 │  ←───────────────────────────→   │                 │ │
│    │     VPS-1        │      MySQL Forwarding           │     VPS-2        │ │
│    │  (São Paulo)     │                                 │  (São Paulo)     │ │
│    │                 │  ←───────────────────────────→   │                 │ │
│    │  • n8n           │      Qdrant Forwarding           │  • EspoCRM       │ │
│    │  • uazapi        │      (6333)                     │  • MySQL         │ │
│    │  • Redis         │                                 │  • Qdrant        │ │
│    │                 │                                 │                 │ │
│    └─────────────────┘                                 └─────────────────┘ │
│           ↑                                                       ↑       │
│           │                                                       │       │
│           │              SSH Tunnel (6379, 6333)                  │       │
│           └───────────────────────  ───────────────────────────────┘       │
│                                    (failover path)                         │
│                                                                             │
│    ┌─────────────────┐                                                     │
│    │                 │  ←─────────────────────────────────────────────────┘ │
│    │     VPS-3        │        Qdrant Forwarding (6333)                     │
│    │  (São Paulo)     │                                                     │
│    │                 │                                                     │
│    │  • n8n (failover)│                                                     │
│    │  • uazapi        │                                                     │
│    │                 │                                                     │
│    └─────────────────┘                                                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Modelo de Direccionamiento

Cada VPS en Hostinger Brasil posee una dirección IPv4 pública asignada dinámicamente. Las conexiones SSH entre servidores utilizan estas direcciones públicas como punto de conexión, mientras que los servicios internos de base de datos permanecen bound a 127.0.0.1 exclusivamente.

| VPS  | Hostname     | IPv4 Pública     | Servicios Expuestos | Servicios Tunneled        |
|------|--------------|-------------------|---------------------|---------------------------|
| VPS-1 | kvm1-spa-01  | 192.168.1.10      | n8n (5678), uazapi  | MySQL (3306), Qdrant (6333) |
| VPS-2 | kvm1-spa-02  | 192.168.1.11      | EspoCRM (443)       | MySQL (3306 bind local), Qdrant (6333 bind local) |
| VPS-3 | kvm1-spa-03  | 192.168.1.12      | n8n (5678), uazapi  | MySQL (3306), Qdrant (6333) |

### Modelo de Seguridad de Red

La restricción C3 implementa un modelo de seguridad donde MySQL y Qdrant escuchan exclusivamente en 127.0.0.1 o ::1, nunca en direcciones que permitan acceso desde redes externas. Los túneles SSH crean una ruta lógica que parece local para las aplicaciones, pero que en realidad atraviesa conexiones cifradas hacia servidores remotos.

Este modelo presenta múltiples capas de defensa. La primera capa es la ocultación de servicios, donde las bases de datos no poseen direcciones IP accesibles públicamente. La segunda capa es el cifrado en tránsito, donde todo el tráfico está protegido por AES-256-GCM mediante SSH. La tercera capa es la autenticación mutua, donde tanto el cliente como el servidor se autentican mediante claves SSH. La cuarta capa es el control de acceso basado en usuario del sistema, donde los túneles se ejecutan con privilegios específicos de usuario.

---

## Pre-requisitos

### Configuración de Claves SSH

Antes de establecer túneles SSH, es fundamental haber completado la configuración de autenticación por clave SSH documentada en el skill relacionado `ssh-key-management.md`. Cada VPS debe tener configurado el acceso por clave SSH hacia los demás VPS de la infraestructura. La clave pública del usuario que ejecutará los túneles debe estar autorizada en todos los servidores remotos.

Los túneles SSH requieren autenticación por clave SSH por dos razones fundamentales. Primero, los túneles deben poder reiniciarse automáticamente sin intervención manual, lo cual es imposible con contraseñas que requieren entrada interactiva. Segundo, las claves SSH proporcionan seguridad superior mediante criptografía asimétrica y la posibilidad de configurar restricciones específicas como direcciones IP de origen permitidas.

### Paquetes Requeridos en Cada VPS

Los siguientes paquetes deben estar instalados en los VPS que ejecutarán túneles SSH:

**Para túneles básicos con SSH nativo:**
- `openssh-client` (incluido en la mayoría de instalaciones base)
- `ssh` (alias o parte del paquete openssh-client)

**Para túneles persistentes con autossh:**
- `autossh` (paquete específico requerido)
- `openssh-client`
- `systemd` (para gestión de servicios)

**Para monitoreo avanzado:**
- `net-tools` (para verificación de puertos con netstat)
- `curl` (para verificación de servicios HTTP/HTTPS)

### Configuración de Sistema Operativo

El kernel de Linux debe tener habilitado el reenvío de IP si se requieren configuraciones avanzadas de enrutamiento. Sin embargo, para los casos de uso típicos de túneles SSH locales, esta configuración no es necesaria ya que el reenvío ocurre a nivel de usuario mediante la biblioteca de sockets de SSH.

Los límites del sistema también deben verificarse. El número máximo de archivos abiertos y el número máximo de procesos deben ser suficientes para las conexiones SSH simultáneas. Estos valores se configuran en `/etc/security/limits.conf` y típicamente no requieren modificación para cargas de trabajo normales.

### Configuración de UFW/Firewall

Los firewalls en cada VPS deben permitir conexiones SSH entrantes desde las direcciones IP de los otros VPS en la infraestructura. La configuración detallada se encuentra en el skill `ufw-firewall-configuration.md`, pero en términos generales, cada VPS debe aceptar conexiones SSH desde los otros dos VPS.

```bash
# En VPS-1 y VPS-3 (clientes de túnel)
ufw allow from 192.168.1.11 proto tcp port 22 comment "SSH from VPS-2"

# En VPS-2 (servidor de túneles)
ufw allow from 192.168.1.10 proto tcp port 22 comment "SSH from VPS-1"
ufw allow from 192.168.1.12 proto tcp port 22 comment "SSH from VPS-3"
```

### Credenciales y Permisos de Usuario

Los túneles SSH para servicios de base de datos deben ejecutarse con un usuario que tenga los permisos necesarios para establecer conexiones SSH y cuya clave SSH esté autorizada en los servidores remotos. Se recomienda crear un usuario dedicado para la gestión de túneles que no sea root, aplicando el principio de mínimo privilegio.

```bash
# Crear usuario dedicado para túneles
useradd -m -s /bin/bash tunnelmgr
usermod -aG sudo tunnelmgr

# Configurar clave SSH para el usuario
mkdir -p /home/tunnelmgr/.ssh
chmod 700 /home/tunnelmgr/.ssh
cp /root/.ssh/authorized_keys /home/tunnelmgr/.ssh/
chown -R tunnelmgr:tunnelmgr /home/tunnelmgr/.ssh
```

---

## Configuración Paso a Paso

### Paso 1: Verificación de Conectividad SSH Base

Antes de configurar túneles, verifique que la conectividad SSH básica funcione correctamente entre los VPS. Esta verificación debe incluir tanto el acceso con autenticación de clave como la capacidad de ejecutar comandos remotos sin interacción.

```bash
# Desde VPS-1, verificar conexión a VPS-2
ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new tunnelmgr@192.168.1.11 "hostname && uptime"

# Desde VPS-1, verificar conexión a VPS-3
ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new tunnelmgr@192.168.1.12 "hostname && uptime"
```

Si estas conexiones fallan, no proceda con la configuración de túneles hasta resolver los problemas de conectividad SSH básica. Los problemas comunes incluyen claves SSH no configuradas correctamente, reglas de firewall bloqueando conexiones, o el servicio SSH no ejecutándose en el servidor remoto.

### Paso 2: Configuración de SSH ControlMaster

Para optimizar el rendimiento cuando se establecen múltiples túneles desde el mismo host, configure SSH para utilizar multiplexación de conexiones. Esta característica permite reutilizar una conexión SSH existente para múltiples sesiones, reduciendo la sobrecarga de establecimiento de nuevas conexiones cifradas.

```bash
# Configuración en ~/.ssh/config para multiplexación
cat >> ~/.ssh/config << 'EOF'

# Host para multiplexación de túneles MySQL/Qdrant
Host vps2-tunnel
    HostName 192.168.1.11
    User tunnelmgr
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking accept-new
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 600
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host vps3-tunnel
    HostName 192.168.1.12
    User tunnelmgr
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking accept-new
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 600
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF

# Crear directorio para sockets de multiplexación
mkdir -p ~/.ssh/sockets
chmod 700 ~/.ssh/sockets
```

### Paso 3: Establecimiento Manual de Túneles

Una vez verificada la conectividad base, puede establecer túneles SSH manualmente para pruebas. Los túneles manuales son útiles para diagnóstico pero no deben utilizarse para producción donde se requiere persistencia y reinicio automático.

```bash
# Tunnel MySQL desde VPS-1 hacia VPS-2
# Este comando crea un túnel que reenvía el puerto local 3306 hacia el puerto 3306 de localhost en VPS-2
ssh -L 3306:127.0.0.1:3306 -N -f tunnelmgr@192.168.1.11

# Tunnel Qdrant desde VPS-1 hacia VPS-2
# Qdrant escucha en 6333 para cliente y 6334 para gRPC
ssh -L 6333:127.0.0.1:6333 -L 6334:127.0.0.1:6334 -N -f tunnelmgr@192.168.1.11

# Verificar que los túneles están activos
netstat -tlnp | grep -E '3306|6333|6334'
```

La sintaxis `-L puerto-local:host-remoto:puerto-remoto` especifica que las conexiones al puerto local se reenviarán a través de la conexión SSH hacia el host remoto especificado, donde host-remoto se resuelve respecto al servidor SSH (en este caso, 127.0.0.1 desde el contexto del servidor remoto).

### Paso 4: Configuración de Servicios Systemd para Túneles Persistentes

Para túneles en producción, los túneles SSH deben gestionarse como servicios systemd para garantizar reinicio automático tras reinicios del sistema, recuperación ante fallos de red, y registro de errores estructurado. Esta configuración es fundamental para cumplir con los requisitos de disponibilidad del proyecto.

---

## Ejemplo 1: Tunnel MySQL desde VPS-1 a VPS-2

### Descripción del Escenario

En este escenario, VPS-1 ejecuta aplicaciones (n8n, uazapi) que requieren acceso a MySQL ubicado en VPS-2. La base de datos MySQL está configurada para escuchar exclusivamente en 127.0.0.1:3306, por lo que el único modo de acceso desde VPS-1 es mediante un túnel SSH que expone localmente el puerto de MySQL.

### Arquitectura de la Solución

```
VPS-1:n8n/uazapi → localhost:3306 → [SSH Tunnel] → VPS-2:127.0.0.1:3306 → MySQL
```

### Script de Configuración Completo

```bash
#!/bin/bash
#===============================================================================
# SCRIPT: setup-mysql-tunnel-vps1-to-vps2.sh
# PROPOSITO: Establecer túnel SSH persistente para MySQL desde VPS-1 hacia VPS-2
# VPS ORIGEN: VPS-1 (192.168.1.10)
# VPS DESTINO: VPS-2 (192.168.1.11)
# PUERTO LOCAL: 3306
# USUARIO: tunnelmgr
#===============================================================================

set -euo pipefail

# Variables de configuración
REMOTE_HOST="192.168.1.11"
REMOTE_USER="tunnelmgr"
LOCAL_PORT="3306"
REMOTE_HOST_DB="127.0.0.1"
REMOTE_PORT_DB="3306"
SSH_KEY="/home/tunnelmgr/.ssh/id_ed25519"
SERVICE_NAME="ssh-tunnel-mysql"
SOCKET_DIR="/home/tunnelmgr/.ssh/sockets"

# Crear directorio para sockets de multiplexación si no existe
mkdir -p "${SOCKET_DIR}"
chmod 700 "${SOCKET_DIR}"

# Detener servicio existente si está en ejecución
if systemctl is-active --quiet "${SERVICE_NAME}"; then
    echo "[INFO] Deteniendo servicio existente ${SERVICE_NAME}..."
    systemctl stop "${SERVICE_NAME}"
fi

# Verificar conectividad SSH antes de iniciar
echo "[INFO] Verificando conectividad SSH hacia ${REMOTE_HOST}..."
if ! ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new \
    -i "${SSH_KEY}" "${REMOTE_USER}@${REMOTE_HOST}" "echo 'SSH OK'" > /dev/null 2>&1; then
    echo "[ERROR] No se puede establecer conexión SSH hacia ${REMOTE_HOST}"
    echo "[ERROR] Verifique que:"
    echo "[ERROR]   1. La clave SSH esté autorizada en ${REMOTE_HOST}"
    echo "[ERROR]   2. El servicio SSH esté ejecutándose en ${REMOTE_HOST}"
    echo "[ERROR]   3. El firewall permita conexiones en puerto 22"
    exit 1
fi

echo "[SUCCESS] Conectividad SSH verificada correctamente"

# Crear archivo de unidad systemd
cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=SSH Tunnel for MySQL - VPS-1 to VPS-2
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=300
StartLimitBurst=5

[Service]
Type=simple
User=tunnelmgr
Group=tunnelmgr
WorkingDirectory=/home/tunnelmgr
Environment="AUTOSSH_GATETIME=0"
Environment="AUTOSSH_PORT=32768"
ExecStart=/usr/bin/autossh \
    -M 32768 \
    -o "ServerAliveInterval=60" \
    -o "ServerAliveCountMax=3" \
    -o "StrictHostKeyChecking=accept-new" \
    -o "ControlMaster=auto" \
    -o "ControlPath=${SOCKET_DIR}/%r@%h-%p" \
    -o "ControlPersist=600" \
    -o "ExitOnForwardFailure=yes" \
    -i "${SSH_KEY}" \
    -N \
    -L ${LOCAL_PORT}:${REMOTE_HOST_DB}:${REMOTE_PORT_DB} \
    ${REMOTE_USER}@${REMOTE_HOST}
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=${SERVICE_NAME}

# Limites de recursos para cumplir C1 (4GB RAM)
MemoryMax=512M
MemoryHigh=256M

[Install]
WantedBy=multi-user.target
EOF

# Recargar daemon de systemd
systemctl daemon-reload

# Habilitar e iniciar servicio
systemctl enable "${SERVICE_NAME}"
systemctl start "${SERVICE_NAME}"

# Verificar estado
sleep 3
if systemctl is-active --quiet "${SERVICE_NAME}"; then
    echo "[SUCCESS] Servicio ${SERVICE_NAME} iniciado correctamente"
    echo "[INFO] MySQL accesible en localhost:${LOCAL_PORT}"
else
    echo "[ERROR] El servicio ${SERVICE_NAME} no pudo iniciarse"
    echo "[INFO] Logs del servicio:"
    journalctl -u "${SERVICE_NAME}" --no-pager -n 20
    exit 1
fi

# Verificar que el puerto está escuchando
if netstat -tlnp 2>/dev/null | grep -q ":${LOCAL_PORT}"; then
    echo "[SUCCESS] Puerto ${LOCAL_PORT} está escuchando correctamente"
else
    echo "[WARNING] El puerto ${LOCAL_PORT} no está escuchando"
    echo "[INFO] Esto puede indicar que el túnel se estableció pero el servicio MySQL no está disponible en VPS-2"
fi

echo ""
echo "============================================================================"
echo "TUNNEL MYSQL CONFIGURADO EXITOSAMENTE"
echo "============================================================================"
echo "Desde VPS-1, MySQL está accesible en: localhost:${LOCAL_PORT}"
echo "El servicio se reiniciará automáticamente tras:"
echo "  - Fallos de conexión SSH"
echo "  - Reinicios del sistema"
echo "  - Interrupciones de red"
echo ""
echo "Comandos de gestión:"
echo "  systemctl status ${SERVICE_NAME}   # Ver estado"
echo "  systemctl restart ${SERVICE_NAME}   # Reiniciar"
echo "  journalctl -u ${SERVICE_NAME} -f     # Ver logs en tiempo real"
echo "============================================================================"
```

### Verificación Post-Instalación

```bash
# Verificar estado del servicio
systemctl status ssh-tunnel-mysql

# Verificar que el puerto local está escuchando
netstat -tlnp | grep 3306

# Probar conexión MySQL a través del túnel
mysql -h 127.0.0.1 -P 3306 -u mantis_user -p \
    -e "SELECT VERSION() AS mysql_version;"

# Ver logs del túnel
journalctl -u ssh-tunnel-mysql -n 50 --no-pager
```

---

## Ejemplo 2: Tunnel Qdrant desde VPS-3 a VPS-2

### Descripción del Escenario

En este escenario, VPS-3 ejecuta instancias de failover de n8n y uazapi que requieren acceso a Qdrant para operaciones de Retrieval-Augmented Generation (RAG). Qdrant está configurado en VPS-2 escuchando exclusivamente en 127.0.0.1:6333 (REST API) y 127.0.0.1:6334 (gRPC). El túnel expone ambos puertos localmente en VPS-3.

### Consideraciones Especiales para Qdrant

Qdrant presenta requisitos específicos para túneles SSH debido a su arquitectura de dos interfaces: REST API sobre HTTP y comunicación gRPC. Ambas interfaces deben estar accesibles a través del túnel para que el cliente Qdrant funcione correctamente. Adicionalmente, Qdrant utiliza WebSocket para algunas operaciones, lo cual requiere que el túnel SSH mantenga conexiones de larga duración.

### Script de Configuración Completo

```bash
#!/bin/bash
#===============================================================================
# SCRIPT: setup-qdrant-tunnel-vps3-to-vps2.sh
# PROPOSITO: Establecer túnel SSH persistente para Qdrant desde VPS-3 hacia VPS-2
# VPS ORIGEN: VPS-3 (192.168.1.12)
# VPS DESTINO: VPS-2 (192.168.1.11)
# PUERTOS LOCALES: 6333 (REST), 6334 (gRPC)
# USUARIO: tunnelmgr
#===============================================================================

set -euo pipefail

# Variables de configuración
REMOTE_HOST="192.168.1.11"
REMOTE_USER="tunnelmgr"
LOCAL_PORT_REST="6333"
LOCAL_PORT_GRPC="6334"
REMOTE_HOST_QDRANT="127.0.0.1"
REMOTE_PORT_REST="6333"
REMOTE_PORT_GRPC="6334"
SSH_KEY="/home/tunnelmgr/.ssh/id_ed25519"
SERVICE_NAME="ssh-tunnel-qdrant"
SOCKET_DIR="/home/tunnelmgr/.ssh/sockets"

# Crear directorio para sockets de multiplexación
mkdir -p "${SOCKET_DIR}"
chmod 700 "${SOCKET_DIR}"

# Detener servicio existente si está en ejecución
if systemctl is-active --quiet "${SERVICE_NAME}"; then
    echo "[INFO] Deteniendo servicio existente ${SERVICE_NAME}..."
    systemctl stop "${SERVICE_NAME}"
fi

# Verificar conectividad SSH
echo "[INFO] Verificando conectividad SSH hacia ${REMOTE_HOST}..."
if ! ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new \
    -i "${SSH_KEY}" "${REMOTE_USER}@${REMOTE_HOST}" "echo 'SSH OK'" > /dev/null 2>&1; then
    echo "[ERROR] No se puede establecer conexión SSH hacia ${REMOTE_HOST}"
    exit 1
fi

echo "[SUCCESS] Conectividad SSH verificada"

# Crear archivo de unidad systemd con configuración específica para Qdrant
cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=SSH Tunnel for Qdrant - VPS-3 to VPS-2
After=network-online.target
Wants=network-online.target
# Qdrant es crítico para RAG, se reinicia más agresivamente
StartLimitIntervalSec=180
StartLimitBurst=10

[Service]
Type=simple
User=tunnelmgr
Group=tunnelmgr
WorkingDirectory=/home/tunnelmgr
Environment="AUTOSSH_GATETIME=0"
Environment="AUTOSSH_PORT=32769"
ExecStart=/usr/bin/autossh \
    -M 32769 \
    -o "ServerAliveInterval=30" \
    -o "ServerAliveCountMax=5" \
    -o "StrictHostKeyChecking=accept-new" \
    -o "ControlMaster=auto" \
    -o "ControlPath=${SOCKET_DIR}/%r@%h-%p" \
    -o "ControlPersist=600" \
    -o "ExitOnForwardFailure=yes" \
    -o "GatewayPorts=no" \
    -i "${SSH_KEY}" \
    -N \
    -L ${LOCAL_PORT_REST}:${REMOTE_HOST_QDRANT}:${REMOTE_PORT_REST} \
    -L ${LOCAL_PORT_GRPC}:${REMOTE_HOST_QDRANT}:${REMOTE_PORT_GRPC} \
    ${REMOTE_USER}@${REMOTE_HOST}
# Reinicio rápido para Qdrant (conexiones largas)
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=${SERVICE_NAME}

# Limites de recursos para cumplir C1 (4GB RAM)
MemoryMax=384M
MemoryHigh=192M

[Install]
WantedBy=multi-user.target
EOF

# Recargar daemon y gestionar servicio
systemctl daemon-reload
systemctl enable "${SERVICE_NAME}"
systemctl start "${SERVICE_NAME}"

# Verificación
sleep 5
if systemctl is-active --quiet "${SERVICE_NAME}"; then
    echo "[SUCCESS] Servicio ${SERVICE_NAME} iniciado correctamente"
else
    echo "[ERROR] El servicio ${SERVICE_NAME} no pudo iniciarse"
    journalctl -u "${SERVICE_NAME}" --no-pager -n 20
    exit 1
fi

# Verificar ambos puertos
echo "[INFO] Verificando puertos del túnel..."
for port in ${LOCAL_PORT_REST} ${LOCAL_PORT_GRPC}; do
    if netstat -tlnp 2>/dev/null | grep -q ":${port}"; then
        echo "[SUCCESS] Puerto ${port} escuchando"
    else
        echo "[WARNING] Puerto ${port} no está escuchando"
    fi
done

echo ""
echo "============================================================================"
echo "TUNNEL QDRANT CONFIGURADO EXITOSAMENTE"
echo "============================================================================"
echo "Desde VPS-3, Qdrant está accesible en:"
echo "  REST API:  http://localhost:${LOCAL_PORT_REST}"
echo "  gRPC:      localhost:${LOCAL_PORT_GRPC}"
echo ""
echo "Comandos de gestión:"
echo "  curl http://localhost:${LOCAL_PORT_REST}/collections  # Verificar API REST"
echo "  systemctl status ${SERVICE_NAME}"
echo "============================================================================"
```

### Verificación de Qdrant a través del Túnel

```bash
# Verificar API REST de Qdrant
curl -s http://localhost:6333/collections | jq '.'

# Verificar salud de Qdrant
curl -s http://localhost:6333/health | jq '.'

# Probar colección de vectores si existe
curl -s http://localhost:6333/collections/mantis_vectors | jq '.result'
```

---

## Ejemplo 3: Script autossh con systemd y restart automático

### Descripción del Escenario

Este ejemplo presenta una configuración completa y reutilizable para túneles SSH persistentes utilizando autossh, systemd, y capacidades avanzadas de monitoreo y recuperación automática. Esta configuración cumple con los requisitos de alta disponibilidad del proyecto MANTIS AGENTIC.

### Script Maestro de Configuración

```bash
#!/bin/bash
#===============================================================================
# SCRIPT: setup-ssh-tunnel-master.sh
# PROPOSITO: Framework master para configuración de túneles SSH persistentes
# PROYECTO: MANTIS AGENTIC
# VERSIÓN: 1.0.0
#===============================================================================

set -euo pipefail

#-------------------------------------------------------------------------------
# CONFIGURACIÓN GLOBAL
#-------------------------------------------------------------------------------
readonly SCRIPT_VERSION="1.0.0"
readonly PROJECT_NAME="mantis-agentic"
readonly TUNNEL_USER="tunnelmgr"
readonly SSH_KEY="/home/tunnelmgr/.ssh/id_ed25519"
readonly SOCKET_DIR="/home/tunnelmgr/.ssh/sockets"
readonly LOG_DIR="/var/log/${PROJECT_NAME}/tunnels"
readonly AUTOSSH_PORT_BASE="32768"

# Colores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

#-------------------------------------------------------------------------------
# FUNCIONES DE UTILIDAD
#-------------------------------------------------------------------------------

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

usage() {
    cat << EOF
Uso: $0 [COMANDO] [OPCIONES]

Comandos:
    create-tunnel    Crea un nuevo túnel SSH
    list-tunnels     Lista todos los túneles configurados
    start-tunnel     Inicia un túnel específico
    stop-tunnel      Detiene un túnel específico
    restart-tunnel   Reinicia un túnel específico
    monitor-tunnel   Monitorea un túnel en tiempo real
    health-check     Ejecuta verificación de salud de todos los túneles

Opciones para create-tunnel:
    -n, --name        Nombre del túnel (ej: mysql, qdrant, redis)
    -r, --remote      Host remoto (IP o hostname)
    -u, --user        Usuario SSH remoto
    -lp, --local-port Puerto local para reenvío
    -rh, --remote-host Host donde se conecta en remoto (default: 127.0.0.1)
    -rp, --remote-port Puerto remoto
    -m, --monitor-port Puerto de monitoreo autossh (auto-generado si no especificado)
    -h, --help        Muestra esta ayuda

Ejemplos:
    $0 create-tunnel -n mysql -r 192.168.1.11 -lp 3306 -rp 3306
    $0 create-tunnel -n qdrant -r 192.168.1.11 -lp 6333 -rp 6333 -rp2 6334
    $0 list-tunnels
    $0 health-check

EOF
    exit 0
}

#-------------------------------------------------------------------------------
# VERIFICACIONES PREVIAS
#-------------------------------------------------------------------------------

verify_dependencies() {
    log_info "Verificando dependencias..."

    local deps=("autossh" "systemctl" "netstat" "ssh")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log_error "Dependencia faltante: $dep"
            log_info "Instale con: apt install $dep"
            exit 1
        fi
    done

    log_success "Todas las dependencias disponibles"
}

verify_permissions() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "Ejecutando como root. Se recomienda usar el usuario ${TUNNEL_USER}"
    fi

    if [[ ! -d "${SOCKET_DIR}" ]]; then
        mkdir -p "${SOCKET_DIR}"
        chmod 700 "${SOCKET_DIR}"
    fi

    if [[ ! -d "${LOG_DIR}" ]]; then
        sudo mkdir -p "${LOG_DIR}"
        sudo chmod 755 "${LOG_DIR}"
    fi
}

#-------------------------------------------------------------------------------
# FUNCIÓN PRINCIPAL DE CREACIÓN DE TÚNEL
#-------------------------------------------------------------------------------

create_tunnel() {
    local name=""
    local remote_host=""
    local remote_user="${TUNNEL_USER}"
    local local_port=""
    local remote_host_conn="127.0.0.1"
    local remote_port=""
    local monitor_port=""
    local extra_forward=""

    # Parseo de argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--name)
                name="$2"
                shift 2
                ;;
            -r|--remote)
                remote_host="$2"
                shift 2
                ;;
            -u|--user)
                remote_user="$2"
                shift 2
                ;;
            -lp|--local-port)
                local_port="$2"
                shift 2
                ;;
            -rh|--remote-host)
                remote_host_conn="$2"
                shift 2
                ;;
            -rp|--remote-port)
                remote_port="$2"
                shift 2
                ;;
            -m|--monitor-port)
                monitor_port="$2"
                shift 2
                ;;
            -e|--extra-forward)
                extra_forward="$2"
                shift 2
                ;;
            *)
                log_error "Opción desconocida: $1"
                usage
                ;;
        esac
    done

    # Validaciones
    if [[ -z "$name" ]] || [[ -z "$remote_host" ]] || [[ -z "$local_port" ]] || [[ -z "$remote_port" ]]; then
        log_error "Faltan parámetros requeridos"
        usage
    fi

    # Generar puerto de monitoreo si no se especifica
    if [[ -z "$monitor_port" ]]; then
        monitor_port=$((AUTOSSH_PORT_BASE + $(echo "$local_port" | cut -d'' -f1 | tr -d ' ')))
    fi

    local service_name="ssh-tunnel-${name}"

    log_info "Creando túnel: ${service_name}"
    log_info "  Host remoto: ${remote_host}"
    log_info "  Puerto local: ${local_port}"
    log_info "  Puerto remoto: ${remote_port}"
    log_info "  Host remoto de destino: ${remote_host_conn}"
    log_info "  Puerto monitoreo: ${monitor_port}"

    # Verificar conectividad SSH
    log_info "Verificando conectividad SSH..."
    if ! ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new \
        -i "${SSH_KEY}" "${remote_user}@${remote_host}" "echo 'SSH OK'" &> /dev/null; then
        log_error "No se puede establecer conexión SSH"
        log_error "Verifique: clave SSH autorizada, servicio SSH activo, firewall"
        exit 1
    fi
    log_success "Conectividad SSH verificada"

    # Construir comando de forward
    local forward_cmd="-L ${local_port}:${remote_host_conn}:${remote_port}"
    if [[ -n "$extra_forward" ]]; then
        forward_cmd="${forward_cmd} -L ${extra_forward}"
    fi

    # Crear archivo de unidad systemd
    log_info "Creando servicio systemd..."
    cat > /etc/systemd/system/${service_name}.service << EOF
[Unit]
Description=SSH Tunnel ${name} - ${remote_host}
Documentation=man:ssh(1) man:autossh(1)
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=300
StartLimitBurst=10

[Service]
Type=simple
User=${TUNNEL_USER}
Group=${TUNNEL_USER}
WorkingDirectory=/home/${TUNNEL_USER}
Environment="AUTOSSH_GATETIME=0"
Environment="AUTOSSH_PORT=${monitor_port}"
Environment="AUTOSSH_LOGFILE=${LOG_DIR}/${name}.log"
ExecStartPre=/bin/sleep 5
ExecStart=/usr/bin/autossh \
    -M ${monitor_port} \
    -o "ServerAliveInterval=60" \
    -o "ServerAliveCountMax=3" \
    -o "StrictHostKeyChecking=accept-new" \
    -o "ControlMaster=auto" \
    -o "ControlPath=${SOCKET_DIR}/%r@%h-%p" \
    -o "ControlPersist=600" \
    -o "ExitOnForwardFailure=yes" \
    -o "PasswordAuthentication=no" \
    -i "${SSH_KEY}" \
    -N \
    ${forward_cmd} \
    ${remote_user}@${remote_host}
Restart=on-failure
RestartSec=15
StandardOutput=journal
StandardError=journal
SyslogIdentifier=${service_name}

# Resource limits para C1 compliance
MemoryMax=512M
MemoryHigh=256M
LimitNOFILE=65536

# Hardening de seguridad
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadOnlyPaths=/
ReadWritePaths=${SOCKET_DIR} ${LOG_DIR}

[Install]
WantedBy=multi-user.target
EOF

    # Recargar systemd y activar servicio
    systemctl daemon-reload
    systemctl enable "${service_name}"
    systemctl start "${service_name}"

    # Verificación
    sleep 5
    if systemctl is-active --quiet "${service_name}"; then
        log_success "Túnel ${name} creado y activo"
    else
        log_error "El túnel no pudo iniciarse"
        log_info "Logs:"
        journalctl -u "${service_name}" --no-pager -n 15
        exit 1
    fi

    # Verificar puerto
    if netstat -tlnp 2>/dev/null | grep -q ":${local_port}"; then
        log_success "Puerto ${local_port} escuchando"
    fi
}

#-------------------------------------------------------------------------------
# FUNCIONES DE GESTIÓN DE TÚNELES
#-------------------------------------------------------------------------------

list_tunnels() {
    echo ""
    echo "============================================================================"
    echo "TÚNELES SSH CONFIGURADOS EN ${HOSTNAME}"
    echo "============================================================================"
    echo ""

    local count=0
    for service in /etc/systemd/system/ssh-tunnel-*.service; do
        if [[ -f "$service" ]]; then
            local name=$(basename "$service" .service | sed 's/ssh-tunnel-//')
            local status=$(systemctl is-active "ssh-tunnel-${name}" 2>/dev/null || echo "inactive")
            local enabled=$(systemctl is-enabled "ssh-tunnel-${name}" 2>/dev/null || echo "disabled")

            printf "%-20s %-10s %-10s\n" "$name" "$status" "$enabled"
            count=$((count + 1))
        fi
    done

    if [[ $count -eq 0 ]]; then
        echo "No hay túneles configurados"
    fi
    echo ""
}

health_check() {
    echo ""
    echo "============================================================================"
    echo "HEALTH CHECK DE TÚNELES SSH - $(date)"
    echo "============================================================================"
    echo ""

    local issues=0

    for service_file in /etc/systemd/system/ssh-tunnel-*.service; do
        if [[ -f "$service_file" ]]; then
            local name=$(basename "$service_file" .service | sed 's/ssh-tunnel-//')
            local service_name="ssh-tunnel-${name}"

            printf "%-20s " "$name"

            if systemctl is-active --quiet "$service_name"; then
                printf "%-15s " "$(printf '\033[0;32mOK\033[0m')"

                # Extraer puerto local del servicio
                local local_port=$(grep -oP '\-L \K[0-9]+' "$service_file" | head -1)
                if [[ -n "$local_port" ]]; then
                    if netstat -tlnp 2>/dev/null | grep -q ":${local_port}"; then
                        printf "%-15s\n" "$(printf '\033[0;32mPort %s OK\033[0m' "$local_port")"
                    else
                        printf "%-15s\n" "$(printf '\033[0;31mPort %s DOWN\033[0m' "$local_port")"
                        issues=$((issues + 1))
                    fi
                else
                    echo ""
                fi
            else
                printf "%-15s\n" "$(printf '\033[0;31mINACTIVE\033[0m')"
                issues=$((issues + 1))
            fi
        fi
    done

    echo ""
    if [[ $issues -gt 0 ]]; then
        echo "Se detectaron ${issues} problemas"
        return 1
    else
        echo "Todos los túneles están operativos"
        return 0
    fi
}

#-------------------------------------------------------------------------------
# PUNTO DE ENTRADA PRINCIPAL
#-------------------------------------------------------------------------------

main() {
    if [[ $# -eq 0 ]]; then
        usage
    fi

    verify_dependencies
    verify_permissions

    local command="${1:-}"
    shift || true

    case "$command" in
        create-tunnel)
            create_tunnel "$@"
            ;;
        list-tunnels)
            list_tunnels
            ;;
        start-tunnel)
            systemctl start "ssh-tunnel-${1}"
            ;;
        stop-tunnel)
            systemctl stop "ssh-tunnel-${1}"
            ;;
        restart-tunnel)
            systemctl restart "ssh-tunnel-${1}"
            ;;
        monitor-tunnel)
            journalctl -u "ssh-tunnel-${1}" -f
            ;;
        health-check)
            health_check
            ;;
        *)
            log_error "Comando desconocido: $command"
            usage
            ;;
    esac
}

main "$@"
```

### Uso del Script Maestro

```bash
# Hacer ejecutable
chmod +x setup-ssh-tunnel-master.sh

# Crear túnel MySQL
sudo ./setup-ssh-tunnel-master.sh create-tunnel \
    --name mysql \
    --remote 192.168.1.11 \
    --user tunnelmgr \
    --local-port 3306 \
    --remote-port 3306

# Crear túnel Qdrant (con puertos REST y gRPC)
sudo ./setup-ssh-tunnel-master.sh create-tunnel \
    --name qdrant \
    --remote 192.168.1.11 \
    --user tunnelmgr \
    --local-port 6333 \
    --remote-port 6333 \
    --extra-forward "6334:127.0.0.1:6334"

# Listar túneles configurados
sudo ./setup-ssh-tunnel-master.sh list-tunnels

# Verificar salud de todos los túneles
sudo ./setup-ssh-tunnel-master.sh health-check

# Monitorear túnel específico en tiempo real
sudo ./setup-ssh-tunnel-master.sh monitor-tunnel mysql
```

---

## Monitoreo y Recuperación Automática

### Configuración de Monitoreo con Systemd

El monitoreo de túneles SSH se implementa a través de múltiples capas de systemd. La primera capa es el mecanismo de Restart=on-failure que reinicia el servicio automáticamente cuando este falla. La segunda capa son los límites StartLimitIntervalSec y StartLimitBurst que controlan la frecuencia de reinicios.

```ini
[Unit]
StartLimitIntervalSec=300
StartLimitBurst=10

[Service]
Restart=on-failure
RestartSec=10
```

### Scripts de Verificación de Salud

Para complementar el monitoreo de systemd, se pueden implementar scripts de verificación que comprueben la disponibilidad real de los servicios a través de los túneles. Estos scripts pueden ejecutarse mediante cron jobs o como parte de sistemas de monitoreo externo.

```bash
#!/bin/bash
#===============================================================================
# SCRIPT: monitor-tunnels.sh
# PROPOSITO: Verificar disponibilidad de servicios a través de túneles SSH
# EJECUTAR: Cada 5 minutos via cron
#===============================================================================

set -euo pipefail

# Configuración
readonly LOG_FILE="/var/log/mantis-agentic/tunnels/health-check.log"
readonly ALERT_EMAIL="alerts@mantis-agentic.local"
readonly MYSQL_PORT="3306"
readonly QDRANT_PORT="6333"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_mysql_tunnel() {
    if timeout 5 bash -c "echo > /dev/tcp/localhost/${MYSQL_PORT}" 2>/dev/null; then
        if mysql -h 127.0.0.1 -P ${MYSQL_PORT} -u mantis_check -p dummy_password \
            -e "SELECT 1" > /dev/null 2>&1; then
            log "MYSQL_TUNNEL: OK"
            return 0
        fi
    fi
    log "MYSQL_TUNNEL: FAILED"
    return 1
}

check_qdrant_tunnel() {
    if timeout 5 bash -c "echo > /dev/tcp/localhost/${QDRANT_PORT}" 2>/dev/null; then
        if curl -sf http://localhost:${QDRANT_PORT}/health > /dev/null 2>&1; then
            log "QDRANT_TUNNEL: OK"
            return 0
        fi
    fi
    log "QDRANT_TUNNEL: FAILED"
    return 1
}

# Verificar y reiniciar si es necesario
main() {
    mkdir -p "$(dirname "$LOG_FILE")"

    local failed=0

    if ! check_mysql_tunnel; then
        log "Intentando reiniciar túnel MySQL..."
        systemctl restart ssh-tunnel-mysql || true
        failed=$((failed + 1))
    fi

    if ! check_qdrant_tunnel; then
        log "Intentando reiniciar túnel Qdrant..."
        systemctl restart ssh-tunnel-qdrant || true
        failed=$((failed + 1))
    fi

    if [[ $failed -gt 0 ]]; then
        log "ALERTA: $failed túnel(es) requieren atención"
        # Aquí se podría agregar envío de email o notificación
    fi
}

main
```

### Configuración de Cron para Monitoreo Periódico

```bash
# Agregar al crontab del usuario root o tunnelmgr
crontab -e

# Ejecutar verificación cada 5 minutos
*/5 * * * * /opt/mantis-agentic/scripts/monitor-tunnels.sh

# Ejecutar verificación de salud cada minuto (para recuperación rápida)
* * * * * /opt/mantis-agentic/scripts/fast-health-check.sh
```

---

## Validación y Testing

### Pruebas de Conectividad Básica

Después de establecer cualquier túnel SSH, se deben ejecutar pruebas de validación para garantizar que el túnel funciona correctamente y que los servicios remotos son accesibles.

```bash
#===============================================================================
# PRUEBA 1: Verificación de Puerto Local
#===============================================================================
echo "=== Prueba 1: Verificación de Puerto Local ==="
netstat -tlnp | grep -E '3306|6333|6334' || echo "FALLO: Puertos no escuchando"

#===============================================================================
# PRUEBA 2: Verificación de Conexión SSH Activa
#===============================================================================
echo "=== Prueba 2: Verificación de Proceso SSH ==="
ps aux | grep -E 'autossh|ssh.*-L' | grep -v grep || echo "FALLO: No hay proceso SSH"

#===============================================================================
# PRUEBA 3: Verificación de Conexión MySQL
#===============================================================================
echo "=== Prueba 3: Verificación de MySQL ==="
mysql -h 127.0.0.1 -P 3306 -u mantis_user -p -e \
    "SELECT 'MySQL via Tunnel OK' AS status, VERSION() AS version;"

#===============================================================================
# PRUEBA 4: Verificación de Qdrant REST API
#===============================================================================
echo "=== Prueba 4: Verificación de Qdrant REST ==="
curl -sf http://localhost:6333/health | jq '.' || echo "FALLO: Qdrant no responde"

#===============================================================================
# PRUEBA 5: Verificación de Qdrant gRPC
#===============================================================================
echo "=== Prueba 5: Verificación de Qdrant gRPC ==="
# Se puede usar grpcurl si está disponible
if command -v grpcurl &> /dev/null; then
    grpcurl -plaintext localhost:6334 list || echo "FALLO: gRPC no responde"
else
    echo "SKIP: grpcurl no instalado"
fi

#===============================================================================
# PRUEBA 6: Test de Latencia
#===============================================================================
echo "=== Prueba 6: Test de Latencia ==="
time mysql -h 127.0.0.1 -P 3306 -u mantis_user -p -e "SELECT 1;" 2>/dev/null
```

### Pruebas de Recuperación ante Fallos

```bash
#===============================================================================
# PRUEBA DE RECUPERACIÓN: Simular fallo de red y verificar reinicio
#===============================================================================

# 1. Hacer backup de la configuración actual
cp /etc/systemd/system/ssh-tunnel-mysql.service /tmp/ssh-tunnel-mysql.service.bak

# 2. Detener el servicio
systemctl stop ssh-tunnel-mysql

# 3. Verificar que está detenido
systemctl status ssh-tunnel-mysql

# 4. Forzar tiempo de espera
sleep 2

# 5. Iniciar el servicio
systemctl start ssh-tunnel-mysql

# 6. Verificar que está activo
systemctl is-active ssh-tunnel-mysql

# 7. Verificar puerto escuchando
netstat -tlnp | grep 3306

# 8. Verificarlogs para confirmar recuperación
journalctl -u ssh-tunnel-mysql -n 10 --no-pager
```

### Script de Validación Completo

```bash
#!/bin/bash
#===============================================================================
# SCRIPT: validate-ssh-tunnels.sh
# PROPOSITO: Validación completa de túneles SSH para proyecto MANTIS AGENTIC
# CUMPLIMIENTO: C1, C2, C3
#===============================================================================

set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

PASS=0
FAIL=0

assert() {
    local description="$1"
    local command="$2"
    local expected="$3"

    echo -n "  $description... "

    local result
    result=$(eval "$command" 2>/dev/null) || true

    if [[ "$result" == *"$expected"* ]] || [[ "$command" == "systemctl is-active"* && "$result" == "active" ]]; then
        echo -e "${GREEN}PASS${NC}"
        PASS=$((PASS + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        echo "    Expected: $expected"
        echo "    Got: $result"
        FAIL=$((FAIL + 1))
        return 1
    fi
}

echo ""
echo "============================================================================"
echo "VALIDACIÓN DE TÚNELES SSH - MANTIS AGENTIC"
echo "Fecha: $(date)"
echo "============================================================================"
echo ""

echo "--- Servicios Systemd ---"
assert "ssh-tunnel-mysql activo" "systemctl is-active ssh-tunnel-mysql" "active"
assert "ssh-tunnel-qdrant activo" "systemctl is-active ssh-tunnel-qdrant" "active"
assert "ssh-tunnel-mysql habilitado" "systemctl is-enabled ssh-tunnel-mysql" "enabled"
assert "ssh-tunnel-qdrant habilitado" "systemctl is-enabled ssh-tunnel-qdrant" "enabled"

echo ""
echo "--- Puertos Locales ---"
assert "Puerto 3306 escuchando" "netstat -tlnp 2>/dev/null | grep 3306 | grep LISTEN" "3306"
assert "Puerto 6333 escuchando" "netstat -tlnp 2>/dev/null | grep 6333 | grep LISTEN" "6333"
assert "Puerto 6334 escuchando" "netstat -tlnp 2>/dev/null | grep 6334 | grep LISTEN" "6334"

echo ""
echo "--- Procesos SSH ---"
assert "Proceso autossh mysql" "ps aux | grep autossh | grep -v grep | grep mysql" "autossh"
assert "Proceso autossh qdrant" "ps aux | grep autossh | grep -v grep | grep qdrant" "autossh"

echo ""
echo "--- Conectividad de Servicios ---"
if command -v mysql &> /dev/null; then
    assert "MySQL accesible via tunnel" "mysql -h 127.0.0.1 -P 3306 -u mantis_check -pcheck -e 'SELECT 1' 2>/dev/null" "1"
fi

if command -v curl &> /dev/null; then
    assert "Qdrant health check" "curl -sf http://localhost:6333/health 2>/dev/null" "ok"
fi

echo ""
echo "--- Compliance C3 Check ---"
# C3: MySQL y Qdrant nunca deben estar en 0.0.0.0
if netstat -tlnp 2>/dev/null | grep -E '3306|6333|6334' | grep -q '0.0.0.0'; then
    echo -e "  ${RED}FAIL: Servicios expuestos en 0.0.0.0 (violación C3)${NC}"
    FAIL=$((FAIL + 1))
else
    echo -e "  ${GREEN}PASS: Servicios no expuestos en 0.0.0.0${NC}"
    PASS=$((PASS + 1))
fi

echo ""
echo "============================================================================"
echo "RESULTADOS: $PASS passed, $FAIL failed"
echo "============================================================================"

if [[ $FAIL -gt 0 ]]; then
    exit 1
else
    exit 0
fi
```

---

## Troubleshooting

### Problemas Comunes y Soluciones

#### Problema 1: Túnel No Se Establece - "Connection Refused"

**Síntomas:** El servicio no inicia, logs muestran "Connection refused" o "Network is unreachable"

**Diagnóstico:**
```bash
# Verificar logs del servicio
journalctl -u ssh-tunnel-mysql -n 50

# Verificar conectividad de red
ping -c 3 192.168.1.11

# Verificar puerto SSH en remoto
nc -zv 192.168.1.11 22

# Probar conexión SSH manual
ssh -vvv -i ~/.ssh/id_ed25519 tunnelmgr@192.168.1.11
```

**Soluciones posibles:**
- Verificar que el servicio SSH está ejecutándose en el servidor remoto
- Confirmar que el firewall permite conexiones SSH desde la IP de origen
- Verificar que la clave SSH está autorizada en el servidor remoto
- Comprobar que la dirección IP del servidor remoto es correcta

#### Problema 2: Túnel Se Establece Pero Puerto No Escucha

**Síntomas:** El servicio está activo pero netstat no muestra el puerto local escuchando

**Diagnóstico:**
```bash
# Ver logs de autossh
journalctl -u ssh-tunnel-mysql -n 50 | grep -i forward

# Verificar proceso ssh
ps aux | grep ssh | grep -v grep

# Verificar que el servicio remote tiene el puerto disponible
ssh tunnelmgr@192.168.1.11 "netstat -tlnp | grep 3306"
```

**Solución más común:** El servicio MySQL en el servidor remoto no está ejecutándose o está bindeado a una interfaz diferente. Verificar la configuración bind-address de MySQL.

#### Problema 3: Túnel Se Cae Frecuentemente

**Síntomas:** El túnel funciona pero se cae regularmente, causando interrupciones

**Diagnóstico:**
```bash
# Ver frecuencia de reinicios
journalctl -u ssh-tunnel-mysql --since "1 hour ago" | grep -i restart

# Verificar estabilidad de red
ping -c 100 192.168.1.11

# Verificar MTU
ip link | grep mtu
```

**Soluciones:**
- Reducir ServerAliveInterval a 30 segundos
- Aumentar ServerAliveCountMax a 5
- Verificar que no hay problemas de MTU (Fragmentation needed)
- Considerar agregar persistencia de conexión SSH (ControlPersist)

#### Problema 4: Autenticación SSH Falla

**Síntomas:** "Permission denied (publickey)" en logs

**Diagnóstico:**
```bash
# Verificar permisos de clave
ls -la ~/.ssh/id_ed25519
ls -la ~/.ssh/id_ed25519.pub

# Verificar clave autorizada en remoto
ssh tunnelmgr@192.168.1.11 "cat ~/.ssh/authorized_keys"

# Probar autenticación manual
ssh -i ~/.ssh/id_ed25519 tunnelmgr@192.168.1.11
```

**Soluciones:**
- Regenerar claves SSH si están corruptas
- Verificar que la clave pública está en authorized_keys del remoto
- Confirmar que los permisos de ~/.ssh son 700 y archivos 600
- Verificar que el usuario tunnelmgr existe en el servidor remoto

#### Problema 5: Memoria Excedida (C1 Violation)

**Síntomas:** Procesos autossh muertos por OOM killer

**Diagnóstico:**
```bash
# Ver logs de OOM
dmesg | grep -i oom | tail -20

# Ver uso de memoria
free -h

# Ver proceso autossh
ps aux | grep autossh
```

**Soluciones:**
- Reducir MemoryMax en la unidad systemd a 256M
- Desactivar ControlMaster si no es necesario
- Reducir cantidad de túneles simultáneos
- Verificar que no hay memory leaks en ssh

### Tabla de Referencia Rápida de Errores

| Error en Logs | Causa Probable | Solución |
|---------------|----------------|----------|
| "Connection refused" | SSH no corre o firewall bloquea | Verificar servicio SSH y reglas UFW |
| "Permission denied" | Clave SSH no autorizada | Regenerar/reinstalar clave SSH |
| "No route to host" | Problema de red/enrutamiento | Verificar conectividad IP y gateway |
| "Connection timed out" | Firewall o red no reachable | Verificar reglas firewall, NAT |
| "Address already in use" | Puerto local en uso | Cambiar puerto local o matar proceso |
| "Remote port forward failed" | Puerto remoto no disponible | Verificar servicio destino en remoto |
| "ControlMaster conflict" | Otra conexión con mismo socket | Matar conexiones ssh antiguas |

---

## Compliance Notes (C3)

### Requisito C3: Restricción de Exposición de Servicios

La restricción C3 del proyecto MANTIS AGENTIC establece explícitamente que MySQL y Qdrant nunca deben estar expuestos en direcciones 0.0.0.0 o 0.0.0.0/0. Esta restricción es fundamental para la seguridad de la arquitectura y los túneles SSH son el mecanismo que hace posible cumplir con este requisito mientras se mantiene la conectividad necesaria entre servicios.

### Verificación de Cumplimiento

```bash
#!/bin/bash
#===============================================================================
# SCRIPT: verify-c3-compliance.sh
# PROPOSITO: Verificar cumplimiento de restricción C3
# PROYECTO: MANTIS AGENTIC
#===============================================================================

set -euo pipefail

echo "============================================================================"
echo "VERIFICACIÓN DE CUMPLIMIENTO C3 - Restricción de Exposición de Servicios"
echo "============================================================================"
echo ""

echo "C3: MySQL y Qdrant NUNCA deben estar en 0.0.0.0"
echo ""

# Verificar MySQL
echo "--- MySQL ---"
if netstat -tlnp 2>/dev/null | grep ':3306' | grep -v '127.0.0.1:3306' | grep -v '::1:3306' | grep -q '0.0.0.0:3306'; then
    echo "  VIOLACIÓN C3: MySQL expuesto en 0.0.0.0:3306"
    echo "  Puertos escuchando:"
    netstat -tlnp 2>/dev/null | grep ':3306'
    exit 1
else
    echo "  OK: MySQL no expuesto en 0.0.0.0"
fi

# Verificar Qdrant
echo ""
echo "--- Qdrant ---"
for port in 6333 6334; do
    if netstat -tlnp 2>/dev/null | grep ":${port}" | grep -v '127.0.0.1' | grep -v '::1' | grep -q '0.0.0.0'; then
        echo "  VIOLACIÓN C3: Qdrant expuesto en 0.0.0.0:${port}"
        netstat -tlnp 2>/dev/null | grep ":${port}"
        exit 1
    else
        echo "  OK: Qdrant puerto ${port} no expuesto en 0.0.0.0"
    fi
done

echo ""
echo "============================================================================"
echo "CUMPLIMIENTO C3 VERIFICADO EXITOSAMENTE"
echo "============================================================================"
```

### Arquitectura C3-Compliant

En una arquitectura C3-compliant, la configuración de red es la siguiente:

**En VPS-2 (servidor de bases de datos):**
```ini
# MySQL my.cnf
bind-address = 127.0.0.1

# Qdrant config.yaml
service:
  host: 127.0.0.1
  http_port: 6333
  grpc_port: 6334
```

**En VPS-1 y VPS-3 (clientes):**
```bash
# Los túneles exponen los servicios localmente
# VPS-1 -> VPS-2:3306 -> localhost:3306
# VPS-3 -> VPS-2:6333 -> localhost:6333
```

Esta configuración garantiza que las bases de datos solo son accesibles desde localhost en VPS-2, pero las aplicaciones en VPS-1 y VPS-3 pueden acceder a ellas a través de los túneles SSH cifrados.

---

## Mantenimiento

### Tareas de Mantenimiento Preventivo

El mantenimiento preventivo de los túneles SSH debe realizarse regularmente para garantizar la disponibilidad y seguridad del sistema. Las siguientes tareas deben programarse y ejecutarse de manera periódica.

**Semanalmente:**
- Ejecutar script de health-check para verificar todos los túneles
- Revisar logs de systemd para identificar patrones de fallos
- Verificar que los servicios están habilitados para inicio automático
- Comprobar que no hay acumulación de sockets SSH huérfanos

**Mensualmente:**
- Rotar claves SSH si ha pasado el período de rotación configurado
- Actualizar paquetes de seguridad en todos los VPS
- Realizar pruebas de failover simulando caídas de túneles
- Documentar cualquier incidencia y su resolución
- Verificar que los límites de recursos (MemoryMax) siguen siendo apropiados

**Trimestralmente:**
- Revisar y actualizar la documentación de arquitectura de túneles
- Verificar cumplimiento de todas las restricciones (C1, C2, C3)
- Realizar auditoría de claves SSH autorizadas
- Probar procedimientos de recuperación ante desastres
- Evaluar si la configuración actual sigue siendo óptima

### Procedimiento de Actualización de Claves SSH

Cuando sea necesario actualizar las claves SSH (por seguridad o rotación programada), el procedimiento debe seguir un orden específico para evitar bloquearse fuera de los servidores.

```bash
#!/bin/bash
#===============================================================================
# SCRIPT: rotate-ssh-keys.sh
# PROPOSITO: Rotar claves SSH de manera segura
# ADVERTENCIA: Ejecutar en el orden especificado para evitar lockout
#===============================================================================

set -euo pipefail

# 1. Generar nueva clave en LOCAL (VPS-1)
# ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_new -C "tunnelmgr@$(hostname)-$(date +%Y%m%d)"

# 2. Copiar clave pública a SERVIDOR REMOTO (VPS-2)
# ssh-copy-id -i ~/.ssh/id_ed25519_new.pub tunnelmgr@192.168.1.11

# 3. Verificar que nueva clave funciona
# ssh -i ~/.ssh/id_ed25519_new tunnelmgr@192.168.1.11 "echo 'Nueva clave funciona'"

# 4. ACTUALIZAR CONFIGURACIÓN EN LOCAL
# mv ~/.ssh/id_ed25519 ~/.ssh/id_ed25519_old
# mv ~/.ssh/id_ed25519_new ~/.ssh/id_ed25519
# chmod 600 ~/.ssh/id_ed25519

# 5. REINICIAR SERVICIOS DE TÚNEL
# systemctl restart ssh-tunnel-mysql
# systemctl restart ssh-tunnel-qdrant

# 6. VERIFICAR QUE TÚNELES FUNCIONAN CON NUEVA CLAVE
# ./validate-ssh-tunnels.sh

# 7. ELIMINAR CLAVE VIEJA DEL SERVIDOR REMOTO
# ssh tunnelmgr@192.168.1.11 "mv ~/.ssh/authorized_keys ~/.ssh/authorized_keys_old"
# ssh tunnelmgr@192.168.1.11 "cat ~/.ssh/authorized_keys_new >> ~/.ssh/authorized_keys"
# ssh tunnelmgr@192.168.1.11 "rm ~/.ssh/authorized_keys_old ~/.ssh/authorized_keys_new"
```

### Procedimiento de Escalamiento de Problemas

Cuando los procedimientos de troubleshooting estándar no resuelven el problema, se debe seguir el siguiente proceso de escalamiento.

**Nivel 1 - Auto-resolución:**
- Revisar logs del servicio con journalctl
- Ejecutar scripts de health-check
- Intentar reinicio del servicio

**Nivel 2 - Verificación de infraestructura:**
- Verificar conectividad de red entre VPS
- Confirmar que servicios remotos están ejecutándose
- Verificar reglas de firewall en ambos extremos

**Nivel 3 - Soporte de Hostinger:**
- Si el problema es de conectividad de red (no atribuible a configuración)
- Reportar ticket de soporte con diagnósticos realizados
- Proporcionarmtr/tracepath hacia los otros VPS

**Nivel 4 - Ingeniería de proyecto:**
- Escalar al equipo de desarrollo de MANTIS AGENTIC
- Proporcionar logs completos, configuración, y timeline de eventos
- Documentar workaround temporales si están implementados

---

## Referencias

- [SSH Key Management](./ssh-key-management.md)
- [UFW Firewall Configuration](./ufw-firewall-configuration.md)
- [Security Rules](../01-RULES/03-SECURITY-RULES.md)
- [Architecture Rules](../01-RULES/01-ARCHITECTURE-RULES.md)
- [Resource Guardrails](../01-RULES/02-RESOURCE-GUARDRAILS.md)

---

## Historial de Cambios

| Versión | Fecha | Autor | Cambios |
|---------|-------|-------|---------|
| 1.0.0 | 2026-04-09 | Mantis-AgenticDev | Versión inicial |

---

*Este documento es parte del proyecto MANTIS AGENTIC - Agentic Infra Docs*
* Specification-Driven Development (SDD) Methodology*
