---
canonical_path: "/RAW_URLS_INDEX.md"
artifact_id: "raw-urls-canonical-index"
artifact_type: "remote_access_catalog"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C5", "C6"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file RAW_URLS_INDEX.md --mode headless --json"
tier: 1
immutable: true
requires_human_approval_for_changes: true
related_files:
  - "[[00-STACK-SELECTOR.md]]"
  - "[[PROJECT_TREE.md]]"
  - "[[knowledge-graph.json]]"
  - "[[05-CONFIGURATIONS/validation/norms-matrix.json]]"
checksum_sha256: "PENDING_GENERATION"
---

# 📄 RAW_URLS_INDEX.md – ÍNDICE CANÓNICO DE URLs PARA ACCESO REMOTO

> **Nota para principiantes:** Este documento es el "catálogo de acceso remoto" del proyecto. Define exactamente qué URLs raw puede consultar un agente externo (Qwen, DeepSeek, MiniMax) para sincronizar contexto sin clonar el repositorio. Si eres nuevo, lee las secciones en orden. Si eres experto, salta al JSON final.  
>  
> **Para IAs:** Este es tu índice de carga remota. **USAR URL NO LISTADA = CONTEXTO INCOMPLETO**. No inventes, no asumas, no omitas.


# 🌐 RAW_URLS_INDEX: Catálogo Canónico de URLs para Acceso Remoto de Agentes

<!-- 
【PARA PRINCIPIANTES】¿Qué es este archivo?
Este documento es el "menú de carga remota" para IAs que operan sin clonar el repositorio.
Define:
• Qué URLs raw puede consultar un agente externo (Qwen, DeepSeek, MiniMax)
• En qué orden cargarlas para construir contexto válido
• Qué metadatos acompañan cada URL (propósito, constraints, criticalidad)
• Cómo validar que la carga fue exitosa

Si eres nuevo: lee en orden. 
Si ya conoces el proyecto: usa los wikilinks para ir directo a lo que necesitas.
-->

> **Instrucción crítica para la IA:** 
> Este documento es tu índice de carga remota. 
> **USAR URL NO LISTADA = CONTEXTO INCOMPLETO**. 
> No inventes, no asumas, no omitas. Si algo no está claro, DETENER y preguntar.

---

## 【0】🎯 PROPÓSITO Y ALCANCE (Explicado para humanos)

<!-- 
【EDUCATIVO】Este documento responde: "¿Qué URLs raw debe cargar un agente remoto para operar con gobernanza completa?"
No es solo una lista. Es un protocolo de carga escalonada que:
• Previene carga de contexto incompleto o inconsistente
• Garantiza que los agentes externos respeten LANGUAGE LOCK y constraints
• Permite actualización incremental sin recargar todo el repositorio
-->

### 0.1 Protocolo de Carga Escalonada para Agentes Remotos

```
FASE 1 – GOBERNANZA CRÍTICA (Carga obligatoria inicial)
├─ 00-STACK-SELECTOR.md → Motor de decisión: ruta → lenguaje → constraints
├─ IA-QUICKSTART.md → Gate de modo A1-B3 + protocolo de interacción
├─ AI-NAVIGATION-CONTRACT.md → Reglas inamovibles + anti-patrones
├─ GOVERNANCE-ORCHESTRATOR.md → Tiers 1/2/3 + validación + entrega
├─ SDD-COLLABORATIVE-GENERATION.md → Especificación de formato de artefactos
├─ PROJECT_TREE.md → Mapa canónico de rutas del repositorio
├─ norms-matrix.json → Matriz de constraints por carpeta (machine-readable)
├─ language-lock-protocol.md → Operadores prohibidos por lenguaje
└─ knowledge-graph.json → Grafo de conocimiento para navegación inteligente

FASE 2 – TOOLCHAIN DE VALIDACIÓN (Carga para validación local)
├─ orchestrator-engine.sh → Motor principal de validación
├─ verify-constraints.sh → Validación de constraints + LANGUAGE LOCK
├─ audit-secrets.sh → Detección de secrets hardcodeados (C3)
├─ check-rls.sh → Validación de tenant isolation en SQL (C4)
├─ validate-frontmatter.sh → Verificación de frontmatter YAML (C5)
├─ check-wikilinks.sh → Validación de wikilinks canónicos (C5)
├─ schema-validator.py → Validación de JSON/YAML contra schemas
└─ packager-assisted.sh → Empaquetado de artefactos Tier 3

FASE 3 – ÍNDICES DE PATRONES (Carga bajo demanda por lenguaje)
├─ 06-PROGRAMMING/00-INDEX.md → Índice agregador maestro
├─ 06-PROGRAMMING/go/00-INDEX.md → Patrones Go (35 artifacts, LANGUAGE LOCK activo)
├─ 06-PROGRAMMING/python/00-INDEX.md → Patrones Python (24 artifacts)
├─ 06-PROGRAMMING/postgresql-pgvector/00-INDEX.md → Patrones pgvector (10 artifacts, V1-V3 obligatorios)
├─ ... (otros índices de lenguaje según necesidad)

FASE 4 – SKILLS Y CONFIGURACIÓN (Carga opcional por dominio)
├─ 02-SKILLS/AI/qwen-integration.md → Integración con Qwen (oriental-optimized)
├─ 02-SKILLS/INFRASTRUCTURA/vps-interconnection.md → Interconexión de VPS
├─ 05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml → Config Docker para VPS1
└─ ... (cargar solo skills relevantes a la tarea actual)
```

