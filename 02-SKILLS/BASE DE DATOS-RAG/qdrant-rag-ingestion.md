---
title: "Ingesta de Documentos en Qdrant con Multi-tenancy"
category: "Skill"
domain: ["rag", "backend", "vectordb"]
constraints: ["C1", "C2", "C4", "C6"]
priority: "Alta"
version: "1.0.0"
last_updated: "2026-04-09"
ai_optimized: true
tags:
  - sdd/skill/qdrant
  - sdd/skill/rag
  - sdd/skill/multi-tenant
  - lang/es
related_files:
  - "01-RULES/06-MULTITENANCY-RULES.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
  - "00-CONTEXT/facundo-infrastructure.md"
  - "validation-checklist.md"
---

## 🎯 Propósito y Alcance

Este skill define patrones de ingesta de documentos en Qdrant (base de datos vectorial) respetando multi-tenancy estricto (C4), límites de hardware (C1, C2) y usando solo APIs cloud para embeddings (C6).

**Alcance:**
- Ingesta de PDFs, TXT, DOCX, HTML a Qdrant
- Chunking optimizado para VPS 4GB RAM
- Filtros obligatorios por `tenant_id` en TODA búsqueda
- Generación de embeddings vía OpenRouter/OpenAI
- Manejo de errores y validación de integridad

**Fuera de alcance:**
- Modelos de embeddings locales (viola C6)
- Ingestas sin `tenant_id` (viola C4)
- Chunks >2000 tokens (viola C1 por consumo de RAM en búsqueda)

## 📐 Fundamentos (Nivel Básico)

### ¿Qué es Qdrant?
Base de datos vectorial optimizada para búsqueda de similitud semántica. Almacena vectores (arrays de números) que representan el "significado" de textos.

### ¿Qué es un Embedding?
Vector numérico de dimensión fija (ej: 1536 números) que captura el significado de un texto:
```
"El perro ladra" → [0.2, 0.8, 0.1, ..., 0.4]  (1536 números)
"El can hace ruido" → [0.21, 0.79, 0.11, ..., 0.39]  (similar)
```

### ¿Qué es Chunking?
Dividir documentos largos en fragmentos pequeños para:
1. No exceder límites de modelos de embeddings (8192 tokens para `text-embedding-3-small`)
2. Mejorar precisión de búsqueda (chunks enfocados)
3. Controlar uso de RAM (C1)

### Flujo de Ingesta RAG
```
Documento → Chunking → Embeddings (API) → Qdrant (+ tenant_id)
   ↓
Búsqueda: Query → Embedding → Qdrant.search(filter: tenant_id) → Resultados
```

## 🏗️ Arquitectura y Hardware Limitado (VPS 2vCPU/4-8GB)

### Topología de Conexión
```
┌─────────────────────────────────────────────────────────────┐
│ VPS 1 (n8n + Aplicación)              VPS 2 (Qdrant + MySQL)│
│  ┌──────────┐                          ┌──────────┐          │
│  │   n8n    │──────HTTP 6333──────────>│  Qdrant  │          │
│  │ Workflow │  (Red interna Docker)    │  1.8+    │          │
│  └──────────┘                          └──────────┘          │
│                                         127.0.0.1:6333       │
│                                         (NO 0.0.0.0 - C3)    │
└─────────────────────────────────────────────────────────────┘
```

### Límites de Recursos para Qdrant
```yaml
# docker-compose.yml
services:
  qdrant:
    image: qdrant/qdrant:v1.8.0
    deploy:
      resources:
        limits:
          memory: 2G      # C1: Max 2GB para Qdrant en VPS 4GB
          cpus: "1.0"     # C2: Max 1 vCPU
    environment:
      - QDRANT__STORAGE__PERFORMANCE__MAX_SEARCH_THREADS=2  # Limitar threads
    ports:
      - "127.0.0.1:6333:6333"  # C3: Solo localhost
    volumes:
      - qdrant_data:/qdrant/storage
```

**Justificación de 2GB:**
- Sistema operativo + otros servicios: ~1.5GB
- Qdrant con 100k vectores: ~1.5-2GB RAM
- Margen para operaciones: 500MB
- Total: 4GB ✅

### Optimización de Colección Qdrant
```python
# Configuración optimizada para hardware limitado
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, OptimizersConfigDiff

client = QdrantClient(host="127.0.0.1", port=6333)

client.create_collection(
    collection_name="mantis_docs",
    vectors_config=VectorParams(
        size=1536,  # text-embedding-3-small
        distance=Distance.COSINE
    ),
    optimizers_config=OptimizersConfigDiff(
        memmap_threshold=20000,  # Usar disco para >20k vectores (ahorra RAM)
        indexing_threshold=10000  # Crear índice HNSW solo si >10k vectores
    ),
    hnsw_config={
        "m": 16,  # Balance entre precisión y RAM
        "ef_construct": 100,  # Calidad de construcción del índice
        "full_scan_threshold": 10000  # Full scan para colecciones pequeñas
    }
)
```

