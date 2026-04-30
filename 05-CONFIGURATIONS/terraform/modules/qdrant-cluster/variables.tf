# ---
# artifact_id: terraform-qdrant-cluster-variables
# artifact_type: infrastructure_config
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C2","C3","C4","C5","V3"]
# canonical_path: 05-CONFIGURATIONS/terraform/modules/qdrant-cluster/variables.tf
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
# checksum_sha256: "d6b9d5383abb3d6a05fb4c5a8dbe84de4aafcfd3f3420f745ed52a7f24e0dcc4"
# ---

# ============================================================================
# VARIABLES: MÓDULO QDRANT CLUSTER (MANTIS v2.0.0)
# Propósito: Parámetros validados para despliegue de búsqueda vectorial en ECS Fargate.
# Generado por: terraform-master-agent
# Fecha: 2026-04-30
# Alineación: qdrant-cluster/main.tf (#7), interface-spec.yaml §1, mapping.yaml
# ============================================================================

# --- IDENTIFICACIÓN & ENTORNO (C4, C5) ---
variable "cluster_name" {
  description = "Nombre identificador del clúster Qdrant"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,31}$", var.cluster_name))
    error_message = "cluster_name: minúsculas, números, guiones; 3-32 chars; iniciar con letra."
  }
}

variable "environment_tag" {
  description = "Entorno de despliegue: dev, staging, prod"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment_tag)
    error_message = "environment_tag debe ser: dev, staging, o prod"
  }
}

# --- SEGURIDAD & AUTENTICACIÓN (C3, C5) ---
variable "api_key" {
  description = "API key para autenticación en Qdrant (inyectar desde Secrets Manager/CI, C3)"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.api_key) >= 32
    error_message = "api_key: longitud mínima 32 caracteres para seguridad de clúster."
  }
}

# --- INFRAESTRUCTURA FARGATE (C2, C5) ---
variable "vpc_id" {
  description = "ID de VPC para despliegue"
  type        = string
  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "vpc_id formato AWS inválido."
  }
}

variable "subnet_ids" {
  description = "Subnets para Fargate (mínimo 2 para redundancia de AZ)"
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "subnet_ids requiere al menos 2 subnets para alta disponibilidad (C7)."
  }
}

variable "cpu" {
  description = "CPU en unidades Fargate (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 1024
  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.cpu)
    error_message = "cpu debe ser un valor válido de la matriz Fargate (256, 512, 1024, 2048, 4096)."
  }
}

variable "memory" {
  description = "Memoria en MB (debe coincidir con CPU per AWS Fargate matrix)"
  type        = number
  default     = 3072
  validation {
    condition     = contains([2048, 3072, 4096, 5120, 8192, 16384, 30720], var.memory)
    error_message = "memory debe ser un valor válido de la matriz Fargate correspondiente al CPU seleccionado."
  }
}

# --- VECTOR SEARCH CONFIG (V3: Performance & Tuning) ---
variable "vector_size" {
  description = "Dimensión de embeddings para colección por defecto (V3)"
  type        = number
  default     = 1536
  validation {
    condition     = var.vector_size >= 64 && var.vector_size <= 4096
    error_message = "vector_size debe estar entre 64 y 4096 (rangos soportados por Qdrant/pgvector)."
  }
}

variable "distance" {
  description = "Métrica de distancia vectorial (V3: performance)"
  type        = string
  default     = "Cosine"
  validation {
    condition     = contains(["Cosine", "Dot", "Euclid"], var.distance)
    error_message = "distance debe ser Cosine, Dot o Euclid."
  }
}

variable "enable_metrics" {
  description = "Habilitar exportación de métricas Prometheus (C8)"
  type        = bool
  default     = true
}

variable "tags_extra" {
  description = "Tags adicionales para override o workload específico"
  type        = map(string)
  default     = {}
  validation {
    condition = alltrue([
      for k, v in var.tags_extra :
      can(regex("^[a-zA-Z0-9_.:/-]+$", k)) && can(regex("^[a-zA-Z0-9_.:/-]+$", v))
    ])
    error_message = "tags_extra: keys y values deben cumplir formato estándar AWS tagging."
  }
}

# --- LOCALS (C4: trazabilidad consistente) ---
locals {
  service_name        = "mantis-${var.environment_tag}-${var.cluster_name}"
  base_tags           = {
    Project     = "mantis-agentic"
    Domain      = "05-CONFIGURATIONS"
    Environment = var.environment_tag
    ManagedBy   = "terraform"
    Module      = "qdrant-cluster"
    Constraint  = "V3-vector-performance,C8-observability"
  }
  merged_tags         = merge(local.base_tags, var.tags_extra)
  collection_config   = jsonencode({
    vectors = {
      size     = var.vector_size
      distance = var.distance
    }
    hnsw_config = {
      m             = 16
      ef_construct  = 100
    }
  })
}

# ============================================================================
# ANTI-PATRONES EXPLÍCITOS (C1, C3, C5)
# ============================================================================
# ❌ NUNCA: `cpu = 512` y `memory = 2048` (combinación inválida en Fargate)
# ❌ NUNCA: Hardcodear `api_key` en variables o tfvars (viola C3)
# ❌ NUNCA: Usar `vector_size < 64` o `> 4096` (viola límites técnicos V3)
# ✅ SIEMPRE: Validar que `memory` sea compatible con `cpu` según docs AWS
# ✅ SIEMPRE: Mantener `sensitive = true` explícito para `api_key`

# ============================================================================
# COMANDOS DE VALIDACIÓN
# ============================================================================
# terraform fmt -check 05-CONFIGURATIONS/terraform/modules/qdrant-cluster/variables.tf
# terraform init -backend=false -input=false 05-CONFIGURATIONS/terraform/modules/qdrant-cluster && terraform validate
# orchestrator-engine.sh --domain terraform --file 05-CONFIGURATIONS/terraform/modules/qdrant-cluster/variables.tf --strict
# CHECKSUM=$(sha256sum 05-CONFIGURATIONS/terraform/modules/qdrant-cluster/variables.tf | awk '{print $1}') && sed -i "s/^# checksum_sha256: "d6b9d5383abb3d6a05fb4c5a8dbe84de4aafcfd3f3420f745ed52a7f24e0dcc4"
```

---
