---
title: "Sincronización Google Drive → Qdrant para RAG Multi-Tenant"
category: "Skill"
domain: ["rag", "backend", "automation"]
constraints: ["C1", "C2", "C4", "C6"]
priority: "Alta"
version: "1.0.0"
last_updated: "2026-04-09"
ai_optimized: true
tags:
  - sdd/skill/google-drive
  - sdd/skill/qdrant
  - sdd/skill/rag
  - sdd/skill/automation
  - sdd/skill/multi-tenant
  - lang/es
related_files:
  - "01-RULES/06-MULTITENANCY-RULES.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
  - "00-CONTEXT/facundo-infrastructure.md"
  - "01-RULES/04-API-RELIABILITY-RULES.md"
---

## 🎯 Propósito y Alcance

Implementar sincronización automática y bidireccional entre Google Drive y Qdrant, permitiendo que documentos subidos por clientes en carpetas específicas se procesen automáticamente en el sistema RAG multi-tenant.

**Casos de uso cubiertos:**
- Cliente sube PDF en Google Drive → Auto-ingesta en Qdrant con tenant_id
- Monitoreo de cambios en carpetas específicas por tenant
- Re-procesamiento de documentos actualizados
- Eliminación sincronizada (Drive → Qdrant)
- Metadata enriquecida (Drive file ID, versión, permisos)

**Arquitectura del flujo:**
```
Google Drive (Carpeta por tenant)
    ↓ Webhook / Polling
n8n Workflow (Orchestrator)
    ↓ Download + OCR
PDF Processing Pipeline
    ↓ Chunking
Embedding API (OpenAI/Cohere)
    ↓ Upsert con tenant_id
Qdrant (Vector DB)
```

**Comparación de estrategias de sincronización:**

| Estrategia | Latencia Detección | Costo API | Complejidad | Recomendado |
|------------|-------------------|-----------|-------------|-------------|
| **Webhooks** (Drive API Push) | Tiempo real (<1min) | Gratis | Alta (requiere endpoint público) | ✅ Producción |
| **Polling** (Check cada N min) | 5-15 min | Bajo (1 query/min) | Media | ✅ MVP |
| **Manual Trigger** | Usuario dispara | Gratis | Baja | ⚠️ Solo testing |
| **Cron diario** | 24 horas | Muy bajo | Baja | ❌ Muy lento |

**Decisión para este skill:** Polling cada 5 minutos (balance costo/latencia), con opción de upgrade a webhooks.

---

## 📐 Fundamentos (Nivel Básico)

### ¿Qué es Google Drive API?

**Google Drive API** permite a aplicaciones interactuar programáticamente con Google Drive:
- Listar archivos en carpetas
- Descargar archivos
- Obtener metadata (nombre, fecha modificación, tamaño)
- Recibir notificaciones de cambios (webhooks)

**Credenciales necesarias:**
1. **Service Account** (para acceso server-to-server, sin login manual)
2. **OAuth 2.0** (si necesitas acceso a carpetas de usuarios reales)

**Decisión para RAG multi-tenant:** Service Account + carpetas compartidas por tenant.

### Modelo Mental: Carpetas por Tenant

```
Google Drive (Cuenta principal del negocio)
│
├── 📁 restaurant_456_docs/
│   ├── 📄 menu.pdf
│   ├── 📄 politicas.pdf
│   └── 📄 manual_empleados.pdf
│
├── 📁 restaurant_789_docs/
│   ├── 📄 menu_especial.pdf
│   └── 📄 carta_vinos.pdf
│
└── 📁 hotel_abc_docs/
    ├── 📄 reglamento.pdf
    └── 📄 servicios.pdf
```

**Mapeo:**
- Nombre de carpeta → tenant_id (ej: `restaurant_456_docs` → `restaurant_456`)
- Cada archivo en carpeta → chunks con `tenant_id` asociado (C4)

### ¿Por qué Sincronización Automática?

**Sin sincronización:**
1. Cliente sube PDF a Drive
2. Cliente notifica manualmente al negocio
3. Alguien descarga el PDF
4. Alguien ejecuta script de ingesta
5. RAG actualizado después de horas/días ❌

**Con sincronización:**
1. Cliente sube PDF a Drive
2. Sistema detecta cambio automáticamente (5 min)
3. PDF se procesa y vectoriza automáticamente
4. RAG actualizado en <10 minutos ✅

**Beneficio:** Experiencia "mágica" para el cliente (sube y ya está disponible).

### Conceptos Clave de Drive API

**File ID:** Identificador único de archivo en Drive
```
https://drive.google.com/file/d/1a2b3c4d5e6f7g8h9i0j/view
                              ↑ File ID
```

**MIME Types:** Tipo de archivo
- `application/pdf` → PDF
- `application/vnd.google-apps.document` → Google Doc
- `image/jpeg` → Imagen

**modifiedTime:** Timestamp de última modificación
- Útil para detectar archivos nuevos o actualizados

---

