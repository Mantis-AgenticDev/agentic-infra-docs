---
artifact_id: "deep-agents-migration-guide"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-migration-guide.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-migration-guide.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-migration-v1.0.0"
generated_at: "2026-05-25T22:15:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-deployment-production"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔄 Deep Agents – Guia de Migração e Compatibilidade

> **Contrato modular**: Artefato filho do Master Agent. Documenta as mudanças entre versões de Deep Agents (0.4.x → 0.5.x) e como migrar código legado, incluindo backends, namespaces e fábricas.

---

## 🎯 Propósito
Garantir que agentes MANTIS acompanhem as evoluções da biblioteca `deepagents` sem quebra de funcionalidade.

## 📋 Especificação (SDD)
- **Entradas**: Código legado com padrões deprecated.
- **Saídas**: Código atualizado para a versão mais recente.
- **Side Effects**: Nenhum.
- **Constraints Aplicáveis**: C1 (contratos), C2 (versionamento), C5 (estrutura), C7 (compatibilidade), C8 (logs).
- **Dependências**: `deepagents>=0.5.0`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Migração de Backend Factories

```python
# ANTES (deprecated)
agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    backend=lambda rt: StateBackend(rt),
)

# DEPOIS
agent = create_deep_agent(
    model="google_genai:gemini-3.5-flash",
    backend=StateBackend(),
)
```

### 2. Migração de StoreBackend

```python
# ANTES
StoreBackend(rt, namespace=lambda rt: (rt.server_info.user.identity,))

# DEPOIS
StoreBackend(namespace=lambda rt: (rt.server_info.user.identity,))
```

### 3. Migração de BackendContext

```python
# ANTES
namespace=lambda ctx: (ctx.runtime.context.user_id,)

# DEPOIS
namespace=lambda rt: (rt.server_info.user.identity,)
```

### 4. Mudanças no Prompt Assembly

```python
# O system_prompt agora é montado em camadas: USER → BASE/CUSTOM → SUFFIX
# Perfis Anthropic e OpenAI adicionam automaticamente um SUFFIX.
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_migration_pattern():
    # Simples verificação de que o novo padrão funciona
    backend = StateBackend()
    assert backend is not None
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-migration-guide.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-core-customization.md]]
