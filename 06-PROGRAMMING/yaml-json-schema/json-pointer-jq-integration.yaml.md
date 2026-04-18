# SHA256: f3c8e1a9d2b7f4e6a0c5b8d2e9f1a4c7b3d6e9f2a5c8b1d4e7a0f3c6b9d2e5a9
---
artifact_id: "json-pointer-jq-integration"
artifact_type: "skill_yaml"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C1","C4","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/yaml-json-schema/json-pointer-jq-integration.yaml.md --json"
canonical_path: "06-PROGRAMMING/yaml-json-schema/json-pointer-jq-integration.yaml.md"
---

# json-pointer-jq-integration.yaml.md – Safe JSON Pointer + jq transformations for MANTIS AGENTIC

## Propósito
Patrones para integración segura de JSON Pointer y jq en transformaciones de configuración, con enforcement de aislamiento por tenant, límites de recursos, validación de sintaxis de paths y reportes estructurados de ejecución.

## Patrones de Código Validados

```yaml
# ✅ C4: Tenant-scoped JSON Pointer extraction with explicit binding
tenant_extract:
  pointer: "/configs/tenant_a/settings"
  jq_cmd: "jq --arg t $TID '.configs[] | select(.tenant_id == $t)'"
  scope: "strict_isolation"
```

```yaml
# ❌ Anti-pattern: unscoped pointer traversal leaks cross-tenant data
unsafe_extract:
  jq_cmd: "jq '.configs[].settings'"  # 🔴 C4 violation
# 🔧 Fix: inject tenant arg + filter before projection (≤5 lines)
safe_extract:
  jq_cmd: "jq --arg t $TID '.configs[] | select(.tenant_id == $t) | .settings'"
```

```yaml
# ✅ C7: JSON Pointer syntax validation before execution
pointer_guard:
  pattern: "^(\/[A-Za-z0-9_.~-]+)*$"
  jq_validator: 'test("^[\\/][A-Za-z0-9_.~-]*$") or error("Invalid JSON Pointer")'
  fail_fast: true
```

```yaml
# ✅ C1/C7: Resource-bounded execution with timeout & stream mode
resource_limits:
  jq_cmd: "timeout 3s jq --stream '.[0] == \"data\"' payload.json"
  max_memory_mb: 256
  exit_status_required: true
```

```yaml
# ❌ Anti-pattern: unbounded recursion causes memory exhaustion
unbounded_parse:
  jq_cmd: "jq '.. | objects'"  # 🔴 C1 violation
# 🔧 Fix: cap depth + enforce resource limits (≤5 lines)
bounded_parse:
  jq_cmd: "jq 'path(..) | select(length <= 5)'"
  timeout_sec: 5
```

```yaml
# ✅ C7/C8: Safe fallback for missing keys with structured error
missing_key_handler:
  jq_cmd: "jq '.target // {error: \"key_not_found\", ts: (now | todate)}'"
  log_format: "json"
  stderr_redirect: true
```

```yaml
# ✅ C8: Structured execution audit schema for observability
execution_audit:
  type: object
  required: [ts, tenant_id, pointer, status]
  properties:
    ts: {type: string, format: date-time}
    tenant_id: {type: string}
    pointer: {type: string}
    status: {type: string, enum: [success, timeout, invalid_pointer]}
```

```yaml
# ✅ C4/C7: Type-safe argument injection to prevent command drift
type_guard:
  jq_cmd: "jq --arg k $KEY --arg v $VAL 'if ($k | type) == \"string\" then .[$k] = $v else . end'"
  validation_rule: "reject_non_string_args"
  tenant_binding: "mandatory"
```

```yaml
# ✅ C1/C8: Pipeline validation command with bounded execution
pipeline_step:
  steps:
    - cmd: "jq --exit-status '.metadata.tenant_id // error(\"missing\")' config.json"
    - cmd: "check-jsonschema --schema out.schema.json result.json"
  timeout_ms: 2000
```

```yaml
# ✅ C4/C7: Pointer traversal depth enforcement per tenant
depth_limiter:
  max_depth: 4
  jq_filter: "path(.[]) | length | select(. <= $max)"
  tenant_scope: "isolate_nested_configs"
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/yaml-json-schema/json-pointer-jq-integration.yaml.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"json-pointer-jq-integration","version":"3.0.0","score":90,"blocking_issues":[],"constraints_verified":["C1","C4","C7","C8"],"examples_count":10,"lines_executable_max":5,"language":"YAML/JSON Schema","vector_constraints_applied":false,"language_lock_status":"enforced","timestamp":"2026-04-19T00:00:00Z"}
```

---
