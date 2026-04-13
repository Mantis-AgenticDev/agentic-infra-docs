# ---
# title: "PostgreSQL RLS Module - Outputs"
# version: "1.0.0"
# constraints_mapped: ["C3", "C4", "C8"]
# validation_command: "terraform validate -no-color -json"
# ---

# =============================================================================
# POSTGRESQL RLS MODULE - OUTPUTS
# =============================================================================
# Outputs for PostgreSQL RLS configuration. Contains connection strings
# (without secrets) and RLS enforcement status.

output "database_name" {
  description = "Provisioned database name"
  value       = var.database_name
}

output "fully_qualified_host" {
  description = "Full PostgreSQL host:port combination"
  value       = "${var.host}:${var.port}"
}

output "app_connection_string_safe" {
  description = "Safe connection string for application use (password masked, C3)"
  value       = "postgresql://${var.app_username}:***REDACTED***@${var.host}:${var.port}/${var.database_name}?schema=public&sslmode=${var.sslmode}"
}

output "admin_connection_string_safe" {
  description = "Safe admin connection string for migrations (password masked)"
  value       = "postgresql://${var.admin_username}:***REDACTED***@${var.host}:${var.port}/postgres?sslmode=${var.sslmode}"
}

output "rls_enabled" {
  description = "Whether Row Level Security is active on all tables"
  value       = var.rls_policy_enabled
}

output "tenant_id_default" {
  description = "Default tenant ID used for initial schema setup"
  value       = var.default_tenant_id
}

output "connection_pool_settings" {
  description = "Resource limits applied to connection pool (C1, C2)"
  value = {
    max_connections                = var.connection_pool_limit
    statement_timeout_ms           = var.statement_timeout_ms
    idle_in_transaction_timeout_ms = var.idle_in_transaction_session_timeout_ms
  }
}

output "rls_bypass_roles" {
  description = "Roles with RLS bypass privilege (use with caution)"
  value       = var.rls_bypass_roles
  sensitive   = true
}

output "prisma_datasource_template" {
  description = "Prisma schema datasource block snippet"
  value       = <<-EOT
  datasource db {
    provider = "postgresql"
    url      = env("DATABASE_URL")
  }
  EOT
}

output "migration_command_example" {
  description = "Example command to run migrations (C5 validation reminder)"
  value       = "DATABASE_URL='postgresql://...' npx prisma migrate deploy"
}

output "structured_log_attributes" {
  description = "Attributes for structured JSON logging (C8)"
  value = {
    database_host    = var.host
    database_name    = var.database_name
    rls_enabled      = var.rls_policy_enabled
    connection_limit = var.connection_pool_limit
    ssl_mode         = var.sslmode
  }
}

# -----------------------------------------------------------------------------
# SENSITIVE OUTPUTS (accessible only via terraform output -json)
# -----------------------------------------------------------------------------
output "app_username" {
  description = "Application username (for reference only)"
  value       = var.app_username
  sensitive   = true
}

output "app_password" {
  description = "Application password (SENSITIVE)"
  value       = var.app_password
  sensitive   = true
}

# -----------------------------------------------------------------------------
# VALIDATION SUMMARY (C5)
# -----------------------------------------------------------------------------
output "validation_checklist" {
  description = "Manual validation steps required"
  value = <<-EOT
  1. Ensure tenant_id is passed in all queries (C4).
  2. Verify RLS policies with check-rls.sh.
  3. Confirm no hardcoded credentials in DATABASE_URL (C3).
  4. Test connection pool limits under load.
  EOT
}

# 🟢 VALIDATION: terraform fmt -check -diff 05-CONFIGURATIONS/terraform/modules/postgres-rls/outputs.tf && terraform validate -no-color -json
