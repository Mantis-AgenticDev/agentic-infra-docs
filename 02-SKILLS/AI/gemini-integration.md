---
title: "gemini-integration.md"
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

**Objetivo en 3 minutos:** Realizar la primera llamada a un modelo Gemini (Flash-Lite) a través de OpenRouter o la API nativa de Google.

1. **Requisito previo:** Obtener una API Key de [Google AI Studio](https://aistudio.google.com/) o de [OpenRouter.ai](https://openrouter.ai).
2. **Configurar variable de entorno (C3):**
   ```bash
   echo "GEMINI_API_KEY=AIza..." >> .env
   # o para OpenRouter:
   echo "OPENROUTER_API_KEY=sk-or-v1-..." >> .env
   ```
3. **Probar con `curl` el modelo gratuito Gemini 2.5 Flash-Lite (vía OpenRouter):**
   ```bash
   curl https://openrouter.ai/api/v1/chat/completions \
     -H "Authorization: Bearer $OPENROUTER_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "model": "google/gemini-2.5-flash-lite",
       "messages": [{"role": "user", "content": "¿Cuál es la capital de Francia?"}]
     }'
   ```
✅ **Deberías ver:** Un JSON con `choices[0].message.content` y la respuesta "París".
❌ **Si ves:** `{"error":{"message":"No endpoints found matching your data policy"}}` → Ve a Troubleshooting #2.

⚠️ **Advertencia para Junior:** Los modelos Gemini de Google incluyen un **generoso free tier** en Google AI Studio (hasta 60 RPM). Sin embargo, respeta siempre los límites de contexto (1M tokens para Flash-Lite, 2M para Pro) y nunca hardcodees las API Keys en tu código (C3).

---

## 🎯 Propósito y Alcance

Este skill documenta los patrones de integración para consumir los modelos de la familia **Gemini de Google** en el ecosistema MANTIS, tanto a través de OpenRouter como de la API nativa de Google AI. Gemini destaca por su **contexto ultra-largo (hasta 2M tokens)**, su **multimodalidad nativa (texto, imágenes, audio)** y su excelente **relación costo/rendimiento**.

**Cubre:**
- Los principales modelos Gemini disponibles: **2.5 Pro**, **2.5 Flash**, **2.5 Flash-Lite**, y los previews de **Gemini 3**.
- Estrategias de implementación para **tool calling (Function Calling)**, **contexto masivo** y **multimodalidad (imagen + texto)**.
- Integración con **OpenRouter** (para fallback unificado) y con la **API nativa de Google AI Studio** (para mayor control y free tier).
- **Normas CI/CD y SDD** para el despliegue continuo de agentes basados en Gemini.
- **Estrategias de evaluación (harness)** con DeepEval y Promptfoo para validar la calidad de las respuestas.
- **Patrones de autogeneración** de código para agentes con Gemini.

**No cubre:**
- Modelos de embedding de Gemini (como `text-embedding-004`), que se tratan en el skill de ingesta RAG.
- La lógica de negocio de los agentes (eso reside en los workflows de n8n).
- La gestión de prompts por vertical (ubicada en `05-CONFIGURATIONS/prompts/`).

### Modelos Gemini Objetivo (2026)

Basado en la disponibilidad en OpenRouter y Google AI Studio, nos enfocaremos en:

| Modelo | ID (OpenRouter / Google) | Contexto | Características Clave | Precio (input/output por 1M tokens) |
| :--- | :--- | :--- | :--- | :--- |
| **Gemini 2.5 Flash-Lite** | `google/gemini-2.5-flash-lite` | 1M | **Mejor relación costo/rendimiento**, gratuito en OpenRouter, baja latencia. | $0.10 / $0.40 |
| **Gemini 2.5 Flash** | `google/gemini-2.5-flash` | 1M | **Multimodal nativo**, tool calling, balance velocidad/precisión. | $0.30 / $2.50 |
| **Gemini 2.5 Pro** | `google/gemini-2.5-pro` | 2M | **Máxima capacidad de razonamiento**, contexto ultra-largo, ideal para tareas complejas. | $1.25 / $10.00 |
| **Gemini 3 Pro Preview** | `google/gemini-3-pro-preview` | 200K+ | Modelo de última generación, mejor rendimiento en benchmarks. | $2.00 / $12.00 |

*Precios según Google AI Studio, Marzo 2026.*

---

## 📐 Fundamentos (De 0 a Intermedio)

### El Ecosistema Gemini
Gemini es la familia de modelos de lenguaje de gran escala (LLM) desarrollada por Google DeepMind. A diferencia de otros modelos, Gemini está diseñado desde cero para ser **multimodal**, pudiendo procesar texto, imágenes, audio y video en una sola arquitectura unificada.

**1. Contexto Masivo (1M-2M tokens):**
Los modelos Gemini 2.5 soportan hasta 2 millones de tokens de contexto. Esto es aproximadamente 1.5 millones de palabras, suficiente para analizar documentos extensos (manuales completos, historiales clínicos, bases de conocimiento enteras) en una sola consulta.

**2. Multimodalidad Nativa:**
Gemini puede procesar imágenes directamente, sin necesidad de un modelo de visión externo. La imagen se tokeniza y se inyecta en el mismo flujo de atención que el texto. Esto es ideal para agentes que deben analizar facturas escaneadas, menús con fotos, o diagramas técnicos.

**3. Tool Calling Robusto:**
Las versiones recientes de Gemini han mejorado drásticamente la fiabilidad del `function calling` (ahora llamado "tool calling"). El modelo es capaz de invocar funciones externas de manera precisa, respetando los esquemas JSON definidos.

**4. Context Caching:**
Google AI ofrece "Context Caching", que permite almacenar en caché los tokens de entrada de prompts largos y recurrentes. Esto reduce la latencia y el costo hasta en un 75% para prompts repetitivos.

### Integración con MANTIS
Al igual que con otros skills de IA, la integración se basa en inyectar el contexto RAG y el `tenant_id` en las llamadas a la API. La principal diferencia radica en el **manejo de la multimodalidad** y la **optimización para contexto ultra-largo** mediante Context Caching.

---

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

### Aplicación de Constraints C1 y C2

- **C1 (RAM ≤ 4GB):** Al usar modelos con contexto masivo (2M tokens), la respuesta puede ser muy larga (máx 8K tokens). **No acumules la respuesta completa en RAM.** Siempre usa `streaming` para procesar el flujo de tokens y liberar memoria.
- **C2 (vCPU):** El costo de CPU es bajo (I/O de red). Para tareas de alta frecuencia, Gemini 2.5 Flash-Lite ofrece la mejor latencia (800-1200 ms) con un costo ínfimo.

### Configuración de Cliente HTTP Optimizado (API Nativa de Google)

```typescript
import axios from 'axios';
import http from 'http';

// Agente HTTP con keepAlive para reutilizar conexiones (C1)
const httpAgent = new http.Agent({ keepAlive: true, maxSockets: 3 });

export const geminiClient = axios.create({
  baseURL: 'https://generativelanguage.googleapis.com/v1beta',
  timeout: 180000, // Timeout de 3 minutos para contexto largo
  headers: {
    'Content-Type': 'application/json',
  },
  httpAgent
});
```

### Configuración vía OpenRouter (Alternativa)

```typescript
export const geminiOpenRouterClient = axios.create({
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
import { geminiClient } from './gemini-client';

export async function generateMultimodalResponse(
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

  const parts: any[] = [{ text: `${systemPrompt}\n\nPregunta: ${userQuery}` }];
  
  if (imageBase64) {
    parts.push({
      inline_data: {
        mime_type: 'image/jpeg',
        data: imageBase64
      }
    });
  }

  try {
    const response = await geminiClient.post(
      `/models/gemini-2.5-flash:generateContent?key=${process.env.GEMINI_API_KEY}`,
      {
        contents: [{ parts }],
        generationConfig: { temperature: 0.1 },
        safetySettings: [
          { category: 'HARM_CATEGORY_HARASSMENT', threshold: 'BLOCK_MEDIUM_AND_ABOVE' }
        ]
      }
    );

    // Registrar tenant_id para auditoría (C4)
    console.log(JSON.stringify({
      event: 'gemini_call',
      tenant_id: tenantId,
      model: 'gemini-2.5-flash',
      has_image: !!imageBase64
    }));

    return response.data.candidates[0].content.parts[0].text;
  } catch (error) {
    console.error(`Gemini error for tenant ${tenantId}:`, error);
    throw error;
  }
}
```

### Integración con n8n: Workflow de Fallback Automático

En el ecosistema MANTIS, es crítico que los agentes sean resilientes. n8n permite crear workflows que automáticamente cambian a otro modelo (ej: GPT-4o) si Gemini falla.

**Patrón de fallback en n8n (simplificado):**
1. Nodo "AI Agent" con Gemini como modelo primario.
2. Si el nodo falla (error 429, 500), la salida "On Error" se activa.
3. Un nodo "Router" incrementa un contador de intentos (`fail_count`).
4. El flujo se redirige a un nodo "AI Agent" con un modelo de respaldo (ej: DeepSeek).
5. Si todos los modelos fallan, se envía una notificación a Telegram.

---

## 🛠️ 15 Ejemplos de Configuración (Copy-Paste Validables)

### Ejemplo 1: Llamada básica a Gemini 2.5 Flash-Lite (vía OpenRouter)
**Objetivo**: Probar el modelo gratuito con una pregunta simple.
**Nivel**: 🟢

```typescript
import axios from 'axios';

async function askGeminiFree(prompt: string) {
  const response = await axios.post(
    'https://openrouter.ai/api/v1/chat/completions',
    {
      model: 'google/gemini-2.5-flash-lite',
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

### Ejemplo 2: Llamada a la API nativa de Google (Google AI Studio)
**Objetivo**: Usar directamente la API de Google para acceder al free tier.
**Nivel**: 🟢

```typescript
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);

