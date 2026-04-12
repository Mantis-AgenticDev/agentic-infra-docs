---
title: "voice-agent-integration.md"
category: "Skill"
domain: ["ai", "comunicacion", "generico"]
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
priority: "ALTA"
version: "1.0.0"
last_updated: "2026-04-11"
ai_optimized: true
tags:
  - sdd/skill/ai
  - sdd/skill/comunicacion
  - lang/es
related_files:
  - "01-RULES/03-SECURITY-RULES.md"
  - "02-SKILLS/COMUNICACION/whatsapp-rag-openrouter.md"
  - "02-SKILLS/COMUNICACION/telegram-bot-integration.md"
  - "02-SKILLS/AI/openrouter-api-integration.md"
  - "02-SKILLS/AI/mistral-ocr-integration.md"
  - "05-CONFIGURATIONS/environment-variable-management.md"
---

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

**Objetivo en 5 minutos:** Procesar un mensaje de voz de WhatsApp, transcribirlo con Whisper, generar una respuesta con GPT-4o-mini y enviarla como texto.

1. **Requisitos previos:** Tener configurado un webhook de WhatsApp Cloud API o UAZapi, y una API Key de OpenAI.
2. **Configurar variables de entorno (C3):**
   ```bash
   echo "OPENAI_API_KEY=sk-proj-..." >> .env
   echo "WHATSAPP_TOKEN=EAA..." >> .env
   echo "VERIFY_TOKEN=mi_token_secreto" >> .env
   ```
3. **Implementar el endpoint de webhook (Node.js + Express):**
   ```typescript
   import express from 'express';
   import { handleWhatsAppVoice } from './voice-agent';
   const app = express();
   app.post('/webhook/whatsapp', express.json(), handleWhatsAppVoice);
   app.listen(3000);
   ```
✅ **Deberías ver:** El servidor corriendo y el webhook verificándose correctamente.
❌ **Si ves:** `Error: verify_token mismatch` → Asegúrate de que el `VERIFY_TOKEN` en tu `.env` coincida con el configurado en Meta Developers.

⚠️ **Advertencia para Junior:** Los mensajes de voz en WhatsApp se reciben como `audio` con un `media_id`. Debes descargar el archivo OGG/Opus desde los servidores de Meta, convertirlo a un formato compatible (WAV/PCM16) y luego enviarlo a la API de transcripción. Este proceso consume ancho de banda y RAM; respeta los límites de tamaño (C1).

---

## 🎯 Propósito y Alcance

Este skill documenta los patrones de integración para construir **agentes de voz** en el ecosistema MANTIS, capaces de recibir mensajes de audio de WhatsApp y Telegram, transcribirlos a texto (STT), procesarlos con un LLM (RAG) y, opcionalmente, responder con voz sintetizada (TTS). El enfoque es **asíncrono y escalable**, respetando las limitaciones de hardware del VPS (C1/C2).

**Cubre:**
- **Ingesta de audio desde WhatsApp Cloud API y Telegram Bot API**: Descarga de archivos, conversión de formatos (OGG → WAV).
- **Speech-to-Text (STT)**: Integración con OpenAI Whisper API, Google Chirp (Speech-to-Text v2) y Deepgram.
- **Text-to-Speech (TTS)**: Integración con ElevenLabs, PlayHT Turbo y OpenAI TTS para respuestas de voz.
- **Arquitectura de pipeline asíncrono**: Uso de colas (BullMQ) para no bloquear el webhook y respetar los timeouts de las APIs de mensajería.
- **Hardening de seguridad**: Cifrado en tránsito (HTTPS), validación de webhooks (SHA256 para WhatsApp, secret token para Telegram), y sanitización de nombres de archivo.
- **CI/CD e IaC**: Despliegue automatizado del servicio de voz con GitHub Actions y Terraform.
- **Autogeneración por IA**: Uso de GPT-4o para generar dinámicamente la configuración de agentes de voz a partir de especificaciones SDD.

**No cubre:**
- Streaming de voz en tiempo real (WebRTC/SIP), que es competencia de `voice-realtime-integration.md`.
- Modelos de voz a voz (speech-to-speech) como OpenAI Realtime API.
- La lógica de negocio específica de cada vertical (eso reside en los workflows de n8n).

---

## 📐 Fundamentos (De 0 a Intermedio)

### El Pipeline de un Agente de Voz

Un agente de voz moderno sigue una arquitectura en cascada (cascading architecture) con tres etapas principales:

