---
ai_optimized: true
version: "v1.0.0"
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
purpose: "Plantilla maestra para generación de skills SDD. Define estructura, validación C1-C6, aislamiento multi-tenant, y ejemplos deterministas compatibles con JSON Schema."
tags: ["template", "sdd", "validation", "multi-tenant", "hardened"]
ai_provider: "openrouter"
related_files:
  - "[[01-RULES/00-INDEX.md]]"
  - "[[05-CONFIGURATIONS/validation/schemas/skill-output.schema.json]]"
  - "[[05-CONFIGURATIONS/validation/validate-skill-integrity.sh]]"
  - "[[05-CONFIGURATIONS/validation/audit-secrets.sh]]"
  - "[[05-CONFIGURATIONS/validation/check-rls.sh]]"
---

# 📦 PLANTILLA MAESTRA: [SKILL_NAME]

## 📋 Overview & Scope
| Dimensión | Detalle |
|-----------|---------|
| **Dominio** | `[INFRASTRUCTURA / BASE-DE-DATOS-RAG / COMUNICACION / SEGURIDAD / AI / RESTAURANTES / ...]` |
| **Modelo Base** | `[openrouter / qwen / deepseek / llama / gemini / gpt / minimax / mistral-ocr / voice-agent / image-gen / video-gen]` |
| **Entrada** | `Prompt estructurado, payload JSON, o trigger de workflow n8n` |
| **Salida** | `JSON validado contra schema, artefactos ejecutables, checksum SHA256` |
| **Tenant Scope** | `Aislamiento obligatorio por tenant_id en queries, headers, logs y storage` |

## 🏗️ Constraint Mapping (C1-C6)
| Constraint | Implementación Requerida | Verificación en Script |
|------------|--------------------------|------------------------|
| **C1: RAM≤4GB / Timeouts** | `timeout_ms: 30000`, `memory_limit_mb: 1024`, connection pools ≤50 | `grep -E 'timeout|memory_limit|connectionLimit'` |
| **C2: 1vCPU / Concurrencia** | `cpu_limit: 1.0`, `EXECUTIONS_MAX_CONCURRENT: 5`, `nice/renice` si aplica | `grep -E 'cpu_limit|EXECUTIONS_MAX_CONCURRENT'` |
| **C3: Zero Hardcode** | Todas las credenciales vía `${ENV_VAR}`, `process.env.*`, o secret manager | `audit-secrets.sh` (regex exclusion patterns) |
| **C4: tenant_id Obligatorio** | `WHERE tenant_id = :tenant_id`, headers `X-Tenant-ID`, RLS policies | `check-rls.sh`, `grep -E 'tenant_id|ctx\.tenant'` |
| **C5: Backup + SHA256** | `audit_hash`, checksum pre/post deploy, rotación automática | `sha256sum`, `grep -E 'sha256|audit_hash|checksum'` |
| **C6: Cloud-Only Inference** | API endpoints públicos, zero inferencia local (excepto Llama con `c6_exception_documented: true`) | `grep -E 'openrouter|api\.openai|cloud.*inference|c6_exception'` |

## ⚙️ Configuration & Security (C3)
```env
# ⚠️ NUNCA hardcodear valores. Usar variables de entorno o secret manager.
AI_PROVIDER_API_KEY="${OPENROUTER_API_KEY}"
TENANT_DB_CONN="postgresql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=require"
REDIS_URL="redis://:${REDIS_PASS}@${REDIS_HOST}:${REDIS_PORT}/0"
LOG_LEVEL="warn"
ENABLE_AUDIT="true"
```

## 🛡️ Multi-Tenant & RLS Implementation (C4)
### SQL / Prisma Pattern
```sql
-- C4: Row-Level Security obligatorio
ALTER TABLE skill_executions ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy ON skill_executions
USING (tenant_id = current_setting('app.current_tenant_id')::uuid);

-- C4: Todas las consultas deben filtrar por tenant_id
SELECT * FROM skill_outputs 
WHERE tenant_id = :tenant_id 
AND status = 'completed' 
ORDER BY created_at DESC;
```

### API / Header Propagation
```javascript
// C4: Inyección de tenant desde contexto de request
const tenantId = req.headers['x-tenant-id'] || ctx.metadata.tenant_id;
if (!tenantId) throw new Error('C4_VIOLATION: tenant_id missing');
db.query('SELECT ... WHERE tenant_id = $1', [tenantId]);
```

