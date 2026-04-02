---
title: "PROJECT TREE - Agentic Infra Docs"
category: "Documentación"
priority: "Siempre"
version: "2.1.0"
last_updated: "2026-03"
language: "es"
repository: "agentic-infra-docs"
owner: "Mantis-AgenticDev"
type: "documentation"
ia_parser_version: "2.0"
auto_validate: false
compliance_check: "on-demand"
tags:
  - tree
  - structure
  - navigation
  - project-map
related_files:
  - "README.md"
  - "PROJECT_OVERVIEW.md"
  - "00-CONTEXT/00-INDEX.md"
---
<!-- IA-NAVIGATION
priority_files:
  - "PROJECT_OVERVIEW.md"
  - "00-CONTEXT/facundo-core-context.md"
  - "01-RULES/00-INDEX.md"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
always_keep_in_context:
  - "00-CONTEXT/"
  - "01-RULES/02-RESOURCE-GUARDRAILS.md"
  - "01-RULES/03-SECURITY-RULES.md"
load_strategy: "progressive"
max_tokens_per_session: 8000
-->

---

# 🌳 Árbol Completo del Proyecto - Agentic Infrastructure

**Repositorio:** agentic-infra-docs  
**Owner:** Mantis-AgenticDev (Facundo)  
**Última actualización:** Marzo 2026  
**Estado:** 🚧 En desarrollo

---

## LEYENDA DE ESTADOS

| Símbolo | Estado      | Significado                      |
|---------|-------------|----------------------------------|
| ✅      | COMPLETADO  | Archivo creado y subido a GitHub |
| 🆕      | PENDIENTE   | Archivo por crear                |
| 📝      | EN PROGRESO | Archivo siendo editado           |
| 📋      | PLANEADO    | Definido pero no iniciado        |


