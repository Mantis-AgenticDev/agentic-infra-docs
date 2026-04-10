---

### 2. 02-SKILLS/SEGURIDAD/rsync-automation.md

```markdown
---
title: "rsync-automation"
category: "Skill"
domain: ["generico", "infraestructura", "backup"]
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
priority: "ALTA"
version: "1.0.0"
last_updated: "2026-04-09"
ai_optimized: true
tags:
  - sdd/skill/infraestructura
  - lang/es
  - rsync/automation
  - vps/sync
related_files:
  - "01-RULES/01-ARCHITECTURE-RULES.md"
  - "01-RULES/07-SCALABILITY-RULES.md"
  - "02-SKILLS/INFRAESTRUCTURA/vps-interconnection.md"
---

# 🔄 AUTOMATIZACIÓN DE RSYNC (CENTRALIZACIÓN DE DATOS)

Este documento detalla el procedimiento estándar para la sincronización de archivos entre los 3 VPS de la arquitectura Mantis y el almacenamiento local externo. Cumple con la metodología Specification-Driven Development (SDD) al priorizar el ahorro de ancho de banda y la seguridad de la conexión (C3).

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

### 📋 Checklist de Prerrequisitos
- [ ] **Rsync instalado**: Verifica con `rsync --version` en ambos servidores (origen y destino).
- [ ] **SSH Keys**: Debes poder hacer `ssh user@vps` sin que te pida contraseña (ver `ssh-key-management.md`).
- [ ] **Puertos**: El puerto SSH (default 22 o custom) debe estar abierto en UFW (ver `ufw-firewall-configuration.md`).
- [ ] **Permisos**: El usuario que ejecuta rsync debe tener permisos de lectura en la carpeta de origen.

### ⏱️ Estimaciones de Tiempo
- **Lectura completa**: 30 minutos.
- **Configuración de túneles/llaves**: 20 minutos.
- **Pruebas de sincronización**: 20 minutos.

### 📊 Glosario Rápido
| Término | Significado |
| :--- | :--- |
| **Delta-transfer** | Solo copia las partes del archivo que han cambiado. |
| **Dry Run** | Simulación. Te dice qué haría el comando sin copiar nada. |
| **Bandwidth Limit** | Límite de velocidad para no saturar la red del VPS. |
| **Trailing Slash (/)** | Una barra al final de la ruta que cambia el comportamiento de copia de carpetas. |

---

## 🎯 Propósito y Alcance

Implementar la **Regla ARQ-006** (Backup Local Externo) y la **Regla ARQ-005** (Comunicación segura entre VPS). El objetivo es que los datos del VPS 2 (CRM y Bases de Datos) se repliquen de forma segura y eficiente hacia el almacenamiento local de Facundo cada madrugada.

---

## 📐 Fundamentos (De 0 a Intermedio)

Rsync es superior a `scp` o `ftp` porque utiliza el algoritmo de transferencia diferencial. Esto es crítico en Mantis porque:
1.  **Ahorra C2 (CPU)**: Al no procesar archivos que no han cambiado.
2.  **Protege la C1 (RAM)**: Rsync es extremadamente ligero si se configura correctamente.
3.  **Seguridad (C3)**: Todo el tráfico viaja dentro de un túnel SSH encriptado.

---

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

### Gestión de Ancho de Banda (C2 y C3)
Nuestros VPS en Hostinger tienen 4TB de ancho de banda, pero la CPU es de solo 1 núcleo. Un proceso `rsync` con compresión extrema (`-z`) puede saturar la vCPU y hacer que los webhooks de WhatsApp (uazapi) fallen por latencia.

**Reglas de Oro en Mantis:**
- **No comprimir archivos ya comprimidos**: Si el archivo es `.gpg`, `.zip` o `.gz`, no uses `-z` en rsync. Solo desperdiciarás CPU.
- **Limitar ancho de banda**: Usar `--bwlimit=2000` (2MB/s) para asegurar que siempre haya red disponible para n8n.

---

## 🔗 Integración con Stack Existente (n8n, Qdrant, EspoCRM)

- **EspoCRM**: Sincronización de la carpeta `data/upload` del VPS 2 hacia el local.
- **Qdrant**: Sincronización de los snapshots vectoriales.
- **n8n**: Respaldo de los archivos `.json` de workflows de los VPS 1 y 3 hacia el VPS 2 centralizador.

---

## 🛠️ 5 Ejemplos de Implementación (Copy-Paste Validables)

### Ejemplo 1: Sincronización de Backups Cifrados (Hacia Local)
**Objetivo**: El comando que debe correr el PC de Facundo para "traer" los datos.
**Nivel**: 🟢 Fácil
**Comando / Código**:
```bash
# Ejecutar desde el PC Local
rsync -av --progress --bwlimit=5000 \
  -e "ssh -i ~/.ssh/id_rsa_mantis -p 22" \
  mantis_user@vps2_ip:/backups/cifrados/ \
  /home/facundo/backups_mantis/

