# ---
# artifact_id: terraform-postgres-rls-variables
# artifact_type: infrastructure_config
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C2","C3","C4","C5","V1","V2"]
# canonical_path: 05-CONFIGURATIONS/terraform/modules/postgres-rls/variables.tf
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
# checksum_sha256: "659fd10b44cd83887f9cf08e83611e30b72b776f04ea4dc9b8d5db9fec19b431"
# ---

# ============================================================================
# VARIABLES: MÓDULO POSTGRESQL + RLS + PGVECTOR (MANTIS v2.0.0)
# Propósito: Parámetros validados para provisionamiento de RDS con aislamiento de tenants y cifrado.
# Generado por: terraform-master-agent
# Fecha: 2026-04-30
# Alineación: postgres-rls/main.tf (#6), interface-spec.yaml §1, mapping.yaml
# ============================================================================

# --- IDENTIFICACIÓN & ENTORNO (C4, C5) ---
variable "db_identifier" {
  description = "Identificador único de la instancia RDS (se concatena con environment_tag en tags)"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,62}$", var.db_identifier))
    error_message = "db_identifier: minúsculas, números, guiones; 3-63 chars; iniciar con letra."
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

# --- AUTENTICACIÓN & SEGURIDAD (C3, C5) ---
variable "db_username" {
  description = "Usuario maestro de PostgreSQL (evitar nombres genéricos como 'admin' o 'root')"
  type        = string
  default     = "mantis_app"
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{2,31}$", var.db_username))
    error_message = "db_username debe iniciar con letra y contener solo alfanuméricos y guion bajo."
  }
}

variable "db_password" {
  description = "Password de la base de datos. Inyectar desde CI/CD secrets o vault (C3)"
  type        = string
  sensitive   = true
  validation {
    condition = (
      length(var.db_password) >= 16 &&
      can(regex("[A-Z]", var.db_password)) &&
      can(regex("[a-z]", var.db_password)) &&
      can(regex("[0-9]", var.db_password)) &&
      can(regex("[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>/?]", var.db_password))
    )
    error_message = "db_password: min 16 chars, requiere mayúscula, minúscula, número y símbolo."
  }
}

# --- INFRAESTRUCTURA & RED (C2, C4) ---
variable "instance_class" {
  description = "Clase de instancia RDS (ajustar según perfil de carga y V1/V3 requirements)"
  type        = string
  validation {
    condition     = can(regex("^db\\.(t[23]\\.(small|medium|large)|r[568]\\.(large|xlarge|2xlarge))$", var.instance_class))
    error_message = "instance_class debe ser db.t2/t3 o db.r5/r6/r8 válido para PostgreSQL."
  }
}

variable "vpc_id" {
  description = "ID de VPC para subnet group y security group"
  type        = string
  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "vpc_id debe seguir formato AWS vpc-xxxxx."
  }
}

variable "subnet_ids" {
  description = "Lista de subnet IDs para despliegue multi-AZ"
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "subnet_ids requiere al menos 2 subnets para alta disponibilidad (C7)."
  }
}

# --- PGVECTOR & PERFORMANCE (V1, V3) ---
variable "pgvector_enabled" {
  description = "Habilitar extensión pgvector para embeddings (V1: aislamiento lógico, V3: tuning)"
  type        = bool
  default     = true
}

variable "multi_az" {
  description = "Habilitar despliegue multi-AZ (recomendado staging/prod para resiliencia C7)"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Días de retención de backups automatizados (V2: integridad y recoverability)"
  type        = number
  default     = 7
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "backup_retention_days debe estar entre 1 y 35."
  }
}

variable "tags_extra" {
  description = "Tags adicionales para override o workload específico"
  type        = map(string)
  default     = {}
  validation {
    condition = alltrue([
      for k, v in var.tags_extra :
      can(regex("^[a-zA-Z0-9_.:/-]+$", k)) && can(regex("^[a-zA-Z0-9_.:/-]+$", v))
    ])
    error_message = "tags_extra: keys y values deben cumplir formato estándar AWS tagging."
  }
}

# --- LOCALS (C4: trazabilidad consistente) ---
locals {
  param_group_name = "mantis-${var.environment_tag}-pg-params"
  base_tags = {
    Project     = "mantis-agentic"
    Domain      = "05-CONFIGURATIONS"
    Environment = var.environment_tag
    ManagedBy   = "terraform"
    Module      = "postgres-rls"
    Constraint  = "V1-tenant-isolation,V2-data-integrity"
  }
  merged_tags = merge(local.base_tags, var.tags_extra)
}

# ============================================================================
# ANTI-PATRONES EXPLÍCITOS (C1, C3, C5)
# ============================================================================
# ❌ NUNCA: Usar `default = "..."` para `db_password` (viola C3 críticamente)
# ❌ NUNCA: Omitir `validation` blocks o usar `type = any` (viola C5)
# ❌ NUNCA: Permitir `subnet_ids < 2` en prod (viola C7 resiliencia)
# ✅ SIEMPRE: Inyectar `db_password` vía `TF_VAR_db_password` o CI/CD secrets
# ✅ SIEMPRE: Mantener `sensitive = true` explícito para evitar exposición en plan/outputs

# ============================================================================
# COMANDOS DE VALIDACIÓN
# ============================================================================
# terraform fmt -check 05-CONFIGURATIONS/terraform/modules/postgres-rls/variables.tf
# terraform init -backend=false -input=false 05-CONFIGURATIONS/terraform/modules/postgres-rls && terraform validate
# orchestrator-engine.sh --domain terraform --file 05-CONFIGURATIONS/terraform/modules/postgres-rls/variables.tf --strict
# CHECKSUM=$(sha256sum 05-CONFIGURATIONS/terraform/modules/postgres-rls/variables.tf | awk '{print $1}') && sed -i "s/^# checksum_sha256: "659fd10b44cd83887f9cf08e83611e30b72b776f04ea4dc9b8d5db9fec19b431"


---
