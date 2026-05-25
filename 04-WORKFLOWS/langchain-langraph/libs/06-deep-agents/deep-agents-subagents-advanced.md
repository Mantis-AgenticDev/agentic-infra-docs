---
artifact_id: "deep-agents-subagents-advanced"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-subagents-advanced.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-subagents-advanced.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-subagents-adv-v1.0.0"
generated_at: "2026-05-25T13:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-subagents-fundamentals", "deep-agents-orchestration-planning"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧩 Deep Agents – Subagentes Avançados e Padrões

> **Contrato modular**: Artefato filho do Master Agent. Cobre padrões avançados de subagentes: CompiledSubAgent, custom graphs, múltiplos níveis de delegação, tratamento de erros, boas práticas de descrição e prompt, e troubleshooting.

---

## 🎯 Propósito
Elevar o uso de subagentes para cenários complexos, incluindo subagentes com grafos customizados, subagentes em cascata e estratégias de isolamento de contexto.

## 📋 Especificação (SDD)
- **Entradas**: Grafos LangGraph compilados, configurações avançadas de subagentes.
- **Saídas**: Subagentes integrados ao ecossistema MANTIS.
- **Side Effects**: Execução de grafos arbitrários como subagentes.
- **Constraints Aplicáveis**: C1 (contrato de Runnable), C3 (isolamento), C5 (schema), C7 (falha isolada), C8 (tracing), C9 (trace_id).
- **Dependências**: `deepagents`, `langgraph`, `langchain.agents`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    import json, datetime, os
    def mantis_log(level, event, detail=""):
        entry = {"ts": datetime.datetime.utcnow().isoformat() + "Z", "level": level, "tenant": os.getenv("TENANT_ID", "global"), "event": event, "detail": detail, "trace_id": os.getenv("TRACE_ID", "null"), "span_id": os.getenv("SPAN_ID", "null"), "fallback": "true"}
        print(json.dumps(entry), flush=True)
```

### 1. CompiledSubAgent – Subagente com Grafo Customizado

```python
from deepagents import create_deep_agent, CompiledSubAgent
from langchain.agents import create_agent

# Cria um grafo customizado com create_agent
custom_graph = create_agent(
    model="openai:gpt-5.4",
    tools=[specialized_data_tool, statistical_analysis],
    prompt="Você é um analista de dados especializado. Analise os dados fornecidos e retorne insights.",
)

custom_subagent = CompiledSubAgent(
    name="data-analyzer",
    description="Analisa dados complexos e retorna insights estatísticos",
    runnable=custom_graph,
)

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    subagents=[custom_subagent],
)
```

### 2. Subagente com Grafo LangGraph Puro

```python
from langgraph.graph import StateGraph, MessagesState, START, END
from langgraph.prebuilt import ToolNode, tools_condition

def build_custom_subagent_graph(tools, model):
    def call_model(state: MessagesState):
        response = model.bind_tools(tools).invoke(state["messages"])
        return {"messages": response}

    builder = StateGraph(MessagesState)
    builder.add_node("call_model", call_model)
    builder.add_node("tools", ToolNode(tools))
    builder.add_edge(START, "call_model")
    builder.add_conditional_edges("call_model", tools_condition)
    builder.add_edge("tools", "call_model")
    return builder.compile()

custom_tools = [fetch_data, clean_data, generate_chart]
model = init_chat_model("openai:gpt-5.4")
graph = build_custom_subagent_graph(custom_tools, model)

custom_subagent = CompiledSubAgent(
    name="data-processor",
    description="Processa dados brutos: busca, limpa e gera visualizações",
    runnable=graph,
)
```

### 3. Padrão: Subagentes em Cascata (Workflow)

```python
subagents = [
    {
        "name": "data-collector",
        "description": "Coleta dados brutos de APIs e salva em /workspace/data/",
        "system_prompt": "Colete dados sobre o tópico solicitado e salve em /workspace/data/raw.json. Retorne 'Dados coletados com sucesso.'",
        "tools": [fetch_api_data, write_file],
    },
    {
        "name": "data-analyzer",
        "description": "Analisa dados salvos em /workspace/data/ e gera insights",
        "system_prompt": "Leia /workspace/data/raw.json, faça análise estatística e salve em /workspace/analysis/summary.md.",
        "tools": [read_file, write_file, statistical_analysis],
    },
    {
        "name": "report-writer",
        "description": "Escreve relatório final a partir da análise",
        "system_prompt": "Leia /workspace/analysis/summary.md e produza um relatório executivo em /workspace/report/final.md.",
        "tools": [read_file, write_file],
    },
]

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    system_prompt="""Você é um gerente de projetos. Para cada tarefa:
    1. Delegue coleta de dados ao data-collector.
    2. Depois, delegue análise ao data-analyzer.
    3. Por fim, delegue a escrita do relatório ao report-writer.
    Sempre aguarde cada etapa concluir antes de iniciar a próxima.""",
    subagents=subagents,
)
```

### 4. Boas Práticas: Descrições Claras e Acionáveis

```python
# ✅ BOA descrição
{
    "name": "financial-analyst",
    "description": "Analisa dados financeiros e gera insights de investimento com scores de confiança. Use para tarefas que exigem análise numérica e projeções.",
}

