---
title: "minimax-integration.md"
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
  - "02-SKILLS/COMUNICACION/whatsapp-rag-openrouter.md"
  - "02-SKILLS/AI/openrouter-api-integration.md"
  - "02-SKILLS/AI/deepseek-integration.md"
  - "05-CONFIGURATIONS/environment-variable-management.md"
---

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

**Objetivo en 3 minutos:** Realizar la primera llamada a un modelo MiniMax (M2.5) a través de OpenRouter o la API nativa de MiniMax.

1. **Requisito previo:** Obtener una API Key de [MiniMax Open Platform](https://platform.minimaxi.com) o de [OpenRouter.ai](https://openrouter.ai).
2. **Configurar variables de entorno (C3):**
   ```bash
   echo "MINIMAX_API_KEY=eyJ..." >> .env
   echo "MINIMAX_GROUP_ID=your_group_id" >> .env  # Requerido para API nativa
   # o para OpenRouter:
   echo "OPENROUTER_API_KEY=sk-or-v1-..." >> .env
   ```
3. **Probar con `curl` el modelo MiniMax M2.5 (vía OpenRouter):**
   ```bash
   curl https://openrouter.ai/api/v1/chat/completions \
     -H "Authorization: Bearer $OPENROUTER_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "model": "minimax/minimax-m2.5",
       "messages": [{"role": "user", "content": "¿Cuál es la capital de Francia?"}]
     }'
   ```
✅ **Deberías ver:** Un JSON con `choices[0].message.content` y la respuesta "París".  
❌ **Si ves:** `{"error":{"message":"No endpoints found matching your data policy"}}` → Ve a Troubleshooting #2.

⚠️ **Advertencia para Junior:** MiniMax M2.5 es un modelo MoE (Mixture of Experts) con **197K-204.8K tokens de contexto** y un costo excepcionalmente bajo ($0.30/M input, $1.20/M output en su versión estándar). Respeta siempre los límites de contexto y nunca hardcodees las API Keys (C3). La API nativa de MiniMax requiere tanto `API_KEY` como `GROUP_ID`, que se obtienen en el panel de desarrollador.

---

## 🎯 Propósito y Alcance

Este skill documenta los patrones de integración para consumir los modelos de la familia **MiniMax** en el ecosistema MANTIS, tanto a través de OpenRouter como de la API nativa de MiniMax. MiniMax se destaca por su **contexto ultra-largo (hasta 4M tokens en la serie 01)**, su **excelente relación costo/rendimiento** y su **especialización en agentes y coding**.

**Cubre:**
- Los principales modelos MiniMax disponibles: **MiniMax-Text-01** (contexto 4M), **M1** (razonamiento avanzado, 1M), **M2.1** (agentes y desarrollo), **M2.5** (flagship 2026, coding SOTA) y **M2.7** (versión más reciente).
- Estrategias de implementación para **razonamiento (reasoning)**, **function calling**, **contexto ultra-largo (hasta 4M tokens)** y **streaming de alta velocidad (100+ TPS)**.
- Integración con **OpenRouter** (fallback unificado) y con la **API nativa de MiniMax** (para mayor control y rendimiento).
- **Normas CI/CD y SDD** para el despliegue continuo de agentes basados en MiniMax.
- **Estrategias de evaluación (harness)** con DeepEval y Promptfoo.
- **Infraestructura como Código (IaC)** con Terraform para desplegar la configuración de agentes.
- **Patrones de autogeneración** de código para agentes con MiniMax.

**No cubre:**
- Modelos de visión (MiniMax-VL-01), que se documentan por separado.
- Modelos especializados en roleplay (M2-her).
- La lógica de negocio de los agentes (eso reside en los workflows de n8n).

### Modelos MiniMax Objetivo (2026)

| Modelo | ID (OpenRouter / MiniMax) | Contexto | Características Clave | Precio (input/output por 1M tokens) |
| :--- | :--- | :--- | :--- | :--- |
| **MiniMax-Text-01** | `minimax/minimax-text-01` | 4M tokens | Contexto masivo, MoE (45.9B activos / 456B totales), razonamiento intercalado. | $0.50 / $5.00 (estimado) |
| **MiniMax M1** | `minimax/m1` | 1M tokens | Razonamiento avanzado, tool calling, investigación académica. | $0.50 / $5.00 (estimado) |
| **MiniMax M2.1** | `minimax/m2.1` | 200K tokens | SOTA en agentes y desarrollo de software. | $0.30 / $1.20 |
| **MiniMax M2.5** | `minimax/minimax-m2.5` | 197K tokens | **Flagship 2026**: SOTA en coding (SWE-Bench 80.2%), 100+ TPS, tool calling confiable. | $0.30 / $2.40 (Lightning) $0.15 / $1.20 (Standard) |
| **MiniMax M2.7** | `minimax/m2.7` | 204.8K tokens | Versión más reciente (Mar 2026), mejoras en razonamiento y tool calling. | $0.30 / $1.20 |

---

## 📐 Fundamentos (De 0 a Intermedio)

### El Ecosistema MiniMax

MiniMax es una empresa china de IA fundada en 2021 que ha desarrollado una familia de modelos de lenguaje y visión. Sus modelos se caracterizan por:

**1. Arquitectura Lightning Attention + MoE:**
La serie 01 de MiniMax introduce una arquitectura híbrida que combina Lightning Attention, Softmax Attention y Mixture-of-Experts (MoE). Esto permite manejar contextos de hasta **4 millones de tokens** de manera eficiente, superando a la mayoría de los modelos comerciales.

**2. Contexto Ultra-Largo (4M tokens):**
MiniMax-Text-01 es uno de los pocos modelos que puede procesar 4 millones de tokens en inferencia. Esto equivale a aproximadamente 3 millones de palabras, suficiente para analizar conjuntos de documentos enteros (por ejemplo, toda la base de conocimiento de un tenant) en una sola consulta.

**3. Rendimiento en Agentes y Coding:**
MiniMax M2.5 ha demostrado ser **SOTA en SWE-Bench (80.2%)**, superando a modelos como Claude Opus 4.6. Esto lo hace ideal para agentes autogenerados que necesitan escribir y ejecutar código.

**4. Velocidad de Inferencia Extrema (100+ TPS):**
La versión Lightning de M2.5 soporta más de 100 tokens por segundo de salida, lo que permite construir agentes con respuestas casi instantáneas.

**5. Razonamiento Intercalado (Interleaved Thinking):**
La API de MiniMax soporta `reasoning` (chain-of-thought) que se intercala con el contenido generado. Esto es útil para auditar el proceso de pensamiento del modelo.

**6. API Compatible con OpenAI:**
Tanto OpenRouter como la API nativa de MiniMax (ChatCompletion v2) son compatibles con el formato de OpenAI, facilitando la migración.

### Integración con MANTIS

Al igual que con otros skills de IA, la integración se basa en inyectar el contexto RAG y el `tenant_id` en las llamadas a la API. La principal diferencia radica en el **manejo de contexto ultra-largo** y la **optimización para alta velocidad de inferencia**.

---

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

### Aplicación de Constraints C1 y C2

- **C1 (RAM ≤ 4GB):** Al usar MiniMax-Text-01 con 4M tokens de contexto, la respuesta puede ser larga. **Siempre usa `streaming`** para procesar el flujo de tokens y evitar picos de memoria.
- **C2 (vCPU):** El costo de CPU es mínimo (I/O de red). La alta velocidad de M2.5 (100+ TPS) permite procesar más solicitudes con la misma capacidad de VPS.
- **Rate Limits:** La API de MiniMax impone límites RPM (Requests Per Minute) y TPM (Tokens Per Minute). Para cuentas gratuitas, el límite es de ~100 prompts por cada 5 horas. Usa `bottleneck` para respetar estos límites.

### Configuración de Cliente HTTP Optimizado (API Nativa de MiniMax)

```typescript
import axios from 'axios';
import http from 'http';

// Agente HTTP con keepAlive para reutilizar conexiones (C1)
const httpAgent = new http.Agent({ keepAlive: true, maxSockets: 5 });

export const minimaxClient = axios.create({
  baseURL: 'https://api.minimax.io/v1',
  timeout: 180000, // Timeout de 3 minutos para contexto largo
  headers: {
    'Authorization': `Bearer ${process.env.MINIMAX_API_KEY}`,
    'Content-Type': 'application/json',
  },
  httpAgent
});
```

### Configuración vía OpenRouter (Alternativa)

```typescript
export const minimaxOpenRouterClient = axios.create({
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

### Inyección de Contexto RAG y Razonamiento

```typescript
import { minimaxOpenRouterClient } from './minimax-client';

export async function generateMinimaxResponse(
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
    const response = await minimaxOpenRouterClient.post('/chat/completions', {
      model: 'minimax/minimax-m2.5',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userQuery }
      ],
      temperature: 0.1,
      reasoning: { enabled: true }, // Activar razonamiento para auditoría
      metadata: { tenant_id: tenantId } // C4
    });

    // Log para auditoría (C4)
    console.log(JSON.stringify({
      event: 'minimax_call',
      tenant_id: tenantId,
      model: 'm2.5',
      usage: response.data.usage
    }));

    return response.data.choices[0].message.content;
  } catch (error) {
    console.error(`MiniMax error for tenant ${tenantId}:`, error);
    throw error;
  }
}
```

---

## 🛠️ 15 Ejemplos de Configuración (Copy-Paste Validables)

### Ejemplo 1: Llamada básica a MiniMax M2.5 (vía OpenRouter)
**Objetivo**: Probar el modelo flagship con una pregunta simple.
**Nivel**: 🟢

```typescript
import axios from 'axios';

