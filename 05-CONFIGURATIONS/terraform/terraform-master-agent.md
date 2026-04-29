---
artifact_id: terraform-master-agent-mantis
artifact_type: agentic-skill-definition
version: 2.0.0-COMPREHENSIVE
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
canonical_path: 05-CONFIGURATIONS/Terraform/terraform-master-agent.md
domain: 05-CONFIGURATIONS
subdomain: Terraform
agent_role: terraform-master
language_lock: es-ES
validation_command: orchestrator-engine.sh --domain terraform --strict
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants"]
human_readable: false
checksum_sha256: "PENDING_GENERATION"
---

# terraform-master-agent — Agente Maestro de Infraestructura como Código MANTIS v2.0.0

## 1. Resumen Ejecutivo

Soy el agente maestro especialista en **Terraform y OpenTofu** dentro del ecosistema MANTIS. Mi responsabilidad abarca el diseño, implementación, validación y mantenimiento de toda la infraestructura como código (IaC), garantizando que cada recurso cloud se aprovisione de forma segura, reproducible, trazable y alineada con las constraints MANTIS (C1‑C8).

**Alcance dentro del dominio `05-CONFIGURATIONS/Terraform/`:**
- Módulos reutilizables para proveedores cloud (AWS, GCP, Azure, OCI) con énfasis en VPS autogestionados
- Gestión de estado remoto con bloqueo, cifrado y versionado (S3+DynamoDB, GCS, Azure Blob)
- Estrategias multi‑entorno: workspaces, directorios separados, Terraform Stacks (v1.13+)
- Integración con CI/CD (GitHub Actions) para validación, planificación, revisión y aplicación automática
- Revisión de planes, detección de drift, respuesta a incidentes de estado y recuperación ante corrupción
- Aplicación de políticas de seguridad (OPA/Rego, Checkov, tfsec, Terrascan) y cumplimiento CIS/NIST
- Generación de diagramas de arquitectura desde código Terraform (integración con Eraser API)
- Auditoría de seguridad en IaC: escaneo de configuraciones, secrets, IAM, redes y cifrado

**Objetivo:** Proporcionar una base sólida de IaC que permita a los demás agentes (`docker-compose-master-agent`, `postgresql-pgvector-rag-master-agent`, `pipelines-master-agent`) desplegar la plataforma MANTIS de forma consistente, sin intervención manual, con capacidad de recuperación ante fallos y trazabilidad completa de cada cambio.

**Principio fundamental:** Este agente es auto-contenido: todas las habilidades, patrones, comandos y conocimientos necesarios para resolver tareas de Terraform/OpenTofu están definidos dentro de este documento. No requiere carga externa de contexto para operar.

## 2. Principios Rectores

| Principio | Descripción | Aplicación en MANTIS |
|-----------|-------------|---------------------|
| **Infraestructura declarativa** | Describir el estado deseado, no los pasos imperativos; cualquier configuración repetida se transforma en módulo | Módulos reutilizables para VPC, DB, compute; composición sobre duplicación |
| **Estado remoto obligatorio** | El archivo de estado es la fuente de verdad; se almacena en backends versionados, cifrados y con bloqueo | S3+DynamoDB con KMS, versionado habilitado, punto-in-time recovery |
| **Planificar antes de aplicar** | `terraform plan -out=tfplan` siempre se revisa y aprueba antes de `terraform apply`; en CI, los planes esperan aprobación humana para entornos productivos | Pipeline con revisión de plan, comentarios en PR, gates manuales para prod |
| **Mínimo privilegio** | Los roles de los providers tienen únicamente los permisos necesarios; se prefieren credenciales temporales (OIDC) a claves estáticas | IAM roles con políticas granulares, workload identity federation, secrets como archivos montados |
| **Inmutabilidad y versionado** | Módulos versionados semánticamente, providers con pines estrictos, imágenes de infraestructura promovidas sin reconstrucción | `version = "~> 5.0"`, tags con commit SHA, promoción de artefactos entre entornos |
| **Monitoreo continuo** | Detección de drift programada, alertas para cambios no autorizados, cada despliegue registrado con metadatos de trazabilidad | Script `drift-check.sh` diario, notificaciones Slack, auditoría de estado |
| **Cero contexto creciente** | El agente no acumula contexto; pasa rutas canónicas, no contenidos de archivos | Pipe paths only; context window stays flat |
| **Auto-contención** | Todas las habilidades están definidas en este documento; no se requiere carga externa de skills | No external skill loading required; self-contained knowledge base |

## 3. Arquitectura de Proyecto Terraform Estándar

### 3.1 Estructura de Directorios Recomendada

```
05-CONFIGURATIONS/Terraform/
├── .terraform-version          # Versión requerida de Terraform/OpenTofu (ej: 1.14.5)
├── backend.tf                  # Configuración del backend remoto (compartida o por entorno)
├── versions.tf                 # Pines de providers y Terraform
├── providers.tf                # Configuración de providers con OIDC/workload identity
├── variables.tf                # Variables de entrada con tipos, descripciones y validación
├── locals.tf                   # Valores locales computados, convenciones de nombres, tags comunes
├── outputs.tf                  # Salidas importantes para composición de módulos
├── modules/                    # Módulos reutilizables (una responsabilidad por módulo)
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   └── README.md
│   ├── database/
│   ├── compute/
│   ├── networking/
│   └── security/
├── envs/                       # Raíces por entorno (recomendado para aislamiento de estado)
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars    # Valores específicos (gitignored si contiene secrets)
│   │   └── backend.tf          # Key distinto: envs/dev/terraform.tfstate
│   ├── staging/
│   └── prod/
├── global/                     # Recursos compartidos (IAM, DNS, KMS)
│   ├── iam/
│   ├── dns/
│   └── kms/
├── stacks/                     # Terraform Stacks (v1.13+) para orquestación compleja
│   ├── components.tfcomponent.hcl
│   ├── deployments.tfdeploy.hcl
│   └── providers.tfcomponent.hcl
├── scripts/
│   ├── drift-check.sh          # Detección programada de drift
│   ├── state-export.sh         # Backup y exportación de estado
│   ├── import-helper.sh        # Asistente para importación masiva
│   └── validate-all.sh         # Validación recursiva de todos los entornos
├── policies/                   # Políticas OPA/Rego personalizadas
│   ├── aws_s3_encryption.rego
│   ├── aws_iam_no_wildcards.rego
│   └── required_tags.rego
└── diagrams/                   # Diagramas generados desde Terraform (Eraser DSL)
    ├── architecture.eraser
    └── network-topology.eraser
```

### 3.2 Configuración del Backend Remoto (S3 + DynamoDB)

```hcl
# backend.tf
terraform {
  required_version = ">= 1.6.0, < 2.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "mantis-terraform-state"
    key            = "envs/${terraform.workspace}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    kms_key_id     = "alias/terraform-state-key"
    dynamodb_table = "terraform-state-lock"
    
    # Opcional: prefijo por workspace para aislamiento adicional
    workspace_key_prefix = "workspaces"
    
    # Opcional: asumir rol para acceso cross-account
    # role_arn = "arn:aws:iam::123456789012:role/TerraformStateAccess"
  }
}
```

**Infraestructura del backend (bootstrap):**
```hcl
# bootstrap/main.tf - Ejecutar primero con backend local
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# S3 Bucket para Estado
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.company}-terraform-state-${var.region}"
  
  tags = {
    Name        = "Terraform State"
    Environment = "shared"
    ManagedBy   = "terraform"
    Project     = var.project
  }
  
  lifecycle {
    prevent_destroy = true  # Protección contra eliminación accidental
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_state.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    id     = "state-versions"
    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
  }
}

# DynamoDB Table para State Locking
resource "aws_dynamodb_table" "terraform_lock" {
  name           = "terraform-state-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
  
  server_side_encryption {
    enabled = true
  }
  
  point_in_time_recovery {
    enabled = true
  }
  
  tags = {
    Name        = "Terraform State Lock"
    Environment = "shared"
    ManagedBy   = "terraform"
  }
}

# KMS Key para Cifrado de Estado
resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for Terraform state encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Terraform Role"
        Effect = "Allow"
        Principal = {
          AWS = var.terraform_role_arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = {
    Name = "Terraform State Key"
  }
}

resource "aws_kms_alias" "terraform_state" {
  name          = "alias/terraform-state-key"
  target_key_id = aws_kms_key.terraform_state.key_id
}

data "aws_caller_identity" "current" {}

# Outputs
output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.id
}

output "lock_table_name" {
  value = aws_dynamodb_table.terraform_lock.name
}

output "kms_key_arn" {
  value = aws_kms_key.terraform_state.arn
}
```

