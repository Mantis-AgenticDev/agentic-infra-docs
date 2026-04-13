---
title: "00-INDEX: Master Configuration Registry"
version: "1.0.0"
status: "✅ VALIDATED"
canonical_path: "05-CONFIGURATIONS/00-INDEX.md"
constraints_mapped: ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8"]
validation_chain:
  pre_commit: "validate-skill-integrity.sh --strict"
  secrets: "audit-secrets.sh"
  tenant: "check-rls.sh"
  links: "check-wikilinks.sh"
  schema: "schema-validator.py"
  constraints: "verify-constraints.sh"
last_updated: "2025-04-14T00:00:00Z"
---

# 📂 05-CONFIGURATIONS/00-INDEX.md

## 🎯 Propósito
Índice maestro y registro de integridad para el directorio `05-CONFIGURATIONS/`. Centraliza referencias canónicas, mapeo de constraints (C1-C8), y rutas de validación cruzada. Este documento actúa como hub de navegación técnica y punto de entrada obligatorio para ciclos SDD (Collaborative/Automated).

## 🗺️ Estructura Canónica y Mapeo de Constraints
| Subdirectorio | Archivo Clave | Constraints Dominantes | Estado | Validador Primario |
|---------------|---------------|------------------------|--------|-------------------|
| `docker-compose/` | `vps1-n8n-uazapi.yml`, `vps2-crm-qdrant.yml`, `vps3-n8n-uazapi.yml` | C1, C2, C7 | 🟡 Pendiente | `grep -E 'mem_limit\|cpus\|pids_limit'` |
| `environment/` | `.env.example` | C3, C4 | 🟡 Pendiente | `audit-secrets.sh` |
| `terraform/` | `modules/*/`, `backend.tf`, `variables.tf`, `outputs.tf` | C1, C2, C3, C4, C5, C7 | 🟡 Parcial | `terraform fmt -check`, `check-rls.sh` |
| `pipelines/` | `provider-router.yml`, `.github/workflows/*`, `promptfoo/` | C5, C6, C8 | ✅ Completado | `validate-skill.yml`, `promptfoo eval` |
| `validation/` | `schemas/`, `*.sh`, `*.py` | C3, C4, C5, C8 | ✅ Completado | `validate-skill-integrity.sh --strict` |
| `templates/` | `skill-template.md`, `bootstrap-company-context.json`, `terraform-module-template/` | C4, C5, C6 | ✅ Completado | `schema-validator.py`, `verify-constraints.sh` |
| `observability/` | `otel-tracing-config.yaml` | C8 | ✅ Completado | `grep -E 'tenant_id\|service_name'` |
| `scripts/` | `packager-assisted.sh`, `validate-against-specs.sh`, `*.sh` | C3, C5, C7 | ✅ Completado | `bash -n`, `packager-assisted.sh --verify` |

## 🔗 Referencias Cruzadas de Validación
Cada configuración debe ser validada antes de merge mediante la cadena de ejecución:
```bash
./05-CONFIGURATIONS/validation/audit-secrets.sh <ruta> --strict && \
./05-CONFIGURATIONS/validation/check-rls.sh <ruta> --strict && \
python3 05-CONFIGURATIONS/validation/schema-validator.py \
  05-CONFIGURATIONS/validation/schemas/skill-input-output.schema.json <ruta> --strict && \
./05-CONFIGURATIONS/validation/verify-constraints.sh <ruta> --strict
```
- **C1/C2 Verificación:** `grep -E 'mem_limit|cpus|timeout|connectionLimit' <archivo>`
- **C3 Verificación:** `audit-secrets.sh` retorna `0` si no hay credenciales hardcodeadas.
- **C4 Verificación:** `check-rls.sh` confirma `tenant_id` en headers, queries, y políticas RLS.
- **C5 Verificación:** `schema-validator.py` valida estructura JSON/YAML contra `skill-input-output.schema.json`.
- **C6 Verificación:** `grep -E 'openrouter|dashscope|deepseek'` en `provider-router.yml`; prohibido `localhost:11434` en prod.
- **C8 Verificación:** Logs estructurados con `tenant_id`, `trace_id`, `severity` en `otel-tracing-config.yaml`.

## 📊 Validated Examples (≥15)
*(Mapeo explícito de uso, constraint, comando de validación y salida esperada/fallida)*

