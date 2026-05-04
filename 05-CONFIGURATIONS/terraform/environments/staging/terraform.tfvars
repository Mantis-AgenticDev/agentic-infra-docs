# ---
# artifact_id: tfvars-staging-mantis
# artifact_type: terraform_config
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C2","C3","C4","C5","V1","V2"]
# canonical_path: 05-CONFIGURATIONS/terraform/envs/staging/terraform.tfvars
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
# checksum_sha256: "9fe0e66ba720807a79f49fb9f315c98692a2cd3f1dee030c02c1b2065883d1e5"
# ---

# ============================================================================
# TERRAFORM VARS: ENTORNO STAGING (MANTIS v2.0.0)
# Propósito: Configuración pre-productiva para validación de carga, HA y pipelines.
# Generado por: terraform-master-agent
# Fecha: 2026-04-30
# Alineación: variables.tf globales, modules/*/variables.tf, interface-spec.yaml
# Regla C3: Secrets siempre inyectados vía CI/CD. Placeholders obligatorios.
# ============================================================================

# --- IDENTIFICACIÓN & CLOUD (C4) ---
aws_region          = "sa-east-1"
environment_tag     = "staging"
project_name        = "mantis-agentic"

# --- BACKEND & ESTADO (C2, C4) ---
backend_bucket_name = "mantis-state"

# --- INFRAESTRUCTURA BASE (C5, C8) ---
vpc_cidr            = "10.1.0.0/16"
instance_type       = "t3.small" # Carga realista para testing de performance
enable_monitoring   = true       # CloudWatch detallado habilitado en staging

# --- BASE DE DATOS (C3, V2, V1) ---
db_identifier       = "mantis-staging-db"
db_username         = "mantis_app"
db_password         = "" # ⚠️ C3: Inyectar vía TF_VAR_db_password o CI secrets
instance_class      = "db.t3.medium"
multi_az            = true         # Habilitado para validar failover pre-prod
backup_retention_days = 14         # Quincenal para staging

# --- PGVECTOR & RLS (V1, V3) ---
pgvector_enabled    = true
pgvector_dimension  = 1536
pgvector_index_type = "hnsw"       # Validar tuning HNSW en staging antes de prod

# --- QDRANT VECTOR SEARCH (V3, C5) ---
qdrant_cluster_name = "mantis-staging-qdrant"
qdrant_api_key      = "" # ⚠️ C3: Inyectar vía TF_VAR_qdrant_api_key
qdrant_vector_size  = 1536
qdrant_distance     = "Cosine"
qdrant_cpu          = 1024  # Fargate matrix validado
qdrant_memory       = 3072  # Compatible con cpu=1024

# --- OPENROUTER PROXY (C3, C8) ---
proxy_name          = "mantis-staging-proxy"
rate_limit_rps      = 25    # Límite intermedio para testing de throttling
allowed_origins     = ["https://staging.mantis.ag", "http://localhost:3000"]
openrouter_api_key_ssm_path = "/mantis/staging/openrouter/api-key"

# --- BACKUP & RECUPERACIÓN (V2) ---
backup_bucket_prefix = "mantis-staging-backups"
backup_retention_days = 14
enable_object_lock    = true # WORM habilitado para validar políticas de compliance

# --- TAGS & TRAZABILIDAD (C4) ---
tags_extra = {
  Environment   = "staging"
  CostCenter    = "engineering"
  AutoShutdown  = "false" # Staging permanece activo 24/7 para validación CI
}

# ============================================================================
# ANTI-PATRONES EXPLÍCITOS (C1, C3, C5)
# ============================================================================
# ❌ NUNCA: `db_password = "valor_real"` en staging (viola C3 críticamente)
# ❌ NUNCA: Usar `environment_tag = "prod"` o `dev` en este archivo
# ❌ NUNCA: `multi_az = false` si se quiere validar routing/failover real
# ✅ SIEMPRE: Inyectar secrets vía `TF_VAR_*` o CI/CD vault en pipeline
# ✅ SIEMPRE: Validar `qdrant_memory` vs `qdrant_cpu` contra AWS Fargate matrix

# ============================================================================
# COMANDOS DE VALIDACIÓN
# ============================================================================
# terraform fmt -check 05-CONFIGURATIONS/terraform/envs/staging/terraform.tfvars
# terraform validate -var-file=05-CONFIGURATIONS/terraform/envs/staging/terraform.tfvars
# orchestrator-engine.sh --domain terraform --file 05-CONFIGURATIONS/terraform/envs/staging/terraform.tfvars --strict
# CHECKSUM=$(sha256sum 05-CONFIGURATIONS/terraform/envs/staging/terraform.tfvars | awk '{print $1}') && sed -i "s/^# checksum_sha256: "9fe0e66ba720807a79f49fb9f315c98692a2cd3f1dee030c02c1b2065883d1e5"


---
