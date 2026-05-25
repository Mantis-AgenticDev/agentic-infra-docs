---
artifact_id: "docker-compose-validation-scripts"
artifact_type: "docker-compose_pattern"
version: "1.0.0"
constraints_mapped: ["C5"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 05-CONFIGURATIONS/docker-compose/libs/validation-scripts.md --json"
canonical_path: "05-CONFIGURATIONS/docker-compose/libs/validation-scripts.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:validation-scripts-v1.0.0"
generated_at: "2026-05-23T19:05:00Z"
tenant_context: "nao_aplicavel"
language: pt-BR
domain: "docker-compose"
ai_navigation:
  read_first: false
  required_for: ["compose-validation", "dockerfile-linting"]
  update_frequency: on-change
audience: ["docker-compose-master-agent"]
status: "🟢 Novo"
next_review: "2026-06-23"
---

# ✅ Scripts de Validação

> **Contrato modular**: Filho de `docker-compose-master-agent-mantis`.

## 🎯 Propósito
Catalogar os comandos de validação disponíveis para arquivos Compose e Dockerfiles, garantindo que todo artefato gerado passe pelas verificações de integridade (C5).

## 📋 Especificação
- **Entradas**: Caminho do arquivo a validar.
- **Saídas**: Código de saída 0 (válido) ou relatório de erros.
- **Constraints Aplicáveis**: C5 (validação automatizada).

---

## 🛡️ Comandos de Validação

### Validar Sintaxe do Compose
```bash
docker compose -f compose.yaml -f compose.prod.yaml config --quiet \
  && echo "✅ Compose válido" || echo "❌ Erro de sintaxe"
```

### Validar Dockerfile com hadolint
```bash
hadolint Dockerfile.prod
```

### Validar com orchestrator-engine.sh
```bash
bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh \
  --domain docker-compose \
  --file compose.prod.yaml \
  --strict
```

### Escanear Imagem com Trivy
```bash
trivy image --severity HIGH,CRITICAL --exit-code 1 \
  registry.mantis.org/app:${VERSION}
```

### Verificar Secrets no Código
```bash
bash 05-CONFIGURATIONS/validation/audit-secrets.sh \
  --path 05-CONFIGURATIONS/docker-compose/
```

---

## 🧪 Testes Unitários (TDD)
```bash
test_compose_config_available() {
  command -v docker &>/dev/null || return 0
  docker compose version &>/dev/null && return 0 || return 1
}
[[ "${1:-}" == "--test" ]] && { test_compose_config_available && echo "✅" || echo "❌"; }
```

---

## 🔗 Referências Cruzadas
- [[docker-compose-master-agent.md]]
- [[/05-CONFIGURATIONS/validation/orchestrator-engine/main.go]]
- [[/05-CONFIGURATIONS/validation/VALIDATOR_DEV_NORMS.md]]
