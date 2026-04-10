---
title: "rsync-automation"
category: "Skill"
domain: ["generico", "seguridad", "infraestructura"]
constraints: ["C1", "C2", "C3", "C4", "C5"]
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
  - "02-SKILLS/SEGURIDAD/backup-encryption.md"
---

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

**¿Qué vas a lograr en 5 minutos?**  
Automatizar la copia segura de archivos entre dos VPS de MANTIS AGENTIC utilizando `rsync` sobre SSH, **sin exponer puertos al público** y respetando los límites de hardware (C1/C2). Al terminar, tu servidor de backups recibirá automáticamente las copias cifradas generadas en [[02-SKILLS/SEGURIDAD/backup-encryption.md]].

**Requisitos previos:**
- Dos VPS Ubuntu 22.04/24.04 accesibles por SSH.
- Autenticación por clave SSH configurada (ver [[02-SKILLS/INFRAESTRUCTURA/ssh-key-management.md]]).
- `rsync` instalado (`sudo apt install rsync -y`).

**Pasos relámpago (prueba de conectividad):**
1. **Verifica que el túnel SSH funcione sin contraseña:**
   ```bash
   ssh usuario_destino@IP_VPS_DESTINO "echo 'Conexión exitosa'"
   ```
2. **Transfiere un archivo de prueba con límites de ancho de banda (C2):**
   ```bash
   rsync -avz --bwlimit=1024 /tmp/archivo_prueba.txt usuario_destino@IP_VPS_DESTINO:/ruta/backups/
   ```
3. **Confirma la recepción:**
   ```bash
   ssh usuario_destino@IP_VPS_DESTINO "ls -lh /ruta/backups/archivo_prueba.txt"
   ```

⚠️ **Regla de Seguridad Crítica (C3):** Jamás uses `rsyncd` (modo demonio sin cifrado) a través de internet. **Siempre** encapsula `rsync` dentro de un túnel SSH (`-e ssh`).

## 🎯 Propósito y Alcance

Este documento establece el protocolo estandarizado para la **sincronización remota segura de archivos** dentro del ecosistema MANTIS AGENTIC. Su objetivo es mover datos (backups cifrados, logs de auditoría, snapshots de Qdrant) desde VPS de producción hacia un VPS de almacenamiento aislado, minimizando la ventana de exposición de datos y optimizando el uso de recursos escasos.

**Alcance específico:**
- Transferencia programada (cron/systemd timers) de backups generados por n8n.
- Sincronización de logs de auditoría con `tenant_id` (C4).
- Integración con scripts post-encriptación de [[02-SKILLS/SEGURIDAD/backup-encryption.md]].
- **Exclusiones:** No cubre la sincronización bidireccional en tiempo real (para eso usar `lsyncd` o `unison`). Tampoco la configuración de VPN (WireGuard) aunque se menciona como alternativa superior.

## 📐 Fundamentos (De 0 a Intermedio)

### 1. ¿Qué es `rsync` y por qué es superior a `scp`?
`rsync` (Remote Sync) es una herramienta que **compara** los archivos de origen y destino y transfiere **solo las diferencias** (delta encoding). En un entorno donde se generan backups diarios de bases de datos de varios GB, pero solo cambian unos pocos MB por día, `rsync` ahorra hasta un **90% de ancho de banda y tiempo de CPU**.

**Analogía docente:** Imagina que tienes un manuscrito de 500 páginas y solo cambias una coma en la página 200. `scp` (Secure Copy) enviaría el libro entero otra vez por mensajería. `rsync` envía solo una nota adhesiva diciendo "Página 200, coma añadida". El destinatario aplica el cambio a su copia local.

### 2. La Santísima Trinidad de la Seguridad en Tránsito (C3)
- **Confidencialidad:** SSH cifra el canal.
- **Integridad:** SSH verifica que los paquetes no se alteren (HMAC).
- **Autenticación:** Claves SSH (no contraseñas) aseguran que solo MANTIS puede enviar los datos.