agentic-infra-docs/
│
├── README.md                                 ✅ COMPLETADO
│   └── Presentación general del repositorio
│
├── .gitignore                                ✅ COMPLETADO
│   └── Reglas para no subir archivos sensibles
│
├── PROJECT_TREE.md                           📝 EN PROGRESO
│   └── Este archivo - mapa del proyecto
│
├── 00-CONTEXT/
│   ├── 00-INDEX.md                           🆕 PENDIENTE
│   │   └── Índice con URLs raw de todos los archivos de contexto
│   │
│   ├── PROJECT_OVERVIEW.md                   ✅ COMPLETADO 
│   │   └── Visión general bilingüe (ES+PT-BR) del proyecto completo
│   │
│   ├── README.md                             🆕 PENDIENTE
│   │   └── Reglas del repositorio, accesible para todas las IAs
│   │
│   ├── facundo-core-context.md               ✅ COMPLETADO 
│   │   └── Contexto base del usuario: dominio, stack, forma de trabajo
│   │
│   ├── facundo-infrastructure.md             🆕 PENDIENTE
│   │   └── Detalle técnico de infraestructura (3 VPS, specs, red)
│   │
│   └── facundo-business-model.md             🆕 PENDIENTE
│       └── Modelo de negocio, pricing, SLA, proyecciones financieras
│
├── 01-RULES/
│   ├── 00-INDEX.md                           ✅ COMPLETADO
│   │   └── Índice de todas las rules con URLs raw y flujo de lectura
│   │
│   ├── 01-ARCHITECTURE-RULES.md              ✅ COMPLETADO
│   │   └── Constraints de infraestructura (VPS, Docker, red, servicios)
│   │
│   ├── 02-RESOURCE-GUARDRAILS.md             ✅ COMPLETADO
│   │   └── Límites de recursos para VPS 4GB RAM (memoria, CPU, polling)
│   │
│   ├── 03-SECURITY-RULES.md                  ✅ COMPLETADO
│   │   └── Seguridad de VPS: UFW, SSH, fail2ban, permisos, secretos
│   │
│   ├── 04-API-RELIABILITY-RULES.md           ✅ COMPLETADO
│   │   └── Estándar de fiabilidad para APIs externas (OpenRouter, Telegram, Gmail)
│   │
│   ├── 05-CODE-PATTERNS-RULES.md             ✅ COMPLETADO
│   │   └── Patrones de código para JS, Python, SQL, Docker Compose, Bash
│   │
│   ├── 06-MULTITENANCY-RULES.md              ✅ COMPLETADO
│   │   └── Aislamiento de datos por tenant en MySQL y Qdrant
│   │
│   ├── 07-SCALABILITY-RULES.md               ✅ COMPLETADO
│   │   └── Criterios para escalar clientes por VPS (fases 1-2-3)
│   │
│   └── 08-SKILLS-REFERENCE.md                ✅ COMPLETADO
│       └── Pointer a skills reutilizables en 02-SKILLS/
│
├── 02-SKILLS/
│   ├── 00-INDEX.md                           🆕 PENDIENTE
│   │   └── Índice de todas las skills con URLs raw
│   │
│   ├── n8n-workflow-patterns.md              🆕 PENDIENTE
│   │   └── Patrones reutilizables para workflows de n8n
│   │
│   ├── whatsapp-rag-agents.md                🆕 PENDIENTE
│   │   └── Patrones para agentes de WhatsApp con RAG
│   │
│   ├── qdrant-rag-ingestion.md               🆕 PENDIENTE
│   │   └── Ingesta de documentos en Qdrant con tenant_id
│   │
│   ├── docker-compose-networking.md          🆕 PENDIENTE
│   │   └── Configuración de redes Docker entre VPS
│   │
│   ├── ssh-tunnels-remote-services.md        🆕 PENDIENTE
│   │   └── Túneles SSH para servicios remotos (MySQL, Qdrant)
│   │
│   ├── multi-tenant-data-isolation.md        🆕 PENDIENTE
│   │   └── Aislamiento de datos por tenant en MySQL y Qdrant
│   │
│   ├── espocrm-api-analytics.md              🆕 PENDIENTE
│   │   └── Uso de API de EspoCRM para reportes y analytics
│   │
│   ├── whatsapp-uazapi-integration.md        🆕 PENDIENTE
│   │   └── Integración con uazapi para WhatsApp no oficial
│   │
│   ├── telegram-bot-integration.md           🆕 PENDIENTE
│   │   └── Integración con Telegram Bot para alertas
│   │
│   ├── gmail-smtp-integration.md             🆕 PENDIENTE
│   │   └── Integración con Gmail SMTP para envío de emails
│   │
│   ├── google-calendar-api-integration.md    🆕 PENDIENTE
│   │   └── Integración con Google Calendar API para eventos
│   │
│   ├── fail2ban-configuration.md             🆕 PENDIENTE
│   │   └── Configuración de fail2ban para protección SSH
│   │
│   ├── ufw-firewall-configuration.md         🆕 PENDIENTE
│   │   └── Configuración de firewall UFW en VPS
│   │
│   ├── ssh-key-management.md                 🆕 PENDIENTE
│   │   └── Gestión de claves SSH para autenticación
│   │
│   ├── mysql-optimization-4gb-ram.md         🆕 PENDIENTE
│   │   └── Optimización de MySQL para VPS con 4GB RAM
│   │
│   ├── n8n-concurrency-limiting.md           🆕 PENDIENTE
│   │   └── Limitación de concurrencia en n8n para evitar saturación
│   │
│   ├── backup-encryption.md                  🆕 PENDIENTE
│   │   └── Encriptación de backups para seguridad
│   │
│   ├── rsync-automation.md                   🆕 PENDIENTE
│   │   └── Automatización de rsync para pull de backups
│   │
│   └── environment-variable-management.md    🆕 PENDIENTE
│       └── Gestión de variables de entorno (.env)
│
├── 03-AGENTS/
│   ├── 00-INDEX.md                           🆕 PENDIENTE
│   │   └── Índice de todos los agentes
│   │
│   ├── infrastructure/
│   │   ├── 00-INDEX.md                       🆕 PENDIENTE
│   │   │   └── Índice de agentes de infraestructura
│   │   │
│   │   ├── health-monitor-agent.md           🆕 PENDIENTE
│   │   │   └── Agente de monitoreo de salud de VPS (polling cada 5 min)
│   │   │
│   │   ├── backup-manager-agent.md           🆕 PENDIENTE
│   │   │   └── Agente de gestión de backups (diario 4 AM)
│   │   │
│   │   ├── alert-dispatcher-agent.md         🆕 PENDIENTE
│   │   │   └── Agente de despacho de alertas (Telegram, Gmail, Calendar)
│   │   │
│   │   └── security-hardening-agent.md       🆕 PENDIENTE
│   │       └── Agente de endurecimiento de seguridad (UFW, SSH, fail2ban)
│   │
│   └── clients/
│       ├── 00-INDEX.md                       🆕 PENDIENTE
│       │   └── Índice de agentes de clientes
│       │
│       ├── whatsapp-attention-agent.md       🆕 PENDIENTE
│       │   └── Agente de atención por WhatsApp (uazapi + RAG + OpenRouter)
│       │
│       ├── rag-knowledge-agent.md            🆕 PENDIENTE
│       │   └── Agente de conocimiento RAG (Qdrant + tenant_id)
│       │
│       └── espocrm-analytics-agent.md        🆕 PENDIENTE
│           └── Agente de analytics de EspoCRM (reportes para clientes Full)
│
├── 04-WORKFLOWS/
│   ├── 00-INDEX.md                           🆕 PENDIENTE
│   │   └── Índice de todos los workflows
│   │
│   ├── n8n/
│   │   ├── 00-INDEX.md                       🆕 PENDIENTE
│   │   │   └── Índice de workflows de n8n
│   │   │
│   │   ├── INFRA-001-Monitor-Salud-VPS.json  🆕 PENDIENTE
│   │   │   └── Workflow de monitoreo de salud de VPS (cada 5 min)
│   │   │
│   │   ├── INFRA-002-Backup-Manager.json     🆕 PENDIENTE
│   │   │   └── Workflow de gestión de backups (diario 4 AM)
│   │   │
│   │   ├── INFRA-003-Alert-Dispatcher.json   🆕 PENDIENTE
│   │   │   └── Workflow de despacho de alertas
|   |   |
|   |   ├── INFRA-004-Security-Hardening.json   🆕 PENDIENTE
│   │   │   └── Workflow verifica, aplica configuraciones de seguridad en los VPS (cada 6 horas) 
│   │   │
│   │   └── CLIENT-001-WhatsApp-RAG.json      🆕 PENDIENTE
│   │       └── Workflow de atención WhatsApp con RAG
│   │
│   └── diagrams/
│       ├── 00-INDEX.md                       🆕 PENDIENTE
│       │   └── Índice de diagramas
│       │
│       ├── architecture-overview.png         🆕 PENDIENTE
│       │   └── Diagrama de arquitectura de 3 VPS
│       │
│       ├── data-flow.png                     🆕 PENDIENTE
│       │   └── Diagrama de flujo de datos
│       │
│       └── security-architecture.png         🆕 PENDIENTE
│           └── Diagrama de arquitectura de seguridad
│
├── 05-CONFIGURATIONS/
│   ├── 00-INDEX.md                           🆕 PENDIENTE
│   │   └── Índice de todas las configuraciones
│   │
│   ├── docker-compose/
│   │   ├── 00-INDEX.md                       🆕 PENDIENTE
│   │   │   └── Índice de archivos docker-compose
│   │   │
│   │   ├── vps1-n8n-uazapi.yml               🆕 PENDIENTE
│   │   │   └── Docker Compose para VPS 1 (n8n + uazapi + Redis)
│   │   │
│   │   ├── vps2-crm-qdrant.yml               🆕 PENDIENTE
│   │   │   └── Docker Compose para VPS 2 (EspoCRM + MySQL + Qdrant)
│   │   │
│   │   └── vps3-n8n-uazapi.yml               🆕 PENDIENTE
│   │       └── Docker Compose para VPS 3 (n8n + uazapi)
│   │
│   ├── scripts/
│   │   ├── 00-INDEX.md                       🆕 PENDIENTE
│   │   │   └── Índice de scripts bash
│   │   │
│   │   ├── health-check.sh                   🆕 PENDIENTE
│   │   │   └── Script de health check para VPS (cada 5 min)
│   │   │
│   │   ├── backup-mysql.sh                   🆕 PENDIENTE
│   │   │   └── Script de backup de MySQL (diario 4 AM)
│   │   │
│   │   ├── backup-qdrant.sh                  🆕 PENDIENTE
│   │   │   └── Script de backup de Qdrant (snapshots)
│   │   │
│   │   ├── test-alerts.sh                    🆕 PENDIENTE
│   │   │   └── Script de prueba de alertas (Telegram, Gmail, Calendar)
│   │   │
│   │   └── restore-mysql.sh                  🆕 PENDIENTE
│   │       └── Script de restauración de MySQL
│   │
│   └── environment/
│       ├── 00-INDEX.md                       🆕 PENDIENTE
│       │   └── Índice de archivos de entorno
│       │
│       └── .env.example                      🆕 PENDIENTE
│           └── Ejemplo de variables de entorno (sin valores reales)
│
├── 06-PROGRAMMING/
│   ├── 00-INDEX.md                           🆕 PENDIENTE
│   │   └── Índice de todos los patrones de programación
│   │
│   ├── python/
│   │   ├── 00-INDEX.md                       🆕 PENDIENTE
│   │   │   └── Índice de patrones Python
│   │   │
│   │   ├── api-call-patterns.md              🆕 PENDIENTE
│   │   │   └── Patrones para llamadas API con requests
│   │   │
│   │   ├── telegram-bot-integration.md       🆕 PENDIENTE
│   │   │   └── Integración con Telegram Bot en Python
│   │   │
│   │   └── google-calendar-api.md            🆕 PENDIENTE
│   │       └── Integración con Google Calendar API en Python
│   │
│   ├── sql/
│   │   ├── 00-INDEX.md                       🆕 PENDIENTE
│   │   │   └── Índice de patrones SQL
│   │   │
│   │   ├── multi-tenant-schema.md            🆕 PENDIENTE
│   │   │   └── Esquema multi-tenant para MySQL
│   │   │
│   │   ├── indexed-queries.md                🆕 PENDIENTE
│   │   │   └── Queries con índices optimizados
│   │   │
│   │   └── backup-restore-commands.md        🆕 PENDIENTE
│   │       └── Comandos SQL para backup y restauración
│   │
│   └── javascript/
│       ├── 00-INDEX.md                       🆕 PENDIENTE
│       │   └── Índice de patrones JavaScript
│       │
│       ├── n8n-function-node-patterns.md     🆕 PENDIENTE
│       │   └── Patrones para Function Node de n8n
│       │
│       └── async-error-handling.md           🆕 PENDIENTE
│           └── Manejo de errores asíncronos en JavaScript
│
├── 07-PROCEDURES/
│   ├── 00-INDEX.md                           🆕 PENDIENTE
│   │   └── Índice de todos los procedimientos
│   │
│   ├── vps-initial-setup.md                  🆕 PENDIENTE
│   │   └── Procedimiento de configuración inicial de VPS (12 pasos)
│   │
│   ├── onboarding-client.md                  🆕 PENDIENTE
│   │   └── Procedimiento de onboarding de clientes (12 pasos)
│   │
│   ├── incident-response-checklist.md        🆕 PENDIENTE
│   │   └── Checklist de respuesta a incidentes (12 pasos)
│   │
│   ├── backup-restore-test.md                🆕 PENDIENTE
│   │   └── Procedimiento de test de restauración de backup (12 pasos)
│   │
│   ├── scaling-decision-matrix.md            🆕 PENDIENTE
│   │   └── Matriz de decisión para escalar clientes por VPS
│   │
│   ├── fire-drill-test-procedures.md         🆕 PENDIENTE
│   │   └── Procedimientos de test de incendio (5 escenarios)
│   │
│   ├── backup-restore-procedures.md          🆕 PENDIENTE
│   │   └── Procedimientos detallados de backup y restauración (movido desde RULES)
│   │
│   ├── monitoring-alerts-procedures.md       🆕 PENDIENTE
│   │   └── Procedimientos de alertas de monitoreo (movido desde RULES)
│   │
│   └── weekly-checklist-template.md          🆕 PENDIENTE
│       └── Plantilla de checklist semanal para seguimiento
│
├── 08-LOGS/
│   ├── 00-INDEX.md                           🆕 PENDIENTE
│   │   └── Índice de logs (referencia)
│   │
│   └── .gitkeep                              ✅ COMPLETADO
│       └── Archivo vacío para mantener carpeta en Git
│
└── .github/
    └── workflows/
        └── 00-INDEX.md                       🆕 PENDIENTE
            └── Índice de workflows de GitHub Actions (futuro)
