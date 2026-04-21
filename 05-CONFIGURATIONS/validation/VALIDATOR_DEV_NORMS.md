---
canonical_path: "05-CONFIGURATIONS/validation/VALIDATOR_DEV_NORMS.md"
artifact_id: "validator-dev-norms-v1.1"
constraints_mapped: "V-INT-01,V-INT-02,V-INT-03,V-INT-04,V-INT-05,V-LOG-01,V-LOG-02,V-DOC-01"
validation_command: "bash 05-CONFIGURATIONS/validation/test-validator-contract.sh --file 05-CONFIGURATIONS/validation/*.sh"
tier: 3
---

# 📐 VALIDATOR_DEV_NORMS.md – Normas Internas de Desarrollo de Validadores

## 🎯 Propósito
Establecer un contrato de ingeniería ligero y obligatorio para todas las herramientas ubicadas en `05-CONFIGURATIONS/validation/`. Estas normas aplican **exclusivamente al equipo de desarrollo de infraestructura** y no se imponen como constraints externas a los artefactos de negocio. El objetivo es garantizar:
• Ejecución predecible y paralelizable (<3000ms/artifact para validaciones complejas, <500ms para simples)
• Integración directa con `[[05-CONFIGURATIONS/validation/orchestrator-engine.sh]]` sin parsing complejo
• Cero sobrecarga de gobernanza en rutas de producción masiva (600-1000+ artefactos)
• **Logs JSONL estandarizados para ingestión automática por dashboards estáticos**

---

## 🔧 Implementación Técnica

### V-INT-01: Contrato de Salida JSON Estricto (Dashboard-Ready)
Todo validador debe generar un único objeto JSON válido por `stdout`. La generación **obligatoriamente** se realiza con `jq -n` o `jq -s`. Nunca se permite concatenación manual de strings.

**Schema mínimo requerido:**
```json
{
  "validator": "check-rls.sh",
  "version": "3.0.0",
  "timestamp": "2026-04-20T20:30:50Z",
  "file": "06-PROGRAMMING/sql/unit-test-patterns/01-clean-rls-compliant.sql.md",
  "constraint": "C4",
  "passed": true,
  "issues": [],
  "issues_count": 0
}
```

**Schema de `issues` (cuando `passed: false`):**
```json
"issues": [
  {
    "constraint": "C4",
    "category": "missing_tenant_filter",
    "description": "DML sin filtro tenant_id en cláusula WHERE",
    "severity": "CRITICAL",
    "line": 42,
    "snippet": "SELECT * FROM orders WHERE status = 'pending'"
  }
]
```

### V-INT-02: Semántica de Códigos de Salida (Exit Codes)
| Código | Significado | Acción del Orquestador |
|--------|-------------|------------------------|
| `0` | `passed: true` | Continúa flujo, registra score positivo |
| `1` | `passed: false` | Registra `blocking_issues` o `warnings`, continúa si no es `--strict` |
| `2` | Error de ejecución (archivo no encontrado, permisos, dependencia faltante) | Aborta fallback, loguea en stderr, no genera JSON de resultado |

### V-INT-03: Separación Estricta de Canales (I/O)
• `stdout`: **Únicamente** el JSON de resultado. Prohibido `echo` de progreso, emojis o logs aquí.
• `stderr`: Logs de debug, advertencias de rendimiento, trazas de error. Formato libre pero legible para humanos.
• Archivo JSONL: Append mode, una línea por artefacto validado, para ingestión por dashboard.
• Implementación técnica: Redirigir logs explícitamente `echo "..." >&2` o usar `>&2` en pipes.

### V-INT-04: Límites de Rendimiento y Recursos
• Timeout máximo por validación: `<3000ms` para validaciones complejas (RLS, secrets), `<500ms` para validaciones simples (frontmatter, wikilinks).
• Uso de memoria: Límite de `64MB` por proceso. Evitar carga completa de archivos grandes en RAM.
• Procesamiento: Lectura streaming (`grep`, `awk`, `sed`, `jq --stream`) o lectura línea por línea. Prohibido `cat file | tr -d '\n'` en archivos >10MB.
• **Métrica obligatoria**: Cada validación debe registrar `elapsed_ms` en el log JSONL para auditoría de performance.

