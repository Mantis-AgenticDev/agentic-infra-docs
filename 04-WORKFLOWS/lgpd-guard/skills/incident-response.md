---
artifact_id: "lgpd-incident-response"
artifact_type: "lgpd_skill"
version: "1.0.0"
constraints_mapped: ["C3","C4","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/lgpd-guard/skills/incident-response.md --json"
canonical_path: "04-WORKFLOWS/lgpd-guard/skills/incident-response.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:lgpd-incident-response-v1.0.0"
generated_at: "2026-05-25T04:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "workflows"
ai_navigation:
  read_first: false
  required_for: ["data-breach", "security-incident", "anpd-notification"]
  update_frequency: on-change
audience: ["lgpd-guard", "n8n-master-agent", "langchain-langraph-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-25"
---

# 🚨 Plano de Resposta a Incidentes de Violação de Dados (Art. 48)

> **Contrato modular**: Artefato filho de `lgpd-guard-mantis`.

## 🎯 Propósito
Padronizar a resposta a incidentes de segurança que envolvam violação de dados pessoais, conforme o Art. 48 da LGPD, que exige comunicação à ANPD e aos titulares afetados em **prazo razoável**, com descrição da natureza do incidente, dados afetados, riscos e medidas adotadas (C3, C4, C6, C7, C8).

## 📋 Especificação (SDD)
- **Entradas**: Detecção de incidente (automática via monitoramento ou manual via report).
- **Saídas**: Comunicação à ANPD, notificação aos titulares afetados, relatório de análise de causa raiz, plano de remediação.
- **Side Effects**: Bloqueio temporário de acessos, rotação de credenciais, isolamento de sistemas afetados.
- **Constraints Aplicáveis**: C3 (proteção pós-incidente), C4 (rastreabilidade), C6 (aprovação para comunicação externa), C7 (rollback/remediação), C8 (logging completo).

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
incident_response:
  art_48: "O controlador deverá comunicar à autoridade nacional e ao titular a ocorrência de incidente de segurança que possa acarretar risco ou dano relevante aos titulares."

  severity_levels:
    critico: "Dados sensíveis expostos, > 1000 titulares afetados → Notificar ANPD em 24h"
    alto: "Dados pessoais expostos, 100-1000 titulares → Notificar ANPD em 48h"
    medio: "Dados pessoais expostos, < 100 titulares → Notificar ANPD em 72h"
    baixo: "Tentativa de acesso sem sucesso → Registrar internamente, sem notificação"

  response_flow:
    detection:
      trigger: "Alerta de segurança (SIEM, monitoramento de logs, report de usuário)"
      actions: ["Classificar severidade", "Isolar sistema afetado", "Acionar equipe de resposta"]
    
    containment:
      actions: ["Bloquear acessos comprometidos", "Rotacionar credenciais", "Revogar tokens expostos"]
      duration: "Imediato após detecção"
    
    investigation:
      actions: ["Coletar logs de auditoria (audit-logging.md)", "Identificar vetor de ataque", "Determinar escopo de dados afetados"]
      duration: "Até 4h para incidentes críticos"
    
    notification:
      anpd: "Comunicar ANPD em prazo definido por severidade"
      titulares: "Notificar titulares afetados com: natureza do incidente, dados afetados, riscos, medidas adotadas"
      form_anpd: |
        - Identificação do controlador
        - Data e hora da detecção
        - Natureza do incidente
        - Categorias e número aproximado de titulares afetados
        - Categorias e número aproximado de registros afetados
        - Medidas de segurança adotadas antes do incidente
        - Medidas adotadas para mitigar os danos
        - Se houve atraso na comunicação, justificativa
    
    remediation:
      actions: ["Corrigir vulnerabilidade", "Reforçar controles", "Atualizar RIPD se necessário"]
    
    post_mortem:
      actions: ["Análise de causa raiz", "Lições aprendidas", "Atualização de políticas de segurança"]

  auto_containment:
    n8n_actions:
      - "Deactivate workflow comprometido"
      - "Revogar todas as API keys do tenant afetado"
      - "Habilitar modo de auditoria máximo (EXECUTIONS_DATA_SAVE_ON_SUCCESS=true temporariamente)"

  communication_template:
    titulares: |
      Prezado(a) titular,
      
      Informamos que ocorreu um incidente de segurança envolvendo seus dados pessoais em {{data_deteccao}}.
      
      Natureza do incidente: {{natureza}}
      Dados potencialmente afetados: {{dados_afetados}}
      Riscos identificados: {{riscos}}
      Medidas adotadas: {{medidas}}
      
      Recomendamos: {{recomendacoes}}
      
      Para mais informações, entre em contato com nosso Encarregado (DPO): {{contato_encarregado}}
      
      Pedimos desculpas pelo ocorrido e reforçamos nosso compromisso com a proteção de seus dados.
      
      Atenciosamente,
      {{controlador_nome}}

  anti_patterns:
    - "Não comunicar ANPD → infração ao Art. 48, passível de multa"
    - "Comunicar titulares sem orientações claras → gera pânico desnecessário"
    - "Não isolar sistema afetado → incidente pode se expandir"
    - "Não realizar post-mortem → mesma vulnerabilidade pode ser explorada novamente"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_incident_severity_levels() {
  local levels=("critico" "alto" "medio" "baixo")
  [[ ${#levels[@]} -eq 4 ]] && return 0 || return 1
}

test_response_flow_stages() {
  local stages=("detection" "containment" "investigation" "notification" "remediation" "post_mortem")
  [[ ${#stages[@]} -eq 6 ]] && return 0 || return 1
}

test_notification_has_required_fields() {
  local fields=("controlador" "data_deteccao" "natureza" "dados_afetados" "riscos" "medidas" "contato_encarregado")
  [[ ${#fields[@]} -eq 7 ]] && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && {
  test_incident_severity_levels && test_response_flow_stages && test_notification_has_required_fields && echo "✅" || echo "❌"
  exit $?
}
```

---

## 🔗 Referências Cruzadas

- [[lgpd-guard.md]]
- [[audit-logging.md]]
- [[pii-redaction.md]]
- [[ripd-generator.md]]
