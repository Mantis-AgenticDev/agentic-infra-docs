---
title: "Telegram Bot Integration - RAG & Customer Service"
category: "Skill"
domain: ["comunicaciones", "rag", "atencion-cliente", "automatizacion"]
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
priority: "CRÍTICA"
version: "2.0.0"
last_updated: "2026-04-09"
ai_optimized: true
tags:
  - sdd/skill/telegram
  - sdd/rag-integration
  - sdd/customer-service
  - sdd/n8n-workflow
  - lang/es
related_files:
  - "01-RULES/04-API-RELIABILITY-RULES.md"
  - "01-RULES/06-MULTITENANCY-RULES.md"
  - "02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md"
  - "02-SKILLS/INFRAESTRUCTURA/vps-interconnection.md"
  - "04-WORKFLOWS/n8n/RAG-001-Telegram-Customer-Service.json"
spec_references: ["C4-001", "RAG-003", "CS-002"]
---

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

### ¿Para quién es este documento?
- ✅ Quieres integrar Telegram como canal de atención al cliente con RAG
- ✅ Necesitas que tu bot responda consultas sobre documentos de clientes (PDFs, manuales, FAQs)
- ✅ Buscas automatizar respuestas vía n8n con aislamiento multi-tenant
- ❌ No necesitas experiencia previa en bots de Telegram

### Checklist de Prerrequisitos
- [ ] Cuenta de Telegram activa
- [ ] Token de bot desde @BotFather
- [ ] Acceso a n8n con workflow RAG configurado
- [ ] Base de conocimiento en Qdrant con `tenant_id`
- [ ] Variables de entorno: `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`, `QDRANT_URL`, `OPENROUTER_API_KEY`

### Tiempo Estimado
| Actividad | Tiempo |
|-----------|--------|
| Crear bot + obtener token | 5 min |
| Configurar webhook en n8n | 10 min |
| Conectar RAG con tenant_id | 15 min |
| Test de consulta RAG | 5 min |
| **Total** | **35 min** |

