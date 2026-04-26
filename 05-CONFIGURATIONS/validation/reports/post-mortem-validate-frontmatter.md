# 📋 POST-MORTEM: `validate-frontmatter.sh` v3.0.0-SELECTIVE

> **Fecha de análisis**: 2026-04-25  
> **Referencia contractual**: `VALIDATOR_DEV_NORMS.md` + `norms-matrix.json` + `harness-norms-v3.0.md`  
> **Estado**: ❌ **NO COMPLIANT** – Requiere remanufactura estructural

---

## 🔴 DESVIACIONES CRÍTICAS (Bloqueantes para CI/CD)

| Norma | Requisito Contractual | Estado Actual del Script | Impacto |
|-------|---------------------|-------------------------|---------|
| **V-INT-01** | JSON mínimo en `stdout`: `{validator, version, timestamp, file, constraint, passed, issues[], issues_count}` | Output JSON excesivo (`"errors"`, `"warnings"`, `"constraints_covered"`, etc.) | ❌ Rompe ingestión del dashboard estático |
| **V-INT-03** | `stdout` = **solo JSON**; `stderr` = logs humanos | Si `--json` no está presente, emite texto plano a `stdout` | ❌ Contamina canal de datos para orchestrator |
| **V-LOG-01** | Logs JSONL en `08-LOGS/validation/...` | No escribe archivos JSONL; solo logs efímeros a `stderr` | ❌ Sin trazabilidad forense ni auditoría |
| **V-LOG-02** | Schema JSONL canónico con `performance_ms`, `performance_ok` | No registra métricas de performance | ❌ Imposible auditar cumplimiento de V-INT-04 |
| **V-INT-04** | `<3000ms/artifact`, streaming, `elapsed_ms` obligatorio | Sin medición de tiempo | ⚠️ Riesgo de timeout en CI runner básico |

---

## 🟡 DESVIACIONES FUNCIONALES (Scope creep)

- **Cálculo de SCORE obsoleto**: Al igual que `verify-constraints.sh`, realiza un conteo complejo de puntajes (0-100) y de `examples_count`, excediendo el requerimiento binario estricto de Valid/Invalid dictado en el Zero-Trust Gate.
- **Redundancia**: Verifica si el documento respeta LANGUAGE LOCK (V1-V3 vector ops), lo cual ya fue delegado a `verify-constraints.sh`.

---

## 🛠️ PLAN DE REMANUFACTURA (v3.0+ CONTRACTUAL)

1. Eliminar sistema de puntuación (`SCORE`) y de validación de vectores (LANGUAGE LOCK y `V*`), dejando este script dedicado **ESTRICTAMENTE** a comprobar la integridad estructural YAML (campos obligatorios).
2. Forzar que `stdout` genere el JSON estricto mínimo, utilizando `jq -n`.
3. Enviar todo texto humano a `stderr`.
4. Capturar `START_MS` y `END_MS` para inyectarlo en `performance_ms`.
5. Apendar el resultado en formato JSONL en `08-LOGS/validation/test-orchestrator-engine/validate-frontmatter/`.
