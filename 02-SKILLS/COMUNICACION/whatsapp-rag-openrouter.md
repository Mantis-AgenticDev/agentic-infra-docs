---
title: "whatsapp-rag-openrouter.md"
category: "Skill"
domain: ["comunicacion", "ai", "base-de-datos-rag"]
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
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

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

**Objetivo en 5 minutos:** Conectar un bot de WhatsApp (vía UAZapi) con un sistema RAG que consulta Qdrant y bases de datos SQL/NoSQL, usando modelos de OpenRouter (GPT, Claude, etc.) para responder con contexto empresarial.

**Pasos resumidos:**

1. **Requisitos previos:** Tener funcionando UAZapi ([[whatsapp-uazapi-integration.md]]) y Qdrant local ([[qdrant-rag-ingestion.md]]).
2. **Clonar el repositorio de plantillas:**  
   `git clone https://github.com/Mantis-AgenticDev/agentic-service-templates.git`
3. **Configurar variables de entorno** según [[environment-variable-management.md]]:
   ```bash
   cp .env.example .env
   # Editar con OPENROUTER_API_KEY, UAZAPI_TOKEN, QDRANT_URL, DB_TYPE=postgresql|mysql|sqlite, etc.
   ```
4. **Ejecutar el adaptador de base de datos correspondiente** (ver ejemplos en sección 🛠️).
5. **Probar el flujo básico:** Enviar mensaje de WhatsApp → RAG busca en Qdrant + DB → OpenRouter genera respuesta → Enviar respuesta.

**⚠️ Advertencia para Junior:** Nunca expongas Qdrant o tu base de datos a internet sin túnel SSH (C3). Usa `ssh -L 6333:localhost:6333 user@vps` para desarrollo local.

---

## 🎯 Propósito y Alcance

Este skill documenta **patrones productivos y educativos** para construir agentes conversacionales sobre WhatsApp que combinan:

- **RAG (Retrieval-Augmented Generation)** con Qdrant como vector store principal.
- **Múltiples fuentes de datos estructuradas y semiestructuradas**: PostgreSQL, MySQL, Supabase, SQLite (referido como ChromeDB), Google Sheets, Airtable, Google Drive (vía OCR), y Prisma como ORM.
- **Inferencia cloud** a través de OpenRouter, con modelos: GPT-4o, Claude 3.5 Sonnet, Qwen 2.5, DeepSeek-V3, MiniMax-Text-01.
- **Aislamiento multi-tenant** obligatorio (C4) mediante `tenant_id` en cada interacción.

**No cubre:** Implementación del cliente de WhatsApp (asumimos UAZapi o similar), configuración inicial de VPS (ver [[vps-interconnection.md]]), ni despliegue de modelos locales (prohibido por C6).

**Audiencia:** Desarrolladores junior que ya comprenden APIs REST y manejo básico de Node.js/Python, pero necesitan guías concretas para integrar todos los componentes sin exceder recursos limitados de VPS (C1/C2).

---

## 📐 Fundamentos (De 0 a Intermedio)

### Teoría: ¿Qué es RAG y por qué usarlo con WhatsApp?

**Definición:** RAG es una técnica que **inyecta conocimiento externo** al prompt de un LLM en tiempo de inferencia, recuperando documentos o datos relevantes de una base de conocimiento vectorial (Qdrant) y/o bases de datos tradicionales.

**¿Por qué importa?** Los LLMs tienen fecha de corte y alucinan datos privados. Para un agente de restaurante, hotel o clínica odontológica (verticales MANTIS), necesitas respuestas basadas en el menú actual, disponibilidad de habitaciones o historial de citas.

**¿Cómo se implementa en MANTIS?**
1. **Ingesta previa:** Documentos PDF, registros SQL, filas de Google Sheets → se convierten en vectores (embeddings) y se almacenan en Qdrant con payload que incluye `tenant_id` y `source_type`.
2. **En tiempo de consulta (WhatsApp):**
   - Se recibe mensaje del usuario (ej: "¿hay mesa para 4 esta noche?").
   - Se genera embedding de la pregunta.
   - Se busca en Qdrant con filtro `tenant_id`.
   - Paralelamente, se consulta la base de datos operativa (PostgreSQL/MySQL) para disponibilidad real.
   - Se combinan resultados en un contexto.
   - Se envía a OpenRouter con instrucciones precisas.
3. **Respuesta:** El LLM sintetiza y responde con datos actualizados.

**¿Qué falla si se omite?**
- **Sin Qdrant:** El LLM responde con conocimiento genérico o inventa ("alucina").
- **Sin filtro tenant_id (C4):** Un restaurante podría ver datos de otro → violación de privacidad catastrófica.
- **Sin límites de recursos (C1/C2):** La consulta concurrente a BD + Qdrant + LLM puede colapsar el VPS de 4GB.

### Componentes clave y su interacción

| Componente | Rol | Constraint asociado |
|------------|-----|---------------------|
| **UAZapi** | Webhook que recibe mensajes de WhatsApp y envía respuestas | C3 (no exponer token) |
| **Qdrant** | Vector store para búsqueda semántica de documentos y registros | C1, C3 |
| **PostgreSQL/MySQL** | Fuente de verdad transaccional (reservas, pedidos) | C1, C2, C3, C4 |
| **Prisma** | ORM para acceder a SQL de forma tipada | - |
| **Supabase** | Backend-as-a-Service (PostgreSQL + APIs auto-generadas) | C3 (manejo de anon key) |
| **Google APIs** | Sheets, Drive (documentos), Airtable | C3, C6 (cuotas) |
| **OpenRouter** | Proxy unificado para múltiples LLMs cloud | C6 |
| **Embeddings** | `text-embedding-3-small` (OpenAI) o `bge-m3` (vía API) | C2 (una vCPU) |

### Flujo de datos simplificado (diagrama ASCII)

```
[WhatsApp User] --> (UAZapi) --> [Webhook Server :3000]
                                      |
                                      v
                              [Orchestrator Agent]
                                      |
         +----------------------------+----------------------------+
         |                            |                            |
         v                            v                            v
   [Qdrant Search]            [SQL Connector]            [Google/Airtable API]
   (vector similarity)         (Prisma / raw)             (OAuth2 / API Key)
         |                            |                            |
         +--------------+-------------+----------------------------+
                        |
                        v
              [Context Assembler] (limita tokens a 3000)
                        |
                        v
              [OpenRouter API] (GPT-4o / Claude / DeepSeek)
                        |
                        v
              [Response Formatter] --> UAZapi --> WhatsApp User
```

---

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

### Aplicación de Constraints C1 y C2

**C1: Máx 4GB RAM/VPS, operaciones limitadas a 75% de recursos.**
**C2: Máx 1 vCPU por operación crítica.**

**Implicaciones prácticas para este skill:**

1. **Concurrencia limitada:** El servidor webhook (Node.js/Python) debe manejar máximo **3-5 peticiones simultáneas** para evitar OOM (Out of Memory).
   - **Solución:** Usar cola de trabajos en memoria o BullMQ con Redis (ver [[redis-session-management.md]]), limitando workers a 1 por tipo de operación pesada.

2. **Procesamiento de embeddings:** La generación de embeddings (para preguntas del usuario) debe ser asíncrona y no bloqueante. Si usas `text-embedding-3-small` vía API, el costo en CPU local es mínimo (solo I/O de red), cumpliendo C2.

3. **Conexiones a bases de datos:**
   - **Pool de conexiones:** Limitar estrictamente el número de conexiones concurrentes a PostgreSQL/MySQL.
     ```prisma
     // schema.prisma
     datasource db {
       provider = "postgresql"
       url      = env("DATABASE_URL")
       connectionLimit = 5 // Máximo para VPS de 4GB
     }
     ```
   - **Qdrant:** Ejecutar con `docker run` limitando memoria a `1.5GB` y CPUs a `0.5`.
     ```bash
     docker run -d --name qdrant \
       --memory="1.5g" --cpus="0.5" \
       -p 6333:6333 qdrant/qdrant
     ```

