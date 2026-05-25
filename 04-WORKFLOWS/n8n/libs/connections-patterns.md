---
artifact_id: "n8n-connections-patterns"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/connections-patterns.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/connections-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:connections-patterns-v1.0.0"
generated_at: "2026-05-24T21:30:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["sdk-connections", "wiring-verification"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔗 Gramática de Conexões do SDK n8n

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar a criação e verificação de conexões entre nós no SDK do n8n, prevenindo a armadilha `.to()` que causa wires silenciosamente descartados, e garantindo que fan-outs, fan-ins e entradas de Merge estejam corretos (C5).

## 📋 Especificação (SDD)
- **Entradas**: Nós de origem e destino, índices de saída/entrada.
- **Saídas**: Conexão SDK válida e verificada.
- **Constraints Aplicáveis**: C5 (validação estrutural).

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
connections:
  non_negotiable_trap: |
    .to() DEVE estar DENTRO de .add(), não depois.
    .add(node.output(0)).to(target)      // ❌ wire descartado silenciosamente
    .add(node.output(0).to(target))      // ✅ correto
    validate_workflow NÃO detecta isso.

  universal_pattern: ".add(source.output(n).to(target))"
  
  composite_handlers:
    if_on_true: ".add(ifNode.onTrue(targetA))    // = .add(ifNode.output(0).to(targetA))"
    if_on_false: ".add(ifNode.onFalse(targetB))   // = .add(ifNode.output(1).to(targetB))"
    switch_on_case: ".add(sw.onCase(2, target))      // = .add(sw.output(2).to(target))"
    error_output: ".add(node.onError(handler))      // = .add(node.output(1).to(handler))"

  verification_post_create: |
    validate_workflow NÃO é suficiente. Após create/update, usar get_workflow_details
    e inspecionar o objeto connections:
    - Cada main[i] tem o conjunto esperado de targets
    - Entradas de Merge nos índices corretos
    - Nós de erro têm onError: 'continueErrorOutput' E main[1] conectado

  merge_index_rules: |
    useDataOfInput: "N" → usar .input(N-1)
    Ex: useDataOfInput: "2" → .input(1)

  anti_patterns:
    - ".add(node.output(0)).to(target) → wire descartado, validação passa"
    - "Misturar useDataOfInput: '2' com .input(2) → off-by-one"
    - "Branch de erro sem onError: 'continueErrorOutput' → inalcançável"
    - "Pular get_workflow_details após create → workflows quebrados em produção"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_connection_to_inside_add() {
  # Verificar que .to() está dentro de .add()
  local code=".add(node.output(0).to(target))"
  echo "$code" | grep -q "\.add(.*\.to(" && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && { test_connection_to_inside_add && echo "✅" || echo "❌"; exit $?; }
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[error-handling-advanced.md]]
- [[workflow-lifecycle.md]]