async function askGeminiNative(prompt: string) {
  const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });
  const result = await model.generateContent(prompt);
  console.log(result.response.text());
}
```
✅ **Deberías ver:** La respuesta del modelo.
❌ **Si ves:** `Error: 403 Forbidden` → Verifica que la API Key esté habilitada en Google AI Studio.

### Ejemplo 3: Procesamiento multimodal (imagen + texto)
**Objetivo**: Analizar una imagen y responder a una pregunta sobre ella.
**Nivel**: 🟡

```typescript
import fs from 'fs/promises';
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);

async function analyzeImageWithGemini(imagePath: string, question: string) {
  const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });
  const imageBuffer = await fs.readFile(imagePath);
  const base64Image = imageBuffer.toString('base64');

  const result = await model.generateContent([
    question,
    {
      inlineData: {
        mimeType: 'image/jpeg',
        data: base64Image,
      },
    },
  ]);
  console.log(result.response.text());
}
```
✅ **Deberías ver:** Una respuesta basada en el contenido de la imagen.
❌ **Si ves:** `Error: 413 Request Entity Too Large` → La imagen es demasiado grande. Redúcela antes de enviar.

### Ejemplo 4: Tool Calling (Function Calling) con Gemini
**Objetivo**: Permitir que el modelo "llame" a una función para obtener información externa.
**Nivel**: 🟡

```typescript
import { GoogleGenerativeAI, FunctionDeclarationSchemaType } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);

