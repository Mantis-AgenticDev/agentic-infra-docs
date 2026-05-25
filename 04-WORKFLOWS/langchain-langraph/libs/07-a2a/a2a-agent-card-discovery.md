---
artifact_id: "a2a-agent-card-discovery"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/a2a-agent-card-discovery.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/a2a-agent-card-discovery.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:a2a-agent-card-discovery-v1.0.0"
generated_at: "2026-05-26T04:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["a2a-protocol-core"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# 🎴 A2A Agent Card Discovery – Descoberta Dinâmica de Agentes

> **Contrato modular**: Artefato filho do Master Agent. Documenta o mecanismo de Agent Card do protocolo A2A, permitindo que agentes MANTIS descubram automaticamente as capacidades, skills e endpoints de outros agentes.

---

## 🎯 Propósito
Permitir que o orquestrador MANTIS descubra dinamicamente quais agentes estão disponíveis, suas capacidades e como se comunicar com eles, usando o endpoint `/.well-known/agent-card.json`.

## 📋 Especificação (SDD)
- **Entradas**: Base URL do Agent Server, assistant_id.
- **Saídas**: Agent Card com nome, descrição, skills, modos de entrada/saída e URL A2A.
- **Side Effects**: Nenhum.
- **Constraints Aplicáveis**: C1 (schema do Agent Card), C5 (estrutura padronizada), C7 (fallback se card não encontrado), C8 (logs).
- **Dependências**: `httpx`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Endpoint de Descoberta

```python
import httpx

AGENT_CARD_PATH = "/.well-known/agent-card.json"

def discover_agent_card(base_url, assistant_id):
    url = f"{base_url}{AGENT_CARD_PATH}?assistant_id={assistant_id}"
    response = httpx.get(url)
    response.raise_for_status()
    card = response.json()
    mantis_log("INFO", "agent_card_discovered", f"Agent: {card.get('name')}, ID: {assistant_id}")
    return card
```

### 2. Estrutura do Agent Card

```python
AGENT_CARD_SCHEMA = {
    "name": "Nome do assistente",
    "description": "Descrição do que o agente faz",
    "url": "URL base do agente",
    "skills": [
        {"id": "skill-1", "name": "Nome da skill", "description": "Descrição"},
    ],
    "defaultInputModes": ["text", "text/plain"],
    "defaultOutputModes": ["text", "text/plain"],
    "capabilities": {
        "streaming": True,
        "pushNotifications": False,
    },
}
```

### 3. Registro de Agentes Descobertos

```python
class AgentRegistry:
    def __init__(self):
        self.agents = {}

    def register(self, base_url, assistant_id):
        card = discover_agent_card(base_url, assistant_id)
        self.agents[assistant_id] = {
            "card": card,
            "a2a_url": f"{base_url}/a2a/{assistant_id}",
            "discovered_at": datetime.datetime.utcnow().isoformat(),
        }
        return self.agents[assistant_id]

    def find_by_skill(self, skill_name):
        found = []
        for agent_id, info in self.agents.items():
            skills = info["card"].get("skills", [])
            if any(s["name"] == skill_name for s in skills):
                found.append(agent_id)
        return found

    def list_all(self):
        return {aid: info["card"]["name"] for aid, info in self.agents.items()}
```

### 4. Cache de Agent Cards

```python
from functools import lru_cache
import time

class CachedAgentRegistry(AgentRegistry):
    @lru_cache(maxsize=128)
    def get_card_cached(self, base_url, assistant_id):
        return discover_agent_card(base_url, assistant_id)

    def refresh(self, base_url, assistant_id):
        self.get_card_cached.cache_clear()
        return self.get_card_cached(base_url, assistant_id)
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_agent_card_schema():
    card = {"name": "Test", "skills": [], "defaultInputModes": ["text"]}
    assert "name" in card
    assert "skills" in card

def test_registry_find():
    registry = AgentRegistry()
    registry.agents = {
        "agent-1": {"card": {"skills": [{"name": "web-search"}]}},
        "agent-2": {"card": {"skills": [{"name": "code-review"}]}},
    }
    assert registry.find_by_skill("web-search") == ["agent-1"]
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/a2a-agent-card-discovery.md --json
```

---

## 🔗 Referências Cruzadas
- [[a2a-protocol-core.md]]
