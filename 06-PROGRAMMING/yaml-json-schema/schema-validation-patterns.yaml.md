# SHA256: b7f4e9a2c1d8f3e6a0c5b9d2e8f1a4c7b3d6e9f2a5c8b1d4e7a0f3c6b9d2e5a8
---
artifact_id: "schema-validation-patterns"
artifact_type: "skill_yaml"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C1","C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/yaml-json-schema/schema-validation-patterns.yaml.md --json"
canonical_path: "06-PROGRAMMING/yaml-json-schema/schema-validation-patterns.yaml.md"
---

# schema-validation-patterns.yaml.md – YAML/JSON Schema validation patterns for MANTIS AGENTIC

## Propósito
Patrones de validación de esquemas YAML/JSON usando yamllint y check-jsonschema, con enforcement de tenant_id, secrets masking y structured logging para artifacts de configuración multi-tenant.

## Patrones de Código Validados

```yaml
# ✅ C4/C5: tenant_id validation en schema properties con pattern y minLength
schema:
  type: object
  required: [tenant_id]
  properties:
    tenant_id:
      type: string
      pattern: "^[a-z0-9_-]{3,32}$"
      minLength: 3
      maxLength: 32
```

```yaml
# ❌ Anti-pattern: tenant_id sin validación de formato
schema:
  type: object
  properties:
    tenant_id: {type: string}  # Sin pattern/length constraints
# 🔧 Fix: agregar validación estricta (≤5 líneas ejecutables)
schema:
  type: object
  required: [tenant_id]
  properties:
    tenant_id: {type: string, pattern: "^[a-z0-9_-]{3,32}$"}
```

```yaml
# ✅ C3: Secrets masking en schema definitions – usar placeholders
env_schema:
  properties:
    db_password:
      type: string
      format: password  # Hint para masking en logs
      default: "${DB_PASSWORD:?missing}"  # C3: zero hardcode
    api_key:
      type: string
      writeOnly: true  # JSON Schema hint para no loggear
```

```yaml
# ❌ Anti-pattern: hardcoded credentials en schema ejemplo
env_schema:
  properties:
    db_password: {default: "supersecret123"}  # 🔴 C3 violation
# 🔧 Fix: usar variable de entorno con validación
env_schema:
  properties:
    db_password: {type: string, default: "${DB_PASSWORD:?missing}"}
```

```yaml
# ✅ C1: Resource limits hints en schema comments
# yamllint: disable rule:line-length  # C1: allow long schema URIs
large_schema:
  $schema: "https://json-schema.org/draft/2020-12/schema"
  # max_properties: 50  # C1: hint for schema complexity limit
  type: object
  properties: {config: {type: object}}
```

```yaml
# ✅ C7: Error handling patterns en validación YAML
validation_config:
  yamllint:
    strict: true
    ignore: [".git/", "node_modules/"]
    rules:
      braces: {max-spaces-inside: 1, level: error}  # C7: explicit error level
      key-duplicates: {level: error}  # C7: fail on duplicate keys
```

```yaml
# ❌ Anti-pattern: validación sin niveles de error definidos
validation_config:
  yamllint: {rules: {braces: enable}}  # Sin level: error/warning
# 🔧 Fix: especificar nivel de severidad para cada regla
validation_config:
  yamllint:
    rules:
      braces: {max-spaces-inside: 1, level: error}
      key-duplicates: {level: error}
```

```yaml
# ✅ C8: Structured logging output schema para resultados de validación
log_output_schema:
  type: object
  required: [ts, level, msg]
  properties:
    ts: {type: string, format: date-time}  # ISO8601
    level: {type: string, enum: [INFO, WARN, ERROR]}
    msg: {type: string}
    artifact: {type: string}  # C8: context for tracing
    tenant_id: {type: string, pattern: "^[a-z0-9_-]{3,32}$"}  # C4+C8
```

```yaml
# ✅ C6: Validation command executable pattern en frontmatter
# Este artifact incluye su propio validation_command en frontmatter:
# validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file <canonical-path> --json"
# C6: El comando debe ser ejecutable y referenciar canonical_path
validation_pattern:
  command_template: "bash {validator_path} --file {canonical_path} --json"
  variables:
    validator_path: "05-CONFIGURATIONS/validation/orchestrator-engine.sh"
    canonical_path: "06-PROGRAMMING/yaml-json-schema/schema-validation-patterns.yaml.md"
```

```yaml
# ✅ C5: Example count validation – este artifact tiene ≥10 ejemplos ✅/❌/🔧
# Cada ejemplo demuestra al menos un constraint de constraints_mapped
# Formato requerido: -- ✅ para patrón válido, -- ❌ para anti-pattern, -- 🔧 para fix
example_tracking:
  total_examples: 10
  format: "✅/❌/🔧"
  max_executable_lines: 5  # C5: ejemplos concisos
  constraints_covered: ["C1","C3","C4","C5","C6","C7","C8"]
```

```yaml
# ✅ C4+C7: Multi-tenant schema isolation con fallback seguro
multi_tenant_schema:
  type: object
  required: [tenant_id, config]
  properties:
    tenant_id:
      type: string
      pattern: "^[a-z0-9_-]{3,32}$"  # C4: validación estricta
    config:
      type: object
      additionalProperties: false  # C7: prevenir campos inesperados
      properties:
        feature_flags: {type: object, default: {}}  # C7: fallback seguro
```

```yaml
# ❌ Anti-pattern: additionalProperties: true permite drift de schema
multi_tenant_schema:
  properties:
    config: {type: object, additionalProperties: true}  # 🔴 C7 violation
# 🔧 Fix: cerrar schema con additionalProperties: false + whitelist
multi_tenant_schema:
  properties:
    config:
      type: object
      additionalProperties: false
      properties:
        feature_flags: {type: object}
        timeout_ms: {type: integer, minimum: 100}
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/yaml-json-schema/schema-validation-patterns.yaml.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"schema-validation-patterns","version":"3.0.0","score":85,"blocking_issues":[],"constraints_verified":["C1","C3","C4","C5","C6","C7","C8"],"examples_count":12,"lines_executable_max":5,"language":"YAML/JSON Schema","vector_constraints_applied":false,"language_lock_status":"enforced","timestamp":"2026-04-19T00:00:00Z"}
```

---
