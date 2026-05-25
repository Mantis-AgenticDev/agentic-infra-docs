---
artifact_id: "langchain-streaming-patterns"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/langchain-streaming-patterns.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/langchain-streaming-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:langchain-streaming-patterns-v1.0.0"
generated_at: "2026-05-26T16:45:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["langchain-sdk-patterns"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# 📡 LangChain Streaming Patterns – Tokens, Eventos e Agentes

> **Contrato modular**: Artefato filho do Master Agent. Explora todas as formas de streaming em LangChain: tokens, eventos de agente, SSE e streaming de RAG, com callbacks customizados.

---

## 🎯 Propósito
Garantir que agentes MANTIS forneçam feedback em tempo real aos usuários, melhorando a experiência de uso e permitindo monitoramento fino.

## 📋 Especificação (SDD)
- **Entradas**: Chains ou agentes com `streaming=True`.
- **Saídas**: Tokens e eventos transmitidos.
- **Side Effects**: Nenhum.
- **Constraints Aplicáveis**: C1 (formato de chunks), C5 (preservação de ordem), C7 (não quebrar fluxo), C8 (logs).
- **Dependências**: `langchain-core`, `langgraph`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
# ...
```

### 1. Streaming de Tokens com Chain Simples

```python
chain = prompt | ChatOpenAI(model="gpt-4o-mini", streaming=True) | StrOutputParser()
for chunk in chain.stream({"topic": "IA"}):
    print(chunk, end="", flush=True)
```

### 2. Streaming Assíncrono

```python
async def stream_async():
    async for chunk in chain.astream({"topic": "IA"}):
        print(chunk, end="", flush=True)
```

### 3. Streaming de Agentes com `stream` (LangGraph)

```python
from langgraph.prebuilt import create_react_agent

agent = create_react_agent(llm, tools)
for event in agent.stream(
    {"messages": [("user", "Busque informações sobre LangChain")]},
    stream_mode="values"
):
    event["messages"][-1].pretty_print()
```

### 4. Streaming de Eventos com `streamEvents` (TypeScript)

```typescript
const eventStream = executor.streamEvents(
    { input: "Calcule 15% de gorjeta sobre $85", chat_history: [] },
    { version: "v2" }
);
for await (const event of eventStream) {
    if (event.event === "on_chat_model_stream") {
        process.stdout.write(event.data.chunk.content ?? "");
    }
}
```

### 5. Streaming de RAG

```python
retrieval_chain = (
    {"context": retriever, "question": RunnablePassthrough()}
    | prompt | llm | StrOutputParser()
)
for chunk in retrieval_chain.stream("O que é LangChain?"):
    print(chunk, end="", flush=True)
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_streaming_chain():
    chain = prompt | ChatOpenAI(model="gpt-4o-mini", streaming=True) | StrOutputParser()
    chunks = list(chain.stream({"topic": "test"}))
    assert len(chunks) > 0
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/langchain-streaming-patterns.md --json
```

---

## 🔗 Referências Cruzadas
- [[langchain-sdk-patterns.md]]