```
[Audio Input] → [STT] → [LLM/RAG] → [TTS] → [Audio Output]
```

1. **Speech-to-Text (STT):** Convierte el audio del usuario en texto. En MANTIS, usamos principalmente **Whisper API** ($0.006/min) por su excelente precisión multilingüe (99 idiomas) y bajo costo. Alternativas: **Google Chirp** (120+ idiomas) y **Deepgram** (streaming de baja latencia).
2. **Large Language Model (LLM):** Procesa el texto transcrito, inyecta contexto RAG y genera una respuesta. Cualquiera de los modelos documentados en `AI/` (GPT-4o-mini, DeepSeek, Qwen, etc.) puede usarse.
3. **Text-to-Speech (TTS):** Convierte la respuesta textual en un archivo de audio que se envía al usuario. **ElevenLabs** es el estándar por su naturalidad y soporte multilingüe (29 idiomas). Para respuestas rápidas y económicas, **PlayHT Turbo** ofrece <300ms de latencia.

### ¿Por qué una Arquitectura Asíncrona?

Las APIs de WhatsApp y Telegram tienen **timeouts estrictos** (usualmente 10-30 segundos). Si intentamos hacer STT + LLM + TTS dentro del mismo ciclo de vida del webhook, es muy probable que el proveedor de mensajería cierre la conexión antes de que terminemos. La solución es:

1. **Recepción inmediata:** El webhook recibe el mensaje, lo valida y **encola** una tarea de procesamiento. Responde con un `200 OK` en <1 segundo.
2. **Procesamiento en segundo plano:** Un worker (proceso separado) toma la tarea de la cola, realiza STT → LLM → TTS.
3. **Envío de respuesta:** Una vez generado el audio (o el texto), se envía al usuario a través de la API de WhatsApp o Telegram.

Esta arquitectura cumple con C2 (no bloquea el event loop del webhook) y permite escalar horizontalmente los workers.

### Modelos de STT y TTS Objetivo (2026)

| Categoría | Proveedor | Modelo/Endpoint | Precio (aprox.) | Características Clave |
| :--- | :--- | :--- | :--- | :--- |
| **STT** | OpenAI | `whisper-1` | $0.006 / min | 99 idiomas, excelente precisión en español. |
| **STT** | Google Cloud | `chirp` (v2) | $0.016 / min | 120+ idiomas, modelos Chirp adaptables. |
| **STT** | Deepgram | `nova-2` | $0.0043 / min | Streaming de baja latencia, diarización de hablantes. |
| **TTS** | ElevenLabs | `eleven_multilingual_v2` | $0.30 / 1000 chars | Voces ultrarrealistas, clonación de voz. |
| **TTS** | PlayHT | `PlayHT2.0-turbo` | $0.05 / 1000 chars | <300ms de latencia, ideal para conversaciones. |
| **TTS** | OpenAI | `tts-1-hd` | $0.03 / 1000 chars | Integración simple, 6 voces predefinidas. |

---

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

### Aplicación de Constraints C1 y C2

- **C1 (RAM ≤ 4GB):** La descarga y conversión de audio puede consumir RAM. **No cargues archivos de audio completos en memoria.** Usa `streams` para descargar el audio desde WhatsApp/Telegram y tuberías (`pipe`) para pasarlo a `ffmpeg` sin almacenarlo en RAM.
- **C2 (1 vCPU por op. crítica):** `ffmpeg` para la conversión OGG → WAV puede consumir CPU. Ejecútalo con `nice -n 19` y limita el número de workers concurrentes a 1.

### Configuración de Workers y Colas (BullMQ)

```typescript
import { Queue, Worker } from 'bullmq';
import IORedis from 'ioredis';

const connection = new IORedis({ maxRetriesPerRequest: null });

// Cola para tareas de procesamiento de voz
export const voiceQueue = new Queue('voice-processing', { connection });

// Worker: solo 1 trabajo concurrente para respetar C2
const worker = new Worker('voice-processing', async (job) => {
  // Procesar STT + LLM + TTS
}, { connection, concurrency: 1 });
```

### Límites de Tamaño de Audio

- **WhatsApp:** Los mensajes de voz están limitados a 16MB (aproximadamente 10 minutos).
- **Telegram:** Los bots pueden descargar archivos de hasta 20MB.
- **Whisper API:** Límite de 25MB por archivo.

