# SHA256: f7a2e9c4d1b8f3e6a0c5b9d2e8f1a4c7b3d6e9f2a5c8b1d4e7a0f3c6b9d2e5a8
---
artifact_id: "00-INDEX-yaml-json-schema"
artifact_type: "skill_index"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/yaml-json-schema/00-INDEX.yaml.md --json"
canonical_path: "06-PROGRAMMING/yaml-json-schema/00-INDEX.yaml.md"
---

# 00-INDEX.yaml.md – Índice maestro para yaml-json-schema/ (MANTIS AGENTIC)

## 📋 Propósito para Humanos
Índice canónico de navegación para artifacts YAML/JSON Schema en MANTIS AGENTIC. Proporciona:
1. **Navegación estructurada** mediante wikilinks `[[ruta/archivo]]` a todos los artifacts de la carpeta
2. **Resumen funcional** de cada artifact: propósito, constraints aplicados, ejemplos clave
3. **Mapa de interacciones** con otros módulos del repositorio (validación, configuración, programación)
4. **Guía de ejecución** para validación automatizada via `orchestrator-engine.sh`

## 🗂️ Artifacts Generados (Fase yaml-json-schema)

| Artifact | Constraints | Propósito | Ejemplos | Validación |
|----------|-------------|-----------|----------|------------|
| [[06-PROGRAMMING/yaml-json-schema/schema-validation-patterns.yaml.md]] | C1,C3,C4,C5,C6,C7,C8 | Patrones base yamllint/check-jsonschema | 12 ✅/❌/🔧 | `orchestrator-engine.sh --file ...` |
| [[06-PROGRAMMING/yaml-json-schema/yaml-security-hardening.yaml.md]] | C3,C4,C5,C7 | Hardening: tags, anchors, RCE prevention | 10 ✅/❌/🔧 | `orchestrator-engine.sh --file ...` |
| [[06-PROGRAMMING/yaml-json-schema/environment-config-schema-patterns.yaml.md]] | C3,C4,C5,C8 | Env vars schemas + secrets masking | 10 ✅/❌/🔧 | `orchestrator-engine.sh --file ...` |
| [[06-PROGRAMMING/yaml-json-schema/multi-tenant-schema-isolation.yaml.md]] | C3,C4,C5,C8 | Tenant scoping at schema level | 10 ✅/❌/🔧 | `orchestrator-engine.sh --file ...` |
| [[06-PROGRAMMING/yaml-json-schema/dynamic-schema-generation.yaml.md]] | C3,C4,C6,C8 | Context-aware schemas + fallbacks | 11 ✅/❌/🔧 | `orchestrator-engine.sh --file ...` |
| [[06-PROGRAMMING/yaml-json-schema/json-pointer-jq-integration.yaml.md]] | C1,C4,C7,C8 | Safe JSON Pointer + jq transformations | 10 ✅/❌/🔧 | `orchestrator-engine.sh --file ...` |
| [[06-PROGRAMMING/yaml-json-schema/schema-versioning-strategies.yaml.md]] | C4,C5,C7,C8 | Backward compatibility + drift detection | 10 ✅/❌/🔧 | `orchestrator-engine.sh --file ...` |
| [[06-PROGRAMMING/yaml-json-schema/json-schema-draft7-draft2020-migration.yaml.md]] | C4,C5,C6 | Migration patterns + breaking change analysis | 10 ✅/❌/🔧 | `orchestrator-engine.sh --file ...` |
| [[06-PROGRAMMING/yaml-json-schema/schema-testing-with-promptfoo.yaml.md]] | C4,C5,C8 | Promptfoo assertions + test cases | 10 ✅/❌/🔧 | `orchestrator-engine.sh --file ...` |

## 🔗 Interacciones con Otros Módulos del Repositorio