4. **Uso de `nice` y `ionice` para procesos batch (C1):**
   - La ingesta masiva de documentos a Qdrant (scripts de sincronización) debe ejecutarse con baja prioridad:
     ```bash
     nice -n 19 ionice -c 3 node scripts/ingest-google-drive.js
     ```

5. **Systemd slice para el webhook:**
   ```ini
   # /etc/systemd/system/whatsapp-rag.service
   [Service]
   CPUQuota=50%
   MemoryMax=1.5G
   MemoryHigh=1.2G
   TasksMax=50
   ```

### Estrategia de caché para reducir carga

- **Redis (local o remoto):** Cachear respuestas frecuentes con TTL de 5 minutos.
- **Qdrant:** Usar `"exact": false` para búsqueda aproximada más rápida con menor CPU.

---

## 🔗 Integración con Stack Existente (n8n, Qdrant, EspoCRM)

### Conexión con n8n (Orquestación de workflows)

Si el agente WhatsApp requiere lógica compleja (ej: confirmar reserva en EspoCRM después de consulta RAG), puedes delegar a n8n mediante webhooks.

**Flujo híbrido:**
1. Webhook de WhatsApp recibe "Quiero reservar para 4 personas mañana".
2. Servicio RAG determina intención y extrae entidades (fecha, personas).
3. Si la intención es "reserva", se envía payload a **webhook de n8n**.
4. n8n ejecuta workflow: consulta disponibilidad en PostgreSQL → crea registro en EspoCRM → envía confirmación por Gmail ([[gmail-smtp-integration.md]]).

**Código de invocación a n8n (respetando C3 con túnel SSH si n8n está en otro VPS):**
```javascript
// Asegurar que n8n solo escucha en localhost
const response = await fetch('http://localhost:5678/webhook/reservas', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ tenant_id, data })
});
```

### Qdrant y multi-tenancy (C4)

**Regla de oro:** Cada colección en Qdrant puede ser única por tenant, o usar payload filtering. Para VPS pequeño, **payload filtering** es más eficiente en RAM.

Ejemplo de punto en Qdrant:
```json
{
  "id": "doc-123",
  "vector": [0.12, -0.34, ...],
  "payload": {
    "tenant_id": "restaurante_la_casona",
    "source": "menu_pdf",
    "text": "Risotto de hongos porcini - $280"
  }
}
```

Al buscar:
```python
from qdrant_client import QdrantClient
client = QdrantClient(host="localhost", port=6333)

hits = client.search(
    collection_name="knowledge_base",
    query_vector=query_embedding,
    query_filter={
        "must": [
            {"key": "tenant_id", "match": {"value": "restaurante_la_casona"}}
        ]
    },
    limit=5
)
```

### EspoCRM como fuente de datos RAG

Si el conocimiento operativo está en EspoCRM (contactos, cuentas), puedes ingestar registros periódicamente a Qdrant usando [[espocrm-api-analytics.md]].

**Ejemplo de script de ingesta (respetando C2 - ejecutar con `nice`):**
```python
import requests
from qdrant_client import QdrantClient
from openai import OpenAI

# Obtener cuentas de EspoCRM
resp = requests.get('https://espocrm.mi-dominio.com/api/v1/Account', 
                    headers={'X-Api-Key': os.getenv('ESPOCRM_API_KEY')})
accounts = resp.json()['list']

# Generar embeddings y subir a Qdrant
for acc in accounts:
    text = f"Cliente: {acc['name']}, Email: {acc['emailAddress']}"
    embedding = openai.embeddings.create(input=text, model="text-embedding-3-small")
    client.upsert(
        collection_name="crm_kb",
        points=[{
            "id": acc['id'],
            "vector": embedding.data[0].embedding,
            "payload": {"tenant_id": tenant_id, "type": "account", "text": text}
        }]
    )
```

---

## 🛠️ 10 Ejemplos de Implementación por Base de Datos (Copy-Paste Validables)

**Nota pedagógica:** Cada ejemplo asume que tienes un proyecto Node.js (TypeScript) con dependencias instaladas (`@qdrant/js-client-rest`, `@prisma/client`, `openai`, `axios`, etc.). Las variables de entorno se cargan según [[environment-variable-management.md]].

### Sección 1: Qdrant (Vector Store)

#### Ejemplo Q1: Búsqueda semántica simple con filtro de tenant

**Objetivo**: Recuperar los 3 fragmentos más relevantes de la base de conocimiento de un tenant específico.

**Nivel**: 🟢

```typescript
// qdrant/search.ts
import { QdrantClient } from "@qdrant/js-client-rest";
import OpenAI from "openai";

const qdrant = new QdrantClient({ url: process.env.QDRANT_URL });
const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

export async function searchKnowledgeBase(
  tenantId: string,
  query: string,
  limit = 3
) {
  // 1. Generar embedding de la consulta
  const emb = await openai.embeddings.create({
    model: "text-embedding-3-small",
    input: query,
  });
  const vector = emb.data[0].embedding;

  // 2. Buscar en Qdrant con filtro tenant_id (C4)
  const results = await qdrant.search("knowledge_base", {
    vector: vector,
    limit: limit,
    filter: {
      must: [{ key: "tenant_id", match: { value: tenantId } }],
    },
  });

  return results.map((hit) => hit.payload?.text || "");
}
```

✅ **Deberías ver:** Un array de strings con los textos recuperados.
❌ **Si ves esto en su lugar:** `Error: Collection knowledge_base not found`
→ Ve a Troubleshooting #Q1

🔗 **Conceptos relacionados:** [[qdrant-rag-ingestion.md]], [[multi-tenant-data-isolation.md]]

#### Ejemplo Q2: Ingesta de texto plano con payload enriquecido

**Objetivo**: Insertar un nuevo fragmento de conocimiento con metadatos.

**Nivel**: 🟢

```typescript
// qdrant/ingest.ts
import { QdrantClient } from "@qdrant/js-client-rest";
import { v4 as uuidv4 } from "uuid";

export async function ingestText(
  tenantId: string,
  text: string,
  source: string,
  embedding: number[]
) {
  const pointId = uuidv4();
  await qdrant.upsert("knowledge_base", {
    wait: true,
    points: [
      {
        id: pointId,
        vector: embedding,
        payload: {
          tenant_id: tenantId,
          source: source,
          text: text,
          ingested_at: new Date().toISOString(),
        },
      },
    ],
  });
  return pointId;
}
```

✅ **Deberías ver:** Retorna el UUID del punto insertado.
❌ **Si ves:** `Error: Validation error: wrong vector dimension`
→ Ve a Troubleshooting #Q2

🔗 **Conceptos relacionados:** [[pdf-mistralocr-processing.md]]

#### Ejemplo Q3: Scroll paginado para actualización masiva

**Objetivo**: Recorrer todos los puntos de una colección para actualizar metadatos (ej: cambiar `source`).

**Nivel**: 🟡

```typescript
// qdrant/scroll-update.ts
async function updateSourceField(tenantId: string, oldSource: string, newSource: string) {
  let offset: string | number | null = null;
  let hasMore = true;

  while (hasMore) {
    const response = await qdrant.scroll("knowledge_base", {
      filter: {
        must: [
          { key: "tenant_id", match: { value: tenantId } },
          { key: "source", match: { value: oldSource } },
        ],
      },
      limit: 100,
      offset: offset,
      with_payload: true,
      with_vector: false, // No traer vectores para ahorrar ancho de banda (C1)
    });

    const points = response.points;
    if (points.length === 0) break;

    // Actualizar payload en lote
    await qdrant.setPayload("knowledge_base", {
      payload: { source: newSource },
      points: points.map(p => p.id),
    });

    offset = response.next_page_offset;
    hasMore = offset !== null;
  }
}
```

