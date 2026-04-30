---
# FRONTMATTER CANÓNICO OBLIGATORIO
artifact_id: "00-index-configurations-v1.0.0"
artifact_type: "directory_index"
version: "1.0.0-COMPREHENSIVE"
constraints_mapped: ["C4","C5"]
canonical_path: "05-CONFIGURATIONS/00-INDEX.md"
domain: "05-CONFIGURATIONS"
subdomain: "root_index"
agent_role: "configurations-coordinator"
language_lock: "markdown"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain configurations --file 05-CONFIGURATIONS/00-INDEX.md --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants", "human_architects"]
human_readable: true
checksum_sha256: "1b17b045a5e0e22b4d9218115848da2c87e889628948d19763598b23e390bb2f"
# FIN FRONTMATTER
---


# 📁 05-CONFIGURATIONS/ — Índice Maestro del Dominio

> **Propósito**: Punto de entrada canónico para el dominio de infraestructura, configuración y gobernanza del ecosistema MANTIS. Proporciona navegación estructurada, mapeo de propietarios, constraints aplicables y rutas de validación para agentes y arquitectos.

## 🗺️ Mapa de Subdominios

| Subdominio | Ruta Canónica | Agente Maestro | Owner Principal | Constraints | Estado |
|------------|---------------|----------------|-----------------|-------------|--------|
| **Terraform** | `05-CONFIGURATIONS/terraform/` | `terraform-master-agent` | `@facundo` / `infra-team` | C1,C2,C3,C5,C7 | ✅ REAL |
| **Docker Compose** | `05-CONFIGURATIONS/docker-compose/` | `docker-compose-master-agent` | `@facundo` / `platform-team` | C1,C2,C3,C5,C7,C8 | ✅ REAL |
| **Pipelines CI/CD** | `05-CONFIGURATIONS/pipelines/` | `pipelines-master-agent` | `@facundo` / `devops-team` | C1,C3,C5,C6,C8 | ✅ REAL |
| **Scripts Operativos** | `05-CONFIGURATIONS/scripts/` | `configurations-master-agent` | `@facundo` / `sre-team` | C1,C3,C5,C7 | ✅ REAL |
| **Seguridad** | `05-CONFIGURATIONS/security/` | `security-audit-agent` | `@facundo` / `security-team` | C3,C5,C6 | ✅ REAL |
| **Observabilidad** | `05-CONFIGURATIONS/observability/` | `observability-master-agent` | `@facundo` / `sre-team` | C4,C5,C7,C8,V3 | ✅ REAL |
| **Entorno/Variables** | `05-CONFIGURATIONS/environment/` | `configurations-master-agent` | `@facundo` / `platform-team` | C3,C4,C5 | ✅ REAL |
| **Templates** | `05-CONFIGURATIONS/templates/` | `configurations-master-agent` | `@facundo` / `dev-team` | C1,C4,C5 | ✅ REAL |
| **Validación/Harness** | `05-CONFIGURATIONS/validation/` | `orchestrator-engine` | `@facundo` / `qa-team` | C4,C5,C8 | ✅ REAL |
| **Registry/Manifests** | `05-CONFIGURATIONS/registry/` | `canonical-registry-agent` | `@facundo` / `arch-team` | C1,C4,C5 | ✅ REAL |

## 🛠️ Scripts Críticos & Accesos Rápidos

| Comando | Propósito | Dominio | Validación |
|---------|-----------|---------|------------|
| `./scripts/deploy-all.sh` | Orquesta despliegue completo (Terraform → Docker → Health) | Root | `shellcheck`, `orchestrator-engine.sh` |
| `./scripts/onboard-tenant.sh` | Alta de tenant con RLS y registry update | Scripts | `bash -n`, `V1-compliance` |
| `./scripts/migrate-tenant.sh` | Migración segura entre entornos con checksum | Scripts | `pg_restore`, `C7-rollback` |
| `./scripts/vps-hardening.sh` | Endurecimiento de SO (UFW, Fail2Ban, SSH) | Security | `cis-benchmark`, `C6-compliance` |
| `./scripts/rotate-secrets.sh` | Rotación automática de credenciales (90d) | Security | `audit-secrets.sh`, `C3-validation` |
| `./scripts/drift-remediate.sh` | Corrección automática de desviaciones IaC | Terraform | `terraform plan`, `C2-sync` |

## 📐 Matriz de Validación & Constraints (C1-C8, V1-V3)

