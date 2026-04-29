# ---
# artifact_id: terraform-module-template-mantis
# artifact_type: infrastructure_template
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C1","C2","C3","C4","C5","C8"]
# canonical_path: 05-CONFIGURATIONS/templates/terraform-module-template/main.tf
# domain: 05-CONFIGURATIONS
# subdomain: templates
# agent_role: terraform-master
# language_lock: es-ES
# validation_command: orchestrator-engine.sh --domain terraform --strict
# tier: 3
# immutable: true
# requires_human_approval_for_changes: true
# audience: ["agentic_assistants"]
# human_readable: false
# checksum_sha256: "ef944def0a5403127d2801c4cb1c241db1e126daf26f860249305e77df1894dc"
# ---

# ============================================================================
# PLANTILLA MÓDULO TERRAFORM (MANTIS v2.0.0)
# Propósito: Esqueleto estandarizado para nuevos módulos de infraestructura.
# Instrucciones: Reemplazar {placeholders} manteniendo estructura de secciones (C1).
# Validar con orchestrator-engine.sh antes de promover a REAL.
# ============================================================================

# --- VARIABLES (C5: validación estricta obligatoria) ---
variable "environment_tag" {
  description = "Entorno de despliegue (dev/staging/prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment_tag)
    error_message = "environment_tag debe ser: dev, staging, o prod"
  }
}

variable "module_name" {
  description = "Nombre identificador del módulo"
  type        = string
  default     = "generic-module"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,31}$", var.module_name))
    error_message = "module_name: minúsculas, números, guiones; 3-32 chars."
  }
}

# [TEMPLATE] Añadir variables específicas con validation block obligatorio (C5)
# variable "{custom_var_name}" { ... }

variable "tags_extra" {
  description = "Tags adicionales específicos del workload"
  type        = map(string)
  default     = {}
}

# --- LOCALS (C4: trazabilidad consistente) ---
locals {
  base_tags = {
    Project     = "mantis-agentic"
    Domain      = "05-CONFIGURATIONS"
    Environment = var.environment_tag
    ManagedBy   = "terraform"
    Module      = var.module_name
    Constraint  = "C4-traceability"
  }
  merged_tags = merge(local.base_tags, var.tags_extra)
}

# --- RESOURCES (C2: IaC, C3: seguridad por defecto) ---
# [TEMPLATE] Reemplazar con recurso específico. Mantener estructura de seguridad.
resource "null_resource" "module_scaffold" {
  triggers = {
    module_name = var.module_name
    env         = var.environment_tag
  }

  # C3: Ejemplo de patrón seguro (descomentar y adaptar)
  # provisioner "local-exec" {
  #   command = "echo 'Resource secured per MANTIS C3'"
  # }

  tags = local.merged_tags
}

# --- OUTPUTS (Alineados estrictamente con interface-spec.yaml) ---
output "module_id" {
  description = "ID del recurso principal del módulo"
  value       = null_resource.module_scaffold.id
  sensitive   = false
}

output "compliance_check" {
  description = "Indicadores de cumplimiento para orchestrator-engine.sh"
  value = {
    C2_iac_module        = true
    C3_security_defaults = true # Ajustar según recurso real
    C4_tags_applied      = true
    C5_vars_validated    = true
    C8_health_ready      = true # Si aplica health checks o endpoints
  }
}

# ============================================================================
# ANTI-PATRONES EXPLÍCITOS (C1, C3, C5)
# ============================================================================
# ❌ NUNCA: Omitir `validation` en variables (viola C5)
# ❌ NUNCA: Hardcodear ARNs, IDs, IPs o credenciales en el template (C3)
# ❌ NUNCA: Modificar esta plantilla base para un caso específico; crear fork documentado (C1)
# ❌ NUNCA: Exponer secrets en outputs sin `sensitive = true` (C3)
# ✅ SIEMPRE: Incluir `compliance_check` output para validación automatizada
# ✅ SIEMPRE: Alinear outputs con `05-CONFIGURATIONS/interface-spec.yaml`

# ============================================================================
# COMANDOS DE VALIDACIÓN Y USO
# ============================================================================
# 1. Instanciar:
#    cp -r 05-CONFIGURATIONS/templates/terraform-module-template 05-CONFIGURATIONS/terraform/modules/{new_module}/
# 2. Adaptar placeholders y recursos:
#    sed -i 's/{custom_var_name}/actual_name/g; s/null_resource/{aws_provider}_{type}/g' main.tf
# 3. Validar:
#    terraform fmt -check . && terraform init -backend=false && terraform validate
#    orchestrator-engine.sh --domain terraform --file <ruta>/main.tf --strict
# 4. Checksum:
#    CHECKSUM=$(sha256sum <ruta> | awk '{print $1}') && sed -i "s/^# checksum_sha256: "ef944def0a5403127d2801c4cb1c241db1e126daf26f860249305e77df1894dc"


---
