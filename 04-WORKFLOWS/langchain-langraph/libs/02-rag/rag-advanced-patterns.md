---
artifact_id: "rag-advanced-patterns"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/rag-advanced-patterns.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/rag-advanced-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:rag-advanced-patterns-v1.0.0"
generated_at: "2026-05-25T00:10:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["agents-swarm-architecture", "memory-hybrid", "integration-postgres-pgvector"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧠 RAG Advanced Patterns – Self‑RAG, Corrective RAG, Agéntic RAG e Graph RAG

> **Contrato modular**: Documenta os padrões avançados de RAG que elevam a precisão e a autonomia dos agentes, incluindo Self‑RAG (reflexão), Corrective RAG (correção), Agéntic RAG (ferramentas) e Graph RAG (grafos de conhecimento), com implementações completas em LangGraph.

---

## 🎯 Propósito
Elevar o pipeline RAG básico a um nível de inteligência agéntica, permitindo que os agentes MANTIS decidam se devem buscar, verifiquem a qualidade do que foi recuperado, corrijam alucinações e integrem conhecimento estruturado de grafos.

## 📋 Especificação (SDD)
- **Entradas**: Consulta, vector store, LLM com capacidade de raciocínio.
- **Saídas**: Resposta final com autocorreção e possível justificativa.
- **Side Effects**: Chamadas adicionais de LLM e possíveis escritas em cache de verificação.
- **Constraints**: C1 (contrato de decisão), C5 (rastreabilidade), C7 (fallback), C8 (logs de cada etapa), C9 (span trace).
- **Dependências**: `langgraph`, `langchain-core`, `langchain-openai`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ... (fallback padrão)
```

### 1. Self‑RAG – O Agente Decide se Deve Recuperar e se a Resposta é Boa
```python
from typing import TypedDict, Literal
from langgraph.graph import StateGraph, START, END

class SelfRAGState(TypedDict):
    question: str
    context: list
    answer: str
    needs_retrieval: bool
    quality_score: float

def decide_retrieval(state: SelfRAGState):
    prompt = f"Essa pergunta requer acesso a documentos externos? Responda 'sim' ou 'não'.\nPergunta: {state['question']}"
    response = llm.invoke(prompt).content.strip().lower()
    state["needs_retrieval"] = "sim" in response
    mantis_log("INFO", "selfrag_decide", f"Necessita retrieval: {state['needs_retrieval']}")
    return state

def retrieve(state: SelfRAGState):
    if state["needs_retrieval"]:
        docs = retriever.invoke(state["question"])
        state["context"] = docs
        mantis_log("INFO", "selfrag_retrieve", f"{len(docs)} docs")
    return state

def generate(state: SelfRAGState):
    if state.get("context"):
        context = "\n\n".join(d.page_content for d in state["context"])
        prompt = f"Contexto:\n{context}\n\nPergunta: {state['question']}\nResposta:"
    else:
        prompt = f"Pergunta: {state['question']}\nResposta (sem conhecimento externo):"
    state["answer"] = llm.invoke(prompt).content
    return state

def evaluate_quality(state: SelfRAGState):
    # LLM avalia se a resposta está correta e relevante
    eval_prompt = f"Pergunta: {state['question']}\nResposta: {state['answer']}\nAvalie a qualidade de 0 a 1. Apenas o número:"
    score = float(llm.invoke(eval_prompt).content.strip())
    state["quality_score"] = score
    mantis_log("INFO", "selfrag_eval", f"Score: {score}")
    return state

def should_regenerate(state: SelfRAGState) -> Literal["generate", "end"]:
    if state["quality_score"] < 0.7:
        mantis_log("WARN", "low_quality", "Regenerando resposta...")
        return "generate"  # poderia voltar a retrieve também
    return "end"

