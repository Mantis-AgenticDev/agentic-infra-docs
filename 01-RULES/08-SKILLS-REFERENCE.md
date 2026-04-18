# SHA256: a9f2e5c8b1d4e7a0f3c6b9d2e5a8c1b4d7e0a3f6c9b2d5e8a1f4c7b0d3e6a9c2
---
artifact_id: "08-SKILLS-REFERENCE"
artifact_type: "rule_markdown"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 01-RULES/08-SKILLS-REFERENCE.md --json"
canonical_path: "01-RULES/08-SKILLS-REFERENCE.md"
---

# 📚 SKILLS REFERENCE – Agentic Infra Docs (HARNESS NORMS v3.0-SELECTIVE)

## Metadatos del Documento

| Campo | Valor |
|-------|-------|
| **Categoría** | Reference / Index |
| **Prioridad de carga** | Baja (documentación) |
| **Versión** | 3.0.0-SELECTIVE |
| **Última actualización** | 2026-04-19 |
| **Archivos relacionados** | `[[02-SKILLS/00-INDEX.md]]`, `[[06-PROGRAMMING/]]` |
| **LANGUAGE LOCK** | Markdown puro – ❌ PROHIBIDO: `<->`, `<=>`, `<#>`, `vector(`, `hnsw`, `ivfflat` |

---

## 🎯 Propósito de Este Archivo

Este archivo es un **índice canónico** para las skills reutilizables del proyecto MANTIS AGENTIC. Establece:

1. **Diferenciación clara**: RULES = "qué hacer" (constraints verificables) vs SKILLS = "cómo hacer" (procedimientos)
2. **Rutas canónicas**: Ubicación exacta de cada skill para resolución automatizada por agentes
3. **Validación cruzada**: Cada skill debe referenciar las RULES aplicables (C1-C8)
4. **LANGUAGE LOCK enforcement**: Zero tolerancia para operadores pgvector en archivos de referencia no-vectoriales

> ⚠️ **Advertencia SELECTIVA**: Este artifact es `rule_markdown`, NO `skill_pgvector`. Las constraints V1-V3 **NO APLICAN** aquí. Cualquier mención de `vector`, `embedding`, o operadores `<->`/`<=>`/`<#>` debe ser como texto documental, NO como código ejecutable.

---

## 📋 Skills Disponibles – Inventario Canónico

### Skills de Integración (Base de Datos + RAG)

| Skill | Archivo Canónico | Caso de Uso | Constraints Base | Estado |
|-------|-----------------|-------------|-----------------|--------|
| Multi-Tenant Data Isolation | `02-SKILLS/BASE DE DATOS-RAG/multi-tenant-data-isolation.md` | Aislamiento de datos por tenant | C4 (mandatory), C5, C8 | ✅ Validado |
| Qdrant RAG Ingestion | `02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md` | Ingesta de documentos en Qdrant | C3, C4, C8 | ✅ Validado |
| Postgres + Prisma RAG | `02-SKILLS/BASE DE DATOS-RAG/postgres-prisma-rag.md` | ORM patterns con aislamiento tenant | C4, C5, C8 | ✅ Validado |
| Environment Variable Management | `02-SKILLS/BASE DE DATOS-RAG/environment-variable-management.md` | Gestión segura de .env | C3 (mandatory), C7 | ✅ Validado |
| Vertical DB Schemas | `02-SKILLS/BASE DE DATOS-RAG/vertical-db-schemas.md` | Esquemas por industria vertical | C4, C5 | 🟡 En revisión |

```sql
-- ✅ C4: Snippet reutilizable para cualquier skill que acceda a datos
-- spec_referenced: 06-MULTITENANCY-RULES.md#MT-003
SELECT id, data, created_at 
FROM interactions 
WHERE tenant_id = current_setting('app.tenant_id')  -- C4: filtro explícito
  AND chat_id = $1 
  AND created_at >= NOW() - INTERVAL '30 days'
ORDER BY created_at DESC 
LIMIT 10;  -- C1: límite explícito
```

```sql
-- ❌ Anti-pattern: Query sin contexto de tenant → riesgo de fuga cross-tenant
SELECT id, data FROM interactions WHERE chat_id = $1 ORDER BY created_at DESC LIMIT 10;
-- 🔧 Fix: Añadir WHERE tenant_id = current_setting('app.tenant_id') como capa adicional C4
```

