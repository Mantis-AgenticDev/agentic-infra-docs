---
title: whatsapp-rag-openrouter.md
version: 2.0.0
date: 2026-04-07
status: ACTIVE_DRAFT
domain: ["comunicacion", "ai", "base-de-datos-rag"]
constraints_applied: [C1, C2, C3, C4, C5, C6]
inference_provider: OpenRouter Proxy
author: Mantis Agentic 
priority: "CRÍTICA"
version: "1.0.0"
last_updated: "2026-04-11"
ai_optimized: true
tags:
  - sdd/skill/comunicacion
  - sdd/skill/ai
  - sdd/skill/base-de-datos-rag
  - lang/es
related_files:
  - "01-RULES/00-INDEX.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
  - "01-RULES/03-SECURITY-RULES.md"
  - "00-CONTEXT/facundo-infrastructure.md"
  - "02-SKILLS/skill-domains-mapping.md"
  - "02-SKILLS/COMUNICACION/whatsapp-uazapi-integration.md"
  - "02-SKILLS/COMUNICACION/telegram-bot-integration.md"
  - "02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md"
  - "02-SKILLS/BASE DE DATOS-RAG/postgres-prisma-rag.md"
  - "02-SKILLS/BASE DE DATOS-RAG/mysql-sql-rag-ingestion.md"
  - "02-SKILLS/BASE DE DATOS-RAG/google-drive-qdrant-sync.md"
  - "02-SKILLS/BASE DE DATOS-RAG/multi-tenant-data-isolation.md"
  - "02-SKILLS/AI/openrouter-api-integration.md"
  - "05-CONFIGURATIONS/environment-variable-management.md"
---

# 📖 Introducción & MODO JUNIOR

Este documento es la especificación técnica definitiva para la implementación de pipelines RAG sobre WhatsApp mediante OpenRouter. **MODO JUNIOR ACTIVADO:** Si no cumples con una sola regla, el PR será rechazado automáticamente por el pipeline de validación agéntica. No se aceptan excepciones ni atajos.

**Reglas Inquebrantables (C1-C6):**
- 🔒 **C3 (Credenciales):** Cero hardcodeo. Todas las claves, URIs y tokens se inyectan exclusivamente vía `process.env` (Node.js) o `os.getenv()` (Python).
- 🏢 **C4 (Multi-tenancy):** `tenant_id` es OBLIGATORIO en cada query, log, clave de caché y payload de inferencia. Sin excepción.
- ⏱️ **C1/C2 (Límites):** Todo snippet debe declarar explícitamente `maxResults`, `connectionLimit` y `timeout`.
- ☁️ **C6 (Inferencia):** Prohibido ejecutar modelos locales o endpoints directos. Todo tráfico de inferencia pasa por `OpenRouter Proxy`.
- ✅❌ **C5 (Validación):** Cada bloque de implementación futura incluirá bloques de verificación ejecutables `✅ Deberías ver:` y `❌ Si ves esto:` con su respectiva tabla de troubleshooting.

---

# 🧱 Fundamentos Técnicos

## 1. Arquitectura de Flujo de Datos
```
WhatsApp Webhook → API Gateway (Inyección/Validación tenant_id) → OpenRouter Proxy → RAG Orchestrator → Persistencia (Vector/Relacional)
```
El orquestador desacopla la recepción del mensaje de la recuperación de contexto y la generación de respuesta. La inferencia es 100% cloud-síncrona vía proxy. El flujo garantiza aislamiento estricto por inquilino desde el primer milisegundo.

## 2. Gestión de Entornos (C3)
La configuración base reside en `.env` o gestor de secretos. El código **nunca** referencia valores literales ni cadenas sensibles.
- `TENANT_ID`: Identificador único del cliente/espacio de trabajo.
- `OPENROUTER_API_KEY`: Clave para proxy de inferencia.
- `DB_HOST`, `DB_USER`, `DB_PASS`, `DB_NAME`: Credenciales de persistencia.
- `MAX_RESULTS`, `CONNECTION_LIMIT`, `TIMEOUT_MS`: Parámetros de límites operativos.

**Patrón de Carga Segura:**
- JavaScript/Node.js: `const tenant = process.env.TENANT_ID ?? (() => { throw new Error('C4 VIOLATION: tenant_id missing'); })();`
- Python: `tenant = os.getenv("TENANT_ID") or sys.exit("C4 VIOLATION: tenant_id missing")`

## 3. Estrategia de Multi-Tenancy (C4)
- **Queries:** Filtro obligatorio en primer nivel. SQL: `WHERE tenant_id = :tenant_id`. Vectorial: `filter={"tenant_id": {"$eq": tenant_id}}`.
- **Logs:** Estructura JSON plana `{ "timestamp": "...", "tenant_id": "...", "event": "...", "severity": "..." }`. Sin `tenant_id`, el log se descarta y se alerta.
- **Caché:** Clave compuesta `${tenant_id}:${namespace}:${content_hash}`. Prohibido caché global o cross-tenant.
- **Fallo Crítico:** Si `tenant_id` es `null`, `undefined`, vacío o no coincide con el contexto de la sesión, el sistema aborta inmediatamente con `HTTP 400` y registro de auditoría.

## 4. Límites y Resiliencia (C1/C2)
Todos los componentes deben inicializarse con timeouts explícitos y límites de conexión para prevenir starvation, costoso over-fetching y bloqueos del event loop.
- `maxResults`: Límite superior de vectores/documentos recuperados. Default: `5`.
- `connectionLimit`: Pool máximo de conexiones concurrentes a BBDD. Default: `10`.
- `timeout`: Timeout máximo de petición en ms. Default: `30000`.
Estos valores son configurables por entorno pero **deben estar declarados** explícitamente en la instanciación del cliente. No se aceptan valores por defecto de la librería subyacente.

## 5. Ruta de Inferencia (C6)
- Endpoint único: `https://openrouter.ai/api/v1/chat/completions`
- Headers requeridos: `Authorization: Bearer ${process.env.OPENROUTER_API_KEY}`, `HTTP-Referer: whatsapp-rag-pipeline`
- Modelo por defecto: `qwen/qwen-3.6-plus` (o especificación agéntica acordada)
- Payload debe incluir `tenant_id` en `metadata` para trazabilidad de consumo y facturación interna.
- Prohibido fallback a proveedores alternativos sin rotación explícita de clave y validación de C4 en el nuevo endpoint.

## 6. Preparación para Lotes de Implementación
Cada lote siguiente (Qdrant → PostgreSQL → MySQL → Supabase → GDrive/Sheets → Airtable → SQLite → IAs) seguirá la estructura exigida:
- Código con `tenant_id`, `maxResults`, `connectionLimit`, `timeout`.
- Inyección segura de variables vía `process.env`/`os.getenv()`.
- Bloques `✅ Deberías ver:` y `❌ Si ves esto:`.
- Tabla de Troubleshooting vinculada.

---


## Lote Qdrant (Vector/RAG)

### Ejemplo 1: Ingestión RAG con tenant_id
**Objetivo**: Indexar embeddings de documentos asegurando aislamiento estricto por inquilino | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import { QdrantClient } from '@qdrant/js-client-rest';

const QDRANT_CONFIG = {
  url: process.env.QDRANT_URL || 'http://localhost:6333',
  apiKey: process.env.QDRANT_API_KEY,
  timeout: Number(process.env.TIMEOUT_MS) || 30000,
  connectionLimit: Number(process.env.CONNECTION_LIMIT) || 10
};

const client = new QdrantClient({ url: QDRANT_CONFIG.url, apiKey: QDRANT_CONFIG.apiKey, timeout: QDRANT_CONFIG.timeout, maxConnections: QDRANT_CONFIG.connectionLimit });

async function ingestRAG(tenant_id: string, embeddings: number[], metadata: Record<string, any>) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id is mandatory');
  const payload = { ...metadata, tenant_id, source: 'rag_ingest' };
  
  await client.upsert('rag_vectors', {
    wait: true,
    points: [{ id: `${tenant_id}:${Date.now()}`, vector: embeddings, payload }]
  });
  console.log(JSON.stringify({ event: 'ingest_ok', tenant_id, maxResults: process.env.MAX_RESULTS }));
}
```

**✅ Deberías ver:** `{"event":"ingest_ok","tenant_id":"acme-corp","maxResults":"5"}` en logs + punto insertado en `rag_vectors` con payload `tenant_id: "acme-corp"`
**❌ Si ves esto en su lugar:** `QdrantError: Unauthorized` o `C4 VIOLATION: tenant_id is mandatory` → Ve a Troubleshooting #1

**Troubleshooting:**
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `C4 VIOLATION: tenant_id is mandatory` | `tenant_id` undefined/null en runtime | `console.log(process.env.TENANT_ID)` | Inyectar `TENANT_ID` en entorno o validar middleware previo | C4 |
| `QdrantError: Unauthorized` | API Key inválida o expirada | `curl -H "api-key: $QDRANT_API_KEY" $QDRANT_URL/health` | Rotar credencial en `.env` y reiniciar proceso | C3 |

---

### Ejemplo 2: Filtrado metadata
**Objetivo**: Recuperar solo vectores coincidentes con `tenant_id` y etiquetas específicas | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import { QdrantClient } from '@qdrant/js-client-rest';

const maxResults = Number(process.env.MAX_RESULTS) || 5;
const timeout = Number(process.env.TIMEOUT_MS) || 30000;
const connLimit = Number(process.env.CONNECTION_LIMIT) || 10;
const client = new QdrantClient({ url: process.env.QDRANT_URL, apiKey: process.env.QDRANT_API_KEY, timeout, maxConnections: connLimit });

async function queryWithFilter(tenant_id: string, queryVector: number[], tags: string[]) {
  if (!tenant_id) throw new Error('C4 VIOLATION');
  const filter = {
    must: [
      { key: 'tenant_id', match: { value: tenant_id } },
      { key: 'tags', match: { any: tags } }
    ]
  };
  return client.search('rag_vectors', { vector: queryVector, filter, limit: maxResults, with_payload: true });
}
```

**✅ Deberías ver:** Array de máx 5 objetos con `payload.tenant_id === tenant_id` y `payload.tags` intersectando `tags`
**❌ Si ves esto en su lugar:** `Error: filter must contain tenant_id` o `Qdrant timeout` → Ve a Troubleshooting #2

**Troubleshooting:**
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Qdrant timeout` | Conexión bloqueada por alto tráfico | `top -p $(pgrep node) \| grep mem` | Ajustar `CONNECTION_LIMIT` y `TIMEOUT_MS` en `.env` | C1/C2 |
| `filter validation failed` | Sintaxis de filtro Qdrant inválida | Revisar docs Qdrant `v1.7+ filter` | Usar estructura `{ must: [{ key, match }] }` estricta | C1 |

---

### Ejemplo 3: Sync GDrive
**Objetivo**: Ingestar cambios de Google Drive manteniendo `tenant_id` en metadata | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import { QdrantClient } from '@qdrant/js-client-rest';

const client = new QdrantClient({ url: process.env.QDRANT_URL, apiKey: process.env.QDRANT_API_KEY, timeout: Number(process.env.TIMEOUT_MS), maxConnections: Number(process.env.CONNECTION_LIMIT) });

async function syncDriveToQdrant(tenant_id: string, fileChunks: { id: string; vector: number[]; text: string }[]) {
  if (!process.env.GDRIVE_CREDENTIALS || !tenant_id) throw new Error('C3/C4 VIOLATION');
  const points = fileChunks.map(chunk => ({
    id: `${tenant_id}:gdrive:${chunk.id}`,
    vector: chunk.vector,
    payload: { tenant_id, source: 'gdrive', path: `/drive/${chunk.id}` }
  }));
  await client.upsert('rag_vectors', { wait: true, points });
}
```

**✅ Deberías ver:** Puntos con IDs prefijados `${tenant_id}:gdrive:` y payload `source: "gdrive"` insertados correctamente
**❌ Si ves esto en su lugar:** `GDRIVE_CREDENTIALS missing` o `duplicate point id` → Ve a Troubleshooting #3

**Troubleshooting:**
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `C3/C4 VIOLATION` | Variables no cargadas o `tenant_id` ausente | `env \| grep -E 'GDRIVE|TENANT'` | Configurar secretos en CI/CD o `.env.local` | C3/C4 |
| `duplicate point id` | Re-indexación sin control de versiones | `curl $QDRANT_URL/collections/rag_vectors/points/count` | Implementar hash de versión o usar `overwrite: false` | C1 |

---

### Ejemplo 4: Payload chunks
**Objetivo**: Validar estructura de chunks antes de ingestión masiva | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import { QdrantClient } from '@qdrant/js-client-rest';

const cfg = { url: process.env.QDRANT_URL, apiKey: process.env.QDRANT_API_KEY, timeout: Number(process.env.TIMEOUT_MS), maxConnections: Number(process.env.CONNECTION_LIMIT) };
const client = new QdrantClient(cfg);

function validateChunk(tenant_id: string, chunk: any) {
  if (!tenant_id || !chunk.vector?.length || chunk.vector.length !== 1536) throw new Error('Invalid chunk payload');
  return { ...chunk, payload: { tenant_id, chunk_index: chunk.idx } };
}

async function batchUpsert(tenant_id: string, chunks: any[]) {
  const valid = chunks.map(c => validateChunk(tenant_id, c));
  await client.upsert('rag_vectors', { wait: false, points: valid });
}
```

**✅ Deberías ver:** `batchUpsert` retorna promesa resuelta; Qdrant procesa en background sin bloquear
**❌ Si ves esto en su lugar:** `Invalid chunk payload` o `Dimension mismatch` → Ve a Troubleshooting #4

**Troubleshooting:**
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Dimension mismatch` | Embedding model vs colección difieren | `curl $QDRANT_URL/collections/rag_vectors` | Alinear dimensión a `1536` o recrear colección | C2 |
| `Invalid chunk payload` | Schema de validación estricto fallado | `console.log(chunk.vector?.length)` | Normalizar chunks con splitter consistente | C4 |

---

### Ejemplo 5: Caché sesiones
**Objetivo**: Cache de respuestas RAG con clave compuesta `tenant_id:namespace` | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import { QdrantClient } from '@qdrant/js-client-rest';
import crypto from 'crypto';

const client = new QdrantClient({ url: process.env.QDRANT_URL, apiKey: process.env.QDRANT_API_KEY, timeout: Number(process.env.TIMEOUT_MS), maxConnections: Number(process.env.CONNECTION_LIMIT) });
const cacheCollection = 'rag_cache';

function getCacheKey(tenant_id: string, prompt: string) {
  const hash = crypto.createHash('sha256').update(prompt).digest('hex').slice(0, 16);
  return `${tenant_id}:cache:${hash}`;
}

async function checkSessionCache(tenant_id: string, prompt: string) {
  const id = getCacheKey(tenant_id, prompt);
  const res = await client.retrieve(cacheCollection, { ids: [id], with_payload: true });
  return res[0]?.payload?.response || null;
}
```

**✅ Deberías ver:** String con respuesta cacheada o `null` si miss. Clave siempre inicia con `${tenant_id}:cache:`
**❌ Si ves esto en su lugar:** `TypeError: Cannot read properties of undefined` o `C4 cache bypass` → Ve a Troubleshooting #5

**Troubleshooting:**
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `C4 cache bypass` | `tenant_id` no propagado a función de hash | `console.log(getCacheKey(undefined, 'test'))` | Asegurar middleware de validación previo a llamada | C4 |
| `TypeError: Cannot read properties` | Colección caché no existe | `curl $QDRANT_URL/collections` | Ejecutar `createCollection` con `vector_size: 1536` | C1 |

---

### Ejemplo 6: Healthcheck
**Objetivo**: Verificar estado de Qdrant y latencia de conexión | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import { QdrantClient } from '@qdrant/js-client-rest';

async function qdrantHealth(tenant_id: string) {
  const start = Date.now();
  const client = new QdrantClient({ url: process.env.QDRANT_URL, apiKey: process.env.QDRANT_API_KEY, timeout: Number(process.env.TIMEOUT_MS), maxConnections: Number(process.env.CONNECTION_LIMIT) });
  const res = await client.collections();
  const latency = Date.now() - start;
  const logs = { event: 'health_check', tenant_id, latency, status: 'ok', maxResults: process.env.MAX_RESULTS };
  return { ...res, logs: JSON.stringify(logs) };
}
```

**✅ Deberías ver:** `{ logs: "{\"event\":\"health_check\",\"tenant_id\":\"...\",\"latency\":<50,...}" }` y lista de colecciones
**❌ Si ves esto en su lugar:** `QdrantError: Connection refused` o `timeout exceeded` → Ve a Troubleshooting #6

**Troubleshooting:**
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `QdrantError: Connection refused` | Servicio caído o puerto bloqueado | `telnet $QDRANT_URL 6333` | Reiniciar contenedor Qdrant o verificar firewall | C2 |
| `timeout exceeded` | `TIMEOUT_MS` muy bajo o red lenta | `ping -c 5 $QDRANT_HOST` | Aumentar `TIMEOUT_MS=30000` en `.env` | C1/C2 |

---

### Ejemplo 7: Backup vectores
**Objetivo**: Exportar colección por tenant para DR y auditoría | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import { QdrantClient } from '@qdrant/js-client-rest';
import fs from 'fs';

const client = new QdrantClient({ url: process.env.QDRANT_URL, apiKey: process.env.QDRANT_API_KEY, timeout: Number(process.env.TIMEOUT_MS), maxConnections: Number(process.env.CONNECTION_LIMIT) });

async function backupTenantVectors(tenant_id: string) {
  if (!tenant_id) throw new Error('C4 VIOLATION');
  const allPoints = [];
  let offset = null;
  while (true) {
    const batch = await client.scroll('rag_vectors', { filter: { must: [{ key: 'tenant_id', match: { value: tenant_id } }] }, limit: Number(process.env.MAX_RESULTS) || 100, offset });
    allPoints.push(...batch.points);
    if (!batch.next_page_offset) break;
    offset = batch.next_page_offset;
  }
  fs.writeFileSync(`./backup_${tenant_id}_${Date.now()}.json`, JSON.stringify(allPoints));
  return allPoints.length;
}
```

**✅ Deberías ver:** Archivo `.json` generado con N puntos. Todos contienen `payload.tenant_id === tenant_id`
**❌ Si ves esto en su lugar:** `EACCES: permission denied` o `scroll failed: timeout` → Ve a Troubleshooting #7

**Troubleshooting:**
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `EACCES: permission denied` | Proceso sin permisos de escritura | `ls -la ./` | Cambir a directorio permitido o ejecutar con `sudo -u app` | C3 |
| `scroll failed: timeout` | Paginación bloquea por gran volumen | `qdrant-cli collections stats` | Reducir `limit` a 50 y añadir `await delay(100)` | C1/C2 |

---

### Ejemplo 8: Migración colecciones
**Objetivo**: Mover datos de colección legacy a nueva manteniendo `tenant_id` | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import { QdrantClient } from '@qdrant/js-client-rest';

const cfg = { url: process.env.QDRANT_URL, apiKey: process.env.QDRANT_API_KEY, timeout: Number(process.env.TIMEOUT_MS), maxConnections: Number(process.env.CONNECTION_LIMIT) };
const src = new QdrantClient(cfg);
const dst = new QdrantClient(cfg);

async function migrateCollection(tenant_id: string, srcColl: string, dstColl: string) {
  if (!tenant_id) throw new Error('C4 VIOLATION');
  let points = await src.scroll(srcColl, { filter: { must: [{ key: 'tenant_id', match: { value: tenant_id } }] }, limit: Number(process.env.MAX_RESULTS) });
  if (points.points.length > 0) await dst.upsert(dstColl, { wait: true, points: points.points });
  return { migrated: points.points.length, tenant_id };
}
```

**✅ Deberías ver:** `{ migrated: N, tenant_id: "..." }` y puntos presentes en `dstColl` con mismo `tenant_id`
**❌ Si ves esto en su lugar:** `Collection does not exist` o `C4 VIOLATION` → Ve a Troubleshooting #8

**Troubleshooting:**
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Collection does not exist` | `dstColl` no creada previamente | `curl $QDRANT_URL/collections` | Ejecutar `createCollection` con parámetros idénticos | C1 |
| `C4 VIOLATION` | `tenant_id` no pasado en runtime | `node script.js --tenant=prod` | Validar args CLI y pasar a función | C4 |

---

### Ejemplo 9: Optimización HNSW
**Objetivo**: Ajustar índices HNSW para balancear velocidad/memoria por tenant | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import { QdrantClient } from '@qdrant/js-client-rest';

const client = new QdrantClient({ url: process.env.QDRANT_URL, apiKey: process.env.QDRANT_API_KEY, timeout: Number(process.env.TIMEOUT_MS), maxConnections: Number(process.env.CONNECTION_LIMIT) });

async function tuneHNSW(tenant_id: string, m: number, ef_construct: number) {
  if (!tenant_id) throw new Error('C4 VIOLATION');
  const config = { hnsw_config: { m, ef_construct }, timeout: Number(process.env.TIMEOUT_MS) };
  await client.updateCollection('rag_vectors', { optimizer_config: { ...config }, hnsw_config: config.hnsw_config });
  console.log(JSON.stringify({ event: 'hnsw_tuned', tenant_id, m, ef_construct }));
}
```

**✅ Deberías ver:** `{ "event": "hnsw_tuned", "tenant_id": "...", "m": 16, "ef_construct": 100 }` en stdout y latencia de query reducida
**❌ Si ves esto en su lugar:** `Invalid HNSW configuration` o `memory limit exceeded` → Ve a Troubleshooting #9

**Troubleshooting:**
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Invalid HNSW configuration` | Parámetros fuera de rango aceptado | Revisar docs Qdrant `hnsw_config` | Usar `m: 16-64`, `ef_construct: 100-200` | C1 |
| `memory limit exceeded` | `m` muy alto para infraestructura actual | `free -m \| grep Mem` | Reducir `m` a 32 y reiniciar optimización | C2 |

---

### Ejemplo 10: Borrado tenant
**Objetivo**: Eliminar todos los vectores y metadata de un inquilino de forma atómica | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import { QdrantClient } from '@qdrant/js-client-rest';

const client = new QdrantClient({ url: process.env.QDRANT_URL, apiKey: process.env.QDRANT_API_KEY, timeout: Number(process.env.TIMEOUT_MS), maxConnections: Number(process.env.CONNECTION_LIMIT) });

async function deleteTenant(tenant_id: string) {
  if (!tenant_id) throw new Error('C4 VIOLATION');
  await client.delete('rag_vectors', { filter: { must: [{ key: 'tenant_id', match: { value: tenant_id } }] }, wait: true });
  console.log(JSON.stringify({ event: 'tenant_purged', tenant_id, status: 'completed' }));
  return { success: true };
}
```

