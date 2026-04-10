---
title: "mysql-optimization-4gb-ram"
category: "Skill"
domain: ["generico", "backend", "database"]
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
priority: "Alta"
version: "1.0.0"
last_updated: "2026-04-10"
ai_optimized: true
tags:
  - sdd/skill/mysql
  - sdd/skill/optimization
  - sdd/skill/vps
  - sdd/skill/multi-tenant
  - lang/es
related_files:
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
  - "01-RULES/06-MULTITENANCY-RULES.md"
  - "00-CONTEXT/facundo-infrastructure.md"
  - "02-SKILLS/INFRASTRUCTURA/espocrm-setup.md"
---

## 🎯 Propósito y Alcance

Optimizar MySQL 8.0 para funcionar dentro de los límites estrictos de un VPS con 4GB RAM y 1 vCPU (C1/C2), manteniendo aislamiento multi-tenant (C4) y rendimiento aceptable para cargas de trabajo combinadas: EspoCRM + tablas de mensajes WhatsApp + metadatos RAG.

**Casos de uso cubiertos:**
- Configuración de `my.cnf` para VPS 4GB con múltiples bases de datos tenant
- Estrategia de índices para queries con `tenant_id` obligatorio (C4)
- Particionamiento de tablas de alto volumen (mensajes WhatsApp)
- Análisis y eliminación de slow queries con `EXPLAIN`
- Backup diario automático con checksum SHA256 (C5)
- Monitoreo de uso de RAM/CPU de MySQL desde Docker

**Fuera de alcance:**
- MySQL Cluster o Galera (requiere múltiples VPS)
- Full-Text Search avanzado (usar Qdrant para embeddings)
- Réplica maestro-esclavo (C1/C2 no permiten servidor adicional)

---

## 📐 Fundamentos (Nivel Básico)

### ¿Por Qué MySQL 8.0 en 4GB RAM es un Desafío?

MySQL por defecto asume que tiene toda la RAM del servidor. Si no se configura, en un VPS de 4GB puede consumir hasta 2-3GB dejando sin memoria a n8n, Qdrant, y el OS.

**Problema típico sin optimización:**
```
VPS-2 sin configurar:
├── MySQL (defaults):  2.8GB ← El problema
├── EspoCRM PHP:       512MB
├── Qdrant:            800MB
└── OS:                512MB
TOTAL: 4.6GB → SWAP → VPS lento o caído ❌
```

**Después de optimizar (objetivo C1):**
```
VPS-2 optimizado:
├── MySQL (configurado): 1.0GB ✅
├── EspoCRM PHP:         512MB ✅
├── Qdrant:              1.0GB ✅
├── OS + buffers:        512MB ✅
└── Margen de seguridad: ~512MB ✅
TOTAL: ~3.5GB (dentro de 4GB)
```

### Motor InnoDB: Los 4 Parámetros Críticos

Estos 4 parámetros controlan el 90% del uso de RAM de MySQL:

```
innodb_buffer_pool_size  → El más importante. Cache de datos e índices.
                           Regla: 25-30% de RAM total en VPS compartido.
                           En 4GB VPS → 768MB-1024MB

innodb_log_file_size     → Tamaño de WAL (Write-Ahead Log).
                           Más grande = menos escrituras en disco, más RAM.
                           Valor seguro: 128MB-256MB

max_connections          → Cada conexión consume ~10MB de RAM.
                           50 conexiones = 500MB. Usar pooling.
                           Valor seguro: 50-100

sort_buffer_size         → Por query que necesita ordenar.
                           Riesgo: si hay 50 queries simultáneas = 50×sort_buffer
                           Valor seguro: 2MB (no 8MB default)
```

### Arquitectura de Bases de Datos en el Proyecto

```
MySQL VPS-2 (puerto 3306, solo red interna - C3)
│
├── espocrm_tenant_001      ← EspoCRM de cliente restaurante
├── espocrm_tenant_002      ← EspoCRM de cliente odontología
├── mantis_whatsapp         ← Mensajes WhatsApp multi-tenant
│   ├── mensajes            → tenant_id + telefono + texto
│   ├── interacciones       → tenant_id + respuesta_ia + tokens
│   └── tenants             → Registro maestro de tenants
└── mantis_rag_meta         ← Metadata de chunks RAG
    ├── documents            → tenant_id + source + status
    └── document_chunks     → tenant_id + qdrant_id + texto
```

---

## 🏗️ Arquitectura y Hardware Limitado (VPS 2vCPU/4-8GB)

### Distribución Completa de RAM en VPS-2

```
VPS-2 (4GB RAM, 1 vCPU)
│
├── MySQL 8.0                          → LÍMITE: 1024MB (C1)
│   ├── innodb_buffer_pool_size: 768MB
│   ├── innodb_log_buffer_size:  32MB
│   ├── sort_buffer_size/conexión: 2MB
│   ├── read_buffer_size/conexión: 1MB
│   └── Overhead base MySQL:     ~100MB
│
├── EspoCRM PHP-FPM                    → LÍMITE: 512MB (C1)
│   ├── PHP workers × 256MB
│   └── max 2 workers activos
│
├── Qdrant                             → LÍMITE: 1024MB (C1)
│   └── RAM para índices HNSW
│
├── OS + Red + SSH                     → RESERVADO: 512MB
│
└── Buffer seguridad                   → ~512MB libre
```

### Docker Compose con Límites Estrictos para MySQL

