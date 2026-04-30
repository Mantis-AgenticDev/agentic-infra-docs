---
# FRONTMATTER CANÓNICO OBLIGATORIO
artifact_id: "onboard-tenant-v1.0.0"
artifact_type: "script"
version: "1.0.0-COMPREHENSIVE"
constraints_mapped: ["C1", "C3", "C4", "C5", "C7", "V1"]
canonical_path: "05-CONFIGURATIONS/scripts/onboard-tenant.sh"
domain: "05-CONFIGURATIONS"
subdomain: "scripts"
agent_role: "tenant-onboarding"
language_lock: "bash"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain scripts --file 05-CONFIGURATIONS/scripts/onboard-tenant.sh --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants"]
human_readable: false
checksum_sha256: "a3e0039c43c80453248c6f6ce2ff5ff78c87ddf5d40285690a7e3a82d92494dd"
# FIN FRONTMATTER
---
```

```bash
#!/usr/bin/env bash
# =============================================================================
# SCRIPT: onboard-tenant.sh
# DOMINIO: 05-CONFIGURATIONS/scripts
# PROPÓSITO: Alta determinista de cliente: Crea esquema DB con RLS, registra 
#            en canonical_registry.json, inicializa directorio de skills.
#            Idempotente y con capacidad de rollback ante fallos críticos.
# USO: ./onboard-tenant.sh --tenant-id <tenant_id> [--env dev|staging|prod]
# DEPENDENCIAS: psql, jq, git, bash >= 5.0
# AUTOR: configurations-master-agent (MANTIS)
# VERSIÓN: 1.0.0
# CONSTRAINTS: C1 (Idempotencia), C3 (Seguridad), C4 (Trazabilidad), V1 (RLS)
# =============================================================================
set -euo pipefail

# --- Configuración -----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel)"
CONFIGS_DIR="${REPO_ROOT}/05-CONFIGURATIONS"
SKILLS_DIR="${REPO_ROOT}/02-SKILLS"
REGISTRY="${REPO_ROOT}/canonical_registry.json"

# Flags de control
ROLLBACK_TRIGGERED="false"
TENANT_ID=""
ENVIRONMENT="dev"
DB_URL=""

# --- Logging -----------------------------------------------------------------
log_info() { echo "[INFO]  $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_warn() { echo "[WARN]  $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }

# --- Cleanup / Rollback ------------------------------------------------------
cleanup() {
    # Si falló en fase crítica de DB y se creó el esquema, intentar eliminarlo
    if [ "${ROLLBACK_TRIGGERED}" = "true" ] && [ -n "${TENANT_SCHEMA:-}" ]; then
        log_warn "🔄 Ejecutando rollback por error crítico en base de datos..."
        if command -v psql &> /dev/null && [ -n "${DB_URL:-}" ]; then
            psql "$DB_URL" -c "DROP SCHEMA IF EXISTS ${TENANT_SCHEMA} CASCADE;" 2>/dev/null || true
            log_info "🗑️ Schema ${TENANT_SCHEMA} eliminado para mantener consistencia."
        else
            log_error "❌ No se pudo conectar a DB para rollback manual. Revisar logs."
        fi
    fi
}
trap cleanup EXIT

# --- Funciones de Validación -------------------------------------------------
validate_inputs() {
    if [[ -z "${TENANT_ID}" ]]; then
        log_error "❌ Faltan argumentos. Uso: $0 --tenant-id <id> [--env dev|staging|prod]"
        exit 1
    fi
    
    # Validar formato de Tenant ID (V1, C5: Estructura estricta)
    if ! [[ "$TENANT_ID" =~ ^[a-z0-9-]{3,32}$ ]]; then
        log_error "❌ Formato inválido para tenant_id. Debe ser [a-z0-9-]{3,32}."
        exit 1
    fi
    
    # Verificar idempotencia (C1)
    if [ -d "${SKILLS_DIR}/${TENANT_ID}" ]; then
        log_warn "⚠️ El directorio de skills ya existe: ${SKILLS_DIR}/${TENANT_ID}"
        read -p "¿Continuar y solo aplicar cambios DB/Registry? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_info "🚫 Abortado por usuario."
            exit 0
        fi
    fi
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --tenant-id)
                TENANT_ID="$2"; shift 2 ;;
            --env)
                ENVIRONMENT="$2"; shift 2 ;;
            --db-url)
                DB_URL="$2"; shift 2 ;;
            -h|--help)
                echo "Uso: $0 --tenant-id <id> [--env <env>] [--db-url <url>]"; exit 0 ;;
            *)
                log_error "Opción desconocida: $1"; exit 1 ;;
        esac
    done
    
    TENANT_SCHEMA="tenant_${TENANT_ID}"
}

