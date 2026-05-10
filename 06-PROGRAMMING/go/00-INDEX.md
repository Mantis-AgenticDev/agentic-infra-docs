---
artifact_id: "00-INDEX-go"
artifact_type: "skill_index"
version: "3.1.0-SELECTIVE"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/go/00-INDEX.md --json"
canonical_path: "06-PROGRAMMING/go/00-INDEX.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:go-index-canonico-v2.3.0"
generated_at: "2026-05-09T00:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "go"
ai_navigation:
  read_first: true
  required_for: ["hydrated_context_loading", "stackselector_query", "master_agent_routing"]
  update_frequency: on-change
audience: ["go-master-agent", "orchestrator-engine", "validation-hooks"]
status: "✅ Estável"
next_review: "2026-06-09"
license: "CC-BY-NC-SA-4.0"
---

# Go Patterns Master Index – Hardening Multi-Tenant, Concorrência e Integração com IA

## 👤 Propósito e Escopo
Índice canônico de navegação para `06-PROGRAMMING/go/`. Documenta 35 artefatos auditados sob HARNESS NORMS v3.1.0-SELECTIVE, mapeia fluxos de execução para desenvolvimento backend/concorrente com isolamento multi-tenant, faz referência ao **agente mestre de geração Go**, e fornece uma árvore JSON enriquecida para roteamento de agentes LLM e pipelines CI/CD.

> 🔑 **Diferenciador crítico**: Este domínio cobre Go 1.21+ com foco em:
> - Segurança de concorrência com goroutines/channels para processamento multi-tenant sem race conditions
> - Type safety nativo com interfaces e generics para validação estática de contratos
> - Abstrações de custo zero para observabilidade (C8) e limites de recursos (C1/C2)
> - Integração segura com backends (SQL, pgvector, Python) respeitando LANGUAGE LOCK

---

## 🤖 Agente de Geração Disponível

| Agente | Canonical Path | Domínio | Constraints Suportados | Hooks de Validação |
|--------|---------------|---------|----------------------|-------------------|
| **`go-master-agent`** ✅ | `[[06-PROGRAMMING/go/go-master-agent.md]]` | `go,golang,concurrency,microservices` | `C1,C2,C3,C4,C5,C7,C8` | `verify-constraints.sh`, `audit-secrets.sh`, `go-vet-validator.sh`, `golangci-lint-check.sh` |

> ⚠️ **Nota contratual**: Este agente é Tier 1 (referência educacional). Qualquer módulo gerado deve passar por validação automática antes do merge. Documentação técnica em pt-BR: `docs/pt-BR/programming/go/go-master-agent/README.md`.

---

## 📂 Mapeamento de Fases e Wikilinks

### FASE 0 – Hardening Essencial (Pré-voo e Type Safety)
| Artefato | Constraints | Propósito |
|----------|-------------|-----------|
| `[[hardening-verification.go.md]]` | C3,C4,C5,C7,C8 | Validação de ambiente Go, limites de recursos e `go vet` pré-execução |
| `[[type-safety-with-generics.go.md]]` | C4,C5,C7,C8 | Generics para contratos type-safe com validação de tenant_id em tempo de compilação |
| `[[error-handling-c7.go.md]]` | C4,C5,C7,C8 | Tratamento estruturado de erros com `errors.Join`, logging e recuperação segura |

### FASE 1 – Segurança Multi-Tenant (Isolamento no Backend)
| Artefato | Constraints | Propósito |
|----------|-------------|-----------|
| `[[microservices-tenant-isolation.go.md]]` | C3,C4,C5,C7,C8 | Middleware de isolamento por tenant com propagação de contexto e isolamento de cache |
| `[[secrets-management-c3.go.md]]` | C3,C5,C7 | Gerenciamento de segredos via variáveis de ambiente, integração com vault e zero hardcode em binários |
| `[[authentication-authorization-patterns.go.md]]` | C3,C4,C8 | JWT/OAuth2 com claims de tenant_id e validação RBAC em handlers HTTP |
| `[[structured-logging-c8.go.md]]` | C4,C5,C8 | Logging estruturado JSON com correlação de requisições e rastreabilidade por tenant |

