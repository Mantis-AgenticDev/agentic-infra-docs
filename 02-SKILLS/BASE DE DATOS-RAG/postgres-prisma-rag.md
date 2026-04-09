---
title: "PostgreSQL + Prisma ORM para RAG Multi-Tenant"
category: "Skill"
domain: ["rag", "backend", "database"]
constraints: ["C1", "C2", "C3", "C4", "C5"]
priority: "Alta"
version: "1.0.0"
last_updated: "2026-04-09"
ai_optimized: true
tags:
  - sdd/skill/postgresql
  - sdd/skill/prisma
  - sdd/skill/rag
  - sdd/skill/multi-tenant
  - lang/es
related_files:
  - "01-RULES/06-MULTITENANCY-RULES.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
  - "00-CONTEXT/facundo-infrastructure.md"
  - "01-RULES/05-CODE-PATTERNS-RULES.md"
---

## 🎯 Propósito y Alcance

Implementar PostgreSQL + Prisma ORM para almacenar metadata de documentos RAG con aislamiento multi-tenant estricto, optimizado para VPS de 4-8GB RAM.

**Casos de uso:**
- Almacenar metadata de chunks procesados (source, tenant_id, embedding_id)
- Tracking de ingesta de documentos (estado, errores, timestamps)
- Relacionar chunks de Qdrant con documentos originales en Google Drive
- Auditoría de accesos por tenant

**No incluye:**
- Almacenamiento de vectores (usar Qdrant para eso)
- Texto completo de documentos (solo referencias y metadata)

---

## 📐 Fundamentos (Nivel Básico)

### ¿Qué es Prisma ORM?

**Prisma** es un ORM (Object-Relational Mapping) que traduce objetos JavaScript/TypeScript a queries SQL, con:
- **Type-safety**: Errores en compile-time, no en runtime
- **Migrations**: Versionado de esquema de BD
- **Auto-completion**: IDE sugiere campos y relaciones

**Flujo básico:**
```
schema.prisma → prisma migrate → PostgreSQL
     ↓
Prisma Client → Tu código Node.js
```

### PostgreSQL vs MySQL para RAG

| Característica | PostgreSQL | MySQL |
|----------------|-----------|-------|
| JSONB nativo | ✅ Sí (rápido) | ⚠️ Solo JSON (lento) |
| Arrays nativos | ✅ Sí | ❌ No |
| Full-text search | ✅ Avanzado | ⚠️ Básico |
| Extensiones | ✅ pgvector, pg_trgm | ❌ Limitado |
| RAM mínima | 512MB | 256MB |

**Para RAG:** PostgreSQL es superior por JSONB y arrays (metadata compleja).

### Modelo Mental: Prisma para RAG

```
Documento original (PDF/Drive)
    ↓
Chunks procesados (texto dividido)
    ↓
Embeddings generados (vectores en Qdrant)
    ↓
Metadata en PostgreSQL (tenant_id, source, status)
```

PostgreSQL NO almacena vectores, solo la metadata que permite:
1. Saber qué documentos ya fueron procesados
2. Relacionar chunks con documentos originales
3. Auditar accesos por tenant

---

## 🏗️ Arquitectura y Hardware Limitado (VPS 2vCPU/4-8GB)

### Configuración PostgreSQL para 4GB RAM Compartidos

**Escenario:** VPS con 4GB RAM total, PostgreSQL debe compartir con n8n, Qdrant, OS.

```ini
# postgresql.conf - Configuración conservadora
shared_buffers = 512MB          # 12.5% de RAM total (C1: No exceder)
effective_cache_size = 1536MB   # 38% de RAM (estimación de cache OS)
maintenance_work_mem = 128MB    # Para VACUUM, CREATE INDEX
work_mem = 16MB                 # Por query (max_connections * work_mem < RAM)
max_connections = 50            # Límite bajo, usar pooling en app
wal_buffers = 16MB              
checkpoint_completion_target = 0.9
random_page_cost = 1.1          # SSD en VPS moderno
effective_io_concurrency = 200  # SSD
```

**Validación de límites:**
```bash
# Verificar uso de RAM de PostgreSQL
docker stats postgres --no-stream

# Output esperado:
# MEM USAGE: 600MB / 1.5GB  ✅ Dentro de C1
# MEM USAGE: 1.8GB / 1.5GB  ❌ Excede límite (ajustar shared_buffers)
```

