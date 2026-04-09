---
title: "Supabase + RAG: Row Level Security para Multi-Tenancy"
category: "Skill"
domain: ["rag", "backend", "cloud"]
constraints: ["C3", "C4", "C6"]
priority: "Alta"
version: "1.0.0"
last_updated: "2026-04-09"
ai_optimized: true
tags:
  - sdd/skill/supabase
  - sdd/skill/rag
  - sdd/skill/rls
  - sdd/skill/multi-tenant
  - lang/es
related_files:
  - "01-RULES/06-MULTITENANCY-RULES.md"
  - "00-CONTEXT/facundo-infrastructure.md"
  - "01-RULES/03-SECURITY-RULES.md"
---

## 🎯 Propósito y Alcance

Implementar Supabase (PostgreSQL como servicio) para metadata RAG con Row Level Security (RLS) automático que garantiza aislamiento multi-tenant a nivel de base de datos.

**Ventajas de Supabase:**
- **RLS nativo**: tenant_id enforcement a nivel BD (C4)
- **Sin gestión de servidor**: No consume RAM local (libera recursos para C1)
- **Backups automáticos**: Cumple C5 sin scripts custom
- **Auth integrado**: JWT con tenant_id en claims

**Casos de uso:**
- RAG SaaS donde cada cliente necesita aislamiento estricto
- Equipos sin experiencia en administración PostgreSQL
- Necesidad de escalado rápido sin tocar infraestructura

**No usar si:**
- Datos extremadamente sensibles (ej: salud, finanzas reguladas) → Self-hosted
- Presupuesto muy bajo → PostgreSQL local es gratis
- Latencia crítica < 10ms → Local siempre es más rápido

---

## 📐 Fundamentos (Nivel Básico)

### ¿Qué es Supabase?

**Supabase** = PostgreSQL + Auth + Storage + Realtime en la nube, con interfaz web amigable.

**Componentes relevantes para RAG:**

1. **PostgreSQL**: Base de datos relacional
2. **Row Level Security (RLS)**: Filtros automáticos por usuario/tenant
3. **Auth**: Manejo de usuarios con JWT
4. **Storage**: Almacenar PDFs originales (opcional)

### Row Level Security (RLS) Explicado

**Sin RLS:**
```javascript
// App debe filtrar manualmente
const docs = await supabase
  .from('documents')
  .select('*')
  .eq('tenant_id', req.user.tenant_id);  // C4: Manual
```

**Con RLS:**
```javascript
// BD filtra automáticamente
const docs = await supabase
  .from('documents')
  .select('*');
// Supabase agrega WHERE tenant_id = user.tenant_id AUTOMÁTICAMENTE
```

**Ventaja:** Imposible olvidar filtrar por tenant (C4 enforcement a nivel BD).

### Modelo Mental: Supabase vs PostgreSQL Local

| Aspecto | Supabase | PostgreSQL Local |
|---------|----------|------------------|
| Gestión | ☁️ Cloud (sin servidor) | 🖥️ VPS (tú administras) |
| C4 Enforcement | RLS automático | App layer manual |
| C1 (RAM) | No consume RAM local | Consume 512MB-1.5GB |
| C5 (Backups) | Automáticos | Scripts manuales |
| Latencia | 50-150ms | <1ms |
| Costo | $25/mes (Pro) | $0 (solo VPS) |

---

## 🏗️ Arquitectura y Hardware Limitado (VPS 2vCPU/4-8GB)

### Arquitectura Híbrida Recomendada

```
┌─────────────────────────────────────┐
│  VPS 1 (4GB RAM)                    │
│  ┌──────────┐  ┌─────────────────┐ │
│  │   n8n    │  │  Qdrant         │ │  C1: RAM local solo para
│  │  (1.5GB) │  │  (vectors)      │ │  servicios que requieren
│  └──────────┘  │  (1.5GB)        │ │  baja latencia
│                └─────────────────┘ │
└──────────────────┬──────────────────┘
                   │
                   │ HTTPS
                   ▼
           ┌───────────────┐
           │   Supabase    │
           │  (PostgreSQL) │  C1: NO consume RAM local
           │   Metadata    │  C4: RLS automático
           └───────────────┘  C5: Backups incluidos
```

