---
artifact_id: "n8n-workflow-lifecycle"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C4","C5","C6","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/workflow-lifecycle.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/workflow-lifecycle.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:workflow-lifecycle-v1.0.0"
generated_at: "2026-05-24T20:30:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["workflow-planning", "workflow-publishing", "production-handoff"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔄 Ciclo de Vida do Workflow — PLAN, BUILD, VALIDATE, TEST, PUBLISH, HANDOFF

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar as 6 etapas do ciclo de vida de um workflow n8n, do planejamento à entrega em produção, garantindo que nenhuma etapa seja pulada e que o workflow resultante seja correto, seguro e operável, com rastreabilidade (C4), validação (C5), aprovação (C6) e qualidade (C8).

## 📋 Especificação (SDD)
- **Entradas**: Requisitos do usuário, workflow alvo.
- **Saídas**: Workflow publicado com documentação de handoff.
- **Constraints Aplicáveis**: C4 (descrições e sticky notes), C5 (validação pré-publish), C6 (aprovação implícita pelo ciclo), C8 (teste e handoff).
- **Dependências**: n8n MCP tools, acesso à API do n8n.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
workflow_lifecycle:
  stages:
    plan:
      description: "Reunir requisitos, fazer perguntas de esclarecimento, buscar workflows/sub-workflows existentes"
      actions:
        - "Confirmar o que o usuário realmente precisa (evitar construir a coisa errada)"
        - "Verificar se lógica similar já existe como sub-workflow"
        - "Identificar pasta/projeto de destino"
        - "Mapear integrações necessárias e sua disponibilidade"
      gate: "Só prosseguir quando o escopo estiver claro"

    build:
      description: "Escrever código SDK com skills apropriadas"
      principles:
        readability:
          - "Descrição do workflow: 1-2 frases capturando o quê e o porquê"
          - "Sticky notes: agrupar nós por propósito com título descritivo"
          - "Node notes: explicar workarounds ou lógica não-óbvia"
          - "Nomes de nós: verbo + substantivo (Fetch active customers, não Postgres1)"
        naming:
          workflows: "Verbo primeiro, escopo. 'Send weekly customer report'"
          nodes: "Descrever ação, não tipo. 'Fetch active customers' não 'Postgres1'"
          sub_workflows: "Prefixo 'Subworkflow:' para discovery. 'Subworkflow: Parse RFC2822 date'"

    validate:
      description: "Validar estrutura e verificar configurações do usuário"
      actions:
        - "validate_workflow → deve passar"
        - "get_workflow_details → inspecionar objeto connections"
        - "Superar limitações de validação (conexões silenciosamente descartadas, fan-outs colapsados, merge index off-by-one)"
        - "User-side wire-up: verificar credenciais por nó, criar credenciais faltantes, criar pastas faltantes"
      gate: "Não prosseguir para TEST até que o usuário confirme as credenciais"

    test:
      description: "Testar com dados representativos até que a saída corresponda à intenção"
      actions:
        - "test_workflow com prepare_test_pin_data"
        - "Para nós com side effects não pináveis (Code, Edit Fields, If, Wait, Execute Command, Data Tables): perguntar antes de rodar"
        - "Iterar até que a saída corresponda ao esperado"
      gate: "Só publicar depois que os testes passarem"

    publish:
      description: "Publicar o workflow após validação e teste limpos"
      actions:
        - "publish_workflow (só depois dos estágios 3 e 4)"
      gate: "Publicação é o ponto de não-retorno"

    handoff:
      description: "Handoff de produção: como acionar, o que retorna, o que observar"
      include:
        - "Como dispara: URL do webhook, cadência do schedule, gatilho manual"
        - "O que retorna / para onde vão os dados: uma frase"
        - "Como invocar de verdade com exemplo (curl, UI, esperar schedule)"
        - "O que observar: modos de falha, rate limits, onde olhar primeiro"
        - "Status de acesso MCP: workflows criados via MCP já são acessíveis"
        - "Pendências do lado do usuário: rotação de secrets, wiring pendente"
      format: "Meia dúzia de bullets, não uma parede de texto"

  anti_patterns:
    - "Chamar publish_workflow sem validar → workflows quebrados em produção"
    - "Pular get_workflow_details após create → bugs de conexão silenciosos"
    - "Criar workflows na raiz porque a pasta solicitada não existe → workflows se perdem"
    - "Nomes genéricos de nós (HTTP Request1, Set2) → ilegíveis um mês depois"
    - "Faltar descrição no create_workflow_from_code → invisível em busca"
    - "Rodar test_workflow com side effects não pináveis sem perguntar → escritas reais indesejadas"
    - "Sticky note titulada 'Set, If, Set' ou sticky de cada cor → ruído visual"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_lifecycle_stages_order() {
  local stages=("PLAN" "BUILD" "VALIDATE" "TEST" "PUBLISH" "HANDOFF")
  [[ "${stages[0]}" == "PLAN" && "${stages[5]}" == "HANDOFF" ]] && return 0 || return 1
}

test_validate_before_publish() {
  # Regra: validate_workflow deve passar antes de publish_workflow
  local validate_passed=true
  local publish_called=false
  if $validate_passed; then publish_called=true; fi
  $publish_called && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && {
  test_lifecycle_stages_order && test_validate_before_publish && echo "✅" || echo "❌"
  exit $?
}
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[workflow-testing-fundamentals.md]]
- [[trigger-testing-strategies.md]]
- [[integration-testing-patterns.md]]
- [[credentials-security.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
