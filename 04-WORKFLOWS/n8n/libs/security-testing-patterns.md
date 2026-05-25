---
artifact_id: "n8n-security-testing-patterns"
artifact_type: "n8n_pattern"
version: "1.0.0"
constraints_mapped: ["C3","C5","C8"]
validation_command: "bash 05-CONFIGURATIONS/validation/orchestrator-engine.sh --file 04-WORKFLOWS/n8n/libs/security-testing-patterns.md --json"
canonical_path: "04-WORKFLOWS/n8n/libs/security-testing-patterns.md"
tier: 2
mode_selected: "B1"
prompt_hash: "sha256:security-testing-v1.0.0"
generated_at: "2026-05-24T19:40:00Z"
tenant_context: "obrigatorio"
language: pt-BR
domain: "n8n"
ai_navigation:
  read_first: false
  required_for: ["security-audit", "vulnerability-scanning"]
  update_frequency: on-change
audience: ["n8n-master-agent", "orchestrator-engine", "validation-hooks"]
status: "🟢 Novo"
next_review: "2026-06-24"
---

# 🛡️ Padrões de Teste de Segurança

> **Contrato modular**: Artefato filho de `n8n-master-agent-mantis`.

## 🎯 Propósito
Padronizar a auditoria de segurança em workflows n8n, incluindo escaneamento de credenciais expostas, verificação de encriptação, testes de autenticação de webhooks, validação de entradas e detecção de vazamento de dados em logs, garantindo segurança (C3), validação (C5) e observabilidade (C8).

## 📋 Especificação (SDD)
- **Entradas**: Workflow ID, URL de webhook.
- **Saídas**: Relatório de auditoria com severidade dos achados e recomendações.
- **Constraints Aplicáveis**: C3 (proteção de credenciais), C5 (validação de segurança), C8 (logging de auditoria).
- **Dependências**: Acesso à API do n8n, workflows em execução.

---

## 🛡️ Bootstrap + Lógica de Domínio

```yaml
security_testing:
  credential_scanning:
    description: "Escanear JSON do workflow em busca de credenciais expostas"
    patterns:
      - "API Keys genéricas"
      - "AWS Access Keys (AKIA...)"
      - "Bearer Tokens"
      - "Slack Tokens (xoxb-...)"
      - "Campos 'password' ou 'secret' em texto plano"
    recommendation: "Remover do workflow, usar n8n credentials"

  encryption_verification:
    description: "Verificar se credenciais estão criptografadas em repouso"
    checks:
      - "Dados não são texto plano"
      - "Algoritmo de encriptação conhecido"
      - "Uso de chave de encriptação da instância"

  webhook_auth_testing:
    description: "Testar se webhooks exigem autenticação"
    tests:
      - "Requisição sem auth deve retornar 401"
      - "Auth inválida (Basic, Bearer, Header) deve retornar 401"

  input_validation:
    description: "Testar sanitização de entradas contra cargas maliciosas"
    payloads:
      - "XSS (<script>alert(1)</script>)"
      - "SQL Injection ('; DROP TABLE...) "
      - "Path Traversal ('../../../etc/passwd')"
      - "Payloads oversized (10MB)"

  expression_security:
    description: "Escanear expressões em busca de funções perigosas"
    dangerous:
      - "eval(), Function()"
      - "require(), import()"
      - "child_process, exec(), spawn()"
      - "fs."

  data_leakage:
    description: "Escanear logs de execução em busca de vazamento de credenciais"
    scan_target: "Execuções recentes (últimas N)"
    patterns: "Passwords, API Keys, Tokens, Authorization Headers"
    fix: "Habilitar mascaramento de credenciais nas configurações do n8n"

  security_report:
    sections:
      - "Sumário (Credential, Webhook, Expression, Data Leakage)"
      - "Achados Críticos (detalhes e localização)"
      - "Recomendações (habilitar auth, rotacionar credenciais, mascarar logs)"
```

---

## 🧪 Testes Unitários (TDD)

```bash
test_credential_scan_no_findings() {
  local workflow='{"nodes":[{"parameters":{"authentication":"predefinedCredentialType"}}]}'
  python3 -c "
import json, re; d=json.loads('$workflow'); s=json.dumps(d)
assert not re.search(r'AKIA[0-9A-Z]{16}', s)
assert not re.search(r'xox[baprs]-[0-9]{10,13}-[0-9]{10,13}-[a-zA-Z0-9]{24}', s)
" 2>/dev/null && return 0 || return 1
}

[[ "${1:-}" == "--test" ]] && { test_credential_scan_no_findings && echo "✅" || echo "❌"; exit $?; }
```

---

## 🔗 Referências Cruzadas

- [[n8n-master-agent.md]]
- [[credentials-security.md]]
- [[error-handling-patterns.md]]
- [[/05-CONFIGURATIONS/validation/audit-secrets.sh]]