### FASE 2 – Concorrência e Padrões Assíncronos
| Artefato | Constraints | Propósito |
|----------|-------------|-----------|
| `[[async-patterns-with-timeouts.go.md]]` | C1,C4,C7,C8 | Goroutines com context.Context, timeouts e cancelamento por tenant |
| `[[resource-limits-c1-c2.go.md]]` | C1,C2,C7 | Limitação de CPU/memória com `runtime/debug.SetMemoryLimit` e semáforos |
| `[[orchestrator-engine.go.md]]` | C1,C3,C4,C5,C6,C7,C8 | Port do orquestrador bash → Go com explicação linha a linha e validação de constraints |
| `[[filesystem-sandboxing.go.md]]` | C3,C4,C7 | Isolamento de operações de filesystem por tenant com padrões tipo chroot |

### FASE 3 – Integração com Banco de Dados e SQL
| Artefato | Constraints | Propósito |
|----------|-------------|-----------|
| `[[sql-core-patterns.go.md]]` | C3,C4,C8 | Queries parametrizadas com `database/sql`, tenant_id obrigatório e prepared statements |
| `[[db-selection-decision-tree.go.md]]` | C4,C5,C7 | Árvore de decisão para seleção de DB (PostgreSQL/MySQL/SQLite) com validação de escopo de tenant |
| `[[mysql-mariadb-optimization.go.md]]` | C1,C4,C7 | Otimizações específicas para MySQL/MariaDB com limites de recursos por tenant |
| `[[prisma-orm-patterns.go.md]]` | C4,C5,C8 | Padrões Prisma Client Go com geração de tipos e validação de tenant_id em queries |

### FASE 4 – Clientes de API e Integrações Externas
| Artefato | Constraints | Propósito |
|----------|-------------|-----------|
| `[[api-client-management.go.md]]` | C3,C4,C7,C8 | Gerenciamento de clientes HTTP com lógica de retry, circuit breaker e headers de tenant_id |
| `[[n8n-webhook-handler.go.md]]` | C3,C4,C8 | Handler de webhooks n8n com validação de assinatura HMAC e escopo de tenant |
| `[[webhook-validation-patterns.go.md]]` | C3,C4,C7 | Validação de webhooks de entrada com rate limiting por tenant e prevenção de replay attack |
| `[[telegram-bot-integration.go.md]]` | C3,C4,C8 | Bot de Telegram com contexto de usuário/tenant e logging estruturado de interações |

### FASE 5 – RAG e Integrações de IA (LANGUAGE LOCK: Delegação)
| Artefato | Constraints | Propósito |
|----------|-------------|-----------|
| `[[postgres-pgvector-integration.go.md]]` | C4,C8,V1,V2 | **Delegação controlada**: wrapper Go para chamar queries pgvector em `postgresql-pgvector/`, NÃO gera operadores vetoriais diretamente |
| `[[rag-ingestion-pipeline.go.md]]` | C1,C4,C7,C8 | Pipeline de ingestão RAG com chunking, limites de recursos e validação de tenant_id em metadados |
| `[[langchain-style-integration.go.md]]` | C4,C5,C8 | Integração estilo LangChain com composição de cadeia e validação de contexto de tenant |
| `[[supabase-rag-integration.go.md]]` | C3,C4,C8 | Integração com Supabase Vector com autenticação com escopo de tenant e logging de queries |

### FASE 6 – Observabilidade e Implantação
| Artefato | Constraints | Propósito |
|----------|-------------|-----------|
| `[[observability-opentelemetry.go.md]]` | C7,C8 | Instrumentação OpenTelemetry com atributos de tenant_id e métricas por serviço |
| `[[static-dashboard-generator.go.md]]` | C1,C4,C7 | Gerador de dashboards estáticos com limites de recursos e isolamento de dados por tenant |
| `[[saas-deployment-zip-auto.go.md]]` | C1,C3,C4,C7 | Implantação automática SaaS com empacotamento ZIP, validação de integridade e rollback por tenant |
| `[[git-disaster-recovery.go.md]]` | C3,C5,C7 | Recuperação de desastres Git com validação de assinaturas GPG e isolamento de branches por tenant |

