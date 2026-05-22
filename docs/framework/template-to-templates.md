

---
# 📦 TEMPLATE DE DESCOMPOSICIÓN DE APÉNDICES – MEMORIA OPERATIVA MANTIS

## 📜 TEMPLATE CANÓNICO: DESCOMPOSICIÓN DE APÉNDICE OPERATIVO

```markdown
---
artifact_id: "appendix-{SECTION_ID}-{COMPONENT_TYPE}-mantis"
artifact_type: "operational_memory_component"
version: "1.0.0"
constraints_mapped: ["C1","C2","C3","C4","C5","C6","C7","C8","C9","DOC-C1","DOC-C2","DOC-C3","DOC-C4","DOC-C5","DOC-V1","DOC-V2","DOC-V3"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --domain docs --file docs/framework/agents/templates/appendix-{SECTION_ID}-{COMPONENT_TYPE}.md --json"
canonical_path: "docs/framework/agents/templates/appendix-{SECTION_ID}-{COMPONENT_TYPE}.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:appendix-decomposition-contract-v1.0.0"
generated_at: "{ISO_8601_UTC}"
tenant_context: "nao_aplicavel"
language: "pt-BR|es-ES"
domain: "docs"
subdomain: "framework/agents/templates"
component_type: "prompt|reference|script|template"
section_id: "{APPENDIX_SECTION_NUMBER}"
ai_navigation:
  read_first: true
  required_for: ["agent-execution-context", "constraint-validation", "i18n-parity-check", "c9-handoff-routing"]
  update_frequency: monthly
  compatible_models: ["qwen", "deepseek", "claude", "minimax", "mimo-xiaomi", "gpt-4", "gemini"]
audience: ["doc-governance-ceo", "orchestrator-engine", "sub-agents", "human-architects"]
status: "✅ Estável"
next_review: "{+30d_ISO_8601}"
license: "CC-BY-NC-SA-4.0"
---

# 🧩 Apéndice Descompuesto: {SECTION_ID} – {COMPONENT_TYPE}
> **Propósito**: Fragmento operativo extraído del Apéndice Principal ({APPENDIX_NAME}). Listo para ejecución bajo normativa MANTIS v2.3.0.
> **Principio**: *"Los apéndices son memoria operativa: prompts, referencias, scripts y templates listos para ejecución bajo normativa MANTIS."*

---

## 📊 MATRIZ DE DESCOMPOSICIÓN

| Campo | Valor | Validación |
|-------|-------|-----------|
| `section_id` | `{APPENDIX_SECTION_NUMBER}` | `grep -c "## {SECTION_ID}" docs/framework/appendix-main.md` |
| `component_type` | `prompt \| reference \| script \| template` | `jq -e '.component_type' docs/framework/agents/templates/{artifact_id}.md` |
| `line_range` | `{START_LINE}-{END_LINE}` | `sed -n '{START_LINE},{END_LINE}p' docs/framework/appendix-main.md \| wc -l` |
| `checksum_sha256` | `sha256:…` | `sed -n '{START_LINE},{END_LINE}p' docs/framework/appendix-main.md \| sha256sum` |
| `drift_status` | `clean` | `bash 05-CONFIGURATIONS/scripts/verify-raw-urls.sh --check-hash` |

---

## 🧠 ESTÁNDAR: PROMPT OPERATIVO
*(Usar cuando `component_type: prompt`)*

```yaml
prompt_schema:
  role: "{AGENT_ROLE}"
  context: "{TASK_CONTEXT}"
  few_shot_examples:
    - input: "{EXAMPLE_INPUT}"
      output: "{EXPECTED_OUTPUT}"
      constraints_enforced: ["C3","DOC-C5","DOC-C8"]
  execution_rules:
    - "Zero invención de datos externos"
    - "Preservar lógica original, enriquecer con bootstrap V-LOG-02"
    - "Si ambigüedad > umbral, emitir evento `prompt_clarification_required` en V-LOG-02"
  output_format: "{yaml|json|markdown|bash}"
  validation_command: "python 05-CONFIGURATIONS/validation/validate-prompt-schema.py --file $1"
