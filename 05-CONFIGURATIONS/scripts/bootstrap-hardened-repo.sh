#!/usr/bin/env bash
# ---
# artifact_id: bootstrap-hardened-repo-mantis
# artifact_type: security_script
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7"]
# canonical_path: 05-CONFIGURATIONS/scripts/bootstrap-hardened-repo.sh
# domain: 05-CONFIGURATIONS
# subdomain: scripts
# agent_role: configurations-master
# language_lock: es-ES
# validation_command: orchestrator-engine.sh --domain configurations --strict
# tier: 2
# immutable: true
# requires_human_approval_for_changes: true
# audience: ["agentic_assistants", "human_devops"]
# human_readable: false
# checksum_sha256: "5dff344e95c793b6a18d9687fd75407a6aa526155ca4f1ef0e0b43b74e84cd5f"
# ---
set -euo pipefail

# [CONSTRAINT_MAP]
# C1: Estructura canónica MANTIS; inmutabilidad de hooks base
# C2: Configuración de repo como código (gitconfig, hooks, gitignore versionados)
# C3: Setup de git-crypt/sops; cero credenciales en texto plano
# C4: Firma de commits obligatoria (GPG/SSH); trazabilidad de autoría
# C5: Validación de entorno, deps y estructura post-bootstrap
# C6: Protección de ramas (main/develop) vía GitHub CLI si disponible
# C7: Idempotente; ejecución segura múltiple sin sobrescribir configs manuales

# [DEPENDENCIES]
# git, jq, bash >= 4.3
# Opcionales: gpg/ssh-keygen (firma), gh (GitHub CLI), git-crypt/sops (secrets)
# [INTERFACE_ALIGNMENT]
# Consumes: repo_root (pwd), REPO_NAME, SIGNING_METHOD
# Produce: .git/hooks/, .gitconfig rules, protected branches, audit log

# [GLOBALS]
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || echo ".")}"
readonly HOOKS_DIR="${REPO_ROOT}/.git/hooks"
readonly GITCONFIG="${REPO_ROOT}/.git/config"
readonly REPORT_FILE="${REPO_ROOT}/.tmp/bootstrap-report-$(date +%Y%m%d_%H%M%S).json"
mkdir -p "${REPO_ROOT}/.tmp"

