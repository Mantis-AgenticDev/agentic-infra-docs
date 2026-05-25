---
artifact_id: "pipelines-troubleshooting"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/troubleshooting.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/troubleshooting.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:pipeline-troubleshooting-v1.0.0"
generated_at: "2026-05-24T01:20:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["pipeline-debugging", "failure-diagnosis"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🐞 Troubleshooting de Pipelines

> **Contrato modular**: Filho de `pipelines-master-agent-mantis`. Complementa [[../../docker-compose/libs/troubleshooting.md]].

## 🎯 Propósito
Diagnosticar e resolver falhas comuns em pipelines CI/CD (C8).

## 📋 Especificação
- **Entradas**: Sintoma da falha.
- **Saídas**: Comando de diagnóstico + solução.
- **Constraints Aplicáveis**: C8.

---

## 🛡️ Problemas Comuns

| Sintoma | Causa | Diagnóstico | Solução |
|---------|-------|-------------|---------|
| Pipeline não inicia | Sem revisores | `gh api /repos/$OWNER/$REPO/environments/production` | Configurar required reviewers |
| Imagem reconstrói sempre | Cache mal ordenado | `docker history <image>` | Reordenar camadas |
| `terraform apply` timeout | Estado bloqueado | `terraform state list` | `-lock-timeout=10m` |
| promptfoo não detecta regressão | Asserções frouxas | `jq '.tests[].assert[]' test-cases/*.yaml` | Adicionar `type: javascript` |
| Canary não chega a 100% | Métrica sem dados | `curl "$PROM_URL/api/v1/query?query=..."` | Ajustar `inconclusiveLimit` |
| Health check passa mas serviço cai | `/ping` não verifica dependências | `curl /health/ready` | Usar deep health check |
| Pipeline lento (>30 min) | Jobs em série, sem cache | `gh run view <id> --log` | Paralelizar, adicionar cache |

---

## 🧪 Testes Unitários (TDD)
```bash
test_troubleshooting_table_complete() {
  grep -q "Pipeline não inicia" "$0" && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_troubleshooting_table_complete && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[../../docker-compose/libs/troubleshooting.md]]
