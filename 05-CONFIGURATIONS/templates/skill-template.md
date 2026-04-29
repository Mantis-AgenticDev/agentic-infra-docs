---
artifact_id: skill-template-mantis
artifact_type: skill_template
version: 2.0.0-COMPREHENSIVE
constraints_mapped: ["C1","C4","C5","C8"]
canonical_path: 05-CONFIGURATIONS/templates/skill-template.md
domain: 05-CONFIGURATIONS
subdomain: templates
agent_role: configurations-master
language_lock: es-ES
validation_command: orchestrator-engine.sh --domain configurations --strict
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants"]
human_readable: false
checksum_sha256: "488d54f0da705cb35435be721d1ebb8fdadad48821553913175aa8b6b071af2c"
---

# Skill Template: {SKILL_ID}
## 1. Metadata
| Field | Value | Constraint |
|-------|-------|------------|
| `id` | `{SKILL_ID}` | C4 |
| `domain` | `{DOMAIN}` | C4 |
| `version` | `0.1.0` | C1 |
| `created_at` | `{ISO8601_TIMESTAMP}` | C4 |
| `owner` | `{AGENT_OR_HUMAN}` | C4 |
| `validation_command` | `orchestrator-engine.sh --skill {SKILL_ID} --strict` | C5 |

## 2. Objective
{BRIEF_EXECUTABLE_DESCRIPTION. MAX 2 SENTENCES. FOCUS ON INPUT → TRANSFORMATION → OUTPUT.}

## 3. Constraints Mapping
```yaml
C1_immutable: "Base structure locked. Overrides via {DOMAIN}/overrides/ only."
C4_traceability: "All commits must reference this template ID. Changelog mandatory."
C5_validation: "Must pass orchestrator-engine.sh --strict before promotion to REAL."
C8_quality: "Includes test harness stub. Threshold ≥ 0.85 on promptfoo eval."
V1_tenant_isolation: "If applies: tenant_id injected via env. RLS policies enforced."
V3_vector_perf: "If applies: embedding_dim matches PGVECTOR_DIMENSION. HNSW enabled."
```

## 4. Dependencies & I/O Contract
```yaml
requires:
  - "{DEPENDENCY_1}"
  - "{DEPENDENCY_2}"
consumes_env:
  - "{VAR_FROM_MAPPING}"
provides_artifacts:
  - "{OUTPUT_FILE_1}"
  - "{OUTPUT_FILE_2}"
interface_alignment: "05-CONFIGURATIONS/interface-spec.yaml §3.agent_registry_mapping.{SKILL_ID}"
```

## 5. Execution Protocol
```bash
# 1. Initialize
cp 05-CONFIGURATIONS/templates/skill-template.md 02-SKILLS/{SKILL_ID}/README.md

# 2. Replace placeholders
sed -i "s/{SKILL_ID}/$SKILL_ID/g; s/{DOMAIN}/$DOMAIN/g; s/{ISO8601_TIMESTAMP}/$(date -u +%Y-%m-%dT%H:%M:%SZ)/g" 02-SKILLS/{SKILL_ID}/README.md

# 3. Validate
bash 05-CONFIGURATIONS/scripts/validate-against-specs.sh 02-SKILLS/{SKILL_ID}/ README.md --strict

# 4. Generate checksum
CHECKSUM=$(sha256sum 02-SKILLS/{SKILL_ID}/README.md | awk '{print $1}')
sed -i "s/checksum_sha256: "488d54f0da705cb35435be721d1ebb8fdadad48821553913175aa8b6b071af2c"
```

## 6. Validation Rules (Pre-Merge)
- [ ] `artifact_id` matches directory name and interface-spec registry
- [ ] `constraints_mapped` ⊆ allowed constraints for domain
- [ ] `checksum_sha256` updated post-final commit
- [ ] No hardcoded secrets, paths, or credentials (C3)
- [ ] All `consumes_env` vars exist in `mapping.yaml` (C5)
- [ ] Test harness executes within timeout (C8)

## 7. Anti-Patterns
- ❌ **NUNCA**: Modificar esta plantilla base directamente. Crear fork en `02-SKILLS/` y documentar desviación en ADR.
- ❌ **NUNCA**: Omitir `validation_command` o dejar `checksum_sha256` sin actualizar.
- ❌ **NUNCA**: Hardcodear `tenant_id`, `api_key` o rutas absolutas. Usar variables de entorno o `mapping.yaml`.
- ✅ **SIEMPRE**: Mantener estructura de secciones intacta. Overrides van en `{DOMAIN}/overrides/` o `.env.{ENV}`.
- ✅ **SIEMPRE**: Ejecutar `validate-against-specs.sh` antes de push a `main`.

## 8. Changelog
| Version | Date | Change | Author |
|---------|------|--------|--------|
| `0.1.0` | `{ISO8601_TIMESTAMP}` | Template inicial alineado a MANTIS v2.0.0 | configurations-master-agent |

---
*Template generado bajo normas C1-C8/V1-V3. Inmutable hasta aprobación humana. Checksum pendiente de generación post-deployment.*


---