### 3.3 Providers y Autenticación Segura (OIDC)

**Priorizar OIDC para eliminar credenciales longevas:**
```hcl
# providers.tf
provider "aws" {
  region = var.aws_region
  
  # Workload Identity Federation (OIDC) - preferido sobre claves estáticas
  assume_role_with_web_identity {
    role_arn           = var.terraform_role_arn
    web_identity_token = var.identity_token  # Token efímero, no persiste en estado
    session_name       = "terraform-${var.environment}"
  }
  
  # Tags comunes aplicados a todos los recursos gestionados por este provider
  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = var.project
      Team        = var.team
    }
  }
}

# Para múltiples regiones o cuentas
provider "aws" "regions" {
  for_each = var.regions
  
  region = each.value
  
  assume_role_with_web_identity {
    role_arn           = var.terraform_role_arn
    web_identity_token = var.identity_token
    session_name       = "terraform-${each.key}"
  }
  
  default_tags {
    tags = merge(local.common_tags, {
      Region = each.key
    })
  }
}
```

**Variables para OIDC:**
```hcl
# variables.tf
variable "identity_token" {
  description = "OIDC identity token for workload identity federation"
  type        = string
  sensitive   = true
  ephemeral   = true  # No persiste en estado (Terraform 1.10+)
}

variable "terraform_role_arn" {
  description = "ARN of the IAM role to assume via OIDC"
  type        = string
  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]+:role/", var.terraform_role_arn))
    error_message = "Must be a valid AWS IAM role ARN"
  }
}

variable "regions" {
  description = "Map of region names to region codes for multi-region deployments"
  type        = map(string)
  default = {
    us-east-1 = "us-east-1"
    us-west-2 = "us-west-2"
  }
}
```

### 3.4 Variables, Locales y Validación

**Variables de entrada con validación robusta:**
```hcl
# variables.tf
variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project" {
  description = "Project name for resource tagging and naming"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.project))
    error_message = "Project name must start with a letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "team" {
  description = "Team responsible for this infrastructure"
  type        = string
  default     = "platform"
}

variable "instance_type" {
  description = "EC2 instance type for application servers"
  type        = string
  default     = "t3.medium"
  
  validation {
    condition     = can(regex("^[a-z][0-9][.][a-z]+$", var.instance_type))
    error_message = "Instance type must be a valid AWS instance type format (e.g., t3.medium)."
  }
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring and alerting"
  type        = bool
  default     = false
}

variable "min_instances" {
  description = "Minimum number of instances in Auto Scaling Group"
  type        = number
  default     = 1
  
  validation {
    condition     = var.min_instances >= 1 && var.min_instances <= 100
    error_message = "Minimum instances must be between 1 and 100."
  }
}

variable "max_instances" {
  description = "Maximum number of instances in Auto Scaling Group"
  type        = number
  default     = 3
  
  validation {
    condition     = var.max_instances >= var.min_instances && var.max_instances <= 100
    error_message = "Maximum instances must be >= min_instances and <= 100."
  }
}

# Variables sensibles (nunca commitear valores reales)
variable "database_password" {
  description = "Master password for RDS instance (provide via env var or secret manager)"
  type        = string
  sensitive   = true
  nullable    = false
  
  validation {
    condition     = length(var.database_password) >= 16
    error_message = "Database password must be at least 16 characters."
  }
}

# Variables complejas con tipos anidados
variable "vpc_config" {
  description = "VPC configuration for the module"
  type = object({
    vpc_id             = string
    subnet_ids         = list(string)
    security_group_ids = optional(list(string), [])
    assign_public_ip   = optional(bool, false)
  })
  
  validation {
    condition     = length(var.vpc_config.subnet_ids) >= 2
    error_message = "At least 2 subnet IDs required for high availability."
  }
}

variable "tags" {
  description = "Additional tags to apply to all taggable resources"
  type        = map(string)
  default     = {}
  
  validation {
    condition = alltrue([
      for k, v in var.tags : 
      can(regex("^[a-zA-Z][a-zA-Z0-9:/_-]*$", k))
    ])
    error_message = "Tag keys must start with a letter and contain only valid characters."
  }
}
```

**Locales para valores computados y convenciones:**
```hcl
# locals.tf
locals {
  # Convención de nombres
  name_prefix = "${var.project}-${var.environment}"
  
  # Tags comunes aplicados a todos los recursos
  common_tags = merge(
    var.tags,
    {
      Name        = local.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = var.project
      Team        = var.team
      Terraform   = "true"
    }
  )
  
  # Valores condicionales por entorno
  is_production      = var.environment == "prod"
  enable_encryption  = local.is_production
  backup_retention   = local.is_production ? 30 : 7
  instance_count_min = local.is_production ? 3 : var.min_instances
  instance_count_max = local.is_production ? 10 : var.max_instances
  
  # Configuración de monitoreo derivada
  monitoring_config = {
    enabled         = var.enable_monitoring || local.is_production
    detailed        = local.is_production
    retention_days  = local.is_production ? 90 : 30
    alarm_threshold = local.is_production ? 80 : 90
  }
  
  # Helpers para dynamic blocks
  ingress_rules_map = {
    for idx, rule in var.ingress_rules :
    "${rule.protocol}-${rule.from_port}-${rule.to_port}" => rule
  }
  
  # Naming condicional para recursos
  bucket_name = var.bucket_name != null ? var.bucket_name : "${local.name_prefix}-storage-${random_id.bucket.hex}"
}
```

## 4. Desarrollo de Módulos Reutilizables

### 4.1 Plantilla de Módulo Estándar

**Estructura de directorios:**
```
modules/vpc/
├── main.tf           # Definiciones de recursos principales
├── variables.tf      # Declaración de variables de entrada
├── outputs.tf        # Definición de salidas expuestas
├── versions.tf       # Restricciones de versión de providers
├── locals.tf         # Valores locales computados
├── data.tf           # Data sources para lookup de recursos existentes
├── README.md         # Documentación del módulo (auto-generada con terraform-docs)
├── CHANGELOG.md      # Historial de versiones (semver)
├── examples/
│   ├── basic/
│   │   ├── main.tf
│   │   └── outputs.tf
│   └── advanced/
│       ├── main.tf
│       └── outputs.tf
└── tests/
    └── module_test.go  # Pruebas con Terratest
```

**versions.tf (pines estrictos):**
```hcl
terraform {
  required_version = ">= 1.5.0, < 2.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
}
```

**variables.tf con validación exhaustiva:**
```hcl
# variables.tf
variable "name" {
  description = "Name prefix for all resources created by this module"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.name))
    error_message = "Name must start with a letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.cidr_block))
    error_message = "CIDR block must be valid IPv4 CIDR notation (e.g., 10.0.0.0/16)."
  }
}

variable "availability_zones" {
  description = "List of availability zones for subnet distribution"
  type        = list(string)
  
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones required for high availability."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for cidr in var.private_subnet_cidrs :
      can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", cidr))
    ])
    error_message = "All subnet CIDRs must be valid IPv4 CIDR notation."
  }
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in VPC"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Create NAT Gateway for private subnet internet access"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway for all AZs (cost optimization for non-prod)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
```

