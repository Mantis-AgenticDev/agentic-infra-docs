---
canonical_path: "/IA-QUICKSTART.md"
artifact_id: "ia-quickstart-seed"
artifact_type: "governance_seed"
version: "3.0.0-SELECTIVE"
mode_gate_required: true
supported_llms: ["qwen", "deepseek", "minimax", "claude", "gemini", "gpt"]
llm_oriental_optimized: true
constraints_mapped: ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file IA-QUICKSTART.md --mode headless --json"
tier: 1
immutable: false
requires_human_approval_for_changes: true
expansion_points: ["modes", "stacks", "validation_profiles", "integrations", "llm_adapters"]
related_files:
  - "[[00-STACK-SELECTOR.md]]"
  - "[[AI-NAVIGATION-CONTRACT.md]]"
  - "[[GOVERNANCE-ORCHESTRATOR.md]]"
  - "[[PROJECT_TREE.md]]"
  - "[[05-CONFIGURATIONS/validation/norms-matrix.json]]"
  - "[[01-RULES/harness-norms-v3.0.md]]"
  - "[[06-PROGRAMMING/00-INDEX.md]]"
checksum_sha256: "PENDING_GENERATION"
---

# 🌱 MANTIS AGENTIC – Semilla de Gobernanza Ejecutable

<!-- 
【PARA PRINCIPIANTES】¿Qué es este archivo?
Este documento es tu "llave de entrada" al proyecto. 
No es código. Es un contrato de gobernanza que:
• Te guía paso a paso para interactuar con el sistema
• Previene errores antes de que ocurran
• Funciona con cualquier IA (Qwen, DeepSeek, MiniMax, Claude, etc.)

Si eres nuevo: lee en orden. 
Si ya conoces el proyecto: usa los wikilinks para ir directo a lo que necesitas.
-->

> **Instrucción crítica para la IA:** 
> Este documento es tu contrato operativo. 
> **NO generes código, NO propongas soluciones, NO asumas contexto** hasta completar el 【Paso 0】.

---

## 【0】🔒 GATE DE MODO OPERATIVO (OBLIGATORIO – NO SALTAR)

<!-- 
【EDUCATIVO】El sistema opera en 6 modos. 
Cada modo combina: 
- CONTEXTO: ¿Es para el proyecto interno (A) o para un cliente (B)?
- AUTONOMÍA: ¿La IA asiste (1), genera código (2) o despliega automático (3)?

Esto no es opcional. Cada modo tiene reglas de validación diferentes.
-->

Antes de cualquier acción, **DEBES** solicitar al humano que seleccione **exactamente uno** de los siguientes modos:

```
【SELECCIÓN DE MODO – RESPONDE CON EL CÓDIGO】
[A1] Interno + Asistido    → Documentación, planos, configuración
[A2] Interno + Auto-gen    → Código validable, scripts, tooling
[A3] Interno + Auto-deploy → Binarios, Docker, CI/CD listo
[B1] Externo + Asistido    → Propuestas, esquemas para cliente
[B2] Externo + Auto-gen    → Código fuente integrable por cliente
[B3] Externo + Auto-deploy → ZIP completo con manifiesto y scripts

⚠️  Sin selección explícita → DETENER EJECUCIÓN y solicitar confirmación.
⚠️  Respuesta inválida → Listar opciones nuevamente y esperar.
✅  Respuesta válida → Proceder al 【Paso 1】 y registrar: mode_selected=<CÓDIGO>
```

> **Regla de contención:** Si el humano no responde en **3 turnos de conversación**, asumir `A1` con `AUDIT_FLAG=human_timeout` y notificar explícitamente antes de continuar:
> ```
> ⚠️  Timeout de selección de modo. Fallback a A1 (Interno + Asistido) con AUDIT_FLAG=human_timeout.
> ¿Desea cambiar de modo antes de proceder? [S/N]
> ```

### 0.1 Tabla de Referencia Rápida de Modos

<!-- 
【PARA PRINCIPIANTES】¿Cuál modo elegir? Esta tabla te ayuda a decidir.
-->

