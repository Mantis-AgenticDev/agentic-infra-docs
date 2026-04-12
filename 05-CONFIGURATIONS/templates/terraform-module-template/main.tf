#---
# metadata_version: 1.0
# sdd_compliant: true
# purpose: "Plantilla mínima para módulos Terraform hardenizados C1-C6"
# constraint: "C1:RAM≤4GB | C2:CPU≤1.0 | C3:No-Hardcode | C4:tenant-aware | C5:Encrypted | C6:Cloud-Only"
# ---
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    # Definir proveedores usados
  }
}

variable "module_name" { type = string }
variable "tenant_id"   { type = string }

# C1/C2: Límites explícitos en recursos
# C3: Usar variables de entorno/vault, nunca strings planos
# C4: Filtrar por tenant_id en políticas/etiquetas
# C5: Habilitar logging/audit en todos los recursos
# C6: Routing cloud-first

resource "null_resource" "hardening_check" {
  triggers = {
    always_run = timestamp()
    # Validación pre-apply simulada
  }
}