### Docker Compose con Límites Estrictos

```yaml
services:
  postgres:
    image: postgres:15-alpine  # Alpine = menos RAM base
    environment:
      POSTGRES_DB: mantis_rag
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./postgres.conf:/etc/postgresql/postgresql.conf:ro
    command: postgres -c config_file=/etc/postgresql/postgresql.conf
    ports:
      - "127.0.0.1:5432:5432"  # C3: Solo localhost
    deploy:
      resources:
        limits:
          memory: 1500M  # C1: 37.5% de 4GB
          cpus: "1.0"    # C2: 1 vCPU
        reservations:
          memory: 512M
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
```

### Pooling de Conexiones (Crítico para C1/C2)

**Problema:** Cada conexión PostgreSQL consume ~10MB RAM.
- 50 conexiones = 500MB RAM solo en conexiones ❌

**Solución:** Prisma con connection pooling

```prisma
// schema.prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider        = "prisma-client-js"
  previewFeatures = ["fullTextSearch", "postgresqlExtensions"]
}
```

```javascript
// prisma-client.js - Singleton con pooling
import { PrismaClient } from '@prisma/client';

const globalForPrisma = global;

export const prisma = globalForPrisma.prisma || new PrismaClient({
  log: ['error', 'warn'],
  datasources: {
    db: {
      url: process.env.DATABASE_URL + '?connection_limit=10&pool_timeout=20'
      // C1: Máximo 10 conexiones simultáneas por instancia de app
    }
  }
});

if (process.env.NODE_ENV !== 'production') {
  globalForPrisma.prisma = prisma;
}
```

**Cálculo de RAM:**
```
10 conexiones × 10MB = 100MB (dentro de límite) ✅
50 conexiones × 10MB = 500MB (excede si hay otros procesos) ❌
```

---

## 🔗 Conexión Local vs Externa (Prisma, Supabase, Qdrant, MySQL)

### Patrón de Connection String

```bash
# .env.local - PostgreSQL en mismo VPS
DATABASE_URL="postgresql://user:password@localhost:5432/mantis_rag?schema=public"

# .env.production - PostgreSQL en VPS separado
DATABASE_URL="postgresql://user:password@10.0.1.2:5432/mantis_rag?schema=public&sslmode=require"

# .env.supabase - PostgreSQL en Supabase cloud
DATABASE_URL="postgresql://postgres:[PASSWORD]@db.[PROJECT].supabase.co:5432/postgres?pgbouncer=true"
```

### Validación de tenant_id en Diferentes Escenarios

**Local (mismo VPS):**
```javascript
// Conexión directa, tenant_id validado en app layer
const chunks = await prisma.document_chunk.findMany({
  where: {
    tenant_id: req.user.tenant_id  // C4: Siempre presente
  }
});
```

**Externa (Supabase con RLS):**
```sql
-- Row Level Security automático
ALTER TABLE document_chunk ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON document_chunk
  FOR ALL
  USING (tenant_id = current_setting('app.current_tenant')::uuid);

-- Configurar tenant en cada conexión
SET app.current_tenant = 'restaurant_123';
```

**Comparación:**

| Escenario | Latencia | Complejidad | C4 Enforcement |
|-----------|----------|-------------|----------------|
| Local (127.0.0.1) | <1ms | Baja | App layer |
| Mismo datacenter | 2-5ms | Baja | App layer |
| Supabase Cloud | 50-150ms | Media | RLS + App |
| VPS diferente región | 100-300ms | Media | App layer |

---

## 📘 Guía de Estructura de Tablas (Para principiantes)

### Schema Prisma Completo para RAG

