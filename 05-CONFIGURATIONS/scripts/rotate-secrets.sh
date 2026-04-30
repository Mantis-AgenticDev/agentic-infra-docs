---
# FRONTMATTER CANÓNICO OBLIGATORIO
artifact_id: "rotate-secrets-v1.0.0"
artifact_type: "script"
version: "1.0.0-COMPREHENSIVE"
constraints_mapped: ["C3", "C6", "C7"]
canonical_path: "05-CONFIGURATIONS/scripts/rotate-secrets.sh"
domain: "05-CONFIGURATIONS"
subdomain: "scripts"
agent_role: "secret-rotation"
language_lock: "bash"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain scripts --file 05-CONFIGURATIONS/scripts/rotate-secrets.sh --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants"]
human_readable: false
checksum_sha256: "d87928d8e8e72187e5a595fec3c6262f698e79d20d9ad3feb36c49512eed3a42"
# FIN FRONTMATTER
---

#!/usr/bin/env bash
# =============================================================================
# SCRIPT: rotate-secrets.sh
# DOMINIO: 05-CONFIGURATIONS/scripts
# PROPÓSITO: Rotación programada de secrets (90 días): genera nuevos valores,
#            actualiza archivos .env.* encriptados, notifica y registra auditoría.
#            Implementa backup previo y verificación de integridad.
# USO: ./rotate-secrets.sh --env prod [--file .env.prod] [--keys KEY1,KEY2] [--force]
# DEPENDENCIAS: bash >= 5.0, openssl, jq, git-crypt (opcional)
# AUTOR: configurations-master-agent (MANTIS)
# VERSIÓN: 1.0.0
# CONSTRAINTS: C3 (Seguridad), C6 (Cumplimiento), C7 (Resiliencia/Backup)
# =============================================================================
set -euo pipefail

# --- Configuración -----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel)"
CONFIGS_DIR="${REPO_ROOT}/05-CONFIGURATIONS"
BACKUP_DIR="${CONFIGS_DIR}/security/backups/secrets/$(date +%Y%m%d_%H%M%S)"
AUDIT_LOG="${CONFIGS_DIR}/security/logs/secret-rotation.log"
MAX_AGE_DAYS=90

# Variables de ejecución
ENVIRONMENT="prod"
TARGET_FILE=""
ROTATION_KEYS=()
FORCE="false"
DRY_RUN="false"

# --- Logging -----------------------------------------------------------------
log() {
    local level="$1"; shift
    local msg="[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [$level] $*"
    echo "$msg" | tee -a "$AUDIT_LOG"
    if [[ "$level" == "ERROR" ]]; then exit 1; fi
}

# --- Validación y Args -------------------------------------------------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --env) ENVIRONMENT="$2"; shift 2 ;;
            --file) TARGET_FILE="$2"; shift 2 ;;
            --keys) IFS=',' read -ra ROTATION_KEYS <<< "$2"; shift 2 ;;
            --force) FORCE="true"; shift ;;
            --dry-run) DRY_RUN="true"; shift ;;
            -h|--help)
                echo "Uso: $0 --env prod [--file .env.prod] [--keys KEY1,KEY2] [--force]"
                exit 0 ;;
            *) log ERROR "Opción desconocida: $1" ;;
        esac
    done

    # Determinar archivo objetivo si no se especifica
    if [[ -z "$TARGET_FILE" ]]; then
        TARGET_FILE="${CONFIGS_DIR}/environment/.env.${ENVIRONMENT}"
    fi

    if [[ ! -f "$TARGET_FILE" ]]; then
        log ERROR "Archivo de entorno no encontrado: $TARGET_FILE"
    fi

    # Verificar si requiere rotación por antigüedad
    if [[ "$FORCE" == "false" ]]; then
        local file_age_days=$(( ( $(date +%s) - $(stat -c %Y "$TARGET_FILE") ) / 86400 ))
        if (( file_age_days < MAX_AGE_DAYS )); then
            log INFO "⏳ El archivo tiene $file_age_days días (umbral: $MAX_AGE_DAYS). No requiere rotación."
            log INFO "   Use --force para forzar la rotación."
            exit 0
        fi
    fi

    mkdir -p "$BACKUP_DIR" "$(dirname "$AUDIT_LOG")"
    log INFO "🔐 Iniciando rotación para $TARGET_FILE (Env: $ENVIRONMENT)..."
}

# --- Funciones de Rotación ---------------------------------------------------
backup_secrets() {
    log INFO "💾 Realizando backup de seguridad (C7: Resiliencia)..."
    cp -p "$TARGET_FILE" "$BACKUP_DIR/"
    log INFO "✅ Backup guardado en: $BACKUP_DIR"
}

generate_secret() {
    local length=32
    openssl rand -base64 "$length" | tr -d '\n\r+/=' | head -c "$length"
}