Para audios que excedan estos límites, se debe responder con un mensaje de error amigable ("El audio es demasiado largo. Por favor, envía un mensaje más corto.").

---

## 🔗 Integración con Stack Existente (n8n, Qdrant, EspoCRM)

### Diagrama de Flujo de Datos

```
[Usuario WhatsApp/Telegram] → (Webhook) → [API Gateway] → [Cola BullMQ]
                                                              ↓
[Usuario] ← (API WhatsApp/Telegram) ← [Worker] ← [STT (Whisper)] → [LLM (GPT-4o)] → [TTS (ElevenLabs)]
                                                              ↓
                                                        [Qdrant (RAG)]
```

### Integración con n8n

Para casos de uso que requieren lógica de negocio compleja (ej: "si el usuario dice 'hablar con un humano', transferir a un agente"), el worker puede invocar un **webhook de n8n** después de la transcripción. n8n orquesta la conversación, consulta disponibilidad en EspoCRM y devuelve la respuesta textual, que luego el worker sintetiza con TTS.

---

## 🛠️ 15 Ejemplos de Configuración (Copy-Paste Validables)

### Ejemplo 1: Webhook de WhatsApp para recibir audio (Node.js)
**Objetivo**: Validar y encolar un mensaje de voz de WhatsApp.
**Nivel**: 🟢

```typescript
import express from 'express';
import crypto from 'crypto';
import { voiceQueue } from './queue';

const app = express();
app.use(express.json());

app.post('/webhook/whatsapp', async (req, res) => {
  // 1. Verificar webhook (GET)
  if (req.method === 'GET') {
    const mode = req.query['hub.mode'];
    const token = req.query['hub.verify_token'];
    const challenge = req.query['hub.challenge'];
    if (mode === 'subscribe' && token === process.env.VERIFY_TOKEN) {
      return res.status(200).send(challenge);
    }
    return res.sendStatus(403);
  }

  // 2. Procesar POST (mensaje entrante)
  const body = req.body;
  if (body.object !== 'whatsapp_business_account') return res.sendStatus(200);

  for (const entry of body.entry) {
    for (const change of entry.changes) {
      if (change.value.messages) {
        for (const msg of change.value.messages) {
          if (msg.type === 'audio') {
            // Encolar tarea de procesamiento
            await voiceQueue.add('process-whatsapp', {
              tenant_id: msg.from, // Usamos el número como tenant_id temporal
              media_id: msg.audio.id,
              mime_type: msg.audio.mime_type,
              from: msg.from,
              phone_number_id: change.value.metadata.phone_number_id
            });
          }
        }
      }
    }
  }
  res.sendStatus(200);
});
```
✅ **Deberías ver:** El webhook responde `200` inmediatamente y el trabajo aparece en la cola.
❌ **Si ves:** `Error: Webhook verification failed` → Asegúrate de que tu URL sea pública (HTTPS) y que el `VERIFY_TOKEN` coincida.

### Ejemplo 2: Descarga de audio de WhatsApp Cloud API
**Objetivo**: Obtener el binario del audio usando el `media_id`.
**Nivel**: 🟡

```typescript
import axios from 'axios';

async function downloadWhatsAppAudio(mediaId: string): Promise<Buffer> {
  // 1. Obtener URL de descarga
  const urlRes = await axios.get(
    `https://graph.facebook.com/v22.0/${mediaId}`,
    { headers: { Authorization: `Bearer ${process.env.WHATSAPP_TOKEN}` } }
  );
  const downloadUrl = urlRes.data.url;

  // 2. Descargar el archivo
  const audioRes = await axios.get(downloadUrl, {
    headers: { Authorization: `Bearer ${process.env.WHATSAPP_TOKEN}` },
    responseType: 'arraybuffer'
  });
  return Buffer.from(audioRes.data);
}
```
✅ **Deberías ver:** Un `Buffer` con el contenido OGG/Opus.
❌ **Si ves:** `Error: Request failed with status code 404` → El `media_id` expiró. Los archivos de WhatsApp solo están disponibles por ~30 días.

### Ejemplo 3: Conversión OGG → WAV con ffmpeg (streaming)
**Objetivo**: Convertir el audio de WhatsApp a un formato compatible con Whisper sin cargar todo en RAM.
**Nivel**: 🟡

```typescript
import { spawn } from 'child_process';
import { Readable } from 'stream';

