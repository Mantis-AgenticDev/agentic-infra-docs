---
title: "security-hardening-vps"
category: "Skill"
domain: ["generico", "seguridad", "infraestructura"]
constraints: ["C1", "C2", "C3", "C5", "C6"]
priority: "CRÍTICA"
version: "1.0.0"
last_updated: "2026-04-10"
ai_optimized: true
tags:
  - sdd/skill/seguridad
  - lang/es
related_files:
  - "01-RULES/03-SECURITY-RULES.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
  - "00-CONTEXT/facundo-infrastructure.md"
  - "00-CONTEXT/facundo-core-context.md"
  - "02-SKILLS/INFRAESTRUCTURA/ufw-firewall-configuration.md"
  - "02-SKILLS/INFRAESTRUCTURA/fail2ban-configuration.md"
  - "02-SKILLS/INFRAESTRUCTURA/ssh-key-management.md"
  - "02-SKILLS/SEGURIDAD/backup-encryption.md"
---

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

**¿Qué vas a lograr en 10 minutos?**  
Transformar un VPS OVH recién instalado (Ubuntu 22.04/24.04) en un bastión seguro conforme a las políticas de MANTIS AGENTIC. Al finalizar, el servidor rechazará intentos de acceso por contraseña, bloqueará escaneos de puertos automáticos y mantendrá un registro de auditoría inmutable para cumplir con la trazabilidad multi-tenant (C4).

**Contexto específico de Facundo ([[00-CONTEXT/facundo-infrastructure.md]]):**  
- **VPS OVH**: 2 vCPU / 4 GB RAM / 80 GB SSD NVMe.  
- **IP Pública**: `51.XX.XX.XX` (única interfaz expuesta).  
- **Servicios activos**: n8n (puerto 5678), EspoCRM (8080), Qdrant (6333).  

