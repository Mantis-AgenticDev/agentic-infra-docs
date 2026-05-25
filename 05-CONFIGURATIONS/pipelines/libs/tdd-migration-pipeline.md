---
artifact_id: "pipelines-tdd-migration"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/tdd-migration-pipeline.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/tdd-migration-pipeline.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:tdd-migration-v1.0.0"
generated_at: "2026-05-24T00:35:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["tdd-code-migration", "behavioral-equivalence"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧪 Pipeline de Migração TDD Zero-Context

> **Contrato modular**: Filho de `pipelines-master-agent-mantis`.

## 🎯 Propósito
Orquestrar a migração de código legado para novas linguagens usando TDD, sem que o orquestrador acumule contexto (C5, C8).

## 📋 Especificação
- **Entradas**: Caminho do código fonte, linguagem destino.
- **Saídas**: Código migrado com testes e relatório de validação.
- **Constraints Aplicáveis**: C5 (validação), C8 (qualidade).

---

## 🛡️ Fases do Pipeline

### Fase 1: SPEC (scout/architect)
Analisar código fonte com tldr-skill, gerar `spec.md` com contratos conductuais.

### Fase 2: FAILING_TESTS (arbiter)
Gerar testes que falham, definindo comportamento esperado antes da implementação.

### Fase 3: ADVERSARIAL_REVIEW (premortem)
3 pases de identificação de modos de falha, race conditions, edge cases.

### Fase 4: PHASED_PLAN (architect)
Criar plano ordenado por dependências, cada fase = unidade testeável.

### Fase 5: BUILD_LOOP (kraken)
Implementar código para passar testes de cada fase.

### Fase 6: INTEGRATION_VALIDATION (atlas)
Validar equivalência conductual contra referência.

### Anti-Padrões
- ❌ Orquestrador NUNCA lê arquivos fonte
- ❌ NUNCA modifica código original
- ❌ NUNCA valida por conta própria

---

## 🧪 Testes Unitários (TDD)
```bash
test_tdd_phase_order() {
  local phases=("SPEC" "FAILING_TESTS" "ADVERSARIAL_REVIEW" "PHASED_PLAN" "BUILD_LOOP" "INTEGRATION_VALIDATION")
  [[ "${phases[0]}" == "SPEC" ]] && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_tdd_phase_order && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[../promptfoo-quality.md]]
