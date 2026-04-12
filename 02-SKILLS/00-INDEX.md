---
ai_optimized: true
version: "v1.0.0"
constraints: ["C1", "C2", "C3", "C4", "C5", "C6"]
purpose: "Índice maestro de habilidades SDD. Navegación unificada para humanos y IA. Mapeo de dominios, estados y rutas canónicas."
tags: ["index", "navigation", "sdd", "skills", "human-readable", "ai-parsable"]
related_files:
  - "[[../README.md]]"
  - "[[../PROJECT_TREE.md]]"
  - "[[../knowledge-graph.json]]"
  - "[[skill-domains-mapping.md]]"
---

# 📚 ÍNDICE MAESTRO DE HABILIDADES (SKILLS) - MANTIS AGENTIC

## 🧭 Guía Rápida (Para personas sin perfil técnico)
Este documento es el **mapa central** de todo el conocimiento y las herramientas automatizadas del proyecto. Piensa en él como el índice de una biblioteca técnica:
- 🔹 **Skills Horizontales**: Son los cimientos técnicos (servidores, bases de datos, inteligencia artificial, seguridad). Sirven para cualquier industria.
- 🏢 **Skills Verticales**: Son soluciones empaquetadas para negocios reales (restaurantes, clínicas, hoteles, redes sociales). Se construyen sobre las horizontales.
- ✅ **Estado**: Indica si un archivo está listo para usar (`✅ Listo`), en construcción (`🟡 En proceso`) o con estructura base pendiente de contenido (`🔧 Estructura lista`).

Cualquier persona o asistente IA puede usar este índice para localizar rápidamente cómo configurar un servidor, conectar una base de datos, implementar un agente de voz o adaptar un flujo a un negocio específico.

---

## 🌐 Skills Horizontales (Core Técnico)

### 🖥️ `INFRAESTRUCTURA/`
*Descripción:* Configuración y mantenimiento de servidores VPS, redes, contenedores y monitoreo. Aquí se definen cómo se conectan y protegen los servicios base.
| Archivo | Estado | Función Principal |
|---------|--------|-------------------|
| `docker-compose-networking.md` | ✅ Listo | Orquestación de contenedores y red interna aislada |
| `espocrm-setup.md` | ✅ Listo | Instalación y configuración del CRM base |
| `fail2ban-configuration.md` | ✅ Listo | Protección contra fuerza bruta y escaneos |
| `ssh-tunnels-remote-services.md` | ✅ Listo | Conexiones seguras a servicios remotos sin exponer puertos |
| `ssh-key-management.md` | ✅ Listo | Gestión de claves criptográficas para acceso seguro |
| `ufw-firewall-configuration.md` | ✅ Listo | Reglas de firewall básicas para filtrar tráfico |
| `vps-interconnection.md` | ✅ Listo | Enlace seguro entre múltiples servidores VPS |
| `n8n-concurrency-limiting.md` | ✅ Listo | Control de flujos paralelos para no saturar recursos |
| `health-monitoring-vps.md` | ✅ Listo | Alertas tempranas de CPU, RAM y disco |

### 🗄️ `BASE-DE-DATOS-RAG/`
*Descripción:* Gestión de información estructurada y no estructurada. Incluye sincronización con Drive/Sheets, ingestión de PDFs, optimización para servidores pequeños (4GB RAM) y aislamiento por cliente.
| Archivo | Estado | Función Principal |
|---------|--------|-------------------|
| `qdrant-rag-ingestion.md` | ✅ Listo | Carga de documentos en vector DB para búsqueda semántica |
| `postgres-prisma-rag.md` | ✅ Listo | ORM tipado y migraciones seguras |
| `multi-tenant-data-isolation.md` | ✅ Listo | Separación estricta de datos por cliente (C4) |
| `pdf-mistralocr-processing.md` | ✅ Listo | Extracción de texto y tablas de PDFs escaneados |
| `google-drive-qdrant-sync.md` | ✅ Listo | Sincronización automática Drive → Vector DB |
| `espocrm-api-analytics.md` | ✅ Listo | Extracción de métricas y reportes desde CRM |
| `mysql-optimization-4gb-ram.md` | ✅ Listo | Ajustes de rendimiento para entornos limitados |
| `rag-system-updates-all-engines.md` | ✅ Listo | Procedimientos de actualización segura de motores RAG |
| `mysql-sql-rag-ingestion.md` | ✅ Listo | Carga masiva y transformación SQL para IA |
| `redis-session-management.md` | ✅ Listo | Caché de sesiones y estado temporal de agentes |
| `environment-variable-management.md` | ✅ Listo | Gestión segura de contraseñas y configuraciones |
| `google-sheets-as-database.md` | ✅ Listo | Uso de Sheets como tabla ligera para prototipos |
| `airtable-database-patterns.md` | ✅ Listo | Estructuras recomendadas para Airtable |

### 📡 `COMUNICACION/`
*Descripción:* Integración con canales de mensajería, correo y calendarios. Permite que los agentes respondan y actúen en tiempo real.
| Archivo | Estado | Función Principal |
|---------|--------|-------------------|
| `telegram-bot-integration.md` | ✅ Listo | Conexión y webhooks para Telegram |
| `gmail-smtp-integration.md` | ✅ Listo | Envío/recepción automatizada de correos |
| `google-calendar-api-integration.md` | ✅ Listo | Gestión de citas y recordatorios sincronizados |
| `whatsapp-rag-openrouter.md` | 🟡 En proceso | Agente conversacional con base de conocimientos (pendiente cierre P9) |