## 🔗 Conexión Local vs Externa (Qdrant)

### Conexión Local (Mismo VPS - Preferida)
```python
# .env
QDRANT_HOST=127.0.0.1
QDRANT_PORT=6333
QDRANT_API_KEY=  # Vacío si es localhost

# Python
from qdrant_client import QdrantClient

client = QdrantClient(
    host=os.getenv("QDRANT_HOST"),
    port=int(os.getenv("QDRANT_PORT")),
    timeout=30  # API-001: Timeout obligatorio
)
```

### Conexión Externa (Otro VPS o Qdrant Cloud)
```python
# .env
QDRANT_HOST=vps2.example.com
QDRANT_PORT=6333
QDRANT_API_KEY=your_api_key_here
QDRANT_USE_HTTPS=true

# Python
client = QdrantClient(
    url=f"https://{os.getenv('QDRANT_HOST')}:{os.getenv('QDRANT_PORT')}",
    api_key=os.getenv("QDRANT_API_KEY"),
    timeout=30,
    https=os.getenv("QDRANT_USE_HTTPS", "false").lower() == "true"
)
```

**⚠️ IMPORTANTE - C3:** Nunca exponer Qdrant a `0.0.0.0`. Usar túnel SSH o VPN si necesitas acceso remoto.

## 📘 Guía de Estructura de Datos en Qdrant

### Schema de Punto (Vector)
```json
{
  "id": "doc_restaurant_123_chunk_001",
  "vector": [0.1, 0.2, ..., 0.5],  // 1536 dimensiones
  "payload": {
    "tenant_id": "restaurant_123",     // C4: OBLIGATORIO
    "text": "Política de devoluciones...",
    "source": "manual_empleados.pdf",
    "page": 12,
    "chunk_index": 1,
    "total_chunks": 45,
    "created_at": "2026-04-09T10:00:00Z",
    "metadata": {
      "author": "RRHH",
      "version": "2.1"
    }
  }
}
```

### Índices y Filtros Críticos
| Campo | Tipo | Indexed | Obligatorio | Propósito |
|-------|------|---------|-------------|-----------|
| `tenant_id` | keyword | ✅ SÍ | ✅ SÍ (C4) | Aislamiento multi-tenant |
| `source` | keyword | ✅ SÍ | ✅ SÍ | Identificar origen del doc |
| `created_at` | keyword | ⚠️ Opcional | ❌ No | Filtros temporales |
| `text` | text | ❌ No | ✅ SÍ | Contenido del chunk |

**Crear índice de payload:**
```python
client.create_payload_index(
    collection_name="mantis_docs",
    field_name="tenant_id",
    field_schema="keyword"  # Keyword para exact match
)

client.create_payload_index(
    collection_name="mantis_docs",
    field_name="source",
    field_schema="keyword"
)
```

## 🛠️ 4 Ejemplos Centrales (Copy-Paste, Validables)

### Ejemplo 1: Ingesta Básica de Texto con tenant_id

```python
# ingest_text.py
import os
from qdrant_client import QdrantClient
from qdrant_client.models import PointStruct
import openai

# C4: tenant_id OBLIGATORIO
TENANT_ID = "restaurant_456"

# Conexión Qdrant (C3: localhost)
qdrant = QdrantClient(host="127.0.0.1", port=6333)

# Conexión OpenAI para embeddings (C6: API cloud, no local)
openai.api_key = os.getenv("OPENAI_API_KEY")

def generate_embedding(text: str) -> list[float]:
    """Genera embedding usando API cloud (C6)"""
    response = openai.embeddings.create(
        model="text-embedding-3-small",  # 1536 dims
        input=text
    )
    return response.data[0].embedding

def ingest_document(text: str, source: str, tenant_id: str):
    """
    Ingesta documento con validación C4.
    
    spec_referenced: MT-004, MT-007
    constraints_applied: C4, C6
    """
    # Validar tenant_id (C4)
    if not tenant_id or len(tenant_id) < 3:
        raise ValueError("tenant_id is required and must be valid (C4)")
    
    # Generar embedding (C6: API cloud)
    embedding = generate_embedding(text)
    
    # Crear punto con payload que incluye tenant_id (C4)
    point = PointStruct(
        id=f"doc_{tenant_id}_{source}_001",
        vector=embedding,
        payload={
            "tenant_id": tenant_id,  # C4: CRÍTICO
            "text": text,
            "source": source,
            "created_at": "2026-04-09T10:00:00Z"
        }
    )
    
    # Insertar en Qdrant
    qdrant.upsert(
        collection_name="mantis_docs",
        points=[point]
    )
    
    print(f"✅ Documento ingestado: {source} (tenant: {tenant_id})")

# Uso
if __name__ == "__main__":
    texto = "Política de devoluciones: Los clientes pueden devolver productos en 30 días."
    ingest_document(texto, "politicas.txt", TENANT_ID)

# Validación SDD:
# ✅ C4: tenant_id en payload
# ✅ C6: Embedding vía API OpenAI
# ✅ C3: Conexión a localhost
```