### 0.2 Reglas Inamovibles de Carga Remota

```
REGLA 0.1: FASE 1 es obligatoria antes de cualquier generación o validación.
REGLA 0.2: URLs con LANGUAGE LOCK (go/, sql/, etc.) requieren verificar language-lock-protocol.md antes de usar.
REGLA 0.3: Constraints declaradas en un artefacto DEBEN estar mapeadas en norms-matrix.json para su carpeta.
REGLA 0.4: Wikilinks en artefactos cargados DEBEN resolverse contra PROJECT_TREE.md, no contra rutas relativas.
REGLA 0.5: Si una URL retorna HTTP 404, DETENER y notificar: "URL_NOT_FOUND: {url}".
```

> 💡 **Consejo para principiantes**: No cargues todo el índice de una vez. Usa el protocolo escalonado: FASE 1 → FASE 2 → FASE 3 (bajo demanda) → FASE 4 (opcional).

---

## 【1】🔐 URLs CRÍTICAS DE GOBERNANZA (FASE 1 – Carga Obligatoria)

<!-- 
【EDUCATIVO】Estas 9 URLs son el núcleo de gobernanza. 
Sin ellas, cualquier agente opera sin contención de deriva.
-->

| URL Raw | Propósito | Constraints | Critical | Wikilink |
|---------|-----------|-------------|----------|----------|
| `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-STACK-SELECTOR.md` | Motor de decisión: ruta → lenguaje → constraints | C5, C6 | 🔐 Sí | `[[00-STACK-SELECTOR]]` |
| `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/IA-QUICKSTART.md` | Semilla de gobernanza: gate de modo A1-B3 | C1, C4, C6 | 🔐 Sí | `[[IA-QUICKSTART]]` |
| `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/AI-NAVIGATION-CONTRACT.md` | Contrato de navegación: reglas inamovibles | C1, C4, C6 | 🔐 Sí | `[[AI-NAVIGATION-CONTRACT]]` |
| `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/GOVERNANCE-ORCHESTRATOR.md` | Motor de certificación: Tiers 1/2/3 | C2, C7, C8 | 🔐 Sí | `[[GOVERNANCE-ORCHESTRATOR]]` |
| `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/SDD-COLLABORATIVE-GENERATION.md` | Especificación de formato de artefactos | C5, C6 | 🔐 Sí | `[[SDD-COLLABORATIVE-GENERATION]]` |
| `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/PROJECT_TREE.md` | Mapa canónico de rutas del repositorio | C5 | 🔐 Sí | `[[PROJECT_TREE]]` |
| `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json` | Matriz de constraints por carpeta (machine-readable) | C4, C5 | 🔐 Sí | `[[05-CONFIGURATIONS/validation/norms-matrix.json]]` |
| `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/language-lock-protocol.md` | Protocolo LANGUAGE LOCK: operadores prohibidos | C4, C5 | 🔐 Sí | `[[01-RULES/language-lock-protocol]]` |
| `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/knowledge-graph.json` | Grafo de conocimiento para navegación inteligente | C5 | 🔐 Sí | `[[knowledge-graph.json]]` |

> ⚠️ **Contención crítica**: Si alguna de estas 9 URLs retorna HTTP ≠ 200, el agente DEBE detenerse y notificar: `"GOVERNANCE_LOAD_FAILED: {url} returned {http_code}"`.

---

## 【2】🧰 TOOLCHAIN DE VALIDACIÓN (FASE 2 – Carga para Validación Local)

<!-- 
【EDUCATIVO】Estas herramientas permiten validar artefactos localmente antes de entregar.
Son esenciales para Tier 2+ y para prevenir deuda técnica.
-->

| URL Raw | Propósito | Tipo | Wikilink |
|---------|-----------|------|----------|
| `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/orchestrator-engine.sh` | Motor principal de validación y scoring | 🧰 Script Bash | `[[05-CONFIGURATIONS/validation/orchestrator-engine.sh]]` |
| `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/verify-constraints.sh` | Validar constraints C1-C8 + LANGUAGE LOCK | 🧰 Script Bash | `[[05-CONFIGURATIONS/validation/verify-constraints.sh]]` |
| `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/audit-secrets.sh` | Detectar secrets hardcodeados (C3) | 🧰 Script Bash | `[[05-CONFIGURATIONS/validation/audit-secrets.sh]]` |
| `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/check-rls.sh` | Validar tenant isolation en SQL (C4) | 🧰 Script Bash | `[[05-CONFIGURATIONS/validation/check-rls.sh]]` |
| `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/validate-frontmatter.sh` | Verificar frontmatter YAML válido (C5) | 🧰 Script Bash | `[[05-CONFIGURATIONS/validation/validate-frontmatter.sh]]` |
| `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/check-wikilinks.sh` | Validar wikilinks canónicos (C5) | 🧰 Script Bash | `[[05-CONFIGURATIONS/validation/check-wikilinks.sh]]` |
| `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schema-validator.py` | Validar JSON/YAML contra schemas | 🧰 Script Python | `[[05-CONFIGURATIONS/validation/schema-validator.py]]` |
| `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/scripts/packager-assisted.sh` | Empaquetar artefactos Tier 3 con manifest | 🧰 Script Bash | `[[05-CONFIGURATIONS/scripts/packager-assisted.sh]]` |