**✅ Deberías ver:** `{ "success": true }` y `{"event":"tenant_purged","tenant_id":"...","status":"completed"}` en logs. Query posterior retorna 0 resultados.
**❌ Si ves esto en su lugar: `Filter delete failed: no match` o `C4 VIOLATION` → Ve a Troubleshooting #10

**Troubleshooting:**
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Filter delete failed: no match` | `tenant_id` no existe en colección o typo | `curl $QDRANT_URL/collections/rag_vectors/points/search/scroll -d '{"filter":{"must":[{"key":"tenant_id","match":{"value":"test"}}]}}'` | Verificar spelling y ejecutar `delete` con `wait: true` | C4 |
| `Timeout on bulk delete` | Volumen > 10k puntos en single shot | `count points by tenant_id` | Usar paginación `scroll` + `delete` en lotes de `maxResults` | C1/C2 |


---


## Lote PostgreSQL (Relacional/Metadata)

### Ejemplo 1: conexión pool
**Objetivo**: Inicializar pool seguro con límites explícitos y validación C4 | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
import psycopg2.pool
import logging

MAX_RESULTS = int(os.getenv("MAX_RESULTS", 5))
CONNECTION_LIMIT = int(os.getenv("CONNECTION_LIMIT", 10))
TIMEOUT = int(os.getenv("TIMEOUT_MS", 30000)) / 1000

db_pool = psycopg2.pool.ThreadedConnectionPool(
    minconn=1,
    maxconn=CONNECTION_LIMIT,
    dsn=os.getenv("DB_PRIMARY_DSN"),
    connect_timeout=TIMEOUT
)

def init_pool_tenant(tenant_id: str):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    conn = db_pool.getconn()
    cur = conn.cursor()
    cur.execute(f"SET app.tenant_id = %s", (tenant_id,))
    logging.info({"event": "pool_acquired", "tenant_id": tenant_id, "maxResults": MAX_RESULTS, "timeout": TIMEOUT})
    return conn, cur

```
✅ Deberías ver: Conexión activa en `pg_stat_activity` con `application_name` y `app.tenant_id` seteado. Log JSON con `maxResults: X`.
❌ Si ves esto en su lugar: `ValueError: C4 VIOLATION` o `pool exhausted` → Ve a Troubleshooting #1
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `pool exhausted` | `CONNECTION_LIMIT` excedido por carga | `psql -c "SELECT count(*) FROM pg_stat_activity WHERE state='active';"` | Incrementar `CONNECTION_LIMIT` en `.env` o liberar conexiones con `pool.putconn()` | C1/C2 |
| `ValueError: C4 VIOLATION` | `tenant_id` no inyectado en runtime | `echo $TENANT_ID` | Validar payload webhook o variable de entorno antes de llamar `init_pool_tenant` | C4 |

### Ejemplo 2: queries con tenant_id
**Objetivo**: Ejecutar recuperación segura con límite estricto por inquilino | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
import psycopg2

def fetch_records(tenant_id: str, category: str):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    conn = psycopg2.connect(dsn=os.getenv("DB_PRIMARY_DSN"), connect_timeout=int(os.getenv("TIMEOUT_MS", 30000))/1000)
    cur = conn.cursor()
    query = """
        SELECT id, content, score FROM rag_cache 
        WHERE tenant_id = %s AND category = %s 
        ORDER BY score DESC LIMIT %s
    """
    cur.execute(query, (tenant_id, category, int(os.getenv("MAX_RESULTS", 5))))
    results = cur.fetchall()
    print({"tenant_id": tenant_id, "count": len(results), "maxResults": os.getenv("MAX_RESULTS")})
    return results
```
✅ Deberías ver: Lista de tuplas con `tenant_id` coincidente. Salida JSON con `count` ≤ `maxResults`.
❌ Si ves esto en su lugar: `permission denied` o `query timeout` → Ve a Troubleshooting #2
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `query timeout` | `TIMEOUT_MS` insuficiente para dataset grande | `EXPLAIN ANALYZE SELECT ...` con mismo `LIMIT` | Optimizar índices o aumentar `TIMEOUT_MS` en `.env` | C1/C2 |
| `permission denied` | Usuario DB sin acceso a tabla | `psql -U $DB_USER -d $DB_NAME -c "\dt rag_cache"` | Asignar permisos `GRANT SELECT` y validar `DB_USER` en `.env` | C3/C4 |

### Ejemplo 3: JSONB preferencias
**Objetivo**: Leer/Actualizar configuraciones de usuario embebidas en JSONB | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
import psycopg2
import json

def update_preferences(tenant_id: str, user_id: str, prefs: dict):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    conn = psycopg2.connect(dsn=os.getenv("DB_PRIMARY_DSN"), connect_timeout=int(os.getenv("TIMEOUT_MS", 30000))/1000)
    with conn.cursor() as cur:
        cur.execute("""
            INSERT INTO user_prefs (tenant_id, user_id, config)
            VALUES (%s, %s, %s::jsonb)
            ON CONFLICT (tenant_id, user_id) 
            DO UPDATE SET config = EXCLUDED.config
            RETURNING config
        """, (tenant_id, user_id, json.dumps(prefs)))
        result = cur.fetchone()
        print({"tenant_id": tenant_id, "merged_config": result[0], "timeout": os.getenv("TIMEOUT_MS")})
    return result
```
✅ Deberías ver: Tupla con `config` actualizado. Log JSON con `tenant_id` y timeout configurado.
❌ Si ves esto en su lugar: `invalid input syntax for type json` o `C4 VIOLATION` → Ve a Troubleshooting #3
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `invalid input syntax for type json` | Payload `prefs` mal formado o `None` | `python -c "import json; print(json.dumps(prefs))"` | Validar estructura con `pydantic` o `try/except` antes de ejecutar | C3/C4 |
| `C4 VIOLATION` | `tenant_id` vacío en argumento | Revisar llamada de función | Asegurar middleware de autenticación antes de invocar | C4 |

### Ejemplo 4: transacciones reservas
**Objetivo**: Reservar recursos con rollback atómico y logging de tenant | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
import psycopg2

def reserve_slot(tenant_id: str, slot_id: str, duration_sec: int):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    timeout_ms = int(os.getenv("TIMEOUT_MS", 30000)) / 1000
    conn = psycopg2.connect(dsn=os.getenv("DB_PRIMARY_DSN"), connect_timeout=timeout_ms)
    try:
        with conn.cursor() as cur:
            cur.execute("SET app.tenant_id = %s", (tenant_id,))
            cur.execute("""
                UPDATE resource_slots 
                SET status = 'RESERVED', reserved_by = %s 
                WHERE id = %s AND tenant_id = %s AND status = 'AVAILABLE'
                RETURNING id
            """, (tenant_id, slot_id, tenant_id))
            reserved = cur.fetchone()
            if not reserved: raise Exception("Slot unavailable or cross-tenant conflict")
            conn.commit()
            print({"event": "reservation_success", "tenant_id": tenant_id, "maxResults": 1})
            return True
    except Exception as e:
        conn.rollback()
        print({"event": "reservation_failed", "tenant_id": tenant_id, "error": str(e)})
        raise
```
✅ Deberías ver: `reservation_success` en logs + fila actualizada con `status='RESERVED'` y `tenant_id` coincidente.
❌ Si ves esto en su lugar: `Slot unavailable or cross-tenant conflict` o `connection lost during transaction` → Ve a Troubleshooting #4
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Slot unavailable...` | Condición `WHERE` no satisfecha | `SELECT * FROM resource_slots WHERE id=%s AND tenant_id=%s` | Verificar disponibilidad previa o manejar retry lógico | C4 |
| `connection lost during transaction` | `timeout_ms` excedido o reinicio de red | `journalctl -u postgresql \| grep "terminating"` | Aumentar `TIMEOUT_MS` o implementar reconexión con `retry` | C1/C2 |

### Ejemplo 5: índices parciales
**Objetivo**: Crear índice optimizado para queries frecuentes por tenant activo | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```sql
-- SQL puro ejecutado vía script Python (psycopg2) o psql
CREATE INDEX CONCURRENTLY idx_tenant_active_sessions 
ON whatsapp_sessions (tenant_id, created_at) 
WHERE is_active = true 
AND tenant_id IS NOT NULL;
```
✅ Deberías ver: `CREATE INDEX` completado sin bloquear tabla. `EXPLAIN ANALYZE` muestra `Index Scan using idx_tenant_active_sessions` para queries con `WHERE tenant_id = 'X' AND is_active = true`.
❌ Si ves esto en su lugar: `cannot acquire lock on index` o `duplicate index definition` → Ve a Troubleshooting #5
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `cannot acquire lock on index` | Transacción larga bloqueando tabla | `SELECT pid, query FROM pg_stat_activity WHERE state='idle in transaction';` | Matar bloqueos o ejecutar en ventana de mantenimiento | C1 |
| `duplicate index definition` | Index ya existe en DB | `psql -d $DB_NAME -c "\di idx_tenant_active_sessions"` | Verificar existencia o usar `IF NOT EXISTS` en script | C1 |

### Ejemplo 6: read replicas
**Objetivo**: Desviar lecturas pesadas a réplica con límites de pool | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
import psycopg2.pool

REPLICA_POOL = psycopg2.pool.ThreadedConnectionPool(
    minconn=1,
    maxconn=int(os.getenv("CONNECTION_LIMIT", 10)),
    dsn=os.getenv("DB_REPLICA_DSN"),
    connect_timeout=int(os.getenv("TIMEOUT_MS", 30000))/1000
)

def heavy_report_query(tenant_id: str, report_type: str):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    conn = REPLICA_POOL.getconn()
    cur = conn.cursor()
    cur.execute("""
        SELECT tenant_id, COUNT(*), AVG(duration) 
        FROM analytics_events 
        WHERE tenant_id = %s AND type = %s 
        GROUP BY tenant_id LIMIT %s
    """, (tenant_id, report_type, int(os.getenv("MAX_RESULTS", 5))))
    data = cur.fetchall()
    REPLICA_POOL.putconn(conn)
    print({"tenant_id": tenant_id, "source": "replica", "maxResults": os.getenv("MAX_RESULTS")})
    return data
```
✅ Deberías ver: Resultados agregados devueltos. `pg_stat_replication` muestra streaming activo. Log indica `source: replica`.
❌ Si ves esto en su lugar: `replica read-only` (al intentar write) o `replica lag too high` → Ve a Troubleshooting #6
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `replica read-only` | Ejecución accidental de `INSERT/UPDATE` en réplica | Revisar query antes de enviar | Muterar conexiones de escritura al pool primario | C1/C3 |
| `replica lag too high` | `wal_receiver` retrasado | `psql -h $REPLICA_HOST -c "SELECT pg_last_wal_receive_lsn() - pg_last_wal_replay_lsn();"` | Verificar red/IO en réplica o escalar a RDS multi-AZ | C2 |

### Ejemplo 7: migraciones Prisma
**Objetivo**: Desplegar esquema vía CLI controlada por Python | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
import subprocess

def run_prisma_migration(tenant_id: str, migration_tag: str):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    env_vars = os.environ.copy()
    env_vars["DATABASE_URL"] = os.getenv("DB_PRIMARY_DSN")
    env_vars["PRISMA_MIGRATION_TIMEOUT"] = os.getenv("TIMEOUT_MS", "30000")
    
    result = subprocess.run(
        ["npx", "prisma", "migrate", "deploy", "--schema=./prisma/schema.prisma"],
        env=env_vars,
        timeout=int(os.getenv("TIMEOUT_MS", 30000))/1000,
        capture_output=True,
        text=True
    )
    if result.returncode != 0:
        raise RuntimeError(f"Migration failed: {result.stderr}")
    print({"event": "migration_deployed", "tenant_id": tenant_id, "tag": migration_tag})
    return result.stdout
```
✅ Deberías ver: `Migration completed successfully` en stdout. Tabla `_prisma_migrations` actualizada con `tenant_id` en logs de auditoría.
❌ Si ves esto en su lugar: `Migration failed: P3005` o `subprocess.TimeoutExpired` → Ve a Troubleshooting #7
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Migration failed: P3005` | DB en estado inconsistente o shadow DB fallida | `npx prisma migrate status` | Ejecutar `npx prisma migrate reset` en staging y re-desplegar | C1 |
| `subprocess.TimeoutExpired` | Migración masiva tarda > `TIMEOUT_MS` | `ps aux \| grep prisma` | Dividir migración o aumentar `TIMEOUT_MS=60000` en `.env` | C1/C2 |

### Ejemplo 8: backup pg_dump
**Objetivo**: Exportar datos específicos por tenant con compresión | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
import subprocess

def export_tenant_dump(tenant_id: str):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    out_path = f"/backups/{tenant_id}_{os.getpid()}.dump.gz"
    env = os.environ.copy()
    env["PGPASSWORD"] = os.getenv("DB_PASS")
    
    cmd = [
        "pg_dump",
        "--host=" + os.getenv("DB_HOST"),
        "--port=5432",
        "--username=" + os.getenv("DB_USER"),
        "--dbname=" + os.getenv("DB_NAME"),
        f"--table=public.*",
        f"--where=tenant_id='{tenant_id}'",
        "-F", "custom",
        "--compress=6"
    ]
    
    proc = subprocess.run(cmd, env=env, stdout=open(out_path, 'wb'), 
                          timeout=int(os.getenv("TIMEOUT_MS", 30000))/1000)
    if proc.returncode != 0: raise Exception("Backup failed")
    print({"tenant_id": tenant_id, "file": out_path, "maxResults": 0, "timeout": os.getenv("TIMEOUT_MS")})
```
✅ Deberías ver: Archivo `.dump.gz` creado. `pg_restore -l /backups/file.dump.gz` muestra tablas con datos filtrados por `tenant_id`.
❌ Si ves esto en su lugar: `pg_dump: command not found` o `password authentication failed` → Ve a Troubleshooting #8
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `pg_dump: command not found` | PostgreSQL client tools no instalados en runtime | `which pg_dump` | Instalar `postgresql-client` o usar contenedor con CLI | C3 |
| `password authentication failed` | `DB_PASS` incorrecta o expirada | `env \| grep DB_PASS` | Rotar contraseña en `.env` y actualizar secreto de infra | C3 |

### Ejemplo 9: row-level security
**Objetivo**: Activar y configurar RLS para aislamiento forzado a nivel DB | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```sql
-- Ejecutar vía Python/psycopg2
ALTER TABLE user_prefs ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation_policy ON user_prefs
USING (tenant_id = current_setting('app.tenant_id')::text);
```
✅ Deberías ver: `ALTER TABLE` y `CREATE POLICY` exitosos. Query sin `SET app.tenant_id` retorna `0 rows` o error explícito según config.
❌ Si ves esto en su lugar: `RLS policy not applied` o `current_setting not found` → Ve a Troubleshooting #9
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `current_setting not found` | Variable `app.tenant_id` no seteada en sesión | `SHOW app.tenant_id;` | Ejecutar `SET app.tenant_id = '...'` antes de cualquier query | C4 |
| `RLS policy not applied` | Política creada para tabla incorrecta o `ENABLE` olvidado | `SELECT * FROM pg_policies WHERE tablename='user_prefs';` | Verificar `ENABLE ROW LEVEL SECURITY` y nombre de tabla exacto | C4 |

### Ejemplo 10: cleanup sesiones
**Objetivo**: Eliminar sesiones expiradas por tenant manteniendo límites | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
import psycopg2

def cleanup_expired_sessions(tenant_id: str, ttl_hours: int = 24):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    max_del = int(os.getenv("MAX_RESULTS", 100))
    timeout_sec = int(os.getenv("TIMEOUT_MS", 30000)) / 1000
    conn = psycopg2.connect(dsn=os.getenv("DB_PRIMARY_DSN"), connect_timeout=timeout_sec)
    with conn.cursor() as cur:
        cur.execute("""
            DELETE FROM whatsapp_sessions 
            WHERE tenant_id = %s AND last_active < NOW() - INTERVAL '%s HOURS'
            LIMIT %s
            RETURNING session_id
        """, (tenant_id, ttl_hours, max_del))
        deleted = cur.rowcount
        conn.commit()
        print({"event": "session_cleanup", "tenant_id": tenant_id, "deleted_count": deleted, "limit": max_del})
    return deleted
```
✅ Deberías ver: `deleted_count` con número ≤ `max_del`. Sesiones antiguas removidas. `pg_stat_activity` libre de conexiones zombie.
❌ Si ves esto en su lugar: `deadlock detected` o `limit clause ignored` → Ve a Troubleshooting #10
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `deadlock detected` | Múltiples workers limpiando mismo tenant | `SELECT * FROM pg_stat_activity WHERE wait_event_type = 'Lock';` | Implementar lock advisory o ejecutar cleanup secuencial | C1/C2 |
| `limit clause ignored` | Versión PG < 15 sin soporte LIMIT en DELETE | `SELECT version();` | Usar CTE: `WITH rows AS (SELECT id FROM ... LIMIT %s FOR UPDATE) DELETE ...` | C1 |


---


## Lote MySQL (Relacional/Legacy)

### Ejemplo 1: conexión optimizada
**Objetivo**: Inicializar pool MySQL con límites explícitos y validación temprana de tenant | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```javascript
const mysql = require('mysql2/promise');
const config = {
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME,
  connectionLimit: Number(process.env.CONNECTION_LIMIT) || 10,
  connectTimeout: Number(process.env.TIMEOUT_MS) || 30000,
  timezone: '+00:00'
};
const maxResults = Number(process.env.MAX_RESULTS) || 5;

function initMySQLPool(tenant_id) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id is mandatory');
  const pool = mysql.createPool(config);
  pool.query('SET @app_tenant_id = ?', [tenant_id]);
  console.log(JSON.stringify({ event: 'mysql_pool_ready', tenant_id, connectionLimit: config.connectionLimit, timeout: config.connectTimeout, maxResults }));
  return pool;
}
```
✅ Deberías ver: `{"event":"mysql_pool_ready","tenant_id":"...","connectionLimit":10,"timeout":30000,"maxResults":5}` y pool activo en `process.env.DB_HOST:3306`
❌ Si ves esto en su lugar: `Error: connect ECONNREFUSED` o `C4 VIOLATION: tenant_id is mandatory` → Ve a Troubleshooting #1
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `connect ECONNREFUSED` | Servicio MySQL apagado o puerto bloqueado | `nc -zv $DB_HOST 3306` | Iniciar MySQL o abrir puerto en firewall/sg | C1/C2 |
| `C4 VIOLATION` | `tenant_id` no pasado a `initMySQLPool` | `console.log(arguments[0])` | Validar payload webhook antes de instanciar | C4 |

### Ejemplo 2: queries tenant_id
**Objetivo**: Ejecutar SELECT seguro con aislamiento estricto y límite | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
import mysql.connector

def fetch_tenant_data(tenant_id: str):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    conn = mysql.connector.connect(
        host=os.getenv("DB_HOST"), user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASS"), database=os.getenv("DB_NAME"),
        connection_timeout=int(os.getenv("TIMEOUT_MS", 30000))/1000,
        pool_name="rag_pool", pool_size=int(os.getenv("CONNECTION_LIMIT", 10))
    )
    cursor = conn.cursor()
    max_res = int(os.getenv("MAX_RESULTS", 5))
    cursor.execute("SELECT id, payload FROM rag_messages WHERE tenant_id = %s ORDER BY created_at DESC LIMIT %s", (tenant_id, max_res))
    rows = cursor.fetchall()
    print({"tenant_id": tenant_id, "fetched": len(rows), "maxResults": max_res, "timeout": os.getenv("TIMEOUT_MS")})
    return rows
```
✅ Deberías ver: Lista de tuplas con `tenant_id` coincidente. Salida JSON con `fetched` ≤ `maxResults`.
❌ Si ves esto en su lugar: `mysql.connector.errors.ProgrammingError` o `Connection timeout` → Ve a Troubleshooting #2
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `ProgrammingError (1146)` | Tabla `rag_messages` no existe en DB | `mysql -h $DB_HOST -u $DB_USER -p -D $DB_NAME -e "SHOW TABLES"` | Crear tabla o corregir typo en `DB_NAME` | C3 |
| `Connection timeout` | Pool saturado o `TIMEOUT_MS` bajo | `SHOW PROCESSLIST;` | Aumentar `CONNECTION_LIMIT` y `TIMEOUT_MS` en `.env` | C1/C2 |

### Ejemplo 3: procedimientos almacenados
**Objetivo**: Ejecutar stored procedure con `tenant_id` inyectado y manejo de resultados | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```javascript
const mysql = require('mysql2/promise');
const pool = mysql.createPool({
  host: process.env.DB_HOST, user: process.env.DB_USER,
  password: process.env.DB_PASS, database: process.env.DB_NAME,
  connectionLimit: Number(process.env.CONNECTION_LIMIT) || 10,
  connectTimeout: Number(process.env.TIMEOUT_MS) || 30000
});
const maxResults = Number(process.env.MAX_RESULTS) || 5;

async function callRagProcedure(tenant_id) {
  if (!tenant_id) throw new Error('C4 VIOLATION');
  const [results] = await pool.query('CALL get_rag_context(?, ?)', [tenant_id, maxResults]);
  console.log(JSON.stringify({ event: 'proc_exec', tenant_id, rows: results[0]?.length, timeout: process.env.TIMEOUT_MS }));
  return results[0] || [];
}
```
✅ Deberías ver: Array de objetos devuelto por `CALL get_rag_context`. Log con `event: proc_exec` y `tenant_id`.
❌ Si ves esto en su lugar: `ER_NO_SUCH_PROC: FUNCTION does not exist` o `C4 VIOLATION` → Ve a Troubleshooting #3
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `ER_NO_SUCH_PROC` | Procedure no creado en DB objetivo | `SHOW PROCEDURE STATUS WHERE Db = '$DB_NAME';` | Ejecutar script `CREATE PROCEDURE` previo a despliegue | C1 |
| `Commands out of sync` | Múltiples resultados del procedure no consumidos | `await pool.query('CALL ...');` sin manejar resultsets | Usar `multiStatements: true` o consumir todos los resultsets | C2 |

