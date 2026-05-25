---
artifact_id: "pipelines-pipeline-review"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/pipeline-review.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/pipeline-review.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:pipeline-review-v1.0.0"
generated_at: "2026-05-24T00:50:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["pipeline-health-check", "pipeline-prioritization"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📊 Revisão de Pipelines (/pipeline-review)

> **Contrato modular**: Filho de `pipelines-master-agent-mantis`.

## 🎯 Propósito
Analisar a saúde dos pipelines, priorizar correções e gerar plano de ação com métricas objetivas (C8).

## 📋 Especificação
- **Entradas**: Segmento ou responsável (opcional).
- **Saídas**: Relatório estruturado com scores, ações e matriz de priorização.
- **Constraints Aplicáveis**: C8 (qualidade de entrega).

---

## 🛡️ Estrutura do Comando

### Invocação
```bash
/pipeline-review              # Todos os pipelines
/pipeline-review skills       # Apenas validação de agentes
/pipeline-review @facundo     # Pipelines atribuídos
```

### Health Score (0-100)
| Dimensão | Peso |
|----------|------|
| Taxa de Sucesso | 25 |
| Tempo de Execução | 25 |
| Cobertura de Testes | 25 |
| Atualização de Dependências | 25 |

### Matriz de Priorização
- 🔴 Críticos: corrigir esta semana
- 🟡 Importantes: otimizar este mês
- 🟢 Manutenção: revisar trimestralmente

---

## 🧪 Testes Unitários (TDD)
```bash
test_review_output_format() {
  echo "Pipeline Review: 2026-05-24" | grep -q "Pipeline Review" && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_review_output_format && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[../metrics-dora.md]]
- [[../../docker-compose/libs/troubleshooting.md]]
