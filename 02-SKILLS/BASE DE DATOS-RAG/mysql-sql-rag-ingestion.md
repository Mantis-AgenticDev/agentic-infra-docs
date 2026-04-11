---
title: "mysql-sql-rag-ingestion"
category: "Skill"
domain: ["generico", "backend", "rag", "database"]
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
priority: "Alta"
version: "1.0.0"
last_updated: "2026-04-10"
ai_optimized: true
tags:
  - sdd/skill/mysql
  - sdd/skill/sql
  - sdd/skill/rag
  - sdd/skill/ingestion
  - sdd/skill/multi-tenant
  - sdd/skill/vector
  - sdd/skill/qdrant
  - lang/es
related_files:
  - "01-RULES/06-MULTITENANCY-RULES.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
  - "01-RULES/05-CODE-PATTERNS-RULES.md"
  - "00-CONTEXT/facundo-infrastructure.md"
  - "02-SKILLS/BASE DE DATOS-RAG/rag-system-updates-all-engines.md"
  - "02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md"
  - "02-SKILLS/BASE DE DATOS-RAG/mysql-optimization-4gb-ram.md"
  - "02-SKILLS/INFRASTRUCTURA/espocrm-setup.md"
---

## 🎯 Propósito y Alcance

MySQL como **capa de metadata y orquestación** para el pipeline RAG completo del stack MANTIS AGENTIC. MySQL NO almacena vectores — ese rol es de Qdrant. MySQL almacena el estado del pipeline, la metadata de documentos y chunks, el historial de conversación para contexto RAG, los logs de auditoría, y las tablas de soporte para billing por tenant.

**Por qué MySQL y no solo Qdrant:**
```
Qdrant responde: "¿Qué texto es semánticamente similar a esta consulta?"
MySQL responde:  "¿Qué documentos tiene este tenant?"
                 "¿Este documento ya fue procesado?"
                 "¿Cuántos tokens consumió este tenant este mes?"
                 "¿Cuál es el historial de esta conversación?"
                 "¿Este chunk fue actualizado o es el original?"
```

**Casos de uso cubiertos:**
- Schema completo RAG con todas las tablas necesarias
- Pipeline de ingesta: detección → procesamiento → almacenamiento de metadata
- Gestión de estado de documentos (pending/processing/completed/failed)
- Historial de conversación para contexto RAG multi-turno
- Deduplicación por hash SHA256 (evitar re-procesar documentos sin cambios)
- Billing y métricas de consumo por tenant
- Limpieza y mantenimiento de tablas de alto volumen
- Queries analíticas sobre el corpus RAG
- Integración MySQL ↔ Qdrant (sincronización de IDs)
- Backup y restore de metadata RAG por tenant (C5)

**Fuera de alcance:**
- Almacenamiento de vectores (→ `qdrant-rag-ingestion.md`)
- Generación de embeddings (→ OpenRouter API, C6)
- Extracción de texto de PDFs (→ `pdf-mistralocr-processing.md`)
- Sync con Google Drive (→ `google-drive-qdrant-sync.md`)

---

## 📐 Fundamentos (Nivel Básico)

### Rol de MySQL en el Pipeline RAG

```
PIPELINE RAG COMPLETO - MANTIS AGENTIC
═══════════════════════════════════════

[Fuente]          [Extracción]       [MySQL]            [Qdrant]
Google Drive  →   Mistral OCR   →    rag_documents  →   collection
PDF Upload    →   Text parser   →    (status track)     rag_{tenant}
URL           →   Web scraper   →    rag_chunks     ↔   points + payload
                                     (metadata FK)
                                          ↓
                                     [Conversación]
                                     rag_conversations
                                     rag_messages
                                          ↓
                                     [Billing]
                                     rag_token_usage
```

### ¿Qué persiste en MySQL vs Qdrant?

| Dato | MySQL | Qdrant | Razón |
|---|---|---|---|
| Estado del documento (pending/completed) | ✅ | ❌ | Queries de orquestación |
| Hash SHA256 del contenido | ✅ | En payload | Dedup eficiente con índice |
| Texto completo del chunk | ❌ | En payload | Qdrant más eficiente para texto largo |
| Preview del chunk (500 chars) | ✅ | En payload | Debug sin cargar Qdrant |
| ID del punto en Qdrant | ✅ | Es el ID | FK lógica bidireccional |
| Tokens consumidos | ✅ | ❌ | Billing por tenant |
| Historial de conversación | ✅ | ❌ | Contexto multi-turno |
| Logs de auditoría | ✅ | ❌ | C5: trazabilidad |
| Vectores (embeddings) | ❌ | ✅ | Solo Qdrant gestiona vectores |

### Diagrama de Relaciones Completo

```
tenants
  └── id (PK)
  └── tenant_id (UK)
        │
        ├──1:N── rag_documents
        │           └── id (PK = qdrant document_id en payload)
        │           └── content_hash → detectar cambios
        │           └── status       → orquestación
        │                 │
        │                 └──1:N── rag_chunks
        │                             └── id (PK = qdrant point id)
        │                             └── qdrant_point_id → FK lógica
        │                             └── content_hash → patch selectivo
        │
        ├──1:N── rag_conversations
        │           └── id (PK)
        │           └── channel: 'whatsapp', 'web', 'api'
        │                 │
        │                 └──1:N── rag_messages
        │                             └── role: 'user' | 'assistant'
        │                             └── rag_chunks_used (JSON)
        │                             └── tokens_input / tokens_output
        │
        ├──1:N── rag_token_usage   → billing mensual
        │
        └──1:N── rag_audit_log     → trazabilidad C5
```

---

## 🏗️ Arquitectura y Hardware Limitado (VPS 2vCPU/4-8GB)

### Presupuesto de RAM para Operaciones RAG en MySQL

```
VPS-2 con MySQL compartido:

Operación                    RAM MySQL estimada
─────────────────────────────────────────────────
INSERT 100 chunks (batch)  → ~2MB  ✅
SELECT metadata 1 doc      → <1MB  ✅
DELETE 500 chunks           → ~5MB  ✅
UPDATE status masivo        → ~3MB  ✅
GROUP BY billing mensual    → ~8MB  ✅ (con índice)
GROUP BY billing sin índice → ~80MB ❌ full scan
JOIN docs + chunks 10K rows → ~20MB ⚠️ solo con LIMIT

Regla C1: Nunca queries sin WHERE tenant_id en tablas > 10K filas.
          Siempre LIMIT en queries de administración.
          Batch deletes: máx 1000 filas por iteración.
```

### Configuración de Pool de Conexiones (C1/C2)

```python
# db_pool.py — Singleton de conexión MySQL para scripts RAG
import mysql.connector.pooling
import os

_pool = None

def get_pool():
    """
    C1: pool de máx 10 conexiones (10 × 10MB = 100MB RAM).
    C2: connect_timeout=10s, connection_timeout=30s.
    C3: Solo HOST interno.
    """
    global _pool
    if _pool is None:
        _pool = mysql.connector.pooling.MySQLConnectionPool(
            pool_name    = "mantis_rag",
            pool_size    = 10,          # C1: No más de 10 conexiones
            host         = os.environ["MYSQL_HOST"],
            port         = int(os.environ.get("MYSQL_PORT", 3306)),
            user         = os.environ["MYSQL_USER"],
            password     = os.environ["MYSQL_PASSWORD"],
            database     = os.environ["MYSQL_DATABASE"],
            connect_timeout = 10,       # C2
            connection_timeout = 30,    # C2
            autocommit   = False
        )
    return _pool

def get_conn():
    return get_pool().get_connection()
```

---

## 🔗 Conexión Local vs Externa

### Patrones de Conexión por Escenario

```bash
# .env.rag — Variables para el módulo RAG
# C3: MySQL NUNCA expuesto a internet

# Escenario 1: Script Python en mismo VPS que MySQL
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_USER=mantis_rag
MYSQL_PASSWORD=<openssl rand -hex 24>
MYSQL_DATABASE=mantis_rag_meta

# Escenario 2: n8n en VPS-1 conecta a MySQL en VPS-2
MYSQL_HOST=10.0.1.2          # IP privada VPS-2
MYSQL_PORT=3306
# C3: Red privada entre VPS — sin exponer puerto público

# Escenario 3: Debug local vía SSH tunnel
# ssh -L 3307:127.0.0.1:3306 user@vps2
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3307              # Puerto del tunnel local

# C6: OpenRouter para embeddings (siempre API externa)
OPENROUTER_API_KEY=<tu key>
EMBEDDING_MODEL=text-embedding-3-small
EMBEDDING_DIMENSIONS=1536
```

---

## 📘 Guía de Estructura de Tablas

### Schema Completo MySQL para RAG

