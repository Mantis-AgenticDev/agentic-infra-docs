---
title: "image-gen-api.md"
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
  - "02-SKILLS/COMUNICACION/whatsapp-rag-openrouter.md"
  - "05-CONFIGURATIONS/environment-variable-management.md"
---

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

**Objetivo en 3 minutos:** Generar tu primera imagen con IA usando OpenRouter o Replicate.

1. **Requisito previo:** Obtener una API Key de [OpenRouter.ai](https://openrouter.ai) o [Replicate.com](https://replicate.com).
2. **Configurar variable de entorno (C3):**
   ```bash
   echo "OPENROUTER_API_KEY=sk-or-v1-..." >> .env
   ```
3. **Probar con `curl` un modelo de imagen:**
   ```bash
   curl https://openrouter.ai/api/v1/chat/completions \
     -H "Authorization: Bearer $OPENROUTER_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "model": "google/nano-banana-2",
       "messages": [{"role": "user", "content": "Genera una imagen de un gato astronauta"}],
       "modalities": ["image", "text"]
     }'
   ```
✅ **Deberías ver:** Un JSON con `choices[0].message.images` conteniendo la imagen en base64 o URL.
❌ **Si ves:** `{"error":{"message":"No endpoints found matching your data policy"}}` → Ve a Troubleshooting #2.

⚠️ **Advertencia para Junior:** La generación de imágenes consume créditos. Usa modelos gratuitos como `nano-banana-2` para pruebas. Nunca hardcodees API Keys (C3).

---

## 🎯 Propósito y Alcance

Este skill documenta los patrones de integración para consumir APIs de generación de imágenes con IA en el ecosistema MANTIS. Cubre desde modelos gratuitos de alta calidad hasta opciones premium para producción, con énfasis en la autogeneración de activos visuales para agentes (menús, catálogos, materiales de marketing).

**Cubre:**
- Los principales modelos de imagen disponibles en 2026: **Nano Banana 2 (Gemini 3.1 Flash Image)**, **FLUX.2**, **Qwen-Image-2.0**, **Stable Diffusion XL**, **DALL-E 3**, **Imagen 3**.
- Estrategias de implementación para generación síncrona/asíncrona, almacenamiento en Supabase/Google Drive y caché de resultados.
- **Hardening de seguridad**: Filtrado de contenido, validación de prompts, cifrado de imágenes en tránsito y reposo.
- **CI/CD e IaC**: Despliegue automatizado del servicio de imágenes con Terraform y GitHub Actions.
- **Autogeneración por IA**: Uso de GPT-4o para generar dinámicamente prompts de imagen a partir de descripciones de negocio.

**No cubre:**
- Modelos de video (Runway, Pika, Sora), que se documentan en `video-gen-api.md`.
- Edición de imágenes (inpainting/outpainting), aunque se mencionan APIs compatibles.
- Modelos self-hosted (prohibido por C6), solo APIs cloud.

### Modelos de Imagen Objetivo (2026)

| Modelo | Proveedor/Endpoint | Precio (aprox.) | Características Clave |
| :--- | :--- | :--- | :--- |
| **Nano Banana 2** | Google (vía OpenRouter) | $0.134 (1K/2K), $0.24 (4K) | Mejor texto en imágenes, Flash speed, edición multimodal |
| **FLUX.2 Schnell** | Black Forest Labs | $0.003 / imagen | Más rápido del mercado, 4 pasos, ideal para prototipado |
| **Qwen-Image-2.0** | Alibaba (vía SiliconFlow) | $0.008 / imagen | 2K fotorrealismo, tipografía precisa, edición avanzada |
| **Stable Diffusion XL** | Stability AI / Replicate | $0.005‑$0.065 / imagen | Open-source, flexible, self-hosting posible (no en MANTIS) |
| **DALL-E 3** | OpenAI | $0.04‑$0.12 / imagen | Premium, mejor integración con GPT-4o, texto en imágenes |
| **Imagen 3** | Google Vertex AI | $0.02‑$0.04 / imagen | Fotorrealismo extremo, via Gemini API |

---

## 📐 Fundamentos (De 0 a Intermedio)

### ¿Cómo Funcionan las APIs de Imagen?

Las APIs de generación de imágenes operan bajo dos modalidades principales:

1. **Text-to-Image (T2I):** Reciben un prompt de texto y devuelven una imagen. Ejemplo: "Un gato astronauta en estilo realista".
2. **Multimodal (Chat + Image):** Modelos como Nano Banana 2 pueden recibir tanto texto como imágenes de entrada, permitiendo edición y variaciones.

**Flujo típico de una API de imagen:**
```
[Prompt] → [API de Imagen] → [Imagen (base64/URL)] → [Almacenamiento (S3/Supabase)] → [CDN/Usuario]
```

**¿Por qué no self-hosted en MANTIS?**
El constraint C6 prohíbe modelos locales. Usar APIs cloud permite:
- No consumir GPU en el VPS (C1/C2).
- Escalar sin gestionar infraestructura.
- Acceder a modelos state-of-the-art sin descargar pesos.

### Proveedores Clave y Gateways

- **OpenRouter:** Unifica acceso a 320+ modelos, incluyendo imagen. Soporta `modalities: ["image"]` para modelos que solo generan imagen.
- **Replicate:** Plataforma especializada en modelos open-source. Pay-per-use, cold starts en planes gratuitos.
- **Fal.ai:** Similar a Replicate, con énfasis en baja latencia y modelos Flux.
- **SiliconFlow:** Proveedor chino con excelente soporte para Qwen-Image-2.0.

---

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

### Aplicación de Constraints C1 y C2

- **C1 (RAM ≤ 4GB):** Las imágenes generadas pueden pesar varios MB. **Nunca acumules imágenes en memoria.** Usa streams para subirlas directamente a Supabase Storage o Google Drive sin pasar por RAM del VPS.
- **C2 (1 vCPU):** La generación de imágenes es I/O de red. El VPS solo espera la respuesta de la API (latencia típica: 2-15 segundos). Para no bloquear el webhook, usa **colas asíncronas** (BullMQ).

### Configuración de Cliente HTTP Optimizado

```typescript
import axios from 'axios';
import http from 'http';

const httpAgent = new http.Agent({ keepAlive: true, maxSockets: 3 }); // C1

export const imageClient = axios.create({
  baseURL: 'https://openrouter.ai/api/v1',
  timeout: 60000, // 60 segundos (generación puede tardar)
  headers: {
    'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}`,
    'HTTP-Referer': process.env.APP_URL || 'http://localhost:3000',
    'X-Title': 'MantisAgenticDev'
  },
  httpAgent
});
```

---

## 🔗 Integración con Stack Existente (n8n, Qdrant, Supabase)

### Pipeline de Generación y Almacenamiento

```typescript
import { imageClient } from './image-client';
import { supabase } from './supabase-client';

