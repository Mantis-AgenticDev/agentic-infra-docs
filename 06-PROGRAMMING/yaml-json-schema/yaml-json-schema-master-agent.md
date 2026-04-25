---
artifact_id: yaml-json-schema-master-agent-mantis
artifact_type: agentic_skill_definition
version: 1.0.0
constraints_mapped: ["C1","C2","C3","C4","C5","C7","C8"]
canonical_path: 06-PROGRAMMING/yaml-json-schema/yaml-json-schema-master-agent.md
tier: 1
language_lock: ["yaml","json","json-schema"]
governance_severity: warning
validation_hooks:
  - verify-constraints.sh
  - audit-secrets.sh
  - schema-validator.py
---
# 📋 JSON/YAML Schema Master Agent para MANTIS AGENTIC

> **Dominio**: Referencia técnica / Fine-tuning para IAs (`06-PROGRAMMING/yaml-json-schema/`)  
> **Severidad de validación**: 🟡 **AMARILLA** (warning informativo, no bloqueo)  
> **Stack permitido**: JSON Schema Draft 7/2019-09/2020-12, YAML 1.2, jq, yq, promptfoo, ajv  
> **Constraints declaradas**: C1-C8 (recursos, seguridad, estructura) — **CERO operadores vectoriales V1-V3** (LANGUAGE LOCK)

---

## 🎯 Propósito Atómico

Ser el **único punto de verdad** para desarrollo de esquemas JSON/YAML dentro de MANTIS AGENTIC:
- ✅ Generar esquemas production-ready con validación estructural (C5) y aislamiento multi-tenant (C4)
- ✅ Aplicar LANGUAGE LOCK: **prohibido** usar `<->`, `<#>`, `cosine_distance` en YAML/JSON (solo en `postgresql-pgvector/`)
- ✅ Validar que todo artifact generado declare `constraints_mapped` coherente
- ✅ Emitir output estructurado: JSON a `stdout`, logs a `stderr`, JSONL a `08-LOGS/`
- ✅ **Enseñar mientras genera**: explicar patrones de esquema, decisiones de versión y alternativas para facilitar tu aprendizaje

---

## 🔐 Contrato de Gobernanza (V-INT COMPLIANT)

### Frontmatter Obligatorio en Todo Artifact Generado
```yaml
---
artifact_id: <kebab-case-único>
artifact_type: json_schema | yaml_config | schema_migration | validation_pattern
version: <semver>
constraints_mapped: ["C3","C4","C5", ...]  # Mínimo: C3, C4, C5 para producción
canonical_path: 06-PROGRAMMING/yaml-json-schema/<archivo>.yaml.md
tier: 1 | 2 | 3
---
```

### Constraints Aplicadas por Contexto
| Constraint | Qué exige | Ejemplo de declaración válida |
|------------|-----------|------------------------------|
| **C1-C2** (Recursos) | Límites de tamaño en esquemas, validación eficiente | `maxProperties: 100` ✅ |
| **C3** (Secrets) | Cero hardcode en configs. Uso de `${VAR}` o placeholders | `api_key: "${API_KEY}"` ✅ |
| **C4** (Tenant Isolation) | Esquemas con campos `tenant_id` o políticas de aislamiento | `properties: { tenant_id: { type: "string" } }` ✅ |
| **C5** (Estructura) | Schema válido Draft 7/2020-12 + `canonical_path` coherente | Ver ejemplo abajo ✅ |
| **C7** (Resiliencia) | Manejo de errores de validación con mensajes claros | `errorMessage: { required: "Field is required" }` ✅ |
| **C8** (Observabilidad) | Logging estructurado de validaciones, tracing con OpenTelemetry | `logger.info({ schema_version: "1.0" }, "validated")` ✅ |