| Modo | ¿Cuándo usarlo? | Ejemplo de tarea | Formato de entrega |
|------|----------------|-----------------|-------------------|
| **A1** | Quieres ayuda para escribir documentación o planos | "Ayúdame a documentar la arquitectura del agente RAG" | Texto en pantalla, requiere revisión humana |
| **A2** | Quieres que la IA genere código para el proyecto interno | "Genera un script de backup para los VPS internos" | Código fuente + comando de validación |
| **A3** | Quieres un paquete listo para desplegar en infra interna | "Empaqueta el orquestador en Docker para producción" | ZIP con Dockerfile, manifest, deploy.sh |
| **B1** | Quieres ayuda para preparar una propuesta para un cliente | "Ayúdame a escribir una propuesta técnica para cliente agrícola" | Documento en pantalla, cliente revisa |
| **B2** | Quieres código que el cliente pueda integrar en su sistema | "Genera un webhook de WhatsApp para cliente X" | Código fuente + instrucciones de integración |
| **B3** | Quieres un paquete completo que el cliente pueda desplegar | "Entrega un ZIP con el agente RAG listo para producción del cliente" | ZIP con manifest, deploy.sh, rollback.sh, README |

---

## 【1】📋 CARGA DE CONTEXTO CANÓNICO (SÓLO DESPUÉS DE MODO CONFIRMADO)

<!-- 
【EDUCATIVO】Una vez confirmado el modo, la IA debe cargar estos archivos en orden estricto. 
Si alguno no está disponible, NOTIFICAR y DETENER. No asumir, no inventar.
-->

Una vez confirmado el modo, cargar en **orden estricto**:

```
1. [[PROJECT_TREE]] → Resolver ruta canónica de destino
2. [[00-STACK-SELECTOR]] → Determinar lenguaje y framework permitido
3. [[05-CONFIGURATIONS/validation/norms-matrix.json]] → Extraer constraints aplicables
4. [[GOVERNANCE-ORCHESTRATOR]] → Aplicar Tier de certificación y formato de entrega
5. [[06-PROGRAMMING/00-INDEX]] → Cargar índices de patrones por lenguaje
```

> **Nota de contención:** Si alguno de estos archivos no está disponible en el contexto, notificar:
> ```
> ⚠️  Archivo [[X]] no disponible en contexto actual.
> ¿Desea: [1] Proceder con validación reducida (riesgo de deriva) | [2] Esperar sincronización de contexto?
> ```
> **Default seguro:** Opción [2] → Detener ejecución hasta que el contexto esté completo.

---

## 【2】🔄 PROTOCOLO DE GENERACIÓN (MODULAR – EXPANSIBLE)

<!-- 
【PARA PRINCIPIANTES】Este es el flujo que sigue la IA para generar artefactos. 
Es determinista: mismos inputs → mismos outputs. 
Si algo no está claro, DETENER y preguntar.
-->

### 【2.1】Validación Pre-Generación (Obligatoria)

Antes de generar cualquier contenido, verificar:

```
✅ ¿La ruta destino existe en [[PROJECT_TREE]]?
✅ ¿El lenguaje asignado coincide con LANGUAGE LOCK en [[00-STACK-SELECTOR]]?
✅ ¿Las constraints declaradas ⊆ norms-matrix[carpeta].allowed?
✅ ¿No hay operadores prohibidos para este lenguaje (LANGUAGE LOCK)?
```

Si **cualquiera** falla → Error estructurado:
```
❌ BLOCKING_ISSUE: <descripción específica>
Sugerencia: <acción correctiva>
Referencia: [[wikilink a norma relevante]]
```

### 【2.2】Generación con Patrones (Según Tier)

<!-- 
【EDUCATIVO】El formato de salida depende del Tier derivado del modo.
-->

| Tier | Modos | Formato de Salida | Requisitos Mínimos |
|------|-------|------------------|-------------------|
| **Tier 1** | A1, B1 | Texto en pantalla + nota "Requiere revisión humana" | Frontmatter válido, wikilinks canónicos |
| **Tier 2** | A2, B2 | Código fuente + `validation_command` + checksum SHA256 | ≥10 ejemplos ✅/❌/🔧, constraints_mapped explícitos |
| **Tier 3** | A3, B3 | ZIP simulado con `manifest.json` + `deploy.sh` + `rollback.sh` | Healthcheck, checksums, audit trail, prompt_hash |

### 【2.3】Plantilla de Frontmatter Canónico

Todo artefacto generado **DEBE** incluir este frontmatter al inicio:

