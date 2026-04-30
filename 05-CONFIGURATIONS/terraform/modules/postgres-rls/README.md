---
# FRONTMATTER CANÓNICO OBLIGATORIO
artifact_id: "postgres-rls-readme-v1.0.0"
artifact_type: "documentation"
version: "1.0.0-COMPREHENSIVE"
constraints_mapped: ["C1","C2","C3","C4","C5","V1"]
canonical_path: "05-CONFIGURATIONS/terraform/modules/postgres-rls/README.md"
domain: "05-CONFIGURATIONS"
subdomain: "terraform/modules/postgres-rls"
agent_role: "terraform-docs-generator"
language_lock: "markdown"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain terraform --file 05-CONFIGURATIONS/terraform/modules/postgres-rls/README.md --strict"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants", "infra_team"]
human_readable: true
checksum_sha256: "f94378349f63018e29bb71f17c25ecf528265ca6996215ce58b329bc64f41ce3"
# FIN FRONTMATTER
---

# 🗄️ `postgres-rls` — Terraform Module for Tenant-Isolated PostgreSQL

> **Descripción**: Provisiona una instancia RDS PostgreSQL con aislamiento estricto por tenant (Row-Level Security), esquema dedicado, conexión segura y opcionalmente extensión `pgvector` para RAG. Diseñado para perfiles `micro` a `large`. Cumple V1 (aislamiento lógico) y C3 (seguridad de credenciales).

## 📦 Uso Estándar

```hcl
module "tenant_db" {
  source = "git::https://github.com/Mantis-AgenticDev/agentic-infra-docs.git//05-CONFIGURATIONS/terraform/modules/postgres-rls?ref=v1.1.0"
  
  identifier       = "mantis-client-xyz"
  tenant_id        = "client-xyz"
  engine_version   = "15.4"
  instance_class   = "db.t3.medium"
  allocated_storage = 50
  
  # Red
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.vpc.db_security_group_id]
  
  # Credenciales (inyectar desde Vault/SSM o variables sensibles)
  master_username = "app_admin"
  master_password = var.db_password
  
  tags = {
    Environment = "prod"
    ManagedBy   = "terraform"
    Tenant      = "client-xyz"
  }
}
```

## 📥 Inputs

| Nombre | Descripción | Tipo | Default | Obligatorio |
|--------|-------------|------|---------|-------------|
| `identifier` | Nombre único para la instancia RDS | `string` | - | ✅ |
| `tenant_id` | Identificador para aislamiento RLS y esquemas | `string` | - | ✅ |
| `master_username` | Usuario administrador (no usar `root`/`postgres`) | `string` | - | ✅ |
| `master_password` | Contraseña maestra | `string` | - | ✅ |
| `vpc_id` | ID de la VPC donde se despliega | `string` | - | ✅ |
| `subnet_ids` | Lista de subnets privadas (mínimo 2 para HA) | `list(string)` | - | ✅ |
| `security_group_ids` | Security groups permitidos para acceso | `list(string)` | `[]` | ❌ |
| `engine_version` | Versión de PostgreSQL (>=15 para pgvector) | `string` | `"15.4"` | ❌ |
| `instance_class` | Clase de instancia RDS | `string` | `"db.t3.micro"` | ❌ |
| `allocated_storage` | Almacenamiento inicial en GB | `number` | `50` | ❌ |
| `enable_pgvector` | Habilitar extensión `vector` para embeddings | `bool` | `false` | ❌ |
| `backup_retention_period` | Días de retención de backups automáticos | `number` | `7` | ❌ |
| `tags` | Etiquetas AWS para trazabilidad y costo | `map(string)` | `{}` | ❌ |

## 📤 Outputs

| Nombre | Descripción | Sensible |
|--------|-------------|----------|
| `endpoint` | Endpoint de conexión (host:port) | ❌ |
| `db_name` | Nombre de la base de datos por defecto (`postgres`) | ❌ |
| `arn` | ARN completo de la instancia | ❌ |
| `connection_string` | URI completo con credenciales (solo para apps internas) | ✅ |
| `security_group_id` | ID del SG creado para este tenant | ❌ |
| `rls_policy_count` | Número de políticas RLS aplicadas automáticamente | ❌ |

## 🛡️ Constraints Aplicables (MANTIS)

| Código | Aplicación en este módulo | Validación |
|--------|---------------------------|------------|
| **C1** | `?ref=v1.1.0` obligatorio. No usar ramas en producción. | `git tag`, pipeline de release |
| **C2** | Todo recurso declarado en HCL. Cero `provisioner` o `local-exec`. | `terraform validate`, `tflint` |
| **C3** | `master_password` marcado `sensitive = true`. Nunca hardcodear en `examples/`. | `audit-secrets.sh`, `checkov CKV_AWS_41` |
| **C4** | Tags `Environment`, `Tenant`, `ManagedBy` inyectados automáticamente. | `tflint --only=terraform_required_tags` |
| **C5** | Bloques `validation {}` en `variables.tf` para `tenant_id`, `storage`, `instance_class`. | `terraform fmt`, `orchestrator-engine.sh` |
| **V1** | Crea esquema `tenant_{id}` y aplica políticas `SELECT/INSERT/UPDATE/DELETE` con `current_setting('app.tenant_id')`. | `check-rls.sh`, `psql \d+` |

## 🧪 Validación y Pruebas

```bash
# 1. Inicialización y validación sintáctica
cd modules/postgres-rls && terraform init -backend=false
terraform validate

# 2. Linting y seguridad
tflint --init && tflint --config .tflint.hcl
checkov -d . --framework terraform --quiet --skip-check CKV_AWS_116

# 3. Prueba de aislamiento RLS (post-deploy manual)
psql "postgresql://admin:pass@${endpoint}/postgres" -c "
  SET app.tenant_id = 'client-xyz';
  SELECT count(*) FROM pg_policies WHERE schemaname = 'tenant_client_xyz';
"
```

## 📜 Requisitos

| Recurso | Versión Mínima |
|---------|----------------|
| **Terraform** | `>= 1.5.0` |
| **AWS Provider** | `~> 5.0` |
| **PostgreSQL** | `>= 15.0` (si `enable_pgvector = true`) |

## 🔄 Changelog (SemVer)

| Versión | Fecha | Cambios | Tipo |
|---------|-------|---------|------|
| `1.1.0` | `2026-05-01` | Soporte explícito para `pgvector` + políticas RLS por tenant | `Minor` |
| `1.0.0` | `2026-04-28` | Lanzamiento inicial con aislamiento lógico y backup automático | `Major` |

## ⚠️ Anti-Patrones (DO NOT)

❌ Usar `postgres` o `root` como `master_username`  
❌ Desplegar en subnets públicas o sin security group restrictivo  
❌ Omitir `sensitive = true` en `connection_string` output  
❌ Modificar políticas RLS manualmente en consola AWS (se perderán en `apply`)  
❌ Documentar sin actualizar `interface-spec.yaml` si cambia el formato de `connection_string`  

✅ **Siempre** usar `lifecycle { ignore_changes = [password] }` para permitir rotación sin reemplazo  
✅ **Siempre** validar que `enable_pgvector` coincide con `engine_version >= 15`  
✅ **Siempre** ejecutar `onboard-tenant.sh` post-deploy para inicializar esquemas y variables de sesión  

---
*Documento generado por `terraform-docs` v0.16.0 | Mantenido por `terraform-master-agent` | Constraints: C1, C2, C3, C4, C5, V1*

---