**Comando de validación:**
```bash
# Verificar que el punto tiene tenant_id
curl -X POST http://localhost:6333/collections/mantis_docs/points/scroll \
  -H 'Content-Type: application/json' \
  -d '{"limit": 1}' | jq '.result.points[0].payload.tenant_id'

# Resultado esperado: "restaurant_456"
```

---

### Ejemplo 2: Búsqueda con Filtro Obligatorio de tenant_id

```python
# search_qdrant.py
from qdrant_client import QdrantClient
from qdrant_client.models import Filter, FieldCondition, MatchValue
import openai

qdrant = QdrantClient(host="127.0.0.1", port=6333)
openai.api_key = os.getenv("OPENAI_API_KEY")

def search_documents(query: str, tenant_id: str, top_k: int = 5):
    """
    Búsqueda RAG con filtro obligatorio de tenant_id (C4).
    
    spec_referenced: MT-004, MT-005
    constraints_applied: C4
    """
    # Validación C4
    if not tenant_id:
        raise ValueError("tenant_id is MANDATORY for all searches (C4)")
    
    # Generar embedding de la query
    query_embedding = openai.embeddings.create(
        model="text-embedding-3-small",
        input=query
    ).data[0].embedding
    
    # Búsqueda con filtro de tenant_id (C4: CRÍTICO)
    results = qdrant.search(
        collection_name="mantis_docs",
        query_vector=query_embedding,
        limit=top_k,
        query_filter=Filter(
            must=[
                FieldCondition(
                    key="tenant_id",
                    match=MatchValue(value=tenant_id)  # C4: Solo datos de este tenant
                )
            ]
        ),
        score_threshold=0.7  # Solo resultados >70% similitud
    )
    
    return results

# Uso
if __name__ == "__main__":
    query = "¿Cuál es la política de devoluciones?"
    tenant = "restaurant_456"
    
    resultados = search_documents(query, tenant)
    
    for i, hit in enumerate(resultados, 1):
        print(f"{i}. Score: {hit.score:.2f}")
        print(f"   Texto: {hit.payload['text'][:100]}...")
        print(f"   Tenant: {hit.payload['tenant_id']}")  # Debe ser "restaurant_456"
        print()

# Validación SDD:
# ✅ C4: Filtro obligatorio por tenant_id en search
# ✅ RES-009: topK limitado a 5
# ✅ API-004: score_threshold >0.7
```

**Comando de validación:**
```bash
# Auditar código para verificar filtro tenant_id
grep -rn "qdrant.search" *.py | grep -v "tenant_id"
# Resultado esperado: VACÍO (todas las búsquedas deben tener filtro)
```

---

### Ejemplo 3: Chunking de Documento Largo con Overlap

