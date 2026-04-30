---
artifact_id: "terraform-module-readme-template-v1.0.0"
artifact_type: "documentation_template"
version: "1.0.0-COMPREHENSIVE"
constraints_mapped: ["C1","C4","C5"]
canonical_path: "05-CONFIGURATIONS/templates/terraform-module-template/README.md"
domain: "05-CONFIGURATIONS"
subdomain: "templates"
agent_role: "terraform-docs-generator"
language_lock: "markdown"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain terraform --file 05-CONFIGURATIONS/templates/terraform-module-template/README.md --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants", "infra_team"]
human_readable: true
checksum_sha256: "9a7f05b1d0979b16567abbba452ab1df0b2226b264d3d627d99751139800c528"
---


# 🏗️ `{module_name}` — Terraform Module

> **Descripción**: `{Breve descripción del módulo. Ej: Provisiona VPC con subnets privadas, NAT Gateway y security groups MANTIS.}`

## 📦 Uso

```hcl
module "{module_slug}" {
  source = "git::https://github.com/Mantis-AgenticDev/agentic-infra-docs.git//05-CONFIGURATIONS/terraform/modules/{module_slug}?ref=v1.0.0"
  
  environment = var.environment
  tenant_id   = var.tenant_id
  # ... inputs obligatorios
}
```

## 📥 Inputs

| Nombre | Descripción | Tipo | Default | Required |
|--------|-------------|------|---------|----------|
| `environment` | Entorno de despliegue | `string` | - | ✅ |
| `tenant_id` | Aislamiento lógico | `string` | - | ✅ |

## 📤 Outputs

| Nombre | Descripción | Sensitive |
|--------|-------------|-----------|
| `id` | Identificador del recurso | ❌ |
| `arn` | ARN completo | ❌ |
| `connection_string` | URI de acceso | ✅ |

## 🛡️ Constraints MANTIS
- **C1**: Versionado estricto `?ref=v{tag}`. No usar ramas en prod.
- **C2**: Declarativo. Cero `provisioner` o `local-exec`.
- **C3**: Variables sensibles con `sensitive = true`. Nunca hardcodear.
- **C4**: Tags obligatorios: `Environment`, `Tenant`, `ManagedBy`.
- **C5**: Validación en `variables.tf` con bloques `validation {}`.

## 🧪 Validación
```bash
terraform init -backend=false && terraform validate
tflint --init && tflint --config .tflint.hcl
checkov -d . --framework terraform --quiet
```

## ⚠️ Anti-Patrones
❌ Hardcodear `account_id` o `region`  
❌ Omitir `validation {}` en inputs críticos  
❌ Exponer outputs sensibles sin flag  
✅ Usar `lifecycle { prevent_destroy = true }` en recursos críticos  
✅ Enlazar outputs a `interface-spec.yaml`

---
*Generado por `terraform-docs` | Mantenido por `terraform-master-agent` | Constraints: C1,C4,C5*

---