### FASE 7 – Testes e Validação
| Artefato | Constraints | Propósito |
|----------|-------------|-----------|
| `[[testing-multi-tenant-patterns.go.md]]` | C4,C5,C8 | Padrões de teste com `testing.T`, fixtures isoladas por tenant e mocks de API com escopo de tenant |
| `[[scale-simulation-utils.go.md]]` | C1,C2,C7 | Utilitários para simulação de carga com limites de recursos e métricas de escalabilidade por tenant |
| `[[testing-multi-tenant-patterns.go.md]]` | C4,C5,C8 | Padrões de teste com `testing.T`, fixtures isoladas por tenant e mocks de API com escopo de tenant |

---

## 🔗 Interações com o Repositório
- **`05-CONFIGURATIONS/validation/`**: Todos os artefatos são validados por `orchestrator-engine.sh`. Os scripts `verify-constraints.sh`, `go-vet-validator.sh` e `golangci-lint-check.sh` consomem o JSON deste índice.
- **`01-RULES/`**: As normas `harness-norms-v3.0.md`, `language-lock-protocol.md` e `06-MULTITENANCY-RULES.md` definem os constraints C1-C8 aplicados.
- **`06-PROGRAMMING/postgresql-pgvector/`**: Pasta irmã com LANGUAGE LOCK estrito. **Delegação obrigatória**: queries vetoriais devem ser geradas em `postgresql-pgvector/`, não aqui. Este domínio contém apenas wrappers de chamada.
- **`06-PROGRAMMING/python/`**: Para lógica de backend pesada ou geração de embedding, usar `python/` e consumir via gRPC/HTTP a partir deste domínio.
- **`06-PROGRAMMING/sql/`**: Para queries SQL puras (sem vetores), delegar para `sql/` e consumir via `database/sql` ou query builder a partir de Go.
- **`08-LOGS/`**: Os handlers de logging estruturado (C8) em Go alimentam dashboards e geram entradas em `failed-attempts/` se as validações de isolamento de tenant falharem.
- **`go-master-agent.md`**: Ponto único de geração para novos artefatos Go. Consulta este índice ANTES de emitir módulos para garantir a coerência com os padrões existentes.

---

## ⚠️ Regras Críticas de LANGUAGE LOCK para go/

