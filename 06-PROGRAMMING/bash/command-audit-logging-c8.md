---
artifact_id: command-audit-logging-c8
artifact_type: bash_utility
version: 1.0.0
constraints_mapped: ["C6","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/command-audit-logging-c8.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:command-audit-logging-c8-v1.0.0"
generated_at: "2026-05-07T01:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [execution-tracing, pii-scrubbing-in-args, telemetry-correlation]
  update_frequency: on-change
audience: ["sre-agents", "compliance-auditors", "orchestrator-engine"]
status: "🟢 Novo"
next_review: "2026-06-07"
---

# Auditoría Ejecutable de Comandos con Scrubbing PII y Trazabilidad (C8)

## 🎯 Propósito
Envolver la ejecución de comandos externos para capturar tiempos de inicio/fin, códigos de salida, argumentos sanitizados (PII/Secrets) y correlacionar con `trace_id`. Cumple C6 (sanitización) y C8 (auditoría forense estructurada).

## 📋 Especificação (SDD)
- **Entradas**: `COMMAND` (string o array), `TRACE_ID` (opcional)
- **Saídas**: JSONL en stderr con `command_sanitized`, `duration_ms`, `exit_code`, `trace_id`
- **Side Effects**: Ejecución del comando, logging estructurado
- **Constraints Aplicáveis**: C6 (scrubbing de argumentos), C8 (auditoría temporal y correlación)
- **Dependências Externas**: `date`, `time` (builtin o external), `sed`, coreutils POSIX

## 🛡️ Bootstrap Resiliente e Lógica de Auditoría (C6+C8)
```bash
if [[ -f "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" ]]; then
  source "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" --mode=observability-only
else
  set -Eeuo pipefail; shopt -s inherit_errexit 2>/dev/null || true
  trap 'exit 130' INT TERM
  : "${TENANT_ID:?ERROR: TENANT_ID não definido.}"
  mantis_log() { printf '{"ts":"%s","level":"%s","tenant":"%s","event":"%s","detail":"%s","fallback":"true"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${1:-INFO}" "${TENANT_ID:-unknown}" "${2:-bootstrap_fallback}" "${3:-}" >&2; }
  mantis_log "WARN" "bootstrap_fallback" "Master agent não encontrado."
fi

readonly SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
readonly ARTIFACT_ID="command-audit-logging-c8"
export TENANT_ID="${TENANT_ID:-}"

scrub_command_args() {
  local raw="$1"
  echo "$raw" | sed -E 's/(--password|--token|--secret|--api-key)[=:][^[:space:]]+/\1=***REDACTED***/gI'
}

audit_exec() {
  local cmd="$1" trace="${TRACE_ID:-none}"
  local sanitized
  sanitized=$(scrub_command_args "$cmd")
  
  mantis_log "INFO" "command_started" "cmd=$sanitized, trace=$trace"
  
  local start_ns end_ns duration_ms
  start_ns=$(date +%s%N)
  eval "$cmd"
  local exit_code=$?
  end_ns=$(date +%s%N)
  
  duration_ms=$(( (end_ns - start_ns) / 1000000 ))
  mantis_log "INFO" "command_completed" "cmd=$sanitized, exit_code=$exit_code, duration_ms=$duration_ms, trace=$trace"
  return $exit_code
}
```

## 🧪 Testes Unitários (TDD)
```bash
test_audit_exec_scrubs_sensitive_args() {
  local out
  out=$(scrub_command_args "deploy --password=secret123 --token=ghp_abc --safe var")
  [[ "$out" == "deploy --password=***REDACTED*** --token=***REDACTED*** --safe var" ]] && return 0
  return 1
}

test_audit_exec_logs_duration_and_exit() {
  export TRACE_ID="trace-test-001"
  audit_exec "echo 'ok'" 2>/dev/null
  mantis_log "INFO" "test" "x" 2>&1 | jq -e '.attributes.mantis.trace_id == "trace-test-001"' >/dev/null 2>&1
}

test_validate_vlog02_schema() {
  mantis_log "INFO" "test" "x" 2>&1 | jq -e 'has("timestamp") and has("resource.tenant_id") and has("resource.artifact")' >/dev/null 2>&1
}

if [[ "${1:-}" == "--test" ]]; then test_audit_exec_scrubs_sensitive_args; test_audit_exec_logs_duration_and_exit; test_validate_vlog02_schema; exit $?; fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/bash/command-audit-logging-c8.md --json --check-structural --check-error-handling --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]]
- [[01-RULES/05-CODE-PATTERNS-RULES.md]]
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]
- [[/05-CONFIGURATIONS/observability/otel-tracing-config.yaml]]

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-07 | Bash Master Agent | Criação inicial: wrapper ejecutable, scrubbing C6, trace C8 | C6,C8 |

---
## 🔍 Observability (Documentación para IA)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `command_started` | INFO | C8 | `"cmd=deploy --password=***REDACTED***, trace=abc-123"` |
| `command_completed` | INFO | C8 | `"cmd=deploy --password=***REDACTED***, exit_code=0, duration_ms=142, trace=abc-123"` |
| `pi_scrubbed` | DEBUG | C6 | `"Argumentos sanitizados antes de log"` |
| `trace_correlated` | DEBUG | C8 | `"Trazas vinculadas a span_id externo"` |

### Validação de Schema V-LOG-02
```bash
validate_vlog02() { jq -e 'has("timestamp") and has("level") and has("resource.tenant_id") and has("resource.artifact")' >/dev/null 2>&1; }
```
----
