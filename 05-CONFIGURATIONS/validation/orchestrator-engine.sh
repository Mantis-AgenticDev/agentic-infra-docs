#!/usr/bin/env bash
# SHA256: $(sha256sum "$0" 2>/dev/null | awk '{print $1}')
# orchestrator-engine.sh v4.0 (DASHBOARD & METRICS)
# MANTIS AGENTIC - Zero-Trust Validation Orchestrator

set -Eeuo pipefail
export LC_ALL=C

# === DEPENDENCY CHECK ===
for cmd in jq awk sed find xargs sha256sum nproc wc; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: Missing required dependency: $cmd" >&2
    exit 1
  fi
done

export SCRIPT_NAME="orchestrator-engine.sh"
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

export LOG_BASE="$PROJECT_ROOT/08-LOGS/validation/test-orchestrator-engine"
export DATE_STR="$(date -u +%Y-%m-%d)"
export TIMESTAMP_STR="$(date -u +%Y%m%d_%H%M%S)"

# Directorios de la arquitectura de logs
export MANIFESTS_DIR="$LOG_BASE/manifests"
export DASHBOARD_DIR="$LOG_BASE/dashboard"
export DASHBOARD_DATA_DIR="$DASHBOARD_DIR/data"

mkdir -p "$MANIFESTS_DIR" "$DASHBOARD_DATA_DIR"

# Asegurar directorios de los 6 validadores
export VALIDATORS=(
  "audit-secrets"
  "check-rls"
  "check-wikilinks"
  "validate-frontmatter"
  "validate-skill-integrity"
  "verify-constraints"
)
for v in "${VALIDATORS[@]}"; do
  mkdir -p "$LOG_BASE/$v"
done

# === LOGGING HUMANO A STDERR ===
log_err() {
  local level="${1:-INFO}" msg="${2:-}"
  printf '{"ts":"%s","level":"%s","script":"%s","msg":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$level" "$SCRIPT_NAME" "$msg" >&2
}

# === WORKER ASÍNCRONO ===
process_file() {
  local file="$1"
  local start_ms=$(date +%s%3N 2>/dev/null || echo 0)
  
  # 1. Integridad Pre
  local pre_hash=$(sha256sum "$file" | awk '{print $1}')
  
  local pass_count=0
  local fail_count=0
  local issues_list="[]"
  
  for v in "audit-secrets" "check-rls" "check-wikilinks" "validate-frontmatter" "validate-skill-integrity" "verify-constraints"; do
    local v_script="$PROJECT_ROOT/05-CONFIGURATIONS/validation/${v}.sh"
    if [[ ! -x "$v_script" ]]; then
      continue
    fi
    
    # Redirigir stderr a logs humanos asíncronos (evita ruido en consola)
    local stderr_log="$LOG_BASE/stderr_${v}_${DATE_STR}.log"
    
    # Ejecutar en modo Read-Only, aislando STDERR
    # Asumimos que todos devuelven el esquema V-INT: {passed: bool, issues: [], performance_ms: int}
    local v_out
    v_out=$("$v_script" --file "$file" 2>>"$stderr_log" || true)
    
    local passed=$(echo "$v_out" | jq -r '.passed // false' 2>/dev/null || echo "false")
    if [[ "$passed" == "true" ]]; then
      ((pass_count++))
    else
      ((fail_count++))
      # Extraer issues y anexar al listado
      local v_issues=$(echo "$v_out" | jq -c '.issues[]? | .validator="'$v'"' 2>/dev/null || echo "")
      if [[ -n "$v_issues" ]]; then
        while IFS= read -r issue; do
          issues_list=$(echo "$issues_list" | jq -c ". + [$issue]")
        done <<< "$v_issues"
      fi
    fi
  done
  
  # 2. Integridad Post
  local post_hash=$(sha256sum "$file" | awk '{print $1}')
  
  if [[ "$pre_hash" != "$post_hash" ]]; then
    # CRÍTICO: Violación de inmutabilidad
    echo "INTEGRITY_VIOLATION|$file" >> "$LOG_BASE/.integrity_errors"
    exit 3
  fi
  
  local end_ms=$(date +%s%3N 2>/dev/null || echo 0)
  local elapsed=$((end_ms - start_ms))
  [[ $elapsed -lt 0 ]] && elapsed=0
  
  # Métricas
  local loc=$(wc -l < "$file" || echo 0)
  local chars=$(wc -m < "$file" || echo 0)
  # tokens ≈ (chars / 4) + (newlines / 2)
  local tokens=$(( (chars / 4) + (loc / 2) ))
  
  # Extraer dominio de la ruta
  local domain="ROOT"
  if [[ "$file" =~ $PROJECT_ROOT/([^/]+)/ ]]; then
    domain="${BASH_REMATCH[1]}"
  fi
  
  local global_pass=true
  [[ $fail_count -gt 0 ]] && global_pass=false
  
  # Escribir el resultado agregado de este fichero en un temporal para el aggregate phase
  jq -n -c \
    --arg f "${file#$PROJECT_ROOT/}" \
    --arg d "$domain" \
    --argjson p "$global_pass" \
    --argjson ms "$elapsed" \
    --argjson loc "$loc" \
    --argjson tok "$tokens" \
    --argjson iss "$issues_list" \
    '{file:$f,domain:$d,passed:$p,time_ms:$ms,loc:$loc,tokens:$tok,issues:$iss}' >> "$LOG_BASE/.tmp_aggregated_results"
}
export -f process_file

# ==============================================================================
# FASE 1: DISCOVERY
# ==============================================================================
TARGET_DIR="${1:-$PROJECT_ROOT}"

