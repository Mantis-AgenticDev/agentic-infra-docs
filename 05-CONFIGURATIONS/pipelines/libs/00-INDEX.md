---
artifact_id: "pipelines-libs-index"
artifact_type: "index"
version: "1.0.0"
constraints_mapped: ["C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/00-INDEX.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/00-INDEX.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:pipelines-libs-index-v1.0.0"
generated_at: "2026-05-23T23:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: true
  required_for: ["pipelines-skill-loading", "pipelines-agent-modular"]
  update_frequency: on-change
audience: ["pipelines-master-agent", "orchestrator-engine"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 📚 Índice de Skills — pipelines/libs/

| Skill | Propósito | Constraints |
|-------|-----------|-------------|
| [[github-actions-fundamentals.md]] | Fundamentos de workflows, tipos de steps, gestión de secretos/variables | C3, C5 |
| [[deployment-strategies.md]] | Rolling, blue-green, canary, feature flags, rollback | C6, C7, C8 |
| [[security-patterns.md]] | Secrets, OIDC, pinning SHA, permisos mínimos, inyección | C3 |
| [[terraform-integration.md]] | Módulos Terraform, validation blocks, outputs con tenant isolation | C1, C4, V1-V3 |
| [[docker-compose-integration.md]] | Estructura Compose por entorno, health checks, multi-arch builds | C8 |
| [[promptfoo-quality.md]] | Configuración promptfoo, casos de prueba, aserciones | C5, C8 |
| [[semantic-release.md]] | Versionado semántico, changelog, convenciones de commit | C1, C4 |
| [[metrics-dora.md]] | Métricas DORA, dashboards Prometheus, rollback por métricas | C8 |
| [[monorepo-patterns.md]] | Detección de paquetes afectados, cache compartido | C2, C5 |
| [[performance-optimization.md]] | Caching multi-nivel, paralelismo, políticas de eviction MoE | C1, C2 |
| [[reusable-workflows.md]] | Plantillas reutilizables (agent validation, VPS deploy, rollback) | C5 |
| [[ansible-provisioning.md]] | Provisionamiento de VPS con Ansible + Terraform | C1, C2 |
| [[best-practices-anti-patterns.md]] | DO/DON'T, resiliencia, retry con backoff | C7 |
| [[advanced-patterns.md]] | Dynamic matrix, composite actions, self-hosted runners | C2 |
| [[platform-deployments.md]] | Despliegues a Vercel, ECS, Kubernetes | C6, C8 |
| [[tdd-migration-pipeline.md]] | Pipeline de migración TDD zero-context | C5, C8 |
| [[opensource-pipeline.md]] | Sanitización segura para open-source | C3, C5 |
| [[rfc-decomposition.md]] | Descomposición de features complejas en DAG | C6 |
| [[pipeline-review.md]] | Comando /pipeline-review, salud y priorización | C8 |
| [[deployment-design.md]] | Diseño de pipelines multi-etapa, health checks shallow/deep | C7, C8 |
| [[gitlab-ci-patterns.md]] | Alternativas GitLab CI, MR review | C5 |
| [[data-etl-pipeline.md]] | Pipelines de datos con n8n, ETL, monitoreo | C8 |
| [[constraints-mapping.md]] | Mapeo de constraints C1-C8, V1-V3 en pipelines | C5 |
| [[troubleshooting.md]] | Solución de problemas comunes en pipelines | C8 |
| [[validation-commands.md]] | Comandos de validación del dominio pipelines | C5 |

> **Nota**: Varias skills de [[../../docker-compose/libs/00-INDEX.md|docker-compose/libs/]] son referenciadas directamente para evitar duplicación (seguridad, health checks, troubleshooting, validación).
