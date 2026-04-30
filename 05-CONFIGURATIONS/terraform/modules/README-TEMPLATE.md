---
# FRONTMATTER CANÓNICO OBLIGATORIO
artifact_id: "terraform-module-readme-template-v1.0.0"
artifact_type: "documentation_template"
version: "1.0.0-COMPREHENSIVE"
constraints_mapped: ["C1","C2","C4","C5"]
canonical_path: "05-CONFIGURATIONS/terraform/modules/README-TEMPLATE.md"
domain: "05-CONFIGURATIONS"
subdomain: "terraform/modules"
agent_role: "terraform-docs-generator"
language_lock: "markdown"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain terraform --file 05-CONFIGURATIONS/terraform/modules/README-TEMPLATE.md --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants", "infra_team"]
human_readable: true
checksum_sha256: "206f0d3d81051cbd40be313783faece4dcec848a1af4cf09ba0d16fbe9363efb"
# FIN FRONTMATTER
---

# 🏗️ `{module_name}` — Terraform Module for MANTIS

> **Descripción**: `{Breve descripción del propósito del módulo, ej: "Provisiona VPC con subnets públicas/privadas, NAT Gateway y security groups estándar para MANTIS"}`

## 📦 Uso Estándar

```hcl
module "{module_slug}" {
  source = "git::https://github.com/Mantis-AgenticDev/agentic-infra-docs.git//05-CONFIGURATIONS/terraform/modules/{module_slug}?ref=v{version}"
  
  # Variables obligatorias
  name        = var.project_name
  environment = var.environment
  tenant_id   = var.tenant_id
  
  # Variables opcionales con defaults seguros
  cidr_block        = "10.0.0.0/16"
  enable_nat_gateway = var.environment == "prod" ? true : false
  
  # Tags obligatorios (C4: Trazabilidad)
  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Constraint  = "C1,C2,C5"
  }
}
```

## 📥 Inputs

| Nombre | Descripción | Tipo | Default | Obligatorio |
|--------|-------------|------|---------|-------------|
| `name` | Nombre base para recursos | `string` | - | ✅ |
| `environment` | Entorno de despliegue (`dev`, `staging`, `prod`) | `string` | - | ✅ |
| `tenant_id` | Identificador único para aislamiento lógico | `string` | - | ✅ |
| `cidr_block` | CIDR principal para la red | `string` | `"10.0.0.0/16"` | ❌ |
| `enable_monitoring` | Habilitar métricas detalladas y alertas | `bool` | `true` | ❌ |

## 📤 Outputs

| Nombre | Descripción | Sensible |
|--------|-------------|----------|
| `id` | ID del recurso principal | ❌ |
| `arn` | ARN completo para integración IAM/SSM | ❌ |
| `connection_string` | Endpoint de conexión (si aplica) | ✅ |
| `security_group_id` | ID del SG creado para este módulo | ❌ |

## 🛡️ Constraints Aplicables (MANTIS)

| Código | Aplicación en este módulo | Validación |
|--------|---------------------------|------------|
| **C1** | Versionado semántico estricto en `?ref=v{version}`. No usar `main` en prod. | `git tag`, `semantic-release` |
| **C2** | Todo recurso definido declarativamente. No `provisioner` ni `null_resource` para config. | `terraform validate`, `tflint` |
| **C3** | Variables sensibles marcadas con `sensitive = true`. No hardcodeo en `examples/`. | `audit-secrets.sh`, `checkov` |
| **C4** | Tags obligatorios: `Environment`, `ManagedBy`, `Project`, `TenantID`. | `tflint --only=terraform_required_tags` |
| **C5** | Validación explícita en `variables.tf` con bloques `validation {}`. | `terraform fmt`, `orchestrator-engine.sh` |

## 🧪 Validación y Pruebas

```bash
# 1. Inicialización y validación sintáctica
terraform init -backend=false
terraform validate

# 2. Linting de estilo y mejores prácticas
tflint --init
tflint --config .tflint.hcl

# 3. Auditoría de seguridad (Checkov)
checkov -d . --framework terraform --quiet --skip-check CKV_AWS_* # Ajustar skips si es necesario

# 4. Pruebas de integración (Terratest - opcional pero recomendado)
cd tests/ && go test -v -timeout 30m
```

## 📜 Requisitos

| Recurso | Versión Mínima |
|---------|----------------|
| **Terraform** | `>= 1.5.0` |
| **AWS Provider** | `~> 5.0` |
| **Random Provider** | `>= 3.5.0` |

## 🔄 Changelog (SemVer)

| Versión | Fecha | Cambios | Tipo |
|---------|-------|---------|------|
| `1.0.0` | `YYYY-MM-DD` | Lanzamiento inicial con estructura canónica MANTIS | `Minor` |
| `0.1.0` | `YYYY-MM-DD` | Borrador de diseño y validación de inputs | `Patch` |

## ⚠️ Anti-Patrones (DO NOT)

❌ Usar `depends_on` implícito o circular entre recursos del mismo módulo  
❌ Omitir `validation {}` en variables de tipo `string` con patrón o `number` con rango  
❌ Hardcodear `account_id`, `region` o `cidr` en lugar de usar `var.` o `data.`  
❌ Exponer outputs sensibles sin `sensitive = true`  
❌ Documentar sin actualizar `CHANGELOG.md` o incrementar versión semántica  

✅ **Siempre** usar `lifecycle { prevent_destroy = true }` en recursos críticos  
✅ **Siempre** probar en entorno efímero antes de promover a `v1.0.0`  
✅ **Siempre** enlazar outputs a `interface-spec.yaml` si son consumidos por otros agentes  

---
*Documento generado por terraform-docs v0.16.0 | Mantenido por `terraform-master-agent` | Constraints: C1, C2, C4, C5*

---
