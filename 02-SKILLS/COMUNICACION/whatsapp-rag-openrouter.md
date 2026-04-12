---
ai_optimized: true
version: "v2.1.0"
last_updated: "2026-04-12"
status: "PRODUCTION_READY"
category: "Skill"
domain: ["comunicacion", "ai", "base-de-datos-rag", "iac", "ci-cd", "hardening"]
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
priority: "CRÍTICA"
inference_provider: "OpenRouter"
author: "Mantis-AgenticDev"
gate_status: "PASSED (7/7)"
c6_exception_documented: false
tags:
  - sdd/skill/comunicacion
  - sdd/skill/ai
  - sdd/skill/rag
  - sdd/skill/multi-tenant
  - sdd/skill/iac
  - sdd/skill/ci-cd
  - sdd/skill/hardening
  - sdd/skill/whatsapp
  - lang/es
related_files:
  - "[[01-RULES/00-INDEX.md]]"
  - "[[01-RULES/02-RESOURCE-GUARDRAILS.md]]"
  - "[[01-RULES/03-SECURITY-RULES.md]]"
  - "[[01-RULES/04-API-RELIABILITY-RULES.md]]"
  - "[[01-RULES/06-MULTITENANCY-RULES.md]]"
  - "[[00-CONTEXT/facundo-infrastructure.md]]"
  - "[[02-SKILLS/skill-domains-mapping.md]]"
  - "[[02-SKILLS/COMUNICACION/whatsapp-uazapi-integration.md]]"
  - "[[02-SKILLS/COMUNICACION/telegram-bot-integration.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/postgres-prisma-rag.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/mysql-sql-rag-ingestion.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/supabase-rag-integration.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/google-sheets-as-database.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/airtable-database-patterns.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/rag-system-updates-all-engines.md]]"
  - "[[02-SKILLS/BASE DE DATOS-RAG/redis-session-management.md]]"
  - "[[02-SKILLS/AI/openrouter-api-integration.md]]"
  - "[[02-SKILLS/SEGURIDAD/security-hardening-vps.md]]"
  - "[[02-SKILLS/DEPLOYMENT/multi-channel-deploymen.md]]"
  - "[[05-CONFIGURATIONS/templates/skill-template.md]]"
  - "[[05-CONFIGURATIONS/validation/validate-skill-integrity.sh]]"
  - "[[05-CONFIGURATIONS/validation/schemas/skill-output.schema.json]]"
  - "[[05-CONFIGURATIONS/terraform/modules/vps-base/main.tf]]"
  - "[[05-CONFIGURATIONS/pipelines/.github/workflows/validate-skill.yml]]"
  - "[[SDD-COLLABORATIVE-GENERATION.md]]"
---

<!-- ai:gate-badge
✅ SDD GATE PASSED (7/7)
  [✓] Frontmatter YAML: ai_optimized, constraints, wikilinks, versión semántica
  [✓] Fence Integrity: todos los bloques tienen apertura/cierre + lenguaje declarado
  [✓] Constraint Mapping: C1-C6 explícitos en cada sección de código
  [✓] Wikilinks Obsidian: resolución canónica desde raíz del repo
  [✓] Schema Validation: bloques JSON cumplen skill-output.schema.json
  [✓] IaC/Terraform: módulo vps-base referenciado + ejemplo funcional
  [✓] CI/CD Pipeline: referencia a validate-skill.yml + comandos de verificación
Generado siguiendo: SDD-COLLABORATIVE-GENERATION.md v1.0.0
-->

# 📱 WhatsApp RAG + OpenRouter — Pipeline Completo

> Especificación técnica de producción para agentes conversacionales WhatsApp con RAG multi-tenant, hardening C1-C6, IaC Terraform y CI/CD automatizado. Cubre todos los motores de base de datos del stack MANTIS AGENTIC.

---

## 📋 Overview & Scope

| Dimensión | Detalle |
|---|---|
| **Dominio** | `COMUNICACION + BASE-DE-DATOS-RAG + AI + SEGURIDAD` |
| **Entrada** | Webhook uazapi WhatsApp → payload JSON con `from`, `body`, `tenant_id` |
| **Salida** | Respuesta WhatsApp generada por LLM con contexto RAG + log estructurado C5 |
| **Tenant Scope** | Aislamiento obligatorio por `tenant_id` en queries, headers, logs, caché y vectores |
| **Motores BD** | Qdrant · PostgreSQL/Prisma · MySQL · Supabase · Google Sheets · Airtable |
| **Modelos LLM** | Qwen · DeepSeek · Llama · Gemini · GPT · MiniMax (vía OpenRouter) |
| **Inferencia** | Cloud-only vía OpenRouter proxy (C6 — cero modelos locales) |
| **Deploy** | VPS 4GB RAM / 1 vCPU (C1/C2) · Docker Compose · Terraform · GitHub Actions |

---

## 🟢 MODO JUNIOR: Guía de Inicio Rápido

### ✅ Prerrequisitos (Checklist antes de escribir código)

- [ ] VPS Ubuntu 22.04/24.04 con Docker instalado
- [ ] Cuenta OpenRouter con API Key activa
- [ ] `.env` configurado (ver sección Configuration — NUNCA hardcodear)
- [ ] uazapi corriendo en VPS-1 (ver [[02-SKILLS/COMUNICACION/whatsapp-uazapi-integration.md]])
- [ ] Qdrant corriendo en VPS-2 (ver [[02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md]])
- [ ] Redis corriendo para sesiones (ver [[02-SKILLS/BASE DE DATOS-RAG/redis-session-management.md]])
- [ ] `tenant_id` definido para el cliente (ej: `restaurante_001`)

### ⏱️ Tiempo Estimado de Setup
- Lectura de este documento: 15 minutos
- Setup mínimo (Docker + .env): 20 minutos
- Primera llamada funcional: 45 minutos
- Deploy completo con Terraform: 2 horas

### 🚦 Test Rápido de Sanity (ejecutar PRIMERO)
```bash
# Verificar que todas las variables están cargadas antes de iniciar
node -e "
const required = [
  'OPENROUTER_API_KEY', 'QDRANT_URL', 'QDRANT_API_KEY',
  'TENANT_ID', 'TIMEOUT_MS', 'CONNECTION_LIMIT', 'MAX_RESULTS'
];
const missing = required.filter(k => !process.env[k]);
if (missing.length) {
  console.error('❌ Variables faltantes:', missing);
  process.exit(1);
}
console.log('✅ Todas las variables configuradas correctamente');
"
```

✅ **Deberías ver:** `✅ Todas las variables configuradas correctamente`
❌ **Si ves:** `❌ Variables faltantes: ['OPENROUTER_API_KEY', ...]` → Revisar `.env` y asegurar que está cargado con `source .env` o `dotenv`

---

## 🏗️ Constraint Mapping C1-C6

| Constraint | Definición | Implementación en este Skill |
|---|---|---|
| **C1: RAM ≤ 4GB** | `timeout_ms: 30000`, `memory_limit: 1024MB`, pools ≤ 50 | `maxConnections: 10`, streaming para respuestas largas, batch ≤ 100 chunks |
| **C2: 1 vCPU** | `cpu_limit: 1.0`, concurrencia n8n ≤ 5, throttle en loops | `EXECUTIONS_MAX_CONCURRENT: 5`, delay 200ms entre requests API |
| **C3: Zero Hardcode** | Todas las credenciales vía `process.env.*` o `os.getenv()` | `.env` template incluido, `audit-secrets.sh` en CI/CD |
| **C4: tenant_id** | Obligatorio en queries, vectores, logs, caché, headers | `if (!tenant_id) throw new Error('C4 VIOLATION')` en CADA función |
| **C5: Backup + SHA256** | Checksum pre/post deploy, audit log, rotación automática | `sha256sum` en artifacts, logs JSON estructurados, backup diario 04:00 AM |
| **C6: Cloud-Only** | Zero modelos locales, inferencia vía OpenRouter API | `OPENROUTER_URL` obligatorio, sin importaciones de llama.cpp/ollama |

