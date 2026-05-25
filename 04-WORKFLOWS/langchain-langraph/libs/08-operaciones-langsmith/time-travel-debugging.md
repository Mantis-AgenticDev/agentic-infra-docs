**Gerando Lote 1: Artefactos 1 a 4 — Time Travel, Tracing Distribuído, Webhooks e Infra do Data Plane**

---

```yaml
---
artifact_id: "time-travel-debugging"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/time-travel-debugging.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/time-travel-debugging.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:time-travel-v1"
generated_at: "2026-05-26T10:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["langgraph-state-graph-fundamentals", "langgraph-create-agent"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-07-25"
---

# 🧩 Time Travel & Depuração com API do Agent Server

> **Contrato modular**: Artefato filho do Master Agent `langchain-langraph-master-agent`. Herda hardening, observability e constraints. Contém APENAS a lógica para navegação temporal, modificação de estado e re-execução a partir de checkpoints históricos.

## 🎯 Propósito

Permitir a depuração avançada e a re-execução controlada de fluxos LangGraph através da API do Agent Server, utilizando os métodos `get_history`, `update_state` e `runs.wait`/`stream` para viajar no tempo e criar forks na execução.

## 📋 Especificação (SDD)
- **Entradas**: `thread_id`, `checkpoint_id` (opcional), novo estado (opcional)
- **Saídas**: Novo `run_id` após re-execução, estado final do thread
- **Side Effects**: Criação de novo checkpoint e fork na história do thread
- **Constraints Aplicáveis**: C1 (Resiliência), C3 (Segurança), C5 (Integridade), C7 (Versionamento), C8 (Observabilidade), C9 (A2A)
- **Dependências**: `langgraph-sdk`, `langgraph-checkpoint`, `pytest`, `pytest-asyncio`

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

# ─── IMPORTAÇÕES ──────────────────────────────────────────────────────────
import asyncio
from typing import Optional, Any, Dict, List, Tuple, AsyncIterator
from langgraph_sdk import get_client
from langgraph_sdk.client import LangGraphClient
import logging
import sys

logger = logging.getLogger("time-travel")

# ═══════════════════════════════════════════════════════════════════════════
# 1. CONEXÃO RESILIENTE COM RETRY (C1)
# ═══════════════════════════════════════════════════════════════════════════
class ResilientClient:
    """Wrapper com retry e circuit breaker simples para o cliente SDK."""
    def __init__(self, deployment_url: str, api_key: str, max_retries: int = 3):
        self.url = deployment_url
        self.api_key = api_key
        self.max_retries = max_retries
        self._client: Optional[LangGraphClient] = None

    async def get_client(self) -> LangGraphClient:
        if self._client is None:
            self._client = get_client(url=self.url, api_key=self.api_key)
        return self._client

    async def _retry(self, coro, *args, **kwargs):
        last_exc = None
        for attempt in range(self.max_retries):
            try:
                return await coro(*args, **kwargs)
            except Exception as e:
                last_exc = e
                mantis_log("WARN", "retry_attempt", f"Tentativa {attempt+1}/{self.max_retries} falhou: {str(e)}")
                if attempt < self.max_retries - 1:
                    await asyncio.sleep(2 ** attempt)
        raise last_exc

    async def wait_for_run(self, thread_id, assistant_id, input=None, checkpoint_id=None):
        client = await self.get_client()
        async def _call():
            return await client.runs.wait(
                thread_id=thread_id,
                assistant_id=assistant_id,
                input=input,
                checkpoint_id=checkpoint_id
            )
        return await self._retry(_call)

    async def stream_run(self, thread_id, assistant_id, input=None, checkpoint_id=None):
        client = await self.get_client()
        async def _stream():
            chunks = []
            async for chunk in client.runs.stream(
                thread_id=thread_id,
                assistant_id=assistant_id,
                input=input,
                checkpoint_id=checkpoint_id,
                stream_mode="values"
            ):
                chunks.append(chunk)
            return chunks
        return await self._retry(_stream)

    async def get_history(self, thread_id):
        client = await self.get_client()
        async def _get():
            return await client.threads.get_history(thread_id)
        return await self._retry(_get)

    async def update_state(self, thread_id, values, checkpoint_id=None):
        client = await self.get_client()
        async def _update():
            return await client.threads.update_state(
                thread_id=thread_id,
                values=values,
                checkpoint_id=checkpoint_id
            )
        return await self._retry(_update)

# ═══════════════════════════════════════════════════════════════════════════
# 2. MÓDULO DE TIME TRAVEL (LÓGICA PRINCIPAL)
# ═══════════════════════════════════════════════════════════════════════════
class TimeTraveler:
    """
    Gerencia viagem no tempo em threads LangGraph.
    Permite listar checkpoints, modificar estado e re-executar a partir de qualquer ponto.
    """
    def __init__(self, client: ResilientClient, assistant_id: str):
        self.client = client
        self.assistant_id = assistant_id

    async def list_checkpoints(self, thread_id: str) -> List[Dict[str, Any]]:
        """Retorna lista de checkpoints (do mais recente ao mais antigo)."""
        mantis_log("INFO", "list_checkpoints", f"Thread={thread_id}")
        states = await self.client.get_history(thread_id)
        checkpoints = [
            {
                "checkpoint_id": s["checkpoint_id"],
                "created_at": s.get("created_at"),
                "values": s.get("values"),
                "parent_checkpoint_id": s.get("parent_checkpoint_id")
            }
            for s in states
        ]
        mantis_log("INFO", "checkpoints_listed", f"Total={len(checkpoints)}")
        return checkpoints

    async def rewind_and_modify(
        self,
        thread_id: str,
        target_checkpoint_id: str,
        new_values: Optional[Dict[str, Any]] = None
    ) -> str:
        """
        Retrocede para um checkpoint e, opcionalmente, modifica o estado antes de re-executar.
        Retorna o novo run_id.
        """
        mantis_log("INFO", "rewind_and_modify", f"Thread={thread_id}, Checkpoint={target_checkpoint_id}")
        if new_values:
            # Atualiza estado no checkpoint
            config = await self.client.update_state(
                thread_id=thread_id,
                values=new_values,
                checkpoint_id=target_checkpoint_id
            )
            mantis_log("INFO", "state_updated", f"Novo checkpoint_id={config['checkpoint_id']}")
            target_checkpoint_id = config["checkpoint_id"]

        # Re-executa a partir do checkpoint
        run = await self.client.wait_for_run(
            thread_id=thread_id,
            assistant_id=self.assistant_id,
            input=None,
            checkpoint_id=target_checkpoint_id
        )
        mantis_log("INFO", "run_created", f"Run ID={run['run_id']}")
        return run["run_id"]

    async def fork_and_explore(
        self,
        thread_id: str,
        checkpoint_index: int = -2  # penúltimo por padrão
    ) -> str:
        """
        Cria um fork a partir de um checkpoint histórico e executa com o mesmo estado (time travel puro).
        checkpoint_index: 0 = mais recente, -1 = anterior, etc.
        """
        checkpoints = await self.list_checkpoints(thread_id)
        if not checkpoints:
            raise ValueError("Nenhum checkpoint encontrado")
        idx = checkpoint_index
        if idx < 0:
            idx = len(checkpoints) + idx
        target = checkpoints[idx]
        mantis_log("INFO", "fork_and_explore", f"Usando checkpoint {target['checkpoint_id']}")
        return await self.rewind_and_modify(
            thread_id=thread_id,
            target_checkpoint_id=target["checkpoint_id"]
        )

    async def replay_with_alternative_input(
        self,
        thread_id: str,
        alternative_values: Dict[str, Any],
        checkpoint_index: int = -2
    ) -> str:
        """
        Modifica o estado do checkpoint selecionado e re-executa.
        """
        checkpoints = await self.list_checkpoints(thread_id)
        if not checkpoints:
            raise ValueError("Nenhum checkpoint encontrado")
        idx = checkpoint_index if checkpoint_index >= 0 else len(checkpoints) + checkpoint_index
        target = checkpoints[idx]
        mantis_log("INFO", "replay_alternative", f"Alterando estado em {target['checkpoint_id']}")
        return await self.rewind_and_modify(
            thread_id=thread_id,
            target_checkpoint_id=target["checkpoint_id"],
            new_values=alternative_values
        )

    async def compare_forks(
        self,
        thread_id: str,
        modifications: List[Dict[str, Any]]
    ) -> List[Dict[str, Any]]:
        """
        Cria múltiplos forks com diferentes modificações a partir do mesmo checkpoint e retorna os resultados.
        """
        checkpoints = await self.list_checkpoints(thread_id)
        if len(checkpoints) < 2:
            raise ValueError("Precisa de pelo menos 2 checkpoints para comparar forks")
        base_checkpoint = checkpoints[-2]["checkpoint_id"]  # penúltimo
        results = []
        for mod in modifications:
            mantis_log("INFO", "compare_fork", f"Mod={mod}")
            run_id = await self.rewind_and_modify(
                thread_id=thread_id,
                target_checkpoint_id=base_checkpoint,
                new_values=mod
            )
            results.append({"run_id": run_id, "modification": mod})
        return results

# ═══════════════════════════════════════════════════════════════════════════
# 3. INTERFACE DE LINHA DE COMANDO (CLI) – EXPOSIÇÃO COMO FERRAMENTA
# ═══════════════════════════════════════════════════════════════════════════
def cli():
    import argparse
    parser = argparse.ArgumentParser(description="Time Travel Debugger for LangGraph Agent Server")
    parser.add_argument("--url", required=True, help="Deployment URL")
    parser.add_argument("--api-key", required=True, help="LangSmith API key")
    parser.add_argument("--thread-id", required=True, help="Thread ID")
    parser.add_argument("--assistant-id", required=True, help="Assistant ID")
    subparsers = parser.add_subparsers(dest="command")

    # list
    subparsers.add_parser("list", help="Listar checkpoints do thread")

    # rewind
    rewind_parser = subparsers.add_parser("rewind", help="Re-executar a partir de checkpoint")
    rewind_parser.add_argument("--checkpoint-id", required=True)
    rewind_parser.add_argument("--state", help="JSON com novos valores de estado")

    # fork
    fork_parser = subparsers.add_parser("fork", help="Criar fork a partir de checkpoint")
    fork_parser.add_argument("--index", type=int, default=-2, help="Índice do checkpoint (negativo conta do final)")

    args = parser.parse_args()

    async def run():
        client = ResilientClient(args.url, args.api_key)
        traveler = TimeTraveler(client, args.assistant_id)
        if args.command == "list":
            cps = await traveler.list_checkpoints(args.thread_id)
            for cp in cps:
                print(f"Checkpoint: {cp['checkpoint_id']}, created: {cp['created_at']}")
        elif args.command == "rewind":
            new_values = json.loads(args.state) if args.state else None
            run_id = await traveler.rewind_and_modify(args.thread_id, args.checkpoint_id, new_values)
            print(f"Novo run: {run_id}")
        elif args.command == "fork":
            run_id = await traveler.fork_and_explore(args.thread_id, args.index)
            print(f"Fork run: {run_id}")

    asyncio.run(run())

if __name__ == "__main__":
    cli()
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
import asyncio
from unittest.mock import AsyncMock, patch
from time_travel_debugging import ResilientClient, TimeTraveler

# Mocks para evitar chamadas reais
@pytest.fixture
def mock_client():
    client = AsyncMock(spec=ResilientClient)
    client.wait_for_run = AsyncMock(return_value={"run_id": "test-run-123"})
    client.get_history = AsyncMock(return_value=[
        {"checkpoint_id": "cp-latest", "created_at": "2026-05-26T10:00:00Z", "values": {"topic": "cats"}, "parent_checkpoint_id": "cp-1"},
        {"checkpoint_id": "cp-1", "created_at": "2026-05-26T09:00:00Z", "values": {}, "parent_checkpoint_id": None}
    ])
    client.update_state = AsyncMock(return_value={"checkpoint_id": "cp-modified"})
    return client

@pytest.mark.asyncio
async def test_list_checkpoints(mock_client):
    traveler = TimeTraveler(mock_client, "assistant-1")
    cps = await traveler.list_checkpoints("thread-1")
    assert len(cps) == 2
    assert cps[0]["checkpoint_id"] == "cp-latest"
    assert cps[1]["checkpoint_id"] == "cp-1"

@pytest.mark.asyncio
async def test_rewind_without_modification(mock_client):
    traveler = TimeTraveler(mock_client, "assistant-1")
    run_id = await traveler.rewind_and_modify("thread-1", "cp-1")
    assert run_id == "test-run-123"
    mock_client.update_state.assert_not_called()

@pytest.mark.asyncio
async def test_rewind_with_modification(mock_client):
    traveler = TimeTraveler(mock_client, "assistant-1")
    new_state = {"topic": "dogs"}
    run_id = await traveler.rewind_and_modify("thread-1", "cp-1", new_state)
    assert run_id == "test-run-123"
    mock_client.update_state.assert_called_once_with(thread_id="thread-1", values=new_state, checkpoint_id="cp-1")

@pytest.mark.asyncio
async def test_fork_and_explore(mock_client):
    traveler = TimeTraveler(mock_client, "assistant-1")
    run_id = await traveler.fork_and_explore("thread-1", checkpoint_index=-2)
    assert run_id == "test-run-123"

@pytest.mark.asyncio
async def test_compare_forks(mock_client):
    traveler = TimeTraveler(mock_client, "assistant-1")
    mods = [{"topic": "birds"}, {"topic": "fish"}]
    results = await traveler.compare_forks("thread-1", mods)
    assert len(results) == 2
    assert all(r["run_id"] == "test-run-123" for r in results)
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/time-travel-debugging.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[langgraph-state-graph-fundamentals.md]]
- [[langgraph-create-agent.md]]
- [[05-CONFIGURATIONS/validation/orchestrator-engine/main.go]]
```

