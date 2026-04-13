# ---
# title: "VPS Base Module - Outputs"
# version: "1.0.0"
# constraints_mapped: ["C3", "C4", "C8"]
# validation_command: "terraform validate -no-color -json"
# ---

# =============================================================================
# VPS BASE MODULE - OUTPUTS
# =============================================================================
# Exposes essential connection info and identifiers for downstream modules
# Never outputs secrets directly (C3).

output "vps_id" {
  description = "Unique identifier of the provisioned VPS instance"
  value       = local.provisioned_vps_id
}

output "vps_name" {
  description = "Canonical name of the VPS"
  value       = var.vps_name
}

output "public_ipv4" {
  description = "Primary public IPv4 address"
  value       = local.public_ipv4_address
}

output "public_ipv6" {
  description = "Primary public IPv6 address (if available)"
  value       = try(local.public_ipv6_address, "")
}

output "private_ip" {
  description = "Private network IP for VPS interconnect"
  value       = local.private_network_ip
}

output "ssh_connection_string" {
  description = "Pre-formatted SSH connection command"
  value       = "ssh -i ${var.ssh_private_key_path} root@${local.public_ipv4_address}"
  sensitive   = true
}

output "ansible_inventory_name" {
  description = "Hostname used in Ansible inventory"
  value       = var.vps_name
}

output "tenant_id" {
  description = "Tenant ID associated with this VPS (C4)"
  value       = var.tenant_id
}

output "resource_limits_applied" {
  description = "Actual resource limits enforced (C1, C2)"
  value       = var.resource_limits
}

output "wireguard_public_key" {
  description = "WireGuard public key of this node (if enabled)"
  value       = var.wireguard_enabled ? local.wireguard_public_key : ""
  sensitive   = true
}

output "monitoring_endpoint" {
  description = "URL for node health checks (health-monitoring-vps)"
  value       = "http://${local.public_ipv4_address}:9100/metrics"
}

output "tags" {
  description = "Aggregated tags applied to the VPS"
  value = merge(
    var.tags,
    {
      "mantis/tenant_id" = var.tenant_id
      "mantis/vps_role"  = var.vps_name
      "mantis/environment" = var.environment
    }
  )
}

output "structured_log_context" {
  description = "Metadata required for structured JSON logging (C8)"
  value = {
    tenant_id   = var.tenant_id
    vps_name    = var.vps_name
    environment = var.environment
    trace_id_prefix = "vps-${substr(var.vps_name, 0, 4)}"
  }
}

# -----------------------------------------------------------------------------
# LOCALS (internal only, not exposed)
# -----------------------------------------------------------------------------
locals {
  provisioned_vps_id    = "vps-${random_id.instance.hex}"
  public_ipv4_address   = hcloud_server.primary.ipv4_address
  public_ipv6_address   = try(hcloud_server.primary.ipv6_address, "")
  private_network_ip    = var.wireguard_enabled ? cidrhost("10.0.0.0/16", index(keys(local.vps_mapping), var.vps_name) + 10) : ""
  wireguard_public_key  = var.wireguard_enabled ? tls_private_key.wireguard[0].public_key_openssh : ""
  vps_mapping           = { for i, v in var.all_vps_names : v => i }
}

# (Placeholder resources for local evaluation; actual provisioning uses 
#  provider resources that will be resolved during apply)
resource "random_id" "instance" {
  byte_length = 8
}

resource "hcloud_server" "primary" {
  name        = var.vps_name
  server_type = var.server_type
  image       = var.image
  location    = var.provider_region
  ssh_keys    = [hcloud_ssh_key.default.id]
  labels      = merge(var.tags, { tenant_id = var.tenant_id })

  lifecycle {
    ignore_changes = [ssh_keys]
  }
}

resource "hcloud_ssh_key" "default" {
  name       = "mantis-${var.vps_name}-key"
  public_key = file(var.ssh_public_key_path)
}

resource "tls_private_key" "wireguard" {
  count     = var.wireguard_enabled ? 1 : 0
  algorithm = "ED25519"
}

# 🟢 VALIDATION: terraform fmt -check -diff -recursive . && terraform validate -no-color -json
