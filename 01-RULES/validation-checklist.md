---
canonical_path: "/01-RULES/validation-checklist.md"
artifact_id: "validation-checklist-canonical"
artifact_type: "governance_checklist"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C5", "C6"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 01-RULES/validation-checklist.md --mode headless --json"
tier: 1
immutable: true
requires_human_approval_for_changes: true
related_files:
  - "[[01-RULES/harness-norms-v3.0.md]]"
  - "[[05-CONFIGURATIONS/validation/norms-matrix.json]]"
  - "[[GOVERNANCE-ORCHESTRATOR.md]]"
  - "[[SDD-COLLABORATIVE-GENERATION.md]]"
  - "[[TOOLCHAIN-REFERENCE.md]]"
  - "[[05-CONFIGURATIONS/validation/orchestrator-engine.sh]]"
checksum_sha256: "PENDING_GENERATION"
---

# 📄 01-RULES/validation-checklist.md – REGENERADO COMPLETO v3.0-SELECTIVE

> **Nota para principiantes:** Este documento es el **checklist ejecutable de validación** para todo artefacto en MANTIS AGENTIC. Define QUÉ verificar, CÓMO verificarlo y CUÁNDO un artefacto está listo para entrega. Si eres nuevo, lee las secciones en orden. Si eres experto, salta al JSON final.  
>  
> **Para IAs:** Este es tu contrato de calidad. **ENTREGAR SIN VALIDAR = DEUDA TÉCNICA AUTOMÁTICA**. No inventes, no asumas, no omitas.



# ✅ VALIDATION-CHECKLIST: Checklist Ejecutable de Validación para Artefactos MANTIS

<!-- 
【PARA PRINCIPIANTES】¿Qué es este archivo?
Este documento es el "examen final" de todo artefacto en el proyecto MANTIS AGENTIC.
Define una lista verificable de ítems que TODO artefacto debe aprobar antes de ser considerado válido.

Si eres nuevo: lee en orden. 
Si ya conoces el proyecto: usa los wikilinks para ir directo a lo que necesitas.
-->

> **Instrucción crítica para la IA:** 
> Este documento es tu contrato de calidad. 
> **ENTREGAR SIN VALIDAR = DEUDA TÉCNICA AUTOMÁTICA**. 
> No inventes, no asumas, no omitas. Si algo no está claro, DETENER y preguntar.

---

## 【0】🎯 PROPÓSITO Y ALCANCE (Explicado para humanos)

<!-- 
【EDUCATIVO】Este documento responde: "¿Cómo sé si mi artefacto está listo para entregar?"
No es una lista de deseos. Es un sistema de validación ejecutable que:
• Proporciona checklist verificable paso a paso para cada Tier (1/2/3)
• Conecta cada ítem con herramientas automáticas de validación (`orchestrator-engine.sh`, etc.)
• Define criterios de aceptación claros: score mínimo, blocking_issues, language_lock_violations
• Permite validación manual y automática para redundancia y seguridad
-->

### 0.1 Arquitectura de Validación en MANTIS AGENTIC

```mermaid
graph LR
    A[Artefacto Generado] --> B[Checklist Manual]
    A --> C[Validación Automática]
    
    B --> D[Verificar frontmatter, estructura, ejemplos]
    C --> E[Ejecutar orchestrator-engine.sh --json]
    
    D --> F{¿Pasa checklist manual?}
    E --> G{¿Pasa validación automática?}
    
    F -->|Sí| H[Proceed to delivery]
    F -->|No| I[Iterar corrección]
    
    G -->|Sí| H
    G -->|No| I
    
    H --> J[Entrega según Tier: pantalla/código/ZIP]
    I --> K[Corregir y re-validar (máx 3 intentos)]
    
    style J fill:#c8e6c9
    style K fill:#ffcdd2
```

### 0.2 Niveles de Validación por Tier

| Tier | Nombre | Checklist Requerido | Score Mínimo | blocking_issues | Herramienta Principal |
|------|--------|-------------------|-------------|----------------|---------------------|
| **1** | Documentación / Propuesta | Frontmatter válido, wikilinks canónicos, estructura SDD básica | ≥ 15 | Solo warnings permitidos | `validate-frontmatter.sh` + `check-wikilinks.sh` |
| **2** | Código Validable | Todo Tier 1 + ≥10 ejemplos ✅/❌/🔧, validation_command ejecutable, checksum | ≥ 30 | Debe estar vacío | `orchestrator-engine.sh --checks C1-C8` |
| **3** | Paquete Desplegable | Todo Tier 2 + bundle completo, manifest.json, deploy.sh, rollback.sh, healthcheck | ≥ 45 | Debe estar vacío | `orchestrator-engine.sh --bundle --checksum` + `packager-assisted.sh` |

> 💡 **Consejo para principiantes**: No intentes saltar Tiers. Cada Tier es un escalón: valida Tier 1 primero, luego Tier 2, luego Tier 3. La madurez se gana con validación, no con prisa.

---

## 【1】🔒 CHECKLIST EJECUTABLE POR TIER (VC-001 a VC-030)

<!-- 
【EDUCATIVO】Estos 30 ítems son contractuales. 
Cada artefacto debe aprobar los ítems correspondientes a su Tier antes de entregar.
-->

### ✅ TIER 1: Checklist de Documentación / Propuesta (VC-001 a VC-010)