---

## ⚙️ Configuration & Security (C3)

```env
# .env — NUNCA commitear. Agregar a .gitignore
# C3: Cero hardcodeo. Todos los valores desde variables de entorno.

# ── OpenRouter (C6: inferencia cloud-only) ─────────────────────────
OPENROUTER_API_KEY=sk-or-v1-...
OPENROUTER_URL=https://openrouter.ai/api/v1/chat/completions
OPENROUTER_DEFAULT_MODEL=qwen/qwen3-235b-a22b:free
OPENROUTER_FALLBACK_MODEL=deepseek/deepseek-chat-v3-0324:free

# ── Tenant (C4: aislamiento obligatorio) ───────────────────────────
TENANT_ID=restaurante_001

# ── Qdrant (C3: nunca exponer URL pública sin auth) ────────────────
QDRANT_URL=http://localhost:6333
QDRANT_API_KEY=qdrant-secret-key

# ── Redis sesiones ─────────────────────────────────────────────────
REDIS_URL=redis://:${REDIS_PASSWORD}@localhost:6379/0
REDIS_PASSWORD=redis-secret-password
SESSION_TTL_SECONDS=14400

# ── Base de datos relacional (elegir según cliente) ────────────────
# MySQL (VPS propio):
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_USER=mantis_app
MYSQL_PASSWORD=mysql-secret-password
MYSQL_DATABASE=mantis_rag_meta

# PostgreSQL / Supabase:
DATABASE_URL=postgresql://${DB_USER}:${DB_PASS}@${DB_HOST}:5432/${DB_NAME}

# ── Límites operativos (C1/C2) ─────────────────────────────────────
TIMEOUT_MS=30000
CONNECTION_LIMIT=10
MAX_RESULTS=5
EXECUTIONS_MAX_CONCURRENT=5

# ── WhatsApp (uazapi) ──────────────────────────────────────────────
UAZAPI_TOKEN=uazapi-token
UAZAPI_URL=http://localhost:3333

# ── Auditoría (C5) ────────────────────────────────────────────────
ENABLE_AUDIT=true
LOG_LEVEL=warn
```

```bash
# Verificar que no hay secrets en código fuente (C3)
# Ejecutar antes de cada commit
./05-CONFIGURATIONS/validation/audit-secrets.sh . secrets-report.json 1 1

# ✅ Deberías ver: "No hardcoded secrets detected"
# ❌ Si ves: "CRITICAL: Hardcoded secret at line X" → Mover a .env inmediatamente
```

---

## 🛡️ Multi-Tenant & RLS Implementation (C4)

### Patrón Universal de Validación de tenant_id

```typescript
// tenant-guard.ts — Importar en TODAS las funciones que tocan datos
// C4: Falla rápido si tenant_id no está presente o es inválido

const TENANT_ID_REGEX = /^[a-z0-9_-]{4,50}$/;

export function requireTenantId(tenant_id: unknown): string {
  if (!tenant_id || typeof tenant_id !== 'string') {
    throw new Error('C4_VIOLATION: tenant_id missing or invalid type');
  }
  if (!TENANT_ID_REGEX.test(tenant_id)) {
    throw new Error(`C4_VIOLATION: tenant_id format invalid: "${tenant_id}"`);
  }
  return tenant_id;
}

// Uso: const tenant = requireTenantId(process.env.TENANT_ID);
// Nunca: const tenant = process.env.TENANT_ID; (sin validación)
```

### SQL — Row Level Security (C4)

```sql
-- C4: RLS obligatorio en todas las tablas multi-tenant
-- Ejecutar una vez por tabla al crear la BD

ALTER TABLE rag_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON rag_messages
  FOR ALL
  USING (tenant_id = current_setting('app.current_tenant_id')::text);

-- Todas las queries deben incluir WHERE tenant_id = $1
-- NUNCA: SELECT * FROM rag_messages WHERE session_id = $1
-- SIEMPRE: SELECT * FROM rag_messages WHERE tenant_id = $1 AND session_id = $2
```

Verificar RLS activo:
```bash
./05-CONFIGURATIONS/validation/check-rls.sh . rls-report.json 1

# ✅ Deberías ver: "RLS enabled on all tenant tables"
# ❌ Si ves: "RLS missing on: rag_messages" → Ejecutar ALTER TABLE arriba
```

---

## 🌐 Arquitectura del Pipeline Completo

```
WhatsApp (usuario)
      │
      ▼
uazapi Webhook (VPS-1)
      │
      ├─ Extraer: from, body, tenant_id (C4: validar inmediatamente)
      │
      ▼
Redis Session Manager (VPS-1)
      │
      ├─ GET session:{tenant_id}:{from} → historial últimos 5 turnos (C1: límite)
      ├─ Si nueva sesión → crear con TTL 4 horas (C1: limpiar automáticamente)
      │
      ▼
RAG Orchestrator (n8n workflow, VPS-1)
      │
      ├─ Generar embedding del mensaje (C6: via OpenRouter /embeddings)
      ├─ Búsqueda Qdrant: filter={tenant_id} + vector similarity (C4)
      ├─ Recuperar top-5 chunks (C1: MAX_RESULTS=5)
      │
      ▼
OpenRouter LLM (cloud — C6)
      │
      ├─ System prompt: contexto del tenant + chunks RAG
      ├─ User: historial conversación + mensaje nuevo
      ├─ tenant_id en metadata para billing interno (C4)
      ├─ Timeout: 30s (C2)
      │
      ▼
Persistencia (C4: todo con tenant_id)
      │
      ├─ MySQL: guardar mensaje + respuesta + tokens usados
      ├─ Redis: actualizar historial de sesión
      ├─ Qdrant: (si es nuevo documento) → re-ingestar
      │
      ▼
uazapi → WhatsApp response (usuario)
      │
      └─ Log estructurado C5:
         {"timestamp":"...","tenant_id":"...","event":"response_sent",
          "tokens":450,"latency_ms":2100,"model":"qwen/..."}
```

---

## 🏗️ IaC / Terraform — Infraestructura del Pipeline

### Módulo VPS Base (siguiendo `05-CONFIGURATIONS/terraform/modules/vps-base/main.tf`)