```prisma
// schema.prisma
model Tenant {
  id         String   @id @default(uuid())
  name       String
  created_at DateTime @default(now())
  
  // Relaciones
  documents  Document[]
  chunks     DocumentChunk[]
  
  @@map("tenants")
}

model Document {
  id          String   @id @default(uuid())
  tenant_id   String   // C4: OBLIGATORIO en todas las tablas
  
  // Metadata del documento original
  source_type String   // 'google_drive', 'pdf_upload', 'url'
  source_id   String   // Drive file ID, path local, URL
  filename    String
  mime_type   String?
  size_bytes  Int?
  
  // Estado de procesamiento
  status      String   // 'pending', 'processing', 'completed', 'failed'
  error_msg   String?
  
  // Metadata de ingesta
  total_chunks     Int      @default(0)
  processed_chunks Int      @default(0)
  embedding_model  String   // 'text-embedding-3-small', 'cohere-embed-v3'
  
  // Timestamps
  created_at  DateTime @default(now())
  updated_at  DateTime @updatedAt
  processed_at DateTime?
  
  // Relaciones
  tenant      Tenant   @relation(fields: [tenant_id], references: [id])
  chunks      DocumentChunk[]
  
  // Índices optimizados (C1: Queries rápidas sin exceder RAM)
  @@index([tenant_id, status])        // Query: Documentos pendientes por tenant
  @@index([tenant_id, source_type])   // Query: Todos los PDFs de un tenant
  @@index([created_at])                // Query: Documentos recientes
  @@map("documents")
}

model DocumentChunk {
  id          String   @id @default(uuid())
  tenant_id   String   // C4: OBLIGATORIO
  document_id String
  
  // Metadata del chunk
  chunk_index Int      // Posición en documento original (0, 1, 2...)
  total_chunks Int     // Total de chunks del documento
  
  // Contenido
  text        String   @db.Text  // Texto del chunk (hasta 10KB)
  token_count Int      // Tokens aprox (para limitar context window)
  
  // Vectorización
  qdrant_id   String?  // ID del punto en Qdrant (uuid)
  embedding_model String // Mismo que Document
  
  // Metadata adicional (JSON flexible)
  metadata    Json?    // { page: 12, section: "Introducción", ... }
  
  // Timestamps
  created_at  DateTime @default(now())
  
  // Relaciones
  tenant      Tenant   @relation(fields: [tenant_id], references: [id])
  document    Document @relation(fields: [document_id], references: [id], onDelete: Cascade)
  
  // Índices compuestos (C4: tenant_id SIEMPRE primero)
  @@index([tenant_id, document_id])
  @@index([tenant_id, qdrant_id])
  @@unique([document_id, chunk_index])  // No duplicar chunks
  @@map("document_chunks")
}

model IngestionLog {
  id          String   @id @default(uuid())
  tenant_id   String   // C4: OBLIGATORIO
  
  // Evento
  event_type  String   // 'ingestion_started', 'chunk_created', 'error', 'completed'
  document_id String?
  
  // Detalles
  message     String?
  error_stack String?  @db.Text
  metadata    Json?
  
  // Timestamp
  created_at  DateTime @default(now())
  
  @@index([tenant_id, created_at])
  @@index([document_id])
  @@map("ingestion_logs")
}
```

### Diagrama de Relaciones

```
Tenant (1) ──────── (N) Document
   │                      │
   │                      │
   │                      ├── status: pending/processing/completed
   │                      ├── total_chunks: 45
   │                      └── embedding_model: text-embedding-3-small
   │
   └────────── (N) DocumentChunk
                      │
                      ├── chunk_index: 0, 1, 2...
                      ├── text: "Contenido del chunk..."
                      ├── qdrant_id: "abc-123-uuid"
                      └── metadata: { page: 12, ... }
```

### Columnas Críticas Explicadas

| Columna | Propósito | Validación C4 |
|---------|-----------|---------------|
| `tenant_id` | Aislamiento multi-tenant | WHERE tenant_id = ? en TODAS las queries |
| `status` | Evitar re-procesamiento | 'completed' = skip, 'failed' = retry |
| `qdrant_id` | Relacionar chunk con vector | JOIN lógico con Qdrant |
| `chunk_index` | Reconstruir documento original | ORDER BY chunk_index |
| `metadata` | Flexibilidad sin alterar schema | JSONB permite evolución |

---

## 🛠️ 4 Ejemplos Centrales (Copy-Paste, validables)

### Ejemplo 1: Crear Documento y Chunks (Ingesta Completa)