```sql
-- ═══════════════════════════════════════════════════════════════
-- SCHEMA: mantis_rag_meta
-- Todas las tablas con tenant_id NOT NULL + índice compuesto (C4)
-- Engine: InnoDB, Charset: utf8mb4 (soporta emojis WhatsApp)
-- ═══════════════════════════════════════════════════════════════

CREATE DATABASE IF NOT EXISTS mantis_rag_meta
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE mantis_rag_meta;

-- ─────────────────────────────────────────────────────────────
-- TABLA 1: rag_documents
-- Registro maestro de documentos por tenant
-- ─────────────────────────────────────────────────────────────
CREATE TABLE rag_documents (
    id              VARCHAR(36)  NOT NULL,
    tenant_id       VARCHAR(50)  NOT NULL,                    -- C4: OBLIGATORIO
    source_type     ENUM('pdf','google_drive','url','text','whatsapp_media')
                                 NOT NULL,
    source_id       VARCHAR(500) NOT NULL,                    -- Drive ID, path, URL
    filename        VARCHAR(255) NOT NULL,
    content_hash    VARCHAR(64)  NOT NULL,                    -- SHA256 texto extraído
    file_size_bytes INT UNSIGNED DEFAULT 0,
    mime_type       VARCHAR(100),
    language        VARCHAR(10)  DEFAULT 'pt-BR',
    status          ENUM('pending','processing','completed','failed','deleted')
                                 NOT NULL DEFAULT 'pending',
    error_message   TEXT,
    total_chunks    SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    embedding_model VARCHAR(100) NOT NULL,                    -- C6: siempre API cloud
    vector_store    VARCHAR(20)  NOT NULL DEFAULT 'qdrant',
    collection_name VARCHAR(100),                             -- Nombre colección Qdrant
    processing_started_at DATETIME,
    processing_ended_at   DATETIME,
    last_updated    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                                          ON UPDATE CURRENT_TIMESTAMP,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    -- C4: tenant_id SIEMPRE primer campo en índices compuestos
    INDEX idx_tenant_status       (tenant_id, status),
    INDEX idx_tenant_source       (tenant_id, source_id(100)),
    INDEX idx_tenant_hash         (tenant_id, content_hash),
    INDEX idx_tenant_created      (tenant_id, created_at DESC),
    INDEX idx_tenant_updated      (tenant_id, last_updated DESC),
    -- FK a tabla maestra de tenants
    CONSTRAINT fk_ragdoc_tenant   FOREIGN KEY (tenant_id)
        REFERENCES tenants(tenant_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci
  COMMENT='Documentos fuente del RAG por tenant - C4 enforced';


-- ─────────────────────────────────────────────────────────────
-- TABLA 2: rag_chunks
-- Chunks individuales con FK al vector store
-- ─────────────────────────────────────────────────────────────
CREATE TABLE rag_chunks (
    id              VARCHAR(36)  NOT NULL,                    -- UUID = ID en Qdrant
    tenant_id       VARCHAR(50)  NOT NULL,                    -- C4: OBLIGATORIO
    document_id     VARCHAR(36)  NOT NULL,
    chunk_index     SMALLINT UNSIGNED NOT NULL,               -- Posición en documento
    total_chunks    SMALLINT UNSIGNED NOT NULL,
    text_preview    VARCHAR(500),                             -- Primeros 500 chars
    token_count     SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    content_hash    VARCHAR(64)  NOT NULL,                    -- SHA256 del texto
    qdrant_point_id VARCHAR(36),                              -- ID en Qdrant (puede ser igual a id)
    collection_name VARCHAR(100),
    embedding_model VARCHAR(100) NOT NULL,                    -- C6
    page_number     SMALLINT UNSIGNED,                        -- Para PDFs
    section         VARCHAR(200),                             -- Sección del documento
    metadata_json   JSON,                                     -- Metadata flexible
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                                          ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    -- C4: tenant_id siempre primero
    INDEX idx_tenant_doc          (tenant_id, document_id),
    INDEX idx_tenant_qdrant       (tenant_id, qdrant_point_id),
    INDEX idx_tenant_updated      (tenant_id, updated_at DESC),
    -- Para reconstruir documento en orden
    UNIQUE KEY uk_doc_chunk_index (document_id, chunk_index),
    CONSTRAINT fk_ragchunk_doc    FOREIGN KEY (document_id)
        REFERENCES rag_documents(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ragchunk_tenant FOREIGN KEY (tenant_id)
        REFERENCES tenants(tenant_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci
  COMMENT='Chunks de documentos RAG - FK a Qdrant via qdrant_point_id';


-- ─────────────────────────────────────────────────────────────
-- TABLA 3: rag_conversations
-- Sesiones de conversación (WhatsApp, web, API)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE rag_conversations (
    id              VARCHAR(36)  NOT NULL,
    tenant_id       VARCHAR(50)  NOT NULL,                    -- C4
    channel         ENUM('whatsapp','web','api','telegram')
                                 NOT NULL DEFAULT 'whatsapp',
    external_id     VARCHAR(100),                             -- Número WA, session ID, etc.
    status          ENUM('active','closed','expired')
                                 NOT NULL DEFAULT 'active',
    context_window  TINYINT UNSIGNED NOT NULL DEFAULT 5,      -- Últimos N mensajes como contexto
    total_messages  SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    total_tokens    INT UNSIGNED NOT NULL DEFAULT 0,
    last_activity   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    INDEX idx_tenant_channel      (tenant_id, channel),       -- C4
    INDEX idx_tenant_external     (tenant_id, external_id),   -- C4: buscar por número WA
    INDEX idx_tenant_activity     (tenant_id, last_activity DESC),
    INDEX idx_tenant_status       (tenant_id, status),
    CONSTRAINT fk_conv_tenant     FOREIGN KEY (tenant_id)
        REFERENCES tenants(tenant_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB
  CHARACTER SET utf8mb4
  COMMENT='Sesiones de conversación RAG multi-canal - C4 enforced';


-- ─────────────────────────────────────────────────────────────
-- TABLA 4: rag_messages
-- Mensajes individuales con chunks usados para contexto
-- ─────────────────────────────────────────────────────────────
CREATE TABLE rag_messages (
    id                  VARCHAR(36)  NOT NULL,
    tenant_id           VARCHAR(50)  NOT NULL,                -- C4
    conversation_id     VARCHAR(36)  NOT NULL,
    role                ENUM('user','assistant','system')
                                     NOT NULL,
    content             TEXT         NOT NULL,
    rag_chunks_used     JSON,       -- Array de {chunk_id, qdrant_id, score}
    rag_query           VARCHAR(500),                         -- Query semántica usada
    tokens_input        SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    tokens_output       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    model_used          VARCHAR(100),                         -- C6: modelo LLM
    latency_ms          SMALLINT UNSIGNED,
    created_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    INDEX idx_tenant_conv         (tenant_id, conversation_id), -- C4
    INDEX idx_tenant_created      (tenant_id, created_at DESC),
    INDEX idx_tenant_role         (tenant_id, role),
    CONSTRAINT fk_msg_conv        FOREIGN KEY (conversation_id)
        REFERENCES rag_conversations(id) ON DELETE CASCADE,
    CONSTRAINT fk_msg_tenant      FOREIGN KEY (tenant_id)
        REFERENCES tenants(tenant_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB
  CHARACTER SET utf8mb4
  COMMENT='Mensajes del pipeline RAG con chunks utilizados - C4 enforced';


-- ─────────────────────────────────────────────────────────────
-- TABLA 5: rag_token_usage
-- Agregados de consumo para billing por tenant/mes
-- ─────────────────────────────────────────────────────────────
CREATE TABLE rag_token_usage (
    id                  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id           VARCHAR(50)  NOT NULL,                -- C4
    year_month          CHAR(7)      NOT NULL,                -- '2026-04'
    embedding_tokens    INT UNSIGNED NOT NULL DEFAULT 0,
    llm_tokens_input    INT UNSIGNED NOT NULL DEFAULT 0,
    llm_tokens_output   INT UNSIGNED NOT NULL DEFAULT 0,
    total_requests      INT UNSIGNED NOT NULL DEFAULT 0,
    total_conversations INT UNSIGNED NOT NULL DEFAULT 0,
    cost_usd_estimated  DECIMAL(10,4) NOT NULL DEFAULT 0,
    last_updated        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                                              ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_tenant_month    (tenant_id, year_month),    -- C4: uno por tenant/mes
    INDEX idx_tenant_month        (tenant_id, year_month DESC),
    CONSTRAINT fk_usage_tenant    FOREIGN KEY (tenant_id)
        REFERENCES tenants(tenant_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB
  COMMENT='Consumo de tokens por tenant y mes - billing - C4 enforced';


-- ─────────────────────────────────────────────────────────────
-- TABLA 6: rag_audit_log
-- Trazabilidad completa de operaciones (C5)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE rag_audit_log (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    tenant_id       VARCHAR(50)  NOT NULL,                    -- C4
    operation       VARCHAR(50)  NOT NULL,
    -- 'ingest_start','ingest_complete','ingest_failed',
    -- 'chunk_created','chunk_updated','chunk_deleted',
    -- 'doc_deleted','full_reingest','conversation_closed'
    entity_type     VARCHAR(30),                              -- 'document','chunk','conversation'
    entity_id       VARCHAR(36),
    details_json    JSON,
    status          ENUM('success','failed','skipped') NOT NULL DEFAULT 'success',
    error_message   TEXT,
    duration_ms     SMALLINT UNSIGNED,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_tenant_created      (tenant_id, created_at DESC), -- C4
    INDEX idx_tenant_operation    (tenant_id, operation),
    INDEX idx_entity              (entity_id)
) ENGINE=InnoDB
  CHARACTER SET utf8mb4
  COMMENT='Audit trail completo de operaciones RAG - C5 enforced'
  PARTITION BY RANGE (YEAR(created_at) * 100 + MONTH(created_at)) (
    PARTITION p202601 VALUES LESS THAN (202602),
    PARTITION p202602 VALUES LESS THAN (202603),
    PARTITION p202603 VALUES LESS THAN (202604),
    PARTITION p202604 VALUES LESS THAN (202605),
    PARTITION p202605 VALUES LESS THAN (202606),
    PARTITION p_future VALUES LESS THAN MAXVALUE
  );
-- Particionamiento mensual para que los deletes de logs viejos sean O(1)
```

