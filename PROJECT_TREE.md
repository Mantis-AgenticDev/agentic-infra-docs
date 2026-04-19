---
canonical_path: "/PROJECT_TREE.md"
artifact_id: "project-tree-canonical"
artifact_type: "repository_map"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file PROJECT_TREE.md --mode headless --json"
tier: 1
immutable: true
requires_human_approval_for_changes: true
related_files:
  - "[[00-STACK-SELECTOR.md]]"
  - "[[IA-QUICKSTART.md]]"
  - "[[AI-NAVIGATION-CONTRACT.md]]"
  - "[[GOVERNANCE-ORCHESTRATOR.md]]"
  - "[[SDD-COLLABORATIVE-GENERATION.md]]"
  - "[[TOOLCHAIN-REFERENCE.md]]"
  - "[[06-PROGRAMMING/00-INDEX.md]]"
checksum_sha256: "PENDING_GENERATION"
---

# 📄 PROJECT_TREE.md – MAPA CANÓNICO DEL REPOSITORIO

> **Nota para principiantes:** Este documento es el "mapa maestro" del proyecto MANTIS AGENTIC. Define la estructura oficial de carpetas y archivos, y qué ruta canónica debe usar cada artefacto. Si eres nuevo, lee las secciones en orden. Si eres experto, salta al JSON final.  
>  
> **Para IAs:** Este es tu contrato de rutas. **USAR RUTA NO CANÓNICA = ARTEFACTO INVÁLIDO**. No inventes, no asumas, no omitas.


# 🗺️ PROJECT_TREE: Mapa Canónico del Repositorio MANTIS AGENTIC

<!-- 
【PARA PRINCIPIANTES】¿Qué es este archivo?
Este documento es el "GPS" del proyecto. Define:
• La estructura oficial de carpetas y archivos
• Qué rutas son canónicas (válidas) para artefactos
• Qué documentos son críticos para la gobernanza
• Cómo navegar entre secciones usando wikilinks

Si eres nuevo: lee en orden. 
Si ya conoces el proyecto: usa los wikilinks para ir directo a lo que necesitas.
-->

> **Instrucción crítica para la IA:** 
> Este documento es tu contrato de rutas. 
> **USAR RUTA NO CANÓNICA = ARTEFACTO INVÁLIDO**. 
> No inventes, no asumas, no omitas. Si algo no está claro, DETENER y preguntar.

---

## 【0】🎯 PROPÓSITO Y ALCANCE (Explicado para humanos)

<!-- 
【EDUCATIVO】Este documento responde: "¿Dónde debe vivir cada archivo en MANTIS AGENTIC?"
No es solo un árbol de archivos. Es un contrato de gobernanza que:
• Previene rutas inventadas o inconsistentes
• Garantiza que los wikilinks [[RUTA]] siempre resuelvan correctamente
• Marca documentos críticos que requieren aprobación humana para cambios
-->

### 0.1 Convenciones de Notación

| Símbolo | Significado | Ejemplo |
|---------|------------|---------|
| `📁` | Directorio/carpeta | `📁 06-PROGRAMMING/` |
| `📄` | Archivo Markdown con frontmatter | `📄 IA-QUICKSTART.md` |
| `🔐` | Documento crítico (requires_human_approval_for_changes: true) | `🔐 00-STACK-SELECTOR.md` |
| `🧰` | Script ejecutable de validación | `🧰 orchestrator-engine.sh` |
| `📦` | Índice agregador de patrones | `📦 00-INDEX.md` |
| `⚙️` | Archivo de configuración/schema | `⚙️ norms-matrix.json` |
| `🗂️` | Carpeta con múltiples artefactos del mismo tipo | `🗂️ go/` |

### 0.2 Reglas Inamovibles de Rutas

```
REGLA 0.1: Todas las rutas en este árbol son canónicas. No usar rutas relativas en wikilinks.
REGLA 0.2: Los documentos marcados 🔐 requieren aprobación humana explícita para cualquier cambio.
REGLA 0.3: Los archivos en 06-PROGRAMMING/ deben seguir LANGUAGE LOCK según su subcarpeta.
REGLA 0.4: Los índices 00-INDEX.md son agregadores: no contienen código, solo referencias.
REGLA 0.5: Los scripts en 05-CONFIGURATIONS/validation/ son parte del toolchain de gobernanza.
```

> 💡 **Consejo para principiantes**: Cuando crees un nuevo artefacto, primero consulta este árbol para identificar la carpeta canónica. Luego consulta `[[00-STACK-SELECTOR]]` para determinar el lenguaje permitido.

---

## 【1】🌳 ÁRBOL CANÓNICO DEL REPOSITORIO

<!-- 
【EDUCATIVO】Este es el árbol oficial. Cada entrada incluye:
• Ruta canónica absoluta
• Tipo de artefacto
• Constraints aplicables
• Wikilink para referencia rápida

El orden es alfabético dentro de cada nivel, excepto documentos críticos que van primero.
-->

