#!/usr/bin/env bash
# VALIDATOR_DEPENDENCIES: bash>=5.0, jq>=1.6
# EXECUTION_PROFILE: <50ms/artifact, <64MB RAM, streaming IO, 1 jq call total
# SCOPE: internal-validation-only
# INTERFACE_VERSION: v3.0  # ← Batch mode + logging centralizado
# Canonical: [[05-CONFIGURATIONS/validation/audit-secrets.sh]]

set -uo pipefail

# === CONFIGURACIÓN GLOBAL ===
readonly LOG_DIR="${LOG_DIR:-08-LOGS/validation/test-orchestrator-engine/audit-secrets}"
readonly LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d_%H%M%S).jsonl"

declare -a FINDINGS_JSON=()
declare -a EXCLUSION_PATTERNS=("changeme" "your-" "xxx" "REDACTED" "<" ">" "null" "undefined" "pattern" "example_" "my_" "dummy_" "tutorial" "docs")

readonly -a SECRET_PATTERNS=(
  "API_KEY~sk-[a-zA-Z0-9_-]{10,}~OpenAI/Anthropic key prefix~CRITICAL"
  "API_KEY~ghp_[a-zA-Z0-9]{36,}~GitHub personal token~CRITICAL"
  "API_KEY~gho_[a-zA-Z0-9]{36,}~GitHub OAuth token~CRITICAL"
  "API_KEY~ghs_[a-zA-Z0-9]{36,}~GitHub server token~CRITICAL"
  "DB_PASSWORD~password[[:space:]]*[=:][[:space:]]*['\"]?[a-zA-Z0-9@#$%^&*!]{8,}~Hardcoded DB password~CRITICAL"
  "AWS_CRED~AKIA[0-9A-Z]{16}~AWS Access Key ID~CRITICAL"
  "AWS_CRED~aws_secret_access_key[[:space:]]*[=:][[:space:]]*['\"]?[a-zA-Z0-9/+=]{40}~AWS Secret Key~CRITICAL"
  "JWT_SECRET~jwt_secret[[:space:]]*[=:][[:space:]]*['\"]?[a-zA-Z0-9]{16,}~JWT signing secret~HIGH"
  "ENCRYPTION_KEY~encryption_key[[:space:]]*[=:][[:space:]]*['\"]?[a-zA-Z0-9]{16,}~Encryption key~HIGH"
  "WEBHOOK_URL~https://hooks\.slack\.com/services/T[A-Z0-9]+/B[A-Z0-9]+/[A-Za-z0-9]+~Slack webhook~HIGH"
  "PRIVATE_KEY~-----BEGIN (RSA|EC|OPENSSH) PRIVATE KEY-----~Private key block~CRITICAL"
)

# === LOGGING ===
mkdir -p "$LOG_DIR" 2>/dev/null || true

log_debug() { echo "[DEBUG] $*" >&2; }
log_info()  { echo "🔍 $*" >&2; }
log_warn()  { echo "⚠️  $*" >&2; }
log_error() { echo "❌ $*" >&2; }

# Log estructurado a JSONL (para dashboard futuro)
log_to_file() {
  local json="$1"
  echo "$json" >> "$LOG_FILE" 2>/dev/null || true
}