### 3. El Cuello de Botella en VPS (C1/C2)
`rsync` puede ser voraz. Si no se limita, consumirá todo el ancho de banda de red del VPS, afectando a n8n, EspoCRM o la API en producción.
- **Parámetro crítico:** `--bwlimit=RATE` (en KBytes/s). Para un VPS con 2 vCPU y 4GB RAM, un límite de **1024 KB/s (1MB/s)** es razonable para no saturar la interfaz de red virtualizada.
- **Parámetro crítico:** `nice -n 19` e `ionice -c 3` para el proceso `rsync` en el origen, reduciendo la prioridad de acceso al disco.

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

<!-- ai:constraint=C1,C2 -->

| Componente | Limitación en VPS Pequeño | Configuración `rsync` Aplicada |
| :--- | :--- | :--- |
| **Red (NIC Virtual)** | Máximo realista 100-200 Mbps. | `--bwlimit=1024` (1 MB/s = 8 Mbps) para compartir el canal con la app. |
| **CPU (Cálculo de Checksums)** | Hasta 1 vCPU (C2). | `--whole-file` (evita cálculo de delta para archivos pequeños, ahorra CPU). O usar `rsync -c` solo cuando sea necesario (verificación de integridad posterior). |
| **RAM (Buffer de Comparación)** | Impacto bajo (10-50MB), pero crítico con millones de archivos. | Evitar `-H` (preservar hard links) en backups comprimidos individuales. |
| **Disco I/O** | Operaciones de lectura secuencial pesadas. | `ionice -c 3` + `nice -n 19` para no interferir con Qdrant/PostgreSQL. |

**Comando de Verificación de Carga de Red (antes de ejecutar):**
```bash
iftop -i eth0 -t -s 5
# Si la media de tráfico saliente supera los 5 Mbps, reduce --bwlimit a 512.
```

## 🔗 Integración con Stack Existente (n8n, Qdrant, EspoCRM)

`rsync` es el último eslabón de la cadena de resiliencia de datos de MANTIS.

1.  **n8n (Nodo Execute Command):**
    - El workflow de backup nocturno (3:00 AM UTC-3) ejecuta `pg_dump`.
    - Ejecuta el cifrado ([[02-SKILLS/SEGURIDAD/backup-encryption.md]]).
    - Ejecuta **este skill** con `rsync` para enviar el `.gpg` al "VPS Almacén".

2.  **Qdrant (Consistencia de Snapshots):**
    - **Advertencia:** No se debe hacer `rsync` de los archivos de segmento de Qdrant mientras el servicio está escribiendo.
    - **Procedimiento MANTIS:**
        1. `curl -X POST "http://localhost:6333/snapshots"` (genera un snapshot consistente).
        2. `rsync` transfiere el snapshot recién generado (formato `.snapshot`).
        3. `rsync` elimina snapshots antiguos del origen para liberar disco.

3.  **EspoCRM (Auditoría Multi-Tenant C4):**
    - Log de acceso: `data/logs/espo-YYYY-MM-DD.log`.
    - **Validación de Trazabilidad:** Antes de `rsync`, el script añade una línea de marca de agua:
      ```bash
      echo "[$(date -Iseconds)] [tenant:${TENANT_ID}] rsync_transfer_initiated" >> /path/to/log
      ```
      Esto asegura que la cadena de custodia cumple con C4.

## 🛠️ 5 Ejemplos de Implementación (Copy-Paste Validables)

### Ejemplo 1: Sincronización Básica de un Directorio de Backups
**Objetivo**: Copiar todos los archivos `.gpg` de un directorio local al VPS de almacenamiento.
**Nivel**: 🟢

