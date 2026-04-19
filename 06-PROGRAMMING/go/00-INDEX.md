# SHA256: a9f2e8c4d1b7f3e6a0c5b9d2e8f1a4c7b3d6e9f2a5c8b1d4e7a0f3c6b9d2e5a8
---
artifact_id: "00-INDEX-go"
artifact_type: "skill_index"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/go/00-INDEX.md --json"
canonical_path: "06-PROGRAMMING/go/00-INDEX.md"
---

# 00-INDEX.md – Índice maestro para 06-PROGRAMMING/go/ (MANTIS AGENTIC)

## 📋 Propósito para Humanos
Índice canónico de navegación para artifacts de programación en Go dentro de MANTIS AGENTIC. Proporciona:
1. **Navegación estructurada** mediante wikilinks `[[ruta/archivo]]` a todos los artifacts Go
2. **Guía de aprendizaje progresivo**: desde conceptos básicos hasta patrones avanzados de microservicios
3. **Mapa de dependencias** con otros módulos del repositorio (validación, configuración, bash, python)
4. **Instrucciones de ejecución** para validación automatizada y generación de binaries

> 💡 **Nota pedagógica**: Cada artifact en esta carpeta incluye **25 ejemplos comentados línea por línea**, diseñados para que puedas entender qué hace cada grupo de comandos aunque estés aprendiendo Go.

## 🗂️ Artifacts Generados (Fase go/)

| Artifact | Constraints | Propósito | Ejemplos | Validación |
|----------|-------------|-----------|----------|------------|
| [[06-PROGRAMMING/go/orchestrator-engine.go.md]] | C1,C3,C4,C5,C6,C7,C8 | Port del orchestrator bash → Go con explicación didáctica | 25 ✅/❌/🔧 | `go build && ./orchestrator-engine --json` |
| [[06-PROGRAMMING/go/mcp-server-patterns.go.md]] | C1,C3,C4,C6,C7,C8 | Patrones para MCP servers: tool registration, context isolation | 25 ✅/❌/🔧 | `go test ./... -v` |
| [[06-PROGRAMMING/go/microservices-tenant-isolation.go.md]] | C3,C4,C5,C7,C8 | Middleware de aislamiento multi-tenant con ejemplos explicados | 25 ✅/❌/🔧 | `go test -race ./...` |
| [[06-PROGRAMMING/go/saas-deployment-zip-auto.go.md]] | C1,C3,C4,C6,C7 | Deploy automático por zip: unpack, validate, exec con rollback | 25 ✅/❌/🔧 | `go build -o deploy && ./deploy --dry-run` |
| [[06-PROGRAMMING/go/api-client-management.go.md]] | C3,C4,C5,C6,C8 | Generación de APIs para clientes: auth, rate-limit, structured JSON | 25 ✅/❌/🔧 | `go test ./api/...` |
| [[06-PROGRAMMING/go/structured-logging-c8.go.md]] | C4,C5,C7,C8 | Logging estructurado JSON a stderr con tenant_id, trace_id | 25 ✅/❌/🔧 | `go run . 2>&1 | jq .` |
| [[06-PROGRAMMING/go/secrets-management-c3.go.md]] | C3,C4,C7,C8 | Manejo seguro de secretos: env vars, zero hardcode, masking | 25 ✅/❌/🔧 | `go test -tags=secrets ./...` |
| [[06-PROGRAMMING/go/resource-limits-c1-c2.go.md]] | C1,C2,C4,C7 | Guardrails de recursos: mem_limit, timeout, pids con explicación | 25 ✅/❌/🔧 | `ulimit -v && go run .` |
| [[06-PROGRAMMING/go/error-handling-c7.go.md]] | C4,C5,C7,C8 | Error handling robusto: retry, fallback, structured error reports | 25 ✅/❌/🔧 | `go test -cover ./errors/...` |

## 🔗 Interacciones con Otros Módulos del Repositorio

