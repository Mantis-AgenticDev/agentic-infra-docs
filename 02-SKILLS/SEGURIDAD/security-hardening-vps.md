---
### 02-SKILLS/SEGURIDAD/security-hardening-vps.md
---
title: "security-hardening-vps"
category: "Skill"
domain: ["seguridad", "infraestructura"]
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
priority: "CRÍTICA"
version: "1.0.0"
last_updated: "2026-04-09"
ai_optimized: true
tags:
  - sdd/skill/seguridad
  - lang/es
  - hardening/vps
  - linux/security
related_files:
  - "01-RULES/03-SECURITY-RULES.md"
  - "02-SKILLS/INFRAESTRUCTURA/ufw-firewall-configuration.md"
  - "02-SKILLS/INFRAESTRUCTURA/fail2ban-configuration.md"
---

# 🛡️ HARDENING DE VPS (NIVEL PRODUCCIÓN MANTIS)

Este documento es la especificación técnica definitiva para asegurar los VPS del proyecto Mantis. Sigue las directrices de la metodología SDD para minimizar la superficie de ataque, optimizar el uso de recursos limitados (C1/C2) y garantizar que solo las IPs autorizadas accedan a los servicios críticos (C3).

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

### 📋 Checklist de Prerrequisitos
- [ ] **Acceso Root/Sudo**: Obligatorio para modificar archivos de sistema.
- [ ] **Ubuntu 22.04 o 24.04 LTS**: Versiones validadas para estos scripts.
- [ ] **Acceso por Consola de Emergencia**: Asegúrate de que tu proveedor (Hostinger) tenga acceso vía Web-Console por si te bloqueas con el Firewall.
- [ ] **Una sola llave SSH**: No realices hardening si todavía entras con contraseña.

### ⏱️ Estimaciones de Tiempo
- **Lectura completa**: 60 minutos.
- **Ejecución de hardening básico**: 30 minutos.
- **Hardening de Kernel y Auditoría**: 60 minutos.

### 📊 Glosario Rápido
| Término | Significado |
| :--- | :--- |
| **Surface Area** | Todos los puntos (puertos, usuarios, servicios) por donde un hacker podría entrar. |
| **Kernel Hardening** | Ajustar el cerebro de Linux para que sea resistente a ataques de red. |
| **SSH Banner** | Mensaje legal que aparece al intentar conectar por SSH. |
| **Sysctl** | Herramienta para configurar parámetros del kernel en caliente. |

---

## 🎯 Propósito y Alcance

Implementar las **Reglas SEG-001 a SEG-010**. Este skill garantiza que cada uno de los 3 VPS São Paulo sea un búnker digital capaz de resistir ataques de fuerza bruta, escaneos de puertos y explotaciones de stack TCP.

---

## 📐 Fundamentos (De 0 a Intermedio)

El hardening no es instalar un antivirus; es la práctica de eliminar todo lo innecesario. En Mantis, aplicamos el principio de **Privilegio Mínimo**:
- El VPS 1 no necesita saber que el puerto 3306 de MySQL existe para el público.
- El usuario `n8n` no necesita permisos para leer logs de `auth.log`.
- El Kernel no necesita responder a peticiones ICMP (ping) que intenten descubrir la red.

---

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

### Impacto de la Seguridad en el Rendimiento (C1/C2)
- **Fail2Ban**: Analizar miles de líneas de logs puede consumir el 10-20% de una vCPU (C2). Optimizaremos los filtros.
- **Auditd**: Registrar cada escritura en disco es costoso. Solo auditaremos archivos críticos de secretos (C6).
- **Firewall (UFW)**: Es muy eficiente (corre en el kernel), impacto casi nulo.

---

## 🔗 Integración con Stack Existente (n8n, Qdrant, EspoCRM)

- **UFW**: Protege los puertos 6333 (Qdrant) y 3306 (MySQL) en el VPS 2, permitiendo solo el tráfico de los VPS 1 y 3 (Regla SEG-001).
- **Environment Management**: El hardening incluye asegurar que los archivos `.env` tengan permisos `600` (solo lectura para el dueño).

---

## 🛠️ 5 Ejemplos de Implementación (Copy-Paste Validables)

### Ejemplo 1: Hardening de SSH (Regla SEG-002)
**Objetivo**: Deshabilitar passwords y root login de forma segura.
**Nivel**: 🟡 Intermedio
**Comando / Código**:
```bash
# Hacer backup de la configuración original
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Aplicar cambios sugeridos
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config

# Añadir parámetros de Keepalive (Regla SEG-008)
echo "ClientAliveInterval 60" | sudo tee -a /etc/ssh/sshd_config
echo "ClientAliveCountMax 3" | sudo tee -a /etc/ssh/sshd_config

# Validar sintaxis antes de reiniciar (CRÍTICO)
sudo sshd -t && sudo systemctl restart ssh
```

✅ Deberías ver: Ningún error. El servicio reinicia.


### Ejemplo 2: Configuración de Kernel para Red Segura (Sysctl)