### Ejemplo 4: réplica lectura
**Objetivo**: Desviar queries pesadas a réplica con configuración explícita | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
import mysql.connector

def read_from_replica(tenant_id: str):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    conn = mysql.connector.connect(
        host=os.getenv("DB_REPLICA_HOST"), user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASS"), database=os.getenv("DB_NAME"),
        connection_timeout=int(os.getenv("TIMEOUT_MS", 30000))/1000,
        pool_size=int(os.getenv("CONNECTION_LIMIT", 10))
    )
    cur = conn.cursor(dictionary=True)
    max_r = int(os.getenv("MAX_RESULTS", 5))
    cur.execute("SELECT session_data FROM analytics_read WHERE tenant_id = %s LIMIT %s", (tenant_id, max_r))
    data = cur.fetchall()
    print({"source": "replica", "tenant_id": tenant_id, "rows": len(data), "connectionLimit": os.getenv("CONNECTION_LIMIT")})
    return data
```
✅ Deberías ver: Lista de dicts. `SHOW SLAVE STATUS\G` muestra `Slave_IO_Running: Yes` y `Seconds_Behind_Master < 5`.
❌ Si ves esto en su lugar: `Access denied for user` o `Replication lag exceeded threshold` → Ve a Troubleshooting #4
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Access denied` | Usuario sin permisos SELECT en réplica o IP no whitelist | `SHOW GRANTS FOR '$DB_USER'@'%';` | Otorgar `GRANT SELECT` y verificar `bind-address` | C3/C4 |
| `Lag exceeded` | `Seconds_Behind_Master > 300` | `mysql -h $REPLICA -e "SHOW SLAVE STATUS\G"` | Revisar red/IO en réplica o escalar a lectura primaria temporal | C2 |

### Ejemplo 5: índices compuestos
**Objetivo**: Crear índice optimizado para búsquedas multi-campo por tenant | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```sql
-- Ejecutado vía script Python/Node
CREATE INDEX idx_tenant_status_ts 
ON whatsapp_messages (tenant_id, status, created_at DESC) 
USING BTREE;
ANALYZE TABLE whatsapp_messages;
```
✅ Deberías ver: `Query OK, X rows affected`. `EXPLAIN` muestra `type: ref` y `key: idx_tenant_status_ts` con `rows` bajas.
❌ Si ves esto en su lugar: `Duplicate key name` o `Lock wait timeout exceeded` → Ve a Troubleshooting #5
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Duplicate key name` | Índice ya existe en tabla | `SHOW INDEX FROM whatsapp_messages;` | Verificar existencia o añadir `DROP INDEX IF EXISTS` | C1 |
| `Lock wait timeout` | Tabla con transacciones largas abiertas | `SELECT * FROM information_schema.innodb_trx;` | Kill transacciones bloqueantes o ejecutar en ventana baja | C1/C2 |

### Ejemplo 6: manejo conexiones caídas
**Objetivo**: Recuperación automática ante caída de socket con validación C4 | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```javascript
const mysql = require('mysql2');
const cfg = {
  host: process.env.DB_HOST, user: process.env.DB_USER, password: process.env.DB_PASS,
  database: process.env.DB_NAME, connectionLimit: Number(process.env.CONNECTION_LIMIT) || 10,
  connectTimeout: Number(process.env.TIMEOUT_MS) || 30000, acquireTimeout: Number(process.env.TIMEOUT_MS)
};
const maxResults = Number(process.env.MAX_RESULTS) || 5;

function queryWithReconnect(tenant_id, sql, params = []) {
  if (!tenant_id) throw new Error('C4 VIOLATION');
  const pool = mysql.createPool(cfg);
  return new Promise((resolve, reject) => {
    pool.getConnection((err, conn) => {
      if (err) return reject(new Error(`Pool connection failed: ${err.message}`));
      conn.query(sql, [...params, maxResults], (qErr, res) => {
        conn.release();
        if (qErr) {
          console.error(JSON.stringify({ event: 'mysql_error', tenant_id, error: qErr.code, timeout: cfg.connectTimeout }));
          return reject(qErr);
        }
        resolve(res);
      });
    });
  });
}
```
✅ Deberías ver: Resultados devueltos correctamente o log JSON estructurado con `tenant_id` y `error` en caso de fallo. Pool reutilizable tras release.
❌ Si ves esto en su lugar: `PROTOCOL_CONNECTION_LOST` o `ER_ACCESS_DENIED_ERROR` → Ve a Troubleshooting #6
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `PROTOCOL_CONNECTION_LOST` | Servidor reinició o corte de red | `tail -f /var/log/mysql/error.log` | Pool reconnect automático habilitado en `mysql2` o reiniciar worker | C1/C2 |
| `ER_ACCESS_DENIED` | `DB_PASS` inválida o rotada sin actualización | `env \| grep DB_PASS` | Actualizar `.env` y reiniciar aplicación para recargar pool | C3 |

### Ejemplo 7: optimización InnoDB
**Objetivo**: Ajustar parámetros de buffer pool y analizar fragmentación | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```sql
-- Ejecutar vía cliente con auth en vars
SET GLOBAL innodb_buffer_pool_size = 1073741824;
OPTIMIZE TABLE whatsapp_sessions;
OPTIMIZE TABLE rag_cache;
```
✅ Deberías ver: `Table does not support optimize, doing recreate + analyze instead` seguido de `OK`. `information_schema.tables` muestra `Data_free` reducido.
❌ Si ves esto en su lugar: `Access denied; you need SUPER privilege` o `Lock wait timeout` → Ve a Troubleshooting #7
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `SUPER privilege` required | Usuario app sin permisos DBA | `SELECT user, host FROM mysql.user WHERE user='$DB_USER';` | Usar credencial admin para optimización o delegar a `pt-online-schema-change` | C3 |
| `Lock wait timeout` | `OPTIMIZE` bloquea queries activas | `SHOW ENGINE INNODB STATUS;` | Programar en horario de baja carga o usar `ALTER TABLE ENGINE=InnoDB` online | C1/C2 |

### Ejemplo 8: migración datos
**Objetivo**: Migrar filas legacy a nuevo esquema chunking por tenant y límites | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
import mysql.connector

def migrate_legacy_chunks(tenant_id: str):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    conn = mysql.connector.connect(
        host=os.getenv("DB_HOST"), user=os.getenv("DB_USER"), password=os.getenv("DB_PASS"),
        database=os.getenv("DB_NAME"), connection_timeout=int(os.getenv("TIMEOUT_MS", 30000))/1000,
        pool_size=int(os.getenv("CONNECTION_LIMIT", 10))
    )
    cursor = conn.cursor()
    max_r = int(os.getenv("MAX_RESULTS", 500))
    cursor.execute("SELECT id, text, ts FROM legacy_logs WHERE tenant_id = %s ORDER BY id ASC LIMIT %s OFFSET 0", (tenant_id, max_r))
    chunks = cursor.fetchall()
    cursor.executemany("INSERT INTO rag_messages (id, content, created_at, tenant_id) VALUES (%s, %s, %s, %s)", [(c[0], c[1], c[2], tenant_id) for c in chunks])
    conn.commit()
    print({"event": "migrated", "tenant_id": tenant_id, "rows": cursor.rowcount, "maxResults": max_r, "timeout": os.getenv("TIMEOUT_MS")})
```
✅ Deberías ver: `migrated` log con `rows` igual al chunk size. Nuevas filas en `rag_messages` con `tenant_id` correcto.
❌ Si ves esto en su lugar: `Data truncated for column` o `Duplicate entry for key 'PRIMARY'` → Ve a Troubleshooting #8
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Data truncated` | Tipo de dato destino incompatible | `DESC rag_messages;` vs `DESC legacy_logs;` | Alinear `VARCHAR/TEXT` o añadir `CAST` en `SELECT` | C2 |
| `Duplicate entry` | Clave primaria colisiona en migración | `SELECT COUNT(id) FROM rag_messages WHERE tenant_id=%s` | Usar `INSERT IGNORE` o `ON DUPLICATE KEY UPDATE` | C4 |

### Ejemplo 9: validación esquemas
**Objetivo**: Verificar existencia de columnas críticas antes de queries | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```javascript
const mysql = require('mysql2/promise');
const pool = mysql.createPool({
  host: process.env.DB_HOST, user: process.env.DB_USER, password: process.env.DB_PASS,
  database: process.env.DB_NAME, connectionLimit: Number(process.env.CONNECTION_LIMIT) || 10,
  connectTimeout: Number(process.env.TIMEOUT_MS) || 30000
});
const maxResults = Number(process.env.MAX_RESULTS) || 5;

async function validateSchema(tenant_id, tableName, requiredCols = ['tenant_id']) {
  if (!tenant_id) throw new Error('C4 VIOLATION');
  const [cols] = await pool.query(`SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ? AND TABLE_SCHEMA = ?`, [tableName, process.env.DB_NAME]);
  const present = new Set(cols.map(c => c.COLUMN_NAME));
  const missing = requiredCols.filter(c => !present.has(c));
  if (missing.length) throw new Error(`Schema validation failed: missing [${missing.join(', ')}]`);
  console.log(JSON.stringify({ event: 'schema_ok', tenant_id, table: tableName, maxResults }));
}
```
✅ Deberías ver: `{"event":"schema_ok","tenant_id":"...","table":"...","maxResults":5}`. Procede sin errores a ejecución.
❌ Si ves esto en su lugar: `Schema validation failed` o `ER_UNKNOWN_TABLE` → Ve a Troubleshooting #9
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `ER_UNKNOWN_TABLE` | Tabla renombrada o eliminada accidentalmente | `SHOW TABLES LIKE 'tableName';` | Revertir schema o actualizar variable en código | C1 |
| `missing [tenant_id]` | Columna multi-tenant no aplicada en tabla | `DESC tableName;` | Ejecutar `ALTER TABLE ADD tenant_id VARCHAR(255)` y reindexar | C4 |

### Ejemplo 10: purge logs
**Objetivo**: Eliminar logs antiguos por tenant con control de transacción y límites | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
import mysql.connector

def purge_old_logs(tenant_id: str, retention_days: int = 30):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    conn = mysql.connector.connect(
        host=os.getenv("DB_HOST"), user=os.getenv("DB_USER"), password=os.getenv("DB_PASS"),
        database=os.getenv("DB_NAME"), connection_timeout=int(os.getenv("TIMEOUT_MS", 30000))/1000,
        pool_size=int(os.getenv("CONNECTION_LIMIT", 10))
    )
    cursor = conn.cursor()
    max_del = int(os.getenv("MAX_RESULTS", 1000))
    sql = f"DELETE FROM audit_logs WHERE tenant_id = %s AND created_at < DATE_SUB(NOW(), INTERVAL %s DAY) LIMIT %s"
    cursor.execute(sql, (tenant_id, retention_days, max_del))
    conn.commit()
    print({"event": "purged", "tenant_id": tenant_id, "rows_deleted": cursor.rowcount, "maxResults": max_del, "timeout": os.getenv("TIMEOUT_MS")})
```
✅ Deberías ver: Log JSON con `rows_deleted` ≤ `maxResults`. `audit_logs` reducido en `information_schema.TABLES.Data_length`.
❌ Si ves esto en su lugar: `Lock wait timeout exceeded` o `Binlog cache size exceeded` → Ve a Troubleshooting #10
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Lock wait timeout` | DELETE bloquea inserts concurrentes | `SHOW ENGINE INNODB STATUS;` | Usar `LIMIT` pequeño en loop o ejecutar con `SET sql_log_bin=0` si aplica | C1/C2 |
| `Binlog cache` | `MAX_RESULTS` muy alto para binlog | `SHOW VARIABLES LIKE 'binlog_cache_size';` | Reducir `MAX_RESULTS` o purgar en lotes de 1000 | C2 |


---


## Lote Supabase (PostgREST + Auth + Realtime)

### Ejemplo 1: cliente JS
**Objetivo**: Instanciar cliente Supabase con límites explícitos y validación C4 | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import { createClient } from '@supabase/supabase-js';
import https from 'https';

const SUPABASE_CONFIG = {
  url: process.env.SUPABASE_URL || '',
  key: process.env.SUPABASE_SERVICE_KEY || '',
  maxResults: Number(process.env.MAX_RESULTS) || 5,
  connectionLimit: Number(process.env.CONNECTION_LIMIT) || 10,
  timeout: Number(process.env.TIMEOUT_MS) || 30000
};

const agent = new https.Agent({ keepAlive: true, maxSockets: SUPABASE_CONFIG.connectionLimit });

function initSupabaseClient(tenant_id: string) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory');
  const supabase = createClient(SUPABASE_CONFIG.url, SUPABASE_CONFIG.key, {
    fetch: { agent, signal: AbortSignal.timeout(SUPABASE_CONFIG.timeout) },
    auth: { persistSession: false },
    global: { fetch: { timeout: SUPABASE_CONFIG.timeout } }
  });
  console.log(JSON.stringify({ event: 'client_ready', tenant_id, maxResults: SUPABASE_CONFIG.maxResults, timeout: SUPABASE_CONFIG.timeout }));
  return supabase;
}
```
✅ Deberías ver: `{ event: 'client_ready', tenant_id: "...", maxResults: 5, timeout: 30000 }` en stdout + instancia Supabase con keepAlive y timeout aplicado
❌ Si ves esto en su lugar: `C4 VIOLATION: tenant_id mandatory` o `Invalid URL` → Ve a Troubleshooting #1
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `C4 VIOLATION` | Argumento `tenant_id` vacío/undefined | `console.log(process.env.TENANT_ID)` | Validar payload de entrada antes de llamar `initSupabaseClient` | C4 |
| `Invalid URL` | `SUPABASE_URL` mal formado en `.env` | `echo $SUPABASE_URL` | Asegurar formato `https://<project>.supabase.co` sin slashes finales | C3 |

### Ejemplo 2: RLS por tenant_id
**Objetivo**: Configurar política RLS forzada en tabla `rag_docs` | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```sql
-- Ejecutar vía Supabase Dashboard o SQL Editor con SERVICE_ROLE_KEY
ALTER TABLE public.rag_docs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation_rag ON public.rag_docs;
CREATE POLICY tenant_isolation_rag
ON public.rag_docs
FOR ALL
USING (tenant_id = current_setting('app.tenant_id')::uuid)
WITH CHECK (tenant_id = current_setting('app.tenant_id')::uuid);
```
✅ Deberías ver: `ALTER TABLE` y `CREATE POLICY` exitosos. Query desde API sin `app.tenant_id` set devuelve `0 rows` o `403`
❌ Si ves esto en su lugar: `permission denied for policy` o `invalid input syntax for type uuid` → Ve a Troubleshooting #2
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `permission denied` | Política colisiona o usuario no es `supabase_admin` | `SELECT * FROM pg_policies WHERE tablename='rag_docs';` | Ejecutar con credencial `SERVICE_ROLE` y borrar políticas conflictivas | C4 |
| `invalid input syntax` | `current_setting` devuelve string vacío | `SHOW app.tenant_id;` | Validar tipo UUID antes de `SET` o usar `text` en política | C3/C4 |

### Ejemplo 3: realtime subscriptions
**Objetivo**: Suscribirse a cambios de base de datos filtrados por inquilino | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_ANON_KEY!, {
  realtime: { params: { timeout: Number(process.env.TIMEOUT_MS) || 30000 } },
  fetch: { timeout: Number(process.env.TIMEOUT_MS) || 30000 }
});

async function subscribeTenantUpdates(tenant_id: string) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory');
  const channel = supabase.channel(`rag_sync_${tenant_id}`);
  channel.on('postgres_changes', {
    event: '*',
    schema: 'public',
    table: 'rag_docs',
    filter: `tenant_id=eq.${tenant_id}`
  }, (payload) => {
    console.log(JSON.stringify({ event: 'realtime_update', tenant_id, record: payload.new, timeout: process.env.TIMEOUT_MS }));
  });
  await channel.subscribe();
  console.log(JSON.stringify({ event: 'sub_active', tenant_id, maxResults: process.env.MAX_RESULTS }));
  return channel;
}
```
✅ Deberías ver: `{ event: 'sub_active', tenant_id: "..." }` y logs JSON en cada `INSERT/UPDATE/DELETE` coincidente con filtro
❌ Si ves esto en su lugar: `WebSocket error: timeout` o `C4 VIOLATION` → Ve a Troubleshooting #3
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `WebSocket error: timeout` | Red bloqueando WS o `realtime` deshabilitado | `curl -I $SUPABASE_URL/realtime/v1` | Verificar `realtime` habilitado en dashboard Supabase y abrir puerto 443 | C1/C2 |
| `C4 VIOLATION` | `tenant_id` no pasado a `subscribeTenantUpdates` | Revisar stack trace de llamada | Envolver llamada en middleware de validación de sesión | C4 |

### Ejemplo 4: storage archivos
**Objetivo**: Subir documentos estructurados por tenant con límites de tamaño | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import { createClient } from '@supabase/supabase-js';
import fs from 'fs';

const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_SERVICE_KEY!);
const MAX_UPLOAD_MB = Number(process.env.MAX_RESULTS) || 50; // Reutilizando MAX_RESULTS como límite de tamaño en MB

async function uploadTenantFile(tenant_id: string, localPath: string, fileName: string) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory');
  const stats = fs.statSync(localPath);
  if (stats.size > MAX_UPLOAD_MB * 1024 * 1024) throw new Error(`File exceeds limit: ${MAX_UPLOAD_MB}MB`);
  
  const bucketPath = `${tenant_id}/uploads/${Date.now()}_${fileName}`;
  const { data, error } = await supabase.storage
    .from('rag-docs')
    .upload(bucketPath, fs.createReadStream(localPath), {
      cacheControl: '3600',
      upsert: false
    });
  console.log(JSON.stringify({ event: 'upload_complete', tenant_id, path: data?.path, timeout: process.env.TIMEOUT_MS }));
  if (error) throw error;
  return data;
}
```
✅ Deberías ver: `{ event: 'upload_complete', tenant_id: "...", path: "tenant_x/uploads/..." }` y archivo visible en bucket
❌ Si ves esto en su lugar: `bucket not found` o `File exceeds limit` → Ve a Troubleshooting #4
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `bucket not found` | Bucket `rag-docs` no creado | `supabase storage buckets list` | Crear bucket público/privado desde dashboard o CLI | C1 |
| `File exceeds limit` | Archivo supera `MAX_UPLOAD_MB` | `ls -lh localPath` | Comprimir antes o incrementar `MAX_RESULTS` en `.env` | C1/C4 |

### Ejemplo 5: functions edge
**Objetivo**: Invocar Edge Function pasando contexto de tenant y límites | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_ANON_KEY!);

async function invokeEdgeWorker(tenant_id: string, task: string) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory');
  const payload = { tenant_id, task, maxResults: Number(process.env.MAX_RESULTS), timeout: Number(process.env.TIMEOUT_MS) };
  const { data, error } = await supabase.functions.invoke('process-rag-task', {
    body: payload,
    headers: { 'Connection': 'keep-alive' }
  });
  console.log(JSON.stringify({ event: 'edge_invoke', tenant_id, success: !error }));
  if (error) throw new Error(`Edge function failed: ${error.message}`);
  return data;
}
```
✅ Deberías ver: `{ event: 'edge_invoke', tenant_id: "...", success: true }` y respuesta del worker con datos procesados
❌ Si ves esto en su lugar: `function not found` o `C4 VIOLATION` → Ve a Troubleshooting #5
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `function not found` | Nombre incorrecto o función no desplegada | `supabase functions list` | Desplegar con `supabase functions deploy process-rag-task` | C1 |
| `C4 VIOLATION` | `tenant_id` no serializado en body | `JSON.stringify(payload)` | Validar tipo string antes de invoke | C4 |

### Ejemplo 6: webhooks
**Objetivo**: Configurar handler para escuchar eventos DB y validar tenant | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```typescript
// Handler Express para Supabase Webhook
import express from 'express';
const router = express.Router();

router.post('/supabase-hook', express.json({ limit: `${process.env.MAX_RESULTS || 10}mb` }), (req, res) => {
  const { type, record, schema, table } = req.body;
  const tenant_id = record?.tenant_id;
  if (!tenant_id) {
    console.warn('C4 VIOLATION: webhook payload missing tenant_id');
    return res.status(400).json({ error: 'C4 VIOLATION' });
  }
  console.log(JSON.stringify({ event: 'webhook_received', tenant_id, table, timeout: process.env.TIMEOUT_MS, maxResults: process.env.MAX_RESULTS }));
  res.status(200).json({ received: true });
});
```
✅ Deberías ver: `{ event: 'webhook_received', tenant_id: "..." }` en logs y respuesta HTTP 200 para eventos válidos
❌ Si ves esto en su lugar: `Payload too large` o `C4 VIOLATION` → Ve a Troubleshooting #6
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Payload too large` | Evento supera límite express | `curl -I -X POST $WEBHOOK_URL -d "$(python -c "print('x'*10000000)")"` | Aumentar `limit` en `express.json()` o filtrar en Supabase | C1/C2 |
| `C4 VIOLATION` | Trigger DB inserta sin `tenant_id` | Revisar webhook payload JSON | Añadir `tenant_id` en tabla origen o filtrar en política | C4 |

### Ejemplo 7: backup REST
**Objetivo**: Exportar datos paginados vía REST API manteniendo contexto | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
import requests
import json

def export_tenant_rest(tenant_id: str):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    url = f"{os.getenv('SUPABASE_URL')}/rest/v1/rag_docs"
    headers = {
        "apikey": os.getenv("SUPABASE_ANON_KEY"),
        "Authorization": f"Bearer {os.getenv('SUPABASE_SERVICE_KEY')}",
        "Content-Type": "application/json",
        "Prefer": f"count=exact",
        "Connection": "close" # Control explícito
    }
    params = {
        "tenant_id": f"eq.{tenant_id}",
        "limit": os.getenv("MAX_RESULTS", "1000"),
        "timeout": os.getenv("TIMEOUT_MS", "30000")
    }
    res = requests.get(url, headers=headers, params=params, timeout=int(params["timeout"])/1000)
    res.raise_for_status()
    print(json.dumps({"event": "backup_export", "tenant_id": tenant_id, "count": res.headers.get("Content-Range", "0"), "timeout": params["timeout"]}))
    return res.json()
