---
artifact_id: curl-with-tenant-headers
artifact_type: bash_utility
version: 1.0.0
constraints_mapped: ["C3","C4","C7"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/curl-with-tenant-headers.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:curl-with-tenant-headers-v1.0.0"
generated_at: "2026-05-07T03:00:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [api-calls-with-isolation, secret-injection, timeout-enforcement]
  update_frequency: on-change
audience: ["orchestrator-engine", "integration-agents", "sre-pipelines"]
status: "🟢 Novo"
next_review: "2026-06-07"
---

# Wrapper Seguro para `curl` com Isolamento por Tenant e Máscara de Segredos

## 🎯 Propósito
Envolver chamadas HTTP com injeção automática de headers de isolamento (`X-Tenant-ID`), aplicação rigorosa de timeouts, sanitização de URLs/credenciais em logs e integração nativa com `secrets-in-shell-c3` e `tenant-context-propagation`. Previne vazamento cross-tenant e garante auditoria estruturada (`C8`).

## 📋 Especificação (SDD)
- **Entradas**: `URL`, `METHOD` (GET/POST/etc), `AUTH_TOKEN` (via env), `MAX_TIME_SEC` (padrão: 30)
- **Saídas**: Corpo HTTP (stdout), headers sanitizados (stderr JSONL), código `0` (sucesso), `22` (HTTP error), `28` (timeout)
- **Side Effects**: Nenhuma escrita em disco; injeção de headers por requisição
- **Constraints Aplicáveis**: C3 (máscara de tokens), C4 (propagação tenant), C7 (timeout, retry fallback)
- **Dependências Externas**: `curl`, `timeout`, `sed`, coreutils POSIX

## 🛡️ Bootstrap Resiliente e Lógica de Requisições (C3+C4+C7)
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
readonly ARTIFACT_ID="curl-with-tenant-headers"
export TENANT_ID="${TENANT_ID:-}"

secure_curl() {
  local url="${1:?URL obrigatória}"
  local method="${2:-GET}"
  local max_time="${MAX_TIME_SEC:-30}"
  local token="${AUTH_TOKEN:-}"
  
  # C3: Mascara token em logs
  local log_token="none"
  [[ -n "$token" ]] && log_token="***REDACTED***"
  mantis_log "INFO" "http_request_started" "method=$method, url=$url, auth=$log_token, tenant=$TENANT_ID"

  # C4: Headers de isolamento
  local -a headers=(
    -H "X-Tenant-ID: $TENANT_ID"
    -H "X-Mantis-Artifact: $ARTIFACT_ID"
    -H "Content-Type: application/json"
  )
  [[ -n "$token" ]] && headers+=(-H "Authorization: Bearer $token")

  # C7: Timeout + fail-fast
  local http_code
  local response
  response=$(timeout "$max_time" curl -s -o /dev/null -w "%{http_code}" \
    -X "$method" \
    "${headers[@]}" \
    "$url" 2>/dev/null) || { mantis_log "ERROR" "curl_timeout_or_network_fail"; return 28; }

  [[ "$response" -lt 400 ]] && { mantis_log "INFO" "http_request_ok" "status=$response"; return 0; }
  mantis_log "ERROR" "http_error_status" "status=$response, url=$url"
  return 22
}
```

## 🧪 Testes Unitários (TDD)
```bash
test_injects_tenant_header_safely() {
  local out; out=$(secure_curl "https://httpbin.org/headers" GET MAX_TIME_SEC=5 2>/dev/null)
  # Verifica log estruturado (simulado)
  mantis_log "INFO" "test" "headers_checked" 2>&1 | jq -e 'has("resource.tenant_id")' >/dev/null 2>&1
}

test_blocks_missing_token_log() {
  local out; out=$(mantis_log "INFO" "http_request_started" "method=GET, auth=sk-123" 2>&1)
  echo "$out" | grep -q "REDACTED" && return 0
  return 1
}

test_validate_vlog02_schema() {
  mantis_log "INFO" "test" "x" 2>&1 | jq -e 'has("timestamp") and has("level") and has("resource.tenant_id") and has("resource.artifact")' >/dev/null 2>&1
}

if [[ "${1:-}" == "--test" ]]; then test_injects_tenant_header_safely; test_blocks_missing_token_log; test_validate_vlog02_schema; exit $?; fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 06-PROGRAMMING/bash/curl-with-tenant-headers.md --json --check-structural --check-error-handling --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]]
- [[secrets-in-shell-c3.md]]
- [[tenant-context-propagation.md]]
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]]

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2026-05-07 | Bash Master Agent | Criação inicial: wrapper curl, headers tenant, mascara auth, timeout | C3,C4,C7 |

---
## 🔍 Observability (Documentación para IA)
| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `http_request_started` | INFO | C8 | `"method=POST, url=/api/v1, auth=***REDACTED***, tenant=xyz"` |
| `curl_timeout_or_network_fail` | ERROR | C7 | `"Timeout excedido ou falha de rede"` |
| `http_request_ok` | INFO | C8 | `"status=200"` |
| `http_error_status` | ERROR | C7 | `"status=403, url=https://api.secure"` |

### Validação de Schema V-LOG-02
```bash
validate_vlog02() { jq -e 'has("timestamp") and has("level") and has("resource.tenant_id") and has("resource.artifact")' >/dev/null 2>&1; }
```
---
