---
artifact_id: "pipelines-deployment-strategies"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/deployment-strategies.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/deployment-strategies.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deploy-strategies-v1.0.0"
generated_at: "2026-05-23T23:10:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["deployment-configuration", "zero-downtime-deploy"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 🚀 Estratégias de Despliegue

> **Contrato modular**: Filho de `pipelines-master-agent-mantis`. Complementa [[../../docker-compose/libs/deployment-strategies.md]] com padrões Kubernetes e Argo Rollouts.

## 🎯 Propósito
Definir padrões de despliegue sem downtime: rolling updates, blue-green, canary com Argo Rollouts e feature flags, aplicando C6 (aprovação), C7 (rollback) e C8 (health checks).

## 📋 Especificação
- **Entradas**: Estratégia desejada, tipo de orquestrador (Kubernetes, Compose, ECS).
- **Saídas**: Configuração YAML de deploy + análise de métricas.
- **Constraints Aplicáveis**: C6, C7, C8.

---

## 🛡️ Padrões

### Rolling Update (Kubernetes)
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 2
    maxUnavailable: 1
```

### Blue-Green (Script)
```bash
kubectl apply -f k8s/$ENVIRONMENT/
kubectl rollout status deployment/mantis-app --timeout=10m
# Smoke tests, depois switch de tráfego
```

### Canary com Argo Rollouts
```yaml
strategy:
  canary:
    steps:
      - setWeight: 10
      - pause: { duration: 5m }
      - setWeight: 100
    analysis:
      templates:
        - templateName: success-rate
```

### Feature Flags (Flagsmith)
```python
if is_feature_enabled("new_flow", user_id):
    return process_v2()
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_canary_analysis_template() {
  local tmp; tmp=$(mktemp -d)
  cat > "$tmp/analysis.yaml" << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: test
spec:
  metrics:
  - name: success-rate
    interval: 60s
    successCondition: "result[0] >= 0.95"
EOF
  python3 -c "import yaml; yaml.safe_load(open('$tmp/analysis.yaml'))" && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_canary_analysis_template && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[../../docker-compose/libs/deployment-strategies.md]] — Estratégias base para Compose
- [[../../docker-compose/libs/healthcheck-patterns.md]] — Health checks para gates
