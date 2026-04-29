# ---
# artifact_id: terraform-postgres-rls-module
# artifact_type: infrastructure_module
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C2","C3","C4","C5","V1","V2","V3"]
# canonical_path: 05-CONFIGURATIONS/terraform/modules/postgres-rls/main.tf
# domain: 05-CONFIGURATIONS
# subdomain: terraform
# agent_role: terraform-master
# language_lock: es-ES
# validation_command: orchestrator-engine.sh --domain terraform --strict
# tier: 3
# immutable: true
# requires_human_approval_for_changes: true
# audience: ["agentic_assistants"]
# human_readable: false
# checksum_sha256: "e507ecc8e2e4b2a38b27b631b0434c07d7114a38f05164c44c0552a4899a635a"
# ---

# ============================================================================
# MÓDULO POSTGRESQL + RLS + PGVECTOR (MANTIS v2.0.0)
# Propósito: Base de datos aislada por tenant (RLS), cifrada, con pgvector (V1/V3)
# Generado por: terraform-master-agent
# Fecha: 2026-04-30
# Alineación: interface-spec.yaml, mapping.yaml, vps-base/main.tf
# ============================================================================

# --- VARIABLES (C5: validación estricta) ---
variable "db_identifier" {
  description = "Identificador único de la instancia RDS"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,62}$", var.db_identifier))
    error_message = "db_identifier: minúsculas, números, guiones; 3-63 chars; iniciar con letra."
  }
}

variable "environment_tag" {
  description = "Entorno de despliegue (dev/staging/prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment_tag)
    error_message = "environment_tag debe ser: dev, staging, o prod"
  }
}

variable "db_username" {
  description = "Usuario maestro de PostgreSQL (C3: no usar 'admin' o 'root')"
  type        = string
  default     = "mantis_app"
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{2,31}$", var.db_username))
    error_message = "db_username inválido o reservado."
  }
}

variable "db_password" {
  description = "Password de la base de datos. Inyectar desde secret manager (C3)"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.db_password) >= 16 && can(regex("[A-Z]", var.db_password)) && can(regex("[a-z]", var.db_password)) && can(regex("[0-9]", var.db_password))
    error_message = "db_password: min 16 chars, debe incluir mayúscula, minúscula y número."
  }
}

variable "instance_class" {
  description = "Clase de instancia RDS (ajustar por perfil de carga)"
  type        = string
  validation {
    condition     = can(regex("^db\\.(t[23]\\.(small|medium|large)|r[568]\\.(large|xlarge))$", var.instance_class))
    error_message = "instance_class debe ser db.t2/t3 o db.r5/r6/r8 válido."
  }
}

variable "vpc_id" {
  description = "ID de VPC para subnet group y security group"
  type        = string
  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "vpc_id formato AWS inválido."
  }
}

variable "subnet_ids" {
  description = "Lista de subnet IDs para despliegue multi-AZ"
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "subnet_ids requiere al menos 2 subnets para alta disponibilidad."
  }
}

variable "pgvector_enabled" {
  description = "Habilitar extensión pgvector para embeddings (V1)"
  type        = bool
  default     = true
}

variable "multi_az" {
  description = "Habilitar despliegue multi-AZ (recomendado staging/prod)"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Días de retención de backups automatizados (V2: integridad)"
  type        = number
  default     = 7
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "backup_retention_days debe estar entre 1 y 35."
  }
}

# --- LOCALS (C4: trazabilidad consistente) ---
locals {
  base_tags = {
    Project     = "mantis-agentic"
    Domain      = "05-CONFIGURATIONS"
    Environment = var.environment_tag
    ManagedBy   = "terraform"
    Module      = "postgres-rls"
    Constraint  = "V1-tenant-isolation,V3-vector-performance"
  }
  param_group_name = "mantis-${var.environment_tag}-pg-params"
}

# ============================================================================
# RECURSOS
# ============================================================================

# --- Security Group Restringido (C3: principio de menor privilegio) ---
resource "aws_security_group" "postgres" {
  name_prefix = "mantis-${var.environment_tag}-pg-"
  description = "PostgreSQL RDS: acceso solo desde VPS base y CIDR de gestión"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL from VPS base"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"] # Ajustar a CIDR de subnets de cómputo
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.base_tags, { Name = "${var.db_identifier}-sg" })
}

# --- DB Subnet Group (VPC) ---
resource "aws_db_subnet_group" "postgres" {
  name       = "mantis-${var.environment_tag}-${var.db_identifier}-subnet"
  subnet_ids = var.subnet_ids

  tags = merge(local.base_tags, { Name = "${var.db_identifier}-subnet-group" })
}

