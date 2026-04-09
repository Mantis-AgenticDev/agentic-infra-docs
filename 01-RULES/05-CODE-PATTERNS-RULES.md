---
version: 1.0.0
last_validated: 2026-04-05
spec_type: code_patterns
validation_script: 05-CONFIGURATION/SCRIPTS/validate-against-specs.sh
description: Patrones de código ejecutables para n8n, SQL y configuración. Especificación base para generación IA.
---

## 📌 PRINCIPIOS ABSOLUTOS (No Negociables)
| ID         | Regla                                             | Implementación                                                                  |
|------------|---------------------------------------------------|---------------------------------------------------------------------------------|
| **C1**     | Máx 4GB RAM/VPS → n8n ≤ 1.5GB                     | `memory: "1500M"` en docker-compose. Contextos ≤ 40 mensajes.                   |
| **C2**     | Máx 1 vCPU                                        | Sin paralelismo pesado. Timeouts ≤ 30s. Backoff exponencial.                    |
| **C3**     | MySQL/Qdrant NUNCA en `0.0.0.0`                   | Solo red interna Docker. Variables `${DB_HOST}`, `${QDRANT_HOST}`.              |
| **C4**     | `tenant_id` OBLIGATORIO en TODA consulta/registro | Inyectado en headers, WHERE, claves Redis, logs y payloads.                     |
| **C5**     | Backup diario 04:00 + AES-256 + SHA256            | Script externo. No se codifica en workflows.                                    |
| **C6**     | Sin modelos locales                               | Solo `openRouterApi` o `openAiApi` cloud. Validador rechaza `ollama`/`localai`. |
| **SDD-01** | Spec > Código                                     | Ningún workflow se genera sin referencia a este archivo.                        |
| **SDD-02** | Validación pre-commit                             | `validate-against-specs.sh` debe retornar `exit 0`.                             |

---

## 🧩 PATRONES N8N (WORKFLOWS)

### PAT-001: Estructura Base de Workflow
Todo workflow debe contener metadatos SDD, nodos de documentación en-canvas y `active: false` por defecto.
```json
{
  "name": "[DOMAIN]-[ACTION]-v1",
  "meta": { "templateCredsSetupCompleted": false, "sdd_validated": true },
  "active": false,
  "settings": { "executionOrder": "v1", "timezone": "America/Sao_Paulo" },
  "nodes": [
    {
      "type": "n8n-nodes-base.stickyNote",
      "parameters": { "content": "# 📋 Spec: 05-CODE-PATTERNS-RULES.md#PAT-001\nObjetivo | Inputs | Outputs" }
    }
  ],
  "connections": {}
}
```

**Validación:** validate_markdown_structure + validate_n8n_patterns


### PAT-002: Nodo HTTP Request con Timeouts & Backoff
Obligatorio en toda llamada a API externa (OpenRouter, UazAPI, CRM, etc.)
```json
{
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "method": "POST",
    "url": "={{ $json.api_endpoint }}",
    "timeout": 30000,
    "retryOnFail": true,
    "maxTries": 3,
    "retryInterval": 5000,
    "headers": {
      "tenant-id": "={{ $input.first().json.tenant_id }}",
      "Authorization": "={{ $env.OPENROUTER_API_KEY }}"
    },
    "onError": "continueErrorOutput"
  }
}
```

**Regla:** timeout debe ser ≤ 30000. Headers deben incluir tenant-id. Credenciales SIEMPRE vía ${ENV_VAR}.


### PAT-003: Agente IA con Output Parser Estructurado
Garantiza respuestas JSON consumibles por downstream nodes.
```json
{
  "type": "@n8n/n8n-nodes-langchain.agent",
  "parameters": {
    "text": "={{ $json.user_message }}",
    "options": {
      "systemMessage": "=# ROL\nEres un agente especializado en [DOMINIO].\n# RESTRICCIONES\n- Responde SOLO en formato JSON válido.\n- Incluye siempre tenant_id en la respuesta.\n# FORMATO\n{ \"tenant_id\": \"string\", \"result\": \"string\", \"status\": \"success|error\" }"
    },
    "hasOutputParser": true
  }
}
```

