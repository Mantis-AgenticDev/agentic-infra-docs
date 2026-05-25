---
artifact_id: "deep-agents-interpreters-core"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-interpreters-core.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-interpreters-core.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-interpreters-v1.0.0"
generated_at: "2026-05-25T15:45:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-interpreters-advanced", "deep-agents-core-customization"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# ⚡ Deep Agents – Intérpretes (Code Interpreter com QuickJS)

> **Contrato modular**: Artefato filho do Master Agent. Documenta o uso de `CodeInterpreterMiddleware` para executar JavaScript/TypeScript em QuickJS, com programmatic tool calling, snapshots e time travel.

---

## 🎯 Propósito
Dar aos agentes MANTIS um ambiente de execução de código isolado para compor ferramentas, orquestrar subagentes e processar dados estruturados sem poluir o contexto do modelo.

## 📋 Especificação (SDD)
- **Entradas**: Middleware `CodeInterpreterMiddleware`, allowlist PTC, backend de skills.
- **Saídas**: Ferramenta `eval` disponível para o agente.
- **Side Effects**: Execução de código JavaScript.
- **Constraints Aplicáveis**: C1 (timeout e limites), C3 (isolamento de runtime), C5 (schema de entrada/saída), C7 (tratamento de erros de runtime), C8 (logs de execução).
- **Dependências**: `langchain-quickjs>=0.1.0`, Python >=3.11.

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

### 1. Adicionar Interpretador ao Agente

```python
from deepagents import create_deep_agent
from langchain_quickjs import CodeInterpreterMiddleware

agent = create_deep_agent(
    model="openai:gpt-5.4",
    middleware=[CodeInterpreterMiddleware()],
)
```

### 2. Código Executado pelo Agente (via `eval`)

```javascript
const rows = [
  { team: "alpha", score: 8 },
  { team: "beta", score: 13 },
  { team: "alpha", score: 21 },
];

const totals = rows.reduce((acc, row) => {
  acc[row.team] = (acc[row.team] ?? 0) + row.score;
  console.log(`${row.team} score: ${acc[row.team]}`);
  return acc;
}, {});

totals;
```

### 3. Programmatic Tool Calling (PTC)

```python
agent = create_deep_agent(
    model="openai:gpt-5.4",
    middleware=[CodeInterpreterMiddleware(ptc=["task"])],
)
```

```javascript
// O agente pode chamar subagentes programaticamente:
const topics = ["retrieval", "memory", "evaluation"];
const reports = await Promise.all(
  topics.map((topic) =>
    tools.task({
      description: `Research ${topic} in Deep Agents and return three concise findings.`,
      subagent_type: "general-purpose",
    }),
  ),
);
reports.join("\n\n");
```

### 4. Chamada com Tratamento de Erro

```javascript
try {
  const report = await tools.task({
    description: "Check the migration notes and return breaking changes.",
    subagent_type: "general-purpose",
  });
  console.log(report);
} catch (error) {
  console.log(`Subagent failed: ${error.message}`);
}
```

### 5. Snapshots e Time Travel

```python
from langgraph.checkpoint.memory import MemorySaver

checkpointer = MemorySaver()
agent = create_deep_agent(
    model="openai:gpt-5.4",
    checkpointer=checkpointer,
    middleware=[CodeInterpreterMiddleware(snapshot_between_turns=True)],
)
```

### 6. Segurança e Limites

```python
CodeInterpreterMiddleware(
    memory_limit=64 * 1024 * 1024,  # 64 MB
    timeout=5.0,
    max_ptc_calls=256,
    max_result_chars=4000,
    capture_console=True,
    snapshot_between_turns=True,
)
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_interpreter_middleware():
    mw = CodeInterpreterMiddleware()
    assert mw is not None
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-interpreters-core.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-interpreters-advanced.md]]
- [[deep-agents-core-customization.md]]