```
/ (raíz del repositorio)
├── 🔐 00-STACK-SELECTOR.md                    # Motor de decisión: ruta → lenguaje → constraints [[00-STACK-SELECTOR]]
├── 🔐 IA-QUICKSTART.md                        # Semilla de gobernanza: gate de modo A1-B3 [[IA-QUICKSTART]]
├── 🔐 AI-NAVIGATION-CONTRACT.md               # Contrato de navegación: reglas inamovibles para IA [[AI-NAVIGATION-CONTRACT]]
├── 🔐 GOVERNANCE-ORCHESTRATOR.md              # Motor de certificación: Tiers 1/2/3 y validación [[GOVERNANCE-ORCHESTRATOR]]
├── 🔐 SDD-COLLABORATIVE-GENERATION.md         # Especificación de formato: frontmatter, estructura, ejemplos [[SDD-COLLABORATIVE-GENERATION]]
├── 🔐 TOOLCHAIN-REFERENCE.md                  # Catálogo de herramientas: validación, CI/CD, hooks [[TOOLCHAIN-REFERENCE]]
├── 🔐 PROJECT_TREE.md                         # Este archivo: mapa canónico del repositorio [[PROJECT_TREE]]
├── 📄 RAW_URLS_INDEX.md                       # Índices de URLs raw para acceso remoto de IAs
├── 📄 knowledge-graph.json                    # Grafo de conocimiento para sincronización de agentes
├── 📄 README.md                               # Punto de entrada humano: descripción del proyecto
├── 📄 SECURITY.md                             # Políticas de seguridad y reporte de vulnerabilidades
├── 📄 AI-NAVIGATION-CONTRACT.md               # (ver arriba)
├── 📄 GOVERNANCE-ORCHESTRATOR.md              # (ver arriba)
├── 📄 SDD-COLLABORATIVE-GENERATION.md         # (ver arriba)
├── 📄 TOOLCHAIN-REFERENCE.md                  # (ver arriba)
├── 📄 IA-QUICKSTART.md                        # (ver arriba)
├── 📄 00-STACK-SELECTOR.md                    # (ver arriba)
│
├── 📁 00-CONTEXT/                             # Documentación base: modelo de negocio, contexto técnico
│   ├── 📄 .gitkeep
│   ├── 📦 00-INDEX.md                         # Índice de contexto
│   ├── 📄 PROJECT_OVERVIEW.md                 # Visión general del proyecto
│   ├── 📄 documentation-validation-checklist.md  # Checklist de validación de docs
│   ├── 📄 documentation-validation-checklist.txt # Versión texto plano del checklist
│   ├── 📄 facundo-business-model.md           # Modelo de negocio específico
│   ├── 📄 facundo-core-context.md             # Contexto central del proyecto
│   └── 📄 facundo-infrastructure.md           # Infraestructura técnica base
│
├── 📁 01-RULES/                               # Normas canónicas: HARNESS v3.0, constraints, LANGUAGE LOCK
│   ├── 📄 .gitkeep
│   ├── 📦 00-INDEX.md                         # Índice de reglas
│   ├── 📄 01-ARCHITECTURE-RULES.md            # Reglas de arquitectura
│   ├── 📄 02-RESOURCE-GUARDRAILS.md           # Límites de recursos (C1, C2)
│   ├── 📄 03-SECURITY-RULES.md                # Reglas de seguridad (C3, C4)
│   ├── 📄 04-API-RELIABILITY-RULES.md         # Confiabilidad de APIs (C6, C7)
│   ├── 📄 05-CODE-PATTERNS-RULES.md           # Patrones de código (C5, C8)
│   ├── 📄 06-MULTITENANCY-RULES.md            # Aislamiento multi-tenant (C4)
│   ├── 📄 07-SCALABILITY-RULES.md             # Escalabilidad (C1, C2, C7)
│   ├── 📄 08-SKILLS-REFERENCE.md              # Referencia de skills/patrones
│   ├── 📄 09-AGENTIC-OUTPUT-RULES.md          # Reglas de salida de agentes
│   ├── 📄 10-SDD-CONSTRAINTS.md               # Definición de constraints C1-C8, V1-V3
│   ├── 📄 harness-norms-v2.0.md               # Versión anterior de normas (referencia)
│   ├── 📄 harness-norms-v3.0.md               # ✅ Normas vigentes: HARNESS v3.0-SELECTIVE
│   ├── 📄 language-lock-protocol.md           # 🔐 Protocolo LANGUAGE LOCK: operadores prohibidos por lenguaje
│   └── 📄 validation-checklist.md             # Checklist de validación de artefactos
│
├── 📁 02-SKILLS/                              # Patrones reutilizables por dominio
│   ├── 📄 .gitkeep
│   ├── 📦 00-INDEX.md                         # Índice de skills
│   ├── 📄 README.md                           # Guía de uso de skills
│   ├── 📄 skill-domains-mapping.md            # Mapeo de dominios a skills
│   ├── 📄 GENERATION-MODELS.md                # Modelos de generación soportados
│   │
│   ├── 📁 AGENTIC-ASSISTANCE/                 # Skills para asistencia agéntica
│   │   └── 📄 ide-cli-integration.md          # Integración IDE/CLI para agentes
│   │
│   ├── 📁 AI/                                 # Skills de integración con LLMs
│   │   ├── 📄 .gitkeep
│   │   ├── 📄 deepseek-integration.md         # Integración con DeepSeek
│   │   ├── 📄 gemini-integration.md           # Integración con Gemini
│   │   ├── 📄 gpt-integration.md              # Integración con GPT
│   │   ├── 📄 image-gen-api.md                # API de generación de imágenes
│   │   ├── 📄 llama-integration.md            # Integración con Llama
│   │   ├── 📄 minimax-integration.md          # Integración con MiniMax
│   │   ├── 📄 mistral-ocr-integration.md      # Integración con Mistral OCR
│   │   ├── 📄 openrouter-api-integration.md   # Integración con OpenRouter
│   │   ├── 📄 qwen-integration.md             # ✅ Integración con Qwen (oriental-optimized)
│   │   ├── 📄 video-gen-api.md                # API de generación de video
│   │   └── 📄 voice-agent-integration.md      # Integración con agentes de voz
│   │
│   ├── 📁 BASE DE DATOS-RAG/                  # Skills para bases de datos y RAG
│   │   ├── 📄 .gitkeep
│   │   ├── 📄 airtable-database-patterns.md   # Patrones para Airtable
│   │   ├── 📄 db-selection-decision-tree.md   # Árbol de decisión para selección de DB
│   │   ├── 📄 environment-variable-management.md  # Gestión de variables de entorno
│   │   ├── 📄 espocrm-api-analytics.md        # Analytics para EspoCRM
│   │   ├── 📄 google-drive-qdrant-sync.md     # Sync Google Drive → Qdrant
│   │   ├── 📄 google-sheets-as-database.md    # Google Sheets como DB ligera
│   │   ├── 📄 multi-tenant-data-isolation.md  # Aislamiento de datos multi-tenant
│   │   ├── 📄 mysql-optimization-4gb-ram.md   # Optimización MySQL para 4GB RAM
│   │   ├── 📄 mysql-sql-rag-ingestion.md      # Ingesta RAG desde MySQL
│   │   ├── 📄 pdf-mistralocr-processing.md    # Procesamiento PDF con Mistral OCR
│   │   ├── 📄 postgres-prisma-rag.md          # RAG con PostgreSQL + Prisma
│   │   ├── 📄 qdrant-rag-ingestion.md         # Ingesta RAG en Qdrant
│   │   ├── 📄 rag-system-updates-all-engines.md  # Actualizaciones de sistema RAG
│   │   ├── 📄 redis-session-management.md     # Gestión de sesiones con Redis
│   │   ├── 📄 supabase-rag-integration.md     # Integración RAG con Supabase
│   │   └── 📄 vertical-db-schemas.md          # Esquemas de DB verticales
│   │
│   ├── 📁 COMUNICACION/                       # Skills de comunicación
│   │   ├── 📄 .gitkeep
│   │   ├── 📄 gmail-smtp-integration.md       # Integración Gmail/SMTP
│   │   ├── 📄 google-calendar-api-integration.md  # Integración Google Calendar API
│   │   ├── 📄 telegram-bot-integration.md     # Integración con bots de Telegram
│   │   └── 📄 whatsapp-rag-openrouter.md      # WhatsApp + RAG vía OpenRouter
│   │
│   ├── 📁 CORPORATE-KB/                       # Base de conocimiento corporativa
│   │   └── 📄 .gitkeep
│   │
│   ├── 📁 DEPLOYMENT/                         # Skills de despliegue
│   │   ├── 📄 .gitkeep
│   │   └── 📄 multi-channel-deployment.md     # Despliegue multi-canal
│   │
│   ├── 📁 HOTELES-POSADAS/                    # Skills para sector hotelero
│   │   ├── 📄 .gitkeep
│   │   ├── 📁 prompts/
│   │   ├── 📁 validation/
│   │   └── 📁 workflows/
│   │
│   ├── 📁 INFRASTRUCTURA/                     # Skills de infraestructura
│   │   ├── 📄 .gitkeep
│   │   ├── 📄 docker-compose-networking.md    # Networking con Docker Compose
│   │   ├── 📄 espocrm-setup.md                # Setup de EspoCRM
│   │   ├── 📄 fail2ban-configuration.md       # Configuración de Fail2Ban
│   │   ├── 📄 health-monitoring-vps.md        # Monitoreo de salud en VPS
│   │   ├── 📄 n8n-concurrency-limiting.md     # Limitación de concurrencia en n8n
│   │   ├── 📄 ssh-key-management.md           # Gestión de claves SSH
│   │   ├── 📄 ssh-tunnels-remote-services.md  # Túneles SSH para servicios remotos
│   │   ├── 📄 ufw-firewall-configuration.md   # Configuración de firewall UFW
│   │   └── 📄 vps-interconnection.md          # Interconexión de VPS
│   │
│   ├── 📁 INSTAGRAM-SOCIAL-MEDIA/             # Skills para redes sociales
│   │   ├── 📄 .gitkeep
│   │   ├── 📁 prompts/
│   │   ├── 📁 validation/
│   │   └── 📁 workflows/
│   │
│   ├── 📁 N8N-PATTERNS/                       # Patrones para n8n
│   │   └── 📄 .gitkeep
│   │
│   ├── 📁 ODONTOLOGIA/                        # Skills para sector odontológico
│   │   └── 📄 .gitkeep
│   │
│   ├── 📁 RESTAURANTES/                       # Skills para sector restaurantes
│   │   ├── 📄 .gitkeep
│   │   ├── 📁 prompts/
│   │   ├── 📁 validation/
│   │   └── 📁 workflows/
│   │
│   ├── 📁 SEGURIDAD/                          # Skills de seguridad
│   │   ├── 📄 .gitkeep
│   │   ├── 📄 backup-encryption.md            # Encriptación de backups
│   │   ├── 📄 rsync-automation.md             # Automatización de rsync
│   │   └── 📄 security-hardening-vps.md       # Hardening de seguridad en VPS
│   │
│   └── 📁 WHATSAPP-RAG AGENTS/                # Agentes RAG para WhatsApp
│       └── 📄 .gitkeep
│
├── 📁 03-AGENTS/                              # Definiciones de agentes
│   ├── 📁 clients/                            # Agentes orientados a clientes
│   │   └── 📄 .gitkeep
│   └── 📁 infrastructure/                     # Agentes de infraestructura
│       └── 📄 .gitkeep
│
├── 📁 04-WORKFLOWS/                           # Diagramas y flujos de trabajo
│   ├── 📁 diagrams/                           # Diagramas de arquitectura (Mermaid)
│   │   └── 📄 .gitkeep
│   ├── 📁 n8n/                                # Workflows exportados de n8n
│   │   └── 📄 .gitkeep
│   └── 📄 sdd-universal-assistant.json        # Workflow SDD universal en JSON
│
├── 📁 05-CONFIGURATIONS/                      # Configuración, scripts, validación, templates
│   ├── 📦 00-INDEX.md                         # Índice de configuraciones
│   │
│   ├── 📁 docker-compose/                     # Configuraciones Docker Compose
│   │   ├── 📄 .gitkeep
│   │   ├── 📦 00-INDEX.md
│   │   ├── 📄 vps1-n8n-uazapi.yml             # Config para VPS1: n8n + UAZAPI
│   │   ├── 📄 vps2-crm-qdrant.yml             # Config para VPS2: CRM + Qdrant
│   │   └── 📄 vps3-n8n-uazapi.yml             # Config para VPS3: n8n + UAZAPI
│   │
│   ├── 📁 environment/                        # Variables de entorno y secretos
│   │   ├── 📄 .gitkeep
│   │   └── 📄 .env.example                    # Ejemplo de .env (sin valores reales)
│   │
│   ├── 📁 observability/                      # Configuración de observabilidad
│   │   └── 📄 otel-tracing-config.yaml        # Config de tracing OpenTelemetry
│   │
│   ├── 📁 pipelines/                          # Pipelines de CI/CD y validación
│   │   ├── 📁 .github/workflows/
│   │   │   ├── 📄 integrity-check.yml         # Workflow de verificación de integridad
│   │   │   ├── 📄 terraform-plan.yml          # Workflow de plan Terraform
│   │   │   └── 📄 validate-skill.yml          # Workflow de validación de skills
│   │   ├── 📁 promptfoo/
│   │   │   ├── 📄 config.yaml                 # Config principal de promptfoo
│   │   │   ├── 📁 assertions/
│   │   │   │   ├── 📄 .gitkeep
│   │   │   │   └── 📄 schema-check.yaml       # Assertions para validación de schema
│   │   │   └── 📁 test-cases/
│   │   │       ├── 📄 .gitkeep
│   │   │       ├── 📄 resource-limits.yaml    # Test cases para límites de recursos
│   │   │       └── 📄 tenant-isolation.yaml   # Test cases para aislamiento de tenant
│   │   └── 📄 provider-router.yml             # Router de proveedores de LLM
│   │
│   ├── 📁 scripts/                            # Scripts operativos y de validación
│   │   ├── 📄 .gitkeep
│   │   ├── 📄 VALIDATOR_DOCUMENTATION.md      # Documentación del validador
│   │   ├── 📄 backup-mysql.sh                 # Script de backup de MySQL
│   │   ├── 📄 generate-repo-validation-report.sh  # Generar reporte de validación del repo
│   │   ├── 📄 health-check.sh                 # Script de health check general
│   │   ├── 📄 packager-assisted.sh            # ✅ Empaquetado asistido para Tier 3
│   │   ├── 📄 sync-to-sandbox.sh              # Sync de cambios a sandbox de prueba
│   │   └── 📄 validate-against-specs.sh       # Validar contra especificaciones
│   │
│   ├── 📁 templates/                          # Plantillas para nuevos artefactos
│   │   ├── 📄 bootstrap-company-context.json  # Contexto base para empresas
│   │   ├── 📄 example-template.md             # Ejemplo de plantilla de skill
│   │   ├── 📄 pipeline-template.yml           # Plantilla de pipeline CI/CD
│   │   ├── 📄 skill-template.md               # ✅ Plantilla base para nuevos skills
│   │   └── 📁 terraform-module-template/
│   │       ├── 📄 .gitkeep
│   │       ├── 📄 README.md
│   │       ├── 📄 main.tf
│   │       ├── 📄 outputs.tf
│   │       └── 📄 variables.tf
│   │
│   ├── 📁 terraform/                          # Infraestructura como código (Terraform)
│   │   ├── 📄 backend.tf                      # Configuración de backend remoto
│   │   ├── 📄 outputs.tf                      # Outputs globales
│   │   ├── 📄 variables.tf                    # Variables globales
│   │   ├── 📁 environments/
│   │   │   ├── 📁 dev/
│   │   │   │   └── 📄 terraform.tfvars        # Variables para entorno dev
│   │   │   ├── 📁 prod/
│   │   │   │   └── 📄 terraform.tfvars        # Variables para entorno prod
│   │   │   └── 📄 variables.tf                # Variables por entorno
│   │   └── 📁 modules/
│   │       ├── 📁 backup-encrypted/           # Módulo de backup encriptado
│   │       │   ├── 📄 main.tf
│   │       │   ├── 📄 outputs.tf
│   │       │   └── 📄 variables.tf
│   │       ├── 📁 openrouter-proxy/           # Módulo de proxy para OpenRouter
│   │       │   ├── 📄 main.tf
│   │       │   ├── 📄 outputs.tf
│   │       │   └── 📄 variables.tf
│   │       ├── 📁 postgres-rls/               # Módulo PostgreSQL con RLS
│   │       │   ├── 📄 main.tf
│   │       │   ├── 📄 outputs.tf
│   │       │   └── 📄 variables.tf
│   │       ├── 📁 qdrant-cluster/             # Módulo de cluster Qdrant
│   │       │   ├── 📄 main.tf
│   │       │   ├── 📄 outputs.tf
│   │       │   └── 📄 variables.tf
│   │       └── 📁 vps-base/                   # Módulo base para VPS
│   │           ├── 📄 main.tf
│   │           ├── 📄 outputs.tf
│   │           └── 📄 variables.tf
│   │
│   └── 📁 validation/                         # ✅ Toolchain de validación de gobernanza
│       ├── 📄 .gitkeep
│       ├── 🧰 audit-secrets.sh                # Detección de secrets hardcodeados (C3)
│       ├── 🧰 check-rls.sh                    # Validación de tenant isolation en SQL (C4)
│       ├── 🧰 check-wikilinks.sh              # Validación de wikilinks canónicos (C5)
│       ├── 🧰 norms-matrix.json               # ✅ Matriz de constraints por carpeta
│       ├── 🧰 orchestrator-engine.sh          # ✅ Motor principal de validación y scoring
│       ├── 🧰 schema-validator.py             # Validación de JSON/YAML contra schemas
│       ├── 📁 schemas/
│       │   ├── 📄 skill-input-output.schema.json  # Schema para input/output de skills
│       │   └── 📄 stack-selection.schema.json     # ✅ Schema para decisiones de stack
│       ├── 🧰 validate-frontmatter.sh         # Verificación de frontmatter YAML (C5)
│       ├── 🧰 validate-skill-integrity.sh     # Validación de integridad de skills
│       └── 🧰 verify-constraints.sh           # Validación de constraints y LANGUAGE LOCK
│
├── 📁 06-PROGRAMMING/                         # ✅ Patrones de código por lenguaje (LANGUAGE LOCK aplicado)
│   ├── 📦 00-INDEX.md                         # ✅ Índice agregador maestro de todos los lenguajes
│   │
│   ├── 🗂️ bash/                              # Patrones para scripts Bash (C1-C8, cero V1-V3)
│   │   ├── 📄 .gitkeep
│   │   ├── 📦 00-INDEX.md                     # Índice de patrones Bash
│   │   ├── 📄 context-compaction-utils.md     # Utilidades de compactación de contexto
│   │   ├── 📄 filesystem-sandbox-sync.md      # Sync de sandbox de sistema de archivos
│   │   ├── 📄 filesystem-sandboxing.md        # Sandboxing de sistema de archivos
│   │   ├── 📄 fix-sintaxis-code.md            # Corrección de sintaxis de código
│   │   ├── 📄 git-disaster-recovery.md        # Recuperación ante desastres en Git
│   │   ├── 📄 hardening-verification.md       # Verificación de hardening
│   │   ├── 📄 orchestrator-routing.md         # Enrutamiento del orchestrator
│   │   ├── 📄 robust-error-handling.md        # Manejo robusto de errores
│   │   ├── 📄 scale-simulation-utils.md       # Utilidades de simulación de escala
│   │   └── 📄 yaml-frontmatter-parser.md      # Parser de frontmatter YAML
│   │
│   ├── 🗂️ go/                                # ✅ Patrones para Go (C1-C8, 🔴 LANGUAGE LOCK: cero pgvector, cero V1-V3)
│   │   ├── 📄 .gitkeep
│   │   ├── 📦 00-INDEX.md                     # Índice de patrones Go
│   │   ├── 📄 api-client-management.go.md     # Gestión de clientes API
│   │   ├── 📄 async-patterns-with-timeouts.go.md  # Patrones async con timeouts (C2)
│   │   ├── 📄 authentication-authorization-patterns.go.md  # Patrones de authN/authZ
│   │   ├── 📄 context-compaction-utils.go.md  # Utilidades de compactación de contexto
│   │   ├── 📄 db-selection-decision-tree.go.md  # Árbol de decisión para selección de DB
│   │   ├── 📄 dependency-management.go.md     # Gestión de dependencias
│   │   ├── 📄 error-handling-c7.go.md         # Manejo de errores (C7: resiliencia)
│   │   ├── 📄 filesystem-sandbox-sync.go.md   # Sync de sandbox de FS en Go
│   │   ├── 📄 filesystem-sandboxing.go.md     # Sandboxing de FS en Go
│   │   ├── 📄 git-disaster-recovery.go.md     # Recuperación ante desastres Git en Go
│   │   ├── 📄 hardening-verification.go.md    # Verificación de hardening en Go
│   │   ├── 📄 langchain-style-integration.go.md  # Integración estilo LangChain
│   │   ├── 📄 mcp-server-patterns.go.md       # Patrones para servidores MCP
│   │   ├── 📄 microservices-tenant-isolation.go.md  # Aislamiento multi-tenant en microservicios (C4)
│   │   ├── 📄 mysql-mariadb-optimization.go.md  # Optimización MySQL/MariaDB
│   │   ├── 📄 n8n-webhook-handler.go.md       # Handler de webhooks para n8n
│   │   ├── 📄 observability-opentelemetry.go.md  # Observabilidad con OpenTelemetry (C8)
│   │   ├── 📄 orchestrator-engine.go.md       # ✅ Motor del orchestrator en Go
│   │   ├── 📄 postgres-pgvector-integration.go.md  # Integración con pgvector (solo referencia, cero operadores)
│   │   ├── 📄 prisma-orm-patterns.go.md       # Patrones con Prisma ORM
│   │   ├── 📄 rag-ingestion-pipeline.go.md    # Pipeline de ingesta RAG
│   │   ├── 📄 resource-limits-c1-c2.go.md     # Límites de recursos (C1, C2)
│   │   ├── 📄 saas-deployment-zip-auto.go.md  # Despliegue automático de SaaS en ZIP
│   │   ├── 📄 scale-simulation-utils.go.md    # Utilidades de simulación de escala
│   │   ├── 📄 secrets-management-c3.go.md     # Gestión de secrets (C3: zero hardcode)
│   │   ├── 📄 sql-core-patterns.go.md         # Patrones core de SQL (sin operadores vectoriales)
│   │   ├── 📄 static-dashboard-generator.go.md  # Generador de dashboards estáticos
│   │   ├── 📄 structured-logging-c8.go.md     # Logging estructurado (C8: observabilidad)
│   │   ├── 📄 supabase-rag-integration.go.md  # Integración RAG con Supabase
│   │   ├── 📄 telegram-bot-integration.go.md  # Integración con bots de Telegram
│   │   ├── 📄 testing-multi-tenant-patterns.go.md  # Patrones de testing multi-tenant
│   │   ├── 📄 type-safety-with-generics.go.md # Seguridad de tipos con generics
│   │   ├── 📄 webhook-validation-patterns.go.md  # Patrones de validación de webhooks
│   │   ├── 📄 whatsapp-bot-integration.go.md  # Integración con bots de WhatsApp
│   │   └── 📄 yaml-frontmatter-parser.go.md   # Parser de frontmatter YAML en Go
│   │
│   ├── 🗂️ javascript/                         # Patrones para TypeScript/JavaScript (C1-C8, cero V1-V3)
│   │   ├── 📄 .gitkeep
│   │   ├── 📦 00-INDEX.md                     # Índice de patrones JS/TS
│   │   ├── 📄 async-patterns-with-timeouts.ts.md  # Patrones async con timeouts
│   │   ├── 📄 authentication-authorization-patterns.ts.md  # Patrones de authN/authZ
│   │   ├── 📄 context-compaction-utils.ts.md  # Utilidades de compactación de contexto
│   │   ├── 📄 context-isolation-patterns.ts.md  # Patrones de aislamiento de contexto
│   │   ├── 📄 db-selection-decision-tree.ts.md  # Árbol de decisión para selección de DB
│   │   ├── 📄 dependency-management.ts.md     # Gestión de dependencias
│   │   ├── 📄 filesystem-sandbox-sync.ts.md   # Sync de sandbox de FS
│   │   ├── 📄 filesystem-sandboxing.ts.md     # Sandboxing de FS
│   │   ├── 📄 fix-sintaxis-code.ts.md         # Corrección de sintaxis
│   │   ├── 📄 git-disaster-recovery.ts.md     # Recuperación ante desastres Git
│   │   ├── 📄 hardening-verification.ts.md    # Verificación de hardening
│   │   ├── 📄 langchainjs-integration.ts.md   # Integración con LangChain.js
│   │   ├── 📄 n8n-webhook-handler.ts.md       # Handler de webhooks para n8n
│   │   ├── 📄 observability-opentelemetry.ts.md  # Observabilidad con OpenTelemetry
│   │   ├── 📄 orchestrator-routing.ts.md      # Enrutamiento del orchestrator
│   │   ├── 📄 robust-error-handling.ts.md     # Manejo robusto de errores
│   │   ├── 📄 scale-simulation-utils.ts.md    # Utilidades de simulación de escala
│   │   ├── 📄 secrets-management-patterns.ts.md  # Patrones de gestión de secrets
│   │   ├── 📄 testing-multi-tenant-patterns.ts.md  # Patrones de testing multi-tenant
│   │   ├── 📄 type-safety-with-typescript.ts.md  # Seguridad de tipos con TypeScript
│   │   ├── 📄 vertical-db-schemas.ts.md       # Esquemas de DB verticales
│   │   ├── 📄 webhook-validation-patterns.ts.md  # Patrones de validación de webhooks
│   │   ├── 📄 whatsapp-bot-integration.ts.md  # Integración con bots de WhatsApp
│   │   └── 📄 yaml-frontmatter-parser.ts.md   # Parser de frontmatter YAML
│   │
│   ├── 🗂️ postgresql-pgvector/                # ✅ ÚNICO lugar para búsqueda vectorial (C1-C8 + V1-V3 obligatorios)
│   │   ├── 📄 .gitkeep
│   │   ├── 📦 00-INDEX.md                     # Índice de patrones pgvector
│   │   ├── 📄 fix-sintaxis-code.pgvector.md   # Corrección de sintaxis para pgvector
│   │   ├── 📄 hardening-verification.pgvector.md  # Verificación de hardening para pgvector
│   │   ├── 📄 hybrid-search-rls-aware.pgvector.md  # Búsqueda híbrida RLS-aware
│   │   ├── 📄 migration-patterns-for-vector-schemas.pgvector.md  # Patrones de migración para schemas vectoriales
│   │   ├── 📄 nl-to-vector-query-patterns.pgvector.md  # Patrones de query NL→vector
│   │   ├── 📄 partitioning-strategies-for-high-dim.pgvector.md  # Estrategias de particionado para alta dimensionalidad
│   │   ├── 📄 rag-query-with-tenant-enforcement.pgvector.md  # ✅ Queries RAG con enforcement de tenant (C4 + V1-V3)
│   │   ├── 📄 similarity-explanation-templates.pgvector.md  # Plantillas de explicación de similitud
│   │   ├── 📄 tenant-isolation-for-embeddings.pgvector.md  # Aislamiento de tenant para embeddings (C4)
│   │   └── 📄 vector-indexing-patterns.pgvector.md  # Patrones de indexación vectorial (V3)
│   │
│   ├── 🗂️ python/                             # Patrones para Python (C1-C8, cero V1-V3 excepto en imports controlados)
│   │   ├── 📄 .gitkeep
│   │   ├── 📦 00-INDEX.md                     # Índice de patrones Python
│   │   ├── 📄 async-patterns-with-timeouts.md  # Patrones async con timeouts
│   │   ├── 📄 authentication-authorization-patterns.md  # Patrones de authN/authZ
│   │   ├── 📄 context-compaction-utils.md     # Utilidades de compactación de contexto
│   │   ├── 📄 db-selection-decision-tree.md   # Árbol de decisión para selección de DB
│   │   ├── 📄 dependency-management.md        # Gestión de dependencias
│   │   ├── 📄 filesystem-sandbox-sync.md      # Sync de sandbox de FS
│   │   ├── 📄 filesystem-sandboxing.md        # Sandboxing de FS
│   │   ├── 📄 fix-sintaxis-code.md            # Corrección de sintaxis
│   │   ├── 📄 git-disaster-recovery.md        # Recuperación ante desastres Git
│   │   ├── 📄 hardening-verification.md       # Verificación de hardening
│   │   ├── 📄 langchain-integration.md        # ✅ Integración con LangChain
│   │   ├── 📄 n8n-integration.md              # Integración con n8n
│   │   ├── 📄 observability-opentelemetry.md  # Observabilidad con OpenTelemetry
│   │   ├── 📄 orchestrator-routing.md         # Enrutamiento del orchestrator
│   │   ├── 📄 robust-error-handling.md        # Manejo robusto de errores
│   │   ├── 📄 scale-simulation-utils.md       # Utilidades de simulación de escala
│   │   ├── 📄 secrets-management-patterns.md  # Patrones de gestión de secrets
│   │   ├── 📄 testing-multi-tenant-patterns.md  # Patrones de testing multi-tenant
│   │   ├── 📄 type-safety-with-mypy.md        # Seguridad de tipos con mypy
│   │   ├── 📄 vertical-db-schemas.md          # Esquemas de DB verticales
│   │   ├── 📄 webhook-validation-patterns.md  # Patrones de validación de webhooks
│   │   ├── 📄 whatsapp-bot-integration.md     # Integración con bots de WhatsApp
│   │   └── 📄 yaml-frontmatter-parser.md      # Parser de frontmatter YAML
│   │
│   ├── 🗂️ sql/                               # Patrones para SQL estándar (C1-C8, 🔴 LANGUAGE LOCK: cero operadores pgvector, cero V1-V3)
│   │   ├── 📄 .gitkeep
│   │   ├── 📦 00-INDEX.md                     # Índice de patrones SQL
│   │   ├── 📄 aggregation-multi-tenant-safe.sql.md  # Agregaciones multi-tenant seguras (C4)
│   │   ├── 📄 audit-logging-triggers.sql.md   # Triggers para logging de auditoría
│   │   ├── 📄 audit-trail-ia-generated.sql.md # Trail de auditoría generado por IA
│   │   ├── 📄 backup-restore-tenant-scoped.sql.md  # Backup/restore scoped por tenant
│   │   ├── 📄 column-encryption-patterns.sql.md  # Patrones de encriptación de columnas
│   │   ├── 📄 constraint-validation-tests.sql.md  # Tests de validación de constraints
│   │   ├── 📄 context-injection-for-ia.sql.md # Inyección de contexto para IA
│   │   ├── 📄 crud-with-tenant-enforcement.sql.md  # CRUD con enforcement de tenant (C4)
│   │   ├── 📄 fix-sintaxis-code.sql.md        # Corrección de sintaxis SQL
│   │   ├── 📄 hardening-verification.sql.md   # Verificación de hardening SQL
│   │   ├── 📄 ia-query-validation-gate.sql.md # Gate de validación de queries de IA
│   │   ├── 📄 integration-test-fixtures.sql.md  # Fixtures para tests de integración
│   │   ├── 📄 join-patterns-rls-aware.sql.md  # Patrones de JOIN RLS-aware
│   │   ├── 📄 mcp-sql-tool-definitions.json.md  # Definiciones de herramientas SQL para MCP
│   │   ├── 📄 migration-versioning-patterns.sql.md  # Patrones de versionado de migraciones
│   │   ├── 📄 nl-to-sql-patterns.sql.md       # Patrones de NL→SQL
│   │   ├── 📄 partitioning-strategies.sql.md  # Estrategias de particionado
│   │   ├── 📄 permission-scoping-for-ia.sql.md  # Scoping de permisos para IA
│   │   ├── 📄 query-explanation-templates.sql.md  # Plantillas de explicación de queries
│   │   ├── 📄 robust-error-handling.sql.md    # Manejo robusto de errores SQL
│   │   ├── 📄 rollback-automation-patterns.sql.md  # Patrones de rollback automatizado
│   │   ├── 📄 row-level-security-policies.sql.md  # ✅ Políticas de seguridad a nivel de fila (RLS)
│   │   ├── 📄 schema-diff-validation.sql.md   # Validación de diff de schemas
│   │   ├── 📄 tenant-context-injection.sql.md # Inyección de contexto de tenant
│   │   └── 📄 unit-test-patterns-for-sql.sql.md  # Patrones de unit testing para SQL
│   │
│   └── 🗂️ yaml-json-schema/                   # Patrones para YAML + JSON Schema (C1-C8, cero V1-V3)
│       ├── 📄 .gitkeep
│       ├── 📦 00-INDEX.md                     # Índice de patrones YAML/Schema
│       ├── 📄 dynamic-schema-generation.yaml.md  # Generación dinámica de schemas
│       ├── 📄 environment-config-schema-patterns.yaml.md  # Patrones de schema para config de entorno
│       ├── 📄 json-pointer-jq-integration.yaml.md  # Integración de JSON Pointer con jq
│       ├── 📄 json-schema-draft7-draft2020-migration.yaml.md  # Migración de Draft 7 a Draft 2020
│       ├── 📄 multi-tenant-schema-isolation.yaml.md  # Aislamiento de schema multi-tenant
│       ├── 📄 schema-testing-with-promptfoo.yaml.md  # Testing de schemas con promptfoo
│       ├── 📄 schema-validation-patterns.yaml.md  # Patrones de validación de schemas
│       ├── 📄 schema-versioning-strategies.yaml.md  # Estrategias de versionado de schemas
│       └── 📄 yaml-security-hardening.yaml.md # Hardening de seguridad para YAML
│
├── 📁 07-PROCEDURES/                          # Runbooks y procedimientos operativos
│   └── 📄 .gitkeep
│
├── 📁 08-LOGS/                                # Registros de generación y validación
│   ├── 📄 .gitkeep
│   └── 📁 generation/                         # Logs de generación de artefactos
│       └── 📄 .gitkeep
│
├── 📁 09-TEST-SANDBOX/                        # Entornos de prueba por modelo de IA
│   ├── 📄 README.md                           # Guía de uso del sandbox
│   ├── 📁 claude/                             # Sandbox para Claude
│   │   └── 📄 .gitkeep
│   ├── 📁 comparison/                         # Comparativas entre modelos
│   │   └── 📄 .gitkeep
│   ├── 📁 deepseek/                           # Sandbox para DeepSeek
│   │   ├── 📄 .gitkeep
│   │   ├── 📄 GOVERNANCE-ORCHESTRATOR.md      # Versión sandbox del orchestrator
│   │   └── 🧰 orchestrator-engine.sh          # Versión sandbox del validador
│   ├── 📁 gemini/                             # Sandbox para Gemini
│   │   ├── 📄 .gitkeep
│   │   ├── 📄 GOVERNANCE-ORCHESTRATOR.md
│   │   └── 🧰 orchestrator-engine.sh
│   ├── 📁 minimax/                            # Sandbox para MiniMax
│   │   ├── 📄 .gitkeep
│   │   ├── 📄 GOVERNANCE-ORCHESTRATOR.md
│   │   └── 🧰 orchestrator-engine.sh
│   └── 📁 qwen/                               # ✅ Sandbox para Qwen (oriental-optimized)
│       ├── 📄 .gitkeep
│       ├── 📄 GOVERNANCE-ORCHESTRATOR.md
│       └── 🧰 orchestrator-engine.sh
│
├── 📁 .github/                                # Configuración de GitHub
│   ├── 📄 CODEOWNERS                          # Definición de code owners
│   ├── 📄 dependabot.yml                      # Configuración de Dependabot
│   ├── 📄 PULL_REQUEST_TEMPLATE.md            # Plantilla para PRs
│   └── 📁 workflows/
│       ├── 📄 codeql-analysis.yml             # Análisis de seguridad con CodeQL
│       └── 📄 validate-mantis.yml             # Workflow principal de validación MANTIS
│
└── 📄 .gitignore                              # Reglas de ignorado para Git
```

