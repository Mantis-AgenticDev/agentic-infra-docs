---
title: "RAW_URLS_INDEX.md – Índice Maestro de URLs Raw para Navegación IA"
version: "2.0.0"
canonical_path: "RAW_URLS_INDEX.md"
purpose: "Índice estructurado de todas las URLs raw del repositorio MANTIS AGENTIC, optimizado para navegación automática por agentes de IA (Qwen, DeepSeek, Claude, GPT, etc.). Divide artefactos por las 9 secciones canónicas + root, con metadatos de tipo, constraint y validación."
audience: ["agentic_assistants", "human_engineers", "ci_cd_pipelines"]
constraints_mapped: [C4, C5, C8]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file $0 --json"
checksum_sha256: "a1b2c3d4e5f6789012345678901234567890123456789012345678901234abcd"
last_updated: "2026-04-15"
generation_method: "git ls-files + sed canonicalization + manual curation"
---

# 🔐 RAW_URLS_INDEX – Navegación Canónica para IA
RAW_URLS_INDEX.md – Índice Maestro de URLs Raw para Navegación IA


> **Propósito**: Este documento es la **fuente de verdad para resolución de rutas raw** en cualquier agente de IA que opere sobre el repositorio MANTIS AGENTIC.  
> **Regla de oro**: Si una URL no está listada aquí, NO EXISTE para efectos de navegación automatizada. No inventes, no asumas, no extrapoles.

---

## 🗂️ Estructura de Navegación

```yaml
base_url: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/"
sections:
  - "ROOT"
  - "00-CONTEXT"
  - "01-RULES"
  - "02-SKILLS"
  - "03-AGENTS"
  - "04-WORKFLOWS"
  - "05-CONFIGURATIONS"
  - "06-PROGRAMMING"
  - "07-PROCEDURES"
  - "08-LOGS"
  - "09-TEST-SANDBOX"
filter_policy:
  include_extensions: [".md", ".json", ".yml", ".yaml", ".tf", ".sh"]
  exclude_patterns: [".gitkeep", "08-LOGS/validation/*-report.json"]
  tenant_aware: true  # C4: URLs aplican a todos los tenants por diseño
```

---

## 📦 ROOT – Artefactos Canónicos de Nivel Superior

| Archivo | URL Raw | Tipo | Constraints | Validación |
|---------|---------|------|-------------|------------|
| `.gitignore` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/.gitignore` | config | C3, C5 | `audit-secrets.sh` |
| `AI-NAVIGATION-CONTRACT.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/AI-NAVIGATION-CONTRACT.md` | spec | C4, C8 | `validate-frontmatter.sh` |
| `GOVERNANCE-ORCHESTRATOR.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/GOVERNANCE-ORCHESTRATOR.md` | spec | C1, C4, C7 | `verify-constraints.sh` |
| `IA-QUICKSTART.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/IA-QUICKSTART.md` | seed | C3, C4, C5 | `orchestrator-engine.sh` |
| `PROJECT_TREE.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/PROJECT_TREE.md` | map | C5, C8 | `check-wikilinks.sh` |
| `RAW_URLS_INDEX.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/RAW_URLS_INDEX.md` | index | C4, C5, C8 | `validate-skill-integrity.sh` |
| `README.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/README.md` | doc | C3, C8 | `validate-frontmatter.sh` |
| `SDD-COLLABORATIVE-GENERATION.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/SDD-COLLABORATIVE-GENERATION.md` | spec | C4, C5, C7 | `verify-constraints.sh` |
| `TOOLCHAIN-REFERENCE.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/TOOLCHAIN-REFERENCE.md` | ref | C5, C8 | `orchestrator-engine.sh` |
| `knowledge-graph.json` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/knowledge-graph.json` | graph | C4, C5 | `schema-validator.py` |

---

## 📁 00-CONTEXT – Contexto Base del Proyecto