✅ Deberías ver: Una lista de archivos .gpg siendo descargados.
❌ Si ves: Connection refused, verifica el puerto SSH y el firewall UFW en el VPS 2.
Ejemplo 2: Mirroring de Configuración (Isolación C4)

Objetivo: Mantener carpetas de configuración de tenants sincronizadas.
Nivel: 🟡 Intermedio
Comando / Código:
code Bash

# --delete: Borra archivos en destino que ya no existen en origen (Espejo exacto)
# --exclude: No sincroniza archivos temporales
rsync -avz --delete \
  --exclude "*.tmp" --exclude "cache/" \
  /opt/mantis/config/ \
  vps2_user@vps2_ip:/opt/mantis/config_backup/

Ejemplo 3: Sincronización a través de Puerto No Estándar

Objetivo: Cumplir con Hardening de SSH (Regla SEG-002).
Nivel: 🟢 Fácil
Comando / Código:
code Bash

rsync -arvz -e 'ssh -p 2222' /var/www/espocrm/ user@dest_vps:/var/www/espocrm_mirror/

Ejemplo 4: Script de Sincronización con Logs Estructurados (C4)

Objetivo: Automatización para Crontab con reporte de errores.
Nivel: 🔴 Avanzado
Comando / Código:
code Bash

#!/bin/bash
# mantis-sync-check.sh
SOURCE_DIR="/var/lib/qdrant/snapshots/"
DEST_SERVER="facundo_local_pc"
LOG_FILE="/var/log/mantis/sync.log"
TENANT_ID="CORE_SYSTEM"

echo "[$(date)] Starting sync for $TENANT_ID" >> $LOG_FILE

rsync -av --bwlimit=3000 $SOURCE_DIR $DEST_SERVER:/backups/qdrant/ >> $LOG_FILE 2>&1

if [ $? -eq 0 ]; then
    echo "[$(date)] SUCCESS: Sync completed" >> $LOG_FILE
else
    echo "[$(date)] ERROR: Sync failed" >> $LOG_FILE
    # Aquí podrías llamar al alert-dispatcher-agent
fi

Ejemplo 5: Sincronización de Logs de Auditoría (C4/C10)

Objetivo: Centralizar logs de todos los VPS en el VPS 2 para auditoría.
Nivel: 🟡 Intermedio
Comando / Código:
code Bash

# Ejecutar en VPS 1 y VPS 3
# Sincroniza logs de auth y n8n
nice -n 19 rsync -av --include="auth.log" --include="n8n.log" --exclude="*" \
  /var/log/ \
  vps2_user@vps2_ip:/logs_centralizados/vps_origin_name/

🐞 5 Eventos/Problemas Críticos y Troubleshooting
Error Exacto (copiable)	Causa Raíz	Solución Paso a Paso
rsync: connection unexpectedly closed	El proceso rsync en el remoto murió o el SSH se cortó.	1. Verifica RAM con free -m.<br>2. Intenta sin compresión (-z).<br>3. Aumenta ServerAliveInterval en .ssh/config.
Permission denied (publickey)	No se envió la llave SSH correcta o no está en authorized_keys.	1. Prueba con ssh -i ruta_llave user@ip.<br>2. Copia la llave: ssh-copy-id -i llave user@ip.
rsync: failed to set times on...	Diferencia de sistemas de archivos (ej: NTFS a EXT4).	Usa la flag -t o --no-perms si el destino es un disco externo Windows.
Disk quota exceeded	El VPS de destino se quedó sin espacio (C1).	1. df -h para ver espacio.<br>2. Borra backups viejos o usa rsync con --delete.
rsync: change_dir "/path" failed: No such file	La carpeta de origen no existe o el path está mal escrito.	Revisa si falta o sobra un / al inicio o final de la ruta.
✅ Validación SDD y Comandos de Verificación

    Validar Delta-Transfer:
    Ejecuta el mismo rsync dos veces seguidas. La segunda vez debería decir "sent X bytes, received Y bytes, speed 0.00 bytes/sec" (o muy cerca de 0).

    Validar Hardening (C3):
    ps aux | grep rsync mientras corre. Verifica que el proceso hijo es un túnel SSH.

    Validar Integridad:
    rsync -avc (La flag -c obliga a comparar por Checksum, no por fecha). Úsalo solo para validaciones mensuales ya que consume mucha CPU (C2).

🔗 Referencias Cruzadas y Glosario

    [[02-SKILLS/INFRAESTRUCTURA/ssh-key-management.md]]: Base para que rsync funcione sin intervención humana.

    Archive Mode (-a): Atajo que incluye recursividad, preservación de links, permisos y tiempos. Es la flag recomendada.

    BWLimit: Crítico para no desconectar los bots de WhatsApp por falta de red.

<!-- ai:constraint=C2,C3,C6 -->
<!-- sdd-compliance: 100% -->
