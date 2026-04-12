---
title: "video-gen-api.md"
category: "Skill"
domain: ["ai", "generico"]
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
priority: "ALTA"
version: "1.0.0"
last_updated: "2026-04-11"
ai_optimized: true
tags:
  - sdd/skill/ai
  - lang/es
related_files:
  - "01-RULES/03-SECURITY-RULES.md"
  - "02-SKILLS/AI/openrouter-api-integration.md"
  - "02-SKILLS/AI/image-gen-api.md"
  - "02-SKILLS/COMUNICACION/whatsapp-rag-openrouter.md"
  - "05-CONFIGURATIONS/environment-variable-management.md"
---

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

**Objetivo en 3 minutos:** Generar tu primer video con IA usando la API asíncrona de un proveedor.

1. **Requisito previo:** Obtener una API Key de [OpenRouter.ai](https://openrouter.ai), [Fal.ai](https://fal.ai), [Replicate](https://replicate.com) o directamente de un proveedor como Runway.
2. **Configurar variable de entorno (C3):**
   ```bash
   echo "OPENROUTER_API_KEY=sk-or-v1-..." >> .env
   ```
3. **Probar con `curl` un modelo de video asíncrono (ej: Sora 2 vía OpenRouter):**
   ```bash
   # Paso 1: Crear tarea de generación
   curl -X POST https://openrouter.ai/api/v1/video/generations \
     -H "Authorization: Bearer $OPENROUTER_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "model": "openai/sora-2",
       "prompt": "Un gato astronauta caminando sobre la luna",
       "duration": 5
     }'
   # Paso 2: Consultar estado (usando el ID devuelto)
   curl https://openrouter.ai/api/v1/video/generations/{id} \
     -H "Authorization: Bearer $OPENROUTER_API_KEY"
   ```
✅ **Deberías ver:** Primero un JSON con `id` y `status: "processing"`. Luego, tras unos minutos, `status: "completed"` con una URL de descarga.
❌ **Si ves:** `{"error":{"message":"No endpoints found matching your data policy"}}` → Ve a Troubleshooting #2.

⚠️ **Advertencia para Junior:** La generación de video es un proceso **asíncrono** y puede tardar desde 30 segundos hasta varios minutos. **Nunca** esperes la respuesta en el mismo ciclo de vida de un webhook (WhatsApp/Telegram). Usa siempre colas (BullMQ) y webhooks de notificación para manejar los resultados (C2). Los costos son elevados: un video de 5 segundos puede costar entre $0.25 y $2.50 dependiendo del modelo.

---

## 🎯 Propósito y Alcance

Este skill documenta los patrones de integración para consumir APIs de generación de video con IA en el ecosistema MANTIS. Está diseñado para la autogeneración de agentes capaces de crear contenido audiovisual (marketing, tutoriales, resúmenes visuales) a partir de texto o imágenes.

**Cubre:**
- Los principales modelos de video disponibles en 2026: **Sora 2/2 Pro (OpenAI)**, **Veo 3.1/3.1 Lite (Google)**, **Runway Gen-4 (Turbo/Aleph)**, **Kling 2.0/2.6 (ByteDance)**, **Pika 2.0**, **Luma Dream Machine**, **Hailuo 02/2.3 (MiniMax)**, **Wanx 2.1/2.6 (Alibaba)**, **Seedance 2.0 (ByteDance)**, **Vidu Q3** y **Stable Video Diffusion**.
- **Arquitectura asíncrona robusta:** Uso de BullMQ (Redis) para encolar tareas, webhooks para notificar finalización y almacenamiento en Supabase Storage o Google Drive.
- **Hardening de seguridad:** Validación de prompts, filtrado de contenido NSFW con Azure Content Safety, cifrado en tránsito y reposo, y marcas de agua para contenido generado (C4).
- **CI/CD e IaC:** Despliegue automatizado del servicio de video con Terraform, Pulumi y GitHub Actions.
- **Autogeneración por IA:** Uso de GPT-4o para generar prompts de video optimizados a partir de descripciones de negocio (RAG para video).

**No cubre:**
- Modelos de video en tiempo real (streaming) o avatares parlantes (HeyGen, D-ID), que se documentan en skills separados.
- Edición de video avanzada (inpainting/outpainting de video), aunque se mencionan APIs compatibles.
- Modelos self-hosted (prohibido por C6), solo APIs cloud.

### Modelos de Video Objetivo (2026)

| Modelo | Proveedor | Precio (aprox.) | Duración/Resolución | Características Clave |
| :--- | :--- | :--- | :--- | :--- |
| **Sora 2 / 2 Pro** | OpenAI | $0.10‑$0.50 / seg | 60s / 1080p | Coherencia narrativa, física realista. |
| **Veo 3.1 Lite** | Google Vertex AI | $0.05‑$0.08 / seg | 8s / 1080p | Mejor relación costo/calidad, audio espacial. |
| **Veo 3.1 Fast/Pro** | Google Vertex AI | $0.35‑$0.50 / seg | 60s+ / 4K | Fotorrealismo extremo, video a video. |
| **Runway Gen-4 Turbo** | Runway / Fal.ai | $0.50 / seg | 45s / 4K | Control creativo profesional, multi-shot. |
| **Kling 2.0/2.6** | ByteDance | $0.29‑$0.92 / video | 5‑10s / 1080p | Consistencia en larga duración, ideal para redes sociales. |
| **Pika 2.0** | Pika Labs | $0.11‑$0.16 / seg | 5‑10s / 720p | Scene Ingredients (personalización de personajes). |
| **Luma Dream Machine** | Luma Labs | $0.20 / generación | 5s / 1080p | Cinematic motion, interfaz sencilla. |
| **Hailuo 02/2.3** | MiniMax | $0.25‑$0.30 / video | 10s / 1080p | Animación facial consistente, bajo costo. |
| **Wanx 2.1/2.6** | Alibaba Cloud | $0.12‑$0.28 / gen | 5‑10s / 1080p | Precisión de movimiento, multi-shot. |
| **Seedance 2.0** | ByteDance | ~$0.58 / seg | 15s / 1080p | Audio nativo sincronizado, consistencia cross-shot. |
| **Vidu Q3** | ShengShu | $0.10‑$0.25 / seg | 4‑8s / 1080p | Rápido, buena adherencia al prompt. |
| **Stable Video Diffusion** | Stability AI | $0.005‑$0.02 / seg | 4s / 1024x576 | Open-source, ideal para prototipado. |

*Precios según APIs y dashboards de proveedores en Abril 2026.*

---

## 📐 Fundamentos (De 0 a Intermedio)

### El Pipeline de Generación de Video

A diferencia de las APIs de imagen (síncronas), las APIs de video son **asíncronas**. El flujo típico es:

1. **Creación de tarea:** Envías el prompt y los parámetros. La API responde inmediatamente con un `task_id` o `generation_id`.
2. **Procesamiento en segundo plano:** El proveedor genera el video (30s a 5min).
3. **Notificación u obtención del resultado:**
   - **Webhook:** Configuras una URL en tu panel de desarrollador. La API te notifica cuando el video está listo.
   - **Polling (consulta periódica):** Consultas repetidamente el endpoint de estado hasta que `status === "completed"`.

**¿Por qué asíncrono?** Los modelos de video son computacionalmente intensivos. Intentar una generación síncrona bloquearía los servidores del proveedor y excedería cualquier timeout HTTP razonable (C2).

### Proveedores y Gateways Clave

- **OpenRouter (video endpoint experimental):** Soporta Sora 2, Veo 3.1 y Kling. Unifica la autenticación y el formato de petición. Ideal para fallback.
- **Fal.ai:** Especializado en modelos open-source (Flux, Stable Video) y Runway Gen-4. Ofrece webhooks robustos y colas gestionadas.
- **Replicate:** Similar a Fal, con un catálogo muy amplio de modelos de video. Cold starts en planes gratuitos.
- **APIs Nativas (Vertex AI, Runway, Pika):** Para casos de uso que requieren el 100% de las funcionalidades (ej: "Scene Ingredients" de Pika).

---

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

### Aplicación de Constraints C1 y C2

- **C1 (RAM ≤ 4GB):** Los videos generados pueden pesar cientos de MB. **Nunca descargues videos en el VPS.** El worker debe subirlos directamente a Supabase Storage o Google Drive usando streams o URLs firmadas, sin pasar por el sistema de archivos local.
- **C2 (1 vCPU por op. crítica):** La generación de video es I/O de red (esperar). El VPS solo orquesta. El procesamiento posterior (ej: añadir marca de agua con `ffmpeg`) debe ejecutarse con `nice -n 19` y en un worker separado, limitado a 1 concurrencia.

### Configuración de Workers y Colas (BullMQ)

```typescript
import { Queue, Worker } from 'bullmq';
import IORedis from 'ioredis';

const connection = new IORedis({ maxRetriesPerRequest: null });

// Cola para tareas de generación de video
export const videoQueue = new Queue('video-generation', { connection });

// Worker: solo 1 trabajo concurrente para respetar C2
const worker = new Worker('video-generation', async (job) => {
  // 1. Crear tarea en API de video (Sora, Veo, etc.)
  // 2. Guardar task_id en BD
  // 3. Configurar polling o esperar webhook
  // 4. Al completar, subir video a Supabase
}, { connection, concurrency: 1 });
```

### Límites de Duración y Tamaño

- **WhatsApp Cloud API:** Los mensajes de video están limitados a **16MB**.
- **Telegram Bot API:** Los archivos de video pueden pesar hasta **50MB** (con `sendVideo`).

Para videos generados que excedan estos límites, se debe:
1. **Comprimir** con `ffmpeg` (reducir bitrate, resolución).
2. **Enviar un enlace** a una galería web (ej: Supabase Storage público) en lugar del archivo directo.

---

## 🔗 Integración con Stack Existente (n8n, Qdrant, Supabase)

### Diagrama de Flujo de Datos

```
[Usuario WhatsApp/Telegram] → (Webhook) → [API Gateway] → [Cola BullMQ (video)]
                                                              ↓
[Usuario] ← (API WhatsApp/Telegram) ← [Worker] ← [Supabase Storage] ← [API de Video (Sora/Veo/Kling)]
                                                              ↓
                                                        [Webhook de notificación (opcional)]
                                                              ↓
                                                        [n8n Workflow (post-procesamiento)]
```

### Integración con n8n

Para flujos complejos que requieren lógica de negocio (ej: "si el video es para Instagram, recortar a 9:16"), el worker puede invocar un **webhook de n8n** una vez que el video está almacenado en Supabase. n8n ejecuta el workflow de post-producción y notifica al usuario final.

---

## 🛠️ 15 Ejemplos de Configuración (Copy-Paste Validables)

### Ejemplo 1: Generación con Sora 2 (OpenAI) usando OpenRouter (Asíncrono)
**Objetivo**: Crear un video a partir de un prompt de texto.
**Nivel**: 🟡

```typescript
import axios from 'axios';

async function createSora2Video(prompt: string): Promise<string> {
  const response = await axios.post(
    'https://openrouter.ai/api/v1/video/generations',
    {
      model: 'openai/sora-2',
      prompt,
      duration: 5,
      aspect_ratio: '16:9'
    },
    { headers: { Authorization: `Bearer ${process.env.OPENROUTER_API_KEY}` } }
  );
  return response.data.id; // task_id para consultar estado
}

async function checkVideoStatus(taskId: string): Promise<any> {
  const response = await axios.get(
    `https://openrouter.ai/api/v1/video/generations/${taskId}`,
    { headers: { Authorization: `Bearer ${process.env.OPENROUTER_API_KEY}` } }
  );
  return response.data; // { status: 'processing' | 'completed', video_url?: string }
}
```
✅ **Deberías ver:** Un `task_id` y, tras varios minutos, una URL de video.
❌ **Si ves:** `Error: 402 Payment Required` → Ve a Troubleshooting #3.

### Ejemplo 2: Worker BullMQ para Sora 2 con Polling
**Objetivo**: Procesar videos en background sin bloquear el webhook.
**Nivel**: 🟡

```typescript
import { Worker } from 'bullmq';
import IORedis from 'ioredis';

