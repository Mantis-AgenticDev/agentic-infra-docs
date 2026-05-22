#!/bin/bash
# ---
# artifact_id: "goals-rotate-agent-db-sh"
# artifact_type: "operations_script"
# version: "1.0.0"
# constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9"]
# validation_command: "bash goals/scripts/rotate-agent-db.sh --dry-run"
# canonical_path: "goals/scripts/rotate-agent-db.sh"
# tier: 2
# immutable: false
# requires_human_approval_for_changes: false
# audience: ["orchestrator-engine", "sysadmin"]
# human_readable: false
# language_lock: "bash"
# prompt_hash: "sha256:rotate-agent-db-v1.0.0"
# generated_at: "2026-05-22T03:20:00Z"
# tenant_context: "nao_aplicavel"
# language: "bash"
# domain: "goals"
# subdomain: "scripts"
# agent_role: "orchestrator-engine"
# agent_specialty: "housekeeping"
# status: "✅ Estável"
# next_review: "2026-06-22"
# license: "CC-BY-NC-SA-4.0"
# ---
# Rota bases SQLite antiguas de agentes, manteniendo las últimas N.

set -euo pipefail

DB_DIR="${MANTIS_HOME:-$HOME/.mantis}/agent-db"
MAX_KEEP=5
DRY_RUN=false

usage() {
  echo "Uso: $0 [--dry-run] [--max-keep N] [--db-dir DIR]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --max-keep) MAX_KEEP="$2"; shift ;;
    --db-dir) DB_DIR="$2"; shift ;;
    *) usage ;;
  esac
  shift
done

if [ ! -d "$DB_DIR" ]; then
  echo "INFO: directorio $DB_DIR no existe, nada que rotar"
  exit 0
fi

# Agrupar por nombre base (ej. bash-master-agent)
find "$DB_DIR" -name "*.db" -print0 | while IFS= read -r -d '' file; do
  base=$(basename "$file" .db)
  # Extraer prefijo y timestamp (asumimos formato: agent-YYYYMMDDHHMMSS.db)
  if [[ "$base" =~ ^(.+)-([0-9]{14})$ ]]; then
    prefix="${BASH_REMATCH[1]}"
    ts="${BASH_REMATCH[2]}"
  else
    prefix="$base"
    ts="00000000000000"
  fi
  # Lista de archivos de este prefix ordenados por timestamp descendente
  mapfile -t files < <(find "$DB_DIR" -name "${prefix}-*.db" -print0 2>/dev/null | xargs -0 ls -1t 2>/dev/null || true)
  count="${#files[@]}"
  if [ "$count" -gt "$MAX_KEEP" ]; then
    for (( i=MAX_KEEP; i<count; i++ )); do
      oldfile="${files[$i]}"
      if [ "$DRY_RUN" = true ]; then
        echo "[DRY-RUN] eliminaría: $oldfile"
      else
        echo "eliminando base antigua: $oldfile"
        rm -f "$oldfile"
      fi
    done
  fi
done

echo "Rotación completada."