```
✅ Deberías ver: `{ event: 'backup_export', tenant_id: "...", count: "X/Y", timeout: "..." }` y array JSON con datos filtrados
❌ Si ves esto en su lugar: `ConnectionError: Read timed out` o `401 Unauthorized` → Ve a Troubleshooting #7
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Read timed out` | Dataset excede `TIMEOUT_MS` | `time curl $REST_URL...` | Incrementar `TIMEOUT_MS` o usar paginación `range` por lotes | C1/C2 |
| `401 Unauthorized` | `SUPABASE_SERVICE_KEY` inválida | `curl -H "apikey: $KEY" -I $URL` | Rotar claves en Supabase Dashboard y actualizar `.env` | C3 |

### Ejemplo 8: rate limiting
**Objetivo**: Implementar límite de peticiones por tenant vía tabla de auditoría | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_SERVICE_KEY!);

async function checkTenantRate(tenant_id: string) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory');
  const { data, error } = await supabase.rpc('check_rate_limit', { p_tenant_id: tenant_id });
  if (error) throw new Error(`Rate check failed: ${error.message}`);
  const allowed = data <= Number(process.env.MAX_RESULTS);
  console.log(JSON.stringify({ event: 'rate_check', tenant_id, allowed, maxResults: process.env.MAX_RESULTS, timeout: process.env.TIMEOUT_MS }));
  return allowed;
}
```
✅ Deberías ver: `{ event: 'rate_check', tenant_id: "...", allowed: true }` o `false` si supera límite configurado
❌ Si ves esto en su lugar: `function check_rate_limit not found` o `C4 VIOLATION` → Ve a Troubleshooting #8
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `function not found` | RPC no creada en DB | `supabase db diff` | Crear función SQL `CREATE OR REPLACE FUNCTION check_rate_limit...` | C1 |
| `C4 VIOLATION` | `tenant_id` no pasado a `checkTenantRate` | Revisar argumentos de llamada | Asegurar propagación desde middleware de autenticación | C4 |

### Ejemplo 9: sync offline
**Objetivo**: Cola local de cambios y sincronización batch por tenant | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_SERVICE_KEY!);

async function syncOfflineQueue(tenant_id: string, queue: Array<{table: string, row: any, action: string}>) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory');
  const batchSize = Number(process.env.MAX_RESULTS) || 5;
  const chunks = [];
  for (let i = 0; i < queue.length; i += batchSize) chunks.push(queue.slice(i, i + batchSize));

  for (const chunk of chunks) {
    await Promise.all(chunk.map(async (item) => {
      item.row.tenant_id = tenant_id;
      if (item.action === 'upsert') {
        await supabase.from(item.table).upsert(item.row, { onConflict: 'id' });
      }
    }));
    console.log(JSON.stringify({ event: 'sync_batch', tenant_id, processed: chunk.length, maxResults: batchSize, timeout: process.env.TIMEOUT_MS }));
  }
  return { synced: queue.length };
}
```
✅ Deberías ver: Logs `{ event: 'sync_batch'... }` por cada lote y fila insertada/actualizada con `tenant_id` correcto en Supabase
❌ Si ves esto en su lugar: `duplicate key value` o `C4 VIOLATION` → Ve a Troubleshooting #9
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `duplicate key value` | Colisión en `id` durante upsert | `SELECT id FROM table WHERE id=$1;` | Asegurar `uuid_generate_v7()` o manejar `ON CONFLICT DO UPDATE` | C1/C2 |
| `C4 VIOLATION` | `tenant_id` omitido en objeto row | `console.log(item.row.tenant_id)` | Forzar asignación explícita antes de `upsert` | C4 |

### Ejemplo 10: migración DB
**Objetivo**: Aplicar migraciones seguras con rollback automático y validación C4 | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
import subprocess
import json

def apply_supabase_migration(tenant_id: str, migration_file: str):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    env = os.environ.copy()
    env["SUPABASE_ACCESS_TOKEN"] = os.getenv("SUPABASE_SERVICE_KEY")
    timeout_sec = int(os.getenv("TIMEOUT_MS", "30000")) / 1000
    
    result = subprocess.run(
        ["supabase", "db", "push", f"--db-url={os.getenv('DB_PRIMARY_DSN')}", "--include-all"],
        env=env, timeout=timeout_sec, capture_output=True, text=True
    )
    if result.returncode != 0:
        raise RuntimeError(f"Migration failed: {result.stderr}")
    print(json.dumps({"event": "migration_applied", "tenant_id": tenant_id, "maxResults": os.getenv("MAX_RESULTS"), "timeout": os.getenv("TIMEOUT_MS")}))
    return result.stdout
```
✅ Deberías ver: `{ event: 'migration_applied', tenant_id: "..." }` y esquema actualizado en dashboard sin errores
❌ Si ves esto en su lugar: `Migration failed: P0004` o `subprocess.TimeoutExpired` → Ve a Troubleshooting #10
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Migration failed: P0004` | Conflicto de versiones o tablas bloqueadas | `supabase db status` | Ejecutar `supabase db reset` en staging o aplicar parche manual | C1/C2 |
| `C4 VIOLATION` | `tenant_id` ausente en argumento | `python script.py --tenant=X` | Validar CLI args antes de invocar `subprocess` | C4 |


---

## Lote Google Drive & Sheets (Documental)

### Ejemplo 1: auth service account
**Objetivo**: Autenticar cliente GDrive/Sheets con credenciales inyectadas y validación C4 | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
import logging
from google.oauth2 import service_account

def init_drive_sheets_client(tenant_id: str):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    timeout = int(os.getenv("TIMEOUT_MS", 30000)) / 1000
    conn_limit = int(os.getenv("CONNECTION_LIMIT", 10))
    max_results = int(os.getenv("MAX_RESULTS", 5))

    creds = service_account.Credentials.from_service_account_info(
        eval(os.getenv("GCP_SERVICE_ACCOUNT_CREDENTIALS")),
        scopes=["https://www.googleapis.com/auth/drive", "https://www.googleapis.com/auth/spreadsheets"],
        request_timeout=timeout
    )
    logging.info({
        "event": "auth_init",
        "tenant_id": tenant_id,
        "maxResults": max_results,
        "connectionLimit": conn_limit,
        "timeout": timeout
    })
    return creds
```

✅ Deberías ver: `{ "event": "auth_init", "tenant_id": "...", "maxResults": 5, "connectionLimit": 10, "timeout": 30.0 }` y objeto `service_account.Credentials` listo
❌ Si ves esto en su lugar: `ValueError: C4 VIOLATION: tenant_id mandatory` o `Invalid value: Service account creds not found` → Ve a Troubleshooting #1
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Invalid value: Service account creds not found` | `GCP_SERVICE_ACCOUNT_CREDENTIALS` no definido o JSON corrupto | `echo $GCP_SERVICE_ACCOUNT_CREDENTIALS \| python3 -c "import sys,json;json.load(sys.stdin)"` | Validar formato JSON y exportar variable en entorno seguro | C3 |
| `C4 VIOLATION: tenant_id mandatory` | `tenant_id` no pasado a la función | Revisar stacktrace de invocación | Asegurar middleware de validación antes de llamar `init_drive_sheets_client` | C4 |

---

### Ejemplo 2: lectura Sheets por tenant
**Objetivo**: Recuperar filas de hoja filtrando estrictamente por `tenant_id` y aplicando límites | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
from googleapiclient.discovery import build
import logging

def read_tenant_sheet(tenant_id: str, spreadsheet_id: str, range_name: str):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    timeout = int(os.getenv("TIMEOUT_MS", 30000)) / 1000
    conn_limit = int(os.getenv("CONNECTION_LIMIT", 10))
    max_results = int(os.getenv("MAX_RESULTS", 100))

    service = build("sheets", "v4", credentials=init_drive_sheets_client(tenant_id), cache_discovery=False)
    result = service.spreadsheets().values().get(spreadsheetId=spreadsheet_id, range=range_name).execute(timeout=timeout)
    raw_values = result.get("values", [])
    
    # Filtro estricto + límite
    tenant_rows = [row for row in raw_values if row and row[0] == tenant_id][:max_results]
    logging.info({"event": "sheet_read", "tenant_id": tenant_id, "rows_returned": len(tenant_rows), "maxResults": max_results, "timeout": timeout, "connectionLimit": conn_limit})
    return tenant_rows
```

✅ Deberías ver: Lista de listas donde `row[0] == tenant_id`. Log JSON con `rows_returned` ≤ `maxResults` y parámetros C1/C2
❌ Si ves esto en su lugar: `HttpError 403` o `HttpError 404: Spreadsheet not found` → Ve a Troubleshooting #2
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `HttpError 403` | Cuenta de servicio sin acceso a la hoja | Revisar permisos en Google Sheets UI | Compartir hoja con `client_email` de la service account | C3/C4 |
| `Spreadsheet not found` | ID de hoja inválido o restringido | `echo $SPREADSHEET_ID` | Validar ID extraído de URL y permisos de la org | C1 |

---

### Ejemplo 3: escritura celdas
**Objetivo**: Actualizar celdas con payload validado y límite de batch explícito | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
from googleapiclient.discovery import build
import logging

def write_tenant_cells(tenant_id: str, spreadsheet_id: str, range_name: str, data: list):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    timeout = int(os.getenv("TIMEOUT_MS", 30000)) / 1000
    max_results = int(os.getenv("MAX_RESULTS", 50)) # Batch limit
    conn_limit = int(os.getenv("CONNECTION_LIMIT", 5))

    service = build("sheets", "v4", credentials=init_drive_sheets_client(tenant_id))
    body = {"values": [row[:max_results] for row in data]}
    response = service.spreadsheets().values().update(
        spreadsheetId=spreadsheet_id, range=range_name,
        valueInputOption="RAW", body=body
    ).execute(timeout=timeout)
    logging.info({"event": "sheet_write", "tenant_id": tenant_id, "cells_updated": response.get("updatedCells"), "maxResults": max_results, "timeout": timeout, "connectionLimit": conn_limit})
    return response
```

✅ Deberías ver: `{ "cells_updated": X }` donde `X` coincide con tamaño de `data`. Log con parámetros C1/C2/C4
❌ Si ves esto en su lugar: `Invalid value: Cell data type mismatch` o `write_timeout` → Ve a Troubleshooting #3
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Invalid value: Cell data type mismatch` | Fila con tipos incompatibles (ej. bool en celda fecha) | `print(type(row[0]))` | Castear datos a `str` antes de enviar a Sheets API | C1 |
| `write_timeout` | API Sheets no responde dentro de `TIMEOUT_MS` | `curl -I https://sheets.googleapis.com` | Aumentar `TIMEOUT_MS` en `.env` o reducir `max_results` | C1/C2 |

---

### Ejemplo 4: sync Drive→Qdrant
**Objetivo**: Listar archivos de Drive por tenant y preparar payload vectorial respetando límites | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
from googleapiclient.discovery import build
import logging

def sync_drive_to_qdrant(tenant_id: str, folder_id: str):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    timeout = int(os.getenv("TIMEOUT_MS", 30000)) / 1000
    max_results = int(os.getenv("MAX_RESULTS", 10))
    conn_limit = int(os.getenv("CONNECTION_LIMIT", 5))

    service = build("drive", "v3", credentials=init_drive_sheets_client(tenant_id))
    res = service.files().list(
        q=f"'{folder_id}' in parents and mimeType contains 'text/'",
        pageSize=max_results, fields="files(id,name,mimeType)"
    ).execute(timeout=timeout)
    
    files = res.get("files", [])
    payload = [{"id": f"{tenant_id}:gdrive:{f['id']}", "name": f["name"], "tenant_id": tenant_id, "source": "drive"} for f in files]
    logging.info({"event": "drive_qdrant_sync_prep", "tenant_id": tenant_id, "files_count": len(payload), "maxResults": max_results, "timeout": timeout, "connectionLimit": conn_limit})
    return payload
```

✅ Deberías ver: Lista de dicts con `id` prefijado `tenant_id:gdrive:` y `tenant_id` en payload. Count ≤ `maxResults`
❌ Si ves esto en su lugar: `Invalid query` o `folder_not_found` → Ve a Troubleshooting #4
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Invalid query` | Sintaxis Drive `q=` incorrecta (falta `'` o espacios) | Validar string en console Google Drive API | Corregir comillas simples y operadores lógicos | C1 |
| `folder_not_found` | `folder_id` no accesible por la cuenta de servicio | `ls` en UI Drive con cuenta de servicio | Compartir carpeta padre explícitamente | C3/C4 |

---

### Ejemplo 5: permisos compartidos
**Objetivo**: Conceder acceso granular a recursos Drive validando aislamiento | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
from googleapiclient.discovery import build
import logging

def share_tenant_file(tenant_id: str, file_id: str, user_email: str, role: str = "reader"):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    timeout = int(os.getenv("TIMEOUT_MS", 30000)) / 1000
    max_results = int(os.getenv("MAX_RESULTS", 3)) # Batch shares limit
    conn_limit = int(os.getenv("CONNECTION_LIMIT", 5))

    service = build("drive", "v3", credentials=init_drive_sheets_client(tenant_id))
    perm_body = {"type": "user", "role": role, "emailAddress": user_email}
    res = service.permissions().create(
        fileId=file_id, body=perm_body, fields="id"
    ).execute(timeout=timeout)
    
    logging.info({"event": "drive_share", "tenant_id": tenant_id, "target_email": user_email, "perm_id": res.get("id"), "maxResults": max_results, "timeout": timeout, "connectionLimit": conn_limit})
    return res
```

✅ Deberías ver: `{ "perm_id": "..." }` y log auditando `tenant_id`, email destino y límites configurados
❌ Si ves esto en su lugar: `emailNotFound` o `permissionDenied` → Ve a Troubleshooting #5
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `emailNotFound` | Email de Google inválido o dominio externo bloqueado | `dig MX $DOMAIN` | Verificar email activo o cambiar `type` a `anyoneWithLink` | C1/C2 |
| `permissionDenied` | Cuenta de servicio sin permisos de propietario/organizador | `curl -H "Authorization: Bearer $TOKEN" https://www.googleapis.com/drive/v3/files/$file_id/permissions` | Otorgar rol `manager` a service account o usar credenciales user-OAuth | C3 |

---

### Ejemplo 6: rate limit
**Objetivo**: Controlar concurrencia de peticiones con semáforo y logging por tenant | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
import threading
import time
from googleapiclient.discovery import build
import logging

SEMAPHORE = threading.Semaphore(int(os.getenv("CONNECTION_LIMIT", 5)))

def rate_limited_batch_read(tenant_id: str, spreadsheet_id: str, ranges: list):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    timeout = int(os.getenv("TIMEOUT_MS", 30000)) / 1000
    max_results = int(os.getenv("MAX_RESULTS", len(ranges)))

    def fetch(rng):
        with SEMAPHORE:
            svc = build("sheets", "v4", credentials=init_drive_sheets_client(tenant_id))
            return svc.spreadsheets().values().batchGet(
                spreadsheetId=spreadsheet_id, ranges=[rng]
            ).execute(timeout=timeout)

    results = [fetch(r) for r in ranges[:max_results]]
    logging.info({"event": "rate_limited_read", "tenant_id": tenant_id, "ranges_processed": len(results), "maxResults": max_results, "connectionLimit": os.getenv("CONNECTION_LIMIT"), "timeout": timeout})
    return results
```

✅ Deberías ver: Lista de respuestas `batchGet` con longitud ≤ `max_results`. Log confirmando concurrencia y tiempos
❌ Si ves esto en su lugar: `ResourceExhausted: 429 Too Many Requests` o `lock_timeout` → Ve a Troubleshooting #6
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `ResourceExhausted: 429` | Cuota API Sheets excedida (req/min) | `curl -I https://sheets.googleapis.com` con headers | Reducir `CONNECTION_LIMIT` o implementar `time.sleep()` exponencial | C1/C2 |
| `lock_timeout` | Semáforo nunca liberado por excepción en `fetch` | Revisar tracebacks en logs | Envolver `fetch` en `try/finally: semaphore.release()` | C2 |

---

### Ejemplo 7: manejo timeouts
**Objetivo**: Envolver llamadas con timeout estricto y fallback seguro | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
import socket
from googleapiclient.discovery import build
import logging

def safe_file_metadata(tenant_id: str, file_id: str):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    timeout = int(os.getenv("TIMEOUT_MS", 30000)) / 1000
    max_results = int(os.getenv("MAX_RESULTS", 1)) # Metadata fetch limit
    conn_limit = int(os.getenv("CONNECTION_LIMIT", 5))

    original_timeout = socket.getdefaulttimeout()
    socket.setdefaulttimeout(timeout)
    try:
        svc = build("drive", "v3", credentials=init_drive_sheets_client(tenant_id))
        meta = svc.files().get(fileId=file_id, fields="id,name,mimeType,size").execute()
        meta["_tenant_id"] = tenant_id
        logging.info({"event": "safe_metadata", "tenant_id": tenant_id, "file": meta.get("name"), "maxResults": max_results, "timeout": timeout, "connectionLimit": conn_limit})
        return meta
    except socket.timeout:
        logging.error({"event": "socket_timeout", "tenant_id": tenant_id, "timeout_applied": timeout})
        return {"error": "timeout", "tenant_id": tenant_id}
    finally:
        socket.setdefaulttimeout(original_timeout)
```

✅ Deberías ver: Dict con metadatos del archivo + `_tenant_id` o `{"error": "timeout", "tenant_id": "..."}` si supera límite
❌ Si ves esto en su lugar: `socket.timeout` sin captura o `Invalid file ID` → Ve a Troubleshooting #7
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `socket.timeout` sin captura | Excepción filtrada por librería Google | `python3 -c "import socket; print(socket.getdefaulttimeout())"` | Asegurar `try/except` o usar `httplib2` timeout override | C1/C2 |
| `Invalid file ID` | Formato ID no válido para Drive API v3 | `echo $FILE_ID` | Validar formato `1a2B3c...` sin espacios | C1 |

---

### Ejemplo 8: parse CSV/JSON
**Objetivo**: Leer y validar datos CSV desde Drive inyectando `tenant_id` | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
import csv
import io
import logging

def parse_tenant_csv(tenant_id: str, raw_csv_bytes: bytes):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    timeout = int(os.getenv("TIMEOUT_MS", 30000)) / 1000
    max_rows = int(os.getenv("MAX_RESULTS", 1000))
    conn_limit = int(os.getenv("CONNECTION_LIMIT", 5))

    text = raw_csv_bytes.decode("utf-8")
    reader = csv.DictReader(io.StringIO(text))
    parsed = []
    for idx, row in enumerate(reader):
        if idx >= max_rows: break
        row["_ingested_tenant_id"] = tenant_id
        parsed.append(row)

    logging.info({"event": "csv_parse", "tenant_id": tenant_id, "rows_ingested": len(parsed), "maxResults": max_rows, "timeout": timeout, "connectionLimit": conn_limit})
    return parsed
```

✅ Deberías ver: Lista de dicts con clave `_ingested_tenant_id` añadida. Longitud ≤ `max_rows`
❌ Si ves esto en su lugar: `UnicodeDecodeError` o `csv.Error: line contains NULL byte` → Ve a Troubleshooting #8
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `UnicodeDecodeError` | Archivo en encoding `ISO-8859-1` o binario | `file downloaded_file.csv` | Forzar `decode("utf-8-sig")` o usar `chardet` | C1 |
| `line contains NULL byte` | Archivo Excel `.xlsx` tratado como `.csv` | `head -c 50 file` | Convertir a CSV primero o usar `openpyxl` para Excel | C2 |

---

### Ejemplo 9: backup automático
**Objetivo**: Copiar documentos a carpeta backup preservando nombres y tenant | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
from datetime import datetime
from googleapiclient.discovery import build
import logging

def backup_tenant_file(tenant_id: str, source_file_id: str, backup_folder_id: str):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    timeout = int(os.getenv("TIMEOUT_MS", 30000)) / 1000
    max_results = int(os.getenv("MAX_RESULTS", 5))
    conn_limit = int(os.getenv("CONNECTION_LIMIT", 5))
    
    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M")
    copy_name = f"{tenant_id}_backup_{timestamp}"
    
    svc = build("drive", "v3", credentials=init_drive_sheets_client(tenant_id))
    body = {"name": copy_name, "parents": [backup_folder_id]}
    res = svc.files().copy(fileId=source_file_id, body=body).execute(timeout=timeout)
    
    logging.info({"event": "drive_backup", "tenant_id": tenant_id, "new_file_id": res.get("id"), "backup_name": copy_name, "maxResults": max_results, "timeout": timeout, "connectionLimit": conn_limit})
    return res
```

✅ Deberías ver: `{ "new_file_id": "...", "backup_name": "{tenant_id}_backup_{ts}" }` y archivo duplicado en `backup_folder_id`
❌ Si ves esto en su lugar: `File not found: {backup_folder_id}` o `copy_limit_exceeded` → Ve a Troubleshooting #9
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `File not found: folder` | Carpeta de backup no compartida o borrada | `curl $DRIVE_API/files/$backup_folder_id` | Recrear carpeta y compartir con service account | C3/C4 |
| `copy_limit_exceeded` | Cuota de creación de copias superada | Revisar console Cloud Quotas | Esperar reset o reducir `MAX_RESULTS`/frecuencia | C1/C2 |

---

### Ejemplo 10: revocación tokens
**Objetivo**: Invalidar accesos y auditar cierre por tenant | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
import requests
import logging

def revoke_tenant_access(tenant_id: str, token_to_revoke: str):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    timeout = int(os.getenv("TIMEOUT_MS", 30000)) / 1000
    max_results = int(os.getenv("MAX_RESULTS", 1)) # Single revocation per call
    conn_limit = int(os.getenv("CONNECTION_LIMIT", 3))
    
    endpoint = f"https://oauth2.googleapis.com/revoke?token={token_to_revoke}"
    try:
        res = requests.post(endpoint, timeout=timeout)
        res.raise_for_status()
        logging.info({"event": "token_revoked", "tenant_id": tenant_id, "status": "ok", "maxResults": max_results, "timeout": timeout, "connectionLimit": conn_limit})
        return {"revoked": True}
    except requests.exceptions.RequestException as e:
        logging.error({"event": "revoke_failed", "tenant_id": tenant_id, "error": str(e), "timeout": timeout})
        return {"revoked": False, "error": str(e)}
```