```javascript
// ingest-document.js
import { prisma } from './prisma-client.js';

async function ingestDocument({
  tenantId,       // C4: Requerido
  sourceType,     // 'google_drive', 'pdf_upload'
  sourceId,       // Drive file ID o path
  filename,
  chunks          // Array de { text, tokenCount, metadata }
}) {
  // Validación C4
  if (!tenantId) {
    throw new Error('tenant_id is required (C4 violation)');
  }
  
  // Transacción atómica (todo o nada)
  const result = await prisma.$transaction(async (tx) => {
    // 1. Crear documento
    const document = await tx.document.create({
      data: {
        tenant_id: tenantId,
        source_type: sourceType,
        source_id: sourceId,
        filename: filename,
        status: 'processing',
        total_chunks: chunks.length,
        processed_chunks: 0,
        embedding_model: 'text-embedding-3-small'
      }
    });
    
    // 2. Crear chunks en batch (C1: Eficiencia de RAM)
    const chunkRecords = chunks.map((chunk, index) => ({
      tenant_id: tenantId,  // C4: Repetir en cada chunk
      document_id: document.id,
      chunk_index: index,
      total_chunks: chunks.length,
      text: chunk.text,
      token_count: chunk.tokenCount,
      metadata: chunk.metadata || {},
      embedding_model: 'text-embedding-3-small'
    }));
    
    // createMany es más eficiente que múltiples create()
    await tx.documentChunk.createMany({
      data: chunkRecords,
      skipDuplicates: true  // Idempotencia
    });
    
    // 3. Actualizar estado del documento
    await tx.document.update({
      where: { id: document.id },
      data: {
        status: 'completed',
        processed_chunks: chunks.length,
        processed_at: new Date()
      }
    });
    
    // 4. Log de auditoría
    await tx.ingestionLog.create({
      data: {
        tenant_id: tenantId,
        event_type: 'ingestion_completed',
        document_id: document.id,
        message: `Ingested ${chunks.length} chunks from ${filename}`,
        metadata: { source_type: sourceType }
      }
    });
    
    return document;
  });
  
  console.log(`✅ Document ${result.id} ingested with ${chunks.length} chunks`);
  return result;
}

// Uso
const doc = await ingestDocument({
  tenantId: 'restaurant_456',
  sourceType: 'pdf_upload',
  sourceId: '/uploads/manual.pdf',
  filename: 'manual.pdf',
  chunks: [
    { text: 'Capítulo 1...', tokenCount: 250, metadata: { page: 1 } },
    { text: 'Sección 1.1...', tokenCount: 300, metadata: { page: 2 } }
  ]
});
```

**Validación:**
```bash
# Query para verificar
psql -U user -d mantis_rag -c "
  SELECT d.id, d.filename, d.status, COUNT(c.id) as chunk_count
  FROM documents d
  LEFT JOIN document_chunks c ON d.id = c.document_id
  WHERE d.tenant_id = 'restaurant_456'
  GROUP BY d.id;
"

# Output esperado:
#  id   | filename    | status    | chunk_count
# ------|-------------|-----------|-------------
#  uuid | manual.pdf  | completed | 2
```

---

### Ejemplo 2: Buscar Chunks con Filtros Multi-Tenant

```javascript
// search-chunks.js
import { prisma } from './prisma-client.js';

async function searchChunks({
  tenantId,          // C4: OBLIGATORIO
  documentId = null, // Opcional: Filtrar por documento
  searchText = null, // Opcional: Full-text search
  limit = 10
}) {
  // C4: Validación estricta
  if (!tenantId) {
    throw new Error('tenant_id required for all queries (C4)');
  }
  
  // Construcción dinámica de filtros
  const where = {
    tenant_id: tenantId  // C4: Siempre presente
  };
  
  if (documentId) {
    where.document_id = documentId;
  }
  
  if (searchText) {
    // Full-text search en PostgreSQL
    where.text = {
      contains: searchText,
      mode: 'insensitive'  // Case-insensitive
    };
  }
  
  const chunks = await prisma.documentChunk.findMany({
    where,
    include: {
      document: {
        select: {
          filename: true,
          source_type: true
        }
      }
    },
    orderBy: [
      { document_id: 'asc' },
      { chunk_index: 'asc' }
    ],
    take: limit
  });
  
  return chunks.map(chunk => ({
    id: chunk.id,
    text: chunk.text,
    source: chunk.document.filename,
    page: chunk.metadata?.page || null,
    qdrant_id: chunk.qdrant_id
  }));
}

// Uso
const results = await searchChunks({
  tenantId: 'restaurant_456',
  searchText: 'política de devoluciones',
  limit: 5
});

console.log(`Found ${results.length} chunks`);
// Output:
// [
//   {
//     id: 'uuid-1',
//     text: 'Nuestra política de devoluciones...',
//     source: 'manual.pdf',
//     page: 12,
//     qdrant_id: 'qdrant-uuid-1'
//   }
// ]
```

