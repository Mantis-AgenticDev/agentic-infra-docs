---
artifact_id: "postgresql-pgvector-enterprise"
artifact_type: "workflow_skill"
version: "2.0.0"
constraints_mapped: ["C1","C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/postgresql-pgvector-enterprise.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/postgresql-pgvector-enterprise.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:pgvector-enterprise-v2.0.0"
generated_at: "2026-05-25T11:10:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["database-vectorstore-unified", "integration-postgres-pgvector"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Refundado"
next_review: "2026-06-24"
---

# 🐘 PostgreSQL + pgvector Enterprise – Instalação, Índices, Particionamento e RLS

> **Contrato modular**: Guia completo para implantar pgvector como vector store empresarial, cobrindo desde a instalação da extensão até índices HNSW, particionamento, replicação e segurança multi‑tenant.

---

## 🎯 Propósito
Estabelecer o PostgreSQL com extensão pgvector como a espinha dorsal de armazenamento vetorial do ecossistema MANTIS, garantindo desempenho, confiabilidade e isolamento de tenants.

## 📋 Especificação (SDD)
- **Entradas**: Conexão PostgreSQL, documentos, configuração de índice.
- **Saídas**: Vector store operacional e otimizada.
- **Side Effects**: Escritas no banco de dados, criação de índices.
- **Constraints Aplicáveis**: C1 (schema do banco), C3 (proteção de credenciais), C4 (tenant isolation via RLS), C5 (estrutura de tabelas), C7 (pooling e retry), C8 (logs).
- **Dependências**: `langchain-postgres`, `pgvector`, `psycopg2`.

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

### 1. Instalação e Configuração Inicial
```sql
-- Criar extensão pgvector
CREATE EXTENSION IF NOT EXISTS vector;

-- Tabela de documentos com metadados JSONB
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id TEXT NOT NULL DEFAULT 'global',
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    embedding VECTOR(1536),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Índices para performance
CREATE INDEX idx_documents_tenant ON documents(tenant_id);
CREATE INDEX idx_documents_metadata ON documents USING GIN (metadata jsonb_path_ops);
```

### 2. Conexão via LangChain com PGVector
```python
from langchain_postgres import PGVector
from langchain_openai import OpenAIEmbeddings

embeddings = OpenAIEmbeddings(model="text-embedding-3-small")

vectorstore = PGVector(
    embeddings=embeddings,
    collection_name="documents",
    connection="postgresql+psycopg://user:pass@localhost:5432/mantis",
    use_jsonb=True,
    pre_delete_collection=False
)
```

### 3. Criação de Índices Vetoriais (HNSW e IVFFlat)
```sql
-- IVFFlat: rápido para construção, adequado para datasets estáticos
CREATE INDEX ON documents USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- HNSW: melhor performance de busca, maior consumo de memória
CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops) WITH (m = 16, ef_construction = 200);
```

### 4. Busca com Filtro de Metadados e Tenant
```python
# Busca com filtro de tenant
results = vectorstore.similarity_search(
    "consulta",
    k=5,
    filter={"tenant_id": "acme", "source": "manual"}
)
```

### 5. Multi‑Tenancy com Row‑Level Security (C4)
```sql
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON documents
    FOR ALL
    USING (tenant_id = current_setting('app.current_tenant', true))
    WITH CHECK (tenant_id = current_setting('app.current_tenant', true));
```
```python
# Configurar tenant na sessão
from sqlalchemy import text
with engine.connect() as conn:
    conn.execute(text("SET app.current_tenant = 'acme'"))
    conn.execute(text("INSERT INTO documents (tenant_id, content, embedding) VALUES ('acme', 'texto', ...)"))
    # Qualquer SELECT automaticamente filtra por tenant_id = 'acme'
```

### 6. Particionamento por Tenant
```sql
CREATE TABLE documents_partitioned (
    id UUID,
    tenant_id TEXT NOT NULL,
    content TEXT,
    embedding VECTOR(1536)
) PARTITION BY LIST (tenant_id);

CREATE TABLE documents_acme PARTITION OF documents_partitioned FOR VALUES IN ('acme');
CREATE TABLE documents_startup PARTITION OF documents_partitioned FOR VALUES IN ('startup');
```

### 7. Backup e Restore
```bash
# Backup lógico
pg_dump -h localhost -U postgres -d mantis -t documents > backup.sql
# Restore
psql -h localhost -U postgres -d mantis < backup.sql
```

### 8. Configuração de Pooling com PgBouncer
```yaml
# docker-compose
services:
  pgbouncer:
    image: edoburu/pgbouncer
    environment:
      DB_USER: postgres
      DB_PASSWORD: secret
      DB_HOST: postgres
      DB_NAME: mantis
    ports:
      - "6432:6432"
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_pgvector_add_search():
    from langchain_core.embeddings import DeterministicFakeEmbedding
    store = PGVector(
        embeddings=DeterministicFakeEmbedding(size=1536),
        collection_name="test",
        connection="postgresql+psycopg://test:test@localhost/test",
        use_jsonb=True
    )
    store.add_documents([Document("teste")], ids=["1"])
    results = store.similarity_search("teste", k=1)
    assert len(results) == 1
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/postgresql-pgvector-enterprise.md --json
```

---

## 🔗 Referências Cruzadas
- [[database-vectorstore-unified.md]]
- [[integration-postgres-pgvector.md]]