---

## 📊 RESUMEN DE ESTADO

Carpeta	            Archivos  Completados	Archivos Pendientes	  Total% Completado
Raíz	            3	      1	            4	                  75%
00-CONTEXT/	        1	      5	            6                     17%
01-RULES/	        9	      9	            0	                  100%
02-SKILLS/	        0	      20	        20	                  0%
03-AGENTS/	        0	      9         	9	                  0%
04-WORKFLOWS/	    0	      10        	10	                  0%
05-CONFIGURATIONS/	0	      12        	12	                  0%
06-PROGRAMMING/	    0	      9	            9	                  0%
07-PROCEDURES/	    0	      10        	10                    0%
08-LOGS/	        1	      1	            2                     50%
TOTAL	            5	      86        	91                    5.5%


---

## 🎯 PRIORIDADES DE CREACIÓN

### **Fase 1: Cimientos (Semana 1-2)**

Prioridad	Archivo	                    Carpeta                     	Razón
🔴 CRÍTICA	00-INDEX.md	                00-CONTEXT/	                    Índice de contexto para IAs
🔴 CRÍTICA	facundo-core-context.md	    00-CONTEXT/	                    Contexto base del usuario
🔴 CRÍTICA	facundo-infrastructure.md	00-CONTEXT/	                    Detalle técnico de infra
🔴 CRÍTICA	00-INDEX.md	                01-RULES/	                    Índice de rules para IAs
🔴 CRÍTICA	02-RESOURCE-GUARDRAILS.md	01-RULES/	                    Límites de recursos 4GB
🔴 CRÍTICA	01-ARCHITECTURE-RULES.md	01-RULES/	                    Constraints de infraestructura
🟠 ALTA	    03-SECURITY-RULES.md	    01-RULES/	                    Seguridad de VPS
🟠 ALTA	    06-MULTITENANCY-RULES.md	01-RULES/	                    Aislamiento de datos
🟠 ALTA	    .env.example	            05-CONFIGURATIONS/environment/	Variables de entorno


