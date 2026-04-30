# ---
# artifact_id: terraform-openrouter-proxy-variables
# artifact_type: infrastructure_config
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C2","C3","C4","C5"]
# canonical_path: 05-CONFIGURATIONS/terraform/modules/openrouter-proxy/variables.tf
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
# checksum_sha256: "4ff3c46d92910642a96bf082d660a32f13963f2b409cc2ac8d97c8640aee8971"
# ---

# ============================================================================
# VARIABLES: MÓDULO OPENROUTER PROXY (MANTIS v2.0.0)
# Propósito: Parámetros validados para configuración de API Gateway, WAF y SSM.
# Generado por: terraform-master-agent
# Fecha: 2026-04-30
# Alineación: openrouter-proxy/main.tf (#19), interface-spec.yaml, mapping.yaml
# ============================================================================

# --- IDENTIFICACIÓN & ENTORNO (C4, C5) ---
variable "proxy_name" {
  description = "Identificador único para el proxy (se concatena con environment_tag)"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,31}$", var.proxy_name))
    error_message = "proxy_name: minúsculas, números, guiones; 3-32 chars; iniciar con letra."
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

# --- PERFORMANCE & SEGURIDAD (C5, C8) ---
variable "rate_limit_rps" {
  description = "Solicitudes por segundo permitidas por IP (WAF Rate-Based Rule)"
  type        = number
  default     = 50
  validation {
    condition     = var.rate_limit_rps >= 1 && var.rate_limit_rps <= 5000
    error_message = "rate_limit_rps debe estar entre 1 y 5000."
  }
}

variable "allowed_origins" {
  description = "Lista de orígenes CORS permitidos"
  type        = list(string)
  validation {
    condition = length(var.allowed_origins) > 0 && alltrue([
      for o in var.allowed_origins : can(regex("^https?://[a-zA-Z0-9.-]+(:[0-9]+)?$", o))
    ])
    error_message = "allowed_origins debe ser lista no vacía de URLs HTTP/HTTPS válidas."
  }
}

# --- INTEGRACIÓN & SECRETS (C3, C5) ---
variable "openrouter_api_key_ssm_path" {
  description = "Ruta SSM Parameter Store para la API key de OpenRouter (SecureString)"
  type        = string
  default     = "/mantis/external/openrouter/api-key"
  validation {
    condition     = can(regex("^/[a-zA-Z0-9_./-]+$", var.openrouter_api_key_ssm_path))
    error_message = "ssm_path debe ser ruta absoluta válida (ej: /mantis/external/service/key)"
  }
}

variable "integration_uri" {
  description = "URI del backend real (Lambda ARN, URL HTTPS, o VPC Link ID)"
  type        = string
  validation {
    condition = can(regex("^(arn:aws:lambda|https?://|vpclink-)", var.integration_uri))
    error_message = "integration_uri debe ser Lambda ARN, URL HTTPS o VPC Link ID."
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
  api_name = "${var.proxy_name}-${var.environment_tag}"
  waf_name = "waf-rate-${local.api_name}"
  base_tags = {
    Project     = "mantis-agentic"
    Domain      = "05-CONFIGURATIONS"
    Environment = var.environment_tag
    ManagedBy   = "terraform"
    Module      = "openrouter-proxy"
    Constraint  = "C8-rate-limiting,C3-secret-storage"
  }
}

# ============================================================================
# ANTI-PATRONES EXPLÍCITOS (C1, C3, C5)
# ============================================================================
# ❌ NUNCA: `allowed_origins = ["*"]` en staging/prod (viola C3/C8)
# ❌ NUNCA: Hardcodear `default = "sk-..."` en variables de API keys
# ❌ NUNCA: Omitir `validation` blocks o usar tipos `any` (viola C5)
# ✅ SIEMPRE: Inyectar `integration_uri` y `ssm_path` vía CI/CD o tfvars
# ✅ SIEMPRE: Mantener `sensitive = true` en outputs derivados de estas variables

# ============================================================================
# COMANDOS DE VALIDACIÓN
# ============================================================================
# terraform fmt -check 05-CONFIGURATIONS/terraform/modules/openrouter-proxy/variables.tf
# terraform init -backend=false -input=false 05-CONFIGURATIONS/terraform/modules/openrouter-proxy && terraform validate
# orchestrator-engine.sh --domain terraform --file 05-CONFIGURATIONS/terraform/modules/openrouter-proxy/variables.tf --strict
# CHECKSUM=$(sha256sum 05-CONFIGURATIONS/terraform/modules/openrouter-proxy/variables.tf | awk '{print $1}') && sed -i "s/^# checksum_sha256: "4ff3c46d92910642a96bf082d660a32f13963f2b409cc2ac8d97c8640aee8971"


---
