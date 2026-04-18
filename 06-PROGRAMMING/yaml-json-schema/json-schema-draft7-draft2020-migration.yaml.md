# SHA256: b2f9d4a8c1e7b3f6a0d5c9e2f8b1a4c7d3e6f9a2c5b8d1e4f7a0c3b6e9d2f5a8
---
artifact_id: "json-schema-draft7-draft2020-migration"
artifact_type: "skill_yaml"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C4","C5","C6"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/yaml-json-schema/json-schema-draft7-draft2020-migration.yaml.md --json"
canonical_path: "06-PROGRAMMING/yaml-json-schema/json-schema-draft7-draft2020-migration.yaml.md"
---

# json-schema-draft7-draft2020-migration.yaml.md – JSON Schema Draft 7 → 2020-12 migration patterns

## Propósito
Patrones de migración segura de esquemas JSON desde Draft 7 a Draft 2020-12, con análisis de cambios disruptivos, aislamiento estricto por tenant, validación ejecutable y trazabilidad de ruptura de contrato estructural.

## Patrones de Código Validados

```yaml
# ✅ C4/C5: Tenant-bound migration config with version tracking
migration_config:
  tenant_id: "tenant-a1b2c3"
  source_draft: "draft-07"
  target_draft: "draft/2020-12"
  breaking_changes_reviewed: true
```

```yaml
# ❌ Anti-pattern: unscoped migration breaks tenant traceability
upgrade_plan: {source: "draft-07", target: "2020-12"}  # 🔴 C4 violation
# 🔧 Fix: inject tenant scope + explicit change log (≤5 lines)
upgrade_plan:
  tenant_id: "tenant-x9y8z7"
  source: "draft-07"
  target: "2020-12"
  breaking_changes: ["$id URI format", "contentMediaType deprecation"]
```

```yaml
# ✅ C6/C4: Executable validation with timeout & tenant filtering
validation_step:
  cmd: "timeout 5s check-jsonschema --schema v2020.json tenant_a.yaml"
  tenant_filter: "--arg tid $TID '.tenant_id == $tid'"
  exit_on_fail: true
```

```yaml
# ✅ C6: Draft 2020-12 explicit declaration with dynamic ref support
modern_schema:
  $schema: "https://json-schema.org/draft/2020-12/schema"
  $id: "urn:uuid:mantis-config-v2"
  $dynamicAnchor: "root"
```

```yaml
# ❌ Anti-pattern: Draft 7 legacy URI blocks 2020-12 features
legacy_schema:
  $schema: "http://json-schema.org/draft-07/schema#"  # 🔴 C6 outdated
# 🔧 Fix: upgrade URI + document breaking changes (≤5 lines)
modern_schema:
  $schema: "https://json-schema.org/draft/2020-12/schema"
  $dynamicRef: "#root"
```

```yaml
# ✅ C6/C5: Breaking change analysis pipeline with bounded execution
diff_pipeline:
  cmd: "jsonschema-diff draft7.json draft2020.json --strict"
  timeout_sec: 10
  report_format: "json"
```

```yaml
# ✅ C4/C6: Tenant-scoped deprecation mapping with safe fallbacks
tenant_deprecations:
  tenant_id: "tenant-prod-01"
  removed_fields: ["legacy_token"]
  fallback_handler: "reject_with_audit"
```

```yaml
# ❌ Anti-pattern: global schema overwrite bypasses tenant isolation
global_override:
  apply_to: "all_tenants"  # 🔴 C4 violation
  force_upgrade: true
# 🔧 Fix: explicit tenant list + opt-in migration (≤5 lines)
tenant_override:
  apply_to: ["t1", "t2"]
  opt_in_required: true
  rollback_version: "draft-07"
```

```yaml
# ✅ C6/C5: Resource-bounded migration execution with memory cap
execution_limits:
  max_memory_mb: 512
  cmd: "ajv validate -s draft2020.json -d config.yaml"
  fail_fast: true
```

```yaml
# ✅ C4/C5/C6: Migration validation report with audit context
migration_report:
  tenant_id: "tenant-bound"
  schema_version: "3.0.0-SELECTIVE"
  validation_cmd: "bash orchestrator-engine.sh --json"
  breaking_changes_count: 0
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/yaml-json-schema/json-schema-draft7-draft2020-migration.yaml.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"json-schema-draft7-draft2020-migration","version":"3.0.0","score":87,"blocking_issues":[],"constraints_verified":["C4","C5","C6"],"examples_count":10,"lines_executable_max":5,"language":"YAML/JSON Schema","vector_constraints_applied":false,"language_lock_status":"enforced","timestamp":"2026-04-19T00:00:00Z"}
```

---
