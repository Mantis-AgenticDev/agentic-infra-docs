#!/usr/bin/env bash
#---
# metadata_version: 2.0
# sdd_compliant: true
# ai_parser_compatible: true
# purpose: "Validación explícita de constraints C1-C6 en ejemplos y código"
# constraint: "C1:RAM≤4GB | C2:1vCPU | C3:No-Hardcode | C4:tenant_id | C5:SHA256 | C6:Cloud-Only"
# output_format: "json + stdout + exit code para CI/CD"
# ---
# ============================================================================
# VERIFY-CONSTRAINTS.SH v2.0.0 — PRODUCTION READY
# Validación de constraints C1-C6 con manejo robusto de edge cases
# Fix crítico: grep con -- para evitar interpretación de flags
# ============================================================================
set -euo pipefail

# ────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN GLOBAL
# ────────────────────────────────────────────────────────────────────────────
readonly VERSION="2.0.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly PROJECT_ROOT="${1:-.}"
readonly REPORT_FILE="${2:-constraints-verify-report.json}"
readonly VERBOSE="${3:-0}"
readonly STRICT="${4:-0}"  # Si 1, warnings son errores en CI/CD

# Pesos por constraint para scoring (ajustable según prioridad)
declare -A CONSTRAINT_WEIGHTS=(
  [C1]=10 [C2]=10 [C3]=25 [C4]=25 [C5]=15 [C6]=15
)

declare -a RESULTS=()
declare -i FILES_CHECKED=0
declare -i TOTAL_SCORE=0
declare -i MAX_POSSIBLE_SCORE=0

