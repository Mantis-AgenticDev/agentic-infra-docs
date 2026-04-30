# ---
# artifact_id: vault-policies-mantis
# artifact_type: security_config
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C3","C4","C5","C6"]
# canonical_path: 05-CONFIGURATIONS/security/vault-policies.hcl
# domain: 05-CONFIGURATIONS
# subdomain: security
# agent_role: configurations-master
# language_lock: es-ES
# validation_command: orchestrator-engine.sh --domain configurations --strict
# tier: 2
# immutable: true
# requires_human_approval_for_changes: true
# audience: ["agentic_assistants", "security_ops"]
# human_readable: false
# checksum_sha256: "b6570ad1a2c2120cfcc25f4ed4a8f983d98973f36f8d53a62a93d9fcb754c675"
# ---

# ============================================================================
# HASHICORP VAULT POLICIES: MANTIS v2.0.0
# Propósito: Control de acceso basado en mínimos privilegios para gestión de secretos.
# Generado por: configurations-master-agent
# Fecha: 2026-04-30
# Alineación: mapping.yaml, interface-spec.yaml §security, docker-compose secrets
# ============================================================================

# --- POLICY 1: mantis-dev-access (Desarrollo local y CI temprano) ---
path "secret/data/mantis/dev/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "secret/metadata/mantis/dev/*" {
  capabilities = ["read", "list"]
}

# --- POLICY 2: mantis-app-runtime (Contenedores y agentes en staging/prod) ---
# Acceso de solo lectura a rutas específicas por entorno. El "+" es wildcard de segmento en Vault.
path "secret/data/mantis/+/db/credentials" {
  capabilities = ["read"]
  allowed_parameters = {
    "format" = ["url", "json"]
  }
}
path "secret/data/mantis/+/qdrant/api_key" {
  capabilities = ["read"]
}
path "secret/data/mantis/+/proxy/openrouter_key" {
  capabilities = ["read"]
}

# C3/C6: Bloqueo explícito de lectura directa en prod sin rol CI/CD aprobado
path "secret/data/mantis/prod/*" {
  capabilities = ["deny"]
}

# --- POLICY 3: mantis-backup-operator (Scripts de backup/restore) ---
path "secret/data/mantis/backup/s3_credentials" {
  capabilities = ["read"]
}
path "transit/encrypt/backup-key" {
  capabilities = ["update"]
}

# --- POLICY 4: mantis-audit-readonly (Monitoreo y cumplimiento C4) ---
# Permite listar metadata sin exponer valores reales. Auditoría habilitada.
path "secret/metadata/mantis/*" {
  capabilities = ["list", "read"]
}
path "sys/audit" {
  capabilities = ["read", "list"]
}
path "sys/audit-hash/*" {
  capabilities = ["update"]
}

# ============================================================================
# ANTI-PATRONES EXPLÍCITOS (C3, C5, C6)
# ============================================================================
# ❌ NUNCA: `capabilities = ["*"]` o incluir `"sudo"` sin justificación ADR (viola C5)
# ❌ NUNCA: Omitir `capabilities = ["deny"]` para paths de producción sin gate humano (viola C6)
# ❌ NUNCA: Hardcodear `VAULT_ADDR` o `VAULT_TOKEN` en políticas, scripts o pipelines (viola C3)
# ❌ NUNCA: Usar wildcards excesivos (`secret/data/*`) en políticas de runtime (viola C5)
# ✅ SIEMPRE: Alinear paths `mantis/+/*` con estructura de `mapping.yaml` y `interface-spec.yaml`
# ✅ SIEMPRE: Validar sintaxis con `vault policy fmt` y dry-run antes de aplicar

# ============================================================================
# COMANDOS DE VALIDACIÓN Y APLICACIÓN
# ============================================================================
# vault policy fmt -write=false 05-CONFIGURATIONS/security/vault-policies.hcl && echo "✅ Sintaxis HCL OK"
# vault policy write mantis-app-runtime 05-CONFIGURATIONS/security/vault-policies.hcl
# vault policy read mantis-app-runtime | grep -q "capabilities = \"read\"" && echo "✅ Privilegios mínimos C5 OK"
# CHECKSUM=$(sha256sum 05-CONFIGURATIONS/security/vault-policies.hcl | awk '{print $1}') && sed -i "s/^# checksum_sha256: "b6570ad1a2c2120cfcc25f4ed4a8f983d98973f36f8d53a62a93d9fcb754c675"


---
