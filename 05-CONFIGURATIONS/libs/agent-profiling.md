---
artifact_id: "configurations-agent-profiling"
artifact_type: "governance_pattern"
version: "1.0.0"
constraints_mapped: ["C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/configurations/libs/agent-profiling.md --json"
canonical_path: "05-CONFIGURATIONS/configurations/libs/agent-profiling.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:agent-profiling-v1.0.0"
generated_at: "2026-05-24T08:40:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "configurations"
ai_navigation:
  read_first: false
  required_for: ["agent-performance", "parallelization-strategies"]
  update_frequency: on-change
audience: ["configurations-ceo"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📈 Perfilado de Rendimento de Agentes

> **Contrato modular**: Filho de `configurations-ceo-mantis`.

## 🎯 Propósito
Monitorar as métricas de rendimento dos agentes mestres (latência, cache hit ratio, consumo de tokens) e aplicar estratégias de paralelização para otimizar fluxos multi-agente (C8).

## 📋 Especificação
- **Entradas**: Logs de execução dos agentes.
- **Saídas**: Relatório de perfilado, sugestões de otimização.
- **Constraints Aplicáveis**: C8 (qualidade de entrega).

---

## 🛡️ Métricas de Rendimento

| Métrica | Threshold de Alerta | Ação Corretiva |
|---------|-------------------|----------------|
| `agent_response_latency_seconds` | p99 > 30s | Reduzir contexto, otimizar templates |
| `agent_cache_hit_ratio` | < 70% | Melhorar caching de artefatos |
| `agent_context_tokens` | > 80% da janela | Aplicar política de eviction |
| `agent_constraint_violations` | > 0 | Reforçar validação |

### Paralelização
Agentes sem dependências mútuas podem ser invocados simultaneamente:
```
Task(terraform-master-agent)  ← paralelo →
Task(docker-compose-master-agent)
         ↓ ponto de sincronização
Task(pipelines-master-agent)
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_latency_threshold() {
  local latency=25
  (( $(echo "$latency < 30" | bc -l) )) && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_latency_threshold && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[configurations-ceo.md]]
- [[../../pipelines/libs/performance-optimization.md]]