const connection = new IORedis({ maxRetriesPerRequest: null });

new Worker('video-generation', async (job) => {
  const { tenant_id, prompt, userId } = job.data;

  // 1. Crear tarea en Sora 2
  const taskId = await createSora2Video(prompt);

  // 2. Polling cada 5 segundos (máx 20 intentos = 100s)
  let videoUrl: string | null = null;
  for (let i = 0; i < 20; i++) {
    await new Promise(r => setTimeout(r, 5000));
    const status = await checkVideoStatus(taskId);
    if (status.status === 'completed') {
      videoUrl = status.video_url;
      break;
    }
  }

  if (!videoUrl) throw new Error('Video generation timeout');

  // 3. Subir a Supabase y notificar
  const publicUrl = await uploadVideoToSupabase(tenant_id, videoUrl);
  await notifyUser(userId, `¡Tu video está listo! ${publicUrl}`);
}, { connection, concurrency: 1 });
```

### Ejemplo 3: Generación con Runway Gen-4 Turbo (Fal.ai)
**Objetivo**: Usar Fal.ai para generar videos de alta calidad.
**Nivel**: 🟡

```typescript
import { fal } from '@fal-ai/client';

fal.config({ credentials: process.env.FAL_KEY });

async function generateRunwayVideo(prompt: string): Promise<string> {
  const result = await fal.subscribe('fal-ai/runway-gen4/turbo', {
    input: { prompt, duration: 5, aspect_ratio: '16:9' },
    logs: true,
    onQueueUpdate: (update) => console.log('Queue status:', update.status)
  });
  return result.data.video.url;
}
```
✅ **Deberías ver:** URL del video generado.
❌ **Si ves:** `Error: 401 Unauthorized` → Verifica tu `FAL_KEY`.

### Ejemplo 4: Generación con Google Veo 3.1 Lite (Vertex AI)
**Objetivo**: Aprovechar el modelo más económico de Google.
**Nivel**: 🔴

```python
from google.cloud import aiplatform