### 2.1 Ejemplo de Uso: Validación Remota de un Artefacto

```bash
# 1. Cargar gobernanza crítica (FASE 1)
curl -sO https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-STACK-SELECTOR.md
curl -sO https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json

# 2. Cargar toolchain (FASE 2)
curl -sO https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/orchestrator-engine.sh
chmod +x orchestrator-engine.sh

# 3. Validar artefacto localmente
bash orchestrator-engine.sh --file mi-artefacto.md --mode headless --json

# 4. Interpretar resultado
# • score >= 30 + blocking_issues == [] → ✅ Aprobado para Tier 2
# • score < 30 o blocking_issues != [] → ❌ Corregir antes de entregar
```

---

## 【3】🗂️ ÍNDICES DE PATRONES POR LENGUAJE (FASE 3 – Carga Bajo Demanda)

<!-- 
【EDUCATIVO】Estos índices permiten cargar solo los patrones relevantes al lenguaje de la tarea.
Cada índice incluye LANGUAGE LOCK rules específicas.
-->

### 3.1 Índice Agregador Maestro

| URL Raw | Propósito | Artifacts | LANGUAGE LOCK | Wikilink |
|---------|-----------|-----------|--------------|----------|
| `https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/00-INDEX.md` | Índice agregador de los 7 lenguajes | 137 artifacts | ✅ Enforcement global | `[[06-PROGRAMMING/00-INDEX]]` |

### 3.2 Índices por Lenguaje (Cargar solo el relevante)

| URL Raw | Lenguaje | Artifacts | Constraints Mandatory | LANGUAGE LOCK Rules | Wikilink |
|---------|----------|-----------|---------------------|-------------------|----------|
| `.../06-PROGRAMMING/go/00-INDEX.md` | Go | 35 | C3, C4, C5, C8 | 🔴 Deny: `<->`, `<=>`, `<#`, `vector(n)`, `USING hnsw/ivfflat`, V1-V3 | `[[06-PROGRAMMING/go/00-INDEX]]` |
| `.../06-PROGRAMMING/python/00-INDEX.md` | Python | 24 | C3, C4, C5, C8 | 🔴 Deny: V1-V3 (vectoriales) | `[[06-PROGRAMMING/python/00-INDEX]]` |
| `.../06-PROGRAMMING/bash/00-INDEX.md` | Bash | 12 | C3, C4, C5, C6 | 🔴 Deny: V1-V3 | `[[06-PROGRAMMING/bash/00-INDEX]]` |
| `.../06-PROGRAMMING/sql/00-INDEX.md` | SQL estándar | 25 | C4, C5 | 🔴 Deny: operadores pgvector, V1-V3 | `[[06-PROGRAMMING/sql/00-INDEX]]` |
| `.../06-PROGRAMMING/postgresql-pgvector/00-INDEX.md` | SQL+pgvector | 10 | C3, C4, C5, V1, V3 | 🟢 Allow: `<->`, `<=>`, `<#` con documentación V2 | `[[06-PROGRAMMING/postgresql-pgvector/00-INDEX]]` |
| `.../06-PROGRAMMING/javascript/00-INDEX.md` | TypeScript/JS | 22 | C3, C4, C5, C8 | 🔴 Deny: V1-V3 | `[[06-PROGRAMMING/javascript/00-INDEX]]` |
| `.../06-PROGRAMMING/yaml-json-schema/00-INDEX.md` | YAML+Schema | 9 | C5 | 🔴 Deny: V1-V3 | `[[06-PROGRAMMING/yaml-json-schema/00-INDEX]]` |

> 💡 **Consejo para principiantes**: No cargues todos los índices. Usa `00-STACK-SELECTOR.md` para determinar qué lenguaje necesita tu tarea, luego carga solo ese índice.

---

## 【4】📦 SKILLS Y CONFIGURACIÓN (FASE 4 – Carga Opcional por Dominio)

<!-- 
【EDUCATIVO】Estas URLs son para carga bajo demanda según el dominio de la tarea.
No son obligatorias para gobernanza básica.
-->

### 4.1 Skills de IA (Ejemplos)

| URL Raw | Dominio | Propósito | Wikilink |
|---------|---------|-----------|----------|
| `.../02-SKILLS/AI/qwen-integration.md` | IA | Integración con Qwen (oriental-optimized) | `[[02-SKILLS/AI/qwen-integration]]` |
| `.../02-SKILLS/AI/langchain-integration.md` | IA | Integración con LangChain | `[[02-SKILLS/AI/langchain-integration]]` |
| `.../02-SKILLS/BASE DE DATOS-RAG/rag-query-with-tenant-enforcement.pgvector.md` | RAG | Queries RAG con tenant isolation | `[[02-SKILLS/BASE DE DATOS-RAG/rag-query-with-tenant-enforcement]]` |

### 4.2 Configuración de Infraestructura (Ejemplos)

| URL Raw | Dominio | Propósito | Wikilink |
|---------|---------|-----------|----------|
| `.../05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml` | Infra | Config Docker para VPS1: n8n + UAZAPI | `[[05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml]]` |
| `.../02-SKILLS/INFRASTRUCTURA/vps-interconnection.md` | Infra | Interconexión segura de VPS | `[[02-SKILLS/INFRASTRUCTURA/vps-interconnection]]` |
| `.../05-CONFIGURATIONS/terraform/modules/postgres-rls/main.tf` | Infra | Módulo Terraform para PostgreSQL con RLS | `[[05-CONFIGURATIONS/terraform/modules/postgres-rls/main.tf]]` |

