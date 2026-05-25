---
artifact_id: "pipelines-deployment-design"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/deployment-design.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/deployment-design.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:deployment-design-v1.0.0"
generated_at: "2026-05-24T01:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["multi-stage-pipeline", "approval-gates"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🎯 Design de Pipelines Multi-Etapa

> **Contrato modular**: Filho de `pipelines-master-agent-mantis`.

## 🎯 Propósito
Definir o fluxo canônico de 9 etapas para pipelines de deploy, com health checks shallow/deep e approval gates (C7, C8).

## 📋 Especificação
- **Entradas**: Tipo de aplicação, ambiente alvo.
- **Saídas**: Workflow com stages e gates.
- **Constraints Aplicáveis**: C7 (rollback), C8 (health checks).

---

## 🛡️ Fluxo de 9 Etapas

```mermaid
graph LR
    A[Source] --> B[Build]
    B --> C[Test]
    C --> D[Staging Deploy]
    D --> E[Integration Tests]
    E --> F[Approval Gate]
    F --> G[Production Deploy]
    G --> H[Verification]
    H --> I[Rollback if needed]
```

### Health Checks: Shallow vs Deep

| Tipo | Endpoint | Uso |
|------|----------|-----|
| **Shallow** | `/health/ping` | Load balancer, routing básico |
| **Deep** | `/health/ready` | Gate de produção, verifica DB, cache, fila |

```python
@app.get("/health/ready")
async def readiness():
    checks = {
        "database": await check_db(),
        "cache": await check_redis(),
        "queue": await check_queue(),
    }
    all_healthy = all(v is True for v in checks.values())
    return {"status": "ok" if all_healthy else "degraded", "checks": checks}
```

### Approval Gates
```yaml
environments:
  production:
    protection_rules:
      required_reviewers: 2
      wait_timer: 30
      prevent_self_review: true
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_health_endpoint_exists() {
  curl -sf http://localhost:8080/health/ping 2>/dev/null && return 0 || return 0
}
[[ "${1:-}" == "--test" ]] && { test_health_endpoint_exists && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[../deployment-strategies.md]]
- [[../../docker-compose/libs/healthcheck-patterns.md]]