def generate_veo_video(prompt: str, project_id: str, location: str = "us-central1"):
    aiplatform.init(project=project_id, location=location)
    model = aiplatform.Model("veo-3.1-lite")
    response = model.predict(instances=[{"prompt": prompt, "duration": 8}])
    return response.predictions[0]["video_uri"]
```
✅ **Deberías ver:** URI de Google Cloud Storage con el video.
❌ **Si ves:** `Error: 403 Permission denied` → Asegúrate de que la cuenta de servicio tenga rol `Vertex AI User`.

### Ejemplo 5: Webhook de notificación (Fal.ai)
**Objetivo**: Recibir notificación automática cuando el video esté listo.
**Nivel**: 🔴

```typescript
// En tu servidor Express
app.post('/webhooks/fal', async (req, res) => {
  const { request_id, status, payload } = req.body;
  if (status === 'COMPLETED') {
    const videoUrl = payload.video.url;
    // Procesar video (subir a Supabase, notificar usuario)
  }
  res.sendStatus(200);
});

// Al crear la tarea en Fal.ai
const result = await fal.queue.submit('fal-ai/runway-gen4/turbo', {
  input: { prompt },
  webhookUrl: 'https://tudominio.com/webhooks/fal'
});
```

### Ejemplo 6: Almacenamiento en Supabase Storage con Stream (evita RAM)
**Objetivo**: Subir video directamente desde URL sin descargar al VPS.
**Nivel**: 🟡

```typescript
import axios from 'axios';
import { supabase } from './supabase-client';

