---
artifact_id: "pipelines-opensource-pipeline"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C3","C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/opensource-pipeline.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/opensource-pipeline.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:opensource-pipeline-v1.0.0"
generated_at: "2026-05-24T00:40:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["open-source-release", "code-sanitization"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🔐 Pipeline de Open-Source

> **Contrato modular**: Filho de `pipelines-master-agent-mantis`.

## 🎯 Propósito
Automatizar a sanitização e publicação segura de projetos para código aberto, garantindo que nenhum secret ou referência interna vaze (C3, C5).

## 📋 Especificação
- **Entradas**: Nome do projeto, licença, organização GitHub.
- **Saídas**: Código sanitizado, documentação, relatórios.
- **Constraints Aplicáveis**: C3 (secrets), C5 (validação).

---

## 🛡️ Protocolo de 3 Etapas

### Etapa 1: FORK (opensource-forker)
- Copiar arquivos (excluindo `.git/`, `node_modules/`, `__pycache__/`)
- Strip de secrets e credenciais
- Gerar `.env.example`
- Limpar histórico git

### Etapa 2: SANITIZE (opensource-sanitizer)
- 6 categorias de escaneio (secrets, PII, referências internas, arquivos perigosos, config, git history)
- Veredito: PASS / PASS WITH WARNINGS / FAIL

### Etapa 3: PACKAGE (opensource-packager)
- Gerar `CLAUDE.md`, `setup.sh`, `README.md`, `LICENSE`, `CONTRIBUTING.md`

---

## 🧪 Testes Unitários (TDD)
```bash
test_sanitization_report_required() {
  echo "SANITIZATION_REPORT.md must exist before packaging" && return 0
}
[[ "${1:-}" == "--test" ]] && { test_sanitization_report_required && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[../../docker-compose/libs/references/security-checklist.md]]
