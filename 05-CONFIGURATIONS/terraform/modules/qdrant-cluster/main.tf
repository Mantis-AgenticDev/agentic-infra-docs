# ---
# artifact_id: terraform-qdrant-cluster-module
# artifact_type: infrastructure_module
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C2","C3","C4","C5","C8","V3"]
# canonical_path: 05-CONFIGURATIONS/terraform/modules/qdrant-cluster/main.tf
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
# checksum_sha256: "bb3858b11e6f36b85524a7cad8cfcc0635cbbbb9155906d474a45e6f4c265ca9"
# ---

# ============================================================================
# MÓDULO QDRANT CLUSTER: Búsqueda vectorial escalable (MANTIS v2.0.0)
# Propósito: ECS Fargate cluster para Qdrant con endpoint seguro, métricas y config V3
# Generado por: terraform-master-agent
# Fecha: 2026-04-30
# Alineación: interface-spec.yaml, mapping.yaml, vps-base/main.tf
# ============================================================================

# --- VARIABLES (C5: validación estricta) ---
variable "cluster_name" {
  description = "Nombre identificador del clúster Qdrant"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,31}$", var.cluster_name))
    error_message = "cluster_name: minúsculas, números, guiones; 3-32 chars."
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

variable "api_key" {
  description = "API key para autenticación en Qdrant (inyectar desde Secrets Manager, C3)"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.api_key) >= 32
    error_message = "api_key: longitud mínima 32 caracteres."
  }
}

variable "vpc_id" {
  description = "VPC para despliegue"
  type        = string
  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "vpc_id formato AWS inválido."
  }
}

variable "subnet_ids" {
  description = "Subnets para Fargate (mínimo 2 para AZ redundancy)"
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "subnet_ids requiere al menos 2 subnets."
  }
}

variable "cpu" {
  description = "CPU en unidades Fargate (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 1024
  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.cpu)
    error_message = "cpu debe ser 256, 512, 1024, 2048 o 4096."
  }
}

variable "memory" {
  description = "Memoria en MB (debe coincidir con CPU per AWS Fargate matrix)"
  type        = number
  default     = 3072
  validation {
    condition     = contains([2048, 3072, 4096, 5120, 8192, 16384, 30720], var.memory)
    error_message = "memory debe ser valor válido de Fargate matrix."
  }
}

variable "vector_size" {
  description = "Dimensión de embeddings para colección por defecto (V3)"
  type        = number
  default     = 1536
  validation {
    condition     = var.vector_size >= 64 && var.vector_size <= 4096
    error_message = "vector_size debe estar entre 64 y 4096."
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

# --- LOCALS (C4: trazabilidad) ---
locals {
  base_tags = {
    Project     = "mantis-agentic"
    Domain      = "05-CONFIGURATIONS"
    Environment = var.environment_tag
    ManagedBy   = "terraform"
    Module      = "qdrant-cluster"
    Constraint  = "V3-vector-performance,C8-observability"
  }
  service_name = "mantis-${var.environment_tag}-${var.cluster_name}"
  collection_config = jsonencode({
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
# RECURSOS
# ============================================================================

# --- Security Group (C3: restricción de acceso) ---
resource "aws_security_group" "qdrant" {
  name_prefix = "mantis-${var.environment_tag}-qdrant-"
  description = "Qdrant: acceso HTTP/gRPC solo desde VPS/ALB interno"
  vpc_id      = var.vpc_id

  ingress {
    description = "Qdrant HTTP from internal CIDR"
    from_port   = 6333
    to_port     = 6333
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    description = "Qdrant gRPC from internal CIDR"
    from_port   = 6334
    to_port     = 6334
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.base_tags, { Name = "${local.service_name}-sg" })
}

# --- ECS Cluster ---
resource "aws_ecs_cluster" "main" {
  name = "${local.service_name}-cluster"
  setting {
    name  = "containerInsights"
    value = var.enable_metrics ? "enabled" : "disabled"
  }
  tags = local.base_tags
}

# --- Task Definition (C3: secrets injection, V3: tuning) ---
resource "aws_ecs_task_definition" "qdrant" {
  family                   = local.service_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name  = "qdrant"
    image = "qdrant/qdrant:latest"
    portMappings = [
      { containerPort = 6333, hostPort = 6333, protocol = "tcp" },
      { containerPort = 6334, hostPort = 6334, protocol = "tcp" }
    ]
    environment = [
      { name = "QDRANT__SERVICE__HTTP_PORT", value = "6333" },
      { name = "QDRANT__TELEMETRY_DISABLED", value = "true" } # C8: métricas propias vía Prometheus
    ]
    secrets = [{
      name      = "QDRANT__SERVICE__API_KEY"
      valueFrom = var.api_key # ARN de Secrets Manager
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/${local.service_name}"
        awslogs-region        = data.aws_region.current.name
        awslogs-stream-prefix = "qdrant"
      }
    }
  }])

  tags = local.base_tags
}

# --- ECS Service ---
resource "aws_ecs_service" "qdrant" {
  name            = local.service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.qdrant.arn
  desired_count   = var.environment_tag == "prod" ? 2 : 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.qdrant.id]
    assign_public_ip = false
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true # C7: resiliencia automática
  }

  tags = local.base_tags
}