async function uploadVideoFromUrl(tenantId: string, videoUrl: string): Promise<string> {
  const response = await axios.get(videoUrl, { responseType: 'stream' });
  const fileName = `${tenantId}/${Date.now()}.mp4`;
  
  const { data, error } = await supabase.storage
    .from('videos')
    .upload(fileName, response.data, {
      contentType: 'video/mp4',
      cacheControl: '31536000'
    });
  if (error) throw error;
  
  const { data: { publicUrl } } = supabase.storage.from('videos').getPublicUrl(fileName);
  return publicUrl;
}
```

### Ejemplo 7: Rate Limiting por Tenant (Redis)
**Objetivo**: Evitar que un solo tenant consuma todos los créditos.
**Nivel**: 🟡

```typescript
import { RateLimiterRedis } from 'rate-limiter-flexible';
import redis from './redis-client';

const rateLimiter = new RateLimiterRedis({
  storeClient: redis,
  keyPrefix: 'video_rl',
  points: 3,    // 3 generaciones
  duration: 3600 // por hora
});

async function limitedGenerate(tenantId: string, prompt: string) {
  try {
    await rateLimiter.consume(tenantId);
    return await generateRunwayVideo(prompt);
  } catch (rejRes) {
    throw new Error('Has excedido tu límite de generaciones por hora.');
  }
}
```

### Ejemplo 8: Validación de prompt con Azure Content Safety
**Objetivo**: Filtrar contenido inapropiado antes de enviar a la API.
**Nivel**: 🔴

```typescript
import { ContentSafetyClient } from '@azure-rest/ai-content-safety';

