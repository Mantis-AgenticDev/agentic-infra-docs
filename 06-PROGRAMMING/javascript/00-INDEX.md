---
artifact_id: "00-INDEX-javascript"
artifact_type: "skill_index"
version: "3.2.0-MODULAR-MERGED"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/javascript/00-INDEX.md --json"
canonical_path: "06-PROGRAMMING/javascript/00-INDEX.md"
tier: 1
mode_selected: "B1"
prompt_hash: "sha256:index-stackselector-v3.2.0-merged"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "required"
language: pt-BR
domain: "javascript-typescript"
ai_navigation:
  read_first: true
  required_for: ["javascript-artifact-generation", "stackselector-hydration", "tdd-validation", "sdd-contract-enforcement"]
  update_frequency: monthly
  compatible_models: ["qwen", "deepseek", "claude", "minimax", "mimo-xiaomi", "gpt-4", "gemini"]
audience: ["javascript-typescript-master-agent", "orchestrator-engine", "validation-hooks", "senior-engineers", "ai-agents"]
status: "✅ Estável"
next_review: "2026-06-09"
license: "CC-BY-NC-SA-4.0"
observability:
  log_schema: "V-LOG-02"
  required_fields: ["ts", "level", "resource.tenant_id", "body.event", "attributes.mantis.constraint"]
  output_channels: { stdout: "json", stderr: "human-readable", jsonl_dir: "08-LOGS/validation/js-index/" }
---

# JavaScript/TypeScript Patterns Master Index – Multi-Tenant Hardening & AI Integration

## 👤 Propósito y Alcance
Índice canónico de navegación para `06-PROGRAMMING/javascript/`. Documenta 30 artifacts auditados bajo HARNESS NORMS v3.2.0-MODULAR-MERGED, mapea flujos de ejecución para desarrollo full-stack con aislamiento multi-tenant, referencia al **agente master de generación JavaScript/TypeScript**, y proporciona un árbol JSON enriquecido para routing de agentes LLM y pipelines CI/CD.

> 🔑 **Diferenciador crítico**: Este dominio cubre tanto JavaScript (ES2022+) como TypeScript (5.x) con enfoque en:
> - Type safety con TypeScript para validación estática de contracts multi-tenant
> - Runtime checks para JavaScript con validación de tenant_id en tiempo de ejecución
> - Integración segura con backends (SQL, pgvector, Python) respetando LANGUAGE LOCK
> - Observabilidad nativa: todo artefacto debe emitir logs JSONL V-LOG-02 vía `mantis_log()`

---

## 🤖 Agente de Generación Disponible

| Agente | Canonical Path | Dominio | Constraints Soportados | Hooks de Validación | Observability |
|--------|---------------|---------|----------------------|-------------------|--------------|
| **`javascript-typescript-master-agent`** ✅ | `[[06-PROGRAMMING/javascript/javascript-typescript-master-agent.md]]` | `javascript,typescript,nodejs,react,vue` | `C1,C2,C3,C4,C5,C6,C7,C8` | `verify-constraints.sh`, `audit-secrets.sh`, `eslint-validator.js`, `tsc-strict-check.sh`, `verify-observability.sh` | `mantis_log()` + JSONL V-LOG-02 |

> ⚠️ **Nota contractual**: Este agente es Tier 1 (referencia educativa). Cualquier módulo generado debe pasar validación automática antes de merge. Zero documentación en `docs/` conforme instrucción del proyecto.

---

## 📂 Mapeo de Fases y Wikilinks

### FASE 0 – Core Hardening (Pre-flight & Type Safety)
| Artifact | Constraints | Propósito | Observability |
|----------|-------------|-----------|--------------|
| `[[js-hardening-verification.js.md]]` | C3,C4,C5,C7,C8 | Validación de entorno Node.js, límites de recursos y type-checking pre-ejecución | `mantis_log('INFO', 'hardening_check', {node_version, resource_limits})` |
| `[[ts-strict-mode-enforcement.ts.md]]` | C4,C5,C7,C8 | Configuración `tsconfig.json` con `strict: true`, `noImplicitAny`, `exactOptionalPropertyTypes` | `mantis_log('DEBUG', 'tsconfig_validated', {strict_mode: true})` |
| `[[js-error-boundaries-patterns.js.md]]` | C4,C5,C7,C8 | Error boundaries en React/Vue con logging estructurado y recuperación segura | `mantis_log('ERROR', 'boundary_caught', {error_name, tenant_id})` |

### FASE 1 – Multi-Tenant Security (Aislamiento en Frontend/Backend)
| Artifact | Constraints | Propósito | Observability |
|----------|-------------|-----------|--------------|
| `[[js-tenant-context-provider.ts.md]]` | C3,C4,C5,C7,C8 | Context API/Pinia store para inyección segura de `tenant_id` en toda la app | `mantis_log('INFO', 'tenant_context_set', {tenant_id})` |
| `[[js-rbac-hooks-patterns.ts.md]]` | C3,C4,C8 | Custom hooks para validación de permisos RBAC por tenant en componentes | `mantis_log('WARN', 'rbac_denied', {user_role, required_permission})` |
| `[[js-secrets-frontend-handling.js.md]]` | C3,C5,C7 | Gestión de secrets en frontend: zero hardcode, env vars via Vite/Webpack, vault integration | `mantis_log('DEBUG', 'secret_accessed', {var_name: '***REDACTED***'})` |
| `[[js-audit-logging-frontend.ts.md]]` | C4,C5,C8 | Logging estructurado JSON en frontend con trazabilidad por tenant y correlación de requests | `mantis_log('INFO', 'audit_event', {action, resource, tenant_id})` |

### FASE 2 – API Integration & Data Fetching
| Artifact | Constraints | Propósito | Observability |
|----------|-------------|-----------|--------------|
| `[[js-fetch-with-tenant-enforcement.ts.md]]` | C3,C4,C8 | Wrapper de `fetch`/`axios` que inyecta automáticamente `X-Tenant-ID` y valida respuestas | `mantis_log('INFO', 'api_call', {endpoint, method, tenant_id, status_code})` |
| `[[js-graphql-tenant-directives.ts.md]]` | C4,C5,C8 | Directivas GraphQL `@tenantScoped` para validación automática en queries/mutations | `mantis_log('DEBUG', 'graphql_query', {operation_name, tenant_scoped: true})` |
| `[[js-websocket-tenant-isolation.ts.md]]` | C4,C7,C8 | Conexiones WebSocket con scope de tenant y reconexión segura con re-auth | `mantis_log('INFO', 'ws_connected', {tenant_id, session_id})` |
| `[[js-api-error-handling-strategies.ts.md]]` | C4,C5,C7,C8 | Estrategias unificadas para manejo de errores 401/403/409 con retry lógico por tenant | `mantis_log('ERROR', 'api_error', {status_code, retry_count, tenant_id})` |

### FASE 3 – State Management & Reactivity
| Artifact | Constraints | Propósito | Observability |
|----------|-------------|-----------|--------------|
| `[[js-redux-tenant-middleware.ts.md]]` | C4,C5,C8 | Middleware de Redux que filtra acciones por tenant_id y previene cross-tenant state leakage | `mantis_log('DEBUG', 'redux_action_filtered', {action_type, tenant_match: true})` |
| `[[js-vue-composables-tenant-scoped.ts.md]]` | C4,C5,C8 | Composables de Vue 3 con scope implícito de tenant para reactividad segura | `mantis_log('INFO', 'composable_executed', {composable_name, tenant_id})` |
| `[[js-react-query-tenant-keys.ts.md]]` | C4,C7,C8 | Query keys de React Query con tenant_id para cache isolation y invalidación granular | `mantis_log('DEBUG', 'query_cached', {query_key, tenant_id, ttl})` |
| `[[js-state-persistence-encryption.ts.md]]` | C3,C4,C7 | Persistencia de estado en localStorage/IndexedDB con encriptación por tenant | `mantis_log('INFO', 'state_persisted', {storage_type, encrypted: true})` |