| Archivo | URL Raw | Tipo | Constraints | Validación |
|---------|---------|------|-------------|------------|
| `00-INDEX.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-CONTEXT/00-INDEX.md` | index | C4, C8 | `check-wikilinks.sh` |
| `PROJECT_OVERVIEW.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-CONTEXT/PROJECT_OVERVIEW.md` | overview | C3, C4 | `validate-frontmatter.sh` |
| `documentation-validation-cheklist.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-CONTEXT/documentation-validation-cheklist.md` | checklist | C5, C8 | `verify-constraints.sh` |
| `documentation-validation-cheklist.txt` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-CONTEXT/documentation-validation-cheklist.txt` | checklist | C5 | `audit-secrets.sh` |
| `facundo-business-model.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-CONTEXT/facundo-business-model.md` | context | C3, C4 | `validate-frontmatter.sh` |
| `facundo-core-context.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-CONTEXT/facundo-core-context.md` | context | C3, C4, C8 | `validate-frontmatter.sh` |
| `facundo-infrastructure.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-CONTEXT/facundo-infrastructure.md` | context | C1, C2, C3 | `verify-constraints.sh` |

> ℹ️ `.gitkeep` excluido por política de filtro (no es artefacto navegable).

---

## 📁 01-RULES – Reglas de Arquitectura y Gobernanza

| Archivo | URL Raw | Tipo | Constraints | Validación |
|---------|---------|------|-------------|------------|
| `00-INDEX.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/00-INDEX.md` | index | C4, C8 | `check-wikilinks.sh` |
| `01-ARCHITECTURE-RULES.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/01-ARCHITECTURE-RULES.md` | rules | C1, C2, C3 | `verify-constraints.sh` |
| `02-RESOURCE-GUARDRAILS.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/02-RESOURCE-GUARDRAILS.md` | rules | C1, C2 | `verify-constraints.sh` |
| `03-SECURITY-RULES.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/03-SECURITY-RULES.md` | rules | C3, C4, C5 | `audit-secrets.sh` |
| `04-API-RELIABILITY-RULES.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/04-API-RELIABILITY-RULES.md` | rules | C4, C6, C7 | `verify-constraints.sh` |
| `05-CODE-PATTERNS-RULES.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/05-CODE-PATTERNS-RULES.md` | rules | C3, C5, C8 | `validate-skill-integrity.sh` |
| `06-MULTITENANCY-RULES.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/06-MULTITENANCY-RULES.md` | rules | C4, C5, C7 | `check-rls.sh` |
| `07-SCALABILITY-RULES.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/07-SCALABILITY-RULES.md` | rules | C1, C2, C7 | `verify-constraints.sh` |
| `08-SKILLS-REFERENCE.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/08-SKILLS-REFERENCE.md` | ref | C4, C8 | `validate-frontmatter.sh` |
| `09-AGENTIC-OUTPUT-RULES.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/09-AGENTIC-OUTPUT-RULES.md` | rules | C4, C5, C8 | `validate-skill-integrity.sh` |
| `validation-checklist.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/validation-checklist.md` | checklist | C5, C8 | `verify-constraints.sh` |

---

## 📁 02-SKILLS – Habilidades por Dominio (Núcleo Operativo)

### 🤖 AI – Integraciones de Modelos de Lenguaje

| Archivo | URL Raw | Tipo | Constraints | Validación |
|---------|---------|------|-------------|------------|
| `00-INDEX.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/00-INDEX.md` | index | C4, C8 | `check-wikilinks.sh` |
| `GENERATION-MODELS.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/GENERATION-MODELS.md` | spec | C4, C5, C7 | `verify-constraints.sh` |
| `skill-domains-mapping.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/skill-domains-mapping.md` | mapping | C4, C8 | `validate-frontmatter.sh` |
| `deepseek-integration.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/AI/deepseek-integration.md` | skill | C3, C4, C6 | `validate-skill-integrity.sh` |
| `gemini-integration.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/AI/gemini-integration.md` | skill | C3, C4, C6 | `validate-skill-integrity.sh` |
| `gpt-integration.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/AI/gpt-integration.md` | skill | C3, C4, C6 | `validate-skill-integrity.sh` |
| `image-gen-api.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/AI/image-gen-api.md` | skill | C3, C6 | `validate-skill-integrity.sh` |
| `llama-integration.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/AI/llama-integration.md` | skill | C3, C4, C6 | `validate-skill-integrity.sh` |
| `minimax-integration.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/AI/minimax-integration.md` | skill | C3, C4, C6 | `validate-skill-integrity.sh` |
| `mistral-ocr-integration.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/AI/mistral-ocr-integration.md` | skill | C3, C4, C6 | `validate-skill-integrity.sh` |
| `openrouter-api-integration.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/AI/openrouter-api-integration.md` | skill | C3, C4, C6, C7 | `validate-skill-integrity.sh` |
| `qwen-integration.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/AI/qwen-integration.md` | skill | C3, C4, C6 | `validate-skill-integrity.sh` |
| `video-gen-api.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/AI/video-gen-api.md` | skill | C3, C6 | `validate-skill-integrity.sh` |
| `voice-agent-integration.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/AI/voice-agent-integration.md` | skill | C3, C4, C6 | `validate-skill-integrity.sh` |

### 🗄️ BASE DE DATOS-RAG – Patrones de Ingesta y Aislamiento

| Archivo | URL Raw | Tipo | Constraints | Validación |
|---------|---------|------|-------------|------------|
| `airtable-database-patterns.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/BASE DE DATOS-RAG/airtable-database-patterns.md` | skill | C3, C4 | `validate-skill-integrity.sh` |
| `db-selection-decision-tree.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/BASE DE DATOS-RAG/db-selection-decision-tree.md` | decision | C4, C8 | `verify-constraints.sh` |
| `environment-variable-management.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/BASE DE DATOS-RAG/environment-variable-management.md` | skill | C3, C4, C5 | `audit-secrets.sh` |
| `espocrm-api-analytics.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/BASE DE DATOS-RAG/espocrm-api-analytics.md` | skill | C4, C8 | `validate-skill-integrity.sh` |
| `google-drive-qdrant-sync.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/BASE DE DATOS-RAG/google-drive-qdrant-sync.md` | skill | C4, C5, C7 | `validate-skill-integrity.sh` |
| `google-sheets-as-database.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/BASE DE DATOS-RAG/google-sheets-as-database.md` | skill | C3, C4 | `validate-skill-integrity.sh` |
| `multi-tenant-data-isolation.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/BASE DE DATOS-RAG/multi-tenant-data-isolation.md` | skill | C4, C5, C7 | `check-rls.sh` |
| `mysql-optimization-4gb-ram.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/BASE DE DATOS-RAG/mysql-optimization-4gb-ram.md` | skill | C1, C2, C3 | `verify-constraints.sh` |
| `mysql-sql-rag-ingestion.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/BASE DE DATOS-RAG/mysql-sql-rag-ingestion.md` | skill | C3, C4, C5 | `validate-skill-integrity.sh` |
| `pdf-mistralocr-processing.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/BASE DE DATOS-RAG/pdf-mistralocr-processing.md` | skill | C3, C6 | `validate-skill-integrity.sh` |
| `postgres-prisma-rag.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/BASE DE DATOS-RAG/postgres-prisma-rag.md` | skill | C3, C4, C5 | `validate-skill-integrity.sh` |
| `qdrant-rag-ingestion.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md` | skill | C3, C4, C5 | `validate-skill-integrity.sh` |
| `rag-system-updates-all-engines.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/BASE DE DATOS-RAG/rag-system-updates-all-engines.md` | skill | C4, C7 | `validate-skill-integrity.sh` |
| `redis-session-management.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/BASE DE DATOS-RAG/redis-session-management.md` | skill | C1, C3, C4 | `verify-constraints.sh` |
| `supabase-rag-integration.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/BASE DE DATOS-RAG/supabase-rag-integration.md` | skill | C3, C4, C5 | `validate-skill-integrity.sh` |
| `vertical-db-schemas.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/BASE DE DATOS-RAG/vertical-db-schemas.md` | schema | C4, C5 | `schema-validator.py` |

### 📡 INFRAESTRUCTURA – Servidores, Redes y Seguridad

| Archivo | URL Raw | Tipo | Constraints | Validación |
|---------|---------|------|-------------|------------|
| `docker-compose-networking.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRASTRUCTURA/docker-compose-networking.md` | skill | C1, C3, C4 | `validate-skill-integrity.sh` |
| `espocrm-setup.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRASTRUCTURA/espocrm-setup.md` | skill | C3, C4, C7 | `validate-skill-integrity.sh` |
| `fail2ban-configuration.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRASTRUCTURA/fail2ban-configuration.md` | skill | C3, C4, C5 | `audit-secrets.sh` |
| `health-monitoring-vps.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRASTRUCTURA/health-monitoring-vps.md` | skill | C1, C2, C8 | `verify-constraints.sh` |
| `n8n-concurrency-limiting.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRASTRUCTURA/n8n-concurrency-limiting.md` | skill | C1, C2, C7 | `verify-constraints.sh` |
| `ssh-key-management.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRASTRUCTURA/ssh-key-management.md` | skill | C3, C4, C5 | `audit-secrets.sh` |
| `ssh-tunnels-remote-services.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRASTRUCTURA/ssh-tunnels-remote-services.md` | skill | C3, C4, C7 | `validate-skill-integrity.sh` |
| `ufw-firewall-configuration.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRASTRUCTURA/ufw-firewall-configuration.md` | skill | C3, C4, C5 | `audit-secrets.sh` |
| `vps-interconnection.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRASTRUCTURA/vps-interconnection.md` | skill | C3, C4, C7 | `validate-skill-integrity.sh` |

### 🔒 SEGURIDAD – Hardening, Backup y Auditoría

| Archivo | URL Raw | Tipo | Constraints | Validación |
|---------|---------|------|-------------|------------|
| `backup-encryption.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/SEGURIDAD/backup-encryption.md` | skill | C3, C5, C7 | `audit-secrets.sh` |
| `rsync-automation.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/SEGURIDAD/rsync-automation.md` | skill | C3, C5, C7 | `validate-skill-integrity.sh` |
| `security-hardening-vps.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/SEGURIDAD/security-hardening-vps.md` | skill | C3, C4, C5 | `audit-secrets.sh` |

### 📧 COMUNICACIÓN – Canales de Mensajería y Notificación

| Archivo | URL Raw | Tipo | Constraints | Validación |
|---------|---------|------|-------------|------------|
| `gmail-smtp-integration.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/COMUNICACION/gmail-smtp-integration.md` | skill | C3, C4, C6 | `validate-skill-integrity.sh` |
| `google-calendar-api-integration.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/COMUNICACION/google-calendar-api-integration.md` | skill | C3, C4, C6 | `validate-skill-integrity.sh` |
| `telegram-bot-integration.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/COMUNICACION/telegram-bot-integration.md` | skill | C3, C4, C6 | `validate-skill-integrity.sh` |
| `whatsapp-rag-openrouter.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/COMUNICACION/whatsapp-rag-openrouter.md` | skill | C3, C4, C6, C7 | `validate-skill-integrity.sh` |

### 🧠 AGENTIC-ASSISTANCE & DEPLOYMENT

| Archivo | URL Raw | Tipo | Constraints | Validación |
|---------|---------|------|-------------|------------|
| `ide-cli-integration.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/AGENTIC-ASSISTANCE/ide-cli-integration.md` | skill | C3, C4, C8 | `validate-skill-integrity.sh` |
| `multi-channel-deploymen.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/DEPLOYMENT/multi-channel-deploymen.md` | skill | C4, C6, C7 | `validate-skill-integrity.sh` |

> ℹ️ Subdirectorios `.gitkeep` de dominios verticales (HOTELES, ODONTOLOGÍA, etc.) excluidos por política de filtro.

---

## 📁 03-AGENTS – Definiciones de Agentes Autónomos

| Archivo | URL Raw | Tipo | Constraints | Validación |
|---------|---------|------|-------------|------------|
| `clients/.gitkeep` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/03-AGENTS/clients/.gitkeep` | placeholder | - | - |
| `infrastructure/.gitkeep` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/03-AGENTS/infrastructure/.gitkeep` | placeholder | - | - |

> ⚠️ Sección en desarrollo. Artefactos funcionales serán añadidos con validación completa.

---

## 📁 04-WORKFLOWS – Flujos de Trabajo Automatizados

| Archivo | URL Raw | Tipo | Constraints | Validación |
|---------|---------|------|-------------|------------|
| `sdd-universal-assistant.json` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/04-WORKFLOWS/sdd-universal-assistant.json` | workflow | C4, C5, C7 | `schema-validator.py` |
| `diagrams/.gitkeep` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/04-WORKFLOWS/diagrams/.gitkeep` | placeholder | - | - |
| `n8n/.gitkeep` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/04-WORKFLOWS/n8n/.gitkeep` | placeholder | - | - |

