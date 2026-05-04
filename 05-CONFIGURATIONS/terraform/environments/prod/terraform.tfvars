# ---
# artifact_id: tfvars-prod-mantis
# artifact_type: terraform_config
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C2","C3","C4","C5","C6","C7","V1","V2","V3"]
# canonical_path: 05-CONFIGURATIONS/terraform/envs/prod/terraform.tfvars
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
# checksum_sha256: "a86a7be0390701df99b9647f771c48fc293d1be2b31d2fb3f07184601ff8c5e3"
# ---

# ============================================================================
# TERRAFORM VARS: ENTORNO PROD (MANTIS v2.0.0)
# Propósito: Configuración productiva con HA, compliance estricto y tuning de performance.
# Generado por: terraform-master-agent
# Fecha: 2026-04-30
# Alineación: variables.tf globales, modules/*/variables.tf, interface-spec.yaml
# Regla C3: SECRETS NUNCA EN REPO. Inyección obligatoria vía CI/CD vault o OIDC.
# ============================================================================

# --- IDENTIFICACIÓN & CLOUD (C4) ---
aws_region          = "sa-east-1"
environment_tag     = "prod"
project_name        = "mantis-agentic"

# --- BACKEND & ESTADO (C2, C4) ---
backend_bucket_name = "mantis-state"

# --- INFRAESTRUCTURA BASE (C5, C7, C8) ---
vpc_cidr            = "10.2.0.0/16"
instance_type       = "t3.medium"   # Balance costo/rendimiento para workloads core
enable_monitoring   = true          # CloudWatch detailed monitoring obligatorio

# --- BASE DE DATOS (C3, V1, V2) ---
db_identifier       = "mantis-prod-db"
db_username         = "mantis_app"
db_password         = "" # ⚠️ C3: OBLIGATORIO inyectar vía TF_VAR_db_password o CI Vault. CERO HARDCODE.
instance_class      = "db.r5.large" # Optimizado para IOPS, conexiones concurrentes y pgvector
multi_az            = true          # HA obligatorio para failover automático (C7)
backup_retention_days = 30          # Retención mensual para compliance y auditoría

# --- PGVECTOR & RLS (V1, V3) ---
pgvector_enabled    = true          # Aislamiento lógico de tenants activo
pgvector_dimension  = 1536          # Alineado con text-embedding-3-small
pgvector_index_type = "hnsw"        # HNSW para latencia sub-milisegunda en prod

# --- QDRANT VECTOR SEARCH (V3, C5, C8) ---
qdrant_cluster_name = "mantis-prod-qdrant"
qdrant_api_key      = "" # ⚠️ C3: Inyectar vía CI/CD secrets. NUNCA commitear.
qdrant_vector_size  = 1536
qdrant_distance     = "Cosine"
qdrant_cpu          = 2048  # Fargate matrix validado (requiere memory >= 4096)
qdrant_memory       = 4096  # Compatible con cpu=2048. Escalable según carga vectorial.

# --- OPENROUTER PROXY (C3, C6, C8) ---
proxy_name          = "mantis-prod-proxy"
rate_limit_rps      = 100   # Límite productivo (ajustar según quota de proveedor)
allowed_origins     = ["https://app.mantis.ag"] # Solo dominio productivo verificado
openrouter_api_key_ssm_path = "/mantis/prod/openrouter/api-key"

# --- BACKUP & RECUPERACIÓN (V2, C7) ---
backup_bucket_prefix = "mantis-prod-backups"
backup_retention_days = 30
enable_object_lock    = true # WORM obligatorio: inmutabilidad de backups críticos

# --- TAGS & TRAZABILIDAD (C4) ---
tags_extra = {
  Environment   = "prod"
  CostCenter    = "engineering"
  AutoShutdown  = "false" # Prod activo 24/7. Sin apagados automáticos.
  Compliance    = "SOC2-ready"
}

# ============================================================================
# ANTI-PATRONES EXPLÍCITOS (C1, C3, C6, V2)
# ============================================================================
# ❌ NUNCA: `db_password = "sk_live_..."` o similar en este archivo (violación crítica C3)
# ❌ NUNCA: `multi_az = false` en producción (riesgo de SPOF, viola C7)
# ❌ NUNCA: `allowed_origins = ["*"]` o incluir dominios de staging/dev (viola C6)
# ❌ NUNCA: `enable_object_lock = false` para backups productivos (viola V2)
# ✅ SIEMPRE: Ejecutar `terraform plan -var-file=...` en pipeline con approval gate humano (C6)
# ✅ SIEMPRE: Validar que `qdrant_memory` y `qdrant_cpu` coincidan con AWS Fargate matrix oficial
# ✅ SIEMPRE: Rotar secrets vía pipeline programado, nunca modificar tfvars manualmente

# ============================================================================
# COMANDOS DE VALIDACIÓN
# ============================================================================
# terraform fmt -check 05-CONFIGURATIONS/terraform/envs/prod/terraform.tfvars
# terraform validate -var-file=05-CONFIGURATIONS/terraform/envs/prod/terraform.tfvars
# orchestrator-engine.sh --domain terraform --file 05-CONFIGURATIONS/terraform/envs/prod/terraform.tfvars --strict
# CHECKSUM=$(sha256sum 05-CONFIGURATIONS/terraform/envs/prod/terraform.tfvars | awk '{print $1}') && sed -i "s/^# checksum_sha256: "a86a7be0390701df99b9647f771c48fc293d1be2b31d2fb3f07184601ff8c5e3"


---
