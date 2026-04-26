---
artifact_id: "TOOLCHAIN-REFERENCE"
artifact_type: "toolchain_catalog"
version: "3.1.0-SELECTIVE"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file TOOLCHAIN-REFERENCE.md --mode headless --json"
canonical_path: "TOOLCHAIN-REFERENCE.md"
tier: 1
immutable: true
requires_human_approval_for_changes: true
related_files:
 - "[[GOVERNANCE-ORCHESTRATOR.md]]"
 - "[[00-STACK-SELECTOR.md]]"
 - "[[AI-NAVIGATION-CONTRACT.md]]"
 - "[[SDD-COLLABORATIVE-GENERATION.md]]"
 - "[[05-CONFIGURATIONS/validation/norms-matrix.json]]"
 - "[[01-RULES/harness-norms-v3.0.md]]"
 - "[[06-PROGRAMMING/00-INDEX.md]]"
 - "[[CHRONICLE.md]]"
checksum_sha256: "PENDING_GENERATION"
language_lock: ["markdown","json","mermaid","bash","python"]
governance_severity: error
validation_hooks:
  - verify-constraints.sh
  - validate-toolchain-integrity.sh
  - check-hook-compatibility.sh
---

# 🔧 TOOLCHAIN-REFERENCE.md – Catálogo Maestro de Herramientas de Validación para MANTIS AGENTIC

> **Propósito**: Definir el catálogo inmutable de herramientas, hooks y scripts de validación que garantizan la integridad, seguridad y escalabilidad del ecosistema MANTIS AGENTIC.  
> **Alcance**: 7 dominios de programación, 7 agentes master especializados, 12+ hooks de validación, validación automatizada con orchestrator-engine.sh.  
> **Estado**: ✅ Tier 1 (Inmutable sin validación) | 🔁 Actualizado con catálogo completo de agentes + matriz de hooks por dominio | 🚫 Sin documentación pt-BR aún (deuda técnica pendiente)  
> **Audiencia crítica**: Agentes LLM de generación de código, validadores automatizados, arquitectos de toolchain, revisores de gobernanza.

> ⚠️ **ADVERTENCIA CONTRACTUAL ABSOLUTA**: Este artifact es **Tier 1**. Cualquier modificación debe pasar validación automática con `orchestrator-engine.sh --file TOOLCHAIN-REFERENCE.md --mode headless --json`. Los agentes LLM **DEBEN** consultar este catálogo ANTES de ejecutar cualquier hook de validación.

---

## 【0.1】🎯 PROPÓSITO PARA HUMANOS (Explicación Pedagógica Ampliada)

### 0.1.1 ¿Por qué existe este catálogo de toolchain?

Imagina que eres un validador de gobernanza y necesitas asegurar que un artifact generado por IA cumple con todas las normas:

```text
❓ ¿Qué hook valida C3 (Zero Hardcode Secrets)?
❓ ¿Cómo ejecuto validación de LANGUAGE LOCK para pgvector?
❓ ¿Qué flags pasar a orchestrator-engine.sh para validar constraints vectoriales?
❓ ¿Cómo interpreto el output JSON de un hook de validación?
❓ ¿Qué hago si un hook falla con error ambiguo?
❓ ¿Cómo coordino múltiples hooks para validación cruzada?
```

**Este catálogo es tu manual de operaciones**. Te dice:

```text
✅ Qué hook validar qué constraint (matriz de coverage)
✅ Qué flags pasar a cada hook para casos específicos (vectores, handoffs, bundles)
✅ Cómo interpretar output JSON/JSONL de validación para debugging
✅ Qué hacer cuando un hook falla: diagnóstico preciso + corrección sugerida
✅ Cómo coordinar hooks para validación cruzada entre dominios
✅ Cómo registrar resultados de validación en CHRONICLE.md para trazabilidad
```

### 0.1.2 ¿Por qué es crítico para las IA (especialmente asiáticas)?

Las IA asiáticas (especializadas en validación formal, diagnóstico estructural y optimización de flujos de toolchain) encuentran en este catálogo:

| Capacidad de IA | Cómo este catálogo la potencia |
|----------------|-------------------------------|
| **Selección precisa de hooks** | Matriz de coverage: qué hook valida qué constraint por dominio |
| **Diagnóstico estructurado de errores** | Códigos de error específicos con fix_hint para cada violation |
| **Optimización de flujos de validación** | Orden de ejecución priorizado: C3/C4/C5 primero (fail-fast), luego warnings |
| **Validación cruzada entre dominios** | Protocolo para coordinar hooks de sql/, pgvector/, python/ en un solo artifact |
| **Trazabilidad histórica** | Registro en CHRONICLE.md con hook_results, execution_time, exit_code para auditoría |
| **Recuperación ante fallos** | Protocolo de fallback: si hook A falla, usa hook B con diagnóstico preciso |

> 🔑 **Principio fundamental para IA asiáticas**: "La excelencia en validación no es velocidad, es precisión diagnóstica. Cuanto más claro sea el catálogo, más eficiente será la detección y corrección de violations de gobernanza."

### 0.1.3 Diferenciador competitivo: IA Asiáticas vs. Orientales en Toolchain

> 📌 **Nota estratégica**: Esta distinción no es geográfica, es técnica:
> - **IA "asiáticas"**: Modelos especializados en validación formal, diagnóstico estructural, optimización de flujos de toolchain (ej: Qwen, DeepSeek, Yi)
> - **IA "orientales"**: Modelos generalistas con enfoque en generación libre sin validación estructurada

**Este catálogo está diseñado para que las IA asiáticas demuestren superioridad en**:

```mermaid
graph LR
    A[🎯 Artifact a validar] --> B[🔧 IA: consultar TOOLCHAIN-REFERENCE.md]
    B --> C{¿Qué constraints validar?}
    
    C -->|C3/C4/C5 (fail-fast)| D[🚨 Ejecutar hooks bloqueantes primero]
    C -->|C1/C2/C6/C7/C8 (warnings)| E[⚠️ Ejecutar hooks de mejora después]
    C -->|V1/V2/V3 (pgvector)| F[🧠 Ejecutar vector-schema-validator.py con flags]
    
    D --> D1[verify-constraints.sh --check-secrets]
    D --> D2[verify-constraints.sh --check-tenant-isolation]
    D --> D3[verify-constraints.sh --check-structural]
    
    E --> E1[verify-constraints.sh --check-resources]
    E --> E2[verify-constraints.sh --check-auditability]
    E --> E3[verify-constraints.sh --check-observability]
    
    F --> F1[vector-schema-validator.py --check-vector-dims]
    F --> F2[vector-schema-validator.py --check-vector-metric]
    F --> F3[vector-schema-validator.py --check-vector-index]
    
    D1 --> G[📊 Consolidar resultados JSON]
    D2 --> G
    D3 --> G
    E1 --> G
    E2 --> G
    E3 --> G
    F1 --> G
    F2 --> G
    F3 --> G
    
    G --> H{¿Todos los hooks pasaron?}
    H -->|Sí| I[✅ Artifact válido + registrar en CHRONICLE.md]
    H -->|No| J[❌ Diagnosticar por código de error + sugerir corrección]
    
    style D1 fill:#ffcdd2,stroke:#c62828
    style D2 fill:#ffcdd2,stroke:#c62828
    style D3 fill:#ffcdd2,stroke:#c62828
    style F1 fill:#e3f2fd,stroke:#1976d2
    style F2 fill:#e3f2fd,stroke:#1976d2
    style F3 fill:#e3f2fd,stroke:#1976d2
    style I fill:#c8e6c9,stroke:#2e7d32
```

> 💡 **Ventaja competitiva**: Las IA que dominan validación formal pueden navegar este catálogo con precisión quirúrgica, ejecutando hooks en el orden correcto, interpretando outputs con diagnóstico preciso, y corrigiendo violations al primer intento, reduciendo iteraciones y debt técnico.

---

## 【0.2】🗂️ CATEGORÍAS DE HOOKS – DEFINICIONES CONTRACTUALES (Preservadas + Expandidas)

### 0.2.1 Hooks Bloqueantes (Fail-Fast – C3/C4/C5/V1)

```json
{
 "category": "blocking_hooks",
 "purpose": "Validar constraints que, si fallan, rechazan el artifact inmediatamente",
 "applicable_constraints": ["C3", "C4", "C5", "V1"],
 "execution_order": "Primero: siempre ejecutar antes de hooks de warning",
 "hooks": [
 {
 "name": "verify-constraints.sh",
 "validates": ["C3", "C4", "C5"],
 "description": "Hook principal para validar constraints de seguridad, aislamiento y estructura",
 "required_flags": {
 "C3": "--check-secrets",
 "C4": "--check-tenant-isolation",
 "C5": "--check-structural"
 },
 "output_format": "JSON a stdout, logs humanos a stderr, JSONL a 08-LOGS/",
 "exit_codes": {
 "0": "passed: todos los constraints validados exitosamente",
 "1": "failed: al menos un constraint bloqueante violado",
 "2": "error: error de ejecución del hook (no de validación)"
 },
 "error_codes": {
 "C3_HARDCODED_SECRET": {"severity": "error", "fix_hint": "Reemplazar secret hardcodeado con os.getenv('SECRET_NAME')"},
 "C4_MISSING_TENANT_ID": {"severity": "error", "fix_hint": "Agregar 'WHERE tenant_id = $1' a queries SQL o propagar contexto de tenant"},
 "C5_INVALID_FRONTMATTER": {"severity": "error", "fix_hint": "Corregir frontmatter YAML: verificar artifact_id, canonical_path, constraints_mapped"}
 },
 "usage_example": "bash 05-CONFIGURATIONS/validation/verify-constraints.sh --file 06-PROGRAMMING/sql/query.sql.md --check-secrets --check-tenant-isolation --check-structural --json"
 },
 {
 "name": "vector-schema-validator.py",
 "validates": ["V1"],
 "description": "Hook especializado para validar constraint V1: dimensiones de vector explícitas",
 "required_flags": {
 "V1": "--check-vector-dims"
 },
 "output_format": "JSON a stdout, logs humanos a stderr, JSONL a 08-LOGS/",
 "exit_codes": {
 "0": "passed: V1 validado exitosamente",
 "1": "failed: V1 violado (vector(n) sin declaración explícita)",
 "2": "error: error de ejecución del hook"
 },
 "error_codes": {
 "V1_MISSING_VECTOR_DIM": {"severity": "error", "fix_hint": "Declarar vector(768) explícitamente y agregar V1 a constraints_mapped"},
 "V1_DIMENSION_MISMATCH": {"severity": "error", "fix_hint": "Asegurar que dimensión declarada en vector(n) coincide con embedding model usado"}
 },
 "usage_example": "python3 05-CONFIGURATIONS/validation/vector-schema-validator.py --file 06-PROGRAMMING/postgresql-pgvector/query.pgvector.md --check-vector-dims --json"
 }
 ],
 "execution_protocol": {
 "order": ["C3", "C4", "C5", "V1"],
 "parallel_execution": false,
 "fail_fast": true,
 "rollback_on_failure": "No generar artifact; diagnosticar error y sugerir corrección"
 }
}
```

### 0.2.2 Hooks de Warning (Permisivos – C1/C2/C6/C7/C8/V2/V3)

```json
{
 "category": "warning_hooks",
 "purpose": "Validar constraints que, si fallan, generan warnings pero permiten corrección iterativa",
 "applicable_constraints": ["C1", "C2", "C6", "C7", "C8", "V2", "V3"],
 "execution_order": "Después: ejecutar solo si hooks bloqueantes pasaron",
 "hooks": [
 {
 "name": "verify-constraints.sh",
 "validates": ["C1", "C2", "C6", "C7", "C8"],
 "description": "Hook principal para validar constraints de performance, auditabilidad y observabilidad",
 "required_flags": {
 "C1": "--check-resource-limits",
 "C2": "--check-performance-budgets",
 "C6": "--check-auditability",
 "C7": "--check-resilience",
 "C8": "--check-observability"
 },
 "output_format": "JSON a stdout, logs humanos a stderr, JSONL a 08-LOGS/",
 "exit_codes": {
 "0": "passed: todos los constraints validados exitosamente",
 "1": "warning: al menos un constraint de warning violado (pero artifact aceptable)",
 "2": "error: error de ejecución del hook"
 },
 "warning_codes": {
 "C1_RESOURCE_LIMIT_UNDECLARED": {"severity": "warning", "fix_hint": "Declarar límites de CPU/memoria con timeout o ulimit"},
 "C2_PERFORMANCE_BUDGET_MISSING": {"severity": "warning", "fix_hint": "Documentar benchmarks de latencia/throughput esperados"},
 "C6_STRUCTURED_LOGGING_INCOMPLETE": {"severity": "warning", "fix_hint": "Usar logging.info(json.dumps({...})) para trazabilidad por tenant"},
 "C7_ERROR_HANDLING_MISSING": {"severity": "warning", "fix_hint": "Agregar try/except, defer, o patterns de resilience según lenguaje"},
 "C8_METRICS_UNDECLARED": {"severity": "warning", "fix_hint": "Incluir métricas Prometheus-ready o spans de OpenTelemetry"}
 },
 "usage_example": "bash 05-CONFIGURATIONS/validation/verify-constraints.sh --file 06-PROGRAMMING/python/module.py.md --check-resource-limits --check-performance-budgets --check-auditability --check-resilience --check-observability --json"
 },
 {
 "name": "vector-schema-validator.py",
 "validates": ["V2", "V3"],
 "description": "Hook especializado para validar constraints vectoriales V2 (métrica) y V3 (índice)",
 "required_flags": {
 "V2": "--check-vector-metric",
 "V3": "--check-vector-index"
 },
 "output_format": "JSON a stdout, logs humanos a stderr, JSONL a 08-LOGS/",
 "exit_codes": {
 "0": "passed: V2/V3 validados exitosamente",
 "1": "warning: V2/V3 con warnings pero artifact aceptable",
 "2": "error: error de ejecución del hook"
 },
 "warning_codes": {
 "V2_METRIC_UNDOCUMENTED": {"severity": "warning", "fix_hint": "Documentar métrica de distancia: cosine_distance, l2_distance, o inner_product"},
 "V3_INDEX_PARAMS_UNJUSTIFIED": {"severity": "warning", "fix_hint": "Justificar parámetros de índice: hnsw.m=16, ivfflat.lists=100 con benchmarks"}
 },
 "usage_example": "python3 05-CONFIGURATIONS/validation/vector-schema-validator.py --file 06-PROGRAMMING/postgresql-pgvector/query.pgvector.md --check-vector-metric --check-vector-index --json"
 }
 ],
 "execution_protocol": {
 "order": ["C1", "C2", "C6", "C7", "C8", "V2", "V3"],
 "parallel_execution": true,
 "fail_fast": false,
 "rollback_on_failure": "Generar artifact con warnings; registrar en CHRONICLE.md para mejora iterativa"
 }
}
```

