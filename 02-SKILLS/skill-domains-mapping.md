---
canonical_path: "/02-SKILLS/skill-domains-mapping.md"
artifact_id: "skill-domains-mapping-canonical"
artifact_type: "governance_mapping"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C5", "C6"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 02-SKILLS/skill-domains-mapping.md --mode headless --json"
tier: 1
immutable: true
requires_human_approval_for_changes: true
related_files:
  - "[[02-SKILLS/00-INDEX.md]]"
  - "[[01-RULES/08-SKILLS-REFERENCE.md]]"
  - "[[05-CONFIGURATIONS/validation/norms-matrix.json]]"
  - "[[GOVERNANCE-ORCHESTRATOR.md]]"
checksum_sha256: "PENDING_GENERATION"
---


# 📄 02-SKILLS/skill-domains-mapping.md – REGENERADO COMPLETO v3.0-SELECTIVE

> **Nota para principiantes:** Este documento es el **"puente de solución"** entre las necesidades de negocio (lo que el cliente quiere) y la arquitectura técnica (cómo lo construimos con skills horizontales). Si eres nuevo, lee las secciones en orden. Si eres experto, salta al JSON final.  
>  
> **Para IAs:** Este es tu mapa de recomendación. **RECOMENDAR SOLUCIONES NO MAPEADAS O SIN REVISIÓN DE CONSTRAINTS = ERROR CRÍTICO**. No inventes, no asumas, no omitas.


# 🗺️ SKILL-DOMAINS-MAPPING: Mapeo de Necesidades de Negocio a Arquitectura Técnica

<!-- 
【PARA PRINCIPIANTES】¿Qué es este archivo?
Este documento es el "menú de soluciones" de MANTIS AGENTIC.
Conecta problemas reales de empresas (ej: "Necesito gestionar reservas") 
con las habilidades técnicas específicas (skills) que resuelven el problema.

Si eres nuevo: lee en orden. 
Si ya conoces el proyecto: usa los wikilinks para ir directo a la arquitectura que necesitas.
-->

> **Instrucción crítica para la IA:** 
> Este documento es tu mapa de recomendación. 
> **RECOMENDAR SOLUCIONES NO MAPEADAS O SIN REVISIÓN DE CONSTRAINTS = ERROR CRÍTICO**. 
> No inventes, no asumas, no omitas. Si algo no está claro, DETENER y preguntar.

---

## 【0】🎯 PROPÓSITO Y ALCANCE (Explicado para humanos)

<!-- 
【EDUCATIVO】Este documento responde: "Tengo un cliente de [Industria] con [Problema], ¿qué skills uso?"
No es teoría de negocios. Es una guía de ensamblaje que:
• Traduce necesidades de negocio en stacks técnicos modulares
• Identifica constraints críticos (ej: C4 para salud, C3 para pagos)
• Asegura que no reinventamos la rueda: reutiliza skills horizontales validadas
• Sirve como fuente de verdad para propuestas comerciales y arquitectura
-->

### 0.1 Flujo de Mapeo: De Negocio a Código

```mermaid
graph LR
    A[Cliente/Negocio] --> B(Necesidad Específica)
    B --> C{Consultar Mapeo}
    C --> D[Skills Horizontales Requeridas]
    D --> E[Validar Constraints Críticas]
    E --> F[Ensamblar Solución Vertical]
    F --> G[Validar con orchestrator-engine.sh]
    G --> H[Entrega Tier 3 (Desplegable)]
```

### 0.2 Resumen de Dominios Mapeados (Estado Actual)

| Industria Vertical | Caso de Uso Principal | Skills Clave | Estado Global | Constraints Críticas | Wikilink Canónico |
|--------------------|-----------------------|--------------|--------------|---------------------|-------------------|
| **AI/LLMs** | Integración de modelos de IA | 11 skills | ✅ 11/11 Listo | C3,C4,C5,C8 | `[[02-SKILLS/AI/]]` |
| **INFRAESTRUCTURA** | Servidores, redes, contenedores | 10 skills | ✅ 10/10 Listo | C1,C3,C5,C7 | `[[02-SKILLS/INFRAESTRUCTURA/]]` |
| **BASE DE DATOS-RAG** | RAG, aislamiento multi-tenant | 12 skills | ✅ 12/12 Listo | C3,C4,C5,V1 | `[[02-SKILLS/BASE DE DATOS-RAG/]]` |
| **COMUNICACIÓN** | WhatsApp, Telegram, Email | 5 skills | 🟡 4/5 Listo | C3,C4,C5,C7 | `[[02-SKILLS/COMUNICACIÓN/]]` |
| **SEGURIDAD** | Backups, hardening | 3 skills | ✅ 3/3 Listo | C3,C5,C8 | `[[02-SKILLS/SEGURIDAD/]]` |
| **WHATSAPP-RAG AGENTS** | Agentes conversacionales RAG | 4 skills | 🆕 1/4 Pendiente | C3,C4,C5,C7,C8 | `[[02-SKILLS/WHATSAPP-RAG AGENTS/]]` |
| **INSTAGRAM-SOCIAL-MEDIA** | Contenido y análisis social | 6 skills | 🆕 0/6 Nuevo | C3,C5,C6 | `[[02-SKILLS/INSTAGRAM-SOCIAL-MEDIA/]]` |
| **ODONTOLOGÍA** | Citas, pacientes, privacidad | 6 skills | 🆕 0/6 Nuevo | C4,C5,C6,C8 | `[[02-SKILLS/ODONTOLOGÍA/]]` |
| **HOTELES-POSADAS** | Reservas, huésped, operaciones | 7 skills | 🆕 0/7 Nuevo | C1,C3,C4,C5 | `[[02-SKILLS/HOTELES-POSADAS/]]` |
| **RESTAURANTES** | Pedidos, reservas, menús | 10 skills | 🆕 0/10 Nuevo | C3,C4,C5,C7 | `[[02-SKILLS/RESTAURANTES/]]` |
| **CORPORATE-KB** | Conocimiento corporativo RAG | 5 skills | 🆕 0/5 Nuevo | C4,C5,C6 | `[[02-SKILLS/CORPORATE-KB/]]` |
| **N8N-PATTERNS** | Workflows y agentes n8n | 3 skills | 🆕 0/3 Nuevo | C5,C6,C7 | `[[02-SKILLS/N8N-PATTERNS/]]` |
| **AGENTIC-ASSISTANCE** | Integración IDE/CLI | 1 skill | ✅ 1/1 Listo | C5,C6 | `[[02-SKILLS/AGENTIC-ASSISTANCE/]]` |
| **DEPLOYMENT** | Despliegue multi-canal | 1 skill | ✅ 1/1 Listo | C1-C8 | `[[02-SKILLS/DEPLOYMENT/]]` |

