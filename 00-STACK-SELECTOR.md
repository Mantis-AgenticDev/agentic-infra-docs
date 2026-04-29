---
canonical_path: "/00-STACK-SELECTOR.md"
artifact_id: "stack-selector-kernel"
artifact_type: "routing_kernel"
version: "2.0.0-PURE-JSON"
mode_gate_required: false
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","V1","V2","V3"]
tier: 3
immutable: true
requires_human_approval_for_changes: true
read_order: 2
read_after: ["IA-QUICKSTART.md"]
read_before_generation: true
ai_role: "routing_oracle"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 00-STACK-SELECTOR.md --mode headless --json"
checksum_sha256: "PENDING_GENERATION"
llm_oriental_optimized: true
human_readable: false
audience: ["agentic_assistants"]
---

```json
{
  "stack_selector_kernel": {

    "metadata": {
      "artifact_id": "stack-selector-kernel",
      "version": "2.0.0-PURE-JSON",
      "artifact_type": "routing_kernel",
      "canonical_path": "/00-STACK-SELECTOR.md",
      "read_order": 2,
      "read_after": "IA-QUICKSTART.md",
      "read_before_generation": true,
      "ai_role": "routing_oracle",
      "purpose": "Single source of truth for: language resolution, agent assignment, constraint mapping, harness selection, infra profiling, and language override governance.",
      "anti_drift_policy": "This file is the ONLY place where language and agent decisions are made. Any deviation must be recorded as AUDIT_FLAG=routing_override with justification.",
      "human_readable": false,
      "changes_in_this_version": "Full rewrite as pure JSON routing kernel. Separated from IA-QUICKSTART. Added language override governance, agent fiscalization, token budget policy, and session token resolution."
    },

    "session_token_resolution": {
      "description": "Resolves all dynamic tokens required before any bundle can be loaded. Must execute BEFORE any artifact generation.",
      "tokens": {
        "{ia_name}": {
          "resolution_order": 0,
          "source": "user_input_at_session_start",
          "prompt": "Identificador de sesión para esta IA (ej: claude-session-01, qwen-dev-02)",
          "default": "ia-unnamed",
          "used_in": ["chronique_protocol", "audit_logs", "08-LOGS/chronique-ia/{ia_name}/"],
          "on_missing": "use_default_and_flag: AUDIT_FLAG=ia_name_not_provided"
        },
        "{language}": {
          "resolution_order": 1,
          "source": "routing_rules",
          "resolution_method": "match task description + target path against routing_rules[*].pattern",
          "fallback_chain": [
            "1. Explicit path match in routing_rules",
            "2. Task keyword match in language_keyword_map",
            "3. User explicit request → validate against override_governance",
            "4. HALT_AND_AUDIT if no match"
          ],
          "on_missing": "HALT_AND_AUDIT: 'No se pudo resolver {language}. Proveer ruta canónica destino o descripción de tarea.'",
          "on_invalid": "HALT_AND_AUDIT: 'Lenguaje {value} no registrado en agent_registry.'"
        },
        "{vertical_slug}": {
          "resolution_order": 2,
          "source": "user_selection_in_ACG_step_2",
          "transform": "kebab-case lowercase",
          "examples": {
            "Odontología": "odontologia",
            "Hotel/Posada": "hotel-posada",
            "Restaurantes": "restaurantes",
            "Instagram/Redes Sociales": "instagram-social-media",
            "Corporate-KB": "corporate-kb"
          },
          "on_missing": "use_default: corporate-kb and flag: AUDIT_FLAG=vertical_not_specified"
        }
      },
      "execution_guarantee": "ALL tokens resolved BEFORE loading any bundle. Token resolution failure = HALT. No partial loads."
    },

    "agent_registry": {
      "description": "Canonical registry of all available master agents. Source of truth for agent loading.",
      "agents": {
        "bash": {
          "id": "bash",
          "master_agent_path": "06-PROGRAMMING/bash/bash-master-agent.md",
          "language": "Bash",
          "version_lock": ">=5.0",
          "domain": "scripting, automation, CI/CD, deploy",
          "tier_affinity": [1, 2, 3],
          "mode_affinity": ["A2", "A3", "B2", "B3"],
          "can_be_primary_in": ["A3", "B3"],
          "can_be_support_in": ["A1", "A2", "B1", "B2"],
          "harness": ["shellcheck", "audit-secrets.sh"],
          "language_lock": {
            "deny_operators": ["pgvector_operators", "<->", "<=>", "<#", "vector(n)", "USING hnsw", "USING ivfflat"],
            "deny_constraints": ["V1", "V2", "V3"],
            "violation_action": "BLOCKING: LANGUAGE_LOCK_VIOLATION"
          },
          "infra_constraints": {
            "reads_from_env": ["MANTIS_MEMORY_LIMIT_MB", "MANTIS_CPU_LIMIT", "MANTIS_INFRA_PROFILE"],
            "never_hardcode": ["mem_limit", "cpu_quota", "timeout_seconds"]
          },
          "status": "REAL"
        },
        "go": {
          "id": "go",
          "master_agent_path": "06-PROGRAMMING/go/go-master-agent.md",
          "language": "Go",
          "version_lock": ">=1.21",
          "domain": "microservices, high-concurrency, binary compilation, orchestration",
          "tier_affinity": [2, 3],
          "mode_affinity": ["A2", "A3", "B2", "B3"],
          "can_be_primary_in": ["A2", "B2"],
          "can_be_support_in": ["A3", "B3"],
          "harness": ["gofmt", "govulncheck", "verify-constraints.sh --check-language-lock", "audit-secrets.sh"],
          "language_lock": {
            "deny_operators": ["<->", "<=>", "<#", "vector(n)", "USING hnsw", "USING ivfflat", "pgx.Vector", "cosine_distance"],
            "deny_constraints": ["V1", "V2", "V3"],
            "deny_imports": ["pgvector", "pgvector-go"],
            "violation_action": "BLOCKING: LANGUAGE_LOCK_VIOLATION + suggest_pgvector_domain"
          },
          "infra_constraints": {
            "reads_from_env": ["MANTIS_MEMORY_LIMIT_MB", "MANTIS_CPU_LIMIT"],
            "binary_output": true,
            "static_linking_preferred": true
          },
          "status": "REAL"
        },
        "javascript": {
          "id": "javascript",
          "master_agent_path": "06-PROGRAMMING/javascript/javascript-typescript-master-agent.md",
          "language": "TypeScript",
          "version_lock": "Node.js >=18 LTS, TypeScript >=5.0",
          "domain": "webhooks, n8n Code Nodes, frontend, REST APIs",
          "tier_affinity": [2, 3],
          "mode_affinity": ["A2", "B2", "B3"],
          "can_be_primary_in": ["B2"],
          "can_be_support_in": ["A2", "A3", "B3"],
          "harness": ["eslint", "tsc --noEmit", "audit-secrets.sh"],
          "language_lock": {
            "deny_operators": ["pgvector_operators", "<->", "<=>", "<#", "vector(n)"],
            "deny_constraints": ["V1", "V2", "V3"],
            "violation_action": "BLOCKING: LANGUAGE_LOCK_VIOLATION"
          },
          "status": "REAL"
        },
        "postgresql-pgvector": {
          "id": "postgresql-pgvector",
          "master_agent_path": "06-PROGRAMMING/postgresql-pgvector/postgresql-pgvector-rag-master-agent.md",
          "language": "SQL + pgvector extension",
          "version_lock": "PostgreSQL >=15, pgvector >=0.5.0",
          "domain": "vector search, RAG pipelines, hybrid search, embedding storage",
          "tier_affinity": [2, 3],
          "mode_affinity": ["A2", "B2", "B3"],
          "can_be_primary_in": ["A2", "B2"],
          "can_be_support_in": ["B3"],
          "harness": ["verify-constraints.sh --check-vector-dims", "check-rls.sh", "schema-validator.py"],
          "language_lock": {
            "exclusive_domain": "06-PROGRAMMING/postgresql-pgvector/",
            "allowed_operators": ["<->", "<=>", "<#>", "vector(n)", "USING hnsw", "USING ivfflat"],
            "requires_artifact_type": "skill_pgvector",
            "requires_tenant_isolation": true,
            "violation_action": "N/A — this is the only domain where pgvector operators are permitted"
          },
          "mandatory_constraints": ["V1", "V3"],
          "optional_constraints": ["V2"],
          "status": "REAL"
        },
        "python": {
          "id": "python",
          "master_agent_path": "06-PROGRAMMING/python/python-master-agent.md",
          "language": "Python",
          "version_lock": ">=3.11",
          "domain": "AI/ML pipelines, LangChain, FastAPI, data processing, RAG orchestration",
          "tier_affinity": [2, 3],
          "mode_affinity": ["A2", "B2", "B3"],
          "can_be_primary_in": ["A2", "B2"],
          "can_be_support_in": ["A1", "B1", "B3"],
          "harness": ["mypy", "ruff", "schema-validator.py", "audit-secrets.sh"],
          "language_lock": {
            "deny_operators": ["pgvector_operators", "<->", "<=>", "<#", "vector(n)"],
            "deny_constraints": ["V1", "V2", "V3"],
            "note": "Python may call pgvector via psycopg2/asyncpg but vector operators are SQL-level, routed to postgresql-pgvector agent",
            "violation_action": "BLOCKING: LANGUAGE_LOCK_VIOLATION + route_to_pgvector_agent"
          },
          "status": "REAL"
        },
        "sql": {
          "id": "sql",
          "master_agent_path": "06-PROGRAMMING/sql/sql-master-agent.md",
          "language": "SQL (standard)",
          "version_lock": "ANSI SQL + PostgreSQL 15 / MySQL 8",
          "domain": "schema design, migrations, reporting, tenant-safe queries",
          "tier_affinity": [1, 2],
          "mode_affinity": ["A1", "A2", "B1", "B2"],
          "can_be_primary_in": ["A2", "B2"],
          "can_be_support_in": ["A1", "B1", "B3"],
          "harness": ["check-rls.sh", "audit-secrets.sh"],
          "language_lock": {
            "deny_operators": ["<->", "<=>", "<#>", "vector(n)", "USING hnsw", "USING ivfflat"],
            "deny_constraints": ["V1", "V2", "V3"],
            "violation_action": "BLOCKING: LANGUAGE_LOCK_VIOLATION + suggest_pgvector_domain"
          },
          "status": "REAL"
        },
        "yaml-json-schema": {
          "id": "yaml-json-schema",
          "master_agent_path": "06-PROGRAMMING/yaml-json-schema/yaml-json-schema-master-agent.md",
          "language": "YAML + JSON Schema",
          "version_lock": "YAML 1.2, JSON Schema Draft 2020-12",
          "domain": "configuration, frontmatter, schemas, docker-compose, terraform variables, n8n exports",
          "tier_affinity": [1, 2, 3],
          "mode_affinity": ["A1", "A2", "A3", "B1", "B2", "B3"],
          "can_be_primary_in": ["A1", "B1"],
          "can_be_support_in": ["A2", "A3", "B2", "B3"],
          "harness": ["yamllint", "validate-frontmatter.sh", "schema-validator.py"],
          "language_lock": {
            "deny_operators": ["pgvector_operators"],
            "deny_constraints": ["V1", "V2", "V3"],
            "violation_action": "BLOCKING: LANGUAGE_LOCK_VIOLATION"
          },
          "status": "REAL"
        }
      }
    },

    "mode_agent_matrix": {
      "description": "Deterministic mapping of mode to agent invocation. Primary agent is loaded first, support agents loaded only if task requires them. Fiscalization rules prevent unauthorized agent substitution.",
      "matrix": {
        "A1": {
          "primary_agent": "yaml-json-schema",
          "support_agents": ["bash"],
          "task_type": "documentation_structural_analysis",
          "dominant_artifacts": [".md", ".json", ".yaml", "canonical_registry", "indexes"],
          "harness_mandatory": ["validate-frontmatter.sh", "check-wikilinks.sh"],
          "harness_optional": ["verify-constraints.sh --checks C5"],
          "forbidden_agents": ["go", "python", "javascript", "sql", "postgresql-pgvector"],
          "forbidden_reason": "A1 produces documentation artifacts only. Executable code agents are outside scope.",
          "infra_constraint_active": false,
          "language_override_policy": "DENY — A1 does not produce executable code. Override requests must redirect to A2.",
          "delivery_format": "screen + human_review"
        },
        "A2": {
          "primary_agent": "{language}",
          "support_agents": ["bash", "yaml-json-schema"],
          "task_type": "code_generation_with_harness",
          "dominant_artifacts": [".go", ".py", ".ts", ".sql", ".sh", "tests", "migrations"],
          "harness_mandatory": ["orchestrator-engine.sh", "verify-constraints.sh", "audit-secrets.sh"],
          "harness_optional": ["schema-validator.py", "check-rls.sh"],
          "forbidden_agents": [],
          "language_override_policy": "ADVISORY — if user requests a language different from routing_rules resolution, evaluate via override_governance before accepting.",
          "infra_constraint_active": true,
          "infra_allowed": ["nano", "micro"],
          "infra_blocked": ["standard", "large"],
          "delivery_format": "code + validation_command + sha256"
        },
        "A3": {
          "primary_agent": "bash",
          "support_agents": ["yaml-json-schema"],
          "task_type": "ci_cd_infra_deploy",
          "dominant_artifacts": [".tf", ".yml", ".sh", "docker-compose.yml", "deploy.zip"],
          "harness_mandatory": ["health-check.sh", "packager-assisted.sh", "orchestrator-engine.sh"],
          "harness_optional": ["sync-to-sandbox.sh"],
          "required_output_artifacts": ["deploy.sh", "rollback.sh", "manifest.json"],
          "forbidden_agents": ["python", "javascript"],
          "forbidden_reason": "A3 produces infrastructure artifacts. Python/JS have no role in IaC output.",
          "language_override_policy": "DENY — A3 stack is bash+yaml+terraform. No override accepted.",
          "infra_constraint_active": true,
          "infra_allowed": ["nano", "micro"],
          "infra_blocked": ["standard", "large"],
          "delivery_format": "zip + manifest.json + deploy.sh + rollback.sh"
        },
        "B1": {
          "primary_agent": "yaml-json-schema",
          "support_agents": [],
          "task_type": "proposal_architecture_planning",
          "dominant_artifacts": ["proposal.md", "architecture-diagram.mermaid", "bootstrap-company-context.json"],
          "harness_mandatory": ["validate-frontmatter.sh"],
          "harness_optional": ["check-wikilinks.sh"],
          "forbidden_agents": ["go", "python", "javascript", "bash", "sql", "postgresql-pgvector"],
          "forbidden_reason": "B1 produces planning artifacts only. No executable code.",
          "language_override_policy": "DENY — B1 does not produce code. Redirect to B2 if code is required.",
          "infra_constraint_active": false,
          "required_context": "05-CONFIGURATIONS/templates/bootstrap-company-context.json",
          "delivery_format": "screen + client_review"
        },
        "B2": {
          "primary_agent": "{language}",
          "support_agents": ["sql", "postgresql-pgvector"],
          "task_type": "integrable_code_with_validation",
          "dominant_artifacts": ["source_code", "tests", "docker-compose.dev.yml"],
          "harness_mandatory": ["orchestrator-engine.sh", "check-rls.sh", "audit-secrets.sh"],
          "harness_optional": ["schema-validator.py", "shellcheck"],
          "rag_trigger": {
            "condition": "task_description contains any of: ['RAG', 'vector', 'embedding', 'similarity', 'pgvector', 'semantic search']",
            "action": "add postgresql-pgvector to support_agents",
            "audit_flag": "rag_agent_activated"
          },
          "forbidden_agents": [],
          "language_override_policy": "ADVISORY — evaluate via override_governance. Senior engineer must justify deviation from routing_rules.",
          "infra_constraint_active": true,
          "infra_profile_defaults": {
            "B2": "nano",
            "override_allowed_to": "micro"
          },
          "delivery_format": "integrable_code + validation_command + sha256"
        },
        "B3": {
          "primary_agent": "bash",
          "support_agents": ["yaml-json-schema", "sql"],
          "task_type": "production_delivery_llave_en_mano",
          "dominant_artifacts": [".zip", "deploy.sh", "rollback.sh", "manifest.json", "docker-compose.prod.yml"],
          "harness_mandatory": ["health-check.sh", "packager-assisted.sh", "orchestrator-engine.sh", "audit-secrets.sh"],
          "harness_optional": ["check-rls.sh", "schema-validator.py"],
          "required_output_artifacts": ["deploy.sh", "rollback.sh", "manifest.json", "README-DEPLOY.md", "checksums.sha256"],
          "forbidden_agents": ["python", "javascript"],
          "forbidden_reason": "B3 is a delivery package. Python/JS are source concerns, not delivery concerns.",
          "language_override_policy": "DENY — B3 delivery stack is fixed. No override accepted.",
          "infra_constraint_active": true,
          "infra_profile_default": "micro",
          "delivery_format": "production_zip + manifest + deploy_scripts"
        }
      }
    },

    "routing_rules": {
      "description": "Deterministic path-to-language mapping. Evaluated top-down, first match wins. Priority field breaks ties.",
      "resolution_algorithm": "1. Match canonical path → exact or prefix. 2. Match task_keywords. 3. Match file extension. 4. Invoke override_governance if no match or conflict.",
      "rules": [
        {
          "id": "RR-01",
          "priority": 100,
          "condition": "path_starts_with",
          "patterns": ["00-CONTEXT/", "01-RULES/", "docs/"],
          "language": "markdown",
          "extension": ".md",
          "agent": "yaml-json-schema",
          "constraints_mandatory": ["C5"],
          "constraints_applicable": ["C8"],
          "constraints_hard_block": ["V1", "V2", "V3"],
          "language_lock_violation": ["pgvector_operators"],
          "harness": ["check-wikilinks.sh", "validate-frontmatter.sh"],
          "infra_profile_irrelevant": true,
          "task_keywords": ["documentation", "rules", "norms", "context", "readme"]
        },
        {
          "id": "RR-02",
          "priority": 100,
          "condition": "path_contains",
          "patterns": ["02-SKILLS/"],
          "language": "markdown",
          "extension": ".md",
          "agent": "yaml-json-schema",
          "constraints_mandatory": ["C5"],
          "constraints_applicable": ["C3", "C4", "C8"],
          "constraints_hard_block": ["V1", "V2", "V3"],
          "harness": ["validate-frontmatter.sh", "validate-skill-integrity.sh"],
          "infra_profile_irrelevant": true,
          "task_keywords": ["skill", "skill file", "base de datos", "RAG skill", "documentation skill"]
        },
        {
          "id": "RR-03",
          "priority": 95,
          "condition": "path_contains",
          "patterns": ["06-PROGRAMMING/go/"],
          "language": "go",
          "extension": ".go",
          "agent": "go",
          "constraints_mandatory": ["C1", "C2", "C3", "C4", "C5", "C7", "C8"],
          "constraints_applicable": ["C6"],
          "constraints_hard_block": ["V1", "V2", "V3"],
          "language_lock_violation": ["<->", "<=>", "<#>", "vector(n)", "USING hnsw", "USING ivfflat", "pgx.Vector", "pgvector"],
          "harness": ["gofmt", "govulncheck", "verify-constraints.sh --check-language-lock --dir 06-PROGRAMMING/go/", "audit-secrets.sh"],
          "infra_notes": "C1/C2 limits read from MANTIS_MEMORY_LIMIT_MB and MANTIS_CPU_LIMIT env vars. Never hardcode.",
          "task_keywords": ["microservice", "binary", "orchestrator", "go service", "high concurrency", "saas-deployment", "packager"]
        },
        {
          "id": "RR-04",
          "priority": 95,
          "condition": "path_contains",
          "patterns": ["06-PROGRAMMING/postgresql-pgvector/", "02-SKILLS/BASE DE DATOS-RAG/"],
          "language": "sql_pgvector",
          "extension": ".sql",
          "agent": "postgresql-pgvector",
          "constraints_mandatory": ["C3", "C4", "V1", "V3"],
          "constraints_applicable": ["C1", "C2", "C5", "C7", "C8", "V2"],
          "constraints_hard_block": [],
          "language_lock_violation": "NONE — exclusive pgvector domain",
          "allowed_operators": ["<->", "<=>", "<#>", "vector(n)", "USING hnsw", "USING ivfflat"],
          "harness": ["verify-constraints.sh --check-vector-dims --check-vector-index", "check-rls.sh", "schema-validator.py"],
          "requires_artifact_type": "skill_pgvector",
          "requires_tenant_isolation": true,
          "task_keywords": ["RAG", "vector", "embedding", "similarity search", "pgvector", "semantic search", "hybrid search", "RRF", "cosine distance"]
        },
        {
          "id": "RR-05",
          "priority": 95,
          "condition": "path_contains",
          "patterns": ["06-PROGRAMMING/python/"],
          "language": "python",
          "extension": ".py",
          "agent": "python",
          "constraints_mandatory": ["C1", "C3", "C4", "C5"],
          "constraints_applicable": ["C2", "C6", "C7", "C8"],
          "constraints_hard_block": ["V1", "V2", "V3"],
          "language_lock_violation": ["pgvector_operators_in_python_code"],
          "language_lock_note": "Python may call pgvector via psycopg2/asyncpg. Vector operators are SQL-level — route SQL fragment to postgresql-pgvector agent. Python code itself must not contain raw pgvector operator strings.",
          "harness": ["mypy", "ruff", "schema-validator.py", "audit-secrets.sh"],
          "task_keywords": ["langchain", "langgraph", "fastapi", "pydantic", "openrouter", "pipeline", "rag orchestration", "webhook python"]
        },
        {
          "id": "RR-06",
          "priority": 95,
          "condition": "path_contains",
          "patterns": ["06-PROGRAMMING/javascript/"],
          "language": "typescript",
          "extension": ".ts",
          "agent": "javascript",
          "constraints_mandatory": ["C3", "C4", "C5"],
          "constraints_applicable": ["C1", "C2", "C6", "C7", "C8"],
          "constraints_hard_block": ["V1", "V2", "V3"],
          "language_lock_violation": ["pgvector_operators"],
          "harness": ["eslint", "tsc --noEmit", "audit-secrets.sh"],
          "task_keywords": ["n8n code node", "webhook", "typescript", "javascript", "node.js", "express", "rest api js"]
        },
        {
          "id": "RR-07",
          "priority": 95,
          "condition": "path_contains",
          "patterns": ["06-PROGRAMMING/sql/"],
          "language": "sql",
          "extension": ".sql",
          "agent": "sql",
          "constraints_mandatory": ["C3", "C4"],
          "constraints_applicable": ["C5", "C7", "C8"],
          "constraints_hard_block": ["V1", "V2", "V3"],
          "language_lock_violation": ["<->", "<=>", "<#>", "vector(n)", "USING hnsw", "USING ivfflat"],
          "harness": ["check-rls.sh", "audit-secrets.sh"],
          "task_keywords": ["schema", "migration", "tenant query", "reporting", "stored procedure", "standard sql", "rls", "row level security"]
        },
        {
          "id": "RR-08",
          "priority": 95,
          "condition": "path_contains",
          "patterns": ["06-PROGRAMMING/bash/", "05-CONFIGURATIONS/scripts/"],
          "language": "bash",
          "extension": ".sh",
          "agent": "bash",
          "constraints_mandatory": ["C1", "C2", "C3", "C7"],
          "constraints_applicable": ["C4", "C5", "C6", "C8"],
          "constraints_hard_block": ["V1", "V2", "V3"],
          "language_lock_violation": ["pgvector_operators"],
          "harness": ["shellcheck", "audit-secrets.sh", "verify-constraints.sh"],
          "task_keywords": ["script", "shell", "bash", "automation", "cron", "deploy script", "health check", "backup", "sync"]
        },
        {
          "id": "RR-09",
          "priority": 90,
          "condition": "path_contains",
          "patterns": ["05-CONFIGURATIONS/docker-compose/"],
          "language": "yaml",
          "extension": ".yml",
          "agent": "yaml-json-schema",
          "constraints_mandatory": ["C1", "C2", "C3", "C4", "C7", "C8"],
          "constraints_applicable": ["C5"],
          "constraints_hard_block": ["V1", "V2", "V3"],
          "language_lock_violation": ["pgvector_operators"],
          "harness": ["yamllint", "validate-frontmatter.sh"],
          "task_keywords": ["docker compose", "container", "service definition", "compose file", "vps config"]
        },
        {
          "id": "RR-10",
          "priority": 90,
          "condition": "path_contains",
          "patterns": ["05-CONFIGURATIONS/terraform/", "05-CONFIGURATIONS/terraform/modules/"],
          "language": "hcl",
          "extension": ".tf",
          "agent": "yaml-json-schema",
          "constraints_mandatory": ["C1", "C2", "C3", "C7"],
          "constraints_applicable": ["C4", "C5", "C8"],
          "constraints_hard_block": ["V1", "V2", "V3"],
          "language_lock_violation": ["pgvector_operators"],
          "harness": ["terraform validate", "tflint", "audit-secrets.sh"],
          "terraform_rules": {
            "sensitive_fields": "sensitive = true required for all credential outputs",
            "backend_state": "remote state only, never local",
            "variable_validation": "validation blocks mandatory for all input variables"
          },
          "task_keywords": ["terraform", "infrastructure as code", "IaC", "cloud provision", "module"]
        },
        {
          "id": "RR-11",
          "priority": 85,
          "condition": "path_contains",
          "patterns": ["06-PROGRAMMING/yaml-json-schema/", "05-CONFIGURATIONS/validation/schemas/"],
          "language": "yaml_json_schema",
          "extension": [".yaml", ".json"],
          "agent": "yaml-json-schema",
          "constraints_mandatory": ["C5"],
          "constraints_applicable": ["C3"],
          "constraints_hard_block": ["V1", "V2", "V3"],
          "language_lock_violation": ["pgvector_operators"],
          "harness": ["yamllint", "schema-validator.py"],
          "task_keywords": ["json schema", "yaml schema", "validation schema", "openapi", "schema definition"]
        },
        {
          "id": "RR-12",
          "priority": 80,
          "condition": "path_contains",
          "patterns": ["04-WORKFLOWS/n8n/"],
          "language": "json",
          "extension": ".json",
          "agent": "yaml-json-schema",
          "constraints_mandatory": ["C3", "C4", "C5"],
          "constraints_applicable": ["C7", "C8"],
          "constraints_hard_block": ["V1", "V2", "V3"],
          "language_lock_violation": ["pgvector_operators"],
          "harness": ["n8n-schema-validator.sh"],
          "task_keywords": ["n8n workflow", "n8n export", "workflow json", "automation flow"]
        }
      ]
    },

    "language_keyword_map": {
      "description": "Secondary resolution: if path is unavailable, match task description keywords to language. Lower confidence than routing_rules.",
      "confidence": "MEDIUM — always prefer routing_rules. This is fallback only.",
      "map": {
        "python": ["langchain", "langgraph", "fastapi", "pydantic", "openai sdk python", "rag python", "huggingface", "celery"],
        "go": ["gin", "cobra", "viper", "goroutine", "channel", "go binary", "microservice go", "gRPC", "go module"],
        "javascript": ["n8n code node", "typescript", "node.js", "express", "fetch api", "webhook ts"],
        "bash": ["shellscript", "bash script", "deploy.sh", "cron job", "health-check", "bash automation"],
        "sql": ["create table", "alter table", "migration sql", "rls policy", "row level security", "stored procedure", "view sql"],
        "postgresql-pgvector": ["cosine similarity", "embedding search", "pgvector", "hnsw", "ivfflat", "vector(", "RAG pipeline", "semantic search"],
        "yaml-json-schema": ["docker-compose", "compose file", "json schema", "yaml config", "frontmatter", "openapi spec", "terraform variables"]
      }
    },

    "override_governance": {
      "description": "Governs user requests to deviate from routing_rules agent assignment. AI must evaluate and respond according to this policy before accepting any override.",
      "policy_levels": {
        "DENY": {
          "applies_to_modes": ["A1", "A3", "B1", "B3"],
          "reason": "These modes have fixed agent stacks by architecture. Override breaks delivery contract.",
          "ai_response": "⛔ Modo {mode} tiene stack fijo: {fixed_stack}. No se acepta override de lenguaje. Si la tarea requiere {requested_language}, cambiar a modo {suggested_mode}.",
          "audit_flag": "override_denied_fixed_mode"
        },
        "ADVISORY": {
          "applies_to_modes": ["A2", "B2"],
          "process": [
            "1. Identify routing_rules match for current task.",
            "2. Compare requested_language vs routing_rules resolved language.",
            "3. Evaluate advisory_criteria.",
            "4. Emit structured advisory to user.",
            "5. Await explicit human confirmation before proceeding.",
            "6. Record decision in audit_log regardless of outcome."
          ],
          "advisory_criteria": [
            {
              "scenario": "requested_language has lower concurrency support than resolved_language",
              "example": "user requests Python instead of Go for high-concurrency microservice",
              "ai_advice": "⚠️ ADVISORY: {resolved_language} es preferido para este patrón ({reason}). {requested_language} es viable pero requiere: {mitigation}. ¿Confirma override? [S/N]"
            },
            {
              "scenario": "requested_language is not in agent_registry",
              "example": "user requests Rust, Ruby, Java",
              "ai_advice": "⛔ {requested_language} no está registrado en agent_registry. Lenguajes disponibles: {agent_registry.keys}. ¿Desea solicitar incorporación formal del lenguaje al proyecto?"
            },
            {
              "scenario": "requested_language violates LANGUAGE_LOCK for target path",
              "example": "user requests Python in 06-PROGRAMMING/go/",
              "ai_advice": "⛔ LANGUAGE_LOCK activo: {target_path} requiere {locked_language}. Override no permitido. Reubicar el artefacto o cambiar la ruta destino."
            },
            {
              "scenario": "requested_language is valid alternative for the task",
              "example": "user requests Go instead of Python for a FastAPI-style API",
              "ai_advice": "✅ ADVISORY: {requested_language} es una alternativa válida. Ventajas vs {resolved_language}: {pros}. Consideraciones: {cons}. Cargando agente {requested_language}. AUDIT_FLAG=language_override_accepted."
            }
          ],
          "audit_fields": ["original_resolved_language", "requested_language", "advisory_issued", "human_confirmed", "final_language", "justification"],
          "audit_flag_on_accept": "language_override_accepted",
          "audit_flag_on_reject": "language_override_rejected"
        }
      },
      "new_language_request_governance": {
        "description": "User requests a language not in agent_registry (e.g., Rust, Java, Ruby).",
        "ai_response_template": "⚠️ {language} no está registrado en agent_registry. Evaluación de viabilidad: {viability_assessment}. Para incorporar formalmente: (1) Crear master agent en 06-PROGRAMMING/{language}/. (2) Actualizar routing_rules en 00-STACK-SELECTOR.md. (3) Registrar LANGUAGE_LOCK. (4) Requiere aprobación humana (requires_human_approval_for_changes: true). ¿Proceder con evaluación de incorporación? [S/N]",
        "viability_assessment_criteria": [
          "Exists a mature ecosystem for the target domain?",
          "Does it offer advantages over current registered languages for this specific task?",
          "Is there a senior maintainer available for the new agent?",
          "Does it require changes to orchestrator-engine.sh harness?"
        ],
        "audit_flag": "new_language_incorporation_requested"
      }
    },

    "infra_profile_constraints": {
      "description": "Maps infra profiles to allowed patterns and code complexity limits. C1/C2 values are read from environment, never hardcoded.",
      "env_vars": {
        "MANTIS_INFRA_PROFILE": "nano | micro | standard | large",
        "MANTIS_MEMORY_LIMIT_MB": "4096 | 8192 | 16384 | 32768",
        "MANTIS_CPU_LIMIT": "1 | 2 | 4 | 8",
        "MANTIS_STORAGE_GB": "50 | 100 | 200 | 400",
        "MANTIS_BANDWIDTH_TB": "4 | 8 | 16 | 32"
      },
      "profiles": {
        "nano": {
          "id": 1,
          "alias": "infra1",
          "vcpu": 1,
          "ram_mb": 4096,
          "storage_gb": 50,
          "bandwidth_tb": 4,
          "max_complexity": "low",
          "allowed_patterns": ["monolith", "single-container", "sqlite-local"],
          "forbidden_patterns": ["distributed-tracing", "high-availability-clusters", "multi-db-sharding", "kafka", "kubernetes"],
          "c1_config": { "mem_limit": "${MANTIS_MEMORY_LIMIT_MB}M", "pids_limit": 50, "timeout_s": 30 },
          "c2_config": { "cpus": 0.5, "max_concurrent_requests": 10 },
          "mode_allowed": ["A1", "A2", "B1", "B2"],
          "mode_blocked": ["A3", "B3"],
          "mode_blocked_reason": "A3/B3 production deploy requires minimum micro profile."
        },
        "micro": {
          "id": 2,
          "alias": "infra2",
          "vcpu": 2,
          "ram_mb": 8192,
          "storage_gb": 100,
          "bandwidth_tb": 8,
          "max_complexity": "medium",
          "allowed_patterns": ["docker-compose", "sidecars", "n8n-whatsapp-agent", "qdrant-local", "postgres-rls"],
          "forbidden_patterns": ["multi-region-replication", "kubernetes", "kafka-cluster"],
          "c1_config": { "mem_limit": "${MANTIS_MEMORY_LIMIT_MB}M", "pids_limit": 100, "timeout_s": 60 },
          "c2_config": { "cpus": 1.0, "max_concurrent_requests": 30 },
          "mode_allowed": ["A1", "A2", "A3", "B1", "B2", "B3"]
        },
        "standard": {
          "id": 3,
          "alias": "infra3",
          "vcpu": 4,
          "ram_mb": 16384,
          "storage_gb": 200,
          "bandwidth_tb": 16,
          "max_complexity": "high",
          "allowed_patterns": ["multi-container", "pgvector-hnsw", "qdrant-cluster", "n8n-cluster", "redis-sidecar"],
          "forbidden_patterns": ["multi-region-replication"],
          "c1_config": { "mem_limit": "${MANTIS_MEMORY_LIMIT_MB}M", "pids_limit": 200, "timeout_s": 120 },
          "c2_config": { "cpus": 2.0, "max_concurrent_requests": 100 },
          "mode_allowed": ["A1", "A2", "A3", "B1", "B2", "B3"]
        },
        "large": {
          "id": 4,
          "alias": "infra4",
          "vcpu": 8,
          "ram_mb": 32768,
          "storage_gb": 400,
          "bandwidth_tb": 32,
          "max_complexity": "enterprise",
          "allowed_patterns": ["kubernetes", "multi-db-sharding", "distributed-tracing", "kafka", "multi-region"],
          "forbidden_patterns": [],
          "c1_config": { "mem_limit": "${MANTIS_MEMORY_LIMIT_MB}M", "pids_limit": 500, "timeout_s": 300 },
          "c2_config": { "cpus": 4.0, "max_concurrent_requests": 500 },
          "mode_allowed": ["A1", "A2", "A3", "B1", "B2", "B3"]
        }
      },
      "internal_modes_restriction": {
        "applies_to": ["A1", "A2", "A3"],
        "allowed_profiles": ["nano", "micro"],
        "blocked_profiles": ["standard", "large"],
        "blocked_reason": "Internal MANTIS development targets VPS environments. Standard/Large profiles are external client concerns.",
        "audit_flag_on_violation": "infra_profile_exceeds_internal_limit"
      }
    },

    "norm_execution_order": {
      "description": "Deterministic constraint application sequence. Fail-fast on critical constraints. Contextual constraints evaluated only if applicable to current domain.",
      "fail_fast_sequence": [
        {
          "constraint": "C3",
          "name": "Zero Hardcode Secrets",
          "check": "No passwords, tokens, API keys, connection strings in artifact body",
          "on_fail": "BLOCKING: C3_VIOLATION — immediate halt, no partial output",
          "validator": "audit-secrets.sh"
        },
        {
          "constraint": "C4",
          "name": "Tenant Isolation",
          "check": "Every query/operation scoped to tenant_id. No cross-tenant data access.",
          "on_fail": "BLOCKING: C4_VIOLATION — immediate halt",
          "validator": "check-rls.sh"
        },
        {
          "constraint": "C5",
          "name": "Structural Contract",
          "check": "Valid YAML frontmatter with required fields: canonical_path, artifact_id, version, constraints_mapped, validation_command, tier",
          "on_fail": "BLOCKING: C5_VIOLATION — frontmatter invalid or missing required fields",
          "validator": "validate-frontmatter.sh"
        }
      ],
      "standard_sequence": [
        {
          "constraint": "C1",
          "name": "Resource Limits",
          "check": "All resource limits read from env vars. No hardcoded values.",
          "on_fail": "WARNING: C1_SOFTFAIL — flag and continue if non-production"
        },
        {
          "constraint": "C6",
          "name": "Cloud-Only Inference",
          "check": "LLM endpoints use https://api.openrouter.ai/v1 or equivalent. No localhost:11434.",
          "on_fail": "BLOCKING: C6_VIOLATION in production artifacts"
        },
        {
          "constraint": "C2",
          "name": "Concurrency Control",
          "check": "Concurrency limits defined via env vars. No unbounded goroutines/threads.",
          "on_fail": "WARNING: C2_SOFTFAIL"
        },
        {
          "constraint": "C7",
          "name": "Resilience",
          "check": "Retry logic, circuit breakers, healthchecks present in service artifacts.",
          "on_fail": "WARNING: C7_SOFTFAIL in Tier 1. BLOCKING in Tier 3."
        },
        {
          "constraint": "C8",
          "name": "Observability",
          "check": "Structured JSON logging with trace_id propagation.",
          "on_fail": "WARNING: C8_SOFTFAIL"
        }
      ],
      "vector_sequence": {
        "applicable_when": "agent == postgresql-pgvector OR path contains postgresql-pgvector OR RAG trigger active",
        "constraints": [
          {
            "constraint": "V1",
            "name": "Vector Dimension Declaration",
            "check": "vector(N) declared with explicit N. Comment with embedding model name and provider.",
            "on_fail": "BLOCKING: V1_VIOLATION"
          },
          {
            "constraint": "V2",
            "name": "Distance Metric Explicit",
            "check": "Operator documented: <-> = L2, <=> = cosine, <#> = inner product.",
            "on_fail": "WARNING: V2_SOFTFAIL"
          },
          {
            "constraint": "V3",
            "name": "Index Type Justified",
            "check": "USING hnsw or USING ivfflat accompanied by justification comment with m, ef_construction params.",
            "on_fail": "BLOCKING: V3_VIOLATION in production artifacts"
          }
        ]
      },
      "language_lock_sequence": {
        "applicable_when": "always — evaluated before any code generation",
        "check": "Scanned artifact body for deny_operators and deny_constraints from agent_registry[language].language_lock",
        "on_fail": "BLOCKING: LANGUAGE_LOCK_VIOLATION — emit specific operator detected + suggest correct domain",
        "validator": "verify-constraints.sh --check-language-lock"
      }
    },

    "token_budget_policy": {
      "description": "Controls agent loading to prevent context window contamination and attention dilution. Anti-drift by design.",
      "rules": {
        "core_bundle_load": "Mandatory once at session start. Not reloaded unless context_refresh_protocol triggers.",
        "overlay_load": "Load ONLY the overlay matching active mode. Never load multiple mode overlays simultaneously.",
        "agent_load_policy": "Load primary agent first. Load support agents only when task explicitly requires them. Trigger: rag_trigger, explicit user mention, or routing_rules support requirement.",
        "never_load_simultaneously": [
          ["go master agent", "python master agent"],
          ["postgresql-pgvector master agent", "sql master agent"],
          ["A1 overlay", "A2 overlay"],
          ["A1 overlay", "A3 overlay"],
          ["B1 overlay", "B2 overlay"]
        ],
        "eviction_policy": {
          "trigger": "Estimated context usage > 75% of window",
          "action": [
            "Trigger chronique_protocol immediately regardless of turn count",
            "Evict current overlay from active context",
            "Retain: core_bundle, active agent, audit_flags",
            "Reload overlay selectively on next generation task",
            "AUDIT_FLAG=context_eviction_triggered"
          ]
        },
        "mode_change_policy": {
          "trigger": "User requests mode change within same session (e.g., A2 → B3)",
          "action": [
            "Re-execute ACG from step_1a_branch_selection",
            "Evict previous mode overlay",
            "Load new mode overlay",
            "Re-resolve {language} token if mode changes A→B or B→A",
            "AUDIT_FLAG=mode_change_mid_session"
          ]
        }
      }
    },

    "harness_registry": {
      "description": "Complete registry of all validation tools. Maps tool to invocation pattern and failure action.",
      "tools": {
        "orchestrator-engine.sh": {
          "path": "05-CONFIGURATIONS/validation/orchestrator-engine.sh",
          "invocation": "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {path} --mode headless --json",
          "checks": ["frontmatter", "constraints", "language_lock", "wikilinks"],
          "acceptance_criteria": { "score_minimum": 30, "blocking_issues": "empty", "language_lock_violations": 0 },
          "status": "REAL"
        },
        "verify-constraints.sh": {
          "path": "05-CONFIGURATIONS/validation/verify-constraints.sh",
          "invocation": "bash 05-CONFIGURATIONS/validation/verify-constraints.sh --check-language-lock --dir {dir}",
          "checks": ["language_lock", "constraint_mapping"],
          "status": "REAL"
        },
        "audit-secrets.sh": {
          "path": "05-CONFIGURATIONS/validation/audit-secrets.sh",
          "invocation": "bash 05-CONFIGURATIONS/validation/audit-secrets.sh --file {path}",
          "checks": ["C3_hardcoded_secrets", "env_var_usage"],
          "status": "REAL"
        },
        "check-rls.sh": {
          "path": "05-CONFIGURATIONS/validation/check-rls.sh",
          "invocation": "bash 05-CONFIGURATIONS/validation/check-rls.sh --file {path}",
          "checks": ["C4_tenant_isolation", "rls_policies"],
          "status": "REAL"
        },
        "check-wikilinks.sh": {
          "path": "05-CONFIGURATIONS/validation/check-wikilinks.sh",
          "invocation": "bash 05-CONFIGURATIONS/validation/check-wikilinks.sh --file {path}",
          "checks": ["wikilink_canonical_format", "broken_links"],
          "status": "REAL"
        },
        "validate-frontmatter.sh": {
          "path": "05-CONFIGURATIONS/validation/validate-frontmatter.sh",
          "invocation": "bash 05-CONFIGURATIONS/validation/validate-frontmatter.sh --file {path}",
          "checks": ["C5_required_fields", "yaml_validity"],
          "status": "REAL"
        },
        "validate-skill-integrity.sh": {
          "path": "05-CONFIGURATIONS/validation/validate-skill-integrity.sh",
          "invocation": "bash 05-CONFIGURATIONS/validation/validate-skill-integrity.sh --file {path}",
          "checks": ["skill_template_compliance", "section_completeness"],
          "status": "REAL"
        },
        "schema-validator.py": {
          "path": "05-CONFIGURATIONS/validation/schema-validator.py",
          "invocation": "python3 05-CONFIGURATIONS/validation/schema-validator.py --file {path} --schema {schema_path}",
          "checks": ["json_schema_validity", "required_properties"],
          "status": "REAL"
        },
        "shellcheck": {
          "path": "external_tool",
          "invocation": "shellcheck {path}",
          "checks": ["bash_syntax", "common_errors", "portability"],
          "status": "REAL"
        },
        "yamllint": {
          "path": "external_tool",
          "invocation": "yamllint {path}",
          "checks": ["yaml_syntax", "indentation", "trailing_spaces"],
          "status": "REAL"
        },
        "health-check.sh": {
          "path": "05-CONFIGURATIONS/scripts/health-check.sh",
          "invocation": "bash 05-CONFIGURATIONS/scripts/health-check.sh",
          "checks": ["service_availability", "endpoint_responsiveness"],
          "status": "REAL"
        },
        "packager-assisted.sh": {
          "path": "05-CONFIGURATIONS/scripts/packager-assisted.sh",
          "invocation": "bash 05-CONFIGURATIONS/scripts/packager-assisted.sh --mode {mode} --output {output_path}",
          "checks": ["manifest_completeness", "checksum_generation", "zip_integrity"],
          "status": "REAL"
        },
        "n8n-schema-validator.sh": {
          "path": "05-CONFIGURATIONS/validation/n8n-schema-validator.sh",
          "invocation": "bash 05-CONFIGURATIONS/validation/n8n-schema-validator.sh --file {path}",
          "checks": ["n8n_workflow_schema", "node_connectivity", "credential_references"],
          "status": "PLANNED"
        }
      }
    },

    "diagram_protocol": {
      "description": "All diagrams in this project use Mermaid syntax embedded in Markdown. PNG files are not AI-parseable and are replaced progressively as documentation is updated.",
      "format": "mermaid",
      "location": "04-WORKFLOWS/diagrams/",
      "index": "04-WORKFLOWS/diagrams/00-INDEX.md",
      "ai_ingestion": "Read 04-WORKFLOWS/diagrams/00-INDEX.md to discover all available diagrams. Load specific .mermaid or .md files as needed. Never attempt to load *.png files.",
      "conversion_status": "IN_PROGRESS — PNG files being converted to Mermaid. New diagrams MUST use Mermaid only.",
      "png_policy": "DEPRECATED — existing PNG files are human reference only. AI must not attempt to load or interpret PNG files. Use index to find Mermaid equivalent.",
      "audit_flag_on_png_load_attempt": "png_load_attempted_deprecated"
    },

    "dependency_graph": {
      "description": "Files this kernel depends on and files that depend on this kernel. Used for impact analysis on changes.",
      "this_file_depends_on": [
        { "file": "PROJECT_TREE.md", "reason": "Path resolution for routing_rules", "load_order": 1 },
        { "file": "05-CONFIGURATIONS/validation/norms-matrix.json", "reason": "Constraint per-folder mapping validation", "load_order": 2 },
        { "file": "01-RULES/harness-norms-v3.0.md", "reason": "C1-C8 textual definitions", "load_order": 3 },
        { "file": "01-RULES/language-lock-protocol.md", "reason": "Operator exclusion rules", "load_order": 4 }
      ],
      "this_file_is_required_by": [
        { "file": "IA-QUICKSTART.md", "reason": "Token {language} resolution and agent loading" },
        { "file": "GOVERNANCE-ORCHESTRATOR.md", "reason": "Tier validation and certification" },
        { "file": "05-CONFIGURATIONS/validation/orchestrator-engine.sh", "reason": "Runtime constraint enforcement" }
      ],
      "change_impact": {
        "adding_new_language": ["agent_registry", "routing_rules", "language_keyword_map", "mode_agent_matrix", "06-PROGRAMMING/00-INDEX.md", "norms-matrix.json"],
        "adding_new_mode": ["mode_agent_matrix", "IA-QUICKSTART.md", "GOVERNANCE-ORCHESTRATOR.md"],
        "modifying_language_lock": ["routing_rules", "agent_registry", "norm_execution_order", "orchestrator-engine.sh"],
        "requires_human_approval": true
      }
    },

    "expansion_hooks": {
      "new_agent_addition": {
        "requires": [
          "Create 06-PROGRAMMING/{language}/{language}-master-agent.md",
          "Add entry to agent_registry in this file",
          "Add routing_rule in routing_rules array",
          "Add keywords to language_keyword_map",
          "Update mode_agent_matrix for applicable modes",
          "Add to 06-PROGRAMMING/00-INDEX.md",
          "Define LANGUAGE_LOCK rules",
          "Update norms-matrix.json for new path",
          "Human approval: requires_human_approval_for_changes = true"
        ],
        "backward_compatibility": "Existing agents and routing_rules must not be modified during addition."
      },
      "new_vertical_addition": {
        "requires": [
          "Add to vertical_options in IA-QUICKSTART.md step_2_context_prompt.external",
          "Create 02-SKILLS/{VERTICAL}/00-INDEX.md",
          "Add bundle in IA-QUICKSTART.md context_injection_matrix",
          "Human approval required"
        ]
      }
    },

    "validation_self_check": {
      "description": "Commands to validate this file's own integrity.",
      "commands": [
        "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 00-STACK-SELECTOR.md --mode headless --json",
        "bash 05-CONFIGURATIONS/validation/validate-frontmatter.sh --file 00-STACK-SELECTOR.md",
        "jq '.stack_selector_kernel.agent_registry.agents | keys' 00-STACK-SELECTOR.md",
        "jq '.stack_selector_kernel.routing_rules.rules | length' 00-STACK-SELECTOR.md"
      ],
      "acceptance_criteria": {
        "frontmatter_valid": true,
        "json_parseable": true,
        "agent_count": 7,
        "routing_rules_count": 12,
        "no_hardcoded_secrets": true
      }
    }

  }
}
```
