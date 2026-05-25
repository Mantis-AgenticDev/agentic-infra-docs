---
artifact_id: "configurations-environment-standards"
artifact_type: "governance_pattern"
version: "1.0.0"
constraints_mapped: ["C3","C4","C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/configurations/libs/environment-standards.md --json"
canonical_path: "05-CONFIGURATIONS/configurations/libs/environment-standards.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:env-standards-v1.0.0"
generated_at: "2026-05-24T08:15:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "configurations"
ai_navigation:
  read_first: false
  required_for: ["environment-management", "secret-management"]
  update_frequency: on-change
audience: ["configurations-ceo", "all-master-agents"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🌍 Gestão de Ambiente e Secrets

> **Contrato modular**: Filho de `configurations-ceo-mantis`.

## 🎯 Propósito
Padronizar a gestão de variáveis de ambiente, secrets e mapeamento de consumo (`mapping.yaml`) para garantir segurança (C3), rastreabilidade (C4) e integridade (C5).

## 📋 Especificação
- **Entradas**: Nome da variável, tipo, valor de exemplo.
- **Saídas**: Entrada em `.env.example`, `mapping.yaml`, e scripts de validação.
- **Constraints Aplicáveis**: C3 (secrets), C4 (trazabilidade), C5 (validação).

---

## 🛡️ Regras

### `.env.example` como Fonte de Verdade
```bash
# ---
# artifact_id: "env-example"
# version: "1.0.0"
# ---
PROJECT_NAME="mantis"
DATABASE_URL=""  # sensitive: true
```

### `mapping.yaml`
```yaml
variables:
  DATABASE_URL:
    consumers: [terraform-master-agent, docker-compose-master-agent]
    type: connection_string
    sensitive: true
    validation: "^postgresql://.+"
```

### Secrets
- Nunca commitar `.env.prod`
- Gerenciar com `git-crypt` ou gestor externo
- Rotação automática com `rotate-secrets.sh`

### Validação
```bash
python3 scripts/validate-env-mapping.py
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_env_example_has_no_real_secrets() {
    grep -q "sensitive: true" environment/.env.example && { grep -qE '^[A-Z_]+="[^"]+' environment/.env.example && return 1 || return 0; }
}
[[ "${1:-}" == "--test" ]] && { test_env_example_has_no_real_secrets && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[configurations-ceo.md]]
- [[../../docker-compose/libs/security-patterns.md]] — Secrets em contêineres
- [[../../pipelines/libs/security-patterns.md]] — Secrets em pipelines
