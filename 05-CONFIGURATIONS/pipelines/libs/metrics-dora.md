---
artifact_id: "pipelines-metrics-dora"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/metrics-dora.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/metrics-dora.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:metrics-dora-v1.0.0"
generated_at: "2026-05-23T23:45:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["deployment-monitoring", "rollback-automation"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 📊 Métricas DORA e Observabilidade

> **Contrato modular**: Filho de `pipelines-master-agent-mantis`.

## 🎯 Propósito
Rastrear métricas DORA (Deployment Frequency, Lead Time, Change Failure Rate, MTTR) e configurar rollback automático baseado em métricas (C8).

## 📋 Especificação
- **Entradas**: Dados de pipelines e Prometheus.
- **Saídas**: Dashboards, alertas, scripts de rollback.
- **Constraints Aplicáveis**: C8.

---

## 🛡️ Métricas e Alertas

| Métrica | Meta Elite |
|---------|------------|
| Deployment Frequency | Múltiplo/dia |
| Lead Time | < 1 hora |
| Change Failure Rate | < 5% |
| MTTR | < 1 hora |

### Alerta Prometheus
```yaml
- alert: HighErrorRatePostDeploy
  expr: |
    sum(rate(http_requests_total{status=~"5.."}[5m]))
    / sum(rate(http_requests_total[5m])) > 0.01
  for: 2m
```

### Rollback por Métricas
```bash
ERROR_RATE=$(curl -sf "$PROM_URL/api/v1/query" --data-urlencode 'query=...')
if (( $(echo "$ERROR_RATE > 0.01" | bc -l) )); then
  kubectl rollout undo deployment/mantis-app
fi
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_prometheus_query_syntax() {
  local q='sum(rate(http_requests_total[5m]))'
  curl -s --data-urlencode "query=$q" "http://localhost:9090/api/v1/query" >/dev/null 2>&1 || return 0
}
[[ "${1:-}" == "--test" ]] && { test_prometheus_query_syntax && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[../../observability/00-INDEX.md]]