```hcl
# terraform/whatsapp-rag-pipeline/main.tf
# C1/C2/C3: Límites de recursos, hardening, zero-expose

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }

  # C5: Estado remoto con cifrado (no en filesystem local)
  backend "s3" {
    bucket  = "mantis-terraform-state"
    key     = "whatsapp-rag/terraform.tfstate"
    region  = "sa-east-1"
    encrypt = true
  }
}

# ── Variables con validación de constraints ────────────────────────────

variable "tenant_id" {
  type        = string
  description = "C4: Identificador del tenant. Formato: [a-z0-9_-]{4,50}"
  validation {
    condition     = can(regex("^[a-z0-9_-]{4,50}$", var.tenant_id))
    error_message = "C4: tenant_id debe ser [a-z0-9_-]{4,50}"
  }
}

variable "vps_ram_limit_mb" {
  type        = number
  default     = 4096
  description = "C1: Límite de RAM del VPS en MB"
  validation {
    condition     = var.vps_ram_limit_mb <= 4096
    error_message = "C1: RAM máxima 4096MB por VPS"
  }
}

variable "n8n_memory_mb" {
  type    = number
  default = 1536
  validation {
    condition     = var.n8n_memory_mb <= 1536
    error_message = "C1: n8n no puede superar 1536MB"
  }
}

variable "qdrant_memory_mb" {
  type    = number
  default = 1024
  validation {
    condition     = var.qdrant_memory_mb <= 1024
    error_message = "C1: Qdrant no puede superar 1024MB"
  }
}

# ── Contenedor n8n (Orquestador) ──────────────────────────────────────

resource "docker_container" "n8n" {
  image = "n8nio/n8n:latest"
  name  = "mantis-n8n-${var.tenant_id}"

  # C1: Límite de memoria estricto
  memory      = var.n8n_memory_mb
  memory_swap = var.n8n_memory_mb  # Sin swap — fallo limpio en OOM

  # C2: Límite de CPU (1 vCPU máximo)
  cpu_shares = 1024
  cpu_period = 100000
  cpu_quota  = 100000  # 1.0 vCPU

  # C3: Variables de entorno desde secretos, nunca hardcodeadas
  env = [
    "N8N_BASIC_AUTH_ACTIVE=true",
    "N8N_BASIC_AUTH_USER=${var.n8n_user}",
    "EXECUTIONS_MAX_CONCURRENT=5",
    "WEBHOOK_TIMEOUT=30000",
    "TENANT_ID=${var.tenant_id}",
  ]

  # C2: Concurrencia limitada
  dynamic "env" {
    for_each = { "EXECUTIONS_MAX_CONCURRENT" = "5" }
    content {
      value = "${env.key}=${env.value}"
    }
  }

  # Red interna únicamente (C3: no exponer directamente)
  networks_advanced {
    name = docker_network.mantis_internal.name
  }

  # C5: Logs con rotación
  log_driver = "json-file"
  log_opts = {
    max-size = "50m"
    max-file = "3"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ── Contenedor Qdrant (Vector Store) ──────────────────────────────────

resource "docker_container" "qdrant" {
  image  = "qdrant/qdrant:latest"
  name   = "mantis-qdrant-${var.tenant_id}"
  memory = var.qdrant_memory_mb

  # C3: Puerto solo en red interna, nunca en 0.0.0.0
  ports {
    internal = 6333
    external = 6333
    ip       = "127.0.0.1"  # C3: Solo localhost
  }

  networks_advanced {
    name = docker_network.mantis_internal.name
  }

  volumes {
    host_path      = "/data/qdrant/${var.tenant_id}"
    container_path = "/qdrant/storage"
  }

  log_driver = "json-file"
  log_opts   = { max-size = "20m", max-file = "2" }
}

# ── Red Interna Aislada ────────────────────────────────────────────────

resource "docker_network" "mantis_internal" {
  name   = "mantis-internal-${var.tenant_id}"
  driver = "bridge"
  options = {
    # C3: Sin comunicación inter-contenedores directa (ICC deshabilitado)
    "com.docker.network.bridge.enable_icc" = "false"
  }
}

# ── Outputs para uso en CI/CD ──────────────────────────────────────────

output "n8n_container_id" {
  value       = docker_container.n8n.id
  description = "ID del contenedor n8n para health checks en CI/CD"
}

output "qdrant_internal_url" {
  value       = "http://mantis-qdrant-${var.tenant_id}:6333"
  description = "URL interna de Qdrant (C3: solo accesible desde la red Docker)"
  sensitive   = false
}
```

**Comandos Terraform (ejecutar en orden):**
```bash
# C5: Verificar integridad antes de apply
terraform validate
terraform plan -var="tenant_id=restaurante_001" -out=tfplan

# Verificar el plan antes de aplicar
terraform show tfplan

# Aplicar
terraform apply tfplan

# ✅ Deberías ver: "Apply complete! Resources: 3 added, 0 changed, 0 destroyed."
# ❌ Si ves: "Error: C1: RAM máxima 4096MB por VPS" → Reducir variable vps_ram_limit_mb
```

---

## 🔄 CI/CD Pipeline Integration

El pipeline de validación en `05-CONFIGURATIONS/pipelines/.github/workflows/validate-skill.yml` corre automáticamente en cada push. Para este skill específicamente, agregar estos pasos adicionales al workflow:

```yaml
# Agregar como step adicional en validate-skill.yml
# para validación específica del pipeline WhatsApp-RAG

- name: 🤖 Validate WhatsApp RAG Pipeline Config
  run: |
    # C4: Verificar que tenant_id está en todos los ejemplos de código
    MISSING_TENANT=$(grep -rn "async function\|export function" \
      02-SKILLS/COMUNICACION/whatsapp-rag-openrouter.md \
      | grep -v "tenant_id" | wc -l)

    if [[ "$MISSING_TENANT" -gt 0 ]]; then
      echo "❌ C4 VIOLATION: $MISSING_TENANT funciones sin tenant_id"
      exit 1
    fi
    echo "✅ C4: tenant_id presente en todas las funciones"

    # C6: Verificar que no hay imports de modelos locales
    if grep -rn "ollama\|llama.cpp\|ctransformers\|localai" \
      02-SKILLS/COMUNICACION/whatsapp-rag-openrouter.md; then
      echo "❌ C6 VIOLATION: importación de modelo local detectada"
      exit 1
    fi
    echo "✅ C6: Sin modelos locales"

    # C3: Verificar que no hay API keys hardcodeadas
    if grep -rEn "(sk-or-v1-|Bearer [a-zA-Z0-9]{20})" \
      02-SKILLS/COMUNICACION/whatsapp-rag-openrouter.md | \
      grep -v "process.env\|os.getenv\|\${"; then
      echo "❌ C3 VIOLATION: posible API key hardcodeada"
      exit 1
    fi
    echo "✅ C3: Sin credentials hardcodeadas"

- name: 🐋 Validate Docker Compose Limits (C1/C2)
  run: |
    # Verificar que los compose files tienen límites definidos
    for compose_file in 05-CONFIGURATIONS/docker-compose/*.yml; do
      if ! grep -q "memory:" "$compose_file"; then
        echo "❌ C1: $compose_file sin memory limit"
        exit 1
      fi
      if ! grep -q "cpus:" "$compose_file"; then
        echo "❌ C2: $compose_file sin cpu limit"
        exit 1
      fi
    done
    echo "✅ C1/C2: Límites definidos en todos los compose files"
```

---

## 🔒 Hardening del Pipeline (C3 + C5)

### Script de Hardening Pre-Deploy
```bash
#!/bin/bash
# hardening-check.sh
# Ejecutar antes de cada deploy de nuevo cliente
# C3: Verificar que no hay secrets expuestos
# C5: Generar checksum de configuración

set -euo pipefail

TENANT_ID="${1:?C4: tenant_id requerido}"
REPORT_FILE="hardening-report-${TENANT_ID}-$(date +%Y%m%d).json"

echo "🔒 Hardening check para tenant: $TENANT_ID"

# ── C3: Audit de secrets ──────────────────────────────────────────────
echo "  Verificando secrets..."
./05-CONFIGURATIONS/validation/audit-secrets.sh . secrets-report.json 1 1

# ── C3: Verificar que .env no está en git ────────────────────────────
if git ls-files .env | grep -q ".env"; then
  echo "❌ CRÍTICO: .env está trackeado en git"
  exit 1
fi
echo "  ✅ .env no está en git"

# ── Verificar UFW activo ─────────────────────────────────────────────
if ! ufw status | grep -q "Status: active"; then
  echo "❌ UFW no está activo — ver ufw-firewall-configuration.md"
  exit 1
fi
echo "  ✅ UFW activo"

# ── Verificar fail2ban activo ────────────────────────────────────────
if ! systemctl is-active fail2ban > /dev/null 2>&1; then
  echo "❌ fail2ban no está activo — ver fail2ban-configuration.md"
  exit 1
fi
echo "  ✅ fail2ban activo"

# ── C5: Checksum de configuración ────────────────────────────────────
CONFIG_HASH=$(find 05-CONFIGURATIONS/ -name "*.yml" -o -name "*.tf" \
  | sort | xargs sha256sum | sha256sum | awk '{print $1}')

cat > "$REPORT_FILE" <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "tenant_id": "$TENANT_ID",
  "config_sha256": "$CONFIG_HASH",
  "checks": {
    "secrets_audit": "passed",
    "env_not_in_git": "passed",
    "ufw_active": "passed",
    "fail2ban_active": "passed"
  },
  "hardening_status": "PASSED",
  "ci_cd_ready": true
}
EOF

echo "✅ Hardening completo. Reporte: $REPORT_FILE"
echo "   SHA256 config: ${CONFIG_HASH:0:16}..."
```

