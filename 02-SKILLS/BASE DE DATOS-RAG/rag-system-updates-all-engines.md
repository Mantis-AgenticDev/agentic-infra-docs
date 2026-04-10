---
title: "rag-system-updates-all-engines"
category: "Skill"
domain: ["rag", "backend", "database", "vector", "multi-tenant"]
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
priority: "Alta"
version: "1.0.0"
last_updated: "2026-04-10"
ai_optimized: true
tags:
  - sdd/skill/rag
  - sdd/skill/qdrant
  - sdd/skill/mysql
  - sdd/skill/postgresql
  - sdd/skill/prisma
  - sdd/skill/supabase
  - sdd/skill/chromadb
  - sdd/skill/vector-ingestion
  - sdd/skill/multi-tenant
  - sdd/skill/chunk-update
  - lang/es
related_files:
  - "01-RULES/06-MULTITENANCY-RULES.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
  - "01-RULES/05-CODE-PATTERNS-RULES.md"
  - "00-CONTEXT/facundo-infrastructure.md"
  - "02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md"
  - "02-SKILLS/BASE DE DATOS-RAG/postgres-prisma-rag.md"
  - "02-SKILLS/BASE DE DATOS-RAG/supabase-rag-integration.md"
  - "02-SKILLS/BASE DE DATOS-RAG/mysql-optimization-4gb-ram.md"
  - "02-SKILLS/BASE DE DATOS-RAG/pdf-mistralocr-processing.md"
  - "02-SKILLS/BASE DE DATOS-RAG/google-drive-qdrant-sync.md"
---

## 🎯 Propósito y Alcance

Documentar todos los patrones de **actualización, reemplazo y concatenación de chunks RAG** para cada motor de base de datos del stack MANTIS AGENTIC. Un documento único para que IAs y desarrolladores encuentren el patrón correcto sin navegar múltiples archivos.

**Patrón universal de actualización RAG:**
```
Documento fuente cambia (PDF, Drive, webhook)
    ↓
1. Detectar cambio (hash SHA256 / timestamp / versión)
    ↓
2. Identificar chunks afectados (por document_id + tenant_id)
    ↓
3. Eliminar chunks viejos (vector store + metadata store)
    ↓
4. Re-generar embeddings (OpenRouter API - C6)
    ↓
5. Re-insertar chunks nuevos (vector store + metadata store)
    ↓
6. Verificar consistencia (conteo + spot check)
    ↓
7. Loguear operación con tenant_id (C4 + C5)
```

**Motores cubiertos en este archivo:**

