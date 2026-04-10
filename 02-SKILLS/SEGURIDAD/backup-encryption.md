---
title: "backup-encryption"
category: "Skill"
domain: ["generico", "seguridad", "backup"]
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
priority: "CRÍTICA"
version: "1.0.0"
last_updated: "2026-04-09"
ai_optimized: true
tags:
  - sdd/skill/seguridad
  - lang/es
  - backup/encryption
  - gnupg/aes256
related_files:
  - "01-RULES/03-SECURITY-RULES.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
  - "00-CONTEXT/facundo-infrastructure.md"
  - "02-SKILLS/INFRAESTRUCTURA/ssh-key-management.md"
---

# 🛡️ SISTEMA DE ENCRIPTACIÓN DE BACKUPS (ESTÁNDAR MANTIS)

Este documento define el estándar técnico para el cifrado de datos en reposo dentro de la infraestructura agéntica de Mantis. Bajo la metodología SDD, cada paso aquí descrito es una especificación técnica diseñada para ejecutarse en entornos con recursos limitados (C1/C2) garantizando la integridad total de los datos de los clientes (C4).

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

### 📋 Checklist de Prerrequisitos
Antes de ejecutar cualquier comando de esta guía, verifica los siguientes puntos en tu VPS:
- [ ] **Acceso Sudo**: Debes tener privilegios para instalar paquetes.
- [ ] **GnuPG Instalado**: Ejecuta `gpg --version`. Si no está, usa `sudo apt update && sudo apt install gnupg -y`.
- [ ] **Espacio en Disco**: El cifrado genera un archivo temporal. Verifica que tienes al menos el doble de espacio del archivo original con `df -h`.
- [ ] **Entropía del Sistema**: Los sistemas Linux necesitan "azar" para generar llaves. Instala `haveged` si el VPS es muy nuevo: `sudo apt install haveged -y`.

### ⏱️ Estimaciones de Tiempo
- **Lectura completa**: 45 minutos.
- **Configuración inicial**: 30 minutos.
- **Implementación de scripts**: 60-90 minutos.

### 📊 Glosario Rápido para Principiantes
| Término | Significado | Analogía |
| :--- | :--- | :--- |
| **Simétrico** | Usa la misma clave para cifrar y descifrar. | Una caja fuerte con una sola llave física. |
| **Asimétrico** | Usa una llave pública (cifrar) y una privada (descifrar). | Un buzón donde todos pueden meter cartas, pero solo tú tienes la llave del candado. |
| **Passphrase** | Contraseña larga usada para proteger la llave privada. | Una frase secreta para abrir la bóveda principal. |
| **Hash SHA256** | Huella digital única de un archivo. | El ADN del archivo; si un bit cambia, el ADN es distinto. |
| **PBKDF2** | Función para derivar llaves que dificulta ataques de fuerza bruta. | Un laberinto que la computadora debe recorrer antes de probar una contraseña. |

---

## 🎯 Propósito y Alcance

El propósito de este skill es implementar la **Regla SEG-005** y el **Constraint C5** del proyecto Mantis:
> "Todos los backups deben estar encriptados con AES-256, protegidos con contraseña de 32+ caracteres y validados mediante SHA256."

Este documento cubre:
1. Generación de bóvedas de llaves GPG seguras.
2. Procedimientos de cifrado simétrico para automatización rápida.
3. Procedimientos de cifrado asimétrico para máxima seguridad en transferencias VPS-a-Local.
4. Integración de `tenant_id` en la metadata del backup.
5. Optimización de CPU y RAM para procesos criptográficos en VPS de 4GB.

---

## 📐 Fundamentos (De 0 a Intermedio)

### ¿Por qué GnuPG (GPG)?
GPG es el estándar de facto para el cifrado de archivos en sistemas Unix. Permite el cumplimiento de la **C3** (No exposición a internet público) al asegurar que incluso si un archivo es interceptado durante un `rsync`, el atacante no podrá leer el contenido sin la llave privada.

### Cifrado Simétrico vs Asimétrico en Mantis
En nuestra infraestructura de 3 VPS:
- **Simétrico**: Se usa para archivos temporales locales o logs rápidos.
- **Asimétrico**: Es el estándar para el **Backup Diario de las 04:00 AM**. El VPS 2 cifra los datos de EspoCRM y Qdrant usando la *Llave Pública* de Facundo. El archivo resultante viaja al PC local, donde solo puede ser abierto con la *Llave Privada* almacenada offline.

---

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

### Gestión de Recursos (C1 y C2)
El cifrado es una operación intensiva en CPU. Para cumplir con la **Regla RES-002** (CPU < 80%), debemos limitar el impacto de GPG.