## 🏗️ Arquitectura y Hardware Limitado (VPS 2vCPU/4-8GB)

### Arquitectura de Sincronización en 3 VPS

```
┌────────────────────────────────────────────┐
│  VPS 1 (4GB RAM) - Orquestación            │
│  ┌──────────────────────────────────────┐  │
│  │  n8n Workflow: Google Drive Sync     │  │
│  │  - Polling cada 5 min                │  │  C2: 1 workflow = ~50MB RAM
│  │  - Download PDFs (max 3 paralelos)   │  │  C1: Batch de 3 archivos
│  │  - Trigger PDF processing pipeline   │  │
│  └──────────────────────────────────────┘  │
└───────────────────┬────────────────────────┘
                    │ HTTPS
                    ▼
┌────────────────────────────────────────────┐
│  VPS 2 (4GB RAM) - Procesamiento           │
│  ┌──────────────────────────────────────┐  │
│  │  Python PDF Processor                │  │
│  │  - PyMuPDF / Mistral OCR             │  │  C1: Procesar 1 PDF a la vez
│  │  - Chunking + Embedding              │  │  C6: Mistral API (cloud)
│  └──────────────────────────────────────┘  │
└───────────────────┬────────────────────────┘
                    │ gRPC
                    ▼
┌────────────────────────────────────────────┐
│  VPS 3 (4GB RAM) - Vector Storage          │
│  ┌──────────────────────────────────────┐  │
│  │  Qdrant (Vector DB)                  │  │
│  │  - Collection: mantis_docs           │  │  C1: 1.5GB RAM limit
│  │  - Filtro tenant_id en searches      │  │  C4: Multi-tenant
│  └──────────────────────────────────────┘  │
└────────────────────────────────────────────┘
```

### Gestión de RAM Durante Sincronización

**Problema:** Descargar 10 PDFs de 10MB cada uno = 100MB en disco, pero ~300MB en RAM durante procesamiento.

**Solución: Streaming y Cleanup**
```javascript
// ❌ MALO: Cargar todos los PDFs en memoria
const files = await Promise.all(fileIds.map(downloadFile));
// RAM: 300MB ❌ Excede límite si hay otros procesos

// ✅ BUENO: Procesar uno a la vez con cleanup
for (const fileId of fileIds) {
  const file = await downloadFile(fileId);
  await processFile(file);
  
  // Cleanup explícito (liberar RAM)
  fs.unlinkSync(file.path);
  if (global.gc) global.gc();  // Forzar garbage collection
}
// RAM: 30MB por iteración ✅
```

### Rate Limiting de Google Drive API

**Límites por proyecto:**
- 1,000 queries por 100 segundos
- ~10 queries/segundo sostenido

**Cálculo para polling cada 5 minutos:**
```
Queries por ciclo:
- 1 query para listar archivos de carpeta
- 3 queries para descargar 3 archivos (en paralelo)
Total: 4 queries cada 5 minutos

4 queries/5min = 0.013 queries/seg ✅ Muy por debajo del límite
```

**Si hay 100 tenants:**
- 100 queries (1 por carpeta) cada 5 min
- 100/300seg = 0.33 queries/seg ✅ Aún dentro del límite

---

## 🔗 Conexión Local vs Externa (Prisma, Supabase, Qdrant, MySQL)

### Configuración de Google Drive Service Account

**Paso 1: Crear Service Account en Google Cloud Console**

```bash
# 1. Ir a: console.cloud.google.com
# 2. Crear proyecto: "mantis-rag-drive-sync"
# 3. Habilitar Google Drive API
# 4. Crear Service Account:
#    - Nombre: "drive-sync-bot"
#    - Rol: Ninguno (acceso solo a carpetas compartidas)
# 5. Crear clave JSON → Descargar
```

**Paso 2: Compartir carpetas con Service Account**

```
Email del Service Account: 
drive-sync-bot@mantis-rag-drive-sync.iam.gserviceaccount.com

Acción:
1. Abrir Google Drive
2. Crear carpeta: "restaurant_456_docs"
3. Botón derecho → Compartir
4. Agregar email del Service Account
5. Permisos: "Visor" (solo lectura)
6. Enviar
```

**Paso 3: Variables de Entorno**

```bash
# .env

# Google Drive
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
GOOGLE_DRIVE_SYNC_ENABLED=true
GOOGLE_DRIVE_POLLING_INTERVAL=5  # minutos

# Mapeo tenant_id → Folder ID
# Formato: tenant_id:folder_id,tenant_id:folder_id
TENANT_DRIVE_FOLDERS=restaurant_456:1a2b3c4d5e6f,restaurant_789:7h8i9j0k1l2m

# Límites (C1/C2)
MAX_PARALLEL_DOWNLOADS=3
MAX_FILE_SIZE_MB=100
```

### Qdrant Connection String

