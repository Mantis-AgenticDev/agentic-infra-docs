#!/bin/bash
#===============================================================================
# SYNC MAIN → SANDBOX-TESTING (Filesystem Only, No Git)
# Propósito: Sincronizar main al sandbox de forma rápida, segura y sin git
#===============================================================================
set -euo pipefail

MAIN_DIR="/home/ricardo/proyectos/agentic-infra-docs"
SANDBOX_DIR="/home/ricardo/proyectos/agentic-infra-docs-testing"
LOG_FILE="${SANDBOX_DIR}/08-LOGS/sync-events.log"
TIMESTAMP=$(date -Iseconds)

mkdir -p "${SANDBOX_DIR}/08-LOGS"

echo "[${TIMESTAMP}] === SYNC START ===" >> "$LOG_FILE"

# 1. Validar que main exista y esté accesible
if [[ ! -d "$MAIN_DIR" || ! -r "$MAIN_DIR" ]]; then
    echo "[ERROR] Directorio main no encontrado o sin permisos: $MAIN_DIR" >> "$LOG_FILE"
    exit 1
fi

# 2. Sync con rsync (borra archivos obsoletos en sandbox, mantiene exclusión)
if rsync -a --delete \
         --exclude='.git' \
         --exclude='08-LOGS/' \
         --exclude='*.bak' \
         --exclude='08-DOSSIERS/' \
         "$MAIN_DIR/" "$SANDBOX_DIR/"; then
    echo "[OK] Sync completado exitosamente." >> "$LOG_FILE"
else
    echo "[FAIL] Error durante rsync. Revisar permisos o espacio en disco." >> "$LOG_FILE"
    exit 2
fi

# 3. Validación ligera post-sync (opcional pero recomendada)
if [[ -f "${SANDBOX_DIR}/05-CONFIGURATIONS/validation/orchestrator-engine.sh" ]]; then
    echo "[INFO] Ejecutando validación post-sync en sandbox..." >> "$LOG_FILE"
    bash "${SANDBOX_DIR}/05-CONFIGURATIONS/validation/orchestrator-engine.sh" \
         --mode headless --dir "$SANDBOX_DIR" --json > /dev/null 2>&1 && \
        echo "[OK] Sandbox validado. Listo para pruebas." >> "$LOG_FILE" || \
        echo "[WARN] Validación reporta advertencias. Revisar manualmente." >> "$LOG_FILE"
fi

echo "[${TIMESTAMP}] === SYNC END ===" >> "$LOG_FILE"
echo "[INFO] Logs: $LOG_FILE"