async function askMinimaxM25(prompt: string) {
  const response = await axios.post(
    'https://openrouter.ai/api/v1/chat/completions',
    {
      model: 'minimax/minimax-m2.5',
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

### Ejemplo 2: Llamada a la API nativa de MiniMax (ChatCompletion v2)
**Objetivo**: Usar directamente la API de MiniMax para mayor control y rendimiento.
**Nivel**: 🟡

```typescript
import axios from 'axios';

async function askMinimaxNative(prompt: string) {
  const response = await axios.post(
    'https://api.minimax.io/v1/text/chatcompletion_v2',
    {
      model: 'MiniMax-M2.5',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 500,
    },
    {
      headers: {
        'Authorization': `Bearer ${process.env.MINIMAX_API_KEY}`,
        'Content-Type': 'application/json',
      },
    }
  );
  console.log(response.data.choices[0].message.content);
}
```
✅ **Deberías ver:** La respuesta del modelo.  
❌ **Si ves:** `Error: 1004 - authentication failed` → Verifica que `MINIMAX_API_KEY` y `MINIMAX_GROUP_ID` estén configurados correctamente.

### Ejemplo 3: Procesamiento de contexto ultra-largo (4M tokens) con MiniMax-Text-01
**Objetivo**: Analizar un documento muy extenso en una sola consulta.
**Nivel**: 🔴

```typescript
import fs from 'fs/promises';
import axios from 'axios';

async function analyzeHugeDocument(filePath: string, question: string) {
  const documentText = await fs.readFile(filePath, 'utf-8');
  // MiniMax-Text-01 soporta 4M tokens (~3M palabras)

  const response = await axios.post(
    'https://openrouter.ai/api/v1/chat/completions',
    {
      model: 'minimax/minimax-text-01',
      messages: [
        { role: 'system', content: 'Eres un asistente de análisis de documentos.' },
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

### Ejemplo 4: Razonamiento intercalado (Interleaved Thinking) con M2.5
**Objetivo**: Obtener el razonamiento paso a paso del modelo para tareas complejas.
**Nivel**: 🟡

```typescript
import axios from 'axios';

async function askWithReasoning(prompt: string) {
  const response = await axios.post(
    'https://openrouter.ai/api/v1/chat/completions',
    {
      model: 'minimax/minimax-m2.5',
      messages: [{ role: 'user', content: prompt }],
      reasoning: { enabled: true }, // Activar razonamiento
    },
    { headers: { 'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}` } }
  );

  const message = response.data.choices[0].message;
  console.log('🧠 Razonamiento:\n', message.reasoning);
  console.log('✅ Respuesta:\n', message.content);
}
```
✅ **Deberías ver:** El razonamiento y la respuesta final.  
❌ **Si ves:** `reasoning` es `null` → Asegúrate de que el modelo soporte reasoning (M1, M2.5, Text-01).

### Ejemplo 5: Function Calling con MiniMax M2.5
**Objetivo**: Permitir que el modelo "llame" a una función para obtener información externa.
**Nivel**: 🟡

```typescript
import axios from 'axios';

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
    'https://api.minimax.io/v1/text/chatcompletion_v2',
    {
      model: 'MiniMax-M2.5',
      messages: [{ role: 'user', content: prompt }],
      tools: tools,
      tool_choice: 'auto',
    },
    {
      headers: {
        'Authorization': `Bearer ${process.env.MINIMAX_API_KEY}`,
        'Content-Type': 'application/json',
      },
    }
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
❌ **Si ves:** `Error: tool_calls is not supported` → Asegúrate de usar ChatCompletion v2.

### Ejemplo 6: Streaming de alta velocidad con M2.5 Lightning (100+ TPS)
**Objetivo**: Procesar la respuesta token por token a máxima velocidad.
**Nivel**: 🟡

```typescript
import axios from 'axios';

async function streamMinimaxResponse(prompt: string) {
  const response = await axios.post(
    'https://openrouter.ai/api/v1/chat/completions',
    {
      model: 'minimax/minimax-m2.5',
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
✅ **Deberías ver:** El texto de la respuesta apareciendo a alta velocidad (100+ tokens/seg).

### Ejemplo 7: Rate Limiting específico para MiniMax (Bottleneck)
**Objetivo**: Evitar errores `1002` (rate limit) respetando los límites de la API.
**Nivel**: 🟡

```typescript
import Bottleneck from 'bottleneck';

// Límite de ~20 RPM para cuentas gratuitas. 1 petición cada 3 segundos es seguro.
const minimaxLimiter = new Bottleneck({ minTime: 3000 });

const safeMinimaxCall = minimaxLimiter.wrap(async (prompt: string) => {
  return await askMinimaxM25(prompt);
});
```

### Ejemplo 8: Logging estructurado de uso de tokens (C4)
**Objetivo**: Auditoría de costos y rendimiento.
**Nivel**: 🟢

```typescript
const response = await minimaxOpenRouterClient.post('/chat/completions', { /* ... */ });
console.log(JSON.stringify({
  event: 'minimax_usage',
  tenant_id: tenantId,
  model: 'm2.5',
  prompt_tokens: response.data.usage?.prompt_tokens,
  completion_tokens: response.data.usage?.completion_tokens,
  total_tokens: response.data.usage?.total_tokens,
  cost: (response.data.usage?.prompt_tokens * 0.0000003) + (response.data.usage?.completion_tokens * 0.0000012)
}));
```

### Ejemplo 9: Control de temperatura para tareas creativas vs. precisas
**Objetivo**: Ajustar la creatividad del modelo según la tarea.
**Nivel**: 🟢

```typescript
// Para tareas precisas (RAG, extracción de datos)
const preciseResponse = await axios.post(..., { temperature: 0.1 });
// Para tareas creativas (brainstorming, generación de texto)
const creativeResponse = await axios.post(..., { temperature: 0.8 });
```

### Ejemplo 10: Integración con OpenRouter para fallback automático
**Objetivo**: Usar OpenRouter como proxy con fallback a otros modelos si MiniMax falla.
**Nivel**: 🟡

```typescript
async function resilientMinimaxCall(prompt: string) {
  try {
    return await askMinimaxM25(prompt);
  } catch (error) {
    if (error.response?.status === 429 || error.response?.status >= 500) {
      console.warn('MiniMax failed, falling back to DeepSeek');
      return await askDeepSeek(prompt);
    }
    throw error;
  }
}
```

### Ejemplo 11: Uso de MiniMax M2.5 para generación de código
**Objetivo**: Aprovechar el rendimiento SOTA en coding para autogenerar agentes.
**Nivel**: 🟡

```typescript
async function generateAgentCode(requirements: string) {
  const prompt = `
    Eres un experto en TypeScript y n8n workflows.
    Genera el código de un agente de IA que cumpla con los siguientes requisitos:
    ${requirements}
    El código debe ser seguro, respetar C1-C6, e incluir manejo de errores.
  `;
  const code = await askMinimaxM25(prompt);
  await fs.writeFile('./generated-agent.ts', code);
}
```

### Ejemplo 12: Evaluación de calidad con Promptfoo (Harness)
**Objetivo**: Integrar evaluaciones automáticas en el pipeline CI/CD.
**Nivel**: 🔴

```yaml
# promptfooconfig.yaml
description: 'MiniMax M2.5 Agent Evaluation'
providers:
  - id: openrouter:minimax/minimax-m2.5
    config:
      apiKey: ${OPENROUTER_API_KEY}
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

### Ejemplo 13: Despliegue automatizado de agentes MiniMax con IaC (Terraform)
**Objetivo**: Gestionar la configuración de agentes como código.
**Nivel**: 🔴

```hcl
# main.tf
resource "n8n_workflow" "minimax_agent" {
  name          = "MiniMax Agent - ${var.tenant_id}"
  workflow_json = templatefile("${path.module}/workflow.json.tpl", {
    tenant_id   = var.tenant_id
    minimax_key = var.minimax_api_key
    group_id    = var.minimax_group_id
    model       = "MiniMax-M2.5"
  })
}

variable "tenant_id" {}
variable "minimax_api_key" { sensitive = true }
variable "minimax_group_id" { sensitive = true }
```
✅ **Deberías ver:** Workflow desplegado automáticamente en n8n.

### Ejemplo 14: Autogeneración de prompts con MiniMax M2.5 (Meta-Prompting)
**Objetivo**: Usar MiniMax para generar dinámicamente los prompts de otros agentes.
**Nivel**: 🔴

```typescript
async function autoGenerateSystemPrompt(tenantVertical: string, tenantData: any) {
  const prompt = `
    Eres un experto en ${tenantVertical}. 
    Genera un system prompt para un agente de IA que debe atender a clientes en un negocio de ${tenantVertical}.
    El negocio tiene las siguientes características: ${JSON.stringify(tenantData)}.
    El prompt debe ser en español, profesional y amigable.
  `;
  const generatedPrompt = await askMinimaxM25(prompt);
  await saveTenantPrompt(tenantId, generatedPrompt);
  return generatedPrompt;
}
```
✅ **Deberías ver:** Un prompt personalizado y guardado en la BD.

### Ejemplo 15: Uso de MiniMax-Text-01 para RAG sobre múltiples documentos
**Objetivo**: Procesar toda la base de conocimiento de un tenant en una sola consulta.
**Nivel**: 🔴

```typescript
async function ragWithHugeContext(tenantId: string, userQuery: string) {
  // 1. Obtener TODOS los documentos del tenant desde Qdrant
  const allDocs = await qdrant.getAllDocuments(tenantId);
  const combinedContext = allDocs.map(doc => doc.text).join('\n---\n');
  
  // 2. Enviar todo el contexto a MiniMax-Text-01 (4M tokens)
  const response = await axios.post(
    'https://openrouter.ai/api/v1/chat/completions',
    {
      model: 'minimax/minimax-text-01',
      messages: [
        { role: 'system', content: `Eres un asistente para el tenant ${tenantId}.` },
        { role: 'user', content: `Contexto:\n${combinedContext}\n\nPregunta: ${userQuery}` }
      ],
      max_tokens: 500,
    },
    { headers: { 'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}` } }
  );
  return response.data.choices[0].message.content;
}
```
✅ **Deberías ver:** Una respuesta basada en toda la base de conocimiento del tenant.

---

## 🐞 15 Errores Comunes y Troubleshooting

| Error Exacto (copiable) | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso | Constraint Afectado |
| :--- | :--- | :--- | :--- | :--- |
| **1.** `Error: 1004 - authentication failed` | API Key o Group ID inválidos en API nativa. | `curl -H "Authorization: Bearer $MINIMAX_API_KEY" https://api.minimax.io/v1/text/models` | 1. Verificar que `MINIMAX_API_KEY` y `MINIMAX_GROUP_ID` estén configurados. 2. Regenerar credenciales en [MiniMax Platform](https://platform.minimaxi.com). | C3 |
| **2.** `"error":{"message":"No endpoints found matching your data policy"}` (OpenRouter) | Configuración de privacidad en OpenRouter. | Revisar `https://openrouter.ai/settings`. | Activar la opción "Enable training and logging (chatroom and API)". Es obligatorio para usar modelos gratuitos. | C6 |
| **3.** `Error: Request failed with status code 402` (OpenRouter) | Créditos insuficientes para un modelo de pago. | Revisar el saldo en OpenRouter. | Añadir créditos a la cuenta o usar modelos disponibles en el plan gratuito. | C6 |
| **4.** `Error: 1002 - rate limit` | Límite de RPM/TPM excedido en API nativa. | Revisar cabeceras `X-RateLimit-Remaining`. | Implementar `bottleneck` con `minTime: 3000` (Ejemplo 7) o solicitar aumento de cuota. | C1 |
| **5.** `Error: 400 Context length exceeded` | El prompt supera el límite de contexto del modelo. | Calcular tokens con `tiktoken`. | 1. Truncar el contexto. 2. Usar MiniMax-Text-01, que soporta 4M tokens. | C2 |
| **6.** `Error: 500 Internal Server Error` | Fallo temporal en la API de MiniMax. | Reintentar tras 60s. | Implementar lógica de fallback a otro modelo (Ejemplo 10). | C6 |
| **7.** `Error: tool_calls is not supported` | Se está usando una versión de API que no soporta function calling. | Verificar el endpoint. | Usar `/v1/text/chatcompletion_v2` en lugar de la versión antigua. | - |
| **8.** `Error: stream terminated unexpectedly` | Problema de red o timeout durante el streaming. | Monitorear la latencia con `ping api.minimax.io`. | 1. Aumentar el timeout del cliente. 2. Implementar reintentos con backoff exponencial. | C6 |
| **9.** `Error: 2045 - rate growth limit` | Aumento repentino en la tasa de solicitudes. | Monitorear el patrón de tráfico. | Implementar un ramp-up gradual en las solicitudes (evitar picos). | C1 |
| **10.** `Error: 2048 - prompt audio too long` | Archivo de audio excede 8 segundos (modelos de voz). | Verificar duración del audio. | Recortar el audio a menos de 8 segundos. | - |
| **11.** `Error: getaddrinfo ENOTFOUND api.minimax.io` | Problema de DNS en el VPS. | `nslookup api.minimax.io`. | 1. Verificar `/etc/resolv.conf` (usar `8.8.8.8`). 2. Reiniciar el servicio de red. | C3 |
| **12.** `Error: 提示次数已用完` (Prompt limit reached) | Límite de 100 prompts por 5 horas en cuentas gratuitas. | Revisar el contador en el dashboard. | 1. Esperar a que se reinicie el contador. 2. Usar múltiples API Keys para distribuir la carga. | C6 |
| **13.** `Error: Invalid model` | Nombre de modelo incorrecto. | `curl https://openrouter.ai/api/v1/models` para ver lista. | Usar IDs exactos: `minimax/minimax-m2.5`, `minimax/minimax-text-01`, etc. | - |
| **14.** `reasoning` es `null` | El modelo no soporta reasoning o no se activó. | Verificar que `reasoning: { enabled: true }` esté en la petición. | Usar modelos que soporten reasoning: M1, M2.5, Text-01. | - |
| **15.** `Error: group_id is required` | Falta el `group_id` en la API nativa de MiniMax. | Verificar la configuración de entorno. | Asegurar que `MINIMAX_GROUP_ID` esté configurado en `.env` y se envíe en la petición. | C3 |

---

## ✅ Validación SDD y Comandos de Verificación

<!-- ai:constraint=C5 -->
### 1. Verificar conectividad con MiniMax API
```bash
curl -X GET "https://api.minimax.io/v1/text/models" \
  -H "Authorization: Bearer $MINIMAX_API_KEY"
```
Debe devolver un JSON con la lista de modelos disponibles.

### 2. Auditar el uso de `tenant_id` en logs (C4)
```bash
grep -c '"tenant_id":"' /var/log/mantis-ai.log
```
El número de líneas debe coincidir con las peticiones realizadas.

### 3. Chequeo de secretos (C3)
```bash
grep -r "eyJ" /opt/mantis --exclude-dir=node_modules
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

### Pipeline de Integración Continua para Agentes MiniMax

El ecosistema MANTIS adopta un enfoque **Specification-Driven Development (SDD)** para la autogeneración de agentes:

1. **Especificación primero:** Cada agente basado en MiniMax se define mediante un archivo `agent-spec.yaml` que describe su propósito, modelo, herramientas y comportamiento.
2. **Generación automática:** Una IA (como MiniMax M2.5) lee la especificación y genera:
   - El código del agente (TypeScript/Python) con las funciones de tool calling.
   - El workflow de n8n correspondiente en formato JSON.
3. **Validación en CI:** El código generado se somete a un pipeline que incluye:
   - Linting y formateo (`eslint`, `prettier`).
   - Pruebas unitarias de las funciones de tool calling.
   - Evaluación de calidad con **Promptfoo** (métricas de relevancia, fidelidad, etc.).
4. **Infraestructura como Código (IaC):** La configuración del agente (incluyendo el workflow de n8n) se gestiona con **Terraform**. Esto garantiza que el despliegue sea reproducible y auditable.
5. **Despliegue Continuo (CD):** Si todas las pruebas pasan, el workflow se despliega automáticamente en la instancia de n8n de producción mediante su API.

### Estrategia de Evaluación (Harness) con Promptfoo

Promptfoo se integra en el pipeline de CI/CD para evaluar automáticamente la calidad de las respuestas de MiniMax. Ejemplo de configuración:

```yaml
# promptfooconfig.yaml
description: 'MiniMax M2.5 RAG Agent Evaluation'
providers:
  - id: openrouter:minimax/minimax-m2.5
    config:
      apiKey: ${OPENROUTER_API_KEY}
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
  description = "ID del tenant para el agente MiniMax"
  type        = string
}