const weatherTool = {
  name: 'get_current_weather',
  description: 'Obtiene el clima actual en una ubicación',
  parameters: {
    type: FunctionDeclarationSchemaType.OBJECT,
    properties: {
      location: {
        type: FunctionDeclarationSchemaType.STRING,
        description: 'La ciudad, ej: "Madrid"',
      },
    },
    required: ['location'],
  },
};

async function askWithTool(prompt: string) {
  const model = genAI.getGenerativeModel({
    model: 'gemini-2.5-pro',
    tools: [{ functionDeclarations: [weatherTool] }],
  });

  const chat = model.startChat();
  const result = await chat.sendMessage(prompt);
  const call = result.response.functionCalls()?.[0];

  if (call) {
    console.log('El modelo quiere llamar a la función:', call.name, call.args);
    // Aquí tu código ejecutaría la función y devolvería el resultado al modelo.
  } else {
    console.log(result.response.text());
  }
}
```
✅ **Deberías ver:** Un objeto `functionCall` si el prompt es sobre el clima.
❌ **Si ves:** `Error: Function calling is not supported` → Asegúrate de usar Gemini 2.5 Pro o Flash.

### Ejemplo 5: Procesamiento de contexto ultra-largo (1M tokens)
**Objetivo**: Enviar un documento muy extenso para su análisis.
**Nivel**: 🔴

```typescript
import { GoogleGenerativeAI } from '@google/generative-ai';
import fs from 'fs/promises';

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);

