---
title: "SKILLS REFERENCE - Agentic Infra Docs"
category: "Skills"
priority: "Baja"
version: "1.0.0"
last_updated: "2026-03"
language: "es"
repository: "agentic-infra-docs"
owner: "Mantis-AgenticDev"
type: "reference"
ia_parser_version: "2.0"
auto_validate: false
compliance_check: "on-demand"
skill_type: "index"
estimated_duration: "5min"
tags:
  - skills
  - reference
  - patterns
  - reusable
  - index
related_files:
  - "02-SKILLS/00-INDEX.md"
  - "06-PROGRAMMING/"
---

# SKILLS REFERENCE

## Metadatos del Documento

- **Categoría:** Skills
- **Prioridad de carga:** Baja
- **Versión:** 1.0.0
- **Última actualización:** Marzo 2026
- **Archivos relacionados:** 02-SKILLS/00-INDEX.md

---

## Propósito de Este Archivo

Este archivo es un pointer a las skills reutilizables del proyecto. Las skills contienen procedimientos paso a paso, mientras que las RULES contienen constraints.

**Diferencia clave:**

- **RULES:** "Qué hacer" (constraints verificables)
- **SKILLS:** "Cómo hacer" (procedimientos detallados)

---

## Skills Disponibles

Las skills están ubicadas en: `02-SKILLS/`

### Skills de Integración

| Skill                        | Archivo                        | Caso de Uso                     |
|------------------------------|--------------------------------|---------------------------------|
| n8n Workflow Patterns        | n8n-workflow-patterns.md       | Crear workflows reutilizables   |
| WhatsApp RAG Agents          | whatsapp-rag-agents.md         | Agentes de WhatsApp con IA      |
| Qdrant RAG Ingestion         | qdrant-rag-ingestion.md        | Ingesta de documentos en Qdrant |
| Docker Compose Networking    | docker-compose-networking.md   | Redes Docker entre VPS          |
| SSH Tunnels Remote Services  | ssh-tunnels-remote-services.md | Túneles SSH para servicios      |
| Multi-Tenant Data Isolation  | multi-tenant-data-isolation.md | Aislamiento de datos por tenant |
| EspoCRM API Analytics        | espocrm-api-analytics.md       | Reportes y analytics de EspoCRM |

#### Skills de Integración (Estado Actual)

| Skill                     | Archivo                                     | Caso de Uso      | Estado       |
|---------------------------|---------------------------------------------|------------------|--------------|
| n8n Workflow Patterns     | `02-SKILLS/n8n-workflow-patterns.md`        | Crear workflows  | 🆕 Pendiente |
| WhatsApp RAG Agents       | `02-SKILLS/whatsapp-rag-agents.md`          | Agentes WhatsApp | 🆕 Pendiente |
| Qdrant RAG Ingestion      | `02-SKILLS/qdrant-rag-ingestion.md`         | Ingesta Qdrant   | 🆕 Pendiente |
| Docker Compose Networking | `05-CONFIGURATIONS/docker-compose/`         | Redes Docker     | ✅ Existe    |
| SSH Tunnels               | `07-PROCEDURES/ssh-tunnel-setup.md`         | Túneles SSH      | 🆕 Pendiente |
| Multi-Tenant Isolation    | `06-PROGRAMMING/sql/multi-tenant-schema.md` | Aislamiento      | 🆕 Pendiente |

**Nota:** Las skills marcadas como 🆕 deben ser creadas antes de que la IA las use.

### Skills de Integración Externa

| Skill                           | Archivo                            | Caso de Uso            |
|---------------------------------|------------------------------------|------------------------|
| WhatsApp UAZAPI Integration     | whatsapp-uazapi-integration.md     | Integración con uazapi |
| Telegram Bot Integration        | telegram-bot-integration.md        | Alertas vía Telegram   |
| Gmail SMTP Integration          | gmail-smtp-integration.md          | Envío de emails        |
| Google Calendar API Integration | google-calendar-api-integration.md | Eventos en Calendar    |

### Skills de Seguridad

| Skill                                      | Archivo                       | Caso de Uso             |
|--------------------------------------------|-------------------------------|-------------------------|
| fail2ban Configuration                     | fail2ban-configuration.md     | Protección SSH          |
| UFW Firewall Configuration                 | ufw-firewall-configuration.md | Firewall en VPS         |
| SSH Key Management                         | ssh-key-management.md         | Gestión de claves SSH   |
| Backup Encryption                          | backup-encryption.md          | Encriptación de backups |

### Skills de Optimización

| Skill                           | Archivo                            | Caso de Uso                 |
|---------------------------------|------------------------------------|-----------------------------|
| MySQL Optimization 4GB RAM      | mysql-optimization-4gb-ram.md      | MySQL en VPS pequeños       |
| n8n Concurrency Limiting        | n8n-concurrency-limiting.md        | Limitar concurrencia en n8n |
| Environment Variable Management | environment-variable-management.md | Gestión de .env             |

---

## Cómo Usar Skills

### Cuando una tarea encaja con una skill:

1. Identificar la skill relevante en esta tabla
2. Leer el archivo de la skill en 02-SKILLS/
3. Seguir el procedimiento paso a paso
4. Validar resultado contra las RULES correspondientes

### Ejemplo de flujo:

Tarea: Configurar Qdrant para nuevo cliente

Leer: 06-MULTITENANCY-RULES.md (constraints)
Leer: 02-SKILLS/qdrant-rag-ingestion.md (procedimiento)
Ejecutar procedimiento
Validar contra reglas MT-001 a MT-010



---

## Skills por Categoría

### Automatización

- n8n-workflow-patterns.md
- whatsapp-rag-agents.md
- whatsapp-uazapi-integration.md

### Datos

- qdrant-rag-ingestion.md
- multi-tenant-data-isolation.md
- espocrm-api-analytics.md
- mysql-optimization-4gb-ram.md

### Infraestructura

- docker-compose-networking.md
- ssh-tunnels-remote-services.md
- fail2ban-configuration.md
- ufw-firewall-configuration.md

### Comunicación

- telegram-bot-integration.md
- gmail-smtp-integration.md
- google-calendar-api-integration.md

### Seguridad

- ssh-key-management.md
- backup-encryption.md
- environment-variable-management.md

### Optimización

- n8n-concurrency-limiting.md

---

## Modo Aprendizaje

Si el usuario pide entender o aprender un concepto:

1. Usar estilo de teach-step-by-step-facundo (si existe la skill)
2. Resumen inicial del concepto
3. Pasos numerados para implementación
4. Analogía opcional para clarificación
5. Ejemplo mínimo funcional

---

## URLs Raw para Skills

Base URL:
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/02-SKILLS/

Ejemplo:
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/02-SKILLS/n8n-workflow-patterns.md


---

## Checklist de Validación

- [ ] Skill relevante identificada antes de implementar
- [ ] Procedimiento de skill seguido paso a paso
- [ ] Resultado validado contra RULES correspondientes
- [ ] Skill actualizada si se encuentra mejora en procedimiento

---

*Versión 1.0.0 - Marzo 2026 - Mantis-AgenticDev*
*Licencia: Creative Commons para uso interno del proyecto*

## 🔗 Conexiones Estructurales (Auto-generado)
[[README.md]]
[[01-RULES/00-INDEX.md]]
[[01-RULES/01-ARCHITECTURE-RULES.md]]
[[01-RULES/02-RESOURCE-GUARDRAILS.md]]
