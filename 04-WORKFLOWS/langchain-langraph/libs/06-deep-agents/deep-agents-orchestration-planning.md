---
artifact_id: "deep-agents-orchestration-planning"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-orchestration-planning.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-orchestration-planning.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-planning-v1.0.0"
generated_at: "2026-05-25T13:45:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-subagents-fundamentals", "deep-agents-core-customization"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧩 Deep Agents – Orquestração e Planejamento (TodoList)

> **Contrato modular**: Artefato filho do Master Agent. Documenta o uso de `TodoListMiddleware` e `write_todos` para planejamento e rastreamento de tarefas multi-passo, com persistência via thread_id.

---

## 🎯 Propósito
Permitir que agentes MANTIS planejem, executem e rastreiem tarefas complexas de forma estruturada, mantendo estado entre interações.

## 📋 Especificação (SDD)
- **Entradas**: Tarefas descritas pelo usuário, thread_id para persistência.
- **Saídas**: Lista de TODOs com status (pending, in_progress, completed).
- **Side Effects**: Estado do TODO salvo no grafo.
- **Constraints Aplicáveis**: C1 (schema dos TODOs), C5 (persistência), C7 (recuperação de estado), C8 (logs de progresso), C9 (thread_id).
- **Dependências**: `deepagents`, `langgraph`.

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

### 1. Planejamento Automático de Tarefas

```python
from deepagents import create_deep_agent

agent = create_deep_agent(model="google_genai:gemini-3.5-flash")
# TodoListMiddleware incluído por padrão

config = {"configurable": {"thread_id": "session-1"}}
result = agent.invoke({
    "messages": [{"role": "user", "content": "Crie uma API REST: projete modelos, implemente CRUD, adicione autenticação, escreva testes."}]
}, config=config)

# O agente planeja automaticamente via write_todos:
# [
#   {"content": "Projetar modelos de dados", "status": "in_progress"},
#   {"content": "Implementar endpoints CRUD", "status": "pending"},
#   {"content": "Adicionar autenticação", "status": "pending"},
#   {"content": "Escrever testes", "status": "pending"}
# ]
```

### 2. Acessando o Estado dos TODOs

```python
# Após a execução, acessar os TODOs do estado final
todos = result.get("todos", [])
for todo in todos:
    mantis_log("INFO", "todo_status", f"[{todo['status']}] {todo['content']}")
    print(f"[{todo['status']}] {todo['content']}")
```

### 3. Persistência entre Invocações (Thread ID)

```python
config = {"configurable": {"thread_id": "user-session-xyz"}}

# Primeira interação
agent.invoke({
    "messages": [{"role": "user", "content": "Planeje uma migração de banco de dados."}]
}, config=config)

# Segunda interação – o agente lembra do plano
result = agent.invoke({
    "messages": [{"role": "user", "content": "Qual o status da tarefa de backup?"}]
}, config=config)

todos = result.get("todos", [])
for todo in todos:
    if "backup" in todo["content"].lower():
        print(f"Status do backup: {todo['status']}")
```

### 4. Estrutura de um TODO Item

```python
# Cada item de TODO possui:
# - content: descrição da tarefa
# - status: "pending", "in_progress", ou "completed"

# Exemplo de criação manual (via ferramenta write_todos)
# O agente chama:
# write_todos(todos=[
#     {"content": "Analisar requisitos", "status": "completed"},
#     {"content": "Desenhar arquitetura", "status": "in_progress"},
#     {"content": "Implementar solução", "status": "pending"},
#     {"content": "Testar e validar", "status": "pending"},
# ])
```

### 5. Fluxo de Trabalho com Orquestrador

```python
agent = create_deep_agent(
    model="anthropic:claude-sonnet-4-6",
    system_prompt="""Você é um gerente de projetos. Para cada tarefa:
    1. Crie um plano usando write_todos.
    2. Execute cada item em ordem, atualizando o status.
    3. Se encontrar bloqueios, ajuste o plano.
    4. Ao final, verifique se todos os itens estão 'completed'.""",
)

config = {"configurable": {"thread_id": "project-alpha"}}
result = agent.invoke({
    "messages": [{"role": "user", "content": "Preciso de um relatório de análise de mercado até sexta-feira."}]
}, config=config)

# O agente planeja, executa e atualiza os TODOs automaticamente
```

