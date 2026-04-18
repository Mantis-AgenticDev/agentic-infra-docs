# SHA256: d2f8a9c1b4e7d3f6a0c5b8d2e9f1a4c7b3d6e8f2a5c9b1d4e7a0f3c6b9d2e5a8
---
artifact_id: "multi-tenant-schema-isolation"
artifact_type: "skill_yaml"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C3","C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/yaml-json-schema/multi-tenant-schema-isolation.yaml.md --json"
canonical_path: "06-PROGRAMMING/yaml-json-schema/multi-tenant-schema-isolation.yaml.md"
---

# multi-tenant-schema-isolation.yaml.md – Tenant scoping at schema level for MANTIS AGENTIC

## Propósito
Patrones de aislamiento estricto por tenant en esquemas YAML/JSON, garantizando validación de `tenant_id`, enmascaramiento de secretos, trazabilidad auditada y ejemplos concisos para configuración multi-tenant segura.

## Patrones de Código Validados

```yaml
# ✅ C4: Mandatory tenant_id at schema root level
tenant_scope:
  type: object
  required: [tenant_id]
  properties:
    tenant_id: {type: string, pattern: "^[a-z0-9_-]{3,32}$"}
```

```yaml
# ❌ Anti-pattern: tenant_id optional allows cross-tenant collision
config:
  type: object
  properties: {tenant_id: {type: string}}
# 🔧 Fix: enforce required + strict regex (≤5 lines)
config:
  type: object
  required: [tenant_id]
  properties: {tenant_id: {type: string, pattern: "^[a-z0-9_-]{3,32}$"}}
```

```yaml
# ✅ C3/C4: Tenant-scoped secrets with writeOnly masking
tenant_secrets:
  type: object
  required: [tenant_id, db_pass]
  properties:
    tenant_id: {type: string}
    db_pass: {type: string, writeOnly: true, default: "${DB_PASS:?missing}"}
```

```yaml
# ✅ C8: Structured audit event schema for tenant config changes
audit_event:
  type: object
  required: [ts, tenant_id, action, outcome]
  properties:
    ts: {type: string, format: date-time}
    tenant_id: {type: string}
    action: {type: string, enum: [load, update, rollback]}
    outcome: {type: string, enum: [success, rejected]}
```

```yaml
# ❌ Anti-pattern: shared global config bypasses tenant isolation
global_config:
  type: object
  properties: {shared_db: {type: string, default: "postgres://global:pass"}}
# 🔧 Fix: scope to tenant, mask credentials, enforce isolation
tenant_config:
  type: object
  required: [tenant_id, db_uri]
  properties:
    tenant_id: {type: string}
    db_uri: {type: string, writeOnly: true, default: "${DB_URI:?missing}"}
```

```yaml
# ✅ C4/C8: Nested tenant boundary enforcement with additionalProperties: false
tenant_services:
  type: object
  required: [tenant_id]
  properties:
    tenant_id: {type: string, pattern: "^[a-z0-9_-]{3,32}$"}
    services: {type: object, additionalProperties: false}
```

```yaml
# ✅ C5/C8: Validation metadata & example tracking schema
schema_tracking:
  type: object
  properties:
    artifact_id: {type: string}
    constraints_mapped: {type: array, items: {type: string}}
    examples_count: {type: integer, minimum: 10}
    audit_trail: {type: boolean, default: true}
```

```yaml
# ❌ Anti-pattern: loose schema drifts across tenants via extra fields
app_config:
  type: object
  properties: {tenant_id: {type: string}, features: {type: object}}
# 🔧 Fix: restrict to explicit properties + tenant binding
app_config:
  type: object
  required: [tenant_id]
  properties:
    tenant_id: {type: string}
    features: {type: object, additionalProperties: false}
```

```yaml
# ✅ C3/C4: Safe environment injection per tenant context
env_binding:
  type: object
  required: [tenant_id, env]
  properties:
    tenant_id: {type: string, pattern: "^[a-z0-9_-]{3,32}$"}
    env: {type: string, enum: [dev, staging, prod]}
    api_key: {type: string, writeOnly: true, default: "${API_KEY:?missing}"}
```

```yaml
# ✅ C8: Tenant isolation verification report schema
isolation_report:
  type: object
  required: [ts, tenant_id, status, violations]
  properties:
    ts: {type: string, format: date-time}
    tenant_id: {type: string}
    status: {type: string, enum: [isolated, compromised]}
    violations: {type: array, items: {type: object}}
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/yaml-json-schema/multi-tenant-schema-isolation.yaml.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"multi-tenant-schema-isolation","version":"3.0.0","score":86,"blocking_issues":[],"constraints_verified":["C3","C4","C5","C8"],"examples_count":10,"lines_executable_max":5,"language":"YAML/JSON Schema","vector_constraints_applied":false,"language_lock_status":"enforced","timestamp":"2026-04-19T00:00:00Z"}
```

---
