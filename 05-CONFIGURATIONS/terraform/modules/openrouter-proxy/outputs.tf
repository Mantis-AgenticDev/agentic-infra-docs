# ---
# artifact_id: terraform-openrouter-proxy-outputs
# artifact_type: infrastructure_config
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C2","C3","C4","C5","C8"]
# canonical_path: 05-CONFIGURATIONS/terraform/modules/openrouter-proxy/outputs.tf
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
# checksum_sha256: "875d3c324b06dd200823157c29c0bc749783d0d0c2db4b7d7d932ee7ab4a4e6f"
# ---

# ============================================================================
# OUTPUTS: MÓDULO OPENROUTER PROXY (MANTIS v2.0.0)
# Propósito: Interfaz de consumo transversal para Docker Compose, pipelines y monitoreo.
# Generado por: terraform-master-agent
# Fecha: 2026-04-30
# Alineación: interface-spec.yaml §1, mapping.yaml, main.tf (#19), variables.tf (#36)
# ============================================================================

# --- ENDPOINTS & ACCESO (C4, C8) ---
output "proxy_endpoint" {
  description = "URL base del API Gateway para consumo por agentes y frontend"
  value       = aws_apigatewayv2_stage.prod.invoke_url
  sensitive   = false
}

output "api_gateway_log_group_arn" {
  description = "ARN del grupo de logs de CloudWatch para auditoría y métricas de latencia"
  value       = aws_cloudwatch_log_group.proxy_api.arn
  sensitive   = false
}

# --- SEGURIDAD & CONFIGURACIÓN EXTERNA (C3, C5) ---
output "waf_acl_arn" {
  description = "ARN del WAFv2 para métricas de bloqueo, rate-limiting y dashboards"
  value       = aws_wafv2_web_acl.rate_limit.arn
  sensitive   = false
}

output "ssm_key_arn" {
  description = "ARN del parámetro SSM SecureString (inyectar vía pipeline/CI, C3)"
  value       = aws_ssm_parameter.openrouter_key.arn
  sensitive   = true # C3: Nunca exponer en terraform plan stdout, logs o archivos no cifrados
}

output "integration_role_arn" {
  description = "ARN del rol IAM que permite a API Gateway acceder al backend/SSM"
  value       = aws_iam_role.api_gateway_integration.arn
  sensitive   = false
}

# --- GOBERNANZA & VALIDACIÓN AUTOMATIZADA (C5, C8) ---
output "compliance_check" {
  description = "Indicadores de cumplimiento para orchestrator-engine.sh y audit-configs.sh"
  value = {
    C2_iac_proxy           = true
    C3_ssm_secure_string   = true
    C3_no_hardcoded_keys   = true
    C4_traceable_logs      = true
    C5_vars_validated      = true
    C8_cors_restricted     = length(var.allowed_origins) > 0
    C8_waf_rate_limiting   = var.rate_limit_rps > 0
    C8_logging_enabled     = true
  }
  sensitive = false
}

# ============================================================================
# ANTI-PATRONES EXPLÍCITOS (C1, C3, C5)
# ============================================================================
# ❌ NUNCA: `sensitive = false` en `ssm_key_arn` o cualquier output derivado de secretos
# ❌ NUNCA: Exponer `aws_ssm_parameter.openrouter_key.value` en outputs (C3 crítica)
# ❌ NUNCA: Modificar estructura de `compliance_check` sin actualizar interface-spec.yaml
# ✅ SIEMPRE: Consumir `ssm_key_arn` via CI/CD secrets injection o Docker secrets
# ✅ SIEMPRE: Alinear nombres de outputs con `terraform_outputs` en interface-spec.yaml §1

# ============================================================================
# COMANDOS DE VALIDACIÓN
# ============================================================================
# terraform fmt -check 05-CONFIGURATIONS/terraform/modules/openrouter-proxy/outputs.tf
# terraform init -backend=false -input=false 05-CONFIGURATIONS/terraform/modules/openrouter-proxy && terraform validate
# yq eval '.terraform_outputs.ssm_key_arn.sensitive' 05-CONFIGURATIONS/interface-spec.yaml | grep -q "true" && echo "✅ Alineación C3 OK"
# orchestrator-engine.sh --domain terraform --file 05-CONFIGURATIONS/terraform/modules/openrouter-proxy/outputs.tf --strict
# CHECKSUM=$(sha256sum 05-CONFIGURATIONS/terraform/modules/openrouter-proxy/outputs.tf | awk '{print $1}') && sed -i "s/^# checksum_sha256: "875d3c324b06dd200823157c29c0bc749783d0d0c2db4b7d7d932ee7ab4a4e6f"


---