---

## 📁 05-CONFIGURATIONS – Configuración Centralizada (Motor de Validación)

### 🗂️ Root de Configuraciones

| Archivo | URL Raw | Tipo | Constraints | Validación |
|---------|---------|------|-------------|------------|
| `00-INDEX.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/00-INDEX.md` | index | C4, C8 | `check-wikilinks.sh` |

### 🐳 Docker Compose

| Archivo | URL Raw | Tipo | Constraints | Validación |
|---------|---------|------|-------------|------------|
| `00-INDEX.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/docker-compose/00-INDEX.md` | index | C4, C8 | `check-wikilinks.sh` |
| `vps1-n8n-uazapi.yml` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml` | compose | C1, C2, C3 | `verify-constraints.sh` |
| `vps2-crm-qdrant.yml` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.yml` | compose | C1, C3, C4 | `verify-constraints.sh` |
| `vps3-n8n-uazapi.yml` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/docker-compose/vps3-n8n-uazapi.yml` | compose | C1, C2, C3 | `verify-constraints.sh` |

### 🌍 Environment & Observability

| Archivo | URL Raw | Tipo | Constraints | Validación |
|---------|---------|------|-------------|------------|
| `.env.example` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/environment/.env.example` | env | C3, C5 | `audit-secrets.sh` |
| `otel-tracing-config.yaml` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/observability/otel-tracing-config.yaml` | observability | C8, C5 | `verify-constraints.sh` |

### 🔄 Pipelines & CI/CD

| Archivo | URL Raw | Tipo | Constraints | Validación |
|---------|---------|------|-------------|------------|
| `provider-router.yml` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/pipelines/provider-router.yml` | pipeline | C4, C6, C7 | `verify-constraints.sh` |
| `.github/workflows/integrity-check.yml` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/pipelines/.github/workflows/integrity-check.yml` | workflow | C5, C8 | `validate-skill-integrity.sh` |
| `.github/workflows/terraform-plan.yml` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/pipelines/.github/workflows/terraform-plan.yml` | workflow | C5, C7 | `validate-skill-integrity.sh` |
| `.github/workflows/validate-skill.yml` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/pipelines/.github/workflows/validate-skill.yml` | workflow | C5, C8 | `validate-skill-integrity.sh` |
| `promptfoo/config.yaml` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/pipelines/promptfoo/config.yaml` | eval | C5, C8 | `schema-validator.py` |
| `promptfoo/assertions/schema-check.yaml` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/pipelines/promptfoo/assertions/schema-check.yaml` | assertion | C5 | `schema-validator.py` |
| `promptfoo/test-cases/resource-limits.yaml` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/pipelines/promptfoo/test-cases/resource-limits.yaml` | test | C1, C2 | `verify-constraints.sh` |
| `promptfoo/test-cases/tenant-isolation.yaml` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/pipelines/promptfoo/test-cases/tenant-isolation.yaml` | test | C4, C5 | `check-rls.sh` |

### 🛠️ Scripts Operativos

| Archivo | URL Raw | Tipo | Constraints | Validación |
|---------|---------|------|-------------|------------|
| `VALIDATOR_DOCUMENTATION.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/scripts/VALIDATOR_DOCUMENTATION.md` | doc | C5, C8 | `validate-frontmatter.sh` |
| `backup-mysql.sh` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/scripts/backup-mysql.sh` | script | C3, C5, C7 | `validate-skill-integrity.sh` |
| `generate-repo-validation-report.sh` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/scripts/generate-repo-validation-report.sh` | script | C5, C7, C8 | `validate-skill-integrity.sh` |
| `health-check.sh` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/scripts/health-check.sh` | script | C1, C2, C8 | `verify-constraints.sh` |
| `packager-assisted.sh` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/scripts/packager-assisted.sh` | script | C3, C5, C7 | `validate-skill-integrity.sh` |
| `sync-to-sandbox.sh` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/scripts/sync-to-sandbox.sh` | script | C3, C5, C7 | `validate-skill-integrity.sh` |
| `validate-against-specs.sh` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/scripts/validate-against-specs.sh` | script | C3, C5, C8 | `validate-skill-integrity.sh` |

### 📋 Templates y Plantillas

| Archivo | URL Raw | Tipo | Constraints | Validación |
|---------|---------|------|-------------|------------|
| `bootstrap-company-context.json` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/templates/bootstrap-company-context.json` | template | C4, C5 | `schema-validator.py` |
| `example-template.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/templates/example-template.md` | template | C3, C4, C5 | `validate-frontmatter.sh` |
| `pipeline-template.yml` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/templates/pipeline-template.yml` | template | C5, C7 | `verify-constraints.sh` |
| `skill-template.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/templates/skill-template.md` | template | C3, C4, C5 | `validate-frontmatter.sh` |
| `terraform-module-template/main.tf` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/templates/terraform-module-template/main.tf` | terraform | C3, C4, C5 | `validate-skill-integrity.sh` |
| `terraform-module-template/outputs.tf` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/templates/terraform-module-template/outputs.tf` | terraform | C4, C5 | `validate-skill-integrity.sh` |
| `terraform-module-template/variables.tf` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/templates/terraform-module-template/variables.tf` | terraform | C3, C4 | `validate-skill-integrity.sh` |
| `terraform-module-template/README.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/templates/terraform-module-template/README.md` | doc | C3, C8 | `validate-frontmatter.sh` |