```text
# Dependencias de validación (C5/C8 enforcement)
[[05-CONFIGURATIONS/validation/orchestrator-engine.sh]] ← Script bash original a portear a Go
[[05-CONFIGURATIONS/validation/validate-skill-integrity.sh]] ← Verifica LANGUAGE LOCK para go/
[[05-CONFIGURATIONS/validation/norms-matrix.json]] ← Routing de validación selectiva (V* excluidas para go/)

# Dependencias de normas (C1-C8 definitions)
[[01-RULES/harness-norms-v3.0.md]] ← Contrato base de constraints aplicables a Go
[[01-RULES/10-SDD-CONSTRAINTS.md]] ← Definiciones técnicas de C1-C8 para validación
[[01-RULES/language-lock-protocol.md]] ← Reglas: go/ NO permite pgvector operators ni SQL embebido

# Dependencias de configuración
[[05-CONFIGURATIONS/environment/.env.example]] ← Patrones ${VAR:?missing} para secrets en Go
[[05-CONFIGURATIONS/templates/skill-template.md]] ← Estructura base para artifacts Go

# Interacciones con programación en otros lenguajes
[[06-PROGRAMMING/bash/orchestrator-routing.md]] ← Lógica bash a replicar en Go con explicación comparativa
[[06-PROGRAMMING/python/orchestrator-routing.md]] ← Patrones Python como referencia cruzada
[[06-PROGRAMMING/yaml-json-schema/00-INDEX.md]] ← Índice hermano – comparte estructura de validación

# Interacciones con infraestructura
[[05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.yml]] ← Go binaries deployados via docker-compose
[[05-CONFIGURATIONS/terraform/modules/vps-base/main.tf]] ← Recursos para compilar/ejecutar Go en VPS
```

## 🚀 Guía de Ejecución para Validación y Aprendizaje

```bash
# 1. Validación individual de un artifact Go (usa orchestrator bash)
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/go/orchestrator-engine.go.md \
  --json

# 2. Compilación y prueba de un ejemplo extraído
# 👇 Extrae el primer ejemplo ✅ de orchestrator-engine.go.md
grep -A5 "^-- ✅" 06-PROGRAMMING/go/orchestrator-engine.go.md | grep -v "^--" > ejemplo.go
# 👇 Compila y ejecuta (requiere Go 1.21+)
go build -o ejemplo ejemplo.go && ./ejemplo --help

# 3. Verificación de LANGUAGE LOCK (cero pgvector leakage en go/)
for f in 06-PROGRAMMING/go/*.go.md; do
  if grep -qE '<->|<=>|<#>|vector\([0-9]+\)|USING\s+(hnsw|ivfflat)' "$f"; then
    echo "❌ LANGUAGE LOCK VIOLATION en: $f"
    exit 1
  fi
done
echo "✅ LANGUAGE LOCK: 0 violaciones en artifacts Go"

# 4. Ejecución del orchestrator Go una vez generado
# 👇 Este comando funcionará después de generar orchestrator-engine.go.md
go run 06-PROGRAMMING/go/orchestrator-engine.go.md --file . --json 2>/dev/null | jq '.summary'
```

## ⚠️ Reglas Críticas de LANGUAGE LOCK para go/

```text
🚫 PROHIBIDO en esta carpeta:
• Operadores pgvector: <->, <#>, <=>, vector(n), USING hnsw, USING ivfflat
• SQL embebido con sintaxis de extensión pgvector
• Constraints vectoriales V1/V2/V3 en constraints_mapped del frontmatter

✅ REQUERIDO en esta carpeta:
• artifact_type: "skill_go" o "skill_index" (NUNCA "skill_pgvector")
• constraints_mapped: SOLO valores de C1-C8
• Ejemplos en formato ✅/❌/🔧 con ≤5 líneas ejecutables de Go puro
• Comentarios explicativos en español para cada grupo de comandos (pedagogía)
• validation_command que referencie orchestrator-engine.sh con canonical_path correcto
• Structured logging a stderr en formato JSON para C8 compliance
```

