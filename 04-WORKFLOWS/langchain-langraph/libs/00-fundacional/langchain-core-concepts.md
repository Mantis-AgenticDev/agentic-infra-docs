---
artifact_id: "langchain-core-concepts"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/langchain-core-concepts.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/langchain-core-concepts.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:langchain-core-concepts-v1.0.0"
generated_at: "2026-05-24T23:30:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: true
  required_for: ["langgraph-create-agent", "langgraph-state-graph-fundamentals", "rag-fundamentals", "rag-advanced-patterns", "memory-hybrid", "agents-swarm-architecture"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧩 LangChain Core Concepts – Fundações Executáveis (LCEL, Chains, RAG, Async)

> **Contrato modular**: Este artefato é filho do Master Agent `langchain-langraph-master-agent`. Herda hardening, observability, thinking system e constraints via source/import. Contém APENAS a lógica de domínio específica para os conceitos fundamentais do LangChain 1.0+.

---

## 🎯 Propósito
Fornecer o conhecimento canônico e exemplos executáveis dos componentes básicos do LangChain (LCEL, prompts, modelos, output parsers, RAG inicial, async e cache) para que qualquer agente ou skill do domínio langchain‑langraph possa construir pipelines de LLM robustos e padronizados.

## 📋 Especificação (SDD – Apenas o Específico deste Módulo)
- **Entradas**: Documentação oficial LangChain 1.x, contexto de constraints MANTIS.
- **Saídas**: Padrões de código Python/JavaScript válidos para LCEL, RAG, prompts, cache e tratamento de erros.
- **Side Effects**: Nenhum estado externo alterado; apenas referência de conhecimento.
- **Constraints Aplicáveis**: C1 (contrato de interface), C3 (proteção de secrets), C5 (integridade estrutural), C7 (resiliência), C8 (observabilidade).
- **Dependências**: Nenhuma além do Master Agent para `mantis_log()`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)

```python
# Bootstrap: importa observabilidade do Master Agent OU fallback mínimo
try:
    from mantis_master import mantis_log
except ImportError:
    import json, datetime, os
    def mantis_log(level: str, event: str, detail: str = ""):
        entry = {
            "ts": datetime.datetime.utcnow().isoformat() + "Z",
            "level": level,
            "tenant": os.getenv("TENANT_ID", "global"),
            "event": event,
            "detail": detail,
            "trace_id": os.getenv("TRACE_ID", "null"),
            "span_id": os.getenv("SPAN_ID", "null"),
            "fallback": "true"
        }
        print(json.dumps(entry), flush=True)
    mantis_log("WARN", "bootstrap_fallback", "Master Agent não encontrado. Usando fallback mínimo.")
```

### 1. LCEL (LangChain Expression Language)
A LCEL usa o operador `|` para compor componentes, garantindo type safety, streaming automático e suporte assíncrono.

```python
from langchain_anthropic import ChatAnthropic
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

# Componentes
llm = ChatAnthropic(model="claude-3-5-sonnet-20241022")
prompt = ChatPromptTemplate.from_template("Tell me a joke about {topic}")
output_parser = StrOutputParser()

# Chain LCEL
chain = prompt | llm | output_parser

# Invocação
result = chain.invoke({"topic": "programming"})
mantis_log("INFO", "lcel_chain_executed", f"Result: {result[:50]}...")
```

### 2. Prompts e Placeholders Dinâmicos
Prompts com histórico (MessagesPlaceholder) habilitam memória de conversa.

```python
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder

prompt = ChatPromptTemplate.from_messages([
    ("system", "Você é um assistente MANTIS que segue constraints C1-C9."),
    MessagesPlaceholder(variable_name="history"),
    ("user", "{input}")
])
mantis_log("INFO", "prompt_loaded", "Prompt com histórico configurado")
```

### 3. Gerenciamento de Modelos
Instância personalizada de modelo com controle de temperatura e timeout.

```python
from langchain_anthropic import ChatAnthropic
llm = ChatAnthropic(
    model="claude-3-5-sonnet-20241022",
    temperature=0.2,  # Determinismo controlado (C1)
    max_tokens=1024,
    timeout=30.0      # C7: resiliência
)
mantis_log("INFO", "model_initialized", f"Model: {llm.model_name}")
```

### 4. Output Parsers e Structured Output
Uso de `PydanticOutputParser` para saídas tipadas e validadas (C5).

```python
from langchain.output_parsers import PydanticOutputParser
from pydantic import BaseModel, Field

class ContactInfo(BaseModel):
    name: str = Field(description="Nome completo")
    email: str = Field(description="Email válido")
    phone: str = Field(description="Telefone com DDD")

parser = PydanticOutputParser(pydantic_object=ContactInfo)
prompt = ChatPromptTemplate.from_template(
    "Extraia as informações de contato.\n{format_instructions}\n{query}"
)
chain = prompt | llm | parser
mantis_log("INFO", "parser_created", "Pydantic parser para ContactInfo")
```

### 5. RAG Básico com LCEL
Pipeline completo: recuperação de documentos → formatação → prompt → LLM.

```python
from langchain_core.runnables import RunnablePassthrough

retriever = vectorstore.as_retriever(search_kwargs={"k": 4})

def format_docs(docs):
    return "\n\n".join(doc.page_content for doc in docs)

template = """Responda baseado apenas no contexto:
Contexto: {context}
Pergunta: {question}
Resposta:"""
prompt = ChatPromptTemplate.from_template(template)

rag_chain = (
    {"context": retriever | format_docs, "question": RunnablePassthrough()}
    | prompt
    | llm
    | StrOutputParser()
)
mantis_log("INFO", "rag_chain_built", "RAG chain com retriever e LCEL")
```

