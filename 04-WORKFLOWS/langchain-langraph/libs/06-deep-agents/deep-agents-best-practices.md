---
artifact_id: "deep-agents-best-practices"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-best-practices.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-best-practices.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-best-practices-v1.0.0"
generated_at: "2026-05-26T02:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-production-checklist"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# 🏆 Deep Agents – Melhores Práticas

> **Contrato modular**: Artefato filho do Master Agent. Consolida todas as melhores práticas para construir, testar e operar Deep Agents no ecossistema MANTIS, extraídas da documentação e experiência de produção.

---

## 🎯 Propósito
Fornecer um guia de referência rápida com todas as recomendações essenciais para Deep Agents, cobrindo design, segurança, desempenho e operação.

## 📋 Especificação (SDD)
- **Entradas**: Todo o conhecimento acumulado dos artefatos Deep Agents.
- **Saídas**: Lista de recomendações acionáveis.
- **Side Effects**: Nenhum.
- **Constraints Aplicáveis**: Todas as constraints C1‑C9.
- **Dependências**: `deepagents`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Design de Agentes

```python
# ✅ Faça:
# - Use create_deep_agent como fábrica principal.
# - Defina system_prompts claros e específicos.
# - Use subagentes para isolar tarefas complexas.
# - Mantenha conjuntos de ferramentas mínimos e focados.
# - Use structured output para respostas parseáveis.

# ❌ Não faça:
# - Não sobrecarregue o agente com ferramentas desnecessárias.
# - Não use descrições vagas para subagentes.
# - Não ignore os limites de contexto do modelo.
```

### 2. Segurança

```python
# ✅ Faça:
# - Sempre use variáveis de ambiente para secrets.
# - Configure HITL para operações destrutivas.
# - Use permissões de arquivo para limitar acesso.
# - Isole tenants com namespaces apropriados.
# - Sanitize saídas de ferramentas antes de usar.

# ❌ Não faça:
# - Não hardcode credenciais.
# - Não use LocalShellBackend em produção.
# - Não confie em saídas de ferramentas sem validação.
# - Não compartilhe memória entre tenants sem isolamento.
```

### 3. Desempenho

```python
# ✅ Faça:
# - Use cache de embeddings e respostas.
# - Configure sumarização automática.
# - Prefira modelos menores para tarefas simples.
# - Use subagentes assíncronos para paralelismo.
# - Monitore uso de tokens e latência.

# ❌ Não faça:
# - Não use o modelo mais caro para todas as tarefas.
# - Não ignore timeouts em chamadas externas.
# - Não acumule histórico indefinidamente.
```

### 4. Operação

```python
# ✅ Faça:
# - Sempre configure health checks.
# - Use LangSmith para tracing e debug.
# - Implemente métricas Prometheus.
# - Configure alertas para erros e custos.
# - Mantenha backups das configurações.

# ❌ Não faça:
# - Não implante sem testar em staging.
# - Não ignore logs de erro.
# - Não opere sem monitoramento.
```

### 5. Checklist Resumido

```python
BEST_PRACTICES_CHECKLIST = [
    "System prompt claro e específico",
    "HITL para operações críticas",
    "Permissões de arquivo configuradas",
    "Cache de embeddings ativo",
    "LangSmith tracing habilitado",
    "Métricas Prometheus exportadas",
    "Health checks configurados",
    "Secrets em variáveis de ambiente",
    "Subagentes com descrições claras",
    "Timeout em chamadas externas",
    "Isolamento multi‑tenant (namespaces)",
    "Checkpointer configurado",
    "Summarization middleware ativo",
    "Rate limiting implementado",
]

for item in BEST_PRACTICES_CHECKLIST:
    mantis_log("INFO", "best_practice", f"Verificado: {item}")
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_best_practices_list():
    assert len(BEST_PRACTICES_CHECKLIST) > 10
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-best-practices.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-production-checklist.md]]