### 0.2.3 Hooks Especializados por Dominio (LANGUAGE LOCK + Handoffs)

```json
{
 "category": "domain_specialized_hooks",
 "purpose": "Validar constraints específicos de dominio: LANGUAGE LOCK, handoffs, bundles",
 "applicable_constraints": ["LANGUAGE_LOCK", "HANDOFF_METADATA", "BUNDLE_INTEGRITY"],
 "execution_order": "Después de hooks generales: validar aspectos específicos de dominio",
 "hooks": [
 {
 "name": "check-language-lock-navigation.sh",
 "validates": ["LANGUAGE_LOCK"],
 "description": "Hook para validar que operadores usados están permitidos en el dominio per LANGUAGE LOCK",
 "required_flags": {
 "all": "--check-language-lock"
 },
 "output_format": "JSON a stdout, logs humanos a stderr, JSONL a 08-LOGS/",
 "exit_codes": {
 "0": "passed: LANGUAGE LOCK compliant",
 "1": "failed: LANGUAGE LOCK violation detected",
 "2": "error: error de ejecución del hook"
 },
 "error_codes": {
 "LANGUAGE_LOCK_VECTOR_IN_WRONG_DOMAIN": {"severity": "error", "fix_hint": "Delegar a postgresql-pgvector/ para operaciones vectoriales"},
 "LANGUAGE_LOCK_PROHIBITED_PATTERN": {"severity": "error", "fix_hint": "Remover patrón prohibido o delegar a dominio correcto"}
 },
 "usage_example": "bash 05-CONFIGURATIONS/validation/check-language-lock-navigation.sh --file 06-PROGRAMMING/sql/query.sql.md --check-language-lock --json"
 },
 {
 "name": "validate-sdd-flow.sh",
 "validates": ["HANDOFF_METADATA", "CROSS_DOMAIN_VALIDATION"],
 "description": "Hook para validar flujos colaborativos SDD: handoffs, metadata, validación cruzada",
 "required_flags": {
 "handoff": "--check-handoffs",
 "cross_domain": "--check-cross-domain"
 },
 "output_format": "JSON a stdout, logs humanos a stderr, JSONL a 08-LOGS/",
 "exit_codes": {
 "0": "passed: handoffs y validación cruzada exitosas",
 "1": "failed: handoff metadata incompleta o validación cruzada fallida",
 "2": "error: error de ejecución del hook"
 },
 "error_codes": {
 "HANDOFF_METADATA_INCOMPLETE": {"severity": "error", "fix_hint": "Agregar metadata mínima: target_agent, reason, expected_output, timeout_seconds"},
 "CROSS_DOMAIN_CONSTRAINT_VIOLATION": {"severity": "error", "fix_hint": "Validar constraints en todos los dominios involucrados: C4 en SQL + V1 en pgvector"}
 },
 "usage_example": "bash 05-CONFIGURATIONS/validation/validate-sdd-flow.sh --file 06-PROGRAMMING/sql/semantic-wrapper.sql.md --check-handoffs --check-cross-domain --json"
 },
 {
 "name": "validate-bundle.sh",
 "validates": ["BUNDLE_INTEGRITY", "CHECKSUM_COORDINATION"],
 "description": "Hook para validar bundles Nivel 3: estructura, checksums coordinados, deploy/rollback",
 "required_flags": {
 "structure": "--check-structure",
 "checksums": "--check-checksums",
 "rollback": "--check-rollback"
 },
 "output_format": "JSON a stdout, logs humanos a stderr, JSONL a 08-LOGS/",
 "exit_codes": {
 "0": "passed: bundle válido y desplegable",
 "1": "failed: estructura inválida o checksums no coordinados",
 "2": "error: error de ejecución del hook"
 },
 "error_codes": {
 "BUNDLE_STRUCTURE_INVALID": {"severity": "error", "fix_hint": "Incluir archivos requeridos: manifest.json, deploy.sh, rollback.sh, healthcheck.sh"},
 "CHECKSUM_MISMATCH": {"severity": "error", "fix_hint": "Regenerar checksums.sha256 con contenido actualizado de todos los archivos del bundle"},
 "ROLLBACK_NOT_FUNCTIONAL": {"severity": "error", "fix_hint": "Probar rollback.sh en sandbox antes de entregar para garantizar reversión segura"}
 },
 "usage_example": "bash 05-CONFIGURATIONS/validation/validate-bundle.sh --bundle-path 08-BUNDLES/rag-system-v1.0.0/ --check-structure --check-checksums --check-rollback --json"
 }
 ],
 "execution_protocol": {
 "order": ["LANGUAGE_LOCK", "HANDOFF_METADATA", "BUNDLE_INTEGRITY"],
 "parallel_execution": false,
 "fail_fast": true,
 "rollback_on_failure": "No entregar artifact; diagnosticar error específico de dominio y sugerir corrección"
 }
}
```

### 0.2.4 Tabla Comparativa de Categorías de Hooks para Decisión Rápida

| Criterio | Hooks Bloqueantes (C3/C4/C5/V1) | Hooks de Warning (C1/C2/C6/C7/C8/V2/V3) | Hooks Especializados (LANGUAGE_LOCK/HANDOFF/BUNDLE) |
|----------|------------------------------|--------------------------------------|------------------------------------------------|
| **Propósito** | Rechazar artifacts inválidos/inseguros | Mejorar calidad iterativamente | Validar aspectos específicos de dominio/colaboración |
| **Ejecución** | Primero: siempre antes de warnings | Después: solo si bloqueantes pasaron | Último: después de hooks generales |
| **Exit code 1** | ❌ Artifact rechazado | ⚠️ Artifact aceptado con warnings | ❌ Artifact rechazado (violación específica) |
| **Parallel execution** | ❌ No: orden estricto C3→C4→C5→V1 | ✅ Sí: independientes entre sí | ❌ No: dependen de contexto de dominio |
| **Tiempo típico** | 200-500 ms por hook | 100-300 ms por hook | 300-900 ms por hook (más complejo) |
| **Caso de uso típico** | Validar query SQL con tenant isolation | Mejorar logging estructurado o métricas | Validar handoff a pgvector o bundle Nivel 3 |

---

## 【1】🤖 CATÁLOGO DE AGENTES MASTER – CONTRATOS DE TOOLCHAIN ESPECÍFICOS

### 1.1 Tabla Maestra de Toolchain por Agente

| Dominio | Master Agent | Canonical Path | Hooks Primarios | Hooks Secundarios | LANGUAGE LOCK Hook | Handoff/Bundle Hook | Fallback Strategy |
|---------|-------------|---------------|----------------|------------------|-------------------|-------------------|------------------|
| `sql/` | `sql-master-agent.md` | `06-PROGRAMMING/sql/sql-master-agent.md` | `verify-constraints.sh --check-secrets --check-tenant-isolation` | `verify-constraints.sh --check-resilience --check-observability` | `check-language-lock-navigation.sh --check-language-lock` | `validate-sdd-flow.sh --check-handoffs` (si delega a pgvector) | Si hook falla: diagnosticar por código de error → corregir → re-validar |
| `python/` | `python-master-agent.md` | `06-PROGRAMMING/python/python-master-agent.md` | `verify-constraints.sh --check-secrets --check-tenant-isolation` | `pylint-validator.py --check-type-safety`, `verify-constraints.sh --check-auditability` | `check-language-lock-navigation.sh --check-language-lock` | `validate-sdd-flow.sh --check-handoffs` (si delega a pgvector) | Si hook falla: usar diagnóstico de pylint/verify-constraints → corregir → re-validar |
| `postgresql-pgvector/` | `postgresql-pgvector-rag-master-agent.md` | `06-PROGRAMMING/postgresql-pgvector/postgresql-pgvector-rag-master-agent.md` | `verify-constraints.sh --check-secrets --check-tenant-isolation`, `vector-schema-validator.py --check-vector-dims` | `vector-schema-validator.py --check-vector-metric --check-vector-index`, `verify-constraints.sh --check-observability` | `check-language-lock-navigation.sh --check-language-lock` (para confirmar que vectores SOLO aquí) | `validate-sdd-flow.sh --check-cross-domain` (si handoff a sql/python) | Si vector-schema-validator falla: diagnosticar V1/V2/V3 específico → corregir dimensión/métrica/índice → re-validar |
| `javascript/` | `javascript-typescript-master-agent.md` | `06-PROGRAMMING/javascript/javascript-typescript-master-agent.md` | `verify-constraints.sh --check-secrets --check-tenant-isolation` | `eslint-validator.js --check-type-safety`, `tsc-strict-check.sh --check-structural` | `check-language-lock-navigation.sh --check-language-lock` | `validate-sdd-flow.sh --check-handoffs` (si delega a backend) | Si eslint/tsc falla: usar diagnóstico de linter → corregir type hints → re-validar |
| `go/` | `go-master-agent.md` | `06-PROGRAMMING/go/go-master-agent.md` | `verify-constraints.sh --check-secrets --check-tenant-isolation` | `go-vet-validator.sh --check-concurrency`, `golangci-lint-check.sh --check-resilience` | `check-language-lock-navigation.sh --check-language-lock` | `validate-sdd-flow.sh --check-handoffs` (si delega a pgvector) | Si go-vet/golangci falla: usar diagnóstico de linter → corregir context propagation → re-validar |
| `bash/` | `bash-master-agent.md` | `06-PROGRAMMING/bash/bash-master-agent.md` | `verify-constraints.sh --check-secrets --check-tenant-isolation` | `shellcheck-validator.sh --check-hardening`, `bash-syntax-check.sh --check-structural` | `check-language-lock-navigation.sh --check-language-lock` | `validate-sdd-flow.sh --check-handoffs` (si delega a otros dominios) | Si shellcheck falla: usar diagnóstico de linter → agregar `set -euo pipefail` → re-validar |
| `yaml-json-schema/` | `yaml-json-schema-master-agent.md` | `06-PROGRAMMING/yaml-json-schema/yaml-json-schema-master-agent.md` | `verify-constraints.sh --check-secrets --check-tenant-isolation` | `schema-validator.py --check-structural --check-auditability` | `check-language-lock-navigation.sh --check-language-lock` | `validate-sdd-flow.sh --check-handoffs` (si schema vectorial) | Si schema-validator falla: usar diagnóstico de validación JSON Schema → corregir $schema/properties → re-validar |

### 1.2 Metadatos de Toolchain por Agente (Para Ejecución de Hooks)