**Pasos relámpago (ejecuta como root o usuario con sudo):**
1. **Actualiza el sistema y habilita actualizaciones de seguridad automáticas:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo apt install unattended-upgrades -y
   sudo dpkg-reconfigure --priority=low unattended-upgrades
   ```
2. **Deshabilita el acceso SSH por contraseña (C3):**
   ```bash
   sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
   sudo systemctl restart sshd
   ```
3. **Configura el firewall UFW restrictivo (C3):**
   ```bash
   sudo ufw default deny incoming
   sudo ufw default allow outgoing
   sudo ufw allow 22/tcp comment 'SSH'
   sudo ufw allow 80,443/tcp comment 'Web'
   sudo ufw enable
   ```
4. **Instala y activa Fail2ban para SSH:**
   ```bash
   sudo apt install fail2ban -y
   sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
   sudo systemctl enable fail2ban --now
   ```

⚠️ **Advertencia crítica:** Antes de cerrar la sesión SSH actual, **abre una segunda terminal** y verifica que puedes conectarte. Si bloqueas el puerto 22 accidentalmente, perderás el acceso al VPS.

## 🎯 Propósito y Alcance

Este documento define el **endurecimiento de seguridad base** para cualquier VPS que forme parte de la infraestructura de MANTIS AGENTIC. Se enfoca en la **superficie de ataque externa** (red, SSH, servicios expuestos) y en la **defensa en profundidad** a nivel de sistema operativo.

**Alcance específico:**
- Configuración segura de SSH (claves, algoritmos, banners).
- Firewall `ufw` con políticas por defecto restrictivas.
- `fail2ban` para mitigación de fuerza bruta.
- Ajustes de kernel (`sysctl`) para protección de red (Syn Cookies, IP Spoofing).
- Auditoría de eventos de seguridad (`auditd`) con foco en `tenant_id` (C4).
- **Exclusiones:** Este skill **no** cubre la seguridad de aplicaciones web (WAF) ni la gestión de secretos en contenedores (eso está en [[01-RULES/03-SECURITY-RULES.md]]).

## 📐 Fundamentos (De 0 a Intermedio)

### 1. El Principio de Mínimo Privilegio en un VPS
Cada servicio que corre en tu VPS (n8n, Qdrant) debe ejecutarse con el usuario **menos privilegiado posible**. Si un atacante explota una vulnerabilidad en n8n y el proceso corre como `root`, el atacante toma control total del servidor. Si corre como usuario `n8n`, el daño está limitado a los archivos de ese usuario.

**Analogía universitaria:** Es como la diferencia entre darle a un alumno la llave maestra del edificio o solo la llave de su taquilla. Un problema en la taquilla no compromete el despacho del decano.

### 2. Defensa en Profundidad: El Modelo de las Capas de Cebolla
La seguridad no depende de una sola medida. Si falla una, la siguiente debe detener el ataque. En MANTIS aplicamos:
1. **Capa 1 (Perímetro):** Firewall `ufw` (solo puertos necesarios).
2. **Capa 2 (Autenticación):** Claves SSH ED25519 (sin contraseña en el servidor).
3. **Capa 3 (Detección):** `fail2ban` (banea IPs que fallan repetidamente).
4. **Capa 4 (Kernel):** Parámetros `sysctl` (mitiga ataques de red).
5. **Capa 5 (Auditoría):** `auditd` (rastrea quién hizo qué, C4).

### 3. El Impacto de las Actualizaciones en Producción (C1/C2)
Las actualizaciones de seguridad automáticas (`unattended-upgrades`) son **obligatorias** en MANTIS, pero deben configurarse para no reiniciar servicios en horas pico. En un VPS de 2 vCPU, una actualización de kernel que requiera reinicio **debe programarse** manualmente en la ventana de mantenimiento de las 3:00 AM (UTC-3).

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

<!-- ai:constraint=C1,C2 -->

El hardening consume recursos mínimos en estado estable, pero ciertas operaciones de escaneo o logueo intensivo pueden afectar a n8n/EspoCRM.

| Componente | Riesgo de Rendimiento | Mitigación MANTIS |
| :--- | :--- | :--- |
| **Fail2ban** | Bajo. Solo analiza logs en segundo plano. | Ajustar `findtime` y `maxretry` para evitar bloqueos por falsos positivos (Ej. tecleo rápido). |
| **Auditd** | **Medio-Alto**. Registrar *todas* las llamadas al sistema puede consumir disco y CPU. | Reglas específicas (solo monitorizar `/etc/`, `/var/www/espocrm/`). Excluir `/var/log` para evitar bucles de log. |
| **Sysctl (SynCookies)** | Muy bajo. Protección a nivel de kernel casi gratuita. | Siempre activado. |
| **Unattended-Upgrades** | Alto durante la instalación de paquetes (uso de CPU y I/O). | `APT::Periodic::Update-Package-Lists "1"` (diario a las 06:00 UTC). Usar `nice` implícito de `apt`. |

**Comando de monitoreo de impacto:**
```bash
# Observar procesos de auditoría en tiempo real
top -b -n 1 | grep -E "(fail2ban|auditd)"
# %CPU de auditd debe ser < 2.0 en idle.
```

## 🔗 Integración con Stack Existente (n8n, Qdrant, EspoCRM)

El hardening no debe romper la funcionalidad. Cada regla debe validarse contra el stack de Facundo.

1.  **n8n (Acceso al Editor):**
    - Por defecto n8n escucha en `0.0.0.0:5678`.
    - **Riesgo:** Exponer el editor sin contraseña a internet.
    - **Regla de Hardening:** Usar `ufw` para **bloquear el puerto 5678 del exterior** y acceder solo mediante **SSH Túnel Local** (`ssh -L 5678:localhost:5678 user@VPS`). Esto elimina la necesidad de configurar autenticación web compleja.

2.  **Qdrant (API de Vectores):**
    - Por defecto escucha en `0.0.0.0:6333`.
    - **Regla de Hardening:** Modificar `config/production.yaml` para que escuche en `127.0.0.1:6333`. Ningún servicio externo necesita acceder directamente a Qdrant sin pasar por n8n.

3.  **EspoCRM (C4 - Auditoría Multi-Tenant):**
    - `auditd` se configura para vigilar cambios en `custom/Espo/Custom/Resources/metadata/`.
    - Cuando se modifica un archivo, el log de auditoría incluye el `uid` y `gid` del proceso. El script de envoltura de MANTIS debe traducir ese `uid` al `tenant_id` correspondiente para cumplir con C4.

## 🛠️ 10 Ejemplos de Implementación (Copy-Paste Validables)

### Ejemplo 1: Configuración Robusta de SSH (Prohibir Root Login y Contraseñas)
**Objetivo**: Eliminar la capacidad de iniciar sesión como `root` o usando contraseñas débiles.
**Nivel**: 🟢

```bash
# Realizar backup de la configuración actual
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Aplicar configuraciones seguras
sudo tee -a /etc/ssh/sshd_config.d/99-mantis-hardening.conf << EOF
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
EOF