```yaml
---
canonical_path: "/ruta/canónica/exacta/desde/raíz.md"
artifact_id: "identificador-único-del-artefacto"
artifact_type: "skill_go|skill_python|documentation|etc"
version: "1.0.0"
constraints_mapped: ["C3", "C4", "C5"]  # Según norms-matrix.json
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file <ruta> --json"
tier: 2  # Derivado del modo seleccionado
mode_selected: "A2"  # Registrado en Paso 0
prompt_hash: "sha256-del-prompt-original"  # Para auditoría
generated_at: "2026-04-19T12:00:00Z"  # RFC3339 UTC
---
```

> 💡 **Consejo para principiantes:** Copia y pega esta plantilla. Luego reemplaza los valores entre `< >`. No inventes campos nuevos sin aprobación humana.

---

## 【3】🛡️ CAPAS DE CONTENCIÓN (NO NEGOCIABLES)

<!-- 
【EDUCATIVO】Estas reglas previenen que la IA "alucine" o se desvíe del protocolo. 
Son inamovibles. Si algo las viola, DETENER y notificar.
-->

| Capa | Regla | Implementación en esta Semilla |
|------|-------|-------------------------------|
| **Modo** | No proceder sin selección explícita | Gate 【0】con stop condition y timeout auditado |
| **Stack** | Lenguaje dictado por ubicación, no por preferencia | Referencia obligatoria a `[[00-STACK-SELECTOR]]` antes de generar |
| **Constraints** | Aplicar solo las permitidas por carpeta | Carga de `[[norms-matrix.json]]` post-modo, validación cruzada |
| **LANGUAGE LOCK** | Operadores vectoriales SOLO en pgvector | Bloqueo explícito: `<->`, `<=>`, `<#>` prohibidos fuera de `postgresql-pgvector/` |
| **Validación** | Todo artefacto debe ser validable | Incluir `validation_command` ejecutable en frontmatter |
| **Auditoría** | Registrar cada decisión humana | Log estructurado con `mode_selected`, `prompt_hash`, `timestamp` |

### 3.1 Anti-Patrones Críticos (Prohibidos)

<!-- 
【PARA PRINCIPIANTES】Estos errores son comunes. Evítalos desde el inicio.
-->

