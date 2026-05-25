---
artifact_id: "deep-agents-permissions"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-permissions.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-permissions.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-permissions-v1.0.0"
generated_at: "2026-05-25T15:15:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-backends-composite", "deep-agents-memory-long-term"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔐 Deep Agents – Permissões Declarativas de Acesso a Arquivos

> **Contrato modular**: Artefato filho do Master Agent. Define e exemplifica o sistema de permissões `FilesystemPermission` para controlar leitura/escrita em paths, com ordenação de regras, herança em subagentes e integração com backends compostos.

---

## 🎯 Propósito
Garantir que agentes MANTIS respeitem políticas de acesso a arquivos, protegendo dados sensíveis e isolando tenants, usando regras declarativas allow/deny.

## 📋 Especificação (SDD)
- **Entradas**: Lista de `FilesystemPermission`, backend.
- **Saídas**: Acesso controlado às ferramentas de arquivo.
- **Side Effects**: Bloqueio de operações não autorizadas.
- **Constraints Aplicáveis**: C1 (schema de regras), C3 (proteção de dados), C4 (isolamento multi‑tenant), C5 (avaliação determinística), C7 (negação segura), C8 (logs de violações).
- **Dependências**: `deepagents>=0.5.2`.

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

### 1. Regra Básica: Bloquear Todas as Escritas

```python
from deepagents import FilesystemPermission, create_deep_agent

agent = create_deep_agent(
    model="openai:gpt-5.4",
    backend=backend,
    permissions=[
        FilesystemPermission(
            operations=["write"],
            paths=["/**"],
            mode="deny",
        ),
    ],
)
mantis_log("INFO", "permissions", "Agente somente leitura configurado")
```

### 2. Isolar para um Diretório de Trabalho

```python
permissions=[
    FilesystemPermission(operations=["read", "write"], paths=["/workspace/**"], mode="allow"),
    FilesystemPermission(operations=["read", "write"], paths=["/**"], mode="deny"),
]
```

### 3. Proteger Arquivos Específicos

```python
permissions=[
    FilesystemPermission(operations=["read", "write"], paths=["/workspace/.env", "/workspace/secrets/**"], mode="deny"),
    FilesystemPermission(operations=["read", "write"], paths=["/workspace/**"], mode="allow"),
    FilesystemPermission(operations=["read", "write"], paths=["/**"], mode="deny"),
]
```

### 4. Ordem das Regras (First‑Match‑Wins)

```python
# ✅ CORRETO: regra mais específica primeiro
correct = [
    FilesystemPermission(operations=["read", "write"], paths=["/workspace/.env"], mode="deny"),
    FilesystemPermission(operations=["read", "write"], paths=["/workspace/**"], mode="allow"),
    FilesystemPermission(operations=["read", "write"], paths=["/**"], mode="deny"),
]

# ❌ INCORRETO: regra genérica primeiro, a específica nunca é alcançada
incorrect = [
    FilesystemPermission(operations=["read", "write"], paths=["/workspace/**"], mode="allow"),
    FilesystemPermission(operations=["read", "write"], paths=["/workspace/.env"], mode="deny"),  # nunca executada
    FilesystemPermission(operations=["read", "write"], paths=["/**"], mode="deny"),
]
```

### 5. Permissões em Subagentes

```python
agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    permissions=[
        FilesystemPermission(operations=["read", "write"], paths=["/workspace/**"], mode="allow"),
        FilesystemPermission(operations=["read", "write"], paths=["/**"], mode="deny"),
    ],
    subagents=[
        {
            "name": "auditor",
            "description": "Revisor de código somente leitura",
            "system_prompt": "Revise o código em busca de problemas.",
            "permissions": [  # Substitui as permissões do pai
                FilesystemPermission(operations=["write"], paths=["/**"], mode="deny"),
                FilesystemPermission(operations=["read"], paths=["/workspace/**"], mode="allow"),
                FilesystemPermission(operations=["read"], paths=["/**"], mode="deny"),
            ],
        }
    ],
)
```

### 6. Permissões com CompositeBackend e Sandbox

```python
from deepagents.backends import CompositeBackend

composite = CompositeBackend(
    default=sandbox,
    routes={"/memories/": memories_backend},
)

# Funciona: permissões scoped à rota /memories/
agent = create_deep_agent(
    model="anthropic:claude-sonnet-4-6",
    backend=composite,
    permissions=[
        FilesystemPermission(operations=["write"], paths=["/memories/**"], mode="deny"),
    ],
)

# NÃO funciona: /workspace/** atinge o default (sandbox)
# Levantaria NotImplementedError
```

### 7. Estrutura da Regra

```python
# Cada FilesystemPermission tem:
# - operations: list["read" | "write"]
# - paths: list[str] (glob patterns, ex: "/workspace/**", suporta {a,b})
# - mode: "allow" | "deny"
```

### 8. Permissões vs Policy Hooks

```python
# Permissões: controle declarativo baseado em paths.
# Policy Hooks: validação customizada (rate limiting, auditoria, inspeção de conteúdo).

# Use permissões para regras simples de acesso.
# Use hooks quando precisar de lógica complexa ou acesso a ferramentas customizadas.
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_permission_rule_structure():
    rule = FilesystemPermission(operations=["read"], paths=["/test/**"], mode="allow")
    assert rule.operations == ["read"]
    assert rule.paths == ["/test/**"]
    assert rule.mode == "allow"

def test_deny_all_writes():
    rule = FilesystemPermission(operations=["write"], paths=["/**"], mode="deny")
    assert rule.mode == "deny"
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-permissions.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-backends-composite.md]]
- [[deep-agents-memory-long-term.md]]