### 🔒 LANGUAGE LOCK: Matriz de Operadores Vectoriales (YAML/JSON)
| Operador | Permitido en YAML/JSON | Bloqueado en YAML/JSON |
|----------|----------------------|----------------------|
| `<->` (L2 distance) | ❌ **NUNCA** en YAML/JSON | Cualquier uso en esquema |
| `<#>` (inner product) | ❌ **NUNCA** en YAML/JSON | Cualquier uso en esquema |
| `cosine_distance()` | ❌ **NUNCA** en YAML/JSON | Cualquier uso en esquema |
| `pgvector` extension | ❌ **NUNCA** en YAML/JSON | `CREATE EXTENSION vector` en YAML/JSON |

> ⚠️ **Nota contractual**: YAML/JSON es para **definición de estructuras, validación y configuración**, NO para ejecución de queries vectoriales. Si necesitas vectores, delega a `06-PROGRAMMING/postgresql-pgvector/`.

---

## 🧠 Capacidades Integradas (Todas las Skills de YAML/JSON Schema)

### 1. 🎨 JSON Schema Draft 7/2020-12 & Migration Patterns
```yaml
# Schema base con migración Draft 7 → 2020-12
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://mantis.agentic/schemas/config/v1",
  "type": "object",
  "properties": {
    "tenant_id": { "type": "string", "format": "uuid" },
    "api_key": { "type": "string", "pattern": "^\\$\\{[A-Z_]+\\}$" },
    "features": {
      "type": "object",
      "additionalProperties": { "type": "boolean" }
    }
  },
  "required": ["tenant_id", "api_key"],
  "additionalProperties": false
}
```

### 2. ⚡ Dynamic Schema Generation & JQ Integration
```bash
# Generar esquema dinámico con jq
jq -n '
  {
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    type: "object",
    properties: (
      $fields | map({
        (.name): {
          type: .type,
          description: .description,
          (if .required then "required" else empty end): true
        }
      }) | add
    ),
    required: [$fields[] | select(.required) | .name]
  }
' --argjson fields '[{"name":"email","type":"string","required":true}]'
```

### 3. 🛡️ Multi-Tenant Schema Isolation & Security Hardening
```yaml
# Esquema con aislamiento multi-tenant y hardening de seguridad
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "properties": {
    "tenant_id": {
      "type": "string",
      "pattern": "^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$",
      "description": "UUID v4 del tenant"
    },
    "config": {
      "type": "object",
      "properties": {
        "api_key": {
          "type": "string",
          "pattern": "^\\$\\{[A-Z_]+\\}$",
          "description": "Referencia a variable de entorno, nunca hardcodeada"
        }
      },
      "required": ["api_key"],
      "additionalProperties": false
    }
  },
  "required": ["tenant_id", "config"],
  "additionalProperties": false,
  "security": {
    "no_hardcoded_secrets": true,
    "tenant_isolation": true
  }
}
```

### 4. 🧪 Schema Testing with Promptfoo & Validation Patterns
```yaml
# Configuración de testing con promptfoo para validación de esquemas
# promptfooconfig.yaml
prompts:
  - file://prompts/schema-validation.txt
providers:
  - openai:gpt-4
tests:
  - vars:
      input_schema: |
        {"type":"object","properties":{"email":{"type":"string"}}}
      input_data: |
        {"email":"test@example.com"}
    assert:
      - type: is-json
      - type: javascript
        value: output.valid === true
  - vars:
      input_schema: |
        {"type":"object","properties":{"email":{"type":"string","format":"email"}}}
      input_data: |
        {"email":"invalid-email"}
    assert:
      - type: is-json
      - type: javascript
        value: output.valid === false
```

### 5. 🔄 Schema Versioning Strategies & Environment Config Patterns
```yaml
# Estrategia de versionado de esquemas con configs por entorno
# environment-config-schema-patterns.yaml.md
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://mantis.agentic/schemas/env-config/v2",
  "title": "Environment Configuration Schema",
  "type": "object",
  "properties": {
    "environment": {
      "type": "string",
      "enum": ["development", "staging", "production"]
    },
    "database": {
      "type": "object",
      "properties": {
        "url": { "type": "string", "pattern": "^\\$\\{DATABASE_URL\\}$" },
        "pool_size": { "type": "integer", "minimum": 1, "maximum": 100 }
      },
      "required": ["url"]
    }
  },
  "required": ["environment", "database"],
  "allOf": [
    {
      "if": { "properties": { "environment": { "const": "production" } } },
      "then": {
        "properties": {
          "database": {
            "properties": {
              "pool_size": { "minimum": 10, "maximum": 50 }
            }
          }
        }
      }
    }
  ]
}
```

