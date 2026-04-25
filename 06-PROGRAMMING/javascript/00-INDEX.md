---
artifact_id: "00-INDEX-javascript"
artifact_type: "skill_index"
version: "3.1.0-SELECTIVE"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/00-INDEX.md --json"
canonical_path: "06-PROGRAMMING/javascript/00-INDEX.md"
---

# JavaScript/TypeScript Patterns Master Index – Multi-Tenant Hardening & AI Integration

## 👤 Propósito y Alcance
Índice canónico de navegación para `06-PROGRAMMING/javascript/`. Documenta 26 artifacts auditados bajo HARNESS NORMS v3.1.0-SELECTIVE, mapea flujos de ejecución para desarrollo full-stack con aislamiento multi-tenant, referencia al **agente master de generación JavaScript/TypeScript**, y proporciona un árbol JSON enriquecido para routing de agentes LLM y pipelines CI/CD.

> 🔑 **Diferenciador crítico**: Este dominio cubre tanto JavaScript (ES2022+) como TypeScript (5.x) con enfoque en:
> - Type safety con TypeScript para validación estática de contracts multi-tenant
> - Runtime checks para JavaScript con validación de tenant_id en tiempo de ejecución
> - Integración segura con backends (SQL, pgvector, Python) respetando LANGUAGE LOCK

---

## 🤖 Agente de Generación Disponible

| Agente | Canonical Path | Dominio | Constraints Soportados | Hooks de Validación |
|--------|---------------|---------|----------------------|-------------------|
| **`javascript-typescript-master-agent`** ✅ | `[[06-PROGRAMMING/javascript/javascript-typescript-master-agent.md]]` | `javascript,typescript,nodejs,react,vue` | `C1,C2,C3,C4,C5,C7,C8` | `verify-constraints.sh`, `audit-secrets.sh`, `eslint-validator.js`, `tsc-strict-check.sh` |

> ⚠️ **Nota contractual**: Este agente es Tier 1 (referencia educativa). Cualquier módulo generado debe pasar validación automática antes de merge. Documentación técnica en pt-BR: `docs/pt-BR/programming/javascript/javascript-typescript-master-agent/README.md`.

---

## 📂 Mapeo de Fases y Wikilinks

### FASE 0 – Core Hardening (Pre-flight & Type Safety)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[js-hardening-verification.js.md]]` | C3,C4,C5,C7,C8 | Validación de entorno Node.js, límites de recursos y type-checking pre-ejecución |
| `[[ts-strict-mode-enforcement.ts.md]]` | C4,C5,C7,C8 | Configuración `tsconfig.json` con `strict: true`, `noImplicitAny`, `exactOptionalPropertyTypes` |
| `[[js-error-boundaries-patterns.js.md]]` | C4,C5,C7,C8 | Error boundaries en React/Vue con logging estructurado y recuperación segura |

### FASE 1 – Multi-Tenant Security (Aislamiento en Frontend/Backend)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[js-tenant-context-provider.ts.md]]` | C3,C4,C5,C7,C8 | Context API/Pinia store para inyección segura de `tenant_id` en toda la app |
| `[[js-rbac-hooks-patterns.ts.md]]` | C3,C4,C8 | Custom hooks para validación de permisos RBAC por tenant en componentes |
| `[[js-secrets-frontend-handling.js.md]]` | C3,C5,C7 | Gestión de secrets en frontend: zero hardcode, env vars via Vite/Webpack, vault integration |
| `[[js-audit-logging-frontend.ts.md]]` | C4,C5,C8 | Logging estructurado JSON en frontend con trazabilidad por tenant y correlación de requests |