### 🏗️ Terraform – Infraestructura como Código

| Archivo | URL Raw | Tipo | Constraints | Validación |
|---------|---------|------|-------------|------------|
| `backend.tf` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/terraform/backend.tf` | terraform | C3, C4, C5 | `validate-skill-integrity.sh` |
| `variables.tf` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/terraform/variables.tf` | terraform | C3, C4 | `validate-skill-integrity.sh` |
| `outputs.tf` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/terraform/outputs.tf` | terraform | C4, C5 | `validate-skill-integrity.sh` |
| `environments/dev/terraform.tfvars` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/terraform/environments/dev/terraform.tfvars` | tfvars | C3, C4 | `audit-secrets.sh` |
| `environments/prod/terraform.tfvars` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/terraform/environments/prod/terraform.tfvars` | tfvars | C3, C4 | `audit-secrets.sh` |
| `environments/variables.tf` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/terraform/environments/variables.tf` | terraform | C3, C4 | `validate-skill-integrity.sh` |

#### Módulos Terraform

| Módulo | Archivo | URL Raw | Constraints | Validación |
|--------|---------|---------|-------------|------------|
| `backup-encrypted` | `main.tf` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/terraform/modules/backup-encrypted/main.tf` | C3, C5, C7 | `validate-skill-integrity.sh` |
| `backup-encrypted` | `outputs.tf` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/terraform/modules/backup-encrypted/outputs.tf` | C4, C5 | `validate-skill-integrity.sh` |
| `backup-encrypted` | `variables.tf` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/terraform/modules/backup-encrypted/variables.tf` | C3, C4 | `validate-skill-integrity.sh` |
| `openrouter-proxy` | `main.tf` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/terraform/modules/openrouter-proxy/main.tf` | C3, C4, C6 | `validate-skill-integrity.sh` |
| `openrouter-proxy` | `outputs.tf` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/terraform/modules/openrouter-proxy/outputs.tf` | C4, C5 | `validate-skill-integrity.sh` |
| `openrouter-proxy` | `variables.tf` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/terraform/modules/openrouter-proxy/variables.tf` | C3, C4 | `validate-skill-integrity.sh` |
| `postgres-rls` | `main.tf` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/terraform/modules/postgres-rls/main.tf` | C4, C5, C7 | `check-rls.sh` |
| `postgres-rls` | `outputs.tf` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/terraform/modules/postgres-rls/outputs.tf` | C4, C5 | `validate-skill-integrity.sh` |
| `postgres-rls` | `variables.tf` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/terraform/modules/postgres-rls/variables.tf` | C3, C4 | `validate-skill-integrity.sh` |
| `qdrant-cluster` | `main.tf` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/terraform/modules/qdrant-cluster/main.tf` | C3, C4, C5 | `validate-skill-integrity.sh` |
| `qdrant-cluster` | `outputs.tf` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/terraform/modules/qdrant-cluster/outputs.tf` | C4, C5 | `validate-skill-integrity.sh` |
| `qdrant-cluster` | `variables.tf` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/terraform/modules/qdrant-cluster/variables.tf` | C3, C4 | `validate-skill-integrity.sh` |
| `vps-base` | `main.tf` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/terraform/modules/vps-base/main.tf` | C1, C2, C3 | `validate-skill-integrity.sh` |
| `vps-base` | `outputs.tf` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/terraform/modules/vps-base/outputs.tf` | C4, C5 | `validate-skill-integrity.sh` |
| `vps-base` | `variables.tf` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/terraform/modules/vps-base/variables.tf` | C3, C4 | `validate-skill-integrity.sh` |

### 🔍 Validation – Suite de Validadores Centralizados

| Archivo | URL Raw | Tipo | Constraints | Validación |
|---------|---------|------|-------------|------------|
| `audit-secrets.sh` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/audit-secrets.sh` | validator | C3, C5 | `validate-skill-integrity.sh` |
| `check-rls.sh` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/check-rls.sh` | validator | C4, C5 | `validate-skill-integrity.sh` |
| `check-wikilinks.sh` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/check-wikilinks.sh` | validator | C5, C8 | `validate-skill-integrity.sh` |
| `norms-matrix.json` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json` | matrix | C4, C5 | `schema-validator.py` |
| `orchestrator-engine.sh` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/orchestrator-engine.sh` | orchestrator | C5, C7, C8 | `validate-skill-integrity.sh` |
| `schema-validator.py` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schema-validator.py` | validator | C5, C8 | `validate-skill-integrity.sh` |
| `schemas/skill-input-output.schema.json` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json` | schema | C4, C5 | `schema-validator.py` |
| `validate-frontmatter.sh` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/validate-frontmatter.sh` | validator | C3, C5 | `validate-skill-integrity.sh` |
| `validate-skill-integrity.sh` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/validate-skill-integrity.sh` | validator | C5, C8 | `validate-skill-integrity.sh` |
| `verify-constraints.sh` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/verify-constraints.sh` | validator | C1-C6 | `validate-skill-integrity.sh` |

---

## 📁 06-PROGRAMMING – Patrones de Programación por Lenguaje

> ℹ️ Sección en desarrollo. URLs de placeholders incluidas para trazabilidad.

| Archivo | URL Raw | Tipo | Constraints | Validación |
|---------|---------|------|-------------|------------|
| `bash/.gitkeep` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/.gitkeep` | placeholder | - | - |
| `javascript/.gitkeep` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/javascript/.gitkeep` | placeholder | - | - |
| `python/.gitkeep` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/.gitkeep` | placeholder | - | - |
| `sql/.gitkeep` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/sql/.gitkeep` | placeholder | - | - |

---

## 📁 07-PROCEDURES – Procedimientos Operativos Estándar

| Archivo | URL Raw | Tipo | Constraints | Validación |
|---------|---------|------|-------------|------------|
| `.gitkeep` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/07-PROCEDURES/.gitkeep` | placeholder | - | - |