load_env() {
    # Cargar variables de entorno si existen (C3: Secrets nunca hardcodeados)
    local env_file="${CONFIGS_DIR}/environment/.env.${ENVIRONMENT}"
    if [[ -f "$env_file" ]]; then
        set -a
        # shellcheck source=/dev/null
        source "$env_file"
        set +a
        log_info "✅ Entorno cargado: $ENVIRONMENT"
    fi
    
    # Validar que DB_URL esté presente (C3)
    if [[ -z "${DB_URL}" ]]; then
        log_error "❌ DATABASE_URL no definida en .env.${ENVIRONMENT} ni pasada por argumento."
        log_error "   Solución: source ${env_file} o export DATABASE_URL=..."
        exit 1
    fi
    
    # Validar conexión previa
    if ! psql "$DB_URL" -c "SELECT 1" >/dev/null 2>&1; then
        log_error "❌ No se pudo conectar a la base de datos. Verificar credenciales y red."
        exit 1
    fi
}

# --- Lógica de Base de Datos -------------------------------------------------
setup_database() {
    log_info "🔧 Configurando base de datos para tenant: $TENANT_ID..."
    ROLLBACK_TRIGGERED="true"  # Activa flag de limpieza si hay error aquí
    
    # 1. Crear esquema dedicado (V1: Aislamiento lógico)
    log_info "📦 Creando esquema: $TENANT_SCHEMA"
    psql "$DB_URL" <<EOF
CREATE SCHEMA IF NOT EXISTS $TENANT_SCHEMA;

-- Asignar permisos al usuario de la aplicación
-- Nota: Se asume que el rol 'app_user' es gestionado por Terraform.
GRANT USAGE ON SCHEMA $TENANT_SCHEMA TO app_user;
GRANT ALL ON ALL TABLES IN SCHEMA $TENANT_SCHEMA TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA $TENANT_SCHEMA GRANT ALL ON TABLES TO app_user;
EOF

    # 2. Aplicar políticas RLS en tablas compartidas (V1: Row Level Security)
    # Estas políticas filtran datos basándose en la variable de sesión app.tenant_id
    log_info "🔒 Aplicando políticas RLS en tablas globales..."
    
    psql "$DB_URL" <<EOF
-- Ejemplo para tabla 'documents' en schema público
-- La tabla debe tener columna tenant_id definida previamente

-- Habilitar RLS si no está activo
ALTER TABLE IF EXISTS public.documents ENABLE ROW LEVEL SECURITY;

-- Política SELECT: Solo ver datos del propio tenant
CREATE POLICY IF NOT EXISTS tenant_select_documents 
    ON public.documents 
    FOR SELECT 
    USING (tenant_id = current_setting('app.tenant_id'));

-- Política INSERT: Solo insertar con el tenant_id correcto
CREATE POLICY IF NOT EXISTS tenant_insert_documents 
    ON public.documents 
    FOR INSERT 
    WITH CHECK (tenant_id = current_setting('app.tenant_id'));

-- Política UPDATE: Solo modificar datos del propio tenant
CREATE POLICY IF NOT EXISTS tenant_update_documents 
    ON public.documents 
    FOR UPDATE 
    USING (tenant_id = current_setting('app.tenant_id'));

-- Política DELETE: Solo eliminar datos del propio tenant
CREATE POLICY IF NOT EXISTS tenant_delete_documents 
    ON public.documents 
    FOR DELETE 
    USING (tenant_id = current_setting('app.tenant_id'));
EOF
    
    ROLLBACK_TRIGGERED="false"  # Fase crítica superada
    log_info "✅ Configuración de DB y RLS completada."
}