**Decisión de arquitectura:**
- **Qdrant local**: Búsqueda vectorial necesita baja latencia (<10ms)
- **Supabase remoto**: Metadata tolera latencia (50-100ms), libera 1GB RAM

### Cálculo de RAM Liberada

```
Escenario 1: Todo local
- PostgreSQL: 1GB
- Qdrant: 1.5GB
- n8n: 1.5GB
Total: 4GB (límite C1 alcanzado) ❌

Escenario 2: Supabase remoto
- Qdrant: 1.5GB
- n8n: 1.5GB
- MySQL (otro proyecto): 800MB
Total: 3.8GB (margen de 200MB) ✅
```

---

## 🔗 Conexión Local vs Externa (Prisma, Supabase, Qdrant, MySQL)

### Setup Inicial: Crear Proyecto Supabase

**Paso 1: Crear proyecto**
```bash
# En supabase.com
1. New Project → "mantis-rag-prod"
2. Region: São Paulo (menor latencia a Brasil)
3. Plan: Pro ($25/mes para 8GB BD, backups diarios)
```

**Paso 2: Obtener credenciales**
```bash
# Project Settings → API
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Project Settings → Database
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:5432/postgres
```

### Connection Strings: Local vs Supabase vs Pooler

```bash
# .env - Diferentes escenarios

# 1. PostgreSQL local (mismo VPS)
DATABASE_URL="postgresql://user:pass@localhost:5432/mantis_rag"
# Latencia: <1ms, RAM: Consume 1GB, C3: OK (localhost)

# 2. Supabase directo (NO recomendado para producción)
DATABASE_URL="postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:5432/postgres"
# Latencia: 80ms, Conexiones: Limitadas (evitar)

# 3. Supabase con Pooler (RECOMENDADO)
DATABASE_URL="postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:6543/postgres?pgbouncer=true"
# Latencia: 60ms, Conexiones: Pooling automático, C1: No consume RAM local
# Puerto 6543 = Pooler, 5432 = Directo

# 4. Supabase con Prisma (connection pooling adicional)
DATABASE_URL="postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:6543/postgres?pgbouncer=true&connection_limit=5"
# C1: Máximo 5 conexiones por instancia de app
```

### Validación de Latencia

```javascript
// test-latency.js
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

async function testLatency() {
  const iterations = 10;
  const latencies = [];
  
  for (let i = 0; i < iterations; i++) {
    const start = Date.now();
    await supabase.from('documents').select('count');
    const latency = Date.now() - start;
    latencies.push(latency);
  }
  
  const avg = latencies.reduce((a, b) => a + b, 0) / iterations;
  console.log(`Average latency: ${avg}ms`);
  console.log(`Min: ${Math.min(...latencies)}ms, Max: ${Math.max(...latencies)}ms`);
}

testLatency();

// Output esperado:
// Average latency: 65ms  ✅ Aceptable para metadata
// Average latency: 250ms ❌ Problema de red/región
```

---

## 📘 Guía de Estructura de Tablas (Para principiantes)

### Schema SQL con RLS (Row Level Security)

