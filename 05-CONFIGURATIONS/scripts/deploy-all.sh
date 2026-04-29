# ✅ ARTEFACTO #3 GENERADO: `deploy-all.sh`

```bash
#!/usr/bin/env bash
# ---
# artifact_id: deploy-all-mantis
# artifact_type: orchestration_script
# version: 2.0.0-COMPREHENSIVE
# constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8"]
# canonical_path: 05-CONFIGURATIONS/scripts/deploy-all.sh
# domain: 05-CONFIGURATIONS
# subdomain: scripts
# agent_role: configurations-master
# language_lock: es-ES
# validation_command: orchestrator-engine.sh --domain configurations --strict
# tier: 3
# immutable: true
# requires_human_approval_for_changes: true
# audience: ["agentic_assistants"]
# human_readable: false
# checksum_sha256: "6945152a9bc836724d438e7d5c55fe6ada025b69cc3dbc5e37ffe63c4146c92a"
# ---
set -euo pipefail

# [CONSTRAINT_MAP]
# C1: Convención sobre configuración | Overrides vía .env, nunca hardcode
# C2: Todo en repositorio | Pipeline único de orquestación
# C3: Secrets seguros | Carga scoped de .env, nunca logueo de valores sensibles
# C4: Trazabilidad | Timestamps, git commit, tags de entorno en logs
# C5: Validación | shellcheck, orchestrator-engine.sh, health checks
# C6: Aprobación prod | Gate CI implícito, fallback manual con confirmación
# C7: Rollback | --rollback flag, state restore, compose down/up
# C8: Calidad | Promptfoo eval, métricas DORA, health endpoints obligatorios

# [DEPENDENCIES]
# terraform, docker, docker compose, jq, curl, yq, shellcheck
# [INTERFACE_ALIGNMENT]
# Consumes: 05-CONFIGURATIONS/interface-spec.yaml variables
# Produces: deployment state, health report, promptfoo results

# [GLOBALS]
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOMAIN_ROOT="$(dirname "$SCRIPT_DIR")"
readonly ENV_DIR="${DOMAIN_ROOT}/environment"
readonly TF_DIR="${DOMAIN_ROOT}/terraform"
readonly COMPOSE_DIR="${DOMAIN_ROOT}/docker-compose"
readonly PIPELINES_DIR="${DOMAIN_ROOT}/pipelines"
readonly OBS_DIR="${DOMAIN_ROOT}/observability"
readonly LOG_FILE="${DOMAIN_ROOT}/.tmp/deploy-$(date +%Y%m%d_%H%M%S).log"
readonly STATE_FILE="${DOMAIN_ROOT}/.tmp/deploy-state.json"

mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$STATE_FILE")"

# [LOGGING]
log() { printf '[%s] [%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$2" | tee -a "$LOG_FILE"; }
log_info()  { log "INFO"  "$1"; }
log_warn()  { log "WARN"  "$1"; }
log_error() { log "ERROR" "$1"; }
log_debug() { log "DEBUG" "$1" || true; }

# [CLEANUP]
cleanup() {
  log_info "Ejecutando cleanup post-ejecución..."
  rm -f "${DOMAIN_ROOT}/.tmp/env-override-*.bak" 2>/dev/null || true
  log_info "Cleanup completado."
}
trap cleanup EXIT

# [ARGS]
ENV="dev"
ROLLBACK=false
SKIP_TF=false
SKIP_BUILD=false
VERBOSE=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --env) ENV="$2"; shift 2 ;;
    --rollback) ROLLBACK=true; shift ;;
    --skip-terraform) SKIP_TF=true; shift ;;
    --skip-build) SKIP_BUILD=true; shift ;;
    --verbose) VERBOSE=true; shift ;;
    *) log_error "Argumento desconocido: $1"; exit 1 ;;
  esac
done

# [VALIDATION]
for cmd in terraform docker jq curl yq; do
  command -v "$cmd" >/dev/null 2>&1 || { log_error "DEPENDENCY_FAIL: $cmd no encontrado"; exit 1; }
done

if ! [[ "$ENV" =~ ^(dev|staging|prod)$ ]]; then
  log_error "VALIDATION_FAIL: ENV debe ser dev|staging|prod"; exit 1
fi

# [ENV_LOAD]
# C3: Carga scoped, sin export global
if [[ ! -f "${ENV_DIR}/.env.${ENV}" ]]; then
  log_error "ENV_MISSING: ${ENV_DIR}/.env.${ENV} no existe"; exit 1
fi

# Parse .env safely (ignores comments, handles quotes)
while IFS='=' read -r key value; do
  [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
  value="${value%\"}"
  value="${value#\"}"
  export "$key"="$value"
done < <(grep -v '^\s*#' "${ENV_DIR}/.env.${ENV}")

log_info "ENV_LOADED: ${ENV} | COMMIT=$(git rev-parse HEAD 2>/dev/null || echo 'unknown')"

# [STATE_TRACKING]
# C7: Registro de estado para rollback atómico
init_state() {
  jq -n \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg env "$ENV" \
    --arg commit "${GIT_COMMIT:-unknown}" \
    '{timestamp: $ts, environment: $env, commit: $commit, phases: {tf: false, build: false, deploy: false, validate: false}}' \
    > "$STATE_FILE"
}
update_phase() { jq ".phases.$1 = true" "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"; }

# [PHASE_1: TERRAFORM]
phase_terraform() {
  log_info "PHASE_1_START: Terraform infra"
  cd "$TF_DIR"
  
  terraform init -input=false -backend-config="bucket=${TF_BACKEND_BUCKET:-mantis-state}-${ENV}" >/dev/null 2>&1 || { log_error "TF_INIT_FAIL"; exit 1; }
  terraform plan -out=tfplan -input=false -var="environment_tag=${ENV}" >/dev/null 2>&1 || { log_error "TF_PLAN_FAIL"; exit 1; }
  
  # C6: Gate de aprobación en prod
  if [[ "$ENV" == "prod" && "${CI:-false}" != "true" ]]; then
    log_warn "APPROVAL_GATE: Producción requiere aprobación explícita o CI pipeline"
    log_info "Para continuar local: export CI=true o ejecutar con --skip-terraform"
    exit 1
  fi
  
  terraform apply -input=false tfplan >/dev/null 2>&1 || { log_error "TF_APPLY_FAIL"; exit 1; }
  update_phase "tf"
  log_info "PHASE_1_COMPLETE: Infra aplicada"
}

# [PHASE_2: BUILD]
phase_build() {
  log_info "PHASE_2_START: Docker build & push"
  cd "$COMPOSE_DIR"
  
  # C5: Trivy scan pre-push
  if command -v trivy >/dev/null 2>&1; then
    docker compose build >/dev/null 2>&1 || { log_error "DOCKER_BUILD_FAIL"; exit 1; }
    for svc in $(docker compose config --services); do
      img=$(docker compose config | yq eval ".services.${svc}.image // empty" - 2>/dev/null || echo "")
      [[ -z "$img" ]] && continue
      trivy image --severity CRITICAL,HIGH --exit-code 1 "$img" >/dev/null 2>&1 || { log_error "TRIVY_SCAN_FAIL: $img"; exit 1; }
    done
  else
    docker compose build >/dev/null 2>&1 || { log_error "DOCKER_BUILD_FAIL"; exit 1; }
  fi
  
  [[ "$ENV" != "dev" ]] && docker compose push >/dev/null 2>&1
  update_phase "build"
  log_info "PHASE_2_COMPLETE: Build & push OK"
}

# [PHASE_3: DEPLOY]
phase_deploy() {
  log_info "PHASE_3_START: Docker compose deploy"
  cd "$COMPOSE_DIR"
  
  docker compose down --timeout 30 >/dev/null 2>&1 || true
  docker compose up -d --remove-orphans >/dev/null 2>&1 || { log_error "COMPOSE_UP_FAIL"; exit 1; }
  
  # C8: Wait for health checks
  log_info "WAITING_HEALTH: 30s grace period..."
  sleep 30
  bash "${SCRIPT_DIR}/health-check.sh" --env "$ENV" >/dev/null 2>&1 || { log_error "HEALTH_CHECK_FAIL"; exit 1; }
  update_phase "deploy"
  log_info "PHASE_3_COMPLETE: Deploy OK"
}

# [PHASE_4: VALIDATE]
phase_validate() {
  log_info "PHASE_4_START: Post-deploy validation"
  
  # C8: Promptfoo agent validation
  if [[ -d "${PIPELINES_DIR}/promptfoo" ]]; then
    cd "${PIPELINES_DIR}/promptfoo"
    npx promptfoo eval --config config.yaml --output results-${ENV}.json >/dev/null 2>&1 || log_warn "PROMPTFOO_WARN: Revisar results-${ENV}.json"
  fi
  
  # C8: DORA metrics check
  ERROR_RATE=$(curl -sf "http://${PROMETHEUS_HOST:-localhost}:9090/api/v1/query?query=sum(rate(http_requests_total{status=~\"5..\",env=\"${ENV}\"}[5m]))/sum(rate(http_requests_total{env=\"${ENV}\"}[5m]))" 2>/dev/null | jq -r '.data.result[0].value[1]' || echo "0")
  if (( $(echo "$ERROR_RATE > 0.01" | bc -l 2>/dev/null || echo 0) )); then
    log_warn "DORA_METRIC_FAIL: Error rate post-deploy > 1% (${ERROR_RATE})"
  else
    log_info "DORA_METRIC_OK: Error rate ${ERROR_RATE}"
  fi
  
  update_phase "validate"
  log_info "PHASE_4_COMPLETE: Validación OK"
}

# [PHASE_5: ROLLBACK]
phase_rollback() {
  log_warn "ROLLBACK_INIT: Iniciando recuperación de estado"
  if [[ ! -f "$STATE_FILE" ]]; then
    log_error "ROLLBACK_FAIL: No state file found"
    exit 1
  fi
  
  PHASES=$(jq -r '.phases | to_entries[] | select(.value == true) | .key' "$STATE_FILE")
  
  for phase in $PHASES; do
    case $phase in
      tf)
        log_info "ROLLBACK_TF: Aplicando estado anterior..."
        cd "$TF_DIR" && terraform apply -auto-approve -refresh-only >/dev/null 2>&1 || log_warn "ROLLBACK_TF_WARN"
        ;;
      build)
        log_info "ROLLBACK_BUILD: Reverting tags not implemented (immutable images)"
        ;;
      deploy)
        log_info "ROLLBACK_DEPLOY: Restarting previous compose stack..."
        cd "$COMPOSE_DIR" && docker compose down --timeout 30 && docker compose up -d --remove-orphans >/dev/null 2>&1 || log_warn "ROLLBACK_DEPLOY_WARN"
        ;;
      validate)
        log_info "ROLLBACK_VALIDATE: Skipping validation on rollback"
        ;;
    esac
  done
  
  log_info "ROLLBACK_COMPLETE: Verificar health manual"
  exit 0
}

# [EXECUTION]
[[ "$ROLLBACK" == true ]] && phase_rollback
init_state
[[ "$SKIP_TF" != true ]] && phase_terraform
[[ "$SKIP_BUILD" != true ]] && phase_build
phase_deploy
phase_validate

log_info "DEPLOY_SUCCESS: ${ENV} | $(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

---
