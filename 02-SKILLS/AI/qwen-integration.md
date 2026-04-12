---
title: "qwen-integration.md"
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
  - "05-CONFIGURATIONS/environment-variable-management.md"
---

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

**Objetivo en 3 minutos:** Realizar la primera llamada a un modelo Qwen (gratuito) a través de OpenRouter.

1.  **Requisito previo:** Una cuenta en [OpenRouter.ai](https://openrouter.ai) y su API Key.
2.  **Configurar variable de entorno (C3):**
    ```bash
    echo "OPENROUTER_API_KEY=sk-or-v1-..." >> .env
    ```
3.  **Probar con `curl` el modelo Qwen 3.6 Plus Preview (Gratuito):**
    ```bash
    curl https://openrouter.ai/api/v1/chat/completions \
      -H "Authorization: Bearer $OPENROUTER_API_KEY" \
      -H "Content-Type: application/json" \
      -d '{
        "model": "qwen/qwen3.6-plus-preview:free",
        "messages": [{"role": "user", "content": "¿Cuál es la capital de Francia?"}]
      }'
    ```
✅ **Deberías ver:** Un JSON con `choices[0].message.content` y la respuesta "París".
❌ **Si ves:** `{"error":{"message":"No endpoints found matching your data policy"}}` → Ve a Troubleshooting #2.

⚠️ **Advertencia para Junior:** Qwen 3.6 Preview es un modelo de **razonamiento obligatorio**. Internamente, "piensa" antes de responder, lo que puede aumentar la latencia pero mejora la precisión en tareas complejas. Respeta siempre los límites de contexto (1M de tokens para 3.6, 262K para 3.5) para evitar errores de truncamiento.

---

## 🎯 Propósito y Alcance

Este skill documenta los patrones de integración para consumir los modelos de la familia **Qwen (Tongyi Qianwen) de Alibaba Cloud**, tanto a través de su API nativa (DashScope) como del gateway unificado de **OpenRouter**. Qwen destaca por su excelente rendimiento en tareas de razonamiento, su ventana de contexto masiva (hasta 1M de tokens) y su sólido soporte para el idioma español.

**Cubre:**
- Los **tres modelos Qwen más utilizados en producción (2026)**: **Qwen 3.6 Plus Preview** (razonamiento y contexto 1M), **Qwen 3.5 Plus** (multimodal y herramienta de llamadas estable) y **Qwen 3 Coder Next** (especializado en código y agentes CLI).
- Estrategias de implementación para **razonamiento obligatorio (Chain-of-Thought)**, manejo de contexto ultra-largo, **tool calling (Function Calling)** y **respuestas estructuradas (JSON Mode)**.
- Configuración de límites de tasa (rate limits) y reintentos para cumplir con las restricciones de hardware del VPS (C1, C2).
- **CI/CD e Infraestructura como Código (IaC)** con Terraform para despliegue automatizado.
- **Hardening de seguridad** y verificación automatizada de integridad de secretos.
- **Autogeneración por IA** de workflows y agentes usando Qwen.

**No cubre:**
- Modelos multimodales específicos como Qwen-VL o Qwen-Omni (aunque se mencionan, su integración detallada está fuera del alcance principal).
- La lógica de negocio de los agentes (eso reside en los workflows de n8n).
- La gestión de prompts por vertical (ubicada en `05-CONFIGURATIONS/prompts/`).

### Modelos Qwen Objetivo (2026)

Basado en el historial de lanzamientos de Alibaba Cloud y la disponibilidad en OpenRouter, nos enfocaremos en:

| Modelo | ID (OpenRouter / DashScope) | Contexto | Características Clave | Estado (Abr 2026) |
| :--- | :--- | :--- | :--- | :--- |
| **Qwen 3.6 Plus Preview** | `qwen/qwen3.6-plus-preview:free` | **1M tokens** | Razonamiento obligatorio, tool calling confiable, gratuito en OpenRouter. | Preview (Gratuito) |
| **Qwen 3.5 Plus** | `qwen/qwen-3.5-plus` (OpenRouter) | 1M tokens | Modelo de producción estable, multimodal (texto/imagen/video), herramienta de llamadas. | Producción |
| **Qwen 3 Coder Next** | `qwen/qwen3-coder-next` (OpenRouter) | 131K tokens | Especializado en generación de código, agentes de codificación, y soporte CLI. | Producción |

---

## 📐 Fundamentos (De 0 a Intermedio)

### El Ecosistema Qwen
Qwen no es un solo modelo, sino una familia. Para MANTIS, nos centramos en la serie "Plus" y "Coder" por su balance entre capacidad y costo.

**1. Razonamiento Obligatorio (Chain-of-Thought):**
A diferencia de otros modelos donde el razonamiento es opcional, Qwen 3.6 **siempre razona**. Esto significa que internamente genera un bloque de pensamiento (`reasoning_content`) antes de producir la respuesta final (`content`).
- **Ventaja:** Respuestas más precisas en lógica, matemáticas y codificación.
- **Desventaja:** Mayor latencia y consumo de tokens (se cobran los tokens de razonamiento).

**2. Contexto de 1M de Tokens:**
Tanto Qwen 3.6 como 3.5 soportan 1 millón de tokens de contexto. Esto es ~750,000 palabras, suficiente para analizar documentos extensos (manuales de procedimientos, historiales clínicos completos) en una sola consulta.

**3. Tool Calling Robusto:**
Las versiones recientes han mejorado drásticamente la fiabilidad del `function calling`. El modelo es menos propenso a alucinar nombres de funciones o tipos de argumentos incorrectos. Esto es crítico para agentes que deben interactuar con bases de datos o APIs.

### Integración con MANTIS
Al igual que con `openrouter-api-integration.md`, la integración se basa en inyectar el contexto RAG y el `tenant_id` en las llamadas a la API. La principal diferencia radica en el **manejo del razonamiento** y la **optimización para contexto ultra-largo**.

---

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

### Aplicación de Constraints C1 y C2

- **C1 (RAM):** El principal riesgo con Qwen es la respuesta. Dado el contexto masivo, la respuesta puede ser muy larga (máx 65K tokens). **No acumules la respuesta completa en RAM.** Siempre usa `streaming` para procesar el flujo de tokens y liberar memoria.
- **C2 (vCPU):** El costo de CPU es bajo (I/O de red), pero el **razonamiento interno** de Qwen ocurre en los servidores de Alibaba/OpenRouter. El VPS solo espera. Ajusta el `timeout` del cliente HTTP a **120 segundos** para dar tiempo al modelo a "pensar".

### Configuración de Cliente HTTP Optimizado

```typescript
import axios from 'axios';
import http from 'http';

// Agente HTTP con keepAlive para reutilizar conexiones (C1)
const httpAgent = new http.Agent({ keepAlive: true, maxSockets: 3 });

export const qwenClient = axios.create({
  baseURL: 'https://openrouter.ai/api/v1', // O 'https://dashscope-intl.aliyuncs.com/compatible-mode/v1' para API nativa
  timeout: 120000, // Timeout de 2 minutos para razonamiento
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

### Inyección de Contexto RAG y Razonamiento

Al usar Qwen 3.6, es útil **extraer y loguear el razonamiento** para auditoría (C4) y depuración de agentes.

```typescript
import { qwenClient } from './qwen-client';

export async function generateReasonedResponse(
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
    const response = await qwenClient.post('/chat/completions', {
      model: 'qwen/qwen3.6-plus-preview:free',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userQuery }
      ],
      temperature: 0.1, // Baja temperatura para tareas RAG
      // Solicitar explícitamente el razonamiento (aunque en 3.6 es obligatorio)
      include_reasoning: true,
      metadata: { tenant_id: tenantId } // C4
    });

    const message = response.data.choices[0].message;
    const reasoning = message.reasoning; // Cadena de pensamiento interna
    const answer = message.content;       // Respuesta final

    // Log para auditoría
    console.log(JSON.stringify({
      event: 'qwen_reasoning',
      tenant_id: tenantId,
      reasoning_length: reasoning?.length,
      answer_length: answer?.length
    }));

    return answer;
  } catch (error) {
    console.error(`Qwen error for tenant ${tenantId}:`, error);
    throw error;
  }
}
```

---

## 🛠️ 20 Ejemplos de Configuración (Copy-Paste Validables)

### Sección A: Qwen 3.6 Plus Preview (8 ejemplos)

#### Ejemplo A1: Llamada básica con razonamiento
**Objetivo**: Consulta simple aprovechando el razonamiento obligatorio.
**Nivel**: 🟢

```typescript
import axios from 'axios';