```
【VC-001】Frontmatter YAML válido al inicio del archivo
✅ Cumplimiento:
---
canonical_path: "/ruta/canónica/exacta/desde/raíz.md"
artifact_id: "identificador-único"
artifact_type: "documentation|skill_go|etc"
version: "1.0.0"
constraints_mapped: ["C3","C4","C5"]
---
❌ Violación: YAML con sintaxis inválida, campos faltantes (`canonical_path`, `constraints_mapped`)
🔧 Validación: `yq eval '.canonical_path' <archivo> | grep -q "/"`

【VC-002】canonical_path es ruta absoluta desde raíz (no relativa)
✅ Cumplimiento: `canonical_path: "/06-PROGRAMMING/go/example.go.md"`
❌ Violación: `canonical_path: "../otra-carpeta/example.md"` o sin slash inicial
🔧 Validación: `yq eval '.canonical_path' <archivo> | grep -q '^/'`

【VC-003】constraints_mapped es subconjunto de norms-matrix[carpeta].allowed
✅ Cumplimiento: Consultar `norms-matrix.json` para la carpeta destino
❌ Violación: Declarar `["C9"]` o constraint no mapeada
🔧 Validación: `bash 05-CONFIGURATIONS/validation/verify-constraints.sh --file <archivo> --json`

【VC-004】Estructura de secciones sigue orden SDD canónico
✅ Cumplimiento: Propósito → Implementación → Ejemplos → Validación → Referencias
❌ Violación: Secciones fuera de orden o faltantes
🔧 Validación: Revisión manual + `grep -E "^## 【[0-9】】" <archivo>`

【VC-005】Wikilinks son canónicos: [[RUTA/DESDE/RAÍZ.md]], nunca relativos
✅ Cumplimiento: `[[00-STACK-SELECTOR]]`, `[[PROJECT_TREE.md]]`
❌ Violación: `[[../otra]]`, `[[./local]]`, `[[archivo#ancla]]`
🔧 Validación: `bash 05-CONFIGURATIONS/validation/check-wikilinks.sh --file <archivo> --json`

【VC-006】Fences de código declaran lenguaje: ```bash, ```python, ```go, etc.
✅ Cumplimiento: ```go, ```python, ```sql, ```json, ```yaml
❌ Violación: ``` sin lenguaje o lenguaje inventado
🔧 Validación: `grep -E '^```[a-z]+' <archivo> | wc -l` vs total fences

【VC-007】No hay código ejecutable sin validación de seguridad (C3)
✅ Cumplimiento: Cero `password = "xxx"`, cero API keys hardcodeadas
❌ Violación: Secrets en texto plano en código, config o logs
🔧 Validación: `bash 05-CONFIGURATIONS/validation/audit-secrets.sh --file <archivo> --json`

【VC-008】No hay queries SQL sin filtro tenant_id si aplica C4
✅ Cumplimiento: `WHERE tenant_id = $1` en todas las queries que acceden a datos
❌ Violación: Query sin aislamiento multi-tenant cuando el artefacto maneja datos de usuario
🔧 Validación: `bash 05-CONFIGURATIONS/validation/check-rls.sh --file <archivo> --json`

【VC-009】Nota de estado de revisión presente según Tier
✅ Cumplimiento: Para Tier 1: `⚠️ Requiere revisión humana antes de usar`
❌ Violación: Entregar Tier 1 como si fuera código listo para producción
🔧 Validación: Revisión manual de nota final del artefacto

【VC-010】validation_command presente y ejecutable (aunque sea para Tier 1)
✅ Cumplimiento: `validation_command: "bash .../orchestrator-engine.sh --file <ruta> --json"`
❌ Violación: Campo faltante o comando con ruta inexistente
🔧 Validación: `yq eval '.validation_command' <archivo> | grep -q "orchestrator-engine.sh"`
```

### ✅ TIER 2: Checklist de Código Validable (VC-011 a VC-020)

```
【VC-011】Todo lo de Tier 1 + frontmatter con tier: 2 y ejemplos_count ≥ 10
✅ Cumplimiento: `tier: 2`, `examples_count: 12` en frontmatter
❌ Violación: tier: 2 pero ejemplos_count < 10 o campo faltante
🔧 Validación: `yq eval '.examples_count' <archivo> | awk '{if($1>=10) print "✅" else print "❌"}'`

【VC-012】≥10 ejemplos en formato ✅/❌/🔧 con casos reales
✅ Cumplimiento: Tabla o lista con al menos 10 filas de ejemplos buenos/malos/corrección
❌ Violación: Menos de 10 ejemplos o ejemplos genéricos sin contexto real
🔧 Validación: `grep -c '✅\|❌\|🔧' <archivo> | awk '{if($1>=10) print "✅" else print "❌"}'`

【VC-013】checksum_sha256 presente y coincide con contenido del archivo
✅ Cumplimiento: `checksum_sha256: "sha256:abc123..."` calculado post-generación
❌ Violación: Checksum faltante o que no coincide con `sha256sum <archivo>`
🔧 Validación: `sha256sum <archivo> | grep -q "$(yq eval '.checksum_sha256' <archivo>)"`

【VC-014】validation_command es ejecutable y retorna exit code significativo
✅ Cumplimiento: Comando que se puede copiar/pegar y ejecutar sin modificaciones
❌ Violación: Comando con rutas relativas, flags inválidos o que siempre retorna 0
🔧 Validación: Ejecutar comando en entorno de prueba y verificar exit code ≠ 0 en fallo

【VC-015】Código pasa linter del lenguaje sin errors (solo warnings permitidos)
✅ Cumplimiento: `go fmt`, `flake8`, `shellcheck`, `eslint` sin errors
❌ Violación: Linter reporta errors que bloquean compilación/ejecución
🔧 Validación: Ejecutar linter correspondiente al lenguaje del artefacto

【VC-016】No hay imports o dependencias no declaradas o con versiones flotantes
✅ Cumplimiento: `go.mod`, `requirements.txt`, `package.json` con versiones fijas
❌ Violación: `import "github.com/user/repo"` sin versión o `pip install package` sin hash
🔧 Validación: `govulncheck`, `pip-audit`, `npm audit` según lenguaje

【VC-017】Funciones/métodos tienen documentación de contrato (input/output)
✅ Cumplimiento: Docstrings, comentarios de firma, o schema JSON para APIs
❌ Violación: Función sin documentación de qué espera y qué retorna
🔧 Validación: Revisión manual + `grep -c "Args:\|Returns:\|schema" <archivo>`

【VC-018】Manejo explícito de errores con fallback o retry (C7)
✅ Cumplimiento: `try/except`, `if err != nil`, `trap cleanup` con fallback definido
❌ Violación: Ignorar errores con `pass`, `/* ignore */`, o crashear sin recuperación
🔧 Validación: Revisión manual de patrones de error handling + tests de resiliencia

【VC-019】Logging estructurado con tenant_id y trace_id si aplica (C8)
✅ Cumplimiento: Logs JSON con campos obligatorios: timestamp, level, event, tenant_id, trace_id
❌ Violación: `print()`, `console.log()` sin estructura o sin campos de trazabilidad
🔧 Validación: `bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --checks C8 --file <archivo> --json`

【VC-020】Score de orchestrator-engine.sh ≥ 30 y blocking_issues == []
✅ Cumplimiento: Ejecutar validación integral y verificar resultado
❌ Violación: Score < 30 o blocking_issues no vacío
🔧 Validación: `bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file <archivo> --json | jq '.score, .blocking_issues'`
```

### ✅ TIER 3: Checklist de Paquete Desplegable (VC-021 a VC-030)

```
【VC-021】Todo lo de Tier 2 + frontmatter con tier: 3 y bundle_required: true
✅ Cumplimiento: `tier: 3`, `bundle_required: true` en frontmatter
❌ Violación: tier: 3 pero bundle_required: false o campo faltante
🔧 Validación: `yq eval '.bundle_required' <archivo> | grep -q "true"`

【VC-022】bundle_contents lista todos los archivos requeridos en el ZIP
✅ Cumplimiento: `bundle_contents: ["manifest.json", "deploy.sh", "rollback.sh", "healthcheck.sh", "README-DEPLOY.md"]`
❌ Violación: Archivo crítico faltante en la lista o en el bundle real
🔧 Validación: Comparar lista en frontmatter con archivos generados en bundle/

【VC-023】manifest.json válido con metadatos canónicos del paquete
✅ Cumplimiento: JSON con artifact_id, version, tier, validation_result, checksum, deploy_command
❌ Violación: manifest.json con sintaxis inválida o campos obligatorios faltantes
🔧 Validación: `jq empty manifest.json && jq '.artifact_id, .version, .tier' manifest.json`

【VC-024】deploy.sh es idempotente y soporta --dry-run
✅ Cumplimiento: Script que verifica estado actual antes de modificar, con flag --dry-run
❌ Violación: Script que crea duplicados al ejecutarse dos veces o sin opción de simulación
🔧 Validación: Ejecutar `./deploy.sh --dry-run` y luego `./deploy.sh` dos veces, verificar idempotencia

【VC-025】rollback.sh revierte cambios de deploy.sh sin pérdida de datos
✅ Cumplimiento: Script que restaura estado previo usando backups o versionado
❌ Violación: rollback.sh que no funciona o que pierde datos al revertir
🔧 Validación: Ejecutar deploy.sh → rollback.sh → verificar que sistema vuelve a estado inicial

【VC-026】healthcheck.sh verifica salud del servicio desplegado
✅ Cumplimiento: Script que retorna exit code 0 si servicio está sano, 1 si no
❌ Violación: healthcheck.sh que siempre retorna 0 o que no verifica dependencias críticas
🔧 Validación: Ejecutar healthcheck.sh con servicio up/down y verificar exit codes

【VC-027】README-DEPLOY.md con instrucciones claras para el cliente
✅ Cumplimiento: Documento con: requisitos previos, pasos de deploy, comandos de rollback, troubleshooting
❌ Violación: README genérico o sin pasos ejecutables específicos para este paquete
🔧 Validación: Revisión manual de claridad y completitud de instrucciones

【VC-028】checksums.sha256 con hashes válidos para todos los archivos del bundle
✅ Cumplimiento: Archivo con `sha256sum <file>` para cada archivo en bundle_contents
❌ Violación: Checksum faltante para algún archivo o hash que no coincide
🔧 Validación: `sha256sum -c checksums.sha256` en directorio del bundle

【VC-029】Score de orchestrator-engine.sh ≥ 45 y blocking_issues == [] para Tier 3
✅ Cumplimiento: Validación integral con flags --bundle --checksum retorna score alto
❌ Violación: Score < 45 o blocking_issues no vacío para artefacto Tier 3
🔧 Validación: `bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file <archivo> --bundle --checksum --json | jq '.score, .blocking_issues'`

【VC-030】packager-assisted.sh genera bundle válido y reproducible
✅ Cumplimiento: Script de empaquetado que crea ZIP con estructura canónica y checksums
❌ Violación: packager-assisted.sh que omite archivos críticos o genera checksums inconsistentes
🔧 Validación: Ejecutar `bash 05-CONFIGURATIONS/scripts/packager-assisted.sh --source <archivo> --dry-run` y verificar estructura
```

---

## 【2】🛡️ VALIDACIÓN AUTOMÁTICA DEL CHECKLIST

<!-- 
【EDUCATIVO】Herramientas y comandos para validar automáticamente los ítems del checklist.
-->

### 2.1 orchestrator-engine.sh – Validación Integral con Scoring

```bash
# 📍 Ubicación
05-CONFIGURATIONS/validation/orchestrator-engine.sh

# 🎯 Propósito
Validar artefacto contra checklist completo, calcular score y detectar blocking_issues.

# 📦 Flags Principales
--file <ruta>              # Artefacto a validar
--mode <headless|interactive>  # headless para CI/CD
--json                     # Salida en formato JSON para parsing
--checks <C1,C2,...>       # Constraints específicas a validar (default: todas aplicables)
--bundle                   # Validar estructura de bundle para Tier 3
--checksum                 # Calcular y verificar checksums SHA256

# ✅ Ejemplo: Validar artefacto Tier 2
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/go/webhook-handler.go.md \
  --mode headless \
  --json

# 📤 Salida Esperada (JSON)
{
  "file": "06-PROGRAMMING/go/webhook-handler.go.md",
  "tier_validated": "tier2-code",
  "score": 42,
  "passed": true,
  "constraints_applied": ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8"],
  "constraints_failed": [],
  "blocking_issues": [],
  "warnings": ["C2: timeout no especificado en función X, se asume default 30s"],
  "language_lock_violations": 0,
  "validation_profile_used": "tier2-code",
  "validation_timestamp": "2026-04-19T12:05:00Z",
  "artifact_checksum": "sha256:abc123...",
  "checklist_items": {
    "VC-001": {"status": "passed", "details": "frontmatter YAML válido"},
    "VC-002": {"status": "passed", "details": "canonical_path absoluto"},
    "VC-012": {"status": "passed", "details": "12 ejemplos ✅/❌/🔧 encontrados"},
    "VC-020": {"status": "passed", "details": "score=42 >= 30, blocking_issues=[]"}
  },
  "next_steps": ["✅ Artefacto aprobado para Tier 2. Entregar con validation_command + checksum."]
}

# ⚠️ Criterios de Aceptación por Tier
| Tier | Score Mínimo | blocking_issues | language_lock_violations |
|------|-------------|-----------------|-------------------------|
| 1    | ≥ 15        | vacío o warnings| 0                       |
| 2    | ≥ 30        | vacío           | 0                       |
| 3    | ≥ 45        | vacío           | 0                       |
```

### 2.2 validate-frontmatter.sh – Validación Rápida de Estructura

```bash
# 📍 Ubicación
05-CONFIGURATIONS/validation/validate-frontmatter.sh

# 🎯 Propósito
Validar que frontmatter YAML es sintácticamente válido y tiene campos obligatorios por Tier.

# 📦 Flags Principales
--file <ruta>              # Archivo Markdown a validar
--level <1|2|3>            # Nivel de especificación: 1=base, 2=código, 3=paquete
--required-fields <lista>  # Campos adicionales requeridos (separados por comas)
--json                     # Salida en formato JSON

# ✅ Ejemplo: Validar frontmatter Tier 2
bash 05-CONFIGURATIONS/validation/validate-frontmatter.sh \
  --file 06-PROGRAMMING/go/webhook-handler.go.md \
  --level 2 \
  --json

# 📤 Salida Esperada (JSON)
{
  "file": "06-PROGRAMMING/go/webhook-handler.go.md",
  "frontmatter_valid": true,
  "yaml_syntax_ok": true,
  "required_fields_present": ["canonical_path", "artifact_id", "artifact_type", "version", "constraints_mapped", "validation_command", "tier", "mode_selected", "prompt_hash", "generated_at"],
  "missing_fields": [],
  "extra_fields": [],
  "passed": true
}
```

### 2.3 check-wikilinks.sh – Validación de Enlaces Canónicos

```bash
# 📍 Ubicación
05-CONFIGURATIONS/validation/check-wikilinks.sh

# 🎯 Propósito
Validar que todos los wikilinks `[[RUTA]]` son canónicos (absolutos desde raíz) y apuntan a archivos existentes.

# 📦 Flags Principales
--file <ruta>              # Archivo Markdown a validar
--project-tree <archivo>   # Ruta a PROJECT_TREE.md (default: PROJECT_TREE.md)
--allow-external           # Permitir wikilinks a URLs externas (https://...)
--json                     # Salida en formato JSON

# ✅ Ejemplo: Validar wikilinks en archivo
bash 05-CONFIGURATIONS/validation/check-wikilinks.sh \
  --file 01-RULES/validation-checklist.md \
  --project-tree PROJECT_TREE.md \
  --json

# 📤 Salida Esperada (JSON)
{
  "file": "01-RULES/validation-checklist.md",
  "wikilinks_found": 24,
  "wikilinks_canonical": 24,
  "wikilinks_relative": 0,
  "wikilinks_broken": 0,
  "findings": [],
  "passed": true,
  "recommendation": "✅ Todos los wikilinks son canónicos y apuntan a archivos existentes."
}
```

---

## 【3】🧭 PROTOCOLO DE VALIDACIÓN PRE-ENTREGA (PASO A PASO)

<!-- 
【EDUCATIVO】Flujo determinista que DEBE seguir cualquier artefacto antes de entregar.
Mismos inputs → mismos outputs. Si algo no está claro, DETENER y preguntar.
-->

```
┌─────────────────────────────────────────────────────────┐
│ 【PASO 0】CONFIRMAR TIER Y MODO                        │
├─────────────────────────────────────────────────────────┤
│ 1. Verificar que mode_selected está confirmado en IA-QUICKSTART │
│ 2. Determinar Tier según mapeo: A1/B1→1, A2/B2→2, A3/B3→3 │
│ 3. Registrar tier en frontmatter del artefacto         │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 1】VALIDACIÓN MANUAL DEL CHECKLIST              │
├─────────────────────────────────────────────────────────┤
│ 4. Ejecutar checklist correspondiente al Tier:         │
│    • Tier 1: VC-001 a VC-010                           │
│    • Tier 2: VC-001 a VC-020                           │
│    • Tier 3: VC-001 a VC-030                           │
│ 5. Marcar cada ítem como ✅/❌ con evidencia            │
│ 6. Si algún ítem crítico falla → iterar corrección    │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 2】VALIDACIÓN AUTOMÁTICA CON TOOLCHAIN          │
├─────────────────────────────────────────────────────────┤
│ 7. Ejecutar validate-frontmatter.sh --level <tier>     │
│ 8. Ejecutar check-wikilinks.sh                         │
│ 9. Ejecutar audit-secrets.sh (si aplica C3)            │
│ 10. Ejecutar check-rls.sh (si aplica C4 y es SQL)      │
│ 11. Ejecutar verify-constraints.sh --check-language-lock│
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 3】SCORING INTEGRAL CON ORCHESTRATOR           │
├─────────────────────────────────────────────────────────┤
│ 12. Ejecutar: orchestrator-engine.sh --file <ruta> --json│
│ 13. Verificar: score >= mínimo para Tier, blocking_issues == []│
│ 14. Si falla → iterar corrección (máx 3 intentos)      │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【PASO 4】ENTREGA SEGÚN TIER + AUDITORÍA              │
├─────────────────────────────────────────────────────────┤
│ 15. Formato de entrega:                                │
│    • Tier 1: Pantalla + nota "Requiere revisión humana"│
│    • Tier 2: Código + validation_command + checksum    │
│    • Tier 3: ZIP con manifest + deploy.sh + rollback.sh│
│ 16. Registrar log de auditoría con prompt_hash, tenant_id, trace_id│
└─────────────────────────────────────────────────────────┘
```

### 3.1 Ejemplo de Traza de Validación Pre-Entrega

```
【TRAZA DE VALIDACIÓN PRE-ENTREGA】
Artefacto: `06-PROGRAMMING/python/rag-query.md`, Tier 2

Paso 0 - Confirmar Tier:
  • mode_selected: "B2" confirmado en IA-QUICKSTART ✅
  • Mapeo: B2 → Tier 2 ✅
  • Frontmatter: tier: 2 registrado ✅

Paso 1 - Checklist manual (VC-001 a VC-020):
  • VC-001: Frontmatter YAML válido ✅
  • VC-002: canonical_path absoluto ✅
  • VC-012: 14 ejemplos ✅/❌/🔧 encontrados ✅
  • VC-020: orchestrator-engine.sh --json retorna score=38, passed=true ✅
  • Todos los ítems Tier 2 aprobados ✅

Paso 2 - Validación automática:
  • validate-frontmatter.sh --level 2 → passed ✅
  • check-wikilinks.sh → 24 wikilinks canónicos, 0 rotos ✅
  • audit-secrets.sh → 0 secrets hardcodeados ✅
  • verify-constraints.sh --check-language-lock → 0 violaciones ✅

Paso 3 - Scoring integral:
  • orchestrator-engine.sh --json → score=38 >= 30, blocking_issues=[] ✅
  • language_lock_violations: 0 ✅

Paso 4 - Entrega Tier 2:
  • Formato: código fuente + validation_command + checksum_sha256 ✅
  • Log auditoría: {"event":"artifact_delivered","tier":2,"score":38,"tenant_id":"cli_001"} ✅

Resultado: ✅ Artefacto certificado para Tier 2, listo para integración.
```

---

## 【4】📚 GLOSARIO PARA PRINCIPIANTES

<!-- 
【EDUCATIVO】Términos técnicos explicados en lenguaje simple.
-->

| Término | Significado simple | Ejemplo |
|---------|-------------------|---------|
| **Tier 1/2/3** | Niveles de madurez: 1=borrador, 2=código listo, 3=paquete desplegable | Tier 2 → código con validation_command y checksum |
| **blocking_issue** | Error que impide la entrega hasta que se corrige | `C3_VIOLATION: API key hardcodeada` |
| **score** | Puntuación de calidad del artefacto (0-100) | Score 42 ≥ 30 → aprobado para Tier 2 |
| **canonical_path** | Ruta absoluta desde raíz del repositorio | `/06-PROGRAMMING/python/rag-query.md` |
| **wikilink canónico** | Enlace interno con ruta absoluta, nunca relativa | `[[PROJECT_TREE.md]]` (no `[[../PROJECT_TREE.md]]`) |
| **checksum SHA256** | Hash que verifica que un archivo no fue modificado | `sha256:abc123...` para verificar integridad |
| **idempotente** | Script que puede ejecutarse múltiples veces sin efectos secundarios | `deploy.sh` que verifica si ya está instalado antes de instalar |
| **dry-run** | Ejecutar comando en modo simulación, sin cambios reales | `./deploy.sh --dry-run` para probar sin desplegar |
| **PII scrubbing** | Reemplazar datos personales por `***REDACTED***` en logs | Log: `user_email=***REDACTED***` en lugar de valor real |
| **LANGUAGE LOCK** | Regla que prohíbe ciertos operadores en ciertos lenguajes | No usar `<->` en `go/`, solo en `postgresql-pgvector/` |

---

## 【5】🧪 SANDBOX DE PRUEBA (OPCIONAL)

<!-- 
【PARA DESARROLLADORES】Pega esta sección en un chat nuevo para validar que la IA sigue el protocolo sin contexto previo.
-->

```
【TEST MODE: VALIDATION-CHECKLIST VALIDATION】
Prompt de prueba: "Validar artefacto de webhook seguro en TypeScript para Tier 2"

Respuesta esperada de la IA:
1. Confirmar Tier: mode_selected "B2" → Tier 2
2. Ejecutar checklist manual VC-001 a VC-020:
   • Verificar frontmatter YAML válido (VC-001)
   • Verificar canonical_path absoluto (VC-002)
   • Verificar ≥10 ejemplos ✅/❌/🔧 (VC-012)
   • Verificar validation_command ejecutable (VC-014)
3. Ejecutar validación automática:
   • validate-frontmatter.sh --level 2
   • check-wikilinks.sh
   • audit-secrets.sh (para C3)
   • verify-constraints.sh --check-language-lock
4. Ejecutar orchestrator-engine.sh --json y verificar score >= 30, blocking_issues == []
5. Si pasa → entregar con formato Tier 2: código + validation_command + checksum
6. Si falla → iterar corrección (máx 3 intentos) con sugerencias específicas

Si la IA omite validación automática, entrega sin checksum, o ignora blocking_issues → FALLA DE VALIDACIÓN.
```

---

## 【6】🔗 REFERENCIAS CANÓNICAS (WIKILINKS)

<!-- 
【PARA IA】Estos enlaces deben resolverse usando PROJECT_TREE.md. 
No uses rutas relativas. Usa siempre la forma canónica [[RUTA]].
-->

- `[[01-RULES/harness-norms-v3.0.md]]` → Definición canónica de constraints C1-C8, V1-V3
- `[[05-CONFIGURATIONS/validation/norms-matrix.json]]` → Mapeo de constraints por carpeta
- `[[GOVERNANCE-ORCHESTRATOR.md]]` → Tiers, validación y formatos de entrega
- `[[SDD-COLLABORATIVE-GENERATION.md]]` → Especificación de formato de artefactos
- `[[TOOLCHAIN-REFERENCE.md]]` → Catálogo de herramientas de validación
- `[[05-CONFIGURATIONS/validation/orchestrator-engine.sh]]` → Motor principal de validación
- `[[05-CONFIGURATIONS/validation/validate-frontmatter.sh]]` → Validador de frontmatter YAML
- `[[05-CONFIGURATIONS/validation/check-wikilinks.sh]]` → Validador de wikilinks canónicos
- `[[PROJECT_TREE]]` → Mapa canónico de rutas para resolución de wikilinks
- `[[00-STACK-SELECTOR]]` → Motor de decisión de stack por ruta

---

## 【7】📦 METADATOS DE EXPANSIÓN (PARA FUTURAS VERSIONES)

<!-- 
【PARA MANTENEDORES】Nuevas secciones deben seguir este formato para no romper compatibilidad.
-->

```json
{
  "expansion_registry": {
    "new_checklist_item": {
      "requires_files_update": [
        "01-RULES/validation-checklist.md: add item with format ## 【VC-XXX】<TÍTULO>",
        "GOVERNANCE-ORCHESTRATOR.md: update tier definitions if item affects scoring",
        "05-CONFIGURATIONS/validation/: add validation logic if item requires new tool",
        "Human approval required: true"
      ],
      "backward_compatibility": "new checklist items must not invalidate existing artifacts that passed previous version; apply only to new generations"
    },
    "new_validation_tool": {
      "requires_files_update": [
        "01-RULES/validation-checklist.md: integrate new tool in validation steps",
        "TOOLCHAIN-REFERENCE.md: document new tool with examples",
        "orchestrator-engine.sh: integrate new check in scoring logic",
        "CI/CD: add new tool to validation pipeline",
        "Human approval required: true"
      ],
      "backward_compatibility": "new tools must support existing artifact formats via optional flags; not break existing validation flows"
    }
  },
  "compatibility_rule": "Nuevos ítems de checklist no deben invalidar artefactos generados bajo versiones anteriores. Cambios breaking requieren major version bump, guía de migración y aprobación humana explícita."
}
```

---

<!-- 
═══════════════════════════════════════════════════════════
🤖 SECCIÓN PARA IA: ÁRBOL JSON ENRIQUECIDO
═══════════════════════════════════════════════════════════
Esta sección contiene metadatos estructurados para consumo automático por agentes de IA.
No está diseñada para lectura humana directa. Los humanos deben usar las secciones 【1】-【7】.

Formato: JSON válido, con comentarios explicativos en claves "doc_*".
Prioridad de ejecución: Los ítems de checklist se validan en orden VC-001 → VC-030.
Dependencias: Cada nodo declara sus archivos requeridos y sus efectos colaterales.
═══════════════════════════════════════════════════════════
-->

```json
{
  "validation_checklist_metadata": {
    "version": "3.0.0-SELECTIVE",
    "canonical_path": "/01-RULES/validation-checklist.md",
    "artifact_type": "governance_checklist",
    "immutable": true,
    "requires_human_approval_for_changes": true,
    "constraints_primary": ["C5", "C6"],
    "llm_optimizations": {
      "oriental_models_friendly": true,
      "delimiters_used": ["【】", "┌─┐", "▼", "✅/❌/🔧"],
      "numbered_sequences": true,
      "stop_conditions_explicit": true
    }
  },
  
  "checklist_items_catalog": {
    "tier_1_items": {
      "VC-001": {"title": "Frontmatter YAML válido", "constraint": "C5", "priority": "critical", "blocking_if_failed": true, "validation_tool": "validate-frontmatter.sh"},
      "VC-002": {"title": "canonical_path absoluto", "constraint": "C5", "priority": "critical", "blocking_if_failed": true, "validation_tool": "yq eval + regex"},
      "VC-003": {"title": "constraints_mapped ⊆ norms-matrix.allowed", "constraint": "C5", "priority": "critical", "blocking_if_failed": true, "validation_tool": "verify-constraints.sh"},
      "VC-004": {"title": "Estructura SDD en orden canónico", "constraint": "C5", "priority": "high", "blocking_if_failed": false, "validation_tool": "manual review + grep"},
      "VC-005": {"title": "Wikilinks canónicos", "constraint": "C5", "priority": "high", "blocking_if_failed": true, "validation_tool": "check-wikilinks.sh"},
      "VC-006": {"title": "Fences de código con lenguaje", "constraint": "C5", "priority": "medium", "blocking_if_failed": false, "validation_tool": "grep + count"},
      "VC-007": {"title": "Cero secrets hardcodeados (C3)", "constraint": "C3", "priority": "critical", "blocking_if_failed": true, "validation_tool": "audit-secrets.sh"},
      "VC-008": {"title": "Queries con tenant_id si aplica C4", "constraint": "C4", "priority": "critical", "blocking_if_failed": true, "validation_tool": "check-rls.sh"},
      "VC-009": {"title": "Nota de estado de revisión presente", "constraint": "C6", "priority": "medium", "blocking_if_failed": false, "validation_tool": "manual review"},
      "VC-010": {"title": "validation_command presente y ejecutable", "constraint": "C6", "priority": "high", "blocking_if_failed": true, "validation_tool": "yq eval + command execution test"}
    },
    "tier_2_items": {
      "VC-011": {"title": "tier: 2 + ejemplos_count ≥ 10", "constraint": "C5", "priority": "high", "blocking_if_failed": true, "validation_tool": "yq eval + awk"},
      "VC-012": {"title": "≥10 ejemplos ✅/❌/🔧 con casos reales", "constraint": "C5", "priority": "high", "blocking_if_failed": false, "validation_tool": "grep count"},
      "VC-013": {"title": "checksum_sha256 válido", "constraint": "C5", "priority": "critical", "blocking_if_failed": true, "validation_tool": "sha256sum verification"},
      "VC-014": {"title": "validation_command ejecutable con exit code significativo", "constraint": "C6", "priority": "critical", "blocking_if_failed": true, "validation_tool": "command execution test"},
      "VC-015": {"title": "Código pasa linter sin errors", "constraint": "C5", "priority": "high", "blocking_if_failed": false, "validation_tool": "language-specific linter"},
      "VC-016": {"title": "Dependencias declaradas con versiones fijas", "constraint": "C1", "priority": "medium", "blocking_if_failed": false, "validation_tool": "govulncheck/pip-audit/npm audit"},
      "VC-017": {"title": "Funciones con documentación de contrato", "constraint": "C5", "priority": "medium", "blocking_if_failed": false, "validation_tool": "manual review + grep"},
      "VC-018": {"title": "Manejo explícito de errores con fallback/retry", "constraint": "C7", "priority": "high", "blocking_if_failed": false, "validation_tool": "manual review + resilience tests"},
      "VC-019": {"title": "Logging estructurado con tenant_id y trace_id", "constraint": "C8", "priority": "high", "blocking_if_failed": false, "validation_tool": "orchestrator-engine.sh --checks C8"},
      "VC-020": {"title": "Score ≥ 30 y blocking_issues == []", "constraint": "C6", "priority": "critical", "blocking_if_failed": true, "validation_tool": "orchestrator-engine.sh --json"}
    },
    "tier_3_items": {
      "VC-021": {"title": "tier: 3 + bundle_required: true", "constraint": "C5", "priority": "critical", "blocking_if_failed": true, "validation_tool": "yq eval"},
      "VC-022": {"title": "bundle_contents lista archivos requeridos", "constraint": "C5", "priority": "high", "blocking_if_failed": true, "validation_tool": "frontmatter vs bundle directory comparison"},
      "VC-023": {"title": "manifest.json válido con metadatos canónicos", "constraint": "C5", "priority": "critical", "blocking_if_failed": true, "validation_tool": "jq empty + field validation"},
      "VC-024": {"title": "deploy.sh idempotente + --dry-run", "constraint": "C6", "priority": "critical", "blocking_if_failed": true, "validation_tool": "idempotency test + dry-run execution"},
      "VC-025": {"title": "rollback.sh revierte cambios sin pérdida de datos", "constraint": "C7", "priority": "critical", "blocking_if_failed": true, "validation_tool": "deploy → rollback → state verification"},
      "VC-026": {"title": "healthcheck.sh verifica salud del servicio", "constraint": "C7", "priority": "high", "blocking_if_failed": false, "validation_tool": "healthcheck execution with service up/down"},
      "VC-027": {"title": "README-DEPLOY.md con instrucciones claras", "constraint": "C6", "priority": "medium", "blocking_if_failed": false, "validation_tool": "manual review for clarity and completeness"},
      "VC-028": {"title": "checksums.sha256 con hashes válidos", "constraint": "C5", "priority": "critical", "blocking_if_failed": true, "validation_tool": "sha256sum -c verification"},
      "VC-029": {"title": "Score ≥ 45 y blocking_issues == [] para Tier 3", "constraint": "C6", "priority": "critical", "blocking_if_failed": true, "validation_tool": "orchestrator-engine.sh --bundle --checksum --json"},
      "VC-030": {"title": "packager-assisted.sh genera bundle válido", "constraint": "C5", "priority": "high", "blocking_if_failed": false, "validation_tool": "packager-assisted.sh --dry-run + structure validation"}
    }
  },
  
  "validation_integration": {
    "orchestrator-engine.sh": {
      "purpose": "Validación integral con scoring y reporte JSON",
      "flags": ["--file", "--mode", "--json", "--checks", "--bundle", "--checksum"],
      "exit_codes": {"0": "passed", "1": "failed"},
      "output_format": "JSON con score, passed, blocking_issues, checklist_items"
    },
    "validate-frontmatter.sh": {
      "purpose": "Validar estructura YAML y campos obligatorios",
      "flags": ["--file", "--level", "--required-fields", "--json"],
      "exit_codes": {"0": "valid", "1": "invalid"},
      "output_format": "JSON con frontmatter_valid, required_fields_present, missing_fields"
    },
    "check-wikilinks.sh": {
      "purpose": "Validar wikilinks canónicos",
      "flags": ["--file", "--project-tree", "--allow-external", "--json"],
      "exit_codes": {"0": "all_canonical", "1": "relative_or_broken_found"},
      "output_format": "JSON con wikilinks_found, wikilinks_canonical, wikilinks_broken"
    },
    "audit-secrets.sh": {
      "purpose": "Detectar secrets hardcodeados (C3)",
      "flags": ["--file", "--dir", "--patterns", "--strict", "--json"],
      "exit_codes": {"0": "no_secrets_found", "1": "secrets_detected"},
      "output_format": "JSON con secrets_found, patterns_checked, findings"
    },
    "check-rls.sh": {
      "purpose": "Validar tenant isolation en SQL (C4)",
      "flags": ["--file", "--dir", "--tenant-column", "--strict", "--json"],
      "exit_codes": {"0": "rls_compliant", "1": "rls_violation"},
      "output_format": "JSON con queries_analyzed, queries_with_tenant_filter"
    },
    "verify-constraints.sh": {
      "purpose": "Validar constraints y LANGUAGE LOCK",
      "flags": ["--file", "--dir", "--check-language-lock", "--check-constraint", "--json"],
      "exit_codes": {"0": "compliant", "1": "violation"},
      "output_format": "JSON con constraints_validated, language_lock.violations"
    }
  },
  
  "dependency_graph": {
    "critical_infrastructure": [
      {"file": "GOVERNANCE-ORCHESTRATOR.md", "purpose": "Definición de Tiers y scoring", "load_order": 1},
      {"file": "05-CONFIGURATIONS/validation/norms-matrix.json", "purpose": "Mapeo de constraints por carpeta", "load_order": 2},
      {"file": "SDD-COLLABORATIVE-GENERATION.md", "purpose": "Especificación de formato estructural", "load_order": 3},
      {"file": "PROJECT_TREE.md", "purpose": "Mapa canónico para resolución de wikilinks", "load_order": 4}
    ],
    "validation_toolchain": [
      {"file": "05-CONFIGURATIONS/validation/orchestrator-engine.sh", "purpose": "Motor principal de validación", "load_order": 1},
      {"file": "05-CONFIGURATIONS/validation/validate-frontmatter.sh", "purpose": "Validación de frontmatter YAML", "load_order": 2},
      {"file": "05-CONFIGURATIONS/validation/check-wikilinks.sh", "purpose": "Validación de wikilinks canónicos", "load_order": 3},
      {"file": "05-CONFIGURATIONS/validation/audit-secrets.sh", "purpose": "Detección de secrets hardcodeados", "load_order": 4},
      {"file": "05-CONFIGURATIONS/validation/check-rls.sh", "purpose": "Validación de tenant isolation en SQL", "load_order": 5},
      {"file": "05-CONFIGURATIONS/validation/verify-constraints.sh", "purpose": "Validación de constraints y LANGUAGE LOCK", "load_order": 6}
    ]
  },
  
  "human_readable_errors": {
    "frontmatter_invalid": "Frontmatter en '{file}' inválido: {details}. Consulte [[SDD-COLLABORATIVE-GENERATION.md]] para formato canónico.",
    "canonical_path_relative": "canonical_path '{path}' no es absoluto. Usar forma canónica: [[RUTA-DESDE-RAÍZ]].",
    "constraint_not_allowed": "Constraint '{constraint}' no permitida para carpeta '{folder}'. Consulte [[05-CONFIGURATIONS/validation/norms-matrix.json]].",
    "wikilink_not_canonical": "Wikilink '{wikilink}' no es canónico. Usar forma absoluta: [[RUTA-DESDE-RAÍZ]].",
    "secrets_detected": "Secrets hardcodeados detectados en '{file}': {findings}. Usar variables de entorno o secret managers.",
    "rls_violation": "Query en '{file}' sin filtro tenant_id. Agregar WHERE tenant_id = $N para cumplir C4.",
    "score_below_threshold": "Score {score} < mínimo {min_score} para Tier {tier}. Revisar blocking_issues y corregir antes de reintentar.",
    "bundle_incomplete": "Paquete Tier 3 incompleto: faltan {missing_files}. Consulte 【VC-022】 para estructura requerida.",
    "checksum_mismatch": "Checksum del archivo no coincide: esperado {expected}, obtenido {actual}. Verificar integridad.",
    "validation_command_broken": "validation_command en '{file}' no es ejecutable o retorna exit code inválido. Corregir comando canónico."
  },
  
  "expansion_hooks": {
    "new_checklist_item": {
      "requires_files_update": [
        "01-RULES/validation-checklist.md: add item with format ## 【VC-XXX】<TÍTULO>",
        "GOVERNANCE-ORCHESTRATOR.md: update tier definitions if item affects scoring",
        "05-CONFIGURATIONS/validation/: add validation logic if item requires new tool",
        "Human approval required: true"
      ],
      "backward_compatibility": "new checklist items must not invalidate existing artifacts that passed previous version; apply only to new generations"
    },
    "new_tier_definition": {
      "requires_files_update": [
        "01-RULES/validation-checklist.md: add new tier section with VC-XXX items",
        "GOVERNANCE-ORCHESTRATOR.md: update tier_definitions table",
        "SDD-COLLABORATIVE-GENERATION.md: update format specification for new tier",
        "orchestrator-engine.sh: add scoring logic for new tier",
        "Human approval required: true + major version bump"
      ],
      "backward_compatibility": "new tiers must not break existing Tier 1/2/3 validation; must provide migration path for existing artifacts"
    }
  },
  
  "validation_metadata": {
    "orchestrator_compatibility": ">=3.0.0-SELECTIVE",
    "schema_version": "validation-checklist.v3.json",
    "checksum_algorithm": "SHA256",
    "audit_log_format": "JSON Lines with RFC3339 timestamps",
    "pii_scrubbing": "enabled for all logs (C3 + C8 compliance)",
    "reproducibility_guarantee": "Any artifact validation can be reproduced identically using this checklist + orchestrator-engine.sh + prompt_hash"
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
# 1. Frontmatter válido
yq eval '.canonical_path' 01-RULES/validation-checklist.md | grep -q "/01-RULES/validation-checklist.md" && echo "✅ Ruta canónica correcta"

# 2. Constraints mapeadas (C5+C6)
yq eval '.constraints_mapped | contains(["C5"]) and contains(["C6"])' 01-RULES/validation-checklist.md && echo "✅ C5 y C6 declaradas"

# 3. Ítems de checklist presentes (VC-001 a VC-030)
grep -c "VC-0[0-9][0-9]:" 01-RULES/validation-checklist.md | awk '{if($1==30) print "✅ 30 ítems de checklist presentes"; else print "⚠️ Faltan ítems: "$1"/30"}'

# 4. Tabla de Tiers presente
grep -q "Niveles de Validación por Tier" 01-RULES/validation-checklist.md && echo "✅ Tabla de Tiers documentada"

# 5. JSON final parseable
tail -n +$(grep -n '```json' 01-RULES/validation-checklist.md | tail -1 | cut -d: -f1) 01-RULES/validation-checklist.md | sed -n '/```json/,/```/p' | sed '1d;$d' | jq empty && echo "✅ JSON parseable"

# 6. Wikilinks canónicos (sin rutas relativas)
for link in $(grep -oE '\[\[[^]]+\]\]' 01-RULES/validation-checklist.md | tr -d '[]' | sort -u); do
  if [[ "$link" =~ ^\[\[\.\/ || "$link" =~ ^\[\[\.\.\/ ]]; then
    echo "❌ Wikilink relativo: $link"
  else
    [ -f "${link#//}" ] || echo "⚠️ Wikilink no resuelto: $link"
  fi
done
```
````

**Criterio de aceptación:**  
- ✅ Frontmatter válido con `canonical_path: "/01-RULES/validation-checklist.md"`  
- ✅ `constraints_mapped` incluye C5 y C6 (estructura + trazabilidad)  
- ✅ 30 ítems de checklist (VC-001 a VC-030) documentados con ejemplos ✅/❌/🔧  
- ✅ Integración con `orchestrator-engine.sh`, `validate-frontmatter.sh`, `check-wikilinks.sh` para validación automática  
- ✅ Sección JSON final es válida (puede parsearse con `jq .`)  
- ✅ Todos los wikilinks son canónicos (absolutos desde raíz)  

---

> 🎯 **Mensaje final para el lector humano**:  
> Este checklist es tu garantía de calidad. No es opcional.  
> **Frontmatter → Estructura → Ejemplos → Validación → Score → Entrega**.  
> Si sigues ese flujo, nunca entregarás un artefacto que no cumpla con lo prometido.  
> La gobernanza no es una carga. Es la libertad de escalar sin miedo a romper.  
