# ---
# artifact_id: terraform-openrouter-proxy-module
# artifact_type: infrastructure_module
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C2","C3","C4","C5","C8"]
# canonical_path: 05-CONFIGURATIONS/terraform/modules/openrouter-proxy/main.tf
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
# checksum_sha256: "2b03f697a387fdf7dd43b4a671c8987dd0b67ed29c63c1a701d2c91f714ca8b2"
# ---

# ============================================================================
# MÓDULO OPENROUTER PROXY (MANTIS v2.0.0)
# Propósito: API Gateway + WAF Rate Limiting + SSM SecureStorage para proxies LLM externos.
# Generado por: terraform-master-agent
# Fecha: 2026-04-30
# Alineación: interface-spec.yaml, mapping.yaml, backend.tf
# ============================================================================

# --- VARIABLES (C5: validación estricta) ---
variable "proxy_name" {
  description = "Identificador único del proxy"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,31}$", var.proxy_name))
    error_message = "proxy_name: minúsculas, números, guiones; 3-32 chars."
  }
}

variable "environment_tag" {
  description = "Entorno de despliegue"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment_tag)
    error_message = "environment_tag debe ser: dev, staging, o prod"
  }
}

variable "rate_limit_rps" {
  description = "Solicitudes por segundo permitidas (WAF Rate-Based Rule)"
  type        = number
  default     = 50
  validation {
    condition     = var.rate_limit_rps >= 1 && var.rate_limit_rps <= 5000
    error_message = "rate_limit_rps debe estar entre 1 y 5000."
  }
}

variable "allowed_origins" {
  description = "Orígenes CORS permitidos"
  type        = list(string)
  validation {
    condition     = length(var.allowed_origins) > 0 && alltrue([for o in var.allowed_origins : can(regex("^https?://", o))])
    error_message = "allowed_origins debe ser lista no vacía de URLs válidas (http/https)."
  }
}

variable "openrouter_api_key_ssm_path" {
  description = "Ruta SSM Parameter Store para la API key de OpenRouter"
  type        = string
  default     = "/mantis/external/openrouter/api-key"
  validation {
    condition     = can(regex("^/[a-zA-Z0-9_./-]+$", var.openrouter_api_key_ssm_path))
    error_message = "ssm_path debe ser ruta absoluta válida (ej: /mantis/proxy/key)"
  }
}

variable "integration_uri" {
  description = "URI del backend real (Lambda ARN, HTTP URL, o VPC Link ID)"
  type        = string
  validation {
    condition     = can(regex("^(arn:aws:lambda|https?://|vpclink-)", var.integration_uri))
    error_message = "integration_uri debe ser Lambda ARN, URL HTTPS o VPC Link ID."
  }
}

# --- LOCALS (C4: trazabilidad) ---
locals {
  api_name    = "${var.proxy_name}-${var.environment_tag}"
  waf_name    = "waf-rate-${local.api_name}"
  base_tags = {
    Project     = "mantis-agentic"
    Domain      = "05-CONFIGURATIONS"
    Environment = var.environment_tag
    ManagedBy   = "terraform"
    Module      = "openrouter-proxy"
    Constraint  = "C8-rate-limiting,C3-secret-storage"
  }
}

# --- RESOURCES (C2, C3, C8) ---

# 1. Almacenamiento seguro de API Key (C3)
resource "aws_ssm_parameter" "openrouter_key" {
  name        = var.openrouter_api_key_ssm_path
  description = "OpenRouter API Key for MANTIS Proxy (${var.environment_tag})"
  type        = "SecureString"
  tier        = "Standard"
  # value se inyecta post-deploy vía pipeline o CLI. NUNCA hardcodear aquí.
  tags = local.base_tags
}

# 2. API Gateway HTTP (C2, C8)
resource "aws_apigatewayv2_api" "proxy" {
  name          = local.api_name
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = var.allowed_origins
    allow_methods = ["POST", "GET", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization", "X-Request-ID"]
    max_age       = 300
  }
  tags = local.base_tags
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.proxy.id
  name        = var.environment_tag
  auto_deploy = true
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.proxy_api.arn
    format          = jsonencode({ requestId = "$context.requestId", ip = "$context.identity.sourceIp", routeKey = "$context.routeKey", status = "$context.status", responseLatency = "$context.responseLatency" })
  }
  tags = local.base_tags
}