---

## 🛠️ 10 Ejemplos — Caso 1: Ingesta Inicial de Documento

### I-1: Registrar Documento Nuevo (INSERT Idempotente)

```python
# ingest_01_register_document.py
import hashlib, uuid
from datetime import datetime
from db_pool import get_conn

def register_document(
    tenant_id:   str,   # C4
    source_type: str,
    source_id:   str,
    filename:    str,
    content:     str,
    embedding_model: str = "text-embedding-3-small"
) -> dict:
    """
    Registra un documento nuevo o detecta si ya existe sin cambios.
    Usa INSERT ... ON DUPLICATE KEY UPDATE para idempotencia total.
    C4: tenant_id en INSERT y en verificación de existencia.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    doc_id       = str(uuid.uuid4())
    content_hash = hashlib.sha256(content.encode("utf-8")).hexdigest()

    conn   = get_conn()
    cursor = conn.cursor(dictionary=True)
    try:
        # Verificar si ya existe por source_id + tenant_id (C4)
        cursor.execute(
            """SELECT id, content_hash, status
               FROM rag_documents
               WHERE tenant_id = %s AND source_id = %s
               LIMIT 1""",
            (tenant_id, source_id)   # C4
        )
        existing = cursor.fetchone()

        if existing:
            if existing["content_hash"] == content_hash:
                return {
                    "action":      "skipped",
                    "reason":      "hash_unchanged",
                    "document_id": existing["id"],
                    "tenant_id":   tenant_id          # C4
                }
            # Hash cambió → marcar pending para re-ingesta
            cursor.execute(
                """UPDATE rag_documents
                   SET content_hash = %s,
                       status       = 'pending',
                       total_chunks  = 0,
                       last_updated = %s
                   WHERE id = %s AND tenant_id = %s""",  # C4
                (content_hash, datetime.utcnow(), existing["id"], tenant_id)
            )
            conn.commit()
            return {
                "action":      "updated",
                "document_id": existing["id"],
                "tenant_id":   tenant_id,              # C4
                "old_hash":    existing["content_hash"],
                "new_hash":    content_hash
            }

        # Documento nuevo
        cursor.execute(
            """INSERT INTO rag_documents
               (id, tenant_id, source_type, source_id, filename,
                content_hash, status, total_chunks, embedding_model,
                vector_store, collection_name, created_at, last_updated)
               VALUES (%s,%s,%s,%s,%s,%s,'pending',0,%s,'qdrant',%s,%s,%s)""",
            (doc_id, tenant_id, source_type, source_id, filename,    # C4
             content_hash, embedding_model, f"rag_{tenant_id}",
             datetime.utcnow(), datetime.utcnow())
        )
        conn.commit()

        return {
            "action":      "created",
            "document_id": doc_id,
            "tenant_id":   tenant_id,                  # C4
            "content_hash": content_hash
        }
    except Exception:
        conn.rollback()
        raise
    finally:
        cursor.close()
        conn.close()
```

---

### I-2: Marcar Inicio de Procesamiento (Heartbeat de Estado)

```python
# ingest_02_mark_processing.py
def mark_document_processing(tenant_id: str, document_id: str) -> bool:
    """
    Marca el documento como 'processing' con timestamp de inicio.
    Permite detectar procesos colgados por timeout (> 1 hora en 'processing').
    C4: WHERE siempre con tenant_id.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    conn   = get_conn()
    cursor = conn.cursor()
    try:
        cursor.execute(
            """UPDATE rag_documents
               SET status                = 'processing',
                   processing_started_at = %s,
                   last_updated          = %s
               WHERE id        = %s
                 AND tenant_id = %s
                 AND status    = 'pending'""",   # C4 + solo desde 'pending'
            (datetime.utcnow(), datetime.utcnow(), document_id, tenant_id)
        )
        conn.commit()
        updated = cursor.rowcount > 0

        if not updated:
            # Verificar si existe pero está en otro estado
            cursor.execute(
                "SELECT status FROM rag_documents WHERE id = %s AND tenant_id = %s",
                (document_id, tenant_id)   # C4
            )
            row = cursor.fetchone()
            if row:
                raise ValueError(f"Cannot process: document is '{row[0]}' (expected 'pending')")
            raise ValueError(f"Document {document_id} not found for tenant {tenant_id} (C4)")

        return True
    except Exception:
        conn.rollback()
        raise
    finally:
        cursor.close()
        conn.close()
```

---

### I-3: Insertar Chunks en Lote (INSERT Masivo Optimizado)

```python
# ingest_03_insert_chunks_batch.py
def insert_chunks_batch(
    tenant_id:   str,       # C4
    document_id: str,
    chunks: list[dict]      # [{"id", "text", "chunk_index", "token_count", "page_number"}]
) -> int:
    """
    Inserta todos los chunks de un documento en un batch eficiente.
    C1: Lotes de 100 filas por INSERT para no saturar RAM.
    C4: tenant_id en cada fila del INSERT.
    Usa INSERT IGNORE para idempotencia total.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")
    if not chunks:
        return 0

    conn   = get_conn()
    cursor = conn.cursor()
    now    = datetime.utcnow()
    model  = __import__("os").environ.get("EMBEDDING_MODEL", "text-embedding-3-small")

    INSERT_SQL = """
        INSERT IGNORE INTO rag_chunks
            (id, tenant_id, document_id, chunk_index, total_chunks,
             text_preview, token_count, content_hash,
             embedding_model, page_number, created_at, updated_at)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
    """

    try:
        total_inserted = 0
        total_chunks   = len(chunks)

        # C1: Lotes de 100 — nunca insertar todo de una vez
        for i in range(0, total_chunks, 100):
            batch = chunks[i:i + 100]
            rows  = [
                (
                    chunk["id"],
                    tenant_id,                                          # C4
                    document_id,
                    chunk["chunk_index"],
                    total_chunks,
                    chunk.get("text", "")[:500],                        # Preview
                    chunk.get("token_count", 0),
                    hashlib.sha256(chunk.get("text","").encode()).hexdigest(),
                    model,
                    chunk.get("page_number"),
                    now, now
                )
                for chunk in batch
            ]
            cursor.executemany(INSERT_SQL, rows)
            total_inserted += cursor.rowcount

        # Actualizar contadores en el documento padre
        cursor.execute(
            """UPDATE rag_documents
               SET total_chunks = %s, last_updated = %s
               WHERE id = %s AND tenant_id = %s""",   # C4
            (total_chunks, now, document_id, tenant_id)
        )
        conn.commit()
        return total_inserted

    except Exception:
        conn.rollback()
        raise
    finally:
        cursor.close()
        conn.close()
```

---

### I-4: Vincular Chunks con IDs de Qdrant (Post-Vectorización)

```python
# ingest_04_link_qdrant_ids.py
def link_chunks_to_qdrant(
    tenant_id:      str,       # C4
    document_id:    str,
    chunk_qdrant_map: list[dict]  # [{"chunk_id": uuid, "qdrant_point_id": uuid}]
) -> int:
    """
    Después de insertar vectores en Qdrant, guarda el qdrant_point_id
    en MySQL para la FK lógica bidireccional.
    C4: UPDATE con tenant_id y document_id para no cruzar tenants.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    conn   = get_conn()
    cursor = conn.cursor()
    now    = datetime.utcnow()

    UPDATE_SQL = """
        UPDATE rag_chunks
        SET qdrant_point_id = %s,
            updated_at      = %s
        WHERE id          = %s
          AND tenant_id   = %s
          AND document_id = %s
    """   # C4: triple filtro

    try:
        updated_total = 0
        # Lotes de 100 UPDATE (C1)
        for i in range(0, len(chunk_qdrant_map), 100):
            batch = chunk_qdrant_map[i:i+100]
            for mapping in batch:
                cursor.execute(UPDATE_SQL, (
                    mapping["qdrant_point_id"],
                    now,
                    mapping["chunk_id"],
                    tenant_id,                # C4
                    document_id
                ))
                updated_total += cursor.rowcount

        conn.commit()
        return updated_total

    except Exception:
        conn.rollback()
        raise
    finally:
        cursor.close()
        conn.close()
```

---

### I-5: Completar Ingesta (Marcar Documento Completed + Audit C5)