### FASE 2 – API Integration & Data Fetching
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[js-fetch-with-tenant-enforcement.ts.md]]` | C3,C4,C8 | Wrapper de `fetch`/`axios` que inyecta automáticamente `X-Tenant-ID` y valida respuestas |
| `[[js-graphql-tenant-directives.ts.md]]` | C4,C5,C8 | Directivas GraphQL `@tenantScoped` para validación automática en queries/mutations |
| `[[js-websocket-tenant-isolation.ts.md]]` | C4,C7,C8 | Conexiones WebSocket con scope de tenant y reconexión segura con re-auth |
| `[[js-api-error-handling-strategies.ts.md]]` | C4,C5,C7,C8 | Estrategias unificadas para manejo de errores 401/403/409 con retry lógico por tenant |

### FASE 3 – State Management & Reactivity
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[js-redux-tenant-middleware.ts.md]]` | C4,C5,C8 | Middleware de Redux que filtra acciones por tenant_id y previene cross-tenant state leakage |
| `[[js-vue-composables-tenant-scoped.ts.md]]` | C4,C5,C8 | Composables de Vue 3 con scope implícito de tenant para reactividad segura |
| `[[js-react-query-tenant-keys.ts.md]]` | C4,C7,C8 | Query keys de React Query con tenant_id para cache isolation y invalidación granular |
| `[[js-state-persistence-encryption.ts.md]]` | C3,C4,C7 | Persistencia de estado en localStorage/IndexedDB con encriptación por tenant |

### FASE 4 – MCP/IA Tooling (Integración con Agentes)
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[js-mcp-client-implementation.ts.md]]` | C3,C4,C8 | Cliente MCP en JS/TS con inyección automática de contexto de tenant en tool calls |
| `[[js-ia-response-validation-gate.ts.md]]` | C3,C4,C5,C8 | Gate de validación para respuestas de LLM: schema validation, tenant scoping, content filtering |
| `[[js-streaming-ia-with-tenant.ts.md]]` | C4,C7,C8 | Streaming de respuestas IA con chunk validation y cancellation por tenant |
| `[[js-prompt-injection-defense.ts.md]]` | C3,C4,C7 | Patrones de defensa contra prompt injection en inputs de usuario con sanitización por contexto |

### FASE 5 – Testing & Validation
| Artifact | Constraints | Propósito |
|----------|-------------|-----------|
| `[[js-vitest-tenant-isolation.ts.md]]` | C4,C5,C8 | Fixtures de Vitest/Jest con aislamiento de tenant y mocks de API tenant-scoped |
| `[[js-e2e-tenant-scenario-tests.ts.md]]` | C3,C4,C7 | Tests E2E con Playwright/Cypress que simulan flujos multi-tenant completos |
| `[[js-type-safety-contract-tests.ts.md]]` | C4,C5,C8 | Tests de contratos TypeScript: validación de interfaces API con `zod`/`io-ts` por tenant |
| `[[js-security-fuzzing-frontend.js.md]]` | C3,C7,C8 | Fuzzing de inputs frontend con detección de XSS, CSRF y tenant leakage |

---

## 🔗 Interacciones con el Repositorio
- **`05-CONFIGURATIONS/validation/`**: Todos los artifacts son validados por `orchestrator-engine.sh`. Los scripts `verify-constraints.sh`, `eslint-validator.js` y `tsc-strict-check.sh` consumen el JSON de este índice.
- **`01-RULES/`**: Las normas `harness-norms-v3.0.md`, `language-lock-protocol.md` y `06-MULTITENANCY-RULES.md` definen los constraints C1-C8 aplicados.
- **`06-PROGRAMMING/postgresql-pgvector/`**: Carpeta hermana con LANGUAGE LOCK estricto. **Delegación obligatoria**: queries vectoriales deben generarse en `postgresql-pgvector/`, no aquí.
- **`06-PROGRAMMING/python/`**: Para lógica de backend pesada o embedding generation, usar `python/` y consumir via API desde este dominio.
- **`06-PROGRAMMING/sql/`**: Para queries SQL puras (sin vectores), delegar a `sql/` y consumir via ORM o query builder desde JS/TS.
- **`08-LOGS/`**: Los handlers de logging estructurado (C8) en frontend/backend alimentan dashboards y generan entradas en `failed-attempts/` si fallan validaciones de tenant isolation.
- **`javascript-typescript-master-agent.md`**: Punto único de generación para nuevos artifacts JS/TS. Consulta este índice ANTES de emitir módulos para asegurar coherencia con patrones existentes.

---

## ⚠️ Reglas Críticas de LANGUAGE LOCK para javascript/

```text
🚫 PROHIBIDO en esta carpeta:
• Importación o uso de operadores pgvector: import { cosineDistance } from 'pgvector', vector(n), <->, <#>, <=>
• Queries SQL embebidas con sintaxis de extensión pgvector
• Constraints vectoriales V1/V2/V3 en constraints_mapped del frontmatter
• CREATE EXTENSION vector; o cualquier referencia directa a pgvector en código JS/TS