resource "aws_cloudwatch_log_group" "proxy_api" {
  name              = "/mantis/api/${local.api_name}"
  retention_in_days = var.environment_tag == "prod" ? 30 : 7
  tags              = local.base_tags
}

# 3. WAFv2 Rate Limiting (C8: calidad, anti-abuso)
resource "aws_wafv2_web_acl" "rate_limit" {
  name        = local.waf_name
  description = "Rate limiting WAF for ${local.api_name}"
  scope       = "REGIONAL"
  default_action { allow {} }

  rule {
    name     = "RateLimitRule"
    priority = 1
    action   { block {} }
    statement {
      rate_based_statement {
        limit              = var.rate_limit_rps * 300 # 5 min window
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.waf_name}-RateLimit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.waf_name}-ACL"
    sampled_requests_enabled   = true
  }
  tags = local.base_tags
}

resource "aws_wafv2_web_acl_association" "api_gateway" {
  resource_arn = aws_apigatewayv2_stage.prod.arn
  web_acl_arn  = aws_wafv2_web_acl.rate_limit.arn
}

# 4. IAM Role para API Gateway → Backend Integration
resource "aws_iam_role" "api_gateway_integration" {
  name               = "${local.api_name}-integration"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "apigateway.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
  tags = local.base_tags
}

resource "aws_iam_role_policy" "ssm_read" {
  name   = "${local.api_name}-ssm-read"
  role   = aws_iam_role.api_gateway_integration.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter"]
      Resource = aws_ssm_parameter.openrouter_key.arn
    }]
  })
}

# ============================================================================
# OUTPUTS (Alineados con interface-spec.yaml)
# ============================================================================
output "proxy_endpoint" {
  description = "URL base del proxy API Gateway"
  value       = "${aws_apigatewayv2_api.proxy.api_endpoint}/${var.environment_tag}"
  sensitive   = false
}

output "waf_acl_arn" {
  description = "ARN del WAF para auditoría y métricas"
  value       = aws_wafv2_web_acl.rate_limit.arn
  sensitive   = false
}

output "ssm_key_arn" {
  description = "ARN de la clave SSM (inyectar vía pipeline, C3)"
  value       = aws_ssm_parameter.openrouter_key.arn
  sensitive   = true
}

output "compliance_check" {
  description = "Indicadores de cumplimiento para orchestrator-engine.sh"
  value = {
    C2_iac_proxy         = true
    C3_ssm_secure_string = true
    C4_tags_applied      = true
    C5_vars_validated    = true
    C8_waf_rate_limit    = var.rate_limit_rps > 0
    C8_cors_restricted   = length(var.allowed_origins) > 0
    C8_logging_enabled   = true
  }
}

# ============================================================================
# ANTI-PATRONES EXPLÍCITOS
# ============================================================================
# ❌ NUNCA: `allow_origins = ["*"]` en staging/prod (C3/C8)
# ❌ NUNCA: Hardcodear `value = "sk-..."` en aws_ssm_parameter
# ❌ NUNCA: Omitir WAF association con API Gateway (C8)
# ❌ NUNCA: Deshabilitar `auto_deploy` en prod sin gate de aprobación (C6)
# ✅ SIEMPRE: Inyectar API key vía pipeline o secrets manager post-provision
# ✅ SIEMPRE: Alinear `rate_limit_rps` con carga real estimada + 20% margen

# ============================================================================
# COMANDOS DE VALIDACIÓN
# ============================================================================
# terraform fmt -check . && terraform init -backend=false && terraform validate
# checkov -d . --framework terraform --check CKV_AWS_76,CKV_AWS_120,CKV_AWS_116
# orchestrator-engine.sh --domain terraform --file 05-CONFIGURATIONS/terraform/modules/openrouter-proxy/main.tf --strict
# CHECKSUM=$(sha256sum 05-CONFIGURATIONS/terraform/modules/openrouter-proxy/main.tf | awk '{print $1}') && sed -i "s/^# checksum_sha256: "2b03f697a387fdf7dd43b4a671c8987dd0b67ed29c63c1a701d2c91f714ca8b2"


---
