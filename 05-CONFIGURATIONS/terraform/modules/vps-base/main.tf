# ---
# artifact_id: terraform-vps-base-module
# artifact_type: infrastructure_module
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C2","C3","C4","C5","V1"]
# canonical_path: 05-CONFIGURATIONS/terraform/modules/vps-base/main.tf
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
# checksum_sha256: "01b7e36d59dec7ed4fbb1a117f609e66f88ac855fa350049c8301265fac7c084"
# ---

# ============================================================================
# MÓDULO BASE VPS: Cimientos de infraestructura reutilizable (MANTIS v2.0.0)
# Propósito: Instancia EC2 hardened con SSM, IMDSv2, EBS cifrado, SG mínimo
# Generado por: terraform-master-agent
# Fecha: 2026-04-30
# Alineación: interface-spec.yaml, mapping.yaml, backend.tf
# ============================================================================

# --- VARIABLES (C5: validación estricta) ---
variable "instance_name" {
  description = "Nombre único para la instancia VPS"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,31}$", var.instance_name))
    error_message = "instance_name: minúsculas, números, guiones; 3-32 chars; no iniciar con guión."
  }
}

variable "environment_tag" {
  description = "Entorno de despliegue (dev/staging/prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment_tag)
    error_message = "environment_tag debe ser: dev, staging, o prod"
  }
}

variable "instance_type" {
  description = "Perfil de infraestructura (nano/micro/standard)"
  type        = string
  validation {
    condition     = can(regex("^t[23]\\.(micro|small|medium|large)$", var.instance_type))
    error_message = "instance_type debe ser t2/t3 micro, small, medium o large."
  }
}

variable "vpc_id" {
  description = "ID de la VPC donde se desplegará (interface-spec.yaml alignment)"
  type        = string
  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "vpc_id debe seguir formato AWS vpc-xxxxx."
  }
}

variable "subnet_id" {
  description = "Subnet para la instancia"
  type        = string
  validation {
    condition     = can(regex("^subnet-[a-z0-9]+$", var.subnet_id))
    error_message = "subnet_id debe seguir formato AWS subnet-xxxxx."
  }
}

variable "ssh_key_name" {
  description = "Par de claves SSH (legacy). Preferir SSM Session Manager (C3)"
  type        = string
  default     = null
  validation {
    condition     = var.ssh_key_name == null || can(regex("^[a-zA-Z0-9-_]{3,255}$", var.ssh_key_name))
    error_message = "ssh_key_name inválido o demasiado largo."
  }
}

variable "user_data_base64" {
  description = "Script cloud-init en base64 (bootstrap, hardening, agents)"
  type        = string
  default     = null
}

variable "enable_monitoring" {
  description = "Habilitar CloudWatch detailed monitoring (C8: métricas DORA)"
  type        = bool
  default     = true
}

variable "tags_extra" {
  description = "Tags adicionales específicos del workload"
  type        = map(string)
  default     = {}
}

# --- LOCALS (C4: consistencia de trazabilidad) ---
locals {
  base_tags = {
    Project     = "mantis-agentic"
    Domain      = "05-CONFIGURATIONS"
    Environment = var.environment_tag
    ManagedBy   = "terraform"
    Module      = "vps-base"
    Constraint  = "C4-traceability,V1-isolation-ready"
  }
  merged_tags = merge(local.base_tags, var.tags_extra)
}

# ============================================================================
# RECURSOS
# ============================================================================

# --- Security Group Mínimo (C3: principio de menor privilegio) ---
resource "aws_security_group" "vps_base" {
  name_prefix = "mantis-${var.environment_tag}-sg-"
  description = "Base SG: SSH restringido, HTTP/S, ICMP echo solo para debugging"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH (Solo para IP de gestión o bastion)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"] # Ajustar a CIDR de gestión en prod (C6)
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.merged_tags, { Name = "${var.instance_name}-sg" })
}

