# 📋 POST-MORTEM: `orchestrator-engine.sh` (Legacy v3.0)

> **Fecha de análisis**: 2026-04-25  
> **Referencia contractual**: PROMPT MAESTRO v4.0 (DASHBOARD & METRICS)  
> **Estado**: ❌ **OBSOLETO / NO COMPLIANT** – Requiere reescritura total desde cero (v4.0)

---

## 🔴 DESVIACIONES CRÍTICAS (Bloqueantes para CI/CD)

| Norma / Concepto | Estado Actual del Script | Impacto |
|------------------|-------------------------|---------|
| **Identidad Arquitectónica** | Actúa como un validador monolítico gigante (implementa reglas C1-C8, escanea regex, calcula un `SCORE` de 0 a 100). | ❌ Vioca el principio de responsabilidad única. Duplica el trabajo que ya realizan los 6 validadores del toolchain. No orquesta nada. |
| **Paralelismo y Escala** | Diseñado para recibir `--file <path>` y operar sincrónicamente un solo archivo a la vez. No soporta escaneo masivo. | ❌ Imposible procesar 1000 artefactos sin un cuello de botella extremo. Falta de `xargs -P` o `GNU parallel`. |
| **Generación de Dashboard** | Inexistente. Solo emite un JSON a `stdout` con su propio puntaje. | ❌ Falla el requerimiento core de generar métricas globales y la UI estática (`index.html`). |
| **Integridad SHA256** | Solo verifica que el encabezado del archivo contenga un SHA256. No computa el hash real en tiempo de ejecución para asegurar la inmutabilidad "Zero-Trust" pre/post análisis. | ❌ Riesgo de alteración no detectada de artefactos. |
| **Manejo de Logs** | No consolida los JSONL de los otros validadores. | ❌ Pérdida de telemetría asíncrona. |

---

## 🟡 CONCLUSIÓN ESTRATÉGICA

El script actual `orchestrator-engine.sh` **no es un orquestador**, sino un validador legacy. Debe ser descartado y reescrito por completo (v4.0). Su nueva responsabilidad será estrictamente delegar (modo *read-only*), coordinar la ejecución paralela de los 6 validadores (`verify-constraints`, `validate-frontmatter`, `validate-skill-integrity`, `check-wikilinks`, `audit-secrets`, `check-rls`), agregar los resultados y compilar un Dashboard Estático (`index.html` + `manifest.json`).