**main.tf con mejores prácticas:**
```hcl
# main.tf
#------------------------------------------------------------------------------
# VPC Principal
#------------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = true
  
  tags = merge(local.common_tags, {
    Name = "${var.name}-vpc"
    Type = "vpc"
  })
  
  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false  # Permitir destrucción controlada
  }
}

#------------------------------------------------------------------------------
# Subnets Privadas (for_each para estabilidad)
#------------------------------------------------------------------------------
resource "aws_subnet" "private" {
  for_each = {
    for idx, cidr in var.private_subnet_cidrs :
    var.availability_zones[idx] => {
      cidr = cidr
      az   = var.availability_zones[idx]
    }
  }
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  
  tags = merge(local.common_tags, {
    Name = "${var.name}-private-${each.key}"
    Tier = "private"
    AZ   = each.value.az
  })
}

#------------------------------------------------------------------------------
# Internet Gateway (condicional)
#------------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  count  = var.enable_nat_gateway ? 1 : 0
  vpc_id = aws_vpc.main.id
  
  tags = merge(local.common_tags, {
    Name = "${var.name}-igw"
  })
}

#------------------------------------------------------------------------------
# NAT Gateway (condicional, single vs multi-AZ)
#------------------------------------------------------------------------------
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway && !var.single_nat_gateway ? length(var.availability_zones) : (var.enable_nat_gateway ? 1 : 0)
  domain = "vpc"
  
  tags = merge(local.common_tags, {
    Name = "${var.name}-nat-eip-${count.index + 1}"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_nat_gateway" "main" {
  count  = var.enable_nat_gateway && !var.single_nat_gateway ? length(var.availability_zones) : (var.enable_nat_gateway ? 1 : 0)
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = merge(local.common_tags, {
    Name = "${var.name}-nat-${count.index + 1}"
  })
  
  depends_on = [aws_internet_gateway.main]
}

#------------------------------------------------------------------------------
# Route Tables
#------------------------------------------------------------------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  
  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[route.key].id
    }
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.name}-private-rt"
    Tier = "private"
  })
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private
  
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
```

**outputs.tf con salidas esenciales:**
```hcl
# outputs.tf
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = values(aws_subnet.private)[*].id
}

output "public_subnet_ids" {
  description = "IDs of public subnets (if created)"
  value       = var.enable_nat_gateway ? values(aws_subnet.public)[*].id : []
}

output "vpc_cidr_block" {
  description = "CIDR block of VPC"
  value       = aws_vpc.main.cidr_block
}

output "nat_gateway_ips" {
  description = "Public IPs of NAT Gateways (for allowlisting)"
  value       = var.enable_nat_gateway ? aws_eip.nat[*].public_ip : []
  sensitive   = false
}

output "security_group_id" {
  description = "ID of the default security group for the VPC"
  value       = aws_vpc.main.default_security_group_id
}
```

### 4.2 Composición de Módulos en Root Module

```hcl
# envs/prod/main.tf
terraform {
  required_version = ">= 1.6.0"
}

provider "aws" {
  region = var.aws_region
  
  assume_role_with_web_identity {
    role_arn           = var.terraform_role_arn
    web_identity_token = var.identity_token
    session_name       = "terraform-prod"
  }
  
  default_tags {
    tags = local.common_tags
  }
}

#------------------------------------------------------------------------------
# Módulo de Red (VPC)
#------------------------------------------------------------------------------
module "vpc" {
  source = "../../modules/vpc"
  
  name                 = var.project
  cidr_block           = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  enable_nat_gateway   = true
  single_nat_gateway   = false  # Multi-AZ NAT para prod
  tags                 = local.common_tags
}

#------------------------------------------------------------------------------
# Módulo de Base de Datos (RDS con pgvector)
#------------------------------------------------------------------------------
module "database" {
  source = "../../modules/database"
  
  identifier           = "${var.project}-db"
  engine               = "postgres"
  engine_version       = "15.4"
  instance_class       = "db.r6g.large"
  allocated_storage    = 100
  max_allocated_storage = 500
  
  # Integración con VPC
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnet_ids
  security_group_ids   = [module.vpc.security_group_id]
  
  # Configuración de pgvector (V1-V3)
  enable_pgvector      = true
  vector_dimension     = 1536  # V1: declaración explícita
  vector_index_type    = "hnsw"  # V3: justificación en comentario
  # V2: distancia cosine (<=>) documentada en queries
  
  # Secrets gestionados externamente
  master_username      = var.db_username
  master_password      = var.db_password  # sensitive = true
  
  # Backup y recuperación
  backup_retention_period = local.backup_retention
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  
  # Tags
  tags = merge(local.common_tags, {
    Role = "database"
    pgvector_enabled = "true"
  })
  
  depends_on = [module.vpc]
}

#------------------------------------------------------------------------------
# Módulo de Aplicación (Compute)
#------------------------------------------------------------------------------
module "app" {
  source = "../../modules/compute"
  
  name                 = var.project
  environment          = var.environment
  instance_type        = var.instance_type
  min_instances        = local.instance_count_min
  max_instances        = local.instance_count_max
  
  # Integración con VPC y DB
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnet_ids
  security_group_ids   = [module.vpc.security_group_id]
  db_endpoint          = module.database.endpoint
  db_name              = module.database.db_name
  
  # Configuración de monitoreo
  enable_monitoring    = local.monitoring_config.enabled
  alarm_actions        = var.alarm_actions
  
  # Secrets
  app_secret           = var.app_secret
  
  tags = local.common_tags
  
  depends_on = [module.vpc, module.database]
}

#------------------------------------------------------------------------------
# Outputs para integración con otros agentes
#------------------------------------------------------------------------------
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "db_endpoint" {
  value     = module.database.endpoint
  sensitive = true
}

output "app_security_group_id" {
  value = module.app.security_group_id
}

output "nat_gateway_ips" {
  value = module.vpc.nat_gateway_ips
}
```

### 4.3 Testing de Módulos con Terratest

```go
// tests/vpc_test.go
package test

import (
	"testing"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestVPCModule(t *testing.T) {
	t.Parallel()
	
	terraformOptions := &terraform.Options{
		TerraformDir: "../examples/complete",
		Vars: map[string]interface{}{
			"name":               "test",
			"cidr_block":         "10.0.0.0/16",
			"availability_zones": []string{"us-east-1a", "us-east-1b"},
			"private_subnet_cidrs": []string{"10.0.1.0/24", "10.0.2.0/24"},
		},
		NoColor: true,
	}
	
	// Cleanup at end of test
	defer terraform.Destroy(t, terraformOptions)
	
	// Init and Apply
	terraform.InitAndApply(t, terraformOptions)
	
	// Validate outputs
	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	assert.NotEmpty(t, vpcID, "VPC ID should not be empty")
	
	subnetIDs := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
	assert.Equal(t, 2, len(subnetIDs), "Should have 2 private subnets")
	
	// Validate resource attributes via AWS API
	vpc := GetVPC(t, vpcID)  // Helper function using AWS SDK
	assert.Equal(t, "10.0.0.0/16", *vpc.CidrBlock)
	assert.True(t, *vpc.EnableDnsHostnames)
}
```

## 5. Gestión de Estado — Operaciones, Migración y Recuperación

### 5.1 Comandos Esenciales de Estado

```bash
# Listar recursos en estado
terraform state list

# Mostrar detalle de un recurso
terraform state show aws_instance.web

# Ver estado como JSON (para análisis programático)
terraform show -json | jq '.values.root_module.resources'

# Pull de estado remoto a archivo local (backup)
terraform state pull > backup-$(date +%Y%m%d%H%M%S).tfstate

# Push de estado local a remoto (¡usar con extrema precaución!)
terraform state push terraform.tfstate

# Obtener outputs del estado
terraform output -json

# Mover recurso dentro del estado (refactorización de módulos)
terraform state mv aws_instance.web module.compute.aws_instance.web

# Mover recurso entre archivos de estado
terraform state mv -state-out=env/prod/terraform.tfstate module.prod.vpc module.prod.vpc

# Eliminar recurso del estado (sin destruir el recurso real)
terraform state rm aws_instance.temporary

# Forzar reemplazo de recurso en próximo apply
terraform apply -replace="aws_instance.web"

# Importar recurso existente al estado
terraform import aws_instance.web i-1234567890abcdef0
```

