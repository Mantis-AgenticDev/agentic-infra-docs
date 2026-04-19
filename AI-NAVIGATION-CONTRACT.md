---
canonical_path: "/AI-NAVIGATION-CONTRACT.md"
artifact_id: "ai-navigation-contract"
artifact_type: "navigation_contract"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file AI-NAVIGATION-CONTRACT.md --mode headless --json"
tier: 1
immutable: true
requires_human_approval_for_changes: true
related_files:
  - "[[00-STACK-SELECTOR.md]]"
  - "[[IA-QUICKSTART.md]]"
  - "[[GOVERNANCE-ORCHESTRATOR.md]]"
  - "[[PROJECT_TREE.md]]"
  - "[[05-CONFIGURATIONS/validation/norms-matrix.json]]"
  - "[[01-RULES/harness-norms-v3.0.md]]"
  - "[[06-PROGRAMMING/00-INDEX.md]]"
checksum_sha256: "PENDING_GENERATION"
---


# 📄 AI-NAVIGATION-CONTRACT.md – CONTRATO DE NAVEGACIÓN EJECUTABLE

> **Nota para principiantes:** Este documento es tu "contrato de interacción" con el ecosistema MANTIS AGENTIC. Define las reglas que la IA DEBE seguir para navegar, generar y validar artefactos. Si eres nuevo, lee las secciones en orden. Si eres experto, salta al JSON final.  
>  
> **Para IAs:** Este es tu contrato operativo. **VIOLAR CUALQUIER REGLA = BLOQUEO INMEDIATO**. No inventes, no asumas, no omitas.



# 🧭 AI-NAVIGATION-CONTRACT: Contrato de Navegación Ejecutable

<!-- 
【PARA PRINCIPIANTES】¿Qué es este archivo?
Este documento es el "contrato legal" entre humanos e IAs en el proyecto MANTIS AGENTIC.
Define las reglas inamovibles que la IA DEBE seguir para:
• Navegar por el repositorio
• Seleccionar lenguajes y patrones
• Generar artefactos válidos
• Validar antes de entregar

Si eres nuevo: lee en orden. 
Si ya conoces el proyecto: usa los wikilinks para ir directo a lo que necesitas.
-->

> **Instrucción crítica para la IA:** 
> Este documento es tu contrato operativo. 
> **VIOLAR CUALQUIER REGLA = BLOQUEO INMEDIATO**. 
> No inventes, no asumas, no omitas. Si algo no está claro, DETENER y preguntar.

---

## 【0】🔒 REGLA 0: MODO EXPLÍCITO OBLIGATORIO (GATE DE ENTRADA)

<!-- 
【EDUCATIVO】Esta es la regla más importante. 
Sin modo explícito, NO HAY GENERACIÓN. 
El modo determina TODO: validación, formato, autonomía, entrega.
-->

### 0.1 Declaración Inamovible

```
REGLA 0.1: Ninguna generación de artefactos procede sin modo explícito confirmado.
REGLA 0.2: Si el humano no especifica modo, la IA DEBE solicitar selección usando el menú de 【IA-QUICKSTART.md】.
REGLA 0.3: Timeout de 3 turnos → fallback a A1 con AUDIT_FLAG=human_timeout.
REGLA 0.4: Respuesta inválida → re-prompt con lista de opciones válidas.
REGLA 0.5: Modo confirmado → registrar mode_selected=<CÓDIGO> + prompt_hash=<SHA256> en trazas.
```

### 0.2 Matriz de Modos (Referencia Rápida)

<!-- 
【PARA PRINCIPIANTES】¿Qué significa cada modo? Esta tabla te ayuda a entender las implicaciones.
-->

| Modo | Contexto | Autonomía | Tier | ¿Puede generar código? | ¿Requiere revisión humana? | Formato de entrega |
|------|----------|-----------|------|----------------------|--------------------------|-------------------|
| **A1** | Interno | Asistido | 1 | ❌ Solo documentación | ✅ Sí, siempre | Pantalla + nota |
| **A2** | Interno | Auto-gen | 2 | ✅ Código validable | ❌ No (gate CI automático) | Código + validation_command |
| **A3** | Interno | Auto-deploy | 3 | ✅ Binarios/Docker | ❌ No (gate CD automático) | ZIP con manifest + deploy.sh |
| **B1** | Externo | Asistido | 1 | ❌ Solo propuestas | ✅ Sí, humano responsable | Pantalla + nota cliente |
| **B2** | Externo | Auto-gen | 2 | ✅ Código integrable | ❌ No (cliente integra) | Código + instrucciones |
| **B3** | Externo | Auto-deploy | 3 | ✅ Paquete producción | ❌ No (cliente despliega) | ZIP completo + README-DEPLOY |

### 0.3 Protocolo de Confirmación (Pseudocódigo para IA)

```
IF mode_not_specified_in_prompt:
    PRESENT menu from [[IA-QUICKSTART.md]] Section 【0】
    WAIT for response in format: A1|A2|A3|B1|B2|B3
    IF timeout (3 turns):
        SET mode_selected = "A1"
        SET audit_flag = "human_timeout"
        NOTIFY: "⚠️ Fallback a A1 con AUDIT_FLAG=human_timeout. ¿Cambiar modo? [S/N]"
        IF human_confirms_change: RE-PROMPT
        ELSE: PROCEED with A1
    ELSE IF response_invalid:
        NOTIFY: "❌ Modo inválido. Opciones válidas: A1, A2, A3, B1, B2, B3"
        RE-PROMPT
    ELSE:
        SET mode_selected = response
        SET audit_flag = "human_confirmed"
        LOG: mode_selected, prompt_hash, timestamp_rfc3339
        PROCEED to Rule 1
ELSE:
    VALIDATE mode against enum [A1,A2,A3,B1,B2,B3]
    IF invalid: BLOCK with error "MODE_INVALID"
    ELSE: PROCEED to Rule 1
```

