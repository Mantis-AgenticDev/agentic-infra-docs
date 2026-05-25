---
artifact_id: "configurations-script-standards"
artifact_type: "governance_pattern"
version: "1.0.0"
constraints_mapped: ["C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/configurations/libs/script-standards.md --json"
canonical_path: "05-CONFIGURATIONS/configurations/libs/script-standards.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:script-standards-v1.0.0"
generated_at: "2026-05-24T08:10:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "configurations"
ai_navigation:
  read_first: false
  required_for: ["script-development", "script-validation"]
  update_frequency: on-change
audience: ["configurations-ceo", "all-master-agents"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📜 Padrão de Scripting MANTIS

> **Contrato modular**: Filho de `configurations-ceo-mantis`.

## 🎯 Propósito
Estabelecer o padrão canônico para todos os scripts bash do ecossistema MANTIS, garantindo resiliência (C7), qualidade (C8) e validação (C5).

## 📋 Especificação
- **Entradas**: Nome e propósito do script.
- **Saídas**: Script bash com cabeçalho, logging, tratamento de erros e cleanup.
- **Constraints Aplicáveis**: C5 (validação), C7 (rollback), C8 (observabilidade).

---

## 🛡️ Estrutura Obrigatória

### Cabeçalho
```bash
#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Script   : <nome>.sh
# Domínio  : 05-CONFIGURATIONS/Scripts
# Propósito: <descrição>
# Uso      : ./<nome>.sh [opções]
# Dependências: <ferramentas>
# Autor    : configurations-ceo
# Versão   : 1.0.0
# Constraints: C1,C2,C3
# ---------------------------------------------------------------------------
set -euo pipefail
```

### Logging
```bash
log_info()  { echo "[INFO]  $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }
```

### Cleanup
```bash
cleanup() { /* lógica de limpeza */ }
trap cleanup EXIT
```

### Validação de Dependências
```bash
for cmd in docker jq curl; do
    command -v "$cmd" >/dev/null 2>&1 || { log_error "$cmd não instalado."; exit 1; }
done
```

### Execução Condicional (TDD)
```bash
if [[ "${1:-}" == "--test" ]]; then
    test_<funcionalidade> && echo "✅" || echo "❌"
    exit $?
fi
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_script_has_shellcheck() {
    shellcheck -x "$1" 2>/dev/null && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { command -v shellcheck &>/dev/null && test_script_has_shellcheck "health-check.sh" && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[configurations-ceo.md]]
- [[../templates/script-template.sh]] — Plantilla reutilizável
- [[../../pipelines/libs/best-practices-anti-patterns.md]]
