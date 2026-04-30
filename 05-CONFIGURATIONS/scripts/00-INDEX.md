---
# FRONTMATTER CANÓNICO OBLIGATORIO
artifact_id: "00-index-scripts-index-v1.0.0"
artifact_type: "directory_index"
version: "1.0.0-COMPREHENSIVE"
constraints_mapped: ["C4","C5"]
canonical_path: "05-CONFIGURATIONS/scripts/00-INDEX.md"
domain: "05-CONFIGURATIONS"
subdomain: "scripts"
agent_role: "scripts-coordinator"
language_lock: "markdown"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain scripts --file 05-CONFIGURATIONS/scripts/00-INDEX.md --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants", "human_architects"]
human_readable: true
checksum_sha256: "4f613b616e6cfcd03b26859453d1f6c53f421af2c1f056c16ef152d3a00c32e4"
# FIN FRONTMATTER
---
```

```markdown
# 📂 05-CONFIGURATIONS/scripts/ — Índice de Scripts Operativos

> **Propósito**: Punto de entrada canónico y referencia técnica para todos los scripts de automatización, mantenimiento, remediación y gobernanza del ecosistema MANTIS. Proporciona mapeo de constraints, dependencias, flujos de ejecución seguros y comandos de validación para agentes y arquitectos.

## 🗺️ Catálogo Maestro de Scripts

| Script | Ruta Canónica | Propósito | Constraints | Dependencias | Estado | Validación |
|--------|---------------|-----------|-------------|--------------|--------|------------|
| `deploy-all.sh` | `05-CONFIGURATIONS/scripts/deploy-all.sh` | Orquestación CI/CD: Terraform → Docker → Health | C1,C2,C5,C7 | Terraform, Docker, jq | ✅ REAL | `shellcheck`, `orchestrator-engine.sh` |
| `onboard-tenant.sh` | `05-CONFIGURATIONS/scripts/onboard-tenant.sh` | Alta de cliente: Schema DB + RLS + Registry + Skills | C1,C3,C4,V1 | psql, jq, git | ✅ REAL | `bash -n`, `check-rls.sh` |
| `migrate-tenant.sh` | `05-CONFIGURATIONS/scripts/migrate-tenant.sh` | Migración segura entre entornos con checksum y gate | C4,C5,C7,V1 | pg_dump, pg_restore, sha256sum | ✅ REAL | `pg_restore --list`, `shellcheck` |
| `rotate-secrets.sh` | `05-CONFIGURATIONS/scripts/rotate-secrets.sh` | Rotación programada de credenciales (90d) con backup | C3,C6,C7 | openssl, jq, git-crypt/sops | ✅ REAL | `audit-secrets.sh`, `shellcheck` |
| `vps-hardening.sh` | `05-CONFIGURATIONS/security/vps-hardening.sh` | Endurecimiento de SO: UFW, Fail2Ban, SSH, Kernel | C3,C6,C7 | ufw, fail2ban, sysctl | ✅ REAL | `cis-benchmark`, `shellcheck` |
| `drift-remediate.sh` | `05-CONFIGURATIONS/scripts/drift-remediate.sh` | Remediación automática de desviaciones IaC | C2,C7,C8 | terraform, jq | ✅ REAL | `terraform plan`, `shellcheck` |
| `backup-verify.sh` | `05-CONFIGURATIONS/scripts/backup-verify.sh` | Verificación de integridad y restore de prueba de backups | C7,V2 | pg_restore, psql, sha256sum | ✅ REAL | `pg_verifybackup`, `shellcheck` |
| `canary-deploy.sh` | `05-CONFIGURATIONS/scripts/canary-deploy.sh` | Despliegue gradual con métricas y rollback automático | C7,C8,V3 | docker, curl, jq, prometheus | ✅ REAL | `shellcheck`, `promtool` |
| `audit-compliance.sh` | `05-CONFIGURATIONS/scripts/audit-compliance.sh` | Auditoría CIS/NIST automatizada (Checkov/TFSec/Trivy) | C5,C6 | checkov, trivy, tfsec, conftest | ✅ REAL | `shellcheck`, `conftest` |
| `validate-env-mapping.py` | `05-CONFIGURATIONS/scripts/validate-env-mapping.py` | Validación cruzada `.env.*` vs `mapping.yaml` | C3,C4,C5 | python3, pyyaml | ✅ REAL | `py_compile`, `yq` |
| `generate-adr.sh` | `05-CONFIGURATIONS/scripts/generate-adr.sh` | Generador de Architecture Decision Records con ID secuencial | C4,C5 | git, bash, date | ✅ REAL | `shellcheck`, `markdownlint` |

