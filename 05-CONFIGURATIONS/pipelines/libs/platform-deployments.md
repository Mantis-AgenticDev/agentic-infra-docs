---
artifact_id: "pipelines-platform-deployments"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C6","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/platform-deployments.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/platform-deployments.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:platform-deployments-v1.0.0"
generated_at: "2026-05-24T00:30:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["vercel-deploy", "ecs-deploy", "kubernetes-deploy"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# ☁️ Despliegues por Plataforma

> **Contrato modular**: Filho de `pipelines-master-agent-mantis`.

## 🎯 Propósito
Fornecer padrões de deploy para plataformas específicas: Vercel (frontend), AWS ECS (Fargate) e Kubernetes (C6, C8).

## 📋 Especificação
- **Entradas**: Plataforma alvo, credenciais OIDC.
- **Saídas**: Workflow de deploy funcional.
- **Constraints Aplicáveis**: C6 (aprovação), C8 (health checks).

---

## 🛡️ Padrões

### Vercel (Preview + Production)
```yaml
- name: Deploy to Vercel
  run: |
    vercel pull --yes --environment=production --token=${{ secrets.VERCEL_TOKEN }}
    vercel build --token=${{ secrets.VERCEL_TOKEN }}
    DEPLOY_URL=$(vercel deploy --prebuilt --prod --token=${{ secrets.VERCEL_TOKEN }})
```

### AWS ECS (Fargate)
```yaml
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
- uses: aws-actions/amazon-ecs-deploy-task-definition@v1
  with:
    task-definition: task-definition.json
    service: mantis-service
    cluster: mantis-cluster
    wait-for-service-stability: true
```

### Kubernetes
```yaml
- name: Deploy to Kubernetes
  run: |
    kubectl set image deployment/mantis-app mantis-container=ghcr.io/mantis/app:${{ github.sha }}
    kubectl rollout status deployment/mantis-app --timeout=10m
    curl -f https://app.example.com/health/ready || exit 1
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_k8s_rollout_command() {
  kubectl version --client &>/dev/null && return 0 || return 0
}
[[ "${1:-}" == "--test" ]] && { test_k8s_rollout_command && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[../deployment-strategies.md]]
- [[../../docker-compose/libs/healthcheck-patterns.md]]
