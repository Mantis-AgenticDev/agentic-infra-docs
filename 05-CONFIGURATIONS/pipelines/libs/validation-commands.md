---
artifact_id: "pipelines-validation-commands"
artifact_type: "pipelines_pattern"
version: "1.0.0"
constraints_mapped: ["C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/pipelines/libs/validation-commands.md --json"
canonical_path: "05-CONFIGURATIONS/pipelines/libs/validation-commands.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:validation-commands-v1.0.0"
generated_at: "2026-05-24T01:30:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "pipelines"
ai_navigation:
  read_first: false
  required_for: ["pipeline-validation", "ci-cd-compliance"]
  update_frequency: on-change
audience: ["pipelines-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# ✅ Comandos de Validação do Domínio Pipelines

> **Contrato modular**: Filho de `pipelines-master-agent-mantis`. Complementa [[../../docker-compose/libs/validation-scripts.md]].

## 🎯 Propósito
Catalogar todos os comandos de validação disponíveis para o domínio `pipelines/`, garantindo que todo artefato gerado passe pelas verificações de integridade (C5).

## 📋 Especificação
- **Entradas**: Caminho do arquivo a validar.
- **Saídas**: Código de saída 0 (válido) ou relatório de erros.
- **Constraints Aplicáveis**: C5 (validação automatizada).

---

## 🛡️ Comandos de Validação

### Validação Rápida (Pre-Commit)
```bash
bash orchestrator-engine.sh --domain pipelines --mode quick
```

### Validação Completa (CI/CD)
```bash
bash orchestrator-engine.sh --domain pipelines --strict
```

### Auditoria de Secrets
```bash
bash audit-secrets.sh --path 05-CONFIGURATIONS/pipelines/ --include-workflows
```

### Validação de LANGUAGE_LOCK
```bash
bash verify-constraints.sh --check-language-lock --domain pipelines
```

### Testes promptfoo
```bash
cd 05-CONFIGURATIONS/pipelines/promptfoo && npx promptfoo eval --config config.yaml
```

### Verificação de Checksums
```bash
for file in 05-CONFIGURATIONS/pipelines/*.md; do
  EXPECTED=$(grep 'checksum_sha256:' "$file" | cut -d'"' -f2)
  ACTUAL=$(sha256sum "$file" | awk '{print $1}')
  [ "$EXPECTED" = "$ACTUAL" ] || echo "⚠️ Checksum mismatch em $file"
done
```

### Verificação de SHA Pinning
```bash
grep -r "uses:.*@v[0-9]" .github/workflows/ | grep -v "@[a-f0-9]\{40\}" && \
  echo "⚠️ Ações sem SHA pinning" || echo "✅ Todas com SHA"
```

### Validação de Workflows
```bash
for wf in .github/workflows/*.yml; do
  python3 -c "import yaml; yaml.safe_load(open('$wf'))" && echo "✅ $wf" || echo "❌ $wf"
done
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_validation_script_exists() {
  for script in orchestrator-engine.sh audit-secrets.sh verify-constraints.sh; do
    [[ -x 05-CONFIGURATIONS/validation/$script ]] || return 1
  done
  return 0
}
[[ "${1:-}" == "--test" ]] && { test_validation_script_exists && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[pipelines-master-agent.md]]
- [[../../docker-compose/libs/validation-scripts.md]]
- [[/05-CONFIGURATIONS/validation/orchestrator-engine/main.go]]