## 🔄 Flujos de Ejecución por Categoría

### 🚀 Despliegue & Orquestación
1. `./deploy-all.sh --env prod` → Orquesta ciclo completo
2. `./canary-deploy.sh --env prod --canary-image registry/app:v2.1.0` → Despliegue gradual con monitoreo
3. `./drift-remediate.sh --env staging --auto-apply` → Corrección automática de desviaciones

### 🔐 Seguridad & Rotación
1. `./vps-hardening.sh --env prod --dry-run` → Prueba de hardening
2. `./rotate-secrets.sh --env prod --keys DB_PASSWORD,API_KEY` → Rotación selectiva
3. `./audit-compliance.sh --scope all --fail-on HIGH` → Auditoría pre-merge

### 👥 Tenant & Migración
1. `./onboard-tenant.sh --tenant-id client-xyz --env dev` → Alta inicial con RLS
2. `./migrate-tenant.sh --tenant-id client-xyz --source dev --target staging` → Migración validada
3. `./backup-verify.sh --env staging --backup-path /backups/client-xyz.dump` → Verificación de integridad

### 📝 Documentación & Gobernanza
1. `./validate-env-mapping.py --env prod --strict` → Validación de variables cruzadas
2. `./generate-adr.sh --title "Migrar a Terraform Stacks" --context "..." --decision "..."` → Registro de decisiones arquitectónicas

## 🛡️ Estándares de Ejecución (C4/C5)

| Práctica | Regla | Comando/Flag |
|----------|-------|--------------|
| **Idempotencia** | Todos los scripts deben poder ejecutarse múltiples veces sin efectos secundarios | `--dry-run` antes de `--force` |
| **Carga de Entorno** | Nunca hardcodear variables. Cargar desde `.env.{environment}` | `source 05-CONFIGURATIONS/environment/.env.${ENV}` |
| **Validación Previa** | Ejecutar `shellcheck`/`py_compile` antes de producción | `bash -n script.sh` o `python3 -m py_compile script.py` |
| **Registro de Auditoría** | Todas las acciones críticas deben loguear timestamp, usuario y resultado | `tee -a /var/log/mantis-{script}.log` |
| **Rollback Automático** | Scripts con impacto en DB/Infra deben incluir `trap cleanup EXIT` | Definido en cada script |

## ⚠️ Anti-Patrones Explícitos (DO NOT)

❌ Ejecutar `deploy-all.sh` o `drift-remediate.sh` sin `--dry-run` en staging primero  
❌ Pasar credenciales como argumentos en línea de comandos (usan variables de entorno o archivos montados)  
❌ Omitir `validation_command` en frontmatter de nuevos scripts  
❌ Modificar scripts sin ejecutar `shellcheck` o `orchestrator-engine.sh --strict`  
❌ Usar `sudo` dentro de scripts sin verificación explícita de `$EUID`  

✅ **Siempre** usar `--dry-run` para simular cambios  
✅ **Siempre** verificar estado post-ejecución con `health-check.sh` o `backup-verify.sh`  
✅ **Siempre** commitear cambios en scripts con mensaje trazable y SHA256 actualizado  

## 🔗 Enlaces Canónicos Relacionados
- [[../00-INDEX.md]] → Índice maestro del dominio `05-CONFIGURATIONS/`
- [[../environment/mapping.yaml]] → Mapeo de variables y ownership
- [[../validation/orchestrator-engine.sh]] → Motor de validación de constraints
- [[../security/vps-hardening.sh]] → Hardening de sistema operativo
- [[../scripts/deploy-all.sh]] → Orquestador principal de despliegue

---
*Documento generado automáticamente por `generate-index.sh` v1.0.0 | Mantenido por `configurations-master-agent` | Constraints: C4, C5*

---