# ────────────────────────────────────────────────────────────────────────────
# UTILIDADES (CORREGIDAS: grep seguro + JSON escaping)
# ────────────────────────────────────────────────────────────────────────────
log_info() { [[ "$VERBOSE" == "1" ]] && echo "[INFO] $*" || true; }
log_warn() { echo "[WARN] $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; }

# 🔐 Escape seguro para JSON (evita rotura por comillas/backslashes)
escape_json() {
  local str="$1"
  str="${str//\\/\\\\}"    # Escapar backslashes primero
  str="${str//\"/\\\"}"    # Escapar comillas dobles
  str="${str//$'\n'/\\n}"  # Escapar newlines
  str="${str//$'\r'/\\r}"  # Escapar carriage returns
  str="${str//$'\t'/\\t}"  # Escapar tabs
  echo "$str"
}

# 🔍 Verificar si archivo es documentación/template (validación relajada)
is_doc_or_template() {
  local file="$1"
  local basename
  basename=$(basename "$file")
  
  # Patrones de archivos que son docs/templates, no código ejecutable
  local -a doc_patterns=(
    "README" "CHANGELOG" "LICENSE" "CONTRIBUTING"
    "TEMPLATE" "template" "example" "EXAMPLE"
    "sample" "SAMPLE" "mock" "MOCK"
    "index.md" "INDEX.md" "00-INDEX"
  )
  
  for pattern in "${doc_patterns[@]}"; do
    [[ "$basename" == *"$pattern"* ]] && return 0
  done
  
  # Extensiones que suelen ser documentación
  [[ "$file" == *.md ]] && grep -qiE '^#.*[Ee]jemplo|^[[:space:]]*```' "$file" 2>/dev/null && return 0
  
  return 1
}

# 🔍 Verificar si archivo es script operacional (C1/C2/C6 pueden ser flexibles)
is_operational_script() {
  local file="$1"
  [[ "$file" == *backup*.sh || "$file" == *health*.sh || "$file" == *monitor*.sh ]] && return 0
  [[ "$file" == *restore*.sh || "$file" == *rotate*.sh ]] && return 0
  return 1
}

# ────────────────────────────────────────────────────────────────────────────
# VALIDADORES C1-C6 (CORREGIDOS: grep con -- y lógica contextual)
# ────────────────────────────────────────────────────────────────────────────

validate_c1() {
  local file="$1"
  local context="$2"  # "code", "doc", "template", "operational"
  
  # Docs/templates: no requieren límites explícitos (se documentan aparte)
  [[ "$context" == "doc" || "$context" == "template" ]] && return 0
  
  # Scripts operacionales: pueden tener límites implícitos vía systemd/cron
  if [[ "$context" == "operational" ]]; then
    grep -qE '(timeout|memory|limit|concurr|nice|ionice)' "$file" 2>/dev/null && return 0
    # Si no encuentra, no fallar inmediatamente: verificar si usa variables de entorno
    grep -qE '\$\{?[A-Z_]+(LIMIT|MEM|TIMEOUT|CONCUR)?\}?' "$file" 2>/dev/null && return 0
    log_warn "C1: Límites de recursos no explícitos en script operacional (verificar configuración externa): $file"
    return 0  # Warning, no fail para operacionales
  fi
  
  # Código/config: deben tener límites explícitos
  # Patrones válidos: docker, k8s, n8n, bash, python, terraform
  if grep -qE -- \
    '(mem_limit|memory:|shm_size|max_connections|EXECUTIONS_MAX|timeout_ms|cpu_limit|cpus:|nice |ionice |ulimit|resource.*limit)' \
    "$file" 2>/dev/null; then
    return 0
  fi
  
  # Variables de entorno para límites (patrón seguro)
  if grep -qE -- '\$\{?[A-Z_]*(RAM|MEM|MEMORY|LIMIT|CONCUR|TIMEOUT)[A-Z_]*\}?' "$file" 2>/dev/null; then
    return 0
  fi
  
  log_error "C1: Sin límites de recursos explícitos en $file"
  return 1
}

validate_c2() {
  local file="$1"
  local context="$2"
  
  [[ "$context" == "doc" || "$context" == "template" ]] && return 0
  
  if [[ "$context" == "operational" ]]; then
    grep -qE '(concurr|rate_limit|throttl|nice|ionice|taskset)' "$file" 2>/dev/null && return 0
    grep -qE '\$\{?[A-Z_]*(CONCUR|RATE|THROTTLE|CPU)[A-Z_]*\}?' "$file" 2>/dev/null && return 0
    log_warn "C2: Aislamiento de CPU/concurrencia no explícito en script operacional: $file"
    return 0
  fi
  
  if grep -qE -- \
    '(cpus:|cpu_limit|concurrency_limit|rate_limit|throttle|nice |ionice |taskset|parallel.*limit|worker.*count)' \
    "$file" 2>/dev/null; then
    return 0
  fi
  
  if grep -qE -- '\$\{?[A-Z_]*(CPU|CONCUR|WORKER|PARALLEL|RATE)[A-Z_]*\}?' "$file" 2>/dev/null; then
    return 0
  fi
  
  log_error "C2: Sin aislamiento de CPU/concurrencia en $file"
  return 1
}

validate_c3() {
  local file="$1"
  local context="$2"
  
  # C3: Verificar gestión segura de variables (NO detección de secretos, eso es audit-secrets.sh)
  # Patrones válidos: ${VAR:?missing}, process.env, os.getenv, docker --env-file, vault, age
  
  # Placeholder seguro: ${VAR:?missing} o ${VAR:?"msg"}
  if grep -qE -- '\$\{[A-Za-z_][A-Za-z0-9_]*:\?"?[^}]*"?\}' "$file" 2>/dev/null; then
    return 0
  fi
  
  # Entornos externos: process.env, os.getenv, docker env, vault, age
  if grep -qE -- \
    '(process\.env\.|os\.getenv\(|getenv\(|ENV\[\]|docker.*--env-file|vault.*read|age -r|-d|--decrypt)' \
    "$file" 2>/dev/null; then
    return 0
  fi
  
  # Templates/docs: aceptan placeholders documentales
  if [[ "$context" == "doc" || "$context" == "template" ]]; then
    if grep -qiE -- '(replace_with_|placeholder|your[_-]?key|TODO|FIXME|CHANGEME|INSERT_HERE)' "$file" 2>/dev/null; then
      return 0
    fi
  fi
  
  # Scripts operacionales: pueden usar variables simples si están en .env.example
  if [[ "$context" == "operational" ]]; then
    if grep -qE -- '\$\{?[A-Z_]+\}?' "$file" 2>/dev/null; then
      # Verificar que no haya valores hardcodeados (pero eso lo hace audit-secrets.sh)
      return 0
    fi
  fi
  
  log_error "C3: Sin gestión segura de secretos (usar \${VAR:?missing} o env externo) en $file"
  return 1
}

validate_c4() {
  local file="$1"
  local context="$2"
  
  # C4: tenant_id para multi-tenant isolation
  # Docs/templates: pueden mencionar tenant_id sin implementarlo
  if [[ "$context" == "doc" || "$context" == "template" ]]; then
    grep -qiE -- '(tenant_id|tenantId|X-Tenant-ID|current_tenant|ctx\.tenant)' "$file" 2>/dev/null && return 0
    log_warn "C4: tenant_id mencionado pero no implementado (esperado en docs/templates): $file"
    return 0
  fi
  
  # Código/config: deben tener tenant_id en queries, labels, environment, etc.
  if grep -qiE -- \
    '(tenant_id|tenantId|X-Tenant-ID|current_tenant|ctx\.tenant|RLS.*tenant|WHERE.*tenant|labels.*tenant|environment.*tenant)' \
    "$file" 2>/dev/null; then
    return 0
  fi
  
  # Excepción: archivos de configuración global o bootstrap que no son multi-tenant por diseño
  if grep -qiE -- '(bootstrap|global-config|single-tenant|c4_exception.*true)' "$file" 2>/dev/null; then
    log_warn "C4: Archivo marcado como excepción de multi-tenant (verificar documentación): $file"
    return 0
  fi
  
  log_error "C4: Sin aislamiento multi-tenant (tenant_id) en $file"
  return 1
}

validate_c5() {
  local file="$1"
  local context="$2"
  
  # C5: Trazabilidad de integridad (checksums, hashes, audit trails)
  
  # Docs: pueden documentar el concepto sin implementarlo
  if [[ "$context" == "doc" ]]; then
    grep -qiE -- '(sha256|checksum|integrity|audit.*hash|verify.*signature)' "$file" 2>/dev/null && return 0
    log_warn "C5: Trazabilidad documentada pero no implementada (esperado en docs): $file"
    return 0
  fi
  
  # Templates: deben incluir placeholders para checksums
  if [[ "$context" == "template" ]]; then
    grep -qiE -- '(sha256|checksum|\$\{.*CHECKSUM|\$\{.*HASH|audit_hash)' "$file" 2>/dev/null && return 0
    log_warn "C5: Placeholder de checksum presente en template: $file"
    return 0
  fi
  
  # Código/config: deben tener implementación real
  if grep -qiE -- \
    '(sha256sum|sha256|checksum|md5sum|integrity.*check|audit.*hash|backup.*enc|age -r|verify.*signature|HMAC)' \
    "$file" 2>/dev/null; then
    return 0
  fi
  
  # Scripts que generan reportes: pueden calcular checksum al vuelo
  if grep -qiE -- '\$\((sha256sum|openssl.*dgst)' "$file" 2>/dev/null; then
    return 0
  fi
  
  log_error "C5: Sin trazabilidad de integridad (checksum/hash) en $file"
  return 1
}

validate_c6() {
  local file="$1"
  local context="$2"
  
  # C6: Inferencia cloud-only (con excepciones documentadas para modelos open-weight)
  
  # Docs: pueden discutir ambas opciones
  if [[ "$context" == "doc" ]]; then
    return 0
  fi
  
  # Templates: deben tener placeholder para endpoint cloud
  if [[ "$context" == "template" ]]; then
    grep -qiE -- '(openrouter|api\.openai|cloud.*endpoint|\$\{.*API.*URL)' "$file" 2>/dev/null && return 0
    log_warn "C6: Endpoint cloud como placeholder en template: $file"
    return 0
  fi
  
  # Excepción explícita: modelos open-weight con inferencia local documentada
  if grep -qiE -- \
    '(llama.*local|ollama|vllm|text-generation-webui|c6_exception.*true|open.*weight.*local|inference.*local)' \
    "$file" 2>/dev/null; then
    # Verificar que la excepción esté documentada
    if grep -qiE -- '(#.*excepción|//.*exception|<!--.*exception|C6: local inference documented)' "$file" 2>/dev/null; then
      log_warn "C6: Excepción de inferencia local documentada (validar en revisión humana): $file"
      return 0
    fi
  fi
  
  # Caso normal: debe usar endpoint cloud documentado
  if grep -qiE -- \
    '(openrouter\.ai|api\.openai\.com|dashscope\.aliyuncs\.com|cloud.*inference|provider.*cloud|endpoint.*https)' \
    "$file" 2>/dev/null; then
    return 0
  fi
  
  # Variables de entorno para endpoint cloud (patrón seguro)
  if grep -qE -- '\$\{?[A-Z_]*(API.*URL|ENDPOINT|PROVIDER)[A-Z_]*\}?' "$file" 2>/dev/null; then
    return 0
  fi
  
  log_error "C6: Sin inferencia cloud documentada o excepción válida en $file"
  return 1
}

# ────────────────────────────────────────────────────────────────────────────
# MOTOR DE VALIDACIÓN CONTEXTUAL
# ────────────────────────────────────────────────────────────────────────────
get_file_context() {
  local file="$1"
  local basename
  basename=$(basename "$file")
  
  if [[ "$file" == *.md ]]; then
    if is_doc_or_template "$file"; then
      echo "doc"
    else
      echo "doc-code"  # Markdown con código embebido
    fi
  elif [[ "$basename" == *"template"* || "$basename" == *"example"* || "$basename" == *"sample"* ]]; then
    echo "template"
  elif is_operational_script "$file"; then
    echo "operational"
  else
    echo "code"
  fi
}

check_file() {
  local file="$1"
  
  [[ ! -f "$file" || "$file" == *".git"* || "$file" == *"node_modules"* ]] && return 0
  ((FILES_CHECKED++)) || true
  
  local context
  context=$(get_file_context "$file")
  log_info "Validando [$context]: $file"
  
  local file_score=0
  local file_max=0
  local file_ok=true
  
  # Calcular score máximo posible para este archivo
  for c in C1 C2 C3 C4 C5 C6; do
    file_max=$((file_max + ${CONSTRAINT_WEIGHTS[$c]}))
  done
  MAX_POSSIBLE_SCORE=$((MAX_POSSIBLE_SCORE + file_max))
  
  # Ejecutar validadores con contexto
  if validate_c1 "$file" "$context"; then
    file_score=$((file_score + ${CONSTRAINT_WEIGHTS[C1]}))
  else
    file_ok=false
  fi
  
  if validate_c2 "$file" "$context"; then
    file_score=$((file_score + ${CONSTRAINT_WEIGHTS[C2]}))
  else
    file_ok=false
  fi
  
  if validate_c3 "$file" "$context"; then
    file_score=$((file_score + ${CONSTRAINT_WEIGHTS[C3]}))
  else
    file_ok=false
  fi
  
  if validate_c4 "$file" "$context"; then
    file_score=$((file_score + ${CONSTRAINT_WEIGHTS[C4]}))
  else
    file_ok=false
  fi
  
  if validate_c5 "$file" "$context"; then
    file_score=$((file_score + ${CONSTRAINT_WEIGHTS[C5]}))
  else
    file_ok=false
  fi
  
  if validate_c6 "$file" "$context"; then
    file_score=$((file_score + ${CONSTRAINT_WEIGHTS[C6]}))
  else
    file_ok=false
  fi
  
  TOTAL_SCORE=$((TOTAL_SCORE + file_score))
  
  # Registrar resultado
  RESULTS+=("$(cat <<EOF
{
  "file": "$(escape_json "$file")",
  "context": "$context",
  "score": $file_score,
  "max_score": $file_max,
  "pass_rate": $(awk "BEGIN {printf \"%.2f\", ($file_score / $file_max) * 100}"),
  "passed": $file_ok
}
EOF
)")
}

scan_dir() {
  local dir="${1:-.}"
  log_info "Escaneando directorio: $dir"
  
  while IFS= read -r -d '' file; do
    check_file "$file"
  done < <(find "$dir" -type f \( \
    -name "*.md" -o -name "*.tf" -o -name "*.yml" -o -name "*.yaml" -o \
    -name "*.py" -o -name "*.sh" -o -name "*.json" -o -name "*.js" -o \
    -name "*.ts" \
  \) -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "*/.venv/*" -print0 2>/dev/null)
}

# ────────────────────────────────────────────────────────────────────────────
# GENERACIÓN DE REPORTE JSON SEGURO
# ────────────────────────────────────────────────────────────────────────────
generate_report() {
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  # Calcular métricas globales
  local overall_pass_rate=0
  if [[ $MAX_POSSIBLE_SCORE -gt 0 ]]; then
    overall_pass_rate=$(awk "BEGIN {printf \"%.2f\", ($TOTAL_SCORE / $MAX_POSSIBLE_SCORE) * 100}")
  fi
  
  local files_passed=0
  for result in "${RESULTS[@]+"${RESULTS[@]}"}"; do
    if echo "$result" | grep -q '"passed": true'; then
      ((files_passed++)) || true
    fi
  done
  
  # Determinar estado final
  local status="passed"
  if [[ $files_passed -lt $FILES_CHECKED ]]; then
    status="partial"
  fi
  if [[ "$STRICT" == "1" && $files_passed -lt $FILES_CHECKED ]]; then
    status="failed"
  fi
  
  # Construir array de resultados (seguro con jq o fallback)
  local results_json="[]"
  if [[ ${#RESULTS[@]} -gt 0 ]]; then
    if command -v jq &>/dev/null; then
      results_json=$(printf '%s\n' "${RESULTS[@]}" | jq -s -c '.' 2>/dev/null || echo "[]")
    else
      results_json="["
      local first=true
      for r in "${RESULTS[@]}"; do
        if [[ "$first" == "true" ]]; then
          results_json+="$r"
          first=false
        else
          results_json+=",$r"
        fi
      done
      results_json+="]"
    fi
  fi
  
  # Calcular checksum del reporte
  local temp_report
  temp_report=$(mktemp)
  
  cat > "$temp_report" << EOF
{
  "validator_version": "$VERSION",
  "timestamp": "$timestamp",
  "target": "$PROJECT_ROOT",
  "constraints_validated": ["C1","C2","C3","C4","C5","C6"],
  "status": "$status",
  "summary": {
    "files_checked": $FILES_CHECKED,
    "files_passed": $files_passed,
    "files_failed": $((FILES_CHECKED - files_passed)),
    "total_score": $TOTAL_SCORE,
    "max_possible_score": $MAX_POSSIBLE_SCORE,
    "overall_pass_rate": $overall_pass_rate
  },
  "constraint_weights": {
    "C1": ${CONSTRAINT_WEIGHTS[C1]},
    "C2": ${CONSTRAINT_WEIGHTS[C2]},
    "C3": ${CONSTRAINT_WEIGHTS[C3]},
    "C4": ${CONSTRAINT_WEIGHTS[C4]},
    "C5": ${CONSTRAINT_WEIGHTS[C5]},
    "C6": ${CONSTRAINT_WEIGHTS[C6]}
  },
  "results": $results_json,
  "recommendations": [
    "Revisar archivos con pass_rate < 50% para priorizar refactor",
    "Documentar excepciones C4/C6 en frontmatter cuando aplique",
    "Usar \${VAR:?missing} para gestión segura de secretos (C3)",
    "Incluir checksums en artefactos de backup/producción (C5)",
    "Validar endpoints cloud en configuración de IA (C6)"
  ],
  "audit": {
    "script_sha256": "$(sha256sum "$0" 2>/dev/null | awk '{print $1}' || echo 'unknown')",
    "report_sha256": "PLACEHOLDER"
  }
}
EOF

  # Reemplazar placeholder con checksum real
  local report_sha
  report_sha=$(sha256sum "$temp_report" 2>/dev/null | awk '{print $1}' || echo 'unknown')
  sed -i "s/\"report_sha256\": \"PLACEHOLDER\"/\"report_sha256\": \"$report_sha\"/" "$temp_report"
  
  mv "$temp_report" "$REPORT_FILE"
  
  # Output en stdout (legible para humanos)
  echo ""
  echo "========================================="
  echo "✅ VALIDACIÓN CONSTRAINTS C1-C6 v$VERSION"
  echo "========================================="
  echo "Target: $PROJECT_ROOT"
  echo "Archivos validados: $FILES_CHECKED"
  echo "✅ Aprobados: $files_passed"
  echo "❌ Pendientes: $((FILES_CHECKED - files_passed))"
  echo "📊 Score global: $TOTAL_SCORE / $MAX_POSSIBLE_SCORE ($overall_pass_rate%)"
  echo "🔐 Report SHA256: $report_sha"
  echo "📄 Reporte guardado: $REPORT_FILE"
  echo "========================================="
  
  # Código de salida para CI/CD
  if [[ "$status" == "failed" ]]; then
    exit 1
  elif [[ "$status" == "partial" && "$STRICT" == "1" ]]; then
    exit 1
  fi
  exit 0
}

# ────────────────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────────────────
main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    cat << EOF
Uso: $0 [ruta] [reporte.json] [verbose:0/1] [strict:0/1]

Validación de constraints C1-C6 para MANTIS AGENTIC.
Evalúa madurez técnica de archivos según reglas de infraestructura.

Constraints:
  C1: Límites de recursos (RAM≤4GB, timeout, concurrency)
  C2: Aislamiento de CPU/concurrencia
  C3: Gestión segura de secretos (\${VAR:?missing}, env externo)
  C4: Aislamiento multi-tenant (tenant_id)
  C5: Trazabilidad de integridad (checksums, hashes)
  C6: Inferencia cloud-only (con excepciones documentadas)

Parámetros:
  ruta              Directorio o archivo a validar (default: .)
  reporte.json      Archivo de salida JSON (default: constraints-verify-report.json)
  verbose:0/1       Modo detallado (default: 0)
  strict:0/1        Tratar 'partial' como fallo en CI/CD (default: 0)

Scoring:
  Cada constraint tiene peso configurable (C3/C4: 25pts, C1/C2: 10pts, C5/C6: 15pts)
  Score final = suma de constraints pasados / máximo posible
  Archivos docs/templates tienen validación relajada

Ejemplos:
  $0 05-CONFIGURATIONS/
  $0 . report.json 1 1
  $0 02-SKILLS/BASE\ DE\ DATOS-RAG/vertical-db-schemas.md

Integración CI/CD:
  ./verify-constraints.sh . report.json 0 1 || echo "Validación fallida"

Salida:
  - Reporte JSON con score por archivo y métricas globales
  - Código de salida: 0 (passed) / 1 (failed o partial en strict mode)
EOF
    exit 0
  fi
  
  log_info "Iniciando validación de constraints C1-C6 v$VERSION"
  
  if [[ -f "$PROJECT_ROOT" ]]; then
    check_file "$PROJECT_ROOT"
  elif [[ -d "$PROJECT_ROOT" ]]; then
    scan_dir "$PROJECT_ROOT"
  else
    log_error "Ruta no encontrada: $PROJECT_ROOT"
    exit 1
  fi
  
  if [[ $FILES_CHECKED -eq 0 ]]; then
    log_warn "No se encontraron archivos válidos para validar en: $PROJECT_ROOT"
  fi
  
  generate_report
}

main "$@"
