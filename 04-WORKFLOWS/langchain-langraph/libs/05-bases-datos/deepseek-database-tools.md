---
artifact_id: "deepseek-database-tools"
artifact_type: "workflow_skill"
version: "2.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deepseek-database-tools.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deepseek-database-tools.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deepseek-db-tools-v2.0.0"
generated_at: "2026-05-25T11:50:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deepseek-integration", "tools-custom"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Refundado"
next_review: "2026-06-24"
---

# 🤖 DeepSeek Database Tools – Ferramentas SQL e NoSQL com Raciocínio

> **Contrato modular**: Cria ferramentas de banco de dados que usam DeepSeek para gerar e executar consultas SQL/NoSQL seguras, com validação, análise de schema e graph RAG.

---

## 🎯 Propósito
Permitir que agentes MANTIS realizem consultas e análises em bancos de dados usando DeepSeek como motor de raciocínio, garantindo segurança e eficiência.

## 📋 Especificação (SDD)
- **Entradas**: Schema do banco, pergunta do usuário, histórico de consultas.
- **Saídas**: Resultado da consulta ou explicação.
- **Side Effects**: Execução de SQL/NoSQL no banco alvo.
- **Constraints Aplicáveis**: C1 (schema), C3 (proteção contra injection), C5 (validação), C7 (timeout), C8 (logs).
- **Dependências**: `langchain-deepseek`, `sqlalchemy`, `pymongo`.

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

### 1. Ferramenta SQL Segura (Somente Leitura)
```python
from langchain.tools import tool
from sqlalchemy import create_engine, text, inspect
from langchain_deepseek import ChatDeepSeek

engine = create_engine(os.getenv("DATABASE_URL"), pool_size=5)
llm = ChatDeepSeek(model="deepseek-chat")

@tool
def sql_query(query: str) -> str:
    """Execute uma consulta SQL SELECT segura. Retorna JSON com resultados."""
    if not query.strip().upper().startswith("SELECT"):
        return json.dumps({"error": "Apenas SELECT é permitido"})
    try:
        with engine.connect() as conn:
            result = conn.execute(text(query))
            rows = [dict(row._mapping) for row in result]
            mantis_log("INFO", "sql_success", f"{len(rows)} linhas")
            return json.dumps(rows, default=str)
    except Exception as e:
        mantis_log("ERROR", "sql_failed", str(e))
        return json.dumps({"error": str(e)})

@tool
def get_db_schema() -> str:
    """Retorna o schema das tabelas do banco de dados."""
    inspector = inspect(engine)
    tables = {}
    for table in inspector.get_table_names():
        columns = [{"name": col["name"], "type": str(col["type"])} for col in inspector.get_columns(table)]
        tables[table] = columns
    return json.dumps(tables)
```

### 2. Ferramenta NoSQL (MongoDB)
```python
from pymongo import MongoClient

mongo = MongoClient(os.getenv("MONGO_URL"))
db = mongo.get_database()

@tool
def mongo_query(collection: str, filter_json: str, limit: int = 5) -> str:
    """Consulta coleção MongoDB com filtro JSON."""
    try:
        filter_dict = json.loads(filter_json)
        results = list(db[collection].find(filter_dict).limit(limit))
        return json.dumps(results, default=str)
    except Exception as e:
        mantis_log("ERROR", "mongo_failed", str(e))
        return json.dumps({"error": str(e)})
```

### 3. Agente com DeepSeek e Ferramentas de Banco
```python
from langchain.agents import create_agent

agent = create_agent(
    llm,
    tools=[sql_query, get_db_schema, mongo_query],
    system_prompt="Você é um analista de dados com acesso ao banco de dados. Use as ferramentas para responder perguntas."
)
result = agent.invoke({"messages": [{"role": "user", "content": "Quantos usuários ativos temos este mês?"}]})
```

### 4. Graph RAG com Neo4j
```python
from neo4j import GraphDatabase

neo4j_driver = GraphDatabase.driver("bolt://localhost:7687", auth=("user", "pass"))

@tool
def graph_query(cypher: str) -> str:
    """Executa consulta Cypher no Neo4j."""
    with neo4j_driver.session() as session:
        result = session.run(cypher)
        records = [record.data() for record in result]
        return json.dumps(records, default=str)
```

---

## 🧪 Testes Unitários (TDD)
```python
def test_sql_tool():
    result = sql_query.invoke("SELECT 1")
    assert "1" in result
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deepseek-database-tools.md --json
```

---

## 🔗 Referências Cruzadas
- [[deepseek-integration.md]]
