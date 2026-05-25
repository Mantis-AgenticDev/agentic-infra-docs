---
artifact_id: "configurations-stakeholder-communication"
artifact_type: "governance_pattern"
version: "1.0.0"
constraints_mapped: ["C6"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/configurations/libs/stakeholder-communication.md --json"
canonical_path: "05-CONFIGURATIONS/configurations/libs/stakeholder-communication.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:stakeholder-comms-v1.0.0"
generated_at: "2026-05-24T08:35:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "configurations"
ai_navigation:
  read_first: false
  required_for: ["stakeholder-reporting", "incident-communication"]
  update_frequency: on-change
audience: ["configurations-ceo", "human-architects"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📢 Comunicação com Stakeholders

> **Contrato modular**: Filho de `configurations-ceo-mantis`.

## 🎯 Propósito
Definir o mapa de stakeholders do ecossistema, os protocolos de comunicação para decisões críticas, reportes de estado (SitRep) e incidentes (C6).

## 📋 Especificação
- **Entradas**: Tipo de evento (decisão crítica, reporte semanal, incidente).
- **Saídas**: Mensagem formatada, ADR, relatório SitRep.
- **Constraints Aplicáveis**: C6 (aprovação de mudanças críticas).

---

## 🛡️ Mapa de Stakeholders

| Stakeholder | Interesse | Canal |
|-------------|-----------|-------|
| Arquitecto principal (Facundo) | Visão geral, prioridades | Slack + repo |
| `pipelines-master-agent` | CI/CD fluido | Artefatos + logs |
| `terraform-master-agent` | Infraestrutura estável | `tfplan` + drift report |
| `docker-compose-master-agent` | Serviços operacionais | Health checks + métricas |
| Colaboradores humanos (pt-BR) | Documentação clara | Issues no GitHub |

### Para Decisões Críticas
1. Gerar ADR.
2. Solicitar revisão via issue.
3. Aguardar aprovação (`/approve`).
4. Documentar a decisão final.

### Para Incidentes
1. Ativar runbook.
2. Notificar arquiteto principal imediatamente.
3. Atualizar SitRep com seção de incidente.

---

## 🧪 Testes Unitários (TDD)
```bash
test_sitrep_template_exists() {
  [[ -f templates/sitrep-template.md ]] && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_sitrep_template_exists && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[configurations-ceo.md]]
- [[../templates/sitrep-template.md]]
- [[../../docker-compose/libs/troubleshooting.md]]
