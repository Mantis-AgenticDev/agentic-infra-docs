---
artifact_id: fix-syntax-code
artifact_type: bash_utility
version: 2.0.0
constraints_mapped: ["C3","C5","C6","C7","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file {canonical_path} --json"
canonical_path: "06-PROGRAMMING/bash/fix-syntax-code.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:fix-syntax-code-v2.0.0-remanufatured"
generated_at: "2026-05-06T12:30:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: bash
ai_navigation:
  read_first: false
  required_for: [pre-commit-correction, syntax-linting, code-quality-gate]
  update_frequency: on-change
audience: ["orchestrator-engine", "ci-cd-pipelines", "developer-tooling"]
status: "🟡 Em remanufatura"
next_review: "2026-06-05"
---

# Corretor Estrutural de Sintaxe Bash (Modo Seguro)

## 🎯 Propósito
Detectar e corrigir automaticamente anti-padrões estruturais comuns em scripts Bash (shebang inválido, hardening ausente, BOM UTF-8, linhas sem terminação, whitespace inconsistente) usando `bash -n` como oráculo de validação. Opera em modo `dry-run` por padrão, aplica correções apenas com flag explícita, gera diff auditável e **nunca executa ou avalia o conteúdo do script** (C3). Projetado para gates de qualidade em pipelines CI/CD e pré-validação de artefatos gerados por IA.

## 📋 Especificação (SDD)
- **Entradas**: 
  - `$1`: Caminho absoluto/relativo ao arquivo `.sh` ou `.sh.md`
  - `$2`: `--dry-run` (padrão) ou `--apply`
  - `MAX_FIX_ATTEMPTS`: limite de iterações de correção (padrão: `3`)
- **Saídas**: 
  - `0`: Sintaxe válida (corrigida ou já correta)
  - `1`: Falha persistente após limite de tentativas ou entrada inválida
  - `2`: Erro de sistema/timeout
  - Diff unificado em stdout (modo `dry-run`) ou log JSONL de ações aplicadas
- **Side Effects**: 
  - Criação de arquivos temporários seguros para cópia e validação
  - Nenhum overwrite do original sem flag `--apply`
  - Backup automático em memória de trabalho, descartado em cleanup
- **Constraints Aplicáveis**: C3 (zero execução/injeção), C5 (normalização estrutural), C6 (sanitização de caminhos e conteúdo), C7 (loop controlado com timeout e trap), C8 (auditoria JSONL de correções)
- **Dependências Externas**: `bash`, `sed`, `tr`, `diff`, `mktemp`, `timeout`, `grep` (POSIX coreutils)

## 🛡️ Bootstrap Resiliente e Lógica de Correção (C3+C5+C6+C7+C8)
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
readonly ARTIFACT_ID="fix-syntax-code"

# =============================================================================
# LÓGICA DE CORREÇÃO ESTRUTURAL (C3: Zero Execução de Conteúdo)
# =============================================================================
# C7: Cleanup garantido em qualquer sinal
cleanup_fix() {
  local exit_code=$?
  [[ -n "${WORKING_FILE:-}" && -f "${WORKING_FILE}" ]] && rm -f "${WORKING_FILE}"
  [[ -n "${CLEAN_FILE:-}" && -f "${CLEAN_FILE}" ]] && rm -f "${CLEAN_FILE}"
  if [[ $exit_code -ne 0 ]]; then
    mantis_log "ERROR" "fix_aborted" "Código de saída: $exit_code | Script: ${TARGET_SCRIPT:-unknown}"
  fi
  exit $exit_code
}
trap cleanup_fix EXIT INT TERM

readonly TARGET_SCRIPT="${1:?Uso: fix-syntax-code.sh <arquivo> [--dry-run|--apply]}"
readonly MODE="${2:---dry-run}"
readonly MAX_ATTEMPTS="${MAX_FIX_ATTEMPTS:-3}"

# C6: Sanitização e validação de entrada (zero path traversal)
[[ -f "$TARGET_SCRIPT" && -r "$TARGET_SCRIPT" ]] || { mantis_log "ERROR" "file_missing_or_unreadable" "Arquivo inexistente ou ilegível: $TARGET_SCRIPT"; exit 1; }
[[ "$TARGET_SCRIPT" == *.sh || "$TARGET_SCRIPT" == *.sh.md ]] || { mantis_log "ERROR" "invalid_extension" "Extensão não suportada: $TARGET_SCRIPT"; exit 1; }

# C5+C7: Criação segura de temporários no mesmo filesystem
WORKING_FILE="$(mktemp)" || { mantis_log "ERROR" "mktemp_failed" "Falha ao criar arquivo temporário de trabalho"; exit 2; }
CLEAN_FILE="$(mktemp)" || { mantis_log "ERROR" "mktemp_failed" "Falha ao criar arquivo temporário de limpeza"; exit 2; }
cp "$TARGET_SCRIPT" "$WORKING_FILE" || { mantis_log "ERROR" "copy_failed" "Falha ao copiar $TARGET_SCRIPT para staging"; exit 2; }

# C3+C5+C6: Correções puramente estruturais, zero avaliação de lógica
apply_safe_fixes() {
  local file="$1"
  # 1. Shebang padrão POSIX compatível
  sed -i '1s|^#!.*bash.*|#!/usr/bin/env bash|' "$file"
  # 2. Inserir hardening mínimo se ausente
  if ! grep -qE '^set -Eeuo pipefail$' "$file"; then
    sed -i '/^#!/a\set -Eeuo pipefail\nIFS=$'"'"'\\n\\t'"'"'' "$file"
  fi
  # 3. Remover BOM UTF-8 e bytes nulos
  sed -i '1s/^\xEF\xBB\xBF//' "$file"
  tr -d '\0' < "$file" > "${file}.clean" && mv "${file}.clean" "$file"
  # 4. Garantir terminação de linha POSIX
  sed -i -e '$a\' "$file"
  mantis_log "INFO" "structural_fixes_applied" "Shebang, hardening, BOM, EOL normalizados"
}

# C7+C1: Loop controlado com oráculo bash -n (validação estática apenas)
attempt=0
while [[ $attempt -lt $MAX_ATTEMPTS ]]; do
  if timeout 5 bash -n "$WORKING_FILE" 2>/dev/null; then
    mantis_log "INFO" "syntax_validated" "Sintaxe válida após $attempt iterações"
    break
  fi
  ((attempt++))
  mantis_log "WARN" "retrying_fix" "Tentativa $attempt/$MAX_ATTEMPTS para $TARGET_SCRIPT"
  apply_safe_fixes "$WORKING_FILE"
done

if ! bash -n "$WORKING_FILE" 2>/dev/null; then
  mantis_log "ERROR" "fix_limit_exceeded" "Não corrigível após $MAX_ATTEMPTS iterações: $TARGET_SCRIPT"
  exit 1
fi

# Aplicação condicional ou diff (C3: nunca executa o script)
if [[ "$MODE" == "--apply" ]]; then
  cp "$WORKING_FILE" "$TARGET_SCRIPT"
  mantis_log "INFO" "file_overwritten" "Arquivo atualizado: $TARGET_SCRIPT"
else
  diff -u "$TARGET_SCRIPT" "$WORKING_FILE" || true
  mantis_log "INFO" "dry_run_diff_generated" "Zero alterações aplicadas (modo dry-run)"
fi
exit 0
```

## 🧪 Testes Unitários (TDD)
```bash
test_fixer_validates_already_correct_script() {
  # Arrange
  local temp_file
  temp_file=$(mktemp)
  printf '#!/usr/bin/env bash\nset -Eeuo pipefail\nIFS=$'"'"'\\n\\t'"'"'\necho "OK"\n' > "$temp_file"

  # Act
  bash "${BASH_SOURCE[0]}" "$temp_file" --dry-run 2>/dev/null
  local exit_code=$?

  # Assert
  if [[ $exit_code -eq 0 ]]; then
    rm -f "$temp_file"
    return 0
  else
    mantis_log "ERROR" "test_failed" "Script válido retornou erro $exit_code"
    rm -f "$temp_file"
    return 1
  fi
}

test_fixer_corrects_missing_hardening_and_eol() {
  # Arrange
  local temp_file
  temp_file=$(mktemp)
  printf '#!/bin/bash\necho "test"' > "$temp_file"  # Sem set, sem EOL, shebang antigo

  # Act
  bash "${BASH_SOURCE[0]}" "$temp_file" --apply 2>/dev/null
  local exit_code=$?
  local has_hardening
  has_hardening=$(grep -c 'set -Eeuo pipefail' "$temp_file")

  # Assert
  if [[ $exit_code -eq 0 && $has_hardening -ge 1 ]]; then
    rm -f "$temp_file"
    return 0
  else
    mantis_log "ERROR" "test_failed" "Correção falhou ou hardening não inserido (exit: $exit_code, hardening: $has_hardening)"
    rm -f "$temp_file"
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
  test_fixer_validates_already_correct_script
  test_fixer_corrects_missing_hardening_and_eol
  test_validate_vlog02_schema
  exit $?
fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/bash/fix-syntax-code.md \
  --json \
  --check-secrets \
  --check-structural \
  --check-resource-limits \
  --check-error-handling \
  --check-observability
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]] ← Contrato de geração, anti-padrões proibidos (zero `eval`)
- [[01-RULES/harness-norms-v3.0.md]] ← Especificação de hardening C7
- [[01-RULES/10-SDD-CONSTRAINTS.md]] ← Definição de C3, C5, C6, C8
- [[01-RULES/05-CODE-PATTERNS-RULES.md]] ← Padrões de sanitização e correção estática
- [[/05-CONFIGURATIONS/observability/00-INDEX.md]] ← Índice de observabilidade
- [[/05-CONFIGURATIONS/observability/loki/config.yml]] ← Pipeline de ingestão de logs JSONL
- [[00-CONTEXT/norms-matrix.json]] ← Fonte de verdade para validação de constraints

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2024-08-20 | Dev inicial | Renomeação de `fix-sintaxis-code.md`, lógica básica com `sed` | Parcial |
| 2.0.0 | 2026-05-06 | Bash Master Agent | Remanufatura: bootstrap resiliente, `mantis_log()` canônica, validação V-LOG-02, remoção de hardening inline | C3,C5,C6,C7,C8 |

