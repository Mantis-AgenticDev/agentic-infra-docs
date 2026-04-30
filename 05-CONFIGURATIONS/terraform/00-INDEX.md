---
# FRONTMATTER CANÓNICO OBLIGATORIO
artifact_id: "00-INDEX-terraform-modules-index-v1.0.0"
artifact_type: "directory_index"
version: "1.0.0-COMPREHENSIVE"
constraints_mapped: ["C1","C2","C4","C5"]
canonical_path: "05-CONFIGURATIONS/terraform/modules/00-INDEX.md"
domain: "05-CONFIGURATIONS"
subdomain: "terraform/modules"
agent_role: "terraform-modules-coordinator"
language_lock: "markdown"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain terraform --file 05-CONFIGURATIONS/terraform/modules/00-INDEX.md --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants", "infra_team"]
human_readable: true
checksum_sha256: "PENDING_GENERATION"
# FIN FRONTMATTER
---
```

```markdown
# 🏗️ 05-CONFIGURATIONS/terraform/modules/ — Índice de Módulos IaC

> **Propósito**: Catálogo maestro de módulos reutilizables de Terraform. Define la estructura, contratos de entrada/salida, versiones, validaciones de seguridad y patrones de uso estándar para asegurar infraestructura consistente, segura y trazable.

## 📚 Catálogo de Módulos Disponibles

| Módulo | Ruta | Propósito | Inputs Clave | Outputs Clave | Estado | Version |
|--------|------|-----------|--------------|---------------|--------|---------|
| **vpc-base** | `modules/vpc-base/` | Red troncal, subnets, NAT, Peering | `cidr_block`, `env`, `region` | `vpc_id`, `subnet_ids`, `nat_gw_id` | ✅ REAL | `v1.2.0` |
| **postgres-rls** | `modules/postgres-rls/` | RDS Postgres con RLS por tenant | `instance_class`, `backup_ret`, `tenant_id` | `db_host`, `connection_string`, `rls_policies` | ✅ REAL | `v1.1.0` |
| **qdrant-vector** | `modules/qdrant-vector/` | Cluster de vectores (Qdrant/PgVector) | `replica_count`, `index_type` (hnsw/ivf) | `vector_endpoint`, `api_key_secret` | ✅ REAL | `v0.9.0` |
| **security-group** | `modules/security-group/` | Grupos de seguridad estándarizados | `allowed_ports`, `cidr_whitelist`, `description` | `sg_id` | ✅ REAL | `v1.0.5` |
| **ecs-fargate** | `modules/ecs-fargate/` | Despliegue de contenedores Serverless | `image_uri`, `task_memory`, `cpu` | `service_url`, `cluster_arn` | 🔄 PLANNED | - |
| **monitoring-stack** | `modules/monitoring-stack/` | Prometheus/Grafana/Loki en infra | `retention_days`, `storage_size_gb` | `dashboard_url`, `alertmanager_ep` | 🔄 PLANNED | - |

## 📐 Estándar de Uso (C1: Versionado e Inmutabilidad)

Para consumir estos módulos en `envs/{environment}/main.tf`, siga estrictamente:

1.  **Source con Version Tag**: Nunca use `ref: main` o `branch` en producción.
    ```hcl
    module "vpc" {
      source  = "git::https://github.com/Mantis-AgenticDev/agentic-infra-docs.git//05-CONFIGURATIONS/terraform/modules/vpc-base?ref=v1.2.0"
      # ...
    }
    ```
2.  **Variables Sensibles**: Nunca hardcodear secrets. Usar variables o referencias a SSM/Vault.
    ```hcl
    module "db" {
      db_password = var.db_password # Variable sensible marcada en variables.tf
      # O:
      db_password = data.aws_ssm_parameter.db_pwd.value
    }
    ```
3.  **Tags Estándar**: Todos los módulos aplican tags comunes (C4: Trazabilidad).
    ```hcl
    tags = {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = "mantis"
      Constraint  = "C1,C2,C3"
    }
    ```

## 🛡️ Validación y Seguridad por Módulo

Cada módulo debe pasar los siguientes checks antes de ser promovido a `REAL`:

| Herramienta | Alcance | Regla |
|-------------|---------|-------|
| **TFLint** | Todos | Sintaxis HCL, reglas de providers (ej: nombres de instancias deprecated). |
| **Checkov** | Todos | Security: No S3 públicos, SGs sin 0.0.0.0/0 en puerto 22, encryption enabled. |
| **TFSec** | Todos | Compliance: IAM sin wildcard `*`, logging habilitado. |
| **Terratest** | Críticos | Pruebas de integración en entorno efímero (crea infra, valida output, destruye). |

### Comandos de Validación
```bash
# Validar sintaxis y formato de TODOS los módulos
cd 05-CONFIGURATIONS/terraform/modules/ && terraform fmt -recursive -check

# Validar inicialización y sintaxis de un módulo específico
cd modules/vpc-base/ && terraform init -backend=false && terraform validate

# Auditoría de seguridad (requiere checkov instalado)
checkov -d modules/postgres-rls/ --framework terraform --quiet
```

## ⚠️ Anti-Patrones Explícitos (DO NOT)

❌ Crear recursos fuera de los módulos definidos ("Snowflake infrastructure")  
❌ Usar variables `default` para valores sensibles (ej: `variable "password" { default = "1234" }`)  
❌ Omisión de `lifecycle { prevent_destroy = true }` en bases de datos críticas o buckets de estado  
❌ Hardcodear `account_id` o `region` en lugar de usar `data.aws_caller_identity` o `var.region`  

✅ **Siempre** documentar `inputs` y `outputs` en el `README.md` del módulo  
✅ **Siempre** usar `terraform fmt` y `tflint` antes del commit  
✅ **Siempre** validar que los módulos nuevos incluyen `variables.tf` con bloques `validation`  

## 🔗 Enlaces Canónicos Relacionados
- [[../00-INDEX.md]] → Índice maestro de configuraciones
- [[../variables.tf]] → Variables globales del proyecto
- [[../outputs.tf]] → Outputs consolidados por entorno
- [[../../../05-CONFIGURATIONS/terraform-master-agent.md]] → Guía del agente maestro
- [[https://www.terraform.io/docs/modules/index.html]] → Documentación oficial HashiCorp

---
*Documento generado por infra-docs-generator v1.0.0 | Mantenido por `terraform-master-agent` | Constraints: C1, C2, C5*
---