> ⚠️ **Regla de carga opcional**: Solo cargar skills/configuración si la tarea lo requiere explícitamente. No precargar todo el repositorio.

---

## 【5】🧭 PROTOCOLO DE CARGA REMOTA PARA IA (PASO A PASO)

<!-- 
【EDUCATIVO】Este es el flujo determinista que DEBE seguir cualquier agente remoto.
Mismos inputs → mismos outputs. Si algo no está claro, DETENER y preguntar.
-->

```
┌─────────────────────────────────────────────────────────┐
│ 【FASE 1】CARGA DE GOBERNANZA CRÍTICA (OBLIGATORIA)    │
├─────────────────────────────────────────────────────────┤
│ 1. Cargar las 9 URLs críticas de la Sección 【1】      │
│ 2. Verificar HTTP 200 para cada una                    │
│ 3. Si alguna falla → DETENER y notificar:              │
│    "GOVERNANCE_LOAD_FAILED: {url} returned {http_code}"│
│ 4. Parsear norms-matrix.json y knowledge-graph.json    │
│ 5. Inicializar LANGUAGE LOCK rules desde:              │
│    • 00-STACK-SELECTOR.md                              │
│    • language-lock-protocol.md                         │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 2】CARGA DE TOOLCHAIN (PARA VALIDACIÓN)         │
├─────────────────────────────────────────────────────────┤
│ 1. Cargar las 8 URLs de la Sección 【2】               │
│ 2. Hacer ejecutables los scripts Bash: chmod +x *.sh   │
│ 3. Verificar que schema-validator.py tiene Python 3.8+ │
│ 4. Probar orchestrator-engine.sh --help para confirmar │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 3】CARGA DE ÍNDICE DE LENGUAJE (BAJO DEMANDA)   │
├─────────────────────────────────────────────────────────┤
│ 1. Consultar 00-STACK-SELECTOR.md para determinar:     │
│    • canonical_path de la tarea                         │
│    • lenguaje permitido para esa ruta                   │
│ 2. Cargar solo el índice de ese lenguaje:              │
│    ej: 06-PROGRAMMING/go/00-INDEX.md                   │
│ 3. Extraer patterns relevantes del índice              │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 4】CARGA DE SKILLS/CONFIG (OPCIONAL)            │
├─────────────────────────────────────────────────────────┤
│ 1. Si la tarea requiere dominio específico (ej: RAG):  │
│    • Cargar skills relevantes de 02-SKILLS/            │
│    • Cargar config relevante de 05-CONFIGURATIONS/     │
│ 2. Si no hay dominio específico → saltar esta fase     │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 5】EJECUCIÓN CON GOBERNANZA ACTIVA              │
├─────────────────────────────────────────────────────────┤
│ 1. Aplicar protocolo de IA-QUICKSTART.md (Gate de modo)│
│ 2. Generar artefacto siguiendo SDD-COLLABORATIVE-...   │
│ 3. Validar con orchestrator-engine.sh --json           │
│ 4. Si Tier 3 → empaquetar con packager-assisted.sh     │
│ 5. Entregar con validation_command + checksum          │
└─────────────────────────────────────────────────────────┘
```

### 5.1 Ejemplo de Traza de Carga Remota (Agente Qwen)

```
【TRAZA DE CARGA REMOTA – AGENTE QWEN】
Tarea: "Generar webhook seguro para WhatsApp de cliente agrícola"

Fase 1 - Gobernanza crítica:
  • Cargar 9 URLs críticas → todas HTTP 200 ✅
  • Parsear norms-matrix.json → constraints por carpeta cargadas ✅
  • Inicializar LANGUAGE LOCK: typescript → deny_operators=[], deny_constraints=[V1,V2,V3] ✅

Fase 2 - Toolchain:
  • Cargar 8 scripts de validación → chmod +x aplicado ✅
  • Probar orchestrator-engine.sh --help → salida correcta ✅

Fase 3 - Índice de lenguaje:
  • Consultar 00-STACK-SELECTOR.md → tarea "webhook WhatsApp" → 06-PROGRAMMING/javascript/
  • Cargar: 06-PROGRAMMING/javascript/00-INDEX.md → 22 patterns disponibles ✅
  • Seleccionar: webhook-validation-patterns.ts.md ✅

Fase 4 - Skills/Config (opcional):
  • Tarea requiere integración WhatsApp → cargar: 02-SKILLS/COMUNICACION/whatsapp-rag-openrouter.md ✅

Fase 5 - Ejecución con gobernanza:
  • Gate de modo: humano confirma "B2" → mode_selected=B2 ✅
  • Generar artefacto con frontmatter Tier 2, ≥10 ejemplos ✅/❌/🔧 ✅
  • Validar: orchestrator-engine.sh --file ... --json → score=42, passed=true ✅
  • Entregar: código + validation_command + checksum_sha256 ✅

Resultado: ✅ Artefacto generado y validado con gobernanza completa, sin clonar repositorio.
```

---

## 【6】📚 GLOSARIO PARA PRINCIPIANTES

<!-- 
【EDUCATIVO】Términos técnicos explicados en lenguaje simple.
-->