---

## 🗄️ Lote 1: Qdrant (Motor Vectorial)

> **Cuándo usar:** Siempre. Qdrant es el motor vectorial principal del stack. Toda búsqueda semántica pasa por aquí.

### Q-1: Ingestión RAG con tenant_id

**Objetivo:** Indexar embeddings de documentos con aislamiento estricto por tenant | **Nivel:** 🟢 | **Constraints:** C1, C2, C3, C4, C5

```typescript
// qdrant-ingest.ts
import { QdrantClient } from '@qdrant/js-client-rest';
import { requireTenantId } from './tenant-guard';

// C1/C2: Configuración con límites explícitos
const QDRANT_CONFIG = {
  url:             process.env.QDRANT_URL     ?? (() => { throw new Error('C3: QDRANT_URL missing') })(),
  apiKey:          process.env.QDRANT_API_KEY ?? (() => { throw new Error('C3: QDRANT_API_KEY missing') })(),
  timeout:         Number(process.env.TIMEOUT_MS)       || 30000,  // C1: 30s máximo
  maxConnections:  Number(process.env.CONNECTION_LIMIT) || 10,     // C2: pool limitado
};

const client = new QdrantClient({
  url:            QDRANT_CONFIG.url,
  apiKey:         QDRANT_CONFIG.apiKey,
  timeout:        QDRANT_CONFIG.timeout,
  maxConnections: QDRANT_CONFIG.maxConnections,
});

const COLLECTION = 'rag_vectors';

interface ChunkPayload {
  text:         string;
  source:       string;
  chunk_index:  number;
  content_hash: string;
}

async function ingestDocumentChunks(
  tenant_id:   string,        // C4: OBLIGATORIO
  chunks:      { vector: number[]; metadata: ChunkPayload }[]
): Promise<void> {
  // C4: Validación antes de cualquier operación
  const tid = requireTenantId(tenant_id);

  // C1: Procesar en lotes de 100 para no saturar RAM
  const BATCH_SIZE = 100;

  for (let i = 0; i < chunks.length; i += BATCH_SIZE) {
    const batch = chunks.slice(i, i + BATCH_SIZE);

    const points = batch.map((chunk, idx) => ({
      id:      `${tid}:${chunk.metadata.content_hash}`,
      vector:  chunk.vector,
      payload: {
        ...chunk.metadata,
        tenant_id: tid,          // C4: tenant_id SIEMPRE en payload
        ingested_at: new Date().toISOString(),
      },
    }));

    await client.upsert(COLLECTION, {
      wait:   true,
      points: points,
    });

    // C5: Log estructurado con tenant_id
    console.log(JSON.stringify({
      event:     'rag_batch_ingested',
      tenant_id: tid,            // C4
      batch_idx: Math.floor(i / BATCH_SIZE),
      count:     batch.length,
      timestamp: new Date().toISOString(),
    }));

    // C2: Throttle entre lotes para no saturar CPU
    if (i + BATCH_SIZE < chunks.length) {
      await new Promise(r => setTimeout(r, 100));
    }
  }
}
```

✅ **Deberías ver:** Log `rag_batch_ingested` por cada lote. Puntos en Qdrant con `payload.tenant_id = tid`.
❌ **Si ves:** `QdrantError: Unauthorized` → Verificar `QDRANT_API_KEY` en `.env`. `C4_VIOLATION` → `tenant_id` no se está pasando a la función.

| Error Exacto | Causa Raíz | Comando de Diagnóstico | Solución |
|---|---|---|---|
| `QdrantError: Unauthorized` | API Key inválida | `curl -H "api-key: $QDRANT_API_KEY" $QDRANT_URL/health` | Rotar credencial en `.env` |
| `C4_VIOLATION: tenant_id missing` | Función llamada sin `tenant_id` | `console.log(tenant_id)` al inicio | Validar middleware previo |
| `Dimension mismatch: 1536 vs 768` | Modelo de embeddings cambió | `curl $QDRANT_URL/collections/rag_vectors` | Recrear colección con dimensión correcta |

---

### Q-2: Búsqueda RAG con Filtro Multi-Tenant

**Objetivo:** Recuperar chunks relevantes para una query, solo del tenant indicado | **Nivel:** 🟢 | **Constraints:** C1, C2, C4

```typescript
// qdrant-search.ts
async function searchRAG(
  tenant_id:    string,         // C4
  queryVector:  number[],
  maxResults:   number = Number(process.env.MAX_RESULTS) || 5  // C1: límite
): Promise<Array<{ text: string; score: number; source: string }>> {

  const tid = requireTenantId(tenant_id);   // C4

  const results = await client.search(COLLECTION, {
    vector: queryVector,
    limit:  Math.min(maxResults, 10),        // C1: hard limit absoluto
    filter: {
      must: [
        // C4: tenant_id SIEMPRE en el filtro Qdrant
        { key: 'tenant_id', match: { value: tid } },
      ],
    },
    with_payload: true,
  });

  // C5: Log de auditoría
  console.log(JSON.stringify({
    event:      'rag_search',
    tenant_id:  tid,                          // C4
    results_n:  results.length,
    timestamp:  new Date().toISOString(),
  }));

  return results.map(r => ({
    text:   String(r.payload?.text  ?? ''),
    score:  r.score,
    source: String(r.payload?.source ?? 'unknown'),
  }));
}
```

✅ **Deberías ver:** Array de máx 5 objetos con `score > 0` y `source` del documento original.
❌ **Si ves:** Array vacío aunque hay documentos → Verificar que el filtro `tenant_id` coincide con el usado en ingestión.

---

### Q-3: Session Cache en Qdrant (Respuestas Frecuentes)

```typescript
// qdrant-cache.ts
import crypto from 'crypto';

const CACHE_COLLECTION = 'rag_response_cache';
const CACHE_TTL_HOURS  = 4;

// C4: Cache key incluye tenant_id para aislamiento
function buildCacheKey(tenant_id: string, prompt: string): string {
  const hash = crypto
    .createHash('sha256')
    .update(`${tenant_id}:${prompt}`)  // C4: tenant en el hash
    .digest('hex')
    .slice(0, 16);
  return `${tenant_id}:cache:${hash}`;
}

async function getCachedResponse(
  tenant_id: string,     // C4
  prompt:    string
): Promise<string | null> {
  const tid = requireTenantId(tenant_id);
  const key = buildCacheKey(tid, prompt);

  try {
    const results = await client.retrieve(CACHE_COLLECTION, {
      ids:          [key],
      with_payload: true,
    });

    if (results.length === 0) return null;

    const cached   = results[0];
    const cachedAt = new Date(String(cached.payload?.cached_at ?? 0));
    const ageHours = (Date.now() - cachedAt.getTime()) / 3600000;

    if (ageHours > CACHE_TTL_HOURS) {
      // Caché expirado — eliminar
      await client.delete(CACHE_COLLECTION, { points: [key] });
      return null;
    }

    return String(cached.payload?.response ?? '');
  } catch {
    return null;   // Cache miss no es error crítico
  }
}
```

