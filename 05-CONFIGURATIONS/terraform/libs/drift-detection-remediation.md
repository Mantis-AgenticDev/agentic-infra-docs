---
artifact_id: "terraform-drift-detection-remediation"
artifact_type: "terraform_pattern"
version: "1.0.0"
constraints_mapped: ["C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/terraform/libs/drift-detection-remediation.md --json"
canonical_path: "05-CONFIGURATIONS/terraform/libs/drift-detection-remediation.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:tf-drift-v1.0.0"
generated_at: "2026-05-24T05:45:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "terraform"
ai_navigation:
  read_first: false
  required_for: ["drift-detection", "state-remediation"]
  update_frequency: on-change
audience: ["terraform-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔍 Detecção e Remediação de Drift

> **Contrato modular**: Filho de `terraform-master-agent-mantis`.

## 🎯 Propósito
Detectar mudanças não autorizadas na infraestrutura (drift), categorizar por severidade e aplicar as ações corretivas apropriadas (C7, C8).

## 📋 Especificação
- **Entradas**: Ambiente alvo.
- **Saídas**: Relatório de drift categorizado, ações recomendadas.
- **Constraints Aplicáveis**: C7 (rollback), C8 (qualidade).

---

## 🛡️ Categorias de Drift

| Categoria | Severidade | Exemplos | Ação |
|-----------|-----------|----------|------|
| Security Drift | CRITICAL | Security groups abertos, IAM relaxado | Reverter imediatamente |
| Configuration Drift | HIGH | Instance type alterado, DB params | Avaliar impacto |
| Tag Drift | MEDIUM | Tags removidos ou incorretos | Atualizar HCL |
| Metadata Drift | LOW | ARNs, timestamps | Aceitar automaticamente |

### Comandos de Detecção
```bash
terraform plan -refresh-only -out=drift.out
terraform show -json drift.out | jq '.resource_changes[] | select(.change.actions != ["no-op"])'
```

### Resolução
```bash
# Aceitar drift (atualizar estado)
terraform apply -refresh-only -auto-approve
# Rejeitar drift (reverter infra)
terraform apply -auto-approve
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_drift_script_exists() {
  [[ -x scripts/drift-check.sh ]] && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_drift_script_exists && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[terraform-master-agent.md]]
- [[../ci-cd-pipeline.md]]
- [[../../pipelines/libs/troubleshooting.md]]
