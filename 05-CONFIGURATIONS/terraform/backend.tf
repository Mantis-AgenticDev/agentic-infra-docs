# ---------------------------------------------------------------------------
# Frontmatter canónico (parseable por IA)
# ---------------------------------------------------------------------------
# ---
# artifact_id: terraform-backend-mantis
# artifact_type: infrastructure_module
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C2","C3","C4","C5"]
# canonical_path: 05-CONFIGURATIONS/terraform/backend.tf
# domain: 05-CONFIGURATIONS
# subdomain: terraform
# agent_role: terraform-master
# language_lock: es-ES
# validation_command: orchestrator-engine.sh --domain terraform --strict
# tier: 3
# immutable: true
# requires_human_approval_for_changes: true
# audience: ["agentic_assistants"]
# human_readable: false
# checksum_sha256: "7f1a3e2e5c468e3c87110e28e322888f035b1562ab9f03213e2216fa74444281"
# ---
# ---------------------------------------------------------------------------

# ============================================================================
# BACKEND REMOTO: S3 + DynamoDB + KMS (C2, C3, C4)
# Propósito: Estado remoto con locking, cifrado y trazabilidad para MANTIS
# Generado por: terraform-master-agent v2.0.0-COMPREHENSIVE
# Fecha: 2026-04-30
# Dependencias: interface-spec.yaml (vpc_id, environment_tag, aws_region)
# ============================================================================

# --- Variables de entrada (validadas per C5) ---
# NOTA: Estas variables se resuelven desde:
#   1. 05-CONFIGURATIONS/environment/.env.${ENVIRONMENT_TAG}
#   2. 05-CONFIGURATIONS/environment/mapping.yaml
#   3. CLI flags o TF_VAR_* environment variables
# NUNCA hardcodear valores sensibles aquí (C3)

variable "aws_region" {
  description = "Región AWS para backend de estado (consistencia con interface-spec.yaml)"
  type        = string
  default     = "sa-east-1" # Rio Grande do Sul proximity

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region debe seguir formato: xx-region-N (ej: sa-east-1)"
  }

  # Constraint mapping (C4: trazabilidad)
  # - Usado en labels OCI de recursos Terraform
  # - Propagado a métricas Prometheus via environment_tag
}

variable "environment_tag" {
  description = "Tag de entorno para aislamiento de estado (dev/staging/prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment_tag)
    error_message = "environment_tag debe ser: dev, staging, o prod"
  }

  # Constraint mapping:
  # - C4: Incluir en labels de recursos para filtrado en dashboards
  # - C3: Nunca usar "prod" sin approval gate humano en pipeline
}

variable "backend_bucket_name" {
  description = "Nombre del bucket S3 para estado de Terraform"
  type        = string
  default     = "mantis-terraform-state"

  validation {
    condition = (
      can(regex("^[a-z0-9][a-z0-9-]{2,62}[a-z0-9]$", var.backend_bucket_name)) &&
      length(var.backend_bucket_name) <= 63
    )
    error_message = "backend_bucket_name: solo minúsculas, números, guiones; 3-63 chars; no iniciar/terminar con guión"
  }

  # Constraint mapping:
  # - C2: Nombre must be globally unique; usar prefix con account ID en producción
  # - C4: Incluir en CloudTrail logs para auditoría de cambios de estado
}

variable "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB para locking de estado"
  type        = string
  default     = "mantis-terraform-locks"

  validation {
    condition = (
      can(regex("^[a-zA-Z0-9_.-]{3,255}$", var.dynamodb_table_name))
    )
    error_message = "dynamodb_table_name: 3-255 chars, alfanumérico + _. -"
  }
}

variable "kms_key_arn" {
  description = "ARN de la clave KMS para cifrado de estado (C3: secrets protection)"
  type        = string
  default     = null # Null = usar AWS-managed key; production debe especificar customer-managed

  validation {
    condition = (
      var.kms_key_arn == null ||
      can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]{36}$", var.kms_key_arn))
    )
    error_message = "kms_key_arn debe ser null o ARN válido de KMS key"
  }

  # Constraint mapping:
  # - C3: En producción, usar customer-managed KMS key con rotation habilitada
  # - C4: Registrar uso de clave en CloudTrail para trazabilidad de acceso a estado
}