## 📊 Validated Examples (≥5)
> **Nota**: Cada bloque JSON debe validar contra `skill-output.schema.json`. Los campos `c1_c6_compliance` deben ser explícitamente `true`.

### Ejemplo 01: Validación de Prompt & Schema
```json
{
  "tenant_id": "rest-tenant-001",
  "model_provider": "openrouter",
  "skill_domain": "AI",
  "constraints_verified": ["C1", "C2", "C3", "C4", "C5", "C6"],
  "execution_context": {
    "timeout_ms": 30000,
    "memory_limit_mb": 1024,
    "cpu_limit": 1.0,
    "tenant_filter": "tenant_id = 'rest-tenant-001'"
  },
  "output_payload": {
    "examples": [
      {
        "id": "ex-01",
        "prompt_template": "Genera configuración de validación SDD para tenant {{tenant_id}} con límites C1-C6.",
        "expected_output_schema": { "type": "object", "properties": { "config": { "type": "object" } } },
        "c1_c6_compliance": { "C1_resources": true, "C2_concurrency": true, "C3_secrets": true, "C4_tenant": true, "C5_audit": true, "C6_cloud": true },
        "executable_snippet": "curl -s -H \"Authorization: Bearer ${API_KEY}\" -d '{\"tenant_id\": \"${TENANT}\"}' ${ENDPOINT}",
        "cost_estimate_usd": 0.0012
      }
    ],
    "validation_rules": [
      { "rule_id": "VR-TENANT-001", "condition": "tenant_id matches /^[a-z0-9-]{8,36}$/", "error_message": "C4: tenant_id inválido", "severity": "error" }
    ],
    "executable_artifacts": [
      { "filename": "validate-config.sh", "content_type": "application/x-sh", "content": "#!/bin/bash\necho \"Validating tenant: $TENANT_ID\"", "sha256": "a1b2c3d4e5f6...", "deploy_ready": true }
    ]
  },
  "audit_metadata": {
    "generated_at": "2024-01-01T00:00:00Z",
    "validator_version": "v1.0.0",
    "output_sha256": "PLACEHOLDER_COMPUTE_ON_GENERATION",
    "validation_status": "passed",
    "ci_cd_ready": true
  }
}
```

*(Repetir estructura para ex-02, ex-03, ex-04, ex-05 variando `prompt_template`, `expected_output_schema`, y `executable_snippet`)*

## 🔍 Validation Rules & CI/CD Integration
| Regla | Patrón | Acción si falla |
|-------|--------|-----------------|
| `VR-FRONTMATTER` | `ai_optimized: true` | Rechazar merge |
| `VR-SECRETS` | `0 matches audit-secrets.sh regex` | Fail pipeline, alert |
| `VR-RLS` | `tenant_id` en 100% queries | Bloquear deploy |
| `VR-SCHEMA` | `jsonschema validate skill-output.schema.json` | Rechazar output |
| `VR-CHECKSUM` | `sha256sum -c` verify | Re-generate artifact |

**Pre-commit Hook:**
```bash
#!/bin/sh
exec 05-CONFIGURATIONS/validation/audit-secrets.sh --pre-commit || exit 1
exec 05-CONFIGURATIONS/validation/check-rls.sh --pre-commit || exit 1
```

## 📦 Executable Artifacts & Audit (C5)
- **Artifact 1:** `[nombre_archivo.sh|py|json]` → SHA256: `[checksum]`
- **Artifact 2:** `[nombre_archivo.sql|yml]` → SHA256: `[checksum]`
- **Integridad:** `sha256sum -c artifacts.sha256` debe retornar `OK` antes de cualquier ejecución.
- **Backup:** Copia encriptada con `age -r ${BACKUP_PUB_KEY} -o backup.tar.gz.age` rotada cada 24h.

## 🔗 Cross-References & Navigation
- Arquitectura: `[[01-RULES/01-ARCHITECTURE-RULES.md]]`
- Seguridad: `[[01-RULES/03-SECURITY-RULES.md]]`
- Multi-Tenant: `[[01-RULES/06-MULTITENANCY-RULES.md]]`
- Validadores: `[[05-CONFIGURATIONS/validation/validate-skill-integrity.sh]]`
- Esquema: `[[05-CONFIGURATIONS/validation/schemas/skill-output.schema.json]]`
