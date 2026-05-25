{
  "stack_selector_kernel": {
    "metadata": {
      "artifact_id": "stack-selector-workflows",
      "version": "3.0.0-WORKFLOWS",
      "artifact_type": "routing_kernel",
      "canonical_path": "/04-WORKFLOWS/00-STACK-SELECTOR.md",
      "read_order": 2,
      "read_after": "04-WORKFLOWS/00-INDEX.md",
      "read_before_generation": true,
      "ai_role": "routing_oracle",
      "purpose": "Single source of truth for: workflow engine selection (n8n vs LangChain/LangGraph), skill loading, domain specialization, and orchestration governance across 04-WORKFLOWS/.",
      "anti_drift_policy": "This file is the ONLY place where workflow engine and domain decisions are made. Any deviation must be recorded as AUDIT_FLAG=routing_override with justification.",
      "human_readable": false,
      "domain_scope": "04-WORKFLOWS/",
      "governed_agents": ["n8n-master-agent", "langchain-langraph-master-agent", "lgpd-guard", "workflows-ceo"],
      "changes_in_this_version": "Initial workflows kernel. Dual-engine orchestration matrix. LGPD enforcement routing. Full skill-to-task mapping for 195+ artifacts across n8n and LangChain/LangGraph."
    },

    "engine_registry": {
      "description": "Canonical registry of all workflow engines available in 04-WORKFLOWS/. Source of truth for engine loading and capability mapping.",
      "engines": {
        "n8n": {
          "id": "n8n",
          "master_agent_path": "04-WORKFLOWS/n8n/n8n-master-agent.md",
          "domain": "visual_automation_api_orchestration",
          "paradigm": "imperative_flow_based",
          "language_primary": "json_workflow",
          "language_secondary": ["javascript_code_node", "python_code_node"],
          "total_skills": 39,
          "skill_domains": {
            "core_automation": {
              "count": 8,
              "skills": [
                "workflow-structure-fundamentals",
                "workflow-patterns-basic",
                "trigger-patterns",
                "data-transformation-patterns",
                "control-flow-patterns",
                "loop-patterns",
                "connections-patterns",
                "expression-syntax-advanced"
              ],
              "purpose": "Fundamentos estruturais de workflows n8n"
            },
            "api_integration": {
              "count": 4,
              "skills": [
                "api-integration-patterns",
                "http-request-patterns",
                "webhook-handler-secure",
                "error-handling-advanced"
              ],
              "purpose": "Integração com APIs externas e webhooks"
            },
            "security_credentials": {
              "count": 3,
              "skills": [
                "credentials-security",
                "security-testing-patterns",
                "error-handling-patterns"
              ],
              "purpose": "Gestão segura de credenciais e hardening"
            },
            "code_execution": {
              "count": 3,
              "skills": [
                "code-execution-patterns",
                "python-code-node",
                "javascript-code-node"
              ],
              "purpose": "Execução de código customizado em nodes"
            },
            "data_management": {
              "count": 4,
              "skills": [
                "database-file-operations",
                "data-tables-patterns",
                "binary-data-patterns",
                "sub-workflow-patterns"
              ],
              "purpose": "Manipulação de dados, arquivos e sub-workflows"
            },
            "mcp_integration": {
              "count": 5,
              "skills": [
                "mcp-orchestrator-core",
                "n8n-mcp-server-patterns",
                "n8n-mcp-client-patterns",
                "tool-composition-chaining",
                "resource-management"
              ],
              "purpose": "Integração com Model Context Protocol"
            },
            "ai_agentic": {
              "count": 4,
              "skills": [
                "agentic-workflow-patterns",
                "ai-agent-workflows-n8n",
                "claude-code-integration",
                "sub-workflows-advanced"
              ],
              "purpose": "Workflows agenticos e integração com IA"
            },
            "operations": {
              "count": 5,
              "skills": [
                "self-hosting-patterns",
                "workflow-lifecycle",
                "debugging-patterns",
                "workflow-testing-fundamentals",
                "trigger-testing-strategies"
              ],
              "purpose": "Operação, teste e deploy de workflows"
            },
            "architecture": {
              "count": 3,
              "skills": [
                "workflow-architect",
                "custom-node-development",
                "project-management-system"
              ],
              "purpose": "Decisões arquiteturais e extensão da plataforma"
            }
          },
          "status": "REAL",
          "best_for": [
            "api_orchestration",
            "scheduled_automation",
            "form_processing",
            "simple_conditional_logic",
            "multi_step_integration",
            "webhook_driven_flows",
            "data_etl_pipelines",
            "notification_systems",
            "crm_sync",
            "spreadsheet_automation"
          ],
          "not_suitable_for": [
            "complex_llm_chains",
            "multi_agent_swarms",
            "rag_pipelines",
            "vector_search",
            "deep_agent_customization",
            "stateful_graph_execution",
            "human_in_the_loop_complex",
            "streaming_token_events",
            "long_running_durable_execution"
          ],
          "handoff_protocol": {
            "trigger": "when n8n encounters task beyond its capabilities",
            "target": "langchain-langraph-master-agent",
            "payload_format": "workflow_json_with_trigger",
            "AUDIT_FLAG": "n8n_to_langchain_handoff"
          }
        },
        "langchain-langraph": {
          "id": "langchain-langraph",
          "master_agent_path": "04-WORKFLOWS/langchain-langraph/langchain-langraph-master-agent.md",
          "domain": "ai_pipelines_multi_agent_rag",
          "paradigm": "state_graph_functional",
          "language_primary": "python",
          "language_secondary": ["typescript", "go", "java", "bash", "yaml"],
          "total_skills": 156,
          "skill_domains": {
            "00-fundacional": {
              "count": 4,
              "skills_path": "04-WORKFLOWS/langchain-langraph/libs/00-fundacional/",
              "purpose": "Fundação LangChain/LangGraph: LCEL, create_agent, StateGraph, dependências"
            },
            "01-langchain-tradicional": {
              "count": 12,
              "skills_path": "04-WORKFLOWS/langchain-langraph/libs/01-langchain-tradicional/",
              "purpose": "Padrões clássicos: chains, agentes ReAct, middleware, deploy LangServe/Express"
            },
            "02-rag": {
              "count": 10,
              "skills_path": "04-WORKFLOWS/langchain-langraph/libs/02-rag/",
              "purpose": "Pipeline RAG completo: chunking, embeddings, vector stores, retrieval, avaliação"
            },
            "03-mcp": {
              "count": 25,
              "skills_path": "04-WORKFLOWS/langchain-langraph/libs/03-mcp/",
              "purpose": "Model Context Protocol: servidores, clientes, integrações multi-linguagem"
            },
            "04-modelos": {
              "count": 13,
              "skills_path": "04-WORKFLOWS/langchain-langraph/libs/04-modelos/",
              "purpose": "Integração com LLMs: OpenRouter, DeepSeek, Gemini, Qwen, multimodal"
            },
            "05-bases-datos": {
              "count": 15,
              "skills_path": "04-WORKFLOWS/langchain-langraph/libs/05-bases-datos/",
              "purpose": "Persistência: vector stores, checkpointers, memória, serialização, encriptação"
            },
            "06-deep-agents": {
              "count": 45,
              "skills_path": "04-WORKFLOWS/langchain-langraph/libs/06-deep-agents/",
              "purpose": "Deep Agents: customização, subagentes, backends, intérpretes, HITL, deploy"
            },
            "07-a2a": {
              "count": 4,
              "skills_path": "04-WORKFLOWS/langchain-langraph/libs/07-a2a/",
              "purpose": "Protocolo Agent-to-Agent: comunicação, discovery, tracing distribuído"
            },
            "08-operaciones-langsmith": {
              "count": 11,
              "skills_path": "04-WORKFLOWS/langchain-langraph/libs/08-operaciones-langsmith/",
              "purpose": "Operações: deploy, CI/CD, scaling, time travel, Mission Control"
            },
            "09-seguridad": {
              "count": 3,
              "skills_path": "04-WORKFLOWS/langchain-langraph/libs/09-seguridad/",
              "purpose": "Segurança: autenticação customizada, autorização, OpenAPI, LGPD"
            },
            "10-observabilidad": {
              "count": 3,
              "skills_path": "04-WORKFLOWS/langchain-langraph/libs/10-observabilidad/",
              "purpose": "Observabilidade: coletores OTel, stack LGTM, cache server-side"
            },
            "11-swarm-supervisor": {
              "count": 9,
              "skills_path": "04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/",
              "purpose": "Enxames e supervisores: handoff, templates, memória multi-agente, CI/CD"
            },
            "12-langgraph-api": {
              "count": 12,
              "skills_path": "04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/",
              "purpose": "APIs do runtime: Graph API, Functional API, streaming v3, fault tolerance"
            }
          },
          "status": "REAL",
          "best_for": [
            "complex_llm_chains",
            "multi_agent_swarms",
            "rag_pipelines",
            "vector_search",
            "deep_agent_customization",
            "stateful_graph_execution",
            "human_in_the_loop_complex",
            "streaming_token_events",
            "long_running_durable_execution",
            "semantic_memory_systems",
            "fault_tolerant_agents",
            "hierarchical_supervisors"
          ],
          "not_suitable_for": [
            "simple_api_calls",
            "basic_form_processing",
            "scheduled_data_sync",
            "spreadsheet_automation",
            "single_webhook_triggers"
          ],
          "handoff_protocol": {
            "trigger": "when LangChain encounters task better suited for visual automation",
            "target": "n8n-master-agent",
            "payload_format": "api_trigger_with_payload",
            "AUDIT_FLAG": "langchain_to_n8n_handoff"
          }
        }
      },
      "guard_registry": {
        "lgpd_guard": {
          "id": "lgpd-guard",
          "master_agent_path": "04-WORKFLOWS/lgpd-guard/lgpd-guard.md",
          "domain": "privacy_compliance",
          "total_skills": 9,
          "skills_path": "04-WORKFLOWS/lgpd-guard/skills/",
          "skills": [
            "data-classifier",
            "consent-management",
            "dsar-handling",
            "audit-logging",
            "retention-deletion",
            "privacy-notice-template",
            "pii-redaction",
            "ripd-generator",
            "incident-response"
          ],
          "status": "REAL",
          "activation_rule": {
            "condition": "task involves personal data processing (PII detection)",
            "pre_validation": true,
            "post_validation": true,
            "AUDIT_FLAG": "lgpd_guard_activated"
          }
        }
      }
    },

    "task_classification_matrix": {
      "description": "Deterministic mapping of task characteristics to engine selection. Evaluated in order; first match wins. If multiple characteristics match across engines, secondary characteristics break ties.",
      "matrix": [
        {
          "characteristic": "data_contains_pii",
          "weight": 100,
          "action": "ACTIVATE_GUARD",
          "guard": "lgpd-guard",
          "description": "If task data contains CPF, email, name, phone, address, biometric data, or any personal identifier, lgpd-guard MUST be activated before any engine executes."
        },
        {
          "characteristic": "requires_llm_generation",
          "weight": 90,
          "engine": "langchain-langraph",
          "domain_hint": "04-modelos",
          "description": "If task requires text generation, summarization, translation, or any LLM call beyond simple classification."
        },
        {
          "characteristic": "requires_rag_retrieval",
          "weight": 90,
          "engine": "langchain-langraph",
          "domain_hint": "02-rag",
          "description": "If task involves document retrieval, embedding, semantic search, or knowledge base queries."
        },
        {
          "characteristic": "requires_multi_agent_coordination",
          "weight": 88,
          "engine": "langchain-langraph",
          "domain_hint": "11-swarm-supervisor",
          "description": "If task requires multiple specialized agents collaborating with handoffs or supervisor."
        },
        {
          "characteristic": "requires_vector_search",
          "weight": 87,
          "engine": "langchain-langraph",
          "domain_hint": "05-bases-datos",
          "description": "If task involves pgvector, Qdrant, FAISS, or any vector similarity operations."
        },
        {
          "characteristic": "requires_stateful_conversation",
          "weight": 85,
          "engine": "langchain-langraph",
          "domain_hint": "12-langgraph-api",
          "description": "If task requires maintaining state across multiple turns with checkpointing."
        },
        {
          "characteristic": "requires_human_approval_loop",
          "weight": 85,
          "engine": "langchain-langraph",
          "domain_hint": "12-langgraph-api",
          "description": "If task requires interrupt-based human-in-the-loop with approval/rejection."
        },
        {
          "characteristic": "requires_fault_tolerance",
          "weight": 82,
          "engine": "langchain-langraph",
          "domain_hint": "12-langgraph-api",
          "description": "If task requires retry policies, timeouts, error handlers, or durable execution."
        },
        {
          "characteristic": "requires_api_orchestration_only",
          "weight": 80,
          "engine": "n8n",
          "domain_hint": "core_automation",
          "description": "If task is purely orchestrating API calls, webhooks, and data transformations without LLM."
        },
        {
          "characteristic": "requires_scheduled_execution",
          "weight": 78,
          "engine": "n8n",
          "domain_hint": "core_automation",
          "description": "If task needs cron-like scheduling with time-based triggers."
        },
        {
          "characteristic": "requires_spreadsheet_integration",
          "weight": 75,
          "engine": "n8n",
          "domain_hint": "data_management",
          "description": "If task involves Google Sheets, Excel, or tabular data processing."
        },
        {
          "characteristic": "requires_crm_sync",
          "weight": 75,
          "engine": "n8n",
          "domain_hint": "api_integration",
          "description": "If task involves syncing data between CRM, ERP, or business systems."
        },
        {
          "characteristic": "requires_mcp_server_exposure",
          "weight": 72,
          "engine": "langchain-langraph",
          "domain_hint": "03-mcp",
          "description": "If task requires exposing tools as MCP server for external consumption."
        },
        {
          "characteristic": "requires_mcp_client_consumption",
          "weight": 70,
          "engine": "ambos",
          "domain_hint_n8n": "mcp_integration",
          "domain_hint_langchain": "03-mcp",
          "description": "If task requires consuming external MCP servers. n8n for simple consumption, LangChain for complex."
        }
      ]
    },

    "skill_selection_rules": {
      "description": "After engine is selected, these rules deterministically map task keywords to specific skill groups and domains. Evaluated top-down; all matching skills are loaded.",
      "n8n_skill_rules": [
        {
          "task_keywords": ["webhook", "trigger", "incoming", "endpoint"],
          "skills": ["trigger-patterns", "workflow-structure-fundamentals", "error-handling-patterns", "security-testing-patterns"]
        },
        {
          "task_keywords": ["api", "rest", "http", "request", "integration"],
          "skills": ["api-integration-patterns", "http-request-patterns", "credentials-security", "error-handling-advanced"]
        },
        {
          "task_keywords": ["database", "sql", "file", "binary", "data"],
          "skills": ["database-file-operations", "data-tables-patterns", "binary-data-patterns", "data-transformation-patterns"]
        },
        {
          "task_keywords": ["email", "notification", "message", "alert"],
          "skills": ["workflow-patterns-basic", "control-flow-patterns", "error-handling-patterns"]
        },
        {
          "task_keywords": ["code", "python", "javascript", "script"],
          "skills": ["code-execution-patterns", "python-code-node", "javascript-code-node"]
        },
        {
          "task_keywords": ["loop", "iterate", "batch", "paginate"],
          "skills": ["loop-patterns", "control-flow-patterns", "expression-syntax-advanced"]
        },
        {
          "task_keywords": ["subworkflow", "modular", "reusable"],
          "skills": ["sub-workflow-patterns", "sub-workflows-advanced", "workflow-lifecycle"]
        },
        {
          "task_keywords": ["mcp", "tool", "agent"],
          "skills": ["mcp-orchestrator-core", "n8n-mcp-server-patterns", "n8n-mcp-client-patterns", "tool-composition-chaining"]
        },
        {
          "task_keywords": ["deploy", "production", "self-host", "docker"],
          "skills": ["self-hosting-patterns", "workflow-lifecycle", "debugging-patterns"]
        },
        {
          "task_keywords": ["test", "validate", "debug"],
          "skills": ["workflow-testing-fundamentals", "trigger-testing-strategies", "debugging-patterns"]
        }
      ],
      "langchain_skill_rules": [
        {
          "task_keywords": ["agent", "create_agent", "tool"],
          "domain": "00-fundacional",
          "skills": ["langgraph-create-agent", "langgraph-state-graph-fundamentals", "langchain-core-concepts"]
        },
        {
          "task_keywords": ["rag", "retrieval", "document", "chunk", "embedding"],
          "domain": "02-rag",
          "skills": ["rag-fundamentals", "rag-chunking-strategies", "rag-embeddings", "rag-vector-stores", "rag-retrieval-strategies"]
        },
        {
          "task_keywords": ["mcp", "model context protocol", "server", "client"],
          "domain": "03-mcp",
          "skills": ["mcp-server-fundamentals", "mcp-client-multi-server", "mcp-langchain-tools-integration"]
        },
        {
          "task_keywords": ["model", "llm", "deepseek", "openai", "gemini", "qwen"],
          "domain": "04-modelos",
          "skills": ["model-selection-strategy", "multi-model-openrouter-integration", "deepseek-integration"]
        },
        {
          "task_keywords": ["database", "postgres", "vector", "qdrant", "checkpoint"],
          "domain": "05-bases-datos",
          "skills": ["checkpointer-backend-config", "memory-management-patterns", "advanced-persistence-patterns"]
        },
        {
          "task_keywords": ["swarm", "supervisor", "multi-agent", "handoff", "enxame"],
          "domain": "11-swarm-supervisor",
          "skills": ["swarm-fundamentals", "supervisor-fundamentals", "handoff-tools-advanced", "swarm-supervisor-patterns"]
        },
        {
          "task_keywords": ["graph", "stategraph", "node", "edge", "command"],
          "domain": "12-langgraph-api",
          "skills": ["graph-api-fundamentals", "graph-api-advanced", "graph-vs-functional-decision"]
        },
        {
          "task_keywords": ["functional", "entrypoint", "task", "workflow"],
          "domain": "12-langgraph-api",
          "skills": ["functional-api-fundamentals", "functional-api-advanced"]
        },
        {
          "task_keywords": ["stream", "streaming", "token", "event"],
          "domain": "12-langgraph-api",
          "skills": ["streaming-api-fundamentals", "streaming-api-advanced", "event-streaming-v3-api"]
        },
        {
          "task_keywords": ["interrupt", "human-in-the-loop", "hitl", "approval"],
          "domain": "12-langgraph-api",
          "skills": ["interrupts-patterns", "functional-api-advanced"]
        },
        {
          "task_keywords": ["retry", "timeout", "fault", "error", "resilience"],
          "domain": "12-langgraph-api",
          "skills": ["fault-tolerance-patterns", "durable-execution-graceful-shutdown"]
        },
        {
          "task_keywords": ["deploy", "standalone", "docker", "kubernetes", "mission control"],
          "domain": "08-operaciones-langsmith",
          "skills": ["standalone-deployment", "mission-control-operations", "cicd-pipeline-agents"]
        },
        {
          "task_keywords": ["security", "auth", "authorization", "openapi"],
          "domain": "09-seguridad",
          "skills": ["custom-auth-authorization", "openapi-security-docs"]
        },
        {
          "task_keywords": ["observability", "telemetry", "log", "monitor", "cache"],
          "domain": "10-observabilidad",
          "skills": ["telemetry-export-collector", "observability-stack-deployment", "server-side-caching"]
        },
        {
          "task_keywords": ["a2a", "agent to agent", "inter-agent"],
          "domain": "07-a2a",
          "skills": ["a2a-protocol-core", "a2a-agent-card-discovery", "a2a-distributed-tracing"]
        },
        {
          "task_keywords": ["deep agent", "subagent", "backend", "interpreter", "sandbox"],
          "domain": "06-deep-agents",
          "skills": ["deep-agents-core-customization", "deep-agents-subagents-fundamentals", "deep-agents-backends-overview"]
        },
        {
          "task_keywords": ["time travel", "debug", "history", "checkpoint"],
          "domain": "08-operaciones-langsmith",
          "skills": ["time-travel-debugging", "distributed-tracing-server"]
        },
        {
          "task_keywords": ["memory", "long-term", "short-term", "context"],
          "domain": "05-bases-datos",
          "skills": ["memory-management-patterns", "advanced-persistence-patterns"]
        },
        {
          "task_keywords": ["pregel", "channel", "runtime"],
          "domain": "12-langgraph-api",
          "skills": ["pregel-runtime-channels"]
        },
        {
          "task_keywords": ["template", "researcher", "customer support", "swarm example"],
          "domain": "11-swarm-supervisor",
          "skills": ["swarm-researcher-template", "customer-support-template"]
        },
        {
          "task_keywords": ["cicd", "pipeline", "github actions", "test"],
          "domain": "11-swarm-supervisor",
          "skills": ["swarm-cicd-pipeline"]
        }
      ]
    },

    "execution_plan_generator": {
      "description": "Generates a deterministic execution plan from task analysis. This is the OUTPUT of the Stack Selector.",
      "algorithm": [
        "1. Receive task.json with description, data_classification, constraints",
        "2. IF data_contains_pii: ACTIVATE lgpd-guard pre-validation",
        "3. Match task characteristics against task_classification_matrix → select engine",
        "4. Match task_keywords against engine-specific skill_selection_rules → select skills",
        "5. Determine if handoff to other engine is needed based on complementary capabilities",
        "6. Generate execution_plan.json with ordered steps"
      ],
      "output_schema": {
        "execution_plan": {
          "task_id": "string",
          "trace_id": "string",
          "selected_engine": "n8n | langchain-langraph",
          "lgpd_guard_required": "boolean",
          "pre_validation_steps": ["lgpd_data_classification", "consent_verification"],
          "primary_agent_path": "string",
          "required_skills": [
            {
              "skill_id": "string",
              "skill_path": "string",
              "load_reason": "string (matched keyword)"
            }
          ],
          "secondary_engine_handoff": "null | { engine: string, trigger_condition: string, payload: object }",
          "expected_output_path": "string",
          "timeout_minutes": "number",
          "mode": "B1 | B2"
        }
      }
    },

    "norm_execution_order": {
      "description": "Constraints applied in order during artifact generation. Fail-fast on critical constraints.",
      "fail_fast": [
        {
          "constraint": "C3",
          "check": "Zero hardcoded secrets in any generated artifact",
          "validator": "audit-secrets.sh"
        },
        {
          "constraint": "C5",
          "check": "Valid frontmatter with all required fields",
          "validator": "validate-frontmatter.sh"
        }
      ],
      "standard": [
        {
          "constraint": "C1",
          "check": "Resource limits from env vars, never hardcoded"
        },
        {
          "constraint": "C4",
          "check": "Tenant isolation when applicable"
        },
        {
          "constraint": "C7",
          "check": "Error handling and retry policies present"
        },
        {
          "constraint": "C8",
          "check": "mantis_log() integrated with trace_id propagation"
        },
        {
          "constraint": "C9",
          "check": "A2A contract compliance: status.json with trace_id, span_id"
        }
      ]
    },

    "dependency_graph": {
      "this_file_depends_on": [
        {
          "file": "04-WORKFLOWS/n8n/n8n-master-agent.md",
          "reason": "n8n skill registry and agent capabilities"
        },
        {
          "file": "04-WORKFLOWS/langchain-langraph/langchain-langraph-master-agent.md",
          "reason": "LangChain/LangGraph skill registry and agent capabilities"
        },
        {
          "file": "04-WORKFLOWS/workflows-ceo.md",
          "reason": "CEO orchestration protocol and handoff rules"
        }
      ],
      "this_file_is_required_by": [
        {
          "file": "04-WORKFLOWS/workflows-ceo.md",
          "reason": "Engine selection and skill loading decisions"
        }
      ]
    },

    "validation_self_check": {
      "commands": [
        "jq '.stack_selector_kernel.engine_registry.engines | keys' 04-WORKFLOWS/00-STACK-SELECTOR.md",
        "jq '.stack_selector_kernel.engine_registry.engines.langchain-langraph.skill_domains | keys | length' 04-WORKFLOWS/00-STACK-SELECTOR.md",
        "jq '.stack_selector_kernel.engine_registry.engines.n8n.skill_domains | keys | length' 04-WORKFLOWS/00-STACK-SELECTOR.md"
      ],
      "acceptance_criteria": {
        "engine_count": 2,
        "langchain_domains": 13,
        "n8n_domains": 9,
        "lgpd_guard_present": true,
        "task_classification_rules": 14
      }
    }
  }
}