✅ REQUERIDO en esta carpeta:
• artifact_type: "javascript_module" | "typescript_module" | "javascript_pattern" | "typescript_pattern" | "frontend_component" (NUNCA "skill_pgvector")
• constraints_mapped: SOLO valores de C1-C8 (V* bloqueado por LANGUAGE LOCK)
• Módulos que interactúan con DB deben validar tenant_id en requests o usar context providers con scope de tenant
• validation_command que referencie orchestrator-engine.sh con canonical_path correcto
• Agente master: consultar norms-matrix.json antes de declarar constraints en módulos generados
• Type safety: usar TypeScript para contracts de API con tenant_id obligatorio en interfaces
```

---

## 🤖 JSON TREE ENRIQUECIDO PARA IA (Metadatos + Dependencias + Prioridad de Normas)

```json
{
 "index_metadata": {
 "artifact_id": "00-INDEX-javascript",
 "artifact_type": "skill_index",
 "version": "3.1.0-SELECTIVE",
 "canonical_path": "06-PROGRAMMING/javascript/00-INDEX.md",
 "language_lock_status": "enforced",
 "vector_constraints_applied": false,
 "generated_timestamp": "2026-01-27T00:00:00Z",
 "master_agent": "javascript-typescript-master-agent"
 },
 "artifacts": [
 {
 "artifact_id": "javascript-typescript-master-agent",
 "file": "javascript-typescript-master-agent.md",
 "canonical_path": "06-PROGRAMMING/javascript/javascript-typescript-master-agent.md",
 "artifact_type": "agentic_skill_definition",
 "tier": 1,
 "constraints_mapped": ["C1","C2","C3","C4","C5","C7","C8"],
 "language_lock": ["javascript","typescript","nodejs","react","vue"],
 "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "eslint-validator.js", "tsc-strict-check.sh"],
 "examples_count": 15,
 "score_baseline": 93,
 "dependencies": {
 "validators": ["verify-constraints.sh", "audit-secrets.sh", "eslint-validator.js", "tsc-strict-check.sh"],
 "norms": ["harness-norms-v3.0.md", "10-SDD-CONSTRAINTS.md", "language-lock-protocol.md", "06-MULTITENANCY-RULES.md"],
 "config": ["norms-matrix.json", "skill-template.md", "tsconfig.json", "eslint.config.js"]
 },
 "dependents": ["all javascript/typescript artifacts"],
 "norms_priority": {
 "execution_order": ["C4", "C3", "C5", "C7", "C8", "C1", "C2"],
 "blocking_constraints": ["C3", "C4"],
 "rationale": "Security (C3) and tenant isolation (C4) are foundational for module generation"
 },
 "interactions": {
 "with_validation": "Emits JSON to stdout, logs to stderr, JSONL to 08-LOGS/ per V-INT-03",
 "with_config": "Consults norms-matrix.json before declaring constraints in generated modules",
 "with_programming": "Delegates vector operations to postgresql-pgvector/, SQL to sql/, backend logic to python/ per LANGUAGE LOCK"
 }
 },
 {
 "artifact_id": "js-hardening-verification",
 "file": "js-hardening-verification.js.md",
 "canonical_path": "06-PROGRAMMING/javascript/js-hardening-verification.js.md",
 "constraints_mapped": ["C3","C4","C5","C7","C8"],
 "examples_count": 10,
 "score_baseline": 89,
 "dependencies": {
 "validators": ["verify-constraints.sh", "eslint-validator.js"],
 "norms": ["harness-norms-v3.0.md", "10-SDD-CONSTRAINTS.md"],
 "templates": ["skill-template.md"]
 },
 "dependents": ["all phase-1 to phase-5 artifacts"],
 "norms_priority": {
 "execution_order": ["C4", "C3", "C7", "C5", "C8"],
 "blocking_constraints": ["C4", "C3"],
 "rationale": "Pre-flight validation must confirm tenant isolation and security before any module execution"
 },
 "interactions": {
 "with_validation": "Provides baseline checks consumed by orchestrator-engine.sh",
 "with_config": "References norms-matrix.json for constraint routing logic",
 "with_programming": "NO interaction with postgresql-pgvector/ due to LANGUAGE LOCK"
 }
 },
 {
 "artifact_id": "js-tenant-context-provider",
 "file": "js-tenant-context-provider.ts.md",
 "canonical_path": "06-PROGRAMMING/javascript/js-tenant-context-provider.ts.md",
 "constraints_mapped": ["C3","C4","C5","C7","C8"],
 "examples_count": 12,
 "score_baseline": 92,
 "dependencies": {
 "validators": ["verify-constraints.sh", "audit-secrets.sh", "tsc-strict-check.sh"],
 "norms": ["harness-norms-v3.0.md#C4", "06-MULTITENANCY-RULES.md"],
 "security_refs": ["03-SECURITY-RULES.md"]
 },
 "dependents": ["js-fetch-with-tenant-enforcement", "js-graphql-tenant-directives", "js-redux-tenant-middleware"],
 "norms_priority": {
 "execution_order": ["C4", "C8", "C3", "C7", "C5"],
 "blocking_constraints": ["C4"],
 "rationale": "Context provider is the enforcement mechanism for C4 in frontend; must be validated first"
 },
 "interactions": {
 "with_validation": "tsc-strict-check.sh validates tenant_id type propagation in TypeScript interfaces",
 "with_config": "Aligns with multi-tenant rules in 06-MULTITENANCY-RULES.md",
 "with_programming": "Context patterns consumed by application components before API calls"
 }
 },
 {
 "artifact_id": "js-secrets-frontend-handling",
 "file": "js-secrets-frontend-handling.js.md",
 "canonical_path": "06-PROGRAMMING/javascript/js-secrets-frontend-handling.js.md",
 "constraints_mapped": ["C3","C5","C7"],
 "examples_count": 10,
 "score_baseline": 90,
 "dependencies": {
 "validators": ["audit-secrets.sh", "verify-constraints.sh"],
 "norms": ["harness-norms-v3.0.md#C3"],
 "templates": [".env.example", "vite.config.ts"]
 },
 "dependents": ["js-tenant-context-provider", "js-fetch-with-tenant-enforcement"],
 "norms_priority": {
 "execution_order": ["C3", "C7", "C5"],
 "blocking_constraints": ["C3"],
 "rationale": "Secrets handling is security-critical; must pass before structural checks"
 },
 "interactions": {
 "with_validation": "audit-secrets.sh validates zero hardcode secrets in examples",
 "with_config": "References .env.example for VITE_ placeholder patterns",
 "with_programming": "Secrets patterns consumed by application config loading at build time"
 }
 },
 {
 "artifact_id": "js-fetch-with-tenant-enforcement",
 "file": "js-fetch-with-tenant-enforcement.ts.md",
 "canonical_path": "06-PROGRAMMING/javascript/js-fetch-with-tenant-enforcement.ts.md",
 "constraints_mapped": ["C3","C4","C8"],
 "examples_count": 14,
 "score_baseline": 93,
 "dependencies": {
 "validators": ["verify-constraints.sh", "eslint-validator.js"],
 "norms": ["harness-norms-v3.0.md#C4"],
 "templates": ["skill-template.md"]
 },
 "dependents": ["js-graphql-tenant-directives", "js-websocket-tenant-isolation", "js-api-error-handling-strategies"],
 "norms_priority": {
 "execution_order": ["C4", "C3", "C8"],
 "blocking_constraints": ["C4"],
 "rationale": "API calls are the primary attack surface; tenant enforcement in headers is non-negotiable"
 },
 "interactions": {
 "with_validation": "verify-constraints.sh validates X-Tenant-ID header injection in all fetch examples",
 "with_config": "Parametrization patterns align with axios interceptors best practices",
 "with_programming": "Core fetch wrapper consumed by application service layer"
 }
 }
 ],
 "dependency_graph": {
 "validation_layer": {
 "orchestrator-engine.sh": ["all artifacts"],
 "verify-constraints.sh": ["all artifacts"],
 "audit-secrets.sh": ["js-secrets-frontend-handling", "js-tenant-context-provider", "javascript-typescript-master-agent"],
 "eslint-validator.js": ["js-hardening-verification", "js-fetch-with-tenant-enforcement", "javascript-typescript-master-agent"],
 "tsc-strict-check.sh": ["ts-strict-mode-enforcement", "js-tenant-context-provider", "javascript-typescript-master-agent"]
 },
 "norms_layer": {
 "harness-norms-v3.0.md": ["all artifacts"],
 "10-SDD-CONSTRAINTS.md": ["all artifacts"],
 "language-lock-protocol.md": ["all artifacts"],
 "06-MULTITENANCY-RULES.md": ["js-tenant-context-provider", "js-fetch-with-tenant-enforcement", "js-rbac-hooks-patterns"],
 "norms-matrix.json": ["all artifacts", "javascript-typescript-master-agent"]
 },
 "config_layer": {
 "skill-template.md": ["all artifacts"],
 ".env.example": ["js-secrets-frontend-handling", "js-tenant-context-provider"],
 "tsconfig.json": ["ts-strict-mode-enforcement", "js-type-safety-contract-tests"],
 "eslint.config.js": ["js-hardening-verification", "javascript-typescript-master-agent"]
 }
 },
 "norms_execution_priority": {
 "global_order": ["C4", "C3", "C7", "C5", "C8", "C1", "C2", "C6"],
 "rationale": "C4 (tenant isolation) is foundational; security (C3) and path safety (C7) precede structural (C5) and observability (C8) checks",
 "blocking_set": ["C3", "C4", "C7"],
 "non_blocking_set": ["C1", "C2", "C5", "C6", "C8"],
 "selective_v_logic": {
 "applies_to": "postgresql-pgvector/ ONLY",
 "trigger": "artifact_type == 'skill_pgvector' AND content has pgvector operators",
 "exclusion": "javascript/ ALWAYS excludes V1/V2/V3 per LANGUAGE LOCK"
 }
 },
 "language_lock_enforcement": {
 "folder": "06-PROGRAMMING/javascript/",
 "prohibited_patterns": ["from ['\"]pgvector['\"]", "cosine_distance", "l2_distance", "hamming_distance", "vector\\(", "<->[^a-zA-Z]", "<#>[^a-zA-Z]"],
 "required_artifact_types": ["javascript_module", "typescript_module", "javascript_pattern", "typescript_pattern", "frontend_component"],
 "prohibited_constraints": ["V1", "V2", "V3"],
 "validation_script": "validate-skill-integrity.sh --check-language-lock",
 "failure_action": "exit 2 with message 'LANGUAGE LOCK VIOLATION: pgvector imports/operators not allowed in JavaScript/TypeScript domain'"
 },
 "ai_navigation_hints": {
 "for_generation": "Read javascript-typescript-master-agent.md AND this index BEFORE generating new JS/TS artifacts",
 "for_validation": "Use norms_execution_priority to order constraint checks; validate C4 before allowing API calls in examples",
 "for_migration": "Consult dependency_graph before modifying shared patterns; type changes may require downstream updates",
 "for_debugging": "Check language_lock_enforcement if pgvector operators appear in javascript/ artifacts",
 "for_master_agent": "Agent must consult norms-matrix.json before declaring constraints; emit JSON to stdout, logs to stderr, JSONL to 08-LOGS/; delegate vector/SQL/backend logic to appropriate domains"
 }
}
```

---

## 🔗 RAW_URLS_INDEX – Patrones JavaScript/TypeScript Disponibles

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
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/eslint-validator.js
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/tsc-strict-check.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json
```