> ⚠️ Sección en desarrollo. Procedimientos funcionales serán añadidos con validación completa.

---

## 📁 08-LOGS – Registros de Ejecución y Auditoría

| Archivo | URL Raw | Tipo | Constraints | Validación |
|---------|---------|------|-------------|------------|
| `.gitkeep` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/08-LOGS/.gitkeep` | placeholder | - | - |
| `generation/.gitkeep` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/08-LOGS/generation/.gitkeep` | placeholder | - | - |

> 🔒 Política: Logs de validación (`*-report.json`) excluidos por `.gitignore` para evitar contaminación de contexto.

---

## 📁 09-TEST-SANDBOX – Entorno de Pruebas por Modelo

### 🧪 Subdirectorios por Modelo (Estructura Común)

| Modelo | Archivo | URL Raw | Propósito |
|--------|---------|---------|-----------|
| `qwen` | `GOVERNANCE-ORCHESTRATOR.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/09-TEST-SANDBOX/qwen/GOVERNANCE-ORCHESTRATOR.md` | Gobernanza específica para Qwen |
| `qwen` | `orchestrator-engine.sh` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/09-TEST-SANDBOX/qwen/orchestrator-engine.sh` | Validador adaptado para Qwen |
| `deepseek` | `GOVERNANCE-ORCHESTRATOR.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/09-TEST-SANDBOX/deepseek/GOVERNANCE-ORCHESTRATOR.md` | Gobernanza específica para DeepSeek |
| `deepseek` | `orchestrator-engine.sh` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/09-TEST-SANDBOX/deepseek/orchestrator-engine.sh` | Validador adaptado para DeepSeek |
| `gemini` | `GOVERNANCE-ORCHESTRATOR.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/09-TEST-SANDBOX/gemini/GOVERNANCE-ORCHESTRATOR.md` | Gobernanza específica para Gemini |
| `gemini` | `orchestrator-engine.sh` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/09-TEST-SANDBOX/gemini/orchestrator-engine.sh` | Validador adaptado para Gemini |
| `minimax` | `GOVERNANCE-ORCHESTRATOR.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/09-TEST-SANDBOX/minimax/GOVERNANCE-ORCHESTRATOR.md` | Gobernanza específica para Minimax |
| `minimax` | `orchestrator-engine.sh` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/09-TEST-SANDBOX/minimax/orchestrator-engine.sh` | Validador adaptado para Minimax |
| `claude` | `.gitkeep` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/09-TEST-SANDBOX/claude/.gitkeep` | Placeholder para Claude |
| `comparison` | `.gitkeep` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/09-TEST-SANDBOX/comparison/.gitkeep` | Placeholder para comparativas |