### V-INT-05: Declaración Explícita de Dependencias
Cada script debe iniciar con un bloque de metadatos comentados que declare:
```bash
# VALIDATOR_DEPENDENCIES: jq>=1.6, bash>=5.0, awk
# EXECUTION_PROFILE: <3000ms, <64MB RAM, streaming IO
# SCOPE: internal-validation-only
```

---

## 🗂️ V-LOG-01: Estructura de Carpetas para Logs (OBLIGATORIA)

Todos los validadores deben escribir sus logs JSONL en la siguiente estructura canónica:

```
08-LOGS/
└── validation/
    └── test-orchestrator-engine/
        ├── audit-secrets/
        │   └── *.jsonl          # Logs de audit-secrets.sh
        ├── check-rls/
        │   └── *.jsonl          # Logs de check-rls.sh
        ├── verify-constraints/
        │   └── *.jsonl
        ├── validate-skill-integrity/
        │   └── *.jsonl
        ├── validate-frontmatter/
        │   └── *.jsonl
        └── check-wikilinks/
            └── *.jsonl
```

**Reglas:**
1. Crear directorio con `mkdir -p "$LOG_DIR"` al inicio del script.
2. Nombre de archivo de log: `$(date +%Y-%m-%d_%H%M%S).jsonl` (timestamp UTC).
3. Modo de escritura: **append** (`>>`), nunca overwrite, para permitir múltiples ejecuciones por día.
4. Cada línea debe ser un JSON válido e independiente (JSONL format).

---

## 📄 V-LOG-02: Formato JSONL para Dashboard (Schema Canónico)

Cada entrada en el archivo `.jsonl` debe seguir este schema **exacto** para permitir agregación y visualización automática:

```json
{
  "validator": "check-rls.sh",
  "version": "3.0.0",
  "timestamp": "2026-04-20T20:30:50Z",
  "file": "06-PROGRAMMING/sql/unit-test-patterns/02-missing-where-tenant.sql.md",
  "constraint": "C4",
  "passed": false,
  "issues": [
    {
      "constraint": "C4",
      "category": "missing_tenant_filter",
      "description": "DML sin filtro tenant_id en cláusula WHERE",
      "severity": "CRITICAL",
      "line": 4,
      "snippet": "SELECT * FROM users WHERE status = 'active';"
    }
  ],
  "issues_count": 1,
  "performance_ms": 142,
  "performance_ok": true
}
```

**Campos obligatorios:**
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `validator` | string | Nombre del script validador (ej: `check-rls.sh`) |
| `version` | string | Versión semántica del validador (ej: `3.0.0`) |
| `timestamp` | string | ISO 8601 UTC, generado con `date -u +%Y-%m-%dT%H:%M:%SZ` |
| `file` | string | Ruta canónica relativa al repo del artefacto validado |
| `constraint` | string | Código de constraint evaluada (ej: `C3`, `C4`, `V-INT-01`) |
| `passed` | boolean | Resultado binario de la validación |
| `issues` | array | Lista de violaciones detectadas (vacío si `passed: true`) |
| `issues_count` | integer | `length` del array `issues` (para agregación rápida sin parsear array) |
| `performance_ms` | integer | Tiempo de ejecución en milisegundos (para auditoría de V-INT-04) |
| `performance_ok` | boolean | `true` si `performance_ms < 3000` (o `<500` para validadores simples) |

**Campos opcionales (pero recomendados):**
| Campo | Tipo | Descripción |
|-------|------|-------------|
| `expected` | string | Valor esperado para testing de contrato (ej: `passed`, `failed`, `error`) |
| `match` | boolean | `true` si resultado coincide con expectativa (solo para orchestrator de testing) |

---

## 🌐 V-DOC-01: Documentación en Portugués (pt-BR) – Estándar Único

**Todos los validadores deben generar documentación técnica exclusivamente en portugués do Brasil**, ubicada en:

```
docs/
└── pt-BR/
    └── validation-tools/
        ├── audit-secrets/
        │   └── README.md
        ├── check-rls/
        │   └── README.md
        ├── verify-constraints/
        │   └── README.md
        ├── validate-skill-integrity/
        │   └── README.md
        ├── validate-frontmatter/
        │   └── README.md
        └── check-wikilinks/
            └── README.md
```

**Propósito:** Facilitar la adopción por equipos de ingeniería en Brasil (Ceasa, Rio Grande do Sul, partners LATAM) y mantener consistencia con la documentación base del proyecto Mantis.