```yaml
# docker-compose.yml (extracto MySQL)
services:
  mysql:
    image: mysql:8.0
    container_name: mantis-mysql
    restart: unless-stopped
    
    # C1: Límites de recursos obligatorios
    deploy:
      resources:
        limits:
          memory: 1024M         # C1: NUNCA superar 1GB
          cpus: "0.8"           # C2: 0.8 vCPU (dejar margen)
        reservations:
          memory: 512M          # Mínimo garantizado
    
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: mantis_whatsapp
      TZ: America/Sao_Paulo
    
    # C3: Solo red interna, nunca expuesto
    ports:
      - "127.0.0.1:3306:3306"  # C3: Solo localhost
    
    volumes:
      - ./my.cnf:/etc/mysql/conf.d/mantis.cnf:ro  # Config optimizada
      - mysql_data:/var/lib/mysql
      - mysql_logs:/var/log/mysql
    
    networks:
      - mantis-backend
    
    # Healthcheck para detectar crashes antes que los servicios dependientes
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
      interval: 15s
      timeout: 5s
      retries: 3
      start_period: 60s
    
    # Configuración vía command (alternativa a my.cnf para parámetros simples)
    command: >
      --default-authentication-plugin=mysql_native_password
      --character-set-server=utf8mb4
      --collation-server=utf8mb4_unicode_ci
      --innodb_buffer_pool_size=768M
      --max_connections=80
      --slow_query_log=ON
      --slow_query_log_file=/var/log/mysql/slow.log
      --long_query_time=2

volumes:
  mysql_data:
    driver: local
  mysql_logs:
    driver: local

networks:
  mantis-backend:
    driver: bridge
```

---

## 🔗 Conexión Local vs Externa (Prisma, Supabase, Qdrant, MySQL)

### Patrones de Conexión por Escenario

```bash
# Escenario 1: n8n en VPS-1 → MySQL en VPS-2 (red privada)
# Variables en .env de n8n (VPS-1)
DB_HOST=10.0.1.2              # IP privada de VPS-2
DB_PORT=3306
DB_USER=mantis_app
DB_PASSWORD=${DB_PASSWORD}
DB_NAME=mantis_whatsapp
DB_SSL=false                  # Red privada = sin SSL necesario

# Escenario 2: EspoCRM en mismo VPS que MySQL
ESPOCRM_DATABASE_HOST=mysql   # Nombre del servicio Docker
ESPOCRM_DATABASE_PORT=3306

# Escenario 3: Acceso de emergencia desde local vía SSH tunnel (C3)
# Primero: ssh -L 3307:localhost:3306 user@vps2
# Luego:
DB_HOST=127.0.0.1
DB_PORT=3307                  # Porta local del tunnel
# ⚠️ C3: NUNCA abrir 3306 directo a internet
```

### Gestión de Usuarios por Tenant (C4)

```sql
-- Crear usuario con acceso solo a su base de datos (C4: aislamiento)
-- Ejecutar como root en MySQL

-- Usuario para EspoCRM de tenant restaurante_001
CREATE USER 'espo_rest001'@'%' IDENTIFIED BY '${ESPO_REST001_PASS}';
GRANT ALL PRIVILEGES ON espocrm_restaurante_001.* TO 'espo_rest001'@'%';

-- Usuario para app n8n (acceso a mensajes propios)
CREATE USER 'mantis_app'@'10.0.1.%' IDENTIFIED BY '${APP_PASS}';
GRANT SELECT, INSERT, UPDATE ON mantis_whatsapp.mensajes TO 'mantis_app'@'10.0.1.%';
GRANT SELECT, INSERT ON mantis_whatsapp.interacciones TO 'mantis_app'@'10.0.1.%';
GRANT SELECT ON mantis_whatsapp.tenants TO 'mantis_app'@'10.0.1.%';

-- ❌ NUNCA dar GRANT ALL a usuario de aplicación
-- ❌ NUNCA usar root desde la aplicación
FLUSH PRIVILEGES;
```

---

## 📘 Guía de Estructura de Tablas (Para principiantes)

### Schema Optimizado para Multi-Tenant en 4GB RAM

Las reglas de diseño de tablas para C1/C4:
1. `tenant_id` SIEMPRE como primera columna en índices compuestos
2. Índices en columnas de filtrado frecuente (después de `tenant_id`)
3. Tipos de dato mínimos (no usar `TEXT` donde `VARCHAR(500)` alcanza)
4. Particionamiento por `tenant_id` para tablas > 1M filas

```sql
-- Tabla principal de mensajes WhatsApp
-- Optimizada para queries filtradas por tenant_id (C4)
CREATE TABLE mensajes (
    id           INT UNSIGNED AUTO_INCREMENT,
    tenant_id    VARCHAR(50)  NOT NULL,               -- C4: OBLIGATORIO
    telefono     VARCHAR(20)  NOT NULL,
    mensaje      TEXT,                                 -- Solo TEXT si > 500 chars
    direccion    ENUM('entrada','salida') NOT NULL,
    estado       ENUM('pendiente','procesado','error') NOT NULL DEFAULT 'pendiente',
    fecha        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    procesado    TINYINT(1)   NOT NULL DEFAULT 0,
    
    PRIMARY KEY (id, tenant_id),                      -- C4: tenant_id en PK compuesta
    
    -- Índice principal: queries por tenant + fecha (más común)
    INDEX idx_tenant_fecha    (tenant_id, fecha DESC),
    
    -- Índice para queries por tenant + teléfono (historial de conversación)
    INDEX idx_tenant_telefono (tenant_id, telefono),
    
    -- Índice para jobs de procesamiento (mensajes pendientes)
    INDEX idx_tenant_estado   (tenant_id, estado, procesado),
    
    -- FK: verificar que tenant existe (integridad referencial C4)
    FOREIGN KEY (tenant_id) REFERENCES tenants(tenant_id)
        ON DELETE RESTRICT    -- No borrar tenant si tiene mensajes
        ON UPDATE CASCADE     -- Propagar cambio de tenant_id
)
-- Opciones de motor optimizadas para 4GB RAM
ENGINE=InnoDB
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci
ROW_FORMAT=DYNAMIC            -- Eficiente para columnas TEXT
COMMENT='Mensajes WhatsApp multi-tenant - C4 enforced';
```