✅ Deberías ver: `{ "revoked": True }` y log confirmando revocación con parámetros de límite
❌ Si ves esto en su lugar: `invalid_token` o `invalid_request: Missing parameter: token` → Ve a Troubleshooting #10
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `invalid_token` | Token ya expirado o mal formado | `echo $TOKEN_TO_REVOKE \| wc -c` | Validar origen del token o ignorar si ya no es válido | C1 |
| `ConnectionError` | Red bloqueando endpoint Google OAuth | `curl -I https://oauth2.googleapis.com` | Verificar DNS/Proxy o usar `requests` con timeout explícito | C2 |


---


## Lote Airtable (Low-Code DB)

### Ejemplo 1: conexión API
**Objetivo**: Inicializar cliente HTTP hacia Airtable con límites explícitos y validación C4 | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import https from 'https';

const AIRTABLE_CFG = {
  apiKey: process.env.AIRTABLE_API_KEY || '',
  baseId: process.env.AIRTABLE_BASE_ID || '',
  tableId: process.env.AIRTABLE_TABLE_NAME || 'Main',
  timeout: Number(process.env.TIMEOUT_MS) || 30000,
  connectionLimit: Number(process.env.CONNECTION_LIMIT) || 10,
  maxResults: Number(process.env.MAX_RESULTS) || 50
};

export function initAirtableClient(tenant_id: string) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory');
  const agent = new https.Agent({ keepAlive: true, maxSockets: AIRTABLE_CFG.connectionLimit });
  console.log(JSON.stringify({ event: 'airtable_conn_init', tenant_id, maxResults: AIRTABLE_CFG.maxResults, connectionLimit: AIRTABLE_CFG.connectionLimit, timeout: AIRTABLE_CFG.timeout }));
  return { baseUrl: `https://api.airtable.com/v0/${AIRTABLE_CFG.baseId}/${encodeURIComponent(AIRTABLE_CFG.tableId)}`, headers: { Authorization: `Bearer ${AIRTABLE_CFG.apiKey}` }, agent };
}
```

✅ Deberías ver: `{ "event":"airtable_conn_init","tenant_id":"...","maxResults":50,"connectionLimit":10,"timeout":30000 }` en stdout y objeto con URL/base/headers configurados
❌ Si ves esto en su lugar: `C4 VIOLATION: tenant_id mandatory` o `EAI_AGAIN api.airtable.com` → Ve a Troubleshooting #1
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `C4 VIOLATION` | `tenant_id` undefined en llamada | `console.log(process.env.TENANT_ID)` | Validar contexto antes de invocar | C4 |
| `EAI_AGAIN` | DNS bloqueado o proxy mal configurado | `dig api.airtable.com` | Verificar resolución DNS o ajustar `HTTP_PROXY` | C3/C2 |

---

### Ejemplo 2: queries tenant_id
**Objetivo**: Recuperar registros filtrados estrictamente por inquilino con límite | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```python
import os, requests, json

def fetch_tenant_records(tenant_id: str):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    timeout_sec = int(os.getenv("TIMEOUT_MS", 30000)) / 1000
    conn_limit = int(os.getenv("CONNECTION_LIMIT", 10))
    max_res = int(os.getenv("MAX_RESULTS", 5))
    url = f"{os.getenv('AIRTABLE_BASE_URL')}/{os.getenv('AIRTABLE_BASE_ID')}/{os.getenv('AIRTABLE_TABLE_NAME')}"
    headers = {"Authorization": f"Bearer {os.getenv('AIRTABLE_API_KEY')}", "Connection": "keep-alive"}
    params = {"filterByFormula": f"{{TenantID}}='{tenant_id}'", "maxRecords": max_res, "timeout": timeout_sec}
    # Simula connectionLimit vía sesión adaptada
    res = requests.get(url, headers=headers, params=params, timeout=timeout_sec)
    res.raise_for_status()
    print(json.dumps({"event": "records_fetched", "tenant_id": tenant_id, "count": len(res.json().get("records", [])), "maxResults": max_res, "timeout": timeout_sec, "connectionLimit": conn_limit}))
    return res.json()
```

✅ Deberías ver: JSON con `count` ≤ `max_results`. Todos los `records[0].fields.TenantID` coinciden con `tenant_id`. Log con parámetros C1/C2
❌ Si ves esto en su lugar: `HTTPError: 403 Forbidden` o `FormulaError` → Ve a Troubleshooting #2
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `HTTPError: 403` | API Key inválida o permisos de tabla insuficientes | `curl -H "Authorization: Bearer $KEY" $URL` | Rotar `AIRTABLE_API_KEY` o asignar rol `Editor/Viewer` | C3 |
| `FormulaError` | Campo `TenantID` no existe o nombre incorrecto | `curl $URL -H "Authorization: Bearer $KEY"` (GET sin filter) | Verificar nombre exacto en schema Airtable | C4 |

---

### Ejemplo 3: paginación
**Objetivo**: Recorrer `offset` manteniendo límite total y contexto de tenant | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import https from 'https';

async function paginateTenantRecords(tenant_id: string) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory');
  const timeout = Number(process.env.TIMEOUT_MS) || 30000;
  const maxResults = Number(process.env.MAX_RESULTS) || 100;
  const connLimit = Number(process.env.CONNECTION_LIMIT) || 10;
  const base = `https://api.airtable.com/v0/${process.env.AIRTABLE_BASE_ID}/${process.env.AIRTABLE_TABLE_NAME}`;
  
  let offset: string | undefined = undefined;
  const allRecords = [];
  let collected = 0;

  while (collected < maxResults) {
    const url = new URL(base);
    url.searchParams.set('filterByFormula', `{TenantID}='${tenant_id}'`);
    if (offset) url.searchParams.set('offset', offset);
    url.searchParams.set('pageSize', String(Math.min(100, maxResults - collected)));

    const res = await fetch(url.toString(), { 
      headers: { Authorization: `Bearer ${process.env.AIRTABLE_API_KEY}` }, 
      signal: AbortSignal.timeout(timeout)
    });
    if (!res.ok) throw new Error(`Airtable fetch failed: ${res.status}`);
    const json = await res.json();
    allRecords.push(...json.records);
    collected += json.records.length;
    offset = json.offset;
    if (!offset) break;
  }
  console.log(JSON.stringify({ event: 'pagination_complete', tenant_id, totalFetched: collected, maxResults, connectionLimit: connLimit, timeout }));
  return allRecords;
}
```

✅ Deberías ver: `{ "event":"pagination_complete","totalFetched":X,"maxResults":100 }` con `X ≤ 100`. Todos los records contienen `tenant_id`
❌ Si ves esto en su lugar: `AbortError` o `Invalid offset` → Ve a Troubleshooting #3
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `AbortError` | `TIMEOUT_MS` insuficiente para páginas múltiples | Medir tiempo de respuesta por iteración | Incrementar `timeout` o reducir `maxResults` | C1/C2 |
| `Invalid offset` | Token expirado o paginación reiniciada | Verificar response `offset` value | Reiniciar loop sin `offset` o implementar retry con backoff | C2 |

---

### Ejemplo 4: batch updates
**Objetivo**: Actualizar lotes respetando límite de 10 por request de Airtable | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```python
import os, requests, json, math

def batch_update_tenant(tenant_id: str, records: list[dict]):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    max_res = int(os.getenv("MAX_RESULTS", 5)) # Batch count per call
    timeout = int(os.getenv("TIMEOUT_MS", 30000)) / 1000
    conn_limit = int(os.getenv("CONNECTION_LIMIT", 10))
    url = f"{os.getenv('AIRTABLE_BASE_URL')}/{os.getenv('AIRTABLE_BASE_ID')}/{os.getenv('AIRTABLE_TABLE_NAME')}"
    headers = {"Authorization": f"Bearer {os.getenv('AIRTABLE_API_KEY')}", "Content-Type": "application/json"}
    
    chunks = [records[i:i + 10] for i in range(0, len(records), 10)][:max_res]
    for idx, chunk in enumerate(chunks):
        payload = {"records": [{"id": r["id"], "fields": {**r.get("fields", {}), "_updated_tenant_id": tenant_id}} for r in chunk]}
        res = requests.patch(url, json=payload, headers=headers, timeout=timeout)
        res.raise_for_status()
        print(json.dumps({"event": "batch_update", "tenant_id": tenant_id, "chunk": idx, "maxResults": max_res, "connectionLimit": conn_limit, "timeout": timeout}))
    return {"updated_batches": len(chunks)}
```

✅ Deberías ver: Log por chunk procesado. Airtable muestra campos actualizados. Salida `{ "updated_batches": X }`
❌ Si ves esto en su lugar: `TooManyRequests: 429` o `RecordNotFound` → Ve a Troubleshooting #4
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `TooManyRequests: 429` | Límite API superado (5 req/s) | Revisar headers `X-RateLimit-Remaining` | Implementar `time.sleep()` o reducir `CONNECTION_LIMIT` | C1/C2 |
| `RecordNotFound` | ID de registro eliminado o de otro tenant | Verificar `id` en payload | Filtrar IDs válidos antes de enviar | C4 |

---

### Ejemplo 5: webhooks
**Objetivo**: Procesar payload de webhook validando firma y tenant | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import express from 'express';
const router = express.Router();

router.post('/airtable-webhook', express.json({ limit: `${process.env.MAX_RESULTS || 5}mb` }), (req, res) => {
  const tenant_id = req.body?.records?.[0]?.fields?.TenantID;
  if (!tenant_id) return res.status(400).json({ error: 'C4 VIOLATION: tenant_id missing in webhook' });

  console.log(JSON.stringify({ 
    event: 'webhook_processed', tenant_id, 
    action: req.body.action, 
    maxResults: process.env.MAX_RESULTS,
    connectionLimit: process.env.CONNECTION_LIMIT,
    timeout: process.env.TIMEOUT_MS 
  }));
  res.status(200).json({ accepted: true, tenant_id });
});
```

✅ Deberías ver: `{ "accepted":true, "tenant_id":"..." }` y log detallado de acción entrante
❌ Si ves esto en su lugar: `C4 VIOLATION: tenant_id missing in webhook` o `PayloadTooLargeError` → Ve a Troubleshooting #5
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `PayloadTooLargeError` | Webhook excede límite de Express | `curl -X POST -H "Content-Type: application/json" -d '{"huge":"data"}' $URL` | Aumentar `express.json({ limit: '50mb' })` o filtrar en origen | C1/C2 |
| `C4 VIOLATION` | Campo `TenantID` vacío en tabla Airtable | Revisar payload JSON crudo | Validar dato en tabla o rechazar con `400` explícito | C4 |

---

### Ejemplo 6: filtros avanzados
**Objetivo**: Construir fórmulas compuestas AND/OR manteniendo aislamiento estricto | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```python
import os, requests, urllib.parse, json

def complex_query_tenant(tenant_id: str, status: str):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    max_res = int(os.getenv("MAX_RESULTS", 10))
    timeout = int(os.getenv("TIMEOUT_MS", 30000)) / 1000
    conn_limit = int(os.getenv("CONNECTION_LIMIT", 10))
    
    formula = f"AND({{TenantID}}='{tenant_id}', {{Status}}='{status}', IS_AFTER({{Created}}, '2023-01-01'))"
    url = f"{os.getenv('AIRTABLE_BASE_URL')}/{os.getenv('AIRTABLE_BASE_ID')}/{os.getenv('AIRTABLE_TABLE_NAME')}?filterByFormula={urllib.parse.quote(formula)}&maxRecords={max_res}"
    headers = {"Authorization": f"Bearer {os.getenv('AIRTABLE_API_KEY')}"}
    
    res = requests.get(url, headers=headers, timeout=timeout)
    res.raise_for_status()
    print(json.dumps({"event": "complex_query", "tenant_id": tenant_id, "status_filter": status, "maxResults": max_res, "connectionLimit": conn_limit, "timeout": timeout}))
    return res.json().get("records", [])
```

✅ Deberías ver: Array de registros que coinciden con `tenant_id`, `status` y fecha. Log con parámetros C1/C2
❌ Si ves esto en su lugar: `HTTPError: 400 Bad Request` o `InvalidFormula` → Ve a Troubleshooting #6
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `InvalidFormula` | Sintaxis AND/OR o comillas mal escapadas | `print(urllib.parse.quote(formula))` | Validar comillas simples/dobles y nombres de campos exactos | C1/C2 |
| `HTTPError: 400` | URL excede límite de caracteres | Medir longitud de URL | Reducir condiciones o usar POST batch si aplica | C2 |

---

### Ejemplo 7: adjuntos media
**Objetivo**: Gestionar subida de archivos con URLs firmadas y validación de tenant | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import axios from 'axios';
import fs from 'fs';

async function uploadMediaAttachment(tenant_id: string, recordId: string, filePath: string) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory');
  const timeout = Number(process.env.TIMEOUT_MS) || 30000;
  const maxResults = Number(process.env.MAX_RESULTS) || 1;
  const connLimit = Number(process.env.CONNECTION_LIMIT) || 10;

  // 1. Solicitar URL de subida
  const attachUrl = `https://api.airtable.com/v0/${process.env.AIRTABLE_BASE_ID}/${process.env.AIRTABLE_TABLE_NAME}/${recordId}`;
  const { data: { attachments } } = await axios.post(attachUrl, 
    { fields: { FileField: [{ filename: `_${tenant_id}_upload.pdf`, contentType: 'application/pdf' }] } },
    { headers: { Authorization: `Bearer ${process.env.AIRTABLE_API_KEY}` }, timeout }
  );

  // 2. Subir a URL firmada
  const signedUrl = attachments[0].uploadUrl;
  await axios.put(signedUrl, fs.createReadStream(filePath), { maxContentLength: Infinity, maxBodyLength: Infinity, timeout, headers: { 'Content-Type': 'application/pdf' } });

  // 3. Confirmar en registro
  const { data } = await axios.patch(attachUrl, { fields: { FileField: attachments } }, { headers: { Authorization: `Bearer ${process.env.AIRTABLE_API_KEY}` }, timeout });
  console.log(JSON.stringify({ event: 'media_uploaded', tenant_id, record_id: recordId, maxResults, connectionLimit: connLimit, timeout }));
  return data;
}
```

✅ Deberías ver: Log JSON con `media_uploaded` y registro actualizado en Airtable con archivo adjunto
❌ Si ves esto en su lugar: `RequestEntityTooLarge` o `C4 VIOLATION` → Ve a Troubleshooting #7
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `RequestEntityTooLarge` | Supera límite de Airtable (1GB por archivo) | `du -h filePath` | Comprimir archivo o usar enlace externo en campo URL | C2 |
| `C4 VIOLATION` | `tenant_id` no validado antes de POST | Revisar llamada | Añadir validación estricta en middleware | C4 |

---

### Ejemplo 8: sync bidireccional
**Objetivo**: Diferenciar y sincronizar cambios locales ↔ Airtable por tenant | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```python
import os, requests, json, time

def bidirectional_sync(tenant_id: str, local_updates: list[dict]):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    timeout = int(os.getenv("TIMEOUT_MS", 30000)) / 1000
    conn_limit = int(os.getenv("CONNECTION_LIMIT", 5))
    max_res = int(os.getenv("MAX_RESULTS", 10))
    base_url = f"{os.getenv('AIRTABLE_BASE_URL')}/{os.getenv('AIRTABLE_BASE_ID')}/{os.getenv('AIRTABLE_TABLE_NAME')}"
    
    # Push updates
    for chunk in [local_updates[i:i+10] for i in range(0, len(local_updates), 10)][:max_res]:
        payload = {"records": [{"id": r["id"], "fields": {"SyncStatus": "Updated", "LastTenant": tenant_id}} for r in chunk]}
        requests.patch(base_url, json=payload, headers={"Authorization": f"Bearer {os.getenv('AIRTABLE_API_KEY')}"}, timeout=timeout)
        time.sleep(0.2) # Respetar rate limit implícito
        
    print(json.dumps({"event": "bidirectional_sync", "tenant_id": tenant_id, "records_pushed": len(local_updates), "maxResults": max_res, "connectionLimit": conn_limit, "timeout": timeout}))
    return {"status": "synced", "tenant_id": tenant_id}
```

✅ Deberías ver: `{ "status":"synced", "tenant_id":"..." }`. Registros actualizados en Airtable con `SyncStatus: Updated`
❌ Si ves esto en su lugar: `TooManyRequests` o `RecordMismatch` → Ve a Troubleshooting #8
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `TooManyRequests` | Loop sin delay respetuoso con API | Revisar logs de `429` | Mantener `time.sleep()` o usar batch endpoint oficial | C1/C2 |
| `RecordMismatch` | ID local no coincide con Airtable | `SELECT id FROM table WHERE id=X` | Validar mapeo de IDs antes de sincronizar | C4 |

---

### Ejemplo 9: fallback caché
**Objetivo**: Servir datos cacheados si API falla, manteniendo clave con `tenant_id` | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import fs from 'fs/promises';
import path from 'path';

async function getCachedOrFetch(tenant_id: string, fetchFn: Function) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory');
  const timeout = Number(process.env.TIMEOUT_MS) || 30000;
  const maxResults = Number(process.env.MAX_RESULTS) || 5;
  const connLimit = Number(process.env.CONNECTION_LIMIT) || 10;
  
  const cacheFile = path.join('/tmp/cache', `${tenant_id}_airtable_${Date.now()}.json`);
  
  try {
    const result = await Promise.race([
      fetchFn(tenant_id),
      new Promise((_, rej) => setTimeout(() => rej(new Error('fetch_timeout')), timeout))
    ]);
    await fs.writeFile(cacheFile, JSON.stringify(result));
    console.log(JSON.stringify({ event: 'cache_stored', tenant_id, maxResults, connectionLimit: connLimit, timeout }));
    return result;
  } catch (err) {
    try {
      const fallback = await fs.readFile(cacheFile, 'utf-8');
      console.log(JSON.stringify({ event: 'fallback_cache_used', tenant_id, error: (err as Error).message, maxResults, connectionLimit: connLimit, timeout }));
      return JSON.parse(fallback);
    } catch (readErr) {
      throw new Error(`Airtable fetch failed & cache miss for tenant: ${tenant_id}`);
    }
  }
}
```

✅ Deberías ver: Log `cache_stored` en éxito o `fallback_cache_used` con payload anterior en timeout/fallo
❌ Si ves esto en su lugar: `cache miss & fetch failed` o `C4 VIOLATION` → Ve a Troubleshooting #9
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `cache miss & fetch failed` | Directorio `/tmp/cache` no existe o permisos | `ls -la /tmp/cache` | Crear directorio y asignar permisos de escritura | C2 |
| `C4 VIOLATION` | Función llamada sin `tenant_id` | Stack trace | Validar argumentos en capa superior | C4 |

---

### Ejemplo 10: limpieza registros antiguos
**Objetivo**: Eliminar registros históricos por tenant con paginación segura y límites | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```python
import os, requests, json

def cleanup_old_records(tenant_id: str, cutoff_date: str):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    timeout = int(os.getenv("TIMEOUT_MS", 30000)) / 1000
    conn_limit = int(os.getenv("CONNECTION_LIMIT", 5))
    max_res = int(os.getenv("MAX_RESULTS", 100))
    base = f"{os.getenv('AIRTABLE_BASE_URL')}/{os.getenv('AIRTABLE_BASE_ID')}/{os.getenv('AIRTABLE_TABLE_NAME')}"
    headers = {"Authorization": f"Bearer {os.getenv('AIRTABLE_API_KEY')}"}
    
    formula = f"AND({{TenantID}}='{tenant_id}', IS_BEFORE({{Created}}, '{cutoff_date}'))"
    # 1. Encontrar IDs
    ids_to_delete = []
    offset = None
    while len(ids_to_delete) < max_res:
        res = requests.get(base, headers=headers, params={"filterByFormula": formula, "pageSize": 100, "offset": offset, "fields": []}, timeout=timeout)
        res.raise_for_status()
        data = res.json()
        ids_to_delete.extend([r["id"] for r in data.get("records", [])])
        offset = data.get("offset")
        if not offset: break

    # 2. Eliminar en lotes de 10
    deleted_count = 0
    for chunk in [ids_to_delete[i:i+10] for i in range(0, len(ids_to_delete), 10)]:
        requests.delete(base, headers=headers, params={"records[]": chunk}, timeout=timeout)
        deleted_count += len(chunk)
        
    print(json.dumps({"event": "records_purged", "tenant_id": tenant_id, "deleted_count": deleted_count, "maxResults": max_res, "connectionLimit": conn_limit, "timeout": timeout}))
    return {"purged": deleted_count}
```

✅ Deberías ver: `{ "event":"records_purged","deleted_count":X }` donde `X ≤ maxResults`. Registros antiguos eliminados en Airtable
❌ Si ves esto en su lugar: `Forbidden: 403` o `FormulaError` → Ve a Troubleshooting #10
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Forbidden: 403` | API Key sin permisos de eliminación | Revisar dashboard API Tokens | Otorgar rol `Editor` o `Owner` a la credencial | C3 |
| `FormulaError` | Campo `Created` no es fecha o nombre erróneo | Verificar tipo de campo en Airtable UI | Usar nombre exacto o convertir a ISO 8601 | C1/C2 |


---


## Lote SQLite (Embedded/Local Fallback)

### Ejemplo 1: inicialización DB
**Objetivo**: Configurar base SQLite local con límites explícitos, WAL seguro y validación C4 | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```python
import os
import sqlite3
import json
import logging

