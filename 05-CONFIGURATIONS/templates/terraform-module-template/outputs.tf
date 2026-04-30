---
artifact_id: "terraform-module-outputs-template-v1.0.0"
artifact_type: "hcl_template"
version: "1.0.0-COMPREHENSIVE"
constraints_mapped: ["C1","C3","C4","C5"]
canonical_path: "05-CONFIGURATIONS/templates/terraform-module-template/outputs.tf"
domain: "05-CONFIGURATIONS"
subdomain: "templates"
agent_role: "terraform-outputs-generator"
language_lock: "hcl"
validation_command: "terraform fmt -check 05-CONFIGURATIONS/templates/terraform-module-template/outputs.tf"
tier: 3
immutable: true
requires_human_approval_for_changes: true
audience: ["agentic_assistants", "infra_team"]
human_readable: false
checksum_sha256: "e2180ffcc95c152a17187663756857592910b59fd834971bfe57ff28f539f178"
---
```

```hcl
output "id" {
  description = "ID del recurso principal creado por el módulo"
  value       = aws_resource.example.id
}

output "arn" {
  description = "ARN completo para integración con IAM/SSM"
  value       = aws_resource.example.arn
}

output "endpoint" {
  description = "Endpoint público para acceso al servicio"
  value       = aws_resource.example.endpoint
  precondition {
    condition     = length(aws_resource.example.endpoint) > 0
    error_message = "El endpoint no está disponible. Verificar estado del recurso."
  }
}

output "connection_string" {
  description = "URI completa con credenciales (solo uso interno)"
  value       = "postgresql://${var.master_username}:${var.master_password}@${aws_db_instance.example.endpoint}/${var.db_name}"
  sensitive   = true
}

output "security_group_id" {
  description = "ID del security group asociado al módulo"
  value       = aws_security_group.example.id
}

output "deployment_checksum" {
  description = "SHA256 del estado actual para trazabilidad C4"
  value       = sha256(jsonencode({
    resource_id = aws_resource.example.id
    version     = var.environment
    timestamp   = timestamp()
  }))
}


---