async function analyzeLargeDocument(filePath: string, question: string) {
  const model = genAI.getGenerativeModel({ model: 'gemini-2.5-pro' });
  const documentText = await fs.readFile(filePath, 'utf-8');
  // Gemini 2.5 Pro soporta hasta 2M de tokens (~1.5M palabras)

  const chat = model.startChat();
  await chat.sendMessage(`Documento:\n${documentText}`);
  const result = await chat.sendMessage(question);
  console.log(result.response.text());
}
```
✅ **Deberías ver:** Una respuesta basada en el contenido del documento.
❌ **Si ves:** `Error: 400 Request payload size exceeds the limit` → Ve a Troubleshooting #5.

### Ejemplo 6: Context Caching para prompts recurrentes
**Objetivo**: Reducir latencia y costo para prompts que se repiten (ej: system prompt de un agente).
**Nivel**: 🟡

```typescript
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);

async function useCachedContext(systemPrompt: string, userQuery: string) {
  // 1. Crear el contenido a cachear
  const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });
  const baseContent = [{ role: 'user', parts: [{ text: systemPrompt }] }];

  // 2. Crear el caché (válido por 1 hora)
  const cacheResult = await model.cacheContent({ contents: baseContent });
  const cacheName = cacheResult.response.name;

  // 3. Usar el caché en consultas posteriores
  const modelWithCache = genAI.getGenerativeModelFromCachedContent(cacheName);
  const result = await modelWithCache.generateContent(userQuery);
  console.log(result.response.text());
}
```
✅ **Deberías ver:** La respuesta, con un tiempo de respuesta reducido (~50%).
❌ **Si ves:** `Error: Cached content not found` → El caché expiró. Vuelve a crearlo.

### Ejemplo 7: Streaming con Gemini (Node.js)
**Objetivo**: Procesar la respuesta del modelo token por token para una experiencia más fluida.
**Nivel**: 🟡

```typescript
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);

async function streamGeminiResponse(prompt: string) {
  const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });
  const result = await model.generateContentStream(prompt);

  for await (const chunk of result.stream) {
    const chunkText = chunk.text();
    process.stdout.write(chunkText);
  }
}
```
✅ **Deberías ver:** El texto de la respuesta apareciendo progresivamente.
❌ **Si ves:** `Error: stream terminated unexpectedly` → Ve a Troubleshooting #8.

### Ejemplo 8: Rate Limiting específico para Gemini (Bottleneck)
**Objetivo**: Evitar errores `429` respetando los límites de la API nativa (60 RPM en free tier).
**Nivel**: 🟡

```typescript
import Bottleneck from 'bottleneck';
import { GoogleGenerativeAI } from '@google/generative-ai';

