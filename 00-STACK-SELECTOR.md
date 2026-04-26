---
canonical_path: "/00-STACK-SELECTOR.md"
artifact_id: stack-selector-canonical
version: "1.0.0"
artifact_type: governance_oracle
audience: ["human_developers", "agentic_assistants", "newcomers"]
ai_optimized: true
llm_oriental_friendly: true
wikilinks_enabled: true
constraints_mapped: ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8"]
vector_constraints_mapped: ["V1", "V2", "V3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 00-STACK-SELECTOR.md --mode headless --json"
tier: 3
immutable: true
requires_human_approval_for_changes: true
related_files:
  - "[[PROJECT_TREE.md]]"
  - "[[IA-QUICKSTART.md]]"
  - "[[AI-NAVIGATION-CONTRACT.md]]"
  - "[[GOVERNANCE-ORCHESTRATOR.md]]"
  - "[[05-CONFIGURATIONS/validation/norms-matrix.json]]"
  - "[[01-RULES/harness-norms-v3.0.md]]"
  - "[[06-PROGRAMMING/00-INDEX.md]]"
checksum_sha256: "PENDING_GENERATION"
---

# 📄 00-STACK-SELECTOR.md – MOTOR DE DECISIÓN CANÓNICO

> **Nota para lectores nuevos en desarrollo:** Este documento está diseñado con comentarios educativos (`<!-- como este -->`) y explicaciones paso a paso. Si eres principiante, lee las secciones en orden. Si eres experto, salta a la matriz JSON al final.
 
 
# 🧭 STACK SELECTOR: Motor de Decisión para Desarrollo Colaborativo Humano+IA

<!-- 
【PARA PRINCIPIANTES】¿Qué es este archivo?
Este documento es el "cerebro" que le dice a cualquier IA (Qwen, DeepSeek, MiniMax, Claude, etc.) 
qué lenguaje, framework y estructura usar para cada tarea en el proyecto MANTIS AGENTIC.

No es código. Es un contrato de gobernanza que previene errores antes de que ocurran.
-->

## 1. 🎯 PROPÓSITO (Explicado para humanos)

<!-- 
【EDUCATIVO】Imagina que eres un nuevo desarrollador. 
Llegas al proyecto y ves 7 lenguajes diferentes (Go, Python, Bash, SQL, TypeScript, YAML, pgvector). 
¿Cómo sabes cuál usar para tu tarea?

RESPUESTA: Consultas este archivo. Él te guía paso a paso.
-->

Este archivo resuelve **tres preguntas críticas** antes de generar cualquier código:

| Pregunta | Por qué importa | Cómo se responde aquí |
|----------|----------------|----------------------|
| **¿En qué modo estoy trabajando?** (Interno/Externo + Nivel de autonomía) | Define cuánta libertad tiene la IA y qué validaciones aplicar | Sección 2: Matriz de 6 modos (A1-B3) |
| **¿Dónde debe vivir el artefacto?** (Ruta canónica) | La ubicación dicta el lenguaje permitido (LANGUAGE LOCK) | Sección 3: Mapa ruta→lenguaje desde `[[PROJECT_TREE.md]]` |
| **¿Qué normas debo aplicar?** (C1-C8, V1-V3) | Garantiza seguridad, multi-tenancy y calidad automática | Sección 4: Mapeo desde `[[05-CONFIGURATIONS/validation/norms-matrix.json]]` |

> 🔐 **Regla de Oro para IA y humanos**: Si una combinación ruta+lenguaje+constraint no está explícita en este documento, **NO EXISTE**. No inventes. Detén la ejecución y solicita aclaración.

---

## 2. 🔄 MATRIZ DE MODOS OPERATIVOS (A1-B3)

<!-- 
【EDUCATIVO】El sistema opera en 6 modos. 
Cada modo combina: 
- CONTEXTO: ¿Es para el proyecto interno (A) o para un cliente (B)?
- AUTONOMÍA: ¿La IA asiste (1), genera código (2) o despliega automático (3)?

Esto no es opcional. Cada modo tiene reglas de validación diferentes.
-->

```mermaid
graph TD
    A[Solicitud] --> B{¿Contexto?}
    B -->|Interno (proyecto)| C[Modos A1/A2/A3]
    B -->|Externo (cliente)| D[Modos B1/B2/B3]
    
    C --> E{¿Autonomía?}
    D --> F{¿Autonomía?}
    
    E -->|Asistido| A1[A1: Tier 1 - Revisión humana]
    E -->|Auto-gen| A2[A2: Tier 2 - Merge automático]
    E -->|Auto-deploy| A3[A3: Tier 3 - ZIP desplegable]
    
    F -->|Asistido| B1[B1: Tier 1 - Propuesta cliente]
    F -->|Auto-gen| B2[B2: Tier 2 - Código integrable]
    F -->|Auto-deploy| B3[B3: Tier 3 - Paquete producción]
```

### 2.1 Tabla de Decisión por Modo

<!-- 
【PARA IA】Esta tabla es ejecutable. 
Cada fila define: modo, carpeta destino, lenguaje permitido, constraints y formato de entrega.
-->

| Modo | Carpeta Destino (desde `[[PROJECT_TREE.md]]`) | Lenguaje Primario | Framework / Herramienta | Constraints Aplicables | Formato de Entrega |
|------|-----------------------------------------------|-------------------|------------------------|----------------------|-------------------|
| **A1, B1** | `00-CONTEXT/`, `01-RULES/`, `02-SKILLS/*/` | Markdown + YAML frontmatter | `yamllint`, `validate-frontmatter.sh` | C5 (frontmatter), C8 (si menciona logging) | Pantalla / Editor (Tier 1) |
| **A1, B1** | `04-WORKFLOWS/diagrams/` | Mermaid (en Markdown) | - | C5 | Pantalla / Editor |
| **A2, B2** | `05-CONFIGURATIONS/scripts/` | Bash | `shellcheck`, `jq` | C1, C2, C3, C4, C5, C6, C7, C8 | Código fuente + validation_command |
| **A2, B2** | `06-PROGRAMMING/bash/` | Bash | Patrones de `bash/00-INDEX.md` | C1-C8 | Código fuente + ejemplos ✅/❌/🔧 |
| **A2, B2** | `06-PROGRAMMING/python/` | Python | LangChain, FastAPI, Pydantic | C1-C8 | Código fuente + type hints |
| **A2, B2** | `06-PROGRAMMING/javascript/` | TypeScript | Node.js, Express, n8n webhooks | C1-C8 | Código fuente + ESLint config |
| **A2, B2** | `06-PROGRAMMING/sql/` | SQL (genérico) | PostgreSQL, MySQL | C4 (tenant_id), C5 (hashes) | Queries con RLS + tenant enforcement |
| **A2, B2** | `02-SKILLS/BASE DE DATOS-RAG/` | SQL + pgvector | PostgreSQL + pgvector | C4 (mandatory) + V1-V3 (contextual) | Queries vectoriales con tenant isolation |
| **A3, B3** | `06-PROGRAMMING/go/` | **Go** (prioritario) | Gin, Cobra, Viper | C1-C8 + LANGUAGE LOCK (cero pgvector) | Binario estático + Dockerfile + manifest |
| **A3, B3** | `05-CONFIGURATIONS/docker-compose/` | YAML | Docker Compose v3.8+ | C1-C8 (todas mandatory) | docker-compose.yml + healthcheck + ZIP |
| **A3, B3** | `05-CONFIGURATIONS/terraform/modules/` | HCL (Terraform) | Terraform 1.5+ | C1-C8 + sensitive=true | Módulo con validation blocks + outputs |
| **A3, B3** | `deploy/` (nueva) | Bash + YAML + Terraform | Scripts de orquestación | C1-C8 + checksums SHA256 | ZIP con manifest.json + deploy.sh + rollback.sh |

> ⚠️ **LANGUAGE LOCK CRÍTICO**: 
> - `06-PROGRAMMING/go/` → **PROHIBIDO** usar operadores pgvector (`<->`, `<=>`, `<#>`, `vector(n)`, `USING hnsw/ivfflat`). 
> - `06-PROGRAMMING/sql/` → **PROHIBIDO** usar operadores pgvector. Solo SQL estándar + C4.
> - `06-PROGRAMMING/postgresql-pgvector/` → **ÚNICO** lugar permitido para V1-V3. Requiere `artifact_type: skill_pgvector`.

---

## 3. 🗺️ MAPA DE RUTAS CANÓNICAS → LENGUAJE

<!-- 
【EDUCATIVO】La estructura del repositorio ES la decisión. 
No elijas lenguaje primero. Primero identifica DÓNDE va el archivo. 
La carpeta te dice QUÉ lenguaje usar.

Ejemplo: Si tu tarea es "script de backup", PROJECT_TREE.md te dice que va en 05-CONFIGURATIONS/scripts/. 
Esa carpeta → Bash. Fin de la discusión.
-->

### 3.1 Tabla de Enrutamiento por Carpeta

| Carpeta Canónica | Lenguaje Obligatorio | Extensión | Por qué esta decisión |
|-----------------|---------------------|-----------|----------------------|
| `00-CONTEXT/` | Markdown | `.md` | Documentación base, sin ejecución |
| `01-RULES/` | Markdown | `.md` | Normas canónicas, legibles por humanos |
| `02-SKILLS/AI/` | Markdown + ejemplos de código | `.md` | Patrones de integración, no código ejecutable |
| `02-SKILLS/INFRAESTRUCTURA/` | Markdown + snippets Bash/YAML | `.md` | Guías de infra, código en ejemplos |
| `02-SKILLS/BASE DE DATOS-RAG/` | Markdown + SQL inline | `.md` | Documentación de queries, SQL en bloques |
| `03-AGENTS/*/` | Markdown + JSON/Python snippets | `.md` | Definiciones de agentes, lógica en ejemplos |
| `04-WORKFLOWS/n8n/` | JSON (n8n export) | `.json` | Workflows ejecutables, validados por schema |
| `05-CONFIGURATIONS/scripts/` | **Bash** | `.sh` | Scripts operativos, portables, sin dependencias |
| `05-CONFIGURATIONS/docker-compose/` | **YAML** | `.yml` | Configuración de contenedores, estándar Docker |
| `05-CONFIGURATIONS/terraform/modules/` | **HCL (Terraform)** | `.tf` | Infraestructura como código, idempotente |
| `06-PROGRAMMING/bash/` | **Bash** | `.go.md` (patrones documentados) | Patrones reutilizables para scripts |
| `06-PROGRAMMING/python/` | **Python** | `.md` (patrones documentados) | Patrones para IA, APIs, procesamiento |
| `06-PROGRAMMING/javascript/` | **TypeScript** | `.md` (patrones documentados) | Patrones para webhooks, n8n, frontend |
| `06-PROGRAMMING/sql/` | **SQL estándar** | `.md` (patrones documentados) | Queries genéricas, sin extensiones vectoriales |
| `06-PROGRAMMING/postgresql-pgvector/` | **SQL + pgvector** | `.md` (patrones documentados) | ÚNICO lugar para búsqueda vectorial |
| `06-PROGRAMMING/go/` | **Go** | `.go.md` (patrones documentados) | Microservicios, alta concurrencia, binarios estáticos |
| `06-PROGRAMMING/yaml-json-schema/` | **YAML + JSON Schema** | `.md` (patrones documentados) | Validación estructural de configuraciones |

> 🔍 **Cómo usar esta tabla**: 
> 1. Identifica la función de tu tarea (ej: "script de backup")
> 2. Busca en `[[PROJECT_TREE.md]]` la carpeta canónica (ej: `05-CONFIGURATIONS/scripts/`)
> 3. Esta tabla te dice: Bash + `.sh`
> 4. Carga los patrones desde `06-PROGRAMMING/bash/00-INDEX.md`
> 5. Genera aplicando constraints C1-C8 según `norms-matrix.json`

---

## 4. 🛡️ APLICACIÓN DE NORMAS (C1-C8 + V1-V3)

<!-- 
【PARA PRINCIPIANTES】Las constraints son reglas de calidad. 
C1-C8 son obligatorias en casi todo. 
V1-V3 son especiales: solo aplican si trabajas con búsqueda vectorial (pgvector).

No las memorices. Este documento y norms-matrix.json las aplican automáticamente.
-->

### 4.1 Resumen Ejecutivo de Constraints

| Constraint | Nombre | ¿Cuándo aplica? | Ejemplo de cumplimiento |
|-----------|--------|----------------|------------------------|
| **C1** | Límites de recursos | Scripts, servicios, containers | `mem_limit: 512M`, `timeout: 30s` |
| **C2** | Concurrencia/CPU | Servicios concurrentes | `cpus: 0.5`, `pids_limit: 100` |
| **C3** | Zero Hardcode Secrets | TODO con datos sensibles | `${DB_PASS:?missing}`, `sensitive = true` |
| **C4** | Tenant Isolation | Cualquier cosa multi-usuario | `WHERE tenant_id = $1`, labels con tenant |
| **C5** | Contrato Estructural | Todos los artefactos | Frontmatter YAML válido, schema JSON |
| **C6** | Cloud-Only Inference | Integraciones con LLMs | `https://api.openrouter.ai/v1` (no localhost:11434) |
| **C7** | Resiliencia | Servicios, scripts críticos | `retry: 3`, `healthcheck:`, `rollback.sh` |
| **C8** | Observabilidad | Servicios, pipelines | `logging: json`, `trace_id: ${TRACE_ID}` |
| **V1** | Vector Dimension Declaration | **Solo** pgvector | `vector(1536)`, comentario con modelo de embedding |
| **V2** | Distance Metric Explicit | **Solo** pgvector | `<=>` documentado como "cosine distance" |
| **V3** | Index-Type Justified | **Solo** pgvector | `USING hnsw WITH (m=16, ef_construction=100)` + justificación |

### 4.2 Matriz de Aplicación por Carpeta (Resumen de norms-matrix.json)

<!-- 
【PARA IA】Esta es la fuente de verdad para validación. 
No inventes intensidades. Usa exactamente lo que dice norms-matrix.json.
-->

| Carpeta | C3 (Secrets) | C4 (Tenant) | V1-V3 (Vector) | Validadores Activos |
|---------|-------------|-------------|---------------|-------------------|
| `00-CONTEXT/` | ⚪ | ⚪ | ⚪ (hard block) | `check-wikilinks.sh` |
| `01-RULES/` | 🟢 | 🟢 | ⚪ (hard block) | `verify-constraints.sh`, `audit-secrets.sh` |
| `02-SKILLS/AI/` | 🟢 | ⚪ | ⚪ (hard block) | `audit-secrets.sh`, `validate-frontmatter.sh` |
| `02-SKILLS/BASE DE DATOS-RAG/` | 🔴 | 🔴 | 🟡 (contextual) | `check-rls.sh`, `schema-validator.py` |
| `05-CONFIGURATIONS/scripts/` | 🔴 | 🔴 | ⚪ (hard block) | `shellcheck`, `audit-secrets.sh` |
| `06-PROGRAMMING/go/` | 🔴 | 🔴 | ⚪ (hard block + LANGUAGE LOCK) | `gofmt`, `govulncheck`, `verify-constraints.sh` |
| `06-PROGRAMMING/postgresql-pgvector/` | 🔴 | 🔴 | 🔴 (mandatory si usa pgvector) | `verify-constraints.sh --check-vector-*` |

*Legenda*: 🔴 = mandatory (bloqueo si falla), 🟢 = applicable (advertencia), 🟡 = contextual (solo si el contenido lo requiere), ⚪ = not_applicable

---

## 5. 🧭 PROTOCOLO DE NAVEGACIÓN PARA IA (PASO A PASO)

<!-- 
【EDUCATIVO】Este es el flujo que DEBE seguir cualquier IA antes de generar código. 
Es determinista: mismos inputs → mismos outputs. 
Si algo no está claro, DETENER y preguntar.
-->

```
┌─────────────────────────────────────────────────────────┐
│ PASO 0: CONFIRMACIÓN DE MODO (GATE HUMANO)              │
├─────────────────────────────────────────────────────────┤
│ Si el humano no especificó modo (A1/A2/A3/B1/B2/B3):    │
│ 1. Mostrar menú de 6 opciones con descripciones claras  │
│ 2. Esperar respuesta explícita (ej: "B2")               │
│ 3. Si timeout (60s) → fallback a A1 con AUDIT_FLAG      │
│ 4. Registrar: mode_selected=<CÓDIGO>, prompt_hash=<SHA> │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ PASO 1: CARGA DE CONTEXTO CANÓNICO                      │
├─────────────────────────────────────────────────────────┤
│ Leer en orden estricto:                                  │
│ 1. [[PROJECT_TREE.md]] → resolver ruta destino          │
│ 2. [[00-STACK-SELECTOR]] (este archivo) → lenguaje      │
│ 3. [[05-CONFIGURATIONS/validation/norms-matrix.json]] → constraints │
│ 4. [[GOVERNANCE-ORCHESTRATOR.md]] → tier y validación   │
│ Si algún archivo no está disponible → NOTIFICAR y DETENER │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ PASO 2: VALIDACIÓN PRE-GENERACIÓN                       │
├─────────────────────────────────────────────────────────┤
│ Verificar:                                               │
│ • ¿La ruta destino existe en PROJECT_TREE.md?           │
│ • ¿El lenguaje asignado coincide con LANGUAGE LOCK?     │
│ • ¿Las constraints declaradas ⊆ norms-matrix[carpeta]?  │
│ Si NO → Error estructurado: "blocking_issue: X"         │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ PASO 3: GENERACIÓN CON PATRONES                         │
├─────────────────────────────────────────────────────────┤
│ 1. Cargar plantilla desde 05-CONFIGURATIONS/templates/  │
│ 2. Aplicar frontmatter canónico con:                    │
│    • canonical_path exacto                              │
│    • constraints_mapped según norms-matrix              │
│    • validation_command ejecutable                      │
│ 3. Generar cuerpo con ≥10 ejemplos ✅/❌/🔧 (Tier 2-3)  │
│ 4. Incluir comentarios educativos si artifact_type lo permite │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ PASO 4: VALIDACIÓN POST-GENERACIÓN                      │
├─────────────────────────────────────────────────────────┤
│ Ejecutar:                                               │
│   bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \ │
│     --file <ruta> --mode headless --json                │
│ Esperar:                                                │
│   • score >= 30                                         │
│   • blocking_issues == []                               │
│   • language_lock_violations == 0                       │
│ Si falla → Iterar corrección (máx 3 intentos)           │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ PASO 5: ENTREGA SEGÚN TIER                              │
├─────────────────────────────────────────────────────────┤
│ Tier 1 (A1/B1): Pantalla + nota "Requiere revisión humana" │
│ Tier 2 (A2/B2): Código + validation_command + checksum  │
│ Tier 3 (A3/B3): ZIP con manifest.json + deploy.sh + rollback.sh │
└─────────────────────────────────────────────────────────┘
```

> 💡 **Consejo para principiantes**: Si te pierdes en algún paso, vuelve al inicio. Este protocolo está diseñado para ser repetible y auditable.

---

## 6. 🚫 ANTI-PATRONES (DECISIONES PROHIBIDAS)

<!-- 
【EDUCATIVO】Estos errores son comunes en principiantes. 
Evítalos desde el inicio para ahorrar tiempo de depuración.
-->

| Anti-patrón | Por qué está prohibido | Alternativa correcta |
|------------|----------------------|---------------------|
| **Elegir lenguaje antes que ruta** | Viola LANGUAGE LOCK, genera inconsistencias | Primero ruta (PROJECT_TREE.md) → luego lenguaje (esta tabla) |
| **Usar Bash para orquestadores >200 líneas** | Inmantenible, sin tests, frágil | Go para lógica compleja, Bash solo para glue scripts |
| **Hardcodear `tenant_id` o secrets** | Viola C3/C4, fuga de datos entre clientes | `${VAR:?missing}`, variables de entorno, secret managers |
| **Aplicar V1-V3 en carpetas no-pgvector** | Violación crítica de LANGUAGE LOCK | V1-V3 solo en `06-PROGRAMMING/postgresql-pgvector/` |
| **Omitir frontmatter o validation_command** | Rompe validación automática, Tier 1 imposible | Siempre incluir frontmatter canónico + command ejecutable |
| **Generar sin confirmar modo (A1-B3)** | Deriva de gobernanza, validación inconsistente | Gate de modo obligatorio (Paso 0 del protocolo) |
| **Inventar constraints no mapeadas** | Falsa sensación de seguridad, auditoría imposible | Solo usar C1-C8 y V1-V3 definidas en norms-matrix.json |

---

## 7. 📚 GLOSARIO PARA PRINCIPIANTES

<!-- 
【EDUCATIVO】Términos técnicos explicados en lenguaje simple.
-->

| Término | Significado simple | Ejemplo |
|---------|-------------------|---------|
| **Canonical Path** | La ruta "oficial" donde debe vivir un archivo en el proyecto | `06-PROGRAMMING/go/orchestrator-engine.go.md` |
| **Frontmatter** | Metadatos al inicio de un archivo Markdown (entre `---`) | `version: "1.0.0"`, `constraints_mapped: ["C1","C3"]` |
| **LANGUAGE LOCK** | Regla que prohíbe ciertos operadores en ciertas carpetas | No usar `<->` en `go/`, solo en `postgresql-pgvector/` |
| **Tenant Isolation (C4)** | Aislar datos de cada cliente para que no se mezclen | `WHERE tenant_id = $1` en cada query |
| **Tier 1/2/3** | Niveles de madurez: 1=borrador, 2=código listo, 3=desplegable | Tier 3 incluye healthcheck, rollback, checksums |
| **Validation Command** | Comando que cualquiera puede ejecutar para verificar el artefacto | `bash orchestrator-engine.sh --file mi-archivo.md --json` |
| **Wikilink** | Enlace interno al proyecto con doble corchete | `[[PROJECT_TREE.md]]` se resuelve a la ruta real |
| **Constraint** | Regla de calidad que debe cumplirse | C3: "Nunca escribas contraseñas en el código" |

---

## 8. 🔗 REFERENCIAS CANÓNICAS (WIKILINKS)

<!-- 
【PARA IA】Estos enlaces deben resolverse usando PROJECT_TREE.md. 
No uses rutas relativas. Usa siempre la forma canónica [[RUTA]].
-->

- `[[PROJECT_TREE.md]]` → Mapa maestro de rutas del repositorio
- `[[IA-QUICKSTART.md]]` → Punto de entrada para IAs, define modos A1-B3
- `[[AI-NAVIGATION-CONTRACT.md]]` → Reglas de interacción y navegación
- `[[GOVERNANCE-ORCHESTRATOR.md]]` → Motor de validación y certificación por Tiers
- `[[05-CONFIGURATIONS/validation/norms-matrix.json]]` → Matriz de aplicación de constraints por carpeta
- `[[01-RULES/harness-norms-v3.0.md]]` → Definición textual de C1-C8
- `[[01-RULES/language-lock-protocol.md]]` → Reglas de exclusión de operadores por lenguaje
- `[[06-PROGRAMMING/00-INDEX.md]]` → Índice agregador de patrones por lenguaje
- `[[05-CONFIGURATIONS/templates/skill-template.md]]` → Plantilla base para nuevos artefactos
- `[[SDD-COLLABORATIVE-GENERATION.md]]` → Especificación de formato de artefactos

---

## 9. 🧪 SANDBOX DE PRUEBA (OPCIONAL)

<!-- 
【PARA DESARROLLADORES】Pega esta sección en un chat nuevo para validar que la IA sigue el protocolo sin contexto previo.
-->

```
【TEST MODE: STACK-SELECTOR VALIDATION】
Prompt de prueba: "Generar script de interconexión de VPS para cliente agrícola"

Respuesta esperada de la IA:
1. 【GATE MODO】Solicitar selección: [A1]...[B3]
2. Si humano responde "B3":
   - Cargar PROJECT_TREE.md → ruta: deploy/vps-interconnect/
   - Consultar STACK-SELECTOR → lenguaje: Bash + YAML
   - Cargar norms-matrix.json → constraints: C3🔴, C4🔴, C7🟢
   - Aplicar LANGUAGE LOCK → Bash: cero pgvector
3. Generar artefacto con:
   - Frontmatter: canonical_path, constraints_mapped, validation_command
   - Cuerpo: script Bash con ${VAR:?missing}, tenant_id en logs, timeout en SSH
   - ≥10 ejemplos ✅/❌/🔧
   - Bloque de validación: orchestrator-engine.sh --file ...
4. Entregar: ZIP simulado con manifest.json + deploy.sh + README-DEPLOY.md

Si la IA omite el Paso 1 o usa lenguaje incorrecto → FALLA DE GOBERNANZA.
```

---

## 10. 📦 METADATOS DE EXPANSIÓN (PARA FUTURAS VERSIONES)

<!-- 
【PARA MANTENEDORES】Nuevas secciones deben seguir este formato para no romper compatibilidad.
-->

```json
{
  "expansion_registry": {
    "modes": {
      "current": ["A1", "A2", "A3", "B1", "B2", "B3"],
      "extensible": true,
      "schema": "enum[A1..B3]",
      "addition_requires": ["IA-QUICKSTART.md update", "GOVERNANCE-ORCHESTRATOR.md sync"]
    },
    "languages": {
      "current": ["bash", "python", "javascript", "sql", "postgresql-pgvector", "go", "yaml-json-schema"],
      "extensible": true,
      "addition_requires": ["PROJECT_TREE.md update", "norms-matrix.json extension", "LANGUAGE LOCK definition"]
    },
    "constraints": {
      "current_c": ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8"],
      "current_v": ["V1", "V2", "V3"],
      "extensible": false,
      "change_requires": ["harness-norms-v3.0.md update", "orchestrator-engine.sh extension", "human approval"]
    }
  },
  "compatibility_rule": "Nuevas secciones deben usar formato ## 【N】<TÍTULO> y declarar EXPANSION_POINT en comentario HTML. La IA debe ignorar secciones desconocidas sin fallar."
}
```

---

<!-- 
═══════════════════════════════════════════════════════════
🤖 SECCIÓN PARA IA: ÁRBOL DE DECISIÓN JSON ENRIQUECIDO
═══════════════════════════════════════════════════════════
Esta sección contiene metadatos estructurados para consumo automático por agentes de IA.
No está diseñada para lectura humana directa. Los humanos deben usar las secciones 1-10.

Formato: JSON válido, con comentarios explicativos en claves "doc_*".
Prioridad de ejecución: Las normas se aplican en el orden definido en "norm_execution_order".
Dependencias: Cada nodo declara sus archivos requeridos y sus efectos colaterales.
═══════════════════════════════════════════════════════════
-->

```json
{
  "stack_decision_tree": {
    "version": "1.0.0",
    "canonical_path": "/00-STACK-SELECTOR.md",
    "artifact_type": "governance_oracle",
    "llm_optimizations": {
      "oriental_models_friendly": true,
      "delimiters_used": ["【】", "┌─┐", "▼", "✅/❌/🔧"],
      "numbered_sequences": true,
      "stop_conditions_explicit": true,
      "response_format_examples": true
    },
    "modes": {
      "A1": {
        "context": "internal",
        "autonomy": "assisted",
        "tier": 1,
        "delivery_format": "screen_editor",
        "validation_profile": "tier1-doc",
        "validation_command_template": "orchestrator-engine.sh --file {path} --checks C5,C6 --mode headless --json",
        "human_approval_required": true,
        "auto_merge_allowed": false,
        "doc_description": "Documentación interna, planos, configuración. Revisión humana obligatoria."
      },
      "A2": {
        "context": "internal",
        "autonomy": "auto_generation",
        "tier": 2,
        "delivery_format": "code_block_with_validation",
        "validation_profile": "tier2-code",
        "validation_command_template": "orchestrator-engine.sh --file {path} --checks C1-C8 --lint --mode headless --json",
        "human_approval_required": false,
        "auto_merge_allowed": true,
        "ci_gate_required": true,
        "doc_description": "Código validable para el proyecto interno. Merge automático tras gate CI."
      },
      "A3": {
        "context": "internal",
        "autonomy": "auto_deploy",
        "tier": 3,
        "delivery_format": "zip_with_manifest",
        "validation_profile": "tier3-deploy",
        "validation_command_template": "orchestrator-engine.sh --file {path} --checks C1-C8 --bundle --checksum --mode headless --json",
        "human_approval_required": false,
        "auto_merge_allowed": true,
        "auto_deploy_allowed": true,
        "requires_packager": true,
        "doc_description": "Binarios, Docker, CI/CD listo para despliegue interno autónomo."
      },
      "B1": {
        "context": "external",
        "autonomy": "assisted",
        "tier": 1,
        "delivery_format": "screen_editor",
        "validation_profile": "tier1-doc",
        "validation_command_template": "orchestrator-engine.sh --file {path} --checks C5,C6 --mode headless --json",
        "human_approval_required": true,
        "client_customization_allowed": true,
        "doc_description": "Propuestas, esquemas para cliente. El humano es responsable final de la entrega."
      },
      "B2": {
        "context": "external",
        "autonomy": "auto_generation",
        "tier": 2,
        "delivery_format": "integrable_code",
        "validation_profile": "tier2-code",
        "validation_command_template": "orchestrator-engine.sh --file {path} --checks C1-C8 --lint --mode headless --json",
        "human_approval_required": false,
        "client_integration_ready": true,
        "doc_description": "Código fuente listo para que el cliente lo integre en su entorno."
      },
      "B3": {
        "context": "external",
        "autonomy": "auto_deploy",
        "tier": 3,
        "delivery_format": "production_zip",
        "validation_profile": "tier3-deploy",
        "validation_command_template": "orchestrator-engine.sh --file {path} --checks C1-C8 --bundle --checksum --mode headless --json",
        "human_approval_required": false,
        "client_deploy_ready": true,
        "requires_packager": true,
        "doc_description": "ZIP completo con manifiesto, scripts de despliegue y rollback, listo para producción del cliente."
      }
    },
    "routing_rules": [
      {
        "condition": "file_path starts_with '00-CONTEXT/' OR '01-RULES/'",
        "language": "markdown",
        "extension": ".md",
        "primary_stack": "documentation",
        "constraints_applicable": ["C5"],
        "constraints_mandatory": [],
        "language_lock": {
          "deny_operators": [],
          "deny_constraints": ["V1", "V2", "V3"],
          "hard_block_violation": true
        },
        "dependencies": ["PROJECT_TREE.md", "harness-norms-v3.0.md"],
        "side_effects": ["update_wikilinks_index"],
        "priority": 1,
        "doc_description": "Documentación base y normas. Solo requiere frontmatter válido (C5)."
      },
      {
        "condition": "file_path contains '06-PROGRAMMING/go/'",
        "language": "go",
        "extension": ".go.md",
        "primary_stack": "microservices",
        "constraints_applicable": ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8"],
        "constraints_mandatory": ["C3", "C4", "C5"],
        "language_lock": {
          "deny_operators": ["<->", "<=>", "<#", "vector(n)", "USING hnsw", "USING ivfflat"],
          "deny_constraints": ["V1", "V2", "V3"],
          "hard_block_violation": true,
          "validator": "verify-constraints.sh --check-language-lock --dir 06-PROGRAMMING/go/"
        },
        "dependencies": ["06-PROGRAMMING/go/00-INDEX.md", "norms-matrix.json"],
        "side_effects": ["generate_binary_stub", "update_go_index"],
        "priority": 10,
        "doc_description": "Microservicios en Go. LANGUAGE LOCK estricto: cero operadores pgvector."
      },
      {
        "condition": "file_path contains '06-PROGRAMMING/postgresql-pgvector/'",
        "language": "sql_pgvector",
        "extension": ".pgvector.md",
        "primary_stack": "vector_search",
        "constraints_applicable": ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "V1", "V2", "V3"],
        "constraints_mandatory": ["C3", "C4", "V1", "V3"],
        "language_lock": {
          "require_artifact_type": "skill_pgvector",
          "require_vector_declaration": true,
          "validator": "verify-constraints.sh --check-vector-dims --check-vector-index"
        },
        "dependencies": ["06-PROGRAMMING/postgresql-pgvector/00-INDEX.md", "norms-matrix.json"],
        "side_effects": ["update_vector_schema_registry"],
        "priority": 10,
        "doc_description": "ÚNICO lugar para búsqueda vectorial. Requiere declaración explícita de dimensiones y justificación de índices."
      },
      {
        "condition": "file_path contains '05-CONFIGURATIONS/docker-compose/'",
        "language": "yaml",
        "extension": ".yml",
        "primary_stack": "container_orchestration",
        "constraints_applicable": ["C1", "C2", "C3", "C4", "C5", "C7", "C8"],
        "constraints_mandatory": ["C1", "C2", "C3", "C4", "C7", "C8"],
        "language_lock": {
          "deny_operators": [],
          "deny_constraints": ["V1", "V2", "V3"],
          "hard_block_violation": true
        },
        "dependencies": ["05-CONFIGURATIONS/validation/norms-matrix.json"],
        "side_effects": ["generate_healthcheck_stub", "update_deploy_manifest"],
        "priority": 9,
        "doc_description": "Configuración de contenedores. Todas las constraints de infra son mandatory."
      }
    ],
    "norm_execution_order": {
      "description": "Orden de aplicación de constraints durante validación. Críticas primero para fail-fast.",
      "sequence": [
        {"constraint": "C3", "reason": "Zero Hardcode Secrets - bloqueo crítico inmediato si falla"},
        {"constraint": "C4", "reason": "Tenant Isolation - fuga de datos es inaceptable"},
        {"constraint": "C5", "reason": "Contrato estructural - sin frontmatter válido, no hay validación posible"},
        {"constraint": "C1", "reason": "Límites de recursos - previene DoS por configuración"},
        {"constraint": "C6", "reason": "Cloud-only inference - seguridad de endpoints"},
        {"constraint": "C2", "reason": "Concurrencia - estabilidad del sistema"},
        {"constraint": "C7", "reason": "Resiliencia - tolerancia a fallos"},
        {"constraint": "C8", "reason": "Observabilidad - auditabilidad post-mortem"},
        {"constraint": "V1", "reason": "Vector dimensions - solo si aplica, después de C-constraints"},
        {"constraint": "V2", "reason": "Distance metric - validación semántica de operadores"},
        {"constraint": "V3", "reason": "Index justification - optimización justificada"}
      ],
      "fail_fast_constraints": ["C3", "C4", "C5"],
      "contextual_constraints": ["C1", "C2", "C7", "C8", "V1", "V2", "V3"]
    },
    "dependency_graph": {
      "critical_infrastructure": [
        "PROJECT_TREE.md",
        "05-CONFIGURATIONS/validation/norms-matrix.json",
        "01-RULES/harness-norms-v3.0.md",
        "01-RULES/language-lock-protocol.md"
      ],
      "navigation_contracts": [
        "IA-QUICKSTART.md",
        "AI-NAVIGATION-CONTRACT.md",
        "GOVERNANCE-ORCHESTRATOR.md"
      ],
      "pattern_indices": [
        "06-PROGRAMMING/00-INDEX.md",
        "06-PROGRAMMING/go/00-INDEX.md",
        "06-PROGRAMMING/python/00-INDEX.md",
        "06-PROGRAMMING/bash/00-INDEX.md",
        "06-PROGRAMMING/sql/00-INDEX.md",
        "06-PROGRAMMING/postgresql-pgvector/00-INDEX.md",
        "06-PROGRAMMING/javascript/00-INDEX.md",
        "06-PROGRAMMING/yaml-json-schema/00-INDEX.md"
      ],
      "validation_toolchain": [
        "05-CONFIGURATIONS/validation/orchestrator-engine.sh",
        "05-CONFIGURATIONS/validation/verify-constraints.sh",
        "05-CONFIGURATIONS/validation/audit-secrets.sh",
        "05-CONFIGURATIONS/validation/check-rls.sh",
        "05-CONFIGURATIONS/validation/schema-validator.py"
      ]
    },
    "interaction_protocols": {
      "mode_confirmation_gate": {
        "trigger": "mode not specified in user prompt",
        "action": "present 6-mode menu with descriptions",
        "timeout_seconds": 60,
        "fallback_mode": "A1",
        "fallback_audit_flag": "human_timeout",
        "required_response_format": "single code: A1|A2|A3|B1|B2|B3",
        "invalid_response_action": "re-prompt with validation error",
        "audit_fields": ["mode_selected", "source:human_confirmed|human_timeout", "prompt_sha256", "timestamp"]
      },
      "missing_context_handling": {
        "trigger": "required canonical file not available in context",
        "action": "notify user with specific missing file list",
        "options": ["proceed_with_reduced_validation", "wait_for_context_sync"],
        "default": "wait_for_context_sync",
        "audit_flag": "context_sync_required"
      },
      "language_lock_violation": {
        "trigger": "detected operator/constraint not allowed in target folder",
        "action": "blocking error with specific violation details",
        "suggestion": "propose correct folder based on required operators",
        "audit_flag": "language_lock_violation"
      }
    },
    "expansion_hooks": {
      "new_mode_addition": {
        "requires_files_update": ["IA-QUICKSTART.md", "GOVERNANCE-ORCHESTRATOR.md", "norms-matrix.json"],
        "requires_schema_update": "stack-selection.schema.json",
        "requires_human_approval": true,
        "backward_compatibility": "new modes must not break existing A1-B3 flows"
      },
      "new_language_addition": {
        "requires_files_update": ["PROJECT_TREE.md", "norms-matrix.json", "06-PROGRAMMING/00-INDEX.md"],
        "requires_language_lock_definition": true,
        "requires_human_approval": true,
        "backward_compatibility": "existing LANGUAGE LOCK rules must remain unchanged"
      }
    },
    "validation_metadata": {
      "orchestrator_compatibility": ">=3.0.0-SELECTIVE",
      "schema_version": "stack-selection.v1.json",
      "checksum_algorithm": "SHA256",
      "audit_log_format": "JSON Lines with RFC3339 timestamps",
      "pii_scrubbing": "enabled for all logs (C8 compliance)"
    }
  }
}
```

```
<!-- 
═══════════════════════════════════════════════════════════
FIN DEL DOCUMENTO 00-STACK-SELECTOR.md

Resumen para humanos:
• Este archivo es el oráculo de decisión: ruta → lenguaje → constraints.
• Siempre consulta PROJECT_TREE.md primero para resolver rutas.
• El gate de modo (Paso 0) es obligatorio: sin modo explícito, no hay generación.
• LANGUAGE LOCK es inamovible: go/ no acepta pgvector, sql/ no acepta V1-V3.
• La sección JSON final es para consumo automático de IAs. Los humanos deben usar las secciones 1-10.

Próximos pasos después de crear este archivo:
1. Crear stack-selection.schema.json en 05-CONFIGURATIONS/validation/schemas/
2. Actualizar orchestrator-engine.sh para validar contra este selector
3. Actualizar IA-QUICKSTART.md para incluir el Paso 0 de confirmación de modo
4. Actualizar AI-NAVIGATION-CONTRACT.md con la Regla 0: Modo Explícito Obligatorio

Para principiantes: Si algo no queda claro, revisa el Glosario (Sección 7) 
o ejecuta el Sandbox de Prueba (Sección 9) en un chat nuevo.

✅ Validación recomendada:
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 00-STACK-SELECTOR.md \
  --mode headless \
  --json
═══════════════════════════════════════════════════════════
-->
```

---

## ✅ CHECKLIST DE VALIDACIÓN POST-GENERACIÓN

<!-- 
【PARA PRINCIPIANTES】Antes de guardar este archivo, ejecuta mentalmente (o en terminal) esta validación.
-->

```bash
# 1. Verificar que el frontmatter es YAML válido
yq eval '.canonical_path' 00-STACK-SELECTOR.md
# Esperado: "/00-STACK-SELECTOR.md"

# 2. Verificar que constraints_mapped solo contiene C1-C8 y V1-V3 válidos
yq eval '.constraints_mapped | .[]' 00-STACK-SELECTOR.md | grep -E '^C[1-8]$|^V[1-3]$'
# Esperado: 11 líneas (8 C + 3 V)

# 3. Verificar LANGUAGE LOCK en sección JSON
grep -A5 '"language_lock"' 00-STACK-SELECTOR.md | grep -q '"deny_operators"' && echo "✅ LANGUAGE LOCK presente"

# 4. Validar con orchestrator (simulación mental)
# - ¿El archivo está en raíz? → SÍ
# - ¿El lenguaje es markdown? → SÍ
# - ¿Constraints aplicables según norms-matrix.json? → C5 mandatory, C8 contextual → SÍ
# - ¿validation_command es ejecutable? → SÍ, apunta a orchestrator-engine.sh

# 5. Verificar wikilinks canónicos
grep -oE '\[\[[^]]+\]\]' 00-STACK-SELECTOR.md | sort -u
# Esperado: Lista de archivos que existen en PROJECT_TREE.md
```

**Criterio de aceptación:**  
- ✅ Frontmatter válido con `canonical_path: "/00-STACK-SELECTOR.md"`  
- ✅ `constraints_mapped` contiene solo C1-C8 y V1-V3  
- ✅ Sección JSON final es válida (puede parsearse con `jq .`)  
- ✅ Wikilinks apuntan a archivos existentes en `PROJECT_TREE.md`  
- ✅ `validation_command` es ejecutable y apunta al orchestrator correcto  

---

> 🎯 **Mensaje final para el lector humano**:  
> Este documento es tu brújula. No memorices cada regla. Confía en el protocolo:  
> **Ruta → Lenguaje → Constraints → Validación**.  
> Si sigues ese flujo, nunca generarás un artefacto fuera de norma.  
> La gobernanza no es una carga. Es la libertad de crear sin miedo a romper.  
