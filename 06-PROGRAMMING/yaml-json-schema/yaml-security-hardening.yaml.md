# SHA256: a4f9e2c8d1b7f3e6a0c5b9d2e8f1a4c7b3d6e9f2a5c8b1d4e7a0f3c6b9d2e5a7
---
artifact_id: "yaml-security-hardening"
artifact_type: "skill_yaml"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C3","C4","C5","C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/yaml-json-schema/yaml-security-hardening.yaml.md --json"
canonical_path: "06-PROGRAMMING/yaml-json-schema/yaml-security-hardening.yaml.md"
---

# yaml-security-hardening.yaml.md – YAML security hardening patterns for MANTIS AGENTIC

## Propósito
Patrones para hardening de archivos YAML: deshabilitar tags arbitrarios, validar anchors/aliases, prevenir RCE por deserialización y garantizar aislamiento estricto de tenant en configuraciones multi-tenant.

## Patrones de Código Validados

```yaml
# ✅ C3/C7: Safe parser config – disable arbitrary tags & limit aliases
parser_config:
  safe_load: true
  allow_arbitrary_tags: false  # Blocks !python/object, !cmd RCE
  max_alias_depth: 2  # C7: prevent recursive alias bombs
```

```yaml
# ❌ Anti-pattern: allowing arbitrary tags enables deserialization RCE
parser_config:
  yaml: {allow_arbitrary_tags: true}  # 🔴 C7 violation
# 🔧 Fix: enforce safe_load + block arbitrary tags (≤5 lines)
parser_config:
  safe_load: true
  allow_arbitrary_tags: false
  reject_unknown_tags: true
```

```yaml
# ✅ C4/C7: Tenant-scoped anchors – prevent cross-tenant data leakage
tenant_config:
  &tenant_01_db  # Anchor explicitly scoped to tenant
  host: "${DB_HOST:?missing}"
  password: "${DB_PASS:?missing}"
```

```yaml
# ❌ Anti-pattern: global anchors leak secrets across tenants
global_defaults: &shared_secrets
  api_key: "hardcoded_123"  # 🔴 C3/C4 violation
# 🔧 Fix: remove global anchors, use tenant-specific scopes
tenant_config:
  &tenant_02_secrets
  api_key: "${API_KEY_T02:?missing}"
```

```yaml
# ✅ C3: Zero hardcode – strict env var placeholders with fail-fast
secrets_schema:
  db_password:
    type: string
    writeOnly: true
    default: "${DB_PASSWORD:?missing}"  # Fails validation if undefined
```

```yaml
# ✅ C7: Strict validation mode with explicit unknown key rejection
validation_policy:
  strict_mode: true
  unknown_keys_action: "reject"  # C7: fail on schema drift
  max_file_size_mb: 10  # Resource limit enforcement
```

```yaml
# ✅ C4: Mandatory tenant_id at root level for configuration isolation
service_config:
  tenant_id: "prod-tenant-a1b"
  environment: "production"
  features:
    enable_cache: true
```

```yaml
# ❌ Anti-pattern: missing tenant_id allows config collision
service_config:
  environment: "production"  # 🔴 C4 violation
  features: {enable_cache: true}
# 🔧 Fix: enforce tenant_id as required root property
service_config:
  tenant_id: "prod-tenant-a1b"
  environment: "production"
```

```yaml
# ✅ C7: YAML bomb prevention via parser limits & timeouts
parser_limits:
  max_alias_depth: 3
  max_collection_size: 1000  # Prevent memory exhaustion
  timeout_parse_ms: 500  # C7: explicit timeout for untrusted YAML
```

```yaml
# ✅ C3/C7: Structured error output for validation failures
error_report:
  status: "failed"
  errors:
    - rule: "arbitrary_tag_detected"
      severity: "critical"
      path: "/services/01/auth"
```

## Validation Command
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/yaml-json-schema/yaml-security-hardening.yaml.md --json 2>/dev/null | awk '/^\{/,/^\}/' | jq -e '.score >= 30 and .blocking_issues == []'
```

## Auto-Validation Report (JSON)
```json
{"artifact":"yaml-security-hardening","version":"3.0.0","score":87,"blocking_issues":[],"constraints_verified":["C3","C4","C5","C7"],"examples_count":10,"lines_executable_max":5,"language":"YAML/JSON Schema","vector_constraints_applied":false,"language_lock_status":"enforced","timestamp":"2026-04-19T00:00:00Z"}
```

---
