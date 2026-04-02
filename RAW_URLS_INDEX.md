---
title: "RAW URLS INDEX - Agentic Infrastructure"
category: "Navegación"
priority: "Siempre"
version: "1.0.0"
last_updated: "2026-04-01"
language: "es"
repository: "agentic-infra-docs"
owner: "Mantis-AgenticDev"
type: "index"
ia_parser_version: "2.0"
auto_validate: false
compliance_check: "on-demand"
total_files: 91
completed_files: 5
completion_percentage: 5.5
tags:
  - raw-urls
  - navigation
  - index
  - ia-guide
  - github
related_files:
  - "PROJECT_TREE.md"
  - "00-CONTEXT/PROJECT_OVERVIEW.md"
  - "01-RULES/00-INDEX.md"
---

<!-- IA-NAVIGATION
priority_files:
  - "00-CONTEXT/PROJECT_OVERVIEW.md"
  - "01-RULES/00-INDEX.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
always_keep_in_context:
  - "PROJECT_TREE.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
  - "01-RULES/03-SECURITY-RULES.md"
load_strategy: "progressive"
max_tokens_per_session: 8000
critical_sections:
  - "flujo-de-lectura"
  - "como-usar-con-ia"
  - "01-rules"
-->


# 📎 RAW URLs Index - Agentic Infrastructure

**Repositorio:** https://github.com/Mantis-AgenticDev/agentic-infra-docs  
**Rama:** main  
**Visibilidad:** 🔓 Público (durante desarrollo) / 🔒 Privado (fuera de horario de trabajo)  
**Horario de visibilidad pública:** 6 horas diarias (hora de Brasil)

---

## ⚠️ IMPORTANTE PARA IAs

Este repositorio alterna entre **público y privado** durante el desarrollo.

- **Cuando es PÚBLICO:** Las IAs pueden leer estas URLs directamente con web_extractor
- **Cuando es PRIVADO:** Las URLs no funcionan. Copiar/pegar contenido en el chat.

**Para verificar visibilidad:** Abrir en ventana de incógnito. Si carga sin login = Público.

---

## 📁 RAÍZ DEL REPOSITORIO

| Archivo | Descripción | URL Raw |
|---------|-------------|---------|
| README.md | Presentación del repositorio | https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/README.md | ✅ Creado |
| .gitignore | Reglas para no subir archivos sensibles |  |
| PROJECT_TREE.md | Mapa completo del proyecto con estados | https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/PROJECT_TREE.md | ✅ Creado |
| RAW_URLS_INDEX.md | Este archivo - índice de todas las URLs raw |  |

---

## 📂 00-CONTEXT/

| Archivo | Descripción | URL Raw | Estado |
|---------|-------------|---------|--------|
| PROJECT_OVERVIEW.md | Visión general bilingüe (ES+PT-BR) del proyecto | https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-CONTEXT/PROJECT_OVERVIEW.md | ✅ Creado |
| README.md | Reglas del repositorio para IAs |  | 🆕 Pendiente |
| facundo-core-context.md | Contexto base del usuario: dominio, stack, forma de trabajo |  | 🆕 Pendiente |
| facundo-infrastructure.md | Detalle técnico de infraestructura (3 VPS, specs, red) |  | 🆕 Pendiente |
| facundo-business-model.md | Modelo de negocio, pricing, SLA, proyecciones financieras |  | 🆕 Pendiente |

---

## 📂 01-RULES/

**Descripción:** Reglas de desarrollo, infraestructura y operación del proyecto.  
**Total de archivos:** 8  
**Estado:** ✅ Completado (según tu documentación)

| # | Archivo | Propósito | Prioridad | URL Raw | Estado |
|---|---------|-----------|-----------|---------|--------|
| 00 | 00-INDEX.md | Navegación y flujo de lectura | Siempre | https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/00-INDEX.md | ✅ Completado |
| 01 | 01-ARCHITECTURE-RULES.md | Infraestructura (VPS, Docker, red) | Alta | https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/01-ARCHITECTURE-RULES.md | ✅ Completado |
| 02 | 02-RESOURCE-GUARDRAILS.md | Recursos (VPS 4GB RAM, límites) | Siempre | https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/02-RESOURCE-GUARDRAILS.md | ✅ Completado |
| 03 | 03-SECURITY-RULES.md | Seguridad (UFW, SSH, fail2ban) | Alta | https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/03-SECURITY-RULES.md | ✅ Completado |
| 04 | 04-API-RELIABILITY-RULES.md | APIs externas (OpenRouter, Telegram) | Media | https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/04-API-RELIABILITY-RULES.md | ✅ Completado |
| 05 | 05-CODE-PATTERNS-RULES.md | Patrones de código (JS, Python, SQL) | Media | https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/05-CODE-PATTERNS-RULES.md | ✅ Completado |
| 06 | 06-MULTITENANCY-RULES.md | Datos (aislamiento por tenant) | Alta | https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/06-MULTITENANCY-RULES.md | ✅ Completado |
| 07 | 07-SCALABILITY-RULES.md | Escalabilidad (clientes por VPS) | Baja | https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/07-SCALABILITY-RULES.md | ✅ Completado |
| 08 | 08-SKILLS-REFERENCE.md | Skills reutilizables (02-SKILLS/) | Baja | https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/08-SKILLS-REFERENCE.md | ✅ Completado |

