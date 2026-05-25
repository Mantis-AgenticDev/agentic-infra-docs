---
artifact_id: "n8n-project-management-system"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C2","C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/project-management-system.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/project-management-system.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:project-management-system-v1.0.0"
generated_at: "2026-05-24T17:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["project-management", "telegram-bot", "construction-automation"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🏗️ Sistema de Gestão de Projetos com n8n + Telegram + Google Sheets

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar a construção de sistemas de gestão de tarefas e relatórios para projetos de construção civil usando n8n, Telegram Bot e Google Sheets, com coleta de status, fotos e GPS, garantindo rastreabilidade (C4), validação (C5) e observabilidade (C8).

## 📋 Especificação (SDD)
- **Entradas**: Configuração do bot Telegram, planilha Google Sheets com tarefas e trabalhadores.
- **Saídas**: Sistema automatizado de distribuição de tarefas, coleta de relatórios e dashboard gerencial.
- **Side Effects**: Envio de mensagens Telegram, escrita em Google Sheets, upload de fotos para Google Drive.
- **Constraints Aplicáveis**: C2 (declarativo), C4 (tenant/worker isolation), C5 (validação de dados), C8 (logging).
- **Dependências**: n8n, conta Telegram Bot, Google Sheets API, Google Drive API.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
project_management_system:
  architecture:
    components:
      manager_interface: "Google Sheets (cria tarefas, visualiza dashboard)"
      worker_interface: "Telegram Bot (recebe tarefas, envia respostas, fotos, GPS)"
      automation_engine: "n8n (orquestra fluxos, valida dados, atualiza planilhas)"
      storage: "Google Drive (armazena fotos dos relatórios)"

  telegram_bot_setup:
    step_1: "Criar bot via @BotFather no Telegram"
    step_2: "Obter token (ex: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz)"
    step_3: "Testar conexão: GET https://api.telegram.org/bot{TOKEN}/getMe"
    step_4: "Configurar webhook para n8n: POST /setWebhook?url=https://n8n-instance.com/webhook/telegram"

  google_sheets_structure:
    tasks_sheet:
      columns: ["Task_ID", "Project", "Object", "Section", "Task", "Executor", "Executor_ID",
                "Date", "Send_Time", "Priority", "Status", "Response", "Response_Time",
                "Photo_Link", "GPS_Lat", "GPS_Lon"]
    workers_sheet:
      columns: ["Name", "Role", "Telegram_ID", "Phone", "Registered"]
    photo_reports_sheet:
      columns: ["Report_ID", "Report_Type", "Executor", "Date", "Time", "Status", "Photo_Link", "Comment"]

  worker_commands:
    start: "Registrar trabalhador (nome, função, ID Telegram)"
    task_response: "Responder a tarefa com texto, foto e/ou GPS"
    photo_report: "Enviar relatório fotográfico periódico"

  workflow_templates:
    morning_distribution:
      trigger: "0 8 * * 1-6"  # 8:00 AM Seg-Sáb
      steps: ["get_today_tasks", "group_by_worker", "send_task_list"]
    photo_collection:
      trigger: "0 12,17 * * 1-6"  # 12:00 e 17:00
      steps: ["get_photo_reports", "send_photo_request"]
    end_of_day:
      trigger: "0 18 * * 1-6"  # 18:00
      steps: ["get_day_stats", "calculate_stats", "send_to_manager"]
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_telegram_bot_token_format() {
  local token="123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
  echo "$token" | grep -qE '^[0-9]+:[a-zA-Z0-9_-]+$' && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && { test_telegram_bot_token_format && echo "✅" || echo "❌"; exit $?; }
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[trigger-patterns.md]]
- [[http-request-patterns.md]]
- [[database-file-operations.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