# --- Registro y Estructura de Archivos ---------------------------------------
update_registry() {
    log_info "📝 Actualizando canonical_registry.json..."
    
    if [[ ! -f "$REGISTRY" ]]; then
        log_error "❌ No se encontró $REGISTRY. Asegúrate de ejecutar desde la raíz del repo."
        exit 1
    fi
    
    local TIMESTAMP
    TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    # Inyectar metadata del tenant en la estructura del registry
    # Se asume que canonical_registry.json tiene soporte para sección 'tenants' o 'metadata'
    jq --arg tid "$TENANT_ID" \
       --arg ts "$TIMESTAMP" \
       --arg env "$ENVIRONMENT" \
       '.tenants[$tid] = { 
           id: $tid, 
           status: "active", 
           created_at: $ts, 
           environment: $env,
           schema: "tenant_\($tid)"
         }' \
       "$REGISTRY" > "${REGISTRY}.tmp" && mv "${REGISTRY}.tmp" "$REGISTRY"
       
    log_info "✅ Registry actualizado."
}

init_skill_directory() {
    log_info "🌱 Inicializando directorio de skills para tenant..."
    
    local tenant_skill_dir="${SKILLS_DIR}/${TENANT_ID}"
    
    if [[ ! -d "$tenant_skill_dir" ]]; then
        mkdir -p "$tenant_skill_dir"
        log_info "📁 Creado: $tenant_skill_dir"
        
        # Generar 00-INDEX.md canónico
        cat > "${tenant_skill_dir}/00-INDEX.md" <<EOF
---
artifact_id: "index-${TENANT_ID}"
artifact_type: "directory_index"
version: "1.0.0"
canonical_path: "02-SKILLS/${TENANT_ID}/00-INDEX.md"
tenant_id: "${TENANT_ID}"
environment: "${ENVIRONMENT}"
---

# Índice de Skills: ${TENANT_ID}

Directorio de habilidades específicas y configuraciones personalizadas para el tenant **${TENANT_ID}**.

## Arquitectura de Datos
- **Schema DB**: \`tenant_${TENANT_ID}\`
- **Aislamiento**: RLS habilitado (V1)
- **Environment**: \`$ENVIRONMENT\`

## Estructura de Archivos
\`\`\`
${TENANT_ID}/
├── 00-INDEX.md       # Este archivo (punto de entrada)
├── skills/           # Skills personalizados por vertical
└── config/           # Overrides de configuración específicos
\`\`\`

## Protocolo de Operación
1. **Creación de Skill**: Copiar \`skill-template.md\` a \`skills/nueva-skill.md\`.
2. **Validación**: Ejecutar \`orchestrator-engine.sh --skill ${TENANT_ID}/skills/nueva-skill.md\`.
3. **Despliegue**: Commit con mensaje trazable y push a \`main\`.

## Seguridad
- **NO** incluir credenciales ni secrets en este directorio.
- **TODO** acceso a datos debe respetar política \`tenant_isolation\`.
EOF
        log_info "✅ 00-INDEX.md generado."
    else
        log_info "ℹ️ Directorio existente, omitiendo creación (Idempotencia)."
    fi
}

# --- Ejecución Principal -----------------------------------------------------
main() {
    parse_args "$@"
    validate_inputs
    load_env
    
    # Secuencia de operaciones
    setup_database
    update_registry
    init_skill_directory
    
    log_info "🚀 Onboarding finalizado exitosamente para tenant: $TENANT_ID"
    log_info "👉 Próximos pasos recomendados:"
    log_info "   1. Validar aislamiento: psql \$DB_URL -c \"SET app.tenant_id='$TENANT_ID'; SELECT count(*) FROM public.documents;\""
    log_info "   2. Generar secrets específicos: bash ${CONFIGS_DIR}/scripts/rotate-secrets.sh --tenant $TENANT_ID"
    log_info "   3. Registrar cambios: git add 02-SKILLS/$TENANT_ID canonical_registry.json"
    log_info "   4. Ejecutar validación cruzada: orchestrator-engine.sh --domain all --strict"
}

main "$@"


---