```bash
# Origen: /var/backups/mantis/ (local)
# Destino: backup@10.0.0.2:/mnt/nfs_backups/

rsync -avz --delete \
  -e "ssh -i /home/mantis/.ssh/id_ed25519_backup" \
  /var/backups/mantis/ \
  backup@10.0.0.2:/mnt/nfs_backups/

✅ Deberías ver:
sending incremental file list
./
backup_db_20260410.sql.gpg
log_audit_20260410.json.gpg

sent 4.2M bytes  received 68 bytes  2.8M bytes/sec
total size is 12.5M  speedup is 2.97

❌ Si ves esto en su lugar:
rsync: connection unexpectedly closed (0 bytes received so far) [sender]

→ Ve a Troubleshooting #1
```
**Flags explicados:**
- `-a`: Modo archivo (preserva permisos, timestamps).
- `-v`: Verbose (saber qué pasa).
- `-z`: Comprime en tránsito (útil para `.sql`, inútil para `.gpg`).
- `--delete`: Elimina en destino archivos que ya no están en origen (para mantener el espejo limpio).

### Ejemplo 2: Transferencia con Límites de Recursos para Horario Pico (C1/C2)
**Objetivo**: Ejecutar la copia sin degradar la experiencia de usuario de EspoCRM a las 10:00 AM.
**Nivel**: 🟡

```bash
# Ejecuta rsync con:
# - Baja prioridad de CPU (nice -n 19)
# - Baja prioridad de Disco (ionice -c 3)
# - Ancho de banda limitado a 512 KB/s (--bwlimit=512)
# - Archivo de log separado para auditoría C4

nice -n 19 ionice -c 3 rsync -av \
  --bwlimit=512 \
  --log-file=/var/log/mantis/rsync_audit_$(date +%Y%m%d).log \
  /data/backups/ \
  almacen@192.168.1.10:/data/backups_remotos/

# Verificar carga del sistema tras el comando:
uptime
# Asegurarse de que el Load Average no supere el número de cores (2.0).

✅ Deberías ver:
El comando tarda más (quizá el doble), pero el sistema sigue respondiendo bien.

❌ Si ves esto en su lugar:
rsync error: unexplained error (code 255) at io.c(226)

→ Ve a Troubleshooting #2 (Saturación de I/O o red).
```

### Ejemplo 3: Validación de Integridad Post-Transferencia (C5)
**Objetivo**: Asegurar que el archivo `.gpg` en el destino tiene el mismo checksum que el original **sin transferir el archivo de vuelta**.
**Nivel**: 🔴

```bash
ARCHIVO="backup_db.sql.gpg"
DESTINO="backup@10.0.0.2"

# 1. Calcular hash local
HASH_LOCAL=$(sha256sum "/var/backups/$ARCHIVO" | awk '{print $1}')

# 2. Calcular hash remoto via SSH
HASH_REMOTO=$(ssh "$DESTINO" "sha256sum /ruta/backups/$ARCHIVO" | awk '{print $1}')

# 3. Comparar sin exponer el contenido
if [ "$HASH_LOCAL" == "$HASH_REMOTO" ]; then
  echo "✅ Integridad verificada (C5 OK)"
else
  echo "❌ CORRUPCIÓN DETECTADA. Código: $HASH_LOCAL vs $HASH_REMOTO" >&2
  exit 1
fi

✅ Deberías ver:
✅ Integridad verificada (C5 OK)

❌ Si ves esto en su lugar:
❌ CORRUPCIÓN DETECTADA. Código: abc123 vs def456

→ Ve a Troubleshooting #5 (Bit Rot o corte de red).
```

### Ejemplo 4: Sincronización con Rotación Automática de Retención
**Objetivo**: Mantener solo las últimas 7 copias en el VPS Almacén, eliminando las antiguas **después** de una transferencia exitosa.
**Nivel**: 🟡