| Término | Significado simple | Ejemplo |
|---------|-------------------|---------|
| **URL Raw** | Enlace directo al contenido de un archivo en GitHub | `https://raw.githubusercontent.com/.../main/FILE.md` |
| **Carga escalonada** | Cargar contexto en fases, no todo de una vez | FASE 1: gobernanza → FASE 2: toolchain → FASE 3: índices |
| **LANGUAGE LOCK** | Regla que prohíbe ciertos operadores en ciertos lenguajes | No usar `<->` en `go/`, solo en `postgresql-pgvector/` |
| **Constraint** | Regla de calidad que debe cumplirse | C3: "Nunca escribas contraseñas en el código" |
| **Tier 1/2/3** | Niveles de madurez: 1=borrador, 2=código listo, 3=desplegable | Tier 3 incluye healthcheck, rollback, checksums |
| **Wikilink canónico** | Enlace interno con ruta absoluta desde raíz | `[[PROJECT_TREE.md]]` (no `[[../PROJECT_TREE.md]]`) |
| **HTTP 200** | Código de respuesta que indica "archivo encontrado" | Si curl retorna 404 → archivo no existe o ruta incorrecta |
| **Machine-readable** | Formato que una IA puede parsear automáticamente | JSON, YAML con schema definido |

---

## 【7】🧪 SANDBOX DE PRUEBA (OPCIONAL)

<!-- 
【PARA DESARROLLADORES】Pega esta sección en un chat nuevo para validar que la IA sigue el protocolo sin contexto previo.
-->

```
【TEST MODE: RAW_URLS_INDEX VALIDATION】
Prompt de prueba: "Cargar contexto remoto para generar webhook TypeScript"

Respuesta esperada de la IA:
1. 【FASE 1】Cargar las 9 URLs críticas de gobernanza
   • Verificar HTTP 200 para cada una
   • Parsear norms-matrix.json y knowledge-graph.json
2. 【FASE 2】Cargar toolchain de validación
   • Hacer ejecutables scripts Bash
   • Probar orchestrator-engine.sh --help
3. 【FASE 3】Determinar lenguaje vía 00-STACK-SELECTOR.md
   • Tarea "webhook TypeScript" → 06-PROGRAMMING/javascript/
   • Cargar: 06-PROGRAMMING/javascript/00-INDEX.md
4. 【FASE 4】(Opcional) Cargar skill de WhatsApp si se requiere
5. 【FASE 5】Ejecutar con gobernanza:
   • Gate de modo → humano confirma "B2"
   • Generar con frontmatter Tier 2 + ≥10 ejemplos ✅/❌/🔧
   • Validar con orchestrator-engine.sh --json
   • Entregar con validation_command + checksum

Si la IA carga URLs no listadas, omite FASE 1, o ignora LANGUAGE LOCK → FALLA DE PROTOCOLO REMOTO.
```

---

## 【8】🔗 REFERENCIAS CANÓNICAS (WIKILINKS)

<!-- 
【PARA IA】Estos enlaces deben resolverse usando PROJECT_TREE.md. 
No uses rutas relativas. Usa siempre la forma canónica [[RUTA]].
-->

- `[[00-STACK-SELECTOR]]` → Motor de decisión de stack (ruta → lenguaje → constraints)
- `[[PROJECT_TREE]]` → Mapa maestro de rutas del repositorio
- `[[05-CONFIGURATIONS/validation/norms-matrix.json]]` → Matriz de aplicación de constraints por carpeta
- `[[01-RULES/language-lock-protocol.md]]` → Reglas de exclusión de operadores por lenguaje
- `[[GOVERNANCE-ORCHESTRATOR]]` → Tiers, validación y certificación
- `[[IA-QUICKSTART]]` → Punto de entrada para IAs, define modos A1-B3
- `[[AI-NAVIGATION-CONTRACT]]` → Reglas de interacción y navegación
- `[[knowledge-graph.json]]` → Grafo de conocimiento para navegación inteligente
- `[[06-PROGRAMMING/00-INDEX]]` → Índice agregador de patrones por lenguaje

---

## 【9】📦 METADATOS DE EXPANSIÓN (PARA FUTURAS VERSIONES)

<!-- 
【PARA MANTENEDORES】Nuevas secciones deben seguir este formato para no romper compatibilidad.
-->

```json
{
  "expansion_registry": {
    "new_governance_url": {
      "requires_files_update": [
        "RAW_URLS_INDEX.md: add URL to Section 【1】with metadata",
        "knowledge-graph.json: add node for new governance document",
        "PROJECT_TREE.md: add file entry if new critical doc",
        "Human approval required: true"
      ],
      "backward_compatibility": "new governance URLs must not break existing FASE 1 load order"
    },
    "new_language_index": {
      "requires_files_update": [
        "RAW_URLS_INDEX.md: add index URL to Section 【3.2】",
        "06-PROGRAMMING/00-INDEX.md: add reference to new language index",
        "00-STACK-SELECTOR.md: add routing rule for new language",
        "norms-matrix.json: add constraint mapping for new folder",
        "Human approval required: true"
      ],
      "backward_compatibility": "new language indices must declare LANGUAGE LOCK rules before being added"
    }
  },
  "compatibility_rule": "Nuevas URLs no deben invalidar el protocolo de carga escalonada. Cambios breaking requieren major version bump, guía de migración y aprobación humana explícita."
}
```

---