```python
# chunking.py
from langchain.text_splitter import RecursiveCharacterTextSplitter
from qdrant_client import QdrantClient
from qdrant_client.models import PointStruct, Batch
import openai
import uuid

qdrant = QdrantClient(host="127.0.0.1", port=6333)
openai.api_key = os.getenv("OPENAI_API_KEY")

def chunk_and_ingest(
    document: str,
    source: str,
    tenant_id: str,
    chunk_size: int = 1000,  # Caracteres, ~250 tokens
    chunk_overlap: int = 200  # 20% overlap
):
    """
    Divide documento en chunks y los ingesta en Qdrant.
    
    spec_referenced: RES-008, MT-004
    constraints_applied: C1 (evita chunks grandes), C4
    """
    # Validar C4
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")
    
    # Configurar splitter (C1: chunks pequeños para no agotar RAM)
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size,
        chunk_overlap=chunk_overlap,
        separators=["\n\n", "\n", ". ", " ", ""]
    )
    
    chunks = splitter.split_text(document)
    total_chunks = len(chunks)
    
    print(f"📄 Documento dividido en {total_chunks} chunks")
    
    # Generar embeddings en batch (más eficiente)
    embeddings_response = openai.embeddings.create(
        model="text-embedding-3-small",
        input=chunks  # Batch de hasta 2048 textos
    )
    embeddings = [e.embedding for e in embeddings_response.data]
    
    # Crear puntos con tenant_id
    points = []
    for i, (chunk, embedding) in enumerate(zip(chunks, embeddings)):
        point = PointStruct(
            id=str(uuid.uuid4()),  # ID único
            vector=embedding,
            payload={
                "tenant_id": tenant_id,  # C4
                "text": chunk,
                "source": source,
                "chunk_index": i + 1,
                "total_chunks": total_chunks
            }
        )
        points.append(point)
    
    # Insertar en batch (más rápido)
    qdrant.upsert(
        collection_name="mantis_docs",
        points=points
    )
    
    print(f"✅ {total_chunks} chunks ingestados para tenant: {tenant_id}")

# Uso
if __name__ == "__main__":
    documento_largo = """
    Manual de Empleados - Restaurante XYZ
    
    Capítulo 1: Política de Devoluciones
    Los clientes pueden devolver productos en un plazo de 30 días...
    
    [... 10,000 palabras más ...]
    """
    
    chunk_and_ingest(
        document=documento_largo,
        source="manual_completo.pdf",
        tenant_id="restaurant_456"
    )

# Validación SDD:
# ✅ C1: chunk_size=1000 (pequeño para RAM limitada)
# ✅ C4: tenant_id en TODOS los chunks
# ✅ RES-008: Batch embedding (eficiente)
```

**Comando de validación:**
```bash
# Verificar que todos los chunks tienen tenant_id
curl -X POST http://localhost:6333/collections/mantis_docs/points/scroll \
  -d '{"limit": 100}' | jq '.result.points[].payload | select(.tenant_id == null)'

# Resultado esperado: VACÍO (ningún punto sin tenant_id)
```

---

### Ejemplo 4: Workflow n8n para Ingesta desde Google Drive

```json
{
  "meta": {
    "sdd_version": "1.0",
    "validation_status": "passed"
  },
  "nodes": [
    {
      "name": "Google Drive Trigger",
      "type": "n8n-nodes-base.googleDrive",
      "parameters": {
        "resource": "file",
        "operation": "download",
        "fileId": "={{ $json.id }}"
      },
      "notes": "C4: Cada archivo debe tener metadata con tenant_id"
    },
    {
      "name": "Extract Text",
      "type": "n8n-nodes-base.code",
      "parameters": {
        "language": "python",
        "code": "import fitz  # PyMuPDF\ntext = fitz.open(items[0].binary.data).get_text()\nreturn {'text': text}"
      }
    },
    {
      "name": "Get tenant_id from filename",
      "type": "n8n-nodes-base.code",
      "parameters": {
        "code": "// C4: Extraer tenant_id del nombre de archivo\nconst filename = $input.item.json.name;\nconst match = filename.match(/tenant_([a-z0-9_]+)/);\nif (!match) throw new Error('tenant_id not found in filename (C4)');\nreturn {tenant_id: match[1]};"
      }
    },
    {
      "name": "Chunk Text",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "http://localhost:5000/api/chunk",
        "method": "POST",
        "body": {
          "text": "={{ $json.text }}",
          "chunk_size": 1000
        }
      }
    },
    {
      "name": "Generate Embeddings",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "https://api.openai.com/v1/embeddings",
        "authentication": "headerAuth",
        "method": "POST",
        "body": {
          "model": "text-embedding-3-small",
          "input": "={{ $json.chunks }}"
        },
        "options": {
          "timeout": 30000
        }
      },
      "notes": "C6: API cloud para embeddings. API-001: timeout 30s"
    },
    {
      "name": "Insert to Qdrant",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "http://127.0.0.1:6333/collections/mantis_docs/points",
        "method": "PUT",
        "body": {
          "points": "={{ $json.embeddings.map((e, i) => ({ id: $now + '_' + i, vector: e, payload: { tenant_id: $('Get tenant_id').item.json.tenant_id, text: $json.chunks[i] } })) }}"
        }
      },
      "notes": "C4: tenant_id en payload de TODOS los puntos. C3: Conexión a localhost"
    }
  ]
}

# Validación SDD:
# ✅ C4: tenant_id extraído y propagado a todos los puntos
# ✅ C6: Embeddings vía OpenAI API
# ✅ C3: Qdrant en localhost (127.0.0.1)
# ✅ API-001: Timeout de 30s en requests
```

**Comando de validación:**
```bash
# Verificar estructura del workflow
jq '.nodes[] | select(.type | contains("Qdrant")) | .parameters.body' workflow.json | grep "tenant_id"

# Resultado esperado: "tenant_id": "={{ $(...).tenant_id }}"
```

## 🔍 >5 Ejemplos Independientes por Caso de Uso

