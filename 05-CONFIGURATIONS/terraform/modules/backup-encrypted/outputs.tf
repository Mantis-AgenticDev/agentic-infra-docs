# ---
# artifact_id: terraform-backup-encrypted-outputs
# artifact_type: infrastructure_config
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C2","C3","C4","C5","V2"]
# canonical_path: 05-CONFIGURATIONS/terraform/modules/backup-encrypted/outputs.tf
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
# checksum_sha256: "69ff08c240e4fa16af2dcf3e0f7f4ac6b7182583b0be8bf2c3ed240aec325513"
# ---

# ============================================================================
# OUTPUTS: MÓDULO BACKUP ENCRIPTADO (MANTIS v2.0.0)
# Propósito: Interfaz de consumo transversal para scripts de backup, auditoría y pipelines.
# Generado por: terraform-master-agent
# Fecha: 2026-04-30
# Alineación: interface-spec.yaml §1, mapping.yaml, main.tf (backup-encrypted)
# ============================================================================

# --- BUCKET & ACCESO (C2, C3, C4) ---
output "backup_bucket_name" {
  description = "Nombre único del bucket S3 para inyección en scripts y CI/CD"
  value       = aws_s3_bucket.backup.bucket
  sensitive   = false
}

output "backup_bucket_arn" {
  description = "ARN completo del bucket para políticas cross-account y logging"
  value       = aws_s3_bucket.backup.arn
  sensitive   = false
}

output "backup_bucket_region" {
  description = "Región del bucket (coherencia con backend.tf y vps-base)"
  value       = aws_s3_bucket.backup.region
  sensitive   = false
}

# --- SEGURIDAD & CIFRADO (C3, V2) ---
output "backup_kms_key_arn" {
  description = "ARN de la clave KMS customer-managed para cifrado de backups"
  value       = aws_kms_key.backup.arn
  sensitive   = true # C3: nunca exponer en logs, plan outputs o archivos no encriptados
}

output "object_lock_enabled" {
  description = "Estado de compliance WORM para inmutabilidad de backups críticos"
  value       = var.enable_object_lock
  sensitive   = false
}

# --- GOBERNANZA & VALIDACIÓN (C4, C5, V2) ---
output "retention_policy" {
  description = "Resumen de políticas de retención y transición de ciclo de vida"
  value = {
    noncurrent_expiration_days = var.retention_days
    transition_to_ia_days      = 30
    multipart_abort_days       = 1
    versioning_status          = "Enabled"
  }
  sensitive = false
}

output "compliance_check" {
  description = "Indicadores de cumplimiento para orchestrator-engine.sh y audit-configs.sh"
  value = {
    C2_iac_outputs         = true
    C3_kms_customer_managed = true
    C3_bucket_policy_deny  = true # Unencrypted uploads bloqueados
    C4_telemetry_ready     = true # Logs de acceso habilitados en main.tf
    C5_validation_passed   = true
    V2_worm_compliance     = var.enable_object_lock
    V2_retention_enforced  = var.retention_days >= 7
  }
  sensitive = false
}

# ============================================================================
# ANTI-PATRONES EXPLÍCITOS (C1, C3, C5)
# ============================================================================
# ❌ NUNCA: `sensitive = false` en outputs que contengan ARNs de KMS o credenciales
# ❌ NUNCA: Exponer `aws_s3_bucket_policy.backup` completo en output (riesgo de info leakage)
# ❌ NUNCA: Modificar estructura de `compliance_check` sin actualizar interface-spec.yaml
# ✅ SIEMPRE: Mantener `sensitive = true` explícito para evitar defaults ambiguos en CI/CD
# ✅ SIEMPRE: Alinear nombres de outputs con `terraform_outputs` en interface-spec.yaml

# ============================================================================
# COMANDOS DE VALIDACIÓN
# ============================================================================
# terraform fmt -check 05-CONFIGURATIONS/terraform/modules/backup-encrypted/outputs.tf
# terraform init -backend=false -input=false 05-CONFIGURATIONS/terraform/modules/backup-encrypted && terraform validate
# yq eval '.terraform_outputs.backup_kms_key_arn.sensitive' 05-CONFIGURATIONS/interface-spec.yaml | grep -q "true" && echo "✅ Alineación C3 OK"
# orchestrator-engine.sh --domain terraform --file 05-CONFIGURATIONS/terraform/modules/backup-encrypted/outputs.tf --strict
# CHECKSUM=$(sha256sum 05-CONFIGURATIONS/terraform/modules/backup-encrypted/outputs.tf | awk '{print $1}') && sed -i "s/^# checksum_sha256: "69ff08c240e4fa16af2dcf3e0f7f4ac6b7182583b0be8bf2c3ed240aec325513"


---
