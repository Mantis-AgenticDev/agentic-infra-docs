---
artifact_id: "pipelines-promptfoo-quality"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/promptfoo-quality.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/promptfoo-quality.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:promptfoo-quality-v1.0.0"
generated_at: "2026-05-23T23:35:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["agent-validation", "promptfoo-configuration"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 🧪 Validação com promptfoo

> **Contrato modular**: Filho de `pipelines-master-agent-mantis`.

## 🎯 Propósito
Configurar promptfoo para validar agentes master, assegurando que as saídas cumpram constraints MANTIS (C5, C8).

## 📋 Especificação
- **Entradas**: Caminho do agente, casos de teste.
- **Saídas**: Resultados JSON de validação.
- **Constraints Aplicáveis**: C5 (validação automatizada), C8 (qualidade).

---

## 🛡️ Configuração Base

```yaml
# promptfoo/config.yaml
prompts:
  - file://prompts/agent-behavior.prompt.md
providers:
  - id: openrouter:qwen/qwen-2.5-72b-instruct
    config:
      temperature: 0.1
tests:
  - file://test-cases/resource-limits.yaml
  - file://test-cases/tenant-isolation.yaml
defaultTest:
  assert:
    - type: contains
      value: "validation_command:"
    - type: javascript
      value: "return !output.includes('password=');"
```

### Caso de Teste (tenant isolation)
```yaml
vars:
  tenant_a_query: "SELECT * FROM orders WHERE tenant_id = 'tenant_a'"
assert:
  - type: not-contains
    value: "tenant_b"
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_promptfoo_config_exists() {
  [[ -f 05-CONFIGURATIONS/pipelines/promptfoo/config.yaml ]] && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_promptfoo_config_exists && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[../../docker-compose/libs/validation-scripts.md]]