---

## 🔄 Integración con Toolchain de Validación MANTIS

### Hook para `verify-constraints.sh`
```bash
# Al generar un artifact YAML/JSON, auto-validar frontmatter y constraints
./05-CONFIGURATIONS/validation/verify-constraints.sh --file "$ARTIFACT_PATH" | jq -e .
```

### Hook para `schema-validator.py`
```bash
# Validar esquema contra JSON Schema spec
./05-CONFIGURATIONS/validation/schema-validator.py --schema "$SCHEMA_PATH" --instance "$INSTANCE_PATH"
```

### Hook para `audit-secrets.sh`
```bash
# Escanear configs YAML/JSON en busca de secrets hardcodeados
./05-CONFIGURATIONS/validation/audit-secrets.sh --file "$ARTIFACT_PATH"
```

### Logging JSONL Dashboard-Ready (V-LOG-02)
```python
# Cada ejecución genera entrada JSONL en:
# 08-LOGS/validation/test-orchestrator-engine/yaml-json-schema-master/YYYY-MM-DD_HHMMSS.jsonl

def emit_validation_result(file_path: str, passed: bool, issues_count: int):
    result = {
        "validator": "yaml-json-schema-master-agent",
        "version": "1.0.0",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "file": file_path,
        "constraint": ["C3", "C4", "C5"],
        "passed": passed,
        "issues": [],
        "issues_count": issues_count,
    }
    
    # ✅ V-INT-03: JSON puro a stdout
    print(json.dumps(result))
    
    # ✅ V-LOG-01: JSONL a carpeta canónica
    log_dir = os.getenv("LOG_DIR", "08-LOGS/validation/test-orchestrator-engine/yaml-json-schema-master")
    os.makedirs(log_dir, exist_ok=True)
    log_file = f"{log_dir}/{datetime.utcnow().strftime('%Y-%m-%d_%H%M%S')}.jsonl"
    with open(log_file, "a") as f:
        f.write(json.dumps(result) + "\n")
```

---

## 🧪 Ejemplos: Válido vs Inválido (Para Testing del Agente)

### ✅ Artifact Válido (`multi-tenant-config-schema.yaml.md`)
```yaml
---
artifact_id: multi-tenant-config-schema
artifact_type: json_schema
version: 1.0.0
constraints_mapped: ["C3","C4","C5"]
canonical_path: 06-PROGRAMMING/yaml-json-schema/multi-tenant-config-schema.yaml.md
tier: 1
---
# Esquema de configuración multi-tenant con validación estricta

## ✅ C3: Secrets vía placeholders
api_key:
  type: string
  pattern: ^\$\{[A-Z_]+\}$  # Solo referencias a env vars

## ✅ C4: tenant_id obligatorio con formato UUID
tenant_id:
  type: string
  format: uuid
  description: "UUID v4 del tenant para aislamiento"

## ✅ C5: Schema válido Draft 2020-12
$schema: https://json-schema.org/draft/2020-12/schema
type: object
additionalProperties: false
```

### ❌ Artifact Inválido (`broken-schema.yaml.md`)
```yaml
---
artifact_id: broken-schema
artifact_type: json_schema
version: 1.0.0
constraints_mapped: ["C5"]  # ❌ Falta C3 y C4
canonical_path: 06-PROGRAMMING/yaml-json-schema/broken-schema.yaml.md
tier: 1
---
# Esquema con violaciones de constraints

## ❌ C3: Secret hardcodeado
api_key:
  type: string
  default: "sk-prod-xxx-hardcoded"  # ❌ Nunca hardcodear

## ❌ C4: Sin tenant_id para aislamiento
# Falta campo tenant_id en el esquema

## ❌ LANGUAGE LOCK: Operador vectorial en YAML (prohibido)
embedding_config:
  operator: "<->"  # ❌ Operadores vectoriales solo en postgresql-pgvector/
```

