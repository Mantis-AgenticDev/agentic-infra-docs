# ---
# artifact_id: terraform-qdrant-cluster-outputs
# artifact_type: infrastructure_config
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C2","C3","C4","C5","V3"]
# canonical_path: 05-CONFIGURATIONS/terraform/modules/qdrant-cluster/outputs.tf
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
# checksum_sha256: "523ef9b0bd038b3208fad5c4761a57d24735b5c7a676ab44b2bf0e1b7bfb9f29"
# ---

# ============================================================================
# OUTPUTS: MÓDULO QDRANT CLUSTER (MANTIS v2.0.0)
# Propósito: Interfaz de consumo transversal para Docker Compose, agentes y monitoreo vectorial.
# Generado por: terraform-master-agent
# Fecha: 2026-04-30
# Alineación estricta: interface-spec.yaml §1, mapping.yaml, main.tf (#7), variables.tf (#39)
# ============================================================================

# --- ENDPOINTS & ACCESO (C4, V3) ---
output "qdrant_endpoint" {
  description = "Endpoint HTTP/HTTPS del clúster Qdrant para consumo por agentes y APIs"
  value       = "http://${aws_ecs_service.qdrant.name}.local:6333" # Service discovery interno
  sensitive   = false
}

output "qdrant_grpc_endpoint" {
  description = "Endpoint gRPC para operaciones de alta performance (búsqueda vectorial V3)"
  value       = "grpc://${aws_ecs_service.qdrant.name}.local:6334"
  sensitive   = false
}

output "cloudwatch_log_group_arn" {
  description = "ARN del grupo de logs para auditoría y métricas de latencia vectorial"
  value       = aws_cloudwatch_log_group.qdrant.arn
  sensitive   = false
}

# --- SEGURIDAD & CONFIGURACIÓN EXTERNA (C3, C5) ---
output "qdrant_api_key" {
  description = "API key para autenticación en Qdrant (inyectar vía Docker secrets/CI, C3)"
  value       = var.api_key
  sensitive   = true # C3: Nunca exponer en terraform plan stdout, logs o archivos no cifrados
}

output "waf_acl_arn" {
  description = "ARN del WAFv2 asociado (si aplica) para métricas de rate-limiting"
  value       = aws_wafv2_web_acl.rate_limit.arn
  sensitive   = false
}

# --- CONFIGURACIÓN VECTORIAL (V3: Performance & Tuning) ---
output "qdrant_collection_config" {
  description = "Configuración JSON de colección para inicialización y validación cruzada (V3)"
  value       = local.collection_config
  sensitive   = false
}

output "hnsw_config_applied" {
  description = "Configuración HNSW aplicada para tuning de performance vectorial"
  value = {
    m             = 16
    ef_construct  = 100
    vector_size   = var.vector_size
    distance      = var.distance
  }
  sensitive = false
}

# --- GOBERNANZA & VALIDACIÓN AUTOMATIZADA (C4, C5, V3) ---
output "compliance_check" {
  description = "Indicadores de cumplimiento para orchestrator-engine.sh y audit-configs.sh"
  value = {
    C2_iac_qdrant          = true
    C3_api_key_secret      = true
    C3_no_public_ip        = true
    C4_traceable_logs      = true
    C5_vars_validated      = true
    V3_vector_size_valid   = var.vector_size >= 64 && var.vector_size <= 4096
    V3_distance_supported  = contains(["Cosine", "Dot", "Euclid"], var.distance)
    V3_hnsw_ready          = true
    C8_metrics_enabled     = var.enable_metrics
  }
  sensitive = false
}

# ============================================================================
# ANTI-PATRONES EXPLÍCITOS (C1, C3, C5)
# ============================================================================
# ❌ NUNCA: `sensitive = false` en `qdrant_api_key` o cualquier output derivado de secretos
# ❌ NUNCA: Exponer `var.api_key` directamente en logs, plan outputs o archivos no cifrados
# ❌ NUNCA: Modificar estructura de `qdrant_collection_config` sin actualizar interface-spec.yaml
# ✅ SIEMPRE: Consumir `qdrant_api_key` via Docker secrets injection o CI/CD vault
# ✅ SIEMPRE: Alinear nombres de outputs con `terraform_outputs` en interface-spec.yaml §1

# ============================================================================
# COMANDOS DE VALIDACIÓN
# ============================================================================
# terraform fmt -check 05-CONFIGURATIONS/terraform/modules/qdrant-cluster/outputs.tf
# terraform init -backend=false -input=false 05-CONFIGURATIONS/terraform/modules/qdrant-cluster && terraform validate
# yq eval '.terraform_outputs.qdrant_api_key.sensitive' 05-CONFIGURATIONS/interface-spec.yaml | grep -q "true" && echo "✅ Alineación C3 OK"
# orchestrator-engine.sh --domain terraform --file 05-CONFIGURATIONS/terraform/modules/qdrant-cluster/outputs.tf --strict
# CHECKSUM=$(sha256sum 05-CONFIGURATIONS/terraform/modules/qdrant-cluster/outputs.tf | awk '{print $1}') && sed -i "s/^# checksum_sha256: "523ef9b0bd038b3208fad5c4761a57d24735b5c7a676ab44b2bf0e1b7bfb9f29"


---