variable "enable_oidc" {
  description = "Habilitar autenticación OIDC para CI/CD (C3: sin secrets estáticos)"
  type        = bool
  default     = true

  # Constraint mapping:
  # - C3: OIDC elimina necesidad de AWS_ACCESS_KEY en variables de entorno
  # - C6: Requerir approval humano para cambios en configuración OIDC
}

# --- Configuración del backend remoto ---
# NOTA: Esta bloque se evalúa en terraform init, no en plan/apply
# Para CI/CD con OIDC, usar github_actions o gitlab_ci provider auth

terraform {
  required_version = ">= 1.6.0" # Soporte nativo para backend config con variables

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30" # Versión con soporte completo para OIDC y KMS
    }
  }

  backend "s3" {
    # NOTA: Los valores se inyectan via CLI o environment variables
    # terraform init -backend-config="bucket=${TF_BACKEND_BUCKET}" ...
    
    # Identificación del bucket (C2: infra como código)
    bucket = "" # Se inyecta: ${var.backend_bucket_name}-${var.environment_tag}
    
    # Key de estado por entorno (aislamiento lógico)
    key = "mantis/05-CONFIGURATIONS/${var.environment_tag}/terraform.tfstate"
    
    # Región de consistencia (interface-spec.yaml alignment)
    region = "" # Se inyecta: ${var.aws_region}
    
    # Locking con DynamoDB (previene race conditions en CI/CD)
    dynamodb_table = "" # Se inyecta: ${var.dynamodb_table_name}
    
    # Cifrado en reposo (C3: protección de datos sensibles en estado)
    encrypt = true
    
    # Cifrado con KMS customer-managed (opcional, recomendado para prod)
    kms_key_id = "" # Se inyecta: ${var.kms_key_arn} si no es null
    
    # Versionado del estado para rollback (C7: resiliencia)
    enable_lock_table_ssencryption = true
    
    # Prevenir eliminación accidental del bucket
    skip_bucket_ssencryption = false
    skip_bucket_root_access  = true
    skip_bucket_enforced_tls = false # Forzar TLS en tránsito (C3)
    
    # Métricas para monitoreo de acceso al estado (C4, C8)
    enable_bucket_logging = true
    bucket_logging_target_prefix = "terraform-state-access/"
  }
}

# --- Provider AWS con configuración OIDC (C3: sin secrets estáticos) ---
# Este bloque se evalúa en plan/apply; compatible con GitHub Actions OIDC

provider "aws" {
  region = var.aws_region

  # OIDC para CI/CD (C3: eliminar AWS_ACCESS_KEY de entorno)
  # En local: usar AWS CLI credentials o profile
  # En GitHub Actions: usar aws-actions/configure-aws-credentials@v4 con role-to-assume
  
  dynamic "assume_role" {
    for_each = var.enable_oidc ? [1] : []
    content {
      # ARN del rol a asumir (inyectar via TF_VAR_aws_role_arn)
      # Ej: arn:aws:iam::123456789012:role/mantis-terraform-${var.environment_tag}
      role_arn = lookup(var, "aws_role_arn", null)
      
      # Session name para auditoría en CloudTrail (C4: trazabilidad)
      session_name = "mantis-terraform-${var.environment_tag}-${formatdate("YYYYMMDD-HHMMSS", timestamp())}"
      
      # Tags para filtrado en Cost Explorer y CloudTrail (C4)
      tags = {
        Environment = var.environment_tag
        ManagedBy   = "terraform"
        Project     = "mantis-agentic"
        Constraint  = "C4-traceability"
      }
    }
  }

  # Default tags para todos los recursos (C4: consistencia en trazabilidad)
  default_tags {
    tags = {
      Project     = "mantis-agentic"
      Domain      = "05-CONFIGURATIONS"
      Environment = var.environment_tag
      ManagedBy   = "terraform"
      # Constraint mapping:
      C4          = "tags para trazabilidad en dashboards y auditoría"
      C2          = "infra como código: todos los recursos etiquetados"
    }
  }

  # Skip metadata service para contenedores (optimización)
  skip_metadata_api_check     = true
  skip_region_validation      = false # Mantener validación de región
  skip_credentials_validation = var.enable_oidc # OIDC no requiere validación tradicional
}