> 💡 **Consejo para principiantes**: No intentes crear skills nuevas para cada cliente. Empieza copiando la solución vertical de este mapeo y adáptala.

---

## 【1】🧠 DOMINIO: AI/LLMS (Integración de Modelos)

```
【PROPÓSITO】Catálogo de proveedores de IA, sus límites de coste, estrategias de fallback y modos de integración.

【ESTADO】✅ 11/11 Skills Validadas y Listas

【SKILLS DISPONIBLES】
| Skill | Estado | Función Principal | Constraints | Wikilink |
|-------|--------|-----------------|------------|----------|
| `openrouter-integration.md` | ✅ | Router unificado, retry, fallback y control de costes | C3,C4,C5,C7,C8 | `[[02-SKILLS/AI/openrouter-integration.md]]` |
| `qwen-integration.md` | ✅ | Modelo base prioritario, contexto largo y JSON mode | C3,C4,C5,C8 | `[[02-SKILLS/AI/qwen-integration.md]]` |
| `deepseek-integration.md` | ✅ | Reasoning optimizado y fallback coder | C3,C4,C5,C8 | `[[02-SKILLS/AI/deepseek-integration.md]]` |
| `llama-integration.md` | ✅ | Modelos open-weight y ejecución local (excepción C6) | C3,C5,C6 | `[[02-SKILLS/AI/llama-integration.md]]` |
| `gemini-integration.md` | ✅ | Entradas multimodales, streaming y filtros de seguridad | C3,C4,C5,C8 | `[[02-SKILLS/AI/gemini-integration.md]]` |
| `gpt-integration.md` | ✅ | Function calling y salidas estructuradas | C3,C4,C5,C8 | `[[02-SKILLS/AI/gpt-integration.md]]` |
| `minimax-integration.md` | ✅ | Contexto ultra-largo (~1M tokens) y procesamiento iterativo | C3,C4,C5,C8 | `[[02-SKILLS/AI/minimax-integration.md]]` |
| `mistral-ocr-integration.md` | ✅ | Extracción avanzada de documentos y tablas | C3,C5,C8 | `[[02-SKILLS/AI/mistral-ocr-integration.md]]` |
| `voice-agent-integration.md` | ✅ | STT/TTS, chunks de audio y aislamiento por tenant | C3,C4,C5,C8 | `[[02-SKILLS/AI/voice-agent-integration.md]]` |
| `image-gen-api.md` | ✅ | Generación de imágenes con filtros y lotes | C3,C5,C8 | `[[02-SKILLS/AI/image-gen-api.md]]` |
| `video-gen-api.md` | ✅ | Text/Img-to-Video, codecs y límites de duración | C3,C5,C8 | `[[02-SKILLS/AI/video-gen-api.md]]` |

【CONSTRAINTS CRÍTICAS】
• **C3 (Zero Secrets)**: API keys de proveedores NUNCA en código. Usar variables de entorno o secret managers.
• **C4 (Tenant Isolation)**: Aislamiento de prompts y respuestas por tenant_id.
• **C8 (Observability)**: Logging estructurado de costes, latencia y errores por modelo.

【CASOS DE USO RECOMENDADOS】
• "Necesito un agente conversacional barato" → `qwen-integration.md` + `openrouter-integration.md`
• "Necesito razonamiento complejo" → `deepseek-integration.md` + fallback a `qwen-integration.md`
• "Necesito procesamiento de documentos" → `mistral-ocr-integration.md` + `qdrant-rag-ingestion.md`
```

---

## 【2】📡 DOMINIO: INFRAESTRUCTURA (Servidores y Redes)

```
【PROPÓSITO】Configuración y mantenimiento de servidores VPS, redes, contenedores y monitoreo.

【ESTADO】✅ 10/10 Skills Validadas y Listas

【SKILLS DISPONIBLES】
| Skill | Estado | Función Principal | Constraints | Wikilink |
|-------|--------|-----------------|------------|----------|
| `ssh-tunnels-remote-services.md` | ✅ | Túneles SSH seguros para MySQL, Qdrant entre VPS | C3,C4,C5 | `[[02-SKILLS/INFRAESTRUCTURA/ssh-tunnels-remote-services.md]]` |
| `docker-compose-networking.md` | ✅ | Redes Docker aisladas entre VPS | C1,C3,C5 | `[[02-SKILLS/INFRAESTRUCTURA/docker-compose-networking.md]]` |
| `espocrm-setup.md` | ✅ | Instalación y configuración del CRM base | C3,C5,C7 | `[[02-SKILLS/INFRAESTRUCTURA/espocrm-setup.md]]` |
| `fail2ban-configuration.md` | ✅ | Protección contra fuerza bruta y escaneos SSH | C3,C5,C7 | `[[02-SKILLS/INFRAESTRUCTURA/fail2ban-configuration.md]]` |
| `ufw-firewall-configuration.md` | ✅ | Reglas de firewall básicas para filtrar tráfico | C3,C5,C7 | `[[02-SKILLS/INFRAESTRUCTURA/ufw-firewall-configuration.md]]` |
| `ssh-key-management.md` | ✅ | Gestión de claves criptográficas para acceso seguro | C3,C5 | `[[02-SKILLS/INFRAESTRUCTURA/ssh-key-management.md]]` |
| `n8n-concurrency-limiting.md` | ✅ | Control de flujos paralelos para no saturar recursos | C1,C2,C5 | `[[02-SKILLS/INFRAESTRUCTURA/n8n-concurrency-limiting.md]]` |
| `health-monitoring-vps.md` | ✅ | Alertas tempranas de CPU, RAM y disco | C5,C6,C8 | `[[02-SKILLS/INFRAESTRUCTURA/health-monitoring-vps.md]]` |
| `vps-interconnection.md` | ✅ | Enlace seguro entre múltiples servidores VPS | C3,C4,C5,C7 | `[[02-SKILLS/INFRAESTRUCTURA/vps-interconnection.md]]` |
| `redis-session-management.md` | ✅ | Buffer de sesión para contexto de conversación | C3,C5,C7 | `[[02-SKILLS/INFRAESTRUCTURA/redis-session-management.md]]` |
| `environment-variable-management.md` | ✅ | Gestión segura de contraseñas y configuraciones | C3,C5 | `[[02-SKILLS/INFRAESTRUCTURA/environment-variable-management.md]]` |

【CONSTRAINTS CRÍTICAS】
• **C1 (Resource Limits)**: Definir límites de CPU/RAM por contenedor para auto-scaling.
• **C3 (Zero Secrets)**: Credenciales SSH, API keys y passwords NUNCA hardcodeados.
• **C7 (Resilience)**: Healthchecks y graceful shutdown para todos los servicios.

【CASOS DE USO RECOMENDADOS】
• "Necesito conectar 3 VPS de forma segura" → `vps-interconnection.md` + `ssh-tunnels-remote-services.md`
• "Quiero monitorear mis servidores" → `health-monitoring-vps.md` + `fail2ban-configuration.md`
• "Necesito gestionar sesiones de agentes" → `redis-session-management.md`
```