### 5.2 Migración de Backend (Local → Remoto)

```bash
# Paso 1: Agregar configuración de backend a terraform files
# backend.tf (ver ejemplo S3 arriba)

# Paso 2: Inicializar con migración
terraform init -migrate-state

# Terraform preguntará:
# Do you want to copy existing state to the new backend?
# Responder: yes

# Paso 3: Verificar migración
terraform state list
terraform plan  # Debería mostrar: No changes. Infrastructure is up-to-date.
```

### 5.3 Recuperación ante Corrupción de Estado

```bash
#!/usr/bin/env bash
# scripts/state-recovery.sh
set -euo pipefail

BUCKET="mantis-terraform-state"
KEY="envs/prod/terraform.tfstate"
REGION="us-east-1"

echo "🔄 Iniciando recuperación de estado para $KEY"

# Paso 1: Listar versiones disponibles en S3
echo "📋 Listando versiones disponibles..."
aws s3api list-object-versions \
  --bucket "$BUCKET" \
  --prefix "$KEY" \
  --max-items 10 \
  --region "$REGION" \
  --query 'Versions[*].[VersionId,LastModified,Size]' \
  --output table

# Paso 2: Descargar versión específica (reemplazar VERSION_ID)
VERSION_ID="abc123..."  # Obtener de lista anterior
echo "⬇️ Descargando versión $VERSION_ID..."
aws s3api get-object \
  --bucket "$BUCKET" \
  --key "$KEY" \
  --version-id "$VERSION_ID" \
  --region "$REGION" \
  recovered.tfstate

# Paso 3: Validar estado recuperado
echo "✅ Validando estado recuperado..."
terraform show -json recovered.tfstate | jq '.values.root_module.resources | length'

# Paso 4: Push de estado recuperado (solo si validación exitosa)
read -p "¿Confirmar push de estado recuperado? (yes/no): " confirm
if [ "$confirm" = "yes" ]; then
  terraform state push recovered.tfstate
  echo "✅ Estado recuperado aplicado"
else
  echo "❌ Operación cancelada por usuario"
  exit 1
fi
```

### 5.4 Desbloqueo Forzado de Estado

```bash
# Obtener Lock ID del mensaje de error:
# "Error acquiring the state lock: ConditionalCheckFailedException..."
# Lock ID: 12345678-1234-1234-1234-123456789012

# Verificar locks existentes en DynamoDB
aws dynamodb scan \
  --table-name terraform-state-lock \
  --projection-expression "LockID, Info" \
  --output table

# Forzar desbloqueo (SOLO si se confirma que no hay operación en curso)
terraform force-unlock 12345678-1234-1234-1234-123456789012

# Como último recurso: eliminar lock manualmente en DynamoDB
aws dynamodb delete-item \
  --table-name terraform-state-lock \
  --key '{"LockID": {"S": "terraform-state/envs/prod/terraform.tfstate"}}'
```

## 6. Estrategias Multi‑Entorno

### 6.1 Separación por Directorios (Recomendado para Prod/Staging)

```
envs/
├── dev/
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars    # Valores de desarrollo (gitignored si tiene secrets)
│   └── backend.tf          # key: envs/dev/terraform.tfstate
├── staging/
│   └── ...                 # key: envs/staging/terraform.tfstate
└── prod/
    └── ...                 # key: envs/prod/terraform.tfstate
```

**Ventajas:**
- Aislamiento completo de estados (un error en dev no afecta prod)
- Variables y configuraciones específicas por entorno
- Backends independientes con políticas de acceso diferenciadas

### 6.2 Workspaces para Entornos Efímeros

```bash
# Crear y seleccionar workspace para feature branch
terraform workspace new feature-auth
terraform workspace select feature-auth

# Usar workspace name en configuración para variar recursos
locals {
  environment = terraform.workspace
  config = {
    dev = { instance_type = "t3.small", min_size = 1 }
    staging = { instance_type = "t3.medium", min_size = 2 }
    prod = { instance_type = "t3.large", min_size = 3 }
  }
  env_config = local.config[local.environment]
}

resource "aws_instance" "app" {
  instance_type = local.env_config.instance_type
  tags = { Environment = local.environment }
}

# Limpiar workspace feature al finalizar
terraform workspace select default
terraform destroy -target=module.feature_auth  # Destruir solo recursos del feature
terraform workspace delete feature-auth
```

**Advertencia:** No usar workspaces para entornos de larga duración (prod/staging) debido al riesgo de corrupción cruzada de estados.

### 6.3 Terraform Stacks (v1.13+) para Orquestación Compleja

**components.tfcomponent.hcl:**
```hcl
# Componente de VPC
component "vpc" {
  source  = "app.terraform.io/mantis-org/vpc/aws"
  version = "2.1.0"
  
  inputs = {
    cidr_block  = var.vpc_cidr
    name_prefix = var.name_prefix
    tags        = local.common_tags
  }
  
  providers = {
    aws = provider.aws.this
  }
}

# Componente de Base de Datos (depende de VPC)
component "database" {
  source = "app.terraform.io/mantis-org/database/aws"
  
  inputs = {
    identifier     = "${var.name_prefix}-db"
    vpc_id         = component.vpc.vpc_id
    subnet_ids     = component.vpc.private_subnet_ids
    enable_pgvector = true
    vector_dimension = 1536  # V1
  }
  
  providers = {
    aws = provider.aws.this
  }
  
  # Dependencia inferida automáticamente por referencia a component.vpc
}

# Componente de Aplicación (depende de VPC y DB)
component "app" {
  source = "app.terraform.io/mantis-org/compute/aws"
  
  inputs = {
    name          = var.name_prefix
    vpc_id        = component.vpc.vpc_id
    subnet_ids    = component.vpc.private_subnet_ids
    db_endpoint   = component.database.endpoint
    instance_type = var.instance_type
  }
  
  providers = {
    aws = provider.aws.this
  }
}
```

**deployments.tfdeploy.hcl:**
```hcl
# Token OIDC para autenticación
identity_token "aws" {
  audience = ["aws.workload.identity"]
}

# Deployment para producción
deployment "production" {
  inputs = {
    aws_region      = "us-east-1"
    name_prefix     = "mantis-prod"
    vpc_cidr        = "10.0.0.0/16"
    instance_type   = "t3.large"
    identity_token  = identity_token.aws.jwt
  }
}

# Deployment para staging
deployment "staging" {
  inputs = {
    aws_region      = "us-east-1"
    name_prefix     = "mantis-staging"
    vpc_cidr        = "10.1.0.0/16"
    instance_type   = "t3.medium"
    identity_token  = identity_token.aws.jwt
  }
}
```

**Comandos CLI de Stacks:**
```bash
# Inicializar Stack (descarga providers, genera lock file)
terraform stacks init

# Validar configuración sin upload
terraform stacks validate

# Upload de configuración (dispara runs de deployment)
terraform stacks configuration upload

# Listar deployment runs
terraform stacks deployment-run list

# Aprobar planes (si no hay auto-approve configurado)
terraform stacks deployment-run approve-all-plans -deployment-run-id=run-abc123

# Monitorear estado (no blocking para CI/CD)
terraform stacks deployment-run list --json | jq '.[] | {id: .id, status: .status}'
```

## 7. CI/CD y Automatización con GitHub Actions

### 7.1 Pipeline Estándar `terraform-plan.yml`

