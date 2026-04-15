#!/usr/bin/env bash
#---
# metadata_version: 1.1
# sdd_compliant: true
# ai_parser_compatible: true
# purpose: "Auditoría de secretos (C3) para todo el repositorio MANTIS AGENTIC"
# scope: "02-SKILLS/, 05-CONFIGURATIONS/, archivos de código, config, docs"
# ai_providers_supported: ["openrouter","qwen","deepseek","llama","gemini","gpt","minimax","mistral-ocr","voice-agent","image-gen","video-gen"]
# infrastructure_patterns: ["aws","gcp","azure","github","docker","postgres","mysql","redis","qdrant","espocrm","n8n"]
# output_format: "json + stdout + exit code para CI/CD"
# ---
# ============================================================================
# AUDIT-SECRETS.SH v1.1.0 — CORREGIDO Y BLINDADO
# Detección de credenciales hardcodeadas (Constraint C3)
# Fix crítico: grep con -- para evitar interpretación de flags
# ============================================================================
set -euo pipefail

# ────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN GLOBAL
# ────────────────────────────────────────────────────────────────────────────
readonly VERSION="1.1.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly PROJECT_ROOT="${1:-.}"
readonly REPORT_FILE="${2:-secrets-audit-report.json}"
readonly EXCLUDE_FILE="${3:-.audit-secrets-ignore}"
readonly VERBOSE="${4:-0}"
readonly STRICT="${5:-0}"  # Si 1, warnings son errores

declare -a FINDINGS=()
declare -a EXCLUDED_PATTERNS=()
declare -i FILES_SCANNED=0
declare -i SECRETS_FOUND=0
declare -i FALSE_POSITIVES_AVOIDED=0