### 🔒 `SEGURIDAD/`
*Descripción:* Copias de seguridad, hardening de servidores y automatización de respaldos cifrados.
| Archivo | Estado | Función Principal |
|---------|--------|-------------------|
| `backup-encryption.md` | ✅ Listo | Cifrado de backups con claves asimétricas (age) |
| `rsync-automation.md` | ✅ Listo | Sincronización incremental eficiente entre nodos |
| `security-hardening-vps.md` | ✅ Listo | Checklist de endurecimiento post-instalación |

### 🤖 `AI/`
*Descripción:* Catálogo de proveedores de Inteligencia Artificial, sus límites de coste, estrategias de fallback y modos de integración.
| Archivo | Estado | Función Principal |
|---------|--------|-------------------|
| `openrouter-api-integration.md` | ✅ Listo | Router unificado, retry, fallback y control de costes |
| `qwen-integration.md` | ✅ Listo | Modelo base prioritario, contexto largo y JSON mode |
| `deepseek-integration.md` | ✅ Listo | Reasoning optimizado y fallback coder |
| `llama-integration.md` | ✅ Listo | Modelos open-weight y ejecución local (excepción C6) |
| `gemini-integration.md` | ✅ Listo | Entradas multimodales, streaming y filtros de seguridad |
| `gpt-integration.md` | ✅ Listo | Function calling y salidas estructuradas |
| `minimax-integration.md` | ✅ Listo | Contexto ultra-largo (~1M tokens) y procesamiento iterativo |
| `mistral-ocr-integration.md` | ✅ Listo | Extracción avanzada de documentos y tablas |
| `voice-agent-integration.md` | ✅ Listo | STT/TTS, chunks de audio y aislamiento por tenant |
| `image-gen-api.md` | ✅ Listo | Generación de imágenes con filtros y lotes |
| `video-gen-api.md` | ✅ Listo | Text/Img-to-Video, codecs y límites de duración |

---

## 🏢 Skills Verticales (Casos de Uso por Industria)
*Nota:* Estas carpetas contienen la estructura base (`prompts/`, `workflows/`, `validation/`) lista para ser poblada. Evita duplicar lógica horizontal; importa las skills técnicas y adapta solo los flujos de negocio.

| Carpeta | Estado | Contenido Base | Propósito |
|---------|--------|----------------|-----------|
| `RESTAURANTES/` | 🔧 Estructura lista | `prompts/.gitkeep`, `workflows/.gitkeep`, `validation/.gitkeep` | Gestión de pedidos, reservas, menú dinámico y fidelización |
| `ODONTOLOGÍA/` | 🔧 Estructura lista | `prompts/.gitkeep`, `workflows/.gitkeep`, `validation/.gitkeep` | Agenda clínica, recordatorios, historial paciente y cumplimiento normativo |
| `HOTELES-POSADAS/` | 🔧 Estructura lista | `prompts/.gitkeep`, `workflows/.gitkeep`, `validation/.gitkeep` | Check-in/out, housekeeping, upselling y gestión de reviews |
| `INSTAGRAM-SOCIAL-MEDIA/` | 🔧 Estructura lista | `prompts/.gitkeep`, `workflows/.gitkeep`, `validation/.gitkeep` | Publicación programada, análisis de engagement y respuestas automáticas |

---

## 📊 Estado Global y Próximos Pasos
| Dimensión | Avance | Acción Inmediata |
|-----------|--------|------------------|
| Skills Horizontales | ~95% ✅ | Validación cruzada C1-C6 y cierre de `whatsapp-rag-openrouter.md` |
| Skills Verticales | 15% (Estructura) | Poblado de `prompts/`, `workflows/` y scripts `validation/` por dominio |
| Validación Automatizada | 100% Scripts ✅ | Integración en pre-commit y pipeline CI/CD |

**Regla de Oro para Contribuir:** 
1. Nunca modifiques un archivo sin actualizar su `version` y `related_files` en el frontmatter.
2. Cada nuevo prompt o workflow debe pasar `validate-skill-integrity.sh` antes de merge.
3. Si no conoces la infraestructura, importa las skills horizontales en lugar de reescribirlas.

---

## 🔗 Navegación Rápida
- 📖 Visión General del Proyecto: `[[../README.md]]`
- 🌳 Estructura Canónica de Archivos: `[[../PROJECT_TREE.md]]`
- 🕸️ Grafo de Conocimientos y Dependencias: `[[../knowledge-graph.json]]`
- 🗺️ Mapeo de Dominios y Reglas de Asignación: `[[skill-domains-mapping.md]]`
- 🛡️ Validadores y Hardening: `[[../05-CONFIGURATIONS/validation/]]`

---

\-\-\-

\## 🤖 Generación de Skills (Para IA y Humanos)
\- 🔹 Modelos de Generación (colaborativo / full-automated): `[[01-GENERATION-MODELS.md]]`
\- 🔹 Flujo Colaborativo para Pendientes (gate pre-entrega): `[[../../SDD-COLLABORATIVE-GENERATION.md]]`
\- 📦 Plantilla Base: `[[../../05-CONFIGURATIONS/templates/skill-template.md]]`
\- 🛡️ Validadores: `[[../../05-CONFIGURATIONS/validation/]]`

\> 📌 \*\*Instrucción para IA:\*\* Antes de generar cualquier archivo, leer `SDD-COLLABORATIVE-GENERATION.md` para aplicar gate de validación pre-entrega. Cero fences rotos. Cero frontmatter inválido. Cero constraints implícitos.
> 📝 *Documento generado bajo especificación SDD. Última sincronización estructural: v1.0.0. Mantener actualizado ante cada merge a `02-SKILLS/`.*