# Verificar sintaxis (MUY IMPORTANTE)
sudo sshd -t

# Reiniciar servicio
sudo systemctl restart sshd

✅ Deberías ver:
# Después de reiniciar, intenta conectar por contraseña:
ssh -o PreferredAuthentications=password usuario@IP
# Resultado: Permission denied (publickey).

❌ Si ves esto en su lugar:
sshd: no hostkeys available -- exiting.

→ Ve a Troubleshooting #3
```
🔗 Conceptos relacionados: [[02-SKILLS/INFRAESTRUCTURA/ssh-key-management.md]]

### Ejemplo 2: Configuración Inicial de UFW para el Stack de Facundo
**Objetivo**: Abrir solo los puertos esenciales (HTTP/HTTPS y SSH) siguiendo el modelo de [[00-CONTEXT/facundo-infrastructure.md]].
**Nivel**: 🟢

```bash
# Política por defecto: Bloquear entrada, permitir salida
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Servicios expuestos (C3: mínima exposición)
sudo ufw allow 22/tcp comment 'SSH Admin Access'
sudo ufw allow 80/tcp comment 'HTTP - EspoCRM / n8n Webhook'
sudo ufw allow 443/tcp comment 'HTTPS - EspoCRM / n8n Webhook'

# ACTIVAR (cuidado: si estás conectado por SSH, el puerto 22 ya está permitido)
sudo ufw --force enable

# Verificar estado
sudo ufw status numbered

✅ Deberías ver:
Status: active

     To                         Action      From
     --                         ------      ----
[ 1] 22/tcp                     ALLOW IN    Anywhere
[ 2] 80/tcp                     ALLOW IN    Anywhere
[ 3] 443/tcp                    ALLOW IN    Anywhere

❌ Si ves esto en su lugar:
ERROR: problem running iptables: Another app is currently holding the xtables lock.

→ Ve a Troubleshooting #1
```
🔗 Conceptos relacionados: [[02-SKILLS/INFRAESTRUCTURA/ufw-firewall-configuration.md]]

### Ejemplo 3: Instalación y Configuración de Fail2ban para SSH
**Objetivo**: Bloquear durante 1 hora cualquier IP que falle 3 veces la autenticación SSH en 10 minutos.
**Nivel**: 🟡

```bash
sudo apt install fail2ban -y

# Crear archivo de configuración local para SSH
sudo tee /etc/fail2ban/jail.d/ssh-mantis.conf << EOF
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
findtime = 600
bantime = 3600
EOF

# Reiniciar fail2ban
sudo systemctl restart fail2ban

# Verificar que la jaula (jail) está activa
sudo fail2ban-client status sshd

✅ Deberías ver:
Status for the jail: sshd
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /var/log/auth.log
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:

❌ Si ves esto en su lugar:
ERROR  NOK: ('sshd',)

→ Ve a Troubleshooting #2
```

### Ejemplo 4: Ajustes de Kernel (sysctl) para Mitigar Ataques de Red (Syn Flood)
**Objetivo**: Activar protecciones TCP/IP que vienen desactivadas por defecto en Ubuntu.
**Nivel**: 🟡

```bash
# Crear archivo de configuración MANTIS
sudo tee /etc/sysctl.d/99-mantis-network-hardening.conf << EOF
# Protección contra Syn Flood (C1: bajo consumo CPU)
net.ipv4.tcp_syncookies = 1

# Ignorar paquetes ICMP echo (ping) broadcast
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Ignorar redirecciones ICMP (evita envenenamiento de rutas)
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Habilitar filtro de ruta inversa (anti-spoofing)
net.ipv4.conf.all.rp_filter = 1
EOF

