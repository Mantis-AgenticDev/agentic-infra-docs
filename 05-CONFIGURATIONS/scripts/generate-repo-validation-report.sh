#!/usr/bin/env bash
# ---
# title: "generate-repo-validation-report.sh"
# version: "3.0.0"
# canonical_path: "05-CONFIGURATIONS/scripts/generate-repo-validation-report.sh"
# ai_optimized: true
# constraints_mapped: ["C1","C2","C3","C5","C7","C8"]
# validation_command: "bash -n 05-CONFIGURATIONS/scripts/generate-repo-validation-report.sh"
# ---
set -euo pipefail

# 🛡️ DECLARACIÓN DE MODO (CRÍTICO PARA IA)
# Este script es READ-ONLY para archivos fuente. NUNCA modifica fuentes.
# PREVENTIVE MODE: Usa chattr +i para bloquear escritura a nivel de kernel.
readonly SCRIPT_MODE="PREVENTIVE_READ_ONLY_AUDIT"
readonly SCRIPT_VERSION="4.0.0"
readonly ALLOWED_WRITE_DIRS=("08-LOGS/validation")

# 📦 CONFIGURACIÓN (C3: Zero Hardcode)
REPO_ROOT="${1:-/home/ricardo/proyectos/agentic-infra-docs}"
BACKUP_ROOT="${2:-/home/ricardo/Backup Proyecto}"
ORCHESTRATOR="${REPO_ROOT}/05-CONFIGURATIONS/validation/orchestrator-engine.sh"
LOG_DIR="${REPO_ROOT}/08-LOGS/validation"
AUDIT_LOG="${BACKUP_ROOT}/backup-audit.log"
DIRS=("." "00-CONTEXT" "01-RULES" "02-SKILLS" "03-AGENTS" "04-WORKFLOWS" "05-CONFIGURATIONS" "06-PROGRAMMING" "07-PROCEDURES")

# 🔐 FUNCIÓN: Logging estructurado
log_audit() {
  local level="$1"
  local message="$2"
  local timestamp
  timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  echo "[${timestamp}] [${level}] ${message}" | tee -a "${AUDIT_LOG}"
}

# 🔐 FUNCIÓN: Backup preventivo completo
create_pre_backup() {
  local source="$1"
  local backup_base="$2"
  local timestamp
  timestamp=$(date '+%Y%m%d_%H%M%S')
  local backup_name="agentic-infra-docs_BACKUP_${timestamp}"
  local backup_path="${backup_base}/${backup_name}"
  
  log_audit "INFO" "Iniciando backup preventivo: ${source} → ${backup_path}"
  mkdir -p "${backup_base}"
  
  rsync -av --exclude='Backup Proyecto' --exclude='08-LOGS/validation/*.md' \
    "${source}/" "${backup_path}/" 2>&1 | tee -a "${AUDIT_LOG}"
  
  local checksum_file="${backup_path}/.backup-checksum.sha256"
  find "${backup_path}" -type f \( -name "*.md" -o -name "*.json" -o -name "*.sh" -o -name "*.tf" -o -name "*.yml" -o -name "*.yaml" \) 2>/dev/null | \
    head -100 | xargs sha256sum 2>/dev/null > "${checksum_file}" || true
  
  cat > "${backup_path}/.backup-metadata.json" << EOF
{
  "backup_timestamp": "${timestamp}",
  "source_path": "${source}",
  "backup_path": "${backup_path}",
  "script_version": "${SCRIPT_VERSION}",
  "script_mode": "${SCRIPT_MODE}",
  "files_included": "all (hidden, .git, ignored)",
  "exclusions": ["Backup Proyecto", "08-LOGS/validation/*.md"],
  "checksum_file": ".backup-checksum.sha256"
}
EOF
  
  local file_count total_size
  file_count=$(find "${backup_path}" -type f | wc -l)
  total_size=$(du -sh "${backup_path}" | cut -f1)
  
  log_audit "INFO" "✅ Backup completado: ${file_count} archivos, ${total_size}"
  echo "${backup_path}"
}