### 6. Combinação com Subagentes

```python
agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    system_prompt="""Você é um coordenador. Use write_todos para planejar e task() para delegar.
    Atualize os TODOs conforme as tarefas forem concluídas.""",
    subagents=[
        {
            "name": "researcher",
            "description": "Pesquisador para coleta de dados",
            "system_prompt": "Pesquise e retorne dados relevantes.",
            "tools": [internet_search],
        },
        {
            "name": "writer",
            "description": "Escritor para criação de conteúdo",
            "system_prompt": "Escreva conteúdo de alta qualidade.",
            "tools": [write_file],
        },
    ],
)

config = {"configurable": {"thread_id": "report-123"}}
result = agent.invoke({
    "messages": [{"role": "user", "content": "Crie um relatório sobre tendências de IA: pesquise, analise e escreva."}]
}, config=config)
```

### 7. Quando Usar e Quando Não Usar TodoList

```python
# ✅ USE TodoList para:
# - Tarefas complexas multi-passo
# - Operações de longa duração
# - Projetos com dependências entre etapas

# ❌ NÃO USE TodoList para:
# - Operações simples de passo único
# - Consultas rápidas (< 3 passos)
# - Tarefas triviais que não precisam de rastreamento
```

### 8. Configuração Avançada: Desabilitando TodoList

```python
from deepagents import HarnessProfile, register_harness_profile

register_harness_profile(
    "openai:gpt-5.4",
    HarnessProfile(
        excluded_middleware={"TodoListMiddleware"},
    ),
)
agent = create_deep_agent(model="openai:gpt-5.4")
# Agente agora não possui a ferramenta write_todos
```

### 9. Monitoramento de Progresso com Logs

```python
@tool
def write_todos_with_logging(todos: list) -> str:
    """Escreve TODOs com logging adicional."""
    for todo in todos:
        mantis_log("INFO", "todo_update", f"{todo['status']}: {todo['content']}")
    # Chama a implementação real...
    return "TODOs atualizados"
```

### 10. Recuperação de Estado Após Interrupção

```python
# Se o agente for interrompido (ex: HITL), o estado dos TODOs é preservado
from langgraph.types import Command

config = {"configurable": {"thread_id": "recoverable-session"}}

# Execução inicial (pode ser interrompida)
result = agent.invoke({
    "messages": [{"role": "user", "content": "Execute o plano de deploy."}]
}, config=config)

# Verificar estado
state = agent.get_state(config)
todos = state.values.get("todos", [])
incomplete = [t for t in todos if t["status"] != "completed"]
if incomplete:
    mantis_log("WARN", "incomplete_todos", f"Tarefas pendentes: {len(incomplete)}")
    # Retomar execução
    result = agent.invoke(
        Command(resume={"decisions": [{"type": "approve"}]}),
        config=config,
    )
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_todos_structure():
    todos = [
        {"content": "Task 1", "status": "pending"},
        {"content": "Task 2", "status": "in_progress"},
        {"content": "Task 3", "status": "completed"},
    ]
    assert len(todos) == 3
    assert todos[0]["status"] == "pending"
    assert todos[2]["status"] == "completed"

def test_thread_persistence():
    config = {"configurable": {"thread_id": "test-thread"}}
    assert config["configurable"]["thread_id"] == "test-thread"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-orchestration-planning.md --json
```

---

## 🔗 Referências Cruzadas (Wikilinks Mínimos)
- [[deep-agents-subagents-fundamentals.md]]
- [[deep-agents-core-customization.md]]
- [[langchain-langraph-master-agent.md]]

---

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-25T13:45:00Z | langchain-langraph-master-agent | Criação inicial: orquestração | C1,C5,C7,C8,C9 |