---

### Ejemplo 3: Actualizar Estado y Asociar Qdrant IDs

```javascript
// update-qdrant-ids.js
import { prisma } from './prisma-client.js';

async function linkChunksToQdrant({
  tenantId,      // C4: OBLIGATORIO
  documentId,
  qdrantMappings // [{ chunkId, qdrantId }]
}) {
  // C4: Validar tenant
  const document = await prisma.document.findFirst({
    where: {
      id: documentId,
      tenant_id: tenantId  // C4: Doble verificación
    }
  });
  
  if (!document) {
    throw new Error('Document not found or tenant mismatch (C4 violation)');
  }
  
  // Actualizar chunks en batch
  const updates = qdrantMappings.map(({ chunkId, qdrantId }) =>
    prisma.documentChunk.updateMany({
      where: {
        id: chunkId,
        tenant_id: tenantId,  // C4: Garantizar no cruzar tenants
        document_id: documentId
      },
      data: {
        qdrant_id: qdrantId
      }
    })
  );
  
  await prisma.$transaction(updates);
  
  console.log(`✅ Linked ${qdrantMappings.length} chunks to Qdrant`);
}

// Uso
await linkChunksToQdrant({
  tenantId: 'restaurant_456',
  documentId: 'doc-uuid-123',
  qdrantMappings: [
    { chunkId: 'chunk-1', qdrantId: 'qdrant-abc' },
    { chunkId: 'chunk-2', qdrantId: 'qdrant-def' }
  ]
});
```

---

### Ejemplo 4: Eliminar Documento y Cascada de Chunks

```javascript
// delete-document.js
import { prisma } from './prisma-client.js';

async function deleteDocument({
  tenantId,   // C4: OBLIGATORIO
  documentId
}) {
  // C4: Verificar ownership antes de eliminar
  const document = await prisma.document.findFirst({
    where: {
      id: documentId,
      tenant_id: tenantId
    },
    include: {
      _count: {
        select: { chunks: true }
      }
    }
  });
  
  if (!document) {
    throw new Error('Document not found or unauthorized (C4)');
  }
  
  // Cascade delete automático (ver schema: onDelete: Cascade)
  await prisma.document.delete({
    where: { id: documentId }
  });
  
  console.log(`✅ Deleted document ${documentId} and ${document._count.chunks} chunks`);
  
  // IMPORTANTE: También eliminar de Qdrant
  return {
    deletedChunks: document._count.chunks,
    qdrantIdsToDelete: await prisma.documentChunk.findMany({
      where: { document_id: documentId },
      select: { qdrant_id: true }
    }).then(chunks => chunks.map(c => c.qdrant_id).filter(Boolean))
  };
}

// Uso
const result = await deleteDocument({
  tenantId: 'restaurant_456',
  documentId: 'doc-uuid-123'
});

console.log(`Need to delete from Qdrant: ${result.qdrantIdsToDelete}`);
// Llamar a Qdrant API para eliminar esos IDs
```

---

## 🔍 >5 Ejemplos Independientes por Caso de Uso

### Caso 1: Listar Documentos Pendientes de Procesamiento

```javascript
async function getPendingDocuments(tenantId) {
  return await prisma.document.findMany({
    where: {
      tenant_id: tenantId,  // C4
      status: 'pending'
    },
    orderBy: {
      created_at: 'asc'  // FIFO
    },
    take: 10  // C1: Procesar en lotes pequeños
  });
}
```

---

### Caso 2: Contar Chunks por Tenant (Métricas)

```javascript
async function getChunkStats(tenantId) {
  const stats = await prisma.documentChunk.groupBy({
    by: ['embedding_model'],
    where: {
      tenant_id: tenantId  // C4
    },
    _count: {
      id: true
    },
    _sum: {
      token_count: true
    }
  });
  
  return stats.map(s => ({
    model: s.embedding_model,
    total_chunks: s._count.id,
    total_tokens: s._sum.token_count
  }));
}

// Output:
// [
//   { model: 'text-embedding-3-small', total_chunks: 450, total_tokens: 112500 }
// ]
```

---

### Caso 3: Reconstruir Documento Original desde Chunks

