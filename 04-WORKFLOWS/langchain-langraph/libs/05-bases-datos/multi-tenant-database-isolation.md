---
artifact_id: "multi-tenant-database-isolation"
artifact_type: "workflow_skill"
version: "2.0.0"
constraints_mapped: ["C1","C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/multi-tenant-database-isolation.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/multi-tenant-database-isolation.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:multi-tenant-db-v2.0.0"
generated_at: "2026-05-25T12:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["postgresql-pgvector-enterprise", "deploy-multi-tenant"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Refundado"
next_review: "2026-06-24"
---

# 🏢 Multi‑Tenant Database Isolation – RLS, Namespaces e Auditoria

> **Contrato modular**: Implementa isolamento de tenants em PostgreSQL, Qdrant e outras stores, com políticas RLS, coleções separadas e trilhas de auditoria.

---

## 🎯 Propósito
Impedir vazamento de dados entre tenants, atendendo ao constraint C4 com mecanismos robustos e auditáveis.

## 📋 Especificação (SDD)
- **Entradas**: Tenant ID, dados a serem isolados.
- **Saídas**: Acesso restrito aos dados do tenant.
- **Side Effects**: Criação de políticas RLS, coleções, logs de auditoria.
- **Constraints Aplicáveis**: C1 (schema), C3 (proteção), C4 (isolamento), C5 (metadados), C7 (falha segura), C8 (auditoria).
- **Dependências**: PostgreSQL, PGVector, Qdrant.

---

## 🛡️ Bootstrap (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    import json, datetime, os
    def mantis_log(level, event, detail=""):
        entry = {"ts": datetime.datetime.utcnow().isoformat() + "Z", "level": level, "tenant": os.getenv("TENANT_ID", "global"), "event": event, "detail": detail, "trace_id": os.getenv("TRACE_ID", "null"), "span_id": os.getenv("SPAN_ID", "null"), "fallback": "true"}
        print(json.dumps(entry), flush=True)
```

### 1. PostgreSQL Row‑Level Security (RLS)
```sql
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents FORCE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON documents
    FOR ALL
    USING (tenant_id = current_setting('app.current_tenant'))
    WITH CHECK (tenant_id = current_setting('app.current_tenant'));
```
```python
def set_tenant(conn, tenant_id):
    conn.execute(text(f"SET app.current_tenant = '{tenant_id}'"))

with engine.connect() as conn:
    set_tenant(conn, "acme")
    conn.execute(text("INSERT INTO documents (tenant_id, content) VALUES ('acme', 'data')"))
    # SELECT retorna apenas rows com tenant_id='acme'
```

### 2. Função de Inicialização de Sessão
```python
from sqlalchemy import event

@event.listens_for(engine, "connect")
def set_tenant_on_connect(dbapi_conn, connection_record):
    dbapi_conn.execute(f"SET app.current_tenant = '{os.getenv('TENANT_ID', 'global')}'")
```

### 3. Qdrant – Coleções por Tenant
```python
def get_tenant_qdrant_store(tenant_id, client, embeddings):
    collection_name = f"docs_tenant_{tenant_id}"
    if not client.collection_exists(collection_name):
        client.create_collection(collection_name, vectors_config=VectorParams(size=1536, distance=Distance.COSINE))
    return QdrantVectorStore(client=client, collection_name=collection_name, embedding=embeddings)
```

### 4. Filtro por Tenant nos Metadados (Chroma, InMemory)
```python
def add_with_tenant(store, docs, tenant_id):
    for doc in docs:
        doc.metadata["tenant_id"] = tenant_id
    store.add_documents(docs)

def search_with_tenant(store, query, tenant_id, k=5):
    return store.similarity_search(query, k=k, filter={"tenant_id": tenant_id})
```

### 5. Auditoria de Acesso
```python
def audit_access(tenant_id, query, result_count):
    mantis_log("AUDIT", "tenant_access", json.dumps({
        "tenant": tenant_id,
        "query": query[:100],
        "results": result_count,
        "timestamp": datetime.datetime.utcnow().isoformat()
    }))
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_tenant_filter():
    store = InMemoryVectorStore(DeterministicFakeEmbedding(size=128))
    add_with_tenant(store, [Document("A")], "t1")
    add_with_tenant(store, [Document("B")], "t2")
    results = search_with_tenant(store, "A", "t1")
    assert all(r.metadata["tenant_id"] == "t1" for r in results)
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/multi-tenant-database-isolation.md --json
```

---

## 🔗 Referências Cruzadas
- [[postgresql-pgvector-enterprise.md]]
- [[deploy-multi-tenant.md]]