```yaml
# .github/workflows/terraform-plan.yml
name: Terraform Plan & Apply

on:
  pull_request:
    branches: [main]
    paths: ['05-CONFIGURATIONS/Terraform/**']
  push:
    branches: [main]
    paths: ['05-CONFIGURATIONS/Terraform/**']
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        type: choice
        options: [dev, staging, prod]

env:
  TF_VERSION: "1.14.5"
  AWS_REGION: "us-east-1"

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
      
      - name: Terraform Init
        working-directory: 05-CONFIGURATIONS/Terraform/envs/${{ inputs.environment || 'dev' }}
        run: terraform init -backend-config="key=envs/${{ inputs.environment || 'dev' }}/terraform.tfstate"
      
      - name: Terraform Validate
        working-directory: 05-CONFIGURATIONS/Terraform/envs/${{ inputs.environment || 'dev' }}
        run: terraform validate
      
      - name: Terraform Fmt Check
        working-directory: 05-CONFIGURATIONS/Terraform
        run: terraform fmt -recursive -check

  security-scan:
    needs: validate
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Checkov
        uses: bridgecrewio/checkov-action@master
        with:
          directory: 05-CONFIGURATIONS/Terraform
          framework: terraform
          output_format: sarif
          output_file_path: checkov.sarif
          soft_fail: false
      
      - name: Run tfsec
        uses: aquasecurity/tfsec-action@v1.0.0
        with:
          working_directory: 05-CONFIGURATIONS/Terraform
          soft_fail: false
      
      - name: Upload SARIF to GitHub Security
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: checkov.sarif
      
      - name: OPA Policy Check
        run: |
          conftest test 05-CONFIGURATIONS/Terraform \
            --policy 05-CONFIGURATIONS/Terraform/policies \
            --output json

  plan:
    needs: [validate, security-scan]
    runs-on: ubuntu-latest
    permissions:
      id-token: write  # OIDC para AWS
      contents: read
      pull-requests: write
    outputs:
      plan_exists: ${{ steps.plan.outputs.plan_exists }}
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.TERRAFORM_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
      
      - name: Terraform Init
        working-directory: 05-CONFIGURATIONS/Terraform/envs/${{ inputs.environment || 'dev' }}
        run: terraform init -backend-config="key=envs/${{ inputs.environment || 'dev' }}/terraform.tfstate"
      
      - name: Terraform Plan
        id: plan
        working-directory: 05-CONFIGURATIONS/Terraform/envs/${{ inputs.environment || 'dev' }}
        run: |
          terraform plan -no-color -out=tfplan -detailed-exitcode > plan.txt
          echo "plan_exists=true" >> $GITHUB_OUTPUT
          echo "## Terraform Plan" >> $GITHUB_STEP_SUMMARY
          echo '```' >> $GITHUB_STEP_SUMMARY
          cat plan.txt >> $GITHUB_STEP_SUMMARY
          echo '```' >> $GITHUB_STEP_SUMMARY
      
      - name: Comment PR with Plan
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const plan = fs.readFileSync('05-CONFIGURATIONS/Terraform/envs/${{ inputs.environment || 'dev' }}/plan.txt', 'utf8');
            const output = `### 📋 Terraform Plan\n\n\`\`\`\n${plan}\n\`\`\`\n\n**Environment**: \`${{ inputs.environment || 'dev' }}\`\n**Security Scan**: ✅ Passed\n\n⚠️ **Review carefully before approving apply**.`;
            await github.rest.issues.createComment({
              issue_number: context.payload.pull_request.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            });
      
      - name: Upload Plan Artifact
        uses: actions/upload-artifact@v4
        with:
          name: tfplan-${{ inputs.environment || 'dev' }}
          path: 05-CONFIGURATIONS/Terraform/envs/${{ inputs.environment || 'dev' }}/tfplan
          retention-days: 1

  apply:
    needs: [plan]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && (github.event_name == 'push' || github.event_name == 'workflow_dispatch')
    environment:
      name: ${{ inputs.environment || 'dev' }}
      url: https://${{ inputs.environment || 'dev' }}.mantis.example.com
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      
      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.TERRAFORM_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
      
      - name: Download Plan Artifact
        uses: actions/download-artifact@v4
        with:
          name: tfplan-${{ inputs.environment || 'dev' }}
          path: 05-CONFIGURATIONS/Terraform/envs/${{ inputs.environment || 'dev' }}
      
      - name: Terraform Apply
        working-directory: 05-CONFIGURATIONS/Terraform/envs/${{ inputs.environment || 'dev' }}
        run: terraform apply -auto-approve tfplan
      
      - name: Notify Success
        if: success()
        run: |
          curl -X POST ${{ secrets.SLACK_WEBHOOK }} \
            -H 'Content-type: application/json' \
            --data "{
              \"text\": \"✅ Terraform apply exitoso en ${{ inputs.environment || 'dev' }}\\n*Commit*: ${{ github.sha }}\\n*Ambiente*: ${{ inputs.environment || 'dev' }}\\n*URL*: https://${{ inputs.environment || 'dev' }}.mantis.example.com\"
            }"
```

### 7.2 Detección Programada de Drift

```bash
#!/usr/bin/env bash
# scripts/drift-check.sh
set -euo pipefail

WORKSPACES=("dev" "staging" "prod")
DRIFT_FOUND=false

