---
artifact_id: "pregel-runtime-channels"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/pregel-runtime-channels.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/pregel-runtime-channels.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:pregel-runtime-channels-v1"
generated_at: "2026-05-27T18:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["graph-api-fundamentals", "functional-api-fundamentals", "advanced-persistence-patterns"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-08-27"
---

# 🧩 Pregel Runtime & Channels — Motor de Execução e Tipos de Canais

> **Contrato modular**: Artefato filho do Master Agent. Implementa o conhecimento do runtime Pregel, os tipos de canais (`LastValue`, `Topic`, `BinaryOperatorAggregate`, `DeltaChannel`) e a construção direta de grafos usando a API de baixo nível.

## 🎯 Propósito

Fornecer uma biblioteca que expõe o motor de execução Pregel e os canais de comunicação entre atores, permitindo construir aplicações LangGraph com controle fino sobre o fluxo de dados, acumulação de estado e otimização de armazenamento com `DeltaChannel`.

## 📋 Especificação (SDD)
- **Entradas**: Definição de canais, nós (`PregelNode`), configuração de `DeltaChannel`
- **Saídas**: Aplicação Pregel compilada, valores de canais após execução
- **Side Effects**: Criação de checkpoints (se configurado), logging de passos de execução
- **Constraints Aplicáveis**: C1, C2, C5, C7, C8
- **Dependências**: `langgraph`, `langgraph-checkpoint`

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
```

```python
# ═══════════════════════════════════════════════════════════════════════════
# 1. CANAIS DE COMUNICAÇÃO DO PREGEL
# ═══════════════════════════════════════════════════════════════════════════
from langgraph.channels import LastValue, Topic, BinaryOperatorAggregate, EphemeralValue
from langgraph.pregel import Pregel, NodeBuilder, ChannelWriteEntry

class ChannelDemo:
    """Demonstra os quatro tipos de canais do Pregel."""
    @staticmethod
    def last_value_example():
        channel = LastValue(int)
        channel.update([1, 2, 3])
        return channel.get()  # 3

    @staticmethod
    def topic_example():
        channel = Topic(str, accumulate=True)
        channel.update(["a", "b"])
        channel.update(["c"])
        return channel.get()  # ['a', 'b', 'c']

    @staticmethod
    def binop_example():
        import operator
        channel = BinaryOperatorAggregate(int, operator.add)
        channel.update([1, 2])
        channel.update([3])
        return channel.get()  # 6

    @staticmethod
    def ephemeral_example():
        channel = EphemeralValue(str)
        channel.update(["hello"])
        val = channel.get()  # 'hello'
        channel.update(["world"])
        return channel.get()  # 'world' (não acumula)

# ═══════════════════════════════════════════════════════════════════════════
# 2. CONSTRUÇÃO DIRETA COM PREGEL (API DE BAIXO NÍVEL)
# ═══════════════════════════════════════════════════════════════════════════
class PregelBuilder:
    """Constrói aplicações Pregel diretamente, sem StateGraph."""
    def __init__(self):
        self.nodes = {}
        self.channels = {}
        self.input_channels = []
        self.output_channels = []

    def add_node(self, name: str, subscribe: list[str], func: callable, write_to: list[str]):
        node = NodeBuilder()
        for ch in subscribe:
            node.subscribe_to(ch) if subscribe.index(ch) > 0 else node.subscribe_only(ch)
        node.do(func)
        for ch in write_to:
            node.write_to(ch)
        self.nodes[name] = node
        return self

    def add_channel(self, name: str, channel_type: type, *args, **kwargs):
        self.channels[name] = channel_type(*args, **kwargs)
        return self

    def set_input(self, *channels):
        self.input_channels = list(channels)
        return self

    def set_output(self, *channels):
        self.output_channels = list(channels)
        return self

    def compile(self) -> Pregel:
        return Pregel(
            nodes=self.nodes,
            channels=self.channels,
            input_channels=self.input_channels,
            output_channels=self.output_channels,
        )

    @staticmethod
    def example_pipeline():
        builder = PregelBuilder()
        builder.add_channel("input", EphemeralValue, str)
        builder.add_channel("middle", LastValue, str)
        builder.add_channel("output", Topic, str, accumulate=True)

        builder.add_node("step1", ["input"], lambda x: x + x, ["middle", "output"])
        builder.add_node("step2", ["middle"], lambda x: x + x, ["output"])
        builder.set_input("input").set_output("output")
        app = builder.compile()
        result = app.invoke({"input": "foo"})
        mantis_log("INFO", "pregel_pipeline_result", str(result))
        return result