> ⚠️ **Contención crítica**: La inferencia contextual (ej: "si menciona 'cliente' → modo B") está **PROHIBIDA** para decisión. Solo se usa para logging de auditoría, nunca para `mode_selected`.

---

## 【1】🗺️ REGLA 1: RUTA CANÓNICA ANTES QUE LENGUAJE

<!-- 
【EDUCATIVO】El error más común es elegir lenguaje primero. 
Este contrato lo previene: primero ruta, luego lenguaje.
-->

### 1.1 Declaración Inamovible

```
REGLA 1.1: La ubicación canónica (dónde va el archivo) determina el lenguaje permitido.
REGLA 1.2: Consultar [[PROJECT_TREE]] para resolver rutas válidas antes de cualquier generación.
REGLA 1.3: Si la ruta destino no existe en PROJECT_TREE → ERROR: "PATH_NOT_CANONICAL".
REGLA 1.4: Consultar [[00-STACK-SELECTOR]] para mapear ruta → lenguaje → constraints.
REGLA 1.5: LANGUAGE LOCK es inamovible: operadores vectoriales SOLO en postgresql-pgvector/.
```

### 1.2 Tabla de Enrutamiento Crítico (Resumen de 00-STACK-SELECTOR)

| Patrón de Ruta | Lenguaje Obligatorio | Constraints Mandatory | LANGUAGE LOCK |
|---------------|---------------------|---------------------|--------------|
| `^/06-PROGRAMMING/go/` | **Go** | C3, C4, C5, C8 | 🔴 Deny: `<->`, `<=>`, `<#>`, `vector(n)`, `USING hnsw/ivfflat`, V1-V3 |
| `^/06-PROGRAMMING/python/` | **Python** | C3, C4, C5, C8 | 🔴 Deny: V1-V3 (vectoriales) |
| `^/06-PROGRAMMING/sql/` | **SQL estándar** | C4, C5 | 🔴 Deny: operadores pgvector, V1-V3 |
| `^/06-PROGRAMMING/postgresql-pgvector/` | **SQL+pgvector** | C3, C4, C5, V1, V3 | 🟢 Allow: `<->`, `<=>`, `<#>` con documentación V2 |
| `^/06-PROGRAMMING/bash/` | **Bash** | C3, C4, C5, C6 | 🔴 Deny: V1-V3 |
| `^/06-PROGRAMMING/javascript/` | **TypeScript** | C3, C4, C5, C8 | 🔴 Deny: V1-V3 |
| `^/06-PROGRAMMING/yaml-json-schema/` | **YAML+JSON Schema** | C5 | 🔴 Deny: V1-V3 |

> 💡 **Consejo para principiantes**: Si no estás seguro de la ruta canónica, pregunta: "¿En qué carpeta debería vivir este artefacto según [[PROJECT_TREE]]?"

### 1.3 Protocolo de Resolución de Ruta (Pseudocódigo para IA)

```
FUNCTION resolve_canonical_path(task_description):
    # Paso 1: Intentar mapear tarea a carpeta usando PROJECT_TREE
    candidate_path = map_task_to_folder(task_description, PROJECT_TREE)
    
    # Paso 2: Validar que la ruta existe y es canónica
    IF candidate_path NOT IN PROJECT_TREE.valid_paths:
        RETURN error: "PATH_NOT_CANONICAL: '{candidate_path}' no es ruta válida. Consulte [[PROJECT_TREE]]."
    
    # Paso 3: Consultar STACK-SELECTOR para lenguaje y constraints
    stack_rule = query_stack_selector(candidate_path, 00-STACK-SELECTOR)
    
    # Paso 4: Validar LANGUAGE LOCK
    IF task_requires_vector_operators AND stack_rule.language != "sql_pgvector":
        RETURN error: "LANGUAGE_LOCK_VIOLATION: operadores vectoriales solo permitidos en postgresql-pgvector/"
    
    RETURN {
        canonical_path: candidate_path,
        language: stack_rule.language,
        constraints_mandatory: stack_rule.constraints_mandatory,
        constraints_allowed: stack_rule.constraints_allowed
    }
```

---

## 【2】🛡️ REGLA 2: CONSTRAINTS APLICABLES POR CARPETA

<!-- 
【EDUCATIVO】Las constraints son reglas de calidad. 
No todas aplican a todo. Esta regla previene aplicar normas incorrectas.
-->

### 2.1 Declaración Inamovible

```
REGLA 2.1: Las constraints declaradas en un artefacto DEBEN ser subconjunto de las permitidas para su carpeta según [[norms-matrix.json]].
REGLA 2.2: Constraints mandatory (C3, C4, C5) DEBEN estar siempre declaradas si aplican a la carpeta.
REGLA 2.3: Constraints vectoriales (V1, V2, V3) SOLO aplican si language == "sql_pgvector".
REGLA 2.4: El orden de validación es: fail_fast (C3,C4,C5) → standard (C1,C2,C6,C7,C8) → vector (V1,V2,V3).
REGLA 2.5: Si una constraint fail_fast falla → bloqueo inmediato, score = 0.
```

### 2.2 Matriz de Aplicación de Constraints (Resumen de norms-matrix.json)

<!-- 
【PARA PRINCIPIANTES】¿Qué normas aplicar según el lenguaje? Esta tabla resume lo esencial.
-->

