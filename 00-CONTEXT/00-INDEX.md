---
file_id: CNT-INDEX-000
file_name: 00-INDEX.md
version: 1.1.0
created: 2026-04-02
last_updated: 2026-04-02
author: Facundo (Mantis-AgenticDev)
category: INDEX
priority: SIEMPRE
type: navigation
ia_parser_version: "2.0"
auto_validate: false
compliance_check: "on-demand"
tokens_estimate: 800
tags:
  - index
  - navigation
  - context
  - startup-guide
related_files:
  - "PROJECT_OVERVIEW.md"
  - "facundo-core-context.md"
  - "facundo-infrastructure.md"
  - "facundo-business-model.md"
  - "../01-RULES/00-INDEX.md"
---

<!-- IA-NAVIGATION
priority_files:
  - "facundo-core-context.md"
  - "facundo-infrastructure.md"
  - "facundo-business-model.md"
  - "PROJECT_OVERVIEW.md"
always_keep_in_context:
  - "facundo-core-context.md"
  - "facundo-infrastructure.md"
load_strategy: "progressive"
max_tokens_per_session: 4000
critical_sections:
  - "archivos-de-contexto"
  - "navegacion-recomendada"
  - "reglas-del-proyecto"
-->

# ÍNDICE DE CONTEXTOS - 00-CONTEXT/

## 📁 Archivos de Contexto

| Archivo | ID | Prioridad | Descripción | Estado |
|---------|-----|-----------|-------------|--------|
| [PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md) | PRO-OVER-001 | CRÍTICA | Visión general del proyecto (bilingüe) | ✅ |
| [facundo-core-context.md](./facundo-core-context.md) | FAC-CORE-001 | CRÍTICA | Contexto base del usuario + constraints absolutos | ✅ |
| [facundo-infrastructure.md](./facundo-infrastructure.md) | FAC-INFRA-002 | CRÍTICA | Detalle técnico: 3 VPS, backups, agentes | ✅ |
| [facundo-business-model.md](./facundo-business-model.md) | FAC-BIZ-003 | ALTA | Modelo de negocio, pricing, costos, KPIs | ✅ |

---

## 🔗 Navegación Recomendada para IAs

### En un chat NUEVO (orden óptimo):

| Orden | Archivo | Por qué |
|-------|---------|---------|
| 1️⃣ | `facundo-core-context.md` | Constraints absolutos, filosofía del proyecto |
| 2️⃣ | `facundo-infrastructure.md` | Arquitectura 3 VPS, agentes, monitoreo |
| 3️⃣ | `facundo-business-model.md` | Precios, costos, distribución de ganancias |
| 4️⃣ | `PROJECT_OVERVIEW.md` | Visión general bilingüe, propósito del proyecto |

### Para tareas ESPECÍFICAS:

| Tarea | Archivos a cargar |
|-------|-------------------|
| **Implementar VPS** | `facundo-core-context.md` + `facundo-infrastructure.md` + `01-RULES/01-ARCHITECTURE-RULES.md` |
| **Definir precios** | `facundo-business-model.md` + `PROJECT_OVERVIEW.md` |
| **Crear agentes n8n** | `facundo-infrastructure.md` + `01-RULES/05-CODE-PATTERNS-RULES.md` |
| **Onboarding cliente** | `facundo-business-model.md` + `07-PROCEDURES/onboarding-client.md` |

---

## 📚 Reglas del Proyecto (01-RULES/)

Todas las reglas están en `../01-RULES/` y deben consultarse según la tarea:

| Archivo | Prioridad | Cuándo consultar |
|---------|-----------|------------------|
| [00-INDEX.md](../01-RULES/00-INDEX.md) | Siempre | Navegación inicial de reglas |
| [01-ARCHITECTURE-RULES.md](../01-RULES/01-ARCHITECTURE-RULES.md) | Alta | Configurar VPS, Docker, red |
| [02-RESOURCE-GUARDRAILS.md](../01-RULES/02-RESOURCE-GUARDRAILS.md) | Siempre | Límites RAM/CPU/disco |
| [03-SECURITY-RULES.md](../01-RULES/03-SECURITY-RULES.md) | Alta | UFW, SSH, fail2ban, secretos |
| [04-API-RELIABILITY-RULES.md](../01-RULES/04-API-RELIABILITY-RULES.md) | Media | Timeouts, error handling |
| [05-CODE-PATTERNS-RULES.md](../01-RULES/05-CODE-PATTERNS-RULES.md) | Media | JavaScript, Python, SQL patrones |
| [06-MULTITENANCY-RULES.md](../01-RULES/06-MULTITENANCY-RULES.md) | Alta | tenant_id, aislamiento de datos |
| [07-SCALABILITY-RULES.md](../01-RULES/07-SCALABILITY-RULES.md) | Baja | Fases de escalado, criterios |
| [08-SKILLS-REFERENCE.md](../01-RULES/08-SKILLS-REFERENCE.md) | Baja | Skills disponibles en 02-SKILLS/ |

---

## 🔍 URLs Raw para IAs

Base URL:
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/00-CONTEXT/

**Archivos individuales:**

https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/00-CONTEXT/PROJECT_OVERVIEW.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/00-CONTEXT/facundo-core-context.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/00-CONTEXT/facundo-infrastructure.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/00-CONTEXT/facundo-business-model.md


---

## ✅ Checklist de Validación

- [ ] Los 4 archivos de contexto existen en la carpeta
- [ ] Todos tienen frontmatter YAML con metadatos
- [ ] Todos tienen metadatos de navegación (`<!-- IA-NAVIGATION -->`)
- [ ] Las reglas en `01-RULES/` están completas
- [ ] Este índice es el primer archivo que una IA debe leer

---

**Versión:** 1.1.0  
**Última actualización:** 2026-04-02  
**Próxima revisión:** Al completar Fase 1 del proyecto
