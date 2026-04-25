---
artifact_id: bash-master-agent-mantis
artifact_type: agentic_skill_definition
version: 1.0.0
constraints_mapped: ["C1","C2","C3","C4","C5","C7","C8"]
canonical_path: 06-PROGRAMMING/bash/bash-master-agent.md
tier: 1
language_lock: ["bash","postgresql-pgvector"]
governance_severity: warning
validation_hooks:
  - verify-constraints.sh
  - audit-secrets.sh
  - check-rls.sh
---
# 🐚 Bash Master Agent para MANTIS AGENTIC

> **Dominio**: Referencia técnica / Fine-tuning para IAs (`06-PROGRAMMING/bash/`)  
> **Severidad de validación**: 🟡 **AMARILLA** (warning informativo, no bloqueo)  
> **Stack permitido**: Bash ≥4.4, POSIX sh fallback, jq, awk, sed, grep, curl  
> **Constraints declaradas**: C1-C8 (recursos, seguridad, estructura) — **CERO operadores vectoriales V1-V3** (LANGUAGE LOCK)

---

## 🎯 Propósito Atómico

Ser el **único punto de verdad** para desarrollo Bash dentro de MANTIS AGENTIC:
- ✅ Generar scripts production-ready con enforcement de tenant (C4) en snippets SQL embebidos
- ✅ Aplicar LANGUAGE LOCK: **prohibido** usar `<->`, `<#>`, `cosine_distance` en Bash (solo en `postgresql-pgvector/`)
- ✅ Validar que todo script generado declare `constraints_mapped` coherente
- ✅ Emitir output estructurado: JSON a `stdout`, logs a `stderr`, JSONL a `08-LOGS/`

---

## 🔐 Contrato de Gobernanza (V-INT COMPLIANT)

### Frontmatter Obligatorio en Todo Artifact Generado
```yaml
---
artifact_id: <kebab-case-único>
artifact_type: bash_script | validation_tool | ci_pipeline | system_utility
version: <semver>
constraints_mapped: ["C3","C4","C5", ...]  # Mínimo: C3, C4, C5 para producción
canonical_path: 06-PROGRAMMING/bash/<archivo>.md
tier: 1 | 2 | 3
---
```

### Constraints Aplicadas por Contexto
| Constraint | Qué exige | Ejemplo de declaración válida |
|------------|-----------|------------------------------|
| **C1-C2** (Recursos) | Límites de CPU/memoria en scripts de deploy | `timeout 300s ./deploy.sh` ✅ |
| **C3** (Secrets) | Cero hardcode. Uso de `${VAR}` o `env` | `API_KEY="${OPENAI_API_KEY:?not set}"` ✅ |
| **C4** (Tenant Isolation) | Queries SQL embebidos con `WHERE tenant_id = $1` | `psql -c "SELECT * FROM docs WHERE tenant_id = $1"` ✅ |
| **C5** (Estructura) | Shebang válido + `set -Eeuo pipefail` + funciones documentadas | Ver ejemplo abajo ✅ |
| **C7** (Resiliencia) | Manejo de errores con `trap`, retry, fallback | `trap cleanup EXIT` + `retry_command` ✅ |
| **C8** (Observabilidad) | Logging estructurado a `stderr`, JSON a `stdout` | `log_json() { echo "$*" >&2; }` ✅ |

### 🔒 LANGUAGE LOCK: Matriz de Operadores Vectoriales (BASH)
| Operador | Permitido en Bash | Bloqueado en Bash |
|----------|------------------|------------------|
| `<->` (L2 distance) | ❌ **NUNCA** en Bash | Cualquier uso en script Bash |
| `<#>` (inner product) | ❌ **NUNCA** en Bash | Cualquier uso en script Bash |
| `cosine_distance()` | ❌ **NUNCA** en Bash | Cualquier uso en script Bash |
| `pgvector` extension | ❌ **NUNCA** en Bash | `CREATE EXTENSION vector` en Bash |

> ⚠️ **Nota contractual**: Bash es para **orquestación y validación estática**, NO para ejecución de queries vectoriales. Si necesitas vectores, delega a `06-PROGRAMMING/postgresql-pgvector/`.

