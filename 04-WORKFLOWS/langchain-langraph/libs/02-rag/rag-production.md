---
artifact_id: "rag-production"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/rag-production.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/rag-production.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:rag-production-v1.0.0"
generated_at: "2026-05-25T00:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deploy-docker", "deploy-kubernetes", "integration-configurations", "cost-optimization"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🏭 RAG em Produção – Cache, Rate Limiting, Monitoramento e Otimização de Custos

> **Contrato modular**: Guia completo para operar pipelines RAG em produção, cobrindo cache de embeddings, rate limiting, monitoramento via LangSmith, deduplicação de documentos e estratégias de custo.

---

## 🎯 Propósito
Garantir que o sistema RAG dos agentes MANTIS seja eficiente, econômico e observável, suportando cargas de produção sem degradação.

## 📋 Especificação (SDD)
- **Entradas**: Configuração de cache, limites de taxa, chaves de API.
- **Saídas**: Pipelines otimizados com métricas de custo e desempenho.
- **Side Effects**: Escritas em Redis/banco de dados para cache.
- **Constraints**: C1 (limites de taxa), C2 (reprodutibilidade), C3 (proteção de chaves), C4 (multi‑tenant), C5 (estrutura de cache), C7 (resiliência), C8 (logs e tracing), C9 (contexto de trace).
- **Dependências**: `redis`, `langchain`, `langsmith`, `prometheus-client`.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ... (fallback)
```

### 1. Cache de Embeddings (Evitando Re‑cálculo)
```python
from langchain.embeddings import CacheBackedEmbeddings
from langchain.storage import RedisStore
import redis

redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)
store = RedisStore(client=redis_client, namespace="embeddings_cache")
cached_embeddings = CacheBackedEmbeddings.from_bytes_store(
    underlying_embeddings=OpenAIEmbeddings(),
    document_embedding_cache=store,
    query_embedding_cache=store  # também cache de consultas
)
mantis_log("INFO", "cache_configured", "Cache de embeddings via Redis ativo")
```

### 2. Rate Limiting com Tenacity
```python
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=2, max=10)
)
def embed_with_retry(texts):
    return cached_embeddings.embed_documents(texts)

# Adicionar um limitador de taxa global
from ratelimit import limits, sleep_and_retry

@sleep_and_retry
@limits(calls=100, period=60)  # 100 chamadas por minuto
def call_llm(prompt):
    return llm.invoke(prompt)
```

### 3. Monitoramento com Prometheus e Grafana
```python
from prometheus_client import Counter, Histogram, start_http_server

# Métricas
rag_requests = Counter('rag_requests_total', 'Total de consultas RAG')
rag_latency = Histogram('rag_request_latency_seconds', 'Latência do pipeline RAG')
embedding_cache_hits = Counter('embedding_cache_hits_total', 'Cache hits de embeddings')

# Decorator para medir
@rag_latency.time()
def monitored_rag_query(question):
    rag_requests.inc()
    # Verifica cache de consulta
    cached_answer = redis_client.get(f"query_cache:{hash(question)}")
    if cached_answer:
        embedding_cache_hits.inc()
        mantis_log("INFO", "query_cache_hit", question)
        return cached_answer.decode()
    answer = rag_chain.invoke(question)
    redis_client.setex(f"query_cache:{hash(question)}", 3600, answer)
    return answer

start_http_server(8000)
```

### 4. Deduplicação de Documentos (Evitando Ingestão Redundante)
```python
import hashlib

def deduplicate_documents(docs: list) -> list:
    seen_hashes = set()
    unique_docs = []
    for doc in docs:
        content_hash = hashlib.md5(doc.page_content.encode()).hexdigest()
        if content_hash not in seen_hashes:
            seen_hashes.add(content_hash)
            unique_docs.append(doc)
    mantis_log("INFO", "dedup", f"Removidos {len(docs)-len(unique_docs)} documentos duplicados")
    return unique_docs
```

### 5. Otimização de Custos: Modelo Pequeno para Preview, Grande para Final
```python
def two_tier_generation(question):
    # Tier 1: modelo barato para verificar se há resposta
    cheap_llm = ChatOpenAI(model="gpt-3.5-turbo", temperature=0)
    context = retriever.invoke(question)
    preview_prompt = f"Com este contexto, responda brevemente: {question}\nContexto: {context}"
    preview = cheap_llm.invoke(preview_prompt)
    # Se a confiança for baixa, usa modelo caro
    if "não sei" in preview.content.lower():
        mantis_log("WARN", "low_confidence", "Usando modelo premium")
        expensive_llm = ChatOpenAI(model="gpt-4.1", temperature=0)
        return expensive_llm.invoke(preview_prompt).content
    return preview.content
```

### 6. Isolamento Multi‑Tenant com Redis (C4)
```python
def get_tenant_cache_key(tenant_id, key):
    return f"tenant:{tenant_id}:{key}"

# Exemplo de uso
cache_key = get_tenant_cache_key(os.getenv("TENANT_ID"), f"rag_result:{hash(question)}")
```

### 7. Estratégia de Atualização de Documentos (Stale Data)
```python
def reingest_if_changed(doc_path, vectorstore, last_modified_db):
    current_mtime = os.path.getmtime(doc_path)
    if current_mtime > last_modified_db.get(doc_path, 0):
        # Remove documentos antigos e reingere
        vectorstore.delete(filter={"source": doc_path})
        new_docs = loader.load(doc_path)
        chunks = splitter.split_documents(new_docs)
        vectorstore.add_documents(chunks)
        last_modified_db[doc_path] = current_mtime
        mantis_log("INFO", "reingest", f"Documento {doc_path} atualizado")
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_deduplication():
    docs = [Document("A"), Document("A"), Document("B")]
    unique = deduplicate_documents(docs)
    assert len(unique) == 2
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/rag-production.md --json
```

---

## 🔗 Referências Cruzadas
- [[rag-embeddings.md]]
- [[rag-vector-stores.md]]
- [[observability-langsmith.md]]
- [[cost-optimization.md]]
