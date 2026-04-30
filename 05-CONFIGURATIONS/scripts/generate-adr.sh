---
# FRONTMATTER CANÓNICO OBLIGATORIO
artifact_id: "generate-adr-v1.0.0"
artifact_type: "script"
version: "1.0.0-COMPREHENSIVE"
constraints_mapped: ["C4","C5"]
canonical_path: "05-CONFIGURATIONS/scripts/generate-adr.sh"
domain: "05-CONFIGURATIONS"
subdomain: "scripts"
agent_role: "adr-generator"
language_lock: "bash"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain scripts --file 05-CONFIGURATIONS/scripts/generate-adr.sh --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants"]
human_readable: true
checksum_sha256: "25feb85cfe066cbd2e5d6d1b23a9cfd7910eab967e9ae3f323cb8705ab45822f"
# FIN FRONTMATTER
---


#!/usr/bin/env bash
# =============================================================================
# SCRIPT: generate-adr.sh
# DOMINIO: 05-CONFIGURATIONS/scripts
# PROPÓSITO: Generador de Architecture Decision Records (ADRs) con plantilla
#            canónica, ID secuencial automático, validación estructural y
#            preparación para commit trazable (C4, C5).
# USO: ./generate-adr.sh --title "Adopt Terraform Stacks" --context "Motivo..." \
#            --decision "Decisión clara" --status Proposed [--constraints C1,C2]
# DEPENDENCIAS: bash >= 5.0, git, sed, date
# AUTOR: configurations-master-agent (MANTIS)
# VERSIÓN: 1.0.0
# CONSTRAINTS: C4 (Trazabilidad), C5 (Integridad Estructural)
# =============================================================================
set -euo pipefail

# --- Configuración -----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"
ADR_DIR="${REPO_ROOT}/docs/adr"
TEMPLATE_PATH="${REPO_ROOT}/05-CONFIGURATIONS/templates/runbook-template.md" # Fallback reference
LOG_FILE="/var/log/mantis-adr-gen.log"

# Variables de ejecución
TITLE=""
CONTEXT=""
DECISION=""
STATUS="Proposed"
CONSTRAINTS="C1,C4,C5,C8"
DRY_RUN="false"

# --- Logging -----------------------------------------------------------------
log() {
    local level="$1"; shift
    local msg="[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [$level] $*"
    echo "$msg" | tee -a "$LOG_FILE"
    [[ "$level" == "ERROR" ]] && exit 1
}

# --- Validación y Args -------------------------------------------------------
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --title) TITLE="$2"; shift 2 ;;
            --context) CONTEXT="$2"; shift 2 ;;
            --decision) DECISION="$2"; shift 2 ;;
            --status) STATUS="$2"; shift 2 ;;
            --constraints) CONSTRAINTS="$2"; shift 2 ;;
            --dry-run) DRY_RUN="true"; shift ;;
            -h|--help)
                echo "Uso: $0 --title \"<título>\" --context \"<contexto>\" --decision \"<decisión>\" [--status Proposed|Accepted|Deprecated]"
                exit 0 ;;
            *) log ERROR "Opción desconocida: $1" ;;
        esac
    done

    # Validaciones obligatorias (C5)
    [[ -z "$TITLE" || -z "$CONTEXT" || -z "$DECISION" ]] && \
        log ERROR "Faltan argumentos obligatorios: --title, --context, --decision"
    
    # Validar status
    case "$STATUS" in
        Proposed|Accepted|Deprecated|Superseded) ;;
        *) log ERROR "Status inválido. Use: Proposed, Accepted, Deprecated, Superseded" ;;
    esac

    mkdir -p "$ADR_DIR"
}

generate_slug() {
    echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g' | head -c 40
}

get_next_adr_id() {
    local max=0
    if compgen -G "${ADR_DIR}/ADR-*.md" > /dev/null; then
        max=$(ls "${ADR_DIR}/ADR-"*.md 2>/dev/null | sed -E 's/.*ADR-([0-9]+).*/\1/' | sort -n | tail -1)
    fi
    echo $((max + 1))
}