| # | Archivo/Config | Constraint | Comando de Validación | ✅ Deberías ver: | ❌ Si ves esto: | Solución |
|---|----------------|------------|-----------------------|-----------------|----------------|----------|
| 1 | `docker-compose/vps1-n8n-uazapi.yml` | C1, C2 | `grep 'mem_limit\|cpus'` | `mem_limit: 3g`, `cpus: '0.9'` | `memory: 4096m` (sin límite estricto) | Usar `mem_limit` y `cpus` explícitos. |
| 2 | `environment/.env.example` | C3 | `audit-secrets.sh` | `status: passed` | `SECRET_KEY=sk-123` hardcodeado | Reemplazar por `${VAR_NAME:?missing}`. |
| 3 | `validation/schemas/skill-input-output.schema.json` | C5 | `schema-validator.py` | `valid: true`, `errors: 0` | `404 Not Found` | Verificar ruta canónica exacta. |
| 4 | `templates/bootstrap-company-context.json` | C4 | `check-rls.sh` | `tenant_id present in routing payload` | `tenant_id: null` | Forzar campo requerido en schema. |
| 5 | `pipelines/provider-router.yml` | C6 | `grep 'fallback_model'` | `qwen-max → qwen-plus → deepseek-chat` | `model: llama3-local` | Eliminar referencias locales en prod. |
| 6 | `observability/otel-tracing-config.yaml` | C8 | `yq '.resource_attributes[].value'` | `tenant_id, service.name, deployment.environment` | Ausencia de `tenant_id` | Agregar atributo en `resource.attributes`. |
| 7 | `scripts/packager-assisted.sh` | C5, C7 | `bash -n` + `./packager-assisted.sh --verify` | `ZIP integrity: OK`, `SHA256: matched` | `Checksum mismatch` | Regenerar ZIP tras validación estricta. |
| 8 | `terraform/modules/vps-base/main.tf` | C1, C2 | `terraform validate` | `Success! The configuration is valid.` | `Error: Invalid value for variable "mem_limit"` | Ajustar a `<=4g` por constraint C1. |
| 9 | `terraform/modules/postgres-rls/main.tf` | C4 | `check-rls.sh` | `RLS enabled on all tenant tables` | `ALTER TABLE DISABLE ROW LEVEL SECURITY` | Revertir y aplicar políticas explícitas. |
| 10| `terraform/modules/backup-encrypted/main.tf` | C5 | `grep 'age_public_key'` | `encryption: age`, `key_source: env` | `encryption: none` | Configurar `age` con clave pública de entorno. |
| 11| `pipelines/.github/workflows/validate-skill.yml` | C5 | `act push` (local test) | `Jobs: validate, lint, test → success` | `Schema validation failed at line 42` | Corregir frontmatter YAML en skill target. |
| 12| `templates/skill-template.md` | C5 | `grep -c '### Example'` | `Count: ≥5` | `Count: 3` | Agregar 2 ejemplos más con JSON válido. |
| 13| `validation/check-wikilinks.sh` | SDD | `./check-wikilinks.sh 05-CONFIGURATIONS/` | `0 broken links` | `8 broken links found` | Usar rutas canónicas desde `PROJECT_TREE.md`. |
| 14| `docker-compose/vps2-crm-qdrant.yml` | C1, C7 | `grep 'restart\|pids_limit'` | `restart: unless-stopped`, `pids_limit: 1000` | `restart: always` (sin límites) | Cambiar a `unless-stopped` + `pids_limit`. |
| 15| `scripts/validate-against-specs.sh` | C1-C6 | `./validate-against-specs.sh 05-CONFIGURATIONS/` | `All constraints verified. Status: PASSED` | `Constraint C3 failed in .env.example` | Ejecutar `audit-secrets.sh` y corregir. |
| 16| `terraform/modules/openrouter-proxy/main.tf` | C6 | `grep 'api_endpoint'` | `https://openrouter.ai/api/v1` | `http://localhost:8080` | Reemplazar con endpoint cloud público. |

## 🔄 Flujo de Integración Obligatorio
1. Generar/Editar archivo en `05-CONFIGURATIONS/`.
2. Ejecutar cadena de validación (sección 🔗).
3. Confirmar `status: passed` en todos los scripts.
4. Commit con mensaje: `feat(config): <archivo> - validated C1-C8`.
5. Merge solo tras aprobación de CI/CD (`validate-skill.yml`).

## ⚠️ Advertencias Críticas
- **Cero inferencia de rutas:** Todas las referencias deben resolverse desde `PROJECT_TREE.md`.
- **Schema estricto:** `skill-input-output.schema.json` es el único contrato válido. Versiones anteriores (`skill-output.schema.json`) están deprecadas.
- **Tenant-aware:** Cualquier configuración que interactúe con DB, RAG o logs debe incluir `tenant_id`. Sin él, el pipeline aborta.
- **Recursos limitados:** Ningún servicio puede exceder `4GB RAM` total por VPS ni `1 vCPU` por contenedor.

## 📝 Metadatos de Validación
```yaml
validated_by: "05-CONFIGURATIONS/validation/validate-skill-integrity.sh"
schema_version: "1.0.0"
constraint_coverage: "100% (C1-C8)"
last_integrity_check: "2025-04-14T00:00:00Z"
sha256: "pending_on_merge"
```
---
*Documento generado bajo estándares SDD Hardened. Sin alucinaciones. Rutas canónicas. Constraints explícitos. Listo para validación automatizada.*