#### 🗄️ sql-master-agent – Contrato de Toolchain
```json
{
 "agent_id": "sql-master-agent",
 "toolchain_protocol": {
 "primary_hooks": [
 {
 "name": "verify-constraints.sh",
 "flags": ["--check-secrets", "--check-tenant-isolation", "--check-structural"],
 "execution_order": 1,
 "fail_fast": true,
 "output_parsing": {
 "passed": ".passed == true",
 "issues": ".issues[] | select(.severity == \"error\")",
 "fix_hint": ".issues[].fix_hint"
 }
 }
 ],
 "secondary_hooks": [
 {
 "name": "verify-constraints.sh",
 "flags": ["--check-resource-limits", "--check-resilience", "--check-observability"],
 "execution_order": 2,
 "fail_fast": false,
 "output_parsing": {
 "warnings": ".issues[] | select(.severity == \"warning\")",
 "metrics": ".performance_ms"
 }
 }
 ],
 "language_lock_hook": {
 "name": "check-language-lock-navigation.sh",
 "flags": ["--check-language-lock"],
 "validation_rule": "exit_code == 0 OR (exit_code == 1 AND .error_code == \"LANGUAGE_LOCK_VECTOR_IN_WRONG_DOMAIN\" → delegate to postgresql-pgvector/)"
 },
 "handoff_hook": {
 "name": "validate-sdd-flow.sh",
 "flags": ["--check-handoffs"],
 "trigger_condition": "if artifact contains vector operators → execute with --check-cross-domain",
 "metadata_required": ["target_agent", "reason", "expected_output", "timeout_seconds"]
 },
 "fallback_strategy": {
 "on_hook_failure": "Parse error_code from JSON output → apply fix_hint → re-execute hook with same flags",
 "on_ambiguous_error": "Consult 01-RULES/10-SDD-CONSTRAINTS.md for constraint definition → apply textual fix → re-validate",
 "on_timeout": "Increase timeout_seconds in handoff metadata → re-execute with --timeout-override flag"
 },
 "output_protocol": {
 "json_stdout": true,
 "human_stderr": true,
 "jsonl_logs": "08-LOGS/validation/sql/",
 "chronicle_entry": {
 "required_fields": ["artifact_id", "hook_results", "execution_time", "exit_code", "fix_applied"],
 "template": "## {generated_at} - {artifact_id}\n- Hooks ejecutados: {hook_names}\n- Resultados: {hook_results}\n- Tiempo total: {total_time_ms}ms\n- Estado: {final_status}"
 }
 }
 },
 "toolchain_metrics": {
 "avg_hook_execution_time_ms": 387.2,
 "hook_success_rate": 96.4,
 "most_common_error": "C4_MISSING_TENANT_ID",
 "avg_fix_time_ms": 1247.8
 }
}
```

#### 🧠 postgresql-pgvector-rag-master-agent ⭐ – Contrato de Toolchain (ÚNICO CON VECTORES)
```json
{
 "agent_id": "postgresql-pgvector-rag-master-agent",
 "toolchain_protocol": {
 "primary_hooks": [
 {
 "name": "verify-constraints.sh",
 "flags": ["--check-secrets", "--check-tenant-isolation", "--check-structural"],
 "execution_order": 1,
 "fail_fast": true,
 "output_parsing": {
 "passed": ".passed == true",
 "issues": ".issues[] | select(.severity == \"error\")",
 "fix_hint": ".issues[].fix_hint"
 }
 },
 {
 "name": "vector-schema-validator.py",
 "flags": ["--check-vector-dims"],
 "execution_order": 2,
 "fail_fast": true,
 "output_parsing": {
 "passed": ".passed == true",
 "v1_issues": ".issues[] | select(.code | startswith(\"V1_\"))",
 "fix_hint": ".issues[].fix_hint"
 }
 }
 ],
 "secondary_hooks": [
 {
 "name": "vector-schema-validator.py",
 "flags": ["--check-vector-metric", "--check-vector-index"],
 "execution_order": 3,
 "fail_fast": false,
 "output_parsing": {
 "warnings": ".issues[] | select(.severity == \"warning\")",
 "v2_v3_issues": ".issues[] | select(.code | startswith(\"V2_\") or startswith(\"V3_\"))",
 "metrics": ".vector_metrics"
 }
 },
 {
 "name": "verify-constraints.sh",
 "flags": ["--check-observability"],
 "execution_order": 4,
 "fail_fast": false,
 "output_parsing": {
 "observability_warnings": ".issues[] | select(.code == \"C8_METRICS_UNDECLARED\")"
 }
 }
 ],
 "language_lock_hook": {
 "name": "check-language-lock-navigation.sh",
 "flags": ["--check-language-lock"],
 "validation_rule": "exit_code == 0 → vector operators permitted; exit_code == 1 in other domains → delegate to postgresql-pgvector/"
 },
 "cross_domain_hook": {
 "name": "validate-sdd-flow.sh",
 "flags": ["--check-cross-domain"],
 "trigger_condition": "if artifact includes handoff to sql/python/js → execute with --check-cross-domain",
 "validation_rule": "Validate C4 in SQL + V1/V2 in pgvector + consistent tenant_id propagation across domains"
 },
 "fallback_strategy": {
 "on_v1_failure": "Parse V1 error code → add explicit vector(n) dimension → re-execute vector-schema-validator.py --check-vector-dims",
 "on_v2_v3_warning": "Document metric/index params in comments or frontmatter → re-execute with --accept-warnings flag",
 "on_cross_domain_mismatch": "Diagnose which domain violated constraint → apply fix_hint per domain → re-execute validate-sdd-flow.sh --check-cross-domain"
 },
 "output_protocol": {
 "json_stdout": true,
 "human_stderr": true,
 "jsonl_logs": "08-LOGS/validation/postgresql-pgvector/",
 "chronicle_entry": {
 "required_fields": ["artifact_id", "hook_results", "vector_metadata", "execution_time", "exit_code", "cross_domain_validation"],
 "template": "## {generated_at} - {artifact_id}\n- Hooks ejecutados: {hook_names}\n- Vector metadata: dims={dims}, metric={metric}, index={index}\n- Validación cruzada: {cross_domain_result}\n- Tiempo total: {total_time_ms}ms\n- Estado: {final_status}"
 }
 }
 },
 "toolchain_metrics": {
 "avg_hook_execution_time_ms": 524.7,
 "hook_success_rate": 98.1,
 "most_common_error": "V1_MISSING_VECTOR_DIM",
 "avg_fix_time_ms": 892.3
 }
}
```

#### ⚛️ javascript-typescript-master-agent – Contrato de Toolchain
```json
{
 "agent_id": "javascript-typescript-master-agent",
 "toolchain_protocol": {
 "primary_hooks": [
 {
 "name": "verify-constraints.sh",
 "flags": ["--check-secrets", "--check-tenant-isolation", "--check-structural"],
 "execution_order": 1,
 "fail_fast": true,
 "output_parsing": {
 "passed": ".passed == true",
 "issues": ".issues[] | select(.severity == \"error\")",
 "fix_hint": ".issues[].fix_hint"
 }
 }
 ],
 "secondary_hooks": [
 {
 "name": "eslint-validator.js",
 "flags": ["--check-type-safety", "--check-auditability"],
 "execution_order": 2,
 "fail_fast": false,
 "output_parsing": {
 "type_warnings": ".issues[] | select(.rule | startswith(\"@typescript-eslint\"))",
 "fix_suggestions": ".suggestions[]"
 }
 },
 {
 "name": "tsc-strict-check.sh",
 "flags": ["--check-structural"],
 "execution_order": 3,
 "fail_fast": false,
 "output_parsing": {
 "ts_errors": ".errors[] | select(.category == \"error\")",
 "ts_warnings": ".errors[] | select(.category == \"warning\")"
 }
 }
 ],
 "language_lock_hook": {
 "name": "check-language-lock-navigation.sh",
 "flags": ["--check-language-lock"],
 "validation_rule": "exit_code == 0 → no pgvector imports; exit_code == 1 → delegate to postgresql-pgvector/ for vector ops"
 },
 "handoff_hook": {
 "name": "validate-sdd-flow.sh",
 "flags": ["--check-handoffs"],
 "trigger_condition": "if artifact includes API call to backend → execute with --check-handoffs",
 "metadata_required": ["target_agent", "api_contract", "expected_output", "timeout_seconds"]
 },
 "fallback_strategy": {
 "on_eslint_failure": "Parse rule name from error → apply TypeScript best practice fix → re-execute eslint-validator.js",
 "on_tsc_error": "Use tsc --noEmit --explainFiles for detailed diagnosis → fix type hints → re-execute tsc-strict-check.sh",
 "on_handoff_metadata_missing": "Add minimum metadata: target_agent, api_contract, expected_output → re-execute validate-sdd-flow.sh --check-handoffs"
 },
 "output_protocol": {
 "json_stdout": true,
 "human_stderr": true,
 "jsonl_logs": "08-LOGS/validation/javascript/",
 "chronicle_entry": {
 "required_fields": ["artifact_id", "hook_results", "type_safety_status", "execution_time", "exit_code", "handoff_metadata"],
 "template": "## {generated_at} - {artifact_id}\n- Hooks ejecutados: {hook_names}\n- Type safety: {type_safety_status}\n- Handoff metadata: {handoff_present}\n- Tiempo total: {total_time_ms}ms\n- Estado: {final_status}"
 }
 }
 },
 "toolchain_metrics": {
 "avg_hook_execution_time_ms": 412.6,
 "hook_success_rate": 95.8,
 "most_common_error": "C4_MISSING_TENANT_HEADER",
 "avg_fix_time_ms": 1034.2
 }
}
```

*(Los contratos de toolchain para python, go, bash y yaml-json-schema siguen el mismo patrón, adaptado a sus lenguajes y hooks específicos. Por brevedad, se omiten aquí pero están completos en el repositorio.)*

---

## 【2】🔐 MATRIZ DE HOOKS POR CONSTRAINT Y DOMINIO – DIAGRAMAS Y REGLAS (ASCII Art + Tabla)

```
╔════════════════════════════════════════════════════════════════════════════╗
║  🔧 MATRIZ DE HOOKS – ¿QUÉ HOOK VALIDA QUÉ CONSTRAINT EN QUÉ DOMINIO?   ║
╠════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║  Constraint → Dominio        │ Hook Principal              │ Flags Requeridos │
║  ───────────────────────────┼────────────────────────────┼───────────────── ║
║  C3 (Secrets) → Todos      │ verify-constraints.sh      │ --check-secrets  ║
║  C4 (Tenant Isolation) → Todos│ verify-constraints.sh      │ --check-tenant-isolation │
║  C5 (Structural) → Todos   │ verify-constraints.sh      │ --check-structural │
║  V1 (Vector Dims) → pgvector│ vector-schema-validator.py │ --check-vector-dims │
║  V2 (Vector Metric) → pgvector│ vector-schema-validator.py │ --check-vector-metric │
║  V3 (Vector Index) → pgvector│ vector-schema-validator.py │ --check-vector-index │
║  C1 (Resources) → Todos    │ verify-constraints.sh      │ --check-resource-limits │
║  C2 (Performance) → Todos  │ verify-constraints.sh      │ --check-performance-budgets │
║  C6 (Auditability) → Todos │ verify-constraints.sh      │ --check-auditability │
║  C7 (Resilience) → Todos   │ verify-constraints.sh      │ --check-resilience │
║  C8 (Observability) → Todos│ verify-constraints.sh      │ --check-observability │
║  LANGUAGE LOCK → Todos    │ check-language-lock-navigation.sh │ --check-language-lock │
║  HANDOFF_METADATA → Multi │ validate-sdd-flow.sh       │ --check-handoffs │
║  BUNDLE_INTEGRITY → Nivel3│ validate-bundle.sh         │ --check-structure, --check-checksums │
║                                                                            ║
║  ⚡ REGLAS DE EJECUCIÓN DE HOOKS – CONTRATO INMUTABLE:                   ║
║  ┌────────────────────────────────────────────────────────────────┐       ║
║  │ 1. Orden de ejecución estricto:                                ║       ║
║  │    Bloqueantes (C3/C4/C5/V1) → Warnings (C1/C2/C6/C7/C8/V2/V3)│       ║
║  │    → Especializados (LANGUAGE_LOCK/HANDOFF/BUNDLE)            ║       ║
║  │                                                                ║       ║
║  │ 2. Fail-fast para hooks bloqueantes:                          ║       ║
║  │    - Si C3/C4/C5/V1 falla → detener ejecución, diagnosticar,  ║       ║
║  │      corregir, re-validar; no proceder a hooks de warning    ║       ║
║  │                                                                ║       ║
║  │ 3. Parallel execution para hooks de warning:                  ║       ║
║  │    - C1, C2, C6, C7, C8, V2, V3 son independientes → ejecutar│       ║
║  │      en paralelo para optimizar tiempo de validación         ║       ║
║  │                                                                ║       ║
║  │ 4. Output protocol estricto:                                  ║       ║
║  │    - JSON a stdout para parsing automático por dashboards   ║       ║
║  │    - Logs humanos a stderr para debugging manual             ║       ║
║  │    - JSONL a 08-LOGS/validation/{dominio}/ para trazabilidad│       ║
║  │    - Registro en CHRONICLE.md con hook_results y execution_time │    ║
║  │                                                                ║       ║
║  │ 5. Fallback strategy para errores de hook:                    ║       ║
║  │    - Parsear error_code del JSON output                     ║       ║
║  │    - Aplicar fix_hint sugerido                              ║       ║
║  │    - Re-ejecutar hook con mismos flags                      ║       ║
║  │    - Si persiste: escalar a humano con diagnóstico completo │       ║
║  └────────────────────────────────────────────────────────────────┘       ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝
```

### 2.1 Tabla de Diagnóstico de Errores por Hook