export async function generateAndStoreImage(
  tenantId: string,
  prompt: string,
  style: string = 'photorealistic'
) {
  // 1. Generar imagen con Nano Banana 2
  const response = await imageClient.post('/chat/completions', {
    model: 'google/nano-banana-2',
    messages: [{ role: 'user', content: `${prompt}. Style: ${style}` }],
    modalities: ['image', 'text']
  });

  const imageBase64 = response.data.choices[0].message.images[0];
  const imageBuffer = Buffer.from(imageBase64, 'base64');

  // 2. Subir a Supabase Storage (evita cargar en RAM del VPS)
  const fileName = `${tenantId}/${Date.now()}-${uuidv4()}.png`;
  const { data, error } = await supabase.storage
    .from('generated-images')
    .upload(fileName, imageBuffer, {
      contentType: 'image/png',
      cacheControl: '31536000' // 1 año
    });

  if (error) throw error;

  // 3. Obtener URL pública
  const { data: { publicUrl } } = supabase.storage
    .from('generated-images')
    .getPublicUrl(fileName);

  // 4. Log de auditoría (C4)
  console.log(JSON.stringify({
    event: 'image_generated',
    tenant_id: tenantId,
    prompt: prompt.slice(0, 100),
    url: publicUrl
  }));

  return publicUrl;
}
```

---

## 🛠️ 15 Ejemplos de Configuración (Copy-Paste Validables)

### Ejemplo 1: Generación básica con Nano Banana 2 (OpenRouter)
**Objetivo**: Probar el modelo gratuito de Google.
**Nivel**: 🟢

```typescript
import axios from 'axios';