| Constraint | ¿Qué verifica? | ¿Cuándo es mandatory? | ¿Fail-fast? | Validator Script |
|-----------|---------------|---------------------|-------------|-----------------|
| **C1** Resource Limits | Memoria, CPU, pids, tamaño | En scripts, servicios, containers | ❌ No | `orchestrator-engine.sh` |
| **C2** Concurrency/Timeout | Goroutines, async, timeouts | En código concurrente | ❌ No | `orchestrator-engine.sh` |
| **C3** Zero Hardcode Secrets | Credenciales en código | 🔴 TODOS los artefactos | ✅ Sí | `audit-secrets.sh` |
| **C4** Tenant Isolation | Fuga de datos entre tenants | 🔴 En código con datos multi-usuario | ✅ Sí | `check-rls.sh` |
| **C5** Structural Contract | Frontmatter, schema, wikilinks | 🔴 TODOS los artefactos | ✅ Sí | `validate-frontmatter.sh` |
| **C6** Verifiable Execution | Dry-run, exit codes, audit trail | En scripts y comandos | ❌ No | `orchestrator-engine.sh` |
| **C7** Operational Resilience | Retry, fallback, healthcheck | En servicios y scripts críticos | ❌ No | `orchestrator-engine.sh` |
| **C8** Structured Logging | Logs JSON, trace_id, PII scrubbing | En código con logging | ❌ No | `orchestrator-engine.sh` |
| **V1** Vector Dimensions | Declaración de dimensiones embedding | 🔴 SOLO en postgresql-pgvector/ | ✅ Sí (si usa pgvector) | `verify-constraints.sh --check-vector-dims` |
| **V2** Distance Metric | Documentar métrica de distancia | 🟢 SOLO en postgresql-pgvector/ | ❌ No | `verify-constraints.sh --check-vector-metric` |
| **V3** Index Justification | Justificar elección de índice vectorial | 🟢 SOLO en postgresql-pgvector/ | ❌ No | `verify-constraints.sh --check-vector-index` |

### 2.3 Protocolo de Validación de Constraints (Pseudocódigo para IA)

```
FUNCTION validate_constraints(artifact_metadata, norms_matrix):
    # Paso 1: Extraer constraints declaradas del artefacto
    declared = artifact_metadata.constraints_mapped
    
    # Paso 2: Obtener constraints permitidas/mandatory para la carpeta
    allowed = norms_matrix.folder_routing_table[artifact_metadata.canonical_path].constraints_allowed
    mandatory = norms_matrix.folder_routing_table[artifact_metadata.canonical_path].constraints_mandatory
    
    # Paso 3: Validar que declared ⊆ allowed
    FOR constraint IN declared:
        IF constraint NOT IN allowed:
            RETURN error: "CONSTRAINT_NOT_ALLOWED: '{constraint}' no aplicable para ruta '{path}'"
    
    # Paso 4: Validar que mandatory ⊆ declared
    FOR constraint IN mandatory:
        IF constraint NOT IN declared:
            RETURN error: "MISSING_MANDATORY_CONSTRAINT: '{constraint}' es obligatoria para ruta '{path}'"
    
    # Paso 5: Validar LANGUAGE LOCK para constraints vectoriales
    IF artifact_metadata.language != "sql_pgvector":
        FOR constraint IN ["V1", "V2", "V3"]:
            IF constraint IN declared:
                RETURN error: "LANGUAGE_LOCK_VIOLATION: constraint '{constraint}' prohibida en lenguaje '{language}'"
    
    # Paso 6: Ejecutar validación en orden fail_fast → standard → vector
    execution_order = norms_matrix.constraint_execution_order
    FOR phase IN ["fail_fast_sequence", "standard_sequence", "vector_sequence"]:
        FOR constraint IN execution_order[phase]:
            IF constraint IN declared:
                result = run_validator(constraint, artifact_metadata)
                IF result.failed AND constraint IN execution_order.fail_fast_sequence:
                    RETURN error: "FAIL_FAST_VIOLATION: {constraint} failed - bloqueo inmediato"
                IF result.failed:
                    LOG warning: "{constraint} validation warning: {result.message}"
    
    RETURN success: "All constraints validated"
```

---

## 【3】🔐 REGLA 3: LANGUAGE LOCK ENFORCEMENT

<!-- 
【EDUCATIVO】LANGUAGE LOCK previene que operadores de un lenguaje "se filtren" a otro. 
Es crítico para integridad del sistema.
-->

### 3.1 Declaración Inamovible

```
REGLA 3.1: Operadores pgvector (<->, <=>, <#, vector(n), USING hnsw/ivfflat) están PROHIBIDOS en todos los lenguajes EXCEPTO sql_pgvector.
REGLA 3.2: Constraints vectoriales (V1, V2, V3) están PROHIBIDAS en todos los lenguajes EXCEPTO sql_pgvector.
REGLA 3.3: La carpeta 06-PROGRAMMING/postgresql-pgvector/ es el ÚNICO lugar permitido para búsqueda vectorial.
REGLA 3.4: Violaciones de LANGUAGE LOCK son bloqueantes: orchestrator retorna blocking_issues: ["LANGUAGE_LOCK_VIOLATION"].
REGLA 3.5: El validador verify-constraints.sh --check-language-lock DEBE ejecutarse para cada artefacto en go/, sql/, python/, etc.
```

### 3.2 Tabla de Operadores Prohibidos por Lenguaje

| Lenguaje | Operadores Prohibidos | Constraints Prohibidas | Validator Command |
|----------|---------------------|----------------------|------------------|
| **Go** | `<->`, `<=>`, `<#`, `vector(n)`, `USING hnsw`, `USING ivfflat` | V1, V2, V3 | `verify-constraints.sh --check-language-lock --dir 06-PROGRAMMING/go/` |
| **Python** | (ninguno específico) | V1, V2, V3 | `verify-constraints.sh --check-language-lock --dir 06-PROGRAMMING/python/` |
| **Bash** | (ninguno específico) | V1, V2, V3 | `verify-constraints.sh --check-language-lock --dir 06-PROGRAMMING/bash/` |
| **SQL (genérico)** | `<->`, `<=>`, `<#`, `vector(n)`, `USING hnsw`, `USING ivfflat` | V1, V2, V3 | `verify-constraints.sh --check-language-lock --dir 06-PROGRAMMING/sql/` |
| **TypeScript/JS** | (ninguno específico) | V1, V2, V3 | `verify-constraints.sh --check-language-lock --dir 06-PROGRAMMING/javascript/` |
| **YAML** | (ninguno específico) | V1, V2, V3 | `verify-constraints.sh --check-language-lock --dir 06-PROGRAMMING/yaml-json-schema/` |
| **SQL+pgvector** | (ninguno - son permitidos) | (ninguna - son permitidas) | `verify-constraints.sh --check-vector-dims --check-vector-metric --check-vector-index` |

