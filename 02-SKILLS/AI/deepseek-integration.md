---
title: "deepseek-integration.md"
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
  - "02-SKILLS/AI/qwen-integration.md"
  - "05-CONFIGURATIONS/environment-variable-management.md"
---

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

**Objetivo en 3 minutos:** Realizar la primera llamada a un modelo DeepSeek (gratuito) a través de OpenRouter.

1. **Requisito previo:** Obtener una API Key de [OpenRouter.ai](https://openrouter.ai) o directamente de [DeepSeek Platform](https://platform.deepseek.com/).
2. **Variable de entorno (C3):**  
   ```bash
   echo "OPENROUTER_API_KEY=sk-or-v1-..." >> .env
   ```
3. **Llamada de prueba con `curl`:**
   ```bash
   curl https://openrouter.ai/api/v1/chat/completions \
     -H "Authorization: Bearer $OPENROUTER_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "model": "deepseek/deepseek-chat-v3-0324:free",
       "messages": [{"role": "user", "content": "¿Cuál es la capital de Francia?"}]
     }'
   ```
✅ **Deberías ver:** Un JSON con `choices[0].message.content` y la respuesta "París".  
❌ **Si ves:** `{"error":{"message":"No endpoints found matching your data policy"}}` → Ve a Troubleshooting #2.

⚠️ **Advertencia para Junior:** DeepSeek es conocido por su excelente relación costo/rendimiento y su soporte para contexto de 128K tokens. El modelo `deepseek-chat` es gratuito en OpenRouter (con límites de uso). Nunca hardcodees la API Key en tu código (C3).

---

## 🎯 Propósito y Alcance

Este skill documenta los patrones de integración para consumir los modelos de **DeepSeek** en el ecosistema MANTIS, tanto a través de OpenRouter como de la API nativa de DeepSeek. DeepSeek destaca por su **ventana de contexto de 128K tokens**, su **campo `reasoning_content`** (que expone el proceso de pensamiento) y su **costo extremadamente bajo**, ideal para agentes de alto volumen.

**Cubre:**
- Los modelos principales: **DeepSeek-V3** (`deepseek-chat`) y **DeepSeek-R1** (`deepseek-reasoner`).
- Estrategias de implementación para **razonamiento (chain-of-thought)**, **contexto largo**, **tool calling** y **streaming**.
- Configuración de reintentos, rate limiting y fallback para cumplir con C1/C2.
- **CI/CD e Infraestructura como Código (IaC)** con Terraform para despliegue automatizado.
- **Hardening de seguridad** y verificación automatizada de integridad de secretos.
- **Autogeneración por IA** de agentes usando DeepSeek.

**No cubre:**
- Modelos de embedding de DeepSeek (si existieran).
- La lógica de negocio de los agentes (eso reside en los workflows de n8n).

---

## 📐 Fundamentos (De 0 a Intermedio)

### ¿Qué es DeepSeek?
DeepSeek es un laboratorio de IA chino que ha desarrollado modelos de lenguaje de alto rendimiento y código abierto. Sus modelos se caracterizan por:

- **Costo bajo:** $0.14 / $0.28 por millón de tokens (input/output) en DeepSeek-V3, significativamente más barato que GPT-4o.
- **Contexto 128K:** Suficiente para procesar documentos extensos.
- **Razonamiento explícito:** El modelo `deepseek-reasoner` devuelve su cadena de pensamiento en el campo `reasoning_content`, lo que permite auditoría y depuración.
- **Tool Calling:** Soporta function calling compatible con OpenAI.

### Integración con MANTIS
DeepSeek es el motor predeterminado para tareas de alto volumen y bajo presupuesto en MANTIS. Se integra perfectamente con el stack RAG (Qdrant) y los workflows de n8n.

---

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

### Aplicación de Constraints C1 y C2

- **C1 (RAM ≤ 4GB):** La inferencia es cloud (C6). El VPS solo realiza I/O de red. El riesgo es la respuesta: `deepseek-reasoner` puede devolver razonamientos largos. **Siempre usa `streaming`** para evitar acumular toda la respuesta en RAM.
- **C2 (1 vCPU):** El cliente HTTP consume <2% de CPU. Para no bloquear el event loop, usa `async/await` y un agente HTTP con keep-alive.

### Configuración de Cliente HTTP Optimizado

```typescript
import axios from 'axios';
import http from 'http';

const httpAgent = new http.Agent({ keepAlive: true, maxSockets: 5 }); // C1

export const deepseekClient = axios.create({
  baseURL: 'https://openrouter.ai/api/v1',
  timeout: 90000, // 90 segundos para razonamiento
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
import { deepseekClient } from './deepseek-client';

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
    const response = await deepseekClient.post('/chat/completions', {
      model: 'deepseek/deepseek-chat-v3-0324:free',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userQuery }
      ],
      temperature: 0.1,
      include_reasoning: true, // Solo para deepseek-reasoner
      metadata: { tenant_id: tenantId } // C4
    });

    const message = response.data.choices[0].message;
    const reasoning = message.reasoning;
    const answer = message.content;

    // Auditoría
    console.log(JSON.stringify({
      event: 'deepseek_call',
      tenant_id: tenantId,
      reasoning_length: reasoning?.length || 0
    }));

    return answer;
  } catch (error) {
    console.error(`DeepSeek error for tenant ${tenantId}:`, error);
    throw error;
  }
}
```

---

## 🛠️ 20 Ejemplos de Configuración (Copy-Paste Validables)

### Ejemplo 1: Llamada básica a DeepSeek-V3 (Gratuito vía OpenRouter)
**Objetivo**: Pregunta simple sin contexto externo.  
**Nivel**: 🟢

```typescript
import axios from 'axios';

async function askDeepSeek(prompt: string) {
  const response = await axios.post(
    'https://openrouter.ai/api/v1/chat/completions',
    {
      model: 'deepseek/deepseek-chat-v3-0324:free',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 200,
    },
    { headers: { Authorization: `Bearer ${process.env.OPENROUTER_API_KEY}` } }
  );
  console.log(response.data.choices[0].message.content);
}
```
✅ **Deberías ver:** La respuesta del modelo.  
❌ **Si ves:** `Error: 402 Payment Required` → Ve a Troubleshooting #3.

### Ejemplo 2: Uso de `deepseek-reasoner` con extracción de razonamiento
**Objetivo**: Obtener el paso a paso lógico para auditoría.  
**Nivel**: 🟡

```typescript
async function askWithReasoning(prompt: string) {
  const response = await deepseekClient.post('/chat/completions', {
    model: 'deepseek/deepseek-reasoner', // Modelo de razonamiento
    messages: [{ role: 'user', content: prompt }],
    include_reasoning: true
  });
  const msg = response.data.choices[0].message;
  console.log('Razonamiento:', msg.reasoning);
  console.log('Respuesta:', msg.content);
}
```
✅ **Deberías ver:** Razonamiento y respuesta final.

### Ejemplo 3: Contexto largo (128K tokens)
**Objetivo**: Procesar un documento extenso.  
**Nivel**: 🔴

```typescript
async function analyzeLargeDoc(doc: string, question: string) {
  const response = await deepseekClient.post('/chat/completions', {
    model: 'deepseek/deepseek-chat-v3-0324:free',
    messages: [
      { role: 'system', content: 'Analiza el documento y responde.' },
      { role: 'user', content: `Documento:\n${doc}\n\nPregunta: ${question}` }
    ],
    max_tokens: 1000
  });
  return response.data.choices[0].message.content;
}
```

### Ejemplo 4: Streaming para respuestas largas
**Objetivo**: Recibir tokens en tiempo real.  
**Nivel**: 🟡

```typescript
async function streamDeepSeek(prompt: string) {
  const response = await axios.post(
    'https://openrouter.ai/api/v1/chat/completions',
    {
      model: 'deepseek/deepseek-chat-v3-0324:free',
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

### Ejemplo 5: Tool Calling (Function Calling)
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

async function deepseekWithTools(prompt: string) {
  const response = await deepseekClient.post('/chat/completions', {
    model: 'deepseek/deepseek-chat-v3-0324:free',
    messages: [{ role: 'user', content: prompt }],
    tools,
    tool_choice: 'auto'
  });
  const msg = response.data.choices[0].message;
  if (msg.tool_calls) console.log('Tool calls:', msg.tool_calls);
  else console.log(msg.content);
}
```

### Ejemplo 6: Rate limiting con `bottleneck`
**Objetivo**: Respetar límites gratuitos (20 req/min).  
**Nivel**: 🟡

```typescript
import Bottleneck from 'bottleneck';
const limiter = new Bottleneck({ minTime: 3000 }); // 1 cada 3 segundos

const safeDeepSeekCall = limiter.wrap(async (prompt: string) => {
  return askDeepSeek(prompt);
});
```

### Ejemplo 7: Reintento con backoff exponencial
**Objetivo**: Robustez ante errores 5xx.  
**Nivel**: 🟡

```typescript
async function callWithRetry(prompt: string, maxRetries = 3): Promise<any> {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await askDeepSeek(prompt);
    } catch (err) {
      if (err.response?.status >= 500 && i < maxRetries - 1) {
        await new Promise(r => setTimeout(r, 1000 * Math.pow(2, i)));
        continue;
      }
      throw err;
    }
  }
}
```

### Ejemplo 8: Cálculo de tokens con `tiktoken`
**Objetivo**: Evitar error 400 por contexto excedido.  
**Nivel**: 🟢

```typescript
import { encoding_for_model } from 'tiktoken';
const enc = encoding_for_model('gpt-4');
const tokens = enc.encode(prompt);
if (tokens.length > 120000) throw new Error('Prompt demasiado largo');
```

### Ejemplo 9: Fallback automático a otro modelo
**Objetivo**: Si DeepSeek falla, usar Qwen 3.6.  
**Nivel**: 🟡

```typescript
async function resilientCall(prompt: string) {
  try {
    return await askDeepSeek(prompt);
  } catch (err) {
    if (err.response?.status === 429 || err.response?.status >= 500) {
      return await askQwen36(prompt); // Ver qwen-integration.md
    }
    throw err;
  }
}
```

### Ejemplo 10: Logging estructurado (C4)
**Objetivo**: Auditoría de uso por tenant.  
**Nivel**: 🟢

```typescript
console.log(JSON.stringify({
  event: 'deepseek_usage',
  tenant_id: tenantId,
  tokens_prompt: usage.prompt_tokens,
  tokens_completion: usage.completion_tokens
}));
```

### Ejemplo 11: Control de temperatura para tareas precisas
**Objetivo**: Ajustar creatividad.  
**Nivel**: 🟢

```typescript
const precise = await deepseekClient.post(..., { temperature: 0.1 });
const creative = await deepseekClient.post(..., { temperature: 0.8 });
```

### Ejemplo 12: Respuesta en JSON estructurado
**Objetivo**: Forzar salida JSON.  
**Nivel**: 🟡

```typescript
const response = await deepseekClient.post('/chat/completions', {
  model: 'deepseek/deepseek-chat-v3-0324:free',
  messages: [
    { role: 'system', content: 'Responde solo con JSON válido.' },
    { role: 'user', content: 'Dame un JSON con nombre, edad y ciudad.' }
  ],
  response_format: { type: 'json_object' }
});
```

### Ejemplo 13: Uso de la API nativa de DeepSeek
**Objetivo**: Conectarse directamente a DeepSeek Platform.  
**Nivel**: 🟡

```typescript
const nativeClient = axios.create({
  baseURL: 'https://api.deepseek.com/v1',
  headers: { Authorization: `Bearer ${process.env.DEEPSEEK_API_KEY}` }
});
const response = await nativeClient.post('/chat/completions', {
  model: 'deepseek-chat',
  messages: [{ role: 'user', content: 'Hola desde API nativa' }]
});
```

### Ejemplo 14: Procesamiento por lotes (batch) para ahorro
**Objetivo**: Usar API batch de DeepSeek para tareas offline.  
**Nivel**: 🔴

```typescript
// Crear archivo JSONL con múltiples solicitudes
// Subir a DeepSeek y esperar resultados (puede tardar horas)
```

### Ejemplo 15: Caché de respuestas con Redis
**Objetivo**: Reducir llamadas repetidas.  
**Nivel**: 🟡

```typescript
const cacheKey = `deepseek:${hash}`;
const cached = await redis.get(cacheKey);
if (cached) return cached;
const response = await askDeepSeek(prompt);
await redis.setex(cacheKey, 3600, response);
```

### Ejemplo 16: Validación de prompt con Azure Content Safety
**Objetivo**: Filtrar contenido inapropiado.  
**Nivel**: 🔴

```typescript
import { ContentSafetyClient } from '@azure-rest/ai-content-safety';
// ... (ver ejemplos en otros skills)
```

### Ejemplo 17: Manejo de múltiples tenants en la misma petición
**Objetivo**: Aislar datos por tenant (C4).  
**Nivel**: 🟢

```typescript
const response = await deepseekClient.post('/chat/completions', {
  // ...
  user: tenantId // Campo estándar para auditoría en OpenAI-compatible APIs
});
```

### Ejemplo 18: Timeout personalizado por llamada
**Objetivo**: Evitar bloqueos.  
**Nivel**: 🟢

```typescript
const response = await deepseekClient.post('/chat/completions', payload, {
  timeout: 45000 // 45 segundos
});
```

### Ejemplo 19: Healthcheck del endpoint de DeepSeek
**Objetivo**: Monitoreo proactivo.  
**Nivel**: 🟢

```typescript
async function healthCheck(): Promise<boolean> {
  try {
    await deepseekClient.get('/models');
    return true;
  } catch {
    return false;
  }
}
```

### Ejemplo 20: Autogeneración de código de agente con DeepSeek
**Objetivo**: Usar DeepSeek para crear un worker de agente.  
**Nivel**: 🔴

```typescript
const spec = fs.readFileSync('agent-spec.yaml', 'utf-8');
const prompt = `Genera el código TypeScript de un agente basado en esta especificación:\n${spec}`;
const code = await askDeepSeek(prompt);
fs.writeFileSync('generated-agent.ts', code);
```

---

## 🐞 20 Errores Comunes y Troubleshooting

| Error Exacto (copiable) | Causa Raíz | Comando de Diagnóstico | Solución Paso a Paso | Constraint Afectado |
| :--- | :--- | :--- | :--- | :--- |
| **1.** `Error: 401 Unauthorized` | API Key de OpenRouter inválida o sin saldo. | `curl -H "Authorization: Bearer $KEY" https://openrouter.ai/api/v1/auth/key` | 1. Regenerar key en OpenRouter. 2. Verificar variable de entorno. | C3 |
| **2.** `"error":{"message":"No endpoints found matching your data policy"}` | Configuración de privacidad en OpenRouter. | Revisar `https://openrouter.ai/settings`. | Activar "Enable training and logging". Requerido para modelos gratuitos. | C6 |
| **3.** `Error: 402 Payment Required` | Intento de usar modelo de pago sin créditos. | Verificar ID del modelo. | Usar `:free` en el ID o añadir créditos. | C6 |
| **4.** `Error: 429 Too Many Requests` | Límite de tasa excedido. | Revisar cabeceras `x-ratelimit-remaining`. | Implementar `bottleneck` (Ejemplo 6). | C1 |
| **5.** `Error: 400 Context length exceeded` | Prompt supera 128K tokens. | Calcular tokens con `tiktoken`. | Truncar contexto RAG a ~120K tokens. | C2 |
| **6.** `Error: 500 Internal Server Error` | Fallo temporal del proveedor. | Reintentar tras 60s. | Implementar fallback (Ejemplo 9). | C6 |
| **7.** `"error":"tool_calls" is not valid` | Uso incorrecto de tool_calls. | Validar esquema JSON con `ajv`. | Usar el formato correcto de function calling. | - |
| **8.** `reasoning_content` vacío o ausente | No se usó `deepseek-reasoner`. | Verificar modelo. | Cambiar a `deepseek/deepseek-reasoner`. | - |
| **9.** `Error: socket hang up` | Timeout de conexión. | `time curl ...` | Aumentar timeout a 90s. | C2 |
| **10.** `Error: getaddrinfo ENOTFOUND openrouter.ai` | Problema de DNS. | `nslookup openrouter.ai`. | Verificar `/etc/resolv.conf` (usar `8.8.8.8`). | C3 |
| **11.** `Error: 400 Invalid model` | Nombre de modelo incorrecto. | `curl https://openrouter.ai/api/v1/models`. | Usar `deepseek/deepseek-chat-v3-0324:free`. | - |
| **12.** Respuesta cortada (`finish_reason = "length"`) | `max_tokens` insuficiente. | Ver campo `finish_reason`. | Aumentar `max_tokens`. | - |
| **13.** Streaming se detiene abruptamente | Problema de red. | Monitorear con `ping`. | Implementar reintentos. | C6 |
| **14.** `Error: 413 Payload Too Large` | Prompt demasiado grande (raro con texto). | Verificar tamaño del body. | Reducir contexto. | C1 |
| **15.** Respuesta en inglés a pesar de prompt en español | Modelo por defecto usa inglés. | Revisar system prompt. | Añadir `Responde siempre en español.`. | - |
| **16.** `Error: Cannot read properties of undefined (reading 'content')` | La API devolvió un error sin `choices`. | Inspeccionar `response.data`. | Manejar `response.data.error`. | - |
| **17.** `Error: 403 Forbidden` | IP bloqueada por política de seguridad. | Probar desde otra IP. | Contactar a OpenRouter/DeepSeek para whitelist. | C3 |
| **18.** `Error: 400 Invalid parameter: 'include_reasoning'` | Modelo no soporta reasoning. | Verificar modelo. | Usar `deepseek-reasoner`. | - |
| **19.** Latencia >30s en `deepseek-reasoner` | Razonamiento complejo. | Medir con `time`. | Usar `streaming` o cambiar a `deepseek-chat`. | C2 |
| **20.** `Error: Request Entity Too Large` en API batch | Archivo JSONL excede límite. | `ls -lh archivo.jsonl`. | Dividir en lotes más pequeños. | C1 |

---

## ✅ Validación SDD y Comandos de Verificación

<!-- ai:constraint=C5 -->
### 1. Verificar conectividad con DeepSeek vía OpenRouter:
```bash
curl -I https://openrouter.ai/api/v1/models/deepseek/deepseek-chat-v3-0324:free
```

### 2. Auditar uso de `tenant_id` en logs (C4):
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
await callDeepSeek(...);
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

### Pipeline de Integración Continua para Agentes DeepSeek

1. **Especificación (`deepseek-agent-spec.yaml`):** Define modelo, temperatura, herramientas y contexto RAG.
2. **Generación automática:** DeepSeek lee la especificación y genera el código TypeScript del worker, el `Dockerfile` y el workflow de GitHub Actions.
3. **Validación en CI:**
   - Linting (`eslint`).
   - Pruebas unitarias de tool calling.
   - Evaluación de calidad con **Promptfoo**.
4. **Infraestructura como Código (IaC) con Terraform:**
   ```hcl
   resource "digitalocean_droplet" "deepseek_agent" {
     name   = "mantis-deepseek-agent"
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
- **Validación de entrada:** Sanitización de prompts.
- **Aislamiento de workers:** Procesos separados con `systemd` y límites de memoria (`MemoryMax=1.5G`).
- **Auditoría (C4):** Cada llamada se registra con `tenant_id` y uso de tokens.
- **Rotación de secretos:** API Keys se rotan cada 90 días usando HashiCorp Vault.

### Autogeneración de Workflows de n8n

Para agentes complejos, el sistema puede generar un workflow de n8n que consuma DeepSeek. El workflow se despliega automáticamente vía API de n8n.

---

## 🔗 Referencias Cruzadas y Glosario

- [[openrouter-api-integration.md]] - Patrón general para consumir modelos vía OpenRouter.
- [[whatsapp-rag-openrouter.md]] - Orquestación de agentes de WhatsApp con RAG.
- [[qwen-integration.md]] - Integración con Qwen.
- [[environment-variable-management.md]] - Gestión segura de `OPENROUTER_API_KEY`.

**Glosario:**
- **RAG:** Retrieval-Augmented Generation.
- **Chain-of-Thought (CoT):** Técnica de prompting que incita al modelo a razonar paso a paso.
- **Tool Calling (Function Calling):** Capacidad del modelo para solicitar la ejecución de una función externa.

FIN DEL ARCHIVO
<!-- ai:file-end marker - do not remove -->
Versión 2.0.0 - 2026-04-11 - Mantis-AgenticDev