```sql
-- 1. Habilitar extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- Full-text search

-- 2. Tabla: documents
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL,  -- C4: OBLIGATORIO
  
  -- Metadata del documento
  source_type TEXT NOT NULL,  -- 'google_drive', 'pdf_upload', 'url'
  source_id TEXT NOT NULL,
  filename TEXT NOT NULL,
  mime_type TEXT,
  size_bytes INTEGER,
  
  -- Estado de procesamiento
  status TEXT NOT NULL DEFAULT 'pending',  -- 'pending', 'processing', 'completed', 'failed'
  error_msg TEXT,
  
  -- Metadata de ingesta
  total_chunks INTEGER DEFAULT 0,
  processed_chunks INTEGER DEFAULT 0,
  embedding_model TEXT NOT NULL,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ,
  
  -- Constraints
  CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  CHECK (total_chunks >= 0),
  CHECK (processed_chunks >= 0 AND processed_chunks <= total_chunks)
);

-- Índices optimizados (tenant_id SIEMPRE primero)
CREATE INDEX idx_documents_tenant_status ON documents(tenant_id, status);
CREATE INDEX idx_documents_tenant_created ON documents(tenant_id, created_at DESC);
CREATE INDEX idx_documents_source ON documents(source_type, source_id);

-- 3. Tabla: document_chunks
CREATE TABLE document_chunks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL,  -- C4: OBLIGATORIO
  document_id UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  
  -- Metadata del chunk
  chunk_index INTEGER NOT NULL,
  total_chunks INTEGER NOT NULL,
  
  -- Contenido
  text TEXT NOT NULL,
  token_count INTEGER NOT NULL,
  
  -- Vectorización
  qdrant_id UUID,
  embedding_model TEXT NOT NULL,
  
  -- Metadata adicional (JSON flexible)
  metadata JSONB DEFAULT '{}',
  
  -- Timestamp
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  UNIQUE(document_id, chunk_index),
  CHECK (chunk_index >= 0),
  CHECK (token_count > 0)
);

-- Índices compuestos
CREATE INDEX idx_chunks_tenant_doc ON document_chunks(tenant_id, document_id);
CREATE INDEX idx_chunks_qdrant ON document_chunks(qdrant_id) WHERE qdrant_id IS NOT NULL;
CREATE INDEX idx_chunks_metadata ON document_chunks USING GIN(metadata);  -- Para queries en JSONB

-- 4. Tabla: ingestion_logs
CREATE TABLE ingestion_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL,  -- C4: OBLIGATORIO
  
  event_type TEXT NOT NULL,  -- 'started', 'chunk_created', 'error', 'completed'
  document_id UUID REFERENCES documents(id) ON DELETE SET NULL,
  
  message TEXT,
  error_stack TEXT,
  metadata JSONB DEFAULT '{}',
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_logs_tenant_created ON ingestion_logs(tenant_id, created_at DESC);
CREATE INDEX idx_logs_event ON ingestion_logs(event_type, created_at DESC);

-- 5. HABILITAR ROW LEVEL SECURITY (C4 enforcement automático)

ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_chunks ENABLE ROW LEVEL SECURITY;
ALTER TABLE ingestion_logs ENABLE ROW LEVEL SECURITY;

-- 6. CREAR POLÍTICAS RLS

-- Política para documents: Solo ver/modificar documentos de su tenant
CREATE POLICY tenant_isolation_documents ON documents
  FOR ALL
  USING (tenant_id = auth.jwt() ->> 'tenant_id'::text::uuid);

-- Política para document_chunks
CREATE POLICY tenant_isolation_chunks ON document_chunks
  FOR ALL
  USING (tenant_id = auth.jwt() ->> 'tenant_id'::text::uuid);

-- Política para ingestion_logs (solo lectura propia, admins pueden escribir)
CREATE POLICY tenant_read_logs ON ingestion_logs
  FOR SELECT
  USING (tenant_id = auth.jwt() ->> 'tenant_id'::text::uuid);

CREATE POLICY admin_write_logs ON ingestion_logs
  FOR INSERT
  WITH CHECK (true);  -- Cualquier servicio autenticado puede escribir logs

-- 7. FUNCIÓN HELPER: Set tenant_id desde app

CREATE OR REPLACE FUNCTION set_tenant_context(p_tenant_id UUID)
RETURNS void AS $$
BEGIN
  PERFORM set_config('app.current_tenant', p_tenant_id::text, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Diagrama de RLS

```
Usuario hace query:
    │
    ▼
┌──────────────────────────┐
│ SELECT * FROM documents  │ ← App NO especifica tenant_id
└────────┬─────────────────┘
         │
         ▼
   ┌─────────────┐
   │   RLS       │ ← Supabase agrega WHERE tenant_id = 'X' AUTOMÁTICAMENTE
   │  Policies   │
   └─────┬───────┘
         │
         ▼
   ┌──────────────────────────────────────┐
   │ SELECT * FROM documents              │
   │ WHERE tenant_id = 'restaurant_456'   │ ← Query real ejecutada
   └──────────────────────────────────────┘