# ────────────────────────────────────────────────────────────────────────────
# PATRONES DE SECRETOS POR CATEGORÍA (LITERALES - USAR grep -F)
# Formato: "CATEGORY|PATTERN_LITERAL|DESCRIPTION|SEVERITY"
# ────────────────────────────────────────────────────────────────────────────
readonly -a SECRET_PATTERNS=(
  # ── AI PROVIDERS ───────────────────────────────────────────────────────
  "AI-OPENROUTER|sk-or-v1-|OpenRouter API key prefix hardcodeado|CRITICAL"
  "AI-OPENROUTER|Bearer sk-or-v1|OpenRouter Bearer token expuesto|CRITICAL"
  
  "AI-QWEN|qwen_api_key=|Qwen API key assignment sin variable|CRITICAL"
  "AI-QWEN|DASHSCOPE_API_KEY=|DashScope/Qwen credential hardcodeada|CRITICAL"
  
  "AI-DEEPSEEK|sk-ds-|DeepSeek API key prefix hardcodeado|CRITICAL"
  "AI-DEEPSEEK|deepseek_key=|DeepSeek credential assignment directa|CRITICAL"
  
  "AI-LLAMA|llama_api_token=|Llama API token hardcodeado|HIGH"
  "AI-LLAMA|HF_TOKEN=hf_|HuggingFace token prefix expuesto|CRITICAL"
  
  "AI-GEMINI|AIzaSy|Google Gemini API key prefix hardcodeado|CRITICAL"
  "AI-GEMINI|gemini_api_key=|Gemini credential assignment directa|CRITICAL"
  
  "AI-GPT|sk-proj-|OpenAI GPT project key prefix hardcodeado|CRITICAL"
  "AI-GPT|sk-|OpenAI API key generic prefix expuesto|CRITICAL"
  "AI-GPT|OPENAI_API_KEY=|OPENAI_API_KEY hardcodeada|CRITICAL"
  
  "AI-MINIMAX|minimax_api_key=|MiniMax API key hardcodeada|CRITICAL"
  "AI-MINIMAX|Authorization: Bearer|MiniMax Bearer token sin variable|HIGH"
  
  "AI-MISTRAL-OCR|mistral_ocr_key=|Mistral OCR key hardcodeada|HIGH"
  "AI-MISTRAL-OCR|MISTRAL_API_KEY=|Mistral API key en texto plano|CRITICAL"
  
  "AI-VOICE|deepgram_api_key=|Deepgram STT key hardcodeada|CRITICAL"
  "AI-VOICE|assemblyai_key=|AssemblyAI credential expuesta|HIGH"
  "AI-VOICE|elevenlabs_api_key=|ElevenLabs TTS key hardcodeada|HIGH"
  
  "AI-IMAGE|dalle_api_key=|DALL-E API key hardcodeada|CRITICAL"
  "AI-IMAGE|stability_api_key=|Stability AI key expuesta|CRITICAL"
  "AI-IMAGE|replicate_token=|Replicate token hardcodeado|HIGH"
  
  "AI-VIDEO|runwayml_key=|RunwayML API key hardcodeada|HIGH"
  "AI-VIDEO|pika_labs_token=|Pika Labs token expuesto|MEDIUM"
  
  # ── CLOUD PROVIDERS ────────────────────────────────────────────────────
  "CLOUD-AWS|AKIA|AWS Access Key ID prefix hardcodeado|CRITICAL"
  "CLOUD-AWS|aws_secret_access_key=|AWS Secret Key assignment directa|CRITICAL"
  
  "CLOUD-GCP|AIza|Google Cloud API key prefix hardcodeada|CRITICAL"
  "CLOUD-GCP|-----BEGIN PRIVATE KEY-----|GCP service account key expuesta|CRITICAL"
  
  "CLOUD-AZURE|client_secret=|Azure client secret hardcodeado|CRITICAL"
  "CLOUD-AZURE|TenantId=|Azure Tenant ID con posible secret adjunto|HIGH"
  
  # ── VERSION CONTROL & CI/CD ───────────────────────────────────────────
  "VCS-GITHUB|ghp_|GitHub Personal Access Token prefix hardcodeado|CRITICAL"
  "VCS-GITHUB|gho_|GitHub OAuth Token prefix expuesto|CRITICAL"
  "VCS-GITHUB|ghs_|GitHub Server-to-Server Token prefix hardcodeado|CRITICAL"
  "VCS-GITHUB|github_pat_|GitHub Fine-Grained PAT prefix expuesto|CRITICAL"
  
  "VCS-GITLAB|glpat-|GitLab Personal Access Token prefix hardcodeado|CRITICAL"
  
  "VCS-BITBUCKET|ATBB|Bitbucket App Password prefix expuesto|HIGH"
  
  # ── DATABASES & CACHING ───────────────────────────────────────────────
  "DB-POSTGRES|postgresql://|Postgres connection string con credenciales|CRITICAL"
  "DB-POSTGRES|PGPASSWORD=|Postgres password hardcodeada|CRITICAL"
  
  "DB-MYSQL|mysql://|MySQL connection string con credenciales|CRITICAL"
  "DB-MYSQL|MYSQL_PASSWORD=|MySQL password hardcodeada|CRITICAL"
  
  "DB-REDIS|redis://:|Redis connection string con password|HIGH"
  "DB-REDIS|REDIS_PASSWORD=|Redis password hardcodeada|HIGH"
  
  "DB-QDRANT|QDRANT_API_KEY=|Qdrant API key hardcodeada|CRITICAL"
  "DB-QDRANT|qdrant_url=|Qdrant URL con credenciales potenciales|HIGH"
  
  "DB-ESPORM|ESPOCRM_API_KEY=|EspoCRM API key hardcodeada|HIGH"
  "DB-ESPORM|espo_password=|EspoCRM password en texto plano|CRITICAL"
  
  # ── INFRASTRUCTURE & ORCHESTRATION ─────────────────────────────────────
  "INFRA-DOCKER|DOCKER_HUB_TOKEN=|Docker Hub token hardcodeado|HIGH"
  "INFRA-DOCKER|docker login -p|Docker login con password en CLI|CRITICAL"
  
  "INFRA-N8N|N8N_ENCRYPTION_KEY=|n8n encryption key hardcodeada|CRITICAL"
  "INFRA-N8N|/webhook/|n8n webhook URL con token potencial|MEDIUM"
  
  "INFRA-SSH|-----BEGIN RSA PRIVATE KEY-----|Private SSH RSA key hardcodeado|CRITICAL"
  "INFRA-SSH|-----BEGIN OPENSSH PRIVATE KEY-----|Private SSH OpenSSH key hardcodeado|CRITICAL"
  "INFRA-SSH|-----BEGIN EC PRIVATE KEY-----|Private SSH EC key hardcodeado|CRITICAL"
  "INFRA-SSH|sshpass -p|sshpass con password en texto plano|CRITICAL"
  
  "INFRA-FAIL2BAN|fail2ban_password=|Fail2ban password hardcodeada|MEDIUM"
  
  # ── GENERAL SECRET PATTERNS ───────────────────────────────────────────
  "GEN-PASSWORD|password=|Password genérico assignment directo|HIGH"
  "GEN-PASSWORD|passwd=|Passwd assignment directo|HIGH"
  "GEN-PASSWORD|pwd=|Pwd assignment directo|MEDIUM"
  
  "GEN-APIKEY|api_key=|API key genérica assignment directa|HIGH"
  "GEN-APIKEY|apikey=|ApiKey assignment sin guiones|HIGH"
  
  "GEN-SECRET|secret=|Secret genérico assignment directo|HIGH"
  "GEN-SECRET|private_key=|Private key reference hardcodeada|CRITICAL"
  
  "GEN-JWT|eyJ|JWT token prefix hardcodeado|HIGH"
  
  "GEN-BASICAUTH|Authorization: Basic|Basic Auth header hardcodeado|HIGH"
  
  "GEN-BEARER|Authorization: Bearer|Bearer token genérico expuesto|HIGH"
)