✅ **Deberías ver:** Proceso silencioso sin errores.
❌ **Si ves:** `Error: Offset type mismatch`
→ Ve a Troubleshooting #Q3

🔗 **Conceptos relacionados:** [[rag-system-updates-all-engines.md]]

#### Ejemplo Q4: Recomendación por similitud (ítems similares)

**Objetivo**: Dado un ítem existente (ej: un producto), encontrar productos similares.

**Nivel**: 🟡

```typescript
// qdrant/recommend.ts
async function recommendSimilar(tenantId: string, positiveItemId: string) {
  // Obtener el vector del ítem positivo
  const points = await qdrant.retrieve("knowledge_base", {
    ids: [positiveItemId],
    with_vector: true,
  });
  if (points.length === 0) throw new Error("Item no encontrado");
  const positiveVector = points[0].vector as number[];

  const results = await qdrant.recommend("knowledge_base", {
    positive: [positiveVector],
    limit: 5,
    filter: {
      must: [{ key: "tenant_id", match: { value: tenantId } }],
    },
  });
  return results;
}
```

✅ **Deberías ver:** Lista de puntos similares (excluyendo el positivo).
❌ **Si ves:** `Error: Unexpected recommend argument`
→ Ve a Troubleshooting #Q4

🔗 **Conceptos relacionados:** Qdrant API Reference

#### Ejemplo Q5: Borrado por filtro (limpieza de tenant)

**Objetivo**: Eliminar todos los puntos de un tenant específico (útil para reseteo o baja).

**Nivel**: 🟡

```typescript
// qdrant/delete-tenant.ts
async function deleteTenantData(tenantId: string) {
  await qdrant.delete("knowledge_base", {
    filter: {
      must: [{ key: "tenant_id", match: { value: tenantId } }],
    },
  });
}
```

✅ **Deberías ver:** Confirmación de borrado.
❌ **Si ves:** `Error: Delete operation timeout`
→ Ve a Troubleshooting #Q5

#### Ejemplo Q6: Creación de colección con índices personalizados

**Objetivo**: Inicializar una colección Qdrant optimizada para filtros por `tenant_id`.

**Nivel**: 🟢

```typescript
// qdrant/create-collection.ts
await qdrant.createCollection("knowledge_base", {
  vectors: {
    size: 1536, // text-embedding-3-small dimension
    distance: "Cosine",
  },
  optimizers_config: {
    default_segment_number: 2,
    memmap_threshold: 20000, // para VPS con poca RAM (C1)
  },
  hnsw_config: {
    m: 16,
    ef_construct: 100,
  },
});
// Crear índice de payload sobre tenant_id para acelerar filtros
await qdrant.createPayloadIndex("knowledge_base", {
  field_name: "tenant_id",
  field_schema: "keyword",
});
```

✅ **Deberías ver:** `{ result: true, status: "ok", time: ... }`
❌ **Si ves:** `Error: Collection already exists`
→ Simplemente ignora o usa `getCollections()` para verificar.

🔗 **Conceptos relacionados:** [[qdrant-rag-ingestion.md]]

#### Ejemplo Q7: Búsqueda híbrida (vector + filtro por fecha)

**Objetivo**: Buscar documentos de los últimos 7 días con similitud semántica.

**Nivel**: 🟡

```typescript
// qdrant/hybrid-search.ts
const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

const results = await qdrant.search("knowledge_base", {
  vector: queryVector,
  limit: 5,
  filter: {
    must: [
      { key: "tenant_id", match: { value: tenantId } },
      { key: "ingested_at", range: { gte: sevenDaysAgo } }
    ],
  },
});
```

✅ **Deberías ver:** Solo puntos recientes.
❌ **Si ves:** `Error: Field ingested_at has no index`
→ Ve a Troubleshooting #Q7

#### Ejemplo Q8: Conteo de puntos por tenant

**Objetivo**: Monitorear uso de Qdrant por tenant.

**Nivel**: 🟢

```typescript
// qdrant/count.ts
const count = await qdrant.count("knowledge_base", {
  filter: {
    must: [{ key: "tenant_id", match: { value: tenantId } }],
  },
  exact: true, // Cuenta exacta, puede ser lento con muchos puntos
});
console.log(`Tenant ${tenantId} tiene ${count.count} puntos`);
```

✅ **Deberías ver:** Número entero.
❌ **Si ves:** `Error: Filter must be an object` → Revisar sintaxis del filtro.

#### Ejemplo Q9: Actualización de vectores sin re-ingestar payload

**Objetivo**: Cambiar modelo de embedding sin perder payload.

**Nivel**: 🔴

```typescript
// qdrant/update-vectors.ts
// Recorrer puntos, re-generar embedding con nuevo modelo, actualizar solo vector.
let offset = null;
do {
  const batch = await qdrant.scroll("knowledge_base", {
    limit: 100,
    offset,
    with_payload: true,
    with_vector: false,
  });
  for (const point of batch.points) {
    const newEmbedding = await generateNewEmbedding(point.payload.text);
    await qdrant.updateVectors("knowledge_base", {
      points: [{ id: point.id, vector: newEmbedding }],
    });
  }
  offset = batch.next_page_offset;
} while (offset);
```

✅ **Deberías ver:** Progreso lento pero exitoso.
❌ **Si ves:** `Error: Wrong vector dimension` → El nuevo modelo tiene otra dimensión. Necesitas recrear colección.

#### Ejemplo Q10: Snapshots para backup (C5)

**Objetivo**: Crear snapshot de colección para respaldo cifrado.

**Nivel**: 🟡

```bash
# En el servidor, vía API de Qdrant
curl -X POST http://localhost:6333/collections/knowledge_base/snapshots
# Descargar el snapshot generado (ubicación en ./snapshots/knowledge_base/...)
# Luego encriptar con age (ver [[backup-encryption.md]])
tar czf - qdrant_snapshot.snapshot | age -r age1... > snapshot.tar.gz.age
```

✅ **Deberías ver:** Archivo `.snapshot` en el directorio de snapshots de Qdrant.

---

### Sección 2: PostgreSQL + Prisma (ORM)

#### Ejemplo P1: Consulta tipada para disponibilidad de mesas

**Objetivo**: Verificar disponibilidad real en base de datos transaccional.

**Nivel**: 🟢

```prisma
// prisma/schema.prisma
model Mesa {
  id        Int      @id @default(autoincrement())
  tenant_id String   @map("tenant_id")
  numero    Int
  capacidad Int
  reservas  Reserva[]
}

model Reserva {
  id         Int      @id @default(autoincrement())
  tenant_id  String   @map("tenant_id")
  mesa_id    Int
  fecha      DateTime
  personas   Int
  mesa       Mesa     @relation(fields: [mesa_id], references: [id])
}
```

```typescript
// db/queries.ts
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

export async function mesasDisponibles(tenantId: string, fecha: Date, personas: number) {
  const mesas = await prisma.mesa.findMany({
    where: {
      tenant_id: tenantId,
      capacidad: { gte: personas },
      reservas: {
        none: {
          fecha: {
            gte: new Date(fecha.setHours(0,0,0,0)),
            lt: new Date(fecha.setHours(23,59,59,999))
          }
        }
      }
    },
    select: { numero: true, capacidad: true }
  });
  return mesas;
}
```

✅ **Deberías ver:** Array de objetos `{ numero: 5, capacidad: 6 }`.
❌ **Si ves:** `PrismaClientValidationError` → Probablemente campo `tenant_id` faltante en where.

🔗 **Conceptos relacionados:** [[postgres-prisma-rag.md]]

#### Ejemplo P2: Transacción con Prisma para reserva atómica

**Objetivo**: Crear reserva evitando overbooking (race condition).

**Nivel**: 🟡

