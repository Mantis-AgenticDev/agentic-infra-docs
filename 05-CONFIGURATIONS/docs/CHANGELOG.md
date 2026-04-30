---
# FRONTMATTER CANÓNICO OBLIGATORIO
artifact_id: "changelog-v1.0.0"
artifact_type: "documentation"
version: "1.0.0-COMPREHENSIVE"
constraints_mapped: ["C1","C4","C5"]
canonical_path: "05-CONFIGURATIONS/docs/CHANGELOG.md"
domain: "05-CONFIGURATIONS"
subdomain: "docs"
agent_role: "changelog-coordinator"
language_lock: "markdown"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain docs --file 05-CONFIGURATIONS/docs/CHANGELOG.md --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants", "release_team", "human_architects"]
human_readable: true
checksum_sha256: "140c822fca3dba7eba84dc1d1d59147703e446d354d4052566dab5705456af2c"
# FIN FRONTMATTER
---
```

```markdown
# 📜 CHANGELOG — 05-CONFIGURATIONS/ (MANTIS AgenticDev)

> **Propósito**: Registro estructurado y automatizado de cambios en el dominio de configuraciones. Generado y actualizado vía CI/CD (`semantic-release`). No editar manualmente; usar commits con prefijos convencionales.

---

## 🔄 Reglas de Versionado (C1: Semantic Versioning)

| Prefijo de Commit | Tipo de Cambio | Incremento | Ejemplo |
|-------------------|----------------|------------|---------|
| `feat:` | Nueva funcionalidad, módulo, script o pipeline | `MINOR` (`v1.1.0`) | `feat: add vps-hardening.sh with UFW/Fail2Ban support` |
| `fix:` | Corrección de bug, drift o validación rota | `PATCH` (`v1.0.1`) | `fix: resolve checksum mismatch in deploy-all.sh` |
| `BREAKING CHANGE:` o `feat!:` | Cambio incompatible con versiones anteriores | `MAJOR` (`v2.0.0`) | `feat!: migrate terraform backend to remote S3+DynamoDB` |
| `chore:`, `docs:`, `refactor:`, `test:` | Mantenimiento, documentación, tests | `Sin incremento` | `chore: update checksum in frontmatter` |

---

## 🗓️ Historial de Versiones

<!-- Este bloque se genera automáticamente. No modificar manualmente. -->

### [Unreleased]
#### Added
- `clean-old-releases.sh` con política de retención configurable y auditoría JSONL
- `audit-configs.sh` para cruce automático contra `interface-spec.yaml` y validación nativa
- `terraform/modules/README-TEMPLATE.md` estandarizado para todos los módulos IaC

#### Changed
- Actualización de constraints mapping en frontmatter de 26+ artefactos
- Unificación de `validation_command` en todos los dominios

#### Fixed
- Corrección de `canary-deploy.sh` para manejo correcto de variables de entorno
- Alineación de `prometheus-rules` con nuevos exporters de Qdrant/pgvector

---

### [1.0.0] - 2026-05-01
#### Added
- `interface-spec.yaml` como contrato único Terraform ↔ Docker ↔ Agents
- `onboard-tenant.sh`, `migrate-tenant.sh` con validación RLS y rollback
- `vps-hardening.sh`, `rotate-secrets.sh`, `drift-remediate.sh`, `backup-verify.sh`
- Índices canónicos: `00-INDEX.md`, `scripts/00-INDEX.md`, `observability/00-INDEX.md`, `security/00-INDEX.md`
- Plantillas: `docker-compose-template.yml`, `observability-template.yaml`, `runbook-template.md`
- Placeholders estructurados: `output/.gitkeep`, `variable/.gitkeep`, `main/.gitkeep`
- Pipeline configs: `provider-router.yml`, `vector-alerts.yml`, `loki-config.yml`, `vector-performance.json`
- `generate-adr.sh` con ID secuencial y validación de secciones obligatorias

#### Security
- Implementación estricta de `C3: Zero Hardcoded Secrets` en todos los scripts
- Auditoría CIS/N integrada vía `audit-compliance.sh`

---

## 🤖 Automatización CI/CD

Este archivo se genera automáticamente mediante `semantic-release` y `@semantic-release/changelog`. Flujo:

1. Developer/Agente commitea con `feat:`, `fix:`, `chore:` siguiendo [Conventional Commits](https://www.conventionalcommits.org/)
2. Pipeline ejecuta `commit-analyzer` → determina `nextRelease.version`
3. Plugin `changelog` agrupa cambios por tipo, inyecta enlaces a commits/PRs y actualiza este archivo
4. `git` plugin commitea `CHANGELOG.md` + `package.json` con tag `v{version}`
5. **Nunca editar manualmente**. Si se detecta edición humana fuera del pipeline, CI revierte con `AUDIT_FLAG=changelog_manual_override`.

---

## 🔍 Validación Estructural (C5)

```bash
# Verificar que el archivo cumple formato Keep a Changelog
grep -qE "^## \[[0-9]+\.[0-9]+\.[0-9]+\]" 05-CONFIGURATIONS/docs/CHANGELOG.md && echo "✅ Formato válido"

# Validar enlaces a commits/PRs (si aplica)
grep -qE "\[.*\]\(.*commit/.*\)" 05-CONFIGURATIONS/docs/CHANGELOG.md || echo "ℹ️ Enlaces opcionales según configuración de repo"

# Validar constraints con orchestrator-engine
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain docs --file 05-CONFIGURATIONS/docs/CHANGELOG.md --strict
```

---

## ⚠️ Anti-Patrones Explícitos (DO NOT)

❌ Editar manualmente entradas debajo de `[Unreleased]` sin pasar por PR aprobado  
❌ Usar prefijos no convencionales (`add:`, `update:`, `patch:`) → rompe `semantic-release`  
❌ Omitir enlaces a ADRs o `canonical_registry.json` cuando un cambio modifica arquitectura  
❌ Commitear sin actualizar `canonical_registry.json` si se añaden artefactos críticos  

✅ **Siempre** usar `feat:`, `fix:`, `chore:` en mensajes de commit  
✅ **Siempre** vincular cambios estructurales a ADRs (`ADR-{id}`)  
✅ **Siempre** ejecutar `git log --oneline --grep="^feat\|^fix" | head` para validar historial antes de merge  

---

## 🔗 Enlaces Canónicos Relacionados
- [[../00-INDEX.md]] → Índice maestro del dominio
- [[../canonical_registry.json]] → Registro de artefactos y checksums
- [[../.github/workflows/release.yml]] → Pipeline de versionado automático
- [[https://keepachangelog.com/en/1.1.0/]] → Estándar Keep a Changelog
- [[https://www.conventionalcommits.org/en/v1.0.0/]] → Conventional Commits

---
*Documento gestionado por `semantic-release` v21.0.0 | Mantenido por `changelog-coordinator` | Constraints: C1, C4, C5*


---