async function generateNanoBanana(prompt: string): Promise<string> {
  const response = await axios.post(
    'https://openrouter.ai/api/v1/chat/completions',
    {
      model: 'google/nano-banana-2',
      messages: [{ role: 'user', content: prompt }],
      modalities: ['image', 'text']
    },
    { headers: { Authorization: `Bearer ${process.env.OPENROUTER_API_KEY}` } }
  );
  return response.data.choices[0].message.images[0]; // base64
}
```
✅ **Deberías ver:** String base64 con la imagen PNG.
❌ **Si ves:** `Error: 400 Invalid modalities` → Asegúrate de incluir `modalities: ["image", "text"]`.

### Ejemplo 2: Generación con Replicate (Flux Schnell)
**Objetivo**: Usar el modelo más rápido y económico.
**Nivel**: 🟢

```typescript
import Replicate from 'replicate';

const replicate = new Replicate({ auth: process.env.REPLICATE_API_KEY });

async function generateFluxSchnell(prompt: string): Promise<string> {
  const output = await replicate.run(
    'black-forest-labs/flux-schnell',
    { input: { prompt, num_outputs: 1, aspect_ratio: '1:1' } }
  );
  return output[0]; // URL de la imagen
}
```
✅ **Deberías ver:** URL de la imagen generada.
❌ **Si ves:** `Error: 401 Unauthorized` → Verifica tu `REPLICATE_API_KEY`.

### Ejemplo 3: Generación con Qwen-Image-2.0 (SiliconFlow)
**Objetivo**: Aprovechar la tipografía precisa y 2K.
**Nivel**: 🟡

```typescript
import axios from 'axios';

async function generateQwenImage(prompt: string): Promise<string> {
  const response = await axios.post(
    'https://api.siliconflow.cn/v1/images/generations',
    {
      model: 'Qwen/Qwen-Image-2.0',
      prompt,
      n: 1,
      size: '1792x1024', // 2K
      response_format: 'url'
    },
    { headers: { Authorization: `Bearer ${process.env.SILICONFLOW_API_KEY}` } }
  );
  return response.data.data[0].url;
}
```
✅ **Deberías ver:** URL de la imagen en 2K.
❌ **Si ves:** `Error: 402 Payment Required` → Añade créditos a SiliconFlow.

### Ejemplo 4: Generación con DALL-E 3 (OpenAI)
**Objetivo**: Máxima calidad para producción.
**Nivel**: 🟢

```typescript
import OpenAI from 'openai';

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

async function generateDalle3(prompt: string): Promise<string> {
  const response = await openai.images.generate({
    model: 'dall-e-3',
    prompt,
    n: 1,
    size: '1024x1024',
    quality: 'hd',
    response_format: 'url'
  });
  return response.data[0].url;
}
```
✅ **Deberías ver:** URL de imagen 1024x1024 HD.
❌ **Si ves:** `Error: 429 Rate limit exceeded` → Ve a Troubleshooting #4.

### Ejemplo 5: Pipeline asíncrono con BullMQ (No bloquea webhook)
**Objetivo**: Generar imágenes en background para no exceder timeouts.
**Nivel**: 🟡

```typescript
import { Queue } from 'bullmq';
import IORedis from 'ioredis';

const connection = new IORedis({ maxRetriesPerRequest: null });
const imageQueue = new Queue('image-generation', { connection });

// En el webhook (respuesta inmediata)
app.post('/generate-image', async (req, res) => {
  const { tenant_id, prompt } = req.body;
  await imageQueue.add('generate', { tenant_id, prompt });
  res.json({ status: 'queued', estimated_time: '10-20 seconds' });
});

// Worker (proceso separado)
const worker = new Worker('image-generation', async (job) => {
  const { tenant_id, prompt } = job.data;
  const imageUrl = await generateAndStoreImage(tenant_id, prompt);
  // Notificar al usuario (ej: via WhatsApp)
  await sendWhatsAppMessage(tenant_id, `Tu imagen está lista: ${imageUrl}`);
}, { connection, concurrency: 1 }); // C2: solo 1 worker
```

### Ejemplo 6: Caché de resultados (Redis) para prompts repetidos
**Objetivo**: Ahorrar costos en prompts frecuentes (C1).
**Nivel**: 🟡

```typescript
import { createHash } from 'crypto';
import redis from './redis-client';

async function generateWithCache(prompt: string): Promise<string> {
  const hash = createHash('md5').update(prompt).digest('hex');
  const cacheKey = `img:${hash}`;
  const cached = await redis.get(cacheKey);
  if (cached) return cached;

  const imageUrl = await generateFluxSchnell(prompt);
  await redis.setex(cacheKey, 86400 * 30, imageUrl); // 30 días
  return imageUrl;
}
```

### Ejemplo 7: Rate Limiting para evitar sobrecostos
**Objetivo**: Limitar generaciones por tenant/minuto.
**Nivel**: 🟡

```typescript
import { RateLimiterRedis } from 'rate-limiter-flexible';
import redis from './redis-client';