```python
# ingest_05_complete_ingestion.py
import time

def complete_ingestion(
    tenant_id:   str,    # C4
    document_id: str,
    chunks_count: int,
    start_time:  float   # time.time() del inicio
) -> dict:
    """
    Marca el documento como 'completed' y escribe el audit log.
    C5: Registro completo con duración, chunks, tenant_id.
    C4: Todos los writes con tenant_id.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    duration_ms = int((time.time() - start_time) * 1000)
    now         = datetime.utcnow()

    conn   = get_conn()
    cursor = conn.cursor()
    try:
        conn.start_transaction()

        cursor.execute(
            """UPDATE rag_documents
               SET status               = 'completed',
                   total_chunks          = %s,
                   processing_ended_at  = %s,
                   last_updated         = %s
               WHERE id        = %s
                 AND tenant_id = %s""",   # C4
            (chunks_count, now, now, document_id, tenant_id)
        )

        if cursor.rowcount == 0:
            raise ValueError(f"Document {document_id} not found for tenant {tenant_id} (C4)")

        # C5: Audit log obligatorio
        cursor.execute(
            """INSERT INTO rag_audit_log
               (tenant_id, operation, entity_type, entity_id,
                details_json, status, duration_ms, created_at)
               VALUES (%s,'ingest_complete','document',%s,%s,'success',%s,%s)""",
            (
                tenant_id,    # C4
                document_id,
                __import__("json").dumps({
                    "chunks_ingested": chunks_count,
                    "duration_ms":     duration_ms
                }),
                duration_ms,
                now
            )
        )

        conn.commit()
        return {
            "tenant_id":   tenant_id,    # C4
            "document_id": document_id,
            "status":      "completed",
            "chunks":      chunks_count,
            "duration_ms": duration_ms
        }

    except Exception:
        conn.rollback()
        # C5: Loguear fallo también
        cursor.execute(
            """INSERT INTO rag_audit_log
               (tenant_id, operation, entity_type, entity_id, status, created_at)
               VALUES (%s,'ingest_failed','document',%s,'failed',%s)""",
            (tenant_id, document_id, now)   # C4
        )
        conn.commit()
        raise
    finally:
        cursor.close()
        conn.close()
```

---

### I-6: Pipeline Completo en Una Transacción

```python
# ingest_06_full_pipeline_transaction.py
def ingest_document_full(
    tenant_id:   str,          # C4
    source_type: str,
    source_id:   str,
    filename:    str,
    content:     str,
    chunks_with_qdrant_ids: list[dict]
    # [{"id", "text", "chunk_index", "token_count", "qdrant_point_id"}]
) -> dict:
    """
    Pipeline de ingesta completo en una sola transacción MySQL.
    Registro del documento + todos sus chunks + audit log.
    C4: tenant_id en cada operación.
    C1: Chunks en lotes de 100.
    Atómico: si falla cualquier paso, rollback total.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    import time
    start    = time.time()
    doc_id   = str(uuid.uuid4())
    content_hash = hashlib.sha256(content.encode()).hexdigest()
    model    = __import__("os").environ.get("EMBEDDING_MODEL", "text-embedding-3-small")
    now      = datetime.utcnow()

    conn   = get_conn()
    cursor = conn.cursor()

    try:
        conn.start_transaction()

        # 1. Insertar documento
        cursor.execute(
            """INSERT INTO rag_documents
               (id,tenant_id,source_type,source_id,filename,content_hash,
                status,total_chunks,embedding_model,vector_store,collection_name,
                processing_started_at,created_at,last_updated)
               VALUES (%s,%s,%s,%s,%s,%s,'processing',%s,%s,'qdrant',%s,%s,%s,%s)""",
            (doc_id, tenant_id, source_type, source_id, filename,    # C4
             content_hash, len(chunks_with_qdrant_ids), model,
             f"rag_{tenant_id}", now, now, now)
        )

        # 2. Insertar chunks en lotes de 100 (C1)
        total_chunks = len(chunks_with_qdrant_ids)
        for i in range(0, total_chunks, 100):
            batch = chunks_with_qdrant_ids[i:i+100]
            cursor.executemany(
                """INSERT IGNORE INTO rag_chunks
                   (id,tenant_id,document_id,chunk_index,total_chunks,
                    text_preview,token_count,content_hash,qdrant_point_id,
                    embedding_model,created_at,updated_at)
                   VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)""",
                [(
                    c["id"], tenant_id, doc_id,                        # C4
                    c["chunk_index"], total_chunks,
                    c.get("text","")[:500],
                    c.get("token_count",0),
                    hashlib.sha256(c.get("text","").encode()).hexdigest(),
                    c.get("qdrant_point_id"),
                    model, now, now
                ) for c in batch]
            )

        # 3. Completar documento
        duration_ms = int((time.time() - start) * 1000)
        cursor.execute(
            """UPDATE rag_documents
               SET status='completed', processing_ended_at=%s, last_updated=%s
               WHERE id=%s AND tenant_id=%s""",   # C4
            (now, now, doc_id, tenant_id)
        )

        # 4. Audit log C5
        cursor.execute(
            """INSERT INTO rag_audit_log
               (tenant_id,operation,entity_type,entity_id,details_json,
                status,duration_ms,created_at)
               VALUES (%s,'ingest_complete','document',%s,%s,'success',%s,%s)""",
            (tenant_id, doc_id,                                        # C4
             __import__("json").dumps({
                 "chunks": total_chunks, "source": source_id
             }),
             duration_ms, now)
        )

        conn.commit()
        return {
            "tenant_id":   tenant_id,                                  # C4
            "document_id": doc_id,
            "chunks":      total_chunks,
            "duration_ms": duration_ms
        }

    except Exception as e:
        conn.rollback()
        # Intentar registrar el fallo en audit log (nueva conexión para no usar la rolled-back)
        try:
            conn2   = get_conn()
            cur2    = conn2.cursor()
            cur2.execute(
                """INSERT INTO rag_audit_log
                   (tenant_id,operation,entity_type,entity_id,
                    status,error_message,created_at)
                   VALUES (%s,'ingest_failed','document',%s,'failed',%s,%s)""",
                (tenant_id, doc_id, str(e)[:500], now)                 # C4
            )
            conn2.commit()
            cur2.close()
            conn2.close()
        except Exception:
            pass
        raise
    finally:
        cursor.close()
        conn.close()
```

---

### I-7: Ingesta desde n8n (Función JavaScript para Nodo Function)

```javascript
// ingest_07_n8n_function_node.js
// Nodo Function de n8n para preparar datos de ingesta hacia MySQL vía HTTP node
// C4: tenant_id en todos los objetos generados

const tenantId = $input.first().json.tenant_id;
if (!tenantId) throw new Error('tenant_id missing in webhook payload (C4 violation)');

const documentId   = $input.first().json.document_id || require('crypto').randomUUID();
const sourceType   = $input.first().json.source_type || 'pdf';
const sourceId     = $input.first().json.source_id;
const filename     = $input.first().json.filename;
const contentHash  = $input.first().json.content_hash;

if (!sourceId || !filename || !contentHash) {
    throw new Error(`Missing required fields: sourceId=${sourceId}, filename=${filename}`);
}

// Preparar payload para HTTP node → API interna de ingesta
return [{
    json: {
        // C4: tenant_id SIEMPRE presente en el payload enviado
        tenant_id:       tenantId,
        document_id:     documentId,
        source_type:     sourceType,
        source_id:       sourceId,
        filename:        filename,
        content_hash:    contentHash,
        embedding_model: process.env.EMBEDDING_MODEL || 'text-embedding-3-small',
        timestamp:       new Date().toISOString(),
        // Metadata de auditoría (C5)
        n8n_workflow_id: $workflow.id,
        n8n_execution_id: $execution.id
    }
}];
```

---

### I-8: Detección de Documentos Pendientes para Worker (Queue Pattern)

```sql
-- ingest_08_fetch_pending_documents.sql
-- Query usada por el worker de ingesta para obtener trabajo pendiente
-- C4: tenant_id en WHERE y SELECT
-- C1: LIMIT para no cargar toda la tabla en memoria

-- Obtener próximos N documentos pendientes (FIFO por tenant)
-- Usar FOR UPDATE para lock pesimista (evitar doble procesamiento)
SELECT
    id,
    tenant_id,           -- C4: siempre presente en resultados
    source_type,
    source_id,
    filename,
    content_hash,
    embedding_model,
    collection_name
FROM rag_documents
WHERE
    status    = 'pending'
    AND tenant_id = ?    -- C4: procesar por tenant específico
ORDER BY created_at ASC  -- FIFO
LIMIT 5                  -- C1: No tomar más de 5 a la vez por worker
FOR UPDATE SKIP LOCKED;  -- Permite múltiples workers sin deadlock
-- SKIP LOCKED: MySQL 8.0+, ignora filas lockeadas por otro worker

-- Limpiar documentos 'processing' bloqueados > 1 hora (proceso crashed)
UPDATE rag_documents
SET
    status        = 'pending',
    last_updated  = NOW()
WHERE
    status       = 'processing'
    AND tenant_id = ?              -- C4
    AND processing_started_at < DATE_SUB(NOW(), INTERVAL 1 HOUR);
```

---

### I-9: Registro de Consumo de Tokens (Billing por Tenant)