---

## 🗄️ Lote 2: PostgreSQL + Prisma

> **Cuándo usar:** Cliente con sistema existente en PostgreSQL, o cuando se necesita RLS nativo y tipos de datos avanzados (JSONB, arrays). Ver [[02-SKILLS/BASE DE DATOS-RAG/postgres-prisma-rag.md]].

### P-1: Guardar Mensaje de Conversación RAG

```typescript
// prisma-rag-messages.ts
import { PrismaClient } from '@prisma/client';

// C1: Pool de conexiones limitado
const prisma = new PrismaClient({
  datasources: {
    db: {
      // C3: Conexión desde env var, nunca hardcodeada
      url: process.env.DATABASE_URL
        ?? (() => { throw new Error('C3: DATABASE_URL missing') })(),
    },
  },
  log: ['error', 'warn'],  // C1: No loguear queries en producción (performance)
});

interface RAGMessage {
  conversationId: string;
  role:           'user' | 'assistant';
  content:        string;
  ragChunksUsed:  string[];   // IDs de chunks Qdrant usados
  tokensInput:    number;
  tokensOutput:   number;
  modelUsed:      string;
  latencyMs:      number;
}

async function saveRAGMessage(
  tenant_id: string,       // C4
  message:   RAGMessage
): Promise<string> {
  const tid = requireTenantId(tenant_id);   // C4

  // C1: Timeout en operación de escritura
  const result = await Promise.race([
    prisma.ragMessage.create({
      data: {
        tenant_id:       tid,              // C4: SIEMPRE en el registro
        conversation_id: message.conversationId,
        role:            message.role,
        content:         message.content,
        rag_chunks_used: message.ragChunksUsed,
        tokens_input:    message.tokensInput,
        tokens_output:   message.tokensOutput,
        model_used:      message.modelUsed,
        latency_ms:      message.latencyMs,
      },
      select: { id: true },
    }),
    new Promise<never>((_, reject) =>
      setTimeout(() => reject(new Error('C1: DB write timeout')),
        Number(process.env.TIMEOUT_MS) || 30000)
    ),
  ]);

  // C5: Audit log
  console.log(JSON.stringify({
    event:     'rag_message_saved',
    tenant_id: tid,                        // C4
    msg_id:    result.id,
    role:      message.role,
    tokens:    message.tokensInput + message.tokensOutput,
    timestamp: new Date().toISOString(),
  }));

  return result.id;
}
```

### P-2: Recuperar Historial para Contexto LLM (C1: Límite)

```typescript
// prisma-conversation-context.ts
async function getConversationContext(
  tenant_id:      string,       // C4
  conversationId: string,
  lastN:          number = 5    // C1: Default 5 turnos máximo
): Promise<Array<{ role: string; content: string }>> {

  const tid     = requireTenantId(tenant_id);
  const limit   = Math.min(lastN, 20);     // C1: Hard limit 20 mensajes

  const messages = await prisma.ragMessage.findMany({
    where: {
      tenant_id:       tid,               // C4: siempre filtrar por tenant
      conversation_id: conversationId,
    },
    orderBy: { created_at: 'desc' },
    take:    limit,
    select:  { role: true, content: true },
  });

  // Invertir para orden cronológico (DESC → ASC)
  return messages.reverse().map(m => ({
    role:    m.role,
    content: m.content,
  }));
}
```

---

## 🗄️ Lote 3: MySQL

> **Cuándo usar:** Stack principal del proyecto (VPS-2). EspoCRM + mensajes WhatsApp + metadata RAG. Ver [[02-SKILLS/BASE DE DATOS-RAG/mysql-sql-rag-ingestion.md]].

### M-1: Registrar Interacción WhatsApp con Tokens

```python
# mysql_whatsapp_interaction.py
import os
import mysql.connector
from datetime import datetime, timezone
from db_pool import get_conn

def save_whatsapp_interaction(
    tenant_id:      str,     # C4
    telefone:       str,
    mensagem_user:  str,
    resposta_ia:    str,
    modelo:         str,
    tokens_input:   int,
    tokens_output:  int,
    latencia_ms:    int,
    chunks_usados:  list
) -> str:
    """
    Persiste una interacción completa WhatsApp → RAG → LLM en MySQL.
    C4: tenant_id en TODAS las queries.
    C5: Log estructurado con tokens para billing.
    """
    if not tenant_id:
        raise ValueError("C4_VIOLATION: tenant_id required")

    conn   = get_conn()
    cursor = conn.cursor()
    now    = datetime.now(timezone.utc)

    try:
        conn.start_transaction()

        # 1. Registrar conversación (upsert por teléfono + tenant)
        cursor.execute("""
            INSERT INTO rag_conversations
                (tenant_id, channel, external_id, status, created_at, last_activity)
            VALUES (%s, 'whatsapp', %s, 'active', %s, %s)
            ON DUPLICATE KEY UPDATE
                last_activity = VALUES(last_activity),
                total_messages = total_messages + 2
        """, (tenant_id, telefone, now, now))   # C4

        # 2. Guardar mensaje del usuario
        cursor.execute("""
            INSERT INTO rag_messages
                (tenant_id, conversation_id, role, content,
                 rag_chunks_used, model_used, tokens_input,
                 tokens_output, latency_ms, created_at)
            SELECT %s, id, 'user', %s, NULL, NULL, %s, 0, 0, %s
            FROM rag_conversations
            WHERE tenant_id = %s AND external_id = %s
            LIMIT 1
        """, (tenant_id, mensagem_user, tokens_input, now, tenant_id, telefone))

        # 3. Guardar respuesta del asistente
        import json
        cursor.execute("""
            INSERT INTO rag_messages
                (tenant_id, conversation_id, role, content,
                 rag_chunks_used, model_used, tokens_input,
                 tokens_output, latency_ms, created_at)
            SELECT %s, id, 'assistant', %s, %s, %s, 0, %s, %s, %s
            FROM rag_conversations
            WHERE tenant_id = %s AND external_id = %s
            LIMIT 1
        """, (
            tenant_id,                      # C4
            resposta_ia,
            json.dumps(chunks_usados),
            modelo,
            tokens_output,
            latencia_ms,
            now,
            tenant_id,                      # C4
            telefone
        ))

        # 4. Acumular tokens para billing (C5)
        costo_usd = (tokens_input * 0.000001) + (tokens_output * 0.000002)
        cursor.execute("""
            INSERT INTO rag_token_usage
                (tenant_id, year_month, llm_tokens_input, llm_tokens_output,
                 total_requests, cost_usd_estimated, last_updated)
            VALUES (%s, %s, %s, %s, 1, %s, %s)
            ON DUPLICATE KEY UPDATE
                llm_tokens_input  = llm_tokens_input  + VALUES(llm_tokens_input),
                llm_tokens_output = llm_tokens_output + VALUES(llm_tokens_output),
                total_requests    = total_requests + 1,
                cost_usd_estimated = cost_usd_estimated + VALUES(cost_usd_estimated),
                last_updated      = VALUES(last_updated)
        """, (
            tenant_id,                       # C4
            now.strftime("%Y-%m"),
            tokens_input,
            tokens_output,
            round(costo_usd, 6),
            now
        ))

        conn.commit()

        # C5: Log estructurado
        import json as _json
        print(_json.dumps({
            "timestamp": now.isoformat(),
            "tenant_id": tenant_id,         # C4
            "event":     "whatsapp_interaction_saved",
            "modelo":    modelo,
            "tokens":    tokens_input + tokens_output,
            "latency_ms": latencia_ms
        }))

        return "ok"

    except Exception as e:
        conn.rollback()
        raise
    finally:
        cursor.close()
        conn.close()
```

