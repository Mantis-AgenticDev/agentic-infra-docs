---
artifact_id: "00-INDEX-yaml-json-schema"
artifact_type: "skill_index"
version: "3.1.0-SELECTIVE"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/yaml-json-schema/00-INDEX.md --json"
canonical_path: "06-PROGRAMMING/yaml-json-schema/00-INDEX.md"
---

# 00-INDEX.md – Índice maestro para yaml-json-schema/ (MANTIS AGENTIC)

## 📋 Propósito para Humanos
Índice canónico de navegación para artifacts YAML/JSON Schema en MANTIS AGENTIC. Proporciona:
1. **Navegación estructurada** mediante wikilinks `[[ruta/archivo]]` a todos los artifacts de la carpeta
2. **Resumen funcional** de cada artifact: propósito, constraints aplicados, ejemplos clave
3. **Mapa de interacciones** con otros módulos del repositorio (validación, configuración, programación)
4. **Guía de ejecución** para validación automatizada via `orchestrator-engine.sh`
5. **Referencia al agente master** `yaml-json-schema-master-agent.md` como punto único de generación

---

## 🤖 Agente de Generación Disponible

| Agente | Canonical Path | Dominio | Constraints Soportados | Hooks de Validación |
|--------|---------------|---------|----------------------|-------------------|
| **`yaml-json-schema-master-agent`** ✅ | `[[06-PROGRAMMING/yaml-json-schema/yaml-json-schema-master-agent.md]]` | `yaml,json,json-schema` | `C1,C2,C3,C4,C5,C7,C8` | `verify-constraints.sh`, `audit-secrets.sh`, `schema-validator.py` |

> ⚠️ **Nota contractual**: Este agente es Tier 1 (referencia educativa). Cualquier esquema generado debe pasar validación automática antes de merge. Documentación técnica en pt-BR: `docs/pt-BR/programming/yaml-json-schema/yaml-json-schema-master-agent/README.md`.

---

## 🗂️ Artifacts Generados (Fase yaml-json-schema)

| Artifact | Constraints | Propósito | Ejemplos | Validación |
|----------|-------------|-----------|----------|------------|
| `[[yaml-json-schema-master-agent.md]]` | C1,C2,C3,C4,C5,C7,C8 | **Agente master**: generación de esquemas production-ready con LANGUAGE LOCK | 15 ✅/❌/🔧 | `orchestrator-engine.sh --file ...` |
| `[[schema-validation-patterns.yaml.md]]` | C1,C3,C4,C5,C6,C7,C8 | Patrones base yamllint/check-jsonschema | 12 ✅/❌/🔧 | `orchestrator-engine.sh --file ...` |
| `[[yaml-security-hardening.yaml.md]]` | C3,C4,C5,C7 | Hardening: tags, anchors, RCE prevention | 10 ✅/❌/🔧 | `orchestrator-engine.sh --file ...` |
| `[[environment-config-schema-patterns.yaml.md]]` | C3,C4,C5,C8 | Env vars schemas + secrets masking | 10 ✅/❌/🔧 | `orchestrator-engine.sh --file ...` |
| `[[multi-tenant-schema-isolation.yaml.md]]` | C3,C4,C5,C8 | Tenant scoping at schema level | 10 ✅/❌/🔧 | `orchestrator-engine.sh --file ...` |
| `[[dynamic-schema-generation.yaml.md]]` | C3,C4,C6,C8 | Context-aware schemas + fallbacks | 11 ✅/❌/🔧 | `orchestrator-engine.sh --file ...` |
| `[[json-pointer-jq-integration.yaml.md]]` | C1,C4,C7,C8 | Safe JSON Pointer + jq transformations | 10 ✅/❌/🔧 | `orchestrator-engine.sh --file ...` |
| `[[schema-versioning-strategies.yaml.md]]` | C4,C5,C7,C8 | Backward compatibility + drift detection | 10 ✅/❌/🔧 | `orchestrator-engine.sh --file ...` |
| `[[json-schema-draft7-draft2020-migration.yaml.md]]` | C4,C5,C6 | Migration patterns + breaking change analysis | 10 ✅/❌/🔧 | `orchestrator-engine.sh --file ...` |
| `[[schema-testing-with-promptfoo.yaml.md]]` | C4,C5,C8 | Promptfoo assertions + test cases | 10 ✅/❌/🔧 | `orchestrator-engine.sh --file ...` |

