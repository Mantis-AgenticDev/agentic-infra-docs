---
artifact_id: "langchain-chains-orchestration"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/langchain-chains-orchestration.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/langchain-chains-orchestration.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:langchain-chains-orchestration-v1.0.0"
generated_at: "2026-05-26T14:45:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["langchain-agents-orchestration"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# ⛓️ LangChain Chains Orchestration – LCEL Avançado

> **Contrato modular**: Artefato filho do Master Agent. Explora padrões avançados de composição de chains com LCEL: RunnableSequence, RunnableParallel, RunnableBranch, RunnablePassthrough, map‑reduce e router chains.

---

## 🎯 Propósito
Permitir que agentes MANTIS tradicionais componham pipelines complexos de processamento de linguagem usando todos os recursos de LCEL.

## 📋 Especificação (SDD)
- **Entradas**: Prompts, modelos, parsers.
- **Saídas**: Chains compostas e executáveis.
- **Side Effects**: Nenhum.
- **Constraints Aplicáveis**: C1 (tipagem), C5 (schema de entrada/saída), C7 (fallback), C8 (logs).
- **Dependências**: `langchain-core`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. RunnableSequence (Sequencial)

```python
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)

# Step 1
idea_prompt = ChatPromptTemplate.from_template("Gere 3 ideias criativas para: {topic}")
idea_chain = idea_prompt | llm | StrOutputParser()

# Step 2
eval_prompt = ChatPromptTemplate.from_template("Avalie estas ideias e escolha a melhor:\n{ideas}")
eval_chain = eval_prompt | llm | StrOutputParser()

# Combinação sequencial
sequential = {"ideas": idea_chain} | RunnablePassthrough.assign(evaluation=eval_chain)
result = sequential.invoke({"topic": "app mobile"})
```

### 2. RunnableParallel (Map)

```python
from langchain_core.runnables import RunnableParallel

map_chain = RunnableParallel(
    summary=ChatPromptTemplate.from_template("Resuma: {text}") | llm | StrOutputParser(),
    keywords=ChatPromptTemplate.from_template("Palavras-chave: {text}") | llm | StrOutputParser(),
    sentiment=ChatPromptTemplate.from_template("Sentimento: {text}") | llm | StrOutputParser(),
)
result = map_chain.invoke({"text": "LangChain é incrível!"})
```

### 3. RunnableBranch (Condicional)

```python
from langchain_core.runnables import RunnableBranch

technical = ChatPromptTemplate.from_template("Explique tecnicamente: {query}") | llm | StrOutputParser()
simple = ChatPromptTemplate.from_template("Explique de forma simples: {query}") | llm | StrOutputParser()

branch = RunnableBranch(
    (lambda x: "complex" in x.get("type", "").lower(), technical),
    simple,
)

chain = {"type": lambda x: x["type"], "query": lambda x: x["query"]} | branch
result = chain.invoke({"type": "complex", "query": "quantum entanglement"})
```

### 4. RunnablePassthrough (Injeção de Contexto)

```python
from langchain_core.runnables import RunnablePassthrough

def fetch_context(query):
    return {"context": f"Dados relevantes para: {query}"}

chain = (
    RunnablePassthrough.assign(context=lambda x: fetch_context(x["query"]))
    | ChatPromptTemplate.from_template("Contexto: {context}\nQuery: {query}")
    | llm | StrOutputParser()
)
```

### 5. Map‑Reduce

```python
map_chain = RunnableParallel(
    summary=ChatPromptTemplate.from_template("Resuma: {text}") | llm | StrOutputParser(),
    keywords=ChatPromptTemplate.from_template("Palavras-chave: {text}") | llm | StrOutputParser(),
)
reduce_prompt = ChatPromptTemplate.from_template("Combine:\nSummary: {summary}\nKeywords: {keywords}")
map_reduce = map_chain | reduce_prompt | llm | StrOutputParser()
result = map_reduce.invoke({"text": "Texto longo..."})
```

### 6. Stuff Documents Chain

```python
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain_core.documents import Document

prompt = ChatPromptTemplate.from_template("Responda baseado no contexto:\n{context}\nPergunta: {input}")
doc_chain = create_stuff_documents_chain(llm, prompt)
result = doc_chain.invoke({
    "input": "O que LangChain suporta?",
    "context": [Document(page_content="LangChain suporta múltiplos provedores.")]
})
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_runnable_sequence():
    chain = ChatPromptTemplate.from_template("Diga oi") | ChatOpenAI(model="gpt-4o-mini") | StrOutputParser()
    result = chain.invoke({})
    assert isinstance(result, str)
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/langchain-chains-orchestration.md --json
```

---

## 🔗 Referências Cruzadas
- [[langchain-agents-orchestration.md]]