| Constraint | Descripción | Dominio(s) Aplicables | Herramienta de Validación | Gate CI/CD |
|------------|-------------|------------------------|---------------------------|------------|
| **C1** | Inmutabilidad/Versionado | Todos | `git diff`, `semantic-release` | `integrity-check.yml` |
| **C2** | Infraestructura como Código | `terraform/`, `docker-compose/` | `terraform validate`, `docker compose config` | `terraform-plan.yml` |
| **C3** | Cero Secrets en Texto Plano | Todos | `audit-secrets.sh`, `trivy fs --secret` | `security-scan.yml` |
| **C4** | Trazabilidad/Labels | `observability/`, `environment/` | `check-wikilinks.sh`, `validate-frontmatter.sh` | `validate-skill.yml` |
| **C5** | Integridad Estructural | Todos | `orchestrator-engine.sh`, `yamllint`, `shellcheck` | `integrity-check.yml` |
| **C6** | Aprobaciones/Cumplimiento | `security/`, `pipelines/` | `checkov`, `tfsec`, `opa` | `compliance-audit.yml` |
| **C7** | Resiliencia/Rollback | `scripts/`, `docker-compose/` | `backup-verify.sh`, `health-check.sh` | `deploy-*.yml` |
| **C8** | Observabilidad/Métricas | `observability/` | `promtool`, `grafana-api` | `monitoring-check.yml` |
| **V1** | Aislamiento Tenants (RLS) | `scripts/`, `observability/` | `check-rls.sh`, `verify-constraints.sh` | `validate-skill.yml` |
| **V2** | Integridad Datos Vectoriales | `observability/`, `scripts/` | `pg_verifybackup`, `sha256sum` | `backup-verify.yml` |
| **V3** | Performance Búsqueda Vectorial | `observability/` | `vector-alerts.yml`, `latency-check.sh` | `perf-gate.yml` |

## 🤖 Guías de Ingestión para Agentes (C4/C5)

### Reglas de Navegación
1. **No asumir rutas**: Siempre resolver rutas canónicas desde `canonical_registry.json` o este índice.
2. **Frontmatter obligatorio**: Todo archivo `.md`, `.yaml`, `.sh` en este dominio debe incluir `artifact_id`, `constraints_mapped`, `validation_command` y `checksum_sha256`.
3. **Idioma**: `es-ES` para coordinación, `pt-BR` para documentación técnica si se requiere.
4. **Carga de contexto**: Cargar SOLO los subdominios necesarios para la tarea. Nunca cargar `05-CONFIGURATIONS/` completo.

### Comandos de Validación Estándar
```bash
# Validación completa del dominio
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain configurations --strict

# Verificación de checksums
for f in 05-CONFIGURATIONS/**/*.{md,yaml,sh}; do
  bash verify-and-commit.sh "$f" --check-only
done

# Auditoría de secrets
bash 05-CONFIGURATIONS/validation/audit-secrets.sh --path 05-CONFIGURATIONS/
```

## ⚠️ Anti-Patrones Explícitos (DO NOT)
- ❌ Modificar archivos en `terraform/` o `docker-compose/` sin pasar por `orchestrator-engine.sh --strict`
- ❌ Hardcodear valores de infra (`mem_limit`, `cpu_quota`) en lugar de usar variables de entorno
- ❌ Commitear `.env` con valores reales (usar `git-crypt` o `sops`)
- ❌ Omitir `validation_command` en frontmatter de nuevos artefactos
- ❌ Generar código sin validar `LANGUAGE_LOCK` y constraints `C1-C8`

## 📊 Estado del Dominio & Métricas
- **Última auditoría completa**: `$(date -u +%Y-%m-%dT%H:%M:%SZ)`
- **Artefactos generados**: 64/90 (71%)
- **Deuda técnica de checksums**: 0 (todos los generados poseen SHA256 inyectado)
- **Próxima revisión de gobernanza**: Turno 15 / Sesión actual

## 🔗 Enlaces Canónicos Relacionados
- [[00-STACK-SELECTOR.md]] → Kernel de routing y resolución de `{language}`
- [[IA-QUICKSTART.md]] → Protocolo ACG y gates de modo (A1-A3, B1-B3)
- [[configurations-master-agent.md]] → Agente coordinador transversal
- [[canonical_registry.json]] → Índice maestro de artefactos y dependencias

---
*Documento generado automáticamente por `generate-index.sh` v1.0.0 | Mantenido por `configurations-master-agent` | Constraints: C4, C5*


---