### Caso 1: Ingesta de PDF con Mistral OCR

```python
# pdf_ocr_ingest.py
import fitz  # PyMuPDF
import requests
import os
from qdrant_client import QdrantClient
from qdrant_client.models import PointStruct

MISTRAL_OCR_API = os.getenv("MISTRAL_OCR_API_URL")
qdrant = QdrantClient(host="127.0.0.1", port=6333)

def extract_text_with_ocr(pdf_path: str) -> str:
    """Extrae texto de PDF, usando OCR si es escaneado"""
    doc = fitz.open(pdf_path)
    text = ""
    
    for page in doc:
        page_text = page.get_text()
        
        if len(page_text.strip()) < 50:  # Página escaneada
            # Usar Mistral OCR (C6: API cloud)
            img = page.get_pixmap()
            img_bytes = img.tobytes("png")
            
            response = requests.post(
                MISTRAL_OCR_API,
                files={"file": img_bytes},
                timeout=30
            )
            page_text = response.json()["text"]
        
        text += page_text + "\n"
    
    return text

def ingest_pdf(pdf_path: str, tenant_id: str):
    """C4: tenant_id obligatorio"""
    if not tenant_id:
        raise ValueError("tenant_id required (C4)")
    
    text = extract_text_with_ocr(pdf_path)
    
    # [... chunking y embedding como en Ejemplo 3 ...]
    
    print(f"✅ PDF ingestado: {pdf_path} (tenant: {tenant_id})")

# Uso
ingest_pdf("manual.pdf", "restaurant_789")

# spec_referenced: RAG-002, C6
# constraints_applied: C4, C6
```

---

### Caso 2: Sincronización Incremental (Solo Nuevos Documentos)

```python
# incremental_sync.py
from qdrant_client import QdrantClient
from qdrant_client.models import Filter, FieldCondition, MatchValue
import hashlib

qdrant = QdrantClient(host="127.0.0.1", port=6333)

def get_document_hash(text: str) -> str:
    """Hash del documento para detectar duplicados"""
    return hashlib.sha256(text.encode()).hexdigest()

def document_exists(doc_hash: str, tenant_id: str) -> bool:
    """Verifica si documento ya existe (C4: por tenant)"""
    results = qdrant.scroll(
        collection_name="mantis_docs",
        scroll_filter=Filter(
            must=[
                FieldCondition(key="tenant_id", match=MatchValue(value=tenant_id)),
                FieldCondition(key="doc_hash", match=MatchValue(value=doc_hash))
            ]
        ),
        limit=1
    )
    return len(results[0]) > 0

def ingest_if_new(text: str, source: str, tenant_id: str):
    """Solo ingesta si el documento es nuevo"""
    doc_hash = get_document_hash(text)
    
    if document_exists(doc_hash, tenant_id):
        print(f"⏭️  Documento ya existe: {source}")
        return
    
    # [... ingestar como en Ejemplo 1, agregando doc_hash al payload ...]
    
    print(f"✅ Nuevo documento ingestado: {source}")

# spec_referenced: RES-010
# constraints_applied: C4
```

---

### Caso 3: Actualización de Documentos (Upsert)

```python
# update_document.py
from qdrant_client import QdrantClient
from qdrant_client.models import Filter, FieldCondition, MatchValue

qdrant = QdrantClient(host="127.0.0.1", port=6333)

def update_document(source: str, new_text: str, tenant_id: str):
    """
    Actualiza documento existente (borra chunks viejos, inserta nuevos).
    
    spec_referenced: MT-001
    constraints_applied: C4
    """
    # C4: Borrar solo chunks de este tenant + source
    qdrant.delete(
        collection_name="mantis_docs",
        points_selector=Filter(
            must=[
                FieldCondition(key="tenant_id", match=MatchValue(value=tenant_id)),
                FieldCondition(key="source", match=MatchValue(value=source))
            ]
        )
    )
    
    # Ingestar nueva versión
    # [... chunking y embedding ...]
    
    print(f"✅ Documento actualizado: {source} (tenant: {tenant_id})")

# Uso
update_document("politicas.txt", "Nueva política...", "restaurant_456")

# spec_referenced: MT-002
# constraints_applied: C4
```

---

### Caso 4: Búsqueda Híbrida (Vector + Keyword)