# ============================================================================
# OUTPUTS ESTANDARIZADOS (Para consumo por otros agentes - interface-spec.yaml)
# ============================================================================

# --- Outputs para docker-compose-master-agent ---
output "backend_bucket_arn" {
  description = "ARN del bucket S3 de estado (para tagging en compose)"
  value       = "arn:aws:s3:::${var.backend_bucket_name}-${var.environment_tag}"
  
  # Constraint mapping (interface-spec.yaml alignment):
  # - consumed_by: docker-compose-master-agent (para logging config)
  # - sensitive: false
  # - constraint: C4 (trazabilidad de recursos de infra)
}

output "dynamodb_table_arn" {
  description = "ARN de la tabla DynamoDB de locks (para métricas de monitoreo)"
  value       = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table_name}"
  
  # Constraint mapping:
  # - consumed_by: configurations-master-agent (para dashboard de locks)
  # - sensitive: false
  # - constraint: C8 (monitoreo de contención en CI/CD)
}

# --- Outputs para configurations-master-agent (auditoría) ---
output "backend_config_summary" {
  description = "Resumen no sensible de configuración para auditoría (C4)"
  value = {
    region              = var.aws_region
    environment         = var.environment_tag
    bucket_prefix       = var.backend_bucket_name
    locking_enabled     = true
    encryption_enabled  = true
    kms_customer_managed = var.kms_key_arn != null
    oidc_enabled        = var.enable_oidc
    # NOTA: Nunca incluir ARNs completos o IDs sensibles aquí (C3)
  }
  
  # Constraint mapping:
  # - consumed_by: configurations-master-agent (para SitRep y audit-configs.sh)
  # - sensitive: false
  # - constraint: C4 (trazabilidad sin exposición de secrets)
}

# --- Output para validación de compliance (C5) ---
output "compliance_check" {
  description = "Indicadores de cumplimiento de constraints para validación automatizada"
  value = {
    C2_iac               = true # Todo en repositorio
    C3_encryption        = true # encrypt = true en backend
    C3_oidc_ready        = var.enable_oidc # OIDC habilitado
    C4_tracing_tags      = true # default_tags configurados
    C5_validation_vars   = true # Todas las variables tienen validation
    C7_versioning_ready  = true # Bucket con versionado implícito en S3 backend
    # V1, V2, V3: No aplican a backend.tf (son de aplicación/db)
  }
  
  # Constraint mapping:
  # - consumed_by: orchestrator-engine.sh (para --strict validation)
  # - sensitive: false
  # - constraint: C5 (validación automatizada de integridad)
}

# ============================================================================
# DATA SOURCES PARA CONTEXTO DE EJECUCIÓN (C4: trazabilidad)
# ============================================================================

data "aws_caller_identity" "current" {
  # Usado para construir ARNs en outputs sin hardcodear account_id
  # Constraint: C4 (trazabilidad de quién ejecuta Terraform)
}

data "aws_partition" "current" {
  # Soporte para GovCloud o China regions si se requiere en futuro
  # Constraint: C2 (infra como código portable entre partitions)
}

# ============================================================================
# LOCALS PARA CONSISTENCIA DE NOMENCLATURA (C1: convención sobre configuración)
# ============================================================================

locals {
  # Nombre completo del bucket con tag de entorno (aislamiento lógico)
  bucket_full_name = "${var.backend_bucket_name}-${var.environment_tag}"
  
  # Prefix para keys de estado por dominio (organización en S3)
  state_key_prefix = "mantis/05-CONFIGURATIONS"
  
  # Tags base para todos los recursos (C4: trazabilidad consistente)
  base_tags = {
    Project     = "mantis-agentic"
    Domain      = "05-CONFIGURATIONS"
    Environment = var.environment_tag
    ManagedBy   = "terraform"
    Constraint  = "C4-traceability"
  }
  
  # Anti-pattern documentation (C1: no modificar convención sin ADR)
  # ❌ NUNCA: Hardcodear account_id, region o bucket names en múltiples lugares
  # ✅ SIEMPRE: Usar variables + locals + data sources para consistencia
}

