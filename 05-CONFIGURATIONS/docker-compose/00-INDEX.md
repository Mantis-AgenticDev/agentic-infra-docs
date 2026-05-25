---
artifact_id: "docker-compose-00-index"
artifact_type: "index"
version: "2.3.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
canonical_path: "05-CONFIGURATIONS/docker-compose/00-INDEX.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:docker-compose-index-v2.3.0"
generated_at: "2026-05-23T21:00:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "docker-compose"
ai_navigation:
  read_first: true
  required_for: ["docker-compose-domain-navigation", "skill-discovery"]
  update_frequency: on-change
  compatible_models: ["qwen","deepseek","claude","minimax","mimo-xiaomi","gpt-4","gemini"]
audience: ["docker-compose-master-agent","orchestrator-engine","human-architects","ai-agents"]
status: "✅ Estável"
next_review: "2026-06-23"
license: "CC-BY-NC-SA-4.0"
---

# 📚 00-INDEX — Domínio Docker Compose MANTIS Agentic v2.3.0

> **Propósito**: Índice canônico do domínio `05-CONFIGURATIONS/docker-compose/`. Lista todos os artefatos, skills e documentação, servindo como ponto de entrada para IAs e desenvolvedores.

---

## 🧠 Agente Mestre

| Artefato | Descrição | Tier |
|----------|-----------|------|
| [[docker-compose-master-agent.md]] | Framework executável de orquestração de contêineres. Herda hardening, observability e constraints C1-C9. Referencia skills em `libs/` sob demanda. | 1 |

---

## 📦 Skills Modulares (`libs/`)

> **Filosofia modular**: Cada skill contém APENAS a lógica de domínio específica. Hardening, observability e constraints são herdados do Master Agent.

| Skill | Propósito | Constraints |
|-------|-----------|-------------|
| [[libs/00-INDEX.md]] | Índice de skills disponíveis | C5 |
| [[libs/base-service-template.md]] | Plantilla YAML reutilizável (`x-service-base`) | C1, C2, C7 |
| [[libs/healthcheck-patterns.md]] | Coleção de health checks por tecnologia | C8 |
| [[libs/network-patterns.md]] | Estratégias de redes, isolamento, service discovery | C2, V1 |
| [[libs/volume-patterns.md]] | Padrões de volumes, tmpfs, persistência | C1, C2 |
| [[libs/security-patterns.md]] | Usuário non-root, capacidades, secrets, read-only | C3 |
| [[libs/deployment-strategies.md]] | Rolling updates, blue-green, canary, rollback | C6, C7 |
| [[libs/image-building.md]] | Multi-stage builds, otimização de cache, .dockerignore | C1, C5 |
| [[libs/logging-observability.md]] | Configuração de logging, métricas, labels OCI | C8 |
| [[libs/environment-strategies.md]] | Múltiplos ambientes, .env, compose.override | C2, C6 |
| [[libs/troubleshooting.md]] | Comandos de diagnóstico e resolução de problemas | C8 |
| [[libs/validation-scripts.md]] | Referência aos validadores e seu uso | C5 |

### 📐 Stack Templates (`libs/stack-templates/`)

| Template | Descrição |
|----------|-----------|
| [[libs/stack-templates/full-stack-mantis.md]] | Stack completo: proxy, backend, DB, Redis, pgvector |
| [[libs/stack-templates/microservices-messaging.md]] | Microserviços com Traefik, RabbitMQ |

### 📘 Referências (`libs/references/`)

| Referência | Descrição |
|------------|-----------|
| [[libs/references/security-checklist.md]] | Guia de segurança para imagens e contêineres |
| [[libs/references/optimization-guide.md]] | Otimização de builds e tamanho de imagem |
| [[libs/references/docker-best-practices.md]] | Melhores práticas gerais de Docker |

---

## 🗂️ Arquivos Compose de Produção

| Arquivo | VPS | Serviços |
|---------|-----|----------|
| [[vps1-n8n-uazapi.yml]] | VPS1 (KVM1/KVM2) | n8n, uazapi, Redis, Traefik, OTEL |
| [[vps2-crm-qdrant.yml]] | VPS2 (KVM1/KVM2) | EspoCRM, MySQL, Qdrant, Traefik, OTEL |
| [[vps3-n8n-uazapi.yml]] | VPS3 (KVM1/KVM2) | n8n (failover), uazapi, Redis, Traefik, OTEL |

---

## 📖 Documentação

| Arquivo | Descrição |
|---------|-----------|
| [[docs/CHANGELOG.md]] | Histórico de alterações nos stacks |
| [[docs/README-deployment.md]] | Guia de deploy e operações |

---

## 🌐 Rede e Interconexão VPS

A documentação completa da rede 3-VPS, túneis SSH e fluxo de tráfego está no índice raiz do domínio:

- [[../00-INDEX.md]] — Índice mestre de `05-CONFIGURATIONS/`
- [[../interface-spec.yaml]] — Especificação de interfaces do domínio

---

## ✅ Validação

| Artefato | Descrição |
|----------|-----------|
| [[../validation/orchestrator-engine.sh]] | Motor de validação canônica |
| [[../validation/norms-matrix.json]] | Mapeamento constraints por rota |
| [[../validation/audit-secrets.sh]] | Scanner de secrets (C3) |
| [[../validation/validate-skill-integrity.sh]] | Validador de integridade de skills |

---

## 🔗 Referências Cruzadas

- [[01-RULES/harness-norms-v3.0.md]] — Hardening padrão
- [[01-RULES/10-SDD-CONSTRAINTS.md]] — Constraints executáveis
- [[01-RULES/11-A2A-COMMUNICATION-RULES.md]] — Contrato A2A (C9)
- [[goals/README.md]] — Sistema de metas
- [[goals/libs/registry_client.py]] — Cliente do registro central

---

> **Versão 2.3.0** — Índice refatorado para arquitetura modular. Skills extraídas para `libs/`. Agente mestre simplificado. 2026-05-23.