# ═══════════════════════════════════════════════════════════════════════════
# 3. DELTACHANNEL (BETA) — OTIMIZAÇÃO DE ARMAZENAMENTO
# ═══════════════════════════════════════════════════════════════════════════
from typing import Annotated, Sequence, Any
from langgraph.channels import DeltaChannel

class DeltaChannelManager:
    """Gerencia canais com armazenamento delta para reduzir tamanho de checkpoints."""
    @staticmethod
    def create_list_delta(reducer: callable = None, snapshot_frequency: int = None):
        """Cria um DeltaChannel para listas."""
        if reducer is None:
            def default_list_reducer(state: list[Any], writes: Sequence[list[Any]]) -> list[Any]:
                result = list(state)
                for write in writes:
                    result.extend(write)
                return result
            reducer = default_list_reducer

        return DeltaChannel(reducer, snapshot_frequency=snapshot_frequency)

    @staticmethod
    def create_dict_delta(snapshot_frequency: int = None):
        """Cria um DeltaChannel para dicionários (merge)."""
        def dict_reducer(state: dict[str, Any], writes: Sequence[dict[str, Any]]) -> dict[str, Any]:
            result = dict(state)
            for write in writes:
                result.update(write)
            return result

        return DeltaChannel(dict_reducer, snapshot_frequency=snapshot_frequency)

    @staticmethod
    def validate_reducer_associativity(reducer: callable, test_cases: list) -> bool:
        """Verifica se um reducer é associativo (requisito para DeltaChannel)."""
        for (initial, writes_a, writes_b) in test_cases:
            left = reducer(reducer(initial, writes_a), writes_b)
            right = reducer(initial, writes_a + writes_b)
            if left != right:
                mantis_log("ERROR", "reducer_not_associative", f"Left={left}, Right={right}")
                return False
        mantis_log("INFO", "reducer_associative")
        return True

# ═══════════════════════════════════════════════════════════════════════════
# 4. EXEMPLO DE CICLO COM PREGEL (LOOP)
# ═══════════════════════════════════════════════════════════════════════════
class CycleExample:
    """Demonstra um grafo com ciclo usando Pregel."""
    @staticmethod
    def build():
        node = (
            NodeBuilder()
            .subscribe_only("value")
            .do(lambda x: x + x if len(x) < 10 else None)
            .write_to(ChannelWriteEntry("value", skip_none=True))
        )
        app = Pregel(
            nodes={"cycle_node": node},
            channels={"value": EphemeralValue(str)},
            input_channels=["value"],
            output_channels=["value"],
        )
        return app

    @staticmethod
    def run():
        app = CycleExample.build()
        result = app.invoke({"value": "a"})
        mantis_log("INFO", "cycle_result", str(result))
        return result  # {'value': 'aaaaaaaaaaaaaaaa'}
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from pregel_runtime_channels import (
    ChannelDemo, PregelBuilder, DeltaChannelManager, CycleExample
)

def test_last_value():
    assert ChannelDemo.last_value_example() == 3

def test_topic_accumulate():
    assert ChannelDemo.topic_example() == ['a', 'b', 'c']

def test_binop_aggregate():
    assert ChannelDemo.binop_example() == 6

def test_pregel_pipeline():
    result = PregelBuilder.example_pipeline()
    assert 'output' in result

def test_cycle():
    result = CycleExample.run()
    assert result['value'] == 'aaaaaaaaaaaaaaaa'

def test_delta_reducer_associativity():
    def good_reducer(state, writes):
        return state + sum(writes)
    test_cases = [
        (10, [1, 2], [3]),
        (0, [5], [5, 5]),
    ]
    assert DeltaChannelManager.validate_reducer_associativity(good_reducer, test_cases)
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/12-langgraph-api/pregel-runtime-channels.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[graph-api-fundamentals.md]]
- [[advanced-persistence-patterns.md]]