```bash
# Este script combina rsync con limpieza remota de archivos antiguos.
# Asume que los archivos se llaman backup_YYYYMMDD.sql.gpg

# 1. Transferir los nuevos
rsync -av /backups/ backup@10.0.0.2:/almacen/backups/

# 2. Conexión remota para limpiar (comando find con -mtime)
ssh backup@10.0.0.2 "find /almacen/backups/ -name '*.gpg' -type f -mtime +7 -delete"

# 3. Log de auditoría con tenant_id (C4)
echo "[$(date)] [tenant:mantis] Limpieza de backups >7 días ejecutada" >> /var/log/mantis/rsync_audit.log

✅ Deberías ver:
Salida normal de rsync seguida de silencio (find -delete no produce salida por defecto).

❌ Si ves esto en su lugar:
find: cannot delete `/almacen/backups/backup_old.gpg`: Permission denied

→ El usuario backup no tiene permisos de escritura en el destino. Verificar propiedad.
```

### Ejemplo 5: Exclusión de Archivos Temporales y Cachés de n8n
**Objetivo**: Evitar enviar miles de archivos pequeños de caché o sesiones temporales que degradan el rendimiento de `rsync`.
**Nivel**: 🟢

```bash
# Crear archivo .rsync-filter en el directorio origen
cat > /home/mantis/.rsync-filter-n8n << EOF
# Excluir carpetas de caché de n8n (cientos de miles de archivos)
- .n8n/cache/
- .n8n/binaryData/temp/
# Excluir logs viejos comprimidos (ya se enviaron)
- *.log.1.gz
- *.log.2.gz
EOF

# Ejecutar con filtro
rsync -avz --filter='. /home/mantis/.rsync-filter-n8n' \
  /home/mantis/ \
  backup@10.0.0.2:/home/mantis_backup/

✅ Deberías ver:
En la lista de archivos enviados no aparecen las carpetas cache/ ni temp/.

❌ Si ves esto en su lugar:
rsync sigue enviando archivos .log.1.gz

→ Revisa que el archivo de filtro no tenga espacios incorrectos. El formato es: "- /patron".
```

## 🐞 5 Eventos/Problemas Críticos y Troubleshooting