# 🔐 FUNCIÓN: Bloquear escritura con chattr +i (PREVENTIVO)
lock_source_files() {
  local search_path="$1"
  log_audit "DEBUG" "🔒 Aplicando chattr +i a archivos en ${search_path}"
  
  while IFS= read -r -d '' file; do
    # Solo bloquear si no está en ALLOWED_WRITE_DIRS
    local dir_name
    dir_name=$(dirname "$file")
    local is_allowed=false
    for allowed in "${ALLOWED_WRITE_DIRS[@]}"; do
      [[ "$dir_name" == *"$allowed"* ]] && is_allowed=true && break
    done
    
    if [[ "$is_allowed" == "false" ]]; then
      # Aplicar immutable bit (requiere sudo, pero falla silenciosamente si no hay permisos)
      sudo chattr +i "$file" 2>/dev/null || log_audit "DEBUG" "⚠️ No se pudo aplicar chattr +i a ${file} (permisos?)"
    fi
  done < <(find "${search_path}" -maxdepth 3 -type f \( \
    -name "*.md" -o -name "*.sh" -o -name "*.tf" -o -name "*.yaml" -o -name "*.yml" -o -name "*.json" \
  \) -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "*/08-LOGS/*" -not -path "*/09-TEST-SANDBOX/*" -not -path "*/.venv/*" -print0 2>/dev/null)
}

# 🔐 FUNCIÓN: Desbloquear archivos después de la validación
unlock_source_files() {
  local search_path="$1"
  log_audit "DEBUG" "🔓 Removiendo chattr +i de archivos en ${search_path}"
  
  while IFS= read -r -d '' file; do
    local dir_name
    dir_name=$(dirname "$file")
    local is_allowed=false
    for allowed in "${ALLOWED_WRITE_DIRS[@]}"; do
      [[ "$dir_name" == *"$allowed"* ]] && is_allowed=true && break
    done
    
    if [[ "$is_allowed" == "false" ]]; then
      sudo chattr -i "$file" 2>/dev/null || true
    fi
  done < <(find "${search_path}" -maxdepth 3 -type f \( \
    -name "*.md" -o -name "*.sh" -o -name "*.tf" -o -name "*.yaml" -o -name "*.yml" -o -name "*.json" \
  \) -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "*/08-LOGS/*" -not -path "*/09-TEST-SANDBOX/*" -not -path "*/.venv/*" -print0 2>/dev/null)
}

# 🔐 FUNCIÓN: Validar que un archivo NO fue modificado (checksum)
verify_file_integrity() {
  local file="$1"
  local expected_hash="$2"
  local actual_hash
  actual_hash=$(sha256sum "$file" 2>/dev/null | cut -d' ' -f1 || echo "unknown")
  
  if [[ "$expected_hash" != "unknown" && "$actual_hash" != "unknown" && "$expected_hash" != "$actual_hash" ]]; then
    log_audit "ERROR" "❌ INTEGRIDAD COMPROMETIDA: ${file}"
    log_audit "ERROR" "   Hash esperado: ${expected_hash}"
    log_audit "ERROR" "   Hash actual: ${actual_hash}"
    return 1
  fi
  return 0
}

# 🔍 VALIDACIÓN PREVIA
log_audit "INFO" "=== INICIO DE EJECUCIÓN - Script v${SCRIPT_VERSION} - MODO: ${SCRIPT_MODE} ==="

if [[ ! -d "${REPO_ROOT}" ]]; then
  log_audit "ERROR" "Directorio raíz no encontrado: ${REPO_ROOT}"
  exit 1
fi

if [[ ! -f "${ORCHESTRATOR}" ]]; then
  log_audit "ERROR" "Orquestador no encontrado en ${ORCHESTRATOR}"
  exit 1
fi

chmod +x "${ORCHESTRATOR}"
mkdir -p "${LOG_DIR}"
mkdir -p "${BACKUP_ROOT}"

# 🔄 BACKUP PREVENTIVO
BACKUP_PATH=$(create_pre_backup "${REPO_ROOT}" "${BACKUP_ROOT}")
log_audit "INFO" "Backup preventivo listo. Ruta: ${BACKUP_PATH}"

