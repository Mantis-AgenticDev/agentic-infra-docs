---
artifact_id: "pipelines-reusable-workflows"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/reusable-workflows.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/reusable-workflows.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:reusable-workflows-v1.0.0"
generated_at: "2026-05-24T00:05:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["workflow-templates", "ci-cd-reuse"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔄 Workflows Reutilizáveis

> **Contrato modular**: Filho de `pipelines-master-agent-mantis`.

## 🎯 Propósito
Fornecer templates de workflows reutilizáveis para validação de agentes, deploy em VPS e rollback automático (C5).

## 📋 Especificação
- **Entradas**: Tipo de workflow (`agent-validation`, `vps-deploy`, `rollback`).
- **Saídas**: Arquivo YAML de workflow genérico.
- **Constraints Aplicáveis**: C5 (validação automatizada).

---

## 🛡️ Templates

### Validação de Agente
```yaml
name: Reusable Agent Validation
on:
  workflow_call:
    inputs:
      agent_path: { required: true, type: string }
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: bash orchestrator-engine.sh --file ${{ inputs.agent_path }} --strict
```

### Deploy em VPS
```yaml
name: Reusable VPS Deployment
on:
  workflow_call:
    inputs:
      compose_file: { required: true, type: string }
    secrets:
      ssh_key: { required: true }
      vps_host: { required: true }
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - uses: appleboy/scp-action@v0.1.7
        with:
          host: ${{ secrets.vps_host }}
          key: ${{ secrets.ssh_key }}
          source: ${{ inputs.compose_file }}
          target: /opt/mantis
      - uses: appleboy/ssh-action@v0.1.7
        with:
          host: ${{ secrets.vps_host }}
          key: ${{ secrets.ssh_key }}
          script: |
            cd /opt/mantis
            docker compose -f ${{ inputs.compose_file }} up -d --wait
```

### Rollback Automático
```yaml
- name: Rollback on failure
  if: failure()
  run: |
    kubectl rollout undo deployment/mantis-app
    curl -X POST $SLACK_WEBHOOK -H 'Content-type: application/json' \
      --data '{"text":"🔙 Rollback executado"}'
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_workflow_call_syntax() {
  local tmp; tmp=$(mktemp -d)
  cat > "$tmp/wf.yml" << 'EOF'
name: test
on: workflow_call
jobs:
  test:
    runs-on: ubuntu-latest
    steps: [run: echo ok]
EOF
  python3 -c "import yaml; yaml.safe_load(open('$tmp/wf.yml'))" && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_workflow_call_syntax && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[../github-actions-fundamentals.md]]
- [[../../docker-compose/libs/deployment-strategies.md]]