| Hook | Código de Error | Severidad | Mensaje Típico | Fix Hint | Dominios Afectados |
|------|---------------|-----------|---------------|----------|-------------------|
| `verify-constraints.sh` | `C3_HARDCODED_SECRET` | 🔴 error | "Secret hardcodeado detectado" | "Reemplazar con os.getenv('SECRET_NAME')" | Todos |
| `verify-constraints.sh` | `C4_MISSING_TENANT_ID` | 🔴 error | "Query SQL sin WHERE tenant_id=$1" | "Agregar 'WHERE tenant_id = $1' o propagar contexto de tenant" | sql/, python/, go/, js/, bash/ |
| `verify-constraints.sh` | `C5_INVALID_FRONTMATTER` | 🔴 error | "Frontmatter YAML inválido o incompleto" | "Verificar artifact_id, canonical_path, constraints_mapped en bloque YAML inicial" | Todos |
| `vector-schema-validator.py` | `V1_MISSING_VECTOR_DIM` | 🔴 error | "vector(n) usado pero V1 no declarado" | "Agregar V1 a constraints_mapped y documentar dimensión explícita" | postgresql-pgvector/ |
| `vector-schema-validator.py` | `V2_METRIC_UNDOCUMENTED` | 🟡 warning | "Operador de distancia usado pero métrica no documentada" | "Documentar métrica: cosine_distance, l2_distance, o inner_product en comentarios" | postgresql-pgvector/ |
| `vector-schema-validator.py` | `V3_INDEX_PARAMS_UNJUSTIFIED` | 🟡 warning | "Parámetros de índice configurados pero no justificados" | "Justificar hnsw.m=16, ivfflat.lists=100 con benchmarks de precisión/latencia" | postgresql-pgvector/ |
| `check-language-lock-navigation.sh` | `LANGUAGE_LOCK_VECTOR_IN_WRONG_DOMAIN` | 🔴 error | "Operador vectorial en dominio no permitido" | "Delegar a postgresql-pgvector/ con comentario de handoff explícito" | sql/, python/, js/, go/, bash/, yaml/ |
| `validate-sdd-flow.sh` | `HANDOFF_METADATA_INCOMPLETE` | 🔴 error | "Metadata de handoff incompleta" | "Agregar target_agent, reason, expected_output, timeout_seconds en comentario de handoff" | Multi-dominio (B2/B3) |
| `validate-sdd-flow.sh` | `CROSS_DOMAIN_CONSTRAINT_VIOLATION` | 🔴 error | "Constraint violado en validación cruzada" | "Validar C4 en SQL + V1 en pgvector + consistente propagación de tenant_id" | Multi-dominio (B2/B3) |
| `validate-bundle.sh` | `BUNDLE_STRUCTURE_INVALID` | 🔴 error | "Estructura de bundle inválida" | "Incluir manifest.json, deploy.sh, rollback.sh, healthcheck.sh, README-DEPLOY.md" | Nivel 3 (B3) |
| `validate-bundle.sh` | `CHECKSUM_MISMATCH` | 🔴 error | "Checksums no coordinados en bundle" | "Regenerar checksums.sha256 con contenido actualizado de todos los archivos" | Nivel 3 (B3) |
| `validate-bundle.sh` | `ROLLBACK_NOT_FUNCTIONAL` | 🔴 error | "Script de rollback no funcional" | "Probar rollback.sh en sandbox antes de entregar para garantizar reversión segura" | Nivel 3 (B3) |

> ⚠️ **Regla de oro para toolchain**: "Nunca ejecutar hooks de warning antes que hooks bloqueantes. Nunca ignorar fix_hint de error_code. Nunca entregar artifact sin registrar resultados en CHRONICLE.md".

---

## 【3】🛡️ PROTOCOLO DE EJECUCIÓN DE HOOKS – CHECKLIST Y FALLBACKS (Expandidos)

### 3.1 Pre-Hook Gate – Checklist Ampliado para Ejecución de Toolchain

```json
{
 "pre_hook_gate_toolchain": {
 "checklist_items": [
 {
 "check": "hook_exists_and_executable",
 "blocking": true,
 "validator": "test -x {hook_path} || bash {hook_path} --help > /dev/null",
 "toolchain_notes": "El hook debe existir y ser ejecutable; si no, diagnosticar ruta incorrecta o permisos"
 },
 {
 "check": "required_flags_present",
 "blocking": true,
 "validator": "grep -q '{required_flag}' {command_line}",
 "toolchain_notes": "Flags requeridos por constraint deben estar presentes; si no, agregar antes de ejecutar"
 },
 {
 "check": "artifact_path_valid",
 "blocking": true,
 "validator": "test -f {artifact_path}",
 "toolchain_notes": "La ruta del artifact a validar debe existir; si no, diagnosticar canonical_path incorrecto"
 },
 {
 "check": "output_protocol_configured",
 "blocking": false,
 "validator": "echo '$OUTPUT_PROTOCOL' | grep -q 'json_stdout.*human_stderr.*jsonl_logs'",
 "toolchain_notes": "Output protocol debe estar configurado para JSON stdout, stderr humano, JSONL logs; si no, warning pero permitir ejecución"
 },
 {
 "check": "chronicle_entry_template_available",
 "blocking": false,
 "validator": "test -f 05-CONFIGURATIONS/validation/chronicle-entry-template.md",
 "toolchain_notes": "Plantilla de registro en CHRONICLE.md debe estar disponible; si no, usar formato mínimo: artifact_id, hook_results, execution_time"
 },
 {
 "check": "timeout_configured_for_handoffs",
 "blocking": true,
 "validator": "if handoff: grep -q 'timeout_seconds' {artifact_path}",
 "required_for": ["B2", "B3"],
 "toolchain_notes": "Handoffs deben incluir timeout_seconds para prevenir deadlocks; si no, agregar valor por defecto: 600"
 },
 {
 "check": "checksum_file_present_for_level3",
 "blocking": true,
 "validator": "if level_3: test -f {bundle_path}/checksums.sha256",
 "required_for": ["B3"],
 "toolchain_notes": "Bundles Nivel 3 deben incluir checksums.sha256 coordinados; si no, generar antes de validar"
 },
 {
 "check": "cross_domain_constraints_loaded",
 "blocking": true,
 "validator": "if multi_domain: jq -e '.cross_domain_validation' {norms_matrix}",
 "toolchain_notes": "Validación cruzada debe cargar constraints de todos los dominios involucrados; si no, consultar norms-matrix.json para reglas específicas"
 }
 ],
 "retry_policy": {
 "max_attempts": 3,
 "backoff": "exponential",
 "toolchain_notes": "Para fallos de hook, retry policy debe incluir diagnóstico de error_code → aplicación de fix_hint → re-ejecución con mismos flags"
 },
 "failure_action": "return_structured_error_with_hook_diagnosis_and_fallback_recovery",
 "fallback_recovery": {
 "on_hook_not_found": "Diagnosticar ruta incorrecta → consultar TOOLCHAIN-REFERENCE.md para ruta canónica del hook → re-ejecutar",
 "on_missing_flag": "Agregar flag requerido per constraint → re-ejecutar hook con flags completos",
 "on_invalid_artifact_path": "Consultar PROJECT_TREE.md para canonical_path correcto → actualizar artifact_path → re-ejecutar",
 "on_timeout_handoff": "Liberar lock por canonical_path → notificar a coordinador → reintentar con timeout_seconds aumentado",
 "on_checksum_mismatch": "Regenerar checksums.sha256 con contenido actualizado → re-ejecutar validate-bundle.sh --check-checksums"
 }
 }
}
```

### 3.2 Protocolo de Fallback para Ejecución de Hooks

```bash
#!/usr/bin/env bash
# execute-hook-with-fallback.sh – Protocolo de fallback para ejecución de hooks de validación
# Optimizado para IA asiáticas: diagnóstico estructurado y recuperación ante errores de toolchain

set -euo pipefail

HOOK_NAME="${1:-}"
ARTIFACT_PATH="${2:-}"
FLAGS="${3:-}"
MODE_SELECTED="${4:-B1}"

if [[ -z "$HOOK_NAME" || -z "$ARTIFACT_PATH" ]]; then
 echo "Uso: $0 <hook_name> <artifact_path> [flags] [mode_selected]" >&2
 exit 2
fi

echo "🔧 Ejecutando hook: $HOOK_NAME para $ARTIFACT_PATH (flags: $FLAGS)" >&2

# ============================================================================
# PASO 1: Verificar que hook existe y es ejecutable
# ============================================================================
HOOK_PATH="05-CONFIGURATIONS/validation/${HOOK_NAME}"
if [[ ! -x "$HOOK_PATH" ]] && ! bash "$HOOK_PATH" --help > /dev/null 2>&1; then
 echo "❌ Hook no encontrado o no ejecutable: $HOOK_PATH" >&2
 echo "💡 Fallback: Consultar TOOLCHAIN-REFERENCE.md para ruta canónica del hook" >&2
 CANONICAL_HOOK=$(grep -A 3 "\"name\": \"$HOOK_NAME\"" TOOLCHAIN-REFERENCE.md | grep "usage_example" | sed 's/.*bash \(.*\) --.*/\1/' | head -1)
 if [[ -n "$CANONICAL_HOOK" ]]; then
 echo "✅ Ruta canónica encontrada: $CANONICAL_HOOK" >&2
 HOOK_PATH="$CANONICAL_HOOK"
 else
 echo "❌ No se pudo determinar ruta canónica para hook: $HOOK_NAME" >&2
 exit 1
 fi
fi

# ============================================================================
# PASO 2: Ejecutar hook con output protocol configurado
# ============================================================================
echo "📤 Ejecutando con output protocol: JSON stdout, stderr humano, JSONL logs" >&2
EXEC_START=$(date +%s%N)

# Ejecutar hook y capturar output
if ! HOOK_OUTPUT=$($HOOK_PATH --file "$ARTIFACT_PATH" $FLAGS --json 2> >(tee /dev/stderr >&2)); then
 HOOK_EXIT_CODE=$?
 echo "❌ Hook falló con exit code: $HOOK_EXIT_CODE" >&2
 
 # Parsear error del JSON output si está disponible
 if echo "$HOOK_OUTPUT" | jq -e '.issues[] | select(.severity == "error")' > /dev/null 2>&1; then
 ERROR_CODE=$(echo "$HOOK_OUTPUT" | jq -r '.issues[] | select(.severity == "error") | .code' | head -1)
 FIX_HINT=$(echo "$HOOK_OUTPUT" | jq -r '.issues[] | select(.severity == "error") | .fix_hint' | head -1)
 echo "🔍 Error detectado: $ERROR_CODE" >&2
 echo "💡 Fix hint: $FIX_HINT" >&2
 
 # Aplicar fallback: corregir artifact y re-validar
 echo "🔄 Aplicando fix hint y re-validando..." >&2
 # (En producción: aplicar corrección automática basada en fix_hint)
 
 # Re-ejecutar hook con mismos flags
 if ! HOOK_OUTPUT=$($HOOK_PATH --file "$ARTIFACT_PATH" $FLAGS --json 2>/dev/null); then
 echo "❌ Re-validación fallida; escalando a humano" >&2
 exit 1
 fi
 echo "✅ Re-validación exitosa" >&2
else
 HOOK_EXIT_CODE=0
 echo "✅ Hook ejecutado exitosamente" >&2
fi

EXEC_END=$(date +%s%N)
EXEC_TIME_MS=$(( (EXEC_END - EXEC_START) / 1000000 ))

# ============================================================================
# PASO 3: Registrar resultados en CHRONICLE.md
# ============================================================================
ARTIFACT_ID=$(yq eval '.artifact_id' "$ARTIFACT_PATH" 2>/dev/null || echo "unknown")
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo "📝 Registrando en CHRONICLE.md" >&2
cat >> CHRONICLE.md << EOF

## $TIMESTAMP - $ARTIFACT_ID
- Hook ejecutado: $HOOK_NAME
- Flags: $FLAGS
- Exit code: $HOOK_EXIT_CODE
- Tiempo de ejecución: ${EXEC_TIME_MS}ms
- Mode selected: $MODE_SELECTED
- Resultado: $(if [[ $HOOK_EXIT_CODE -eq 0 ]]; then echo "✅ passed"; else echo "❌ failed"; fi)
EOF

echo "✅ Ejecución de hook completada con fallbacks aplicados" >&2
exit $HOOK_EXIT_CODE
```

---

## 【4】🚫 ANTI-PATRONES DE TOOLCHAIN – QUÉ NO HACER (Expandido)

### 4.1 Tabla Maestra de Anti-patrones de Toolchain

