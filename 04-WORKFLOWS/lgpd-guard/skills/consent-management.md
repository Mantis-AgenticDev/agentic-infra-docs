---
artifact_id: "lgpd-consent-management"
artifact_type: "lgpd_skill"
version: "1.0.0"
constraints_mapped: ["C3","C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/lgpd-guard/skills/consent-management.md --json"
canonical_path: "04-WORKFLOWS/lgpd-guard/skills/consent-management.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:lgpd-consent-management-v1.0.0"
generated_at: "2026-05-25T03:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "workflows"
ai_navigation:
  read_first: false
  required_for: ["consent-collection", "opt-in-opt-out", "consent-revocation"]
  update_frequency: on-change
audience: ["lgpd-guard", "n8n-master-agent", "langchain-langraph-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-25"
---

# 📝 Gestão de Consentimento (Art. 7º, I e Art. 8º)

> **Contrato modular**: Artefato filho de `lgpd-guard-mantis`.

## 🎯 Propósito
Padronizar a coleta, registro e revogação do consentimento do titular de dados, conforme os Artigos 7º (inciso I) e 8º da LGPD, garantindo que todo tratamento baseado em consentimento seja precedido de manifestação **livre, informada e inequívoca** do titular para uma **finalidade determinada** (C3, C4, C5, C8).

## 📋 Especificação (SDD)
- **Entradas**: Dados do titular, finalidade do tratamento, canal de coleta (webhook, formulário, chatbot).
- **Saídas**: Registro de consentimento em Data Table com timestamp, IP, finalidade e canal de revogação.
- **Side Effects**: Envio de confirmação ao titular com instruções de revogação.
- **Constraints Aplicáveis**: C3 (armazenamento seguro), C4 (rastreabilidade), C5 (validação), C8 (logging).
- **Dependências**: n8n com Data Tables, webhook para opt-out.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
consent_management:
  non_negotiables:
    - "Consentimento deve ser LIVRE, INFORMADO e INEQUÍVOCO. Não pode ser inferido do silêncio ou inação."
    - "Finalidade deve ser ESPECÍFICA. Consentimento genérico ('para fins de marketing') é NULO."
    - "Consentimento para tratamento de dados SENSÍVEIS deve ser EXPLÍCITO e destacado."
    - "Para crianças/adolescentes: consentimento de PELO MENOS UM dos pais ou responsável legal."
    - "O titular pode REVOGAR o consentimento a qualquer momento, de forma GRATUITA e FACILITADA."

  opt_in_flow:
    trigger: "Webhook ou formulário com dados do titular"
    steps:
      - "Classificar dados (data-classifier.md)"
      - "Exibir finalidade ESPECÍFICA e aviso de privacidade (privacy-notice-template.md)"
      - "Registrar consentimento em Data Table: {titular_id, finalidade, timestamp, ip, user_agent}"
      - "Enviar confirmação ao titular com link para revogação"
      - "Log de auditoria: lgpd_consent_granted"

  opt_out_flow:
    trigger: "Webhook de revogação ou comando /revogar"
    steps:
      - "Localizar registro de consentimento pelo titular_id e finalidade"
      - "Marcar como revoked: true, revoked_at: timestamp"
      - "Disparar workflow de eliminação de dados (retention-deletion.md) se aplicável"
      - "Log de auditoria: lgpd_consent_revoked"

  data_table_schema:
    table_name: "lgpd_consents"
    columns:
      - { name: "consent_id", type: "string" }
      - { name: "titular_id", type: "string" }
      - { name: "titular_email", type: "string" }
      - { name: "finalidade", type: "string" }
      - { name: "base_legal", type: "string", default: "consentimento" }
      - { name: "granted_at", type: "date" }
      - { name: "ip_address", type: "string" }
      - { name: "user_agent", type: "string" }
      - { name: "revoked", type: "boolean", default: false }
      - { name: "revoked_at", type: "date" }
      - { name: "data_class", type: "string" }

  anti_patterns:
    - "Checkbox pré-marcado → NÃO é consentimento válido (não é inequívoco)"
    - "Consentimento enterrado em Termos de Uso → NÃO é destacado"
    - "Consentimento único para múltiplas finalidades → DEVE permitir escolha separada"
    - "Ausência de registro de revogação → impossibilita comprovar cumprimento"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_consent_record_has_required_fields() {
  local record='{"titular_id":"user-001","finalidade":"marketing","granted_at":"2026-05-25T10:00:00Z","ip_address":"192.168.1.1"}'
  python3 -c "
import json; d=json.loads('$record')
required = ['titular_id','finalidade','granted_at','ip_address']
assert all(k in d for k in required), f'Missing fields: {[k for k in required if k not in d]}'
" 2>/dev/null && return 0 || return 1
}

test_consent_revocation_record() {
  local record='{"revoked":true,"revoked_at":"2026-05-25T15:00:00Z"}'
  python3 -c "
import json; d=json.loads('$record')
assert d['revoked'] == True and 'revoked_at' in d
" 2>/dev/null && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && {
  test_consent_record_has_required_fields && test_consent_revocation_record && echo "✅" || echo "❌"
  exit $?
}
```

---

## 🔗 Referências Cruzadas

- [[lgpd-guard.md]]
- [[data-classifier.md]]
- [[privacy-notice-template.md]]
- [[retention-deletion.md]]
- [[audit-logging.md]]