```typescript
async function crearReserva(tenantId: string, mesaId: number, fecha: Date, personas: number) {
  return await prisma.$transaction(async (tx) => {
    // Verificar disponibilidad dentro de transacción
    const conflicto = await tx.reserva.findFirst({
      where: {
        tenant_id: tenantId,
        mesa_id: mesaId,
        fecha: {
          gte: new Date(fecha.setHours(0,0,0,0)),
          lt: new Date(fecha.setHours(23,59,59,999))
        }
      }
    });
    if (conflicto) throw new Error("Mesa no disponible");

    return tx.reserva.create({
      data: {
        tenant_id: tenantId,
        mesa_id: mesaId,
        fecha,
        personas
      }
    });
  });
}
```

✅ **Deberías ver:** Objeto `Reserva` creado.
❌ **Si ves:** `Transaction failed due to a write conflict` → Reintentar.

#### Ejemplo P3: Conexión pool limitada (C1)

**Objetivo**: Configurar Prisma para VPS de 4GB RAM.

**Nivel**: 🟢

```env
# .env
DATABASE_URL="postgresql://user:pass@localhost:5432/mantis?schema=public&connection_limit=5"
```

```typescript
// prisma.ts
const prisma = new PrismaClient({
  log: ['warn', 'error'],
  datasources: {
    db: {
      url: process.env.DATABASE_URL,
    },
  },
});
```

✅ **Deberías ver:** `prisma:info Starting a postgresql pool with 5 connections.`

#### Ejemplo P4: Full-text search en PostgreSQL

**Objetivo**: Búsqueda textual complementaria a Qdrant.

**Nivel**: 🟡

```sql
-- Migración SQL
ALTER TABLE productos ADD COLUMN search_vector tsvector
  GENERATED ALWAYS AS (to_tsvector('spanish', coalesce(nombre,'') || ' ' || coalesce(descripcion,''))) STORED;
CREATE INDEX idx_productos_search ON productos USING GIN(search_vector);
```

```typescript
const resultados = await prisma.$queryRaw`
  SELECT id, nombre, descripcion
  FROM productos
  WHERE tenant_id = ${tenantId}
    AND search_vector @@ plainto_tsquery('spanish', ${query})
  ORDER BY ts_rank(search_vector, plainto_tsquery('spanish', ${query})) DESC
  LIMIT 5;
`;
```

✅ **Deberías ver:** Productos relevantes aunque no coincidan exactamente.
❌ **Si ves:** `function plainto_tsquery(unknown) does not exist` → Instalar extensión `unaccent` y configurar idioma.

#### Ejemplo P5: Uso de JSONB para datos flexibles

**Objetivo**: Almacenar metadatos de ingesta RAG.

**Nivel**: 🟢

```prisma
model DocumentoIngestado {
  id         String   @id @default(uuid())
  tenant_id  String
  source_url String?
  metadata   Json     // { "pages": 5, "author": "..." }
  created_at DateTime @default(now())
}
```

```typescript
await prisma.documentoIngestado.create({
  data: {
    tenant_id: tenantId,
    source_url: "https://drive.google.com/...",
    metadata: { pages: 5, ocr_confidence: 0.98 }
  }
});
// Consulta con filtro JSON
const docs = await prisma.documentoIngestado.findMany({
  where: {
    tenant_id: tenantId,
    metadata: { path: ['ocr_confidence'], gte: 0.95 }
  }
});
```

#### Ejemplo P6: Listen/Notify para actualizaciones en tiempo real

**Objetivo**: Notificar al agente WhatsApp cuando cambia disponibilidad.

**Nivel**: 🔴

```sql
-- Trigger en PostgreSQL
CREATE OR REPLACE FUNCTION notificar_cambio_mesa() RETURNS TRIGGER AS $$
BEGIN
  PERFORM pg_notify('mesa_update', json_build_object('tenant', NEW.tenant_id, 'mesa', NEW.numero)::text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

```typescript
// Listener en Node.js
import { Client } from 'pg';
const client = new Client({ connectionString: process.env.DATABASE_URL });
await client.connect();
client.on('notification', (msg) => {
  const payload = JSON.parse(msg.payload);
  // Invalidar caché Redis para ese tenant
});
await client.query('LISTEN mesa_update');
```

#### Ejemplo P7: Migración con Prisma para multi-tenant

**Objetivo**: Añadir columna `tenant_id` a tablas existentes.

**Nivel**: 🟡

```sql
-- migration.sql
ALTER TABLE mesas ADD COLUMN tenant_id VARCHAR(50) NOT NULL DEFAULT 'legacy';
CREATE INDEX idx_mesas_tenant ON mesas(tenant_id);
-- Luego actualizar valores y quitar default
```

#### Ejemplo P8: Conexión segura vía túnel SSH (C3)

**Objetivo**: Conectar Prisma a PostgreSQL remoto sin exponer puerto.

**Nivel**: 🟡

```bash
# Establecer túnel SSH (mantener en segundo plano)
ssh -L 5433:localhost:5432 user@vps-db -N
```

```env
DATABASE_URL="postgresql://user:pass@localhost:5433/mantis?schema=public"
```

#### Ejemplo P9: Optimización de consultas con índices parciales

**Objetivo**: Acelerar búsquedas por tenant.

**Nivel**: 🟡

```sql
CREATE INDEX idx_reservas_tenant_fecha ON reservas (tenant_id, fecha) WHERE tenant_id IS NOT NULL;
```

#### Ejemplo P10: Row Level Security (RLS) nativo en PostgreSQL

**Objetivo**: Asegurar C4 a nivel de base de datos.

**Nivel**: 🔴

```sql
ALTER TABLE mesas ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON mesas USING (tenant_id = current_setting('app.tenant_id')::text);
-- En cada sesión:
SET app.tenant_id = 'rest_123';
```

---

### Sección 3: MySQL / MariaDB

#### Ejemplo M1: Consulta de productos con límite de conexiones (C1)

**Objetivo**: Obtener menú desde MySQL con pool controlado.

**Nivel**: 🟢

```javascript
// mysql/pool.js
const mysql = require('mysql2/promise');
const pool = mysql.createPool({
  host: 'localhost',
  user: process.env.MYSQL_USER,
  password: process.env.MYSQL_PASS,
  database: 'mantis',
  waitForConnections: true,
  connectionLimit: 5, // C1
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 10000
});

async function getMenu(tenantId) {
  const [rows] = await pool.execute(
    'SELECT nombre, precio FROM productos WHERE tenant_id = ? AND disponible = 1',
    [tenantId]
  );
  return rows;
}
```

✅ **Deberías ver:** Array de objetos.
❌ **Si ves:** `ER_ACCESS_DENIED_ERROR` → Verificar credenciales.

🔗 **Conceptos relacionados:** [[mysql-optimization-4gb-ram.md]], [[mysql-sql-rag-ingestion.md]]

#### Ejemplo M2: Optimización de índices para búsquedas rápidas

**Objetivo**: Acelerar consultas frecuentes por `tenant_id` y `categoria`.

**Nivel**: 🟢

```sql
-- Ejecutar en MySQL
ALTER TABLE productos ADD INDEX idx_tenant_categoria (tenant_id, categoria);
```

#### Ejemplo M3: Transacción con reintento por deadlock

**Objetivo**: Actualizar stock de forma segura.

**Nivel**: 🟡

```javascript
async function reducirStock(tenantId, productoId, cantidad) {
  let retries = 3;
  while (retries--) {
    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();
      const [rows] = await conn.execute(
        'SELECT stock FROM productos WHERE tenant_id = ? AND id = ? FOR UPDATE',
        [tenantId, productoId]
      );
      if (rows[0].stock < cantidad) throw new Error('Stock insuficiente');
      await conn.execute(
        'UPDATE productos SET stock = stock - ? WHERE tenant_id = ? AND id = ?',
        [cantidad, tenantId, productoId]
      );
      await conn.commit();
      return true;
    } catch (err) {
      await conn.rollback();
      if (err.code === 'ER_LOCK_DEADLOCK' && retries > 0) {
        await new Promise(r => setTimeout(r, 100));
        continue;
      }
      throw err;
    } finally {
      conn.release();
    }
  }
}
```

✅ **Deberías ver:** `true`.
❌ **Si ves:** `ER_LOCK_DEADLOCK` persistente → Ve a Troubleshooting #M1

#### Ejemplo M4: Full-Text Search en MySQL

**Objetivo**: Búsqueda textual en descripciones de productos.

**Nivel**: 🟡

```sql
ALTER TABLE productos ADD FULLTEXT INDEX ft_nombre_desc (nombre, descripcion);
```

```javascript
const [rows] = await pool.execute(
  'SELECT nombre, descripcion, MATCH(nombre, descripcion) AGAINST(? IN NATURAL LANGUAGE MODE) as score ' +
  'FROM productos WHERE tenant_id = ? AND MATCH(nombre, descripcion) AGAINST(? IN NATURAL LANGUAGE MODE) > 0 ' +
  'ORDER BY score DESC LIMIT 5',
  [query, tenantId, query]
);
```

✅ **Deberías ver:** Productos con score de relevancia.
❌ **Si ves:** `The used table type doesn't support FULLTEXT indexes` → Asegurar que la tabla es InnoDB (MySQL 5.6+ soporta).

