---
title: "Agentic Infrastructure Validation Toolchain"
version: "1.0.0"
canonical_path: "TOOLCHAIN-REFERENCE.md"
ai_optimized: true
purpose: "Documentación técnica centralizada para el uso, integración y mantenimiento de los validadores y scripts operativos del ecosistema MANTIS AGENTIC."
audience: ["human_engineers", "agentic_assistants", "ci_cd_pipelines"]
constraints_mapped: ["C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --mode headless --file TOOLCHAIN-REFERENCE.md --json"
related_files:
  - "PROJECT_TREE.md"
  - "05-CONFIGURATIONS/validation/norms-matrix.json"
  - "05-CONFIGURATIONS/validation/orchestrator-engine.sh"
  - "05-CONFIGURATIONS/scripts/generate-repo-validation-report.sh"
---

# 📘 TOOLCHAIN-REFERENCE.md
---

## 🎯 Propósito y Alcance

Este documento es la **referencia técnica oficial** del ecosistema MANTIS AGENTIC. Centraliza el uso, parámetros, códigos de salida y patrones de integración de todos los validadores y scripts operativos. 

Está diseñado para ser **consumido por humanos y agentes de IA** con igual precisión: estructura determinista, comandos explícitos, guardrails claros y salida estandarizada en JSON para pipelines CI/CD.

> 🔐 **Regla de Oro**: Todos los validadores operan en modo `READ-ONLY`. Ningún script modifica archivos fuente. Los reportes se generan en `08-LOGS/validation/` o en archivos `*-report.json` adyacentes.

---

## 🤖 Guía de Uso para IA y Humanos

| Rol | Recomendación | Comando Base |
|-----|---------------|--------------|
| **Humano** | Ejecutar con `--verbose 1` para ver logs paso a paso. Usar `./script.sh --help` para referencia rápida. | `bash 05-CONFIGURATIONS/validation/<script>.sh --verbose 1` |
| **Agente IA** | Nunca usar `--verbose`. Capturar solo `stdout` para JSON. Validar `exit code` antes de continuar. | `bash <script> --json 2>/dev/null` |
| **CI/CD Pipeline** | Ejecutar en modo estricto `--strict 1`. Bloquear merge si `exit code != 0`. | `bash <script> --strict 1 --json` |

> 📌 **Nota para IA**: Si un script devuelve `exit 1` pero el JSON contiene `"status": "partial"` o `"blocking_message": ""`, es una advertencia de madurez, no un bloqueo fatal. Revisa `warnings` antes de fallar el pipeline.

---

## 🛡️ Suite de Validación (`05-CONFIGURATIONS/validation/`)

| Script | Versión | Propósito | Comando Canónico | Flags Clave | Salida | Notas |
|--------|---------|-----------|------------------|-------------|--------|-------|
| `orchestrator-engine.sh` | `1.1.0` | Motor central de validación SDD. Enruta checks C1-C8, invoca validadores secundarios, calcula score/tier. | `bash ... --mode headless --file <ruta> --json` | `--mode [headless\|verbose]`, `--json`, `--file` | JSON estructurado | Requiere `norms-matrix.json`. No usar en directorios completos. |
| `audit-secrets.sh` | `1.1.0` | Detección de credenciales hardcodeadas (AI keys, DB pass, SSH, cloud). Filtra placeholders seguros. | `bash ... <ruta> [reporte.json] [verbose:0/1] [strict:0/1]` | `[1-5]`, `--pre-commit` | JSON + stdout | Usa `grep -F -q --`. Excluye `${VAR:?missing}` y `GENERAR_CON_*`. |
| `verify-constraints.sh` | `2.0.0` | Validación explícita de C1-C6 con scoring ponderado y validación contextual (code/doc/template). | `bash ... <ruta> [reporte.json] [verbose:0/1] [strict:0/1]` | `[1-4]` | JSON + stdout | Peso: C3/C4=25, C1/C2=10, C5/C6=15. Docs/templates tienen reglas relajadas. |
| `check-rls.sh` | `2.0.0` | Verifica aislamiento multi-tenant: `WHERE tenant_id=?`, `RLS POLICY`, excepciones documentadas. | `bash ... <ruta\|dir> [reporte.json] [verbose:0/1] [strict:0/1]` | `[1-4]` | JSON + stdout | Extrae bloques SQL de `.md`. Omite archivos sin SQL. Detecta `-- C4_EXEMPT`. |
| `check-wikilinks.sh` | `1.3.0` | Valida enlaces `[[ruta/canónica.md]]`. Detecta rotos, cíclicos y auto-referencias. | `bash ... <ruta> [reporte.json] [verbose:0/1] [strict:0/1]` | `[1-4]` | JSON + stdout | Resuelve contra `PROJECT_TREE.md`. Reporta warnings para `self-reference`. |
| `validate-frontmatter.sh` | `2.0.2` | Verifica bloques YAML/`# ---`, campos obligatorios (`purpose`, `version` semver), `related_files` válidos. | `bash ... <ruta\|dir> [reporte.json] [verbose:0/1] [strict:0/1]` | `[1-4]` | JSON + stdout | Omite `.tf/.json/.yml`. Falla si falta `purpose` o versión no es `X.Y.Z`. |
| `validate-skill-integrity.sh` | `2.0.1` | Valida estructura de skills: ≥5 ejemplos `✅/❌/🔧`, `validation_command`, constraints referenciados. | `bash ... <ruta> [reporte.json] [verbose:0/1] [strict:0/1]` | `[1-4]` | JSON + stdout | Usa `git rev-parse --show-toplevel`. Omite `INDEX/README/template` de checks técnicos. |

---

## ⚙️ Scripts Operativos (`05-CONFIGURATIONS/scripts/`)

| Script | Versión | Propósito | Comando Canónico | Estado | Notas |
|--------|---------|-----------|------------------|--------|-------|
| `generate-repo-validation-report.sh` | `4.0.0` | Ejecuta validación masiva, genera reportes consolidados en `08-LOGS/validation/`, backup preventivo con `rsync`, bloqueo `chattr +i`. | `bash ... [REPO_ROOT] [BACKUP_ROOT]` | ✅ Estable | Modo `PREVENTIVE_READ_ONLY_AUDIT`. Cero escritura en fuentes. |
| `validate-against-specs.sh` | `2.0.1` | Validación estructural rápida: shebang, frontmatter, constraints C1-C8, ejemplos, determinismo. | `bash ... <ruta> [reporte.json]` | ✅ Estable | Ideal para pre-generación de artefactos. Contadores blindados contra `\r\n`. |
| `health-check.sh` | `1.0.0` | Verificación de servicios VPS (puertos, procesos, uptime, carga). | `bash ... [host] [timeout]` | ⚠️ No probado | Requiere servidor activo. Usa `curl`, `nc`, `systemctl`. |
| `backup-mysql.sh` | `1.0.0` | Backup cifrado de DB con `mysqldump`, `age`, rotación y checksum SHA256. | `bash ... [db_name] [backup_dir] [encryption_key]` | ⚠️ No probado | Requiere MySQL y `age`. Valida integridad post-backup. |
| `packager-assisted.sh` | `1.0.0` | Empaquetado de skills/modulos validados en `.tar.gz` con manifiesto SDD y firma SHA256. | `bash ... <source_dir> <output.tar.gz>` | ⚠️ No probado | Usa `orchestrator-engine.sh` para validar antes de empaquetar. |

---

## 📊 Matriz de Comandos Rápidos

| Caso de Uso | Comando Exacto | Salida Esperada |
|-------------|----------------|-----------------|
| Validar 1 archivo (modo CI) | `bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --mode headless --file <ruta> --json` | JSON + `exit 0/1` |
| Auditoría de secretos pre-commit | `bash 05-CONFIGURATIONS/validation/audit-secrets.sh . secrets-audit-report.json 0 1` | JSON + `exit 1` si críticos |
| Validar RLS en SQL skills | `bash 05-CONFIGURATIONS/validation/check-rls.sh "02-SKILLS/BASE DE DATOS-RAG/vertical-db-schemas.md"` | JSON + `exit 0/1` |
| Verificar wikilinks canónicos | `bash 05-CONFIGURATIONS/validation/check-wikilinks.sh PROJECT_TREE.md` | JSON + warnings de cíclicos |
| Validar frontmatter masivo | `bash 05-CONFIGURATIONS/validation/validate-frontmatter.sh 02-SKILLS/` | JSON por carpeta o único |
| Validar integridad de skill | `bash 05-CONFIGURATIONS/validation/validate-skill-integrity.sh "02-SKILLS/.../skill.md"` | JSON + conteo de ejemplos |
| Generar reportes + backup | `bash 05-CONFIGURATIONS/scripts/generate-repo-validation-report.sh` | Logs en `08-LOGS/`, backup en `/home/ricardo/Backup Proyecto/` |
| Validación estructural rápida | `bash 05-CONFIGURATIONS/scripts/validate-against-specs.sh <ruta>` | JSON + `passed/partial/failed` |

---

## 🔌 Integración en Pipelines y Agentes

### 🔹 Pre-commit Hook (Git)
```bash
#!/bin/sh
# .git/hooks/pre-commit
bash 05-CONFIGURATIONS/validation/audit-secrets.sh --pre-commit || exit 1
bash 05-CONFIGURATIONS/validation/validate-frontmatter.sh . frontmatter-report.json || exit 1
```

### 🔹 Pipeline CI/CD (GitHub Actions / GitLab CI)
```yaml
- name: SDD Validation Suite
  run: |
    bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --mode headless --file "$CHANGED_FILE" --json > report.json
    jq -e '.status == "passed" or .status == "human_review_required"' report.json || exit 1
```

### 🔹 Prompt Maestro para Agentes IA
```text
⛔ RESTRICCIÓN: Usar únicamente los comandos documentados en TOOLCHAIN-REFERENCE.md.
⛔ NUNCA modificar archivos fuente. Todos los validadores son READ-ONLY.
✅ CAPTURAR SOLO stdout para JSON. Validar exit code antes de continuar.
✅ Si .status == "failed" o .blocking_issues existe, detener flujo y reportar.
✅ Usar --strict 1 solo en entornos CI/CD. Para desarrollo, omitir flag.
```

---

## 🚦 Códigos de Salida y Diagnóstico

| Código | Significado | Acción Recomendada |
|--------|-------------|-------------------|
| `0` | Validación exitosa o `human_review_required` | Continuar pipeline. Revisar `warnings` si existen. |
| `1` | Fallo crítico, `SCORE_FAIL`, o `--strict` activado | Detener flujo. Revisar `blocking_issues` o `failures`. |
| `2` | Error de ejecución (ruta inválida, dependencia faltante) | Corregir entorno. Revisar `stderr`. |

📍 **Logs de Auditoría**: 
- Reportes JSON: `08-LOGS/validation/*.md` o `*-report.json` adyacentes.
- Backup preventivo: `/home/ricardo/Backup Proyecto/agentic-infra-docs_BACKUP_YYYYMMDD_HHMMSS/`
- Integridad: Cada reporte incluye `script_sha256` y `report_sha256`.

---

## 🛡️ Guardrails para Agentes de IA

1. **Ejecución Segura**: Siempre ejecutar con `bash` explícito, nunca con `./` sin `chmod`.
2. **Rutas Relativas**: Usar rutas relativas desde `REPO_ROOT`. No hardcodear `/home/ricardo/...`.
3. **Captura de Salida**: `cmd_out=$(bash <script> --json 2>/dev/null)` → nunca redirigir `stdout` al mismo archivo de entrada.
4. **Validación Post-Ejecución**: Siempre ejecutar `echo "$cmd_out" | jq empty >/dev/null && echo "✅ JSON válido"`.
5. **Fallo Silencioso**: Si `jq` o `bash` no están disponibles, abortar con `exit 2`. No asumir comportamiento.

---

## 📝 Historial de Versiones

| Fecha | Script | Versión | Cambio Clave |
|-------|--------|---------|--------------|
| 2026-04-15 | `orchestrator-engine.sh` | `1.1.0` | Headless mode, JSON estructurado, routing de validadores |
| 2026-04-15 | `audit-secrets.sh` | `1.1.0` | Fix `grep -F -q --`, exclusión de placeholders, JSON seguro |
| 2026-04-15 | `verify-constraints.sh` | `2.0.0` | Context-aware, scoring ponderado, skip docs/templates |
| 2026-04-15 | `check-rls.sh` | `2.0.0` | Parser SQL robusto, detección `C4_EXEMPT`, skip no-SQL |
| 2026-04-15 | `check-wikilinks.sh` | `1.3.0` | Resolución canónica, detección cíclicas, sin errores grep |
| 2026-04-15 | `validate-frontmatter.sh` | `2.0.2` | Parser `# ---`, semver estricto, resolución `related_files` |
| 2026-04-15 | `validate-skill-integrity.sh` | `2.0.1` | Conteo ejemplos real, `${raw%]]}`, filtro `INDEX/README` |
| 2026-04-15 | `validate-against-specs.sh` | `2.0.1` | Aritmética blindada, reporte coherente, ejecución limpia |
| 2026-04-15 | `generate-repo-validation-report.sh` | `4.0.0` | Backup preventivo, `chattr +i`, checksum pre/post, modo read-only |

---

> ✅ **Documento generado bajo contrato SDD v1.0.0**. Validado contra `norms-matrix.json`. Listo para integración en pipelines, agentes y documentación técnica.  
> 🔐 Para dudas o extensión de guardrails, revisar `05-CONFIGURATIONS/validation/norms-matrix.json` y `01-RULES/01-ARCHITECTURE-RULES.md`.