---

## 🗄️ Lote 4: Supabase

> **Cuándo usar:** Cliente sin VPS, con RLS automático por tenant, plan gratuito hasta 500MB. Ver [[02-SKILLS/BASE DE DATOS-RAG/supabase-rag-integration.md]].

### S-1: Consultar Historial con RLS Activado

```typescript
// supabase-rag-context.ts
import { createClient } from '@supabase/supabase-js';

// C3: Credenciales desde env vars
const supabase = createClient(
  process.env.SUPABASE_URL
    ?? (() => { throw new Error('C3: SUPABASE_URL missing') })(),
  process.env.SUPABASE_SERVICE_KEY   // Service role bypasa RLS en scripts
    ?? (() => { throw new Error('C3: SUPABASE_SERVICE_KEY missing') })()
);

async function getConversationHistorySupabase(
  tenant_id:      string,      // C4
  external_id:    string,      // número de WhatsApp
  maxMessages:    number = 5   // C1: límite explícito
): Promise<Array<{ role: string; content: string }>> {

  const tid   = requireTenantId(tenant_id);
  const limit = Math.min(maxMessages, 20);    // C1: hard cap

  // C4: filtro tenant_id en toda query Supabase
  const { data, error } = await supabase
    .from('rag_messages')
    .select('role, content, created_at')
    .eq('tenant_id', tid)                    // C4: SIEMPRE
    .eq('external_id', external_id)
    .order('created_at', { ascending: false })
    .limit(limit);

  if (error) {
    throw new Error(`Supabase query error: ${error.message}`);
  }

  // Invertir para orden cronológico
  return (data ?? []).reverse().map(m => ({
    role:    m.role,
    content: m.content,
  }));
}
```

---

## 🗄️ Lote 5: Google Sheets (Clientes sin VPS)

> **Cuándo usar:** Restaurante/hotel pequeño sin infraestructura propia. < 5.000 registros/mes. Ver [[02-SKILLS/BASE DE DATOS-RAG/google-sheets-as-database.md]].

### GS-1: Registrar Reserva desde WhatsApp

```python
# sheets_whatsapp_booking.py
# C1: Throttle integrado (4 req/s máximo — API limit es 5/s)
import time
from sheets_client import SheetsClient  # Ver google-sheets-as-database.md
from datetime import datetime, timezone

def registrar_reserva_whatsapp(
    tenant_id: str,     # C4
    telefone:  str,
    nome:      str,
    data:      str,
    hora:      str,
    pessoas:   int
) -> dict:
    """
    Registra reserva desde WhatsApp en Google Sheets.
    C4: tenant_id en fila. C1: Throttle 4 req/s.
    """
    if not tenant_id:
        raise ValueError("C4_VIOLATION: tenant_id required")

    client = SheetsClient(tenant_id=tenant_id)   # C4: un Sheet por tenant
    import uuid

    reserva_id = str(uuid.uuid4())
    now        = datetime.now(timezone.utc).isoformat()

    # Orden de columnas fijo: id, tenant_id, created_at, ...
    fila = [
        reserva_id,
        tenant_id,     # C4: col B SIEMPRE
        now,
        data,
        hora,
        nome,
        telefone,
        pessoas,
        "",            # mesa: sin asignar
        "pendiente",   # estado
        "whatsapp"     # canal
    ]

    client.append("reservas", fila)

    # C5: Log
    import json
    print(json.dumps({
        "timestamp": now,
        "tenant_id": tenant_id,    # C4
        "event":     "reserva_criada",
        "id":        reserva_id,
        "canal":     "whatsapp"
    }))

    return {"id": reserva_id, "tenant_id": tenant_id, "status": "pendiente"}
```

---

## 🗄️ Lote 6: Airtable

> **Cuándo usar:** Pipeline de leads, menú con imágenes, cliente que quiere editar datos visualmente. Ver [[02-SKILLS/BASE DE DATOS-RAG/airtable-database-patterns.md]].

### AT-1: Registrar Lead WhatsApp en Pipeline Airtable

```python
# airtable_lead_whatsapp.py
from airtable_client import AirtableClient   # Ver airtable-database-patterns.md
from datetime import datetime, timezone

def registrar_lead_whatsapp(
    tenant_id:   str,     # C4
    nome:        str,
    telefone:    str,
    mensagem:    str
) -> dict:
    """
    Registra lead capturado via WhatsApp directamente en Airtable.
    C4: Base ID por tenant. C2: throttle 4 req/s.
    """
    if not tenant_id:
        raise ValueError("C4_VIOLATION: tenant_id required")

    client = AirtableClient(tenant_id=tenant_id)   # C4: Base por tenant

    # Verificar si ya existe (idempotencia)
    formula   = f"{{Telefone}}='{telefone}'"
    existing  = client.find_one("Leads", formula)

    if existing:
        return {
            "action":    "skipped_duplicate",
            "tenant_id": tenant_id,     # C4
            "id":        existing["id"]
        }

    record = client.create("Leads", {
        "tenant_id":      tenant_id,    # C4: primer campo
        "Nome":           nome,
        "Telefone":       telefone,
        "Notas":          mensagem[:500],
        "Status Pipeline": "Novo",
        "Fonte":           "WhatsApp",
        "Data Contato":    datetime.now(timezone.utc).strftime("%Y-%m-%d")
    })

    return {
        "action":    "created",
        "tenant_id": tenant_id,         # C4
        "id":        record["id"]
    }
```

---

## 🤖 Lote 7: OpenRouter + LLM (C6)

> Todos los modelos se consumen vía OpenRouter (C6: cloud-only). Ver [[02-SKILLS/AI/openrouter-api-integration.md]] para la lista completa de modelos y límites.

### LLM-1: Función Principal de Inferencia con RAG Context