# Aplicar cambios sin reiniciar
sudo sysctl -p /etc/sysctl.d/99-mantis-network-hardening.conf

# Verificar valor
cat /proc/sys/net/ipv4/tcp_syncookies

✅ Deberías ver:
1

❌ Si ves esto en su lugar:
sysctl: cannot stat /proc/sys/net/ipv4/...: No such file or directory

→ Kernel antiguo o módulo no cargado. Actualizar kernel con `sudo apt install linux-generic`.
```

### Ejemplo 5: Auditoría de Cambios en Archivos de Configuración de EspoCRM (C4)
**Objetivo**: Registrar cada vez que se modifica un archivo de entidad en EspoCRM, crucial para la trazabilidad multi-tenant.
**Nivel**: 🔴

```bash
# Instalar auditd
sudo apt install auditd -y

# Añadir regla para vigilar escrituras en custom/Espo/
sudo auditctl -w /var/www/espocrm/custom/Espo/Custom/Resources/metadata/ -p wa -k espo_entity_changes

# Hacer la regla permanente
echo "-w /var/www/espocrm/custom/Espo/Custom/Resources/metadata/ -p wa -k espo_entity_changes" | sudo tee -a /etc/audit/rules.d/audit.rules

# Probar: Crear un archivo dummy (simula cambio)
sudo -u www-data touch /var/www/espocrm/custom/Espo/Custom/Resources/metadata/test.json

# Buscar el evento en los logs
sudo ausearch -k espo_entity_changes | tail -n 5

✅ Deberías ver:
time->Mon Apr 10 10:00:00 2026
type=PROCTITLE msg=audit(...)
type=PATH msg=audit(...) name="/var/www/espocrm/custom/.../test.json"
type=SYSCALL msg=audit(...) syscall=257 success=yes

❌ Si ves esto en su lugar:
<no matches>

→ Ve a Troubleshooting #6
```

### Ejemplo 6: Deshabilitar Servicios Innecesarios para Reducir Superficie de Ataque
**Objetivo**: Detener y enmascarar servicios que no se usan en un VPS de aplicación (ej. `cups`, `avahi-daemon`).
**Nivel**: 🟢

```bash
# Listar servicios activos escuchando en red
sudo ss -tulpn

# Identificar servicios que no deberían estar (ej. cups en 0.0.0.0:631)
# Proceder a detenerlos y enmascararlos (imposible iniciarlos manualmente por error)
sudo systemctl stop cups
sudo systemctl disable cups
sudo systemctl mask cups

# Verificar estado
systemctl status cups

✅ Deberías ver:
Loaded: masked (Reason: Unit cups.service is masked.)
Active: inactive (dead)

❌ Si ves esto en su lugar:
Failed to stop cups.service: Unit cups.service not loaded.

→ El servicio ya no está instalado. Nada que hacer.
```

### Ejemplo 7: Bloqueo de Escaneos de Puertos con Puertos Trampa (Port Knocking Pasivo)
**Objetivo**: Hacer que el escaneo de puertos con `nmap` sea más lento y detectable, bloqueando temporalmente al escáner.
**Nivel**: 🔴

```bash
# Configurar fail2ban para que detecte intentos de conexión a puertos cerrados (iptables logs)
# Primero, habilitar logging de paquetes denegados en UFW
sudo ufw logging on

# Crear jail para "portscan"
sudo tee /etc/fail2ban/jail.d/portscan-mantis.conf << EOF
[portscan]
enabled = true
filter = portscan
logpath = /var/log/ufw.log
maxretry = 5
findtime = 60
bantime = 86400
action = iptables-allports[name=portscan]
EOF

# Crear filtro personalizado (busca líneas de UFW BLOCK)
sudo tee /etc/fail2ban/filter.d/portscan.conf << EOF
[Definition]
failregex = ^\s*\S+ kernel: .*UFW BLOCK.* SRC=<HOST> .* PROTO=TCP .*
ignoreregex =
EOF

# Reiniciar fail2ban
sudo systemctl restart fail2ban

✅ Deberías ver:
Después de ejecutar `nmap -p- <IP>` desde fuera, la IP queda baneada por 24h.

❌ Si ves esto en su lugar:
fail2ban-regex test fails.

