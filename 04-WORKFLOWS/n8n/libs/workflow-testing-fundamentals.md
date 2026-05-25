---
artifact_id: "n8n-workflow-testing-fundamentals"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/workflow-testing-fundamentals.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/workflow-testing-fundamentals.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:workflow-testing-fundamentals-v1.0.0"
generated_at: "2026-05-24T20:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["workflow-testing", "execution-validation", "data-flow-tracing"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🧪 Fundamentos de Teste de Workflows n8n

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar a validação completa de workflows n8n: estrutura (nós órfãos, credenciais, trigger), execução com dados realistas, rastreamento de fluxo de dados entre nós, cenários de erro e medição de performance, garantindo validação (C5) e observabilidade (C8).

## 📋 Especificação (SDD)
- **Entradas**: Workflow ID, casos de teste com entradas e saídas esperadas.
- **Saídas**: Relatório de teste com status por caso, dados reais de saída, métricas de execução.
- **Side Effects**: Execução real do workflow em ambiente de teste (nós com side effects devem ser pinados).
- **Constraints Aplicáveis**: C5 (validação), C8 (logging e métricas).
- **Dependências**: n8n API, workflow alvo em estado ativo.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
workflow_testing:
  structure_validation:
    description: "Validar a integridade estrutural do workflow antes da execução"
    checks:
      trigger_presence: "Todo workflow deve ter um nó trigger (Webhook, Schedule, etc.)"
      orphan_nodes: "Detectar nós sem conexões de entrada ou saída"
      credential_existence: "Verificar que todas as credenciais referenciadas existem"
      connection_integrity: "Validar que source e target de cada conexão existem"
    code_pattern: |
      const triggerNode = workflow.nodes.find(n => n.type.includes('trigger') || n.type.includes('webhook'));
      if (!triggerNode) throw new Error('Workflow must have a trigger node');
      const connectedNodes = new Set();
      for (const [source, targets] of Object.entries(workflow.connections)) {
        connectedNodes.add(source);
        for (const outputs of Object.values(targets)) {
          for (const connections of outputs) {
            for (const conn of connections) connectedNodes.add(conn.node);
          }
        }
      }
      const orphans = workflow.nodes.filter(n => !connectedNodes.has(n.name));

  execution_testing:
    description: "Executar workflow com dados de teste realistas e validar saídas"
    test_case_structure:
      name: "Descrição do cenário"
      input: "Dados de entrada (payload do trigger)"
      expected: "Saída esperada (objeto ou regex)"
      timeout: "Timeout em ms (default 30000)"
    validation_flow: |
      const execution = await executeWorkflow(workflowId, testCase.input);
      const result = await waitForCompletion(execution.id, testCase.timeout);
      const outputValid = validateOutput(result.data, testCase.expected);

  data_flow_tracing:
    description: "Rastrear dados através de cada nó na execução"
    trace_structure:
      - "Para cada nó, capturar: input, output, executionTime, status"
      - "Validar mapeamento de dados entre nós consecutivos"
      - "Detectar campos ausentes no mapeamento"
    code_pattern: |
      for (const [nodeName, runs] of Object.entries(execution.data.resultData.runData)) {
        for (const run of runs) {
          dataFlow.push({
            node: nodeName,
            input: run.data?.main?.[0]?.[0]?.json || {},
            output: run.data?.main?.[0]?.[0]?.json || {},
            executionTime: run.executionTime,
            status: run.executionStatus
          });
        }
      }

  error_handling_testing:
    description: "Testar cenários de erro e verificar tratamento"
    scenarios:
      timeout: { inject: { delay: 35000 }, expectedError: 'timeout' }
      invalid_data: { inject: { invalidField: true }, expectedError: 'validation' }
      missing_credentials: { inject: { removeCredentials: true }, expectedError: 'authentication' }
    checks:
      - "Erro foi capturado (execution.status === 'failed')"
      - "Error workflow foi disparado"
      - "Alerta foi enviado (Slack, Email)"

  test_data_generators:
    webhook: |
      { body: { event: 'test', timestamp: new Date().toISOString() },
        headers: { 'Content-Type': 'application/json' },
        query: { source: 'test' } }
    slack: |
      { type: 'message', channel: 'C123456', user: 'U789012', text: 'Test message' }
    github: |
      { action: 'opened', issue: { number: 1, title: 'Test Issue', body: 'Test body' },
        repository: { full_name: 'test/repo' } }
    stripe: |
      { type: 'payment_intent.succeeded',
        data: { object: { id: 'pi_test123', amount: 1000, currency: 'usd' } } }

  execution_assertions:
    completed: "execution.finished === true && execution.status === 'success'"
    node_executed: "execution.data.resultData.runData[nodeName][0].executionStatus === 'success'"
    data_transformed: "nodeOutput matches expectedData (partial match)"
    execution_time: "duration < maxMs"

  quick_checklist:
    - "Todos os nós estão conectados (sem órfãos)"
    - "Nó trigger está configurado corretamente"
    - "Mapeamentos de dados entre nós são válidos"
    - "Workflows de erro estão definidos"
    - "Credenciais estão referenciadas corretamente"
    - "Testar cada caminho de execução separadamente"
    - "Validar transformações de dados em cada nó"
    - "Verificar comportamento de retry e tratamento de erros"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_trigger_presence_check() {
  local workflow='{"nodes":[{"type":"n8n-nodes-base.webhook","name":"Webhook"}],"connections":{}}'
  python3 -c "
import json; d=json.loads('$workflow')
has_trigger = any('trigger' in n.get('type','') or 'webhook' in n.get('type','') for n in d['nodes'])
assert has_trigger, 'No trigger node found'
" 2>/dev/null && return 0 || return 1
}

test_orphan_detection() {
  local workflow='{"nodes":[{"name":"A"},{"name":"B"}],"connections":{"A":{"main":[[{"node":"B"}]]}}}'
  python3 -c "
import json; d=json.loads('$workflow')
connected = set()
for src, targets in d.get('connections',{}).items():
    connected.add(src)
    for outputs in targets.values():
        for conns in outputs:
            for c in conns: connected.add(c['node'])
orphans = [n['name'] for n in d['nodes'] if n['name'] not in connected]
assert len(orphans) == 0, f'Orphan nodes: {orphans}'
" 2>/dev/null && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && {
  test_trigger_presence_check && test_orphan_detection && echo "✅" || echo "❌"
  exit $?
}
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[integration-testing-patterns.md]]
- [[error-handling-patterns.md]]
- [[trigger-testing-strategies.md]]
- [[/05-CONFIGURATIONS/validation/norms-matrix.json]]