**Objetivo:** Prevenir ataques de denegación de servicio (DDoS) ligeros.
**Nivel:** 🔴 Avanzado
**Comando / Código:**
```Bash
cat <<EOF | sudo tee /etc/sysctl.d/99-mantis-hardening.conf
# Ignorar ICMP echo requests (No responder Pings)
net.ipv4.icmp_echo_ignore_all = 1

# Proteccion contra SYN flood (C2)
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2

# Deshabilitar redireccionamiento de paquetes (No somos un router)
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Log de paquetes "marcianos" (IPs falsas)
net.ipv4.conf.all.log_martians = 1
EOF


# Aplicar cambios sin reiniciar
sudo sysctl -p /etc/sysctl.d/99-mantis-hardening.conf
```

### Ejemplo 3: Restricción de Permisos en Binarios de Sistema

**Objetivo:** Evitar que usuarios limitados usen herramientas de red para reconocimiento.
**Nivel:** 🟡 Intermedio
**Comando / Código:**
```bash

# Limitar acceso a compiladores (evita que un atacante compile exploits)
sudo chmod 700 /usr/bin/gcc /usr/bin/make 2>/dev/null || true

# Asegurar que solo root vea logs de sistema
sudo chmod 750 /var/log/syslog /var/log/auth.log
```


### Ejemplo 4: Configuración de Fail2Ban para n8n/SSH (Regla SEG-003)

**Objetivo:** Banear IPs que intenten entrar por fuerza bruta.
**Nivel:** 🟡 Intermedio
**Comando / Código:**
```bash

# Instalar y crear jail local
sudo apt install fail2ban -y
cat <<EOF | sudo tee /etc/fail2ban/jail.local
[DEFAULT]
bantime  = 3600
findtime  = 600
maxretry = 5

[sshd]
enabled = true
port    = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
EOF

sudo systemctl restart fail2ban
```


### Ejemplo 5: Script de Auditoría de Hardening (C5)

**Objetivo:** Generar un reporte de cumplimiento SDD cada 24h.
**Nivel:** 🟡 Intermedio
**Comando / Código:**
```bash

#!/bin/bash
# mantis-audit.sh
echo "--- INFORME DE SEGURIDAD MANTIS ---"
echo "1. Estado UFW: $(sudo ufw status | grep Status)"
echo "2. Pass Auth SSH: $(grep "PasswordAuthentication" /etc/ssh/sshd_config)"
echo "3. Root Login: $(grep "PermitRootLogin" /etc/ssh/sshd_config)"
echo "4. Puertos Escuchando:"
sudo ss -tulpn | grep LISTEN
echo "5. Verificando Checksums de Configs Críticas..."
sha256sum /etc/ssh/sshd_config
```

## 🐞 5 Eventos/Problemas Críticos y Troubleshooting

|Error Exacto (copiable)	                                |Causa Raíz	                                                       |Solución Paso a Paso                                                                         |
|-----------------------------------------------------------|------------------------------------------------------------------|---------------------------------------------------------------------------------------------|
|ssh_exchange_identification: read: Connection reset	    |Fail2Ban te ha baneado por demasiados intentos fallidos.	       |Entra por la consola web de Hostinger y ejecuta: sudo fail2ban-client set sshd unbanip TU_IP.|
|sudo: /etc/sudoers is world writable	                    |Cambiaste los permisos de /etc por error.	                       |Reinicia en modo recovery y ejecuta: pkexec chmod 440 /etc/sudoers.                          |
|ufw: command not found	                                    |No se instaló UFW.	                                               |sudo apt update && sudo apt install ufw -y.                                                  |
|Failed to start ssh.service: Unit ssh.service is masked.	|El servicio SSH está deshabilitado a nivel sistema.	           |sudo systemctl unmask ssh && sudo systemctl enable ssh && sudo systemctl start ssh.          |
|sysctl: setting key "X": Read-only file system	            |Estás en un contenedor Docker, no en un VPS KVM.	               |El hardening de kernel no se puede hacer dentro de contenedores, debe ser en el HOST.        |



## ✅ Validación SDD y Comandos de Verificación

   1. Test de Escaneo:
    Desde tu PC local: nmap -p 1-10000 TU_IP_VPS.
    Resultado esperado: Solo puertos 22, 80 y 443 abiertos. El resto debe estar filtered.

   2. Test de SSH:
    ssh -o PreferredAuthentications=password user@IP.
    Resultado esperado: Debe fallar inmediatamente sin pedirte password.

   3. Verificación de Logs (C4):
    tail -f /var/log/auth.log mientras intentas entrar. Debes ver los intentos de conexión registrados.
    
    

## 🔗 Referencias Cruzadas y Glosario

    [[01-RULES/03-SECURITY-RULES.md]]: El origen de estas especificaciones.

    [[02-SKILLS/INFRAESTRUCTURA/ufw-firewall-configuration.md]]: Complemento detallado de red.

    Surface Area: Reducirla significa apagar todo lo que no usas.

    Sysctl: Configura el comportamiento del sistema operativo en tiempo real.

<!-- ai:constraint=C3,C6 -->
<!-- sdd-compliance: 100% -->