→ El formato del log de UFW puede variar. Usa `tail -f /var/log/ufw.log` para ver el formato exacto y ajustar `failregex`.
```

### Ejemplo 8: Configuración de Actualizaciones de Seguridad Automáticas (Unattended-Upgrades)
**Objetivo**: Garantizar que los parches de seguridad críticos se aplican sin intervención humana, pero solo para repositorios oficiales.
**Nivel**: 🟡

```bash
sudo apt install unattended-upgrades update-notifier-common -y

# Configurar orígenes permitidos (SOLO seguridad)
sudo tee /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
        "\${distro_id}:\${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";
EOF

# Activar el servicio
sudo dpkg-reconfigure -plow unattended-upgrades

# Simular una ejecución (ver qué se instalaría)
sudo unattended-upgrade --dry-run --debug

✅ Deberías ver:
pkgs that look like they should be upgraded: ...

❌ Si ves esto en su lugar:
/usr/bin/dpkg returned an error code (1)

→ Ve a Troubleshooting #8
```

### Ejemplo 9: Restricción de Acceso a n8n vía SSH Túnel (Alternativa a Exponer Puerto 5678)
**Objetivo**: Acceder al editor de n8n de forma segura sin abrir el puerto 5678 al mundo.
**Nivel**: 🟡

```bash
# En el VPS: Asegurar que n8n escucha solo en localhost
# Editar .env de n8n o archivo de configuración docker:
N8N_HOST=localhost
N8N_PORT=5678

# Reiniciar n8n
sudo systemctl restart n8n

# En tu MÁQUINA LOCAL (Linux/Mac/WSL):
ssh -L 5678:localhost:5678 usuario@IP_DEL_VPS

# Abrir navegador local en: http://localhost:5678

✅ Deberías ver:
La interfaz de n8n cargando correctamente a través del túnel cifrado.

❌ Si ves esto en su lugar:
channel 2: open failed: connect failed: Connection refused

→ n8n no está corriendo en el VPS o no está escuchando en localhost:5678.
```

### Ejemplo 10: Endurecimiento de Permisos de Archivos de Configuración Sensibles
**Objetivo**: Asegurar que los archivos `.env` y claves SSH privadas solo puedan ser leídos por su propietario.
**Nivel**: 🟢

```bash
# Buscar archivos con permisos inseguros en directorios críticos
find /home /root /etc /var/www -type f \( -name "*.env" -o -name "id_*" -o -name "*.key" \) -perm /o+r -exec ls -l {} \;

# Corregir permisos para el .env de n8n (ejemplo)
sudo chmod 600 /home/mantis/n8n/.env
sudo chown mantis:mantis /home/mantis/n8n/.env

# Verificar
ls -l /home/mantis/n8n/.env

✅ Deberías ver:
-rw------- 1 mantis mantis 1024 Apr 10 09:00 .env

❌ Si ves esto en su lugar:
-rw-r--r-- 1 mantis mantis 1024 Apr 10 09:00 .env

