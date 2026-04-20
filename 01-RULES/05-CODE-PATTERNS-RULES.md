---
canonical_path: "/01-RULES/05-CODE-PATTERNS-RULES.md"
artifact_id: "code-patterns-rules-canonical"
artifact_type: "governance_rule_set"
version: "3.0.0-SELECTIVE"
constraints_mapped: ["C1", "C2", "C4", "C5", "C6", "C7", "C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 01-RULES/05-CODE-PATTERNS-RULES.md --mode headless --json"
tier: 1
immutable: true
requires_human_approval_for_changes: true
related_files:
  - "[[00-STACK-SELECTOR.md]]"
  - "[[PROJECT_TREE.md]]"
  - "[[06-PROGRAMMING/00-INDEX.md]]"
  - "[[SDD-COLLABORATIVE-GENERATION.md]]"
  - "[[05-CONFIGURATIONS/validation/verify-constraints.sh]]"
  - "[[GOVERNANCE-ORCHESTRATOR.md]]"
checksum_sha256: "PENDING_GENERATION"
---

# 📄 01-RULES/05-CODE-PATTERNS-RULES.md – REGENERADO v3.0-SELECTIVE

> **Nota para principiantes:** Este documento define **cómo** debe escribirse el código en MANTIS AGENTIC, independientemente del lenguaje. No dicta *qué* hace el código, sino *cómo* se estructura, valida y entrega para mantener coherencia, seguridad y calidad en todo el ecosistema. Si eres nuevo, lee las secciones en orden. Si eres experto, salta al JSON final.  
>  
> **Para IAs:** Este es tu contrato de patrones. **DESVIARSE DE LA ESTRUCTURA CANÓNICA = DEUDA TÉCNICA AUTOMÁTICA**. No inventes, no asumas, no omitas.


# 🧩 05-CODE-PATTERNS-RULES: Contrato de Estructura y Patrones Canónicos

<!-- 
【PARA PRINCIPIANTES】¿Qué es este archivo?
Este documento es el "manual de estilo técnico" de MANTIS AGENTIC.
Define las reglas inamovibles para garantizar que todo código generado sea:
• Determinista (misma estructura → mismo comportamiento)
• Multi-tenant nativo (C4 aplicado desde la primera línea)
• Validable automáticamente (sin intervención manual para checks básicos)
• Consistente entre lenguajes (Go, Python, Bash, TS, SQL, YAML)

Si eres nuevo: lee en orden. 
Si ya conoces el proyecto: usa los wikilinks para ir directo a lo que necesitas.
-->

> **Instrucción crítica para la IA:** 
> Este documento es tu contrato de patrones. 
> **DESVIARSE DE LA ESTRUCTURA CANÓNICA = DEUDA TÉCNICA AUTOMÁTICA**. 
> No inventes, no asumas, no omitas. Si algo no está claro, DETENER y preguntar.

---

## 【0】🎯 PROPÓSITO Y ALCANCE (Explicado para humanos)

<!-- 
【EDUCATIVO】Este documento responde: "¿Cómo escribo código que encaje perfectamente en el sistema sin romper la gobernanza?"
No es una guía de buenas prácticas genérica. Es un sistema estructural que:
• Exige que cada patrón siga el formato SDD (frontmatter + secciones + JSON tree)
• Garantiza que tenant_id se inyecta explícitamente, nunca se asume
• Obliga a que límites de recursos, timeouts y cleanup sean parte del diseño, no parches
• Asegura que el código es observable, resiliente y validable antes de integrarse
-->

### 0.1 Principios de Patrones Canónicos

```
P1: SDD-First → Todo artefacto de código sigue la especificación SDD-COLLABORATIVE-GENERATION.
P2: Tenant-Explicit → Nunca implícito. `tenant_id` se inyecta, se valida, se loguea.
P3: Resource-Aware → Memoria, CPU y timeouts se definen antes de la lógica de negocio.
P4: Observability-Native → Logging estructurado y trazabilidad son requisitos, no opcionales.
P5: Language-Lock-Respect → Los patrones respetan estrictamente los dominios permitidos.
P6: Validation-Gate → Ningún patrón se entrega sin pasar scoring automático ≥ umbral Tier.
```

---

## 【1】🔒 REGLAS INAMOVIBLES DE PATRONES (CP-001 a CP-010)

<!-- 
【EDUCATIVO】Estas 10 reglas son contractuales. 
Cualquier violación genera `blocking_issue` o `debt_technical_flag` en validación.
-->

### CP-001: SDD Format Compliance (Estructura Canónica)

```
【REGLA CP-001】Todo patrón de código debe seguir la estructura SDD obligatoria.

✅ Cumplimiento:
• Frontmatter YAML válido al inicio con campos obligatorios por Tier
• Secciones en orden estricto: Propósito → Implementación → Ejemplos → Validación → Referencias
• ≥10 ejemplos ✅/❌/🔧 para Tier 2+
• JSON tree final parseable por `jq` para agentes remotos

❌ Violación crítica:
• Código sin frontmatter o con campos faltantes (`canonical_path`, `constraints_mapped`)
• Secciones desordenadas o omitidas
• Menos de 10 ejemplos en Tier 2/3
• JSON final con sintaxis inválida o claves inconsistentes

【EJEMPLO ESTRUCTURA ✅】
---
canonical_path: "/06-PROGRAMMING/go/tenant-query.go.md"
constraints_mapped: ["C1","C4","C5","C8"]
tier: 2
---
# 🎯 TÍTULO
...
## 【1】IMPLEMENTACIÓN
...
## 【2】EJEMPLOS ✅/❌/🔧
...
## 【3】VALIDACIÓN
...
{"pattern_metadata": {...}}
```

### CP-002: Tenant-First Context Injection (C4 Nativo)

```
【REGLA CP-002】El aislamiento multi-tenant se inyecta explícitamente en la capa de entrada.

✅ Cumplimiento por stack:
• Go: `ctx := context.WithValue(r.Context(), "tenant_id", tenantID)`
• Python: `tenant_id = request.headers.get("X-Tenant-ID") or raise ValueError`
• SQL: `WHERE tenant_id = $1` en TODAS las queries (incluyendo JOINs)
• TS/JS: Middleware que extrae, valida y adjunta `tenant_id` a `req.locals`

❌ Violación crítica:
• Query sin `WHERE tenant_id = ?`
• Función que recibe `tenant_id` como parámetro opcional
• Log o error que expone `tenant_id` de otro contexto

【EJEMPLO INYECCIÓN ✅ (SQL)】
SELECT u.id, u.name, m.content
FROM users u
JOIN messages m ON m.user_id = u.id
WHERE u.tenant_id = $1 AND m.status = 'active';

【EJEMPLO INYECCIÓN ❌】
SELECT * FROM messages WHERE status = 'active'; -- 🚫 Sin filtro tenant
```

### CP-003: Resource-Aware Execution (C1 + C2 Integrados)

```
【REGLA CP-003】Límites de recursos y concurrencia son parte del diseño, no configuración posterior.

✅ Cumplimiento:
• Go: `debug.SetMemoryLimit(512 << 20)`, `context.WithTimeout(ctx, 30*time.Second)`
• Python: `asyncio.wait_for(coro, timeout=30)`, `concurrent.futures.ThreadPoolExecutor(max_workers=4)`
• Bash: `timeout 60s comando`, `ulimit -v 1048576`, `trap cleanup EXIT`
• Docker: `mem_limit: 512M`, `cpus: 0.5`, `pids_limit: 100`

✅ Patrón de fallback:
• Si se alcanza límite → degradar funcionalidad, no crashear
• Loguear evento con `level: WARN` + `tenant_id` + `resource_exceeded`

❌ Violación crítica:
• Bucle `while True` o `for range` sin condición de salida o timeout
• Goroutine/hilo sin canal de cancelación o `context.Done()`
• Contenedor sin límites de memoria/CPU en producción
```

### CP-004: LANGUAGE LOCK Boundary Respect (Aislamiento de Dominio)

```
【REGLA CP-004】Los patrones respetan estrictamente los límites de lenguaje y operadores permitidos.

✅ Cumplimiento:
• `06-PROGRAMMING/go/` → cero imports de `pgvector`, cero operadores `<->`, `<=>`, `<#>`
• `06-PROGRAMMING/sql/` → cero declaración de `vector(n)`, cero `USING hnsw/ivfflat`
• `06-PROGRAMMING/postgresql-pgvector/` → único lugar para búsqueda vectorial con V1-V3 obligatorios
• Verificación automática vía `verify-constraints.sh --check-language-lock`

❌ Violación crítica:
• `import "github.com/pgvector/pgvector-go"` en artefacto Go
• `CREATE INDEX idx_emb ON docs USING hnsw (embedding vector_cosine_ops)` en carpeta `sql/`
• `constraints_mapped: ["V1"]` declarado en patrón Python o TS

【EJEMPLO FRONTERA ✅】
Go: `db.QueryContext(ctx, "SELECT id FROM tenants WHERE id = $1", tenantID)`
pgvector: `SELECT id, embedding <=> $1 AS dist FROM embeddings WHERE tenant_id = $2`
```

### CP-005: Observability by Default (C6 + C8 Nativos)

```
【REGLA CP-005】Todo patrón incluye logging estructurado, trazabilidad y validación de comandos.

✅ Cumplimiento:
• Logs JSON a stderr con `timestamp` RFC3339, `trace_id`, `tenant_id`, `event`
• `prompt_hash` en frontmatter para reproducibilidad forense
• `validation_command` ejecutable que retorna exit code significativo
• Scrubbing automático de campos sensibles antes de loguear

✅ Patrón de log canónico:
```json
{"timestamp":"2026-04-19T12:00:00Z","level":"INFO","tenant_id":"cli_001","event":"query_executed","trace_id":"otel-xyz","status":"success","duration_ms":42}
```

❌ Violación crítica:
• `print()`, `console.log()`, o `fmt.Println()` sin estructura JSON
• Timestamp en formato local o sin zona horaria
• `validation_command` inexistente o no ejecutable
```

### CP-006: Resilient Error Handling (C7 Integrado)

```
【REGLA CP-006】Los fallos se manejan explícitamente con retry, fallback y cleanup garantizado.

✅ Cumplimiento:
• Go: `retry.ExponentialBackoff(maxAttempts=3, jitter=true)`, `defer cleanup()`
• Python: `tenacity.retry(stop=tenacity.stop_after_attempt(3), wait=tenacity.wait_exponential())`
• Bash: `set -euo pipefail`, `trap 'rm -f /tmp/$$.tmp' EXIT`
• Siempre registrar error con nivel adecuado, nunca silenciar excepciones

✅ Patrón de degradación:
• Si API externa falla → retornar cache local o respuesta parcial
• Si DB no responde → 503 Retry-After con header `Retry-After: 60`
• Nunca propagar stack traces completos a clientes externos

❌ Violación crítica:
• `try/except: pass` o `if err != nil { /* ignore */ }`
• Cleanup de recursos temporales omitido en caso de fallo
• Retorno de 200 OK con payload de error para requests fallidos
```

### CP-007: Explicit Contract Validation (C5 por Diseño)

```
【REGLA CP-007】Todo input se valida contra esquema explícito antes de procesar.

✅ Cumplimiento:
• Go: `struct` con tags `validate:"required,min=3"` o `jsonschema:"required"`
• Python: `pydantic.BaseModel` con validación automática en `model_validate()`
• TS: `zod` schema o `joi` con `schema.parse()`
• SQL: `CHECK (length(tenant_id) > 0)`, `NOT NULL` constraints en columnas críticas

✅ Patrón de rechazo temprano:
```python
class WebhookPayload(BaseModel):
    tenant_id: str = Field(..., min_length=10, pattern=r"^cli_[a-z0-9]+$")
    signature: str = Field(..., min_length=64)
    body: dict

# Rechazo automático si no cumple esquema
payload = WebhookPayload.model_validate_json(request_body)
```

❌ Violación crítica:
• Procesar JSON/SQL/XML sin validación previa de estructura
• Permitir campos desconocidos sin `additionalProperties: false`
• Validación solo en frontend, nunca en backend
```

### CP-008: Deterministic Execution Paths (Idempotencia y Dry-Run)

```
【REGLA CP-008】Todo patrón ejecutable debe ser idempotente y soportar `--dry-run`.

✅ Cumplimiento:
• Scripts de deploy/config: verificar estado actual antes de modificar
• `--dry-run`: simular cambios, loguear acciones planeadas, exit code 0
• Idempotencia: ejecutar N veces → mismo resultado que ejecutar 1 vez
• Usar transacciones o lock files para operaciones concurrentes

✅ Patrón de idempotencia (Bash):
```bash
deploy_service() {
    local service_name="$1"
    if systemctl is-active --quiet "$service_name"; then
        echo "[DRY-RUN] $service_name already running. Skipping."
        return 0
    fi
    # Proceed with deployment...
}
```

❌ Violación crítica:
• Script que crea archivos duplicados al ejecutarse dos veces
• `INSERT` sin `ON CONFLICT DO NOTHING` o verificación previa
• Faltar flag `--dry-run` en scripts de infraestructura Tier 3
```

### CP-009: Zero Implicit Dependencies (Gestión Explícita)

```
【REGLA CP-009】Todas las dependencias se declaran, versionan y auditan explícitamente.

✅ Cumplimiento:
• Go: `go.mod` con versiones fijas, `go.sum` versionado, `govulncheck` en CI
• Python: `pyproject.toml` o `requirements.txt` con hashes, `pip-audit` en CI
• Node/TS: `package.json` con versiones fijas (`^` prohibido en prod), `npm audit`
• Bash: Comandos coreutils verificados, `command -v` antes de ejecutar

✅ Patrón de verificación:
```bash
# Bash: verificar dependencias antes de ejecutar
for cmd in jq yq curl sha256sum; do
    command -v "$cmd" >/dev/null || { echo "Missing $cmd"; exit 1; }
done
```

❌ Violación crítica:
• Importar librería sin versión fija (`pip install package`, `npm install lib`)
• Confiar en `latest` o `*` en entornos de producción
• No auditar vulnerabilidades conocidas antes de merge
```

### CP-010: Pattern Reuse Over Reinvention (Índices como Fuente de Verdad)

```
【REGLA CP-010】Nunca reinventar patrones existentes. Extender o referenciar índices canónicos.

✅ Cumplimiento:
• Consultar `06-PROGRAMMING/<lenguaje>/00-INDEX.md` antes de escribir código nuevo
• Si patrón existe → reutilizar, adaptar con `extends: [[ruta-original]]`
• Si patrón no existe → crear siguiendo `skill-template.md`, actualizar índice
• Documentar dependencias cruzadas en frontmatter: `depends_on: ["[[ruta]]"]`

✅ Flujo de reutilización:
1. Buscar en índice: `grep -l "webhook.*validation" 06-PROGRAMMING/js/*.md`
2. Si encontrado → `extends: [[06-PROGRAMMING/javascript/webhook-validation-patterns.ts.md]]`
3. Si no → generar nuevo, actualizar `00-INDEX.md`, commit atómico

❌ Violación crítica:
• Escribir validación de webhooks desde cero ignorando patrón existente
• No actualizar índice tras añadir nuevo patrón
• Copiar/pegar código sin declarar dependencia o autoría
```

---

## 【2】🛡️ VALIDACIÓN AUTOMÁTICA DE PATRONES (Toolchain Integration)

<!-- 
【EDUCATIVO】Estas herramientas permiten validar automáticamente el cumplimiento de CP-001 a CP-010.
-->

| Herramienta | Regla Validada | Comando |
|------------|---------------|---------|
| `validate-frontmatter.sh` | CP-001, CP-007, CP-010 | `bash .../validate-frontmatter.sh --file artifact.md --level 2 --json` |
| `verify-constraints.sh` | CP-002, CP-004, CP-009 | `bash .../verify-constraints.sh --file artifact.md --check-language-lock --json` |
| `check-rls.sh` | CP-002 (SQL patterns) | `bash .../check-rls.sh --dir 06-PROGRAMMING/sql/ --strict --json` |
| `orchestrator-engine.sh` | CP-003, CP-005, CP-006, CP-008 | `bash .../orchestrator-engine.sh --file artifact.md --mode headless --json` |

---

## 【3】🧭 PROTOCOLO DE DISEÑO DE PATRONES (PASO A PASO)

```
┌─────────────────────────────────────────────────────────┐
│ 【FASE 0】BUSCAR EN ÍNDICE EXISTENTE                   │
├─────────────────────────────────────────────────────────┤
│ 1. Consultar 06-PROGRAMMING/<lenguaje>/00-INDEX.md     │
│ 2. ¿Patrón existe? → SÍ: extender con extends: [[ruta]]│
│ 3. ¿Patrón existe? → NO: proceder a Fase 1             │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 1】CARGAR PLANTILLA Y DECLARAR CONSTRAINTS      │
├─────────────────────────────────────────────────────────┤
│ 1. Copiar skill-template.md                            │
│ 2. Definir canonical_path exacto                       │
│ 3. Declarar constraints_mapped según norms-matrix.json │
│ 4. Añadir depends_on si extiende patrón existente      │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 2】IMPLEMENTAR CON REGLAS CP-001 A CP-010       │
├─────────────────────────────────────────────────────────┤
│ 1. Inyectar tenant_id explícito (CP-002)               │
│ 2. Definir límites y timeouts (CP-003)                 │
│ 3. Respetar LANGUAGE LOCK (CP-004)                     │
│ 4. Añadir logging estructurado (CP-005)                │
│ 5. Implementar error handling resiliente (CP-006)      │
│ 6. Validar input con schema (CP-007)                   │
│ 7. Garantizar idempotencia + dry-run (CP-008)          │
│ 8. Declarar dependencias explícitas (CP-009)           │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 3】VALIDACIÓN PRE-ENTREGA                       │
├─────────────────────────────────────────────────────────┤
│ 1. Ejecutar toolchain de validación (Fase 2)           │
│ 2. Corregir fallos hasta passed: true                  │
│ 3. Verificar score ≥ umbral Tier                       │
└─────────────────────────────────────────────────────────┘
 ▼
┌─────────────────────────────────────────────────────────┐
│ 【FASE 4】ACTUALIZAR ÍNDICE Y ENTREGAR                 │
├─────────────────────────────────────────────────────────┤
│ 1. Añadir entrada a 00-INDEX.md si es patrón nuevo     │
│ 2. Comprometer con validation_command + checksum       │
│ 3. Registrar audit log con prompt_hash                 │
└─────────────────────────────────────────────────────────┘
```

---

## 【4】📚 GLOSARIO PARA PRINCIPIANTES

| Término | Significado simple | Ejemplo |
|---------|-------------------|---------|
| **SDD Format** | Estructura obligatoria para artefactos: frontmatter + secciones + JSON | `canonical_path`, `constraints_mapped`, `validation_command` |
| **Tenant-First** | `tenant_id` se inyecta y valida antes de cualquier lógica | Middleware que rechaza requests sin header válido |
| **Resource-Aware** | Memoria, CPU y timeouts definidos en diseño, no en runtime | `debug.SetMemoryLimit(512MB)`, `context.WithTimeout` |
| **LANGUAGE LOCK** | Aislamiento de operadores y constraints por lenguaje | `<->` solo en `postgresql-pgvector/` |
| **Observability-Native** | Logs JSON con `trace_id` y `tenant_id` por defecto | `slog.InfoContext(ctx, "event", ...)` |
| **Idempotency** | Ejecutar N veces → mismo resultado que 1 vez | `INSERT ... ON CONFLICT DO NOTHING` |
| **Dry-Run** | Simular cambios sin modificar estado real | `./deploy.sh --dry-run` loguea acciones planeadas |
| **Zero Implicit Deps** | Todas las librerías/comandos declarados y versionados | `go.mod` con versiones fijas, `command -v` en Bash |
| **Pattern Reuse** | Extender índices existentes antes de crear nuevo código | `extends: [[06-PROGRAMMING/python/webhook.md]]` |

---

## 【5】🧪 SANDBOX DE PRUEBA (OPCIONAL)

```
【TEST MODE: CODE-PATTERNS VALIDATION】
Prompt de prueba: "Generar patrón de consulta SQL resiliente para analytics multi-tenant"

Respuesta esperada de la IA:
1. Buscar en 06-PROGRAMMING/sql/00-INDEX.md → verificar si existe patrón similar
2. Si no existe → cargar skill-template.md, definir canonical_path en 06-PROGRAMMING/sql/
3. Aplicar reglas:
   • CP-002: WHERE tenant_id = $1 obligatorio
   • CP-003: timeout y límite de filas (LIMIT)
   • CP-004: cero operadores vectoriales (solo SQL estándar)
   • CP-006: manejo de errores con retry en conexión
   • CP-008: idempotencia + --dry-run en script wrapper
4. Generar ≥10 ejemplos ✅/❌/🔧
5. Ejecutar validación: check-rls.sh → verify-constraints.sh → orchestrator-engine.sh
6. Actualizar índice, entregar con validation_command + checksum

Si la IA omite tenant_id, usa `SELECT *`, o entrega sin validation_command → FALLA DE PATRÓN.
```

---

## 【6】🔗 REFERENCIAS CANÓNICAS (WIKILINKS)

- `[[00-STACK-SELECTOR]]` → Motor de decisión de stack
- `[[PROJECT_TREE]]` → Mapa canónico de rutas
- `[[06-PROGRAMMING/00-INDEX]]` → Índices agregadores por lenguaje
- `[[SDD-COLLABORATIVE-GENERATION]]` → Especificación de formato
- `[[GOVERNANCE-ORCHESTRATOR]]` → Tiers y validación
- `[[05-CONFIGURATIONS/validation/norms-matrix.json]]` → Mapeo de constraints
- `[[01-RULES/language-lock-protocol.md]]` → Aislamiento de operadores
- `[[TOOLCHAIN-REFERENCE]]` → Catálogo de herramientas de validación

---

## 【7】📦 METADATOS DE EXPANSIÓN (PARA FUTURAS VERSIONES)

```json
{
  "expansion_registry": {
    "new_code_pattern": {
      "requires_files_update": [
        "01-RULES/05-CODE-PATTERNS-RULES.md: add rule with format ## CP-XXX: <TÍTULO>",
        "06-PROGRAMMING/<lenguaje>/00-INDEX.md: reference new pattern if applicable",
        "05-CONFIGURATIONS/validation/: add check if pattern requires new validation",
        "Human approval required: true"
      ],
      "backward_compatibility": "new patterns must not break existing artifacts that comply with current CP-001 to CP-010"
    },
    "new_language_support": {
      "requires_files_update": [
        "01-RULES/05-CODE-PATTERNS-RULES.md: add language-specific examples for existing CP rules",
        "06-PROGRAMMING/<new>/00-INDEX.md: create with initial patterns",
        "00-STACK-SELECTOR.md: add routing rule for new language",
        "Human approval required: true"
      ],
      "backward_compatibility": "new language patterns must declare LANGUAGE LOCK rules before being added"
    }
  },
  "compatibility_rule": "Nuevas reglas de patrones no deben invalidar artefactos generados bajo versiones anteriores. Cambios breaking requieren major version bump, guía de migración y aprobación humana explícita."
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
Prioridad de ejecución: Las reglas se aplican en orden CP-001 → CP-010.
Dependencias: Cada nodo declara sus archivos requeridos y sus efectos colaterales.
═══════════════════════════════════════════════════════════
-->

```json
{
  "code_patterns_metadata": {
    "version": "3.0.0-SELECTIVE",
    "canonical_path": "/01-RULES/05-CODE-PATTERNS-RULES.md",
    "artifact_type": "governance_rule_set",
    "immutable": true,
    "requires_human_approval_for_changes": true,
    "llm_optimizations": {
      "oriental_models_friendly": true,
      "delimiters_used": ["【】", "┌─┐", "▼", "✅/❌/🔧"],
      "numbered_sequences": true,
      "stop_conditions_explicit": true
    }
  },
  
  "rules_catalog": {
    "CP-001": {"title": "SDD Format Compliance", "constraint": "C5", "priority": "critical", "blocking_if_violated": true, "validation_tool": "validate-frontmatter.sh"},
    "CP-002": {"title": "Tenant-First Context Injection", "constraint": "C4", "priority": "critical", "blocking_if_violated": true, "validation_tool": "check-rls.sh + manual review"},
    "CP-003": {"title": "Resource-Aware Execution", "constraint": "C1, C2", "priority": "high", "blocking_if_violated": false, "validation_tool": "orchestrator-engine.sh --checks C1,C2"},
    "CP-004": {"title": "LANGUAGE LOCK Boundary Respect", "constraint": "C5", "priority": "critical", "blocking_if_violated": true, "validation_tool": "verify-constraints.sh --check-language-lock"},
    "CP-005": {"title": "Observability by Default", "constraint": "C6, C8", "priority": "high", "blocking_if_violated": false, "validation_tool": "orchestrator-engine.sh --checks C6,C8"},
    "CP-006": {"title": "Resilient Error Handling", "constraint": "C7", "priority": "high", "blocking_if_violated": false, "validation_tool": "orchestrator-engine.sh --checks C7"},
    "CP-007": {"title": "Explicit Contract Validation", "constraint": "C5", "priority": "high", "blocking_if_violated": true, "validation_tool": "schema-validator.py + type checkers"},
    "CP-008": {"title": "Deterministic Execution Paths", "constraint": "C6", "priority": "high", "blocking_if_violated": false, "validation_tool": "idempotency test + --dry-run flag check"},
    "CP-009": {"title": "Zero Implicit Dependencies", "constraint": "C1", "priority": "medium", "blocking_if_violated": false, "validation_tool": "dependency audit (govulncheck, pip-audit, npm audit)"},
    "CP-010": {"title": "Pattern Reuse Over Reinvention", "constraint": "C5, C6", "priority": "medium", "blocking_if_violated": false, "validation_tool": "index diff + extends: field check"}
  },
  
  "validation_integration": {
    "validate-frontmatter.sh": {"purpose": "Validar estructura YAML y campos obligatorios", "exit_codes": {"0": "valid", "1": "invalid"}},
    "check-rls.sh": {"purpose": "Validar tenant_id en queries SQL", "exit_codes": {"0": "compliant", "1": "violation"}},
    "verify-constraints.sh": {"purpose": "Validar constraints y LANGUAGE LOCK", "exit_codes": {"0": "compliant", "1": "violation"}},
    "orchestrator-engine.sh": {"purpose": "Scoring integral y validación final", "exit_codes": {"0": "passed", "1": "failed"}}
  },
  
  "dependency_graph": {
    "critical_infrastructure": [
      {"file": "06-PROGRAMMING/00-INDEX.md", "purpose": "Índices agregadores por lenguaje", "load_order": 1},
      {"file": "SDD-COLLABORATIVE-GENERATION.md", "purpose": "Especificación de formato SDD", "load_order": 2},
      {"file": "01-RULES/language-lock-protocol.md", "purpose": "Aislamiento de operadores", "load_order": 3},
      {"file": "05-CONFIGURATIONS/validation/norms-matrix.json", "purpose": "Mapeo de constraints por carpeta", "load_order": 4}
    ],
    "pattern_templates": [
      {"file": "05-CONFIGURATIONS/templates/skill-template.md", "purpose": "Plantilla base para nuevos patrones", "load_order": 1}
    ],
    "validation_toolchain": [
      {"file": "05-CONFIGURATIONS/validation/orchestrator-engine.sh", "purpose": "Motor principal de validación", "load_order": 1},
      {"file": "05-CONFIGURATIONS/validation/verify-constraints.sh", "purpose": "Validación de LANGUAGE LOCK", "load_order": 2},
      {"file": "05-CONFIGURATIONS/validation/check-rls.sh", "purpose": "Validación de tenant isolation en SQL", "load_order": 3}
    ]
  },
  
  "human_readable_errors": {
    "sdd_format_violation": "Estructura SDD inválida en '{file}': faltan secciones obligatorias o frontmatter incompleto. Consulte [[SDD-COLLABORATIVE-GENERATION]].",
    "tenant_missing_injection": "Query o función en '{file}' no inyecta tenant_id explícitamente. Añadir WHERE tenant_id = $N o validación de header.",
    "resource_limit_missing": "Límites de recursos no definidos en '{file}'. Añadir mem_limit, timeout o pids_limit según stack.",
    "language_lock_violation": "Operador '{op}' prohibido en lenguaje '{lang}' para archivo '{file}'. Consulte [[01-RULES/language-lock-protocol]].",
    "logging_unstructured": "Log en '{file}' no sigue formato JSON estructurado. Usar slog/pydantic-logging con trace_id y tenant_id.",
    "error_handling_swallowed": "Excepción silenciada en '{file}'. Implementar retry/backoff o fallback degradado.",
    "schema_validation_missing": "Input en '{file}' no validado contra schema explícito. Añadir pydantic/zod/struct tags con validation.",
    "non_idempotent_operation": "Operación en '{file}' no es idempotente. Verificar estado actual o usar ON CONFLICT / lock files.",
    "implicit_dependency": "Dependencia '{dep}' declarada sin versión fija en '{file}'. Pin versión y auditar vulnerabilidades.",
    "pattern_reinvention": "Patrón reinventado en '{file}' ignora índice existente. Usar extends: [[ruta-canónica]] o actualizar índice."
  },
  
  "expansion_hooks": {
    "new_pattern_rule": {
      "requires_files_update": [
        "01-RULES/05-CODE-PATTERNS-RULES.md: add rule with format ## CP-XXX: <TÍTULO>",
        "06-PROGRAMMING/<lenguaje>/00-INDEX.md: reference new pattern if applicable",
        "05-CONFIGURATIONS/validation/: add check if pattern requires new validation",
        "Human approval required: true"
      ],
      "backward_compatibility": "new rules must not invalidate existing artifacts that comply with current CP-001 to CP-010"
    },
    "new_language_pattern": {
      "requires_files_update": [
        "01-RULES/05-CODE-PATTERNS-RULES.md: add language-specific examples for existing CP rules",
        "06-PROGRAMMING/<new>/00-INDEX.md: create with initial patterns",
        "00-STACK-SELECTOR.md: add routing rule for new language",
        "Human approval required: true"
      ],
      "backward_compatibility": "new language patterns must declare LANGUAGE LOCK rules before being added"
    }
  },
  
  "validation_metadata": {
    "orchestrator_compatibility": ">=3.0.0-SELECTIVE",
    "schema_version": "code-patterns-rules.v1.json",
    "checksum_algorithm": "SHA256",
    "audit_log_format": "JSON Lines with RFC3339 timestamps",
    "pii_scrubbing": "enabled for all logs (C3 + C8 compliance)",
    "reproducibility_guarantee": "Any code pattern can be regenerated identically using this rule set + skill-template.md"
  }
}
```

---

## ✅ CHECKLIST DE VALIDACIÓN POST-GENERACIÓN
````markdown
```bash
# 1. Frontmatter válido
yq eval '.canonical_path' 01-RULES/05-CODE-PATTERNS-RULES.md | grep -q "/01-RULES/05-CODE-PATTERNS-RULES.md" && echo "✅ Ruta canónica correcta"

# 2. Constraints mapeadas
yq eval '.constraints_mapped | length' 01-RULES/05-CODE-PATTERNS-RULES.md | grep -q "7" && echo "✅ 7 constraints declaradas"

# 3. Reglas presentes
grep -c "CP-0[0-9][0-9]:" 01-RULES/05-CODE-PATTERNS-RULES.md | awk '{if($1==10) print "✅ 10 reglas de patrones"; else print "⚠️ Faltan reglas"}'

# 4. JSON válido
tail -n +$(grep -n '```json' 01-RULES/05-CODE-PATTERNS-RULES.md | tail -1 | cut -d: -f1) 01-RULES/05-CODE-PATTERNS-RULES.md | sed -n '/```json/,/```/p' | sed '1d;$d' | jq empty && echo "✅ JSON parseable"

# 5. Wikilinks canónicos
for link in $(grep -oE '\[\[[^]]+\]\]' 01-RULES/05-CODE-PATTERNS-RULES.md | tr -d '[]' | sort -u); do
  [ -f "${link#//}" ] || echo "⚠️ Wikilink roto: $link"
done
```
````

> 🎯 **Mensaje final**: Este manual es tu garantía de calidad técnica. No es opcional.  
> **Estructura → Tenant → Recursos → Validación → Observabilidad**.  
> Si sigues ese flujo, nunca entregarás código que rompa el ecosistema.  
> La gobernanza no es una carga. Es la libertad de escalar sin miedo a romper.  
