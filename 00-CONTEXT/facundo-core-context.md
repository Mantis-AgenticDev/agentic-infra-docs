---
title: "Facundo Core Context - Agentic Infra Docs"
category: "Contexto"
priority: "Siempre"
version: "1.0.0"
last_updated: "2026-04-05"
language: "es"
repository: "agentic-infra-docs"
owner: "Mantis-AgenticDev"
type: "overview"
ia_parser_version: "2.0"
auto_validate: true
compliance_check: "weekly"
validation_script: "scripts/validate-against-specs.sh"
auto_fixable: false
severity_scope: "critical"
tags:
  - perfil-usuario
  - principios
  - constraints
  - tenant-id
related_files:
  - "00-CONTEXT/PROJECT_OVERVIEW.md"
  - "00-CONTEXT/facundo-business-model.md"
  - "01-RULES/06-MULTITENANCY-RULES.md"
---

<!-- IA-NAVIGATION
priority_files:
  - "00-CONTEXT/PROJECT_OVERVIEW.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
always_keep_in_context:
  - "facundo-core-context.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
load_strategy: "full"
max_tokens_per_session: 4000
critical_sections:
  - "constraints-absolutos"
  - "actualizacion-y-mantenimiento"
-->
---

# FACUNDO CORE CONTEXT - MANTIS AGENTIC

## 🎯 PROPÓSITO DEL DOCUMENTO
Este archivo establece el contexto fundamental del usuario y del proyecto para cualquier IA que intervenga en el ecosistema MANTIS AGENTIC. Contiene información persistente, principios rectores y constraints que NO deben ser ignorados ni sobrescritos.

## 👤 PERFIL DEL USUARIO PRINCIPAL


| Campo            | Valor                                                    |
|------------------|----------------------------------------------------------|
| Nombre           | Facundo                                                  |
| Ubicación Base   | xxxxxxxxxxxxx / Porto Alegre, Rio Grande do Sul, Brasil  |
| Registro         | xxxxxxxxxxxx (Brasil)                                    |
| Enfoque Técnico  | xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx        |
| Stack Tecnológico| Linux, n8n, Docker, Python, RAG, Qdrant                  |
| Idiomas          | Español, Portugués, Inglés (técnico)                     |
| Filosofía        | Ciencia abierta                                          |


## 🧭 PRINCIPIOS RECTORES DEL PROYECTO

### Prioridad 1: Estabilidad del Servicio
- Ninguna innovación compromete la disponibilidad del servicio
- SLA objetivo: 99.5% uptime para clientes activos
- Recuperación ante fallos: < 60 minutos para restauración crítica

### Prioridad 2: Protección de Datos y Procesos
- Backup diario automático a las 04:00 AM (UTC-3)
- Copias encriptadas y validadas semanalmente
- Separación estricta de tenant_id en todas las consultas

### Prioridad 3: Eficiencia de Recursos
- Hardware limitado: 3 VPS x 4GB RAM, 1 vCPU, 50GB NVMe c/u
- Prohibido: modelos de IA locales, procesamiento pesado en VPS
- Obligatorio: uso de APIs cloud para componentes de alta demanda

### Prioridad 4: Innovación con Restricciones
- Innovar dentro de los límites de hardware establecidos
- Validar cada nueva funcionalidad con checklist de recursos
- Documentar cualquier desviación temporal con plan de reversa

## 🔗 NAVEGACIÓN PARA IA - FLUJO RECOMENDADO

[IA inicia sesión]
        │
        ▼
+---------------------+
| 1. Leer este archivo|
| facundo-core-context|
+---------------------+
        │
        ▼
+---------------------+     +---------------------+
| 2. Cargar rules:    |---->| 3. Validar contra   |
| -RESOURCE-GUARDRAILS|     | ARCHITECTURE-RULES  |
| -ARCHITECTURE-RULES |     +---------------------+
+---------------------+
        │
        ▼
+---------------------+
| 4. Consultar:       |
| - infrastructure.md |
| - business-model.md |
+---------------------+
        │
        ▼
[Proceder con tarea asignada]


## ⚠️ CONSTRAINTS ABSOLUTOS (NO NEGOCIABLES)


| ID | Restricción                               | Consecuencia si se viola     |
|----|-------------------------------------------|------------------------------|
| C1 | Máximo 4 GB RAM por VPS                   | Caída del servicio           |
| C2 | Máximo 1 vCPU por VPS                     | Saturación y timeout         |
| C3 | MySQL y Qdrant NUNCA expuestos a 0.0.0.0  | Brecha de seguridad          |
| C4 | tenant_id obligatorio en TODAS las queries| Fuga de datos entre clientes |
| C5 | Backup diario validado                    | Pérdida de datos crítica     |
| C6 | No modelos de IA locales en VPS           | Colapso por memoria          |


## 🔄 ACTUALIZACIÓN Y MANTENIMIENTO

- Este archivo se revisa trimestralmente o ante cambios estructurales
- Cualquier modificación requiere: 
  1. Validación contra PROJECT_OVERVIEW.md
  2. Actualización de version y last_updated
  3. Notificación a logs de auditoría

## 📌 NOTAS PARA EL DESARROLLO FUTURO

> "La estabilidad no es un feature, es el fundamento. Cada línea de código, 
> cada configuración, cada decisión arquitectónica debe responder primero a: 
> ¿Esto hace el sistema más resistente o más frágil?"

---
FIN DEL ARCHIVO - facundo-core-context.md

## 🔗 Conexiones Estructurales (Auto-generado)
[[README.md]]
[[00-CONTEXT/00-INDEX.md]]