> 💡 **Consejo para principiantes**: Cuando crees un nuevo artefacto:
> 1. Consulta este árbol para identificar la carpeta canónica
> 2. Consulta `[[00-STACK-SELECTOR]]` para determinar el lenguaje permitido
> 3. Consulta `[[norms-matrix.json]]` para constraints aplicables
> 4. Usa la plantilla `[[05-CONFIGURATIONS/templates/skill-template.md]]`

---

## 【2】🔐 DOCUMENTOS CRÍTICOS DE GOBERNANZA

<!-- 
【EDUCATIVO】Estos documentos son el "núcleo duro" del sistema. 
Cualquier cambio requiere aprobación humana explícita y major version bump.
-->

| Documento | Propósito | Constraints | ¿Por qué es crítico? | Wikilink |
|-----------|-----------|-------------|---------------------|----------|
| `00-STACK-SELECTOR.md` | Motor de decisión: ruta → lenguaje → constraints | C5, C6 | Define el stack permitido para cada tarea. Sin él, deriva garantizada. | `[[00-STACK-SELECTOR]]` |
| `IA-QUICKSTART.md` | Semilla de gobernanza: gate de modo A1-B3 | C1, C4, C6 | Punto de entrada para IAs. Sin gate de modo, validación inconsistente. | `[[IA-QUICKSTART]]` |
| `AI-NAVIGATION-CONTRACT.md` | Contrato de navegación: reglas inamovibles | C1, C4, C6 | Define lo que la IA NO puede hacer. Sin él, alucinaciones sin control. | `[[AI-NAVIGATION-CONTRACT]]` |
| `GOVERNANCE-ORCHESTRATOR.md` | Motor de certificación: Tiers 1/2/3 | C2, C7, C8 | Define cómo se valida y certifica cada artefacto. Sin él, calidad no medible. | `[[GOVERNANCE-ORCHESTRATOR]]` |
| `SDD-COLLABORATIVE-GENERATION.md` | Especificación de formato: frontmatter, estructura | C5, C6 | Define cómo debe verse un artefacto válido. Sin él, inconsistencia estructural. | `[[SDD-COLLABORATIVE-GENERATION]]` |
| `TOOLCHAIN-REFERENCE.md` | Catálogo de herramientas: validación, CI/CD | C5, C8 | Define qué herramientas usar y cómo. Sin él, validación no reproducible. | `[[TOOLCHAIN-REFERENCE]]` |
| `PROJECT_TREE.md` | Este archivo: mapa canónico del repositorio | C5 | Define rutas válidas. Sin él, wikilinks rotos y rutas inventadas. | `[[PROJECT_TREE]]` |
| `norms-matrix.json` | Matriz de constraints por carpeta | C4, C5 | Define qué normas aplican dónde. Sin él, validación arbitraria. | `[[05-CONFIGURATIONS/validation/norms-matrix.json]]` |
| `language-lock-protocol.md` | Reglas de exclusión de operadores por lenguaje | C4, C5 | Previene inyección de operadores prohibidos. Sin él, LANGUAGE LOCK inútil. | `[[01-RULES/language-lock-protocol]]` |

