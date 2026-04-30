# ---
# artifact_id: tfvars-dev-mantis
# artifact_type: terraform_config
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C2","C3","C4","C5"]
# canonical_path: 05-CONFIGURATIONS/terraform/envs/dev/terraform.tfvars
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
# checksum_sha256: "b53a765f0778bfd303a648ccf6ca086561a037b65dc9048b554f3afc4a68bce2"
# ---

# ============================================================================
# TERRAFORM VARS: ENTORNO DEV (MANTIS v2.0.0)
# Propósito: Valores de desarrollo para pruebas locales y CI temprano.
# Generado por: terraform-master-agent
# Fecha: 2026-04-30
# Alineación: variables.tf globales, modules/*/variables.tf, interface-spec.yaml
# Regla C3: NUNCA incluir valores reales de secrets aquí. Usar placeholders o inyección CI.
# ============================================================================

# --- IDENTIFICACIÓN & CLOUD (C4) ---
aws_region          = "sa-east-1" # [valid: interface-spec.yaml]
environment_tag     = "dev"       # [valid: dev|staging|prod]
project_name        = "mantis-agentic"

# --- BACKEND & ESTADO (C2, C4) ---
backend_bucket_name = "mantis-state" # Prefijo; se concatena con environment_tag en backend.tf

# --- INFRAESTRUCTURA BASE (C5: validado contra vps-base/variables.tf) ---
vpc_cidr            = "10.0.0.0/16"
instance_type       = "t3.micro" # Perfil nano para dev (costo mínimo)
enable_monitoring   = false      # Desactivado en dev para reducir ruido/métricas

# --- BASE DE DATOS (C3: placeholders, no reales) ---
db_identifier       = "mantis-dev-db"
db_username         = "mantis_app"
db_password         = "" # ⚠️ C3: Inyectar vía TF_VAR_db_password o CI secrets. NUNCA hardcodear.
instance_class      = "db.t3.small" # Mínimo para pruebas funcionales
multi_az            = false         # Single-AZ en dev para reducir costo
backup_retention_days = 1           # Mínimo compliance para dev

# --- PGVECTOR & RLS (V1) ---
pgvector_enabled    = true          # Habilitado incluso en dev para validar aislamiento
pgvector_dimension  = 1536          # Alinear con modelo de embeddings usado
pgvector_index_type = "hnsw"        # HNSW para testing de performance local

# --- QDRANT VECTOR SEARCH (V3, C3) ---
qdrant_cluster_name = "mantis-dev-qdrant"
qdrant_api_key      = "" # ⚠️ C3: Inyectar vía TF_VAR_qdrant_api_key o Docker secrets
qdrant_vector_size  = 1536
qdrant_distance     = "Cosine"
qdrant_cpu          = 512   # Mínimo Fargate para dev
qdrant_memory       = 2048  # Compatible con cpu=512 en Fargate matrix

# --- OPENROUTER PROXY (C3, C8) ---
proxy_name          = "mantis-dev-proxy"
rate_limit_rps      = 10    # Bajo para testing, evitar throttling accidental
allowed_origins     = ["http://localhost:3000", "http://localhost:5678"] # Dev origins only
openrouter_api_key_ssm_path = "/mantis/dev/openrouter/api-key" # Ruta SSM dev

# --- BACKUP & RECUPERACIÓN (V2) ---
backup_bucket_prefix = "mantis-dev-backups"
backup_retention_days = 7    # Semanal en dev
enable_object_lock    = false # WORM opcional en dev (habilitar en staging/prod)

# --- TAGS & TRAZABILIDAD (C4) ---
tags_extra = {
  Environment   = "dev"
  CostCenter    = "engineering"
  AutoShutdown  = "true" # Script externo puede apagar recursos dev fuera de horario
}

# ============================================================================
# ANTI-PATRONES EXPLÍCITOS (C1, C3, C5)
# ============================================================================
# ❌ NUNCA: `db_password = "valor_real"` en este archivo (viola C3 críticamente)
# ❌ NUNCA: Usar `environment_tag = "prod"` en vars de dev (riesgo de deploy accidental)
# ❌ NUNCA: Omitir `backup_retention_days >= 1` incluso en dev (viola V2 mínimo)
# ✅ SIEMPRE: Inyectar secrets vía `TF_VAR_*` environment variables o CI/CD vault
# ✅ SIEMPRE: Mantener `multi_az = false` en dev para control de costos (activar en staging+)

# ============================================================================
# COMANDOS DE VALIDACIÓN
# ============================================================================
# terraform fmt -check 05-CONFIGURATIONS/terraform/envs/dev/terraform.tfvars
# terraform validate -var-file=05-CONFIGURATIONS/terraform/envs/dev/terraform.tfvars
# orchestrator-engine.sh --domain terraform --file 05-CONFIGURATIONS/terraform/envs/dev/terraform.tfvars --strict
# CHECKSUM=$(sha256sum 05-CONFIGURATIONS/terraform/envs/dev/terraform.tfvars | awk '{print $1}') && sed -i "s/^# checksum_sha256: "b53a765f0778bfd303a648ccf6ca086561a037b65dc9048b554f3afc4a68bce2"


---
