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

## 🛡️ Hardening (Harness Norms v3.0 - Executável)
```bash
#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="2.0.0"

# C8: Auditoria JSONL em stderr
log_fix() {
  local level="${1:-INFO}" event="${2:-fix_event}" detail="${3:-}"
  printf '{"ts":"%s","level":"%s","tenant":"%s","script":"%s","event":"%s","detail":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "${TENANT_ID:-na}" "$SCRIPT_NAME" "$event" "$detail" >&2
}

# C7: Cleanup garantido em qualquer sinal
cleanup() {
  local exit_code=$?
  [[ -n "${WORKING_FILE:-}" && -f "${WORKING_FILE}" ]] && rm -f "${WORKING_FILE}"
  [[ -n "${CLEAN_FILE:-}" && -f "${CLEAN_FILE}" ]] && rm -f "${CLEAN_FILE}"
  exit $exit_code
}
trap cleanup EXIT INT TERM

readonly TARGET_SCRIPT="${1:?Uso: fix-syntax-code.sh <arquivo> [--dry-run|--apply]}"
readonly MODE="${2:---dry-run}"
readonly MAX_ATTEMPTS="${MAX_FIX_ATTEMPTS:-3}"

# C6: Sanitização e validação de entrada
[[ -f "$TARGET_SCRIPT" && -r "$TARGET_SCRIPT" ]] || { log_fix "ERROR" "file_missing_or_unreadable" "$TARGET_SCRIPT"; exit 1; }
[[ "$TARGET_SCRIPT" == *.sh || "$TARGET_SCRIPT" == *.sh.md ]] || { log_fix "ERROR" "invalid_extension" "$TARGET_SCRIPT"; exit 1; }

WORKING_FILE="$(mktemp)" || { log_fix "ERROR" "mktemp_failed"; exit 2; }
CLEAN_FILE="$(mktemp)" || { log_fix "ERROR" "mktemp_failed"; exit 2; }
cp "$TARGET_SCRIPT" "$WORKING_FILE" || { log_fix "ERROR" "copy_failed"; exit 2; }

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
  log_fix "INFO" "structural_fixes_applied" "Shebang, hardening, BOM, EOL"
}

# C7+C1: Loop controlado com oráculo bash -n
attempt=0
while [[ $attempt -lt $MAX_ATTEMPTS ]]; do
  if timeout 5 bash -n "$WORKING_FILE" 2>/dev/null; then
    log_fix "INFO" "syntax_validated" "Tentativa $attempt"
    break
  fi
  ((attempt++))
  log_fix "WARN" "retrying_fix" "Tentativa $attempt/$MAX_ATTEMPTS"
  apply_safe_fixes "$WORKING_FILE"
done

if ! bash -n "$WORKING_FILE" 2>/dev/null; then
  log_fix "ERROR" "fix_limit_exceeded" "Não corrigível após $MAX_ATTEMPTS iterações"
  exit 1
fi

# Aplicação condicional ou diff
if [[ "$MODE" == "--apply" ]]; then
  cp "$WORKING_FILE" "$TARGET_SCRIPT"
  log_fix "INFO" "file_overwritten" "$TARGET_SCRIPT"
else
  diff -u "$TARGET_SCRIPT" "$WORKING_FILE" || true
  log_fix "INFO" "dry_run_diff_generated" "Zero alterações aplicadas"
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
    printf '[TEST_FAIL] Script válido retornou erro %s\n' "$exit_code" >&2
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
    printf '[TEST_FAIL] Correção falhou ou hardening não inserido (exit: %s, hardening: %s)\n' "$exit_code" "$has_hardening" >&2
    rm -f "$temp_file"
    return 1
  fi
}

if [[ "${1:-}" == "--test" ]]; then
  test_fixer_validates_already_correct_script
  test_fixer_corrects_missing_hardening_and_eol
  exit $?
fi
```

## 🔍 Validação (VDD)
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --file 06-PROGRAMMING/bash/fix-syntax-code.md \
  --json \
  --check-secrets \
  --check-tenant-isolation \
  --check-structural \
  --check-resource-limits \
  --check-error-handling
```

## 🔗 Referências Cruzadas
- [[bash-master-agent.md]] ← Contrato de geração, anti-padrões proibidos (zero `eval`)
- [[01-RULES/harness-norms-v3.0.md]] ← Especificação de hardening C7
- [[01-RULES/10-SDD-CONSTRAINTS.md]] ← Definição de C3, C5, C6, C8
- [[01-RULES/05-CODE-PATTERNS-RULES.md]] ← Padrões de sanitização e correção estática
- [[00-CONTEXT/norms-matrix.json]] ← Fonte de verdade para validação de constraints

## 📝 Histórico de Revisões
| Versão | Data | Autor | Mudança Principal | Constraints Afetadas |
|--------|------|-------|------------------|---------------------|
| 1.0.0 | 2024-08-20 | Dev inicial | Renomeação de `fix-sintaxis-code.md`, lógica básica com `sed` | Parcial |
| 2.0.0 | 2026-05-06 | Bash Master Agent | Remanufatura completa: loop controlado com `bash -n`, zero `eval`, modo `dry-run` padrão, JSONL C8, testes TDD, sanização C6 | C3,C5,C6,C7,C8 |

---