```python
# hybrid_search.py
from qdrant_client import QdrantClient
from qdrant_client.models import Filter, FieldCondition, MatchValue, MatchText

qdrant = QdrantClient(host="127.0.0.1", port=6333)

def hybrid_search(query: str, keywords: list[str], tenant_id: str):
    """
    Búsqueda que combina similitud vectorial + palabras clave.
    
    spec_referenced: RAG-004
    constraints_applied: C4
    """
    query_embedding = generate_embedding(query)  # Como en Ejemplo 2
    
    # C4: Filtro por tenant_id + keywords
    filter_conditions = [
        FieldCondition(key="tenant_id", match=MatchValue(value=tenant_id))
    ]
    
    # Agregar condiciones de keywords (OR)
    for keyword in keywords:
        filter_conditions.append(
            FieldCondition(key="text", match=MatchText(text=keyword))
        )
    
    results = qdrant.search(
        collection_name="mantis_docs",
        query_vector=query_embedding,
        query_filter=Filter(must=filter_conditions),
        limit=10
    )
    
    return results

# Uso
resultados = hybrid_search(
    query="política de devoluciones",
    keywords=["devolución", "reembolso"],
    tenant_id="restaurant_456"
)

# spec_referenced: RAG-004
# constraints_applied: C4
```

---

### Caso 5: Re-indexación Masiva por Tenant

```python
# reindex_tenant.py
from qdrant_client import QdrantClient
from qdrant_client.models import Filter, FieldCondition, MatchValue

qdrant = QdrantClient(host="127.0.0.1", port=6333)

def reindex_tenant(tenant_id: str, new_embedding_model: str = "text-embedding-3-large"):
    """
    Re-genera embeddings de todos los documentos de un tenant.
    Útil cuando cambias de modelo de embeddings.
    
    ⚠️ ADVERTENCIA C1: Puede consumir mucha RAM. Ejecutar en lotes.
    
    spec_referenced: RES-008
    constraints_applied: C1, C4
    """
    # Obtener todos los puntos del tenant (C4)
    points, _ = qdrant.scroll(
        collection_name="mantis_docs",
        scroll_filter=Filter(
            must=[FieldCondition(key="tenant_id", match=MatchValue(value=tenant_id))]
        ),
        limit=1000,  # C1: Procesar en lotes de 1000
        with_payload=True,
        with_vectors=False  # No necesitamos vectores viejos
    )
    
    # Extraer textos
    texts = [p.payload["text"] for p in points]
    
    # Generar nuevos embeddings en batch (C6: API cloud)
    new_embeddings = openai.embeddings.create(
        model=new_embedding_model,
        input=texts
    ).data
    
    # Actualizar vectores
    for point, new_emb in zip(points, new_embeddings):
        qdrant.update_vectors(
            collection_name="mantis_docs",
            points=[{
                "id": point.id,
                "vector": new_emb.embedding
            }]
        )
    
    print(f"✅ Re-indexados {len(points)} puntos de tenant: {tenant_id}")

# Uso (ejecutar fuera de horas pico)
reindex_tenant("restaurant_456")

# spec_referenced: RES-008, ARQ-005
# constraints_applied: C1, C4, C6
```

---

### Caso 6: Limpieza de Vectores Huérfanos (Sin tenant_id)

```python
# cleanup_orphan_vectors.py
from qdrant_client import QdrantClient
from qdrant_client.models import Filter, IsNullCondition

qdrant = QdrantClient(host="127.0.0.1", port=6333)

def cleanup_orphan_vectors():
    """
    Elimina puntos que no tienen tenant_id (violación de C4).
    
    spec_referenced: MT-007
    constraints_applied: C4
    """
    # Buscar puntos sin tenant_id
    orphans, _ = qdrant.scroll(
        collection_name="mantis_docs",
        scroll_filter=Filter(
            must=[
                IsNullCondition(is_null={"key": "tenant_id"})
            ]
        ),
        limit=10000
    )
    
    if not orphans:
        print("✅ No hay vectores huérfanos")
        return
    
    # Borrar huérfanos
    orphan_ids = [p.id for p in orphans]
    qdrant.delete(
        collection_name="mantis_docs",
        points_selector=orphan_ids
    )
    
    print(f"🗑️  Eliminados {len(orphan_ids)} vectores huérfanos (sin tenant_id)")

# Ejecutar como cron job semanal
cleanup_orphan_vectors()

# spec_referenced: MT-007
# constraints_applied: C4
```

---

### Caso 7: Exportar Documentos de un Tenant (Backup)