```sql
-- Tabla de interacciones IA (tokens = impacto en billing)
CREATE TABLE interacciones (
    id           INT UNSIGNED    AUTO_INCREMENT PRIMARY KEY,
    tenant_id    VARCHAR(50)     NOT NULL,             -- C4
    mensaje_id   INT UNSIGNED    NOT NULL,
    respuesta_ia TEXT,
    modelo_ia    VARCHAR(100),                         -- C6: siempre API cloud
    tokens_input INT UNSIGNED   DEFAULT 0,
    tokens_output INT UNSIGNED  DEFAULT 0,
    costo_usd    DECIMAL(10, 6) DEFAULT 0,            -- Hasta $0.000001
    duracion_ms  INT UNSIGNED   DEFAULT 0,            -- Para monitoreo C2
    fecha        DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- C4: tenant_id siempre primero en índices
    INDEX idx_tenant_fecha     (tenant_id, fecha DESC),
    INDEX idx_tenant_costo     (tenant_id, costo_usd),  -- Para billing por tenant
    INDEX idx_mensaje          (mensaje_id),
    
    FOREIGN KEY (tenant_id)   REFERENCES tenants(tenant_id),
    FOREIGN KEY (mensaje_id)  REFERENCES mensajes(id) ON DELETE CASCADE
)
ENGINE=InnoDB
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci
COMMENT='Interacciones con IA - C4, C6 enforced';
```

### Diagrama de Relaciones

```
tenants (maestro)
  id: restaurante_001
  nombre: "Restaurante Serra"
  plan: "full"
       │
       ├──1:N──→ mensajes (tenant_id = restaurante_001)
       │              │
       │              └──1:N──→ interacciones (tenant_id = restaurante_001)
       │
       ├──1:N──→ espocrm_restaurante_001.account (BD separada)
       │
       └──1:N──→ qdrant collection: rag_restaurante_001 (Qdrant)
```

### Columnas Críticas y sus Índices

| Columna | Por Qué Indexar | Índice Recomendado | Impacto C1 (RAM) |
|---|---|---|---|
| `tenant_id` | Toda query lo filtra (C4) | INDEX compuesto como primer campo | Bajo (solo VARCHAR) |
| `fecha` | Rangos de tiempo frecuentes | INDEX compuesto con tenant_id | Medio |
| `estado` + `procesado` | Jobs de procesamiento de mensajes | INDEX compuesto con tenant_id | Bajo |
| `telefono` | Historial de conversación | INDEX compuesto con tenant_id | Bajo |
| `costo_usd` | Billing mensual por tenant | INDEX compuesto con tenant_id | Bajo |

---

## 🛠️ 4 Ejemplos Centrales (Copy-Paste, validables)

### Ejemplo 1: Archivo my.cnf Completo para VPS 4GB

```ini
# /etc/mysql/conf.d/mantis.cnf
# Optimizado para VPS 4GB RAM, 1 vCPU, multi-tenant
# C1: Límites de RAM respetados
# C2: CPU limitado
# C4: Configuraciones que soportan aislamiento por tenant_id

[mysqld]
# ─── IDENTIFICACIÓN ───────────────────────────────────────────────
server-id       = 1
pid-file        = /var/run/mysqld/mysqld.pid
socket          = /var/run/mysqld/mysqld.sock
datadir         = /var/lib/mysql
log-error       = /var/log/mysql/error.log

# ─── CHARSET (obligatorio para WhatsApp con emojis) ───────────────
character-set-server  = utf8mb4
collation-server      = utf8mb4_unicode_ci
init_connect          = 'SET NAMES utf8mb4'

# ─── INNODB BUFFER POOL (el parámetro más crítico - C1) ───────────
# Regla: 25% de RAM total en VPS compartido
# 4GB × 25% = 1024MB → Usamos 768MB para dejar margen
innodb_buffer_pool_size     = 768M    # C1: No superar para mantener dentro de 1GB total MySQL

# Instancias del buffer pool (1 por cada 1GB de buffer pool, mínimo 1)
innodb_buffer_pool_instances = 1      # C2: 1 instancia para 1 vCPU

# ─── INNODB I/O OPTIMIZACIÓN ──────────────────────────────────────
innodb_log_file_size        = 128M    # WAL: balance entre rendimiento y RAM
innodb_log_buffer_size      = 16M     # Buffer de log antes de escribir a disco
innodb_flush_method         = O_DIRECT # Evitar doble caché (OS + InnoDB)
innodb_io_capacity          = 200     # IOPs disponibles en NVMe del VPS
innodb_io_capacity_max      = 400
innodb_read_io_threads      = 2       # C2: Limitado por 1 vCPU
innodb_write_io_threads     = 2       # C2: Limitado por 1 vCPU

# Flush en cada commit (durabilidad vs rendimiento)
# 1 = máxima durabilidad (recomendado para producción)
# 2 = puede perder 1 segundo de transacciones en crash
innodb_flush_log_at_trx_commit = 1

# ─── CONEXIONES (crítico para RAM - C1) ───────────────────────────
# Cada conexión consume ~10MB. 80 × 10MB = 800MB (si todas activas)
# En práctica, pocas conexiones activas simultáneamente
max_connections         = 80
max_connect_errors      = 1000

# ─── BUFFERS POR QUERY (se multiplican por conexiones activas) ────
# sort_buffer_size × conexiones_activas = RAM usada en sorts
# 2MB × 20 conexiones activas = 40MB (razonable para C1)
sort_buffer_size        = 2M     # C1: No usar el default 8MB
read_buffer_size        = 1M     # Para sequential scans
read_rnd_buffer_size    = 1M     # Para random reads tras sort
join_buffer_size        = 2M     # Para JOINs sin índice (C1: bajo)
tmp_table_size          = 32M    # Tablas temporales en RAM
max_heap_table_size     = 32M    # Debe coincidir con tmp_table_size

# ─── QUERY CACHE (deshabilitado en MySQL 8+) ──────────────────────
# query_cache_type = 0  # Removido en MySQL 8.0

# ─── SLOW QUERY LOG (obligatorio para diagnóstico) ────────────────
slow_query_log          = ON
slow_query_log_file     = /var/log/mysql/slow.log
long_query_time         = 2      # Logear queries > 2 segundos
log_queries_not_using_indexes = ON  # Detectar queries sin índice

# ─── BINLOG (opcional, útil para C5 backups incrementales) ────────
# Deshabilitado para ahorrar RAM y disco si no se usa replicación
# binlog_format         = ROW
# log_bin               = /var/log/mysql/mysql-bin
# expire_logs_days      = 7

# ─── TABLA DE ESTADO (para monitoreo) ─────────────────────────────
performance_schema              = ON
performance_schema_max_table_instances = 200  # Limitar overhead

# ─── CHARSET DEFAULT ──────────────────────────────────────────────
[mysql]
default-character-set = utf8mb4

[client]
default-character-set = utf8mb4
```