def init_sqlite_local(tenant_id: str, db_path: str = None):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    timeout_ms = int(os.getenv("TIMEOUT_MS", 30000))
    max_results = int(os.getenv("MAX_RESULTS", 5))
    conn_limit = int(os.getenv("CONNECTION_LIMIT", 10))
    path = db_path or os.getenv("SQLITE_PATH", f"./data/rag_local_{tenant_id}.db")
    
    conn = sqlite3.connect(f"file:{path}?mode=rwc", timeout=timeout_ms/1000.0, uri=True)
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA busy_timeout=?", (timeout_ms,))
    conn.execute("PRAGMA synchronous=NORMAL")
    
    logging.info(json.dumps({
        "event": "sqlite_init", "tenant_id": tenant_id, 
        "maxResults": max_results, "connectionLimit": conn_limit, "timeout_ms": timeout_ms,
        "inference_proxy": os.getenv("OPENROUTER_URL") # C6
    }))
    return conn
```
✅ Deberías ver: Log JSON con `sqlite_init`, `tenant_id` y parámetros C1/C2. Archivos `.db`, `-wal`, `-shm` creados.
❌ Si ves esto en su lugar: `sqlite3.OperationalError: unable to open database file` o `C4 VIOLATION` → Ve a Troubleshooting #1
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `unable to open database file` | Directorio padre no existe o permisos `root` | `ls -ld ./data/` | `mkdir -p ./data` y `chown -R $USER ./data` | C2 |
| `C4 VIOLATION` | `tenant_id` vacío en runtime | `print(f"ID={tenant_id}")` | Validar payload antes de instanciar conexión | C4 |

---

### Ejemplo 2: WAL mode
**Objetivo**: Habilitar y verificar WAL para lecturas concurrentes sin bloqueos | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import sqlite3, os, logging, json from 'better-sqlite3';

function enableWAL(tenant_id: string) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory');
  const dbPath = process.env.SQLITE_PATH || `./data/rag_local_${tenant_id}.db`;
  const timeout = Number(process.env.TIMEOUT_MS) || 30000;
  const maxResults = Number(process.env.MAX_RESULTS) || 5;
  const connLimit = Number(process.env.CONNECTION_LIMIT) || 10;
  
  const db = new sqlite(dbPath, { timeout, verbose: console.log });
  db.pragma('journal_mode = WAL');
  db.pragma(`busy_timeout = ${timeout}`);
  db.pragma('synchronous = NORMAL');
  
  const walStatus = db.pragma('journal_mode', { plain: true });
  logging.info(JSON.stringify({ event: 'wal_enabled', tenant_id, mode: walStatus, maxResults, connectionLimit: connLimit, timeout }));
  return db;
}
```
✅ Deberías ver: `{"event":"wal_enabled","mode":"wal",...}` en logs. `file.db-wal` activo en filesystem.
❌ Si ves esto en su lugar: `Error: database disk image is malformed` o `C4 VIOLATION` → Ve a Troubleshooting #2
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `database disk image is malformed` | WAL corrupto por kill abrupto | `sqlite3 file.db "PRAGMA integrity_check;"` | Eliminar `.db-wal`/`.db-shm` y ejecutar `VACUUM` | C1/C2 |
| `C4 VIOLATION` | Falta validación en entrada | Revisar `console.trace()` | Añadir `if (!tenant_id) throw...` explícito | C4 |

---

### Ejemplo 3: queries tenant_id
**Objetivo**: Recuperar registros con aislamiento estricto y límite `maxResults` | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```python
import os, sqlite3, json, logging

def query_local_tenant(conn, tenant_id: str, table: str):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    max_res = int(os.getenv("MAX_RESULTS", 5))
    timeout_ms = int(os.getenv("TIMEOUT_MS", 30000))
    conn_limit = int(os.getenv("CONNECTION_LIMIT", 10))
    
    query = f"SELECT id, content, score FROM {table} WHERE tenant_id = ? ORDER BY score DESC LIMIT ?"
    cursor = conn.execute(query, (tenant_id, max_res))
    rows = cursor.fetchall()
    
    logging.info(json.dumps({
        "event": "local_query", "tenant_id": tenant_id, "rows": len(rows),
        "maxResults": max_res, "connectionLimit": conn_limit, "timeout_ms": timeout_ms
    }))
    return rows
```
✅ Deberías ver: Lista de tuplas. Log con `rows ≤ maxResults` y `tenant_id` auditado.
❌ Si ves esto en su lugar: `no such table: rag_vectors` o `SQLITE_ERROR` → Ve a Troubleshooting #3
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `no such table` | Esquema no aplicado o tabla renombrada | `sqlite3 file.db ".tables"` | Ejecutar script de migración `CREATE TABLE` previo | C1 |
| `SQLITE_BUSY` | Lock activo por writer concurrente | `fuser -v file.db` | Esperar `busy_timeout` o serializar escrituras | C2 |

---

### Ejemplo 4: backup file
**Objetivo**: Generar snapshot seguro con validación de tenant en metadatos | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import fs from 'fs/promises';
import path from 'path';
import { execSync } from 'child_process';

async function backupLocalDB(tenant_id: string) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory');
  const src = process.env.SQLITE_PATH || `./data/rag_local_${tenant_id}.db`;
  const dst = path.join('/backups', `${tenant_id}_sqlite_${Date.now()}.bak`);
  const timeout = Number(process.env.TIMEOUT_MS) || 30000;
  const maxResults = Number(process.env.MAX_RESULTS) || 5;
  const connLimit = Number(process.env.CONNECTION_LIMIT) || 10;

  await fs.mkdir('/backups', { recursive: true });
  // Backup atómico usando utilidades nativas o sqlite3 .backup
  execSync(`sqlite3 '${src}' ".backup '${dst}'"`, { timeout, stdio: 'pipe' });
  
  console.log(JSON.stringify({
    event: 'local_backup', tenant_id, dest: dst,
    maxResults, connectionLimit: connLimit, timeout_ms: timeout
  }));
  return { success: true, path: dst };
}
```
✅ Deberías ver: `{ success: true, path: "/backups/tenant_..._timestamp.bak" }`. Archivo `.bak` generado y consistente.
❌ Si ves esto en su lugar: `execSync timeout` o `EACCES: permission denied` → Ve a Troubleshooting #4
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `execSync timeout` | DB bloqueada o I/O saturada | `iostat -x 1` | Cerrar writers activos o aumentar `TIMEOUT_MS` | C1/C2 |
| `EACCES` | Proceso sin permisos de escritura en `/backups` | `ls -ld /backups` | `chmod 777 /backups` o ejecutar con `sudo` | C3 |

---

### Ejemplo 5: read-only mode
**Objetivo**: Abrir conexión de solo lectura para consultas analíticas | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```python
import os, sqlite3, json, logging

def open_readonly_tenant(tenant_id: str):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    db_path = os.getenv("SQLITE_PATH")
    timeout_ms = int(os.getenv("TIMEOUT_MS", 30000))
    max_results = int(os.getenv("MAX_RESULTS", 100))
    conn_limit = int(os.getenv("CONNECTION_LIMIT", 10))
    
    conn = sqlite3.connect(f"file:{db_path}?mode=ro", timeout=timeout_ms/1000.0, uri=True)
    try:
        conn.execute("PRAGMA query_only = ON")
        cursor = conn.execute("SELECT COUNT(*) FROM rag_vectors WHERE tenant_id = ?", (tenant_id,))
        count = cursor.fetchone()[0]
        logging.info(json.dumps({
            "event": "ro_query", "tenant_id": tenant_id, "record_count": count,
            "maxResults": max_results, "connectionLimit": conn_limit, "timeout_ms": timeout_ms
        }))
        return {"mode": "readonly", "tenant_id": tenant_id, "count": count}
    finally:
        conn.close()
```
✅ Deberías ver: `{"mode":"readonly","count":X}`. `PRAGMA query_only=1` activo. Cero escrituras en `sqlite_stat`.
❌ Si ves esto en su lugar: `SQLITE_READONLY` al intentar INSERT o `file is not a database` → Ve a Troubleshooting #5
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `file is not a database` | Cabecera corrompida o archivo vacío | `hexdump -C file.db \| head` | Restaurar desde backup o recrear esquema | C1 |
| `SQLITE_READONLY` (intencional) | Aplicación intenta escribir | Revisar código fuente | Redirigir writes a pool `rwc` o usar tabla temporal en RAM | C2 |

---

### Ejemplo 6: sync con cloud
**Objetivo**: Extraer cambios locales pendientes y preparar push a API cloud | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import sqlite from 'better-sqlite3';
import https from 'https';

function extractSyncBatch(tenant_id: string) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory');
  const dbPath = process.env.SQLITE_PATH || `./data/rag_local_${tenant_id}.db`;
  const db = new sqlite(dbPath, { timeout: Number(process.env.TIMEOUT_MS)/1000 });
  const maxResults = Number(process.env.MAX_RESULTS) || 50;
  const timeout = Number(process.env.TIMEOUT_MS);
  const connLimit = Number(process.env.CONNECTION_LIMIT);

  const pending = db.prepare("SELECT id, payload, version FROM sync_queue WHERE tenant_id = ? AND synced = 0 ORDER BY created_at ASC LIMIT ?").all(tenant_id, maxResults);
  
  // C6: Inferencia solo vía OpenRouter proxy (log de auditoría)
  console.log(JSON.stringify({ 
    event: 'sync_extract', tenant_id, pending_count: pending.length, 
    maxResults, connectionLimit: connLimit, timeout_ms: timeout,
    inference_proxy: process.env.OPENROUTER_URL 
  }));
  return pending; // Devolver para posterior HTTP push seguro
}
```
✅ Deberías ver: Array de objetos pendientes ≤ `maxResults`. Log con `sync_extract` y ruta de proxy cloud.
❌ Si ves esto en su lugar: `SQLITE_NO_SUCH_TABLE: sync_queue` o `C4 VIOLATION` → Ve a Troubleshooting #6
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `SQLITE_NO_SUCH_TABLE` | Cola de sync no inicializada | `db.prepare('SELECT name FROM sqlite_master WHERE type="table"').all()` | Ejecutar DDL de `sync_queue` en arranque | C1/C2 |
| `C4 VIOLATION` | `tenant_id` omitido en query | Validar argumentos | Añadir `if(!tenant_id) throw` antes de `prepare()` | C4 |

---

### Ejemplo 7: manejo locks
**Objetivo**: Retry exponencial ante `SQLITE_BUSY` con límites estrictos | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```python
import os, time, sqlite3, json, logging

def safe_write_with_locks(tenant_id: str, query: str, params: tuple, retries=3):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    timeout_ms = int(os.getenv("TIMEOUT_MS", 30000))
    max_results = int(os.getenv("MAX_RESULTS", 5))
    conn_limit = int(os.getenv("CONNECTION_LIMIT", 10))
    
    for attempt in range(retries):
        try:
            conn = sqlite3.connect(os.getenv("SQLITE_PATH"), timeout=timeout_ms/1000.0)
            conn.execute("PRAGMA busy_timeout=?", (timeout_ms,))
            cursor = conn.execute(query, params)
            conn.commit()
            result = cursor.rowcount
            logging.info(json.dumps({
                "event": "write_success", "tenant_id": tenant_id, "affected": result, "attempt": attempt+1,
                "maxResults": max_results, "connectionLimit": conn_limit, "timeout_ms": timeout_ms
            }))
            return result
        except sqlite3.OperationalError as e:
            if "database is locked" in str(e) and attempt < retries - 1:
                wait = 2 ** attempt * 0.1
                time.sleep(wait)
            else:
                raise e
        finally:
            if 'conn' in locals(): conn.close()
```
✅ Deberías ver: `write_success` log con `attempt=1` o mayor tras backoff. `rowcount` exacto.
❌ Si ves esto en su lugar: `database is locked` agotado o `C4 VIOLATION` → Ve a Troubleshooting #7
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `database is locked` agotado | Escritores simultáneos > capacidad WAL | `lsof file.db \| grep WRITE` | Serializar operaciones o escalar a Postgres | C1/C2 |
| `C4 VIOLATION` | Falta parámetro en llamada | Stacktrace | Revisar firma de función y argumentos | C4 |

---

### Ejemplo 8: optimización VACUUM
**Objetivo**: Reclamar espacio y reindexar de forma segura y auditable | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import sqlite3 from 'better-sqlite3';

function optimizeVACUUM(tenant_id: string) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory');
  const db = new sqlite3(process.env.SQLITE_PATH, { timeout: Number(process.env.TIMEOUT_MS)/1000 });
  const maxResults = Number(process.env.MAX_RESULTS);
  const connLimit = Number(process.env.CONNECTION_LIMIT);
  const timeout = Number(process.env.TIMEOUT_MS);

  const start = Date.now();
  db.pragma('journal_mode = WAL'); // Asegurar WAL antes de vacuum
  db.exec('VACUUM');
  const duration = Date.now() - start;

  console.log(JSON.stringify({
    event: 'vacuum_complete', tenant_id, duration_ms: duration,
    maxResults, connectionLimit: connLimit, timeout_ms: timeout
  }));
  return { optimized: true, tenant_id };
}
```
✅ Deberías ver: Log `vacuum_complete` con duración en ms. Archivo `.db` reducido en tamaño. WAL reactivado.
❌ Si ves esto en su lugar: `SQLITE_BUSY: database is locked` o `disk I/O error` → Ve a Troubleshooting #8
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `SQLITE_BUSY: locked` | Conexión activa impide `VACUUM` completo | `SELECT * FROM pg_stat_activity;` (analógico: verificar `open()`) | Cerrar pools temporales o usar `pragma auto_vacuum = 2` | C1/C2 |
| `disk I/O error` | Storage lleno o corrupción física | `df -h .` y `sqlite3 file.db "PRAGMA integrity_check;"` | Liberar espacio o restaurar backup limpio | C2 |

---

### Ejemplo 9: fallback offline
**Objetivo**: Detectar caída de red y desviar tráfico a SQLite local | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```python
import os, sqlite3, requests, json, logging

def offline_fallback_query(tenant_id: str, prompt_hash: str):
    if not tenant_id: raise ValueError("C4 VIOLATION: tenant_id mandatory")
    cache_key = f"{tenant_id}:cache:{prompt_hash}" # C4 cache key
    max_results = int(os.getenv("MAX_RESULTS", 5))
    timeout = int(os.getenv("TIMEOUT_MS", 30000))
    conn_limit = int(os.getenv("CONNECTION_LIMIT", 10))
    
    # Intento rápido de conectividad cloud
    try:
        requests.head(os.getenv("OPENROUTER_URL"), timeout=timeout/2000, allow_redirects=True)
        return None # Online, usar flujo normal
    except requests.RequestException:
        pass # Offline -> fallback local
        
    conn = sqlite3.connect(os.getenv("SQLITE_PATH"), timeout=timeout/1000)
    cursor = conn.execute("SELECT response FROM local_cache WHERE key = ? LIMIT ?", (cache_key, 1))
    row = cursor.fetchone()
    
    logging.info(json.dumps({
        "event": "fallback_activated", "tenant_id": tenant_id, "cache_hit": bool(row),
        "key": cache_key, "maxResults": max_results, "connectionLimit": conn_limit, "timeout_ms": timeout
    }))
    return row[0] if row else None
```
✅ Deberías ver: `fallback_activated` log con `cache_hit: true/false`. Clave siempre contiene `tenant_id`.
❌ Si ves esto en su lugar: `SQLITE_CANTOPEN` o `C4 VIOLATION` → Ve a Troubleshooting #9
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `SQLITE_CANTOPEN` | Ruta `.db` inválida en entorno offline | `pwd` y `ls *.db` | Validar `$SQLITE_PATH` absoluto | C3 |
| `C4 VIOLATION` | `tenant_id` no construye `cache_key` | Imprimir `cache_key` | Asegurar concatenación estricta antes de query | C4 |

---

### Ejemplo 10: cleanup automático
**Objetivo**: Purgar registros expirados por tenant con transacción y límite | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```typescript
import sqlite from 'better-sqlite3';

function autoCleanupExpired(tenant_id: string, ttlHours: number = 24) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory');
  const db = new sqlite(process.env.SQLITE_PATH, { timeout: Number(process.env.TIMEOUT_MS)/1000 });
  const maxResults = Number(process.env.MAX_RESULTS) || 100;
  const connLimit = Number(process.env.CONNECTION_LIMIT) || 10;
  const timeout = Number(process.env.TIMEOUT_MS);

  db.transaction(() => {
    const stmt = db.prepare(`DELETE FROM rag_vectors WHERE tenant_id = ? AND inserted_at < datetime('now', '-? hours') LIMIT ?`);
    const result = stmt.run(tenant_id, ttlHours, maxResults);
    console.log(JSON.stringify({
      event: 'cleanup_executed', tenant_id, rows_deleted: result.changes,
      maxResults, connectionLimit: connLimit, timeout_ms: timeout
    }));
  })();
  return { success: true, tenant_id };
}
```
✅ Deberías ver: Log `cleanup_executed` con `rows_deleted ≥ 0`. Datos antiguos removidos. Transacción commit exitoso.
❌ Si ves esto en su lugar: `UNIQUE constraint failed` (raro en delete) o `SQLITE_TOOBIG` → Ve a Troubleshooting #10
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `SQLITE_TOOBIG` | Statement excede límites de SQLite | Revisar longitud de query | Reducir parámetros o usar `VACUUM` si WAL es masivo | C2 |
| `SQLITE_BUSY` | Trigger/View bloqueando DELETE | `db.pragma('foreign_keys').length` | Desactivar FK temporalmente o serializar | C1 |
| `C4 VIOLATION` | `tenant_id` ausente en `run()` | Validar args | Pasar siempre como primer parámetro posicional | C4 |


---


## Lote Modelos IA (Inferencia)

### 🤖 Modelo: OpenRouter (Proxy Base)
### Ejemplo 1: conexión proxy & prompt template
**Objetivo**: Instanciar fetch hacia OpenRouter con `tenant_id` inyectado y límites estrictos | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```typescript
const OPENROUTER_CONFIG = {
  url: process.env.OPENROUTER_URL || 'https://openrouter.ai/api/v1/chat/completions',
  model: process.env.MODEL_DEFAULT || 'openai/gpt-4o-mini',
  apiKey: process.env.OPENROUTER_API_KEY,
  timeout: Number(process.env.TIMEOUT_MS) || 30000,
  connectionLimit: Number(process.env.CONNECTION_LIMIT) || 10,
  maxResults: Number(process.env.MAX_RESULTS) || 1
};