```text
# Dependencias de validación (C5/C8 enforcement)
[[05-CONFIGURATIONS/validation/orchestrator-engine.sh]] ← Ejecuta scoring de todos los artifacts
[[05-CONFIGURATIONS/validation/validate-frontmatter.sh]] ← Valida metadatos de cada artifact
[[05-CONFIGURATIONS/validation/validate-skill-integrity.sh]] ← Verifica LANGUAGE LOCK + selectividad V*

# Dependencias de normas (C1-C8 definitions)
[[01-RULES/harness-norms-v3.0.md]] ← Contrato base de constraints
[[01-RULES/10-SDD-CONSTRAINTS.md]] ← Definiciones técnicas de C1-C8
[[01-RULES/language-lock-protocol.md]] ← Reglas de aislamiento por carpeta

# Dependencias de configuración
[[05-CONFIGURATIONS/validation/norms-matrix.json]] ← Routing de validación selectiva V*
[[05-CONFIGURATIONS/templates/skill-template.md]] ← Plantilla base para generación

# Interacciones con programación
[[06-PROGRAMMING/postgresql-pgvector/00-INDEX.md]] ← Índice hermano (pgvector) – NO comparte V* por LANGUAGE LOCK
[[06-PROGRAMMING/sql/00-INDEX.md]] ← Índice hermano (SQL puro) – LANGUAGE LOCK mutuo

# Interacciones con skills de referencia
[[02-SKILLS/BASE DE DATOS-RAG/environment-variable-management.md]] ← Patrón de env vars reutilizado en environment-config-schema-patterns
[[02-SKILLS/SEGURIDAD/backup-encryption.md]] ← Patrón de secrets masking aplicado en yaml-security-hardening
```

## 🚀 Guía de Ejecución para Validación

```bash
# 1. Validación individual de un artifact
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/yaml-json-schema/schema-validation-patterns.yaml.md \
  --json

# 2. Validación de toda la carpeta yaml-json-schema/
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/yaml-json-schema/ \
  --json 2>/dev/null | jq '.summary'

# 3. Verificación de LANGUAGE LOCK (cero pgvector leakage)
for f in 06-PROGRAMMING/yaml-json-schema/*.yaml.md; do
  grep -qE '<->|<=>|<#>|vector\([0-9]+\)|USING\s+(hnsw|ivfflat)' "$f" && \
    echo "❌ VIOLATION: $f" || echo "✅ OK: $f"
done

# 4. Validación cruzada con norms-matrix.json
jq '.matrix_by_location."06-PROGRAMMING/yaml-json-schema/".extensions.".md".vector_constraints' \
  05-CONFIGURATIONS/validation/norms-matrix.json
# Debe retornar: {"V1":{"hard_block":true}, "V2":{"hard_block":true}, "V3":{"hard_block":true}}
```

## ⚠️ Reglas Críticas de LANGUAGE LOCK para yaml-json-schema/

```text
🚫 PROHIBIDO en esta carpeta:
• Operadores pgvector: <->, <#>, <=>, vector(n), USING hnsw, USING ivfflat
• Constraints vectoriales V1/V2/V3 en constraints_mapped del frontmatter
• SQL embebido con sintaxis de extensión pgvector

✅ REQUERIDO en esta carpeta:
• artifact_type: "skill_yaml" o "skill_index" (NUNCA "skill_pgvector")
• constraints_mapped: SOLO valores de C1-C8
• Ejemplos en formato ✅/❌/🔧 con ≤5 líneas ejecutables de YAML/JSON puro
• validation_command que referencie orchestrator-engine.sh con canonical_path correcto
```

---

## 🤖 JSON TREE ENRIQUECIDO PARA IA (Metadatos + Dependencias + Prioridad de Normas)