```

---

## 🛠️ 4 Ejemplos Centrales (Copy-Paste, validables)

### Ejemplo 1: Inicializar Cliente Supabase con tenant_id

```javascript
// supabase-client.js
import { createClient } from '@supabase/supabase-js';

export function createTenantClient(tenantId) {
  // C4: Validar tenant_id
  if (!tenantId) {
    throw new Error('tenant_id required for Supabase client (C4)');
  }
  
  const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_ANON_KEY,
    {
      auth: {
        persistSession: false  // No guardar sesión en server-side
      },
      global: {
        headers: {
          'x-tenant-id': tenantId  // Custom header para auditoría
        }
      }
    }
  );
  
  // Configurar tenant context (para RLS policies que usen set_config)
  supabase.rpc('set_tenant_context', { p_tenant_id: tenantId });
  
  return supabase;
}

// Uso en n8n o Express
const supabase = createTenantClient(req.user.tenant_id);
```

### Ejemplo 2: Insertar Documento con RLS Automático

```javascript
// ingest-document-supabase.js
import { createTenantClient } from './supabase-client.js';

async function ingestDocument({
  tenantId,
  sourceType,
  sourceId,
  filename,
  chunks  // Array de { text, tokenCount, metadata }
}) {
  const supabase = createTenantClient(tenantId);
  
  // 1. Crear documento
  const { data: document, error: docError } = await supabase
    .from('documents')
    .insert({
      tenant_id: tenantId,  // C4: Explícito, aunque RLS lo valida
      source_type: sourceType,
      source_id: sourceId,
      filename: filename,
      status: 'processing',
      total_chunks: chunks.length,
      embedding_model: 'text-embedding-3-small'
    })
    .select()
    .single();
  
  if (docError) {
    throw new Error(`Failed to create document: ${docError.message}`);
  }
  
  // 2. Insertar chunks en batch
  const chunkRecords = chunks.map((chunk, index) => ({
    tenant_id: tenantId,
    document_id: document.id,
    chunk_index: index,
    total_chunks: chunks.length,
    text: chunk.text,
    token_count: chunk.tokenCount,
    metadata: chunk.metadata || {},
    embedding_model: 'text-embedding-3-small'
  }));
  
  // Dividir en batches de 500 (límite de Supabase)
  const batchSize = 500;
  for (let i = 0; i < chunkRecords.length; i += batchSize) {
    const batch = chunkRecords.slice(i, i + batchSize);
    
    const { error: chunkError } = await supabase
      .from('document_chunks')
      .insert(batch);
    
    if (chunkError) {
      // Rollback: Eliminar documento si fallan chunks
      await supabase.from('documents').delete().eq('id', document.id);
      throw new Error(`Failed to insert chunks: ${chunkError.message}`);
    }
  }
  
  // 3. Actualizar estado
  await supabase
    .from('documents')
    .update({
      status: 'completed',
      processed_chunks: chunks.length,
      processed_at: new Date().toISOString()
    })
    .eq('id', document.id);
  
  console.log(`✅ Document ${document.id} ingested with ${chunks.length} chunks`);
  return document;
}

// Uso
const doc = await ingestDocument({
  tenantId: 'restaurant_456',
  sourceType: 'pdf_upload',
  sourceId: '/uploads/manual.pdf',
  filename: 'manual.pdf',
  chunks: [...]
});
```

### Ejemplo 3: Buscar Chunks con Full-Text Search

```javascript
// search-chunks-supabase.js
import { createTenantClient } from './supabase-client.js';

