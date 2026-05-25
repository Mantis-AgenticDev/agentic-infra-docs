---
artifact_id: "configurations-observability-standards"
artifact_type: "governance_pattern"
version: "1.0.0"
constraints_mapped: ["C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/configurations/libs/observability-standards.md --json"
canonical_path: "05-CONFIGURATIONS/configurations/libs/observability-standards.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:obs-standards-v1.0.0"
generated_at: "2026-05-24T08:20:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "configurations"
ai_navigation:
  read_first: false
  required_for: ["observability-setup", "dashboard-configuration"]
  update_frequency: on-change
audience: ["configurations-ceo", "all-master-agents"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📊 Padrões de Observabilidade

> **Contrato modular**: Filho de `configurations-ceo-mantis`. Complementa [[../../docker-compose/libs/logging-observability.md]].

## 🎯 Propósito
Definir as métricas obrigatórias, dashboards e regras de alerta para todo o ecossistema MANTIS (C8).

## 📋 Especificação
- **Entradas**: Tipo de serviço (HTTP, DB, queue).
- **Saídas**: Configuração de métricas, dashboard JSON, regra de alerta.
- **Constraints Aplicáveis**: C8 (qualidade de entrega).

---

## 🛡️ Métricas Obrigatórias por Serviço

| Métrica | Threshold de Alerta |
|---------|-------------------|
| `http_requests_total` | — |
| `http_request_duration_seconds` | p99 > 2s |
| `http_errors_total` | rate > 1% |
| `db_connections_active` | > 80% pool |
| `backup_last_success_timestamp` | > 24h |

### Health Endpoints
```yaml
services:
  backend-api:
    url: "http://localhost:4000/health/ready"
    expected: { status: 200 }
```

### Alertas Críticas
```yaml
- alert: HighErrorRate
  expr: sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) > 0.01
  for: 2m
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_alert_rule_has_runbook() {
    grep -q "runbook_url:" "$1" && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_alert_rule_has_runbook "../observability/alerts/critical-alerts.yml" 2>/dev/null && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[configurations-ceo.md]]
- [[../../observability/00-INDEX.md]]
- [[../../docker-compose/libs/logging-observability.md]]