---

```yaml
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
```

---

*(Os artefatos 3 e 4 continuam no mesmo padrão, com alta densidade de código. Veja abaixo.)*

```yaml
---
artifact_id: "webhook-integration"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/webhook-integration.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/webhook-integration.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:webhook-integration-v1"
generated_at: "2026-05-26T10:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["langgraph-create-agent", "scaling-performance-tuning"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-07-25"
---

# 🧩 Webhook Integration no Agent Server

> **Contrato modular**: Artefato filho do Master Agent. Implementa o padrão de webhooks para notificações assíncronas de conclusão de runs, com segurança, payload e configuração via `langgraph.json`.

## 🎯 Propósito

Permitir que sistemas externos recebam notificações automáticas quando uma execução no Agent Server terminar, utilizando endpoints webhook configuráveis e seguros.

## 📋 Especificação (SDD)
- **Entradas**: `webhook` URL, headers estáticos, restrições de domínio, payload customizado
- **Saídas**: POST com payload do Run ao finalizar, com status e valores
- **Side Effects**: Chamada de endpoint externo, falha se não alcançável
- **Constraints Aplicáveis**: C1 (Resiliência), C3 (Segurança), C5 (Integridade), C8 (Observabilidade)
- **Dependências**: `langgraph-sdk`, `httpx`, `starlette` (para servidor de teste)

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

# ─── LÓGICA DO MÓDULO ────────────────────────────────────────────────────
import asyncio, re
from typing import Optional, Dict, Any
import httpx
from langgraph_sdk import get_client

# ═══════════════════════════════════════════════════════════════════════════
# 1. CLIENTE DE EXECUÇÃO COM SUPORTE A WEBHOOK
# ═══════════════════════════════════════════════════════════════════════════
class WebhookAwareClient:
    def __init__(self, deployment_url: str, api_key: str, webhook_url: str = None):
        self.client = get_client(url=deployment_url, api_key=api_key)
        self.webhook_url = webhook_url

    async def stream_with_webhook(
        self,
        thread_id: str,
        assistant_id: str,
        input: dict,
        webhook_url: Optional[str] = None,
        webhook_headers: Optional[Dict[str, str]] = None
    ):
        effective_url = webhook_url or self.webhook_url
        if not effective_url:
            raise ValueError("Webhook URL é obrigatória para notificações")

        mantis_log("INFO", "webhook_stream_start", f"Thread={thread_id}, URL={effective_url}")
        async for chunk in self.client.runs.stream(
            thread_id=thread_id,
            assistant_id=assistant_id,
            input=input,
            stream_mode="events",
            webhook=effective_url
        ):
            yield chunk
        mantis_log("INFO", "webhook_stream_end", f"Thread={thread_id}")

# ═══════════════════════════════════════════════════════════════════════════
# 2. PROCESSADOR DE PAYLOAD DE WEBHOOK (LADO RECEPTOR)
# ═══════════════════════════════════════════════════════════════════════════
class WebhookPayload:
    """Modelo do payload recebido."""
    def __init__(self, data: dict):
        self.run_id = data["run_id"]
        self.thread_id = data["thread_id"]
        self.status = data["status"]
        self.values = data.get("values")
        self.error = data.get("error")
        self.webhook_sent_at = data.get("webhook_sent_at")

    def is_success(self) -> bool:
        return self.status == "success"

    def get_error_message(self) -> Optional[str]:
        if self.error:
            return self.error.get("message")
        return None

# ═══════════════════════════════════════════════════════════════════════════
# 3. SERVIDOR DE TESTE DE WEBHOOK (PARA DESENVOLVIMENTO LOCAL)
# ═══════════════════════════════════════════════════════════════════════════
from starlette.applications import Starlette
from starlette.routing import Route
from starlette.responses import JSONResponse
import uvicorn

class WebhookTestServer:
    def __init__(self, port: int = 9999):
        self.port = port
        self.received_payloads = []
        self.app = Starlette(routes=[Route("/webhook", self.handle_webhook, methods=["POST"])])

    async def handle_webhook(self, request):
        payload = await request.json()
        mantis_log("INFO", "webhook_received", f"Run ID={payload.get('run_id')}")
        self.received_payloads.append(WebhookPayload(payload))
        return JSONResponse({"status": "received"})

    def start(self):
        uvicorn.run(self.app, port=self.port, log_level="info")

# ═══════════════════════════════════════════════════════════════════════════
# 4. VALIDADOR DE URL DE WEBHOOK (SEGURANÇA C3)
# ═══════════════════════════════════════════════════════════════════════════
class WebhookURLValidator:
    """
    Implementa as regras de restrição de webhooks do Agent Server:
    - allowed_domains com suporte a wildcards
    - require_https
    - disable_loopback
    - max_url_length
    """
    def __init__(
        self,
        allowed_domains: list = None,
        require_https: bool = True,
        disable_loopback: bool = True,
        max_url_length: int = 2048,
        allowed_ports: set = None
    ):
        self.allowed_domains = allowed_domains or []
        self.require_https = require_https
        self.disable_loopback = disable_loopback
        self.max_url_length = max_url_length
        self.allowed_ports = allowed_ports or {443, 80}

    def validate(self, url: str) -> bool:
        if len(url) > self.max_url_length:
            mantis_log("ERROR", "webhook_url_too_long", f"URL length {len(url)} > {self.max_url_length}")
            return False

        # Parse URL
        from urllib.parse import urlparse
        parsed = urlparse(url)
        if self.require_https and parsed.scheme != "https":
            mantis_log("ERROR", "webhook_https_required", f"Scheme {parsed.scheme} not allowed")
            return False

        if self.disable_loopback:
            hostname = parsed.hostname or ""
            if hostname in ("localhost", "127.0.0.1", "::1"):
                mantis_log("ERROR", "webhook_loopback_blocked", hostname)
                return False

        port = parsed.port or (443 if parsed.scheme == "https" else 80)
        if port not in self.allowed_ports:
            mantis_log("ERROR", "webhook_port_blocked", str(port))
            return False

        # Verificar domínios permitidos (com wildcard)
        if self.allowed_domains:
            hostname = parsed.hostname
            allowed = False
            for pattern in self.allowed_domains:
                regex = re.escape(pattern).replace(r"\*", ".*")
                if re.match(regex, hostname):
                    allowed = True
                    break
            if not allowed:
                mantis_log("ERROR", "webhook_domain_not_allowed", hostname)
                return False

        return True

# ═══════════════════════════════════════════════════════════════════════════
# 5. INTEGRAÇÃO COM LANGGRAPH.JSON (EXEMPLO DE HEADERS ESTÁTICOS)
# ═══════════════════════════════════════════════════════════════════════════
WEBHOOK_CONFIG_EXAMPLE = """
{
  "webhooks": {
    "headers": {
      "X-Custom-Header": "my-value",
      "Authorization": "Bearer ${{ env.LG_WEBHOOK_TOKEN }}"
    },
    "url": {
      "allowed_domains": ["*.mycompany.com"],
      "require_https": true
    }
  }
}
"""
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from webhook_integration import WebhookPayload, WebhookURLValidator

def test_webhook_payload_success():
    payload = WebhookPayload({"run_id": "r1", "thread_id": "t1", "status": "success", "webhook_sent_at": "2026-05-26T10:00:00Z"})
    assert payload.is_success()
    assert payload.get_error_message() is None

def test_webhook_payload_error():
    payload = WebhookPayload({"run_id": "r2", "thread_id": "t2", "status": "error", "error": {"error": "TimeoutError", "message": "Run timed out"}})
    assert not payload.is_success()
    assert payload.get_error_message() == "Run timed out"

def test_url_validator_https():
    v = WebhookURLValidator(allowed_domains=["*.example.com"], require_https=True)
    assert v.validate("https://api.example.com/webhook")
    assert not v.validate("http://api.example.com/webhook")

def test_url_validator_loopback():
    v = WebhookURLValidator(disable_loopback=True)
    assert not v.validate("http://localhost:8000/webhook")
    assert not v.validate("https://127.0.0.1/webhook")

def test_url_validator_domain_wildcard():
    v = WebhookURLValidator(allowed_domains=["*.mycompany.com"])
    assert v.validate("https://sub.mycompany.com/path")
    assert not v.validate("https://other.com/path")
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/webhook-integration.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[langgraph-create-agent.md]]
```

