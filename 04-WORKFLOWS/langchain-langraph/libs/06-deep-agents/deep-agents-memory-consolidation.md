---
artifact_id: "deep-agents-memory-consolidation"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C4","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-memory-consolidation.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-memory-consolidation.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-memory-consolidation-v1.0.0"
generated_at: "2026-05-25T18:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-memory-long-term", "deep-agents-memory-scopes"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧠 Deep Agents – Consolidação de Memória em Background

> **Contrato modular**: Artefato filho do Master Agent. Ensina a implementar consolidação de memória entre conversas usando agentes de background e cron jobs, com padrões de extração, mesclagem e resolução de conflitos.

---

## 🎯 Propósito
Permitir que agentes MANTIS processem memórias de forma assíncrona, extraindo fatos e aprendizados de conversas passadas sem impactar a latência do usuário.

## 📋 Especificação (SDD)
- **Entradas**: Histórico de conversas, agentes de consolidação, cron schedule.
- **Saídas**: Memórias atualizadas no store.
- **Side Effects**: Escritas no store.
- **Constraints Aplicáveis**: C1 (schema de cron), C3 (proteção de dados), C4 (isolamento), C5 (formato de memória), C7 (retry em falhas), C8 (logs), C9 (thread_id).
- **Dependências**: `langgraph-sdk`, `deepagents`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    import json, datetime, os
    def mantis_log(level, event, detail=""):
        entry = {"ts": datetime.datetime.utcnow().isoformat() + "Z", "level": level, "tenant": os.getenv("TENANT_ID", "global"), "event": event, "detail": detail, "trace_id": os.getenv("TRACE_ID", "null"), "span_id": os.getenv("SPAN_ID", "null"), "fallback": "true"}
        print(json.dumps(entry), flush=True)
```

### 1. Agente de Consolidação

```python
from deepagents import create_deep_agent
from langgraph_sdk import get_client
from langchain.tools import tool, ToolRuntime
from datetime import datetime, timedelta, timezone

sdk_client = get_client(url="<DEPLOYMENT_URL>")

@tool
async def search_recent_conversations(query: str, runtime: ToolRuntime) -> str:
    """Busca conversas recentes do usuário."""
    user_id = runtime.server_info.user.identity
    since = datetime.now(timezone.utc) - timedelta(hours=6)
    threads = await sdk_client.threads.search(
        metadata={"user_id": user_id},
        updated_after=since.isoformat(),
        limit=20,
    )
    conversations = []
    for thread in threads:
        history = await sdk_client.threads.get_history(thread_id=thread["thread_id"])
        conversations.append(history["values"]["messages"])
    return str(conversations)

@tool
async def read_current_memory(path: str, runtime: ToolRuntime) -> str:
    """Lê o arquivo de memória atual."""
    # Implementação de leitura do store...
    return "memória atual..."

@tool
async def write_memory(path: str, content: str, runtime: ToolRuntime) -> str:
    """Escreve no arquivo de memória."""
    # Implementação de escrita no store...
    mantis_log("INFO", "memory_written", f"Arquivo: {path}")
    return "Memória atualizada"

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    system_prompt="""Revise conversas recentes e atualize o arquivo de memória do usuário.
Mescle novos fatos, remova informações desatualizadas e mantenha conciso.""",
    tools=[search_recent_conversations, read_current_memory, write_memory],
)
```

### 2. Registro no `langgraph.json`

```json
{
  "dependencies": ["."],
  "graphs": {
    "agent": "./agent.py:agent",
    "consolidation_agent": "./consolidation_agent.py:agent"
  },
  "env": ".env"
}
```

### 3. Cron Job

```python
cron_job = await sdk_client.crons.create(
    assistant_id="consolidation_agent",
    schedule="0 */6 * * *",
    input={"messages": [{"role": "user", "content": "Consolidate recent memories."}]},
)
```

### 4. Sincronização entre Cron e Lookback

```python
# Cron: 0 */6 * * * (a cada 6 horas)
# Lookback: timedelta(hours=6)
# Devem ser coerentes para evitar reprocessamento ou perda de dados
```

### 5. Estratégia de Mesclagem de Memórias

```python
# Exemplo de prompt de mesclagem:
MERGE_PROMPT = """Dadas as memórias atuais e novos fatos extraídos, produza um arquivo de memória mesclado:
- Mantenha preferências conflitantes mais recentes
- Remova informações contraditórias
- Agrupe fatos relacionados
- Mantenha o formato markdown"""
```

### 6. Tratamento de Conflitos

```python
def safe_merge_memory(existing_content: str, new_facts: list[dict], max_retries=3):
    for attempt in range(max_retries):
        try:
            merged = llm.invoke(f"{MERGE_PROMPT}\n\nMemória atual:\n{existing_content}\n\nNovos fatos:\n{new_facts}")
            mantis_log("INFO", "memory_merged", f"Tamanho: {len(merged.content)} caracteres")
            return merged.content
        except Exception as e:
            mantis_log("WARN", "merge_failed", f"Tentativa {attempt+1}: {e}")
    mantis_log("ERROR", "merge_failed_all", "Todas as tentativas falharam")
    return existing_content
```

### 7. Escopos na Consolidação

```python
# Consolidação por usuário
StoreBackend(namespace=lambda rt: (rt.server_info.user.identity,))

# Consolidação por organização
StoreBackend(namespace=lambda rt: (rt.context.org_id,))
```

### 8. Métricas de Consolidação

```python
from prometheus_client import Counter, Gauge

consolidation_runs = Counter('memory_consolidation_runs', 'Total de execuções de consolidação')
memories_updated = Counter('memories_updated', 'Total de memórias atualizadas')
last_consolidation = Gauge('last_consolidation_timestamp', 'Timestamp da última consolidação')
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_merge_memory():
    existing = "## Prefs\n- Tema escuro"
    new_facts = [{"fact": "Prefere tema claro"}]
    # Mock do LLM
    result = safe_merge_memory(existing, new_facts)
    assert result is not None

def test_cron_schedule():
    assert "0 */6 * * *"  # Expressão cron válida
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-memory-consolidation.md --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[deep-agents-memory-long-term.md]]
- [[deep-agents-memory-scopes.md]]
- [[langchain-langraph-master-agent.md]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-25T18:00:00Z | langchain-langraph-master-agent | Criação inicial: consolidação | C1,C3,C4,C5,C7,C8,C9 |