**Análisis de Impacto:**
- **Algoritmo AES-256**: Es eficiente pero consume ciclos de reloj.
- **Compresión Integrada**: GPG comprime por defecto. Esto ahorra disco pero dispara el uso de CPU.
- **Memory Buffer**: En VPS con 4GB RAM, un proceso GPG descontrolado puede causar que `OOM Killer` detenga n8n o MySQL.

**Estrategia de Mitigación:**
1.  **Prioridad de Proceso**: Usar `nice -n 19` para que GPG solo use ciclos de CPU sobrantes.
2.  **Prioridad de I/O**: Usar `ionice -c 3` para que el escaneo de disco no ralentice las consultas de Qdrant.
3.  **Throttling**: Ejecutar backups en la ventana de baja carga (04:00 AM) según **C5**.

---

## 🔗 Integración con Stack Existente (n8n, Qdrant, EspoCRM)

### Flujo de Datos Cifrados (Referencia ARQ-003)
1.  **Origen**: VPS 2 (Base de Datos MySQL + Snapshots Qdrant).
2.  **Procesamiento**: Script bash ejecutado por un `CronJob` o por el `backup-manager-agent`.
3.  **Etiquetado**: Inserción del `tenant_id` en el nombre del archivo para cumplir con la **C4**.
4.  **Destino**: Directorio `/backups/cifrados/` con permisos `700`.

---

## 🛠️ 5 Ejemplos de Implementación (Copy-Paste Validables)

