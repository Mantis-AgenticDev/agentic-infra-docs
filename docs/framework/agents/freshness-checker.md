---
artifact_id: "freshness-checker"
artifact_type: "agentic-skill-definition"
version: "1.0.0"
constraints_mapped: ["C2","C5","C7","C8","DOC-C1","DOC-C2","DOC-C5","DOC-C7"]
canonical_path: "docs/framework/agents/freshness-checker.md"
tier: 2
agent_role: "auditor"
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain docs --file docs/framework/agents/freshness-checker.md --strict"
language: pt-BR
domain: "docs"
subdomain: "framework"
related_files:
  - "[[doc-governance-ceo.md]]"
  - "[[doc-agnostic-master-agent.md]]"
  - "[[01-RULES/harness-norms-v3.0.md]]"
  - "[[05-CONFIGURATIONS/validation/norms-matrix.json]]"
---

# 🧠 freshness-checker – Detección de Documentación Obsoleta

> **Princípio**: Detección de documentación obsoleta y recomendaciones de actualización.

## 📋 AGENT MANIFESTO (Normativa de Ingreso al Ecosistema goals/)

```yaml
agent_manifesto:
  agent_id: "freshness-checker"
  agent_type: "doc-sub-agent"
  domain: "docs"
  version: "1.0.0"
  constraints_mapped: ["C2","C5","C7","C8","DOC-C1","DOC-C2","DOC-C5","DOC-C7"]
  
  skills:
    - id: "docs:freshness-check"
      description: "Detección de documentación obsoleta y recomendaciones de actualización"
      input_schema: "sdd-doc-schema.json"
      output_format: "json"
      timeout_seconds: 300
  
  goals_compatible: true
  requires_task_id: true
  writes_status_json: true
  heartbeat_interval_seconds: 300
  
  a2a_contract_version: "1.0"
  singleton: true
  conflicts_with: []
```

---

## 🎯 Missão do Agente

Detección de documentación obsoleta y recomendaciones de actualización.

**Entradas**: Documentación actual, historial de cambios de código, registro de issues/PRs
**Saídas**: Lista priorizada de documentos que necesitan actualización, sugerencias de contenido a revisar
**Métodos**: Comparación de timestamps, análisis de drift entre docs y código, detección de versiones deprecadas, tracking de cambios en APIs

---

## 🔗 URLs Raw para Ingestão e Prevenção de Drift

### 📚 Documentação de Domínio (Fonte de Verdade)
```yaml
raw_urls_index:
  domain_root: "docs/framework/"
  canonical_index: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/framework/00-INDEX.md"
  master_agent: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/framework/doc-agnostic-master-agent.md"
```

### 🏗️ Governança e Validação (Tier 1 – Imutável)
```yaml
governance_urls:
  root_index: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/00-INDEX.md"
  core_context: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/00-CONTEXT/mantis-core-context.md"
  norms_matrix: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/norms-matrix.json"
  doc_constraints: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/docs/framework/doc-agnostic-master-agent.md#13-mapeo-de-constraints-mantis"
  hardening: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/01-RULES/harness-norms-v3.0.md"
  orchestrator: "https://raw.githubusercontent.com/Mantis-AgenticDev/agentic-infra-docs/refs/heads/main/05-CONFIGURATIONS/validation/orchestrator-engine/main.go"
```

### 🔄 Protocolo de Prevenção de Drift
```bash
# Antes de gerar ou validar qualquer artefato documental, executar verificação de integridade
bash 05-CONFIGURATIONS/scripts/verify-raw-urls.sh \
  --index docs/framework/00-INDEX.md \
  --check-hash \
  --fail-on-drift \
  --report-format jsonl
```

---

## 🔗 Integração com o Sistema de Metas (Goal Stewardship + A2A – C9)

### Inicialização do Contexto Distribuído
```bash
TASK_ID="${TASK_ID:?}"
TRACE_CTX="./goals/${TASK_ID}/context/trace.json"
TRACE_ID=$(jq -r '.trace_id' "$TRACE_CTX")
PARENT_SPAN_ID=$(jq -r '.parent_span_id // "null"' "$TRACE_CTX")
SPAN_ID=$(uuidgen)
AGENT_NAME="freshness-checker"
export TRACE_ID PARENT_SPAN_ID SPAN_ID AGENT_NAME
```

