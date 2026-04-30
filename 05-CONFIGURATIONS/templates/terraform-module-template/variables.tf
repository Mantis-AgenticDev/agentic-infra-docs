---
artifact_id: "terraform-module-variables-template-v1.0.0"
artifact_type: "hcl_template"
version: "1.0.0-COMPREHENSIVE"
constraints_mapped: ["C1","C3","C5"]
canonical_path: "05-CONFIGURATIONS/templates/terraform-module-template/variables.tf"
domain: "05-CONFIGURATIONS"
subdomain: "templates"
agent_role: "terraform-variables-generator"
language_lock: "hcl"
validation_command: "terraform fmt -check 05-CONFIGURATIONS/templates/terraform-module-template/variables.tf"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants", "infra_team"]
human_readable: false
checksum_sha256: "439a19dfe1f19601b789abd2a61f0fd8373e75b17129b722480c59f83be400ee"
---


variable "environment" {
  description = "Entorno de despliegue (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Debe ser dev, staging o prod."
  }
}

variable "tenant_id" {
  description = "Identificador único de tenant para aislamiento lógico"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{3,32}$", var.tenant_id))
    error_message = "Formato inválido: [a-z0-9-]{3,32}"
  }
}

variable "instance_type" {
  description = "Tipo de instancia para computo"
  type        = string
  default     = "t3.micro"
  validation {
    condition     = can(regex("^t[234]\\.micro$|^m[56]\\.large$", var.instance_type))
    error_message = "Tipo de instancia no permitido para este perfil."
  }
}

variable "enable_monitoring" {
  description = "Habilitar métricas detalladas y alertas"
  type        = bool
  default     = false
}

variable "master_password" {
  description = "Contraseña maestra (inyectar desde Vault/SSM)"
  type        = string
  sensitive   = true
  nullable    = false
  validation {
    condition     = length(var.master_password) >= 16
    error_message = "Longitud mínima: 16 caracteres."
  }
}

variable "tags" {
  description = "Etiquetas adicionales para recursos"
  type        = map(string)
  default     = {}
  validation {
    condition = alltrue([
      for k, v in var.tags :
      can(regex("^[a-zA-Z][a-zA-Z0-9:/_-]*$", k))
    ])
    error_message = "Claves de tag inválidas."
  }
}