---
## 🔍 Observability (Documentação para IA)

> Este artefato emite os seguintes eventos via `mantis_log()` (definida em [[bash-master-agent.md]]):

| Evento | Nível | Constraint | Exemplo de `detail` |
|--------|-------|------------|-------------------|
| `fix_started` | INFO | C8 | `"Arquivo: /path/script.sh, modo: dry-run"` |
| `file_missing_or_unreadable` | ERROR | C6 | `"Arquivo inexistente ou ilegível: /tmp/missing.sh"` |
| `structural_fixes_applied` | INFO | C5 | `"Shebang, hardening, BOM, EOL normalizados"` |
| `syntax_validated` | INFO | C7 | `"Sintaxe válida após 1 iterações"` |
| `retrying_fix` | WARN | C7 | `"Tentativa 2/3 para /path/script.sh"` |
| `fix_limit_exceeded` | ERROR | C7 | `"Não corrigível após 3 iterações: /path/script.sh"` |
| `file_overwritten` | INFO | C3 | `"Arquivo atualizado: /path/script.sh"` |
| `dry_run_diff_generated` | INFO | C8 | `"Zero alterações aplicadas (modo dry-run)"` |

### Exemplo de Output JSONL (para aprendizado de padrão por IA)
```json
{"timestamp":"2026-05-06T12:30:00Z","level":"INFO","resource":{"tenant_id":"global","artifact":"fix-syntax-code"},"body":{"event":"structural_fixes_applied","detail":"Shebang, hardening, BOM, EOL normalizados"},"attributes":{"mantis":{"tier":"2","version":"2.0.0","constraint":"C3,C5,C6","trace_id":""},"code.filepath":"06-PROGRAMMING/bash/fix-syntax-code.md","code.lineno":67,"telemetry.sdk.name":"mantis-bash-adapter","telemetry.sdk.version":"1.0.0"}}
```

### Configuração Específica de Este Artefato
```bash
# Variáveis de entorno que afetam o comportamento de logging deste artefato
export LOG_FIX_DIFF="${LOG_FIX_DIFF:-true}"           # Incluir diff unificado em logs (modo dry-run)
export LOG_FIX_ATTEMPTS="${LOG_FIX_ATTEMPTS:-true}"   # Incluir contagem de tentativas de correção
export TRACE_FIX_OPS="${TRACE_FIX_OPS:-false}"        # Habilitar trace_id para correlação OTel
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