### 3.3 Protocolo de Verificación de LANGUAGE LOCK (Pseudocódigo para IA)

```
FUNCTION verify_language_lock(artifact_content, language, norms_matrix):
    # Paso 1: Obtener lista de operadores prohibidos para este lenguaje
    deny_list = norms_matrix.language_lock_enforcement.language_specific_rules[language].deny_operators
    
    # Paso 2: Buscar operadores prohibidos en el contenido
    FOR operator IN deny_list:
        IF regex_search(operator, artifact_content):
            RETURN error: "LANGUAGE_LOCK_VIOLATION: operador '{operator}' prohibido en lenguaje '{language}'"
    
    # Paso 3: Validar constraints vectoriales
    IF language != "sql_pgvector":
        FOR constraint IN ["V1", "V2", "V3"]:
            IF constraint IN artifact_metadata.constraints_mapped:
                RETURN error: "LANGUAGE_LOCK_VIOLATION: constraint '{constraint}' prohibida en lenguaje '{language}'"
    
    # Paso 4: Si language == sql_pgvector, validar requisitos adicionales
    IF language == "sql_pgvector":
        IF "V1" NOT IN artifact_metadata.constraints_mapped:
            RETURN error: "MISSING_MANDATORY_CONSTRAINT: V1 es obligatoria para postgresql-pgvector/"
        IF NOT has_vector_dimension_declaration(artifact_content):
            RETURN error: "V1_VIOLATION: falta declaración de dimensiones vectoriales"
    
    RETURN success: "LANGUAGE_LOCK validated"
```

---

## 【4】🔄 REGLA 4: PROTOCOLO DE NAVEGACIÓN DETERMINISTA

<!-- 
【EDUCATIVO】Este es el flujo paso a paso que la IA DEBE seguir. 
Mismos inputs → mismos outputs. Sin ambigüedad.
-->

### 4.1 Secuencia Obligatoria de Navegación

```
┌─────────────────────────────────────────────────────────┐
│ 【FASE 0】GATE DE MODO (Regla 0)                        │
├─────────────────────────────────────────────────────────┤
│ • Confirmar modo explícito (A1-B3)                      │
│ • Registrar mode_selected + prompt_hash                 │
│ • Si timeout → fallback A1 con AUDIT_FLAG               │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 1】RESOLUCIÓN DE RUTA (Regla 1)                  │
├─────────────────────────────────────────────────────────┤
│ • Consultar [[PROJECT_TREE]] para ruta canónica         │
│ • Consultar [[00-STACK-SELECTOR]] para lenguaje         │
│ • Validar que ruta existe y lenguaje coincide           │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 2】MAPEO DE CONSTRAINTS (Regla 2)                │
├─────────────────────────────────────────────────────────┤
│ • Cargar [[norms-matrix.json]]                          │
│ • Extraer constraints_allowed/mandatory para la carpeta │
│ • Validar que constraints_mapped ⊆ allowed              │
│ • Validar que mandatory ⊆ constraints_mapped            │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 3】LANGUAGE LOCK (Regla 3)                       │
├─────────────────────────────────────────────────────────┤
│ • Verificar que no hay operadores prohibidos            │
│ • Verificar que no hay constraints vectoriales fuera de │
│   postgresql-pgvector/                                  │
│ • Si language=pgvector, validar V1/V2/V3                │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 4】GENERACIÓN CON PATRONES                       │
├─────────────────────────────────────────────────────────┤
│ • Cargar índice de lenguaje desde [[06-PROGRAMMING/00-INDEX]] │
│ • Seleccionar plantilla específica del patrón           │
│ • Aplicar frontmatter canónico con todos los campos     │
│ • Generar cuerpo con ejemplos ✅/❌/🔧 según Tier      │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 5】VALIDACIÓN POST-GENERACIÓN                    │
├─────────────────────────────────────────────────────────┤
│ • Ejecutar: orchestrator-engine.sh --file <ruta> --json│
│ • Esperar: score >= 30, blocking_issues == []           │
│ • Si falla → iterar corrección (máx 3 intentos)        │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 6】ENTREGA SEGÚN TIER                            │
├─────────────────────────────────────────────────────────┤
│ • Tier 1: Pantalla + nota "Requiere revisión humana"    │
│ • Tier 2: Código + validation_command + checksum        │
│ • Tier 3: ZIP con manifest + deploy.sh + rollback.sh    │
└─────────────────────────────────────────────────────────┘
```

### 4.2 Trazas de Decisión (Ejemplos para Principiantes)

<!-- 
【EDUCATIVO】Así se ve una traza de decisión correcta. 
Úsala como referencia para depurar.
-->

#### Ejemplo 1: Solicitud válida → Generación exitosa

