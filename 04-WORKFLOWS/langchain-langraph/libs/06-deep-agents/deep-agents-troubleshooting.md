---
artifact_id: "deep-agents-troubleshooting"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-troubleshooting.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-troubleshooting.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-troubleshooting-v1.0.0"
generated_at: "2026-05-26T00:45:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-core-customization"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# 🐛 Deep Agents – Troubleshooting e Diagnóstico

> **Contrato modular**: Artefato filho do Master Agent. Guia de diagnóstico e resolução dos problemas mais comuns em Deep Agents, com exemplos de sintomas, causas e soluções.

---

## 🎯 Propósito
Permitir que operadores MANTIS identifiquem e resolvam rapidamente problemas em agentes Deep Agents, minimizando tempo de inatividade.

## 📋 Especificação (SDD)
- **Entradas**: Sintomas observados, logs, traces.
- **Saídas**: Diagnóstico e solução.
- **Side Effects**: Nenhum.
- **Constraints Aplicáveis**: C1 (padrões de erro), C5 (mensagens claras), C7 (recuperação), C8 (logs), C9 (tracing).
- **Dependências**: `langsmith`, `langgraph`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Subagente Não Está Sendo Chamado

```python
# Sintoma: Agente principal faz o trabalho sozinho em vez de delegar.
# Solução 1: Descrição mais específica
subagent = {
    "name": "research-specialist",
    "description": "Conducts in-depth research on specific topics using web search. Use when you need detailed information that requires multiple searches.",
}

# Solução 2: Instruir o agente principal
agent = create_deep_agent(
    system_prompt="""IMPORTANTE: Para tarefas complexas, delegue aos seus subagentes usando task().
    Isso mantém seu contexto limpo e melhora os resultados.""",
    subagents=[...],
)
```

### 2. Contexto Inchando (Context Bloat)

```python
# Sintoma: Respostas cada vez mais lentas, erros de limite de tokens.
# Solução 1: Subagente retornar apenas resumo
system_prompt="""IMPORTANTE: Retorne apenas o resumo essencial.
NÃO inclua dados brutos, resultados intermediários ou saídas detalhadas.
Sua resposta deve ter menos de 500 palavras."""

# Solução 2: Usar filesystem para dados grandes
system_prompt="""Quando coletar grandes quantidades de dados:
1. Salve dados brutos em /workspace/raw_results.txt
2. Processe e analise os dados
3. Retorne apenas o resumo da análise"""
```

### 3. Subagente Errado Sendo Selecionado

```python
# Solução: Diferenciar descrições claramente
subagents = [
    {"name": "quick-researcher", "description": "For simple, quick research questions that need 1-2 searches."},
    {"name": "deep-researcher", "description": "For complex, in-depth research requiring multiple searches, synthesis, and analysis."},
]
```

### 4. Polling Imediato Após Launch (Async Subagents)

```python
# Sintoma: Supervisor chama check logo após launch.
# Solução: Reforçar no system prompt
system_prompt="""Após lançar um subagente assíncrono, SEMPRE retorne o controle ao usuário.
Nunca chame check_async_task imediatamente após o launch."""
```

### 5. Task ID Truncado

```python
# Sintoma: Supervisor encurta o task_id, causando falha no check/cancel.
# Solução: Instruir o modelo
system_prompt="""Sempre use o task_id completo, nunca trunque ou abrevie."""
```

### 6. Workers Insuficientes

```bash
# Sintoma: Launch de subagente demora muito.
# Solução: Aumentar pool
langgraph dev --n-jobs-per-worker 10
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_subagent_description():
    desc = "Conducts in-depth research on specific topics using web search."
    assert len(desc) > 20
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-troubleshooting.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-core-customization.md]]
