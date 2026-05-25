---
artifact_id: "deep-agents-interpreters-advanced"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-interpreters-advanced.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-interpreters-advanced.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-interpreters-adv-v1.0.0"
generated_at: "2026-05-25T17:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-interpreters-core"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# ⚡ Deep Agents – Intérpretes Avançados (PTC, Recursive Models e Skills)

> **Contrato modular**: Artefato filho do Master Agent. Aprofunda o uso de intérpretes com Programmatic Tool Calling, recursive language models, interpreter skills e configurações de segurança.

---

## 🎯 Propósito
Elevar o uso de intérpretes para orquestração complexa de ferramentas, processamento de dados em larga escala e execução de código reutilizável.

## 📋 Especificação (SDD)
- **Entradas**: Middleware com allowlist PTC, skills de interpretador.
- **Saídas**: Agente capaz de compor ferramentas via código.
- **Side Effects**: Chamadas de ferramentas programáticas.
- **Constraints Aplicáveis**: C1 (limites de PTC), C3 (isolamento), C5 (schema), C7 (timeout), C8 (logs).
- **Dependências**: `langchain-quickjs>=0.1.0`.

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

### 1. Habilitar PTC com Várias Ferramentas

```python
agent = create_deep_agent(
    model="openai:gpt-5.4",
    tools=[web_search, database_query, email_sender],
    middleware=[CodeInterpreterMiddleware(ptc=["web_search", "database_query", "task"])],
)
```

### 2. Processamento Paralelo com Promise.all

```javascript
const queries = ["Q1", "Q2", "Q3"];
const results = await Promise.all(
  queries.map(q => tools.web_search({query: q, max_results: 3}))
);
results.join("\n---\n");
```

### 3. Lógica Condicional no Interpretador

```javascript
const data = await tools.database_query({query: "SELECT * FROM sales"});
if (data.rows.length > 1000) {
  console.log("Dataset grande, aplicando agregação...");
  // agregação em JavaScript
}
```

### 4. Recursive Language Models (Decomposição)

```javascript
const candidates = notes.filter(note => note.includes("migration")).slice(0, 5);
const riskReports = await Promise.all(
  candidates.map(note =>
    tools.task({
      description: `Analyze this migration note for release risk: ${note}`,
      subagent_type: "general-purpose",
    }),
  ),
);
const summary = riskReports.map((report, i) => `## Candidate ${i+1}\n${report}`).join("\n\n");
summary;
```

### 5. Interpreter Skills (Módulos Reutilizáveis)

```python
# Habilita skills no interpretador
agent = create_deep_agent(
    model="openai:gpt-5.4",
    middleware=[CodeInterpreterMiddleware(skills_backend=backend)],
)
```

```javascript
// Importa um módulo de skill
import { sortBy, groupBy } from "./skills/data-utils";
const grouped = groupBy(rows, "team");
```

### 6. Configuração Completa de Segurança

```python
CodeInterpreterMiddleware(
    memory_limit=128 * 1024 * 1024,  # 128 MB
    timeout=10.0,
    max_ptc_calls=500,
    max_result_chars=8000,
    capture_console=True,
    snapshot_between_turns=True,
    max_snapshot_bytes=10 * 1024 * 1024,  # 10 MB
)
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_ptc_allowlist():
    mw = CodeInterpreterMiddleware(ptc=["task", "web_search"])
    assert "task" in mw.ptc
    assert "web_search" in mw.ptc
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-interpreters-advanced.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-interpreters-core.md]]