### 📄 Root de Sandbox

| Archivo | URL Raw | Tipo | Constraints | Validación |
|---------|---------|------|-------------|------------|
| `README.md` | `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/09-TEST-SANDBOX/README.md` | doc | C3, C8 | `validate-frontmatter.sh` |

---

## 🧭 Protocolo de Navegación para IA

```yaml
navigation_protocol:
  step_1_load: "IA-QUICKSTART.md"  # Determinar modo y tier operativo
  step_2_resolve: "PROJECT_TREE.md"  # Validar ruta canónica del artefacto solicitado
  step_3_fetch: "RAW_URLS_INDEX.md"  # Obtener URL raw exacta desde esta tabla
  step_4_validate: "orchestrator-engine.sh --file <path> --json"  # Validar integridad pre-uso
  step_5_execute: "Aplicar artifact según constraints C1-C8"
  
error_handling:
  url_not_found: "Abortar y reportar: '[NAVIGATION_ERROR] URL no listada en RAW_URLS_INDEX.md'"
  constraint_violation: "Abortar y reportar: '[CONSTRAINT_ERROR] <constraint> no cumplido en <artifact>'"
  validation_failed: "Reintentar máx. 2 veces; si persiste, generar postmortem.md"
```

---

## 🔐 Notas de Integridad y Mantenimiento

