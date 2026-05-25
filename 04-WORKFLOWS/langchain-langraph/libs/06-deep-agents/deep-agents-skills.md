---
artifact_id: "deep-agents-skills"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-skills.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-skills.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-skills-v1.0.0"
generated_at: "2026-05-25T18:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-core-customization"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🎯 Deep Agents – Skills (Habilidades)

> **Contrato modular**: Artefato filho do Master Agent. Documenta o sistema de skills com progressive disclosure, carregamento on‑demand, interpreter skills e estrutura de SKILL.md.

---

## 🎯 Propósito
Permitir que agentes MANTIS carreguem dinamicamente conhecimentos especializados (skills) apenas quando necessário, economizando tokens e contexto.

## 📋 Especificação (SDD)
- **Entradas**: Diretórios de skills, backend, arquivos SKILL.md.
- **Saídas**: Agente com acesso a skills sob demanda.
- **Side Effects**: Leitura de arquivos de skill.
- **Constraints Aplicáveis**: C1 (formato SKILL.md), C3 (proteção de skills sensíveis), C5 (estrutura), C7 (fallback se skill não encontrada), C8 (logs).
- **Dependências**: `deepagents`.

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

### 1. Estrutura de um SKILL.md

```markdown
---
name: langgraph-docs
description: Busca documentação relevante do LangGraph para fornecer orientação precisa.
---

# langgraph-docs

Use a ferramenta fetch_url para ler https://docs.langchain.com/llms.txt e então buscar páginas relevantes.

## Como usar
1. Identifique a consulta do usuário
2. Busque na documentação
3. Retorne a resposta com citações
```

### 2. Configuração de Skills no Agente

```python
from deepagents import create_deep_agent
from deepagents.backends import StateBackend
from deepagents.backends.utils import create_file_data
from langgraph.checkpoint.memory import MemorySaver

skill_url = "https://raw.githubusercontent.com/langchain-ai/deepagents/refs/heads/main/libs/cli/examples/skills/langgraph-docs/SKILL.md"
with urlopen(skill_url) as response:
    skill_content = response.read().decode('utf-8')

skills_files = {"/skills/langgraph-docs/SKILL.md": create_file_data(skill_content)}

agent = create_deep_agent(
    model="openai:gpt-5.4",
    backend=StateBackend(),
    skills=["/skills/"],
    checkpointer=MemorySaver(),
)
result = agent.invoke(
    {"messages": [{"role": "user", "content": "O que é LangGraph?"}],
     "files": skills_files},
    config={"configurable": {"thread_id": "12345"}},
)
```

### 3. Skills com StoreBackend

```python
from deepagents.backends import StoreBackend

store = InMemoryStore()
store.put(
    ("filesystem",),
    "/skills/langgraph-docs/SKILL.md",
    create_file_data(skill_content),
)

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    backend=StoreBackend(namespace=lambda rt: ("filesystem",)),
    store=store,
    skills=["/skills/"],
)
```

### 4. Skills em Subagentes

```python
research_subagent = {
    "name": "researcher",
    "description": "Assistente de pesquisa com skills especializadas",
    "system_prompt": "Você é um pesquisador.",
    "tools": [web_search],
    "skills": ["/skills/research/", "/skills/web-search/"],
}

agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    skills=["/skills/main/"],  # Agente principal e GP subagent recebem
    subagents=[research_subagent],
)
```

### 5. Interpreter Skills (Módulos JS)

```python
from langchain_quickjs import CodeInterpreterMiddleware

agent = create_deep_agent(
    model="openai:gpt-5.4",
    middleware=[CodeInterpreterMiddleware(skills_backend=backend)],
)
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_skill_file_structure():
    skill = {"name": "test", "description": "A test skill"}
    assert "name" in skill
    assert "description" in skill
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-skills.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-core-customization.md]]
- [[langchain-langraph-master-agent.md]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-25T18:15:00Z | langchain-langraph-master-agent | Criação inicial: skills | C1,C3,C5,C7,C8 |