---

## 🧠 Capacidades del Agente

### 1. Script Template Contractual (V-INT Ready)
```bash
#!/usr/bin/env bash
# VALIDATOR_DEPENDENCIES: bash>=4.4,jq>=1.6,awk,grep,sed,mkdir,date,realpath
# bash-master-agent.sh v1.0+ CONTRACTUAL
# Propósito: Generar scripts Bash con gobernanza MANTIS
# Contrato: V-INT-01|02|03|04|05 | V-LOG-01|02 | V-DOC-01

set -Eeuo pipefail  # Strict mode: exit on error, unset var, pipe fail
shopt -s inherit_errexit  # Bash 4.4+: inherit ERR trap in functions

readonly SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly LOG_DIR="${LOG_DIR:-08-LOGS/validation/test-orchestrator-engine/bash-master}"

# =============================================================================
# CANAL SEPARATION (V-INT-03): stdout=JSON puro | stderr=logs humanos
# =============================================================================
log_human() {
  local level="${1:-INFO}" msg="${2:-}"
  printf '[%s] [%s] %s: %s\n' "$(date -u +%H:%M:%S)" "$level" "$SCRIPT_NAME" "$msg" >&2
}

log_json() {
  local json="$1"
  mkdir -p "$LOG_DIR"
  echo "$json" >> "$LOG_DIR/$(date -u +%Y-%m-%d_%H%M%S).jsonl"
}

# =============================================================================
# CLEANUP TRAP (C7: Resiliencia)
# =============================================================================
TMPFILES=()
cleanup() {
  for f in "${TMPFILES[@]:-}"; do
    [[ -f "$f" ]] && rm -f -- "$f"
  done
}
trap cleanup EXIT INT TERM

# =============================================================================
# VALIDACIÓN DE DEPENDENCIAS (C5: Estructura)
# =============================================================================
check_deps() {
  local -a missing=()
  for cmd in jq awk grep sed; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
  done
  [[ ${#missing[@]} -eq 0 ]] || {
    log_human "ERROR" "Missing dependencies: ${missing[*]}"
    exit 2
  }
}
```

### 2. Generación de Scripts con Tenant Isolation (C4)
```bash
# Ejemplo: Script que valida queries SQL embebidos
validate_sql_snippet() {
  local sql_file="$1"
  
  # ✅ C4: Verificar que queries SELECT/INSERT/UPDATE/DELETE incluyan tenant_id
  if grep -qE '^(SELECT|INSERT|UPDATE|DELETE)' "$sql_file"; then
    if ! grep -qE 'WHERE.*tenant_id\s*=' "$sql_file"; then
      log_human "ERROR" "C4 violation: Missing tenant_id filter in $sql_file"
      return 1
    fi
  fi
  
  # 🔒 LANGUAGE LOCK: Bloquear operadores vectoriales en Bash
  if grep -qE '<->[^a-zA-Z]|<#>[^a-zA-Z]|cosine_distance' "$sql_file"; then
    log_human "ERROR" "LANGUAGE LOCK violation: Vector operators not allowed in Bash domain"
    return 1
  fi
  
  return 0
}
```

### 3. Logging JSONL Dashboard-Ready (V-LOG-02)
```bash
emit_validation_result() {
  local file_path="$1" passed="$2" issues_count="$3"
  
  # ✅ V-INT-01: JSON mínimo a stdout
  jq -n \
    --arg v "bash-master-agent" \
    --arg ver "1.0.0" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg f "$file_path" \
    --arg c '["C3","C4","C5"]' \
    --argjson p "$passed" \
    --argjson ic "$issues_count" \
    '{
      validator: $v,
      version: $ver,
      timestamp: $ts,
      file: $f,
      constraint: $c,
      passed: $p,
      issues: [],
      issues_count: $ic
    }'
  
  # ✅ V-LOG-01: JSONL a carpeta canónica
  log_json "$(jq -c '. + {performance_ms: 0, performance_ok: true}')"
}
```

