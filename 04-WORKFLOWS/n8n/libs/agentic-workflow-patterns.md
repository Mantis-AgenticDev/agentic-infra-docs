---
artifact_id: "n8n-agentic-workflow-patterns"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C4","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/agentic-workflow-patterns.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/agentic-workflow-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:agentic-workflow-patterns-v1.0.0"
generated_at: "2026-05-24T14:40:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["agentic-orchestration", "multi-agent-workflows", "autonomous-loops"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧠 Padrões de Workflow Agêntico — Multi-Passo, Multi-Agente e Autônomos

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Definir padrões canônicos para orquestração de workflows agênticos com n8n e Claude Code, incluindo fluxos multi-passo, orquestração multi-agente e loops autônomos de monitoramento e remediação (C4, C5, C8).

## 📋 Especificação (SDD)
- **Entradas**: Descrição do cenário de automação, agentes envolvidos.
- **Saídas**: Diagrama de arquitetura e configuração de workflows n8n para cada padrão.
- **Side Effects**: Execução de workflows encadeados, invocação de múltiplos agentes IA.
- **Constraints Aplicáveis**: C4 (rastreabilidade de tenant), C5 (validação de sequências), C8 (logging de execuções).
- **Dependências**: Claude Code, n8n MCP Server/Client configurados.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
agentic_patterns:
  pattern_1_multi_step:
    name: "Processamento Multi-Passo com Agente"
    description: "Claude Code orquestra múltiplos workflows n8n em sequência lógica"
    scenario: "Processamento de ticket de suporte"
    steps:
      - agent_action: "Criar ticket"
        mcp_call: "create_support_ticket(issue_type='login')"
        n8n_workflow: "Cria ticket Jira, notifica Slack, retorna ID"
      - agent_action: "Buscar soluções"
        mcp_call: "search_knowledge_base(query='login issues')"
        n8n_workflow: "Consulta docs internos e tickets passados"
      - agent_action: "Analisar e sugerir"
        mcp_call: "update_ticket(id, suggested_solution)"
        n8n_workflow: "Atualiza Jira, notifica cliente"

  pattern_2_multi_agent:
    name: "Orquestração Multi-Agente"
    description: "Agente orquestrador coordena múltiplos agentes especialistas"
    scenario: "Pipeline de criação de conteúdo"
    agents:
      research_agent: "Coleta dados via n8n: gather_data"
      writing_agent: "Gera conteúdo via n8n: generate_content"
      seo_agent: "Otimiza para busca via n8n: optimize_for_search"
    final_workflow: "n8n publica conteúdo, faz upload de imagens, notifica equipe"

  pattern_3_autonomous_loop:
    name: "Loop Autônomo de Monitoramento"
    description: "Monitoramento contínuo com remediação automática"
    scenario: "Verificação de saúde do sistema a cada 5 minutos"
    flow: |
      n8n Schedule Trigger → Check metrics → Anomaly? 
        → YES: MCP call to Claude → Claude analyzes → Claude calls execute_remediation()
        → NO: Wait for next cycle
    remediation_actions:
      - "Reiniciar serviço"
      - "Escalar recursos"
      - "Limpar cache"
      - "Criar ticket de incidente"
      - "Alertar engenheiro de plantão"

  pattern_4_event_driven:
    name: "Arquitetura Orientada a Eventos"
    description: "Eventos externos disparam fluxos agênticos"
    scenario: "Pagamento Stripe recebido"
    flow: |
      Stripe Webhook → n8n Webhook Trigger → MCP Call: analyze_payment_risk()
      Claude analisa risco → Retorna score
      n8n roteia: risco > 0.7 → revisão manual; caso contrário → aprovação automática

  pattern_5_human_in_the_loop:
    name: "Humano no Circuito"
    description: "Agente IA prepara, humano aprova"
    scenario: "Resposta de email redigida por IA"
    flow: |
      Claude redige resposta → MCP Call: request_human_approval(draft)
      n8n envia para gerente via Slack → Aguarda aprovação (webhook)
      Aprovado → Claude envia email final

  pattern_6_multi_modal:
    name: "Processamento Multi-Modal"
    description: "Combinação de visão, texto e ação"
    scenario: "Upload de imagem pelo usuário"
    flow: |
      User uploads image → Claude analisa (OCR, objetos, ações)
      Para cada item de ação → n8n MCP Tool: create_task, send_notification, update_dashboard
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_agentic_patterns_documented() {
  grep -q "pattern_1_multi_step" "$0" && \
  grep -q "pattern_2_multi_agent" "$0" && \
  grep -q "pattern_3_autonomous_loop" "$0" && \
  return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && { test_agentic_patterns_documented && echo "✅" || echo "❌"; exit $?; }
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[mcp-orchestrator-core.md]]
- [[n8n-mcp-server-patterns.md]]
- [[claude-code-integration.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