async function askQwen36(prompt: string) {
  const response = await axios.post(
    'https://openrouter.ai/api/v1/chat/completions',
    {
      model: 'qwen/qwen3.6-plus-preview:free',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 500,
      include_reasoning: true
    },
    { headers: { Authorization: `Bearer ${process.env.OPENROUTER_API_KEY}` } }
  );
  console.log('Razonamiento:', response.data.choices[0].message.reasoning);
  console.log('Respuesta:', response.data.choices[0].message.content);
}
```
✅ **Deberías ver:** Razonamiento y respuesta final.
❌ **Si ves:** `reasoning` es `null` → Asegúrate de usar el modelo correcto.

#### Ejemplo A2: Contexto masivo (1M tokens)
**Objetivo**: Procesar un documento extenso.
**Nivel**: 🔴

```typescript
async function analyzeLargeDocWithQwen(doc: string, question: string) {
  const response = await qwenClient.post('/chat/completions', {
    model: 'qwen/qwen3.6-plus-preview:free',
    messages: [
      { role: 'system', content: 'Analiza el documento y responde.' },
      { role: 'user', content: `Documento:\n${doc}\n\nPregunta: ${question}` }
    ],
    max_tokens: 1000
  });
  return response.data.choices[0].message.content;
}
```
✅ **Deberías ver:** Respuesta basada en todo el documento.
❌ **Si ves:** `Error: 400 Context length exceeded` → Ve a Troubleshooting #5.

#### Ejemplo A3: Streaming para respuestas largas
**Objetivo**: Recibir tokens en tiempo real.
**Nivel**: 🟡

```typescript
async function streamQwen36(prompt: string) {
  const response = await axios.post(
    'https://openrouter.ai/api/v1/chat/completions',
    {
      model: 'qwen/qwen3.6-plus-preview:free',
      messages: [{ role: 'user', content: prompt }],
      stream: true
    },
    { headers: { Authorization: `Bearer ${process.env.OPENROUTER_API_KEY}` }, responseType: 'stream' }
  );
  response.data.on('data', (chunk: Buffer) => {
    const lines = chunk.toString().split('\n').filter(line => line.trim() !== '');
    for (const line of lines) {
      const message = line.replace(/^data: /, '');
      if (message === '[DONE]') return;
      try {
        const parsed = JSON.parse(message);
        process.stdout.write(parsed.choices[0].delta.content || '');
      } catch {}
    }
  });
}
```

#### Ejemplo A4: Tool Calling
**Objetivo**: Llamar funciones externas.
**Nivel**: 🟡

```typescript
const tools = [{
  type: 'function',
  function: {
    name: 'get_weather',
    description: 'Obtiene el clima actual',
    parameters: {
      type: 'object',
      properties: { location: { type: 'string' } },
      required: ['location']
    }
  }
}];

