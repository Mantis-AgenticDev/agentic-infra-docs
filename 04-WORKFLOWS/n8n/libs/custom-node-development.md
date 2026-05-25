---
artifact_id: "n8n-custom-node-development"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C1","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/custom-node-development.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/custom-node-development.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:custom-node-dev-v1.0.0"
generated_at: "2026-05-24T15:50:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["custom-node-creation", "typescript-nodes"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔧 Desenvolvimento de Nós Personalizados

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar o desenvolvimento de nós personalizados em TypeScript para n8n, incluindo estilos programático e declarativo, configuração de credenciais e publicação, garantindo imutabilidade (C1), validação (C5) e qualidade (C8).

## 📋 Especificação (SDD)
- **Entradas**: Requisitos do nó (tipo de integração, autenticação, parâmetros).
- **Saídas**: Pacote npm com nó personalizado funcional.
- **Constraints Aplicáveis**: C1 (versionamento), C5 (validação), C8 (qualidade).

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
custom_node_development:
  when_to_build:
    - "Lógica reutilizável em >3 workflows"
    - "Autenticação complexa (OAuth2, multi-step)"
    - "Operações críticas de performance"
    - "Contribuição comunitária (npm público)"
    - "Integrações específicas da organização"

  styles:
    programmatic:
      description: "Controle total sobre autenticação, UI e operações"
      use_for: ["Auth flows complexos", "Validação avançada de parâmetros", "UI components customizados", "Polling com gestão de estado"]
    declarative:
      description: "Simplificado para CRUD e wrappers REST"
      use_for: ["Operações CRUD padrão", "Wrappers de API RESTful", "Integrações simples"]

  workflow:
    step_1_init: "npm create @n8n/node my-custom-node"
    step_2_implement: "Definir node properties, implementar execute(), adicionar error handling"
    step_3_build: "npm run build"
    step_4_test: "npm link → reiniciar n8n"
    step_5_publish: "npm publish"

  complexity_rating:
    declarative_crud: 2
    programmatic_with_auth: 3
    complex_state_management: 4
    advanced_polling_webhooks: 5

  done_definition:
    - "Todas as operações implementadas e testadas"
    - "Credenciais integradas e funcionando"
    - "Parâmetros validados"
    - "Tipos TypeScript definidos"
    - "Tratamento de erros abrangente"
    - "README com instruções de instalação"
    - "Publicado no npm (se público)"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_custom_node_structure() {
  local dir="${1:-.}"
  [[ -f "$dir/nodes/MyNode/MyNode.node.ts" || -f "$dir/package.json" ]] && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && { test_custom_node_structure && echo "✅" || echo "❌"; exit $?; }
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[code-execution-patterns.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
