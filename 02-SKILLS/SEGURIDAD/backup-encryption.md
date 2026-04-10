---
title: "backup-encryption"
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
  - "02-SKILLS/INFRAESTRUCTURA/ssh-key-management.md"
  - "02-SKILLS/SEGURIDAD/rsync-automation.md"
---

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

**¿Qué vas a lograr en 5 minutos?**  
Proteger una copia de seguridad de la base de datos o archivos de configuración de MANTIS AGENTIC utilizando encriptación simétrica con `gpg` (GNU Privacy Guard). Al finalizar, tendrás un archivo `.gpg` que **solo puede ser descifrado con tu clave secreta**, incluso si un atacante obtiene acceso físico al VPS o al almacenamiento externo.

**Requisitos previos:**  
- Acceso SSH a un VPS Ubuntu 22.04/24.04 con al menos 1GB de RAM libre (C1).  
- Conocimientos básicos de línea de comandos (`cd`, `ls`, `nano`).

**Pasos relámpago (para impacientes):**
1. **Genera una frase de contraseña robusta y guárdala en un gestor de contraseñas.** *Jamás en un post-it digital.*
2. Ejecuta el cifrado simétrico:
   ```bash
   gpg --symmetric --cipher-algo AES256 --batch --passphrase-file <(echo "TU_FRASE_SECRETA") /ruta/backup/backup_db.sql
   ```
3. Verifica que el archivo `.gpg` no sea legible:
   ```bash
   file backup_db.sql.gpg
   # Deberías ver: "GPG symmetrically encrypted data (AES256 cipher)"
   ```
4. **Elimina el original en texto plano** (`shred -u backup_db.sql`).
5. Copia el `.gpg` a un almacenamiento externo usando [[02-SKILLS/SEGURIDAD/rsync-automation.md]].

⚠️ **Regla de Seguridad (C3):** Si este VPS se expone a internet, **nunca almacenes la frase de paso en el mismo servidor**. Usa variables de entorno temporales o un vault externo.

## 🎯 Propósito y Alcance

Este documento define el estándar educativo y operativo para la **encriptación de backups** dentro de la infraestructura de MANTIS AGENTIC. Su propósito es garantizar la **confidencialidad** (C3) y la **integridad** (C5) de los datos almacenados fuera del entorno de producción activo.

**Alcance específico:**
- Encriptación simétrica de volcados de bases de datos (PostgreSQL/MySQL).
- Encriptación de archivos de configuración de n8n, EspoCRM y Qdrant.
- Integración con flujos de automatización `rsync`.
- **Exclusiones:** Este skill **no cubre** la encriptación de discos completos (LUKS) ni la gestión de certificados TLS para tránsito. Eso pertenece a [[02-SKILLS/SEGURIDAD/security-hardening-vps.md]].

## 📐 Fundamentos (De 0 a Intermedio)

### 1. ¿Por qué encriptar backups? (Teoría)
Un backup es una "foto" estática de tus datos. Si esa foto se almacena en texto plano (ej. un archivo `.sql` con `INSERT INTO users VALUES (...)`), cualquier persona con acceso al disco duro, al bucket S3 o al servidor FTP puede leer información sensible de clientes (C3: Tenant Data Isolation).

**Analogía universitaria:** Encriptar un backup es como guardar el examen final de la asignatura en una caja fuerte antes de enviarlo a la copistería. La copistería puede transportar la caja, pero no puede leer el contenido.

### 2. Simétrico vs. Asimétrico (Decisión de diseño)
Para backups automatizados en VPS con recursos limitados (C1: 2vCPU, C2: 75% carga), **utilizaremos exclusivamente cifrado simétrico (AES-256)**.
- **Ventaja:** Menor consumo de CPU (menos de 1 vCPU completa durante la operación). Una clave compartida secreta es suficiente para descifrar en caso de desastre.
- **Desventaja:** Requiere gestión segura de una única "frase de paso" fuera del servidor (C6: Secretos en Vault/.env).

### 3. El costo oculto: Entropía y VPS Pequeños (C1/C2)
El cifrado requiere números aleatorios de alta calidad (entropía). En VPS virtualizados, la entropía puede agotarse, **congelando el proceso de backup por minutos u horas**.
- **Síntoma:** El comando `gpg` se queda colgado al 0% de CPU.
- **Solución MANTIS:** Instalaremos y configuraremos `haveged` (generador de entropía por software) o usaremos `rng-tools` con precaución.

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

<!-- ai:constraint=C1,C2 -->