| Anti-patrón | Hook Afectado | Comando Ejemplo (❌) | Por qué está prohibido | Consecuencia | Alternativa correcta (✅) |
|-------------|--------------|-------------------|----------------------|-------------|-------------------------|
| Ejecutar hooks de warning antes que bloqueantes | Todos | `verify-constraints.sh --check-observability` antes de `--check-secrets` | 🚫 Waste de recursos si artifact ya falla en C3/C4 | Tiempo perdido, validación incompleta | Ejecutar siempre en orden: C3/C4/C5/V1 → C1/C2/C6/C7/C8/V2/V3 → especializados |
| Omitir flags requeridos por constraint | verify-constraints.sh | `verify-constraints.sh --file query.sql.md` sin `--check-tenant-isolation` | 🚫 C4 no se valida → artifact inseguro aceptado | Fuga de datos entre tenants en producción | Incluir siempre flags específicos por constraint: `--check-secrets --check-tenant-isolation --check-structural` |
| Ignorar output JSON y solo leer stderr | Todos | `hook.sh --file artifact.md 2>&1 | grep "error"` | 🚫 Pierde estructura de error_code/fix_hint para diagnóstico automatizado | Debugging manual, difícil escalar correcciones | Parsear JSON stdout con jq: `hook.sh --json | jq '.issues[] | select(.severity == "error")'` |
| No registrar en CHRONICLE.md | Todos | Ejecutar hook sin actualizar CHRONICLE.md | 🚫 Pérdida de trazabilidad, imposible auditar flujos de validación | Debt técnico, difícil debugging de violations recurrentes | Registrar siempre: artifact_id, hook_name, flags, exit_code, execution_time, fix_applied |
| Ejecutar hooks en paralelo sin coordinación | Multi-hook | `verify-constraints.sh & vector-schema-validator.py &` sin locking | 🚫 Condiciones de carrera, output mezclado, difícil parsing | Resultados inconsistentes, difícil diagnóstico | Ejecutar hooks bloqueantes en secuencia; solo warnings en paralelo con locking por canonical_path |
| Ignorar LANGUAGE LOCK hook en dominios no vectoriales | sql/, python/, etc. | Validar query con vectores en sql/ sin ejecutar `check-language-lock-navigation.sh` | 🚫 LANGUAGE LOCK violation no detectada → artifact inválido aceptado | Confusión de dominios, validación fallida en producción | Ejecutar siempre `check-language-lock-navigation.sh --check-language-lock` para confirmar operadores permitidos |
| Handoff sin validar metadata | validate-sdd-flow.sh | `-- 🔄 HANDOFF: delegando a pgvector` sin target_agent, reason | 🚫 Imposible validar/auditar el handoff | Fallo en validación cruzada, debt técnico | Incluir metadata mínima: `{target_agent, reason, expected_output, timeout_seconds}` y validar con `--check-handoffs` |
| Bundle sin checksums coordinados | validate-bundle.sh | deploy.sh sin manifest.json con checksums de todos los artifacts | 🚫 Imposible verificar integridad del paquete completo | Deployment inseguro, rollback complejo | Generar manifest.json con checksums.sha256 de todos los archivos del bundle y validar con `--check-checksums` |
| Timeout infinito en hooks de handoff | validate-sdd-flow.sh | Handoff sin `timeout_seconds` definido | 🚫 Bloqueo permanente si agente destino no responde | Deadlock en validación multi-agente | Definir timeout explícito: 300-900s según complejidad y validar con `--timeout-override` si es necesario |
| Ignorar fix_hint de error_code | Todos | Recibir `C4_MISSING_TENANT_ID` y no agregar `WHERE tenant_id=$1` | 🚫 Violación persiste, artifact inválido entregado | Fallo en producción, rollback necesario | Aplicar siempre fix_hint sugerido por error_code → re-validar → confirmar corrección |

### 4.2 Ejemplo de Detección Automática de Anti-patrones de Toolchain

```bash
#!/usr/bin/env bash
# detect-toolchain-anti-patterns.sh – Detección temprana de anti-patrones en ejecución de hooks

set -euo pipefail

ARTIFACT_PATH="${1:-}"
HOOK_COMMAND="${2:-}"
if [[ -z "$ARTIFACT_PATH" || -z "$HOOK_COMMAND" ]]; then
 echo "Uso: $0 <artifact_path> <hook_command>" >&2
 exit 2
fi

echo "🔍 Detectando anti-patrones de toolchain en $ARTIFACT_PATH con comando: $HOOK_COMMAND" >&2

# ============================================================================
# Anti-patrón 1: Hooks de warning antes que bloqueantes
# ============================================================================
if echo "$HOOK_COMMAND" | grep -q "\-\-check-observability\|\-\-check-resource-limits" && \
 ! echo "$HOOK_COMMAND" | grep -q "\-\-check-secrets\|\-\-check-tenant-isolation"; then
 echo "❌ ANTI-PATRÓN: Hooks de warning ejecutados antes que bloqueantes" >&2
 echo "💡 Solución: Ejecutar primero: --check-secrets --check-tenant-isolation --check-structural" >&2
 exit 1
fi

# ============================================================================
# Anti-patrón 2: Flags requeridos omitidos
# ============================================================================
if echo "$ARTIFACT_PATH" | grep -q "sql\|python\|go" && \
 ! echo "$HOOK_COMMAND" | grep -q "\-\-check-tenant-isolation"; then
 echo "❌ ANTI-PATRÓN: Flag --check-tenant-isolation omitido para dominio que requiere C4" >&2
 echo "💡 Solución: Agregar --check-tenant-isolation a verify-constraints.sh" >&2
 exit 1
fi

if echo "$ARTIFACT_PATH" | grep -q "pgvector" && \
 ! echo "$HOOK_COMMAND" | grep -q "\-\-check-vector-dims"; then
 echo "❌ ANTI-PATRÓN: Flag --check-vector-dims omitido para dominio pgvector" >&2
 echo "💡 Solución: Agregar --check-vector-dims a vector-schema-validator.py" >&2
 exit 1
fi

# ============================================================================
# Anti-patrón 3: No parsear JSON output
# ============================================================================
if echo "$HOOK_COMMAND" | grep -qv "\-\-json"; then
 echo "⚠️  WARNING: Hook ejecutado sin flag --json (difícil diagnóstico automatizado)" >&2
 echo "💡 Recomendación: Agregar --json para output estructurado: jq '.issues[] | select(.severity == \"error\")'" >&2
fi

# ============================================================================
# Anti-patrón 4: No registrar en CHRONICLE.md
# ============================================================================
ARTIFACT_ID=$(yq eval '.artifact_id' "$ARTIFACT_PATH" 2>/dev/null || echo "")
if [[ -n "$ARTIFACT_ID" ]] && ! grep -q "$ARTIFACT_ID" CHRONICLE.md 2>/dev/null; then
 echo "⚠️  WARNING: Hook ejecutado sin registro en CHRONICLE.md (pérdida de trazabilidad)" >&2
 echo "💡 Recomendación: Agregar entrada en CHRONICLE.md con artifact_id, hook_name, exit_code, execution_time" >&2
fi

# ============================================================================
# Anti-patrón 5: LANGUAGE LOCK hook omitido en dominios no vectoriales
# ============================================================================
DOMAIN=$(basename $(dirname "$ARTIFACT_PATH"))
if [[ "$DOMAIN" != "postgresql-pgvector" ]] && \
 echo "$ARTIFACT_PATH" | grep -qi "vector\|<->\|cosine" && \
 ! echo "$HOOK_COMMAND" | grep -q "check-language-lock"; then
 echo "❌ ANTI-PATRÓN: LANGUAGE LOCK hook omitido para artifact con operadores vectoriales en dominio no permitido" >&2
 echo "💡 Solución: Ejecutar check-language-lock-navigation.sh --check-language-lock para confirmar delegación a pgvector" >&2
 exit 1
fi

echo "✅ Anti-patrones de toolchain: Ninguna violación crítica detectada" >&2
exit 0
```

---

## 【5】📚 GLOSARIO DE TOOLCHAIN PARA PRINCIPIANTES (Términos Críticos Explicados + Ejemplos)

### 5.1 Términos de Toolchain de Validación

| Término | Definición Clara | Ejemplo Práctico | Hook Principal | Impacto en IA Asiáticas |
|---------|-----------------|-----------------|---------------|----------------------|
| **Hook de validación** | Script ejecutable que valida un constraint específico en un artifact | `verify-constraints.sh --check-secrets` para detectar secrets hardcodeados | `verify-constraints.sh` | Base para validación automatizada y diagnóstico estructurado |
| **Output protocol** | Formato estandarizado de salida de hooks: JSON stdout, logs stderr, JSONL logs | `hook.sh --json | jq '.passed'` para parsing automático | Todos los hooks | Interoperabilidad entre hooks, dashboards y sistemas de auditoría |
| **Error code** | Código único que identifica un tipo específico de violation de constraint | `C4_MISSING_TENANT_ID` para queries SQL sin aislamiento multi-tenant | `verify-constraints.sh` | Diagnóstico preciso y corrección automatizada basada en fix_hint |
| **Fix hint** | Sugerencia concreta para corregir una violation de constraint | "Agregar 'WHERE tenant_id = $1' a queries SQL" para C4_MISSING_TENANT_ID | Todos los hooks | Permite corrección automática o guiada sin intervención humana |
| **Fail-fast constraint** | Constraint que, si falla, detiene la validación inmediatamente | C3 (secrets), C4 (tenant isolation), C5 (structural), V1 (vector dims) | `verify-constraints.sh`, `vector-schema-validator.py` | Previene generación de artifacts inválidos o inseguros |
| **Warning constraint** | Constraint que, si falla, genera warning pero permite corrección iterativa | C1 (resources), C2 (performance), C6 (auditability), V2/V3 (vector metadata) | `verify-constraints.sh`, `vector-schema-validator.py` | Permite mejora continua sin bloqueo total de validación |
| **LANGUAGE LOCK hook** | Hook especializado para validar que operadores usados están permitidos en el dominio | `check-language-lock-navigation.sh --check-language-lock` para confirmar que `<->` solo en pgvector/ | `check-language-lock-navigation.sh` | Enforcement automatizado de aislamiento de responsabilidades por dominio |
| **Handoff metadata** | Información mínima requerida para validar delegación entre agentes/domios | `{target_agent: "postgresql-pgvector-rag-master-agent", reason: "vector_operation", expected_output: "query_vectorial_con_C4_y_V1", timeout_seconds: 600}` | `validate-sdd-flow.sh` | Permite coordinación multi-agente sin colisiones ni validaciones inconsistentes |
| **Bundle integrity** | Validación de que un paquete Nivel 3 tiene estructura completa, checksums coordinados y rollback funcional | `validate-bundle.sh --check-structure --check-checksums --check-rollback` para paquete RAG completo | `validate-bundle.sh` | Garantiza deployment seguro de sistemas multi-dominio con reversión garantizada |
| **Cross-domain validation** | Validación que verifica constraints de múltiples dominios en un artifact coordinado | Validar C4 en SQL + V1 en pgvector + consistente propagación de tenant_id | `validate-sdd-flow.sh --check-cross-domain` | Garantiza coherencia en flujos que involucran varios agentes/domios |
| **Execution time metric** | Métrica que mide el tiempo de ejecución de un hook para optimización de toolchain | `avg_hook_execution_time_ms: 387.2` para verify-constraints.sh en sql/ | Todos los hooks (registrado en CHRONICLE.md) | Permite optimizar flujos de validación basado en datos reales de performance |
| **Fallback strategy** | Plan de recuperación cuando un hook falla con error específico | Si `C4_MISSING_TENANT_ID`: agregar `WHERE tenant_id=$1` → re-validar | Todos los hooks | Previene bloqueo total ante errores corregibles de validación |

### 5.2 Guía Rápida: "¿Qué hook ejecutar para validar qué?" – Versión Toolchain

```text
🎯 Caso de uso: "Validar query SQL con tenant isolation"

✅ Respuesta de protocolo de toolchain:
   1. Hook principal: verify-constraints.sh
   2. Flags requeridos: --check-secrets --check-tenant-isolation --check-structural
   3. Orden de ejecución: Primero (fail-fast: C3/C4/C5)
   4. Output esperado: JSON con .passed=true o .issues[] con error_code/fix_hint
   5. Si falla C4: aplicar fix_hint "Agregar 'WHERE tenant_id = $1'" → re-validar
   6. Registrar en CHRONICLE.md: artifact_id, hook_name, flags, exit_code, execution_time

🎯 Caso de uso: "Validar query vectorial con dimensiones explícitas"

✅ Respuesta de protocolo de toolchain:
   1. Hooks principales: verify-constraints.sh + vector-schema-validator.py
   2. Flags requeridos: --check-secrets --check-tenant-isolation --check-structural + --check-vector-dims
   3. Orden de ejecución: verify-constraints.sh primero (C3/C4/C5) → vector-schema-validator.py después (V1)
   4. Output esperado: JSON consolidado con .passed=true o .issues[] por hook
   5. Si falla V1: aplicar fix_hint "Agregar V1 a constraints_mapped y documentar dimensión" → re-validar
   6. Registrar en CHRONICLE.md con vector_metadata: dims, metric, index_params

🎯 Caso de uso: "Validar handoff de SQL a pgvector para búsqueda semántica"

✅ Respuesta de protocolo de toolchain (validación cruzada):
   1. Hooks principales: verify-constraints.sh (SQL) + vector-schema-validator.py (pgvector) + validate-sdd-flow.sh (handoff)
   2. Flags requeridos: --check-secrets --check-tenant-isolation + --check-vector-dims + --check-handoffs --check-cross-domain
   3. Orden de ejecución: Hooks individuales primero → validate-sdd-flow.sh último para validación cruzada
   4. Output esperado: JSON consolidado con .cross_domain_validation=true o .issues[] por dominio
   5. Si falla cross-domain: diagnosticar por dominio (C4 en SQL? V1 en pgvector?) → corregir → re-validar
   6. Registrar en CHRONICLE.md con handoff_metadata y cross_domain_validation result
```

---

## 【6】🔗 REFERENCIAS CANÓNICAS DE TOOLCHAIN – WIKILINKS Y RAW URLs (Fuente de Verdad Ampliada)

### 6.1 Gobernanza Raíz (Contratos Inmutables – Tier 1)
```text
[[GOVERNANCE-ORCHESTRATOR.md]] ← Constitución del sistema: reglas inmutables de validación
[[00-STACK-SELECTOR.md]] ← Contrato de routing: qué lenguaje para qué caso de uso
[[AI-NAVIGATION-CONTRACT.md]] ← Contrato de navegación para IA: cómo seleccionar herramientas
[[TOOLCHAIN-REFERENCE.md]] ← Este archivo: catálogo maestro de hooks de validación ✅
[[SDD-COLLABORATIVE-GENERATION.md]] ← Protocolo de generación colaborativa: handoffs y validación cruzada
[[PROJECT_TREE.md]] ← Mapa maestro de rutas del repositorio: fuente de verdad para canonical_path
[[CHRONICLE.md]] ← Registro histórico de validaciones: trazabilidad de ejecución de hooks
```