#### Ejemplo M5: Event Scheduler para limpieza de datos temporales

**Objetivo**: Eliminar reservas antiguas automáticamente.

**Nivel**: 🟡

```sql
SET GLOBAL event_scheduler = ON;
CREATE EVENT limpiar_reservas_antiguas
ON SCHEDULE EVERY 1 DAY
DO
  DELETE FROM reservas WHERE fecha < DATE_SUB(NOW(), INTERVAL 6 MONTH);
```

#### Ejemplo M6: Uso de JSON column (MySQL 5.7+)

**Objetivo**: Almacenar preferencias de usuario flexibles.

**Nivel**: 🟢

```sql
CREATE TABLE usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  tenant_id VARCHAR(50),
  preferencias JSON
);
```

```javascript
await pool.execute(
  'INSERT INTO usuarios (tenant_id, preferencias) VALUES (?, ?)',
  [tenantId, JSON.stringify({ idioma: 'es', notificaciones: true })]
);
// Consulta con JSON_EXTRACT
const [rows] = await pool.execute(
  "SELECT * FROM usuarios WHERE tenant_id = ? AND JSON_EXTRACT(preferencias, '$.idioma') = 'es'",
  [tenantId]
);
```

#### Ejemplo M7: Slow Query Log para optimización

**Objetivo**: Identificar consultas lentas (C1).

**Nivel**: 🟡

```sql
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;
SET GLOBAL log_queries_not_using_indexes = 'ON';
```

Luego revisar archivo de log para optimizar índices.

#### Ejemplo M8: Replicación de solo lectura para descarga de consultas

**Objetivo**: Usar réplica para búsquedas RAG que no modifican.

**Nivel**: 🔴

```javascript
const readPool = mysql.createPool({ host: 'replica-db.local', ... });
// Usar readPool para SELECT, writePool para INSERT/UPDATE.
```

#### Ejemplo M9: Particionamiento por tenant_id (para grandes volúmenes)

**Objetivo**: Mejorar rendimiento en multi-tenancy extremo.

**Nivel**: 🔴

```sql
ALTER TABLE productos PARTITION BY KEY(tenant_id) PARTITIONS 10;
```

#### Ejemplo M10: Respaldo lógico con mysqldump y cifrado (C5)

**Objetivo**: Backup diario compatible con constraints.

**Nivel**: 🟢

```bash
mysqldump --single-transaction --routines --triggers mantis | gzip | age -r age1... > backup.sql.gz.age
```

🔗 **Conceptos relacionados:** [[backup-encryption.md]]

---

### Sección 4: Supabase (PostgreSQL + APIs)

#### Ejemplo S1: Consulta RAG usando Supabase JS client

**Objetivo**: Obtener documentos ingesta desde Supabase.

**Nivel**: 🟢

```typescript
import { createClient } from '@supabase/supabase-js';
const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_ANON_KEY!);

async function getDocumentsForRAG(tenantId: string) {
  const { data, error } = await supabase
    .from('documentos')
    .select('id, contenido, metadata')
    .eq('tenant_id', tenantId)
    .limit(10);
  if (error) throw error;
  return data;
}
```

✅ **Deberías ver:** Array de documentos.
❌ **Si ves:** `JWT expired` → Refrescar sesión.

🔗 **Conceptos relacionados:** [[multi-tenant-data-isolation.md]]

#### Ejemplo S2: Realtime subscriptions para notificaciones

**Objetivo**: Recibir alertas de nuevos documentos ingesta.

**Nivel**: 🟡

```typescript
const channel = supabase
  .channel('schema-db-changes')
  .on(
    'postgres_changes',
    { event: 'INSERT', schema: 'public', table: 'documentos', filter: `tenant_id=eq.${tenantId}` },
    (payload) => {
      console.log('Nuevo documento:', payload.new);
      // Disparar re-ingesta a Qdrant
    }
  )
  .subscribe();
```

#### Ejemplo S3: Row Level Security (RLS) automático con helper

**Objetivo**: Implementar C4 sin código manual.

**Nivel**: 🟢

```sql
-- En SQL Editor de Supabase
ALTER TABLE documentos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Tenant isolation" ON documentos
  USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::text);
```

#### Ejemplo S4: Storage para archivos PDF (Google Drive alternative)

**Objetivo**: Almacenar PDFs en Supabase Storage y procesar con Mistral OCR.

**Nivel**: 🟡

```typescript
const { data, error } = await supabase.storage
  .from('pdfs')
  .upload(`${tenantId}/${fileName}`, fileBuffer, {
    contentType: 'application/pdf',
    cacheControl: '3600'
  });
// Luego obtener URL firmada para procesar
const { data: { signedUrl } } = await supabase.storage
  .from('pdfs')
  .createSignedUrl(`${tenantId}/${fileName}`, 60);
```

#### Ejemplo S5: Edge Functions para lógica serverless

**Objetivo**: Ejecutar embedding y búsqueda Qdrant desde Edge.

**Nivel**: 🟡

```typescript
// supabase/functions/whatsapp-webhook/index.ts
Deno.serve(async (req) => {
  const { tenant_id, query } = await req.json();
  // Llamar a Qdrant vía URL interna
  const qdrantRes = await fetch('http://vps-ip:6333/collections/knowledge_base/points/search', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ vector: await embed(query), limit: 3, filter: { must: [{ key: "tenant_id", match: { value: tenant_id } }] } })
  });
  // Llamar a OpenRouter
  // ...
  return new Response(JSON.stringify({ respuesta }));
});
```

---

### Sección 5: Google Drive (Documentos y OCR)

#### Ejemplo G1: Listar archivos de una carpeta específica del tenant

**Objetivo**: Sincronizar PDFs de Drive a Qdrant.

**Nivel**: 🟢

```typescript
import { google } from 'googleapis';
const auth = new google.auth.GoogleAuth({
  keyFile: 'service-account.json',
  scopes: ['https://www.googleapis.com/auth/drive.readonly'],
});
const drive = google.drive({ version: 'v3', auth });

async function listPdfFiles(folderId: string) {
  const res = await drive.files.list({
    q: `'${folderId}' in parents and mimeType='application/pdf' and trashed=false`,
    fields: 'files(id, name, modifiedTime)',
  });
  return res.data.files;
}
```

✅ **Deberías ver:** Lista de archivos PDF.
❌ **Si ves:** `Error: The user's Drive storage quota has been exceeded.` → Ve a Troubleshooting #G1

🔗 **Conceptos relacionados:** [[google-drive-qdrant-sync.md]]

