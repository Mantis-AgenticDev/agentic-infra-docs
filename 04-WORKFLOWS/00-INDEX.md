---
# FRONTMATTER CANÔNICO OBRIGATÓRIO
artifact_id: "00-index-workflows-v3.0.0"
artifact_type: "directory_index"
version: "3.0.0"
constraints_mapped: ["C4","C5"]
canonical_path: "04-WORKFLOWS/00-INDEX.md"
domain: "04-WORKFLOWS"
subdomain: "root_index"
agent_role: "workflows-ceo"
language_lock: "pt-BR"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain workflows --file 04-WORKFLOWS/00-INDEX.md --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants", "human_architects"]
human_readable: true
checksum_sha256: "PENDING_GENERATION"
# FIN FRONTMATTER
---

# 📁 04-WORKFLOWS/ — Índice Mestre do Domínio de Workflows

> **Propósito**: Ponto de entrada canônico para o ecossistema de workflows do MANTIS. Este domínio contém **dois motores de execução** (n8n e LangChain/LangGraph), um **orquestrador central** (workflows-ceo), um **motor de decisão** (Stack Selector), um **guardião de privacidade** (LGPD Guard) e **195+ skills** distribuídas entre os motores. Fornece navegação estruturada, mapeamento de proprietários, constraints aplicáveis e rotas de validação para agentes e arquitetos.

## 🗺️ Mapa de Subdomínios

| Subdomínio | Rota Canônica | Agente Responsável | Owner Principal | Constraints | Estado |
|------------|---------------|-------------------|-----------------|-------------|--------|
| **Coordenação (CEO)** | `04-WORKFLOWS/workflows-ceo.md` | `workflows-ceo` | `@facundo` / `arch-team` | C1-C9 | ✅ REAL |
| **Stack Selector** | `04-WORKFLOWS/00-STACK-SELECTOR.md` | `workflows-ceo` | `@facundo` / `arch-team` | C1-C9 | ✅ REAL |
| **SDD Universal Assistant** | `04-WORKFLOWS/sdd-universal-assistant.json` | `workflows-ceo` | `@facundo` / `arch-team` | C5,C6 | ✅ REAL |
| **Módulo de Integração CEO-Stack** | `04-WORKFLOWS/libs/stack-selector-integration.md` | `workflows-ceo` | `@facundo` / `arch-team` | C1-C9 | ✅ REAL |
| **n8n Master Agent** | `04-WORKFLOWS/n8n/n8n-master-agent.md` | `n8n-master-agent` | `@facundo` / `automation-team` | C1-C9 | ✅ REAL |
| **n8n Skills (39)** | `04-WORKFLOWS/n8n/libs/` | `n8n-master-agent` | `@facundo` / `automation-team` | C1-C9 | ✅ REAL |
| **LangChain/LangGraph Master Agent** | `04-WORKFLOWS/langchain-langraph/langchain-langraph-master-agent.md` | `langchain-langraph-master-agent` | `@facundo` / `ai-team` | C1-C9 | ✅ REAL |
| **LangChain/LangGraph Skills (156)** | `04-WORKFLOWS/langchain-langraph/libs/` | `langchain-langraph-master-agent` | `@facundo` / `ai-team` | C1-C9 | ✅ REAL |
| **LGPD Guard** | `04-WORKFLOWS/lgpd-guard/lgpd-guard.md` | `lgpd-guard` | `@facundo` / `compliance-team` | C2-C8 | ✅ REAL |
| **LGPD Guard Skills (9)** | `04-WORKFLOWS/lgpd-guard/skills/` | `lgpd-guard` | `@facundo` / `compliance-team` | C2-C8 | ✅ REAL |
| **Diagramas** | `04-WORKFLOWS/diagrams/` | `workflows-ceo` | `@facundo` / `arch-team` | C5 | ✅ REAL |

## 📦 Distribuição de Skills por Motor

### 🔄 n8n (39 skills) – Automação Visual e API

| Grupo | Quantidade | Skills |
|-------|-----------|--------|
| **Core Automation** | 8 | `workflow-structure-fundamentals`, `workflow-patterns-basic`, `trigger-patterns`, `data-transformation-patterns`, `control-flow-patterns`, `loop-patterns`, `connections-patterns`, `expression-syntax-advanced` |
| **API Integration** | 4 | `api-integration-patterns`, `http-request-patterns`, `webhook-handler-secure`, `error-handling-advanced` |
| **Security & Credentials** | 3 | `credentials-security`, `security-testing-patterns`, `error-handling-patterns` |
| **Code Execution** | 3 | `code-execution-patterns`, `python-code-node`, `javascript-code-node` |
| **Data Management** | 4 | `database-file-operations`, `data-tables-patterns`, `binary-data-patterns`, `sub-workflow-patterns` |
| **MCP Integration** | 5 | `mcp-orchestrator-core`, `n8n-mcp-server-patterns`, `n8n-mcp-client-patterns`, `tool-composition-chaining`, `resource-management` |
| **AI Agentic** | 4 | `agentic-workflow-patterns`, `ai-agent-workflows-n8n`, `claude-code-integration`, `sub-workflows-advanced` |
| **Operations** | 5 | `self-hosting-patterns`, `workflow-lifecycle`, `debugging-patterns`, `workflow-testing-fundamentals`, `trigger-testing-strategies` |
| **Architecture** | 3 | `workflow-architect`, `custom-node-development`, `project-management-system` |

