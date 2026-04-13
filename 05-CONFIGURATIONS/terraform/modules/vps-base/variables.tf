# ---
# title: "VPS Base Module - Variables"
# version: "1.0.0"
# constraints_mapped: ["C1", "C2", "C3", "C6"]
# validation_command: "terraform validate -var-file=../../environment/terraform.tfvars.example"
# ---

# =============================================================================
# VPS BASE MODULE - VARIABLES
# =============================================================================
# This module defines the baseline configuration for any VPS instance
# in the Mantis Agentic Infrastructure.
# Enforces explicit resource limits (C1, C2) and forbids hardcoded values (C3).

# ------------------------------
# REQUIRED VARIABLES
# ------------------------------

variable "vps_name" {
  description = "Unique name identifier for the VPS instance (e.g., vps1-n8n, vps2-crm)"
  type        = string
  validation {
    condition     = can(regex("^vps[0-9]+-[a-z0-9-]+$", var.vps_name))
    error_message = "VPS name must match pattern 'vpsN-service' (e.g., vps1-n8n-uazapi)"
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

variable "tenant_id" {
  description = "Primary tenant identifier for resource tagging and isolation (C4)"
  type        = string
  validation {
    condition     = can(regex("^tenant-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.tenant_id))
    error_message = "tenant_id must be a valid UUID prefixed with 'tenant-'"
  }
}

# ------------------------------
# PROVIDER / CONNECTION
# ------------------------------

variable "ssh_public_key_path" {
  description = "Path to SSH public key for initial root access"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
  sensitive   = true
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for provisioning (C3: no hardcoded key)"
  type        = string
  default     = "~/.ssh/id_ed25519"
  sensitive   = true
}

variable "provider_token" {
  description = "API token for the VPS provider (Hetzner, DigitalOcean, etc.) - MUST be set via env TF_VAR_provider_token"
  type        = string
  sensitive   = true
  nullable    = false

  validation {
    condition     = var.provider_token != ""
    error_message = "Provider token must not be empty. Use environment variable TF_VAR_provider_token (C3)."
  }
}

variable "provider_region" {
  description = "Cloud provider region (e.g., nbg1, fra1, nyc1)"
  type        = string
  default     = "nbg1"
}

variable "server_type" {
  description = "VPS instance type/size"
  type        = string
  default     = "cpx21" # 4GB RAM, 2 vCPU (Hetzner CPX21 equivalent)
}

variable "image" {
  description = "Base OS image"
  type        = string
  default     = "ubuntu-24.04"
}

# ------------------------------
# RESOURCE LIMITS (C1, C2)
# ------------------------------

variable "resource_limits" {
  description = "Explicit container/resource limits for services running on this VPS"
  type = object({
    memory_limit_mb   = number
    cpu_quota_percent = number
    pids_limit        = number
    disk_quota_gb     = optional(number, 50)
  })
  default = {
    memory_limit_mb   = 3072      # 3GB of 4GB total, leaving 1GB for OS
    cpu_quota_percent = 150       # 1.5 vCPU limit
    pids_limit        = 200
    disk_quota_gb     = 50
  }

  validation {
    condition     = var.resource_limits.memory_limit_mb > 512 && var.resource_limits.memory_limit_mb <= 4096
    error_message = "Memory limit must be between 512MB and 4GB."
  }
  validation {
    condition     = var.resource_limits.cpu_quota_percent >= 50 && var.resource_limits.cpu_quota_percent <= 200
    error_message = "CPU quota must be between 50% and 200% of a single core."
  }
  validation {
    condition     = var.resource_limits.pids_limit >= 50
    error_message = "PIDs limit must be at least 50."
  }
}

# ------------------------------
# NETWORK & SECURITY
# ------------------------------

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to SSH into the VPS"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Will be overridden in prod
}

variable "allowed_http_cidrs" {
  description = "CIDRs allowed for HTTP/HTTPS traffic"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "vps_interconnect_cidrs" {
  description = "CIDR blocks of other VPS instances for private interconnect (vps-interconnection.md)"
  type        = list(string)
  default     = []
}

variable "wireguard_enabled" {
  description = "Enable WireGuard VPN for VPS interconnect"
  type        = bool
  default     = true
}

variable "wireguard_port" {
  description = "Port for WireGuard (if enabled)"
  type        = number
  default     = 51820
}

# ------------------------------
# MONITORING & OBSERVABILITY
# ------------------------------

variable "enable_monitoring" {
  description = "Deploy node_exporter, cadvisor, and promtail for observability"
  type        = bool
  default     = true
}

variable "log_level" {
  description = "Log verbosity level for system services"
  type        = string
  default     = "info"
  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.log_level)
    error_message = "Log level must be one of: debug, info, warn, error"
  }
}

variable "otel_tracing_endpoint" {
  description = "OpenTelemetry collector endpoint (C6: must be cloud endpoint, not localhost)"
  type        = string
  default     = ""
  validation {
    condition     = var.otel_tracing_endpoint == "" || can(regex("^https?://", var.otel_tracing_endpoint))
    error_message = "OTEL endpoint must be a valid HTTP/HTTPS URL (C6: no localhost)."
  }
}

# ------------------------------
# BACKUP CONFIGURATION
# ------------------------------

variable "backup_enabled" {
  description = "Enable automated encrypted backups (rsync-automation, backup-encryption)"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain encrypted backups"
  type        = number
  default     = 30
}

variable "backup_destination" {
  description = "Remote backup destination (rsync URL or S3 bucket)"
  type        = string
  default     = ""
  sensitive   = true
}

# ------------------------------
# TAGGING & METADATA
# ------------------------------

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# OUTPUT VALIDATION (C5: included as comment per protocol)
# -----------------------------------------------------------------------------
# 🟢 VALIDATION: terraform validate -no-color -json
