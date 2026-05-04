---
artifact_id: "doc-agnostic-master-agent-mantis"
artifact_type: "agentic-skill-definition"
version: "2.0.0-COMPREHENSIVE"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
# Constraints condicionales: aplican solo cuando la doc trata temas específicos
constraints_conditional:
  V1: "Aplica si la documentación trata aislamiento de tenants, RLS, o configs multi-tenant"
  V2: "Aplica si la documentación incluye ejemplos de embeddings, checksums de datasets vectoriales, o validación de índices"
  V3: "Aplica si la documentación trata métricas de performance vectorial (latencia, recall, benchmarks)"
canonical_path: "docs/framework/doc-agnostic-master-agent.md"
domain: "docs"
subdomain: "framework"
agent_role: "doc-agnostic-master"
language_lock: "es-ES,pt-BR"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain docs --file docs/framework/doc-agnostic-master-agent.md --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants", "human_architects"]
human_readable: true
related_files:
  - "[[00-STACK-SELECTOR.md]]"
  - "[[IA-QUICKSTART.md]]"
  - "[[AI-NAVIGATION-CONTRACT.md]]"
  - "[[PROJECT_TREE.md]]"
  - "[[05-CONFIGURATIONS/validation/norms-matrix.json]]"
  - "[[01-RULES/harness-norms-v3.0.md]]"
  - "[[docs/framework/doc-agnostic-master-agent-appendix-mantis.md]]"
checksum_sha256: "PENDING_GENERATION"
---

# DOC-AGENTIC FRAMEWORK v2.0.0
## Sistema de Orquestación Documental Multi-Agente para MANTIS

> **"La documentación no es un subproducto del código — es la interfaz entre la intención humana y la ejecución de la máquina."**

---

## Índice de Contenidos