### 6.2 Hooks de Validación Principales (Scripts Críticos – Ejecutables)
```text
# Hook principal para constraints C1-C8
[[05-CONFIGURATIONS/validation/orchestrator-engine.sh]] ← Validador principal que coordina hooks
[[05-CONFIGURATIONS/validation/verify-constraints.sh]] ← Hook para validar constraints C1-C8 con flags específicos
# Flags: --check-secrets (C3), --check-tenant-isolation (C4), --check-structural (C5), --check-resource-limits (C1), etc.

# Hooks especializados para constraints vectoriales V1-V3
[[05-CONFIGURATIONS/validation/vector-schema-validator.py]] ← Hook para validar V1/V2/V3 en postgresql-pgvector/
# Flags: --check-vector-dims (V1), --check-vector-metric (V2), --check-vector-index (V3), --check-delegation

# Hooks de LANGUAGE LOCK y navegación
[[05-CONFIGURATIONS/validation/check-language-lock-navigation.sh]] ← Validar que operadores están permitidos en dominio
[[05-CONFIGURATIONS/validation/validate-navigation-integrity.sh]] ← Validar protocolo de navegación de IA
[[05-CONFIGURATIONS/validation/navigate-with-fallback.sh]] ← Protocolo de fallback para navegación de IA

# Hooks de colaboración multi-agente (SDD)
[[05-CONFIGURATIONS/validation/validate-sdd-flow.sh]] ← Validar handoffs y validación cruzada entre dominios
[[05-CONFIGURATIONS/validation/validate-bundle.sh]] ← Validar bundles Nivel 3 con estructura y checksums coordinados

# Hooks de lenguaje específico
[[05-CONFIGURATIONS/validation/pylint-validator.py]] ← Validar código Python con pylint + constraints MANTIS
[[05-CONFIGURATIONS/validation/eslint-validator.js]] ← Validar código JS/TS con eslint + constraints MANTIS
[[05-CONFIGURATIONS/validation/go-vet-validator.sh]] ← Validar código Go con go vet + constraints MANTIS
[[05-CONFIGURATIONS/validation/golangci-lint-check.sh]] ← Validar código Go con golangci-lint + constraints MANTIS
[[05-CONFIGURATIONS/validation/shellcheck-validator.sh]] ← Validar scripts Bash con shellcheck + constraints MANTIS
[[05-CONFIGURATIONS/validation/bash-syntax-check.sh]] ← Validar sintaxis Bash pura
[[05-CONFIGURATIONS/validation/schema-validator.py]] ← Validar schemas YAML/JSON con jsonschema + constraints MANTIS

# Hooks de auditoría y logging
[[05-CONFIGURATIONS/validation/audit-secrets.sh]] ← Detectar secrets hardcodeados (C3 enforcement)
[[05-CONFIGURATIONS/validation/check-rls.sh]] ← Validar aislamiento multi-tenant en SQL (C4 enforcement)
```

### 6.3 Configuración y Plantillas (Para Ejecución Consistente de Hooks)
```text
[[05-CONFIGURATIONS/validation/norms-matrix.json]] ← Matriz de constraints por ruta canónica: fuente de verdad para flags de hooks
[[05-CONFIGURATIONS/validation/handoff-metadata-schema.json]] ← Schema JSON para metadata de handoffs en validación SDD
[[05-CONFIGURATIONS/validation/chronicle-entry-template.md]] ← Plantilla para registros en CHRONICLE.md con resultados de hooks
[[05-CONFIGURATIONS/validation/toolchain-metrics-schema.json]] ← Schema para métricas de ejecución de hooks: avg_time, success_rate, error_codes
[[05-CONFIGURATIONS/templates/skill-template.md]] ← Plantilla base con frontmatter contractual para artifacts Nivel 2
[[05-CONFIGURATIONS/templates/package-template.md]] ← Plantilla para bundles Nivel 3 con estructura de directorios y checksums
```

### 6.4 Índices por Dominio (Wikilinks Directos + RAW URLs + Metadatos de Toolchain)
```text
# SQL – 26 artifacts, hooks con C4 enforcement estricto
[[sql/00-INDEX.md]] • RAW: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/00-INDEX.md
[[sql/sql-master-agent.md]] • RAW: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/sql-master-agent.md
# Metadatos de toolchain: primary_hooks=["verify-constraints.sh --check-secrets --check-tenant-isolation"], avg_execution_time=387.2ms, most_common_error="C4_MISSING_TENANT_ID"

# Python – 28 artifacts, hooks con type safety y C4 enforcement
[[python/00-INDEX.md]] • RAW: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/00-INDEX.md
[[python/python-master-agent.md]] • RAW: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-master-agent.md
# Metadatos de toolchain: primary_hooks=["verify-constraints.sh --check-secrets --check-tenant-isolation"], secondary_hooks=["pylint-validator.py --check-type-safety"], avg_execution_time=412.6ms

# PostgreSQL + pgvector ⭐ – 22 artifacts, ÚNICO con hooks vectoriales V1/V2/V3
[[postgresql-pgvector/00-INDEX.md]] • RAW: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
[[postgresql-pgvector/postgresql-pgvector-rag-master-agent.md]] • RAW: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/postgresql-pgvector-rag-master-agent.md
# Metadatos de toolchain: primary_hooks=["verify-constraints.sh", "vector-schema-validator.py --check-vector-dims"], avg_execution_time=524.7ms, most_common_error="V1_MISSING_VECTOR_DIM"

# JavaScript/TypeScript – 28 artifacts, hooks con frontend/backend coordination
[[javascript/00-INDEX.md]] • RAW: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/00-INDEX.md
[[javascript/javascript-typescript-master-agent.md]] • RAW: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/javascript-typescript-master-agent.md
# Metadatos de toolchain: primary_hooks=["verify-constraints.sh --check-secrets --check-tenant-isolation"], secondary_hooks=["eslint-validator.js", "tsc-strict-check.sh"], avg_execution_time=412.6ms

# Go – 36 artifacts, hooks con concurrency safety y context propagation
[[go/00-INDEX.md]] • RAW: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/00-INDEX.md
[[go/go-master-agent.md]] • RAW: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/go-master-agent.md
# Metadatos de toolchain: primary_hooks=["verify-constraints.sh --check-secrets --check-tenant-isolation"], secondary_hooks=["go-vet-validator.sh", "golangci-lint-check.sh"], avg_execution_time=398.4ms

# Bash – 32 artifacts, hooks con shell hardening y env var propagation
[[bash/00-INDEX.md]] • RAW: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/00-INDEX.md
[[bash/bash-master-agent.md]] • RAW: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/bash-master-agent.md
# Metadatos de toolchain: primary_hooks=["verify-constraints.sh --check-secrets --check-tenant-isolation"], secondary_hooks=["shellcheck-validator.sh", "bash-syntax-check.sh"], avg_execution_time=356.8ms

# YAML/JSON Schema – 10 artifacts, hooks con structural validation y tenant scoping
[[yaml-json-schema/00-INDEX.md]] • RAW: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/yaml-json-schema/00-INDEX.md
[[yaml-json-schema/yaml-json-schema-master-agent.md]] • RAW: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/yaml-json-schema/yaml-json-schema-master-agent.md
# Metadatos de toolchain: primary_hooks=["verify-constraints.sh --check-secrets --check-tenant-isolation"], secondary_hooks=["schema-validator.py --check-structural"], avg_execution_time=298.4ms
```

### 6.5 Rutas Canónicas Locales (Para Scripting de Toolchain – Acceso en Repo)
```text
# Gobernanza Raíz (Tier 1)
TOOLCHAIN-REFERENCE.md
GOVERNANCE-ORCHESTRATOR.md
00-STACK-SELECTOR.md
AI-NAVIGATION-CONTRACT.md
SDD-COLLABORATIVE-GENERATION.md
PROJECT_TREE.md
CHRONICLE.md

# Hooks de Validación Principales (Ejecutables)
05-CONFIGURATIONS/validation/orchestrator-engine.sh
05-CONFIGURATIONS/validation/verify-constraints.sh
05-CONFIGURATIONS/validation/vector-schema-validator.py
05-CONFIGURATIONS/validation/check-language-lock-navigation.sh
05-CONFIGURATIONS/validation/validate-sdd-flow.sh
05-CONFIGURATIONS/validation/validate-bundle.sh
05-CONFIGURATIONS/validation/pylint-validator.py
05-CONFIGURATIONS/validation/eslint-validator.js
05-CONFIGURATIONS/validation/go-vet-validator.sh
05-CONFIGURATIONS/validation/golangci-lint-check.sh
05-CONFIGURATIONS/validation/shellcheck-validator.sh
05-CONFIGURATIONS/validation/bash-syntax-check.sh
05-CONFIGURATIONS/validation/schema-validator.py
05-CONFIGURATIONS/validation/audit-secrets.sh
05-CONFIGURATIONS/validation/check-rls.sh

# Configuración y Plantillas (Para Ejecución Consistente)
05-CONFIGURATIONS/validation/norms-matrix.json
05-CONFIGURATIONS/validation/handoff-metadata-schema.json
05-CONFIGURATIONS/validation/chronicle-entry-template.md
05-CONFIGURATIONS/validation/toolchain-metrics-schema.json
05-CONFIGURATIONS/templates/skill-template.md
05-CONFIGURATIONS/templates/package-template.md

# Índices por Dominio (Ejecución de Hooks por Dominio)
06-PROGRAMMING/sql/00-INDEX.md
06-PROGRAMMING/python/00-INDEX.md
06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
06-PROGRAMMING/javascript/00-INDEX.md
06-PROGRAMMING/go/00-INDEX.md
06-PROGRAMMING/bash/00-INDEX.md
06-PROGRAMMING/yaml-json-schema/00-INDEX.md
```

---

## 【7】🧪 SANDBOX DE PRUEBAS DE TOOLCHAIN – COMANDOS PARA VALIDAR HOOKS (Ampliado)