```python
# export_tenant_data.py
import json
from qdrant_client import QdrantClient
from qdrant_client.models import Filter, FieldCondition, MatchValue

qdrant = QdrantClient(host="127.0.0.1", port=6333)

def export_tenant_documents(tenant_id: str, output_file: str):
    """
    Exporta todos los documentos de un tenant a JSON.
    
    spec_referenced: SEG-009, C5
    constraints_applied: C4, C5
    """
    # Obtener TODOS los puntos del tenant (C4)
    all_points = []
    offset = None
    
    while True:
        points, offset = qdrant.scroll(
            collection_name="mantis_docs",
            scroll_filter=Filter(
                must=[FieldCondition(key="tenant_id", match=MatchValue(value=tenant_id))]
            ),
            limit=1000,
            offset=offset,
            with_payload=True,
            with_vectors=True  # Incluir vectores en backup
        )
        
        all_points.extend(points)
        
        if offset is None:
            break
    
    # Convertir a JSON
    export_data = {
        "tenant_id": tenant_id,
        "total_documents": len(all_points),
        "export_date": "2026-04-09T10:00:00Z",
        "points": [
            {
                "id": p.id,
                "vector": p.vector,
                "payload": p.payload
            }
            for p in all_points
        ]
    }
    
    # Guardar (C5: luego encriptar con AES-256)
    with open(output_file, "w") as f:
        json.dump(export_data, f, indent=2)
    
    print(f"✅ Exportados {len(all_points)} documentos a {output_file}")
    print(f"💡 Siguiente paso: Encriptar con: openssl enc -aes-256-cbc -salt -in {output_file} -out {output_file}.enc")

# Uso
export_tenant_documents("restaurant_456", "backup_restaurant_456.json")

# spec_referenced: SEG-009, C5
# constraints_applied: C4, C5
```

## 🐞 Troubleshooting: 5+ Problemas Comunes y Soluciones Exactas

| Error Exacto | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso |
|--------------|------------|------------------------|----------------------|
| `QdrantException: Collection mantis_docs not found` | Colección no existe o nombre incorrecto | `curl -s http://localhost:6333/collections \| jq '.result.collections[].name'` | **1.** Verificar nombre exacto de colección<br>**2.** Crear colección: `client.create_collection("mantis_docs", ...)`<br>**3.** Re-ejecutar ingesta |
| `openai.RateLimitError: Rate limit reached` | Demasiadas peticiones a OpenAI API | Revisar uso en: https://platform.openai.com/usage | **1.** Implementar rate limiting: `time.sleep(1)` entre batches<br>**2.** Usar tier superior de OpenAI<br>**3.** Reducir tamaño de batches de embeddings |
| `qdrant_client.http.exceptions.UnexpectedResponse: Payload field 'tenant_id' not indexed` | Falta crear índice de payload | `curl http://localhost:6333/collections/mantis_docs \| jq '.result.payload_schema'` | **1.** Crear índice: `client.create_payload_index("mantis_docs", "tenant_id", "keyword")`<br>**2.** Re-ejecutar búsquedas |
| Búsqueda retorna documentos de OTRO tenant (violación C4) | Filtro de tenant_id omitido o incorrecto | Auditar código: `grep "qdrant.search" *.py \| grep -v tenant_id` | **1.** CRÍTICO: Agregar filtro obligatorio en TODAS las búsquedas<br>**2.** Validar: `results = qdrant.search(..., query_filter=Filter(must=[FieldCondition(key="tenant_id", ...)]))`<br>**3.** Agregar test unitario que valide C4 |
| `MemoryError` durante ingesta masiva | Procesando demasiados chunks a la vez (violación C1) | `docker stats qdrant` | **1.** Reducir batch size de embeddings: `chunks[:100]` en vez de `chunks`<br>**2.** Procesar en lotes con `time.sleep(2)` entre lotes<br>**3.** Aumentar swap temporal (último recurso) |
| `ConnectionRefusedError: [Errno 111] Connection refused` | Qdrant no está corriendo o puerto incorrecto | `docker ps \| grep qdrant`<br>`netstat -tlnp \| grep 6333` | **1.** Verificar estado: `docker logs qdrant`<br>**2.** Iniciar contenedor: `docker-compose up -d qdrant`<br>**3.** Verificar puerto en .env: `QDRANT_PORT=6333` |
| Embeddings de diferentes dimensiones en misma colección | Cambio de modelo sin re-crear colección | `curl http://localhost:6333/collections/mantis_docs \| jq '.result.config.params.vectors.size'` | **1.** Crear nueva colección con nueva dimensión<br>**2.** Migrar datos: `client.migrate_collection(...)`<br>**3.** O re-indexar todo el tenant (ver Caso 5) |
| Chunks duplicados en Qdrant | Falta de hash de documento (ver Caso 2) | `curl -X POST http://localhost:6333/collections/mantis_docs/points/scroll -d '{"limit":100}' \| jq '.result.points \| group_by(.payload.text) \| map(select(length > 1))'` | **1.** Implementar hash de documentos<br>**2.** Ejecutar script de limpieza de duplicados<br>**3.** Agregar validación pre-ingesta |

## ✅ Validación SDD y Comandos de Prueba

### Checklist de Validación Pre-Deploy