---

```yaml
---
artifact_id: "data-plane-infra"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/data-plane-infra.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/data-plane-infra.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:data-plane-infra-v1"
generated_at: "2026-05-26T10:45:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["scaling-performance-tuning", "checkpointer-backend-config"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-07-25"
---

# 🧩 Data Plane Infrastructure Automation

> **Contrato modular**: Artefato filho do Master Agent. Contém a lógica para interagir com a infraestrutura do Data Plane: PostgreSQL, Redis, MongoDB, autoescalonamento e telemetria.

## 🎯 Propósito

Fornecer uma biblioteca de funções para gerenciar, monitorar e configurar a infraestrutura de execução dos Agent Servers, incluindo health checks, pool de conexões, métricas de autoescalonamento e configuração de backends de checkpoint.

## 📋 Especificação (SDD)
- **Entradas**: Configurações de conexão (URI), limites de recursos, métricas
- **Saídas**: Status de saúde, métricas de performance, ações de scaling
- **Side Effects**: Criação de índices, ajuste de parâmetros de pool, queries de monitoramento
- **Constraints Aplicáveis**: C1, C2, C3, C5, C7, C8
- **Dependências**: `asyncpg`, `redis`, `psutil`, `pymongo`, `langgraph-checkpoint`

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

# ─── IMPORTAÇÕES ─────────────────────────────────────────────────────────
import asyncio, os, logging, time
from typing import Optional, Dict, Any, List, Tuple
import asyncpg
import redis.asyncio as redis
import psutil
from pymongo import MongoClient

# ═══════════════════════════════════════════════════════════════════════════
# 1. HEALTH CHECKER MULTI-BACKEND
# ═══════════════════════════════════════════════════════════════════════════
class DataPlaneHealth:
    def __init__(self, db_uri: str, redis_uri: str, mongo_uri: Optional[str] = None):
        self.db_uri = db_uri
        self.redis_uri = redis_uri
        self.mongo_uri = mongo_uri

    async def check_postgres(self) -> Dict[str, Any]:
        try:
            conn = await asyncpg.connect(self.db_uri)
            row = await conn.fetchrow("SELECT 1 AS ok, pg_database_size(current_database()) AS size, version() AS version")
            await conn.close()
            mantis_log("INFO", "pg_health_ok", str(dict(row)))
            return {"status": "healthy", "size": row["size"], "version": row["version"]}
        except Exception as e:
            mantis_log("ERROR", "pg_health_fail", str(e))
            return {"status": "unhealthy", "error": str(e)}

    async def check_redis(self) -> Dict[str, Any]:
        try:
            r = redis.Redis.from_url(self.redis_uri)
            await r.ping()
            info = await r.info()
            await r.close()
            mantis_log("INFO", "redis_health_ok", f"Memory used: {info.get('used_memory_human')}")
            return {"status": "healthy", "used_memory": info.get("used_memory_human")}
        except Exception as e:
            mantis_log("ERROR", "redis_health_fail", str(e))
            return {"status": "unhealthy", "error": str(e)}

    def check_mongodb(self) -> Dict[str, Any]:
        if not self.mongo_uri:
            return {"status": "not_configured"}
        try:
            client = MongoClient(self.mongo_uri, serverSelectionTimeoutMS=5000)
            client.server_info()
            db = client.get_default_database()
            stats = db.command("dbStats")
            mantis_log("INFO", "mongo_health_ok", f"Data size: {stats.get('dataSize')}")
            return {"status": "healthy", "data_size": stats.get("dataSize")}
        except Exception as e:
            mantis_log("ERROR", "mongo_health_fail", str(e))
            return {"status": "unhealthy", "error": str(e)}

# ═══════════════════════════════════════════════════════════════════════════
# 2. AUTOESCALONAMENTO SIMULADO (MÉTRICAS E DECISÃO)
# ═══════════════════════════════════════════════════════════════════════════
class AutoscalingSimulator:
    """
    Simula o autoescalonamento baseado em CPU, memória e fila de runs pendentes.
    Pode ser usado para testar políticas de scaling ou gerar alertas.
    """
    def __init__(self, target_cpu: float = 75, target_memory: float = 75, target_pending: int = 10):
        self.target_cpu = target_cpu
        self.target_memory = target_memory
        self.target_pending = target_pending

    def get_current_metrics(self) -> Dict[str, float]:
        cpu = psutil.cpu_percent()
        mem = psutil.virtual_memory().percent
        # pending runs seria lido de uma fonte externa, simulamos aqui
        pending = self._read_pending_runs()
        mantis_log("INFO", "current_metrics", f"CPU={cpu}%, Memory={mem}%, Pending={pending}")
        return {"cpu": cpu, "memory": mem, "pending_runs": pending}

    def _read_pending_runs(self) -> int:
        # Em produção, isso viria do Agent Server queue stats
        return int(os.getenv("PENDING_RUNS", "5"))

    def calculate_desired_replicas(self, current_replicas: int) -> int:
        metrics = self.get_current_metrics()
        reasons = []
        desired = current_replicas
        if metrics["cpu"] > self.target_cpu:
            desired = max(desired, min(current_replicas * 2, 10))
            reasons.append(f"CPU {metrics['cpu']}% > {self.target_cpu}%")
        if metrics["memory"] > self.target_memory:
            desired = max(desired, min(current_replicas * 2, 10))
            reasons.append(f"Memory {metrics['memory']}% > {self.target_memory}%")
        if metrics["pending_runs"] > self.target_pending * current_replicas:
            new = int(metrics["pending_runs"] / self.target_pending)
            desired = max(desired, new)
            reasons.append(f"Pending {metrics['pending_runs']} > {self.target_pending * current_replicas}")
        if desired > current_replicas:
            mantis_log("WARN", "autoscale_up", f"From {current_replicas} to {desired}, reasons: {', '.join(reasons)}")
        elif desired < current_replicas:
            mantis_log("INFO", "autoscale_down", f"From {current_replicas} to {desired}")
        return desired

# ═══════════════════════════════════════════════════════════════════════════
# 3. CONFIGURAÇÃO DE CHECKPOINTER (POSTGRES / MONGODB / CUSTOM)
# ═══════════════════════════════════════════════════════════════════════════
class CheckpointerConfigurator:
    """Configura o backend de checkpoint conforme langgraph.json ou variáveis de ambiente."""
    BACKEND_POSTGRES = "postgres"
    BACKEND_MONGO = "mongo"
    BACKEND_CUSTOM = "custom"

    def __init__(self, config: dict):
        self.backend = config.get("backend", "default")
        self.ttl = config.get("ttl", {})

    def get_connection_args(self) -> dict:
        if self.backend == CheckpointerConfigurator.BACKEND_MONGO:
            uri = os.getenv("LS_MONGODB_URI", "mongodb://localhost:27017/langgraph")
            return {"uri": uri, "replica_set": "rs0"}
        elif self.backend == CheckpointerConfigurator.BACKEND_POSTGRES:
            uri = os.getenv("DATABASE_URI") or os.getenv("POSTGRES_URI_CUSTOM")
            if not uri:
                raise ValueError("DATABASE_URI não configurada")
            return {"uri": uri}
        else:
            # Custom – carregar dinamicamente
            return {"backend": "custom", "path": config.get("path")}

    def get_ttl_settings(self) -> dict:
        return {
            "strategy": self.ttl.get("strategy", "delete"),
            "default_ttl": self.ttl.get("default_ttl", 43200),
            "sweep_interval_minutes": self.ttl.get("sweep_interval_minutes", 10)
        }

# ═══════════════════════════════════════════════════════════════════════════
# 4. GERENCIADOR DE POOL DE CONEXÕES (POSTGRES)
# ═══════════════════════════════════════════════════════════════════════════
class PoolManager:
    def __init__(self, uri: str, min_size: int = 5, max_size: int = 20):
        self.uri = uri
        self.min_size = min_size
        self.max_size = max_size
        self._pool = None

    async def initialize(self):
        self._pool = await asyncpg.create_pool(
            self.uri,
            min_size=self.min_size,
            max_size=self.max_size,
            max_inactive_connection_lifetime=300
        )
        mantis_log("INFO", "pool_initialized", f"min={self.min_size}, max={self.max_size}")

    async def acquire(self):
        if not self._pool:
            await self.initialize()
        return await self._pool.acquire()

    async def close(self):
        if self._pool:
            await self._pool.close()
            mantis_log("INFO", "pool_closed")

# ═══════════════════════════════════════════════════════════════════════════
# 5. SIMULADOR DE CARGA PARA TESTE DE ESTRESSE
# ═══════════════════════════════════════════════════════════════════════════
class LoadSimulator:
    """Simula um número de runs concorrentes para testar o scaling."""
    def __init__(self, autoscaler: AutoscalingSimulator, pool_manager: PoolManager):
        self.autoscaler = autoscaler
        self.pool = pool_manager

    async def simulate_runs(self, count: int):
        tasks = [self._simulate_run(i) for i in range(count)]
        await asyncio.gather(*tasks)

    async def _simulate_run(self, run_id: int):
        conn = await self.pool.acquire()
        try:
            await conn.execute("SELECT pg_sleep(0.1)")  # trabalho simulado
            mantis_log("DEBUG", "run_completed", f"Run {run_id}")
        finally:
            await self.pool.release(conn)
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from data_plane_infra import AutoscalingSimulator, DataPlaneHealth, CheckpointerConfigurator

def test_autoscaler_scale_up():
    asm = AutoscalingSimulator(target_cpu=50, target_memory=50, target_pending=5)
    # Simula alta CPU
    with patch('psutil.cpu_percent', return_value=90):
        with patch.object(asm, '_read_pending_runs', return_value=20):
            desired = asm.calculate_desired_replicas(1)
            assert desired > 1

def test_checkpointer_config_postgres():
    config = {"backend": "postgres"}
    cc = CheckpointerConfigurator(config)
    assert cc.backend == "postgres"
    args = cc.get_connection_args()
    assert "uri" in args

def test_health_check_pg_mock():
    import asyncio
    async def run():
        hp = DataPlaneHealth("postgres://test", "redis://test")
        with patch('asyncpg.connect') as mock_conn:
            mock_conn.return_value.fetchrow = AsyncMock(return_value={"ok": 1, "size": 123, "version": "PostgreSQL 16"})
            result = await hp.check_postgres()
            assert result["status"] == "healthy"
    asyncio.run(run())
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/data-plane-infra.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[scaling-performance-tuning.md]]
- [[checkpointer-backend-config.md]]