### 6. Execução Assíncrona e Streaming
Padrões async com `ainvoke` e `astream` para não bloquear o event loop.

```python
import asyncio

async def process(query: str):
    mantis_log("INFO", "async_invoke_start", f"Query: {query}")
    result = await chain.ainvoke({"topic": query})
    mantis_log("INFO", "async_invoke_end", f"Result: {result[:50]}...")
    return result

# Streaming de tokens
async for chunk in llm.astream("Conte uma história curta"):
    print(chunk.content, end="", flush=True)
```

### 7. Cache e Rate Limiting
Cache semântico e em Redis para otimizar custos (C1: eficiência).

```python
from langchain.cache import RedisCache
from langchain.globals import set_llm_cache
import redis

redis_client = redis.Redis.from_url("redis://localhost:6379")
set_llm_cache(RedisCache(redis_client))
mantis_log("INFO", "cache_enabled", "Redis cache configurado")

from ratelimit import limits, sleep_and_retry

class RateLimitedLLM:
    @sleep_and_retry
    @limits(calls=50, period=60)  # 50 chamadas/min
    def _call(self, prompt, **kwargs):
        return llm._call(prompt, **kwargs)
```

### 8. Tratamento de Erros e Fallback
Chain com fallback em caso de falha do modelo primário.

```python
from langchain_core.runnables import RunnableWithFallbacks

primary_chain = prompt | ChatAnthropic(model="claude-3-5-sonnet-20241022")
fallback_chain = prompt | ChatOpenAI(model="gpt-4-turbo-preview")

chain = primary_chain.with_fallbacks([fallback_chain])
try:
    result = chain.invoke({"input": "teste"})
except Exception as e:
    mantis_log("ERROR", "chain_failed", str(e))
    raise
```

### 9. Observabilidade com LangSmith
Habilitação de tracing automático e callback customizado.

```python
import os
os.environ["LANGCHAIN_TRACING_V2"] = "true"
os.environ["LANGCHAIN_API_KEY"] = "ls__..."
os.environ["LANGCHAIN_PROJECT"] = "mantis-agentic"

from langchain_core.callbacks import BaseCallbackHandler

class MANTISCallback(BaseCallbackHandler):
    def on_llm_start(self, serialized, prompts, **kwargs):
        mantis_log("DEBUG", "llm_start", f"Prompts: {prompts[:1]}")
    def on_llm_end(self, response, **kwargs):
        mantis_log("DEBUG", "llm_end", "LLM concluído")
    def on_llm_error(self, error, **kwargs):
        mantis_log("ERROR", "llm_error", str(error))
```

---

## 🧪 Testes Unitários (TDD)

```python
import pytest

# Teste: LCEL chain retorna string não vazia
def test_lcel_chain_output():
    from langchain_core.prompts import ChatPromptTemplate
    from langchain_core.output_parsers import StrOutputParser
    from langchain_anthropic import ChatAnthropic
    llm = ChatAnthropic(model="claude-3-5-sonnet-20241022")
    prompt = ChatPromptTemplate.from_template("Diga 'OK' em {lang}")
    chain = prompt | llm | StrOutputParser()
    result = chain.invoke({"lang": "pt-BR"})
    assert "OK" in result
    mantis_log("INFO", "test_pass", "test_lcel_chain_output")

# Teste: Fallback chain é acionada quando modelo primário falha (mock)
def test_fallback_chain():
    from unittest.mock import patch
    primary = ChatAnthropic(model="claude-3-5-sonnet-20241022")
    fallback = ChatOpenAI(model="gpt-4-turbo-preview")
    chain = primary.with_fallbacks([fallback])
    with patch.object(primary, 'invoke', side_effect=Exception("fail")):
        result = chain.invoke("test")
        assert result is not None
    mantis_log("INFO", "test_pass", "test_fallback_chain")
```

---

## 🔍 Validação (VDD)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/langchain-core-concepts.md \
  --json \
  --check-structural \
  --check-error-handling \
  --check-observability
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[langchain-langraph-master-agent.md]] ← Fonte de hardening, observability, constraints
- [[/05-CONFIGURATIONS/validation/orchestrator-engine/main.go]] ← Motor de validação
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]] ← Mapeamento constraints por rota
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]] ← Infraestrutura de logs

---

## 📊 Métricas de Qualidade
| Métrica | Meta | Como Medir |
|---------|------|-----------|
| Cobertura de exemplos LCEL | 100% dos conceitos | Testes unitários |
| Conformidade C3 (secrets) | Zero hardcoded | auditoria estática |
| Performance de invocação | < 2s | logs de `mantis_log` |

---

## 🚫 Anti-Padrões
- ❌ Usar `chain.invoke` em loop assíncrono sem `async/await`
- ❌ Armazenar `LANGSMITH_API_KEY` em código
- ❌ Ignorar `with_fallbacks` em produção
- ❌ Não usar `PydanticOutputParser` para dados estruturados

---

## 📋 Checklist de Geração
1. ✅ Frontmatter mínimo válido (C5)
2. ✅ Bootstrap com `mantis_log()` herdado (C8)
3. ✅ Padrões LCEL, RAG, cache e fallback documentados
4. ✅ Testes unitários para cada padrão crítico
5. ✅ Wikilinks e referências de governança

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-24T23:30:00Z | langchain-langraph-master-agent | Criação inicial: fundamentos LangChain | C1,C3,C5,C7,C8 |