### 2.1 Protocolo de Cambio para Documentos Críticos

```
REGLA 2.1: Cualquier cambio a un documento 🔐 requiere:
  1. Crear rama feature/nombre-cambio
  2. Documentar justificación en PR description
  3. Ejecutar validación completa: orchestrator-engine.sh --file <doc> --json
  4. Obtener aprobación explícita de al menos 2 humanos con rol "governance-owner"
  5. Actualizar version en frontmatter con SemVer (major si breaking change)
  6. Actualizar CHANGELOG.md con descripción del cambio

REGLA 2.2: Cambios breaking (que invalidan artefactos existentes) requieren:
  • Major version bump (ej: 3.0.0 → 4.0.0)
  • Guía de migración en el mismo PR
  • Período de deprecación de 30 días para artefactos antiguos
  • Aprobación explícita de stakeholder principal

REGLA 2.3: Después de merge, ejecutar:
  • generate-repo-validation-report.sh para actualizar índices
  • sync-to-sandbox.sh para propagar cambios a entornos de prueba
  • Notificar a canal #governance-updates con resumen de cambios
```

---

## 【3】🗂️ ÍNDICES AGREGADORES (00-INDEX.md)

<!-- 
【EDUCATIVO】Estos archivos no contienen código, solo referencias canónicas. 
Son el "índice de un libro": te dicen dónde encontrar cada patrón.
-->

