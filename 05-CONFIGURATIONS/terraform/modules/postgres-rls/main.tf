# C4: Row-Level Security & Aislamiento Multi-Tenant
terraform {
  required_providers {
    postgresql = { source = "cyrilgdn/postgresql", version = "~> 1.20" }
  }
}

variable "db_host" { type = string }
variable "db_name" { type = string }
variable "tenant_tables" { type = list(string) }

resource "postgresql_role" "app_role" {
  name     = "app_tenant_isolated"
  login    = true
  password = var.db_host # C3: Inyectar desde vault/env en producción
  superuser = false
}

resource "postgresql_extension" "rls_enabler" {
  name     = "pgcrypto"
  database = var.db_name
  count    = length(var.tenant_tables) > 0 ? 1 : 0
}

resource "null_resource" "rls_policies" {
  for_each = toset(var.tenant_tables)
  provisioner "local-exec" {
    command = <<EOF
      psql "host=${var.db_host} dbname=${var.db_name} user=${postgresql_role.app_role.name}" <<SQL
      ALTER TABLE ${each.value} ENABLE ROW LEVEL SECURITY;
      CREATE POLICY tenant_isolation ON ${each.value}
      USING (tenant_id = current_setting('app.current_tenant_id')::uuid);
      GRANT ALL ON ${each.value} TO ${postgresql_role.app_role.name};
SQL
    EOF
  }
  depends_on = [postgresql_role.app_role]
}
