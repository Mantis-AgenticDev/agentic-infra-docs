---
title: "llama-integration.md"
category: "Skill"
domain: ["ai", "generico"]
constraints: ["C1", "C2", "C3", "C4", "C6"]
priority: "ALTA"
version: "2.0.0"
last_updated: "2026-04-11"
ai_optimized: true
tags:
  - sdd/skill/ai
  - lang/es
related_files:
  - "01-RULES/03-SECURITY-RULES.md"
  - "02-SKILLS/COMUNICACION/whatsapp-rag-openrouter.md"
  - "02-SKILLS/AI/openrouter-api-integration.md"
  - "02-SKILLS/AI/deepseek-integration.md"
  - "05-CONFIGURATIONS/environment-variable-management.md"
---

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

**Objetivo en 3 minutos:** Realizar la primera llamada a un modelo Llama (Meta) a través de OpenRouter.

1. **Requisito previo:** Tener una cuenta en [OpenRouter.ai](https://openrouter.ai) y su API Key.
2. **Configurar variable de entorno (C3):**  
   ```bash
   echo "OPENROUTER_API_KEY=sk-or-v1-..." >> .env
   ```
3. **Probar con `curl` el modelo gratuito Llama 3.3 70B:**
   ```bash
   curl https://openrouter.ai/api/v1/chat/completions \
     -H "Authorization: Bearer $OPENROUTER_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "model": "meta-llama/llama-3.3-70b-instruct:free",
       "messages": [{"role": "user", "content": "¿Cuál es la capital de Francia?"}]
     }'
   ```
✅ **Deberías ver:** Un JSON con `choices[0].message.content` y la respuesta "París".  
❌ **Si ves:** `{"error":{"message":"No endpoints found matching your data policy"}}` → Ve a Troubleshooting #2.

⚠️ **Advertencia para Junior:** Los modelos Llama destacan por su excelente rendimiento general y soporte multilingüe (200+ idiomas). Al usar versiones gratuitas a través de OpenRouter, respeta los límites de contexto (131K-192K tokens) para evitar errores de truncamiento.

---

## 🎯 Propósito y Alcance

Este skill documenta los patrones de integración para consumir los modelos de la familia **Llama de Meta** en el ecosistema MANTIS, tanto a través de OpenRouter como de proveedores especializados como **Groq** (inferencia de alta velocidad) y **Together AI** (modelos open-source). Llama es la columna vertebral de muchos agentes autogenerados en MANTIS por su balance entre rendimiento, contexto y costo.

**Cubre:**
- Los principales modelos Llama disponibles en 2026: **Llama 3.3 70B** (texto), **Llama 4 Scout** (multimodal texto+imagen), y **Llama 4 Maverick** (contexto masivo).
- Estrategias de implementación para **razonamiento**, **tool calling (Function Calling)**, y **manejo de contexto ultra-largo** (hasta 1M tokens).
- Configuración de límites de tasa (rate limits) y reintentos para cumplir con las restricciones de hardware del VPS (C1, C2).
- Integración con **Groq** para inferencia de baja latencia (460 tokens/seg) y **Together AI** para despliegues de bajo costo.
- **CI/CD e Infraestructura como Código (IaC)** con Terraform para despliegue automatizado.
- **Hardening de seguridad** y verificación automatizada de integridad de secretos.
- **Autogeneración por IA** de workflows y agentes usando Llama.

**No cubre:**
- Modelos de código especializados como Llama 4 Coder (se mencionan pero no son el foco principal).
- La lógica de negocio de los agentes (eso reside en los workflows de n8n).
- La gestión de prompts por vertical (ubicada en `05-CONFIGURATIONS/prompts/`).

### Modelos Llama Objetivo (2026)

Basado en la disponibilidad en OpenRouter y las especificaciones de Meta, nos enfocaremos en:

| Modelo | ID (OpenRouter / Groq) | Contexto | Características Clave | Estado (Abr 2026) |
| :--- | :--- | :--- | :--- | :--- |
| **Llama 3.3 70B** | `meta-llama/llama-3.3-70b-instruct:free` | 128K tokens | Rendimiento nivel GPT-4, solo texto, excelente para tareas generales y RAG. | Estable (Gratuito en OpenRouter) |
| **Llama 4 Scout** | `meta-llama/llama-4-scout-17b-16e-instruct` | 192K tokens | Multimodal nativo (texto + imagen), MoE (17B activos / 109B totales), tool calling. | Producción (Groq / Together) |
| **Llama 4 Maverick** | `meta-llama/llama-4-maverick:free` | 1M tokens (256K en OpenRouter) | Contexto masivo, MoE (17B activos / 400B totales, 128 expertos), multimodal, tool calling avanzado. | Gratuito en OpenRouter |

---

## 📐 Fundamentos (De 0 a Intermedio)

### El Ecosistema Llama
Llama es una familia de modelos open-weight desarrollados por Meta. A diferencia de otros modelos, Llama está optimizado para ser eficiente y versátil.

**1. Arquitectura Mixture of Experts (MoE):**
Llama 4 introduce MoE, donde el modelo tiene un gran número de parámetros "expertos" pero solo activa un subconjunto pequeño (ej: 17B de 400B) para cada tarea. Esto permite un rendimiento superior con un costo computacional controlado.

**2. Contexto Ultra-Largo:**
Llama 4 Maverick soporta hasta 1M de tokens de contexto, ideal para analizar documentos extensos (manuales, historiales clínicos) en una sola consulta. Scout ofrece 192K tokens, suficiente para la mayoría de los casos de uso.

**3. Tool Calling Robusto:**
Las versiones recientes han mejorado drásticamente la fiabilidad del `function calling`. El modelo es menos propenso a alucinar nombres de funciones o tipos de argumentos incorrectos. Esto es crítico para agentes que deben interactuar con bases de datos o APIs.

**4. Multimodalidad Nativa:**
Scout y Maverick pueden procesar imágenes directamente, sin necesidad de un modelo de visión externo. La imagen se tokeniza y se inyecta en el mismo flujo de atención que el texto.

### Integración con MANTIS
Al igual que con `openrouter-api-integration.md`, la integración se basa en inyectar el contexto RAG y el `tenant_id` en las llamadas a la API. La principal diferencia radica en el **manejo de la multimodalidad** y la **optimización para contexto ultra-largo**.

---

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

### Aplicación de Constraints C1 y C2

- **C1 (RAM):** Al usar modelos con contexto masivo (1M tokens), la respuesta puede ser muy larga. **No acumules la respuesta completa en RAM.** Siempre usa `streaming` para procesar el flujo de tokens y liberar memoria.
- **C2 (vCPU):** El costo de CPU es bajo (I/O de red). Para tareas de alta frecuencia, considera usar **Groq**, que ofrece inferencia a 460 tokens/seg, reduciendo el tiempo de espera del VPS.

### Configuración de Cliente HTTP Optimizado

```typescript
import axios from 'axios';
import http from 'http';

// Agente HTTP con keepAlive para reutilizar conexiones (C1)
const httpAgent = new http.Agent({ keepAlive: true, maxSockets: 3 });

export const llamaClient = axios.create({
  baseURL: 'https://openrouter.ai/api/v1', // O 'https://api.groq.com/openai/v1' para Groq
  timeout: 120000, // Timeout de 2 minutos para contexto largo
  headers: {
    'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}`,
    'HTTP-Referer': process.env.APP_URL || 'http://localhost:3000',
    'X-Title': 'MantisAgenticDev'
  },
  httpAgent
});
```

---

## 🔗 Integración con Stack Existente (n8n, Qdrant, EspoCRM)

### Inyección de Contexto RAG y Tool Calling

```typescript
import { llamaClient } from './llama-client';