---

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

# Interacción con agente master
[[yaml-json-schema-master-agent.md]] ← Punto único de generación: consulta este índice ANTES de emitir nuevos artifacts
```

---

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
for f in 06-PROGRAMMING/yaml-json-schema/*.md; do
 grep -qE '<->|<=>|<#>|vector\([0-9]+\)|USING\s+(hnsw|ivfflat)' "$f" && \
 echo "❌ VIOLATION: $f" || echo "✅ OK: $f"
done

# 4. Validación cruzada con norms-matrix.json
jq '.matrix_by_location."06-PROGRAMMING/yaml-json-schema/".extensions.".md".vector_constraints' \
 05-CONFIGURATIONS/validation/norms-matrix.json
# Debe retornar: {"V1":{"hard_block":true}, "V2":{"hard_block":true}, "V3":{"hard_block":true}}

# 5. Validar el agente master mismo
bash 05-CONFIGURATIONS/validation/verify-constraints.sh \
 --file 06-PROGRAMMING/yaml-json-schema/yaml-json-schema-master-agent.md | jq
```

---

## ⚠️ Reglas Críticas de LANGUAGE LOCK para yaml-json-schema/

```text
🚫 PROHIBIDO en esta carpeta:
• Operadores pgvector: <->, <#>, <=>, vector(n), USING hnsw, USING ivfflat
• Constraints vectoriales V1/V2/V3 en constraints_mapped del frontmatter
• SQL embebido con sintaxis de extensión pgvector

✅ REQUERIDO en esta carpeta:
• artifact_type: "skill_yaml" | "skill_index" | "agentic_skill_definition" (NUNCA "skill_pgvector")
• constraints_mapped: SOLO valores de C1-C8 (V* bloqueado por LANGUAGE LOCK)
• Ejemplos en formato ✅/❌/🔧 con ≤5 líneas ejecutables de YAML/JSON puro
• validation_command que referencie orchestrator-engine.sh con canonical_path correcto
• Agente master: consultar norms-matrix.json antes de declarar constraints en artifacts generados
```

---

## 🤖 JSON TREE ENRIQUECIDO PARA IA (Metadatos + Dependencias + Prioridad de Normas)