#### Ejemplo G2: Descargar archivo y extraer texto con Mistral OCR

**Objetivo**: Obtener texto plano de PDF para embedding.

**Nivel**: 🟡

```typescript
async function downloadAndOcr(fileId: string) {
  const res = await drive.files.get({ fileId, alt: 'media' }, { responseType: 'stream' });
  const chunks: Buffer[] = [];
  for await (const chunk of res.data) chunks.push(chunk);
  const pdfBuffer = Buffer.concat(chunks);
  
  // Llamar a Mistral OCR (API)
  const formData = new FormData();
  formData.append('file', pdfBuffer, 'doc.pdf');
  const ocrRes = await fetch('https://api.mistral.ai/v1/ocr', {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${process.env.MISTRAL_API_KEY}` },
    body: formData
  });
  const data = await ocrRes.json();
  return data.text;
}
```

✅ **Deberías ver:** String con texto extraído.
❌ **Si ves:** `Error: File too large` → Ve a Troubleshooting #G2

🔗 **Conceptos relacionados:** [[pdf-mistralocr-processing.md]]

#### Ejemplo G3: Webhook de notificaciones de cambios en Drive

**Objetivo**: Recibir notificaciones cuando se añade/modifica un archivo.

**Nivel**: 🔴

```typescript
// Registrar webhook
await drive.files.watch({
  fileId: folderId,
  requestBody: {
    id: uuidv4(),
    type: 'web_hook',
    address: 'https://miapi.com/drive-webhook'
  }
});
// Endpoint que recibe header 'X-Goog-Resource-State'
```

#### Ejemplo G4: Paginación para manejar muchas carpetas

**Objetivo**: Sincronizar miles de archivos sin exceder memoria (C1).

**Nivel**: 🟡

```typescript
let pageToken: string | undefined;
do {
  const res = await drive.files.list({
    q: `'${folderId}' in parents`,
    pageSize: 100,
    pageToken,
    fields: 'nextPageToken, files(id, name)'
  });
  for (const file of res.data.files) {
    // Procesar archivo uno por uno para mantener memoria baja
    await processFile(file);
  }
  pageToken = res.data.nextPageToken;
} while (pageToken);
```

#### Ejemplo G5: Manejo de cuotas y rate limiting (C6)

**Objetivo**: Evitar errores 429 de Google Drive.

**Nivel**: 🟢

```typescript
import { exponentialBackoff } from './utils';
async function safeDriveCall<T>(apiCall: () => Promise<T>): Promise<T> {
  return exponentialBackoff(apiCall, {
    retries: 5,
    initialDelay: 1000,
    maxDelay: 32000,
    shouldRetry: (err) => err.code === 429 || err.code === 403
  });
}
```

---

### Sección 6: Google Sheets

#### Ejemplo SH1: Leer menú de restaurante desde Google Sheets

**Objetivo**: Usar Sheets como CMS para datos semi-estructurados.

**Nivel**: 🟢

```typescript
import { google } from 'googleapis';
const sheets = google.sheets({ version: 'v4', auth });

async function getMenuFromSheet(spreadsheetId: string, range: string) {
  const res = await sheets.spreadsheets.values.get({
    spreadsheetId,
    range,
  });
  // rows: [['Plato', 'Precio', 'Descripción'], ['Risotto', '280', '...']]
  return res.data.values;
}
```

✅ **Deberías ver:** Array de arrays con datos.
❌ **Si ves:** `Error: The caller does not have permission` → Ve a Troubleshooting #SH1

#### Ejemplo SH2: Transformar datos de Sheets a documentos RAG

**Objetivo**: Convertir filas en texto enriquecido para Qdrant.

**Nivel**: 🟢

```typescript
const rows = await getMenuFromSheet(SHEET_ID, 'Menu!A2:C');
for (const row of rows) {
  const [plato, precio, desc] = row;
  const text = `${plato}: $${precio}. ${desc}`;
  const embedding = await generateEmbedding(text);
  await qdrant.upsert(...);
}
```

#### Ejemplo SH3: Escribir logs de conversación en Sheets

**Objetivo**: Auditoría de interacciones WhatsApp.

**Nivel**: 🟢

```typescript
await sheets.spreadsheets.values.append({
  spreadsheetId: LOG_SHEET_ID,
  range: 'Logs!A:D',
  valueInputOption: 'USER_ENTERED',
  requestBody: {
    values: [[new Date().toISOString(), tenantId, userPhone, userQuery]]
  }
});
```

#### Ejemplo SH4: Cachear valores de Sheets en Redis

**Objetivo**: Evitar llamadas a API de Google en cada mensaje (C1/C2).

**Nivel**: 🟡

```typescript
const cacheKey = `sheets:${spreadsheetId}:${range}`;
let data = await redis.get(cacheKey);
if (!data) {
  data = await sheets.spreadsheets.values.get(...);
  await redis.setex(cacheKey, 300, JSON.stringify(data)); // 5 min TTL
}
```

#### Ejemplo SH5: Webhook de Google Apps Script para notificaciones

**Objetivo**: Recibir notificaciones push cuando Sheets cambia.

**Nivel**: 🔴

```javascript
// En Google Apps Script vinculado al Sheet
function onEdit(e) {
  const url = 'https://mi-webhook.com/sheets-update';
  UrlFetchApp.fetch(url, {
    method: 'post',
    payload: JSON.stringify({ range: e.range.getA1Notation() })
  });
}
```

---

### Sección 7: Airtable

#### Ejemplo A1: Listar registros de una base Airtable

**Objetivo**: Obtener inventario o base de conocimiento.

**Nivel**: 🟢

```typescript
import Airtable from 'airtable';
const base = new Airtable({ apiKey: process.env.AIRTABLE_API_KEY }).base(process.env.AIRTABLE_BASE_ID!);

async function getRecords(tableName: string, tenantId: string) {
  const records = await base(tableName).select({
    filterByFormula: `{tenant_id} = '${tenantId}'`,
    maxRecords: 100
  }).all();
  return records.map(r => r.fields);
}
```

✅ **Deberías ver:** Array de objetos con campos.
❌ **Si ves:** `Error: AirtableError: NOT_FOUND` → Ve a Troubleshooting #A1

#### Ejemplo A2: Paginación con offset (Airtable usa offset string)

**Objetivo**: Procesar todas las filas sin límite de 100.

**Nivel**: 🟢

```typescript
let allRecords: any[] = [];
await base(tableName).select().eachPage((records, fetchNextPage) => {
  allRecords.push(...records);
  fetchNextPage();
});
```

#### Ejemplo A3: Webhook de Airtable (mediante scripting block)

**Objetivo**: Sincronización bidireccional.

**Nivel**: 🔴

Airtable no tiene webhooks nativos, pero se puede usar un Scripting block con un trigger periódico o Zapier.

#### Ejemplo A4: Cachear resultados en memoria (C1)

**Objetivo**: Reducir llamadas a API de Airtable.

**Nivel**: 🟡

```typescript
const cacheKey = `airtable:${tableName}:${tenantId}`;
// Similar a Google Sheets.
```

#### Ejemplo A5: Actualizar registros desde WhatsApp (ej: cambiar estado pedido)

**Objetivo**: Permitir a meseros confirmar pedidos.

**Nivel**: 🟡

```typescript
await base('Pedidos').update([
  { id: recordId, fields: { Estado: 'Entregado' } }
]);
```

---

### Sección 8: SQLite (referido como ChromeDB en el prompt)

#### Ejemplo L1: Conexión a SQLite local para desarrollo

**Objetivo**: Base de datos embebida para pruebas.

**Nivel**: 🟢

```typescript
import sqlite3 from 'sqlite3';
import { open } from 'sqlite';

const db = await open({
  filename: './mantis_local.db',
  driver: sqlite3.Database
});

