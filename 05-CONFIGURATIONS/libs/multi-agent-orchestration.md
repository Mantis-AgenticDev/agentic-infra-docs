---
artifact_id: "configurations-multi-agent-orchestration"
artifact_type: "governance_pattern"
version: "1.0.0"
constraints_mapped: ["C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/configurations/libs/multi-agent-orchestration.md --json"
canonical_path: "05-CONFIGURATIONS/configurations/libs/multi-agent-orchestration.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:multi-agent-orch-v1.0.0"
generated_at: "2026-05-24T08:25:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "configurations"
ai_navigation:
  read_first: false
  required_for: ["deployment-orchestration", "agent-coordination"]
  update_frequency: on-change
audience: ["configurations-ceo"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🎻 Orquestração Multi‑Agente

> **Contrato modular**: Filho de `configurations-ceo-mantis`.

## 🎯 Propósito
Padronizar o fluxo de despliegue completo, a resolução de dependências entre agentes e o protocolo de delegação `Task()` (C6, C7, C8).

## 📋 Especificação
- **Entradas**: Ambiente alvo, agentes envolvidos.
- **Saídas**: Script `deploy-all.sh`, relatório de dependências.
- **Constraints Aplicáveis**: C6 (aprovação), C7 (rollback), C8 (qualidade).

---

## 🛡️ Fluxo de Despliegue

1. Terraform Plan/Apply
2. Docker Build & Push
3. Deploy Compose to VPS
4. Validação post-deploy
5. Notificação

### Protocolo `Task()`
```yaml
Task(terraform-master-agent):
  prompt: "Gerar plan de infra para ${ENV}"
  context: ["main.tf", ".env.prod"]
  expected_output: ["tfplan", "outputs.json"]
  timeout_minutes: 30
```

### Resolução de Dependências
```bash
orchestrator-engine.sh --resolve-deps
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_deploy_script_exists() {
    [[ -f scripts/deploy-all.sh ]] && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_deploy_script_exists && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[configurations-ceo.md]]
- [[../../pipelines/libs/deployment-design.md]]
- [[../../docker-compose/libs/deployment-strategies.md]]