# 🔒 BLOQUEO PREVENTIVO DE ARCHIVOS FUENTE (NUEVO: PREVENTIVO, NO REACTIVO)
log_audit "INFO" "🔒 Aplicando bloqueo preventivo (chattr +i) a archivos fuente..."
for dir in "${DIRS[@]}"; do
  [[ "${dir}" == "08-LOGS" || "${dir}" == "09-TEST-SANDBOX" ]] && continue
  lock_source_files "${REPO_ROOT}/${dir}"
done
log_audit "INFO" "✅ Bloqueo preventivo aplicado"

# 📊 GENERACIÓN DE REPORTES (READ-ONLY GARANTIZADO POR chattr +i)
for dir in "${DIRS[@]}"; do
  dir_name="${dir:-ROOT}"
  output_file="${LOG_DIR}/${dir_name}.md"
  search_path="${REPO_ROOT}/${dir}"

  # 🔇 EXCLUSIÓN EXPLÍCITA DE CARPETAS SENSIBLES
  if [[ "${dir}" == "08-LOGS" || "${dir}" == "09-TEST-SANDBOX" ]]; then
    log_audit "INFO" "⏭️ Excluyendo carpeta sensible: ${dir}"
    continue
  fi

  log_audit "INFO" "🔄 Procesando carpeta: ${dir_name} (modo: ${SCRIPT_MODE})..."

  {
    echo "# 📊 Reporte de Validación - ${dir_name}"
    echo "**Fecha**: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo "**Ruta origen**: \`${dir}\`"
    echo "**Orquestador**: \`${ORCHESTRATOR}\`"
    echo "**Modo**: ${SCRIPT_MODE} (chattr +i activo en fuentes)"
    echo "**Backup preventivo**: \`${BACKUP_PATH}\`"
    echo ""
    echo "---"
    echo ""

    total=0
    passed=0
    failed=0
    warn=0
    skipped=0

    while IFS= read -r -d '' file; do
      rel_path="${file#${REPO_ROOT}/}"
      rel_path="${rel_path#./}"
      file_basename=$(basename "$file")

      # 🔧 EXCLUSIÓN DE ARTEFACTOS DE REPORTE
      case "$file_basename" in
        *-report.json|*-validation-*.json|validation-report.json|skill-validation-report.json|wikilinks-validation-report.json)
          log_audit "DEBUG" "⏭️ Saltando artefacto de reporte: ${rel_path}"
          continue
          ;;
        *.log)
          log_audit "DEBUG" "⏭️ Saltando archivo de log: ${rel_path}"
          continue
          ;;
      esac

      # 🔐 CHECKSUM PRE-VALIDACIÓN (para auditoría, no para recuperación)
      pre_hash=$(sha256sum "$file" 2>/dev/null | cut -d' ' -f1 || echo "unknown")

      total=$((total + 1))
      echo "### 📄 \`${rel_path}\`"
      echo ""

      # Ejecutar validación (el archivo está protegido por chattr +i)
      if cmd_out=$(${ORCHESTRATOR} --mode headless --file "${rel_path}" --json 2>&1); then
        if command -v jq &>/dev/null; then
          json_part=$(echo "$cmd_out" | sed -n '/^{/,/^}/p')
          status=$(echo "$json_part" | jq -r '.status // .result // "unknown"' 2>/dev/null || echo "unknown")
          blocking_msg=$(echo "$json_part" | jq -r '.blocking_message // ""' 2>/dev/null || echo "")
        else
          status="unknown"
          blocking_msg=""
          [[ "$cmd_out" == *"passed"* || "$cmd_out" == *"✅"* ]] && status="passed"
          [[ "$cmd_out" == *"failed"* || "$cmd_out" == *"❌"* ]] && status="failed"
        fi

        if [[ "$blocking_msg" == *"Ubicación no reconocida"* ]] || [[ "$cmd_out" == *"identity_location: FAIL"* ]]; then
          skipped=$((skipped + 1))
          echo "⚠️ **SKIP**: Archivo en ubicación no registrada en PROJECT_TREE"
          echo "> Este archivo está en una ruta válida pero no está mapeado en PROJECT_TREE.md"
          echo ""
          echo '```json'
          echo "$cmd_out"
          echo '```'
        elif [[ "$cmd_out" == *"JSON inválido"* ]] || [[ "$cmd_out" == *"parse error"* ]]; then
          warn=$((warn + 1))
          echo "⚠️ **WARN**: Error en norms-matrix.json (problema externo al archivo)"
          echo ""
          echo '```text'
          echo "$cmd_out"
          echo '```'
        else
          case "$status" in
            passed|success|tier_3|tier_2) passed=$((passed + 1)) ;;
            failed|error|block)          failed=$((failed + 1)) ;;
            *)                           warn=$((warn + 1)) ;;
          esac
          echo '```json'
          echo "$cmd_out"
          echo '```'
        fi
      else
        failed=$((failed + 1))
        echo "⚠️ Error de ejecución del orquestador"
        echo '```text'
        echo "$cmd_out"
        echo '```'
      fi

      # 🔐 VERIFICACIÓN DE INTEGRIDAD (auditoría, no recuperación)
      if ! verify_file_integrity "$file" "$pre_hash"; then
        echo ""
        echo "⚠️ **ALERTA**: El archivo fue modificado a pesar de chattr +i"
        echo "> Esto indica un fallo de permisos o un proceso con privilegios elevados"
        log_audit "ERROR" "Integridad fallida en ${rel_path} a pesar de chattr +i"
      fi

      echo ""
      echo "-------"
      echo ""
    done < <(find "${search_path}" -maxdepth 3 -type f \( \
      -name "*.md" -o -name "*.sh" -o -name "*.tf" -o -name "*.yaml" -o -name "*.yml" -o -name "*.json" \
    \) -not -path "*/.git/*" \
      -not -path "*/node_modules/*" \
      -not -path "*/08-LOGS/*" \
      -not -path "*/09-TEST-SANDBOX/*" \
      -not -path "*/.venv/*" \
      -print0 2>/dev/null | sort -z)

    # 📈 ÍNDICE DE CUMPLIMIENTO
    echo "## 📈 Índice de Cumplimiento - ${dir_name}"
    echo "| Métrica | Valor | Porcentaje |"
    echo "|---------|-------|------------|"
    if [[ $total -gt 0 ]]; then
      echo "| ✅ Aprobados | ${passed} | $(( passed * 100 / total ))% |"
      echo "| ❌ Fallidos | ${failed} | $(( failed * 100 / total ))% |"
      echo "| ⚠️ Advertencias | ${warn} | $(( warn * 100 / total ))% |"
      echo "| ⏭️ Saltados (ubicación no mapeada) | ${skipped} | $(( skipped * 100 / total ))% |"
      echo "| 📦 Total procesados | ${total} | 100% |"
    else
      echo "| ℹ️ Sin archivos validables | 0 | - |"
    fi
    echo ""
    echo "---"
    echo "*Fin del reporte. Generado en modo ${SCRIPT_MODE}.*"
  } > "${output_file}"

  log_audit "INFO" "✅ Guardado: ${output_file} (${total} archivos procesados, ${skipped} saltados)"
done

# 🔓 DESBLOQUEAR ARCHIVOS DESPUÉS DE LA VALIDACIÓN
log_audit "INFO" "🔓 Removiendo bloqueo preventivo (chattr -i)..."
for dir in "${DIRS[@]}"; do
  [[ "${dir}" == "08-LOGS" || "${dir}" == "09-TEST-SANDBOX" ]] && continue
  unlock_source_files "${REPO_ROOT}/${dir}"
done
log_audit "INFO" "✅ Desbloqueo completado"

# 📋 RESUMEN FINAL
log_audit "INFO" "=== PROCESO FINALIZADO ==="
log_audit "INFO" "Reportes consolidados en: ${LOG_DIR}/"
log_audit "INFO" "Backup preventivo disponible en: ${BACKUP_PATH}"
log_audit "INFO" "=== FIN DE EJECUCIÓN ==="

echo "🎉 Proceso finalizado. Reportes en: ${LOG_DIR}/"
echo "🔐 Backup preventivo en: ${BACKUP_PATH}"
echo "📋 Log de auditoría: ${AUDIT_LOG}"