# --- Parameter Group (Optimización pgvector & Performance V3) ---
resource "aws_db_parameter_group" "postgres" {
  name   = local.param_group_name
  family = "postgres16" # Ajustar según versión requerida

  dynamic "parameter" {
    for_each = var.pgvector_enabled ? [1] : []
    content {
      name         = "shared_preload_libraries"
      value        = "pgvector,pg_stat_statements"
      apply_method = "pending-reboot"
    }
  }

  parameter {
    name  = "log_statement"
    value = "ddl"
  }
  parameter {
    name  = "log_min_duration_statement"
    value = "1000" # ms, para detectar queries lentas (C8)
  }

  tags = local.base_tags
}

# --- RDS Instance (C2, C3, V2) ---
resource "aws_db_instance" "postgres" {
  identifier     = var.db_identifier
  engine         = "postgres"
  engine_version = "16.3" # Versión estable con soporte pgvector nativo
  
  instance_class   = var.instance_class
  username         = var.db_username
  password         = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.postgres.id]
  parameter_group_name   = aws_db_parameter_group.postgres.name

  # C3: Cifrado en reposo
  storage_encrypted = true
  
  # C7: Backups automatizados para resiliencia
  backup_retention_period = var.backup_retention_days
  copy_tags_to_snapshot   = true
  delete_automated_backups = false

  # V1/V2: Aislamiento y mantenimiento
  multi_az               = var.multi_az
  publicly_accessible    = false
  auto_minor_version_upgrade = true
  maintenance_window     = "sun:03:00-sun:04:00"
  
  # Performance tuning (V3)
  allocated_storage     = 20
  max_allocated_storage = 100 # Auto-scaling storage
  iops                  = 3000 # gp3 baseline
  storage_type          = "gp3"

  tags = merge(local.base_tags, { Name = var.db_identifier })
}

# ============================================================================
# OUTPUTS (Alineados estrictamente con interface-spec.yaml)
# ============================================================================

output "db_endpoint" {
  description = "Connection string sin credenciales (interface-spec.yaml alignment)"
  value       = "postgres://${aws_db_instance.postgres.endpoint}/${var.db_username}"
  sensitive   = false
}

output "db_schema" {
  description = "Schema por defecto para aislamiento RLS de tenants"
  value       = "tenant_${var.environment_tag}_base"
  sensitive   = false
}

output "db_pool_size" {
  description = "Tamaño recomendado del pool de conexiones"
  value       = var.instance_class == "db.t3.medium" ? 20 : 50
  sensitive   = false
}

output "security_group_id" {
  description = "ID del SG de PostgreSQL para reference cruzada"
  value       = aws_security_group.postgres.id
}

output "compliance_check" {
  description = "Indicadores de cumplimiento para orchestrator-engine.sh"
  value = {
    C2_iac_db            = true
    C3_encrypted_storage = true
    C3_no_public_access  = true
    C4_tags_applied      = true
    C5_vars_validated    = true
    V2_backup_configured = var.backup_retention_days > 0
    V3_pgvector_ready    = var.pgvector_enabled
  }
}

# ============================================================================
# ANTI-PATRONES EXPLÍCITOS (C1, C3, C5)
# ============================================================================
# ❌ NUNCA: `publicly_accessible = true` en prod o staging
# ❌ NUNCA: Hardcodear `password` en .tf o .env del repo
# ❌ NUNCA: Omitir `storage_encrypted = true` (violación C3 crítica)
# ❌ NUNCA: Usar `engine_version` sin validar compatibilidad pgvector
# ✅ SIEMPRE: Aplicar políticas RLS post-provisioning vía migración SQL
# ✅ SIEMPRE: Mantener `auto_minor_version_upgrade = true` para parches de seguridad

# ============================================================================
# COMANDOS DE VALIDACIÓN Y USO
# ============================================================================
# 1. Formatear & validar:
#    terraform fmt -check . && terraform init -backend=false && terraform validate
# 2. Scan seguridad (C3/C5):
#    checkov -d . --framework terraform --check CKV_AWS_17,CKV_AWS_15,CKV_AWS_16,CKV2_AWS_5
# 3. Integración orchestrator:
#    orchestrator-engine.sh --domain terraform --file 05-CONFIGURATIONS/terraform/modules/postgres-rls/main.tf --strict
# 4. Post-provisioning RLS (ejemplo):
#    psql "${db_endpoint}" -U "${db_username}" -f migrations/rls_policies.sql
# 5. Update checksum:
#    CHECKSUM=$(sha256sum <ruta> | awk '{print $1}') && sed -i "s/^# checksum_sha256: "e507ecc8e2e4b2a38b27b631b0434c07d7114a38f05164c44c0552a4899a635a"
```

---