```javascript
// qdrant-client.js
import { QdrantClient } from '@qdrant/js-client-rest';

export const qdrantClient = new QdrantClient({
  url: process.env.QDRANT_URL || 'http://localhost:6333',
  apiKey: process.env.QDRANT_API_KEY,  // Solo si Qdrant Cloud
  timeout: 30000  // API-001: 30s timeout
});

// Verificar conexión
export async function testQdrantConnection() {
  try {
    const collections = await qdrantClient.getCollections();
    console.log('✅ Qdrant connected:', collections.collections.length, 'collections');
  } catch (error) {
    console.error('❌ Qdrant connection failed:', error.message);
    throw error;
  }
}
```

### PostgreSQL para Tracking de Sincronización

```sql
-- Tabla para tracking de archivos sincronizados
CREATE TABLE drive_sync_state (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL,  -- C4: OBLIGATORIO
  
  -- Google Drive metadata
  drive_file_id TEXT NOT NULL UNIQUE,
  drive_folder_id TEXT NOT NULL,
  filename TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  file_size_bytes BIGINT NOT NULL,
  
  -- Sincronización
  drive_modified_time TIMESTAMPTZ NOT NULL,
  last_synced_at TIMESTAMPTZ,
  sync_status TEXT NOT NULL DEFAULT 'pending',  -- 'pending', 'synced', 'failed'
  
  -- Qdrant references
  qdrant_point_ids TEXT[],  -- Array de IDs de puntos en Qdrant
  chunks_count INTEGER DEFAULT 0,
  
  -- Errors
  error_msg TEXT,
  retry_count INTEGER DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CHECK (sync_status IN ('pending', 'syncing', 'synced', 'failed')),
  CHECK (retry_count >= 0)
);

-- Índices optimizados
CREATE INDEX idx_sync_tenant_status ON drive_sync_state(tenant_id, sync_status);
CREATE INDEX idx_sync_drive_file ON drive_sync_state(drive_file_id);
CREATE INDEX idx_sync_modified ON drive_sync_state(drive_modified_time DESC);

-- Trigger para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_drive_sync_state_updated_at
  BEFORE UPDATE ON drive_sync_state
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

---

## 📘 Guía de Estructura de Tablas (Para principiantes)

### Diagrama de Relaciones

```
Tenant (1) ────── (N) drive_sync_state
   │                      │
   │                      ├── drive_file_id: "1a2b3c..."
   │                      ├── sync_status: pending/synced
   │                      ├── qdrant_point_ids: ["uuid1", "uuid2"]
   │                      └── chunks_count: 45
   │
   └────────── (N) document_chunks (en Qdrant)
                      │
                      └── payload.drive_metadata: {
                            file_id: "1a2b3c...",
                            filename: "menu.pdf",
                            version: 3
                          }
```

### Flujo de Estados

```
File nuevo detectado
    ↓
sync_status: 'pending'
    ↓
Download + Process
    ↓
sync_status: 'syncing'
    ↓
Upload a Qdrant (con tenant_id)
    ↓
sync_status: 'synced'
    qdrant_point_ids: ["uuid1", "uuid2", ...]
    chunks_count: 45
    
Si falla:
    ↓
sync_status: 'failed'
    error_msg: "OCR timeout"
    retry_count++
```

### Columnas Críticas Explicadas

| Columna | Propósito | Ejemplo | C4 Relevancia |
|---------|-----------|---------|---------------|
| `drive_file_id` | Identificador único en Drive | `"1a2b3c4d5e6f"` | Permite rastrear origen |
| `drive_modified_time` | Detectar archivos actualizados | `2026-04-09T10:30:00Z` | Re-procesar si cambió |
| `qdrant_point_ids` | IDs de chunks en Qdrant | `["uuid1", "uuid2"]` | Eliminar si archivo se borra |
| `tenant_id` | Aislamiento multi-tenant | `"restaurant_456"` | ✅ C4: Presente en TODAS las filas |
| `sync_status` | Estado de sincronización | `"synced"` | Evitar re-procesar innecesariamente |

---

## 🛠️ 4 Ejemplos Centrales (Copy-Paste, validables)

### Ejemplo 1: Listar Archivos Nuevos en Google Drive

```javascript
// list-new-files.js
const { google } = require('googleapis');

async function listNewFilesInFolder(folderId, tenantId, lastCheckTime) {
  // C4: Validar tenant_id
  if (!tenantId) {
    throw new Error('tenant_id required (C4)');
  }
  
  // Autenticar con Service Account
  const auth = new google.auth.GoogleAuth({
    keyFile: process.env.GOOGLE_APPLICATION_CREDENTIALS,
    scopes: ['https://www.googleapis.com/auth/drive.readonly']
  });
  
  const drive = google.drive({ version: 'v3', auth });
  
  // Query: Archivos en carpeta modificados después de lastCheckTime
  const query = [
    `'${folderId}' in parents`,
    `mimeType='application/pdf'`,  // Solo PDFs
    `trashed=false`,
    lastCheckTime ? `modifiedTime > '${lastCheckTime.toISOString()}'` : null
  ].filter(Boolean).join(' and ');
  
  const response = await drive.files.list({
    q: query,
    fields: 'files(id, name, mimeType, size, modifiedTime, webViewLink)',
    orderBy: 'modifiedTime desc',
    pageSize: 100  // C1: No listar más de 100 a la vez
  });
  
  const files = response.data.files || [];
  
  console.log(`📁 Found ${files.length} new/updated files in folder ${folderId}`);
  
  return files.map(file => ({
    drive_file_id: file.id,
    filename: file.name,
    mime_type: file.mimeType,
    file_size_bytes: parseInt(file.size),
    drive_modified_time: new Date(file.modifiedTime),
    web_view_link: file.webViewLink,
    tenant_id: tenantId  // C4: Asociar a tenant desde el inicio
  }));
}