<!-- 
═══════════════════════════════════════════════════════════
🤖 SECCIÓN PARA IA: CATÁLOGO JSON ENRIQUECIDO
═══════════════════════════════════════════════════════════
Esta sección contiene metadatos estructurados para consumo automático por agentes de IA.
No está diseñada para lectura humana directa. Los humanos deben usar las secciones 【1】-【9】.

Formato: JSON válido, con comentarios explicativos en claves "doc_*".
Prioridad de carga: Las URLs se cargan en el orden definido en "load_phases".
Dependencias: Cada nodo declara sus archivos requeridos y sus efectos colaterales.
═══════════════════════════════════════════════════════════
-->

```json
{
  "raw_urls_index_metadata": {
    "version": "3.0.0-SELECTIVE",
    "canonical_path": "/RAW_URLS_INDEX.md",
    "artifact_type": "remote_access_catalog",
    "immutable": true,
    "requires_human_approval_for_changes": true,
    "total_urls": 284,
    "critical_governance_urls": 9,
    "validation_toolchain_urls": 8,
    "language_index_urls": 8,
    "llm_optimizations": {
      "oriental_models_friendly": true,
      "delimiters_used": ["【】", "┌─┐", "▼", "✅/❌/🔧"],
      "numbered_sequences": true,
      "stop_conditions_explicit": true
    }
  },
  
  "load_phases": {
    "phase_1_governance_critical": {
      "description": "Carga obligatoria inicial: núcleo de gobernanza",
      "required": true,
      "urls": [
        {
          "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-STACK-SELECTOR.md",
          "path": "/00-STACK-SELECTOR.md",
          "purpose": "Motor de decisión: ruta → lenguaje → constraints",
          "constraints": ["C5", "C6"],
          "critical": true,
          "language_lock_applicable": false,
          "load_order": 1
        },
        {
          "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/IA-QUICKSTART.md",
          "path": "/IA-QUICKSTART.md",
          "purpose": "Semilla de gobernanza: gate de modo A1-B3",
          "constraints": ["C1", "C4", "C6"],
          "critical": true,
          "language_lock_applicable": false,
          "load_order": 2
        },
        {
          "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/AI-NAVIGATION-CONTRACT.md",
          "path": "/AI-NAVIGATION-CONTRACT.md",
          "purpose": "Contrato de navegación: reglas inamovibles",
          "constraints": ["C1", "C4", "C6"],
          "critical": true,
          "language_lock_applicable": false,
          "load_order": 3
        },
        {
          "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/GOVERNANCE-ORCHESTRATOR.md",
          "path": "/GOVERNANCE-ORCHESTRATOR.md",
          "purpose": "Motor de certificación: Tiers 1/2/3",
          "constraints": ["C2", "C7", "C8"],
          "critical": true,
          "language_lock_applicable": false,
          "load_order": 4
        },
        {
          "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/SDD-COLLABORATIVE-GENERATION.md",
          "path": "/SDD-COLLABORATIVE-GENERATION.md",
          "purpose": "Especificación de formato de artefactos",
          "constraints": ["C5", "C6"],
          "critical": true,
          "language_lock_applicable": false,
          "load_order": 5
        },
        {
          "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/PROJECT_TREE.md",
          "path": "/PROJECT_TREE.md",
          "purpose": "Mapa canónico de rutas del repositorio",
          "constraints": ["C5"],
          "critical": true,
          "language_lock_applicable": false,
          "load_order": 6
        },
        {
          "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json",
          "path": "/05-CONFIGURATIONS/validation/norms-matrix.json",
          "purpose": "Matriz de constraints por carpeta (machine-readable)",
          "constraints": ["C4", "C5"],
          "critical": true,
          "language_lock_applicable": false,
          "load_order": 7,
          "parse_as": "json"
        },
        {
          "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/language-lock-protocol.md",
          "path": "/01-RULES/language-lock-protocol.md",
          "purpose": "Protocolo LANGUAGE LOCK: operadores prohibidos",
          "constraints": ["C4", "C5"],
          "critical": true,
          "language_lock_applicable": true,
          "load_order": 8
        },
        {
          "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/knowledge-graph.json",
          "path": "/knowledge-graph.json",
          "purpose": "Grafo de conocimiento para navegación inteligente",
          "constraints": ["C5"],
          "critical": true,
          "language_lock_applicable": false,
          "load_order": 9,
          "parse_as": "json"
        }
      ]
    },
    
    "phase_2_validation_toolchain": {
      "description": "Carga para validación local de artefactos",
      "required": false,
      "urls": [
        {
          "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/orchestrator-engine.sh",
          "path": "/05-CONFIGURATIONS/validation/orchestrator-engine.sh",
          "purpose": "Motor principal de validación y scoring",
          "type": "bash_script",
          "executable": true,
          "load_order": 10
        },
        {
          "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/verify-constraints.sh",
          "path": "/05-CONFIGURATIONS/validation/verify-constraints.sh",
          "purpose": "Validar constraints C1-C8 + LANGUAGE LOCK",
          "type": "bash_script",
          "executable": true,
          "load_order": 11
        },
        {
          "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/audit-secrets.sh",
          "path": "/05-CONFIGURATIONS/validation/audit-secrets.sh",
          "purpose": "Detectar secrets hardcodeados (C3)",
          "type": "bash_script",
          "executable": true,
          "load_order": 12
        },
        {
          "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/check-rls.sh",
          "path": "/05-CONFIGURATIONS/validation/check-rls.sh",
          "purpose": "Validar tenant isolation en SQL (C4)",
          "type": "bash_script",
          "executable": true,
          "load_order": 13
        },
        {
          "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/validate-frontmatter.sh",
          "path": "/05-CONFIGURATIONS/validation/validate-frontmatter.sh",
          "purpose": "Verificar frontmatter YAML válido (C5)",
          "type": "bash_script",
          "executable": true,
          "load_order": 14
        },
        {
          "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/check-wikilinks.sh",
          "path": "/05-CONFIGURATIONS/validation/check-wikilinks.sh",
          "purpose": "Validar wikilinks canónicos (C5)",
          "type": "bash_script",
          "executable": true,
          "load_order": 15
        },
        {
          "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schema-validator.py",
          "path": "/05-CONFIGURATIONS/validation/schema-validator.py",
          "purpose": "Validar JSON/YAML contra schemas",
          "type": "python_script",
          "executable": true,
          "requires_python": ">=3.8",
          "load_order": 16
        },
        {
          "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/scripts/packager-assisted.sh",
          "path": "/05-CONFIGURATIONS/scripts/packager-assisted.sh",
          "purpose": "Empaquetar artefactos Tier 3 con manifest",
          "type": "bash_script",
          "executable": true,
          "load_order": 17
        }
      ]
    },
    
    "phase_3_language_indices": {
      "description": "Índices de patrones por lenguaje (cargar bajo demanda)",
      "required": false,
      "conditional_load": "based_on_00-STACK-SELECTOR_resolution",
      "urls": [
        {
          "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/00-INDEX.md",
          "path": "/06-PROGRAMMING/00-INDEX.md",
          "purpose": "Índice agregador maestro de los 7 lenguajes",
          "language": "index_aggregator",
          "artifact_count": 137,
          "language_lock_enforcement": true,
          "load_order": 20
        },
        {
          "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/go/00-INDEX.md",
          "path": "/06-PROGRAMMING/go/00-INDEX.md",
          "purpose": "Índice de patrones Go (35 artifacts)",
          "language": "go",
          "artifact_count": 35,
          "constraints_mandatory": ["C3", "C4", "C5", "C8"],
          "language_lock": {
            "deny_operators": ["<->", "<=>", "<#", "vector(n)", "USING hnsw", "USING ivfflat"],
            "deny_constraints": ["V1", "V2", "V3"]
          },
          "load_order": 21
        },
        {
          "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/python/00-INDEX.md",
          "path": "/06-PROGRAMMING/python/00-INDEX.md",
          "purpose": "Índice de patrones Python (24 artifacts)",
          "language": "python",
          "artifact_count": 24,
          "constraints_mandatory": ["C3", "C4", "C5", "C8"],
          "language_lock": {
            "deny_constraints": ["V1", "V2", "V3"]
          },
          "load_order": 22
        },
        {
          "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/00-INDEX.md",
          "path": "/06-PROGRAMMING/postgresql-pgvector/00-INDEX.md",
          "purpose": "Índice de patrones pgvector (10 artifacts) - ÚNICO para búsqueda vectorial",
          "language": "postgresql-pgvector",
          "artifact_count": 10,
          "constraints_mandatory": ["C3", "C4", "C5", "V1", "V3"],
          "language_lock": {
            "require_artifact_type": "skill_pgvector",
            "require_vector_declaration": true
          },
          "is_vector_only": true,
          "load_order": 23
        }
      ]
    }
  },
  
  "url_validation_rules": {
    "http_status_required": 200,
    "content_type_validation": {
      ".md": "text/markdown",
      ".json": "application/json",
      ".sh": "text/x-shellscript",
      ".py": "text/x-python",
      ".yml": "text/yaml"
    },
    "checksum_verification": {
      "algorithm": "SHA256",
      "field_name": "checksum_sha256",
      "verification_command": "curl -s {url} | sha256sum"
    },
    "wikilink_resolution": {
      "format": "[[RUTA/CANÓNICA/DESDE/RAÍZ.ext]]",
      "forbidden_patterns": ["../", "./", "#section-anchors"],
      "resolution_source": "PROJECT_TREE.md"
    }
  },
  
  "dependency_graph": {
    "critical_infrastructure": [
      {"file": "PROJECT_TREE.md", "purpose": "Resolver rutas canónicas para wikilinks", "load_order": 1},
      {"file": "00-STACK-SELECTOR.md", "purpose": "Determinar lenguaje por ruta", "load_order": 2},
      {"file": "05-CONFIGURATIONS/validation/norms-matrix.json", "purpose": "Mapear constraints por carpeta", "load_order": 3},
      {"file": "01-RULES/language-lock-protocol.md", "purpose": "Reglas de exclusión de operadores", "load_order": 4}
    ],
    "navigation_contracts": [
      {"file": "IA-QUICKSTART.md", "purpose": "Definir modos A1-B3 y gate humano", "load_order": 1},
      {"file": "AI-NAVIGATION-CONTRACT.md", "purpose": "Reglas de interacción IA-humano", "load_order": 2},
      {"file": "GOVERNANCE-ORCHESTRATOR.md", "purpose": "Tiers, validación y certificación", "load_order": 3}
    ],
    "validation_toolchain": [
      {"file": "05-CONFIGURATIONS/validation/orchestrator-engine.sh", "purpose": "Motor principal de validación", "load_order": 1},
      {"file": "05-CONFIGURATIONS/validation/verify-constraints.sh", "purpose": "Validación de constraints y LANGUAGE LOCK", "load_order": 2},
      {"file": "05-CONFIGURATIONS/validation/audit-secrets.sh", "purpose": "Detección de secrets hardcodeados", "load_order": 3}
    ]
  },
  
  "human_readable_errors": {
    "url_not_found": "URL '{url}' retornó HTTP {status}. Verificar que el archivo existe en PROJECT_TREE.md.",
    "content_type_mismatch": "URL '{url}' retornó Content-Type '{actual}' pero se esperaba '{expected}'. Verificar extensión del archivo.",
    "checksum_mismatch": "Checksum de '{url}' no coincide: esperado {expected}, obtenido {actual}. Verificar integridad del archivo.",
    "wikilink_not_canonical": "Wikilink '{wikilink}' no es canónico. Usar forma absoluta: [[RUTA-DESDE-RAÍZ]].",
    "language_lock_violation": "Violación de LANGUAGE LOCK: operador '{operator}' prohibido en lenguaje '{language}' para URL '{url}'.",
    "phase_load_failed": "Fase {phase} de carga falló: {error_details}. Detener ejecución y notificar."
  },
  
  "expansion_hooks": {
    "new_critical_url": {
      "requires_files_update": [
        "RAW_URLS_INDEX.md: add URL to phase_1_governance_critical with metadata",
        "knowledge-graph.json: add node for new governance document",
        "PROJECT_TREE.md: add file entry if new critical doc",
        "Human approval required: true"
      ],
      "backward_compatibility": "new critical URLs must not break existing load order; append to end of phase_1"
    },
    "new_language_index": {
      "requires_files_update": [
        "RAW_URLS_INDEX.md: add index URL to phase_3_language_indices",
        "06-PROGRAMMING/00-INDEX.md: add reference to new language index",
        "00-STACK-SELECTOR.md: add routing rule for new language",
        "norms-matrix.json: add constraint mapping for new folder",
        "Human approval required: true"
      ],
      "backward_compatibility": "new language indices must declare LANGUAGE LOCK rules before being added"
    }
  },
  
  "validation_metadata": {
    "orchestrator_compatibility": ">=3.0.0-SELECTIVE",
    "schema_version": "raw-urls-index.v1.json",
    "checksum_algorithm": "SHA256",
    "audit_log_format": "JSON Lines with RFC3339 timestamps",
    "pii_scrubbing": "enabled for all logs (C8 compliance)",
    "reproducibility_guarantee": "Any remote context load can be reproduced identically using this index + load_phases order"
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
yq eval '.canonical_path' RAW_URLS_INDEX.md
# Esperado: "/RAW_URLS_INDEX.md"

# 2. Verificar que constraints_mapped solo contiene C5,C6 (este archivo es catálogo)
yq eval '.constraints_mapped | .[]' RAW_URLS_INDEX.md | grep -E '^C[56]$' | wc -l
# Esperado: 2 líneas

# 3. Verificar que las 9 URLs críticas están listadas en Fase 1
grep -c "FASE 1" RAW_URLS_INDEX.md && echo "✅ Fase 1 presente"
grep -c "critical: true" RAW_URLS_INDEX.md | awk '{if($1>=9) print "✅ 9 URLs críticas marcadas"; else print "⚠️ Menos de 9 críticas"}'

# 4. Verificar que todos los wikilinks apuntan a archivos existentes
for link in $(grep -oE '\[\[[^]]+\]\]' RAW_URLS_INDEX.md | tr -d '[]' | sort -u); do
  if [ ! -f "${link#//}" ] && [ ! -f "${link}" ]; then
    echo "⚠️  Wikilink roto: $link"
  fi
done

# 5. Validar que la sección JSON final es parseable
tail -n +$(grep -n '```json' RAW_URLS_INDEX.md | tail -1 | cut -d: -f1) RAW_URLS_INDEX.md | \
  sed -n '/```json/,/```/p' | sed '1d;$d' | jq empty && echo "✅ JSON válido"