**Validación:**
```bash
# Verificar que MySQL inicia con la configuración
docker exec mantis-mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" \
    -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"

# Output esperado:
# +---------------------------+-----------+
# | Variable_name             | Value     |
# +---------------------------+-----------+
# | innodb_buffer_pool_size   | 805306368 | ← 768MB en bytes
# +---------------------------+-----------+

# Verificar uso actual de RAM del contenedor
docker stats mantis-mysql --no-stream --format "{{.MemUsage}}"
# Output esperado: ~600MiB / 1GiB  ✅ C1 respetado
```

---

### Ejemplo 2: Script de Análisis de Slow Queries

```bash
#!/bin/bash
# analyze-slow-queries.sh
# C4: Analiza queries lentas e identifica aquellas sin tenant_id
# C5: Genera reporte con timestamp para auditoría
set -euo pipefail

MYSQL_ROOT="${MYSQL_ROOT_PASSWORD:-}"
SLOW_LOG="/var/log/mysql/slow.log"
REPORT_FILE="/var/log/mantis/slow-query-report-$(date +%Y%m%d).txt"

echo "═══════════════════════════════════════════" | tee "$REPORT_FILE"
echo "REPORTE SLOW QUERIES - $(date)" | tee -a "$REPORT_FILE"
echo "═══════════════════════════════════════════" | tee -a "$REPORT_FILE"

# Top 10 queries más lentas usando pt-query-digest (Percona Toolkit)
if command -v pt-query-digest &>/dev/null; then
    echo "--- TOP 10 QUERIES MÁS LENTAS ---" | tee -a "$REPORT_FILE"
    pt-query-digest --limit 10 "$SLOW_LOG" 2>/dev/null | tee -a "$REPORT_FILE"
else
    # Alternativa con mysqldumpslow
    echo "--- TOP 10 (mysqldumpslow) ---" | tee -a "$REPORT_FILE"
    mysqldumpslow -s t -t 10 "$SLOW_LOG" 2>/dev/null | tee -a "$REPORT_FILE"
fi

echo "" | tee -a "$REPORT_FILE"

# ⚠️ Detectar queries sin tenant_id (violación C4)
echo "--- QUERIES SIN tenant_id (VIOLACIÓN C4) ---" | tee -a "$REPORT_FILE"
if grep -i "^# Query_time" -A 5 "$SLOW_LOG" 2>/dev/null | grep -i "SELECT\|UPDATE\|DELETE\|INSERT" | grep -iv "tenant_id" | head -20; then
    echo "⚠️ ATENCIÓN: Se encontraron queries sin tenant_id" | tee -a "$REPORT_FILE"
else
    echo "✅ Todas las slow queries tienen tenant_id" | tee -a "$REPORT_FILE"
fi

echo "" | tee -a "$REPORT_FILE"

# Estadísticas de uso de InnoDB en tiempo real
echo "--- ESTADO INNODB BUFFER POOL ---" | tee -a "$REPORT_FILE"
docker exec mantis-mysql mysql -u root -p"${MYSQL_ROOT}" --skip-column-names -e "
SELECT
    CONCAT(ROUND(Innodb_buffer_pool_pages_data * 100 / 
           NULLIF(Innodb_buffer_pool_pages_total, 0), 1), '%') AS 'Buffer Pool Usado',
    CONCAT(ROUND(Innodb_buffer_pool_read_requests_per_sec, 1), '/s') AS 'Reads/s',
    CONCAT(ROUND(Innodb_buffer_pool_write_requests_per_sec, 1), '/s') AS 'Writes/s'
FROM (
    SELECT
        variable_name AS metric,
        CAST(variable_value AS UNSIGNED) AS value
    FROM performance_schema.global_status
    WHERE variable_name IN (
        'Innodb_buffer_pool_pages_data',
        'Innodb_buffer_pool_pages_total',
        'Innodb_buffer_pool_read_requests',
        'Innodb_buffer_pool_write_requests'
    )
) stats LIMIT 1;
" 2>/dev/null | tee -a "$REPORT_FILE" || echo "No se pudo conectar a MySQL" | tee -a "$REPORT_FILE"

echo "✅ Reporte guardado en: $REPORT_FILE"
```

**Validación:**
```bash
chmod +x analyze-slow-queries.sh
./analyze-slow-queries.sh

# Output esperado (si no hay problemas):
# ✅ Todas las slow queries tienen tenant_id
# Buffer Pool Usado: 72.3%  ← Bueno, > 50% = cache efectivo
```

---

### Ejemplo 3: EXPLAIN + Optimización de Query con tenant_id

Este ejemplo muestra el ciclo completo de diagnóstico y optimización de una query lenta.