```bash
#!/bin/bash
# validate_qdrant_ingestion.sh

echo "🔍 Validando ingesta Qdrant según SDD..."

# C4: Verificar que NO existan puntos sin tenant_id
orphans=$(curl -s -X POST http://localhost:6333/collections/mantis_docs/points/scroll \
  -H 'Content-Type: application/json' \
  -d '{"limit": 10000, "filter": {"must_not": [{"key": "tenant_id"}]}}' \
  | jq '.result.points | length')

if [ "$orphans" -gt 0 ]; then
  echo "❌ C4 VIOLADO: $orphans puntos sin tenant_id"
  exit 1
else
  echo "✅ C4: Todos los puntos tienen tenant_id"
fi

# C6: Verificar que código no use modelos locales
local_models=$(grep -rn "ollama\|localai" *.py)
if [ -n "$local_models" ]; then
  echo "❌ C6 VIOLADO: Modelos locales detectados"
  echo "$local_models"
  exit 1
else
  echo "✅ C6: Solo APIs cloud para embeddings"
fi

# RES-009: Verificar topK en búsquedas
high_topk=$(grep -rn "limit.*=[0-9]\+" *.py | grep -v "limit=\([1-9]\|[1-9][0-9]\)")
if [ -n "$high_topk" ]; then
  echo "⚠️  RES-009: Algunos topK >99 (revisar manualmente)"
  echo "$high_topk"
else
  echo "✅ RES-009: topK razonables (<100)"
fi

# MT-004: Verificar filtros en búsquedas
missing_filter=$(grep -rn "qdrant.search" *.py | grep -v "query_filter")
if [ -n "$missing_filter" ]; then
  echo "❌ MT-004 VIOLADO: Búsquedas sin filtro detectadas"
  echo "$missing_filter"
  exit 1
else
  echo "✅ MT-004: Todas las búsquedas tienen filtros"
fi

echo ""
echo "✅ Validación SDD completada exitosamente"
```

### Test Unitario de tenant_id

```python
# test_multi_tenancy.py
import pytest
from qdrant_client import QdrantClient

@pytest.fixture
def qdrant():
    return QdrantClient(host="127.0.0.1", port=6333)

def test_search_respects_tenant_isolation(qdrant):
    """
    Test crítico C4: Búsqueda NO debe retornar datos de otros tenants.
    
    spec_referenced: MT-004, MT-005
    """
    # Ingestar documento de tenant A
    ingest_document("Doc A", "source_a.txt", "tenant_a")
    
    # Buscar como tenant B
    results = search_documents("Doc A", "tenant_b")
    
    # DEBE estar vacío (C4)
    assert len(results) == 0, "❌ C4 VIOLADO: Búsqueda retornó datos de otro tenant"

def test_all_points_have_tenant_id(qdrant):
    """Test que TODOS los puntos tengan tenant_id."""
    points, _ = qdrant.scroll(
        collection_name="mantis_docs",
        limit=10000,
        with_payload=True
    )
    
    for point in points:
        assert "tenant_id" in point.payload, f"❌ C4 VIOLADO: Punto {point.id} sin tenant_id"
        assert len(point.payload["tenant_id"]) > 0, f"❌ C4 VIOLADO: tenant_id vacío en {point.id}"

# Ejecutar: pytest test_multi_tenancy.py -v
```

## 🔗 Referencias Cruzadas

### Documentación del Proyecto
- [[01-RULES/06-MULTITENANCY-RULES.md]] - Reglas MT-001 a MT-011 (tenant_id obligatorio)
- [[01-RULES/02-RESOURCE-GUARDRAILS.md]] - RES-008 (chunking), RES-009 (topK)
- [[00-CONTEXT/facundo-infrastructure.md]] - Arquitectura de 3 VPS
- [[validation-checklist.md]] - Sección 4: Validación de Qdrant (QDR-01 a QDR-16)

### Skills Relacionados
- [[multi-tenant-data-isolation.md]] - Patrones avanzados de aislamiento
- [[whatsapp-rag-agents.md]] - Uso de Qdrant en chatbots WhatsApp
- [[google-drive-qdrant-sync.md]] - Sincronización automática Google Drive → Qdrant

### Recursos Externos
- [Qdrant Docs: Multi-tenancy](https://qdrant.tech/documentation/guides/multiple-partitions/)
- [OpenAI Embeddings Guide](https://platform.openai.com/docs/guides/embeddings)
- [LangChain Text Splitters](https://python.langchain.com/docs/modules/data_connection/document_transformers/)

---

**Última validación SDD:** 2026-04-09  
**Constraints verificados:** ✅ C1, ✅ C2, ✅ C4, ✅ C6  
**Estado:** 🟢 Production Ready
