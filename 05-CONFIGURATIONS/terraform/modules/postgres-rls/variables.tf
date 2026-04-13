# ---
# title: "PostgreSQL RLS Module - Variables"
# version: "1.0.0"
# constraints_mapped: ["C1", "C3", "C4", "C6"]
# validation_command: "terraform validate -no-color -json"
# ---

# =============================================================================
# POSTGRESQL RLS MODULE - VARIABLES
# =============================================================================
# Variables for deploying PostgreSQL with Row Level Security (RLS) enabled.
# Enforces tenant_id isolation (C4), no hardcoded credentials (C3).

# ------------------------------
# REQUIRED CONNECTION PARAMETERS
# ------------------------------

variable "database_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "mantis_agentic"
  validation {
    condition     = length(var.database_name) > 0 && can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.database_name))
    error_message = "Database name must start with a letter and contain only alphanumeric/underscores."
  }
}

variable "admin_username" {
  description = "PostgreSQL admin username (will be created if not exists)"
  type        = string
  default     = "mantis_admin"
  sensitive   = true
}

variable "admin_password" {
  description = "PostgreSQL admin password. MUST be provided via environment variable TF_VAR_admin_password (C3)."
  type        = string
  sensitive   = true
  nullable    = false

  validation {
    condition     = var.admin_password != ""
    error_message = "Admin password cannot be empty. Use TF_VAR_admin_password."
  }
}

variable "app_username" {
  description = "Application-level username for Prisma/n8n connections"
  type        = string
  default     = "mantis_app"
  sensitive   = true
}

variable "app_password" {
  description = "Application user password. MUST be set via environment (C3)."
  type        = string
  sensitive   = true
  nullable    = false

  validation {
    condition     = var.app_password != ""
    error_message = "App password cannot be empty. Use TF_VAR_app_password."
  }
}

variable "host" {
  description = "PostgreSQL server host (C6: must be remote cloud endpoint, not localhost)"
  type        = string
  validation {
    condition     = var.host != "localhost" && var.host != "127.0.0.1"
    error_message = "PostgreSQL host must be a remote cloud endpoint (C6 violation)."
  }
}

variable "port" {
  description = "PostgreSQL server port"
  type        = number
  default     = 5432
}

variable "sslmode" {
  description = "SSL connection mode"
  type        = string
  default     = "require"
  validation {
    condition     = contains(["disable", "require", "verify-ca", "verify-full"], var.sslmode)
    error_message = "SSL mode must be one of: disable, require, verify-ca, verify-full."
  }
}

# ------------------------------
# MULTI-TENANCY CONFIGURATION (C4)
# ------------------------------

variable "tenant_schema_prefix" {
  description = "Prefix for tenant-specific schemas (e.g., 'tenant_')"
  type        = string
  default     = "tenant_"
}

variable "default_tenant_id" {
  description = "Default tenant ID for initial setup (will be replaced per-request)"
  type        = string
  default     = "tenant-00000000-0000-0000-0000-000000000000"
  validation {
    condition     = can(regex("^tenant-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.default_tenant_id))
    error_message = "Default tenant_id must match UUID prefixed with 'tenant-'."
  }
}

variable "rls_policy_enabled" {
  description = "Enable Row Level Security on all tables"
  type        = bool
  default     = true
}

variable "rls_bypass_roles" {
  description = "List of roles allowed to bypass RLS (e.g., admin, backup)"
  type        = list(string)
  default     = ["mantis_admin", "mantis_backup"]
}

# ------------------------------
# RESOURCE LIMITS (C1, C2)
# ------------------------------

variable "connection_pool_limit" {
  description = "Maximum number of database connections (C2: explicit limit)"
  type        = number
  default     = 20
  validation {
    condition     = var.connection_pool_limit >= 5 && var.connection_pool_limit <= 100
    error_message = "Connection pool limit must be between 5 and 100."
  }
}

variable "statement_timeout_ms" {
  description = "Statement timeout in milliseconds (C2)"
  type        = number
  default     = 10000
  validation {
    condition     = var.statement_timeout_ms >= 1000 && var.statement_timeout_ms <= 60000
    error_message = "Statement timeout must be between 1000ms and 60000ms."
  }
}

variable "idle_in_transaction_session_timeout_ms" {
  description = "Timeout for idle transactions (C2)"
  type        = number
  default     = 30000
}

# ------------------------------
# CONNECTION STRING GENERATION (C3)
# ------------------------------

variable "database_url_template" {
  description = "Template for DATABASE_URL environment variable. Do not hardcode secrets."
  type        = string
  default     = "postgresql://${var.app_username}:${var.app_password}@${var.host}:${var.port}/${var.database_name}?schema=public&sslmode=${var.sslmode}"
}

# ------------------------------
# MIGRATION AND SETUP
# ------------------------------

variable "run_migrations" {
  description = "Whether to run Prisma migrations automatically"
  type        = bool
  default     = false
}

variable "migrations_path" {
  description = "Path to Prisma migrations folder"
  type        = string
  default     = "../../02-SKILLS/BASE DE DATOS-RAG/prisma/migrations"
}

# ------------------------------
# TAGGING
# ------------------------------

variable "tenant_id_tag" {
  description = "Tenant ID for resource tagging"
  type        = string
  default     = var.default_tenant_id
}

# 🟢 VALIDATION: terraform fmt -check -diff 05-CONFIGURATIONS/terraform/modules/postgres-rls/variables.tf && terraform validate -no-color -json
