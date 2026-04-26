# 📋 POST-MORTEM: `check-wikilinks.sh` v1.3

> **Fecha de análisis**: 2026-04-25  
> **Referencia contractual**: `VALIDATOR_DEV_NORMS.md` + `norms-matrix.json` + `harness-norms-v3.0.md`  
> **Estado**: ❌ **NO COMPLIANT** – Requiere remanufactura estructural

---

## 🔴 DESVIACIONES CRÍTICAS (Bloqueantes para CI/CD)

| Norma | Requisito Contractual | Estado Actual del Script | Impacto |
|-------|---------------------|-------------------------|---------|
| **V-INT-01** | JSON mínimo en `stdout`: `{validator, version, timestamp, file, constraint, passed, issues[], issues_count}` | Escribe un archivo `wikilinks-validation-report.json` con schema propio | ❌ No se adhiere al pipeline std de I/O de los validadores |
| **V-INT-03** | `stdout` = **solo JSON**; `stderr` = logs humanos | Manda un reporte estilizado ("🔗 VALIDACIÓN...") por `stdout` | ❌ Destruye la posibilidad de capturar el output en scripts orquestadores |
| **V-LOG-01/02** | Logs JSONL en `08-LOGS/validation/...` | No utiliza el sistema de JSONL ni emite métricas `performance_ms` | ❌ Falla en proveer data al dashboard estático temporal |
| **V-INT-04** | `<3000ms/artifact` | No mide su propio tiempo de ejecución | ⚠️ Escaneo de toda la DB sin límite ni control |

---

## 🟡 DESVIACIONES FUNCIONALES (Scope creep)

- **Comportamiento por lote vs archivo**: El script actual escanea directorios completos y emite un reporte global, cuando el estándar de MANTIS AGENTIC asume validadores que examinan por `--file` para encajar en `orchestrator-engine.sh`.
- **Creación de temporales**: Manipula `/tmp` y copia archivos internamente sin adherirse al sistema `trap` de limpieza estándar.

---

## 🛠️ PLAN DE REMANUFACTURA (v3.0+ CONTRACTUAL)

1. Convertir la entrada principal de un escáner de directorio a un evaluador focalizado por fichero (recibe `--file`).
2. Remover la creación de `wikilinks-validation-report.json`. El output se emitirá directamente a `stdout` siguiendo el Schema JSON canónico.
3. Desviar los print legibles (errores de links, estado de escaneo) hacia `stderr`.
4. Calcular `START_MS` y `END_MS` generando un log en formato JSONL y registrándolo en `08-LOGS/validation/test-orchestrator-engine/check-wikilinks/`.