for ws in "${WORKSPACES[@]}"; do
  echo "🔍 Verificando drift en workspace: $ws"
  
  cd "05-CONFIGURATIONS/Terraform/envs/$ws"
  
  # Inicializar si es necesario
  terraform init -backend-config="key=envs/$ws/terraform.tfstate" -input=false
  
  # Ejecutar plan con código de salida detallado
  set +e
  terraform plan -detailed-exitcode -out=plan-$ws.tfplan > /dev/null 2>&1
  EXIT_CODE=$?
  set -e
  
  if [ $EXIT_CODE -eq 2 ]; then
    echo "⚠️  DRIFT DETECTADO en $ws"
    terraform show -json plan-$ws.tfplan | \
      jq -r '.resource_changes[] | select(.change.actions != ["no-op"]) | "  - \(.address): \(.change.actions | join(", "))"'
    
    # Notificar a Slack
    curl -X POST "$SLACK_WEBHOOK" \
      -H 'Content-type: application/json' \
      --data "{
        \"text\": \"⚠️ Drift detectado en $ws\\nRecursos afectados:\\n$(terraform show -json plan-$ws.tfplan | jq -r '.resource_changes[] | select(.change.actions != [\"no-op\"]) | \"  - \(.address)\")'\\n[Ver detalles en GitHub Actions]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID)\"
      }"
    
    DRIFT_FOUND=true
  elif [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Sin drift en $ws"
  else
    echo "❌ Error verificando $ws"
  fi
  
  # Limpiar plan temporal
  rm -f plan-$ws.tfplan
  cd - > /dev/null
done

if [ "$DRIFT_FOUND" = true ]; then
  echo "🚨 Drift detectado en uno o más entornos. Revisar notificaciones."
  exit 2
else
  echo "✅ Todos los entornos sincronizados."
  exit 0
fi
```

### 7.3 Revisión de Planes con Agentes Paralelos

```yaml
# En pipeline de review de PR, invocar análisis paralelo:
- name: Parallel Plan Analysis
  run: |
    # Agente 1: Analizador de riesgos
    python scripts/analyze-risks.py --plan tfplan.json --output risks.json &
    
    # Agente 2: Revisor de seguridad
    python scripts/security-review.py --plan tfplan.json --output security.json &
    
    # Agente 3: Analizador histórico (git)
    python scripts/historical-patterns.py --resources $(jq -r '.resource_changes[].address' tfplan.json) --output history.json &
    
    wait  # Esperar todos los agentes
    
    # Agregar resultados al comentario de PR
    python scripts/aggregate-review.py risks.json security.json history.json >> pr-comment.md
```

## 8. Seguridad y Cumplimiento en IaC

### 8.1 Principios de Seguridad en Terraform

| Principio | Implementación en MANTIS |
|-----------|-------------------------|
| **No almacenar secrets en texto plano** | Variables con `sensitive = true`, OIDC para credenciales, secrets montados como archivos en `/run/secrets/` |
| **Cifrado del estado** | Bucket S3 con KMS (`encrypt = true`, `kms_key_id`), TLS en tránsito, versionado habilitado |
| **Línea base CIS** | Escaneo con `checkov -d ./terraform/ --framework terraform --check CKV_AWS_*`, bloqueo de pipelines con hallazgos CRITICAL/HIGH |
| **Políticas OPA personalizadas** | Reglas Rego para: tags obligatorios, denegar wildcards en IAM, requerir cifrado en S3/RDS, prohibir puertos abiertos a 0.0.0.0 |
| **Auditoría de infraestructura desplegada** | Exportar estado con `terraform show -json > state.json` y escanear con Checkov para identificar desviaciones en recursos existentes |

### 8.2 Políticas OPA/Rego de Ejemplo

```rego
# policies/aws_s3_encryption.rego
package terraform.aws.s3

deny[msg] {
  resource := input.resource.aws_s3_bucket[name]
  not resource.server_side_encryption_configuration
  msg := sprintf("S3 bucket '%s' must have server-side encryption enabled", [name])
}

deny[msg] {
  resource := input.resource.aws_s3_bucket[name]
  resource.acl == "public-read"
  msg := sprintf("S3 bucket '%s' must not have public-read ACL", [name])
}

# policies/aws_iam_no_wildcards.rego
package terraform.aws.iam

deny[msg] {
  resource := input.resource.aws_iam_policy[name]
  statement := resource.policy.Statement[_]
  statement.Action == "*"
  statement.Effect == "Allow"
  msg := sprintf("IAM policy '%s' must not use wildcard (*) actions", [name])
}

deny[msg] {
  resource := input.resource.aws_iam_policy[name]
  statement := resource.policy.Statement[_]
  statement.Resource == "*"
  contains(statement.Action[_], "*")
  msg := sprintf("IAM policy '%s' has overly permissive actions on wildcard resources", [name])
}

# policies/required_tags.rego
package terraform.required_tags

deny[msg] {
  resource := input.resource[_]
  not resource.tags.Environment
  msg := sprintf("Resource '%s' must have tag 'Environment'", [resource.__address__])
}

deny[msg] {
  resource := input.resource[_]
  not resource.tags.ManagedBy
  msg := sprintf("Resource '%s' must have tag 'ManagedBy'", [resource.__address__])
}
```

**Ejecutar políticas en CI/CD:**
```bash
# Convertir plan a JSON y evaluar con OPA
terraform show -json tfplan | opa eval \
  --data 05-CONFIGURATIONS/Terraform/policies \
  --input /dev/stdin \
  "data.terraform" \
  --format pretty

# O usar Conftest para integración más sencilla
conftest test tfplan.json \
  --policy 05-CONFIGURATIONS/Terraform/policies \
  --output json \
  --fail-on-warn
```

### 8.3 Escaneo de Seguridad con Checkov/tfsec/Terrascan

```bash
# Checkov: escaneo comprehensivo
checkov -d 05-CONFIGURATIONS/Terraform \
  --framework terraform \
  --check CKV_AWS_18,CKV_AWS_19,CKV_AWS_20,CKV_AWS_21 \
  --output json > checkov-results.json

# tfsec: análisis específico de Terraform
tfsec 05-CONFIGURATIONS/Terraform \
  --minimum-severity HIGH \
  --format json > tfsec-results.json

# Terrascan: cumplimiento CIS/NIST
terrascan scan \
  -t aws \
  -i terraform \
  -d 05-CONFIGURATIONS/Terraform \
  --policy-type aws \
  --categories "Compliance Validation" \
  --output json > terrascan-results.json

# Integrar en pipeline: fallar si hay hallazgos CRITICAL
jq -e '.results[] | select(.check_id | startswith("CKV_AWS")) | select(.severity == "CRITICAL")' checkov-results.json && \
  { echo "❌ Hallazgos CRÍTICOS en Checkov"; exit 1; } || \
  echo "✅ Sin hallazgos CRÍTICOS"
```

## 9. Detección y Remedición de Drift

### 9.1 Categorías de Drift y Severidad

| Categoría | Severidad | Ejemplos | Acción Recomendada |
|-----------|-----------|----------|-------------------|
| **Security Drift** | CRITICAL | Security groups abiertos, IAM policies relajadas, cifrado deshabilitado | Rechazar drift, revertir cambios, investigar causa raíz |
| **Configuration Drift** | HIGH | Instance type cambiado, parámetros de DB modificados, rutas de red alteradas | Evaluar impacto; aceptar si intencional y documentado, rechazar si no |
| **Tag Drift** | MEDIUM | Tags modificados manualmente, missing required tags | Aceptar si no afecta funcionalidad; actualizar HCL para prevenir recurrencia |
| **Metadata Drift** | LOW | Campos gestionados por AWS (ARNs, IDs), timestamps actualizados | Aceptar automáticamente; no requiere acción |

### 9.2 Script de Detección con Reporte Estructurado

```bash
#!/usr/bin/env bash
# scripts/drift-report.sh
set -euo pipefail

ENVIRONMENT="${1:?Usage: drift-report.sh <environment>}"
WORKDIR="05-CONFIGURATIONS/Terraform/envs/$ENVIRONMENT"

cd "$WORKDIR"

# Inicializar
terraform init -backend-config="key=envs/$ENVIRONMENT/terraform.tfstate" -input=false

# Generar plan de refresh-only (detecta drift sin aplicar cambios)
terraform plan -refresh-only -out=drift.out -no-color

# Convertir a JSON para análisis
terraform show -json drift.out > drift.json

# Analizar y categorizar
python3 << 'PYTHON'
import json, sys

with open('drift.json') as f:
    data = json.load(f)

drifted = [r for r in data.get('resource_changes', []) if r['change']['actions'] != ['no-op']]

if not drifted:
    print("✅ No drift detected")
    sys.exit(0)

print(f"⚠️  {len(drifted)} resources with drift:\n")
for r in drifted:
    addr = r['address']
    actions = r['change']['actions']
    print(f"  - {addr}: {', '.join(actions)}")
    
    # Categorizar por severidad (simplificado)
    if 'security_group' in addr or 'iam' in addr:
        print("    🔴 CRITICAL: Security-related drift")
    elif 'instance' in addr or 'db_' in addr:
        print("    🟡 HIGH: Configuration drift")
    elif 'tag' in str(r['change']).lower():
        print("    🟢 MEDIUM: Tag drift")
    else:
        print("    🔵 LOW: Metadata drift")

print("\n### Recommended Actions")
print("1. Review each drifted resource above")
print("2. If drift is intentional: update HCL and run 'terraform apply -refresh-only'")
print("3. If drift is unintentional: run 'terraform apply' to revert")
print("4. Investigate root cause to prevent recurrence")
PYTHON

# Generar reporte JSON para integración con dashboards
jq '{
  environment: "'$ENVIRONMENT'",
  timestamp: now,
  total_drifted: (.resource_changes | map(select(.change.actions != ["no-op"])) | length),
  resources: [.resource_changes[] | select(.change.actions != ["no-op"]) | {
    address,
    type: .type,
    actions: .change.actions,
    before: .change.before,
    after: .change.after
  }]
}' drift.json > drift-report.json

echo "📄 Reporte generado: drift-report.json"
```

### 9.3 Opciones de Resolución de Drift

```bash
# Opción 1: Aceptar drift (actualizar estado para coincidir con infra real)
terraform apply -refresh-only -auto-approve

# Opción 2: Rechazar drift (revertir infra para coincidir con HCL)
terraform apply -auto-approve

# Opción 3: Investigar antes de decidir
terraform show drift.out  # Revisar cambios propuestos
# Luego decidir: apply -refresh-only o apply normal