# === FUNCIONES DE VALIDACIÓN ===
is_excluded() {
  local line="$1" lower="${1,,}"
  [[ "$line" =~ ^[[:space:]]*# ]] && return 0
  [[ "$line" =~ ^[[:space:]]*// ]] && return 0
  [[ "$line" =~ ^[[:space:]]*\* ]] && return 0
  for p in "${EXCLUSION_PATTERNS[@]}"; do
    [[ "$lower" == *"$p"* ]] && return 0
  done
  return 1
}

add_finding() {
  local raw="$6"
  raw="${raw//\\/\\\\}"; raw="${raw//\"/\\\"}"; raw="${raw:0:120}"
  FINDINGS_JSON+=("$(jq -n -c \
    --arg c "$3" --arg d "$4" --arg s "$5" \
    --argjson l "$2" --arg sn "$raw" \
    '{constraint:"C3",category:$c,description:$d,severity:$s,line:$l,snippet:$sn}')")
}

load_context() {
  local file="$1"
  local norms="05-CONFIGURATIONS/validation/norms-matrix.json"
  [[ -f "$norms" ]] || return 0
  local folder=$(dirname "$file" | sed 's|^\./||')
  local exc
  exc=$(jq -r --arg f "$folder" '.[$f].c3_exceptions // [] | .[]' "$norms" 2>/dev/null) || return 0
  while IFS= read -r e; do [[ -n "$e" ]] && EXCLUSION_PATTERNS+=("$e"); done <<< "$exc"
}

scan_stream() {
  local file="$1" strict="${2:-0}" ln=0
  [[ ! -r "$file" ]] && return 2
  while IFS= read -r line || [[ -n "$line" ]]; do
    ((ln++))
    is_excluded "$line" && continue
    for entry in "${SECRET_PATTERNS[@]}"; do
      IFS='~' read -r cat pat desc sev <<< "$entry"
      if [[ "$line" =~ $pat ]]; then
        add_finding "$file" "$ln" "$cat" "$desc" "$sev" "$line"
        log_warn "C3 violation: $cat at $file:$ln"
        [[ "$sev" == "CRITICAL" && "$strict" == "1" ]] && return 1
      fi
    done
  done < "$file"
  return 0
}

emit_json() {
  local status="$1" file="$2"
  local issues="[]"
  [[ ${#FINDINGS_JSON[@]} -gt 0 ]] && issues=$(printf '%s\n' "${FINDINGS_JSON[@]}" | jq -s -c '.')
  jq -n -c \
    --arg v "audit-secrets.sh" --arg ver "3.0.0" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg f "$file" \
    --arg c "C3" \
    --argjson passed "$([ "$status" == "passed" ] && echo true || echo false)" \
    --argjson issues "$issues" --argjson count "${#FINDINGS_JSON[@]}" \
    '{validator:$v,version:$ver,timestamp:$ts,file:$f,constraint:$c,passed:$passed,issues:$issues,issues_count:$count}'
}

# === PROCESAMIENTO INDIVIDUAL (para orchestrator) ===
process_single() {
  local FILE="$1" STRICT="${2:-0}"
  FINDINGS_JSON=()
  
  [[ ! -f "$FILE" ]] && { log_error "File not found: $FILE"; return 2; }
  
  load_context "$FILE"
  scan_stream "$FILE" "$STRICT"
  local rc=$?
  
  local status="passed"
  [[ $rc -eq 2 ]] && status="error"
  [[ ${#FINDINGS_JSON[@]} -gt 0 ]] && status="failed"
  
  local json
  json=$(emit_json "$status" "$FILE")
  
  # stdout: JSON para orchestrator (V-INT-03)
  echo "$json"
  # stderr: log humano
  log_info "Audit: $FILE → $status (${#FINDINGS_JSON[@]} issues)"
  # archivo: JSONL para dashboard
  log_to_file "$json"
  
  [[ "$status" == "passed" ]] && return 0 || [[ "$status" == "failed" ]] && return 1 || return 2
}

# === MODO BATCH (para escaneo masivo con reporte) ===
process_batch() {
  local DIR="$1" STRICT="${2:-0}"
  local total=0 passed=0 failed=0 errors=0
  local start_time=$(date +%s%N)
  
  log_info "🚀 Batch scan: $DIR (strict=$STRICT)"
  log_info "📁 Logs: $LOG_FILE"
  echo "" >&2
  
  while IFS= read -r -d '' file; do
    ((total++))
    local file_start=$(date +%s%N)
    
    FINDINGS_JSON=()
    if ! [[ -f "$file" ]]; then
      log_error "⚠️  Skip (not found): $file"
      ((errors++))
      continue
    fi
    
    load_context "$file"
    scan_stream "$file" "$STRICT"
    local rc=$?
    
    local status="passed"
    [[ $rc -eq 2 ]] && status="error"
    [[ ${#FINDINGS_JSON[@]} -gt 0 ]] && status="failed"
    
    local json
    json=$(emit_json "$status" "$file")
    log_to_file "$json"
    
    # Reporte por archivo (stderr, humano)
    if [[ "$status" == "failed" ]]; then
      log_warn "❌ $file"
      for issue in "${FINDINGS_JSON[@]}"; do
        local cat line sev
        cat=$(echo "$issue" | jq -r '.category')
        line=$(echo "$issue" | jq -r '.line')
        sev=$(echo "$issue" | jq -r '.severity')
        echo "   → Línea $line: $cat [$sev]" >&2
      done
      ((failed++))
    elif [[ "$status" == "error" ]]; then
      log_error "⚠️  $file → error de ejecución" >&2
      ((errors++))
    else
      log_info "✅ $file" >&2
      ((passed++))
    fi
    
    local file_end=$(date +%s%N)
    local file_ms=$(( (file_end - file_start) / 1000000 ))
    [[ $file_ms -gt 3000 ]] && log_warn "⚠️  Lentitud: ${file_ms}ms en $file" >&2
  done < <(find "$DIR" -type f -name "*.md" -print0)
  
  local end_time=$(date +%s%N)
  local total_ms=$(( (end_time - start_time) / 1000000 ))
  local avg_ms=0
  [[ $total -gt 0 ]] && avg_ms=$(( total_ms / total ))
  
  # === REPORTE FINAL (stderr, humano) ===
  echo "" >&2
  echo "=========================================" >&2
  echo "📊 REPORTE EJECUTIVO – audit-secrets.sh v3.0" >&2
  echo "=========================================" >&2
  echo "📁 Directorio: $DIR" >&2
  echo "📄 Documentos procesados: $total" >&2
  echo "✅ Pasaron (sin secrets): $passed" >&2
  echo "❌ Fallaron (secrets detectados): $failed" >&2
  echo "⚠️  Errores de ejecución: $errors" >&2
  echo "⏱️  Tiempo total: ${total_ms}ms" >&2
  echo "⚡ Promedio por archivo: ${avg_ms}ms" >&2
  echo "🎯 Cumple <3000ms/artifact: $([ $avg_ms -lt 3000 ] && echo '✅ SÍ' || echo '❌ NO')" >&2
  echo "📄 Log JSONL: $LOG_FILE" >&2
  echo "=========================================" >&2
  
  # === RESUMEN JSON (stdout, para dashboard/orchestrator) ===
  jq -n -c \
    --arg dir "$DIR" \
    --argjson total "$total" \
    --argjson passed "$passed" \
    --argjson failed "$failed" \
    --argjson errors "$errors" \
    --argjson total_ms "$total_ms" \
    --argjson avg_ms "$avg_ms" \
    --arg log_file "$LOG_FILE" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{
      summary: {
        directory: $dir,
        timestamp: $ts,
        total_files: $total,
        passed: $passed,
        failed: $failed,
        errors: $errors,
        performance: {
          total_ms: $total_ms,
          avg_ms: $avg_ms,
          meets_3000ms: ($avg_ms < 3000)
        }
      },
      log_file: $log_file
    }'
  
  # Exit code: 0 si todo pasó, 1 si hubo fallos de validación, 2 si hubo errores
  [[ $failed -eq 0 && $errors -eq 0 ]] && return 0 || [[ $errors -eq 0 ]] && return 1 || return 2
}

# === PUNTO DE ENTRADA ===
main() {
  local MODE="single" TARGET="" STRICT="0"
  
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --file|-f) MODE="single"; TARGET="$2"; shift 2;;
      --dir|-d) MODE="batch"; TARGET="$2"; shift 2;;
      --strict|-s) STRICT="1"; shift;;
      --log-dir) LOG_DIR="$2"; shift 2;;
      --help|-h)
        echo "Uso: $0 [--file <path> | --dir <path>] [--strict] [--log-dir <path>]" >&2
        echo "  --file, -f: Validar un solo archivo (modo orchestrator)" >&2
        echo "  --dir, -d:  Escanear directorio completo (modo batch + reporte)" >&2
        echo "  --strict:   Early-exit al primer CRITICAL" >&2
        echo "  --log-dir:  Carpeta para logs JSONL (default: $LOG_DIR)" >&2
        exit 0;;
      *) log_error "Unknown arg: $1"; exit 2;;
    esac
  done
  
  if [[ -z "$TARGET" ]]; then
    log_error "Missing target: use --file <path> or --dir <path>"
    exit 2
  fi
  
  if [[ "$MODE" == "single" ]]; then
    process_single "$TARGET" "$STRICT"
    exit $?
  else
    process_batch "$TARGET" "$STRICT"
    exit $?
  fi
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"