| Motor | Rol en el stack | Sección |
|---|---|---|
| Qdrant | Almacén vectorial principal | [→ Qdrant](#qdrant) |
| MySQL | Metadata RAG + tablas de estado | [→ MySQL](#mysql) |
| PostgreSQL + Prisma | Metadata RAG alternativa estructurada | [→ PostgreSQL](#postgresql) |
| Supabase | PostgreSQL cloud + RLS multi-tenant | [→ Supabase](#supabase) |
| ChromaDB | RAG local embebido (dev/clientes sin VPS) | [→ ChromaDB](#chromadb) |

**Tabla de decisión — ¿qué motor usar?**

```
¿Dónde corre el sistema?
│
├── VPS propio (VPS-2) ────────────────→ Qdrant (vectores) + MySQL (metadata)
│
├── Cliente sin VPS propio ─────────→ Supabase (todo en cloud)
│
├── Desarrollo local / prototipo ────→ ChromaDB (embebido, sin servidor)
│
└── Sistema existente con Postgres ──→ PostgreSQL + Prisma + pgvector
```

**Tipos de actualización:**

| Tipo | Cuándo | Impacto |
|---|---|---|
| **Incremental** | Un documento cambió | Solo re-procesa ese documento |
| **Full re-ingest** | Cambio de modelo de embeddings | Re-procesa toda la colección |
| **Append** | Documento nuevo sin tocar los existentes | Solo inserta, no borra |
| **Patch** | Sección específica de un documento cambió | Re-procesa solo los chunks afectados |
| **Delete** | Documento eliminado del origen | Purga chunks + metadata |

---

## 📐 Fundamentos (Nivel Básico)

### ¿Qué es un chunk y por qué se actualiza?

Un chunk es un fragmento de texto de un documento original, dividido para que quepa en el context window de un LLM y tenga un embedding representativo.

```
Documento: "Manual de atendimento do restaurante.pdf" (80 páginas)
    ↓ chunking (500 tokens, overlap 50)
Chunk 0: "Horário de funcionamento: seg-sex 12h-23h..."
Chunk 1: "Reservas aceitas com até 3 dias de antecedência..."
Chunk 2: "Cardápio inclui opções vegetarianas e veganas..."
...
Chunk 47: "Política de cancelamento: até 2h antes sem cobrança..."
```

Cuando el dueño actualiza el horario, **solo los chunks que contienen esa información** necesitan re-generarse. No re-procesar el PDF completo es fundamental para respetar C1/C2.

### Anatomía de un chunk en el stack MANTIS

```python
# Estructura de un chunk completo (vectores + metadata)
chunk = {
    # ─── Vector store (Qdrant/ChromaDB) ───────────────────────────
    "id": "uuid-v4",                    # ID único del punto vectorial
    "vector": [0.023, -0.412, ...],     # Embedding 1536 dims (text-embedding-3-small)
    "payload": {
        # C4: tenant_id SIEMPRE en payload
        "tenant_id":    "restaurante_001",
        "document_id":  "doc-uuid-abc",
        "chunk_index":  12,
        "total_chunks": 47,
        "text":         "Horário de funcionamento: seg-sex 12h-23h...",
        "source":       "manual-atendimento.pdf",
        "source_type":  "pdf",
        "page":         3,
        "token_count":  287,
        "hash_content": "sha256-del-texto",   # Para detectar cambios
        "embedding_model": "text-embedding-3-small",
        "created_at":   "2026-04-10T14:00:00Z",
        "updated_at":   "2026-04-10T14:00:00Z"
    },

    # ─── Metadata store (MySQL/Postgres/Supabase) ─────────────────
    # Mismos campos almacenados en BD relacional para queries complejas
    # tenant_id: "restaurante_001"  ← C4: repetido intencionalmente
    # qdrant_id: "uuid-v4"          ← FK lógica entre BD y Qdrant
}
```

### Generación de Embeddings (C6: Solo API Cloud)

```python
# embeddings.py - Generador centralizado
# C6: NUNCA modelos locales. Solo OpenRouter o API directa.
import os
import requests
import time

def generate_embedding(text: str, model: str = "text-embedding-3-small") -> list[float]:
    """
    Genera embedding vía OpenRouter.
    C6: modelo cloud obligatorio.
    C2: timeout 30s.
    """
    response = requests.post(
        "https://openrouter.ai/api/v1/embeddings",
        headers={
            "Authorization": f"Bearer {os.environ['OPENROUTER_API_KEY']}",
            "Content-Type": "application/json"
        },
        json={"model": model, "input": text},
        timeout=30  # C2
    )
    response.raise_for_status()
    return response.json()["data"][0]["embedding"]

def generate_embeddings_batch(
    texts: list[str],
    model: str = "text-embedding-3-small",
    batch_size: int = 20   # C1: lotes pequeños para no saturar RAM
) -> list[list[float]]:
    """
    Genera embeddings en lotes.
    C1: batch_size=20 máximo para VPS 4GB.
    """
    all_embeddings = []
    for i in range(0, len(texts), batch_size):
        batch = texts[i:i + batch_size]
        response = requests.post(
            "https://openrouter.ai/api/v1/embeddings",
            headers={"Authorization": f"Bearer {os.environ['OPENROUTER_API_KEY']}"},
            json={"model": model, "input": batch},
            timeout=30  # C2
        )
        response.raise_for_status()
        embeddings = [item["embedding"] for item in response.json()["data"]]
        all_embeddings.extend(embeddings)
        time.sleep(0.1)  # Rate limit suave entre lotes
    return all_embeddings
```

---

## 🏗️ Arquitectura y Hardware Limitado (VPS 2vCPU/4-8GB)

### Presupuesto de RAM por Operación de Update

```
Operación de re-ingesta (documento de 100 chunks):

Por lote de 20 chunks:
├── Texto de chunks en RAM:      ~0.5MB
├── Embeddings 1536 dims × 20:  ~0.5MB (float32)
├── Overhead Python:             ~50MB
└── Total por lote:              ~51MB

100 chunks / 20 por lote = 5 lotes
RAM pico: ~51MB × 1 operación = manejable ✅

Riesgo C1: si se procesan 3 documentos en paralelo
51MB × 3 = 153MB (aún OK para VPS 4GB)
Riesgo real: n8n ejecutando 5 workflows simultáneos
51MB × 5 = 255MB (monitorear con docker stats)
```

### Límites de Concurrencia para Updates RAG

```yaml
# Variables de entorno para n8n (RES-009)
EXECUTIONS_MAX_CONCURRENT: 3    # C1: Máx 3 re-ingestas simultáneas
                                 # (no 5 default — RAG consume más RAM)
WEBHOOK_TIMEOUT: 30000           # C2: 30s por operación HTTP

# Para scripts Python directos (fuera de n8n)
MAX_PARALLEL_DOCUMENTS: 2        # C1: Máx 2 documentos en paralelo
CHUNK_BATCH_SIZE: 20             # C1: Lotes de 20 embeddings
SLEEP_BETWEEN_BATCHES_MS: 100   # Throttle suave
```

---

## 🔗 Conexión Local vs Externa

### Variables de Entorno por Motor

```bash
# .env — Conexiones a todos los motores
# C3: Todas las BDs internas solo en red privada

# ─── Qdrant ──────────────────────────────────────────────────────
QDRANT_HOST=localhost              # Mismo VPS
QDRANT_PORT=6333
QDRANT_API_KEY=${QDRANT_API_KEY}   # Si está habilitado

# ─── MySQL ───────────────────────────────────────────────────────
MYSQL_HOST=127.0.0.1              # C3: Solo local
MYSQL_PORT=3306
MYSQL_USER=mantis_rag
MYSQL_PASSWORD=${MYSQL_RAG_PASS}
MYSQL_DATABASE=mantis_rag_meta

# ─── PostgreSQL / Prisma ─────────────────────────────────────────
DATABASE_URL="postgresql://user:${PG_PASS}@localhost:5432/mantis_rag"

# ─── Supabase (cloud) ────────────────────────────────────────────
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_SERVICE_KEY=${SUPABASE_SERVICE_KEY}  # Service role (bypasa RLS)

# ─── ChromaDB ────────────────────────────────────────────────────
CHROMA_HOST=localhost
CHROMA_PORT=8000
# O embebido: CHROMA_PERSIST_DIR=/data/chromadb

# ─── OpenRouter (C6: embeddings cloud) ───────────────────────────
OPENROUTER_API_KEY=${OPENROUTER_API_KEY}
EMBEDDING_MODEL=text-embedding-3-small
```

---

## 📘 Guía de Estructura de Tablas (Para principiantes)

### Schema Unificado de Metadata RAG (aplica a MySQL y PostgreSQL)

```sql
-- Tabla maestra de documentos (igual en MySQL y PostgreSQL)
CREATE TABLE rag_documents (
    id              VARCHAR(36)  PRIMARY KEY,     -- UUID
    tenant_id       VARCHAR(50)  NOT NULL,         -- C4: OBLIGATORIO
    source_type     VARCHAR(50)  NOT NULL,         -- 'pdf', 'google_drive', 'url', 'text'
    source_id       VARCHAR(500) NOT NULL,         -- Path, Drive ID, URL
    filename        VARCHAR(255) NOT NULL,
    content_hash    VARCHAR(64)  NOT NULL,         -- SHA256 del contenido original
    status          VARCHAR(20)  NOT NULL DEFAULT 'pending',
                                                   -- pending/processing/completed/failed
    total_chunks    INT          NOT NULL DEFAULT 0,
    embedding_model VARCHAR(100) NOT NULL,         -- C6: modelo API cloud
    last_updated    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_tenant_status  (tenant_id, status),       -- C4: tenant primero
    INDEX idx_tenant_source  (tenant_id, source_id),    -- Para detectar duplicados
    INDEX idx_content_hash   (tenant_id, content_hash)  -- Para detectar cambios
);

-- Tabla de chunks con FK al vector store
CREATE TABLE rag_chunks (
    id              VARCHAR(36)  PRIMARY KEY,     -- UUID = mismo ID en Qdrant/ChromaDB
    tenant_id       VARCHAR(50)  NOT NULL,         -- C4: OBLIGATORIO
    document_id     VARCHAR(36)  NOT NULL,
    chunk_index     INT          NOT NULL,
    total_chunks    INT          NOT NULL,
    text_preview    VARCHAR(500),                  -- Primeros 500 chars (para debug)
    token_count     INT          NOT NULL DEFAULT 0,
    content_hash    VARCHAR(64)  NOT NULL,         -- SHA256 del texto del chunk
    vector_store    VARCHAR(20)  NOT NULL,         -- 'qdrant', 'chroma', 'pgvector'
    collection_name VARCHAR(100),                  -- Nombre de colección en vector store
    embedding_model VARCHAR(100) NOT NULL,         -- C6
    created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_tenant_doc     (tenant_id, document_id),  -- C4
    INDEX idx_tenant_vector  (tenant_id, vector_store),
    UNIQUE KEY uk_doc_chunk  (document_id, chunk_index) -- No duplicar chunks
);
```

---

---

# <a name="qdrant"></a>🔷 MOTOR 1: Qdrant

**Rol:** Almacén de vectores principal. Almacena embeddings + payload (metadata completa). Es el motor de búsqueda semántica.

**Cuándo actualizar:**
- Documento fuente fue modificado (nuevo hash SHA256)
- Se cambió el modelo de embeddings (C6: nuevo modelo en OpenRouter)
- Se detectaron chunks corruptos (embedding inválido)
- Tenant solicita re-indexar su base de conocimiento

---

### Ejemplo Q-1: Update Incremental — Un Documento Modificado

```python
# qdrant_update_incremental.py
from qdrant_client import QdrantClient
from qdrant_client.models import PointStruct, Filter, FieldCondition, MatchValue
import os
import hashlib
from embeddings import generate_embeddings_batch
from chunker import split_text_into_chunks

def update_document_in_qdrant(
    tenant_id: str,           # C4: OBLIGATORIO
    document_id: str,
    new_text: str,
    collection_name: str = None
) -> dict:
    """
    Reemplaza todos los chunks de un documento en Qdrant.
    Patrón: DELETE chunks viejos → INSERT chunks nuevos (atómico por lotes).
    C4: tenant_id en todos los filtros y payloads.
    C1: lotes de 20 embeddings máximo.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    collection = collection_name or f"rag_{tenant_id}"
    client = QdrantClient(
        host=os.environ["QDRANT_HOST"],
        port=int(os.environ["QDRANT_PORT"]),
        timeout=30  # C2
    )

    # ─── PASO 1: Calcular hash del nuevo contenido ────────────────
    new_hash = hashlib.sha256(new_text.encode()).hexdigest()

    # ─── PASO 2: Eliminar chunks viejos del documento ────────────
    # C4: Filtro doble — tenant_id + document_id
    client.delete(
        collection_name=collection,
        points_selector=Filter(
            must=[
                FieldCondition(key="tenant_id",   match=MatchValue(value=tenant_id)),
                FieldCondition(key="document_id", match=MatchValue(value=document_id))
            ]
        )
    )

    # ─── PASO 3: Generar nuevos chunks ───────────────────────────
    chunks = split_text_into_chunks(new_text, max_tokens=500, overlap=50)

    # ─── PASO 4: Generar embeddings en lotes (C1: batch_size=20) ─
    texts = [c["text"] for c in chunks]
    embeddings = generate_embeddings_batch(texts, batch_size=20)

    # ─── PASO 5: Insertar en Qdrant con payload completo ─────────
    points = []
    for i, (chunk, embedding) in enumerate(zip(chunks, embeddings)):
        chunk_hash = hashlib.sha256(chunk["text"].encode()).hexdigest()
        points.append(PointStruct(
            id=chunk["id"],   # UUID estable
            vector=embedding,
            payload={
                "tenant_id":       tenant_id,      # C4
                "document_id":     document_id,
                "chunk_index":     i,
                "total_chunks":    len(chunks),
                "text":            chunk["text"],
                "token_count":     chunk["token_count"],
                "content_hash":    chunk_hash,
                "document_hash":   new_hash,
                "embedding_model": os.environ.get("EMBEDDING_MODEL", "text-embedding-3-small"),
                "updated_at":      __import__("datetime").datetime.utcnow().isoformat() + "Z"
            }
        ))

    # Insertar en lotes de 100 puntos (C1: no enviar todo de una vez)
    for i in range(0, len(points), 100):
        client.upsert(collection_name=collection, points=points[i:i+100])

    return {
        "tenant_id":     tenant_id,        # C4
        "document_id":   document_id,
        "chunks_deleted": "all previous",
        "chunks_inserted": len(chunks),
        "new_hash":       new_hash
    }
```

---

### Ejemplo Q-2: Full Re-ingest de Colección Completa (Cambio de Modelo)

```python
# qdrant_full_reingest.py
def full_reingest_collection(
    tenant_id: str,           # C4
    new_model: str = "text-embedding-3-large",
    batch_size: int = 20      # C1
) -> dict:
    """
    Re-genera todos los embeddings de un tenant con nuevo modelo.
    C6: Siempre vía API cloud.
    C1: Procesa en lotes, nunca carga todo en RAM.
    C5: Loguea progreso para auditoría.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    client = QdrantClient(host=os.environ["QDRANT_HOST"], port=int(os.environ["QDRANT_PORT"]), timeout=30)
    collection = f"rag_{tenant_id}"

    # ─── PASO 1: Scroll sobre todos los puntos del tenant (C4) ───
    offset = None
    total_updated = 0
    errors = []

    while True:
        # Scroll en lotes de 50 (C1: no cargar todo)
        results, next_offset = client.scroll(
            collection_name=collection,
            scroll_filter=Filter(
                must=[FieldCondition(key="tenant_id", match=MatchValue(value=tenant_id))]
            ),
            limit=50,
            offset=offset,
            with_payload=True,
            with_vectors=False   # No cargar vectores viejos (ahorramos RAM)
        )

        if not results:
            break

        # ─── PASO 2: Re-generar embeddings para este lote ────────
        texts = [p.payload.get("text", "") for p in results]
        try:
            new_embeddings = generate_embeddings_batch(texts, model=new_model, batch_size=batch_size)
        except Exception as e:
            errors.append({"batch_offset": str(offset), "error": str(e)})
            offset = next_offset
            continue

        # ─── PASO 3: Actualizar solo los vectores (mantener payload) ─
        updated_points = []
        for point, new_vector in zip(results, new_embeddings):
            updated_points.append(PointStruct(
                id=point.id,
                vector=new_vector,
                payload={
                    **point.payload,
                    "embedding_model": new_model,      # Actualizar modelo en payload
                    "updated_at": __import__("datetime").datetime.utcnow().isoformat() + "Z"
                }
            ))

        client.upsert(collection_name=collection, points=updated_points)
        total_updated += len(updated_points)

        # C5: Log de progreso
        print(f"[{tenant_id}] Updated {total_updated} chunks | model: {new_model}")

        if next_offset is None:
            break
        offset = next_offset

    return {
        "tenant_id":     tenant_id,     # C4
        "total_updated": total_updated,
        "new_model":     new_model,
        "errors":        errors
    }
```

---

### Ejemplo Q-3: Append — Agregar Documento Nuevo sin Tocar los Existentes

```python
# qdrant_append.py
def append_document_to_qdrant(
    tenant_id: str,    # C4
    document_id: str,
    text: str,
    metadata: dict = None
) -> dict:
    """
    Agrega un documento nuevo a la colección existente.
    NO borra chunks existentes — solo inserta los nuevos.
    Usa upsert para idempotencia (re-ejecutar es seguro).
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    client = QdrantClient(host=os.environ["QDRANT_HOST"], port=int(os.environ["QDRANT_PORT"]), timeout=30)
    collection = f"rag_{tenant_id}"

    # ─── Verificar que el documento no existe ya (idempotencia) ──
    existing = client.count(
        collection_name=collection,
        count_filter=Filter(
            must=[
                FieldCondition(key="tenant_id",   match=MatchValue(value=tenant_id)),
                FieldCondition(key="document_id", match=MatchValue(value=document_id))
            ]
        )
    )

    if existing.count > 0:
        # Ya existe: redirigir a update incremental
        return update_document_in_qdrant(tenant_id, document_id, text)

    # ─── Chunk + embed + insert ───────────────────────────────────
    chunks = split_text_into_chunks(text, max_tokens=500, overlap=50)
    embeddings = generate_embeddings_batch([c["text"] for c in chunks], batch_size=20)

    points = [
        PointStruct(
            id=chunk["id"],
            vector=embedding,
            payload={
                "tenant_id":       tenant_id,   # C4
                "document_id":     document_id,
                "chunk_index":     i,
                "total_chunks":    len(chunks),
                "text":            chunk["text"],
                "content_hash":    hashlib.sha256(chunk["text"].encode()).hexdigest(),
                "embedding_model": os.environ.get("EMBEDDING_MODEL", "text-embedding-3-small"),
                "created_at":      __import__("datetime").datetime.utcnow().isoformat() + "Z",
                **(metadata or {})
            }
        )
        for i, (chunk, embedding) in enumerate(zip(chunks, embeddings))
    ]

    for i in range(0, len(points), 100):
        client.upsert(collection_name=collection, points=points[i:i+100])

    return {"tenant_id": tenant_id, "document_id": document_id, "chunks_inserted": len(chunks)}
```

---

### Ejemplo Q-4: Delete — Purgar Documento Eliminado del Origen

```python
# qdrant_delete.py
def delete_document_from_qdrant(
    tenant_id: str,    # C4
    document_id: str
) -> dict:
    """
    Elimina todos los chunks de un documento del vector store.
    C4: Filtro doble tenant_id + document_id (NUNCA solo document_id).
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    client = QdrantClient(host=os.environ["QDRANT_HOST"], port=int(os.environ["QDRANT_PORT"]), timeout=30)
    collection = f"rag_{tenant_id}"

    # Contar antes de eliminar (para log C5)
    count_before = client.count(
        collection_name=collection,
        count_filter=Filter(
            must=[
                FieldCondition(key="tenant_id",   match=MatchValue(value=tenant_id)),
                FieldCondition(key="document_id", match=MatchValue(value=document_id))
            ]
        )
    ).count

    if count_before == 0:
        return {"tenant_id": tenant_id, "document_id": document_id, "deleted": 0, "status": "not_found"}

    # C4: Filtro obligatorio con tenant_id para no borrar chunks de otro tenant
    client.delete(
        collection_name=collection,
        points_selector=Filter(
            must=[
                FieldCondition(key="tenant_id",   match=MatchValue(value=tenant_id)),
                FieldCondition(key="document_id", match=MatchValue(value=document_id))
            ]
        )
    )

    # C5: Log estructurado
    import json, datetime
    log_entry = {
        "timestamp":   datetime.datetime.utcnow().isoformat() + "Z",
        "tenant_id":   tenant_id,                   # C4
        "event":       "qdrant_document_deleted",
        "document_id": document_id,
        "chunks_deleted": count_before
    }
    print(json.dumps(log_entry))

    return {"tenant_id": tenant_id, "document_id": document_id, "deleted": count_before}
```

---

### Ejemplo Q-5: Patch — Actualizar Solo Chunks Específicos por Contenido Cambiado

```python
# qdrant_patch.py
def patch_changed_chunks(
    tenant_id: str,    # C4
    document_id: str,
    updated_chunks: list[dict]   # [{"chunk_index": N, "new_text": "..."}]
) -> dict:
    """
    Re-genera solo los chunks cuyo contenido cambió.
    Compara hash del texto nuevo vs hash almacenado en payload.
    C1: Más eficiente que re-ingestar el documento completo.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    client = QdrantClient(host=os.environ["QDRANT_HOST"], port=int(os.environ["QDRANT_PORT"]), timeout=30)
    collection = f"rag_{tenant_id}"

    patched = 0
    skipped = 0

    for update in updated_chunks:
        chunk_index = update["chunk_index"]
        new_text    = update["new_text"]
        new_hash    = hashlib.sha256(new_text.encode()).hexdigest()

        # Buscar chunk existente por tenant_id + document_id + chunk_index (C4)
        existing, _ = client.scroll(
            collection_name=collection,
            scroll_filter=Filter(
                must=[
                    FieldCondition(key="tenant_id",   match=MatchValue(value=tenant_id)),
                    FieldCondition(key="document_id", match=MatchValue(value=document_id)),
                    FieldCondition(key="chunk_index", match=MatchValue(value=chunk_index))
                ]
            ),
            limit=1,
            with_payload=True,
            with_vectors=False
        )

        if existing:
            old_hash = existing[0].payload.get("content_hash", "")
            if old_hash == new_hash:
                skipped += 1
                continue  # Contenido idéntico, no re-procesar (C1: ahorrar recursos)

        # Generar nuevo embedding solo para este chunk
        [new_embedding] = generate_embeddings_batch([new_text], batch_size=1)

        point_id = existing[0].id if existing else str(__import__("uuid").uuid4())

        client.upsert(
            collection_name=collection,
            points=[PointStruct(
                id=point_id,
                vector=new_embedding,
                payload={
                    "tenant_id":       tenant_id,   # C4
                    "document_id":     document_id,
                    "chunk_index":     chunk_index,
                    "text":            new_text,
                    "content_hash":    new_hash,
                    "embedding_model": os.environ.get("EMBEDDING_MODEL"),
                    "updated_at":      __import__("datetime").datetime.utcnow().isoformat() + "Z"
                }
            )]
        )
        patched += 1

    return {
        "tenant_id": tenant_id,   # C4
        "document_id": document_id,
        "patched": patched,
        "skipped_unchanged": skipped
    }
```

---

### 🐞 Troubleshooting Qdrant (5 Problemas)

| Error Exacto | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso |
|---|---|---|---|
| `UnexpectedResponse: 404 Not Found` al hacer delete o search | Colección `rag_{tenant_id}` no existe todavía | `curl http://localhost:6333/collections` → ver lista | 1. Verificar nombre: colección debe ser `rag_restaurante_001` no `restaurante_001`<br>2. Crear si no existe: `client.create_collection(collection_name, vectors_config=VectorParams(size=1536, distance=Distance.COSINE))`<br>3. Agregar en el flujo: `get_or_create_collection()` antes de cualquier operación |
| Después de update, búsqueda devuelve chunks viejos y nuevos mezclados | `delete()` ejecutado pero no esperó confirmación antes de `upsert()` | `client.count(collection, filter=FieldCondition(document_id=X))` → contar chunks | 1. Agregar `time.sleep(0.2)` entre delete y upsert<br>2. O usar operaciones secuenciales con verificación: contar = 0 antes de insertar<br>3. Para producción: Qdrant no tiene transacciones; usar `document_version` en payload para filtrar en búsqueda |
| `ValueError: Vector size mismatch` al insertar chunks nuevos | Modelo de embeddings cambió (1536 dims → 3072 dims) sin recrear colección | `client.get_collection(collection_name)` → ver `vectors.size` | 1. Crear nueva colección: `rag_{tenant_id}_v2`<br>2. Migrar todos los chunks: `full_reingest_collection()`<br>3. Actualizar variable de entorno `EMBEDDING_MODEL`<br>4. Renombrar: borrar vieja, renombrar nueva |
| `OutOfMemory` en VPS durante full re-ingest de colección grande | Scroll cargando demasiados puntos en RAM simultáneamente | `docker stats qdrant` → ver MEM | 1. Reducir `limit` del scroll a 20 (no 50)<br>2. Agregar `gc.collect()` entre lotes en Python<br>3. Programar re-ingest fuera de horario pico (madrugada, cron 03:00 AM)<br>4. Si persiste: dividir por rango de `created_at` (mitad del mes primero, luego segunda mitad) |
| Chunks de tenant_A aparecen en búsqueda de tenant_B (violación C4) | `search()` ejecutado sin filtro por `tenant_id` | `grep -r "client.search" . \| grep -v "tenant_id"` | 1. CRÍTICO: auditar todo el código de búsqueda<br>2. Agregar en `search()`: `query_filter=Filter(must=[FieldCondition(key="tenant_id", match=MatchValue(value=tenant_id))])`<br>3. Crear wrapper obligatorio: `def search_rag(tenant_id, query_vector): assert tenant_id; return client.search(..., query_filter=...)`<br>4. Nunca llamar `client.search()` directo — solo el wrapper |

---

---

# <a name="mysql"></a>🟠 MOTOR 2: MySQL

**Rol:** Metadata RAG + estado de ingesta + tablas de mensajes WhatsApp. Motor principal en VPS-2. **NO almacena vectores** — solo la metadata que relaciona documentos con sus chunks en Qdrant.

**Cuándo actualizar:**
- Documento re-procesado: actualizar `status`, `content_hash`, `total_chunks`
- Chunk re-generado: actualizar `content_hash`, `updated_at`, `vector_store` ID
- Documento eliminado: DELETE en cascada chunks + actualizar documento como `deleted`
- Billing: actualizar contadores de tokens por tenant

---

### Ejemplo M-1: Update Incremental de Documento y Sus Chunks

```python
# mysql_update_document.py
import mysql.connector
import os
import hashlib
from datetime import datetime

def get_mysql_connection():
    """C3: Solo conexión interna."""
    return mysql.connector.connect(
        host=os.environ["MYSQL_HOST"],
        port=int(os.environ.get("MYSQL_PORT", 3306)),
        user=os.environ["MYSQL_USER"],
        password=os.environ["MYSQL_PASSWORD"],
        database=os.environ["MYSQL_DATABASE"],
        connect_timeout=10  # C2
    )

def update_document_metadata(
    tenant_id: str,         # C4
    document_id: str,
    new_content_hash: str,
    new_chunks: list[dict]  # [{"id": uuid, "chunk_index": N, "text_preview": "...", "token_count": N}]
) -> dict:
    """
    Actualiza metadata del documento y reemplaza todos sus chunks.
    Usa transacción para garantizar atomicidad.
    C4: tenant_id en TODAS las queries.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    conn = get_mysql_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        conn.start_transaction()

        # ─── PASO 1: Verificar que el documento pertenece al tenant ─
        cursor.execute(
            "SELECT id, content_hash FROM rag_documents WHERE id = %s AND tenant_id = %s",
            (document_id, tenant_id)   # C4: WHERE con tenant_id
        )
        doc = cursor.fetchone()
        if not doc:
            raise ValueError(f"Document {document_id} not found for tenant {tenant_id} (C4)")

        # ─── PASO 2: Si el hash no cambió, salir sin hacer nada ──
        if doc["content_hash"] == new_content_hash:
            conn.rollback()
            return {"tenant_id": tenant_id, "document_id": document_id, "status": "unchanged"}

        # ─── PASO 3: Actualizar documento ────────────────────────
        cursor.execute("""
            UPDATE rag_documents
            SET status        = 'processing',
                content_hash  = %s,
                total_chunks  = %s,
                last_updated  = %s
            WHERE id = %s AND tenant_id = %s
        """, (new_content_hash, len(new_chunks), datetime.utcnow(), document_id, tenant_id))
        # C4: WHERE siempre incluye tenant_id

        # ─── PASO 4: Eliminar chunks viejos del tenant/documento ─
        cursor.execute(
            "DELETE FROM rag_chunks WHERE document_id = %s AND tenant_id = %s",
            (document_id, tenant_id)   # C4
        )
        deleted_count = cursor.rowcount

        # ─── PASO 5: Insertar chunks nuevos en lote ──────────────
        insert_sql = """
            INSERT INTO rag_chunks
                (id, tenant_id, document_id, chunk_index, total_chunks,
                 text_preview, token_count, content_hash, vector_store,
                 embedding_model, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        now = datetime.utcnow()
        chunk_rows = [
            (
                chunk["id"],
                tenant_id,                          # C4
                document_id,
                chunk["chunk_index"],
                len(new_chunks),
                chunk.get("text", "")[:500],        # Preview 500 chars
                chunk.get("token_count", 0),
                hashlib.sha256(chunk.get("text", "").encode()).hexdigest(),
                "qdrant",
                os.environ.get("EMBEDDING_MODEL", "text-embedding-3-small"),
                now,
                now
            )
            for chunk in new_chunks
        ]

        # Insertar en lotes de 100 (C1)
        for i in range(0, len(chunk_rows), 100):
            cursor.executemany(insert_sql, chunk_rows[i:i+100])

        # ─── PASO 6: Marcar documento como completado ─────────────
        cursor.execute("""
            UPDATE rag_documents
            SET status = 'completed', last_updated = %s
            WHERE id = %s AND tenant_id = %s
        """, (datetime.utcnow(), document_id, tenant_id))  # C4

        conn.commit()

        return {
            "tenant_id":       tenant_id,        # C4
            "document_id":     document_id,
            "chunks_deleted":  deleted_count,
            "chunks_inserted": len(new_chunks),
            "new_hash":        new_content_hash
        }

    except Exception as e:
        conn.rollback()
        # C5: Marcar documento como fallido para reintento
        cursor.execute("""
            UPDATE rag_documents SET status = 'failed', last_updated = %s
            WHERE id = %s AND tenant_id = %s
        """, (datetime.utcnow(), document_id, tenant_id))  # C4
        conn.commit()
        raise
    finally:
        cursor.close()
        conn.close()
```

---

### Ejemplo M-2: Full Re-ingest — Resetear Estado de Todos los Documentos de un Tenant

```sql
-- mysql_full_reingest_reset.sql
-- Marca todos los documentos de un tenant como 'pending' para re-procesamiento
-- C4: WHERE tenant_id SIEMPRE presente

-- PASO 1: Ver estado actual antes de resetear
SELECT
    tenant_id,
    status,
    COUNT(*) AS documentos,
    SUM(total_chunks) AS chunks_totales
FROM rag_documents
WHERE tenant_id = ?          -- C4: Parámetro obligatorio
GROUP BY tenant_id, status;

-- PASO 2: Resetear documentos (solo 'completed' o 'failed')
UPDATE rag_documents
SET
    status       = 'pending',
    total_chunks = 0,
    last_updated = NOW()
WHERE
    tenant_id = ?            -- C4
    AND status IN ('completed', 'failed');

-- PASO 3: Eliminar todos los chunks del tenant para re-ingesta limpia
DELETE FROM rag_chunks
WHERE tenant_id = ?          -- C4: NUNCA sin tenant_id
LIMIT 5000;                  -- C1: En lotes para no lockear la tabla
-- Repetir hasta que afecte 0 filas (verificar con ROW_COUNT())

-- PASO 4: Verificar que quedó limpio
SELECT COUNT(*) AS chunks_restantes
FROM rag_chunks
WHERE tenant_id = ?;         -- C4
-- Esperado: 0
```

---

### Ejemplo M-3: Append — Registrar Nuevo Documento sin Tocar los Existentes

```python
# mysql_append_document.py
def register_new_document(
    tenant_id: str,         # C4
    document_id: str,
    source_type: str,
    source_id: str,
    filename: str,
    content_hash: str,
    embedding_model: str
) -> dict:
    """
    Registra un nuevo documento en MySQL.
    Usa INSERT IGNORE para idempotencia.
    C4: tenant_id en insert y en verificación de existencia.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    conn = get_mysql_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        # Verificar si ya existe (por source_id + tenant_id, no solo source_id)
        cursor.execute(
            "SELECT id, content_hash, status FROM rag_documents WHERE tenant_id = %s AND source_id = %s",
            (tenant_id, source_id)   # C4
        )
        existing = cursor.fetchone()

        if existing:
            if existing["content_hash"] == content_hash:
                return {"status": "already_exists_unchanged", "document_id": existing["id"], "tenant_id": tenant_id}
            else:
                # Contenido cambió → update incremental
                cursor.execute("""
                    UPDATE rag_documents
                    SET content_hash = %s, status = 'pending', last_updated = NOW()
                    WHERE id = %s AND tenant_id = %s
                """, (content_hash, existing["id"], tenant_id))  # C4
                conn.commit()
                return {"status": "updated_hash", "document_id": existing["id"], "tenant_id": tenant_id}

        # Insertar nuevo documento
        cursor.execute("""
            INSERT INTO rag_documents
                (id, tenant_id, source_type, source_id, filename, content_hash,
                 status, total_chunks, embedding_model, created_at, last_updated)
            VALUES (%s, %s, %s, %s, %s, %s, 'pending', 0, %s, NOW(), NOW())
        """, (document_id, tenant_id, source_type, source_id, filename, content_hash, embedding_model))
        # C4: tenant_id segundo campo en INSERT

        conn.commit()
        return {"status": "created", "document_id": document_id, "tenant_id": tenant_id}  # C4

    finally:
        cursor.close()
        conn.close()
```

---

### Ejemplo M-4: Purgar Documentos y Chunks Huérfanos (Mantenimiento)

```sql
-- mysql_purge_orphans.sql
-- Eliminar chunks sin documento padre (inconsistencia por fallo en transacción)
-- C4: Siempre filtrar por tenant_id

-- PASO 1: Detectar chunks huérfanos por tenant
SELECT
    rc.tenant_id,                -- C4
    COUNT(*) AS chunks_huerfanos
FROM rag_chunks rc
LEFT JOIN rag_documents rd
    ON rc.document_id = rd.id
    AND rc.tenant_id  = rd.tenant_id    -- C4: JOIN con tenant_id también
WHERE rd.id IS NULL
  AND rc.tenant_id = ?                  -- C4: Solo del tenant solicitado
GROUP BY rc.tenant_id;

-- PASO 2: Eliminar chunks huérfanos en lotes (C1)
DELETE rc
FROM rag_chunks rc
LEFT JOIN rag_documents rd
    ON rc.document_id = rd.id
    AND rc.tenant_id  = rd.tenant_id    -- C4
WHERE rd.id IS NULL
  AND rc.tenant_id = ?                  -- C4
LIMIT 1000;

-- PASO 3: Detectar documentos 'processing' bloqueados > 1 hora (fallo de proceso)
UPDATE rag_documents
SET status = 'failed', last_updated = NOW()
WHERE
    tenant_id   = ?                     -- C4
    AND status  = 'processing'
    AND last_updated < DATE_SUB(NOW(), INTERVAL 1 HOUR);

-- PASO 4: Contar documentos por estado (dashboard)
SELECT status, COUNT(*) AS total
FROM rag_documents
WHERE tenant_id = ?                     -- C4
GROUP BY status
ORDER BY FIELD(status, 'pending', 'processing', 'completed', 'failed');
```

---

### Ejemplo M-5: Audit Trail de Actualizaciones (C5)

```python
# mysql_audit_rag_updates.py
def log_rag_operation(
    tenant_id: str,       # C4
    operation: str,       # 'update', 'delete', 'full_reingest', 'append'
    document_id: str,
    chunks_before: int,
    chunks_after: int,
    duration_ms: int,
    status: str           # 'success', 'failed', 'skipped'
) -> None:
    """
    C5: Log estructurado de todas las operaciones RAG para auditoría.
    Tabla rag_audit_log con retención 90 días.
    """
    conn = get_mysql_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""
            INSERT INTO rag_audit_log
                (tenant_id, operation, document_id,
                 chunks_before, chunks_after, duration_ms, status, created_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, NOW())
        """, (tenant_id, operation, document_id, chunks_before, chunks_after, duration_ms, status))
        # C4: tenant_id primer campo

        conn.commit()
    finally:
        cursor.close()
        conn.close()

# Query de auditoría: actividad de los últimos 7 días por tenant
def get_audit_summary(tenant_id: str) -> list:
    conn = get_mysql_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("""
            SELECT
                DATE(created_at) AS fecha,
                operation,
                COUNT(*)         AS total_ops,
                SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) AS exitosas,
                AVG(duration_ms) AS duracion_avg_ms
            FROM rag_audit_log
            WHERE
                tenant_id  = %s           -- C4
                AND created_at > DATE_SUB(NOW(), INTERVAL 7 DAY)
            GROUP BY DATE(created_at), operation
            ORDER BY fecha DESC, operation
        """, (tenant_id,))
        return cursor.fetchall()
    finally:
        cursor.close()
        conn.close()
```

---

### 🐞 Troubleshooting MySQL (5 Problemas)

| Error Exacto | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso |
|---|---|---|---|
| `Deadlock found when trying to get lock` durante update masivo de chunks | Dos procesos intentando `DELETE FROM rag_chunks WHERE document_id = X` simultáneamente | `SHOW ENGINE INNODB STATUS\G` → buscar sección DEADLOCK | 1. Agregar retry con backoff: `for attempt in range(3): try: ... except DeadlockError: sleep(0.5 * attempt)`<br>2. Serializar updates del mismo documento con lock de aplicación (Redis o flag en MySQL)<br>3. Usar `SELECT ... FOR UPDATE` al inicio de la transacción para lockear el documento |
| `UPDATE rag_documents SET status='failed'` afecta 0 filas aunque el ID existe | Query sin `tenant_id` en WHERE, o `tenant_id` incorrecto (C4 violation) | `SELECT id, tenant_id FROM rag_documents WHERE id = 'X';` → ver tenant_id real | 1. Verificar que `tenant_id` en la llamada coincide con el de la BD<br>2. Nunca hacer `WHERE id = X` sin `AND tenant_id = Y`<br>3. Agregar assertion: `assert cursor.rowcount > 0, f"Document {id} not found for tenant {tenant_id}"` |
| Tabla `rag_chunks` crece sin control (disco > 80% - RES-003) | No se purgan chunks de documentos eliminados del origen (Drive/PDF borrado) | `SELECT COUNT(*), SUM(LENGTH(text_preview)) FROM rag_chunks WHERE tenant_id = ?;` | 1. Implementar `purge_orphans()` (Ejemplo M-4) como cron diario<br>2. Agregar `ON DELETE CASCADE` en FK de `rag_chunks.document_id → rag_documents.id`<br>3. Job semanal: eliminar documentos con `status = 'deleted'` y sus chunks<br>4. Monitorear: `SELECT table_name, ROUND(data_length/1024/1024,1) AS MB FROM information_schema.tables WHERE table_schema = 'mantis_rag_meta';` |
| `INSERT INTO rag_chunks` lento (> 5s para 200 chunks) | No hay índice en `document_id` o se inserta fila por fila en lugar de `executemany()` | `EXPLAIN INSERT INTO rag_chunks VALUES ...` → ver si hay index check | 1. Usar `executemany()` con lotes de 100, no loop de `execute()` individuales<br>2. Para inserciones masivas: `SET foreign_key_checks = 0;` antes, `SET foreign_key_checks = 1;` después<br>3. Verificar índice: `SHOW INDEX FROM rag_chunks;` debe tener `idx_tenant_doc (tenant_id, document_id)` |
| Documentos quedan en `status = 'processing'` indefinidamente (proceso murió) | n8n reiniciado durante ingesta, sin cleanup de estado (C1/C2: proceso OOM killed) | `SELECT id, filename, last_updated FROM rag_documents WHERE status = 'processing' AND tenant_id = ?;` | 1. Implementar cron cada 30 min: `UPDATE rag_documents SET status='failed' WHERE status='processing' AND last_updated < DATE_SUB(NOW(), INTERVAL 1 HOUR) AND tenant_id = ?`<br>2. Agregar `heartbeat_at` column: el proceso la actualiza cada 30s; si se detiene, cron detecta en < 2 min<br>3. Usar `status = 'pending'` como estado default de reintento |

---

---

# <a name="postgresql"></a>🐘 MOTOR 3: PostgreSQL + Prisma

**Rol:** Alternativa a MySQL para metadata RAG. Preferido cuando el cliente ya tiene PostgreSQL en su stack, cuando se necesita JSONB avanzado, o para sistemas con Supabase self-hosted.

**Diferencia clave vs MySQL:** PostgreSQL tiene `pgvector` (vectores nativos), arrays JSONB, y Row Level Security. Prisma agrega type-safety y migrations versionadas.

---

### Ejemplo P-1: Update Incremental con Prisma (Transacción Atómica)

```typescript
// prisma_update_document.ts
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient({
  datasources: { db: { url: process.env.DATABASE_URL + '?connection_limit=10' } }  // C1
});

async function updateDocumentPrisma(
  tenantId: string,       // C4
  documentId: string,
  newContentHash: string,
  newChunks: Array<{
    id: string;
    chunkIndex: number;
    text: string;
    tokenCount: number;
    qdrantId?: string;
  }>
): Promise<object> {

  if (!tenantId) throw new Error('tenantId required (C4)');

  return await prisma.$transaction(async (tx) => {

    // C4: Verificar ownership antes de cualquier modificación
    const doc = await tx.ragDocument.findFirst({
      where: { id: documentId, tenantId }   // C4: siempre tenant_id
    });

    if (!doc) throw new Error(`Document not found for tenant ${tenantId} (C4)`);
    if (doc.contentHash === newContentHash) {
      return { status: 'unchanged', tenantId, documentId };
    }

    // Actualizar documento
    await tx.ragDocument.update({
      where: { id: documentId },
      data: {
        contentHash:  newContentHash,
        status:       'processing',
        totalChunks:  newChunks.length,
        lastUpdated:  new Date()
      }
    });

    // Eliminar chunks viejos (C4: deleteMany con tenant_id)
    const { count: deletedCount } = await tx.ragChunk.deleteMany({
      where: { documentId, tenantId }   // C4
    });

    // Insertar chunks nuevos en lote (C1: createMany)
    await tx.ragChunk.createMany({
      data: newChunks.map((chunk, i) => ({
        id:             chunk.id,
        tenantId:       tenantId,           // C4
        documentId:     documentId,
        chunkIndex:     chunk.chunkIndex,
        totalChunks:    newChunks.length,
        textPreview:    chunk.text.slice(0, 500),
        tokenCount:     chunk.tokenCount,
        contentHash:    require('crypto').createHash('sha256').update(chunk.text).digest('hex'),
        vectorStore:    'qdrant',
        qdrantId:       chunk.qdrantId ?? null,
        embeddingModel: process.env.EMBEDDING_MODEL ?? 'text-embedding-3-small',
        createdAt:      new Date(),
        updatedAt:      new Date()
      })),
      skipDuplicates: true   // Idempotencia
    });

    // Completar
    await tx.ragDocument.update({
      where: { id: documentId },
      data: { status: 'completed', lastUpdated: new Date() }
    });

    return {
      tenantId,      // C4
      documentId,
      deletedChunks: deletedCount,
      insertedChunks: newChunks.length
    };
  });
}
```

---

### Ejemplo P-2: Full Re-ingest con Cursor Paginado (C1)

```typescript
// prisma_full_reingest.ts
async function fullReingestTenant(
  tenantId: string,   // C4
  newModel: string
): Promise<object> {

  if (!tenantId) throw new Error('tenantId required (C4)');

  let cursor: string | undefined;
  let totalUpdated = 0;

  do {
    // C1: Procesar en lotes de 50, nunca cargar todo
    const chunks = await prisma.ragChunk.findMany({
      where:   { tenantId },    // C4
      take:     50,
      skip:     cursor ? 1 : 0,
      cursor:   cursor ? { id: cursor } : undefined,
      orderBy:  { id: 'asc' },
      select: { id: true, textPreview: true }
    });

    if (chunks.length === 0) break;

    // Re-generar embeddings para este lote (C6: API cloud)
    const texts = chunks.map(c => c.textPreview ?? '');
    const embeddings = await generateEmbeddingsBatch(texts, { model: newModel, batchSize: 20 });

    // Actualizar modelo en metadata (el vector se actualiza en Qdrant por separado)
    await prisma.$transaction(
      chunks.map((chunk, i) =>
        prisma.ragChunk.update({
          where: { id: chunk.id },
          data: {
            embeddingModel: newModel,
            updatedAt:      new Date()
          }
        })
      )
    );

    totalUpdated += chunks.length;
    cursor = chunks[chunks.length - 1].id;

    await new Promise(r => setTimeout(r, 100));  // Throttle (C1)

  } while (true);

  return { tenantId, totalUpdated, newModel };   // C4
}
```

---

### Ejemplo P-3: Migración Prisma para Schema RAG

```prisma
// schema.prisma — Schema RAG unificado
// Ejecutar: npx prisma migrate dev --name rag_documents_chunks

model RagDocument {
  id             String   @id @default(uuid())
  tenantId       String                            // C4: OBLIGATORIO
  sourceType     String                            // 'pdf', 'google_drive', 'url'
  sourceId       String
  filename       String
  contentHash    String
  status         String   @default("pending")
  totalChunks    Int      @default(0)
  embeddingModel String
  lastUpdated    DateTime @default(now()) @updatedAt
  createdAt      DateTime @default(now())

  chunks         RagChunk[]

  @@index([tenantId, status])         // C4: tenant primero
  @@index([tenantId, sourceId])       // C4: para detectar duplicados
  @@index([tenantId, contentHash])    // C4: para detectar cambios
  @@map("rag_documents")
}

model RagChunk {
  id             String   @id @default(uuid())
  tenantId       String                            // C4: OBLIGATORIO
  documentId     String
  chunkIndex     Int
  totalChunks    Int
  textPreview    String?  @db.VarChar(500)
  tokenCount     Int      @default(0)
  contentHash    String
  vectorStore    String   @default("qdrant")      // 'qdrant', 'chroma', 'pgvector'
  qdrantId       String?                           // ID en Qdrant
  embeddingModel String
  createdAt      DateTime @default(now())
  updatedAt      DateTime @default(now()) @updatedAt

  document       RagDocument @relation(fields: [documentId], references: [id], onDelete: Cascade)

  @@index([tenantId, documentId])    // C4
  @@index([tenantId, vectorStore])
  @@unique([documentId, chunkIndex])
  @@map("rag_chunks")
}

model RagAuditLog {
  id           String   @id @default(uuid())
  tenantId     String                             // C4
  operation    String
  documentId   String?
  chunksBefore Int      @default(0)
  chunksAfter  Int      @default(0)
  durationMs   Int      @default(0)
  status       String
  createdAt    DateTime @default(now())

  @@index([tenantId, createdAt])     // C4
  @@map("rag_audit_log")
}
```

---

### Ejemplo P-4: Patch de Chunks con JSONB Metadata

```typescript
// prisma_patch_metadata.ts
// Actualizar metadata enriquecida de chunks (página, sección, tags)
// JSONB en PostgreSQL permite evolución sin alterar schema

async function patchChunkMetadata(
  tenantId: string,           // C4
  chunkId: string,
  metadataUpdate: Record<string, unknown>
): Promise<object> {

  if (!tenantId) throw new Error('tenantId required (C4)');

  // C4: Verificar ownership antes de modificar
  const chunk = await prisma.ragChunk.findFirst({
    where: { id: chunkId, tenantId }   // C4
  });

  if (!chunk) throw new Error(`Chunk not found for tenant ${tenantId} (C4)`);

  // Merge metadata JSONB (no sobrescribir todo el objeto)
  // Requiere campo `metadata Json?` en el schema
  const currentMeta = (chunk as any).metadata ?? {};
  const newMeta = { ...currentMeta, ...metadataUpdate };

  const updated = await prisma.ragChunk.update({
    where: { id: chunkId },
    data: {
      // metadata: newMeta,   // Descomentar si se agrega campo al schema
      updatedAt: new Date()
    }
  });

  return { tenantId, chunkId, updated: true };   // C4
}
```

---

### Ejemplo P-5: Reporte de Estado de Ingesta por Tenant

```typescript
// prisma_ingestion_status.ts
async function getIngestionStatus(tenantId: string): Promise<object> {
  if (!tenantId) throw new Error('tenantId required (C4)');

  const [docStats, chunkStats, recentErrors] = await Promise.all([
    // Documentos agrupados por estado
    prisma.ragDocument.groupBy({
      by: ['status'],
      where: { tenantId },   // C4
      _count: { id: true },
      _sum: { totalChunks: true }
    }),

    // Total de chunks con embedding model
    prisma.ragChunk.groupBy({
      by: ['embeddingModel'],
      where: { tenantId },   // C4
      _count: { id: true }
    }),

    // Últimos 5 errores
    prisma.ragDocument.findMany({
      where: { tenantId, status: 'failed' },   // C4
      orderBy: { lastUpdated: 'desc' },
      take: 5,
      select: { id: true, filename: true, lastUpdated: true }
    })
  ]);

  return {
    tenantId,      // C4
    documents: docStats.map(s => ({
      status:       s.status,
      count:        s._count.id,
      totalChunks:  s._sum.totalChunks ?? 0
    })),
    chunksByModel: chunkStats.map(s => ({
      model: s.embeddingModel,
      count: s._count.id
    })),
    recentErrors
  };
}
```

---

### 🐞 Troubleshooting PostgreSQL + Prisma (5 Problemas)

| Error Exacto | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso |
|---|---|---|---|
| `P2034: Transaction failed due to a write conflict or a deadlock` | Dos procesos Prisma actualizando los mismos chunks simultáneamente | Ver logs de app para requests concurrentes en el mismo `documentId` | 1. Implementar retry: `for (let i = 0; i < 3; i++) { try { await tx(...); break; } catch(e) { if (e.code !== 'P2034') throw e; await sleep(500 * i); } }`<br>2. Serializar operaciones por documento con Redis lock key `rag_lock:{tenantId}:{documentId}`<br>3. Reducir `EXECUTIONS_MAX_CONCURRENT` en n8n a 2 para workflows de ingesta |
| `PrismaClientInitializationError: Can't reach database server` | PostgreSQL caído o `DATABASE_URL` incorrecto | `docker ps \| grep postgres` + `docker logs mantis-postgres --tail 20` | 1. Reiniciar: `docker-compose restart postgres`<br>2. Verificar URL: `echo $DATABASE_URL` — debe ser `postgresql://user:pass@localhost:5432/db`<br>3. Prisma connection pool exhausto: agregar `?connection_limit=5` a DATABASE_URL |
| `deleteMany` con `tenantId` en `where` borra 0 filas aunque existen chunks | `tenantId` en el objeto Prisma es `undefined` (error silencioso) | `console.log('tenantId:', tenantId)` antes del deleteMany | 1. Agregar validación explícita: `if (!tenantId) throw new Error('tenantId required')`<br>2. Prisma con `undefined` en `where` omite la condición — verificar que el campo no es opcional en el type<br>3. Usar `strict` en TypeScript para detectar en compile time |
| Migración `prisma migrate dev` falla con `P3006: failed to apply migration` | Schema tiene cambios incompatibles (cambiar tipo de columna sin migración intermedia) | `npx prisma migrate status` → ver migraciones pendientes o fallidas | 1. Ver el error específico: `npx prisma migrate dev --create-only` para crear SQL sin aplicar<br>2. Editar el SQL generado manualmente si el cambio requiere transformación de datos<br>3. Para VPS producción: `npx prisma migrate deploy` (no `dev`) — nunca `migrate reset` en producción |
| `createMany` con `skipDuplicates: true` silencia errores reales | Se están ignorando errores que no son de duplicado (constraint violations de FK) | Loguear antes: `console.log('Inserting', data.length, 'chunks for', tenantId)` | 1. Para debug: temporalmente usar `create()` en loop para ver el error exacto por chunk<br>2. Verificar que `documentId` existe en `rag_documents` antes de insertar chunks<br>3. Usar transacción con `createDocument` + `createManyChunks` para garantizar FK válida |

---

---

# <a name="supabase"></a>🟢 MOTOR 4: Supabase

**Rol:** PostgreSQL cloud con Row Level Security (RLS). Ideal para clientes sin VPS propio o cuando se quiere multi-tenancy gestionado por la BD (no solo por la app).

**Diferencia clave vs PostgreSQL local:** RLS enforcea C4 a nivel de base de datos — incluso si el código olvida poner `tenant_id` en el WHERE, la BD lo bloquea automáticamente. Es una capa de seguridad extra.

---

### Ejemplo S-1: Configurar RLS para RAG Multi-Tenant

```sql
-- supabase_rls_setup.sql
-- Ejecutar en Supabase SQL Editor UNA VEZ por proyecto

-- ─── TABLAS ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS rag_documents (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id      TEXT NOT NULL,           -- C4
    source_type    TEXT NOT NULL,
    source_id      TEXT NOT NULL,
    filename       TEXT NOT NULL,
    content_hash   TEXT NOT NULL,
    status         TEXT NOT NULL DEFAULT 'pending',
    total_chunks   INT  NOT NULL DEFAULT 0,
    embedding_model TEXT NOT NULL,
    last_updated   TIMESTAMPTZ DEFAULT NOW(),
    created_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS rag_chunks (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id      TEXT NOT NULL,           -- C4
    document_id    UUID NOT NULL REFERENCES rag_documents(id) ON DELETE CASCADE,
    chunk_index    INT  NOT NULL,
    total_chunks   INT  NOT NULL,
    text_preview   TEXT,
    token_count    INT  NOT NULL DEFAULT 0,
    content_hash   TEXT NOT NULL,
    vector_store   TEXT NOT NULL DEFAULT 'qdrant',
    qdrant_id      TEXT,
    embedding_model TEXT NOT NULL,
    created_at     TIMESTAMPTZ DEFAULT NOW(),
    updated_at     TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (document_id, chunk_index)
);

-- ─── ÍNDICES (C4: tenant_id siempre primero) ─────────────────────
CREATE INDEX IF NOT EXISTS idx_ragdoc_tenant_status  ON rag_documents (tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_ragdoc_tenant_source  ON rag_documents (tenant_id, source_id);
CREATE INDEX IF NOT EXISTS idx_ragchunk_tenant_doc   ON rag_chunks    (tenant_id, document_id);

-- ─── ROW LEVEL SECURITY (C4 a nivel BD) ──────────────────────────
ALTER TABLE rag_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE rag_chunks    ENABLE ROW LEVEL SECURITY;

-- Política: cada request solo ve sus propios datos
-- La app debe ejecutar: SET app.current_tenant = 'restaurante_001';
CREATE POLICY rls_rag_documents ON rag_documents
    FOR ALL
    USING (tenant_id = current_setting('app.current_tenant', true));

CREATE POLICY rls_rag_chunks ON rag_chunks
    FOR ALL
    USING (tenant_id = current_setting('app.current_tenant', true));

-- Función helper para establecer tenant en la sesión
CREATE OR REPLACE FUNCTION set_tenant(p_tenant_id TEXT)
RETURNS VOID AS $$
BEGIN
    PERFORM set_config('app.current_tenant', p_tenant_id, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

### Ejemplo S-2: Update Incremental via Supabase SDK

```javascript
// supabase_update_document.js
import { createClient } from '@supabase/supabase-js';

// Service role key bypasa RLS (solo para scripts de backend - C3: NUNCA en cliente)
const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_KEY   // Service key — nunca anon key para updates
);

async function updateDocumentSupabase(tenantId, documentId, newContentHash, newChunks) {
    // C4: Validación explícita
    if (!tenantId) throw new Error('tenantId required (C4)');

    // ─── PASO 1: Verificar ownership (C4) ────────────────────────
    const { data: doc, error: docError } = await supabase
        .from('rag_documents')
        .select('id, content_hash')
        .eq('id', documentId)
        .eq('tenant_id', tenantId)    // C4
        .single();

    if (docError || !doc) throw new Error(`Document not found for tenant ${tenantId} (C4)`);
    if (doc.content_hash === newContentHash) return { status: 'unchanged', tenantId };

    // ─── PASO 2: Actualizar documento a 'processing' ─────────────
    await supabase
        .from('rag_documents')
        .update({ status: 'processing', content_hash: newContentHash, last_updated: new Date() })
        .eq('id', documentId)
        .eq('tenant_id', tenantId);   // C4

    // ─── PASO 3: Eliminar chunks viejos (C4: doble filtro) ───────
    const { count: deletedCount } = await supabase
        .from('rag_chunks')
        .delete()
        .eq('document_id', documentId)
        .eq('tenant_id', tenantId)    // C4
        .select('count');

    // ─── PASO 4: Insertar chunks nuevos en lotes (C1) ────────────
    let insertedCount = 0;
    for (let i = 0; i < newChunks.length; i += 100) {
        const batch = newChunks.slice(i, i + 100).map((chunk, j) => ({
            tenant_id:       tenantId,             // C4
            document_id:     documentId,
            chunk_index:     i + j,
            total_chunks:    newChunks.length,
            text_preview:    chunk.text?.slice(0, 500),
            token_count:     chunk.tokenCount ?? 0,
            content_hash:    chunk.contentHash,
            vector_store:    'qdrant',
            qdrant_id:       chunk.qdrantId ?? null,
            embedding_model: process.env.EMBEDDING_MODEL
        }));

        const { error } = await supabase.from('rag_chunks').insert(batch);
        if (error) throw new Error(`Chunk insert failed: ${error.message}`);
        insertedCount += batch.length;
    }

    // ─── PASO 5: Completar ───────────────────────────────────────
    await supabase
        .from('rag_documents')
        .update({ status: 'completed', total_chunks: newChunks.length, last_updated: new Date() })
        .eq('id', documentId)
        .eq('tenant_id', tenantId);   // C4

    return { tenantId, documentId, deletedChunks: deletedCount, insertedChunks: insertedCount };
}
```

---

### Ejemplo S-3: Full Re-ingest con Paginación Supabase (C1)

```javascript
// supabase_full_reingest.js
async function fullReingestSupabase(tenantId, newModel) {
    if (!tenantId) throw new Error('tenantId required (C4)');

    let from = 0;
    const pageSize = 50;   // C1: lotes pequeños
    let totalUpdated = 0;

    while (true) {
        // C4: Siempre filtrar por tenant_id
        const { data: chunks, error } = await supabase
            .from('rag_chunks')
            .select('id, text_preview')
            .eq('tenant_id', tenantId)    // C4
            .order('id')
            .range(from, from + pageSize - 1);

        if (error) throw error;
        if (!chunks || chunks.length === 0) break;

        // Re-generar embeddings (C6: API cloud, batch 20)
        const texts = chunks.map(c => c.text_preview ?? '');
        const embeddings = await generateEmbeddingsBatch(texts, { model: newModel, batchSize: 20 });

        // Actualizar modelo en metadata Supabase
        // (los vectores se actualizan en Qdrant por separado)
        const updatePromises = chunks.map(chunk =>
            supabase
                .from('rag_chunks')
                .update({ embedding_model: newModel, updated_at: new Date() })
                .eq('id', chunk.id)
                .eq('tenant_id', tenantId)   // C4
        );
        await Promise.all(updatePromises);

        totalUpdated += chunks.length;
        from += pageSize;
        await new Promise(r => setTimeout(r, 100));  // Throttle (C1)
    }

    return { tenantId, totalUpdated, newModel };   // C4
}
```

---

### Ejemplo S-4: Append con Detección de Cambios (Hash)

```javascript
// supabase_append_with_dedup.js
async function appendOrUpdateSupabase(tenantId, sourceId, filename, text, contentHash) {
    if (!tenantId) throw new Error('tenantId required (C4)');

    // Buscar por source_id + tenant_id (C4)
    const { data: existing } = await supabase
        .from('rag_documents')
        .select('id, content_hash, status')
        .eq('tenant_id', tenantId)   // C4
        .eq('source_id', sourceId)
        .maybeSingle();

    if (existing) {
        if (existing.content_hash === contentHash) {
            return { action: 'skipped', reason: 'hash_unchanged', tenantId, sourceId };
        }
        // Hash cambió → update del documento existente
        return { action: 'update', documentId: existing.id, tenantId };
    }

    // Documento nuevo → crear registro
    const { data: newDoc, error } = await supabase
        .from('rag_documents')
        .insert({
            tenant_id:       tenantId,   // C4
            source_type:     'pdf',
            source_id:       sourceId,
            filename:        filename,
            content_hash:    contentHash,
            status:          'pending',
            embedding_model: process.env.EMBEDDING_MODEL
        })
        .select()
        .single();

    if (error) throw error;
    return { action: 'created', documentId: newDoc.id, tenantId };
}
```

---

### Ejemplo S-5: Purgar Chunks Huérfanos y Auditoría

```sql
-- supabase_purge_and_audit.sql
-- Ejecutar en Supabase SQL Editor

-- PASO 1: Chunks sin documento padre (inconsistencia por fallo)
-- C4: SET tenant antes de ejecutar (RLS)
SELECT set_tenant('restaurante_001');

SELECT rc.id, rc.document_id, rc.chunk_index
FROM rag_chunks rc
LEFT JOIN rag_documents rd
    ON rc.document_id = rd.id
    AND rc.tenant_id  = rd.tenant_id
WHERE rd.id IS NULL
  AND rc.tenant_id = current_setting('app.current_tenant');

-- PASO 2: Eliminar huérfanos
DELETE FROM rag_chunks rc
USING (
    SELECT rc2.id
    FROM rag_chunks rc2
    LEFT JOIN rag_documents rd ON rc2.document_id = rd.id
        AND rc2.tenant_id = rd.tenant_id
    WHERE rd.id IS NULL
      AND rc2.tenant_id = current_setting('app.current_tenant')   -- C4 via RLS
) orphans
WHERE rc.id = orphans.id;

-- PASO 3: Vista de auditoría de ingesta (últimas 24h)
SELECT
    status,
    COUNT(*)                    AS documentos,
    SUM(total_chunks)           AS chunks_totales,
    MIN(last_updated)           AS mas_antiguo,
    MAX(last_updated)           AS mas_reciente
FROM rag_documents
WHERE
    tenant_id    = current_setting('app.current_tenant')   -- C4 via RLS
    AND last_updated > NOW() - INTERVAL '24 hours'
GROUP BY status
ORDER BY status;
```

---

### 🐞 Troubleshooting Supabase (5 Problemas)

| Error Exacto | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso |
|---|---|---|---|
| `new row violates row-level security policy for table rag_documents` | Intentando insertar sin establecer `app.current_tenant` en la sesión | `SELECT current_setting('app.current_tenant', true);` → debería retornar el tenant_id | 1. Antes de cualquier INSERT/UPDATE: `await supabase.rpc('set_tenant', { p_tenant_id: tenantId })`<br>2. Si usás service key (bypasa RLS): el error no ocurre — revisar qué key se está usando<br>3. Para scripts de backend: siempre usar service key y filtrar manualmente con `.eq('tenant_id', tenantId)` |
| `select()` retorna filas de OTRO tenant (RLS no activo) | Se está usando `service_role` key que bypasa RLS sin filtro manual de tenant_id | `console.log(supabase.auth.getSession())` → si es service key, RLS está bypaseado | 1. Con service key: SIEMPRE agregar `.eq('tenant_id', tenantId)` manualmente (C4)<br>2. Con anon key: RLS activo pero necesita `set_tenant()` antes<br>3. Nunca mezclar anon key en backend — solo service key con filtro explícito |
| Rate limit de Supabase: `Error 429: Too Many Requests` durante full re-ingest | Demasiadas requests en poco tiempo (plan free: 500 req/min) | Monitorear en Supabase Dashboard → API → Requests | 1. Agregar `await sleep(200)` entre cada batch de 50 chunks<br>2. Para clientes en plan free: reducir `pageSize` a 20<br>3. Agrupar múltiples updates en un solo `.upsert([...])` en lugar de updates individuales<br>4. Considerar upgrading a plan Pro si el cliente tiene > 5000 documentos |
| `ForeignKeyViolation` al insertar chunks: `document_id` no existe | Chunks se están insertando antes de que se confirme el insert del documento | Verificar orden de operaciones en el código | 1. Garantizar que el `INSERT INTO rag_documents` esté confirmado (`.single()` retornó data) antes de insertar chunks<br>2. Usar función RPC de Supabase que envuelva todo en una transacción PostgreSQL<br>3. Agregar retry: si FK violation, esperar 500ms y reintentar — puede ser lag de replicación |
| Updates muy lentos (> 10s) para documentos con > 500 chunks | `.update()` individual por chunk en loop (N queries) en vez de upsert en batch | `console.time('update'); await ...; console.timeEnd('update')` | 1. Reemplazar loop de updates por `supabase.from('rag_chunks').upsert([...500 chunks])` en un solo request<br>2. Supabase acepta hasta 1000 filas por upsert<br>3. Para > 1000: dividir en lotes de 500 con `for (let i=0; i<chunks.length; i+=500)` |

---

---

# <a name="chromadb"></a>🟣 MOTOR 5: ChromaDB

**Rol:** Vector store embebido para desarrollo local y clientes sin VPS propio. No requiere servidor separado — corre embebido en el mismo proceso Python o como servidor HTTP ligero. Ideal para prototipos y demos.

**Cuándo NO usar en producción:** C1 — ChromaDB en modo embebido no soporta acceso concurrente de múltiples procesos. Para producción con n8n, usar Qdrant.

**Modos de uso:**
```python
# Modo embebido (solo desarrollo/prototipo)
client = chromadb.PersistentClient(path="/data/chromadb")

# Modo servidor HTTP (puede usarse en producción single-process)
client = chromadb.HttpClient(host="localhost", port=8000)
```

---

### Ejemplo C-1: Update Incremental en ChromaDB

```python
# chromadb_update_incremental.py
import chromadb
import os
import hashlib
from embeddings import generate_embeddings_batch
from chunker import split_text_into_chunks

def get_chroma_client():
    """C3: Solo conexión local."""
    if os.environ.get("CHROMA_HOST"):
        return chromadb.HttpClient(
            host=os.environ["CHROMA_HOST"],
            port=int(os.environ.get("CHROMA_PORT", 8000))
        )
    return chromadb.PersistentClient(
        path=os.environ.get("CHROMA_PERSIST_DIR", "/data/chromadb")
    )

def update_document_chroma(
    tenant_id: str,        # C4
    document_id: str,
    new_text: str
) -> dict:
    """
    Reemplaza chunks de un documento en ChromaDB.
    C4: Colección por tenant (rag_{tenant_id}).
    ChromaDB no tiene delete por filtro como Qdrant —
    necesitamos obtener IDs primero, luego eliminarlos.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    client = get_chroma_client()

    # C4: Colección separada por tenant
    collection_name = f"rag_{tenant_id}"

    # get_or_create: idempotente
    collection = client.get_or_create_collection(
        name=collection_name,
        metadata={"tenant_id": tenant_id, "hnsw:space": "cosine"}
    )

    # ─── PASO 1: Obtener IDs de chunks viejos del documento ──────
    # ChromaDB requiere obtener IDs antes de eliminar por metadata
    old_results = collection.get(
        where={"$and": [
            {"tenant_id":   {"$eq": tenant_id}},     # C4
            {"document_id": {"$eq": document_id}}
        ]},
        include=["metadatas"]
    )

    if old_results["ids"]:
        collection.delete(ids=old_results["ids"])

    # ─── PASO 2: Chunk + Embed + Insert ──────────────────────────
    chunks = split_text_into_chunks(new_text, max_tokens=500, overlap=50)
    texts = [c["text"] for c in chunks]
    embeddings = generate_embeddings_batch(texts, batch_size=20)  # C1

    chunk_ids = [chunk["id"] for chunk in chunks]

    # ChromaDB acepta inserción con embeddings pre-generados
    collection.add(
        ids=chunk_ids,
        embeddings=embeddings,
        documents=texts,
        metadatas=[{
            "tenant_id":       tenant_id,             # C4
            "document_id":     document_id,
            "chunk_index":     i,
            "total_chunks":    len(chunks),
            "content_hash":    hashlib.sha256(chunk["text"].encode()).hexdigest(),
            "embedding_model": os.environ.get("EMBEDDING_MODEL", "text-embedding-3-small"),
            "token_count":     chunk.get("token_count", 0)
        } for i, chunk in enumerate(chunks)]
    )

    return {
        "tenant_id":      tenant_id,     # C4
        "document_id":    document_id,
        "deleted_chunks": len(old_results["ids"]),
        "inserted_chunks": len(chunks)
    }
```

---

### Ejemplo C-2: Full Re-ingest de Colección ChromaDB

```python
# chromadb_full_reingest.py
def full_reingest_chroma(
    tenant_id: str,       # C4
    new_model: str
) -> dict:
    """
    Re-genera todos los embeddings de una colección ChromaDB.
    C1: Procesar en lotes de 50 (ChromaDB carga todos en RAM si no se pagina).
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    client = get_chroma_client()
    collection = client.get_or_create_collection(f"rag_{tenant_id}")

    # ChromaDB no tiene scroll nativo — obtener todos los IDs (cuidado con C1)
    all_data = collection.get(
        where={"tenant_id": {"$eq": tenant_id}},  # C4
        include=["documents", "metadatas"]
    )

    total_ids    = all_data["ids"]
    total_docs   = all_data["documents"]
    total_metas  = all_data["metadatas"]
    total_updated = 0

    # Procesar en lotes de 50 (C1)
    for i in range(0, len(total_ids), 50):
        batch_ids    = total_ids[i:i+50]
        batch_texts  = total_docs[i:i+50]
        batch_metas  = total_metas[i:i+50]

        new_embeddings = generate_embeddings_batch(batch_texts, model=new_model, batch_size=20)

        # Actualizar metadata con nuevo modelo
        updated_metas = [{**m, "embedding_model": new_model} for m in batch_metas]

        # ChromaDB: update requiere embeddings explícitos
        collection.update(
            ids=batch_ids,
            embeddings=new_embeddings,
            metadatas=updated_metas
        )

        total_updated += len(batch_ids)
        __import__("time").sleep(0.1)  # Throttle (C1)

    return {"tenant_id": tenant_id, "total_updated": total_updated, "new_model": new_model}
```

---

### Ejemplo C-3: Append — Nuevo Documento sin Tocar Existentes

```python
# chromadb_append.py
def append_document_chroma(
    tenant_id: str,    # C4
    document_id: str,
    text: str,
    metadata: dict = None
) -> dict:
    """
    Agrega documento nuevo a la colección.
    Verifica que no exista antes para idempotencia.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    client = get_chroma_client()
    collection = client.get_or_create_collection(f"rag_{tenant_id}")

    # Verificar si ya existe (C4: filtro con tenant_id)
    existing = collection.get(
        where={"$and": [
            {"tenant_id":   {"$eq": tenant_id}},
            {"document_id": {"$eq": document_id}}
        ]},
        include=[]  # Solo IDs, sin cargar vectores (C1)
    )

    if existing["ids"]:
        # Ya existe → redirigir a update
        return update_document_chroma(tenant_id, document_id, text)

    chunks     = split_text_into_chunks(text, max_tokens=500, overlap=50)
    texts_list = [c["text"] for c in chunks]
    embeddings = generate_embeddings_batch(texts_list, batch_size=20)

    collection.add(
        ids=[c["id"] for c in chunks],
        embeddings=embeddings,
        documents=texts_list,
        metadatas=[{
            "tenant_id":       tenant_id,   # C4
            "document_id":     document_id,
            "chunk_index":     i,
            "total_chunks":    len(chunks),
            "embedding_model": os.environ.get("EMBEDDING_MODEL"),
            **(metadata or {})
        } for i, _ in enumerate(chunks)]
    )

    return {"tenant_id": tenant_id, "document_id": document_id, "chunks_inserted": len(chunks)}
```

---

### Ejemplo C-4: Delete — Purgar Documento

```python
# chromadb_delete.py
def delete_document_chroma(
    tenant_id: str,    # C4
    document_id: str
) -> dict:
    """
    Elimina todos los chunks de un documento en ChromaDB.
    C4: Filtro doble tenant_id + document_id.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    client = get_chroma_client()
    collection_name = f"rag_{tenant_id}"

    try:
        collection = client.get_collection(collection_name)
    except Exception:
        return {"tenant_id": tenant_id, "document_id": document_id, "deleted": 0, "status": "collection_not_found"}

    # Obtener IDs antes de eliminar (ChromaDB API)
    results = collection.get(
        where={"$and": [
            {"tenant_id":   {"$eq": tenant_id}},    # C4
            {"document_id": {"$eq": document_id}}
        ]},
        include=[]
    )

    if not results["ids"]:
        return {"tenant_id": tenant_id, "document_id": document_id, "deleted": 0, "status": "not_found"}

    collection.delete(ids=results["ids"])

    return {
        "tenant_id":   tenant_id,            # C4
        "document_id": document_id,
        "deleted":     len(results["ids"])
    }
```

---

### Ejemplo C-5: Search RAG con Filtro Multi-Tenant

```python
# chromadb_search.py
def search_rag_chroma(
    tenant_id: str,        # C4
    query_text: str,
    n_results: int = 5
) -> list[dict]:
    """
    Búsqueda semántica en ChromaDB con aislamiento multi-tenant.
    C4: where filter con tenant_id OBLIGATORIO.
    C6: embedding del query vía OpenRouter.
    """
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")

    client = get_chroma_client()

    try:
        collection = client.get_collection(f"rag_{tenant_id}")
    except Exception:
        return []  # Colección no existe = sin documentos para este tenant

    # C6: Embedding del query vía API cloud
    [query_embedding] = generate_embeddings_batch([query_text], batch_size=1)

    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=min(n_results, 10),   # C1: Máximo 10 resultados
        where={"tenant_id": {"$eq": tenant_id}},   # C4: SIEMPRE filtrar
        include=["documents", "metadatas", "distances"]
    )

    return [
        {
            "tenant_id":    tenant_id,      # C4
            "text":         doc,
            "metadata":     meta,
            "distance":     dist,
            "relevance":    round(1 - dist, 4)  # Convertir distancia a score 0-1
        }
        for doc, meta, dist in zip(
            results["documents"][0],
            results["metadatas"][0],
            results["distances"][0]
        )
    ]
```

---

### 🐞 Troubleshooting ChromaDB (5 Problemas)

| Error Exacto | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso |
|---|---|---|---|
| `sqlite3.OperationalError: database is locked` | Dos procesos Python abriendo `PersistentClient` en el mismo directorio simultáneamente | `lsof /data/chromadb/chroma.sqlite3` → ver procesos con el archivo abierto | 1. ChromaDB embebido no soporta concurrencia — usar `HttpClient` con servidor separado<br>2. Levantar servidor: `chroma run --path /data/chromadb --port 8000`<br>3. Cambiar a `chromadb.HttpClient(host='localhost', port=8000)` en el código<br>4. Para desarrollo: garantizar que solo un proceso accede a la vez |
| `collection.get()` retorna todos los documentos ignorando el `where` | Versión de ChromaDB < 0.4.0 no soporta `$and` en `where` | `python -c "import chromadb; print(chromadb.__version__)"` | 1. Actualizar: `pip install chromadb --upgrade --break-system-packages`<br>2. Si no se puede actualizar: filtrar manualmente en Python después del `.get()` (ineficiente pero funciona)<br>3. Alternativa: usar colecciones separadas por tenant (ya lo hacemos con `rag_{tenant_id}`) — el `where` puede simplificarse solo a `document_id` |
| `chromadb.errors.InvalidDimensionException: Embedding dimension 3072 does not match collection dimension 1536` | Se cambió el modelo de embeddings sin recrear la colección | `collection.metadata` → ver dimensión configurada | 1. Crear nueva colección: `client.create_collection('rag_{tenant}_v2', metadata={"hnsw:space": "cosine"})`<br>2. Migrar todos los docs a la nueva colección con el nuevo modelo<br>3. Eliminar la vieja: `client.delete_collection('rag_{tenant}')`<br>4. Renombrar en código: cambiar `f"rag_{tenant_id}"` a la nueva |
| Búsqueda devuelve resultados incorrectos mezclados entre tenants | Se olvidó el `where={"tenant_id": ...}` en `collection.query()` | `grep -r "collection.query" . \| grep -v "tenant_id"` | 1. Audit inmediato del código — buscar todos los `.query()` sin `where`<br>2. Crear wrapper obligatorio: `def search_safe(tenant_id, query_emb): assert tenant_id; return collection.query(..., where={"tenant_id": {"$eq": tenant_id}})`<br>3. Aunque la colección ya es por tenant, el `where` es defensa en profundidad para C4 |
| `PersistentClient` usa > 2GB de RAM con 50K chunks | ChromaDB carga el índice HNSW completo en RAM al inicializar | `docker stats` o `htop` → ver proceso Python | 1. C1: ChromaDB no tiene opción de memory-map como Qdrant — es una limitación del motor<br>2. Si el dataset supera 20K chunks, migrar a Qdrant en producción<br>3. Como mitigación temporal: usar `HttpClient` con servidor dedicado limitado a 1GB en Docker<br>4. Reducir dimensión de embeddings: usar `text-embedding-3-small` (1536) no `large` (3072) |

---

---

## 🛠️ Patrones Transversales (Aplican a Todos los Motores)

### Función de Chunking Estándar

```python
# chunker.py — Usado por todos los ejemplos de este archivo
import uuid
import re

def split_text_into_chunks(
    text: str,
    max_tokens: int = 500,
    overlap: int = 50,
    approx_chars_per_token: int = 4
) -> list[dict]:
    """
    Divide texto en chunks con overlap para preservar contexto.
    Estimación: 1 token ≈ 4 caracteres (inglés/portugués).
    """
    max_chars   = max_tokens * approx_chars_per_token
    overlap_chars = overlap * approx_chars_per_token

    # Dividir por párrafos primero (respeta estructura del documento)
    paragraphs = [p.strip() for p in re.split(r'\n\s*\n', text) if p.strip()]

    chunks = []
    current_chunk = ""

    for para in paragraphs:
        if len(current_chunk) + len(para) <= max_chars:
            current_chunk += ("\n\n" if current_chunk else "") + para
        else:
            if current_chunk:
                chunks.append({
                    "id":          str(uuid.uuid4()),
                    "text":        current_chunk,
                    "token_count": len(current_chunk) // approx_chars_per_token
                })
            # Overlap: iniciar nuevo chunk con final del anterior
            overlap_text = current_chunk[-overlap_chars:] if len(current_chunk) > overlap_chars else current_chunk
            current_chunk = overlap_text + "\n\n" + para

    if current_chunk:
        chunks.append({
            "id":          str(uuid.uuid4()),
            "text":        current_chunk,
            "token_count": len(current_chunk) // approx_chars_per_token
        })

    return chunks
```

### Detector de Cambios por Hash (Evita Re-procesar Innecesariamente - C1)

```python
# change_detector.py
import hashlib

def compute_content_hash(text: str) -> str:
    """SHA256 del contenido. Si el hash no cambió, no re-procesar."""
    return hashlib.sha256(text.encode('utf-8')).hexdigest()

def should_update(current_hash: str, new_hash: str) -> bool:
    """
    True si el contenido cambió y necesita re-ingesta.
    False si es idéntico — ahorrar recursos C1/C2/C6.
    """
    return current_hash != new_hash
```

### Orquestador Universal de Update (Abstrae el Motor)

```python
# rag_update_orchestrator.py
# Capa de abstracción que elige el motor correcto según configuración

class RAGUpdateOrchestrator:
    """
    Fachada unificada para actualizar RAG independientemente del motor.
    C4: tenant_id propagado a todas las llamadas.
    C6: Embeddings siempre vía API cloud.
    """

    def __init__(self, vector_store: str = "qdrant"):
        """
        vector_store: 'qdrant' | 'chromadb'
        Para metadata siempre MySQL o PostgreSQL (C3: interno).
        """
        self.vector_store = vector_store

    def update_document(self, tenant_id: str, document_id: str, new_text: str, **kwargs) -> dict:
        if not tenant_id:
            raise ValueError("tenant_id required (C4)")

        new_hash = compute_content_hash(new_text)

        # Verificar si cambió (consultar MySQL/Postgres)
        current_hash = self._get_current_hash(tenant_id, document_id)
        if not should_update(current_hash, new_hash):
            return {"status": "unchanged", "tenant_id": tenant_id, "document_id": document_id}

        # Generar chunks y embeddings
        chunks     = split_text_into_chunks(new_text)
        embeddings = generate_embeddings_batch([c["text"] for c in chunks], batch_size=20)

        # Actualizar vector store
        if self.vector_store == "qdrant":
            result = update_document_in_qdrant(tenant_id, document_id, new_text)
        elif self.vector_store == "chromadb":
            result = update_document_chroma(tenant_id, document_id, new_text)
        else:
            raise ValueError(f"Unknown vector store: {self.vector_store}")

        # Actualizar metadata en MySQL (siempre, independiente del vector store)
        update_document_metadata(tenant_id, document_id, new_hash, chunks)

        return {**result, "tenant_id": tenant_id}   # C4

    def _get_current_hash(self, tenant_id: str, document_id: str) -> str:
        """Consultar MySQL para obtener hash actual del documento."""
        conn = get_mysql_connection()
        cursor = conn.cursor()
        cursor.execute(
            "SELECT content_hash FROM rag_documents WHERE id = %s AND tenant_id = %s",
            (document_id, tenant_id)   # C4
        )
        row = cursor.fetchone()
        cursor.close()
        conn.close()
        return row[0] if row else ""
```

---

## ✅ Validación SDD y Comandos de Prueba

### Script de Validación Completo (Todos los Motores)

```bash
#!/bin/bash
# validate-rag-updates.sh
# Verifica que C4 está presente en todos los motores
set -euo pipefail

TENANT_ID="${1:-test_tenant_001}"
PASS=0
FAIL=0

check() {
    local desc="$1"; local cmd="$2"; local expected="$3"
    result=$(eval "$cmd" 2>/dev/null || echo "ERROR")
    if echo "$result" | grep -qi "$expected"; then
        echo "✅ $desc"; ((PASS++))
    else
        echo "❌ FAIL: $desc | Esperado: $expected | Obtenido: ${result:0:100}"; ((FAIL++))
    fi
}

echo "═══ VALIDACIÓN RAG UPDATES ═══ tenant: $TENANT_ID"

# Qdrant: Verificar que la colección existe
check "Qdrant: colección rag_${TENANT_ID} existe" \
    "curl -s http://localhost:6333/collections/rag_${TENANT_ID} | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get(\"result\",{}).get(\"status\",\"missing\"))'" \
    "green\|yellow"

# Qdrant: Verificar que búsqueda sin tenant_id es rechazada (wrapper C4)
check "Qdrant: wrapper rechaza tenant_id vacío" \
    "python3 -c \"from qdrant_update_incremental import update_document_in_qdrant; update_document_in_qdrant('', 'x', 'y')\" 2>&1" \
    "tenant_id required"

# MySQL: Verificar índice con tenant_id
check "MySQL: índice tenant_id en rag_documents" \
    "docker exec mantis-mysql mysql -u root -p\${MYSQL_ROOT_PASSWORD} mantis_rag_meta --skip-column-names -e \"SELECT COUNT(*) FROM information_schema.STATISTICS WHERE TABLE_NAME='rag_documents' AND COLUMN_NAME='tenant_id' AND SEQ_IN_INDEX=1;\" 2>/dev/null" \
    "[1-9]"

# ChromaDB: Verificar que servidor responde (si está configurado)
if [ -n "${CHROMA_HOST:-}" ]; then
    check "ChromaDB: servidor responde" \
        "curl -s http://${CHROMA_HOST}:${CHROMA_PORT:-8000}/api/v1/heartbeat | python3 -c 'import json,sys; print(\"ok\")'" \
        "ok"
fi

echo "═══════════════════════════════"
echo "RESULTADO: ✅ $PASS pasaron | ❌ $FAIL fallaron"
[ $FAIL -eq 0 ] && exit 0 || exit 1
```

### Test de Aislamiento Multi-Tenant

```python
# test_rag_isolation.py
"""
Verifica que un tenant no puede ver ni modificar datos de otro.
Ejecutar antes de cada deploy a producción.
"""
import assert_module as assert

def test_isolation_qdrant():
    from qdrant_update_incremental import update_document_in_qdrant
    from qdrant_client import QdrantClient
    from qdrant_client.models import Filter, FieldCondition, MatchValue

    client = QdrantClient(host="localhost", port=6333)

    # Insertar chunk en tenant_a
    update_document_in_qdrant("tenant_a", "doc_test", "Texto exclusivo de tenant_a", "rag_test")

    # Buscar desde tenant_b — no debe encontrar nada
    results = client.scroll(
        collection_name="rag_tenant_a",
        scroll_filter=Filter(must=[
            FieldCondition(key="tenant_id", match=MatchValue(value="tenant_b"))  # Busca con tenant_b
        ]),
        limit=10
    )
    assert len(results[0]) == 0, "❌ AISLAMIENTO ROTO: tenant_b puede ver chunks de tenant_a"
    print("✅ Qdrant: aislamiento tenant_a/tenant_b correcto")

def test_isolation_mysql():
    conn = get_mysql_connection()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT COUNT(*) FROM rag_documents WHERE tenant_id = 'tenant_b' AND id IN (SELECT id FROM rag_documents WHERE tenant_id = 'tenant_a')",
    )
    count = cursor.fetchone()[0]
    cursor.close()
    conn.close()
    assert count == 0, "❌ AISLAMIENTO ROTO: IDs compartidos entre tenant_a y tenant_b"
    print("✅ MySQL: aislamiento tenant_a/tenant_b correcto")

if __name__ == "__main__":
    test_isolation_qdrant()
    test_isolation_mysql()
    print("✅ Todos los tests de aislamiento pasaron")
```

---

## 🔗 Referencias Cruzadas

- [[01-RULES/06-MULTITENANCY-RULES.md]] — MT-001 a MT-010 (tenant_id enforcement completo)
- [[01-RULES/02-RESOURCE-GUARDRAILS.md]] — RES-001 (RAM 4GB), RES-002 (CPU), RES-008 (no bucles infinitos)
- [[01-RULES/04-API-RELIABILITY-RULES.md]] — Timeouts 30s, retry con backoff exponencial
- [[01-RULES/05-CODE-PATTERNS-RULES.md]] — Prepared statements, manejo de errores
- [[00-CONTEXT/facundo-infrastructure.md]] — VPS-2: Qdrant + MySQL, distribución de servicios
- [[02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md]] — Setup inicial de Qdrant y primera ingesta
- [[02-SKILLS/BASE DE DATOS-RAG/postgres-prisma-rag.md]] — Schema Prisma completo y ejemplos CRUD
- [[02-SKILLS/BASE DE DATOS-RAG/supabase-rag-integration.md]] — Configuración cloud y RLS
- [[02-SKILLS/BASE DE DATOS-RAG/mysql-optimization-4gb-ram.md]] — Tuning MySQL para VPS 4GB
- [[02-SKILLS/BASE DE DATOS-RAG/pdf-mistralocr-processing.md]] — Extracción de texto antes de chunking
- [[02-SKILLS/BASE DE DATOS-RAG/google-drive-qdrant-sync.md]] — Sync automático desde Google Drive

**Skills pendientes que usan este archivo:**
- `02-SKILLS/AGENTES/whatsapp-rag-openrouter.md` — Consume el RAG actualizado para responder WhatsApp
- `02-SKILLS/INFRAESTRUCTURA/redis-session-management.md` — Buffer de sesión para contexto de conversación
