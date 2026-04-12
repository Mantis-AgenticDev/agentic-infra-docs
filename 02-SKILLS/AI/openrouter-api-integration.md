---
title: "openrouter-api-integration.md"
category: "Skill"
domain: ["ai", "generico"]
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
priority: "CRÍTICA"
version: "2.0.0"
last_updated: "2026-04-11"
ai_optimized: true
tags:
  - sdd/skill/ai
  - lang/es
related_files:
  - "01-RULES/03-SECURITY-RULES.md"
  - "02-SKILLS/COMUNICACION/whatsapp-rag-openrouter.md"
  - "02-SKILLS/AI/deepseek-integration.md"
  - "02-SKILLS/AI/qwen-integration.md"
  - "02-SKILLS/AI/llama-integration.md"
  - "05-CONFIGURATIONS/environment-variable-management.md"
---

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

**Objetivo en 3 minutos:** Realizar tu primera llamada a un modelo de IA gratuito a través de OpenRouter.

1.  **Requisito previo:** Tener una cuenta en [OpenRouter.ai](https://openrouter.ai) y una API Key.
2.  **Configurar variable de entorno (C3):**
    ```bash
    echo "OPENROUTER_API_KEY=sk-or-v1-..." >> .env
    ```
3.  **Probar con `curl` un modelo gratuito:**
    ```bash
    curl https://openrouter.ai/api/v1/chat/completions \
      -H "Authorization: Bearer $OPENROUTER_API_KEY" \
      -H "Content-Type: application/json" \
      -d '{
        "model": "qwen/qwen3.6-plus-preview:free",
        "messages": [{"role": "user", "content": "¿Qué es un RAG?"}]
      }'
    ```
✅ **Deberías ver:** Un JSON con `choices[0].message.content` y la respuesta del modelo.
❌ **Si ves:** `{"error":{"message":"No endpoints found..."}}` → Ve a Troubleshooting #2.

⚠️ **Advertencia para Junior:** Nunca hardcodees la API Key en tu código. Usa siempre variables de entorno (C3). Respeta los límites de `rate limit` de los modelos gratuitos para evitar el error `429`.

---

## 🎯 Propósito y Alcance

Este skill documenta el patrón de integración unificado para consumir múltiples Modelos de Lenguaje de Gran Escala (LLMs) a través del gateway de **OpenRouter**. Actúa como la capa de abstracción fundamental para la inferencia de IA en el ecosistema MANTIS, permitiendo la autogeneración de agentes sin atarse a un proveedor específico.

**Cubre:**
- Configuración de la API de OpenRouter (autenticación, endpoints, cabeceras).
- **5 ejemplos detallados por cada uno de los 5 mejores modelos gratuitos (Free In/Out)** para tareas de agentes, RAG y reasoning.
- Implementación de estrategias de `fallback`, `retry` y manejo de rate limits (C6).
- Inyección de contexto multi-tenant (`tenant_id`) en las peticiones para auditoría (C4).
- **CI/CD e Infraestructura como Código (IaC)** con Terraform para despliegue automatizado.
- **Hardening de seguridad** y verificación automatizada de integridad de secretos.
- **Autogeneración por IA** de workflows y agentes usando OpenRouter.

**No cubre:**
- La implementación de la lógica de RAG (eso reside en `whatsapp-rag-openrouter.md`).
- La gestión de prompts por vertical (ubicada en `05-CONFIGURATIONS/prompts/`).
- La configuración de modelos locales (prohibido por C6).

### Top 5 Modelos Gratuitos para Agentes MANTIS (Abril 2026)

| Modelo | ID (OpenRouter) | Contexto | Fortalezas para MANTIS | Límite Diario (Aprox.) |
| :--- | :--- | :--- | :--- | :--- |
| **Qwen 3.6 Plus Preview** | `qwen/qwen3.6-plus-preview:free` | 1M | **Razonamiento (Chain-of-Thought)**, tareas complejas, ventana de contexto masiva. | 50 reqs/día |
| **NVIDIA Nemotron 3 Super** | `nvidia/nemotron-3-super:free` | 1M | **Rendimiento en agentes**, multi-step planning, excelente en benchmarks de agentes. | 50 reqs/día |
| **DeepSeek V3** | `deepseek/deepseek-chat-v3-0324:free` | 128K | **Mejor relación costo/rendimiento (económico)**, ideal para alto volumen de consultas simples. | 50 reqs/día |
| **Llama 3.3 70B** | `meta-llama/llama-3.3-70b-instruct:free` | 131K | **Mejor rendimiento general gratuito**, nivel GPT-4 para la mayoría de tareas. | 50 reqs/día |
| **Step 3.5 Flash** | `stepfun/step-3.5-flash:free` | 256K | **Velocidad de inferencia extremadamente rápida**, razonamiento general sólido. | 50 reqs/día |

> **Nota sobre límites:** Para cuentas sin crédito, el límite es de ~50 peticiones/día y 20 peticiones/minuto. Al mantener un saldo de crédito > $10 USD, el límite diario se expande a ~1000 peticiones/día.

---

## 📐 Fundamentos (De 0 a Intermedio)

### ¿Qué es OpenRouter?
OpenRouter es un **gateway de API unificado** para LLMs. En lugar de gestionar múltiples cuentas, API Keys y formatos de petición para cada proveedor (OpenAI, Anthropic, Google, etc.), OpenRouter te permite acceder a **más de 400 modelos** usando una única API Key y un formato de petición estándar (compatible con OpenAI).

### ¿Por qué es importante para MANTIS?
1.  **Flexibilidad (C6):** Permite al sistema de autogeneración de agentes seleccionar el mejor modelo para cada tarea (ej: `deepseek-chat` para economía, `qwen3.6` para razonamiento complejo) sin cambiar el código.
2.  **Robustez:** Implementa lógica de **fallback automático**. Si un proveedor (ej: DeepSeek) está caído, OpenRouter puede enrutar la petición a otro modelo similar, garantizando la continuidad del servicio.
3.  **Estandarización:** Al usar el formato de la API de OpenAI, la migración desde o hacia otros servicios es mínima.

---

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

### Aplicación de Constraints C1 y C2

La inferencia a través de OpenRouter es una operación de I/O de red. **No consume RAM ni CPU significativas en tu VPS** (cumpliendo C1 y C2). El costo principal es la latencia y la gestión de la concurrencia.

- **C1 (RAM):** La respuesta de la API se almacena en memoria temporalmente. Para respuestas largas, es preferible usar `streaming` (ver ejemplos) para procesar los datos como un flujo y no como un gran bloque, limitando el uso de RAM.
- **C2 (vCPU):** El uso de CPU es mínimo (~1-2% de una vCPU) para el cliente HTTP. El riesgo es el **bloqueo del event loop** de Node.js/Python si se realizan muchas peticiones secuenciales. Para mitigarlo, siempre usa `async/await` y un pool de conexiones HTTP con `keepAlive`.

### Configuración de `axios` optimizada para VPS

```typescript
import axios from 'axios';
import http from 'http';

const httpAgent = new http.Agent({ keepAlive: true, maxSockets: 5 }); // C1: límite de 5 conexiones

export const openRouterClient = axios.create({
  baseURL: 'https://openrouter.ai/api/v1',
  timeout: 60000, // Timeout generoso de 60s
  headers: {
    'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}`,
    'HTTP-Referer': process.env.APP_URL || 'http://localhost:3000', // Recomendado por OpenRouter
    'X-Title': 'MantisAgenticDev' // Recomendado por OpenRouter
  },
  httpAgent
});
```

---

## 🔗 Integración con Stack Existente (n8n, Qdrant, EspoCRM)

### Inyección de Contexto RAG y Multi-Tenancy (C4)

```typescript
import { openRouterClient } from './openrouter-client';