```javascript
async function reconstructDocument(tenantId, documentId) {
  const chunks = await prisma.documentChunk.findMany({
    where: {
      tenant_id: tenantId,  // C4
      document_id: documentId
    },
    orderBy: {
      chunk_index: 'asc'
    },
    select: {
      text: true,
      metadata: true
    }
  });
  
  return {
    full_text: chunks.map(c => c.text).join('\n\n'),
    page_map: chunks.reduce((acc, c) => {
      const page = c.metadata?.page;
      if (page) {
        acc[page] = (acc[page] || []).concat(c.text);
      }
      return acc;
    }, {})
  };
}
```

---

### Caso 4: Buscar Documentos por Rango de Fechas

```javascript
async function getDocumentsByDateRange(tenantId, startDate, endDate) {
  return await prisma.document.findMany({
    where: {
      tenant_id: tenantId,  // C4
      created_at: {
        gte: new Date(startDate),
        lte: new Date(endDate)
      }
    },
    select: {
      id: true,
      filename: true,
      created_at: true,
      status: true,
      _count: {
        select: { chunks: true }
      }
    }
  });
}

// Uso
const docs = await getDocumentsByDateRange(
  'restaurant_456',
  '2026-01-01',
  '2026-01-31'
);
```

---

### Caso 5: Obtener Logs de Errores de Ingesta

```javascript
async function getIngestionErrors(tenantId, limit = 20) {
  return await prisma.ingestionLog.findMany({
    where: {
      tenant_id: tenantId,  // C4
      event_type: 'error'
    },
    orderBy: {
      created_at: 'desc'
    },
    take: limit,
    include: {
      document: {
        select: {
          filename: true
        }
      }
    }
  });
}
```

---

### Caso 6: Actualizar Metadata de Chunk (JSONB)

```javascript
async function updateChunkMetadata(tenantId, chunkId, newMetadata) {
  // C4: Verificar ownership
  const chunk = await prisma.documentChunk.findFirst({
    where: {
      id: chunkId,
      tenant_id: tenantId
    }
  });
  
  if (!chunk) {
    throw new Error('Chunk not found or unauthorized (C4)');
  }
  
  // Merge metadata (no sobrescribir todo)
  return await prisma.documentChunk.update({
    where: { id: chunkId },
    data: {
      metadata: {
        ...chunk.metadata,
        ...newMetadata
      }
    }
  });
}

// Uso
await updateChunkMetadata('restaurant_456', 'chunk-1', {
  reviewed: true,
  quality_score: 0.95
});
```

---

## 🐞 Troubleshooting: 5+ Problemas Comunes y Soluciones Exactas

| Error Exacto | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso |
|--------------|-----------|------------------------|----------------------|
| `P2002: Unique constraint failed on the fields: (document_id, chunk_index)` | Intentar crear chunk duplicado | `SELECT * FROM document_chunks WHERE document_id = 'X' AND chunk_index = Y;` | 1. Verificar si chunk ya existe<br>2. Usar `createMany` con `skipDuplicates: true`<br>3. O hacer `upsert` en vez de `create` |
| `P2025: Record to update not found` | Query con `tenant_id` incorrecto (C4 violation) | `SELECT * FROM documents WHERE id = 'X';` (sin filtro tenant) | 1. Verificar `tenant_id` en request<br>2. Agregar validación: `if (!tenantId) throw Error`<br>3. Siempre usar `findFirst` con `where: { id, tenant_id }` |
| `Container OOM (Out of Memory)` durante `createMany` de 10,000 chunks | Batch muy grande excede C1 | `docker stats postgres` (ver MEM USAGE) | 1. Dividir en batches de 500 chunks<br>2. Usar loop: `for (let i=0; i<chunks.length; i+=500) { ... }`<br>3. Pausar 100ms entre batches: `await sleep(100)` |
| `Error: P1001: Can't reach database server at localhost:5432` | PostgreSQL no corriendo o puerto incorrecto | `docker ps | grep postgres` | 1. Iniciar contenedor: `docker-compose up -d postgres`<br>2. Verificar logs: `docker logs postgres`<br>3. Verificar puerto en `.env`: `DATABASE_URL` |
| `Query slow: 5+ segundos` para `findMany` con 100K+ chunks | Falta índice en columna filtrada | `EXPLAIN ANALYZE SELECT * FROM document_chunks WHERE tenant_id = 'X';` | 1. Verificar índices: `\di` en psql<br>2. Crear índice faltante: `@@index([tenant_id, created_at])`<br>3. Ejecutar migración: `prisma migrate dev` |
| `P2034: Transaction failed due to a write conflict` | Dos procesos modificando mismo documento simultáneamente | Ver logs de app para requests concurrentes | 1. Implementar retry con backoff exponencial<br>2. Usar queue (Bull) para serializar ingesta por documento<br>3. O usar `SELECT ... FOR UPDATE` en raw query |