```sql
-- ─── PASO 1: QUERY LENTA ORIGINAL ────────────────────────────────
-- ❌ PROBLEMA: Sin índice compuesto óptimo
SELECT m.id, m.telefono, m.mensaje, i.respuesta_ia, i.costo_usd
FROM mensajes m
JOIN interacciones i ON m.id = i.mensaje_id
WHERE m.tenant_id = 'restaurante_001'  -- C4: Presente ✅
  AND m.fecha > '2026-04-01'
  AND m.estado = 'procesado'
ORDER BY m.fecha DESC
LIMIT 50;

-- ─── PASO 2: ANALIZAR CON EXPLAIN ────────────────────────────────
EXPLAIN FORMAT=JSON
SELECT m.id, m.telefono, m.mensaje, i.respuesta_ia, i.costo_usd
FROM mensajes m
JOIN interacciones i ON m.id = i.mensaje_id
WHERE m.tenant_id = 'restaurante_001'
  AND m.fecha > '2026-04-01'
  AND m.estado = 'procesado'
ORDER BY m.fecha DESC
LIMIT 50;

/*
Resultado EXPLAIN problemático:
{
  "query_block": {
    "table": {
      "table_name": "m",
      "access_type": "ALL",        ← ❌ Full table scan (lento con millones de filas)
      "rows_examined_per_scan": 854000,  ← ❌ Examina 854K filas para retornar 50
      "filtered": 1.5
    }
  }
}
*/

-- ─── PASO 3: CREAR ÍNDICE OPTIMIZADO ─────────────────────────────
-- Orden de columnas en índice: primero las de igualdad, luego rango, luego orden
-- tenant_id (=) → estado (=) → fecha (>, ORDER BY)
ALTER TABLE mensajes
ADD INDEX idx_tenant_estado_fecha (tenant_id, estado, fecha DESC);

-- ─── PASO 4: VERIFICAR MEJORA ────────────────────────────────────
EXPLAIN FORMAT=JSON
SELECT m.id, m.telefono, m.mensaje, i.respuesta_ia, i.costo_usd
FROM mensajes m
JOIN interacciones i ON m.id = i.mensaje_id
WHERE m.tenant_id = 'restaurante_001'
  AND m.fecha > '2026-04-01'
  AND m.estado = 'procesado'
ORDER BY m.fecha DESC
LIMIT 50;

/*
Resultado EXPLAIN optimizado:
{
  "query_block": {
    "table": {
      "table_name": "m",
      "access_type": "range",           ← ✅ Usa índice
      "key": "idx_tenant_estado_fecha", ← ✅ El índice nuevo
      "rows_examined_per_scan": 127,    ← ✅ Solo 127 filas (antes 854K)
      "filtered": 100
    }
  }
}
Mejora: 854000 → 127 filas examinadas = 6724x más rápido ✅
*/
```

**Script de validación post-índice:**
```bash
# Comparar tiempo antes/después
docker exec mantis-mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" mantis_whatsapp -e "
SET profiling = 1;
SELECT COUNT(*) FROM mensajes 
WHERE tenant_id = 'restaurante_001' AND estado = 'procesado' AND fecha > '2026-04-01';
SHOW PROFILES;
" 2>/dev/null
# Output esperado: Duration < 0.01s (con índice) vs > 0.5s (sin índice)
```

---

### Ejemplo 4: Backup Diario Automatizado con SHA256 (C5)

```bash
#!/bin/bash
# backup-mysql-tenants.sh
# C4: Backup independiente por tenant (permite restore individual)
# C5: Backup diario + checksum SHA256 + retención 30 días
set -euo pipefail

# ─── CONFIGURACIÓN ────────────────────────────────────────────────
BACKUP_DIR="/backups/mysql"
MYSQL_HOST="localhost"
MYSQL_PORT="3306"
MYSQL_ROOT="${MYSQL_ROOT_PASSWORD:?'MYSQL_ROOT_PASSWORD no configurado'}"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30
LOG_FILE="/var/log/mantis/backup-$(date +%Y%m%d).log"

mkdir -p "$BACKUP_DIR" "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" | tee -a "$LOG_FILE"
}

# ─── PASO 1: OBTENER LISTA DE BASES DE DATOS TENANT ───────────────
log "Iniciando backup multi-tenant..."

# C4: Obtener todas las BDs (espocrm_* y mantis_*)
DATABASES=$(docker exec mantis-mysql mysql \
    -h "$MYSQL_HOST" -P "$MYSQL_PORT" \
    -u root -p"$MYSQL_ROOT" \
    --skip-column-names -e \
    "SHOW DATABASES WHERE \`Database\` REGEXP '^(espocrm_|mantis_)' AND \`Database\` != 'mantis_test';" \
    2>/dev/null)

if [ -z "$DATABASES" ]; then
    log "❌ ERROR: No se encontraron bases de datos para backup"
    exit 1
fi

BACKUP_MANIFEST="$BACKUP_DIR/manifest_${DATE}.json"
echo '{"timestamp":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'","backups":[' > "$BACKUP_MANIFEST"
FIRST=true

# ─── PASO 2: BACKUP POR BASE DE DATOS ────────────────────────────
for DB in $DATABASES; do
    BACKUP_FILE="$BACKUP_DIR/${DB}_${DATE}.sql.gz"
    
    log "Respaldando: $DB → $(basename "$BACKUP_FILE")"
    
    # mysqldump con opciones de consistencia
    docker exec mantis-mysql mysqldump \
        -h "$MYSQL_HOST" -P "$MYSQL_PORT" \
        -u root -p"$MYSQL_ROOT" \
        --single-transaction \     # InnoDB: snapshot consistente sin lock
        --routines \               # Incluir stored procedures
        --triggers \               # Incluir triggers
        --hex-blob \               # Datos binarios seguros
        --set-gtid-purged=OFF \    # No incluir GTID (evita errores en restore)
        --databases "$DB" \
        2>/dev/null | gzip -9 > "$BACKUP_FILE"
    
    # ─── PASO 3: VERIFICAR INTEGRIDAD (C5) ───────────────────────
    if ! gzip -t "$BACKUP_FILE" 2>/dev/null; then
        log "❌ ERROR: Backup corrupto para $DB"
        rm -f "$BACKUP_FILE"
        continue
    fi
    
    # C5: Generar checksum SHA256
    SHA256=$(sha256sum "$BACKUP_FILE" | awk '{print $1}')
    SIZE=$(du -sh "$BACKUP_FILE" | awk '{print $1}')
    
    log "✅ $DB | Tamaño: $SIZE | SHA256: ${SHA256:0:16}..."
    
    # Agregar al manifest JSON
    [ "$FIRST" = true ] && FIRST=false || echo "," >> "$BACKUP_MANIFEST"
    cat >> "$BACKUP_MANIFEST" << EOF
{
    "database": "$DB",
    "file": "$(basename "$BACKUP_FILE")",
    "size": "$SIZE",
    "sha256": "$SHA256",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    
    # Guardar checksum en archivo separado para verificación rápida
    echo "$SHA256  $(basename "$BACKUP_FILE")" >> "$BACKUP_DIR/checksums_${DATE}.sha256"
done

echo "]}" >> "$BACKUP_MANIFEST"

# ─── PASO 4: RETENCIÓN (C5: eliminar backups > 30 días) ──────────
log "Limpiando backups antiguos (> $RETENTION_DAYS días)..."
find "$BACKUP_DIR" -name "*.sql.gz" -mtime "+$RETENTION_DAYS" -delete
find "$BACKUP_DIR" -name "*.sha256" -mtime "+$RETENTION_DAYS" -delete
find "$BACKUP_DIR" -name "manifest_*.json" -mtime "+$RETENTION_DAYS" -delete

# ─── PASO 5: VERIFICACIÓN FINAL ──────────────────────────────────
BACKUP_COUNT=$(find "$BACKUP_DIR" -name "*_${DATE}.sql.gz" | wc -l)
log "✅ Backup completado: $BACKUP_COUNT bases de datos respaldadas"
log "Manifest: $BACKUP_MANIFEST"
```

