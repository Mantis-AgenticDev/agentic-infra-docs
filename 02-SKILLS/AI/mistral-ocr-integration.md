---
title: "mistral-ocr-integration.md"
category: "Skill"
domain: ["ai", "base-de-datos-rag"]
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
priority: "ALTA"
version: "2.0.0"
last_updated: "2026-04-11"
ai_optimized: true
tags:
  - sdd/skill/ai
  - sdd/skill/ocr
  - lang/es
related_files:
  - "01-RULES/03-SECURITY-RULES.md"
  - "02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md"
  - "02-SKILLS/BASE DE DATOS-RAG/pdf-mistralocr-processing.md"
  - "02-SKILLS/BASE DE DATOS-RAG/google-drive-qdrant-sync.md"
  - "05-CONFIGURATIONS/environment-variable-management.md"
  - "02-SKILLS/AI/openrouter-api-integration.md"
---

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

**Objetivo en 3 minutos:** Extraer texto y tablas de un PDF usando la API de OCR de Mistral y generar embeddings para Qdrant.

1. **Requisito previo:** Tener una cuenta en [Mistral AI](https://mistral.ai) y una API Key.
2. **Variable de entorno (C3):**  
   ```bash
   echo "MISTRAL_API_KEY=xxxxxxxx" >> .env
   ```
3. **Llamada básica con `curl`:**
   ```bash
   curl -X POST https://api.mistral.ai/v1/ocr \
     -H "Authorization: Bearer $MISTRAL_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "model": "mistral-ocr-latest",
       "document": {
         "type": "document_url",
         "document_url": "https://example.com/documento.pdf"
       }
     }'
   ```
✅ **Deberías ver:** JSON con `pages` conteniendo `markdown` y `images`.  
❌ **Si ves:** `{"message":"Invalid API Key"}` → Verifica la variable de entorno y que la key esté activa.

⚠️ **Seguridad (C3):** Nunca expongas la API Key en código cliente. Procesa siempre los documentos en el backend.

---

## 🎯 Propósito y Alcance

Este skill documenta la integración con la **API de OCR de Mistral AI** para extraer texto estructurado, tablas y procedimientos desde documentos PDF e imágenes. Está diseñado para ser utilizado por agentes autogenerados dentro del ecosistema MANTIS que requieren ingestar conocimiento no estructurado (facturas, manuales, menús, protocolos médicos) hacia la base de conocimiento vectorial (Qdrant).

**Cubre:**
- Configuración de la API de OCR de Mistral (`mistral-ocr-latest`).
- Procesamiento de documentos desde URLs o archivos locales (respetando C1/C2).
- Extracción avanzada de **tablas** en formato Markdown y su conversión a embeddings vectoriales.
- Extracción de **procedimientos paso a paso** (listas numeradas) para RAG procedural.
- Integración con el pipeline de ingesta a Qdrant (`qdrant-rag-ingestion.md`).
- **CI/CD e Infraestructura como Código (IaC)** con Terraform para despliegue automatizado.
- **Hardening de seguridad** y verificación automatizada de integridad de secretos.
- **Autogeneración por IA** de workflows de ingesta documental.

**No cubre:**
- La lógica de chunking semántico avanzado (eso es parte del skill de ingesta RAG).
- El almacenamiento de los archivos originales (se asume Google Drive o Supabase Storage).
- OCR de video (fuera del alcance de Mistral).

---

## 📐 Fundamentos (De 0 a Intermedio)

### ¿Qué es Mistral OCR?
Mistral OCR es un modelo multimodal que **entiende la estructura visual** de un documento (PDF, imagen) y la convierte en texto en formato **Markdown**. A diferencia de un OCR tradicional que solo devuelve líneas de texto, Mistral OCR:
- Conserva **títulos, negritas, listas**.
- Convierte **tablas complejas** en sintaxis Markdown (`| Col1 | Col2 |`).
- Detecta **imágenes y diagramas** y puede devolverlos como `base64` para su procesamiento posterior.

### ¿Por qué es importante para MANTIS?
En verticales como **odontología** (historias clínicas escaneadas) u **hoteles** (facturas en PDF), el conocimiento está atrapado en documentos no digitalizados. Mistral OCR permite:
1. **Vectorizar tablas de precios** para que un agente WhatsApp pueda responder "¿Cuánto cuesta una limpieza dental?".
2. **Vectorizar procedimientos** ("Pasos para check-in") para guiar a empleados.
3. **Auditar contratos** corporativos.

### Estructura de la Respuesta de Mistral OCR
```json
{
  "pages": [
    {
      "index": 0,
      "markdown": "# Título\n\nTexto en **negrita**...\n\n| Producto | Precio |\n|----------|--------|\n| A | $10 |",
      "images": [
        {
          "id": "img_001",
          "image_base64": "iVBORw0KGgo..."
        }
      ]
    }
  ],
  "model": "mistral-ocr-latest",
  "usage": { "pages_processed": 1 }
}
```

---

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

### Aplicación de Constraints C1 y C2

- **C1 (RAM ≤ 4GB):** La API de Mistral es **cloud-based** (C6). El procesamiento del documento ocurre en los servidores de Mistral. El VPS solo envía el archivo (o URL) y recibe el texto.  
  **Riesgo:** Cargar un PDF de 100MB en memoria para enviarlo como `base64` puede agotar la RAM.  
  → **Mitigación:** Siempre que sea posible, usar `document_url` (archivo alojado en Google Drive o Supabase Storage) en lugar de subir el binario. Si es inevitable, usar **streaming** y procesar por chunks.

- **C2 (1 vCPU por op. crítica):** La llamada a Mistral es I/O de red, consumo de CPU mínimo. Para no bloquear el event loop, usar `async/await`. El procesamiento posterior del Markdown (split, limpieza) sí puede consumir CPU; ejecutarlo con `setImmediate` o en un worker thread si el documento es muy grande.

- **Tiempo de procesamiento:** Mistral OCR tarda entre 2 y 15 segundos por página, dependiendo de la complejidad. **Timeout recomendado:** 120 segundos.

### Configuración de Cliente HTTP Optimizado

```typescript
import axios from 'axios';

const mistralClient = axios.create({
  baseURL: 'https://api.mistral.ai/v1',
  timeout: 120000, // 2 minutos
  headers: {
    'Authorization': `Bearer ${process.env.MISTRAL_API_KEY}`,
    'Content-Type': 'application/json'
  },
  maxBodyLength: 50 * 1024 * 1024, // 50MB máximo (C1)
  maxContentLength: 50 * 1024 * 1024
});
```

---

## 🔗 Integración con Stack Existente (Qdrant, Google Drive)

### Flujo de Ingesta Completo (Google Drive → OCR → Qdrant)

```typescript
import { google } from 'googleapis';
import { QdrantClient } from '@qdrant/js-client-rest';
import { mistralClient } from './mistral-client';
import { embedText } from './embeddings'; // text-embedding-3-small

async function ingestDriveFile(tenantId: string, fileId: string) {
  // 1. Obtener URL firmada de Google Drive
  const drive = google.drive({ version: 'v3', auth });
  const file = await drive.files.get({ fileId, fields: 'webContentLink' });
  const documentUrl = file.data.webContentLink;

  // 2. Procesar con Mistral OCR
  const ocrResponse = await mistralClient.post('/ocr', {
    model: 'mistral-ocr-latest',
    document: {
      type: 'document_url',
      document_url: documentUrl
    }
  });

  // 3. Recorrer páginas y generar embeddings
  const qdrant = new QdrantClient({ url: process.env.QDRANT_URL });
  for (const page of ocrResponse.data.pages) {
    const chunks = splitMarkdownIntoChunks(page.markdown, 1000); // función propia
    for (const chunk of chunks) {
      const embedding = await embedText(chunk);
      await qdrant.upsert('knowledge_base', {
        wait: true,
        points: [{
          id: uuidv4(),
          vector: embedding,
          payload: {
            tenant_id: tenantId,
            source: `drive:${fileId}`,
            page: page.index,
            text: chunk,
            type: 'ocr_markdown'
          }
        }]
      });
    }
  }
}
```

**Cumplimiento de C4:** `tenant_id` en cada punto de Qdrant.

---

## 🛠️ 15 Ejemplos de Configuración (Copy-Paste Validables)

### Ejemplo 1: OCR desde URL pública
**Objetivo**: Procesar un PDF alojado en internet.
**Nivel**: 🟢

```typescript
import axios from 'axios';

async function ocrFromUrl(documentUrl: string) {
  const response = await axios.post(
    'https://api.mistral.ai/v1/ocr',
    {
      model: 'mistral-ocr-latest',
      document: {
        type: 'document_url',
        document_url: documentUrl
      }
    },
    { headers: { Authorization: `Bearer ${process.env.MISTRAL_API_KEY}` } }
  );
  return response.data.pages.map(p => p.markdown).join('\n\n');
}
```
✅ **Deberías ver:** Texto completo en Markdown.  
❌ **Si ves:** `"document_url" is not accessible` → Ve a Troubleshooting #1.

### Ejemplo 2: Subir archivo local como base64 (controlado)
**Objetivo**: Procesar un PDF almacenado en el VPS.
**Nivel**: 🟡  
**⚠️ Precaución C1:** No usar con archivos > 10MB.

```typescript
import fs from 'fs/promises';

async function ocrFromLocalFile(filePath: string) {
  const fileBuffer = await fs.readFile(filePath);
  const base64 = fileBuffer.toString('base64');

  const response = await axios.post(
    'https://api.mistral.ai/v1/ocr',
    {
      model: 'mistral-ocr-latest',
      document: {
        type: 'document_base64',
        document_base64: base64
      }
    },
    { headers: { Authorization: `Bearer ${process.env.MISTRAL_API_KEY}` } }
  );
  return response.data;
}
```
✅ **Deberías ver:** JSON con páginas procesadas.  
❌ **Si ves:** `Error: Request body larger than maxBodyLength` → Ve a Troubleshooting #2.

### Ejemplo 3: Procesar imagen (JPG/PNG)
**Objetivo**: Extraer texto de una foto (ej: cartel de menú).
**Nivel**: 🟢

```typescript
// Mismo código que Ejemplo 2, pero con filePath a un .jpg
const ocrResult = await ocrFromLocalFile('./menu_del_dia.jpg');
console.log(ocrResult.pages[0].markdown);
```

### Ejemplo 4: Extracción de tablas como Markdown y vectorización
**Objetivo**: Detectar tablas y prepararlas para búsqueda semántica.
**Nivel**: 🟡

```typescript
async function extractAndVectorizeTables(tenantId: string, markdown: string) {
  const tableRegex = /\|(.+)\|[\r\n]+\|[-:\s|]+\|[\r\n]+((?:\|.+\|[\r\n]+)+)/g;
  let match;
  const tables = [];
  while ((match = tableRegex.exec(markdown)) !== null) {
    tables.push(match[0]);
  }

  for (const table of tables) {
    const embedding = await embedText(`Tabla: ${table}`);
    await qdrant.upsert('knowledge_base', {
      points: [{
        id: uuidv4(),
        vector: embedding,
        payload: {
          tenant_id: tenantId,
          type: 'table',
          content: table,
          description: 'Tabla extraída por Mistral OCR'
        }
      }]
    });
  }
}
```
✅ **Deberías ver:** Puntos en Qdrant con `type: 'table'`.

### Ejemplo 5: Extracción de procedimientos (listas numeradas)
**Objetivo**: Identificar pasos de un proceso (ej: "1. Lavar, 2. Secar").
**Nivel**: 🟡

```typescript
function extractProcedures(markdown: string): string[] {
  const procedureRegex = /^(\d+\.\s+.+)$/gm;
  const steps = markdown.match(procedureRegex) || [];
  return steps;
}

async function vectorizeProcedures(tenantId: string, markdown: string) {
  const steps = extractProcedures(markdown);
  if (steps.length === 0) return;

  const procedureText = `Procedimiento:\n${steps.join('\n')}`;
  const embedding = await embedText(procedureText);
  await qdrant.upsert('knowledge_base', {
    points: [{
      id: uuidv4(),
      vector: embedding,
      payload: {
        tenant_id: tenantId,
        type: 'procedure',
        content: procedureText,
        step_count: steps.length
      }
    }]
  });
}
```

### Ejemplo 6: Chunking inteligente de Markdown (respetando estructuras)
**Objetivo**: Dividir el Markdown en fragmentos sin romper tablas o listas.
**Nivel**: 🟡

```typescript
function splitMarkdownSmart(markdown: string, maxTokens = 800): string[] {
  const sections = markdown.split(/(?=^#{1,3}\s)/m); // Dividir por encabezados
  const chunks: string[] = [];
  for (const section of sections) {
    if (section.length < maxTokens * 4) {
      chunks.push(section);
    } else {
      // Subdividir por párrafos
      const paragraphs = section.split(/\n\n+/);
      let current = '';
      for (const para of paragraphs) {
        if ((current + para).length > maxTokens * 4) {
          chunks.push(current);
          current = para;
        } else {
          current += (current ? '\n\n' : '') + para;
        }
      }
      if (current) chunks.push(current);
    }
  }
  return chunks;
}
```

### Ejemplo 7: Manejo de imágenes incluidas (base64)
**Objetivo**: Extraer las imágenes detectadas para posible análisis multimodal.
**Nivel**: 🔴

```typescript
async function extractImages(documentUrl: string) {
  const response = await mistralClient.post('/ocr', {
    model: 'mistral-ocr-latest',
    document: { type: 'document_url', document_url: documentUrl },
    include_image_base64: true // Parámetro para recibir las imágenes
  });

  for (const page of response.data.pages) {
    for (const image of page.images) {
      // Guardar imagen en Supabase Storage (ver skill correspondiente)
      await saveImageToStorage(image.id, image.image_base64);
    }
  }
}
```
✅ **Deberías ver:** Imágenes almacenadas.

### Ejemplo 8: Pipeline completo con reintentos
**Objetivo**: Robustez ante fallos temporales de la API.
**Nivel**: 🟡

```typescript
async function ocrWithRetry(documentUrl: string, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await ocrFromUrl(documentUrl);
    } catch (error) {
      if (error.response?.status >= 500 && i < maxRetries - 1) {
        await new Promise(r => setTimeout(r, 2000 * (i + 1)));
        continue;
      }
      throw error;
    }
  }
}
```

### Ejemplo 9: Procesamiento asíncrono con cola (BullMQ)
**Objetivo**: No bloquear el webhook de WhatsApp mientras se hace OCR.
**Nivel**: 🔴

```typescript
import { Queue } from 'bullmq';
const ocrQueue = new Queue('ocr-processing');

// En el webhook:
await ocrQueue.add('process-document', { tenantId, documentUrl });

// En el worker (proceso separado):
ocrQueue.process('process-document', async (job) => {
  const { tenantId, documentUrl } = job.data;
  const markdown = await ocrFromUrl(documentUrl);
  await ingestToQdrant(tenantId, markdown);
});
```

### Ejemplo 10: Uso de `mistral-ocr-latest` con páginas específicas
**Objetivo**: Procesar solo las primeras 3 páginas de un PDF largo.
**Nivel**: 🟢

```typescript
const response = await mistralClient.post('/ocr', {
  model: 'mistral-ocr-latest',
  document: { type: 'document_url', document_url: pdfUrl },
  pages: [0, 1, 2] // índices base 0
});
```

### Ejemplo 11: Extracción de datos estructurados (JSON) desde una factura
**Objetivo**: Usar Mistral OCR + un prompt posterior para obtener campos.
**Nivel**: 🟡

```typescript
async function parseInvoice(documentUrl: string) {
  const markdown = await ocrFromUrl(documentUrl);
  // Llamar a un LLM para extraer JSON
  const extractionPrompt = `
    Del siguiente texto en Markdown, extrae un JSON con:
    - numero_factura
    - fecha
    - total
    Texto:
    ${markdown}
  `;
  const llmResponse = await callOpenRouter(extractionPrompt); // usar skill openrouter
  return JSON.parse(llmResponse);
}
```

### Ejemplo 12: Control de tamaño de archivo antes de subir
**Objetivo**: Evitar errores por archivos demasiado grandes (C1).
**Nivel**: 🟢

```typescript
import fs from 'fs';

async function safeLocalOcr(filePath: string) {
  const stats = await fs.stat(filePath);
  const fileSizeMB = stats.size / (1024 * 1024);
  if (fileSizeMB > 20) {
    throw new Error(`Archivo demasiado grande (${fileSizeMB}MB). Máximo 20MB.`);
  }
  return ocrFromLocalFile(filePath);
}
```

### Ejemplo 13: Cacheo de resultados de OCR para documentos no modificados
**Objetivo**: Ahorrar costos y tiempo (C1/C6).
**Nivel**: 🟡

```typescript
import { createHash } from 'crypto';
import redis from './redis-client';

async function ocrWithCache(documentUrl: string) {
  const hash = createHash('md5').update(documentUrl).digest('hex');
  const cacheKey = `ocr:${hash}`;
  const cached = await redis.get(cacheKey);
  if (cached) return JSON.parse(cached);

  const result = await ocrFromUrl(documentUrl);
  await redis.setex(cacheKey, 86400, JSON.stringify(result)); // 24h
  return result;
}
```

### Ejemplo 14: Logging estructurado para auditoría (C4)
**Objetivo**: Trazabilidad de qué tenant procesó qué documento.
**Nivel**: 🟢

```typescript
async function ocrWithAudit(tenantId: string, documentUrl: string) {
  const start = Date.now();
  try {
    const result = await ocrFromUrl(documentUrl);
    console.log(JSON.stringify({
      event: 'ocr_success',
      tenant_id: tenantId,
      document_url: documentUrl,
      pages: result.pages.length,
      latency_ms: Date.now() - start
    }));
    return result;
  } catch (error) {
    console.error(JSON.stringify({
      event: 'ocr_error',
      tenant_id: tenantId,
      document_url: documentUrl,
      error: error.message,
      latency_ms: Date.now() - start
    }));
    throw error;
  }
}
```

### Ejemplo 15: Validación de que el OCR devolvió contenido útil
**Objetivo**: Detectar documentos corruptos o escaneos vacíos.
**Nivel**: 🟡

```typescript
function validateOcrResult(result: any): boolean {
  const totalLength = result.pages.reduce((acc, page) => acc + page.markdown.length, 0);
  if (totalLength < 50) {
    console.warn('OCR devolvió muy poco texto, posible documento vacío o ilegible.');
    return false;
  }
  return true;
}
```

---

## 🐞 15 Errores Comunes y Troubleshooting

| Error Exacto (copiable) | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso | Constraint Afectado |
|--------------------------|------------|------------------------|----------------------|---------------------|
| **1.** `"document_url" is not accessible` | La URL no es pública o requiere autenticación. | `curl -I "URL"` debe devolver 200. | 1. Asegurar que el archivo sea público. 2. Si es Google Drive, usar el link de descarga directa (`https://drive.google.com/uc?export=download&id=...`). | C3 |
| **2.** `Error: Request body larger than maxBodyLength` | Archivo base64 > 50MB (límite de axios). | `ls -lh archivo.pdf`. | 1. Subir archivo a Google Drive/Supabase y usar `document_url`. 2. Si es inevitable, aumentar `maxBodyLength` en cliente axios (riesgo C1). | C1 |
| **3.** `Error: 401 Unauthorized` | API Key inválida o sin créditos. | `curl -H "Authorization: Bearer $MISTRAL_API_KEY" https://api.mistral.ai/v1/models`. | 1. Regenerar key en console.mistral.ai. 2. Verificar saldo en billing. | C6 |
| **4.** `Error: 429 Too Many Requests` | Rate limit excedido (10 req/min en plan gratuito). | Revisar cabeceras `x-ratelimit-remaining`. | Implementar `bottleneck` con `minTime: 6000` (1 cada 6 seg). | C1 |
| **5.** `Error: 400 Invalid document format` | El archivo no es PDF, JPEG o PNG. | `file archivo.xxx`. | Convertir a formato soportado. Mistral OCR acepta PDF, JPEG, PNG, WEBP. | - |
| **6.** `Error: 500 Internal Server Error` | Fallo temporal de Mistral. | Reintentar tras 60s. | Implementar lógica de reintentos (Ejemplo 8). | C6 |
| **7.** `Error: timeout of 120000ms exceeded` | Documento muy complejo o PDF con muchas páginas. | Procesar menos páginas con el parámetro `pages`. | Aumentar timeout en cliente axios (`timeout: 300000`). O usar cola asíncrona. | C2 |
| **8.** El markdown devuelto está vacío o es basura | PDF escaneado con baja calidad o sin texto. | Abrir el PDF manualmente para verificar. | 1. Preprocesar con herramientas como `ocrmypdf`. 2. Usar un modelo más potente si está disponible. | - |
| **9.** Las tablas no se detectan correctamente | Tabla sin bordes claros o con celdas fusionadas complejas. | Revisar el markdown generado. | Post-procesar con un LLM para corregir el formato de tabla (ver Ejemplo 11). | - |
| **10.** `Error: getaddrinfo ENOTFOUND api.mistral.ai` | Problema de DNS en VPS. | `nslookup api.mistral.ai`. | 1. Verificar `/etc/resolv.conf`. 2. Usar `8.8.8.8`. | C3 |
| **11.** `"message":"Model not found"` | Nombre de modelo incorrecto. | `curl https://api.mistral.ai/v1/models`. | Usar `mistral-ocr-latest`. | - |
| **12.** `Error: Request Entity Too Large (413)` | El documento base64 supera el límite del servidor de Mistral. | Mismo que #2. | Usar `document_url` siempre que sea posible. | C1 |
| **13.** Las imágenes extraídas (`image_base64`) no se decodifican correctamente | El string base64 puede incluir prefijo `data:image/jpeg;base64,`. | Verificar las primeras letras del string. | Limpiar el prefijo antes de guardar: `base64Data.replace(/^data:image\/\w+;base64,/, '')`. | - |
| **14.** La respuesta de Mistral incluye `pages` vacías (`markdown: ""`) | La página está en blanco o es una imagen sin texto OCR. | Revisar `page.images`. | Si la página no tiene texto, ignorarla para la ingesta RAG. | - |
| **15.** El procesamiento de muchas páginas consume mucha memoria en el chunking | El string `markdown` completo se mantiene en RAM. | Monitorear con `process.memoryUsage()`. | Procesar página por página y liberar referencias: `page.markdown = null` después de procesar. | C1 |

---

## ✅ Validación SDD y Comandos de Verificación

<!-- ai:constraint=C5 -->
### 1. Verificar conectividad con Mistral API
```bash
curl -I https://api.mistral.ai/v1/models
```
Debe responder `HTTP/2 200` o `401`.

### 2. Comprobar que la API Key está configurada (C3)
```bash
grep -q "MISTRAL_API_KEY" .env && echo "OK" || echo "Falta MISTRAL_API_KEY"
```

### 3. Monitorear tamaño de archivos procesados (C1)
```bash
find ./uploads -type f -size +20M -exec ls -lh {} \;
```

### 4. Auditar logs de OCR (C4)
```bash
grep "ocr_success" /var/log/mantis-ai.log | jq '.tenant_id' | sort | uniq -c
```

### 5. Verificar integridad de backups de configuración (C5)
```bash
sha256sum .env > .env.sha256
diff -s .env.sha256 .env.sha256.backup
```

---

## 🚀 CI/CD, IaC y Autogeneración con IA (Normas MANTIS)

### Pipeline de Integración Continua para Ingesta OCR

1. **Especificación (`ocr-agent-spec.yaml`):** Define fuentes de datos (Google Drive, URLs), modelo Mistral, bucket de almacenamiento y políticas de retención.
2. **Generación automática:** Una IA (GPT-4o) lee la especificación y genera el código TypeScript del worker, el `Dockerfile` y el workflow de GitHub Actions.
3. **Validación en CI:**
   - Linting (`eslint`).
   - Pruebas unitarias de funciones de extracción de tablas y procedimientos.
   - Evaluación de calidad del Markdown generado con métricas personalizadas.
4. **Infraestructura como Código (IaC) con Terraform:**
   ```hcl
   resource "digitalocean_droplet" "ocr_worker" {
     name   = "mantis-ocr-worker"
     size   = "s-2vcpu-4gb"
     image  = "ubuntu-22-04-x64"
     region = "nyc3"
     user_data = templatefile("${path.module}/cloud-init.yaml", {
       mistral_api_key = var.mistral_api_key
       qdrant_url      = var.qdrant_url
     })
   }

   variable "mistral_api_key" {
     type      = string
     sensitive = true
   }
   variable "qdrant_url" {
     type = string
   }
   ```
5. **Despliegue Continuo:** GitHub Actions ejecuta `terraform apply` y reinicia el servicio en el VPS.

### Hardening de Seguridad

- **Cifrado en tránsito:** HTTPS obligatorio para todas las APIs.
- **Validación de entrada:** Se verifica que las URLs de documentos sean válidas y accesibles.
- **Sanitización de archivos:** Los archivos temporales se nombran con UUIDs para evitar path traversal.
- **Aislamiento de workers:** El worker de OCR se ejecuta en un proceso separado con límites de memoria (`--max-old-space-size=512`).
- **Auditoría (C4):** Cada documento procesado se registra con `tenant_id`, `source_url`, `pages_processed` y `latency_ms`.
- **Rotación de secretos:** La API Key de Mistral se rota cada 90 días usando HashiCorp Vault.

### Autogeneración de Workflows de n8n

Para agentes que requieren ingesta documental como parte de un flujo más amplio, el sistema de autogeneración puede crear un workflow de n8n que:
1. Monitoree una carpeta de Google Drive (trigger).
2. Llame al servicio de OCR (HTTP Request).
3. Almacene el Markdown en Qdrant.
4. Notifique al administrador por Telegram.

---

## 🔗 Referencias Cruzadas y Glosario

- [[qdrant-rag-ingestion.md]] – Ingesta de los resultados del OCR en el vector store.
- [[pdf-mistralocr-processing.md]] – Skill específico para procesamiento masivo de PDFs.
- [[google-drive-qdrant-sync.md]] – Sincronización automática de Drive a Qdrant usando OCR.
- [[openrouter-api-integration.md]] – Para el paso posterior de extracción de JSON desde el Markdown.
- [[environment-variable-management.md]] – Gestión segura de `MISTRAL_API_KEY`.

**Glosario:**
- **OCR:** Optical Character Recognition (Reconocimiento Óptico de Caracteres).
- **Markdown:** Lenguaje de marcado ligero que Mistral OCR usa para representar texto estructurado.
- **Base64:** Codificación de datos binarios (como un PDF) en texto ASCII para transmisión HTTP.
- **Chunking:** División de un texto largo en fragmentos más pequeños para su vectorización.

FIN DEL ARCHIVO
<!-- ai:file-end marker - do not remove -->
Versión 2.0.0 - 2026-04-11 - Mantis-AgenticDev