---

## 【3】🗄️ DOMINIO: BASE DE DATOS-RAG (Información y Búsqueda)

```
【PROPÓSITO】Gestión de información estructurada y no estructurada. Incluye sincronización con Drive/Sheets, ingestión de PDFs, optimización para servidores pequeños (4GB RAM) y aislamiento por cliente.

【ESTADO】✅ 12/12 Skills Validadas y Listas

【SKILLS DISPONIBLES】
| Skill | Estado | Función Principal | Constraints | Wikilink |
|-------|--------|-----------------|------------|----------|
| `qdrant-rag-ingestion.md` | ✅ | Carga de documentos en vector DB para búsqueda semántica | C3,C4,C5,V1 | `[[02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md]]` |
| `mysql-sql-rag-ingestion.md` | ✅ | MySQL/SQL, RAG Ingestion patterns base de datos | C3,C4,C5 | `[[02-SKILLS/BASE DE DATOS-RAG/mysql-sql-rag-ingestion.md]]` |
| `rag-system-updates-all-engines.md` | ✅ | Actualización, reemplazo, concatenación de BD RAG | C5,C6,C7 | `[[02-SKILLS/BASE DE DATOS-RAG/rag-system-updates-all-engines.md]]` |
| `multi-tenant-data-isolation.md` | ✅ | Aislamiento de datos por tenant (C4 enforcement) | C4,C5,C8 | `[[02-SKILLS/BASE DE DATOS-RAG/multi-tenant-data-isolation.md]]` |
| `postgres-prisma-rag.md` | ✅ | PostgreSQL + Prisma para RAG con tipos seguros | C3,C4,C5 | `[[02-SKILLS/BASE DE DATOS-RAG/postgres-prisma-rag.md]]` |
| `supabase-rag-integration.md` | ✅ | Supabase + RAG patterns con auth integrado | C3,C4,C5 | `[[02-SKILLS/BASE DE DATOS-RAG/supabase-rag-integration.md]]` |
| `pdf-mistralocr-processing.md` | ✅ | Extracción de texto y tablas de PDFs escaneados | C3,C5 | `[[02-SKILLS/BASE DE DATOS-RAG/pdf-mistralocr-processing.md]]` |
| `google-drive-qdrant-sync.md` | ✅ | Sincronización automática Drive → Qdrant | C3,C4,C5 | `[[02-SKILLS/BASE DE DATOS-RAG/google-drive-qdrant-sync.md]]` |
| `espocrm-api-analytics.md` | ✅ | Extracción de métricas y reportes desde CRM | C3,C4,C5 | `[[02-SKILLS/BASE DE DATOS-RAG/espocrm-api-analytics.md]]` |
| `airtable-database-patterns.md` | ✅ | Estructuras recomendadas para Airtable | C3,C5 | `[[02-SKILLS/BASE DE DATOS-RAG/airtable-database-patterns.md]]` |
| `google-sheets-as-database.md` | ✅ | Uso de Sheets como tabla ligera para prototipos | C3,C5 | `[[02-SKILLS/BASE DE DATOS-RAG/google-sheets-as-database.md]]` |
| `mysql-optimization-4gb-ram.md` | ✅ | Ajustes de rendimiento para entornos limitados | C1,C5,C7 | `[[02-SKILLS/BASE DE DATOS-RAG/mysql-optimization-4gb-ram.md]]` |

【CONSTRAINTS CRÍTICAS】
• **C4 (Tenant Isolation)**: TODO acceso a datos debe incluir `WHERE tenant_id = $1`.
• **V1 (Vector Dimensions)**: Declarar dimensiones del embedding y modelo en queries vectoriales.
• **C3 (Zero Secrets)**: Credenciales de DB NUNCA en código.

【CASOS DE USO RECOMENDADOS】
• "Necesito RAG para documentos PDF" → `pdf-mistralocr-processing.md` + `qdrant-rag-ingestion.md`
• "Quiero sincronizar Google Drive con mi vector DB" → `google-drive-qdrant-sync.md`
• "Necesito aislar datos de múltiples clientes" → `multi-tenant-data-isolation.md` + `postgres-prisma-rag.md`
```

---

## 【4】📱 DOMINIO: WHATSAPP-RAG AGENTS (Agentes Conversacionales)

```
【PROPÓSITO】Patrones para agentes WhatsApp con RAG integrado a múltiples backends (Qdrant, Prisma, Supabase, Google Drive, MySQL, PostgreSQL, Airtable, Google Sheets) y múltiples proveedores de IA (OpenRouter, GPT, Claude, Qwen, DeepSeek, Minimax).

【ESTADO】🆕 1/4 Skills Pendientes de Validación

【SKILLS DISPONIBLES】
| Skill | Estado | Función Principal | Constraints | Wikilink |
|-------|--------|-----------------|------------|----------|
| `whatsapp-rag-openrouter.md` | ✅ | Patrones para agentes WhatsApp con RAG multi-backend y multi-IA | C3,C4,C5,C7,C8 | `[[02-SKILLS/WHATSAPP-RAG AGENTS/whatsapp-rag-openrouter.md]]` |
| `whatsapp-uazapi-integration.md` | 🆕 | Integración con uazapi para WhatsApp Business API | C3,C4,C5 | `[[02-SKILLS/WHATSAPP-RAG AGENTS/whatsapp-uazapi-integration.md]]` |
| `telegram-bot-integration.md` | 🆕 | Integración Telegram Bot con RAG | C3,C4,C5,C7 | `[[02-SKILLS/WHATSAPP-RAG AGENTS/telegram-bot-integration.md]]` |
| `multi-channel-routing.md` | 🆕 | Routing inteligente WhatsApp + Telegram + Email | C3,C4,C5,C6 | `[[02-SKILLS/WHATSAPP-RAG AGENTS/multi-channel-routing.md]]` |

【CONSTRAINTS CRÍTICAS】
• **C3 (Zero Secrets)**: API keys de WhatsApp, Telegram y proveedores de IA protegidas.
• **C4 (Tenant Isolation)**: Aislamiento estricto de conversaciones y contexto por tenant.
• **C7 (Resilience)**: Fallback a respuesta manual si el RAG falla o tarda >30s.
• **C8 (Observability)**: Logging estructurado de cada interacción con tenant_id y trace_id.

【CASOS DE USO RECOMENDADOS】
• "Quiero un agente de reservas por WhatsApp" → `whatsapp-rag-openrouter.md` + `postgres-prisma-rag.md`
• "Necesito atender por WhatsApp y Telegram" → `multi-channel-routing.md` + skills individuales
• "Quiero integrar uazapi para WhatsApp oficial" → `whatsapp-uazapi-integration.md` (pendiente validación)
```