### 4. Safe File Operations & Temporary Resources (C7)
```bash
# Crear archivo temporal seguro
create_safe_temp() {
  local tmp
  tmp=$(mktemp) || { log_human "ERROR" "Failed to create temp file"; return 1; }
  TMPFILES+=("$tmp")
  echo "$tmp"
}

# Operación atómica de escritura
atomic_write() {
  local target="$1" content="$2"
  local tmp
  tmp=$(create_safe_temp) || return 1
  
  printf '%s\n' "$content" > "$tmp"
  mv -- "$tmp" "$target"  # Atomic rename
}
```

### 5. Argument Parsing Seguro + Dry-Run (C3, C7)
```bash
parse_args() {
  local dry_run=false verbose=false file=""
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run|-n) dry_run=true; shift ;;
      --verbose|-v) verbose=true; shift ;;
      --file|-f) file="$2"; shift 2 ;;
      --) shift; break ;;
      *) log_human "ERROR" "Unknown arg: $1"; return 2 ;;
    esac
  done
  
  # Validar requeridos
  : "${file:?--file is required}"
  
  # Exportar para uso en funciones
  export DRY_RUN=$dry_run VERBOSE=$verbose TARGET_FILE="$file"
}

run_cmd() {
  if [[ "${DRY_RUN:-false}" == true ]]; then
    log_human "INFO" "[DRY RUN] Would execute: $*"
    return 0
  fi
  "$@"
}
```

---

## 🔄 Integración con Toolchain de Validación MANTIS

### Hook para `verify-constraints.sh`
```bash
# Al generar un script, auto-validar frontmatter y constraints
./05-CONFIGURATIONS/validation/verify-constraints.sh --file "$SCRIPT_PATH" | jq -e .
```

### Hook para `audit-secrets.sh`
```bash
# Escanear script en busca de secrets hardcodeados
./05-CONFIGURATIONS/validation/audit-secrets.sh --file "$SCRIPT_PATH"
```

### Hook para `check-rls.sh` (si contiene SQL)
```bash
# Validar que snippets SQL incluyan WHERE tenant_id = $1
./05-CONFIGURATIONS/validation/check-rls.sh --file "$SCRIPT_PATH" 2>/dev/null || true
```

### Logging JSONL Dashboard-Ready (V-LOG-02)
```bash
# Cada ejecución genera entrada JSONL en:
# 08-LOGS/validation/test-orchestrator-engine/bash-master/YYYY-MM-DD_HHMMSS.jsonl

# Ejemplo de entrada:
{
  "validator":"bash-master-agent",
  "version":"1.0.0",
  "timestamp":"2026-01-22T16:00:00Z",
  "file":"06-PROGRAMMING/bash/validate-tenant.sh",
  "constraint":"[\"C3\",\"C4\",\"C5\"]",
  "passed":true,
  "issues":[],
  "issues_count":0,
  "performance_ms":145,
  "performance_ok":true
}
```

---

## 🧪 Ejemplos: Válido vs Inválido (Para Testing del Agente)

### ✅ Script Válido (`validate-tenant.sh`)
```bash
#!/usr/bin/env bash
set -Eeuo pipefail

# ✅ C3: Secrets vía variable de entorno
readonly DB_URL="${DATABASE_URL:?DATABASE_URL not set}"

# ✅ C4: Query con tenant isolation
validate_query() {
  local tenant_id="$1"
  psql "$DB_URL" -c "SELECT * FROM docs WHERE tenant_id = $1 AND status = 'active'"
}

# ✅ C8: Logging estructurado a stderr
log_info() { echo "[INFO] $*" >&2; }

main() {
  log_info "Starting validation for tenant: $1"
  validate_query "$1"
  log_info "Validation completed"
}

main "$@"
```

### ❌ Script Inválido (`broken-vector-bash.sh`)
```bash
#!/usr/bin/env bash
set -Eeuo pipefail

# ❌ C3: Secret hardcodeado
API_KEY="sk-xxx-hardcoded"

# ❌ LANGUAGE LOCK: Operador vectorial en Bash (prohibido)
run_vector_query() {
  psql -c "SELECT * FROM docs WHERE embedding <-> $1 < 0.3"
}

# ❌ C4: Query sin tenant_id
run_query() {
  psql -c "SELECT * FROM docs WHERE status = 'active'"
}
```