```
【TRAZA DE DECISIÓN】
Prompt: "Generar webhook seguro para WhatsApp de cliente agrícola"

Paso 0 - Modo:
  • Humano responde: "B2"
  • Registrado: mode_selected=B2, audit_flag=human_confirmed, prompt_hash=abc123...

Paso 1 - Ruta:
  • PROJECT_TREE: tarea "webhook" → carpeta 06-PROGRAMMING/javascript/
  • 00-STACK-SELECTOR: ruta → language=typescript, constraints=C3,C4,C5,C8

Paso 2 - Constraints:
  • norms-matrix.json[06-PROGRAMMING/javascript/]: allowed=[C1-C8], mandatory=[C3,C4,C5,C8]
  • Validación: declared=[C3,C4,C5,C8] ⊆ allowed ✅, mandatory ⊆ declared ✅

Paso 3 - LANGUAGE LOCK:
  • language=typescript → deny_operators=[], deny_constraints=[V1,V2,V3]
  • Verificación: no hay operadores vectoriales en contenido ✅

Paso 4 - Generación:
  • Cargar índice: [[06-PROGRAMMING/javascript/00-INDEX]]
  • Seleccionar plantilla: webhook-validation-patterns.ts.md
  • Generar con frontmatter canónico + 10 ejemplos ✅/❌/🔧

Paso 5 - Validación:
  • Ejecutar: orchestrator-engine.sh --file 06-PROGRAMMING/javascript/webhook-whatsapp.ts.md --json
  • Resultado: score=42, blocking_issues=[], language_lock_violations=0 ✅

Paso 6 - Entrega (Tier 2):
  • Formato: código fuente + validation_command + checksum_sha256
  • Nota: "Código listo para integración. Ejecute validation_command para verificar."
```

#### Ejemplo 2: Violación de LANGUAGE LOCK → Bloqueo

```
【TRAZA DE DECISIÓN】
Prompt: "Generar query vectorial para embeddings en Go"

Paso 0 - Modo:
  • Humano responde: "A2"
  • Registrado: mode_selected=A2, audit_flag=human_confirmed

Paso 1 - Ruta:
  • PROJECT_TREE: tarea "query vectorial" → ¿carpeta?
  • Humano especifica: 06-PROGRAMMING/go/vector-search.go.md
  • 00-STACK-SELECTOR: ruta → language=go, constraints=C1-C8, deny=[V1,V2,V3]

Paso 2 - Constraints:
  • norms-matrix.json[06-PROGRAMMING/go/]: allowed=[C1-C8], mandatory=[C3,C4,C5,C8], denied=[V1,V2,V3]
  • Humano declara constraints_mapped: ["C3","C4","C5","V1"] ← ⚠️ V1 no permitida en go/

Paso 3 - LANGUAGE LOCK:
  • Verificación: constraint "V1" en declared pero language != "sql_pgvector"
  • ❌ ERROR: "LANGUAGE_LOCK_VIOLATION: constraint 'V1' prohibida en lenguaje 'go'"
  • Sugerencia: "Para búsqueda vectorial, use ruta en 06-PROGRAMMING/postgresql-pgvector/ con language=sql_pgvector"
  • Referencia: [[01-RULES/language-lock-protocol]]

Resultado: BLOQUEO INMEDIATO. No se genera artefacto.
```

---

## 【5】🚫 REGLA 5: ANTI-PATRONES PROHIBIDOS (BLOQUEO INMEDIATO)

<!-- 
【EDUCATIVO】Estos errores son comunes. Conócelos para evitarlos.
-->