---

## 【5】🦷 DOMINIO: ODONTOLOGÍA (Clínicas y Privacidad)

```
【PROPÓSITO】Gestión de agendas médicas, recordatorios automáticos y cumplimiento de privacidad de datos del paciente.

【ESTADO】🆕 0/6 Skills Nuevas (Estructura Base Lista)

【SKILLS PENDIENTES】
| Skill | Estado | Función Principal | Constraints | Wikilink |
|-------|--------|-----------------|------------|----------|
| `dental-appointment-automation.md` | 🆕 | Automatización de citas dentales con validación | C4,C5,C6 | `[[02-SKILLS/ODONTOLOGÍA/dental-appointment-automation.md]]` |
| `voice-agent-dental.md` | 🆕 | Voice agent con Gemini AI para atención telefónica | C3,C4,C8 | `[[02-SKILLS/ODONTOLOGÍA/voice-agent-dental.md]]` |
| `google-calendar-dental.md` | 🆕 | Google Calendar para clínicas con aislamiento | C4,C5,C6 | `[[02-SKILLS/ODONTOLOGÍA/google-calendar-dental.md]]` |
| `supabase-dental-patient.md` | 🆕 | Supabase para gestión de pacientes con RLS | C3,C4,C5 | `[[02-SKILLS/ODONTOLOGÍA/supabase-dental-patient.md]]` |
| `phone-integration-dental.md` | 🆕 | Integración telefónica para recordatorios automáticos | C3,C4,C7 | `[[02-SKILLS/ODONTOLOGÍA/phone-integration-dental.md]]` |
| `gmail-smtp-integration.md` | ✅ | Integración Gmail SMTP para notificaciones | C3,C5,C7 | `[[02-SKILLS/COMUNICACIÓN/gmail-smtp-integration.md]]` |

【CONSTRAINTS CRÍTICAS】
• **C4 (Tenant Isolation - CRÍTICO)**: Los datos de salud son sensibles. Aislamiento estricto obligatorio.
• **C8 (Observability)**: Auditoría de quién accedió a los datos de qué paciente (logs con scrubbing).
• **C3 (Zero Secrets)**: Credenciales de calendario, DB y email altamente protegidas.

【CASOS DE USO RECOMENDADOS】
• "Necesito recordatorios de citas por WhatsApp" → `whatsapp-rag-openrouter.md` + `google-calendar-dental.md`
• "Quiero gestión de pacientes con privacidad" → `supabase-dental-patient.md` + `multi-tenant-data-isolation.md`
• "Necesito voz para atención telefónica" → `voice-agent-dental.md` (pendiente)
```

---

## 【6】🏨 DOMINIO: HOTELES-POSADAS (Operaciones y Huésped)

```
【PROPÓSITO】Automatizar check-in, solicitudes de limpieza, upselling y gestión de reviews durante la estancia del huésped.

【ESTADO】🆕 0/7 Skills Nuevas (Estructura Base Lista)

【SKILLS PENDIENTES】
| Skill | Estado | Función Principal | Constraints | Wikilink |
|-------|--------|-----------------|------------|----------|
| `hotel-booking-automation.md` | 🆕 | Automatización de reservas hoteleras con validación | C3,C4,C5 | `[[02-SKILLS/HOTELES-POSADAS/hotel-booking-automation.md]]` |
| `hotel-receptionist-whatsapp.md` | 🆕 | Recepcionista WhatsApp con Gemini para consultas | C3,C4,C5,C7 | `[[02-SKILLS/HOTELES-POSADAS/hotel-receptionist-whatsapp.md]]` |
| `hotel-competitor-monitoring.md` | 🆕 | Monitoreo de precios y disponibilidad de competidores | C3,C5,C6 | `[[02-SKILLS/HOTELES-POSADAS/hotel-competitor-monitoring.md]]` |
| `hotel-guest-journey.md` | 🆕 | Journey del huésped: pre-llegada, estancia, post-salida | C4,C5,C6 | `[[02-SKILLS/HOTELES-POSADAS/hotel-guest-journey.md]]` |
| `hotel-pre-arrival-messages.md` | 🆕 | Mensajes automatizados pre-llegada con upselling | C3,C4,C5 | `[[02-SKILLS/HOTELES-POSADAS/hotel-pre-arrival-messages.md]]` |
| `redis-session-management.md` | ✅ | Redis para sesiones de huésped y contexto de conversación | C3,C5,C7 | `[[02-SKILLS/INFRAESTRUCTURA/redis-session-management.md]]` |
| `slack-hotel-integration.md` | 🆕 | Slack para coordinación de equipos hoteleros | C3,C5,C6 | `[[02-SKILLS/HOTELES-POSADAS/slack-hotel-integration.md]]` |

【CONSTRAINTS CRÍTICAS】
• **C1 (Resource Limits)**: Asegurar que el sistema aguanta picos de check-in simultáneo.
• **C4 (Tenant Isolation)**: Datos de huéspedes separados por propiedad/hotel.
• **C7 (Resilience)**: Fallback a respuesta manual si el sistema de reservas se cae.

【CASOS DE USO RECOMENDADOS】
• "Quiero check-in automático por WhatsApp" → `hotel-receptionist-whatsapp.md` + `hotel-booking-automation.md`
• "Necesito monitorear precios de competidores" → `hotel-competitor-monitoring.md`
• "Quiero mensajes pre-llegada con upselling" → `hotel-pre-arrival-messages.md`
```

---

## 【7】🍕 DOMINIO: RESTAURANTES (Pedidos y Reservas)