const rateLimiter = new RateLimiterRedis({
  storeClient: redis,
  keyPrefix: 'img_rl',
  points: 5,    // 5 generaciones
  duration: 60  // por minuto
});

async function limitedGenerate(tenantId: string, prompt: string) {
  try {
    await rateLimiter.consume(tenantId);
    return await generateNanoBanana(prompt);
  } catch (rejRes) {
    throw new Error('Rate limit exceeded. Try again later.');
  }
}
```

### Ejemplo 8: Validación de prompt con Azure Content Safety
**Objetivo**: Filtrar contenido inapropiado antes de generar.
**Nivel**: 🔴

```typescript
import { ContentSafetyClient } from '@azure-rest/ai-content-safety';

const client = new ContentSafetyClient(process.env.AZURE_CS_ENDPOINT!, {
  key: process.env.AZURE_CS_KEY!
});

async function validatePrompt(prompt: string): Promise<boolean> {
  const response = await client.path('/text:analyze').post({
    body: { text: prompt, categories: ['Hate', 'Sexual', 'Violence', 'SelfHarm'] }
  });
  return !response.body.categoriesAnalysis.some(c => c.severity > 2);
}
```
✅ **Deberías ver:** `true` para prompts seguros, `false` para bloqueados.

### Ejemplo 9: Almacenamiento en Google Drive (alternativa a Supabase)
**Objetivo**: Usar Drive como CDN económico.
**Nivel**: 🟡

```typescript
import { google } from 'googleapis';

const drive = google.drive({ version: 'v3', auth });

async function uploadToDrive(tenantId: string, imageBuffer: Buffer, filename: string) {
  const response = await drive.files.create({
    requestBody: { name: filename, parents: [tenantFolderId] },
    media: { mimeType: 'image/png', body: imageBuffer },
    fields: 'id, webContentLink'
  });
  return response.data.webContentLink;
}
```

### Ejemplo 10: Webhook de notificación al completar generación
**Objetivo**: Avisar al usuario cuando la imagen esté lista.
**Nivel**: 🟡

```typescript
async function notifyUser(tenantId: string, imageUrl: string) {
  // Usar WhatsApp o Telegram (ver skills de COMUNICACION)
  await axios.post('https://graph.facebook.com/v22.0/.../messages', {
    messaging_product: 'whatsapp',
    to: tenantId,
    type: 'image',
    image: { link: imageUrl }
  });
}
```

### Ejemplo 11: Evaluación de calidad con PickScore (CI/CD)
**Objetivo**: Validar que las imágenes generadas cumplen estándares.
**Nivel**: 🔴

```typescript
import axios from 'axios';

async function evaluateImageQuality(imageUrl: string, prompt: string): Promise<number> {
  // Usar API de PickScore (modelo open-source)
  const response = await axios.post('https://api.pickscore.ai/v1/score', {
    image_url: imageUrl,
    prompt
  });
  return response.data.score; // 0-1
}
```

### Ejemplo 12: Despliegue con Terraform (IaC)
**Objetivo**: Aprovisionar el VPS y configurar el servicio de imágenes.
**Nivel**: 🔴

```hcl
# main.tf
resource "digitalocean_droplet" "image_agent" {
  name   = "mantis-image-gen"
  size   = "s-2vcpu-4gb"
  image  = "ubuntu-22-04-x64"
  region = "nyc3"
  user_data = file("cloud-init.yaml")
}

resource "null_resource" "deploy" {
  provisioner "remote-exec" {
    inline = [
      "git clone https://github.com/Mantis-AgenticDev/image-agent.git",
      "cd image-agent && npm ci",
      "pm2 start ecosystem.config.js"
    ]
  }
}
```

### Ejemplo 13: GitHub Actions para despliegue continuo
**Objetivo**: Automatizar despliegue en cada push a main.
**Nivel**: 🔴

```yaml
# .github/workflows/deploy.yml
name: Deploy Image Agent
on: [push]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Terraform Apply
        run: |
          cd infra
          terraform init && terraform apply -auto-approve