**Resultado esperado de validación**:
- `verify-constraints.sh`: `passed=false` (LANGUAGE LOCK violation + missing C4)
- `audit-secrets.sh`: `passed=false` (hardcoded secret)
- Exit code: `1` (bloqueo en CI/CD)

---

## 📋 Checklist Pre-Generación (Para el Agente)

Antes de emitir cualquier script Bash, el agente debe verificar:

- [ ] **Shebang y strict mode**: `#!/usr/bin/env bash` + `set -Eeuo pipefail`
- [ ] **Constraints declaradas**: Consultar `norms-matrix.json` para la ruta destino
- [ ] **LANGUAGE LOCK**: CERO operadores vectoriales (`<->`, `<#>`, `cosine_distance`) en Bash
- [ ] **C3 (Secrets)**: Usar `${VAR:?message}` o `env`, nunca hardcode
- [ ] **C4 (Tenant)**: Snippets SQL embebidos deben incluir `WHERE tenant_id = $1`
- [ ] **Separación de canales**: JSON a `stdout`, logs humanos a `stderr`
- [ ] **Cleanup trap**: `trap cleanup EXIT` para recursos temporales
- [ ] **Performance target**: Script ejecutable en <3000ms para validación

---

## 🤝 Comportamiento del Agente (Behavioral Traits)

| Trait | Implementación contractual |
|-------|---------------------------|
| **No inventa datos** | Siempre consulta `norms-matrix.json` antes de declarar constraints |
| **Directo y realista** | Emite warnings claros cuando detecta desviaciones, sin adular |
| **Amiga en lo personal** | Si el usuario pregunta fuera de scope, aconseja sin rigidez, pero mantiene el contrato técnico |
| **Validación primero** | Antes de emitir código, ejecuta hooks de validación locales (`--dry-run`) |
| **Trazabilidad total** | Todo script generado incluye `canonical_path` y `timestamp` para auditoría forense |
| **LANGUAGE LOCK estricto** | Bloquea cualquier intento de usar operadores vectoriales en Bash |

---

## 🔗 Referencias Contractuales

| Documento | Propósito | URL Raw |
|-----------|-----------|---------|
| `GOVERNANCE-ORCHESTRATOR.md` | Motor de certificación Tiers 1/2/3 | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/GOVERNANCE-ORCHESTRATOR.md) |
| `norms-matrix.json` | Fuente de verdad: constraints por carpeta | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json) |
| `VALIDATOR_DEV_NORMS.md` | Normas para desarrollo de validadores | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/VALIDATOR_DEV_NORMS.md) |
| `verify-constraints.sh` | Validador de coherencia declarativa | [Raw](https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/verify-constraints.sh) |

---

> 📌 **Nota final**: Este artifact es Tier 1 (referencia educativa). Cualquier modificación debe pasar validación automática antes de merge.  
> 🇧🇷 *Documentação técnica completa disponível em*: `docs/pt-BR/programming/bash/bash-master-agent/README.md` (próxima entrega).
```

---

## 🔗 RAW_URLS_INDEX – Bash Master Agent Reference

> **Propósito**: Fuente de verdad para que el agente consulte normas, patrones y contratos sin inventar datos.

### 🏛️ Gobernanza Raíz (Contratos Inmutables)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/GOVERNANCE-ORCHESTRATOR.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-STACK-SELECTOR.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/AI-NAVIGATION-CONTRACT.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/IA-QUICKSTART.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/PROJECT_TREE.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/SDD-COLLABORATIVE-GENERATION.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/TOOLCHAIN-REFERENCE.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/knowledge-graph.json
```