export async function generateAgentResponse(
  tenantId: string,
  userQuery: string,
  ragContext: string[]
) {
  const systemPrompt = `
    Eres un asistente útil para el tenant ${tenantId}.
    Responde ÚNICAMENTE basándote en el siguiente contexto:
    ${ragContext.join('\n---\n')}
    Si la respuesta no está en el contexto, di "No tengo esa información".
  `;

  try {
    const response = await openRouterClient.post('/chat/completions', {
      model: 'meta-llama/llama-3.3-70b-instruct:free', // Modelo gratuito por defecto
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userQuery }
      ],
      temperature: 0.2,
      // Incluir tenant_id en metadatos para auditoría (C4)
      transforms: ["openrouter/auto"],
      metadata: { tenant_id: tenantId }
    });

    return response.data.choices[0].message.content;
  } catch (error) {
    // Lógica de fallback (Ejemplo 6 de cada modelo)
    console.error(`OpenRouter error for tenant ${tenantId}:`, error);
    throw error;
  }
}
```

---

## 🛠️ 25 Ejemplos de Configuración (5 por cada modelo gratuito)

### 🤖 Modelo 1: Qwen 3.6 Plus Preview

#### Ejemplo Q1.1: Llamada básica con razonamiento
**Objetivo**: Consulta simple aprovechando el razonamiento obligatorio del modelo.
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

#### Ejemplo Q1.2: Contexto masivo (1M tokens)
**Objetivo**: Procesar un documento extenso.
**Nivel**: 🔴

```typescript
async function analyzeLargeDocWithQwen(doc: string, question: string) {
  const response = await openRouterClient.post('/chat/completions', {
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

#### Ejemplo Q1.3: Streaming para respuestas largas
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

#### Ejemplo Q1.4: Tool Calling
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
  const response = await openRouterClient.post('/chat/completions', {
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

#### Ejemplo Q1.5: Rate limiting y reintentos
**Objetivo**: Manejar límites gratuitos con backoff.
**Nivel**: 🟡

```typescript
import Bottleneck from 'bottleneck';
const limiter = new Bottleneck({ minTime: 3000 }); // 20 req/min

const safeQwenCall = limiter.wrap(async (prompt: string) => {
  return askQwen36(prompt);
});
```

---

### 🤖 Modelo 2: NVIDIA Nemotron 3 Super

#### Ejemplo N2.1: Llamada básica para agentes
**Objetivo**: Uso general con excelente planificación multi-step.
**Nivel**: 🟢

```typescript
async function askNemotron(prompt: string) {
  const response = await openRouterClient.post('/chat/completions', {
    model: 'nvidia/nemotron-3-super:free',
    messages: [{ role: 'user', content: prompt }],
    max_tokens: 400
  });
  console.log(response.data.choices[0].message.content);
}
```
✅ **Deberías ver:** Respuesta bien estructurada.
❌ **Si ves:** `Error: 402 Payment Required` → Verifica que el ID termine en `:free`.

#### Ejemplo N2.2: Planificación multi-step
**Objetivo**: Resolver problemas que requieren varios pasos.
**Nivel**: 🟡

```typescript
const prompt = "Planifica un viaje de 3 días a Madrid: lugares a visitar, transporte y presupuesto.";
const response = await askNemotron(prompt);
```

#### Ejemplo N2.3: Contexto largo (1M tokens)
**Objetivo**: Analizar documentos extensos.
**Nivel**: 🔴

```typescript
async function analyzeWithNemotron(doc: string, question: string) {
  return openRouterClient.post('/chat/completions', {
    model: 'nvidia/nemotron-3-super:free',
    messages: [
      { role: 'system', content: 'Eres un analista de documentos.' },
      { role: 'user', content: `Documento:\n${doc}\n\nPregunta: ${question}` }
    ]
  });
}
```

#### Ejemplo N2.4: Streaming
**Objetivo**: Respuesta fluida.
**Nivel**: 🟡
(Código similar al ejemplo Q1.3, cambiando el modelo)

#### Ejemplo N2.5: Tool Calling para agentes
**Objetivo**: Orquestar herramientas externas.
**Nivel**: 🟡
(Código similar al ejemplo Q1.4)

---

### 🤖 Modelo 3: DeepSeek V3

#### Ejemplo D3.1: Llamada básica económica
**Objetivo**: Respuesta rápida y barata.
**Nivel**: 🟢

```typescript
async function askDeepSeek(prompt: string) {
  const response = await openRouterClient.post('/chat/completions', {
    model: 'deepseek/deepseek-chat-v3-0324:free',
    messages: [{ role: 'user', content: prompt }],
    max_tokens: 300
  });
  console.log(response.data.choices[0].message.content);
}
```

#### Ejemplo D3.2: Extracción de `reasoning_content`
**Objetivo**: Obtener el razonamiento interno (solo en DeepSeek).
**Nivel**: 🟡

```typescript
async function deepseekWithReasoning(prompt: string) {
  const response = await openRouterClient.post('/chat/completions', {
    model: 'deepseek/deepseek-chat-v3-0324:free',
    messages: [{ role: 'user', content: prompt }],
    include_reasoning: true
  });
  const msg = response.data.choices[0].message;
  console.log('Reasoning:', msg.reasoning);
  console.log('Content:', msg.content);
}
```

#### Ejemplo D3.3: Cálculo de tokens previo
**Objetivo**: Evitar exceder límite de 128K.
**Nivel**: 🟢

```typescript
import { encoding_for_model } from 'tiktoken';
const enc = encoding_for_model('gpt-4');
const tokens = enc.encode(prompt);
if (tokens.length > 120000) throw new Error('Prompt demasiado largo');
```

#### Ejemplo D3.4: Streaming
**Objetivo**: Procesamiento progresivo.
**Nivel**: 🟡
(Similar a ejemplos anteriores)

#### Ejemplo D3.5: Rate limiting y fallback
**Objetivo**: Usar DeepSeek como primario y Qwen como fallback.
**Nivel**: 🟡

```typescript
async function resilientCall(prompt: string) {
  try {
    return await askDeepSeek(prompt);
  } catch (err) {
    if (err.response?.status === 429 || err.response?.status >= 500) {
      return await askQwen36(prompt); // Fallback a Qwen
    }
    throw err;
  }
}
```

---

### 🤖 Modelo 4: Llama 3.3 70B

#### Ejemplo L4.1: Llamada básica de propósito general
**Objetivo**: Mejor rendimiento general gratuito.
**Nivel**: 🟢

```typescript
async function askLlama(prompt: string) {
  const response = await openRouterClient.post('/chat/completions', {
    model: 'meta-llama/llama-3.3-70b-instruct:free',
    messages: [{ role: 'user', content: prompt }],
    max_tokens: 500
  });
  console.log(response.data.choices[0].message.content);
}
```

#### Ejemplo L4.2: Tool Calling nativo
**Objetivo**: Llamar funciones externas con alta precisión.
**Nivel**: 🟡
(Código similar al ejemplo Q1.4, usando el modelo de Llama)

#### Ejemplo L4.3: Respuesta en JSON estructurado
**Objetivo**: Forzar salida JSON.
**Nivel**: 🟡

```typescript
const response = await openRouterClient.post('/chat/completions', {
  model: 'meta-llama/llama-3.3-70b-instruct:free',
  messages: [
    { role: 'system', content: 'Responde solo con JSON válido.' },
    { role: 'user', content: 'Dame un JSON con nombre, edad y ciudad.' }
  ],
  response_format: { type: 'json_object' }
});
```

#### Ejemplo L4.4: Streaming
**Objetivo**: Respuesta token a token.
**Nivel**: 🟡
(Similar a ejemplos anteriores)

#### Ejemplo L4.5: Selección dinámica de modelo
**Objetivo**: Usar Llama para tareas generales, Qwen para razonamiento.
**Nivel**: 🟡

```typescript
function selectModel(prompt: string): string {
  if (prompt.includes('razona') || prompt.includes('paso a paso')) {
    return 'qwen/qwen3.6-plus-preview:free';
  }
  return 'meta-llama/llama-3.3-70b-instruct:free';
}
```

---

### 🤖 Modelo 5: Step 3.5 Flash

#### Ejemplo S5.1: Llamada básica de alta velocidad
**Objetivo**: Respuesta casi instantánea.
**Nivel**: 🟢

```typescript
async function askStepFlash(prompt: string) {
  const response = await openRouterClient.post('/chat/completions', {
    model: 'stepfun/step-3.5-flash:free',
    messages: [{ role: 'user', content: prompt }],
    max_tokens: 400
  });
  console.log(response.data.choices[0].message.content);
}
```
✅ **Deberías ver:** Respuesta en <1 segundo.
❌ **Si ves:** `Error: 402` → Verifica el ID `:free`.

#### Ejemplo S5.2: Streaming rápido
**Objetivo**: Tokens a máxima velocidad.
**Nivel**: 🟡
(Similar a ejemplos anteriores)

#### Ejemplo S5.3: Caché de respuestas con Redis
**Objetivo**: Reducir llamadas para FAQs.
**Nivel**: 🟡

```typescript
const cacheKey = `step:${hash}`;
const cached = await redis.get(cacheKey);
if (cached) return cached;
const response = await askStepFlash(prompt);
await redis.setex(cacheKey, 3600, response);
```

#### Ejemplo S5.4: Tool Calling
**Objetivo**: Llamadas a funciones con baja latencia.
**Nivel**: 🟡
(Código similar al ejemplo Q1.4)

#### Ejemplo S5.5: Uso como fallback de baja latencia
**Objetivo**: Si el modelo principal es lento, cambiar a Step 3.5 Flash.
**Nivel**: 🟡

```typescript
const start = Date.now();
try {
  return await askLlama(prompt);
} catch (err) {
  if (err.code === 'ECONNABORTED' || err.response?.status >= 500) {
    console.warn('Fallback to Step 3.5 Flash due to latency');
    return await askStepFlash(prompt);
  }
  throw err;
}
```

---

## 🐞 15 Errores Comunes y Troubleshooting

| Error Exacto (copiable) | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso | Constraint Afectado |
| :--- | :--- | :--- | :--- | :--- |
| **1.** `Error: socket hang up` | Timeout de la conexión. | `time curl ...` | Aumentar timeout a 60s. Usar streaming. Cambiar a modelo más rápido (Step 3.5 Flash). | C2 |
| **2.** `"error":{"message":"No endpoints found matching your data policy"}` | Configuración de privacidad. | Revisar `https://openrouter.ai/settings`. | Activar "Enable training and logging (chatroom and API)". | C6 |
| **3.** `Error: Request failed with status code 402` | Créditos insuficientes para un modelo de pago. | Revisar saldo en OpenRouter. | Añadir créditos o cambiar a modelo `:free`. | C6 |
| **4.** `Error: 429 Too Many Requests` | Límite de tasa excedido. | Revisar cabeceras `x-ratelimit-remaining`. | Implementar `bottleneck` con `minTime` calculado. Esperar. | C1 |
| **5.** `Error: 400 Context length exceeded` | Prompt excede ventana de contexto. | Calcular tokens con `tiktoken`. | Truncar contexto RAG. Usar modelo con mayor contexto (Qwen 3.6). | C2 |
| **6.** `"error":{"message":"Invalid model"}` | ID de modelo incorrecto. | `curl https://openrouter.ai/api/v1/models`. | Usar el ID exacto, incluyendo proveedor y sufijo `:free`. | - |
| **7.** `Error: 401 Unauthorized` | API Key inválida. | `curl -H "Authorization: Bearer $KEY" https://openrouter.ai/api/v1/auth/key`. | Regenerar key en OpenRouter. | C3 |
| **8.** `Error: 500 Internal Server Error` | Fallo del proveedor. | Revisar páginas de estado. | Implementar fallback a otro modelo (Ejemplo D3.5). | C6 |
| **9.** `"reasoning" es null` | Modelo no soporta reasoning o no se solicitó. | Asegurar `include_reasoning: true`. | Usar modelos que sí lo soportan (Qwen 3.6, DeepSeek). | - |
| **10.** `Error: getaddrinfo ENOTFOUND openrouter.ai` | Problema de DNS. | `nslookup openrouter.ai`. | Verificar `/etc/resolv.conf` (usar `8.8.8.8`). | C3 |
| **11.** El streaming se detiene abruptamente | Problema de red. | Monitorear con `ping`. | Implementar reintentos y fallback. | C6 |
| **12.** `"error":{"message":"provider_not_supported"}` | Modelo de pago usado como gratuito. | Verificar sufijo `:free`. | Usar solo IDs de la lista de modelos gratuitos. | - |
| **13.** La respuesta está en inglés a pesar del prompt en español | El modelo por defecto usa inglés. | Revisar `system prompt`. | Añadir al system: `Responde siempre en español.`. | - |
| **14.** `Error: Request Entity Too Large (413)` | Payload demasiado grande. | Verificar tamaño del body. | Evitar enviar imágenes enormes en base64. | C1 |
| **15.** `Error: Cannot read properties of undefined (reading 'content')` | La API devolvió un error en JSON sin `choices`. | Inspeccionar `response.data`. | Validar `response.data.error` antes de acceder a `choices`. | - |

---

## ✅ Validación SDD y Comandos de Verificación

<!-- ai:constraint=C5 -->
### 1. Verificar conectividad con OpenRouter:
```bash
curl -I https://openrouter.ai/api/v1/models
```

### 2. Auditar el uso de `tenant_id` en logs (C4):
```bash
grep -c '"tenant_id":"' /var/log/mantis-ai.log
```

### 3. Chequeo de secretos (C3):
```bash
grep -r "sk-or-v1-" /opt/mantis --exclude-dir=node_modules
```

### 4. Monitoreo de latencia y errores (C2):
Implementar métrica Prometheus para `openrouter_request_duration_seconds`.

### 5. Backup de la API Key (C5):
```bash
sha256sum .env > .env.sha256
rsync -avz .env.sha256 backup@server:/backup/
```

---

## 🚀 CI/CD, IaC y Autogeneración con IA (Normas MANTIS)

### Pipeline de Integración Continua para Agentes OpenRouter

1. **Especificación (`openrouter-agent-spec.yaml`):** Define modelos primarios/fallback, rate limits y contexto.
2. **Generación automática:** Una IA (GPT-4o) lee la especificación y genera el código TypeScript del worker.
3. **Validación en CI:**
   - Linting (`eslint`).
   - Pruebas unitarias de funciones de llamada a OpenRouter.
   - Evaluación de calidad con **Promptfoo**.
4. **Infraestructura como Código (IaC) con Terraform:**
   ```hcl
   resource "digitalocean_droplet" "openrouter_agent" {
     name   = "mantis-openrouter-agent"
     size   = "s-2vcpu-4gb"
     image  = "ubuntu-22-04-x64"
     region = "nyc3"
     user_data = file("cloud-init.yaml")
   }
   ```
5. **Despliegue Continuo:** GitHub Actions ejecuta `terraform apply` y reinicia el servicio.

### Hardening de Seguridad

- **Cifrado en tránsito:** HTTPS obligatorio.
- **Validación de webhooks:** Firma SHA256 para endpoints de notificación.
- **Rotación de secretos:** API Keys se rotan cada 90 días usando HashiCorp Vault.
- **Aislamiento de workers:** Procesos separados con `systemd` y límites de memoria.

### Autogeneración de Workflows de n8n

Para agentes que requieren lógica compleja, el sistema puede generar un workflow de n8n que consuma OpenRouter. El workflow se despliega automáticamente vía API de n8n.

---

## 🔗 Referencias Cruzadas y Glosario

- [[whatsapp-rag-openrouter.md]] - Orquestación de agentes de WhatsApp con RAG y OpenRouter.
- [[deepseek-integration.md]] - Patrones de integración específicos para DeepSeek.
- [[qwen-integration.md]] - Patrones para Qwen.
- [[llama-integration.md]] - Patrones para Llama.
- [[environment-variable-management.md]] - Gestión segura de `OPENROUTER_API_KEY`.

**Glosario:**
- **RAG:** Retrieval-Augmented Generation.
- **Gateway:** Punto de acceso unificado a múltiples servicios.
- **Rate Limit:** Límite de peticiones por unidad de tiempo.
- **Fallback:** Mecanismo de respaldo ante un fallo.
- **Streaming:** Técnica para enviar la respuesta en tiempo real, token por token.

FIN DEL ARCHIVO
<!-- ai:file-end marker - do not remove -->
Versión 2.0.0 - 2026-04-11 - Mantis-AgenticDev