| Componente | Límite Estricto (C1/C2) | Técnica de Mitigación en MANTIS |
| :--- | :--- | :--- |
| **CPU** | Máximo **1 vCPU (100%)** durante la encriptación. | Usar `nice -n 19` y `ionice -c 3`. Evitar `gpg` con múltiples hilos (`--no-use-agent`). |
| **RAM** | Máximo **512MB** para buffer de cifrado. | Procesar archivos por streaming (`--compress-algo none` si es posible) o dividir backups grandes (`split`). |
| **I/O Disco** | Prioridad baja para no afectar a n8n/EspoCRM. | `ionice -c 3` (Idle class). **Nunca** encriptar en el mismo disco del sistema operativo si está al 80% de uso. |
| **Entropía** | Bloqueo por falta de aleatoriedad. | Servicio `haveged` en ejecución (`systemctl enable --now haveged`). |

**Comando de verificación de recursos antes de ejecutar:**
```bash
free -h && uptime
# Si el load average > 2.0 y la RAM libre < 1GB, pospón la tarea.
```

## 🔗 Integración con Stack Existente (n8n, Qdrant, EspoCRM)

La encriptación no vive aislada. Se integra en el flujo nocturno de mantenimiento.

1.  **n8n (Workflow de Backup):**
    - Un nodo `Execute Command` ejecuta el script de volcado de PostgreSQL (`pg_dump`).
    - Un segundo nodo `Execute Command` invoca **este skill** para cifrar el archivo `.sql`.
    - Un tercer nodo llama a [[02-SKILLS/SEGURIDAD/rsync-automation.md]] para enviar el `.gpg` al VPS remoto de almacenamiento.

2.  **Qdrant (Snapshots de Vectores):**
    - Qdrant permite crear snapshots internamente. Estos snapshots son **binarios pero no cifrados por defecto**.
    - **Acción:** Tras crear el snapshot en `/qdrant/snapshots`, este skill cifra el archivo `.snapshot` resultante **antes** de que salga del servidor.

3.  **EspoCRM (Configuración de Entidad):**
    - El archivo `custom/Espo/Custom/Resources/metadata/entityDefs/` contiene lógica de negocio crítica.
    - **Validación (C5):** Antes de cifrar, se genera un checksum:
      ```bash
      sha256sum /var/www/espocrm/data/config.php > config.sha256
      gpg --symmetric config.sha256 config.php
      ```

## 🛠️ 5 Ejemplos de Implementación (Copy-Paste Validables)

### Ejemplo 1: Cifrado Simétrico Básico de un Volcado SQL
**Objetivo**: Proteger un archivo `backup.sql` con contraseña temporal.
**Nivel**: 🟢

```bash
# 1. Crear un archivo de prueba (simula pg_dump)
echo "CREATE TABLE usuarios (id INT, nombre TEXT);" > backup_test.sql

# 2. Cifrar con AES256 (Preguntará interactivamente por la contraseña)
gpg --symmetric --cipher-algo AES256 backup_test.sql

# 3. Verificar que el original sigue intacto y el .gpg existe
ls -lh backup_test.sql*

✅ Deberías ver:
-rw-rw-r-- 1 user user  50 Apr 10 10:00 backup_test.sql
-rw-rw-r-- 1 user user 200 Apr 10 10:00 backup_test.sql.gpg

❌ Si ves esto en su lugar:
gpg: problem with the agent: Permission denied

→ Ve a Troubleshooting #3
```
🔗 Conceptos relacionados: [[02-SKILLS/SEGURIDAD/rsync-automation.md]]

### Ejemplo 2: Cifrado No Interactivo para Scripts de n8n (AUTOMATIZADO)
**Objetivo**: Cifrar un archivo sin intervención humana usando una variable de entorno.
**Nivel**: 🟡

```bash
# ¡IMPORTANTE! La variable solo vive en esta sesión del script.
export MANTIS_BACKUP_PASSPHRASE="ClaveSuperSeguraGeneradaConKeepassXC"

# Cifrado por lotes usando la variable de entorno (seguro, no aparece en 'ps aux')
gpg --batch --passphrase-fd 0 --symmetric --cipher-algo AES256 archivo_a_cifrar.tar.gz <<< "$MANTIS_BACKUP_PASSPHRASE"

# Limpiar la variable inmediatamente
unset MANTIS_BACKUP_PASSPHRASE

✅ Deberías ver:
gpg: AES256 encrypted data
gpg: writing to 'archivo_a_cifrar.tar.gz.gpg'

❌ Si ves esto en su lugar:
gpg: cannot open '/dev/tty': No such device or address

→ Ve a Troubleshooting #1
```
⚠️ **REGLA DE ORO (C6):** Nunca escribas la frase en texto plano dentro de un archivo `.sh` permanente. Cárgala desde `/etc/environment` restringido (root:root 600) o, idealmente, desde un secreto de n8n.

### Ejemplo 3: Verificación de Integridad Post-Cifrado (Validación C5)
**Objetivo**: Asegurar que el archivo cifrado no está corrupto antes de borrar el original.
**Nivel**: 🟡