# ❌ DESCRIÇÃO RUIM
{
    "name": "helper",
    "description": "ajuda com coisas",
}
```

### 5. Boas Práticas: System Prompts Detalhados

```python
research_subagent = {
    "name": "research-agent",
    "description": "Conduz pesquisas aprofundadas usando busca na web e sintetiza achados",
    "system_prompt": """Você é um pesquisador minucioso. Suas responsabilidades:

    1. Decomponha a pergunta de pesquisa em consultas buscáveis
    2. Use internet_search para encontrar informações relevantes
    3. Sintetize os achados em um resumo abrangente mas conciso
    4. Cite fontes ao fazer afirmações

    Formato de saída:
    - Resumo (2-3 parágrafos)
    - Principais achados (bullet points)
    - Fontes (com URLs)

    Mantenha sua resposta em menos de 500 palavras para preservar o contexto.""",
    "tools": [internet_search],
}
```

### 6. Minimizando Conjuntos de Ferramentas

```python
# ✅ Bom: ferramentas focadas
email_agent = {
    "name": "email-sender",
    "tools": [send_email, validate_email],
}

# ❌ Ruim: ferramentas demais
email_agent = {
    "name": "email-sender",
    "tools": [send_email, web_search, database_query, file_upload],
}
```

### 7. Escolha de Modelos por Tarefa

```python
subagents = [
    {
        "name": "contract-reviewer",
        "description": "Revisa documentos legais e contratos",
        "system_prompt": "Você é um revisor jurídico especialista...",
        "tools": [read_document, analyze_contract],
        "model": "google_genai:gemini-3.5-flash",  # Contexto grande para documentos longos
    },
    {
        "name": "financial-analyst",
        "description": "Analisa dados financeiros e tendências de mercado",
        "system_prompt": "Você é um analista financeiro especialista...",
        "tools": [get_stock_price, analyze_fundamentals],
        "model": "openai:gpt-5.4",  # Melhor para análise numérica
    },
]
```

### 8. Retorno de Resultados Concisos

```python
data_analyst = {
    "system_prompt": """Analise os dados e retorne:
    1. Insights principais (3-5 bullet points)
    2. Score de confiança geral
    3. Ações recomendadas

    NÃO inclua:
    - Dados brutos
    - Cálculos intermediários
    - Saídas detalhadas de ferramentas

    Mantenha a resposta em menos de 300 palavras."""
}
```

### 9. Troubleshooting: Subagente Não Está Sendo Chamado

```python
# Solução 1: Descrições mais específicas
{
    "name": "research-specialist",
    "description": "Conduz pesquisas aprofundadas sobre tópicos específicos usando busca na web. Use quando precisar de informações detalhadas que exigem múltiplas buscas."
}

# Solução 2: Instruir o agente principal a delegar
agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    system_prompt="""...suas instruções...
    IMPORTANTE: Para tarefas complexas, delegue aos seus subagentes usando a ferramenta task().
    Isso mantém seu contexto limpo e melhora os resultados.""",
    subagents=[...]
)
```

### 10. Troubleshooting: Contexto Ainda Inchando

```python
# Solução: Subagente deve retornar apenas o essencial
system_prompt="""...
IMPORTANTE: Retorne apenas o resumo essencial.
NÃO inclua dados brutos, resultados intermediários de busca, ou saídas detalhadas de ferramentas.
Sua resposta deve ter menos de 500 palavras."""

# Solução alternativa: usar filesystem para dados grandes
system_prompt="""Quando você coletar grandes quantidades de dados:
1. Salve dados brutos em /workspace/raw_results.txt
2. Processe e analise os dados
3. Retorne apenas o resumo da análise
Isso mantém o contexto limpo."""
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_compiled_subagent():
    from langchain.agents import create_agent
    graph = create_agent(model="openai:gpt-5.4", tools=[], prompt="You are a test agent.")
    compiled = CompiledSubAgent(name="test", description="test", runnable=graph)
    assert compiled.name == "test"
    assert compiled.runnable is not None

def test_cascade_workflow():
    # Verificar que subagentes em cascata podem ser criados
    subagents = [
        {"name": "step1", "description": "Step 1", "system_prompt": "Do step 1", "tools": []},
        {"name": "step2", "description": "Step 2", "system_prompt": "Do step 2", "tools": []},
    ]
    agent = create_deep_agent(model="openai:gpt-5.4", subagents=subagents)
    assert agent is not None
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-subagents-advanced.md --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[deep-agents-subagents-fundamentals.md]]
- [[deep-agents-orchestration-planning.md]]
- [[langchain-langraph-master-agent.md]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-25T13:30:00Z | langchain-langraph-master-agent | Criação inicial: subagentes avançados | C1,C3,C5,C7,C8,C9 |