### **Fase 2: Configuraciones Técnicas (Semana 3-4)**

Prioridad	Archivo	                    Carpeta	                            Razón
🔴 CRÍTICA	vps1-n8n-uazapi.yml	        05-CONFIGURATIONS/docker-compose/	Docker VPS 1
🔴 CRÍTICA	vps2-crm-qdrant.yml	        05-CONFIGURATIONS/docker-compose/	Docker VPS 2
🔴 CRÍTICA	vps3-n8n-uazapi.yml	        05-CONFIGURATIONS/docker-compose/	Docker VPS 3
🔴 CRÍTICA	health-check.sh	            05-CONFIGURATIONS/scripts/	        Health check
🔴 CRÍTICA	backup-mysql.sh	            05-CONFIGURATIONS/scripts/	        Backup MySQL
🟠 ALTA	    04-API-RELIABILITY-RULES.md	01-RULES/	                        Fiabilidad de APIs
🟠 ALTA	    05-CODE-PATTERNS-RULES.md	01-RULES/	                        Patrones de código


### **Fase 3: Agentes y Workflows (Semana 5-8)**

Prioridad	Archivo	                           Carpeta	                    Razón
🟠 ALTA	    health-monitor-agent.md	            03-AGENTS/infrastructure/	Agente de monitoreo
🟠 ALTA	    backup-manager-agent.md	            03-AGENTS/infrastructure/	Agente de backup
🟠 ALTA	    alert-dispatcher-agent.md	        03-AGENTS/infrastructure/	Agente de alertas
🟡 MEDIA	INFRA-001-Monitor-Salud-VPS.json	04-WORKFLOWS/n8n/       	Workflow monitoreo
🟡 MEDIA	INFRA-002-Backup-Manager.json	    04-WORKFLOWS/n8n/	        Workflow backup