**Nodo complementario obligatorio:** @n8n/n8n-nodes-langchain.outputParserStructured con schema explícito.


### PAT-004: Manejo de Errores en Function Nodes (JS)
```javascript
try {
  const input = $input.first().json;
  // Lógica segura
  const result = processSecurely(input);
  return [{ json: { ...result, tenant_id: input.tenant_id } }];
} catch (error) {
  console.error(`[ERROR][tenant:${$input.first().json.tenant_id}] ${error.message}`);
  return [{ json: { error: error.message, tenant_id: $input.first().json.tenant_id, status: "failed" } }];
}
```

**Regla:** Nunca throw sin capturar. Siempre registrar tenant_id en logs.


### PAT-005: Enrutamiento Multi-Modal (Texto/Audio/Imagen/Ubicación)
Patrón de Switch → Normalización → Agente Único.
```json
{
  "type": "n8n-nodes-base.switch",
  "parameters": {
    "rules": {
      "values": [
        { "conditions": { "leftValue": "={{ $json.messageType }}", "operator": "equals", "rightValue": "text" } },
        { "conditions": { "leftValue": "={{ $json.messageType }}", "operator": "equals", "rightValue": "audio" } },
        { "conditions": { "leftValue": "={{ $json.messageType }}", "operator": "equals", "rightValue": "image" } }
      ]
    }
  }
}
```

**Flujo:** Audio → Transcripción (OpenAI Whisper) → Texto. Imagen → Descripción (Vision/Gemini) → Texto. 
Todo converge a payload estandarizado: `{ tenant_id, text, source: "text|transcribed|vision" }`.


### PAT-006: Gestión de Memoria & Sesiones
```json
{
  "type": "@n8n/n8n-nodes-langchain.memoryPostgresChat",
  "parameters": {
    "sessionKey": "={{ $json.tenant_id }}:{{ $json.chat_id }}",
    "sessionIdType": "customKey",
    "contextWindowLength": 40
  }
}
```

**Constraints:** TTL Redis/Postgres ≤ 3600s. contextWindowLength ≤ 40 para respetar C1 (RAM).


### PAT-007: Webhook Response & Procesamiento Asíncrono
Evita timeouts en VPS de 1 vCPU cuando la IA tarda > 10s.
```json
{
  "type": "n8n-nodes-base.respondToWebhook",
  "parameters": {
    "respondWith": "json",
    "responseBody": "={{ JSON.stringify({ status: 'processing', tenant_id: $input.first().json.tenant_id }) }}"
  }
}
```

**Flujo:** Webhook → Responde 200 inmediatamente → Dispara sub-workflow en background → Notifica vía WhatsApp/Telegram al completar.

---

## 🗄️ PATRONES SQL & MULTITENANCY

### SQL-001: Migration Base con tenant_id
```sql
CREATE TABLE IF NOT EXISTS interactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id VARCHAR(50) NOT NULL,
  chat_id VARCHAR(100) NOT NULL,
  message_type VARCHAR(20) NOT NULL CHECK (message_type IN ('text','audio','image','location')),
  content TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
CREATE INDEX idx_tenant_chat_time ON interactions(tenant_id, chat_id, created_at DESC);
```

**Regla:** tenant_id SIEMPRE NOT NULL. Índices compuestos obligatorios para consultas por tenant.


### SQL-002: Consultas Seguras (Prepared Statements)
```sql
-- ✅ VÁLIDO
SELECT content, created_at FROM interactions WHERE tenant_id = ? AND chat_id = ? ORDER BY created_at DESC LIMIT 40;

-- ❌ RECHAZADO POR VALIDADOR
SELECT * FROM interactions WHERE chat_id = '{{ $json.chat_id }}';
```

**Regla:**  Nunca interpolación directa de variables en queries. Siempre ? o $N.


### SQL-003: Upsert & Soft Deletes
```sql
INSERT INTO interactions (tenant_id, chat_id, message_type, content)
VALUES (?, ?, ?, ?)
ON CONFLICT (tenant_id, chat_id, id) DO UPDATE SET content = EXCLUDED.content, updated_at = NOW();
```

