---
artifact_id: "deep-agents-production-checklist"
artifact_type: "workflow_skill"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C7","C8","C9"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-production-checklist.md --json"
canonical_path: "04-WORKFLOWS/langchain-langraph/libs/deep-agents-production-checklist.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deep-agents-checklist-v1.0.0"
generated_at: "2026-05-26T00:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "langchain-langraph"
ai_navigation:
  read_first: false
  required_for: ["deep-agents-deployment-production"]
  update_frequency: on-change
audience: ["langchain-langraph-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-26"
---

# ✅ Deep Agents – Checklist de Produção

> **Contrato modular**: Artefato filho do Master Agent. Lista exaustiva de verificações para colocar um Deep Agent em produção com segurança, desempenho e observabilidade.

---

## 🎯 Propósito
Garantir que agentes MANTIS estejam prontos para produção, cobrindo todos os aspectos de segurança, resiliência, monitoramento e custos.

## 📋 Especificação (SDD)
- **Entradas**: Configuração do agente, ambiente de deploy.
- **Saídas**: Checklist validado.
- **Side Effects**: Nenhum.
- **Constraints Aplicáveis**: C1 (contratos), C2 (versionamento), C3 (segurança), C4 (multi‑tenant), C5 (configuração), C7 (resiliência), C8 (observabilidade), C9 (tracing).
- **Dependências**: `deepagents`, `langsmith`.

---

## 🛡️ Bootstrap Resiliente + Lógica de Domínio (C3+C8)
```python
try:
    from mantis_master import mantis_log
except ImportError:
    # ...
```

### 1. Checklist de Segurança

```python
SECURITY_CHECKS = [
    ("API keys em variáveis de ambiente", lambda: all(k in os.environ for k in ["OPENAI_API_KEY"])),
    ("Sem hardcoding de secrets", lambda: "sk-" not in open(__file__).read()),
    ("Permissões de arquivo configuradas", lambda: hasattr(agent, 'permissions')),
    ("HITL para operações críticas", lambda: hasattr(agent, 'interrupt_on')),
    ("Sanitização de saídas ativada", lambda: sanitize_tool_output is not None),
    ("Rate limiting configurado", lambda: limiter is not None),
    ("Isolamento multi‑tenant (namespace)", lambda: "user.identity" in str(backend_config)),
]

def run_security_checks():
    for name, check in SECURITY_CHECKS:
        try:
            assert check(), f"Falhou: {name}"
            mantis_log("INFO", "security_check_pass", name)
        except AssertionError as e:
            mantis_log("ERROR", "security_check_fail", str(e))
```

### 2. Checklist de Resiliência

```python
RESILIENCE_CHECKS = [
    ("Checkpointer configurado", lambda: agent.checkpointer is not None),
    ("Retry em ferramentas de rede", lambda: has_retry_decorator(agent)),
    ("Timeout em chamadas externas", lambda: has_timeout_config(agent)),
    ("Fallback para modelos alternativos", lambda: has_fallback_model(agent)),
    ("Circuit breaker em DB", lambda: has_circuit_breaker(agent)),
]

def run_resilience_checks():
    for name, check in RESILIENCE_CHECKS:
        try:
            assert check(), f"Falhou: {name}"
            mantis_log("INFO", "resilience_check_pass", name)
        except AssertionError as e:
            mantis_log("ERROR", "resilience_check_fail", str(e))
```

### 3. Checklist de Observabilidade

```python
OBSERVABILITY_CHECKS = [
    ("LangSmith tracing ativo", lambda: os.getenv("LANGCHAIN_TRACING_V2") == "true"),
    ("Métricas Prometheus exportadas", lambda: has_prometheus_metrics()),
    ("Logs estruturados (V‑LOG‑02)", lambda: has_jsonl_logs()),
    ("Alertas configurados", lambda: has_alerts()),
    ("Dashboard Grafana provisionado", lambda: has_dashboard()),
]
```

### 4. Checklist de Deploy

```python
DEPLOY_CHECKS = [
    ("langgraph.json válido", lambda: os.path.exists("langgraph.json")),
    ("Variáveis de ambiente documentadas", lambda: os.path.exists(".env.example")),
    ("Store injetado pela plataforma", lambda: "STORE" in os.environ or has_local_store()),
    ("Cron jobs configurados", lambda: has_cron_jobs()),
    ("Workers dimensionados", lambda: "--n-jobs-per-worker" in os.getenv("LANGGRAPH_ARGS", "")),
]
```

### 5. Checklist de Custo

```python
COST_CHECKS = [
    ("Cache de embeddings ativo", lambda: has_embedding_cache()),
    ("Summarization configurado", lambda: has_summarization_middleware()),
    ("Skills para reduzir contexto", lambda: len(agent.skills) > 0),
    ("Modelo proporcional à tarefa", lambda: has_model_tier_strategy()),
    ("Limite de tokens por sessão", lambda: has_token_limit()),
]
```

---

## 🧪 Testes Unitários (TDD)

```python
def test_security_checks():
    for name, check in SECURITY_CHECKS:
        assert callable(check)
```

---

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 04-WORKFLOWS/langchain-langraph/libs/deep-agents-production-checklist.md --json
```

---

## 🔗 Referências Cruzadas
- [[deep-agents-deployment-production.md]]
- [[deep-agents-security-best-practices.md]]
