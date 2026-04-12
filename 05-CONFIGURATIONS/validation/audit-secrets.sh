
#!/usr/bin/env bash
#---
# metadata_version: 1.0
# sdd_compliant: true
# ai_parser_compatible: true
# purpose: "Auditoría de secretos (C3) para todo el repositorio MANTIS AGENTIC"
# scope: "02-SKILLS/, 05-CONFIGURATIONS/, archivos de código, config, docs"
# ai_providers_supported: ["openrouter","qwen","deepseek","llama","gemini","gpt","minimax","mistral-ocr","voice-agent","image-gen","video-gen"]
# infrastructure_patterns: ["aws","gcp","azure","github","docker","postgres","mysql","redis","qdrant","espocrm","n8n"]
# output_format: "json + stdout + exit code para CI/CD"
# ---
# ============================================================================
# AUDIT-SECRETS.SH v1.0
# Detección de credenciales hardcodeadas (Constraint C3)
# Propósito: Escanear archivos del repositorio en busca de patrones de
# secretos expuestos, excluyendo placeholders válidos, y generar reporte
# auditivo con checksum SHA256 para integración en pre-commit/CI.
# ============================================================================
set -euo pipefail

# ────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN GLOBAL
# ────────────────────────────────────────────────────────────────────────────
readonly VERSION="1.0.0"
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
# PATRONES DE SECRETOS POR CATEGORÍA
# Formato: "CATEGORY|PATTERN_REGEX|DESCRIPTION|SEVERITY"
# ────────────────────────────────────────────────────────────────────────────
readonly -a SECRET_PATTERNS=(
  # ── AI PROVIDERS ───────────────────────────────────────────────────────
  "AI-OPENROUTER|sk-or-v1-[a-zA-Z0-9]{48,}|OpenRouter API key hardcodeada|CRITICAL"
  "AI-OPENROUTER|Bearer\s+sk-or-v1[a-zA-Z0-9_-]{20,}|OpenRouter Bearer token expuesto|CRITICAL"
  
  "AI-QWEN|qwen_api_key\s*=\s*['\"][a-zA-Z0-9]{32,}['\"]|Qwen API key hardcodeada|CRITICAL"
  "AI-QWEN|DASHSCOPE_API_KEY\s*=\s*['\"][^'\"]{20,}['\"]|DashScope/Qwen credential expuesta|CRITICAL"
  
  "AI-DEEPSEEK|sk-ds-[a-zA-Z0-9]{40,}|DeepSeek API key hardcodeada|CRITICAL"
  "AI-DEEPSEEK|deepseek_key\s*[:=]\s*['\"][a-zA-Z0-9]{30,}['\"]|DeepSeek credential en texto plano|CRITICAL"
  
  "AI-LLAMA|llama_api_token\s*=\s*['\"][a-zA-Z0-9_-]{40,}['\"]|Llama API token hardcodeado|HIGH"
  "AI-LLAMA|HF_TOKEN\s*=\s*['\"]hf_[a-zA-Z]{34}['\"]|HuggingFace token expuesto (para Llama)|CRITICAL"
  
  "AI-GEMINI|AIzaSy[a-zA-Z0-9_-]{33}|Google Gemini API key hardcodeada|CRITICAL"
  "AI-GEMINI|gemini_api_key\s*[:=]\s*['\"][a-zA-Z0-9_-]{30,}['\"]|Gemini credential en texto plano|CRITICAL"
  
  "AI-GPT|sk-proj-[a-zA-Z0-9]{48,}|OpenAI GPT project key hardcodeada|CRITICAL"
  "AI-GPT|sk-[a-zA-Z0-9]{48,}|OpenAI API key genérica expuesta|CRITICAL"
  "AI-GPT|OPENAI_API_KEY\s*=\s*['\"][^'\"]{20,}['\"]|OPENAI_API_KEY hardcodeada|CRITICAL"
  
  "AI-MINIMAX|minimax_api_key\s*=\s*['\"][a-zA-Z0-9]{32,}['\"]|MiniMax API key hardcodeada|CRITICAL"
  "AI-MINIMAX|Authorization:\s*Bearer\s+[a-zA-Z0-9._-]{40,}|MiniMax Bearer token expuesto|HIGH"
  
  "AI-MISTRAL-OCR|mistral_ocr_key\s*=\s*['\"][a-zA-Z0-9_-]{32,}['\"]|Mistral OCR key hardcodeada|HIGH"
  "AI-MISTRAL-OCR|MISTRAL_API_KEY\s*=\s*['\"][^'\"]{20,}['\"]|Mistral API key en texto plano|CRITICAL"
  
  "AI-VOICE|deepgram_api_key\s*=\s*['\"][a-zA-Z0-9_-]{40,}['\"]|Deepgram STT key hardcodeada|CRITICAL"
  "AI-VOICE|assemblyai_key\s*[:=]\s*['\"][a-zA-Z0-9]{32,}['\"]|AssemblyAI credential expuesta|HIGH"
  "AI-VOICE|elevenlabs_api_key\s*=\s*['\"][a-zA-Z0-9_-]{32,}['\"]|ElevenLabs TTS key hardcodeada|HIGH"
  
  "AI-IMAGE|dalle_api_key\s*=\s*['\"][^'\"]{20,}['\"]|DALL-E API key hardcodeada|CRITICAL"
  "AI-IMAGE|stability_api_key\s*[:=]\s*['\"][a-zA-Z0-9_-]{32,}['\"]|Stability AI key expuesta|CRITICAL"
  "AI-IMAGE|replicate_token\s*=\s*['\"][a-zA-Z0-9/_-]{32,}['\"]|Replicate token hardcodeado|HIGH"
  
  "AI-VIDEO|runwayml_key\s*=\s*['\"][a-zA-Z0-9_-]{32,}['\"]|RunwayML API key hardcodeada|HIGH"
  "AI-VIDEO|pika_labs_token\s*[:=]\s*['\"][^'\"]{20,}['\"]|Pika Labs token expuesto|MEDIUM"
  
  # ── CLOUD PROVIDERS ────────────────────────────────────────────────────
  "CLOUD-AWS|AKIA[0-9A-Z]{16}|AWS Access Key ID hardcodeado|CRITICAL"
  "CLOUD-AWS|aws_secret_access_key\s*=\s*['\"][a-zA-Z0-9/+=]{40}['\"]|AWS Secret Key hardcodeada|CRITICAL"
  "CLOUD-AWS|arn:aws:iam::[0-9]{12}:user/[a-zA-Z0-9_/-]+|AWS ARN con credencial potencial|MEDIUM"
  
  "CLOUD-GCP|AIza[0-9A-Za-z_-]{35}|Google Cloud API key hardcodeada|CRITICAL"
  "CLOUD-GCP|service_account.*private_key.*-----BEGIN PRIVATE KEY-----|GCP service account key expuesta|CRITICAL"
  
  "CLOUD-AZURE|client_secret\s*=\s*['\"][a-zA-Z0-9~._-]{34}['\"]|Azure client secret hardcodeado|CRITICAL"
  "CLOUD-AZURE|TenantId\s*[:=]\s*['\"][a-f0-9-]{36}['\"]|Azure Tenant ID con posible secret adjunto|HIGH"
  
  # ── VERSION CONTROL & CI/CD ───────────────────────────────────────────
  "VCS-GITHUB|ghp_[a-zA-Z0-9]{36}|GitHub Personal Access Token hardcodeado|CRITICAL"
  "VCS-GITHUB|gho_[a-zA-Z0-9]{36}|GitHub OAuth Token expuesto|CRITICAL"
  "VCS-GITHUB|ghs_[a-zA-Z0-9]{36}|GitHub Server-to-Server Token hardcodeado|CRITICAL"
  "VCS-GITHUB|github_pat_[a-zA-Z0-9]{22}_[a-zA-Z0-9]{59}|GitHub Fine-Grained PAT expuesto|CRITICAL"
  
  "VCS-GITLAB|glpat-[a-zA-Z0-9_-]{20}|GitLab Personal Access Token hardcodeado|CRITICAL"
  
  "VCS-BITBUCKET|ATBB[a-zA-Z0-9_-]{32}|Bitbucket App Password expuesto|HIGH"
  
  # ── DATABASES & CACHING ───────────────────────────────────────────────
  "DB-POSTGRES|postgresql://[^:]+:[^@]+@[^/]+|Postgres connection string con password|CRITICAL"
  "DB-POSTGRES|PGPASSWORD\s*=\s*['\"][^'\"]{8,}['\"]|Postgres password hardcodeada|CRITICAL"
  
  "DB-MYSQL|mysql://[^:]+:[^@]+@[^/]+|MySQL connection string con password|CRITICAL"
  "DB-MYSQL|MYSQL_PASSWORD\s*=\s*['\"][^'\"]{8,}['\"]|MySQL password hardcodeada|CRITICAL"
  
  "DB-REDIS|redis://:[^@]+@|Redis connection string con password|HIGH"
  "DB-REDIS|REDIS_PASSWORD\s*=\s*['\"][^'\"]{8,}['\"]|Redis password hardcodeada|HIGH"
  
  "DB-QDRANT|QDRANT_API_KEY\s*=\s*['\"][a-zA-Z0-9_-]{32,}['\"]|Qdrant API key hardcodeada|CRITICAL"
  "DB-QDRANT|qdrant_url\s*=\s*['\"]https://[^:]+:[^@]+@|Qdrant URL con credenciales|HIGH"
  
  "DB-ESPORM|ESPOCRM_API_KEY\s*=\s*['\"][a-zA-Z0-9]{32,}['\"]|EspoCRM API key hardcodeada|HIGH"
  "DB-ESPORM|espo_password\s*[:=]\s*['\"][^'\"]{8,}['\"]|EspoCRM password en texto plano|CRITICAL"
  
  # ── INFRASTRUCTURE & ORCHESTRATION ─────────────────────────────────────
  "INFRA-DOCKER|DOCKER_HUB_TOKEN\s*=\s*['\"][a-zA-Z0-9-]{32,}['\"]|Docker Hub token hardcodeado|HIGH"
  "INFRA-DOCKER|docker login -u [^ ]+ -p [^ ]+|Docker login con password en CLI|CRITICAL"
  
  "INFRA-N8N|N8N_ENCRYPTION_KEY\s*=\s*['\"][a-zA-Z0-9]{32,}['\"]|n8n encryption key hardcodeada|CRITICAL"
  "INFRA-N8N|WEBHOOK_URL\s*=\s*['\"]https://[^/]+/webhook/[a-zA-Z0-9_-]{32,}['\"]|n8n webhook URL con token|MEDIUM"
  
  "INFRA-SSH|-----BEGIN (RSA|OPENSSH|EC|DSA) PRIVATE KEY-----|Private SSH key hardcodeado|CRITICAL"
  "INFRA-SSH|sshpass\s+-p\s+['\"][^'\"]+['\"]|sshpass con password en texto plano|CRITICAL"
  
  "INFRA-FAIL2BAN|fail2ban_password\s*=\s*['\"][^'\"]{8,}['\"]|Fail2ban password hardcodeada|MEDIUM"
  
  "INFRA-UFW|ufw\s+allow\s+from\s+[0-9.]+/32\s+to\s+any\s+port\s+[0-9]+\s+comment\s+['\"][^'\"]*key[^'\"]*['\"]|Regla UFW con referencia a clave|MEDIUM"
  
  # ── GENERAL SECRET PATTERNS ───────────────────────────────────────────
  "GEN-PASSWORD|password\s*[:=]\s*['\"][^'\"]{8,}['\"]|Password genérico hardcodeado|HIGH"
  "GEN-PASSWORD|passwd\s*[:=]\s*['\"][^'\"]{8,}['\"]|Passwd hardcodeado (variante)|HIGH"
  "GEN-PASSWORD|pwd\s*[:=]\s*['\"][^'\"]{8,}['\"]|Pwd hardcodeado (variante)|MEDIUM"
  
  "GEN-APIKEY|api[_-]?key\s*[:=]\s*['\"][a-zA-Z0-9_-]{16,}['\"]|API key genérica hardcodeada|HIGH"
  "GEN-APIKEY|apikey\s*[:=]\s*['\"][a-zA-Z0-9]{20,}['\"]|ApiKey sin guiones hardcodeada|HIGH"
  
  "GEN-SECRET|secret\s*[:=]\s*['\"][a-zA-Z0-9_-]{16,}['\"]|Secret genérico hardcodeado|HIGH"
  "GEN-SECRET|private[_-]?key\s*[:=]\s*['\"][^'\"]{20,}['\"]|Private key reference hardcodeada|CRITICAL"
  
  "GEN-JWT|eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*|JWT token hardcodeado|HIGH"
  
  "GEN-BASICAUTH|Authorization:\s*Basic\s+[A-Za-z0-9+/=]{20,}|Basic Auth header hardcodeado|HIGH"
  
  "GEN-BEARER|Authorization:\s*Bearer\s+[a-zA-Z0-9._-]{20,}|Bearer token genérico expuesto|HIGH"
)