async function convertOggToWav(inputBuffer: Buffer): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const ffmpeg = spawn('ffmpeg', [
      '-i', 'pipe:0',           // Leer de stdin
      '-f', 'wav',              // Formato de salida WAV
      '-ar', '16000',           // Sample rate 16kHz (requerido por Whisper)
      '-ac', '1',               // Mono
      '-c:a', 'pcm_s16le',      // Codec PCM 16-bit
      'pipe:1'                  // Escribir a stdout
    ]);
    const chunks: Buffer[] = [];
    ffmpeg.stdout.on('data', (chunk) => chunks.push(chunk));
    ffmpeg.on('close', (code) => {
      if (code === 0) resolve(Buffer.concat(chunks));
      else reject(new Error(`ffmpeg exited with code ${code}`));
    });
    const inputStream = new Readable();
    inputStream.push(inputBuffer);
    inputStream.push(null);
    inputStream.pipe(ffmpeg.stdin);
  });
}
```
✅ **Deberías ver:** Un `Buffer` con el audio en formato WAV PCM16.
❌ **Si ves:** `Error: ffmpeg exited with code 1` → Asegúrate de que `ffmpeg` esté instalado (`sudo apt install ffmpeg`).

### Ejemplo 4: Transcripción con OpenAI Whisper API
**Objetivo**: Enviar el audio WAV a Whisper y obtener el texto transcrito.
**Nivel**: 🟢

```typescript
import OpenAI from 'openai';
import { createReadStream } from 'fs';
import { writeFileSync, unlinkSync } from 'fs';

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

async function transcribeWithWhisper(audioBuffer: Buffer): Promise<string> {
  // Guardar temporalmente (Whisper API requiere un archivo)
  const tempFile = `/tmp/audio-${Date.now()}.wav`;
  writeFileSync(tempFile, audioBuffer);
  
  try {
    const response = await openai.audio.transcriptions.create({
      file: createReadStream(tempFile),
      model: 'whisper-1',
      language: 'es', // Opcional: forzar idioma
      response_format: 'text'
    });
    return response as unknown as string;
  } finally {
    unlinkSync(tempFile); // Limpiar
  }
}
```
✅ **Deberías ver:** El texto transcrito.
❌ **Si ves:** `Error: 413 Payload Too Large` → El audio excede 25MB. Comprime o divide.

### Ejemplo 5: Integración con Telegram Bot API (Recepción de voz)
**Objetivo**: Descargar un mensaje de voz de Telegram usando `getFile`.
**Nivel**: 🟡

```typescript
import axios from 'axios';

async function downloadTelegramVoice(fileId: string): Promise<Buffer> {
  // 1. Obtener file_path
  const getFileRes = await axios.get(
    `https://api.telegram.org/bot${process.env.TELEGRAM_BOT_TOKEN}/getFile`,
    { params: { file_id: fileId } }
  );
  const filePath = getFileRes.data.result.file_path;

  // 2. Descargar archivo
  const downloadUrl = `https://api.telegram.org/file/bot${process.env.TELEGRAM_BOT_TOKEN}/${filePath}`;
  const audioRes = await axios.get(downloadUrl, { responseType: 'arraybuffer' });
  return Buffer.from(audioRes.data);
}
```
✅ **Deberías ver:** Un `Buffer` con el audio (generalmente OGG/Opus).
❌ **Si ves:** `Error: 400 Bad Request: file_id is invalid` → El `file_id` no existe o el bot no tiene acceso.

### Ejemplo 6: Text-to-Speech con ElevenLabs
**Objetivo**: Generar un audio de respuesta con una voz natural.
**Nivel**: 🟢

```typescript
import axios from 'axios';

async function synthesizeElevenLabs(text: string): Promise<Buffer> {
  const response = await axios.post(
    `https://api.elevenlabs.io/v1/text-to-speech/${process.env.ELEVENLABS_VOICE_ID}`,
    {
      text,
      model_id: 'eleven_multilingual_v2',
      voice_settings: { stability: 0.5, similarity_boost: 0.75 }
    },
    {
      headers: {
        'xi-api-key': process.env.ELEVENLABS_API_KEY!,
        'Content-Type': 'application/json'
      },
      responseType: 'arraybuffer'
    }
  );
  return Buffer.from(response.data);
}
```
✅ **Deberías ver:** Un `Buffer` con audio MP3.
❌ **Si ves:** `Error: 401 Unauthorized` → Verifica tu `ELEVENLABS_API_KEY`.

### Ejemplo 7: Envío de audio a WhatsApp Cloud API
**Objetivo**: Subir el audio generado y enviarlo como mensaje de voz.
**Nivel**: 🟡

```typescript
import FormData from 'form-data';
import axios from 'axios';