const client = new ContentSafetyClient(process.env.AZURE_CS_ENDPOINT!, {
  key: process.env.AZURE_CS_KEY!
});

async function validateVideoPrompt(prompt: string): Promise<boolean> {
  const response = await client.path('/text:analyze').post({
    body: { text: prompt, categories: ['Hate', 'Sexual', 'Violence', 'SelfHarm'] }
  });
  return !response.body.categoriesAnalysis.some(c => c.severity > 2);
}
```

### Ejemplo 9: Compresión de video con ffmpeg (si excede 16MB para WhatsApp)
**Objetivo**: Reducir el tamaño para cumplir con límites de mensajería.
**Nivel**: 🟡

```typescript
import { spawn } from 'child_process';
import { Readable } from 'stream';

async function compressVideoForWhatsApp(inputUrl: string): Promise<Buffer> {
  // Descargar video con axios (stream)
  const response = await axios.get(inputUrl, { responseType: 'stream' });
  
  return new Promise((resolve, reject) => {
    const ffmpeg = spawn('ffmpeg', [
      '-i', 'pipe:0',
      '-c:v', 'libx264', '-crf', '28', // Mayor compresión
      '-vf', 'scale=640:-2',           // Reducir resolución
      '-f', 'mp4', 'pipe:1'
    ]);
    const chunks: Buffer[] = [];
    ffmpeg.stdout.on('data', (chunk) => chunks.push(chunk));
    ffmpeg.on('close', (code) => {
      if (code === 0) resolve(Buffer.concat(chunks));
      else reject(new Error('ffmpeg failed'));
    });
    response.data.pipe(ffmpeg.stdin);
  });
}
```

### Ejemplo 10: Integración con Telegram (Envío de video)
**Objetivo**: Enviar el video generado a un chat de Telegram.
**Nivel**: 🟢

```typescript
import axios from 'axios';

async function sendTelegramVideo(chatId: string, videoUrl: string, caption?: string) {
  await axios.post(`https://api.telegram.org/bot${process.env.TELEGRAM_BOT_TOKEN}/sendVideo`, {
    chat_id: chatId,
    video: videoUrl,
    caption,
    supports_streaming: true
  });
}
```

### Ejemplo 11: Evaluación de calidad con VBench (CI/CD)
**Objetivo**: Validar que los videos generados cumplen estándares de calidad.
**Nivel**: 🔴

```python
# test_video_quality.py
import pytest
from vbench import VBench