# 6. Validar con orchestrator (simulación mental)
# - ¿El archivo está en raíz? → SÍ
# - ¿El lenguaje es markdown con catálogo de URLs? → SÍ
# - ¿Constraints aplicables según norms-matrix.json? → C5,C6 → SÍ
# - ¿validation_command es ejecutable? → SÍ, apunta a orchestrator-engine.sh
```
````

**Criterio de aceptación:**  
- ✅ Frontmatter válido con `canonical_path: "/RAW_URLS_INDEX.md"`  
- ✅ `constraints_mapped` contiene solo C5,C6 (este archivo es catálogo)  
- ✅ 9 URLs críticas marcadas con `"critical": true` en Fase 1  
- ✅ Sección JSON final es válida (puede parsearse con `jq .`)  
- ✅ Todos los wikilinks apuntan a archivos existentes en `PROJECT_TREE.md`  
- ✅ `validation_command` es ejecutable y apunta al orchestrator correcto  

---

> 🎯 **Mensaje final para el lector humano**:  
> Este índice es tu puerta de acceso remoto. No es estático: evoluciona con el proyecto.  
> **FASE 1 → FASE 2 → FASE 3 (bajo demanda) → FASE 4 (opcional)**.  
> Si sigues ese flujo, nunca cargarás contexto incompleto.  
> La gobernanza no es una carga. Es la libertad de operar remoto sin miedo a romper.  