### Cómo Usar Este Documento
1. **Si es tu primer bot**: Ve a [[#ejemplo-1-crear-bot-para-rag-y-atencion-cliente]]
2. **Si ya tienes bot y quieres RAG**: Ve a [[#ejemplo-2-integrar-qdrant-rag-con-tenant_id]]
3. **Si necesitas workflow n8n completo**: Ve a [[#ejemplo-3-workflow-n8n-para-consulta-rag-via-telegram]]
4. **Si quieres respuestas personalizadas por cliente**: Ve a [[#ejemplo-4-filtrar-conocimiento-por-tenant_id]]
5. **Si tienes errores**: Ve a [[#ejemplo-5-webhook-con-validacion-de-tenant]]

### Qué Hacer Si Falla (Resumen Rápido)
| Error | Causa Probable | Solución Inmediata |
|-------|---------------|-------------------|
| `401 Unauthorized` | Token incorrecto | Regenerar token en @BotFather |
| `tenant_id missing` | Payload sin identificador | Añadir `tenant_id` en webhook n8n |
| `Qdrant connection refused` | URL o puerto incorrecto | Verificar túnel SSH o configuración de red |
| `Rate limit exceeded` | Demasiadas consultas/segundo | Añadir delay en n8n o usar cola |
| `No context found` | Documento no indexado para ese tenant | Verificar ingesta RAG con `tenant_id` |

### Glosario Rápido
| Término | Significado | Ejemplo |
|---------|-------------|---------|
| **tenant_id** | Identificador único del cliente/agencia | `restaurante-pepe`, `clinica-dental-01` |
| **RAG** | Recuperación Aumentada por Generación | IA que responde con TU conocimiento, no genérico |
| **Webhook** | URL que recibe mensajes de Telegram en tiempo real | `https://n8n.tu-dominio.com/webhook/telegram-rag` |
| **Embedding** | Representación vectorial de texto | `qdrant.upsert(points=[{"vector": [0.1, 0.2...]}])` |
| **Callback Query** | Respuesta a botón inline del bot | `{"callback_data": "rag_query:tenant123"}` |

---

## 🎯 Propósito y Alcance

### Propósito
Este documento establece el procedimiento estándar para integrar **bots de Telegram como canal de atención al cliente con RAG**, permitiendo que usuarios finales consulten documentación específica de su tenant (restaurante, clínica, hotel, etc.) mediante IA, con aislamiento estricto de datos y optimización para hardware limitado.

### Alcance Técnico
| Componente | Cubierto | No Cubierto |
|------------|----------|-------------|
| **Creación de bot** | ✅ Token, webhook, commands | ❌ Diseño de avatar del bot |
| **Integración RAG** | ✅ Qdrant + tenant_id + n8n | ❌ Entrenamiento de modelos propios |
| **Multi-tenant** | ✅ Aislamiento por `tenant_id` en queries y logs | ❌ Migración de tenants entre VPS |
| **Atención al cliente** | ✅ Consultas FAQs, booking, estado de pedidos | ❌ Chat humano en vivo |
| **Monitoreo** | ✅ Alertas de salud del bot y RAG | ❌ Métricas de negocio (ventas, conversión) |

### Constraints Aplicadas (C1-C6)
| Constraint | Aplicación en este Skill |
|------------|-------------------------|
| **C1** (RAM ≤4GB) | Limitar `max_workers=2` en procesamiento de embeddings; throttling de consultas RAG |
| **C2** (1 vCPU crítico) | Usar `nice -n 19` para procesos de background; evitar blocking I/O en webhook |
| **C3** (No exponer DB) | Qdrant/MySQL accesibles solo vía túnel SSH o red interna Docker; webhook con autenticación HMAC |
| **C4** (tenant_id obligatorio) | **Todos** los payloads de Telegram → n8n → Qdrant deben incluir `tenant_id`; logs de auditoría con `tenant_id` |
| **C5** (Backup + SHA256) | Backup diario de configs del bot + checksum; logs de conversaciones rotados y verificados |
| **C6** (Sin modelos locales) | Inferencia vía OpenRouter/Qwen; embeddings generados en cloud, no local |

### Objetivos de Negocio Habilitados
1. **Atención 24/7 automatizada**: Clientes consultan FAQs, estado de reservas, menús, sin intervención humana.
2. **Escalabilidad multi-tenant**: Un solo bot/n8n/Qdrant sirve a 15+ agencias con aislamiento estricto.
3. **Reducción de carga operativa**: 80% de consultas repetitivas resueltas por RAG; humanos solo para casos complejos.
4. **Trazabilidad completa**: Cada interacción logueada con `tenant_id` para auditoría y mejora continua.

---

## 📐 Fundamentos (De 0 a Intermedio)

### Arquitectura de Integración Telegram + RAG + n8n

┌─────────────────────────────────────────────────────────────────────┐
│                    FLUJO DE CONSULTA RAG VIA TELEGRAM                │
│                                                                      │
│  [Cliente]                                                           │
│     │                                                                │
│     │ 1. Mensaje: "¿Cuál es el menú de hoy?"                         │
│     ▼                                                                │
│  [Telegram Servers]                                                  │
│     │                                                                │
│     │ 2. Webhook POST                                                │
│     ▼                                                                │
│  [n8n: Webhook Trigger]                                              │
│     │                                                                │
│     │ 3. Extraer: {text, chat_id, tenant_id}                         │
│     ▼                                                                │
│  [n8n: RAG Query Node]                                               │
│     │                                                                │
│     │ 4. Qdrant.search(                                              │
│     │      collection=f"docs_{tenant_id}",                           │
│     │      query_vector=embed(text),                                 │
│     │      filter={"tenant_id": tenant_id}  # ← C4: aislamiento      │
│     │    )                                                           │
│     ▼                                                                │
│  [n8n: LLM Generation Node]                                          │
│     │                                                                │
│     │ 5. Prompt: "Responde como asistente de {tenant_name}..."       │
│     │    + contextos recuperados + historia de chat                  │
│     ▼                                                                │
│  [n8n: Telegram Response Node]                                       │
│     │                                                                │
│     │ 6. sendMessage(chat_id, respuesta_formateada)                  │
│     ▼                                                                │
│  [Cliente recibe respuesta contextualizada]                          │
│                                                                      │
│  🔐 Auditoría: Cada paso loguea tenant_id (C4)                       │
│  ⚡ Optimización: Embeddings cacheados por tenant (C1/C2)            │
└─────────────────────────────────────────────────────────────────────┘


### Modelo de Datos Multi-Tenant para RAG

```yaml
# Colección Qdrant por tenant (ej: restaurante-pepe)
collection_name: "docs_restaurante-pepe"
vectors:
  size: 768  # Modelo de embedding usado
  distance: Cosine
payload_schema:
  tenant_id: { type: keyword, index: true }  # ← Filtro obligatorio (C4)
  doc_type: { type: keyword, index: true }   # "menu", "faq", "booking_policy"
  language: { type: keyword, index: true }   # "es", "pt-BR"
  last_updated: { type: datetime }
  source_file: { type: text }                # Para trazabilidad (C5)
```

### Patrones de Mensajería Soportados

|Patrón                  |Caso de Uso                                   |Ejemplo de Payload                                                            |
|------------------------|----------------------------------------------|------------------------------------------------------------------------------|
|Consulta RAG simple     |"""¿Aceptan tarjetas?"""                      |"{""text"": ""¿Aceptan tarjetas?"", ""tenant_id"": ""restaurante-pepe""}"     |
|Consulta con contexto   |"""Reservar mesa para 4 personas mañana"""    |"{""text"": ""..."", ""tenant_id"": ""..."", ""chat_history"": [...]}"        |
|Acción con botón        |Confirmar reserva                             |"{""callback_data"": ""confirm_booking:restaurante-pepe:12345""}"             |
|Archivo adjunto         |Enviar menú en PDF                            |"{""document"": {""file_id"": ""..."", ""file_name"": ""menu.pdf""}}"         |
|Broadcast segmentado    |Promo para clientes VIP                       |"{""text"": ""..."", ""tenant_id"": ""..."", ""filter"": {""tag"": ""vip""}}" |

---

## 🏗️ Arquitectura y Límites de Hardware (VPS 2vCPU/4-8GB RAM)

```yaml
# docker-compose.rag-telegram.yml (fragmento optimizado C1/C2)
services:
  n8n:
    image: n8nio/n8n:latest
    deploy:
      resources:
        limits:
          memory: 1.5G  # ← C1: 75% de 2GB asignados a n8n
          cpus: '0.75'  # ← C2: máximo 1 vCPU para servicios críticos
    environment:
      - GENERIC_TIMEZONE=America/Sao_Paulo
      - N8N_CONCURRENCY_LIMIT=2  # ← Evitar saturación en VPS pequeño
      - WEBHOOK_URL=https://n8n.tu-dominio.com/webhook

  qdrant:
    image: qdrant/qdrant:v1.8.0
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '0.5'
    volumes:
      - qdrant_data:/qdrant/storage
    command: >
      --service.max_workers 2
      --optimizers.max_optimization_threads 1  # ← C1: limitar CPU en background

  # Túnel SSH para acceso seguro a Qdrant externo (C3)
  ssh-tunnel-qdrant:
    image: alpine:latest
    command: >
      sh -c "apk add openssh-client &&
             ssh -N -L 6333:localhost:6333 user@qdrant-externo.com -i /secrets/ssh_key"
    volumes:
      - ./secrets:/secrets:ro
    restart: unless-stopped
```

### Rate Limits y Throttling Estratégico

|Componente	                |Límite	                                |Justificación SDD                                |
|---------------------------|---------------------------------------|-------------------------------------------------|
|**Telegram Bot API**	    |30 msg/s global, 1 msg/s por chat	    |Evitar bans; cumplir C6 (cloud-only)             |
|**n8n webhook handler**	|10 req/s por tenant	                |Prevenir DoS accidental; cumplir C1 (RAM)        |
|**Qdrant search**	        |5 queries/s por colección	            |Evitar saturación de I/O; cumplir C2 (CPU)       |
|**OpenRouter API**	        |1 req/2s por tenant	                |Control de costos; cumplir C6 (inferencia cloud) |


### Estrategia de Cache para Hardware Limitado
```python
# /opt/mantis/lib/rag_cache.py (snippet optimizado C1/C2)
from functools import lru_cache
import hashlib, time

@lru_cache(maxsize=128)  # ← C1: limitar memoria de cache
def get_cached_embedding(text_hash: str, tenant_id: str):
    """Retorna embedding cacheado si existe y < 24h de antigüedad"""
    cache_key = f"{tenant_id}:{text_hash}"
    # Lógica de recuperación de cache (Redis local o archivo)
    # ...
    return embedding

def embed_with_cache(text: str, tenant_id: str):
    text_hash = hashlib.sha256(text.encode()).hexdigest()
    cached = get_cached_embedding(text_hash, tenant_id)
    if cached:
        return cached  # ← Ahorra CPU y tiempo de inferencia
    # Si no hay cache, generar nuevo embedding (vía API cloud, C6)
    # ... y guardar en cache
```
---

## 🔗 Conexión Local vs Externa / Cross-VPS

### Topología Recomendada para Multi-VPS

┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   VPS-1         │     │   VPS-2         │     │   VPS-3         │
│   (n8n +        │     │   (Qdrant +     │     │   (n8n +        │
│    Telegram)    │     │    MySQL)       │     │    EspoCRM)     │
│                 │     │                 │     │                 │
│  • Webhook      │     │  • Colecciones  │     │  • Webhook      │
│    Telegram     │     │    RAG por      │     │    alternativo  │
│  • Workflow     │     │    tenant       │     │  • Backup de    │
│    RAG-001      │     │  • Aislamiento  │     │    conversaciones│
│                 │     │    C4           │     │                 │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         │  Túnel SSH (C3)       │  Red Docker interna   │  Webhook fallback
         │  :6333 → :6333        │  :5432, :8080         │  :8443
         ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    RED PRIVADA MANTIS                           │
│  • Todos los servicios se comunican vía IPs privadas            │
│  • Webhooks públicos solo con autenticación HMAC (C3)           │
│  • Logs centralizados con tenant_id para auditoría (C4, C5)     │
└─────────────────────────────────────────────────────────────────┘

### Patrón de Webhook Seguro (C3 + C4)

```bash
# /opt/mantis/scripts/validate-telegram-webhook.sh
# Valida que el webhook de Telegram es legítimo y tiene tenant_id

#!/bin/bash
set -euo pipefail

# 1. Verificar firma HMAC (C3: autenticación de origen)
EXPECTED_SIG=$(echo -n "$REQUEST_BODY" | openssl dgst -sha256 -hmac "$TELEGRAM_WEBHOOK_SECRET" | awk '{print $2}')
if [[ "${HTTP_X_TELEGRAM_SIGNATURE:-}" != "$EXPECTED_SIG" ]]; then
    echo "❌ Firma HMAC inválida" >&2
    exit 403
fi

# 2. Extraer y validar tenant_id (C4: obligatorio)
TENANT_ID=$(echo "$REQUEST_BODY" | jq -r '.tenant_id // empty')
if [[ -z "$TENANT_ID" ]]; then
    echo "❌ tenant_id missing en payload" >&2
    # Log para auditoría (C4)
    echo "[$(date -Iseconds)] MISSING_TENANT_ID: $REQUEST_BODY" >> /var/log/mantis/telegram-audit.log
    exit 400
fi

# 3. Validar que el tenant existe en Qdrant (prevención de enumeración)
if ! curl -s "http://qdrant-internal:6333/collections/docs_${TENANT_ID}" | jq -e '.result.status == "green"' > /dev/null; then
    echo "❌ tenant_id no registrado: $TENANT_ID" >&2
    exit 404
fi

# ✅ Validación exitosa: proceder con procesamiento RAG
echo "$REQUEST_BODY" | jq ". + {validated: true, processed_at: \"$(date -Iseconds)\"}"
```

---


## 🛠️ 5 Ejemplos de Implementación (Copy-Paste Validables)


### EJEMPLO 1: Crear Bot para RAG y Atención al Cliente

**Objetivo:** Configurar un bot de Telegram listo para integrar con RAG multi-tenant.
**Nivel:** 🟢 Junior
```bash
# 1. Crear bot con @BotFather
#    - Comando: /newbot
#    - Nombre: "Asistente {NombreCliente}"
#    - Username: "{cliente}_assistant_bot" (debe terminar en _bot)
#    - Guardar TOKEN: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`

# 2. Configurar comandos del bot (mejora UX)
curl -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setMyCommands" \
  -H "Content-Type: application/json" \
  -d '{
    "commands": [
      {"command": "start", "description": "Iniciar asistencia"},
      {"command": "menu", "description": "Ver menú o servicios"},
      {"command": "reservar", "description": "Reservar cita/mesa"},
      {"command": "faq", "description": "Preguntas frecuentes"},
      {"command": "humano", "description": "Hablar con agente humano"}
    ]
  }'

# 3. Guardar credenciales con tenant_id (C4)
echo "TELEGRAM_BOT_TOKEN_restaurante-pepe=\"123456789:ABCdef...\"" >> ~/.env.mantis
echo "TELEGRAM_CHAT_ID_restaurante-pepe=\"-1001234567890\"" >> ~/.env.mantis
echo "TENANT_ID_restaurante-pepe=\"restaurante-pepe\"" >> ~/.env.mantis

# 4. Test básico de envío (validación inicial)
curl -s -X POST \
  "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN_restaurante-pepe}/sendMessage" \
  -d "chat_id=${TELEGRAM_CHAT_ID_restaurante-pepe}" \
  -d "text=✅ Bot de restaurante-pepe listo para RAG. Escribe /faq para probar." \
  -d "parse_mode=HTML"

# 5. Configurar webhook en n8n (C3: seguro)
#    En n8n > Settings > Webhook URL: https://n8n.tu-dominio.com/webhook/telegram-rag
#    Luego registrar en Telegram:
curl -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN_restaurante-pepe}/setWebhook" \
  -d "url=https://n8n.tu-dominio.com/webhook/telegram-rag" \
  -d "secret_token=${TELEGRAM_WEBHOOK_SECRET}"  # ← Autenticación HMAC (C3)
```
**✅ Deberías ver:** Mensaje de confirmación en el chat del bot + webhook registrado ({"ok":true,"result":true}).

**❌ Si ves esto... → Ve a Troubleshooting 1:**

    {"ok":false,"error_code":409,"description":"Conflict: can't set webhook"} → Webhook ya configurado; usa /deleteWebhook primero.

**🔗 Conceptos relacionados:** [[02-SKILLS/INFRAESTRUCTURA/ssh-tunnels-remote-services.md]], [[01-RULES/03-SECURITY-RULES.md]]



### EJEMPLO 2: Integrar Qdrant RAG con tenant_id (C4)

**Objetivo:** Configurar búsqueda RAG en Qdrant con aislamiento estricto por tenant.
**Nivel:** 🟡 Intermedio

```python
# /opt/mantis/lib/rag_qdrant_client.py
from qdrant_client import QdrantClient, models
from sentence_transformers import SentenceTransformer

# Inicializar cliente (vía túnel SSH si Qdrant es externo, C3)
client = QdrantClient(
    host="localhost",  # ← túnel SSH local endpoint
    port=6333,
    https=False,
    timeout=10  # ← C1/C2: timeout corto para no bloquear recursos
)

def rag_query(text: str, tenant_id: str, top_k: int = 3):
    """
    Busca documentos relevantes en Qdrant para un tenant específico.
    
    Args:
        text: Consulta del usuario
        tenant_id: Identificador del cliente (C4: obligatorio)
        top_k: Número de resultados a recuperar
    
    Returns:
        Lista de documentos con metadata
    """
    # 1. Validar tenant_id (C4: defensa en profundidad)
    if not tenant_id or not isinstance(tenant_id, str):
        raise ValueError("tenant_id es obligatorio y debe ser string")
    
    # 2. Generar embedding (usar cache para ahorrar CPU, C1/C2)
    from .rag_cache import embed_with_cache
    query_vector = embed_with_cache(text, tenant_id)
    
    # 3. Buscar en colección específica del tenant (aislamiento C4)
    collection_name = f"docs_{tenant_id}"
    
    results = client.search(
        collection_name=collection_name,
        query_vector=query_vector,
        limit=top_k,
        # Filtro estricto: solo documentos de este tenant (C4)
        query_filter=models.Filter(
            must=[
                models.FieldCondition(
                    key="tenant_id",
                    match=models.MatchValue(value=tenant_id)
                )
            ]
        ),
        # Payload a recuperar: solo lo necesario para el LLM
        with_payload=["content", "doc_type", "source_file", "last_updated"]
    )
    
    # 4. Log para auditoría (C4 + C5)
    import logging, hashlib
    query_hash = hashlib.sha256(f"{tenant_id}:{text}".encode()).hexdigest()
    logging.info(f"RAG_QUERY tenant={tenant_id} hash={query_hash} results={len(results)}")
    
    return [r.payload for r in results]

# Ejemplo de uso en workflow n8n (Python node):
# contexts = rag_query("¿Aceptan reservas para grupos?", tenant_id="restaurante-pepe")
```
**✅ Deberías ver:** Lista de 3 documentos relevantes con tenant_id coincidente.

**❌ Si ves esto... → Ve a Troubleshooting 2:**

    Collection docs_restaurante-pepe not found → El tenant no tiene documentos indexados; ejecutar ingesta RAG primero.

**🔗 Conceptos relacionados:** [[02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md]], [[01-RULES/06-MULTITENANCY-RULES.md]]



### EJEMPLO 3: Workflow n8n para Consulta RAG vía Telegram

**Objetivo:** Crear workflow completo que recibe mensaje de Telegram, consulta RAG y responde.
**Nivel:** 🟡 Intermedio

```json
{
  "name": "RAG-001 Telegram Customer Service",
  "active": true,
  "nodes": [
    {
      "name": "Telegram Webhook",
      "type": "n8n-nodes-base.telegramTrigger",
      "parameters": {
        "updates": ["message", "callback_query"],
        "additionalFields": {
          "allowed_updates": ["message", "callback_query"]
        }
      },
      "webhookId": "telegram-rag"
    },
    {
      "name": "Extract & Validate",
      "type": "n8n-nodes-base.function",
      "parameters": {
        "functionCode": "// Validar y extraer datos (C4: tenant_id)\nconst body = $input.all()[0].json;\n\n// Extraer tenant_id de chat_id o payload\nconst tenant_id = body.tenant_id || \n  (body.message?.chat?.id ? `tenant_${body.message.chat.id}` : null);\n\nif (!tenant_id) {\n  throw new Error('tenant_id missing - C4 violation');\n}\n\n// Extraer texto de la consulta\nconst text = body.message?.text || \n  body.callback_query?.data?.replace('rag_query:', '') || '';\n\nreturn [{\n  json: {\n    tenant_id,\n    text,\n    chat_id: body.message?.chat?.id || body.callback_query?.message?.chat?.id,\n    message_id: body.message?.message_id,\n    callback_query_id: body.callback_query?.id,\n    timestamp: new Date().toISOString()\n  }\n}];"
      }
    },
    {
      "name": "RAG Query Qdrant",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "method": "POST",
        "url": "http://qdrant-internal:6333/collections/docs_{{ $json.tenant_id }}/points/search",
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            { "name": "vector", "value": "={{ $json.embedding }}" },
            { "name": "limit", "value": "3" },
            { "name": "with_payload", "value": "true" },
            { "name": "filter", "value": "={\"must\":[{\"key\":\"tenant_id\",\"match\":{\"value\":\"{{ $json.tenant_id }}\"}}]}" }
          ]
        },
        "options": { "timeout": 5000 }  // ← C1/C2: timeout corto
      }
    },
    {
      "name": "LLM Generation (OpenRouter)",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "method": "POST",
        "url": "https://openrouter.ai/api/v1/chat/completions",
        "headers": {
          "Authorization": "Bearer {{ $env.OPENROUTER_API_KEY }}",
          "HTTP-Referer": "https://mantis-agentic.dev",
          "X-Title": "Mantis RAG Telegram"
        },
        "sendBody": true,
        "bodyParameters": {
          "parameters": [
            { "name": "model", "value": "openrouter/qwen/qwen-2.5-coder-32b-instruct:free" },
            { "name": "messages", "value": "=[{\"role\":\"system\",\"content\":\"Eres asistente de {{$json.tenant_id}}. Responde solo con información de los contextos proporcionados. Si no sabes, di que consultarás con un humano.\"},{\"role\":\"user\",\"content\":\"Pregunta: {{$json.text}}\\n\\nContextos relevantes:\\n{{ $json.rag_contexts }}\"}]" },
            { "name": "max_tokens", "value": "500" },  // ← C1: limitar output para ahorrar tokens
            { "name": "temperature", "value": "0.3" }   // ← Respuestas consistentes para atención al cliente
          ]
        }
      }
    },
    {
      "name": "Send Telegram Response",
      "type": "n8n-nodes-base.telegram",
      "parameters": {
        "operation": "sendMessage",
        "chatId": "={{ $json.chat_id }}",
        "text": "={{ $json.llm_response }}",
        "additionalFields": {
          "parse_mode": "Markdown",
          "reply_to_message_id": "={{ $json.message_id }}"
        }
      },
      "credentials": {
        "telegramApi": {
          "id": "telegram_api_{{$json.tenant_id}}",
          "name": "Telegram API - {{$json.tenant_id}}"
        }
      }
    },
    {
      "name": "Audit Log (C4+C5)",
      "type": "n8n-nodes-base.function",
      "parameters": {
        "functionCode": "// Log para auditoría con tenant_id (C4) y timestamp (C5)\nconst logEntry = {\n  timestamp: new Date().toISOString(),\n  tenant_id: $input.all()[0].json.tenant_id,\n  query_hash: require('crypto').createHash('sha256').update($input.all()[0].json.text).digest('hex'),\n  response_length: $input.all()[0].json.llm_response?.length || 0,\n  status: 'success'\n};\n\n// Escribir en archivo rotativo (C5: backup de logs)\nconst fs = require('fs');\nconst logPath = `/var/log/mantis/rag-telegram-${logEntry.tenant_id}.jsonl`;\nfs.appendFileSync(logPath, JSON.stringify(logEntry) + '\\n');\n\nreturn $input.all();"
      }
    }
  ],
  "connections": {
    "Telegram Webhook": { "main": [["Extract & Validate"]] },
    "Extract & Validate": { "main": [["RAG Query Qdrant"]] },
    "RAG Query Qdrant": { "main": [["LLM Generation (OpenRouter)"]] },
    "LLM Generation (OpenRouter)": { "main": [["Send Telegram Response", "Audit Log (C4+C5)"]] },
    "Send Telegram Response": { "main": [["Audit Log (C4+C5)"]] }
  }
}
```

**✅ Deberías ver:** Respuesta en Telegram con información contextualizada del tenant, y entrada en /var/log/mantis/rag-telegram-{tenant_id}.jsonl.

**❌ Si ves esto... → Ve a Troubleshooting 3:**

    tenant_id missing - C4 violation → El payload de Telegram no incluye tenant_id; revisar extracción en nodo "Extract & Validate".

**🔗 Conceptos relacionados:** [[04-WORKFLOWS/n8n/RAG-001-Telegram-Customer-Service.json]], [[01-RULES/06-MULTITENANCY-RULES.md]]



### EJEMPLO 4: Filtrar Conocimiento por tenant_id (Aislamiento C4)

**Objetivo:** Garantizar que un cliente solo accede a su propia documentación, nunca a la de otros tenants.
**Nivel:** 🔴 Avanzado

```python
# /opt/mantis/lib/rag_security.py
"""
Módulo de seguridad para RAG: validación de tenant_id y prevención de fuga de datos.
Cumple C4 (aislamiento) y C3 (no exponer datos entre tenants).
"""
import re, logging
from typing import Optional

# Patrón seguro para tenant_id: solo minúsculas, guiones, dígitos (prevención de inyección)
TENANT_ID_PATTERN = re.compile(r'^[a-z0-9\-]{3,50}$')

def validate_tenant_id(tenant_id: Optional[str]) -> bool:
    """Valida que tenant_id cumple formato seguro (defensa en profundidad C4)."""
    if not tenant_id or not isinstance(tenant_id, str):
        return False
    if not TENANT_ID_PATTERN.match(tenant_id):
        logging.warning(f"tenant_id inválido (formato): {tenant_id}")
        return False
    # Lista negra de tenant_ids reservados (prevención de enumeración)
    if tenant_id in ['admin', 'system', 'mantis', 'all', '*']:
        logging.warning(f"tenant_id reservado intentado: {tenant_id}")
        return False
    return True

def build_qdrant_filter(tenant_id: str, additional_filters: Optional[dict] = None) -> dict:
    """
    Construye filtro de Qdrant con tenant_id obligatorio + filtros opcionales.
    
    Args:
        tenant_id: Identificador validado del cliente
        additional_filters: Filtros adicionales (doc_type, language, etc.)
    
    Returns:
        Dict compatible con Qdrant Filter API
    """
    # Validación estricta (C4: nunca confiar en input externo)
    if not validate_tenant_id(tenant_id):
        raise ValueError(f"tenant_id no válido: {tenant_id}")
    
    # Filtro base: tenant_id obligatorio (C4)
    must_conditions = [
        {
            "key": "tenant_id",
            "match": {"value": tenant_id}
        }
    ]
    
    # Añadir filtros adicionales si existen
    if additional_filters:
        for key, value in additional_filters.items():
            must_conditions.append({
                "key": key,
                "match": {"value": value}
            })
    
    return {"must": must_conditions}

# Ejemplo de uso en workflow:
# filter = build_qdrant_filter(
#     tenant_id="restaurante-pepe",
#     additional_filters={"doc_type": "menu", "language": "es"}
# )
# results = qdrant.search(collection="docs_restaurante-pepe", query_vector=..., query_filter=filter)
```

**✅ Deberías ver:** Filtro Qdrant que incluye tenant_id obligatorio + filtros adicionales, listo para usar en búsqueda.

**❌ Si ves esto... → Ve a Troubleshooting 4:**

    ValueError: tenant_id no válido → El tenant_id no cumple patrón seguro; revisar origen del dato (webhook, base de datos, etc.).

**🔗 Conceptos relacionados:** [[01-RULES/06-MULTITENANCY-RULES.md#patrones-de-aislamiento]], [[02-SKILLS/BASE DE DATOS-RAG/multi-tenant-data-isolation.md]]



### EJEMPLO 5: Webhook con Validación de tenant y HMAC (C3 + C4)

**Objetivo:** Implementar webhook seguro que valida origen (HMAC) y tenant_id antes de procesar.
**Nivel:** 🔴 Avanzado

```bash
#!/usr/bin/env python3
# /opt/mantis/webhooks/telegram-rag-handler.py
"""
Webhook handler para Telegram + RAG con validación de seguridad (C3, C4).
Debe ser ejecutado por n8n o como servicio independiente con autenticación.
"""
import os, sys, json, hmac, hashlib, logging
from flask import Flask, request, abort, jsonify
from pathlib import Path

# Configuración
app = Flask(__name__)
WEBHOOK_SECRET = os.getenv('TELEGRAM_WEBHOOK_SECRET', '')  # ← C3: secreto compartido
ALLOWED_TENANTS = json.loads(os.getenv('ALLOWED_TENANTS_JSON', '[]'))  # ← C4: whitelist de tenants

# Validar configuración al inicio (fail-fast)
if not WEBHOOK_SECRET:
    logging.error("TELEGRAM_WEBHOOK_SECRET no configurado (C3 violation)")
    sys.exit(1)
if not ALLOWED_TENANTS:
    logging.warning("ALLOWED_TENANTS_JSON vacío: cualquier tenant_id válido será aceptado")

def verify_hmac_signature(payload: bytes, signature: str) -> bool:
    """Verifica firma HMAC del webhook (C3: autenticación de origen)."""
    expected = hmac.new(
        WEBHOOK_SECRET.encode(),
        payload,
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(expected, signature)

@app.route('/webhook/telegram-rag', methods=['POST'])
def telegram_rag_webhook():
    # 1. Validar firma HMAC (C3)
    signature = request.headers.get('X-Telegram-Signature', '')
    if not verify_hmac_signature(request.data, signature):
        logging.warning(f"HMAC inválido desde {request.remote_addr}")
        abort(403, description="Invalid signature")
    
    # 2. Parsear payload
    try:
        payload = request.get_json(force=True)
    except Exception as e:
        logging.error(f"JSON parse error: {e}")
        abort(400, description="Invalid JSON")
    
    # 3. Extraer y validar tenant_id (C4)
    tenant_id = payload.get('tenant_id')
    if not tenant_id or tenant_id not in ALLOWED_TENANTS:
        logging.warning(f"tenant_id no autorizado: {tenant_id} (allowed: {ALLOWED_TENANTS})")
        abort(403, description="Unauthorized tenant")
    
    # 4. Validar tipo de mensaje (solo texto o callback para RAG)
    message = payload.get('message', {})
    callback = payload.get('callback_query', {})
    
    if message and 'text' in message:
        query_text = message['text']
        chat_id = message['chat']['id']
    elif callback and 'data' in callback:
        # Extraer query de callback_data: "rag_query:tenant123:¿Cuál es el menú?"
        parts = callback['data'].split(':', 2)
        if len(parts) != 3 or parts[0] != 'rag_query':
            abort(400, description="Invalid callback format")
        query_text = parts[2]
        chat_id = callback['message']['chat']['id']
    else:
        # Ignorar mensajes no textuales (fotos, ubicación, etc.)
        return jsonify({"ok": True, "ignored": "non-text message"}), 200
    
    # 5. Preparar payload para n8n / RAG pipeline
    processed = {
        "tenant_id": tenant_id,
        "query": query_text,
        "chat_id": chat_id,
        "message_id": message.get('message_id') or callback.get('message', {}).get('message_id'),
        "timestamp": payload.get('message', {}).get('date') or callback.get('message', {}).get('date'),
        "validated": True  # ← Marca para nodos downstream
    }
    
    # 6. Log de auditoría (C4 + C5)
    logging.info(f"WEBHOOK_VALIDATED tenant={tenant_id} query_hash={hashlib.sha256(query_text.encode()).hexdigest()}")
    
    # 7. Retornar para procesamiento por n8n (webhook response)
    return jsonify(processed), 200

if __name__ == '__main__':
    # Ejecutar solo en entorno controlado (C3: no exponer directamente a internet)
    if os.getenv('ENVIRONMENT') != 'production':
        app.run(host='127.0.0.1', port=5000, debug=True)
    else:
        # En producción, este script debe estar detrás de nginx con SSL y rate limiting
        logging.info("Webhook handler listo (ejecutar detrás de nginx con SSL)")
```

**✅ Deberías ver:** Respuesta 200 OK con payload procesado cuando se envía un mensaje válido con firma HMAC correcta.

**❌ Si ves esto... → Ve a Troubleshooting 5:**

    403 Invalid signature → El secreto HMAC no coincide; verificar TELEGRAM_WEBHOOK_SECRET en Telegram y en el servidor.

**🔗 Conceptos relacionados:** [[01-RULES/03-SECURITY-RULES.md#webhooks-seguros]], [[02-SKILLS/INFRAESTRUCTURA/ssh-tunnels-remote-services.md]]


---

## 🐞 5 Eventos/Problemas Críticos y Troubleshooting

|Error Exacto (copiable)	                                    |Causa Raíz (lenguaje simple)	                                 |Comando de Diagnóstico	                                                    |Solución Paso a Paso	                                                                                                                                                                                                                                                                                   |Constraint Afectado (C#)|
|---------------------------------------------------------------|----------------------------------------------------------------|------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------|
|`{"ok":false,"error_code":401,"description":"Unauthorized"}`	|Token de bot incorrecto o revocado	                             |`curl -s "https://api.telegram.org/bot${TOKEN}/getMe" | jq .`	                |1. Ir a @BotFather → /mybots → seleccionar bot → /revoke para regenerar token<br>2. Actualizar `TELEGRAM_BOT_TOKEN_{tenant}` en `.env`<br>3. Reiniciar n8n o servicio que usa el token	                                                                                                                   |C4                      |
|`tenant_id missing - C4 violation`	                            |Payload de webhook no incluye `tenant_id` o está mal extraído	 |`echo "$RAW_PAYLOAD" | jq '.tenant_id'`	                                    |1. Verificar que el frontend (app móvil, web) envía `tenant_id` en el payload<br>2. Revisar nodo "Extract & Validate" en n8n: ¿extrae `tenant_id` de `chat_id` o de campo explícito?<br>3. Añadir logging temporal para depurar: `console.log("Payload:", $input.all()[0].json)`	                       |C4                      |
|`Collection docs_{tenant_id} not found`                     	|El tenant no tiene documentos indexados en Qdrant	             |`curl -s "http://qdrant:6333/collections" | jq '.result[].name' | grep docs_`	|1. Verificar que el proceso de ingesta RAG se ejecutó para este tenant<br>2. Ejecutar manualmente: `python3 /opt/mantis/scripts/rag-ingest.py --tenant {tenant_id} --source /path/to/docs`<br>3. Confirmar en Qdrant: `curl "http://qdrant:6333/collections/docs_{tenant_id}/points/count"`	           |C4                      |
|`403 Forbidden: tenant not in ALLOWED_TENANTS`	                |tenant_id no está en la whitelist de configuración	             |`echo "$ALLOWED_TENANTS_JSON" | jq .`	                                        |1. Añadir tenant_id a la variable de entorno `ALLOWED_TENANTS_JSON`<br>2. Formato: `["restaurante-pepe","clinica-dental-01",...]`<br>3. Reiniciar el servicio webhook para cargar nueva config<br>4. Validar con: `curl -X POST ... -d '{"tenant_id":"nuevo-tenant"}'`	                                   |C4                      |
|`Timeout waiting for Qdrant response`	                        |Qdrant no responde en el tiempo límite (red, recursos, carga)	 |`timeout 5 curl -s "http://qdrant:6333/healthz" | jq .`	                    |1. Verificar conectividad de red: `ping qdrant` o túnel SSH activo<br>2. Revisar recursos de Qdrant: `docker stats qdrant` (¿CPU/RAM al límite?)<br>3. Aumentar timeout en n8n solo si es necesario (C1/C2: no exceder límites)<br>4. Implementar retry con backoff exponencial en el nodo HTTP Request   |C1, C2                  |


### Troubleshooting Detallado 1: tenant_id missing (C4)

**Diagnóstico paso a paso:**
```bash
# 1. Capturar payload raw del webhook (para debug)
# En n8n: añadir nodo "Debug" después de "Telegram Webhook" con:
# {{ JSON.stringify($input.all()[0].json, null, 2) }}

# 2. Verificar estructura esperada:
{
  "update_id": 123456,
  "message": {
    "chat": {"id": 987654, "type": "private"},
    "text": "¿Cuál es el menú?",
    "date": 1712650000
  },
  "tenant_id": "restaurante-pepe"  # ← ¡Este campo es obligatorio!
}

# 3. Si falta tenant_id, rastrear origen:
#    a) ¿El frontend (app/web) lo envía?
#    b) ¿Se extrae de chat_id mediante mapeo?
#    c) ¿Hay un middleware que lo inyecta?

# 4. Solución común: añadir tenant_id en el frontend antes de enviar a Telegram webhook
# Ejemplo en JavaScript (frontend):
const payload = {
  message: telegramMessage,
  tenant_id: getCurrentTenantId() // ← Función que obtiene tenant del contexto de usuario
};
fetch('/webhook/telegram-rag', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify(payload)
});
```

---

## ✅ Validación SDD y Comandos de Verificación

### Checklist de Validación Automática

```bash
#!/bin/bash
# /opt/mantis/scripts/validate-telegram-rag-integration.sh
# Valida configuración completa de Telegram + RAG con enfoque C1-C6

set -euo pipefail
TENANT_ID="${1:-}"  # Argumento opcional: validar tenant específico

echo "=== Validación Telegram RAG - Mantis Agentic ==="
echo "Tenant: ${TENANT_ID:-all}"
echo ""

ERRORS=0

# 1. Validar variables de entorno (C3, C4)
for var in TELEGRAM_BOT_TOKEN TELEGRAM_WEBHOOK_SECRET OPENROUTER_API_KEY; do
  if [[ -z "${!var:-}" ]]; then
    echo "❌ $var no está definido en entorno"
    ERRORS=$((ERRORS+1))
  else
    echo "✅ $var está definido"
  fi
done

# 2. Validar formato de tenant_id si se especifica (C4)
if [[ -n "$TENANT_ID" ]]; then
  if ! [[ "$TENANT_ID" =~ ^[a-z0-9\-]{3,50}$ ]]; then
    echo "❌ tenant_id no cumple formato seguro: $TENANT_ID"
    ERRORS=$((ERRORS+1))
  else
    echo "✅ tenant_id formato válido: $TENANT_ID"
  fi
fi

# 3. Test de conectividad a Qdrant (C3: red interna)
if ! timeout 5 curl -s "http://qdrant-internal:6333/healthz" | jq -e '.status == "ok"' > /dev/null 2>&1; then
  echo "❌ Qdrant no responde en endpoint interno"
  ERRORS=$((ERRORS+1))
else
  echo "✅ Qdrant accesible vía red interna"
fi

# 4. Test de bot de Telegram (solo si TENANT_ID especificado)
if [[ -n "$TENANT_ID" ]]; then
  TOKEN_VAR="TELEGRAM_BOT_TOKEN_${TENANT_ID//-/_}"
  CHAT_VAR="TELEGRAM_CHAT_ID_${TENANT_ID//-/_}"
  
  if [[ -n "${!TOKEN_VAR:-}" && -n "${!CHAT_VAR:-}" ]]; then
    TEST_RESULT=$(curl -s -X POST \
      "https://api.telegram.org/bot${!TOKEN_VAR}/sendMessage" \
      -d "chat_id=${!CHAT_VAR}" \
      -d "text=🧪 Test RAG - tenant: ${TENANT_ID}" \
      -d "parse_mode=HTML")
    
    if echo "$TEST_RESULT" | jq -e '.ok == true' > /dev/null 2>&1; then
      echo "✅ Mensaje de test enviado a Telegram (tenant: ${TENANT_ID})"
    else
      ERROR_DESC=$(echo "$TEST_RESULT" | jq -r '.description')
      echo "❌ Error al enviar: ${ERROR_DESC}"
      ERRORS=$((ERRORS+1))
    fi
  else
    echo "⚠️  Variables de Telegram no definidas para tenant: ${TENANT_ID}"
  fi
fi

# 5. Validar logs de auditoría (C4 + C5)
LOG_FILE="/var/log/mantis/rag-telegram-${TENANT_ID:-all}.jsonl"
if [[ -f "$LOG_FILE" ]]; then
  LAST_ENTRY=$(tail -1 "$LOG_FILE" | jq -r '.timestamp // "unknown"')
  echo "ℹ️  Último log de auditoría: ${LAST_ENTRY}"
else
  echo "ℹ️  Archivo de logs no existe aún (se creará en primera consulta)"
fi

echo ""
if [[ $ERRORS -eq 0 ]]; then
  echo "🎉 Validación Telegram RAG: TODOS LOS CHECKS PASARON"
  exit 0
else
  echo "❌ Validación Telegram RAG: $ERRORS ERRORES ENCONTRADOS"
  exit 1
fi
```

### Comandos de Verificación Rápida

```bash
# Test de bot (sin tenant específico)
curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe" | jq .

# Test de webhook HMAC (simular payload)
echo '{"tenant_id":"test","message":{"text":"hello","chat":{"id":123}}}' | \
  openssl dgst -sha256 -hmac "$TELEGRAM_WEBHOOK_SECRET" | \
  xargs -I SIG curl -s -X POST http://localhost:5000/webhook/telegram-rag \
    -H "Content-Type: application/json" \
    -H "X-Telegram-Signature: $SIG" \
    -d @-

# Verificar colecciones Qdrant por tenant
curl -s "http://qdrant:6333/collections" | jq '.result[].name | select(startswith("docs_"))'

# Monitorear logs de auditoría en tiempo real
tail -f /var/log/mantis/rag-telegram-*.jsonl | jq -c '{tenant: .tenant_id, time: .timestamp}'
```

---

## 🔗 Referencias Cruzadas y Glosario

### Archivos Relacionados (Wikilinks para IA)

|Archivo	                                                        |Descripción	                            |Relevancia para este Skill                              |
|-------------------------------------------------------------------|-------------------------------------------|--------------------------------------------------------|
|[[01-RULES/04-API-RELIABILITY-RULES.md]]	                        |Timeouts, retries, fallbacks de APIs	    |C6: manejo de errores en llamadas a OpenRouter/Telegram |
|[[01-RULES/06-MULTITENANCY-RULES.md]]	                            |Patrones de aislamiento de datos	        |C4: filtro `tenant_id` en todas las queries RAG         |
|[[02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md]]	        |Ingesta de documentos en Qdrant	        |Prerrequisito: documentos indexados con `tenant_id`     |
|[[02-SKILLS/INFRAESTRUCTURA/vps-interconnection.md]]	            |Conexión segura entre VPS	                |C3: túneles SSH para Qdrant externo                     |
|[[04-WORKFLOWS/n8n/RAG-001-Telegram-Customer-Service.json]]	    |Workflow n8n completo	                    |Implementación de referencia para copiar/adaptar        |
|[[01-RULES/03-SECURITY-RULES.md#webhooks-seguros]]	                |Validación HMAC para webhooks	            |C3: autenticación de origen en webhook Telegram         |


### Glosario Técnico Ampliado

|Término	             |Definición	                                                                                                        |Contexto de Uso                                                              |
|------------------------|----------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------|
|**tenant_id**         	 |Identificador único, inmutable y seguro de un cliente/agencia	                                                        |Clave primaria para aislamiento de datos (C4); formato: `^[a-z0-9\-]{3,50}$` |
|**RAG**	             |Retrieval-Augmented Generation: IA que responde usando documentos específicos del tenant, no conocimiento genérico	|Consultas de clientes: "¿Cuál es el menú?", "¿Aceptan tarjetas?"             |
|**Embedding**	         |Representación vectorial de texto usada para búsqueda semántica en Qdrant	                                            |`qdrant.search(query_vector=embed(query_text), ...)`                         |
|**Webhook HMAC**	     |Firma criptográfica que valida que el webhook viene de Telegram legítimo	                                            |`X-Telegram-Signature` header; prevenir spoofing (C3)                        |
|**Callback Query**	     |Respuesta a botón inline en mensaje de Telegram	                                                                    |`{"callback_data": "rag_query:tenant123:¿Menú vegetariano?"}`                |
|**Payload sanitizado**	 |Datos de entrada limpios de caracteres peligrosos antes de procesar	                                                |Prevenir inyección en queries Qdrant o logs                                  |
|**Audit log rotativo**	 |Archivo de logs que se rota diariamente con checksum SHA256	                                                        |Cumplimiento C5: trazabilidad y recuperación ante fallos                     |

### Variables de Entorno Obligatorias

```bash
# ~/.env.mantis (por tenant o global)
# --- Telegram ---
TELEGRAM_BOT_TOKEN_restaurante-pepe="123456789:ABCdef..."
TELEGRAM_CHAT_ID_restaurante-pepe="-1001234567890"
TELEGRAM_WEBHOOK_SECRET="super-secret-hmac-key-change-me"

# --- RAG / Qdrant ---
QDRANT_URL="http://qdrant-internal:6333"  # ← red interna, no público (C3)
QDRANT_COLLECTION_PREFIX="docs_"

# --- LLM / Inferencia ---
OPENROUTER_API_KEY="sk-or-v1-..."  # ← C6: inferencia cloud-only
LLM_MODEL="openrouter/qwen/qwen-2.5-coder-32b-instruct:free"

# --- Multi-tenant ---
ALLOWED_TENANTS_JSON='["restaurante-pepe","clinica-dental-01","hotel-playa"]'
TENANT_CONFIG_DIR="/opt/mantis/config/tenants"  # ← configs por tenant aisladas
```

### URLs Raw para IAs (Acceso Directo a Documentación)

Base: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/

https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/02-SKILLS/COMUNICACION/telegram-bot-integration.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/02-SKILLS/BASE%20DE%20DATOS-RAG/qdrant-rag-ingestion.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/01-RULES/06-MULTITENANCY-RULES.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/04-WORKFLOWS/n8n/RAG-001-Telegram-Customer-Service.json

FIN DEL ARCHIVO  
<!-- ai:file-end marker - do not remove -->  
Versión 2.0.0 - 2026-04-09 - Mantis-AgenticDev
Licencia: Creative Commons BY-NC-SA 4.0 para uso interno del proyecto
Auditoría: Cada interacción loguea tenant_id (C4) + timestamp + checksum (C5)
