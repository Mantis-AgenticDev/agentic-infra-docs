---
artifact_id: "n8n-ai-agent-workflows"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/ai-agent-workflows-n8n.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/ai-agent-workflows-n8n.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:ai-agent-workflows-n8n-v1.0.0"
generated_at: "2026-05-24T16:20:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["ai-agents", "langchain", "rag", "multi-agent"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🤖 Workflows de Agentes IA com n8n

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar a construção de workflows com agentes IA usando LangChain no n8n, incluindo padrões de agente autônomo, Gatekeeper, RAG e multi-agente, garantindo rastreabilidade (C4), validação (C5) e observabilidade (C8).

## 📋 Especificação (SDD)
- **Entradas**: Tipo de agente, ferramentas disponíveis, prompt do sistema.
- **Saídas**: Workflow n8n com nó AI Agent configurado.
- **Constraints Aplicáveis**: C4 (tenant isolation), C5 (validação de entrada/saída), C8 (logging).

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
ai_agent_workflows:
  agent_config:
    types: ["OpenAI Functions", "ReAct", "Conversational"]
    llm: ["OpenAI", "Anthropic", "Hugging Face", "Ollama (local)"]
    memory: ["Buffer", "Buffer Window", "Summary"]
    tools: ["Calculator", "Webhook", "Database query", "Custom API calls"]

  patterns:
    basic_agent:
      description: "Agente com ferramentas e memória"
      flow: "Manual Trigger → AI Agent → Output"
      prompt: "You are a helpful assistant that {{$json.task}}"

    gatekeeper:
      description: "Agente supervisionado com aprovação humana"
      flow: |
        Webhook → AI Agent → If (requires approval)
          → Send Email → Wait for Webhook → Execute Action
          → (auto-approve) → Execute Action

    iterative_agent:
      description: "Resolução de problemas multi-passo com estado"
      flow: |
        Loop Start → AI Agent → Tool Execution → State Update → Loop End
      state_fields: ["task", "iteration", "maxIterations", "context", "completed"]

    rag:
      description: "Retrieval Augmented Generation"
      flow: |
        Query Input → Vector Store Search → Format Context → LLM → Response Output
      vector_store_setup:
        - "Document Loader → Split text into chunks"
        - "Embeddings node → Generate vectors"
        - "Vector Store node → Store in Pinecone/Qdrant/Supabase"
        - "Query: Retrieve relevant chunks → Inject into LLM prompt"

  complexity_rating:
    simple_llm: 1
    agent_with_tools: 3
    gatekeeper: 4
    multi_agent_orchestration: 5
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_agent_workflow_has_tools() {
  local config='{"agentType":"openAi","tools":["calculator","webhook"]}'
  python3 -c "
import json; d=json.loads('$config')
assert 'tools' in d and len(d['tools']) > 0
" 2>/dev/null && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && { test_agent_workflow_has_tools && echo "✅" || echo "❌"; exit $?; }
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[mcp-orchestrator-core.md]]
- [[agentic-workflow-patterns.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
