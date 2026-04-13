# ---
# title: "Backup Encrypted Module - Variables"
# version: "1.0.0"
# constraints_mapped: ["C1", "C3", "C4", "C7"]
# validation_command: "terraform validate -no-color -json"
# ---

# =============================================================================
# BACKUP ENCRYPTED MODULE - VARIABLES
# =============================================================================
# Variables for configuring encrypted backups (rsync-automation, backup-encryption).
# Enforces tenant isolation (C4) and no hardcoded secrets (C3).

# ------------------------------
# REQUIRED BACKUP TARGET
# ------------------------------

variable "backup_name" {
  description = "Unique identifier for this backup configuration"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.backup_name))
    error_message = "Backup name must be lowercase alphanumeric with hyphens."
  }
}

variable "source_path" {
  description = "Absolute path to the directory or file to backup"
  type        = string
  validation {
    condition     = can(regex("^/", var.source_path))
    error_message = "Source path must be absolute."
  }
}

variable "destination" {
  description = "Remote destination (rsync URL, S3 bucket, or SSH host:path)"
  type        = string
  validation {
    condition     = length(var.destination) > 0
    error_message = "Destination cannot be empty."
  }
}

variable "tenant_id" {
  description = "Tenant ID for encryption context and isolation (C4)"
  type        = string
  validation {
    condition     = can(regex("^tenant-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.tenant_id))
    error_message = "tenant_id must be UUID prefixed with 'tenant-'."
  }
}

# ------------------------------
# ENCRYPTION SETTINGS
# ------------------------------

variable "encryption_enabled" {
  description = "Enable GPG or AES encryption on backup archives"
  type        = bool
  default     = true
}

variable "encryption_key" {
  description = "Encryption passphrase or key. MUST be set via TF_VAR_encryption_key (C3)."
  type        = string
  sensitive   = true
  nullable    = false
  validation {
    condition     = var.encryption_enabled ? length(var.encryption_key) >= 32 : true
    error_message = "Encryption key must be at least 32 characters when encryption is enabled."
  }
}

variable "encryption_algorithm" {
  description = "GPG symmetric cipher algorithm"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "AES128", "TWOFISH"], var.encryption_algorithm)
    error_message = "Encryption algorithm must be one of AES256, AES128, TWOFISH."
  }
}

variable "recipient_key_id" {
  description = "Optional GPG recipient key ID for asymmetric encryption"
  type        = string
  default     = ""
}

# ------------------------------
# SCHEDULE AND RETENTION (C7)
# ------------------------------

variable "schedule_cron" {
  description = "Cron expression for backup frequency"
  type        = string
  default     = "0 2 * * *" # Daily at 2 AM
  validation {
    condition     = can(regex("^(@(hourly|daily|weekly|monthly|yearly|reboot))|((((\\d+,)+\\d+|(\\d+(\\/|-)\\d+)|\\d+|\\*) ?){5,7})$", var.schedule_cron))
    error_message = "Invalid cron expression."
  }
}

variable "retention_days" {
  description = "Number of days to retain encrypted backups"
  type        = number
  default     = 30
  validation {
    condition     = var.retention_days >= 1 && var.retention_days <= 365
    error_message = "Retention days must be between 1 and 365."
  }
}

variable "retention_count" {
  description = "Maximum number of backup files to keep (alternative to retention_days)"
  type        = number
  default     = 0
  validation {
    condition     = var.retention_count >= 0
    error_message = "Retention count cannot be negative."
  }
}

# ------------------------------
# RESOURCE LIMITS (C1, C2)
# ------------------------------

variable "cpu_quota_percent" {
  description = "CPU limit for backup process (percentage of one core)"
  type        = number
  default     = 25
  validation {
    condition     = var.cpu_quota_percent >= 10 && var.cpu_quota_percent <= 100
    error_message = "CPU quota must be between 10% and 100%."
  }
}

variable "io_nice_level" {
  description = "I/O scheduling priority (ionice class/idle)"
  type        = number
  default     = 3 # Idle class
  validation {
    condition     = var.io_nice_level >= 0 && var.io_nice_level <= 7
    error_message = "I/O nice level must be between 0 and 7."
  }
}

variable "bandwidth_limit_kb" {
  description = "Limit rsync bandwidth (KB/s, 0 = unlimited)"
  type        = number
  default     = 1024 # 1 MB/s
  validation {
    condition     = var.bandwidth_limit_kb >= 0
    error_message = "Bandwidth limit cannot be negative."
  }
}

# ------------------------------
# RETRY AND BACKOFF (C7)
# ------------------------------

variable "max_retries" {
  description = "Maximum number of retry attempts on failure"
  type        = number
  default     = 3
  validation {
    condition     = var.max_retries >= 0 && var.max_retries <= 10
    error_message = "Max retries must be between 0 and 10."
  }
}

variable "retry_backoff_seconds" {
  description = "Initial backoff delay in seconds"
  type        = number
  default     = 60
  validation {
    condition     = var.retry_backoff_seconds >= 10
    error_message = "Retry backoff must be at least 10 seconds."
  }
}

# ------------------------------
# SSH CONNECTION (if rsync over SSH)
# ------------------------------

variable "ssh_key_path" {
  description = "Path to SSH private key for rsync authentication"
  type        = string
  default     = "~/.ssh/id_ed25519"
  sensitive   = true
}

variable "ssh_known_hosts" {
  description = "SSH known hosts entry for destination host verification"
  type        = string
  default     = ""
}

# ------------------------------
# NOTIFICATIONS
# ------------------------------

variable "notify_on_failure" {
  description = "Send notification on backup failure (telegram, email)"
  type        = bool
  default     = true
}

variable "notification_webhook_url" {
  description = "Webhook URL for failure notifications (Telegram bot or similar)"
  type        = string
  default     = ""
  sensitive   = true
}

# ------------------------------
# TAGGING AND LABELING
# ------------------------------

variable "tags" {
  description = "Additional tags for backup identification"
  type        = map(string)
  default     = {}
}

# 🟢 VALIDATION: terraform fmt -check -diff 05-CONFIGURATIONS/terraform/modules/backup-encrypted/variables.tf && terraform validate -no-color -json