### 🦜 LangChain/LangGraph (156 skills em 12 domínios) – IA Pesada e Agentes

| Domínio | Quantidade | Rota Base |
|---------|-----------|-----------|
| **00-fundacional** | 4 | `04-WORKFLOWS/langchain-langraph/libs/00-fundacional/` |
| **01-langchain-tradicional** | 12 | `04-WORKFLOWS/langchain-langraph/libs/01-langchain-tradicional/` |
| **02-rag** | 10 | `04-WORKFLOWS/langchain-langraph/libs/02-rag/` |
| **03-mcp** | 25 | `04-WORKFLOWS/langchain-langraph/libs/03-mcp/` |
| **04-modelos** | 13 | `04-WORKFLOWS/langchain-langraph/libs/04-modelos/` |
| **05-bases-datos** | 15 | `04-WORKFLOWS/langchain-langraph/libs/05-bases-datos/` |
| **06-deep-agents** | 45 | `04-WORKFLOWS/langchain-langraph/libs/06-deep-agents/` |
| **07-a2a** | 4 | `04-WORKFLOWS/langchain-langraph/libs/07-a2a/` |
| **08-operaciones-langsmith** | 11 | `04-WORKFLOWS/langchain-langraph/libs/08-operaciones-langsmith/` |
| **09-seguridad** | 3 | `04-WORKFLOWS/langchain-langraph/libs/09-seguridad/` |
| **10-observabilidad** | 3 | `04-WORKFLOWS/langchain-langraph/libs/10-observabilidad/` |
| **11-swarm-supervisor** | 9 | `04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/` |
| **12-langgraph-api** | 12 | `04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/` |

> **Nota**: A lista completa e detalhada das 156 skills (com nomes de arquivos, propósitos e condições de carregamento) está documentada no `langchain-langraph-master-agent.md`. Este índice referencia o master agent como fonte de verdade.

### 🛡️ LGPD Guard (9 skills) – Conformidade e Privacidade

| Skill | Arquivo | Propósito |
|-------|---------|-----------|
| **Data Classifier** | `skills/data-classifier.md` | Classificação automática de dados (pessoal, sensível, público, anonimizado) |
| **Consent Management** | `skills/consent-management.md` | Gestão de consentimentos (opt-in, opt-out, revogação) |
| **DSAR Handling** | `skills/dsar-handling.md` | Tratamento de requisições de titulares (acesso, correção, eliminação) |
| **Audit Logging** | `skills/audit-logging.md` | Logs de auditoria para todas as operações com dados pessoais |
| **Retention & Deletion** | `skills/retention-deletion.md` | Políticas de retenção e exclusão de dados |
| **Privacy Notice Template** | `skills/privacy-notice-template.md` | Geração de avisos de privacidade |
| **PII Redaction** | `skills/pii-redaction.md` | Sanitização de dados pessoais antes de envio a LLMs |
| **RIPD Generator** | `skills/ripd-generator.md` | Geração de Relatório de Impacto à Proteção de Dados |
| **Incident Response** | `skills/incident-response.md` | Resposta a incidentes de violação de dados |

## 🛠️ Scripts Críticos & Acessos Rápidos

| Comando | Propósito | Domínio | Validação |
|---------|-----------|---------|------------|
| `workflows-ceo.process_task(task.json)` | Entrada principal do CEO: recebe goal e orquestra motores | Root | `orchestrator-engine.sh` |
| `StackSelectorIntegration.process_task(task.json)` | Classifica tarefa e gera execution_plan.json | libs/ | `validate-frontmatter.sh` |
| `n8n-master-agent.generate_workflow(sdd)` | Gera workflow n8n a partir de especificação | n8n/ | `n8n-schema-validator.sh` |
| `langchain-langraph-master-agent.generate_artifact(sdd)` | Gera artefacto LangChain/LangGraph | langchain-langraph/ | `orchestrator-engine.sh --check C1-C8` |
| `lgpd-guard.validate_pii(task)` | Valida se task contém dados pessoais e aplica conformidade | lgpd-guard/ | `check-rls.sh`, `audit-secrets.sh` |

## 📐 Matriz de Validação & Constraints (C1-C9)