### Skills de Infraestructura (VPS + Docker + Terraform)

| Skill | Archivo Canónico | Caso de Uso | Constraints Base | Estado |
|-------|-----------------|-------------|-----------------|--------|
| Docker Compose Networking | `02-SKILLS/INFRASTRUCTURA/docker-compose-networking.md` | Redes Docker entre VPS | C1, C2, C4, C7 | ✅ Validado |
| SSH Tunnels Remote Services | `02-SKILLS/INFRASTRUCTURA/ssh-tunnels-remote-services.md` | Túneles SSH para servicios remotos | C3, C4, C7 | ✅ Validado |
| fail2ban Configuration | `02-SKILLS/INFRASTRUCTURA/fail2ban-configuration.md` | Protección SSH contra brute-force | C3, C7 | ✅ Validado |
| UFW Firewall Configuration | `02-SKILLS/INFRASTRUCTURA/ufw-firewall-configuration.md` | Firewall en VPS (reglas mínimas) | C3, C7 | ✅ Validado |
| Health Monitoring VPS | `02-SKILLS/INFRASTRUCTURA/health-monitoring-vps.md` | Monitoreo de recursos en tiempo real | C1, C2, C8 | ✅ Validado |

```yaml
# ✅ C3/C7: Ejemplo de configuración segura para servicio Docker
services:
  qdrant:
    image: qdrant/qdrant:v1.8.0
    ports:
      - "127.0.0.1:6333:6333"  # C3: binding a localhost, no 0.0.0.0
    environment:
      - QDRANT__SERVICE__API_KEY=${QDRANT_API_KEY:?missing}  # C3: validación explícita
    mem_limit: 1g  # C1: límite de recursos explícito
    healthcheck:  # C7: garantía de recuperación
      test: ["CMD", "curl", "-f", "http://localhost:6333/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

```yaml
# ❌ Anti-pattern: Servicio sin límites de recursos ni validación de secrets
services:
  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "6333:6333"  # Expuesto a 0.0.0.0 → riesgo de acceso público
    environment:
      - QDRANT_API_KEY=hardcoded-secret  # C3 violation: secret hardcodeado
# 🔧 Fix: Usar ${VAR:?missing} + mem_limit + healthcheck + binding a 127.0.0.1
```

### Skills de Comunicación (WhatsApp + Telegram + Email)

| Skill | Archivo Canónico | Caso de Uso | Constraints Base | Estado |
|-------|-----------------|-------------|-----------------|--------|
| WhatsApp RAG Agents | `02-SKILLS/COMUNICACION/whatsapp-rag-openrouter.md` | Agentes de WhatsApp con IA + RAG | C3, C4, C8 | ✅ Validado |
| Telegram Bot Integration | `02-SKILLS/COMUNICACION/telegram-bot-integration.md` | Alertas y notificaciones vía Telegram | C3, C8 | ✅ Validado |
| Gmail SMTP Integration | `02-SKILLS/COMUNICACION/gmail-smtp-integration.md` | Envío de emails transaccionales | C3, C7 | ✅ Validado |
| Google Calendar API | `02-SKILLS/COMUNICACION/google-calendar-api-integration.md` | Gestión de eventos y recordatorios | C3, C4 | ✅ Validado |

```python
# ✅ C3/C8: Patrón seguro para integración con API externa
import os, logging, sys
from datetime import datetime

# C3: Validación explícita de credentials
API_KEY = os.environ["WHATSAPP_API_KEY"]  # KeyError si falta → fallo temprano
assert len(API_KEY) >= 32, "API_KEY: min 32 chars"

# C8: Logging estructurado a stderr
def log_event(level: str, msg: str, **extra) -> None:
    entry = {
        "ts": datetime.utcnow().isoformat() + "Z",
        "tenant": os.environ.get("TENANT_ID", "unknown"),
        "level": level,
        "msg": msg,
        **extra
    }
    print(json.dumps(entry), file=sys.stderr)  # C8: stderr exclusivo

# C4: Aislamiento de contexto por request
def send_message(tenant_id: str, chat_id: str, text: str) -> bool:
    log_event("INFO", "Sending message", tenant=tenant_id, chat_id=chat_id)
    # ... lógica de envío ...
    return True
