---
artifact_id: "pipelines-data-etl"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/data-etl-pipeline.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/data-etl-pipeline.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:data-etl-v1.0.0"
generated_at: "2026-05-24T01:10:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["etl-workflows", "n8n-data-pipelines"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📊 Pipeline de Dados ETL com n8n

> **Contrato modular**: Filho de `pipelines-master-agent-mantis`.

## 🎯 Propósito
Definir padrões de pipelines de dados usando n8n para extração, transformação e carga (ETL), com monitoramento de freshness e alertas (C8).

## 📋 Especificação
- **Entradas**: Fonte de dados, cron schedule.
- **Saídas**: Workflow n8n em JSON.
- **Constraints Aplicáveis**: C8 (qualidade de entrega).

---

## 🛡️ Padrão ETL

### Workflow n8n (JSON)
```json
{
  "name": "Daily Sales ETL",
  "nodes": [
    { "name": "Extract Shopify", "type": "n8n-nodes-base.shopify" },
    { "name": "Extract Stripe", "type": "n8n-nodes-base.stripe" },
    { "name": "Merge", "type": "n8n-nodes-base.merge" },
    { "name": "Transform", "type": "n8n-nodes-base.code" },
    { "name": "Load to BigQuery", "type": "n8n-nodes-base.googleBigQuery" }
  ],
  "triggers": [{
    "type": "n8n-nodes-base.scheduleTrigger",
    "parameters": { "rule": { "interval": [{ "field": "cronExpression", "expression": "0 2 * * *" }] } }
  }]
}
```

### Monitoramento de Freshness
```sql
SELECT COUNT(*) as row_count, MAX(date) as last_date
FROM analytics.sales_daily
WHERE date >= CURRENT_DATE - INTERVAL '2 days'
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_etl_schedule_cron_valid() {
  echo "0 2 * * *" | grep -qE '^[0-9*,/ -]+$' && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_etl_schedule_cron_valid && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[../metrics-dora.md]]