### **Fase 4: Skills y Procedimientos (Semana 9-12)**

Prioridad	Archivo	                        Carpeta	         Razón
🟡 MEDIA	00-INDEX.md	                    02-SKILLS/	     Índice de skills
🟡 MEDIA	n8n-workflow-patterns.md	    02-SKILLS/	     Patrones n8n
🟡 MEDIA	onboarding-client.md	        07-PROCEDURES/	 Onboarding clientes
🟡 MEDIA	incident-response-checklist.md	07-PROCEDURES/	 Respuesta incidentes
🟡 MEDIA	07-SCALABILITY-RULES.md	        01-RULES/	     Criterios de escalado
🟡 MEDIA	08-SKILLS-REFERENCE.md	        01-RULES/	     Pointer a skills


---

## 📝 NOTAS IMPORTANTES

### **Para IAs en chats nuevos:**

Cuando abras un chat nuevo con cualquier IA (incluyéndome), proporciona:

URL del PROJECT_OVERVIEW.md (visión general)
URL del 00-INDEX.md de la carpeta que vas a trabajar
URLs de los archivos específicos que necesitas


### **Para mantener actualizado:**

Cada vez que crees un archivo nuevo, actualiza este PROJECT_TREE.md
Cambia el estado de 🆕 a ✅
Actualiza el resumen de estado (% completado)
Haz commit y push del PROJECT_TREE.md también

