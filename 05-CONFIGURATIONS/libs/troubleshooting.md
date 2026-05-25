---
artifact_id: "configurations-troubleshooting"
artifact_type: "governance_pattern"
version: "1.0.0"
constraints_mapped: ["C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/configurations/libs/troubleshooting.md --json"
canonical_path: "05-CONFIGURATIONS/configurations/libs/troubleshooting.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:config-troubleshooting-v1.0.0"
generated_at: "2026-05-24T08:55:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "configurations"
ai_navigation:
  read_first: false
  required_for: ["coordination-debugging", "failure-diagnosis"]
  update_frequency: on-change
audience: ["configurations-ceo", "all-master-agents"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🐞 Troubleshooting de Coordenação

> **Contrato modular**: Filho de `configurations-ceo-mantis`. Complementa [[../../docker-compose/libs/troubleshooting.md]] e [[../../pipelines/libs/troubleshooting.md]].

## 🎯 Propósito
Diagnosticar e resolver falhas comuns na coordenação multi-agente e na gestão de configurações (C8).

## 📋 Especificação
- **Entradas**: Sintoma da falha.
- **Saídas**: Comando de diagnóstico + solução.
- **Constraints Aplicáveis**: C8.

---

## 🛡️ Problemas Comuns

| Sintoma | Causa | Diagnóstico | Solução |
|---------|-------|-------------|---------|
| Script falha por variável não definida | `.env` não carregado | `grep -r "VAR" Environment/` | Adicionar ao `mapping.yaml`, recarregar |
| Templates não são aplicados | Outro agente hardcodou valores | `diff template base vs artefato` | Corrigir agente, documentar desvio |
| Dashboard sem métricas | Prometheus não scrapeia | `curl localhost:3000/metrics` | Adicionar job no `prometheus.yml` |
| CI/CD para no build | Dependência não satisfeita | `--resolve-deps` | Verificar outputs dos agentes |
| Conflito de merge no `.env` | Múltiplos agentes modificaram | `git log -p -- .env.example` | Atualizar `mapping.yaml`, comunicar |
| Health check falha pós-deploy | `/health/ready` não verifica tudo | `curl -v /health/ready` | Implementar health check profundo |
| Rollback não restaura estado | Script não atualiza Terraform | `terraform state list` | Incluir `terraform apply` no rollback |

---

## 🧪 Testes Unitários (TDD)
```bash
test_troubleshooting_table_complete() {
  grep -q "Script falha" "$0" && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_troubleshooting_table_complete && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[configurations-ceo.md]]
- [[../../docker-compose/libs/troubleshooting.md]]
- [[../../pipelines/libs/troubleshooting.md]]
