# 📋 POST-MORTEM: `check-rls.sh` v3.2.5

> **Fecha de análisis**: 2026-04-25  
> **Referencia contractual**: `VALIDATOR_DEV_NORMS.md` + `norms-matrix.json` + `harness-norms-v3.0.md`  
> **Estado**: ⚠️ **PARCIALMENTE COMPLIANT** – Requiere ajustes para alineación total

---

## 🔴 DESVIACIONES (Bloqueantes para CI/CD y Dashboard)

| Norma | Requisito Contractual | Estado Actual del Script | Impacto |
|-------|---------------------|-------------------------|---------|
| **V-LOG-01** | Logs JSONL apilables diarios (ej: `2026-04-25.jsonl`) | Al igual que `audit-secrets`, genera un archivo `.jsonl` único por cada ejecución con precisión de segundos (`$(date +%Y-%m-%d_%H%M%S).jsonl`). | ❌ Saturación de inodos; imposible de ingestar de forma eficiente en el Dashboard. |

---

## 🟡 DESVIACIONES FUNCIONALES (Scope creep)

- **Modo Batch Redundante**: Implementa su propia lógica recursiva con `find ... -print0`, imprimiendo barras de progreso a `stderr`. Es redundante puesto que `orchestrator-engine.sh` asume el rol del escaneo masivo por lotes.
- **Doble impresión a stdout**: En el modo file actual, hace:
  ```bash
  echo "$result"
  echo "$result" >> "$LOG_FILE"
  ```
  Esto es correcto para I/O, pero el modo batch altera las firmas de salida.

---

## 🛠️ PLAN DE REMANUFACTURA (v3.3-CONTRACTUAL)

1. **Estandarizar Logging**: Fijar el log en `08-LOGS/validation/test-orchestrator-engine/check-rls/$(date -u +%Y-%m-%d).jsonl`.
2. **Atomicidad**: Remover el modo `--dir` y los progresos interactivos, convirtiéndolo puramente en una herramienta atómica CLI `--file`.
3. **Optimización I/O**: Garantizar que devuelva estrictamente su JSON con `performance_ms` y `performance_ok`.