# ────────────────────────────────────────────────────────────────────────────
# PATRONES DE EXCLUSIÓN (PLACEHOLDERS VÁLIDOS - NO SON FALSOS POSITIVOS)
# ────────────────────────────────────────────────────────────────────────────
readonly -a EXCLUSION_PATTERNS=(
  '\$\{[A-Z_0-9]+\}'           # ${ENV_VAR}
  '\$\([A-Z_0-9]+\)'           # $(ENV_VAR) shell
  'process\.env\.[A-Z_0-9]+'  # process.env.VAR Node.js
  'os\.getenv\([A-Z_0-9_]+\)' # os.getenv() Python
  'getenv\([A-Z_0-9_]+\)'     # getenv() genérico
  'ENV\[[A-Z_0-9_]+\]'        # ENV['VAR'] Ruby
  '<[A-Z_0-9_]+>'             # <PLACEHOLDER>
  'XXXX+'                     # XXXX, XXXXXXX
  'TODO'                      # TODO markers
  'FIXME'                     # FIXME markers
  'CHANGEME'                  # CHANGEME markers
  'your[_-]?key[_-]?here'     # Documentación
  'your[_-]?api[_-]?key'      # Documentación
  'placeholder'               # Placeholder genérico
  'REPLACE_ME'                # REPLACE_ME
  'INSERT_KEY_HERE'           # Instrucciones
  'GET_YOUR_KEY_FROM'         # Instrucciones
  'https://.*\.example\.com'  # URLs de ejemplo
  'sk-XXXX'                   # Key ofuscada en docs
  'api_key_XXXX'              # Key ofuscada en docs
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
# UTILIDADES
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

is_placeholder() {
  local line="$1"
  for pattern in "${EXCLUSION_PATTERNS[@]}"; do
    if echo "$line" | grep -qE "$pattern"; then
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
# MOTOR DE DETECCIÓN
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
      
      if echo "$line" | grep -qE "$pattern"; then
        # Verificar exclusiones personalizadas
        local excluded=false
        for custom_excl in "${EXCLUDED_PATTERNS[@]}"; do
          if echo "$line" | grep -qE "$custom_excl"; then
            excluded=true
            break
          fi
        done
        [[ "$excluded" == "true" ]] && continue
        
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
  "snippet_preview": "$(echo "$line" | sed 's/["\]/\\&/g' | cut -c1-120)..."
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
# GENERACIÓN DE REPORTE JSON
# ────────────────────────────────────────────────────────────────────────────
generate_report() {
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  
  local status="passed"
  local critical_count=0
  local high_count=0
  local medium_count=0
  
  # Contar por severidad
  for finding in "${FINDINGS[@]}"; do
    if echo "$finding" | grep -q '"severity": "CRITICAL"'; then
      ((critical_count++)) || true
    elif echo "$finding" | grep -q '"severity": "HIGH"'; then
      ((high_count++)) || true
    elif echo "$finding" | grep -q '"severity": "MEDIUM"'; then
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
  
  # Construir array de findings para JSON
  local findings_json="[]"
  if [[ ${#FINDINGS[@]} -gt 0 ]]; then
    findings_json=$(printf '%s\n' "${FINDINGS[@]}" | paste -sd ',' | sed 's/}{/},{/g')
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
  "findings": [$findings_json],
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
      echo "  • $(echo "$finding" | grep -o '"file": "[^"]*"' | cut -d'"' -f4):$(echo "$finding" | grep -o '"line": [0-9]*' | cut -d' ' -f2) - $(echo "$finding" | grep -o '"category": "[^"]*"' | cut -d'"' -f4)"
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
  local files
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
    # Crear archivo temporal con placeholders válidos (debería pasar)
    local test_file
    test_file=$(mktemp --suffix=.md)
    cat > "$test_file" << 'TESTEOF'
# Prueba de auditoría C3 - Archivo seguro

Ejemplos de uso correcto (NO deben detectarse):
- `api_key = "${OPENROUTER_KEY}"` ✓
- `password = process.env.DB_PASS` ✓
- `sk-XXXX` en documentación ✓

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

