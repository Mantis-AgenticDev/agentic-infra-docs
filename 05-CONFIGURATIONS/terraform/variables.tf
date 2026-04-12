# Variables globales validadas para C1-C6
variable "environment" {
  type        = string
  validation { condition = contains(["dev", "staging", "prod"], var.environment); error_message = "Entorno no válido" }
}

variable "tenant_id" {
  type        = string
  validation { condition = can(regex("^[a-z0-9-]{8,36}$", var.tenant_id)); error_message = "C4: tenant_id inválido" }
}

variable "max_ram_mb" {
  type        = number
  default     = 3800 # C1: Margen 200MB para SO
  validation { condition = var.max_ram_mb <= 4096; error_message = "C1: Límite RAM excedido" }
}

variable "enable_c6_cloud_routing" {
  type    = bool
  default = true
  description = "C6: Forzar inferencia cloud. Desactivar solo con excepción documentada."
}