```python
# ingest_09_track_token_usage.py
def track_token_usage(
    tenant_id:         str,    # C4
    embedding_tokens:  int = 0,
    llm_tokens_input:  int = 0,
    llm_tokens_output: int = 0,
    cost_usd:          float = 0.0
) -> None:
    """
    Acumula tokens consumidos en la tabla de billing mensual.
    Usa INSERT ... ON DUPLICATE KEY UPDATE para acumulación atómica.
    C4: tenant_id en INSERT y ON DUPLICATE.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    year_month = datetime.utcnow().strftime("%Y-%m")

    conn   = get_conn()
    cursor = conn.cursor()
    try:
        cursor.execute(
            """INSERT INTO rag_token_usage
               (tenant_id, year_month,
                embedding_tokens, llm_tokens_input, llm_tokens_output,
                total_requests, cost_usd_estimated, last_updated)
               VALUES (%s,%s,%s,%s,%s,1,%s,NOW())
               ON DUPLICATE KEY UPDATE
                   embedding_tokens    = embedding_tokens    + VALUES(embedding_tokens),
                   llm_tokens_input    = llm_tokens_input    + VALUES(llm_tokens_input),
                   llm_tokens_output   = llm_tokens_output   + VALUES(llm_tokens_output),
                   total_requests      = total_requests      + 1,
                   cost_usd_estimated  = cost_usd_estimated  + VALUES(cost_usd_estimated),
                   last_updated        = NOW()""",
            (tenant_id, year_month,                          # C4
             embedding_tokens, llm_tokens_input, llm_tokens_output,
             round(cost_usd, 6))
        )
        conn.commit()
    finally:
        cursor.close()
        conn.close()

# Consultar billing del mes actual
def get_monthly_billing(tenant_id: str, year_month: str = None) -> dict:
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    year_month = year_month or datetime.utcnow().strftime("%Y-%m")
    conn   = get_conn()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(
            """SELECT
                   tenant_id,              -- C4
                   year_month,
                   embedding_tokens,
                   llm_tokens_input,
                   llm_tokens_output,
                   total_requests,
                   cost_usd_estimated,
                   ROUND(cost_usd_estimated * 5.0, 2) AS cost_brl_estimated
               FROM rag_token_usage
               WHERE tenant_id  = %s
                 AND year_month = %s""",   -- C4
            (tenant_id, year_month)
        )
        row = cursor.fetchone()
        return row or {"tenant_id": tenant_id, "year_month": year_month, "total_requests": 0}
    finally:
        cursor.close()
        conn.close()
```

---

### I-10: Verificación de Integridad Post-Ingesta

```sql
-- ingest_10_integrity_check.sql
-- Ejecutar después de cada ingesta masiva para detectar inconsistencias
-- C4: tenant_id en TODOS los WHERE

-- CHECK 1: Documentos 'completed' con 0 chunks (error en pipeline)
SELECT
    d.id,
    d.tenant_id,       -- C4
    d.filename,
    d.total_chunks     AS declared_chunks,
    COUNT(c.id)        AS actual_chunks
FROM rag_documents d
LEFT JOIN rag_chunks c
    ON d.id = c.document_id
    AND d.tenant_id = c.tenant_id    -- C4: JOIN con tenant_id
WHERE
    d.tenant_id = ?                  -- C4
    AND d.status  = 'completed'
GROUP BY d.id, d.tenant_id, d.filename, d.total_chunks
HAVING actual_chunks = 0 OR actual_chunks != declared_chunks;
-- Resultado esperado: 0 filas

-- CHECK 2: Chunks sin qdrant_point_id (no vectorizados)
SELECT
    tenant_id,         -- C4
    document_id,
    COUNT(*)           AS chunks_sin_vector
FROM rag_chunks
WHERE
    tenant_id          = ?           -- C4
    AND qdrant_point_id IS NULL
GROUP BY tenant_id, document_id;
-- Resultado esperado: 0 filas

-- CHECK 3: Chunks huérfanos (sin documento padre)
SELECT
    rc.id,
    rc.tenant_id,      -- C4
    rc.document_id
FROM rag_chunks rc
LEFT JOIN rag_documents rd
    ON rc.document_id = rd.id
    AND rc.tenant_id  = rd.tenant_id    -- C4: JOIN con tenant_id
WHERE
    rd.id IS NULL
    AND rc.tenant_id = ?                -- C4
LIMIT 20;
-- Resultado esperado: 0 filas

-- CHECK 4: Documentos bloqueados en 'processing' > 30 minutos
SELECT
    id,
    tenant_id,         -- C4
    filename,
    processing_started_at,
    TIMESTAMPDIFF(MINUTE, processing_started_at, NOW()) AS minutes_stuck
FROM rag_documents
WHERE
    tenant_id            = ?            -- C4
    AND status           = 'processing'
    AND processing_started_at < DATE_SUB(NOW(), INTERVAL 30 MINUTE);
-- Resultado esperado: 0 filas
```

---

---

## 🛠️ 10 Ejemplos — Caso 2: Gestión de Conversaciones RAG

### C-1: Crear o Recuperar Conversación Activa

```python
# conv_01_get_or_create_conversation.py
def get_or_create_conversation(
    tenant_id:   str,     # C4
    channel:     str,
    external_id: str,     # Número WhatsApp, session ID, etc.
    context_window: int = 5
) -> dict:
    """
    Retorna conversación activa existente o crea una nueva.
    Una conversación es 'activa' si tuvo actividad en las últimas 4 horas.
    C4: tenant_id en todas las queries.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    conn   = get_conn()
    cursor = conn.cursor(dictionary=True)
    try:
        # Buscar conversación activa reciente (C4: doble filtro)
        cursor.execute(
            """SELECT id, status, total_messages, total_tokens
               FROM rag_conversations
               WHERE tenant_id   = %s
                 AND channel     = %s
                 AND external_id = %s
                 AND status      = 'active'
                 AND last_activity > DATE_SUB(NOW(), INTERVAL 4 HOUR)
               ORDER BY last_activity DESC
               LIMIT 1""",
            (tenant_id, channel, external_id)   # C4
        )
        existing = cursor.fetchone()

        if existing:
            return {
                "conversation_id": existing["id"],
                "is_new":          False,
                "tenant_id":       tenant_id,     # C4
                "total_messages":  existing["total_messages"]
            }

        # Crear nueva conversación
        conv_id = str(uuid.uuid4())
        cursor.execute(
            """INSERT INTO rag_conversations
               (id, tenant_id, channel, external_id, status,
                context_window, total_messages, created_at, last_activity)
               VALUES (%s,%s,%s,%s,'active',%s,0,%s,%s)""",
            (conv_id, tenant_id, channel, external_id,    # C4
             context_window, datetime.utcnow(), datetime.utcnow())
        )
        conn.commit()
        return {
            "conversation_id": conv_id,
            "is_new":          True,
            "tenant_id":       tenant_id    # C4
        }

    except Exception:
        conn.rollback()
        raise
    finally:
        cursor.close()
        conn.close()
```

---

### C-2: Guardar Mensaje con Chunks RAG Utilizados

```python
# conv_02_save_message_with_rag.py
def save_message_with_rag_context(
    tenant_id:        str,      # C4
    conversation_id:  str,
    role:             str,      # 'user' | 'assistant'
    content:          str,
    rag_chunks_used:  list = None,  # [{"chunk_id": ..., "score": 0.92}]
    rag_query:        str = None,
    tokens_input:     int = 0,
    tokens_output:    int = 0,
    model_used:       str = None,
    latency_ms:       int = 0
) -> str:
    """
    Guarda un mensaje y actualiza contadores de la conversación.
    Registra qué chunks RAG se usaron para trazabilidad (C5).
    C4: tenant_id en INSERT y UPDATE.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    import json
    msg_id = str(uuid.uuid4())
    now    = datetime.utcnow()

    conn   = get_conn()
    cursor = conn.cursor()
    try:
        conn.start_transaction()

        # Verificar que la conversación pertenece al tenant (C4)
        cursor.execute(
            "SELECT id FROM rag_conversations WHERE id = %s AND tenant_id = %s",
            (conversation_id, tenant_id)   # C4
        )
        if not cursor.fetchone():
            raise ValueError(f"Conversation not found for tenant {tenant_id} (C4)")

        # Insertar mensaje
        cursor.execute(
            """INSERT INTO rag_messages
               (id, tenant_id, conversation_id, role, content,
                rag_chunks_used, rag_query, tokens_input, tokens_output,
                model_used, latency_ms, created_at)
               VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)""",
            (
                msg_id, tenant_id, conversation_id,    # C4
                role, content,
                json.dumps(rag_chunks_used or []),
                rag_query,
                tokens_input, tokens_output,
                model_used,
                latency_ms,
                now
            )
        )

        # Actualizar contadores en conversación
        cursor.execute(
            """UPDATE rag_conversations
               SET total_messages = total_messages + 1,
                   total_tokens   = total_tokens   + %s,
                   last_activity  = %s
               WHERE id        = %s
                 AND tenant_id = %s""",   # C4
            (tokens_input + tokens_output, now, conversation_id, tenant_id)
        )

        conn.commit()
        return msg_id

    except Exception:
        conn.rollback()
        raise
    finally:
        cursor.close()
        conn.close()
```

---

### C-3: Obtener Contexto Multi-Turno para LLM