async function qwenWithTools(prompt: string) {
  const response = await qwenClient.post('/chat/completions', {
    model: 'qwen/qwen3.6-plus-preview:free',
    messages: [{ role: 'user', content: prompt }],
    tools,
    tool_choice: 'auto'
  });
  const msg = response.data.choices[0].message;
  if (msg.tool_calls) console.log('Tool calls:', msg.tool_calls);
  else console.log(msg.content);
}
```

#### Ejemplo A5: Rate limiting y reintentos
**Objetivo**: Manejar límites gratuitos con backoff.
**Nivel**: 🟡

```typescript
import Bottleneck from 'bottleneck';
const limiter = new Bottleneck({ minTime: 3000 }); // 20 req/min

const safeQwenCall = limiter.wrap(async (prompt: string) => {
  return askQwen36(prompt);
});
```

#### Ejemplo A6: Respuesta en JSON estructurado
**Objetivo**: Forzar salida JSON para parseo automático.
**Nivel**: 🟡

```typescript
const response = await qwenClient.post('/chat/completions', {
  model: 'qwen/qwen3.6-plus-preview:free',
  messages: [
    { role: 'system', content: 'Responde solo con JSON válido.' },
    { role: 'user', content: 'Dame un JSON con nombre, edad y ciudad.' }
  ],
  response_format: { type: 'json_object' }
});
```

#### Ejemplo A7: Control de temperatura para tareas creativas vs. precisas
**Objetivo**: Ajustar la creatividad del modelo.
**Nivel**: 🟢

```typescript
// Para tareas precisas (RAG)
const precise = await qwenClient.post(..., { temperature: 0.1 });
// Para tareas creativas
const creative = await qwenClient.post(..., { temperature: 0.8 });
```

#### Ejemplo A8: Fallback automático a otro modelo
**Objetivo**: Si Qwen 3.6 falla, usar Qwen 3.5 Plus.
**Nivel**: 🟡

```typescript
async function resilientCall(prompt: string) {
  try {
    return await askQwen36(prompt);
  } catch (err) {
    if (err.response?.status === 429 || err.response?.status >= 500) {
      return await askQwen35(prompt); // Fallback a 3.5 Plus
    }
    throw err;
  }
}
```

### Sección B: Qwen 3.5 Plus (6 ejemplos)

#### Ejemplo B1: Llamada básica de producción
**Objetivo**: Usar el modelo estable para casos generales.
**Nivel**: 🟢

```typescript
async function askQwen35(prompt: string) {
  const response = await qwenClient.post('/chat/completions', {
    model: 'qwen/qwen-3.5-plus',
    messages: [{ role: 'user', content: prompt }],
    max_tokens: 400
  });
  console.log(response.data.choices[0].message.content);
}
```

#### Ejemplo B2: Multimodal (imagen + texto)
**Objetivo**: Analizar una imagen y responder.
**Nivel**: 🟡

```typescript
import fs from 'fs/promises';