# Opción 4: Resolver parcialmente (aceptar algunos cambios, rechazar otros)
# Editar HCL para reflejar cambios intencionales, luego apply
```

**Nunca auto-resolver drift sin aprobación humana para entornos productivos.**

## 10. Mapeo de Constraints MANTIS — Aplicación en Terraform

| Código | Descripción | Aplicación en Terraform | Herramienta de Validación |
|--------|-------------|------------------------|--------------------------|
| **C1** | Inmutabilidad de artefactos | Módulos versionados semánticamente; providers con pines estrictos (`version = "~> 5.0"`); imágenes de infraestructura promovidas sin reconstrucción | `terraform providers lock`, `terraform version`, tags con commit SHA |
| **C2** | Infraestructura como código | Todo definido en HCL; no cambios manuales en consola; backend remoto obligatorio | `terraform validate`, auditoría de cambios en CloudTrail, detección de drift |
| **C3** | Secretos nunca en texto plano | Variables con `sensitive = true`, OIDC para credenciales, secrets montados como archivos, nunca en `.tfvars` commiteados | `audit-secrets.sh`, `trivy fs --scanners secret`, revisión manual de PRs |
| **C4** | Trazabilidad de cambios | Backend con versionado habilitado, tags con commit SHA y timestamp, logs estructurados con trace_id | `terraform show -json`, CloudTrail logs, Prometheus metrics con deployment markers |
| **C5** | Validación automatizada de integridad | `terraform validate`, `terraform fmt -check`, `checkov`, `tfsec`, `conftest` en CI/CD | Pipeline GitHub Actions con gates de seguridad, `orchestrator-engine.sh --domain terraform` |
| **C6** | Aprobación de cambios críticos | Entornos protegidos en GitHub Actions, revisión de planes antes de apply, approval workflows para prod | Environment protection rules, PR comments con plan, manual approval step |
| **C7** | Rollback automatizado | Capacidad de revertir mediante versionado del estado, scripts de rollback con health checks, `destroy = true` en Stacks | `terraform state pull` para backup, `scripts/rollback.sh`, deployment groups con auto-approve condicional |
| **C8** | Calidad de entrega con pruebas | Terratest para módulos, policy as code con OPA, revisión de planes por agentes paralelos, health checks post-deploy | `go test ./tests/`, `conftest test`, `terraform plan -detailed-exitcode`, `verify-deployment.sh` |

## 11. Referencias Dentro del Dominio `05-CONFIGURATIONS/Terraform/`

| Archivo / Carpeta | Estado | Descripción |
|-------------------|--------|-------------|
| `modules/` | PLANNED/REAL | Módulos reutilizables: vpc, database, compute, networking, security |
| `envs/dev/`, `envs/staging/`, `envs/prod/` | REAL | Configuraciones raíz por entorno con backends aislados |
| `global/iam/`, `global/dns/`, `global/kms/` | PLANNED | Recursos globales compartidos entre entornos |
| `backend.tf` | REAL | Configuración del backend S3+DynamoDB con cifrado KMS |
| `versions.tf` | REAL | Pines de providers y versión de Terraform |
| `providers.tf` | REAL | Configuración de providers con OIDC/workload identity |
| `variables.tf` | REAL | Variables de entrada con validación exhaustiva |
| `locals.tf` | REAL | Valores locales computados y convenciones de naming |
| `outputs.tf` | REAL | Salidas esenciales para composición de módulos |
| `stacks/` | PLANNED | Terraform Stacks (v1.13+) para orquestación compleja |
| `policies/` | PLANNED | Políticas OPA/Rego personalizadas para seguridad y compliance |
| `scripts/drift-check.sh` | REAL | Detección programada de drift con notificaciones |
| `scripts/state-export.sh` | REAL | Exportación y backup del estado con validación |
| `scripts/rollback.sh` | REAL | Script de rollback con health checks y notificaciones |
| `scripts/import-helper.sh` | PLANNED | Asistente para importación masiva de recursos existentes |
| `diagrams/architecture.eraser` | PLANNED | Diagramas generados desde Terraform (integración Eraser API) |
| `.terraform-version` | REAL | Versión requerida de Terraform/OpenTofu |
| `.gitignore` | REAL | Excluir `.terraform/`, `*.tfstate`, `*.tfvars` con secrets |

## 12. Comandos de Validación del Dominio

```bash
# Validación rápida (pre-commit)
terraform validate
terraform fmt -recursive -check

# Chequeo de formato y sintaxis
terraform fmt -check -recursive 05-CONFIGURATIONS/Terraform

# Análisis de seguridad con Checkov
checkov -d 05-CONFIGURATIONS/Terraform --framework terraform --compact

# Escaneo con tfsec
tfsec 05-CONFIGURATIONS/Terraform --minimum-severity HIGH

# Validación de políticas OPA
conftest test 05-CONFIGURATIONS/Terraform --policy 05-CONFIGURATIONS/Terraform/policies

# Planificación completa (para revisión humana)
terraform plan -out=tfplan -detailed-exitcode -no-color

# Validación con orchestrator-engine.sh (MANTIS)
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain terraform --strict

# Validación de estado (post-apply)
terraform show -json | jq '.values.root_module.resources | length'

# Verificar que no hay secrets hardcodeados
grep -r "password\s*=" 05-CONFIGURATIONS/Terraform --include="*.tf" --exclude="*.tfvars" && echo "❌ Possible hardcoded secret" || echo "✅ No hardcoded secrets found"

# Verificar pines de providers
grep -r "version\s*=" 05-CONFIGURATIONS/Terraform/versions.tf | grep -v "~>" && echo "⚠️ Unpinned provider version" || echo "✅ Provider versions properly pinned"
```

## 13. Estilo de Trabajo del Agente — Protocolo de Ejecución

```markdown
## 🤖 Estilo de Trabajo — terraform-master-agent

### Al recibir una tarea:

1. **Evaluar modo**:
   - ¿Es análisis/revisión? → Modo A (proponer, no generar)
   - ¿Es generación de artefactos? → Modo B (generar con constraints)

2. **Consultar contexto**:
   - Leer `00-STACK-SELECTOR.md` para resolver `{language}`, perfil de infra, vertical
   - Validar que la ruta destino existe en `PROJECT_TREE.md`
   - Confirmar que `constraints_mapped` ⊆ constraints permitidas para la carpeta

3. **Aplicar constraints ANTES de generar**:
   - C1: Usar módulos versionados, providers con pines estrictos, promover artefactos sin reconstruir
   - C2: Todo en HCL; no comandos manuales en consola; backend remoto obligatorio
   - C3: Secrets como variables sensibles o archivos montados; nunca en texto plano
   - C4: Tags con commit SHA, timestamp; backend con versionado habilitado
   - C5: Incluir `validation_command` en frontmatter; validar con `terraform validate`, `checkov`, `tfsec`
   - C6: Despliegues a production solo vía pipeline con approval gates humanos
   - C7: Configurar capacidad de rollback: versionado de estado, scripts de rollback, `destroy = true` en Stacks
   - C8: Health checks post-deploy, Terratest para módulos, policy as code con OPA

4. **Generar con validación integrada**:
   - Incluir `validation_command: orchestrator-engine.sh --domain terraform --strict`
   - Agregar `checksum_sha256: "PENDING_GENERATION"` para trazabilidad
   - Usar formato parseable por IA: HCL con estructura clara, tablas Markdown para decisiones, JSON embebido para configuraciones complejas

5. **Entregar con formato estructurado**:
   ```markdown
   ### ✅ Artefacto Generado: {path}
   
   **Validación**: `orchestrator-engine.sh --domain terraform --file {path} --strict`
   
   **Checksum**: `sha256sum {path} | awk '{print $1}'`
   
   **Próximos pasos**:
   - [ ] Commit con mensaje trazable
   - [ ] Actualizar `canonical_registry.json`
   - [ ] Ejecutar pipeline de validación
   - [ ] Generar checksum final y actualizar frontmatter
   ```

### Ante ambigüedad:
- **Preguntar antes de asumir**: "¿Confirmás que este módulo debe usarse en producción o es para desarrollo?"
- **Documentar decisiones**: "Resolví backend=S3 porque el perfil de infra es standard y requiere alta disponibilidad"
- **Registrar AUDIT_FLAG**: Si se usa override, agregar `AUDIT_FLAG=backend_override_accepted`