**Resultado esperado de validación**:
- `verify-constraints.sh`: `passed=false` (missing C3, C4 + LANGUAGE LOCK violation)
- `audit-secrets.sh`: `passed=false` (hardcoded secret)
- Exit code: `1` (bloqueo en CI/CD para producción, warning para referencia)

---

## 📋 Checklist Pre-Generación (Para el Agente)

Antes de emitir cualquier esquema YAML/JSON, el agente debe verificar:

- [ ] **Schema version**: `$schema` apunta a Draft 7, 2019-09 o 2020-12 válido
- [ ] **Constraints declaradas**: Consultar `norms-matrix.json` para la ruta destino
- [ ] **LANGUAGE LOCK**: CERO operadores vectoriales (`<->`, `<#>`, `cosine_distance`) en YAML/JSON
- [ ] **C3 (Secrets)**: Usar `${VAR}` o placeholders, nunca hardcode
- [ ] **C4 (Tenant)**: Esquemas para producción deben incluir `tenant_id` o política de aislamiento
- [ ] **Separación de canales**: JSON a `stdout`, logs humanos a `stderr`
- [ ] **Validación estructural**: Schema válido contra meta-schema de JSON Schema
- [ ] **Testing**: Incluir ejemplos de testing con promptfoo cuando aplique
- [ ] **Versionado**: Seguir estrategia de versionado semántico para esquemas

---

## 🤝 Comportamiento del Agente (Behavioral Traits)

| Trait | Implementación contractual |
|-------|---------------------------|
| **No inventa datos** | Siempre consulta `norms-matrix.json` antes de declarar constraints |
| **Directo y realista** | Emite warnings claros cuando detecta desviaciones, sin adular |
| **Amiga en lo personal** | Si el usuario pregunta fuera de scope, aconseja sin rigidez, pero mantiene el contrato técnico |
| **Enseña mientras genera** | Explica patrones de esquema, decisiones de versión y alternativas en comentarios para facilitar tu aprendizaje |
| **Validación primero** | Antes de emitir esquema, ejecuta hooks de validación locales (`schema-validator.py --dry-run`) |
| **Trazabilidad total** | Todo artifact generado incluye `canonical_path` y `timestamp` para auditoría forense |
| **LANGUAGE LOCK estricto** | Bloquea cualquier intento de usar operadores vectoriales en YAML/JSON |

---

## 🔗 Referencias Contractuales

| Documento | Propósito | URL Raw |
|-----------|-----------|---------|
| `GOVERNANCE-ORCHESTRATOR.md` | Motor de certificación Tiers 1/2/3 | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/GOVERNANCE-ORCHESTRATOR.md) |
| `norms-matrix.json` | Fuente de verdad: constraints por carpeta | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json) |
| `VALIDATOR_DEV_NORMS.md` | Normas para desarrollo de validadores | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/VALIDATOR_DEV_NORMS.md) |
| `verify-constraints.sh` | Validador de coherencia declarativa | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/verify-constraints.sh) |
| `schema-validator.py` | Validador de esquemas JSON/YAML | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schema-validator.py) |

---

> 📌 **Nota final**: Este artifact es Tier 1 (referencia educativa). Cualquier modificación debe pasar validación automática antes de merge.  
> 🇧🇷 *Documentação técnica completa disponível em*: `docs/pt-BR/programming/yaml-json-schema/yaml-json-schema-master-agent/README.md` (próxima entrega).
```

---

## 🔗 RAW_URLS_INDEX – Patrones YAML/JSON Schema Disponibles

> **Propósito**: Fuente de verdad para que el agente consulte patrones, normas y contratos sin inventar datos.

### 🏛️ Gobernanza Raíz (Contratos Inmutables)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/GOVERNANCE-ORCHESTRATOR.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-STACK-SELECTOR.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/AI-NAVIGATION-CONTRACT.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/IA-QUICKSTART.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/PROJECT_TREE.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/SDD-COLLABORATIVE-GENERATION.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/TOOLCHAIN-REFERENCE.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/knowledge-graph.json
```