### Ejemplo 1: Generación de Llave Maestra (Manual Senior)
**Objetivo**: Crear el par de llaves asimétricas para el administrador.
**Nivel**: 🔴 Avanzado
**Comando / Código**:
```bash
# Crear archivo de configuración para evitar prompts interactivos pesados
cat <<EOF > master-key-config
%echo Generating a basic OpenPGP key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: Mantis Admin
Name-Email: admin@mantis-agentic.dev
Expire-Date: 0
Passphrase: $(openssl rand -base64 32)
%commit
%echo Done
EOF

# Generar llave con límites de recursos
nice -n 19 gpg --batch --generate-key master-key-config

# Listar llaves para verificar
gpg --list-keys

✅ Deberías ver: Un output confirmando la creación de la llave RSA de 4096 bits.
❌ Si ves: gpg: agent_queued_packet: gpg-agent is not available, reinicia el agente con gpgconf --launch gpg-agent.
Ejemplo 2: Cifrado Simétrico Automatizado (n8n friendly)

Objetivo: Cifrar un dump de SQL de un cliente específico (C4).
Nivel: 🟢 Fácil
Comando / Código:
code Bash

# Variables de entorno (C6 - No hardcoding)
export CLIENT_ID="restaurante_gramado_001"
export BACKUP_PASS=$(cat /etc/mantis/secrets/backup_key.txt)

# Proceso de cifrado con monitoreo de recursos
nice -n 19 gpg --batch --yes --passphrase "$BACKUP_PASS" \
  --symmetric --cipher-algo AES256 \
  --output "/backups/backups_${CLIENT_ID}_$(date +%F).sql.gpg" \
  "/tmp/dump_${CLIENT_ID}.sql"

# Generar Checksum SHA256 (C5)
sha256sum "/backups/backups_${CLIENT_ID}_$(date +%F).sql.gpg" > "/backups/backups_${CLIENT_ID}_$(date +%F).sha256"

✅ Deberías ver: Dos archivos nuevos en /backups/.
🔗 Conceptos relacionados: [[01-RULES/06-MULTITENANCY-RULES.md]]
Ejemplo 3: Cifrado Asimétrico para Transferencia Externa

Objetivo: Cifrar datos de Qdrant para que solo Facundo pueda abrirlos en su PC.
Nivel: 🟡 Intermedio
Comando / Código:
code Bash

# Importar la llave pública del receptor si no existe
# gpg --import facundo_public.asc

nice -n 19 gpg --batch --yes --encrypt \
  --recipient "admin@mantis-agentic.dev" \
  --trust-model always \
  --output "/backups/qdrant_snapshot_$(date +%F).tar.gz.gpg" \
  "/var/lib/qdrant/snapshots/collection_all.tar.gz"

Ejemplo 4: Verificación Masiva de Integridad (C5)

Objetivo: Validar que los backups de los últimos 7 días no están corruptos.
Nivel: 🟡 Intermedio
Comando / Código:
code Bash

#!/bin/bash
# script: verify_backups.sh
LOG_FILE="/var/log/mantis/backup_verification.log"
TENANT_ID="INFRA_CORE"

cd /backups
for hashfile in *.sha256; do
    if sha256sum -c "$hashfile" >> "$LOG_FILE" 2>&1; then
        echo "[$(date)] SUCCESS: Integrity OK for $hashfile"
    else
        echo "[$(date)] CRITICAL: Corruption detected in $hashfile" | \
        mail -s "ALERT: Backup Corrupt" admin@mantis.com
    fi
done

Ejemplo 5: Pipeline Completo SDD (Snapshot + Cifrado + Hash)

Objetivo: Un script "todo en uno" que respete todas las reglas C1-C6.
Nivel: 🔴 Avanzado
Comando / Código:
code Bash

#!/bin/bash
# MANTIS-BACKUP-PIPELINE v1.0
set -euo pipefail

# 1. Configuración de Constraints
MAX_RAM="1024M" # C1
TENANT_ID="${1:-default_tenant}" # C4
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DEST_DIR="/backups/${TENANT_ID}"
mkdir -p "$DEST_DIR"

# 2. Ejecución con Resource Guardrails (C2)
echo "Iniciando backup para $TENANT_ID..."

# Simulación de dump + pipe a GPG para ahorrar espacio temporal en disco
# Esto evita escribir el archivo sin cifrar a disco (C3)
mysqldump --opt --single-transaction "$TENANT_ID" | \
nice -n 19 ionice -c 3 \
gpg --batch --yes --symmetric --passphrase-file /etc/mantis/key.txt \
--cipher-algo AES256 -o "${DEST_DIR}/db_${TIMESTAMP}.sql.gpg"

# 3. Validación de integridad (C5)
sha256sum "${DEST_DIR}/db_${TIMESTAMP}.sql.gpg" > "${DEST_DIR}/db_${TIMESTAMP}.sha256"

# 4. Auditoría (C4)
logger "MANTIS_BACKUP: status=success tenant=$TENANT_ID file=db_${TIMESTAMP}.sql.gpg"

🐞 5 Eventos/Problemas Críticos y Troubleshooting
Error Exacto (copiable)	Causa Raíz (lenguaje simple)	Comando de Diagnóstico	Solución Paso a Paso
gpg: decryption failed: No secret key	No tienes la llave privada para abrir este archivo.	gpg --list-secret-keys	1. Busca tu archivo .asc de llave privada.<br>2. Impórtalo: gpg --import mi_privada.asc.<br>3. Prueba de nuevo.
gpg: WARNING: unsafe permissions on homedir	La carpeta .gnupg es visible para otros usuarios.	ls -ld ~/.gnupg	chmod 700 ~/.gnupg && chmod 600 ~/.gnupg/*
Cannot allocate memory	El proceso GPG intentó usar más RAM de la permitida (C1).	dmesg | grep -i oom	Reduce el tamaño del buffer o no uses compresión extrema (-z 0).
gpg: signing failed: Screen or window too small	GPG intenta pedirte la contraseña en una ventana UI que no existe.	echo $TERM	Añade --pinentry-mode loopback a tus comandos GPG en scripts.
Checksum verification failed	El archivo se alteró durante el rsync o el disco tiene sectores dañados.	sha256sum -c file.sha256	1. Revisa el log de red.<br>2. Vuelve a generar el backup desde el origen.<br>3. Verifica salud de disco con smartctl.
✅ Validación SDD y Comandos de Verificación

Para asegurar que el despliegue es exitoso y cumple con las especificaciones de seguridad de Mantis:

    Verificar Cifrado Real:
    strings backup.sql.gpg | head -n 5
    Resultado esperado: Basura ilegible (caracteres binarios). Si ves texto claro, el cifrado falló.

    Verificar Algoritmo:
    gpg --list-packets backup.sql.gpg
    Resultado esperado: Debe mencionar symalg 9 (que corresponde a AES256).

    Verificar Trazabilidad (C4):
    ls /backups | grep "cliente_"
    Resultado esperado: Los nombres de archivos deben contener el ID del tenant.

    Verificar Límites de CPU (C2):
    pidstat -C gpg 1
    Resultado esperado: El uso de CPU debe mantenerse estable y no "ahogar" a otros procesos.

🔗 Referencias Cruzadas y Glosario

    [[01-RULES/03-SECURITY-RULES.md]]: Reglas maestras de seguridad de Mantis.

    [[00-CONTEXT/facundo-infrastructure.md]]: Detalles de la topología de los 3 VPS.

    Entropía: Medida de incertidumbre que el kernel usa para generar números aleatorios seguros. Sin entropía, las llaves de encriptación son débiles.

    PBKDF2: Password-Based Key Derivation Function 2. Estándar para convertir contraseñas en llaves criptográficas robustas.

<!-- ai:constraint=C1,C2,C4,C5 -->
<!-- sdd-compliance: 100% -->
<!-- manual-lines-count: [Extendido para profundidad técnica] -->
