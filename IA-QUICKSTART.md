---
title: "IA QuickStart – Universal Seed Prompt for Agentic Workflows"
version: "3.1.0"
canonical_path: "IA-QUICKSTART.md"
ai_optimized: true
purpose: "Documento semilla universal que instruye a cualquier IA (DeepSeek, Qwen, MiniMax, GPT, Claude, Gemini) sobre cómo navegar, validar y generar artefactos en el ecosistema MANTIS AGENTIC, cubriendo desarrollo interno y producción externa con tres niveles de autonomía."
audience: ["human_engineers", "agentic_assistants", "ci_cd_pipelines", "client_teams"]
language_policy: "Prompts lógicos en inglés para precisión técnica; contenido de artefactos en español/portugués según audiencia."
constraints_mapped: ["C3","C4","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --mode headless --file IA-QUICKSTART.md --json"
related_files:
  - "PROJECT_TREE.md"
  - "AI-NAVIGATION-CONTRACT.md"
  - "SDD-COLLABORATIVE-GENERATION.md"
  - "GOVERNANCE-ORCHESTRATOR.md"
  - "knowledge-graph.json"
  - "README.md"
  - "RAW_URLS_INDEX.md"
  - "TOOLCHAIN-REFERENCE.md"
  - "05-CONFIGURATIONS/templates/skill-template.md"
---

# 🤖 IA-QUICKSTART.md
---

## 🎯 Propósito y Alcance

Este documento es el **punto de entrada canónico** para cualquier agente de IA que interactúe con el repositorio `agentic-infra-docs`. Su función es triple:

1.  **Bootstrapping**: Instruir a la IA sobre cómo cargar contexto, navegar el árbol de archivos y aplicar el contrato SDD.
2.  **Enrutamiento**: Clasificar la solicitud del usuario en uno de los 6 modos operativos (Interno/Externo × Asistido/Auto-generación/Auto-deploy).
3.  **Ejecución**: Proveer prompts específicos, validaciones y guardrails para cada escenario, garantizando coherencia arquitectónica.

> 🔐 **Regla de Oro para IA**: Si una ruta, constraint o patrón no está documentado en los archivos canónicos listados abajo, **NO EXISTE**. No inventes, no asumas, no extrapoles. Pregunta al usuario o detén la ejecución.

---

## 📚 Carga de Contexto Canónico (OBLIGATORIO)

**Antes de ejecutar cualquier tarea, DEBES leer y memorizar los siguientes archivos en este orden EXACTO.** Usa las URLs raw para acceso directo desde cualquier entorno.

| Orden | Archivo | Propósito Clave | URL Raw |
|-------|---------|----------------|---------|
| 1 | `PROJECT_TREE.md` | Mapa canónico de rutas. Si no está aquí, no existe. | https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/PROJECT_TREE.md |
| 2 | `AI-NAVIGATION-CONTRACT.md` | Contrato de interacción: cómo preguntar, cómo confirmar, cómo reportar. | https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/AI-NAVIGATION-CONTRACT.md |
| 3 | `SDD-COLLABORATIVE-GENERATION.md` | Especificación de artefactos: frontmatter, ejemplos, constraints, validation_command. | https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/SDD-COLLABORATIVE-GENERATION.md |
| 4 | `GOVERNANCE-ORCHESTRATOR.md` | Motor de validación: scoring, tiering, blocking_issues, next_step. | https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/GOVERNANCE-ORCHESTRATOR.md |
| 5 | `knowledge-graph.json` | Grafo de dependencias entre skills, configs y agentes. | https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/knowledge-graph.json |
| 6 | `README.md` | Visión general, quickstart humano, enlaces a documentación. | https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/README.md |
| 7 | `TOOLCHAIN-REFERENCE.md` | Comandos exactos para validadores y scripts operativos. | https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/TOOLCHAIN-REFERENCE.md |
| 8 | `RAW_URLS_INDEX.md` | Índice actualizado de URLs raw para todos los documentos. | https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/RAW_URLS_INDEX.md |
| 9 | `05-CONFIGURATIONS/templates/skill-template.md` | Plantilla base para generar nuevos skills. | https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/templates/skill-template.md |

**Instrucción de memoria para IA**:
```text
[SYSTEM] After loading the above files, store in working memory:
- The canonical path resolution logic from PROJECT_TREE.md
- The SDD frontmatter schema and required fields
- The constraint definitions C1-C8 and their validation patterns
- The tier certification criteria (1=review, 2=auto-merge, 3=auto-deploy)
- The output format expectations for each mode (code block, JSON payload, ZIP manifest)
```

---

## 🧭 Matriz de Modos Operativos

Identifica el **contexto** y el **nivel de autonomía** solicitado. Luego, ejecuta **EXACTAMENTE** el prompt correspondiente.

```mermaid
graph TD
    A[Solicitud del Usuario] --> B{¿Contexto?}
    B -->|Interno| C[Desarrollo del repositorio agentic-infra-docs]
    B -->|Externo| D[Generación para cliente/producción SaaS]
    
    C --> E{¿Nivel de Autonomía?}
    D --> F{¿Nivel de Autonomía?}
    
    E -->|Asistido| G[1A: IA Asistida - Tier 1]
    E -->|Auto-generación| H[1B: Auto-generación con entrega - Tier 2]
    E -->|Auto-deploy| I[1C: Auto-deploy con ZIP - Tier 3]
    
    F -->|Asistido| J[2A: IA Asistida Cliente - Tier 1]
    F -->|Auto-generación| K[2B: Auto-generación Cliente - Tier 2]
    F -->|Auto-deploy| L[2C: Auto-deploy Cliente - Tier 3]
```

---

## 🔵 CONTEXTO 1: INTERNO (Desarrollo del repositorio `agentic-infra-docs`)

### 📋 1A. IA Asistida (Tier 1 – Revisión Humana)

**Objetivo**: Generar un artefacto estructurado para revisión humana, sin validación automática.

**Prompt específico para la IA**:
```text
[MODE: INTERNAL_ASSISTED_TIER1]
You are generating a new artifact for the agentic-infra-docs repository.

STEP 1 – PATH RESOLUTION:
- Ask the user for the functional domain (e.g., "database-rag", "infra-monitoring", "ai-provider-integration").
- Use PROJECT_TREE.md to resolve the canonical destination folder.
- If the folder does not exist in PROJECT_TREE.md, STOP and ask the user to define it first.

STEP 2 – TEMPLATE APPLICATION:
- Load 05-CONFIGURATIONS/templates/skill-template.md.
- Fill the frontmatter with:
  * canonical_path: "<resolved_path>/<filename>.md"
  * ai_optimized: true
  * constraints_mapped: [list of C1-C8 that apply]
  * validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --mode headless --file <canonical_path> --json"
  * related_files: [list of canonical paths this skill depends on]

STEP 3 – CONTENT GENERATION:
- Write the body following SDD-COLLABORATIVE-GENERATION.md structure:
  * ## 🎯 Purpose (1-2 sentences)
  * ## 🏗️ Architecture (diagram or bullet list)
  * ## 🔧 Implementation Steps (numbered, with code blocks)
  * ## ✅ Examples (minimum 5, with ✅/❌/🔧 format)
  * ## 🔍 Human Review Checklist (bullet list of items to validate)
- Apply constraints C1-C8 where relevant (e.g., use ${VAR:?missing} for C3, include tenant_id filters for C4).

STEP 4 – OUTPUT:
- Deliver the artifact as a Markdown code block.
- Do NOT execute validation commands.
- Append a final note: "⚠️ Requires human review before merge. Run validation_command to certify."

[END MODE]
```

**Formato de entrega**:
````markdown
```markdown
[Contenido del artefacto con frontmatter YAML]
```
⚠️ Requires human review before merge. Run validation_command to certify.
````

---

### 📋 1B. Auto-generación con Entrega (Tier 2 – Merge Automático)

**Objetivo**: Generar un artefacto que pase validación automática (`tier_certified: 2`) y esté listo para merge sin intervención humana.

**Prompt específico para la IA**:
```text
[MODE: INTERNAL_AUTOGEN_TIER2]
You are generating a production-ready artifact for auto-merge in agentic-infra-docs.

STEP 1 – PATH & TEMPLATE (same as Tier 1):
- Resolve canonical path via PROJECT_TREE.md.
- Apply skill-template.md with complete frontmatter.

STEP 2 – ZERO-PLACEHOLDER POLICY:
- Eliminate ALL TODO, FIXME, ${VAR} without default values.
- For variables, use ${VAR:?missing} pattern (C3 compliance).
- For secrets, reference environment variables or secret managers ONLY.

STEP 3 – CONSTRAINT ENFORCEMENT:
- C1: Include resource limits (mem_limit, timeout, concurrency) or document exemption.
- C2: Add CPU isolation patterns (cpus:, nice, rate_limit) or document exemption.
- C3: Use ${VAR:?missing} for all sensitive values; NO hardcoded secrets.
- C4: Include tenant_id filters in queries, labels, or environment; document global exceptions.
- C5: Add checksum/audit patterns (sha256sum, age -r, backup verification).
- C6: Use cloud endpoints (openrouter.ai, api.openai.com) or document local inference exception.
- C7: Include retry/backoff/healthcheck patterns for resilience.
- C8: Add observability hooks (logging, metrics, tracing) where applicable.

STEP 4 – EXAMPLES & VALIDATION:
- Include ≥10 examples with ✅/❌/🔧 format.
- Ensure all wikilinks [[...]] resolve to canonical paths in PROJECT_TREE.md.
- Add a working validation_command that returns exit 0 when run.

STEP 5 – AUTO-VALIDATION LOOP:
- Construct a JSON payload for the orchestrator:
  {
    "file_path": "<canonical_path>",
    "file_type": "markdown",
    "target_folder": "<folder>",
    "function": "<function_type>",
    "constraints_declared": ["C1","C3","C4",...],
    "examples_count": <number>,
    "wikilinks_resolved": true
  }
- Simulate execution of:
  bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --mode headless --file <canonical_path> --json
- If output contains blocking_issues OR score < 30:
  * Analyze the failure reason.
  * Correct the artifact.
  * Repeat validation (max 3 iterations).
- If output contains tier_certified: 2 (or higher):
  * Proceed to delivery.

STEP 6 – OUTPUT:
- Deliver the final artifact as a Markdown code block.
- Append the validation JSON report as a separate code block.
- Include a merge instruction: "✅ Certified for auto-merge. Run: git add <path> && git commit -m 'feat: <description>'".

[END MODE]
```

**Formato de entrega**:
````markdown
```markdown
[Contenido final del artefacto]
```

```json
{
  "orchestrator_version": "1.1.0",
  "status": "passed",
  "tier_certified": 2,
  "score": 45,
  "blocking_issues": [],
  "next_step": "auto_merge_approved"
}
```

✅ Certified for auto-merge. Run: git add <path> && git commit -m 'feat: <description>'
````

---

### 📋 1C. Auto-Deploy con ZIP (Tier 3 – Despliegue Autónomo)

**Objetivo**: Generar un artefacto empaquetado, firmado y listo para despliegue autónomo en infraestructura objetivo.

**Prompt específico para la IA**:
```text
[MODE: INTERNAL_AUTODEPLOY_TIER3]
You are generating a deploy-ready package for autonomous execution in target infrastructure.

STEP 1 – TIER 2 COMPLIANCE:
- Fulfill ALL requirements from mode 1B first.

STEP 2 – PRODUCTION HARDENING:
- Add explicit idempotency guarantees: "Same input → same output, no side effects on re-run".
- Include healthcheck endpoint/command: "curl -f http://<service>/health || exit 1".
- Document rollback procedure: "To rollback: <command_or_steps>".
- Ensure namespace isolation: prefix resources with mantis-<env>-<tenant>- pattern.

STEP 3 – MULTI-TENANT SAFEGUARDS:
- For database queries: ALWAYS include WHERE tenant_id = ? or RLS policy.
- For API calls: ALWAYS include X-Tenant-ID header or context propagation.
- For file paths: ALWAYS use tenant-scoped directories (/data/<tenant_id>/...).

STEP 4 – PACKAGING PREPARATION:
- Generate a manifest.json with:
  {
    "artifact_name": "<filename>",
    "version": "<semver>",
    "sha256": "<checksum_of_artifact>",
    "dependencies": ["list_of_canonical_paths"],
    "deployment_target": ["vps1", "vps2", "k8s", ...],
    "healthcheck_command": "<command>",
    "rollback_command": "<command>"
  }
- Simulate packaging command:
  bash 05-CONFIGURATIONS/scripts/packager-assisted.sh --input <artifact> --output <artifact>.zip

STEP 5 – FINAL VALIDATION:
- Run orchestrator validation expecting tier_certified: 3.
- If validation fails, iterate correction (max 3 attempts).
- If validation passes, proceed to delivery.

STEP 6 – OUTPUT:
- Deliver a ZIP manifest as a JSON code block (simulated, since actual ZIP generation requires filesystem access).
- Include deployment instructions:
  ```bash
  # Deploy
  unzip <artifact>.zip -d /opt/mantis/<tenant_id>/
  cd /opt/mantis/<tenant_id>/
  ./healthcheck.sh && ./deploy.sh
  
  # Rollback (if needed)
  ./rollback.sh
  ```
- Append certification note: "✅ Tier 3 certified. Ready for autonomous deployment."

[END MODE]
```

**Formato de entrega**:
````json
{
  "package_name": "qdrant-cluster-v1.2.0.zip",
  "sha256": "a1b2c3d4...",
  "manifest": {
    "artifact_name": "qdrant-cluster/variables.tf",
    "version": "1.2.0",
    "dependencies": ["05-CONFIGURATIONS/terraform/backend.tf", ...],
    "healthcheck": "terraform validate && curl -f http://qdrant:6333/ready",
    "rollback": "terraform destroy -auto-approve && terraform apply -auto-approve"
  },
  "deployment_instructions": "unzip qdrant-cluster-v1.2.0.zip -d /opt/mantis/ && cd /opt/mantis/ && ./deploy.sh"
}
```
✅ Tier 3 certified. Ready for autonomous deployment.
````

---

## 🔴 CONTEXTO 2: EXTERNO (Generación para clientes / producción SaaS)

### 📋 2A. IA Asistida Cliente (Tier 1 – Personalización Humana)

**Objetivo**: Generar un artefacto base con placeholders seguros para que el equipo del cliente lo revise y complete.

**Prompt específico para la IA**:
```text
[MODE: EXTERNAL_ASSISTED_TIER1]
You are generating a client-ready artifact template for customization by the client's team.

STEP 1 – CLIENT CONTEXT:
- Ask the user for:
  * client_name: "Acme Corp"
  * tenant_id: "acme-prod-01"
  * functional_domain: "database-rag", "ai-routing", etc.
- Use PROJECT_TREE.md to map to equivalent client folder structure (e.g., clients/acme-prod-01/02-SKILLS/...).

STEP 2 – TEMPLATE WITH PLACEHOLDERS:
- Load skill-template.md and adapt with client-specific placeholders:
  * {{CLIENT_NAME}} → "Acme Corp"
  * {{TENANT_ID}} → "acme-prod-01"
  * {{DB_ENDPOINT}} → "postgres://{{DB_USER}}:{{DB_PASS}}@{{DB_HOST}}:5432/{{DB_NAME}}"
  * {{AI_PROVIDER_ENDPOINT}} → "https://{{AI_PROVIDER}}.api.example.com/v1"
- Ensure placeholders follow C3: use {{VAR}} syntax (not ${VAR}) to avoid shell expansion.

STEP 3 – FRONTMATTER & CONSTRAINTS:
- Fill frontmatter with:
  * canonical_path: "clients/{{TENANT_ID}}/02-SKILLS/<domain>/<filename>.md"
  * ai_optimized: true
  * constraints_mapped: [list of C1-C8 that apply]
  * validation_command: "bash clients/{{TENANT_ID}}/05-CONFIGURATIONS/validation/orchestrator-engine.sh --mode headless --file <canonical_path> --json"
- Document constraint exemptions if needed (e.g., "C6: local inference allowed per client agreement").

STEP 4 – EXAMPLES WITH FICTIONAL DATA:
- Include ≥5 examples using realistic but fictional data:
  * ✅ "Query with tenant_id='acme-prod-01' returns 200 OK"
  * ❌ "Query without tenant_id returns 403 Forbidden"
  * 🔧 "Add WHERE tenant_id=? to fix isolation breach"
- Use {{VAR}} placeholders in code blocks, never real credentials.

STEP 5 – CLIENT INSTRUCTIONS:
- Append a section:
  ```markdown
  ## 📋 Instrucciones para el Cliente
  
  1. Reemplazar todos los {{PLACEHOLDERS}} con valores reales de su entorno.
  2. Ejecutar el validation_command en su entorno para certificar el artefacto.
  3. Para secrets, usar su secret manager (Vault, AWS Secrets, etc.) y NO hardcodear.
  4. Para multi-tenant, asegurar que tenant_id se propaga en todas las capas.
  ```

STEP 6 – OUTPUT:
- Deliver the artifact as a Markdown code block with placeholders intact.
- Do NOT execute validation (client will do it in their environment).
- Append note: "⚠️ Requires client customization and validation before deployment."

[END MODE]
```

**Formato de entrega**:
````markdown
```markdown
---
canonical_path: "clients/{{TENANT_ID}}/02-SKILLS/database-rag/rag-ingestion.md"
ai_optimized: true
constraints_mapped: ["C3","C4","C5"]
validation_command: "bash clients/{{TENANT_ID}}/05-CONFIGURATIONS/validation/orchestrator-engine.sh --mode headless --file clients/{{TENANT_ID}}/02-SKILLS/database-rag/rag-ingestion.md --json"
---

# RAG Ingestion Pipeline for {{CLIENT_NAME}}

## 🔧 Implementation
```bash
export DB_URL="postgres://{{DB_USER}}:{{DB_PASS}}@{{DB_HOST}}:5432/{{DB_NAME}}"
```

## ✅ Examples
✅ Query with tenant_id='{{TENANT_ID}}' returns 200 OK
❌ Query without tenant_id returns 403 Forbidden
🔧 Add WHERE tenant_id=? to fix isolation breach

## 📋 Instrucciones para el Cliente
1. Reemplazar todos los {{PLACEHOLDERS}} con valores reales...
```
⚠️ Requires client customization and validation before deployment.
````

---

### 📋 2B. Auto-generación Cliente (Tier 2 – Integración Directa)

**Objetivo**: Entregar un artefacto completamente funcional que el cliente pueda integrar directamente en su CI/CD, sin placeholders.

**Prompt específico para la IA**:
```text
[MODE: EXTERNAL_AUTOGEN_TIER2]
You are generating a production-ready artifact for direct client integration.

STEP 1 – CLIENT VALUES COLLECTION:
- Obtain from user:
  * tenant_id: "acme-prod-01"
  * db_endpoint: "postgres://user:pass@host:5432/db"
  * ai_provider_endpoint: "https://api.openrouter.ai/v1"
  * resource_limits: { memory: "512Mi", cpu: "0.5", timeout: "30s" }
  * any other environment-specific values

STEP 2 – ZERO-PLACEHOLDER GENERATION:
- Generate the artifact with ALL values resolved (no {{VAR}} or ${VAR} left).
- Apply C3 compliance: use environment variable references for secrets ONLY:
  * DB_URL: "${DB_URL:?missing}" (not hardcoded credentials)
  * API_KEY: "${OPENROUTER_KEY:?missing}"
- For non-sensitive config, use resolved values directly.

STEP 3 – CONSTRAINT ENFORCEMENT (CLIENT CONTEXT):
- C1: Include client-specific resource limits in config.
- C2: Add CPU isolation patterns appropriate for client's infra (K8s limits, Docker cpus, etc.).
- C3: Zero hardcoded secrets; all sensitive values via env vars or secret manager references.
- C4: Ensure tenant_id is enforced in ALL queries, headers, and file paths.
- C5: Include checksum/audit commands client can run in their environment.
- C6: Use client-approved AI endpoints (cloud or local per agreement).
- C7: Add retry/backoff patterns compatible with client's monitoring stack.
- C8: Include logging/metrics hooks that integrate with client's observability.

STEP 4 – CLIENT VALIDATION COMMAND:
- Provide the exact command the client must run to validate:
  ```bash
  bash clients/{{TENANT_ID}}/05-CONFIGURATIONS/validation/orchestrator-engine.sh \
    --mode headless \
    --file clients/{{TENANT_ID}}/02-SKILLS/<domain>/<filename>.md \
    --json
  ```
- Document expected output: "Look for tier_certified: 2 and status: passed".

STEP 5 – SIMULATED AUTO-VALIDATION:
- Construct orchestrator payload with client values.
- Simulate validation expecting tier_certified: 2.
- If validation would fail, correct and retry (max 3 iterations).

STEP 6 – CI/CD INTEGRATION INSTRUCTIONS:
- Append a section:
  ```markdown
  ## 🚀 Integración en CI/CD del Cliente
  
  ### GitHub Actions Example
  ```yaml
  - name: Validate SDD Artifact
    run: |
      bash clients/acme-prod-01/05-CONFIGURATIONS/validation/orchestrator-engine.sh \
        --mode headless \
        --file clients/acme-prod-01/02-SKILLS/database-rag/rag-ingestion.md \
        --json > report.json
      jq -e '.status == "passed" and .tier_certified >= 2' report.json
  ```
  
  ### GitLab CI Example
  ```yaml
  validate_sdd:
    script:
      - bash clients/acme-prod-01/05-CONFIGURATIONS/validation/orchestrator-engine.sh --json > report.json
      - 'jq -e '"'"'.status == "passed" and .tier_certified >= 2'"'"' report.json'
  ```
  ```

STEP 7 – OUTPUT:
- Deliver the final artifact as a Markdown code block (all values resolved).
- Append the simulated validation JSON report.
- Include CI/CD integration instructions.
- Append certification note: "✅ Certified for client integration. Run validation_command in your environment to confirm."

[END MODE]
```

**Formato de entrega**:
````markdown
```markdown
---
canonical_path: "clients/acme-prod-01/02-SKILLS/database-rag/rag-ingestion.md"
ai_optimized: true
constraints_mapped: ["C1","C3","C4","C5","C6"]
validation_command: "bash clients/acme-prod-01/05-CONFIGURATIONS/validation/orchestrator-engine.sh --mode headless --file clients/acme-prod-01/02-SKILLS/database-rag/rag-ingestion.md --json"
---

# RAG Ingestion Pipeline for Acme Corp

## 🔧 Implementation
```bash
export DB_URL="${DB_URL:?missing}"
export OPENROUTER_KEY="${OPENROUTER_KEY:?missing}"
```

## ✅ Examples
✅ Query with tenant_id='acme-prod-01' returns 200 OK
❌ Query without tenant_id returns 403 Forbidden
🔧 Add WHERE tenant_id=? to fix isolation breach
```

```json
{
  "orchestrator_version": "1.1.0",
  "status": "passed",
  "tier_certified": 2,
  "score": 42,
  "blocking_issues": [],
  "next_step": "client_integration_approved"
}
```

## 🚀 Integración en CI/CD del Cliente
[GitHub Actions / GitLab CI examples]

✅ Certified for client integration. Run validation_command in your environment to confirm.
````

---

### 📋 2C. Auto-Deploy Cliente (Tier 3 – Paquete Desplegable)

**Objetivo**: Proporcionar un paquete ZIP firmado que el cliente pueda desplegar en su infraestructura sin modificaciones.

**Prompt específico para la IA**:
```text
[MODE: EXTERNAL_AUTODEPLOY_TIER3]
You are generating a client-deployable package for autonomous execution in client infrastructure.

STEP 1 – TIER 2 COMPLIANCE:
- Fulfill ALL requirements from mode 2B first.

STEP 2 – CLIENT INFRASTRUCTURE ADAPTATION:
- Ask for client's deployment target: [k8s, docker-compose, terraform, bare-metal].
- Adapt artifact format accordingly:
  * k8s: Generate Deployment, Service, ConfigMap YAMLs with tenant labels.
  * docker-compose: Generate docker-compose.yml with env_file references.
  * terraform: Generate module with variables.tf, outputs.tf, and backend config.
  * bare-metal: Generate systemd unit + config file + deploy script.

STEP 3 – MULTI-TENANT HARDENING:
- Ensure ALL resources are tenant-scoped:
  * Database: WHERE tenant_id = ? or RLS policy per tenant.
  * Storage: /data/<tenant_id>/... paths.
  * Networking: X-Tenant-ID header propagation.
  * Logging: tenant_id in every log entry.
- Document tenant isolation guarantees in README.

STEP 4 – PRODUCTION OPERATIONS:
- Include healthcheck endpoint/command compatible with client's monitoring.
- Document rollback procedure with exact commands.
- Add idempotency guarantee: "Re-running deploy.sh has no side effects".
- Include resource limits appropriate for client's infra (C1/C2 compliance).

STEP 5 – PACKAGING & SIGNING:
- Generate manifest.json with:
  {
    "client_name": "Acme Corp",
    "tenant_id": "acme-prod-01",
    "artifact_version": "1.2.0",
    "deployment_target": "k8s",
    "sha256_artifact": "<checksum>",
    "sha256_manifest": "<checksum>",
    "dependencies": ["list_of_canonical_paths"],
    "healthcheck": "<command>",
    "rollback": "<command>",
    "multi_tenant_guarantees": ["tenant_id_in_queries", "namespace_isolation", ...]
  }
- Simulate packaging:
  bash 05-CONFIGURATIONS/scripts/packager-assisted.sh \
    --input clients/acme-prod-01/02-SKILLS/database-rag/rag-ingestion.md \
    --output acme-rag-ingestion-v1.2.0.zip

STEP 6 – FINAL VALIDATION:
- Run orchestrator validation expecting tier_certified: 3.
- If validation fails, iterate correction (max 3 attempts).
- If validation passes, proceed to delivery.

STEP 7 – CLIENT DEPLOYMENT GUIDE:
- Append a comprehensive README-DEPLOY.md section:
  ```markdown
  # 🚀 Guía de Despliegue para {{CLIENT_NAME}}
  
  ## Requisitos Previos
  - Kubernetes 1.24+ / Docker 24+ / Terraform 1.5+
  - Access to secret manager (Vault/AWS Secrets/...)
  - Network policies allowing tenant isolation
  
  ## Despliegue
  ```bash
  # 1. Extraer paquete
  unzip acme-rag-ingestion-v1.2.0.zip -d /opt/mantis/acme-prod-01/
  cd /opt/mantis/acme-prod-01/
  
  # 2. Configurar secrets (ejemplo para Vault)
  export DB_URL=$(vault kv get -field=url secret/acme-prod-01/db)
  export OPENROUTER_KEY=$(vault kv get -field=key secret/acme-prod-01/ai)
  
  # 3. Desplegar
  ./deploy.sh
  
  # 4. Verificar
  ./healthcheck.sh
  ```
  
  ## Rollback
  ```bash
  ./rollback.sh
  ```
  
  ## Soporte
  - Documentación: https://docs.mantis.agentic.dev
  - Issue tracker: https://github.com/Mantis-AgenticDev/agentic-infra-docs/issues
  ```

STEP 8 – OUTPUT:
- Deliver a ZIP manifest as a JSON code block (simulated).
- Include the full README-DEPLOY.md content.
- Append certification note: "✅ Tier 3 certified. Ready for client autonomous deployment."

[END MODE]
```

**Formato de entrega**:
````json
{
  "package_name": "acme-rag-ingestion-v1.2.0.zip",
  "client": "Acme Corp",
  "tenant_id": "acme-prod-01",
  "sha256_artifact": "a1b2c3d4...",
  "sha256_manifest": "e5f6g7h8...",
  "deployment_target": "k8s",
  "manifest": {
    "artifact_version": "1.2.0",
    "dependencies": ["05-CONFIGURATIONS/terraform/backend.tf", ...],
    "healthcheck": "kubectl exec -n acme-prod-01 rag-pod -- curl -f http://localhost:8080/health",
    "rollback": "kubectl rollout undo deployment/rag-pod -n acme-prod-01",
    "multi_tenant_guarantees": ["tenant_id_in_queries", "namespace_isolation", "header_propagation"]
  },
  "deployment_guide": "See README-DEPLOY.md section below"
}
```

```markdown
# 🚀 Guía de Despliegue para Acme Corp
[Contenido completo de README-DEPLOY.md]
```

✅ Tier 3 certified. Ready for client autonomous deployment.
````

---

## 🌐 Guía de Idioma para Modelos Orientales

Para maximizar la precisión en tareas técnicas y de código:

| Modelo | Recomendación de Idioma | Notas |
|--------|-------------------------|-------|
| **DeepSeek** | Inglés para prompts lógicos; contenido en español/portugués | Mejor rendimiento en inglés para JSON Schema, HCL, YAML. |
| **Qwen** | Inglés para lógica; contenido bilingüe aceptable | Soporte sólido en español, pero validar formatos estrictos. |
| **MiniMax** | Inglés para instrucciones; contenido localizado | Priorizar inglés en prompts de sistema para consistencia. |
| **GPT-4/Claude/Gemini** | Flexible; usar idioma del usuario | Excelente soporte multilingüe; validar output con orchestrator. |

**Regla práctica**:
```text
[SYSTEM PROMPT LANGUAGE]
- Use English for: logical instructions, JSON schemas, code generation, validation commands.
- Use Spanish/Portuguese for: user-facing content, comments, examples, documentation body.
- Never mix languages within the same logical block (e.g., don't write English comments in Spanish code).
```

---

## 🔄 Flujo de Trabajo Estándar para IA

```mermaid
sequenceDiagram
    participant U as Usuario/Humano
    participant IA as Agente IA
    participant V as Validadores
    participant R as Repositorio
    
    U->>IA: Solicitud de artefacto + contexto (Interno/Externo, Tier)
    IA->>IA: Cargar archivos canónicos (PROJECT_TREE, SDD, etc.)
    IA->>IA: Clasificar modo (1A/1B/1C/2A/2B/2C)
    IA->>IA: Ejecutar prompt específico del modo
    IA->>V: (Opcional) Simular validación con orchestrator-engine.sh
    alt Validación falla
        V->>IA: blocking_issues o score insuficiente
        IA->>IA: Corregir artefacto (máx. 3 intentos)
        IA->>V: Re-validar
    else Validación pasa
        V->>IA: tier_certified: N, status: passed
        IA->>R: Entregar artefacto + reporte JSON
    end
    IA->>U: Confirmación + instrucciones de siguiente paso
```

---

## 🛡️ Guardrails Críticos para IA

1.  **Nunca modificar archivos existentes**: Todos los validadores son `READ-ONLY`. Si necesitas contexto, lee en memoria; nunca escribas sobre fuentes.
2.  **Resolución de rutas canónicas**: Usa `PROJECT_TREE.md` como única fuente de verdad. Si una ruta no está allí, no existe.
3.  **Cero placeholders en Tier 2/3**: Elimina `TODO`, `FIXME`, `{{VAR}}`, `${VAR}` sin valor por defecto antes de entregar.
4.  **Validación antes de entrega**: Siempre simula o ejecuta `orchestrator-engine.sh --json` y verifica `tier_certified` y `blocking_issues`.
5.  **Manejo de secretos**: Nunca hardcodees credenciales. Usa `${VAR:?missing}` para interno, `{{VAR}}` para externo, o referencias a secret managers.
6.  **Aislamiento multi-tenant**: Incluye `tenant_id` en queries, headers, paths y logs. Documenta excepciones explícitamente.
7.  **Idempotencia y rollback**: En Tier 3, garantiza que re-ejecutar el deploy no tenga side effects y documenta el procedimiento de rollback.

---

## 📞 Instrucción Final para la IA

**Una vez leído este documento, responde ÚNICAMENTE con:**
```
QUICKSTART v3.1 RECIBIDO. Contexto: [INTERNO/EXTERNO]. Modo: [ASISTIDO/AUTOGEN/DEPLOY]. Esperando solicitud de artefacto.
```

*A partir de ese momento, espera el prompt del usuario con la solicitud concreta. No generes contenido hasta recibir la instrucción específica del artefacto a crear.*

## Inferencia con Metadatos para IA
```json
{
  "metadata_inference_graph": {
    "version": "2.1.0",
    "scope": ["ROOT", "00-CONTEXT", "01-RULES", "02-SKILLS", "05-CONFIGURATIONS"],
    "inference_type": "causal_dependency",
    "generated_for": "PROJECT_TREE.md_headless_mode + IA-QUICKSTART.md_routing",
    "artifacts": [
      {"canonical_path": "IA-QUICKSTART.md", "depends_on": [], "required_by": ["PROJECT_TREE.md", "AI-NAVIGATION-CONTRACT.md", "GOVERNANCE-ORCHESTRATOR.md", "05-CONFIGURATIONS/validation/orchestrator-engine.sh"], "constraints": ["C3", "C4", "C5"]},
      {"canonical_path": "README.md", "depends_on": ["IA-QUICKSTART.md"], "required_by": [], "constraints": ["C3", "C8"]},
      {"canonical_path": "PROJECT_TREE.md", "depends_on": ["IA-QUICKSTART.md", "05-CONFIGURATIONS/validation/norms-matrix.json"], "required_by": ["05-CONFIGURATIONS/scripts/validate-against-specs.sh", ".github/workflows/integrity-check.yml"], "constraints": ["C4", "C5", "C8"]},
      {"canonical_path": "knowledge-graph.json", "depends_on": ["PROJECT_TREE.md", "00-CONTEXT/facundo-core-context.md"], "required_by": ["05-CONFIGURATIONS/validation/schema-validator.py"], "constraints": ["C4", "C5"]},
      {"canonical_path": "SDD-COLLABORATIVE-GENERATION.md", "depends_on": ["GOVERNANCE-ORCHESTRATOR.md", "01-RULES/09-AGENTIC-OUTPUT-RULES.md"], "required_by": ["02-SKILLS/GENERATION-MODELS.md", "05-CONFIGURATIONS/templates/skill-template.md"], "constraints": ["C4", "C5", "C7"]},
      {"canonical_path": "TOOLCHAIN-REFERENCE.md", "depends_on": ["05-CONFIGURATIONS/validation/orchestrator-engine.sh"], "required_by": ["01-RULES/validation-checklist.md"], "constraints": ["C5", "C8"]},
      {"canonical_path": "AI-NAVIGATION-CONTRACT.md", "depends_on": ["GOVERNANCE-ORCHESTRATOR.md"], "required_by": ["IA-QUICKSTART.md", "02-SKILLS/AI/qwen-integration.md"], "constraints": ["C4", "C8"]},
      {"canonical_path": "GOVERNANCE-ORCHESTRATOR.md", "depends_on": ["01-RULES/09-AGENTIC-OUTPUT-RULES.md"], "required_by": ["AI-NAVIGATION-CONTRACT.md", "SDD-COLLABORATIVE-GENERATION.md", "05-CONFIGURATIONS/validation/orchestrator-engine.sh"], "constraints": ["C1", "C4", "C7"]},
      {"canonical_path": "RAW_URLS_INDEX.md", "depends_on": ["PROJECT_TREE.md"], "required_by": ["IA-QUICKSTART.md", "05-CONFIGURATIONS/pipelines/provider-router.yml"], "constraints": ["C4", "C5", "C8"]},
      {"canonical_path": "00-CONTEXT/00-INDEX.md", "depends_on": ["PROJECT_TREE.md", "RAW_URLS_INDEX.md"], "required_by": ["05-CONFIGURATIONS/scripts/validate-against-specs.sh"], "constraints": ["C4", "C8"]},
      {"canonical_path": "00-CONTEXT/PROJECT_OVERVIEW.md", "depends_on": ["00-CONTEXT/facundo-core-context.md"], "required_by": [], "constraints": ["C3", "C4"]},
      {"canonical_path": "00-CONTEXT/README.md", "depends_on": ["01-RULES/01-ARCHITECTURE-RULES.md"], "required_by": ["IA-QUICKSTART.md"], "constraints": ["C3", "C8"]},
      {"canonical_path": "00-CONTEXT/facundo-core-context.md", "depends_on": [], "required_by": ["00-CONTEXT/facundo-infrastructure.md", "00-CONTEXT/PROJECT_OVERVIEW.md", "knowledge-graph.json"], "constraints": ["C3", "C4", "C8"]},
      {"canonical_path": "00-CONTEXT/facundo-infrastructure.md", "depends_on": ["01-RULES/01-ARCHITECTURE-RULES.md", "00-CONTEXT/facundo-core-context.md"], "required_by": ["05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml", "05-CONFIGURATIONS/terraform/modules/vps-base/main.tf", "02-SKILLS/INFRAESTRUCTURA/vps-interconnection.md"], "constraints": ["C1", "C2", "C3"]},
      {"canonical_path": "00-CONTEXT/facundo-business-model.md", "depends_on": ["00-CONTEXT/facundo-core-context.md"], "required_by": ["01-RULES/07-SCALABILITY-RULES.md"], "constraints": ["C3", "C4"]},
      {"canonical_path": "00-CONTEXT/documentation-validation-cheklist.md", "depends_on": ["01-RULES/validation-checklist.md", "TOOLCHAIN-REFERENCE.md"], "required_by": ["05-CONFIGURATIONS/validation/validate-skill-integrity.sh"], "constraints": ["C5", "C8"]},
      {"canonical_path": "01-RULES/00-INDEX.md", "depends_on": ["PROJECT_TREE.md"], "required_by": ["05-CONFIGURATIONS/validation/check-wikilinks.sh"], "constraints": ["C4", "C8"]},
      {"canonical_path": "01-RULES/01-ARCHITECTURE-RULES.md", "depends_on": ["00-CONTEXT/facundo-infrastructure.md"], "required_by": ["05-CONFIGURATIONS/terraform/modules/vps-base/main.tf", "02-SKILLS/INFRAESTRUCTURA/docker-compose-networking.md", "05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml"], "constraints": ["C1", "C2", "C3"]},
      {"canonical_path": "01-RULES/02-RESOURCE-GUARDRAILS.md", "depends_on": ["00-CONTEXT/facundo-infrastructure.md"], "required_by": ["05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.yml", "02-SKILLS/BASE DE DATOS-RAG/mysql-optimization-4gb-ram.md", "05-CONFIGURATIONS/pipelines/provider-router.yml"], "constraints": ["C1", "C2"]},
      {"canonical_path": "01-RULES/03-SECURITY-RULES.md", "depends_on": ["00-CONTEXT/facundo-infrastructure.md"], "required_by": ["02-SKILLS/SEGURIDAD/security-hardening-vps.md", "05-CONFIGURATIONS/scripts/audit-secrets.sh", "05-CONFIGURATIONS/terraform/modules/vps-base/main.tf"], "constraints": ["C3", "C4", "C5"]},
      {"canonical_path": "01-RULES/04-API-RELIABILITY-RULES.md", "depends_on": ["00-CONTEXT/facundo-infrastructure.md"], "required_by": ["05-CONFIGURATIONS/pipelines/provider-router.yml", "02-SKILLS/AI/openrouter-api-integration.md", "02-SKILLS/COMUNICACIÓN/telegram-bot-integration.md"], "constraints": ["C4", "C6", "C7"]},
      {"canonical_path": "01-RULES/05-CODE-PATTERNS-RULES.md", "depends_on": [], "required_by": ["02-SKILLS/AI/qwen-integration.md", "06-PROGRAMMING/bash/robust-error-handling.md", "05-CONFIGURATIONS/templates/skill-template.md"], "constraints": ["C3", "C5", "C8"]},
      {"canonical_path": "01-RULES/06-MULTITENANCY-RULES.md", "depends_on": ["01-RULES/02-RESOURCE-GUARDRAILS.md"], "required_by": ["02-SKILLS/BASE DE DATOS-RAG/multi-tenant-data-isolation.md", "05-CONFIGURATIONS/terraform/modules/postgres-rls/main.tf", "03-AGENTS/clients/rag-knowledge-agent.md"], "constraints": ["C4", "C5", "C7"]},
      {"canonical_path": "01-RULES/07-SCALABILITY-RULES.md", "depends_on": ["00-CONTEXT/facundo-business-model.md", "01-RULES/02-RESOURCE-GUARDRAILS.md"], "required_by": ["04-WORKFLOWS/n8n/INFRA-003-Alert-Dispatcher.json", "07-PROCEDURES/scaling-decision-matrix.md"], "constraints": ["C1", "C2", "C7"]},
      {"canonical_path": "01-RULES/08-SKILLS-REFERENCE.md", "depends_on": ["02-SKILLS/00-INDEX.md"], "required_by": ["02-SKILLS/GENERATION-MODELS.md"], "constraints": ["C4", "C8"]},
      {"canonical_path": "01-RULES/09-AGENTIC-OUTPUT-RULES.md", "depends_on": ["GOVERNANCE-ORCHESTRATOR.md"], "required_by": ["05-CONFIGURATIONS/validation/orchestrator-engine.sh", "SDD-COLLABORATIVE-GENERATION.md", "02-SKILLS/GENERATION-MODELS.md"], "constraints": ["C4", "C5", "C8"]},
      {"canonical_path": "01-RULES/validation-checklist.md", "depends_on": ["05-CONFIGURATIONS/validation/norms-matrix.json", "TOOLCHAIN-REFERENCE.md"], "required_by": ["00-CONTEXT/documentation-validation-cheklist.md", ".github/workflows/integrity-check.yml"], "constraints": ["C5", "C8"]},
      {"canonical_path": "02-SKILLS/00-INDEX.md", "depends_on": ["PROJECT_TREE.md", "01-RULES/08-SKILLS-REFERENCE.md"], "required_by": ["05-CONFIGURATIONS/templates/skill-template.md", "02-SKILLS/skill-domains-mapping.md"], "constraints": ["C4", "C8"]},
      {"canonical_path": "02-SKILLS/skill-domains-mapping.md", "depends_on": ["02-SKILLS/00-INDEX.md"], "required_by": ["knowledge-graph.json", "05-CONFIGURATIONS/pipelines/provider-router.yml"], "constraints": ["C4", "C8"]},
      {"canonical_path": "02-SKILLS/GENERATION-MODELS.md", "depends_on": ["SDD-COLLABORATIVE-GENERATION.md", "01-RULES/09-AGENTIC-OUTPUT-RULES.md"], "required_by": ["05-CONFIGURATIONS/templates/skill-template.md", "IA-QUICKSTART.md"], "constraints": ["C4", "C5", "C7"]},
      {"canonical_path": "02-SKILLS/AI/qwen-integration.md", "depends_on": ["01-RULES/05-CODE-PATTERNS-RULES.md", "AI-NAVIGATION-CONTRACT.md"], "required_by": ["02-SKILLS/WHATSAPP-RAG AGENTS/whatsapp-rag-openrouter.md", "02-SKILLS/COMUNICACIÓN/whatsapp-rag-openRouter.md"], "constraints": ["C3", "C4", "C6"]},
      {"canonical_path": "02-SKILLS/AI/openrouter-api-integration.md", "depends_on": ["01-RULES/04-API-RELIABILITY-RULES.md"], "required_by": ["02-SKILLS/AI/qwen-integration.md", "02-SKILLS/COMUNICACIÓN/whatsapp-rag-openRouter.md", "05-CONFIGURATIONS/pipelines/provider-router.yml"], "constraints": ["C3", "C4", "C6", "C7"]},
      {"canonical_path": "02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md", "depends_on": ["01-RULES/06-MULTITENANCY-RULES.md", "05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.yml"], "required_by": ["02-SKILLS/WHATSAPP-RAG AGENTS/whatsapp-rag-openrouter.md", "03-AGENTS/clients/rag-knowledge-agent.md", "05-CONFIGURATIONS/terraform/modules/qdrant-cluster/main.tf"], "constraints": ["C3", "C4", "C5"]},
      {"canonical_path": "02-SKILLS/BASE DE DATOS-RAG/multi-tenant-data-isolation.md", "depends_on": ["01-RULES/06-MULTITENANCY-RULES.md"], "required_by": ["05-CONFIGURATIONS/terraform/modules/postgres-rls/main.tf", "03-AGENTS/clients/rag-knowledge-agent.md"], "constraints": ["C4", "C5", "C7"]},
      {"canonical_path": "02-SKILLS/BASE DE DATOS-RAG/mysql-optimization-4gb-ram.md", "depends_on": ["01-RULES/02-RESOURCE-GUARDRAILS.md"], "required_by": ["05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.yml", "07-PROCEDURES/vps-initial-setup.md"], "constraints": ["C1", "C2", "C3"]},
      {"canonical_path": "02-SKILLS/INFRAESTRUCTURA/docker-compose-networking.md", "depends_on": ["01-RULES/01-ARCHITECTURE-RULES.md"], "required_by": ["05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml", "05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.yml", "05-CONFIGURATIONS/docker-compose/vps3-n8n-uazapi.yml"], "constraints": ["C1", "C3", "C4"]},
      {"canonical_path": "02-SKILLS/INFRAESTRUCTURA/vps-interconnection.md", "depends_on": ["01-RULES/01-ARCHITECTURE-RULES.md", "00-CONTEXT/facundo-infrastructure.md"], "required_by": ["04-WORKFLOWS/n8n/INFRA-001-Monitor-Salud-VPS.json", "05-CONFIGURATIONS/scripts/health-check.sh"], "constraints": ["C3", "C4", "C7"]},
      {"canonical_path": "02-SKILLS/SEGURIDAD/security-hardening-vps.md", "depends_on": ["01-RULES/03-SECURITY-RULES.md"], "required_by": ["03-AGENTS/infrastructure/security-hardening-agent.md", "04-WORKFLOWS/n8n/INFRA-004-Security-Hardening.json", "07-PROCEDURES/vps-initial-setup.md"], "constraints": ["C3", "C4", "C5"]},
      {"canonical_path": "02-SKILLS/COMUNICACIÓN/telegram-bot-integration.md", "depends_on": ["01-RULES/04-API-RELIABILITY-RULES.md"], "required_by": ["03-AGENTS/infrastructure/alert-dispatcher-agent.md", "04-WORKFLOWS/n8n/INFRA-003-Alert-Dispatcher.json"], "constraints": ["C3", "C4", "C6"]},
      {"canonical_path": "02-SKILLS/WHATSAPP-RAG AGENTS/whatsapp-rag-openrouter.md", "depends_on": ["02-SKILLS/AI/qwen-integration.md", "02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md", "01-RULES/04-API-RELIABILITY-RULES.md"], "required_by": ["03-AGENTS/clients/whatsapp-attention-agent.md", "04-WORKFLOWS/n8n/CLIENT-001-WhatsApp-RAG.json"], "constraints": ["C3", "C4", "C6", "C7"]},
      {"canonical_path": "05-CONFIGURATIONS/00-INDEX.md", "depends_on": ["PROJECT_TREE.md", "01-RULES/08-SKILLS-REFERENCE.md"], "required_by": ["05-CONFIGURATIONS/validation/validate-skill-integrity.sh"], "constraints": ["C4", "C8"]},
      {"canonical_path": "05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml", "depends_on": ["02-SKILLS/INFRAESTRUCTURA/docker-compose-networking.md", "01-RULES/02-RESOURCE-GUARDRAILS.md", "00-CONTEXT/facundo-infrastructure.md"], "required_by": ["04-WORKFLOWS/n8n/INFRA-001-Monitor-Salud-VPS.json"], "constraints": ["C1", "C2", "C3"]},
      {"canonical_path": "05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.yml", "depends_on": ["02-SKILLS/BASE DE DATOS-RAG/qdrant-rag-ingestion.md", "02-SKILLS/INFRAESTRUCTURA/docker-compose-networking.md", "01-RULES/02-RESOURCE-GUARDRAILS.md"], "required_by": ["04-WORKFLOWS/n8n/INFRA-002-Backup-Manager.json", "03-AGENTS/clients/rag-knowledge-agent.md"], "constraints": ["C1", "C3", "C4"]},
      {"canonical_path": "05-CONFIGURATIONS/docker-compose/vps3-n8n-uazapi.yml", "depends_on": ["05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml", "01-RULES/02-RESOURCE-GUARDRAILS.md"], "required_by": ["04-WORKFLOWS/n8n/CLIENT-001-WhatsApp-RAG.json"], "constraints": ["C1", "C2", "C3"]},
      {"canonical_path": "05-CONFIGURATIONS/validation/orchestrator-engine.sh", "depends_on": ["05-CONFIGURATIONS/validation/norms-matrix.json", "01-RULES/09-AGENTIC-OUTPUT-RULES.md", "GOVERNANCE-ORCHESTRATOR.md"], "required_by": ["PROJECT_TREE.md", "05-CONFIGURATIONS/scripts/validate-against-specs.sh", ".github/workflows/integrity-check.yml", "05-CONFIGURATIONS/templates/skill-template.md"], "constraints": ["C5", "C7", "C8"]},
      {"canonical_path": "05-CONFIGURATIONS/validation/norms-matrix.json", "depends_on": ["01-RULES/validation-checklist.md"], "required_by": ["05-CONFIGURATIONS/validation/orchestrator-engine.sh", "05-CONFIGURATIONS/validation/verify-constraints.sh", "PROJECT_TREE.md", "05-CONFIGURATIONS/scripts/validate-against-specs.sh"], "constraints": ["C4", "C5"]},
      {"canonical_path": "05-CONFIGURATIONS/validation/validate-skill-integrity.sh", "depends_on": ["05-CONFIGURATIONS/validation/norms-matrix.json", "01-RULES/09-AGENTIC-OUTPUT-RULES.md"], "required_by": ["05-CONFIGURATIONS/templates/skill-template.md", ".github/workflows/validate-skill.yml"], "constraints": ["C5", "C8"]},
      {"canonical_path": "05-CONFIGURATIONS/terraform/modules/vps-base/main.tf", "depends_on": ["01-RULES/01-ARCHITECTURE-RULES.md", "01-RULES/03-SECURITY-RULES.md"], "required_by": ["05-CONFIGURATIONS/terraform/modules/qdrant-cluster/main.tf", "05-CONFIGURATIONS/terraform/modules/postgres-rls/main.tf"], "constraints": ["C1", "C2", "C3"]},
      {"canonical_path": "05-CONFIGURATIONS/terraform/modules/postgres-rls/main.tf", "depends_on": ["01-RULES/06-MULTITENANCY-RULES.md", "05-CONFIGURATIONS/terraform/modules/vps-base/main.tf"], "required_by": ["05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.yml", "02-SKILLS/BASE DE DATOS-RAG/multi-tenant-data-isolation.md"], "constraints": ["C4", "C5", "C7"]},
      {"canonical_path": "05-CONFIGURATIONS/terraform/modules/qdrant-cluster/main.tf", "depends_on": ["05-CONFIGURATIONS/terraform/modules/vps-base/main.tf", "01-RULES/06-MULTITENANCY-RULES.md"], "required_by": ["05-CONFIGURATIONS/docker-compose/vps2-crm-qdrant.yml"], "constraints": ["C3", "C4", "C5"]},
      {"canonical_path": "05-CONFIGURATIONS/pipelines/provider-router.yml", "depends_on": ["01-RULES/04-API-RELIABILITY-RULES.md", "01-RULES/02-RESOURCE-GUARDRAILS.md"], "required_by": ["02-SKILLS/AI/openrouter-api-integration.md", "04-WORKFLOWS/sdd-assisted-generation-loop.json"], "constraints": ["C4", "C6", "C7"]},
      {"canonical_path": "05-CONFIGURATIONS/templates/skill-template.md", "depends_on": ["01-RULES/09-AGENTIC-OUTPUT-RULES.md", "05-CONFIGURATIONS/validation/validate-skill-integrity.sh"], "required_by": ["02-SKILLS/GENERATION-MODELS.md", "IA-QUICKSTART.md"], "constraints": ["C3", "C4", "C5"]},
      {"canonical_path": "05-CONFIGURATIONS/scripts/validate-against-specs.sh", "depends_on": ["05-CONFIGURATIONS/validation/orchestrator-engine.sh", "01-RULES/validation-checklist.md"], "required_by": [".github/workflows/integrity-check.yml"], "constraints": ["C3", "C5", "C8"]},
      {"canonical_path": "05-CONFIGURATIONS/scripts/health-check.sh", "depends_on": ["01-RULES/02-RESOURCE-GUARDRAILS.md", "02-SKILLS/INFRAESTRUCTURA/vps-interconnection.md"], "required_by": ["03-AGENTS/infrastructure/health-monitor-agent.md", "04-WORKFLOWS/n8n/INFRA-001-Monitor-Salud-VPS.json"], "constraints": ["C1", "C2", "C8"]},
      {"canonical_path": "05-CONFIGURATIONS/environment/.env.example", "depends_on": ["01-RULES/03-SECURITY-RULES.md"], "required_by": ["05-CONFIGURATIONS/docker-compose/vps1-n8n-uazapi.yml", "05-CONFIGURATIONS/terraform/environments/variables.tf"], "constraints": ["C3", "C5"]}
    ]
  }
}
```
---

> ✅ **Documento generado bajo contrato SDD v1.0.0**. Validado contra `norms-matrix.json`.  
> 🔐 Para actualizar este documento, modificar `05-CONFIGURATIONS/templates/skill-template.md` y re-ejecutar `orchestrator-engine.sh --mode headless --file IA-QUICKSTART.md --json`.  
> 🌱 Próxima iteración: Incluir ejemplos de payloads JSON para cada modo y agregar soporte para validación offline con `jq` fallback.