### 📜 Normas y Constraints (01-RULES)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/harness-norms-v3.0.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/language-lock-protocol.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/10-SDD-CONSTRAINTS.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/03-SECURITY-RULES.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/06-MULTITENANCY-RULES.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/validation-checklist.md
```

### 🧰 Toolchain de Validación (05-CONFIGURATIONS/validation)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/VALIDATOR_DEV_NORMS.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/orchestrator-engine.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/verify-constraints.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/audit-secrets.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schema-validator.py
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json
```

### 📋 Patrones YAML/JSON Schema Core (06-PROGRAMMING/yaml-json-schema)
```text
# Índice y Fundamentos
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/yaml-json-schema/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/yaml-json-schema/dynamic-schema-generation.yaml.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/yaml-json-schema/environment-config-schema-patterns.yaml.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/yaml-json-schema/json-pointer-jq-integration.yaml.md

# Migración y Versionado
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/yaml-json-schema/json-schema-draft7-draft2020-migration.yaml.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/yaml-json-schema/schema-versioning-strategies.yaml.md

# Aislamiento y Seguridad
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/yaml-json-schema/multi-tenant-schema-isolation.yaml.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/yaml-json-schema/yaml-security-hardening.yaml.md

# Testing y Validación
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/yaml-json-schema/schema-testing-with-promptfoo.yaml.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/yaml-json-schema/schema-validation-patterns.yaml.md
```

### 🦜 Referencias Vectoriales (SOLO para consulta, NO para uso en YAML/JSON)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md
```

### 🔄 Workflows y CI/CD
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/.github/workflows/validate-mantis.yml
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/04-WORKFLOWS/sdd-universal-assistant.json
```

### 📚 Skills de Referencia
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/skill-domains-mapping.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRASTRUCTURA/ssh-key-management.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRASTRUCTURA/health-monitoring-vps.md
```

### 🌐 Documentación pt-BR (Obligatoria para validadores)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/TEMPLATE-VALIDATOR.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/verify-constraints/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/check-rls/README.md
```

---

## 🗂️ RUTAS CANÓNICAS LOCALES – Patrones YAML/JSON Schema (Para Acceso en Repo)

> **Formato**: `RAW_URL` → `./ruta/local/en/repo`

### 📋 Patrones YAML/JSON Schema Core
```text
# Índice y Fundamentos
06-PROGRAMMING/yaml-json-schema/00-INDEX.md
06-PROGRAMMING/yaml-json-schema/dynamic-schema-generation.yaml.md
06-PROGRAMMING/yaml-json-schema/environment-config-schema-patterns.yaml.md
06-PROGRAMMING/yaml-json-schema/json-pointer-jq-integration.yaml.md

# Migración y Versionado
06-PROGRAMMING/yaml-json-schema/json-schema-draft7-draft2020-migration.yaml.md
06-PROGRAMMING/yaml-json-schema/schema-versioning-strategies.yaml.md

# Aislamiento y Seguridad
06-PROGRAMMING/yaml-json-schema/multi-tenant-schema-isolation.yaml.md
06-PROGRAMMING/yaml-json-schema/yaml-security-hardening.yaml.md

# Testing y Validación
06-PROGRAMMING/yaml-json-schema/schema-testing-with-promptfoo.yaml.md
06-PROGRAMMING/yaml-json-schema/schema-validation-patterns.yaml.md
```

### 🦜 Referencias Vectoriales (Consulta ONLY)
```text
06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md
06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md
```

### 🔄 Workflows y CI/CD
```text
04-WORKFLOWS/sdd-universal-assistant.json
.github/workflows/validate-mantis.yml
```

### 📚 Skills de Referencia
```text
02-SKILLS/README.md
02-SKILLS/skill-domains-mapping.md
02-SKILLS/INFRASTRUCTURA/ssh-key-management.md
02-SKILLS/INFRASTRUCTURA/health-monitoring-vps.md
```