// 1 petición cada 1 segundo = 60 RPM (límite seguro para free tier)
const geminiLimiter = new Bottleneck({ minTime: 1000 });

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);
const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });

const safeGeminiCall = geminiLimiter.wrap(async (prompt: string) => {
  const result = await model.generateContent(prompt);
  return result.response.text();
});
```
✅ **Deberías ver:** Las peticiones se ejecutan espaciadas, sin errores `429`.

### Ejemplo 9: Logging estructurado de uso de tokens (C4)
**Objetivo**: Auditoría de costos y rendimiento.
**Nivel**: 🟢

```typescript
const result = await model.generateContent(prompt);
const response = result.response;
console.log(JSON.stringify({
  event: 'gemini_usage',
  tenant_id: tenantId,
  model: 'gemini-2.5-flash',
  prompt_tokens: response.usageMetadata?.promptTokenCount,
  completion_tokens: response.usageMetadata?.candidatesTokenCount,
  total_tokens: response.usageMetadata?.totalTokenCount,
}));
```
✅ **Deberías ver:** Un log JSON con el conteo de tokens.

### Ejemplo 10: Control de temperatura y parámetros de generación
**Objetivo**: Ajustar la creatividad del modelo según la tarea.
**Nivel**: 🟢

```typescript
const model = genAI.getGenerativeModel({
  model: 'gemini-2.5-pro',
  generationConfig: {
    temperature: 0.1,        // Baja para tareas precisas (RAG)
    topP: 0.95,
    topK: 40,
    maxOutputTokens: 2048,
    stopSequences: ['\n\n'],
  },
});
```

### Ejemplo 11: Integración con OpenRouter para fallback automático
**Objetivo**: Usar OpenRouter como proxy con fallback a otros modelos si Gemini falla.
**Nivel**: 🟡

```typescript
async function resilientGeminiCall(prompt: string) {
  try {
    // Intento primario: Gemini vía OpenRouter
    return await askGeminiFree(prompt);
  } catch (error) {
    if (error.response?.status === 429 || error.response?.status >= 500) {
      console.warn('Gemini falló, usando fallback a DeepSeek');
      // Fallback a DeepSeek (ver deepseek-integration.md)
      return await askDeepSeek(prompt);
    }
    throw error;
  }
}
```

### Ejemplo 12: Uso de Grounding con Google Search
**Objetivo**: Permitir que Gemini acceda a información actualizada de la web.
**Nivel**: 🔴

```typescript
const model = genAI.getGenerativeModel({
  model: 'gemini-2.5-pro',
  tools: [{ googleSearch: {} }], // Activa Grounding
});

const result = await model.generateContent('¿Quién ganó el Oscar a mejor película en 2026?');
console.log(result.response.text());
// La respuesta incluirá enlaces a las fuentes.
```
✅ **Deberías ver:** Una respuesta con información actualizada y enlaces.
❌ **Si ves:** `Error: Google Search is not enabled` → Actívalo en Google AI Studio (requiere facturación).

### Ejemplo 13: Evaluación de calidad con DeepEval (Harness)
**Objetivo**: Integrar evaluaciones automáticas de la calidad de las respuestas de Gemini en el pipeline CI/CD.
**Nivel**: 🔴

```python
# test_gemini_responses.py
import pytest
from deepeval import assert_test
from deepeval.test_case import LLMTestCase
from deepeval.metrics import AnswerRelevancyMetric, FaithfulnessMetric

def test_gemini_response_relevancy():
    # Simular una respuesta de Gemini
    test_case = LLMTestCase(
        input="¿Cuáles son los síntomas de la caries dental?",
        actual_output="Los síntomas incluyen dolor de muelas, sensibilidad...",
        retrieval_context=["La caries dental es una enfermedad infecciosa..."]
    )
    assert_test(test_case, [AnswerRelevancyMetric(), FaithfulnessMetric()])