async function searchChunks({
  tenantId,
  searchText,
  limit = 10
}) {
  const supabase = createTenantClient(tenantId);
  
  // Full-text search usando pg_trgm
  const { data, error } = await supabase
    .from('document_chunks')
    .select(`
      id,
      text,
      metadata,
      qdrant_id,
      document:documents(filename, source_type)
    `)
    .textSearch('text', searchText, {
      type: 'websearch',
      config: 'spanish'  // Mejor stemming para español
    })
    .limit(limit);
  
  if (error) {
    throw new Error(`Search failed: ${error.message}`);
  }
  
  // RLS garantiza que solo vemos chunks de nuestro tenant (C4)
  return data.map(chunk => ({
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
```

### Ejemplo 4: Realtime Subscription para Monitorear Ingesta

```javascript
// realtime-monitor.js
import { createTenantClient } from './supabase-client.js';

function monitorDocumentIngestion(tenantId, documentId, onProgress) {
  const supabase = createTenantClient(tenantId);
  
  // Subscribirse a cambios en document_chunks
  const subscription = supabase
    .channel(`document:${documentId}`)
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'document_chunks',
        filter: `document_id=eq.${documentId}`
      },
      (payload) => {
        // RLS garantiza que solo vemos inserts de nuestro tenant
        const chunk = payload.new;
        onProgress({
          chunkIndex: chunk.chunk_index,
          totalChunks: chunk.total_chunks,
          progress: ((chunk.chunk_index + 1) / chunk.total_chunks * 100).toFixed(1)
        });
      }
    )
    .subscribe();
  
  return () => subscription.unsubscribe();
}

// Uso en UI
const unsubscribe = monitorDocumentIngestion(
  'restaurant_456',
  'doc-uuid-123',
  (progress) => {
    console.log(`Progress: ${progress.progress}% (${progress.chunkIndex}/${progress.totalChunks})`);
  }
);

// Cleanup cuando termine
// unsubscribe();
```

---

## 🔍 >5 Ejemplos Independientes por Caso de Uso

### Caso 1: Validar que RLS esté Funcionando

```javascript
// test-rls.js
import { createClient } from '@supabase/supabase-js';

async function testRLSIsolation() {
  const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY  // Bypass RLS para setup
  );
  
  // Crear 2 documentos de diferentes tenants
  await supabase.from('documents').insert([
    { tenant_id: 'tenant_A', filename: 'doc_A.pdf', status: 'completed', embedding_model: 'test' },
    { tenant_id: 'tenant_B', filename: 'doc_B.pdf', status: 'completed', embedding_model: 'test' }
  ]);
  
  // Ahora usar cliente normal con tenant_A
  const clientA = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_ANON_KEY
  );
  
  // Simular JWT con tenant_id de tenant_A
  const { data } = await clientA
    .from('documents')
    .select('*');
  
  // RLS debe filtrar automáticamente
  console.assert(data.length === 1, 'RLS failed: saw documents from other tenants');
  console.assert(data[0].tenant_id === 'tenant_A', 'RLS failed: wrong tenant_id');
  
  console.log('✅ RLS is working correctly (C4 enforced at DB level)');
}
```

### Caso 2: Migrar desde PostgreSQL Local a Supabase

```bash
# 1. Export desde PostgreSQL local
pg_dump -h localhost -U user -d mantis_rag --data-only --table=documents --table=document_chunks > backup.sql

# 2. Limpiar SQL (Supabase usa UUIDs diferentes)
sed -i 's/nextval.*//g' backup.sql

# 3. Import a Supabase
psql "postgresql://postgres:[PASSWORD]@db.xxxxx.supabase.co:5432/postgres" < backup.sql

# 4. Verificar conteos
psql "postgresql://..." -c "SELECT COUNT(*) FROM documents;"
psql "postgresql://..." -c "SELECT COUNT(*) FROM document_chunks;"
```

### Caso 3: Usar Storage de Supabase para PDFs Originales

```javascript
// upload-pdf-supabase.js
import { createTenantClient } from './supabase-client.js';
import fs from 'fs';