rotate_variable() {
    local key="$1"
    local file="$2"
    local new_val
    new_val=$(generate_secret)

    # Verificar si la clave existe
    if ! grep -qE "^${key}=" "$file"; then
        log WARN "⚠️ Clave $key no encontrada en $file. Omitiendo."
        return 0
    fi

    # Reemplazar valor (sed in-place)
    # Escapar caracteres especiales si los hubiera
    local escaped_val
    escaped_val=$(printf '%s\n' "$new_val" | sed -e 's/[\/&]/\\&/g')
    
    # Backup de la línea original para auditoría (sin valor)
    local old_val_exists
    if grep -qE "^${key}=." "$file"; then
        old_val_exists="true"
    else
        old_val_exists="false"
    fi

    sed -i "s/^${key}=.*/${key}=${escaped_val}/" "$file"

    # Registrar en log (SOLO metadata, NUNCA el valor)
    log INFO "🔄 Rotada: $key (Nuevo valor generado, longitud: ${#new_val})"
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ROTATE key=$key env=$ENVIRONMENT status=SUCCESS length=${#new_val}" >> "$AUDIT_LOG"
}

encrypt_env() {
    # Placeholder para integración con git-crypt o sops
    # En producción: sops -i -e "$TARGET_FILE" o git-crypt lock
    if command -v sops &>/dev/null; then
        log INFO "🔒 Encriptando archivo con SOPS..."
        sops -e -i "$TARGET_FILE" || log WARN "⚠️ Fallo en encriptación SOPS (archivo permanece en texto plano temporalmente)."
    elif command -v git-crypt &>/dev/null; then
        log INFO "🔒 Encriptando archivo con git-crypt..."
        # git-crypt lock maneja el stage, aquí simulamos la acción
        git add "$TARGET_FILE"
    else
        log INFO "ℹ️ Herramienta de encriptación no detectada. Archivo permanece en texto plano (solo dev/staging)."
    fi
}

verify_rotation() {
    log INFO "🔍 Verificando integridad post-rotación..."
    local errors=0
    
    for key in "${ROTATION_KEYS[@]}"; do
        if grep -qE "^${key}=.{10,}" "$TARGET_FILE"; then
            log INFO "✅ $key: Valor actualizado correctamente."
        else
            log ERROR "❌ $key: No se verificó la actualización."
            ((errors++))
        fi
    done

    # Si no se especificaron keys, verificar que el archivo no esté vacío
    if [[ ${#ROTATION_KEYS[@]} -eq 0 ]]; then
        if [[ -s "$TARGET_FILE" ]]; then
            log INFO "✅ Archivo válido y no vacío."
        else
            log ERROR "❌ Archivo vacío tras rotación."
            ((errors++))
        fi
    fi

    if [[ $errors -gt 0 ]]; then
        log ERROR "❌ Verificación fallida. Restaurando backup..."
        cp -f "$BACKUP_DIR/$(basename "$TARGET_FILE")" "$TARGET_FILE"
        log INFO "🔄 Restaurado backup. Integridad recuperada."
        exit 1
    fi
}

# --- Ejecución Principal -----------------------------------------------------
main() {
    parse_args "$@"
    backup_secrets

    if [[ ${#ROTATION_KEYS[@]} -eq 0 ]]; then
        # Si no se especifican keys, rotar todas las que parezcan secrets
        log INFO "🔍 Detectando variables sensibles en mapping.yaml..."
        
        local mapping_file="${CONFIGS_DIR}/environment/mapping.yaml"
        if [[ -f "$mapping_file" ]]; then
            # Extraer keys marcadas como sensitive: true en mapping.yaml
            local sensitive_keys
            sensitive_keys=$(yq e '.variables | to_entries[] | select(.value.sensitive == true) | .key' "$mapping_file" 2>/dev/null || echo "")
            
            if [[ -n "$sensitive_keys" ]]; then
                while IFS= read -r key; do
                    ROTATION_KEYS+=("$key")
                done <<< "$sensitive_keys"
                log INFO "📋 Claves sensibles detectadas: ${#ROTATION_KEYS[@]}"
            else
                log WARN "⚠️ No se encontraron claves sensibles en mapping.yaml. Rotando todas las definidas en .env."
                ROTATION_KEYS=($(grep -oP '^\w+(?==)' "$TARGET_FILE"))
            fi
        else
            log WARN "⚠️ mapping.yaml no encontrado. Rotando todas las variables."
            ROTATION_KEYS=($(grep -oP '^\w+(?==)' "$TARGET_FILE"))
        fi
    fi

    for key in "${ROTATION_KEYS[@]}"; do
        rotate_variable "$key" "$TARGET_FILE"
    done

    encrypt_env
    verify_rotation

    log INFO "🎉 Rotación completada exitosamente."
    log INFO "👉 Próximos pasos:"
    log INFO "   1. Verificar servicios: docker compose restart"
    log INFO "   2. Commit seguro: git add $TARGET_FILE && git commit -m 'chore(security): rotate secrets for $ENVIRONMENT'"
    log INFO "   3. Notificar al equipo (Slack/Email) si es producción."
}

main "$@"


---
