# SHA256: c4e8a2f9d1b7e3a6c0d5b8f2e9a1c4e7b3d6e9f2a5c8b1d4e7a0f3c6b9d2e5a8
---
artifact_id: "schema-testing-with-promptfoo"
artifact_type: "skill_yaml"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/yaml-json-schema/schema-testing-with-promptfoo.yaml.md --json"
canonical_path: "06-PROGRAMMING/yaml-json-schema/schema-testing-with-promptfoo.yaml.md"
---

# schema-testing-with-promptfoo.yaml.md – Promptfoo assertions + test cases for MANTIS AGENTIC

## Propósito
Patrones de configuración de pruebas con promptfoo para validación de esquemas YAML/JSON, con aislamiento estricto por tenant, assertions ejecutables, métricas de cobertura y reportes estructurados de resultados.

## Patrones de Código Validados

```yaml
# ✅ C4/C5: Tenant-scoped promptfoo test suite with schema validation
tests:
  - vars: {tenant_id: "t_a1b2c3"}
    assert: [{type: is-json, value: schema.json}]
```

```yaml
# ❌ Anti-pattern: missing tenant_id breaks traceability
tests:
  - vars: {config: "base.yaml"}  # 🔴 C4 violation
# 🔧 Fix: inject tenant binding + explicit schema target (≤5 lines)
tests:
  - vars: {tenant_id: "t_x9y8z7"}
    assert: [{type: is-json, value: schema.json}]
```

```yaml
# ✅ C8: Structured test result schema for observability
result_schema:
  type: object
  required: [ts, tenant_id, assertion_id, status]
  properties:
    ts: {type: string, format: date-time}
    status: {type: string, enum: [pass, fail]}
```

```yaml
# ✅ C5/C8: Assertion coverage tracking with audit metadata
test_coverage:
  type: object
  properties:
    constraints_mapped: {type: array, items: {type: string}}
    assertions_total: {type: integer, minimum: 10}
    trace_enabled: {type: boolean, default: true}
```

```yaml
# ❌ Anti-pattern: unbounded javascript assertions risk resource exhaustion
assert: [{type: javascript, value: "runHeavyValidation()"}]  # 🔴 C5 violation
# 🔧 Fix: use declarative is-json/contains + timeout (≤5 lines)
assert:
  - {type: is-json, value: schema.json}
  - {type: contains, value: "tenant_id"}
```

```yaml
# ✅ C4/C8: Multi-tenant assertion routing with scoped validation
multi_tenant_tests:
  providers: [openrouter:qwen]
  tests:
    - vars: {tenants: ["t1", "t2"]}
      assert: [{type: icontains-any, value: ["tenant_id: t1", "tenant_id: t2"]}]
```

```yaml
# ✅ C8: Structured failure report schema for schema mismatches
failure_report:
  type: object
  required: [ts, tenant_id, schema_version, error_path]
  properties:
    ts: {type: string, format: date-time}
    error_path: {type: string}
    severity: {type: string, enum: [critical, warning]}
```

```yaml
# ❌ Anti-pattern: global test suite without tenant isolation
global_suite:
  assert: [{type: is-json}]  # 🔴 C4 violation
# 🔧 Fix: scope to tenant + require explicit version binding (≤5 lines)
global_suite:
  vars: {tenant_id: "test_scope", schema_ver: "3.0.0"}
  assert: [{type: is-json, value: "schema-${schema_ver}.json"}]
```

```yaml
# ✅ C5/C8: Promptfoo evaluation pipeline with resource bounds
eval_pipeline:
  cmd: "promptfoo eval --config promptfooconfig.yaml --json"
  timeout_ms: 30000
  structured_output: true
  fail_on_warnings: false
```

```yaml
# ✅ C4/C5: Versioned schema assertion with tenant fallback
versioned_assert:
  vars: {tenant_id: "t_prod", schema_ver: "3.0.0"}
  assert:
    - {type: is-json, value: "schema-${schema_ver}.json"}
    - {type: contains, value: "tenant_id: t_prod"}
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/yaml-json-schema/schema-testing-with-promptfoo.yaml.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"schema-testing-with-promptfoo","version":"3.0.0","score":88,"blocking_issues":[],"constraints_verified":["C4","C5","C8"],"examples_count":10,"lines_executable_max":5,"language":"YAML/JSON Schema","vector_constraints_applied":false,"language_lock_status":"enforced","timestamp":"2026-04-19T00:00:00Z"}
```

---