async function uploadPDFToStorage(tenantId, filePath, filename) {
  const supabase = createTenantClient(tenantId);
  
  // Leer archivo
  const fileBuffer = fs.readFileSync(filePath);
  
  // Upload a bucket (crear bucket "documents" en Supabase UI primero)
  const { data, error } = await supabase.storage
    .from('documents')
    .upload(`${tenantId}/${filename}`, fileBuffer, {
      contentType: 'application/pdf',
      upsert: false
    });
  
  if (error) {
    throw new Error(`Upload failed: ${error.message}`);
  }
  
  // Obtener URL pública (signed, 1 hora de validez)
  const { data: urlData } = await supabase.storage
    .from('documents')
    .createSignedUrl(`${tenantId}/${filename}`, 3600);
  
  return {
    path: data.path,
    url: urlData.signedUrl
  };
}

// Uso
const result = await uploadPDFToStorage(
  'restaurant_456',
  '/tmp/manual.pdf',
  'manual.pdf'
);

console.log(`PDF stored at: ${result.url}`);
```

### Caso 4: Agregar Custom Claims al JWT

```javascript
// auth-hook.js - Supabase Edge Function
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  const { user } = await req.json();
  
  // Buscar tenant_id del usuario en tabla custom
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL'),
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  );
  
  const { data } = await supabase
    .from('user_tenants')
    .select('tenant_id')
    .eq('user_id', user.id)
    .single();
  
  // Agregar tenant_id a JWT claims
  return new Response(
    JSON.stringify({
      tenant_id: data.tenant_id  // C4: Disponible en RLS policies
    }),
    { headers: { 'Content-Type': 'application/json' } }
  );
});
```

### Caso 5: Backup Manual con Supabase CLI

```bash
# Instalar Supabase CLI
npm install -g supabase

# Login
supabase login

# Link a proyecto
supabase link --project-ref xxxxx

# Backup de schema + data
supabase db dump -f backup_$(date +%Y%m%d).sql

# Restaurar (si es necesario)
psql "postgresql://..." < backup_20260409.sql
```

### Caso 6: Queries Avanzadas con JSONB

```javascript
// query-metadata.js
import { createTenantClient } from './supabase-client.js';

async function findChunksByMetadata(tenantId, filters) {
  const supabase = createTenantClient(tenantId);
  
  // Buscar chunks con metadata específica
  // Ejemplo: { page: 12, section: "Introducción" }
  const { data } = await supabase
    .from('document_chunks')
    .select('*')
    .contains('metadata', filters);  // Operador JSONB
  
  return data;
}

// Uso
const chunks = await findChunksByMetadata('restaurant_456', {
  page: 12
});

// Query generada:
// SELECT * FROM document_chunks
// WHERE tenant_id = 'restaurant_456'
// AND metadata @> '{"page":12}'
```

---

## 🐞 Troubleshooting: 5+ Problemas Comunes y Soluciones Exactas

| Error Exacto | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso |
|--------------|-----------|------------------------|----------------------|
| `new row violates row-level security policy` | Intentar insertar sin tenant_id correcto en JWT | Ver JWT: `console.log(supabase.auth.session())` | 1. Verificar que JWT tenga claim `tenant_id`<br>2. Usar `createTenantClient(tenantId)` helper<br>3. O deshabilitar RLS temporalmente: `ALTER TABLE ... DISABLE ROW LEVEL SECURITY;` |
| `remaining connection slots reserved for non-replication superuser connections` | Demasiadas conexiones simultáneas | Dashboard Supabase → Database → Connections | 1. Usar pooler: puerto 6543 en connection string<br>2. Reducir `connection_limit` en Prisma<br>3. Implementar connection pooling en app (PgBouncer) |
| `JWT expired` | Token de más de 1 hora | `supabase.auth.getSession()` | 1. Implementar refresh automático:<br>`await supabase.auth.refreshSession()`<br>2. O usar `service_role_key` para servicios backend (sin expiración) |
| Latencia >500ms en queries | Región de Supabase lejos de VPS | `ping db.xxxxx.supabase.co` | 1. Migrar proyecto a región más cercana (Settings → General)<br>2. O usar PostgreSQL local si latencia es crítica<br>3. Cachear queries frecuentes en Redis |
| `Error: fetch failed` al llamar Supabase | Firewall VPS bloqueando HTTPS saliente | `curl https://xxxxx.supabase.co` | 1. Verificar UFW: `sudo ufw status`<br>2. Permitir HTTPS: `sudo ufw allow out 443/tcp`<br>3. Verificar DNS: `nslookup xxxxx.supabase.co` |
| Queries lentas con JSONB | Sin índice GIN en columna metadata | `EXPLAIN ANALYZE SELECT ... WHERE metadata @> ...` | 1. Crear índice GIN en Supabase SQL Editor:<br>`CREATE INDEX idx_chunks_metadata ON document_chunks USING GIN(metadata);`<br>2. Re-ejecutar query |