await db.exec(`
  CREATE TABLE IF NOT EXISTS conocimiento (
    id TEXT PRIMARY KEY,
    tenant_id TEXT,
    texto TEXT,
    embedding BLOB
  )
`);
```

✅ **Deberías ver:** Archivo `.db` creado.
❌ **Si ves:** `SQLITE_CANTOPEN` → Permisos de directorio.

#### Ejemplo L2: Búsqueda con extensión vec0 (vector similarity)

**Objetivo**: Simular Qdrant en local.

**Nivel**: 🔴

```sql
-- Requiere compilar SQLite con extensión vec0
.load ./vec0
CREATE VIRTUAL TABLE vec_items USING vec0(embedding float[1536]);
INSERT INTO vec_items(rowid, embedding) VALUES (1, ?);
SELECT rowid, distance FROM vec_items WHERE embedding MATCH ? ORDER BY distance LIMIT 5;
```

#### Ejemplo L3: Transacción con backup automático

**Objetivo**: Asegurar integridad.

**Nivel**: 🟢

```typescript
await db.run('BEGIN TRANSACTION');
try {
  await db.run('INSERT INTO ...');
  await db.run('UPDATE ...');
  await db.run('COMMIT');
} catch {
  await db.run('ROLLBACK');
}
```

#### Ejemplo L4: Uso en memoria para tests

**Objetivo**: Pruebas unitarias rápidas.

**Nivel**: 🟢

```typescript
const db = await open({ filename: ':memory:', driver: sqlite3.Database });
```

#### Ejemplo L5: Migraciones con Knex.js

**Objetivo**: Gestionar cambios de esquema.

**Nivel**: 🟡

```javascript
exports.up = function(knex) {
  return knex.schema.createTable('conocimiento', table => {
    table.string('id').primary();
    table.string('tenant_id').index();
    table.text('texto');
  });
};
```

---

### Sección 9: SQL Genérico (Raw SQL con múltiples motores)

#### Ejemplo R1: Función de utilidad para ejecutar consulta parametrizada

**Objetivo**: Abstracción para soportar PostgreSQL y MySQL.

**Nivel**: 🟢

```typescript
type DBType = 'pg' | 'mysql';
async function query(dbType: DBType, sql: string, params: any[]) {
  if (dbType === 'pg') {
    const { rows } = await pgPool.query(sql, params);
    return rows;
  } else {
    const [rows] = await mysqlPool.execute(sql, params);
    return rows;
  }
}
```

#### Ejemplo R2: Plantilla para consulta de disponibilidad genérica

**Objetivo**: Escribir SQL portable.

**Nivel**: 🟡

```sql
-- Usar sintaxis compatible
SELECT * FROM reservas WHERE tenant_id = ? AND fecha = ?;
-- En PostgreSQL usar $1, $2, en MySQL ? ?
```

#### Ejemplo R3: Manejo de errores específicos de cada motor

**Objetivo**: Robustez.

**Nivel**: 🟢

```typescript
try {
  await query(...);
} catch (err) {
  if (dbType === 'pg' && err.code === '23505') {
    // unique violation
  } else if (dbType === 'mysql' && err.code === 'ER_DUP_ENTRY') {
    // duplicate entry
  }
}
```

#### Ejemplo R4: Pool de conexiones común para ambos motores

**Objetivo**: Configuración centralizada C1.

**Nivel**: 🟢

```typescript
const poolConfig = { max: 5, idleTimeoutMillis: 30000 };
```

#### Ejemplo R5: Healthcheck de conexión

**Objetivo**: Verificar antes de usar.

**Nivel**: 🟢

```typescript
async function healthCheck() {
  try {
    await pgPool.query('SELECT 1');
    await mysqlPool.execute('SELECT 1');
    return true;
  } catch {
    return false;
  }
}
```

---

### Sección 10: ChromeDB (Simulación con SQLite + extensión de navegador)

**Nota:** "ChromeDB" no es una base de datos real; interpretamos como almacenamiento local del navegador (IndexedDB/WebSQL) usado por extensiones o PWAs. En el contexto de MANTIS, podría usarse para un panel de administración local.

#### Ejemplo C1: Uso de IndexedDB para caché offline de respuestas RAG

**Objetivo**: Permitir funcionamiento sin conexión en dashboard.

**Nivel**: 🟢

```javascript
// En frontend
const request = indexedDB.open('mantisCache', 1);
request.onupgradeneeded = (event) => {
  const db = event.target.result;
  db.createObjectStore('responses', { keyPath: 'queryHash' });
};
async function cacheResponse(queryHash, response) {
  const db = await openDB();
  const tx = db.transaction('responses', 'readwrite');
  tx.objectStore('responses').put({ queryHash, response, timestamp: Date.now() });
}
```

#### Ejemplo C2: Sincronización con backend usando Background Sync

**Objetivo**: Enviar mensajes de WhatsApp cuando vuelve la conexión.

**Nivel**: 🔴

```javascript
if ('serviceWorker' in navigator && 'SyncManager' in window) {
  const registration = await navigator.serviceWorker.ready;
  await registration.sync.register('send-message');
}
// En service worker
self.addEventListener('sync', (event) => {
  if (event.tag === 'send-message') {
    event.waitUntil(sendPendingMessages());
  }
});
```

---


## 🤖 Sección IA: 5 Ejemplos por Modelo (OpenRouter)

### Modelo 1: GPT-4o (OpenAI vía OpenRouter)

#### Ejemplo GPT1: Llamada básica con contexto RAG

**Objetivo**: Generar respuesta a pregunta de cliente con contexto de Qdrant.

**Nivel**: 🟢

```typescript
import axios from 'axios';