**Validar backup generado:**
```bash
# Verificar checksum SHA256
sha256sum --check /backups/mysql/checksums_$(date +%Y%m%d)*.sha256
# Output esperado: todas las líneas con "OK"

# Probar restore en BD de test
DB_TEST="mantis_whatsapp_test"
docker exec mantis-mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" \
    -e "CREATE DATABASE IF NOT EXISTS ${DB_TEST};"
zcat /backups/mysql/mantis_whatsapp_*.sql.gz | \
    docker exec -i mantis-mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" "${DB_TEST}"
echo "✅ Restore de prueba exitoso"
```

---

## 🔍 >5 Ejemplos Independientes por Caso de Uso

### Caso 1: Query de Billing - Costo Total por Tenant del Mes

```sql
-- C4: tenant_id en WHERE y SELECT
-- C1: Usa índice idx_tenant_fecha para evitar full scan

SELECT
    i.tenant_id,                                    -- C4: Siempre presente
    COUNT(*)                AS total_interacciones,
    SUM(i.tokens_input)     AS tokens_entrada,
    SUM(i.tokens_output)    AS tokens_salida,
    SUM(i.tokens_input + i.tokens_output) AS tokens_totales,
    ROUND(SUM(i.costo_usd), 4) AS costo_usd_mes,
    ROUND(SUM(i.costo_usd) * 5.0, 2) AS costo_brl_estimado  -- Tasa USD→BRL aprox
FROM interacciones i
WHERE
    i.tenant_id = ?                                 -- C4: Parámetro obligatorio
    AND i.fecha >= DATE_FORMAT(CURDATE(), '%Y-%m-01') -- Inicio del mes
    AND i.fecha <  DATE_FORMAT(CURDATE() + INTERVAL 1 MONTH, '%Y-%m-01')
GROUP BY i.tenant_id;

-- Verificar que usa índice idx_tenant_fecha
EXPLAIN SELECT ... WHERE tenant_id = 'x' AND fecha >= '2026-04-01';
-- Esperado: key = idx_tenant_fecha
```

---

### Caso 2: Purgar Mensajes Antiguos (Mantenimiento de Disco - C1/RES-003)

```sql
-- ANTES de purgar: verificar cuánto libera
SELECT
    tenant_id,
    COUNT(*)  AS mensajes_a_eliminar,
    MIN(fecha) AS mas_antiguo
FROM mensajes
WHERE
    tenant_id = ?                          -- C4: Solo del tenant indicado
    AND fecha < DATE_SUB(NOW(), INTERVAL 6 MONTH)
    AND procesado = 1                      -- Solo mensajes ya procesados
GROUP BY tenant_id;

-- Si el resultado es aceptable, proceder con DELETE en lotes
-- C1: DELETE en lotes de 1000 para no saturar InnoDB buffer pool
DELETE FROM mensajes
WHERE
    tenant_id = ?                          -- C4
    AND fecha < DATE_SUB(NOW(), INTERVAL 6 MONTH)
    AND procesado = 1
ORDER BY fecha ASC
LIMIT 1000;
-- Repetir hasta que afecte 0 filas (usar en loop bash con sleep 100ms entre iteraciones)
```

---

### Caso 3: Detectar Tabla sin Índice en tenant_id (Auditoría C4)

```sql
-- Listar columnas tenant_id SIN índice (violación C4)
SELECT
    t.TABLE_NAME,
    'tenant_id presente pero SIN ÍNDICE' AS problema
FROM information_schema.COLUMNS c
JOIN information_schema.TABLES t
    ON c.TABLE_SCHEMA = t.TABLE_SCHEMA
    AND c.TABLE_NAME = t.TABLE_NAME
WHERE
    c.TABLE_SCHEMA = 'mantis_whatsapp'
    AND c.COLUMN_NAME = 'tenant_id'
    AND t.TABLE_TYPE = 'BASE TABLE'
    AND NOT EXISTS (
        SELECT 1
        FROM information_schema.STATISTICS s
        WHERE s.TABLE_SCHEMA = c.TABLE_SCHEMA
          AND s.TABLE_NAME = c.TABLE_NAME
          AND s.COLUMN_NAME = 'tenant_id'
          AND s.SEQ_IN_INDEX = 1  -- tenant_id debe ser PRIMERA columna del índice
    )
ORDER BY t.TABLE_NAME;
-- Resultado esperado: 0 filas (todas las tablas tienen índice con tenant_id primero)
```

---

### Caso 4: Monitoreo de Conexiones Activas por Tenant

```sql
-- Ver queries activas filtradas por tenant (útil para debug de lentitud)
-- C4: tenant_id visible en el INFO de la query

SELECT
    ID,
    USER,
    HOST,
    DB,
    COMMAND,
    TIME,
    STATE,
    -- Extraer tenant_id del texto de la query en ejecución
    REGEXP_SUBSTR(INFO, "'[a-z0-9_]+'") AS tenant_posible
FROM information_schema.PROCESSLIST
WHERE
    COMMAND != 'Sleep'
    AND TIME > 5                    -- Queries que llevan > 5 segundos
ORDER BY TIME DESC;

-- Para matar una query específica que está bloqueando (usar con precaución)
-- KILL QUERY {ID};
```

---

### Caso 5: Configurar Particionamiento para Tabla de Alto Volumen