```

### Ejemplo 14: Autogeneración de prompts con GPT-4o
**Objetivo**: Usar LLM para crear prompts de imagen a partir de descripciones de negocio.
**Nivel**: 🔴

```typescript
async function autoGenerateImagePrompt(businessDesc: string): Promise<string> {
  const llmPrompt = `
    Eres un experto en generación de imágenes con IA.
    A partir de la siguiente descripción de negocio, crea un prompt detallado para generar una imagen de marketing.
    Descripción: ${businessDesc}
    El prompt debe ser en inglés, incluir estilo (photorealistic/illustration), iluminación, composición.
  `;
  return await askGPT4o(llmPrompt);
}
```

### Ejemplo 15: Watermarking de imágenes generadas
**Objetivo**: Añadir marca de agua para proteger propiedad intelectual.
**Nivel**: 🟡

```typescript
import sharp from 'sharp';

async function addWatermark(imageBuffer: Buffer, tenantId: string): Promise<Buffer> {
  const watermarkText = `Mantis Agentic - ${tenantId}`;
  return sharp(imageBuffer)
    .composite([{
      input: Buffer.from(`<svg><text x="10" y="30">${watermarkText}</text></svg>`),
      gravity: 'southeast'
    }])
    .png()
    .toBuffer();
}
```

---

## 🐞 15 Errores Comunes y Troubleshooting

| Error Exacto (copiable) | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso | Constraint Afectado |
| :--- | :--- | :--- | :--- | :--- |
| **1.** `Error: 401 Unauthorized` | API Key inválida o expirada. | `curl -H "Authorization: Bearer $KEY" https://openrouter.ai/api/v1/auth/key` | 1. Regenerar API Key en el panel de control. 2. Verificar que la variable de entorno se cargue correctamente. | C3 |
| **2.** `"error":{"message":"No endpoints found matching your data policy"}` (OpenRouter) | Configuración de privacidad. | Revisar `https://openrouter.ai/settings`. | Activar "Enable training and logging (chatroom and API)". Requerido para modelos gratuitos. | C6 |
| **3.** `Error: 400 Invalid modalities` | Faltó `modalities: ["image", "text"]` en la petición. | Revisar el body de la petición. | Incluir el array `modalities` en la petición para modelos de imagen de OpenRouter. | - |
| **4.** `Error: 429 Rate limit exceeded` | Límite de RPM/TPM excedido. | Revisar cabeceras `x-ratelimit-remaining`. | Implementar rate limiter (Ejemplo 7) o solicitar aumento de cuota. | C1 |
| **5.** `Error: 413 Payload Too Large` | Imagen base64 > 20MB. | Verificar tamaño del buffer. | Redimensionar imagen antes de subir o usar URL en lugar de base64. | C1 |
| **6.** `Error: 500 Internal Server Error` | Fallo temporal del proveedor. | Revisar status page del proveedor. | Implementar fallback a otro modelo (Ej: si Nano Banana falla, usar Flux). | C6 |
| **7.** `Error: 400 Invalid prompt` | Prompt contiene términos bloqueados. | Validar prompt con Azure Content Safety (Ejemplo 8). | Sanitizar prompt o usar un modelo con políticas menos restrictivas. | - |
| **8.** `Error: Request timeout` | Generación excede 60s. | Medir latencia con `time curl ...`. | Usar cola asíncrona (Ejemplo 5) para no bloquear el webhook. | C2 |
| **9.** `Error: Cold start` en Replicate | El modelo se está cargando en GPU. | Esperar 10-30s y reintentar. | Usar modelos siempre calientes (Flux Schnell en Replicate) o pagar por warm workers. | C2 |
| **10.** `Error: 402 Payment Required` | Créditos insuficientes. | Revisar saldo en el panel del proveedor. | Añadir créditos o usar modelos gratuitos (Nano Banana 2, Flux Schnell). | C6 |
| **11.** `Error: getaddrinfo ENOTFOUND api.openrouter.ai` | Problema de DNS en VPS. | `nslookup api.openrouter.ai`. | 1. Verificar `/etc/resolv.conf`. 2. Usar `8.8.8.8`. | C3 |
| **12.** `Error: 403 Forbidden` en Supabase Storage | RLS bloquea la subida. | Revisar políticas RLS en Supabase. | Añadir política `INSERT` para el bucket `generated-images` con `tenant_id = (auth.jwt() ->> 'tenant_id')`. | C4 |
| **13.** `Error: Invalid image format` | El buffer no es PNG/JPEG válido. | `file output.png`. | Asegurarse de que la API devuelve base64 correcto. Algunos modelos devuelven `data:image/png;base64,...`; limpiar el prefijo. | - |
| **14.** `Error: 400 Aspect ratio not supported` | Relación de aspecto no soportada. | Revisar documentación del modelo. | Usar relaciones estándar: 1:1, 16:9, 9:16, 4:3, 3:4. | - |
| **15.** `Error: Cannot read properties of undefined (reading 'images')` | La API no devolvió imagen. | Inspeccionar `response.data`. | Verificar que el prompt no esté vacío y que el modelo soporte generación de imagen. | - |

