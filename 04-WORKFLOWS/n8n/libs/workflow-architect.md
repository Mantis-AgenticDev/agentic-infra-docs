---
artifact_id: "n8n-workflow-architect"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C2","C4","C5","C6","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/workflow-architect.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/workflow-architect.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:workflow-architect-v1.0.0"
generated_at: "2026-05-24T18:50:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["automation-architecture", "stack-analysis", "production-readiness"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🏛️ Arquiteto de Automação — n8n vs Python vs Híbrido

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Fornecer uma matriz de decisão canônica para escolher entre n8n puro, Python/Claude Code ou arquitetura híbrida, com base na stack de serviços, volume de dados, complexidade e requisitos de manutenção, garantindo declaração (C2), rastreabilidade (C4), validação (C5), aprovação (C6) e qualidade (C8).

## 📋 Especificação (SDD)
- **Entradas**: Descrição da stack de negócio e requisitos de automação.
- **Saídas**: Recomendação fundamentada (n8n / Python / Híbrido) com plano de implementação.
- **Side Effects**: Definição da arquitetura de automação.
- **Constraints Aplicáveis**: C2, C4, C5, C6, C8.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
workflow_architect:
  philosophy: "Viabilidade sobre possibilidade. Construir sistemas que sobrevivam em produção."

  decision_tree:
    use_n8n:
      - "Autenticação OAuth necessária"
      - "Mantenedores não-técnicos"
      - "Processos multi-dia com waits"
      - "Integrações SaaS padrão"
      - "< 5.000 registros por execução"
      - "< 20 nós de lógica de negócio"
    use_python:
      - "> 5.000 registros para processar"
      - "Arquivos > 20MB"
      - "Algoritmos complexos (> 20 nós equivalentes)"
      - "Bibliotecas de IA de ponta"
      - "Transformações pesadas de dados (Pandas, NumPy)"
    use_hybrid:
      - "Mix dos casos acima"
      architecture: |
        n8n (Camada de Orquestração)
        ├── Webhooks & triggers
        ├── Autenticação OAuth
        ├── Integrações com usuários
        └── Coordenação de fluxo
            └── Chama Python Service (Camada de Processamento)
                ├── Computação pesada
                ├── Lógica complexa
                ├── Operações IA/ML
                └── Retorna resultados para n8n

  production_readiness:
    observability:
      - "Workflow de notificação de erro existe"
      - "Logging de execuções para banco de dados"
      - "Health check para caminhos críticos"
      - "Alertas estruturados por severidade"
    idempotency:
      - "Tratamento de webhooks duplicados"
      - "Padrões check-before-create"
      - "Chaves de idempotência para pagamentos"
      - "Capacidade de re-execução segura"
    cost_awareness:
      - "Custos de API de IA calculados e aprovados"
      - "Rate limits documentados"
      - "Estratégia de cache para chamadas repetidas"
      - "Modelo de IA adequado ao custo (Haiku vs Sonnet vs Opus)"
    operational_control:
      - "Kill switch acessível a não-técnicos"
      - "Filas de aprovação para ações de alto risco"
      - "Trilha de auditoria para todas as ações"
      - "Configuração externalizada"

  red_flags:
    - flag: "IA para tudo"
      risk: "Explosão de custos, imprevisibilidade"
      recommendation: "Escopo de IA para tarefas específicas, cache de resultados"
    - flag: "Milhões de registros"
      risk: "Crash por memória"
      recommendation: "Python com streaming, não loops em n8n"
    - flag: "Workflow com 50 nós"
      risk: "Impossível de manter"
      recommendation: "Consolidar em blocos de código ou dividir workflows"
    - flag: "Tratamento de erros depois"
      risk: "Falhas silenciosas"
      recommendation: "Construir tratamento de erros desde o dia um"

  common_scenarios:
    ecommerce: "Shopify + Klaviyo + Slack + Google Sheets → n8n puro"
    ai_lead_qualification: "Typeform + HubSpot + OpenAI + Scoring customizado → Híbrido"
    data_pipeline_etl: "PostgreSQL + BigQuery + 50k+ registros/dia → Python + n8n trigger"
    multi_step_approval: "Slack + Notion + Email + delays de 3 dias → n8n puro"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_decision_tree_complete() {
  local conditions_n8n=("OAuth" "non-technical" "multi-day" "SaaS" "<5000" "<20 nodes")
  local conditions_python=(">5000 records" ">20MB" "complex algorithm" "cutting-edge AI" "heavy transform")
  [[ "${#conditions_n8n[@]}" -eq 6 && "${#conditions_python[@]}" -eq 5 ]] && return 0 || return 1
}

test_red_flags_documented() {
  grep -q "IA para tudo" "$0" && grep -q "Milhões de registros" "$0" && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && {
  test_decision_tree_complete && test_red_flags_documented && echo "✅" || echo "❌"
  exit $?
}
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[mcp-orchestrator-core.md]]
- [[agentic-workflow-patterns.md]]
- [[self-hosting-patterns.md]]
- [[error-handling-patterns.md]]
- [[integration-testing-patterns.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