```python
# conv_03_get_conversation_context.py
def get_conversation_context(
    tenant_id:       str,    # C4
    conversation_id: str,
    last_n_messages: int = 5
) -> list[dict]:
    """
    Recupera los últimos N mensajes de la conversación para
    construir el contexto del LLM.
    C4: tenant_id en WHERE.
    C1: LIMIT para no cargar conversaciones largas completas.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    last_n_messages = min(last_n_messages, 20)  # C1: Máximo 20 mensajes

    conn   = get_conn()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(
            """SELECT role, content, rag_chunks_used, created_at
               FROM rag_messages
               WHERE conversation_id = %s
                 AND tenant_id       = %s
               ORDER BY created_at DESC
               LIMIT %s""",
            (conversation_id, tenant_id, last_n_messages)   # C4
        )
        messages = cursor.fetchall()
        # Invertir para orden cronológico (DESC → ASC)
        messages.reverse()

        # Formato para OpenRouter API
        return [
            {
                "role":    msg["role"],
                "content": msg["content"]
            }
            for msg in messages
        ]

    finally:
        cursor.close()
        conn.close()
```

---

### C-4: Cerrar Conversaciones Expiradas (Mantenimiento)

```sql
-- conv_04_close_expired_conversations.sql
-- Cerrar conversaciones sin actividad > 4 horas
-- C4: tenant_id en todos los WHERE
-- Ejecutar como cron cada 30 minutos

-- PASO 1: Identificar conversaciones a cerrar por tenant
SELECT
    tenant_id,           -- C4
    COUNT(*) AS a_cerrar
FROM rag_conversations
WHERE
    tenant_id     = ?    -- C4: Por tenant específico o ALL si es mantenimiento global
    AND status    = 'active'
    AND last_activity < DATE_SUB(NOW(), INTERVAL 4 HOUR)
GROUP BY tenant_id;

-- PASO 2: Cerrar en lotes (C1: máx 500 por UPDATE)
UPDATE rag_conversations
SET status = 'expired'
WHERE
    tenant_id     = ?    -- C4
    AND status    = 'active'
    AND last_activity < DATE_SUB(NOW(), INTERVAL 4 HOUR)
LIMIT 500;

-- PASO 3: Auditoría del cierre (C5)
INSERT INTO rag_audit_log
    (tenant_id, operation, entity_type, status, details_json, created_at)
SELECT
    tenant_id,           -- C4
    'conversation_batch_close',
    'conversation',
    'success',
    JSON_OBJECT('closed_at', NOW(), 'reason', 'expired_4h'),
    NOW()
FROM rag_conversations
WHERE tenant_id = ? AND status = 'expired'
  AND last_activity > DATE_SUB(NOW(), INTERVAL 1 MINUTE)  -- Las recién cerradas
LIMIT 1;
```

---

### C-5: Reporte de Actividad de Conversaciones por Tenant

```sql
-- conv_05_activity_report.sql
-- Dashboard de conversaciones para el cliente final
-- C4: tenant_id en ALL queries

SELECT
    tenant_id,                                              -- C4
    DATE(created_at)                    AS fecha,
    channel,
    COUNT(*)                            AS conversaciones,
    SUM(total_messages)                 AS mensajes_total,
    SUM(total_tokens)                   AS tokens_total,
    ROUND(AVG(total_messages), 1)       AS mensajes_promedio,
    SUM(CASE WHEN status='closed'   THEN 1 ELSE 0 END) AS cerradas,
    SUM(CASE WHEN status='expired'  THEN 1 ELSE 0 END) AS expiradas,
    SUM(CASE WHEN status='active'   THEN 1 ELSE 0 END) AS activas
FROM rag_conversations
WHERE
    tenant_id  = ?                                          -- C4
    AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY
    tenant_id,
    DATE(created_at),
    channel
ORDER BY
    fecha DESC,
    channel;
```

---

### C-6: Buscar Conversaciones por Número de Teléfono

```python
# conv_06_search_by_phone.py
def get_conversations_by_phone(
    tenant_id:    str,    # C4
    phone_number: str,
    limit:        int = 10
) -> list[dict]:
    """
    Recupera historial de conversaciones de un número de teléfono.
    Útil para contexto de cliente recurrente en WhatsApp.
    C4: tenant_id en WHERE con external_id.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    # Normalizar teléfono (quitar +, espacios)
    normalized = phone_number.replace("+","").replace(" ","").strip()

    conn   = get_conn()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(
            """SELECT
                   id,
                   tenant_id,          -- C4
                   channel,
                   external_id,
                   status,
                   total_messages,
                   total_tokens,
                   last_activity,
                   created_at
               FROM rag_conversations
               WHERE
                   tenant_id   = %s    -- C4
                   AND external_id LIKE %s
               ORDER BY last_activity DESC
               LIMIT %s""",
            (tenant_id, f"%{normalized}%", min(limit, 50))   # C4, C1
        )
        return cursor.fetchall()

    finally:
        cursor.close()
        conn.close()
```

---

### C-7: Obtener Chunks RAG Más Utilizados (Analytics)

```sql
-- conv_07_most_used_chunks.sql
-- Qué chunks del RAG son más consultados por los usuarios de un tenant
-- C4: tenant_id en WHERE y en extracción del JSON

SELECT
    m.tenant_id,                        -- C4
    jt.chunk_id,
    rc.text_preview,
    rc.document_id,
    rd.filename,
    COUNT(*)                AS veces_usado,
    ROUND(AVG(jt.score),3)  AS score_promedio
FROM rag_messages m
-- Expandir el array JSON de chunks usados
JOIN JSON_TABLE(
    m.rag_chunks_used,
    '$[*]' COLUMNS (
        chunk_id VARCHAR(36) PATH '$.chunk_id',
        score    FLOAT       PATH '$.score'
    )
) AS jt ON TRUE
JOIN rag_chunks rc
    ON jt.chunk_id = rc.id
    AND rc.tenant_id = m.tenant_id       -- C4: JOIN con tenant_id
JOIN rag_documents rd
    ON rc.document_id = rd.id
    AND rd.tenant_id  = m.tenant_id      -- C4
WHERE
    m.tenant_id   = ?                    -- C4
    AND m.role    = 'assistant'
    AND m.created_at > DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY
    m.tenant_id, jt.chunk_id, rc.text_preview, rc.document_id, rd.filename
ORDER BY veces_usado DESC
LIMIT 20;
```

---

### C-8: Limpiar Mensajes Antiguos (Mantenimiento de Disco - RES-003)

```sql
-- conv_08_purge_old_messages.sql
-- Purgar mensajes de conversaciones cerradas > 90 días
-- C1/RES-003: Liberar espacio en disco
-- C4: tenant_id en TODOS los DELETE

-- PASO 1: Cuánto se va a liberar (siempre verificar antes de borrar)
SELECT
    c.tenant_id,             -- C4
    COUNT(m.id)              AS mensajes_a_purgar,
    ROUND(SUM(LENGTH(m.content)) / 1024 / 1024, 1) AS mb_estimado
FROM rag_messages m
JOIN rag_conversations c
    ON m.conversation_id = c.id
    AND m.tenant_id      = c.tenant_id   -- C4: JOIN con tenant_id
WHERE
    c.tenant_id  = ?                     -- C4
    AND c.status IN ('closed','expired')
    AND c.last_activity < DATE_SUB(NOW(), INTERVAL 90 DAY)
GROUP BY c.tenant_id;

-- PASO 2: DELETE en lotes de 1000 (C1: no lockear la tabla)
DELETE m
FROM rag_messages m
JOIN rag_conversations c
    ON m.conversation_id = c.id
    AND m.tenant_id      = c.tenant_id   -- C4
WHERE
    c.tenant_id  = ?                     -- C4
    AND c.status IN ('closed','expired')
    AND c.last_activity < DATE_SUB(NOW(), INTERVAL 90 DAY)
LIMIT 1000;
-- Repetir hasta ROW_COUNT() = 0

-- PASO 3: Eliminar las conversaciones vacías
DELETE FROM rag_conversations
WHERE
    tenant_id     = ?                    -- C4
    AND status    IN ('closed','expired')
    AND last_activity < DATE_SUB(NOW(), INTERVAL 90 DAY)
    AND total_messages = 0
LIMIT 500;
```

---

### C-9: Estadísticas de Tiempo de Respuesta del RAG

```sql
-- conv_09_rag_latency_stats.sql
-- Métricas de latencia para detectar degradación del sistema
-- C4: tenant_id en WHERE

SELECT
    tenant_id,                                    -- C4
    DATE(created_at)            AS fecha,
    COUNT(*)                    AS respuestas,
    ROUND(AVG(latency_ms))      AS latencia_avg_ms,
    ROUND(MIN(latency_ms))      AS latencia_min_ms,
    ROUND(MAX(latency_ms))      AS latencia_max_ms,
    -- P95: percentil 95 (requiere MySQL 8.0)
    ROUND(
        PERCENTILE_CONT(0.95)
        WITHIN GROUP (ORDER BY latency_ms)
        OVER (PARTITION BY tenant_id, DATE(created_at))
    )                           AS latencia_p95_ms,
    SUM(CASE WHEN latency_ms > 5000 THEN 1 ELSE 0 END) AS respuestas_lentas_5s
FROM rag_messages
WHERE
    tenant_id  = ?               -- C4
    AND role   = 'assistant'
    AND latency_ms IS NOT NULL
    AND created_at > DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY tenant_id, DATE(created_at)
ORDER BY fecha DESC;
```

---

### C-10: Exportar Historial de Conversación Completo