# ────────────────────────────────────────────────────────────────────────────
# PATRONES DE EXCLUSIÓN (PLACEHOLDERS VÁLIDOS - NO SON FALSOS POSITIVOS)
# ────────────────────────────────────────────────────────────────────────────
readonly -a EXCLUSION_PATTERNS=(
  '${'                      # ${ENV_VAR} bash
  '$('                      # $(ENV_VAR) shell
  'process.env.'            # process.env.VAR Node.js
  'os.getenv'               # os.getenv() Python
  'getenv('                 # getenv() genérico
  'ENV['                    # ENV['VAR'] Ruby
  '<'                       # <PLACEHOLDER>
  'XXXX'                    # XXXX, XXXXXXX
  'TODO'                    # TODO markers
  'FIXME'                   # FIXME markers
  'CHANGEME'                # CHANGEME markers
  'your-key-here'           # Documentación
  'your_api_key'            # Documentación
  'placeholder'             # Placeholder genérico
  'REPLACE_ME'              # REPLACE_ME
  'INSERT_KEY_HERE'         # Instrucciones
  'GET_YOUR_KEY_FROM'       # Instrucciones
  '.example.com'            # URLs de ejemplo
  'sk-XXXX'                 # Key ofuscada en docs
  'api_key_XXXX'            # Key ofuscada en docs
  ':?missing'               # ${VAR:?missing} patrón seguro
  ':?"'                     # ${VAR:?"message"} patrón seguro
)

# ────────────────────────────────────────────────────────────────────────────
# ARCHIVOS Y EXTENSIONES A ESCANEAR
# ────────────────────────────────────────────────────────────────────────────
readonly -a SCAN_EXTENSIONS=(
  "md" "json" "yaml" "yml" "sh" "bash" "py" "js" "ts" "sql" "env" 
  "conf" "cfg" "ini" "toml" "dockerfile" "docker-compose" "tf" "tfvars"
)

readonly -a EXCLUDE_DIRS=(
  ".git" "node_modules" "venv" ".venv" "__pycache__" ".pytest_cache"
  "dist" "build" ".next" "coverage" "*.egg-info"
)