### 💻 Patrones JavaScript/TypeScript Core (06-PROGRAMMING/javascript)
```text
# Índice y Agente Master
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/javascript-typescript-master-agent.md

# Fase 0: Core Hardening
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/js-hardening-verification.js.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/ts-strict-mode-enforcement.ts.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/js-error-boundaries-patterns.js.md

# Fase 1: Multi-Tenant Security
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/js-tenant-context-provider.ts.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/js-rbac-hooks-patterns.ts.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/js-secrets-frontend-handling.js.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/js-audit-logging-frontend.ts.md

# Fase 2: API Integration & Data Fetching
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/js-fetch-with-tenant-enforcement.ts.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/js-graphql-tenant-directives.ts.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/js-websocket-tenant-isolation.ts.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/js-api-error-handling-strategies.ts.md

# Fase 3: State Management & Reactivity
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/js-redux-tenant-middleware.ts.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/js-vue-composables-tenant-scoped.ts.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/js-react-query-tenant-keys.ts.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/js-state-persistence-encryption.ts.md

# Fase 4: MCP/IA Tooling
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/js-mcp-client-implementation.ts.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/js-ia-response-validation-gate.ts.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/js-streaming-ia-with-tenant.ts.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/js-prompt-injection-defense.ts.md

# Fase 5: Testing & Validation
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/js-vitest-tenant-isolation.ts.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/js-e2e-tenant-scenario-tests.ts.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/js-type-safety-contract-tests.ts.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/js-security-fuzzing-frontend.js.md
```

