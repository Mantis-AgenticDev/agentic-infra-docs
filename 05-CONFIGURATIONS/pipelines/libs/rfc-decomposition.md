---
artifact_id: "pipelines-rfc-decomposition"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C6"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/rfc-decomposition.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/rfc-decomposition.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:rfc-decomposition-v1.0.0"
generated_at: "2026-05-24T00:45:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["feature-decomposition", "merge-queue"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📋 Decomposição de Features Complexas (RFC)

> **Contrato modular**: Filho de `pipelines-master-agent-mantis`.

## 🎯 Propósito
Decompor features grandes em unidades testáveis com DAG de dependências, merge queue e rollback coordenado (C6).

## 📋 Especificação
- **Entradas**: RFC ID, descrição da feature.
- **Saídas**: YAML com unidades, dependências, testes de aceitação.
- **Constraints Aplicáveis**: C6 (aprovação de mudanças críticas).

---

## 🛡️ Estrutura de Decomposição

```yaml
rfc_id: RFC-2026-004
units:
  - id: unit-01
    depends_on: []
    acceptance_tests: [...]
    risk_level: high
    rollback_plan: "..."
  - id: unit-02
    depends_on: [unit-01]
    acceptance_tests: [...]
    risk_level: medium
```

### Regras de Merge Queue
1. Nunca mergear unidade com dependências falhadas
2. Rebase automático sobre `main`
3. Re-executar testes após cada merge
4. Timeout por unidade (2h)
5. Rollback coordenado (desfazer unidade + dependentes)

---

## 🧪 Testes Unitários (TDD)
```bash
test_dag_no_circular_deps() {
  python3 -c "
deps = {'unit-01': [], 'unit-02': ['unit-01'], 'unit-03': ['unit-01', 'unit-02']}
# Verificar sem dependências circulares
for u, d in deps.items():
    for dep in d:
        assert dep in deps, f'Dependência {dep} não existe'
print('DAG válido')
" && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_dag_no_circular_deps && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[../deployment-design.md]]