| Constraint | Descrição | Domínio(s) Aplicáveis | Ferramenta de Validação |
|------------|-----------|------------------------|-------------------------|
| **C1** | Resiliência / Timeout | Todos | `orchestrator-engine.sh` |
| **C2** | Validação de Input | `n8n/`, `langchain-langraph/` | `validate-frontmatter.sh` |
| **C3** | Zero Secrets em Texto Plano | Todos | `audit-secrets.sh` |
| **C4** | Tenant Isolation | `lgpd-guard/`, `langchain-langraph/05-bases-datos/` | `check-rls.sh` |
| **C5** | Integridade Estrutural (Frontmatter) | Todos | `validate-frontmatter.sh` |
| **C6** | Multi-Tenancy / Aprovações | `lgpd-guard/`, `n8n/` | `check-rls.sh`, `compliance-audit.sh` |
| **C7** | Versionamento / Resiliência | `langchain-langraph/12-langgraph-api/`, `n8n/` | `verify-constraints.sh` |
| **C8** | Observabilidade / Logging | Todos | `check-wikilinks.sh` |
| **C9** | Contrato A2A / Handoff | `workflows-ceo.md`, agentes | `check-a2a-contract.sh` |

## 🤖 Guias de Ingestão para Agentes (C4/C5)

### Regras de Navegação
1. **Entrada única**: Todo agente externo deve entrar pelo `workflows-ceo`. O CEO consulta o Stack Selector e delega.
2. **Stack Selector primeiro**: Antes de qualquer geração, o CEO DEVE carregar `04-WORKFLOWS/00-STACK-SELECTOR.md` para resolver motor e skills.
3. **Não assumir motor**: Nunca gerar artefactos em `04-WORKFLOWS/` sem antes consultar o Stack Selector.
4. **Idioma**: `pt-BR` como padrão para todos os artefactos.
5. **Frontmatter obrigatório**: Todo artefacto deve seguir o template modular v2.3.0 com `artifact_id`, `constraints_mapped`, `validation_command`.

### Comandos de Validação Padrão
```bash
# Validação completa do domínio
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain workflows --strict

# Validação de skill individual
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file <caminho-da-skill> --json

# Verificação do Stack Selector
jq empty 04-WORKFLOWS/00-STACK-SELECTOR.md && echo "✅ JSON válido"

# Auditoria de handoffs A2A
python3 goals/scripts/check_a2a_contract.py --task-id "$TASK_ID" --agent "$AGENT_NAME" --json
```

## ⚠️ Anti-Padrões Explícitos (NÃO FAZER)
- ❌ Gerar artefactos em `04-WORKFLOWS/` sem passar pelo `workflows-ceo` e pelo Stack Selector
- ❌ Usar `n8n` para tarefas de IA complexa (RAG, enxames, agentes profundos)
- ❌ Usar `LangChain/LangGraph` para automações simples (webhooks, ETL, notificações)
- ❌ Ignorar validação LGPD quando `data_contains_pii = true`
- ❌ Omitir `validation_command` no frontmatter de novos artefactos
- ❌ Modificar o Stack Selector sem aprovação humana (`requires_human_approval_for_changes: true`)
- ❌ Handoff entre agentes sem `status.json` com `trace_id` e `span_id` (viola C9)

## 📊 Estado do Domínio & Métricas
- **Última auditoria completa**: 2026-05-28T04:00:00Z
- **Versão do CEO**: 2.3.0 (stack selector integration embutido)
- **Versão do Stack Selector**: 3.0.0-WORKFLOWS (JSON kernel parseável)
- **Versão do SDD Universal Assistant**: 4.0.0-WORKFLOWS
- **Total de skills**: 204 (39 n8n + 156 langchain-langraph + 9 lgpd-guard)
- **Total de artefactos governados**: 210+ (skills + master agents + CEO + Stack Selector + SDD + libs)
- **Motores de workflow**: 2 (n8n, LangChain/LangGraph)
- **Domínios internos do LangChain/LangGraph**: 12
- **Próxima revisão de governança**: 2026-08-28

## 🔗 Links Canônicos Relacionados
- [[04-WORKFLOWS/00-STACK-SELECTOR.md]] → Kernel de roteamento e seleção de motor/skills
- [[04-WORKFLOWS/workflows-ceo.md]] → Agente coordenador do domínio
- [[04-WORKFLOWS/sdd-universal-assistant.json]] → Workflow de orquestração e validação
- [[04-WORKFLOWS/libs/stack-selector-integration.md]] → Módulo de integração CEO-Stack Selector
- [[04-WORKFLOWS/n8n/n8n-master-agent.md]] → Master Agent do motor n8n (39 skills)
- [[04-WORKFLOWS/langchain-langraph/langchain-langraph-master-agent.md]] → Master Agent do motor LangChain/LangGraph (156 skills)
- [[04-WORKFLOWS/lgpd-guard/lgpd-guard.md]] → Guardião de privacidade LGPD
- [[00-STACK-SELECTOR.md]] → Kernel global de seleção de stacks (raiz do projeto)
- [[IA-QUICKSTART.md]] → Protocolo ACG e gates de modo
- [[GOVERNANCE-ORCHESTRATOR.md]] → Governança central do projeto
- [[05-CONFIGURATIONS/validation/norms-matrix.json]] → Matriz de constraints por domínio

---
*Documento gerado por `workflows-ceo` v2.3.0 | Mantido por `workflows-ceo` | Constraints: C4, C5*