```
【PROPÓSITO】Gestión de pedidos, reservas, menús dinámicos y fidelización mediante asistentes conversacionales.

【ESTADO】🆕 0/10 Skills Nuevas (Estructura Base Lista)

【SKILLS PENDIENTES】
| Skill | Estado | Función Principal | Constraints | Wikilink |
|-------|--------|-----------------|------------|----------|
| `restaurant-booking-ai.md` | 🆕 | Sistema de reservas con IA y validación de disponibilidad | C3,C4,C5 | `[[02-SKILLS/RESTAURANTES/restaurant-booking-ai.md]]` |
| `restaurant-order-chatbot.md` | 🆕 | Chatbot de pedidos con qwen3.5 y integración POS | C3,C4,C5,C7 | `[[02-SKILLS/RESTAURANTES/restaurant-order-chatbot.md]]` |
| `restaurant-pos-integration.md` | 🆕 | Integración con sistemas POS existentes | C3,C4,C5 | `[[02-SKILLS/RESTAURANTES/restaurant-pos-integration.md]]` |
| `restaurant-voice-agents.md` | 🆕 | Voice agents para toma de pedidos telefónicos | C3,C4,C8 | `[[02-SKILLS/RESTAURANTES/restaurant-voice-agents.md]]` |
| `restaurant-menu-management.md` | 🆕 | Gestión dinámica de menús con actualizaciones en tiempo real | C3,C5,C6 | `[[02-SKILLS/RESTAURANTES/restaurant-menu-management.md]]` |
| `restaurant-delivery-tracking.md` | 🆕 | Tracking de delivery con notificaciones automáticas | C3,C4,C7 | `[[02-SKILLS/RESTAURANTES/restaurant-delivery-tracking.md]]` |
| `restaurant-google-maps-leadgen.md` | 🆕 | Lead generation desde Google Maps con IA | C3,C5,C6 | `[[02-SKILLS/RESTAURANTES/restaurant-google-maps-leadgen.md]]` |
| `apify-web-scraping.md` | 🆕 | Web scraping con Apify para menús y reseñas | C3,C5 | `[[02-SKILLS/RESTAURANTES/apify-web-scraping.md]]` |
| `airtable-restaurant-db.md` | 🆕 | Patrones Airtable para gestión de restaurantes | C3,C5 | `[[02-SKILLS/RESTAURANTES/airtable-restaurant-db.md]]` |
| `restaurant-multi-channel-receptionist.md` | 🆕 | Recepcionista multi-canal: WhatsApp + Teléfono + Email | C3,C4,C5,C7 | `[[02-SKILLS/RESTAURANTES/restaurant-multi-channel-receptionist.md]]` |

【CONSTRAINTS CRÍTICAS】
• **C3 (Zero Secrets)**: API keys de WhatsApp, POS y proveedores de IA protegidas.
• **C4 (Tenant Isolation)**: Datos de pedidos y clientes separados por restaurante.
• **C7 (Resilience)**: Fallback a pedido manual si el chatbot falla o el POS se cae.

【CASOS DE USO RECOMENDADOS】
• "Quiero tomar pedidos por WhatsApp" → `restaurant-order-chatbot.md` + `whatsapp-rag-openrouter.md`
• "Necesito gestión de menús dinámica" → `restaurant-menu-management.md` + `google-drive-qdrant-sync.md`
• "Quiero tracking de delivery" → `restaurant-delivery-tracking.md` + `telegram-bot-integration.md`
```

---

## 【8】🧭 PROTOCOLO DE USO PARA IA Y HUMANOS

<!-- 
【EDUCATIVO】Cómo usar este mapeo para construir una solución desde cero.
-->

```
┌─────────────────────────────────────────────────────────┐
│ 【PASO 1】IDENTIFICAR DOMINIO Y NECESIDAD              │
├─────────────────────────────────────────────────────────┤
│ Ej: "Cliente Restaurante. Quiere reservas por WhatsApp".│
│ → Ir a Sección 【7】 DOMINIO: RESTAURANTES             │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 2】SELECCIONAR SKILLS REQUERIDAS                │
├─────────────────────────────────────────────────────────┤
│ Consultar tabla de skills requeridas.                  │
│ • Descargar/Verificar: restaurant-booking-ai.md        │
│ • Descargar/Verificar: whatsapp-rag-openrouter.md      │
│ • Descargar/Verificar: postgres-prisma-rag.md          │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 3】VALIDAR CONSTRAINTS CRÍTICAS                 │
├─────────────────────────────────────────────────────────┤
│ Para cada skill seleccionada:                          │
│ • Verificar constraints_mapped en frontmatter          │
│ • Ejecutar: verify-constraints.sh --file <skill> --json│
│ • Confirmar: C3 (secrets), C4 (tenant), C5 (estructura)│
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 4】ENSAMBLAR Y VALIDAR SOLUCIÓN                 │
├─────────────────────────────────────────────────────────┤
│ • Integrar skills en flujo de negocio                  │
│ • Ejecutar: orchestrator-engine.sh --dir <solución> --json│
│ • Verificar: score >= 30, blocking_issues == []        │
│ • Si pasa → entregar; si falla → iterar (máx 3 intentos)│
└─────────────────────────────────────────────────────────┘
```

### 8.1 Ejemplo de Mapeo End-to-End

```
【EJEMPLO: Agente de reservas para restaurante vía WhatsApp】
Necesidad: "Quiero que clientes reserven mesa por WhatsApp con confirmación automática"

Paso 1 - Identificar dominio:
  • Industria: Restaurantes → Sección 【7】 ✅
  • Caso de uso: Reservas por WhatsApp → `restaurant-booking-ai.md` + `whatsapp-rag-openrouter.md` ✅

Paso 2 - Seleccionar skills:
  • `restaurant-booking-ai.md` (🆕 Pendiente) → Usar estructura base y adaptar
  • `whatsapp-rag-openrouter.md` (✅ Listo) → Validar con orchestrator-engine.sh ✅
  • `postgres-prisma-rag.md` (✅ Listo) → Validar con check-rls.sh ✅

Paso 3 - Validar constraints:
  • C3: Verificar que API keys están en variables de entorno ✅
  • C4: Confirmar que queries incluyen `WHERE tenant_id = $1` ✅
  • C5: Validar frontmatter y wikilinks canónicos ✅

Paso 4 - Ensamblar y validar:
  • Integrar skills en flujo n8n o código personalizado
  • Ejecutar: orchestrator-engine.sh --dir solution/ --json
  • Resultado: score=38, passed=true, blocking_issues=[] ✅

Resultado: ✅ Solución de reservas funcional con gobernanza aplicada.
```

---

## 【9】📚 GLOSARIO PARA PRINCIPIANTES

<!-- 
【EDUCATIVO】Términos técnicos explicados en lenguaje simple.
-->