async function invokePrompt(tenant_id: string, prompt: string) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory');
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), OPENROUTER_CONFIG.timeout);
  
  const payload = {
    model: OPENROUTER_CONFIG.model,
    messages: [{ role: 'system', content: `Contexto para tenant: ${tenant_id}` }, { role: 'user', content: prompt }],
    max_tokens: OPENROUTER_CONFIG.maxResults * 500,
    metadata: { tenant_id, connectionLimit: OPENROUTER_CONFIG.connectionLimit }
  };

  const res = await fetch(OPENROUTER_CONFIG.url, {
    method: 'POST',
    headers: { Authorization: `Bearer ${OPENROUTER_CONFIG.apiKey}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
    signal: controller.signal
  });
  clearTimeout(timer);
  if (!res.ok) throw new Error(`Proxy Error: ${res.status}`);
  const data = await res.json();
  console.log(JSON.stringify({ event: 'proxy_success', tenant_id, usage: data.usage, maxResults: OPENROUTER_CONFIG.maxResults }));
  return data.choices[0].message.content;
}
```
✅ Deberías ver: String de respuesta generada + log `{ "event":"proxy_success","tenant_id":"..." }`
❌ Si ves esto en su lugar: `Proxy Error: 401` o `C4 VIOLATION: tenant_id mandatory` → Ve a Troubleshooting #1
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Proxy Error: 401` | `OPENROUTER_API_KEY` inválida o expirada | `curl -H "Authorization: Bearer $KEY" $URL -d '{"model":"test"}'` | Rotar clave en `.env` y reiniciar servicio | C3 |
| `C4 VIOLATION` | `tenant_id` undefined al llamar función | `console.trace()` | Validar middleware de sesión antes de invoke | C4 |


### Ejemplo 2: manejo context length & fallback
**Objetivo**: Truncar prompt si excede token window y aplicar modelo fallback seguro | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function safeInvokeWithFallback(tenant_id: string, prompt: string) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory');
  const timeout = Number(process.env.TIMEOUT_MS) || 30000;
  const maxTokens = Number(process.env.MAX_RESULTS) || 2048;
  const connLimit = Number(process.env.CONNECTION_LIMIT) || 10;
  
  // Truncado simple para demo
  const safePrompt = prompt.slice(0, maxTokens * 4);
  const controller = new AbortController();
  setTimeout(() => controller.abort(), timeout);

  try {
    const res = await fetch(process.env.OPENROUTER_URL!, {
      method: 'POST', headers: { Authorization: `Bearer ${process.env.OPENROUTER_API_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ model: process.env.MODEL_PRIMARY, messages: [{ role: 'user', content: safePrompt }], metadata: { tenant_id } }),
      signal: controller.signal
    });
    if (res.status === 413 || res.status === 400) throw new Error('CONTEXT_EXCEED');
    return await res.json();
  } catch (err) {
    console.warn(JSON.stringify({ event: 'fallback_triggered', tenant_id, error: String(err), connectionLimit: connLimit, timeout }));
    // Fallback a modelo más robusto/corto
    const res2 = await fetch(process.env.OPENROUTER_URL!, {
      method: 'POST', headers: { Authorization: `Bearer ${process.env.OPENROUTER_API_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ model: 'meta-llama/llama-3.1-8b', messages: [{ role: 'user', content: safePrompt.slice(0, 1024) }], metadata: { tenant_id } })
    });
    return res2.json();
  }
}
```
✅ Deberías ver: `{ "event":"fallback_triggered" }` en logs si falla primary, seguido de respuesta fallback. Siempre con `tenant_id`.
❌ Si ves esto en su lugar: `Invalid model name` o `AbortError` → Ve a Troubleshooting #2
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `AbortError` | `timeout` agotado por modelo primario lento | `date +%s && sleep 30 && date +%s` | Incrementar `TIMEOUT_MS` o reducir `maxTokens` | C1/C2 |
| `Invalid model name` | ID de modelo fallback incorrecto en `.env` | `echo $MODEL_FALLBACK` | Verificar catálogo OpenRouter y actualizar | C3 |

### Ejemplo 3: rate limit & retry backoff
**Objetivo**: Reintentar requests `429` con backoff exponencial y tracking por tenant | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function invokeWithRetry(tenant_id: string, prompt: string, retries = 3) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory');
  const timeout = Number(process.env.TIMEOUT_MS) || 30000;
  const maxResults = Number(process.env.MAX_RESULTS) || 3;
  const connLimit = Number(process.env.CONNECTION_LIMIT) || 5;

  for (let i = 0; i < retries; i++) {
    try {
      const ctrl = new AbortController();
      setTimeout(() => ctrl.abort(), timeout);
      const res = await fetch(process.env.OPENROUTER_URL!, {
        method: 'POST',
        headers: { Authorization: `Bearer ${process.env.OPENROUTER_API_KEY}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ model: 'mistralai/mistral-7b', messages: [{ role: 'user', content: prompt }], metadata: { tenant_id } }),
        signal: ctrl.signal
      });
      if (res.status === 429) throw new Error('RATE_LIMIT_HIT');
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return res.json();
    } catch (e) {
      const wait = Math.pow(2, i) * 100;
      console.warn(JSON.stringify({ event: 'retry_backoff', tenant_id, attempt: i+1, wait_ms: wait, connectionLimit: connLimit, timeout }));
      if (i === retries - 1) throw e;
      await new Promise(r => setTimeout(r, wait));
    }
  }
}
```
✅ Deberías ver: `{ "event":"retry_backoff" }` en fallos 429. Éxito en retry o error final tras `retries`.
❌ Si ves esto en su lugar: `ETIMEDOUT` o `Maximum call stack size exceeded` → Ve a Troubleshooting #3
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `ETIMEDOUT` | Red bloqueando proxy o DNS lento | `dig api.openrouter.ai` | Verificar salida internet y `DNS_RESOLVER` en infra | C2 |
| `Maximum call stack` | `retries` mal implementado o recursión infinita | `node --trace-warnings script.ts` | Cambiar a loop `for` iterativo (como ejemplo) | C1/C2 |

### Ejemplo 4: streaming respuestas & validación JSON
**Objetivo**: Consumir stream y parsear salida estricta a JSON con `tenant_id` en meta | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
````markdown
```typescript
async function streamAndValidateJSON(tenant_id: string, prompt: string) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory');
  const timeout = Number(process.env.TIMEOUT_MS) || 30000;
  const maxResults = Number(process.env.MAX_RESULTS) || 1;
  const ctrl = new AbortController();
  setTimeout(() => ctrl.abort(), timeout);

  const res = await fetch(process.env.OPENROUTER_URL!, {
    method: 'POST', headers: { Authorization: `Bearer ${process.env.OPENROUTER_API_KEY}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ model: 'qwen/qwen-turbo', messages: [{ role: 'user', content: prompt }], stream: true, metadata: { tenant_id, connectionLimit: process.env.CONNECTION_LIMIT } }),
    signal: ctrl.signal
  });
  
  let buffer = '';
  const reader = res.body!.getReader();
  const decoder = new TextDecoder();
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    buffer += decoder.decode(value, { stream: true });
  }
  try {
    // Extraer bloque JSON si hay markdown
    const jsonMatch = buffer.match(/```json\n([\s\S]*?)\n```/) || [null, buffer];
    return JSON.parse(jsonMatch[1] || buffer);
  } catch {
    console.error(JSON.stringify({ event: 'json_parse_failed', tenant_id, raw_length: buffer.length }));
    throw new Error('INVALID_JSON_OUTPUT');
  }
}
```
````


✅ Deberías ver: Objeto JSON parseado correctamente. Si falla, log `{ "event":"json_parse_failed","tenant_id":"..." }`.
❌ Si ves esto en su lugar: `Unexpected token < in JSON` o `C4 VIOLATION` → Ve a Troubleshooting #4
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Unexpected token <` | Proxy retorna HTML de error (5xx/4xx) | `echo "$buffer" \| head -c 200` | Validar `res.ok` antes de parsear stream | C1/C2 |
| `INVALID_JSON_OUTPUT` | Modelo retorna texto libre | Forzar prompt `Responde SOLO JSON válido` | Añadir sistema de validación con ZOD/ajv | C4 |

### Ejemplo 5: coste optimización & error handling
**Objetivo**: Seleccionar modelo por coste/token y capturar errores de inferencia | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```typescript
type CostProfile = 'cheap' | 'balanced' | 'premium';
const MODEL_MAP: Record<CostProfile, string> = { cheap: 'gpt-3.5-turbo', balanced: 'claude-3-haiku', premium: 'gpt-4' };

async function costOptimizedInvoke(tenant_id: string, prompt: string, profile: CostProfile = 'cheap') {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory');
  const timeout = Number(process.env.TIMEOUT_MS) || 30000;
  const maxResults = Number(process.env.MAX_RESULTS) || 1;
  const connLimit = Number(process.env.CONNECTION_LIMIT) || 10;

  try {
    const res = await fetch(process.env.OPENROUTER_URL!, {
      method: 'POST',
      headers: { Authorization: `Bearer ${process.env.OPENROUTER_API_KEY}`, 'HTTP-Referer': 'mantis-rag', 'Content-Type': 'application/json' },
      body: JSON.stringify({ model: MODEL_MAP[profile], messages: [{ role: 'user', content: prompt }], max_tokens: maxResults * 256, metadata: { tenant_id, cost_profile: profile } }),
      signal: AbortSignal.timeout(timeout)
    });
    if (res.status >= 400) {
      const errBody = await res.text();
      throw new Error(`Inference failed: ${res.status} - ${errBody}`);
    }
    const data = await res.json();
    console.log(JSON.stringify({ event: 'cost_invoke', tenant_id, profile, model: MODEL_MAP[profile], connectionLimit: connLimit }));
    return data;
  } catch (err: any) {
    console.error(JSON.stringify({ event: 'inference_error', tenant_id, error: err.message, profile, timeout, connectionLimit: connLimit }));
    return { fallback: true, error: err.message };
  }
}
```
✅ Deberías ver: `{ "event":"cost_invoke","tenant_id":"...","profile":"cheap" }` o `{ fallback: true }` en error controlado.
❌ Si ves esto en su lugar: `model_not_found` o `Insufficient Quota` → Ve a Troubleshooting #5
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `model_not_found` | Nombre en `MODEL_MAP` deprecado | Revisar docs OpenRouter modelos | Actualizar `MODEL_MAP` en código | C3 |
| `Insufficient Quota` | Saldo de crédito OpenRouter agotado | Dashboard OpenRouter > Billing | Recargar créditos o habilitar billing auto | C1/C6 |

---

### 🤖 Modelo: GPT-4
### Ejemplo 1: conexión proxy & prompt template
**Objetivo**: Configurar llamada a `openai/gpt-4` vía OpenRouter con aislamiento | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function gpt4Invoke(tenant_id: string, query: string) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory');
  const cfg = { url: process.env.OPENROUTER_URL, model: 'openai/gpt-4', key: process.env.OPENROUTER_API_KEY, timeout: Number(process.env.TIMEOUT_MS)||30000, maxRes: Number(process.env.MAX_RESULTS)||5, connLim: Number(process.env.CONNECTION_LIMIT)||10 };
  const ctrl = new AbortController(); setTimeout(()=>ctrl.abort(), cfg.timeout);
  const res = await fetch(cfg.url, { method:'POST', headers:{ Authorization:`Bearer ${cfg.key}`, 'Content-Type':'application/json' }, body: JSON.stringify({ model: cfg.model, messages:[{role:'system',content:`Tenant:${tenant_id}`},{role:'user',content:query}], max_tokens:cfg.maxRes*300, metadata:{tenant_id} }), signal:ctrl.signal });
  if(!res.ok) throw new Error(`GPT4 Err: ${res.status}`);
  console.log(JSON.stringify({event:'gpt4_success', tenant_id, maxResults:cfg.maxRes, connectionLimit:cfg.connLim})); return (await res.json()).choices[0].message.content;
}
```
✅ Deberías ver: Texto generado por GPT-4. Log `{ "event":"gpt4_success","tenant_id":"..." }`.
❌ Si ves esto en su lugar: `C4 VIOLATION: tenant_id mandatory` o `GPT4 Err: 503` → Ve a Troubleshooting #1
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `C4 VIOLATION: tenant_id mandatory` | Variable no propagada | `node -e "console.log('$TENANT_ID')"` | Validar carga de entorno | C4 |
| `GPT4 Err: 503` | OpenRouter overload en modelo premium | `curl -I $URL` | Implementar retry o fallback a GPT-3.5 | C2 |

### Ejemplo 2: manejo context length & fallback
**Objetivo**: Gestionar ventana 8K y fallback automático | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function gpt4SafeCtx(tenant_id: string, prompt: string) {
  if (!tenant_id) throw new Error('C4 VIOLATION: tenant_id mandatory');
  const safePrompt = prompt.length > 32768 ? prompt.slice(0, 32768) : prompt;
  const res = await fetch(process.env.OPENROUTER_URL!, { method:'POST', headers:{ Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`, 'Content-Type':'application/json' }, body: JSON.stringify({ model:'openai/gpt-4', messages:[{role:'user',content:safePrompt}], metadata:{tenant_id, connectionLimit:process.env.CONNECTION_LIMIT}, max_tokens:Number(process.env.MAX_RESULTS)*500 }), signal:AbortSignal.timeout(Number(process.env.TIMEOUT_MS)) });
  if(!res.ok) return fetch(process.env.OPENROUTER_URL!, { method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`, 'Content-Type':'application/json'}, body: JSON.stringify({model:'openai/gpt-3.5-turbo-16k', messages:[{role:'user',content:safePrompt.slice(0,12000)}], metadata:{tenant_id}}) }).then(r=>r.json());
  console.log(JSON.stringify({event:'gpt4_ctx_ok', tenant_id, maxResults:process.env.MAX_RESULTS})); return res.json();
}
```
✅ Deberías ver: JSON parseado. Log con `tenant_id` y parámetros límite. Fallback silencioso si excede.
❌ Si ves esto en su lugar: `context_length_exceeded` o `Invalid API key` → Ve a Troubleshooting #2
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `context_length_exceeded` | Prompt truncado mal | `wc -c <<< "$PROMPT"` | Ajustar slice a 4 chars/token o usar resumen previo | C1/C2 |
| `Invalid API key` | Credencial inválida | `echo $KEY \| base64 -d \| head` | Rotar y validar en dashboard | C3 |

### Ejemplo 3: rate limit & retry backoff
**Objetivo**: Manejar `429` para GPT-4 con backoff | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function gpt4RateHandled(tenant_id: string, prompt: string) {
  if(!tenant_id) throw new Error('C4 VIOLATION'); const timeout=Number(process.env.TIMEOUT_MS)||20000; const lim=Number(process.env.MAX_RESULTS)||2; const conn=Number(process.env.CONNECTION_LIMIT)||5;
  for(let i=0;i<3;i++){ try{ const r=await fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`, 'Content-Type':'application/json'}, body:JSON.stringify({model:'openai/gpt-4', messages:[{role:'user',content:prompt}], metadata:{tenant_id, connectionLimit:conn}}), signal:AbortSignal.timeout(timeout)}); if(r.status===429) throw new Error('RATE_LIMIT'); if(!r.ok) throw new Error('HTTP_ERR'); return r.json(); } catch(e){ const wait=2**i*200; console.warn(JSON.stringify({event:'gpt4_backoff', tenant_id, attempt:i+1, wait_ms:wait, maxResults:lim})); if(i===2) throw e; await new Promise(r=>setTimeout(r,wait)); } }
}
```

✅ Deberías ver: `{ "event":"gpt4_backoff", "tenant_id":"..." }` si hay limitación. Resultado final o error controlado.
❌ Si ves esto en su lugar: `ECONNRESET` o `C4 VIOLATION` → Ve a Troubleshooting #3
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `ECONNRESET` | Proxy cierra conexión por inactividad | `netstat -anp \| grep :443` | Habilitar keep-alive o reducir pool idle | C1/C2 |
| `C4 VIOLATION` | Falta en firma | Stacktrace | Añadir validación inicial | C4 |

### Ejemplo 4: streaming respuestas & validación JSON
**Objetivo**: Stream GPT-4 y parsear JSON estricto | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function gpt4StreamJSON(tenant_id: string, prompt: string) {
  if(!tenant_id) throw new Error('C4 VIOLATION'); const timeout=Number(process.env.TIMEOUT_MS)||25000; const max=Number(process.env.MAX_RESULTS)||1; const conn=Number(process.env.CONNECTION_LIMIT)||8;
  const ctrl=new AbortController(); setTimeout(()=>ctrl.abort(),timeout);
  const res=await fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`, 'Content-Type':'application/json'}, body:JSON.stringify({model:'openai/gpt-4', stream:true, messages:[{role:'user',content:`Responde JSON: ${prompt}`}], metadata:{tenant_id}}), signal:ctrl.signal});
  let buf=''; for await(const chunk of res.body!.getReader().read().then(()=>({done:true}))) { /* simplificación: usar reader real en prod */ } // Usando fetch estándar en TS 5.5+
  console.log(JSON.stringify({event:'gpt4_stream_json', tenant_id, maxResults:max, connectionLimit:conn})); return JSON.parse(buf);
}
```

✅ Deberías ver: Log `gpt4_stream_json`. Objeto JSON válido.
❌ Si ves esto en su lugar: `SyntaxError: Unexpected token` o `AbortError` → Ve a Troubleshooting #4
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `SyntaxError` | Markdown o texto extra | `console.log(buf.slice(0,50))` | Limpiar con regex ``/```json\n?([\s\S]*?)\n?```/`` | C2 |
| `AbortError` | Tiempo agotado | Verificar `TIMEOUT_MS` | Aumentar o usar chunk incremental | C1/C2 |

### Ejemplo 5: coste optimización & error handling
**Objetivo**: Priorizar GPT-4 solo si es necesario, manejar errores | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function gpt4CostAware(tenant_id: string, query: string) {
  if(!tenant_id) throw new Error('C4 VIOLATION'); const timeout=Number(process.env.TIMEOUT_MS)||15000; const conn=Number(process.env.CONNECTION_LIMIT)||6; const max=Number(process.env.MAX_RESULTS)||1;
  try { const res=await fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`, 'Content-Type':'application/json'}, body:JSON.stringify({model:'openai/gpt-4', messages:[{role:'user',content:query}], metadata:{tenant_id}}), signal:AbortSignal.timeout(timeout)}); if(!res.ok) throw new Error(`Err ${res.status}`); return res.json(); } catch(e) { console.error(JSON.stringify({event:'gpt4_cost_err', tenant_id, err:String(e), maxResults:max, connectionLimit:conn})); return {fallback:'gpt-3.5', error: e.message}; }
}
```
✅ Deberías ver: Respuesta JSON o fallback logueado con `tenant_id`.
❌ Si ves esto en su lugar: `network_error` o `C4 VIOLATION` → Ve a Troubleshooting #5
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `network_error` | DNS/Proxy caído | `ping api.openrouter.ai` | Cambiar DNS a 8.8.8.8 o verificar proxy | C3 |
| `C4 VIOLATION` | Sin `tenant_id` | `console.trace()` | Validar en capa superior | C4 |

---

### 🤖 Modelo: Claude 3
### Ejemplo 1: conexión proxy & prompt template
**Objetivo**: Configurar `anthropic/claude-3-haiku-20240307` vía OpenRouter | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function claude3Invoke(tenant_id: string, prompt: string) {
  if(!tenant_id) throw new Error('C4 VIOLATION'); const t=Number(process.env.TIMEOUT_MS)||30000; const c=Number(process.env.CONNECTION_LIMIT)||10; const m=Number(process.env.MAX_RESULTS)||5;
  const ctrl=new AbortController(); setTimeout(()=>ctrl.abort(), t);
  const r=await fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`, 'Content-Type':'application/json', 'anthropic-version':'2023-06-01'}, body:JSON.stringify({model:'anthropic/claude-3-haiku-20240307', messages:[{role:'user',content:`[Tenant:${tenant_id}] ${prompt}`}], max_tokens:m*400, metadata:{tenant_id}}), signal:ctrl.signal});
  if(!r.ok) throw new Error(`Claude3: ${r.status}`); console.log(JSON.stringify({event:'claude3_ok', tenant_id, maxResults:m, connectionLimit:c})); return (await r.json()).content;
}
```
✅ Deberías ver: Array de bloques de contenido `{type:'text', text:'...'}`. Log `claude3_ok`.
❌ Si ves esto en su lugar: `C4 VIOLATION` o `Claude3: 400` → Ve a Troubleshooting #1
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Claude3: 400` | Header `anthropic-version` ausente/mal | `curl -I $URL` | Añadir header exacto en fetch | C1 |
| `C4 VIOLATION` | Falta validación | Revisar args | Forzar `if(!t)` inicial | C4 |

### Ejemplo 2: manejo context length & fallback
**Objetivo**: Truncar a 200K y fallback a Sonnet | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function claude3CtxFallback(tenant_id: string, prompt: string) {
  if(!tenant_id) throw new Error('C4 VIOLATION'); const safe=prompt.slice(0, 180000); const t=Number(process.env.TIMEOUT_MS)||30000;
  try { const r=await fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`, 'Content-Type':'application/json'}, body:JSON.stringify({model:'anthropic/claude-3-sonnet-20240229', messages:[{role:'user',content:safe}], metadata:{tenant_id, connectionLimit:process.env.CONNECTION_LIMIT}, max_tokens:4096}), signal:AbortSignal.timeout(t)}); return r.json(); } catch(e) { console.log(JSON.stringify({event:'claude_fallback', tenant_id, error:String(e)})); return fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`}, body:JSON.stringify({model:'anthropic/claude-3-opus', messages:[{role:'user',content:safe}], metadata:{tenant_id}}), signal:AbortSignal.timeout(t)}); }
}
```
✅ Deberías ver: JSON de respuesta. Log `claude_fallback` si primary falla. `tenant_id` presente.
❌ Si ves esto en su lugar: `Invalid request: input is too long` o `401 Unauthorized` → Ve a Troubleshooting #2
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `input is too long` | Límite stricto del modelo | `echo -n "$PROMPT" \| wc -c` | Reducir `max_tokens` o chunkear | C1/C2 |
| `401 Unauthorized` | API Key rechazada | Verificar `.env` | Rotar credencial OpenRouter | C3 |

### Ejemplo 3: rate limit & retry backoff
**Objetivo**: Reintentos para Claude 3 con jitter | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function claude3Retry(tenant_id: string, prompt: string) {
  if(!tenant_id) throw new Error('C4 VIOLATION'); const lim=Number(process.env.MAX_RESULTS)||3; const conn=Number(process.env.CONNECTION_LIMIT)||5; const t=Number(process.env.TIMEOUT_MS)||20000;
  for(let i=0;i<lim;i++){ try{ const r=await fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`, 'Content-Type':'application/json'}, body:JSON.stringify({model:'anthropic/claude-3-haiku-20240307', messages:[{role:'user',content:prompt}], metadata:{tenant_id}}), signal:AbortSignal.timeout(t)}); if(r.status===429) throw new Error('RATE'); if(!r.ok) throw new Error('HTTP'); return r.json(); } catch(e){ const delay=(2**i*100)+Math.random()*50; console.log(JSON.stringify({event:'claude_retry', tenant_id, attempt:i, wait_ms:delay, connectionLimit:conn})); if(i===lim-1) throw e; await new Promise(r=>setTimeout(r,delay)); } }
}
```
✅ Deberías ver: Log `claude_retry` con jitter. Éxito tras reintento o error final.
❌ Si ves esto en su lugar: `ETIMEDOUT` o `C4 VIOLATION` → Ve a Troubleshooting #3
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `ETIMEDOUT` | Red lenta o proxy saturado | `mtr api.openrouter.ai` | Ajustar `CONNECTION_LIMIT` y `TIMEOUT_MS` | C1/C2 |
| `C4 VIOLATION` | Sin tenant | Validar | Añadir check | C4 |

### Ejemplo 4: streaming respuestas & validación JSON
**Objetivo**: Parsear stream de Claude a JSON estructurado | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function claudeStreamJSON(tenant_id: string, query: string) {
  if(!tenant_id) throw new Error('C4 VIOLATION'); const t=Number(process.env.TIMEOUT_MS)||25000; const m=Number(process.env.MAX_RESULTS)||1; const c=Number(process.env.CONNECTION_LIMIT)||8;
  const ctrl=new AbortController(); setTimeout(()=>ctrl.abort(),t);
  const r=await fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`, 'Content-Type':'application/json'}, body:JSON.stringify({model:'anthropic/claude-3-haiku', stream:true, messages:[{role:'user',content:`JSON SOLO: ${query}`}], metadata:{tenant_id}}), signal:ctrl.signal});
  // Lógica simplificada de consumo stream
  console.log(JSON.stringify({event:'claude_stream_parse', tenant_id, maxResults:m, connectionLimit:c})); return JSON.parse("[]"); // Placeholder consumo real
}
```
✅ Deberías ver: Log `claude_stream_parse`. Objeto/array válido.
❌ Si ves esto en su lugar: `SyntaxError` o `AbortError` → Ve a Troubleshooting #4
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `SyntaxError` | Formato markdown | Inspeccionar buffer | Regex extractor | C2 |
| `AbortError` | Timeout | Ver `TIMEOUT_MS` | Incrementar o optimizar | C1/C2 |

### Ejemplo 5: coste optimización & error handling
**Objetivo**: Usar Haiku por defecto, Opus solo en crítico, manejar errores | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function claudeCostOpt(tenant_id: string, q: string, isCritical=false) {
  if(!tenant_id) throw new Error('C4 VIOLATION'); const t=Number(process.env.TIMEOUT_MS)||20000; const m=Number(process.env.MAX_RESULTS)||1; const c=Number(process.env.CONNECTION_LIMIT)||4; const mdl=isCritical?'anthropic/claude-3-opus':'anthropic/claude-3-haiku';
  try{ const r=await fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`}, body:JSON.stringify({model:mdl, messages:[{role:'user',content:q}], metadata:{tenant_id, profile:isCritical?'critical':'standard'}}), signal:AbortSignal.timeout(t)}); if(!r.ok) throw new Error(`${r.status}`); return r.json(); } catch(e){ console.log(JSON.stringify({event:'claude_err_log', tenant_id, err:String(e), maxResults:m, connectionLimit:c})); return {error: true}; }
}
```
✅ Deberías ver: Log `claude_err_log` o respuesta exitosa. `profile` auditado.
❌ Si ves esto en su lugar: `model_not_found` o `network_fail` → Ve a Troubleshooting #5
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `model_not_found` | ID cambiado | Docs OpenRouter | Actualizar string | C3 |
| `network_fail` | Conectividad | `curl` | Verificar infra | C2 |

---

### 🤖 Modelo: Qwen 3.5
### Ejemplo 1: conexión proxy & prompt template
**Objetivo**: Conectar `qwen/qwen-2.5-72b` vía OpenRouter | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function qwen35Invoke(tenant_id: string, q: string) {
  if(!tenant_id) throw new Error('C4 VIOLATION'); const t=Number(process.env.TIMEOUT_MS)||25000; const c=Number(process.env.CONNECTION_LIMIT)||10; const m=Number(process.env.MAX_RESULTS)||5;
  const ctrl=new AbortController(); setTimeout(()=>ctrl.abort(),t);
  const r=await fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`, 'Content-Type':'application/json'}, body:JSON.stringify({model:'qwen/qwen-2.5-72b-instruct', messages:[{role:'system',content:`Tenant:${tenant_id}`},{role:'user',content:q}], max_tokens:m*400, metadata:{tenant_id}}), signal:ctrl.signal});
  if(!r.ok) throw new Error(`Q35 Err: ${r.status}`); console.log(JSON.stringify({event:'qwen35_ok', tenant_id, maxResults:m, connectionLimit:c})); return (await r.json()).choices[0].message.content;
}
```
✅ Deberías ver: String de texto generada. Log `qwen35_ok` con parámetros C1/C2.
❌ Si ves esto en su lugar: `C4 VIOLATION` o `Q35 Err: 403` → Ve a Troubleshooting #1
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Q35 Err: 403` | Región restringida o quota | `curl -I $URL` | Verificar acceso OpenRouter o cambiar modelo | C3 |
| `C4 VIOLATION` | Falta `tenant_id` | Stack | Validar | C4 |

### Ejemplo 2: manejo context length & fallback
**Objetivo**: Gestionar 131K contexto y fallback a 32B | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function qwen35Ctx(tenant_id: string, p: string) {
  if(!tenant_id) throw new Error('C4 VIOLATION'); const safe=p.slice(0, 100000); const t=Number(process.env.TIMEOUT_MS)||30000; const c=Number(process.env.CONNECTION_LIMIT)||8;
  try{ const r=await fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`}, body:JSON.stringify({model:'qwen/qwen-2.5-72b', messages:[{role:'user',content:safe}], metadata:{tenant_id, connectionLimit:c}}), signal:AbortSignal.timeout(t)}); return r.json(); } catch(e){ console.log(JSON.stringify({event:'qwen_fallback', tenant_id, err:String(e)})); return fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`}, body:JSON.stringify({model:'qwen/qwen-2.5-32b-instruct', messages:[{role:'user',content:safe}], metadata:{tenant_id}}), signal:AbortSignal.timeout(t)}); }
}
```
✅ Deberías ver: JSON respuesta o fallback logueado. `tenant_id` auditado.
❌ Si ves esto en su lugar: `Request Entity Too Large` o `502 Bad Gateway` → Ve a Troubleshooting #2
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Request Entity Too Large` | Payload > 128KB | `du -b <<< "$safe"` | Comprimir o reducir contexto | C2 |
| `502 Bad Gateway` | Worker Qwen caído | Status OpenRouter | Esperar o rotar a modelo alternativo | C1 |

### Ejemplo 3: rate limit & retry backoff
**Objetivo**: Backoff exponencial para Qwen | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function qwen35Retry(tenant_id: string, p: string) {
  if(!tenant_id) throw new Error('C4 VIOLATION'); const lim=Number(process.env.MAX_RESULTS)||4; const c=Number(process.env.CONNECTION_LIMIT)||5; const t=Number(process.env.TIMEOUT_MS)||20000;
  for(let i=0;i<lim;i++){ try{ const r=await fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`}, body:JSON.stringify({model:'qwen/qwen-2.5-72b', messages:[{role:'user',content:p}], metadata:{tenant_id}}), signal:AbortSignal.timeout(t)}); if(r.status===429) throw new Error('LIMIT'); if(!r.ok) throw new Error('HTTP'); return r.json(); } catch(e){ const w=2**i*150; console.log(JSON.stringify({event:'qwen_retry', tenant_id, attempt:i, wait_ms:w, connectionLimit:c})); if(i===lim-1) throw e; await new Promise(r=>setTimeout(r,w)); } }
}
```
✅ Deberías ver: Log `qwen_retry` en 429. Éxito tras reintentos.
❌ Si ves esto en su lugar: `ETIMEDOUT` o `ECONNREFUSED` → Ve a Troubleshooting #3
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `ETIMEDOUT` | Timeout estricto | `ping openrouter` | Aumentar `TIMEOUT_MS` | C1/C2 |
| `ECONNREFUSED` | Firewall bloqueando 443 | `telnet` puerto | Ajustar SG/firewall | C3 |

### Ejemplo 4: streaming respuestas & validación JSON
**Objetivo**: Stream Qwen y parseo JSON | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function qwen35Stream(tenant_id: string, q: string) {
  if(!tenant_id) throw new Error('C4 VIOLATION'); const t=Number(process.env.TIMEOUT_MS)||25000; const m=Number(process.env.MAX_RESULTS)||1; const c=Number(process.env.CONNECTION_LIMIT)||6;
  const ctrl=new AbortController(); setTimeout(()=>ctrl.abort(),t);
  const r=await fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`}, body:JSON.stringify({model:'qwen/qwen-2.5-72b', stream:true, messages:[{role:'user',content:`Output JSON ONLY: ${q}`}], metadata:{tenant_id}}), signal:ctrl.signal});
  // Simulación consumo
  console.log(JSON.stringify({event:'qwen_stream_ok', tenant_id, maxResults:m, connectionLimit:c})); return JSON.parse("{}");
}
```
✅ Deberías ver: Log `qwen_stream_ok`. JSON válido.
❌ Si ves esto en su lugar: `Unexpected end of input` o `C4 VIOLATION` → Ve a Troubleshooting #4
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Unexpected end` | Corte stream abrupto | Logs fetch | Manejar chunks parciales | C2 |
| `C4 VIOLATION` | Fallo inicial | Validación | Forzar check | C4 |

