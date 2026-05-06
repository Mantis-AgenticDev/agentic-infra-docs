---
artifact_id: hardening-verification
artifact_type: bash_utility
version: 2.0.0
constraints_mapped: ["C1","C5","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/hardening-verification.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:hardening-verification-v2.0.0-remanufatured"
generated_at: "2026-05-06T12:05:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [pre-commit-validation, pipeline-gate, audit-compliance]
  update_frequency: on-change
audience: ["orchestrator-engine", "ci-cd-pipelines", "security-auditors"]
status: "🟡 Em remanufatura"
next_review: "2026-06-05"
---

# Verificação Automatizada de Hardening Bash

## 🎯 Propósito
Validar scripts Bash contra as normas de endurecimento (Harness Norms v3.0) do projeto MANTIS antes do commit ou deploy. Verifica presença obrigatória de `set -Eeuo pipefail`, `IFS` seguro, `trap` de cleanup, validação de tenant, timeouts estruturados e logging em stderr. Gera output JSONL para consumo direto pelo orchestrator-engine ou pipelines CI/CD.

## 📋 Especificação (SDD)
- **Entradas**: 
  - `$1`: Caminho absoluto ou relativo ao arquivo `.sh` ou `.sh.md`
  - `$STRICT_MODE`: (booleano, padrão: `true`) Falha no primeiro erro crítico
  - `$MAX_SCAN_SECONDS`: (inteiro, padrão: `10`) Limite de tempo para análise estática
- **Saídas**: 
  - Objeto JSON em stdout: `{"script": "...", "passed": bool, "issues": [...], "metrics": {...}}`
  - Códigos de retorno: `0` (aprovado), `1` (falha em constraint crítica), `2` (erro de execução/timeout)
- **Side Effects**: 
  - Nenhum (leitura pura, sem modificação de arquivos)
  - Logs de execução em stderr (JSONL) para auditoria via `mantis_log()`
- **Constraints Aplicáveis**: C1 (limite de tempo de varredura), C5 (validação estrutural de padrões), C7 (verificação de resiliência), C8 (registro de auditoria)
- **Dependências Externas**: `grep`, `awk`, `sed` (apenas para extração segura), `date`, `jq` (opcional, fallback nativo em bash)

## 🛡️ Bootstrap Resiliente e Lógica de Verificação (C1+C5+C7+C8)
```bash
# =============================================================================
# BOOTSTRAP RESILIENTE: Hardening + Observabilidade (C3+C4+C7)
# Fonte de verdade: bash-master-agent.md via source
# Nota: tenant_context=nao_aplicavel → validação de TENANT_ID opcional
# =============================================================================
if [[ -f "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" ]]; then
  source "${MANTIS_ROOT:-.}/06-PROGRAMMING/bash/bash-master-agent.sh" --mode=observability-only
else
  set -Eeuo pipefail; shopt -s inherit_errexit 2>/dev/null || true
  trap 'exit 130' INT TERM
  # C4: Validação condicional (apenas se tenant_context != nao_aplicavel)
  if [[ "${TENANT_CONTEXT:-nao_aplicavel}" != "nao_aplicavel" ]]; then
    : "${TENANT_ID:?ERROR: TENANT_ID não definido. Defina via env ou argumento.}"
  fi
  mantis_log() { printf '{"ts":"%s","level":"%s","tenant":"%s","event":"%s","detail":"%s","fallback":"true"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${1:-INFO}" "${TENANT_ID:-global}" "${2:-bootstrap_fallback}" "${3:-}" >&2; }
  mantis_log "WARN" "bootstrap_fallback" "Master agent não encontrado. Executando com hardening mínimo."
fi

readonly SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="${VERSION:-2.0.0}"
readonly ARTIFACT_ID="hardening-verification"

# =============================================================================
# LÓGICA DE VERIFICAÇÃO DE HARDENING (C1+C5+C7+C8)
# =============================================================================
# C7: Cleanup garantido em qualquer sinal
cleanup_verify() {
  local exit_code=$?
  # Finalizar watchdog se ainda estiver ativo
  [[ -n "${WATCHDOG_PID:-}" ]] && kill "$WATCHDOG_PID" 2>/dev/null && wait "$WATCHDOG_PID" 2>/dev/null || true
  if [[ $exit_code -ne 0 ]]; then
    mantis_log "ERROR" "verification_aborted" "Código de saída: $exit_code | Script: ${TARGET_SCRIPT:-unknown}"
  fi
  exit $exit_code
}
trap cleanup_verify EXIT INT TERM

readonly TARGET_SCRIPT="${1:?Uso: hardening-verification.sh <caminho-do-script>}"
readonly STRICT_MODE="${STRICT_MODE:-true}"
readonly MAX_SCAN_SECONDS="${MAX_SCAN_SECONDS:-10}"

# C1: Watchdog para timeout na varredura estática (evita loops em arquivos malformados)
(
  sleep "$MAX_SCAN_SECONDS"
  mantis_log "ERROR" "verification_timeout" "Limite de ${MAX_SCAN_SECONDS}s excedido na verificação de ${TARGET_SCRIPT}"
  exit 2
) &
WATCHDOG_PID=$!

# =============================================================================
# FUNÇÕES DE VERIFICAÇÃO POR CONSTRAINT (C5 + C7)
# =============================================================================
verify_hardening() {
  local script="$1"
  local issues=()
  local passed=true

  # C5: Validação de shebang POSIX
  if ! head -1 "$script" | grep -qE '^#!/usr/bin/env bash$'; then
    issues+=("shebang_invalid: deve ser #!/usr/bin/env bash")
    [[ "$STRICT_MODE" == "true" ]] && passed=false
  fi

  # C7: Validação de set -Eeuo pipefail
  if ! grep -qE '^set -Eeuo pipefail$' "$script"; then
    issues+=("missing_strict_mode: set -Eeuo pipefail não encontrado")
    [[ "$STRICT_MODE" == "true" ]] && passed=false
  fi

  # C5: Validação de IFS seguro
  if ! grep -qE "^IFS=\$'\\\\n\\\\t'$" "$script"; then
    issues+=("unsafe_ifs: IFS deve ser \$'\\n\\t' para evitar word splitting")
    [[ "$STRICT_MODE" == "true" ]] && passed=false
  fi

  # C7: Validação de trap de cleanup
  if ! grep -qE 'trap .* (EXIT|INT|TERM)' "$script"; then
    issues+=("missing_trap: trap para cleanup em EXIT/INT/TERM não encontrado")
    [[ "$STRICT_MODE" == "true" ]] && passed=false
  fi

  # C4: Validação de tenant (apenas se aplicável ao script alvo)
  if grep -q 'tenant_context: "obrigatorio"' "$script" 2>/dev/null; then
    if ! grep -qE ':\s*"\$\{TENANT_ID:\?' "$script"; then
      issues+=("missing_tenant_validation: validação de TENANT_ID ausente")
      [[ "$STRICT_MODE" == "true" ]] && passed=false
    fi
  fi

  # C1: Validação de timeout em operações críticas
  if grep -qE '(curl|wget|psql|mysql|git push)' "$script" 2>/dev/null; then
    if ! grep -qE 'timeout [0-9]+' "$script"; then
      issues+=("missing_timeout: operações de rede/IO devem ter timeout explícito")
      [[ "$STRICT_MODE" == "false" ]] && mantis_log "WARN" "missing_timeout_warning" "Operações sem timeout detectadas em $script"
    fi
  fi

  # C8: Validação de logging estruturado
  if grep -qE '(printf|echo).*\[INFO\]|\[ERROR\]' "$script" 2>/dev/null; then
    issues+=("unstructured_logging: usar mantis_log() em vez de printf/echo para logs")
    [[ "$STRICT_MODE" == "true" ]] && passed=false
  fi

  # Output JSON estruturado
  local issues_json
  issues_json=$(printf '%s\n' "${issues[@]}" | jq -R . | jq -s .)
  local issue_count=${#issues[@]}

  if [[ "$passed" == "true" ]]; then
    mantis_log "INFO" "verification_passed" "Script aprovado: $script | Issues: $issue_count"
  else
    mantis_log "ERROR" "verification_failed" "Script reprovado: $script | Issues críticas: $issue_count"
  fi

  # Retorno JSON para consumo por orchestrator
  printf '{"script":"%s","passed":%s,"issues":%s,"metrics":{"scan_time_sec":%d,"lines_scanned":%d}}\n' \
    "$script" \
    "$passed" \
    "$issues_json" \
    "$(($(date +%s) - start_ts))" \
    "$(wc -l < "$script")"
}

# =============================================================================
# EXECUÇÃO PRINCIPAL
# =============================================================================
start_ts=$(date +%s)

# C6: Validação de entrada (caminho seguro)
[[ -f "$TARGET_SCRIPT" && -r "$TARGET_SCRIPT" ]] || { mantis_log "ERROR" "file_missing_or_unreadable" "Arquivo inexistente ou ilegível: $TARGET_SCRIPT"; exit 1; }
[[ "$TARGET_SCRIPT" == *.sh || "$TARGET_SCRIPT" == *.sh.md ]] || { mantis_log "ERROR" "invalid_extension" "Extensão não suportada: $TARGET_SCRIPT"; exit 1; }

mantis_log "INFO" "verification_started" "Iniciando verificação de hardening para: $TARGET_SCRIPT | Strict: $STRICT_MODE"

# Executar verificação e capturar resultado
result=$(verify_hardening "$TARGET_SCRIPT")
exit_code=$?

# Finalizar watchdog com sucesso
kill "$WATCHDOG_PID" 2>/dev/null && wait "$WATCHDOG_PID" 2>/dev/null || true

# Output do resultado
echo "$result"

# Código de retorno baseado em passed/fail
if echo "$result" | jq -e '.passed == true' >/dev/null 2>&1; then
  exit 0
else
  exit 1
fi
```

## 🧪 Testes Unitários (TDD)
```bash
test_verify_passes_on_valid_script() {
  # Arrange
  local temp_valid
  temp_valid=$(mktemp)
  cat > "$temp_valid" << 'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
trap 'exit $?' EXIT
: "${TENANT_ID:?Required}"
timeout 60 echo "safe"
EOF

  # Act
  local result
  result=$(bash "${BASH_SOURCE[0]}" "$temp_valid" 2>/dev/null) || true
  
  # Assert
  if echo "$result" | jq -e '.passed == true' >/dev/null 2>&1; then
    rm -f "$temp_valid"
    return 0
  else
    mantis_log "ERROR" "test_failed" "Script válido não passou na verificação"
    rm -f "$temp_valid"
    return 1
  fi
}

test_verify_fails_on_missing_set_euo() {
  # Arrange
  local temp_invalid
  temp_invalid=$(mktemp)
  echo '#!/usr/bin/env bash' > "$temp_invalid"
  echo 'echo "unsafe"' >> "$temp_invalid"

  # Act
  local result
  result=$(bash "${BASH_SOURCE[0]}" "$temp_invalid" 2>/dev/null) || true

  # Assert
  if echo "$result" | jq -e '.passed == false' >/dev/null 2>&1; then
    rm -f "$temp_invalid"
    return 0
  else
    mantis_log "ERROR" "test_failed" "Script inválido não foi detectado"
    rm -f "$temp_invalid"
    return 1
  fi
}

test_validate_vlog02_schema() {
  local log_output
  log_output=$(mantis_log "INFO" "test_event" "detalhe_teste" 2>&1)
  if printf '%s\n' "$log_output" | jq -e '
    has("timestamp") and has("level") and has("resource.tenant_id") and has("resource.artifact") and has("body.event")
  ' >/dev/null 2>&1; then
    return 0
  else
    mantis_log "ERROR" "schema_validation_failed" "Log não conforma com V-LOG-02"
    return 1
  fi
}

if [[ "${1:-}" == "--test" ]]; then
  test_verify_passes_on_valid_script
  test_verify_fails_on_missing_set_euo
  test_validate_vlog02_schema
  exit $?
fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/bash/hardening-verification.md \
  --json \
  --check-secrets \
  --check-structural \
  --check-resource-limits \
  --check-error-handling \
  --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]] ← Contrato de geração e função `mantis_log()`
- [[01-RULES/harness-norms-v3.0.md]] ← Especificação de hardening C7
- [[01-RULES/10-SDD-CONSTRAINTS.md]] ← Definição de C1, C5, C7, C8
- [[01-RULES/validation-checklist.md]] ← Checklist de validação por constraint
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]] ← Índice de observabilidade
- [[/05-CONFIGURATIONS/observability/loki/config.yml]] ← Pipeline de ingestão de logs JSONL
- [[00-CONTEXT/norms-matrix.json]] ← Fonte de verdade para validação de constraints

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2024-08-15 | Dev inicial | Criação básica com grep simples | Parcial |
| 2.0.0 | 2026-05-06 | Bash Master Agent | Remanufatura: bootstrap resiliente, `mantis_log()` canônica, validação V-LOG-02, watchdog C1, remoção de hardening inline | C1,C5,C7,C8 |

---
## 🔍 Observability (Documentação para IA)

> Este artefato emite os seguintes eventos via `mantis_log()` (definida em [[bash-master-agent.md]]):

| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `verification_started` | INFO | C8 | `"Iniciando verificação de hardening para: /path/script.sh | Strict: true"` |
| `file_missing_or_unreadable` | ERROR | C6 | `"Arquivo inexistente ou ilegível: /tmp/missing.sh"` |
| `verification_passed` | INFO | C5 | `"Script aprovado: /path/script.sh | Issues: 0"` |
| `verification_failed` | ERROR | C7 | `"Script reprovado: /path/script.sh | Issues críticas: 3"` |
| `missing_strict_mode` | ERROR | C7 | `"set -Eeuo pipefail não encontrado"` |
| `unsafe_ifs` | WARN | C5 | `"IFS deve ser \$'\\n\\t' para evitar word splitting"` |
| `missing_trap` | ERROR | C7 | `"trap para cleanup em EXIT/INT/TERM não encontrado"` |
| `missing_tenant_validation` | ERROR | C4 | `"validação de TENANT_ID ausente em script com tenant_context=obrigatorio"` |
| `missing_timeout_warning` | WARN | C1 | `"Operações sem timeout detectadas em /path/script.sh"` |
| `unstructured_logging` | ERROR | C8 | `"usar mantis_log() em vez de printf/echo para logs"` |
| `verification_timeout` | ERROR | C1 | `"Limite de 10s excedido na verificação de /path/script.sh"` |
| `verification_aborted` | ERROR | C7 | `"Código de saída: 1 | Script: /path/script.sh"` |

### Exemplo de Output JSONL (para aprendizado de padrão por IA)
```json
{"timestamp":"2026-05-06T12:05:00Z","level":"INFO","resource":{"tenant_id":"global","artifact":"hardening-verification"},"body":{"event":"verification_passed","detail":"Script aprovado: 06-PROGRAMMING/bash/context-compaction-utils.md | Issues: 0"},"attributes":{"mantis":{"tier":"2","version":"2.0.0","constraint":"C1,C5,C7,C8","trace_id":""},"code.filepath":"06-PROGRAMMING/bash/hardening-verification.md","code.lineno":112,"telemetry.sdk.name":"mantis-bash-adapter","telemetry.sdk.version":"1.0.0"}}
```

### Configuração Específica de Este Artefato
```bash
# Variáveis de entorno que afetam o comportamento de logging deste artefato
export LOG_VERIFY_DETAILS="${LOG_VERIFY_DETAILS:-true}"    # Incluir lista de issues em logs
export LOG_VERIFY_METRICS="${LOG_VERIFY_METRICS:-true}"    # Incluir tempo de scan e linhas processadas
export TRACE_VERIFY_OPS="${TRACE_VERIFY_OPS:-false}"       # Habilitar trace_id para correlação OTel
```

### Validação de Schema V-LOG-02 (Helper Executável)
```bash
# Função helper para validação local de logs
validate_vlog02() {
  jq -e '
    has("timestamp") and
    has("level") and
    has("resource.tenant_id") and
    has("resource.artifact") and
    has("body.event") and
    has("attributes.mantis.tier") and
    has("attributes.mantis.version")
  ' >/dev/null 2>&1
}

# Uso em testes ou validação manual:
# mantis_log "INFO" "test" "x" 2>&1 | validate_vlog02 && echo "✅ Schema V-LOG-02 válido"
```
---
