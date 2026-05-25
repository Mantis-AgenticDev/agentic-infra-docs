---
artifact_id: "docker-compose-libs-index"
artifact_type: "index"
version: "1.0.0"
constraints_mapped: ["C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/docker-compose/libs/00-INDEX.md --json"
canonical_path: "05-CONFIGURATIONS/docker-compose/libs/00-INDEX.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:docker-compose-libs-index-v1.0.0"
generated_at: "2026-05-23T18:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "docker-compose"
ai_navigation:
  read_first: true
  required_for: ["docker-compose-skill-loading", "docker-compose-agent-modular"]
  update_frequency: on-change
audience: ["docker-compose-master-agent", "orchestrator-engine"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# 📚 Índice de Skills — docker-compose/libs/

| Skill | Propósito | Constraints |
|-------|-----------|-------------|
| [[base-service-template.md]] | Plantilla YAML reutilizable (`x-service-base`) para todos los servicios | C1, C2, C7 |
| [[healthcheck-patterns.md]] | Colección de health checks por tecnología | C8 |
| [[network-patterns.md]] | Estrategias de redes, aislamiento, service discovery | C2, V1 |
| [[volume-patterns.md]] | Patrones de volúmenes, tmpfs, external, persistencia | C1, C2 |
| [[security-patterns.md]] | Usuario non-root, capacidades, secrets, read-only | C3 |
| [[deployment-strategies.md]] | Rolling updates, blue-green, canary, rollback | C6, C7 |
| [[image-building.md]] | Multi-stage builds, optimización de caché, .dockerignore | C1, C5 |
| [[logging-observability.md]] | Configuración de logging, métricas, labels OCI | C8 |
| [[environment-strategies.md]] | Múltiples entornos, .env, compose.override | C2, C6 |
| [[troubleshooting.md]] | Comandos de diagnóstico y resolución de problemas | C8 |
| [[validation-scripts.md]] | Referencia a los validators y su uso | C5 |
| [[stack-templates/full-stack-mantis.md]] | Stack completo: proxy, backend, DB, Redis, pgvector | C1-C8, V1-V3 |
| [[stack-templates/microservices-messaging.md]] | Microservicios con Traefik, RabbitMQ | C1-C8 |
| [[references/security-checklist.md]] | Guía de seguridad para imágenes/contenedores | C3 |
| [[references/optimization-guide.md]] | Optimización de builds y tamaño de imagen | C5 |
| [[references/docker-best-practices.md]] | Mejores prácticas generales de Docker | C5 |