→ Archivo legible para "otros". Ejecuta el comando chmod 600.
```

## 🐞 10 Eventos/Problemas Críticos y Troubleshooting

| Error Exacto (copiable) | Causa Raíz (lenguaje simple) | Comando de Diagnóstico | Solución Paso a Paso | Constraint Afectado (C#) |
| :--- | :--- | :--- | :--- | :--- |
| `ERROR: problem running iptables: Another app is currently holding the xtables lock` | Otro proceso (Docker, `ufw` ejecutándose en otra shell) está modificando las reglas de firewall al mismo tiempo. | `sudo lsof /run/xtables.lock` | 1. Esperar unos segundos (el bloqueo es temporal). 2. Si persiste, identificar proceso con `ps aux | grep iptables`. 3. Si es Docker, reiniciar Docker **después** de configurar UFW (`sudo systemctl restart docker`). | C3 (Firewall inactivo) |
| `ERROR NOK: ('sshd',)` en Fail2ban | El archivo de log `/var/log/auth.log` no existe o `fail2ban` no tiene permisos de lectura. También puede deberse a que `sshd` no está instalado. | `ls -l /var/log/auth.log` y `sudo fail2ban-client -d`. | 1. Asegurar que `rsyslog` está corriendo: `systemctl status rsyslog`. 2. Verificar que el backend es `systemd` (en Ubuntu moderno): `fail2ban-client set logtarget /var/log/fail2ban.log`. 3. Modificar `jail.d/ssh-mantis.conf` añadiendo `backend = systemd`. | C3 / C5 (Monitorización fallida) |
| `sshd: no hostkeys available -- exiting.` | El servicio SSH no puede encontrar las claves privadas del servidor (HostKeys). Sucede tras un mal respaldo o corrupción. | `ls -l /etc/ssh/ssh_host_*` | 1. **No reiniciar el servicio si hay una sesión abierta**. 2. Regenerar claves faltantes: `sudo ssh-keygen -A`. 3. Verificar que `sshd_config` apunta a las rutas correctas. | C3 (Pérdida de acceso remoto) |
| `UFW BLOCK` en logs pero servicio sigue accesible (ej. n8n puerto 5678) | Docker manipula `iptables` directamente saltándose las reglas de UFW. UFW ve el tráfico como bloqueado, pero Docker lo permite internamente. | `sudo iptables -L DOCKER -n -v` | 1. **Solución real:** No exponer puertos en Docker con `-p 5678:5678`. Usar `-p 127.0.0.1:5678:5678`. 2. Si el puerto debe estar expuesto, usar `sudo ufw allow 5678`. | C3 (Falsa sensación de seguridad) |
| `audit: backlog limit exceeded` en `dmesg` | `auditd` está generando más eventos de los que el kernel puede encolar en el buffer. Riesgo de pérdida de eventos de auditoría (C4). | `sudo auditctl -s` | 1. Aumentar el buffer: `sudo auditctl -b 8192`. 2. Reducir la verbosidad de las reglas (evitar `-p wa` en directorios con mucha escritura como `cache/`). 3. Mover logs a disco más rápido. | C4 (Pérdida de trazabilidad) |
| `ausearch` no muestra eventos para archivos modificados por usuario `www-data` | La regla de auditoría no incluye el flag `-F uid!=0` o similar, o el proceso usa llamadas al sistema no capturadas. | `sudo auditctl -l` (lista reglas activas). | 1. Verificar que la regla tiene `-p wa`. 2. Probar con `-S all` (peligroso en producción) solo para debug: `auditctl -w /path -p w -k test -S all`. 3. Asegurar que el sistema de archivos soporta auditoría (ext4/xfs). | C4 |
| El servidor no arranca tras aplicar `sysctl` hardening (kernel panic) | Configuración incompatible con el hardware virtual de OVH (ej. deshabilitar IPv6 completamente cuando OVH lo requiere para la red interna). | Acceder por consola de emergencia OVH (KVM/IPMI). | 1. Arrancar en modo rescate. 2. Montar disco y eliminar o comentar la línea problemática en `/etc/sysctl.d/99-mantis...`. 3. **Recomendación:** No deshabilitar IPv6 (`net.ipv6.conf.all.disable_ipv6 = 1`) en OVH, usar `prefer_ipv4` en aplicaciones. | C1 (Indisponibilidad del servicio) |
| `unattended-upgrade` rompe dependencias de n8n (Error de Node.js) | `unattended-upgrade` actualizó `nodejs` a una versión incompatible con n8n, o actualizó bibliotecas del sistema de forma inconsistente. | `cat /var/log/unattended-upgrades/unattended-upgrades.log` | 1. **Prevención:** Usar `Unattended-Upgrade::Package-Blacklist` para excluir `nodejs`, `docker`, `postgresql`. 2. Solución: Reinstalar versión específica de Node desde NodeSource (`curl -fsSL https://deb.nodesource.com/setup_20.x`). | C5 (Integridad del stack) |
| Conexión SSH rechazada: `Connection closed by remote host` después de habilitar `PasswordAuthentication no` | No hay ninguna clave pública autorizada en `~/.ssh/authorized_keys` o los permisos del directorio `.ssh` son demasiado abiertos. | En modo rescate OVH: `ls -la /home/usuario/.ssh/` | 1. `chmod 700 ~/.ssh`. 2. `chmod 600 ~/.ssh/authorized_keys`. 3. Verificar que la clave privada en tu PC local corresponde a la pública pegada en el archivo. | C3 (Lockout total) |
| `fail2ban` banea IPs legítimas de usuarios (falsos positivos) | `maxretry` muy bajo (ej. 1) y el usuario escribe mal la contraseña una vez. O una aplicación mal configurada intenta reconectar con credenciales erróneas. | `sudo zgrep "Ban" /var/log/fail2ban.log` | 1. Aumentar `maxretry` a 3-5. 2. Usar `ignoreip` en `jail.local` para añadir la IP de la oficina o la IP pública de Facundo (`ignoreip = 127.0.0.1/8 ::1 51.XX.XX.XX`). 3. Desbanear manualmente: `sudo fail2ban-client set sshd unbanip <IP>`. | C4 / C1 (Denegación de servicio autoinfligida) |

