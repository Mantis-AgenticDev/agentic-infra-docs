# 📋 POST-MORTEM: `validate-skill-integrity.sh` v3.0.0-SELECTIVE

> **Fecha de análisis**: 2026-04-25  
> **Referencia contractual**: `VALIDATOR_DEV_NORMS.md` + `norms-matrix.json` + `harness-norms-v3.0.md`  
> **Estado**: ❌ **NO COMPLIANT** – Requiere remanufactura estructural

---

## 🔴 DESVIACIONES CRÍTICAS (Bloqueantes para CI/CD)

| Norma | Requisito Contractual | Estado Actual del Script | Impacto |
|-------|---------------------|-------------------------|---------|
| **V-INT-01** | JSON mínimo en `stdout`: `{validator, version, timestamp, file, constraint, passed, issues[], issues_count}` | Output JSON no estándar con conteo de links, constraints_covered, etc. | ❌ Rompe ingestión del dashboard estático |
| **V-INT-03** | `stdout` = **solo JSON**; `stderr` = logs humanos | Si `--json=false`, contamina `stdout` con texto plano | ❌ Imposible encadenar en pipes con `jq` |
| **V-LOG-01** | Logs JSONL en `08-LOGS/validation/...` | No escribe logs persistentes, omite trazabilidad | ❌ Incumple auditoría forense obligatoria |
| **V-INT-04** | `<3000ms/artifact`, `elapsed_ms` en output | Carece de temporizador de rendimiento interno | ⚠️ Imposible auditar límites de CI/CD |

---

## 🟡 DESVIACIONES FUNCIONALES (Scope creep)

- **Altamente Redundante**: Posee exactamente el mismo código base que `validate-frontmatter.sh` para la carga, verificación de vectores, scoring (0-100), conteo de ejemplos, etc.
- **Validación de Wikilinks embebida**: Intenta verificar links rotos, solapando su responsabilidad con `check-wikilinks.sh`.

---

## 🛠️ PLAN DE REMANUFACTURA (v3.0+ CONTRACTUAL)

1. Reducir la lógica a **SÓLO** la validación de integridad estructural propia de las Skills (ej. presencia de descripciones, coherencia del frontmatter respecto a requisitos específicos del skill_type).
2. Quitar todo rastreo de `SCORE`, `V1-V3` vector checks y chequeo de `wikilinks`.
3. Estandarizar la salida a `stdout` generando un dict JSON mínimo.
4. Mover todas las alertas legibles a `stderr`.
5. Activar el logger JSONL apuntando a `08-LOGS/validation/test-orchestrator-engine/validate-skill-integrity/`.