```bash
ARCHIVO="datos_clientes.csv"
PASSPHRASE="MiClave"

# Ciframos
gpg --batch --passphrase-fd 0 --symmetric "$ARCHIVO" <<< "$PASSPHRASE"

# VERIFICACIÓN SILENCIOSA (Descifra en memoria y calcula hash, NO escribe disco)
gpg --batch --passphrase-fd 0 --decrypt "$ARCHIVO.gpg" 2>/dev/null <<< "$PASSPHRASE" | sha256sum > /tmp/decrypted.sha256

# Comparar con el hash original
sha256sum "$ARCHIVO" | diff -s - /tmp/decrypted.sha256

✅ Deberías ver:
Files - and /tmp/decrypted.sha256 are identical

❌ Si ves esto en su lugar:
Files - and /tmp/decrypted.sha256 differ

→ ¡No borres el original! El archivo .gpg está corrupto. Ve a Troubleshooting #4.
```

### Ejemplo 4: Manejo de Archivos Grandes (>2GB) en VPS con Poca RAM (C1/C2)
**Objetivo**: Cifrar un backup de base de datos de 4GB en un VPS de 2GB RAM sin colapsar.
**Nivel**: 🔴

```bash
# NO HACER ESTO: gpg --symmetric archivo_grande.sql
# Resultado: OOM Killer mata el proceso o el sistema se cuelga por swapping.

# 1. Comprimir con prioridad baja antes de cifrar (divide la carga)
nice -n 19 ionice -c 3 pigz -9 archivo_grande.sql

# 2. Dividir en chunks de 512MB (Máximo manejable por RAM/CPU según C1)
split -b 512M archivo_grande.sql.gz archivo_grande_part_

# 3. Cifrar cada parte con restricción de CPU (C2: 1 vCPU máxima)
for PART in archivo_grande_part_*; do
  nice -n 19 taskset -c 0 gpg --batch --passphrase-file <(echo "$PASS") --symmetric "$PART"
  rm "$PART" # Borrar fragmento en texto plano
done

# 4. Para reconstruir:
# cat archivo_grande_part_*.gpg > archivo_grande_unido.gpg
# (Luego descifrar el unificado)

✅ Deberías ver:
gpg: AES256 encrypted data (para cada parte)

❌ Si ves esto en su lugar:
gpg: can't open 'archivo_grande_part_aa': No such file or directory

→ Asegúrate de que el disco no esté lleno (df -h).
```
🔗 Conceptos relacionados: [[01-RULES/02-RESOURCE-GUARDRAILS.md]]

### Ejemplo 5: Descifrado de Emergencia en un Entorno Limpio
**Objetivo**: Recuperar los datos del backup cifrado en un nuevo VPS.
**Nivel**: 🟢

```bash
# 1. Instalar gpg (viene por defecto en Ubuntu)
sudo apt update && sudo apt install gpg -y

# 2. Traer el archivo .gpg (por SCP/SSH Túnel)
scp usuario@vps_produccion:/ruta/backup.sql.gpg .

# 3. Descifrar (preguntará interactivamente por la frase secreta)
gpg --output datos_recuperados.sql --decrypt backup.sql.gpg

# 4. Verificar contenido
head -n 5 datos_recuperados.sql

✅ Deberías ver:
gpg: AES256 encrypted data
gpg: encrypted with 1 passphrase

Y el contenido SQL aparecerá.

❌ Si ves esto en su lugar:
gpg: decryption failed: Bad session key

→ La frase de paso es incorrecta o el archivo fue alterado. Ve a Troubleshooting #5.
```

## 🐞 5 Eventos/Problemas Críticos y Troubleshooting

