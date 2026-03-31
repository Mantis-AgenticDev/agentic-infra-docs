---
title: "INDEX DE RULES - Agentic Infra Docs"
category: "Navegación"
priority: "Siempre"
version: "1.0.0"
last_updated: "2026-03"
language: "es"
repository: "agentic-infra-docs"
owner: "Mantis-AgenticDev"
type: "index"
ia_parser_version: "2.0"
auto_validate: false
compliance_check: "on-demand"
total_files: 9
estimated_tokens: 5200
tags:
  - index
  - navigation
  - rules
  - metadata
related_files:
  - "00-CONTEXT/00-INDEX.md"
  - "02-SKILLS/00-INDEX.md"
---

# INDEX DE RULES - Agentic Infrastructure

## Metadatos del Documento

- **Repositorio:** agentic-infra-docs
- **Propietario:** Mantis-AgenticDev (Facundo)
- **Ubicación:** Rio Grande do Sul, Brasil
- **Versión:** 1.0.0
- **Última actualización:** Marzo 2026
- **Idioma:** Español / Português BR
- **Total de archivos:** 9
- **Tokens estimados (carga completa):** 5200

---

## Propósito de Este Directorio

Este directorio contiene reglas de desarrollo agnósticas a plataforma para todas las IA que intervengan en el proyecto. Son constraints verificables, no procedimientos paso a paso.

**Definición de regla:** Declaración técnica verificable que limita o guía decisiones de arquitectura y código.

**Ejemplo de regla:** "Todas las APIs externas deben tener timeout máximo de 5 segundos"

**Contraejemplo (esto va a PROCEDURES):** "Cómo configurar timeout en n8n paso a paso"

---

## Tabla de Archivos

| ID | Archivo                     | Categoría       | Prioridad | Tokens | Estado    |
|----|-----------------------------|-----------------|-----------|--------|-----------|
| 00 | 00-INDEX.md                 | Navegación      | Siempre   | 400    | Completado|
| 01 | 01-ARCHITECTURE-RULES.md    | Infraestructura | Alta      | 800    | Completado|
| 02 | 02-RESOURCE-GUARDRAILS.md   | Recursos        | Siempre   | 600    | Completado|
| 03 | 03-SECURITY-RULES.md        | Seguridad       | Alta      | 700    | Completado|
| 04 | 04-API-RELIABILITY-RULES.md | APIs            | Media     | 500    | Completado|
| 05 | 05-CODE-PATTERNS-RULES.md   | Código          | Media     | 900    | Completado|
| 06 | 06-MULTITENANCY-RULES.md    | Datos           | Alta      | 600    | Completado|
| 07 | 07-SCALABILITY-RULES.md     | Escalabilidad   | Baja      | 400    | Completado|
| 08 | 08-SKILLS-REFERENCE.md      | Skills          | Baja      | 300    | Completado|

---

## Flujo de Lectura Recomendado

### IA Inicia Sesión Nueva
Paso 1: 00-INDEX.md (este archivo)
Paso 2: 02-RESOURCE-GUARDRAILS.md (límites hardware)
Paso 3: 01-ARCHITECTURE-RULES.md (infraestructura base)

### Tareas de Arquitectura
Paso 1: 00-INDEX.md
Paso 2: 01-ARCHITECTURE-RULES.md
Paso 3: 02-RESOURCE-GUARDRAILS.md
Paso 4: 03-SECURITY-RULES.md

### Tareas de Código
Paso 1: 00-INDEX.md
Paso 2: 02-RESOURCE-GUARDRAILS.md
Paso 3: 05-CODE-PATTERNS-RULES.md
Paso 4: 04-API-RELIABILITY-RULES.md

### Tareas de Base de Datos
Paso 1: 00-INDEX.md
Paso 2: 02-RESOURCE-GUARDRAILS.md
Paso 3: 06-MULTITENANCY-RULES.md
Paso 4: 05-CODE-PATTERNS-RULES.md (sección SQL)

### Planificación de Escalabilidad
Paso 1: 00-INDEX.md
Paso 2: 01-ARCHITECTURE-RULES.md
Paso 3: 07-SCALABILITY-RULES.md


---

## Reglas de Uso

1. Nunca cargar todos los archivos simultáneamente si no es necesario
2. 00-INDEX.md y 02-RESOURCE-GUARDRAILS.md deben estar siempre en contexto
3. Los archivos numerados siguen orden de prioridad de carga
4. Cada archivo es autocontenido (no depende de lectura previa excepto INDEX)
5. Actualizar este INDEX cuando se agregue, elimine o modifique un archivo

---

## Relación con Otros Directorios

| Directorio        | Propósito                                | Ejemplo de Contenido             |
|-------------------|------------------------------------------|----------------------------------|
| 00-CONTEXT        | Quién eres, qué haces, modelo de negocio | facundo-business-model.md        |
| 01-RULES          | Constraints y patrones                   | Timeout máximo 5 segundos        |
| 02-SKILLS         | Procedimientos reutilizables             | Cómo configurar timeout en n8n   |
| 03-AGENTS         | Especificación de agentes                | health-monitor-agent.md          |
| 04-WORKFLOWS      | Workflows exportables de n8n             | INFRA-001-Monitor-Salud-VPS.json |
| 05-CONFIGURATIONS | Archivos de configuración                | docker-compose.yml, .env         |
| 06-PROGRAMMING    | Patrones de código por lenguaje          | api-call-patterns.md             |
| 07-PROCEDURES     | Checklists operativos                    | onboarding-client.md             |

---

## Lo Que Este Directorio No Es

- No es documentación de usuario final
- No es tutorial de implementación paso a paso
- No es registro de cambios (para eso existe CHANGELOG.md en root)
- No es específico de Cursor u otro IDE
- No contiene procedimientos operativos (van a 07-PROCEDURES)
- No contiene configuraciones específicas (van a 05-CONFIGURATIONS)

---

## Lo Que Este Directorio Sí Es

- Conjunto de reglas de desarrollo para IA
- Constraints técnicos verificables
- Patrones repetibles y validados
- Referencia rápida para decisiones de arquitectura
- Agnóstico a plataforma (funciona con cualquier IA)

---

## URLs Raw para IAs

Base URL:
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/01-RULES/


Ejemplos de URLs completas:
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/01-RULES/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/01-RULES/02-RESOURCE-GUARDRAILS.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/01-RULES/06-MULTITENANCY-RULES.md



---

## Historial de Versiones

| Versión | Fecha   | Cambios           | Autor |
|---------|---------|-------------------|-------|
| 1.0.0   | 2026-03 | Documento inicial |Facundo|

---

*Versión 1.0.0 - Marzo 2026 - Mantis-AgenticDev*
*Licencia: Creative Commons para uso interno del proyecto*