| Término | Significado simple | Ejemplo |
|---------|-------------------|---------|
| **Skill Horizontal** | Habilidad técnica reutilizable en cualquier industria | `docker-compose-networking.md` sirve para restaurantes, hoteles, clínicas |
| **Skill Vertical** | Solución empaquetada para un negocio específico | `02-SKILLS/RESTAURANTES/` con prompts y workflows de reservas |
| **✅ Listo** | Skill validada con score >= umbral y blocking_issues == [] | Puede usarse en producción sin revisión adicional |
| **🆕 Pendiente/Nuevo** | Skill con estructura base lista pero contenido por desarrollar | Falta implementación, pruebas o validación final |
| **canonical_path** | Ruta absoluta desde raíz del repositorio | `/02-SKILLS/AI/qwen-integration.md` |
| **wikilink canónico** | Enlace interno con ruta absoluta, nunca relativa | `[[02-SKILLS/AI/qwen-integration]]` (no `[[../AI/qwen-integration]]`) |
| **constraints_mapped** | Lista de reglas de calidad que aplica a esta skill | `["C3","C4","C5","C8"]` para skills que manejan datos de usuario |
| **validation_command** | Comando ejecutable para validar la skill automáticamente | `bash .../orchestrator-engine.sh --file <ruta> --json` |
| **LANGUAGE LOCK** | Regla que prohíbe ciertos operadores en ciertos lenguajes | No usar `<->` en `go/`, solo en `postgresql-pgvector/` |

---

## 【10】🔗 REFERENCIAS CANÓNICAS (WIKILINKS)

<!-- 
【PARA IA】Estos enlaces deben resolverse usando PROJECT_TREE.md. 
No uses rutas relativas. Usa siempre la forma canónica [[RUTA]].
-->

- `[[02-SKILLS/00-INDEX.md]]` → Índice maestro de skills con estado global
- `[[01-RULES/08-SKILLS-REFERENCE.md]]` → Catálogo de habilidades por dominio
- `[[05-CONFIGURATIONS/validation/norms-matrix.json]]` → Mapeo de constraints por carpeta
- `[[GOVERNANCE-ORCHESTRATOR.md]]` → Tiers, validación y certificación
- `[[SDD-COLLABORATIVE-GENERATION.md]]` → Especificación de formato de artefactos
- `[[TOOLCHAIN-REFERENCE.md]]` → Catálogo de herramientas de validación
- `[[PROJECT_TREE.md]]` → Mapa canónico de rutas para resolución de wikilinks
- `[[00-STACK-SELECTOR.md]]` → Motor de decisión: ruta → lenguaje → constraints

---

## 【11】📦 METADATOS DE EXPANSIÓN (PARA FUTURAS VERSIONES)

<!-- 
【PARA MANTENEDORES】Nuevas secciones deben seguir este formato para no romper compatibilidad.
-->

```json
{
  "expansion_registry": {
    "new_vertical_domain": {
      "requires_files_update": [
        "02-SKILLS/skill-domains-mapping.md: add domain entry to tabla maestra con propósito, skills, estado, constraints, wikilink",
        "02-SKILLS/<new-domain>/: create folder with 00-INDEX.md and initial skill files",
        "02-SKILLS/00-INDEX.md: add domain to horizontal/vertical skills catalog",
        "01-RULES/08-SKILLS-REFERENCE.md: add domain to domain_catalog",
        "Human approval required: true"
      ],
      "backward_compatibility": "new domains must not break existing navigation or validation flows; must declare constraints applicability clearly"
    },
    "new_skill_addition": {
      "requires_files_update": [
        "02-SKILLS/skill-domains-mapping.md: add skill entry to appropriate domain table with file, status, function, constraints, wikilink",
        "02-SKILLS/<domain>/: create new skill file following SDD-COLLABORATIVE-GENERATION.md",
        "02-SKILLS/00-INDEX.md: update skill count and status for domain",
        "Human approval required: true"
      ],
      "backward_compatibility": "new skills must not break existing navigation or validation flows; must declare constraints applicability clearly"
    }
  },
  "compatibility_rule": "Nuevas entradas en el mapeo no deben invalidar wikilinks existentes o validaciones automáticas. Cambios breaking requieren major version bump, guía de migración y aprobación humana explícita."
}
```

---

<!-- 
═══════════════════════════════════════════════════════════
🤖 SECCIÓN PARA IA: ÁRBOL JSON ENRIQUECIDO
═══════════════════════════════════════════════════════════
Esta sección contiene metadatos estructurados para consumo automático por agentes de IA.
No está diseñada para lectura humana directa. Los humanos deben usar las secciones 【1】-【11】.

Formato: JSON válido, con comentarios explicativos en claves "doc_*".
Prioridad de ejecución: Los dominios se consultan en orden: horizontales → verticales.
Dependencias: Cada nodo declara sus archivos requeridos y sus efectos colaterales.
═══════════════════════════════════════════════════════════
-->