```json
{
  "index_metadata": {
    "artifact_id": "00-INDEX-yaml-json-schema",
    "artifact_type": "skill_index",
    "version": "3.0.0-SELECTIVE",
    "canonical_path": "06-PROGRAMMING/yaml-json-schema/00-INDEX.yaml.md",
    "language_lock_status": "enforced",
    "vector_constraints_applied": false,
    "generated_timestamp": "2026-04-19T00:00:00Z"
  },
  "artifacts": [
    {
      "artifact_id": "schema-validation-patterns",
      "file": "schema-validation-patterns.yaml.md",
      "canonical_path": "06-PROGRAMMING/yaml-json-schema/schema-validation-patterns.yaml.md",
      "constraints_mapped": ["C1","C3","C4","C5","C6","C7","C8"],
      "examples_count": 12,
      "score_baseline": 85,
      "dependencies": {
        "validators": ["yamllint", "check-jsonschema", "orchestrator-engine.sh"],
        "norms": ["harness-norms-v3.0.md", "10-SDD-CONSTRAINTS.md"],
        "templates": ["skill-template.md"]
      },
      "dependents": ["environment-config-schema-patterns", "multi-tenant-schema-isolation"],
      "norms_priority": {
        "execution_order": ["C4", "C5", "C3", "C7", "C8", "C1", "C6"],
        "blocking_constraints": ["C4"],
        "rationale": "C4 (tenant_id) must be validated first to ensure isolation before other checks"
      },
      "interactions": {
        "with_validation": "Provides base patterns consumed by validate-frontmatter.sh for C5 checks",
        "with_config": "References norms-matrix.json for constraint routing logic",
        "with_programming": "NO interaction with postgresql-pgvector/ due to LANGUAGE LOCK"
      }
    },
    {
      "artifact_id": "yaml-security-hardening",
      "file": "yaml-security-hardening.yaml.md",
      "canonical_path": "06-PROGRAMMING/yaml-json-schema/yaml-security-hardening.yaml.md",
      "constraints_mapped": ["C3","C4","C5","C7"],
      "examples_count": 10,
      "score_baseline": 87,
      "dependencies": {
        "validators": ["audit-secrets.sh", "verify-constraints.sh"],
        "norms": ["harness-norms-v3.0.md#C3", "language-lock-protocol.md"],
        "security_refs": ["backup-encryption.md"]
      },
      "dependents": ["environment-config-schema-patterns", "dynamic-schema-generation"],
      "norms_priority": {
        "execution_order": ["C3", "C4", "C7", "C5"],
        "blocking_constraints": ["C3", "C4"],
        "rationale": "C3 (secrets) and C4 (tenant_id) are security-critical and must pass before structural checks"
      },
      "interactions": {
        "with_validation": "audit-secrets.sh validates C3 compliance in examples",
        "with_config": "Uses ${VAR:?missing} pattern defined in environment/.env.example",
        "with_programming": "Patterns reusable in go/ and sql/ via LANGUAGE LOCK-aware imports"
      }
    },
    {
      "artifact_id": "environment-config-schema-patterns",
      "file": "environment-config-schema-patterns.yaml.md",
      "canonical_path": "06-PROGRAMMING/yaml-json-schema/environment-config-schema-patterns.yaml.md",
      "constraints_mapped": ["C3","C4","C5","C8"],
      "examples_count": 10,
      "score_baseline": 88,
      "dependencies": {
        "validators": ["validate-frontmatter.sh", "verify-constraints.sh"],
        "norms": ["harness-norms-v3.0.md#C8"],
        "templates": ["bootstrap-company-context.json"]
      },
      "dependents": ["dynamic-schema-generation", "schema-testing-with-promptfoo"],
      "norms_priority": {
        "execution_order": ["C4", "C3", "C8", "C5"],
        "blocking_constraints": ["C4"],
        "rationale": "Tenant isolation (C4) enables correct C8 structured logging per tenant context"
      },
      "interactions": {
        "with_validation": "C8 examples validated by verify-constraints.sh for JSON structure",
        "with_config": "References .env.example for placeholder patterns",
        "with_programming": "Env schema patterns consumed by docker-compose/*.yml validation"
      }
    },
    {
      "artifact_id": "multi-tenant-schema-isolation",
      "file": "multi-tenant-schema-isolation.yaml.md",
      "canonical_path": "06-PROGRAMMING/yaml-json-schema/multi-tenant-schema-isolation.yaml.md",
      "constraints_mapped": ["C3","C4","C5","C8"],
      "examples_count": 10,
      "score_baseline": 86,
      "dependencies": {
        "validators": ["check-rls.sh", "verify-constraints.sh"],
        "norms": ["harness-norms-v3.0.md#C4", "06-MULTITENANCY-RULES.md"],
        "security_refs": ["backup-encryption.md"]
      },
      "dependents": ["dynamic-schema-generation", "schema-versioning-strategies"],
      "norms_priority": {
        "execution_order": ["C4", "C8", "C3", "C5"],
        "blocking_constraints": ["C4"],
        "rationale": "C4 tenant_id validation is foundational; C8 audit trails depend on correct isolation"
      },
      "interactions": {
        "with_validation": "Patterns inform check-rls.sh for SQL-level tenant enforcement",
        "with_config": "Aligns with multi-tenant rules in 06-MULTITENANCY-RULES.md",
        "with_programming": "Schema patterns reusable in postgres-pgvector/ ONLY if V* triggers met"
      }
    },
    {
      "artifact_id": "dynamic-schema-generation",
      "file": "dynamic-schema-generation.yaml.md",
      "canonical_path": "06-PROGRAMMING/yaml-json-schema/dynamic-schema-generation.yaml.md",
      "constraints_mapped": ["C3","C4","C6","C8"],
      "examples_count": 11,
      "score_baseline": 89,
      "dependencies": {
        "validators": ["verify-constraints.sh", "schema-validator.py"],
        "norms": ["harness-norms-v3.0.md#C6"],
        "templates": ["skill-template.md"]
      },
      "dependents": ["schema-versioning-strategies", "schema-testing-with-promptfoo"],
      "norms_priority": {
        "execution_order": ["C4", "C6", "C3", "C8"],
        "blocking_constraints": ["C4", "C6"],
        "rationale": "C6 (executable validation) must succeed before C3/C8 can be meaningfully evaluated"
      },
      "interactions": {
        "with_validation": "C6 examples provide executable commands for orchestrator-engine.sh",
        "with_config": "Fallback patterns align with provider-router.yml error handling",
        "with_programming": "Dynamic resolution logic reusable in go/ MCP services"
      }
    },
    {
      "artifact_id": "json-pointer-jq-integration",
      "file": "json-pointer-jq-integration.yaml.md",
      "canonical_path": "06-PROGRAMMING/yaml-json-schema/json-pointer-jq-integration.yaml.md",
      "constraints_mapped": ["C1","C4","C7","C8"],
      "examples_count": 10,
      "score_baseline": 90,
      "dependencies": {
        "validators": ["verify-constraints.sh", "shellcheck"],
        "norms": ["harness-norms-v3.0.md#C1,C7"],
        "tools": ["jq", "yq", "check-jsonschema"]
      },
      "dependents": ["schema-testing-with-promptfoo", "dynamic-schema-generation"],
      "norms_priority": {
        "execution_order": ["C4", "C7", "C1", "C8"],
        "blocking_constraints": ["C4", "C7"],
        "rationale": "Resource limits (C7) and tenant isolation (C4) prevent unsafe jq execution"
      },
      "interactions": {
        "with_validation": "jq patterns validated by verify-constraints.sh for timeout/resource compliance",
        "with_config": "Resource limits align with docker-compose mem_limit/cpus constraints",
        "with_programming": "Safe jq patterns reusable in bash validation scripts"
      }
    },
    {
      "artifact_id": "schema-versioning-strategies",
      "file": "schema-versioning-strategies.yaml.md",
      "canonical_path": "06-PROGRAMMING/yaml-json-schema/schema-versioning-strategies.yaml.md",
      "constraints_mapped": ["C4","C5","C7","C8"],
      "examples_count": 10,
      "score_baseline": 88,
      "dependencies": {
        "validators": ["verify-constraints.sh", "validate-frontmatter.sh"],
        "norms": ["harness-norms-v3.0.md#C7"],
        "templates": ["skill-template.md"]
      },
      "dependents": ["json-schema-draft7-draft2020-migration"],
      "norms_priority": {
        "execution_order": ["C4", "C7", "C8", "C5"],
        "blocking_constraints": ["C4", "C7"],
        "rationale": "Drift detection (C7) requires correct tenant scoping (C4) to avoid false positives"
      },
      "interactions": {
        "with_validation": "C7 drift patterns inform verify-constraints.sh schema comparison logic",
        "with_config": "Versioning strategy aligns with norms-matrix.json version_history structure",
        "with_programming": "Migration patterns applicable to postgres-pgvector/ ONLY with V* triggers"
      }
    },
    {
      "artifact_id": "json-schema-draft7-draft2020-migration",
      "file": "json-schema-draft7-draft2020-migration.yaml.md",
      "canonical_path": "06-PROGRAMMING/yaml-json-schema/json-schema-draft7-draft2020-migration.yaml.md",
      "constraints_mapped": ["C4","C5","C6"],
      "examples_count": 10,
      "score_baseline": 87,
      "dependencies": {
        "validators": ["check-jsonschema", "verify-constraints.sh"],
        "norms": ["harness-norms-v3.0.md#C6"],
        "tools": ["ajv", "jsonschema-diff"]
      },
      "dependents": [],
      "norms_priority": {
        "execution_order": ["C4", "C6", "C5"],
        "blocking_constraints": ["C4"],
        "rationale": "Tenant binding (C4) must be preserved across schema version migrations"
      },
      "interactions": {
        "with_validation": "Migration commands validated by check-jsonschema for Draft 2020-12 compliance",
        "with_config": "Breaking change analysis aligns with orchestrator-engine.sh tier calculation",
        "with_programming": "Migration patterns inform postgres-pgvector/ schema evolution (with V* triggers)"
      }
    },
    {
      "artifact_id": "schema-testing-with-promptfoo",
      "file": "schema-testing-with-promptfoo.yaml.md",
      "canonical_path": "06-PROGRAMMING/yaml-json-schema/schema-testing-with-promptfoo.yaml.md",
      "constraints_mapped": ["C4","C5","C8"],
      "examples_count": 10,
      "score_baseline": 88,
      "dependencies": {
        "validators": ["promptfoo", "verify-constraints.sh"],
        "norms": ["harness-norms-v3.0.md#C8"],
        "configs": ["promptfoo/config.yaml"]
      },
      "dependents": [],
      "norms_priority": {
        "execution_order": ["C4", "C8", "C5"],
        "blocking_constraints": ["C4"],
        "rationale": "Tenant-scoped assertions (C4) enable meaningful C8 structured test reports"
      },
      "interactions": {
        "with_validation": "Promptfoo assertions consumed by orchestrator-engine.sh for C5 example validation",
        "with_config": "Test config aligns with pipelines/promptfoo/config.yaml structure",
        "with_programming": "Assertion patterns reusable in postgres-pgvector/ testing (with V* triggers)"
      }
    }
  ],
  "dependency_graph": {
    "validation_layer": {
      "orchestrator-engine.sh": ["all artifacts"],
      "validate-frontmatter.sh": ["all artifacts"],
      "validate-skill-integrity.sh": ["all artifacts"],
      "audit-secrets.sh": ["yaml-security-hardening", "environment-config-schema-patterns"],
      "check-jsonschema": ["schema-validation-patterns", "json-schema-draft7-draft2020-migration"]
    },
    "norms_layer": {
      "harness-norms-v3.0.md": ["all artifacts"],
      "10-SDD-CONSTRAINTS.md": ["all artifacts"],
      "language-lock-protocol.md": ["all artifacts"],
      "norms-matrix.json": ["all artifacts"]
    },
    "config_layer": {
      "skill-template.md": ["all artifacts"],
      ".env.example": ["environment-config-schema-patterns", "yaml-security-hardening"],
      "promptfoo/config.yaml": ["schema-testing-with-promptfoo"]
    }
  },
  "norms_execution_priority": {
    "global_order": ["C4", "C3", "C7", "C5", "C8", "C1", "C2", "C6"],
    "rationale": "C4 (tenant isolation) is foundational; security (C3) and safety (C7) precede structural (C5) and observability (C8) checks",
    "blocking_set": ["C3", "C4", "C7"],
    "non_blocking_set": ["C1", "C2", "C5", "C6", "C8"],
    "selective_v_logic": {
      "applies_to": "postgresql-pgvector/ ONLY",
      "trigger": "artifact_type == 'skill_pgvector' AND content has pgvector operators",
      "exclusion": "yaml-json-schema/ ALWAYS excludes V1/V2/V3 per LANGUAGE LOCK"
    }
  },
  "language_lock_enforcement": {
    "folder": "06-PROGRAMMING/yaml-json-schema/",
    "prohibited_patterns": ["<->", "<=>", "<#>", "vector\\([0-9]+\\)", "USING\\s+(hnsw|ivfflat)"],
    "required_artifact_types": ["skill_yaml", "skill_index"],
    "prohibited_constraints": ["V1", "V2", "V3"],
    "validation_script": "validate-skill-integrity.sh --check-language-lock",
    "failure_action": "exit 2 with message 'LANGUAGE LOCK VIOLATION'"
  },
  "ai_navigation_hints": {
    "for_generation": "Read this index FIRST before generating new yaml-json-schema artifacts",
    "for_validation": "Use norms_execution_priority to order constraint checks in custom validators",
    "for_migration": "Consult dependency_graph before modifying shared patterns across artifacts",
    "for_debugging": "Check language_lock_enforcement if pgvector operators appear in yaml-json-schema/ artifacts"
  }
}
```

---