### 3.1 Jerarquía de Índices

```
📦 06-PROGRAMMING/00-INDEX.md          # ✅ Maestro: agrega los 7 índices de lenguaje
   ├─ 📦 bash/00-INDEX.md              # Patrones Bash (12 artifacts)
   ├─ 📦 go/00-INDEX.md                # ✅ Patrones Go (35 artifacts, LANGUAGE LOCK activo)
   ├─ 📦 javascript/00-INDEX.md        # Patrones TypeScript/JS (22 artifacts)
   ├─ 📦 postgresql-pgvector/00-INDEX.md  # ✅ Patrones pgvector (10 artifacts, V1-V3 obligatorios)
   ├─ 📦 python/00-INDEX.md            # Patrones Python (24 artifacts)
   ├─ 📦 sql/00-INDEX.md               # Patrones SQL estándar (25 artifacts, LANGUAGE LOCK activo)
   └─ 📦 yaml-json-schema/00-INDEX.md  # Patrones YAML/Schema (9 artifacts)
```

### 3.2 Reglas para Índices Agregadores

```
REGLA 3.1: Los índices 00-INDEX.md NO contienen código ejecutable, solo referencias.
REGLA 3.2: Cada entrada en un índice debe incluir: artifact_id, canonical_path, constraints_mapped.
REGLA 3.3: Los índices deben actualizarse automáticamente vía generate-repo-validation-report.sh.
REGLA 3.4: Los wikilinks en índices deben ser canónicos: [[RUTA-DESDE-RAÍZ]], nunca relativos.
REGLA 3.5: El índice maestro 06-PROGRAMMING/00-INDEX.md debe listarse primero en PROJECT_TREE.md.
```

