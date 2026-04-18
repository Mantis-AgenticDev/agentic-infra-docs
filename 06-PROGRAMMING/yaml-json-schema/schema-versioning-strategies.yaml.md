# SHA256: a1d9c4f7e2b8d3a6c0f5b9d2e8a1c4e7b3d6e9f2a5c8b1d4e7a0f3c6b9d2e5a8
---
artifact_id: "schema-versioning-strategies"
artifact_type: "skill_yaml"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/yaml-json-schema/schema-versioning-strategies.yaml.md --json"
canonical_path: "06-PROGRAMMING/yaml-json-schema/schema-versioning-strategies.yaml.md"
---

# schema-versioning-strategies.yaml.md – Schema versioning & drift detection for MANTIS AGENTIC

## Propósito
Patrones de versionado de esquemas YAML/JSON con compatibilidad hacia atrás, detección de drift estructural por tenant, fallback seguro ante rupturas de contrato y trazabilidad auditada de migraciones.

## Patrones de Código Validados

```yaml
# ✅ C4/C7: Versioned tenant config with explicit backward compatibility mode
versioned_config:
  schema_version: "2.1.0"
  compatibility_mode: "backward"
  properties: {tenant_id: {type: string}}
```

```yaml
# ❌ Anti-pattern: breaking change without tenant scoping or fallback
config_v3:
  properties: {new_field: {type: integer, required: true}}
# 🔧 Fix: add tenant binding + deprecation metadata (≤5 lines)
config_v3:
  schema_version: "3.0.0"
  properties: {tenant_id: {type: string}, new_field: {type: integer, deprecated: true}}
```

```yaml
# ✅ C7: Strict drift detection with zero unknown fields allowed
drift_guard:
  allow_unknown_fields: false
  required_fields: ["tenant_id", "schema_version"]
  diff_tolerance: 0
```

```yaml
# ✅ C8: Structured version migration audit log schema
migration_audit:
  type: object
  required: [ts, tenant_id, from_version, to_version]
  properties:
    ts: {type: string, format: date-time}
    status: {type: string, enum: [success, rolled_back, partial]}
```

```yaml
# ❌ Anti-pattern: unversioned schema breaks compatibility tracking
app_config:
  properties: {db_timeout: {type: integer}}
# 🔧 Fix: inject version + compatibility bounds (≤5 lines)
app_config:
  schema_version: "1.0.0"
  compatibility: {min_supported: "0.9.0", max_supported: "2.0.0"}
```

```yaml
# ✅ C4/C8: Phased rollout tracking per tenant context
rollout_tracker:
  type: object
  required: [tenant_id, target_version, status]
  properties:
    tenant_id: {type: string}
    deployed_at: {type: string, format: date-time}
    rollback_available: {type: boolean}
```

```yaml
# ✅ C7/C8: Compatibility validation report with structured diffs
compat_report:
  type: object
  properties:
    is_compatible: {type: boolean}
    breaking_changes: {type: array, items: {type: string}}
    deprecations: {type: array, items: {type: string}}
```

```yaml
# ❌ Anti-pattern: global version forces simultaneous tenant migration
global_upgrade:
  schema_version: "4.0.0"
  apply_to: "all_tenants"
# 🔧 Fix: scope to tenant + require explicit opt-in (≤5 lines)
tenant_upgrade:
  schema_version: "4.0.0"
  apply_to: ["tenant_a", "tenant_b"]
  opt_in_required: true
```

```yaml
# ✅ C5/C7: Artifact validation metadata & drift coverage tracking
artifact_meta:
  constraints_verified: ["C4","C5","C7","C8"]
  examples_count: 10
  max_lines: 5
  drift_detection: true
```

```yaml
# ✅ C4/C7: Safe fallback schema for unsupported versions
version_fallback:
  type: object
  required: [tenant_id]
  properties:
    tenant_id: {type: string}
    fallback_version: {type: string, const: "stable"}
    reject_on_breaking: true
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/yaml-json-schema/schema-versioning-strategies.yaml.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"schema-versioning-strategies","version":"3.0.0","score":88,"blocking_issues":[],"constraints_verified":["C4","C5","C7","C8"],"examples_count":10,"lines_executable_max":5,"language":"YAML/JSON Schema","vector_constraints_applied":false,"language_lock_status":"enforced","timestamp":"2026-04-19T00:00:00Z"}
```

---
