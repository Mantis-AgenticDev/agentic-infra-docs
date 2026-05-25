---
artifact_id: "configurations-project-management"
artifact_type: "governance_pattern"
version: "1.0.0"
constraints_mapped: ["C5","C6"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/configurations/libs/project-management.md --json"
canonical_path: "05-CONFIGURATIONS/configurations/libs/project-management.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:project-mgmt-v1.0.0"
generated_at: "2026-05-24T08:30:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "configurations"
ai_navigation:
  read_first: false
  required_for: ["roadmap-planning", "task-prioritization", "adr-generation"]
  update_frequency: on-change
audience: ["configurations-ceo", "human-architects"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📊 Gestão de Projeto e Roadmap

> **Contrato modular**: Artefato filho de `configurations-ceo-mantis`. Herda hardening e constraints do Master Agent.

## 🎯 Propósito
Padronizar a priorização de tarefas (RICE), a elaboração de roadmaps trimestrais e a documentação de decisões arquitetônicas (ADR), garantindo validação (C5) e aprovação de mudanças críticas (C6).

## 📋 Especificação
- **Entradas**: Lista de features, dívidas técnicas ou melhorias.
- **Saídas**: Roadmap trimestral (`YYYY-QN.md`), ADR documentado.
- **Constraints Aplicáveis**: C5 (validação de integridade), C6 (aprovação de mudanças críticas).

---

## 🛡️ Métricas e Modelos

### Fórmula RICE
```
RICE Score = (Reach × Impact × Confidence) / Effort
```

| Variável | Descrição | Escala |
|----------|-----------|--------|
| **Reach** | Quantos subdomínios/agentes são afetados | 1-5 |
| **Impact** | Impacto no ecossistema | 1-3 |
| **Confidence** | Nível de confiança na estimativa | 0.25-1.0 |
| **Effort** | Esforço estimado em pontos | 1-20 |

### Marcadores de Tarefa
- ✅ **Ready**: Imediatamente executável.
- ⏳ **Pending**: Aguardando dependência.
- 🔍 **Research**: Requer investigação.
- 🚧 **Blocked**: Bloqueador crítico.

### Roadmap Trimestral
```markdown
# Roadmap Q2 2026 — "Estabilização"
├─ 🔴 Completar workflows de CI/CD
├─ 🔴 Unificar templates de Docker Compose
├─ 🟡 Script deploy-all.sh funcional
├─ 🟡 Dashboard de monitoreo base
└─ 🟢 Documentação pt-BR para colaboradores
```

### ADR (Architecture Decision Record)
Estrutura padronizada em [[templates/adr-template.md]] com seções: Contexto, Decisão, Consequências, Alternativas, Implementação, Revisão.

---

## 🧪 Testes Unitários (TDD)
```bash
test_rice_score_calculation() {
  local reach=5 impact=3 confidence=0.9 effort=8
  local score=$(echo "scale=2; ($reach * $impact * $confidence) / $effort" | bc)
  [[ "$score" == "1.68" || "$score" == "1.69" ]] && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_rice_score_calculation && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[configurations-ceo.md]]
- [[../templates/adr-template.md]]
- [[../templates/roadmap-template.md]]
- [[../templates/sitrep-template.md]]
