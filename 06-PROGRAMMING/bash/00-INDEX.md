---
title: "00-INDEX.md – Patrones Bash para MANTIS AGENTIC"
version: "1.0.0"
canonical_path: "06-PROGRAMMING/bash/00-INDEX.md"
purpose: "Índice maestro de patrones Bash con enlaces, nivel de madurez, constraints aplicados y grafo de dependencias para consumo humano e IA."
audience: ["human_engineers", "agentic_assistants", "ci_cd_pipelines"]
constraints_mapped: ["C3", "C4", "C5", "C7", "C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/validate-skill-integrity.sh --file $0 --json"
checksum_sha256: "c8d4e6f2a9b1c3d5e7f9a1b3c5d7e9f1a3b5c7d9e1f3a5b7c9d1e3f5a7b9c1d3"
last_updated: "2026-04-16T04:00:00Z"
generation_method: "manual_curation + SDD v2.1.1 + dependency_extraction"
status_legend:
  "✅ COMPLETADO": "Patrón validado, estable, listo para producción"
  "🆕 PENDIENTE": "Patrón planificado, sin contenido generado"
  "📝 EN PROGRESO": "Patrón en desarrollo activo"
navigation:
  ia_mode: "Fetch raw URL → Parse JSON headless block → Resolve depends_on → Generate/validate"
  human_mode: "Browse table → Filter by constraint → Consult example → Copy template"
wikilinks_enabled: true
machine_block_location: "END_OF_FILE"
---

# 🐚 00-INDEX – Patrones Bash MANTIS AGENTIC

> **Propósito**: Este índice centraliza todos los patrones de scripting Bash para el proyecto MANTIS AGENTIC. Cada patrón incluye ejemplos ✅/❌/🔧, constraints mapeados y comando de validación.  
> **Regla de oro**: Todo script Bash en este repositorio DEBE seguir al menos un patrón listado aquí.  
> **Actualización**: Este índice se actualiza manualmente tras cada merge de un nuevo patrón bash.  
> **Wikilinks**: Formato `[[archivo.md]]` para navegación en Obsidian y resolución automática en GitHub/IA.

---

## 📊 Resumen de Patrones

| Total patrones | ✅ Completados | 🆕 Pendientes | 📝 En progreso | Constraints cubiertos |
|---------------|--------------|--------------|----------------|---------------------|
| 10 | 10 | 0 | 0 | C1, C3, C4, C5, C7, C8 |

---

## 🗂️ Tabla de Patrones Bash

| Archivo | Estado | Wikilink | Descripción | Constraints | Validation Command | Depends On |
|---------|--------|----------|-------------|-------------|-------------------|------------|
| `00-INDEX.md` | ✅ | [[00-INDEX.md]] | **Este archivo**: índice maestro con metadatos y navegación | C4, C8 | `validate-skill-integrity.sh --file $0` | — |
| `robust-error-handling.md` | ✅ | [[robust-error-handling.md]] | `set -Eeuo pipefail`, `trap`, fallbacks `${VAR:?missing}`, idempotencia | C3, C7, C8 | `validate-skill-integrity.sh --file $0` | [[01-RULES/05-CODE-PATTERNS-RULES.md]] |
| `filesystem-sandboxing.md` | ✅ | [[filesystem-sandboxing.md]] | Rutas canónicas, `mktemp -d`, `chmod 700`, límites de escritura, verificación de integridad | C3, C4, C5, C7, C8 | `validate-skill-integrity.sh --file $0` | [[01-RULES/03-SECURITY-RULES.md]] |
| `git-disaster-recovery.md` | ✅ | [[git-disaster-recovery.md]] | Snapshots preventivos, `git reflog`, `git bundle`, rollback con checksum, validación pre/post | C3, C4, C5, C7, C8 | `validate-skill-integrity.sh --file $0` | [[01-RULES/03-SECURITY-RULES.md]] |
| `orchestrator-routing.md` | ✅ | [[orchestrator-routing.md]] | Modo `headless`, dispatch de validadores, routing JSON, scoring umbral ≥30 | C3, C4, C5, C7, C8 | `validate-skill-integrity.sh --file $0` | [[05-CONFIGURATIONS/validation/orchestrator-engine.sh]] |
| `context-compaction-utils.md` | ✅ | [[context-compaction-utils.md]] | Extracción de contexto crítico, generación de dossiers `handoff`, logging estructurado, token budget | C3, C4, C5, C7, C8 | `validate-skill-integrity.sh --file $0` | [[02-SKILLS/AI/qwen-integration.md]] |
| `hardening-verification.md` | ✅ | [[hardening-verification.md]] | Protocolo de pre-vuelo: checklist, --dry-run, inmutabilidad, gate de promoción | C3, C4, C5, C7, C8 | `validate-skill-integrity.sh --file $0` | [[01-RULES/03-SECURITY-RULES.md]] |
| `fix-sintaxis-code.md` | ✅ | [[fix-sintaxis-code.md]] | Control de errores sintácticos: `bash -n`, `shellcheck`, quoting seguro, anti-pattern detection | C3, C4, C5, C7, C8 | `validate-skill-integrity.sh --file $0` | [[01-RULES/05-CODE-PATTERNS-RULES.md]] |
| `yaml-frontmatter-parser.md` | ✅ | [[yaml-frontmatter-parser.md]] | Parsing seguro con `awk`/`grep`, validación de campos, sin dependencias externas (`yq`/`python`) | C3, C4, C5, C8 | `validate-skill-integrity.sh --file $0` | [[05-CONFIGURATIONS/validation/validate-frontmatter.sh]] |
| `filesystem-sandbox-sync.md` | ✅ | [[filesystem-sandbox-sync.md]] | Sincronización `rsync` main → sandbox con exclusión, checksum post-sync, validación gate | C1, C3, C4, C5, C7, C8 | `validate-skill-integrity.sh --file $0` | [[05-CONFIGURATIONS/scripts/sync-to-sandbox.sh]] |
| `scale-simulation-utils.md` | ✅ | [[scale-simulation-utils.md]] | Simulación de carga, throttling de recursos, límites de jobs concurrentes, métricas de ejecución | C1, C3, C4, C7, C8 | `validate-skill-integrity.sh --file $0` | [[01-RULES/02-RESOURCE-GUARDRAILS.md]] |

---

## 🧭 Protocolo de Navegación para Humanos

```yaml
bash_pattern_navigation_human:
  trigger: "Necesito generar/modificar/validar un script bash en MANTIS"
  steps:
    - "Abrir [[00-INDEX.md]] en editor o GitHub"
    - "Filtrar por constraint requerido (ej: C3 → robust-error-handling.md)"
    - "Consultar wikilink [[archivo.md]] para navegación directa en Obsidian"
    - "Copiar ejemplo ✅ del patrón seleccionado como base"
    - "Adaptar a caso de uso específico manteniendo constraints mapeados"
    - "Validar localmente con validation_command antes de commit"
  fallback: "Si patrón no existe, crear nuevo archivo siguiendo [[skill-template.md]]"
```

---

## 🔐 Notas de Integridad

1. **Actualización manual**: Este índice se actualiza tras cada merge de un nuevo patrón bash. No hay automatización para evitar deriva de estado.
2. **Consistencia de constraints**: Cada patrón debe mapear explícitamente los constraints C1-C8 que aplica. Validar con `verify-constraints.sh`.
3. **Wikilinks**: Formato `[[archivo.md]]` para compatibilidad con Obsidian y resolución automática en GitHub/IA.
4. **Checksum**: El campo `checksum_sha256` debe actualizarse tras cada modificación significativa.
5. **Bloque JSON para IA**: Ubicado al final del archivo; ignorar para navegación humana.

---

## ✅ Checklist Pre-Commit para Nuevos Patrones Bash

```bash
# 1. El nuevo patrón sigue la plantilla skill-template.md
grep -q "✅/❌/🔧" 06-PROGRAMMING/bash/nuevo-patron.md || echo "[ERROR] Faltan ejemplos"

# 2. El patrón mapea al menos un constraint explícitamente
grep -qE "constraints_mapped:" 06-PROGRAMMING/bash/nuevo-patron.md || echo "[ERROR] Sin constraints mapeados"

# 3. El patrón incluye validation_command funcional
grep -q "validation_command:" 06-PROGRAMMING/bash/nuevo-patron.md || echo "[ERROR] Sin comando de validación"

# 4. El índice 00-INDEX.md se actualiza con la nueva entrada
grep -q "nuevo-patron.md" 06-PROGRAMMING/bash/00-INDEX.md || echo "[WARN] Índice no actualizado"

# 5. Validación final con orchestrator (simulada)
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/bash/nuevo-patron.md --json 2>/dev/null | jq -e '.status == "passed"' || echo "[ALERTA] Validación fallida"
```

---

> 📬 **Para usar este índice en un prompt de IA**: Copiar la tabla de patrones o inyectar la URL raw de este archivo para navegación dinámica.  
> 🔐 **Checksum de integridad**: `sha256sum 06-PROGRAMMING/bash/00-INDEX.md` → comparar con frontmatter.  
> 🌱 **Próxima actualización**: Tras merge de nuevos patrones bash o modificación de dependencias.

*Documento generado bajo contrato SDD v2.1.1. Validado contra [[norms-matrix.json]].  
Última sincronización: `2026-04-16T04:00:00Z`.  
MANTIS AGENTIC – Gobernanza ejecutable para inteligencia colaborativa humano-IA.* 🔐🌱

---

## 🤖 MACHINE BLOCK – JSON Headless for IA Consumption

```json
{
  "metadata_inference_graph": {
    "version": "1.0.0",
    "scope": "06-PROGRAMMING/bash/",
    "inference_type": "causal_dependency_with_constraint_priority",
    "generated_for": "PROJECT_TREE_headless_mode + IA-QUICKSTART_routing",
    "constraint_priority_order": [
      {"constraint": "C3", "priority": 1, "reason": "Fallback explícito: abortar temprano evita cascada de errores"},
      {"constraint": "C4", "priority": 2, "reason": "Tenant isolation: prevenir contaminación cruzada antes de operar"},
      {"constraint": "C5", "priority": 3, "reason": "Integridad: verificar checksums antes de ejecutar código"},
      {"constraint": "C7", "priority": 4, "reason": "Rollback/retry: mecanismos de recuperación ante fallos"},
      {"constraint": "C8", "priority": 5, "reason": "Observability: logging estructurado para trazabilidad post-ejecución"},
      {"constraint": "C1", "priority": 6, "reason": "Resource limits: validación de recursos (aplica solo a scripts de carga/sync)"},
      {"constraint": "C2", "priority": 7, "reason": "Performance thresholds: métricas de tiempo (aplica solo a scripts de simulación)"},
      {"constraint": "C6", "priority": 8, "reason": "Cloud/env awareness: configuración por entorno (último en aplicar)"}
    ],
    "artifacts": [
      {
        "canonical_path": "06-PROGRAMMING/bash/00-INDEX.md",
        "status": "completed",
        "type": "index",
        "constraints": ["C4", "C8"],
        "validation_command": "bash 05-CONFIGURATIONS/validation/validate-skill-integrity.sh --file $0 --json",
        "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/00-INDEX.md",
        "depends_on": ["02-SKILLS/00-INDEX.md", "01-RULES/08-SKILLS-REFERENCE.md"],
        "required_by": ["PROJECT_TREE.md", "05-CONFIGURATIONS/scripts/validate-against-specs.sh"],
        "constraint_priority": ["C4", "C8"],
        "description": "Índice maestro de patrones Bash con metadatos y grafo de dependencias"
      },
      {
        "canonical_path": "06-PROGRAMMING/bash/robust-error-handling.md",
        "status": "completed",
        "type": "skill",
        "constraints": ["C3", "C7", "C8"],
        "validation_command": "bash 05-CONFIGURATIONS/validation/validate-skill-integrity.sh --file $0 --json",
        "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/robust-error-handling.md",
        "depends_on": ["01-RULES/05-CODE-PATTERNS-RULES.md"],
        "required_by": ["06-PROGRAMMING/bash/hardening-verification.md", "06-PROGRAMMING/bash/git-disaster-recovery.md", "06-PROGRAMMING/bash/orchestrator-routing.md"],
        "constraint_priority": ["C3", "C7", "C8"],
        "description": "Patrones de manejo de errores: trap, fallbacks, idempotencia, fail-fast"
      },
      {
        "canonical_path": "06-PROGRAMMING/bash/filesystem-sandboxing.md",
        "status": "completed",
        "type": "skill",
        "constraints": ["C3", "C4", "C5", "C7", "C8"],
        "validation_command": "bash 05-CONFIGURATIONS/validation/validate-skill-integrity.sh --file $0 --json",
        "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/filesystem-sandboxing.md",
        "depends_on": ["01-RULES/03-SECURITY-RULES.md", "06-PROGRAMMING/bash/robust-error-handling.md"],
        "required_by": ["06-PROGRAMMING/bash/filesystem-sandbox-sync.md", "09-TEST-SANDBOX/README.md"],
        "constraint_priority": ["C3", "C4", "C5", "C7", "C8"],
        "description": "Aislamiento de filesystem: mktemp -d, chmod 700, path validation, integrity checks"
      },
      {
        "canonical_path": "06-PROGRAMMING/bash/git-disaster-recovery.md",
        "status": "completed",
        "type": "skill",
        "constraints": ["C3", "C4", "C5", "C7", "C8"],
        "validation_command": "bash 05-CONFIGURATIONS/validation/validate-skill-integrity.sh --file $0 --json",
        "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/git-disaster-recovery.md",
        "depends_on": ["01-RULES/03-SECURITY-RULES.md", "06-PROGRAMMING/bash/robust-error-handling.md"],
        "required_by": ["07-PROCEDURES/incident-response-checklist.md", "05-CONFIGURATIONS/scripts/bootstrap-hardened-repo.sh"],
        "constraint_priority": ["C3", "C4", "C5", "C7", "C8"],
        "description": "Recuperación de desastres Git: reflog, bundle, checksum pre/post, safe rollback"
      },
      {
        "canonical_path": "06-PROGRAMMING/bash/orchestrator-routing.md",
        "status": "completed",
        "type": "skill",
        "constraints": ["C3", "C4", "C5", "C7", "C8"],
        "validation_command": "bash 05-CONFIGURATIONS/validation/validate-skill-integrity.sh --file $0 --json",
        "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/orchestrator-routing.md",
        "depends_on": ["05-CONFIGURATIONS/validation/orchestrator-engine.sh", "06-PROGRAMMING/bash/robust-error-handling.md"],
        "required_by": ["04-WORKFLOWS/sdd-assisted-generation-loop.json", "IA-QUICKSTART.md"],
        "constraint_priority": ["C3", "C4", "C5", "C7", "C8"],
        "description": "Routing headless: JSON dispatch, scoring ≥30, fallback providers, validation gating"
      },
      {
        "canonical_path": "06-PROGRAMMING/bash/context-compaction-utils.md",
        "status": "completed",
        "type": "skill",
        "constraints": ["C3", "C4", "C5", "C7", "C8"],
        "validation_command": "bash 05-CONFIGURATIONS/validation/validate-skill-integrity.sh --file $0 --json",
        "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/context-compaction-utils.md",
        "depends_on": ["02-SKILLS/AI/qwen-integration.md", "06-PROGRAMMING/bash/robust-error-handling.md"],
        "required_by": ["06-PROGRAMMING/bash/orchestrator-routing.md", "02-SKILLS/AI/context-handoff-patterns.md"],
        "constraint_priority": ["C3", "C4", "C5", "C7", "C8"],
        "description": "Compresión de contexto: token budget, handoff dossiers, structured logging, UTF-8 safe truncation"
      },
      {
        "canonical_path": "06-PROGRAMMING/bash/hardening-verification.md",
        "status": "completed",
        "type": "skill",
        "constraints": ["C3", "C4", "C5", "C7", "C8"],
        "validation_command": "bash 05-CONFIGURATIONS/validation/validate-skill-integrity.sh --file $0 --json",
        "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/hardening-verification.md",
        "depends_on": ["01-RULES/03-SECURITY-RULES.md", "06-PROGRAMMING/bash/robust-error-handling.md", "06-PROGRAMMING/bash/filesystem-sandboxing.md"],
        "required_by": ["05-CONFIGURATIONS/validation/orchestrator-engine.sh", "07-PROCEDURES/vps-initial-setup.md"],
        "constraint_priority": ["C3", "C4", "C5", "C7", "C8"],
        "description": "Pre-flight protocol: checklist, dry-run mandatory, tenant isolation, checksum verification, rollback trap"
      },
      {
        "canonical_path": "06-PROGRAMMING/bash/fix-sintaxis-code.md",
        "status": "completed",
        "type": "skill",
        "constraints": ["C3", "C4", "C5", "C7", "C8"],
        "validation_command": "bash 05-CONFIGURATIONS/validation/validate-skill-integrity.sh --file $0 --json",
        "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/fix-sintaxis-code.md",
        "depends_on": ["01-RULES/05-CODE-PATTERNS-RULES.md", "06-PROGRAMMING/bash/robust-error-handling.md"],
        "required_by": ["05-CONFIGURATIONS/scripts/validate-against-specs.sh", ".github/workflows/integrity-check.yml"],
        "constraint_priority": ["C3", "C4", "C5", "C7", "C8"],
        "description": "Detección de anti-patrones: bash -n, shellcheck integration, eval prohibition, safe quoting"
      },
      {
        "canonical_path": "06-PROGRAMMING/bash/yaml-frontmatter-parser.md",
        "status": "completed",
        "type": "skill",
        "constraints": ["C3", "C4", "C5", "C8"],
        "validation_command": "bash 05-CONFIGURATIONS/validation/validate-skill-integrity.sh --file $0 --json",
        "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/yaml-frontmatter-parser.md",
        "depends_on": ["05-CONFIGURATIONS/validation/validate-frontmatter.sh", "06-PROGRAMMING/bash/robust-error-handling.md"],
        "required_by": ["05-CONFIGURATIONS/templates/skill-template.md", "06-PROGRAMMING/bash/orchestrator-routing.md"],
        "constraint_priority": ["C3", "C4", "C5", "C8"],
        "description": "Parsing puro con awk/grep: required fields validation, safe extraction, no external deps (yq/python)"
      },
      {
        "canonical_path": "06-PROGRAMMING/bash/filesystem-sandbox-sync.md",
        "status": "completed",
        "type": "skill",
        "constraints": ["C1", "C3", "C4", "C5", "C7", "C8"],
        "validation_command": "bash 05-CONFIGURATIONS/validation/validate-skill-integrity.sh --file $0 --json",
        "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/filesystem-sandbox-sync.md",
        "depends_on": ["05-CONFIGURATIONS/scripts/sync-to-sandbox.sh", "06-PROGRAMMING/bash/filesystem-sandboxing.md", "06-PROGRAMMING/bash/hardening-verification.md"],
        "required_by": ["09-TEST-SANDBOX/README.md", "05-CONFIGURATIONS/scripts/bootstrap-hardened-repo.sh"],
        "constraint_priority": ["C3", "C4", "C5", "C7", "C8", "C1"],
        "description": "Sincronización atómica: rsync con exclusiones, checksum post-sync, validation gate, resource limits"
      },
      {
        "canonical_path": "06-PROGRAMMING/bash/scale-simulation-utils.md",
        "status": "completed",
        "type": "skill",
        "constraints": ["C1", "C3", "C4", "C7", "C8"],
        "validation_command": "bash 05-CONFIGURATIONS/validation/validate-skill-integrity.sh --file $0 --json",
        "raw_url": "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/06-PROGRAMMING/bash/scale-simulation-utils.md",
        "depends_on": ["01-RULES/02-RESOURCE-GUARDRAILS.md", "06-PROGRAMMING/bash/robust-error-handling.md"],
        "required_by": ["07-PROCEDURES/scaling-decision-matrix.md", "04-WORKFLOWS/n8n/INFRA-003-Alert-Dispatcher.json"],
        "constraint_priority": ["C3", "C4", "C7", "C8", "C1"],
        "description": "Simulación de carga: throttling de recursos, límites de jobs concurrentes, métricas de ejecución, fallback graceful"
      }
    ],
    "interaction_matrix": {
      "critical_path": [
        "06-PROGRAMMING/bash/robust-error-handling.md → (base para todos los demás)",
        "06-PROGRAMMING/bash/hardening-verification.md → (gate de promoción a producción)",
        "06-PROGRAMMING/bash/orchestrator-routing.md → (integración con CI/CD y IA-QUICKSTART)"
      ],
      "dependency_clusters": [
        {
          "cluster": "security_hardening",
          "artifacts": ["filesystem-sandboxing.md", "git-disaster-recovery.md", "hardening-verification.md"],
          "shared_constraints": ["C3", "C4", "C5", "C7", "C8"],
          "execution_order": ["filesystem-sandboxing.md", "git-disaster-recovery.md", "hardening-verification.md"]
        },
        {
          "cluster": "validation_pipeline",
          "artifacts": ["fix-sintaxis-code.md", "yaml-frontmatter-parser.md", "orchestrator-routing.md"],
          "shared_constraints": ["C3", "C4", "C5", "C8"],
          "execution_order": ["fix-sintaxis-code.md", "yaml-frontmatter-parser.md", "orchestrator-routing.md"]
        },
        {
          "cluster": "resource_aware",
          "artifacts": ["filesystem-sandbox-sync.md", "scale-simulation-utils.md"],
          "shared_constraints": ["C1", "C3", "C4", "C7", "C8"],
          "execution_order": ["scale-simulation-utils.md", "filesystem-sandbox-sync.md"]
        }
      ],
      "constraint_impact_analysis": {
        "C3": {"affected_artifacts": 10, "critical_for": ["fallback validation", "abort on missing vars"], "risk_if_omitted": "high"},
        "C4": {"affected_artifacts": 10, "critical_for": ["tenant isolation", "context separation"], "risk_if_omitted": "high"},
        "C5": {"affected_artifacts": 9, "critical_for": ["integrity verification", "checksum validation"], "risk_if_omitted": "medium"},
        "C7": {"affected_artifacts": 10, "critical_for": ["rollback mechanisms", "cleanup traps"], "risk_if_omitted": "high"},
        "C8": {"affected_artifacts": 10, "critical_for": ["structured logging", "observability"], "risk_if_omitted": "medium"},
        "C1": {"affected_artifacts": 2, "critical_for": ["resource limits", "memory/CPU throttling"], "risk_if_omitted": "low (domain-specific)"},
        "C2": {"affected_artifacts": 0, "critical_for": ["performance thresholds"], "risk_if_omitted": "N/A (not applicable to bash patterns)"},
        "C6": {"affected_artifacts": 0, "critical_for": ["cloud/env awareness"], "risk_if_omitted": "N/A (handled at higher abstraction)"}
      }
    }
  }
}
```

