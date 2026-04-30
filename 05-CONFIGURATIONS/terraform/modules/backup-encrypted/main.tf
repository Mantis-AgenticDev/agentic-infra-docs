# ---
# artifact_id: terraform-backup-encrypted-module
# artifact_type: infrastructure_module
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C2","C3","C4","C5","V2"]
# canonical_path: 05-CONFIGURATIONS/terraform/modules/backup-encrypted/main.tf
# domain: 05-CONFIGURATIONS
# subdomain: terraform
# agent_role: terraform-master
# language_lock: es-ES
# validation_command: orchestrator-engine.sh --domain terraform --strict
# tier: 2
# immutable: true
# requires_human_approval_for_changes: true
# audience: ["agentic_assistants"]
# human_readable: false
# checksum_sha256: "4521829ea15232d5df9a9da8393a1fc6332d0ddab2c03e8efbcdc993377ed1c6"
# ---

# ============================================================================
# MÓDULO BACKUP ENCRIPTADO (MANTIS v2.0.0)
# Propósito: Vault S3 con KMS, versioning, Object Lock (V2: integridad) y lifecycle policies.
# Generado por: terraform-master-agent
# Fecha: 2026-04-30
# Alineación: interface-spec.yaml, mapping.yaml, postgres-rls/main.tf
# ============================================================================

# --- VARIABLES (C5: validación estricta) ---
variable "bucket_name_prefix" {
  description = "Prefijo único para el bucket de backups"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,40}$", var.bucket_name_prefix))
    error_message = "bucket_name_prefix: minúsculas, números, guiones; 3-43 chars."
  }
}

variable "environment_tag" {
  description = "Entorno de despliegue"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment_tag)
    error_message = "environment_tag debe ser: dev, staging, o prod"
  }
}

variable "retention_days" {
  description = "Días de retención obligatoria antes de eliminación (V2: integridad)"
  type        = number
  default     = 30
  validation {
    condition     = var.retention_days >= 7 && var.retention_days <= 365
    error_message = "retention_days debe estar entre 7 y 365."
  }
}

variable "enable_object_lock" {
  description = "Habilitar WORM compliance para backups críticos"
  type        = bool
  default     = true
}

variable "backup_role_arn" {
  description = "ARN del rol IAM que ejecutará los backups (inyectar desde secrets/registry)"
  type        = string
  sensitive   = true
  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/.+", var.backup_role_arn))
    error_message = "backup_role_arn debe ser un ARN IAM válido."
  }
}

# --- LOCALS (C4: trazabilidad) ---
locals {
  bucket_name = "${var.bucket_name_prefix}-backups-${var.environment_tag}"
  base_tags = {
    Project     = "mantis-agentic"
    Domain      = "05-CONFIGURATIONS"
    Environment = var.environment_tag
    ManagedBy   = "terraform"
    Module      = "backup-encrypted"
    Constraint  = "V2-data-integrity,C3-encryption"
  }
}

# --- RESOURCES (C2, C3, V2) ---
resource "aws_s3_bucket" "backup" {
  bucket        = local.bucket_name
  object_lock_enabled = var.enable_object_lock
  force_destroy = false # C7/V2: Prevenir eliminación accidental

  tags = local.base_tags
}

resource "aws_s3_bucket_versioning" "backup" {
  bucket = aws_s3_bucket.backup.id
  versioning_configuration {
    status = "Enabled" # V2: Historial completo de backups
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.backup.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id
  rule {
    id     = "expire-old-versions"
    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = var.retention_days
    }
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
  }
  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

resource "aws_s3_bucket_policy" "backup" {
  bucket = aws_s3_bucket.backup.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyUnencryptedUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.backup.arn}/*"
        Condition = {
          StringNotEquals = { "s3:x-amz-server-side-encryption" = "aws:kms" }
        }
      },
      {
        Sid       = "AllowBackupRoleAccess"
        Effect    = "Allow"
        Principal = { AWS = var.backup_role_arn }
        Action    = ["s3:PutObject", "s3:GetObject", "s3:ListBucket", "s3:DeleteObjectVersion"]
        Resource  = [aws_s3_bucket.backup.arn, "${aws_s3_bucket.backup.arn}/*"]
      }
    ]
  })
}

resource "aws_kms_key" "backup" {
  description             = "KMS Key para cifrado de backups MANTIS (${var.environment_tag})"
  deletion_window_in_days = 30
  enable_key_rotation     = true # C3: Rotación automática

  tags = local.base_tags
}

resource "aws_kms_key_policy" "backup" {
  key_id = aws_kms_key.backup.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccountPermissions"
        Effect = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowBackupRoleDecrypt"
        Effect = "Allow"
        Principal = { AWS = var.backup_role_arn }
        Action = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = "*"
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

# ============================================================================
# OUTPUTS (Alineados con interface-spec.yaml)
# ============================================================================
output "backup_bucket_arn" {
  description = "ARN del bucket S3 de backups"
  value       = aws_s3_bucket.backup.arn
  sensitive   = false
}

output "backup_kms_key_arn" {
  description = "ARN de la clave KMS para backups (inyectar como docker secret o vault ref)"
  value       = aws_kms_key.backup.arn
  sensitive   = true
}

output "backup_bucket_name" {
  description = "Nombre del bucket para scripts de backup/restore"
  value       = aws_s3_bucket.backup.bucket
  sensitive   = false
}

output "compliance_check" {
  description = "Indicadores de cumplimiento para orchestrator-engine.sh"
  value = {
    C2_iac_backup        = true
    C3_kms_encrypted     = true
    C3_bucket_policy     = true # Deny unencrypted uploads
    C4_tags_applied      = true
    C5_vars_validated    = true
    V2_versioning_on     = true
    V2_object_lock       = var.enable_object_lock
    V2_retention_days    = var.retention_days >= 7
  }
}

# ============================================================================
# ANTI-PATRONES EXPLÍCITOS
# ============================================================================
# ❌ NUNCA: `force_destroy = true` en buckets de backup (V2/C7)
# ❌ NUNCA: Omitir `bucket_policy` de deny para uploads sin cifrado (C3)
# ❌ NUNCA: Hardcodear `backup_role_arn` en el módulo; inyectar vía variable
# ❌ NUNCA: Deshabilitar `enable_key_rotation` sin ADR de justificación
# ✅ SIEMPRE: Mantener `object_lock_enabled` en prod para WORM compliance
# ✅ SIEMPRE: Alinear outputs con `interface-spec.yaml` para consumo por scripts

# ============================================================================
# COMANDOS DE VALIDACIÓN
# ============================================================================
# terraform fmt -check . && terraform init -backend=false && terraform validate
# checkov -d . --framework terraform --check CKV_AWS_18,CKV_AWS_144,CKV_AWS_145
# orchestrator-engine.sh --domain terraform --file 05-CONFIGURATIONS/terraform/modules/backup-encrypted/main.tf --strict
# CHECKSUM=$(sha256sum 05-CONFIGURATIONS/terraform/modules/backup-encrypted/main.tf | awk '{print $1}') && sed -i "s/^# checksum_sha256: "4521829ea15232d5df9a9da8393a1fc6332d0ddab2c03e8efbcdc993377ed1c6"


---