```

---

## 📚 ESTÁNDAR: REFERENCIA CANÓNICA
*(Usar cuando `component_type: reference`)*

```yaml
reference_schema:
  canonical_url: "{RAW_GITHUB_URL}"
  local_mirror_path: "docs/framework/agents/references/{REFERENCE_NAME}.md"
  constraint_mapping:
    - constraint: "DOC-C3"
      clause: "Zero secrets en ejemplos"
      verification: "scan_doc_secrets"
    - constraint: "C9"
      clause: "Handoff A2A con trace_id"
      verification: "check-a2a-contract.sh"
  verification:
    hash_check: "curl -sL $canonical_url | sha256sum"
    drift_alert: "if [ $LOCAL_HASH != $REMOTE_HASH ]; then mantis_log WARN reference_drift; fi"
  last_verified: "{ISO_8601_UTC}"
```

---

## ⚙️ ESTÁNDAR: SCRIPT EJECUTABLE
*(Usar cuando `component_type: script`)*

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="${VERSION:-1.0.0}"
trap '[[ -n "${TEMP_FILE:-}" && -f "${TEMP_FILE}" ]] && rm -f "${TEMP_FILE}"; exit $?' EXIT INT TERM
: "${TENANT_ID:?TENANT_ID não definida. Abortando para evitar vazamento.}"

# C7: Timeout para operaciones críticas
readonly OPERATION_TIMEOUT="${OPERATION_TIMEOUT:-120}"

# C8: Observabilidad V-LOG-02
source_mantis_log || fallback_mantis_log

# I/O Schema
INPUT_SCHEMA="{REQUIRED_INPUT_VAR}"
OUTPUT_PATH="{EXPECTED_OUTPUT_PATH}"

# Validación pre-ejecución
validate_inputs() {
  [[ -z "${!INPUT_SCHEMA}" ]] && { mantis_log ERROR missing_input "$INPUT_SCHEMA"; exit 1; }
  [[ -f "${!INPUT_SCHEMA}" ]] || { mantis_log ERROR invalid_path "${!INPUT_SCHEMA}"; exit 1; }
}

# Lógica ejecutable (extraída del apéndice)
execute_logic() {
  # [PEGAR AQUÍ BLOCO EXTRAÍDO DEL APÉNDICE]
  mantis_log INFO execution_completed "output:${OUTPUT_PATH}" "reference" "pt-BR"
}

# Post-ejecución & C9
write_status_json() {
  mkdir -p "./goals/${TASK_ID}/artifacts/${SCRIPT_NAME}"
  cat > "./goals/${TASK_ID}/artifacts/${SCRIPT_NAME}/status.json" <<EOF
{
  "agent_id": "${SCRIPT_NAME}",
  "trace_id": "${TRACE_ID}",
  "span_id": "${SPAN_ID}",
  "parent_span_id": "${PARENT_SPAN_ID}",
  "status": "completed",
  "output_ref": "${OUTPUT_PATH}",
  "next_agent_hint": "doc-governance-ceo",
  "timestamp_completed": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "a2a_contract_version": "1.0"
}
EOF
}

main() {
  validate_inputs
  execute_logic
  write_status_json
}
main "$@"
```

---

## 📝 ESTÁNDAR: TEMPLATE EJECUTABLE
*(Usar cuando `component_type: template`)*

```jinja2
{# TEMPLATE SCHEMA – MANTIS OPERATIONAL MEMORY #}
{# Engine: Jinja2 / Markdown / YAML #}
{# Validation: orchestrator-engine --domain docs --check-diataxis #}

---
artifact_id: "{{ document_name }}"
artifact_type: "{{ diataxis_quadrant }}"
version: "{{ version | default('1.0.0') }}"
constraints_mapped: ["DOC-C1","DOC-C2","DOC-C3","DOC-C4","DOC-C5"]
canonical_path: "docs/{{ quadrant }}/{{ document_name }}.md"
tier: 3
language: "{{ language | default('pt-BR') }}"
diataxis: "{{ diataxis_quadrant }}"
audience: "{{ audience | default('beginner') }}"
prerequisites: {{ prerequisites | tojson }}
estimated_time: "{{ estimated_time }} minutos"
last_updated: "{{ last_updated | default(now()) }}"
---

# {{ title }}

{{ overview }}

{% if steps %}
{% for step in steps %}
## Paso {{ loop.index }}: {{ step.title }}
{{ step.content }}
{% if step.code %}
```{{ step.lang | default('bash') }}
{{ step.code }}
```
{% endif %}
{% endfor %}
{% endif %}

{% if validation_gates %}
## Validación
{% for gate in validation_gates %}
- [ ] {{ gate.name }}: {{ gate.check }}
{% endfor %}
{% endif %}
```