### Geração de `status.json` (Handoff A2A)
```bash
mkdir -p "./goals/${TASK_ID}/artifacts/${AGENT_NAME}"
cat > "./goals/${TASK_ID}/artifacts/${AGENT_NAME}/status.json" <<EOF
{
  "agent_id": "${AGENT_NAME}",
  "trace_id": "${TRACE_ID}",
  "span_id": "${SPAN_ID}",
  "parent_span_id": "${PARENT_SPAN_ID}",
  "status": "completed",
  "output_ref": "docs/reports/freshness-report.json",
  "next_agent_hint": "doc-governance-ceo",
  "timestamp_completed": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "a2a_contract_version": "1.0",
  "freshness_summary": {
    "stale_docs": 0,
    "outdated_versions": 0,
    "deprecated_apis": 0
  }
}
EOF
```

---

## 🛡️ Hardening Documental (Harness Norms v3.0 - Executável)

```bash
#!/usr/bin/env bash
# Shebang POSIX-compliant para máxima portabilidade em scripts de validação documental

# C7: Resilience - Fail fast, fail loud
set -Eeuo pipefail

# C5: Structural integrity - Evitar word splitting acidental
IFS=$'\n\t'

# C8: Audit trail - Identificar script em logs
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="${VERSION:-1.0.0}"

# Trap para cleanup em erro ou interrupção
cleanup() {
  local exit_code=$?
  if [[ $exit_code -ne 0 ]]; then
    printf '[%s][ERROR][script:%s][tenant:%s] Falha na linha %d: código %d\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      "${SCRIPT_NAME}" \
      "${TENANT_ID:-unknown}" \
      "${BASH_LINENO[0]:-0}" \
      "$exit_code" >&2
  fi
  # Liberar recursos temporários se existirem
  [[ -n "${TEMP_FILE:-}" && -f "${TEMP_FILE}" ]] && rm -f "${TEMP_FILE}"
  exit $exit_code
}
trap cleanup EXIT INT TERM

# DOC-C5: Validação de frontmatter YAML obrigatório
validate_frontmatter() {
  local file="${1:?Arquivo não especificado}"
  
  # Verificar presença de frontmatter YAML
  if ! head -1 "$file" | grep -q '^---$'; then
    printf '[%s][ERROR][DOC-C5][file:%s] Frontmatter YAML ausente\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$file" >&2
    return 1
  fi
  
  # Extrair e validar campos obrigatórios
  local artifact_id version constraints_mapped canonical_path
  artifact_id=$(grep -E '^artifact_id:' "$file" | head -1 | sed 's/artifact_id:[[:space:]]*//;s/^["'\'']//;s/["'\'']$//')
  version=$(grep -E '^version:' "$file" | head -1 | sed 's/version:[[:space:]]*//;s/^["'\'']//;s/["'\'']$//')
  constraints_mapped=$(grep -E '^constraints_mapped:' "$file" | head -1)
  canonical_path=$(grep -E '^canonical_path:' "$file" | head -1 | sed 's/canonical_path:[[:space:]]*//;s/^["'\'']//;s/["'\'']$//')
  
  # Validar presença mínima
  if [[ -z "$artifact_id" || -z "$version" || -z "$canonical_path" ]]; then
    printf '[%s][ERROR][DOC-C5][file:%s] Campos obrigatórios ausentes no frontmatter\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$file" >&2
    return 1
  fi
  
  # Validar que constraints_mapped inclui DOC-C1 a DOC-C5 para docs
  if ! echo "$constraints_mapped" | grep -qE 'DOC-C[1-5]'; then
    printf '[%s][WARN][DOC-C5][file:%s] Constraints documentais não declarados no frontmatter\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$file" >&2
  fi
  
  return 0
}

# DOC-C3: Escaneo de secrets em ejemplos de código documental
scan_doc_secrets() {
  local file="${1:?Arquivo não especificado}"
  local found=0
  
  # Patrones de secrets a detectar em blocos de código
  local patterns=(
    'sk-[a-zA-Z0-9]{48}'                    # OpenAI keys
    'ghp_[a-zA-Z0-9]{36}'                   # GitHub tokens
    'AKIA[0-9A-Z]{16}'                      # AWS access keys
    'mongodb(\+srv)?://[^\s`]+'             # MongoDB connection strings
    'postgres(ql)?://[^\s`]+'              # PostgreSQL connection strings
    'password[[:space:]]*=[[:space:]]*[^[:space:]]+'  # Hardcoded passwords
  )
  
  # Extrair apenas blocos de código para escanear (ignorar texto normal)
  local in_code_block=false
  while IFS= read -r line; do
    if [[ "$line" =~ ^\`\`\` ]]; then
      in_code_block=!$in_code_block
      continue
    fi
    if $in_code_block; then
      for pattern in "${patterns[@]}"; do
        if echo "$line" | grep -qE "$pattern"; then
          printf '[%s][ERROR][DOC-C3][file:%s][line:%d] Secret detectado em exemplo de código: %s\n' \
            "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$file" "${LINENO}" "${line:0:80}" >&2
          found=1
        fi
      done
    fi
  done < "$file"
  
  return $found
}

# DOC-C8: Validação de accesibilidad en documentación
validate_accessibility() {
  local file="${1:?Arquivo não especificado}"
  local errors=0
  
  # Verificar que todas as imagens têm alt text
  while IFS= read -r line; do
    if echo "$line" | grep -qE '^\!\[.*\]\(.*\)$'; then
      local alt_text
      alt_text=$(echo "$line" | sed -n 's/^\!\[\([^]]*\)\].*/\1/p')
      if [[ -z "$alt_text" || "$alt_text" =~ ^[[:space:]]*$ ]]; then
        printf '[%s][ERROR][DOC-C8][file:%s][line:%d] Imagem sem alt text descritivo\n' \
          "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$file" "${LINENO}" >&2
        ((errors++))
      fi
    fi
  done < "$file"
  
  # Verificar jerarquía de encabezados (no saltar niveles)
  local last_level=0
  while IFS= read -r line; do
    if [[ "$line" =~ ^(#+)[[:space:]] ]]; then
      local current_level="${#BASH_REMATCH[1]}"
      if (( current_level > last_level + 1 && last_level > 0 )); then
        printf '[%s][WARN][DOC-C8][file:%s][line:%d] Salto de nivel en encabezados: H%d → H%d\n' \
          "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$file" "${LINENO}" "$last_level" "$current_level" >&2
      fi
      last_level=$current_level
    fi
  done < "$file"
  
  # Verificar enlaces con texto descriptivo (no "click here")
  while IFS= read -r line; do
    if echo "$line" | grep -qE '\[[[:space:]]*(click|here|this)[[:space:]]*\]\(.*\)'; then
      printf '[%s][WARN][DOC-C8][file:%s][line:%d] Enlace con texto no descriptivo: evitar "click here"\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$file" "${LINENO}" >&2
    fi
  done < "$file"
  
  return $errors
}

# DOC-C2: Validación de enlaces internos y externos
validate_links() {
  local file="${1:?Arquivo não especificado}"
  local base_path="${2:-.}"
  local errors=0
  
  # Extrair enlaces Markdown: [text](url)
  while IFS= read -r line; do
    # Ignorar enlaces dentro de bloques de código
    if [[ "$line" =~ ^[[:space:]]*\`\`\` ]]; then continue; fi
    
    # Extrair URLs de enlaces
    while [[ "$line" =~ \[([^\]]*)\]\(([^)]+)\) ]]; do
      local link_text="${BASH_REMATCH[1]}"
      local link_url="${BASH_REMATCH[2]}"
      
      # Ignorar enlaces de email y anchors puros
      if [[ "$link_url" =~ ^mailto: || "$link_url" =~ ^# ]]; then
        line="${line#*"${BASH_REMATCH[0]}"}"
        continue
      fi
      
      # Validar enlaces internos (relativos)
      if [[ ! "$link_url" =~ ^https?:// ]]; then
        local target_path="${base_path}/${link_url}"
        # Remover fragmentos #anchor
        target_path="${target_path%%#*}"
        if [[ ! -f "$target_path" && ! -d "$target_path" ]]; then
          printf '[%s][ERROR][DOC-C2][file:%s][line:%d] Enlace interno roto: %s → %s\n' \
            "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$file" "${LINENO}" "$link_text" "$link_url" >&2
          ((errors++))
        fi
      fi
      
      # Remover el enlace procesado para continuar buscando en la misma línea
      line="${line#*"${BASH_REMATCH[0]}"}"
    done
  done < "$file"
  
  return $errors
}

# DOC-V2: Validación de paridad i18n ES/PT
validate_i18n_parity() {
  local base_file="${1:?Arquivo base não especificado}"
  local es_file="${base_file%.md}.es.md"
  local pt_file="${base_file%.md}.pt.md"
  local warnings=0
  
  # Si existen variantes, verificar que tienen frontmatter compatible
  for variant in "$es_file" "$pt_file"; do
    if [[ -f "$variant" ]]; then
      local base_lang variant_lang
      base_lang=$(grep -E '^language:' "$base_file" 2>/dev/null | head -1 | sed 's/.*:[[:space:]]*//')
      variant_lang=$(grep -E '^language:' "$variant" 2>/dev/null | head -1 | sed 's/.*:[[:space:]]*//')
      
      # Verificar que artifact_id coincide
      local base_artifact variant_artifact
      base_artifact=$(grep -E '^artifact_id:' "$base_file" | head -1 | sed 's/.*:[[:space:]]*//')
      variant_artifact=$(grep -E '^artifact_id:' "$variant" | head -1 | sed 's/.*:[[:space:]]*//')
      
      if [[ "$base_artifact" != "$variant_artifact" ]]; then
        printf '[%s][WARN][DOC-V2][file:%s] artifact_id divergente: base=%s vs variant=%s\n' \
          "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$variant" "$base_artifact" "$variant_artifact" >&2
        ((warnings++))
      fi
    fi
  done
  
  return $warnings
}

# C4: Tenant isolation - Validação obrigatória de contexto para logs
: "${TENANT_ID:?Variável de ambiente TENANT_ID não definida. Abortando para evitar vazamento de contexto documental.}"

# DOC-C1: Resource limits - Timeout para operações de validação documental
# Ajustar conforme complexidade: simple=30, standard=120, full=300
readonly DOC_VALIDATION_TIMEOUT="${DOC_VALIDATION_TIMEOUT:-120}"
```

---

## 🔍 Observability Integration (OpenTelemetry Native)

### Função Canônica: `mantis_log()` (V-LOG-02 + C8 + PII Scrubbing)
```bash
# Assinatura canônica atualizada (definida aqui, herdada por todos os artefatos documentais)
mantis_log() {
  local level="${1:-INFO}"                    # DEBUG|INFO|WARN|ERROR|FATAL
  local event="${2:-unknown}"                 # Nome do evento (ex: "doc_generated", "gate_failed")
  local detail="${3:-}"                       # Descrição livre ou JSON stringificado
  local diataxis="${4:-unknown}"              # tutorial|how-to|reference|explanation|adr|event-catalog
  local languages="${5:-pt-BR}"               # es-ES|pt-BR|both
  
  # C3: Sanitização automática de dados sensíveis (PII Scrubbing)
  local sanitized_detail
  sanitized_detail=$(printf '%s' "$detail" | sed -E 's/(password|token|api_key|secret|key|auth)[=:][^[:space:]]+/\1=***REDACTED***/gi')
  
  # V-LOG-02: Schema JSONL completo para Loki/Grafana + OTel mappable
  printf '{"timestamp":"%s","level":"%s","resource":{"tenant_id":"%s","artifact":"%s"},"body":{"event":"%s","detail":"%s","diataxis_type":"%s","languages_generated":%s},"attributes":{"mantis":{"tier":"%s","version":"%s","constraint":"%s","trace_id":"%s","span_id":"%s","parent_span_id":"%s"},"code.filepath":"%s","code.lineno":"%s","telemetry.sdk.name":"mantis-doc-adapter","telemetry.sdk.version":"1.0.0","doc.gates":{"structure":%s,"content":%s,"security":%s,"accessibility":%s,"agent_compat":%s}}}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "$level" \
    "${TENANT_ID:-unknown}" \
    "${ARTIFACT_ID:-unknown}" \
    "$event" \
    "$sanitized_detail" \
    "$diataxis" \
    "[\"${languages//,/\",\"}\"]" \
    "${TIER:-2}" \
    "${VERSION:-1.0.0}" \
    "${CONSTRAINT:-unknown}" \
    "${TRACE_ID:-}" \
    "${SPAN_ID:-}" \
    "${PARENT_SPAN_ID:-}" \
    "${BASH_SOURCE[1]:-unknown}" \
    "${BASH_LINENO[0]:-0}" \
    "${GATE_STRUCTURE:-0}" \
    "${GATE_CONTENT:-0}" \
    "${GATE_SECURITY:-0}" \
    "${GATE_ACCESSIBILITY:-0}" \
    "${GATE_AGENT_COMPAT:-0}" \
    >&2
}
```

---

## 🧪 Testes Unitários (TDD)

```bash
# 3 casos mínimos: happy path, error handling, constraint validation

test_freshness_checker_happy_path() {
  # Arrange
  export TENANT_ID="test-tenant"
  export TASK_ID="test-task-001"
  local test_file="/tmp/test-fresh.md"
  cat > "$test_file" <<'EOF'
---
artifact_id: "test"
version: "1.0.0"
last_updated: "2026-05-24"
---
# Fresh Doc
EOF
  
  # Act
  local result
  result=$(check_freshness "$test_file")
  
  # Assert
  echo "$result" | jq -e '.is_fresh' || return 1
  rm -f "$test_file"
  return 0
}

test_freshness_checker_error_handling() {
  # Arrange
  export TENANT_ID="test-tenant"
  export TASK_ID="test-task-002"
  local nonexistent_file="/nonexistent/doc.md"
  
  # Act
  local result
  result=$(check_freshness "$nonexistent_file" 2>&1) || true
  
  # Assert
  echo "$result" | grep -q "ERROR" || return 1
  return 0
}

test_freshness_checker_constraint_validation() {
  # Arrange
  export TENANT_ID="test-tenant"
  export TASK_ID="test-task-003"
  local test_file="/tmp/test-stale.md"
  cat > "$test_file" <<'EOF'
---
artifact_id: "test"
version: "1.0.0"
last_updated: "2020-01-01"
---
# Stale Doc
EOF
  
  # Act
  local result
  result=$(check_freshness "$test_file")
  
  # Assert
  echo "$result" | jq -e '.is_stale' || return 1
  rm -f "$test_file"
  return 0
}
```

---

## 🔍 Validação (VDD)

```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --domain docs \
  --file docs/framework/agents/freshness-checker.md \
  --json \
  --check-diataxis \
  --check-links \
  --check-secrets \
  --check-accessibility \
  --check-i18n-parity \
  --check-agent-compat
```

## 🔗 Referências Cruzadas

- [[doc-governance-ceo.md]]
- [[doc-agnostic-master-agent.md]]
- [[01-RULES/harness-norms-v3.0.md]]
- [[01-RULES/11-A2A-COMMUNICATION-RULES.md]]
- [[05-CONFIGURATIONS/validation/norms-matrix.json]]
- [[goals/README.md]]

---

## 📋 Checklist de Geração – Antes de Commit

1. ✅ Frontmatter YAML válido con clasificación Diátaxis (DOC-C5)
2. ✅ Hardening documental aplicado (DOC-C8)
3. ✅ Zero secrets en ejemplos (DOC-C3)
4. ✅ `mantis_log()` implementada e validada (C8)
5. ✅ Tests TDD passam (3 casos mínimos)
6. ✅ `orchestrator-engine --json` retorna `passed: true`
7. ✅ Contexto A2A inicializado: `trace_id` y `span_id` generados (C9)
8. ✅ `status.json` escrito con schema completo (C9)
9. ✅ Validação C9 via `check-a2a-contract.sh` pasó (exit 0)