async function sendWhatsAppVoice(phoneNumberId: string, to: string, audioBuffer: Buffer) {
  // 1. Subir el audio (obtener media_id)
  const form = new FormData();
  form.append('file', audioBuffer, { filename: 'response.ogg', contentType: 'audio/ogg' });
  form.append('messaging_product', 'whatsapp');
  const uploadRes = await axios.post(
    `https://graph.facebook.com/v22.0/${phoneNumberId}/media`,
    form,
    { headers: { ...form.getHeaders(), Authorization: `Bearer ${process.env.WHATSAPP_TOKEN}` } }
  );
  const mediaId = uploadRes.data.id;

  // 2. Enviar mensaje de audio
  await axios.post(
    `https://graph.facebook.com/v22.0/${phoneNumberId}/messages`,
    {
      messaging_product: 'whatsapp',
      to,
      type: 'audio',
      audio: { id: mediaId }
    },
    { headers: { Authorization: `Bearer ${process.env.WHATSAPP_TOKEN}` } }
  );
}
```
✅ **Deberías ver:** El usuario recibe un mensaje de voz reproducible.
❌ **Si ves:** `Error: (#100) The parameter messaging_product is required` → Asegúrate de incluirlo en el body.

### Ejemplo 8: Worker BullMQ completo (STT + LLM + TTS)
**Objetivo**: Orquestar todo el pipeline en un worker.
**Nivel**: 🟡

```typescript
import { Worker } from 'bullmq';
import IORedis from 'ioredis';

const connection = new IORedis({ maxRetriesPerRequest: null });

const worker = new Worker('voice-processing', async (job) => {
  const { tenant_id, media_id, from, phone_number_id } = job.data;

  // 1. Descargar y convertir audio
  const oggBuffer = await downloadWhatsAppAudio(media_id);
  const wavBuffer = await convertOggToWav(oggBuffer);

  // 2. Transcribir
  const transcript = await transcribeWithWhisper(wavBuffer);

  // 3. Procesar con LLM (inyectar RAG)
  const responseText = await generateGPTResponse(tenant_id, transcript, await getRAGContext(tenant_id, transcript));

  // 4. Sintetizar respuesta
  const audioResponse = await synthesizeElevenLabs(responseText);

  // 5. Enviar audio
  await sendWhatsAppVoice(phone_number_id, from, audioResponse);

  // 6. Log de auditoría (C4)
  console.log(JSON.stringify({
    event: 'voice_agent_success',
    tenant_id,
    transcript_length: transcript.length,
    response_length: responseText.length
  }));
}, { connection, concurrency: 1 }); // C2: solo 1 worker concurrente
```
✅ **Deberías ver:** El pipeline se ejecuta correctamente y el usuario recibe una respuesta de voz.

### Ejemplo 9: Uso de Deepgram para STT de baja latencia
**Objetivo**: Transcribir con Deepgram (alternativa a Whisper).
**Nivel**: 🟡

```typescript
import { createClient } from '@deepgram/sdk';

const deepgram = createClient(process.env.DEEPGRAM_API_KEY!);

async function transcribeWithDeepgram(audioBuffer: Buffer): Promise<string> {
  const { result } = await deepgram.listen.prerecorded.transcribeFile(audioBuffer, {
    model: 'nova-2',
    language: 'es',
    smart_format: true
  });
  return result.results.channels[0].alternatives[0].transcript;
}
```
✅ **Deberías ver:** Transcripción en español con formato inteligente (números, puntuación).

### Ejemplo 10: Uso de PlayHT Turbo para TTS de baja latencia
**Objetivo**: Sintetizar voz con <300ms de latencia.
**Nivel**: 🟡

```typescript
import PlayHT from 'playht';

PlayHT.init({ apiKey: process.env.PLAYHT_API_KEY!, userId: process.env.PLAYHT_USER_ID! });

async function synthesizePlayHT(text: string): Promise<Buffer> {
  const stream = await PlayHT.stream(text, {
    voiceEngine: 'PlayHT2.0-turbo',
    voiceId: 's3://voice-cloning-zero-shot/...',
    outputFormat: 'mp3',
    speed: 1.0
  });
  const chunks: Buffer[] = [];
  for await (const chunk of stream) chunks.push(chunk);
  return Buffer.concat(chunks);
}
```
✅ **Deberías ver:** Audio generado en ~300ms.

### Ejemplo 11: Hardening: Validación de Webhook con SHA256 (WhatsApp)
**Objetivo**: Verificar que las peticiones POST provienen realmente de Meta.
**Nivel**: 🔴

```typescript
import crypto from 'crypto';

function verifyWhatsAppSignature(req: express.Request): boolean {
  const signature = req.headers['x-hub-signature-256'] as string;
  if (!signature) return false;
  const elements = signature.split('=');
  const expectedHash = crypto
    .createHmac('sha256', process.env.WHATSAPP_APP_SECRET!)
    .update(JSON.stringify(req.body))
    .digest('hex');
  return elements[1] === expectedHash;
}
```
✅ **Deberías ver:** La validación pasa para peticiones legítimas.
❌ **Si ves:** Falsos positivos → Asegúrate de usar `WHATSAPP_APP_SECRET` (no el token de acceso).

### Ejemplo 12: Sanitización de nombres de archivo (Prevención de Path Traversal)
**Objetivo**: Evitar inyección de rutas al guardar archivos temporales.
**Nivel**: 🟢

```typescript
import path from 'path';
import { v4 as uuidv4 } from 'uuid';

function safeTempFilename(prefix: string): string {
  const safePrefix = prefix.replace(/[^a-zA-Z0-9_-]/g, '');
  return path.join('/tmp', `${safePrefix}-${uuidv4()}.wav`);
}
```

### Ejemplo 13: Evaluación de Calidad con Promptfoo (CI/CD)
**Objetivo**: Integrar pruebas de regresión de voz en el pipeline.
**Nivel**: 🔴

```yaml
# promptfooconfig.yaml
description: 'Voice Agent Regression Tests'
providers:
  - id: openai:gpt-4o-mini
prompts:
  - file://prompts/voice_agent_system.txt
tests:
  - vars:
      transcript: 'Hola, ¿cuál es el horario de atención?'
    assert:
      - type: contains
        value: '9:00'
      - type: llm-rubric
        value: 'La respuesta debe ser en español y no exceder 300 caracteres.'
```
✅ **Deberías ver:** Los tests ejecutándose en GitHub Actions.

### Ejemplo 14: Despliegue de Infraestructura con Terraform (IaC)
**Objetivo**: Aprovisionar el VPS y configurar el servicio de voz.
**Nivel**: 🔴

```hcl
# main.tf
resource "digitalocean_droplet" "voice_agent" {
  name   = "mantis-voice-agent"
  size   = "s-2vcpu-4gb" # C1/C2
  image  = "ubuntu-22-04-x64"
  region = "nyc3"
  ssh_keys = [data.digitalocean_ssh_key.main.id]
}

resource "null_resource" "deploy" {
  connection { host = digitalocean_droplet.voice_agent.ipv4_address }
  provisioner "remote-exec" {
    inline = [
      "git clone https://github.com/Mantis-AgenticDev/voice-agent.git",
      "cd voice-agent && npm ci",
      "pm2 start ecosystem.config.js"
    ]
  }
}
```

### Ejemplo 15: Autogeneración de Agente de Voz con IA
**Objetivo**: Usar GPT-4o para generar el código del agente a partir de una especificación SDD.
**Nivel**: 🔴

```typescript
async function autoGenerateVoiceAgent(spec: string) {
  const prompt = `
    Eres un arquitecto de agentes de voz.
    Genera el código TypeScript completo para un agente de voz que cumpla con la siguiente especificación:
    ${spec}
    Incluye: webhook de WhatsApp, descarga de audio, transcripción con Whisper, procesamiento con GPT-4o-mini, y envío de respuesta.
    Respeta las normas C1-C6 de MANTIS.
  `;
  const code = await askGPT4o(prompt);
  await fs.writeFile('./generated-voice-agent.ts', code);
}
```
✅ **Deberías ver:** Un archivo TypeScript listo para ser desplegado.

---

## 🐞 15 Errores Comunes y Troubleshooting

| Error Exacto (copiable) | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso | Constraint Afectado |
| :--- | :--- | :--- | :--- | :--- |
| **1.** `Error: Webhook verification failed` | `VERIFY_TOKEN` no coincide o URL no es HTTPS. | `curl -X GET "https://tudominio.com/webhook?hub.mode=subscribe&hub.verify_token=XXX&hub.challenge=CHALLENGE"` | 1. Asegurar que la URL sea pública (HTTPS). 2. Verificar que el token en Meta Developers coincida con `process.env.VERIFY_TOKEN`. | C3 |
| **2.** `Error: Request failed with status code 404` al descargar audio | `media_id` expirado o inválido. | Revisar logs del webhook. | Los archivos de WhatsApp expiran en ~30 días. Reintentar inmediatamente después de recibir el webhook. | - |
| **3.** `Error: ffmpeg exited with code 1` | Formato de audio no soportado o ffmpeg no instalado. | `ffmpeg -version`. | 1. Instalar ffmpeg: `sudo apt install ffmpeg`. 2. Asegurar que el buffer de entrada no esté corrupto. | C2 |
| **4.** `Error: 413 Payload Too Large` en Whisper API | Audio > 25MB. | `ls -lh /tmp/audio-*.wav`. | 1. Comprimir el audio (reducir bitrate). 2. Dividir el audio en chunks más pequeños. 3. Usar un modelo de STT que soporte streaming. | C1 |
| **5.** `Error: 429 You exceeded your current quota` en OpenAI | Límite de RPM/TPM o créditos agotados. | Revisar [Usage Dashboard](https://platform.openai.com/usage). | 1. Añadir créditos. 2. Implementar rate limiting con `bottleneck`. 3. Usar un modelo más económico (gpt-4o-mini). | C6 |
| **6.** `Error: 401 Unauthorized` en ElevenLabs | API Key inválida o sin créditos. | `curl -H "xi-api-key: $KEY" https://api.elevenlabs.io/v1/voices`. | 1. Regenerar API Key. 2. Verificar créditos en el dashboard. | C3 |
| **7.** `Error: getaddrinfo ENOTFOUND api.telegram.org` | Problema de DNS en el VPS. | `nslookup api.telegram.org`. | 1. Verificar `/etc/resolv.conf`. 2. Usar `8.8.8.8` como DNS. | C3 |
| **8.** `Error: Job stalled` en BullMQ | El worker tardó más de 30s en procesar. | Revisar logs del worker. | 1. Aumentar el timeout del worker (`lockDuration: 120000`). 2. Optimizar el pipeline (usar modelos más rápidos). | C2 |
| **9.** `Error: Cannot read properties of undefined (reading 'audio')` | El webhook de WhatsApp no contiene el campo `audio`. | Inspeccionar `req.body`. | Asegurarse de que el mensaje entrante sea de tipo `audio`. Los mensajes de voz aparecen como `type: 'audio'`. | - |
| **10.** `Error: 400 Bad Request: file_id is invalid` en Telegram | El `file_id` no existe o el bot no tiene permisos. | Usar `getFile` con el `file_id` manualmente. | 1. Asegurarse de que el bot esté en el chat/grupo. 2. El `file_id` puede expirar; descargar inmediatamente. | - |
| **11.** `Error: 500 Internal Server Error` en ElevenLabs | Fallo temporal del servicio. | Revisar `https://status.elevenlabs.io`. | Implementar fallback a otro proveedor TTS (PlayHT o OpenAI). | C6 |
| **12.** El audio de respuesta se escucha cortado | El TTS se generó con `max_tokens` insuficiente. | Revisar la longitud de `responseText`. | Asegurarse de que el LLM no trunque la respuesta. Usar `max_tokens: 500` para respuestas de voz. | - |
| **13.** `Error: Invalid audio format` al enviar a WhatsApp | El audio no es OGG/Opus o AAC. | `ffprobe archivo.ogg`. | Convertir el audio a OGG/Opus con `ffmpeg -i input.mp3 -c:a libopus output.ogg`. | - |
| **14.** `Error: 1004 - authentication failed` en API nativa de MiniMax | API Key o Group ID inválidos. | `curl -H "Authorization: Bearer $KEY" https://api.minimax.io/v1/text/models`. | Regenerar credenciales en el panel de MiniMax. | C3 |
| **15.** `Error: listen EADDRINUSE :::3000` | El puerto ya está en uso. | `sudo lsof -i :3000`. | Cambiar el puerto en la configuración del servidor o detener el proceso que lo ocupa. | - |

---

## ✅ Validación SDD y Comandos de Verificación

<!-- ai:constraint=C5 -->
### 1. Verificar conectividad con APIs de STT/TTS
```bash
# Whisper
curl -H "Authorization: Bearer $OPENAI_API_KEY" https://api.openai.com/v1/models
# ElevenLabs
curl -H "xi-api-key: $ELEVENLABS_API_KEY" https://api.elevenlabs.io/v1/voices
```

### 2. Auditar el uso de `tenant_id` en logs (C4)
```bash
grep -c '"tenant_id":"' /var/log/mantis-voice.log
```

### 3. Chequeo de secretos (C3)
```bash
grep -r "sk-proj-\|EAA\|xi-api-key" /opt/mantis --exclude-dir=node_modules
```

### 4. Validar el pipeline de CI/CD
```bash
npx promptfoo eval --config promptfooconfig.yaml
```

### 5. Verificar límites de recursos del worker (C1/C2)
```bash
pm2 monit mantis-voice-worker
```

### 6. Backup de la configuración (C5)
```bash
sha256sum .env > .env.sha256
rsync -avz .env.sha256 backup@server:/backup/configs/
```

---

## 🚀 CI/CD, IaC y Autogeneración con IA (Normas MANTIS)

### Pipeline de CI/CD para Agentes de Voz

El ecosistema MANTIS aplica **Specification-Driven Development (SDD)** a los agentes de voz:

1. **Especificación (`voice-agent-spec.yaml`):** Define el flujo (WhatsApp/Telegram), los modelos STT/TTS a usar, el idioma por defecto y el prompt del sistema.
2. **Generación automática:** Una IA (GPT-4o) lee la especificación y genera el código TypeScript del worker, el archivo `Dockerfile` y el workflow de GitHub Actions.
3. **Pruebas en CI:**
   - Linting (`eslint`).
   - Pruebas unitarias de las funciones de descarga, conversión y transcripción.
   - Evaluación de calidad de respuestas con **Promptfoo** (usando transcripciones sintéticas).
4. **Infraestructura como Código (IaC):** Terraform aprovisiona el VPS, configura las variables de entorno (desde HashiCorp Vault) y despliega el servicio.
5. **Despliegue continuo:** Un workflow de GitHub Actions construye la imagen Docker, la sube a un registro privado y la despliega en el VPS.

### Hardening de Seguridad Específico para Voz

- **Cifrado en tránsito:** Todas las APIs (WhatsApp, Telegram, STT, TTS) se consumen sobre HTTPS.
- **Validación de webhooks:** Verificación de firma SHA256 (WhatsApp) y uso de `secret_token` (Telegram).
- **Sanitización de archivos:** Los archivos temporales se nombran con UUIDs para evitar path traversal.
- **Aislamiento de workers:** El worker de procesamiento de voz se ejecuta en un proceso separado, con límites de memoria (`--max-old-space-size=512`) para respetar C1.
- **Auditoría (C4):** Cada interacción de voz se registra con `tenant_id`, `transcript_length`, `response_length` y latencia.

### Autogeneración de Workflows de n8n

Para agentes que requieren lógica condicional compleja (ej: "si el usuario dice 'reservar', invocar herramienta X"), el sistema de autogeneración puede crear un workflow de n8n que se active mediante un webhook desde el worker de voz. El worker envía la transcripción a n8n, n8n ejecuta la lógica de negocio y devuelve el texto de respuesta, que luego el worker sintetiza con TTS.

---

## 🔗 Referencias Cruzadas y Glosario

- [[whatsapp-rag-openrouter.md]] - Orquestación de agentes de WhatsApp con RAG.
- [[telegram-bot-integration.md]] - Integración básica con Telegram.
- [[openrouter-api-integration.md]] - Patrón general para consumir LLMs vía OpenRouter.
- [[gpt-integration.md]] - Integración específica con GPT-4o.
- [[deepseek-integration.md]] - Integración con DeepSeek.
- [[environment-variable-management.md]] - Gestión segura de secretos.

**Glosario:**
- **STT:** Speech-to-Text. Conversión de audio a texto.
- **TTS:** Text-to-Speech. Conversión de texto a audio.
- **RAG:** Retrieval-Augmented Generation.
- **BullMQ:** Biblioteca de colas basada en Redis para Node.js.
- **Opus:** Codec de audio de alta calidad usado por WhatsApp y Telegram.
- **WAV/PCM16:** Formato de audio sin comprimir requerido por Whisper API.

FIN DEL ARCHIVO
<!-- ai:file-end marker - do not remove -->
Versión 1.0.0 - 2026-04-11 - Mantis-AgenticDev