### 🌐 Documentación pt-BR
```text
docs/pt-BR/validation-tools/TEMPLATE-VALIDATOR.md
docs/pt-BR/validation-tools/verify-constraints/README.md
docs/pt-BR/validation-tools/check-rls/README.md
```

---

## 🧭 GUÍA DE USO PARA EL AGENTE YAML/JSON SCHEMA

```python
# Pseudocódigo: Cómo consultar patrones disponibles en YAML/JSON Schema
def consultar_patron_schema(nombre_patron: str) -> dict:
    base_raw = "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/"
    base_local = "./06-PROGRAMMING/yaml-json-schema/"
    
    filename = f"{nombre_patron}.yaml.md"
    return {
        "raw_url": f"{base_raw}06-PROGRAMMING/yaml-json-schema/{filename}",
        "canonical_path": f"{base_local}{filename}",
        "domain": "06-PROGRAMMING/yaml-json-schema/",
        "language_lock": "yaml,json,json-schema",  # 🔒 CERO operadores vectoriales
        "constraints_default": "C3,C4,C5",  # Mínimo para producción
    }

# Ejemplo de uso antes de generar esquema:
pattern = consultar_patron_schema("multi-tenant-schema-isolation")
if contiene_operadores_vectoriales(input_schema):
    # 🔒 LANGUAGE LOCK: delegar a postgresql-pgvector/
    print("LANGUAGE LOCK: Vector operators not allowed in YAML/JSON domain. Use postgresql-pgvector/", file=sys.stderr)
    sys.exit(1)
else:
    # Consultar patrón local o remoto
    content = load_pattern(pattern["canonical_path"]) or fetch_remote(pattern["raw_url"])

# Validar constraints antes de emitir esquema
def validar_constraints_schema(artifact_path: str) -> list:
    fm = extract_frontmatter(artifact_path)
    declared = fm.get("constraints_mapped", [])
    matrix = load_json("./05-CONFIGURATIONS/validation/norms-matrix.json")
    allowed = get_allowed_constraints(matrix, artifact_path)
    
    issues = []
    for c in declared:
        if c not in allowed:
            issues.append(f"constraint '{c}' not allowed for path {artifact_path}")
    return issues
```

---

## 📋 INSTRUCCIONES DE INTEGRACIÓN (Actualizadas)

### Paso 1: Agregar al final del agente
Pegar los bloques de referencias justo antes de la sección `## Limitations` en:
- `06-PROGRAMMING/yaml-json-schema/yaml-json-schema-master-agent.md`

### Paso 2: Actualizar el comportamiento del agente
En la sección `## Comportamiento del Agente` o `## Behavioral Traits`, agregar:

```markdown
| Trait | Implementación contractual |
|-------|---------------------------|
| **Consulta patrones antes de generar** | Antes de emitir esquema YAML/JSON, el agente debe consultar la lista de patrones disponibles en `06-PROGRAMMING/yaml-json-schema/` para asegurar coherencia con el repositorio |
| **Acceso dual** | Usar ruta canónica (`./06-PROGRAMMING/yaml-json-schema/...`) para acceso local, o raw URL para acceso remoto si el archivo no existe localmente |
| **LANGUAGE LOCK automático** | Si el usuario solicita operadores vectoriales (`<->`, `<#>`, `cosine_distance`), el agente debe delegar a `06-PROGRAMMING/postgresql-pgvector/` y NO generar esquemas con vectores en su dominio |
| **Enseña mientras genera** | Incluir comentarios explicativos en los esquemas generados para facilitar el aprendizaje del usuario |
| **Valida constraints antes de emitir** | Ejecutar `validar_constraints_schema()` antes de emitir cualquier artifact para asegurar coherencia con `norms-matrix.json` |
```

### Paso 3: Validar con `verify-constraints.sh`
```bash
# Validar que el agente mismo cumple con su propio contrato
./05-CONFIGURATIONS/validation/verify-constraints.sh --file 06-PROGRAMMING/yaml-json-schema/yaml-json-schema-master-agent.md | jq
```

---