```json
{
 "index_metadata": {
 "artifact_id": "00-INDEX-yaml-json-schema",
 "artifact_type": "skill_index",
 "version": "3.1.0-SELECTIVE",
 "canonical_path": "06-PROGRAMMING/yaml-json-schema/00-INDEX.md",
 "language_lock_status": "enforced",
 "vector_constraints_applied": false,
 "generated_timestamp": "2026-01-27T00:00:00Z",
 "master_agent": "yaml-json-schema-master-agent"
 },
 "artifacts": [
 {
 "artifact_id": "yaml-json-schema-master-agent",
 "file": "yaml-json-schema-master-agent.md",
 "canonical_path": "06-PROGRAMMING/yaml-json-schema/yaml-json-schema-master-agent.md",
 "artifact_type": "agentic_skill_definition",
 "tier": 1,
 "constraints_mapped": ["C1","C2","C3","C4","C5","C7","C8"],
 "language_lock": ["yaml","json","json-schema"],
 "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "schema-validator.py"],
 "examples_count": 15,
 "score_baseline": 92,
 "dependencies": {
 "validators": ["verify-constraints.sh", "audit-secrets.sh", "schema-validator.py"],
 "norms": ["harness-norms-v3.0.md", "10-SDD-CONSTRAINTS.md", "language-lock-protocol.md"],
 "config": ["norms-matrix.json", "skill-template.md"]
 },
 "dependents": ["all yaml-json-schema artifacts"],
 "norms_priority": {
 "execution_order": ["C4", "C3", "C5", "C7", "C8", "C1", "C2"],
 "blocking_constraints": ["C3", "C4"],
 "rationale": "Security (C3) and tenant isolation (C4) are foundational for schema generation"
 },
 "interactions": {
 "with_validation": "Emits JSON to stdout, logs to stderr, JSONL to 08-LOGS/ per V-INT-03",
 "with_config": "Consults norms-matrix.json before declaring constraints in generated artifacts",
 "with_programming": "Delegates vector operations to postgresql-pgvector/ per LANGUAGE LOCK"
 }
 },
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
 "audit-secrets.sh": ["yaml-security-hardening", "environment-config-schema-patterns", "yaml-json-schema-master-agent"],
 "check-jsonschema": ["schema-validation-patterns", "json-schema-draft7-draft2020-migration"],
 "schema-validator.py": ["yaml-json-schema-master-agent", "dynamic-schema-generation"]
 },
 "norms_layer": {
 "harness-norms-v3.0.md": ["all artifacts"],
 "10-SDD-CONSTRAINTS.md": ["all artifacts"],
 "language-lock-protocol.md": ["all artifacts"],
 "norms-matrix.json": ["all artifacts", "yaml-json-schema-master-agent"]
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
 "required_artifact_types": ["skill_yaml", "skill_index", "agentic_skill_definition"],
 "prohibited_constraints": ["V1", "V2", "V3"],
 "validation_script": "validate-skill-integrity.sh --check-language-lock",
 "failure_action": "exit 2 with message 'LANGUAGE LOCK VIOLATION'"
 },
 "ai_navigation_hints": {
 "for_generation": "Read yaml-json-schema-master-agent.md AND this index BEFORE generating new yaml-json-schema artifacts",
 "for_validation": "Use norms_execution_priority to order constraint checks in custom validators",
 "for_migration": "Consult dependency_graph before modifying shared patterns across artifacts",
 "for_debugging": "Check language_lock_enforcement if pgvector operators appear in yaml-json-schema/ artifacts",
 "for_master_agent": "Agent must consult norms-matrix.json before declaring constraints; emit JSON to stdout, logs to stderr, JSONL to 08-LOGS/"
 }
}
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
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/yaml-json-schema/yaml-json-schema-master-agent.md
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
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/programming/yaml-json-schema/yaml-json-schema-master-agent/README.md
```

---

## 🗂️ RUTAS CANÓNICAS LOCALES – Patrones YAML/JSON Schema (Para Acceso en Repo)

> **Formato**: `RAW_URL` → `./ruta/local/en/repo`

### 📋 Patrones YAML/JSON Schema Core
```text
# Índice y Fundamentos
06-PROGRAMMING/yaml-json-schema/00-INDEX.md
06-PROGRAMMING/yaml-json-schema/yaml-json-schema-master-agent.md
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
docs/pt-BR/programming/yaml-json-schema/yaml-json-schema-master-agent/README.md
```

---

## 🧭 GUÍA DE USO PARA EL AGENTE YAML/JSON SCHEMA

```python
# Pseudocódigo: Cómo consultar patrones disponibles en YAML/JSON Schema
def consultar_patron_schema(nombre_patron: str) -> dict:
 base_raw = "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/"
 base_local = "./06-PROGRAMMING/yaml-json-schema/"

 filename = f"{nombre_patron}.md" if nombre_patron == "yaml-json-schema-master-agent" else f"{nombre_patron}.yaml.md"
 return {
 "raw_url": f"{base_raw}06-PROGRAMMING/yaml-json-schema/{filename}",
 "canonical_path": f"{base_local}{filename}",
 "domain": "06-PROGRAMMING/yaml-json-schema/",
 "language_lock": "yaml,json,json-schema", # 🔒 CERO operadores vectoriales
 "constraints_default": "C3,C4,C5", # Mínimo para producción
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
| **Emite logs estructurados** | JSON a `stdout`, logs humanos a `stderr`, JSONL a `08-LOGS/validation/...` per V-INT-03 y V-LOG-02 |
```

### Paso 3: Validar con `verify-constraints.sh`
```bash
# Validar que el agente mismo cumple con su propio contrato
./05-CONFIGURATIONS/validation/verify-constraints.sh --file 06-PROGRAMMING/yaml-json-schema/yaml-json-schema-master-agent.md | jq
```

---

> 📌 **Nota final**: Este índice es Tier 1 (referencia contractual). Cualquier modificación debe pasar validación automática antes de merge.  
> 🇧🇷 *Documentação técnica completa disponível em*: `docs/pt-BR/programming/yaml-json-schema/00-INDEX/README.md` (próxima entrega).
```

---