---

## 【4】🔗 WIKILINKS CANÓNICOS: GUÍA DE USO

<!-- 
【EDUCATIVO】Los wikilinks son enlaces internos al proyecto. 
Usarlos correctamente es crítico para navegación y validación.
-->

### 4.1 Formato Correcto vs Incorrecto

| Wikilink ✅ Válido | Wikilink ❌ Inválido | Corrección 🔧 |
|------------------|---------------------|--------------|
| `[[PROJECT_TREE.md]]` | `[[../PROJECT_TREE.md]]` | Eliminar `../`: usar ruta absoluta desde raíz |
| `[[00-STACK-SELECTOR]]` | `[[./00-STACK-SELECTOR]]` | Eliminar `./`: la raíz es implícita |
| `[[06-PROGRAMMING/go/00-INDEX]]` | `[[go/00-INDEX]]` | Incluir ruta completa desde raíz |
| `[[norms-matrix.json]]` | `[[../validation/norms-matrix.json]]` | Usar ruta canónica: `[[05-CONFIGURATIONS/validation/norms-matrix.json]]` |

### 4.2 Resolución de Wikilinks (Algoritmo)

```
FUNCTION resolve_wikilink(wikilink_text):
    # Paso 1: Extraer contenido entre [[ y ]]
    raw = extract_between(wikilink_text, "[[", "]]")  # ej: "00-STACK-SELECTOR"
    
    # Paso 2: Normalizar extensión
    IF raw does not end with .md, .json, .yml, .yaml, .sh, .py, .go, .ts, .sql:
        raw = raw + ".md"  # Default a Markdown
    
    # Paso 3: Normalizar ruta absoluta
    IF raw does not start with /:
        raw = "/" + raw  # Raíz implícita
    
    # Paso 4: Verificar existencia en PROJECT_TREE.md
    IF raw NOT IN PROJECT_TREE.valid_paths:
        RETURN error: "WIKILINK_NOT_CANONICAL: '{raw}' no es ruta válida"
    
    RETURN raw  # Ruta canónica resuelta
```

> ⚠️ **Contención crítica**: El validador `check-wikilinks.sh` bloquea artefactos con wikilinks relativos. Esto es C5: Structural Contract.

---

## 【5】🧪 SANDBOX DE PRUEBA (OPCIONAL)

<!-- 
【PARA DESARROLLADORES】Pega esta sección en un chat nuevo para validar que la IA sigue el protocolo sin contexto previo.
-->

```
【TEST MODE: PROJECT_TREE VALIDATION】
Prompt de prueba: "¿Dónde debo guardar un patrón de webhook seguro en TypeScript?"

Respuesta esperada de la IA:
1. Consultar PROJECT_TREE.md → buscar carpeta para "webhook" + "TypeScript"
2. Encontrar: 06-PROGRAMMING/javascript/ (TypeScript) → archivo: webhook-validation-patterns.ts.md
3. Consultar 00-STACK-SELECTOR → confirmar: ruta → language=typescript, constraints=C3,C4,C5,C8
4. Consultar norms-matrix.json → validar: constraints_allowed=["C1"-"C8"], mandatory=["C3","C4","C5","C8"]
5. Aplicar LANGUAGE LOCK → typescript: deny_operators=[], deny_constraints=["V1","V2","V3"] ✅
6. Generar artefacto en ruta canónica: 06-PROGRAMMING/javascript/webhook-validation-patterns.ts.md
7. Incluir frontmatter con canonical_path exacto y validation_command ejecutable

Si la IA sugiere ruta no canónica (ej: src/webhooks/), usa lenguaje incorrecto, 
o declara constraints no permitidas → FALLA DE NAVEGACIÓN CANÓNICA.
```

---

## 【6】📦 METADATOS DE EXPANSIÓN (PARA FUTURAS VERSIONES)

<!-- 
【PARA MANTENEDORES】Nuevas secciones deben seguir este formato para no romper compatibilidad.
-->

```json
{
  "expansion_registry": {
    "new_language_folder": {
      "requires_files_update": [
        "PROJECT_TREE.md: add new folder entry under 06-PROGRAMMING/",
        "00-STACK-SELECTOR.md: add routing rule for new language",
        "norms-matrix.json: add constraint mapping for new folder",
        "06-PROGRAMMING/00-INDEX.md: add reference to new language index",
        "Create new 00-INDEX.md in new folder with at least 1 pattern",
        "Human approval required: true"
      ],
      "backward_compatibility": "new languages must not modify LANGUAGE LOCK rules for existing languages"
    },
    "new_governance_document": {
      "requires_files_update": [
        "PROJECT_TREE.md: add new document to root with 🔐 marker if critical",
        "Update related_files in frontmatter of affected documents",
        "Update AI-NAVIGATION-CONTRACT.md if new navigation rules",
        "Update TOOLCHAIN-REFERENCE.md if new validation tools",
        "Human approval required: true + major version bump if breaking"
      ],
      "backward_compatibility": "new governance docs must not invalidate existing artifact formats"
    },
    "new_validation_tool": {
      "requires_files_update": [
        "PROJECT_TREE.md: add tool to 05-CONFIGURATIONS/validation/",
        "TOOLCHAIN-REFERENCE.md: document tool with examples",
        "orchestrator-engine.sh: integrate tool in validation flow",
        "CI/CD workflows: include tool in pre-commit and GitHub Actions",
        "Human approval required: true"
      ],
      "backward_compatibility": "new tools must support existing artifact formats via optional flags"
    }
  },
  "compatibility_rule": "Nuevas entradas en el árbol no deben invalidar rutas canónicas existentes. Cambios breaking requieren major version bump, guía de migración y aprobación humana explícita."
}
```

---

<!-- 
═══════════════════════════════════════════════════════════
🤖 SECCIÓN PARA IA: ÁRBOL JSON ENRIQUECIDO
═══════════════════════════════════════════════════════════
Esta sección contiene metadatos estructurados para consumo automático por agentes de IA.
No está diseñada para lectura humana directa. Los humanos deben usar las secciones 【1】-【6】.

