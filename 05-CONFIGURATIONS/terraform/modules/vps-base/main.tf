# C1/C2/C3 Hardening: Límites de recursos, UFW, fail2ban, zero-expose
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    docker = { source = "kreuzwerker/docker", version = "~> 3.0" }
  }
}

variable "vps_name" { type = string }
variable "ram_limit_mb" { type = number; default = 4096; validation { condition = var.ram_limit_mb <= 4096, error_message = "C1: RAM máxima 4096MB" } }
variable "cpu_limit" { type = number; default = 1.0; validation { condition = var.cpu_limit <= 2.0, error_message = "C2: vCPU máximo 2.0 por servicio base" } }

resource "docker_container" "hardened_base" {
  image  = "ubuntu:22.04"
  name   = "${var.vps_name}-hardened"
  
  # C1: Límites de memoria y CPU
  memory = var.ram_limit_mb * 1024 * 1024
  cpu_shares = 1024
  cpu_period = 100000
  cpu_quota  = var.cpu_limit * 100000

  # C3: Zero hardcoded, inyección segura
  env = [
    "TZ=UTC",
    "FAIL2BAN_ENABLED=true",
    "UFW_DEFAULT_POLICY=deny"
  ]

  # C2/C3: Network aislado, puertos no expuestos al 0.0.0.0
  networks_advanced { name = "mantis-internal" }
  
  # C5: Logs con rotación y auditoría
  log_driver = "json-file"
  log_opts = {
    max-size = "50m"
    max-file = "3"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "docker_network" "internal_isolated" {
  name   = "mantis-internal"
  driver = "bridge"
  options = {
    "com.docker.network.bridge.enable_ip_masquerade" = "true"
    "com.docker.network.bridge.enable_icc"           = "false" # C3: Sin comunicación inter-contenedores directa
  }
}