| Error Exacto (copiable) | Causa Raíz (lenguaje simple) | Comando de Diagnóstico | Solución Paso a Paso | Constraint Afectado (C#) |
| :--- | :--- | :--- | :--- | :--- |
| `rsync: connection unexpectedly closed (0 bytes received so far) [sender]` | El servidor destino rechazó la conexión SSH (puerto 22 cerrado, firewall, o clave incorrecta). | `ssh -v usuario@IP` (modo verbose). | 1. Verificar que el puerto 22 está abierto en el VPS destino. 2. Revisar `ufw status` en destino. 3. Comprobar que la clave pública está en `~/.ssh/authorized_keys` del destino. | C3 (Canal seguro roto) |
| `rsync error: error in rsync protocol data stream (code 12) at io.c(226)` | `rsync` se quedó sin memoria o fue interrumpido por una desconexión de red debido a una transferencia muy larga sin timeout. | `dmesg | tail -20` (buscar "Out of memory"). | 1. **Mitigación inmediata:** Usar `--partial --append-verify` para reanudar transferencias fallidas sin empezar de cero. 2. Dividir la tarea en chunks más pequeños (`find . -type f`). 3. Aumentar `ClientAliveInterval` en `/etc/ssh/sshd_config` del destino. | C1 / C2 (Agotamiento de recursos) |
| `rsync: mkstemp "/ruta/destino/.backup.sql.gpg.XXXXXX" failed: Permission denied (13)` | El usuario SSH en el destino **no tiene permisos de escritura** en la carpeta de destino. | `ssh usuario@IP "ls -ld /ruta/destino"`. | 1. Verificar que el usuario destino (ej. `backup`) sea el propietario: `sudo chown backup:backup /ruta/destino`. 2. Asignar permisos 755/750 según corresponda. | C3 / C5 (Fallo en escritura remota) |
| `rsync: read errors mapping "/ruta/origen/archivo": No such file or directory (2)` | El archivo fue **borrado o movido** mientras `rsync` escaneaba el directorio. Esto pasa en directorios muy activos como `/tmp` de n8n. | `lsof /ruta/origen/archivo` (comprobar si está abierto). | 1. Usar `--ignore-missing-args` para que `rsync` ignore el error y continúe. 2. **Mejor práctica:** Generar un backup estático (volcado SQL) y `rsync` ESE archivo estático, no el directorio de datos vivos. | C5 (Integridad de la operación) |
| `rsync: [generator] failed to set times on "/ruta/destino": Operation not permitted (1)` | El usuario remoto no puede cambiar el timestamp del archivo. Frecuente en sistemas de archivos NFS o en contenedores sin CAP_FOWNER. | `ssh usuario@IP "touch /ruta/destino/test && rm /ruta/destino/test"`. | 1. Si el error es **solo de timestamps**, la copia de datos fue correcta. 2. Se puede suprimir el error con `--no-t`. 3. **Auditoría C4:** Aunque los timestamps no se copien, el contenido (checksum) sí. La auditoría se basa en el hash del archivo. | C4 (Metadatos vs Contenido) |

## ✅ Validación SDD y Comandos de Verificación

<!-- ai:constraint=C5 -->

Estas comprobaciones garantizan que la automatización `rsync` de MANTIS cumple con el Specification-Driven Development.

### 1. Verificación de Canal Seguro (C3)
Asegura que la conexión utiliza **exclusivamente SSH** y que el banner del servidor no está alterado.
```bash
# Ejecutar desde el VPS de ORIGEN
ssh -v -o BatchMode=yes usuario_destino@IP "exit" 2>&1 | grep "Authentications that can continue"
# Salida esperada: "publickey" (si está bien configurado).

# Comprobar que rsync no usa el puerto 873 (rsyncd inseguro)
netstat -tulpn | grep 873
# Salida esperada: VACÍO. Si hay algo, detener el servicio.
```

### 2. Verificación de Límite de Ancho de Banda (C1/C2)
Simula una transferencia y mide el tráfico real.
```bash
# Terminal 1: Inicia la transferencia con límite 512
rsync -av --bwlimit=512 /tmp/test.dat destino:/tmp/

# Terminal 2: Monitorea el tráfico durante la transferencia
iftop -i eth0 -t -s 10 -L 5 2>/dev/null | grep "Cumulative"
# La tasa media debería estar alrededor de 4 Megabits/s (512KB/s * 8).
```

### 3. Verificación de Trazabilidad Multi-Tenant (C4)
Comprueba que los logs de `rsync` contienen la identificación del inquilino.
```bash
# Revisar el log de rsync especificado en el comando
tail -n 5 /var/log/mantis/rsync_audit_$(date +%Y%m%d).log

# Debe aparecer una línea similar a:
# [2026-04-10 03:00:01] [tenant:facundo] Transfer started: backup_*.gpg
# Si el log solo muestra rutas de archivo, INCUMPLE C4. Ajustar script de envoltura.
```

## 🔗 Referencias Cruzadas y Glosario

- **[[02-SKILLS/SEGURIDAD/backup-encryption.md]]**: El paso previo indispensable. Solo se envía el `.gpg` resultante.
- **[[02-SKILLS/INFRAESTRUCTURA/ssh-key-management.md]]**: Configuración detallada de las claves sin passphrase para automatización segura.
- **[[01-RULES/02-RESOURCE-GUARDRAILS.md]]**: Política completa sobre `nice`, `ionice` y `ulimit`.
- **[[00-CONTEXT/facundo-infrastructure.md]]**: Direcciones IP internas y nombres de host de los VPS de almacenamiento.

**Glosario Rápido:**
- **Delta Encoding**: Algoritmo que envía solo las partes modificadas de un archivo.
- **Checksum (SHA256)**: Huella digital del archivo. Útil para verificar que la copia remota es bit a bit idéntica.
- **`ionice -c 3`**: Clase "Idle". El proceso solo accede al disco cuando ningún otro proceso lo está usando.
- **`--bwlimit`**: Limitador de ancho de banda en KBytes por segundo. 1024 = 1MB/s.

FIN DEL ARCHIVO
<!-- ai:file-end marker - do not remove -->
Versión 1.0.0 - 2026-04-10 - Mantis-AgenticDev