```json
{
  "skill_domains_mapping_metadata": {
    "version": "3.0.0-SELECTIVE",
    "canonical_path": "/02-SKILLS/skill-domains-mapping.md",
    "artifact_type": "governance_mapping",
    "immutable": true,
    "requires_human_approval_for_changes": true,
    "constraints_primary": ["C5", "C6"],
    "total_domains": 13,
    "total_skills_mapped": 95,
    "llm_optimizations": {
      "oriental_models_friendly": true,
      "delimiters_used": ["【】", "┌─┐", "▼", "✅/❌/🔧"],
      "numbered_sequences": true,
      "stop_conditions_explicit": true
    }
  },
  
  "horizontal_domains_catalog": {
    "ai_llms": {
      "path": "02-SKILLS/AI/",
      "description": "Catálogo de proveedores de IA, límites de coste, estrategias de fallback",
      "skills_count": 11,
      "status": "✅ 11/11 Listo",
      "typical_constraints": ["C3", "C4", "C5", "C8"],
      "validator": "orchestrator-engine.sh --checks C3,C4,C5,C8",
      "wikilink": "[[02-SKILLS/AI/]]"
    },
    "infraestructura": {
      "path": "02-SKILLS/INFRAESTRUCTURA/",
      "description": "Configuración y mantenimiento de servidores VPS, redes, contenedores y monitoreo",
      "skills_count": 10,
      "status": "✅ 10/10 Listo",
      "typical_constraints": ["C1", "C3", "C5", "C7"],
      "validator": "orchestrator-engine.sh --checks C1,C3,C5,C7",
      "wikilink": "[[02-SKILLS/INFRAESTRUCTURA/]]"
    },
    "base_de_datos_rag": {
      "path": "02-SKILLS/BASE DE DATOS-RAG/",
      "description": "Gestión de información estructurada y no estructurada, RAG, aislamiento multi-tenant",
      "skills_count": 12,
      "status": "✅ 12/12 Listo",
      "typical_constraints": ["C3", "C4", "C5", "V1"],
      "validator": "orchestrator-engine.sh --checks C3,C4,C5,V1",
      "wikilink": "[[02-SKILLS/BASE DE DATOS-RAG/]]"
    },
    "comunicacion": {
      "path": "02-SKILLS/COMUNICACIÓN/",
      "description": "Integración con canales de mensajería, correo y calendarios",
      "skills_count": 5,
      "status": "🟡 4/5 Listo",
      "typical_constraints": ["C3", "C4", "C5", "C7"],
      "validator": "orchestrator-engine.sh --checks C3,C4,C5,C7",
      "wikilink": "[[02-SKILLS/COMUNICACIÓN/]]",
      "pending": ["whatsapp-uazapi-integration.md"]
    },
    "seguridad": {
      "path": "02-SKILLS/SEGURIDAD/",
      "description": "Copias de seguridad, hardening de servidores y automatización de respaldos cifrados",
      "skills_count": 3,
      "status": "✅ 3/3 Listo",
      "typical_constraints": ["C3", "C5", "C8"],
      "validator": "orchestrator-engine.sh --checks C3,C5,C8",
      "wikilink": "[[02-SKILLS/SEGURIDAD/]]"
    }
  },
  
  "vertical_domains_catalog": {
    "whatsapp_rag_agents": {
      "path": "02-SKILLS/WHATSAPP-RAG AGENTS/",
      "description": "Agentes conversacionales con RAG integrado a múltiples backends y proveedores de IA",
      "skills_count": 4,
      "status": "🆕 1/4 Pendiente",
      "typical_constraints": ["C3", "C4", "C5", "C7", "C8"],
      "validator": "orchestrator-engine.sh --checks C3,C4,C5,C7,C8",
      "wikilink": "[[02-SKILLS/WHATSAPP-RAG AGENTS/]]"
    },
    "instagram_social_media": {
      "path": "02-SKILLS/INSTAGRAM-SOCIAL-MEDIA/",
      "description": "Generación de contenido, programación y análisis de engagement mediante IA",
      "skills_count": 6,
      "status": "🆕 0/6 Nuevo",
      "typical_constraints": ["C3", "C5", "C6"],
      "validator": "orchestrator-engine.sh --checks C3,C5,C6",
      "wikilink": "[[02-SKILLS/INSTAGRAM-SOCIAL-MEDIA/]]"
    },
    "odontologia": {
      "path": "02-SKILLS/ODONTOLOGÍA/",
      "description": "Gestión de agendas médicas, recordatorios y cumplimiento de privacidad de datos",
      "skills_count": 6,
      "status": "🆕 0/6 Nuevo",
      "typical_constraints": ["C4", "C5", "C6", "C8"],
      "validator": "orchestrator-engine.sh --checks C4,C5,C6,C8",
      "wikilink": "[[02-SKILLS/ODONTOLOGÍA/]]"
    },
    "hoteles_posadas": {
      "path": "02-SKILLS/HOTELES-POSADAS/",
      "description": "Automatización de check-in, housekeeping, upselling y gestión de reviews",
      "skills_count": 7,
      "status": "🆕 0/7 Nuevo",
      "typical_constraints": ["C1", "C3", "C4", "C5"],
      "validator": "orchestrator-engine.sh --checks C1,C3,C4,C5",
      "wikilink": "[[02-SKILLS/HOTELES-POSADAS/]]"
    },
    "restaurantes": {
      "path": "02-SKILLS/RESTAURANTES/",
      "description": "Gestión de pedidos, reservas, menús dinámicos y fidelización",
      "skills_count": 10,
      "status": "🆕 0/10 Nuevo",
      "typical_constraints": ["C3", "C4", "C5", "C7"],
      "validator": "orchestrator-engine.sh --checks C3,C4,C5,C7",
      "wikilink": "[[02-SKILLS/RESTAURANTES/]]"
    },
    "corporate_kb": {
      "path": "02-SKILLS/CORPORATE-KB/",
      "description": "Conocimiento corporativo con RAG para preguntas frecuentes y soporte interno",
      "skills_count": 5,
      "status": "🆕 0/5 Nuevo",
      "typical_constraints": ["C4", "C5", "C6"],
      "validator": "orchestrator-engine.sh --checks C4,C5,C6",
      "wikilink": "[[02-SKILLS/CORPORATE-KB/]]"
    },
    "n8n_patterns": {
      "path": "02-SKILLS/N8N-PATTERNS/",
      "description": "Patrones reutilizables para workflows y agentes en n8n",
      "skills_count": 3,
      "status": "🆕 0/3 Nuevo",
      "typical_constraints": ["C5", "C6", "C7"],
      "validator": "orchestrator-engine.sh --checks C5,C6,C7",
      "wikilink": "[[02-SKILLS/N8N-PATTERNS/]]"
    },
    "agentic_assistance": {
      "path": "02-SKILLS/AGENTIC-ASSISTANCE/",
      "description": "Integración IDE & CLI para Generación Asistida y Autogeneración SDD",
      "skills_count": 1,
      "status": "✅ 1/1 Listo",
      "typical_constraints": ["C5", "C6"],
      "validator": "orchestrator-engine.sh --checks C5,C6",
      "wikilink": "[[02-SKILLS/AGENTIC-ASSISTANCE/]]"
    },
    "deployment": {
      "path": "02-SKILLS/DEPLOYMENT/",
      "description": "Despliegue multi-canal con manifest, deploy.sh, rollback.sh",
      "skills_count": 1,
      "status": "✅ 1/1 Listo",
      "typical_constraints": ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8"],
      "validator": "orchestrator-engine.sh --bundle --checksum",
      "wikilink": "[[02-SKILLS/DEPLOYMENT/]]"
    }
  },
  
  "validation_integration": {
    "orchestrator-engine.sh": {
      "purpose": "Validación integral de skills con scoring y reporte JSON",
      "flags": ["--file", "--dir", "--mode", "--json", "--checks"],
      "exit_codes": {"0": "passed", "1": "failed"},
      "output_format": "JSON con score, passed, blocking_issues, constraints_applied"
    },
    "verify-constraints.sh": {
      "purpose": "Validar constraints y LANGUAGE LOCK para skills que tocan código",
      "flags": ["--file", "--check-constraint", "--check-language-lock", "--json"],
      "exit_codes": {"0": "compliant", "1": "violation"},
      "output_format": "JSON con constraints_validated, language_lock.violations"
    }
  },
  
  "dependency_graph": {
    "critical_infrastructure": [
      {"file": "02-SKILLS/00-INDEX.md", "purpose": "Índice maestro de skills con estado global", "load_order": 1},
      {"file": "01-RULES/08-SKILLS-REFERENCE.md", "purpose": "Catálogo de habilidades por dominio", "load_order": 2},
      {"file": "05-CONFIGURATIONS/validation/norms-matrix.json", "purpose": "Mapeo de constraints por carpeta", "load_order": 3},
      {"file": "GOVERNANCE-ORCHESTRATOR.md", "purpose": "Tiers y validación", "load_order": 4}
    ],
    "horizontal_skills_dependencies": [
      {"file": "02-SKILLS/AI/qwen-integration.md", "purpose": "Skill de IA base para agentes conversacionales", "load_order": 1},
      {"file": "02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md", "purpose": "Skill de RAG para búsqueda semántica", "load_order": 2},
      {"file": "02-SKILLS/WHATSAPP-RAG AGENTS/whatsapp-rag-openrouter.md", "purpose": "Skill de comunicación WhatsApp + RAG", "load_order": 3}
    ],
    "vertical_skills_dependencies": [
      {"file": "02-SKILLS/RESTAURANTES/", "purpose": "Estructura base para skills de restaurantes", "load_order": 1},
      {"file": "02-SKILLS/ODONTOLOGÍA/", "purpose": "Estructura base para skills de odontología", "load_order": 2}
    ]
  },
  
  "human_readable_errors": {
    "domain_not_found": "Dominio '{domain_name}' no encontrado en skill-domains-mapping.md. Consultar tabla maestra para dominios disponibles.",
    "skill_not_mapped": "Skill '{skill_name}' no mapeada a ningún dominio. Añadir entrada en tabla correspondiente.",
    "wikilink_not_canonical": "Wikilink '{wikilink}' no es canónico. Usar forma absoluta: [[RUTA-DESDE-RAÍZ]].",
    "constraint_not_applicable": "Constraint '{constraint}' no aplicable para skill '{skill}'. Consulte [[norms-matrix.json]] para mapeo por carpeta.",
    "validation_failed": "Validación de '{skill}' falló: {error_details}. Consulte [[01-RULES/validation-checklist.md]] para ítems específicos a corregir.",
    "language_lock_violation": "Violación de LANGUAGE LOCK: operador '{operator}' prohibido en skill '{skill}'. Consulte [[01-RULES/language-lock-protocol.md]].",
    "status_mismatch": "Estado de skill '{skill}' marcado como ✅ Listo pero validación no pasa. Ejecutar validation_command para verificar."
  },
  
  "expansion_hooks": {
    "new_vertical_domain": {
      "requires_files_update": [
        "02-SKILLS/skill-domains-mapping.md: add domain entry to vertical_domains_catalog with path, description, skills_count, status, constraints, validator, wikilink",
        "02-SKILLS/<new-domain>/: create folder with 00-INDEX.md and initial skill files",
        "02-SKILLS/00-INDEX.md: add domain to vertical_skills_catalog",
        "01-RULES/08-SKILLS-REFERENCE.md: add domain to domain_catalog",
        "Human approval required: true"
      ],
      "backward_compatibility": "new domains must not break existing navigation or validation flows; must declare constraints applicability clearly"
    },
    "new_skill_addition": {
      "requires_files_update": [
        "02-SKILLS/skill-domains-mapping.md: add skill entry to appropriate domain table with file, status, function, constraints, wikilink",
        "02-SKILLS/<domain>/: create new skill file following SDD-COLLABORATIVE-GENERATION.md",
        "02-SKILLS/00-INDEX.md: update skill count and status for domain",
        "Human approval required: true"
      ],
      "backward_compatibility": "new skills must not break existing navigation or validation flows; must declare constraints applicability clearly"
    }
  },
  
  "validation_metadata": {
    "orchestrator_compatibility": ">=3.0.0-SELECTIVE",
    "schema_version": "skill-domains-mapping.v3.json",
    "checksum_algorithm": "SHA256",
    "audit_log_format": "JSON Lines with RFC3339 timestamps",
    "pii_scrubbing": "enabled for all logs (C3 + C8 compliance)",
    "reproducibility_guarantee": "Any skill domain mapping can be reproduced identically using this document + canonical wikilinks"
  }
}
```