log_err "INFO" "Starting Discovery in $TARGET_DIR"

rm -f "$LOG_BASE/.tmp_aggregated_results" "$LOG_BASE/.integrity_errors"
touch "$LOG_BASE/.tmp_aggregated_results"

# Limitar a 1000 artefactos
# Exclusiones canónicas
find "$TARGET_DIR" -type f \
  \( -name "*.md" -o -name "*.sql" -o -name "*.py" -o -name "*.go" -o -name "*.js" -o -name "*.ts" -o -name "*.sh" -o -name "*.yaml" -o -name "*.json" \) \
  -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "*/08-LOGS/*" \
  -not -path "*/__pycache__/*" -not -path "*/.venv/*" -not -name "*.tmp" \
  | head -n 1000 > "$LOG_BASE/discovery.tmp"

TOTAL_FILES=$(wc -l < "$LOG_BASE/discovery.tmp")
log_err "INFO" "Discovery complete. Target artifacts: $TOTAL_FILES"

if [[ $TOTAL_FILES -eq 0 ]]; then
  log_err "WARNING" "No files found."
  exit 0
fi

# ==============================================================================
# FASE 2: VALIDATION (PARALELA)
# ==============================================================================
log_err "INFO" "Starting Parallel Validation using $(nproc) threads..."

EPOCH_START=$(date +%s%3N)

cat "$LOG_BASE/discovery.tmp" | xargs -P "$(nproc)" -I {} bash -c 'process_file "{}"'

# Check integrity violations
if [[ -f "$LOG_BASE/.integrity_errors" ]] && [[ -s "$LOG_BASE/.integrity_errors" ]]; then
  log_err "CRITICAL" "INTEGRITY VIOLATION DETECTED. Files modified during validation."
  cat "$LOG_BASE/.integrity_errors" >&2
  exit 3
fi

EPOCH_END=$(date +%s%3N)
TOTAL_EPOCH_MS=$((EPOCH_END - EPOCH_START))

# ==============================================================================
# FASE 3: AGGREGATION
# ==============================================================================
log_err "INFO" "Aggregating metrics..."

# Calcular sumatorias
PASSED_COUNT=$(grep -c '"passed":true' "$LOG_BASE/.tmp_aggregated_results" || true)
FAILED_COUNT=$((TOTAL_FILES - PASSED_COUNT))

PASS_RATE="0.00"
FAIL_RATE="0.00"
if [[ $TOTAL_FILES -gt 0 ]]; then
  PASS_RATE=$(LC_NUMERIC=C awk "BEGIN {printf \"%.2f\", ($PASSED_COUNT / $TOTAL_FILES) * 100}")
  FAIL_RATE=$(LC_NUMERIC=C awk "BEGIN {printf \"%.2f\", ($FAILED_COUNT / $TOTAL_FILES) * 100}")
fi

TOTAL_LOC=$(jq -s 'map(.loc) | add // 0' "$LOG_BASE/.tmp_aggregated_results")
TOTAL_TOKENS=$(jq -s 'map(.tokens) | add // 0' "$LOG_BASE/.tmp_aggregated_results")

# Generar manifest final
MANIFEST_FILE="$MANIFESTS_DIR/manifest_${TIMESTAMP_STR}.json"

jq -n \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson total "$TOTAL_FILES" \
  --argjson passed "$PASSED_COUNT" \
  --argjson failed "$FAILED_COUNT" \
  --arg prate "$PASS_RATE" \
  --arg frate "$FAIL_RATE" \
  --argjson loc "$TOTAL_LOC" \
  --argjson tok "$TOTAL_TOKENS" \
  --argjson t_ms "$TOTAL_EPOCH_MS" \
  --argjson files "$(<"$LOG_BASE/.tmp_aggregated_results" jq -s '. | sort_by(.file)')" \
  '{
    timestamp: $ts,
    metrics: {
      total_artifacts: $total,
      passed: $passed,
      failed: $failed,
      pass_rate_pct: $prate,
      fail_rate_pct: $frate,
      total_loc: $loc,
      total_tokens: $tok,
      total_time_ms: $t_ms
    },
    artifacts: $files
  }' > "$MANIFEST_FILE"

# Generar hash del manifest y registrar
sha256sum "$MANIFEST_FILE" >> "$MANIFESTS_DIR/index.log"

# Actualizar el dashboard data
cp "$MANIFEST_FILE" "$DASHBOARD_DATA_DIR/manifest.json"

rm -f "$LOG_BASE/.tmp_aggregated_results" "$LOG_BASE/discovery.tmp"

# ==============================================================================
# FASE 4: ALERTAS & CLEANUP
# ==============================================================================
AVG_TIME=$(( TOTAL_EPOCH_MS / TOTAL_FILES ))
if [[ $AVG_TIME -gt 2500 ]]; then
  log_err "WARNING" "THRESHOLD BREACH: Average time per artifact (${AVG_TIME}ms) exceeds 2500ms"
fi
# Usar LC_NUMERIC=C para evitar error de comas en el awk if
if LC_NUMERIC=C awk "BEGIN {if ($FAIL_RATE > 15.0) exit 0; else exit 1}"; then
  log_err "WARNING" "THRESHOLD BREACH: Fail rate (${FAIL_RATE}%) exceeds 15%"
fi

log_err "INFO" "Orchestration Complete. Total time: ${TOTAL_EPOCH_MS}ms. Manifest: $MANIFEST_FILE"

if [[ $FAILED_COUNT -gt 0 ]]; then
  exit 1
fi
exit 0
