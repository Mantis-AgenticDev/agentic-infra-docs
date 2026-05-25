---
artifact_id: "a2a-multi-agent-conversation"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/a2a-multi-agent-conversation.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/a2a-multi-agent-conversation.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:a2a-multi-agent-conversation-v1.0.0"
generated_at: "2026-05-26T04:45:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["a2a-protocol-core", "a2a-distributed-tracing"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# 💬 A2A Multi‑Agent Conversation – Conversas entre Agentes

> **Contrato modular**: Artefato filho do Master Agent. Demonstra conversas completas entre múltiplos agentes usando o protocolo A2A, com continuidade via contextId/taskId, histórico compartilhado e integração com LangSmith.

---

## 🎯 Propósito
Permitir que o orquestrador MANTIS coordene diálogos multi‑agente, onde cada agente processa a resposta do outro, mantendo continuidade e rastreabilidade.

## 📋 Especificação (SDD)
- **Entradas**: URLs A2A de múltiplos agentes, mensagem inicial.
- **Saídas**: Conversa multi‑turno completa.
- **Side Effects**: Múltiplas chamadas A2A.
- **Constraints Aplicáveis**: C1 (formato), C5 (estado), C7 (retry), C8 (logs), C9 (tracing).
- **Dependências**: `aiohttp`, `langsmith`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Simulação de Conversa entre Dois Agentes

```python
async def simulate_conversation(agent_a_url, agent_b_url, initial_message, rounds=3):
    async with aiohttp.ClientSession() as session:
        context_id = None
        task_id = None
        message = initial_message

        for i in range(rounds):
            mantis_log("INFO", "round_start", f"Round {i+1}")

            # Agente A
            response_text, context_id, task_id = await send_a2a_message(
                session, agent_a_url, message, context_id, task_id
            )
            mantis_log("INFO", "agent_a_response", response_text[:100])
            print(f"🔵 Agente A: {response_text}")

            # Agente B
            response_text, context_id, task_id = await send_a2a_message(
                session, agent_b_url, response_text, context_id, task_id
            )
            mantis_log("INFO", "agent_b_response", response_text[:100])
            print(f"🔴 Agente B: {response_text}\n")

            message = response_text
```

### 2. Conversa com Memória Compartilhada

```python
class ConversationMemory:
    def __init__(self):
        self.history = []

    def add_turn(self, agent_name, message):
        self.history.append({"agent": agent_name, "message": message, "ts": datetime.datetime.utcnow().isoformat()})

    def get_context(self, last_n=5):
        return self.history[-last_n:]

memory = ConversationMemory()
```

### 3. Orquestrador de Múltiplos Agentes

```python
class MultiAgentOrchestrator:
    def __init__(self, agents: dict):
        self.agents = agents  # {name: url}
        self.memory = ConversationMemory()

    async def broadcast(self, from_agent, message):
        results = {}
        for name, url in self.agents.items():
            if name != from_agent:
                response = await self._send(url, message)
                results[name] = response
                self.memory.add_turn(name, response)
        return results

    async def route_to_best(self, message, skill_required):
        # Encontrar agente com a skill necessária via Agent Card
        for name, url in self.agents.items():
            card = discover_agent_card(url, name)
            if any(s["name"] == skill_required for s in card.get("skills", [])):
                return await self._send(url, message)
        return None
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_conversation_memory():
    mem = ConversationMemory()
    mem.add_turn("agent-a", "Hello")
    assert len(mem.history) == 1
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/a2a-multi-agent-conversation.md --json
```

---

## 🔗 Referências Cruzadas
- [[a2a-protocol-core.md]]
- [[a2a-distributed-tracing.md]]