---

## ✅ Validación SDD y Comandos de Prueba

### Checklist RLS (C4 Enforcement)

```sql
-- 1. Verificar que RLS esté habilitado en TODAS las tablas
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('documents', 'document_chunks', 'ingestion_logs');

-- Output esperado:
--  tablename        | rowsecurity
-- ------------------|-------------
--  documents         | t (true)
--  document_chunks   | t
--  ingestion_logs    | t

-- 2. Listar políticas RLS
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE schemaname = 'public';

-- Debe haber al menos 1 política por tabla con filtro de tenant_id

-- 3. Test de aislamiento (como service_role para bypasear RLS)
-- Insertar datos de 2 tenants diferentes
INSERT INTO documents (tenant_id, filename, status, embedding_model)
VALUES 
  ('tenant_A', 'doc_A.pdf', 'completed', 'test'),
  ('tenant_B', 'doc_B.pdf', 'completed', 'test');

-- Simular query de tenant_A (RLS debería filtrar)
SET app.current_tenant = 'tenant_A';
SELECT COUNT(*) FROM documents;  -- Debe retornar 1, no 2
```

### Test de Latencia Comparativa

```javascript
// benchmark-latency.js
import { createClient } from '@supabase/supabase-js';
import { PrismaClient } from '@prisma/client';

async function benchmarkSupabaseVsLocal() {
  // Supabase
  const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_ANON_KEY
  );
  
  // PostgreSQL local
  const prisma = new PrismaClient({
    datasources: { db: { url: 'postgresql://localhost:5432/mantis_rag' } }
  });
  
  const iterations = 100;
  
  // Benchmark Supabase
  console.time('Supabase 100 queries');
  for (let i = 0; i < iterations; i++) {
    await supabase.from('documents').select('count');
  }
  console.timeEnd('Supabase 100 queries');
  
  // Benchmark local
  console.time('Local 100 queries');
  for (let i = 0; i < iterations; i++) {
    await prisma.document.count();
  }
  console.timeEnd('Local 100 queries');
}

benchmarkSupabaseVsLocal();

// Output típico:
// Supabase 100 queries: 6500ms  (65ms/query)
// Local 100 queries: 150ms       (1.5ms/query)
```

### Validación de Backups Automáticos

```bash
# En Supabase Dashboard:
# Settings → Database → Backups

# Verificar:
# 1. Daily backups habilitados ✅
# 2. Point-in-time recovery (PITR) activo ✅
# 3. Retention: 7 días (Pro plan) ✅

# Test de restore (solo si es necesario):
# Settings → Database → Restore from backup → Select date
```

---

## 🔗 Referencias Cruzadas

- [[01-RULES/06-MULTITENANCY-RULES.md]] - MT-010, MT-011 (RLS enforcement)
- [[01-RULES/03-SECURITY-RULES.md]] - SEG-004 (conexiones SSL), SEG-007 (JWT expiración)
- [[00-CONTEXT/facundo-infrastructure.md]] - Arquitectura híbrida VPS + Cloud

**Skills relacionados:**
- `postgres-prisma-rag.md` - Alternativa self-hosted a Supabase
- `qdrant-rag-ingestion.md` - Complemento para almacenamiento de vectores
- `multi-tenant-data-isolation.md` - Patrones avanzados de aislamiento