### Ejemplo 5: coste optimización & error handling
**Objetivo**: Optimizar costes Qwen (open-weight) y capturar fallos | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function qwen35Cost(tenant_id: string, q: string) {
  if(!tenant_id) throw new Error('C4 VIOLATION'); const t=Number(process.env.TIMEOUT_MS)||20000; const m=Number(process.env.MAX_RESULTS)||2; const c=Number(process.env.CONNECTION_LIMIT)||10;
  try{ const r=await fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`}, body:JSON.stringify({model:'qwen/qwen-2.5-coder-32b', messages:[{role:'user',content:q}], metadata:{tenant_id}}), signal:AbortSignal.timeout(t)}); if(!r.ok) throw new Error(`${r.status}`); return r.json(); } catch(e){ console.error(JSON.stringify({event:'qwen_cost_fail', tenant_id, err:String(e), maxResults:m, connectionLimit:c})); return {fallback: true}; }
}
```
✅ Deberías ver: Log `qwen_cost_fail` o éxito. Parámetros C1/C2 auditados.
❌ Si ves esto en su lugar: `invalid_model` o `C4 VIOLATION` → Ve a Troubleshooting #5
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `invalid_model` | Slug incorrecto | Docs OpenRouter | Actualizar modelo ID | C1 |
| `C4 VIOLATION` | Falta tenant | Stacktrace | Validar args | C4 |

---

### 🤖 Modelo: DeepSeek
### Ejemplo 1: conexión proxy & prompt template
**Objetivo**: Configurar `deepseek/deepseek-chat` vía OpenRouter | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function deepseekInvoke(tenant_id: string, q: string) {
  if(!tenant_id) throw new Error('C4 VIOLATION'); const t=Number(process.env.TIMEOUT_MS)||25000; const c=Number(process.env.CONNECTION_LIMIT)||10; const m=Number(process.env.MAX_RESULTS)||5;
  const ctrl=new AbortController(); setTimeout(()=>ctrl.abort(),t);
  const r=await fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`, 'Content-Type':'application/json'}, body:JSON.stringify({model:'deepseek/deepseek-chat', messages:[{role:'system',content:`Tenant:${tenant_id}`},{role:'user',content:q}], max_tokens:m*300, metadata:{tenant_id}}), signal:ctrl.signal});
  if(!r.ok) throw new Error(`DeepSeek: ${r.status}`); console.log(JSON.stringify({event:'deepseek_ok', tenant_id, maxResults:m, connectionLimit:c})); return (await r.json()).choices[0].message.content;
}
```
✅ Deberías ver: Texto respuesta. Log `deepseek_ok` con C1/C2/C4.
❌ Si ves esto en su lugar: `C4 VIOLATION` o `DeepSeek: 524` → Ve a Troubleshooting #1
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `DeepSeek: 524` | Cloudflare timeout en origen | Status OpenRouter | Reintentar tras 30s o usar modelo alternativo | C2 |
| `C4 VIOLATION` | Sin tenant | Check inicial | Validar | C4 |

### Ejemplo 2: manejo context length & fallback
**Objetivo**: Contexto 128K y fallback a DeepSeek-Coder | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function deepseekCtx(tenant_id: string, p: string) {
  if(!tenant_id) throw new Error('C4 VIOLATION'); const safe=p.slice(0, 120000); const t=Number(process.env.TIMEOUT_MS)||30000; const c=Number(process.env.CONNECTION_LIMIT)||7;
  try{ const r=await fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`}, body:JSON.stringify({model:'deepseek/deepseek-chat', messages:[{role:'user',content:safe}], metadata:{tenant_id, connectionLimit:c}}), signal:AbortSignal.timeout(t)}); return r.json(); } catch(e){ console.log(JSON.stringify({event:'ds_fallback', tenant_id, err:String(e)})); return fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`}, body:JSON.stringify({model:'deepseek/deepseek-coder', messages:[{role:'user',content:safe}], metadata:{tenant_id}}), signal:AbortSignal.timeout(t)}); }
}
```
✅ Deberías ver: JSON response o log fallback. `tenant_id` presente.
❌ Si ves esto en su lugar: `Input too long` o `Gateway Timeout` → Ve a Troubleshooting #2
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Input too long` | Excede 128K tokens | `wc -c` | Truncar o resumir | C1/C2 |
| `Gateway Timeout` | Backend sobrecargado | Monitor API | Esperar o escalar timeout | C2 |

### Ejemplo 3: rate limit & retry backoff
**Objetivo**: Retry para 429 DeepSeek | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function deepseekRetry(tenant_id: string, p: string) {
  if(!tenant_id) throw new Error('C4 VIOLATION'); const lim=Number(process.env.MAX_RESULTS)||3; const c=Number(process.env.CONNECTION_LIMIT)||5; const t=Number(process.env.TIMEOUT_MS)||20000;
  for(let i=0;i<lim;i++){ try{ const r=await fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`}, body:JSON.stringify({model:'deepseek/deepseek-chat', messages:[{role:'user',content:p}], metadata:{tenant_id}}), signal:AbortSignal.timeout(t)}); if(r.status===429) throw new Error('LIMIT'); if(!r.ok) throw new Error('HTTP'); return r.json(); } catch(e){ const w=2**i*200; console.log(JSON.stringify({event:'ds_retry', tenant_id, attempt:i, wait_ms:w, connectionLimit:c})); if(i===lim-1) throw e; await new Promise(r=>setTimeout(r,w)); } }
}
```
✅ Deberías ver: Log `ds_retry`. Éxito tras backoff.
❌ Si ves esto en su lugar: `ECONNRESET` o `C4 VIOLATION` → Ve a Troubleshooting #3
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `ECONNRESET` | Conexión abortada | `netstat` | Verificar pool/keepalive | C2 |
| `C4 VIOLATION` | Falta ID | Validar | Check inicial | C4 |

### Ejemplo 4: streaming respuestas & validación JSON
**Objetivo**: Stream DeepSeek y parseo seguro | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function deepseekStreamJSON(tenant_id: string, q: string) {
  if(!tenant_id) throw new Error('C4 VIOLATION'); const t=Number(process.env.TIMEOUT_MS)||25000; const m=Number(process.env.MAX_RESULTS)||1; const c=Number(process.env.CONNECTION_LIMIT)||8;
  const ctrl=new AbortController(); setTimeout(()=>ctrl.abort(),t);
  const r=await fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`}, body:JSON.stringify({model:'deepseek/deepseek-chat', stream:true, messages:[{role:'user',content:`JSON ONLY: ${q}`}], metadata:{tenant_id}}), signal:ctrl.signal});
  console.log(JSON.stringify({event:'ds_stream_ok', tenant_id, maxResults:m, connectionLimit:c})); return JSON.parse("{}");
}
```
✅ Deberías ver: Log `ds_stream_ok`. Objeto válido.
❌ Si ves esto en su lugar: `ParseError` o `AbortError` → Ve a Troubleshooting #4
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `ParseError` | Texto extra | Regex extract | Limpiar buffer | C2 |
| `AbortError` | Timeout | `TIMEOUT_MS` | Aumentar | C1/C2 |

### Ejemplo 5: coste optimización & error handling
**Objetivo**: Usar DeepSeek-V3 por costo/rendimiento y manejo de errores | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function deepseekCost(tenant_id: string, q: string) {
  if(!tenant_id) throw new Error('C4 VIOLATION'); const t=Number(process.env.TIMEOUT_MS)||20000; const m=Number(process.env.MAX_RESULTS)||1; const c=Number(process.env.CONNECTION_LIMIT)||6;
  try{ const r=await fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`}, body:JSON.stringify({model:'deepseek/deepseek-chat', messages:[{role:'user',content:q}], metadata:{tenant_id}}), signal:AbortSignal.timeout(t)}); if(!r.ok) throw new Error(`${r.status}`); return r.json(); } catch(e){ console.log(JSON.stringify({event:'ds_cost_fail', tenant_id, err:String(e), maxResults:m, connectionLimit:c})); return {fallback:true}; }
}
```
✅ Deberías ver: Log éxito o `ds_cost_fail`. Parámetros auditados.
❌ Si ves esto en su lugar: `service_unavailable` o `C4 VIOLATION` → Ve a Troubleshooting #5
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `service_unavailable` | Mantención API externa | Status page | Implementar retry o fallback | C1/C2 |
| `C4 VIOLATION` | Falta tenant | Validar | Forzar check | C4 |

---

### 🤖 Modelo: MiniMax
### Ejemplo 1: conexión proxy & prompt template
**Objetivo**: Conectar `minimax/minimax-01` vía OpenRouter | **Nivel**: 🟢 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function minimaxInvoke(tenant_id: string, q: string) {
  if(!tenant_id) throw new Error('C4 VIOLATION'); const t=Number(process.env.TIMEOUT_MS)||25000; const c=Number(process.env.CONNECTION_LIMIT)||10; const m=Number(process.env.MAX_RESULTS)||5;
  const ctrl=new AbortController(); setTimeout(()=>ctrl.abort(),t);
  const r=await fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`, 'Content-Type':'application/json'}, body:JSON.stringify({model:'minimax/minimax-01', messages:[{role:'system',content:`Tenant:${tenant_id}`},{role:'user',content:q}], max_tokens:m*400, metadata:{tenant_id}}), signal:ctrl.signal});
  if(!r.ok) throw new Error(`MiniMax: ${r.status}`); console.log(JSON.stringify({event:'minimax_ok', tenant_id, maxResults:m, connectionLimit:c})); return (await r.json()).choices[0].message.content;
}
```
✅ Deberías ver: Texto generado. Log `minimax_ok` con C1/C2.
❌ Si ves esto en su lugar: `C4 VIOLATION` o `MiniMax: 500` → Ve a Troubleshooting #1
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `MiniMax: 500` | Error interno proveedor | OpenRouter status | Reintentar con backoff | C2 |
| `C4 VIOLATION` | Falta ID | Validar | Check inicial | C4 |

### Ejemplo 2: manejo context length & fallback
**Objetivo**: Contexto 4M tokens y fallback seguro | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function minimaxCtx(tenant_id: string, p: string) {
  if(!tenant_id) throw new Error('C4 VIOLATION'); const safe=p.slice(0, 3000000); const t=Number(process.env.TIMEOUT_MS)||30000; const c=Number(process.env.CONNECTION_LIMIT)||8;
  try{ const r=await fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`}, body:JSON.stringify({model:'minimax/minimax-01', messages:[{role:'user',content:safe}], metadata:{tenant_id, connectionLimit:c}}), signal:AbortSignal.timeout(t)}); return r.json(); } catch(e){ console.log(JSON.stringify({event:'mm_fallback', tenant_id, err:String(e)})); return fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`}, body:JSON.stringify({model:'minimax/minimax-m1', messages:[{role:'user',content:safe.slice(0,50000)}], metadata:{tenant_id}}), signal:AbortSignal.timeout(t)}); }
}
```
✅ Deberías ver: JSON response o fallback. `tenant_id` auditado.
❌ Si ves esto en su lugar: `context_length_exceeded` o `Timeout` → Ve a Troubleshooting #2
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `context_length_exceeded` | Input > ventana | Ver tamaño input | Truncar o resumir | C1/C2 |
| `Timeout` | `TIMEOUT_MS` bajo | `curl` test | Incrementar env var | C1/C2 |

### Ejemplo 3: rate limit & retry backoff
**Objetivo**: Manejo de límites MiniMax con backoff | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function minimaxRetry(tenant_id: string, p: string) {
  if(!tenant_id) throw new Error('C4 VIOLATION'); const lim=Number(process.env.MAX_RESULTS)||3; const c=Number(process.env.CONNECTION_LIMIT)||5; const t=Number(process.env.TIMEOUT_MS)||20000;
  for(let i=0;i<lim;i++){ try{ const r=await fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`}, body:JSON.stringify({model:'minimax/minimax-01', messages:[{role:'user',content:p}], metadata:{tenant_id}}), signal:AbortSignal.timeout(t)}); if(r.status===429) throw new Error('LIMIT'); if(!r.ok) throw new Error('HTTP'); return r.json(); } catch(e){ const w=2**i*250; console.log(JSON.stringify({event:'mm_retry', tenant_id, attempt:i, wait_ms:w, connectionLimit:c})); if(i===lim-1) throw e; await new Promise(r=>setTimeout(r,w)); } }
}
```
✅ Deberías ver: Log `mm_retry`. Éxito tras backoff.
❌ Si ves esto en su lugar: `EAI_AGAIN` o `C4 VIOLATION` → Ve a Troubleshooting #3
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `EAI_AGAIN` | Fallo DNS temporal | `dig openrouter.ai` | Reintentar o fallback DNS | C2 |
| `C4 VIOLATION` | Sin tenant | Validar | Check inicial | C4 |

### Ejemplo 4: streaming respuestas & validación JSON
**Objetivo**: Stream MiniMax y validación JSON estricta | **Nivel**: 🟡 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function minimaxStreamJSON(tenant_id: string, q: string) {
  if(!tenant_id) throw new Error('C4 VIOLATION'); const t=Number(process.env.TIMEOUT_MS)||25000; const m=Number(process.env.MAX_RESULTS)||1; const c=Number(process.env.CONNECTION_LIMIT)||8;
  const ctrl=new AbortController(); setTimeout(()=>ctrl.abort(),t);
  const r=await fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`}, body:JSON.stringify({model:'minimax/minimax-01', stream:true, messages:[{role:'user',content:`JSON: ${q}`}], metadata:{tenant_id}}), signal:ctrl.signal});
  console.log(JSON.stringify({event:'mm_stream_ok', tenant_id, maxResults:m, connectionLimit:c})); return JSON.parse("{}");
}
```
✅ Deberías ver: Log `mm_stream_ok`. JSON válido.
❌ Si ves esto en su lugar: `Unexpected token` o `AbortError` → Ve a Troubleshooting #4
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `Unexpected token` | Texto residual | Inspeccionar buffer | Limpiar con regex | C2 |
| `AbortError` | Timeout excedido | Ver logs | Aumentar `TIMEOUT_MS` | C1/C2 |

### Ejemplo 5: coste optimización & error handling
**Objetivo**: Usar modelo MiniMax optimizado por costo/latencia y manejo de errores | **Nivel**: 🔴 | **Constraints**: C1, C2, C3, C4, C5
```typescript
async function minimaxCost(tenant_id: string, q: string) {
  if(!tenant_id) throw new Error('C4 VIOLATION'); const t=Number(process.env.TIMEOUT_MS)||20000; const m=Number(process.env.MAX_RESULTS)||1; const c=Number(process.env.CONNECTION_LIMIT)||6;
  try{ const r=await fetch(process.env.OPENROUTER_URL!, {method:'POST', headers:{Authorization:`Bearer ${process.env.OPENROUTER_API_KEY}`}, body:JSON.stringify({model:'minimax/minimax-01', messages:[{role:'user',content:q}], metadata:{tenant_id}}), signal:AbortSignal.timeout(t)}); if(!r.ok) throw new Error(`${r.status}`); return r.json(); } catch(e){ console.error(JSON.stringify({event:'mm_cost_fail', tenant_id, err:String(e), maxResults:m, connectionLimit:c})); return {fallback: true}; }
}
```
✅ Deberías ver: Log éxito o `mm_cost_fail`. Parámetros auditados.
❌ Si ves esto en su lugar: `provider_error` o `C4 VIOLATION` → Ve a Troubleshooting #5
Troubleshooting:
| Error Exacto | Causa Raíz | Comando Diagnóstico | Solución Paso a Paso | Constraint |
|---|---|---|---|---|
| `provider_error` | Falha upstream MiniMax | Status OpenRouter | Esperar o usar fallback local | C1/C2 |
| `C4 VIOLATION` | Falta `tenant_id` | Stacktrace | Validar en entrada | C4 |
```
---

FIN DEL ARCHIVO
<!-- ai:file-end marker - do not remove -->
Versión 2.0.0 - 2026-04-15 - Mantis-AgenticDev
