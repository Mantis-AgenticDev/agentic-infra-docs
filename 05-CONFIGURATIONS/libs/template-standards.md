---
artifact_id: "configurations-template-standards"
artifact_type: "governance_pattern"
version: "1.0.0"
constraints_mapped: ["C1","C2","C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/configurations/libs/template-standards.md --json"
canonical_path: "05-CONFIGURATIONS/configurations/libs/template-standards.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:template-standards-v1.0.0"
generated_at: "2026-05-24T08:05:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "configurations"
ai_navigation:
  read_first: false
  required_for: ["template-management", "template-versioning"]
  update_frequency: on-change
audience: ["configurations-ceo", "docker-compose-master-agent", "terraform-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📐 Padrões de Uso e Versionamento de Templates

> **Contrato modular**: Artefato filho de `configurations-ceo-mantis`. Herda hardening e constraints do Master Agent.

## 🎯 Propósito
Definir as regras canônicas para criação, versionamento, personalização e validação de templates no domínio `05-CONFIGURATIONS/`, garantindo imutabilidade (C1), IaC (C2) e integridade (C5).

## 📋 Especificação
- **Entradas**: Tipo de template (Dockerfile, Compose, Terraform, script, dashboard).
- **Saídas**: Template versionado com frontmatter e comentários padronizados.
- **Constraints Aplicáveis**: C1 (imutabilidade), C2 (IaC), C5 (validação).

---

## 🛡️ Regras de Templates

### Versionamento Semântico
- **Major**: mudanças estruturais que quebram compatibilidade
- **Minor**: novas opções ou funcionalidades
- **Patch**: correções de documentação ou bugs menores

### Personalização
- Overrides via variáveis de ambiente ou arquivos de override (ex.: `compose.override.yaml`)
- **Nunca modificar a template base** sem documentar a desvio num ADR

### Estrutura Padrão de Template
Todo template deve incluir um cabeçalho YAML com:
```yaml
# ---
# artifact_id: "<nome>-template"
# version: "X.Y.Z"
# constraints_mapped: ["C1","C2","C3"]
# last_updated: "<ISO8601>"
# ---
```

### Validação
- `orchestrator-engine.sh --domain templates --strict` antes de promover para `REAL`

---

## 🧪 Testes Unitários (TDD)
```bash
test_template_has_header() {
  grep -q "artifact_id:" "$1" && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_template_has_header "../../Templates/Dockerfile.template" 2>/dev/null && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[configurations-ceo.md]]
- [[../../docker-compose/libs/base-service-template.md]] — Exemplo de template Compose
- [[../../terraform/libs/module-development.md]] — Exemplo de template de módulo