### 🔗 Referencias de Dominios Hermanos (Para Delegación)
```text
# SQL puro (delegar queries sin vectores)
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/crud-with-tenant-enforcement.sql.md

# Python (delegar lógica de backend)
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/python-sqlalchemy-tenant-enforcement.py.md

# pgvector/RAG (delegar operaciones vectoriales)
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md

# YAML/JSON Schema (delegar definiciones de config)
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/yaml-json-schema/00-INDEX.md
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
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/eslint-validator/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/tsc-strict-check/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/programming/javascript/javascript-typescript-master-agent/README.md
```

---

## 🗂️ RUTAS CANÓNICAS LOCALES – Patrones JavaScript/TypeScript (Para Acceso en Repo)

> **Formato**: `RAW_URL` → `./ruta/local/en/repo`

### 💻 Patrones JavaScript/TypeScript Core
```text
# Índice y Agente Master
06-PROGRAMMING/javascript/00-INDEX.md
06-PROGRAMMING/javascript/javascript-typescript-master-agent.md

# Fase 0: Core Hardening
06-PROGRAMMING/javascript/js-hardening-verification.js.md
06-PROGRAMMING/javascript/ts-strict-mode-enforcement.ts.md
06-PROGRAMMING/javascript/js-error-boundaries-patterns.js.md

# Fase 1: Multi-Tenant Security
06-PROGRAMMING/javascript/js-tenant-context-provider.ts.md
06-PROGRAMMING/javascript/js-rbac-hooks-patterns.ts.md
06-PROGRAMMING/javascript/js-secrets-frontend-handling.js.md
06-PROGRAMMING/javascript/js-audit-logging-frontend.ts.md

# Fase 2: API Integration & Data Fetching
06-PROGRAMMING/javascript/js-fetch-with-tenant-enforcement.ts.md
06-PROGRAMMING/javascript/js-graphql-tenant-directives.ts.md
06-PROGRAMMING/javascript/js-websocket-tenant-isolation.ts.md
06-PROGRAMMING/javascript/js-api-error-handling-strategies.ts.md

# Fase 3: State Management & Reactivity
06-PROGRAMMING/javascript/js-redux-tenant-middleware.ts.md
06-PROGRAMMING/javascript/js-vue-composables-tenant-scoped.ts.md
06-PROGRAMMING/javascript/js-react-query-tenant-keys.ts.md
06-PROGRAMMING/javascript/js-state-persistence-encryption.ts.md

# Fase 4: MCP/IA Tooling
06-PROGRAMMING/javascript/js-mcp-client-implementation.ts.md
06-PROGRAMMING/javascript/js-ia-response-validation-gate.ts.md
06-PROGRAMMING/javascript/js-streaming-ia-with-tenant.ts.md
06-PROGRAMMING/javascript/js-prompt-injection-defense.ts.md

# Fase 5: Testing & Validation
06-PROGRAMMING/javascript/js-vitest-tenant-isolation.ts.md
06-PROGRAMMING/javascript/js-e2e-tenant-scenario-tests.ts.md
06-PROGRAMMING/javascript/js-type-safety-contract-tests.ts.md
06-PROGRAMMING/javascript/js-security-fuzzing-frontend.js.md
```

