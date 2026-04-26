# 📋 POST-MORTEM: `audit-secrets.sh` v3.0.0

> **Fecha de análisis**: 2026-04-25  
> **Referencia contractual**: `VALIDATOR_DEV_NORMS.md` + `norms-matrix.json` + `harness-norms-v3.0.md`  
> **Estado**: ⚠️ **PARCIALMENTE COMPLIANT** – Requiere ajustes para alineación total

---

## 🔴 DESVIACIONES (Bloqueantes para CI/CD y Dashboard)

| Norma | Requisito Contractual | Estado Actual del Script | Impacto |
|-------|---------------------|-------------------------|---------|
| **V-LOG-01** | Logs JSONL apilables diarios (ej: `2026-04-25.jsonl`) | Genera un archivo `.jsonl` nuevo por cada milisegundo de ejecución (`$(date +%Y-%m-%d_%H%M%S).jsonl`) | ❌ Fragmentación masiva de logs; rompe la ingesta del Dashboard. |
| **V-INT-01/04** | Schema JSON canónico en `stdout` incluyendo `performance_ms` | El output individual en `emit_json` no incluye el campo `performance_ms`. | ❌ El orchestrator y el Dashboard no tendrán métricas de este validador. |

---

## 🟡 DESVIACIONES FUNCIONALES (Scope creep)

- **Modo Batch Redundante**: Posee una función `process_batch` muy compleja que hace escaneos de directorio. Dado que el orquestador (`orchestrator-engine.sh`) se encarga de paralelizar/enrutar archivos a los validadores mediante llamadas `--file`, el modo batch interno del script añade sobrecarga innecesaria y confunde el output `stdout` final.

---

## 🛠️ PLAN DE REMANUFACTURA (v3.1-CONTRACTUAL)

1. **Estandarizar Logging**: Cambiar la ruta del archivo de log a `08-LOGS/validation/test-orchestrator-engine/audit-secrets/$(date -u +%Y-%m-%d).jsonl` para consolidar toda la data diaria.
2. **Eliminar Modo Batch**: Reducir la herramienta para que procese un único fichero por invocación (`--file`), retornando siempre un objeto JSON por `stdout`.
3. **Métricas en JSON**: Inyectar `performance_ms` en el payload JSON usando el cálculo de `START_MS` y `END_MS`.