## 🎓 Enfoque Pedagógico – Cómo Leer Estos Artifacts

```text
Cada artifact en go/ está diseñado para que aprendas mientras implementas:

1. 📖 COMENTARIOS EXPLICATIVOS: Cada bloque de código incluye comentarios en español
   que explican QUÉ hace cada línea y POR QUÉ es importante para el constraint aplicado.

2. 🔍 COMPARACIÓN BASH → GO: Cuando portamos lógica del orchestrator bash, incluimos
   una tabla comparativa que muestra la equivalencia entre comandos bash y funciones Go.

3. 🧪 EJEMPLOS EJECUTABLES: Los 25 ejemplos por artifact son código Go real que puedes
   copiar, compilar y ejecutar. Cada uno tiene ≤5 líneas ejecutables para facilitar el aprendizaje.

4. 🔄 PATRONES REPETIBLES: Los patrones de tenant isolation, secrets management y logging
   se repiten con variaciones para que internalices la estructura antes de avanzar.

5. 📊 VALIDACIÓN AUTOMÁTICA: Cada artifact incluye un validation_command que puedes
   ejecutar para verificar que tu código cumple con las normas antes de integrarlo.

💡 Consejo: Comienza con structured-logging-c8.go.md y secrets-management-c3.go.md,
   ya que son fundamentales para todos los demás artifacts y tienen explicaciones
   más detalladas de los conceptos base de Go.
```

---

## 🤖 JSON TREE ENRIQUECIDO PARA IA (Metadatos + Dependencias + Prioridad de Normas)

