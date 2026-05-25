---
artifact_id: "distributed-tracing-server"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/distributed-tracing-server.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/distributed-tracing-server.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:distributed-tracing-v1"
generated_at: "2026-05-26T10:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["langgraph-create-agent", "a2a-protocol-core"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-07-25"
---

# 🧩 Distributed Tracing com Agent Server

> **Contrato modular**: Artefato filho do Master Agent `langchain-langraph-master-agent`. Herda hardening, observability. Implementa a propagação de contexto de trace entre Agent Servers e clientes.

## 🎯 Propósito

Unificar traces distribuídos ao chamar um Agent Server a partir de outro serviço, usando os cabeçalhos `langsmith-trace` e `baggage` via RemoteGraph ou SDK, para que toda a requisição apareça como uma única trace no LangSmith.

## 📋 Especificação (SDD)
- **Entradas**: Configuração do grafo, `distributed_tracing=True`, cabeçalhos de trace
- **Saídas**: Trace unificada no LangSmith, execução remota como child span
- **Side Effects**: Propagação de `langsmith-trace`, `langsmith-project`, metadados e tags
- **Constraints Aplicáveis**: C1 (Resiliência), C5 (Integridade), C8 (Observabilidade), C9 (A2A)
- **Dependências**: `langgraph-sdk`, `langgraph`, `langsmith`, `contextlib`, `pytest`

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from langchain_langraph_master_agent import mantis_log
except ImportError:
    import json, datetime, os
    def mantis_log(level, event, detail=""):
        entry = {
            "ts": datetime.datetime.utcnow().isoformat() + "Z",
            "level": level,
            "tenant": os.getenv("TENANT_ID", "global"),
            "event": event,
            "detail": detail,
            "trace_id": os.getenv("TRACE_ID", "null"),
            "span_id": os.getenv("SPAN_ID", "null"),
            "fallback": "true"
        }
        print(json.dumps(entry), flush=True)
    mantis_log("WARN", "bootstrap_fallback", "Master Agent langchain-langraph não encontrado.")

# ─── IMPLEMENTAÇÃO PRINCIPAL ─────────────────────────────────────────────
import contextlib
from typing import AsyncGenerator, Optional, Any
import langsmith as ls
from langgraph.graph import StateGraph, MessagesState
from langgraph.pregel.remote import RemoteGraph
from langgraph_sdk import get_client

# ═══════════════════════════════════════════════════════════════════════════
# 1. SERVIDOR: GRAPH QUE ACEITA CABEÇALHOS DE TRACE DISTRIBUÍDO
# ═══════════════════════════════════════════════════════════════════════════
def build_my_graph() -> StateGraph:
    """Constrói um grafo de exemplo com um nó simples."""
    from langchain.chat_models import init_chat_model
    model = init_chat_model("gpt-4o", temperature=0)
    
    def assistant(state):
        response = model.invoke(state["messages"])
        return {"messages": [response]}
    
    builder = StateGraph(MessagesState)
    builder.add_node("assistant", assistant)
    builder.add_edge("__start__", "assistant")
    return builder.compile()

@contextlib.asynccontextmanager
async def graph_with_distributed_tracing(config: dict) -> AsyncGenerator[StateGraph, None]:
    """
    Context manager que extrai headers de trace e configura o tracing_context.
    Uso no Agent Server: exportar esta função como 'graph' no langgraph.json.
    """
    configurable = config.get("configurable", {})
    parent_trace = configurable.get("langsmith-trace")
    parent_project = configurable.get("langsmith-project")
    metadata = configurable.get("langsmith-metadata", {})
    tags = configurable.get("langsmith-tags", [])

    mantis_log("INFO", "tracing_headers", f"parent_trace={parent_trace}, project={parent_project}")

    with ls.tracing_context(
        parent=parent_trace,
        project_name=parent_project,
        metadata=metadata,
        tags=tags
    ):
        graph = build_my_graph()
        yield graph

# ═══════════════════════════════════════════════════════════════════════════
# 2. CLIENTE: USANDO REMOTEGRAPH COM TRACE DISTRIBUÍDO
# ═══════════════════════════════════════════════════════════════════════════
class DistributedRemoteGraph:
    """Encapsula RemoteGraph com propagação automática de traces."""
    def __init__(self, graph_name: str, deployment_url: str, api_key: str):
        self.graph = RemoteGraph(
            graph_name,
            url=deployment_url,
            api_key=api_key,
            distributed_tracing=True  # Ativa propagação automática
        )

    async def invoke(self, messages: list, metadata: dict = None) -> dict:
        mantis_log("INFO", "remote_invoke", f"Enviando {len(messages)} mensagens")
        return await self.graph.ainvoke(
            {"messages": messages},
            config={"metadata": metadata or {}}
        )

    async def stream(self, messages: list):
        async for event in self.graph.astream(
            {"messages": messages},
            stream_mode="values"
        ):
            yield event