** Nota:** No se permiten DELETE físicos en producción. Usar status = 'archived' o triggers de auditoría.

---

## ⚙️ PATRONES DE CONFIGURACIÓN & DEPLOY

### ENV-001: Variables de Entorno Seguras (.env.example)
```env
# 🔑 APIs
OPENROUTER_API_KEY=
UAZAPI_WEBHOOK_SECRET=
ESPOCRM_API_KEY=

# 🗄️ DB
MYSQL_HOST=db.internal
MYSQL_PORT=3306
MYSQL_DATABASE=mantis_db
MYSQL_USER=mantis_app
MYSQL_PASSWORD=

# 🧠 Vector
QDRANT_HOST=qdrant.internal
QDRANT_PORT=6333
QDRANT_API_KEY=

# ⚙️ Runtime
NODE_ENV=production
N8N_ENCRYPTION_KEY=
N8N_SECURE_COOKIE=true
TENANT_ID_REGEX=^[a-z0-9_-]{4,32}$
```
**Regla:** Validador rechaza archivos con claves reales. Solo PLACEHOLDER o vacío.


### DOCKER-001: Límites de Recursos (C1/C2)
```yaml
services:
  n8n:
    image: n8nio/n8n:latest
    deploy:
      resources:
        limits:
          cpus: "1.0"
          memory: 1500M
        reservations:
          cpus: "0.25"
          memory: 256M
    environment:
      - N8N_DEFAULT_TIMEZONE=America/Sao_Paulo
      - N8N_SECURE_COOKIE=true
    networks:
      - mantis_internal
```

**Regla:** memory ≤ 1500M. cpus ≤ 1.0. Red mantis_internal aislada.


### NET-001: Aislamiento de Red (C3)
```yaml
networks:
  mantis_internal:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
  mantis_public:
    driver: bridge
```

**Regla:** mysql, qdrant, redis SOLO en mantis_internal. n8n expuesto en mantis_public solo por puertos 5678/443.

---

## ✅ CHECKLIST DE VALIDACIÓN PRE-COMMIT

|Verificación	                            |Herramienta	                |Estado Requerido
|-------------------------------------------|-------------------------------|---------------------------------|
|`tenant_id` en todos los nodos de datos	|`validate_tenant_awareness`	|✅ Presente                      |
|Timeouts explícitos en HTTP	            |`validate_n8n_patterns`	    |✅ ≤ 30000ms                     |
|Sin secrets hardcodeados	                |`validate_markdown_structure`	|✅ 0 coincidencias               |
|Code fences balanceados	                |`validate_markdown_structure`	|✅ Par exacto                    |
|Límites Docker ≤ 1500M/1CPU	            |`validate_resource_limits`	    |✅ Cumplido                      |
|Puertos BD no expuestos	                |`validate_security`	        |✅ Solo red interna              |
|Modelos locales ausentes	                |`validate_security`	        |✅ 0 referencias a ollama/localai|
|Schema JSON válido en parsers	            |`validate_n8n_patterns`	    |✅ Parseable                     |

**Ejecución:** ./05-CONFIGURATION/SCRIPTS/validate-against-specs.sh ./05-CODE-PATTERNS-RULES.md - 1 0

---

## 📝 NOTAS DE MANTENIMIENTO SDD

-Extensión: Para agregar un nuevo patrón, crea PAT-XXX o SQL-XXX, documenta inputs/outputs, y actualiza validate-against-specs.sh si requiere reglas nuevas.
-Generación IA: El prompt de sistema para generación de workflows debe incluir: "Referencia obligatoria: 05-CODE-PATTERNS-RULES.md. Cumplir C1-C6. Inyectar tenant_id en cada nodo de datos. Validar con validate-against-specs.sh antes de retornar."
-Versionado: Cada cambio en este archivo debe incrementar sdd_version y registrar changelog en 00-CONTEXT/PROJECT_OVERVIEW.md.

## 🔗 Conexiones Estructurales (Auto-generado)
[[README.md]]
[[01-RULES/00-INDEX.md]]
[[01-RULES/01-ARCHITECTURE-RULES.md]]
[[01-RULES/02-RESOURCE-GUARDRAILS.md]]