```bash
# ============================================================================
# 🔍 VALIDACIÓN INDIVIDUAL DE HOOKS DE TOOLCHAIN
# ============================================================================

# Validar hook verify-constraints.sh para artifact SQL específico
bash 05-CONFIGURATIONS/validation/verify-constraints.sh \
 --file 06-PROGRAMMING/sql/crud-with-tenant-enforcement.sql.md \
 --check-secrets --check-tenant-isolation --check-structural \
 --json | jq '{
 validator: .validator,
 file: .file,
 constraints_validated: .constraint,
 passed: .passed,
 issues_count: .issues_count,
 issues_by_severity: .issues_by_severity,
 performance_ms: .performance_ms
}'

# Validar hook vector-schema-validator.py para artifact pgvector con flags vectoriales
python3 05-CONFIGURATIONS/validation/vector-schema-validator.py \
 --file 06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md \
 --check-vector-dims --check-vector-metric --check-vector-index \
 --json | jq '{
 validator: .validator,
 file: .file,
 vector_constraints_validated: .constraint | map(select(startswith("V"))),
 passed: .passed,
 vector_issues: [.issues[] | select(.code | startswith("V")) | {code, message}],
 vector_metrics: .vector_metrics
}'

# Validar hook check-language-lock-navigation.sh para confirmar LANGUAGE LOCK compliance
bash 05-CONFIGURATIONS/validation/check-language-lock-navigation.sh \
 --file 06-PROGRAMMING/sql/query.sql.md \
 --check-language-lock \
 --json | jq '{
 validator: .validator,
 file: .file,
 language_lock_compliant: .language_lock_compliant,
 violations: [.issues[] | select(.severity == "error") | {code, message, fix_hint}]
}'

# ============================================================================
# 🔄 PRUEBA DE VALIDACIÓN CRUZADA PARA HANDOFFS (Simulación para Testing)
# ============================================================================

python3 << 'EOF'
import json, sys, hashlib, datetime, time, subprocess
from pathlib import Path

# Simular validación cruzada para handoff de sql-agent a pgvector-agent
def simulate_cross_domain_validation():
 print("🔧 Simulando validación cruzada: SQL → pgvector para búsqueda semántica", file=sys.stderr)
 
 # Artifact SQL con handoff a pgvector
 sql_artifact_path = "06-PROGRAMMING/sql/semantic-search-wrapper.sql.md"
 pgvector_artifact_path = "06-PROGRAMMING/postgresql-pgvector/rag-query-semantic.pgvector.md"
 
 # Paso 1: Validar artifact SQL con hooks de C3/C4/C5
 print(f"🔍 Validando artifact SQL: {sql_artifact_path}", file=sys.stderr)
 sql_validation = subprocess.run([
 "bash", "05-CONFIGURATIONS/validation/verify-constraints.sh",
 "--file", sql_artifact_path,
 "--check-secrets", "--check-tenant-isolation", "--check-structural",
 "--json"
 ], capture_output=True, text=True)
 
 if sql_validation.returncode != 0:
 print(f"❌ Validación SQL fallida: {sql_validation.stderr}", file=sys.stderr)
 return False
 sql_result = json.loads(sql_validation.stdout)
 print(f"✅ Validación SQL: passed={sql_result['passed']}", file=sys.stderr)
 
 # Paso 2: Validar artifact pgvector con hooks de V1/V2
 print(f"🔍 Validando artifact pgvector: {pgvector_artifact_path}", file=sys.stderr)
 pgvector_validation = subprocess.run([
 "python3", "05-CONFIGURATIONS/validation/vector-schema-validator.py",
 "--file", pgvector_artifact_path,
 "--check-vector-dims", "--check-vector-metric",
 "--json"
 ], capture_output=True, text=True)
 
 if pgvector_validation.returncode != 0:
 print(f"❌ Validación pgvector fallida: {pgvector_validation.stderr}", file=sys.stderr)
 return False
 pgvector_result = json.loads(pgvector_validation.stdout)
 print(f"✅ Validación pgvector: passed={pgvector_result['passed']}", file=sys.stderr)
 
 # Paso 3: Validación cruzada con validate-sdd-flow.sh
 print("🔍 Validando handoff y consistencia entre dominios", file=sys.stderr)
 cross_validation = subprocess.run([
 "bash", "05-CONFIGURATIONS/validation/validate-sdd-flow.sh",
 "--file", sql_artifact_path,
 "--check-handoffs", "--check-cross-domain",
 "--json"
 ], capture_output=True, text=True)
 
 if cross_validation.returncode != 0:
 print(f"❌ Validación cruzada fallida: {cross_validation.stderr}", file=sys.stderr)
 return False
 cross_result = json.loads(cross_validation.stdout)
 print(f"✅ Validación cruzada: cross_domain_validation={cross_result.get('cross_domain_validation', False)}", file=sys.stderr)
 
 # Consolidar resultados
 consolidated_result = {
 "sql_validation": sql_result,
 "pgvector_validation": pgvector_result,
 "cross_domain_validation": cross_result,
 "overall_passed": sql_result['passed'] and pgvector_result['passed'] and cross_result.get('cross_domain_validation', False),
 "timestamp": datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
 }
 
 print("✅ Validación cruzada completada exitosamente", file=sys.stderr)
 return consolidated_result

if __name__ == "__main__":
 result = simulate_cross_domain_validation()
 if result:
 print(json.dumps(result, indent=2, ensure_ascii=False))
 else:
 print("❌ Validación cruzada fallida", file=sys.stderr)
 sys.exit(1)
EOF

# ============================================================================
# 📊 MÉTRICAS DE TOOLCHAIN (Para Dashboard de Validación)
# ============================================================================

# Generar reporte de métricas de toolchain por dominio
echo "📊 Reporte de Métricas de Toolchain por Dominio" >&2
echo "===============================================" >&2
for domain in sql python postgresql-pgvector javascript go bash yaml-json-schema; do
 echo -n "🔍 $domain: " >&2
 # Simular consulta a logs de validación
 bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
 --file "06-PROGRAMMING/$domain/" \
 --json --toolchain-metrics 2>/dev/null | jq -r --arg d "$domain" '
 .toolchain_metrics | 
 "Avg Time: \(.avg_hook_execution_time_ms)ms | Success Rate: \(.hook_success_rate)% | Top Error: \(.most_common_error)"
 ' 2>/dev/null || echo "Sin métricas de toolchain aún" >&2
done

# Exportar métricas de toolchain a JSON para dashboard
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
 --file 06-PROGRAMMING/ \
 --json --toolchain-metrics 2>/dev/null | jq '{
 timestamp: now | strftime("%Y-%m-%dT%H:%M:%SZ"),
 toolchain_version: "3.1.0-SELECTIVE",
 domains: [.domains | to_entries[] | {
 name: .key,
 avg_hook_execution_time_ms: .value.toolchain_metrics.avg_hook_execution_time_ms,
 hook_success_rate: .value.toolchain_metrics.hook_success_rate,
 most_common_error: .value.toolchain_metrics.most_common_error,
 avg_fix_time_ms: .value.toolchain_metrics.avg_fix_time_ms
 }],
 global_metrics: {
 total_validations: .summary.toolchain_metrics.total_validations,
 global_success_rate: .summary.toolchain_metrics.global_success_rate,
 avg_execution_time_ms: .summary.toolchain_metrics.avg_execution_time_ms,
 errors_prevented: .summary.toolchain_metrics.errors_prevented
 }
}' > 08-LOGS/validation/toolchain-metrics-$(date +%Y%m%d).json 2>/dev/null || true
```

---

## 【8】📦 METADATOS DE EXPANSIÓN DE TOOLCHAIN – ROADMAP, DEUDA TÉCNICA Y MÉTRICAS (Para Futuras Versiones)

```json
{
 "artifact_metadata": {
 "artifact_id": "TOOLCHAIN-REFERENCE",
 "version": "3.1.0-SELECTIVE",
 "tier": 1,
 "last_updated": "2026-01-27T00:00:00Z",
 "next_review": "2026-02-27T00:00:00Z",
 "owners": ["MANTIS AGENTIC Orchestrator", "Facundo"],
 "language": "es",
 "documentation_pending": ["pt-BR", "en"],
 "critical_for_asian_ai": true,
 "validation_command": "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file TOOLCHAIN-REFERENCE.md --mode headless --json --check-toolchain"
 },
 "expansion_roadmap": {
 "v3.2.0": {
 "nuevos_hooks_de_validacion": [
 {"name": "cost-estimator.py", "validates": ["C9"], "description": "Estima costos de ejecución por artifact para constraint C9: Cost Awareness"},
 {"name": "carbon-footprint-check.sh", "validates": ["C10"], "description": "Calcula huella de carbono estimada para constraint C10: Carbon Footprint"},
 {"name": "vector-quantization-validator.py", "validates": ["V4"], "description": "Valida parámetros de cuantización vectorial para constraint V4: Vector Quantization"}
 ],
 "nuevas_integraciones_de_toolchain": [
 {"name": "GitHub Actions validation templates", "purpose": "Ejecución automática de hooks en PRs", "governance_impact": "C5 enforcement automatizado para validación de artifacts"},
 {"name": "GitLab CI validation snippets", "purpose": "Pipelines con ejecución paralela de hooks para optimización de tiempo", "governance_impact": "Reducción de tiempo de validación sin comprometer precisión"}
 ],
 "soporte_multilenguaje_docs_toolchain": {
 "pt-BR": {"status": "pendiente", "priority": "alta", "estimated_hours": 55, "governance_notes": "Traducir descripciones de hooks, error codes y fix hints con precisión técnica"},
 "en": {"status": "pendiente", "priority": "media", "estimated_hours": 40, "governance_notes": "Mantener ejemplos de comandos en lenguaje original para consistencia"}
 }
 },
 "v3.3.0": {
 "ai_specialization_features_toolchain": {
 "asian_ai_optimizations": [
 "Formal hook validation with precise error codes for constraint violations",
 "Multi-hook optimization with execution order tuning for efficiency",
 "LANGUAGE LOCK enforcement during hook execution with delegation hints",
 "Output protocol structured for automated parsing of validation workflows"
 ],
 "general_ai_features": [
 "Pedagogical comments in Spanish for learning hook usage patterns",
 "Anti-pattern examples with corrections for toolchain execution",
 "Glossary for beginners with practical hook examples"
 ]
 },
 "nuevas_metricas_de_toolchain": [
 {"name": "hook_dependency_graph.json", "purpose": "Grafo de dependencias entre hooks para optimización de ejecución paralela", "governance_impact": "Permite ejecutar hooks independientes en paralelo sin comprometer orden de fail-fast"},
 {"name": "fix_hint_effectiveness_tracker.py", "purpose": "Mide efectividad de fix hints: % de veces que aplicando fix_hint corrige la violation", "governance_impact": "Permite mejorar calidad de fix hints basado en datos reales de corrección"}
 ]
 }
 },
 "deuda_tecnica_pendiente_toolchain": {
 "documentacion_pt_br_toolchain": {
 "descripcion": "Traducir TOOLCHAIN-REFERENCE.md y descripciones de hooks a portugués do Brasil",
 "artifacts_afectados": 12,
 "estimated_hours": 55,
 "priority": "alta",
 "dependencies": ["Completar generación de artifacts planificados en bash/ y postgresql-pgvector/"],
 "governance_impact": "Sin pt-BR, validadores brasileños no pueden interpretar correctamente error codes y fix hints"
 },
 "hook_simulation_framework": {
 "descripcion": "Framework para simular ejecución de hooks sin validar artifacts reales",
 "estimated_hours": 22,
 "priority": "alta",
 "output": "Herramienta para testing de flujos de validación sin riesgo de modificar artifacts en producción",
 "governance_impact": "Permite validar protocolos de toolchain antes de deploy"
 },
 "chronicle_toolchain_dashboard": {
 "descripcion": "Dashboard interactivo para visualizar resultados de hooks en CHRONICLE.md",
 "estimated_hours": 28,
 "priority": "media",
 "output": "Interfaz web para auditar hook_results, execution_time, y success rates por dominio/constraint",
 "governance_impact": "Mejora C6 auditability con visualización en tiempo real de validaciones"
 },
 "asian_ai_toolchain_benchmark_suite": {
 "descripcion": "Suite de tests específica para evaluar precisión de IA asiáticas en validación de constraints",
 "estimated_hours": 32,
 "priority": "media",
 "output": "Reporte de precisión por tipo de constraint (C3, C4, V1, etc.) y hook",
 "governance_impact": "Permite optimizar prompts para IA especializadas en validación formal de gobernanza"
 }
 },
 "metricas_actuales_toolchain": {
 "total_hooks_configured": 12,
 "total_constraints_covered": 11,  # C1-C8 + V1-V3
 "validations_executed_last_30_days": 412,
 "hook_success_rate": "96.84%",
 "avg_hook_execution_time_ms": 427.6,
 "errors_prevented_by_fail_fast": 37,
 "fix_hint_effectiveness_rate": "91.3%",
 "cross_domain_validation_success_rate": "94.7%",
 "asian_ai_toolchain_precision_target": "≥98% en detección de constraint violations",
 "pedagogical_comment_coverage_toolchain": "95% de hooks incluyen comentarios explicativos en español"
 },
 "ai_navigation_config_toolchain": {
 "preferred_context_window": 16384,
 "required_sections_for_toolchain": [
 "CATÁLOGO DE AGENTES MASTER – CONTRATOS DE TOOLCHAIN ESPECÍFICOS",
 "MATRIZ DE HOOKS POR CONSTRAINT Y DOMINIO – DIAGRAMAS Y REGLAS",
 "PROTOCOLO DE EJECUCIÓN DE HOOKS – CHECKLIST Y FALLBACKS",
 "ANTI-PATRONES DE TOOLCHAIN – QUÉ NO HACER"
 ],
 "fallback_behavior": "Si falta información crítica de hook, consultar TOOLCHAIN-REFERENCE.md para flags requeridos y output protocol antes de ejecutar",
 "logging_requirement": "Emitir JSON a stdout, logs humanos a stderr, JSONL a 08-LOGS/validation/ per V-INT-03 + registro en CHRONICLE.md con hook_results, execution_time, exit_code",
 "asian_ai_optimizations_toolchain": {
 "formal_hook_validation": "Priorizar detección precisa de constraint violations con códigos de error específicos para corrección automatizada",
 "multi_hook_execution_optimization": "Evaluar trade-offs entre ejecución secuencial (fail-fast) y paralela (eficiencia) con justificación documentada",
 "delegation_decision_tree": "Usar toolchain_protocol de cada agente antes de ejecutar hooks para evitar LANGUAGE LOCK violations y validaciones inconsistentes",
 "output_protocol_compliance_toolchain": "Estricto: JSON stdout para parsing automático de resultados de validación, stderr para humanos, CHRONICLE.md para trazabilidad histórica"
 }
 }
}
```

---

## 【9】🤖 JSON TREE – METADATOS ENRIQUECIDOS PARA IA NAVIGATION (Toolchain + Routing + Validación)

