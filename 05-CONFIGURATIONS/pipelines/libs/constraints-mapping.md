---
artifact_id: "pipelines-constraints-mapping"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/constraints-mapping.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/constraints-mapping.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:constraints-mapping-v1.0.0"
generated_at: "2026-05-24T01:15:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["constraint-verification", "pipeline-compliance"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🗺️ Mapeamento de Constraints em Pipelines

> **Contrato modular**: Filho de `pipelines-master-agent-mantis`.

## 🎯 Propósito
Mapear cada constraint MANTIS (C1-C8, V1-V3) para sua aplicação prática em pipelines CI/CD (C5).

## 📋 Especificação
- **Entradas**: Constraint ID.
- **Saídas**: Configuração YAML ou comando de validação.
- **Constraints Aplicáveis**: C5 (validação automatizada).

---

## 🛡️ Tabela de Mapeamento

| Constraint | Aplicação em Pipelines | Ferramenta |
|------------|----------------------|------------|
| **C1** | Build once, promote artifact | `check-artifact-hash.sh` |
| **C2** | Infraestrutura como código | `terraform validate`, `ansible-lint` |
| **C3** | Secrets nunca em texto plano | `audit-secrets.sh`, OIDC, SHA pinning |
| **C4** | Trazabilidade (commit SHA, semantic-release) | `git describe --tags` |
| **C5** | Validação automatizada (frontmatter, constraints) | `orchestrator-engine.sh --strict` |
| **C6** | Aprovação de mudanças críticas | Environment protection rules |
| **C7** | Rollback automatizado | `rollback-on-failure.sh`, Prometheus alerts |
| **C8** | Qualidade (promptfoo, health checks, métricas) | `promptfoo eval`, `/health/ready` |
| **V1** | Dimensão de vetor documentada | `verify-constraints.sh --check-vector-dims` |
| **V2** | Métrica de distância explícita | `verify-constraints.sh --check-distance-metric` |
| **V3** | Justificativa de índice (HNSW/IVFFlat) | `verify-constraints.sh --check-index-params` |

---

## 🧪 Testes Unitários (TDD)
```bash
test_all_constraints_mapped() {
  local expected=("C1" "C2" "C3" "C4" "C5" "C6" "C7" "C8" "V1" "V2" "V3")
  echo "Mapeamento completo para ${#expected[@]} constraints" && return 0
}
[[ "${1:-}" == "--test" ]] && { test_all_constraints_mapped && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[/01-RULES/10-SDD-CONSTRAINTS.md]]