### FASE 4 – MCP/IA Tooling (Integración con Agentes)
| Artifact | Constraints | Propósito | Observability |
|----------|-------------|-----------|--------------|
| `[[js-mcp-client-implementation.ts.md]]` | C3,C4,C8 | Cliente MCP en JS/TS con inyección automática de contexto de tenant en tool calls | `mantis_log('INFO', 'mcp_tool_call', {tool_name, tenant_context_injected: true})` |
| `[[js-ia-response-validation-gate.ts.md]]` | C3,C4,C5,C8 | Gate de validación para respuestas de LLM: schema validation, tenant scoping, content filtering | `mantis_log('WARN', 'ia_response_filtered', {reason, tenant_id})` |
| `[[js-streaming-ia-with-tenant.ts.md]]` | C4,C7,C8 | Streaming de respuestas IA con chunk validation y cancellation por tenant | `mantis_log('DEBUG', 'stream_chunk', {chunk_size, tenant_id, sequence_num})` |
| `[[js-prompt-injection-defense.ts.md]]` | C3,C4,C7 | Patrones de defensa contra prompt injection en inputs de usuario con sanitización por contexto | `mantis_log('WARN', 'prompt_sanitized', {input_hash, sanitization_rules_applied})` |

### FASE 5 – Testing & Validation
| Artifact | Constraints | Propósito | Observability |
|----------|-------------|-----------|--------------|
| `[[js-vitest-tenant-isolation.ts.md]]` | C4,C5,C8 | Fixtures de Vitest/Jest con aislamiento de tenant y mocks de API tenant-scoped | `mantis_log('INFO', 'test_executed', {test_name, tenant_isolated: true})` |
| `[[js-e2e-tenant-scenario-tests.ts.md]]` | C3,C4,C7 | Tests E2E con Playwright/Cypress que simulan flujos multi-tenant completos | `mantis_log('INFO', 'e2e_scenario', {scenario_name, tenants_tested})` |
| `[[js-type-safety-contract-tests.ts.md]]` | C4,C5,C8 | Tests de contratos TypeScript: validación de interfaces API con `zod`/`io-ts` por tenant | `mantis_log('DEBUG', 'contract_validated', {interface_name, tenant_scoped: true})` |
| `[[js-security-fuzzing-frontend.js.md]]` | C3,C7,C8 | Fuzzing de inputs frontend con detección de XSS, CSRF y tenant leakage | `mantis_log('WARN', 'fuzz_input_rejected', {attack_type, input_hash})` |

### 📦 Artefactos Core del Dominio (Base de Hardening)
| Artifact | Constraints | Propósito | Observability |
|----------|-------------|-----------|--------------|
| `[[00-INDEX.md]]` | C1-C8 | Índice canónico con stackselector JSON para hidratación segmentada | `mantis_log('INFO', 'index_loaded', {artifacts_count: 30})` |
| `[[javascript-typescript-master-agent.md]]` | C1-C8 | Master Agent con función `mantis_log()` canónica y bootstrap resiliente | `mantis_log('DEBUG', 'master_agent_invoked', {prompt_hash})` |
| `[[async-patterns-with-timeouts.ts.md]]` | C1,C7,C8 | Patrones de async/await con AbortController y timeouts configurables | `mantis_log('INFO', 'async_operation', {operation_name, timeout_ms})` |
| `[[authentication-authorization-patterns.ts.md]]` | C3,C4,C5,C8 | JWT/OAuth2 patterns con validación de tenant claims y refresh token rotation | `mantis_log('INFO', 'auth_validated', {user_id, tenant_id, token_type})` |
| `[[context-compaction-utils.ts.md]]` | C1,C8 | Utilidades para compactar contexto LLM sin perder trazas de tenant | `mantis_log('DEBUG', 'context_compacted', {original_tokens, compacted_tokens})` |
| `[[context-isolation-patterns.ts.md]]` | C4,C5,C8 | AsyncLocalStorage para aislamiento de contexto por request/tenant | `mantis_log('DEBUG', 'context_isolated', {tenant_id, request_id})` |
| `[[db-selection-decision-tree.ts.md]]` | C1,C4,C5 | Árbol de decisión para selección de DB por tenant (PostgreSQL, MySQL, SQLite) | `mantis_log('INFO', 'db_selected', {tenant_id, db_type, connection_pool})` |
| `[[dependency-management.ts.md]]` | C3,C5 | Gestión segura de dependencias: audit, lockfile validation, vulnerability scanning | `mantis_log('WARN', 'dependency_alert', {package_name, severity, cve_id})` |
| `[[filesystem-sandbox-sync.ts.md]]` | C3,C4,C7 | Operaciones de filesystem con sandboxing y sync/async modes con tenant isolation | `mantis_log('INFO', 'fs_operation', {operation, path_sanitized, tenant_id})` |
| `[[filesystem-sandboxing.ts.md]]` | C3,C4,C7 | Sandbox de filesystem con path resolution seguro y prefix validation por tenant | `mantis_log('DEBUG', 'sandbox_validated', {requested_path, resolved_path, tenant_prefix})` |
| `[[fix-sintaxis-code.ts.md]]` | C5,V1 | Utilidad para corrección de sintaxis con validación de constraints (V1 solo para referencia) | `mantis_log('INFO', 'syntax_fixed', {file_path, errors_corrected})` |
| `[[git-disaster-recovery.ts.md]]` | C5,C7 | Recuperación de desastres en Git: reset seguro, stash por tenant, branch protection | `mantis_log('WARN', 'git_recovery', {operation, branch, tenant_context})` |
| `[[hardening-verification.ts.md]]` | C3,C4,C5,C7,C8 | Verificación integral de hardening: secrets, tenant, type safety, observability | `mantis_log('INFO', 'hardening_verified', {checks_passed, checks_total})` |
| `[[langchainjs-integration.ts.md]]` | C4,C7,C8 | Integración con LangChain.js con inyección de tenant context en chains y agents | `mantis_log('DEBUG', 'langchain_executed', {chain_name, tenant_id, tokens_used})` |
| `[[n8n-webhook-handler.ts.md]]` | C3,C4,C7 | Handler de webhooks para n8n con validación de firma y tenant routing | `mantis_log('INFO', 'webhook_received', {workflow_id, tenant_id, signature_valid})` |
| `[[observability-opentelemetry.ts.md]]` | C8,V-LOG-02 | Integración con OpenTelemetry: spans con tenant.id, metrics, logs JSONL | `mantis_log('DEBUG', 'otel_span_created', {span_name, trace_id, tenant_id})` |
| `[[orchestrator-routing.ts.md]]` | C4,C7,C8 | Routing inteligente de requests a microservicios con tenant-aware load balancing | `mantis_log('INFO', 'request_routed', {endpoint, target_service, tenant_id, latency_ms})` |
| `[[robust-error-handling.ts.md]]` | C7,C8 | Manejo de errores con retry exponencial, circuit breaker y logging estructurado | `mantis_log('ERROR', 'error_handled', {error_type, retry_attempt, fallback_used})` |
| `[[scale-simulation-utils.ts.md]]` | C1,C7 | Utilidades para simular carga y escalado con métricas por tenant | `mantis_log('INFO', 'scale_simulation', {target_rps, tenants_simulated, duration_ms})` |
| `[[secrets-management-patterns.ts.md]]` | C3,C4 | Patrones de gestión de secrets: env vars, Vault integration, runtime injection | `mantis_log('DEBUG', 'secret_injected', {var_name: '***REDACTED***', source})` |
| `[[testing-multi-tenant-patterns.ts.md]]` | C4,C8 | Patrones de testing multi-tenant: fixtures, mocks, isolation validation | `mantis_log('INFO', 'test_isolation_verified', {tenant_count, cross_tenant_leaks: 0})` |
| `[[type-safety-with-typescript.ts.md]]` | C5,V1 | Type safety avanzado: branded types, discriminated unions, zod validation | `mantis_log('DEBUG', 'type_validated', {type_name, validation_passed: true})` |
| `[[vertical-db-schemas.ts.md]]` | C4,C5 | Esquemas de DB verticales por tenant: migration strategies, schema isolation | `mantis_log('INFO', 'schema_applied', {tenant_id, schema_version, migration_status})` |
| `[[webhook-validation-patterns.ts.md]]` | C3,C4,C7 | Validación de webhooks: signature verification, replay attack prevention, tenant scoping | `mantis_log('WARN', 'webhook_rejected', {reason, signature_valid, tenant_match})` |
| `[[whatsapp-bot-integration.ts.md]]` | C3,C4,C7,C8 | Integración con WhatsApp Bot: message routing, tenant context, rate limiting | `mantis_log('INFO', 'whatsapp_message', {phone_hash, tenant_id, message_type})` |
| `[[yaml-frontmatter-parser.ts.md]]` | C5,C8 | Parser de frontmatter YAML con validación de schema y logging de errores | `mantis_log('DEBUG', 'frontmatter_parsed', {artifact_id, constraints_count, validation_errors})` |