// Uso
const newFiles = await listNewFilesInFolder(
  '1a2b3c4d5e6f',  // Folder ID de restaurant_456_docs
  'restaurant_456',  // tenant_id (C4)
  new Date('2026-04-09T00:00:00Z')  // Última verificación
);
```

### Ejemplo 2: Descargar Archivo de Drive

```javascript
// download-file.js
const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');

async function downloadFileFromDrive(fileId, tenantId) {
  // C4: Validar tenant_id
  if (!tenantId) {
    throw new Error('tenant_id required (C4)');
  }
  
  const auth = new google.auth.GoogleAuth({
    keyFile: process.env.GOOGLE_APPLICATION_CREDENTIALS,
    scopes: ['https://www.googleapis.com/auth/drive.readonly']
  });
  
  const drive = google.drive({ version: 'v3', auth });
  
  // Obtener metadata del archivo
  const metadata = await drive.files.get({
    fileId: fileId,
    fields: 'name, size, mimeType'
  });
  
  const filename = metadata.data.name;
  const fileSize = parseInt(metadata.data.size);
  
  // C1: Validar tamaño antes de descargar
  const maxSize = 100 * 1024 * 1024;  // 100MB
  if (fileSize > maxSize) {
    throw new Error(`File too large: ${(fileSize / 1024 / 1024).toFixed(1)}MB (max 100MB)`);
  }
  
  // Crear directorio temporal por tenant (aislamiento)
  const tempDir = `/tmp/drive-sync/${tenantId}`;
  if (!fs.existsSync(tempDir)) {
    fs.mkdirSync(tempDir, { recursive: true });
  }
  
  const destPath = path.join(tempDir, `${fileId}_${filename}`);
  const dest = fs.createWriteStream(destPath);
  
  // Descargar archivo (streaming para no consumir RAM)
  const response = await drive.files.get(
    { fileId: fileId, alt: 'media' },
    { responseType: 'stream' }
  );
  
  return new Promise((resolve, reject) => {
    response.data
      .on('end', () => {
        console.log(`✅ Downloaded: ${filename} (${(fileSize / 1024).toFixed(1)}KB)`);
        resolve({
          path: destPath,
          filename: filename,
          size_bytes: fileSize,
          tenant_id: tenantId  // C4
        });
      })
      .on('error', reject)
      .pipe(dest);
  });
}

// Uso
const file = await downloadFileFromDrive('7h8i9j0k1l2m', 'restaurant_456');
```

### Ejemplo 3: Registrar Estado de Sincronización en PostgreSQL

```javascript
// track-sync-state.js
import { prisma } from './prisma-client.js';

async function trackFileSyncState(fileMetadata) {
  const {
    drive_file_id,
    drive_folder_id,
    filename,
    mime_type,
    file_size_bytes,
    drive_modified_time,
    tenant_id  // C4: OBLIGATORIO
  } = fileMetadata;
  
  // C4: Validar
  if (!tenant_id) {
    throw new Error('tenant_id required (C4)');
  }
  
  // Upsert: Crear si no existe, actualizar si existe
  const syncRecord = await prisma.drive_sync_state.upsert({
    where: {
      drive_file_id: drive_file_id
    },
    update: {
      // Actualizar si archivo fue modificado
      drive_modified_time: drive_modified_time,
      sync_status: 'pending',  // Re-procesar
      retry_count: 0,
      error_msg: null,
      updated_at: new Date()
    },
    create: {
      tenant_id: tenant_id,  // C4
      drive_file_id: drive_file_id,
      drive_folder_id: drive_folder_id,
      filename: filename,
      mime_type: mime_type,
      file_size_bytes: file_size_bytes,
      drive_modified_time: drive_modified_time,
      sync_status: 'pending'
    }
  });
  
  console.log(`📝 Tracked file: ${filename} (status: ${syncRecord.sync_status})`);
  return syncRecord;
}