### 🔗 Referencias de Dominios Hermanos (Para Delegación)
```text
# SQL puro
06-PROGRAMMING/sql/00-INDEX.md
06-PROGRAMMING/sql/crud-with-tenant-enforcement.sql.md

# Python
06-PROGRAMMING/python/00-INDEX.md
06-PROGRAMMING/python/python-sqlalchemy-tenant-enforcement.py.md

# pgvector/RAG
06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md

# YAML/JSON Schema
06-PROGRAMMING/yaml-json-schema/00-INDEX.md
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
docs/pt-BR/validation-tools/eslint-validator/README.md
docs/pt-BR/validation-tools/tsc-strict-check/README.md
docs/pt-BR/programming/javascript/javascript-typescript-master-agent/README.md
```

---

## 🧭 GUÍA DE USO PARA EL AGENTE JAVASCRIPT/TYPESCRIPT

```typescript
// Pseudocódigo: Cómo consultar patrones disponibles en JS/TS
// (Implementado en el agente, no en TS puro para evitar circularidad)

interface PatternReference {
  raw_url: string;
  canonical_path: string;
  domain: string;
  language_lock: string[];
  constraints_default: string[];
  vector_ops_allowed: boolean; // 🔑 Flag crítico para routing
}

function consultarPatronJS(nombrePatron: string): PatternReference {
  const baseRaw = "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/";
  const baseLocal = "./06-PROGRAMMING/javascript/";
  
  const isMaster = nombrePatron === "javascript-typescript-master-agent";
  const extension = isMaster ? ".md" : (nombrePatron.includes("ts") ? ".ts.md" : ".js.md");
  const filename = `${nombrePatron}${extension}`;
  
  return {
    raw_url: `${baseRaw}06-PROGRAMMING/javascript/${filename}`,
    canonical_path: `${baseLocal}${filename}`,
    domain: "06-PROGRAMMING/javascript/",
    language_lock: ["javascript", "typescript", "nodejs", "react", "vue"],
    constraints_default: ["C3", "C4", "C5"], // Mínimo para producción
    vector_ops_allowed: false, // 🔒 CERO operadores de pgvector en este dominio
  };
}

// Validación de constraints antes de emitir módulo
function validarConstraintsJS(artifactPath: string): string[] {
  const fm = extractFrontmatter(artifactPath);
  const declared = fm.constraints_mapped || [];
  const content = loadFile(artifactPath);
  const matrix = loadJSON("./05-CONFIGURATIONS/validation/norms-matrix.json");
  const allowed = getAllowedConstraints(matrix, artifactPath);
  
  const issues: string[] = [];
  
  // Verificar constraints declarados vs permitidos
  for (const c of declared) {
    if (!allowed.includes(c)) {
      issues.push(`constraint '${c}' not allowed for path ${artifactPath}`);
    }
  }
  
  // C4: Validar que hay tenant_id en API calls o context usage
  if (content.includes("fetch(") || content.includes("axios.") || content.includes("graphql")) {
    if (!content.includes("tenant_id") && !content.includes("X-Tenant-ID")) {
      issues.push("C4 missing: API call lacks tenant_id propagation (header or param)");
    }
  }
  
  // C3: Zero hardcode secrets
  if (/API_KEY\s*=\s*['"][^'"]+['"]|password\s*:\s*['"][^'"]+['"]/.test(content)) {
    issues.push("C3 violation: hardcoded secret detected");
  }
  
  return issues;
}

// Detección de LANGUAGE LOCK: operadores vectoriales prohibidos
function contieneOperadoresVectoriales(code: string): boolean {
  return /from\s+['"]pgvector['"]|cosine_distance|l2_distance|hamming_distance|vector\(\d+\)|<->[^a-zA-Z]|<#>[^a-zA-Z]/.test(code);
}

// Delegación por dominio según LANGUAGE LOCK
function delegarPorDominio(query: string, context: Record<string, unknown>): string {
  if (contieneOperadoresVectoriales(query)) {
    // 🔄 Delegar a postgresql-pgvector/
    console.error("LANGUAGE LOCK: Vector operators not allowed in JS/TS domain. Use postgresql-pgvector/");
    return delegarADominio("06-PROGRAMMING/postgresql-pgvector/", query, context);
  } else if (esQuerySQLPura(query)) {
    // 🔄 Delegar a sql/
    return delegarADominio("06-PROGRAMMING/sql/", query, context);
  } else if (esLogicaBackendPesada(query)) {
    // 🔄 Delegar a python/
    return delegarADominio("06-PROGRAMMING/python/", query, context);
  } else {
    // ✅ Permitido: generar código JS/TS estándar con tenant isolation
    return generarModuloJS(query, context);
  }
}

// Ejemplo de uso en el agente:
const pattern = consultarPatronJS("js-fetch-with-tenant-enforcement");
const issues = validarConstraintsJS(pattern.canonical_path);
if (issues.length > 0) {
  console.error("Validation failed:", issues);
  process.exit(1);
}
// Generar módulo seguro...
```