def test_video_quality(video_path: str, prompt: str):
    vbench = VBench(device="cuda")
    scores = vbench.evaluate(video_path, prompt)
    assert scores['motion_smoothness'] > 0.7
    assert scores['semantic_consistency'] > 0.8
```

### Ejemplo 12: Despliegue de Infraestructura con Pulumi (IaC)
**Objetivo**: Aprovisionar el VPS y configurar el servicio de video.
**Nivel**: 🔴

```typescript
// index.ts (Pulumi)
import * as digitalocean from "@pulumi/digitalocean";

const droplet = new digitalocean.Droplet("video-agent", {
  image: "ubuntu-22-04-x64",
  size: digitalocean.DropletSlug.DropletS2VCPU4GB, // C1/C2
  region: digitalocean.Region.NYC3,
  userData: `#!/bin/bash
    git clone https://github.com/Mantis-AgenticDev/video-agent.git
    cd video-agent && npm ci
    pm2 start ecosystem.config.js`
});

export const ip = droplet.ipv4Address;
```

### Ejemplo 13: GitHub Actions para despliegue continuo
**Objetivo**: Automatizar despliegue en cada push a main.
**Nivel**: 🔴

```yaml
# .github/workflows/deploy-video-agent.yml
name: Deploy Video Agent
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: pulumi/actions@v4
        with:
          command: up
          stack-name: prod
          work-dir: infra
        env:
          PULUMI_ACCESS_TOKEN: ${{ secrets.PULUMI_ACCESS_TOKEN }}
```

### Ejemplo 14: Autogeneración de prompts de video con GPT-4o
**Objetivo**: Usar LLM para crear prompts de video optimizados a partir de descripciones de negocio.
**Nivel**: 🔴

```typescript
async function autoGenerateVideoPrompt(businessDesc: string, targetPlatform: 'instagram' | 'tiktok'): Promise<string> {
  const llmPrompt = `
    Eres un experto en generación de videos con IA.
    A partir de la siguiente descripción de negocio, crea un prompt detallado para generar un video de marketing para ${targetPlatform}.
    Descripción: ${businessDesc}
    El prompt debe incluir: sujeto, acción, escena, estilo visual (cinematic/realistic), duración estimada, y relación de aspecto (${targetPlatform === 'tiktok' ? '9:16' : '16:9'}).
  `;
  return await askGPT4o(llmPrompt);
}
```

### Ejemplo 15: Watermarking de videos generados (Hardening C4)
**Objetivo**: Añadir marca de agua para trazabilidad y cumplimiento normativo.
**Nivel**: 🟡

```typescript
import ffmpeg from 'fluent-ffmpeg';