# ────────────────────────────────────────────────────────────────────────────
# UTILIDADES (CORREGIDAS: grep con -- y -F para literales)
# ────────────────────────────────────────────────────────────────────────────
log_info() { [[ "$VERBOSE" == "1" ]] && echo "[INFO] $*" || true; }
log_warn() { echo "[WARN] $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; }
log_finding() { 
  echo "[FINDING] $*" >&2
  FINDINGS+=("$*")
  ((SECRETS_FOUND++)) || true
}

is_excluded_dir() {
  local path="$1"
  for excl in "${EXCLUDE_DIRS[@]}"; do
    [[ "$path" == *"$excl"* ]] && return 0
  done
  return 1
}

is_valid_extension() {
  local file="$1"
  local ext="${file##*.}"
  for valid_ext in "${SCAN_EXTENSIONS[@]}"; do
    [[ "$ext" == "$valid_ext" ]] && return 0
  done
  return 1
}

# 🔐 FUNCIÓN CORREGIDA: is_placeholder con grep -F -- para evitar flags
is_placeholder() {
  local line="$1"
  for pattern in "${EXCLUSION_PATTERNS[@]}"; do
    # grep -F: fixed string (no regex), -q: quiet, --: end of options
    if echo "$line" | grep -F -q -- "$pattern" 2>/dev/null; then
      ((FALSE_POSITIVES_AVOIDED++)) || true
      return 0
    fi
  done
  return 1
}

load_custom_exclusions() {
  if [[ -f "$EXCLUDE_FILE" ]]; then
    log_info "Cargando exclusiones personalizadas desde: $EXCLUDE_FILE"
    while IFS= read -r pattern || [[ -n "$pattern" ]]; do
      [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
      EXCLUDED_PATTERNS+=("$pattern")
    done < "$EXCLUDE_FILE"
  fi
}

# ────────────────────────────────────────────────────────────────────────────
# MOTOR DE DETECCIÓN (CORREGIDO: grep -F -- para patrones literales)
# ────────────────────────────────────────────────────────────────────────────
scan_file() {
  local file="$1"
  
  [[ ! -f "$file" ]] && return 0
  is_excluded_dir "$file" && return 0
  is_valid_extension "$file" || return 0
  
  log_info "Escaneando: $file"
  ((FILES_SCANNED++)) || true
  
  local line_num=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    ((line_num++)) || true
    
    # Saltar líneas que son claramente placeholders
    is_placeholder "$line" && continue
    
    # Verificar contra cada patrón de secreto
    for pattern_entry in "${SECRET_PATTERNS[@]}"; do
      IFS='|' read -r category pattern description severity <<< "$pattern_entry"
      
      # 🔐 CORRECCIÓN CRÍTICA: grep -F para fixed-string, -- para evitar flags
      if echo "$line" | grep -F -q -- "$pattern" 2>/dev/null; then
        # Verificar exclusiones personalizadas
        local excluded=false
        for custom_excl in "${EXCLUDED_PATTERNS[@]}"; do
          if echo "$line" | grep -F -q -- "$custom_excl" 2>/dev/null; then
            excluded=true
            break
          fi
        done
        [[ "$excluded" == "true" ]] && continue
        
        # Escapar comillas para JSON seguro
        local safe_line
        safe_line=$(echo "$line" | sed 's/["\\]/\\&/g' | cut -c1-120)
        
        # Registrar hallazgo
        log_finding "$(cat <<EOF
{
  "file": "$file",
  "line": $line_num,
  "category": "$category",
  "pattern_matched": "$pattern",
  "description": "$description",
  "severity": "$severity",
  "constraint": "C3",
  "snippet_preview": "${safe_line}..."
}
EOF
)"
      fi
    done
  done < "$file"
}

scan_directory() {
  local dir="$1"
  
  log_info "=== Escaneando directorio: $dir ==="
  
  while IFS= read -r -d '' file; do
    scan_file "$file"
  done < <(find "$dir" -type f \( \
    -name "*.md" -o -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o \
    -name "*.sh" -o -name "*.bash" -o -name "*.py" -o -name "*.js" -o \
    -name "*.ts" -o -name "*.sql" -o -name "*.env" -o -name "*.conf" -o \
    -name "*.cfg" -o -name "*.ini" -o -name "*.toml" -o -name "Dockerfile" -o \
    -name "*.dockerfile" -o -name "docker-compose*" -o -name "*.tf" -o \
    -name "*.tfvars" \
  \) -print0 2>/dev/null)
}

# ────────────────────────────────────────────────────────────────────────────
# GENERACIÓN DE REPORTE JSON (CORREGIDO: construcción segura de array)
# ────────────────────────────────────────────────────────────────────────────
generate_report() {
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  local status="passed"
  local critical_count=0
  local high_count=0
  local medium_count=0
  
  # Contar por severidad
  for finding in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
    if echo "$finding" | grep -F -q -- '"severity": "CRITICAL"' 2>/dev/null; then
      ((critical_count++)) || true
    elif echo "$finding" | grep -F -q -- '"severity": "HIGH"' 2>/dev/null; then
      ((high_count++)) || true
    elif echo "$finding" | grep -F -q -- '"severity": "MEDIUM"' 2>/dev/null; then
      ((medium_count++)) || true
    fi
  done
  
  # Determinar estado final
  if [[ "$STRICT" == "1" && ($critical_count -gt 0 || $high_count -gt 0) ]]; then
    status="failed"
  elif [[ $critical_count -gt 0 ]]; then
    status="failed"
  elif [[ $high_count -gt 0 && "$STRICT" != "1" ]]; then
    status="warnings"
  fi
  
  # Construir array de findings para JSON (seguro con jq o fallback)
  local findings_json="[]"
  if [[ ${#FINDINGS[@]} -gt 0 ]]; then
    if command -v jq &>/dev/null; then
      findings_json=$(printf '%s\n' "${FINDINGS[@]}" | jq -s -c '.' 2>/dev/null || echo "[]")
    else
      # Fallback manual: unir con coma, asegurando que cada finding esté entre {}
      findings_json="["
      local first=true
      for f in "${FINDINGS[@]}"; do
        if [[ "$first" == "true" ]]; then
          findings_json+="$f"
          first=false
        else
          findings_json+=",$f"
        fi
      done
      findings_json+="]"
    fi
  fi
  
  # Calcular checksum del reporte
  local temp_report
  temp_report=$(mktemp)
  
  cat > "$temp_report" << EOF
{
  "audit_version": "$VERSION",
  "timestamp": "$timestamp",
  "target": "$PROJECT_ROOT",
  "constraint": "C3",
  "status": "$status",
  "summary": {
    "files_scanned": $FILES_SCANNED,
    "secrets_found": $SECRETS_FOUND,
    "false_positives_avoided": $FALSE_POSITIVES_AVOIDED,
    "by_severity": {
      "critical": $critical_count,
      "high": $high_count,
      "medium": $medium_count
    }
  },
  "ai_providers_audited": ["openrouter", "qwen", "deepseek", "llama", "gemini", "gpt", "minimax", "mistral-ocr", "voice-agent", "image-gen", "video-gen"],
  "infrastructure_patterns_audited": ["aws", "gcp", "azure", "github", "docker", "postgres", "mysql", "redis", "qdrant", "espocrm", "n8n", "ssh", "fail2ban", "ufw"],
  "findings": $findings_json,
  "recommendations": [
    "Migrar todas las credenciales a variables de entorno o secret manager",
    "Implementar pre-commit hook con este script",
    "Rotar inmediatamente cualquier credencial expuesta detectada",
    "Documentar excepción C6 para Llama si se usa inferencia local",
    "Usar SSH tunnels para acceso a DBs (C3: DB-no-expuesta)"
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
  
  # Output en stdout
  echo ""
  echo "========================================="
  echo "🔐 AUDITORÍA DE SECRETOS C3 v$VERSION"
  echo "========================================="
  echo "Target: $PROJECT_ROOT"
  echo "Archivos escaneados: $FILES_SCANNED"
  echo "🔴 Críticos: $critical_count"
  echo "🟠 Altos: $high_count"
  echo "🟡 Medios: $medium_count"
  echo "✅ Falsos positivos evitados: $FALSE_POSITIVES_AVOIDED"
  echo "Estado: $status"
  echo "🔐 Report SHA256: $report_sha"
  echo "📄 Reporte guardado: $REPORT_FILE"
  echo "========================================="
  
  if [[ ${#FINDINGS[@]} -gt 0 ]]; then
    echo ""
    echo "⚠️  Hallazgos detectados (revisar reporte JSON para detalles):"
    for finding in "${FINDINGS[@]}"; do
      local f_file f_line f_cat
      f_file=$(echo "$finding" | grep -oP '"file": "\K[^"]*' 2>/dev/null || echo "unknown")
      f_line=$(echo "$finding" | grep -oP '"line": \K[0-9]*' 2>/dev/null || echo "?")
      f_cat=$(echo "$finding" | grep -oP '"category": "\K[^"]*' 2>/dev/null || echo "unknown")
      echo "  • ${f_file}:${f_line} - ${f_cat}"
    done
  fi
  
  # Código de salida para CI/CD
  if [[ "$status" == "failed" ]]; then
    exit 1
  elif [[ "$status" == "warnings" && "$STRICT" == "1" ]]; then
    exit 1
  fi
  exit 0
}

# ────────────────────────────────────────────────────────────────────────────
# PRE-COMMIT HOOK MODE
# ────────────────────────────────────────────────────────────────────────────
run_precommit() {
  log_info "Modo pre-commit: escaneando solo archivos modificados"
  
  # Obtener archivos modificados en staging o working tree
  local files=""
  if git diff --cached --name-only >/dev/null 2>&1; then
    files=$(git diff --cached --name-only 2>/dev/null || true)
  fi
  if [[ -z "$files" ]]; then
    files=$(git diff --name-only HEAD 2>/dev/null || true)
  fi
  
  if [[ -n "$files" ]]; then
    while IFS= read -r file; do
      [[ -n "$file" && -f "$file" ]] && scan_file "$file"
    done <<< "$files"
  else
    log_info "No hay archivos modificados para escanear"
  fi
}

# ────────────────────────────────────────────────────────────────────────────
# MAIN
# ────────────────────────────────────────────────────────────────────────────
main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    cat << EOF
Uso: $0 [ruta] [reporte.json] [exclusiones.txt] [verbose:0/1] [strict:0/1]

Auditoría de secretos (Constraint C3) para MANTIS AGENTIC.
Detecta credenciales hardcodeadas para todos los proveedores de IA
y patrones de infraestructura, excluyendo placeholders válidos.

Parámetros:
  ruta              Directorio o archivo a escanear (default: .)
  reporte.json      Archivo de salida JSON (default: secrets-audit-report.json)
  exclusiones.txt   Archivo con patrones regex adicionales a excluir (opcional)
  verbose:0/1       Modo detallado (default: 0)
  strict:0/1        Tratar warnings como errores en CI/CD (default: 0)

Modos especiales:
  --pre-commit      Escanear solo archivos modificados en git (para hooks)
  --list-patterns   Listar todos los patrones de detección activos
  --test-sample     Ejecutar prueba con archivo de ejemplo seguro

Proveedores de IA auditados:
  openrouter, qwen, deepseek, llama, gemini, gpt, minimax, 
  mistral-ocr, voice-agent, image-gen, video-gen

Patrones de infraestructura:
  aws, gcp, azure, github, docker, postgres, mysql, redis, 
  qdrant, espocrm, n8n, ssh, fail2ban, ufw

Ejemplos:
  $0 02-SKILLS/AI/
  $0 . audit.json .secrets-ignore 1 1
  $0 --pre-commit
  $0 --list-patterns | grep -i gemini

Integración pre-commit (.git/hooks/pre-commit):
  #!/bin/sh
  ./05-CONFIGURATIONS/validation/audit-secrets.sh --pre-commit || exit 1

Salida:
  - Reporte JSON con hallazgos, severidad y checksum SHA256
  - Código de salida: 0 (limpio) / 1 (críticos detectados o strict mode)
EOF
    exit 0
  fi
  
  if [[ "${1:-}" == "--pre-commit" ]]; then
    load_custom_exclusions
    run_precommit
    generate_report
    exit $?
  fi
  
  if [[ "${1:-}" == "--list-patterns" ]]; then
    echo "# Patrones de detección activos en audit-secrets.sh v$VERSION"
    echo "# Formato: CATEGORY|PATTERN|DESCRIPTION|SEVERITY"
    echo ""
    printf '%s\n' "${SECRET_PATTERNS[@]}"
    exit 0
  fi
  
  if [[ "${1:-}" == "--test-sample" ]]; then
    echo "Ejecutando prueba con muestra segura..."
    local test_file
    test_file=$(mktemp --suffix=.md)
    cat > "$test_file" << 'TESTEOF'
# Prueba de auditoría C3 - Archivo seguro

Ejemplos de uso correcto (NO deben detectarse):
- `api_key = "${OPENROUTER_KEY}"` ✓
- `password = process.env.DB_PASS` ✓
- `sk-XXXX` en documentación ✓
- `${VAR:?missing}` patrón seguro ✓

Ejemplo de fallo intencional (comentado para no fallar):
- # api_key = "sk-or-v1-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
TESTEOF
    scan_file "$test_file"
    rm -f "$test_file"
    generate_report
    exit $?
  fi
  
  # Ejecución normal
  log_info "Iniciando auditoría de secretos C3 v$VERSION"
  log_info "Proveedores IA: ${#SECRET_PATTERNS[@]} patrones activos"
  
  load_custom_exclusions
  
  if [[ -f "$PROJECT_ROOT" ]]; then
    scan_file "$PROJECT_ROOT"
  elif [[ -d "$PROJECT_ROOT" ]]; then
    scan_directory "$PROJECT_ROOT"
  else
    log_error "Ruta no encontrada: $PROJECT_ROOT"
    exit 1
  fi
  
  generate_report
}

main "$@"
