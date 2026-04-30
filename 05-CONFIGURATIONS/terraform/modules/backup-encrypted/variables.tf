# ---
# artifact_id: terraform-backup-encrypted-variables
# artifact_type: infrastructure_config
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C2","C3","C4","C5","V2"]
# canonical_path: 05-CONFIGURATIONS/terraform/modules/backup-encrypted/variables.tf
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
# checksum_sha256: "83eef6710959f3486418c3868e0257a39b2fcb92e9d22b419ae79eb0fa9d2e56"
# ---

# ============================================================================
# VARIABLES: MÓDULO BACKUP ENCRIPTADO (MANTIS v2.0.0)
# Propósito: Parámetros de configuración con validación estricta para el módulo de backups.
# Generado por: terraform-master-agent
# Fecha: 2026-04-30
# Alineación: main.tf del módulo, interface-spec.yaml, mapping.yaml
# ============================================================================

# --- IDENTIFICACIÓN & ENTORNO (C4, C5) ---
variable "bucket_name_prefix" {
  description = "Prefijo único para el bucket de backups (se concatena con environment_tag)"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,40}$", var.bucket_name_prefix))
    error_message = "bucket_name_prefix: minúsculas, números, guiones; 3-43 chars; iniciar con letra."
  }
}

variable "environment_tag" {
  description = "Entorno de despliegue: dev, staging, prod"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment_tag)
    error_message = "environment_tag debe ser: dev, staging, o prod"
  }
}

# --- RETENCIÓN & COMPLIANCE (V2: integridad de datos) ---
variable "retention_days" {
  description = "Días de retención obligatoria antes de eliminación de versiones antiguas"
  type        = number
  default     = 30
  validation {
    condition     = var.retention_days >= 7 && var.retention_days <= 365
    error_message = "retention_days debe estar entre 7 y 365 (mínimo 7 para compliance básico)"
  }
}

variable "enable_object_lock" {
  description = "Habilitar WORM (Write-Once-Read-Many) para backups críticos"
  type        = bool
  default     = true
}

# --- SEGURIDAD & ACCESO (C3) ---
variable "backup_role_arn" {
  description = "ARN del rol IAM que ejecutará los backups (inyectar desde secrets/registry)"
  type        = string
  sensitive   = true
  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/.+", var.backup_role_arn))
    error_message = "backup_role_arn debe ser un ARN IAM válido de la forma arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME"
  }
}

variable "kms_key_rotation_enabled" {
  description = "Habilitar rotación automática de la clave KMS (C3: best practice)"
  type        = bool
  default     = true
}

# --- TAGS & TRAZABILIDAD (C4) ---
variable "tags_extra" {
  description = "Tags adicionales para override o workload específico"
  type        = map(string)
  default     = {}
  validation {
    condition = alltrue([
      for k, v in var.tags_extra :
      can(regex("^[a-zA-Z0-9_.:/-]+$", k)) && can(regex("^[a-zA-Z0-9_.:/-]+$", v))
    ])
    error_message = "tags_extra: keys y values deben ser alfanuméricos con caracteres básicos de tagging AWS"
  }
}

# --- LOCALS (C4: consistencia de trazabilidad) ---
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
  merged_tags = merge(local.base_tags, var.tags_extra)
}

# ============================================================================
# ANTI-PATRONES EXPLÍCITOS (C1, C3, C5)
# ============================================================================
# ❌ NUNCA: Usar `default = "hardcoded-value"` para variables sensibles como backup_role_arn
# ❌ NUNCA: Omitir `validation` blocks en nuevas variables (viola C5)
# ❌ NUNCA: Permitir `retention_days < 7` en staging/prod (viola V2 compliance mínimo)
# ✅ SIEMPRE: Inyectar `backup_role_arn` vía `TF_VAR_` o CI/CD secrets, nunca hardcodear
# ✅ SIEMPRE: Mantener `sensitive = true` para evitar exposición en logs o plan outputs

# ============================================================================
# COMANDOS DE VALIDACIÓN
# ============================================================================
# terraform fmt -check 05-CONFIGURATIONS/terraform/modules/backup-encrypted/variables.tf
# terraform init -backend=false -input=false 05-CONFIGURATIONS/terraform/modules/backup-encrypted && terraform validate
# orchestrator-engine.sh --domain terraform --file 05-CONFIGURATIONS/terraform/modules/backup-encrypted/variables.tf --strict
# CHECKSUM=$(sha256sum 05-CONFIGURATIONS/terraform/modules/backup-encrypted/variables.tf | awk '{print $1}') && sed -i "s/^# checksum_sha256: "83eef6710959f3486418c3868e0257a39b2fcb92e9d22b419ae79eb0fa9d2e56"


---
