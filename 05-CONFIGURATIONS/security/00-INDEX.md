---
# FRONTMATTER CANÓNICO OBLIGATORIO
artifact_id: "00-INDEX-security-index-v1.0.0"
artifact_type: "directory_index"
version: "1.0.0-COMPREHENSIVE"
constraints_mapped: ["C3","C5","C6","C7"]
canonical_path: "05-CONFIGURATIONS/security/00-INDEX.md"
domain: "05-CONFIGURATIONS"
subdomain: "security"
agent_role: "security-coordinator"
language_lock: "markdown"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain security --file 05-CONFIGURATIONS/security/00-INDEX.md --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants", "security_team"]
human_readable: true
checksum_sha256: "026eb4c94d3a44b211f7142b03408c0cabfaca06fb1b32c776d49e3c82ccb176"
# FIN FRONTMATTER
---
```

```markdown
# 🔒 05-CONFIGURATIONS/security/ — Índice de Seguridad y Cumplimiento

> **Propósito**: Catálogo maestro de políticas, procedimientos, herramientas de escaneo y gestión de credenciales del ecosistema MANTIS. Define estándares de endurecimiento, rotación de secretos, auditoría continua y cumplimiento normativo (CIS/NIST). Garantiza trazabilidad (C5), cero credenciales expuestas (C3) y gobernanza de cambios críticos (C6).

## 🗺️ Mapa de Componentes

| Componente | Ruta Canónica | Propósito | Constraints | Estado | Validación |
|------------|---------------|-----------|-------------|--------|------------|
| **Hardening de SO** | `vps-hardening.sh` | Endurecimiento pre-despliegue: UFW, Fail2Ban, SSH, Kernel | C3, C6, C7 | ✅ REAL | `shellcheck`, `cis-benchmark` |
| **Rotación de Secretos** | `../scripts/rotate-secrets.sh` | Rotación automática cada 90d con backup y auditoría | C3, C6, C7 | ✅ REAL | `audit-secrets.sh`, `jq` |
| **Políticas Vault** | `vault-policies.hcl` | Políticas RBAC y mínimos privilegios para HashiCorp Vault | C3, C6 | ✅ REAL | `vault policy fmt`, `checkov` |
| **Gestión de Claves Git-Crypt** | `git-crypt-keys/` | Almacenamiento seguro de claves de cifrado simétrico | C3, C6 | ✅ REAL | `git-crypt status`, `gpg` |
| **Auditoría de Cumplimiento** | `../scripts/audit-compliance.sh` | Escaneo CIS/NIST con Checkov, TFSec, Trivy y OPA | C5, C6 | ✅ REAL | `conftest`, `promtool` |
| **Verificación de Integridad** | `../scripts/backup-verify.sh` | Validación de checksums y restore de prueba de backups | C7, V2 | ✅ REAL | `pg_restore --list`, `sha256sum` |

## 🛡️ Estándares de Seguridad (C3/C6)

| Práctica | Regla | Herramienta/Flag |
|----------|-------|------------------|
| **Cero Secrets en Código** | Nunca hardcodear credenciales en `.tf`, `.yml`, `.sh`, `.py` o Dockerfiles | `audit-secrets.sh`, `trivy fs --scanners secret` |
| **Rotación Proactiva** | Credenciales rotadas automáticamente cada 90 días o tras rotación de personal | `rotate-secrets.sh --env prod --force` |
| **OIDC sobre Claves Largas** | Preferir `assume_role_with_web_identity` (AWS) o `Workload Identity` (GCP) | `provider-router.yml`, `backend.tf` |
| **Escaneo Continuo** | Todos los artefactos IaC y contenedores escaneados pre-merge | `checkov`, `tfsec`, `trivy image` |
| **Aprobación de Cambios Críticos** | Modificaciones en `security/` o prod requieren 2 reviewers + gate manual | GitHub Environment Protection Rules |

## 🔍 Comandos de Auditoría y Validación

```bash
# Escaneo de secretos hardcodeados en todo el dominio
bash 05-CONFIGURATIONS/validation/audit-secrets.sh --path 05-CONFIGURATIONS/

# Auditoría CIS/NIST de infraestructura como código
bash 05-CONFIGURATIONS/scripts/audit-compliance.sh --scope all --fail-on HIGH

# Verificar estado de cifrado git-crypt
git-crypt status --verbose

# Validar políticas Vault antes de aplicar
vault policy fmt -check vault-policies.hcl

# Validación integral de dominio security
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain security --strict
```

## ⚠️ Anti-Patrones Explícitos (DO NOT)

❌ Commitear `.env`, `*.pem`, `credentials.json` o `secrets/` con valores reales  
❌ Usar `PermitRootLogin yes` o `PasswordAuthentication yes` en producción  
❌ Definir security groups con `0.0.0.0/0` en puerto 22, 3306, 5432, 6379  
❌ Omitir `runbook_url` o `validation_command` en políticas o scripts nuevos  
❌ Aplicar cambios de infraestructura sin escaneo previo con `checkov`/`tfsec`  

✅ **Siempre** usar `--dry-run` en `vps-hardening.sh` o `rotate-secrets.sh` antes de aplicar  
✅ **Siempre** almacenar claves de cifrado en `git-crypt-keys/` con acceso GPG restringido  
✅ **Siempre** validar políticas Vault con `vault policy fmt` y aplicar via CI/CD con gate manual  
✅ **Siempre** registrar rotaciones y auditorías en `08-LOGS/security-audit/` para compliance  

## 🔗 Enlaces Canónicos Relacionados
- [[../00-INDEX.md]] → Índice maestro del dominio `05-CONFIGURATIONS/`
- [[../templates/observability-template.yaml]] → Estándares de métricas de seguridad (logs, alertas)
- [[../scripts/audit-compliance.sh]] → Motor de escaneo CIS/NIST automatizado
- [[https://www.cisecurity.org/benchmark/virtualization]] → Benchmarks CIS oficiales
- [[https://developer.hashicorp.com/vault/docs/policies]] → Documentación HashiCorp Vault

---
*Documento generado automáticamente por `generate-index.sh` v1.0.0 | Mantenido por `security-coordinator` | Constraints: C3, C5, C6, C7*

---