# ═══════════════════════════════════════════════════════════════════════════
# 3. CLIENTE MANUAL: USANDO SDK COM run_tree.to_headers()
# ═══════════════════════════════════════════════════════════════════════════
class ManualTraceClient:
    """Propaga trace manualmente via SDK, útil quando RemoteGraph não é suficiente."""
    def __init__(self, deployment_url: str, api_key: str):
        self.url = deployment_url
        self.api_key = api_key

    async def call_remote_agent(self, assistant_id: str, query: str) -> dict:
        client = get_client(url=self.url, api_key=self.api_key)
        with ls.trace("call_remote_agent", inputs={"query": query}) as rt:
            headers = rt.to_headers()
            mantis_log("INFO", "manual_trace_headers", f"Headers={headers}")
            chunks = []
            async for chunk in client.runs.stream(
                thread_id=None,
                assistant_id=assistant_id,
                input={"messages": [{"role": "user", "content": query}]},
                stream_mode="values",
                headers=headers
            ):
                chunks.append(chunk)
            return chunks[-1] if chunks else {}

# ═══════════════════════════════════════════════════════════════════════════
# 4. FUNÇÃO DE TESTE QUE SIMULA CHAMADA REMOTA DENTRO DE UM GRAFO LOCAL
# ═══════════════════════════════════════════════════════════════════════════
def build_local_orchestrator_graph(remote_graph_name: str, remote_url: str, api_key: str):
    """Grafo local que chama RemoteGraph como um nó, herdando trace automaticamente."""
    remote = RemoteGraph(remote_graph_name, url=remote_url, api_key=api_key, distributed_tracing=True)
    builder = StateGraph(MessagesState)
    
    def call_remote(state):
        result = remote.invoke({"messages": state["messages"]})
        return {"messages": result["messages"]}
    
    builder.add_node("remote_node", call_remote)
    builder.add_edge("__start__", "remote_node")
    return builder.compile()

# ═══════════════════════════════════════════════════════════════════════════
# 5. CONFIGURAÇÃO DO LANGGRAPH.JSON (EXEMPLO COMENTADO)
# ═══════════════════════════════════════════════════════════════════════════
CONFIG_EXAMPLE = """
{
  "graphs": {
    "agent": "./src/agent.py:graph"
  }
}
"""
# O servidor deve exportar 'graph_with_distributed_tracing' como 'graph'.

# ═══════════════════════════════════════════════════════════════════════════
# 6. MONITORAMENTO DE CABEÇALHOS DE TRACE (MIDDLEWARE DE LOG)
# ═══════════════════════════════════════════════════════════════════════════
class TraceHeaderLogger:
    """Middleware que loga todos os cabeçalhos de trace recebidos."""
    @staticmethod
    def log_headers(config):
        configurable = config.get("configurable", {})
        mantis_log("INFO", "incoming_trace_headers", 
                   f"trace={configurable.get('langsmith-trace')}, "
                   f"project={configurable.get('langsmith-project')}, "
                   f"metadata={configurable.get('langsmith-metadata')}")
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from unittest.mock import patch, MagicMock

def test_graph_with_distributed_tracing():
    import asyncio
    from distributed_tracing_server import graph_with_distributed_tracing
    config = {
        "configurable": {
            "langsmith-trace": "parent-trace-id",
            "langsmith-project": "test-project",
            "langsmith-metadata": {"key": "val"},
            "langsmith-tags": ["tag1"]
        }
    }
    async def run():
        async with graph_with_distributed_tracing(config) as g:
            assert isinstance(g, StateGraph)
    asyncio.run(run())

@patch('distributed_tracing_server.RemoteGraph')
def test_distributed_remote_graph(mock_remote):
    dg = DistributedRemoteGraph("test_graph", "http://localhost:8123", "key")
    assert dg.graph.distributed_tracing == True
    mock_remote.assert_called_once_with(
        "test_graph", url="http://localhost:8123", api_key="key", distributed_tracing=True
    )

def test_trace_header_logger(capsys):
    config = {"configurable": {"langsmith-trace": "trace-123"}}
    TraceHeaderLogger.log_headers(config)
    captured = capsys.readouterr()
    assert "trace-123" in captured.out
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/distributed-tracing-server.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[langgraph-create-agent.md]]
- [[a2a-protocol-core.md]]