```sql
-- Para tablas mensajes con > 5 millones de filas por tenant
-- Particionamiento por tenant_id usando HASH para distribución uniforme
-- Ejecutar solo si la tabla ya existe y tiene > 5M filas

ALTER TABLE mensajes
PARTITION BY HASH(CRC32(tenant_id))
PARTITIONS 4;    -- 4 particiones = 4 archivos .ibd (1 por partición)
                 -- C1: Más particiones = más RAM para mantener abiertas

-- Verificar distribución de filas entre particiones
SELECT
    PARTITION_NAME,
    TABLE_ROWS,
    ROUND(DATA_LENGTH / 1024 / 1024, 1) AS data_mb
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'mantis_whatsapp'
  AND TABLE_NAME = 'mensajes'
ORDER BY PARTITION_NAME;

-- Para queries con tenant_id, MySQL pruning automático: solo lee la partición relevante
EXPLAIN SELECT * FROM mensajes WHERE tenant_id = 'x' AND fecha > '2026-01-01';
-- En "partitions" debe mostrar solo 1 partición, no las 4
```

---

### Caso 6: Variables de Entorno Completas para .env

```bash
# .env.mysql - Mantis Agentic VPS-2
# C3: NUNCA compartir este archivo. Sin hardcoded secrets en repositorio.
# C4: Credenciales separadas por tenant (aislamiento)

# ─── MySQL Root (solo para operaciones administrativas) ───────────
MYSQL_ROOT_PASSWORD=<generado con: openssl rand -hex 32>

# ─── Usuario de aplicación (n8n, scripts Python) ─────────────────
MYSQL_APP_USER=mantis_app
MYSQL_APP_PASSWORD=<generado con: openssl rand -hex 24>

# ─── Usuarios EspoCRM por tenant (C4: uno por tenant) ────────────
ESPOCRM_DB_USER_RESTAURANTE_001=espo_rest001
ESPOCRM_DB_PASS_RESTAURANTE_001=<generado con: openssl rand -hex 24>

ESPOCRM_DB_USER_ODONTOLOGIA_002=espo_odon002
ESPOCRM_DB_PASS_ODONTOLOGIA_002=<generado con: openssl rand -hex 24>

# ─── Configuración de conexión ────────────────────────────────────
MYSQL_HOST=127.0.0.1           # Desde misma VPS
MYSQL_HOST_VPS2=10.0.1.2       # Desde VPS-1 a VPS-2 (red privada)
MYSQL_PORT=3306
MYSQL_CHARSET=utf8mb4

# ─── Backup (C5) ──────────────────────────────────────────────────
BACKUP_DIR=/backups/mysql
BACKUP_RETENTION_DAYS=30
BACKUP_ENCRYPTION_KEY=<generado con: openssl rand -hex 32>
```

---

## 🐞 Troubleshooting: 5+ Problemas Comunes y Soluciones Exactas

| Error Exacto | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso |
|---|---|---|---|
| `Out of memory` — contenedor MySQL reiniciando repetidamente | `innodb_buffer_pool_size` demasiado alto para memoria disponible del contenedor | `docker stats mantis-mysql --no-stream` → ver MEM USAGE | 1. Reducir `innodb_buffer_pool_size` a 512M<br>2. Editar `my.cnf`: `innodb_buffer_pool_size = 512M`<br>3. Reiniciar: `docker-compose restart mysql`<br>4. Confirmar: `docker stats` muestra < 700MB |
| `ERROR 1040: Too many connections` | `max_connections=80` agotado; muchos workers n8n conectando sin pooling | `SHOW STATUS LIKE 'Max_used_connections';` | 1. Verificar conexiones activas: `SHOW PROCESSLIST \| wc -l`<br>2. Reducir workers n8n: `EXECUTIONS_MAX_CONCURRENT=3`<br>3. Agregar `?connection_limit=5` a la connection string<br>4. O aumentar `max_connections=120` si RAM lo permite |
| Query con `tenant_id` tarda > 2s en tabla de 500K filas | Índice compuesto no empieza por `tenant_id` o no existe | `EXPLAIN SELECT ... WHERE tenant_id = ? AND fecha > ?;` → ver `access_type: ALL` | 1. Si `key: NULL` → crear índice: `ALTER TABLE mensajes ADD INDEX idx_t_f (tenant_id, fecha)`<br>2. Si `key: idx_fecha` pero no `idx_tenant_fecha` → el orden del índice es incorrecto; crear nuevo<br>3. Forzar uso: `SELECT ... FROM mensajes USE INDEX (idx_tenant_fecha) WHERE ...` |
| `ERROR 1062: Duplicate entry 'X-Y' for key 'PRIMARY'` en INSERT masivo | Intento de insertar registro con ID ya existente (proceso reiniciado, idempotencia faltante) | `SELECT * FROM mensajes WHERE id = X AND tenant_id = 'Y';` | 1. Usar `INSERT IGNORE INTO mensajes ...` para ignorar duplicados silenciosamente<br>2. O usar `INSERT INTO mensajes ... ON DUPLICATE KEY UPDATE fecha = VALUES(fecha)`<br>3. Verificar que el generador de IDs sea único por tenant |
| Backup falla: `mysqldump: Error 2006: MySQL server has gone away` | Timeout de conexión durante dump de tablas grandes | `SHOW VARIABLES LIKE 'wait_timeout';` | 1. Agregar al comando mysqldump: `--net_buffer_length=16M --max_allowed_packet=512M`<br>2. Aumentar timeout solo para backup: `mysqldump ... --connect-timeout=60`<br>3. Si la tabla es muy grande, hacer dump por tabla: `mysqldump --tables mensajes` |
| `Disk space full` en `/var/lib/mysql` — MySQL se detiene | Logs binarios (`binlog`) creciendo sin límite, o tabla de auditoría sin TRUNCATE | `du -sh /var/lib/mysql/*` → identificar el directorio más grande | 1. Si es binlog: `PURGE BINARY LOGS BEFORE NOW() - INTERVAL 3 DAY;`<br>2. Si es tabla de logs: `DELETE FROM auditoria WHERE fecha < DATE_SUB(NOW(), INTERVAL 90 DAY) LIMIT 10000;` (en loop)<br>3. Agregar a my.cnf: `expire_logs_days = 3` para binlog automático |
| `Innodb_buffer_pool_hit_rate < 90%` — muchos disk reads | Buffer pool demasiado pequeño para el dataset activo (working set > 768MB) | `SHOW STATUS LIKE 'Innodb_buffer_pool_read%';` | 1. Calcular: `hit_rate = reads_requests / (reads_requests + reads)`. Objetivo: > 95%<br>2. Si < 90%: el working set no cabe. Opciones:<br>   a. Aumentar buffer pool a 1024M (verificar RAM disponible con `free -m`)<br>   b. Purgar datos históricos de tablas grandes (casos 2 en ejemplos)<br>   c. Agregar índices mejores para reducir páginas leídas |