**Plantilla maestra:** Ver `[[docs/pt-BR/validation-tools/TEMPLATE-VALIDATOR.md]]` (sección siguiente).

---

## 📋 Ejemplos ✅/❌/🔧

### ✅ Cumple normas (schema completo + log JSONL)

````markdown
```bash
#!/usr/bin/env bash
# VALIDATOR_DEPENDENCIES: jq>=1.6, bash>=5.0, awk
# EXECUTION_PROFILE: <3000ms, <64MB RAM, streaming IO
set -euo pipefail

FILE="${1:?Missing file argument}"
VERSION="3.0.0"
CONSTRAINT="C4"
LOG_DIR="08-LOGS/validation/test-orchestrator-engine/check-rls"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d_%H%M%S).jsonl"

start_ms=$(date +%s%3N)
# ... lógica de validación ...
end_ms=$(date +%s%3N)
elapsed_ms=$((end_ms - start_ms))
perf_ok=$([[ $elapsed_ms -lt 3000 ]] && echo true || echo false)

# Emitir JSON dashboard-ready
jq -n \
  --arg v "check-rls.sh" \
  --arg ver "$VERSION" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg f "$FILE" \
  --arg c "$CONSTRAINT" \
  --argjson p true \
  --argjson ic 0 \
  --argjson pm "$elapsed_ms" \
  --argjson po "$perf_ok" \
  '{validator:$v,version:$ver,timestamp:$ts,file:$f,constraint:$c,passed:$p,issues:[],issues_count:$ic,performance_ms:$pm,performance_ok:$po}' \
  | tee >(jq -c . >> "$LOG_FILE")

exit 0
```

### ❌ Violación V-LOG-02 (schema incompleto)
```json
{"file":"test.md","passed":true}
```
**🔧 Corrección:** Agregar todos los campos obligatorios del schema canónico.

### ❌ Violación V-LOG-01 (ruta de log incorrecta)
```bash
LOG_FILE="./logs/check-rls.jsonl"  # ← Ruta relativa no canónica
```
**🔧 Corrección:** `LOG_FILE="08-LOGS/validation/test-orchestrator-engine/check-rls/$(date +%Y-%m-%d_%H%M%S).jsonl"`

---

## 🧪 Validación Automatizada

### Test de Contrato V-INT + V-LOG
```bash
# 1. JSON válido y schema completo?
output=$(bash 05-CONFIGURATIONS/validation/check-rls.sh --file dummy.md 2>/dev/null)
echo "$output" | jq -e '.validator and .version and .timestamp and .file and .constraint and .passed and .issues and .issues_count and .performance_ms and .performance_ok' && echo "✅ Schema completo"

# 2. Exit codes semánticos?
bash 05-CONFIGURATIONS/validation/check-rls.sh --file /no/existe.md >/dev/null 2>&1; [[ $? -eq 2 ]] && echo "✅ Exit 2=error"

# 3. stdout limpio (sólo JSON)?
[[ "$output" =~ ^\{.*\}$ ]] && echo "✅ V-INT-03: stdout limpio"

# 4. Log JSONL generado en ruta canónica?
find 08-LOGS/validation/test-orchestrator-engine/check-rls/ -name "*.jsonl" -exec head -1 {} \; | jq -e '.validator' && echo "✅ V-LOG-01: log en ruta correcta"
```
````

### Test de Performance

```bash
# Arquivo de 10k líneas debe procesar en <3000ms
time bash 05-CONFIGURATIONS/validation/check-rls.sh --file 06-PROGRAMMING/sql/large-test.sql.md >/dev/null 2>&1
# Esperado: real 0m0,XXXs (no minutos)
```

---

## 🔗 Referencias

• `[[01-RULES/harness-norms-v3.0.md]]` (Gobernanza externa - NO aplica aquí)
• `[[05-CONFIGURATIONS/validation/norms-matrix.json]]` (Contexto de constraints por carpeta)
• `[[05-CONFIGURATIONS/validation/orchestrator-engine.sh]]` (Consumidor final de outputs)
• `[[06-PROGRAMMING/bash/00-INDEX.md]]` (Patrones canónicos de shell)
• `[[docs/pt-BR/validation-tools/TEMPLATE-VALIDATOR.md]]` (Plantilla de documentación pt-BR)


