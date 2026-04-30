# ---
# artifact_id: terraform-variables-global-mantis
# artifact_type: infrastructure_config
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C2","C3","C4","C5"]
# canonical_path: 05-CONFIGURATIONS/terraform/variables.tf
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
# checksum_sha256: "7496509f2936ef3239bce41304e6e275dc59dc55c6659d6876454b60454169f3"
# ---

# ============================================================================
# VARIABLES GLOBALES TERRAFORM (MANTIS v2.0.0)
# Propósito: Centralización de parámetros de infra con validación estricta y alineación transversal.
# Generado por: terraform-master-agent
# Fecha: 2026-04-30
# Alineación: interface-spec.yaml, mapping.yaml, backend.tf
# ============================================================================

# --- REGION & ENTORNO (C4, C5) ---
variable "aws_region" {
  description = "Región AWS para despliegue (interface-spec.yaml alignment)"
  type        = string
  default     = "sa-east-1"
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region debe seguir formato xx-region-N (ej: sa-east-1)"
  }
}

variable "environment_tag" {
  description = "Etiqueta de entorno: dev, staging, prod"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment_tag)
    error_message = "environment_tag debe ser: dev, staging, o prod"
  }
}

# --- IDENTIFICACIÓN & BACKEND (C2, C4) ---
variable "project_name" {
  description = "Identificador único del proyecto para tagging y namespaces"
  type        = string
  default     = "mantis-agentic"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,62}$", var.project_name))
    error_message = "project_name: minúsculas, números, guiones; 3-63 chars."
  }
}

variable "backend_bucket_name" {
  description = "Prefijo del bucket S3 para estado remoto"
  type        = string
  default     = "mantis-state"
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{2,62}$", var.backend_bucket_name))
    error_message = "backend_bucket_name: solo minúsculas, números, guiones; 3-63 chars."
  }
}

# --- SECRETOS CRÍTICOS (C3: inyección externa obligatoria) ---
variable "db_password" {
  description = "Password de PostgreSQL (inyectar vía CI/CD secrets o vault)"
  type        = string
  sensitive   = true
  validation {
    condition = length(var.db_password) >= 16 && can(regex("[A-Z]", var.db_password)) && can(regex("[a-z]", var.db_password)) && can(regex("[0-9]", var.db_password)) && can(regex("[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>/?]", var.db_password))
    error_message = "db_password: min 16 chars, requiere mayúscula, minúscula, número y símbolo."
  }
}

variable "qdrant_api_key" {
  description = "API Key para Qdrant cluster (inyectar como Docker secret/SSM)"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.qdrant_api_key) >= 32
    error_message = "qdrant_api_key: longitud mínima 32 caracteres."
  }
}

# --- SEGURIDAD & CI/CD (C3, C6) ---
variable "enable_oidc" {
  description = "Habilitar autenticación OIDC para CI/CD (elimina static keys)"
  type        = bool
  default     = true
}

variable "tags_extra" {
  description = "Tags adicionales para override o workload específico"
  type        = map(string)
  default     = {}
  validation {
    condition = alltrue([for k, v in var.tags_extra : can(regex("^[a-zA-Z0-9_.:/-]+$", k)) && can(regex("^[a-zA-Z0-9_.:/-]+$", v))])
    error_message = "tags_extra: keys y values deben ser alfanuméricos con caracteres básicos de tagging AWS."
  }
}

# --- LOCALS (C4: trazabilidad consistente) ---
locals {
  standard_tags = {
    Project     = var.project_name
    Domain      = "05-CONFIGURATIONS"
    Environment = var.environment_tag
    ManagedBy   = "terraform"
    Constraint  = "C4-traceability"
  }
  merged_tags = merge(local.standard_tags, var.tags_extra)
}

# --- OUTPUTS (Auditoría sin exposición de secrets) ---
output "global_variables_summary" {
  description = "Resumen no sensible de variables globales para auditoría"
  value = {
    aws_region      = var.aws_region
    environment     = var.environment_tag
    project         = var.project_name
    oidc_enabled    = var.enable_oidc
    tags_merged     = length(local.merged_tags)
  }
  sensitive = false
}

# ============================================================================
# ANTI-PATRONES EXPLÍCITOS
# ============================================================================
# ❌ NUNCA: Usar `default = "..."` para variables sensibles (viola C3)
# ❌ NUNCA: Omitir `validation` blocks en nuevas variables globales (viola C5)
# ❌ NUNCA: Hardcodear regiones o entornos en módulos hijos; pasar siempre via vars
# ✅ SIEMPRE: Inyectar `db_password` y `qdrant_api_key` vía `TF_VAR_` o CI/CD secrets
# ✅ SIEMPRE: Mantener `sensitive = true` para evitar logs o outputs en texto plano

# ============================================================================
# COMANDOS DE VALIDACIÓN
# ============================================================================
# terraform fmt -check 05-CONFIGURATIONS/terraform/variables.tf
# terraform init -backend=false -input=false 05-CONFIGURATIONS/terraform && terraform validate
# orchestrator-engine.sh --domain terraform --file 05-CONFIGURATIONS/terraform/variables.tf --strict
# CHECKSUM=$(sha256sum 05-CONFIGURATIONS/terraform/variables.tf | awk '{print $1}') && sed -i "s/^# checksum_sha256: "7496509f2936ef3239bce41304e6e275dc59dc55c6659d6876454b60454169f3"


---