---

## ✅ Validación SDD y Comandos de Prueba

### Checklist de Validación C4 (tenant_id)

```bash
# 1. Verificar que TODAS las tablas tengan tenant_id
psql -U user -d mantis_rag -c "
  SELECT table_name, column_name
  FROM information_schema.columns
  WHERE table_schema = 'public'
  AND column_name = 'tenant_id';
"

# Output esperado:
#  table_name      | column_name
# -----------------|-------------
#  documents        | tenant_id
#  document_chunks  | tenant_id
#  ingestion_logs   | tenant_id

# 2. Verificar índices con tenant_id primero
psql -U user -d mantis_rag -c "
  SELECT indexname, indexdef
  FROM pg_indexes
  WHERE tablename IN ('documents', 'document_chunks')
  AND indexdef LIKE '%tenant_id%';
"

# 3. Auditar queries sin tenant_id (NO debe haber)
grep -r "prisma.document.findMany" . | grep -v "tenant_id"
# Resultado esperado: VACÍO

# 4. Test de aislamiento multi-tenant
# Crear 2 documentos de diferentes tenants
# Verificar que tenant A NO vea documentos de tenant B
```

### Pruebas de Límites (C1/C2)

```javascript
// test-limits.js
import { prisma } from './prisma-client.js';

async function testRAMLimits() {
  const tenantId = 'test_tenant';
  
  // Crear 10,000 chunks simulados
  console.time('createMany 10k chunks');
  
  const chunks = Array.from({ length: 10000 }, (_, i) => ({
    tenant_id: tenantId,
    document_id: 'test-doc',
    chunk_index: i,
    total_chunks: 10000,
    text: 'Test chunk '.repeat(100),  // ~1KB por chunk
    token_count: 200,
    embedding_model: 'test'
  }));
  
  // Dividir en batches de 500 (C1: No sobrecargar RAM)
  for (let i = 0; i < chunks.length; i += 500) {
    const batch = chunks.slice(i, i + 500);
    await prisma.documentChunk.createMany({
      data: batch,
      skipDuplicates: true
    });
    console.log(`Inserted batch ${i / 500 + 1}`);
    await new Promise(r => setTimeout(r, 100));  // Pausa 100ms
  }
  
  console.timeEnd('createMany 10k chunks');
  
  // Verificar uso de RAM
  console.log('\n📊 Check Docker stats:');
  console.log('Run: docker stats postgres --no-stream');
}

testRAMLimits();
```

### Validación de Integridad

```sql
-- Verificar que todos los chunks tengan documento padre
SELECT c.id, c.document_id
FROM document_chunks c
LEFT JOIN documents d ON c.document_id = d.id
WHERE d.id IS NULL;

-- Resultado esperado: 0 rows (ningún chunk huérfano)

-- Verificar que chunk_index sea secuencial
SELECT document_id, array_agg(chunk_index ORDER BY chunk_index) as indices
FROM document_chunks
GROUP BY document_id
HAVING array_agg(chunk_index ORDER BY chunk_index) != 
       (SELECT array_agg(i) FROM generate_series(0, COUNT(*)-1) i);

-- Resultado esperado: 0 rows (todos secuenciales)
```

---

## 🔗 Referencias Cruzadas

- [[01-RULES/06-MULTITENANCY-RULES.md]] - MT-001 a MT-011 (tenant_id enforcement)
- [[01-RULES/02-RESOURCE-GUARDRAILS.md]] - RES-001, RES-005 (límites RAM/CPU)
- [[01-RULES/05-CODE-PATTERNS-RULES.md]] - PAT-002 (prepared statements con Prisma)
- [[00-CONTEXT/facundo-infrastructure.md]] - Arquitectura 3-VPS y límites hardware

**Skills relacionados:**
- `qdrant-rag-ingestion.md` - Almacenar vectores en Qdrant
- `supabase-rag-integration.md` - Alternativa cloud a PostgreSQL local
- `multi-tenant-data-isolation.md` - Patrones de aislamiento avanzados