create_adr() {
    local adr_id="$1"
    local slug="$2"
    local filename="ADR-${adr_id}-${slug}.md"
    local filepath="${ADR_DIR}/${filename}"
    local date_utc
    date_utc=$(date -u +%Y-%m-%d)

    if [[ -f "$filepath" ]]; then
        log ERROR "ADR ya existe: $filepath. Elimine o renombre antes de reintentar."
    fi

    # Generar contenido canónico
    cat > "$filepath" <<EOF
---
artifact_id: "adr-${adr_id}"
artifact_type: "architecture_decision_record"
version: "1.0.0"
canonical_path: "docs/adr/${filename}"
domain: "docs"
subdomain: "adr"
adr_status: "${STATUS}"
date: "${date_utc}"
author: "$(git config user.name 2>/dev/null || echo 'unknown')"
constraints_mapped: [${CONSTRAINTS}]
checksum_sha256: "25feb85cfe066cbd2e5d6d1b23a9cfd7910eab967e9ae3f323cb8705ab45822f"
---

# ADR-${adr_id}: ${TITLE}

**Estado:** ${STATUS}  
**Fecha:** ${date_utc}  
**Decisor:** $(git config user.name 2>/dev/null || echo 'Agente MANTIS')  
**Stakeholders afectados:** [Lista de agentes/equipos]

## Contexto
${CONTEXT}

## Decisión
${DECISION}

## Consecuencias
### Positivas
- [Ventaja 1 derivada de la decisión]
- [Mejora en trazabilidad/compliance/performance]

### Negativas / Trade-offs aceptados
- [Costo de implementación o complejidad añadida]
- [Limitación temporal o dependencia externa]

## Alternativas consideradas
| Alternativa | Pros | Contras | Razón de descarte |
|-------------|------|---------|-------------------|
| [Nombre] | [Ventaja] | [Desventaja] [Razón principal] |
| [Nombre] | [Ventaja] | [Desventaja] [Razón principal] |

## Implementación
- [ ] Tarea 1: [Descripción] (Responsable: [nombre/agente])
- [ ] Tarea 2: [Descripción] (Responsable: [nombre/agente])
- [ ] Actualizar documentación afectada (runbooks, interface-spec, pipelines)

## Revisión
Próxima revisión programada: $(date -u -d "+6 months" +%Y-%m-%d 2>/dev/null || date -u -v+6m +%Y-%m-%d 2>/dev/null || echo "2027-01-01")  
Criterios de re-evaluación: [Condiciones que dispararían revisión o cambio de status]

---
*Generado por generate-adr.sh v1.0.0 | Constraints: ${CONSTRAINTS} | MANTIS AgenticDev*
EOF

    echo "$filepath"
}

validate_adr_structure() {
    local file="$1"
    local missing=0
    for section in "Contexto" "Decisión" "Consecuencias" "Alternativas consideradas" "Implementación"; do
        if ! grep -q "^## ${section}$" "$file"; then
            log WARN "⚠️ Sección faltante en ADR: $section"
            ((missing++))
        fi
    done
    
    if ! grep -q "^artifact_id:" "$file" || ! grep -q "^checksum_sha256:" "$file"; then
        log ERROR "❌ Frontmatter canónico inválido o incompleto (C5)"
    fi
    
    [[ $missing -gt 0 ]] && log WARN "⚠️ ADR generado con $missing secciones vacías. Completar antes de merge." || true
}

# --- Ejecución Principal -----------------------------------------------------
main() {
    parse_args "$@"
    
    local adr_id slug filepath
    adr_id=$(get_next_adr_id)
    slug=$(generate_slug)
    
    log INFO "📝 Generando ADR-${adr_id}: ${TITLE}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        filepath=$(mktemp /tmp/adr-dry-run.XXXXXX.md)
        log INFO "[DRY-RUN] Generado temporalmente en: $filepath"
    else
        filepath=$(create_adr "$adr_id" "$slug")
    fi
    
    validate_adr_structure "$filepath"
    
    log INFO "✅ ADR generado exitosamente: $filepath"
    log INFO "👉 Próximos pasos:"
    log INFO "   1. Revisar contenido: cat $filepath"
    log INFO "   2. Completar secciones entre corchetes [ ]"
    log INFO "   3. Commit: git add $filepath && git commit -m 'docs: add ADR-${adr_id} ${TITLE}'"
    log INFO "   4. Actualizar índice: bash 05-CONFIGURATIONS/scripts/update-adr-index.sh (si existe)"
}

main "$@"


---