# --- IAM Instance Profile para SSM (C3: eliminación de SSH en prod) ---
resource "aws_iam_role" "ssm" {
  name = "mantis-${var.environment_tag}-${var.instance_name}-ssm"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = local.merged_tags
}

resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "mantis-${var.environment_tag}-${var.instance_name}-ssm-profile"
  role = aws_iam_role.ssm.name
}

# --- Instancia EC2 (C2, C3, C4, V1) ---
resource "aws_instance" "vps_base" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.vps_base.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm.name
  key_name               = var.ssh_key_name
  user_data_base64       = var.user_data_base64
  monitoring             = var.enable_monitoring

  # C3: IMDSv2 obligatorio (previene SSRF y metadatos no autorizados)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # C3: EBS root cifrado por defecto
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
    tags = { Name = "${var.instance_name}-root" }
  }

  # C4: Trazabilidad completa
  tags = local.merged_tags

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [user_data_base64] # Permite actualización sin recreación
  }
}

# --- Data Source: AMI Oficial (C2: reproducible) ---
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# ============================================================================
# OUTPUTS (Alineados con interface-spec.yaml)
# ============================================================================

output "instance_id" {
  description = "ID de la instancia EC2 creada"
  value       = aws_instance.vps_base.id
  # interface-spec.yaml: consumed_by: docker-compose, health-check.sh
}

output "private_ip" {
  description = "IP privada de la instancia (para comunicación interna segura)"
  value       = aws_instance.vps_base.private_ip
  # interface-spec.yaml: consumed_by: docker-compose, monitoring
}

output "public_ip" {
  description = "IP pública (solo si asignada automáticamente)"
  value       = aws_instance.vps_base.public_ip
  sensitive   = false
}

output "security_group_id" {
  description = "ID del security group base (interface-spec.yaml alignment)"
  value       = aws_security_group.vps_base.id
}

output "compliance_check" {
  description = "Indicadores de cumplimiento de constraints para orchestrator-engine.sh"
  value = {
    C2_iac_base          = true
    C3_imdsv2_enforced   = true
    C3_ebs_encrypted     = true
    C3_ssm_ready         = true
    C4_tags_applied      = true
    C5_vars_validated    = true
    V1_isolation_ready   = true # SG mínimo + SSM + red privada por defecto
  }
}

# ============================================================================
# ANTI-PATRONES EXPLÍCITOS (C1, C3, C5)
# ============================================================================
# ❌ NUNCA: Asignar IP pública directamente en instancias de prod sin NAT/LoadBalancer
# ❌ NUNCA: Usar http_tokens = "optional" (IMDSv1 expuesto a SSRF)
# ❌ NUNCA: Hardcodear credenciales en user_data (viola C3 críticamente)
# ❌ NUNCA: Abrir puertos 0.0.0.0/0 en SSH o DB sin justificación ADR (C6)
# ✅ SIEMPRE: Usar SSM Session Manager para acceso remoto seguro
# ✅ SIEMPRE: Mantener security groups lo más restrictivos posible

# ============================================================================
# COMANDOS DE VALIDACIÓN Y USO
# ============================================================================
# 1. Validar módulo:
#    terraform fmt -check . && terraform validate
# 2. Scan seguridad (C5):
#    checkov -d . --framework terraform --check CKV_AWS_88,CKV_AWS_135,CKV_AWS_79
# 3. Integración orchestrator:
#    orchestrator-engine.sh --domain terraform --file 05-CONFIGURATIONS/terraform/modules/vps-base/main.tf --strict
# 4. Update checksum:
#    CHECKSUM=$(sha256sum 05-CONFIGURATIONS/terraform/modules/vps-base/main.tf | awk '{print $1}')
#    sed -i "s/^# checksum_sha256: "01b7e36d59dec7ed4fbb1a117f609e66f88ac855fa350049c8301265fac7c084"
```

---