async function analyzeImageWithQwen35(imagePath: string, question: string) {
  const imageBuffer = await fs.readFile(imagePath);
  const base64Image = imageBuffer.toString('base64');

  const response = await qwenClient.post('/chat/completions', {
    model: 'qwen/qwen-3.5-plus',
    messages: [{
      role: 'user',
      content: [
        { type: 'text', text: question },
        { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${base64Image}` } }
      ]
    }]
  });
  console.log(response.data.choices[0].message.content);
}
```

#### Ejemplo B3: Tool Calling avanzado
**Objetivo**: Llamar múltiples funciones con parámetros complejos.
**Nivel**: 🔴

```typescript
const advancedTools = [{
  type: 'function',
  function: {
    name: 'search_database',
    description: 'Busca en la base de conocimiento',
    parameters: {
      type: 'object',
      properties: {
        query: { type: 'string' },
        filters: {
          type: 'object',
          properties: {
            date_range: { type: 'string' },
            category: { type: 'string' }
          }
        }
      },
      required: ['query']
    }
  }
}];
// Uso similar al ejemplo A4
```

#### Ejemplo B4: Streaming con 3.5 Plus
**Objetivo**: Respuesta fluida en producción.
**Nivel**: 🟡
(Código similar al ejemplo A3, cambiando el modelo)

#### Ejemplo B5: API nativa de DashScope
**Objetivo**: Conectarse directamente a Alibaba Cloud.
**Nivel**: 🟡

```typescript
const dashscopeClient = axios.create({
  baseURL: 'https://dashscope-intl.aliyuncs.com/compatible-mode/v1',
  headers: { 'Authorization': `Bearer ${process.env.DASHSCOPE_API_KEY}` }
});

const response = await dashscopeClient.post('/chat/completions', {
  model: 'qwen3.5-plus',
  messages: [{ role: 'user', content: 'Hola desde la API nativa' }]
});
```

#### Ejemplo B6: Logging estructurado de uso de tokens (C4)
**Objetivo**: Auditoría de costos.
**Nivel**: 🟢

```typescript
const usage = response.data.usage;
console.log(JSON.stringify({
  event: 'qwen_usage',
  tenant_id: tenantId,
  model: 'qwen-3.5-plus',
  prompt_tokens: usage.prompt_tokens,
  completion_tokens: usage.completion_tokens
}));
```

### Sección C: Qwen 3 Coder Next (6 ejemplos)

#### Ejemplo C1: Generación de código simple
**Objetivo**: Crear una función Python.
**Nivel**: 🟢

```typescript
async function generateCode(prompt: string) {
  const response = await qwenClient.post('/chat/completions', {
    model: 'qwen/qwen3-coder-next',
    messages: [
      { role: 'system', content: 'You are a coding assistant. Output only valid code.' },
      { role: 'user', content: prompt }
    ],
    max_tokens: 800
  });
  console.log(response.data.choices[0].message.content);
}
```

#### Ejemplo C2: Explicación de código
**Objetivo**: Documentar una función existente.
**Nivel**: 🟢

```typescript
const code = `function sum(a, b) { return a + b; }`;
const response = await qwenClient.post('/chat/completions', {
  model: 'qwen/qwen3-coder-next',
  messages: [{ role: 'user', content: `Explica este código:\n${code}` }]
});
```

#### Ejemplo C3: Refactorización automática
**Objetivo**: Mejorar código legacy.
**Nivel**: 🟡

```typescript
const legacyCode = `...`;
const response = await qwenClient.post('/chat/completions', {
  model: 'qwen/qwen3-coder-next',
  messages: [{ role: 'user', content: `Refactoriza este código para usar async/await:\n${legacyCode}` }]
});
```

#### Ejemplo C4: Detección de vulnerabilidades
**Objetivo**: Revisión de seguridad.
**Nivel**: 🟡

```typescript
const response = await qwenClient.post('/chat/completions', {
  model: 'qwen/qwen3-coder-next',
  messages: [{ role: 'user', content: `Revisa este código en busca de vulnerabilidades:\n${code}` }]
});
```

#### Ejemplo C5: Generación de tests unitarios
**Objetivo**: Crear pruebas automáticamente.
**Nivel**: 🟡

```typescript
const response = await qwenClient.post('/chat/completions', {
  model: 'qwen/qwen3-coder-next',
  messages: [{ role: 'user', content: `Genera tests unitarios para esta función:\n${code}` }]
});
```

#### Ejemplo C6: Traducción entre lenguajes
**Objetivo**: Convertir Python a TypeScript.
**Nivel**: 🟡

```typescript
const pythonCode = `def hello(): print("Hello")`;
const response = await qwenClient.post('/chat/completions', {
  model: 'qwen/qwen3-coder-next',
  messages: [{ role: 'user', content: `Traduce este código de Python a TypeScript:\n${pythonCode}` }]
});
```

---

## 🐞 20 Errores Comunes y Troubleshooting

| Error Exacto (copiable) | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso | Constraint Afectado |
| :--- | :--- | :--- | :--- | :--- |
| **1.** `Error: 401 Unauthorized` | API Key de OpenRouter inválida o sin saldo. | `curl -H "Authorization: Bearer $OPENROUTER_API_KEY" https://openrouter.ai/api/v1/auth/key` | 1. Verificar que la key esté activa en OpenRouter Settings. 2. Asegurar que la variable de entorno se cargue correctamente. | C3 |
| **2.** `"error":{"message":"No endpoints found matching your data policy"}` | Configuración de privacidad en OpenRouter. | Revisar `https://openrouter.ai/settings`. | Activar la opción "Enable training and logging (chatroom and API)". Es obligatorio para modelos gratuitos. | C6 |
| **3.** `Error: Request failed with status code 402` | Intento de usar modelo de pago sin créditos. | Verificar el ID del modelo. | Asegurarse de que el ID termine en `:free` o añadir créditos. | C6 |
| **4.** `Error: 429 Too Many Requests` | Límite de tasa excedido. | Revisar cabeceras `x-ratelimit-remaining`. | Implementar `bottleneck` con `minTime: 3000`. | C1 |
| **5.** `Error: 400 Context length exceeded` | Prompt supera 1M/131K tokens. | Calcular tokens con `tiktoken`. | Truncar contexto RAG. Usar modelo con mayor contexto. | C2 |
| **6.** `Error: 500 Internal Server Error` con `qwen3.6-plus-preview:free` | Modelo en preview inestable. | Verificar `https://status.openrouter.ai`. | Implementar fallback a `qwen-3.5-plus`. | C6 |
| **7.** `"error":"tool_calls" is not valid` | Uso incorrecto de tool_calls. | Validar esquema JSON. | Usar modelos que soporten tool_calls (Qwen 3.6, 3.5, Coder). Validar con `ajv`. | - |
| **8.** Respuesta en inglés a pesar de prompt en español | Modelo por defecto usa inglés. | Revisar system prompt. | Añadir `Responde siempre en español.`. | - |
| **9.** `InternalError.Algo.InvalidParameter` con `tool_calls` | Falta mensaje de tool que responda a `tool_call_id`. | Revisar historial de conversación. | Asegurar que tras `assistant` con `tool_calls`, el siguiente mensaje sea de tipo `tool` con el `tool_call_id`. | - |
| **10.** `UNABLE_TO_VERIFY_LEAF_SIGNATURE` (API nativa) | Problema de certificados SSL en red corporativa. | `curl https://dashscope-intl.aliyuncs.com`. | Configurar `NODE_EXTRA_CA_CERTS`. | C3 |
| **11.** `Error: socket hang up` | Timeout de conexión. | `time curl ...`. | Aumentar timeout a 120s. Usar streaming. | C2 |
| **12.** `"message":"Model not found"` | Nombre de modelo incorrecto. | `curl https://openrouter.ai/api/v1/models`. | Usar IDs exactos: `qwen/qwen3.6-plus-preview:free`, `qwen/qwen-3.5-plus`, `qwen/qwen3-coder-next`. | - |
| **13.** `Error: 400 Invalid image format` (multimodal) | Imagen no es JPEG/PNG. | `file imagen.xxx`. | Convertir a JPEG o PNG. | - |
| **14.** `reasoning` es `null` | Modelo no soporta reasoning o no se solicitó. | Asegurar `include_reasoning: true`. | Usar Qwen 3.6 o Qwen Max. | - |
| **15.** `Error: Request Entity Too Large (413)` | Payload demasiado grande (imagen base64). | Verificar tamaño del body. | Redimensionar imagen antes de enviar. | C1 |
| **16.** `Error: getaddrinfo ENOTFOUND openrouter.ai` | Problema de DNS en VPS. | `nslookup openrouter.ai`. | Verificar `/etc/resolv.conf` (usar `8.8.8.8`). | C3 |
| **17.** Streaming se detiene abruptamente | Problema de red. | Monitorear con `ping`. | Implementar reintentos y fallback. | C6 |
| **18.** `Error: 403 Forbidden` en API nativa | API Key de DashScope sin permisos. | Verificar en consola de Alibaba Cloud. | Habilitar servicio "Tongyi Qianwen" para la key. | C3 |
| **19.** Respuesta JSON mal formada | Modelo no siguió esquema. | Revisar `response_format`. | Usar `response_format: { type: 'json_object' }` y reforzar en system prompt. | - |
| **20.** Latencia >30s en Qwen 3.6 | Razonamiento complejo. | Medir con `time`. | Usar `streaming` para mejorar experiencia. Cambiar a Qwen 3.5 Plus si no se requiere razonamiento. | C2 |

---

## ✅ Validación SDD y Comandos de Verificación

<!-- ai:constraint=C5 -->
### 1. Verificar conectividad con OpenRouter y modelo Qwen:
```bash
curl -I https://openrouter.ai/api/v1/models/qwen/qwen3.6-plus-preview:free
```
Debe devolver `200 OK` o `401 Unauthorized`.

### 2. Auditar el uso de `tenant_id` en logs (C4):
```bash
grep -c '"tenant_id":"' /var/log/mantis-ai.log
```

### 3. Chequeo de secretos (C3):
```bash
grep -r "sk-or-v1-" /opt/mantis --exclude-dir=node_modules
```

### 4. Monitoreo de latencia (C2):
```typescript
const start = Date.now();
await callQwen(...);
const latency = Date.now() - start;
if (latency > 30000) console.warn(`Alta latencia: ${latency}ms`);
```

### 5. Backup de configuración (C5):
```bash
sha256sum .env > .env.sha256
rsync -avz .env.sha256 backup@server:/backup/
```

---

## 🚀 CI/CD, IaC y Autogeneración con IA (Normas MANTIS)

### Pipeline de CI/CD para Agentes Qwen

1. **Especificación (`qwen-agent-spec.yaml`):** Define modelo, temperatura, herramientas y contexto RAG.
2. **Generación automática:** Una IA (Qwen 3.5 Plus) lee la especificación y genera el código TypeScript del worker, el `Dockerfile` y el workflow de GitHub Actions.
3. **Validación en CI:**
   - Linting (`eslint`).
   - Pruebas unitarias de tool calling.
   - Evaluación de calidad con **Promptfoo**.
4. **Infraestructura como Código (IaC) con Terraform:**
   ```hcl
   resource "digitalocean_droplet" "qwen_agent" {
     name   = "mantis-qwen-agent"
     size   = "s-2vcpu-4gb"
     image  = "ubuntu-22-04-x64"
     region = "nyc3"
     user_data = templatefile("${path.module}/cloud-init.yaml", {
       openrouter_key = var.openrouter_api_key
     })
   }

   variable "openrouter_api_key" {
     type      = string
     sensitive = true
   }
   ```
5. **Despliegue Continuo:** GitHub Actions ejecuta `terraform apply` y reinicia el servicio.

### Hardening de Seguridad

- **Cifrado en tránsito:** HTTPS obligatorio.
- **Validación de entrada:** Se sanitizan prompts para prevenir inyecciones.
- **Aislamiento de workers:** Procesos separados con `systemd` y límites de memoria (`MemoryMax=1.5G`).
- **Auditoría (C4):** Cada llamada se registra con `tenant_id` y uso de tokens.
- **Rotación de secretos:** API Keys se rotan cada 90 días usando HashiCorp Vault.

### Autogeneración de Workflows de n8n

Para agentes complejos, el sistema puede generar un workflow de n8n que consuma Qwen. El workflow se despliega automáticamente vía API de n8n.

---

## 🔗 Referencias Cruzadas y Glosario

- [[openrouter-api-integration.md]] - Patrón general para consumir modelos vía OpenRouter.
- [[whatsapp-rag-openrouter.md]] - Orquestación de agentes de WhatsApp con RAG.
- [[deepseek-integration.md]] - Patrones de integración específicos para DeepSeek.
- [[environment-variable-management.md]] - Gestión segura de `OPENROUTER_API_KEY`.

**Glosario:**
- **RAG:** Retrieval-Augmented Generation.
- **Chain-of-Thought (CoT):** Técnica de prompting que incita al modelo a razonar paso a paso.
- **Tool Calling (Function Calling):** Capacidad del modelo para solicitar la ejecución de una función externa.
- **DashScope:** La plataforma de servicios de modelos de Alibaba Cloud.
- **MoE:** Mixture of Experts, una arquitectura de modelo que activa solo una parte de sus parámetros para ser más eficiente.

FIN DEL ARCHIVO
<!-- ai:file-end marker - do not remove -->
Versión 2.0.0 - 2026-04-11 - Mantis-AgenticDev
