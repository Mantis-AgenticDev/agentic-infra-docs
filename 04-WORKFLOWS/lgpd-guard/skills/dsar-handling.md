---
artifact_id: "lgpd-dsar-handling"
artifact_type: "lgpd_skill"
version: "1.0.0"
constraints_mapped: ["C4","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/lgpd-guard/skills/dsar-handling.md --json"
canonical_path: "04-WORKFLOWS/lgpd-guard/skills/dsar-handling.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:lgpd-dsar-handling-v1.0.0"
generated_at: "2026-05-25T03:10:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "workflows"
ai_navigation:
  read_first: false
  required_for: ["data-subject-request", "right-to-access", "right-to-deletion"]
  update_frequency: on-change
audience: ["lgpd-guard", "n8n-master-agent", "langchain-langraph-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-25"
---

# 📋 Atendimento a Requisições de Titulares (DSAR — Art. 18)

> **Contrato modular**: Artefato filho de `lgpd-guard-mantis`.

## 🎯 Propósito
Padronizar o fluxo de resposta às requisições dos titulares de dados, conforme o Art. 18 da LGPD, que garante ao titular o direito de: confirmar existência de tratamento, acessar seus dados, corrigir dados incompletos/inexatos/desatualizados, anonimizar/bloquear/eliminar dados desnecessários, portabilidade, eliminação de dados tratados com consentimento, informação sobre compartilhamento e revogação de consentimento. O prazo legal é de **15 dias** a partir da requisição (Art. 19, §1º).

## 📋 Especificação (SDD)
- **Entradas**: Requisição do titular (via webhook, formulário, e-mail), tipo de requisição, dados de identificação.
- **Saídas**: Resposta ao titular dentro do prazo legal com a ação executada ou justificativa.
- **Side Effects**: Alteração/eliminação de dados nos sistemas de armazenamento.
- **Constraints Aplicáveis**: C4 (rastreabilidade), C5 (validação), C6 (aprovação para ações destrutivas), C7 (rollback possível), C8 (logging).
- **Dependências**: n8n, Data Tables, bancos de dados externos, sistemas de storage.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
dsar_handling:
  rights_art_18:
    confirmation: "Direito de confirmar a existência de tratamento"
    access: "Direito de acesso aos dados"
    correction: "Direito de correção de dados incompletos, inexatos ou desatualizados"
    anonymization: "Direito de anonimização, bloqueio ou eliminação de dados desnecessários"
    portability: "Direito de portabilidade dos dados a outro fornecedor"
    deletion: "Direito de eliminação dos dados tratados com consentimento"
    sharing_info: "Direito de informação sobre compartilhamento com entidades públicas e privadas"
    consent_info: "Direito de informação sobre possibilidade de não consentir e consequências"
    revocation: "Direito de revogação do consentimento"

  flow_access:
    trigger: "Requisição de confirmação/acesso"
    steps:
      - "Verificar identidade do titular (certificação gov.br ou documento)"
      - "Buscar dados em todos os sistemas: Data Tables, bancos SQL, storage"
      - "Compilar relatório estruturado"
      - "Enviar ao Encarregado (DPO) para revisão"
      - "Encaminhar resposta ao titular em até 15 dias"
      - "Log: lgpd_dsar_completed com tipo=acesso"

  flow_deletion:
    trigger: "Requisição de eliminação"
    steps:
      - "Verificar identidade do titular"
      - "Identificar todos os registros vinculados ao titular_id"
      - "Avaliar exceções legais (obrigação legal, exercício regular de direitos)"
      - "Se não há exceção: eliminar ou anonimizar dados"
      - "Se há exceção: informar ao titular quais dados foram mantidos e por qual motivo legal"
      - "Log: lgpd_dsar_completed com tipo=eliminação"

  identity_verification:
    methods:
      gov_br: "Autenticação via login único gov.br (selo prata ou ouro)"
      document: "Conferência presencial de documento físico com foto"
      digital: "Certificação digital ICP-Brasil"
      fallback: "Cotejamento de informações com bases públicas"

  deadline_monitoring:
    max_days: 15
    alert_days: [10, 13]  # Alertar DPO se próximo do limite
    escalation: "Se > 15 dias, notificar Controlador e registrar justificativa"

  anti_patterns:
    - "Responder requisição de acesso sem verificar identidade → violação de segurança"
    - "Eliminar dados sem verificar exceções legais → pode eliminar dados obrigatórios"
    - "Exceder 15 dias sem justificativa → infração ao Art. 19"
    - "Cobrar taxa indevida → o serviço deve ser gratuito (salvo exceções justificadas)"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_dsar_deadline_monitoring() {
  local max_days=15
  local alert_days=(10 13)
  [[ $max_days -eq 15 && ${alert_days[0]} -eq 10 && ${alert_days[1]} -eq 13 ]] && return 0 || return 1
}

test_dsar_rights_count() {
  local rights=("confirmation" "access" "correction" "anonymization" "portability" "deletion" "sharing_info" "consent_info" "revocation")
  [[ ${#rights[@]} -eq 9 ]] && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && {
  test_dsar_deadline_monitoring && test_dsar_rights_count && echo "✅" || echo "❌"
  exit $?
}
```

---

## 🔗 Referências Cruzadas

- [[lgpd-guard.md]]
- [[consent-management.md]]
- [[retention-deletion.md]]
- [[audit-logging.md]]