- [1. Identidad y Propósito](#1-identidad-y-propósito)
- [2. Filosofía Central y Principios](#2-filosofía-central-y-principios)
- [3. Arquitectura de Agentes](#3-arquitectura-de-agentes)
- [4. Taxonomía Documental](#4-taxonomía-documental)
- [5. Ciclo de Vida y Flujos de Trabajo](#5-ciclo-de-vida-y-flujos-de-trabajo)
- [6. Patrones de Generación](#6-patrones-de-generación)
- [7. Gates de Calidad y Validación](#7-gates-de-calidad-y-validación)
- [8. Automatización e Integración CI/CD](#8-automatización-e-integración-cicd)
- [9. Monitoreo, Analítica y Bucles de Retroalimentación](#9-monitoreo-analítica-y-bucles-de-retroalimentación)
- [10. Ecosistema de Herramientas](#10-ecosistema-de-herramientas)
- [11. Plantillas y Scaffolding](#11-plantillas-y-scaffolding)
- [12. Seguridad y Gobernanza](#12-seguridad-y-gobernanza)
- [13. Mapeo de Constraints MANTIS](#13-mapeo-de-constraints-mantis)
- [14. Anti-Patrones y Modos de Fallo](#14-anti-patrones-y-modos-de-fallo)
- [15. Métricas de Éxito](#15-métricas-de-éxito)
- [Apéndice A: Plantillas de Prompt para Agentes](#apéndice-a-plantillas-de-prompt-para-agentes)
  [canonical_path: "docs/framework/doc-agnostic-master-agent-appendix-mantis.md"]
- [Apéndice B: Tarjetas de Referencia Rápida](#apéndice-b-tarjetas-de-referencia-rápida)
  [canonical_path: "docs/framework/doc-agnostic-master-agent-appendix-mantis.md"]

---

## 1. Identidad y Propósito

### ¿Qué es DOC-AGENTIC para MANTIS?

DOC-AGENTIC es un framework multi-agente para orquestar la creación, análisis, mantenimiento y evolución de documentación técnica a lo largo del ciclo de vida completo del software en el ecosistema MANTIS. Trata la documentación como un **producto de primera clase** — versionado, testeado, monitoreado y continuamente mejorado.

A diferencia de enfoques monolíticos de documentación, DOC-AGENTIC descompone el problema documental en agentes autónomos especializados, cada uno con responsabilidades, entradas, salidas y gates de calidad claros. Un orquestador maestro coordina estos agentes para producir documentación que sea precisa, descubrible, mantenible y alineada tanto con lectores humanos como con agentes de IA.

### ¿Para quién es este framework?

| Persona | Rol | Agentes Primarios |
|---------|------|----------------|
| **Desarrollador** | Escribe código y necesita documentarlo | `code-doc-generator`, `diagram-agent` |
| **Tech Lead** | Revisa arquitectura y decisiones | `architecture-doc-agent`, `adr-agent` |
| **Ingeniero DevOps** | Gestiona infraestructura y despliegues | `deployment-doc-agent`, `pipeline-agent` |
| **Product Manager** | Necesita documentación orientada al usuario | `user-guide-agent`, `api-doc-agent` |
| **Nuevo Integrante** | Onboarding a una base de código | `code-explainer-agent`, `onboarding-agent` |
| **Agente de IA** | Consume documentación programáticamente | `agent-instruction-agent`, `schema-agent` |
| **Líder de Documentación** | Gestiona calidad documental en proyectos | `doc-audit-agent`, `doc-analytics-agent` |

### Alcance

Este framework cubre:

- **Generación**: Crear documentación desde código, configs, schemas e intención humana
- **Análisis**: Auditar documentación existente por brechas, obsolescencia y calidad
- **Mantenimiento**: Mantener documentación sincronizada con sistemas en evolución
- **Evolución**: Adaptar estructura documental mientras los proyectos escalan
- **Gobernanza**: Hacer cumplir estándares, accesibilidad y seguridad en documentación

### Integración con Arquitectura MANTIS

DOC-AGENTIC vive en `docs/framework/` y opera como capa de documentación humana, mientras la raíz del repositorio (`00-CONTEXT` → `09-TEST-SANDBOX`) se mantiene limpia para consumo de agentes de IA. El puente entre ambos mundos es `GOVERNANCE-ORCHESTRATOR.md`, que define los contratos de validación cruzada.

```
┌─────────────────────────────────────────┐
│ RAÍZ DEL REPO (IA-parseable)             │
│ • Frontmatter canónico, constraints     │
│ • Scripts ejecutables, configs HCL/YAML │
│ • Agentes maestros de MANTIS            │
│ • GOVERNANCE-ORCHESTRATOR.md (puente)  │
└─────────────────────────────────────────┘
                    ↕ delega documentación
┌─────────────────────────────────────────┐
│ docs/ (Humano-legible)                   │
│ • DOC-AGENTIC framework vive aquí       │
│ • Espejo estructural de la raíz         │
│ • Índice HTML con búsqueda semántica    │
│ • Bilingüe: ES/PT según config          │
│ • Cron interno para recordatorios       │
└─────────────────────────────────────────┘
```

---

## 2. Filosofía Central y Principios

### Las Cinco Leyes de la Documentación MANTIS

```
L1: EL CÓDIGO ES VERDAD, LA DOC ES CONTRATO
    La documentación debe representar fielmente lo que hace el sistema.
    Cuando código y docs divergen, el código gana — pero las docs deben corregirse.

L2: AUDIENCIA ANTE TODO
    Cada documento tiene un lector. Si no sabes quién es,
    no sabes qué escribir.

L3: LA ESTRUCTURA HABILITA EL DESCUBRIMIENTO
    Un documento perfecto que nadie puede encontrar es un documento que no existe.

L4: LA OBSOLESCENCIA ES UN BUG
    Documentación desactualizada es peor que ninguna documentación.
    Trata la obsolescencia con la misma urgencia que un build roto.

L5: AUTOMATIZA LO MECÁNICO, ELEVA LO HUMANO
    Las máquinas generan referencias y validan estructura.
    Los humanos proporcionan narrativa, contexto y sabiduría.
```

### Principios de Diseño

| Principio | Descripción | Anti-Patrón |
|-----------|-------------|-------------|
| **Alineación Diátaxis** | Todas las docs clasificadas como Tutorial, How-To, Referencia o Explicación | Mezclar contenido orientado a aprendizaje y tarea en un solo doc |
| **Divulgación Progresiva** | Visión general primero, detalles bajo demanda | Volcar todo en un solo muro de texto |
| **Fuente Única de Verdad** | Cada hecho vive en exactamente un lugar | Información duplicada en múltiples docs |
| **Docs-as-Code** | Documentación vive en el repo, versionada con código | Wiki separada que deriva de la realidad |
| **Accesibilidad Primero** | Alt text, encabezados semánticos, contraste legible, compatible con lectores de pantalla | Usar imágenes para texto, color como único indicador |
| **Consciente de Agentes** | Documentación estructurada para consumo humano y de IA | Prosa no estructurada que solo tiene sentido con contexto humano |
| **Bilingüe por Diseño** | Contenido generado en ES/PT según audiencia o config | Traducción manual posterior sin trazabilidad |

---

## 3. Arquitectura de Agentes

### 3.1 Visión General de la Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                DOC-ORCHESTRATOR (Agente Maestro)                │
│                                                                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│  │ Parser   │→│ Motor de │→│ Pipeline │→│ Validar  │→ Salida  │
│  │ Intención│ │ Ruteo    │ │ Ejecución│ │ & Fusionar│          │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘           │
│       ↕              ↕             ↕            ↕                │
│  ┌─────────────────────────────────────────────────────┐        │
│  │                 POOL DE AGENTES                      │        │
│  │                                                      │        │
│  │  ┌─────────────┐  ┌──────────────┐  ┌────────────┐ │        │
│  │  │ Cluster de  │  │ Cluster de   │  │ Cluster de │ │        │
│  │  │ GENERACIÓN  │  │ ANÁLISIS     │  │ GOBERNANZA │ │        │
│  │  │              │  │              │  │            │ │        │
│  │  │ • code-doc   │  │ • doc-audit  │  │ • agent-   │ │        │
│  │  │ • api-doc    │  │ • link-      │  │   instruc- │ │        │
│  │  │ • diagram    │  │   validator  │  │   tion     │ │        │
│  │  │ • deploy-doc │  │ • freshness  │  │ • security │ │        │
│  │  │ • user-guide │  │   checker    │  │   scanner  │ │        │
│  │  │ • adr-agent  │  │ • audience   │  │ • access-  │ │        │
│  │  │ • event-     │  │   analyzer   │  │   ibility  │ │        │
│  │  │   catalog    │  │ • coverage   │  │   checker  │ │        │
│  │  │ • code-      │  │   mapper     │  │ • license  │ │        │
│  │  │   explainer  │  │              │  │   auditor  │ │        │
│  │  └─────────────┘  └──────────────┘  └────────────┘ │        │
│  │                                                      │        │
│  │  ┌─────────────────────────────────────────────┐    │        │
│  │  │ Cluster de EXPERIENCIA                        │    │        │
│  │  │ • onboarding-agent  • search-optimizer       │    │        │
│  │  │ • i18n-agent (ES/PT)• feedback-collector      │    │        │
│  │  └─────────────────────────────────────────────┘    │        │
│  └─────────────────────────────────────────────────────┘        │
│                                                                  │
│  ┌─────────────────────────────────────────────────────┐        │
│  │           MEMORIA COMPARTIDA Y CONTEXTO              │        │
│  │  • Inventario de proyecto  • Personas de audiencia  │        │
│  │  • Glosario de términos    • Guía de estilo         │        │
│  │  • Grafo de enlaces        • Timestamps de frescura │        │
│  │  • Registry ES/PT          • Cron de recordatorios  │        │
│  └─────────────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 Definiciones de Agentes

#### 3.2.1 DOC-ORCHESTRATOR (Agente Maestro)

**Rol**: Coordinador central que recibe solicitudes de documentación, las descompone en subtareas, rutea a agentes especializados, fusiona salidas y hace cumplir gates de calidad.

**Entradas**: Solicitud de usuario, contexto de proyecto, inventario de documentación existente
**Salidas**: Artefactos documentales finales, reporte de validación, ítems de acción

**Comportamiento**:
```
1. PARSEAR intención desde solicitud de usuario
2. INVENTARIAR alcance de documentación existente
3. CLASIFICAR tipo de tarea: generar | revisar | auditar | evolucionar
4. DESCOMPONER en subtareas con dependencias
5. RUTEAR subtareas a agentes especialistas (paralelo donde sea posible)
6. COLECTAR salidas de agentes
7. VALIDAR contra gates de calidad (§7)
8. FUSIONAR en entregable coherente
9. REPORTAR resultados + brechas restantes
```

**Reglas de Delegación**:
- Si la solicitud es puramente documentación de API → delegar a `api-doc-agent` y detenerse
- Si la solicitud es puramente visual/diagramática → delegar a `diagram-agent` y detenerse
- Si la solicitud abarca múltiples dominios → descomponer y coordinar
- Si la solicitud es ambigua → hacer UNA pregunta aclaratoria, luego proceder con mejor interpretación
- Si la solicitud requiere bilingüismo ES/PT → activar `i18n-agent` en pipeline de generación

---

#### 3.2.2 Cluster de Generación

##### `code-doc-generator`
**Especialidad**: Extraer documentación desde código fuente (funciones, clases, módulos, configs)
**Entradas**: Archivos fuente, comentarios de código, anotaciones de tipo
**Salidas**: Referencias de API, mejoras de doc inline, visiones generales de módulos
**Métodos**: Parsing de AST, extracción de comentarios, inferencia de tipos, análisis de grafo de dependencias

##### `api-doc-agent`
**Especialidad**: Generar y mantener documentación de API (REST, GraphQL, gRPC, WebSocket)
**Entradas**: Specs OpenAPI, definiciones de rutas, archivos de schema, anotaciones de código
**Salidas**: Referencias de endpoints, ejemplos de request/response, guías de autenticación, catálogos de errores
**Métodos**: Parsing de OpenAPI/Swagger, transformación schema-to-doc, generación de ejemplos

##### `diagram-agent`
**Especialidad**: Crear representaciones visuales de sistemas, flujos y modelos de datos
**Entradas**: Estructura de código, descripciones de arquitectura, flujos de secuencia
**Salidas**: Diagramas Mermaid (flowchart, sequence, class, state, ER, C4, gantt, mindmap, gitgraph)
**Lógica de Selección**:

| Documentando... | Tipo de Diagrama |
|----------------|----------------|
| Flujo de proceso, algoritmos | Flowchart |
| Llamadas de API, interacciones de servicio | Sequence Diagram |
| Diseño orientado a objetos | Class Diagram |
| Máquinas de estado, ciclos de vida | State Diagram |
| Schema de base de datos | ER Diagram |
| Arquitectura de sistema (alto nivel) | C4 Context |
| Contenedores de aplicación | C4 Container |
| Internals de componentes | C4 Component |
| Flujos de experiencia de usuario | User Journey |
| Líneas de tiempo de proyecto | Gantt Chart |
| Jerarquías de conceptos | Mindmap |
| Evolución histórica | Timeline |
| Proporciones | Pie Chart |

##### `deployment-doc-agent`
**Especialidad**: Documentar infraestructura, pipelines CI/CD, procedimientos de despliegue, estrategias de rollback
**Entradas**: Dockerfiles, docker-compose, manifiestos Kubernetes, config CI, Terraform/CDK
**Salidas**: Guías de despliegue, referencias de entorno, procedimientos de rollback, diagramas de infraestructura
**Métodos**: Parsing de config, detección de secrets, validación de health-check

##### `user-guide-agent`
**Especialidad**: Crear documentación para usuarios finales, tutoriales y guías how-to
**Entradas**: Especificaciones de features, screenshots de UI, user stories, guías existentes
**Salidas**: Tutoriales paso a paso, guías de features, FAQ, docs de troubleshooting
**Métodos**: Escritura basada en personas, divulgación progresiva, flujo de información old-to-new

##### `adr-agent`
**Especialidad**: Gestionar Architecture Decision Records (ADRs)
**Entradas**: Contexto de discusión, análisis de trade-offs, preferencias del equipo
**Salidas**: Documentos ADR (Contexto, Decisión, Consecuencias, Estado)
**Métodos**: Aplicación de plantillas, tracking de consecuencias, repositorio de ADRs buscable

##### `event-catalog-agent`
**Especialidad**: Generar documentación EventCatalog para arquitecturas event-driven
**Entradas**: Definiciones de servicio, schemas de eventos, configuraciones de canales, modelos de dominio
**Salidas**: Archivos MDX de EventCatalog (servicios, eventos, commands, queries, dominios, flujos, canales, lenguaje ubicuo)
**Métodos**: Extracción de schema, mapeo de relaciones, validación de frontmatter, generación de NodeGraph

##### `code-explainer-agent`
**Especialidad**: Transformar código complejo en contenido educativo comprensible
**Entradas**: Código fuente, métricas de complejidad, nivel de audiencia
**Salidas**: Walkthroughs paso a paso, explicaciones visuales, rutas de aprendizaje, ejemplos interactivos
**Métodos**: Análisis de AST, scoring de complejidad, identificación de conceptos, detección de patrones, divulgación progresiva

##### `i18n-agent` (ES/PT)
**Especialidad**: Gestionar internacionalización y localización de documentación en español y portugués
**Entradas**: Documentación fuente, locales objetivo, memoria de traducción
**Salidas**: Documentación traducida, reportes de paridad
**Comportamiento**: Mantener idioma fuente de verdad, trackear completitud de traducción, flaggear divergencias, generar variantes ES/PT con frontmatter bilingüe

---

#### 3.2.3 Cluster de Análisis

##### `doc-audit-agent`
**Especialidad**: Evaluación integral de calidad documental
**Entradas**: Repositorio de documentación, base de código de proyecto
**Salidas**: Reporte de auditoría con scores por categoría, lista priorizada de remediación
**Categorías de Scoring**:

| Categoría | Peso | Métricas |
|----------|--------|---------|
| Estructura | 20% | Profundidad máx 3 niveles, docs < 3000 palabras, sin páginas huérfanas |
| Cohesión | 15% | Densidad de transiciones, consistencia terminológica, flujo de información |
| Audiencia | 15% | Prerrequisitos declarados, indicadores de audiencia, matching de complejidad |
| Navegación | 15% | Breadcrumbs, enlaces relacionados, presencia de TOC, integridad de enlaces |
| Mantenimiento | 20% | Fechas de última actualización, info de versión, frescura de ejemplos de código |
| Legibilidad | 15% | Longitud de párrafos, jerarquía de encabezados, breaks visuales, sizing de bloques de código |

##### `link-validator`
**Especialidad**: Detectar enlaces internos y externos rotos
**Entradas**: Archivos de documentación, configuración de URL base
**Salidas**: Reporte de enlaces rotos con archivo, línea y destino
**Métodos**: Extracción recursiva de enlaces, validación HTTP, chequeo de anchors

##### `freshness-checker`
**Especialidad**: Identificar documentación obsoleta
**Entradas**: Archivos de documentación con metadata, historial de git
**Salidas**: Reporte de frescura ordenado por severidad de obsolescencia
**Umbrales**:
- **Fresco**: Actualizado dentro de 30 días
- **Envejeciendo**: 30-90 días sin actualización
- **Obsoleto**: 90-180 días — revisión requerida
- **Crítico**: 180+ días — asumir inexacto hasta verificación

##### `audience-analyzer`
**Especialidad**: Detectar mezcla de audiencias y desajustes de complejidad
**Entradas**: Contenido documental, personas de audiencia definidas
**Salidas**: Reporte de consistencia de audiencia, recomendaciones de reescritura
**Señales de Detección**: Niveles técnicos mezclados, jerga no definida, prerrequisitos ausentes

##### `coverage-mapper`
**Especialidad**: Mapear cobertura documental contra base de código
**Entradas**: Código fuente, rutas de API, archivos de config, docs existentes
**Salidas**: Matriz de cobertura mostrando superficies documentadas vs no documentadas
**Método**: Extraer todas las interfaces públicas → match contra documentación → reportar brechas

---

#### 3.2.4 Cluster de Gobernanza

##### `agent-instruction-agent`
**Especialidad**: Gestionar AGENTS.md, CONTRIBUTING.md y archivos de instrucción para IA
**Entradas**: Estructura de repositorio, workflows de equipo, config CI/CD, setup de herramientas
**Salidas**: AGENTS.md, CONTRIBUTING.md, archivos alias (CLAUDE.md, .cursorrules, .pi/)
**Comportamiento**:
- Inventariar todos los archivos de instrucción existentes
- Determinar fuente canónica (AGENTS.md o CLAUDE.md)
- Generar o actualizar con prácticas actuales de repo
- Asegurar compatibilidad dual-mode (contribuidores humanos + agentes de IA)
- Detectar y resolver drift de políticas entre archivos alias

##### `security-scanner`
**Especialidad**: Detectar información sensible en documentación
**Entradas**: Archivos de documentación, configs de entorno
**Salidas**: Reporte de seguridad con ítems flaggeados
**Objetivos de Detección**:
- API keys, tokens, passwords en ejemplos
- URLs internas, endpoints privados
- Nombres de empleados, direcciones de email
- Codenames de proyectos internos
- IPs hardcodeadas o detalles de infraestructura

##### `accessibility-checker`
**Especialidad**: Asegurar que la documentación cumple estándares de accesibilidad
**Entradas**: Archivos de documentación, plantillas
**Salidas**: Reporte de accesibilidad con scores de cumplimiento WCAG
**Chequeos**:
- Alt text en todas las imágenes
- Texto de enlace descriptivo (no "click here")
- Jerarquía de encabezados correcta para lectores de pantalla
- Bloques de código con especificación de lenguaje
- Encabezados de tabla marcados correctamente
- Color no como único indicador de significado

##### `license-auditor`
**Especialidad**: Verificar cumplimiento de licencias en documentación
**Entradas**: Archivos de documentación, archivos de dependencias
**Salidas**: Reporte de cumplimiento de licencias
**Chequeos**: Headers de licencia presentes, atribución de contenido de terceros, cumplimiento open-source

---

#### 3.2.5 Cluster de Experiencia

##### `onboarding-agent`
**Especialidad**: Crear documentación de onboarding para desarrolladores
**Entradas**: Estructura de repositorio, workflows de equipo, setup de desarrollo
**Salidas**: Guía de getting started, setup de entorno, guía de primera contribución, visión general de arquitectura
**Objetivo**: Nuevo desarrollador debe ser productivo dentro de 1 semana

##### `i18n-agent` (ES/PT)
**Especialidad**: Gestionar internacionalización y localización de documentación
**Entradas**: Documentación fuente, locales objetivo, memoria de traducción
**Salidas**: Documentación traducida, reportes de paridad
**Comportamiento**: Mantener idioma fuente de verdad, trackear completitud de traducción, flaggear divergencias, generar variantes ES/PT con frontmatter bilingüe

##### `search-optimizer`
**Especialidad**: Mejorar descubribilidad de documentación
**Entradas**: Contenido documental, analytics de búsqueda, queries de usuario
**Salidas**: Títulos optimizados, descripciones, tags, sugerencias de enlazado interno
**Métodos**: Análisis de keywords, análisis de logs de búsqueda, identificación de brechas de contenido

##### `feedback-collector`
**Especialidad**: Agregar y analizar feedback de documentación
**Entradas**: Feedback de usuario, ratings, comentarios, tickets de soporte
**Salidas**: Reporte de feedback, lista priorizada de mejoras, análisis de tendencias
**Métodos**: Análisis de sentimiento, clustering de temas, scoring de impacto

---

### 3.3 Protocolo de Comunicación entre Agentes

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Agente A   │────▶│  Message Bus  │────▶│   Agente B   │
│              │     │              │     │              │
│ Salida: {    │     │ Ruteo:       │     │ Entrada: {   │
│   type,      │     │  por type,   │     │   type,      │
│   content,   │     │  por scope,  │     │   content,   │
│   metadata,  │     │  por priority│     │   metadata,  │
│   confidence │     │              │     │   confidence │
│ }            │     │              │     │ }            │
└─────────────┘     └──────────────┘     └─────────────┘
```

**Schema de Mensaje**:
```yaml
message:
  id: uuid
  from_agent: string          # ID de agente fuente
  to_agent: string | "*"      # Agente destino o broadcast
  type: task | result | query | alert
  priority: critical | high | normal | low
  payload:
    task_description: string
    input_artifacts: list      # Rutas de archivo o contenido inline
    output_format: string      # Formato de salida esperado
    constraints: list          # Constraints a respetar
    language: "es" | "pt" | "both"  # Idioma de salida
  context:
    project_inventory: object  # Estado compartido de proyecto
    audience_persona: object   # Definición de audiencia objetivo
    style_guide: object        # Reglas de formato
    i18n_config: object        # Config de traducción ES/PT
  timestamp: ISO-8601
  confidence: float            # 0.0 - 1.0
```

---

## 4. Taxonomía Documental

### 4.1 Alineación con Framework Diátaxis

Toda la documentación en este framework DEBE clasificarse en uno de cuatro cuadrantes:

```
                    ┌─────────────────────────────────────┐
                    │         ESTUDIANDO                   │
                    │                                      │
                    │   ┌──────────────┬──────────────┐   │
                    │   │  TUTORIALES  │  EXPLICACIÓN  │   │
                    │   │              │              │   │
                    │   │  Orientado a │ Orientado a  │   │
                    │   │  aprendizaje │ comprensión  │   │
                    │   │              │              │   │
                    │   │  "Déjame    │  "Ayúdame a │   │
                    │   │   mostrarte"│   entender" │   │
                    │   ├──────────────┼──────────────┤   │
                    │   │  HOW-TO      │  REFERENCIA │   │
                    │   │  GUÍAS       │              │   │
                    │   │              │              │   │
                    │   │  Orientado a │ Orientado a  │   │
                    │   │  tarea       │ información  │   │
                    │   │              │              │   │
                    │   │  "Muéstrame │  "Dime los  │   │
                    │   │   cómo"     │   hechos"   │   │
                    │   └──────────────┴──────────────┘   │
                    │         HACIENDO                     │
                    └─────────────────────────────────────┘
```

| Cuadrante | Propósito | Características | Ejemplos |
|----------|---------|----------------|---------|
| **Tutorial** | Aprendizaje mediante práctica | Paso a paso, entorno seguro, éxito garantizado | Getting started, primera llamada a API, construir tu primer plugin |
| **How-To** | Realizar tareas específicas | Orientado a objetivo, asume competencia, pasos prácticos | Desplegar a producción, migrar base de datos, añadir autenticación |
| **Referencia** | Buscar información | Completo, preciso, consistente, navegable | Referencia de API, opciones de config, códigos de error, comandos CLI |
| **Explicación** | Entender conceptos | Contexto, discusión, por qué las cosas funcionan así | Visión general de arquitectura, filosofía de diseño, análisis de trade-offs |

### 4.2 Registro de Tipos de Documento

| Tipo | Cuadrante Diátaxis | Agentes Típicos | Trigger de Actualización |
|------|------------------|----------------|----------------|
| README | Mixto (punto de entrada) | `code-doc-generator` | Cualquier cambio significativo |
| Referencia de API | Referencia | `api-doc-agent` | Cambio de endpoint/schema |
| Tutorial | Tutorial | `user-guide-agent` | Adición de feature |
| Guía How-To | How-To | `user-guide-agent` | Cambio de workflow |
| Doc de Arquitectura | Explicación | `diagram-agent`, `adr-agent` | Cambio de diseño de sistema |
| ADR | Explicación | `adr-agent` | Decisión tomada |
| Guía de Despliegue | How-To | `deployment-doc-agent` | Cambio de infraestructura |
| Changelog | Referencia | `code-doc-generator` | Cada release |
| Catálogo de Eventos | Referencia | `event-catalog-agent` | Cambio de servicio/evento |
| Instrucciones para Agentes | Referencia | `agent-instruction-agent` | Cambio de workflow/herramienta |
| Guía de Contribución | How-To | `agent-instruction-agent` | Cambio de proceso |
| Guía de Onboarding | Tutorial | `onboarding-agent` | Cambio de equipo/proceso |
| Troubleshooting | How-To | `user-guide-agent` | Nuevos issues conocidos |
| Glosario | Referencia | `event-catalog-agent` | Adición de término |

### 4.3 Plantillas de Estructura de Carpetas

#### Estándar (Alineado a Diátaxis)
```
docs/
├── tutorials/          # Orientado a aprendizaje
│   ├── getting-started.md
│   └── build-your-first-plugin.md
├── how-to/             # Orientado a tarea
│   ├── deploy-to-production.md
│   └── add-authentication.md
├── reference/          # Orientado a información
│   ├── api/
│   │   └── endpoints.md
│   ├── config.md
│   └── error-codes.md
├── explanation/        # Orientado a comprensión
│   ├── architecture.md
│   └── design-philosophy.md
└── adr/                # Architecture Decision Records
    ├── 001-database-choice.md
    └── 002-api-versioning.md
```

#### Event-Driven (EventCatalog)
```
domains/
├── {DomainName}/
│   ├── index.mdx                    # Definición de dominio
│   ├── ubiquitous-language.mdx      # Glosario DDD
│   └── services/
│       └── {ServiceName}/
│           ├── index.mdx            # Definición de servicio
│           ├── events/
│           │   └── {EventName}/
│           │       ├── index.mdx    # Documentación de evento
│           │       └── schema.json  # Schema de evento
│           ├── commands/
│           │   └── {CommandName}/
│           │       └── index.mdx
│           └── queries/
│               └── {QueryName}/
│                   └── index.mdx
channels/
├── {ChannelName}/
│   └── index.mdx
flows/
├── {FlowName}/
│   └── index.mdx
teams/
├── {team-name}.mdx
```

#### Plano (Proyectos Pequeños)
```
docs/
├── README.md
├── CONTRIBUTING.md
├── AGENTS.md
├── api.md
├── architecture.md
├── deployment.md
├── changelog.md
└── adr/
    └── 001-initial-decisions.md
```

### 4.4 Soporte Bilingüe ES/PT

Cada documento en `docs/` puede generar variantes en español y portugués mediante frontmatter:

```yaml
---
type: tutorial
name: "Getting Started"
languages: ["es", "pt"]
last_updated: "2024-05-21"
---
```

El `i18n-agent` genera:
- `docs/tutorials/getting-started.es.md`
- `docs/tutorials/getting-started.pt.md`
- `docs/tutorials/getting-started.html` (índice bilingüe)

---

## 5. Ciclo de Vida y Flujos de Trabajo

### 5.1 Ciclo de Vida de la Documentación

```
    ┌──────────┐
    │  PLANEAR │ ◄── Identificar alcance, audiencia, tipo
    └────┬─────┘
         │
         ▼
    ┌──────────┐
    │ GENERAR  │ ◄── Crear contenido inicial (agentes + humano)
    └────┬─────┘
         │
         ▼
    ┌──────────┐
    │ VALIDAR  │ ◄── Gates de calidad, chequeo de precisión (§7)
    └────┬─────┘
         │
         ▼
    ┌──────────┐
    │ PUBLICAR │ ◄── Desplegar a plataforma de documentación
    └────┬─────┘
         │
         ▼
    ┌──────────┐
    │ MONITOREAR│ ◄── Trackear uso, feedback, frescura (§9)
    └────┬─────┘
         │
         ▼
    ┌──────────┐
    │ EVOLUCIONAR│ ◄── Actualizar basado en cambios + feedback
    └────┬─────┘
         │
         └──────► Volver a PLANEAR (ciclo continuo)
```

### 5.2 Workflow: Generar Documentación desde Código

```yaml
workflow: generate-from-code
trigger: "Usuario solicita documentación para codebase o módulo"
steps:
  - name: inventory
    agent: doc-orchestrator
    action: Escanear estructura de proyecto, identificar interfaces públicas
    output: surface_list

  - name: classify
    agent: doc-orchestrator
    action: Mapear cada superficie a tipo de documentación (§4.2)
    output: doc_plan

  - name: generate_api_docs
    agent: api-doc-agent
    input: route_definitions, schemas, auth_config
    output: api_reference.md
    parallel: true

  - name: generate_architecture
    agent: diagram-agent
    input: service_dependencies, data_flows
    output: architecture.md + mermaid_diagrams
    parallel: true

  - name: generate_deployment
    agent: deployment-doc-agent
    input: dockerfiles, ci_config, manifests
    output: deployment.md
    parallel: true

  - name: generate_readme
    agent: code-doc-generator
    input: project_metadata, package_json, all_generated_docs
    output: README.md
    depends_on: [generate_api_docs, generate_architecture, generate_deployment]

  - name: generate_i18n
    agent: i18n-agent
    input: all_generated_docs, languages: ["es", "pt"]
    output: docs/*.{es,pt}.md
    parallel: true

  - name: validate
    agent: doc-audit-agent
    input: all_generated_docs
    output: audit_report
    depends_on: [generate_readme, generate_i18n]

  - name: fix_issues
    agent: doc-orchestrator
    input: audit_report
    action: Rutear fixes a agentes apropiados
    output: corrected_docs

  - name: security_scan
    agent: security-scanner
    input: all_docs
    output: security_report

  - name: deliver
    agent: doc-orchestrator
    input: corrected_docs, audit_report, security_report
    output: final_deliverable
```

### 5.3 Workflow: Auditar Documentación Existente

```yaml
workflow: audit-documentation
trigger: "Usuario solicita revisión o auditoría de documentación"
steps:
  - name: inventory
    agent: doc-orchestrator
    action: Descubrir todos los archivos de documentación
    output: file_inventory

  - name: structure_analysis
    agent: doc-audit-agent
    input: file_inventory
    checks:
      - navigation_depth <= 3
      - document_size < 3000_words
      - no_orphan_pages
      - heading_hierarchy_valid
    output: structure_report
    parallel: true

  - name: link_validation
    agent: link-validator
    input: file_inventory
    output: link_report
    parallel: true

  - name: freshness_check
    agent: freshness-checker
    input: file_inventory, git_history
    output: freshness_report
    parallel: true

  - name: audience_analysis
    agent: audience-analyzer
    input: file_inventory
    output: audience_report
    parallel: true

  - name: coverage_mapping
    agent: coverage-mapper
    input: codebase, file_inventory
    output: coverage_report
    parallel: true

  - name: security_scan
    agent: security-scanner
    input: file_inventory
    output: security_report
    parallel: true

  - name: accessibility_check
    agent: accessibility-checker
    input: file_inventory
    output: accessibility_report
    parallel: true

  - name: i18n_parity_check
    agent: i18n-agent
    input: file_inventory
    output: parity_report
    parallel: true

  - name: synthesize
    agent: doc-orchestrator
    input: all_reports
    output: unified_audit_report
    scoring:
      structure: 20%
      cohesion: 15%
      audience: 15%
      navigation: 15%
      maintenance: 20%
      readability: 15%

  - name: remediate
    agent: doc-orchestrator
    input: unified_audit_report
    action: Fix issues de alta confianza, reportar otros
    output: remediated_docs + remaining_issues
```

### 5.4 Workflow: Gestión de Instrucciones para Agentes

```yaml
workflow: manage-agent-instructions
trigger: "Nuevo setup de repo, cambio de workflow, o drift de agente detectado"
steps:
  - name: inventory
    agent: agent-instruction-agent
    action: Encontrar todos los archivos de instrucción (AGENTS.md, CLAUDE.md, .cursorrules, etc.)
    output: instruction_inventory

  - name: determine_canonical
    agent: agent-instruction-agent
    action: Identificar archivo de instrucción primario, mapear aliases
    output: canonical_mapping
    rules:
      - AGENTS.md es canónico si está presente
      - CLAUDE.md es tratado como fuente de política canónica si AGENTS.md ausente
      - Otros archivos (.cursorrules, .pi/, .agent/) son aliases

  - name: generate_or_update
    agent: agent-instruction-agent
    input: repo_structure, ci_config, tooling, workflows
    output: updated_instruction_files
    content:
      - Visión general de proyecto y arquitectura
      - Setup de desarrollo y comandos
      - Estilo de código y convenciones
      - Requisitos de testing
      - Descripción de pipeline CI/CD
      - Estándares de documentación
      - Workflow de contribución
      - Instrucciones específicas para agentes

  - name: validate_consistency
    agent: agent-instruction-agent
    input: all_instruction_files
    checks:
      - no_policy_conflicts
      - all_commands_executable
      - no_stale_references
    output: consistency_report
```

### 5.5 Workflow: Generación de Catálogo de Eventos

```yaml
workflow: generate-event-catalog
trigger: "Usuario quiere documentar arquitectura event-driven"
steps:
  - name: discover
    agent: event-catalog-agent
    action: Identificar servicios, eventos, commands, canales desde codebase
    output: resource_inventory

  - name: generate_domain
    agent: event-catalog-agent
    input: domain_definitions, service_list
    output: domains/{Domain}/index.mdx
    rule: "Cada dominio DEBE tener al menos un servicio"

  - name: generate_services
    agent: event-catalog-agent
    input: service_definitions, message_relationships
    output: services/{Service}/index.mdx
    parallel: true

  - name: generate_events
    agent: event-catalog-agent
    input: event_definitions, schemas
    output: events/{Event}/index.mdx + schema files
    parallel: true

  - name: generate_channels
    agent: event-catalog-agent
    input: channel_definitions, routing_rules
    output: channels/{Channel}/index.mdx
    parallel: true

  - name: generate_flows
    agent: event-catalog-agent
    input: business_process_definitions
    output: flows/{Flow}/index.mdx
    parallel: true

  - name: generate_ubiquitous_language
    agent: event-catalog-agent
    input: all_domain_terms, service_names, event_names
    output: domains/{Domain}/ubiquitous-language.mdx

  - name: validate
    agent: event-catalog-agent
    checks:
      - all_ids_match_folder_names
      - all_versions_valid_semver
      - all_sends_receives_reference_valid_ids
      - all_domains_have_services
      - all_services_listed_in_domain_frontmatter
      - all_domains_have_ubiquitous_language
      - nodegraph_component_in_every_resource
    output: validation_report
```

---

## 6. Patrones de Generación

### 6.1 Patrón de Generación de README

```markdown
# {Nombre del Proyecto}

{Descripción de una línea de lo que hace este proyecto y por qué existe}

## Inicio Rápido

{3 pasos o menos para poner en marcha}

```bash
# Paso 1: Instalar
{comando_de_instalación}

# Paso 2: Configurar
{comando_de_configuración}

# Paso 3: Ejecutar
{comando_de_ejecución}
```

## Visión General

{2-3 párrafos explicando el proyecto, su propósito y features clave}

{Diagrama de arquitectura - Mermaid flowchart o C4 Context}

## Instalación

{Instrucciones detalladas de instalación para diferentes entornos}

## Uso

{Patrones de uso comunes con ejemplos de código}

## Configuración

{Todas las opciones de configuración con defaults y descripciones}

| Opción | Tipo | Default | Descripción |
|--------|------|---------|-------------|
| ... | ... | ... | ... |

## Referencia de API

{Enlace a docs detalladas de API o resumen inline}

## Desarrollo

{Cómo configurar para desarrollo, ejecutar tests, contribuir}

## Contribución

{Enlace a CONTRIBUTING.md o guías inline}

## Licencia

{Tipo de licencia}
```

### 6.2 Patrón de Documentación de API

```markdown
# {Nombre del Endpoint}

{Descripción de lo que hace este endpoint}

## Request

`{MÉTODO} {path}`

### Headers

| Header | Requerido | Descripción |
|--------|----------|-------------|
| Authorization | Sí | Bearer token |
| Content-Type | Sí | application/json |

### Parámetros

| Parámetro | Tipo | En | Requerido | Descripción |
|-----------|------|-----|----------|-------------|
| id | string | path | Sí | Identificador de recurso |
| filter | string | query | No | Criterios de filtro |

### Request Body

```json
{
  "field": "value"
}
```

## Response

### Éxito (200)

```json
{
  "data": {},
  "meta": {}
}
```

### Errores

| Código | Descripción | Causa |
|--------|-------------|-------|
| 400 | Bad Request | Parámetros inválidos |
| 401 | Unauthorized | Token faltante o inválido |
| 404 | Not Found | El recurso no existe |
| 429 | Too Many Requests | Límite de rate excedido |

## Ejemplos

### cURL
```bash
curl -X {MÉTODO} {url} \
  -H "Authorization: Bearer {token}" \
  -d '{"field": "value"}'
```

### Python
```python
response = requests.{method}("{url}", json={"field": "value"})
```

## Límites de Rate

{Información de límites de rate}

## Relacionado

- [{Endpoint Relacionado}](./related-endpoint.md)
- [{Guía Relacionada}](../how-to/related-guide.md)
```

### 6.3 Patrón de Architecture Decision Record

```markdown
# ADR-{NNN}: {Título de la Decisión}

**Estado**: {proposed | accepted | deprecated | superseded}
**Fecha**: {YYYY-MM-DD}
**Decisores**: {lista de personas involucradas}

## Contexto

{¿Cuál es el issue que estamos viendo que motiva esta decisión o cambio?}

## Decisión

{¿Cuál es el cambio que estamos proponiendo y/o haciendo?}

## Consecuencias

### Positivas
- {consecuencia positiva 1}
- {consecuencia positiva 2}

### Negativas
- {consecuencia negativa 1}
- {consecuencia negativa 2}

### Neutrales
- {consecuencia neutral 1}

## Alternativas Consideradas

### {Alternativa 1}
- **Pros**: ...
- **Contras**: ...
- **Por qué rechazada**: ...

### {Alternativa 2}
- **Pros**: ...
- **Contras**: ...
- **Por qué rechazada**: ...

## Relacionado

- Supersede: ADR-{NNN}
- Relacionado con: ADR-{NNN}
```

### 6.4 Patrón de Guía de Despliegue

```markdown
# Guía de Despliegue: {Nombre de la Aplicación}

## Visión General

{Qué cubre este documento, métodos de despliegue disponibles}

**Métodos de Despliegue:**
- CI/CD Automatizado (preferido)
- Despliegue blue-green
- Despliegue canary
- Despliegue manual (solo emergencia)

**Entornos:**
| Entorno | URL | Propósito |
|-------------|-----|---------|
| Desarrollo | dev.example.com | Desarrollo activo |
| Staging | staging.example.com | Testing pre-producción |
| Producción | example.com | Usuarios en vivo |

## Prerrequisitos

{Herramientas requeridas, acceso, conocimiento}

## Proceso de Despliegue

### Despliegue Estándar (CI/CD)

{Proceso de despliegue automatizado paso a paso}

```mermaid
sequenceDiagram
    participant Dev as Desarrollador
    participant CI as Pipeline CI/CD
    participant Staging as Staging
    participant Prod as Producción

    Dev->>CI: Push a main
    CI->>CI: Ejecutar tests
    CI->>Staging: Desplegar a staging
    CI->>CI: Ejecutar tests de integración
    CI->>Prod: Desplegar a producción
    CI->>Dev: Notificar éxito
```

### Despliegue de Emergencia (Manual)

{Pasos de despliegue manual para emergencias}

### Procedimiento de Rollback

{Cómo hacer rollback si algo sale mal}

## Health Checks

{Cómo verificar éxito del despliegue}

## Monitoreo

{Qué monitorear después del despliegue}

## Troubleshooting

{Issues comunes de despliegue y soluciones}
```

### 6.5 Patrón de Explicación de Código

```markdown
# Entendiendo: {Nombre de la Sección de Código}

## Qué Hace Este Código

{Resumen de 2-3 oraciones en lenguaje plano}

**Conceptos Clave**: {concepto1}, {concepto2}, {concepto3}
**Nivel de Dificultad**: {beginner | intermediate | advanced}

{Diagrama de flujo de alto nivel}

## Cómo Funciona

### Paso 1: {Primer Paso Mayor}

{Explicación de lo que sucede}

```python
# Snippet de código anotado
code_here  # Explicación de esta línea
```

### Paso 2: {Segundo Paso Mayor}

{Explicación con diagrama si es complejo}

## Decisiones Clave de Diseño

- **Por qué {patrón}**: {explicación}
- **Por qué no {alternativa}**: {explicación de trade-off}

## Casos Borde

| Caso | Comportamiento | Por qué |
|------|----------|-----|
| Input vacío | Retorna default | Previene errores null |
| Acceso concurrente | Encola request | Seguridad de hilos |

## Errores a Evitar

1. **{Error común}**: {Por qué está mal y qué hacer en su lugar}
2. **{Error común}**: {Por qué está mal y qué hacer en su lugar}

## Relacionado

- [{Sección de código relacionada}](./related.md)
- [{Explicación de concepto}](../explanation/concept.md)
```

---

## 7. Gates de Calidad y Validación

### 7.1 Pipeline de Gates de Calidad

Cada artefacto documental DEBE pasar por gates de calidad antes de publicación:

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ GATE 1   │───▶│ GATE 2   │───▶│ GATE 3   │───▶│ GATE 4   │───▶│ GATE 5   │
│ Estructura│    │ Contenido│    │ Seguridad│    │ Acces-   │    │ Compat   │
│          │    │          │    │          │    │ ibilidad │    │ Agente   │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
```

### 7.2 Definiciones de Gates

#### Gate 1: Validación de Estructura
```
CHEQUEAR:
  ✓ Frontmatter YAML válido (donde aplique)
  ✓ Campos id coinciden con nombres de carpeta
  ✓ Campos version son semver válidos
  ✓ Jerarquía de encabezados (H1 → H2 → H3, sin saltos)
  ✓ Profundidad de navegación ≤ 3 niveles
  ✓ Conteo de palabras del documento < 3000 (o intencionalmente dividido)
  ✓ Sin páginas huérfanas (cada página tiene al menos un enlace entrante)
  ✓ Convenciones de nombre de archivo coinciden con estándares de proyecto

HERRAMIENTA: markdownlint-cli (desactivar MD013, MD033, MD041)
COMANDO: npx --yes markdownlint-cli --disable MD013 MD033 MD041 -- "**/*.md"
```

#### Gate 2: Calidad de Contenido
```
CHEQUEAR:
  ✓ Consistencia terminológica (>90% en todas las docs)
  ✓ Oraciones de transición entre secciones mayores
  ✓ Flujo de información old-to-new
  ✓ Todos los acrónimos definidos en primer uso
  ✓ Ejemplos de código tienen especificación de lenguaje
  ✓ Ejemplos de código están bajo 20 líneas (o divididos)
  ✓ Todos los ejemplos de código testeado y funcional
  ✓ Audiencia claramente declarada
  ✓ Prerrequisitos listados
  ✓ Enlaces a contenido relacionado presentes (3-5 por página)

HERRAMIENTA: Custom terminology checker
COMANDO: for term in "setup" "set-up" "set up"; do echo "$term: $(grep -ri "$term" docs/ | wc -l)"; done
```

#### Gate 3: Escaneo de Seguridad
```
CHEQUEAR:
  ✓ Sin API keys, tokens o passwords
  ✓ Sin URLs internas o endpoints privados
  ✓ Sin PII de empleados (nombres, emails)
  ✓ Sin IPs hardcodeadas o detalles de infraestructura
  ✓ Sin codenames de proyectos internos
  ✓ Ejemplos usan valores placeholder (example.com, api-key-here)

HERRAMIENTA: Secret scanner basado en regex
PATRONES:
  - sk-[a-zA-Z0-9]{48}           # Keys de OpenAI
  - ghp_[a-zA-Z0-9]{36}          # Tokens de GitHub
  - AKIA[0-9A-Z]{16}             # Access keys de AWS
  - mongodb(\+srv)?://[^\s]+     # Connection strings de MongoDB
  - postgres(ql)?://[^\s]+       # Connection strings de PostgreSQL
```

#### Gate 4: Accesibilidad
```
CHEQUEAR:
  ✓ Todas las imágenes tienen alt text
  ✓ Texto de enlace es descriptivo (no "click here")
  ✓ Estructura de encabezados correcta para lectores de pantalla
  ✓ Bloques de código especifican lenguaje
  ✓ Tablas tienen filas de encabezado
  ✓ Color no es único indicador de significado
  ✓ Contraste suficiente en imágenes/diagramas embebidos

HERRAMIENTA: Accessibility linter
```

#### Gate 5: Compatibilidad con Agentes
```
CHEQUEAR:
  ✓ AGENTS.md existe y está actualizado
  ✓ CONTRIBUTING.md existe y coincide con workflow
  ✓ Sin conflictos de políticas entre archivos de instrucción
  ✓ Todos los comandos en AGENTS.md son ejecutables
  ✓ Mapa de superficie de instrucción de agente está completo
  ✓ Archivos alias (CLAUDE.md, .cursorrules, etc.) están en sync

HERRAMIENTA: Validación de agent-instruction-agent
```

### 7.3 Comandos de Validación

```bash
# Suite completa de validación
doc-agentic validate --all

# Gates individuales
doc-agentic validate --structure
doc-agentic validate --content
doc-agentic validate --security
doc-agentic validate --accessibility
doc-agentic validate --agent-compat

# Chequeo rápido (estructura + enlaces solo)
doc-agentic validate --quick

# Modo reporte (no fixear, solo reportar)
doc-agentic validate --all --report-only

# Validación bilingüe ES/PT
doc-agentic validate --i18n --languages es,pt
```

---

## 8. Automatización e Integración CI/CD

### 8.1 Workflow de GitHub Actions

```yaml
# .github/workflows/docs-ci.yml
name: CI de Documentación

on:
  push:
    paths:
      - 'docs/**'
      - 'README.md'
      - 'CONTRIBUTING.md'
      - 'AGENTS.md'
      - 'src/**'          # Re-validar cuando cambia código
  pull_request:
    paths:
      - 'docs/**'
      - 'README.md'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Validación de Estructura
        run: |
          npx --yes markdownlint-cli --disable MD013 MD033 MD041 \
            -- "**/*.md" "docs/**/*.md"

      - name: Validación de Enlaces
        run: |
          npx --yes markdown-link-check \
            "**/*.md" "docs/**/*.md" \
            --config .markdown-link-check.json

      - name: Escaneo de Seguridad
        run: |
          # Escanear por secrets en docs
          grep -rn -E "(sk-[a-zA-Z0-9]{48}|ghp_[a-zA-Z0-9]{36}|AKIA[0-9A-Z]{16})" \
            docs/ README.md && exit 1 || true

      - name: Chequeo de Frescura
        run: |
          # Flaggear docs no actualizadas en 180+ días
          find docs/ -name "*.md" -mtime +180 -exec echo "OBSOLETO: {}" \;

      - name: Reporte de Cobertura
        run: |
          # Comparar endpoints documentados vs rutas reales
          python scripts/doc_coverage.py

  generate:
    needs: validate
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4

      - name: Generar Docs de API
        run: |
          # Auto-generar desde spec OpenAPI
          npx @redocly/cli build-docs openapi.yaml -o docs/reference/api/index.html

      - name: Generar Docs de Catálogo de Eventos
        run: |
          python plugins/doc-generator/doc_generator.py

      - name: Generar Variantes Bilingües ES/PT
        run: |
          python docs/framework/generate_i18n.py --languages es,pt

      - name: Commit de Docs Generadas
        run: |
          git config user.name "Documentation Bot"
          git config user.email "docs@bot.local"
          git add docs/
          git diff --staged --quiet || git commit -m "docs: auto-update generated documentation"
          git push
```

### 8.2 Hooks Pre-commit

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: docs-lint
        name: Linting de Documentación
        entry: npx markdownlint-cli --disable MD013 MD033 MD041
        language: node
        files: '\.md$'

      - id: docs-links
        name: Chequeo de Enlaces de Documentación
        entry: npx markdown-link-check
        language: node
        files: '\.md$'

      - id: docs-secrets
        name: Escaneo de Secrets en Documentación
        entry: grep -n -E "(sk-[a-zA-Z0-9]{48}|ghp_[a-zA-Z0-9]{36})"
        language: system
        files: '\.md$'

      - id: docs-i18n
        name: Validación de Paridad ES/PT
        entry: python docs/framework/validate_i18n.py
        language: python
        files: 'docs/.*\.(es|pt)\.md$'
```

### 8.3 Pipeline de Generación de Documentación

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Fuente      │────▶│  Extraer    │────▶│  Generar    │────▶│  Publicar   │
│  Código/Config│     │  Metadata   │     │  Docs       │     │             │
│              │     │             │     │             │     │             │
│ • OpenAPI    │     │ • Endpoints │     │ • Markdown  │     │ • Sitio     │
│ • Comentarios│     │ • Schemas   │     │ • MDX       │     │   Estático  │
│ • Type defs  │     │ • Deps      │     │ • Diagramas │     │ • GitHub    │
│ • Config     │     │ • Rutas     │     │ • Tablas    │     │   Pages     │
│ • Schemas    │     │ • Metadata  │     │ • Ejemplos  │     │ • Wiki      │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

---

## 9. Monitoreo, Analítica y Bucles de Retroalimentación

### 9.1 Dashboard de Salud Documental

```
┌─────────────────────────────────────────────────────────────┐
│                  DASHBOARD DE SALUD DOC                      │
│                                                              │
│  Puntuación General: 78/100 ████████████░░░░ Buena          │
│                                                              │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐        │
│  │ Estructura   │ │ Frescura     │ │ Cobertura    │        │
│  │ 85/100       │ │ 62/100       │ │ 91/100       │        │
│  │ ████████░░   │ │ ██████░░░░   │ │ █████████░   │        │
│  └──────────────┘ └──────────────┘ └──────────────┘        │
│                                                              │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐        │
│  │ Enlaces      │ │ Seguridad    │ │ Accesibilidad│        │
│  │ 95/100       │ │ 100/100      │ │ 72/100       │        │
│  │ █████████░   │ │ ██████████   │ │ ███████░░░   │        │
│  └──────────────┘ └──────────────┘ └──────────────┘        │
│                                                              │
│  Alertas:                                                    │
│  🔴 3 documentos > 180 días obsoletos                       │
│  🟡 7 documentos sin indicadores de audiencia               │
│  🟡 2 imágenes sin alt text                                 │
│  🟢 Todos los enlaces válidos                               │
│  🟢 No se detectaron secrets                                │
│  🟢 Paridad ES/PT: 94%                                      │
└─────────────────────────────────────────────────────────────┘
```

### 9.2 Métricas a Trackear

| Métrica | Categoría | Objetivo | Medición |
|--------|----------|--------|-------------|
| Profundidad de navegación | Estructura | ≤ 3 niveles | Profundidad máx de carpeta |
| Tamaño de documento | Estructura | < 3000 palabras | Conteo de palabras por archivo |
| Páginas huérfanas | Estructura | 0 | Páginas sin enlaces entrantes |
| Consistencia terminológica | Contenido | > 90% | Varianza de uso de términos |
| Densidad de transiciones | Contenido | Cada 2-3 párrafos | Conteo de palabras de transición |
| Enlaces rotos | Enlaces | 0 | Escaneo de validación de enlaces |
| Documentos obsoletos | Frescura | < 5% del total | Documentos > 180 días |
| Cobertura | Completitud | > 80% | Interfaces documentadas / total |
| Claridad de audiencia | UX | 100% | Docs con audiencia declarada |
| Score de accesibilidad | Accesibilidad | > 90% | Score de checker de accesibilidad |
| Tasa de éxito de búsqueda | Descubribilidad | > 85% | Búsquedas encontrando resultados relevantes |
| Tiempo de onboarding | Efectividad | < 1 semana | Ramp-up time de nuevo integrante |
| Resolución de feedback | Responsividad | < 7 días | Tiempo para abordar issues reportados |
| Paridad ES/PT | Internacionalización | > 95% | % de docs con variantes completas |

### 9.3 Bucle de Retroalimentación

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   COLECTAR  │────▶│   ANALIZAR  │────▶│    ACTUAR   │
│             │     │             │     │             │
│ • Page views│     │ • Patrones  │     │ • Actualizar│
│ • Búsquedas │     │ • Brechas   │     │   docs obsol│
│ • Feedback  │     │ • Tendencias│     │ • Fix enlaces│
│ • Tickets de│     │ • Sentimiento│    │   rotos     │
│   soporte   │     │             │     │ • Añadir    │
│ • Sugerencias│    │             │     │   contenido │
│   de edición│     │             │     │   faltante  │
│             │     │             │     │ • Reestructurar│
└─────────────┘     └─────────────┘     └─────────────┘
       │                                       │
       └───────────────────────────────────────┘
                    Bucle Continuo
```

---

## 10. Ecosistema de Herramientas

### 10.1 Herramientas Core (Requeridas)

| Herramienta | Propósito | Instalación |
|------|---------|-------------|
| **markdownlint-cli** | Validación de formato Markdown | `npx markdownlint-cli` |
| **markdown-link-check** | Detección de enlaces rotos | `npx markdown-link-check` |
| **Mermaid CLI** | Renderizado y validación de diagramas | `npx @mermaid-js/mermaid-cli` |
| **doc_agentic.py** | Suite de validación Python (scripts entregados) | `python docs/framework/doc_agentic.py` |
| **validate-docs.sh** | Script bash ligero para CI/CD | `bash docs/framework/validate-docs.sh` |
| **generate_docs.py** | Renderizador de templates Jinja2 | `python docs/framework/generate_docs.py` |

### 10.2 Herramientas Extendidas (Recomendadas)

| Herramienta | Propósito | Cuándo Usar |
|------|---------|-------------|
| **VitePress** | Sitio de docs basado en Vue | Docs modernas con builds rápidos |
| **Docusaurus** | Sitio de docs basado en React | Documentación MDX-heavy |
| **MkDocs** | Sitio de docs basado en Python | Documentación markdown simple |
| **Redoc** | Renderizado de OpenAPI | Documentación de API |
| **EventCatalog** | Docs de arquitectura event-driven | Sistemas event-driven |
| **Trivy** | Escaneo de secrets en docs | Gate de seguridad |
| **Vale** | Linting de prosa | Consistencia de estilo |
| **Obsidian** | Gestión de conocimiento | Bases de conocimiento personales/de equipo |

### 10.3 Comandos de Análisis Estático

```bash
# Análisis de estructura
find docs/ -name "*.md" -type f | wc -l                    # Total de archivos
find docs/ -name "*.md" -exec wc -w {} + | sort -rn | head -5  # Archivos más grandes
find docs/ -name "*.md" | awk -F/ '{print NF-1}' | sort -rn | head -1  # Profundidad máx

# Análisis de contenido
grep -E "However|Therefore|Additionally|Furthermore" docs/*.md | wc -l  # Transiciones
grep -r "Prerequisites\|Audience\|Required knowledge" docs/  # Indicadores de audiencia

# Análisis de frescura
find docs/ -name "*.md" -mtime +90   # Docs más antiguas que 90 días
find docs/ -name "*.md" -mtime +180  # Docs más antiguas que 180 días

# Validación de enlaces
npx --yes markdown-link-check "*.md" "docs/**/*.md"

# Validación de formato
npx --yes markdownlint-cli --disable MD013 MD033 MD041 -- "*.md" "docs/**/*.md"

# Validación bilingüe ES/PT
python docs/framework/validate_i18n.py --check-parity
```

---

## 11. Plantillas y Scaffolding

### 11.1 Scaffolding de Documentación para Nuevo Proyecto

```bash
# Inicializar estructura de documentación para un nuevo proyecto
doc-agentic init --template diataxis

# Crea:
# docs/
# ├── tutorials/
# │   └── getting-started.md
# ├── how-to/
# │   └── common-tasks.md
# ├── reference/
# │   └── api.md
# ├── explanation/
# │   └── architecture.md
# ├── adr/
# │   └── 000-template.md
# README.md
# CONTRIBUTING.md
# AGENTS.md
# CHANGELOG.md
```

### 11.2 Plantilla: Tutorial

```markdown
---
type: tutorial
audience: {beginner|intermediate|advanced}
languages: ["es", "pt"]
prerequisites:
  - {prerrequisito 1}
  - {prerrequisito 2}
estimated_time: {X} minutos
last_updated: {YYYY-MM-DD}
---

# {Título del Tutorial}

## Qué Aprenderás

Al final de este tutorial, podrás:
- {Resultado de aprendizaje 1}
- {Resultado de aprendizaje 2}
- {Resultado de aprendizaje 3}

## Prerrequisitos

Antes de comenzar, asegúrate de tener:
- {prerrequisito con enlace de setup}

**Tiempo estimado**: {{ estimated_time }}

---

{% for step in steps %}
## Paso {{ loop.index }}: {{ step.title }}

{{ step.explanation }}

{% if step.code %}
```{{ step.language | default('bash') }}
{{ step.code }}
```
{% endif %}

{% if step.output %}
**Salida**:
```
{{ step.output }}
```
{% endif %}

{% if step.note %}
> **Nota**: {{ step.note }}
{% endif %}

{% endfor %}

---

## Resumen

En este tutorial, aprendiste:
{% for point in summary_points %}
- {{ point }}
{% endfor %}

{% if next_steps %}
## Próximos Pasos

{% for link in next_steps %}
- [{{ link.title }}]({{ link.url }})
{% endfor %}
{% endif %}
```

### 11.3 Plantilla: Auto-Generación Jinja2

```jinja2
{# agents.md.j2 - Plantilla de Referencia de Agentes #}
# Referencia de Agentes

> Auto-generado desde catálogo de marketplace
> Última actualización: {{ now }}
> Total de agentes: {{ stats.total_agents }}

{% for category, plugins in plugins_by_category.items() %}
## {{ category | title }}

{% for plugin in plugins %}
### {{ plugin.name }}

{{ plugin.description }}

| Agente | Modelo | Descripción |
|-------|-------|-------------|
{% for agent in all_agents if agent.plugin == plugin.name %}
| **{{ agent.name }}** | `{{ agent.model }}` | {{ agent.description }} |
{% endfor %}

{% endfor %}
{% endfor %}

---

*Generado por agente documentation-update de DOC-AGENTIC*
```

---

## 12. Seguridad y Gobernanza

### 12.1 Reglas de Seguridad Documental

```
REGLA-1: NUNCA incluir credenciales reales en ejemplos de documentación
REGLA-2: NUNCA exponer URLs internas o detalles de infraestructura
REGLA-3: NUNCA incluir PII de empleados sin consentimiento
REGLA-4: SIEMPRE usar valores placeholder (example.com, api-key-here, ****)
REGLA-5: SIEMPRE escanear documentación antes de publicar
REGLA-6: SIEMPRE redactar datos sensibles de ejemplos de error
REGLA-7: SIEMPRE revisar documentación generada por fuga de información
```

### 12.2 Estándares de Placeholder

| Tipo | Placeholder | Ejemplo |
|------|-------------|---------|
| URL | `https://api.example.com` | No URLs internas |
| API Key | `your-api-key-here` | No keys reales |
| Email | `user@example.com` | No emails reales |
| IP | `192.0.2.1` (RFC 5737) | No IPs de producción |
| Password | `********` o `[REDACTED]` | No passwords reales |
| Dominio | `example.com` / `example.org` | No dominios internos |
| Base de Datos | `postgresql://user:pass@localhost:5432/dbname` | No strings de producción |

### 12.3 Jerarquía de Documentación de Gobernanza

```
┌─────────────────────────────────────────┐
│         FUENTE CANÓNICA                  │
│         AGENTS.md (o CLAUDE.md)          │
│         Política: TODOS los agentes leen esto │
├─────────────────────────────────────────┤
│         CONTRIBUTING.md                  │
│         Política: Contribuidores humanos │
├─────────────────────────────────────────┤
│         ARCHIVOS ALIAS                   │
│         .cursorrules, .pi/, .agent/      │
│         Política: Mantener en sync, no  │
│         autoritativos                    │
└─────────────────────────────────────────┘

PRECEDENCIA: Canónico > Contributing > Aliases
DETECCIÓN DE DRIFT: Ejecutar en cada PR que toque cualquier archivo de instrucción
```

---

## 13. Mapeo de Constraints MANTIS

Este framework mapea a los siguientes constraints de calidad y gobernanza:

| Constraint | ID | Descripción | Cobertura del Framework |
|-----------|-----|-------------|-------------------|
| **Precisión Documental** | DOC-C1 | Docs deben coincidir con comportamiento actual del sistema | §7 Gate 2, §9.2 Métricas de frescura |
| **Integridad Estructural** | DOC-C2 | Jerarquía consistente, sin huérfanos, profundidad adecuada | §7 Gate 1, §4.3 Estructuras de carpeta |
| **Cumplimiento de Seguridad** | DOC-C3 | Sin secrets, PII, o URLs internas en docs | §7 Gate 3, §12 Reglas de seguridad |
| **Trazabilidad** | DOC-C4 | Cada cambio de doc está versionado y atribuible | §8 CI/CD, Principio Docs-as-Code |
| **Validación Automatizada** | DOC-C5 | Gates de calidad se ejecutan automáticamente | §7 Gates de calidad, §8 Automatización |
| **Proceso de Revisión** | DOC-C6 | Docs críticas requieren revisión humana | §7 Pipeline de gates, §8 Chequeos de PR |
| **Capacidad de Rollback** | DOC-C7 | Documentación puede revertirse a estado anterior | Versionado basado en Git |
| **Accesibilidad** | DOC-C8 | Documentación es usable por todos | §7 Gate 4, §10 Checker de accesibilidad |
| **Compatibilidad con Agentes** | DOC-V1 | Agentes de IA pueden consumir documentación | §7 Gate 5, §3.2.4 Agente de instrucción |
| **Internacionalización** | DOC-V2 | Paridad multi-idioma trackeada | §3.2.5 i18n-agent, soporte ES/PT |
| **Descubribilidad** | DOC-V3 | Documentación es encontrable y buscable | §3.2.5 search-optimizer, §9.2 Métricas |

---

## 14. Anti-Patrones y Modos de Fallo

### 14.1 Anti-Patrones Documentales

| Anti-Patrón | Descripción | Remedio |
|-------------|-------------|--------|
| **El Muro** | Bloques de texto masivos sin breaks visuales | Párrafos < 5 líneas, usar listas y tablas |
| **El Cementerio** | Docs que nadie actualiza, lentamente convirtiéndose en mentiras | Chequeos de frescura, asignar ownership |
| **La Cámara de Eco** | Misma información duplicada en 5 lugares | Fuente única de verdad, cross-references |
| **La Novela de Misterio** | Entierra la respuesta bajo párrafos de contexto | Pirámide invertida: respuesta primero, contexto después |
| **El Club Solo para Expertos** | Asume que el lector lo sabe todo | Declarar prerrequisitos, definir términos |
| **El Museo de Screenshots** | Screenshots en lugar de texto que puede versionarse | Usar bloques de código, tablas, descripciones de texto |
| **El Cementerio de Enlaces** | Lleno de enlaces rotos apuntando a contenido movido/eliminado | Validación automatizada de enlaces |
| **El README Monolito** | README de 5000 líneas tratando de ser todo | Dividir en docs/ con taxonomía clara |
| **La Novela del Changelog** | "Arreglados algunos bugs" — no le dice nada al lector | Changelog estructurado (Added, Changed, Fixed, Removed) |
| **El Páramo Generado** | Docs auto-generadas sin narrativa humana | Generar lo mecánico, narrar lo significativo |

### 14.2 Modos de Fallo de Agentes

| Fallo | Causa | Mitigación |
|---------|-------|------------|
| **Contenido alucinado** | Agente genera info plausible pero incorrecta | Siempre validar contra código fuente; requerir revisión humana para docs críticas |
| **Scope creep** | Agente genera docs fuera del scope solicitado | Límites claros de tarea en prompts de agente; orquestador hace cumplir scope |
| **Refinamiento infinito** | Agente sigue iterando sin converger | Establecer máx iteraciones; aceptar "suficientemente bueno" para docs no críticas |
| **Overflow de ventana de contexto** | Demasiado código/docs para un solo pase de agente | Procesamiento por chunks; usar sub-agentes para trabajo paralelo |
| **Rigidez de plantilla** | Agente fuerza contenido en plantilla incorrecta | Agente selecciona plantilla basada en tipo de contenido; permite override de plantilla |

---

## 15. Métricas de Éxito

### 15.1 Métricas a Nivel de Framework

| Métrica | Objetivo | Método de Medición |
|--------|--------|--------------------|
| Cobertura documental | > 80% de interfaces públicas | Coverage mapper |
| Frescura | < 5% docs obsoletas (> 180 días) | Freshness checker |
| Cero enlaces rotos | 0 enlaces rotos | Link validator |
| Cumplimiento de seguridad | 0 secrets/PII encontrados | Security scanner |
| Score de accesibilidad | > 90% cumplimiento WCAG | Accessibility checker |
| Compatibilidad con agentes | Todos los archivos de instrucción en sync | Agent instruction agent |
| Tiempo de onboarding | Nuevo desarrollador productivo en < 1 semana | Encuesta de equipo |
| Satisfacción con documentación | > 4.0/5.0 rating de usuario | Sistema de feedback |
| Paridad ES/PT | > 95% de docs con variantes completas | i18n-agent parity report |

### 15.2 Métricas por Documento

```
SCORE DE SALUD DOCUMENTAL = (
    structure_score * 0.20 +
    content_score * 0.20 +
    freshness_score * 0.20 +
    link_score * 0.15 +
    accessibility_score * 0.15 +
    audience_score * 0.10
)

CALIFICACIONES:
  90-100: Excelente — mantener estado actual
  75-89:  Buena — mejoras menores necesarias
  60-74:  Regular — mejoras significativas necesarias
  < 60:   Pobre — reescribir o retirar
```

---

## Apéndice A: Plantillas de Prompt para Agentes

### Prompt del Orquestador Maestro

```
Eres DOC-ORCHESTRATOR, el coordinador maestro del framework de documentación. Tu rol es:

1. Entender la solicitud de documentación del usuario
2. Inventariar alcance de documentación existente
3. Descomponer la solicitud en subtareas
4. Rutear subtareas a agentes especialistas
5. Validar salidas contra gates de calidad
6. Fusionar resultados en un entregable coherente
7. Reportar resultados y brechas restantes

CONSTRAINTS:
- Seguir framework Diátaxis para clasificación
- Aplicar los 5 gates de calidad antes de entrega
- Nunca exponer secrets o URLs internas
- Hacer como máximo UNA pregunta aclaratoria antes de proceder
- Paralelizar subtareas independientes
- Priorizar precisión sobre velocidad
- Soportar generación bilingüe ES/PT cuando se solicite
```

### Plantilla de Prompt para Agente de Generación

```
Eres {AGENT_NAME}, un especialista en {SPECIALTY}.

CONTEXTO:
{project_context}

TAREA:
{task_description}

CONSTRAINTS:
- Seguir el patrón de plantilla {TEMPLATE_NAME}
- Incluir frontmatter YAML con id, name, version, summary
- Incluir diagramas Mermaid donde añadan claridad
- Usar valores placeholder para todos los datos sensibles
- Mantener documentos bajo 3000 palabras
- Declarar audiencia y prerrequisitos
- Soportar generación bilingüe si languages incluye ["es", "pt"]

SALIDA:
{expected_output_format}

GATES DE CALIDAD:
{applicable_quality_checks}
```

### Plantilla de Prompt para Agente de Auditoría

```
Eres DOC-AUDIT-AGENT, responsable de evaluación integral de calidad documental.

ALCANCE:
{documentation_scope}

CHEQUEOS A REALIZAR:
- [ ] Validación de estructura (profundidad, tamaño, huérfanos, encabezados)
- [ ] Calidad de contenido (terminología, transiciones, flujo)
- [ ] Frescura (fechas de última actualización, vigencia de versión)
- [ ] Integridad de enlaces (internos y externos)
- [ ] Consistencia de audiencia (prerrequisitos, matching de complejidad)
- [ ] Escaneo de seguridad (secrets, PII, URLs internas)
- [ ] Accesibilidad (alt text, encabezados, texto de enlace)
- [ ] Cobertura (superficies documentadas vs no documentadas)
- [ ] Paridad ES/PT (si aplica)

FORMATO DE SALIDA:
{
  "overall_score": 0-100,
  "category_scores": { ... },
  "issues": [
    {
      "severity": "critical|high|medium|low",
      "category": "...",
      "file": "...",
      "line": N,
      "description": "...",
      "fix_suggestion": "..."
    }
  ],
  "summary": "...",
  "i18n_parity": { "es": 0.98, "pt": 0.94 }
}
```

---

## Apéndice B: Tarjetas de Referencia Rápida

### Árbol de Decisión Documental

```
¿Necesitas documentar algo?
│
├─ ¿Es un proceso/workflow?
│  ├─ Para aprender → TUTORIAL
│  └─ Para hacer → GUÍA HOW-TO
│
├─ ¿Son hechos técnicos/specs?
│  └─ REFERENCIA
│
├─ ¿Son conceptos/razonamiento?
│  └─ EXPLICACIÓN
│
├─ ¿Es una decisión arquitectónica?
│  └─ ADR
│
├─ ¿Es arquitectura event-driven?
│  └-> CATÁLOGO DE EVENTOS
│
└─ ¿No estás seguro?
   └─ Preguntar: "¿Qué HARÁ el lector con esta información?"
      ├─ Aprender → Tutorial
      ├─ Realizar → How-To
      ├─ Consultar → Referencia
      └─ Entender → Explicación
```

### Referencia Rápida de Selección de Diagramas

```
¿Qué estás documentando?
│
├─ ¿Un proceso? → flowchart
├─ ¿Interacciones entre sistemas? → sequence diagram
├─ ¿Relaciones de datos? → ER diagram
├─ ¿Estructura de clase/objeto? → class diagram
├─ ¿Transiciones de estado? → stateDiagram
├─ ¿Arquitectura de sistema? → C4 diagram
├─ ¿Experiencia de usuario? → user journey
├─ ¿Línea de tiempo de proyecto? → gantt
├─ ¿Relaciones de conceptos? → mindmap
└─ ¿Eventos históricos? → timeline
```

### Checklist Rápido de Gate de Calidad

```
Antes de publicar cualquier documentación:

□ Estructura: Profundidad ≤ 3, palabras < 3000, sin huérfanos
□ Contenido: Términos consistentes, transiciones presentes, flujo lógico
□ Enlaces: Todos los enlaces internos y externos válidos
□ Seguridad: Sin secrets, PII, o URLs internas
□ Accesibilidad: Alt text, enlaces descriptivos, jerarquía de encabezados
□ Audiencia: Declarada, prerrequisitos listados, complejidad matcheada
□ Frescura: Fecha de actualización presente, contenido coincide con estado actual
□ Compat con Agentes: AGENTS.md actual, sin conflictos de instrucción
□ Bilingüe ES/PT: Variantes completas si languages incluye ambos
```

---

## Integración con Scripts y Templates Entregados

Este agente maestro DOC-AGENTIC integra los siguientes componentes entregados:

### Scripts de Validación
- `doc_agentic.py` — Suite completa de validación con 7 gates, CLI, scaffolding
- `validate-docs.sh` — Script bash ligero para pipelines CI/CD
- `generate_docs.py` — Renderizador de templates Jinja2 con soporte JSON/YAML

### Templates Jinja2 (16 archivos)
- 9 templates principales: README, API, tutorial, how-to, architecture, ADR, deployment, changelog, contributing, agents
- 5 templates EventCatalog: domain, service, event, flow, ubiquitous-language
- 2 partials reutilizables: frontmatter, related-links
- 1 archivo de datos de ejemplo: `project-data.json`

### Comandos de Integración
```bash
# Validar documentación con suite Python
python docs/framework/doc_agentic.py validate --all

# Validar con script bash ligero (CI/CD)
bash docs/framework/validate-docs.sh

# Generar documentación desde template
python docs/framework/generate_docs.py --template README --data project.json --output docs/

# Generar variantes bilingües
python docs/framework/generate_docs.py --template README --data project.json --languages es,pt --output docs/
```

---

> **DOC-AGENTIC v2.0.0 para MANTIS**
> Construido sobre el principio de que la documentación es la interfaz entre la intención humana y la ejecución de la máquina.
> 
> Framework diseñado para orquestación multi-agente con supervisión humana, soporte bilingüe ES/PT, e integración con GOVERNANCE-ORCHESTRATOR.md.
> 
> Generado desde análisis de 12 dominios de skill documental + scripts/templates entregados.
> Listo para integración con configuraciones-master-agent de 05-CONFIGURATIONS/.
```