---

## ✅ Validación SDD y Comandos de Verificación

<!-- ai:constraint=C5 -->
### 1. Verificar conectividad con OpenRouter
```bash
curl -I https://openrouter.ai/api/v1/models
```

### 2. Auditar uso de `tenant_id` en logs (C4)
```bash
grep -c '"tenant_id":"' /var/log/mantis-image.log
```

### 3. Chequeo de secretos (C3)
```bash
grep -r "sk-or-v1-\|r8_" /opt/mantis --exclude-dir=node_modules
```

### 4. Validar pipeline de CI/CD
```bash
npx promptfoo eval --config promptfooconfig.yaml
```

### 5. Verificar límites de recursos (C1/C2)
```bash
pm2 monit mantis-image-worker
```

### 6. Backup de configuración (C5)
```bash
sha256sum .env > .env.sha256
rsync -avz .env.sha256 backup@server:/backup/configs/
```

---

## 🚀 CI/CD, IaC y Autogeneración con IA (Normas MANTIS)

### Pipeline de Integración Continua para Agentes de Imagen

1. **Especificación (`image-agent-spec.yaml`):** Define el modelo a usar, el estilo por defecto, los límites de rate y el bucket de almacenamiento.
2. **Generación automática:** Una IA (GPT-4o) lee la especificación y genera el código TypeScript del worker, el `Dockerfile` y el workflow de GitHub Actions.
3. **Pruebas en CI:**
   - Linting (`eslint`).
   - Pruebas unitarias de funciones de generación y almacenamiento.
   - Evaluación de calidad de imagen con **PickScore** (Ejemplo 11).
4. **Infraestructura como Código (IaC):** Terraform aprovisiona el VPS, configura las variables de entorno y despliega el servicio.
5. **Despliegue continuo:** GitHub Actions construye la imagen Docker y la despliega.

### Hardening de Seguridad para Imágenes

- **Cifrado en tránsito:** HTTPS para todas las APIs.
- **Validación de prompts:** Uso de Azure Content Safety o filtros similares para bloquear contenido NSFW.
- **Watermarking:** Añadir marca de agua con `tenant_id` para trazabilidad (Ejemplo 15).
- **Aislamiento de workers:** El worker de generación se ejecuta en un proceso separado con límites de memoria.
- **Auditoría (C4):** Cada generación se registra con `tenant_id`, prompt, URL y costo estimado.
- **Rotación de secretos:** API Keys se rotan cada 90 días usando HashiCorp Vault.

### Autogeneración de Workflows de n8n

Para agentes que requieren generación de imágenes como parte de un flujo más amplio (ej: "generar menú visual y enviarlo por WhatsApp"), el sistema de autogeneración puede crear un workflow de n8n que:
1. Recibe el prompt desde el webhook de WhatsApp.
2. Llama al servicio de imágenes (vía HTTP Request).
3. Espera la URL de la imagen.
4. Envía la imagen al usuario.

---

## 🔗 Referencias Cruzadas y Glosario

- [[openrouter-api-integration.md]] - Patrón general para consumir APIs vía OpenRouter.
- [[whatsapp-rag-openrouter.md]] - Orquestación de agentes de WhatsApp.
- [[gpt-integration.md]] - Integración con GPT-4o para autogeneración de prompts.
- [[environment-variable-management.md]] - Gestión segura de secretos.

**Glosario:**
- **T2I:** Text-to-Image. Generación de imagen a partir de texto.
- **Base64:** Codificación de imagen en texto para transmisión HTTP.
- **Flux:** Familia de modelos de imagen de Black Forest Labs.
- **Nano Banana 2:** Modelo de imagen de Google (Gemini 3.1 Flash Image Preview).
- **PickScore:** Métrica de evaluación de calidad de imagen basada en CLIP.

FIN DEL ARCHIVO
<!-- ai:file-end marker - do not remove -->
Versión 1.0.0 - 2026-04-11 - Mantis-AgenticDev