```
✅ **Deberías ver:** Tests pasando en el pipeline CI/CD.
❌ **Si ves:** Tests fallando → Ve a Troubleshooting #13.

### Ejemplo 14: Despliegue automatizado de agentes Gemini con n8n + GitHub Actions
**Objetivo**: Automatizar el despliegue de workflows de n8n que usan Gemini mediante CI/CD.
**Nivel**: 🔴

```yaml
# .github/workflows/deploy-n8n-agent.yml
name: Deploy Gemini Agent Workflow
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Validate workflow JSON
        run: npx n8n-workflow-validator ./workflows/gemini-agent.json
      - name: Deploy to n8n instance
        run: |
          curl -X POST https://n8n.mantis.local/api/v1/workflows \
            -H "X-N8N-API-KEY: ${{ secrets.N8N_API_KEY }}" \
            -d @workflows/gemini-agent.json
```
✅ **Deberías ver:** Workflow desplegado automáticamente en n8n.

### Ejemplo 15: Autogeneración de prompts con Gemini para agentes
**Objetivo**: Usar Gemini para generar dinámicamente los prompts de otros agentes (meta-prompting).
**Nivel**: 🔴

```typescript
async function autoGenerateSystemPrompt(tenantVertical: string, tenantData: any) {
  const prompt = `
    Eres un experto en ${tenantVertical}. 
    Genera un system prompt para un agente de IA que debe atender a clientes en un negocio de ${tenantVertical}.
    El negocio tiene las siguientes características: ${JSON.stringify(tenantData)}.
    El prompt debe ser en español, profesional y amigable.
  `;
  const generatedPrompt = await askGeminiNative(prompt);
  // Guardar el prompt generado en la base de datos del tenant
  await saveTenantPrompt(tenantId, generatedPrompt);
  return generatedPrompt;
}
```
✅ **Deberías ver:** Un prompt personalizado y guardado en la BD.

---

## 🐞 15 Errores Comunes y Troubleshooting

| Error Exacto (copiable) | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso | Constraint Afectado |
| :--- | :--- | :--- | :--- | :--- |
| **1.** `Error: 403 Forbidden` | API Key inválida o proyecto no habilitado. | `curl -H "Content-Type: application/json" -d '{}' "https://generativelanguage.googleapis.com/v1beta/models?key=$GEMINI_API_KEY"` | 1. Verificar que la key esté activa en [Google AI Studio](https://aistudio.google.com/app/apikey). 2. Asegurar que el proyecto tenga la API de Gemini habilitada. | C3 |
| **2.** `"error":{"message":"No endpoints found matching your data policy"}` (OpenRouter) | Configuración de privacidad en OpenRouter. | Revisar `https://openrouter.ai/settings`. | Activar la opción "Enable training and logging (chatroom and API)". Es obligatorio para usar modelos gratuitos. | C6 |
| **3.** `Error: Request failed with status code 402` (OpenRouter) | Intento de usar un modelo de pago sin créditos. | Verificar el ID del modelo. | Asegurarse de usar modelos disponibles en el plan gratuito (ej: `google/gemini-2.5-flash-lite`). | C6 |
| **4.** `Error: 429 Too Many Requests` / `Resource has been exhausted` | Límite de tasa de Google AI Studio excedido (60 RPM en free tier). | Revisar el dashboard de Google AI Studio. | 1. Implementar `bottleneck` con `minTime: 1000` (Ejemplo 8). 2. Considerar cambiar a un plan de pago para aumentar el límite. | C1 |
| **5.** `Error: 400 Request payload size exceeds the limit` | El prompt supera el límite de contexto del modelo (1M-2M tokens). | Calcular tokens con `countTokens()` del SDK de Gemini. | 1. Truncar el contexto RAG a ~800K tokens. 2. Usar Gemini 2.5 Pro, que soporta hasta 2M tokens. | C2 |
| **6.** `Error: 500 Internal Server Error` | Fallo temporal en la API de Google. | Verificar `https://status.cloud.google.com/`. | Implementar lógica de fallback a otro modelo (Ejemplo 11) con reintentos. | C6 |
| **7.** `Error: The model does not support function calling` | Se está usando un modelo que no soporta tools (ej: versiones antiguas). | Verificar la documentación del modelo. | Usar `gemini-2.5-pro` o `gemini-2.5-flash`, que sí soportan function calling. | - |
| **8.** `Error: stream terminated unexpectedly` | Problema de red o timeout durante el streaming. | Monitorear la latencia de red con `ping generativelanguage.googleapis.com`. | 1. Aumentar el timeout del cliente HTTP. 2. Implementar reintentos con backoff exponencial. | C6 |
| **9.** `Error: 413 Request Entity Too Large` (al enviar imágenes) | La imagen base64 supera el límite de la API. | Verificar el tamaño de la imagen (`ls -lh`). | Redimensionar la imagen a un máximo de 1024x1024 antes de enviarla. | C1 |
| **10.** `Error: Safety settings blocked the response` | El contenido generado activó los filtros de seguridad de Gemini. | Revisar `response.candidates[0].finishReason`. | 1. Ajustar los `safetySettings` en la petición. 2. Si es un falso positivo, reportarlo a Google. | - |
| **11.** `Error: Cached content not found` | El caché de contexto expiró (TTL máximo 24h). | Verificar el tiempo de creación del caché. | Volver a crear el caché (Ejemplo 6) antes de usarlo. | C5 |
| **12.** `Error: getaddrinfo ENOTFOUND generativelanguage.googleapis.com` | Problema de DNS en el VPS. | `nslookup generativelanguage.googleapis.com`. | 1. Verificar `/etc/resolv.conf` (usar `8.8.8.8`). 2. Reiniciar el servicio de red del VPS. | C3 |
| **13.** Tests de evaluación (DeepEval) fallando en CI/CD | Degradación en la calidad de las respuestas de Gemini. | Revisar los logs de las ejecuciones de prueba. | 1. Ajustar el prompt o la temperatura del modelo. 2. Si la degradación es significativa, considerar un fallback a otro modelo. | C5 |
| **14.** `Error: Quota exceeded for project` | Se ha superado la cuota diaria de tokens en el free tier. | Revisar el dashboard de Google Cloud. | 1. Esperar al siguiente día. 2. Actualizar a un plan de pago para eliminar la cuota diaria. | C6 |
| **15.** `Error: Invalid JSON payload` | El esquema de tool calling no es válido. | Validar el JSON con una herramienta como `ajv`. | Asegurarse de que el esquema de parámetros siga el estándar OpenAPI/JSON Schema. | - |