---

## 🔗 Interacciones con el Repositorio
- **`05-CONFIGURATIONS/validation/`**: Todos los artifacts son validados por `orchestrator-engine.sh`. Los scripts `verify-constraints.sh`, `eslint-validator.js`, `tsc-strict-check.sh` y `verify-observability.sh` consumen el JSON de este índice.
- **`01-RULES/`**: Las normas `harness-norms-v3.0.md`, `language-lock-protocol.md` y `06-MULTITENANCY-RULES.md` definen los constraints C1-C8 aplicados.
- **`06-PROGRAMMING/postgresql-pgvector/`**: Carpeta hermana con LANGUAGE LOCK estricto. **Delegación obligatoria**: queries vectoriales deben generarse en `postgresql-pgvector/`, no aquí.
- **`06-PROGRAMMING/python/`**: Para lógica de backend pesada o embedding generation, usar `python/` y consumir via API desde este dominio.
- **`06-PROGRAMMING/sql/`**: Para queries SQL puras (sin vectores), delegar a `sql/` y consumir via ORM o query builder desde JS/TS.
- **`08-LOGS/`**: Los handlers de logging estructurado (C8) en frontend/backend alimentan dashboards y generan entradas en `failed-attempts/` si fallan validaciones de tenant isolation. **Formato obligatorio**: JSONL V-LOG-02.
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
• Observability: todo artefacto debe usar mantis_log() canónica con schema V-LOG-02
```

---

## 🤖 JSON TREE ENRIQUECIDO PARA IA (Stackselector v3.2.0 - 30 Artefactos como REAL)

```json
{
  "index_metadata": {
    "artifact_id": "00-INDEX-javascript",
    "artifact_type": "skill_index",
    "version": "3.2.0-MODULAR-MERGED",
    "canonical_path": "06-PROGRAMMING/javascript/00-INDEX.md",
    "language_lock_status": "enforced",
    "vector_constraints_applied": false,
    "generated_timestamp": "2026-05-09T00:00:00Z",
    "master_agent": "javascript-typescript-master-agent",
    "observability_schema": "V-LOG-02",
    "total_artifacts": 30,
    "all_artifacts_status": "real"
  },
  "artifacts": [
    {
      "artifact_id": "00-INDEX-javascript",
      "file": "00-INDEX.md",
      "canonical_path": "06-PROGRAMMING/javascript/00-INDEX.md",
      "artifact_type": "skill_index",
      "tier": 1,
      "status": "real",
      "constraints_mapped": ["C1","C2","C3","C4","C5","C6","C7","C8"],
      "language_lock": ["javascript","typescript","nodejs","react","vue"],
      "validation_hooks": ["verify-constraints.sh", "orchestrator-engine.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "orchestrator-engine.sh"],
        "norms": ["harness-norms-v3.0.md", "10-SDD-CONSTRAINTS.md", "language-lock-protocol.md"],
        "config": ["norms-matrix.json", "template_artifacts.md"]
      },
      "dependents": ["all javascript/typescript artifacts"],
      "norms_priority": {
        "execution_order": ["C4", "C3", "C7", "C5", "C8", "C1", "C2", "C6"],
        "blocking_constraints": ["C3", "C4"],
        "rationale": "Tenant isolation (C4) and secrets (C3) are foundational for JS/TS generation"
      },
      "hydration_weight": "light",
      "entrypoint_function": "load_stackselector",
      "tenant_context_required": false,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["index_loaded", "artifact_selected", "validation_started"],
        "output_format": "jsonl"
      }
    },
    {
      "artifact_id": "javascript-typescript-master-agent",
      "file": "javascript-typescript-master-agent.md",
      "canonical_path": "06-PROGRAMMING/javascript/javascript-typescript-master-agent.md",
      "artifact_type": "agentic_skill_definition",
      "tier": 1,
      "status": "real",
      "constraints_mapped": ["C1","C2","C3","C4","C5","C6","C7","C8"],
      "language_lock": ["javascript","typescript","nodejs","react","vue"],
      "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "eslint-validator.js", "tsc-strict-check.sh", "verify-observability.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "audit-secrets.sh", "eslint-validator.js", "tsc-strict-check.sh", "verify-observability.sh"],
        "norms": ["harness-norms-v3.0.md", "10-SDD-CONSTRAINTS.md", "language-lock-protocol.md", "06-MULTITENANCY-RULES.md"],
        "config": ["norms-matrix.json", "template_artifacts.md", "tsconfig.json", "eslint.config.js"]
      },
      "dependents": ["all javascript/typescript artifacts"],
      "norms_priority": {
        "execution_order": ["C4", "C3", "C7", "C5", "C8", "C1", "C2", "C6"],
        "blocking_constraints": ["C3", "C4"],
        "rationale": "Security (C3) and tenant isolation (C4) are foundational for module generation"
      },
      "hydration_weight": "heavy",
      "entrypoint_function": "mantis_log",
      "tenant_context_required": true,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["master_invoked", "artifact_generated", "validation_passed"],
        "output_format": "jsonl",
        "pii_scrubbing": true
      }
    },
    {
      "artifact_id": "async-patterns-with-timeouts",
      "file": "async-patterns-with-timeouts.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/async-patterns-with-timeouts.ts.md",
      "artifact_type": "typescript_pattern",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C1","C7","C8"],
      "language_lock": ["typescript","nodejs"],
      "validation_hooks": ["verify-constraints.sh", "tsc-strict-check.sh", "verify-observability.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "tsc-strict-check.sh"],
        "norms": ["harness-norms-v3.0.md#C7", "harness-norms-v3.0.md#C8"],
        "config": ["tsconfig.json"]
      },
      "dependents": ["robust-error-handling", "orchestrator-routing"],
      "norms_priority": {
        "execution_order": ["C7", "C8", "C1"],
        "blocking_constraints": ["C7"],
        "rationale": "Timeout handling is critical for resource management (C7)"
      },
      "hydration_weight": "light",
      "entrypoint_function": "withTimeout",
      "tenant_context_required": false,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["timeout_triggered", "async_completed"],
        "output_format": "jsonl"
      }
    },
    {
      "artifact_id": "authentication-authorization-patterns",
      "file": "authentication-authorization-patterns.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/authentication-authorization-patterns.ts.md",
      "artifact_type": "typescript_pattern",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C3","C4","C5","C8"],
      "language_lock": ["typescript","nodejs","react"],
      "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "tsc-strict-check.sh", "verify-observability.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "audit-secrets.sh", "tsc-strict-check.sh"],
        "norms": ["harness-norms-v3.0.md#C3", "06-MULTITENANCY-RULES.md"],
        "config": ["tsconfig.json", "jose-config.json"]
      },
      "dependents": ["js-tenant-context-provider", "js-fetch-with-tenant-enforcement"],
      "norms_priority": {
        "execution_order": ["C4", "C3", "C5", "C8"],
        "blocking_constraints": ["C3", "C4"],
        "rationale": "Auth patterns must enforce tenant isolation (C4) and zero secrets (C3)"
      },
      "hydration_weight": "medium",
      "entrypoint_function": "validateJWT",
      "tenant_context_required": true,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["auth_validated", "token_refreshed", "auth_denied"],
        "output_format": "jsonl",
        "pii_scrubbing": true
      }
    },
    {
      "artifact_id": "context-compaction-utils",
      "file": "context-compaction-utils.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/context-compaction-utils.ts.md",
      "artifact_type": "typescript_module",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C1","C8"],
      "language_lock": ["typescript","nodejs"],
      "validation_hooks": ["verify-constraints.sh", "tsc-strict-check.sh", "verify-observability.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "tsc-strict-check.sh"],
        "norms": ["harness-norms-v3.0.md#C1", "harness-norms-v3.0.md#C8"],
        "config": ["tsconfig.json"]
      },
      "dependents": ["javascript-typescript-master-agent", "orchestrator-routing"],
      "norms_priority": {
        "execution_order": ["C8", "C1"],
        "blocking_constraints": [],
        "rationale": "Context compaction is optimization (C1) with observability (C8)"
      },
      "hydration_weight": "light",
      "entrypoint_function": "compactContext",
      "tenant_context_required": false,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["context_compacted", "tokens_saved"],
        "output_format": "jsonl"
      }
    },
    {
      "artifact_id": "context-isolation-patterns",
      "file": "context-isolation-patterns.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/context-isolation-patterns.ts.md",
      "artifact_type": "typescript_pattern",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C4","C5","C8"],
      "language_lock": ["typescript","nodejs"],
      "validation_hooks": ["verify-constraints.sh", "tsc-strict-check.sh", "check-rls.sh", "verify-observability.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "check-rls.sh", "tsc-strict-check.sh"],
        "norms": ["harness-norms-v3.0.md#C4", "06-MULTITENANCY-RULES.md"],
        "config": ["tsconfig.json"]
      },
      "dependents": ["js-tenant-context-provider", "secrets-management-patterns"],
      "norms_priority": {
        "execution_order": ["C4", "C8", "C5"],
        "blocking_constraints": ["C4"],
        "rationale": "Context isolation is foundational for multi-tenant (C4)"
      },
      "hydration_weight": "medium",
      "entrypoint_function": "withTenantContext",
      "tenant_context_required": true,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["context_isolated", "tenant_switched"],
        "output_format": "jsonl"
      }
    },
    {
      "artifact_id": "db-selection-decision-tree",
      "file": "db-selection-decision-tree.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/db-selection-decision-tree.ts.md",
      "artifact_type": "typescript_module",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C1","C4","C5"],
      "language_lock": ["typescript","nodejs"],
      "validation_hooks": ["verify-constraints.sh", "tsc-strict-check.sh", "check-rls.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "check-rls.sh"],
        "norms": ["harness-norms-v3.0.md#C4", "harness-norms-v3.0.md#C5"],
        "config": ["tsconfig.json", "db-config.json"]
      },
      "dependents": ["vertical-db-schemas", "orchestrator-routing"],
      "norms_priority": {
        "execution_order": ["C4", "C5", "C1"],
        "blocking_constraints": ["C4"],
        "rationale": "DB selection must respect tenant isolation (C4)"
      },
      "hydration_weight": "medium",
      "entrypoint_function": "selectDatabase",
      "tenant_context_required": true,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["db_selected", "connection_established"],
        "output_format": "jsonl"
      }
    },
    {
      "artifact_id": "dependency-management",
      "file": "dependency-management.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/dependency-management.ts.md",
      "artifact_type": "typescript_module",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C3","C5"],
      "language_lock": ["typescript","nodejs"],
      "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "tsc-strict-check.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "audit-secrets.sh"],
        "norms": ["harness-norms-v3.0.md#C3", "harness-norms-v3.0.md#C5"],
        "config": ["package.json.schema", "tsconfig.json"]
      },
      "dependents": ["all artifacts with external dependencies"],
      "norms_priority": {
        "execution_order": ["C3", "C5"],
        "blocking_constraints": ["C3"],
        "rationale": "Dependency security (C3) precedes type safety (C5)"
      },
      "hydration_weight": "light",
      "entrypoint_function": "validateDependencies",
      "tenant_context_required": false,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["dependency_validated", "vulnerability_detected"],
        "output_format": "jsonl"
      }
    },
    {
      "artifact_id": "filesystem-sandbox-sync",
      "file": "filesystem-sandbox-sync.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/filesystem-sandbox-sync.ts.md",
      "artifact_type": "typescript_module",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C3","C4","C7"],
      "language_lock": ["typescript","nodejs"],
      "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "check-rls.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "audit-secrets.sh"],
        "norms": ["harness-norms-v3.0.md#C3", "06-MULTITENANCY-RULES.md"],
        "config": ["fs-config.json"]
      },
      "dependents": ["filesystem-sandboxing", "yaml-frontmatter-parser"],
      "norms_priority": {
        "execution_order": ["C4", "C3", "C7"],
        "blocking_constraints": ["C3", "C4"],
        "rationale": "Filesystem access must be tenant-scoped (C4) and secret-safe (C3)"
      },
      "hydration_weight": "medium",
      "entrypoint_function": "safeReadFile",
      "tenant_context_required": true,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["file_accessed", "path_sanitized"],
        "output_format": "jsonl"
      }
    },
    {
      "artifact_id": "filesystem-sandboxing",
      "file": "filesystem-sandboxing.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/filesystem-sandboxing.ts.md",
      "artifact_type": "typescript_pattern",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C3","C4","C7"],
      "language_lock": ["typescript","nodejs"],
      "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "check-rls.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "audit-secrets.sh"],
        "norms": ["harness-norms-v3.0.md#C3", "06-MULTITENANCY-RULES.md"],
        "config": ["fs-config.json"]
      },
      "dependents": ["all artifacts with filesystem access"],
      "norms_priority": {
        "execution_order": ["C4", "C3", "C7"],
        "blocking_constraints": ["C3", "C4"],
        "rationale": "Sandboxing is critical for multi-tenant filesystem isolation"
      },
      "hydration_weight": "medium",
      "entrypoint_function": "createSandbox",
      "tenant_context_required": true,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["sandbox_created", "access_denied"],
        "output_format": "jsonl"
      }
    },
    {
      "artifact_id": "fix-sintaxis-code",
      "file": "fix-sintaxis-code.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/fix-sintaxis-code.ts.md",
      "artifact_type": "typescript_module",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C5","V1"],
      "language_lock": ["typescript","javascript"],
      "validation_hooks": ["verify-constraints.sh", "tsc-strict-check.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "tsc-strict-check.sh"],
        "norms": ["harness-norms-v3.0.md#C5"],
        "config": ["tsconfig.json", "eslint.config.js"]
      },
      "dependents": ["javascript-typescript-master-agent"],
      "norms_priority": {
        "execution_order": ["C5"],
        "blocking_constraints": [],
        "rationale": "Syntax fixing is type-safety optimization (C5); V1 for reference only"
      },
      "hydration_weight": "light",
      "entrypoint_function": "fixSyntax",
      "tenant_context_required": false,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["syntax_fixed", "errors_corrected"],
        "output_format": "jsonl"
      }
    },
    {
      "artifact_id": "git-disaster-recovery",
      "file": "git-disaster-recovery.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/git-disaster-recovery.ts.md",
      "artifact_type": "typescript_module",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C5","C7"],
      "language_lock": ["typescript","nodejs"],
      "validation_hooks": ["verify-constraints.sh", "tsc-strict-check.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh"],
        "norms": ["harness-norms-v3.0.md#C5", "harness-norms-v3.0.md#C7"],
        "config": ["git-config.json"]
      },
      "dependents": ["dependency-management", "orchestrator-routing"],
      "norms_priority": {
        "execution_order": ["C7", "C5"],
        "blocking_constraints": [],
        "rationale": "Git recovery is resilience (C7) with type safety (C5)"
      },
      "hydration_weight": "light",
      "entrypoint_function": "recoverGitState",
      "tenant_context_required": false,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["git_operation", "recovery_completed"],
        "output_format": "jsonl"
      }
    },
    {
      "artifact_id": "hardening-verification",
      "file": "hardening-verification.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/hardening-verification.ts.md",
      "artifact_type": "typescript_module",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C3","C4","C5","C7","C8"],
      "language_lock": ["typescript","nodejs"],
      "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "check-rls.sh", "verify-observability.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "audit-secrets.sh", "check-rls.sh"],
        "norms": ["harness-norms-v3.0.md", "06-MULTITENANCY-RULES.md"],
        "config": ["hardening-config.json"]
      },
      "dependents": ["all phase-0 to phase-5 artifacts"],
      "norms_priority": {
        "execution_order": ["C4", "C3", "C7", "C5", "C8"],
        "blocking_constraints": ["C3", "C4"],
        "rationale": "Hardening verification is pre-flight for all JS/TS modules"
      },
      "hydration_weight": "heavy",
      "entrypoint_function": "verifyHardening",
      "tenant_context_required": true,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["hardening_check_started", "hardening_check_completed"],
        "output_format": "jsonl",
        "pii_scrubbing": true
      }
    },
    {
      "artifact_id": "langchainjs-integration",
      "file": "langchainjs-integration.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/langchainjs-integration.ts.md",
      "artifact_type": "typescript_module",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C4","C7","C8"],
      "language_lock": ["typescript","nodejs"],
      "validation_hooks": ["verify-constraints.sh", "check-rls.sh", "verify-observability.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "verify-observability.sh"],
        "norms": ["harness-norms-v3.0.md#C4", "harness-norms-v3.0.md#C8"],
        "config": ["langchain-config.json"]
      },
      "dependents": ["js-mcp-client-implementation", "js-ia-response-validation-gate"],
      "norms_priority": {
        "execution_order": ["C4", "C8", "C7"],
        "blocking_constraints": ["C4"],
        "rationale": "LangChain integration must respect tenant context (C4)"
      },
      "hydration_weight": "medium",
      "entrypoint_function": "createTenantAwareChain",
      "tenant_context_required": true,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["chain_executed", "tokens_used", "tenant_context_applied"],
        "output_format": "jsonl"
      }
    },
    {
      "artifact_id": "n8n-webhook-handler",
      "file": "n8n-webhook-handler.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/n8n-webhook-handler.ts.md",
      "artifact_type": "typescript_module",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C3","C4","C7"],
      "language_lock": ["typescript","nodejs"],
      "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "check-rls.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "audit-secrets.sh"],
        "norms": ["harness-norms-v3.0.md#C3", "06-MULTITENANCY-RULES.md"],
        "config": ["webhook-config.json"]
      },
      "dependents": ["whatsapp-bot-integration", "orchestrator-routing"],
      "norms_priority": {
        "execution_order": ["C4", "C3", "C7"],
        "blocking_constraints": ["C3", "C4"],
        "rationale": "Webhook handling must validate tenant and secrets"
      },
      "hydration_weight": "medium",
      "entrypoint_function": "handleWebhook",
      "tenant_context_required": true,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["webhook_received", "signature_verified", "tenant_routed"],
        "output_format": "jsonl"
      }
    },
    {
      "artifact_id": "observability-opentelemetry",
      "file": "observability-opentelemetry.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/observability-opentelemetry.ts.md",
      "artifact_type": "typescript_module",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C8","V-LOG-02"],
      "language_lock": ["typescript","nodejs"],
      "validation_hooks": ["verify-observability.sh", "verify-constraints.sh"],
      "dependencies": {
        "validators": ["verify-observability.sh"],
        "norms": ["harness-norms-v3.0.md#C8", "V-LOG-02.md"],
        "config": ["otel-config.json"]
      },
      "dependents": ["all artifacts requiring observability"],
      "norms_priority": {
        "execution_order": ["C8"],
        "blocking_constraints": [],
        "rationale": "Observability is non-blocking but required for production readiness"
      },
      "hydration_weight": "medium",
      "entrypoint_function": "initOpenTelemetry",
      "tenant_context_required": true,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["otel_initialized", "span_created", "metric_exported"],
        "output_format": "jsonl",
        "otel_integration": true
      }
    },
    {
      "artifact_id": "orchestrator-routing",
      "file": "orchestrator-routing.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/orchestrator-routing.ts.md",
      "artifact_type": "typescript_module",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C4","C7","C8"],
      "language_lock": ["typescript","nodejs"],
      "validation_hooks": ["verify-constraints.sh", "check-rls.sh", "verify-observability.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "verify-observability.sh"],
        "norms": ["harness-norms-v3.0.md#C4", "06-MULTITENANCY-RULES.md"],
        "config": ["routing-config.json"]
      },
      "dependents": ["whatsapp-bot-integration", "n8n-webhook-handler"],
      "norms_priority": {
        "execution_order": ["C4", "C7", "C8"],
        "blocking_constraints": ["C4"],
        "rationale": "Routing must enforce tenant isolation before load balancing"
      },
      "hydration_weight": "medium",
      "entrypoint_function": "routeRequest",
      "tenant_context_required": true,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["request_routed", "latency_measured", "tenant_validated"],
        "output_format": "jsonl"
      }
    },
    {
      "artifact_id": "robust-error-handling",
      "file": "robust-error-handling.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/robust-error-handling.ts.md",
      "artifact_type": "typescript_pattern",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C7","C8"],
      "language_lock": ["typescript","javascript"],
      "validation_hooks": ["verify-constraints.sh", "verify-observability.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "verify-observability.sh"],
        "norms": ["harness-norms-v3.0.md#C7", "harness-norms-v3.0.md#C8"],
        "config": ["error-config.json"]
      },
      "dependents": ["all artifacts with async operations"],
      "norms_priority": {
        "execution_order": ["C7", "C8"],
        "blocking_constraints": [],
        "rationale": "Error handling is resilience (C7) with observability (C8)"
      },
      "hydration_weight": "light",
      "entrypoint_function": "withRetry",
      "tenant_context_required": false,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["error_caught", "retry_attempted", "fallback_used"],
        "output_format": "jsonl"
      }
    },
    {
      "artifact_id": "scale-simulation-utils",
      "file": "scale-simulation-utils.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/scale-simulation-utils.ts.md",
      "artifact_type": "typescript_module",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C1","C7"],
      "language_lock": ["typescript","nodejs"],
      "validation_hooks": ["verify-constraints.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh"],
        "norms": ["harness-norms-v3.0.md#C1", "harness-norms-v3.0.md#C7"],
        "config": ["load-test-config.json"]
      },
      "dependents": ["orchestrator-routing", "robust-error-handling"],
      "norms_priority": {
        "execution_order": ["C7", "C1"],
        "blocking_constraints": [],
        "rationale": "Scale simulation is optimization (C1) with resilience testing (C7)"
      },
      "hydration_weight": "light",
      "entrypoint_function": "simulateLoad",
      "tenant_context_required": false,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["simulation_started", "metrics_collected"],
        "output_format": "jsonl"
      }
    },
    {
      "artifact_id": "secrets-management-patterns",
      "file": "secrets-management-patterns.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/secrets-management-patterns.ts.md",
      "artifact_type": "typescript_pattern",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C3","C4"],
      "language_lock": ["typescript","nodejs"],
      "validation_hooks": ["audit-secrets.sh", "verify-constraints.sh", "check-rls.sh"],
      "dependencies": {
        "validators": ["audit-secrets.sh", "verify-constraints.sh"],
        "norms": ["harness-norms-v3.0.md#C3", "06-MULTITENANCY-RULES.md"],
        "config": ["vault-config.json"]
      },
      "dependents": ["authentication-authorization-patterns", "js-secrets-frontend-handling"],
      "norms_priority": {
        "execution_order": ["C3", "C4"],
        "blocking_constraints": ["C3"],
        "rationale": "Secrets management is security-critical (C3) with tenant scoping (C4)"
      },
      "hydration_weight": "medium",
      "entrypoint_function": "injectSecret",
      "tenant_context_required": true,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["secret_accessed", "vault_connection"],
        "output_format": "jsonl",
        "pii_scrubbing": true
      }
    },
    {
      "artifact_id": "testing-multi-tenant-patterns",
      "file": "testing-multi-tenant-patterns.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/testing-multi-tenant-patterns.ts.md",
      "artifact_type": "typescript_pattern",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C4","C8"],
      "language_lock": ["typescript","vitest"],
      "validation_hooks": ["verify-constraints.sh", "check-rls.sh", "verify-observability.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "check-rls.sh"],
        "norms": ["harness-norms-v3.0.md#C4", "harness-norms-v3.0.md#C8"],
        "config": ["vitest.config.ts"]
      },
      "dependents": ["js-vitest-tenant-isolation", "js-e2e-tenant-scenario-tests"],
      "norms_priority": {
        "execution_order": ["C4", "C8"],
        "blocking_constraints": ["C4"],
        "rationale": "Testing must validate tenant isolation (C4) with observability (C8)"
      },
      "hydration_weight": "light",
      "entrypoint_function": "createTenantFixture",
      "tenant_context_required": true,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["test_started", "tenant_isolated", "test_completed"],
        "output_format": "jsonl"
      }
    },
    {
      "artifact_id": "type-safety-with-typescript",
      "file": "type-safety-with-typescript.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/type-safety-with-typescript.ts.md",
      "artifact_type": "typescript_pattern",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C5","V1"],
      "language_lock": ["typescript"],
      "validation_hooks": ["verify-constraints.sh", "tsc-strict-check.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "tsc-strict-check.sh"],
        "norms": ["harness-norms-v3.0.md#C5"],
        "config": ["tsconfig.json", "zod-schema.json"]
      },
      "dependents": ["all TypeScript artifacts"],
      "norms_priority": {
        "execution_order": ["C5"],
        "blocking_constraints": [],
        "rationale": "Type safety is structural (C5); V1 for reference only"
      },
      "hydration_weight": "medium",
      "entrypoint_function": "validateType",
      "tenant_context_required": false,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["type_validated", "schema_matched"],
        "output_format": "jsonl"
      }
    },
    {
      "artifact_id": "vertical-db-schemas",
      "file": "vertical-db-schemas.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/vertical-db-schemas.ts.md",
      "artifact_type": "typescript_module",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C4","C5"],
      "language_lock": ["typescript","nodejs"],
      "validation_hooks": ["verify-constraints.sh", "check-rls.sh", "tsc-strict-check.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "check-rls.sh"],
        "norms": ["harness-norms-v3.0.md#C4", "harness-norms-v3.0.md#C5"],
        "config": ["migration-config.json", "tsconfig.json"]
      },
      "dependents": ["db-selection-decision-tree", "orchestrator-routing"],
      "norms_priority": {
        "execution_order": ["C4", "C5"],
        "blocking_constraints": ["C4"],
        "rationale": "DB schemas must enforce tenant isolation (C4) with type safety (C5)"
      },
      "hydration_weight": "medium",
      "entrypoint_function": "applyTenantSchema",
      "tenant_context_required": true,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["schema_applied", "migration_completed"],
        "output_format": "jsonl"
      }
    },
    {
      "artifact_id": "webhook-validation-patterns",
      "file": "webhook-validation-patterns.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/webhook-validation-patterns.ts.md",
      "artifact_type": "typescript_pattern",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C3","C4","C7"],
      "language_lock": ["typescript","nodejs"],
      "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "check-rls.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "audit-secrets.sh"],
        "norms": ["harness-norms-v3.0.md#C3", "06-MULTITENANCY-RULES.md"],
        "config": ["webhook-security-config.json"]
      },
      "dependents": ["n8n-webhook-handler", "whatsapp-bot-integration"],
      "norms_priority": {
        "execution_order": ["C4", "C3", "C7"],
        "blocking_constraints": ["C3", "C4"],
        "rationale": "Webhook validation must verify tenant and signature"
      },
      "hydration_weight": "medium",
      "entrypoint_function": "validateWebhookSignature",
      "tenant_context_required": true,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["webhook_validated", "signature_verified", "tenant_matched"],
        "output_format": "jsonl"
      }
    },
    {
      "artifact_id": "whatsapp-bot-integration",
      "file": "whatsapp-bot-integration.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/whatsapp-bot-integration.ts.md",
      "artifact_type": "typescript_module",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C3","C4","C7","C8"],
      "language_lock": ["typescript","nodejs"],
      "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "check-rls.sh", "verify-observability.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "audit-secrets.sh", "verify-observability.sh"],
        "norms": ["harness-norms-v3.0.md#C3", "06-MULTITENANCY-RULES.md"],
        "config": ["whatsapp-config.json"]
      },
      "dependents": ["orchestrator-routing", "n8n-webhook-handler"],
      "norms_priority": {
        "execution_order": ["C4", "C3", "C7", "C8"],
        "blocking_constraints": ["C3", "C4"],
        "rationale": "WhatsApp integration must enforce tenant and secrets with observability"
      },
      "hydration_weight": "medium",
      "entrypoint_function": "handleWhatsAppMessage",
      "tenant_context_required": true,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["message_received", "tenant_routed", "response_sent"],
        "output_format": "jsonl",
        "pii_scrubbing": true
      }
    },
    {
      "artifact_id": "yaml-frontmatter-parser",
      "file": "yaml-frontmatter-parser.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/yaml-frontmatter-parser.ts.md",
      "artifact_type": "typescript_module",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C5","C8"],
      "language_lock": ["typescript","nodejs"],
      "validation_hooks": ["verify-constraints.sh", "tsc-strict-check.sh", "verify-observability.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "tsc-strict-check.sh"],
        "norms": ["harness-norms-v3.0.md#C5", "harness-norms-v3.0.md#C8"],
        "config": ["yaml-schema.json", "tsconfig.json"]
      },
      "dependents": ["javascript-typescript-master-agent", "00-INDEX.md"],
      "norms_priority": {
        "execution_order": ["C5", "C8"],
        "blocking_constraints": [],
        "rationale": "Frontmatter parsing is structural (C5) with logging (C8)"
      },
      "hydration_weight": "light",
      "entrypoint_function": "parseFrontmatter",
      "tenant_context_required": false,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["frontmatter_parsed", "schema_validated"],
        "output_format": "jsonl"
      }
    },
    {
      "artifact_id": "js-hardening-verification",
      "file": "js-hardening-verification.js.md",
      "canonical_path": "06-PROGRAMMING/javascript/js-hardening-verification.js.md",
      "artifact_type": "javascript_pattern",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C3","C4","C5","C7","C8"],
      "language_lock": ["javascript","nodejs"],
      "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "eslint-validator.js", "verify-observability.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "audit-secrets.sh", "eslint-validator.js"],
        "norms": ["harness-norms-v3.0.md", "06-MULTITENANCY-RULES.md"],
        "config": ["eslint.config.js"]
      },
      "dependents": ["all JavaScript artifacts"],
      "norms_priority": {
        "execution_order": ["C4", "C3", "C7", "C5", "C8"],
        "blocking_constraints": ["C3", "C4"],
        "rationale": "Hardening verification is pre-flight for all JS modules"
      },
      "hydration_weight": "medium",
      "entrypoint_function": "verifyHardeningJS",
      "tenant_context_required": true,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["js_hardening_check", "validation_completed"],
        "output_format": "jsonl",
        "pii_scrubbing": true
      }
    },
    {
      "artifact_id": "ts-strict-mode-enforcement",
      "file": "ts-strict-mode-enforcement.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/ts-strict-mode-enforcement.ts.md",
      "artifact_type": "typescript_module",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C5","V1"],
      "language_lock": ["typescript"],
      "validation_hooks": ["verify-constraints.sh", "tsc-strict-check.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "tsc-strict-check.sh"],
        "norms": ["harness-norms-v3.0.md#C5"],
        "config": ["tsconfig.strict.json"]
      },
      "dependents": ["all TypeScript artifacts"],
      "norms_priority": {
        "execution_order": ["C5"],
        "blocking_constraints": [],
        "rationale": "Strict mode enforcement is type-safety optimization (C5)"
      },
      "hydration_weight": "light",
      "entrypoint_function": "enforceStrictMode",
      "tenant_context_required": false,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["strict_mode_enabled", "type_errors_found"],
        "output_format": "jsonl"
      }
    },
    {
      "artifact_id": "js-error-boundaries-patterns",
      "file": "js-error-boundaries-patterns.js.md",
      "canonical_path": "06-PROGRAMMING/javascript/js-error-boundaries-patterns.js.md",
      "artifact_type": "javascript_pattern",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C7","C8"],
      "language_lock": ["javascript","react","vue"],
      "validation_hooks": ["verify-constraints.sh", "eslint-validator.js", "verify-observability.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "verify-observability.sh"],
        "norms": ["harness-norms-v3.0.md#C7", "harness-norms-v3.0.md#C8"],
        "config": ["error-boundary-config.json"]
      },
      "dependents": ["all frontend components"],
      "norms_priority": {
        "execution_order": ["C7", "C8"],
        "blocking_constraints": [],
        "rationale": "Error boundaries are resilience (C7) with observability (C8)"
      },
      "hydration_weight": "light",
      "entrypoint_function": "createErrorBoundary",
      "tenant_context_required": false,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["error_caught", "boundary_rendered", "fallback_shown"],
        "output_format": "jsonl"
      }
    },
    {
      "artifact_id": "js-tenant-context-provider",
      "file": "js-tenant-context-provider.ts.md",
      "canonical_path": "06-PROGRAMMING/javascript/js-tenant-context-provider.ts.md",
      "artifact_type": "typescript_module",
      "tier": 2,
      "status": "real",
      "constraints_mapped": ["C3","C4","C5","C7","C8"],
      "language_lock": ["typescript","react","vue"],
      "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "check-rls.sh", "verify-observability.sh"],
      "dependencies": {
        "validators": ["verify-constraints.sh", "audit-secrets.sh", "check-rls.sh"],
        "norms": ["harness-norms-v3.0.md#C4", "06-MULTITENANCY-RULES.md"],
        "config": ["context-config.json"]
      },
      "dependents": ["all frontend artifacts with tenant context"],
      "norms_priority": {
        "execution_order": ["C4", "C3", "C8", "C7", "C5"],
        "blocking_constraints": ["C4", "C3"],
        "rationale": "Tenant context provider is foundational for frontend multi-tenancy"
      },
      "hydration_weight": "heavy",
      "entrypoint_function": "TenantProvider",
      "tenant_context_required": true,
      "vectorizable": false,
      "observability": {
        "log_schema": "V-LOG-02",
        "required_events": ["tenant_context_set", "context_propagated"],
        "output_format": "jsonl",
        "pii_scrubbing": true
      }
    }
  ],
  "dependency_graph": {
    "validation_layer": {
      "orchestrator-engine.sh": ["all artifacts"],
      "verify-constraints.sh": ["all artifacts"],
      "audit-secrets.sh": ["secrets-management-patterns", "authentication-authorization-patterns", "js-secrets-frontend-handling", "javascript-typescript-master-agent"],
      "eslint-validator.js": ["js-hardening-verification", "js-error-boundaries-patterns", "javascript-typescript-master-agent"],
      "tsc-strict-check.sh": ["ts-strict-mode-enforcement", "type-safety-with-typescript", "javascript-typescript-master-agent"],
      "verify-observability.sh": ["observability-opentelemetry", "all artifacts with C8"],
      "check-rls.sh": ["context-isolation-patterns", "vertical-db-schemas", "js-tenant-context-provider"]
    },
    "norms_layer": {
      "harness-norms-v3.0.md": ["all artifacts"],
      "10-SDD-CONSTRAINTS.md": ["all artifacts"],
      "language-lock-protocol.md": ["all artifacts"],
      "06-MULTITENANCY-RULES.md": ["context-isolation-patterns", "secrets-management-patterns", "js-tenant-context-provider", "authentication-authorization-patterns"],
      "norms-matrix.json": ["all artifacts", "javascript-typescript-master-agent", "00-INDEX.md"],
      "V-LOG-02.md": ["observability-opentelemetry", "all artifacts with C8"]
    },
    "config_layer": {
      "template_artifacts.md": ["all artifacts"],
      "tsconfig.json": ["all TypeScript artifacts"],
      "eslint.config.js": ["all JavaScript artifacts"],
      "otel-config.json": ["observability-opentelemetry"],
      "vault-config.json": ["secrets-management-patterns"]
    }
  },
  "norms_execution_priority": {
    "global_order": ["C4", "C3", "C7", "C5", "C8", "C1", "C2", "C6"],
    "rationale": "C4 (tenant isolation) is foundational; security (C3) and path safety (C7) precede structural (C5) and observability (C8) checks",
    "blocking_set": ["C3", "C4", "C7"],
    "non_blocking_set": ["C1", "C2", "C5", "C6", "C8"],
    "observability_requirement": "C8 artifacts must emit JSONL V-LOG-02 via mantis_log()",
    "selective_v_logic": {
      "applies_to": "postgresql-pgvector/ ONLY",
      "trigger": "artifact_type == 'skill_pgvector' AND content has pgvector operators",
      "exclusion": "javascript/ ALWAYS excludes V1/V2/V3 per LANGUAGE LOCK"
    }
  },
  "language_lock_enforcement": {
    "folder": "06-PROGRAMMING/javascript/",
    "prohibited_patterns": ["from ['\"]pgvector['\"]", "cosine_distance", "l2_distance", "hamming_distance", "vector\\(", "<->[^a-zA-Z]", "<#>[^a-zA-Z]", "<=>[^a-zA-Z]"],
    "required_artifact_types": ["javascript_module", "typescript_module", "javascript_pattern", "typescript_pattern", "frontend_component"],
    "prohibited_constraints": ["V1", "V2", "V3"],
    "validation_script": "validate-skill-integrity.sh --check-language-lock",
    "failure_action": "exit 2 with message 'LANGUAGE LOCK VIOLATION: pgvector imports/operators not allowed in JavaScript/TypeScript domain'"
  },
  "ai_navigation_hints": {
    "for_generation": "Read javascript-typescript-master-agent.md AND this index BEFORE generating new JS/TS artifacts. Use stackselector to hydrate only required modules.",
    "for_validation": "Use norms_execution_priority to order constraint checks; validate C4 before allowing API calls in examples. Verify observability with verify-observability.sh --schema V-LOG-02.",
    "for_migration": "Consult dependency_graph before modifying shared patterns; type changes may require downstream updates.",
    "for_debugging": "Check language_lock_enforcement if pgvector operators appear in javascript/ artifacts. Check observability field if logs are not JSONL.",
    "for_master_agent": "Agent must consult norms-matrix.json before declaring constraints; emit JSON to stdout, logs to stderr, JSONL to 08-LOGS/ per V-LOG-02; delegate vector/SQL/backend logic to appropriate domains.",
    "for_stackselector": "Use hydration_weight to prioritize module loading: heavy=master/index, medium=core patterns, light=utilities. All 30 artifacts are status:real for design-first generation."
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
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/verify-observability.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json
```

### 💻 Patrones JavaScript/TypeScript Core (06-PROGRAMMING/javascript) - 30 Artefactos
```text
# Índice y Master
06-PROGRAMMING/javascript/00-INDEX.md
06-PROGRAMMING/javascript/javascript-typescript-master-agent.md

# Core Patterns (24 existentes)
06-PROGRAMMING/javascript/async-patterns-with-timeouts.ts.md
06-PROGRAMMING/javascript/authentication-authorization-patterns.ts.md
06-PROGRAMMING/javascript/context-compaction-utils.ts.md
06-PROGRAMMING/javascript/context-isolation-patterns.ts.md
06-PROGRAMMING/javascript/db-selection-decision-tree.ts.md
06-PROGRAMMING/javascript/dependency-management.ts.md
06-PROGRAMMING/javascript/filesystem-sandbox-sync.ts.md
06-PROGRAMMING/javascript/filesystem-sandboxing.ts.md
06-PROGRAMMING/javascript/fix-sintaxis-code.ts.md
06-PROGRAMMING/javascript/git-disaster-recovery.ts.md
06-PROGRAMMING/javascript/hardening-verification.ts.md
06-PROGRAMMING/javascript/langchainjs-integration.ts.md
06-PROGRAMMING/javascript/n8n-webhook-handler.ts.md
06-PROGRAMMING/javascript/observability-opentelemetry.ts.md
06-PROGRAMMING/javascript/orchestrator-routing.ts.md
06-PROGRAMMING/javascript/robust-error-handling.ts.md
06-PROGRAMMING/javascript/scale-simulation-utils.ts.md
06-PROGRAMMING/javascript/secrets-management-patterns.ts.md
06-PROGRAMMING/javascript/testing-multi-tenant-patterns.ts.md
06-PROGRAMMING/javascript/type-safety-with-typescript.ts.md
06-PROGRAMMING/javascript/vertical-db-schemas.ts.md
06-PROGRAMMING/javascript/webhook-validation-patterns.ts.md
06-PROGRAMMING/javascript/whatsapp-bot-integration.ts.md
06-PROGRAMMING/javascript/yaml-frontmatter-parser.ts.md

# Planificados → Reales (Design-First)
06-PROGRAMMING/javascript/js-hardening-verification.js.md
06-PROGRAMMING/javascript/ts-strict-mode-enforcement.ts.md
06-PROGRAMMING/javascript/js-error-boundaries-patterns.js.md
06-PROGRAMMING/javascript/js-tenant-context-provider.ts.md
```

### 🔗 Referencias de Dominios Hermanos (Para Delegación)
```text
# SQL puro (delegar queries sin vectores)
06-PROGRAMMING/sql/00-INDEX.md
06-PROGRAMMING/sql/crud-with-tenant-enforcement.sql.md

# Python (delegar lógica de backend)
06-PROGRAMMING/python/00-INDEX.md
06-PROGRAMMING/python/python-sqlalchemy-tenant-enforcement.py.md

# pgvector/RAG (delegar operaciones vectoriales)
06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md

# YAML/JSON Schema (delegar definiciones de config)
06-PROGRAMMING/yaml-json-schema/00-INDEX.md
```

### 🔄 Workflows y CI/CD
```text
.github/workflows/validate-mantis.yml
04-WORKFLOWS/sdd-universal-assistant.json
```

### 📚 Skills de Referencia
```text
02-SKILLS/README.md
02-SKILLS/skill-domains-mapping.md
02-SKILLS/INFRASTRUCTURA/ssh-key-management.md
02-SKILLS/INFRASTRUCTURA/health-monitoring-vps.md
```

---

## 🗂️ RUTAS CANÓNICAS LOCALES – Patrones JavaScript/TypeScript (Para Acceso en Repo)

> **Formato**: `RAW_URL` → `./ruta/local/en/repo`

### 💻 Patrones JavaScript/TypeScript Core (30 artefactos - todos `status: real`)
```text
# Índice y Agente Master
06-PROGRAMMING/javascript/00-INDEX.md
06-PROGRAMMING/javascript/javascript-typescript-master-agent.md

# Core Patterns (24 existentes)
06-PROGRAMMING/javascript/async-patterns-with-timeouts.ts.md
06-PROGRAMMING/javascript/authentication-authorization-patterns.ts.md
06-PROGRAMMING/javascript/context-compaction-utils.ts.md
06-PROGRAMMING/javascript/context-isolation-patterns.ts.md
06-PROGRAMMING/javascript/db-selection-decision-tree.ts.md
06-PROGRAMMING/javascript/dependency-management.ts.md
06-PROGRAMMING/javascript/filesystem-sandbox-sync.ts.md
06-PROGRAMMING/javascript/filesystem-sandboxing.ts.md
06-PROGRAMMING/javascript/fix-sintaxis-code.ts.md
06-PROGRAMMING/javascript/git-disaster-recovery.ts.md
06-PROGRAMMING/javascript/hardening-verification.ts.md
06-PROGRAMMING/javascript/langchainjs-integration.ts.md
06-PROGRAMMING/javascript/n8n-webhook-handler.ts.md
06-PROGRAMMING/javascript/observability-opentelemetry.ts.md
06-PROGRAMMING/javascript/orchestrator-routing.ts.md
06-PROGRAMMING/javascript/robust-error-handling.ts.md
06-PROGRAMMING/javascript/scale-simulation-utils.ts.md
06-PROGRAMMING/javascript/secrets-management-patterns.ts.md
06-PROGRAMMING/javascript/testing-multi-tenant-patterns.ts.md
06-PROGRAMMING/javascript/type-safety-with-typescript.ts.md
06-PROGRAMMING/javascript/vertical-db-schemas.ts.md
06-PROGRAMMING/javascript/webhook-validation-patterns.ts.md
06-PROGRAMMING/javascript/whatsapp-bot-integration.ts.md
06-PROGRAMMING/javascript/yaml-frontmatter-parser.ts.md

# Design-First (4 planificados → tratados como reales)
06-PROGRAMMING/javascript/js-hardening-verification.js.md
06-PROGRAMMING/javascript/ts-strict-mode-enforcement.ts.md
06-PROGRAMMING/javascript/js-error-boundaries-patterns.js.md
06-PROGRAMMING/javascript/js-tenant-context-provider.ts.md
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

---

## 🧭 GUÍA DE USO PARA EL AGENTE JAVASCRIPT/TYPESCRIPT

```typescript
// Pseudocódigo: Cómo consultar el stackselector con hidratación segmentada
interface StackSelectorEntry {
  artifact_id: string;
  canonical_path: string;
  status: "real";  // 🔑 Todos son "real" para design-first
  hydration_weight: "light" | "medium" | "heavy";
  tenant_context_required: boolean;
  observability: { log_schema: string; required_events: string[] };
}

function loadStackSelector(): Record<string, StackSelectorEntry> {
  const index = loadJSON("06-PROGRAMMING/javascript/00-INDEX.md");
  return index.artifacts.reduce((acc, artifact) => {
    acc[artifact.artifact_id] = {
      artifact_id: artifact.artifact_id,
      canonical_path: artifact.canonical_path,
      status: "real",  // 🔑 Design-first: todos tratados como existentes
      hydration_weight: artifact.hydration_weight,
      tenant_context_required: artifact.tenant_context_required,
      observability: artifact.observability
    };
    return acc;
  }, {});
}

// Hidratación segmentada por prompt/constraints
function hydrateModules(requiredConstraints: string[], prompt: string): StackSelectorEntry[] {
  const selector = loadStackSelector();
  return Object.values(selector).filter(entry => {
    // Cargar siempre el master agent e index
    if (["00-INDEX-javascript", "javascript-typescript-master-agent"].includes(entry.artifact_id)) {
      return true;
    }
    // Filtrar por constraints requeridas
    const artifact = selector[entry.artifact_id];
    return artifact.constraints_mapped?.some(c => requiredConstraints.includes(c));
  });
}

// Validación de observabilidad V-LOG-02
function validateObservability(artifactPath: string): string[] {
  const content = loadFile(artifactPath);
  const issues: string[] = [];
  
  // Verificar que usa mantis_log() o fallback compatible
  if (!content.includes("mantis_log") && !content.includes("fallback")) {
    issues.push("C8 violation: artifact must use mantis_log() or documented fallback");
  }
  
  // Verificar que los logs siguen schema V-LOG-02
  const logPattern = /mantis_log\s*\(\s*['"](?:DEBUG|INFO|WARN|ERROR|FATAL)['"]/;
  if (content.includes("mantis_log") && !logPattern.test(content)) {
    issues.push("C8 violation: mantis_log() must use valid level (DEBUG|INFO|WARN|ERROR|FATAL)");
  }
  
  return issues;
}

// Ejemplo de uso en el agente:
const required = ["C3", "C4", "C8"];  // Constraints del prompt actual
const modules = hydrateModules(required, userPrompt);
for (const mod of modules) {
  if (mod.tenant_context_required) {
    injectTenantContext(mod.canonical_path);
  }
  const obsIssues = validateObservability(mod.canonical_path);
  if (obsIssues.length > 0) {
    console.error("Observability validation failed:", obsIssues);
    process.exit(1);
  }
}
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
| **Consulta stackselector antes de generar** | Antes de emitir módulo JS/TS, cargar `00-INDEX.md` y usar `hydration_weight` para hidratar solo módulos necesarios |
| **Acceso dual** | Usar ruta canónica (`./06-PROGRAMMING/javascript/...`) para acceso local, o raw URL para acceso remoto si el archivo no existe localmente |
| **LANGUAGE LOCK automático** | Si el usuario solicita operadores vectoriales (`from 'pgvector'`, `cosine_distance`, `<->`), delegar a `06-PROGRAMMING/postgresql-pgvector/` y NO generar código con vectores en su dominio |
| **Observabilidad obligatoria** | Todo artefacto generado debe usar `mantis_log()` canónica con schema V-LOG-02; validar con `verify-observability.sh` |
| **Type safety primero** | Priorizar TypeScript con `strict: true` para contracts de API; incluir validación de tenant_id en interfaces y types |
| **Enseña mientras genera** | Incluir JSDoc/TSDoc explicativos y comentarios sobre tenant isolation en los módulos generados |
| **Valida constraints antes de emitir** | Ejecutar `validarConstraintsJS()` y `validateObservability()` antes de emitir cualquier artifact |
| **Emite logs estructurados** | JSON a `stdout`, logs humanos a `stderr`, JSONL a `08-LOGS/validation/...` per V-INT-03 y V-LOG-02 |
```

### Paso 3: Validar con `verify-constraints.sh` y `verify-observability.sh`
```bash
# Validación integral del índice
./05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/javascript/00-INDEX.md \
  --check-all \
  --json | jq

# Validación específica de observabilidad V-LOG-02
./05-CONFIGURATIONS/validation/verify-observability.sh \
  --file 06-PROGRAMMING/javascript/00-INDEX.md \
  --schema V-LOG-02 \
  --json | jq

# Validación de LANGUAGE LOCK
./05-CONFIGURATIONS/validation/validate-skill-integrity.sh \
  --folder 06-PROGRAMMING/javascript/ \
  --prohibited "<->,<#>,cosine_distance" \
  --json | jq
```

---

> 📌 **Nota final**: Este índice es Tier 1 (referencia contractual). Cualquier modificación debe pasar validación automática antes de merge.  
> 🇧🇷 *Zero documentación en `docs/pt-BR/` conforme instrucción del proyecto. El framework con 15 agentes especializados en portugués se encargará de esa capa posteriormente.*

---
