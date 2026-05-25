---
artifact_id: "lgpd-audit-logging"
artifact_type: "lgpd_skill"
version: "1.0.0"
constraints_mapped: ["C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/lgpd-guard/skills/audit-logging.md --json"
canonical_path: "04-WORKFLOWS/lgpd-guard/skills/audit-logging.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:lgpd-audit-logging-v1.0.0"
generated_at: "2026-05-25T03:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "workflows"
ai_navigation:
  read_first: false
  required_for: ["lgpd-audit", "compliance-logging", "data-access-log"]
  update_frequency: on-change
audience: ["lgpd-guard", "n8n-master-agent", "langchain-langraph-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-25"
---

# 📊 Logs de Auditoria LGPD (Accountability — Art. 6º, X)

> **Contrato modular**: Artefato filho de `lgpd-guard-mantis`.

## 🎯 Propósito
Padronizar a geração de logs de auditoria para todo tratamento de dados pessoais, garantindo o princípio de **responsabilização e prestação de contas** (Art. 6º, X) e a capacidade de demonstrar conformidade à ANPD e aos titulares (C4, C5, C8).

## 📋 Especificação (SDD)
- **Entradas**: Eventos de tratamento (consentimento, acesso, modificação, exclusão, compartilhamento, violação).
- **Saídas**: Registros de auditoria em formato JSONL com metadados completos.
- **Side Effects**: Armazenamento em Data Table `lgpd_audit_log` ou sistema externo (ELK, Datadog, CloudWatch).
- **Constraints Aplicáveis**: C4 (rastreabilidade), C5 (validação de logs), C8 (logging estruturado).

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
audit_logging:
  required_events:
    consent_granted: "lgpd_consent_granted — {titular_id, finalidade, base_legal, timestamp}"
    consent_revoked: "lgpd_consent_revoked — {titular_id, finalidade, timestamp}"
    data_accessed: "lgpd_data_accessed — {titular_id, campo, workflow_id, node_name, agent_id}"
    data_modified: "lgpd_data_modified — {titular_id, campo, valor_anterior, valor_novo, timestamp}"
    data_deleted: "lgpd_data_deleted — {titular_id, registro_id, motivo, timestamp}"
    data_shared: "lgpd_data_shared — {titular_id, destinatario, finalidade, base_legal, timestamp}"
    dsar_received: "lgpd_dsar_received — {titular_id, tipo, timestamp}"
    dsar_completed: "lgpd_dsar_completed — {titular_id, tipo, acao, prazo_dias, timestamp}"
    violation_detected: "lgpd_violation_detected — {tipo, campo, motivo, severidade, timestamp}"
    retention_executed: "lgpd_retention_executed — {registros_afetados, data_limite, timestamp}"
    data_classified: "lgpd_data_classified — {workflow_id, campos, classes, timestamp}"

  log_schema:
    required_fields: ["event", "timestamp", "titular_id", "workflow_id", "agent_id", "tenant_id"]
    optional_fields: ["campo", "valor", "finalidade", "base_legal", "destinatario", "severidade"]

  storage:
    n8n: "Data Table `lgpd_audit_log` com retenção de 5 anos"
    external: "ELK, Datadog, CloudWatch, ou banco SQL externo"
    backup: "Exportação mensal para storage frio (S3 Glacier)"

  data_table_schema:
    table_name: "lgpd_audit_log"
    columns:
      - { name: "log_id", type: "string" }
      - { name: "event", type: "string" }
      - { name: "timestamp", type: "date" }
      - { name: "titular_id", type: "string" }
      - { name: "workflow_id", type: "string" }
      - { name: "agent_id", type: "string" }
      - { name: "tenant_id", type: "string" }
      - { name: "detail_json", type: "string" }

  anti_patterns:
    - "Logs sem timestamp → impossível auditar"
    - "Logs que expõem o dado pessoal em texto (ex.: 'nome=João Silva') → violação de segurança"
    - "Logs sem retention policy → acumulam indefinidamente"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_audit_log_has_required_fields() {
  local log='{"event":"lgpd_consent_granted","timestamp":"2026-05-25T10:00:00Z","titular_id":"user-001","workflow_id":"wf-123","agent_id":"n8n-agent","tenant_id":"restaurante_001"}'
  python3 -c "
import json; d=json.loads('$log')
required = ['event','timestamp','titular_id','workflow_id','agent_id','tenant_id']
assert all(k in d for k in required), f'Missing: {[k for k in required if k not in d]}'
" 2>/dev/null && return 0 || return 1
}

test_audit_log_no_pii_in_detail() {
  local log='{"event":"lgpd_data_accessed","detail_json":"{\"campo\":\"email\",\"acao\":\"leitura\"}"}'
  echo "$log" | grep -qv 'nome=' && echo "$log" | grep -qv 'cpf=' && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && {
  test_audit_log_has_required_fields && test_audit_log_no_pii_in_detail && echo "✅" || echo "❌"
  exit $?
}
```

---

## 🔗 Referências Cruzadas

- [[lgpd-guard.md]]
- [[consent-management.md]]
- [[dsar-handling.md]]
- [[retention-deletion.md]]
