---
artifact_id: "langchain-memory-systems"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/langchain-memory-systems.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/langchain-memory-systems.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:langchain-memory-systems-v1.0.0"
generated_at: "2026-05-26T17:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["langchain-agents-orchestration", "langchain-chains-orchestration"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# 🧠 LangChain Memory Systems – Buffer, Window, Summary e Vector Store

> **Contrato modular**: Artefato filho do Master Agent. Explora todos os tipos de memória conversacional do LangChain tradicional: `ConversationBufferMemory`, `BufferWindowMemory`, `SummaryMemory`, `SummaryBufferMemory`, `VectorStoreRetrieverMemory` e integração com LangGraph State.

---

## 🎯 Propósito
Permitir que agentes MANTIS tradicionais mantenham contexto de conversa, otimizando tokens e recuperando informações relevantes do histórico.

## 📋 Especificação (SDD)
- **Entradas**: Memória configurada, chain ou agente.
- **Saídas**: Conversas com estado preservado.
- **Side Effects**: Armazenamento de histórico.
- **Constraints Aplicáveis**: C1 (formato de mensagens), C5 (persistência), C7 (fallback se memória falhar), C8 (logs), C9 (thread_id).
- **Dependências**: `langchain.memory`, `langgraph`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. ConversationBufferMemory (Histórico Completo)

```python
from langchain.memory import ConversationBufferMemory
from langchain.chains import LLMChain

memory = ConversationBufferMemory(memory_key="chat_history", return_messages=True)
chain = LLMChain(llm=ChatOpenAI(model="gpt-4o-mini"), prompt=prompt, memory=memory)

chain.run(input="Meu nome é Alice")
response = chain.run(input="Qual é o meu nome?")
# Lembra: "Alice"
```

### 2. ConversationBufferWindowMemory (Últimas K Interações)

```python
from langchain.memory import ConversationBufferWindowMemory

memory = ConversationBufferWindowMemory(k=5, memory_key="chat_history", return_messages=True)
```

### 3. ConversationSummaryMemory (Resumo Automático)

```python
from langchain.memory import ConversationSummaryMemory

memory = ConversationSummaryMemory(llm=ChatOpenAI(model="gpt-4o-mini"), memory_key="chat_history", return_messages=True)
```

### 4. ConversationSummaryBufferMemory (Resumo + Recente)

```python
from langchain.memory import ConversationSummaryBufferMemory

memory = ConversationSummaryBufferMemory(
    llm=ChatOpenAI(model="gpt-4o-mini"),
    max_token_limit=100,
    memory_key="chat_history",
    return_messages=True,
)
```

### 5. VectorStoreRetrieverMemory (Busca Semântica)

```python
from langchain.memory import VectorStoreRetrieverMemory
from langchain_community.vectorstores import FAISS
from langchain_openai import OpenAIEmbeddings

embeddings = OpenAIEmbeddings()
vectorstore = FAISS.from_texts([], embeddings)
memory = VectorStoreRetrieverMemory(retriever=vectorstore.as_retriever(search_kwargs={"k": 5}))

memory.save_context({"input": "Minha cor favorita é azul"}, {"output": "Que legal!"})
relevant = memory.load_memory_variables({"input": "Qual é a minha cor favorita?"})
```

### 6. Recall Memories com LangGraph State

```python
from typing import List
from langgraph.graph import MessagesState, StateGraph, START

class State(MessagesState):
    recall_memories: List[str]

def load_memories(state: State):
    last_message = state["messages"][-1].content if state["messages"] else ""
    docs = vectorstore.similarity_search(last_message, k=3)
    return {"recall_memories": [doc.page_content for doc in docs]}

builder = StateGraph(State)
builder.add_node("load_memories", load_memories)
builder.add_edge(START, "load_memories")
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_buffer_memory():
    memory = ConversationBufferMemory(memory_key="history", return_messages=True)
    memory.save_context({"input": "Oi"}, {"output": "Olá"})
    assert len(memory.load_memory_variables({})["history"]) == 2

def test_window_memory():
    memory = ConversationBufferWindowMemory(k=1, memory_key="history", return_messages=True)
    memory.save_context({"input": "Oi"}, {"output": "Olá"})
    memory.save_context({"input": "Tudo bem?"}, {"output": "Tudo ótimo"})
    assert len(memory.load_memory_variables({})["history"]) == 2  # apenas as últimas 2 mensagens
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/langchain-memory-systems.md --json
```

---

## 🔗 Referências Cruzadas
- [[langchain-agents-orchestration.md]]