---

## ✅ CHECKLIST DE VALIDACIÓN POST-GENERACIÓN

<!-- 
【PARA PRINCIPIANTES】Antes de guardar este archivo, verifica estos puntos.
-->

```bash
# 1. Frontmatter válido
yq eval '.canonical_path' 02-SKILLS/skill-domains-mapping.md | grep -q "/02-SKILLS/skill-domains-mapping.md" && echo "✅ Ruta canónica correcta"

# 2. Constraints mapeadas (C5+C6)
yq eval '.constraints_mapped | contains(["C5"]) and contains(["C6"])' 02-SKILLS/skill-domains-mapping.md && echo "✅ C5 y C6 declaradas"

# 3. Tabla maestra con 13 dominios presente
grep -c "AI/LLMs\|INFRAESTRUCTURA\|RESTAURANTES" 02-SKILLS/skill-domains-mapping.md | awk '{if($1>=13) print "✅ 13 dominios indexados"; else print "⚠️ Faltan dominios: "$1"/13"}'

# 4. Skills con estado definido (✅/🆕/🟡)
grep -c "✅\|🆕\|🟡" 02-SKILLS/skill-domains-mapping.md | awk '{if($1>=95) print "✅ 95+ skills con estado definido"; else print "⚠️ Faltan estados: "$1"/95"}'

# 5. JSON final parseable
tail -n +$(grep -n '```json' 02-SKILLS/skill-domains-mapping.md | tail -1 | cut -d: -f1) 02-SKILLS/skill-domains-mapping.md | sed -n '/```json/,/```/p' | sed '1d;$d' | jq empty && echo "✅ JSON parseable"

# 6. Wikilinks canónicos (sin rutas relativas)
for link in $(grep -oE '\[\[[^]]+\]\]' 02-SKILLS/skill-domains-mapping.md | tr -d '[]' | sort -u); do
  if [[ "$link" =~ ^\[\[\.\/ || "$link" =~ ^\[\[\.\.\/ ]]; then
    echo "❌ Wikilink relativo: $link"
  else
    [ -f "${link#//}" ] || echo "⚠️ Wikilink no resuelto: $link"
  fi
done
```
````

**Criterio de aceptación:**  
- ✅ Frontmatter válido con `canonical_path: "/02-SKILLS/skill-domains-mapping.md"`  
- ✅ `constraints_mapped` incluye C5 y C6 (estructura + trazabilidad)  
- ✅ Tabla maestra con 13 dominios (5 horizontales + 8 verticales) documentados  
- ✅ 95+ skills con estado definido (✅/🆕/🟡) y constraints asociadas  
- ✅ Sección JSON final es válida (puede parsearse con `jq .`)  
- ✅ Todos los wikilinks son canónicos (absolutos desde raíz)  

---

> 🎯 **Mensaje final para el lector humano**:  
> Este mapeo es tu brújula de soluciones. No es estático: evoluciona con el proyecto.  
> **Identificar → Consultar → Validar → Ensamblar**.  
> Si sigues ese flujo, nunca te perderás en las skills ni integrarás patrones no validados.  
> La gobernanza no es una carga. Es la libertad de escalar sin miedo a romper.  

---