```text
🚫 PROIBIDO nesta pasta:
• Importação ou uso direto de operadores pgvector: import "github.com/pgvector/pgvector-go", <->, <#>, <=>, vector(n)
• Queries SQL embutidas com sintaxe de extensão pgvector (CREATE EXTENSION vector, USING hnsw, etc.)
• Constraints vetoriais V1/V2/V3 em constraints_mapped do frontmatter (exceto em postgres-pgvector-integration.go.md que é wrapper de delegação)
• Geração direta de código com operadores vetoriais; apenas wrappers que delegam para postgresql-pgvector/ são permitidos

✅ REQUERIDO nesta pasta:
• artifact_type: "go_module" | "go_pattern" | "go_microservice" | "go_cli" (NUNCA "skill_pgvector")
• constraints_mapped: APENAS valores de C1-C8 (V* bloqueado por LANGUAGE LOCK, exceto delegação controlada)
• Módulos que interagem com DB devem validar tenant_id em queries ou usar context com escopo de tenant
• validation_command que referencie orchestrator-engine.sh com canonical_path correto
• Agente mestre: consultar norms-matrix.json antes de declarar constraints em módulos gerados
• Concurrency safety: usar context.Context para cancelamento e propagação de timeout em goroutines
• Comentários pedagógicos: incluir `// 👇 EXPLICAÇÃO:` em português para facilitar o aprendizado
```

---

## 🤖 JSON TREE ENRIQUECIDO PARA IA (Metadados + Dependências + Prioridade de Normas)

```json
{
 "index_metadata": {
 "artifact_id": "00-INDEX-go",
 "artifact_type": "skill_index",
 "version": "3.1.0-SELECTIVE",
 "canonical_path": "06-PROGRAMMING/go/00-INDEX.md",
 "language_lock_status": "enforced",
 "vector_constraints_applied": false,
 "generated_timestamp": "2026-01-27T00:00:00Z",
 "master_agent": "go-master-agent"
 },
 "artifacts": [
 {
 "artifact_id": "go-master-agent",
 "file": "go-master-agent.md",
 "canonical_path": "06-PROGRAMMING/go/go-master-agent.md",
 "artifact_type": "agentic_skill_definition",
 "tier": 1,
 "constraints_mapped": ["C1","C2","C3","C4","C5","C7","C8"],
 "language_lock": ["go","golang","concurrency","microservices"],
 "validation_hooks": ["verify-constraints.sh", "audit-secrets.sh", "go-vet-validator.sh", "golangci-lint-check.sh"],
 "examples_count": 15,
 "score_baseline": 94,
 "dependencies": {
 "validators": ["verify-constraints.sh", "audit-secrets.sh", "go-vet-validator.sh", "golangci-lint-check.sh"],
 "norms": ["harness-norms-v3.0.md", "10-SDD-CONSTRAINTS.md", "language-lock-protocol.md", "06-MULTITENANCY-RULES.md"],
 "config": ["norms-matrix.json", "skill-template.md", "go.mod", ".golangci.yml"]
 },
 "dependents": ["all go artifacts"],
 "norms_priority": {
 "execution_order": ["C4", "C3", "C5", "C7", "C8", "C1", "C2"],
 "blocking_constraints": ["C3", "C4"],
 "rationale": "Segurança (C3) e isolamento de tenant (C4) são fundamentais para a geração de módulos Go"
 },
 "interactions": {
 "with_validation": "Emite JSON para stdout, logs para stderr, JSONL para 08-LOGS/ por V-INT-03",
 "with_config": "Consulta norms-matrix.json antes de declarar constraints em módulos gerados",
 "with_programming": "Delega operações vetoriais para postgresql-pgvector/, SQL para sql/, lógica de embedding para python/ por LANGUAGE LOCK"
 }
 },
 {
 "artifact_id": "hardening-verification",
 "file": "hardening-verification.go.md",
 "canonical_path": "06-PROGRAMMING/go/hardening-verification.go.md",
 "constraints_mapped": ["C3","C4","C5","C7","C8"],
 "examples_count": 10,
 "score_baseline": 90,
 "dependencies": {
 "validators": ["verify-constraints.sh", "go-vet-validator.sh"],
 "norms": ["harness-norms-v3.0.md", "10-SDD-CONSTRAINTS.md"],
 "templates": ["skill-template.md"]
 },
 "dependents": ["all phase-1 to phase-7 artifacts"],
 "norms_priority": {
 "execution_order": ["C4", "C3", "C7", "C5", "C8"],
 "blocking_constraints": ["C4", "C3"],
 "rationale": "A validação pré-voo deve confirmar o isolamento de tenant e a segurança antes de qualquer execução de módulo Go"
 },
 "interactions": {
 "with_validation": "Fornece verificações básicas consumidas por orchestrator-engine.sh",
 "with_config": "Referencia norms-matrix.json para lógica de roteamento de constraints",
 "with_programming": "NÃO há interação com postgresql-pgvector/ devido ao LANGUAGE LOCK"
 }
 },
 {
 "artifact_id": "microservices-tenant-isolation",
 "file": "microservices-tenant-isolation.go.md",
 "canonical_path": "06-PROGRAMMING/go/microservices-tenant-isolation.go.md",
 "constraints_mapped": ["C3","C4","C5","C7","C8"],
 "examples_count": 12,
 "score_baseline": 93,
 "dependencies": {
 "validators": ["verify-constraints.sh", "audit-secrets.sh"],
 "norms": ["harness-norms-v3.0.md#C4", "06-MULTITENANCY-RULES.md"],
 "security_refs": ["03-SECURITY-RULES.md"]
 },
 "dependents": ["sql-core-patterns", "api-client-management", "observability-opentelemetry"],
 "norms_priority": {
 "execution_order": ["C4", "C8", "C3", "C7", "C5"],
 "blocking_constraints": ["C4"],
 "rationale": "O isolamento de middleware é o mecanismo de aplicação para C4 em microsserviços Go; deve ser validado primeiro"
 },
 "interactions": {
 "with_validation": "verify-constraints.sh valida a propagação de tenant_id em exemplos de context.Context",
 "with_config": "Alinha-se com as regras multi-tenant em 06-MULTITENANCY-RULES.md",
 "with_programming": "Padrões de contexto consumidos por handlers HTTP antes de chamadas de DB/API"
 }
 },
 {
 "artifact_id": "secrets-management-c3",
 "file": "secrets-management-c3.go.md",
 "canonical_path": "06-PROGRAMMING/go/secrets-management-c3.go.md",
 "constraints_mapped": ["C3","C5","C7"],
 "examples_count": 10,
 "score_baseline": 91,
 "dependencies": {
 "validators": ["audit-secrets.sh", "verify-constraints.sh"],
 "norms": ["harness-norms-v3.0.md#C3"],
 "templates": [".env.example", "go.mod"]
 },
 "dependents": ["microservices-tenant-isolation", "api-client-management"],
 "norms_priority": {
 "execution_order": ["C3", "C7", "C5"],
 "blocking_constraints": ["C3"],
 "rationale": "O tratamento de segredos é crítico para a segurança; deve passar antes das verificações estruturais"
 },
 "interactions": {
 "with_validation": "audit-secrets.sh valida segredos de hardcode zero em exemplos",
 "with_config": "Referencia .env.example para padrões de placeholder",
 "with_programming": "Padrões de segredos consumidos pelo carregamento de configuração da aplicação em tempo de compilação"
 }
 },
 {
 "artifact_id": "sql-core-patterns",
 "file": "sql-core-patterns.go.md",
 "canonical_path": "06-PROGRAMMING/go/sql-core-patterns.go.md",
 "constraints_mapped": ["C3","C4","C8"],
 "examples_count": 14,
 "score_baseline": 94,
 "dependencies": {
 "validators": ["verify-constraints.sh", "go-vet-validator.sh"],
 "norms": ["harness-norms-v3.0.md#C4"],
 "templates": ["skill-template.md"]
 },
 "dependents": ["mysql-mariadb-optimization", "prisma-orm-patterns", "rag-ingestion-pipeline"],
 "norms_priority": {
 "execution_order": ["C4", "C3", "C8"],
 "blocking_constraints": ["C4"],
 "rationale": "Queries de DB são a principal superfície de ataque; a aplicação de tenant em cláusulas WHERE é inegociável"
 },
 "interactions": {
 "with_validation": "verify-constraints.sh valida o filtro tenant_id em todos os exemplos de query",
 "with_config": "Padrões de parametrização alinham-se com as melhores práticas de database/sql",
 "with_programming": "Modelo de query principal consumido pela camada de serviço da aplicação"
 }
 },
 {
 "artifact_id": "postgres-pgvector-integration",
 "file": "postgres-pgvector-integration.go.md",
 "canonical_path": "06-PROGRAMMING/go/postgres-pgvector-integration.go.md",
 "constraints_mapped": ["C4","C8"],
 "examples_count": 8,
 "score_baseline": 89,
 "dependencies": {
 "validators": ["verify-constraints.sh", "go-vet-validator.sh"],
 "norms": ["harness-norms-v3.0.md#C4", "language-lock-protocol.md"],
 "delegation_refs": ["postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md"]
 },
 "dependents": ["rag-ingestion-pipeline", "supabase-rag-integration"],
 "norms_priority": {
 "execution_order": ["C4", "C8"],
 "blocking_constraints": ["C4"],
 "rationale": "O wrapper deve impor o isolamento de tenant antes de delegar operações vetoriais para postgresql-pgvector/"
 },
 "interactions": {
 "with_validation": "verify-constraints.sh valida que NENHUM operador vetorial é gerado diretamente, apenas chamadas de delegação",
 "with_config": "Padrões de delegação alinham-se com norms-matrix.json para roteamento entre domínios",
 "with_programming": "Padrão de wrapper consumido pelo pipeline RAG antes de chamar a busca vetorial em postgresql-pgvector/"
 }
 }
 ],
 "dependency_graph": {
 "validation_layer": {
 "orchestrator-engine.sh": ["all artifacts"],
 "verify-constraints.sh": ["all artifacts"],
 "audit-secrets.sh": ["secrets-management-c3", "microservices-tenant-isolation", "go-master-agent"],
 "go-vet-validator.sh": ["hardening-verification", "sql-core-patterns", "go-master-agent"],
 "golangci-lint-check.sh": ["type-safety-with-generics", "error-handling-c7", "go-master-agent"]
 },
 "norms_layer": {
 "harness-norms-v3.0.md": ["all artifacts"],
 "10-SDD-CONSTRAINTS.md": ["all artifacts"],
 "language-lock-protocol.md": ["all artifacts"],
 "06-MULTITENANCY-RULES.md": ["microservices-tenant-isolation", "sql-core-patterns", "authentication-authorization-patterns"],
 "norms-matrix.json": ["all artifacts", "go-master-agent"]
 },
 "config_layer": {
 "skill-template.md": ["all artifacts"],
 ".env.example": ["secrets-management-c3", "microservices-tenant-isolation"],
 "go.mod": ["hardening-verification", "saas-deployment-zip-auto"],
 ".golangci.yml": ["type-safety-with-generics", "go-master-agent"]
 }
 },
 "norms_execution_priority": {
 "global_order": ["C4", "C3", "C7", "C5", "C8", "C1", "C2", "C6"],
 "rationale": "C4 (isolamento de tenant) é fundamental; segurança (C3) e segurança de concorrência (C7) precedem verificações estruturais (C5) e de observabilidade (C8)",
 "blocking_set": ["C3", "C4", "C7"],
 "non_blocking_set": ["C1", "C2", "C5", "C6", "C8"],
 "selective_v_logic": {
 "applies_to": "postgresql-pgvector/ APENAS",
 "trigger": "artifact_type == 'skill_pgvector' AND content has pgvector operators",
 "exclusion": "go/ SEMPRE exclui V1/V2/V3 por LANGUAGE LOCK (exceto postgres-pgvector-integration.go.md que é apenas wrapper de delegação)"
 }
 },
 "language_lock_enforcement": {
 "folder": "06-PROGRAMMING/go/",
 "prohibited_patterns": ["import.*pgvector|cosine_distance|l2_distance|hamming_distance|vector\\(|<->[^a-zA-Z]|<#>[^a-zA-Z]|USING\\s+(hnsw|ivfflat)"],
 "required_artifact_types": ["go_module", "go_pattern", "go_microservice", "go_cli"],
 "prohibited_constraints": ["V1", "V2", "V3"],
 "delegation_exception": {
 "file": "postgres-pgvector-integration.go.md",
 "allowed": "apenas chamadas de wrapper, NENHUMA geração direta de operador vetorial",
 "validation": "deve referenciar artefatos postgresql-pgvector/ via canonical_path"
 },
 "validation_script": "validate-skill-integrity.sh --check-language-lock",
 "failure_action": "exit 2 with message 'VIOLAÇÃO DE LANGUAGE LOCK: importações/operadores pgvector não permitidos no domínio Go'"
 },
 "ai_navigation_hints": {
 "for_generation": "Leia go-master-agent.md E este índice ANTES de gerar novos artefatos Go. Inclua comentários `// 👇 EXPLICAÇÃO:` em português para pedagogia.",
 "for_validation": "Use norms_execution_priority: valide C4 antes de permitir chamadas de DB/API em exemplos; use go-vet para análise estática",
 "for_migration": "Consulte dependency_graph antes de modificar padrões compartilhados; mudanças de concorrência podem exigir atualizações downstream",
 "for_debugging": "Verifique language_lock_enforcement se operadores pgvector aparecerem em artefatos go/; delegue para postgresql-pgvector/",
 "for_master_agent": "O agente deve consultar norms-matrix.json antes de declarar constraints; emitir JSON para stdout, logs para stderr, JSONL para 08-LOGS/; delegar lógica vetorial/SQL/embedding para os domínios apropriados; incluir comentários pedagógicos em português"
 }
}
```

---

## 🤖 STACKSELECTOR_JSONL (Hidratação Segmentada v2.3.0)

*(Bloco consumido por `query_stackselector` em `go-master-agent`)*

<!-- STACKSELECTOR_JSONL_START -->
```jsonl
{"artifact_id": "go-master-agent", "file": "go-master-agent.md", "constraints": ["C1","C2","C3","C4","C5","C7","C8"], "capability": "agentic_skill_definition", "deterministic_config_ref": "go-master-agent-mantis", "function_human": "Agente master para geração de artefatos Go"}
{"artifact_id": "00-INDEX-go", "file": "00-INDEX.md", "constraints": ["C1","C2","C3","C4","C5","C6","C7","C8"], "capability": "skill_index", "deterministic_config_ref": "00-INDEX-go", "function_human": "Índice canônico do domínio Go"}
{"artifact_id": "hardening-verification", "file": "hardening-verification.go.md", "constraints": ["C3","C4","C5","C7","C8"], "capability": "go_pattern", "deterministic_config_ref": "hardening-verification", "function_human": "Validação de ambiente Go e limites de recursos"}
{"artifact_id": "type-safety-with-generics", "file": "type-safety-with-generics.go.md", "constraints": ["C4","C5","C7","C8"], "capability": "go_pattern", "deterministic_config_ref": "type-safety-with-generics", "function_human": "Genéricos para type safety em tempo de compilação"}
{"artifact_id": "error-handling-c7", "file": "error-handling-c7.go.md", "constraints": ["C4","C5","C7","C8"], "capability": "go_pattern", "deterministic_config_ref": "error-handling-c7", "function_human": "Tratamento de erros com wrapping, retry e fallback"}
{"artifact_id": "microservices-tenant-isolation", "file": "microservices-tenant-isolation.go.md", "constraints": ["C3","C4","C5","C7","C8"], "capability": "go_pattern", "deterministic_config_ref": "microservices-tenant-isolation", "function_human": "Middleware de isolamento multi-tenant"}
{"artifact_id": "secrets-management-c3", "file": "secrets-management-c3.go.md", "constraints": ["C3","C5","C7"], "capability": "go_pattern", "deterministic_config_ref": "secrets-management-c3", "function_human": "Gestão de secrets com zero hardcode"}
{"artifact_id": "authentication-authorization-patterns", "file": "authentication-authorization-patterns.go.md", "constraints": ["C3","C4","C8"], "capability": "go_pattern", "deterministic_config_ref": "authentication-authorization-patterns", "function_human": "JWT/OAuth2 com claims de tenant_id"}
{"artifact_id": "structured-logging-c8", "file": "structured-logging-c8.go.md", "constraints": ["C4","C5","C8"], "capability": "go_pattern", "deterministic_config_ref": "structured-logging-c8", "function_human": "Logging JSON estruturado com V-LOG-02"}
{"artifact_id": "async-patterns-with-timeouts", "file": "async-patterns-with-timeouts.go.md", "constraints": ["C1","C4","C7","C8"], "capability": "go_pattern", "deterministic_config_ref": "async-patterns-with-timeouts", "function_human": "Goroutines com contextos e timeouts"}
{"artifact_id": "resource-limits-c1-c2", "file": "resource-limits-c1-c2.go.md", "constraints": ["C1","C2","C7"], "capability": "go_pattern", "deterministic_config_ref": "resource-limits-c1-c2", "function_human": "Limitação de CPU/memória em Go"}
{"artifact_id": "orchestrator-engine", "file": "orchestrator-engine.go.md", "constraints": ["C1","C3","C4","C5","C6","C7","C8"], "capability": "go_pattern", "deterministic_config_ref": "orchestrator-engine", "function_human": "Motor de validação de constraints"}
{"artifact_id": "filesystem-sandboxing", "file": "filesystem-sandboxing.go.md", "constraints": ["C3","C4","C7"], "capability": "go_pattern", "deterministic_config_ref": "filesystem-sandboxing", "function_human": "Sandbox de sistema de arquivos por tenant"}
{"artifact_id": "sql-core-patterns", "file": "sql-core-patterns.go.md", "constraints": ["C3","C4","C8"], "capability": "go_pattern", "deterministic_config_ref": "sql-core-patterns", "function_human": "Queries SQL parametrizadas com tenant_id"}
{"artifact_id": "db-selection-decision-tree", "file": "db-selection-decision-tree.go.md", "constraints": ["C4","C5","C7"], "capability": "go_pattern", "deterministic_config_ref": "db-selection-decision-tree",