## ✅ Validación SDD y Comandos de Verificación

<!-- ai:constraint=C5 -->

### 1. Auditoría Automatizada de Superficie de Ataque (C3)
Este script debe ejecutarse semanalmente vía cron. Genera un reporte de puertos abiertos y servicios escuchando.
```bash
#!/bin/bash
echo "=== MANTIS SECURITY AUDIT $(date) ==="
echo ">>> Puertos abiertos en todas las interfaces:"
ss -tulpn | grep -v "127.0.0.1"
echo ">>> Intentos de login fallidos SSH (últimas 24h):"
journalctl -u ssh --since "24 hours ago" | grep "Failed password" | wc -l
echo ">>> Estado de UFW:"
ufw status verbose
echo ">>> Paquetes actualizables de seguridad:"
apt list --upgradable 2>/dev/null | grep -i security
```

### 2. Verificación de Cumplimiento de Permisos (C6)
Comando que verifica que los archivos `.env` no sean legibles por "otros".
```bash
find /home /opt /etc -type f -name ".env" -perm /o+r 2>/dev/null
# Si la salida NO está vacía, INCUMPLE C6.
# Si está vacía, el cumplimiento es correcto.
```

### 3. Verificación de `auditd` y Trazabilidad (C4)
Simula un cambio en EspoCRM y verifica que aparece el log.
```bash
# Crear archivo de prueba
sudo -u www-data touch /var/www/espocrm/custom/Espo/Custom/Resources/metadata/audit_test.json
sleep 2
# Buscar en audit.log
sudo ausearch -f /var/www/espocrm/custom/Espo/Custom/Resources/metadata/audit_test.json
# Limpiar
sudo rm /var/www/espocrm/custom/Espo/Custom/Resources/metadata/audit_test.json
# Debe mostrar al menos un evento SYSCALL.
```

## 🔗 Referencias Cruzadas y Glosario

- **[[00-CONTEXT/facundo-infrastructure.md]]**: Especificaciones técnicas exactas de los VPS OVH.
- **[[00-CONTEXT/facundo-core-context.md]]**: Contexto del negocio y requisitos de cumplimiento.
- **[[02-SKILLS/INFRAESTRUCTURA/ufw-firewall-configuration.md]]**: Guía avanzada de reglas UFW para aplicaciones específicas.
- **[[02-SKILLS/INFRAESTRUCTURA/fail2ban-configuration.md]]**: Configuración detallada de jails para n8n y EspoCRM.
- **[[01-RULES/03-SECURITY-RULES.md]]**: Política de rotación de claves y gestión de secretos.

**Glosario Rápido:**
- **Syn Cookies**: Mecanismo para mitigar ataques de inundación SYN sin usar colas de memoria.
- **Jail (Fail2ban)**: Conjunto de reglas que definen qué logs vigilar y qué acción tomar (banear IP).
- **Auditd**: Subsistema de auditoría del kernel Linux que registra accesos a archivos y llamadas al sistema.
- **Enmascarar (systemctl mask)**: Impide que un servicio sea iniciado, incluso manualmente o por dependencias.
- **Port Knocking Pasivo**: Técnica de defensa que bloquea temporalmente a quien escanea puertos cerrados.

FIN DEL ARCHIVO
<!-- ai:file-end marker - do not remove -->
Versión 1.0.0 - 2026-04-10 - Mantis-AgenticDev