export async function generateAgentResponse(
  tenantId: string,
  userQuery: string,
  ragContext: string[]
) {
  const systemPrompt = `
    Eres un asistente para el tenant ${tenantId}.
    Usa el siguiente contexto para responder:
    ${ragContext.join('\n---\n')}
  `;

  try {
    const response = await llamaClient.post('/chat/completions', {
      model: 'meta-llama/llama-4-maverick:free',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userQuery }
      ],
      temperature: 0.1, // Baja temperatura para tareas RAG
      metadata: { tenant_id: tenantId } // C4
    });

    return response.data.choices[0].message.content;
  } catch (error) {
    console.error(`Llama error for tenant ${tenantId}:`, error);
    throw error;
  }
}
```

---

## 🛠️ 15 Ejemplos de Configuración (Copy-Paste Validables)

### Ejemplo 1: Llamada básica a Llama 3.3 70B (Gratuito vía OpenRouter)
**Objetivo**: Probar el modelo gratuito con una pregunta simple.
**Nivel**: 🟢

```typescript
import axios from 'axios';

async function askLlamaFree(prompt: string) {
  const response = await axios.post(
    'https://openrouter.ai/api/v1/chat/completions',
    {
      model: 'meta-llama/llama-3.3-70b-instruct:free',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 200,
    },
    {
      headers: {
        'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}`,
        'Content-Type': 'application/json',
      },
    }
  );
  console.log(response.data.choices[0].message.content);
}
```
✅ **Deberías ver:** La respuesta del modelo en la consola.  
❌ **Si ves:** `Error: Request failed with status code 402` → Ve a Troubleshooting #3.

### Ejemplo 2: Procesamiento multimodal con Llama 4 Scout (imagen + texto)
**Objetivo**: Analizar una imagen y responder a una pregunta sobre ella.
**Nivel**: 🟡

```typescript
import fs from 'fs/promises';