| Anti-patrón | Por qué está prohibido | Consecuencia |
|------------|----------------------|-------------|
| **Generar sin confirmar modo (A1-B3)** | Deriva de gobernanza, validación inconsistente | ❌ Bloqueo inmediato: "MODE_NOT_SPECIFIED" |
| **Elegir lenguaje antes que ruta** | Viola LANGUAGE LOCK, genera inconsistencias | ❌ Error: "LANGUAGE_MISMATCH" con sugerencia de ruta correcta |
| **Usar operadores pgvector en go/ o sql/** | Violación crítica de LANGUAGE LOCK | ❌ Bloqueo: "LANGUAGE_LOCK_VIOLATION" + referencia a norma |
| **Hardcodear secrets o tenant_id** | Viola C3/C4, fuga de datos entre clientes | ❌ Bloqueo crítico: "C3_VIOLATION" o "C4_VIOLATION" |
| **Omitir frontmatter o validation_command** | Rompe validación automática, Tier 1 imposible | ❌ Error: "STRUCTURAL_CONTRACT_INVALID" |
| **Inventar constraints no mapeadas** | Falsa sensación de seguridad, auditoría imposible | ❌ Error: "CONSTRAINT_NOT_ALLOWED" + lista de válidas |
| **Usar wikilinks relativos (`[[../otra]]`)** | Rompe resolución canónica, imposible auditar | ❌ Advertencia: "WIKILINK_NOT_CANONICAL" + corrección sugerida |

---

## 【4】🧭 PROTOCOLO DE NAVEGACIÓN PARA IA (PASO A PASO)

<!-- 
【EDUCATIVO】Este es el flujo determinista que DEBE seguir cualquier IA. 
Mismos inputs → mismos outputs. Si algo no está claro, DETENER y preguntar.
-->

```
┌─────────────────────────────────────────────────────────┐
│ 【PASO 0】CONFIRMACIÓN DE MODO (GATE HUMANO)            │
├─────────────────────────────────────────────────────────┤
│ Si el humano no especificó modo (A1/A2/A3/B1/B2/B3):    │
│ 1. Mostrar menú de 6 opciones con descripciones claras  │
│ 2. Esperar respuesta explícita (ej: "B2")               │
│ 3. Si timeout (3 turnos) → fallback a A1 con AUDIT_FLAG │
│ 4. Registrar: mode_selected=<CÓDIGO>, prompt_hash=<SHA> │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 1】CARGA DE CONTEXTO CANÓNICO                    │
├─────────────────────────────────────────────────────────┤
│ Leer en orden estricto:                                  │
│ 1. [[PROJECT_TREE]] → resolver ruta destino             │
│ 2. [[00-STACK-SELECTOR]] → lenguaje permitido           │
│ 3. [[norms-matrix.json]] → constraints aplicables       │
│ 4. [[GOVERNANCE-ORCHESTRATOR]] → tier y validación      │
│ Si algún archivo no está disponible → NOTIFICAR y DETENER │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 2】VALIDACIÓN PRE-GENERACIÓN                     │
├─────────────────────────────────────────────────────────┤
│ Verificar:                                               │
│ • ¿La ruta destino existe en PROJECT_TREE?              │
│ • ¿El lenguaje asignado coincide con LANGUAGE LOCK?     │
│ • ¿constraints_mapped ⊆ norms-matrix[carpeta].allowed? │
│ • ¿No hay operadores prohibidos para este lenguaje?     │
│ Si NO → Error estructurado: "blocking_issue: X"         │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 3】GENERACIÓN CON PATRONES                       │
├─────────────────────────────────────────────────────────┤
│ 1. Cargar plantilla desde 05-CONFIGURATIONS/templates/  │
│ 2. Aplicar frontmatter canónico (ver 【2.3】)           │
│ 3. Generar cuerpo con ≥10 ejemplos ✅/❌/🔧 (Tier 2-3)  │
│ 4. Incluir comentarios educativos si artifact_type lo permite │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 4】VALIDACIÓN POST-GENERACIÓN                    │
├─────────────────────────────────────────────────────────┤
│ Ejecutar (mental o real):                                │
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
│ 【PASO 5】ENTREGA SEGÚN TIER                            │
├─────────────────────────────────────────────────────────┤
│ Tier 1 (A1/B1): Pantalla + nota "Requiere revisión humana" │
│ Tier 2 (A2/B2): Código + validation_command + checksum  │
│ Tier 3 (A3/B3): ZIP con manifest.json + deploy.sh + rollback.sh │
└─────────────────────────────────────────────────────────┘
```

> 💡 **Consejo para principiantes**: Si te pierdes en algún paso, vuelve al inicio. Este protocolo está diseñado para ser repetible y auditable.

---

## 【5】📚 GLOSARIO PARA PRINCIPIANTES

<!-- 
【EDUCATIVO】Términos técnicos explicados en lenguaje simple.
-->

| Término | Significado simple | Ejemplo |
|---------|-------------------|---------|
| **Canonical Path** | La ruta "oficial" donde debe vivir un archivo en el proyecto | `/06-PROGRAMMING/go/orchestrator-engine.go.md` |
| **Frontmatter** | Metadatos al inicio de un archivo Markdown (entre `---`) | `version: "1.0.0"`, `constraints_mapped: ["C1","C3"]` |
| **LANGUAGE LOCK** | Regla que prohíbe ciertos operadores en ciertas carpetas | No usar `<->` en `go/`, solo en `postgresql-pgvector/` |
| **Tenant Isolation (C4)** | Aislar datos de cada cliente para que no se mezclen | `WHERE tenant_id = $1` en cada query |
| **Tier 1/2/3** | Niveles de madurez: 1=borrador, 2=código listo, 3=desplegable | Tier 3 incluye healthcheck, rollback, checksums |
| **Validation Command** | Comando que cualquiera puede ejecutar para verificar el artefacto | `bash orchestrator-engine.sh --file mi-archivo.md --json` |
| **Wikilink** | Enlace interno al proyecto con doble corchete | `[[PROJECT_TREE.md]]` se resuelve a la ruta real |
| **Constraint** | Regla de calidad que debe cumplirse | C3: "Nunca escribas contraseñas en el código" |
| **Prompt Hash** | SHA256 del prompt original del humano | Para auditoría: saber qué solicitud generó este artefacto |
| **AUDIT_FLAG** | Marca que indica cómo se tomó una decisión | `human_confirmed`, `human_timeout`, `fallback_applied` |

---

## 【6】🧪 SANDBOX DE PRUEBA (OPCIONAL)

<!-- 
【PARA DESARROLLADORES】Pega esta sección en un chat nuevo para validar que la IA sigue el protocolo sin contexto previo.
-->

```
【TEST MODE: IA-QUICKSTART VALIDATION】
Prompt de prueba: "Generar agente RAG multi-tenant con webhook de WhatsApp para cliente agrícola"

Respuesta esperada de la IA:
1. 【GATE MODO】Solicitar selección: [A1]...[B3] con descripciones claras
2. Si humano responde "B3":
   - Registrar: mode_selected=B3, prompt_hash=<SHA256 del prompt>
   - Cargar PROJECT_TREE → ruta: services/rag/whatsapp-agent/
   - Consultar 00-STACK-SELECTOR → lenguaje: Python + postgresql-pgvector
   - Cargar norms-matrix.json → constraints: C3🔴, C4🔴, C5🔴, V1🔴, V3🔴
   - Aplicar LANGUAGE LOCK → Python: cero operadores pgvector en código, solo en queries
3. Cargar índices: [[06-PROGRAMMING/python/00-INDEX]], [[06-PROGRAMMING/postgresql-pgvector/00-INDEX]]
4. Seleccionar plantillas: langchain-integration.md + rag-query-with-tenant-enforcement.pgvector.md
5. Generar artefacto con:
   - Frontmatter canónico con mode_selected, constraints_mapped, validation_command
   - Cuerpo: agente LangGraph con tenant_id propagation, queries vectoriales con V1/V3 documentadas
   - ≥10 ejemplos ✅/❌/🔧
   - Bloque de validación: orchestrator-engine.sh --file ... --mode headless --json
6. Entregar: ZIP simulado con manifest.json, deploy.sh, rollback.sh, README-DEPLOY.md

Si la IA omite el Paso 1 o usa lenguaje incorrecto → FALLA DE GOBERNANZA.
```

---

## 【7】🔗 REFERENCIAS CANÓNICAS (WIKILINKS)

<!-- 
【PARA IA】Estos enlaces deben resolverse usando PROJECT_TREE.md. 
No uses rutas relativas. Usa siempre la forma canónica [[RUTA]].
-->

- `[[00-STACK-SELECTOR]]` → Motor de decisión de stack (ruta → lenguaje → constraints)
- `[[PROJECT_TREE]]` → Mapa maestro de rutas del repositorio
- `[[05-CONFIGURATIONS/validation/norms-matrix.json]]` → Matriz de aplicación de constraints por carpeta
- `[[01-RULES/harness-norms-v3.0.md]]` → Definición textual de C1-C8
- `[[01-RULES/language-lock-protocol.md]]` → Reglas de exclusión de operadores por lenguaje
- `[[GOVERNANCE-ORCHESTRATOR]]` → Tiers, validación y certificación
- `[[AI-NAVIGATION-CONTRACT]]` → Reglas de interacción y navegación
- `[[06-PROGRAMMING/00-INDEX]]` → Índice agregador de patrones por lenguaje
- `[[05-CONFIGURATIONS/templates/skill-template.md]]` → Plantilla base para nuevos artefactos
- `[[SDD-COLLABORATIVE-GENERATION]]` → Especificación de formato de artefactos

---

## 【8】📦 METADATOS DE EXPANSIÓN (PARA FUTURAS VERSIONES)

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
      "addition_requires": [
        "Update this file: add mode description to table in 【0.1】",
        "Update 00-STACK-SELECTOR.md: add mode to decision matrix",
        "Update GOVERNANCE-ORCHESTRATOR.md: add tier mapping",
        "Update norms-matrix.json: add validation_profile",
        "Human approval required: true"
      ]
    },
    "llm_adapters": {
      "current": ["qwen", "deepseek", "minimax", "claude", "gemini", "gpt"],
      "extensible": true,
      "optimization_notes": {
        "oriental_models": "Use delimiters 【】, numbered sequences, explicit stop conditions",
        "western_models": "Use clear headings, bullet points, code fences",
        "all_models": "Always include prompt_hash for auditability"
      }
    }
  },
  "compatibility_rule": "Nuevas secciones deben usar formato ## 【N】<TÍTULO> y declarar EXPANSION_POINT en comentario HTML. La IA debe ignorar secciones desconocidas sin fallar."
}
```

---

<!-- 
═══════════════════════════════════════════════════════════
🤖 SECCIÓN PARA IA: ÁRBOL JSON ENRIQUECIDO
═══════════════════════════════════════════════════════════
Esta sección contiene metadatos estructurados para consumo automático por agentes de IA.
No está diseñada para lectura humana directa. Los humanos deben usar las secciones 【1】-【8】.

Formato: JSON válido, con comentarios explicativos en claves "doc_*".
Prioridad de ejecución: Las normas se aplican en el orden definido en "norm_execution_order".
Dependencias: Cada nodo declara sus archivos requeridos y sus efectos colaterales.
═══════════════════════════════════════════════════════════
-->

```json
{
  "quickstart_metadata": {
    "version": "3.0.0-SELECTIVE",
    "canonical_path": "/IA-QUICKSTART.md",
    "artifact_type": "governance_seed",
    "mode_gate_required": true,
    "supported_llms": ["qwen", "deepseek", "minimax", "claude", "gemini", "gpt"],
    "llm_optimizations": {
      "oriental_models_friendly": true,
      "delimiters_used": ["【】", "┌─┐", "▼", "✅/❌/🔧"],
      "numbered_sequences": true,
      "stop_conditions_explicit": true,
      "response_format_examples": true
    }
  },
  
  "mode_definitions": {
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
  
  "protocol_steps": {
    "step_0_mode_gate": {
      "trigger": "mode not specified in user prompt",
      "action": "present 6-mode menu with descriptions",
      "timeout_turns": 3,
      "fallback_mode": "A1",
      "fallback_audit_flag": "human_timeout",
      "required_response_format": "single code: A1|A2|A3|B1|B2|B3",
      "invalid_response_action": "re-prompt with validation error",
      "audit_fields": ["mode_selected", "source:human_confirmed|human_timeout", "prompt_sha256", "timestamp_rfc3339"]
    },
    "step_1_context_load": {
      "load_order": [
        {"file": "PROJECT_TREE.md", "purpose": "resolve canonical path", "required": true},
        {"file": "00-STACK-SELECTOR.md", "purpose": "determine language by path", "required": true},
        {"file": "05-CONFIGURATIONS/validation/norms-matrix.json", "purpose": "map constraints by folder", "required": true},
        {"file": "GOVERNANCE-ORCHESTRATOR.md", "purpose": "apply tier and validation profile", "required": true},
        {"file": "06-PROGRAMMING/00-INDEX.md", "purpose": "load language-specific patterns", "required": false}
      ],
      "missing_file_action": "notify_user_with_options",
      "default_action": "wait_for_context_sync"
    },
    "step_2_pre_generation_validation": {
      "checks": [
        {"check": "path_exists_in_project_tree", "blocking": true},
        {"check": "language_matches_stack_selector", "blocking": true},
        {"check": "constraints_subset_of_norms_matrix", "blocking": true},
        {"check": "no_language_lock_violations", "blocking": true}
      ],
      "error_format": "❌ BLOCKING_ISSUE: {description}\nSugerencia: {corrective_action}\nReferencia: [[{wikilink}]]"
    },
    "step_3_generation_with_patterns": {
      "template_source": "05-CONFIGURATIONS/templates/skill-template.md",
      "frontmatter_required_fields": [
        "canonical_path", "artifact_id", "artifact_type", "version",
        "constraints_mapped", "validation_command", "tier", "mode_selected",
        "prompt_hash", "generated_at"
      ],
      "examples_minimum": {"tier_1": 0, "tier_2": 10, "tier_3": 10},
      "example_format": "✅ Good | ❌ Bad | 🔧 Fix"
    },
    "step_4_post_generation_validation": {
      "command_template": "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {path} --mode headless --json",
      "acceptance_criteria": {
        "score_minimum": 30,
        "blocking_issues_empty": true,
        "language_lock_violations_zero": true
      },
      "retry_policy": {"max_attempts": 3, "backoff": "linear"}
    },
    "step_5_delivery_by_tier": {
      "tier_1": {"format": "screen_editor", "note": "Requiere revisión humana"},
      "tier_2": {"format": "code_block", "includes": ["validation_command", "checksum_sha256"]},
      "tier_3": {"format": "zip_simulated", "includes": ["manifest.json", "deploy.sh", "rollback.sh", "README-DEPLOY.md", "checksums.sha256"]}
    }
  },
  
  "constraint_execution_order": {
    "description": "Orden de aplicación de constraints durante validación. Críticas primero para fail-fast.",
    "fail_fast_sequence": [
      {"constraint": "C3", "reason": "Zero Hardcode Secrets - bloqueo crítico inmediato si falla"},
      {"constraint": "C4", "reason": "Tenant Isolation - fuga de datos es inaceptable"},
      {"constraint": "C5", "reason": "Structural Contract - sin frontmatter válido, no hay validación posible"}
    ],
    "standard_sequence": [
      {"constraint": "C1", "reason": "Resource Limits - previene DoS por configuración"},
      {"constraint": "C6", "reason": "Verifiable Execution - auditabilidad de comandos"},
      {"constraint": "C2", "reason": "Concurrency Control - estabilidad del sistema"},
      {"constraint": "C7", "reason": "Resilience - tolerancia a fallos operativos"},
      {"constraint": "C8", "reason": "Observability - trazabilidad post-mortem"}
    ],
    "vector_sequence": [
      {"constraint": "V1", "reason": "Vector Dimensions - declaración obligatoria para pgvector"},
      {"constraint": "V2", "reason": "Distance Metric - documentación semántica del operador"},
      {"constraint": "V3", "reason": "Index Justification - optimización basada en evidencia"}
    ],
    "evaluation_logic": "1) Ejecutar fail_fast_sequence. Si alguna falla → bloqueo inmediato. 2) Ejecutar standard_sequence según lenguaje. 3) Si language=postgresql-pgvector, ejecutar vector_sequence."
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
      {"file": "AI-NAVIGATION-CONTRACT.md", "purpose": "Reglas de interacción IA-humano", "load_order": 1},
      {"file": "GOVERNANCE-ORCHESTRATOR.md", "purpose": "Tiers, validación y certificación", "load_order": 2}
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
      {"file": "05-CONFIGURATIONS/validation/audit-secrets.sh", "purpose": "Detección de secrets hardcodeados", "load_order": 3}
    ]
  },
  
  "language_lock_enforcement": {
    "global_deny_list": {
      "operators": ["<->", "<=>", "<#", "vector(n)", "USING hnsw", "USING ivfflat"],
      "constraints": ["V1", "V2", "V3"],
      "applies_to_languages": ["go", "bash", "python", "javascript", "typescript", "sql", "yaml"],
      "exception_language": "postgresql-pgvector"
    },
    "validation_command_template": "bash 05-CONFIGURATIONS/validation/verify-constraints.sh --check-language-lock --dir 06-PROGRAMMING/<language>/",
    "failure_action": "orchestrator-engine.sh returns blocking_issues: ['LANGUAGE_LOCK_VIOLATION'] with specific operator/constraint details"
  },
  
  "human_readable_errors": {
    "mode_invalid": "Modo '{value}' no reconocido. Use uno de: A1, A2, A3, B1, B2, B3. Ver 【0】para descripciones.",
    "path_not_canonical": "Ruta '{value}' no es canónica. Consulte [[PROJECT_TREE]] para rutas válidas.",
    "language_mismatch": "Lenguaje '{language}' no permitido para ruta '{path}'. Según [[00-STACK-SELECTOR]], esta ruta requiere: '{expected_language}'.",
    "constraint_not_allowed": "Constraint '{constraint}' no aplicable para ruta '{path}'. Consulte [[05-CONFIGURATIONS/validation/norms-matrix.json]].",
    "language_lock_violation_operator": "Violación de LANGUAGE LOCK: operador '{operator}' prohibido en lenguaje '{language}'. Ver [[01-RULES/language-lock-protocol]].",
    "missing_frontmatter_field": "Campo obligatorio '{field}' faltante en frontmatter. Consulte plantilla en 【2.3】.",
    "validation_failed": "Validación fallida: score={score}, blocking_issues={issues}. Ejecute: {validation_command}"
  },
  
  "audit_requirements": {
    "required_log_fields": [
      "timestamp_rfc3339",
      "mode_selected",
      "canonical_path",
      "language",
      "constraints_mapped",
      "validation_profile",
      "prompt_sha256",
      "validation_result",
      "blocking_issues",
      "language_lock_violations",
      "audit_flag"
    ],
    "pii_scrubbing_rules": {
      "enabled": true,
      "fields_to_scrub": ["password", "secret", "token", "api_key", "credential", "tenant_data"],
      "scrub_method": "replace_with_***REDACTED***",
      "compliance": "C3 (Zero Hardcode Secrets) + C8 (Observabilidad)"
    },
    "retention_policy": {
      "debug_logs": "90_days",
      "audit_logs": "7_years",
      "compliance_logs": "permanent_if_tier3",
      "rotation": "daily_with_checksum"
    },
    "export_formats": ["JSON Lines", "CSV for SIEM", "OpenTelemetry OTLP"]
  },
  
  "expansion_hooks": {
    "new_mode_addition": {
      "requires_files_update": [
        "IA-QUICKSTART.md (this file): add mode to table in 【0.1】",
        "00-STACK-SELECTOR.md: add mode to decision matrix",
        "GOVERNANCE-ORCHESTRATOR.md: add tier mapping",
        "norms-matrix.json: add validation_profile"
      ],
      "requires_schema_update": "stack-selection.schema.json",
      "requires_human_approval": true,
      "backward_compatibility": "new modes must not break existing A1-B3 flows"
    },
    "new_llm_adapter": {
      "requires_optimization_notes": "Add entry to llm_adapters.optimization_notes with model-specific tips",
      "requires_testing": "Validate protocol steps with new model in sandbox mode",
      "requires_human_approval": false,
      "backward_compatibility": "new adapters must support all existing protocol steps"
    }
  },
  
  "validation_metadata": {
    "orchestrator_compatibility": ">=3.0.0-SELECTIVE",
    "schema_version": "quickstart-seed.v1.json",
    "checksum_algorithm": "SHA256",
    "audit_log_format": "JSON Lines with RFC3339 timestamps",
    "pii_scrubbing": "enabled for all logs (C8 compliance)"
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
yq eval '.canonical_path' IA-QUICKSTART.md
# Esperado: "/IA-QUICKSTART.md"

# 2. Verificar que constraints_mapped solo contiene C1-C8 (este archivo no es pgvector)
yq eval '.constraints_mapped | .[]' IA-QUICKSTART.md | grep -E '^C[1-8]$' | wc -l
# Esperado: 8 líneas

# 3. Verificar que el gate de modo está presente y bien formado
grep -q "【0】.*GATE DE MODO" IA-QUICKSTART.md && echo "✅ Gate de modo presente"

# 4. Verificar que todos los wikilinks apuntan a archivos existentes
for link in $(grep -oE '\[\[[^]]+\]\]' IA-QUICKSTART.md | tr -d '[]' | sort -u); do
  if [ ! -f "${link#//}" ] && [ ! -f "${link}" ]; then
    echo "⚠️  Wikilink roto: $link"
  fi
done

# 5. Validar que la sección JSON final es parseable
tail -n +$(grep -n '```json' IA-QUICKSTART.md | tail -1 | cut -d: -f1) IA-QUICKSTART.md | \
  sed -n '/```json/,/```/p' | sed '1d;$d' | jq empty && echo "✅ JSON válido"

# 6. Validar con orchestrator (simulación mental)
# - ¿El archivo está en raíz? → SÍ
# - ¿El lenguaje es markdown con seed de gobernanza? → SÍ
# - ¿Constraints aplicables según norms-matrix.json? → C5 mandatory → SÍ
# - ¿validation_command es ejecutable? → SÍ, apunta a orchestrator-engine.sh
```
````

**Criterio de aceptación:**  
- ✅ Frontmatter válido con `canonical_path: "/IA-QUICKSTART.md"`  
- ✅ `constraints_mapped` contiene solo C1-C8 (este archivo no es pgvector)  
- ✅ Gate de modo 【0】presente con timeout y fallback auditado  
- ✅ Sección JSON final es válida (puede parsearse con `jq .`)  
- ✅ Todos los wikilinks apuntan a archivos existentes en `PROJECT_TREE.md`  
- ✅ `validation_command` es ejecutable y apunta al orchestrator correcto  

---


> 🎯 **Mensaje final para el lector humano**:  
> Este documento es tu contrato. No es opcional.  
> **Modo → Ruta → Lenguaje → Constraints → Validación**.  
> Si sigues ese flujo, nunca generarás un artefacto fuera de norma.  
> La gobernanza no es una carga. Es la libertad de crear sin miedo a romper.  