```python
# conv_10_export_conversation.py
def export_conversation_full(
    tenant_id:       str,    # C4
    conversation_id: str
) -> dict:
    """
    Exporta una conversación completa con todos sus mensajes
    y metadata de chunks RAG usados.
    Útil para soporte al cliente y auditoría (C5).
    C4: tenant_id en todas las queries.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    import json
    conn   = get_conn()
    cursor = conn.cursor(dictionary=True)
    try:
        # Metadata de la conversación (C4: verificar ownership)
        cursor.execute(
            """SELECT * FROM rag_conversations
               WHERE id = %s AND tenant_id = %s""",   # C4
            (conversation_id, tenant_id)
        )
        conv = cursor.fetchone()
        if not conv:
            raise ValueError(f"Conversation not found for tenant {tenant_id} (C4)")

        # Mensajes con chunks usados
        cursor.execute(
            """SELECT
                   id, role, content,
                   rag_chunks_used, rag_query,
                   tokens_input, tokens_output,
                   model_used, latency_ms, created_at
               FROM rag_messages
               WHERE conversation_id = %s
                 AND tenant_id       = %s   -- C4
               ORDER BY created_at ASC""",
            (conversation_id, tenant_id)
        )
        messages = cursor.fetchall()

        # Enriquecer con información de chunks (para auditoría)
        for msg in messages:
            if msg.get("rag_chunks_used"):
                chunks_used = json.loads(msg["rag_chunks_used"]) if isinstance(msg["rag_chunks_used"], str) else msg["rag_chunks_used"]
                if chunks_used:
                    chunk_ids = [c["chunk_id"] for c in chunks_used if "chunk_id" in c]
                    if chunk_ids:
                        fmt   = ",".join(["%s"] * len(chunk_ids))
                        cursor.execute(
                            f"""SELECT id, text_preview, document_id
                                FROM rag_chunks
                                WHERE id IN ({fmt})
                                  AND tenant_id = %s""",  # C4
                            (*chunk_ids, tenant_id)
                        )
                        msg["chunk_details"] = cursor.fetchall()

        return {
            "tenant_id":      tenant_id,    # C4
            "conversation":   conv,
            "messages":       messages,
            "total_messages": len(messages),
            "exported_at":    datetime.utcnow().isoformat()
        }

    finally:
        cursor.close()
        conn.close()
```

---

---

## 🐞 10 Errores Comunes y Cómo Subsanarlos

| # | Error Exacto | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso |
|---|---|---|---|---|
| 1 | `IntegrityError: 1451 Cannot delete or update a parent row: a foreign key constraint fails (rag_chunks, CONSTRAINT fk_ragchunk_doc)` | Intentar hacer `DELETE FROM rag_documents` sin borrar primero sus chunks, y la FK no tiene `ON DELETE CASCADE` | `SHOW CREATE TABLE rag_chunks\G` → ver si FK tiene `ON DELETE CASCADE` | 1. Si la tabla fue creada sin CASCADE: `ALTER TABLE rag_chunks DROP FOREIGN KEY fk_ragchunk_doc;`<br>2. Recrear FK: `ALTER TABLE rag_chunks ADD CONSTRAINT fk_ragchunk_doc FOREIGN KEY (document_id) REFERENCES rag_documents(id) ON DELETE CASCADE;`<br>3. O borrar manualmente en orden: `DELETE FROM rag_chunks WHERE document_id=X AND tenant_id=Y; DELETE FROM rag_documents WHERE id=X AND tenant_id=Y;` |
| 2 | `UPDATE` o `DELETE` afecta 0 filas aunque el registro existe | WHERE incluye `tenant_id` incorrecto — registro existe pero para otro tenant (C4 violation silenciosa) | `SELECT id, tenant_id FROM rag_documents WHERE id = 'X';` (sin filtro tenant) | 1. Comparar el tenant_id real del registro vs el que se está usando en el código<br>2. Agregar assertion explícita: `if cursor.rowcount == 0: raise ValueError(f"Not found or wrong tenant_id={tenant_id}")`<br>3. Loguear el tenant_id en cada operación para detectar la fuente del error |
| 3 | `Deadlock found when trying to get lock; try restarting transaction` durante ingestas concurrentes | Dos workers procesando el mismo document_id simultáneamente — `UPDATE status='processing'` compite con `DELETE FROM rag_chunks` | `SHOW ENGINE INNODB STATUS\G` → buscar sección `LATEST DETECTED DEADLOCK` | 1. Agregar retry automático con backoff exponencial: `for attempt in range(3): try: ...; break; except DeadlockError: time.sleep(0.5 * (attempt+1))`<br>2. Usar `SELECT ... FOR UPDATE SKIP LOCKED` para que cada worker tome un documento distinto (Ejemplo I-8)<br>3. Para documentos grandes: serializar con Redis lock key `rag_ingest:{tenant_id}:{document_id}` |
| 4 | `Data too long for column 'text_preview' at row 1` | El texto del chunk supera los 500 chars antes del truncamiento, o el campo es VARCHAR(255) en vez de VARCHAR(500) | `SHOW CREATE TABLE rag_chunks\G` → ver tipo de `text_preview` | 1. Verificar en código: `chunk["text"][:500]` — el slice DEBE estar antes del INSERT<br>2. Si la columna es VARCHAR(255): `ALTER TABLE rag_chunks MODIFY COLUMN text_preview VARCHAR(500);`<br>3. Para emojis WhatsApp (multi-byte): usar `text[:500].encode('utf-8')[:500].decode('utf-8','ignore')` para cortar correctamente |
| 5 | `Lost connection to MySQL server during query` durante INSERT de 5000 chunks | El INSERT batch es demasiado grande para `max_allowed_packet` de MySQL (default 4MB) | `SHOW VARIABLES LIKE 'max_allowed_packet';` | 1. Reducir lote: en el código cambiar batch de 100 a 50 chunks por `executemany()`<br>2. O aumentar el parámetro: en `my.cnf`: `max_allowed_packet = 64M` y reiniciar MySQL<br>3. Agregar reconexión automática: `connect_timeout=10, autoReconnect=True` en el pool |
| 6 | `Table 'mantis_rag_meta.rag_token_usage' doesn't exist` al trackear tokens | Tabla no fue creada, o se conectó a la base de datos equivocada | `SHOW TABLES LIKE 'rag_%';` en la base de datos activa | 1. Verificar base de datos activa: `SELECT DATABASE();`<br>2. Si conecta a la BD incorrecta: revisar variable `MYSQL_DATABASE` en `.env`<br>3. Crear tabla faltante ejecutando el schema completo (sección de tablas de este documento)<br>4. Verificar que el usuario MySQL tiene permisos: `SHOW GRANTS FOR 'mantis_rag'@'localhost';` |
| 7 | Query `SELECT COUNT(*) FROM rag_chunks` tarda 8 segundos en tabla con 2M filas | Full table scan — no usa índice porque el WHERE no incluye `tenant_id` como primer campo del índice compuesto | `EXPLAIN SELECT COUNT(*) FROM rag_chunks WHERE document_id = 'X';` → ver `type: ALL` | 1. SIEMPRE incluir `tenant_id` en el WHERE: `WHERE tenant_id = ? AND document_id = ?`<br>2. Verificar que el índice es compuesto con tenant_id primero: `SHOW INDEX FROM rag_chunks;` — debe tener `idx_tenant_doc` con `Seq_in_index=1` para tenant_id<br>3. Si el índice no existe: `ALTER TABLE rag_chunks ADD INDEX idx_tenant_doc (tenant_id, document_id);` |
| 8 | `JSON_TABLE` retorna 0 filas aunque `rag_chunks_used` tiene datos | El campo `rag_chunks_used` fue guardado como string `"[{...}]"` en vez de JSON nativo | `SELECT id, JSON_TYPE(rag_chunks_used) FROM rag_messages LIMIT 5;` → si retorna `NULL` es string, no JSON | 1. En Python: `json.dumps(lista)` para serializar ANTES del INSERT — verificar que no se está haciendo doble serialización (string de un string)<br>2. Migrar datos existentes: `UPDATE rag_messages SET rag_chunks_used = CAST(rag_chunks_used AS JSON) WHERE JSON_VALID(rag_chunks_used) = 0;`<br>3. Cambiar tipo de columna a `JSON` si actualmente es `TEXT`: `ALTER TABLE rag_messages MODIFY COLUMN rag_chunks_used JSON;` |
| 9 | `rag_audit_log` crece 500MB/semana y el disco llega a 80% (RES-003) | Tabla de audit log sin particionamiento ni purga automática | `SELECT COUNT(*), ROUND(SUM(LENGTH(details_json))/1024/1024,1) AS mb FROM rag_audit_log WHERE tenant_id = ?;` | 1. Agregar cron de purga mensual: `DELETE FROM rag_audit_log WHERE created_at < DATE_SUB(NOW(), INTERVAL 90 DAY) AND tenant_id = ? LIMIT 10000;` (en loop)<br>2. Si la tabla ya existe sin particionamiento: agregar particionamiento manual por año-mes<br>3. Comprimir logs viejos: exportar a JSON con `SELECT INTO OUTFILE` antes de borrar<br>4. Reducir verbosidad: loguear solo `ingest_failed` y `doc_deleted` en prod, no cada chunk |
| 10 | `Incorrect datetime value '0000-00-00 00:00:00'` al insertar documento | MySQL en modo estricto rechaza fechas inválidas — ocurre cuando `processing_started_at` se pasa como `None` en vez de omitirse | `SELECT @@sql_mode;` → verificar si incluye `NO_ZERO_DATE` | 1. En Python: nunca pasar `None` explícito a columnas `DATETIME NOT NULL` — omitir el campo para que tome el `DEFAULT`<br>2. Si la columna es nullable (`DATETIME` sin `NOT NULL`): `None` en Python → `NULL` en MySQL → OK<br>3. O establecer explícitamente: `processing_started_at = datetime.utcnow()` antes del INSERT<br>4. Deshabilitar el modo estricto solo si es absolutamente necesario: evitar en producción |

