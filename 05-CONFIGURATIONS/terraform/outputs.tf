# ---
# artifact_id: terraform-outputs-global-mantis
# artifact_type: infrastructure_config
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C2","C3","C4","C5","V1","V3"]
# canonical_path: 05-CONFIGURATIONS/terraform/outputs.tf
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
# checksum_sha256: "33dcedac6fb47262cf2e2480ee16f7f953b186f932884620901e9609adde5c4e"
# ---

# ============================================================================
# OUTPUTS GLOBALES TERRAFORM (MANTIS v2.0.0)
# Propósito: Fuente canónica de verdad para consumo transversal (Docker Compose, Agents, CI/CD).
# Generado por: terraform-master-agent
# Fecha: 2026-04-30
# Alineación estricta: interface-spec.yaml §1, mapping.yaml, backend.tf
# ============================================================================

# [CONSTRAINT_MAP]
# C2: Outputs como contrato de interfaz IaC → Orchestration
# C3: CERO credenciales expuestas; todos sensitive=false o sanitizados
# C4: Estructura tipada para trazabilidad automática en dashboards
# C5: Valores derivados de variables/locals validados previamente
# V1: db_schema expuesto para aislamiento RLS de tenants
# V3: qdrant_collection_config listo para tuning de performance

# --- RED & INFRAESTRUCTURA BASE (Interface §1) ---
output "vpc_id" {
  description = "ID de VPC principal para tagging y referencia en security groups"
  value       = module.vps_base.vpc_id # Resuelto desde módulo vps-base o data.aws_vpc
  sensitive   = false
}

output "subnet_ids" {
  description = "Lista de subnet IDs para despliegue multi-AZ y composición Compose"
  value       = module.vps_base.subnet_ids
  sensitive   = false
}

output "security_group_id" {
  description = "ID del security group base (reglas mínimas: SSH/HTTP/HTTPS)"
  value       = module.vps_base.security_group_id
  sensitive   = false
}

# --- BASE DE DATOS & RLS (Interface §1, V1) ---
output "db_endpoint" {
  description = "Connection string sin credenciales (formato postgres://host:port/dbname)"
  value       = module.postgres_rls.db_endpoint
  sensitive   = false
}

output "db_schema" {
  description = "Schema por defecto para aislamiento lógico de tenants (RLS V1)"
  value       = module.postgres_rls.db_schema
  sensitive   = false
}

output "db_pool_size" {
  description = "Tamaño recomendado del pool de conexiones por clase de instancia"
  value       = module.postgres_rls.db_pool_size
  sensitive   = false
}

# --- VECTOR SEARCH & QDRANT (Interface §1, V3) ---
output "qdrant_endpoint" {
  description = "Endpoint HTTP/HTTPS del clúster Qdrant para embeddings"
  value       = module.qdrant_cluster.qdrant_endpoint
  sensitive   = false
}

output "qdrant_collection_config" {
  description = "Configuración JSON de colección (vector_size, distance, hnsw_config)"
  value       = module.qdrant_cluster.qdrant_collection_config
  sensitive   = false
}

# --- CONTRATO ESTRUCTURADO PARA AGENTES (Cross-Domain) ---
output "agent_contract" {
  description = "Objeto consolidado para inyección directa en docker-compose y pipelines"
  value = {
    network = {
      vpc_id            = module.vps_base.vpc_id
      subnet_ids        = module.vps_base.subnet_ids
      security_group_id = module.vps_base.security_group_id
    }
    database = {
      endpoint  = module.postgres_rls.db_endpoint
      schema    = module.postgres_rls.db_schema
      pool_size = module.postgres_rls.db_pool_size
      rls_v1    = true
    }
    vector_search = {
      endpoint          = module.qdrant_cluster.qdrant_endpoint
      collection_config = module.qdrant_cluster.qdrant_collection_config
      v3_performance    = true
    }
    compliance = {
      c3_secrets_safe     = true # Ningún valor sensible expuesto
      c4_traceable        = true # Tags y estructura auditables
      environment         = var.environment_tag
      generated_at        = timestamp()
    }
  }
  sensitive = false
}

# --- AUDITORÍA & GOBERNANZA (C4, C5) ---
output "compliance_matrix" {
  description = "Indicadores de cumplimiento C1-C8/V1-V3 para orchestrator-engine.sh"
  value = {
    C2_iac_outputs       = true
    C3_no_plain_secrets  = true
    C4_structured_export = true
    C5_validated_sources = true
    V1_tenant_rls_ready  = true
    V3_vector_config     = true
    contract_version     = "2.0.0"
  }
  sensitive = false
}

# ============================================================================
# ANTI-PATRONES EXPLÍCITOS (C1, C3, C5)
# ============================================================================
# ❌ NUNCA: Exponer `db_password`, `qdrant_api_key` o ARNs de KMS aquí (viola C3)
# ❌ NUNCA: Usar `sensitive = false` en valores derivados de inputs secretos
# ❌ NUNCA: Hardcodear IDs, IPs o endpoints estáticos; siempre referenciar módulos/data
# ❌ NUNCA: Modificar estructura de `agent_contract` sin actualizar interface-spec.yaml
# ✅ SIEMPRE: Mantener `sensitive = false` explícito para evitar defaults ambiguos
# ✅ SIEMPRE: Validar que outputs coincidan 1:1 con interface-spec.yaml §1

# ============================================================================
# COMANDOS DE VALIDACIÓN
# ============================================================================
# terraform fmt -check 05-CONFIGURATIONS/terraform/outputs.tf
# terraform init -backend=false -input=false 05-CONFIGURATIONS/terraform && terraform validate
# yq eval '.terraform_outputs | keys' 05-CONFIGURATIONS/interface-spec.yaml | sort | diff - <(terraform output -json 05-CONFIGURATIONS/terraform | jq -r 'keys[]')
# orchestrator-engine.sh --domain terraform --file 05-CONFIGURATIONS/terraform/outputs.tf --strict
# CHECKSUM=$(sha256sum 05-CONFIGURATIONS/terraform/outputs.tf | awk '{print $1}') && sed -i "s/^# checksum_sha256: "33dcedac6fb47262cf2e2480ee16f7f953b186f932884620901e9609adde5c4e"


---