---

## 📋 INSTRUCCIONES DE INTEGRACIÓN (Actualizadas)

### Paso 1: Agregar al final del agente
Pegar los bloques de referencias justo antes de la sección `## Limitations` en:
- `06-PROGRAMMING/javascript/javascript-typescript-master-agent.md`

### Paso 2: Actualizar el comportamiento del agente
En la sección `## Comportamiento del Agente` o `## Behavioral Traits`, agregar:

```markdown
| Trait | Implementación contractual |
|-------|---------------------------|
| **Consulta patrones antes de generar** | Antes de emitir módulo JS/TS, el agente debe consultar la lista de patrones disponibles en `06-PROGRAMMING/javascript/` para asegurar coherencia con el repositorio |
| **Acceso dual** | Usar ruta canónica (`./06-PROGRAMMING/javascript/...`) para acceso local, o raw URL para acceso remoto si el archivo no existe localmente |
| **LANGUAGE LOCK automático** | Si el usuario solicita operadores vectoriales (`from 'pgvector'`, `cosine_distance`, `<->`), el agente debe delegar a `06-PROGRAMMING/postgresql-pgvector/` y NO generar código con vectores en su dominio |
| **Type safety primero** | Priorizar TypeScript con `strict: true` para contracts de API; incluir validación de tenant_id en interfaces y types |
| **Enseña mientras genera** | Incluir JSDoc/TSDoc explicativos y comentarios sobre tenant isolation en los módulos generados |
| **Valida constraints antes de emitir** | Ejecutar `validarConstraintsJS()` antes de emitir cualquier artifact para asegurar coherencia con `norms-matrix.json` |
| **Emite logs estructurados** | JSON a `stdout`, logs humanos a `stderr`, JSONL a `08-LOGS/validation/...` per V-INT-03 y V-LOG-02 |
```

### Paso 3: Validar con `verify-constraints.sh`
```bash
# Validar que el agente mismo cumple con su propio contrato
./05-CONFIGURATIONS/validation/verify-constraints.sh --file 06-PROGRAMMING/javascript/javascript-typescript-master-agent.md | jq

# Validación adicional con linters específicos
./05-CONFIGURATIONS/validation/eslint-validator.js --file 06-PROGRAMMING/javascript/javascript-typescript-master-agent.md
./05-CONFIGURATIONS/validation/tsc-strict-check.sh --file 06-PROGRAMMING/javascript/javascript-typescript-master-agent.md
```

---

> 📌 **Nota final**: Este índice es Tier 1 (referencia contractual). Cualquier modificación debe pasar validación automática antes de merge.  
> 🇧🇷 *Documentação técnica completa disponível em*: `docs/pt-BR/programming/javascript/00-INDEX/README.md` (próxima entrega).
```

---
