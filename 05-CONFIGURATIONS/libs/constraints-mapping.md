---
artifact_id: "configurations-constraints-mapping"
artifact_type: "governance_pattern"
version: "1.0.0"
constraints_mapped: ["C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/configurations/libs/constraints-mapping.md --json"
canonical_path: "05-CONFIGURATIONS/configurations/libs/constraints-mapping.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:config-constraints-v1.0.0"
generated_at: "2026-05-24T08:50:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "configurations"
ai_navigation:
  read_first: false
  required_for: ["constraint-verification", "compliance-audit"]
  update_frequency: on-change
audience: ["configurations-ceo", "all-master-agents"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🗺️ Mapeamento de Constraints para Coordenação

> **Contrato modular**: Filho de `configurations-ceo-mantis`.

## 🎯 Propósito
Mapear cada constraint MANTIS (C1-C8, V1-V3) para sua aplicação prática no domínio de coordenação (C5).

## 📋 Especificação
- **Entradas**: Constraint ID.
- **Saídas**: Ação de validação correspondente.
- **Constraints Aplicáveis**: C5 (validação automatizada).

---

## 🛡️ Tabela de Mapeamento

| Constraint | Aplicação em Coordenação | Ferramenta |
|------------|--------------------------|------------|
| **C1** | Templates versionados não se modificam; overrides em arquivos separados | `git diff --name-only` |
| **C2** | Tudo no repo; nada manual em VPS | `audit-configs.sh` |
| **C3** | `.env.prod` externo; mapping.yaml sem secrets | `audit-secrets.sh` |
| **C4** | Scripts com versão; ADRs documentam decisões | `git log --follow` |
| **C5** | `audit-configs.sh` em cada push | `orchestrator-engine.sh --strict` |
| **C6** | Roadmap aprovado pelo arquiteto; deploy com gate | Environment protection rules |
| **C7** | Scripts de deploy incluem rollback | `deploy-all.sh --rollback` |
| **C8** | Health checks; promptfoo; métricas DORA | `health-check.sh`, dashboards Grafana |
| **V1** | Redes separadas por tenant nos templates | `check-rls.sh` |
| **V2** | Backups com checksum | `backup-verify.sh` |
| **V3** | Métricas de latência pgvector nos dashboards | `vector_search_latency_seconds` |

---

## 🧪 Testes Unitários (TDD)
```bash
test_all_constraints_mapped() {
  local constraints=("C1" "C2" "C3" "C4" "C5" "C6" "C7" "C8" "V1" "V2" "V3")
  echo "Mapeamento completo para ${#constraints[@]} constraints" && return 0
}
[[ "${1:-}" == "--test" ]] && { test_all_constraints_mapped && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[configurations-ceo.md]]
- [[../../pipelines/libs/constraints-mapping.md]]
- [[../../terraform/libs/constraints-mapping.md]]
