---
artifact_id: "configurations-agent-registry-format"
artifact_type: "governance_pattern"
version: "1.0.0"
constraints_mapped: ["C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/configurations/libs/agent-registry-format.md --json"
canonical_path: "05-CONFIGURATIONS/configurations/libs/agent-registry-format.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:agent-registry-format-v1.0.0"
generated_at: "2026-05-24T08:45:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "configurations"
ai_navigation:
  read_first: false
  required_for: ["stack-selector-updates", "agent-registration"]
  update_frequency: on-change
audience: ["configurations-ceo", "all-master-agents"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📋 Formato de Registro de Agentes

> **Contrato modular**: Filho de `configurations-ceo-mantis`.

## 🎯 Propósito
Padronizar o formato de entrada de cada agente mestre no `00-STACK-SELECTOR.md`, garantindo que todas as informações necessárias para o orquestrador sejam consistentes e validadas (C5).

## 📋 Especificação
- **Entradas**: Agente ID, domínio, skills, dependências.
- **Saídas**: Entrada JSON válida no `agent_registry`.
- **Constraints Aplicáveis**: C5 (validação de integridade).

---

## 🛡️ Formato Padrão

```json
{
  "configurations-ceo": {
    "id": "configurations-ceo",
    "master_agent_path": "05-CONFIGURATIONS/configurations-ceo.md",
    "language": "pt-BR",
    "version_lock": ">=2.3.0",
    "domain": "05-CONFIGURATIONS",
    "subdomains": ["templates", "scripts", "environment", "observability"],
    "capabilities": ["coordination", "project-management", "governance"],
    "depends_on": ["pipelines-master-agent", "terraform-master-agent", "docker-compose-master-agent"],
    "artifacts_produced": [
      "05-CONFIGURATIONS/Templates/*",
      "05-CONFIGURATIONS/Scripts/*",
      "05-CONFIGURATIONS/Environment/*",
      "05-CONFIGURATIONS/Observability/*",
      "docs/reports/sitrep/*.md",
      "docs/adr/*.md"
    ],
    "outputs": {
      "roadmap": "docs/roadmap/YYYY-QN.md",
      "sitrep": "docs/reports/sitrep/YYYY-WW.md",
      "adr": "docs/adr/ADR-XXX.md"
    },
    "harness": ["audit-configs.sh", "validate-env-mapping.py", "shellcheck"],
    "language_lock": {
      "exclusive_domain": "05-CONFIGURATIONS/",
      "violation_action": "BLOCKING + suggest_coordination_protocol"
    }
  }
}
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_registry_entry_valid_json() {
  python3 -c "import json; json.loads(open('$1').read())" "$1" 2>/dev/null && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_registry_entry_valid_json "00-STACK-SELECTOR.md" 2>/dev/null && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[configurations-ceo.md]]
- [[/00-STACK-SELECTOR.md]]