Formato: JSON válido, con comentarios explicativos en claves "doc_*".
Prioridad de ejecución: Las normas se aplican en el orden definido en "norm_execution_order".
Dependencias: Cada nodo declara sus archivos requeridos y sus efectos colaterales.
═══════════════════════════════════════════════════════════
-->

```json
{
  "project_tree_metadata": {
    "version": "3.0.0-SELECTIVE",
    "canonical_path": "/PROJECT_TREE.md",
    "artifact_type": "repository_map",
    "immutable": true,
    "requires_human_approval_for_changes": true,
    "last_updated": "2026-04-19T00:00:00Z",
    "total_directories": 47,
    "total_files": 284,
    "critical_infrastructure_count": 9,
    "llm_optimizations": {
      "oriental_models_friendly": true,
      "delimiters_used": ["【】", "┌─┐", "▼", "✅/❌/🔧"],
      "numbered_sequences": true,
      "stop_conditions_explicit": true
    }
  },
  
  "critical_infrastructure": {
    "description": "Documentos que requieren aprobación humana explícita para cambios",
    "files": [
      {
        "path": "/00-STACK-SELECTOR.md",
        "purpose": "Motor de decisión: ruta → lenguaje → constraints",
        "constraints": ["C5", "C6"],
        "change_requires": ["human_approval", "major_version_bump_if_breaking", "migration_guide"]
      },
      {
        "path": "/IA-QUICKSTART.md",
        "purpose": "Semilla de gobernanza: gate de modo A1-B3",
        "constraints": ["C1", "C4", "C6"],
        "change_requires": ["human_approval", "major_version_bump_if_breaking"]
      },
      {
        "path": "/AI-NAVIGATION-CONTRACT.md",
        "purpose": "Contrato de navegación: reglas inamovibles para IA",
        "constraints": ["C1", "C4", "C6"],
        "change_requires": ["human_approval", "major_version_bump_if_breaking"]
      },
      {
        "path": "/GOVERNANCE-ORCHESTRATOR.md",
        "purpose": "Motor de certificación: Tiers 1/2/3 y validación",
        "constraints": ["C2", "C7", "C8"],
        "change_requires": ["human_approval", "major_version_bump_if_breaking"]
      },
      {
        "path": "/SDD-COLLABORATIVE-GENERATION.md",
        "purpose": "Especificación de formato: frontmatter, estructura, ejemplos",
        "constraints": ["C5", "C6"],
        "change_requires": ["human_approval", "major_version_bump_if_breaking"]
      },
      {
        "path": "/TOOLCHAIN-REFERENCE.md",
        "purpose": "Catálogo de herramientas: validación, CI/CD, hooks",
        "constraints": ["C5", "C8"],
        "change_requires": ["human_approval", "major_version_bump_if_breaking"]
      },
      {
        "path": "/PROJECT_TREE.md",
        "purpose": "Mapa canónico del repositorio (este archivo)",
        "constraints": ["C5"],
        "change_requires": ["human_approval", "major_version_bump_if_breaking"]
      },
      {
        "path": "/05-CONFIGURATIONS/validation/norms-matrix.json",
        "purpose": "Matriz de constraints por carpeta",
        "constraints": ["C4", "C5"],
        "change_requires": ["human_approval", "major_version_bump_if_breaking"]
      },
      {
        "path": "/01-RULES/language-lock-protocol.md",
        "purpose": "Protocolo LANGUAGE LOCK: operadores prohibidos por lenguaje",
        "constraints": ["C4", "C5"],
        "change_requires": ["human_approval", "major_version_bump_if_breaking"]
      }
    ]
  },
  
  "programming_languages_registry": {
    "description": "Registro de lenguajes en 06-PROGRAMMING/ con LANGUAGE LOCK rules",
    "languages": [
      {
        "name": "bash",
        "folder": "06-PROGRAMMING/bash/",
        "index_file": "06-PROGRAMMING/bash/00-INDEX.md",
        "artifact_count": 12,
        "constraints_applicable": ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8"],
        "constraints_mandatory": ["C3", "C4", "C5", "C6"],
        "language_lock": {
          "deny_operators": [],
          "deny_constraints": ["V1", "V2", "V3"],
          "hard_block_violation": true
        },
        "primary_use_cases": ["scripts", "orchestration", "glue-code", "validation"]
      },
      {
        "name": "go",
        "folder": "06-PROGRAMMING/go/",
        "index_file": "06-PROGRAMMING/go/00-INDEX.md",
        "artifact_count": 35,
        "constraints_applicable": ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8"],
        "constraints_mandatory": ["C3", "C4", "C5", "C8"],
        "language_lock": {
          "deny_operators": ["<->", "<=>", "<#", "vector(n)", "USING hnsw", "USING ivfflat"],
          "deny_constraints": ["V1", "V2", "V3"],
          "hard_block_violation": true,
          "validator": "verify-constraints.sh --check-language-lock --dir 06-PROGRAMMING/go/"
        },
        "primary_use_cases": ["microservices", "high-concurrency", "static-binaries", "mcp-servers"]
      },
      {
        "name": "javascript",
        "folder": "06-PROGRAMMING/javascript/",
        "index_file": "06-PROGRAMMING/javascript/00-INDEX.md",
        "artifact_count": 22,
        "constraints_applicable": ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8"],
        "constraints_mandatory": ["C3", "C4", "C5", "C8"],
        "language_lock": {
          "deny_operators": [],
          "deny_constraints": ["V1", "V2", "V3"],
          "hard_block_violation": true
        },
        "primary_use_cases": ["webhooks", "n8n-integration", "frontend", "messaging-bots"],
        "default_extension": "ts.md"
      },
      {
        "name": "postgresql-pgvector",
        "folder": "06-PROGRAMMING/postgresql-pgvector/",
        "index_file": "06-PROGRAMMING/postgresql-pgvector/00-INDEX.md",
        "artifact_count": 10,
        "constraints_applicable": ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "V1", "V2", "V3"],
        "constraints_mandatory": ["C3", "C4", "C5", "V1", "V3"],
        "language_lock": {
          "require_artifact_type": "skill_pgvector",
          "require_vector_declaration": true,
          "require_distance_metric_doc": true,
          "validator": "verify-constraints.sh --check-vector-dims --check-vector-metric --check-vector-index"
        },
        "primary_use_cases": ["vector-search", "embeddings", "rag-queries", "hybrid-search"],
        "is_vector_only": true
      },
      {
        "name": "python",
        "folder": "06-PROGRAMMING/python/",
        "index_file": "06-PROGRAMMING/python/00-INDEX.md",
        "artifact_count": 24,
        "constraints_applicable": ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8"],
        "constraints_mandatory": ["C3", "C4", "C5", "C8"],
        "language_lock": {
          "deny_operators": [],
          "deny_constraints": ["V1", "V2", "V3"],
          "hard_block_violation": true
        },
        "primary_use_cases": ["ai-ml", "langchain", "rapid-prototyping", "data-processing"]
      },
      {
        "name": "sql",
        "folder": "06-PROGRAMMING/sql/",
        "index_file": "06-PROGRAMMING/sql/00-INDEX.md",
        "artifact_count": 25,
        "constraints_applicable": ["C3", "C4", "C5", "C6"],
        "constraints_mandatory": ["C4", "C5"],
        "language_lock": {
          "deny_operators": ["<->", "<=>", "<#", "vector(n)", "USING hnsw", "USING ivfflat"],
          "deny_constraints": ["V1", "V2", "V3"],
          "hard_block_violation": true,
          "validator": "verify-constraints.sh --check-language-lock --dir 06-PROGRAMMING/sql/"
        },
        "primary_use_cases": ["relational-queries", "rls-policies", "migrations", "audit-triggers"]
      },
      {
        "name": "yaml-json-schema",
        "folder": "06-PROGRAMMING/yaml-json-schema/",
        "index_file": "06-PROGRAMMING/yaml-json-schema/00-INDEX.md",
        "artifact_count": 9,
        "constraints_applicable": ["C1", "C3", "C4", "C5", "C7"],
        "constraints_mandatory": ["C5"],
        "language_lock": {
          "require_json_schema_validation": true,
          "deny_constraints": ["V1", "V2", "V3"],
          "hard_block_violation": true,
          "validator": "check-jsonschema --schemafile"
        },
        "primary_use_cases": ["structural-validation", "config-management", "schema-definitions"]
      }
    ]
  },
  
  "valid_paths_index": {
    "description": "Índice de rutas canónicas válidas para validación de wikilinks",
    "root_files": [
      "/00-STACK-SELECTOR.md",
      "/IA-QUICKSTART.md",
      "/AI-NAVIGATION-CONTRACT.md",
      "/GOVERNANCE-ORCHESTRATOR.md",
      "/SDD-COLLABORATIVE-GENERATION.md",
      "/TOOLCHAIN-REFERENCE.md",
      "/PROJECT_TREE.md",
      "/RAW_URLS_INDEX.md",
      "/knowledge-graph.json",
      "/README.md",
      "/SECURITY.md",
      "/.gitignore"
    ],
    "directories": [
      "/00-CONTEXT/",
      "/01-RULES/",
      "/02-SKILLS/",
      "/03-AGENTS/",
      "/04-WORKFLOWS/",
      "/05-CONFIGURATIONS/",
      "/06-PROGRAMMING/",
      "/07-PROCEDURES/",
      "/08-LOGS/",
      "/09-TEST-SANDBOX/",
      "/.github/"
    ],
    "validation_endpoints": [
      "/05-CONFIGURATIONS/validation/orchestrator-engine.sh",
      "/05-CONFIGURATIONS/validation/verify-constraints.sh",
      "/05-CONFIGURATIONS/validation/audit-secrets.sh",
      "/05-CONFIGURATIONS/validation/check-rls.sh",
      "/05-CONFIGURATIONS/validation/validate-frontmatter.sh",
      "/05-CONFIGURATIONS/validation/check-wikilinks.sh",
      "/05-CONFIGURATIONS/validation/schema-validator.py"
    ]
  },
  
  "wikilink_resolution_rules": {
    "description": "Reglas para resolver wikilinks [[RUTA]] a rutas canónicas",
    "normalization_steps": [
      {"step": 1, "action": "extract_content_between_brackets", "example": "[[00-STACK-SELECTOR]] → 00-STACK-SELECTOR"},
      {"step": 2, "action": "add_default_extension_if_missing", "default": ".md", "example": "00-STACK-SELECTOR → 00-STACK-SELECTOR.md"},
      {"step": 3, "action": "prepend_root_slash_if_missing", "example": "00-STACK-SELECTOR.md → /00-STACK-SELECTOR.md"},
      {"step": 4, "action": "validate_against_valid_paths_index", "error_if_not_found": "WIKILINK_NOT_CANONICAL"}
    ],
    "forbidden_patterns": [
      {"pattern": "^\\.\\./", "reason": "Relative paths break canonical resolution", "correction": "Use absolute path from root"},
      {"pattern": "^\\./", "reason": "Explicit current-dir is redundant in canonical paths", "correction": "Remove ./ prefix"}
    ]
  },
  
  "dependency_graph": {
    "critical_infrastructure": [
      {"file": "PROJECT_TREE.md", "purpose": "Resolver rutas canónicas", "load_order": 1},
      {"file": "00-STACK-SELECTOR.md", "purpose": "Determinar lenguaje por ruta", "load_order": 2},
      {"file": "05-CONFIGURATIONS/validation/norms-matrix.json", "purpose": "Mapear constraints por carpeta", "load_order": 3},
      {"file": "01-RULES/harness-norms-v3.0.md", "purpose": "Definición textual de constraints", "load_order": 4},
      {"file": "01-RULES/language-lock-protocol.md", "purpose": "Reglas de exclusión de operadores", "load_order": 5}
    ],
    "navigation_contracts": [
      {"file": "IA-QUICKSTART.md", "purpose": "Definir modos A1-B3 y gate humano", "load_order": 1},
      {"file": "AI-NAVIGATION-CONTRACT.md", "purpose": "Reglas de interacción IA-humano", "load_order": 2},
      {"file": "GOVERNANCE-ORCHESTRATOR.md", "purpose": "Tiers, validación y certificación", "load_order": 3}
    ],
    "pattern_indices": [
      {"file": "06-PROGRAMMING/00-INDEX.md", "purpose": "Agregador de patrones por lenguaje", "load_order": 1},
      {"file": "06-PROGRAMMING/go/00-INDEX.md", "purpose": "Patrones específicos de Go", "load_order": 2},
      {"file": "06-PROGRAMMING/python/00-INDEX.md", "purpose": "Patrones específicos de Python", "load_order": 2},
      {"file": "06-PROGRAMMING/postgresql-pgvector/00-INDEX.md", "purpose": "Patrones específicos de pgvector", "load_order": 2}
    ],
    "validation_toolchain": [
      {"file": "05-CONFIGURATIONS/validation/orchestrator-engine.sh", "purpose": "Motor principal de validación", "load_order": 1},
      {"file": "05-CONFIGURATIONS/validation/verify-constraints.sh", "purpose": "Validación de constraints y LANGUAGE LOCK", "load_order": 2},
      {"file": "05-CONFIGURATIONS/validation/audit-secrets.sh", "purpose": "Detección de secrets hardcodeados", "load_order": 3},
      {"file": "05-CONFIGURATIONS/validation/check-rls.sh", "purpose": "Validación de tenant isolation en SQL", "load_order": 4},
      {"file": "05-CONFIGURATIONS/validation/check-wikilinks.sh", "purpose": "Validación de wikilinks canónicos", "load_order": 5}
    ]
  },
  
  "expansion_hooks": {
    "new_file_addition": {
      "requires_files_update": [
        "PROJECT_TREE.md: add new file entry in correct directory with appropriate emoji marker",
        "Update 00-INDEX.md of parent directory if applicable",
        "Update related_files in frontmatter of affected documents",
        "If critical infrastructure: update critical_infrastructure list and add 🔐 marker",
        "Human approval required: true if in critical_infrastructure or changes navigation"
      ],
      "backward_compatibility": "new files must not break existing wikilinks or canonical paths"
    },
    "new_directory_addition": {
      "requires_files_update": [
        "PROJECT_TREE.md: add new directory entry with 📁 marker and description",
        "Create .gitkeep and 00-INDEX.md in new directory",
        "Update 06-PROGRAMMING/00-INDEX.md if under programming/",
        "Update norms-matrix.json with constraint mapping for new directory",
        "Update 00-STACK-SELECTOR.md with routing rule if under programming/",
        "Human approval required: true"
      ],
      "backward_compatibility": "new directories must not invalidate existing canonical paths"
    }
  },
  
  "validation_metadata": {
    "orchestrator_compatibility": ">=3.0.0-SELECTIVE",
    "schema_version": "project-tree.v1.json",
    "checksum_algorithm": "SHA256",
    "audit_log_format": "JSON Lines with RFC3339 timestamps",
    "pii_scrubbing": "enabled for all logs (C8 compliance)",
    "reproducibility_guarantee": "Any canonical path can be resolved identically using this tree + wikilink_resolution_rules"
  }
}
```