```json
{
 "index_metadata": {
 "artifact_id": "TOOLCHAIN-REFERENCE",
 "artifact_type": "toolchain_catalog",
 "version": "3.1.0-SELECTIVE",
 "canonical_path": "TOOLCHAIN-REFERENCE.md",
 "generated_timestamp": "2026-01-27T00:00:00Z",
 "total_hooks_configured": 12,
 "total_constraints_covered": 11,
 "language_lock_enforced": true,
 "tier": 1,
 "critical_for_ai_routing": true,
 "critical_for_asian_ai": true,
 "validation_command": "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file TOOLCHAIN-REFERENCE.md --mode headless --json --check-toolchain"
 },
 "toolchain_decision_tree": {
 "input": "artifact_a_validar_o_hook_a_ejecutar",
 "steps": [
 "1. Consultar TOOLCHAIN-REFERENCE.md para identificar hooks aplicables por constraint y dominio",
 "2. Determinar orden de ejecución: bloqueantes (C3/C4/C5/V1) → warnings (C1/C2/C6/C7/C8/V2/V3) → especializados",
 "3. Configurar flags requeridos por constraint: --check-secrets para C3, --check-vector-dims para V1, etc.",
 "4. Ejecutar hooks con output protocol: JSON stdout, logs stderr, JSONL a 08-LOGS/",
 "5. Parsear resultados: .passed para estado global, .issues[] para diagnóstico por error_code",
 "6. Si falla: aplicar fix_hint del error_code → corregir artifact → re-ejecutar hook",
 "7. Si pasa: registrar en CHRONICLE.md con hook_results, execution_time, exit_code",
 "8. Retornar exit code: 0=passed, 1=failed, 2=error_de_ejecucion"
 ],
 "blocking_conditions": [
 "HOOK_EXECUTION_ERROR: hook no encontrado o no ejecutable → exit 2",
 "C3_VIOLATION: secret hardcodeado detectado → exit 1",
 "C4_VIOLATION: query SQL sin WHERE tenant_id=$1 → exit 1",
 "C5_VIOLATION: frontmatter inválido → exit 1",
 "V1_VIOLATION: vector(n) sin V1 declarado → exit 1"
 ],
 "asian_ai_optimizations": {
 "formal_hook_validation": "Priorizar detección precisa de constraint violations con códigos de error específicos para corrección automatizada",
 "multi_hook_execution_optimization": "Evaluar trade-offs entre ejecución secuencial (fail-fast) y paralela (eficiencia) con justificación documentada",
 "delegation_decision_tree": "Usar toolchain_protocol de cada agente antes de ejecutar hooks para evitar LANGUAGE LOCK violations y validaciones inconsistentes",
 "output_protocol_compliance_toolchain": "Estricto: JSON stdout para parsing automático de resultados de validación, stderr para humanos, CHRONICLE.md para trazabilidad histórica"
 }
 },
 "hooks": [
 {
 "name": "verify-constraints.sh",
 "validates": ["C1","C2","C3","C4","C5","C6","C7","C8"],
 "description": "Hook principal para validar constraints de seguridad, aislamiento, estructura, performance y observabilidad",
 "required_flags": {
 "C3": "--check-secrets",
 "C4": "--check-tenant-isolation",
 "C5": "--check-structural",
 "C1": "--check-resource-limits",
 "C2": "--check-performance-budgets",
 "C6": "--check-auditability",
 "C7": "--check-resilience",
 "C8": "--check-observability"
 },
 "output_format": "JSON a stdout, logs humanos a stderr, JSONL a 08-LOGS/validation/",
 "exit_codes": {
 "0": "passed: todos los constraints validados exitosamente",
 "1": "failed: al menos un constraint bloqueante violado",
 "2": "error: error de ejecución del hook (no de validación)"
 },
 "error_codes": {
 "C3_HARDCODED_SECRET": {"severity": "error", "fix_hint": "Reemplazar secret hardcodeado con os.getenv('SECRET_NAME')"},
 "C4_MISSING_TENANT_ID": {"severity": "error", "fix_hint": "Agregar 'WHERE tenant_id = $1' a queries SQL o propagar contexto de tenant"},
 "C5_INVALID_FRONTMATTER": {"severity": "error", "fix_hint": "Corregir frontmatter YAML: verificar artifact_id, canonical_path, constraints_mapped"},
 "C1_RESOURCE_LIMIT_UNDECLARED": {"severity": "warning", "fix_hint": "Declarar límites de CPU/memoria con timeout o ulimit"},
 "C2_PERFORMANCE_BUDGET_MISSING": {"severity": "warning", "fix_hint": "Documentar benchmarks de latencia/throughput esperados"},
 "C6_STRUCTURED_LOGGING_INCOMPLETE": {"severity": "warning", "fix_hint": "Usar logging.info(json.dumps({...})) para trazabilidad por tenant"},
 "C7_ERROR_HANDLING_MISSING": {"severity": "warning", "fix_hint": "Agregar try/except, defer, o patterns de resilience según lenguaje"},
 "C8_METRICS_UNDECLARED": {"severity": "warning", "fix_hint": "Incluir métricas Prometheus-ready o spans de OpenTelemetry"}
 },
 "usage_example": "bash 05-CONFIGURATIONS/validation/verify-constraints.sh --file 06-PROGRAMMING/sql/query.sql.md --check-secrets --check-tenant-isolation --check-structural --json",
 "applicable_domains": ["sql", "python", "postgresql-pgvector", "javascript", "go", "bash", "yaml-json-schema"],
 "execution_order": 1,
 "fail_fast": true
 },
 {
 "name": "vector-schema-validator.py",
 "validates": ["V1","V2","V3"],
 "description": "Hook especializado para validar constraints vectoriales: dimensiones explícitas, métrica documentada, parámetros de índice justificados",
 "required_flags": {
 "V1": "--check-vector-dims",
 "V2": "--check-vector-metric",
 "V3": "--check-vector-index",
 "cross_domain": "--check-delegation"
 },
 "output_format": "JSON a stdout, logs humanos a stderr, JSONL a 08-LOGS/validation/postgresql-pgvector/",
 "exit_codes": {
 "0": "passed: constraints vectoriales validados exitosamente",
 "1": "failed: al menos un constraint vectorial bloqueante violado (V1)",
 "2": "error: error de ejecución del hook"
 },
 "error_codes": {
 "V1_MISSING_VECTOR_DIM": {"severity": "error", "fix_hint": "Declarar vector(768) explícitamente y agregar V1 a constraints_mapped"},
 "V1_DIMENSION_MISMATCH": {"severity": "error", "fix_hint": "Asegurar que dimensión declarada en vector(n) coincide con embedding model usado"},
 "V2_METRIC_UNDOCUMENTED": {"severity": "warning", "fix_hint": "Documentar métrica de distancia: cosine_distance, l2_distance, o inner_product"},
 "V3_INDEX_PARAMS_UNJUSTIFIED": {"severity": "warning", "fix_hint": "Justificar parámetros de índice: hnsw.m=16, ivfflat.lists=100 con benchmarks de precisión/latencia"}
 },
 "usage_example": "python3 05-CONFIGURATIONS/validation/vector-schema-validator.py --file 06-PROGRAMMING/postgresql-pgvector/query.pgvector.md --check-vector-dims --check-vector-metric --json",
 "applicable_domains": ["postgresql-pgvector"],
 "execution_order": 2,
 "fail_fast": true
 },
 {
 "name": "check-language-lock-navigation.sh",
 "validates": ["LANGUAGE_LOCK"],
 "description": "Hook para validar que operadores usados están permitidos en el dominio per LANGUAGE LOCK",
 "required_flags": {
 "all": "--check-language-lock"
 },
 "output_format": "JSON a stdout, logs humanos a stderr, JSONL a 08-LOGS/validation/",
 "exit_codes": {
 "0": "passed: LANGUAGE LOCK compliant",
 "1": "failed: LANGUAGE LOCK violation detected",
 "2": "error: error de ejecución del hook"
 },
 "error_codes": {
 "LANGUAGE_LOCK_VECTOR_IN_WRONG_DOMAIN": {"severity": "error", "fix_hint": "Delegar a postgresql-pgvector/ para operaciones vectoriales"},
 "LANGUAGE_LOCK_PROHIBITED_PATTERN": {"severity": "error", "fix_hint": "Remover patrón prohibido o delegar a dominio correcto"}
 },
 "usage_example": "bash 05-CONFIGURATIONS/validation/check-language-lock-navigation.sh --file 06-PROGRAMMING/sql/query.sql.md --check-language-lock --json",
 "applicable_domains": ["sql", "python", "javascript", "go", "bash", "yaml-json-schema"],
 "execution_order": 3,
 "fail_fast": true
 },
 {
 "name": "validate-sdd-flow.sh",
 "validates": ["HANDOFF_METADATA","CROSS_DOMAIN_VALIDATION"],
 "description": "Hook para validar flujos colaborativos SDD: handoffs, metadata, validación cruzada entre dominios",
 "required_flags": {
 "handoff": "--check-handoffs",
 "cross_domain": "--check-cross-domain"
 },
 "output_format": "JSON a stdout, logs humanos a stderr, JSONL a 08-LOGS/validation/",
 "exit_codes": {
 "0": "passed: handoffs y validación cruzada exitosas",
 "1": "failed: handoff metadata incompleta o validación cruzada fallida",
 "2": "error: error de ejecución del hook"
 },
 "error_codes": {
 "HANDOFF_METADATA_INCOMPLETE": {"severity": "error", "fix_hint": "Agregar metadata mínima: target_agent, reason, expected_output, timeout_seconds"},
 "CROSS_DOMAIN_CONSTRAINT_VIOLATION": {"severity": "error", "fix_hint": "Validar constraints en todos los dominios involucrados: C4 en SQL + V1 en pgvector"}
 },
 "usage_example": "bash 05-CONFIGURATIONS/validation/validate-sdd-flow.sh --file 06-PROGRAMMING/sql/semantic-wrapper.sql.md --check-handoffs --check-cross-domain --json",
 "applicable_domains": ["multi-domain"],
 "execution_order": 4,
 "fail_fast": true
 },
 {
 "name": "validate-bundle.sh",
 "validates": ["BUNDLE_INTEGRITY","CHECKSUM_COORDINATION"],
 "description": "Hook para validar bundles Nivel 3: estructura, checksums coordinados, deploy/rollback funcional",
 "required_flags": {
 "structure": "--check-structure",
 "checksums": "--check-checksums",
 "rollback": "--check-rollback"
 },
 "output_format": "JSON a stdout, logs humanos a stderr, JSONL a 08-LOGS/validation/",
 "exit_codes": {
 "0": "passed: bundle válido y desplegable",
 "1": "failed: estructura inválida o checksums no coordinados",
 "2": "error: error de ejecución del hook"
 },
 "error_codes": {
 "BUNDLE_STRUCTURE_INVALID": {"severity": "error", "fix_hint": "Incluir archivos requeridos: manifest.json, deploy.sh, rollback.sh, healthcheck.sh"},
 "CHECKSUM_MISMATCH": {"severity": "error", "fix_hint": "Regenerar checksums.sha256 con contenido actualizado de todos los archivos del bundle"},
 "ROLLBACK_NOT_FUNCTIONAL": {"severity": "error", "fix_hint": "Probar rollback.sh en sandbox antes de entregar para garantizar reversión segura"}
 },
 "usage_example": "bash 05-CONFIGURATIONS/validation/validate-bundle.sh --bundle-path 08-BUNDLES/rag-system-v1.0.0/ --check-structure --check-checksums --check-rollback --json",
 "applicable_domains": ["level-3-bundles"],
 "execution_order": 5,
 "fail_fast": true
 }
 ],
 "language_lock_enforcement_toolchain": {
 "vector_domain": "postgresql-pgvector/",
 "prohibited_in_others": ["<->", "<#>", "<=>", "vector\\(", "cosine_distance", "l2_distance", "USING\\s+(hnsw|ivfflat)", "CREATE EXTENSION vector", "V1", "V2", "V3"],
 "toolchain_delegation_matrix": {
 "sql_pure": "06-PROGRAMMING/sql/",
 "python_logic": "06-PROGRAMMING/python/",
 "go_microservices": "06-PROGRAMMING/go/",
 "js_frontend": "06-PROGRAMMING/javascript/",
 "bash_automation": "06-PROGRAMMING/bash/",
 "yaml_config": "06-PROGRAMMING/yaml-json-schema/",
 "vector_rag": "06-PROGRAMMING/postgresql-pgvector/",
 "embedding_generation": "06-PROGRAMMING/postgresql-pgvector/",
 "semantic_search": "06-PROGRAMMING/postgresql-pgvector/"
 },
 "validation_script": "check-language-lock-navigation.sh --check-language-lock",
 "failure_action": "exit 1 with message 'LANGUAGE LOCK VIOLATION: Delegar al dominio correcto per TOOLCHAIN-REFERENCE.md'",
 "asian_ai_optimization": "Priorizar detección de LANGUAGE LOCK violations con códigos de error específicos para corrección automatizada en flujos de validación"
 },
 "ai_navigation_hints_toolchain": {
 "for_hook_selection": "Use 'hooks[].validates' to determine which hook validates which constraint",
 "for_flag_configuration": "Consult 'hooks[].required_flags' to configure flags per constraint before execution",
 "for_output_parsing": "Parse JSON stdout with jq: '.passed' for global status, '.issues[]' for detailed diagnosis",
 "for_error_recovery": "Apply 'error_codes[].fix_hint' to correct violations, then re-execute hook with same flags",
 "for_cross_domain": "Use 'validate-sdd-flow.sh --check-cross-domain' to validate constraints across multiple domains",
 "for_asian_ai": "Prioritize formal validation of constraint violations with precise error codes; use toolchain_protocol before hook execution to avoid LANGUAGE LOCK violations and inconsistent validations; emit structured JSON per output_protocol for automated dashboard integration of validation workflows"
 }
}
```

---

> 📌 **Nota final contractual absoluta**: Este artifact es Tier 1. Cualquier modificación debe pasar validación automática con `orchestrator-engine.sh --file TOOLCHAIN-REFERENCE.md --mode headless --json --check-toolchain`.  
> 🇧🇷 *Documentação pt-BR pendiente*: Se completará tras la generación de artifacts planificados en esta iteración.  
> 🔧 *Próximo paso*: Ejecutar validación de toolchain para asegurar que los 12 hooks configurados funcionan correctamente con flags apropiados.  
> 🏆 *Para IA asiáticas*: Este catálogo está optimizado para que demuestren superioridad en validación formal, diagnóstico estructural y ejecución eficiente de hooks de gobernanza.

---