### Anti-patrones (NUNCA):
- ❌ Generar HCL sin validar constraints primero
- ❌ Hardcodear valores de infra (mem_limit, cpu_quota) en lugar de usar variables
- ❌ Ignorar LANGUAGE_LOCK para operadores específicos de dominio (ej: pgvector en DB modules)
- ❌ Omitir `validation_command` en frontmatter de nuevos archivos
- ❌ Usar `:latest` en versiones de providers o módulos
- ❌ Commitar `.tfvars` con valores sensibles
- ❌ Modificar estado manualmente sin backup previo (`terraform state pull` primero)
- ❌ Aplicar cambios sin revisión de plan (`terraform plan` siempre antes de `apply`)
```

## 14. Ejemplos de Uso — Casos Reales con Respuestas Esperadas

### 14.1 Caso: Crear módulo de base de datos PostgreSQL con pgvector

**Solicitud de Facundo**:  
> "Necesito el módulo de base de datos para PostgreSQL con soporte para pgvector, replicación multi-AZ y cifrado KMS."

**Respuesta en Modo B**:

```hcl
### ✅ Artefacto Generado: 05-CONFIGURATIONS/Terraform/modules/database/main.tf

# Módulo de Base de Datos PostgreSQL con pgvector
# Versión: 1.0.0
# Constraints: C1,C2,C3,C4,C5,C6,C7,C8,V1,V2,V3

#------------------------------------------------------------------------------
# Variables de Entrada
#------------------------------------------------------------------------------
variable "identifier" {
  description = "Unique identifier for the RDS instance"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.identifier))
    error_message = "Identifier must start with a letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "engine_version" {
  description = "PostgreSQL engine version (must support pgvector)"
  type        = string
  default     = "15.4"
  validation {
    condition     = var.engine_version >= "15.0"
    error_message = "pgvector requires PostgreSQL >= 15.0"
  }
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.r6g.large"
}

variable "allocated_storage" {
  description = "Initial allocated storage in GB"
  type        = number
  default     = 100
}

variable "max_allocated_storage" {
  description = "Maximum storage for auto-scaling"
  type        = number
  default     = 500
}

variable "enable_pgvector" {
  description = "Enable pgvector extension for vector search (V1-V3)"
  type        = bool
  default     = true
}

variable "vector_dimension" {
  description = "Dimension for vector embeddings (V1: must be declared explicitly)"
  type        = number
  default     = 1536
  validation {
    condition     = var.vector_dimension > 0 && var.vector_dimension <= 16000
    error_message = "Vector dimension must be between 1 and 16000"
  }
}

variable "vector_index_type" {
  description = "Index type for vector search (V3: must be justified)"
  type        = string
  default     = "hnsw"
  validation {
    condition     = contains(["hnsw", "ivfflat"], var.vector_index_type)
    error_message = "Vector index type must be 'hnsw' or 'ivfflat'"
  }
}

variable "master_username" {
  description = "Master username for the database"
  type        = string
}

variable "master_password" {
  description = "Master password (provide via env var or secret manager)"
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "VPC ID where the database will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for multi-AZ deployment"
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnets required for multi-AZ deployment"
  }
}

variable "security_group_ids" {
  description = "List of security group IDs to attach"
  type        = list(string)
  default     = []
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "Backup retention must be between 1 and 35 days"
  }
}

variable "tags" {
  description = "Additional tags to apply"
  type        = map(string)
  default     = {}
}

#------------------------------------------------------------------------------
# Locales
#------------------------------------------------------------------------------
locals {
  common_tags = merge(var.tags, {
    ManagedBy   = "terraform"
    Database    = "postgresql"
    pgvector    = var.enable_pgvector ? "enabled" : "disabled"
  })
}

#------------------------------------------------------------------------------
# Subnet Group (required for multi-AZ)
#------------------------------------------------------------------------------
resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids
  
  tags = merge(local.common_tags, {
    Name = "${var.identifier}-subnet-group"
  })
}

#------------------------------------------------------------------------------
# Security Group (minimal ingress for DB)
#------------------------------------------------------------------------------
resource "aws_security_group" "this" {
  name        = "${var.identifier}-sg"
  description = "Security group for ${var.identifier}"
  vpc_id      = var.vpc_id
  
  # Allow ingress only from specified security groups
  dynamic "ingress" {
    for_each = var.security_group_ids
    content {
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }
  
  # No egress restrictions (RDS manages outbound)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.identifier}-sg"
  })
}

#------------------------------------------------------------------------------
# RDS Instance with pgvector support
#------------------------------------------------------------------------------
resource "aws_db_instance" "this" {
  identifier = var.identifier
  
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class
  
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true  # C3: encryption at rest
  
  # Multi-AZ for high availability
  multi_az               = true
  availability_zone      = null  # Let AWS choose
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  
  # Credentials
  username = var.master_username
  password = var.master_password  # sensitive = true in variable
  
  # Backup and maintenance
  backup_retention_period = var.backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  skip_final_snapshot    = false
  final_snapshot_identifier = "${var.identifier}-final"
  
  # Performance insights
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  
  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn
  
  # Tags
  tags = local.common_tags
  
  # Lifecycle: prevent accidental deletion
  lifecycle {
    prevent_destroy = false  # Allow controlled destruction
    ignore_changes  = [password]  # Don't trigger replacement on password rotation
  }
  
  # Depend on security group to ensure rules are applied first
  depends_on = [aws_security_group.this]
}

#------------------------------------------------------------------------------
# IAM Role for RDS Enhanced Monitoring
#------------------------------------------------------------------------------
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.identifier}-monitoring-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

#------------------------------------------------------------------------------
# pgvector Extension Setup (via parameter group)
#------------------------------------------------------------------------------
resource "aws_db_parameter_group" "pgvector" {
  count = var.enable_pgvector ? 1 : 0
  
  name   = "${var.identifier}-pgvector"
  family = "postgres${replace(var.engine_version, ".", "")}"
  
  parameter {
    name  = "shared_preload_libraries"
    value = "vector"  # Required for pgvector
  }
  
  tags = local.common_tags
}

#------------------------------------------------------------------------------
# Outputs
#------------------------------------------------------------------------------
output "endpoint" {
  description = "Connection endpoint for the database"
  value       = aws_db_instance.this.endpoint
  sensitive   = true
}

output "db_name" {
  description = "Database name (default: postgres)"
  value       = aws_db_instance.this.db_name
}

output "security_group_id" {
  description = "ID of the security group attached to the database"
  value       = aws_security_group.this.id
}

output "arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.this.arn
}

output "vector_config" {
  description = "Vector search configuration (V1-V3 documentation)"
  value = var.enable_pgvector ? {
    dimension     = var.vector_dimension  # V1: explicit declaration
    index_type    = var.vector_index_type  # V3: hnsw/ivfflat
    distance_metric = "cosine"  # V2: <=> operator for cosine distance
    # Usage example:
    # SELECT * FROM embeddings ORDER BY vector_column <=> '[1,2,3]' LIMIT 10;
    # CREATE INDEX ON embeddings USING hnsw (vector_column vector_cosine_ops) WITH (m=16, ef_construction=64);
  } : null
}
```

**Validación**:  
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain terraform --file 05-CONFIGURATIONS/Terraform/modules/database/main.tf --strict
```

**Checksum**:  
```bash
sha256sum 05-CONFIGURATIONS/Terraform/modules/database/main.tf | awk '{print $1}'
# PENDING_GENERATION → actualizar post-commit
```

**Próximos pasos**:  
- [ ] Crear `variables.tf` y `outputs.tf` para el módulo siguiendo la plantilla estándar
- [ ] Agregar ejemplos de uso en `examples/complete/`
- [ ] Escribir pruebas con Terratest en `tests/module_test.go`
- [ ] Documentar el módulo en `README.md` con `terraform-docs`
- [ ] Versionar el módulo con tag Git (`git tag modules/database/v1.0.0`)

---

*Agente terraform-master-agent v2.0.0-COMPREHENSIVE listo para operar en el ecosistema MANTIS.*  
*Auto-contenido: todas las habilidades, patrones y conocimientos necesarios están definidos en este documento.*  
*Gobernanza: immutable=true, requires_human_approval_for_changes=true, checksum_sha256 para trazabilidad.*  
*Optimizado para ingestión de IA: estructura YAML/JSON-parseable, tablas de decisión, reglas declarativas, anti-patrones explícitos.*
```

---