---

## ✅ CHECKLIST DE VALIDACIÓN POST-GENERACIÓN

<!-- 
【PARA PRINCIPIANTES】Antes de guardar este archivo, verifica estos puntos.
-->

````markdown
```bash
# 1. Verificar que el frontmatter es YAML válido
yq eval '.canonical_path' PROJECT_TREE.md
# Esperado: "/PROJECT_TREE.md"

# 2. Verificar que constraints_mapped solo contiene C5 (este archivo es mapa estructural)
yq eval '.constraints_mapped | .[]' PROJECT_TREE.md | grep -E '^C5$' && echo "✅ C5 presente"

# 3. Verificar que todos los documentos críticos están marcados 🔐 en el árbol
grep -c "🔐" PROJECT_TREE.md | awk '{if($1>=9) print "✅ 9+ documentos críticos marcados"; else print "⚠️ Menos de 9 críticos"}'

# 4. Verificar que todos los wikilinks en este archivo apuntan a archivos existentes
for link in $(grep -oE '\[\[[^]]+\]\]' PROJECT_TREE.md | tr -d '[]' | sort -u); do
  if [ ! -f "${link#//}" ] && [ ! -f "${link}" ]; then
    echo "⚠️  Wikilink roto: $link"
  fi
done

# 5. Validar que la sección JSON final es parseable
tail -n +$(grep -n '```json' PROJECT_TREE.md | tail -1 | cut -d: -f1) PROJECT_TREE.md | \
  sed -n '/```json/,/```/p' | sed '1d;$d' | jq empty && echo "✅ JSON válido"

# 6. Validar con orchestrator (simulación mental)
# - ¿El archivo está en raíz? → SÍ
# - ¿El lenguaje es markdown con mapa de repositorio? → SÍ
# - ¿Constraints aplicables según norms-matrix.json? → C5 mandatory → SÍ
# - ¿validation_command es ejecutable? → SÍ, apunta a orchestrator-engine.sh
```
````

**Criterio de aceptación:**  
- ✅ Frontmatter válido con `canonical_path: "/PROJECT_TREE.md"`  
- ✅ `constraints_mapped` contiene solo C5 (este archivo es estructural)  
- ✅ 9 documentos críticos marcados con 🔐 y listados en critical_infrastructure  
- ✅ Sección JSON final es válida (puede parsearse con `jq .`)  
- ✅ Todos los wikilinks apuntan a archivos existentes en el árbol  
- ✅ `validation_command` es ejecutable y apunta al orchestrator correcto  

---

> 🎯 **Mensaje final para el lector humano**:  
> Este mapa es tu brújula. No es estático: evoluciona con el proyecto.  
> **Ruta canónica → Lenguaje permitido → Constraints aplicables → Validación → Entrega**.  
> Si sigues ese flujo, nunca te perderás en el repositorio.  
> La gobernanza no es una carga. Es la libertad de escalar sin miedo a romper.  