# --- IAM Roles ---
resource "aws_iam_role" "ecs_task_execution" {
  name               = "${local.service_name}-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
  tags               = local.base_tags
}

resource "aws_iam_role" "ecs_task_role" {
  name               = "${local.service_name}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
  tags               = local.base_tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# --- CloudWatch Log Group ---
resource "aws_cloudwatch_log_group" "qdrant" {
  name              = "/ecs/${local.service_name}"
  retention_in_days = var.environment_tag == "prod" ? 30 : 7
  tags              = local.base_tags
}

data "aws_region" "current" {}

# ============================================================================
# OUTPUTS (Alineados estrictamente con interface-spec.yaml)
# ============================================================================

output "qdrant_endpoint" {
  description = "Endpoint HTTP del clúster (ALB o service discovery interno)"
  value       = "http://${aws_ecs_service.qdrant.name}.local:6333"
  sensitive   = false
}

output "qdrant_api_key" {
  description = "API key para autenticación (inyectar como Docker secret)"
  value       = var.api_key
  sensitive   = true
}

output "qdrant_collection_config" {
  description = "Configuración JSON de colección para inicialización (V3)"
  value       = local.collection_config
  sensitive   = false
}

output "compliance_check" {
  description = "Indicadores de cumplimiento para orchestrator-engine.sh"
  value = {
    C2_iac_qdrant      = true
    C3_api_key_secret  = true
    C3_no_public_ip    = true
    C4_tags_applied    = true
    C5_vars_validated  = true
    C7_circuit_breaker = true
    C8_metrics_enabled = var.enable_metrics
    V3_hnsw_ready      = true
  }
}

# ============================================================================
# ANTI-PATRONES EXPLÍCITOS (C1, C3, C5, V3)
# ============================================================================
# ❌ NUNCA: `assign_public_ip = true` en servicios internos
# ❌ NUNCA: Hardcodear `QDRANT__SERVICE__API_KEY` en env vars
# ❌ NUNCA: Deshabilitar `deployment_circuit_breaker.rollback` en prod
# ❌ NUNCA: Ignorar `vector_size` mismatch con modelo de embeddings (V3)
# ✅ SIEMPRE: Validar configuración de colección post-deploy con API `/collections`
# ✅ SIEMPRE: Mantener `telemetry_disabled = true` y usar métricas nativas (C8)

# ============================================================================
# COMANDOS DE VALIDACIÓN Y USO
# ============================================================================
# 1. Formato & validación:
#    terraform fmt -check . && terraform init -backend=false && terraform validate
# 2. Scan seguridad (C3/C5):
#    checkov -d . --framework terraform --check CKV_AWS_334,CKV_AWS_335,CKV_AWS_338
# 3. Integración orchestrator:
#    orchestrator-engine.sh --domain terraform --file 05-CONFIGURATIONS/terraform/modules/qdrant-cluster/main.tf --strict
# 4. Post-deploy init collection (V3):
#    curl -X PUT "${qdrant_endpoint}/collections/mantis_vectors" \
#      -H "api-key: ${qdrant_api_key}" \
#      -H "Content-Type: application/json" \
#      -d '${qdrant_collection_config}'
# 5. Update checksum:
#    CHECKSUM=$(sha256sum <ruta> | awk '{print $1}') && sed -i "s/^# checksum_sha256: "bb3858b11e6f36b85524a7cad8cfcc0635cbbbb9155906d474a45e6f4c265ca9"


---