### **URLs Raw para IAs (cuando el repo sea público):**


Base URL: https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/

Ejemplos:
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/PROJECT_OVERVIEW.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/00-CONTEXT/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/01-RULES/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/main/05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml
    

---

## 🚀 SIGUIENTES PASOS INMEDIATOS

Orden	Archivo	                    Carpeta	        Estado
1	    00-INDEX.md	                00-CONTEXT/ 	🆕 PENDIENTE
2	    facundo-core-context.md	    00-CONTEXT/	    🆕 PENDIENTE
3	    facundo-infrastructure.md	00-CONTEXT/	    🆕 PENDIENTE
4	    facundo-business-model.md	00-CONTEXT/  	🆕 PENDIENTE
5	    00-INDEX.md	                01-RULES/	    ✅ COMPLETADO
6	    02-RESOURCE-GUARDRAILS.md	01-RULES/	    ✅ COMPLETADO
7	    01-ARCHITECTURE-RULES.md	01-RULES/	    ✅ COMPLETADO

---
##    VALIDACIÓN DE ESTRUCTURA

Criterio	                               Estado	         Observación
Separación RULES vs PROCEDURES	            ✅ Correcta	     Rules = constraints, Procedures = pasos
Separación RULES vs SKILLS	                ✅ Correcta	     Rules = qué hacer, Skills = cómo hacer
Separación AGENTS vs WORKFLOWS	            ✅ Correcta	     Agents = especificación, Workflows = implementación
Separación CONFIGURATIONS vs PROGRAMMING	✅ Correcta	     Configs = archivos ejecutables, Programming = patrones
INDEX en cada carpeta	                    ✅ Correcta	     Permite navegación autónoma por IA
Numeración de archivos	                    ✅ Correcta	     Orden de carga/prioridad claro
Total de archivos	                        ✅ Optimizado	 91 vs 92 originales (sin inflación)


Última actualización: Marzo 2026
Próxima revisión: Al completar Fase 1 (Cimientos)
Versión del árbol: 2.1.0 (estructura corregida)




---

## 🚀 SIGUIENTES PASOS INMEDIATOS

1. ✅ Guardar este archivo como `PROJECT_TREE.md` en la raíz del repositorio
2. 🆕 Crear `00-CONTEXT/00-INDEX.md`
3. 🆕 Crear `00-CONTEXT/facundo-core-context.md`
4. 🆕 Crear `00-CONTEXT/facundo-infrastructure.md`
5. 🆕 Crear `00-CONTEXT/facundo-business-model.md`
6. 🆕 Crear `01-RULES/00-INDEX.md`

---

*Última actualización: Marzo 2026*
*Próxima revisión: Al completar Fase 1 (Cimientos)*