// Actualizar estado después de procesar
async function updateSyncStatus(driveFileId, status, qdrantPointIds = [], error = null) {
  const update = {
    sync_status: status,
    last_synced_at: status === 'synced' ? new Date() : undefined,
    qdrant_point_ids: qdrantPointIds.length > 0 ? qdrantPointIds : undefined,
    chunks_count: qdrantPointIds.length,
    error_msg: error,
    retry_count: status === 'failed' ? { increment: 1 } : undefined
  };
  
  const record = await prisma.drive_sync_state.update({
    where: { drive_file_id: driveFileId },
    data: update
  });
  
  console.log(`✅ Updated sync status: ${driveFileId} → ${status}`);
  return record;
}
```

### Ejemplo 4: Pipeline Completo de Sincronización

```javascript
// sync-pipeline.js
import { listNewFilesInFolder } from './list-new-files.js';
import { downloadFileFromDrive } from './download-file.js';
import { trackFileSyncState, updateSyncStatus } from './track-sync-state.js';
import { processPDFAuto } from './pdf-ingestion-pipeline.js';
import { upsertToQdrant } from './qdrant-upsert.js';
import fs from 'fs';

async function syncGoogleDriveToQdrant(tenantConfig) {
  const { tenant_id, folder_id, last_check_time } = tenantConfig;
  
  console.log(`\n🔄 Starting sync for tenant: ${tenant_id}`);
  
  try {
    // PASO 1: Listar archivos nuevos/actualizados
    const newFiles = await listNewFilesInFolder(
      folder_id,
      tenant_id,
      last_check_time
    );
    
    if (newFiles.length === 0) {
      console.log('✅ No new files to sync');
      return { synced: 0, failed: 0 };
    }
    
    console.log(`📂 Found ${newFiles.length} new files`);
    
    // PASO 2: Procesar cada archivo
    const results = { synced: 0, failed: 0 };
    
    for (const fileMetadata of newFiles) {
      try {
        // C1: Procesar uno a la vez (no en paralelo)
        console.log(`\n📄 Processing: ${fileMetadata.filename}`);
        
        // Registrar en BD
        await trackFileSyncState(fileMetadata);
        
        // Actualizar estado a 'syncing'
        await updateSyncStatus(fileMetadata.drive_file_id, 'syncing');
        
        // Descargar de Drive
        const downloadedFile = await downloadFileFromDrive(
          fileMetadata.drive_file_id,
          tenant_id
        );
        
        // Procesar PDF (OCR si es necesario)
        const processed = await processPDFAuto(
          downloadedFile.path,
          tenant_id,  // C4
          process.env.MISTRAL_API_KEY
        );
        
        // Generar embeddings y subir a Qdrant
        const qdrantPointIds = await upsertToQdrant(
          processed.chunks,
          tenant_id,  // C4
          {
            drive_file_id: fileMetadata.drive_file_id,
            drive_filename: fileMetadata.filename,
            drive_folder_id: folder_id
          }
        );
        
        // Actualizar estado a 'synced'
        await updateSyncStatus(
          fileMetadata.drive_file_id,
          'synced',
          qdrantPointIds
        );
        
        // Cleanup: Eliminar archivo temporal
        fs.unlinkSync(downloadedFile.path);
        
        console.log(`✅ Synced: ${fileMetadata.filename} (${qdrantPointIds.length} chunks)`);
        results.synced++;
        
      } catch (error) {
        console.error(`❌ Failed to process ${fileMetadata.filename}:`, error.message);
        
        // Actualizar estado a 'failed'
        await updateSyncStatus(
          fileMetadata.drive_file_id,
          'failed',
          [],
          error.message
        );
        
        results.failed++;
      }
    }
    
    console.log(`\n📊 Sync completed: ${results.synced} synced, ${results.failed} failed`);
    return results;
    
  } catch (error) {
    console.error(`❌ Sync pipeline failed for tenant ${tenant_id}:`, error);
    throw error;
  }
}

// Ejecutar sync para todos los tenants
async function syncAllTenants() {
  const tenantConfigs = [
    {
      tenant_id: 'restaurant_456',
      folder_id: '1a2b3c4d5e6f',
      last_check_time: new Date(Date.now() - 5 * 60 * 1000)  // Últimos 5 min
    },
    {
      tenant_id: 'restaurant_789',
      folder_id: '7h8i9j0k1l2m',
      last_check_time: new Date(Date.now() - 5 * 60 * 1000)
    }
  ];
  
  console.log('🚀 Starting multi-tenant sync...\n');
  
  const results = [];
  
  // C2: Procesar tenants secuencialmente (no en paralelo)
  for (const config of tenantConfigs) {
    const result = await syncGoogleDriveToQdrant(config);
    results.push({ tenant_id: config.tenant_id, ...result });
  }
  
  console.log('\n✅ All tenants synced:');
  console.table(results);
}

syncAllTenants();
```

---

## 🔍 >5 Ejemplos Independientes por Caso de Uso

### Caso 1: Webhook de Google Drive (Push Notifications)

```javascript
// drive-webhook.js
const express = require('express');
const { google } = require('googleapis');

const app = express();
app.use(express.json());