---

## ✅ Validación SDD y Comandos de Prueba

### Health Check Completo de MySQL

```bash
#!/bin/bash
# validate-mysql-sdd.sh
# Valida cumplimiento de C1-C5 en la configuración MySQL actual
set -euo pipefail

MYSQL="docker exec mantis-mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} --skip-column-names -e"
PASS=0
FAIL=0

check() {
    local description="$1"
    local query="$2"
    local expected="$3"
    
    result=$($MYSQL "$query" 2>/dev/null | tr -d ' \n' || echo "ERROR")
    
    if echo "$result" | grep -qi "$expected"; then
        echo "✅ C$4: $description"
        ((PASS++))
    else
        echo "❌ C$4 FAIL: $description | Esperado: $expected | Obtenido: $result"
        ((FAIL++))
    fi
}

echo "═══ VALIDACIÓN SDD MYSQL ═══"

# C1: Verificar innodb_buffer_pool_size ≤ 1GB
check "innodb_buffer_pool_size ≤ 1GB" \
    "SELECT ROUND(@@innodb_buffer_pool_size/1024/1024) < 1025;" \
    "1" "1"

# C1: Verificar max_connections ≤ 100
check "max_connections ≤ 100" \
    "SELECT @@max_connections <= 100;" \
    "1" "1"

# C2: Verificar que sort_buffer_size no es excesivo (< 8MB)
check "sort_buffer_size < 8MB" \
    "SELECT @@sort_buffer_size < 8388608;" \
    "1" "2"

# C3: Verificar que MySQL NO escucha en 0.0.0.0
check "MySQL bind solo en localhost/red privada" \
    "SELECT @@bind_address NOT LIKE '0.0.0.0';" \
    "1" "3"

# C4: Verificar que tabla mensajes tiene índice con tenant_id primero
check "Índice con tenant_id en tabla mensajes" \
    "SELECT COUNT(*) FROM information_schema.STATISTICS WHERE TABLE_SCHEMA='mantis_whatsapp' AND TABLE_NAME='mensajes' AND COLUMN_NAME='tenant_id' AND SEQ_IN_INDEX=1;" \
    "[1-9]" "4"

# C5: Verificar que slow query log está habilitado
check "Slow query log habilitado" \
    "SELECT @@slow_query_log;" \
    "1" "5"

# C5: Verificar que long_query_time ≤ 2s
check "long_query_time ≤ 2s" \
    "SELECT @@long_query_time <= 2;" \
    "1" "5"

echo "═══════════════════════════"
echo "RESULTADO: ✅ $PASS pasaron | ❌ $FAIL fallaron"
[ $FAIL -eq 0 ] && echo "🎉 MySQL cumple todos los constraints SDD" && exit 0 || exit 1
```

**Ejecutar:**
```bash
chmod +x validate-mysql-sdd.sh
./validate-mysql-sdd.sh

# Output esperado (configuración correcta):
# ✅ C1: innodb_buffer_pool_size ≤ 1GB
# ✅ C1: max_connections ≤ 100
# ✅ C2: sort_buffer_size < 8MB
# ✅ C3: MySQL bind solo en localhost/red privada
# ✅ C4: Índice con tenant_id en tabla mensajes
# ✅ C5: Slow query log habilitado
# ✅ C5: long_query_time ≤ 2s
# ═══════════════════════════
# RESULTADO: ✅ 7 pasaron | ❌ 0 fallaron
# 🎉 MySQL cumple todos los constraints SDD
```

### Prueba de Rendimiento con tenant_id

```sql
-- Benchmark manual: comparar query con y sin índice óptimo
-- Ejecutar en MySQL CLI

SET profiling = 1;
SET profiling_history_size = 10;

-- Query 1: Con índice correcto (debe ser < 10ms para 100K filas)
SELECT COUNT(*), MAX(fecha)
FROM mensajes
WHERE tenant_id = 'restaurante_001'
  AND estado = 'procesado'
  AND fecha > DATE_SUB(NOW(), INTERVAL 30 DAY);

SHOW PROFILES;
-- Duration esperada: < 0.01s ✅

-- Si > 0.1s → ejecutar Ejemplo 3 (EXPLAIN + crear índice)
```

---

## 🔗 Referencias Cruzadas

- [[01-RULES/02-RESOURCE-GUARDRAILS.md]] — RES-001 (RAM 4GB), RES-002 (CPU 1 vCPU), RES-003 (disco 50GB)
- [[01-RULES/06-MULTITENANCY-RULES.md]] — MT-001 (tenant_id en todas las tablas), MT-007 (backup por tenant)
- [[01-RULES/03-SECURITY-RULES.md]] — SEC-002 (C3: MySQL no expuesto a internet), credenciales en .env
- [[00-CONTEXT/facundo-infrastructure.md]] — Mapa VPS-1/VPS-2/VPS-3, distribución de servicios
- [[02-SKILLS/INFRASTRUCTURA/espocrm-setup.md]] — MySQL usado por EspoCRM: `espocrm_${tenant_id}`
- [[02-SKILLS/INFRASTRUCTURA/health-monitoring-vps.md]] — Monitoreo de MySQL desde exterior

**Skills relacionados:**
- `espocrm-api-analytics.md` — Queries analíticas sobre el MySQL de EspoCRM
- `multi-tenant-data-isolation.md` — Patrones avanzados de aislamiento en MySQL
- `backup-encryption.md` — Cifrado AES-256 de backups generados por este skill