async function addWatermarkToVideo(inputUrl: string, tenantId: string): Promise<string> {
  const outputPath = `/tmp/${tenantId}-watermarked.mp4`;
  return new Promise((resolve, reject) => {
    ffmpeg(inputUrl)
      .outputOptions('-vf', `drawtext=text='Mantis Agentic - ${tenantId}':x=10:y=10:fontsize=24:fontcolor=white@0.5`)
      .on('end', () => resolve(outputPath))
      .on('error', reject)
      .save(outputPath);
  });
}
```

---

## 🐞 15 Errores Comunes y Troubleshooting

| Error Exacto (copiable) | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso | Constraint Afectado |
| :--- | :--- | :--- | :--- | :--- |
| **1.** `Error: 401 Unauthorized` | API Key inválida o expirada. | `curl -H "Authorization: Bearer $KEY" https://api.openrouter.ai/api/v1/auth/key` | 1. Regenerar API Key en el panel de control. 2. Verificar que la variable de entorno se cargue correctamente. | C3 |
| **2.** `"error":{"message":"No endpoints found matching your data policy"}` (OpenRouter) | Configuración de privacidad. | Revisar `https://openrouter.ai/settings`. | Activar "Enable training and logging (chatroom and API)". Requerido para modelos de video. | C6 |
| **3.** `Error: 402 Payment Required` | Créditos insuficientes. | Revisar saldo en el panel del proveedor. | Añadir créditos o usar modelos gratuitos/económicos (Veo 3.1 Lite, Hailuo). | C6 |
| **4.** `Error: 429 Rate limit exceeded` | Límite de RPM/TPM excedido. | Revisar cabeceras `x-ratelimit-remaining`. | Implementar rate limiter (Ejemplo 7) y/o colas con backoff exponencial. | C1 |
| **5.** `Error: 400 Invalid prompt` | Prompt contiene términos bloqueados o excede longitud. | Validar prompt con Azure Content Safety (Ejemplo 8). | Sanitizar prompt o acortarlo (máx 500 caracteres recomendado). | - |
| **6.** `Error: Request timeout` | La generación de video excede el timeout del cliente HTTP (60s). | Usar endpoints asíncronos (polling/webhooks). | **Nunca** usar llamadas síncronas. Implementar polling (Ejemplo 2) o webhooks (Ejemplo 5). | C2 |
| **7.** `Error: Job stalled` en BullMQ | El worker tardó más de 5 minutos en completar el polling. | Revisar logs del worker. | Aumentar el `lockDuration` del worker a 10 minutos y el número máximo de intentos de polling. | C2 |
| **8.** `Error: 413 Payload Too Large` | El video generado excede el límite de tamaño del destino (WhatsApp 16MB). | `ffprobe video.mp4` para ver tamaño/duración. | Comprimir con ffmpeg (Ejemplo 9) o enviar un enlace en lugar del archivo. | C1 |
| **9.** `Error: getaddrinfo ENOTFOUND api.fal.ai` | Problema de DNS en VPS. | `nslookup api.fal.ai`. | 1. Verificar `/etc/resolv.conf`. 2. Usar `8.8.8.8`. | C3 |
| **10.** `Error: 400 Aspect ratio not supported` | Relación de aspecto no soportada por el modelo. | Revisar documentación del modelo. | Usar relaciones estándar: 16:9, 9:16, 1:1, 4:3. | - |
| **11.** `Error: 500 Internal Server Error` | Fallo temporal del proveedor. | Revisar página de estado del proveedor. | Implementar fallback a otro modelo (ej: si Sora falla, usar Veo). | C6 |
| **12.** `Error: Webhook signature verification failed` | La firma HMAC del webhook no coincide. | Verificar que el secreto configurado en el panel coincida con `process.env.WEBHOOK_SECRET`. | Calcular firma esperada y comparar. | C3 |
| **13.** `Error: Video generation timeout` | El modelo tardó más de lo esperado (>5 min). | Consultar el estado directamente en el dashboard del proveedor. | Aumentar el tiempo de polling o usar webhooks. | C2 |
| **14.** `Error: 403 Forbidden` en Supabase Storage | RLS bloquea la subida. | Revisar políticas RLS en Supabase. | Añadir política `INSERT` para el bucket `videos` con `tenant_id = (auth.jwt() ->> 'tenant_id')`. | C4 |
| **15.** `Error: Invalid video format` | El video devuelto por la API no es MP4. | `ffprobe video.mp4`. | Convertir a MP4 con ffmpeg antes de subir a Supabase. | - |

---

## ✅ Validación SDD y Comandos de Verificación

<!-- ai:constraint=C5 -->
### 1. Verificar conectividad con OpenRouter (video)
```bash
curl -I https://openrouter.ai/api/v1/video/generations
```

### 2. Auditar uso de `tenant_id` en logs (C4)
```bash
grep -c '"tenant_id":"' /var/log/mantis-video.log
```

### 3. Chequeo de secretos (C3)
```bash
grep -r "sk-or-v1-\|fal-key\|vertex-ai-key" /opt/mantis --exclude-dir=node_modules
```