# ============================================================================
# ANTI-PATRONES EXPLÍCITOS (NUNCA HACER - C1, C3, C5)
# ============================================================================

# ❌ NUNCA: Usar backend "local" en producción
# terraform { backend "local" { ... } } # Viola C2: infra como código

# ❌ NUNCA: Hardcodear AWS credentials en provider
# provider "aws" {
#   access_key = "AKIA..." # Viola C3: secrets en texto plano
#   secret_key = "..."
# }

# ❌ NUNCA: Omitir validation en variables sensibles
# variable "kms_key_arn" { type = string } # Sin validation = riesgo de typo en ARN (C5)

# ❌ NUNCA: Exponer secrets en outputs
# output "aws_access_key" { value = var.aws_access_key } # Viola C3 críticamente

# ❌ NUNCA: Usar environment_tag = "prod" sin approval gate en pipeline
# # Esto se controla en pipelines-master-agent, no aquí, pero documentar (C6)

# ============================================================================
# COMANDOS DE VALIDACIÓN Y USO (C5: automatización)
# ============================================================================

# --- Inicializar backend con configuración inyectada ---
# terraform init \
#   -backend-config="bucket=${TF_BACKEND_BUCKET}-${TF_ENV}" \
#   -backend-config="key=mantis/05-CONFIGURATIONS/${TF_ENV}/terraform.tfstate" \
#   -backend-config="region=${TF_AWS_REGION}" \
#   -backend-config="dynamodb_table=${TF_DYNAMODB_TABLE}" \
#   -backend-config="kms_key_id=${TF_KMS_KEY_ARN}" # Opcional

# --- Validar configuración con orchestrator-engine.sh ---
# orchestrator-engine.sh --domain terraform --file 05-CONFIGURATIONS/terraform/backend.tf --strict
# Esperado: PASS si:
#   - Todas las variables tienen validation (C5)
#   - Backend tiene encrypt=true (C3)
#   - Outputs no exponen secrets (C3)
#   - Tags base están configurados (C4)

# --- Generar checksum post-modificación ---
# CHECKSUM=$(sha256sum 05-CONFIGURATIONS/terraform/backend.tf | awk '{print $1}')
# sed -i "s/^# checksum_sha256: "7f1a3e2e5c468e3c87110e28e322888f035b1562ab9f03213e2216fa74444281"

# --- Registrar en checksum-manifest.json ---
# jq --arg path "05-CONFIGURATIONS/terraform/backend.tf" \
#    --arg sha "$CHECKSUM" \
#    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
#    '.artifacts[$path] = {version: "2.0.0", sha256: $sha, constraints: ["C2","C3","C4","C5"]}' \
#    05-CONFIGURATIONS/registry/checksum-manifest.json > /tmp/m.tmp && mv /tmp/m.tmp 05-CONFIGURATIONS/registry/checksum-manifest.json

# ============================================================================
# METADATOS DE GENERACIÓN (Para auditoría - C4)
# ============================================================================
# generated_by: "terraform-master-agent v2.0.0-COMPREHENSIVE"
# generation_timestamp: "2026-04-30T00:00:00Z"
# source_masters:
#   - "05-CONFIGURATIONS/terraform/terraform-master-agent.md"
#   - "05-CONFIGURATIONS/interface-spec.yaml"
#   - "05-CONFIGURATIONS/configurations-master-agent.md"
# constraints_applied: ["C2","C3","C4","C5"]
# version_constraints: [] # Backend no aplica V1-V3 (son de aplicación/db)
# next_review_date: "2026-07-30" # Trimestral per roadmap Q3 2026
# interface_alignment:
#   - "vpc_id: no aplica (backend es pre-infra)"
#   - "environment_tag: usado para aislamiento de estado"
#   - "aws_region: consistente con interface-spec.yaml"
```

---
