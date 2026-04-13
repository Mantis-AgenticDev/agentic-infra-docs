# ---
# title: "Backup Encrypted Module - Outputs"
# version: "1.0.0"
# constraints_mapped: ["C3", "C4", "C7", "C8"]
# validation_command: "terraform validate -no-color -json"
# ---

# =============================================================================
# BACKUP ENCRYPTED MODULE - OUTPUTS
# =============================================================================
# Exposes backup configuration details, retention policies, and status.
# Never outputs encryption keys or plaintext secrets (C3).

output "backup_id" {
  description = "Unique identifier for this backup configuration"
  value       = var.backup_name
}

output "backup_source" {
  description = "Source path being backed up"
  value       = var.source_path
}

output "backup_destination_masked" {
  description = "Destination with credentials redacted (C3)"
  value       = replace(var.destination, "/:[^@]+@/", ":***REDACTED***@")
}

output "encryption_enabled" {
  description = "Whether GPG/AES encryption is applied"
  value       = var.encryption_enabled
}

output "encryption_algorithm" {
  description = "Symmetric cipher algorithm used for encryption"
  value       = var.encryption_enabled ? var.encryption_algorithm : "none"
}

output "tenant_id" {
  description = "Tenant ID associated with this backup (C4)"
  value       = var.tenant_id
}

output "schedule_cron" {
  description = "Backup frequency (cron expression)"
  value       = var.schedule_cron
}

output "retention_policy" {
  description = "Backup retention configuration"
  value = {
    days  = var.retention_days
    count = var.retention_count
  }
}

output "resource_limits" {
  description = "CPU, I/O, and bandwidth limits applied (C1, C2)"
  value = {
    cpu_quota_percent  = var.cpu_quota_percent
    io_nice_level      = var.io_nice_level
    bandwidth_limit_kb = var.bandwidth_limit_kb
  }
}

output "retry_config" {
  description = "Retry and backoff settings (C7)"
  value = {
    max_retries          = var.max_retries
    backoff_seconds      = var.retry_backoff_seconds
    exponential_backoff  = true
  }
}

output "notification_enabled" {
  description = "Whether failure notifications are configured"
  value       = var.notify_on_failure && var.notification_webhook_url != ""
}

output "structured_log_context" {
  description = "Metadata for JSON structured logging (C8)"
  value = {
    backup_name    = var.backup_name
    tenant_id      = var.tenant_id
    source_path    = var.source_path
    encryption     = var.encryption_enabled
    schedule       = var.schedule_cron
    retention_days = var.retention_days
  }
}

output "restore_command_example" {
  description = "Example command to restore from latest encrypted backup"
  value       = <<-EOT
  # Decrypt and extract the latest backup
  gpg --decrypt --batch --passphrase "\${BACKUP_PASSPHRASE}" backup.tar.gz.gpg | tar xz
  EOT
  sensitive   = true
}

output "validation_checklist" {
  description = "Manual validation steps required (C5)"
  value = <<-EOT
  1. Confirm encryption key is set via TF_VAR_encryption_key (C3).
  2. Verify cron job is active: crontab -l | grep ${var.backup_name}
  3. Test restore procedure in isolated environment.
  4. Check that backup destination includes tenant_id prefix for isolation (C4).
  5. Ensure bandwidth limit prevents resource starvation (C2).
  EOT
}

# 🟢 VALIDATION: terraform fmt -check -diff 05-CONFIGURATIONS/terraform/modules/backup-encrypted/outputs.tf && terraform validate -no-color -json
