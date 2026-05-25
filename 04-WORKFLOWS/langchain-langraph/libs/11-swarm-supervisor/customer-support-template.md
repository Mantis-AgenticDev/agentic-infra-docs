---
artifact_id: "customer-support-template"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/customer-support-template.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/customer-support-template.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:cust-support-template-v1"
generated_at: "2026-05-27T09:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["swarm-fundamentals", "multi-agent-memory"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-08-27"
---

# 🧩 Customer Support Swarm Template — Atendimento Multi-Serviço com Handoff

> **Contrato modular**: Artefato filho do Master Agent. Template reutilizável para sistemas de atendimento onde agentes especializados (voos, hotéis, etc.) transferem controle entre si, mantendo contexto do usuário.

## 🎯 Propósito

Oferecer um esqueleto de enxame de suporte ao cliente que pode ser adaptado para qualquer domínio multi-serviço, com reservas, busca e handoff automático entre especialistas.

## 📋 Especificação (SDD)
- **Entradas**: Mensagens do usuário, `user_id`, contexto de reservas
- **Saídas**: Respostas dos agentes, confirmações de reserva
- **Side Effects**: Atualização de estado de reservas, logging de handoffs
- **Constraints Aplicáveis**: C1, C2, C3, C5, C6, C7, C8
- **Dependências**: `langgraph-swarm`, `langchain`, `pydantic`

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
# 1. ESTADO DE RESERVAS E FERRAMENTAS DE DOMÍNIO
# ═══════════════════════════════════════════════════════════════════════════
from collections import defaultdict
from typing import Callable, Optional, Dict, Any
from langchain_core.runnables import RunnableConfig

# Armazenamento mock (em produção, usar banco de dados)
RESERVATIONS = defaultdict(lambda: {"flight_info": {}, "hotel_info": {}})

# Dados mock
TOMORROW = (datetime.date.today() + datetime.timedelta(days=1)).isoformat()
FLIGHTS = [
    {"departure_airport": "BOS", "arrival_airport": "JFK", "airline": "Jet Blue", "date": TOMORROW, "id": "1"}
]
HOTELS = [
    {"location": "New York", "name": "McKittrick Hotel", "neighborhood": "Chelsea", "id": "1"}
]

def search_flights(departure_airport: str, arrival_airport: str, date: str) -> list[dict]:
    """Busca voos disponíveis."""
    mantis_log("INFO", "search_flights", f"{departure_airport}->{arrival_airport} {date}")
    return FLIGHTS

def book_flight(flight_id: str, config: RunnableConfig) -> str:
    """Reserva um voo."""
    user_id = config["configurable"].get("user_id", "anon")
    flight = next((f for f in FLIGHTS if f["id"] == flight_id), None)
    if flight:
        RESERVATIONS[user_id]["flight_info"] = flight
        mantis_log("INFO", "flight_booked", f"User={user_id}, Flight={flight_id}")
        return "Voo reservado com sucesso."
    return "Voo não encontrado."

def search_hotels(location: str) -> list[dict]:
    """Busca hotéis."""
    mantis_log("INFO", "search_hotels", location)
    return HOTELS

def book_hotel(hotel_id: str, config: RunnableConfig) -> str:
    """Reserva um hotel."""
    user_id = config["configurable"].get("user_id", "anon")
    hotel = next((h for h in HOTELS if h["id"] == hotel_id), None)
    if hotel:
        RESERVATIONS[user_id]["hotel_info"] = hotel
        mantis_log("INFO", "hotel_booked", f"User={user_id}, Hotel={hotel_id}")
        return "Hotel reservado com sucesso."
    return "Hotel não encontrado."

# ═══════════════════════════════════════════════════════════════════════════
# 2. CONSTRUÇÃO DOS AGENTES COM PROMPTS DINÂMICOS
# ═══════════════════════════════════════════════════════════════════════════
from langchain.chat_models import init_chat_model
from langchain.agents import create_agent
from langgraph_swarm import create_handoff_tool, create_swarm
from langgraph.checkpoint.memory import InMemorySaver