async function analyzeImageWithLlama(imagePath: string, question: string) {
  const imageBuffer = await fs.readFile(imagePath);
  const base64Image = imageBuffer.toString('base64');

  const response = await axios.post(
    'https://openrouter.ai/api/v1/chat/completions',
    {
      model: 'meta-llama/llama-4-scout-17b-16e-instruct',
      messages: [
        {
          role: 'user',
          content: [
            { type: 'text', text: question },
            {
              type: 'image_url',
              image_url: { url: `data:image/jpeg;base64,${base64Image}` }
            }
          ]
        }
      ],
    },
    { headers: { 'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}` } }
  );
  console.log(response.data.choices[0].message.content);
}
```
✅ **Deberías ver:** Una respuesta basada en el contenido de la imagen.  
❌ **Si ves:** `Error: 413 Request Entity Too Large` → La imagen es demasiado grande. Redúcela antes de enviar.

### Ejemplo 3: Tool Calling (Function Calling) con Llama 4 Maverick
**Objetivo**: Permitir que el modelo "llame" a una función para obtener información externa.
**Nivel**: 🟡

```typescript
const tools = [
  {
    type: 'function',
    function: {
      name: 'get_current_weather',
      description: 'Obtiene el clima actual en una ubicación',
      parameters: {
        type: 'object',
        properties: {
          location: { type: 'string', description: 'La ciudad, ej: "Madrid"' },
        },
        required: ['location'],
      },
    },
  },
];

async function askWithTools(prompt: string) {
  const response = await axios.post(
    'https://openrouter.ai/api/v1/chat/completions',
    {
      model: 'meta-llama/llama-4-maverick:free',
      messages: [{ role: 'user', content: prompt }],
      tools: tools,
      tool_choice: 'auto',
    },
    { headers: { 'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}` } }
  );

  const message = response.data.choices[0].message;
  if (message.tool_calls) {
    console.log('El modelo quiere llamar a la función:', message.tool_calls);
  } else {
    console.log(message.content);
  }
}
```
✅ **Deberías ver:** Un objeto `tool_calls` si el prompt es sobre el clima.  
❌ **Si ves:** `"error":"tool_calls" is not valid` → Ve a Troubleshooting #7.

### Ejemplo 4: Procesamiento de contexto ultra-largo (1M tokens) con Maverick
**Objetivo**: Enviar un documento muy extenso para su análisis.
**Nivel**: 🔴

```typescript
import fs from 'fs/promises';

async function analyzeLargeDocument(filePath: string, question: string) {
  const documentText = await fs.readFile(filePath, 'utf-8');
  // Llama 4 Maverick soporta 1M de tokens (~750,000 palabras)

  const response = await axios.post(
    'https://openrouter.ai/api/v1/chat/completions',
    {
      model: 'meta-llama/llama-4-maverick:free',
      messages: [
        { role: 'system', content: 'Analiza el siguiente documento y responde a la pregunta.' },
        { role: 'user', content: `Documento:\n${documentText}\n\nPregunta: ${question}` }
      ],
      max_tokens: 1000,
    },
    { headers: { 'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}` } }
  );
  console.log(response.data.choices[0].message.content);
}
```
✅ **Deberías ver:** Una respuesta basada en el contenido del documento.  
❌ **Si ves:** `Error: 400 Context length exceeded` → Ve a Troubleshooting #5.

### Ejemplo 5: Uso de Groq para inferencia de alta velocidad (Llama 4 Scout)
**Objetivo**: Obtener respuestas en tiempo real con baja latencia.
**Nivel**: 🟡

```typescript
import Groq from 'groq-sdk';

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

async function askGroqLlama(prompt: string) {
  const chatCompletion = await groq.chat.completions.create({
    model: 'llama-4-scout-17b-16e-instruct',
    messages: [{ role: 'user', content: prompt }],
    max_tokens: 500,
    temperature: 0.5,
  });
  console.log(chatCompletion.choices[0]?.message?.content);
}
```
✅ **Deberías ver:** Una respuesta rápida (460 tokens/seg).  
❌ **Si ves:** `Error: 401 Unauthorized` → Ve a Troubleshooting #1.

### Ejemplo 6: Together AI para despliegues de bajo costo (Llama 3.3 70B)
**Objetivo**: Usar Together AI como alternativa económica a OpenRouter.
**Nivel**: 🟢

```python
import os
from together import Together

client = Together(api_key=os.environ["TOGETHER_API_KEY"])

response = client.chat.completions.create(
    model="meta-llama/Llama-3.3-70B-Instruct-Turbo",
    messages=[{"role": "user", "content": "Explícame qué es un RAG"}],
    max_tokens=512,
    temperature=0.7,
)
print(response.choices[0].message.content)
```
✅ **Deberías ver:** Una explicación sobre RAG.  
❌ **Si ves:** `AuthenticationError` → Verifica que `TOGETHER_API_KEY` esté exportada.

### Ejemplo 7: Streaming con Llama 3.3 70B (Node.js)
**Objetivo**: Procesar la respuesta del modelo token por token.
**Nivel**: 🟡

```typescript
import axios from 'axios';

async function streamLlamaResponse(prompt: string) {
  const response = await axios.post(
    'https://openrouter.ai/api/v1/chat/completions',
    {
      model: 'meta-llama/llama-3.3-70b-instruct:free',
      messages: [{ role: 'user', content: prompt }],
      stream: true,
    },
    {
      headers: { 'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}` },
      responseType: 'stream',
    }
  );

  response.data.on('data', (chunk: Buffer) => {
    const lines = chunk.toString().split('\n').filter(line => line.trim() !== '');
    for (const line of lines) {
      const message = line.replace(/^data: /, '');
      if (message === '[DONE]') return;
      try {
        const parsed = JSON.parse(message);
        process.stdout.write(parsed.choices[0].delta.content || '');
      } catch (error) {
        console.error('Could not parse stream message', message, error);
      }
    }
  });
}
```
✅ **Deberías ver:** El texto de la respuesta apareciendo progresivamente.  
❌ **Si ves:** `Error: stream terminated unexpectedly` → Ve a Troubleshooting #8.

### Ejemplo 8: Rate Limiting específico para Llama en OpenRouter
**Objetivo**: Evitar errores `429` respetando los límites de los modelos gratuitos.
**Nivel**: 🟡

```typescript
import Bottleneck from 'bottleneck';

// Límite de ~20 req/min para cuentas gratuitas. 1 petición cada 3 segundos es seguro.
const llamaLimiter = new Bottleneck({ minTime: 3000 });

const safeLlamaCall = llamaLimiter.wrap(async (prompt: string) => {
  return askLlamaFree(prompt); // Reutiliza la función del Ejemplo 1
});
```
✅ **Deberías ver:** Las peticiones se ejecutan espaciadas, sin errores `429`.

### Ejemplo 9: Logging estructurado de uso de tokens (C4)
**Objetivo**: Auditoría de costos y rendimiento.
**Nivel**: 🟢

```typescript
const response = await llamaClient.post('/chat/completions', { /* ... */ });
const usage = response.data.usage;
console.log(JSON.stringify({
  event: 'llama_usage',
  tenant_id: tenantId,
  model: 'llama-3.3-70b',
  prompt_tokens: usage.prompt_tokens,
  completion_tokens: usage.completion_tokens,
  total_tokens: usage.total_tokens,
}));
```
✅ **Deberías ver:** Un log JSON con el conteo de tokens.

### Ejemplo 10: Control de temperatura para tareas creativas vs. precisas
**Objetivo**: Ajustar la creatividad del modelo según la tarea.
**Nivel**: 🟢

```typescript
// Para tareas precisas (RAG, extracción de datos)
const preciseResponse = await axios.post(..., { temperature: 0.1 });
// Para tareas creativas (brainstorming, generación de texto)
const creativeResponse = await axios.post(..., { temperature: 0.8 });
```

### Ejemplo 11: Selección dinámica de modelo basada en la tarea
**Objetivo**: Usar el mejor modelo gratuito según el tipo de consulta del usuario.
**Nivel**: 🟡

```typescript
function selectModelForTask(userPrompt: string): string {
  if (userPrompt.includes('imagen') || userPrompt.includes('foto')) {
    return 'meta-llama/llama-4-scout-17b-16e-instruct'; // Multimodal
  } else if (userPrompt.length > 50000) {
    return 'meta-llama/llama-4-maverick:free'; // Contexto 1M
  } else {
    return 'meta-llama/llama-3.3-70b-instruct:free'; // Generalista
  }
}
```

### Ejemplo 12: Validación de salida JSON estructurada
**Objetivo**: Forzar a un modelo a responder en un formato JSON específico para su uso en workflows.
**Nivel**: 🔴

```typescript
const jsonSchema = {
  type: 'object',
  properties: {
    sentimiento: { type: 'string', enum: ['positivo', 'negativo', 'neutral'] },
    resumen: { type: 'string' }
  },
  required: ['sentimiento', 'resumen']
};

async function getStructuredOutput(text: string) {
  const response = await axios.post(
    'https://openrouter.ai/api/v1/chat/completions',
    {
      model: 'meta-llama/llama-3.3-70b-instruct:free',
      messages: [
        { role: 'system', content: `Eres un analizador de texto. Responde ÚNICAMENTE con un JSON válido que cumpla este esquema: ${JSON.stringify(jsonSchema)}` },
        { role: 'user', content: text }
      ],
      response_format: { type: 'json_object' } // Algunos modelos lo soportan
    },
    { headers: { 'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}` } }
  );
  return JSON.parse(response.data.choices[0].message.content);
}
```

### Ejemplo 13: Manejo de errores con `axios` interceptors
**Objetivo**: Centralizar la lógica de reintento y logging para todas las llamadas a Llama.
**Nivel**: 🟡

```typescript
llamaClient.interceptors.response.use(
  response => response,
  async (error) => {
    const originalRequest = error.config;
    if (error.response?.status === 429 && !originalRequest._retry) {
      originalRequest._retry = true;
      await new Promise(resolve => setTimeout(resolve, 5000)); // Esperar 5 segundos
      return llamaClient(originalRequest);
    }
    return Promise.reject(error);
  }
);
```

### Ejemplo 14: Fallback automático a otro modelo
**Objetivo**: Si Llama 4 Maverick falla, intentar con Llama 3.3 70B (C6).
**Nivel**: 🟡

```typescript
const MODEL_PRIMARY = 'meta-llama/llama-4-maverick:free';
const MODEL_FALLBACK = 'meta-llama/llama-3.3-70b-instruct:free';

async function robustChat(prompt: string) {
  try {
    return await callLlama(MODEL_PRIMARY, prompt);
  } catch (error) {
    console.warn(`Modelo ${MODEL_PRIMARY} falló, usando fallback. Error: ${error.message}`);
    return await callLlama(MODEL_FALLBACK, prompt);
  }
}
```

### Ejemplo 15: Cálculo de tokens antes de enviar (evitar error 400)
**Objetivo**: Estimar tokens usando `tiktoken`.
**Nivel**: 🟢

```bash
npm install tiktoken
```

```typescript
import { encoding_for_model } from 'tiktoken';

// El tokenizador de GPT-4 es una buena aproximación para la mayoría de modelos
const enc = encoding_for_model('gpt-4');
const tokens = enc.encode(userQuery + systemPrompt);
console.log(`Tokens estimados: ${tokens.length}`);
if (tokens.length > 120000) throw new Error('Contexto demasiado largo');
enc.free();
```

---

## 🐞 15 Errores Comunes y Troubleshooting

| Error Exacto (copiable) | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso | Constraint Afectado |
| :--- | :--- | :--- | :--- | :--- |
| **1.** `Error: 401 Unauthorized` | API Key de OpenRouter/Groq inválida o sin saldo. | `curl -H "Authorization: Bearer $API_KEY" https://openrouter.ai/api/v1/auth/key` | 1. Verificar que la key esté activa en el panel de control. 2. Asegurar que la variable de entorno se cargue correctamente. | C3 |
| **2.** `"error":{"message":"No endpoints found matching your data policy"}` | Configuración de privacidad en OpenRouter. | Revisar `https://openrouter.ai/settings`. | Activar la opción "Enable training and logging (chatroom and API)". Es obligatorio para modelos gratuitos. | C6 |
| **3.** `Error: Request failed with status code 402` | Intento de usar un modelo de pago sin créditos. | Verificar el ID del modelo. | Asegurarse de que el ID del modelo termine en `:free` o añadir créditos a la cuenta. | C6 |
| **4.** `Error: 429 Too Many Requests` | Límite de tasa (rate limit) de OpenRouter excedido. | Revisar cabeceras `x-ratelimit-remaining` en la respuesta. | Implementar `bottleneck` (Ejemplo 8) con `minTime: 3000` (1 petición cada 3 segundos). | C1 |
| **5.** `Error: 400 Context length exceeded` | El prompt supera 128K-192K tokens (según modelo). | Calcular tokens con `tiktoken`. | 1. Truncar el contexto RAG a ~100K tokens. 2. Usar Llama 4 Maverick, que soporta 1M tokens. | C2 |
| **6.** `Error: 500 Internal Server Error` con `llama-4-maverick:free` | El modelo está en preview y puede ser inestable. | Verificar `https://status.openrouter.ai`. | Implementar un fallback automático a Llama 3.3 70B (Ejemplo 14). | C6 |
| **7.** `"error":"tool_calls" is not valid` | Uso incorrecto de `tool_calls` o el modelo no lo soporta. | Asegurarse de que el `type` es `function` y el esquema JSON es válido. | 1. Usar modelos que soporten `tool_calls`: Llama 4 Scout/Maverick. 2. Validar el esquema JSON con una herramienta como `ajv`. | - |
| **8.** La respuesta está en inglés a pesar del prompt en español. | El modelo por defecto puede usar inglés. | Revisar el `system prompt`. | Añadir al `system prompt`: `Responde siempre en español.` Llama tiene buen soporte multilingüe. | - |
| **9.** `Error: 413 Request Entity Too Large` (al enviar imágenes) | La imagen base64 supera el límite del proveedor. | Verificar el tamaño de la imagen (`ls -lh`). | Redimensionar la imagen antes de enviarla. Una imagen de 512x512 se convierte en ~1,610 tokens. | C1 |
| **10.** `UNABLE_TO_VERIFY_LEAF_SIGNATURE` (al usar API nativa de Groq) | Problema de certificados SSL en red corporativa. | Probar `curl https://api.groq.com/openai/v1/models`. | Configurar la variable de entorno `NODE_EXTRA_CA_CERTS` con la ruta al certificado de la CA corporativa. | C3 |
| **11.** `Error: getaddrinfo ENOTFOUND openrouter.ai` | Problema de DNS en VPS. | `nslookup openrouter.ai`. | 1. Verificar `/etc/resolv.conf`. 2. Usar `8.8.8.8`. | C3 |
| **12.** Streaming se detiene abruptamente | Problema de red o timeout durante el streaming. | Monitorear la latencia con `ping openrouter.ai`. | Implementar lógica de reintento (Ejemplo 13) y, si falla, reintentar con otro modelo (fallback). | C6 |
| **13.** `"error":{"message":"provider_not_supported"}` | Estás intentando usar un modelo de pago como gratuito. | Asegurarse de que el ID del modelo termine en `:free`. | Usar solo IDs de la lista de modelos gratuitos. | - |
| **14.** Respuesta JSON mal formada | El modelo no siguió el esquema. | Revisar `response_format`. | Usar `response_format: { type: 'json_object' }` y reforzar en el system prompt. | - |
| **15.** `Error: Cannot read properties of undefined (reading 'content')` | La API de OpenRouter devolvió un error en formato JSON pero el código no lo maneja. | Inspeccionar `response.data` con `console.log(JSON.stringify(response.data))`. | Validar siempre `response.data.error` antes de intentar acceder a `choices`. Ver el código de error en `response.data.error.code`. | - |

---

## ✅ Validación SDD y Comandos de Verificación

<!-- ai:constraint=C5 -->
### 1. Verificar conectividad con OpenRouter y el modelo Llama:
```bash
curl -I https://openrouter.ai/api/v1/models/meta-llama/llama-3.3-70b-instruct:free
```
Debe devolver un código `200 OK` o `401 Unauthorized`.

### 2. Auditar el uso de `tenant_id` en logs (C4):
```bash
grep -c '"tenant_id":"' /var/log/mantis-ai.log
```
El número de líneas debe coincidir con las peticiones realizadas.

### 3. Chequeo de secretos (C3):
```bash
grep -r "sk-or-v1-" /opt/mantis --exclude-dir=node_modules
```
No debe haber keys hardcodeadas fuera de los archivos `.env`.

### 4. Monitoreo de latencia y errores (C2):
```typescript
const start = Date.now();
await callLlama(...);
const latency = Date.now() - start;
if (latency > 30000) console.warn(`Alta latencia en Llama: ${latency}ms`);
```

### 5. Backup de la configuración de modelos (C5):
Asegurar que los IDs de los modelos utilizados estén documentados y su configuración (temperatura, max_tokens) esté respaldada en el sistema de control de versiones.

---

## 🚀 CI/CD, IaC y Autogeneración con IA (Normas MANTIS)

### Pipeline de Integración Continua para Agentes Llama

1. **Especificación (`llama-agent-spec.yaml`):** Define el modelo, la temperatura, las herramientas y el contexto RAG.
2. **Generación automática:** Una IA (Llama 3.3 70B o GPT-4o) lee la especificación y genera el código TypeScript del worker, el `Dockerfile` y el workflow de GitHub Actions.
3. **Validación en CI:**
   - Linting (`eslint`).
   - Pruebas unitarias de las funciones de tool calling.
   - Evaluación de calidad con **Promptfoo**.
4. **Infraestructura como Código (IaC) con Terraform:**
   ```hcl
   resource "digitalocean_droplet" "llama_agent" {
     name   = "mantis-llama-agent"
     size   = "s-2vcpu-4gb"
     image  = "ubuntu-22-04-x64"
     region = "nyc3"
     user_data = templatefile("${path.module}/cloud-init.yaml", {
       openrouter_key = var.openrouter_api_key
       groq_key       = var.groq_api_key
     })
   }

   variable "openrouter_api_key" {
     type      = string
     sensitive = true
   }
   variable "groq_api_key" {
     type      = string
     sensitive = true
   }
   ```
5. **Despliegue Continuo:** GitHub Actions ejecuta `terraform apply` y reinicia el servicio en el VPS.

### Hardening de Seguridad

- **Cifrado en tránsito:** HTTPS obligatorio.
- **Validación de entrada:** Sanitización de prompts para prevenir inyecciones.
- **Aislamiento de workers:** Procesos separados con `systemd` y límites de memoria (`MemoryMax=1.5G`).
- **Auditoría (C4):** Cada llamada se registra con `tenant_id` y uso de tokens.
- **Rotación de secretos:** API Keys se rotan cada 90 días usando HashiCorp Vault.

### Autogeneración de Workflows de n8n

Para agentes complejos, el sistema puede generar un workflow de n8n que consuma Llama. El workflow se despliega automáticamente vía API de n8n.

---

## 🔗 Referencias Cruzadas y Glosario

- [[openrouter-api-integration.md]] - Patrón general para consumir modelos vía OpenRouter.
- [[whatsapp-rag-openrouter.md]] - Orquestación de agentes de WhatsApp con RAG.
- [[deepseek-integration.md]] - Patrones de integración específicos para DeepSeek.
- [[environment-variable-management.md]] - Gestión segura de `OPENROUTER_API_KEY`.

**Glosario:**
- **RAG:** Retrieval-Augmented Generation.
- **MoE:** Mixture of Experts, arquitectura que activa solo un subconjunto de parámetros para cada tarea.
- **Tool Calling (Function Calling):** Capacidad del modelo para solicitar la ejecución de una función externa.
- **Groq:** Proveedor de inferencia de alta velocidad basado en LPUs (Language Processing Units).

FIN DEL ARCHIVO
<!-- ai:file-end marker - do not remove -->
Versión 2.0.0 - 2026-04-11 - Mantis-AgenticDev