| Error Exacto (copiable) | Causa Raíz (lenguaje simple) | Comando de Diagnóstico | Solución Paso a Paso | Constraint Afectado (C#) |
| :--- | :--- | :--- | :--- | :--- |
| `gpg: problem with the agent: Permission denied` | El directorio `~/.gnupg` tiene permisos incorrectos o GPG intenta usar `pinentry` gráfico sin `$DISPLAY`. | `ls -ld ~/.gnupg` | 1. `chmod 700 ~/.gnupg`. 2. Usar siempre `--batch --passphrase-fd 0` en scripts para evitar el agente gráfico. | C2 (Bloqueo de automatización) |
| `gpg: can't connect to the agent: IPC connect call failed` | Falta el paquete `pinentry-curses` o el agente GPG no se ha iniciado correctamente en sesiones cron. | `systemctl --user status gpg-agent` | 1. Instalar: `sudo apt install pinentry-curses`. 2. En scripts cron, añadir `export GPG_TTY=$(tty)`. Mejor aún, usa el método de variable de entorno `--passphrase-fd` del Ejemplo 2. | C3 (Fallback inseguro) |
| `gpg: cannot open '/dev/tty': No such device or address` | Se ejecutó `gpg` sin `--batch` desde un entorno no interactivo (cron, script n8n, systemd). | `tty` (devolverá "not a tty"). | **Solución definitiva:** Usar **siempre** el flag `--batch` junto con `--passphrase-fd 0` o `--passphrase-file`. **Nunca** llamar a `gpg` sin `--batch` en un workflow automático. | C6 (Exposición de prompt) |
| `gpg: decrypt_message failed: Wrong key or checksum error` | El archivo `.gpg` se truncó durante una transferencia `rsync` fallida o el disco duro tiene sectores defectuosos (bit rot). | `gpg --list-packets archivo.gpg \| head` (Si muestra datos rotos, es corrupción). | 1. Verificar checksum SHA256 del archivo original vs el transferido. 2. Restaurar desde una copia de seguridad más antigua del archivo `.gpg`. **Prevención:** Siempre validar con `--decrypt` en modo prueba (Ejemplo 3) antes de borrar el original. | C5 (Integridad de Backup) |
| `gpg: decryption failed: Bad session key` | **La frase de paso es incorrecta.** O el algoritmo fue cambiado (poco probable). | Intenta con `gpg --verbose --decrypt archivo.gpg`. | 1. **No hay solución técnica** para recuperar los datos sin la frase exacta. 2. Verificar que el layout del teclado no haya cambiado al escribir caracteres especiales (ñ, ¿). 3. **Lección MANTIS:** La frase debe almacenarse en un gestor de secretos externo (Bitwarden/Vault). **Nunca** dependas solo de la memoria humana. | C3 / C6 (Pérdida de Confidencialidad) |

## ✅ Validación SDD y Comandos de Verificación

<!-- ai:constraint=C5 -->

Para asegurar que la implementación cumple con las políticas de MANTIS, ejecuta estos comandos de auditoría después de implementar el script de backup.

### 1. Verificación de Encriptación Real (C3)
Confirma que el contenido no contiene cadenas de texto plano identificables (ej. nombres de tablas).
```bash
# Busca la palabra 'CREATE TABLE' dentro del archivo cifrado. NO debería encontrarse.
strings /ruta/backups/backup_db.sql.gpg | grep -i "CREATE TABLE"
# Salida esperada: Ninguna línea (código de retorno 1).
```

### 2. Verificación de Uso de Recursos (C1/C2)
Mide el pico máximo de RAM y CPU usado por `gpg` durante una prueba de estrés.
```bash
# Terminal 1: Simula backup y mide
/usr/bin/time -v gpg --batch --passphrase-file <(echo "test") --symmetric large_file.test

# Busca en la salida:
# "Maximum resident set size (kbytes)" -> Debe ser < 500000 (500MB)
# "Percent of CPU this job got" -> Debe ser < 100% (Si hay otras cargas)
```

### 3. Verificación de Automatización Segura (C6)
Asegura que no hay claves hardcodeadas en el script de backup.
```bash
# Escanea el script de backup en busca de la cadena "gpg --passphrase"
grep -n "passphrase" /opt/mantis/scripts/backup_encrypt.sh

# Si encuentra una línea como:
# gpg --passphrase "MiClave123" ...
# --> VIOLACIÓN DE C6. Debes refactorizar a variable de entorno.
```

## 🔗 Referencias Cruzadas y Glosario

- **[[01-RULES/03-SECURITY-RULES.md]]**: Reglas globales de seguridad, incluyendo rotación de claves.
- **[[02-SKILLS/SEGURIDAD/rsync-automation.md]]**: Complemento indispensable para enviar este `.gpg` a almacenamiento remoto seguro.
- **[[00-CONTEXT/facundo-infrastructure.md]]**: Diagrama de la topología de VPS de Facundo donde residen estos backups.
- **[[01-RULES/02-RESOURCE-GUARDRAILS.md]]**: Detalles sobre `nice`, `ionice` y límites de memoria en VPS pequeños.

**Glosario Rápido:**
- **AES-256**: Estándar de Encriptación Avanzada con clave de 256 bits. Virtualmente irrompible por fuerza bruta con la tecnología actual.
- **Entropía**: "Aleatoriedad" del sistema. Necesaria para generar números impredecibles en el cifrado.
- **Batch Mode (`--batch`)**: Modo de GPG que suprime las interacciones con el usuario (ventanas de contraseña), obligatorio para scripts.
- **OOM Killer**: "Asesino por Falta de Memoria". Proceso del Kernel de Linux que mata aplicaciones cuando la RAM se agota para evitar que el sistema colapse.

FIN DEL ARCHIVO
<!-- ai:file-end marker - do not remove -->
Versión 1.0.0 - 2026-04-10 - Mantis-AgenticDev