---

## 🔗 INTEGRACIÓN CON `goals/` & C9 (A2A)

| Etapa | Acción | Archivo/Endpoint |
|-------|--------|------------------|
| Pre-ejecución | Leer `context/trace.json` | `./goals/${TASK_ID}/context/trace.json` |
| Durante | Emitir logs V-LOG-02 | `mantis_log()` con `diataxis_type` + `gate_scores` |
| Post-ejecución | Escribir `status.json` | `./goals/${TASK_ID}/artifacts/${ARTIFACT_ID}/status.json` |
| Validación | Chequear contrato C9 | `bash ./goals/check-a2a-contract.sh --task-id $TASK_ID --agent $AGENT_NAME` |

---

## 🧪 PROTOCOLO DE VALIDACIÓN AUTOMÁTICA

```bash
# 1. Verificar que el componente extraído coincide con hash original
sed -n '{START_LINE},{END_LINE}p' docs/framework/appendix-main.md | sha256sum | cut -d' ' -f1
# → Comparar con `checksum_sha256` en frontmatter

# 2. Validar schema según tipo
case $COMPONENT_TYPE in
  prompt)   python 05-CONFIGURATIONS/validation/validate-prompt-schema.py --file "$1" ;;
  reference) bash 05-CONFIGURATIONS/validation/verify-reference-hash.sh --url "$CANONICAL_URL" ;;
  script)    bash "$1" --dry-run 2>&1 | jq -e '.passed' ;;
  template)  jinja2 --validate "$1" --schema 05-CONFIGURATIONS/validation/template-schema.json ;;
esac

# 3. Inyectar en `goals/` para ejecución trazable
TASK_ID="appendix-decomp-$(date +%s)"
mkdir -p "./goals/${TASK_ID}/context"
echo '{"trace_id":"init","parent_span_id":null,"current_agent":"appendix-decomposer","task_id":"'"${TASK_ID}"'"}' > "./goals/${TASK_ID}/context/trace.json"
```

---

## 🗂️ ESTRUCTURA DE SALIDA RECOMENDADA

```
docs/framework/agents/
├── templates/
│   ├── appendix-01-prompt.md
│   ├── appendix-02-reference.md
│   ├── appendix-03-script.md
│   ├── appendix-04-template.md
│   └── ...
├── references/
│   ├── constraints-mapping.yaml
│   ├── canonical-urls-index.json
│   └── drift-alerts.log
├── scripts/
│   ├── validate-fragment.sh
│   ├── extract-appendix-block.py
│   └── inject-goals-context.sh
└── prompts/
    ├── diataxis-routing.yaml
    ├── i18n-parity-check.yaml
    └── c9-handoff-template.yaml
```

---

## 📋 CHECKLIST DE DESCOMPOSICIÓN (Pre-Merge)

- [ ] Cada fragmento tiene `artifact_id` único y `checksum_sha256` verificado
- [ ] `component_type` coincide con el estándar (`prompt|reference|script|template`)
- [ ] Script incluye `set -Eeuo pipefail`, `trap cleanup`, `mantis_log()` + fallback
- [ ] Template incluye validación Jinja2/Markdown y mapeo `diataxis`
- [ ] Referencia incluye `canonical_url`, `hash_check`, `drift_alert`
- [ ] Prompt incluye `few_shot_examples`, `execution_rules`, `output_format`
- [ ] Todos pasan `orchestrator-engine.sh --domain docs --check-all --json`
- [ ] `status.json` C9 escrito tras ejecución de cada fragmento script/template

---