// Endpoint para recibir notificaciones de Drive
app.post('/webhooks/drive', async (req, res) => {
  const channelId = req.headers['x-goog-channel-id'];
  const resourceState = req.headers['x-goog-resource-state'];  // 'sync', 'add', 'remove', 'update'
  
  console.log(`📬 Webhook received: ${resourceState} on channel ${channelId}`);
  
  // Responder rápido (Google espera 200 OK en <10s)
  res.status(200).send('OK');
  
  // Procesar async (no bloquear respuesta)
  if (resourceState === 'update' || resourceState === 'add') {
    const tenantId = channelId.split('_')[0];  // Ej: 'restaurant_456_channel'
    
    syncGoogleDriveToQdrant({ tenant_id: tenantId, ... })
      .catch(err => console.error('Sync failed:', err));
  }
});

// Registrar webhook para carpeta
async function registerWebhook(folderId, tenantId) {
  const auth = new google.auth.GoogleAuth({
    keyFile: process.env.GOOGLE_APPLICATION_CREDENTIALS,
    scopes: ['https://www.googleapis.com/auth/drive.readonly']
  });
  
  const drive = google.drive({ version: 'v3', auth });
  
  const channelId = `${tenantId}_drive_channel`;
  const webhookUrl = `https://your-domain.com/webhooks/drive`;  // Debe ser HTTPS público
  
  const response = await drive.files.watch({
    fileId: folderId,
    requestBody: {
      id: channelId,
      type: 'web_hook',
      address: webhookUrl,
      expiration: Date.now() + (7 * 24 * 60 * 60 * 1000)  // 7 días
    }
  });
  
  console.log(`✅ Webhook registered for folder ${folderId}:`, response.data);
  return response.data;
}

app.listen(3000, () => console.log('Webhook server listening on :3000'));
```

### Caso 2: Detectar y Eliminar Archivos Borrados

```javascript
// detect-deleted-files.js
async function detectDeletedFiles(tenantId, folderId) {
  // Listar archivos actuales en Drive
  const currentFiles = await listNewFilesInFolder(folderId, tenantId, null);
  const currentFileIds = new Set(currentFiles.map(f => f.drive_file_id));
  
  // Listar archivos en nuestra BD para este tenant
  const syncedFiles = await prisma.drive_sync_state.findMany({
    where: {
      tenant_id: tenantId,
      drive_folder_id: folderId,
      sync_status: 'synced'
    },
    select: {
      drive_file_id: true,
      qdrant_point_ids: true,
      filename: true
    }
  });
  
  // Detectar archivos que ya no están en Drive
  const deletedFiles = syncedFiles.filter(
    sf => !currentFileIds.has(sf.drive_file_id)
  );
  
  if (deletedFiles.length === 0) {
    console.log('✅ No deleted files detected');
    return [];
  }
  
  console.log(`🗑️  Detected ${deletedFiles.length} deleted files`);
  
  // Eliminar de Qdrant
  for (const file of deletedFiles) {
    try {
      // Eliminar puntos de Qdrant
      await qdrantClient.delete('mantis_docs', {
        filter: {
          must: [
            { key: 'tenant_id', match: { keyword: tenantId } },  // C4
            { key: 'drive_file_id', match: { keyword: file.drive_file_id } }
          ]
        }
      });
      
      // Eliminar de BD
      await prisma.drive_sync_state.delete({
        where: { drive_file_id: file.drive_file_id }
      });
      
      console.log(`✅ Deleted: ${file.filename}`);
      
    } catch (error) {
      console.error(`❌ Failed to delete ${file.filename}:`, error.message);
    }
  }
  
  return deletedFiles;
}
```

### Caso 3: Re-procesar Archivos Actualizados

```javascript
// reprocess-updated-files.js
async function reprocessUpdatedFiles(tenantId, folderId) {
  // Listar archivos actuales en Drive
  const currentFiles = await listNewFilesInFolder(folderId, tenantId, null);
  
  for (const driveFile of currentFiles) {
    // Buscar en BD
    const syncedFile = await prisma.drive_sync_state.findUnique({
      where: { drive_file_id: driveFile.drive_file_id }
    });
    
    if (!syncedFile) continue;  // Archivo nuevo
    
    // Comparar timestamps
    const driveModified = new Date(driveFile.drive_modified_time);
    const lastSynced = syncedFile.last_synced_at;
    
    if (driveModified > lastSynced) {
      console.log(`🔄 File updated: ${driveFile.filename} (re-processing)`);
      
      // Eliminar chunks antiguos de Qdrant
      await qdrantClient.delete('mantis_docs', {
        filter: {
          must: [
            { key: 'tenant_id', match: { keyword: tenantId } },
            { key: 'drive_file_id', match: { keyword: driveFile.drive_file_id } }
          ]
        }
      });
      
      // Actualizar estado a 'pending' para re-procesar
      await updateSyncStatus(driveFile.drive_file_id, 'pending');
      
      console.log(`✅ Marked for re-processing: ${driveFile.filename}`);
    }
  }
}
```

### Caso 4: Exportar Google Docs a PDF

```javascript
// export-google-doc.js
async function exportGoogleDocToPDF(fileId, tenantId) {
  const auth = new google.auth.GoogleAuth({
    keyFile: process.env.GOOGLE_APPLICATION_CREDENTIALS,
    scopes: ['https://www.googleapis.com/auth/drive.readonly']
  });
  
  const drive = google.drive({ version: 'v3', auth });
  
  // Verificar que es un Google Doc
  const metadata = await drive.files.get({
    fileId: fileId,
    fields: 'mimeType, name'
  });
  
  if (metadata.data.mimeType !== 'application/vnd.google-apps.document') {
    throw new Error('Not a Google Doc');
  }
  
  // Exportar como PDF
  const destPath = `/tmp/drive-sync/${tenantId}/${fileId}.pdf`;
  const dest = fs.createWriteStream(destPath);
  
  const response = await drive.files.export(
    {
      fileId: fileId,
      mimeType: 'application/pdf'  // Convertir a PDF
    },
    { responseType: 'stream' }
  );
  
  return new Promise((resolve, reject) => {
    response.data
      .pipe(dest)
      .on('finish', () => {
        console.log(`✅ Exported Google Doc to PDF: ${metadata.data.name}`);
        resolve({ path: destPath, filename: `${metadata.data.name}.pdf` });
      })
      .on('error', reject);
  });
}
```

### Caso 5: Sincronización Incremental con Paginación

```javascript
// incremental-sync.js
async function incrementalSyncWithPagination(folderId, tenantId) {
  const auth = new google.auth.GoogleAuth({
    keyFile: process.env.GOOGLE_APPLICATION_CREDENTIALS,
    scopes: ['https://www.googleapis.com/auth/drive.readonly']
  });
  
  const drive = google.drive({ version: 'v3', auth });
  
  let pageToken = null;
  let allFiles = [];
  
  do {
    const response = await drive.files.list({
      q: `'${folderId}' in parents and mimeType='application/pdf' and trashed=false`,
      fields: 'nextPageToken, files(id, name, modifiedTime)',
      pageSize: 100,  // C1: No más de 100 por página
      pageToken: pageToken,
      orderBy: 'modifiedTime desc'
    });
    
    const files = response.data.files || [];
    allFiles = allFiles.concat(files);
    
    pageToken = response.data.nextPageToken;
    
    console.log(`📄 Fetched page: ${files.length} files (total: ${allFiles.length})`);
    
  } while (pageToken);
  
  console.log(`✅ Total files in folder: ${allFiles.length}`);
  return allFiles;
}
```

### Caso 6: Logs Estructurados de Sincronización

```javascript
// sync-logger.js
import winston from 'winston';

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.File({ filename: 'drive-sync.log' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ]
});