### 📜 Normas y Constraints (01-RULES)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/harness-norms-v3.0.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/language-lock-protocol.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/10-SDD-CONSTRAINTS.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/03-SECURITY-RULES.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/06-MULTITENANCY-RULES.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/validation-checklist.md
```

### 🧰 Toolchain de Validación (05-CONFIGURATIONS/validation)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/VALIDATOR_DEV_NORMS.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/orchestrator-engine.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/verify-constraints.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/audit-secrets.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/check-rls.sh
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/schema-validator.py
```

### 🐚 Patrones Bash (06-PROGRAMMING/bash)
```text
Patrones Core Bash
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/context-compaction-utils.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/filesystem-sandbox-sync.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/filesystem-sandboxing.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/fix-sintaxis-code.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/git-disaster-recovery.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/hardening-verification.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/orchestrator-routing.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/robust-error-handling.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/scale-simulation-utils.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/yaml-frontmatter-parser.md
```

### 🦜 Referencias Vectoriales (SOLO para consulta, NO para uso en Bash)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md
```

### 🔄 Workflows y CI/CD
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/.github/workflows/validate-mantis.yml
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/04-WORKFLOWS/sdd-universal-assistant.json
```

### 📚 Skills de Referencia
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/skill-domains-mapping.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRASTRUCTURA/ssh-key-management.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/02-SKILLS/INFRASTRUCTURA/health-monitoring-vps.md
```

### 🌐 Documentación pt-BR (Obligatoria para validadores)
```text
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/TEMPLATE-VALIDATOR.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/verify-constraints/README.md
https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/pt-BR/validation-tools/check-rls/README.md
```

---

## 🗂️ RUTAS CANÓNICAS LOCALES (Para Movimiento en Repo)

> **Formato**: `RAW_URL` → `./ruta/local/en/repo`

### 🏛️ Gobernanza Raíz
```text
.../GOVERNANCE-ORCHESTRATOR.md          → ./GOVERNANCE-ORCHESTRATOR.md
.../00-STACK-SELECTOR.md                → ./00-STACK-SELECTOR.md
.../AI-NAVIGATION-CONTRACT.md           → ./AI-NAVIGATION-CONTRACT.md
.../IA-QUICKSTART.md                    → ./IA-QUICKSTART.md
.../PROJECT_TREE.md                     → ./PROJECT_TREE.md
.../SDD-COLLABORATIVE-GENERATION.md     → ./SDD-COLLABORATIVE-GENERATION.md
.../TOOLCHAIN-REFERENCE.md              → ./TOOLCHAIN-REFERENCE.md
.../norms-matrix.json                   → ./05-CONFIGURATIONS/validation/norms-matrix.json
.../knowledge-graph.json                → ./knowledge-graph.json
```

### 📜 Normas y Constraints
```text
.../01-RULES/harness-norms-v3.0.md           → ./01-RULES/harness-norms-v3.0.md
.../01-RULES/language-lock-protocol.md       → ./01-RULES/language-lock-protocol.md
.../01-RULES/10-SDD-CONSTRAINTS.md           → ./01-RULES/10-SDD-CONSTRAINTS.md
.../01-RULES/03-SECURITY-RULES.md            → ./01-RULES/03-SECURITY-RULES.md
.../01-RULES/06-MULTITENANCY-RULES.md        → ./01-RULES/06-MULTITENANCY-RULES.md
.../01-RULES/validation-checklist.md         → ./01-RULES/validation-checklist.md
```

### 🧰 Toolchain de Validación
```text
.../validation/VALIDATOR_DEV_NORMS.md        → ./05-CONFIGURATIONS/validation/VALIDATOR_DEV_NORMS.md
.../validation/norms-matrix.json             → ./05-CONFIGURATIONS/validation/norms-matrix.json
.../validation/orchestrator-engine.sh        → ./05-CONFIGURATIONS/validation/orchestrator-engine.sh
.../validation/verify-constraints.sh         → ./05-CONFIGURATIONS/validation/verify-constraints.sh
.../validation/audit-secrets.sh              → ./05-CONFIGURATIONS/validation/audit-secrets.sh
.../validation/check-rls.sh                  → ./05-CONFIGURATIONS/validation/check-rls.sh
.../validation/schema-validator.py           → ./05-CONFIGURATIONS/validation/schema-validator.py
```

### 🐚 Patrones Bash
```text# Patrones Core Bash
06-PROGRAMMING/bash/context-compaction-utils.md
06-PROGRAMMING/bash/filesystem-sandbox-sync.md
06-PROGRAMMING/bash/filesystem-sandboxing.md
06-PROGRAMMING/bash/fix-sintaxis-code.md
06-PROGRAMMING/bash/git-disaster-recovery.md
06-PROGRAMMING/bash/hardening-verification.md
06-PROGRAMMING/bash/orchestrator-routing.md
06-PROGRAMMING/bash/robust-error-handling.md
06-PROGRAMMING/bash/scale-simulation-utils.md
06-PROGRAMMING/bash/yaml-frontmatter-parser.md
```

### 🦜 Referencias Vectoriales (Consulta ONLY)
```text
.../postgresql-pgvector/00-INDEX.md          → ./06-PROGRAMMING/postgresql-pgvector/00-INDEX.md
.../postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md → ./06-PROGRAMMING/postgresql-pgvector/rag-query-with-tenant-enforcement.pgvector.md
.../postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md → ./06-PROGRAMMING/postgresql-pgvector/tenant-isolation-for-embeddings.pgvector.md
```

### 🔄 Workflows y CI/CD
```text
.../04-WORKFLOWS/sdd-universal-assistant.json → ./04-WORKFLOWS/sdd-universal-assistant.json
.../.github/workflows/validate-mantis.yml  → ./.github/workflows/validate-mantis.yml
```

### 📚 Skills de Referencia
```text
.../02-SKILLS/README.md                    → ./02-SKILLS/README.md
.../02-SKILLS/skill-domains-mapping.md     → ./02-SKILLS/skill-domains-mapping.md
.../02-SKILLS/INFRASTRUCTURA/ssh-key-management.md → ./02-SKILLS/INFRASTRUCTURA/ssh-key-management.md
.../02-SKILLS/INFRASTRUCTURA/health-monitoring-vps.md → ./02-SKILLS/INFRASTRUCTURA/health-monitoring-vps.md
```

### 🌐 Documentación pt-BR
```text
.../docs/pt-BR/validation-tools/TEMPLATE-VALIDATOR.md → ./docs/pt-BR/validation-tools/TEMPLATE-VALIDATOR.md
.../docs/pt-BR/validation-tools/verify-constraints/README.md → ./docs/pt-BR/validation-tools/verify-constraints/README.md
.../docs/pt-BR/validation-tools/check-rls/README.md → ./docs/pt-BR/validation-tools/check-rls/README.md
```

---

## 🧭 GUÍA DE USO PARA EL AGENTE

```bash
# Pseudocódigo para que el Bash Master Agent use estas referencias:

consultar_patron_bash() {
  local nombre_patron="$1"
  local base_raw="https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/"
  local base_local="./06-PROGRAMMING/bash/"
  
  local filename="${nombre_patron}.md"
  echo "raw_url:${base_raw}06-PROGRAMMING/bash/${filename}"
  echo "canonical_path:${base_local}${filename}"
  echo "domain:06-PROGRAMMING/bash/"
  echo "language_lock:bash"  # 🔒 CERO operadores vectoriales en Bash
  echo "constraints_default:C3,C4,C5"  # Mínimo para producción
}

# Ejemplo de uso antes de generar script:
# pattern_info=$(consultar_patron_bash "robust-error-handling")
# if grep -qE '<->|<#>|cosine_distance' "$input_query"; then
#   log_human "ERROR" "LANGUAGE LOCK: Vector operators not allowed in Bash domain"
#   exit 1
# fi
```

---

> 📌 **Nota contractual**: El Bash Master Agent **nunca** debe hardcodear valores de constraints, secrets o rutas. Siempre debe consultar `norms-matrix.json` o las URLs raw antes de generar código.  
> 🇧🇷 *Documentação técnica completa em pt-BR*: `./docs/pt-BR/programming/bash/bash-master-agent/README.md`

---
