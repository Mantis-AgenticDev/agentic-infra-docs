---
artifact_id: "configurations-libs-index"
artifact_type: "index"
version: "1.0.0"
constraints_mapped: ["C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/configurations/libs/00-INDEX.md --json"
canonical_path: "05-CONFIGURATIONS/configurations/libs/00-INDEX.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:config-libs-index-v1.0.0"
generated_at: "2026-05-24T08:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "configurations"
ai_navigation:
  read_first: true
  required_for: ["configurations-ceo-skill-loading", "configurations-governance"]
  update_frequency: on-change
audience: ["configurations-ceo", "orchestrator-engine"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 📚 Índice de Skills — configurations/libs/

| Skill | Propósito | Constraints |
|-------|-----------|-------------|
| [[template-standards.md]] | Versionado, uso y personalización de plantillas | C1, C2, C5 |
| [[script-standards.md]] | Estándar de scripting (plantilla, buenas prácticas) | C5, C7, C8 |
| [[environment-standards.md]] | Gestión de variables de entorno, `mapping.yaml`, secrets | C3, C4, C5 |
| [[observability-standards.md]] | Métricas obligatorias, dashboards, alertas, health endpoints | C8 |
| [[multi-agent-orchestration.md]] | Flujo de despliegue, dependencias, delegación `Task()` | C6, C7, C8 |
| [[project-management.md]] | Priorización RICE, roadmap, ADR, reportes SitRep | C5, C6 |
| [[stakeholder-communication.md]] | Mapa de stakeholders, protocolos de comunicación | C6 |
| [[agent-profiling.md]] | Perfilado de rendimiento y optimización multi-agente | C8 |
| [[agent-registry-format.md]] | Formato de entradas en `00-STACK-SELECTOR.md` | C5 |
| [[constraints-mapping.md]] | Mapeamento de constraints aplicadas à coordenação | C5 |
| [[templates/adr-template.md]] | Plantilla de Architecture Decision Record | C5 |
| [[templates/sitrep-template.md]] | Plantilla de reporte semanal (SitRep) | C5 |
| [[templates/script-template.sh]] | Plantilla de script bash estandarizado | C5 |
| [[templates/roadmap-template.md]] | Plantilla de roadmap trimestral | C5 |
| [[troubleshooting.md]] | Diagnóstico de problemas comuns na coordenação | C8 |

> **Nota**: Skills de segurança e validação podem referenciar [[../../docker-compose/libs/security-patterns.md]] e [[../../pipelines/libs/security-patterns.md]].