builder = StateGraph(SelfRAGState)
builder.add_node("decide_retrieval", decide_retrieval)
builder.add_node("retrieve", retrieve)
builder.add_node("generate", generate)
builder.add_node("evaluate_quality", evaluate_quality)
builder.add_edge(START, "decide_retrieval")
builder.add_edge("decide_retrieval", "retrieve")
builder.add_edge("retrieve", "generate")
builder.add_edge("generate", "evaluate_quality")
builder.add_conditional_edges("evaluate_quality", should_regenerate, {"generate": "generate", "end": END})
self_rag = builder.compile()
```

### 2. Corrective RAG – Verificação e Correção dos Documentos Recuperados
```python
def verify_and_correct(state: SelfRAGState):
    # Verifica se o contexto é relevante e corrige se necessário
    if not state.get("context"):
        # Reescrita da consulta para melhorar busca
        rewritten_query = llm.invoke(
            f"A pergunta original '{state['question']}' não teve bons resultados. Reformule para melhorar a busca:"
        ).content
        state["question"] = rewritten_query
        state["context"] = retriever.invoke(rewritten_query)
        mantis_log("INFO", "corrective_rag", f"Nova consulta: {rewritten_query}")
    return state
```

### 3. Agéntic RAG – Ferramenta de RAG dentro de um Agente
```python
from langchain.agents import create_agent
from langchain.tools import tool

@tool
def research_tool(query: str) -> str:
    """Pesquisar informações na base de conhecimento interna."""
    docs = retriever.invoke(query)
    if not docs:
        return "Nenhuma informação encontrada."
    return "\n\n".join(d.page_content for d in docs)

agent = create_agent(
    model="anthropic:claude-sonnet-4-5",
    tools=[research_tool],
    system_prompt="Você é um assistente de pesquisa com acesso à documentação interna. Use a ferramenta de pesquisa sempre que necessário."
)
# O agente decide quando usar a ferramenta
result = agent.invoke({"messages": [{"role": "user", "content": "Quais são as políticas de segurança?"}]})
mantis_log("INFO", "agentic_rag", "Consulta via agente RAG concluída")
```

### 4. Graph RAG – Integração com Grafos de Conhecimento
```python
# Exemplo conceitual: combinar busca vetorial com consulta a um grafo (Neo4j)
# Aqui usamos um stub para ilustrar o fluxo
class GraphRAG:
    def __init__(self, vectorstore, graph_conn):
        self.vectorstore = vectorstore
        self.graph = graph_conn

    def query(self, question: str):
        # 1. Busca vetorial para entidades
        docs = self.vectorstore.similarity_search(question, k=3)
        entities = self._extract_entities(docs)
        # 2. Expande via grafo
        graph_context = self.graph.query(f"MATCH (n)-[r]->(m) WHERE n.name IN {entities} RETURN n, r, m")
        # 3. Combina contextos
        combined = self._format_context(docs, graph_context)
        prompt = f"Contexto:\n{combined}\n\nPergunta: {question}\nResposta:"
        return llm.invoke(prompt).content

    def _extract_entities(self, docs):
        # Simplificado: usa LLM para extrair entidades dos documentos
        text = " ".join(d.page_content for d in docs)
        response = llm.invoke(f"Extraia as principais entidades do texto (separadas por vírgula): {text}")
        return [e.strip() for e in response.content.split(",")]

# Uso:
# graph_rag = GraphRAG(vectorstore, neo4j_connection)
# answer = graph_rag.query("Como a Empresa X se relaciona com a Y?")
```

### 5. Padrão de Orquestração de Múltiplas Fontes
```python
def multi_source_rag(query: str):
    sources = {
        "documentos_internos": retriever_interno,
        "web": retriever_web,
        "faq": retriever_faq
    }
    all_docs = []
    for name, ret in sources.items():
        docs = ret.invoke(query)
        for doc in docs:
            doc.metadata["source_type"] = name
        all_docs.extend(docs)
        mantis_log("INFO", "multi_source", f"{name}: {len(docs)} docs")

    # Re‑ranking unificado
    ranked = rerank_with_cohere(query, all_docs)
    return generate_response(query, ranked[:5])
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_self_rag_decision():
    state = {"question": "Qual o tempo hoje?", "context": [], "answer": "", "needs_retrieval": False, "quality_score": 0.0}
    new_state = decide_retrieval(state)
    # A pergunta sobre tempo deve geralmente pedir retrieval
    assert new_state["needs_retrieval"] == True
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/rag-advanced-patterns.md --json
```

---

## 🔗 Referências Cruzadas
- [[rag-fundamentals.md]]
- [[agents-single.md]]
- [[memory-hybrid.md]]