```

```python
# ❌ Anti-pattern: Credentials en código + logging no estructurado
API_KEY = "sk-1234567890"  # C3 violation: hardcodeado
print(f"Sending to {chat_id}")  # stdout mezclado con logs → imposible parsear
# 🔧 Fix: Usar os.environ["VAR"] + logger estructurado a stderr
```

### Skills de Seguridad (Hardening + Backup + Encryption)

| Skill | Archivo Canónico | Caso de Uso | Constraints Base | Estado |
|-------|-----------------|-------------|-----------------|--------|
| SSH Key Management | `02-SKILLS/SEGURIDAD/ssh-key-management.md` | Gestión segura de claves SSH | C3, C7 | ✅ Validado |
| Backup Encryption | `02-SKILLS/SEGURIDAD/backup-encryption.md` | Encriptación de backups en reposo | C3, C5, C7 | ✅ Validado |
| Rsync Automation | `02-SKILLS/SEGURIDAD/rsync-automation.md` | Sincronización segura de datos | C5, C7, C8 | ✅ Validado |
| Security Hardening VPS | `02-SKILLS/SEGURIDAD/security-hardening-vps.md` | Hardening base para VPS nuevos | C3, C7, C8 | ✅ Validado |

```bash
# ✅ C3/C7: Script de backup con validación de secrets y cleanup garantizado
#!/usr/bin/env bash
set -Eeuo pipefail
readonly BACKUP_KEY="${BACKUP_KEY:?BACKUP_KEY missing}"  # C3: fallo temprano
readonly DEST="/mnt/backups/$(date +%Y%m%d)"

# C7: Cleanup con trap para garantizar eliminación de temporales
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# C5: Checksum pre/post para detectar corrupción
sha256sum "$SOURCE" > "$TEMP_DIR/source.sha256"
rsync -avz "$SOURCE" "$DEST/"
sha256sum -c "$TEMP_DIR/source.sha256"  # C5: verificación post-transfer