---

## ✅ Validación SDD y Comandos de Verificación

<!-- ai:constraint=C5 -->
### 1. Verificar conectividad con Gemini API
```bash
curl -X GET "https://generativelanguage.googleapis.com/v1beta/models?key=$GEMINI_API_KEY"
```
Debe devolver un JSON con la lista de modelos disponibles.

### 2. Auditar el uso de `tenant_id` en logs (C4)
```bash
grep -c '"tenant_id":"' /var/log/mantis-ai.log
```
El número de líneas debe coincidir con las peticiones realizadas.

### 3. Chequeo de secretos (C3)
```bash
grep -r "AIza" /opt/mantis --exclude-dir=node_modules
```
No debe haber keys hardcodeadas fuera de los archivos `.env`.

### 4. Ejecutar evaluación automática (Harness) en CI/CD
```bash
# En el pipeline de CI/CD (GitHub Actions)
npm run test:gemini-evals
```
Debe ejecutar las pruebas definidas con DeepEval/Promptfoo (Ejemplo 13).

### 5. Validar el despliegue automático del workflow
```bash
# Verificar que el workflow se ha desplegado correctamente en n8n
curl -X GET "https://n8n.mantis.local/api/v1/workflows" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" | jq '.data[] | select(.name | contains("Gemini"))'
```