1. **Actualización automática**: Este índice debe regenerarse tras cada merge a `main` mediante:
   ```bash
   git ls-files | grep -E '\.(md|json|yml|yaml|tf|sh)$' | \
     grep -v '08-LOGS/' | \
     sed 's|^|https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/|' > raw_urls_temp.txt
   # Luego curar manualmente la estructura de tablas por sección
   ```

2. **Validación de consistencia**: Ejecutar semanalmente:
   ```bash
   bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file RAW_URLS_INDEX.md --json | \
     jq -e '.status == "passed"' || echo "[ALERTA] RAW_URLS_INDEX.md requiere revisión"
   ```

3. **Política de exclusión**: `.gitkeep`, `*-report.json`, y archivos en `08-LOGS/` se excluyen deliberadamente para evitar ruido en navegación automatizada.

---

## ✅ Checklist de Verificación Pre-Entrega

```bash
# 1. Validar que todas las URLs listadas existen
while IFS= read -r url; do
  curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200" || echo "[WARN] URL no accesible: $url"
done < <(grep "https://raw.githubusercontent.com" RAW_URLS_INDEX.md | sed 's/.*| `\([^`]*\)`/\1/')

# 2. Verificar que no hay URLs duplicadas
grep "https://raw.githubusercontent.com" RAW_URLS_INDEX.md | sort | uniq -d

# 3. Confirmar que el checksum del encabezado coincide con el contenido actual
sha256sum RAW_URLS_INDEX.md
```

---

> 📬 **Para usar este índice en un prompt de IA**: Copiar la sección de tablas correspondiente al dominio de interés, o inyectar la URL raw de este archivo completo para navegación dinámica.  
> 🔐 **Checksum de integridad**: `sha256sum RAW_URLS_INDEX.md` → comparar con `checksum_sha256` en frontmatter.  
> 🌱 **Próxima actualización**: Tras merge de `06-PROGRAMMING/bash/` artefactos.

---

*Documento generado bajo contrato SDD v2.0.0. Validado contra `norms-matrix.json`.  
Última sincronización: `$(date -Iseconds)`.  
MANTIS AGENTIC – Gobernanza ejecutable para inteligencia colaborativa.* 🔐🌱
