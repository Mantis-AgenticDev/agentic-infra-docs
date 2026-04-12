---
title: "gpt-integration.md"
category: "Skill"
domain: ["ai", "generico"]
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
priority: "CRÍTICA"
version: "1.0.0"
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

**Objetivo en 3 minutos:** Realizar la primera llamada a un modelo GPT (OpenAI) a través de OpenRouter o directamente a la API de OpenAI.

1. **Requisito previo:** Tener una API Key de [OpenAI](https://platform.openai.com/api-keys) o de [OpenRouter.ai](https://openrouter.ai).
2. **Configurar variable de entorno (C3):**
   ```bash
   echo "OPENAI_API_KEY=sk-proj-..." >> .env
   # o para OpenRouter:
   echo "OPENROUTER_API_KEY=sk-or-v1-..." >> .env
   ```
3. **Probar con `curl` el modelo GPT-4o-mini (vía OpenRouter):**
   ```bash
   curl https://openrouter.ai/api/v1/chat/completions \
     -H "Authorization: Bearer $OPENROUTER_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "model": "openai/gpt-4o-mini",
       "messages": [{"role": "user", "content": "¿Cuál es la capital de Francia?"}]
     }'
   ```
✅ **Deberías ver:** Un JSON con `choices[0].message.content` y la respuesta "París".
❌ **Si ves:** `{"error":{"message":"Insufficient credits"}}` → Ve a Troubleshooting #3.

⚠️ **Advertencia para Junior:** Los modelos GPT de OpenAI son de pago. Asegúrate de tener créditos en tu cuenta. Respeta siempre los límites de contexto (128K tokens para GPT-4o, 200K para GPT-4.1) y nunca hardcodees las API Keys (C3).

---

## 🎯 Propósito y Alcance

Este skill documenta los patrones de integración para consumir los modelos de la familia **GPT de OpenAI** en el ecosistema MANTIS, tanto a través de OpenRouter como de la API nativa de OpenAI. GPT es el estándar de facto en la industria, con un rendimiento excepcional en tareas de razonamiento, generación de código, y tool calling.

**Cubre:**
- Los principales modelos GPT disponibles: **GPT-4o**, **GPT-4o-mini**, **GPT-4.1** (con contexto 1M), y **o3-mini** (razonamiento avanzado).
- Estrategias de implementación para **streaming**, **function calling**, **respuestas estructuradas (JSON Mode)**, y **procesamiento de imágenes (multimodal)**.
- Integración con **OpenRouter** (fallback unificado) y con la **API nativa de OpenAI** (para mayor control y fine-tuning).
- **Normas CI/CD y SDD** para el despliegue continuo de agentes basados en GPT.
- **Estrategias de evaluación (harness)** con DeepEval y Promptfoo para validar la calidad de las respuestas.
- **Infraestructura como Código (IaC)** para desplegar la configuración de agentes de manera reproducible.
- **Patrones de autogeneración** de código para agentes con GPT.

**No cubre:**
- Modelos de embedding de OpenAI (como `text-embedding-3-small`), que se tratan en el skill de ingesta RAG.
- Fine-tuning de modelos GPT (proceso avanzado que se documenta por separado).
- La lógica de negocio de los agentes (eso reside en los workflows de n8n).

### Modelos GPT Objetivo (2026)

Basado en la disponibilidad en OpenRouter y OpenAI, nos enfocaremos en:

| Modelo | ID (OpenRouter / OpenAI) | Contexto | Características Clave | Precio (input/output por 1M tokens) |
| :--- | :--- | :--- | :--- | :--- |
| **GPT-4o** | `openai/gpt-4o` | 128K | **Multimodal nativo** (texto + imagen), tool calling, excelente rendimiento general. | $2.50 / $10.00 |
| **GPT-4o-mini** | `openai/gpt-4o-mini` | 128K | **Modelo económico y rápido**, ideal para tareas de bajo costo y alta frecuencia. | $0.15 / $0.60 |
| **GPT-4.1** | `openai/gpt-4.1` | 1M | **Contexto ultra-largo (1M tokens)**, mejor rendimiento en benchmarks de codificación. | $2.00 / $8.00 |
| **o3-mini** | `openai/o3-mini` | 200K | **Razonamiento avanzado (Chain-of-Thought)**, especializado en STEM y lógica. | $1.10 / $4.40 |

*Precios según OpenAI, Abril 2026.*

---

## 📐 Fundamentos (De 0 a Intermedio)

### El Ecosistema GPT
GPT (Generative Pre-trained Transformer) es la familia de modelos de lenguaje de OpenAI. Son modelos de propósito general que destacan por su versatilidad y fiabilidad.

**1. Multimodalidad Nativa:**
GPT-4o y GPT-4.1 pueden procesar imágenes directamente. La imagen se tokeniza y se inyecta en el mismo flujo de atención que el texto. Esto es ideal para agentes que deben analizar facturas escaneadas, menús con fotos, o diagramas técnicos.

**2. JSON Mode y Structured Outputs:**
OpenAI ofrece un modo JSON estricto y "Structured Outputs", que garantiza que la respuesta del modelo se adhiera a un esquema JSON definido. Esto es fundamental para la autogeneración de agentes, donde la salida del modelo debe ser parseable por código de manera fiable.

**3. Function Calling Robusto:**
El `function calling` de GPT es uno de los más maduros del mercado. El modelo es muy preciso al seleccionar la herramienta adecuada y generar los argumentos en el formato correcto.

**4. Predicted Outputs:**
Para tareas donde se conoce la mayor parte de la respuesta (ej: refactorización de código), se puede usar "Predicted Outputs" para acelerar la generación y reducir costos.

### Integración con MANTIS
Al igual que con otros skills de IA, la integración se basa en inyectar el contexto RAG y el `tenant_id` en las llamadas a la API. La principal diferencia radica en el uso de **Structured Outputs** para garantizar la fiabilidad en la autogeneración de código y la **integración con herramientas de IaC** para el despliegue.

---

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

### Aplicación de Constraints C1 y C2

- **C1 (RAM ≤ 4GB):** La API de OpenAI es I/O de red. La respuesta puede ser larga (máx 16K tokens). **Siempre usa `streaming`** para procesar el flujo de tokens y evitar picos de memoria.
- **C2 (vCPU):** El costo de CPU es mínimo. Para tareas de alta frecuencia, **GPT-4o-mini** ofrece la mejor relación latencia/costo (500-800 ms).

### Configuración de Cliente HTTP Optimizado (API Nativa de OpenAI)

```typescript
import OpenAI from 'openai';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
  maxRetries: 2, // Reintentos automáticos para errores 5xx
  timeout: 120000, // 2 minutos
  httpAgent: new http.Agent({ keepAlive: true, maxSockets: 5 }), // C1
});
```

### Configuración vía OpenRouter (Alternativa)

```typescript
export const gptOpenRouterClient = axios.create({
  baseURL: 'https://openrouter.ai/api/v1',
  timeout: 120000,
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

### Inyección de Contexto RAG y Multimodalidad

```typescript
import OpenAI from 'openai';

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

export async function generateGPTResponse(
  tenantId: string,
  userQuery: string,
  ragContext: string[],
  imageBase64?: string
) {
  const systemPrompt = `
    Eres un asistente para el tenant ${tenantId}.
    Usa el siguiente contexto para responder:
    ${ragContext.join('\n---\n')}
  `;

  const messages: any[] = [
    { role: 'system', content: systemPrompt },
    { role: 'user', content: userQuery }
  ];

  if (imageBase64) {
    messages[1].content = [
      { type: 'text', text: userQuery },
      { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${imageBase64}` } }
    ];
  }

  try {
    const response = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages,
      temperature: 0.1,
      user: tenantId, // C4: tenant_id en el campo 'user' para auditoría
    });

    // Log para auditoría (C4)
    console.log(JSON.stringify({
      event: 'gpt_call',
      tenant_id: tenantId,
      model: 'gpt-4o-mini',
      usage: response.usage
    }));

    return response.choices[0].message.content;
  } catch (error) {
    console.error(`GPT error for tenant ${tenantId}:`, error);
    throw error;
  }
}
```

---

## 🛠️ 15 Ejemplos de Configuración (Copy-Paste Validables)

### Ejemplo 1: Llamada básica a GPT-4o-mini (vía OpenRouter)
**Objetivo**: Probar el modelo económico con una pregunta simple.
**Nivel**: 🟢

```typescript
import axios from 'axios';

async function askGPTMini(prompt: string) {
  const response = await axios.post(
    'https://openrouter.ai/api/v1/chat/completions',
    {
      model: 'openai/gpt-4o-mini',
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

### Ejemplo 2: Llamada a la API nativa de OpenAI (GPT-4o)
**Objetivo**: Usar directamente la API de OpenAI para mayor control.
**Nivel**: 🟢

```typescript
import OpenAI from 'openai';

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

async function askGPT4o(prompt: string) {
  const completion = await openai.chat.completions.create({
    model: 'gpt-4o',
    messages: [{ role: 'user', content: prompt }],
    max_tokens: 500,
  });
  console.log(completion.choices[0].message.content);
}
```
✅ **Deberías ver:** La respuesta del modelo.
❌ **Si ves:** `Error: 429 You exceeded your current quota` → Ve a Troubleshooting #4.

### Ejemplo 3: Procesamiento multimodal (imagen + texto) con GPT-4o
**Objetivo**: Analizar una imagen y responder a una pregunta sobre ella.
**Nivel**: 🟡

```typescript
import OpenAI from 'openai';
import fs from 'fs/promises';

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

async function analyzeImageWithGPT(imagePath: string, question: string) {
  const imageBuffer = await fs.readFile(imagePath);
  const base64Image = imageBuffer.toString('base64');

  const response = await openai.chat.completions.create({
    model: 'gpt-4o',
    messages: [
      {
        role: 'user',
        content: [
          { type: 'text', text: question },
          { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${base64Image}` } },
        ],
      },
    ],
  });
  console.log(response.choices[0].message.content);
}
```
✅ **Deberías ver:** Una respuesta basada en el contenido de la imagen.
❌ **Si ves:** `Error: 400 Invalid image format` → Asegúrate de que la imagen sea JPEG o PNG.

### Ejemplo 4: JSON Mode y Structured Outputs
**Objetivo**: Garantizar que la respuesta del modelo sea un JSON válido que siga un esquema.
**Nivel**: 🟡

```typescript
import OpenAI from 'openai';
import { zodResponseFormat } from 'openai/helpers/zod';
import { z } from 'zod';

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

const CalendarEventSchema = z.object({
  title: z.string(),
  date: z.string(),
  attendees: z.array(z.string()),
});

async function extractEventFromText(text: string) {
  const completion = await openai.beta.chat.completions.parse({
    model: 'gpt-4o-mini',
    messages: [
      { role: 'system', content: 'Extract the calendar event from the text.' },
      { role: 'user', content: text },
    ],
    response_format: zodResponseFormat(CalendarEventSchema, 'event'),
  });

  const event = completion.choices[0].message.parsed;
  console.log(event); // { title: "...", date: "...", attendees: [...] }
}
```
✅ **Deberías ver:** Un objeto JavaScript con la estructura definida.
❌ **Si ves:** `Error: Invalid response format` → El modelo no pudo generar un JSON válido. Mejora el prompt.

### Ejemplo 5: Function Calling con GPT-4o
**Objetivo**: Permitir que el modelo "llame" a una función para obtener información externa.
**Nivel**: 🟡

```typescript
import OpenAI from 'openai';

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

const tools = [
  {
    type: 'function' as const,
    function: {
      name: 'get_current_weather',
      description: 'Get the current weather in a given location',
      parameters: {
        type: 'object',
        properties: {
          location: { type: 'string', description: 'The city, e.g. "San Francisco"' },
        },
        required: ['location'],
      },
    },
  },
];

async function askWithFunction(prompt: string) {
  const response = await openai.chat.completions.create({
    model: 'gpt-4o',
    messages: [{ role: 'user', content: prompt }],
    tools: tools,
    tool_choice: 'auto',
  });

  const message = response.choices[0].message;
  if (message.tool_calls) {
    console.log('Model wants to call function:', message.tool_calls);
    // Execute the function and send the result back to the model.
  } else {
    console.log(message.content);
  }
}
```
✅ **Deberías ver:** Un objeto `tool_calls` si el prompt es sobre el clima.

### Ejemplo 6: Procesamiento de contexto largo con GPT-4.1 (1M tokens)
**Objetivo**: Analizar un documento muy extenso en una sola consulta.
**Nivel**: 🔴

```typescript
import OpenAI from 'openai';
import fs from 'fs/promises';

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

async function analyzeLargeDocument(filePath: string, question: string) {
  const documentText = await fs.readFile(filePath, 'utf-8');
  // GPT-4.1 soporta 1M tokens (~750,000 palabras)

  const response = await openai.chat.completions.create({
    model: 'gpt-4.1',
    messages: [
      { role: 'system', content: 'You are a document analysis assistant.' },
      { role: 'user', content: `Document:\n${documentText}\n\nQuestion: ${question}` }
    ],
    max_tokens: 1000,
  });
  console.log(response.choices[0].message.content);
}
```
✅ **Deberías ver:** Una respuesta basada en el contenido del documento.
❌ **Si ves:** `Error: 400 Context length exceeded` → Trunca el documento.

### Ejemplo 7: Uso de o3-mini para razonamiento avanzado
**Objetivo**: Resolver problemas matemáticos o lógicos complejos.
**Nivel**: 🟡

```typescript
const response = await openai.chat.completions.create({
  model: 'o3-mini',
  messages: [{ role: 'user', content: 'Solve this equation: x^2 - 5x + 6 = 0' }],
  // Nota: o3-mini no soporta 'temperature' directamente, usa 'reasoning_effort'
  reasoning_effort: 'high',
});
console.log(response.choices[0].message.content);
```

### Ejemplo 8: Streaming con GPT-4o-mini (Node.js)
**Objetivo**: Procesar la respuesta token por token para una experiencia más fluida.
**Nivel**: 🟡

```typescript
import OpenAI from 'openai';

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

async function streamGPTResponse(prompt: string) {
  const stream = await openai.chat.completions.create({
    model: 'gpt-4o-mini',
    messages: [{ role: 'user', content: prompt }],
    stream: true,
  });

  for await (const chunk of stream) {
    process.stdout.write(chunk.choices[0]?.delta?.content || '');
  }
}
```
✅ **Deberías ver:** El texto de la respuesta apareciendo progresivamente.

### Ejemplo 9: Rate Limiting con Bottleneck para GPT-4o-mini
**Objetivo**: Evitar errores `429` respetando los límites de la API.
**Nivel**: 🟡

```typescript
import Bottleneck from 'bottleneck';
import OpenAI from 'openai';

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
// GPT-4o-mini tiene límites altos (~10,000 RPM en Tier 1). 10 req/seg es seguro.
const limiter = new Bottleneck({ minTime: 100 }); // 100ms entre llamadas

const safeGPTCall = limiter.wrap(async (prompt: string) => {
  return await askGPTMini(prompt);
});
```

### Ejemplo 10: Logging estructurado de uso de tokens (C4)
**Objetivo**: Auditoría de costos y rendimiento.
**Nivel**: 🟢

```typescript
const response = await openai.chat.completions.create({ /* ... */ });
console.log(JSON.stringify({
  event: 'gpt_usage',
  tenant_id: tenantId,
  model: 'gpt-4o-mini',
  prompt_tokens: response.usage?.prompt_tokens,
  completion_tokens: response.usage?.completion_tokens,
  total_tokens: response.usage?.total_tokens,
}));
```

### Ejemplo 11: Predicted Outputs para acelerar la generación
**Objetivo**: Reducir latencia y costo cuando se conoce gran parte de la respuesta.
**Nivel**: 🔴
````markdown
```typescript
const response = await openai.chat.completions.create({
  model: 'gpt-4o-mini',
  messages: [{ role: 'user', content: 'Refactor this code to use async/await:\n```js\n...\n```' }],
  prediction: {
    type: 'content',
    content: '```js\nasync function fetchData() {\n  try {\n    const response = await fetch(url);\n    return await response.json();\n  } catch (error) {\n    console.error(error);\n  }\n}\n```'
  },
});
```
````
✅ **Deberías ver:** La respuesta generada más rápido y con menor costo.

### Ejemplo 12: Integración con OpenRouter para fallback automático
**Objetivo**: Usar OpenRouter como proxy con fallback a otros modelos si GPT falla.
**Nivel**: 🟡

```typescript
async function resilientGPTCall(prompt: string) {
  try {
    return await askGPTMini(prompt); // vía OpenRouter
  } catch (error) {
    if (error.response?.status === 429 || error.response?.status >= 500) {
      console.warn('GPT failed, falling back to Claude');
      return await askClaude(prompt); // Ver claude-integration.md
    }
    throw error;
  }
}
```

### Ejemplo 13: Evaluación de calidad con Promptfoo (Harness)
**Objetivo**: Integrar evaluaciones automáticas en el pipeline CI/CD.
**Nivel**: 🔴

```yaml
# promptfooconfig.yaml
description: 'GPT-4o-mini Agent Evaluation'
providers:
  - id: openai:gpt-4o-mini
    config:
      apiKey: ${OPENAI_API_KEY}
prompts:
  - file://prompts/system_prompt.txt
tests:
  - vars:
      query: '¿Cuál es el horario de atención?'
    assert:
      - type: contains
        value: '9:00'
      - type: llm-rubric
        value: 'La respuesta debe ser en español y profesional.'
```
✅ **Deberías ver:** Resultados de la evaluación en el pipeline de CI.

### Ejemplo 14: Despliegue automatizado de agentes GPT con IaC (Terraform)
**Objetivo**: Gestionar la configuración de agentes como código.
**Nivel**: 🔴

```hcl
# main.tf
resource "n8n_workflow" "gpt_agent" {
  name        = "GPT-4o Agent - ${var.tenant_id}"
  workflow_json = templatefile("${path.module}/workflow.json.tpl", {
    tenant_id   = var.tenant_id
    openai_key  = var.openai_api_key
    model       = "gpt-4o-mini"
  })
}

variable "tenant_id" {}
variable "openai_api_key" {}
```
✅ **Deberías ver:** Workflow desplegado automáticamente en n8n.

### Ejemplo 15: Autogeneración de agentes con GPT-4o (Meta-Prompting)
**Objetivo**: Usar GPT para generar el código y la configuración de un nuevo agente.
**Nivel**: 🔴

```typescript
async function autoGenerateAgent(tenantVertical: string, requirements: string) {
  const prompt = `
    Eres un arquitecto de agentes de IA. 
    Genera un archivo YAML de especificación de agente (agent-spec.yaml) para un negocio de ${tenantVertical} con los siguientes requisitos: ${requirements}.
    La especificación debe incluir:
    - model: gpt-4o-mini
    - tools: [get_menu, make_reservation]
    - system_prompt: (generado)
  `;
  const specYaml = await askGPT4o(prompt);
  await fs.writeFile(`./specs/${tenantId}.yaml`, specYaml);
  // Luego, el pipeline de CI/CD generará el código a partir de esta especificación.
}
```
✅ **Deberías ver:** Un archivo de especificación generado y listo para ser procesado.

---

## 🐞 15 Errores Comunes y Troubleshooting

| Error Exacto (copiable) | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso | Constraint Afectado |
| :--- | :--- | :--- | :--- | :--- |
| **1.** `Error: 401 Unauthorized` | API Key de OpenAI inválida o expirada. | `curl -H "Authorization: Bearer $OPENAI_API_KEY" https://api.openai.com/v1/models` | 1. Regenerar la key en [OpenAI Platform](https://platform.openai.com/api-keys). 2. Verificar que la variable de entorno esté correctamente cargada. | C3 |
| **2.** `Error: 429 You exceeded your current quota` | Se ha superado la cuota de créditos o el límite de RPM. | Revisar [Usage Dashboard](https://platform.openai.com/usage). | 1. Añadir créditos a la cuenta. 2. Implementar rate limiting (Ejemplo 9). 3. Esperar al siguiente ciclo de facturación. | C6 |
| **3.** `Error: Request failed with status code 402` (OpenRouter) | Créditos insuficientes en OpenRouter para un modelo de pago. | Revisar el saldo en OpenRouter. | Añadir créditos a la cuenta de OpenRouter o usar un modelo gratuito. | C6 |
| **4.** `Error: 400 Invalid image format` | La imagen enviada no es JPEG, PNG, WEBP, o GIF no animado. | `file imagen.xxx` para verificar el formato. | Convertir la imagen a JPEG o PNG antes de enviarla. | - |
| **5.** `Error: 400 Context length exceeded` | El prompt supera los 128K/200K/1M tokens del modelo. | Calcular tokens con `tiktoken`. | 1. Truncar el contexto RAG. 2. Usar GPT-4.1, que soporta 1M tokens. | C2 |
| **6.** `Error: 500 Internal Server Error` | Fallo temporal en la API de OpenAI. | Verificar `https://status.openai.com`. | Implementar lógica de reintentos con backoff exponencial o fallback a otro modelo. | C6 |
| **7.** `Error: The model `gpt-4o` does not support function calling` | Se está usando un ID de modelo incorrecto. | Verificar la documentación de OpenAI. | Usar `gpt-4o`, `gpt-4o-mini`, o `gpt-4.1`. | - |
| **8.** `Error: stream terminated unexpectedly` | Problema de red o timeout durante el streaming. | Monitorear la latencia con `ping api.openai.com`. | 1. Aumentar el timeout del cliente. 2. Usar `stream: false` si el problema persiste. | C6 |
| **9.** `Error: 413 Request Entity Too Large` (al enviar imágenes) | La imagen base64 supera el límite de 20MB de la API. | `ls -lh imagen.jpg`. | Redimensionar la imagen a un máximo de 2048x2048 píxeles antes de enviarla. | C1 |
| **10.** `Error: Invalid response format` en JSON Mode | El modelo no pudo generar un JSON válido. | Revisar el prompt y el esquema. | 1. Mejorar el prompt para que sea más explícito. 2. Usar `zodResponseFormat` (Ejemplo 4) que reintenta internamente. | - |
| **11.** `Error: Rate limit reached for model` | Límite específico de RPM/TPM para ese modelo. | Revisar los headers `x-ratelimit-remaining-requests`. | Implementar `bottleneck` con un `minTime` calculado según los límites del modelo. | C1 |
| **12.** `Error: getaddrinfo ENOTFOUND api.openai.com` | Problema de DNS en el VPS. | `nslookup api.openai.com`. | 1. Verificar `/etc/resolv.conf` (usar `8.8.8.8`). 2. Reiniciar el servicio de red. | C3 |
| **13.** `Error: The API deployment for this resource does not exist` | Se está usando un deployment name en lugar del model name (Azure OpenAI). | Verificar la URL y el deployment name. | Usar el nombre del modelo (`gpt-4o`) en lugar del nombre del deployment si se usa la API de OpenAI directamente. | - |
| **14.** `Error: Request too large for gpt-4o-mini` | El prompt excede el límite de tokens de entrada para ese modelo. | Mismo que #5. | Usar un modelo con mayor contexto o truncar. | C2 |
| **15.** Tests de evaluación (Promptfoo) fallando en CI/CD | Degradación en la calidad de las respuestas de GPT. | Revisar los logs de las ejecuciones de prueba. | 1. Ajustar el prompt o la temperatura del modelo. 2. Considerar un fallback a otro modelo si la degradación es significativa. | C5 |

---

## ✅ Validación SDD y Comandos de Verificación

<!-- ai:constraint=C5 -->
### 1. Verificar conectividad con OpenAI API
```bash
curl -H "Authorization: Bearer $OPENAI_API_KEY" https://api.openai.com/v1/models
```
Debe devolver un JSON con la lista de modelos disponibles.

### 2. Auditar el uso de `tenant_id` en logs (C4)
```bash
grep -c '"tenant_id":"' /var/log/mantis-ai.log
```
El número de líneas debe coincidir con las peticiones realizadas.

### 3. Chequeo de secretos (C3)
```bash
grep -r "sk-proj-" /opt/mantis --exclude-dir=node_modules
```
No debe haber keys hardcodeadas fuera de los archivos `.env`.

### 4. Ejecutar evaluación automática (Harness) en CI/CD
```bash
npx promptfoo eval --config promptfooconfig.yaml
```
Debe ejecutar las pruebas definidas y mostrar un resumen de resultados.

### 5. Validar el despliegue de IaC
```bash
terraform plan
terraform apply -auto-approve
```
Debe mostrar los recursos a crear/modificar y aplicarlos sin errores.

### 6. Backup de la configuración de modelos (C5)
```bash
sha256sum .env > .env.sha256
rsync -avz .env.sha256 backup@server:/backup/configs/
```

---

## 🚀 CI/CD, IaC y Autogeneración con IA (Normas MANTIS)

### Pipeline de Integración Continua para Agentes GPT

El ecosistema MANTIS adopta un enfoque **Specification-Driven Development (SDD)** para la autogeneración de agentes:

1. **Especificación primero:** Cada agente basado en GPT se define mediante un archivo `agent-spec.yaml` que describe su propósito, modelo, herramientas y comportamiento.
2. **Generación automática:** Una IA (como GPT-4o) lee la especificación y genera:
   - El código del agente (TypeScript/Python) con las funciones de tool calling.
   - El workflow de n8n correspondiente en formato JSON.
3. **Validación en CI:** El código generado se somete a un pipeline que incluye:
   - Linting y formateo (`eslint`, `prettier`).
   - Pruebas unitarias de las funciones de tool calling.
   - Evaluación de calidad con **Promptfoo** (métricas de relevancia, fidelidad, etc.).
4. **Infraestructura como Código (IaC):** La configuración del agente (incluyendo el workflow de n8n) se gestiona con **Terraform** o **Pulumi**. Esto garantiza que el despliegue sea reproducible y auditable.
5. **Despliegue Continuo (CD):** Si todas las pruebas pasan, el workflow se despliega automáticamente en la instancia de n8n de producción mediante su API.

### Estrategia de Evaluación (Harness) con Promptfoo

Promptfoo se integra en el pipeline de CI/CD para evaluar automáticamente la calidad de las respuestas de GPT. Ejemplo de configuración:

```yaml
# promptfooconfig.yaml
description: 'GPT-4o-mini RAG Agent Evaluation'
providers:
  - id: openai:gpt-4o-mini
    config:
      apiKey: ${OPENAI_API_KEY}
      temperature: 0.1

prompts:
  - file://prompts/system_prompt.txt

tests:
  - vars:
      query: '¿Cuál es el horario de atención?'
      context: 'El horario de atención es de 9:00 a 18:00, de lunes a viernes.'
    assert:
      - type: contains
        value: '9:00'
      - type: llm-rubric
        value: 'La respuesta debe ser en español, profesional y basada únicamente en el contexto proporcionado.'
```

### Infraestructura como Código (IaC) con Terraform

Para desplegar la configuración del agente de manera reproducible, se usa Terraform:

```hcl
# variables.tf
variable "tenant_id" {
  description = "ID del tenant para el agente GPT"
  type        = string
}

variable "openai_api_key" {
  description = "API Key de OpenAI"
  type        = string
  sensitive   = true
}

# main.tf
resource "local_file" "agent_config" {
  content = templatefile("${path.module}/agent-spec.yaml.tpl", {
    tenant_id = var.tenant_id
    model     = "gpt-4o-mini"
  })
  filename = "${path.module}/generated/${var.tenant_id}.yaml"
}

resource "n8n_workflow" "gpt_agent" {
  name          = "GPT Agent - ${var.tenant_id}"
  workflow_json = file("${path.module}/workflows/gpt-agent.json")
}
```

### Autogeneración de Agentes con GPT-4o

El propio GPT-4o se utiliza para autogenerar componentes del ecosistema:

1. **Generación de especificaciones:** A partir de una descripción en lenguaje natural del negocio, GPT-4o genera el archivo `agent-spec.yaml`.
2. **Generación de código de herramientas:** GPT-4o puede leer la documentación de una API (en formato OpenAPI) y generar el código TypeScript necesario para integrarla como una herramienta.
3. **Generación de casos de prueba:** GPT-4o analiza el historial de conversaciones y genera casos de prueba para evaluar la robustez del agente.

Este enfoque permite que el ecosistema MANTIS evolucione rápidamente, con agentes que se adaptan a las necesidades específicas de cada tenant sin intervención manual extensa.

---

## 🔗 Referencias Cruzadas y Glosario

- [[openrouter-api-integration.md]] - Patrón general para consumir modelos vía OpenRouter.
- [[whatsapp-rag-openrouter.md]] - Orquestación de agentes de WhatsApp con RAG.
- [[deepseek-integration.md]] - Patrones de integración específicos para DeepSeek.
- [[gemini-integration.md]] - Patrones de integración para modelos Gemini.
- [[environment-variable-management.md]] - Gestión segura de `OPENAI_API_KEY`.

**Glosario:**
- **RAG:** Retrieval-Augmented Generation.
- **Function Calling:** Capacidad del modelo para solicitar la ejecución de una función externa.
- **JSON Mode:** Modo que garantiza que la respuesta del modelo sea un JSON válido.
- **Structured Outputs:** Extensión de JSON Mode que fuerza el cumplimiento de un esquema JSON.
- **SDD:** Specification-Driven Development.
- **IaC:** Infrastructure as Code (Infraestructura como Código).
- **Promptfoo:** Herramienta de evaluación y testing para LLMs.

FIN DEL ARCHIVO
<!-- ai:file-end marker - do not remove -->
Versión 1.0.0 - 2026-04-11 - Mantis-AgenticDev