```json
{
  "index_metadata": {
    "artifact_id": "00-INDEX-go",
    "artifact_type": "skill_index",
    "version": "3.0.0-SELECTIVE",
    "canonical_path": "06-PROGRAMMING/go/00-INDEX.md",
    "language_lock_status": "enforced",
    "vector_constraints_applied": false,
    "generated_timestamp": "2026-04-19T00:00:00Z",
    "pedagogical_mode": true,
    "examples_per_artifact": 25
  },
  "artifacts": [
    {
      "artifact_id": "orchestrator-engine",
      "file": "orchestrator-engine.go.md",
      "canonical_path": "06-PROGRAMMING/go/orchestrator-engine.go.md",
      "constraints_mapped": ["C1","C3","C4","C5","C6","C7","C8"],
      "examples_count": 25,
      "score_baseline": 90,
      "pedagogical_features": {
        "bash_to_go_comparison_table": true,
        "line_by_line_comments": true,
        "executable_examples": true,
        "error_explanations": true
      },
      "dependencies": {
        "source_reference": ["06-PROGRAMMING/bash/orchestrator-routing.md"],
        "validators": ["verify-constraints.sh", "audit-secrets.sh"],
        "norms": ["harness-norms-v3.0.md", "10-SDD-CONSTRAINTS.md"],
        "tools": ["go 1.21+", "go vet", "go test"]
      },
      "dependents": ["mcp-server-patterns", "microservices-tenant-isolation", "saas-deployment-zip-auto"],
      "norms_priority": {
        "execution_order": ["C4", "C3", "C7", "C5", "C8", "C1", "C6"],
        "blocking_constraints": ["C3", "C4"],
        "rationale": "Secrets (C3) and tenant isolation (C4) are foundational; other checks depend on correct auth/authorization"
      },
      "interactions": {
        "with_validation": "Port of bash orchestrator logic; validates other Go artifacts via embedded checks",
        "with_config": "Reads .env.example patterns for secrets; uses norms-matrix.json for constraint routing",
        "with_programming": "Provides base patterns reusable in mcp-server-patterns and microservices artifacts"
      }
    },
    {
      "artifact_id": "mcp-server-patterns",
      "file": "mcp-server-patterns.go.md",
      "canonical_path": "06-PROGRAMMING/go/mcp-server-patterns.go.md",
      "constraints_mapped": ["C1","C3","C4","C6","C7","C8"],
      "examples_count": 25,
      "score_baseline": 89,
      "pedagogical_features": {
        "tool_registration_explained": true,
        "context_isolation_diagram": true,
        "tenant_routing_flow": true
      },
      "dependencies": {
        "source_reference": ["02-SKILLS/AI/openrouter-api-integration.md"],
        "validators": ["verify-constraints.sh", "schema-validator.py"],
        "norms": ["harness-norms-v3.0.md#C4,C6"],
        "protocols": ["modelcontextprotocol/spec"]
      },
      "dependents": ["api-client-management", "microservices-tenant-isolation"],
      "norms_priority": {
        "execution_order": ["C4", "C6", "C3", "C8", "C1", "C7"],
        "blocking_constraints": ["C4", "C6"],
        "rationale": "Tenant isolation (C4) and executable validation (C6) must succeed before MCP tools can be safely registered"
      },
      "interactions": {
        "with_validation": "MCP tool definitions validated by schema-validator.py for JSON schema compliance",
        "with_config": "Tool registration patterns align with provider-router.yml for multi-model routing",
        "with_programming": "Patterns reusable in javascript/ and python/ MCP implementations with LANGUAGE LOCK awareness"
      }
    },
    {
      "artifact_id": "microservices-tenant-isolation",
      "file": "microservices-tenant-isolation.go.md",
      "canonical_path": "06-PROGRAMMING/go/microservices-tenant-isolation.go.md",
      "constraints_mapped": ["C3","C4","C5","C7","C8"],
      "examples_count": 25,
      "score_baseline": 91,
      "pedagogical_features": {
        "middleware_explanation": true,
        "request_flow_diagram": true,
        "error_propagation_guide": true
      },
      "dependencies": {
        "source_reference": ["02-SKILLS/BASE DE DATOS-RAG/multi-tenant-data-isolation.md"],
        "validators": ["check-rls.sh", "verify-constraints.sh"],
        "norms": ["harness-norms-v3.0.md#C4", "06-MULTITENANCY-RULES.md"],
        "frameworks": ["chi", "gin", "echo"]
      },
      "dependents": ["api-client-management", "structured-logging-c8"],
      "norms_priority": {
        "execution_order": ["C4", "C8", "C3", "C7", "C5"],
        "blocking_constraints": ["C4"],
        "rationale": "Tenant_id extraction and validation (C4) is the first middleware step; structured logging (C8) depends on correct tenant context"
      },
      "interactions": {
        "with_validation": "Middleware patterns validated by verify-constraints.sh for tenant_id propagation",
        "with_config": "Aligns with multi-tenant rules in 06-MULTITENANCY-RULES.md and docker-compose tenant labels",
        "with_programming": "Patterns reusable in postgres-pgvector/ ONLY if V* triggers met (LANGUAGE LOCK aware)"
      }
    },
    {
      "artifact_id": "saas-deployment-zip-auto",
      "file": "saas-deployment-zip-auto.go.md",
      "canonical_path": "06-PROGRAMMING/go/saas-deployment-zip-auto.go.md",
      "constraints_mapped": ["C1","C3","C4","C6","C7"],
      "examples_count": 25,
      "score_baseline": 88,
      "pedagogical_features": {
        "unpack_validation_flow": true,
        "rollback_mechanism_explained": true,
        "resource_limit_comments": true
      },
      "dependencies": {
        "source_reference": ["02-SKILLS/DEPLOYMENT/multi-channel-deploymen.md"],
        "validators": ["verify-constraints.sh", "shellcheck"],
        "norms": ["harness-norms-v3.0.md#C1,C7"],
        "tools": ["archive/zip", "os/exec", "context.WithTimeout"]
      },
      "dependents": ["orchestrator-engine", "api-client-management"],
      "norms_priority": {
        "execution_order": ["C4", "C1", "C7", "C3", "C6"],
        "blocking_constraints": ["C1", "C4"],
        "rationale": "Resource limits (C1) and tenant scoping (C4) prevent unsafe zip extraction and deployment"
      },
      "interactions": {
        "with_validation": "Deploy commands validated by verify-constraints.sh for timeout/resource compliance",
        "with_config": "Resource limits align with docker-compose mem_limit/cpus; tenant scoping with norms-matrix.json",
        "with_programming": "Zip handling patterns reusable in bash/ and python/ deployment scripts"
      }
    },
    {
      "artifact_id": "api-client-management",
      "file": "api-client-management.go.md",
      "canonical_path": "06-PROGRAMMING/go/api-client-management.go.md",
      "constraints_mapped": ["C3","C4","C5","C6","C8"],
      "examples_count": 25,
      "score_baseline": 90,
      "pedagogical_features": {
        "auth_flow_explained": true,
        "rate_limit_mechanism": true,
        "structured_response_format": true
      },
      "dependencies": {
        "source_reference": ["02-SKILLS/COMUNICACION/whatsapp-rag-openrouter.md"],
        "validators": ["verify-constraints.sh", "schema-validator.py"],
        "norms": ["harness-norms-v3.0.md#C8"],
        "tools": ["net/http", "encoding/json", "github.com/go-chi/chi/v5/middleware"]
      },
      "dependents": ["mcp-server-patterns", "structured-logging-c8"],
      "norms_priority": {
        "execution_order": ["C4", "C3", "C8", "C6", "C5"],
        "blocking_constraints": ["C3", "C4"],
        "rationale": "Secrets (C3) and tenant isolation (C4) enable secure API endpoints; structured logging (C8) requires correct auth context"
      },
      "interactions": {
        "with_validation": "API response schemas validated by schema-validator.py for JSON compliance",
        "with_config": "Auth patterns align with .env.example for credential management; rate limits with provider-router.yml",
        "with_programming": "Handler patterns reusable in javascript/ and python/ API implementations"
      }
    },
    {
      "artifact_id": "structured-logging-c8",
      "file": "structured-logging-c8.go.md",
      "canonical_path": "06-PROGRAMMING/go/structured-logging-c8.go.md",
      "constraints_mapped": ["C4","C5","C7","C8"],
      "examples_count": 25,
      "score_baseline": 92,
      "pedagogical_features": {
        "json_log_format_explained": true,
        "stderr_vs_stdout_guide": true,
        "trace_id_propagation": true
      },
      "dependencies": {
        "source_reference": ["05-CONFIGURATIONS/observability/otel-tracing-config.yaml"],
        "validators": ["verify-constraints.sh"],
        "norms": ["harness-norms-v3.0.md#C8"],
        "tools": ["log/slog", "encoding/json", "context.Value"]
      },
      "dependents": ["orchestrator-engine", "microservices-tenant-isolation", "api-client-management"],
      "norms_priority": {
        "execution_order": ["C4", "C8", "C7", "C5"],
        "blocking_constraints": ["C4"],
        "rationale": "Tenant_id in logs (C4) is foundational; structured format (C8) enables observability pipelines"
      },
      "interactions": {
        "with_validation": "Log output validated by verify-constraints.sh for JSON structure and required fields",
        "with_config": "Aligns with otel-tracing-config.yaml for trace_id propagation; uses .env.example for log level config",
        "with_programming": "Logging patterns reusable across all Go artifacts; reference for bash/python structured logging"
      }
    },
    {
      "artifact_id": "secrets-management-c3",
      "file": "secrets-management-c3.go.md",
      "canonical_path": "06-PROGRAMMING/go/secrets-management-c3.go.md",
      "constraints_mapped": ["C3","C4","C7","C8"],
      "examples_count": 25,
      "score_baseline": 91,
      "pedagogical_features": {
        "env_var_loading_explained": true,
        "missing_var_handling": true,
        "masking_in_logs": true
      },
      "dependencies": {
        "source_reference": ["02-SKILLS/SEGURIDAD/backup-encryption.md"],
        "validators": ["audit-secrets.sh", "verify-constraints.sh"],
        "norms": ["harness-norms-v3.0.md#C3"],
        "tools": ["os.Getenv", "os.LookupEnv", "strings.Replacer"]
      },
      "dependents": ["orchestrator-engine", "api-client-management", "saas-deployment-zip-auto"],
      "norms_priority": {
        "execution_order": ["C3", "C4", "C8", "C7"],
        "blocking_constraints": ["C3"],
        "rationale": "Zero hardcode (C3) is security-critical; tenant isolation (C4) ensures secrets are scoped correctly"
      },
      "interactions": {
        "with_validation": "Secret patterns validated by audit-secrets.sh for ${VAR:?missing} compliance",
        "with_config": "Uses .env.example placeholder patterns; aligns with backup-encryption.md for credential handling",
        "with_programming": "Secret loading patterns reusable in all Go artifacts; reference for bash/python secrets management"
      }
    },
    {
      "artifact_id": "resource-limits-c1-c2",
      "file": "resource-limits-c1-c2.go.md",
      "canonical_path": "06-PROGRAMMING/go/resource-limits-c1-c2.go.md",
      "constraints_mapped": ["C1","C2","C4","C7"],
      "examples_count": 25,
      "score_baseline": 87,
      "pedagogical_features": {
        "mem_limit_explained": true,
        "timeout_mechanism": true,
        "pids_limit_context": true
      },
      "dependencies": {
        "source_reference": ["01-RULES/02-RESOURCE-GUARDRAILS.md"],
        "validators": ["verify-constraints.sh"],
        "norms": ["harness-norms-v3.0.md#C1,C2"],
        "tools": ["runtime/debug", "context.WithTimeout", "syscall"]
      },
      "dependents": ["orchestrator-engine", "saas-deployment-zip-auto"],
      "norms_priority": {
        "execution_order": ["C1", "C2", "C4", "C7"],
        "blocking_constraints": ["C1", "C2"],
        "rationale": "Resource limits (C1/C2) prevent DoS; tenant scoping (C4) ensures limits are per-tenant"
      },
      "interactions": {
        "with_validation": "Limit enforcement validated by verify-constraints.sh for compliance with docker-compose constraints",
        "with_config": "Aligns with docker-compose mem_limit/cpus; uses .env.example for configurable limits",
        "with_programming": "Resource patterns reusable in all Go artifacts; reference for bash/python resource management"
      }
    },
    {
      "artifact_id": "error-handling-c7",
      "file": "error-handling-c7.go.md",
      "canonical_path": "06-PROGRAMMING/go/error-handling-c7.go.md",
      "constraints_mapped": ["C4","C5","C7","C8"],
      "examples_count": 25,
      "score_baseline": 89,
      "pedagogical_features": {
        "error_wrapping_explained": true,
        "retry_mechanism_guide": true,
        "fallback_patterns": true
      },
      "dependencies": {
        "source_reference": ["06-PROGRAMMING/bash/robust-error-handling.md"],
        "validators": ["verify-constraints.sh"],
        "norms": ["harness-norms-v3.0.md#C7"],
        "tools": ["errors", "fmt.Errorf", "time.Sleep"]
      },
      "dependents": ["orchestrator-engine", "microservices-tenant-isolation", "api-client-management"],
      "norms_priority": {
        "execution_order": ["C4", "C7", "C8", "C5"],
        "blocking_constraints": ["C4", "C7"],
        "rationale": "Tenant-aware errors (C4) enable correct routing; structured error handling (C7) prevents leaks"
      },
      "interactions": {
        "with_validation": "Error patterns validated by verify-constraints.sh for structured output and tenant scoping",
        "with_config": "Aligns with orchestrator-engine.sh error handling; uses structured logging patterns from C8 artifact",
        "with_programming": "Error handling patterns reusable in all Go artifacts; reference for bash/python error management"
      }
    }
  ],
  "dependency_graph": {
    "validation_layer": {
      "orchestrator-engine.sh": ["all go/ artifacts"],
      "verify-constraints.sh": ["all go/ artifacts"],
      "audit-secrets.sh": ["secrets-management-c3", "api-client-management"],
      "schema-validator.py": ["mcp-server-patterns", "api-client-management"]
    },
    "norms_layer": {
      "harness-norms-v3.0.md": ["all go/ artifacts"],
      "10-SDD-CONSTRAINTS.md": ["all go/ artifacts"],
      "language-lock-protocol.md": ["all go/ artifacts"],
      "norms-matrix.json": ["all go/ artifacts"]
    },
    "config_layer": {
      ".env.example": ["secrets-management-c3", "structured-logging-c8", "resource-limits-c1-c2"],
      "skill-template.md": ["all go/ artifacts"],
      "otel-tracing-config.yaml": ["structured-logging-c8"]
    }
  },
  "norms_execution_priority": {
    "global_order": ["C4", "C3", "C7", "C5", "C8", "C1", "C2", "C6"],
    "rationale": "C4 (tenant isolation) is foundational; security (C3) and safety (C7) precede structural (C5) and observability (C8) checks; resource limits (C1/C2) and executable validation (C6) are final gates",
    "blocking_set": ["C3", "C4", "C7"],
    "non_blocking_set": ["C1", "C2", "C5", "C6", "C8"],
    "selective_v_logic": {
      "applies_to": "postgresql-pgvector/ ONLY",
      "trigger": "artifact_type == 'skill_pgvector' AND content has pgvector operators",
      "exclusion": "go/ ALWAYS excludes V1/V2/V3 per LANGUAGE LOCK"
    }
  },
  "language_lock_enforcement": {
    "folder": "06-PROGRAMMING/go/",
    "prohibited_patterns": ["<->", "<=>", "<#>", "vector\\([0-9]+\\)", "USING\\s+(hnsw|ivfflat)", "SELECT.*FROM.*pg_"],
    "required_artifact_types": ["skill_go", "skill_index"],
    "prohibited_constraints": ["V1", "V2", "V3"],
    "validation_script": "validate-skill-integrity.sh --check-language-lock",
    "failure_action": "exit 2 with message 'LANGUAGE LOCK VIOLATION: pgvector operators not permitted in go/'"
  },
  "pedagogical_metadata": {
    "target_audience": "Developers learning Go with focus on MANTIS AGENTIC patterns",
    "prerequisite_knowledge": "Basic programming concepts; bash familiarity helpful but not required",
    "learning_path": [
      "1. structured-logging-c8.go.md (foundational C8 patterns)",
      "2. secrets-management-c3.go.md (security fundamentals)",
      "3. resource-limits-c1-c2.go.md (operational guardrails)",
      "4. error-handling-c7.go.md (robustness patterns)",
      "5. orchestrator-engine.go.md (integration of all constraints)",
      "6. mcp-server-patterns.go.md (advanced MCP integration)",
      "7. microservices-tenant-isolation.go.md (multi-tenant architecture)",
      "8. saas-deployment-zip-auto.go.md (deployment automation)",
      "9. api-client-management.go.md (client-facing API patterns)"
    ],
    "comment_convention": "// 👇 EXPLICACIÓN: texto en español que describe qué hace la línea y por qué es importante",
    "example_format": "✅ Patrón válido / ❌ Anti-pattern / 🔧 Fix corregido – todos con ≤5 líneas ejecutables"
  },
  "ai_navigation_hints": {
    "for_generation": "Read this index FIRST before generating new go/ artifacts; follow pedagogical_metadata.learning_path",
    "for_validation": "Use norms_execution_priority to order constraint checks; enforce LANGUAGE LOCK via validate-skill-integrity.sh",
    "for_learning": "Start with structured-logging-c8.go.md and secrets-management-c3.go.md for foundational Go patterns",
    "for_debugging": "Check language_lock_enforcement if pgvector/SQL operators appear in go/ artifacts; verify comments follow // 👇 EXPLICACIÓN convention"
  }
}
```

---