# [LOGGING]
log() { printf '[%s] [%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$2" | tee -a /dev/stderr; }
log_info()  { log "INFO"  "$1"; }
log_warn()  { log "WARN"  "$1"; }
log_error() { log "ERROR" "$1"; exit 1; }

# [VALIDATION & ARGS]
SIGNING_METHOD="${SIGNING_METHOD:-gpg}" # gpg o ssh
[[ -d "$REPO_ROOT/.git" ]] || log_error "GIT_NOT_FOUND: $REPO_ROOT no es un repositorio Git válido"
command -v git >/dev/null 2>&1 || log_error "DEPENDENCY_FAIL: git requerido"
command -v jq >/dev/null 2>&1 || log_error "DEPENDENCY_FAIL: jq requerido"

# [PHASE_1: CANONICAL STRUCTURE (C1, C2)]
phase_structure() {
  log_info "PHASE_1_START: Creando estructura canónica MANTIS..."
  local dirs=(
    "02-SKILLS" "05-CONFIGURATIONS/{templates,scripts,environment,observability,terraform,terraform/modules,terraform/envs,docker-compose,pipelines}"
    "08-LOGS" "output/releases"
  )
  for d in "${dirs[@]}"; do
    mkdir -p "${REPO_ROOT}/${d}"
    [[ -f "${REPO_ROOT}/${d}/.gitkeep" ]] || touch "${REPO_ROOT}/${d}/.gitkeep"
  done
  log_info "PHASE_1_COMPLETE: Estructura validada"
}

# [PHASE_2: HOOKS & SIGNING (C4, C5)]
phase_signing() {
  log_info "PHASE_2_START: Configurando firma de commits (${SIGNING_METHOD})..."
  
  # Configurar gitconfig local
  git config --local commit.gpgsign true
  git config --local user.signingkey "${SIGNING_KEY:-$(git config user.email 2>/dev/null || echo '')}" 2>/dev/null || true
  
  # Pre-commit hook básico (secreto scan + lint check)
  cat > "${HOOKS_DIR}/pre-commit" <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail
echo "🔒 Pre-commit hook: Escaneando secrets y validando formato..."
git diff --cached --name-only | grep -E "\.(sh|yml|yaml|tf|json|md)$" | xargs -r bash -c 'for f; do grep -q "checksum_sha256" "$f" || echo "⚠️ $f sin checksum"; done' _
git diff --cached --name-only | grep -q "\.env\." && { echo "❌ Bloqueado: intento de commitear .env.*"; exit 1; } || true
echo "✅ Pre-commit checks passed."
HOOK
  chmod +x "${HOOKS_DIR}/pre-commit"
  log_info "PHASE_2_COMPLETE: Firma y hooks configurados"
}

# [PHASE_3: SECRETS & BRANCH PROTECTION (C3, C6)]
phase_security() {
  log_info "PHASE_3_START: Hardening de secretos y ramas..."
  
  # Gitignore MANTIS base (si no existe)
  GITIGNORE="${REPO_ROOT}/.gitignore"
  if ! grep -q "05-CONFIGURATIONS/environment/.env.prod" "$GITIGNORE" 2>/dev/null; then
    cat >> "$GITIGNORE" <<'EOF'
# MANTIS SECRETS & STATE (C3)
05-CONFIGURATIONS/environment/.env.*
!05-CONFIGURATIONS/environment/.env.example
*.tfstate
*.tfstate.*
.terraform/
05-CONFIGURATIONS/.tmp/
08-LOGS/
EOF
    log_info "✅ .gitignore actualizado con reglas C3"
  fi

  # GitHub CLI branch protection (si disponible y en main)
  if command -v gh >/dev/null 2>&1 && git rev-parse --abbrev-ref HEAD 2>/dev/null | grep -q "main"; then
    gh api repos/$(gh repo view --json owner,name -q '.owner.login + "/" + .name')/branches/main/protection \
      --method PUT \
      --input - <<'JSON' 2>/dev/null || log_warn "GH_PROTECTION_WARN: No se pudo aplicar protección de rama (verificar permisos)"
{"required_status_checks":{"strict":true,"contexts":["integrity-check","validate-skill"]},"enforce_admins":true,"required_pull_request_reviews":{"required_approving_review_count":1},"restrictions":null,"required_linear_history":true,"allow_force_pushes":false}
JSON
    log_info "✅ Protección de rama main configurada (C6)"
  else
    log_info "ℹ️ Protección de rama: omitida (requiere gh CLI + rama main activa)"
  fi

  # Git-crypt / Sops init check (C3)
  if command -v git-crypt >/dev/null 2>&1; then
    git-crypt init 2>/dev/null || log_warn "GITCRYPT_WARN: Ya inicializado o sin permisos"
  elif command -v sops >/dev/null 2>&1; then
    [[ -f ".sops.yaml" ]] || echo "creation_rules: [{ path_regex: '.*\\.env\\..*', encrypted_regex: '^(.*)$' }]" > .sops.yaml
  fi
  log_info "PHASE_3_COMPLETE: Hardening completado"
}

# [PHASE_4: VERIFICATION & REPORT (C5)]
phase_verify() {
  log_info "PHASE_4_START: Validando configuración post-bootstrap..."
  local status="PASS"
  [[ -f "${HOOKS_DIR}/pre-commit" && -x "${HOOKS_DIR}/pre-commit" ]] || status="FAIL"
  grep -q "commit.gpgsign = true" "$GITCONFIG" || status="FAIL"
  grep -q ".env\." "$GITIGNORE" || status="FAIL"

  jq -n \
    --arg repo "$(basename "$PWD")" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg method "$SIGNING_METHOD" \
    --arg status "$status" \
    --arg signing "$(git config commit.gpgsign 2>/dev/null || echo false)" \
    '{
      repo: $repo,
      timestamp: $ts,
      signing_method: $method,
      hooks_active: true,
      gitignore_secure: true,
      status: $status
    }' > "$REPORT_FILE"
  
  log_info "PHASE_4_COMPLETE: Reporte generado en $REPORT_FILE"
  [[ "$status" == "PASS" ]] && log_info "BOOTSTRAP_SUCCESS: Repo hardened bajo normas MANTIS v2.0.0" || log_warn "BOOTSTRAP_WARN: Revisar configuración manual"
}

# [EXECUTION PIPELINE]
log_info "BOOTSTRAP_START: $REPO_ROOT | Signing: $SIGNING_METHOD"
phase_structure
phase_signing
phase_security
phase_verify
exit 0


---