class CustomerSupportSwarm:
    def __init__(self, model_provider: str = "deepseek"):
        self.model = init_chat_model(
            model="deepseek-chat" if model_provider == "deepseek" else "gpt-4o",
            model_provider=model_provider,
            temperature=0.05,
        )
        self.agents = []

    def _make_prompt(self, base_prompt: str) -> Callable:
        def prompt_fn(state: dict, config: RunnableConfig) -> list:
            user_id = config["configurable"].get("user_id", "anon")
            reservation = dict(RESERVATIONS[user_id])
            system_prompt = (
                f"{base_prompt}\n\nReserva ativa do usuário: {reservation}\nHoje: {datetime.datetime.now()}"
            )
            return [{"role": "system", "content": system_prompt}] + state["messages"]
        return prompt_fn

    def build(self):
        transfer_to_hotel = create_handoff_tool(
            agent_name="hotel_assistant",
            description="Transferir para o assistente de hotéis.",
        )
        transfer_to_flight = create_handoff_tool(
            agent_name="flight_assistant",
            description="Transferir para o assistente de voos.",
        )

        flight_agent = create_agent(
            self.model,
            tools=[search_flights, book_flight, transfer_to_hotel],
            system_prompt=self._make_prompt("Você é um assistente de reserva de voos."),
            name="flight_assistant",
        )

        hotel_agent = create_agent(
            self.model,
            tools=[search_hotels, book_hotel, transfer_to_flight],
            system_prompt=self._make_prompt("Você é um assistente de reserva de hotéis."),
            name="hotel_assistant",
        )

        checkpointer = InMemorySaver()
        workflow = create_swarm(
            [flight_agent, hotel_agent],
            default_active_agent="flight_assistant",
        )
        app = workflow.compile(checkpointer=checkpointer)
        mantis_log("INFO", "customer_support_swarm_built")
        return app

# ═══════════════════════════════════════════════════════════════════════════
# 3. RUNNER COM GERENCIAMENTO DE USUÁRIO
# ═══════════════════════════════════════════════════════════════════════════
class CustomerSupportRunner:
    def __init__(self, app):
        self.app = app

    def handle_message(self, user_id: str, message: str, thread_id: Optional[str] = None):
        config = {
            "configurable": {
                "thread_id": thread_id or str(uuid.uuid4()),
                "user_id": user_id,
            }
        }
        result = self.app.invoke(
            {"messages": [{"role": "user", "content": message}]},
            config,
        )
        return result

    def stream_response(self, user_id: str, message: str, thread_id: Optional[str] = None):
        config = {
            "configurable": {
                "thread_id": thread_id or str(uuid.uuid4()),
                "user_id": user_id,
            }
        }
        for chunk in self.app.stream(
            {"messages": [{"role": "user", "content": message}]},
            config,
            stream_mode="values",
            subgraphs=True,
        ):
            yield chunk
```

## 🧪 Testes Unitários (TDD)
```python
import pytest
from customer_support_template import CustomerSupportSwarm, CustomerSupportRunner, search_flights

def test_search_flights():
    flights = search_flights("BOS", "JFK", "2026-01-01")
    assert len(flights) > 0
    assert flights[0]["airline"] == "Jet Blue"

def test_customer_support_swarm_build():
    swarm = CustomerSupportSwarm()
    app = swarm.build()
    assert app is not None

def test_runner_stream():
    swarm = CustomerSupportSwarm()
    app = swarm.build()
    runner = CustomerSupportRunner(app)
    chunks = list(runner.stream_response("user1", "Preciso de um voo"))
    assert len(chunks) > 0
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/11-swarm-supervisor/customer-support-template.md --json
```

## 🔗 Referências Cruzadas (Wikilinks)
- [[langchain-langraph-master-agent.md]]
- [[swarm-fundamentals.md]]
- [[multi-agent-memory.md]]