### 📖 Flujo de Lectura Recomendado para IAs

Orden recomendado para que una IA entienda el contexto:

    00-INDEX.md          → Navegación y visión general
    01-ARCHITECTURE-RULES.md → Infraestructura base
    02-RESOURCE-GUARDRAILS.md → Límites de recursos
    03-SECURITY-RULES.md → Seguridad
    04-API-RELIABILITY-RULES.md → APIs externas
    05-CODE-PATTERNS-RULES.md → Patrones de código
    06-MULTITENANCY-RULES.md → Aislamiento de datos
    07-SCALABILITY-RULES.md → Escalabilidad
    08-SKILLS-REFERENCE.md → Skills relacionadas

---

## 📂 02-SKILLS/

| Archivo | Descripción | URL Raw | Estado |
|---------|-------------|---------|--------|
| n8n-workflow-patterns.md | Patrones reutilizables para workflows de n8n |  | 🆕 Pendiente |
| whatsapp-rag-agents.md | Patrones para agentes de WhatsApp con RAG |  | 🆕 Pendiente |
| qdrant-rag-ingestion.md | Ingesta de documentos en Qdrant con tenant_id |  | 🆕 Pendiente |

*(Lista completa en PROJECT_TREE.md)*

---

## 📂 03-AGENTS/

| Archivo | Descripción | URL Raw | Estado |
|---------|-------------|---------|--------|
| health-monitor-agent.md | Agente de monitoreo de salud de VPS |  | 🆕 Pendiente |
| backup-manager-agent.md | Agente de gestión de backups | | 🆕 Pendiente |
| alert-dispatcher-agent.md | Agente de despacho de alertas |  | 🆕 Pendiente |

---

## 📂 05-CONFIGURATIONS/

| Archivo | Descripción | URL Raw | Estado |
|---------|-------------|---------|--------|
| vps1-n8n-uazapi.yml | Docker Compose para VPS 1 |  | 🆕 Pendiente |
| vps2-crm-qdrant.yml | Docker Compose para VPS 2 |  | 🆕 Pendiente |
| vps3-n8n-uazapi.yml | Docker Compose para VPS 3 |  | 🆕 Pendiente |
| .env.example | Ejemplo de variables de entorno |  | 🆕 Pendiente |

---

## 🚀 CÓMO USAR CON UNA IA (Ejemplo: Qwen)

### **En un chat nuevo:**

Hola, por favor lee este archivo primero para tener todas las URLs raw del proyecto:
[URL de RAW_URLS_INDEX.md]


**Paso 2: La IA sabrá qué URLs cargar según la tarea**

| Si quieres que la IA... | Debes pedir... |
|-------------------------|----------------|
| Entienda el proyecto completo | "Lee PROJECT_OVERVIEW.md y las reglas base (00-INDEX, 02-RESOURCE-GUARDRAILS, 03-SECURITY-RULES)" |
| Implemente seguridad | "Lee 03-SECURITY-RULES.md y las skills de seguridad" |
| Cree workflows de n8n | "Lee 08-SKILLS-REFERENCE.md y los patrones de n8n" |
| Configure un VPS | "Lee 01-ARCHITECTURE-RULES.md y vps-initial-setup.md" |

---

### **Comandos útiles para IAs**

```markdown
# Para que la IA cargue múltiples archivos de una vez:

"Por favor carga estos archivos en orden:
1. [URL de 00-CONTEXT/PROJECT_OVERVIEW.md]
2. [URL de 01-RULES/00-INDEX.md]
3. [URL de 01-RULES/02-RESOURCE-GUARDRAILS.md]
4. [URL de 01-RULES/03-SECURITY-RULES.md]"

# Para que la IA busque una regla específica:

"Busca en 01-RULES/ qué dice sobre [timeout/tenant_id/UFW]"

# Para que la IA genere un checklist:

"Basado en 01-RULES/03-SECURITY-RULES.md, dime si mi VPS cumple con todas las reglas"
```

Última actualización: 1 de Abril 2026
Versión: 1.0.0
Próxima revisión: Al completar Fase 1 (Cimientos)