### 6. Backup de la configuración de modelos (C5)
```bash
sha256sum .env > .env.sha256
rsync -avz .env.sha256 backup@server:/backup/configs/
```

---

## 🚀 CI/CD y Autogeneración con IA (Normas MANTIS)

### Pipeline de Integración Continua para Agentes Gemini

El ecosistema MANTIS adopta un enfoque **Specification-Driven Development (SDD)** para la autogeneración de agentes. Esto significa que:

1. **Especificación primero:** Cada agente basado en Gemini se define primero mediante un archivo de especificación (`agent-spec.yaml`) que describe su propósito, modelo, herramientas y comportamiento esperado.
2. **Generación automática:** Una IA (como Gemini 2.5 Pro) lee la especificación y genera el código del agente (TypeScript/Python) y el workflow de n8n correspondiente.
3. **Validación en CI:** El código generado se somete a un pipeline de CI que incluye:
   - **Linting y formateo** (`eslint`, `prettier`).
   - **Pruebas unitarias** de las funciones de tool calling.
   - **Evaluación de calidad** con DeepEval/Promptfoo (métricas de relevancia, fidelidad, etc.).
   - **Pruebas de integración** con un entorno de staging.
4. **Despliegue continuo (CD):** Si todas las pruebas pasan, el workflow se despliega automáticamente en la instancia de n8n de producción mediante la API de n8n (Ejemplo 14).

### Estrategia de Evaluación (Harness)

Para asegurar la calidad de los agentes Gemini, MANTIS implementa un **harness de evaluación** que se ejecuta en cada commit. Las métricas clave incluyen:

- **Answer Relevancy:** ¿La respuesta es relevante para la pregunta?
- **Faithfulness:** ¿La respuesta se basa exclusivamente en el contexto RAG proporcionado?
- **Tool Correctness:** ¿El modelo invoca las herramientas correctas con los argumentos adecuados?

Estas evaluaciones se integran en el pipeline de CI/CD utilizando **DeepEval** (para Python) o **Promptfoo** (para TypeScript).

### Autogeneración de Agentes con Gemini

El propio Gemini puede usarse para autogenerar componentes del ecosistema:

- **Generación de prompts:** Gemini 2.5 Pro puede generar prompts de sistema personalizados para cada tenant, basándose en su vertical y datos específicos (Ejemplo 15).
- **Generación de código de tool calling:** A partir de una descripción en lenguaje natural de una API, Gemini puede generar el código TypeScript necesario para integrarla como una herramienta.
- **Generación de casos de prueba:** Gemini puede analizar el historial de conversaciones y generar casos de prueba para evaluar la robustez del agente.

---

## 🔗 Referencias Cruzadas y Glosario

- [[openrouter-api-integration.md]] - Patrón general para consumir modelos vía OpenRouter.
- [[whatsapp-rag-openrouter.md]] - Orquestación de agentes de WhatsApp con RAG.
- [[deepseek-integration.md]] - Patrones de integración específicos para DeepSeek.
- [[llama-integration.md]] - Patrones de integración para modelos Llama.
- [[environment-variable-management.md]] - Gestión segura de `GEMINI_API_KEY`.

**Glosario:**
- **RAG:** Retrieval-Augmented Generation.
- **Tool Calling (Function Calling):** Capacidad del modelo para solicitar la ejecución de una función externa.
- **Context Caching:** Mecanismo de Google AI para cachear tokens de entrada y reducir costos.
- **Multimodalidad:** Capacidad del modelo para procesar múltiples tipos de datos (texto, imagen, audio).
- **SDD:** Specification-Driven Development. Metodología de desarrollo donde la especificación es el artefacto principal.
- **Harness:** Conjunto de pruebas y métricas para evaluar la calidad de un modelo de IA.

FIN DEL ARCHIVO
<!-- ai:file-end marker - do not remove -->
Versión 1.0.0 - 2026-04-11 - Mantis-AgenticDev