async function askGPT4o(prompt: string, context: string, tenantId: string) {
  const response = await axios.post('https://openrouter.ai/api/v1/chat/completions', {
    model: 'openai/gpt-4o',
    messages: [
      { role: 'system', content: `Eres asistente de restaurante. Tenant: ${tenantId}. Usa solo el contexto proporcionado.` },
      { role: 'user', content: `Contexto: ${context}\n\nPregunta: ${prompt}` }
    ],
    temperature: 0.2,
    max_tokens: 500
  }, {
    headers: {
      'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}`,
      'HTTP-Referer': process.env.APP_URL,
      'X-Title': 'MantisWhatsApp'
    }
  });
  return response.data.choices[0].message.content;
}
```

✅ **Deberías ver:** Respuesta coherente basada en el contexto.
❌ **Si ves:** `Error: 402 Payment Required` → Ve a Troubleshooting #IA1

### Modelo 2: Claude 3.5 Sonnet

#### Ejemplo CL1: Uso de sistema de mensajes para control de formato

**Objetivo**: Respuestas en markdown estructurado.

**Nivel**: 🟢

```typescript
const claudeRes = await axios.post('https://openrouter.ai/api/v1/chat/completions', {
  model: 'anthropic/claude-3.5-sonnet',
  messages: [
    { role: 'system', content: 'Responde en formato Markdown con viñetas.' },
    { role: 'user', content: finalPrompt }
  ],
  max_tokens: 800
}, { headers });
```

✅ **Deberías ver:** Texto con `*` y saltos de línea.

### Modelo 3: Qwen 2.5

#### Ejemplo QW1: Razonamiento para consultas complejas

**Objetivo**: Preguntas que requieren varios pasos lógicos.

**Nivel**: 🟡

```typescript
// Qwen es bueno para chain-of-thought
const qwenRes = await axios.post(..., {
  model: 'qwen/qwen-2.5-72b-instruct',
  messages: [
    { role: 'system', content: 'Piensa paso a paso antes de responder.' },
    { role: 'user', content: prompt }
  ],
  temperature: 0.1
});
```

### Modelo 4: DeepSeek-V3

#### Ejemplo DS1: Optimización de costos para respuestas masivas

**Objetivo**: Alto volumen de consultas con presupuesto limitado.

**Nivel**: 🟢

```typescript
// DeepSeek es más económico, ideal para preguntas frecuentes
const dsRes = await axios.post(..., {
  model: 'deepseek/deepseek-chat',
  messages: [...],
  max_tokens: 400
});
```

### Modelo 5: MiniMax-Text-01

#### Ejemplo MM1: Soporte para contexto muy largo (hasta 1M tokens)

**Objetivo**: Procesar documentos extensos completos.

**Nivel**: 🟡

```typescript
const mmRes = await axios.post(..., {
  model: 'minimax/minimax-text-01',
  messages: [{ role: 'user', content: longDocument + '\n\n' + query }],
  max_tokens: 2000
});
```

---

## 🐞 10 Problemas Comunes en Conexión con Bases de Datos y Soluciones

| Error Exacto (copiable) | Causa Raíz (lenguaje simple) | Comando de Diagnóstico | Solución Paso a Paso | Constraint Afectado (C#) |
|--------------------------|------------------------------|------------------------|----------------------|--------------------------|
| `Error: connect ECONNREFUSED 127.0.0.1:3306` | MySQL no está corriendo o escucha en otra interfaz | `sudo systemctl status mysql` | 1. `sudo systemctl start mysql` 2. Verificar `bind-address` en `/etc/mysql/mysql.conf.d/mysqld.cnf` | C3 |
| `PrismaClientInitializationError: Can't reach database server at localhost:5432` | PostgreSQL caído o mal configurado | `pg_isready -h localhost` | 1. `sudo systemctl restart postgresql` 2. Revisar logs con `journalctl -u postgresql` | C3 |
| `Error: connect ETIMEDOUT` cuando se conecta a Qdrant remoto | Firewall bloquea puerto 6333 | `telnet vps-ip 6333` | Usar túnel SSH: `ssh -L 6333:localhost:6333 user@vps` y conectar a `localhost:6333` | C3 |
| `Error: ER_CON_COUNT_ERROR: Too many connections` | Se superó el límite de conexiones MySQL (C1) | `SHOW VARIABLES LIKE 'max_connections'; SHOW STATUS LIKE 'Threads_connected';` | 1. Aumentar límite en my.cnf: `max_connections=20`. 2. Usar pool con `connectionLimit:5`. 3. Cerrar conexiones no usadas. | C1 |
| `FATAL: sorry, too many clients already` en PostgreSQL | Mismo problema que arriba | `SELECT count(*) FROM pg_stat_activity;` | Ajustar `max_connections = 20` en `postgresql.conf` y reiniciar. | C1 |
| `Error: P1001: Can't reach database server at ...` (Prisma) | URL incorrecta o VPN requerida | `nslookup db-host` | Verificar que la URL de conexión use `localhost` si hay túnel SSH, o IP privada si VPS interconectado. | C3 |
| `error: no pg_hba.conf entry for host ...` | PostgreSQL rechaza conexión desde IP no autorizada | `grep "host.*all.*all" /etc/postgresql/*/main/pg_hba.conf` | Agregar línea: `host all all 10.0.0.0/8 md5` para red interna. Luego `sudo systemctl reload postgresql`. | C3 |
| `Error: The provided key ... does not have access to Google Drive` | Service account sin permisos sobre el archivo/carpeta | `gcloud auth activate-service-account --key-file=key.json` y probar con `gcloud` | Compartir la carpeta de Drive con el email de la service account (ej: `xxx@...gserviceaccount.com`) con rol "Lector". | C6 |
| `Error: AirtableError: NOT_FOUND` | ID de base o tabla incorrecta | `curl -H "Authorization: Bearer $AIRTABLE_API_KEY" https://api.airtable.com/v0/meta/bases` | Verificar que el Base ID y el nombre de tabla coincidan exactamente (sensible a mayúsculas). | - |
| `SQLITE_BUSY: database is locked` | Escritura concurrente en SQLite (no soporta bien escritura paralela) | `lsof mantis.db` para ver procesos abiertos | 1. Usar `db.configure('busyTimeout', 5000)`. 2. No usar SQLite en producción multi-hilo. | C1 |

## 🐞 5 Errores Comunes con IA (OpenRouter) y Soluciones

| Error Exacto | Causa Raíz | Diagnóstico | Solución | Constraint |
|--------------|------------|-------------|----------|------------|
| `Error: 429 You exceeded your current quota` | Límite de créditos OpenRouter o rate limit | Revisar dashboard de OpenRouter | 1. Reducir frecuencia de llamadas. 2. Implementar cola con retry exponencial. 3. Usar modelo más económico (DeepSeek). | C6 |
| `Error: 400 Invalid model` | Nombre de modelo incorrecto en la petición | `curl https://openrouter.ai/api/v1/models` | Usar identificador exacto: `openai/gpt-4o`, `anthropic/claude-3.5-sonnet`. | - |
| `Error: Request Entity Too Large` | Contexto excede el límite de tokens del modelo | Contar tokens del prompt (aprox 4 chars = 1 token) | Truncar contexto RAG a 2000 tokens máximo. Usar modelo de contexto largo (MiniMax) si es necesario. | C2 |
| `Error: 500 Internal Server Error` desde OpenRouter | Error temporal del proveedor | Esperar y reintentar | Implementar lógica de reintento con backoff. Registrar incidencia. | - |
| `Error: Connection timeout` | Llamada a API de IA tarda >30s | Medir latencia con `time curl ...` | Aumentar timeout en cliente HTTP a 60s. Si persiste, usar modelo más rápido (GPT-3.5 Turbo). | C6 |

---

## ✅ Validación SDD y Comandos de Verificación

<!-- ai:constraint=C5 -->
Para asegurar que el despliegue cumple con las restricciones:

1. **Verificar límites de memoria de contenedores:**
   ```bash
   docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}"
   ```
   Asegurar que ningún contenedor supere 1.5GB.

2. **Verificar que Qdrant no está expuesto:**
   ```bash
   ss -tlnp | grep 6333
   ```
   Debe mostrar `127.0.0.1:6333` o `::1:6333`, nunca `0.0.0.0:6333`.

3. **Chequeo de conexiones activas a BD:**
   ```sql
   -- PostgreSQL
   SELECT count(*) FROM pg_stat_activity WHERE state = 'active';
   -- Debe ser < connectionLimit
   ```

4. **Validación de tenant_id en logs (C4):**
   ```bash
   grep -E "tenant_id\":\"[^\"]+\"" /var/log/whatsapp-rag.log | wc -l
   ```
   Debe coincidir con número de peticiones.

5. **Backup de configuraciones (C5):**
   ```bash
   sha256sum .env > .env.sha256
   rsync -avz .env* backups@backup-server:/backups/config/
   ```

---

## 🔗 Referencias Cruzadas y Glosario

- **[[skill-domains-mapping.md]]**: Estado de todos los skills.
- **[[qdrant-rag-ingestion.md]]**: Ingesta base en Qdrant.
- **[[postgres-prisma-rag.md]]**: Uso avanzado de Prisma.
- **[[multi-tenant-data-isolation.md]]**: Estrategias de aislamiento.
- **[[environment-variable-management.md]]**: Gestión segura de secretos.
- **[[google-drive-qdrant-sync.md]]**: Sincronización Drive ↔ Qdrant.
- **[[whatsapp-uazapi-integration.md]]**: Integración con UAZapi.
- **[[openrouter-api-integration.md]]**: Detalles de OpenRouter.
- **[[mysql-optimization-4gb-ram.md]]**: Configuración para VPS pequeños.

**Glosario:**
- **RAG**: Retrieval-Augmented Generation.
- **Embedding**: Representación vectorial de texto.
- **Tenant**: Cliente/negocio aislado lógicamente.
- **OpenRouter**: Proxy unificado de LLMs.
- **SDD**: Specification-Driven Development.

FIN DEL ARCHIVO
<!-- ai:file-end marker - do not remove -->
Versión 1.0.0 - 2026-04-11 - Mantis-AgenticDev