function logSyncEvent(tenantId, event, metadata = {}) {
  logger.info({
    timestamp: new Date().toISOString(),
    tenant_id: tenantId,  // C4: Siempre presente
    event: event,
    ...metadata
  });
}

// Uso
logSyncEvent('restaurant_456', 'sync_started', {
  folder_id: '1a2b3c4d5e6f',
  files_to_sync: 3
});

logSyncEvent('restaurant_456', 'file_synced', {
  drive_file_id: '7h8i9j0k1l2m',
  filename: 'menu.pdf',
  chunks_created: 12,
  processing_time_ms: 3500
});
```

---

## 🐞 Troubleshooting: 5+ Problemas Comunes y Soluciones Exactas

| Error Exacto | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso |
|--------------|-----------|------------------------|----------------------|
| `Error: invalid_grant (Invalid JWT Signature)` | Service Account key inválida o expirada | Verificar fecha de creación de key en Google Cloud Console | 1. Ir a Google Cloud Console → IAM → Service Accounts<br>2. Eliminar key antigua<br>3. Crear nueva key JSON<br>4. Actualizar `GOOGLE_APPLICATION_CREDENTIALS` en `.env`<br>5. Reiniciar servicio |
| `Error: File not found` | Archivo existe en Drive pero Service Account no tiene acceso | `drive.files.get({ fileId: 'xxx' })` (verificar permisos) | 1. Abrir archivo en Drive<br>2. Botón derecho → Compartir<br>3. Agregar email del Service Account<br>4. Permisos: "Visor"<br>5. Verificar con query de nuevo |
| `ENOSPC: no space left on device` | Disco del VPS lleno por archivos temporales | `df -h` (ver uso de disco) | 1. Verificar: `du -sh /tmp/drive-sync/*`<br>2. Eliminar archivos viejos: `find /tmp/drive-sync -mtime +1 -delete`<br>3. Implementar cleanup automático después de cada sync<br>4. O reducir `MAX_PARALLEL_DOWNLOADS` |
| `Error: Rate limit exceeded` | Demasiadas queries a Drive API | Ver quota usage en Google Cloud Console → APIs & Services | 1. Aumentar intervalo de polling (5min → 10min)<br>2. Reducir `pageSize` en queries (100 → 50)<br>3. Implementar backoff exponencial en retries<br>4. O solicitar aumento de quota a Google |
| Archivos procesados múltiples veces | No se está checkeando `drive_modified_time` correctamente | `SELECT * FROM drive_sync_state WHERE sync_status='synced' AND drive_file_id='xxx'` | 1. Comparar `drive_modified_time` en Drive vs BD<br>2. Actualizar lógica de detección de cambios<br>3. Agregar índice en `drive_modified_time` |
| Chunks duplicados en Qdrant | No se están eliminando chunks viejos antes de re-procesar | `qdrantClient.scroll('mantis_docs', { filter: {...}})` | 1. Antes de re-procesar, eliminar chunks antiguos<br>2. Verificar que filtro incluya `tenant_id` (C4)<br>3. Confirmar eliminación antes de insertar nuevos chunks |

---

## ✅ Validación SDD y Comandos de Prueba

### Test de Conexión a Google Drive

```javascript
// test-drive-connection.js
const { google } = require('googleapis');

async function testDriveConnection() {
  try {
    const auth = new google.auth.GoogleAuth({
      keyFile: process.env.GOOGLE_APPLICATION_CREDENTIALS,
      scopes: ['https://www.googleapis.com/auth/drive.readonly']
    });
    
    const drive = google.drive({ version: 'v3', auth });
    
    // Listar archivos raíz
    const response = await drive.files.list({
      pageSize: 1,
      fields: 'files(id, name)'
    });
    
    console.log('✅ Google Drive API connected');
    console.log('Sample file:', response.data.files[0]);
    
  } catch (error) {
    console.error('❌ Connection failed:', error.message);
    process.exit(1);
  }
}

testDriveConnection();
```

### Validación de tenant_id en Chunks (C4)

```javascript
// validate-tenant-id.js
async function validateTenantIdInQdrant(tenantId) {
  const response = await qdrantClient.scroll('mantis_docs', {
    filter: {
      must: [
        { key: 'tenant_id', match: { keyword: tenantId } }
      ]
    },
    limit: 1000
  });
  
  const points = response.points;
  
  // Verificar que TODOS tengan tenant_id
  const missingTenantId = points.filter(
    p => !p.payload.tenant_id || p.payload.tenant_id !== tenantId
  );
  
  if (missingTenantId.length > 0) {
    console.error(`❌ C4 VIOLATION: ${missingTenantId.length} points without correct tenant_id`);
    return false;
  }
  
  console.log(`✅ All ${points.length} points have correct tenant_id (C4 compliant)`);
  return true;
}

// Ejecutar para todos los tenants
const tenants = ['restaurant_456', 'restaurant_789'];
for (const tid of tenants) {
  await validateTenantIdInQdrant(tid);
}
```

### Test End-to-End de Sincronización

```bash
#!/bin/bash
# test-sync-e2e.sh

echo "🧪 Starting end-to-end sync test..."

# 1. Subir archivo de prueba a Drive (manual)
echo "📤 Upload test.pdf to Drive folder"
echo "Press Enter when ready..."
read

# 2. Ejecutar sincronización
echo "🔄 Running sync..."
node sync-pipeline.js

# 3. Verificar en PostgreSQL
echo "📊 Checking PostgreSQL..."
psql -d mantis_rag -c "
  SELECT filename, sync_status, chunks_count 
  FROM drive_sync_state 
  WHERE filename LIKE '%test%' 
  ORDER BY created_at DESC 
  LIMIT 1;
"

# 4. Verificar en Qdrant
echo "🔍 Checking Qdrant..."
curl -X POST http://localhost:6333/collections/mantis_docs/points/scroll \
  -H 'Content-Type: application/json' \
  -d '{
    "filter": {
      "must": [
        {"key": "drive_filename", "match": {"keyword": "test.pdf"}}
      ]
    },
    "limit": 1
  }' | jq '.result.points | length'

echo "✅ Test completed"
```

---

## 🔗 Referencias Cruzadas

- [[01-RULES/06-MULTITENANCY-RULES.md]] - MT-004, MT-007, MT-009 (tenant_id en metadata, payloads)
- [[01-RULES/02-RESOURCE-GUARDRAILS.md]] - RES-001, RES-008, RES-010 (límites RAM, chunking, archivos)
- [[01-RULES/04-API-RELIABILITY-RULES.md]] - API-001, API-003 (timeouts, retries)
- [[00-CONTEXT/facundo-infrastructure.md]] - Arquitectura 3-VPS, C1/C2 constraints

**Skills relacionados:**
- `qdrant-rag-ingestion.md` - Upsert de vectores con tenant_id
- `pdf-mistralocr-processing.md` - Procesamiento de PDFs descargados
- `postgres-prisma-rag.md` - Almacenar metadata de sincronización
- `supabase-rag-integration.md` - Alternativa cloud para metadata