| Anti-patrón | Por qué está prohibido | Consecuencia | Referencia |
|------------|----------------------|-------------|-----------|
| **Generar sin modo explícito** | Deriva de gobernanza, validación inconsistente | ❌ Bloqueo: "MODE_NOT_SPECIFIED" | [[IA-QUICKSTART#0]] |
| **Elegir lenguaje antes que ruta** | Viola LANGUAGE LOCK, genera inconsistencias | ❌ Error: "LANGUAGE_MISMATCH" | [[00-STACK-SELECTOR#3]] |
| **Usar operadores pgvector en go/ o sql/** | Violación crítica de LANGUAGE LOCK | ❌ Bloqueo: "LANGUAGE_LOCK_VIOLATION" | [[01-RULES/language-lock-protocol]] |
| **Declarar V1/V2/V3 en lenguaje no-pgvector** | Falsa aplicación de normas vectoriales | ❌ Bloqueo: "CONSTRAINT_NOT_ALLOWED" | [[norms-matrix.json]] |
| **Hardcodear secrets o tenant_id** | Viola C3/C4, fuga de datos entre clientes | ❌ Bloqueo crítico: "C3_VIOLATION" o "C4_VIOLATION" | [[harness-norms-v3.0#C3]] |
| **Omitir frontmatter o validation_command** | Rompe validación automática, Tier 1 imposible | ❌ Error: "STRUCTURAL_CONTRACT_INVALID" | [[05-CONFIGURATIONS/templates/skill-template]] |
| **Inventar constraints no mapeadas** | Falsa sensación de seguridad, auditoría imposible | ❌ Error: "CONSTRAINT_NOT_ALLOWED" | [[norms-matrix.json]] |
| **Usar wikilinks relativos (`[[../otra]]`)** | Rompe resolución canónica, imposible auditar | ⚠️ Advertencia: "WIKILINK_NOT_CANONICAL" | [[PROJECT_TREE]] |
| **Inferir modo por contexto (sin confirmación)** | Deriva silenciosa, validación inconsistente | ❌ Bloqueo: "MODE_INFERENCE_PROHIBITED" | [[AI-NAVIGATION-CONTRACT#0]] |
| **Saltar validación pre-generación** | Artefactos inválidos, deuda técnica acumulada | ❌ Bloqueo: "PRE_GENERATION_VALIDATION_SKIPPED" | [[GOVERNANCE-ORCHESTRATOR]] |

---

## 【6】📚 GLOSARIO PARA PRINCIPIANTES

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
| **Fail-fast** | Constraint que, si falla, detiene todo inmediatamente | C3, C4, C5 son fail-fast: error crítico = bloqueo |
| **Determinista** | Mismos inputs → mismos outputs, sin ambigüedad | Este protocolo: si sigues los pasos, siempre obtienes el mismo resultado |

---

## 【7】🧪 SANDBOX DE PRUEBA (OPCIONAL)

<!-- 
【PARA DESARROLLADORES】Pega esta sección en un chat nuevo para validar que la IA sigue el protocolo sin contexto previo.
-->

```
【TEST MODE: AI-NAVIGATION-CONTRACT VALIDATION】
Prompt de prueba: "Generar script de backup para VPS de cliente agrícola"

Respuesta esperada de la IA:
1. 【GATE MODO】Solicitar selección: [A1]...[B3] con descripciones claras
2. Si humano responde "B3":
   - Registrar: mode_selected=B3, prompt_hash=<SHA256>, audit_flag=human_confirmed
   - Cargar PROJECT_TREE → ruta: deploy/vps-backup/
   - Consultar 00-STACK-SELECTOR → lenguaje: Bash
   - Cargar norms-matrix.json → constraints: C3🔴, C4🔴, C5🔴, C6🔴, C7🟢
   - Aplicar LANGUAGE LOCK → Bash: cero pgvector, cero V1-V3
3. Cargar índice: [[06-PROGRAMMING/bash/00-INDEX]]
4. Seleccionar plantilla: robust-error-handling.md + filesystem-sandboxing.md
5. Generar artefacto con:
   - Frontmatter canónico con mode_selected, constraints_mapped, validation_command
   - Cuerpo: script Bash con ${VAR:?missing}, tenant_id en logs, timeout en rsync, retry con backoff
   - ≥10 ejemplos ✅/❌/🔧
   - Bloque de validación: orchestrator-engine.sh --file ... --mode headless --json
6. Ejecutar validación mental:
   - score >= 30? ✅
   - blocking_issues == []? ✅
   - language_lock_violations == 0? ✅
7. Entregar (Tier 3): ZIP simulado con manifest.json, deploy.sh, rollback.sh, README-DEPLOY.md, checksums.sha256

Si la IA omite el Paso 1, usa lenguaje incorrecto, o declara constraints no permitidas → FALLA DE GOBERNANZA.
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
- `[[01-RULES/harness-norms-v3.0.md]]` → Definición textual de C1-C8
- `[[01-RULES/language-lock-protocol.md]]` → Reglas de exclusión de operadores por lenguaje
- `[[GOVERNANCE-ORCHESTRATOR]]` → Tiers, validación y certificación
- `[[IA-QUICKSTART]]` → Punto de entrada para IAs, define modos A1-B3
- `[[06-PROGRAMMING/00-INDEX]]` → Índice agregador de patrones por lenguaje
- `[[05-CONFIGURATIONS/templates/skill-template.md]]` → Plantilla base para nuevos artefactos
- `[[SDD-COLLABORATIVE-GENERATION]]` → Especificación de formato de artefactos

---

## 【9】📦 METADATOS DE EXPANSIÓN (PARA FUTURAS VERSIONES)

<!-- 
【PARA MANTENEDORES】Nuevas secciones deben seguir este formato para no romper compatibilidad.
-->

```json
{
  "expansion_registry": {
    "navigation_rules": {
      "current_count": 5,
      "extensible": true,
      "addition_requires": [
        "Update this file: add new rule with format ## 【N】REGLA N: <TÍTULO>",
        "Update IA-QUICKSTART.md: reference new rule in protocol steps",
        "Update GOVERNANCE-ORCHESTRATOR.md: integrate with validation flow",
        "Update norms-matrix.json: if rule affects constraint applicability",
        "Human approval required: true"
      ]
    },
    "anti_patterns": {
      "current_count": 10,
      "extensible": true,
      "addition_requires": [
        "Add entry to Section 【5】with: anti-pattern, reason, consequence, reference",
        "Ensure consequence is enforceable by orchestrator-engine.sh",
        "Human approval required: true"
      ]
    }
  },
  "compatibility_rule": "Nuevas reglas no deben invalidar artefactos generados bajo versiones anteriores. Cambios breaking requieren major version bump y guía de migración."
}
```

---

<!-- 
═══════════════════════════════════════════════════════════
🤖 SECCIÓN PARA IA: ÁRBOL JSON ENRIQUECIDO
═══════════════════════════════════════════════════════════
Esta sección contiene metadatos estructurados para consumo automático por agentes de IA.
No está diseñada para lectura humana directa. Los humanos deben usar las secciones 【1】-【9】.

Formato: JSON válido, con comentarios explicativos en claves "doc_*".
Prioridad de ejecución: Las normas se aplican en el orden definido en "norm_execution_order".
Dependencias: Cada nodo declara sus archivos requeridos y sus efectos colaterales.
═══════════════════════════════════════════════════════════
-->

```json
{
  "navigation_contract_metadata": {
    "version": "3.0.0-SELECTIVE",
    "canonical_path": "/AI-NAVIGATION-CONTRACT.md",
    "artifact_type": "navigation_contract",
    "immutable": true,
    "requires_human_approval_for_changes": true,
    "llm_optimizations": {
      "oriental_models_friendly": true,
      "delimiters_used": ["【】", "┌─┐", "▼", "✅/❌/🔧"],
      "numbered_sequences": true,
      "stop_conditions_explicit": true,
      "response_format_examples": true
    }
  },
  
  "rule_definitions": {
    "rule_0_mode_gate": {
      "priority": "critical",
      "blocking_if_violated": true,
      "validation_logic": "mode_must_be_explicit_enum_A1_to_B3",
      "timeout_policy": {"turns": 3, "fallback_mode": "A1", "audit_flag": "human_timeout"},
      "audit_fields": ["mode_selected", "source:human_confirmed|human_timeout", "prompt_sha256", "timestamp_rfc3339"],
      "error_messages": {
        "mode_not_specified": "Modo no especificado. Consulte [[IA-QUICKSTART#0]] para seleccionar.",
        "mode_invalid": "Modo '{value}' no reconocido. Opciones válidas: A1, A2, A3, B1, B2, B3.",
        "mode_inference_prohibited": "Inferencia de modo por contexto está prohibida. Requiere confirmación explícita."
      }
    },
    
    "rule_1_canonical_path_first": {
      "priority": "critical",
      "blocking_if_violated": true,
      "validation_logic": "path_must_exist_in_PROJECT_TREE_and_match_STACK_SELECTOR",
      "resolution_protocol": "map_task_to_folder → validate_path → query_stack_selector → validate_language",
      "error_messages": {
        "path_not_canonical": "Ruta '{value}' no es canónica. Consulte [[PROJECT_TREE]] para rutas válidas.",
        "language_mismatch": "Lenguaje '{language}' no permitido para ruta '{path}'. Según [[00-STACK-SELECTOR]], requiere: '{expected_language}'."
      }
    },
    
    "rule_2_constraints_applicability": {
      "priority": "critical",
      "blocking_if_violated": true,
      "validation_logic": "declared_constraints_must_be_subset_of_allowed_and_include_mandatory",
      "execution_order": {
        "fail_fast": ["C3", "C4", "C5"],
        "standard": ["C1", "C2", "C6", "C7", "C8"],
        "vector": ["V1", "V2", "V3"]
      },
      "error_messages": {
        "constraint_not_allowed": "Constraint '{constraint}' no aplicable para ruta '{path}'. Consulte [[norms-matrix.json]].",
        "missing_mandatory_constraint": "Constraint '{constraint}' es obligatoria para ruta '{path}' pero no fue declarada.",
        "fail_fast_violation": "Constraint fail-fast '{constraint}' falló: {details}. Bloqueo inmediato."
      }
    },
    
    "rule_3_language_lock": {
      "priority": "critical",
      "blocking_if_violated": true,
      "validation_logic": "deny_operators_and_constraints_must_not_appear_in_artifact_content",
      "global_deny_list": {
        "operators": ["<->", "<=>", "<#", "vector(n)", "USING hnsw", "USING ivfflat"],
        "constraints": ["V1", "V2", "V3"],
        "exception_language": "sql_pgvector"
      },
      "language_specific_rules": {
        "go": {"deny_operators": ["<->", "<=>", "<#", "vector(n)", "USING hnsw", "USING ivfflat"], "deny_constraints": ["V1", "V2", "V3"]},
        "sql": {"deny_operators": ["<->", "<=>", "<#", "vector(n)", "USING hnsw", "USING ivfflat"], "deny_constraints": ["V1", "V2", "V3"]},
        "sql_pgvector": {"require_artifact_type": "skill_pgvector", "require_vector_declaration": true}
      },
      "error_messages": {
        "language_lock_violation_operator": "Violación de LANGUAGE LOCK: operador '{operator}' prohibido en lenguaje '{language}'. Ver [[01-RULES/language-lock-protocol]].",
        "language_lock_violation_constraint": "Violación de LANGUAGE LOCK: constraint '{constraint}' prohibida en lenguaje '{language}'. Solo aplican en 'sql_pgvector'."
      }
    },
    
    "rule_4_deterministic_protocol": {
      "priority": "high",
      "blocking_if_violated": false,
      "validation_logic": "protocol_steps_must_be_followed_in_order",
      "protocol_phases": [
        {"phase": "mode_gate", "rule": "rule_0", "blocking": true},
        {"phase": "path_resolution", "rule": "rule_1", "blocking": true},
        {"phase": "constraint_mapping", "rule": "rule_2", "blocking": true},
        {"phase": "language_lock", "rule": "rule_3", "blocking": true},
        {"phase": "pattern_generation", "rule": "use_templates_from_06-PROGRAMMING", "blocking": false},
        {"phase": "post_validation", "rule": "run_orchestrator-engine.sh", "blocking": true},
        {"phase": "tier_delivery", "rule": "format_output_per_tier", "blocking": false}
      ],
      "error_messages": {
        "protocol_step_skipped": "Paso '{phase}' del protocolo de navegación fue omitido. Consulte [[AI-NAVIGATION-CONTRACT#4]].",
        "validation_failed": "Validación post-generación fallida: score={score}, blocking_issues={issues}. Ejecute: {validation_command}"
      }
    }
  },
  
  "anti_patterns_registry": {
    "mode_not_specified": {
      "description": "Generar sin confirmar modo explícito (A1-B3)",
      "consequence": "blocking_issue: MODE_NOT_SPECIFIED",
      "reference": "[[IA-QUICKSTART#0]]",
      "prevention": "Always present mode selection menu before any generation"
    },
    "language_before_path": {
      "description": "Elegir lenguaje antes que ruta canónica",
      "consequence": "blocking_issue: LANGUAGE_MISMATCH",
      "reference": "[[00-STACK-SELECTOR#3]]",
      "prevention": "Always resolve path via PROJECT_TREE before selecting language"
    },
    "pgvector_in_wrong_language": {
      "description": "Usar operadores pgvector en go/, sql/, python/, etc.",
      "consequence": "blocking_issue: LANGUAGE_LOCK_VIOLATION",
      "reference": "[[01-RULES/language-lock-protocol]]",
      "prevention": "Enforce deny_operators list per language via verify-constraints.sh"
    },
    "vector_constraints_outside_pgvector": {
      "description": "Declarar V1/V2/V3 en lenguaje no-pgvector",
      "consequence": "blocking_issue: CONSTRAINT_NOT_ALLOWED",
      "reference": "[[norms-matrix.json]]",
      "prevention": "Validate constraints_mapped against norms-matrix[folder].allowed"
    },
    "hardcoded_secrets_or_tenant": {
      "description": "Hardcodear secrets o tenant_id en código",
      "consequence": "blocking_issue: C3_VIOLATION or C4_VIOLATION",
      "reference": "[[harness-norms-v3.0#C3]]",
      "prevention": "Run audit-secrets.sh and check-rls.sh in pre-generation validation"
    }
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
      {"file": "AI-NAVIGATION-CONTRACT.md", "purpose": "Reglas de interacción IA-humano (este archivo)", "load_order": 2},
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
      {"file": "05-CONFIGURATIONS/validation/check-rls.sh", "purpose": "Validación de tenant isolation en SQL", "load_order": 4}
    ]
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
    "evaluation_logic": "1) Ejecutar fail_fast_sequence. Si alguna falla → bloqueo inmediato. 2) Ejecutar standard_sequence según lenguaje. 3) Si language=sql_pgvector, ejecutar vector_sequence."
  },
  
  "human_readable_errors": {
    "mode_invalid": "Modo '{value}' no reconocido. Use uno de: A1, A2, A3, B1, B2, B3. Ver [[IA-QUICKSTART#0]].",
    "path_not_canonical": "Ruta '{value}' no es canónica. Consulte [[PROJECT_TREE]] para rutas válidas.",
    "language_mismatch": "Lenguaje '{language}' no permitido para ruta '{path}'. Según [[00-STACK-SELECTOR]], esta ruta requiere: '{expected_language}'.",
    "constraint_not_allowed": "Constraint '{constraint}' no aplicable para ruta '{path}'. Consulte [[05-CONFIGURATIONS/validation/norms-matrix.json]].",
    "constraint_missing_mandatory": "Constraint '{constraint}' es obligatoria para ruta '{path}' pero no fue declarada. Agregue '{constraint}' a constraints_mapped.",
    "language_lock_violation_operator": "Violación de LANGUAGE LOCK: operador '{operator}' prohibido en lenguaje '{language}'. Ver [[01-RULES/language-lock-protocol]].",
    "language_lock_violation_constraint": "Violación de LANGUAGE LOCK: constraint '{constraint}' prohibida en lenguaje '{language}'. Solo aplican en 'sql_pgvector'.",
    "vector_missing_declaration": "【pgvector】Falta declaración de dimensiones (V1). Agregue comentario: '-- embedding: NNNd, model: nombre-modelo' o use vector(NNN) en CREATE INDEX.",
    "protocol_step_skipped": "Paso '{phase}' del protocolo de navegación fue omitido. Consulte [[AI-NAVIGATION-CONTRACT#4]] para la secuencia correcta.",
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
      "audit_flag",
      "rule_violated"
    ],
    "pii_scrubbing_rules": {
      "enabled": true,
      "fields_to_scrub": ["password", "secret", "token", "api_key", "credential", "tenant_data", "user_email"],
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
    "new_navigation_rule": {
      "requires_files_update": [
        "AI-NAVIGATION-CONTRACT.md (this file): add rule with format ## 【N】REGLA N: <TÍTULO>",
        "IA-QUICKSTART.md: reference new rule in protocol steps",
        "GOVERNANCE-ORCHESTRATOR.md: integrate with validation flow",
        "norms-matrix.json: if rule affects constraint applicability"
      ],
      "requires_human_approval": true,
      "backward_compatibility": "new rules must not invalidate artifacts generated under previous versions"
    },
    "new_anti_pattern": {
      "requires_files_update": [
        "AI-NAVIGATION-CONTRACT.md: add entry to Section 【5】",
        "orchestrator-engine.sh: ensure consequence is enforceable"
      ],
      "requires_human_approval": true,
      "backward_compatibility": "new anti-patterns apply only to new generations, not existing artifacts"
    }
  },
  
  "validation_metadata": {
    "orchestrator_compatibility": ">=3.0.0-SELECTIVE",
    "schema_version": "navigation-contract.v1.json",
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

```bash
# 1. Verificar que el frontmatter es YAML válido
yq eval '.canonical_path' AI-NAVIGATION-CONTRACT.md
# Esperado: "/AI-NAVIGATION-CONTRACT.md"

# 2. Verificar que constraints_mapped solo contiene C1-C8 (este archivo no es pgvector)
yq eval '.constraints_mapped | .[]' AI-NAVIGATION-CONTRACT.md | grep -E '^C[1-8]$' | wc -l
# Esperado: 8 líneas

# 3. Verificar que la Regla 0 (Gate de Modo) está presente y bien formada
grep -q "【0】.*REGLA 0.*MODO EXPLÍCITO" AI-NAVIGATION-CONTRACT.md && echo "✅ Regla 0 presente"

# 4. Verificar que todos los wikilinks apuntan a archivos existentes
for link in $(grep -oE '\[\[[^]]+\]\]' AI-NAVIGATION-CONTRACT.md | tr -d '[]' | sort -u); do
  if [ ! -f "${link#//}" ] && [ ! -f "${link}" ]; then
    echo "⚠️  Wikilink roto: $link"
  fi
done

# 5. Validar que la sección JSON final es parseable
tail -n +$(grep -n '```json' AI-NAVIGATION-CONTRACT.md | tail -1 | cut -d: -f1) AI-NAVIGATION-CONTRACT.md | \
  sed -n '/```json/,/```/p' | sed '1d;$d' | jq empty && echo "✅ JSON válido"

# 6. Validar con orchestrator (simulación mental)
# - ¿El archivo está en raíz? → SÍ
# - ¿El lenguaje es markdown con contrato de navegación? → SÍ
# - ¿Constraints aplicables según norms-matrix.json? → C5 mandatory → SÍ
# - ¿validation_command es ejecutable? → SÍ, apunta a orchestrator-engine.sh
```

**Criterio de aceptación:**  
- ✅ Frontmatter válido con `canonical_path: "/AI-NAVIGATION-CONTRACT.md"`  
- ✅ `constraints_mapped` contiene solo C1-C8 (este archivo no es pgvector)  
- ✅ Regla 0 (Gate de Modo) presente con timeout y fallback auditado  
- ✅ Sección JSON final es válida (puede parsearse con `jq .`)  
- ✅ Todos los wikilinks apuntan a archivos existentes en `PROJECT_TREE.md`  
- ✅ `validation_command` es ejecutable y apunta al orchestrator correcto  

---

> 🎯 **Mensaje final para el lector humano**:  
> Este contrato es tu garantía. No es opcional.  
> **Modo → Ruta → Lenguaje → Constraints → LANGUAGE LOCK → Validación**.  
> Si sigues ese flujo, nunca generarás un artefacto fuera de norma.  
> La gobernanza no es una carga. Es la libertad de crear sin miedo a romper.  