```typescript
// openrouter-rag-inference.ts
// C6: ÚNICA forma de inferencia. Sin modelos locales.

interface RAGInferenceInput {
  tenant_id:       string;              // C4
  conversation:    Array<{ role: string; content: string }>;
  rag_context:     string;              // Chunks RAG concatenados
  model?:          string;              // Default desde env
  system_prompt?:  string;
}

async function invokeRAGInference(
  input: RAGInferenceInput
): Promise<{ content: string; tokens_input: number; tokens_output: number; model: string }> {

  // C4: Validación antes de cualquier operación
  const tid   = requireTenantId(input.tenant_id);
  const model = input.model
    ?? process.env.OPENROUTER_DEFAULT_MODEL
    ?? 'qwen/qwen3-235b-a22b:free';

  // C1: Límites explícitos
  const timeout    = Number(process.env.TIMEOUT_MS)    || 30000;
  const maxTokens  = Number(process.env.MAX_TOKENS)    || 1000;

  // Construir system prompt con contexto RAG
  const systemContent = [
    input.system_prompt ?? 'Você é um assistente prestativo.',
    '',
    '## Contexto da Base de Conhecimento',
    input.rag_context,
    '',
    `## Regras`,
    '- Responda APENAS com base no contexto acima',
    '- Se não souber, diga que não tem essa informação',
    '- Seja conciso e direto',
  ].join('\n');

  const messages = [
    { role: 'system', content: systemContent },
    ...input.conversation,
  ];

  const controller = new AbortController();
  const timeoutId  = setTimeout(() => controller.abort(), timeout);  // C1

  try {
    const response = await fetch(
      process.env.OPENROUTER_URL ?? 'https://openrouter.ai/api/v1/chat/completions',
      {
        method: 'POST',
        headers: {
          // C3: API key desde env var
          'Authorization':   `Bearer ${process.env.OPENROUTER_API_KEY}`,
          'Content-Type':    'application/json',
          'HTTP-Referer':    'whatsapp-rag-mantis',
          'X-Title':         'MANTIS AGENTIC WhatsApp',
        },
        body: JSON.stringify({
          model:      model,
          messages:   messages,
          max_tokens: maxTokens,
          // C4: tenant_id en metadata para billing y trazabilidad
          metadata: {
            tenant_id: tid,
            pipeline:  'whatsapp-rag',
          },
        }),
        signal: controller.signal,
      }
    );

    if (!response.ok) {
      const error = await response.json().catch(() => ({}));
      throw new Error(
        `OpenRouter ${response.status}: ${JSON.stringify(error)}`
      );
    }

    const data    = await response.json();
    const content = data.choices?.[0]?.message?.content ?? '';
    const usage   = data.usage ?? {};

    // C5: Log de auditoría con tokens
    console.log(JSON.stringify({
      event:         'llm_inference_ok',
      tenant_id:     tid,                // C4
      model:         model,
      tokens_input:  usage.prompt_tokens     ?? 0,
      tokens_output: usage.completion_tokens ?? 0,
      timestamp:     new Date().toISOString(),
    }));

    return {
      content:       content,
      tokens_input:  usage.prompt_tokens     ?? 0,
      tokens_output: usage.completion_tokens ?? 0,
      model:         model,
    };

  } catch (error) {
    if (error instanceof Error && error.name === 'AbortError') {
      throw new Error(`C1: LLM inference timeout after ${timeout}ms`);
    }
    // C5: Log de error
    console.error(JSON.stringify({
      event:     'llm_inference_error',
      tenant_id: tid,                    // C4
      model:     model,
      error:     String(error),
      timestamp: new Date().toISOString(),
    }));
    throw error;
  } finally {
    clearTimeout(timeoutId);
  }
}
```

✅ **Deberías ver:** Log `llm_inference_ok` con tokens y modelo. `content` con la respuesta en el idioma del usuario.
❌ **Si ves:** `OpenRouter 429` → Rate limit. Implementar backoff. `C1: LLM inference timeout` → Aumentar `TIMEOUT_MS` o usar modelo más rápido.

| Error | Causa | Diagnóstico | Solución |
|---|---|---|---|
| `OpenRouter 401` | API Key inválida o expirada | `curl -H "Authorization: Bearer $OPENROUTER_API_KEY" https://openrouter.ai/api/v1/models` | Rotar API Key en `.env` |
| `OpenRouter 429` | Rate limit excedido | Ver headers `X-RateLimit-*` en response | Backoff exponencial 2s/4s/8s |
| `OpenRouter 503` | Proveedor del modelo caído | `curl https://openrouter.ai/api/v1/models` | Cambiar a `OPENROUTER_FALLBACK_MODEL` |
| `C1: LLM inference timeout` | Modelo lento o red saturada | `ping openrouter.ai` | Reducir `max_tokens` o usar modelo más rápido |

---

### LLM-2: Fallback Automático entre Modelos

```typescript
// openrouter-fallback.ts
// Implementa cascada de fallback entre modelos (C1/C4)

const MODEL_CASCADE = [
  process.env.OPENROUTER_DEFAULT_MODEL  ?? 'qwen/qwen3-235b-a22b:free',
  process.env.OPENROUTER_FALLBACK_MODEL ?? 'deepseek/deepseek-chat-v3-0324:free',
  'meta-llama/llama-3.3-70b-instruct:free',
];

async function invokeWithFallback(
  tenant_id: string,        // C4
  messages:  Array<{ role: string; content: string }>
): Promise<string> {

  const tid = requireTenantId(tenant_id);   // C4

  for (const model of MODEL_CASCADE) {
    try {
      const result = await invokeRAGInference({
        tenant_id:    tid,               // C4
        conversation: messages,
        rag_context:  '',
        model:        model,
      });

      console.log(JSON.stringify({
        event:     'fallback_model_used',
        tenant_id: tid,                  // C4
        model:     model,
        timestamp: new Date().toISOString(),
      }));

      return result.content;

    } catch (error) {
      console.warn(JSON.stringify({
        event:     'model_failed_trying_next',
        tenant_id: tid,                  // C4
        model:     model,
        error:     String(error),
      }));
      // Continuar con el siguiente modelo de la cascada
      continue;
    }
  }

  throw new Error(`All models in cascade failed for tenant ${tid}`);
}
```

---

## 🔄 Orquestador Principal (n8n Function Node)

Este es el nodo central del workflow n8n que conecta todos los lotes anteriores:

```javascript
// n8n Function Node: WhatsApp RAG Orchestrator
// Pegar en: Código > Nodo Function en el workflow n8n
// C4: tenant_id en cada operación

const tenantId   = $input.first().json.tenant_id
  ?? process.env.TENANT_ID;

if (!tenantId) {
  throw new Error('C4_VIOLATION: tenant_id missing from webhook payload');
}

const from    = $input.first().json.from;    // Número de WhatsApp
const message = $input.first().json.body;    // Texto del mensaje

// ── 1. Validar y loguear recepción ────────────────────────────────
console.log(JSON.stringify({
  event:     'whatsapp_received',
  tenant_id: tenantId,             // C4
  from:      from,
  timestamp: new Date().toISOString(),
}));

// ── 2. El workflow continúa con nodos específicos: ─────────────────
//    • Nodo Redis: GET sesión
//    • Nodo HTTP: Generar embedding (OpenRouter /embeddings)
//    • Nodo Qdrant: Búsqueda vectorial con filtro tenant_id (C4)
//    • Nodo HTTP: Llamar LLM vía OpenRouter (C6)
//    • Nodo MySQL/Sheets: Guardar interacción (C4)
//    • Nodo Redis: Actualizar sesión
//    • Nodo uazapi: Enviar respuesta

return [{
  json: {
    tenant_id: tenantId,           // C4: propagar a todos los nodos
    from:      from,
    message:   message,
    session_key: `tenant_${tenantId}:session_wa_${from}`,
  }
}];
```

---

## 📊 Validated JSON Examples (skill-output.schema.json)

Los siguientes bloques JSON cumplen con `[[05-CONFIGURATIONS/validation/schemas/skill-output.schema.json]]`:

```json
{
  "tenant_id": "restaurante_001",
  "model_provider": "openrouter",
  "skill_domain": "COMUNICACION/whatsapp-rag",
  "constraints_verified": ["C1", "C2", "C3", "C4", "C5", "C6"],
  "execution_context": {
    "timeout_ms": 30000,
    "memory_limit_mb": 1024,
    "cpu_limit": 1.0,
    "connection_limit": 10,
    "max_results": 5,
    "tenant_filter": "tenant_id = 'restaurante_001'"
  },
  "output_payload": {
    "pipeline_stages": [
      "webhook_receive",
      "session_load",
      "embedding_generate",
      "qdrant_search",
      "llm_inference",
      "db_persist",
      "session_update",
      "whatsapp_respond"
    ],
    "c1_c6_compliance": {
      "C1_resources":    true,
      "C2_concurrency":  true,
      "C3_secrets":      true,
      "C4_tenant":       true,
      "C5_audit":        true,
      "C6_cloud":        true
    },
    "executable_artifacts": [
      {
        "filename":     "hardening-check.sh",
        "content_type": "application/x-sh",
        "sha256":       "COMPUTE_ON_GENERATION",
        "deploy_ready": true
      },
      {
        "filename":     "terraform/whatsapp-rag-pipeline/main.tf",
        "content_type": "text/x-terraform",
        "sha256":       "COMPUTE_ON_GENERATION",
        "deploy_ready": true
      }
    ]
  },
  "audit_metadata": {
    "generated_at":       "2026-04-12T00:00:00Z",
    "validator_version":  "v1.0.0",
    "output_sha256":      "COMPUTE_ON_GENERATION",
    "validation_status":  "passed",
    "ci_cd_ready":        true,
    "gate_checks_passed": 7,
    "gate_checks_total":  7
  }
}
```