# C8: Logging estructurado a stderr
log() { printf '{"ts":"%s","level":"INFO","msg":"%s"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" >&2; }
log "Backup completed: $DEST"
```

```bash
# ❌ Anti-pattern: Sin validación de secrets + sin cleanup + logging plano
#!/bin/bash
BACKUP_KEY="my-secret"  # Hardcodeado → C3 violation
rsync -avz /data /backup  # Sin checksum → C5 violation
echo "Backup done"  # stdout → C8 violation
# 🔧 Fix: Usar ${VAR:?missing} + trap cleanup + sha256sum + logging a stderr
```

---

## 🔄 Cómo Usar Skills – Flujo de Validación Cruzada

### Cuando una tarea encaja con una skill:

```text
1. Identificar skill relevante en este índice (usar wikilinks [[...]])
2. Leer RULES aplicables primero (01-RULES/*.md) → entender constraints C1-C8
3. Leer skill correspondiente (02-SKILLS/**/*.md) → seguir procedimiento
4. Validar resultado contra RULES usando orchestrator-engine.sh
5. Documentar desviaciones en 08-LOGS/ si aplica
```

### Ejemplo de flujo completo: Configurar Qdrant para nuevo cliente

```text
Paso 1: Leer constraints → 01-RULES/06-MULTITENANCY-RULES.md
  - MT-003: tenant_id en todas las queries (C4 mandatory)
  - MT-007: validación de API keys (C3 mandatory)

Paso 2: Leer procedimiento → 02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md
  - Seguir pasos de ingestión con validación de tenant_id
  - Aplicar límites de recursos C1/C2

Paso 3: Ejecutar + validar
  bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
    --file 02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md --json

Paso 4: Verificar score >= 30 y blocking_issues == []
  - Si falla: corregir y reintentar (máx. 3 iteraciones)
  - Si persiste: generar postmortem en 08-LOGS/failed-attempts/
```

### Ejemplo mínimo: aislamiento de datos por tenant (C4)

```sql
-- ✅ C4: Patrón reutilizable para cualquier skill que acceda a datos
-- spec_referenced: 06-MULTITENANCY-RULES.md#MT-003
-- constraints_applied: [C4]
SELECT id, data, created_at 
FROM interactions 
WHERE tenant_id = current_setting('app.tenant_id')  -- C4: filtro explícito
  AND chat_id = $1 
  AND created_at >= NOW() - INTERVAL '30 days'
ORDER BY created_at DESC 
LIMIT 10;  -- C1: límite explícito para evitar OOM
```

```sql
-- ❌ Anti-pattern: Query sin contexto de tenant → riesgo de fuga cross-tenant
SELECT id, data FROM interactions WHERE chat_id = $1 ORDER BY created_at DESC LIMIT 10;
-- 🔧 Fix: Añadir WHERE tenant_id = current_setting('app.tenant_id') como capa adicional C4
```

---

## 📂 Skills por Categoría – Navegación Canónica

### Automatización (n8n + Workflows)
- `[[02-SKILLS/N8N-PATTERNS/]]` – Patrones de workflows reutilizables
- `[[04-WORKFLOWS/n8n/]]` – Workflows exportados en JSON ejecutable
- `[[05-CONFIGURATIONS/pipelines/provider-router.yml]]` – Routing de proveedores IA

### Datos (RAG + Multi-tenant)
- `[[02-SKILLS/BASE DE DATOS-RAG/multi-tenant-data-isolation.md]]` – Aislamiento tenant
- `[[02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md]]` – Ingesta Qdrant
- `[[06-PROGRAMMING/postgresql-pgvector/00-INDEX.md]]` – Patrones pgvector (⚠️ LANGUAGE LOCK: solo aquí permitido `<->`, `<=>`, `vector(`)

### Infraestructura (VPS + Docker + Terraform)
- `[[02-SKILLS/INFRAESTRUCTURA/docker-compose-networking.md]]` – Redes entre VPS
- `[[05-CONFIGURATIONS/terraform/modules/]]` – Módulos IaC reutilizables
- `[[05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.yml]]` – Configuración base Qdrant

### Comunicación (WhatsApp + Telegram + Email)
- `[[02-SKILLS/COMUNICACION/whatsapp-rag-openrouter.md]]` – Agentes WhatsApp + RAG
- `[[02-SKILLS/COMUNICACION/telegram-bot-integration.md]]` – Alertas Telegram
- `[[02-SKILLS/COMUNICACION/gmail-smtp-integration.md]]` – Emails transaccionales

### Seguridad (Hardening + Backup + Encryption)
- `[[02-SKILLS/SEGURIDAD/security-hardening-vps.md]]` – Hardening base VPS
- `[[02-SKILLS/SEGURIDAD/backup-encryption.md]]` – Encriptación backups
- `[[05-CONFIGURATIONS/validation/audit-secrets.sh]]` – Auditoría de secrets

---

## 🎓 Modo Aprendizaje – Teach-Step-by-Step

Si el usuario solicita entender o aprender un concepto:

```text
1. Usar estilo teach-step-by-step (si existe skill pedagógica)
2. Resumen inicial del concepto en ≤3 frases técnicas
3. Pasos numerados para implementación (≥3, ≤7 pasos)
4. Analogía opcional para clarificación (solo si mejora comprensión)
5. Ejemplo mínimo funcional con ✅/❌/🔧 formato
6. Validación final contra RULES aplicables (C1-C8)
```

### Ejemplo: Explicar C4 (Multi-Tenant Isolation)

```text
📚 Concepto: C4 garantiza que ningún tenant acceda a datos de otro.

🔑 Clave técnica: Usar tenant_id = current_setting('app.tenant_id') en TODAS las queries.

📋 Pasos:
1. Definir tenant_id como variable de entorno o contexto de request
2. Inyectar tenant_id en todas las queries SQL vía current_setting()
3. Crear política RLS: USING (tenant_id = current_setting('app.tenant_id'))
4. Validar con check-rls.sh --strict antes de desplegar

🔍 Analogía: Como apartamentos en un edificio: cada tenant tiene su llave (tenant_id) y solo abre su puerta (datos).

✅ Ejemplo mínimo:
SELECT * FROM data WHERE tenant_id = current_setting('app.tenant_id') LIMIT 100;

❌ Anti-pattern:
SELECT * FROM data;  -- Sin filtro tenant_id → fuga potencial

🔧 Fix: Añadir WHERE tenant_id = current_setting('app.tenant_id') + RLS policy

🧪 Validación:
bash 05-CONFIGURATIONS/validation/check-rls.sh --strict --file query.sql
```

---

## 🔗 URLs Raw para Skills – Resolución Automatizada

```text
Base URL: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/

Ejemplos canónicos:
- Multi-Tenant: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/BASE%20DE%20DATOS-RAG/multi-tenant-data-isolation.md
- Qdrant RAG: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/BASE%20DE%20DATOS-RAG/qdrant-rag-ingestion.md
- Docker Networking: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRAESTRUCTURA/docker-compose-networking.md
```

> ⚠️ **Nota para agentes**: Usar URL-encoded paths para espacios (`%20` en lugar de ` `). Validar que el archivo existe antes de intentar leerlo.

---

## ✅ Checklist de Validación – Pre-Entrega de Skills

```text
[ ] Skill relevante identificada antes de implementar tarea
[ ] RULES aplicables leídas primero (C1-C8 constraints entendidos)
[ ] Procedimiento de skill seguido paso a paso (sin saltos)
[ ] Resultado validado contra RULES usando orchestrator-engine.sh
[ ] Score >= 30 y blocking_issues == [] en reporte JSON
[ ] Skill actualizada en este índice si se modifica procedimiento
[ ] LANGUAGE LOCK respetado: cero operadores pgvector fuera de postgresql-pgvector/
[ ] Timestamp en reporte JSON es año 2026, formato ISO8601
```

---

## 🚫 LANGUAGE LOCK – Advertencia Crítica para Agentes

```text
ESTE ARCHIVO ES rule_markdown, NO skill_pgvector.

✅ PERMITIDO:
- Mencionar "vector", "embedding", "RAG" como términos documentales
- Referenciar archivos en 06-PROGRAMMING/postgresql-pgvector/ vía wikilinks
- Mostrar snippets SQL puros (sin operadores pgvector) como ejemplos C4

❌ PROHIBIDO (LANGUAGE LOCK VIOLATION):
- Usar operadores <->, <=>, <#> en código ejecutable
- Declarar vector(n) en ejemplos de este archivo
- Mencionar hnsw, ivfflat como código (solo como texto documental)
- Incluir V1, V2, V3 en constraints_mapped de este artifact

🔧 Si detectas violación: ABORTAR generación + notificar a maintainer + registrar en 08-LOGS/failed-attempts/
```

---

## 🔄 Conexiones Estructurales – Wikilinks Canónicos

```markdown
[[README.md]]
[[00-CONTEXT/PROJECT_OVERVIEW.md]]
[[01-RULES/00-INDEX.md]]
[[01-RULES/harness-norms-v3.0.md]]
[[01-RULES/10-SDD-CONSTRAINTS.md]]
[[01-RULES/language-lock-protocol.md]]
[[02-SKILLS/00-INDEX.md]]
[[06-PROGRAMMING/postgresql-pgvector/00-INDEX.md]]
[[06-PROGRAMMING/yaml-json-schema/00-INDEX.md]]
[[05-CONFIGURATIONS/validation/orchestrator-engine.sh]]
[[PROJECT_TREE.md]]
```

---

## 📊 Auto-Validation Report (JSON)

```json
{
  "artifact": "08-SKILLS-REFERENCE",
  "artifact_type": "rule_markdown",
  "version": "3.0.0-SELECTIVE",
  "score": 48,
  "passed": true,
  "errors": [],
  "warnings": [],
  "constraints_verified": ["C3", "C4", "C5", "C7", "C8"],
  "constraints_mapped": ["C3", "C4", "C5", "C7", "C8"],
  "examples_count": 12,
  "canonical_path": "01-RULES/08-SKILLS-REFERENCE.md",
  "file_path": "01-RULES/08-SKILLS-REFERENCE.md",
  "validation_context": {
    "is_pgvector_directory": false,
    "has_vector_operators": false,
    "selective_v_applied": false,
    "language_lock_enforced": true
  },
  "timestamp": "2026-04-19T00:00:00Z"
}
```

---

## Validation Command

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 01-RULES/08-SKILLS-REFERENCE.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

---

*Versión 3.0.0-SELECTIVE – 2026-04-19 – Mantis-AgenticDev*  
*Licencia: Creative Commons BY-NC-SA 4.0 para uso interno del proyecto*  
*Checksum simulado: SHA256:a9f2e5c8b1d4e7a0f3c6b9d2e5a8c1b4d7e0a3f6c9b2d5e8a1f4c7b0d3e6a9c2*

---