### 4. Validar pipeline de CI/CD
```bash
npm run test:video-quality
```

### 5. Verificar límites de recursos del worker (C1/C2)
```bash
pm2 monit mantis-video-worker
```

### 6. Backup de la configuración (C5)
```bash
sha256sum .env > .env.sha256
rsync -avz .env.sha256 backup@server:/backup/configs/
```

---

## 🚀 CI/CD, IaC y Autogeneración con IA (Normas MANTIS)

### Pipeline de CI/CD para Agentes de Video

1. **Especificación (`video-agent-spec.yaml`):** Define el modelo de video a usar, la duración por defecto, el límite de generaciones por tenant y el bucket de almacenamiento.
2. **Generación automática:** Una IA (GPT-4o) lee la especificación y genera el código TypeScript del worker, el `Dockerfile` y el workflow de GitHub Actions.
3. **Pruebas en CI:**
   - Linting (`eslint`).
   - Pruebas unitarias de funciones de creación de tareas y polling.
   - Evaluación de calidad de video con **VBench** (métricas de suavidad de movimiento, consistencia semántica).
4. **Infraestructura como Código (IaC):** Pulumi o Terraform aprovisionan el VPS, configuran las variables de entorno (desde HashiCorp Vault) y despliegan el servicio.
5. **Despliegue continuo:** GitHub Actions construye la imagen Docker y la despliega.

### Hardening de Seguridad para Video

- **Cifrado en tránsito:** HTTPS para todas las APIs. URLs firmadas para acceder a videos en Supabase.
- **Validación de prompts:** Uso de Azure Content Safety o filtros similares para bloquear contenido NSFW y deepfakes no consentidos.
- **Watermarking:** Añadir marca de agua visible con `tenant_id` para trazabilidad y cumplimiento de normativas de transparencia (C4).
- **Aislamiento de workers:** El worker de video se ejecuta en un proceso separado con límites de memoria (`--max-old-space-size=512`).
- **Auditoría (C4):** Cada generación se registra con `tenant_id`, `prompt`, `modelo`, `costo_estimado` y `duración`.
- **Cumplimiento normativo:** Etiquetado de contenido sintético según regulaciones locales (ej: India IT Rules 2026) mediante metadatos en Supabase.

### Autogeneración de Workflows de n8n

Para agentes que requieren generación de video como parte de un flujo más amplio (ej: "crear un reel de Instagram a partir de una descripción de producto"), el sistema de autogeneración puede crear un workflow de n8n que:
1. Recibe la descripción desde el webhook de WhatsApp.
2. Llama a GPT-4o para generar un prompt de video optimizado (Ejemplo 14).
3. Invoca al servicio de video (vía HTTP Request).
4. Espera la URL del video.
5. Aplica watermarking y compresión.
6. Envía el video al usuario.

---

## 🔗 Referencias Cruzadas y Glosario

- [[openrouter-api-integration.md]] - Patrón general para consumir APIs vía OpenRouter.
- [[image-gen-api.md]] - Patrones de generación de imágenes.
- [[whatsapp-rag-openrouter.md]] - Orquestación de agentes de WhatsApp.
- [[gpt-integration.md]] - Integración con GPT-4o para autogeneración de prompts.
- [[environment-variable-management.md]] - Gestión segura de secretos.

**Glosario:**
- **T2V:** Text-to-Video. Generación de video a partir de texto.
- **I2V:** Image-to-Video. Generación de video a partir de una imagen.
- **Polling:** Consulta periódica del estado de una tarea asíncrona.
- **Webhook:** URL de callback que el proveedor llama cuando la tarea asíncrona finaliza.
- **VBench:** Framework de evaluación de calidad de video generado por IA.
- **Scene Ingredients:** Tecnología de Pika para personalizar personajes y objetos en videos.

FIN DEL ARCHIVO
<!-- ai:file-end marker - do not remove -->
Versión 1.0.0 - 2026-04-11 - Mantis-AgenticDev