variable "minimax_api_key" {
  description = "API Key de MiniMax"
  type        = string
  sensitive   = true
}

variable "minimax_group_id" {
  description = "Group ID de MiniMax"
  type        = string
  sensitive   = true
}

# main.tf
resource "local_file" "agent_config" {
  content = templatefile("${path.module}/agent-spec.yaml.tpl", {
    tenant_id = var.tenant_id
    model     = "MiniMax-M2.5"
  })
  filename = "${path.module}/generated/${var.tenant_id}.yaml"
}

resource "n8n_workflow" "minimax_agent" {
  name          = "MiniMax Agent - ${var.tenant_id}"
  workflow_json = file("${path.module}/workflows/minimax-agent.json")
}
```

### Autogeneración de Agentes con MiniMax M2.5

El propio MiniMax M2.5 se utiliza para autogenerar componentes del ecosistema:

1. **Generación de especificaciones:** A partir de una descripción en lenguaje natural del negocio, M2.5 genera el archivo `agent-spec.yaml`.
2. **Generación de código de herramientas:** M2.5 puede leer la documentación de una API (en formato OpenAPI) y generar el código TypeScript necesario para integrarla como una herramienta.
3. **Generación de casos de prueba:** M2.5 analiza el historial de conversaciones y genera casos de prueba para evaluar la robustez del agente.

Este enfoque permite que el ecosistema MANTIS evolucione rápidamente, con agentes que se adaptan a las necesidades específicas de cada tenant sin intervención manual extensa.

### Hardening de Seguridad para Agentes MiniMax

Para cumplir con los requisitos de hardening, se aplican las siguientes medidas:

1. **Cifrado de secretos en tránsito y reposo:** Las API Keys se almacenan en HashiCorp Vault o en variables de entorno cifradas con `sops`.
2. **Rate limiting a nivel de aplicación:** Se usa `bottleneck` para respetar los límites de MiniMax y evitar bloqueos.
3. **Validación de entradas:** Se sanitizan los prompts del usuario para prevenir inyecciones.
4. **Logging de auditoría (C4):** Cada llamada a MiniMax se registra con `tenant_id` y uso de tokens.
5. **Monitoreo y alertas:** Se configura Prometheus + Grafana para monitorear latencia, tasa de errores y costos.

---

## 🔗 Referencias Cruzadas y Glosario

- [[openrouter-api-integration.md]] - Patrón general para consumir modelos vía OpenRouter.
- [[whatsapp-rag-openrouter.md]] - Orquestación de agentes de WhatsApp con RAG.
- [[deepseek-integration.md]] - Patrones de integración específicos para DeepSeek.
- [[gemini-integration.md]] - Patrones de integración para modelos Gemini.
- [[gpt-integration.md]] - Patrones de integración para modelos GPT.
- [[environment-variable-management.md]] - Gestión segura de `MINIMAX_API_KEY`.

**Glosario:**
- **RAG:** Retrieval-Augmented Generation.
- **MoE:** Mixture of Experts, arquitectura que activa solo un subconjunto de parámetros para cada tarea.
- **Tool Calling (Function Calling):** Capacidad del modelo para solicitar la ejecución de una función externa.
- **Lightning Attention:** Mecanismo de atención eficiente usado por MiniMax para manejar contextos largos.
- **SDD:** Specification-Driven Development.
- **IaC:** Infrastructure as Code (Infraestructura como Código).
- **Promptfoo:** Herramienta de evaluación y testing para LLMs.

FIN DEL ARCHIVO
<!-- ai:file-end marker - do not remove -->
Versión 1.0.0 - 2026-04-11 - Mantis-AgenticDev