---

## ✅ Validación SDD y Comandos de Prueba

### Script de Validación Completo

```bash
#!/bin/bash
# validate-mysql-rag-ingestion.sh
# Verifica que el schema y constraints C1-C5 estén correctos
set -euo pipefail

DB="${MYSQL_DATABASE:-mantis_rag_meta}"
MYSQL="docker exec mantis-mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} ${DB} --skip-column-names -e"
PASS=0; FAIL=0

check() {
    local desc="$1"; local query="$2"; local expected="$3"; local constraint="$4"
    result=$($MYSQL "$query" 2>/dev/null | tr -d ' \n' || echo "ERROR")
    if echo "$result" | grep -qP "$expected"; then
        echo "✅ ${constraint}: ${desc}"; ((PASS++))
    else
        echo "❌ ${constraint} FAIL: ${desc} | Obtenido: ${result:0:80}"; ((FAIL++))
    fi
}

TENANT="${1:-test_tenant_001}"
echo "═══ VALIDACIÓN MYSQL RAG INGESTION ═══ tenant: $TENANT"

# C1: Tablas críticas existen
for TABLE in rag_documents rag_chunks rag_conversations rag_messages rag_token_usage rag_audit_log; do
    check "Tabla $TABLE existe" \
        "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='${TABLE}';" \
        "^1$" "C1"
done

# C4: Índice con tenant_id primero en rag_documents
check "idx_tenant_status en rag_documents" \
    "SELECT COUNT(*) FROM information_schema.STATISTICS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='rag_documents' AND INDEX_NAME='idx_tenant_status' AND COLUMN_NAME='tenant_id' AND SEQ_IN_INDEX=1;" \
    "^1$" "C4"

# C4: Índice con tenant_id primero en rag_chunks
check "idx_tenant_doc en rag_chunks" \
    "SELECT COUNT(*) FROM information_schema.STATISTICS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='rag_chunks' AND INDEX_NAME='idx_tenant_doc' AND COLUMN_NAME='tenant_id' AND SEQ_IN_INDEX=1;" \
    "^1$" "C4"

# C4: FK CASCADE en rag_chunks
check "FK ON DELETE CASCADE en rag_chunks" \
    "SELECT DELETE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA='${DB}' AND CONSTRAINT_NAME='fk_ragchunk_doc';" \
    "CASCADE" "C4"

# C5: Tabla de audit log existe y tiene particionamiento
check "rag_audit_log particionada" \
    "SELECT COUNT(*) FROM information_schema.PARTITIONS WHERE TABLE_SCHEMA='${DB}' AND TABLE_NAME='rag_audit_log';" \
    "^[1-9]" "C5"

# C4: No existen queries sin tenant_id (verificar código)
echo ""
echo "─── Verificación C4 en código fuente ───"
if find . -name "*.py" -exec grep -l "rag_documents\|rag_chunks\|rag_messages" {} \; 2>/dev/null | xargs grep -l "SELECT\|UPDATE\|DELETE" 2>/dev/null | xargs grep -L "tenant_id" 2>/dev/null | grep -v "test_\|__pycache__" | head -5; then
    echo "⚠️  Archivos con queries posiblemente sin tenant_id (revisar manualmente)"
    ((FAIL++))
else
    echo "✅ C4: Todos los archivos Python con queries incluyen tenant_id"
    ((PASS++))
fi

echo ""
echo "═══════════════════════════════════════"
echo "RESULTADO: ✅ $PASS pasaron | ❌ $FAIL fallaron"
[ $FAIL -eq 0 ] && echo "🎉 Schema MySQL RAG cumple todos los constraints SDD" && exit 0 || exit 1
```

### Test de Pipeline Completo End-to-End

```python
# test_ingest_pipeline_e2e.py
"""
Test end-to-end del pipeline de ingesta MySQL.
Verifica que el flujo completo funciona sin errores.
Ejecutar antes de cada deploy.
"""
import uuid, time, hashlib, os

def test_full_ingest_pipeline():
    tenant_id = "test_tenant_e2e"
    doc_id    = str(uuid.uuid4())
    content   = "Texto de prueba para test de ingesta RAG. " * 50  # ~2500 chars
    content_hash = hashlib.sha256(content.encode()).hexdigest()

    # FASE 1: Registrar documento
    result = register_document(
        tenant_id=tenant_id, source_type="text",
        source_id=f"test_{doc_id}", filename="test.txt",
        content=content
    )
    assert result["action"]    == "created",    f"Esperado 'created', obtenido: {result['action']}"
    assert result["tenant_id"] == tenant_id,    "C4: tenant_id incorrecto en resultado"
    print(f"✅ Fase 1: Documento registrado - {result['document_id']}")

    # FASE 2: Marcar processing
    mark_document_processing(tenant_id, result["document_id"])
    print("✅ Fase 2: Documento marcado como 'processing'")

    # FASE 3: Insertar chunks simulados
    fake_chunks = [
        {"id": str(uuid.uuid4()), "text": f"Chunk {i} " * 50,
         "chunk_index": i, "token_count": 50}
        for i in range(10)
    ]
    inserted = insert_chunks_batch(tenant_id, result["document_id"], fake_chunks)
    assert inserted == 10, f"Esperado 10 chunks, insertados: {inserted}"
    print(f"✅ Fase 3: {inserted} chunks insertados")

    # FASE 4: Completar
    start = time.time()
    completion = complete_ingestion(tenant_id, result["document_id"], 10, start)
    assert completion["status"]    == "completed", f"Estado incorrecto: {completion['status']}"
    assert completion["tenant_id"] == tenant_id,   "C4: tenant_id incorrecto"
    print(f"✅ Fase 4: Ingesta completada en {completion['duration_ms']}ms")

    # FASE 5: Idempotencia — registrar el mismo documento de nuevo
    result2 = register_document(
        tenant_id=tenant_id, source_type="text",
        source_id=f"test_{doc_id}", filename="test.txt",
        content=content
    )
    assert result2["action"] == "skipped", f"Idempotencia falló: {result2['action']}"
    print("✅ Fase 5: Idempotencia correcta (segundo registro ignorado)")

    # FASE 6: Verificar aislamiento (C4)
    wrong_tenant_result = register_document(
        tenant_id="otro_tenant", source_type="text",
        source_id=f"test_{doc_id}", filename="test.txt",
        content=content
    )
    # Para otro_tenant el mismo source_id NO debe existir
    assert wrong_tenant_result["action"] == "created", "C4: Documento visible desde otro tenant"
    print("✅ Fase 6: Aislamiento multi-tenant correcto (C4)")

    print("\n🎉 Pipeline completo: TODOS LOS TESTS PASARON")

if __name__ == "__main__":
    test_full_ingest_pipeline()
```

---

## 🔗 Referencias Cruzadas

- [[01-RULES/06-MULTITENANCY-RULES.md]] — MT-001 (tenant_id en tablas), MT-003 (filtros), MT-006 (logs)
- [[01-RULES/02-RESOURCE-GUARDRAILS.md]] — RES-001 (RAM 4GB), RES-002 (CPU 1 vCPU), RES-003 (disco 50GB)
- [[01-RULES/05-CODE-PATTERNS-RULES.md]] — PAT-001 (prepared statements), PAT-003 (error handling)
- [[00-CONTEXT/facundo-infrastructure.md]] — VPS-2: MySQL + Qdrant + EspoCRM
- [[02-SKILLS/BASE DE DATOS-RAG/rag-system-updates-all-engines.md]] — Actualizaciones y reemplazo de chunks
- [[02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md]] — Vector store que recibe los IDs generados aquí
- [[02-SKILLS/BASE DE DATOS-RAG/mysql-optimization-4gb-ram.md]] — Tuning del MySQL que corre este schema
- [[02-SKILLS/BASE DE DATOS-RAG/pdf-mistralocr-processing.md]] — Genera el `content` que entra en `register_document()`
- [[02-SKILLS/BASE DE DATOS-RAG/google-drive-qdrant-sync.md]] — `source_type='google_drive'` en `rag_documents`
- [[02-SKILLS/INFRASTRUCTURA/espocrm-setup.md]] — EspoCRM en mismo VPS-2 comparte el MySQL

**Skills pendientes que usan este archivo:**
- `02-SKILLS/AGENTES/whatsapp-rag-openrouter.md` — Llama a `get_or_create_conversation()` y `save_message_with_rag_context()`
- `02-SKILLS/INFRAESTRUCTURA/redis-session-management.md` — Buffer temporal antes de persistir en `rag_messages`