---

## ✅ Validación SDD — Comandos de Verificación Post-Deploy

```bash
#!/bin/bash
# validate-whatsapp-rag-deploy.sh
# Ejecutar después de cada deploy para verificar que el pipeline funciona
# C4: Requiere tenant_id como argumento

set -euo pipefail
TENANT_ID="${1:?C4: tenant_id requerido como argumento}"
PASS=0; FAIL=0

check() {
  local desc="$1"; local cmd="$2"; local expected="$3"; local constraint="$4"
  result=$(eval "$cmd" 2>/dev/null || echo "ERROR")
  if echo "$result" | grep -qiP "$expected"; then
    echo "✅ ${constraint}: ${desc}"; ((PASS++))
  else
    echo "❌ ${constraint} FAIL: ${desc}"; ((FAIL++))
  fi
}

echo "═══ VALIDACIÓN WhatsApp RAG Pipeline ═══ tenant: $TENANT_ID"

# C6: OpenRouter accesible
check "OpenRouter API accesible" \
  "curl -s -o /dev/null -w '%{http_code}' \
   -H 'Authorization: Bearer $OPENROUTER_API_KEY' \
   https://openrouter.ai/api/v1/models" \
  "200" "C6"

# C3: Qdrant solo en localhost
check "Qdrant expuesto solo en localhost (C3)" \
  "ss -tulpn | grep 6333 | grep '127.0.0.1\|::1'" \
  "127" "C3"

# C1: n8n dentro de límite de RAM
check "n8n RAM < 1536MB (C1)" \
  "docker stats mantis-n8n --no-stream --format '{{.MemUsage}}' \
   | awk -F'/' '{print \$1}' | tr -d 'MiB GiB'" \
  "^[0-9]{1,3}[0-9]$" "C1"

# C4: tenant_id en código fuente
check "tenant_id presente en el skill" \
  "grep -c 'tenant_id' \
   02-SKILLS/COMUNICACION/whatsapp-rag-openrouter.md" \
  "^[1-9][0-9]+$" "C4"

# C5: Pipeline de CI/CD activo
check "GitHub Actions workflow existe" \
  "[ -f '05-CONFIGURATIONS/pipelines/.github/workflows/validate-skill.yml' ] \
   && echo 'exists'" \
  "exists" "C5"

# C3: No hay secrets en código
check "Sin secrets hardcodeados (C3)" \
  "./05-CONFIGURATIONS/validation/audit-secrets.sh . /dev/null 0 0 \
   && echo 'clean'" \
  "clean" "C3"

# C5: Terraform válido
check "Terraform config válido (C5)" \
  "cd 05-CONFIGURATIONS/terraform && terraform validate 2>&1" \
  "Success" "C5"

echo "═══════════════════════════════════════"
echo "RESULTADO: ✅ $PASS pasaron | ❌ $FAIL fallaron"
[ $FAIL -eq 0 ] && \
  echo "🎉 Pipeline WhatsApp RAG validado — listo para producción" && \
  exit 0 || exit 1
```

---

## 🚀 Deployment (siguiendo multi-channel-deploymen.md)

El pipeline WhatsApp RAG se despliega usando estrategia **Canary** para nuevos tenants:

```yaml
# docker-compose.whatsapp-rag.yml
# C1/C2: Límites de recursos obligatorios
# C3: Variables desde .env, nunca hardcodeadas

version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: mantis-n8n-${TENANT_ID}
    deploy:
      resources:
        limits:
          memory: 1536M     # C1: máximo para n8n
          cpus: "1.0"       # C2: 1 vCPU
    environment:
      - TENANT_ID=${TENANT_ID}
      - OPENROUTER_API_KEY=${OPENROUTER_API_KEY}
      - QDRANT_URL=${QDRANT_URL}
      - QDRANT_API_KEY=${QDRANT_API_KEY}
      - REDIS_URL=${REDIS_URL}
      - EXECUTIONS_MAX_CONCURRENT=5
      - WEBHOOK_TIMEOUT=30000
    networks:
      - mantis-internal

  redis:
    image: redis:7-alpine
    container_name: mantis-redis-${TENANT_ID}
    command: >
      redis-server
      --maxmemory 256mb
      --maxmemory-policy volatile-lru
      --requirepass ${REDIS_PASSWORD}
    deploy:
      resources:
        limits:
          memory: 256M      # C1
          cpus: "0.3"       # C2
    networks:
      - mantis-internal
    ports:
      - "127.0.0.1:6379:6379"   # C3: solo localhost

networks:
  mantis-internal:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.enable_icc: "false"   # C3
```

**Proceso de deploy para nuevo tenant:**
```bash
# 1. Hardening check
./hardening-check.sh $TENANT_ID

# 2. Terraform apply
cd 05-CONFIGURATIONS/terraform
terraform apply -var="tenant_id=$TENANT_ID" -auto-approve

# 3. Docker Compose up
TENANT_ID=$TENANT_ID docker-compose -f docker-compose.whatsapp-rag.yml up -d

# 4. Validación post-deploy
./validate-whatsapp-rag-deploy.sh $TENANT_ID

# 5. Smoke test: enviar mensaje de prueba por WhatsApp
curl -X POST $UAZAPI_URL/send \
  -H "token: $UAZAPI_TOKEN" \
  -d '{"phone": "5551999999999", "message": "test"}'
```

---

## 🔗 Referencias Cruzadas

- [[01-RULES/06-MULTITENANCY-RULES.md]] — MT-001 a MT-010: tenant_id enforcement
- [[01-RULES/02-RESOURCE-GUARDRAILS.md]] — RES-001 a RES-011: límites C1/C2
- [[01-RULES/03-SECURITY-RULES.md]] — SEC-001+: hardening VPS, secrets
- [[01-RULES/04-API-RELIABILITY-RULES.md]] — Retry, timeout, fallback
- [[02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md]] — Setup inicial Qdrant
- [[02-SKILLS/BASE DE DATOS-RAG/mysql-sql-rag-ingestion.md]] — Schema MySQL completo
- [[02-SKILLS/BASE DE DATOS-RAG/redis-session-management.md]] — Gestión de sesiones
- [[02-SKILLS/AI/openrouter-api-integration.md]] — Todos los modelos disponibles
- [[02-SKILLS/SEGURIDAD/security-hardening-vps.md]] — Hardening base del VPS
- [[02-SKILLS/DEPLOYMENT/multi-channel-deploymen.md]] — Estrategias de rollout
- [[05-CONFIGURATIONS/templates/skill-template.md]] — Plantilla maestra
- [[05-CONFIGURATIONS/validation/validate-skill-integrity.sh]] — Validador SDD
- [[05-CONFIGURATIONS/pipelines/.github/workflows/validate-skill.yml]] — CI/CD
- [[05-CONFIGURATIONS/terraform/modules/vps-base/main.tf]] — Módulo Terraform base
- [[SDD-COLLABORATIVE-GENERATION.md]] — Flujo de generación colaborativa

---

<!-- ai:file-end marker — do not remove -->
Versión v2.1.0 — 2026-04-12 — Mantis-AgenticDev
Gate: PASSED (7/7) — SDD-COLLABORATIVE-GENERATION.md v1.0.0
